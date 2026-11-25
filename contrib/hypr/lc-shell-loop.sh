#!/bin/sh
# Starts lc-shell and restarts it if it stops (crash, `kill`): the lock
# screen relies on it (allow_session_lock_restore, relocking on restart).
# To really stop it: pkill -f lc-shell-loop, then qs -c lc kill.
while :; do
    qs -c lc
    sleep 2
done
