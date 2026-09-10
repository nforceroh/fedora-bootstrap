#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

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

G502_NAME=""
for _ in $(seq 1 {{ g502_discovery_attempts }}); do
    G502_NAME=$(ratbagctl list | awk -F: '/G502/ {gsub(/[[:space:]]+$/, "", $1); print $1; exit}')
    if [ -n "$G502_NAME" ] && ratbagctl "$G502_NAME" profile active set "$PROFILE" 2>/dev/null; then
        printf '%s\n' "$PROFILE" > "$PROFILE_CACHE"
        chmod 600 "$PROFILE_CACHE"
        if [ "$(id -u)" -eq 0 ]; then
            chown "{{ target_user }}" "$PROFILE_CACHE"
        fi
        echo "[$(date)] Successfully switched $G502_NAME to Profile $PROFILE." >> /tmp/mouse_success.log
        exit 0
    fi
    sleep {{ g502_discovery_delay }}
done

echo "[$(date)] Error: G502 was not available for profile $PROFILE after {{ g502_discovery_attempts }} attempts." >> /tmp/mouse_err.log
exit 1
