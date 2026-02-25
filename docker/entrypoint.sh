#!/bin/bash
set -euo pipefail

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
  echo "Available top-level playbooks:"
  find /ansible -maxdepth 2 -name '*.yml' \
    ! -path '*/memory-bank-branches/*' \
    ! -path '*/group_vars/*' \
    ! -path '*/host_vars/*' \
    | sed 's|^/ansible/||' | sort
  echo ""
  exit 1
fi

echo "Running: ansible-playbook ${PLAYBOOK} $*"
exec ansible-playbook "/ansible/${PLAYBOOK}" "$@"
