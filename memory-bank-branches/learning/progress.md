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
| 12 | Hetzner Cloud provisioning | `playbooks/provision_hetzner.yml`, `group_vars/hcloud_location/`, `group_vars/hcloud_type/` | done |
| 13 | Deprovision Hetzner VM | `playbooks/deprovision_hetzner.yml` | done |
| 14 | `ansible.builtin.apt` | `playbooks/manage_packages.yml` | done |

## Key Concepts Learned

- Variable precedence chain: `group_vars/all < group_vars/<group> < host_vars < play vars < -e`
- `gather_facts: false` required for unreachable hosts
- `lookup('template', ...)` renders Jinja2 locally without SSH
- `ansible.cfg` ignored on WSL `/mnt/c/` — workaround: `ANSIBLE_CONFIG` env var
- Vault `vault_` prefix convention for safe secret referencing
- Role task names appear prefixed: `<role> : <task name>`
- `group_vars/<group>/` only loads for hosts in that group — use `vars_files:` to load explicitly in `localhost` plays
- Hetzner fingerprints are MD5 format; `ssh-keygen` defaults to SHA256 — use `-E md5` flag to match
- `hetzner.hcloud` collection requires `pipx inject ansible-core hcloud` for the Python SDK
- `lineinfile` module for idempotently updating a line in a file by regexp
- `playbook_dir` built-in variable: directory of the currently running playbook
- Hetzner server names must be valid hostnames — no underscores
- `ansible.builtin.service` `state: started` + `enabled: true` starts and enables a service on boot
- `state: absent` with `apt` removes packages — used to eliminate conflicting services
- `gnome-remote-desktop` must be removed on Ubuntu 24.04 before xrdp works
- `light-locker` must be removed to prevent black screen over RDP in xfce4
- `xfce4-session` is the correct session command for RDP (not `startxfce4`)
- `passlib` must be injected via `pipx inject ansible-core passlib` for `password_hash` filter
- Handlers fire once at end of play, regardless of how many tasks notify them
- `remote_user:` in a play overrides `ansible_user` from inventory for that play only
- `delegate_to: localhost` runs a task on the control node instead of the remote host
- Passwordless sudo is unsafe; use `ALL=(ALL) ALL` and a vaulted password instead
- `validate: /usr/sbin/visudo -cf %s` prevents writing a broken sudoers file
- `password_hash('sha512')` requires `passlib` on the control node
- `ansible.builtin.known_hosts` with `state: absent` is idempotent — no error if entry doesn't exist
- Ansible auto-adds hosts to `known_hosts` on first connection (e.g. via `ping` module)
- `ansible.builtin.apt` `state: present` is idempotent — reports `ok` if package already installed
- `cache_valid_time: 3600` skips `apt update` if cache is fresher than 1 hour
- Packages pre-installed on Ubuntu 24.04 image: `vim`, `curl`, `htop` — not `tree`

## Remaining Roadmap

| # | Topic | Notes |
|---|---|---|
| 15 | Remote desktop (XRDP) | `playbooks/setup_remote_desktop.yml` | done |
| 16 | Non-root admin user | `playbooks/create_admin_user.yml` | done |
| 17 | Real template deploy | `ansible.builtin.template` with `dest:` on live host |
| 18 | Server hardening playbook | SSH config, firewall, unattended-upgrades |
| 19 | Dynamic inventory | Hetzner Cloud plugin |
