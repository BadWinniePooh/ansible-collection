# Ansible Learning Guidelines

These rules govern how we work together through this step-by-step Ansible learning project.

---

## 1. Structure

Each learning iteration covers one focused topic and follows this pattern:

1. **Concept explanation** — brief, to the point
2. **Practical example or exercise** — hands-on work in this repo
3. **Checkpoint** — you verify things work before we move on

---

## 2. Progression

Topics build on each other in the following order:

1. Basics (inventory, ad-hoc commands, playbooks)
2. Variables, facts & templates
3. Roles & project structure
4. Advanced features (conditionals, loops, handlers, tags)
5. Real-world scenarios (Hetzner Cloud, Linux server hardening, etc.)

---

## 3. Platform Awareness

- Ansible's **control node** must be Linux or macOS — bare Windows is not supported
- You run Windows locally, so we will set up **WSL2** (or a Linux VM) as the control node early on
- **Targets** will be Linux servers (e.g., Hetzner Cloud VMs) as well as other systems as needed
- Any platform-specific quirks (Windows management via `winrm`, macOS targets, etc.) will be addressed when the relevant scenario is reached

---

## 4. Code Quality

- All YAML files follow Ansible best-practice conventions (2-space indentation, explicit `---` document start, descriptive task names)
- The project directory structure follows the [official Ansible layout](https://docs.ansible.com/ansible/latest/tips_tricks/sample_setup.html)
- No hardcoded secrets — variables and Ansible Vault are used for sensitive data

---

## 5. Feedback & Fixes

- Issues are always pointed out **immediately** with a clear explanation
- You decide how to proceed — just say:
  - **"fix it"** — I apply the fix silently and explain what changed
  - **"hint me"** — I guide you toward the solution without giving it away directly

---

## 6. Workspace

- All Ansible work lives in this repository: `c:\Users\NRueber\source\repos\private\ansible`
- Sub-folders will follow the official Ansible project layout and be introduced progressively
- Files are committed incrementally so progress is always tracked in Git history

---

## 7. Git Usage

- Every completed learning step ends with a `git commit` to this repo
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) format:
  ```
  type(scope): short description
  ```
  Examples: `feat(inventory): add first static inventory file`, `docs(guidelines): initial project guidelines`
- Each commit message includes a Co-Author footer:
  ```
  Co-authored-by: GitHub Copilot <copilot@github.com>
  ```
- **All changes go on a feature branch** — direct commits to `main` are not allowed; changes reach `main` only via pull request
- Branch names follow the pattern `type/short-description`, e.g. `feat/dynamic-inventory`, `fix/ssh-key-handling`
- **You are responsible for `git push`** — I will only stage and commit locally
- Git commands are always run directly in the active terminal session — never via `wsl --` invocation
