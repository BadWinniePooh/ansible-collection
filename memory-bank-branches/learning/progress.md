# Progress

## Completed Iterations

| # | Topic | Key Files | Status |
|---|---|---|---|
| 1 | Control node setup (WSL2 + ansible-core) | — | done |
| 2 | Static inventory | `inventories/dev/hosts.ini` | done |
| 3 | First playbook + ad-hoc commands | `playbooks/hello.yml` | done |
| 4 | Inline variables + `-e` CLI override | `playbooks/hello.yml` | done |
| 5 | `group_vars` + variable precedence | `inventories/dev/group_vars/` | done |
| 6 | Loops (`loop:`) + conditionals (`when:`) | `playbooks/loops_and_conditions.yml` | done |
| 7 | Handlers | `playbooks/handlers_demo.yml` | done |
| 8 | Roles + `ansible.cfg` | `roles/common/`, `playbooks/site.yml`, `ansible.cfg` | done |
| 9 | Jinja2 Templates | `roles/common/templates/motd.j2` | done |
| 10 | Tags (`--tags`, `--skip-tags`) | `roles/common/tasks/main.yml` | done |
| 11 | Ansible Vault | `inventories/dev/group_vars/all/vault.yml` | done |

## Key Concepts Learned

- Variable precedence chain: `group_vars/all < group_vars/<group> < host_vars < play vars < -e`
- `gather_facts: false` required for unreachable hosts
- `lookup('template', ...)` renders Jinja2 locally without SSH
- `ansible.cfg` ignored on WSL `/mnt/c/` — workaround: `ANSIBLE_CONFIG` env var
- Vault `vault_` prefix convention for safe secret referencing
- Role task names appear prefixed: `<role> : <task name>`
- Tags allow surgical task execution without changing playbooks

## Remaining Roadmap

| # | Topic | Notes |
|---|---|---|
| 12 | Real SSH targets | Provision Hetzner Cloud VM, replace placeholder IPs |
| 13 | `ansible.builtin.apt` | Package management on real host |
| 14 | `ansible.builtin.service` | Service management |
| 15 | Real template deploy | `ansible.builtin.template` with `dest:` on live host |
| 16 | Server hardening playbook | SSH config, firewall, unattended-upgrades |
| 17 | Dynamic inventory | Hetzner Cloud plugin |
