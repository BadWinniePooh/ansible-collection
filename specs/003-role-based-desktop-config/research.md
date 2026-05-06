# Research: Role-Based Desktop Configuration

**Phase**: 0 — Pre-design research
**Feature**: `003-role-based-desktop-config`
**Date**: 2026-05-05

## Unknowns Resolved

### 1. `include_role` with a loop

**Decision**: Use `ansible.builtin.include_role` with `name: "{{ item }}"` and `loop: "{{ active_roles }}"` in a single task inside the play.

**Rationale**: This is the standard Ansible pattern for dynamic role loading. Unlike `import_role` (static, resolved at parse time), `include_role` is dynamic and supports variable interpolation in the `name` field. Ansible documentation explicitly supports this pattern.

**Alternatives considered**:
- `import_role` — rejected; static, cannot use variables in `name`.
- Separate plays per role — rejected; introduces excessive repetition and defeats the purpose of the loop.

**Example**:
```yaml
- name: Run active desktop roles
  ansible.builtin.include_role:
    name: "{{ item }}"
  loop: "{{ active_roles }}"
```

---

### 2. Dynamic `vars_files` with Jinja2 paths

**Decision**: `vars_files` entries support Jinja2 expressions. Extra-vars (highest Ansible variable precedence) are resolved before `vars_files` is loaded. Therefore `"vars/{{ provider }}-{{ platform }}.yml"` with `--extra-vars "provider=hetzner platform=linux"` works correctly.

**Rationale**: Ansible resolves `vars_files` paths using the known variable context at that point in play execution. Extra-vars are always available. This is documented Ansible behavior and widely used.

**Alternatives considered**:
- `include_vars` task — viable alternative; deferred to post-task inclusion rather than play-level loading. Rejected in favor of `vars_files` since play-level loading gives clearer precedence semantics and mirrors the spec's design intent.

---

### 3. Handler scoping with `include_role` in a loop

**Decision**: Each role's handlers are registered in the handler context of the including play. Handler names declared inside a role are merged into the play handler scope. A `notify: Cleanup apt cache` in `base_packages/tasks/main.yml` will correctly trigger `base_packages/handlers/main.yml:Cleanup apt cache` handler.

**Rationale**: When using `include_role`, handlers from the included role are added to the play's handler list. Role-local handlers run when flushed (at play end or `meta: flush_handlers`). Multiple roles can declare handlers with the same logical name; Ansible deduplicates by name within a play — the first registration wins.

**Implication**: `Cleanup apt cache` and `Restart XRDP` handlers must be defined in each role that uses them (as the spec requires). Since these are the same handler name across roles, only one definition will be active per play. This is fine — they are functionally identical.

**Alternatives considered**:
- Shared handlers in a common role — rejected; over-engineering for handlers that are each only 2–3 lines.

---

### 4. Play-level `vars` inheritance into roles

**Decision**: Roles included with `include_role` inherit all play-level variables, including those defined in the play's `vars:` block. Therefore `desktop_user_names: "{{ desktop_users | map(attribute='name') | list }}"` defined at play level is accessible inside all included roles.

**Rationale**: Ansible's variable scoping: play vars are in scope for all tasks within that play, including dynamically included roles. This is standard Ansible behavior.

---

### 5. `become: true` play-level propagation into roles

**Decision**: Play-level `become: true` propagates into all tasks within included roles. Task-level `become: false` overrides it for that specific task. This is consistent with how the original `setup-desktop.yml` managed the homebrew installer and user-scoped tasks.

**Rationale**: Ansible task-level `become` overrides play-level `become`. This is documented and stable behavior.

---

### 6. Role dependency declarations vs. runtime auto-inclusion

**Decision**: `meta/main.yml` dependencies declared with `dependencies:` are automatically included by Ansible when the parent role is invoked directly (via `roles:` or `include_role` without `apply_defaults`). However, when using `include_role` in a loop, Ansible **does** process `meta/main.yml` dependencies. The dependency roles run first.

**Rationale**: Per Ansible documentation, `include_role` respects `meta/main.yml` dependencies. This means if `github_cli` declares `homebrew` as a dependency, homebrew will run before github_cli even if `homebrew` was already run in the loop. Use `allow_duplicates: false` (the default) to prevent re-running.

**Implication**: Role dependencies in `meta/main.yml` serve both as documentation AND as runtime guards. The `active_roles` list order still controls the primary execution order, but dependencies provide a safety net.

**Alternatives considered**:
- Omitting dependencies and relying purely on `active_roles` order — viable but loses the safety net; rejected because it would silently break if an operator reorders the list.

---

### 7. `ansible_user` var in roles

**Decision**: The original `setup-desktop.yml` defined `ansible_user: "{{ my_hetzner_config.ansible_user.name }}"` as a play var. This is not needed in the new design — `ansible_user` was only referenced in task names/comments in the original, not in actual task logic. The `desktop_user_names` computed var is needed and will be defined at play level in `configure-linux.yml`.

**Rationale**: Inspecting the full `setup-desktop.yml` source confirms `ansible_user` was used only in task name strings, not in module parameters or `become_user`. The `desktop_user_names` var IS used in `loop:` targets and `become_user`. The new entry-point will define it.

---

### 8. `pre_tasks` (apt cache update) placement

**Decision**: The `pre_tasks` block from `setup-desktop.yml` (apt cache update) will move into `base_packages/tasks/main.yml` as a regular task. Since `base_packages` is first in `active_roles`, it runs first and updates the apt cache before any other apt operations.

**Rationale**: Play-level `pre_tasks` cannot be placed in individual roles. Since `base_packages` is the first role and the only one that performs apt operations before any other role needs a fresh cache, placing the apt update there achieves equivalent behavior.

**Alternatives considered**:
- Play-level `pre_tasks` in `configure-linux.yml` — viable; would guarantee it runs before any role. Slightly cleaner separation but mixes infrastructure concern (apt cache) with the entry-point orchestrator. Rejected to keep the entry-point purely orchestration.

## Summary

All NEEDS CLARIFICATION items resolved. No blocking unknowns. Implementation can proceed.
