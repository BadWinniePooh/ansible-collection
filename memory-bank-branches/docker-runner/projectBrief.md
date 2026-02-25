# Project Brief — docker-runner

## Purpose

Build a Docker image that packages this Ansible repo and can run any playbook
inside a container — no local Ansible installation required on the host.

## Goals

- Any playbook in the repo can be executed by passing `PLAYBOOK=<path>` at runtime
- Inventory and playbooks are baked into the image (rebuild = update)
- Vault password is supplied at runtime via a mounted file (no secrets in image)
- Extra-vars and any other `ansible-playbook` flags are passed as CMD args
- Image is the canonical way to run Ansible for this repo in CI/CD later

## Usage Interface (target)

```bash
docker run --rm \
  -e PLAYBOOK=provision.yml \
  -v ~/.vault_pass:/vault_pass:ro \
  -v /path/to/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  ansible-runner \
  --extra-vars "provider=hetzner platform=linux"
```

## Collaboration Rules

- Same iteration structure as the learning branch (one topic per step)
- Every completed step ends with a git commit
- Full rules in `GUIDELINES.md`
