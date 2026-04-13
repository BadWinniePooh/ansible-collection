# Quickstart: Consolidate Developer Tool Installation via Homebrew

**Branch**: `001-brew-package-manager-consolidation`

## Prerequisites

- Ansible installed on the control node
- A fresh Hetzner Cloud Ubuntu 24.04 server with SSH access
- An inventory file with the target host configured
- `desktop_users` variable defined (list of objects with a `name` field)
- Desktop user home directories must exist on the target server before running

## Run the Playbook

```bash
ansible-playbook playbooks/setup-desktop.yml -i <inventory>
```

## Verify After Provisioning

SSH to the target server as a desktop user and confirm:

```bash
# Homebrew
brew --version

# GitHub CLI
gh --version

# Fast Node Manager
fnm --version

# Node and npm (via fnm default)
node --version
npm --version

# Claude Code CLI
claude --version

# VS Code (snap)
code --version

# Firefox
firefox --version
```

All commands should return version output without errors.

## Idempotency Check

Run the playbook a second time against the same server:

```bash
ansible-playbook playbooks/setup-desktop.yml -i <inventory>
```

Expected result: zero failed tasks. Changed task count should be 0 (or equal only to tasks that were legitimately non-idempotent before this feature, if any).

## Key Variable

| Variable | Description | Example |
|----------|-------------|---------|
| `desktop_users` | List of desktop user objects | `[{name: "alice"}, {name: "bob"}]` |
| `my_hetzner_config.ansible_user.name` | Ansible connection user | `"ubuntu"` |
