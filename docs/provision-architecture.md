# Provision Architecture

```mermaid
flowchart TD
    CLI["ansible-playbook provision.yml\n--extra-vars 'provider=hcloud platform=linux'"]

    subgraph provision["provision.yml (entry point)"]
        P1["import_playbook:\nprovisioners/hetzner-linux-up.yml"]
        P2["import_playbook:\nconfigurations/configure-linux.yml"]
    end

    CLI --> P1
    P1 --> P2

    subgraph provisioner["provisioners/hetzner-linux-up.yml\nhosts: localhost (connection: local)"]
        PR_VARS["vars_files"]
        PR_T1["import_tasks:\ntasks/hetzner/ensure-ssh-key.yml"]
        PR_T2["task: hetzner.hcloud.server\n(create server)"]
        PR_T3["meta: refresh_inventory"]
        PR_T4["import_tasks:\ntasks/add-server-to-known-hosts.yml"]

        PR_VARS --> PR_T1 --> PR_T2 --> PR_T3 --> PR_T4
    end

    P1 --> provisioner

    subgraph prov_vars["Provisioner vars_files"]
        V1["inventories/group_vars/all/vars.yml\n(my_hetzner_config, desktop_users)"]
        V2["inventories/group_vars/all/vault.yml\n(vault secrets - encrypted)"]
        V3["inventories/group_vars/hcloud_location/vars.yml\n(hcloud_default_location: hel1)"]
        V4["inventories/group_vars/hcloud_type/vars.yml\n(hcloud_default_type: cx33)"]
    end

    PR_VARS --> prov_vars

    subgraph tasks["Task files"]
        T1["tasks/hetzner/ensure-ssh-key.yml\nhetzner.hcloud.ssh_key\n(upload local pubkey → Hetzner API)"]
        T2["tasks/add-server-to-known-hosts.yml\nssh-keyscan → known_hosts\n(retries until server available)"]
    end

    PR_T1 --> T1
    PR_T4 --> T2

    subgraph configure["configurations/configure-linux.yml\nhosts: all (become: true)"]
        C1["import_playbook:\nplaybooks/setup-users.yml"]
        C2["vars_files:\nconfigurations/vars/hetzner-linux.yml"]
        C3["include_role loop\nover active_roles"]

        C1 --> C2 --> C3
    end

    P2 --> configure

    subgraph setup_users["playbooks/setup-users.yml\nhosts: all (become: true, user: root)"]
        SU1["Create user accounts\n(console_users + desktop_users)"]
        SU2["Grant passwordless sudo\nto ansible user"]
        SU3["Add SSH pubkey\nto all users"]
        SU4["Disable SSH password auth\n→ handler: Restart SSH"]

        SU1 --> SU2 --> SU3 --> SU4
    end

    C1 --> setup_users

    subgraph roles["Roles (active_roles from hetzner-linux.yml)"]
        R1["base_packages\n(apt packages, system deps)"]
        R2["dotnet\n(.NET SDK)"]
        R3["firefox\n(browser)"]
        R4["homebrew\n(Linuxbrew)"]
        R5["github_cli\n(gh)"]
        R6["fnm\n(Node version manager)"]
        R7["claude_code\n(Claude Code CLI)"]
        R8["remote_desktop\n(xrdp/desktop env)"]
        R9["vscode\n(VS Code)"]
    end

    C3 --> roles

    subgraph inventory["Dynamic Inventory"]
        INV["inventories/hcloud.yml\nplugin: hetzner.hcloud.hcloud\nfilter: platform=linux\ncompose: ansible_user=root"]
    end

    provisioner -. "refresh_inventory" .-> inventory
    configure -. "targets hosts from inventory" .-> inventory

    subgraph config_vars["Configuration vars (provider-platform)"]
        CV1["configurations/vars/hetzner-linux.yml\nactive_roles: all 9 roles"]
        CV2["configurations/vars/other-linux.yml\nactive_roles: base_packages,\nhomebrew, github_cli"]
    end

    C2 --> CV1
    C2 -. "alt provider" .-> CV2

    HCLOUD_API["Hetzner Cloud API\nhetzner.hcloud collection"]
    T1 -. "API call" .-> HCLOUD_API
    PR_T2 -. "API call" .-> HCLOUD_API
```

## Flow Summary

1. **Provision phase** — `hetzner-linux-up.yml` runs on `localhost`, uploads SSH key to Hetzner API, creates the cloud server, scans + trusts its host key.
2. **Configure phase** — `configure-linux.yml` runs on the new server (via dynamic inventory). First creates user accounts and hardens SSH (`setup-users.yml`), then loops over `active_roles` to install the full software stack.
3. **Role set** is provider-specific: `hetzner-linux.yml` activates all 9 roles; `other-linux.yml` activates only 3.
4. **Secrets** flow from `vault.yml` (Ansible Vault encrypted) → `vars.yml` → provisioner + configure plays.
