#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

PROFILE_SCRIPT="$(dirname "$0")/reset-mouse-profile.sh"
PROFILE_ACTIVATED=0

restore_desktop_profile() {
    if [ "$PROFILE_ACTIVATED" -eq 1 ]; then
        "$PROFILE_SCRIPT" 0
    fi
}

trap restore_desktop_profile EXIT

if ! "$PROFILE_SCRIPT" 1; then
    echo "Error: Could not activate the World of Tanks mouse profile."
    exit 1
fi
PROFILE_ACTIVATED=1

echo "World of Tanks mouse profile activated."

# Launch World of Tanks via Bottles CLI engine.
flatpak run --command=bottles-cli com.usebottles.bottles run -b "WoT" -p "WorldOfTanks"

# Give the game a few seconds to initialize and register a process name.
echo "Waiting for World of Tanks process to spawn..."
sleep 5

# Bottles may return before the Wine process exits, so wait for the game too.
while pgrep -i -f "WorldOfTanks" > /dev/null || pgrep -i -f "wot.exe" > /dev/null; do
    sleep 3
done

echo "World of Tanks has closed; restoring the desktop mouse profile."
restore_desktop_profile
PROFILE_ACTIVATED=0
sudo tuned-adm profile powersave

