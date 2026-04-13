---

description: "Task list for 002-docker-image-update-notification"
---

# Tasks: Docker Image Update Notification

**Input**: Design documents from `/specs/002-docker-image-update-notification/`
**Prerequisites**: plan.md (complete), spec.md (complete)
**Tests**: Not requested in spec — no test tasks included.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- No tests included (not requested in spec)

---

## Phase 1: Foundational — Write VERSION at build time

**Purpose**: Write the VERSION file into the image at build time. All user stories depend on this file existing. Must be complete before entrypoint changes can be validated.

**⚠️ CRITICAL**: T001 and T002 must be complete before T003 can be fully tested end-to-end.

- [ ] T001 [P] [US4] Add `ARG IMAGE_VERSION=dev` and `RUN echo "${IMAGE_VERSION}" > /ansible/VERSION` to the runtime stage of `.docker/Dockerfile`. The `ARG` line goes after the `FROM` of the runtime stage. The `RUN echo` line must come **after** `COPY . /ansible` (and after `RUN chmod +x /ansible/.docker/entrypoint.sh`) — placing it before `COPY` would cause the COPY to overwrite the file.
- [ ] T002 [P] [US4] Add `IMAGE_VERSION=${{ github.ref_name }}` to the `build-args` block of the `Build and push Docker image` step in `.github/workflows/docker-publish.yml`. The step currently has no `build-args` key — add it as a new `build-args:` input under the `with:` block.

- [ ] T004 [P] [US4] Add `VERSION` to `.dockerignore` so that any locally existing `VERSION` file in the working tree cannot be accidentally copied into the image by `COPY . /ansible`, masking the build-arg value.

**Checkpoint**: Build the image locally with and without `--build-arg IMAGE_VERSION=v1.0.0`. Confirm `cat /ansible/VERSION` returns `v1.0.0` and `dev` respectively (US4 acceptance scenarios).

---

## Phase 2: Core Feature — version_check() in entrypoint

**Purpose**: Implement the update notification logic. Depends on Phase 1 (VERSION file must exist in the image for end-to-end validation).

- [ ] T003 [US1, US2, US3] Add the `version_check()` bash function definition and its call to `.docker/entrypoint.sh`, inserted at the top of the script immediately after the `set -euo pipefail` line and before the variable declarations. Implement exactly per plan.md Step 3.

**Checkpoint — US1 (Outdated image notification)**: Run a container with `/ansible/VERSION` = `v1.0.0` (override via build-arg or volume) while the GitHub Releases API returns a newer tag. Verify the update notice appears before any `Running: ansible-playbook` output.

**Checkpoint — US2 (Silent failure)**: Run the container with `--network none`. Verify the playbook still executes and no version-related output appears.

**Checkpoint — US3 (Dev build skips check)**: Build without `--build-arg IMAGE_VERSION` so VERSION = `dev`. Run the container and verify no version-related output appears.

---

## Dependencies & Execution Order

- **T001**, **T002**, and **T004** are independent of each other and can be done in parallel (different files).
- **T003** can be started at any time but requires T001 to be complete for full end-to-end testing (the VERSION file must exist in the image).
- Commit order recommendation: T001 + T002 + T004 together (one commit for "bake VERSION into image"), then T003 (one commit for "add version_check() to entrypoint").

---

## Notes

- No new packages are added to the image. Python3 urllib is used for the HTTP call (already present in runtime stage).
- All errors in `version_check()` are silently suppressed — the function must never cause the script's `set -euo pipefail` to terminate the container.
- The version comparison is string equality only. No semver parsing.
- The GitHub API call uses a 3-second timeout (FR-008). This is the maximum added latency on network failure.
