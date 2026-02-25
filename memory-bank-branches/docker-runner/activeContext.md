# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Iteration 4 complete:
- `docker/README.md` written with build + run + mounts + env vars reference
- `entrypoint.sh` updated to warn when `ANSIBLE_VAULT_PASSWORD_FILE` is not set
- `ANSIBLE_VAULT_PASSWORD_FILE` confirmed removed from Dockerfile default; passed explicitly at runtime
- Provision run verified end-to-end: `ok=11` on localhost, `ok=23 changed=17` on mount-doom

## Immediate Next Step

**Iteration 5 — CI/CD foundation (optional)**

Or declare the docker-runner scope complete. Discuss with learner.

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
