#!/bin/bash
# NyxNiri EyeCare Toggle — via DMS night mode IPC
set -uo pipefail

# Serialization lock
exec 9> "${XDG_RUNTIME_DIR:-/tmp}/nyxniri-eyecare.lock"
flock -w 5 9 || exit 1

NIRI_DIR="$HOME/.config/niri"
EFFECTS_LINK="$NIRI_DIR/effects.kdl"
NORMAL_EFFECTS="$NIRI_DIR/effects_normal.kdl"
EYECARE_EFFECTS="$NIRI_DIR/effects_eyecare.kdl"

# Check current state via effects.kdl symlink
CURRENTLY_ON=false
if [ "$(readlink "$EFFECTS_LINK" 2>/dev/null)" = "$EYECARE_EFFECTS" ]; then
    CURRENTLY_ON=true
fi

# Toggle effects.kdl symlink
apply_effects() {
    local target
    if [ "$1" = "on" ]; then
        target="$EYECARE_EFFECTS"
    else
        target="$NORMAL_EFFECTS"
    fi
    ln -sfn "$target" "$EFFECTS_LINK"
    if command -v niri >/dev/null 2>&1; then
        niri msg action load-config-file 2>/dev/null || true
    fi
}

# --sync: reconcile state on niri restart
if [ "${1:-}" = "--sync" ]; then
    link_target="$(readlink "$EFFECTS_LINK" 2>/dev/null || true)"
    if [ "$link_target" != "$EYECARE_EFFECTS" ] && [ "$link_target" != "$NORMAL_EFFECTS" ]; then
        ln -sfn "$NORMAL_EFFECTS" "$EFFECTS_LINK"
        CURRENTLY_ON=false
    fi
    # Sync DMS night mode with effects.kdl state
    if [ "$CURRENTLY_ON" = "true" ]; then
        dms ipc call night enable 2>/dev/null || true
    else
        dms ipc call night disable 2>/dev/null || true
    fi
    exit 0
fi

IS_TURNING_ON=false

if [ "$CURRENTLY_ON" = "true" ]; then
    # Turning OFF: switch to normal effects + disable DMS night mode
    apply_effects off
    dms ipc call night disable 2>/dev/null || true
else
    # Turning ON: switch to eyecare effects + enable DMS night mode at 5500K
    apply_effects on
    dms ipc call night temperature 5000 2>/dev/null || true
    dms ipc call night enable 2>/dev/null || true
    IS_TURNING_ON=true
fi

# Notification
if [ "$IS_TURNING_ON" = "true" ]; then
    notify-send -t 2000 "Eye Care : On"
else
    notify-send -t 2000 "Eye Care : Off"
fi
