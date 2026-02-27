# Progress — docker-runner

## Completed Iterations

| # | Topic | Key Files | Status |
|---|---|---|---|
| — | memory-bank-branch created | `memory-bank-branches/docker-runner/` | done |
| 1 | Dockerfile + entrypoint | `docker/Dockerfile`, `docker/entrypoint.sh`, `.dockerignore` | done |
| 2 | Build verification | `docker build` clean, entrypoint error + playbook list verified | done |
| 3 | Run a real playbook | `destroy.yml` via `docker run` with vault + extra-vars, WSL Docker fixed | done |
| 4 | README / usage docs | `.docker/README.md`, entrypoint ANSIBLE_VAULT_PASSWORD_FILE check added | done |
| 5 | CI/CD foundation | `.github/workflows/docker-publish.yml`, `.docker/tests.yaml`, multi-platform build, cosign signing, ubuntu:24.04 upgrade | done |
| 6 | Image size optimisation | `.docker/Dockerfile` multi-stage build — builder + runtime stages | done |
| 7 | CI status badge | decided not needed — discarded | cancelled |
| 8 | Renovate for `ansible-core` | regex manager verified correct; live run confirms on next merge to main | done |
| 9 | Dynamic inventory | `inventories/hcloud.yml`, `ansible.cfg`, provisioners updated | done |

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
- `ansible-core` version pinned in Dockerfile (`==2.20.3`) — reproducible builds
- Ubuntu 24.04 ships Python 3.12; `ansible-core >=2.18` requires Python >=3.11, `>=2.20` requires Python >=3.12 — base image and version pin must stay in sync
- Ubuntu 24.04 enforces PEP 668 (externally managed Python); `pip3 install pipx` fails — install `pipx` from apt instead
- `pipx inject -r <file>` not supported in the apt-bundled pipx version on Ubuntu 24.04 — use `pipx runpip <venv> install -r <file>` to keep `requirements.txt` as single source of truth
- `pipx runpip <venv> <pip-args>` runs pip inside a specific pipx-managed venv without hardcoding venv paths
- `container-structure-test` version regex in `tests.yaml` must be updated when `ansible-core` major/minor version changes
- `local_action: { module: ... }` (mapping syntax) deprecated since ansible-core 2.20, removed in 2.23 — use `delegate_to: localhost` + FQCN (`ansible.builtin.shell`, `ansible.builtin.known_hosts`, etc.)
- Static `hosts.ini` with `<PLACEHOLDER>` IP triggers three `[WARNING]: inventory` log lines on every run after deprovisioning — ini parser rejects the placeholder as invalid; fix is dynamic inventory (`hetzner.hcloud.hcloud` plugin, iteration 9)
- `interpreter_python = auto_silent` in `ansible.cfg` — localhost tasks use the pipx-venv Python (has `requests`/`hcloud`); remote hosts auto-discover `/usr/bin/python3` without a warning; replaces the earlier `ansible_python_interpreter` group_var approach which broke localhost module imports
- `ansible.posix` collection emits a deprecation warning about `ansible.module_utils._text` import — this is inside the collection's own code, not fixable here; will be resolved by a future `ansible.posix` release; Renovate will open the PR automatically
- `hetzner.hcloud.hcloud` dynamic inventory plugin replaces `hosts.ini`; token via `HCLOUD_TOKEN` env var (vault blob approach does not work — plugin runs before vault is decrypted); `filters: label_selector: platform=linux` constrains discovery; `groups: hcloud_type: true` + `mordor: true` ensure group_vars load correctly
- `requests==2.32.3` added to `requirements.txt` — `hcloud` SDK 2.x dropped it as a transitive dep but `hetzner.hcloud` collection `module_utils` still imports it directly
- `ansible.cfg` `interpreter_python = auto_silent` resolves both the interpreter discovery warning and the `requests` import error on localhost tasks (pipx venv Python is used for localhost; auto-discovered for remotes)
- Multi-stage Dockerfile: `builder` installs build tools (pipx, git, pip) and runs `pipx install` + `ansible-galaxy`; `runtime` copies only `/root/.local` (venv + wrappers) and `/root/.ansible` (collections) from builder — final image contains no compilers, pip, or git
- `container-structure-test` (Google) used to validate the built image against a YAML spec — runs inside CI, no Ansible install needed on the runner
- GitHub Actions workflow: `build` job pushes to ghcr.io; `test` job runs on a matrix of `ubuntu-24.04` (amd64) and `ubuntu-24.04-arm` (arm64)
- cosign + sigstore Fulcio used to sign the pushed image digest — supply-chain security
- `cache-from: type=gha` / `cache-to: type=gha,mode=max` — BuildKit GHA cache drastically speeds up repeat builds
- `workflow_dispatch` trigger allows manual pipeline runs from the GitHub UI
- `GITHUB_TOKEN` used for ghcr.io login — no extra secrets needed for registry auth
- PR builds skip the push step (`push: ${{ github.event_name != 'pull_request' }}`) — safe validation without publishing
- Test job pulls `:latest` on PRs (validates against existing image) and the newly pushed image on main/tags

## Remaining Roadmap

All planned iterations complete or cancelled. The docker-runner memory branch is closed.

