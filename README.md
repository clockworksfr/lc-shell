# lc-shell

Shell Wayland perso, écrit de zéro sur [Quickshell](https://quickshell.org) (sans plugin C++).

```sh
qs -c lc            # ~/.config/quickshell/lc -> ce repo
qs -c lc ipc show   # liste des commandes IPC
```

## Structure

| Dossier | Rôle |
|---|---|
| `shell.qml` | Point d'entrée : une `ScreenScope` par écran (`Variants` sur `Quickshell.screens`) |
| `modules/` | Fenêtres par écran (`bar/`, `osd/`), activées selon l'agencement |
| `blocks/` | Blocs placés dans les zones (horloge, espaces de travail…) + `Registry` nom → fichier |
| `services/` | Singletons d'état et de données : `Audio` (PipeWire), `Players` (MPRIS), `Brightness` (backlight + DDC/CI), `Osd`, `Layout`, IPC… |
| `theme/` | `Theme` : tokens neutres (couleurs, espacements, rayons, polices) |
| `components/` | Composants de base qui ne lisent que les tokens du thème |
| `config/layout.json` | Agencement des blocs, rechargé à chaud |

## Agencement (`config/layout.json`)

```json
{
  "default": { "bar": { "position": "top", "left": ["workspaces"], "center": ["clock"], "right": [] } },
  "screens": {
    "DP-1":     { "bar": { "center": [{ "type": "clock", "format": "dddd d MMMM  HH:mm" }] } },
    "HDMI-A-1": { "bar": null }
  }
}
```

- `default` s'applique à tous les écrans ; `screens.<sortie>` surcharge clé par clé (noms via `hyprctl monitors`).
- Un module à `null` est désactivé sur cet écran.
- Un bloc s'écrit `"nom"` ou `{ "type": "nom", ...options }`. Un nom inconnu s'affiche `?nom` en rouge.
- Blocs disponibles : `workspaces`, `clock` (`format`), `media` (`maxWidth`), `volume`.
- Modules : `bar` (`position`: top/bottom, `left`/`center`/`right`), `osd` (`position`: bottom/top, `margin`).
- Pour ajouter un bloc : créer `blocks/Xxx.qml` (propriétés `screen` et `options`) et l'inscrire dans `blocks/Registry.qml`.

## OSD et touches multimédia

L'OSD réagit aux **changements** (PipeWire, sysfs du rétroéclairage) et non aux touches : les binds peuvent rester sur `wpctl`/`brightnessctl` et continuent de marcher shell arrêté. Les écrans externes (DDC/CI) ne passent que par l'IPC `brightness`.

## IPC

| Commande | Effet |
|---|---|
| `qs -c lc ipc call bar toggle` / `open` / `close` | Afficher ou masquer les barres |
| `qs -c lc ipc call audio increment` / `decrement` / `toggleMute` / `toggleMicMute` | Volume de la sortie par défaut |
| `qs -c lc ipc call media togglePlaying` / `next` / `previous` / `cycle` | Lecteur actif (`cycle` change de lecteur) |
| `qs -c lc ipc call brightness increment` / `decrement` | Luminosité de l'écran focalisé (rétroéclairage ou DDC/CI) |
| `qs -c lc ipc call shell reload` | Rechargement complet (nécessaire après modification d'un `.js`) |
