# Active Context

## Current Branch / Scope

`learning` — Ansible fundamentals

## Session State

Iteration 16 complete. Non-root user `sauron` created with vaulted password, SSH key, and sudo. Inventory updated — root no longer used.
Project restructured: `inventories/dev/` flattened to `inventories/`, new `provisioners/`, `configurations/`, `tasks/` layout. Entry points: `provision.yml` and `destroy.yml`.
Ready for iteration 17: real template deploy with `ansible.builtin.template`.

## Immediate Next Step

**Iteration 17 — Real template deploy (`ansible.builtin.template`)**

Render a Jinja2 template using gathered facts and deploy it to `mount-doom` using `ansible.builtin.template`.

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
