#!/bin/bash
set -euo pipefail

version_check() {
  local current_version latest_version
  current_version=$(tr -d '[:space:]' < /ansible/VERSION 2>/dev/null) || return 0
  [[ -z "$current_version" || "$current_version" == "dev" ]] && return 0
  latest_version=$(python3 -c "
import urllib.request, json, sys
try:
    req = urllib.request.Request(
        'https://api.github.com/repos/BadWinniePooh/ansible-collection/releases/latest',
        headers={
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'ansible-runner-update-check/1.0',
            'X-GitHub-Api-Version': '2022-11-28',
        }
    )
    with urllib.request.urlopen(req, timeout=3) as r:
        print(json.load(r)['tag_name'])
except Exception:
    sys.exit(1)
" 2>/dev/null) || return 0
  [[ -z "$latest_version" ]] && return 0
  # Normalise versions for comparison (strip leading 'v' if present)
  local current_cmp="${current_version#v}"
  local latest_cmp="${latest_version#v}"
  if [[ "$current_cmp" != "$latest_cmp" ]]; then
    echo ""
    echo "*** Update available ***"
    echo "Current version : ${current_version}"
    echo "Latest version  : ${latest_version}"
    echo "Pull the latest image: docker pull ghcr.io/badwinniepooh/ansible-runner:${latest_version}"
    echo ""
  fi
}

version_check

VAULT_FILE="/ansible/inventories/group_vars/all/vault.yml"
SSH_KEY="/root/.ssh/hetzner_ansible"
VAULT_PASS="/vault_pass"

# Default vault password file location — override with -e ANSIBLE_VAULT_PASSWORD_FILE=...
export ANSIBLE_VAULT_PASSWORD_FILE="${ANSIBLE_VAULT_PASSWORD_FILE:-$VAULT_PASS}"

if [[ ! -f "$ANSIBLE_VAULT_PASSWORD_FILE" ]]; then
  echo ""
  echo "WARNING: vault password file not found at ${ANSIBLE_VAULT_PASSWORD_FILE}."
  echo "Plays that use vault will fail. Mount it with:"
  echo "  -v ~/vault.password:${VAULT_PASS}:ro"
  echo ""
fi

if [[ ! -f "$VAULT_FILE" ]]; then
  echo ""
  echo "WARNING: vault.yml is not mounted. Plays that reference vault variables will fail."
  echo "Mount it with:"
  echo "  -v /path/to/your/vault.yml:${VAULT_FILE}:ro"
  echo ""
fi

if [[ ! -f "$SSH_KEY" ]]; then
  echo ""
  echo "WARNING: SSH key not found at ${SSH_KEY}."
  echo "Plays that connect to managed nodes will fail."
  echo "Mount your host key with:"
  echo "  -v ~/.ssh/hetzner_ansible:/root/.ssh/hetzner_ansible:ro"
  echo "  -v ~/.ssh/hetzner_ansible.pub:/root/.ssh/hetzner_ansible.pub:ro"
  echo ""
fi

if [[ -z "${PLAYBOOK:-}" ]]; then
  echo ""
  echo "ERROR: PLAYBOOK environment variable is required."
  echo ""
  echo "Usage:"
  echo "  docker run --rm \\"
  echo "    -e PLAYBOOK=provision.yml \\"
  echo "    -v ~/.vault_pass:/vault_pass:ro \\"
  echo "    ansible-runner \\"
  echo "    [--extra-vars \"key=value\"] [--tags tag1,tag2] [...]"
  echo ""
  echo "Available playbooks:"
  find /ansible -maxdepth 1 -name '*.yml' \
    ! -name 'requirements.yml' \
    | sed 's|^/ansible/||' | sort
  echo ""
  exit 1
fi

echo "Running: ansible-playbook ${PLAYBOOK} $*"
exec ansible-playbook "/ansible/${PLAYBOOK}" "$@"
