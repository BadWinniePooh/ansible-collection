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

### Project Dependencies

This project uses two requirements files to capture all dependencies:

| File | Managed by | Purpose |
|---|---|---|
| `requirements.yml` | `ansible-galaxy` | Ansible collections (`hetzner.hcloud`, `ansible.posix`) |
| `requirements.txt` | `pipx inject` | Python packages (`hcloud`, `passlib`) |

After cloning the repo, install both with:

```zsh
ansible-galaxy collection install -r requirements.yml
pipx inject ansible-core -r requirements.txt
```

- `ansible-galaxy collection install` downloads collections to `~/.ansible/collections/`
- `pipx inject` adds Python packages into the same isolated venv that `ansible-core` lives in — they are not visible to the system Python

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

## 12. Hetzner Cloud Provisioning

### Installing a collection

Ansible collections extend core with third-party modules. Install from Ansible Galaxy:

```zsh
ansible-galaxy collection install hetzner.hcloud
```

Collections that call external APIs also need a Python SDK in the same venv:

```zsh
pipx inject ansible-core hcloud   # adds hcloud Python lib to Ansible's isolated venv
```

### Provisioning playbook structure

Provisioning runs against `localhost` with `connection: local` — no SSH needed, it calls the Hetzner API instead:

```yaml
- name: Provision Hetzner Cloud VM
  hosts: localhost
  connection: local
  gather_facts: false
```

### Storing the API token in Vault

Follow the same `vault_` prefix pattern:
```
vault.yml  → vault_hetzner_api_token: "<token>"
vars.yml   → hetzner_api_token: "{{ vault_hetzner_api_token }}"
```

### Loading variable files explicitly with vars_files

`group_vars/<group>/` files are only auto-loaded for hosts that belong to that group.
For `localhost` plays, load reference files explicitly:

```yaml
vars_files:
  - "../inventories/dev/group_vars/hcloud_location/vars.yml"
  - "../inventories/dev/group_vars/hcloud_type/vars.yml"
```

This makes reference/documentation variable files available without polluting `group_vars/all/`.

### Key modules (hetzner.hcloud collection)

| Module | Purpose |
|---|---|
| `hetzner.hcloud.ssh_key_info` | List all SSH keys in the Hetzner account |
| `hetzner.hcloud.ssh_key` | Upload/manage an SSH key |
| `hetzner.hcloud.server` | Create/delete/manage a VM |

### Idempotent SSH key upload

Hetzner rejects duplicate key content. Compare by MD5 fingerprint before uploading:

```yaml
- name: Get local SSH key fingerprint
  ansible.builtin.command:
    cmd: "ssh-keygen -E md5 -lf ~/.ssh/hetzner_ansible.pub"
  register: local_key_info
  changed_when: false

- name: Set fingerprint fact
  ansible.builtin.set_fact:
    local_key_fingerprint: "{{ local_key_info.stdout.split()[1] | regex_replace('^MD5:', '') }}"

- name: Upload key only if not already present
  hetzner.hcloud.ssh_key:
    ...
  when: local_key_fingerprint not in (existing_keys | map(attribute='fingerprint') | list)
```

- `-E md5` — makes `ssh-keygen` output MD5 fingerprint to match Hetzner's format
- `regex_replace('^MD5:', '')` — strips the `MD5:` prefix from the output

### Updating hosts.ini automatically

After provisioning, write the real IP into `hosts.ini` so all subsequent playbooks work without manual edits:

```yaml
- name: Update hosts.ini with real IP
  ansible.builtin.lineinfile:
    path: "{{ playbook_dir }}/../inventories/dev/hosts.ini"
    regexp: '^{{ hcloud_server_name }} ansible_host='
    line: "{{ hcloud_server_name }} ansible_host={{ hcloud_server.hcloud_server.ipv4_address }} ansible_user={{ admin_user_on_fresh_system }}"
```

- `lineinfile` — replaces a line matching `regexp`, or appends if no match found
- `playbook_dir` — built-in variable: the directory containing the running playbook
- `register` + `.hcloud_server.ipv4_address` — how to extract the IP from the server module's return value

### Server hostname constraint

Hetzner requires server names to be valid hostnames (RFC 952): lowercase letters, digits, hyphens only. **Underscores are not allowed.**

### Key SSH commands

```zsh
# Generate a dedicated key pair for Ansible (no passphrase for unattended access)
ssh-keygen -t ed25519 -C "ansible@hetzner" -f ~/.ssh/hetzner_ansible -N ""

# Show MD5 fingerprint (matches Hetzner's format)
ssh-keygen -E md5 -lf ~/.ssh/hetzner_ansible.pub
```

### Hetzner server types (quick reference)

| Series | CPU | Best for |
|---|---|---|
| `cx*` | Intel/AMD shared | General purpose |
| `cpx*` | AMD EPYC shared | Slightly cheaper per core |
| `cax*` | Ampere ARM shared | Best price/performance (EU only) |
| `ccx*` | AMD dedicated | Production, no noisy-neighbour |

Full table with pricing: `inventories/dev/group_vars/hcloud_type/vars.yml`
Locations: `inventories/dev/group_vars/hcloud_location/vars.yml`

---

## 13. ansible.cfg

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

## 14. Useful Commands

| Command | Purpose |
|---|---|
| `ansible-inventory -i <inv> --list` | Parse and display inventory as JSON |
| `ansible -i <inv> all -m ping` | Test SSH connectivity to all hosts |
| `ansible-playbook -i <inv> <playbook>` | Run a playbook |
| `ansible-playbook ... -e "key=val"` | Run with extra variable override |
| `ansible-doc ansible.builtin.debug` | Show module documentation |

---

## 15. Project Layout (so far)

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
│           ├── webservers.yml
│           ├── hcloud_location/
│           │   └── vars.yml   ← location reference table + hcloud_default_location
│           └── hcloud_type/
│               └── vars.yml   ← server type reference table + hcloud_default_type
├── playbooks/
│   ├── hello.yml
│   ├── loops_and_conditions.yml
│   ├── handlers_demo.yml
│   ├── site.yml
│   └── provision_hetzner.yml  ← provisions VM via Hetzner API
└── roles/
    └── common/
        ├── tasks/
        │   └── main.yml
        └── templates/
            └── motd.j2
```

---

## 16. Next Topics

- Test SSH connectivity to live VM: `ansible all -m ping`
- `ansible.builtin.apt` for package management
- `ansible.builtin.service` for service management
- Real template deploy: `ansible.builtin.template` writing `motd.j2` to `/etc/motd`
- Server hardening playbook (SSH config, firewall, unattended-upgrades)
- Dynamic inventory with the Hetzner Cloud plugin
