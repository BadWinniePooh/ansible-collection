# Implementation Plan: Docker Image Update Notification

**Branch**: `002-docker-image-update-notification` | **Date**: 2026-04-13 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-docker-image-update-notification/spec.md`

## Summary

Add a `version_check()` bash function to `.docker/entrypoint.sh` that reads `/ansible/VERSION` at container startup, queries the GitHub Releases API using Python3 stdlib, and prints a notice if a newer image version is available — silently suppressing all errors. The VERSION file is written at Docker build time via a new `IMAGE_VERSION` build ARG, and the CI workflow passes the git tag as the ARG value on tag-triggered builds.

## Technical Context

**Language/Version**: Bash (entrypoint), Dockerfile, YAML (GitHub Actions), Python3 (stdlib inline call)
**Primary Dependencies**: Python3 urllib (already present in runtime image), GitHub Releases API (unauthenticated)
**Storage**: `/ansible/VERSION` plain-text file written at image build time
**Testing**: Manual container runs per acceptance scenarios in spec
**Target Platform**: Docker container on Ubuntu 24.04 LTS (Hetzner Cloud)
**Project Type**: Infrastructure / DevOps tooling
**Performance Goals**: Version check adds at most 3 seconds of latency (timeout enforced)
**Constraints**: No new packages added to image (no curl); all errors silently suppressed; string equality comparison only
**Scale/Scope**: Single container entrypoint; 3 files touched

## Constitution Check

No violations. This is a small, self-contained enhancement touching exactly 3 files. No new dependencies, no new services, no architectural changes.

## Project Structure

### Documentation (this feature)

```text
specs/002-docker-image-update-notification/
├── plan.md              # This file (/speckit.plan command output)
└── spec.md              # Feature specification
```

### Source Code (files touched)

```text
.docker/
├── Dockerfile           # Add IMAGE_VERSION ARG + write VERSION file
└── entrypoint.sh        # Add version_check() function, call at top

.github/workflows/
└── docker-publish.yml   # Pass --build-arg IMAGE_VERSION=${{ github.ref_name }}
```

**Structure Decision**: This feature modifies 3 existing files only. No new source directories or modules are introduced.

## Implementation Steps

### Step 1 — `.docker/Dockerfile`

In the runtime stage, add:

```dockerfile
ARG IMAGE_VERSION=dev
# ... (COPY . /ansible and RUN chmod +x must appear first — see ordering note below)
RUN echo "${IMAGE_VERSION}" > /ansible/VERSION
```

The `ARG` must be declared after the `FROM` of the runtime stage (ARGs do not persist across stages). The `RUN` writes the version string so it is baked into every image layer.

**Ordering constraint**: The `RUN echo "${IMAGE_VERSION}" > /ansible/VERSION` line must be placed **after** `COPY . /ansible` (and after `RUN chmod +x /ansible/.docker/entrypoint.sh`). Placing it before `COPY` would cause the COPY instruction to overwrite the freshly written file with whatever is on the host filesystem.

**`.dockerignore` requirement**: Add `VERSION` to `.dockerignore`. Without this, a locally leftover `VERSION` file in the working tree would be copied into the image by `COPY . /ansible` immediately before the `RUN echo` step, and while the subsequent `RUN echo` would still overwrite it, the stale file could cause confusion during debugging. Excluding it is the correct hygiene.

**Scheduled and manually dispatched builds**: On `workflow_dispatch` and `schedule` triggers, `github.ref_name` resolves to the branch name (e.g. `main`). These builds will therefore write `main` as the version string. The `version_check()` function will silently skip the update check because `main` will never match a release tag returned by the GitHub Releases API. This behaviour is acceptable per spec — no special handling is required.

### Step 2 — `.github/workflows/docker-publish.yml`

In the `build-push-action` step, add to the `build-args` input:

```yaml
build-args: |
  IMAGE_VERSION=${{ github.ref_name }}
```

On tag-triggered builds `github.ref_name` is the tag (e.g. `v1.2.3`). On branch builds it is the branch name, which the version check function treats as `dev`-equivalent (no notification shown since it will not match a release tag).

### Step 3 — `.docker/entrypoint.sh`

Define and call `version_check()` at the very top of the script (before the existing vault/SSH/vault-file warning checks):

```bash
version_check() {
  local current_version latest_version
  current_version=$(cat /ansible/VERSION 2>/dev/null | tr -d '[:space:]') || return 0
  [[ -z "$current_version" || "$current_version" == "dev" ]] && return 0
  latest_version=$(python3 -c "
import urllib.request, json, sys
try:
    req = urllib.request.Request(
        'https://api.github.com/repos/BadWinniePooh/ansible-collection/releases/latest',
        headers={'Accept': 'application/vnd.github+json'}
    )
    with urllib.request.urlopen(req, timeout=3) as r:
        print(json.load(r)['tag_name'])
except Exception:
    sys.exit(1)
" 2>/dev/null) || return 0
  [[ -z "$latest_version" ]] && return 0
  if [[ "$current_version" != "$latest_version" ]]; then
    echo "Notice: A newer image version is available: ${latest_version} (you have ${current_version}). Pull the latest image to update."
  fi
}

version_check
```

Key design decisions:
- `|| return 0` on every failure point ensures `set -euo pipefail` cannot propagate errors out of the function.
- `2>/dev/null` on the python3 call suppresses all stderr.
- `timeout=3` in Python3 urllib enforces the 3-second cap from FR-008.
- String inequality check covers all edge cases: `dev`, branch names, pre-release tags all silently produce no output.
- Missing `/ansible/VERSION` is handled by `2>/dev/null || return 0` on the `cat` call.

## Complexity Tracking

No constitution violations. No complexity justification required.
