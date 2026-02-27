# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Iteration 6 committed (branch `feature/multi-stage-build`), not yet merged to `main`.
Deprecation fix committed (branch `fix/ansible-deprecation-warnings`), not yet merged to `main`.

Iteration 6 delivered:
- Multi-stage Dockerfile: `builder` stage installs all tooling; `runtime` stage copies only `/root/.local` (pipx venv) and `/root/.ansible` (collections) — no compilers or build tools in final image
- Docker section added to repo root `README.md`

Deprecation fix delivered (branch `fix/ansible-deprecation-warnings`):
- `local_action` mapping syntax replaced with `delegate_to: localhost` + FQCN in `tasks/add-server-to-known-hosts.yml`
- Silences both `DEPRECATION WARNING: Using a mapping for action` warnings ahead of ansible-core 2.23 removal

## Immediate Next Step

Merge open branches to `main`, verify CI passes, then proceed with roadmap:
- Iteration 7: CI status badge in `README.md`
- Iteration 8: Verify Renovate custom regex manager for `ansible-core`
- Iteration 9: Dynamic inventory via `hetzner.hcloud.hcloud` plugin

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
