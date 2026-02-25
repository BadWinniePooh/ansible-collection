# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Iteration 3 complete:
- `destroy.yml` run via `docker run` from WSL with vault.yml + vault_pass mounts and `--extra-vars`
- WSL Docker access fixed via Rancher Desktop WSL integration toggle
- Confirmed `"$@"` in entrypoint correctly forwards extra-vars to ansible-playbook

## Immediate Next Step

**Iteration 4 — README / usage docs**

Write a `docker/README.md` documenting how to build the image and run any playbook,
including the required runtime mounts and common examples.

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
