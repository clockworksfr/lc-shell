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
| `modules/` | Fenêtres par écran (`bar/`, `osd/`, `launcher/`), activées selon l'agencement |
| `launcher/` | Lanceur : état, recherche, fournisseurs (applis, emoji, fichiers, calcul, actions) |
| `panels/` | Contenus de popups (`AudioPanel`) |
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
- Blocs disponibles : `workspaces`, `clock` (`format`), `media` (`maxWidth`), `volume` (clic : panneau audio avec choix des périphériques, clic milieu : muet, molette : volume).
- Modules : `bar` (`position`: top/bottom, `left`/`center`/`right`), `osd` (`position`: bottom/top, `margin`).
- Pour ajouter un bloc : créer `blocks/Xxx.qml` (propriétés `screen` et `options`) et l'inscrire dans `blocks/Registry.qml`.

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
| `qs -c lc ipc call shell reload` | Rechargement complet (nécessaire après modification d'un `.js`) |
