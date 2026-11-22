# Barre : édition et cartes de survol (étude v4)

Spécification issue de l'étude de design (artifact « lc-shell rendus », onglets Édition et Survol). À adapter au modèle de config existant (profils d'écrans dans `screens[]`, config par mode) plutôt qu'à la structure `bar.screens` proposée par l'étude.

## Modèle de données

- Zones `start`, `center`, `end` (en vertical : haut, milieu, bas).
- Une zone = liste de **groupes** ; un groupe = un îlot (disposition îlots) ou une capsule / un séparateur (barre complète, cadre).
- Widget : `{ id, type, size, options }` ; `id` stable (type + compteur) ; `size` = `compact` | `normal` | `extended`. Ordre = ordre des tableaux.
- Types : `workspaces`, `window`, `clock`, `media`, `volume`, `network`, `bluetooth`, `battery`, `notifications`, `tray`, `system`, `weather`, `dynamicIsland`.
- Vertical : `window` forcé compact ; `media`, `notifications`, `clock` limités à `normal` (taille refusée → taille autorisée suivante).
- Widget envoyé vers un écran modules : devient un module (S = 2×1, M = 4×2, L = 6×3) à la première case libre.
- Écriture à « Terminé », atomique (fichier temporaire + renommage) ; la config reste rechargée à chaud.
- Compatibilité : un widget écrit comme simple chaîne (`"clock"`) reste accepté.

## Mode édition

- **Entrée** : clic droit sur la barre → menu (« Modifier la barre », « Réglages de la barre », « Paramètres ») ; appui long 600 ms sur un widget (tactile) ; raccourci (proposé : `Super + Alt + E`) ; Paramètres › Barre ; IPC `bar edit`. Toutes les barres passent en édition ; cartes de survol désactivées.
- **Affichage** : zones en pointillé accent 55 % + fond accent 7 % + étiquette mono 10 px ; chaque widget a une poignée ⋮⋮, une pastille S/M/L et une croix (20 px, 48 au doigt) ; barre d'outils flottante sous la barre de l'écran actif : Annuler, Rétablir, Palette, Valeurs du thème, Abandonner, Terminé, vignettes d'écrans.
- **Glisser** : seuil 4 px (souris), 300 ms d'appui (doigt) ; widget soulevé échelle 1,05, rotation −1,5°, opacité 0,92, fantôme 35 % à sa place ; curseur d'insertion 3 px accent, voisins qui s'écartent en 160 ms ; insertion avant le premier widget dont le milieu dépasse le pointeur.
- **Cibles** : entre widgets, tête/fin de zone, « + Nouvel îlot » / « + Groupe », palette (= retirer), vignette d'écran (= déplacer vers cet écran ; pas de glisser entre surfaces layer-shell) ; cible refusée bordée de rouge avec la raison.
- **Taille** : pastille S → M → L (en bas à droite du widget, la croix en haut à gauche : jamais de chevauchement entre voisins ; 28 px sur écran tactile) ; `+` / `−`.
- **Inspecteur** (clic ; feuille du bas au doigt) : tailles avec aperçu, options du widget, « Déplacer vers… », « Retirer ».
- **Palette** : widgets absents, aperçu, recherche ; glisser vers une zone ou « + » puis la zone.
- **Annulation** : 50 instantanés, `Ctrl+Z` / `Ctrl+Maj+Z` ; « Abandonner » restaure l'état d'entrée ; après « Terminé », toast « Annuler » 8 s.
- **Sortie** : Terminé, Échap, clic hors barre et barre d'outils (changements gardés) ; un plein écran qui démarre ferme l'édition en enregistrant.
- **Clavier** : Tab choisit un widget ; ← / → déplacent (et changent de zone en bout de zone) ; Suppr retire ; Entrée ouvre l'inspecteur.
- **Cadre** : widgets seulement dans le côté de la barre.

## Cartes de survol

### Règles communes

- Apparition après 350 ms d'immobilité : le tiroir sort de la barre. Carte ouverte (ou fermée depuis moins de 600 ms) : un autre widget s'affiche sans attente, le tiroir **ne se referme pas** : il glisse et se redimensionne jusqu'au nouveau widget (durée `base` du thème) pendant que le contenu passe en fondu enchaîné. Surface layer-shell persistante le long de la barre, entrée limitée au tiroir. Sortie : grâce 250 ms, puis fondu 120 ms ; le pointeur sur la carte la garde.
- Clic : la carte grandit en panneau complet (220 ms). Toucher : 1er appui = carte, 2e / « Ouvrir » = panneau, appui long = édition. Clavier : focus = carte, Entrée = panneau, Échap = fermer. Les contrôles de la carte marchent sans ouvrir le panneau.
- Jamais en plein écran, en édition, pendant un glisser.
- 380 px de large (360 sur le portable), ≤ 60 % de la hauteur de l'écran ; marge intérieure 16, écart 12.
- Placement : sous la barre (haut), au-dessus et sections inversées (bas), à côté et centrée verticalement (gauche/droite), tiroir fusionné (cadre) ; bornée à 8 px des bords.
- Attache par thème : Classique 8 px d'écart, rayon 20 ; Constellation col 64×12, rayon 24 ; Façade carte suspendue, coins hauts carrés ; Modulaire panneau vissé ; Matrix 8 px, contour 1, rayon 28.

### Cartes

1. **Espaces de travail** (Hyprland workspaces + clients) : « Espace N », écran, nombre de fenêtres ; aperçu schématique aux proportions de l'écran (rectangles avec icône et titre, fenêtre focalisée cernée) ; vignettes des espaces ; « clic : y aller · glisser une fenêtre ici ».
2. **Horloge et calendrier** (heure, agenda iCal/CalDAV, second fuseau optionnel) : date longue + semaine, puce du second fuseau ; grande heure, secondes atténuées ; mini-mois (colonne semaines, semaine teintée, jour plein, points d'événements) ; deux prochains événements ; molette = mois.
3. **Média** (MPRIS, paroles en cache) : pochette 84 px, source « 1/3 », titre, artiste, album ; progression cliquable avec temps écoulé/restant ; trois lignes de paroles ; précédent / lecture (64 px) / suivant ; puces des sources.
4. **Volume** (PipeWire) : sortie, curseur 28 px avec valeur ; applis avec mini-barres ; micro avec niveau en direct ; puces de sortie ; molette ±2 %, clic milieu = muet.
5. **Réseau** (NetworkManager, compteurs `/sys/class/net` sur 60 s, VPN) : signal (dBm, bande, canal) ; modules réception/envoi avec courbe ; IP locale, latence passerelle ; VPN ; hors ligne : dernier réseau + « Réessayer ».
6. **Bluetooth** (BlueZ, UPower) : une ligne par appareil (anneau de batterie, nom, %, autonomie, « bas » < 20 %, « Connecter » si déconnecté).
7. **Batterie** (UPower, power-profiles-daemon) : grand %, état, autonomie ; courbe 6 h + projection pointillée + repère « maintenant » ; profils ; santé, cycles.
8. **Notifications** : titre + badge + bascule ne pas déranger ; 3 dernières groupées « ×n » ; « Tout effacer » ; glisser pour ignorer.
9. **Tray** (StatusNotifierItem) : icône, nom, état, infobulle, puces des actions du menu ; clic = ouvrir, clic droit = menu.
10. **Système** (`/proc`, amdgpu sysfs/hwmon, sans réveiller l'eGPU) : modules CPU / GPU (valeur, température, courbe 60 s) ; barres RAM et VRAM ; 3 processus les plus gourmands ; ventilateurs ; clic = btop.
11. **Météo** (open-meteo, en cache) : grand chiffre, condition, ressenti, vent ; 6 prochaines heures + probabilité de pluie ; source et heure du relevé ; hors ligne : dernière donnée datée.

12. **Fenêtre active** (Hyprland toplevels) : icône, appli, espace de travail et écran ; titre complet ; autres fenêtres de l'appli (clic : y aller) ; actions Flottante, Plein écran, Épingler, Fermer (second clic pour confirmer) ; « Déplacer vers » un espace de travail. Pendant un partage d'écran (évènement Hyprland `screencast`), titres masqués dans la barre et la carte.

### Déclinaison par thème

| Thème | Progression | Grands chiffres | Labels |
|---|---|---|---|
| Classique moderne | pilule | Figtree 700 | JetBrains Mono majuscules |
| Constellation | comète (2 px + tête) | Outfit 200–300 | Outfit, lettres espacées |
| Façade | segments VFD / LCD | Doto dans un afficheur | Plex Condensed |
| Modulaire | échelle de LED | Nixie | Michroma |
| Matrix | points de 6 px | Doto Matrix | Space Mono majuscules |

## Implémenté (design 5)

- Barre d'outils (`windows/bar/EditToolbar.qml`) : actions (annuler, rétablir, abandonner, terminé) ; inspecteur du widget sélectionné avec ses trois tailles en aperçu vivant, la zone, « Vers <écran> » (autres écrans normaux avec barre ; annulable en une fois) et « Retirer » ; palette des widgets absents avec aperçu et recherche.
- Après « Terminé » : toast « Barre enregistrée · Annuler » 8 s (`EditToast.qml`, barre de temps, pause au survol) ; « Annuler » remet les barres d'avant l'enregistrement.
- IPC : `bar select <type>`, `bar resize <compact|normal|extended>`, `bar undoSave`.
- Pas encore : widget soulevé (échelle, rotation), cible refusée avec sa raison, envoi vers un écran modules (en module), hachures du cadre, feuille du bas au doigt.

