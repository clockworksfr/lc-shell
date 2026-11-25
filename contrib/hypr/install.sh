#!/bin/sh
# Installs lc-shell's Hyprland bindings (shell.lua) and helper scripts into
# ~/.config/hypr, keeping a backup of any file it replaces (*.orig, made
# once), then reloads Hyprland.
#   sh contrib/hypr/install.sh
# Your hyprland.lua must load the bindings with `require("shell")`.
set -e
here="$(cd "$(dirname "$0")" && pwd)"
hypr="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
mkdir -p "$hypr"
for f in shell.lua lock-and-dpms.sh lc-shell-loop.sh; do
    [ -e "$hypr/$f" ] && [ ! -e "$hypr/$f.orig" ] && cp "$hypr/$f" "$hypr/$f.orig"
    cp "$here/$f" "$hypr/$f"
done
chmod +x "$hypr/lock-and-dpms.sh" "$hypr/lc-shell-loop.sh"
hyprctl reload >/dev/null && echo "lc-shell bindings installed in $hypr (previous files kept as *.orig)."
