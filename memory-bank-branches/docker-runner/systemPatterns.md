# System Patterns — docker-runner

## Directory Structure

```
ansible/
├── docker/
│   ├── Dockerfile
│   └── entrypoint.sh
└── ... (rest of existing repo)
```

## Dockerfile Pattern

```
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3 python3-pip pipx git openssh-client
RUN pipx install ansible-core
RUN pipx inject ansible-core hcloud passlib
RUN /root/.local/bin/ansible-galaxy collection install hetzner.hcloud

ENV PATH="/root/.local/bin:$PATH"
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg
ENV ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass

WORKDIR /ansible
COPY . /ansible

ENTRYPOINT ["docker/entrypoint.sh"]
```

## Entrypoint Pattern

```bash
#!/bin/bash
set -euo pipefail

if [[ -z "${PLAYBOOK:-}" ]]; then
  echo "ERROR: PLAYBOOK env var is required."
  echo "Usage: docker run -e PLAYBOOK=provision.yml ... <image> [extra-args]"
  exit 1
fi

exec ansible-playbook "$PLAYBOOK" "$@"
```

## Runtime Usage Pattern

```bash
# Basic run
docker run --rm \
  -e PLAYBOOK=provision.yml \
  -e ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass \
  -v ~/vault.password:/vault_pass:ro \
  -v /path/to/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ansible-runner

# With extra-vars and tags
docker run --rm \
  -e PLAYBOOK=provision.yml \
  -e ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass \
  -v ~/vault.password:/vault_pass:ro \
  -v /path/to/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ansible-runner \
  --extra-vars "provider=hetzner platform=linux" \
  --tags provision
```

## Secrets at Runtime (never baked in)

| What | Mount path in container | How |
|---|---|---|
| Vault password | `/vault_pass` | `-v ~/vault.password:/vault_pass:ro` + `-e ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass` |
| Vault secrets file | `/ansible/inventories/group_vars/all/vault.yml` | `-v /path/to/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro` |
| SSH private key | `/root/.ssh/hetzner_ansible` | `-v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro` |
| SSH public key | `/root/.ssh/hetzner_ansible.pub` | `-v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro` |

## Build Pattern

```bash
docker build -t ansible-runner -f docker/Dockerfile .
```

Build context is always the repo root so `COPY . /ansible` captures everything.
