# Progress — docker-runner

## Completed Iterations

| # | Topic | Key Files | Status |
|---|---|---|---|
| — | memory-bank-branch created | `memory-bank-branches/docker-runner/` | done |
| 1 | Dockerfile + entrypoint | `docker/Dockerfile`, `docker/entrypoint.sh`, `.dockerignore` | done |
| 2 | Build verification | `docker build` clean, entrypoint error + playbook list verified | done |
| 3 | Run a real playbook | `destroy.yml` via `docker run` with vault + extra-vars, WSL Docker fixed | done |

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
- `requirements.yml` and `tasks/` files must be excluded from entrypoint playbook listing — they are not runnable playbooks
- Entrypoint args (`$@`) are passed to `ansible-playbook` after the playbook path — overriding entrypoint needed to run arbitrary container commands
- `**/vault.yml` excluded via `.dockerignore` — Ansible Vault secrets must never be baked into the image; mount at runtime
- Entrypoint warns (non-fatal) if vault.yml is not mounted — lets non-vault playbooks run without obstruction
- Rancher Desktop (not Docker Desktop) requires WSL integration enabled under Preferences → WSL → Integrations
- `--extra-vars "key=value"` passed as CMD args flows correctly through `"$@"` in the entrypoint
- Running from WSL is required — PowerShell misinterprets `--` flags as operators
- `changed=0` on destroy when server already gone — idempotent, correct behaviour

## Remaining Roadmap

| # | Topic | Notes |
|---|---|---|
| 3 | Run a real playbook | `docker run` with PLAYBOOK + vault mount |
| 4 | README / usage docs | Document build + run commands |
| 5 | CI/CD foundation (optional) | GitHub Actions or similar |

