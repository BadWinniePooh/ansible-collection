# Feature Specification: Consolidate Developer Tool Installation via Homebrew

**Feature Branch**: `001-brew-package-manager-consolidation`
**Created**: 2026-04-10
**Status**: Draft
**Input**: User description: "Streamline the Ansible desktop provision playbook for a Hetzner Cloud Ubuntu Linux development environment by using Homebrew (Linuxbrew) as the primary package manager for developer tools, replacing the snap source and the curl|bash install scripts where possible. Add Firefox browser. Goal is to reduce the number of distinct package sources/installation methods."

## Clarifications

### Session 2026-04-10

- Q: Should Firefox be installed via apt or snap? → A: apt (`apt install firefox`). Rationale: idempotent with `ansible.builtin.apt`, avoids snap daemon overhead on an RDP-based server, and works on all target Ubuntu LTS versions.
- Q: How should the existing apt-installed `gh` be removed when migrating to Homebrew? → A: Explicitly remove the apt `gh` package and its apt repository source before the Homebrew install task, using `ansible.builtin.apt: name=gh state=absent` plus removal of the apt source file, to prevent PATH ambiguity.
- Q: Should Node 24 be set as the fnm default version after installation? → A: Yes — run `fnm default 24` after installing Node 24 so that `node` and `npm` are available in new shell sessions without requiring `fnm use` to be called manually.
- Q: How should the Claude Code CLI npm install be run from an Ansible task when npm is only available via fnm shims? → A: Use an inline fnm init in the Ansible `shell` task: `eval "$(fnm env)" && fnm use 24 && npm install -g @anthropic-ai/claude-code`. This activates the fnm-managed Node within the non-interactive shell session.
- Q: Should the Homebrew install script be verified with a checksum? → A: No additional checksum verification; fetch via HTTPS from the official GitHub URL. GitHub's TLS certificate is the integrity control, consistent with Homebrew's own documented install process and standard Ansible provisioning practice.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Provision Fresh Desktop Environment (Priority: P1)

A developer runs the desktop provision playbook against a fresh Hetzner Cloud Ubuntu server and receives a fully configured development workstation in a single step. All developer tools are installed consistently, without manual intervention or post-run fixes.

**Why this priority**: This is the core end-to-end use case. Every other story is a subset. If the full provision works, all individual tool installations are validated implicitly.

**Independent Test**: Can be fully tested by running the playbook against a fresh Ubuntu server and verifying all expected tools are present and functional afterwards — delivers a fully usable development environment.

**Acceptance Scenarios**:

1. **Given** a fresh Ubuntu server with no developer tools, **When** the provision playbook is run, **Then** all expected tools (gh, fnm, Node, Claude Code CLI, VS Code, Firefox) are available to the desktop user and the playbook completes without errors.
2. **Given** the playbook has already been run once, **When** it is run again, **Then** it completes without errors and reports no unexpected changes (idempotent run).

---

### User Story 2 - Install Developer Tools via Single Managed Source (Priority: P2)

A developer wants all developer-focused CLI tools (gh, fnm, Node via fnm, Claude Code CLI) installed through Homebrew so that future upgrades and additions require changes to a single place in the playbook rather than managing multiple install methods.

**Why this priority**: This is the primary driver of the feature — reducing the number of distinct package sources. Achieving this for CLI tools creates the consolidation benefit even if VS Code stays on snap.

**Independent Test**: Can be tested independently by running only the Homebrew-related tasks and confirming that `brew`, `gh`, `fnm`, `node`, and `claude` are all available to the target user without requiring any curl-piped scripts or apt packages for these tools.

**Acceptance Scenarios**:

1. **Given** Homebrew is not yet installed on the target server, **When** the playbook runs, **Then** Homebrew is installed for each desktop user and the PATH is configured so brew-installed tools are accessible in new shell sessions.
2. **Given** Homebrew is installed, **When** the playbook installs developer tools, **Then** `gh`, `fnm`, Node (via fnm), and Claude Code CLI are all installed and callable from the desktop user's shell.
3. **Given** `gh` was previously installed via apt, **When** the playbook runs after the migration, **Then** `gh` is provided by Homebrew and the apt-installed version is removed or superseded.

---

### User Story 3 - Add Firefox Browser (Priority: P3)

A developer using the provisioned desktop environment needs a web browser for daily work. Firefox should be available immediately after provisioning without any manual installation steps.

**Why this priority**: Firefox is additive (not currently installed), so it does not block the core provision flow. It is lower priority than the package-manager consolidation but is still a concrete requirement.

**Independent Test**: Can be tested independently by running only the Firefox installation task and confirming Firefox launches successfully on the provisioned desktop.

**Acceptance Scenarios**:

1. **Given** Firefox is not present on the server, **When** the provision playbook runs, **Then** Firefox is installed and available in the desktop application menu.
2. **Given** Firefox is already installed, **When** the playbook runs again, **Then** it reports no change (idempotent).

---

### User Story 4 - VS Code Continues to Work via Snap (Priority: P4)

VS Code is installed via snap (as today) because Homebrew on Linux does not support casks. The provision should continue to deliver a working VS Code installation for the desktop user.

**Why this priority**: VS Code is already working. This story is about ensuring the consolidation work does not break the existing snap-based install.

**Independent Test**: Can be tested by running the VS Code snap task in isolation and confirming VS Code launches from the desktop after provisioning.

**Acceptance Scenarios**:

1. **Given** VS Code is not installed, **When** the provision playbook runs, **Then** VS Code is installed via snap and launchable from the XFCE desktop.
2. **Given** VS Code is already installed via snap, **When** the playbook runs again, **Then** it reports the snap package is already present and makes no changes.

---

### Edge Cases

- What happens when the Homebrew installer cannot reach the internet during provisioning? The task should fail with a clear error rather than silently produce a partial install.
- What happens when fnm is installed via Homebrew but the shell configuration files (`.bashrc`, `.profile`, or equivalent) are not updated to include fnm's shims in PATH? Node would not be found in new shell sessions.
- What happens if `gh` was previously installed via apt and Homebrew also installs it? The apt-installed `gh` package and its apt repository source are explicitly removed by the playbook before Homebrew installs `gh`, ensuring no PATH ambiguity or version conflict.
- What happens when the playbook is run as root but Homebrew is expected to be installed per-user? Homebrew on Linux should be installed under the desktop user's home directory, not as root.
- What happens when a desktop user does not yet have a home directory at playbook run time? User home directories must exist before Homebrew installation tasks run.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The provision playbook MUST install Homebrew (Linuxbrew) for each configured desktop user using the official install script.
- **FR-002**: The provision playbook MUST configure each desktop user's shell environment so that Homebrew-installed binaries are available in new interactive shell sessions without manual PATH changes.
- **FR-003**: The provision playbook MUST install `gh` (GitHub CLI) via Homebrew, replacing the current apt-based installation. The apt-installed `gh` package and the GitHub CLI apt repository/keyring MUST be explicitly removed (using `ansible.builtin.apt: name=gh state=absent` and removing the apt source file) before or as part of the Homebrew-based install, to prevent PATH ambiguity between the two versions.
- **FR-004**: The provision playbook MUST install `fnm` (Fast Node Manager) via Homebrew for each desktop user, replacing the current curl-piped install script.
- **FR-005**: After fnm is installed, the provision playbook MUST install Node 24 via fnm for each desktop user and MUST set Node 24 as the fnm default version (`fnm default 24`) so that `node` and `npm` are available in all new shell sessions without requiring `fnm use` to be called manually.
- **FR-006**: The provision playbook MUST install the Claude Code CLI for each desktop user via `npm install -g @anthropic-ai/claude-code`. The Ansible task MUST initialize fnm inline within the shell task to make `npm` available: `eval "$(fnm env)" && fnm use 24 && npm install -g @anthropic-ai/claude-code`. This approach is required because npm is only accessible through fnm's shims, which are not active in non-interactive Ansible shell sessions without explicit fnm initialization.
- **FR-007**: The provision playbook MUST install VS Code via snap (classic), as Homebrew on Linux does not support casks.
- **FR-008**: The provision playbook MUST install Firefox via `apt install firefox`. The apt package is preferred over snap because it uses the standard `ansible.builtin.apt` module, is idempotent without extra configuration, and avoids snap daemon overhead on a headless server provisioned for RDP access.
- **FR-009**: All Homebrew installation tasks MUST run as the target desktop user (not root), since Homebrew on Linux operates under the user's home directory.
- **FR-010**: The provision playbook MUST be idempotent — running it multiple times on the same server MUST NOT produce errors or unintended duplicate installations.
- **FR-011**: System utilities installed via apt (curl, tree, unzip, build-essential, libsecret-tools, seahorse, .NET SDK, XFCE, XRDP) MUST continue to be installed as today; only the developer tool installations listed above change their source.

### Key Entities

- **Desktop User**: A named Linux user on the provisioned server who receives the full developer environment. Multiple desktop users may be configured. Each user gets their own Homebrew installation and tool set.
- **Package Source**: A distinct mechanism for installing software (apt, snap, Homebrew, curl-piped script). The goal of this feature is to reduce the total count of active package sources.
- **Provision Playbook**: The Ansible playbook (`playbooks/setup-desktop.yml`) that is run against a Hetzner Cloud Ubuntu server to produce the development desktop environment.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After running the provision playbook against a fresh Ubuntu server, all of the following tools are callable from the desktop user's shell: `brew`, `gh`, `fnm`, `node`, `npm`, `claude`, `code`, `firefox`. Zero manual post-run steps required.
- **SC-002**: The number of distinct installation methods (package sources) in the playbook is reduced from 4 (apt, snap, curl-piped fnm, curl-piped Claude Code) to 3 or fewer (apt, snap, Homebrew).
- **SC-003**: The provision playbook runs to completion without errors on a freshly created Hetzner Cloud Ubuntu server in a single execution.
- **SC-004**: A second consecutive run of the provision playbook on the same server reports zero failed tasks and the number of changed tasks is 0 or equal only to legitimately non-idempotent tasks already present before this change.
- **SC-005**: Firefox is accessible from the desktop application menu after provisioning on every run against a fresh server.

## Assumptions

- The target operating system is Ubuntu (latest LTS) on Hetzner Cloud. Debian compatibility is a bonus but not a requirement for this feature.
- Desktop users listed in the `desktop_users` variable all have home directories created prior to the Homebrew installation tasks (handled by upstream user-creation playbooks or tasks).
- Homebrew on Linux (Linuxbrew) supports all required formulae: `gh`, `fnm`. This is verified by the Homebrew formula registry.
- Homebrew on Linux does NOT support casks. VS Code therefore remains on snap.
- The target servers have outbound internet access during provisioning (required to download Homebrew and formulae).
- The Claude Code CLI installation via npm (`npm install -g @anthropic-ai/claude-code`) is the preferred method after Node is available via fnm; the existing curl-piped script is an acceptable fallback if npm install is not straightforward in an Ansible shell task.
- Firefox is installed via `apt install firefox`. On Ubuntu 24.04 LTS this installs the native deb from Ubuntu's universe repository. If the system's apt configuration delivers a snap-backed shim instead (as on some Ubuntu 22.04 configurations), that outcome is acceptable since the goal is a working Firefox accessible from the desktop — the installation mechanism detail does not affect acceptance criteria.
- `build-essential` remains in apt; Homebrew may depend on it for compiling formulae from source if bottles are unavailable.
- The Homebrew install script is fetched from `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh` over HTTPS. No additional checksum verification is performed; GitHub's TLS certificate is the integrity control, consistent with Homebrew's own documented install instructions and standard community practice for Ansible-based Homebrew provisioning.
- The `.NET SDK` packages remain installed via apt (not migrated to Homebrew in this feature).
- The XFCE desktop, XRDP, and all GUI-related packages remain installed via apt.
