#!/bin/sh
# Verrouille la session, puis éteint TOUS les écrans après un court délai.
#
# Pourquoi un script et pas deux `exec` dans le bind : il faut attendre que
# l'écran de verrouillage soit réellement affiché (sinon on éteint avant de
# masquer le bureau, et le bureau reste visible une fraction de seconde au
# rallumage), et vérifier qu'on est encore verrouillé — si tu déverrouilles
# dans l'intervalle, on ne t'éteint pas l'écran au nez.
#
# Verrouillage par lc-shell (`qs -c lc ipc call lock …`). Si lc-shell ne
# répond pas (arrêté, en panne), hyprlock prend le relais : on n'est jamais
# laissé sans verrou.
#
# Le retour d'écran est assuré par misc:{mouse_move,key_press}_enables_dpms
# dans hyprland.lua : sans eux, une fois `dpms off` posé à la main, aucune
# frappe ne rallume.
#
# Usage : lock-and-dpms.sh [délai en secondes, défaut 5]

DELAY=${1:-5}

if qs -c lc ipc call lock lock 2>/dev/null; then
    sleep "$DELAY"
    [ "$(qs -c lc ipc call lock isLocked 2>/dev/null)" = "true" ] || exit 0
else
    # lc-shell absent : hyprlock (bloquant, donc lancé à part).
    hyprlock &
    sleep "$DELAY"
    pgrep -x hyprlock >/dev/null || exit 0
fi

# Config Lua (Hyprland 0.57+) : `hyprctl dispatch` attend une expression hl.dsp.
if hyprctl status -j 2>/dev/null | grep -q '"configProvider": *"lua"'; then
    exec hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'
fi
exec hyprctl dispatch dpms off
