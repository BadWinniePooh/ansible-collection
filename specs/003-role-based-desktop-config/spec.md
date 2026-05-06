# Feature Specification: Role-Based Desktop Configuration

**Feature Branch**: `003-role-based-desktop-config`
**Created**: 2026-05-05
**Status**: Draft
**Input**: User description: "Role-based desktop configuration with provider-scoped role lists — Refactor the monolithic setup-desktop.yml playbook into discrete Ansible roles, replacing configurations/configure-linux.yml with a role-driven pipeline that loads an active_roles list from a provider+platform vars file."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Full Hetzner Provisioning Works Unchanged (Priority: P1)

An infrastructure operator runs the existing provision workflow against a Hetzner Linux server. The server is fully configured — users created, all desktop software installed — with the exact same end-state as the monolithic playbook produced before.

**Why this priority**: This is the non-regression guarantee. If P1 fails, the refactoring broke production workflows.

**Independent Test**: Run `provision.yml` against a fresh Hetzner Linux host and verify all expected software (base utilities, .NET SDKs, Firefox, Homebrew, GitHub CLI, fnm, Node 24, Claude Code CLI, VS Code, XFCE/XRDP) is installed and configured.

**Acceptance Scenarios**:

1. **Given** a fresh Hetzner Linux server, **When** `provision.yml` is executed, **Then** all software items from the original `setup-desktop.yml` are installed with the same configuration as before
2. **Given** the new entry point `configurations/configure-linux.yml`, **When** executed on a Hetzner Linux host, **Then** users are created before any role runs
3. **Given** the XRDP role tasks, **When** the play runs, **Then** all tasks carry the `not-supported-on-vagrant-docker` tag as in the original
4. **Given** a completed provisioning run, **When** XRDP is configured, **Then** the XRDP service is running and enabled

---

### User Story 2 - Selectively Enable/Disable Components per Provider (Priority: P2)

An infrastructure operator needs to provision a server that does not require certain software (e.g., remote desktop or .NET). They edit the provider vars file and remove the unwanted role names from `active_roles`. The next provisioning run skips those components without any playbook edits.

**Why this priority**: This is the primary reason for the refactoring — enabling operator control over the component set without touching playbook code.

**Independent Test**: Remove `dotnet` from `active_roles` in the Hetzner vars file and run provisioning; verify .NET SDKs are not installed and no other component is affected.

**Acceptance Scenarios**:

1. **Given** a vars file with `dotnet` removed from `active_roles`, **When** provisioning runs, **Then** .NET SDK is not installed and all other roles execute normally
2. **Given** a vars file with `remote_desktop` removed from `active_roles`, **When** provisioning runs, **Then** XFCE and XRDP are not installed
3. **Given** a vars file with `claude_code` present but `fnm` absent from `active_roles`, **When** provisioning runs, **Then** only the explicitly listed roles run (dependency ordering is the operator's responsibility via list order)

---

### User Story 3 - Add a New Provider+Platform Configuration (Priority: P3)

An infrastructure operator wants to provision servers on a new provider (e.g., a different cloud or local VM). They create a new vars file under `configurations/vars/` and define a custom `active_roles` list appropriate for that target. No changes to roles or the entry-point playbook are needed.

**Why this priority**: Confirms the provider-scoped design actually generalises beyond Hetzner Linux.

**Independent Test**: Create `configurations/vars/other-linux.yml` with a subset of roles; set `provider=other` and `platform=linux` when running the entry-point playbook; verify only the declared roles run.

**Acceptance Scenarios**:

1. **Given** a new vars file `configurations/vars/other-linux.yml` with a custom `active_roles` list, **When** `configure-linux.yml` is run with matching `provider` and `platform` variables, **Then** only the roles in that file's `active_roles` list are executed
2. **Given** no vars file matching `provider`+`platform`, **When** provisioning runs, **Then** a clear failure message is produced (Ansible's standard missing-vars-file error)

---

### Edge Cases

- What happens when a role listed in `active_roles` does not exist on disk? Ansible produces a role-not-found error on the first loop iteration; the operator must ensure listed roles are present.
- What happens when `desktop_users` is empty or undefined? Roles that loop over `desktop_users` must be guarded or will produce a loop-over-undefined error; the vars must be populated before the role loop runs.
- What happens when `homebrew` is not in `active_roles` but `github_cli` or `fnm` is listed? The dependent role will fail because Homebrew is not installed; the operator is responsible for correct ordering and inclusion of dependencies.
- What happens when the entry-point playbook is run as a user without sudo rights? `become: true` at the play level will fail; this matches the existing behavior and is not changed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The entry-point playbook `configurations/configure-linux.yml` MUST load a vars file at `configurations/vars/{{ provider }}-{{ platform }}.yml` before executing any roles
- **FR-002**: `configurations/configure-linux.yml` MUST import `setup-users.yml` before iterating over roles, ensuring user accounts exist prior to any role that references `desktop_users`
- **FR-003**: `configurations/configure-linux.yml` MUST execute each role named in the `active_roles` list using `include_role` in a loop, in list order
- **FR-004**: `configurations/vars/hetzner-linux.yml` MUST define `active_roles` containing all nine roles: `base_packages`, `dotnet`, `firefox`, `homebrew`, `github_cli`, `fnm`, `claude_code`, `remote_desktop`, `vscode`
- **FR-005**: Each role MUST have `tasks/main.yml` containing tasks migrated 1:1 from `setup-desktop.yml` with no logic changes
- **FR-006**: Each role MUST have `meta/main.yml`; roles with dependencies (`github_cli` → `homebrew`; `fnm` → `homebrew`; `claude_code` → `fnm`) MUST declare them there
- **FR-007**: Roles whose tasks must not run as root (`homebrew`, `github_cli`, `fnm`, `claude_code` user-scoped tasks) MUST apply `become: false` on affected tasks, mirroring the original behavior
- **FR-008**: Roles with handlers (e.g., `Cleanup apt cache`, `Restart XRDP`) MUST define those handlers in the role's own `handlers/main.yml`
- **FR-009**: All tasks originally tagged `not-supported-on-vagrant-docker` in `setup-desktop.yml` MUST carry that same tag in the `remote_desktop` role
- **FR-010**: `provision.yml` MUST continue to invoke `configurations/configure-linux.yml` without modification; the external interface is unchanged
- **FR-011**: `playbooks/setup-users.yml` MUST remain unmodified
- **FR-012**: The `base_packages` role MUST install: `curl`, `tree`, `unzip`, `build-essential`, `libsecret-tools`, `seahorse`, `python3-full` (consolidating the three separate apt tasks from the original)
- **FR-013**: The `remote_desktop` role MUST include tasks to: install `dbus-x11`, XFCE4+XRDP, start+enable XRDP, remove `gnome-remote-desktop`, remove `light-locker`, configure `.xsession` per `desktop_users`, remove apt `gh` package and its apt sources, enable XFCE session
- **FR-014**: The `homebrew` role MUST configure Homebrew PATH in `.bashrc` for each user in `desktop_users`
- **FR-015**: The `fnm` role MUST install Node 24, set it as default, configure fnm in `.bashrc`, and set npm prefix for each user in `desktop_users`

### Key Entities

- **Role**: A named, self-contained Ansible unit with `tasks/main.yml`, `meta/main.yml`, and optionally `handlers/main.yml`. Each role corresponds to one logical software component.
- **active_roles list**: An ordered list of role names defined in a provider+platform vars file that controls which components are installed on a given target.
- **Provider+platform vars file**: A YAML file at `configurations/vars/<provider>-<platform>.yml` that declares `active_roles` for that combination.
- **Entry-point playbook**: `configurations/configure-linux.yml` — single play that wires together user setup and role execution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A provisioning run against a fresh Hetzner Linux host produces an identical installed software state compared to the previous monolithic `setup-desktop.yml` run, with zero new failures
- **SC-002**: An operator can add or remove a component from the active configuration by changing a single line (one role name) in a vars file — no playbook code changes required
- **SC-003**: All nine software components can be independently verified by running their individual role in isolation against a suitable host
- **SC-004**: Adding support for a new provider+platform combination requires creating exactly one new vars file with an `active_roles` list — zero changes to existing playbooks or roles
- **SC-005**: The `not-supported-on-vagrant-docker` tag continues to suppress remote desktop tasks when that tag is skipped, exactly as in the original playbook

## Assumptions

- `desktop_users` variable is already defined in `group_vars` and populated before provisioning runs; this feature does not change how that variable is sourced
- `provision.yml` currently calls `configurations/configure-linux.yml` directly; its content is not inspected or changed by this feature
- Role dependency declarations in `meta/main.yml` are processed by Ansible at runtime when using `include_role`; declared dependency roles run before the declaring role. `allow_duplicates: false` (the default) prevents a dependency role from running again if it already ran earlier in the `active_roles` loop. The operator still controls the primary execution order via `active_roles`
- The Ansible host running the playbook has internet access for package downloads (Homebrew installer, npm, apt packages) — same assumption as the original playbook
- No new roles are introduced beyond the nine derived from `setup-desktop.yml`
- Docker provider support is explicitly out of scope
