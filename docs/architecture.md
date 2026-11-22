# Architecture cible

État des décisions au 22/11/2026. Ce document décrit où va le shell ; le README décrit ce qui existe.

## Écrans : profils et modes

Chaque écran est reconnu par son **modèle** (`ShellScreen.model`, ex. `DELL U4025QW`, `XENEON EDGE`), pas par son connecteur : avec l'eGPU, `DP-1`/`HDMI-A-1` changent. Le connecteur reste utilisable en secours (`eDP-*` pour l'écran interne).

Un **profil** associe un écran à :

- un **mode** :
  - `normal` — barre permanente, rendu classique (DP-1, écran interne du portable, tout écran inconnu) ;
  - `modules` — tableau de bord de modules avec des cases fenêtre (Xeneon) ;
- un **thème** (sinon celui du mode) ;
- `touch` — cibles agrandies, rien qui ne dépende du survol (aucun écran tactile utilisable aujourd'hui, mais prévu) ;
- des surcharges (barre, OSD…).

## Thèmes

- Thèmes prévus : **Classique moderne** (défaut et base), **Ligne**, **Façade**, **Modulaire**, **Matrix**. Spécification : [`themes.md`](themes.md). Décision du 22/11 : on part sur les propositions de design telles quelles, Classique moderne partout pour commencer (écrans normaux et modules), on peaufine ensuite.
- Chaque thème a une variante **claire** et **sombre**. Bascule : manuelle, horaires fixes, ou lever/coucher du soleil (calcul local, sans réseau). IPC pour les binds. Réglage dans l'app de paramètres (fin du projet) ; par défaut identique sur tous les écrans, réglable par écran ensuite.
- Thème choisi par mode (`normal` → Classique, `modules` → Façade par défaut), surchargeable par profil d'écran.
- Un thème = des tokens (palette par variante, polices statiques, rayons, bordures, espacements) + des **axes de style** pour les composants (forme des curseurs, des jauges, des espaces de travail, de l'horloge…) + les **valeurs par défaut de la barre**. Aucun composant ne teste le nom d'un thème : il lit des tokens et des axes.
- Portée : chaque fenêtre porte le thème de son écran (`window.theme`) ; les composants le retrouvent par `QsWindow.window`. Un même composant peut donc s'afficher en Classique sur DP-1 et en Façade sur le Xeneon.

## Barre (écrans normaux)

Toujours présente. Agencement des blocs dans `left` / `center` / `right`, et rendu paramétrable, chaque thème fournissant ses défauts :

| Paramètre | Valeurs |
|---|---|
| `style` | `full` (une bande) · `islands` (un îlot par zone) |
| `floating` | décollée des bords (marge) ou collée |
| `margin`, `radius`, `opacity`, `border` | nombres |
| `screenCorners` | rayon des coins d'écran arrondis (0 = aucun) |

## Mode modules

- Une **grille libre** de cases. Une case est soit un **module** (média, paroles, monitoring, VU…), soit une **case fenêtre**.
- Les **espaces de travail Hyprland** de cet écran sont des **pages de modules** : chaque espace de travail a sa propre grille. Changer d'espace de travail change de page.
- Une fenêtre arrivant sur un espace de travail de l'écran modules est rendue flottante et placée par le shell dans une case fenêtre libre (règles poussées via `hl.dsp.window.float/move/resize`). N'importe quelle fenêtre Hyprland peut y aller (kitty, btop…).
- Les modules sont dessinés sur la couche `bottom`, sous les fenêtres.
- Une interface d'édition permettra de choisir, placer et redimensionner modules et cases fenêtre.

## Plein écran

Rien d'**automatique** ne s'affiche au-dessus d'un jeu en plein écran (`HyprlandWorkspace.hasFullscreen`) : l'OSD et les notifications sont redirigés vers un écran modules s'il y en a un, sinon retenus. Ce qui est appelé explicitement (lanceur, panneaux) reste autorisé.

## Phases

Fait : socle (1), jetons du thème Classique (2, partiel), premier jet du mode modules (3), langues EN/FR. Notifications (5) écrites et testées en essai contrôlé (Caelestia arrêté une minute) ; bascule définitive à décider. Priorité actuelle : **fonctionnalités brutes** ; le design se peaufine après.


1. **Socle** — profils d'écran par modèle, registre de thèmes avec clair/sombre programmable, thème par fenêtre, styles de barre, politique plein écran, indicateur tactile.
2. **Thèmes** — implémentation des cinq thèmes d'après la spécification de l'artifact (polices, palettes, composants).
3. **Mode modules** — grille, pages par espace de travail, cases fenêtre, premiers modules (média, paroles, monitoring, VU).
4. **Éditeur** — interface pour gérer modules et barre ; écran de paramètres (aussi accessible depuis le lanceur).
5. **Notifications** (bascule depuis Caelestia), fond d'écran, puis inactivité et verrouillage en dernier.
