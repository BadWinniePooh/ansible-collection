# Ansible Infrastructure

Ansible project for provisioning and configuring Linux servers on Hetzner Cloud.

Covers the full lifecycle: provisioning a VM, configuring users and a desktop environment, and deprovisioning when done.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Windows 11 + WSL2 | Ubuntu 22.04 recommended as the control node |
| `pipx` | Install via `sudo apt install pipx && pipx ensurepath` |
| `ansible-core` | Installed into an isolated pipx venv (see below) |
| Hetzner Cloud account | API token required for provisioning |

---

## Setup

### 1. Install ansible-core

```zsh
pipx install ansible-core
```

### 2. Install project dependencies

Ansible collections and Python packages are tracked in requirements files:

```zsh
ansible-galaxy collection install -r requirements.yml
pipx inject ansible-core -r requirements.txt
```

`requirements.yml` installs the `hetzner.hcloud` and `ansible.posix` collections.  
`requirements.txt` injects `hcloud` (Hetzner Python SDK) and `passlib` (password hashing) into the `ansible-core` venv.

### 3. Configure ANSIBLE_CONFIG

The project root lives on a WSL-mounted Windows drive (`/mnt/c/`), which is world-writable. Ansible ignores `ansible.cfg` there by default. Work around it by exporting the path explicitly — add to `~/.zshrc`:

```zsh
export ANSIBLE_CONFIG=/mnt/c/Users/<you>/source/repos/private/ansible/ansible.cfg
```

### 4. Create your vault file

Sensitive values (API token, passwords, SSH keys) are encrypted with Ansible Vault. Create `inventories/group_vars/all/vault.yml`:

```zsh
ansible-vault create inventories/group_vars/all/vault.yml
```

Required vault variables:

| Variable | Description |
|---|---|
| `vault_db_password` | Database password |
| `vault_my_ansible_user_password` | Password for the Ansible automation user (`morgoth`) |
| `vault_my_ssh_public` | Dict with `name` and `key` for the Hetzner SSH key |
| `vault_my_hetzner_api_token` | Hetzner Cloud API token |
| `vault_sauron` | Dict with `password` for the desktop user |

---

## Usage

### Provision + configure

```zsh
ansible-playbook ./provision.yml --extra-vars "provider=hetzner platform=linux" --ask-vault-pass
```

This provisions a Hetzner VM (`provisioners/hetzner-linux-up.yml`) and then configures it (`configurations/configure-linux.yml`).

### Deprovision

```zsh
ansible-playbook ./destroy.yml --extra-vars "provider=hetzner platform=linux" --ask-vault-pass
```

Deletes the server and cleans `known_hosts`. The dynamic inventory plugin automatically reflects the removed server on the next run.

---

## Docker

No local Ansible installation required — run any playbook inside the pre-built container image from `ghcr.io`.

### Build locally (optional)

```bash
docker build -t ansible-runner -f .docker/Dockerfile .
```

### Run a playbook

All `docker run` commands must be executed from the **repo root in WSL** (not PowerShell).

```bash
docker run --rm \
  -e PLAYBOOK=provision.yml \
  -e HCLOUD_TOKEN=<your-hetzner-api-token> \
  -v ./inventories/group_vars/all/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/vault.password:/vault_pass:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ghcr.io/badwinniepooh/ansible-runner:latest \
  --extra-vars "provider=hetzner platform=linux"
```

Replace `PLAYBOOK=provision.yml` with any playbook in the repo (e.g. `destroy.yml`).  
Extra flags (`--tags`, `--check`, etc.) are appended after the image name and forwarded directly to `ansible-playbook`.

### List available playbooks

Run without `PLAYBOOK` set to see what's available:

```bash
docker run --rm ghcr.io/badwinniepooh/ansible-runner:latest
```

> Full reference (mounts, env vars, detached mode, signature verification): [`.docker/README.md`](.docker/README.md)

---

## Project Structure

```
ansible/
├── provision.yml              ← entry point: provision + configure
├── destroy.yml                ← entry point: deprovision
├── requirements.yml           ← Ansible collection dependencies
├── requirements.txt           ← Python package dependencies (pipx inject)
├── ansible.cfg
├── inventories/
│   ├── hcloud.yml     ← dynamic inventory (hetzner.hcloud.hcloud plugin)
│   └── group_vars/
│       ├── all/
│       │   ├── vars.yml       ← plain variables (reference vault_ vars)
│       │   └── vault.yml      ← AES256 encrypted secrets (not committed as plaintext)
│       ├── hcloud_location/   ← Hetzner location reference table
│       └── hcloud_type/       ← Hetzner server type reference table + admin_user_on_fresh_system
├── provisioners/              ← cloud provider provisioning playbooks
│   ├── hetzner-linux-up.yml
│   └── hetzner-linux-down.yml
├── configurations/            ← OS configuration entry points
│   └── configure-linux.yml
├── playbooks/                 ← reusable playbooks (imported by configurations/)
│   ├── setup-users.yml
│   ├── setup-desktop.yml
│   ├── manage_packages.yml
│   └── demo/                  ← learning/demo playbooks
├── tasks/                     ← reusable task files
│   └── add-server-to-known-hosts.yml
├── roles/
│   └── common/
└── docs/
    └── notes.md               ← learning notes and quick reference
```
