FROM ubuntu:24.04

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    openssh-client \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && pip3 install "pipx>=1.1.0" \
  && pipx ensurepath

# Ensure pipx-installed tools are on PATH
ENV PATH="/root/.local/bin:$PATH"

# Install ansible-core and required Python packages
# Copy requirements.txt first so this layer is cached independently of other repo changes
COPY requirements.txt /tmp/requirements.txt
RUN pipx install ansible-core==2.17.14 \
  && pipx inject ansible-core -r /tmp/requirements.txt

# Install Ansible collections declared in requirements.yml
# Copy requirements first so this layer is cached independently of other repo changes
COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml

# Point Ansible at the baked-in config (no direnv needed in container)
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

WORKDIR /ansible

# Copy the entire repo into the image
COPY . /ansible

# Make entrypoint executable
RUN chmod +x /ansible/.docker/entrypoint.sh

ENTRYPOINT ["/ansible/.docker/entrypoint.sh"]
