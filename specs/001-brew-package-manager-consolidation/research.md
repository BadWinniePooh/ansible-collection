# Research: Consolidate Developer Tool Installation via Homebrew

**Branch**: `001-brew-package-manager-consolidation` | **Date**: 2026-04-10

All unknowns were resolved during the spec clarification session. This file documents the decisions and their rationale.

---

## Decision 1: Homebrew Install Path and Idempotency Guard

**Decision**: Use `creates: /home/{{ item }}/.linuxbrew/bin/brew` as the idempotency guard for the Homebrew install task.

**Rationale**: Homebrew on Linux (Linuxbrew) installs under the user's home directory at `~/.linuxbrew`. The `brew` binary at `~/.linuxbrew/bin/brew` is the canonical post-install marker. Using `creates:` is simpler than a `stat` + `when:` pre-check and is the standard Ansible pattern for shell tasks that produce a file artifact.

**Alternatives considered**: `stat` module + `when: not stat.stat.exists` — equivalent correctness but requires an extra task and registered variable; rejected for unnecessary verbosity.

---

## Decision 2: Homebrew Runs as Desktop User

**Decision**: All Homebrew installation and formula install tasks use `become_user: "{{ item }}"`.

**Rationale**: Homebrew on Linux is a per-user installation. Running as root would install Homebrew in `/home/root` or `/root/.linuxbrew`, making the tools inaccessible to the desktop user. Homebrew explicitly does not support running as root on Linux.

**Alternatives considered**: System-wide Homebrew — not supported on Linux. Rejected.

---

## Decision 3: Remove apt `gh` Before Homebrew Install

**Decision**: Use `ansible.builtin.apt: name=gh state=absent` and `ansible.builtin.file: path=/etc/apt/sources.list.d/github-cli.list state=absent` before installing `gh` via Homebrew.

**Rationale**: If both apt and Homebrew install `gh`, the version that appears first in PATH wins, leading to non-deterministic behavior. Explicitly removing the apt package and its source file ensures Homebrew's `gh` is the only one present and that apt does not re-install the apt version on subsequent `apt upgrade` calls.

**Alternatives considered**: Rely on PATH ordering (Homebrew bin before `/usr/bin`) — fragile; PATH is not guaranteed to be ordered correctly in all shell contexts. Rejected.

---

## Decision 4: fnm and Claude Code Use Inline fnm Init in Ansible Shell Tasks

**Decision**: The Claude Code CLI install task uses `eval "$(/home/{{ item }}/.linuxbrew/bin/fnm env)" && fnm use 24 && npm install -g @anthropic-ai/claude-code`.

**Rationale**: Ansible `shell` tasks run in a non-interactive, non-login shell. `.bashrc` is not sourced automatically, so fnm shims are not in PATH. Inlining the fnm env eval activates fnm within the single shell session that runs the task, making `npm` available without requiring `.bashrc` sourcing.

**Alternatives considered**: Source `.bashrc` at the start of the shell task — unreliable because `.bashrc` typically contains a guard (`[ -z "$PS1" ] && return`) that exits early in non-interactive shells. Rejected.

---

## Decision 5: Firefox via apt

**Decision**: `ansible.builtin.apt: name=firefox state=present`.

**Rationale**: The `apt` module is idempotent by design, requires no extra configuration, and avoids snap daemon overhead on a headless RDP-provisioned server. On Ubuntu 24.04, `apt install firefox` delivers the native deb from Ubuntu's universe repository.

**Alternatives considered**: snap firefox — adds snap daemon overhead and was excluded by the spec clarification. Rejected.

---

## Decision 6: No Homebrew Install Script Checksum Verification

**Decision**: Fetch the Homebrew install script from `https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh` over HTTPS without additional checksum verification.

**Rationale**: Homebrew does not publish a stable SHA256 for its install script (it updates frequently). GitHub's TLS certificate provides integrity assurance. This is consistent with Homebrew's own documented install process and is the standard community practice for Ansible-based Homebrew provisioning.

**Alternatives considered**: SHA256 checksum of install.sh — not published by Homebrew; would require manual update on every Homebrew release. Rejected.

---

## Decision 7: VS Code Stays on Snap

**Decision**: `community.general.snap: name=code classic=true state=present` — no change.

**Rationale**: Homebrew on Linux does not support casks. VS Code has no official deb package in Ubuntu's default repositories. Snap is the lowest-friction, officially supported path and is already working. No change required.

**Alternatives considered**: Microsoft's official apt repository — not currently used; adds another apt source, which works against the consolidation goal. Rejected.

---

## Homebrew Formula Availability Verification

The following formulae are confirmed available in the Homebrew core tap (https://formulae.brew.sh):

| Formula | Homebrew Formula Page | Linux Support |
|---------|-----------------------|---------------|
| `gh`    | formulae.brew.sh/formula/gh | Yes |
| `fnm`   | formulae.brew.sh/formula/fnm | Yes |

Both are bottles (pre-compiled binaries), so no compilation step is needed on the target server under normal conditions. `build-essential` remains in apt as a fallback for bottle unavailability.
