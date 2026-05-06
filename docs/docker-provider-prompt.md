Feature: Docker provider for local Ansible testing

Add a `provider=docker` execution path so the existing `provision.yml` / `destroy.yml` 
entry points can target a local Docker container instead of a Hetzner VM.

## Goal
Enable full ansible-playbook runs (setup-users, setup-desktop subset) against a local 
Docker container for fast, cost-free testing — no Hetzner account or API token required.

## Invocation (must work as-is)
docker run --rm \
  -e PLAYBOOK=provision.yml \
  -v ./inventories/group_vars/all/vault.yml:/ansible/inventories/group_vars/all/vault.yml:ro \
  -v ~/vault.password:/vault_pass:ro \
  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro \
  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ansible-runner \
  --extra-vars "provider=docker platform=linux"

## What provision does (provider=docker)
1. Build or pull a Docker target image (Ubuntu 22.04 + sshd + sudo + python3).
2. Start the target container on a dedicated bridge network, exposing SSH.
3. Add the container's IP/hostname to the in-memory Ansible inventory (group: all).
4. Run the same configure-linux.yml pipeline as the Hetzner path.

## What destroy does (provider=docker)
Stop and remove the target container. Remove known_hosts entry if present.

## Compatibility guards
Tasks incompatible with Docker must be skipped gracefully:
- Snap packages (VS Code)
- XRDP / XFCE service start/enable
- Any task that requires systemd

Guard mechanism: tag `not-supported-on-docker` or `when: provider != 'docker'` condition.
setup-desktop.yml already uses `tags: not-supported-on-vagrant-docker` on the play level — 
extend or adopt this pattern.

## Target Docker image requirements
- Ubuntu 22.04 base
- openssh-server running on port 22
- sudo, python3 pre-installed
- Root or initial user accepts the mounted SSH public key at startup

## Constraints
- Must NOT require docker-compose (single docker run UX preserved).
- Vault file and SSH key mounts remain identical to Hetzner path.
- HCLOUD_TOKEN env var must be optional (absent = docker provider assumed or explicit).
- No new top-level entry point files — reuse provision.yml / destroy.yml.

## Success criteria
- `provider=docker` run completes without error.
- Target container has the users from setup-users.yml created with correct sudo access.
- Target container has apt packages from setup-desktop.yml (excluding snap/XRDP tasks).
- `destroy.yml provider=docker` removes the target container cleanly.