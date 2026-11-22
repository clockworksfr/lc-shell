-- ~~~ Shell de bureau — lc-shell ~~~
-- Remplace la version Caelestia (gardée dans shell-caelestia.lua).
--
-- POINT D'ABSTRACTION : tout ce qui dépend du shell (barre, lanceur, OSD,
-- notifications, capture d'écran, verrouillage) vit ICI et nulle part
-- ailleurs. hyprland.lua ne connaît que `require("shell")`.
--
-- Raccourcis : `global` (raccourcis globaux Hyprland, appid « lc ») —
-- instantané, pas de process lancé. `hyprctl globalshortcuts` les liste ;
-- Paramètres › Raccourcis de lc-shell aussi.

-- Fichier chargé à part : les `local` de hyprland.lua n'y sont pas visibles.
local mod = "SUPER"

-- hl.bind avec une description, lue par la cheatsheet (keybinds.sh).
local function bind(keys, dispatcher, desc, opts)
    local o = { desc = desc }
    for k, v in pairs(opts or {}) do o[k] = v end
    hl.bind(keys, dispatcher, o)
end

local exec = hl.dsp.exec_cmd
local lc = function(name) return hl.dsp.global("lc:" .. name) end

--- Démarrage
-- Lancé explicitement parce qu'on est en session Hyprland "nue"
-- (graphical-session.target inactif, cf. hyprland.lua).
hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c lc -d")

    -- Presse-papier : plus de cliphist, lc-shell enregistre lui-même
    -- l'historique (wl-paste --watch lancé par le shell).

    -- Panneau Philips Hue : configuration QuickShell INDÉPENDANTE
    -- (~/.config/quickshell/hue).
    -- ⚠️ `qs` est le binaire de QuickShell, et lc-shell tourne dessus aussi :
    -- un `pkill qs` tue les deux. Pour ne viser que ce panneau : `qs -c hue kill`.
    hl.exec_cmd("qs -c hue")
end)

--- Raccourcis

bind(mod .. " + Space", lc("launcher"), "Lanceur d'applications")
bind(mod .. " + A",     lc("launcher"), "Lanceur d'applications")

-- Super+U : « U » et « Hue » se prononcent pareil.
bind(mod .. " + U",         exec("qs -c hue ipc call panel toggle"), "Panneau Philips Hue")
bind(mod .. " + SHIFT + U", exec("~/.local/bin/huectl group 1 toggle"), "Hue : Salon on/off")

-- Caelestia avait une sidebar et un dashboard ; lc-shell ouvre à la place le
-- panneau des notifications et la carte média (lecteur, paroles).
bind(mod .. " + S",     lc("notifications"), "Panneau des notifications")
bind(mod .. " + comma", lc("media"),         "Carte média (lecteur, paroles)")

-- Gestionnaire du presse-papier de lc-shell (historique, épinglés, collage
-- direct) ; pause « incognito » de l'enregistrement. Emoji : dans le lanceur.
bind(mod .. " + SHIFT + V",        lc("clipboard"),          "Historique du presse-papier")
bind(mod .. " + CTRL + SHIFT + V", lc("clipboardIncognito"), "Presse-papier : pause / reprise")
bind(mod .. " + period",           lc("emoji"),              "Sélecteur d'emoji")

-- Capture d'écran : copiée dans le presse-papier, gardée en cache, puis
-- notification « Ouvrir » (swappy) / « Enregistrer » (~/Images/Screenshots).
-- La zone se choisit sur les écrans figés.
bind("Print",         lc("screenshot"),       "Capture d'une zone")
bind("SHIFT + Print", lc("screenshotScreen"), "Capture de l'écran ayant le focus")

-- Verrouille, puis éteint tous les écrans 5 s plus tard (le script vérifie
-- qu'on est toujours verrouillé ; hyprlock si lc-shell ne répond pas).
-- Chemin absolu : les binds Hyprland n'ont pas ~/.local/bin dans leur PATH.
bind(mod .. " + Escape", exec("/home/simon/.config/hypr/lock-and-dpms.sh"), "Verrouiller + éteindre les écrans")

bind(mod .. " + SHIFT + N", lc("clearNotifs"), "Effacer les notifications")
bind(mod .. " + CTRL + N",  lc("dnd"),         "Ne pas déranger")

bind(mod .. " + slash", exec("bash ~/.config/hypr/keybinds.sh"), "Cheatsheet des raccourcis")

-- Thème de lc-shell : clair / sombre, et thème suivant (Classique,
-- Constellation, Façade, Modulaire, Matrix). Le reste du système n'est pas
-- touché.
bind(mod .. " + SHIFT + T", lc("toggleVariant"), "Thème clair / sombre")
bind(mod .. " + CTRL + T",  lc("nextTheme"),     "Thème suivant")

--- Touches multimédia
-- Pilotées par wpctl/brightnessctl plutôt que par le shell : lc-shell affiche
-- son OSD en écoutant PipeWire/backlight, donc l'OSD marche quand même, et les
-- touches continuent de fonctionner si le shell est arrêté.
bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume +", { locked = true, repeating = true })
bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        "Volume -", { locked = true, repeating = true })
bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       "Muet",     { locked = true })
bind("XF86MonBrightnessUp",   exec("brightnessctl set 5%+"), "Luminosité +", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), "Luminosité -", { locked = true, repeating = true })

bind("XF86AudioPlay",  exec("playerctl play-pause"), "Lecture / pause", { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), "Lecture / pause", { locked = true })
bind("XF86AudioNext",  exec("playerctl next"),       "Piste suivante",  { locked = true })
bind("XF86AudioPrev",  exec("playerctl previous"),   "Piste précédente", { locked = true })
bind("XF86AudioStop",  exec("playerctl stop"),       "Stop",            { locked = true })
