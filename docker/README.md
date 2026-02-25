# ansible-runner Docker Image

Packages this Ansible repo into a portable container. Run any playbook without
a local Ansible installation — only Docker and your secret files are needed on
the host.

---

## Prerequisites

- [Rancher Desktop](https://rancherdesktop.io/) (or Docker Desktop) running
- WSL distro integration enabled in Rancher Desktop → Preferences → WSL → Integrations
- The following files on your host:
  - `inventories/group_vars/all/vault.yml` — encrypted Ansible Vault secrets
  - `~/vault.password` — vault password file
  - `~/.ssh/hetzner_ansible` + `~/.ssh/hetzner_ansible.pub` — SSH key pair

---

## Build

Run from the **repo root**:

```bash
docker build -t ansible-runner -f docker/Dockerfile .
```

Rebuild whenever you change `requirements.yml` (collection dependencies) or the
`Dockerfile` itself. For playbook-only changes, rebuild to bake the latest code
in — the collection install layer will be cached.

---

## Run

All `docker run` commands must be executed from the **repo root in WSL** (not PowerShell).

### Full example — provision

```bash
docker run --rm \
  -e PLAYBOOK=provision.yml \
  -e ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass \
  -v ./inventories/group_vars/all/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/vault.password:/vault_pass:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ansible-runner \
  --extra-vars "provider=hetzner platform=linux"
```

### Full example — destroy

```bash
docker run --rm \
  -e PLAYBOOK=destroy.yml \
  -e ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass \
  -v ./inventories/group_vars/all/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/vault.password:/vault_pass:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ansible-runner \
  --extra-vars "provider=hetzner platform=linux"
```

---

## Required runtime mounts

| What | Host path | Container path |
|---|---|---|
| Vault secrets | `./inventories/group_vars/all/vault.yml` | `/ansible/inventories/group_vars/all/vault.yml` |
| Vault password | `~/vault.password` | `/vault_pass` |
| SSH private key | `~/.ssh/hetzner_ansible` | `/root/.ssh/hetzner_ansible` |
| SSH public key | `~/.ssh/hetzner_ansible.pub` | `/root/.ssh/hetzner_ansible.pub` |

All mounts use `:ro` (read-only). **None of these files are baked into the image.**

---

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `PLAYBOOK` | Yes | Path to the playbook relative to repo root (e.g. `provision.yml`) |
| `ANSIBLE_VAULT_PASSWORD_FILE` | Yes (if vault used) | Path to vault password file inside the container (e.g. `/vault_pass`) |

---

## Available playbooks

Run the container with no `PLAYBOOK` set to see the current list:

```bash
docker run --rm ansible-runner
```

---

## Notes

- Extra flags (`--extra-vars`, `--tags`, `--check`, etc.) are passed directly
  after the image name and forwarded to `ansible-playbook`
- The entrypoint prints warnings for missing mounts before running — useful for
  diagnosing failed runs
- `ANSIBLE_CONFIG` is set to `/ansible/ansible.cfg` inside the container — no
  `direnv` needed
