# System Patterns

## Project Conventions

### Directory Structure
```
ansible/
├── GUIDELINES.md
├── ansible.cfg                ← points to inventories/hosts.ini
├── provision.yml              ← entry point: provision + configure
├── destroy.yml                ← entry point: deprovision
├── memory-bank-branches/      ← session context, scoped by learning branch
│   └── learning/
├── docs/
│   └── notes.md
├── inventories/
│   ├── hosts.ini              ← static inventory
│   └── group_vars/
│       ├── all/
│       │   ├── vars.yml       ← plain variables (references vault_ vars)
│       │   └── vault.yml      ← AES256 encrypted secrets
│       ├── hcloud_location/
│       │   └── vars.yml       ← Hetzner location reference table
│       ├── hcloud_type/
│       │   └── vars.yml       ← Hetzner server type reference table
│       └── webservers.yml
├── provisioners/              ← cloud provider provisioning playbooks
│   ├── hetzner-linux-up.yml
│   └── hetzner-linux-down.yml
├── configurations/            ← OS configuration entry points
│   └── configure-linux.yml
├── playbooks/                 ← reusable playbooks (imported by configurations/)
│   ├── setup-users.yml
│   ├── setup-desktop.yml
│   ├── manage_packages.yml
│   └── demo/                  ← learning/demo playbooks (not for production)
│       ├── hello.yml
│       ├── handlers_demo.yml
│       ├── loops_and_conditions.yml
│       └── site.yml
├── tasks/                     ← reusable task files (imported with import_tasks)
│   └── add-server-to-known-hosts.yml
└── roles/
    └── <role>/
        ├── tasks/main.yml
        ├── handlers/main.yml
        ├── templates/         ← .j2 files
        ├── files/
        ├── vars/main.yml
        └── defaults/main.yml
```

### Naming Conventions
- Playbooks: `kebab-case.yml` for production, `snake_case.yml` for demo/learning
- Roles: `snake_case`
- Variables: `snake_case`
- Vault secrets: prefixed with `vault_` (e.g. `vault_db_password`)
- Plain wrapper variable: same name without prefix (e.g. `db_password`)
- Colleague-convention secrets: prefixed with `my_` (e.g. `my_hetzner_config.api_token`)

### Vault Pattern
```
group_vars/all/vault.yml  → vault_db_password: "secret"
group_vars/all/vars.yml   → db_password: "{{ vault_db_password }}"
```
Playbooks always reference the plain wrapper, never the `vault_` variable directly.

### ansible.cfg
```ini
[defaults]
inventory  = inventories/hosts.ini
roles_path = roles
```
Loaded via `ANSIBLE_CONFIG` env var due to WSL world-writable directory restriction.

### Inventory Group Hierarchy
```ini
[hcloud_type:children]
webservers
dbservers
```
All Hetzner hosts inherit `group_vars/hcloud_type/vars.yml` (including `admin_user_on_fresh_system`) via this parent group — no need to duplicate in `group_vars/all/`.

### Provisioning Entry Points
```
provision.yml  → provisioners/<provider>-<platform>-up.yml
                → configurations/configure-<platform>.yml
destroy.yml    → provisioners/<provider>-<platform>-down.yml
```
Run with: `ansible-playbook ./provision.yml --extra-vars "provider=hetzner platform=linux" --ask-vault-pass`

### Task Naming
- Always include a descriptive `name:` on every task
- Role tasks appear as `<role> : <task name>` in output

### gather_facts
- Set `gather_facts: false` for plays targeting placeholder/unreachable hosts
- Enable for real hosts to access `ansible_*` facts (OS, IP, etc.)

## Git Commit Pattern
```
type(scope): short description

Body explaining what and why (not how).

Co-authored-by: GitHub Copilot <copilot@github.com>
```
Types used: `feat`, `docs`, `chore`, `fix`
