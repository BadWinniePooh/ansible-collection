# Tasks: Role-Based Desktop Configuration

**Input**: Design documents from `specs/003-role-based-desktop-config/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1/US2/US3)
- No test tasks — not requested in spec

---

## Phase 1: Setup

**Purpose**: Create the provider+platform vars file and rewrite the entry-point orchestrator. These two files wire everything together and are prerequisites for all user stories.

- [ ] T001 Create `configurations/vars/hetzner-linux.yml` with ordered `active_roles` list containing all nine role names: `base_packages`, `dotnet`, `firefox`, `homebrew`, `github_cli`, `fnm`, `claude_code`, `remote_desktop`, `vscode`
- [ ] T002 Rewrite `configurations/configure-linux.yml` as a single orchestration file: import `../playbooks/setup-users.yml` first, then a single play (`hosts: all`, `become: true`) that defines `desktop_user_names` in `vars:`, loads `vars_files: ["vars/{{ provider }}-{{ platform }}.yml"]`, and uses `ansible.builtin.include_role name="{{ item }}" loop="{{ active_roles }}"` to execute each role in order

**Checkpoint**: Entry-point and vars file ready. Role directories can now be created in parallel.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No additional foundational infrastructure is required beyond Phase 1. The `configure-linux.yml` rewrite in T002 is the only structural prerequisite for all three user stories. Proceed directly to user story phases.

**⚠️ CRITICAL**: T001 and T002 must be complete before running any provisioning test.

---

## Phase 3: User Story 1 — Full Hetzner Provisioning Works Unchanged (Priority: P1) 🎯 MVP

**Goal**: All nine roles exist on disk with tasks migrated 1:1 from `setup-desktop.yml`. A full `provision.yml` run produces the identical software state as the original monolithic playbook.

**Independent Test**: Run `ansible-playbook ./provision.yml --extra-vars "provider=hetzner platform=linux" --vault-password-file ~/.vault_pass` against a fresh Hetzner Linux host. Verify `curl`, `tree`, `unzip`, `build-essential`, `libsecret-tools`, `seahorse`, `python3-full`, `dotnet-sdk-8.0`, `dotnet-sdk-10.0`, `firefox`, Homebrew, `gh`, `fnm`, Node 24, Claude Code CLI, VS Code (snap), XFCE4, and XRDP are all installed and configured.

### Implementation for User Story 1 (all tasks are parallel — each creates a different role directory)

- [ ] T003 [P] [US1] Create `roles/base_packages/tasks/main.yml` with: apt cache update task (cache_valid_time: 3600); single apt task installing `curl`, `tree`, `unzip`, `python3-full`, `build-essential`, `libsecret-tools`, `seahorse` (state: present, notify: Cleanup apt cache). Create `roles/base_packages/handlers/main.yml` with `Cleanup apt cache` handler (apt autoremove+autoclean). Create `roles/base_packages/meta/main.yml` with empty `dependencies: []`.

- [ ] T004 [P] [US1] Create `roles/dotnet/tasks/main.yml` with apt task installing `dotnet-sdk-8.0` and `dotnet-sdk-10.0` (state: present, notify: Cleanup apt cache). Create `roles/dotnet/handlers/main.yml` with `Cleanup apt cache` handler. Create `roles/dotnet/meta/main.yml` with empty `dependencies: []`.

- [ ] T005 [P] [US1] Create `roles/firefox/tasks/main.yml` with apt task installing `firefox` (state: present, notify: Cleanup apt cache). Create `roles/firefox/handlers/main.yml` with `Cleanup apt cache` handler. Create `roles/firefox/meta/main.yml` with empty `dependencies: []`.

- [ ] T006 [P] [US1] Create `roles/homebrew/tasks/main.yml` with two tasks: (1) `ansible.builtin.shell` running the Linuxbrew installer (`NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`, creates: `/home/linuxbrew/.linuxbrew/bin/brew`, `become: false`); (2) `ansible.builtin.lineinfile` adding `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` to `/home/{{ item }}/.bashrc` for each item in `desktop_user_names` (regexp: `brew shellenv`, create: true, owner/group/mode: 0644). Create `roles/homebrew/meta/main.yml` with `dependencies: []`.

- [ ] T007 [P] [US1] Create `roles/github_cli/tasks/main.yml` with one task: `ansible.builtin.shell` running `/home/linuxbrew/.linuxbrew/bin/brew install gh` (creates: `/home/linuxbrew/.linuxbrew/bin/gh`, `become: false`). Create `roles/github_cli/meta/main.yml` with `dependencies: [homebrew]`.

- [ ] T008 [P] [US1] Create `roles/fnm/tasks/main.yml` with five tasks: (1) `ansible.builtin.shell` `brew install fnm` (creates: `/home/linuxbrew/.linuxbrew/bin/fnm`, `become: false`); (2) `ansible.builtin.lineinfile` adding `eval "$(/home/linuxbrew/.linuxbrew/bin/fnm env --use-on-cd)"` to `/home/{{ item }}/.bashrc` per `desktop_user_names` (regexp: `fnm env`, create: true, owner/group/mode: 0644); (3) `ansible.builtin.shell` `fnm install 24` (creates: `/home/{{ item }}/.local/share/fnm/node-versions/v24`, `become_user: "{{ item }}"`, env `HOME: /home/{{ item }}`) per `desktop_user_names`; (4) `ansible.builtin.shell` `fnm default 24` (`become_user: "{{ item }}"`, env `HOME: /home/{{ item }}`, `changed_when: fnm_default.rc == 0`, register fnm_default) per `desktop_user_names`; (5) `ansible.builtin.lineinfile` adding `prefix=~/.local` to `/home/{{ item }}/.npmrc` (regexp: `^prefix=`, create: true, owner/group/mode: 0644) per `desktop_user_names`. Create `roles/fnm/meta/main.yml` with `dependencies: [homebrew]`.

- [ ] T009 [P] [US1] Create `roles/claude_code/tasks/main.yml` with one task: `ansible.builtin.shell` running `eval "$(/home/linuxbrew/.linuxbrew/bin/fnm env --shell bash)" && /home/linuxbrew/.linuxbrew/bin/fnm use 24 && npm install -g @anthropic-ai/claude-code` (creates: `/home/{{ item }}/.local/bin/claude`, `become_user: "{{ item }}"`, env `HOME: /home/{{ item }}"`) looped over `desktop_user_names`. Create `roles/claude_code/meta/main.yml` with `dependencies: [fnm]`.

- [ ] T010 [P] [US1] Create `roles/remote_desktop/tasks/main.yml` with all tasks tagged `not-supported-on-vagrant-docker`: (1) apt remove `gh` (state: absent, notify: Cleanup apt cache); (2) file remove `/etc/apt/sources.list.d/github-cli.list` (state: absent); (3) file remove `/etc/apt/keyrings/githubcli-archive-keyring.gpg` (state: absent); (4) apt remove `gnome-remote-desktop` (state: absent, notify: Cleanup apt cache); (5) apt install `dbus-x11`, `xfce4`, `xfce4-goodies`, `xrdp` (state: present, notify: Cleanup apt cache); (6) service `xrdp` (state: started, enabled: true); (7) apt remove `light-locker` (state: absent, notify: Cleanup apt cache); (8) lineinfile writing `xfce4-session` to `/home/{{ item }}/.xsession` (regexp: `^.*`, create: true, owner/group/mode: 0644, notify: Restart XRDP) looped over `desktop_user_names`. Create `roles/remote_desktop/handlers/main.yml` with both `Cleanup apt cache` and `Restart XRDP` handlers. Create `roles/remote_desktop/meta/main.yml` with `dependencies: []`.

- [ ] T011 [P] [US1] Create `roles/vscode/tasks/main.yml` with one task: `community.general.snap` installing `code` (classic: true, state: present). Create `roles/vscode/meta/main.yml` with `dependencies: []`.

**Checkpoint**: All nine roles exist. The complete provisioning pipeline (`provision.yml → configure-linux.yml → setup-users.yml + roles loop`) is ready for an end-to-end test against a Hetzner Linux host.

---

## Phase 4: User Story 2 — Selectively Enable/Disable Components (Priority: P2)

**Goal**: Confirm that removing a role name from `active_roles` in `configurations/vars/hetzner-linux.yml` causes that component to be skipped with no side effects.

**Independent Test**: Edit `configurations/vars/hetzner-linux.yml`, remove `dotnet` from `active_roles`, run provisioning, verify `dotnet-sdk-8.0` and `dotnet-sdk-10.0` are absent. Restore the line afterward.

**No new implementation tasks required**: US2 is inherently satisfied by the `include_role` loop design implemented in T002. The `active_roles` list is the single control point — operators edit only the vars file.

- [ ] T016 [US2] Verify selective role execution: remove one role name (e.g. `dotnet`) from `active_roles` in `configurations/vars/hetzner-linux.yml`, run provisioning, confirm the removed component is absent on the host, restore the entry

**Checkpoint**: US2 is verified at runtime using the output of Phase 1 + Phase 3. No code changes needed beyond confirming the design works as intended.

---

## Phase 5: User Story 3 — Add a New Provider+Platform Configuration (Priority: P3)

**Goal**: Demonstrate that a second provider+platform vars file works with the existing entry-point, proving the design generalises without any playbook changes.

**Independent Test**: Run `ansible-playbook ./configurations/configure-linux.yml --extra-vars "provider=other platform=linux" --vault-password-file ~/.vault_pass` and verify only the roles declared in the file execute.

- [ ] T012 [P] [US3] Create `configurations/vars/other-linux.yml` with a trimmed `active_roles` list (e.g., `base_packages`, `homebrew`, `github_cli`) to serve as a documented second-provider example. This file is both a test fixture and the reference pattern for adding new provider+platform combinations.

**Checkpoint**: Two provider vars files exist. The entry-point playbook is unchanged. Operators can create additional `<provider>-<platform>.yml` files without touching any other file.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Lint validation, syntax verification, and retirement of the monolithic playbook.

- [ ] T013 [P] Run `ansible-lint roles/base_packages roles/dotnet roles/firefox roles/homebrew roles/github_cli roles/fnm roles/claude_code roles/remote_desktop roles/vscode configurations/configure-linux.yml` and resolve any reported errors (zero errors required)
- [ ] T014 [P] Run `ansible-playbook --syntax-check configurations/configure-linux.yml --extra-vars "provider=hetzner platform=linux"` to validate playbook structure parses correctly
- [ ] T017 [US1] Run `ansible-playbook ./provision.yml --extra-vars "provider=hetzner platform=linux" --vault-password-file ~/.vault_pass` against a Hetzner Linux test host; confirm all nine components are installed and XRDP is running; this is the gate for T015
- [ ] T015 Delete `playbooks/setup-desktop.yml` (depends on T017 passing; this file is superseded by the role-based pipeline)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: N/A — merged into Phase 1
- **User Story 1 (Phase 3)**: Depends on Phase 1 completion (T001 + T002 must exist before roles can be tested)
- **User Story 2 (Phase 4)**: Depends on Phase 1 + Phase 3 — no new implementation
- **User Story 3 (Phase 5)**: Depends on Phase 1 (configure-linux.yml exists) — can be created in parallel with Phase 3
- **Polish (Phase 6)**: Depends on all prior phases

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 1. All 9 role creation tasks are mutually independent and run in parallel.
- **US2 (P2)**: Depends on US1 completion — verified at runtime, no code changes.
- **US3 (P3)**: Depends on Phase 1 (T002) only — `configurations/vars/other-linux.yml` can be created as soon as configure-linux.yml exists.

### Within Each User Story

- T003–T011: All parallel — each creates a different `roles/<name>/` directory tree
- T013–T014: Both parallel — independent lint and syntax checks

### Parallel Opportunities

- After T001+T002 complete: T003–T011 can all run simultaneously (different directories)
- T012 can run in parallel with T003–T011 (different directory)
- T013 and T014 can run in parallel (read-only validation)

---

## Parallel Example: User Story 1

```bash
# After T001 and T002 complete, run all role creation in parallel:
# Worker A: T003 (base_packages) + T004 (dotnet) + T005 (firefox)
# Worker B: T006 (homebrew) + T007 (github_cli)
# Worker C: T008 (fnm) + T009 (claude_code)
# Worker D: T010 (remote_desktop)
# Worker E: T011 (vscode)

# T012 (other-linux.yml) can run alongside any of the above
```

---

## Implementation Strategy

**MVP scope**: Complete Phase 1 → Phase 3 (T001–T011). This delivers US1 (full provisioning) and inherently enables US2 (selective roles). US3 (T012) and Polish (T013–T015) can follow.

**Incremental delivery**:
1. T001 + T002 — wiring complete (5 min)
2. T003–T005 — simple apt roles (parallel, ~15 min)
3. T006–T009 — Homebrew chain roles (parallel, ~20 min)
4. T010 — remote_desktop role (most complex, ~20 min)
5. T011 — vscode role (2 min)
6. T012 — other-linux.yml (2 min)
7. T013–T015, T017 — polish

**Total task count**: 17
**Tasks per user story**: US1=10 (T003–T011, T017), US2=1 (T016), US3=1 (T012)
**Parallel opportunities**: 9 (T003–T011 all parallel after T002)
