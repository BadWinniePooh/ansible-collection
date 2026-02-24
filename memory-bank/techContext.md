# Tech Context

## Control Node

| Property | Value |
|---|---|
| OS | Windows 11 with WSL2 |
| WSL distro | Ubuntu 22.04.3 LTS |
| Shell | zsh (oh-my-zsh) |
| Ansible install method | pipx (`pipx install ansible-core`) |
| Ansible version | core 2.17.14 |
| Python version | 3.10.12 |

## Environment Setup

- `pipx` installs `ansible-core` into an isolated venv at `~/.local/pipx/venvs/ansible-core/`
- All CLI tools (`ansible`, `ansible-playbook`, etc.) are symlinked to `~/.local/bin/`
- `~/.local/bin` is on PATH via `~/.zshrc`
- `ANSIBLE_CONFIG` must be exported explicitly due to WSL world-writable mount:
  ```zsh
  export ANSIBLE_CONFIG=/mnt/c/Users/NRueber/source/repos/private/ansible/ansible.cfg
  ```
  This is set in `~/.zshrc`.

## Repository

- Path (Windows): `C:\Users\NRueber\source\repos\private\ansible`
- Path (WSL): `/mnt/c/Users/NRueber/source/repos/private/ansible`
- Git branch: `main`
- Remote: not yet configured

## Managed Nodes

- Currently placeholder hosts only (`<PLACEHOLDER>` IPs in inventory)
- No live SSH targets yet
- Next target: Hetzner Cloud Linux VMs
