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

## 9. ansible.cfg

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

## 10. Useful Commands

| Command | Purpose |
|---|---|
| `ansible-inventory -i <inv> --list` | Parse and display inventory as JSON |
| `ansible -i <inv> all -m ping` | Test SSH connectivity to all hosts |
| `ansible-playbook -i <inv> <playbook>` | Run a playbook |
| `ansible-playbook ... -e "key=val"` | Run with extra variable override |
| `ansible-doc ansible.builtin.debug` | Show module documentation |

---

## 11. Project Layout (so far)

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
│           ├── all.yml
│           └── webservers.yml
├── playbooks/
│   ├── hello.yml
│   ├── loops_and_conditions.yml
│   ├── handlers_demo.yml
│   └── site.yml
└── roles/
    └── common/
        └── tasks/
            └── main.yml
```

---

## 12. Next Topics

- Templates (`template:` module, Jinja2 `.j2` files)
- Tags (`--tags`, `--skip-tags`)
- Real SSH targets (Hetzner Cloud)
- Ansible Vault (encrypting secrets)
