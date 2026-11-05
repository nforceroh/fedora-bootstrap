# Fedora Bootstrap

Ansible playbook for provisioning a Fedora Workstation. Supports multiple machines (optimus desktop + raider laptop) under a single playbook.

## Overview

This playbook targets `localhost` with an inventory that defines two host groups:
- `[optimus]` — the ASUS TUF GAMING X670E-PLUS WIFI desktop (KDE Plasma)
- `[raider]` — a laptop

Run on each machine with:
```bash
ansible-playbook -K -i inventory.ini initial_setup.yml
```

The playbook uses `hosts: fedora` and gates roles with `when:` conditions per host group.

## Fresh Fedora Setup

These steps assume a fresh Fedora Workstation installation and a user who can run `sudo`.

### 1. Install prerequisites

```bash
sudo dnf upgrade --refresh -y
sudo dnf install -y git ansible-core
```

Verify the tools:

```bash
git --version
ansible-playbook --version
```

### 2. Get this repository

```bash
git clone <repository-url> ~/repositories/init_desktop
cd ~/repositories/init_desktop
```

Replace `<repository-url>` with the URL of this repository.

### 3. Run the playbook

```bash
ansible-playbook -K -i inventory.ini initial_setup.yml
```

`-K` prompts for the sudo password. Omit it when sudo is configured without a password prompt.

The playbook targets `localhost` via the `inventory.ini` — no SSH inventory or remote host setup is required.

## Inventory

`inventory.ini` defines two groups:

```ini
[optimus]
optimus ansible_connection=local ansible_python_interpreter=/usr/bin/python3

[raider]
raider ansible_connection=local ansible_python_interpreter=/usr/bin/python3

[fedora:children]
optimus
raider
```

- Run for optimus: `ansible-playbook -K -i inventory.ini initial_setup.yml`
- Run for raider: same command; roles are gated by group variables

## Roles

Roles are selected in `initial_setup.yml`. The playbook targets the `fedora` group and includes roles gated by host-group variables:

| Role | When enabled | Purpose |
|---|---|---|
| `system_setup` | always | Sets hostname, installs Ansible/curl, downloads custom CA cert |
| `dev_tools` | always | Installs dev packages (`git, gh, fzf, ripgrep, jq, btop, ...`) |
| `docker` | always | Adds Docker CE repo, installs packages, enables service, adds user to docker group |
| `tabby` | always | Adds PackageCloud Tabby repo, installs tabby RPM |
| `vscode` | always | Adds Microsoft repo, installs Visual Studio Code |
| `lug-helper` | `enable_lug_helper` (optimus only) | Installs Star Citizen LUG Helper and gaming dependencies |
| `fusion360` | `enable_fusion360` (both) | Installs Autodesk Fusion 360 through external Linux installer |

Per-host variables are in `group_vars/optimus.yml` and `group_vars/raider.yml`.

### Optimus (desktop) — `group_vars/optimus.yml`

```yaml
hostname: "optimus"
enable_lug_helper: true
enable_fusion360: true
```

### Raider (laptop) — `group_vars/raider.yml`

```yaml
hostname: "raider"
enable_lug_helper: false
enable_fusion360: true
```

## Running Safely

```bash
ansible-playbook --syntax-check -i inventory.ini initial_setup.yml
ansible-playbook -K --check -i inventory.ini initial_setup.yml
ansible-playbook -K -i inventory.ini initial_setup.yml
```

## Customization

Role defaults are in each role's `defaults/main.yml`. Override per-host in `group_vars/` or pass with `-e` on the command line.

New roles added in this refactor:

- `dev_tools` — installs `git, gh, fzf, ripgrep, jq, btop, tree, zoxide, fd-find, ncdu, unzip, curl, make, gcc`
- `docker` — Docker CE repo + packages + service enable + docker group
- `tabby` — PackageCloud Tabby repo + tabby RPM

Removed roles:

- `mouse-profile` — Logitech G502 profile scripts and udev rules (removed per user request)

For machine-specific tweaks, add variables to `host_vars/<hostname>.yml` or override with `-e`.
