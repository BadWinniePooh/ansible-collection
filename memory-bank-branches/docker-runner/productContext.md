# Product Context — docker-runner

## Why This Exists

The Ansible control node is set up inside WSL2, which is fine for local use but
not portable or CI-friendly. Wrapping the repo in a Docker image makes it
runnable anywhere Docker is available, without WSL2 or a Python/Ansible install.

## End Goal

A lightweight, reproducible Docker image that:
- Contains all playbooks, roles, tasks, configurations, and templates from this repo
- Accepts a playbook selection via `PLAYBOOK` env var
- Accepts runtime flags (extra-vars, tags, etc.) via CMD args
- Reads the vault password from a mounted file — never baked in
- Can be used locally and as the basis for CI/CD pipelines later

## Non-Goals (for now)

- Dynamic inventory inside the container (deferred — planned as iteration 9; will replace static `hosts.ini` with the `hetzner.hcloud.hcloud` plugin)
- Multi-stage builds for size optimisation (deferred — planned as iteration 6; branch exists)
- Publishing to a container registry (deferred)
- Multi-stage builds for size optimisation (deferred)
