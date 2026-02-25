# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Memory-bank-branch created. No files written to `docker/` yet.

## Immediate Next Step

**Iteration 1 — Dockerfile + entrypoint**

Create `docker/Dockerfile` and `docker/entrypoint.sh` to package this repo as a
runnable Ansible container, with `PLAYBOOK` env var selecting the playbook and
vault password supplied via a mounted file.

## Open Items / Decisions Pending

- `.dockerignore`: decide what to exclude (memory-bank-branches, .git, etc.)
- Whether to pin `ansible-core` version in Dockerfile or float to latest

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
