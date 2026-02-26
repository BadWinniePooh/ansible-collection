# ── Build stage ───────────────────────────────────────────────────────────────
# Installs all build-time tooling. Nothing from this stage ends up in the final
# image except the explicit COPY --from=builder lines below.
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    pipx \
    git \
    openssh-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV PATH="/root/.local/bin:$PATH"

# Install ansible-core and required Python packages
# Copy requirements.txt first so this layer is cached independently of other repo changes
COPY requirements.txt /tmp/requirements.txt
RUN pipx install ansible-core==2.20.3 \
  && pipx runpip ansible-core install -r /tmp/requirements.txt

# Install Ansible collections declared in requirements.yml
# Copy requirements.yml first so this layer is cached independently of other repo changes
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml


# ── Runtime stage ─────────────────────────────────────────────────────────────
# Minimal image: only Python (needed to run the pipx venv) and openssh-client.
# No compilers, no pip, no pipx, no git — build tools stay in the builder stage.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    openssh-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Copy the pipx venv + ansible-playbook/ansible-galaxy wrappers from the builder
COPY --from=builder /root/.local /root/.local

# Copy installed Ansible collections from the builder
COPY --from=builder /root/.ansible /root/.ansible

ENV PATH="/root/.local/bin:$PATH"

# Point Ansible at the baked-in config (no direnv needed in container)
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

WORKDIR /ansible

# Copy the entire repo into the image
COPY . /ansible

# Make entrypoint executable
RUN chmod +x /ansible/.docker/entrypoint.sh

ENTRYPOINT ["/ansible/.docker/entrypoint.sh"]
