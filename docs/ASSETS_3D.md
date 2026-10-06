# WordEnd 3D — Cahier des charges des assets 3D

Personnages, ennemis, décors et île : le format attendu par le jeu.

Ce document s'adresse à qui produit les assets : une IA (ChatGPT ou un autre outil de génération),
un artiste, ou un mélange des deux (Blender, VRoid Studio, Meshy…). Il décrit **exactement** ce que
le projet Godot sait intégrer sans retoucher le gameplay. Tout ce qui est marqué **obligatoire**
conditionne le fonctionnement du jeu : un nom d'animation ou une durée qui ne correspond pas casse
le combat. Le reste est une recommandation de style.

> **Consigne pour l'IA qui lit ce document** : produis les fichiers listés en section 9, dans
> l'arborescence indiquée, en respectant les conventions des sections 3 à 7. Pour chaque fichier,
> donne aussi une ligne de crédit (section 10). Quand tu ne peux pas produire directement un
> binaire `.glb`, produis un script Blender (Python, `bpy`) qui le génère et l'exporte avec les
> réglages de la section 3.4, et dis-le clairement. Ne livre jamais un modèle sans ses animations
> nommées ni sans son fichier `.anim.json`.

---

## 1. Le jeu en bref

- **Genre** : action-aventure 3D en vue à la 3e personne, centrée sur le combat (façon Zelda),
  jouable dans le navigateur (WebGL 2), sur ordinateur et téléphone.
- **Moteur** : Godot 4.7, rendu « Compatibility » (OpenGL 3 / WebGL 2). Pas de lancer de rayons,
  pas d'effets lourds : une seule lumière directionnelle (le soleil couchant) et une lumière
  ambiante.
- **Héroïne** : Chtholly, jeune fille aux cheveux bleus en dégradé vers le rouge, uniforme noir à
  liserés dorés, qui manie **Seniolis**, une grande épée bleu glacier. Elle frappe en trois coups
  enchaînés et lance une **onde magique** après une charge.
- **Ennemis** : les **Timeres**, créatures vert sombre au long cou terminé par une gueule dentée,
  au corps voûté porté par six pattes fines d'araignée. Quatre tailles : Petit, Normal, Coureur,
  Grand (un seul modèle, mis à l'échelle par le jeu).
- **Monde** : une île de 160 × 160 m au soleil couchant : village au centre, dunes à l'ouest (avec
  l'arène), forêt au nord, plage au sud, colline à l'est.
- **Aujourd'hui** : les personnages sont des sprites 2D (planches dessinées), le décor est fait de
  formes simples. Les assets 3D doivent remplacer ces éléments **sans changer le code de jeu**.

Références visuelles dans le dépôt :
- `assets/characters/chtholly/chtholly.png` et `assets/enemies/timere/timere.png` : les planches
  actuelles (apparence, couleurs, poses de chaque animation) ;
- les captures du jeu (village, forêt, arène) jointes à la PR de la tranche verticale.

## 2. Direction artistique

- **Chibi, low-poly, coloré et doux**, dans l'esprit d'Animal Crossing : têtes grandes (environ un
  tiers de la hauteur pour les personnages), grands yeux, formes arrondies, silhouettes lisibles à
  10 m de distance.
- **Couleurs** : vives mais douces. Palette de l'île au couchant (indicative) :

  | Usage | Couleur |
  | --- | --- |
  | Ciel haut / bas | `#7A5C8F` violet → `#F6A96B` orange |
  | Herbe | `#8DBF6A` |
  | Sable des dunes | `#E9C48F` |
  | Eau du lagon | `#3F9EC4` |
  | Murs des maisons | `#FFF2D6` |
  | Toits | `#E5615A`, `#6B8FD6`, `#A178C9` |
  | Bois | `#B57F52` (clair), `#73503A` (foncé) |

- **Matériaux simples** : couleur de base (texture peinte à la main ou couleurs unies), pas de
  métal (`metallic = 0`), rugosité élevée (`roughness ≈ 0.8`). Pas de normal map obligatoire. Pas
  de matériaux transparents mélangés : pour les bords découpés (feuillage, mèches), utiliser
  l'alpha **découpé** (« alpha clip / mask »), jamais l'alpha mélangé (« blend »).
- **Facettes visibles acceptées** (low-poly assumé) ; pas de détails fins invisibles en jeu.
- **Lumière** : le jeu éclaire avec un soleil rasant orangé et une ambiance claire. Éviter les
  textures très sombres ou très saturées : elles deviennent illisibles au couchant.

## 3. Conventions communes à tous les modèles (obligatoire)

### 3.1 Format

- **glTF 2.0 binaire : `.glb`**, une scène par fichier, textures **embarquées** dans le `.glb`.
- Textures **PNG**, dimensions en **puissance de deux** (256, 512, 1024), espace sRGB pour la
  couleur.
- Pas de caméras ni de lumières dans les fichiers.
- Un seul jeu d'UV (`TEXCOORD_0`).

### 3.2 Repère et échelle

- **1 unité = 1 mètre.**
- **Y vers le haut.**
- **L'avant du modèle regarde vers +Z** (convention glTF ; dans Blender, avant = −Y avant export,
  l'exporteur glTF convertit). Le jeu fait tourner le modèle autour de Y pour que son +Z pointe
  dans la direction de marche ou vers la cible.
- **Origine** :
  - personnages et ennemis : **au sol, au centre entre les pieds** (ou sous le centre du corps
    pour le Timere) ;
  - décors : **au centre de la base, au niveau du sol** (y = 0 = point de contact avec le sol).
- Transformations « appliquées » (échelle 1, rotation 0 sur l'objet racine) avant export.

### 3.3 Budgets (obligatoire : le jeu tourne dans un navigateur, jusque sur téléphone)

| Asset | Triangles max | Matériaux max | Texture max | Taille du `.glb` |
| --- | --- | --- | --- | --- |
| Chtholly (épée comprise) | 15 000 | 2 | 1024 × 1024 | ≤ 3 Mo |
| Autre personnage jouable | 12 000 | 2 | 1024 × 1024 | ≤ 3 Mo |
| PNJ | 8 000 | 2 | 512 × 512 | ≤ 1,5 Mo |
| Timere (jusqu'à 12 à l'écran) | 4 000 | 1 | 512 × 512 | ≤ 1 Mo |
| Décor (prop) | 2 000 (arbre : 1 500) | 1 | atlas partagé 512 × 512 | ≤ 300 Ko |

- Os : 64 au plus, **4 influences par sommet** au plus.
- Toute la scène affichée doit rester sous **150 000 triangles** et **150 appels de dessin** :
  préférer peu de matériaux partagés et peu d'objets séparés.
- Le jeu complet doit rester sous **25 Mo compressés** jusqu'au jalon M3 (10,6 Mo aujourd'hui),
  60 Mo au jalon M4.

### 3.4 Réglages d'export (Blender → glTF)

- Format : **glTF Binary (.glb)**.
- Inclure : objets sélectionnés ou visibles, **Apply Modifiers**, **+Y Up** coché.
- Maillage : UVs, normales, couleurs de sommets si utilisées ; pas de tangentes nécessaires.
- Animation : **Animations** cochées, mode d'animation **« Actions »** (chaque action Blender
  devient une animation glTF qui porte son nom : nommez les actions exactement comme en section
  4.3), échantillonnage des animations activé, **pas de « root motion »**.
- Skinning : cocher **Skinning**, « Include All Bone Influences » décoché (4 au plus).
- Compression Draco : **non** (le jeu ne la lit pas).

## 4. Personnages jouables

### 4.1 Fichiers par personnage

Pour un personnage d'identifiant `<id>` (minuscules ASCII, sans espace : `chtholly`) :

```
assets/models/characters/<id>/<id>.glb            modèle + squelette + animations
assets/models/characters/<id>/<id>.anim.json       cadence et images clés de chaque animation
assets/models/characters/<id>/<id>_portrait.png    portrait carré 256 × 256, fond transparent
```

Le portrait sert au menu de sélection et à la boîte de dialogue : buste de face, cadré serré,
expression neutre et souriante.

### 4.2 Modèle

- **Tailles debout** (sommet de la tête, sans l'épée) : Chtholly **1,50 m** ; bibliothécaire
  1,60 m ; forgeron 1,75 m ; enfant 1,10 m. Un autre personnage : entre 1,1 et 1,8 m.
- **Largeur** : le corps tient dans un cylindre vertical de **0,35 m de rayon** (la collision du
  joueur), bras le long du corps. Seules l'épée et les mèches peuvent en sortir.
- **Pose de repos du squelette** : T-pose ou A-pose.
- **Squelette** humanoïde, un seul maillage « skinné » de préférence. Noms d'os libres mais
  identiques d'un personnage à l'autre (pour partager des animations), par exemple : `hips`,
  `spine`, `chest`, `neck`, `head`, `shoulder.L`, `upper_arm.L`, `lower_arm.L`, `hand.L`,
  `upper_leg.L`, `lower_leg.L`, `foot.L` (et `.R`).
- **Seniolis** (Chtholly seulement) : maillage nommé `Seniolis`, attaché à l'os `hand.R`, longueur
  environ **1,2 m**, lame large bleu glacier avec reflets clairs, garde sombre. Elle fait partie du
  même `.glb` et suit les animations.

### 4.3 Animations (noms et durées : obligatoire)

- **Noms exacts**, en minuscules, sans accent ni suffixe : `repos`, `marche`, `course`, `attaque`,
  `charge`, `degats`, `mort`. Le jeu appelle les animations par ces noms. Une animation
  supplémentaire est tolérée, une animation manquante ne l'est pas.
- **Sur place** : aucune translation horizontale de la racine (le jeu déplace le personnage
  lui-même). Le bassin peut monter et descendre.
- **Cadence et images** : le jeu raisonne en « images » comme l'easter egg 2D. Une animation a une
  cadence `ips` (images par seconde) et un nombre d'images ; **sa durée doit valoir exactement
  `images / ips` secondes** (à 1 ms près). Les images « coup » (l'épée touche) et l'image
  « onde » (l'onde magique part) sont des numéros d'image, à partir de 0.

| Animation | ips | Images | Durée | Boucle | Coup | Onde | Contenu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `repos` | 10 | 20 | 2,0 s | oui | | | respiration, léger balancement, épée en main |
| `marche` | 10 | 6 | 0,6 s | oui | | | un cycle complet de marche (2 pas) à 4 m/s |
| `course` | 14 | 5 | 0,357 s | oui | | | un cycle de course (2 foulées) à 7 m/s, buste penché |
| `attaque` | **14** | **4** | **0,286 s** | non | **1, 2, 3** | | coup d'épée horizontal devant soi (arc de 90°) : image 0 armé, images 1 à 3 la lame balaie l'avant, fin sur une pose de garde |
| `charge` | **10** | **4** | **0,4 s** | non | | **3** | images 0 à 2 : rassemble la magie (le jeu **fige** ces poses tant que le bouton est tenu, elles doivent tenir seules) ; image 3 : relâche, épée pointée vers l'avant (+Z) |
| `degats` | 10 | 4 | 0,4 s | non | | | recul sous un coup, buste rejeté en arrière |
| `mort` | 10 | 12 | 1,2 s | non | | | chute au sol ; **la dernière image reste à l'écran** (allongée) |

En gras : valeurs **imposées** par le combat. Les autres peuvent varier (gardez alors
`durée = images / ips` et indiquez-les dans le `.anim.json`).

### 4.4 Fichier `<id>.anim.json` (obligatoire)

Le glTF ne sait pas dire qu'une animation boucle ni quelles images touchent : ce fichier le dit au
jeu. Mêmes clés que les planches 2D de l'easter egg.

```json
{
  "version": 1,
  "modele": "chtholly.glb",
  "hauteur_m": 1.5,
  "animations": {
    "repos":   { "ips": 10, "images": 20, "boucle": true },
    "marche":  { "ips": 10, "images": 6,  "boucle": true },
    "course":  { "ips": 14, "images": 5,  "boucle": true },
    "attaque": { "ips": 14, "images": 4,  "boucle": false, "coup": [1, 2, 3] },
    "charge":  { "ips": 10, "images": 4,  "boucle": false, "onde": 3 },
    "degats":  { "ips": 10, "images": 4,  "boucle": false },
    "mort":    { "ips": 10, "images": 12, "boucle": false }
  }
}
```

### 4.5 PNJ (bibliothécaire, forgeron, enfant, futurs habitants)

- Même format et mêmes conventions que les personnages jouables, dossier
  `assets/models/characters/<id>/`.
- Identifiants actuels : `bibliothecaire` (dame âgée, cheveux argentés, lunettes rondes, robe
  violette), `forgeron` (homme robuste, barbe brune, tablier de cuir), `enfant` (casquette rouge,
  tenue verte).
- Animation **obligatoire** : `repos`. Recommandées : `marche`, et une petite animation de parole
  `parle` (boucle, facultative). Portrait obligatoire.

## 5. Ennemis : les Timeres

Fichiers :

```
assets/models/enemies/timere/timere.glb
assets/models/enemies/timere/timere.anim.json
```

- **Un seul modèle** à l'échelle 1 : hauteur au repos **1,03 m** (sommet de la tête), longueur
  environ 1,3 m. Le jeu l'agrandit lui-même : Petit × 0,8, Coureur × 0,9, Normal × 1, Grand × 1,3.
  Ne pas livrer quatre modèles (une variante de couleur pour le Grand est un bonus, en matériau
  séparé dans le même fichier).
- Face vers **+Z**, origine **au sol sous le centre du corps**, corps tenant dans un cylindre de
  0,4 m de rayon (pattes au repos comprises, à l'échelle 1).
- Apparence : voir `assets/enemies/timere/timere.png`. Vert sombre (`#4D5E3A` à `#6E8150`), peau
  granuleuse, petites pustules, yeux clairs, gueule dentée au bout d'un long cou souple, six pattes
  fines articulées.
- Squelette : colonne + cou (au moins 4 os pour onduler) + tête + mâchoire + pattes (2 os par
  patte).

| Animation | ips | Images | Durée | Boucle | Coup | Contenu |
| --- | --- | --- | --- | --- | --- | --- |
| `repos` | 6 | 5 | 0,833 s | oui | | cou qui ondule, pattes qui tapotent |
| `marche` | 7 | 4 | 0,571 s | oui | | marche d'araignée, cou bas |
| `course` | 12 | 6 | 0,5 s | oui | | course rapide, cou tendu vers l'avant (le Coureur fonce en ligne droite) |
| `fouet` | **8** | **4** | **0,5 s** | non | **1, 2** | coup de cou latéral en fouet, portée ~1 m devant |
| `morsure` | **8** | **4** | **0,5 s** | non | **1, 2** | la tête plonge vers l'avant et mord |
| `degats` | 12 | 5 | 0,417 s | non | | secousse, recul du corps |
| `mort` | 8 | 6 | 0,75 s | non | | s'effondre, pattes repliées ; la dernière image reste |

`timere.anim.json` : même structure qu'en 4.4, avec ces valeurs (`"coup": [1, 2]` pour `fouet` et
`morsure`).

## 6. Décors (props)

### 6.1 Fichiers

```
assets/models/props/<nom>.glb
assets/models/props/palette.png      atlas de couleurs partagé par tous les décors (512 × 512)
```

**Atlas partagé recommandé** : une seule texture de palette (cases de couleur unie) pour tous les
décors, les UV de chaque face pointant vers une case. Tous les décors partagent alors **un seul
matériau**, ce qui permet au jeu de les regrouper (peu d'appels de dessin).

### 6.2 Conventions

- Origine au **centre de la base, au sol**, avant vers +Z, échelle réelle (mètres).
- **Collisions** : ajouter dans le même `.glb` une forme simplifiée **invisible** dont le nom se
  termine par **`-colonly`** (boîte, cylindre ou boîte englobante grossière, quelques dizaines de
  triangles), ou **`-convcolonly`** pour une forme convexe. Godot en fait automatiquement un corps
  statique. Pas de collision pour le feuillage, les fleurs, l'herbe : seulement les troncs, murs,
  rochers, clôtures.
- Pas de faces cachées sous le sol ; pas de faces doubles.

### 6.3 Liste des décors à remplacer (ordres de grandeur actuels)

| Nom (`<nom>.glb`) | Description | Taille indicative (L × H × P) |
| --- | --- | --- |
| `house` | maison de village, toit coloré, porte, fenêtres éclairées, jardinière | 5 × 5 × 4,5 m (porte 1,2 × 2 m) |
| `well` | puits de pierre au toit de bois | Ø 1,4 m, 2,5 m de haut |
| `arch` | portail d'entrée du village (style torii rouge) | 4 × 3,5 m |
| `hedge` | haie taillée (module répétable) | 2 × 1,2 × 0,8 m |
| `fence` | clôture de bois (module répétable) | 2 × 1 m |
| `lamp` | lampadaire, lanterne chaude | 0,4 × 2,6 m |
| `tree_round` | feuillu rond | Ø 3,5 m, 5 m |
| `tree_pine` | sapin de la forêt (étages de cônes) | Ø 3,2 m, 4,5 m |
| `tree_blossom` | cerisier en fleurs | Ø 4 m, 5 m |
| `palm` | palmier de la plage, noix de coco | 6 m |
| `bush` | buisson | Ø 1,2 m |
| `flowers` | massif de fleurs (bleues, roses, jaunes) | Ø 1 m |
| `rock` | rocher arrondi (3 variantes : `rock_a`, `rock_b`, `rock_c`) | 0,5 à 2 m |
| `log` | tronc couché | 2,5 × Ø 0,5 m |
| `mushroom` | champignon rouge à pois (cercle de la clairière) | 0,4 à 0,8 m |
| `ruin` | ruine de pierre des dunes (murs effondrés) | 3 × 2,5 m |
| `pillar` | colonne / poteau des dunes | Ø 0,6 × 3 m |
| `banner` | bannière sur mât | 0,8 × 3 m |
| `pier` | ponton de la plage (module) | 2 × 4 m |
| `umbrella` | parasol de plage | Ø 2 m, 2,3 m |
| `buoy` | bouée qui marque la limite de l'île | Ø 0,6 m |
| `lookout` | belvédère du sommet de la colline | 4 × 4 × 4 m |
| `arena_sign` | panneau de bois « Affronter les Timeres » (sans texte gravé : le jeu l'affiche) | 1,2 × 1,8 m |

Nouveaux décors bienvenus (même format) : charrette, étal de marché, bancs, tonneaux, caisses,
moulin, statue, lanternes suspendues, pancartes de zone.

## 7. L'île et ses zones (cartes)

Le terrain actuel est calculé par le jeu (relief, côte, dunes, colline) et peint par zones. Trois
façons de le remplacer, de la plus simple à intégrer à la plus lourde :

**A. Garder le terrain, remplacer les décors (recommandé d'abord)** : les props de la section 6
suffisent à changer l'allure du monde. Rien à livrer de plus.

**B. Terrain en images** (idéal pour une IA qui génère des images) :

```
assets/models/island/island_height.png    carte de hauteur, niveaux de gris 16 bits, 257 × 257 px
assets/models/island/island_albedo.png    couleur du sol vue de dessus, 1024 × 1024 px
assets/models/island/island_layout.json   rappel des repères ci-dessous (centres de zones, échelle)
```

- L'image couvre le carré de 160 × 160 m : **haut de l'image = nord (−Z)**, **gauche = ouest
  (−X)** ; 1 pixel de hauteur = 0,625 m.
- Hauteur : noir (0) = −1,3 m (fond de la mer), blanc (65535) = +12 m, linéaire. Le niveau de
  l'eau est à −0,6 m ; le sol courant (village) à 0 m.
- L'albédo peint l'herbe, les chemins de terre (3 m de large au moins), le sable, la place pavée du
  village, l'anneau de l'arène, le sous-bois.

**C. Île complète en `.glb`** : `assets/models/island/island.glb`, sol visible ≤ 60 000 triangles,
avec une forme de collision séparée `ground-colonly` simplifiée (≤ 20 000 triangles). Respecter
exactement les repères ci-dessous.

### Repères à respecter (obligatoire pour B et C)

Coordonnées en mètres, centre de l'île = (0, 0), x vers l'est, z vers le sud, y vers le haut.

| Zone | Centre (x, z) | Contraintes de jeu |
| --- | --- | --- |
| Village | (0, 0) | place plate de 9 m de rayon (puits au centre) ; zone de ±22 m fermée par une haie à ±21 m avec **4 portes** (N, S, E, O) au bout des chemins ; point d'apparition du joueur en (0, 9) ; 6 maisons autour de la place |
| Dunes au couchant | (−51, 0) | **arène plate de 15 m de rayon, totalement dégagée** (rien de plus haut que 0,3 m) ; 4 points d'apparition d'ennemis à 13 m du centre (N, S, E, O) ; dunes et ruines au-delà de 15 m |
| Forêt des Timeres | (0, −51) | **clairière de 15 m de rayon sans arbre** au centre ; sapins tout autour |
| Plage aux coquillages | (0, +51) | baie au sud, ponton, palmiers, rochers, parasols |
| Colline du belvédère | (52, −3) | rayon 21 m, sommet plat de 4 m de rayon à **8 m** de haut, belvédère au sommet |

Règles de jeu sur tout le terrain : **pentes praticables ≤ 40°** (45° au maximum), aucun trou, pas
de marche de plus de 10 cm sur les chemins, chemins d'au moins 3 m entre les zones, côte en pente
douce vers l'eau, limite de l'île (murs invisibles) au carré de ±80 m.

## 8. Images 2D associées

- **Portraits** : 256 × 256, PNG transparent (section 4.1).
- **Icônes d'objets** (facultatif) : 64 × 64, PNG transparent, `assets/items/<id>.png` : fragment
  de page, marque-page porte-bonheur, coquillage, fleur bleue.
- **Textures** : puissance de deux, ≤ 1024, PNG ; pas de texte écrit dans les textures (le jeu est
  en français et pourra être traduit).
- **Planches 2D** (si l'on garde des sprites pour un personnage plutôt qu'un modèle 3D) : même
  format que `assets/characters/chtholly/chtholly.png` + `.json` (une image par pose, ancre aux
  pieds, mêmes animations et mêmes nombres d'images que le JSON de Chtholly).

## 9. Livraison

Arborescence complète attendue (seuls les dossiers des assets livrés) :

```
assets/
├── CREDITS.md                                   une ligne par asset (section 10)
└── models/
    ├── characters/
    │   ├── chtholly/      chtholly.glb, chtholly.anim.json, chtholly_portrait.png
    │   ├── bibliothecaire/
    │   ├── forgeron/
    │   └── enfant/
    ├── enemies/
    │   └── timere/        timere.glb, timere.anim.json
    ├── props/             <nom>.glb (section 6.3), palette.png
    └── island/            (option B ou C de la section 7)
```

Les `.glb` sont suivis par **Git LFS** dans ce dépôt (déjà configuré dans `.gitattributes`) :
installer `git lfs` avant de les commiter.

### Check-list avant de livrer

- [ ] Le `.glb` s'ouvre sans erreur dans le validateur glTF de Khronos et dans une visionneuse glTF
      (ou Blender).
- [ ] Échelle : Chtholly mesure 1,50 m, le Timere 1,03 m ; origine aux pieds ; face vers +Z.
- [ ] Toutes les animations obligatoires sont présentes, **nommées exactement**, sur place.
- [ ] Chaque durée vaut `images / ips` du `.anim.json` ; `attaque` = 0,286 s, `charge` = 0,4 s,
      `fouet` et `morsure` = 0,5 s.
- [ ] Budgets de la section 3.3 respectés (triangles, matériaux, textures, poids du fichier).
- [ ] Textures embarquées, PNG, puissance de deux ; pas de transparence mélangée.
- [ ] Décors : formes `-colonly` présentes pour ce qui doit bloquer ; feuillage sans collision.
- [ ] Une ligne de crédit par asset.

## 10. Licence et provenance

Pour chaque fichier livré, une ligne dans `assets/CREDITS.md` : chemin, auteur ou outil (par
exemple « généré avec ChatGPT, modèle X, le JJ/MM/AAAA » ou « Blender, par … »), licence accordée
au projet, sources éventuelles (packs CC0 : Kenney, Quaternius, Poly Haven, avec leur URL). Les
assets générés par IA sont marqués comme tels, comme les planches générées avec Gemini. Rappel du
plan (section 5) : Chtholly, Seniolis et les Timeres viennent de *SukaSuka* ; le jeu reste un
hommage non commercial tant que la décision de la section 13 n'est pas prise.

## 11. Intégration dans le jeu (pour la session Claude Code qui suivra)

À donner à une session Claude Code une fois les fichiers commités :

> Projet Yume-WordEnd. Intègre les assets 3D livrés selon `docs/ASSETS_3D.md` :
> 1. Écris un script d'import (`EditorScenePostImport`, ou lecture à l'exécution dans
>    `CharacterVisual`) qui applique `<id>.anim.json` aux animations du `.glb` : boucle
>    (`loop_mode`) et métadonnées `ips`, `coup`, `onde` (déjà lues par
>    `src/visuals/character_visual.gd`, variante mesh). Vérifie que
>    `round(durée × ips) == images` pour chaque animation.
> 2. Pour chaque personnage : `data/skins/<id>.tres` → `mesh_scene` = le `.glb` (ou une scène qui
>    l'enveloppe), `sprite_sheet` vidé (le visuel n'utilise le mesh que sans planche), `portrait`,
>    `height_m`. Timere : `data/enemies/visuals/timere.tres`.
> 3. Décors : remplace les maillages de `src/world/props/` par les `.glb` en gardant les
>    collisions sur la couche 1 et le regroupement par `PropBatcher`.
> 4. Terrain (option B ou C) : adapte `src/world/terrain.gd` (`IslandTerrain`) en gardant la
>    structure figée des zones et les repères de la section 7.
> 5. Vérifie : `tools/check.sh` vert, tests de combat M1 (images « coup » des vrais modèles),
>    captures du village, de l'arène et de la forêt, moins de 150 appels de dessin et
>    150 000 triangles, taille du build Web sous le budget.
