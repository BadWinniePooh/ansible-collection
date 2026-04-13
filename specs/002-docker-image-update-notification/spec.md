# Feature Specification: Docker Image Update Notification

**Feature Branch**: `002-docker-image-update-notification`  
**Created**: 2026-04-13  
**Status**: Draft  
**Input**: User description: "At container startup (in .docker/entrypoint.sh), before running ansible-playbook, check whether a newer image version is available and notify the user if so."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Outdated image notification at startup (Priority: P1)

A user runs the ansible-runner container. Their local image was built from an older git tag. Before the playbook executes, they see a notice telling them the current version and the latest available version so they can decide whether to pull the newer image.

**Why this priority**: This is the core deliverable. Without this story, the feature has no value.

**Independent Test**: Run a container whose `/ansible/VERSION` contains an older tag (e.g. `v1.0.0`) while the GitHub Releases API returns a newer tag (e.g. `v1.2.0`). Verify that the update notice is printed before the playbook output and shows both versions.

**Acceptance Scenarios**:

1. **Given** the container has `/ansible/VERSION` = `v1.0.0`, **When** the GitHub Releases API returns `tag_name` = `v1.2.0`, **Then** a notice is printed that includes both `v1.0.0` (current) and `v1.2.0` (available) before `ansible-playbook` runs.
2. **Given** the container has `/ansible/VERSION` = `v1.2.0`, **When** the GitHub Releases API returns `tag_name` = `v1.2.0`, **Then** no version-related output is printed.

---

### User Story 2 - Silent failure on unreachable API (Priority: P1)

A user runs the container in an air-gapped environment or with no internet access. The GitHub Releases API call fails (timeout, DNS error, HTTP error). The container starts normally and runs the playbook with no version-related output at all.

**Why this priority**: Equally critical as P1 — the silent-failure guarantee is a hard requirement. Breaking this would cause containers to hang or emit noise in production environments.

**Independent Test**: Run the container with network disabled (`--network none`) or pointed at an unreachable API URL. Verify the playbook still executes and there is no version-related output or error message.

**Acceptance Scenarios**:

1. **Given** the GitHub API is unreachable (no network), **When** the container starts, **Then** the playbook runs normally with no extra output.
2. **Given** the GitHub API returns a non-200 HTTP status, **When** the container starts, **Then** the playbook runs normally with no extra output.
3. **Given** the API call times out after 3 seconds, **When** the container starts, **Then** the container does not stall and the playbook runs normally.

---

### User Story 3 - Dev build skips update check output (Priority: P2)

A developer builds the image locally without passing `IMAGE_VERSION`. The `/ansible/VERSION` file contains `dev`. When the container starts, no update notification is shown (because `dev` is not a release tag and will never equal any GitHub release tag).

**Why this priority**: Prevents false positives and noise for developers doing local builds. Important for DX but does not affect production users.

**Independent Test**: Build the image without `--build-arg IMAGE_VERSION` (so `/ansible/VERSION` = `dev`). Run the container and verify no update-check output appears regardless of what the API returns.

**Acceptance Scenarios**:

1. **Given** `/ansible/VERSION` = `dev`, **When** the GitHub API returns any release tag, **Then** no version-related output is printed.

---

### User Story 4 - VERSION file written correctly at CI build time (Priority: P2)

When a GitHub Actions workflow builds the image for a git tag push (e.g. `v1.2.3`), the resulting image has `/ansible/VERSION` = `v1.2.3`.

**Why this priority**: Without this, the update check can never work correctly in released images.

**Independent Test**: Inspect a CI-built image for a tagged release and verify `cat /ansible/VERSION` returns the expected tag.

**Acceptance Scenarios**:

1. **Given** a CI build triggered by pushing tag `v1.2.3`, **When** the image is built with `--build-arg IMAGE_VERSION=v1.2.3`, **Then** `cat /ansible/VERSION` inside the running container returns `v1.2.3`.
2. **Given** a local build with no `--build-arg IMAGE_VERSION`, **When** the image is built, **Then** `cat /ansible/VERSION` returns `dev`.

---

### Edge Cases

- What happens when `/ansible/VERSION` does not exist (e.g. older image without this feature)? The version check function must handle a missing file silently without causing a `set -euo pipefail` failure.
- What happens when the API response body is malformed or `tag_name` is absent? The `grep`/`sed` parse must return an empty string; the function must then skip the comparison silently.
- What happens when `curl` is not present in the runtime image? Not applicable — curl will not be added; Python3 (already present in the runtime stage) is used instead via inline `python3 -c "import urllib.request, json; ..."` to avoid increasing image size or attack surface.
- What if the user is running a version newer than the latest published release (e.g. a pre-release or hotfix)? No notification should be shown — the check should only notify when the API tag is strictly newer.
- What happens when the VERSION file exists but is empty or contains only whitespace? The function must treat this the same as `dev` — no notification.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Dockerfile MUST accept a build ARG `IMAGE_VERSION` with a default value of `dev`.
- **FR-002**: The Dockerfile MUST write the value of `IMAGE_VERSION` to `/ansible/VERSION` in the runtime stage, so it is present in all images regardless of how they are built.
- **FR-003**: The GitHub Actions `docker-publish.yml` workflow MUST pass `--build-arg IMAGE_VERSION=${{ github.ref_name }}` to the `build-push-action` step. This argument is only meaningful on tag-triggered builds; it is harmless on branch builds (will result in a branch name in VERSION, which the check treats like `dev`).
- **FR-004**: The entrypoint script (`.docker/entrypoint.sh`) MUST define a `version_check()` bash function that:
  - Reads `/ansible/VERSION`; if missing or empty, returns silently.
  - If version is `dev`, returns silently.
  - Queries `https://api.github.com/repos/BadWinniePooh/ansible-collection/releases/latest` using Python3 stdlib inline: `python3 -c "import urllib.request, json; print(json.load(urllib.request.urlopen('URL'))['tag_name'])"`. Python3 is already present in the runtime stage; curl is NOT added.
  - If `tag_name` extraction yields an empty string or the Python3 call fails for any reason, returns silently.
  - Compares the current version against `tag_name` using string equality; if they differ, prints a notice showing both versions.
  - All errors (network failures, parse failures, any subshell errors) are suppressed without any output to stdout or stderr.
- **FR-005**: The `version_check()` function MUST be called at the very top of `.docker/entrypoint.sh`, before the existing vault/SSH/vault-file warning checks and before the playbook is executed. This ensures the update notice is the first thing the user sees.
- **FR-006**: The update notice MUST clearly state the current version and the available version (e.g. `"Notice: A newer image version is available: v1.2.3 (you have v1.0.0). Pull the latest image to update."`).
- **FR-007**: The version_check function MUST NOT use `set -e` propagation to exit the script on any failure — all internal errors must be caught within the function.
- **FR-008**: The Python3 urllib call MUST use a short timeout (3 seconds) to avoid blocking container startup.

### Key Entities

- **VERSION file** (`/ansible/VERSION`): A plain-text file containing the image's version string (e.g. `v1.2.3` or `dev`). Written at Docker build time, read at container startup.
- **GitHub Releases API response**: JSON response from `https://api.github.com/repos/BadWinniePooh/ansible-collection/releases/latest`. The relevant field is `tag_name` (a string like `"v1.2.3"`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A container built from a tag-triggered CI build has `cat /ansible/VERSION` return the exact git tag (e.g. `v1.2.3`).
- **SC-002**: A container built locally without `IMAGE_VERSION` build arg has `cat /ansible/VERSION` return `dev`.
- **SC-003**: When the container version is older than the latest GitHub release, the update notice appears in stdout before any `Running: ansible-playbook ...` line.
- **SC-004**: When the GitHub API is unreachable, the container starts and reaches `exec ansible-playbook` within the same time it would take without the version check (i.e., the 3-second curl timeout is the maximum added latency).
- **SC-005**: No output related to versioning appears when the container version matches the latest release.
- **SC-006**: No output related to versioning appears when `/ansible/VERSION` = `dev`.

## Assumptions

- `curl` is NOT added to the runtime image. Python3 (already present) is used instead via inline `python3 -c "import urllib.request, json; ..."`. This avoids increasing image size or attack surface. [RESOLVED: do not add curl]
- The version comparison is string equality only: if the VERSION file string does not equal the API `tag_name`, a notice is shown. No semver ordering (greater-than comparison) is attempted. Rationale: `dev` will never match a release tag; releases are monotonically increasing; the primary use case is detecting when you're behind. No semver library or complex bash semver parsing is needed. [RESOLVED: string inequality is sufficient]
- The `version_check()` function is called at the very top of the entrypoint, before the existing vault/SSH/vault-file warning checks. This ensures the update notice is the first thing the user sees. [RESOLVED: place at top, before existing warnings]
- Only the `releases/latest` API endpoint is used (not listing all releases). This means pre-releases are not considered — only the latest stable release.
- The GitHub API is queried without authentication (unauthenticated). Rate limits (60 requests/hour/IP) are sufficient for typical usage.
- The `tag_name` is extracted directly from the parsed JSON using Python3 stdlib: `json.load(urllib.request.urlopen(url))['tag_name']`. No grep/sed/jq needed.
