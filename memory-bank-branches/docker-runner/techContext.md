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
| Base image | `ubuntu:24.04` |
| Ansible install | `pipx install ansible-core` |
| Ansible version | `ansible-core==2.20.3` |
| Python | 3.12.x (Ubuntu 24.04 default) |
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
- `hcloud` Python package (installed via `pipx runpip ansible-core install -r requirements.txt`)
- `passlib` Python package (installed via `pipx runpip ansible-core install -r requirements.txt`)
