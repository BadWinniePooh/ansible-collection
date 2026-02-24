# Active Context

## Current Branch / Scope

`learning` — Ansible fundamentals

## Session State

Iteration 14 complete. `manage_packages.yml` installs vim, curl, htop, tree on `mount-doom` using `ansible.builtin.apt`.
Ready for iteration 15: service management with `ansible.builtin.service`.

## Immediate Next Step

**Iteration 15 — Service management (`ansible.builtin.service`)**

Manage services on `mount-doom` using `ansible.builtin.service`.

## Open Items / Decisions Pending

- Vault password strategy: still `--ask-vault-pass`; `~/.vault_pass` file later
- `web01` placeholder line still in `hosts.ini` (harmless, can clean up on commit)

## Git Notes

- The terminal is always already in the repo root — **do not `cd` before running `git` commands**, it will fail.

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
