# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

All iterations complete. The docker-runner memory branch is closed.

**Final state:**
- Iterations 1–6, 9: done
- Iteration 7 (CI badge): cancelled — decided not needed
- Iteration 8 (Renovate ansible-core): done — regex manager verified correct in `renovate.json`
- Open branches pending merge to main: `feature/dynamic-inventory`, `fix/hcloud-token-env-var`, `fix/ansible-deprecation-warnings`, `feature/multi-stage-build`

## Immediate Next Step

None — work on this branch is complete.

## Open Items / Decisions Pending

- None

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
