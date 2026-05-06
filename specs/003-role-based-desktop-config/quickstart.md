# Quickstart: Role-Based Desktop Configuration

**Feature**: `003-role-based-desktop-config`

## Overview

The desktop configuration pipeline is driven by a provider+platform vars file that declares
an ordered `active_roles` list. The entry-point playbook loads the vars file, creates users,
then executes each listed role in order.

## Running a Full Hetzner Provision

```bash
ansible-playbook ./provision.yml \
  --extra-vars "provider=hetzner platform=linux" \
  --vault-password-file ~/.vault_pass
```

This is unchanged from before. `provision.yml` calls `configurations/configure-linux.yml`
which reads `configurations/vars/hetzner-linux.yml` and runs all nine roles.

## Running Only Configuration (skip provisioning)

```bash
ansible-playbook ./configurations/configure-linux.yml \
  --extra-vars "provider=hetzner platform=linux" \
  --vault-password-file ~/.vault_pass
```

## Changing Which Roles Run

Edit `configurations/vars/hetzner-linux.yml` and remove (or comment out) any role you
do not want to run:

```yaml
# configurations/vars/hetzner-linux.yml
active_roles:
  - base_packages
  - dotnet
  # - firefox       ← commented out: Firefox will not be installed
  - homebrew
  - github_cli
  - fnm
  - claude_code
  - remote_desktop
  - vscode
```

No other files need to be changed.

## Running a Single Role

```bash
ansible-playbook ./configurations/configure-linux.yml \
  --extra-vars "provider=hetzner platform=linux active_roles=[dotnet]" \
  --vault-password-file ~/.vault_pass
```

Note: Overriding `active_roles` via extra-vars bypasses the vars file list. Use this for
targeted remediation only. The user setup play (`setup-users.yml`) always runs first.

## Skipping Remote Desktop (e.g. Docker/Vagrant targets)

The `remote_desktop` role carries the `not-supported-on-vagrant-docker` tag on all tasks.
Skip it with:

```bash
ansible-playbook ./provision.yml \
  --extra-vars "provider=hetzner platform=linux" \
  --skip-tags not-supported-on-vagrant-docker \
  --vault-password-file ~/.vault_pass
```

## Adding a New Provider+Platform

1. Create `configurations/vars/<provider>-<platform>.yml` with an `active_roles` list.
2. Run with `--extra-vars "provider=<provider> platform=<platform>"`.
3. No other files need to change.

Example:

```yaml
# configurations/vars/other-linux.yml
active_roles:
  - base_packages
  - homebrew
  - github_cli
```

## Role Dependency Notes

The following roles declare dependencies in their `meta/main.yml`:

| Role | Depends On |
|------|-----------|
| `github_cli` | `homebrew` |
| `fnm` | `homebrew` |
| `claude_code` | `fnm` (which depends on `homebrew`) |

When using the `active_roles` loop, Ansible processes `meta/main.yml` dependencies
automatically. However, the convention is to include the dependency role explicitly in the
`active_roles` list to keep the configuration readable and self-documenting.
