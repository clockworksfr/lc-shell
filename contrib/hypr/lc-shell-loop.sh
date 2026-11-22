#!/bin/sh
# Lance lc-shell et le relance s'il s'arrête (plantage, `kill`) : le
# verrouillage en dépend (allow_session_lock_restore, reverrouillage au
# redémarrage). Pour l'arrêter vraiment : pkill -f lc-shell-loop, puis qs -c lc kill.
while :; do
    qs -c lc
    sleep 2
done
