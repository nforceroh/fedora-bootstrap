#!/bin/bash

set -u

OUTPUT_DIR="${1:-$HOME/kvm-diagnostic-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTPUT_DIR"

if ! sudo -v; then
    echo "Unable to obtain sudo access."
    exit 1
fi

exec > >(tee "$OUTPUT_DIR/diagnostic.log") 2>&1

echo "Diagnostic output: $OUTPUT_DIR"
echo "Started: $(date --iso-8601=seconds)"

capture_state() {
    local label="$1"
    local file="$OUTPUT_DIR/$label.txt"

    {
        echo "=== date ==="
        date --iso-8601=seconds
        echo
        echo "=== ratbagctl list ==="
        ratbagctl list || true
        echo
        echo "=== lsusb ==="
        lsusb || true
        echo
        echo "=== installed udev rule ==="
        sudo cat /etc/udev/rules.d/99-g502-kvm.rules 2>&1 || true
        echo
        echo "=== installed profile script ==="
        grep -n -A12 'G502_NAME=' "$HOME/.local/bin/reset-mouse-profile.sh" 2>&1 || true
        echo
        echo "=== profile logs ==="
        tail -n 20 /tmp/mouse_success.log 2>&1 || true
        tail -n 20 /tmp/mouse_err.log 2>&1 || true
        echo
        echo "=== recent relevant journal ==="
        sudo journalctl -b --since "$START_TIME" --no-pager 2>&1 |
            grep -Ei 'ratbag|hidpp|046d|407f|g502|usb|udev-worker' || true
    } > "$file"

    echo "Captured $label: $file"
}

START_TIME="$(date --iso-8601=seconds)"
capture_state before

UDEV_LOG="$OUTPUT_DIR/udev-monitor.log"
sudo udevadm monitor --kernel --udev --property > "$UDEV_LOG" 2>&1 &
UDEV_PID=$!

echo
echo "Switch the KVM to the other computer within the next five seconds."
sleep 5
echo "Switch the KVM back to this computer now."
sleep 15

sudo kill "$UDEV_PID" 2>/dev/null || true
wait "$UDEV_PID" 2>/dev/null || true

capture_state after

echo
echo "=== filtered udev events ==="
grep -E '^(KERNEL|UDEV|ACTION=|DEVPATH=.*(usb1/1-5|046D|046d)|SUBSYSTEM=|HID_ID=|HID_NAME=|DRIVER=)' "$UDEV_LOG" || true

ARCHIVE="${OUTPUT_DIR%/}.tar.gz"
tar -czf "$ARCHIVE" -C "$(dirname "$OUTPUT_DIR")" "$(basename "$OUTPUT_DIR")"
echo
echo "Complete archive: $ARCHIVE"