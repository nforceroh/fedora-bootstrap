# Desktop Ansible Setup

Ansible playbook for provisioning a Fedora Workstation desktop. The playbook runs locally on the machine being configured and uses `sudo` for system changes.

## Fresh Fedora Setup

These steps assume a fresh Fedora Workstation installation and a user who can run `sudo`.

### 1. Install prerequisites

Update the system and install Git and Ansible:

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

Clone the repository and enter it:

```bash
git clone <repository-url> ~/repositories/init_desktop
cd ~/repositories/init_desktop
```

Replace `<repository-url>` with the URL of this repository.

### 3. Check the target user

The mouse-profile role defaults to the user `sylvain`. For another user, either edit `roles/mouse-profile/defaults/main.yml` or pass the values on the command line:

```bash
ansible-playbook --syntax-check initial_setup.yml
ansible-playbook -K \
  -e "target_user=$USER" \
  -e "home_dir=$HOME" \
  initial_setup.yml
```

`-K` prompts for the sudo password. Omit it when sudo is configured without a password prompt.

The playbook targets `localhost`, so no SSH inventory or remote host setup is required.

## Roles

The roles are selected in [`initial_setup.yml`](initial_setup.yml):

| Role | Purpose | Current status |
| --- | --- | --- |
| `system_setup` | Sets the hostname, installs Ansible and curl, and installs a custom CA certificate | Disabled |
| `vscode` | Adds Microsoft's repository and installs Visual Studio Code | Disabled |
| `lug-helper` | Installs the Star Citizen LUG Helper and gaming dependencies | Disabled; includes an interactive step |
| `fusion360` | Installs Autodesk Fusion 360 through an external Linux installer | Disabled; downloads and runs an external installer |
| `mouse-profile` | Installs Logitech G502 profile scripts, the PowerPlay udev rule, and login initialization | Enabled |

Uncomment the roles you want in `initial_setup.yml`, then run the playbook again. Review each role before enabling it on a new machine.

### Important role notes

- `system_setup` currently sets the hostname to `optimus` and downloads `https://ca.nf.lab/roots.pem`. Customize those tasks before enabling it on a different network or machine.
- `lug-helper` launches an interactive installer and should be run from an active graphical desktop session.
- `fusion360` downloads an installer from Codeberg and may take up to 30 minutes.
- The mouse profile role expects `ratbagctl` to be available and a Logitech G502/PowerPlay setup to be connected. A disconnected mouse does not fail the provisioning run.

## Running Safely

Run a syntax check before applying changes:

```bash
ansible-playbook --syntax-check initial_setup.yml
```

Preview supported changes with check mode:

```bash
ansible-playbook -K --check initial_setup.yml
```

Apply the configuration:

```bash
ansible-playbook -K initial_setup.yml
```

## Logitech G502 Profiles

The mouse-profile role installs:

- `~/.local/bin/reset-mouse-profile.sh`
- `~/.local/bin/wot-launcher.sh`
- `~/.config/autostart/reset-mouse-profile.desktop`
- `/etc/udev/rules.d/99-g502-kvm.rules`
- `~/.cache/g502-profile`

The cache records the most recently selected profile. The login entry initializes desktop profile `0`. The PowerPlay udev event restores the cached profile after the KVM reconnects.

Select the desktop profile manually:

```bash
~/.local/bin/reset-mouse-profile.sh 0
```

Select the gaming profile before launching a game:

```bash
~/.local/bin/reset-mouse-profile.sh 1
```

Launch World of Tanks with profile `1` and automatically return to profile `0` when it exits:

```bash
~/.local/bin/wot-launcher.sh
```

After changing the udev rule, reload it with:

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Customization

Role defaults are in each role's `defaults/main.yml`. The most relevant mouse-profile variables are:

```yaml
target_user: "your-user"
home_dir: "/home/your-user"
mouse_profile: "0"
powerplay_vendor_id: "046d"
powerplay_product_id: "c53a"
```

For repeatable machine-specific settings, add variables to `group_vars/` or pass them with `-e` rather than modifying role defaults.
