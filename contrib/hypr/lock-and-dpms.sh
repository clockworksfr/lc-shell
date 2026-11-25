#!/bin/sh
# Locks the session, then turns ALL screens off after a short delay.
#
# The delay lets the lock screen actually show up (otherwise the screens go
# off before it is drawn and flash back on), and the script checks that the
# session is still locked: unlock in the meantime and the screens stay on.
#
# lc-shell locks through its IPC; if it doesn't answer (stopped, crashed),
# hyprlock takes over, so the session is never left unlocked.
#
# Screens come back on input thanks to misc:{mouse_move,key_press}_enables_dpms
# in your Hyprland config: without them, once `dpms off` is set by hand, no
# input wakes the screens.
#
# Usage: lock-and-dpms.sh [delay in seconds, default 5]

DELAY=${1:-5}

if qs -c lc ipc call lock lock 2>/dev/null; then
    sleep "$DELAY"
    [ "$(qs -c lc ipc call lock isLocked 2>/dev/null)" = "true" ] || exit 0
else
    # No lc-shell: hyprlock (blocking, so started in the background).
    hyprlock &
    sleep "$DELAY"
    pgrep -x hyprlock >/dev/null || exit 0
fi

# Lua config (Hyprland 0.57+): `hyprctl dispatch` takes an hl.dsp expression.
if hyprctl status -j 2>/dev/null | grep -q '"configProvider": *"lua"'; then
    exec hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'
fi
exec hyprctl dispatch dpms off
