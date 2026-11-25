-- ~~~ Desktop shell: lc-shell ~~~
-- Hyprland (Lua config, 0.57+) bindings for lc-shell. Load it from
-- hyprland.lua with `require("shell")`.
--
-- Everything that depends on the desktop shell (bar, launcher, OSD,
-- notifications, screenshots, lock screen) lives here and nowhere else, so
-- switching shells means swapping this one file.
--
-- Most bindings use `global` (Hyprland global shortcuts, app id "lc"):
-- instant, no process started. `hyprctl globalshortcuts` lists them, and so
-- does lc-shell's Settings > Shortcuts page.

-- Loaded separately: the `local`s of hyprland.lua aren't visible here.
local mod = "SUPER"

-- hl.bind with a description (shown by cheatsheets that read them).
local function bind(keys, dispatcher, desc, opts)
    local o = { desc = desc }
    for k, v in pairs(opts or {}) do o[k] = v end
    hl.bind(keys, dispatcher, o)
end

local exec = hl.dsp.exec_cmd
local lc = function(name) return hl.dsp.global("lc:" .. name) end

--- Startup
hl.on("hyprland.start", function()
    -- lc-shell, restarted if it stops (crash, `kill`): the lock screen
    -- relies on it (allow_session_lock_restore + relocking on restart).
    -- To really stop it: pkill -f lc-shell-loop, then qs -c lc kill.
    hl.exec_cmd("~/.config/hypr/lc-shell-loop.sh")
end)

--- Shell

bind(mod .. " + Space", lc("launcher"), "Application launcher")

-- The Lights drawer (Philips Hue) on the active screen, or a centred panel
-- when the widget isn't in the bar.
bind(mod .. " + U", exec("qs -c lc ipc call bar panel lights"), "Lights (Philips Hue)")

bind(mod .. " + S",     lc("notifications"), "Notifications panel")
bind(mod .. " + comma", lc("media"),         "Media card (player, lyrics)")

-- Clipboard history (pins, tags, direct paste) and its "incognito" pause.
bind(mod .. " + SHIFT + V",        lc("clipboard"),          "Clipboard history")
bind(mod .. " + CTRL + SHIFT + V", lc("clipboardIncognito"), "Clipboard: pause / resume recording")
bind(mod .. " + period",           lc("emoji"),              "Emoji picker")

-- Screenshots: an area or window picked on frozen screens, copied, then a
-- notification offers Annotate / Save / Open.
bind("Print",         lc("screenshot"),       "Screenshot of an area or window")
bind("SHIFT + Print", lc("screenshotScreen"), "Screenshot of the focused screen")
bind("CTRL + Print",  lc("screenshotWindow"), "Screenshot of the active window")

-- Lock, then turn every screen off 5 s later (the script checks the session
-- is still locked; falls back to hyprlock if lc-shell doesn't answer).
-- lc-shell also applies its own lock shortcut (Settings > Lock), replacing
-- this one while it runs: this binding is the fallback.
bind(mod .. " + Escape", exec("~/.config/hypr/lock-and-dpms.sh"), "Lock and turn screens off")

bind(mod .. " + SHIFT + N", lc("clearNotifs"), "Clear notifications")
bind(mod .. " + CTRL + N",  lc("dnd"),         "Do not disturb")

-- lc-shell's theme only: light / dark, and next theme (Classic,
-- Constellation, Façade, Modulaire, Matrix).
bind(mod .. " + SHIFT + T", lc("toggleVariant"), "Light / dark theme")
bind(mod .. " + CTRL + T",  lc("nextTheme"),     "Next theme")

--- Media keys
-- Driven by wpctl / brightnessctl / playerctl rather than the shell:
-- lc-shell shows its OSD by watching PipeWire and the backlight, so the OSD
-- still appears, and the keys keep working while the shell is stopped.
bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up",   { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        "Volume down", { locked = true, repeating = true })
bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       "Mute",        { locked = true })
bind("XF86MonBrightnessUp",   exec("brightnessctl set 5%+"), "Brightness up",   { locked = true, repeating = true })
bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), "Brightness down", { locked = true, repeating = true })

bind("XF86AudioPlay",  exec("playerctl play-pause"), "Play / pause",   { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), "Play / pause",   { locked = true })
bind("XF86AudioNext",  exec("playerctl next"),       "Next track",     { locked = true })
bind("XF86AudioPrev",  exec("playerctl previous"),   "Previous track", { locked = true })
bind("XF86AudioStop",  exec("playerctl stop"),       "Stop",           { locked = true })
