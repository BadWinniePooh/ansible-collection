# Progress — docker-runner

## Completed Iterations

| # | Topic | Key Files | Status |
|---|---|---|---|
| — | memory-bank-branch created | `memory-bank-branches/docker-runner/` | done |
| 1 | Dockerfile + entrypoint | `docker/Dockerfile`, `docker/entrypoint.sh`, `.dockerignore` | done |

## Key Concepts (docker-runner)

- Build context must be repo root so `COPY . /ansible` captures all playbooks/roles
- `DEBIAN_FRONTEND=noninteractive` prevents apt prompts blocking the build
- `pipx inject ansible-core hcloud passlib` adds Python deps into Ansible's isolated venv
- `ansible-galaxy collection install` runs at build time — no internet needed at runtime
- `ANSIBLE_CONFIG` set as ENV var in image (replaces direnv inside the container)
- `ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass` — file must be mounted at runtime, never baked in
- Entrypoint prepends `/ansible/` to `$PLAYBOOK` so user only needs to pass e.g. `provision.yml`
- Entrypoint lists available playbooks if `PLAYBOOK` is unset — helpful error UX
- `.dockerignore` excludes `.git`, `memory-bank-branches/`, `.envrc` to keep image clean

## Remaining Roadmap

| # | Topic | Notes |
|---|---|---|
| 2 | Build verification | `docker build`, inspect layers, confirm ansible runs |
| 3 | Run a real playbook | `docker run` with PLAYBOOK + vault mount |
| 4 | README / usage docs | Document build + run commands |
| 5 | CI/CD foundation (optional) | GitHub Actions or similar |
