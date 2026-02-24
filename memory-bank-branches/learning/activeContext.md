# Active Context

## Current Branch / Scope

`learning` — Ansible fundamentals

## Session State

Iteration 12 complete. VM `mount-doom` running on Hetzner Cloud (`hel1`, `89.167.104.177`).
SSH connectivity confirmed (`ansible all -m ping` returns `pong`).
Ready for iteration 13: package management with `ansible.builtin.apt`.

## Immediate Next Step

**Iteration 13 — Package management (`ansible.builtin.apt`)**

Install packages on `mount-doom` using `ansible.builtin.apt`.

## Open Items / Decisions Pending

- Vault password strategy: still `--ask-vault-pass`; `~/.vault_pass` file later
- `web01` placeholder line still in `hosts.ini` (harmless, can clean up on commit)

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
