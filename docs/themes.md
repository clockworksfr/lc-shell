# Spécification des thèmes

Issue de l'étude de design du 22/11/2026 (maquettes : artifact « lc-shell rendus », v2). Sert de référence pour la phase 2 (implémentation dans `theme/defs/`). Les valeurs sont des choix de design ; aucun code n'est repris de Caelestia, les composants cités sont à recréer.

## Règles communes

- **Rôles de couleur** : `bg` (fond/bureau), `surface`, `surface2`, `surface3`, `ink`, `soft` (encre atténuée), `line`, `accent`, `onAccent`, `urgent`, `warn`, `ok`, plus des rôles propres à certains thèmes (`ghost`, `silk`, `vu`…).
- **Couches** : barre et coins d'écran en `top`. Jamais `overlay` quand l'espace de travail actif a une fenêtre plein écran.
- **Densités** : compacte 32, normale 40, tactile 56 (cibles 48). Mode modules : cibles ≥ 72.
- **Polices** : fichiers statiques uniquement (Qt ignore les axes variables) ; instancier les variables avec `fontTools varLib.instancer`.
- **Textures et effets** : coupés pendant un jeu en plein écran.

## Axes de barre (surchargeables par écran)

| Axe | Valeurs |
|---|---|
| `layout` | `islands` · `full` · `center` (largeur fixe centrée) |
| `floating` | 0/1, `margin` 0–24 |
| `radius` | 0–24 ; collée : seulement les coins côté fenêtres |
| `concave` | 0/1, coins concaves (collée seulement) |
| `groups` | `bare` · `caps` (capsules) |
| `opacity` | 0–100 |
| `border` | 0/1/2 px, couleur `line` |
| `screenCorners` | 0/12/14/20 |
| `height` | 32/40/44/56 |
| `position` | haut/bas |
| `autoHide` | non/intelligent |

## 1. Classique moderne (défaut)

| Rôle | Sombre | Clair |
|---|---|---|
| bg | #0F1114 | #E7EAEE |
| surface | #171A1E | #FAFBFC |
| surface2 | #20242A | #EEF1F4 |
| surface3 | #2B3037 | #E1E5EA |
| ink | #E9ECEF | #14171B |
| soft | #A1A9B3 | #56606B |
| line | #2B3038 | #D5DAE1 |
| accent (jade) | #5FD0A8 | #0E7A5C |
| onAccent | #06281D | #FFFFFF |
| urgent | #FF6B5E | #C8372D |
| warn | #F2C14E | #9A6A00 |
| ok | #8BD17C | #2E7D3A |

- **Polices** : Figtree 400/500/600/700 (OFL, github.com/erikdkennedy/figtree) · JetBrains Mono 400/500/600 (OFL) · Material Symbols Rounded, instances FILL 0 et 1, wght 400, opsz 24 (Apache 2.0).
- **Formes** : rayons îlot 14, contrôle 10, module 16, panneau 20, carte Xeneon 28, boutons et curseurs pilule. Bordure 1 px `line` sur îlots et panneaux, 0 sur les cartes ; urgent = liseré intérieur 4 px. Espacements 4/8/12/16/24/32. Ombre 0 4 18 #0000008C (sombre) / #1A2A3A2E (clair), panneaux 0 14 40. Animations 160–220 ms OutCubic, sans rebond.
- **Barre** : îlots flottants, marge 8, hauteur 40, rayon 14, opacité 94 %, bordure 1, groupes nus, coins d'écran 14.
- **Textures** : aucune ; option : accent tiré du fond d'écran.
- **Composants** :
  - Espaces : pastilles 8 px, actif = pilule 27×8 accent, occupé = encre 55 %, vide = `line`, urgent = `urgent`.
  - Horloge : Figtree SemiBold 15, chiffres tabulaires, date en `soft`, îlot central.
  - Îlot central dynamique, par priorité : OSD (1,2 s) > enregistrement > minuteur > nouveau titre (3 s) > heure ; largeur animée en 200 ms.
  - Curseurs : pilule 44 px dans les panneaux, 14 px dans les modules, icône et valeur dans la piste.
  - Progression : barre arrondie 6–8 px.
  - Interrupteurs : modules 112 px sur deux lignes, actif = fond accent.
  - Notifications : panneau de rayon 20, groupées par appli.
  - Tiroirs : sortent de leur îlot.

## 2. Constellation (remplace Ligne, étude v4)

Concept inspiré de Nebula (github.com/LilaccFlowerr/Nebula, **AGPL-3.0** : concept seulement, aucun code repris) : îlots flottants à rôle fixe, popups reliés à leur îlot par un col concave, verre teinté sans flou, univers spatial. Différences : palette fixe (pas de matugen), constellation et étoiles, comète, orbites, Outfit au lieu d'Inter.

| Rôle | Nuit | Aube |
|---|---|---|
| bg | #0B0E1A | #EEF0F8 |
| surface (86 % nuit, 90 % aube) | #141A2B | #FFFFFF |
| surface2 | #1C2338 | #F3F4FB |
| surface3 | #262E47 | #E4E7F4 |
| ink | #E6E9F5 | #171B2E |
| soft | #9AA3BF | #5A6180 |
| line | #2A3350 | #D8DCEC |
| accent | #9FB8FF | #4255C8 |
| accent2 | #F2A7D8 | #C2408F |
| onAccent | #0E1430 | #FFFFFF |
| urgent | #FF7A8A | #C93A4E |
| warn | #FFD27A | #956400 |
| ok | #7EE0B5 | #23805B |
| glass (reflet haut) | #FFFFFF14 | #FFFFFF99 |
| star | #FFFFFFB0 | #3A46808A |

- **Polices** : Outfit 200/300/400/500/600 (OFL, github.com/Outfitio/Outfit-Fonts) · Geist Mono 400/500 (OFL, github.com/vercel/geist-font) · Material Symbols Rounded FILL 1 wght 400 opsz 24.
- **Formes** : îlots, boutons, curseurs en pilule ; cartes 24 ; modules 22–28 ; contrôles internes 16. Bordure 1 px accent 16–22 % ; urgent = liseré 3 px + halo rose. Col 64×12 (deux arcs concaves r 12). Espacements 6/10/14/20/28. Ombre 0 6 26 #00000080 (nuit) / #2A3A8A26 (aube). Mouvement 200–260 ms OutQuint.
- **Barre** : îlots flottants, marge 10, hauteur 44, rayon 22, opacité 86 %, contour 1, groupes nus, coins d'écran 18. Cadre (off) : épaisseur 8, rayon intérieur 22, coins extérieurs 30. Verticale : 52 px, heure sur deux lignes Outfit 300.
- **Textures** : verre = surface 86 % + reflet blanc 8 % sur les 58 % hauts, sans flou ; champ d'étoiles en Canvas peint une fois (réseaux 140 et 97 px), optionnel, jamais redessiné en jeu ; halos (≤ 16 px) limités à l'étoile active, la comète, la pochette.
- **Composants** : espaces = constellation (vide : cercle 1,5 px ; occupé : point ; actif : étoile 4 branches accent avec halo ; urgent : point rose annelé ; fil lumineux en dégradé) ; horloge Outfit 300 (200 en grand) ; progression = comète (trait 2 px, traînée accent2 → accent, tête 10 px) ; curseurs pilules en dégradé ; bouton principal en dégradé 135° ; monitoring en orbites (planète à valeur × 360°) ; cartes et tiroirs reliés par un col.
- **Xeneon** : média (pochette ronde avec halo, paroles, comète, boutons 110–130 px), orbites CPU/GPU/RAM, horloge Outfit 200 + météo + agenda, modules ne pas déranger / micro / replay / minuteur, carte urgente au liseré rose.

## 3. Façade (ampli hi-fi, afficheur VFD)

| Rôle | Sombre (VFD) | Clair (alu + LCD) |
|---|---|---|
| bg | #0D1112 | #C9CCC6 |
| surface (façade) | #1B1E20 | #D7D8D5 |
| surface2 (verre/LCD) | #030505 | #B6BEA1 |
| surface3 (modules, touches) | #2B2F31 | #D4D5D2 |
| ink | #6EF3D6 (phosphore) | #1D2618 (segments) |
| soft | #6EF3D66B | #1D261873 |
| ghost (segments éteints) | #6EF3D616 | #1D261814 |
| silk (sérigraphie) | #C9CCC4 | #1E2022 |
| line | #000000 | #8F9295 |
| accent | #6EF3D6 | #1E8C7B |
| urgent (ambre) | #FFB547 | #A85A00 |
| critical | #FF4A3D | #C8392C |
| vu (cadran) | #F1DFAE | #F1DFAE |

- **Polices** : DSEG7 Classic Bold/Regular, DSEG14 Classic Bold (OFL, github.com/keshikan/DSEG) · Doto statique wght 900 ROND 0 (OFL, github.com/oliverlalan/Doto), à défaut DotGothic16 · IBM Plex Sans Condensed 500/600/700.
- **Formes** : rayons afficheur 4, module 6, touche 8 ; barre 0 en haut, 6 en bas. Bordure 2 px #000 (sombre) / 1 px #8F9295 (clair) ; biseau haut 1 px blanc 12–30 %. Espacements 8/14/24 ; vis Ø 10 à 18 px des angles ; touches Xeneon 140×120.
- **Barre** : centrée, largeur fixe 2560, collée, hauteur 44, rayon bas 6, opaque, bordure 2, groupes en capsules, coins carrés.
- **Textures** : sombre = maille VFD en ShaderEffect statique (ligne 1 px tous les 3 px, blanc 2–3 %), segments fantômes 8 % (« 88:88 » sous la valeur), halo = texte doublé 50 % + ombre 0,35 em. Clair = alu brossé (stries 1 px 3 %), sans halo.
- **Composants** :
  - Espaces : 7 segments ; actif plein avec halo, occupé 42 %, vide fantôme, urgent ambre.
  - Voyants allumés/fantômes : BT, VPN, REC, MSG, NET, JEU.
  - Horloge : DSEG7.
  - Curseurs : fader (bouton 56×30, rail 4 px) ou bargraphe de 24 cellules.
  - Progression : pointillé 8/6.
  - VU à aiguille amortie (SmoothedAnimation 0,25 s) + spectre en colonnes de points.
  - Boutons : touches rectangulaires à LED.
  - Notifications : défilement dans l'afficheur + liste en Plex Condensed.

## 4. Modulaire (synthé Eurorack)

| Rôle | Sombre (anodisé noir) | Clair (alu) |
|---|---|---|
| bg | #141617 | #D6D3CC |
| surface → surface2 (dégradé panneau) | #2B2C2E → #1D1E20 | #D3D0C8 → #BCB8AE |
| case (boîtier, rails) | #111212 | #191A1A |
| ink (sérigraphie) | #E9E7E1 | #18181A |
| line | #FFFFFF14 | #00000040 |

Communs : LCD #1A2410 sur #C6F37A, Nixie #FF8A2A, audio (accent) #E8742A, système #E5C230, alerte #D2332B, LED verte #46C46A, réseau #5AA0FF (sombre) / #2F6FB5 (clair).

- **Polices** : Michroma, Barlow Condensed 500/600/700, Nixie One, Doto statique (LCD). OFL.
- **Formes** : rayons module 3, bouton 8, CRT 18 ; boutons rotatifs et jacks ronds. Bordure 1 px intérieure ; rails 6 px (1U) et 26 px (3U) percés tous les 20 px. 1 HP = 20 px, 8 px entre modules ; boutons de transport 180×120.
- **Barre** : rail 1U centré de 2800 px, collé, hauteur 56, rayon 0, opaque, sans bordure, groupes = modules, coins carrés.
- **Textures** : alu brossé (stries verticales 1 px 2–3 % + reflet central 10 %), vis aux angles, halo Nixie (trois ombres orangées), LED avec halo 0,6 em, câbles en Shape/PathCubic 11 px (contour 16). LED à 4 Hz, 1 Hz en jeu.
- **Composants** : espaces en séquenceur 9 pas ; horloge Nixie ; fader + bouton rotatif (glissement vertical), curseurs plats sur le portable ; échelles de LED (vert, jaune ≥ 70 %, rouge ≥ 85 %) ; OSD couronne de LED + LCD « VOL 64 » ; patch audio : jacks Ø 46 (zone de prise 96), un câble = un lien PipeWire.

## 5. Matrix (DA de simon, esprit Nothing)

| Rôle | Sombre | Clair |
|---|---|---|
| surface | #0B0B0B | #F2F2F0 |
| surfaceDim (fond) | #080808 | #E4E4E2 |
| containers 0–4 | #000000 #121212 #1A1A1A #222222 #2C2C2C | #FFFFFF #FAFAF9 #FFFFFF #ECECEA #E3E3E0 |
| ink | #F2F2F2 | #111111 |
| soft | #8C8C8C | #7A7A78 |
| line | #262626 | #DCDCD9 |
| secondary | #A6A6A6 | #5C5C5A |
| accent rouge (alertes) | #D71921 | #D71921 |
| error | #E5323A | #D71921 |
| success | #8FCB9F | #3E7D52 |

Alerte = rouge avec texte #FFFFFF.

- **Polices** : Doto Matrix = Doto statique wght 900 ROND 100 (OFL) · Space Grotesk 400/500/600 statiques (OFL) · Space Mono Regular/Bold (OFL) · Material Symbols Sharp FILL 0 wght 400 opsz 24.
- **Formes** : pilule pour tous les contrôles ; cartes rayon 28 ; contour 1 px `line` sur contrôles, cartes, notifications ; boutons tonaux en contour seul. Curseur pilule 46×104 (rayon 23), interrupteur pilule 40 (rayon 20), points 6 px, modules séparées de 16.
- **Barre** : complète, collée, hauteur 40, opaque (`surface`), groupes nus, sans bordure, coins d'écran 20. Espaces à gauche, horloge au centre, statuts à droite.
- **Textures** : grille de points (pas 16, rayon 1,1, encre 16 % en clair / 13 % en sombre, sur `surfaceDim`), peinte une fois ; halo de la LED active en sombre seulement (flou 0,8, max 6).
- **Composants** :
  - Labels Space Mono en majuscules ; chiffres en Doto Matrix ; progression en points.
  - Tableau en modules : horloge, semaine, météo en glyphes de points, anneaux de points, média avec disque et progression en points, curseurs et interrupteurs pilules qui s'inversent.
  - Visualiseur en anneau de points ; animation de repos en points ; fond en grille de points.
  - États : label à 80 % en `soft` au-dessus de la valeur, valeur rouge si alerte ; échelle 0,68/0,8 sous 900 px de haut.
  - Espaces : LED 6×6 (`line` si vide, encre si occupé), active = barre 14×6, 8 px avant un numéro Space Mono.
  - Notifications : en-tête mono avec point rouge 8 px, titre court en Doto (22), actions = pilule encre + pilule filaire, bande lumineuse 3 px à 40 % de largeur, rouge si critique.
  - À recréer dans lc-shell : arc de points, égaliseur de points, icônes en points, grille de points, statistique Matrix.

## Cadre et position de la barre (étude v3)

### Axes (défauts Classique moderne)

| Axe | Valeurs | Défaut |
|---|---|---|
| `bar.position` | `top` · `bottom` · `left` · `right` | `top` |
| `bar.frame.enabled` | booléen | `false` |
| `bar.frame.thickness` | 4–16, surchargeable par côté (`top`/`bottom`/`left`/`right`, 0 accepté) | 8 |
| `bar.frame.innerRadius` | 4–32 | 18 |
| `bar.frame.opacity` | 0–100 (toujours celle de la barre) | 100 |
| `bar.frame.outline` | 0/1/2 px, couleur `line` | 1 |
| `bar.frame.color` | rôle | `surface` |
| `bar.verticalWidth` | 48 compacte · 56 normale · 72 tactile | 56 |
| `screenCorners` | `auto` avec le cadre = min(innerRadius + thickness, 32) | — |

### Défauts par thème

| Thème | Cadre | Épaisseur | Rayon intérieur | Opacité | Contour | Coins ext. | Largeur verticale |
|---|---|---|---|---|---|---|---|
| Classique moderne | non | 8 | 18 | 100 | 1 | 26 | 56 |
| Constellation | non | 8 | 22 | 86 | 1 | 30 | 52 |
| Façade | non | 12 | 6 | 100 | 2 | 18 | 64 |
| Modulaire | non | 14 | 4 | 100 | 0 | 18 | 72 |
| Matrix | **oui** | 10 | 24 | 100 | 0 | 32 | 56 |

Position par défaut `top` partout.

### Géométrie layer-shell

- **Sans cadre** : une surface de barre ancrée à son bord et aux deux voisins ; `exclusiveZone` = marge + épaisseur (îlots flottants Classique : 8 + 40 = 48 en horizontal, 8 + 56 = 64 en vertical) ; Hyprland ajoute `gaps_out`.
- **Avec cadre** :
  - Réservation : quatre surfaces invisibles sans entrée, une par bord (ancrée à ce bord et à ses voisins), `exclusiveZone` = épaisseur du côté ; le côté barre réserve l'épaisseur de la barre.
  - Dessin : une surface plein écran en couche `top`, `exclusionMode: Ignore`, anneau en pair-impair = rectangle extérieur (rayon des coins extérieurs) moins rectangle intérieur (rayon `innerRadius`). Masque d'entrée = côté barre + tiroirs ouverts.
  - `innerRadius` ≈ `rounding` Hyprland + `gaps_out` (10 + 8 = 18) pour des arrondis concentriques.
  - En cadre : îlots, flottant et auto-masquage ignorés, marge 0 ; groupes nus ou en capsules selon le thème.
- **Tiroir fusionné** (coordonnées u le long du bord, v vers l'intérieur ; v0 = épaisseur du côté, p = position, L = longueur, d = profondeur, rf = rd = max(8, innerRadius)) : départ (p − rf, v0 − 2) ; arc concave rf jusqu'à (p, v0 + rf) ; droite jusqu'à (p, v0 + d − rd) ; arc convexe jusqu'à (p + rd, v0 + d) ; droite jusqu'à (p + L − rd, v0 + d) ; arc convexe jusqu'à (p + L, v0 + d − rd) ; droite jusqu'à (p + L, v0 + rf) ; arc concave jusqu'à (p + L + rf, v0) ; fermeture dans le cadre. Écran : haut (u, v), bas (u, H − v), gauche (v, u), droite (W − v, u) ; bas et gauche : sens des arcs inversé. Ouverture : d de 0 à sa valeur en 200 ms OutCubic, raccords fixes, contenu en fondu dès 60 %. Rendu : `Shape` pair-impair ou SDF en `ShaderEffect`.
- **Plein écran** (fenêtre en mode 2 sur l'espace actif) : épaisseurs animées à 0 en 180 ms, réservations à 0, masque vide, tiroirs fermés ; jamais `overlay`. Une fenêtre agrandie (mode 1) garde le cadre.
- **Xeneon en mode modules** : pas de cadre par défaut ; avec cadre, les modules deviennent les côtés épais (zone de fenêtres = le trou). En jeu sur DP-1, le Xeneon garde son cadre et reçoit OSD et urgences.

### Barre verticale (de haut en bas)

1. Lanceur (bouton carré de la largeur de la barre).
2. Icône de l'appli active, puis espaces de travail empilés (défilement à la molette au-delà de 10). Classique : pastilles 8 px, actif = pilule debout 8 × 27.
3. Ressort.
4. Horloge sur deux lignes (HH / MM, chiffres tabulaires), date en option (0,7 em).
5. Ressort.
6. Média : pochette 32 px avec anneau de progression ; le titre passe dans le tiroir.
7. Statuts : icône + valeur de 2–3 caractères dessous (0,7 em).
8. Tray en colonne : icônes 20 px, 5 visibles puis « ⋯ ».
9. Notifications, puis session.

Jamais de texte pivoté ; pas de titre de fenêtre. Corps ≈ 0,27 × largeur. Îlots verticaux : trois îlots de la largeur de la barre à 8 px du bord (haut : lanceur et espaces ; milieu : horloge ; bas : média, statuts, tray, notifications).

### Popups selon le bord

| Bord | Ancrage | Direction | Alignement |
|---|---|---|---|
| Haut | bas de la barre | vers le bas | centré sur le déclencheur, borné à 8 px des bords |
| Bas | haut de la barre | vers le haut | idem |
| Gauche | bord droit de la barre | vers la droite | centré verticalement |
| Droite | bord gauche de la barre | vers la gauche | idem |

- Sans cadre : écart 8 px, rayon 20, ombre, glissement 12 px + fondu 180 ms. Avec cadre : tiroir fusionné.
- Réglages, média et calendrier sortent du côté de la barre. Notifications à droite (à gauche si la barre est à droite). Session à droite, au milieu. Lanceur : centré (sans cadre), côté opposé à la barre (avec cadre).
- DP-1 avec barre à gauche : 64 px sur 5120 (1,25 %) contre 48 sur 2160 (2,2 %) ; le bord gauche est loin du regard : toasts, OSD et lanceur restent au centre.
