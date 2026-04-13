# Implementation Plan: Consolidate Developer Tool Installation via Homebrew

**Branch**: `001-brew-package-manager-consolidation` | **Date**: 2026-04-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-brew-package-manager-consolidation/spec.md`

## Summary

Modify `playbooks/setup-desktop.yml` to replace curl-piped install scripts and the apt-sourced `gh` package with Homebrew (Linuxbrew) as the single managed source for developer CLI tools (`gh`, `fnm`, Node 24, Claude Code CLI). Firefox is added via apt. VS Code remains on snap. The playbook's distinct installation methods drop from 4 to 3 (apt, snap, Homebrew).

## Technical Context

**Language/Version**: YAML (Ansible playbook), targeting Ubuntu 24.04 LTS (Hetzner Cloud)
**Primary Dependencies**: `ansible.builtin.apt`, `ansible.builtin.shell`, `ansible.builtin.lineinfile`, `community.general.snap` — all already used in the repo
**Storage**: N/A
**Testing**: Manual end-to-end run against a fresh Hetzner Cloud Ubuntu server; idempotency verified by a second consecutive run
**Target Platform**: Ubuntu 24.04 LTS on Hetzner Cloud (Linux server, x86_64)
**Project Type**: Ansible collection / infrastructure-as-code playbook
**Performance Goals**: Playbook completes without errors; second run produces zero failed tasks
**Constraints**: Homebrew must run as the desktop user (not root); all Homebrew tasks use `become_user`; idempotency enforced via `creates:` guards
**Scale/Scope**: One playbook file; tasks loop over `desktop_user_names`

## Constitution Check

The project constitution file is a blank template with no active principles or gates defined. No constitution gates apply to this feature. The plan proceeds without gate violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-brew-package-manager-consolidation/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
playbooks/
└── setup-desktop.yml    # Only file modified by this feature
```

**Structure Decision**: Single file modification. The repository is an Ansible collection; the only source change is `playbooks/setup-desktop.yml`.

## Complexity Tracking

No constitution violations. Table not required.

---

## Phase 0: Research

### Research Tasks

All unknowns were fully resolved during the spec clarification session (2026-04-10). No NEEDS CLARIFICATION items remain. The research below documents the decisions made.

### research.md Summary

See [research.md](./research.md) for full findings. Key decisions:

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Homebrew install via `creates:` guard on `~/.linuxbrew/bin/brew` | Idempotent without a `stat` pre-check; matches Homebrew's own post-install path on Linux | `stat` module + `when:` condition — equivalent but more verbose |
| Run all Homebrew tasks as `become_user: "{{ item }}"` | Homebrew on Linux is a per-user install under `~/.linuxbrew`; root-owned install is unsupported | System-wide Homebrew — not supported on Linux |
| Remove apt `gh` and its source file before Homebrew install | Prevents PATH ambiguity between two `gh` versions | Rely on PATH ordering — fragile and non-deterministic |
| `eval "$(fnm env)" && fnm use 24 && npm install -g ...` inline in shell task | npm is only accessible through fnm shims; non-interactive Ansible shell sessions do not source `.bashrc` | Source `.bashrc` in the shell task — unreliable in non-login, non-interactive shells |
| Firefox via `ansible.builtin.apt: name=firefox` | Idempotent, no snap daemon overhead, works on all Ubuntu LTS targets | snap firefox — adds snap overhead and was excluded by clarification decision |
| No Homebrew checksum verification | Consistent with Homebrew's own documented install process; HTTPS from GitHub is the integrity control | SHA256 checksum of install.sh — not published by Homebrew; would require manual update on each Homebrew release |
| VS Code stays on snap | Homebrew on Linux does not support casks | apt/deb — no official Microsoft apt repo is in use; no change needed |

---

## Phase 1: Design

### data-model.md Summary

This feature has no new data models. The only persistent state it manages is file-system presence (Homebrew directories, shell profile lines, package installations). See [data-model.md](./data-model.md) for the entity catalogue.

### Contracts

No external interfaces are introduced or changed. The playbook's public contract is its variable interface (`desktop_users`, `my_hetzner_config`), which is unchanged. No `/contracts/` directory is needed.

### quickstart.md

See [quickstart.md](./quickstart.md) for run instructions.

---

## Implementation Design

### Task Sequence in `playbooks/setup-desktop.yml`

The following describes the complete ordered task set after the change. Tasks marked **[NEW]** are added; **[MODIFIED]** are changed; **[REMOVED]** are deleted; **[UNCHANGED]** are untouched.

#### 1. Update apt cache — [UNCHANGED]
`pre_tasks` block, no change.

#### 2. Install console utilities (curl, tree, unzip) — [UNCHANGED]

#### 3. Install minimal GNOME desktop — [UNCHANGED]

#### 4. Install XFCE extras — [MODIFIED]
Remove `gh` from the `apt` name list. Keep `build-essential`, `libsecret-tools`, `seahorse`.

```yaml
- name: Install XFCE extras and developer tools
  apt:
    name:
      - build-essential
      - libsecret-tools
      - seahorse
    state: present
  notify: Cleanup apt cache
```

#### 5. Install .NET SDK — [UNCHANGED]

#### 6. Remove apt-installed gh — [NEW]
Remove the `gh` apt package. Run before Homebrew installs `gh` to eliminate PATH ambiguity.

```yaml
- name: Remove apt-installed gh (replaced by Homebrew)
  ansible.builtin.apt:
    name: gh
    state: absent
  notify: Cleanup apt cache
```

#### 7. Remove GitHub CLI apt source file and keyring — [NEW]
Remove the apt source list entry and GPG keyring for the GitHub CLI repository to prevent the package from being re-installed by `apt upgrade` or other playbooks and to leave no orphaned keyring files.

```yaml
- name: Remove GitHub CLI apt source
  ansible.builtin.file:
    path: /etc/apt/sources.list.d/github-cli.list
    state: absent

- name: Remove GitHub CLI apt keyring
  ansible.builtin.file:
    path: /etc/apt/keyrings/githubcli-archive-keyring.gpg
    state: absent
```

#### 8. Install Homebrew for each desktop user — [NEW]
Run the official Homebrew install script as each desktop user. `creates:` makes it idempotent.

```yaml
- name: Install Homebrew for {{ desktop_user_names | join(', ') }}
  ansible.builtin.shell:
    cmd: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    creates: "/home/{{ item }}/.linuxbrew/bin/brew"
  become_user: "{{ item }}"
  loop: "{{ desktop_user_names }}"
  environment:
    NONINTERACTIVE: "1"
    HOME: "/home/{{ item }}"
```

#### 9. Configure Homebrew PATH in shell profile — [NEW]
Add the `brew shellenv` eval line to each user's `.bashrc` so brew-managed binaries are available in new interactive sessions.

```yaml
- name: Configure Homebrew PATH for {{ desktop_user_names | join(', ') }}
  ansible.builtin.lineinfile:
    path: "/home/{{ item }}/.bashrc"
    line: 'eval "$(/home/{{ item }}/.linuxbrew/bin/brew shellenv)"'
    create: yes
    owner: "{{ item }}"
    group: "{{ item }}"
    mode: '0644'
  loop: "{{ desktop_user_names }}"
```

#### 10. Install gh via Homebrew — [NEW, replaces apt gh]
Install the GitHub CLI via Homebrew for each desktop user.

```yaml
- name: Install gh via Homebrew for {{ desktop_user_names | join(', ') }}
  ansible.builtin.shell:
    cmd: /home/{{ item }}/.linuxbrew/bin/brew install gh
    creates: "/home/{{ item }}/.linuxbrew/bin/gh"
  become_user: "{{ item }}"
  loop: "{{ desktop_user_names }}"
```

#### 11. Install fnm via Homebrew — [NEW, replaces curl|bash fnm]
Install Fast Node Manager via Homebrew for each desktop user.

```yaml
- name: Install fnm via Homebrew for {{ desktop_user_names | join(', ') }}
  ansible.builtin.shell:
    cmd: /home/{{ item }}/.linuxbrew/bin/brew install fnm
    creates: "/home/{{ item }}/.linuxbrew/bin/fnm"
  become_user: "{{ item }}"
  loop: "{{ desktop_user_names }}"
```

#### 12. Configure fnm in shell — [NEW]
Add fnm init to `.bashrc` so Node/npm shims are available in new shell sessions.

```yaml
- name: Configure fnm in shell for {{ desktop_user_names | join(', ') }}
  ansible.builtin.lineinfile:
    path: "/home/{{ item }}/.bashrc"
    line: 'eval "$(fnm env --use-on-cd)"'
    create: yes
    owner: "{{ item }}"
    group: "{{ item }}"
    mode: '0644'
  loop: "{{ desktop_user_names }}"
```

#### 13. Install Node 24 via fnm — [MODIFIED]
Replace the old task that called `~/.local/share/fnm/fnm` (curl-installed path) with the Homebrew-managed `fnm` binary path. Set Node 24 as the default version.

```yaml
- name: Install Node 24 via fnm for {{ desktop_user_names | join(', ') }}
  ansible.builtin.shell:
    cmd: |
      /home/{{ item }}/.linuxbrew/bin/fnm install 24 && \
      /home/{{ item }}/.linuxbrew/bin/fnm default 24
    creates: "/home/{{ item }}/.local/share/fnm/aliases/default"
  become_user: "{{ item }}"
  loop: "{{ desktop_user_names }}"
```

#### 14. Install Claude Code CLI via npm — [MODIFIED, replaces curl|bash claude]
Replace the curl-piped Claude Code install with npm, using inline fnm init to activate Node 24 in the non-interactive shell session.

```yaml
- name: Install Claude Code CLI for {{ desktop_user_names | join(', ') }}
  ansible.builtin.shell:
    cmd: >
      eval "$(/home/{{ item }}/.linuxbrew/bin/fnm env)" &&
      fnm use 24 &&
      npm install -g @anthropic-ai/claude-code
    creates: "/home/{{ item }}/.local/bin/claude"
  become_user: "{{ item }}"
  loop: "{{ desktop_user_names }}"
```

#### 15. Remove old fnm curl|bash task — [REMOVED]
Delete the task:
```yaml
# REMOVE THIS TASK:
- name: Install fnm (Fast Node Manager) for ...
  ansible.builtin.shell:
    cmd: curl -fsSL https://fnm.vercel.app/install | bash
    creates: "/home/{{ item }}/.local/share/fnm/fnm"
```

#### 16. Remove old Claude Code curl|bash task — [REMOVED]
Delete the task:
```yaml
# REMOVE THIS TASK:
- name: Install Claude Code CLI for ...
  ansible.builtin.shell:
    cmd: curl -fsSL https://claude.ai/install.sh | bash
    creates: "/home/{{ item }}/.local/bin/claude"
```

#### 17. Install VS Code via snap — [UNCHANGED]

#### 18. Install Firefox via apt — [NEW]

```yaml
- name: Install Firefox
  ansible.builtin.apt:
    name: firefox
    state: present
  notify: Cleanup apt cache
```

#### 19. Remove GNOME remote desktop — [UNCHANGED]

#### 20. Install XFCE desktop and XRDP — [UNCHANGED]

#### 21. Start and enable XRDP — [UNCHANGED]

#### 22. Remove light-locker — [UNCHANGED]

#### 23. Enable XFCE session — [UNCHANGED]

---

### Idempotency Strategy

| Task | Guard |
|------|-------|
| Install Homebrew | `creates: /home/{{ item }}/.linuxbrew/bin/brew` |
| Install gh via brew | `creates: /home/{{ item }}/.linuxbrew/bin/gh` |
| Install fnm via brew | `creates: /home/{{ item }}/.linuxbrew/bin/fnm` |
| Configure PATH (brew, fnm) | `ansible.builtin.lineinfile` — only inserts if line absent |
| Install Node 24 via fnm | `creates: /home/{{ item }}/.local/share/fnm/aliases/default` |
| Install Claude Code CLI | `creates: /home/{{ item }}/.local/bin/claude` |
| Remove apt gh | `state: absent` — no-op if already absent |
| Remove apt source file | `state: absent` — no-op if already absent |
| Remove GitHub CLI keyring | `state: absent` — no-op if already absent |
| Firefox | `state: present` — no-op if already installed |

---

### Edge Case Handling

| Edge Case | Handling |
|-----------|----------|
| No internet during provisioning | `curl` and Homebrew install will fail with a clear error; task aborts with non-zero exit; Ansible reports failure — no silent partial install |
| fnm PATH not in shell after install | Task 12 (lineinfile) ensures `.bashrc` contains the fnm eval line before Node install tasks run |
| `gh` installed via both apt and Homebrew | Tasks 6–7 explicitly remove apt `gh` and its source before Homebrew installs it |
| Playbook run as root, Homebrew per-user | All Homebrew tasks use `become_user: "{{ item }}"` — Homebrew installs under user's home |
| Desktop user home directory missing | Pre-condition: user home directories must exist before these tasks run (handled by upstream user-creation tasks — assumed by spec) |

---

## Acceptance Criteria Mapping

| Success Criterion | Covered By |
|-------------------|-----------|
| SC-001: All tools callable after fresh provision | Tasks 8–14 + Task 18 |
| SC-002: Installation methods reduced to ≤ 3 | Removal of curl|bash tasks (15, 16); gh moved from apt to Homebrew (6, 7, 10) |
| SC-003: Playbook completes without errors | End-to-end test on fresh server |
| SC-004: Second run produces zero failures | Idempotency guards on all new tasks |
| SC-005: Firefox accessible after provisioning | Task 18 |
