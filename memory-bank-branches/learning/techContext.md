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
- `ANSIBLE_CONFIG` must be exported explicitly due to WSL world-writable mount.
  Managed via `direnv` + `.envrc` in the repo root (not hardcoded in `~/.zshrc`):
  ```bash
  # .envrc (committed to repo)
  export ANSIBLE_CONFIG="$(pwd)/ansible.cfg"
  ```
  Prerequisites (one-time WSL setup):
  ```bash
  sudo apt install direnv
  echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc
  source ~/.zshrc
  direnv allow   # run once in repo root
  ```
  `ANSIBLE_CONFIG` is then set automatically on `cd` into the repo and unset on `cd` away.

## Repository

- Path (Windows): `C:\Users\NRueber\source\repos\private\ansible`
- Path (WSL): `/mnt/c/Users/NRueber/source/repos/private/ansible`
- Git branch: `main`
- Remote: not yet configured

## Managed Nodes

- Currently placeholder hosts only (`<PLACEHOLDER>` IPs in inventory)
- No live SSH targets yet
- Next target: Hetzner Cloud Linux VMs
