# Ansible Learning Notes

Quick reference for everything covered so far.

---

## 1. Control Node Setup

- Ansible **only runs from Linux/macOS** — on Windows, use WSL2 as the control node
- Install via pipx (isolated Python environment — preferred over apt):
  ```zsh
  pipx install ansible-core
  ```
- Verify:
  ```zsh
  ansible --version
  ansible-inventory --version
  ```

---

## 2. Key Concepts

| Term | Meaning |
|---|---|
| **Control node** | The machine Ansible runs *from* |
| **Managed node** | The target machine being configured (no agent needed — SSH only) |
| **Inventory** | File listing which hosts to manage and how to reach them |
| **Playbook** | YAML file defining what tasks to run on which hosts |
| **Module** | A built-in unit of work (e.g. `debug`, `ping`, `apt`, `copy`) |
| **Task** | A single call to a module inside a playbook |
| **Play** | A group of tasks targeting a specific set of hosts |
| **Fact** | System info Ansible collects automatically before tasks run |

---

## 3. Inventory

Static inventory file (`hosts.ini`):

```ini
[all:vars]
ansible_user=root          # applies to every host

[webservers]
web01 ansible_host=1.2.3.4

[dbservers]
db01 ansible_host=5.6.7.8
```

- Hosts can belong to one or more groups
- `all` is a built-in group containing every host
- `ungrouped` is a built-in group for hosts not in any named group

Validate inventory:
```zsh
ansible-inventory -i inventories/dev/hosts.ini --list
```

---

## 4. Playbook Structure

```yaml
---
- name: Name of the play          # shown in output
  hosts: webservers               # which group(s) to target
  gather_facts: false             # skip SSH fact collection (useful for placeholders)

  tasks:
    - name: Descriptive task name
      ansible.builtin.debug:
        msg: "Hello from {{ inventory_hostname }}"
```

Run a playbook:
```zsh
ansible-playbook -i inventories/dev/hosts.ini playbooks/hello.yml
```

- `inventory_hostname` — built-in variable: the name of the current host as defined in the inventory
- `gather_facts: false` — disables automatic SSH-based fact collection; required when hosts aren't reachable

---

## 5. Variables

**Inline (play vars):**
```yaml
vars:
  greeting: "Hello"
```

**`group_vars/` files** (loaded automatically by convention):
```
inventories/dev/group_vars/
  all.yml          # applies to every host
  webservers.yml   # applies to the webservers group only
```

**CLI override:**
```zsh
ansible-playbook ... -e "greeting='Overridden'"
```

**Precedence (lowest → highest):**
```
group_vars/all  <  group_vars/<group>  <  host_vars  <  play vars  <  extra vars (-e)
```

More specific always wins. `-e` always wins.

---

## 6. Loops & Conditionals

**Loop over a list:**
```yaml
- name: Install packages
  ansible.builtin.debug:
    msg: "Installing {{ item }}"
  loop:
    - nginx
    - curl
    - git
```
`item` is the built-in variable holding the current loop value.

**Run only when a condition is true:**
```yaml
when: inventory_hostname in groups['webservers']
when: some_variable == "value"
when: some_variable is defined
```

---

## 7. Handlers

Handlers run **once after all tasks**, only if notified by a task that reported `changed`.

```yaml
tasks:
  - name: Update config
    ansible.builtin.copy:
      src: nginx.conf
      dest: /etc/nginx/nginx.conf
    notify: Restart nginx

handlers:
  - name: Restart nginx
    ansible.builtin.service:
      name: nginx
      state: restarted
```

- `changed_when: true` — forces a task to report `changed` (useful for testing)
- A handler notified multiple times still runs only once

---

## 8. Roles

Reusable, self-contained units of automation with a standardised layout:

```
roles/common/
├── tasks/main.yml       # required — tasks run when role is applied
├── handlers/main.yml    # optional
├── vars/main.yml        # optional — high precedence variables
├── defaults/main.yml    # optional — lowest precedence variables
├── templates/           # optional — Jinja2 .j2 template files
└── files/               # optional — static files
```

Apply a role in a playbook:
```yaml
- name: Configure all hosts
  hosts: all
  roles:
    - common
```

---

## 9. Templates

Templates use Jinja2 to generate dynamic config files from variables.

**Template file (`motd.j2`):**
```
# Managed by Ansible — do not edit manually
Welcome to {{ inventory_hostname }}
Server group: {{ group_names | join(', ') }}
```

**Deploy to a managed node (requires SSH):**
```yaml
- name: Write motd
  ansible.builtin.template:
    src: motd.j2
    dest: /etc/motd
```

**Preview locally without SSH (control node only):**
```yaml
- name: Preview template
  ansible.builtin.debug:
    msg: "{{ lookup('template', 'motd.j2') }}"
```

| Method | Renders on | Writes to target | SSH needed |
|---|---|---|---|
| `lookup('template', ...)` | control node | no | no |
| `ansible.builtin.template` | control node | yes | yes |

- `group_names` — built-in list of all groups the current host belongs to
- `| join(', ')` — Jinja2 filter to turn a list into a string
- Template files live in `roles/<name>/templates/` and use the `.j2` extension

---

## 10. Tags

Tags let you run a subset of tasks without changing the playbook.

```yaml
- name: Install packages
  ansible.builtin.debug:
    msg: "Installing packages"
  tags: [packages, setup]

- name: Apply config
  ansible.builtin.debug:
    msg: "Applying config"
  tags: [config]
```

| CLI | Effect |
|---|---|
| `--tags packages` | run only tasks tagged `packages` |
| `--tags packages,config` | run tasks tagged either |
| `--skip-tags config` | run everything except `config` tagged tasks |

Tags can also be applied to an entire role:
```yaml
roles:
  - role: common
    tags: [common]
```

---

## 11. Ansible Vault

Encrypts sensitive values so secrets can be safely committed to Git.

**Common commands:**
```zsh
ansible-vault create secrets.yml       # create new encrypted file
ansible-vault edit secrets.yml         # edit existing encrypted file
ansible-vault view secrets.yml         # view without editing
```

**Best practice — `vault_` prefix convention:**
```
group_vars/all/
  vault.yml   ← encrypted, contains: vault_db_password: "secret"
  vars.yml    ← plain,     contains: db_password: "{{ vault_db_password }}"
```
Playbooks reference `db_password` — never the raw `vault_` variable directly.

**Run with vault decryption:**
```zsh
ansible-playbook playbooks/site.yml --ask-vault-pass
ansible-playbook playbooks/site.yml --vault-password-file ~/.vault_pass
```

- Variables are loaded for all hosts on every run — they only appear in output if a task explicitly references them
- The encrypted blob in `vault.yml` is safe to commit to Git

---

## 12. ansible.cfg

Project-level configuration file placed at the **project root**. Ansible loads it automatically when running commands from that directory.

```ini
[defaults]
inventory  = inventories/dev/hosts.ini   # default inventory (no -i needed)
roles_path = roles                        # where to find roles
```

**WSL gotcha:** `/mnt/c/` is world-writable from Linux's perspective, so Ansible ignores `ansible.cfg` there as a security measure. Fix by exporting the path explicitly — add to `~/.zshrc`:

```zsh
export ANSIBLE_CONFIG=/mnt/c/Users/NRueber/source/repos/private/ansible/ansible.cfg
```

---

## 13. Useful Commands

| Command | Purpose |
|---|---|
| `ansible-inventory -i <inv> --list` | Parse and display inventory as JSON |
| `ansible -i <inv> all -m ping` | Test SSH connectivity to all hosts |
| `ansible-playbook -i <inv> <playbook>` | Run a playbook |
| `ansible-playbook ... -e "key=val"` | Run with extra variable override |
| `ansible-doc ansible.builtin.debug` | Show module documentation |

---

## 14. Project Layout (so far)

```
ansible/
├── GUIDELINES.md
├── ansible.cfg
├── docs/
│   └── notes.md                  ← this file
├── inventories/
│   └── dev/
│       ├── hosts.ini
│       └── group_vars/
│           ├── all/
│           │   ├── vars.yml
│           │   └── vault.yml  ← AES256 encrypted
│           └── webservers.yml
├── playbooks/
│   ├── hello.yml
│   ├── loops_and_conditions.yml
│   ├── handlers_demo.yml
│   └── site.yml
└── roles/
    └── common/
        ├── tasks/
        │   └── main.yml
        └── templates/
            └── motd.j2
```

---

## 15. Next Topics

- Real Hetzner Cloud VMs (SSH connectivity, `ansible -m ping`)
- `ansible.builtin.apt` for package management
- `ansible.builtin.service` for service management
- A real server hardening playbook
