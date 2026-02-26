# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Iteration 5 complete. Iteration 6 starting — image size optimisation via multi-stage build.

Iteration 5 delivered:
- Base image upgraded from `ubuntu:22.04` to `ubuntu:24.04` (Python 3.12)
- `ansible-core` bumped to `2.20.3` (requires Python >=3.12, now satisfied)
- `pipx` installed via apt to avoid PEP 668 failure on Ubuntu 24.04
- `pipx inject -r` replaced with `pipx runpip ansible-core install -r` — keeps `requirements.txt` as single source of truth
- `tests.yaml` version regex updated from `2\.17\.` to `2\.20\.`
- Renovate confirmed to already handle GitHub Actions SHA pinning natively via `config:recommended`
- CI/CD pipeline verified end-to-end

## Immediate Next Step

Iteration 6: convert `.docker/Dockerfile` to a multi-stage build.
- Stage 1 (`builder`): install all build-time deps, pipx, ansible-core, collections
- Stage 2 (`runtime`): copy only the pipx venv, collections, and playbooks — no compilers, no apt package cache

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
