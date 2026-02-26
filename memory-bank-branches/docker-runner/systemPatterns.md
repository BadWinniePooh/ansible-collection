# System Patterns — docker-runner

## Directory Structure

```
ansible/
├── .docker/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── README.md
│   └── tests.yaml
├── .github/
│   └── workflows/
│       └── docker-publish.yml
└── ... (rest of existing repo)
```

## Dockerfile Pattern

```
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv pipx git openssh-client \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.local/bin:$PATH"

COPY requirements.txt /tmp/requirements.txt
RUN pipx install ansible-core==2.20.3 \
  && pipx runpip ansible-core install -r /tmp/requirements.txt

COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml

ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

WORKDIR /ansible
COPY . /ansible

RUN chmod +x /ansible/.docker/entrypoint.sh
ENTRYPOINT ["/ansible/.docker/entrypoint.sh"]
```

Key changes from original pattern:
- Base image upgraded to `ubuntu:24.04` (Python 3.12)
- `pipx` installed via apt — avoids PEP 668 "externally managed" error on Ubuntu 24.04
- `pipx inject -r <file>` not supported in apt-bundled pipx; replaced with `pipx runpip <venv> install -r <file>`
- `requirements.txt` is single source of truth for Python deps — no duplication in Dockerfile
- `requirements.txt` copied before `RUN` for independent layer caching
- `ansible-core` version pinned for reproducible builds
- ENTRYPOINT uses absolute path inside the container

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
  -v ~/vault.password:/vault_pass:ro \
  -v /path/to/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  ansible-runner

# With extra-vars and tags
docker run --rm \
  -e PLAYBOOK=provision.yml \
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
| Vault password | `/vault_pass` | `-v ~/vault.password:/vault_pass:ro` (default path; override with `-e ANSIBLE_VAULT_PASSWORD_FILE=...`) |
| Vault secrets file | `/ansible/inventories/group_vars/all/vault.yml` | `-v /path/to/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro` |
| SSH private key | `/root/.ssh/hetzner_ansible` | `-v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro` |
| SSH public key | `/root/.ssh/hetzner_ansible.pub` | `-v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro` |

## Build Pattern

```bash
docker build -t ansible-runner -f .docker/Dockerfile .
```

Build context is always the repo root so `COPY . /ansible` captures everything.

## CI/CD Workflow Pattern

`.github/workflows/docker-publish.yml` — triggers on push to `main`, semver tags, PRs, weekly cron, and `workflow_dispatch`.

```
jobs:
  build:
    - Checkout repo
    - Install cosign (non-PR only)
    - Set up Docker Buildx
    - Login to ghcr.io (non-PR only)
    - Extract metadata (tags/labels)
    - Build + push multi-platform image (linux/amd64, linux/arm64)
      file: .docker/Dockerfile, context: .
      push: skipped on PRs
      cache: type=gha
    - Sign image digest with cosign (non-PR only)

  test:
    needs: build
    strategy.matrix: [ubuntu-24.04/amd64, ubuntu-24.04-arm/arm64]
    - Checkout repo
    - Login to ghcr.io
    - docker pull ghcr.io/badwinniepooh/ansible-runner:latest
    - Install container-structure-test
    - Run: container-structure-test test --image ... --config .docker/tests.yaml
```

## Container-Structure-Test Pattern

`.docker/tests.yaml` — validates the built image without running Ansible:

```yaml
schemaVersion: 2.0.0
commandTests:
  - name: "ansible-playbook is available"
    command: "ansible-playbook"
    args: [ "--version" ]
    expectedOutput: [ "ansible-playbook \\[core 2\\.17\\." ]
  - name: "hetzner.hcloud collection is installed"
    ...
```
