# System Patterns

## Project Conventions

### Directory Structure
```
ansible/
├── GUIDELINES.md
├── ansible.cfg
├── memory-bank/           ← session context and knowledge persistence
├── docs/
│   └── notes.md           ← human-readable learning reference
├── inventories/
│   └── dev/
│       ├── hosts.ini
│       └── group_vars/
│           ├── all/
│           │   ├── vars.yml    ← plain variables (references vault_ vars)
│           │   └── vault.yml   ← AES256 encrypted secrets
│           └── webservers.yml
├── playbooks/
│   └── site.yml           ← main entry point
└── roles/
    └── <role>/
        ├── tasks/main.yml
        ├── handlers/main.yml
        ├── templates/         ← .j2 files
        ├── files/
        ├── vars/main.yml      ← high-precedence role vars
        └── defaults/main.yml  ← low-precedence role defaults
```

### Naming Conventions
- Playbooks: `snake_case.yml`
- Roles: `snake_case`
- Variables: `snake_case`
- Vault secrets: prefixed with `vault_` (e.g. `vault_db_password`)
- Plain wrapper variable: same name without prefix (e.g. `db_password`)

### Vault Pattern
```
group_vars/all/vault.yml  → vault_db_password: "secret"
group_vars/all/vars.yml   → db_password: "{{ vault_db_password }}"
```
Playbooks always reference the plain wrapper, never the `vault_` variable directly.

### ansible.cfg
```ini
[defaults]
inventory  = inventories/dev/hosts.ini
roles_path = roles
```
Loaded via `ANSIBLE_CONFIG` env var due to WSL world-writable directory restriction.

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
