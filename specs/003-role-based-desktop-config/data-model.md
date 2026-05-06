# Data Model: Role-Based Desktop Configuration

**Phase**: 1 — Design
**Feature**: `003-role-based-desktop-config`
**Date**: 2026-05-05

## Entities

### Role

A self-contained Ansible unit responsible for exactly one software component.

| Attribute | Description |
|-----------|-------------|
| `name` | Unique identifier matching the directory name under `roles/` |
| `tasks/main.yml` | Task list migrated 1:1 from the corresponding section of `setup-desktop.yml` |
| `meta/main.yml` | Role metadata and `dependencies:` list (empty or named roles) |
| `handlers/main.yml` | Handlers triggered by tasks in this role (present only if role notifies handlers) |

**Invariant**: A role name used in `active_roles` MUST have a corresponding directory under `roles/` with a valid `tasks/main.yml`.

---

### active_roles list

An ordered YAML sequence of role names that controls which components are installed on a given target.

| Attribute | Description |
|-----------|-------------|
| Type | `list[str]` — each string is a role name |
| Source | Provider+platform vars file loaded at play startup |
| Order semantics | Roles execute in list order; dependency roles (via `meta/main.yml`) run before their dependents |
| Mutability | Operators edit the list to add/remove components; no playbook changes needed |

**Invariant**: Every string in `active_roles` must be a valid role name present on disk.

---

### Provider+Platform Vars File

A YAML file that binds a provider+platform combination to its `active_roles` list.

| Attribute | Description |
|-----------|-------------|
| Path pattern | `configurations/vars/<provider>-<platform>.yml` |
| Required keys | `active_roles: [list of role names]` |
| Resolution | Loaded at play startup via `vars_files: ["vars/{{ provider }}-{{ platform }}.yml"]` |
| Extra-var inputs | `provider` and `platform` supplied as `--extra-vars` at invocation time |

**Invariant**: A vars file for the target `provider`+`platform` must exist before provisioning runs.

---

### Entry-Point Playbook (`configure-linux.yml`)

Orchestrates user creation and role execution for a Linux target.

| Attribute | Description |
|-----------|-------------|
| Path | `configurations/configure-linux.yml` |
| Play-level vars | `desktop_user_names: "{{ desktop_users \| map(attribute='name') \| list }}"` |
| Imported playbook | `../playbooks/setup-users.yml` (runs first, before the role loop play) |
| vars_files | `vars/{{ provider }}-{{ platform }}.yml` (loaded at play startup) |
| Role loop | `include_role name="{{ item }}" loop="{{ active_roles }}"` |
| become | `true` at play level; individual tasks override with `become: false` where needed |

---

## Role Catalog

### `base_packages`
- **Purpose**: Install system utilities and development prerequisites
- **Packages**: `curl`, `tree`, `unzip`, `python3-full`, `build-essential`, `libsecret-tools`, `seahorse`
- **Handlers**: `Cleanup apt cache`
- **Dependencies**: none

### `dotnet`
- **Purpose**: Install .NET SDK toolchain
- **Packages**: `dotnet-sdk-8.0`, `dotnet-sdk-10.0`
- **Handlers**: `Cleanup apt cache`
- **Dependencies**: none

### `firefox`
- **Purpose**: Install Firefox web browser
- **Packages**: `firefox`
- **Handlers**: `Cleanup apt cache`
- **Dependencies**: none

### `homebrew`
- **Purpose**: Install Linuxbrew and configure PATH for desktop users
- **Key tasks**: Run installer (`become: false`), add `brew shellenv` to `.bashrc` for each `desktop_users` entry
- **Handlers**: none
- **Dependencies**: none

### `github_cli`
- **Purpose**: Install GitHub CLI via Homebrew
- **Key tasks**: `brew install gh` (`become: false`)
- **Handlers**: none
- **Dependencies**: `homebrew`

### `fnm`
- **Purpose**: Install Fast Node Manager, Node 24, and configure shell integration for desktop users
- **Key tasks**: `brew install fnm` (`become: false`), add fnm env to `.bashrc`, install Node 24, set default, configure npm prefix
- **Handlers**: none
- **Dependencies**: `homebrew`

### `claude_code`
- **Purpose**: Install Claude Code CLI globally via npm for each desktop user
- **Key tasks**: `npm install -g @anthropic-ai/claude-code` using fnm-managed Node (`become_user: "{{ item }}"`)
- **Handlers**: none
- **Dependencies**: `fnm`

### `remote_desktop`
- **Purpose**: Configure XFCE4 desktop environment with XRDP remote access
- **Packages installed**: `dbus-x11`, `xfce4`, `xfce4-goodies`, `xrdp`
- **Packages removed**: `gnome-remote-desktop`, `light-locker`, `gh`
- **Files removed**: `/etc/apt/sources.list.d/github-cli.list`, `/etc/apt/keyrings/githubcli-archive-keyring.gpg`
- **Per-user config**: `.xsession` file set to `xfce4-session`
- **Services**: XRDP started + enabled
- **Tags**: ALL tasks carry `not-supported-on-vagrant-docker`
- **Handlers**: `Cleanup apt cache`, `Restart XRDP`
- **Dependencies**: none

### `vscode`
- **Purpose**: Install Visual Studio Code via snap
- **Key tasks**: `snap install code --classic`
- **Handlers**: none
- **Dependencies**: none

---

## File System Layout (post-implementation)

```text
configurations/
  configure-linux.yml          ← rewritten entry point (replaces old two-import file)
  vars/
    hetzner-linux.yml          ← active_roles list for provider=hetzner platform=linux

roles/
  base_packages/
    tasks/main.yml
    handlers/main.yml
    meta/main.yml
  dotnet/
    tasks/main.yml
    handlers/main.yml
    meta/main.yml
  firefox/
    tasks/main.yml
    handlers/main.yml
    meta/main.yml
  homebrew/
    tasks/main.yml
    meta/main.yml
  github_cli/
    tasks/main.yml
    meta/main.yml
  fnm/
    tasks/main.yml
    meta/main.yml
  claude_code/
    tasks/main.yml
    meta/main.yml
  remote_desktop/
    tasks/main.yml
    handlers/main.yml
    meta/main.yml
  vscode/
    tasks/main.yml
    meta/main.yml
```

**Unchanged files**:
- `playbooks/setup-users.yml` — not modified
- `provision.yml` — not modified
- `playbooks/setup-desktop.yml` — retired (replaced by roles); kept in repo until implementation is verified
