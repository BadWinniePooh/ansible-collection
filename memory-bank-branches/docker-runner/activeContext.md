# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Iteration 5 in progress:
- `docker/` directory renamed to `.docker/`
- Dockerfile updated: pinned `ansible-core==2.17.14`, added `python3-venv`, ENTRYPOINT path corrected to `/ansible/.docker/entrypoint.sh`
- `entrypoint.sh` expanded: now checks for SSH key and vault.yml presence in addition to vault password
- `.docker/tests.yaml` added: container-structure-test specs for `ansible-playbook --version`, `hetzner.hcloud`, `ansible.posix`, `community.general`
- `.github/workflows/docker-publish.yml` added: builds multi-platform image (`linux/amd64` + `linux/arm64`), pushes to `ghcr.io/badwinniepooh/ansible-runner`, signs with cosign, runs container-structure-test matrix on both architectures
- Several fix commits stabilising the workflow (permissions, entrypoint path, test content)

## Immediate Next Step

Verify CI/CD pipeline passes end-to-end on GitHub Actions, then decide:
- Declare Iteration 5 complete and docker-runner scope done, or
- Continue with additional improvements (e.g. publish README badge, multi-stage build for size)

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
