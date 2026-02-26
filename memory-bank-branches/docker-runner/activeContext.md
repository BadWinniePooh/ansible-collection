# Active Context — docker-runner

## Current Branch / Scope

`docker-runner` — Dockerised Ansible runner

## Session State

Iterations 5 and 6 complete. Starting iteration 9 (pulled forward) — dynamic inventory.

Iteration 6 delivered:
- `.docker/Dockerfile` converted to multi-stage build: `builder` stage installs all tooling; `runtime` stage copies only `/root/.local` and `/root/.ansible` — no compilers/pip/git in final image
- Docker section added to repo root `README.md`

Also completed (branch `fix/ansible-deprecation-warnings`):
- `local_action` mapping syntax replaced with `delegate_to: localhost` + FQCN in `tasks/add-server-to-known-hosts.yml`
- `ansible_python_interpreter: /usr/bin/python3` added to `group_vars/all/vars.yml` — silences interpreter auto-discovery warning

## Immediate Next Step

Iteration 9: replace `inventories/hosts.ini` static inventory with the `hetzner.hcloud.hcloud` dynamic inventory plugin.
- Remove `<PLACEHOLDER>` IP pattern and manual `hosts.ini` updates from provision/destroy workflow
- Configure the plugin to discover servers by label or group matching existing Hetzner Cloud setup
- Update `ansible.cfg` inventory path accordingly
- Verify `provision.yml` and `destroy.yml` still work end-to-end

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
