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

When starting a new chat, paste this prompt verbatim:

---

> You are GitHub Copilot, my Ansible learning partner. We have been working through a structured, step-by-step Ansible learning project together.
>
> Before doing anything else, read all 6 files in `memory-bank-branches/learning/` to fully restore context:
> - `activeContext.md` — current state and immediate next step
> - `progress.md` — completed iterations and remaining roadmap
> - `projectBrief.md` — learner profile and collaboration rules
> - `productContext.md` — end goals and learning philosophy
> - `techContext.md` — WSL2/Ansible environment details
> - `systemPatterns.md` — conventions, directory layout, vault pattern
>
> Also read `GUIDELINES.md` in the repo root for the collaboration rules we agreed on.
>
> Once you have read all files, confirm what you know about the current state and immediately continue from where we left off — do not re-explain things already covered.

---
