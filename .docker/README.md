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
docker build -t ansible-runner -f .docker/Dockerfile .
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
  -v ./inventories/group_vars/all/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/vault.password:/vault_pass:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ansible-runner \
  --extra-vars "provider=hetzner platform=linux"
```

### Detached mode (background)

Add `-d` and `--name` to run the playbook in the background and return immediately:

```bash
docker run -d --rm \
  --name ansible-provision \
  -e PLAYBOOK=provision.yml \
  -v ./inventories/group_vars/all/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/vault.password:/vault_pass:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ansible-runner \
  --extra-vars "provider=hetzner platform=linux"
```

Follow the output:

```bash
docker logs -f ansible-provision
```

> `--rm` still applies in detached mode — the container is removed automatically when the playbook finishes.

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
| `ANSIBLE_VAULT_PASSWORD_FILE` | No | Defaults to `/vault_pass`. Override only if you mount the password file at a different path. |

---

## Available playbooks

Run the container with no `PLAYBOOK` set to see the current list:

```bash
docker run --rm ansible-runner
```

---

## Verify image signature

Every image pushed to `ghcr.io` is signed with [cosign](https://github.com/sigstore/cosign)
using **keyless signing** — no static key is stored anywhere. The signature is bound to
the GitHub Actions OIDC identity of this repo's workflow.

Install cosign:

```bash
brew install cosign        # macOS / WSL with brew
# or: https://github.com/sigstore/cosign/releases
```

Verify:

```bash
cosign verify \
  --certificate-identity "https://github.com/BadWinniePooh/ansible-private-test/.github/workflows/docker-publish.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/badwinniepooh/ansible-runner:latest
```

A successful verification prints the signing certificate fields and the Rekor transparency log entry.
If the image was tampered with or signed by a different workflow, cosign exits non-zero.

> **Tip:** the exact `--certificate-identity` value is printed in the cosign error message if you
> get it wrong — use that output to copy the correct subject.

---

## Notes

- Extra flags (`--extra-vars`, `--tags`, `--check`, etc.) are passed directly
  after the image name and forwarded to `ansible-playbook`
- The entrypoint prints warnings for missing mounts before running — useful for
  diagnosing failed runs
- `ANSIBLE_CONFIG` is set to `/ansible/ansible.cfg` inside the container — no
  `direnv` needed
