# Active Context

## Current Branch / Scope

`learning` — Ansible fundamentals

## Session State

Infrastructure fixes applied this session (no new iteration number — these are corrections):
- `inventories/hosts.ini` recreated (was lost during iter-16 restructure); auto-written by provisioner
- `ANSIBLE_CONFIG` now managed via `direnv` + `.envrc` (not hardcoded in `~/.zshrc`)
- `ansible_ssh_private_key_file` added to `group_vars/hcloud_type/vars.yml`
- Flat `my_*` vars in `group_vars/all/vars.yml` consolidated into `my_hetzner_config` dict
- Inventory group renamed from `webservers` to `mordor`; provisioner writes it dynamically
- `.gitignore` created
- `hetzner-linux-down.yml` reset-placeholder task uncommented and updated
- `setup-desktop.yml` running (install minimal GNOME desktop task in progress on mount-doom)

Ready for iteration 17 once `configure-linux.yml` finishes successfully.

## Immediate Next Step

**Iteration 17 — Real template deploy (`ansible.builtin.template`)**

Render a Jinja2 template using gathered facts and deploy it to `mount-doom` using `ansible.builtin.template`.

## Open Items / Decisions Pending

- Vault password strategy: still `--ask-vault-pass`; `~/.vault_pass` file later
- `direnv allow` must be run once in WSL after `sudo apt install direnv` + hook in `~/.zshrc`

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
