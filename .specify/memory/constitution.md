<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0
Added sections: Core Principles, Infrastructure Requirements, Development Workflow, Governance
Removed sections: none (initial fill)
Templates requiring updates:
  - .specify/templates/plan-template.md  ✅ Constitution Check gates align with principles below
  - .specify/templates/spec-template.md  ✅ Requirements section aligns with provider/vault constraints
  - .specify/templates/tasks-template.md ✅ Task types cover provisioner, role, vault, Docker test tasks
Deferred TODOs: none
-->

# Ansible Developer VM Collection Constitution

## Core Principles

### I. Provider Abstraction

All provisioning and teardown operations MUST be routed through a provider-agnostic interface.
The `provider` extra-var selects the active backend (e.g., `provider=hetzner`, `provider=docker`).
Adding a new backend MUST NOT require changes to `provision.yml`, `destroy.yml`, roles, or
shared tasks outside the provider-specific provisioner file under `provisioners/`.
Provider-specific logic is confined to `provisioners/<provider>-<platform>-up.yml` and
`provisioners/<provider>-<platform>-down.yml`.

### II. Idempotent Playbooks

Every playbook and role MUST be idempotent. Running the same playbook multiple times against
the same target MUST produce identical end-state without side effects, duplicate resources, or
errors on subsequent runs. Tasks MUST use Ansible modules (not raw shell) wherever a module
exists. Shell/command tasks MUST include an appropriate `changed_when` or `creates` guard.

### III. Vault-Only Secrets (NON-NEGOTIABLE)

No secret, credential, API token, or password MAY appear in plaintext in any committed file.
ALL sensitive values MUST reside in Ansible Vault-encrypted files. Vault files MUST be listed
in `.gitignore`. Vault-encrypted variables MUST be prefixed `vault_`. Plaintext variable files
MUST reference vault variables (double-variable pattern) — never inline secrets directly.
Committing unencrypted vault content is a blocking violation requiring immediate remediation.

### IV. Docker-First Local Testing

All new roles and playbooks MUST be testable locally against a Docker container target before
any deployment to a cloud provider. Docker MUST be the default `provider` value for development
and CI. A Docker-based test run MUST complete successfully before a Hetzner Cloud deployment is
considered valid for review. Docker test targets MUST mirror the OS family and init system of
the production target where feasible.

### V. Declarative Configuration

Infrastructure and configuration state MUST be declared in YAML using Ansible tasks and roles.
Ad-hoc `ansible` commands MUST NOT substitute for playbooks in automated workflows. Shell-heavy
workarounds MUST NOT replace proper Ansible modules when a suitable module exists. Variables
controlling environment-specific behavior MUST be stored in inventory `group_vars` or passed as
`--extra-vars`, never hardcoded in playbook files.

## Infrastructure Requirements

- **Control node**: Linux or macOS only (WSL2 Ubuntu 22.04+ on Windows is supported).
  Bare Windows as a control node is NOT supported.
- **Target platforms**: Linux servers (Debian/Ubuntu family). Windows and macOS targets are
  out of scope unless explicitly added as a new provider/platform pair.
- **Primary production provider**: Hetzner Cloud via `hetzner.hcloud` collection.
- **Primary test provider**: Docker container (local). CI pipelines MUST use Docker provider.
- **Dependencies**: Managed via `requirements.yml` (collections) and `requirements.txt`
  (Python packages injected into the `ansible-core` pipx venv). Both files MUST be kept in sync.
- **Dynamic inventory**: Cloud providers MUST use a dynamic inventory plugin, not static host
  files, to reflect real-time resource state.

## Development Workflow

1. **Feature branch** per change. No direct commits to `main`.
2. **Docker test gate** MUST pass locally before opening a PR. Run:
   `ansible-playbook ./provision.yml --extra-vars "provider=docker platform=linux"`
   followed by the target configuration playbook, then teardown.
3. **Vault check**: Verify no plaintext secrets with `git diff --staged` before every commit.
4. **Lint gate**: `ansible-lint` MUST report zero errors on modified playbooks/roles.
5. **PR review**: At least one peer review required before merge to `main`.
6. **Hetzner deploy**: Only from `main`. Requires vault password and explicit `provider=hetzner`.

## Governance

This constitution supersedes all other documented practices for this repository. Any practice
contradicting a principle here MUST be updated to comply.

**Amendment procedure**:
- PATCH (clarifications, wording): single-author PR with updated `Last Amended` date.
- MINOR (new principle or section): PR + at least one reviewer approval.
- MAJOR (principle removal or breaking redefinition): PR + team discussion documented in PR body.

All amendments MUST increment `CONSTITUTION_VERSION` per semantic versioning rules and update
`Last Amended`. Ratification date is frozen at original adoption.

Compliance is verified during PR review via the Constitution Check section of `plan-template.md`.
Use `GUIDELINES.md` for day-to-day Ansible coding conventions.

**Version**: 1.0.0 | **Ratified**: 2026-05-05 | **Last Amended**: 2026-05-05
