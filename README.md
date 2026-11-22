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
| `launcher/` | Lanceur : état, recherche, fournisseurs (applis, emoji, fichiers, calcul, actions) |
| `panels/` | Contenus de popups (`AudioPanel`) |
| `services/` | Singletons : `Config`, `Screens`, `Audio`, `Players`, `Brightness`, `Osd`, IPC… |
| `theme/` | `Themes` (registre, clair/sombre, programmation), `defs/` (un fichier par thème) |
| `components/` | Composants de base, qui lisent le thème de leur fenêtre |
| `config/shell.json` | Configuration, rechargée à chaud |

## Configuration (`config/shell.json`)

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
- **Modes** : `normal` (barre permanente) ou `modules` (tableau de bord, en cours). La config d'un module (`bar`, `osd`) vient du mode, surchargée clé par clé par le profil ; `null` le désactive.
- **Thèmes** : un par mode (`appearance.themes`), surchargeable par profil (`"theme": "matrix"`). Disponibles : `classic` (provisoire), `matrix`.
- **Clair/sombre** : `variant` = `dark`, `light` ou `auto` ; en `auto`, `schedule` = horaires fixes (`type: "time"`) ou soleil (`type: "sun"`, `latitude`, `longitude`, calcul local).
- **Barre** : blocs dans `left`/`center`/`right`. Rendu fourni par le thème, surchargeable : `style` (`full`/`islands`), `floating`, `margin`, `radius`, `opacity`, `border`, `padding`, `spacing`, `height`, `position` (`top`/`bottom`), `screenCorners` (rayon des coins d'écran, 0 = aucun).
- Blocs : `workspaces`, `clock` (`format`), `media` (`maxWidth`), `volume` (clic : panneau audio, clic milieu : muet, molette : volume). Un nom inconnu s'affiche `?nom` en rouge. Ajouter un bloc : `blocks/Xxx.qml` (propriétés `screen`, `options`) + `blocks/Registry.qml`.
- **Plein écran** : rien d'automatique (OSD, bientôt notifications) ne s'affiche au-dessus ; c'est redirigé vers un écran `modules` ou retenu. Le lanceur, appelé explicitement, reste autorisé.

## Lanceur

`qs -c lc ipc call launcher toggle`, ou `openWith ":"` pour ouvrir directement un mode.

| Préfixe | Mode | Entrée | Maj+Entrée / clic droit |
|---|---|---|---|
| (aucun) | Applis, actions, calcul si l'entrée ressemble à une opération | lancer | |
| `:` | Emoji (noms français, CLDR) | taper + copier | copier seulement |
| `/` | Fichiers de `~` (`fd`, sans cachés ni ignorés) | ouvrir | ouvrir le dossier |
| `=` | Calcul `qalc` (unités, devises…) | copier le résultat | |
| `>` | Actions : verrouiller, veille, quitter, redémarrer, éteindre, recharger, sortie/entrée audio | exécuter | |

Tab change de mode. Les actions destructrices demandent une seconde validation. Verrouillage et veille passent par logind (`loginctl lock-session`, `systemctl suspend`) : ils marchent avec l'écran de verrouillage qui écoute logind, quel qu'il soit. L'historique d'usage (classement) est dans `~/.local/state/quickshell/…/launcher-usage.json`.

Les choix faits à l'exécution (thème, variante via IPC) sont gardés dans `…/appearance.json` et priment sur `shell.json`.

## OSD et touches multimédia

L'OSD réagit aux **changements** (PipeWire, sysfs du rétroéclairage) et non aux touches : les binds peuvent rester sur `wpctl`/`brightnessctl` et continuent de marcher shell arrêté. Les écrans externes (DDC/CI) ne passent que par l'IPC `brightness`.

## IPC

| Commande | Effet |
|---|---|
| `qs -c lc ipc call bar toggle` / `open` / `close` | Afficher ou masquer les barres |
| `qs -c lc ipc call launcher toggle` / `openWith <texte>` / `close` | Lanceur |
| `qs -c lc ipc call audio increment` / `decrement` / `toggleMute` / `toggleMicMute` | Volume de la sortie par défaut |
| `qs -c lc ipc call media togglePlaying` / `next` / `previous` / `cycle` | Lecteur actif (`cycle` change de lecteur) |
| `qs -c lc ipc call brightness increment` / `decrement` | Luminosité de l'écran focalisé (rétroéclairage ou DDC/CI) |
| `qs -c lc ipc call theme set <id>` / `setModules <id>` / `list` | Thème des écrans normaux / modules |
| `qs -c lc ipc call theme variant dark\|light\|auto` / `toggleVariant` | Clair / sombre |
| `qs -c lc ipc call shell reload` | Rechargement complet (nécessaire après modification d'un `.js`) |
