# Besoins et décisions

Ce que simon a demandé et décidé, dans l'ordre où c'est arrivé (22/11/2026). Référence pour vérifier que l'implémentation colle au besoin, pas seulement aux maquettes. Le comment est dans [`architecture.md`](architecture.md), [`themes.md`](themes.md), [`bar-editing.md`](bar-editing.md).

## Contexte

- Arch, Hyprland 0.57 en **config Lua** (`hl.dsp.*`, plus de `hyprctl keyword`).
- Portable Framework + eGPU RX 9070 : écrans branchés/débranchés à chaud ; connecteurs instables → écrans reconnus par **modèle**.
- Écrans : DP-1 Dell U4025QW 5120×2160 (principal) ; HDMI-A-1 Corsair Xeneon Edge 2560×720 (tactile matériellement, pas encore sous Linux) ; écran interne du portable (eDP).
- Joue en plein écran à la manette.
- Shell actuel : fork de Caelestia, qui doit **continuer à tourner** pendant le développement ; bascule par étapes.

## Règles de fond

1. **Quickshell nu**, écrit de zéro. **Aucun code** de Caelestia (GPL-3), de la config d'outfoxxed (sans licence) ni de Nebula (AGPL-3.0) : on s'en inspire seulement. Licence de lc-shell non choisie (rester libre de publier en MIT).
2. **Plus de structure imposée** : agencement des widgets libre, par écran.
3. **Rien au-dessus d'un jeu en plein écran** pour ce qui est automatique (OSD, notifications, coins, cadre) ; ce qui est appelé explicitement (lanceur, panneaux) reste permis.
4. **Multilingue** dès maintenant : anglais et français pour commencer.
5. **Tactile** à prévoir (grandes cibles, rien qui ne dépende du survol).
6. Touches multimédia via `wpctl` / `brightnessctl` (marchent shell arrêté) ; l'OSD réagit aux changements.
7. Verrouillage et inactivité **en dernier**, hyprlock en secours ; un crash verrouillé = écran rouge.
8. Priorité aux **fonctionnalités brutes** ; le design se peaufine ensuite. simon vérifiera tout à la fin.

## Fonctionnalités demandées

- Barre (permanente sur les écrans « normaux ») ; OSD volume/luminosité ; lanceur ; notifications (un seul serveur possible → bascule d'un coup) ; fond d'écran ; inactivité et verrouillage ; IPC pour les binds.
- Audio : choix des entrées et sorties.
- Lanceur : applis + actions (emoji, recherche de fichiers, calculatrice, verrouillage, mise en veille…), puis l'écran de paramètres.
- Widgets cités : audio, paroles, monitoring, notifications, espaces de travail (liste ouverte).

## Rendu et thèmes

- Propositions de l'étude de design validées comme base. Sérigraphie écarté ; Ligne remplacé par un thème inspiré de **Nebula** (→ Constellation).
- Thèmes au choix : **Classique moderne** (défaut, pour commencer partout), Constellation, Façade, Modulaire, **Matrix** (DA de simon dans son fork).
- **Clair / sombre** pour chaque thème, bascule programmable : heures fixes ou lever/coucher du soleil ; par défaut identique partout, réglable par écran plus tard ; réglage dans l'app de paramètres (faite à la fin).

## Écrans et barre

- Deux **modes d'écran**, attribuables par écran :
  - **normal** : barre permanente, rendu classique ; l'écran interne du portable est toujours normal ;
  - **modules** : tableau de bord de modules (Xeneon), avec une interface pour choisir/redimensionner les modules.
- L'écran modules a des **espaces de travail** : grille libre, **cases fenêtre** où n'importe quelle fenêtre Hyprland peut aller (kitty sur l'écran déporté) ; idéalement des espaces de travail de modules (une page par espace de travail).
- Barre agençable : îlots, barre complète, flottante ou non, arrondis, transparence, bordures, coins… (défauts par thème, surchargeables) ; **mode « cadre »** comme Caelestia ; barre **sur le côté de son choix**.
- Chaque élément de la barre : **réagençable, redimensionnable, déplaçable** vers un autre endroit ; **détail au survol**, soigné (« assez sympa »).
- Un widget **fenêtre active** (titre de la fenêtre) ; l'emplacement par défaut de la date et de l'heure est à revoir en conséquence (l'agencement restant libre).

## Organisation

- Développement à côté de Caelestia (`qs -c lc`, lien `~/.config/quickshell/lc`).
- Réglages de simon hors du repo (`~/.config/lc/settings.json`), défauts génériques dans le repo.
- Relecture prévue par l'agent de design : conformité à la spec, qualité, cohérence, adéquation au besoin et au contexte.
