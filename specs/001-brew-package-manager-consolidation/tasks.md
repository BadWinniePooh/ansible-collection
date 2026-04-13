---

description: "Task list for Consolidate Developer Tool Installation via Homebrew"
---

# Tasks: Consolidate Developer Tool Installation via Homebrew

**Input**: Design documents from `/specs/001-brew-package-manager-consolidation/`
**Prerequisites**: plan.md, spec.md
**Target file**: `playbooks/setup-desktop.yml` (only file modified by this feature)

**Tests**: No test tasks — not requested in the feature specification. Validation is manual end-to-end run against a fresh Hetzner Cloud Ubuntu server.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Read existing playbook)

**Purpose**: Understand the current state of `playbooks/setup-desktop.yml` before making changes

- [X] T001 Read `playbooks/setup-desktop.yml` to confirm current task structure before any edits

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Remove the two old curl-piped install tasks and the apt `gh` package entry — these MUST be done before adding Homebrew-based replacements to prevent conflicts

**Note**: All changes are in `playbooks/setup-desktop.yml`

- [X] T002 Remove `gh` from the apt name list in the "Install XFCE extras and developer tools" task in `playbooks/setup-desktop.yml` (keep `build-essential`, `libsecret-tools`, `seahorse`)
- [X] T003 Remove the "Install fnm (Fast Node Manager)" curl-piped shell task from `playbooks/setup-desktop.yml`
- [X] T004 Remove the "Install Claude Code CLI" curl-piped shell task from `playbooks/setup-desktop.yml`

**Checkpoint**: Old curl-piped installs and apt `gh` entry removed — Homebrew replacement tasks can now be added without conflicts

---

## Phase 3: User Story 2 - Install Developer Tools via Single Managed Source (Priority: P2) MVP

**Goal**: Install all developer CLI tools (`gh`, `fnm`, Node 24, Claude Code CLI) via Homebrew, replacing apt `gh` and both curl-piped scripts. This is the primary driver of the feature.

**Independent Test**: Run only the Homebrew-related tasks and confirm that `brew`, `gh`, `fnm`, `node`, and `claude` are all available to the target user without requiring any curl-piped scripts or apt packages for these tools.

### Implementation for User Story 2

- [X] T005 [US2] Add "Remove apt-installed gh (replaced by Homebrew)" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.apt: name=gh state=absent`, with `notify: Cleanup apt cache`, positioned after the XFCE extras task
- [X] T006 [US2] Add "Remove GitHub CLI apt source" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.file: path=/etc/apt/sources.list.d/github-cli.list state=absent`, positioned after T005; also add a second `ansible.builtin.file` task removing the GPG keyring at `/etc/apt/keyrings/githubcli-archive-keyring.gpg state=absent` to leave no orphaned keyring file
- [X] T007 [US2] Add "Install Homebrew for desktop users" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.shell` with `cmd: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`, `creates: "/home/{{ item }}/.linuxbrew/bin/brew"`, `become_user: "{{ item }}"`, `loop: "{{ desktop_user_names }}"`, and `environment: { NONINTERACTIVE: "1", HOME: "/home/{{ item }}" }` (HOME must be set explicitly so Homebrew detects the correct per-user install prefix when running under become_user), positioned after T006
- [X] T008 [US2] Add "Configure Homebrew PATH for desktop users" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.lineinfile` to add `eval "$(/home/{{ item }}/.linuxbrew/bin/brew shellenv)"` to `/home/{{ item }}/.bashrc` with `create: yes`, `owner/group/mode`, and `loop: "{{ desktop_user_names }}"`, positioned after T007
- [X] T009 [US2] Add "Install gh via Homebrew for desktop users" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.shell` with `cmd: /home/{{ item }}/.linuxbrew/bin/brew install gh`, `creates: "/home/{{ item }}/.linuxbrew/bin/gh"`, `become_user: "{{ item }}"`, `loop: "{{ desktop_user_names }}"`, positioned after T008
- [X] T010 [US2] Add "Install fnm via Homebrew for desktop users" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.shell` with `cmd: /home/{{ item }}/.linuxbrew/bin/brew install fnm`, `creates: "/home/{{ item }}/.linuxbrew/bin/fnm"`, `become_user: "{{ item }}"`, `loop: "{{ desktop_user_names }}"`, positioned after T009
- [X] T011 [US2] Add "Configure fnm in shell for desktop users" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.lineinfile` to add `eval "$(fnm env --use-on-cd)"` to `/home/{{ item }}/.bashrc` with `create: yes`, `owner/group/mode`, and `loop: "{{ desktop_user_names }}"`, positioned after T010
- [X] T012 [US2] Replace the existing "Install Node 24 via fnm" task in `playbooks/setup-desktop.yml` with the updated version that uses `/home/{{ item }}/.linuxbrew/bin/fnm install 24 && /home/{{ item }}/.linuxbrew/bin/fnm default 24` and `creates: "/home/{{ item }}/.local/share/fnm/aliases/default"` (fnm installs Node into a versioned directory like `v24.x.x`, not `v24`; the `aliases/default` file is reliably created by `fnm default 24` and makes an idempotent guard), removing the old `register`/`changed_when` approach
- [X] T013 [US2] Add "Install Claude Code CLI for desktop users" task (replacing the removed curl-piped task) in `playbooks/setup-desktop.yml` — uses `ansible.builtin.shell` with inline fnm init: `eval "$(/home/{{ item }}/.linuxbrew/bin/fnm env)" && fnm use 24 && npm install -g @anthropic-ai/claude-code`, `creates: "/home/{{ item }}/.local/bin/claude"` (npm global install places the `claude` binary at `~/.local/bin/claude` via fnm's global prefix; this path is stable regardless of the Node patch version installed), `become_user: "{{ item }}"`, `loop: "{{ desktop_user_names }}"`, positioned after the Node 24 task

**Checkpoint**: At this point, User Story 2 should be fully functional — all developer CLI tools installed via Homebrew, apt `gh` removed, curl-piped scripts gone

---

## Phase 4: User Story 3 - Add Firefox Browser (Priority: P3)

**Goal**: Install Firefox via apt so it is available immediately after provisioning without any manual steps.

**Independent Test**: Run only the Firefox installation task and confirm Firefox launches successfully on the provisioned desktop.

### Implementation for User Story 3

- [X] T014 [US3] Add "Install Firefox" task to `playbooks/setup-desktop.yml` — uses `ansible.builtin.apt: name=firefox state=present` with `notify: Cleanup apt cache`, positioned before "Remove GNOME remote desktop" (with the other apt install tasks)

**Checkpoint**: At this point, User Story 3 should be fully functional — Firefox installed via apt and idempotent on re-run

---

## Phase 5: User Story 4 - VS Code Continues to Work via Snap (Priority: P4)

**Goal**: Verify the existing VS Code snap task is untouched and still functional after all surrounding changes.

**Independent Test**: Run the VS Code snap task in isolation and confirm VS Code launches from the desktop after provisioning.

### Implementation for User Story 4

- [X] T015 [US4] Verify the "Install VS Code" snap task in `playbooks/setup-desktop.yml` is unchanged — confirm `community.general.snap: name=code classic=true state=present` is still present and no surrounding changes have inadvertently modified it

**Checkpoint**: VS Code snap task confirmed intact; all four user stories are now implemented

---

## Phase 6: User Story 1 - End-to-End Provision Validation (Priority: P1)

**Goal**: Confirm the full playbook hangs together correctly as a single coherent provision run — task ordering is correct, no duplicate tasks, idempotency guards are in place.

**Independent Test**: Run the full playbook against a fresh Ubuntu server and verify all expected tools (`brew`, `gh`, `fnm`, `node`, `npm`, `claude`, `code`, `firefox`) are callable from the desktop user's shell. Run again to confirm idempotency.

### Implementation for User Story 1

- [X] T016 [US1] Review the full task order in `playbooks/setup-desktop.yml` to confirm: apt `gh` removal (T005–T006) precedes Homebrew `gh` install (T009); Homebrew install (T007) precedes all `brew install` tasks; Homebrew PATH config (T008) precedes fnm install (T010); fnm shell config (T011) precedes Node install (T012); Node install (T012) precedes Claude Code CLI install (T013); Firefox (T014) is present among apt install tasks
- [X] T017 [US1] Verify all new tasks in `playbooks/setup-desktop.yml` have correct idempotency guards: `creates:` on all shell tasks, `state: absent` on removal tasks, `lineinfile` for PATH config lines, `state: present` on apt/snap tasks

**Checkpoint**: Full end-to-end playbook is coherent, ordered correctly, and idempotent — ready for manual validation run

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final review and cleanup

- [X] T018 Review `playbooks/setup-desktop.yml` for any remaining references to the old curl-piped fnm or Claude Code install paths (`~/.local/share/fnm/fnm`, `~/.local/bin/claude`) that are no longer valid after this change

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (read file first) — BLOCKS all user story work
- **User Story 2 (Phase 3)**: Depends on Phase 2 completion (old tasks removed before new ones added)
- **User Story 3 (Phase 4)**: Depends on Phase 2; independent of US2 but both target the same file — sequence after US2 for clarity
- **User Story 4 (Phase 5)**: Depends on Phase 2; can be verified at any point after foundational removals
- **User Story 1 (Phase 6)**: Depends on US2, US3, US4 being complete — validates the combined result
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 2 (P2)**: Primary implementation — must complete before US1 end-to-end validation
- **User Story 3 (P3)**: Independent of US2, but same file — sequence after US2 to avoid edit conflicts
- **User Story 4 (P4)**: Verification only — can be done any time after Phase 2
- **User Story 1 (P1)**: End-to-end validation — depends on all other stories being complete

### Within Each User Story

- Removal tasks (T002–T004) before addition tasks (T005–T013)
- Homebrew install (T007) before Homebrew PATH config (T008) before `brew install` tasks (T009–T010)
- fnm PATH config (T011) before Node install (T012) before Claude Code CLI install (T013)
- apt `gh` removal (T005–T006) before Homebrew `gh` install (T009)

### Parallel Opportunities

All tasks target a single file (`playbooks/setup-desktop.yml`), so true parallelism is limited. Within the foundational phase, T002–T004 are logically independent removals within the same file and can be planned together but must be applied sequentially to avoid edit conflicts.

---

## Parallel Example: User Story 2 (Homebrew CLI Tools)

```
# These tasks within US2 must be sequential (same file, ordered dependencies):
T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012 → T013

# US3 (Firefox, T014) and US4 verification (T015) can be done after US2
# or interleaved as separate edit operations on the same file
```

---

## Implementation Strategy

### MVP First (User Story 2 — Primary Driver)

1. Complete Phase 1: Read the playbook
2. Complete Phase 2: Remove old tasks (foundational — blocks everything)
3. Complete Phase 3: User Story 2 (Homebrew CLI tools)
4. **STOP and VALIDATE**: All Homebrew tools present; no curl-piped scripts; apt `gh` gone
5. Continue with US3 (Firefox) and US4 (VS Code verification)

### Incremental Delivery

1. Phase 1 + Phase 2 → File read and old tasks removed
2. Phase 3 (US2) → Homebrew consolidation complete — primary feature value delivered
3. Phase 4 (US3) → Firefox added
4. Phase 5 (US4) → VS Code confirmed intact
5. Phase 6 (US1) → End-to-end validation confirming all stories work together
6. Phase 7 → Polish pass

---

## Notes

- All tasks modify only `playbooks/setup-desktop.yml`
- No [P] markers on implementation tasks — single-file edits must be sequential
- [Story] labels map each task to its user story for traceability
- Idempotency guards are load-bearing: `creates:` on shell tasks, `lineinfile` for PATH lines, `state: absent/present` on package tasks
- US1 (P1) is intentionally last in implementation order because it validates the combined result of US2 + US3 + US4
- Commit after each phase or logical group to enable easy rollback
