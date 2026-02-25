# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Iteration 1 complete:
- `docker/Dockerfile` — Ubuntu 22.04, pipx, ansible-core 2.17.14, hcloud + passlib, hetzner.hcloud collection
- `docker/entrypoint.sh` — validates PLAYBOOK env var, lists available playbooks on error, execs ansible-playbook
- `.dockerignore` — excludes .git, memory-bank-branches/, .envrc

## Immediate Next Step

**Iteration 2 — Build verification**

Run `docker build -t ansible-runner -f docker/Dockerfile .` and verify the image
builds cleanly, ansible-playbook is available, and the entrypoint error message
works (run with no PLAYBOOK set).

## Open Items / Decisions Pending

- None currently

## Git Notes

- The terminal is always already in the repo root — **do not `cd` before running `git` commands**, it will fail.

## How to Resume a Session

When starting a new chat, paste this prompt verbatim:

---

> You are GitHub Copilot, my Ansible learning partner. We are working on wrapping this Ansible repo in a Docker image.
>
> Before doing anything else, read all 6 files in `memory-bank-branches/docker-runner/` to fully restore context:
> - `activeContext.md` — current state and immediate next step
> - `progress.md` — completed iterations and remaining roadmap
> - `projectBrief.md` — goals and usage interface
> - `productContext.md` — end goals and non-goals
> - `techContext.md` — host + container environment details
> - `systemPatterns.md` — Dockerfile, entrypoint, and runtime patterns
>
> Also read `GUIDELINES.md` in the repo root for the collaboration rules we agreed on.
>
> Once you have read all files, confirm what you know about the current state and immediately continue from where we left off — do not re-explain things already covered.

---
