#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

sleep 1.5
PROFILE_CACHE="{{ profile_cache_path }}"

if [ -n "${1:-}" ]; then
    PROFILE="$1"
elif [ -s "$PROFILE_CACHE" ]; then
    PROFILE=$(cat "$PROFILE_CACHE")
else
    PROFILE="{{ mouse_profile }}"
fi

case "$PROFILE" in
    0|1) ;;
    *)
        echo "[$(date)] Error: Invalid mouse profile: $PROFILE" >> /tmp/mouse_err.log
        exit 1
        ;;
esac

G502_NAME=$(ratbagctl list | grep "G502" | cut -f1 -d: | xargs)

if [ -z "$G502_NAME" ]; then
    echo "[$(date)] Error: Logitech G502 mouse not detected over wireless link!" >> /tmp/mouse_err.log
    exit 1
fi

if ratbagctl "$G502_NAME" profile active set "$PROFILE" 2>/dev/null; then
    printf '%s\n' "$PROFILE" > "$PROFILE_CACHE"
    chmod 600 "$PROFILE_CACHE"
    if [ "$(id -u)" -eq 0 ]; then
        chown "{{ target_user }}" "$PROFILE_CACHE"
    fi
    echo "[$(date)] Successfully switched $G502_NAME to Profile $PROFILE." >> /tmp/mouse_success.log
else
    echo "[$(date)] Error: Failed to execute active profile set for $PROFILE." >> /tmp/mouse_err.log
    exit 1
fi
