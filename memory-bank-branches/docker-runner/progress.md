# Progress — docker-runner

## Completed Iterations

| # | Topic | Key Files | Status |
|---|---|---|---|
| — | memory-bank-branch created | `memory-bank-branches/docker-runner/` | done |
| 1 | Dockerfile + entrypoint | `docker/Dockerfile`, `docker/entrypoint.sh`, `.dockerignore` | done |
| 2 | Build verification | `docker build` clean, entrypoint error + playbook list verified | done |
| 3 | Run a real playbook | `destroy.yml` via `docker run` with vault + extra-vars, WSL Docker fixed | done |
| 4 | README / usage docs | `.docker/README.md`, entrypoint ANSIBLE_VAULT_PASSWORD_FILE check added | done |
| 5 | CI/CD foundation | `.github/workflows/docker-publish.yml`, `.docker/tests.yaml`, multi-platform build, cosign signing | in progress |

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
- `ANSIBLE_VAULT_PASSWORD_FILE` commented out in Dockerfile — must be passed explicitly via `-e` at runtime (no default in image)
- Docker security warning on `ENV` for `ANSIBLE_VAULT_PASSWORD_FILE` is a false positive (it's a file path, not a secret) — but removing it from the image default is cleaner practice
- `docker/` renamed to `.docker/` — hidden directory keeps repo root cleaner
- `ansible-core` version pinned in Dockerfile (`==2.17.14`) — reproducible builds
- `container-structure-test` (Google) used to validate the built image against a YAML spec — runs inside CI, no Ansible install needed on the runner
- GitHub Actions workflow: `build` job pushes to ghcr.io; `test` job runs on a matrix of `ubuntu-24.04` (amd64) and `ubuntu-24.04-arm` (arm64)
- cosign + sigstore Fulcio used to sign the pushed image digest — supply-chain security
- `cache-from: type=gha` / `cache-to: type=gha,mode=max` — BuildKit GHA cache drastically speeds up repeat builds
- `workflow_dispatch` trigger allows manual pipeline runs from the GitHub UI
- `GITHUB_TOKEN` used for ghcr.io login — no extra secrets needed for registry auth
- PR builds skip the push step (`push: ${{ github.event_name != 'pull_request' }}`) — safe validation without publishing
- Test job pulls `:latest` on PRs (validates against existing image) and the newly pushed image on main/tags

## Remaining Roadmap

| # | Topic | Notes |
|---|---|---|
| 5 | CI/CD foundation | Verify pipeline passes end-to-end; declare complete |

