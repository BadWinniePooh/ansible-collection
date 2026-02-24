# Active Context

## Current Branch / Scope

`learning` — Ansible fundamentals

## Session State

All 11 foundation iterations completed. Memory bank created to persist context
across sessions. About to move into real infrastructure.

## Immediate Next Step

**Iteration 12 — Real SSH targets (Hetzner Cloud)**

1. Learner provisions a Hetzner Cloud VM (or provides existing IPs)
2. Replace `<PLACEHOLDER>` values in `inventories/dev/hosts.ini`
3. Set up SSH key access from WSL2 to the VM
4. Run first real connectivity test: `ansible all -m ping`
5. Run first real template deploy: `ansible.builtin.template` writing `motd.j2` to `/etc/motd`

## Open Items / Decisions Pending

- Hetzner Cloud API token → will be stored in Vault as `vault_hetzner_api_token`
- SSH key location on WSL: `~/.ssh/` — needs to be created/configured
- Vault password strategy: `--ask-vault-pass` for now, `~/.vault_pass` file later

## How to Resume a Session

When starting a new chat, provide this prompt:

> "Read memory-bank-branches/learning/activeContext.md and the other files
> in memory-bank-branches/learning/ to restore context, then continue from
> where we left off."

GitHub Copilot should read all 6 files in `memory-bank-branches/learning/` before proceeding.
