# lc-shell

Shell Wayland perso, écrit de zéro sur [Quickshell](https://quickshell.org) (sans plugin C++).

```sh
qs -c lc            # ~/.config/quickshell/lc -> ce repo
qs -c lc ipc show   # liste des commandes IPC
```

Architecture cible et décisions : [`docs/architecture.md`](docs/architecture.md).

## Structure

| Dossier | Rôle |
|---|---|
| `shell.qml` | Point d'entrée : une `ScreenScope` par écran (`Variants` sur `Quickshell.screens`) |
| `modules/` | Fenêtres par écran (`bar/`, `osd/`, `launcher/`), selon le profil de l'écran |
| `blocks/` | Blocs de barre + `Registry` nom → fichier |
| `i18n/` | Langue de l'interface : `I18n` + `en.json`, `fr.json` |
| `launcher/` | Lanceur : état, recherche, fournisseurs (applis, emoji, fichiers, calcul, actions) |
| `panels/` | Contenus de popups : audio, réseau, Bluetooth, énergie |
| `services/` | Singletons : `Config`, `Screens`, `Audio`, `Players`, `Brightness`, `Osd`, `NetworkService`, `BluetoothService`, `Power`, `SystemStats`, IPC… |
| `assets/fonts/` | Polices statiques embarquées (OFL) : Figtree, JetBrains Mono |
| `theme/` | `Themes` (registre, clair/sombre, programmation), `defs/` (un fichier par thème) |
| `components/` | Composants de base, qui lisent le thème de leur fenêtre |
| `config/defaults.json` | Valeurs par défaut (génériques), rechargées à chaud |

## Configuration

Deux couches, rechargées à chaud :

- `config/defaults.json` (repo) : valeurs par défaut génériques ;
- `~/.config/lc/settings.json` (`$XDG_CONFIG_HOME`) : **tes réglages**, superposés aux défauts. Écrit aussi par le shell (IPC, app de paramètres). Les objets se fusionnent clé par clé ; les listes (blocs, écrans, pages) remplacent.

Exemple de réglages :

```json
{
  "appearance": {
    "variant": "auto",
    "schedule": { "type": "time", "light": "07:30", "dark": "19:30" },
    "themes": { "normal": "classic", "modules": "matrix" }
  },
  "modes": {
    "normal": { "bar": { "left": ["workspaces"], "center": ["clock"], "right": ["media", "volume"] }, "osd": {} },
    "modules": { "osd": {} }
  },
  "screens": [
    { "match": { "model": "XENEON EDGE" }, "mode": "modules", "touch": true },
    { "match": { "name": "eDP-*" }, "mode": "normal" }
  ]
}
```

- **Écrans** : reconnus par `model` (stable, contrairement au connecteur avec l'eGPU) ou par `name` (motif, `eDP-*`). Le premier profil qui correspond gagne ; un écran inconnu est `normal`.
- **Modes** : `normal` (barre permanente) ou `modules` (tableau de bord, voir plus bas). La config d'un module (`bar`, `osd`) vient du mode, surchargée clé par clé par le profil ; `null` le désactive.
- **Thèmes** : un par mode (`appearance.themes`), surchargeable par profil (`"theme": "matrix"`). Disponibles : `classic` (défaut, jetons de la spec), `matrix` (palettes ; polices pas encore embarquées).
- **Clair/sombre** : `variant` = `dark`, `light` ou `auto` ; en `auto`, `schedule` = horaires fixes (`type: "time"`) ou soleil (`type: "sun"`, `latitude`, `longitude`, calcul local).
- **Barre** : sur n'importe quel bord, `position` = `top`/`bottom`/`left`/`right`. Blocs dans `left`/`center`/`right` (sur une barre verticale : du haut vers le bas ; `start`/`center`/`end` accepté). Rendu fourni par le thème, surchargeable : `style` (`full`/`islands`), `floating`, `margin`, `radius`, `opacity`, `border`, `padding`, `spacing`, `height` (épaisseur horizontale), `verticalWidth` (épaisseur verticale), `screenCorners` (rayon des coins d'écran, 0 = aucun).
- **Cadre** : `"frame": true` (ou `{ "enabled": true, "thickness": 8 | { "top": …, "left": … }, "innerRadius": 18, "outline": 1 }`) dans la config de la barre. Un anneau entoure le bureau, la barre en est le côté épais (collée, sans îlots) ; les autres côtés réservent leur épaisseur. Dessiné sous les fenêtres, invisible aux clics, retiré en plein écran. Actif par défaut dans Matrix. Les coins d'écran (noirs, façon bord d'écran) suivent : `screenCorners`, ou automatique avec le cadre.
- **Barre verticale** : blocs empilés et compacts (libellé puis valeur, jamais de texte pivoté), horloge sur deux lignes (`verticalFormat`), espaces de travail et tray en colonne. Les panneaux s'ouvrent vers l'intérieur de l'écran ; notifications et OSD s'écartent de la barre.
- Blocs :
  - `workspaces`, `clock` (`format`), `media` (`maxWidth`) ;
  - `volume` — clic : panneau audio (volumes, périphériques), clic milieu : muet, molette : volume ;
  - `tray` — clic : activer, clic droit : menu, clic milieu : action secondaire (`showPassive`) ;
  - `network` — clic : panneau (filaire, interrupteur Wi-Fi, réseaux, mot de passe à la volée) ;
  - `bluetooth` — clic : panneau (interrupteur, appareils ; un nouvel appareil est appairé, approuvé et connecté) ; masqué sans adaptateur ;
  - `battery` — clic : panneau (autonomie, profil d'énergie) ; masqué sans batterie ;
  - `notifications` — non lues ; clic : historique (ne pas déranger, tout effacer), clic milieu : ne pas déranger. Un nom inconnu s'affiche `?nom` en rouge. Ajouter un bloc : `blocks/Xxx.qml` (propriétés `screen`, `options`) + `blocks/Registry.qml`.
- **Plein écran** : rien d'automatique (OSD, bientôt notifications) ne s'affiche au-dessus ; c'est redirigé vers un écran `modules` ou retenu. Le lanceur, appelé explicitement, reste autorisé.

## Paramètres

`qs -c lc ipc call settings toggle` (ou `openPage <page>`), ou « Paramètres » dans le lanceur. Fenêtre normale, réglages appliqués en direct et écrits dans `settings.json` :

- **Apparence** : thème des écrans normaux / modules, clair / sombre / automatique, bascule à heures fixes ou au soleil (latitude, longitude) ;
- **Écrans** : par écran branché — mode, thème, tactile, position de la barre, cadre (profil créé au besoin, repéré par le modèle) ;
- **Barre** : rendu (style, flottante, opacité, position, cadre) et blocs par zone (monter, descendre, changer de zone, retirer, ajouter) ;
- **Fond d'écran** : activation, dossier, grille de choix, au hasard ;
- **Général** : langue, ne pas déranger, rangement des fenêtres du tableau de bord.

## Verrouillage et inactivité

- **Verrouillage** (`ext-session-lock`) : une surface par écran (fond flouté, heure, champ mot de passe), authentification PAM (service `lock.pamService`, `hyprlock` par défaut). Déclenché par `loginctl lock-session` (logind, écouté via `gdbus monitor`), l'inactivité, l'IPC `lock lock`, ou avant la mise en veille (verrou « delay » de `systemd-inhibit` relâché une fois l'écran verrouillé affiché).
- **Aperçu** : `qs -c lc ipc call lock preview` ou « Aperçu du verrouillage » dans le lanceur — même écran dans une fenêtre, vrai contrôle PAM, rien n'est verrouillé. Attention : les échecs comptent pour `pam_faillock` (3 = compte bloqué 10 min).
- **Inactivité** (`idle`, secondes, 0 = jamais) : `lock` 600, `screenOff` 900, `lockedScreenOff` 30, `suspend` 0. Les inhibiteurs sont respectés (`idle_inhibit fullscreen` de Hyprland, applis).
- **Sécurité** : si le shell plante verrouillé, Hyprland garde la session verrouillée (écran rouge). Ajouter dans `hyprland.lua`, section `misc` : `allow_session_lock_restore = true,` ; un shell relancé (ou `hyprlock`, gardé en secours) peut alors reprendre la main. Depuis un TTY : `hyprlock` (avec `WAYLAND_DISPLAY` / `HYPRLAND_INSTANCE_SIGNATURE` de la session).
- **Tant que Caelestia tourne**, il gère aussi inactivité et verrouillage : couper l'un des deux (`"idle": { "enabled": false }`).

## Langues

Interface en anglais et en français. `"language"` dans `settings.json` : `auto` (suit la locale du système), `en` ou `fr` ; `"locale"` pour forcer le format des dates et nombres (ex. `en_GB`). Bascule à chaud : `qs -c lc ipc call i18n set en|fr|auto`.

- Textes : `i18n/<langue>.json`, clés plates (`"osd.volume": "Volume"`) avec `{paramètres}`, rechargés à chaud. Clé manquante : repli sur l'anglais, puis sur la clé elle-même.
- Dans le code : `I18n.tr("clé", { n: 2 })`, `I18n.percent(0.42)`, `I18n.number(x, 1)`, `I18n.locale` pour les dates. Aucun texte visible en dur.
- Recherche du lanceur (actions, emoji) dans toutes les langues à la fois : « veille » et « sleep » trouvent la même action.
- Ajouter une langue : copier `en.json`, traduire, ajouter le code dans `I18n.languages` (et les annotations CLDR dans `tools/gen-emoji.py`).

## Mode modules (tableau de bord)

`modes.modules.dashboard` (surchargeable par écran) :

```json
"dashboard": {
  "grid": { "columns": 12, "rows": 4, "gap": 12, "margin": 12 },
  "windows": { "enabled": true, "ignore": ["steam"], "only": [] },
  "pages": {
    "default": [
      { "type": "clock",  "x": 0, "y": 0, "w": 3, "h": 2 },
      { "type": "window", "x": 3, "y": 0, "w": 6, "h": 4 }
    ],
    "8": [ ... ]
  }
}
```

- Chaque espace de travail Hyprland de l'écran est une **page** : `pages["<nom de l'espace de travail>"]`, sinon `pages.default`.
- Tuiles : `clock` (`format`), `media`, `system` (CPU, RAM, GPU, températures), `workspaces`, `window`, `lyrics` (paroles synchronisées via lrclib.net — seuls artiste, titre et durée sont envoyés ; cache local), `vu` (VU-mètre de la sortie par défaut, échelle en dB, crête retenue ; barres dans le sens long de la tuile).
- **Cases fenêtre** (`"type": "window"`) : toute fenêtre arrivant sur un espace de travail de cet écran est rendue flottante et placée dans la première case libre (les suivantes s'empilent dans la dernière). Repartie vers un écran normal, elle redevient tuilée. Les fenêtres plein écran ne sont pas touchées. `windows.ignore` / `only` filtrent par classe.
- Le tableau de bord est sur la couche `bottom`, sous les fenêtres.

## Lanceur

`qs -c lc ipc call launcher toggle`, ou `openWith ":"` pour ouvrir directement un mode.

| Préfixe | Mode | Entrée | Maj+Entrée / clic droit |
|---|---|---|---|
| (aucun) | Applis, actions, calcul si l'entrée ressemble à une opération | lancer | |
| `:` | Emoji (noms français, CLDR) | taper + copier | copier seulement |
| `/` | Fichiers de `~` (`fd`, sans cachés ni ignorés) | ouvrir | ouvrir le dossier |
| `=` | Calcul `qalc` (unités, devises…) | copier le résultat | |
| `>` | Actions : verrouiller, veille, quitter, redémarrer, éteindre, recharger, sortie/entrée audio | exécuter | |
| `@` | Fonds d'écran (miniatures) | tous les écrans | cet écran seulement |

Tab change de mode. Les actions destructrices demandent une seconde validation. Verrouillage et veille passent par logind (`loginctl lock-session`, `systemctl suspend`) : ils marchent avec l'écran de verrouillage qui écoute logind, quel qu'il soit. L'historique d'usage (classement) est dans `~/.local/state/quickshell/…/launcher-usage.json`.

Les choix faits par IPC (thème, variante, langue) sont écrits dans `settings.json`.

## Fond d'écran

`"wallpaper": { "enabled": true, "directory": "~/Images/Wallpapers" }`. Une image par écran (repéré par son modèle) ou une pour tous, gardée dans `…/wallpaper.json` ; sans image, la couleur de fond du thème. Changement en fondu enchaîné, image décodée à la taille de l'écran. Choix dans le lanceur (`@`) ou par IPC. Tant que Caelestia dessine aussi son fond, `"enabled": false` évite la superposition.

## Notifications

Serveur `org.freedesktop.Notifications` intégré. Un seul processus peut le détenir : tant que Caelestia tourne, celui de lc-shell attend (avertissement dans le journal) et prend le relais dès que le nom se libère.

- Popups en haut à droite de l'écran actif, sous la barre ; 6 s par défaut (ou le délai demandé par l'appli), en pause au survol ; les critiques restent jusqu'à fermeture.
- Jamais au-dessus d'un plein écran : redirigées vers un écran `modules`, sinon mises en attente jusqu'à ce qu'un écran se libère.
- Ne pas déranger : plus de popups (sauf critiques), tout reste dans l'historique.
- Corps affiché en texte brut (balisage retiré : aucune image distante chargée). Actions de l'appli en boutons, clic sur la carte = action par défaut.
- Historique (100 max) conservé entre les redémarrages dans `…/notifications.json`.

## OSD et touches multimédia

L'OSD réagit aux **changements** (PipeWire, sysfs du rétroéclairage) et non aux touches : les binds peuvent rester sur `wpctl`/`brightnessctl` et continuent de marcher shell arrêté. Les écrans externes (DDC/CI) ne passent que par l'IPC `brightness`.

## IPC

| Commande | Effet |
|---|---|
| `qs -c lc ipc call bar toggle` / `open` / `close` | Afficher ou masquer les barres |
| `qs -c lc ipc call launcher toggle` / `openWith <texte>` / `close` | Lanceur |
| `qs -c lc ipc call audio increment` / `decrement` / `toggleMute` / `toggleMicMute` | Volume de la sortie par défaut |
| `qs -c lc ipc call media togglePlaying` / `next` / `previous` / `cycle` / `info` | Lecteur actif (`cycle` change de lecteur, `info` le décrit) |
| `qs -c lc ipc call lyrics status` / `current` | Paroles (état, ligne en cours) |
| `qs -c lc ipc call brightness increment` / `decrement` | Luminosité de l'écran focalisé (rétroéclairage ou DDC/CI) |
| `qs -c lc ipc call theme set <id>` / `setModules <id>` / `list` | Thème des écrans normaux / modules |
| `qs -c lc ipc call theme variant dark\|light\|auto` / `toggleVariant` | Clair / sombre |
| `qs -c lc ipc call i18n set en\|fr\|auto` / `get` | Langue de l'interface |
| `qs -c lc ipc call notifs toggleDnd` / `clear` / `markRead` | Notifications |
| `qs -c lc ipc call wallpaper set <chemin>` / `setHere <chemin>` / `random` / `get` | Fond d'écran (tous / écran actif) |
| `qs -c lc ipc call settings toggle` / `openPage <page>` / `close` | Paramètres |
| `qs -c lc ipc call lock lock` / `preview` / `isLocked` | Verrouillage |
| `qs -c lc ipc call shell reload` | Rechargement complet (nécessaire après modification d'un `.js`) |
