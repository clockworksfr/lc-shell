#!/bin/sh
# Installe les raccourcis lc-shell dans la config Hyprland (en gardant la
# version Caelestia à côté), puis recharge Hyprland.
#   sh contrib/hypr/install.sh
set -e
here="$(cd "$(dirname "$0")" && pwd)"
hypr="$HOME/.config/hypr"
[ -e "$hypr/shell-caelestia.lua" ] || cp "$hypr/shell.lua" "$hypr/shell-caelestia.lua"
[ -e "$hypr/lock-and-dpms-caelestia.sh" ] || cp "$hypr/lock-and-dpms.sh" "$hypr/lock-and-dpms-caelestia.sh"
cp "$here/shell.lua" "$hypr/shell.lua"
cp "$here/lock-and-dpms.sh" "$hypr/lock-and-dpms.sh"
chmod +x "$hypr/lock-and-dpms.sh"
hyprctl reload >/dev/null && echo "Raccourcis lc-shell installés (Caelestia : shell-caelestia.lua, lock-and-dpms-caelestia.sh)."
