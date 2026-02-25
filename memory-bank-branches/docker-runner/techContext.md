# Tech Context — docker-runner

## Host Environment

| Property | Value |
|---|---|
| Host OS | Windows 11 |
| Docker runtime | Docker Desktop for Windows (WSL2 backend) |
| Build context | Repo root (`c:\Users\NRueber\source\repos\private\ansible`) |

## Container Environment

| Property | Value |
|---|---|
| Base image | `ubuntu:22.04` (mirrors existing control node distro) |
| Ansible install | `pipx install ansible-core` |
| Ansible version | Matches control node (core 2.17.x) |
| Python | 3.10.x (Ubuntu 22.04 default) |
| Working directory | `/ansible` |
| Vault password mount | `-v <host_path>:/vault_pass:ro` |
| Env var | `ANSIBLE_VAULT_PASSWORD_FILE=/vault_pass` |
| Entrypoint | `docker/entrypoint.sh` |

## Repo Layout in Container

```
/ansible/               ← COPY . /ansible in Dockerfile
├── ansible.cfg
├── provision.yml
├── destroy.yml
├── inventories/
├── playbooks/
├── roles/
├── tasks/
└── configurations/
```

`ANSIBLE_CONFIG` is set to `/ansible/ansible.cfg` in the image (no direnv needed inside the container).

## Collections / Python Dependencies

- `hetzner.hcloud` Ansible collection (installed at build time)
- `hcloud` Python package (installed via pipx inject)
- `passlib` Python package (installed via pipx inject)
