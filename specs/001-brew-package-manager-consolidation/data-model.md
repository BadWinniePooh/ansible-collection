# Data Model: Consolidate Developer Tool Installation via Homebrew

**Branch**: `001-brew-package-manager-consolidation` | **Date**: 2026-04-10

This feature introduces no new data structures, databases, or persistent state objects. The "data" it manages is file-system presence and shell configuration lines.

---

## Entities

### Desktop User

**Definition**: A named Linux user on the provisioned server who receives the full developer environment.

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `name` | string | `desktop_users` Ansible variable | Loop variable: `{{ item }}` |
| home directory | path | `/home/{{ item }}` | Must exist before Homebrew tasks run |

**Relationships**: One Desktop User → one Homebrew installation → one set of formula binaries.

---

### Homebrew Installation (per user)

**Definition**: A Linuxbrew installation rooted at `~/.linuxbrew` for a given desktop user.

| File-system artifact | Path | Created by |
|----------------------|------|-----------|
| brew binary | `/home/{{ item }}/.linuxbrew/bin/brew` | Homebrew install script |
| gh binary | `/home/{{ item }}/.linuxbrew/bin/gh` | `brew install gh` |
| fnm binary | `/home/{{ item }}/.linuxbrew/bin/fnm` | `brew install fnm` |

**State transitions**:
- absent → present (first playbook run, via install tasks)
- present → present (subsequent runs, no-op via `creates:` guards)

---

### Shell Profile Configuration (per user)

**Definition**: Lines added to `/home/{{ item }}/.bashrc` to activate Homebrew and fnm in new shell sessions.

| Line | File | Managed by |
|------|------|-----------|
| `eval "$(/home/{{ item }}/.linuxbrew/bin/brew shellenv)"` | `.bashrc` | `ansible.builtin.lineinfile` |
| `eval "$(fnm env --use-on-cd)"` | `.bashrc` | `ansible.builtin.lineinfile` |

---

### fnm Node Installation (per user)

**Definition**: Node 24 installed and defaulted under fnm's node-versions directory.

| Artifact | Path |
|----------|------|
| Node 24 version directory | `/home/{{ item }}/.local/share/fnm/node-versions/v24` |
| claude binary (npm global) | `/home/{{ item }}/.local/share/fnm/node-versions/v24/installation/bin/claude` |

---

### Package Source Inventory (before vs. after)

| Tool | Before | After |
|------|--------|-------|
| `gh` | apt (github-cli repo) | Homebrew |
| `fnm` | curl\|bash from vercel | Homebrew |
| Node 24 | fnm (curl-installed) | fnm (Homebrew-installed) |
| Claude Code CLI | curl\|bash from claude.ai | npm (via fnm) |
| VS Code | snap | snap (unchanged) |
| Firefox | absent | apt |
| System utilities | apt | apt (unchanged) |
| .NET SDK | apt | apt (unchanged) |

**Package source count**: 4 → 3 (apt, snap, Homebrew).
