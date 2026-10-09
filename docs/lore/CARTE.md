# La carte de l'île n° 68 : chaque lieu, dessiné

Ce document dessine, carte par carte, les lieux de la refonte (`docs/REFONTE.md`, sections 3 et
7.1). Les lots du moteur (E1 à E10) et de la pose le suivent à la lettre : chaque carte a son
`map_id`, sa taille, son plan coté, ses paliers, ses matières, ses bâtiments et grands décors, ses
kits, ses sorties et marqueurs, ses places réservées, ses lumières, ses vues au nord et sa densité.

**Sources.** Les dossiers du canon (`docs/lore/canon/v1_vex.md`, `v2_v3.md`, `v4_v5.md`), cités
comme eux : `(V1, « L'Homme sans Marque »)`. Ce que l'œuvre ne dit pas et que ce document décide
est marqué **(original)** ; ce qu'elle laisse deviner, **(déduction)**. Les noms d'images sont ceux
des images livrées (`assets/hd2d/…`) ou, à défaut, ceux du cahier n° 3
(`docs/ASSETS_HD2D_SUKASUKA.md`) et des cahiers n° 1 et 2 ; un nom qui n'existe dans aucun cahier
est dit **nom proposé** (section 12, à commander). Les documents frères : `docs/lore/ACTE1.md`
(l'acte 1 en jours et en scènes) et `docs/lore/VIE.md` (la vie de l'entrepôt et de l'île) ; ils
renvoient aux **points nommés** de ce document (`entrepot:cour_willem`, `entrepot_rdc:refectoire_allee`…).

## 0. Mode d'emploi

### 0.1 Repères, cotes et données de pose

- **Repères** (contrat `docs/REFONTE.md`, section 7.1, et `PLAN.md`, « (E1) Créer une carte ») :
  origine au coin nord-ouest, x vers l'est, z vers le sud, y vers le haut, 1 unité = 1 m ; la carte
  occupe `[0, largeur] × [0, profondeur]` ; sol courant à y = 0, paliers par pas de 0,5 m.
- **Chaque carte a son bloc « données de pose »** (bloc de code `plan`) : la source des cotes, lue
  par le script de vérification et par les lots de pose. Une instruction par ligne, en mètres :

  | Instruction | Sens |
  | --- | --- |
  | `carte ID L P dedans\|dehors` | début d'une carte : `map_id`, largeur (x), profondeur (z) |
  | `nom "…"`, `region R` | `display_name` et `region` de la `Map` |
  | `sol MATIÈRE x0 z0 x1 z1` | rectangle de sol (dehors) ; le dernier posé l'emporte |
  | `palier Y x0 z0 x1 z1` | rectangle à la hauteur Y ; `rampe x0 z0 x1 z1 Y0 Y1 SENS` : rampe qui va de Y0 à Y1 dans le sens donné |
  | `bati NOM x0 z0 x1 z1 H IMAGE` | volume de bâtiment (`Building`), emprise et hauteur au faîte, façade sud |
  | `decor IMAGE x z l p h [libre] [pp]` | panneau (`DecorPanel`) : centre de l'emprise au sol (x, z), largeur l (est-ouest), profondeur p, hauteur h ; `libre` = sans collision ; `pp` = premier plan, s'efface autour du joueur |
  | `arbre IMAGE x z couronne h [pp]` | arbre : tronc de 1 × 1 m qui bloque, couronne (largeur) et hauteur pour la règle de caméra |
  | `bord TYPE x0 z0 x1 z1 h [pp]` | ce qui ferme la carte (forêt, falaise, rambarde, vide…) : bloque ; h pour la règle de caméra |
  | `eau x0 z0 x1 z1 [profonde]` | eau peinte au ras du sol ; « basse » (on y marche, on s'y mouille) ou profonde (bloque) |
  | `place NOM x0 z0 x1 z1` | place réservée : rien n'y bloque |
  | `chemin NOM l x;z x;z …` | chemin : polyligne et largeur libre de collision |
  | `piece ID x0 z0 x1 z1 SOL MUR "nom"` | pièce (dedans) : rectangle de sol nu, murs sur ses bords |
  | `porte A B x z l IMAGE`, `ouverture A B x z l` | passage sur le mur commun de A et B (`dehors` pour un mur extérieur), centré en (x, z), large de l |
  | `fenetre PIÈCE MUR pos IMAGE l` | fenêtre posée sur le mur N, E, O ou S, centrée à pos (x pour N et S, z pour E et O) |
  | `meuble IMAGE x z l p h [libre]` | meuble : comme `decor` ; `xN` en fin de ligne = rangée de N meubles sur la largeur l |
  | `mural IMAGE PIÈCE MUR pos bas l` | élément de mur (écriteau, horloge, miroir…) : bas à `bas` m du sol |
  | `objet IMAGE x z` | objet posé sur un meuble (sans collision) |
  | `sortie ID x0 z0 x1 z1 CIBLE MARQUEUR "invite"` | `MapExit` : zone, `target_map`, `target_marker`, `prompt` (vide : on passe en marchant) |
  | `marqueur NOM x z REGARD` | `Marker3D` d'arrivée, regard N, S, E ou O |
  | `point NOM x z` | point nommé (scènes, vie, objets à examiner) : doit être atteignable |
  | `lumiere NOM x z h TYPE` | source de lumière (E9) |

- **Meubles** : la largeur l est celle de l'image vue de face, la profondeur p celle de l'objet au
  sol ; un meuble « contre le mur est » a son bord est sur le mur. Un panneau se tourne toujours
  vers le sud (`CLAUDE.md`, pièges HD-2D).
- **Plans ASCII** : dessinés par le script à partir des données, jamais à la main. Dedans, un
  caractère vaut 0,5 × 0,5 m ; dehors, 1 m (est-ouest) × 2 m (nord-sud). Les cotes en mètres sont
  en haut et à gauche. Symboles : `+ - |` murs, `=` porte sur un mur est-ouest, `:` porte sur un
  mur nord-sud, un trou dans un mur = ouverture sans porte, `o` fenêtre, `*` sortie à invite,
  `< > ^ v` sortie à pied au bord, `@` marqueur `Spawn`, `T` tronc d'arbre, `#` bâtiment ou
  rangée de maisons, `^` forêt ou lisière, `&` fourré ou haie, `X` falaise ou roche, `H` rambarde
  ou parapet, `/` toit, `"` jardins clos, `-` muret (dehors), `W` eau profonde.
  Sols dehors : `.` herbe, `'` herbe fleurie, `,` herbe sèche, `:` terre et sentier, `=` potager,
  planches ou tôle, `~` boue, `w` eau basse, `%` tourbe, `;` sous-bois, `_` pavés et dalles.
  Les lettres sont les meubles et décors, légendés sous chaque plan.

### 0.2 Vérification

Les plans sont vérifiés par un script (`build/d2/carte.py`, hors dépôt, lot D2) qui lit les blocs
`plan` de ce document :

- tout est dans la carte ; les pièces ne se chevauchent pas ; chaque porte est posée sur le mur
  commun des deux pièces qu'elle relie (portes alignées) et fait au moins 1,2 m ;
- les meubles sont dans leur pièce, murs compris (mur de 0,25 m), sans chevauchement ; les
  éléments de mur sont sur un mur de leur pièce ;
- dehors, bâtiments et grands décors ne se chevauchent pas ; places et chemins sont libres ; un
  chemin fait au moins 3 m ;
- **passages** : depuis `Spawn`, chaque sortie, marqueur, place et seuil de porte est atteignable
  par un disque de 1,2 m de diamètre dedans, de 3 m dehors ; chaque point nommé par un disque de
  1,2 m ;
- **règle de caméra** (section 0.3) : aucun avertissement restant dans ce document.

Résultat à la dernière relecture : toutes les cartes de ce document passent, sans erreur ni
avertissement.

### 0.3 La règle de caméra, chiffrée

La caméra (`src/player/camera_rig.gd`) regarde le nord, inclinée de 32°, à 21 m du point visé,
lui-même 2,5 m au nord du joueur ; la vue montre environ 10 m de part et d'autre, 7 m au sud et
21 m au nord du point visé (`PLAN.md`, « (E1) Créer une carte »). Un objet de hauteur h cache donc
ce qui se trouve au nord de lui sur environ **1,6 × (h − 0,5) m** (1 / tan 32°). D'où :

- **rien de plus haut que 1,2 m au sud d'un endroit où l'on marche, à moins de cette distance** :
  un bâtiment de 10 m cache 15 m derrière lui ; un arbre de 9 m, 13,6 m ; un fourré de 1,6 m,
  1,8 m ;
- ce qu'on contemple (façades, lisières, falaises, mer de nuages, navires) se pose **au nord** des
  endroits où l'on marche ;
- le bord sud d'une carte et les grands arbres au milieu des passages sont des panneaux de
  **premier plan** (`pp`, `DecorPanel.foreground`), qui s'effacent autour du joueur ;
- derrière un bâtiment (au nord), rien où l'on marche : bois, fourrés, tas de bûches, que la
  caméra ne voit pas ;
- dedans, le mur sud de chaque pièce est coupé (`docs/REFONTE.md`, 7.1 et 8.1). Pour une carte à
  plusieurs pièces, ce document recommande à E3 : **tous les murs est-ouest coupés au ras du
  sol** (`wallcut_*`), sauf le mur nord du bâtiment, haut ; les murs nord-sud entiers. Ce qui doit
  se voir (fenêtres, menus, horloges, calendriers, cheminée) est donc sur le mur nord extérieur ou
  sur un mur est ou ouest ; un meuble haut n'est jamais juste au sud d'un endroit où l'on passe.

### 0.4 Densité visée

D'après `docs/REFONTE.md`, section 2 : **40 à 120 éléments à l'écran** (un écran ≈ 20 × 20 m de
sol), **aucune surface de sol nue de plus de 6 × 6 m** hors des places voulues, **de la vie dans
chaque vue** (un personnage, un animal ou une animation), au moins **deux niveaux de relief** par
carte dehors. Les données de pose ne listent que l'ossature (bâtiments, grands décors, places,
chemins) ; le reste vient des **kits** de chaque carte, posés par bande avec les règles de leur
tableau (écartement, densité au m², distance aux chemins).

## 1. La carte de l'île : le graphe

### 1.1 Ce que dit l'œuvre

- L'île est assez grande, couverte presque entièrement d'une forêt dense, semée de marais de
  toutes tailles ; pas de grande ville, mais de petits villages et une ville d'hommes-bêtes (V1,
  « L'Homme sans Marque » ; VEX, « Cinq cents ans »).
- Au port, un panneau usé aux flèches rouges : le centre-ville à 2 000 marmer « à droite »,
  l'entrepôt n° 4 à 500 marmer dans l'autre direction (V1, « L'Homme sans Marque »).
- De l'entrepôt au port, un sentier étroit à travers la forêt et le marais (V1 ; V2, « Temps
  écoulé depuis lors ») ; de l'entrepôt à la ville, on **descend** un sentier forestier aux pierres
  clairsemées (V3, « Je suis à la maison » ; V5, « La fin imminente »).
- Un village d'hommes-bêtes à quelques pas de l'entrepôt, au bord de l'île (VEX, « Cinq cents
  ans ») ; une petite colline de la périphérie, assez proche pour y monter la nuit (V1, « Le ciel
  étoilé sous le ciel étoilé ») ; l'aire-port à bonne distance, flanqué d'une colline toujours
  ventée (V2, « Les protecteurs du ciel d'azur » ; V3, « La Fille sans visage ») ; une rivière où
  l'on puise l'eau du bain (V3, « Des journées chaudes… ») ; des montagnes où vivent les ours (V2 ;
  V5, « Faire face au passé »).

### 1.2 Le graphe

**Orientation (décision de ce document).** La caméra regarde le nord : ce qu'on contemple au-delà
d'un bord (mer de nuages, navires) doit être au nord de chaque carte. Le croquis de
`docs/REFONTE.md` (section 3.2) met le port au sud de l'entrepôt ; ici, **le port, le village et
la colline des étoiles sont sur la côte nord**, l'entrepôt au cœur de la forêt au sud du village,
la forêt profonde et la montagne plus au sud, la ville au sud-est. Les liaisons du croquis sont
gardées ; seules les directions changent, pour qu'une sortie mène là où pointe la carte de l'île.

```text
                   ~ ~ ~ ~ ~ ~ ~ ~  le vide, la mer de nuages (nord)  ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
   cascade ┌──────────┐      ┌──────────┐               ┌────────────────────┐
   du bord │ VILLAGE  │      │ COLLINE  │               │ PORT, aire-port,   │
           │ café,    │      │ des      │               │ colline ventée     │
           │ Limashenka│     │ étoiles  │               └──┬─────────┬───────┘
           └────┬─────┘      └────┬─────┘                  │passerelle│ route du port
                │ 250              │ 300                ┌──┴───────┐ │ 2 000 marmer
                └──────┐   ┌──────┘                     │ À BORD : │ │
                    ┌──┴───┴───────┐   SENTIER 500      │ transport│ │
                    │  ENTREPÔT    ├────────────────────┤ Garde    │ │
                    │ (dehors) +   │  et marais         │ Barocupot│ │
                    │ rdc, étage,  │       │            └──────────┘ │
                    │ toit, armes  │       │ chemin de la ville      │
                    └──────┬───────┘       │ 1 600, descend          │
                           │ 400           │                         │
                    ┌──────┴───────┐       │    ┌────────────────────┴──┐
                    │ FORÊT        │       └────┤ VILLE HAUTE (rue en   │
                    │ PROFONDE     │            │ pente) ── VILLE MARCHÉ│
                    └──────┬───────┘            │ + 6 intérieurs        │
                           │ 900               └───────────────────────┘
                    ┌──────┴───────┐
                    │ MONTAGNE     │  (au-delà : là où Nygglatho chasse l'ours)
                    └──────────────┘
```

| `map_id` | Lieu, `region` | Taille (m) | Sorties (vers, par) | Distance, marche |
| --- | --- | --- | --- | --- |
| `entrepot` | l'entrepôt, dehors (`entrepot`) | 88 × 60 | `village` (ouest), `colline` (nord-ouest), `sentier` (est), `foret_profonde` (sud), `entrepot_rdc` (porte d'entrée, porte de service) | — |
| `entrepot_rdc` | rez-de-chaussée (`entrepot`) | 32 × 16 | `entrepot` (×2), `entrepot_etage`, `salle_des_armes` | — |
| `entrepot_etage` | étage (`entrepot`) | 32 × 16 | `entrepot_rdc`, `entrepot_toit` | — |
| `entrepot_toit` | le toit (`entrepot`) | 16 × 16 | `entrepot_etage` | — |
| `salle_des_armes` | la crypte (`entrepot`) | 14 × 10 | `entrepot_rdc` | — |
| `village` | le village des hommes-bêtes (`village`) | 56 × 40 | `entrepot` (est), `cafe`, `maison_limashenka` | 250 marmer de l'entrepôt, 4 min |
| `cafe`, `maison_limashenka` | intérieurs (`village`) | 12 × 10, 10 × 8 | `village` | — |
| `colline` | la colline des étoiles (`colline`) | 40 × 40 | `entrepot` (sud) | 300 marmer, 5 min |
| `sentier` | le sentier et le marais (`sentier`) | 80 × 40 | `entrepot` (ouest), `port` (est), `ville_haute` (sud-est) | 500 marmer de l'entrepôt au port, 7 min |
| `port` | le port et l'aire-port (`port`) | 70 × 40 | `sentier` (ouest), `ville_marche` (est), `transport_garde` (passerelle) | — |
| `transport_garde` | à bord, le pont (`port`) | 20 × 11 | `port` | — |
| `barocupot` | à bord, la salle du conseil de guerre (`ciel`) | 14 × 8 | scène : retour sur l'île (`entrepot`, `from_barocupot`) | — |
| `foret_profonde` | la forêt profonde (`foret_profonde`) | 80 × 60 | `entrepot` (nord), `montagne` (est) | 400 marmer, 6 min |
| `montagne` | la montagne aux ours (`montagne`) | 80 × 60 | `foret_profonde` (ouest) | 900 marmer, 13 min |
| `ville_haute` | le centre-ville, haut (`ville`) | 60 × 60 | `sentier` (nord-ouest), `ville_marche` (sud), 4 portes de boutiques | 1 600 marmer par le chemin de la ville, 23 min depuis l'entrepôt |
| `ville_marche` | le centre-ville, place du marché (`ville`) | 56 × 44 | `ville_haute` (nord), `port` (ouest), 2 portes | 2 000 marmer du port, 28 min |
| `ville_snack`, `ville_cafe`, `ville_librairie`, `ville_projection`, `ville_boulangerie`, `ville_horloger` | intérieurs (`ville`) | 9 × 7 à 12 × 10 | leur rue | — |

- **Distances** : on prend **1 marmer ≈ 1 m (original)** et une marche de 1,2 m/s ; la carte de
  l'île affiche la durée indicative (colonne de droite) quand on y choisit un lieu découvert
  (`docs/REFONTE.md`, section 3.1). Les 500 et 2 000 marmer sont ceux du panneau (V1) ; le
  chemin de la ville (1 600) et les autres distances sont **(original)**, dans l'ordre que donnent
  l'œuvre et ses verbes (« à quelques pas », « une bonne distance », « descendre »).
- **Découverte** : au début de l'acte 1, l'entrepôt (dehors et dedans), le sentier et le port sont
  connus (Willem y arrive, Chtholly y court) ; le village, la colline, la ville, la forêt profonde
  et la montagne se découvrent en y allant à pied (ACTE1.md dit quand l'histoire y mène).
- **Ce que la carte de l'île montre** : l'île vue de dessus, la forêt, les marais, la côte nord et
  ses deux saillies (village, colline), le port, la ville en pente au sud-est, la montagne au sud ;
  chaque lieu découvert porte son nom et sa durée de marche depuis le lieu courant.

## 2. L'entrepôt, dehors (`entrepot`)

### 2.1 Ce que dit l'œuvre

- Une clairière défrichée au cœur d'une forêt dense, des marais sombres de toutes formes au-delà
  (VEX, « L'endroit où je veux retourner » ; V2, « De ce côté-ci de l'écran ») ; une forêt
  « assez dense » où l'eau dort dans des creux (V5, épilogue).
- Un bâtiment de bois de deux niveaux, ancien, prévu pour une cinquantaine de personnes (V2), si
  délabré qu'un visiteur le compare à une étable en ruine (V5, « La fin imminente ») ; rien de
  militaire, un dortoir (V1, « L'Homme sans Marque »). Une entrée principale (VEX, « L'homme-chat »)
  et un manteau à la patère près de la porte (V5).
- Juste à côté, un minuscule potager et un parterre bien tenus ; un peu plus loin, un terrain un
  peu trop petit (V2, « De ce côté-ci de l'écran ») ; des pots de fleurs (V5).
- « Le champ dans la forêt », visible de la fenêtre de la salle de lecture : on y joue au ballon,
  rouges contre blancs, avec des cages ; il est bordé d'un bosquet profond et de fourrés où le
  ballon se perd, et devient boueux après la pluie (V1, « Les filles de l'entrepôt » ; « Entrepôt
  de fées » ; V5, « Faire face au passé »).
- La cour en terre où se joue le duel : les pas y marquent, une chute soulève la poussière (V1,
  « Les valeureux et leurs successeurs »).
- La clairière d'entraînement « à l'arrière », à l'abri des regards : herbe, sol meuble, un arbre
  où s'adosser, des bâtons ramassés par terre, un banc, des marais autour où Seniorious finit dans
  la boue (VEX, « Chtholly Nota Seniorious » ; « L'endroit où je veux retourner »).
- Un grand arbre « à côté de l'entrepôt », aux grosses branches, où l'on grimpe malgré l'interdit
  (V5, « La fin imminente ») ; un coin d'herbe au soleil, un gros tronc, un seau (VEX, prologue,
  ill.) ; un banc devant l'entrée (V3, « Des journées chaudes… ») ; le toit à linge (V2).
- Pas un mot de clôture, de puits ni de lampadaire : on n'en pose pas.

### 2.2 Plan

<!-- ascii:entrepot -->
```text
entrepot : 88 × 60 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50        60        70        80
    0 ^^^^^^^^^^^^::^:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      wwwwww;;;;;;::::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^aaaa^^^^aaaa^^^^^^
      wwwwww..............T.....^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^,,,,,,,,,FFFF,,,,,,,,,^^
      wwCCww....................^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^,,,,,,,,,,,,,,,,,,,,VVVV
   10 wwwwww..................UU....^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^,,,,,,,,,,,,,,,,,,,,VVVV
      wwwwww.................SSS.ff.##############################....,,,,,,,,,,,,,,,,,,,,,,^^
      wwwwww.................SSS::::##############################....,,,,,,,,,,,,,,,,,,,,,,^^
      wwwwww....................::::##############################::::,,,,,,,,,,II,,,,,,,,YYY^
      wDDDww....................::::##############################::::,,,,,,,,,,II,,,,,,,,,,^^
   20 wDDDww....................::::*entrepot_ouest####entrepot_e#::::,,,,,,,,,,,,,,,,,,,,,,^^
      wwwwww....................::::##############################::::,,,,,,,,,,,,,,,,,,,,ZZZ^
      wwwEEw.............=====..::::##############################::::,,,,,,,,,,,,,,,,,,,,ZZZ^
      wwwEEw..........eeecccccdd::::RRPPPPPPQQAA*AAPPPPPPPP.......::::,,,,,,,,,,,,,,,,,,,,,,^^
      wwwwww..........eeecccccJ.::::.::::::::AAAAAA:LL:::::::::...::::,,,,,,,,,GGGG,,,,,,,,,^^
   30 ^^..............''''''''''''...::::::::::::::::::::::::::....bbb,,,,,,,,,,,,,,,,,,,,,,^^
      ^^..............''''''''''''...:::::::::::@::::::::::::::....bbb....................;;^^
      ^^..............''''''''''''...::::::::::::::::::::::::::...........................;;^^
      ^^..............''''''''''''...:::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      ::::::::::::::::::::::::::::::::::::::::::::::::::KK:::::::::::::::::::::::::::::::::::>
   40 <:::::::::::::::::::::::::::::::::::::::::::::::::KK:::::...........................;;^^
      ^^................gg...........::::::::::::::::::::::::::...........................;;^^
      wwww%%%%%%%%%%;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::;;;;;YYYY;;;;;;;;;;;;;;;;;;;;^^
      wwwwwww%%%%%%%;;;;;;;;;jj;;;;hh;;;;;;;::::::::;;;;;;;;;ii;;;;;YYYY;;;;;;;;;;;;;;;;;;;;^^
      %%%wwww%MMM%%%;;;;;;;;;;;;;;;NN;;;;;;;::::::::;;;;;ZZ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^
   50 %%%wwww%MMM%%%;;;;;;;;;;;;;;;NN;;;;;;;::::::::;;;;;ZZ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^
      %%%wwwwwww%%%%;;;;;;;;;;;;;;;;;;;;;;;;::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^
      %%%%%%wwww%%%%;;;;;;;;;;;;;;;;;;;;;;;;::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^
      %%%%%%wwww%%T%;;;;;;;;;;;;;;;;;;;;;;;;::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^;::v::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
Légende des lettres : `A` warehouse_porch ; `B` wall_lantern ; `C` reeds ; `D` marsh_snag ; `E` reeds_b ; `F` play_goal ; `G` play_goal_red ; `I` ball ; `J` watering_can ; `K` chalk_hopscotch ; `L` toys_a ; `M` boardwalk ; `N` fern_a ; `P` flower_bed ; `Q` flower_pots ; `R` rain_barrel ; `S` bench_b ; `U` stick_rack ; `V` thicket_c ; `Y` thicket_a ; `Z` thicket_b ; `a` bramble_hedge ; `b` climbing_tree ; `c` vegetable_patch ; `d` garden_tools ; `e` wheelbarrow ; `f` firewood_pile ; `g` stump_axe ; `h` stump_a ; `i` stump_b ; `j` bush_c.
<!-- /ascii:entrepot -->

- **Taille** 88 × 60 m (environ 4,5 × 3 écrans) ; **bornes de caméra** `Rect2(10, 9, 68, 43)` :
  au nord, la lisière et la façade ferment la vue.
- **Le parcours** : on arrive par l'est (sentier du port) ou par la porte ; la cour en terre est au
  centre, devant la façade ; le champ au nord-est, la clairière d'entraînement au nord-ouest, toutes
  deux « derrière » le bâtiment vu de l'entrée, mais décalées sur ses côtés pour que la caméra les
  voie ; le village à l'ouest, la forêt profonde au sud, la colline par la clairière.

### 2.3 Paliers et matières

| Zone | Hauteur | Bords | Sol | Source |
| --- | --- | --- | --- | --- |
| Clairière, cour, abords | 0 | — | herbe (`grass`), terre battue de la cour et des chemins (`path_dirt`, `path_dirt_b`) | V1 (cour en terre) |
| Clairière d'entraînement | +0,5 | talus de terre (`cliff/step_earth`) au sud et à l'est, rampe au sud-est (22 → 26 ; 22 → 25) | herbe drue et molle (`grass_b`), touffes (`moss_patch_a`) | VEX (« sol mou et herbeux ») |
| Champ de ballon | −0,5 | talus au sud et à l'ouest, rampe à l'ouest (62 → 66 ; 16 → 20) | herbe sèche piétinée (`grass_dry`) ; après la pluie, flaques et boue (`mud_patch`, `puddle_a`, E9) | V1 ; V2 ; V5 |
| Lisière nord | +1,0 | talus d'un mètre (`cliff/wall_earth_1m`) face au sud | sous-bois (`forest_floor`) | **(original)** |
| Marais de l'ouest et du sud-ouest | −0,5 | berge de tourbe (`cliff/step_marsh`) | tourbe (`peat`), eau basse au ras du sol | VEX (« des marais l'entourent ») |
| Rivière | −0,5 | berges de galets (`river_bank`) | lit (`stream_bed`), eau basse | V3 (on puise l'eau à la rivière) |
| Bois du sud | 0 → −0,5 au bord | rampe du chemin de la forêt (38 → 46 ; 50 → 56) | sous-bois, feuilles (`leaf_litter`) | **(original)** |
| Coin d'herbe au soleil | 0 | — | herbe fleurie (`meadow_flowers`) | VEX (prologue, ill.) |
| Potager | 0 | — | terre de jardin (`garden_soil`) | V2 |

### 2.4 Le bâtiment

L'œuvre ne décrit ni façade ni toit (dossier V1/VEX, rubrique 2). Ce document fixe un bâtiment qui
tient les pièces de l'œuvre (section 3) : **30 × 14 m, deux niveaux**, posé de x 30 à 60 et de
z 12 à 26, façade sud à z = 26 **(original)**. Deux volumes (`Building`) :

| Volume | Emprise (m) | Hauteur | Toit | Façade sud | Flanc | Matières |
| --- | --- | --- | --- | --- | --- | --- |
| `entrepot_ouest` | x 30 → 48, z 12 → 26 | murs 6,5, faîte 10 | long, ardoise, combles fermés | **`warehouse_front_a`**, 1728 × 624 px (18 × 6,5 m) | **`warehouse_front_a_side`**, pignon 1344 × 960 px (14 × 10 m) | `wall_planks`, `roof_slate` |
| `entrepot_est` | x 48 → 60, z 12 → 26 | murs 6,5 | **toit plat en terrasse** (le toit à linge, carte `entrepot_toit`) bordé de la rambarde basse (`roof_railing`, livrée) ; on voit dépasser les séchoirs (`drying_frame`, livrée) et le linge (`anim/laundry_wave`) | **`warehouse_front_b`**, 1152 × 624 px (12 × 6,5 m) | **`warehouse_front_b_side`**, gouttereau 1344 × 624 px (14 × 6,5 m) | `wall_planks` |

- **Ce que montrent les façades** (à commander, section 12) : bardage de planches brun foncé
  rapiécé sur soubassement de pierre, comme `warehouse_main` (livrée, 16 m) ; au rez-de-chaussée,
  de l'ouest à l'est : deux fenêtres dépolies (salle de bains), une petite (toilettes), un mur
  plein (placard), **la porte d'entrée à deux battants à x = 42** (centre de la pièce `entree`),
  le porche devant, deux fenêtres (salle de jeux), deux fenêtres (infirmerie) ; à l'étage, deux
  fenêtres par dortoir, une petite aux toilettes ; plannings punaisés près de la porte, plaque de
  bronze sans texte (V1). Le flanc ouest montre la porte de service (z = 20) ; le flanc est, la
  fenêtre à banc de la salle de lecture vue de dehors et une échelle de bois contre le mur.
- **En attendant ces images** : `warehouse_main` (16 m) au milieu du volume ouest, le reste en
  matière ; le volume est en `wall_planks` avec `roof_railing` et `drying_frame` posés sur le
  toit.
- **Le toit** : la cheminée de briques (`chimney_brick`) sur le pan sud du volume ouest à x = 38,
  au-dessus de la cheminée de Nygglatho (V2) ; fumée (`anim/chimney_smoke`) le soir et les jours
  froids. Aucune autre fumée : le fourneau de la cuisine est à cristal (V1).
- **Correspondance dehors-dedans** : dedans = dehors − (29, 11) (le bâtiment occupe x 1 → 31,
  z 1 → 15 des cartes `entrepot_rdc` et `entrepot_etage`). La porte d'entrée est en (42 ; 26)
  dehors, (13 ; 15) dedans ; la porte de service en (30 ; 20) dehors, (1 ; 9,5) dedans.
- **Derrière le bâtiment** (z 4 → 12) : rien où l'on marche ; la caméra ne le voit pas
  (`bord arriere`) : bûches, broussailles, souches.

### 2.5 Grands décors

| Décor | Image | Position (m) | Emprise, hauteur | Source |
| --- | --- | --- | --- | --- |
| Porche et banc devant l'entrée | `warehouse_porch` (livrée, 6 m) | (42 ; 27,2) | 6 × 2,4, 3,25 ; sans collision sauf les deux poteaux et le banc | V3 (banc devant l'entrée) |
| Parterres le long de la façade | `flower_bed` (en rangées) | x 32 → 38,5 et 45,5 → 52,5, z ≈ 26,3 | 0,5 de profondeur, 0,4 | V2 |
| Pots de fleurs près de la porte | `flower_pots` | (39,2 ; 27) | 0,7 × 0,5, 0,6 | V5 |
| Tonneau de pluie | `rain_barrel` | (31,2 ; 26,6) | 0,8 × 0,8, 1 | **(original)** |
| Lanterne à cristal de la porte | `wall_lantern` | (40,6 ; 25,9), contre la façade | — | **(original)** : la seule lumière du dehors |
| Grand arbre (escalade interdite) | `climbing_tree` (livré, 8 × 10 m), **premier plan** | tronc en (62,5 ; 32) | tronc 1,2 m ; couronne 8 m, 10 m | V5, « La fin imminente » |
| Potager minuscule | `vegetable_patch` ×3 | (21,5 ; 26,4 / 27,6 / 28,8) | 5 × 0,8 chacun | V2 |
| Outils, brouette, arrosoir | `garden_tools`, `wheelbarrow`, `watering_can` | (25,2 ; 26,6), (17,4 ; 27,8), (24,6 ; 29,6) | — | **(original)** |
| Tas de bûches (cheminée de Nygglatho) | `firewood_pile` | (28 ; 12,8) | 2 × 0,8, 1,2 | V2 (la cheminée) |
| Arbre de la clairière, où s'adosser | `oak_a` | tronc en (20 ; 6,5) | couronne 7 m, 9 m | VEX |
| Banc de la clairière | `bench_b` | (24,6 ; 14) | 1,6 × 0,5 | VEX |
| Râtelier de bâtons | `stick_rack` | (24,6 ; 11,6) | 1,2 × 0,4 | VEX (bâtons ramassés : le râtelier est **original**) |
| Cages du champ | `play_goal` (blancs, au nord), `play_goal_red` (rouges, au sud, premier plan) | (75 ; 7,2) et (75 ; 28,8) | 3 × 0,6, 2 ; sans collision sauf les poteaux | V1 |
| Fourrés du champ (le ballon s'y perd) | `thicket_c` (trou au ras du sol), `thicket_a`, `thicket_b` | (85,6 ; 10 / 17 / 24) | 1,4 à 1,8 | V1, « Entrepôt de fées » |
| Haie de ronces au nord du champ | `bramble_hedge` ×2 | (72 ; 5,6), (80 ; 5,6) | 4 × 0,6, 1,5 | V1 |
| Souches des arbres abattus | `stump_axe`, `stump_a`, `stump_b` | (19 ; 43,4), (30 ; 47), (56 ; 47) | — | VEX (« arbres abattus ») |
| Marais de la clairière | `reeds`, `reeds_b`, `marsh_snag` | (3 ; 9), (4 ; 26), (2,5 ; 20) | sans collision | VEX |
| Puisage de la rivière | `boardwalk` (décalque) | (9,5 ; 49,5) | 2 × 1,5 | V3 |
| Aulne du marais du sud-ouest | `alder` | tronc en (12 ; 55) | couronne 4 m, 7 m | **(original)** |
| Craie de marelle dans la cour | `chalk_hopscotch` (décalque) | (51 ; 40) | 2 × 3 | **(original)** |
| Jouets qui traînent | `toys_a` | (47,2 ; 29,2) | — | V2 (l'esprit des lieux) |

### 2.6 Kits par bande

| Bande | Où | Images (livrées ou du cahier) | Règles de pose |
| --- | --- | --- | --- |
| **Lisière nord** | z 0 → 5, et derrière le bâtiment | `forest_wall_a` à `_d`, `treeline_autumn_a/b`, `oak_*`, `beech_*`, `tree_old_pine`, `fern_*`, `bush_*` | lisières de 16 m sur toute la largeur, deux rangs d'arbres devant, décalés ; un arbre tous les 3 à 5 m ; fougères au pied du talus |
| **Abords du bâtiment** | 1 à 3 m autour des murs | `flower_bed`, `flower_pots`, `drainpipe`, `ivy_wall_a/b`, `window_box`, `broom_bucket`, `bucket`, `laundry_basket` | rien de plus haut que 1,2 m devant la façade ; une gouttière à chaque angle ; lierre sur le flanc ouest |
| **Cour en terre** | `place cour` | `chalk_drawings`, `chalk_hopscotch`, `footprints`, `pebbles_a/b`, `toys_a/b`, `ball` | décalques seulement dans la place du duel (`place duel` reste nue) ; au plus un jouet par 20 m² |
| **Bord de chemin** | 1,5 à 3 m de chaque côté des chemins | `grass_clump_*`, `tall_grass`, `wildflowers_a/b`, `fern_*`, `stump_*`, `rock_small_*`, `grass_edge_a/b` | jamais dans la bande libre du chemin ; une touffe tous les 1 à 2 m ; pierres plates au sentier (`stepping_stones`) |
| **Champ** | `place champ` et ses bords | `grass_dry`, `mud_patch`, `puddle_a/b`, `footprints` ; bords : `thicket_*`, `bramble_hedge`, `bush_*`, `berry_bush` | la place reste nue (on y court) ; après la pluie, 6 à 10 flaques ; fourrés serrés à l'est et au nord, rien de haut au sud |
| **Clairière d'entraînement** | `place clairiere` et ses bords | `moss_patch_a/b`, `clover_patch`, `wildflowers_*`, `branches_a/b` (bâtons au sol) | la place reste nue ; quelques bâtons au sol près du râtelier |
| **Marais** | x 0 → 6 et sud-ouest | `reeds`, `reeds_b`, `cattails`, `lily_pads`, `mist_patch`, `marsh_hummock_*`, `alder`, `willow` | eau basse : on y marche, éclaboussures ; roseaux en touffes de 1,5 m tous les 2 m ; brume le matin |
| **Bois du sud** | z 44 → 60 | `bush_*`, `fern_*`, `sapling_a/b`, `log_hollow`, `mushroom_*`, `leaves_*` ; au bord sud, `fg_trunk_a/b`, `fg_bush`, `fg_fern` en **premier plan** | rien de plus haut que 3 m à moins de 5 m au sud d'un chemin ; les grands troncs seulement en premier plan au bord |

### 2.7 Sorties et marqueurs

| Sortie | Zone (m) | Cible, marqueur d'arrivée | Invite |
| --- | --- | --- | --- |
| `vers_village` | x 0 → 0,6, z 38 → 42 | `village`, `from_entrepot` | à pied |
| `vers_colline` | x 12 → 16, z 0 → 0,6 | `colline`, `from_entrepot` | à pied |
| `vers_sentier` | x 87,4 → 88, z 36 → 40 | `sentier`, `from_entrepot` | à pied |
| `vers_foret` | x 37 → 43, z 59,4 → 60 | `foret_profonde`, `from_entrepot` | à pied |
| `porte_entree` | x 41 → 43, z 25,4 → 26 | `entrepot_rdc`, `from_entrepot` | « Entrer » |
| `porte_service` | x 29,4 → 30, z 19,4 → 20,6 | `entrepot_rdc`, `from_entrepot_service` | « Entrer » |

Marqueurs : `Spawn` (42 ; 33) N ; `from_village` (2,5 ; 40) E ; `from_colline` (14 ; 2,5) S ;
`from_sentier` (85,5 ; 38) O ; `from_foret_profonde` (40,5 ; 57,5) N ; `from_entrepot_rdc`
(42 ; 29) S ; `from_entrepot_rdc_service` (28,2 ; 20) O ; `from_barocupot` (47 ; 37) N (retour en
volant, ACTE1.md jour 8).

### 2.8 Places réservées et points nommés

- **`cour`** (32 → 56, 30 → 44) et **`duel`** (36 → 48, 31 → 43) : la cour en terre du duel (V1),
  12 × 12 m nus ; Willem en `cour_willem`, Chtholly en `cour_chtholly`.
- **`champ`** (66 → 84, 8 → 28) : 18 × 20 m pour le ballon, cages au nord et au sud (V1).
- **`clairiere`** (7 → 23, 8 → 23) : l'entraînement au bâton et avec Seniorious (VEX).
- **`coin_soleil`** (17 → 27, 31 → 36) : l'herbe au soleil (VEX, prologue).
- Points : `porche_banc`, `porte_seuil`, `cour_willem`, `cour_chtholly`, `cour_centre`,
  `arbre_pied`, `arbre_vigie` (au pied, pour la petite tout en haut), `potager`, `coin_soleil`,
  `clairiere_centre`, `clairiere_banc`, `clairiere_arbre`, `marais_epee` (là où tombe
  Seniorious), `champ_centre`, `champ_but_nord`, `champ_but_sud`, `fourre_ballon`,
  `riviere_puisage`, `lisiere_sud`.

### 2.9 Lumières

- **Jour** : préréglage du moment (E9) ; taches de soleil sous les arbres (`sun_dapple`,
  `canopy_shadow_*`).
- **Nuit** : les fenêtres de la façade s'allument (vitres éclairées, lot N) selon qui veille
  (VIE.md : la lumière sous la porte de Nygglatho, la salle de lecture, les archives) ; la lanterne
  à cristal de la porte (**original**). **Aucun lampadaire** (V1 : pas une lumière sur le sentier).
  Les fées portent une petite lumière magique dans la main (`anim/fairy_light`, V1).

### 2.10 Points de vue au nord

- Depuis la cour : la façade, le porche, les séchoirs qui dépassent du toit-terrasse, la cheminée
  qui fume, et derrière, la lisière d'or et de rouille (la vue de l'entrée).
- Depuis la clairière : l'arbre où s'adosser et la forêt noire ; à l'ouest, le marais.
- Depuis le champ : la haie de ronces, le bosquet profond du nord-est où le ballon se perd.

### 2.11 Densité visée

70 à 110 éléments par écran dans la cour et autour du bâtiment, 40 à 60 dans le champ et la
clairière (places nues voulues, bords pleins), 90 à 120 dans les bois et marais. Aucune surface nue
de plus de 6 × 6 m hors des quatre places. De la vie partout : les petites (VIE.md), des
papillons orange au champ (`anim/butterfly`, VEX, ill.), des oiseaux qui s'envolent
(`anim/birds_flock`), des feuilles qui tombent (`anim/falling_leaf_*`).

### 2.12 Données de pose

```plan
carte entrepot 88 60 dehors
nom "L'entrepôt des fées"
region entrepot
# --- sol (le dernier posé l'emporte) ---
sol grass 0 0 88 60
sol forest_floor 0 0 88 6
sol forest_floor 0 44 88 60
sol forest_floor 84 6 88 44
sol grass_b 6 6 26 24
sol grass_dry 64 6 86 31
sol meadow_flowers 16 30 28 37
sol garden_soil 19 25.5 24 29.5
sol path_dirt 31 28 57 45
sol path_dirt 26 14 30 30
sol path_dirt 60 16 64 30
sol path_dirt_b 0 38 31 42
sol path_dirt_b 57 36 88 40
sol path_dirt_b 38 45 46 60
sol path_dirt_b 12 0 16 6
sol peat 0 4 6 30
sol peat 0 44 14 60
sol stream_bed 6 52 10 60
sol stream_bed 3 47 7 53
sol stream_bed 0 44 4 48
# --- paliers et rampes ---
palier 1.0 0 0 88 5
palier 0.5 6 6 26 24
palier -0.5 64 5 88 31
palier -0.5 0 4 6 30
palier -0.5 0 44 14 60
palier -0.5 30 56 60 60
rampe 22 22 26 25 0.5 0 S
rampe 62 16 66 20 0 -0.5 E
rampe 38 50 46 56 0 -0.5 S
rampe 12 4 16 7 1.0 0.5 S
# --- bâtiment (façade sud à z = 26) ---
bati entrepot_ouest 30 12 48 26 10 warehouse_front_a
bati entrepot_est 48 12 60 26 7.2 warehouse_front_b
decor warehouse_porch 42 27.2 6 2.4 3.25 libre
decor flower_bed 35.25 26.3 6.5 0.5 0.4
decor flower_bed 49 26.3 7 0.5 0.4
decor flower_pots 39.2 27.0 0.7 0.5 0.6
decor rain_barrel 31.2 26.6 0.8 0.8 1.0
decor wall_lantern 40.6 25.9 0.4 0.2 0.6 libre
# --- bords (ce qui bloque) ---
bord foret 0 0 12 4 11
bord foret 16 0 88 5 11
bord arriere 30 4 60 12 4
bord foret 26 4 30 10 6
bord foret 60 5 64 12 6
bord bosquet 86 5 88 36 9
bord foret 86 40 88 60 9 pp
bord foret 0 30 2 38 8
bord foret 0 42 2 44 8 pp
bord foret 0 58 37 60 9 pp
bord foret 43 58 88 60 9 pp
# --- clairière d'entraînement (VEX) ---
place clairiere 7 8 23 23
arbre oak_a 20 6.5 7 9
decor bench_b 24.6 14 1.6 0.5 1.1
decor stick_rack 24.6 11.6 1.2 0.4 1.2
eau 0 4 6 30
decor reeds 3 9 1.5 1.5 1.4 libre
decor marsh_snag 2.5 20 2 2 2 libre
decor reeds_b 4 26 1.5 1.5 1.4 libre
# --- champ de ballon (V1 ; V2 ; V5) ---
place champ 66 8 84 28
decor play_goal 75 7.2 3 0.6 2 libre
decor play_goal_red 75 28.8 3 0.6 2 libre pp
decor thicket_c 85.6 10 3 1.2 1.8
decor thicket_a 85.6 17 2.5 1 1.6
decor thicket_b 85.6 24 2 1 1.4
decor bramble_hedge 72 5.6 4 0.6 1.5
decor bramble_hedge 80 5.6 4 0.6 1.5
decor ball 75 18 0.3 0.3 0.3 libre
# --- cour en terre, porche, abords (V1 ; V2 ; V3 ; V5) ---
place cour 32 30 56 44
place duel 36 31 48 43
decor climbing_tree 62.5 32 1.2 1.2 10 pp
place coin_soleil 17 31 27 36
decor vegetable_patch 21.5 26.4 5 0.8 0.6
decor vegetable_patch 21.5 27.6 5 0.8 0.6
decor vegetable_patch 21.5 28.8 5 0.8 0.6
decor garden_tools 25.2 26.6 0.9 0.5 1.4
decor wheelbarrow 17.4 27.8 1.4 0.7 0.8
decor watering_can 24.6 29.6 0.4 0.3 0.4 libre
decor firewood_pile 28 12.8 2 0.8 1.2
decor chalk_hopscotch 51 40 2 3 0 libre
decor toys_a 47.2 29.2 1.2 0.6 0.5 libre
decor stump_axe 19 43.4 0.9 0.8 0.7
decor stump_a 30 47 0.8 0.8 0.5
decor stump_b 56 47 0.8 0.8 0.5
# --- bois du sud, rivière, marais du sud-ouest ---
eau 6 52 10 60
eau 3 47 7 53
eau 0 44 4 48
decor boardwalk 9.5 49.5 2 1.5 0.2 libre
arbre alder 12 55 4 7
decor fern_a 30 50 1 0.8 0.8 libre
decor thicket_b 52 50 2 1 1.4
decor thicket_a 64 46 2.5 1 1.6
decor bush_c 24 47 1.5 1 1.2
# --- chemins (bande libre de 3 m au moins) ---
chemin vers_village 3.5 31;39 20;40 1;40
chemin vers_clairiere 3 32;29.5 28;28 27.6;22 24;19
chemin vers_colline 3 14;10 14;1
chemin vers_champ 3 57;29.5 62;27 62;21 66.5;18.5
chemin vers_sentier 3.5 56;38 70;38 87;38
chemin vers_foret 3.5 44;44 44;52 40;59
# --- sorties ---
sortie vers_village 0 38 0.6 42 village from_entrepot ""
sortie vers_colline 12 0 16 0.6 colline from_entrepot ""
sortie vers_sentier 87.4 36 88 40 sentier from_entrepot ""
sortie vers_foret 37 59.4 43 60 foret_profonde from_entrepot ""
sortie porte_entree 41 25.4 43 26 entrepot_rdc from_entrepot "Entrer"
sortie porte_service 29.4 19.4 30 20.6 entrepot_rdc from_entrepot_service "Entrer"
# --- marqueurs ---
marqueur Spawn 42 33 N
marqueur from_village 2.5 40 E
marqueur from_colline 14 2.5 S
marqueur from_sentier 85.5 38 O
marqueur from_foret_profonde 40.5 57.5 N
marqueur from_entrepot_rdc 42 29 S
marqueur from_entrepot_rdc_service 28.2 20 O
marqueur from_barocupot 47 37 N
# --- points nommés (scènes, vie) ---
point porche_banc 44.2 28.8
point porte_seuil 42 28.2
point cour_willem 42 35
point cour_chtholly 42 40.5
point cour_centre 44 37
point arbre_pied 62.5 34.2
point arbre_vigie 62.5 33.4
point potager 21.5 30.3
point coin_soleil 22 33.5
point clairiere_centre 15 15
point clairiere_banc 24.6 15.1
point clairiere_arbre 20 8.4
point marais_epee 3 12
point champ_centre 75 18
point champ_but_nord 75 9.2
point champ_but_sud 75 26.6
point fourre_ballon 83.3 10
point riviere_puisage 9.5 48
point lisiere_sud 44 50
lumiere lanterne_porte 40.6 25.9 2.0 cristal
lumiere fenetres_facade 45 26 3.0 fenetres
```

## 3. L'entrepôt, dedans

### 3.0 Principes

- **Deux étages par carte** (`entrepot_rdc`, `entrepot_etage`), plus le toit (`entrepot_toit`,
  dehors) et la crypte (`salle_des_armes`) ; même cadre (32 × 16 m) pour les deux étages : le
  bâtiment de 30 × 14 m y occupe x 1 → 31, z 1 → 15.
- **Trois bandes** : au nord, les pièces à voir (7,5 m de profondeur, mur nord haut avec fenêtres) ;
  au milieu, le **couloir** de 2 m qui court d'un pignon à l'autre (V1 : « nombreuses petites
  pièces disposées régulièrement ») ; au sud, contre la façade, des pièces de 4,5 m (mur sud coupé).
- **Aucun escalier n'est décrit** (V1 ; V2) : celui-ci est **original** : droit, contre le mur
  ouest de la cage, il monte vers le nord ; on arrive à l'étage sur un palier au nord de la trémie.
- **L'entrepôt n'a sans doute pas l'eau courante** (V3, « Des journées chaudes… ») : tonneau d'eau,
  seaux, évier sans robinet, auge du couloir.
- **Hauteur sous plafond** 3 m ; murs de 0,25 m ; portes de 1,2 m d'ouverture (le panneau
  `door_room`, 1,1 m, se pose au milieu ; E3 habille le jeu d'un chambranle).
- **Objets à examiner** : les tableaux de chaque pièce disent ce que montre l'invite « Regarder » ;
  les textes définitifs sont à écrire (paraphrase, jamais l'œuvre), dans `data/texts/`.

### 3.1 Rez-de-chaussée (`entrepot_rdc`)

<!-- ascii:entrepot_rdc -->
```text
entrepot_rdc : 32 × 16 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10        15        20        25        30
    0 
      
        +---o----+----------o----------+-------+-=-+-----o-+--------+
        |GGG.IIII|NNNNréfectoire...PPPP|escalie|a*m|YYYY...|gggfffff|
    2   |cuisine.|.....................|.......|...|bb..ZZZ|lecture.|
        |........|...QQQQQQQQQQQQQQ....|VVV....|...|bb..ZZZ|........|
        |........|..RRRRRRRRSSSSSSSS...|VVV....|...|archive|........|
        |.KKKKK..|..RRRRRRRRSSSSSSSS...|VVV....|...|aaa....|.jjjj...|
    4   |.KKKKK..:..RUUUUUUUUUUUUUUS...|VVV....|...|aaa.ccc|.jjjj...|
        |.KKKKK..:...UUUUUUUUUUUUUU....|VVV....|...|.BBBcee|hjjjj...|
        |........:.....................|VVV....|...|.BBBBee|hhh.....o
        |JJ......|.....................|.......|...|.BBBBB.|........|
    6   |JJ......|...QQQQQQQQQQQQQQ....|.*.....|...|ddddBB.|iii.....|
        |LL......|..SSSSSSSSRRRRRRRR...|.......|...|dddd...|iii..kkk|
        |LL...MMM|..SSSSSSSSRRRRRRRR...|.......|...|.......|.....kkk|
        |.....MMM|..SUUUUUUUUUUUUUUR...|.......|...|.......|m....kkk|
    8   |.....MMM|...UUUUUUUUUUUUUU....|.......|...|.......|m.......|
        +----=---+==-----------------==             --==---+--==----+
        :.CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC..nnnn|
      < :.CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC......o
   10   :couloir....................................................|
        +---------=-+-=-+-=-         -------=-------+-=-------------+
        |pppppbains.|wc.|pl.|entrée.|xxxEEEEEEEEEyyy|...55556555566.|
        |ppppp......|...|...|.......|xxxEEEEEEEEE...|..77555.55555..|
   12   |..DDDDD....|...|...|....vvv|.F.EEEEEEEEE...|..77infirmerie.o
        |..DDDDD....|...|.uu|.......|...EEE111EEEzzz|...............|
        |..DDDDD....|...|.uu|...@...|..22EE111EEEzzz|............888|
        |rrDDDDD.qqq|...|...|.......|..22EEEEEEEE...|???.5555....888|
   14   |rr...ss.qqq|...|tt.|.......|...444EEE333...|???.5555...99..|
        |.....ss....|...|tt.|.......|...444...333...|???.5555...99..|
        +-----------+---+---+--===--+---------------+---------------+
                                v
```
Légende des lettres : `1` game_table ; `2` plush_blue ; `3` plush_pile ; `4` floor_cushions ; `5` bed_iron ; `6` bedside_table ; `7` chair_child ; `8` medicine_cabinet ; `9` washbasin_stand ; `?` infirmary_desk ; `A` crystal_pendant ; `B` papers_floor ; `C` runner_rug ; `D` bath_puddles ; `E` rug_playroom ; `F` ball_white ; `G` crystal_stove ; `I` kitchen_counter ; `J` pantry_cupboard ; `K` kitchen_table_ingredients ; `L` water_tub ; `M` sacks_vegetables ; `N` china_cabinet ; `P` sink_stone ; `Q` chair_wood ; `R` dining_table_set ; `S` dining_table_long ; `U` chair_wood_back ; `V` stairs_up ; `Y` archive_shelves ; `Z` paper_pile_a ; `a` desk_buried ; `b` paper_pile_b ; `c` filing_cabinet ; `d` sofa_beige ; `e` paper_pile_c ; `f` window_reading_seat ; `g` bookshelf_tall ; `h` bookshelf_low ; `i` bookshelf_tall_b ; `j` reading_table ; `k` armchair_reading ; `m` book_pile ; `n` washstand_corridor ; `p` bath_tub ; `q` towel_shelf ; `r` wash_tub ; `s` hamper ; `t` supply_cupboard ; `u` cleaning_set ; `v` shoe_rack ; `x` piano_old ; `y` toy_chest ; `z` board_games_shelf.
<!-- /ascii:entrepot_rdc -->

**Bornes de caméra** `Rect2(8, 4, 16, 6)` (le point visé reste dans le bâtiment ; la vue entière
tient en deux écrans). **Lumière** : préréglage `interieur` (E9), lueur chaude des cristaux.

| Pièce | Cotes (m) | Ce que dit l'œuvre | Portes et fenêtres | Mobilier (images) | À examiner |
| --- | --- | --- | --- | --- | --- |
| **Cuisine** | 4,5 × 7,5 (x 1 → 5,5) | seule la cuisinière du jour y entre ; fourneau de cristal, comptoir, tablier ; œufs, sucre, lait, crème, baies ; marmite et louche (V1, « Directeur en carton » ; V3) | porte au couloir (3,4) ; porte au réfectoire, mur est (z 4,6) ; petite fenêtre au nord | `crystal_stove`, `kitchen_counter`, `kitchen_table_ingredients`, `water_tub`, `pantry_cupboard`, `sacks_vegetables` ; murs : `wallitem_utensils`, `wallitem_spice_shelf` (le pot de moutarde à l'étiquette d'enfant, VEX), `wallitem_apron_hook` ; vapeur `anim/pot_steam` | le fourneau (« un gros cristal ambré chauffe sous la fonte ») ; le pot de moutarde ; le tablier |
| **Réfectoire** | 11 × 7,5 | tout le monde y mange ; grande fenêtre ; vaisselier vitré ; évier où l'on rapporte sa tasse ; menu et ligne « dessert du jour » ; marques de taille ; prière, fourchettes levées ensemble (V1 ; V3 ; V4 ; V5 ; VEX, ill.) | portes au couloir aux deux bouts (6,3 et 15,75) ; porte à la cuisine ; grande fenêtre au nord (x = 11) | deux rangées de deux tables (`dining_table_set`, `dining_table_long`), chaises au nord (`chair_wood`) et au sud (`chair_wood_back`, dos à la caméra) : 28 places ; `china_cabinet` (nord-ouest), `sink_stone` (nord-est), deux suspensions `crystal_pendant` ; murs : `wallitem_menu_board` (x 8,8), `wallitem_height_marks` (x 13,4), applique ; sur les tables `meal_lunch`, `tableware_a`, `dessert_flans` (jour 4) | le menu (« la ligne du bas, ajoutée à la craie, attend son dessert ») ; les marques de taille ; le vaisselier ; la fenêtre la nuit |
| **Cage d'escalier** | 4 × 7,5 | (original) | ouverte sur le couloir sur 4 m | `stairs_up` contre le mur ouest (x 16,7 → 18,3, z 2,5 → 5,5) ; murs : `wallitem_chore_chart` (nord, x 19,4 : les **plannings de corvées**, V1), `wallitem_notice_b` (« on ne court pas dans les couloirs », V1), `wallitem_notices_mix`, applique | le planning des corvées (qui fait la cuisine aujourd'hui, VIE.md) ; l'écriteau |
| **Palier des armes** | 2 × 7,5 | la grande porte de métal rivetée à cinq serrures, seul élément militaire (V1, « Entrepôt de fées ») | ouvert sur le couloir ; **porte rivetée au mur nord** (x 21,5, 1,3 m) | `door_armory` ; murs : `wallitem_bronze_plaque` (celle de la « salle de stockage », à côté de la porte des archives, V1), applique | la porte (« cinq serrures ; Nygglatho garde la clé ») |
| **Archives** (« salle de stockage ») | 4 × 7,5 | plaque de bronze ; un océan de papiers ; un bureau et une chaise sous les piles ; horloge murale dont on entend la trotteuse ; canapé beige à trois places ; personne n'y vient, on s'y cache pour couper aux corvées (V1, « Les valeureux… » ; V3) | porte au couloir (24,2) ; petite fenêtre haute et poussiéreuse au nord | `archive_shelves`, `paper_pile_a/b/c`, `desk_buried`, `filing_cabinet`, `sofa_beige` ; décalque `papers_floor` ; murs : `wallitem_wall_clock` (ouest), `wallitem_clippings` (est) ; `coffee_tray` (la nuit des archives) | l'horloge ; une coupure de magazine pour filles ; un rapport de patrouille de nuit ; le bon de commande de carottes (V1) |
| **Salle de lecture** | 4,5 × 7,5 | silence imposé (papier roulé de Nephren) ; un siège près du rebord de la fenêtre, avec vue sur le champ, où tout le monde s'agglutine (V1, « Les filles de l'entrepôt ») ; tables, étagères de gros livres (V2 ; V4) | porte au couloir (28,3) ; **fenêtre à banc au nord** (x 29,6), petite fenêtre à l'est (le champ est au nord-est) | `window_reading_seat`, `bookshelf_tall`, `bookshelf_tall_b`, `bookshelf_low` (livres d'images des petites), `reading_table` et sa lampe, `armchair_reading`, `book_pile` | la fenêtre (le champ, les petites au ballon) ; le livre d'images sur les emnetwiht, sur l'étagère basse (lu à la salle de jeux, ACTE1.md 6.2) |
| **Couloir** | 30 × 2 | parquet usé, murs plâtrés, papiers punaisés ; on y épie, on y court (V1) ; le point d'eau froide de la toilette du matin (VEX, « L'homme-chat » ; emplacement **déduit**) | porte de service au pignon ouest (z 9,5) ; fenêtre au pignon est | tapis de couloir `runner_rug` (tourné de 90°) ; au bout est, `washstand_corridor` (auge, cuvettes, brosses à dents) | l'auge et l'eau glacée |
| **Salle de bains** | 6 × 4,5 | bain bien chaud ; grand miroir installé par Nygglatho ; règlement du bain ; séchage des cheveux (V1 ; V3 ; V4) | porte au couloir (6,0) | `bath_tub`, `wash_tub`, `towel_shelf`, `hamper` ; décalque `bath_puddles` ; murs : `mirror_large` (ouest), `wallitem_bath_rules` (est) ; vapeur `anim/bath_steam` | le règlement (« trois lignes ajoutées d'une autre encre », V4 : clin d'œil permis, il ne révèle rien) ; le miroir |
| **Toilettes** | 2 × 4,5 | (V1 : il y en a à chaque étage) | porte au couloir (8,0) | — | — |
| **Placard du bas** | 2 × 4,5 | le marteau « dans le placard en bas » (V2 ; V3) | porte au couloir (10,0) | `supply_cupboard`, `cleaning_set` | le marteau |
| **Entrée** | 4 × 4,5 | l'entrée principale (VEX) ; manteau à la patère (V5) ; pantoufles (V3) | porte d'entrée au sud (x 13, 2 m, mur coupé : on sort en marchant) ; ouverte sur le couloir | `shoe_rack` ; murs : `wallitem_coat_hooks` (ouest), `wallitem_frame_landscape` (est) | les patères (le manteau de Nygglatho, le pardessus de Willem) |
| **Salle de jeux** (« salle de loisirs ») | 8 × 4,5 | tapis, peluches ; Collon et sa peluche bleue, Pannibal et la balle contre le mur, Tiat sur le tapis (V2) ; jeux de société, pile de petites sur Willem (VEX) ; le vieux piano (V4) | porte au couloir (19,0) | `rug_playroom`, `piano_old`, `toy_chest`, `board_games_shelf`, `game_table`, `plush_blue`, `plush_pile`, `floor_cushions`, `ball_white` ; mur : `wallitem_kids_drawings` (ouest) | la partie en cours ; le piano (fermé à l'acte 1) |
| **Infirmerie** | 8 × 4,5 | des lits, une petite chaise au chevet, bandages, serviette humide, couverture ; blouse ; rideaux et fenêtre, vase, calendrier dont on tourne la feuille chaque matin, bureau (V1 ; V3) | porte au couloir (24,0) ; fenêtre à rideaux à l'est | trois `bed_iron`, deux `bedside_table` (vase `vase_flowers`), `chair_child` au chevet, `medicine_cabinet`, `washbasin_stand`, `infirmary_desk` ; murs : `wallitem_day_calendar` (est), `wallitem_labcoat` (ouest) | le calendrier du jour ; la trousse de premiers secours |

**Points nommés** : `cuisine_fourneau`, `cuisine_table`, `cuisine_tonneau`, `refectoire_vaisselier`,
`refectoire_evier`, `refectoire_fenetre`, `refectoire_allee` (entre les deux rangées),
`refectoire_bout_est`, `refectoire_bout_ouest`, `refectoire_porte_cuisine` (là où l'on épie),
`escalier_pied`, `planning`, `porte_armes`, `archives_bureau`, `archives_canape`,
`lecture_banquette`, `lecture_table`, `couloir_ouest`, `couloir_centre`, `couloir_est`,
`point_eau`, `bains_baignoire`, `entree`, `jeux_tapis`, `jeux_mur_balle`, `infirmerie_lit_a`,
`infirmerie_fenetre`, `infirmerie_bureau`.

```plan
carte entrepot_rdc 32 16 dedans
nom "L'entrepôt — rez-de-chaussée"
region entrepot
# bâtiment : x 1 → 31, z 1 → 15 (= dehors x 30 → 60, z 12 → 26 ; dehors = dedans + (29, 11))
# --- pièces : bande nord (mur nord haut, fenêtres visibles), couloir, bande sud ---
piece cuisine 1 1 5.5 8.5 floor_kitchen_tiles wall_kitchen_tiles "cuisine"
piece refectoire 5.5 1 16.5 8.5 floor_planks_worn wall_wainscot "réfectoire"
piece escalier 16.5 1 20.5 8.5 floor_planks_worn wall_plaster_worn "escalier"
piece palier_armes 20.5 1 22.5 8.5 floor_planks_worn wall_plaster_worn "armes"
piece archives 22.5 1 26.5 8.5 floor_planks_worn wall_plaster_worn "archives"
piece lecture 26.5 1 31 8.5 floor_planks_worn wall_wainscot "lecture"
piece couloir 1 8.5 31 10.5 floor_planks_worn wall_plaster_worn "couloir"
piece bains 1 10.5 7 15 floor_tiles_bath wall_plaster_worn "bains"
piece toilettes 7 10.5 9 15 floor_tiles_bath wall_plaster_worn "wc"
piece placard 9 10.5 11 15 floor_planks_worn wall_plaster_worn "pl."
piece entree 11 10.5 15 15 floor_planks_worn wall_wainscot "entrée"
piece jeux 15 10.5 23 15 floor_planks_worn wall_wainscot "salle de jeux"
piece infirmerie 23 10.5 31 15 floor_planks_worn wall_plaster_worn "infirmerie"
# --- portes et ouvertures ---
porte cuisine couloir 3.4 8.5 1.2 door_room
porte refectoire cuisine 5.5 4.6 1.2 door_room
porte refectoire couloir 6.3 8.5 1.2 door_room
porte refectoire couloir 15.75 8.5 1.2 door_room
ouverture escalier couloir 18.5 8.5 4
ouverture palier_armes couloir 21.5 8.5 2
porte archives couloir 24.2 8.5 1.2 door_room
porte lecture couloir 28.3 8.5 1.2 door_room
porte bains couloir 6.0 10.5 1.2 door_room
porte toilettes couloir 8.0 10.5 1.2 door_room
porte placard couloir 10.0 10.5 1.2 door_room
ouverture entree couloir 13 10.5 4
porte jeux couloir 19.0 10.5 1.2 door_room
porte infirmerie couloir 24.0 10.5 1.2 door_room
porte entree dehors 13 15 2.0 door_double
porte couloir dehors 1 9.5 1.2 door_service
porte palier_armes dehors 21.5 1 1.3 door_armory
# --- cuisine (V1, « Directeur en carton » ; V3) ---
fenetre cuisine N 3.2 window_cross_small 0.8
meuble crystal_stove 2.0 1.5 1.4 0.7 1.2
meuble kitchen_counter 4.4 1.5 1.8 0.7 1.05
mural wallitem_utensils cuisine N 4.4 1.4 1.2
mural wallitem_spice_shelf cuisine O 3.0 1.5 1.2
mural wallitem_apron_hook cuisine O 5.6 0.9 0.4
meuble pantry_cupboard 1.7 5.8 1.1 0.6 2.0
meuble kitchen_table_ingredients 3.25 4.4 1.6 0.9 1.0
meuble water_tub 1.7 7.0 1.0 0.8 0.9
meuble sacks_vegetables 4.7 7.8 1.2 0.7 0.7
objet pot_steam 2.0 1.5
point cuisine_fourneau 2.0 2.55
point cuisine_table 3.25 5.6
point cuisine_tonneau 2.9 7.0
# --- réfectoire (V1 ; V3 ; V4 ; V5 ; VEX, ill.) ---
fenetre refectoire N 11.0 window_cross_large 2.4
mural wallitem_menu_board refectoire N 8.8 1.1 0.8
mural wallitem_height_marks refectoire N 13.4 0.0 0.4
mural wallitem_crystal_sconce refectoire O 2.6 1.6 0.3
meuble china_cabinet 6.8 1.45 1.6 0.6 2.2
meuble sink_stone 15.6 1.45 1.4 0.6 1.05
meuble chair_wood 11 3.2 7 0.5 1.0 x14
meuble dining_table_set 9 3.95 4 1 0.8
meuble dining_table_long 13 3.95 4 1 0.8
meuble chair_wood_back 11 4.7 7 0.5 1.0 x14
meuble chair_wood 11 6.4 7 0.5 1.0 x14
meuble dining_table_long 9 7.15 4 1 0.8
meuble dining_table_set 13 7.15 4 1 0.8
meuble chair_wood_back 11 7.9 7 0.5 1.0 x14
meuble crystal_pendant 9 3.95 0.8 0.3 0 libre
meuble crystal_pendant 13 7.15 0.8 0.3 0 libre
objet meal_lunch 9 3.95
objet tableware_a 13 7.15
point refectoire_vaisselier 6.8 2.4
point refectoire_evier 15.6 2.4
point refectoire_fenetre 11 2.35
point refectoire_allee 11 5.55
point refectoire_bout_est 16.0 5.6
point refectoire_bout_ouest 6.25 5.6
point refectoire_porte_cuisine 6.25 4.6
# --- escalier, corvées, écriteaux (V1, « L'Homme sans Marque ») ---
meuble stairs_up 17.5 4.0 1.6 3.0 3.0
mural wallitem_chore_chart escalier N 19.4 1.2 1.0
mural wallitem_notice_b escalier E 6.4 1.4 0.4
mural wallitem_notices_mix escalier E 3.6 1.2 0.8
mural wallitem_crystal_sconce escalier O 6.8 1.6 0.3
point escalier_pied 17.5 6.7
point planning 19.4 4.0
# --- palier de la salle des armes (V1, « Entrepôt de fées ») ---
mural wallitem_crystal_sconce palier_armes O 4.5 1.6 0.3
mural wallitem_bronze_plaque palier_armes E 7.6 1.6 0.5
point porte_armes 21.5 2.4
# --- archives, « salle de stockage » (V1, « Les valeureux… » ; V3) ---
fenetre archives N 25.5 window_dusty 1.0
mural wallitem_wall_clock archives O 3.4 1.2 0.5
mural wallitem_clippings archives E 7.0 1.3 0.8
meuble archive_shelves 23.7 1.45 2.0 0.6 2.4
meuble paper_pile_a 25.7 2.4 1.2 0.8 1.4
meuble desk_buried 23.35 3.9 1.4 0.8 1.3
meuble paper_pile_b 23.2 2.45 0.8 0.6 0.9
meuble filing_cabinet 25.85 4.3 1.0 0.5 1.4
meuble sofa_beige 23.65 6.5 2.0 0.9 0.9
meuble paper_pile_c 26.05 5.0 0.6 0.5 0.5
meuble papers_floor 24.8 5.3 2 1.5 0 libre
objet coffee_tray 23.35 3.9
point archives_bureau 23.35 4.95
point archives_canape 23.65 7.6
# --- salle de lecture (V1, « Les filles de l'entrepôt » ; V2 ; V4) ---
meuble window_reading_seat 29.6 1.55 2.0 0.8 2.2
fenetre lecture E 5.0 window_cross_small 0.8
meuble bookshelf_tall 27.5 1.45 1.6 0.6 2.3
meuble bookshelf_low 27.35 5.0 1.4 0.5 0.9
meuble bookshelf_tall_b 27.5 6.4 1.6 0.6 2.3
meuble reading_table 28.6 4.3 1.8 0.9 0.95
meuble armchair_reading 30.3 7.4 1.0 0.9 1.05
meuble book_pile 27.2 7.9 0.5 0.5 0.5
objet crystal_lamp_table 28.2 4.3
mural wallitem_crystal_sconce lecture E 7.4 1.6 0.3
point lecture_banquette 29.6 2.55
point lecture_table 28.8 5.4
# --- couloir (V1 ; VEX, « L'homme-chat » : le point d'eau) ---
meuble washstand_corridor 30.0 8.9 1.6 0.5 1.15
meuble runner_rug 15 9.5 26 1.0 0 libre
fenetre couloir E 9.5 window_cross_small 0.8
point couloir_ouest 3 9.5
point couloir_centre 13 9.5
point couloir_est 26 9.5
point point_eau 30.0 9.75
# --- salle de bains (V1 ; V3 ; V4) ---
meuble bath_tub 2.5 11.3 2.4 1.0 1.0
mural mirror_large bains O 13.0 0.0 1.2
mural wallitem_bath_rules bains E 12.0 1.3 0.4
meuble towel_shelf 6.3 14.2 1.0 0.5 1.6
meuble wash_tub 2.0 13.9 0.8 0.6 0.5
meuble hamper 4.6 14.3 0.6 0.5 0.7
meuble bath_puddles 3.6 12.8 2 1.5 0 libre
point bains_baignoire 2.5 12.4
# --- placard du bas (V2 ; V3 : le marteau) ---
meuble supply_cupboard 10.0 14.3 1.0 0.5 2.0
meuble cleaning_set 10.4 13.0 0.7 0.4 1.4
# --- entrée (V5 : le manteau à la patère ; V3 : les pantoufles) ---
mural wallitem_coat_hooks entree O 12.5 0.9 1.2
mural wallitem_frame_landscape entree E 11.6 1.4 0.6
meuble shoe_rack 14.25 12.2 1.2 0.4 0.6
point entree 13 12.6
# --- salle de jeux (V2 ; VEX ; V4 : le vieux piano) ---
meuble rug_playroom 19.4 12.9 4 3 0 libre
meuble piano_old 16.2 11.4 1.6 0.7 1.4
meuble toy_chest 22.2 11.2 1.0 0.6 0.8
meuble board_games_shelf 22.25 13.0 1.2 0.5 1.6
meuble game_table 19.4 12.8 1.2 0.6 0.5
meuble plush_blue 17.0 13.6 0.5 0.5 0.5
meuble plush_pile 20.6 14.4 1.0 0.5 0.6
meuble floor_cushions 17.6 14.4 1.2 0.4 0.4
meuble ball_white 16.3 12.2 0.2 0.2 0.2 libre
mural wallitem_kids_drawings jeux O 13.0 1.1 1.2
point jeux_tapis 19.4 14.0
point jeux_mur_balle 16.0 13.0
# --- infirmerie (V1 ; V3) ---
meuble bed_iron 26.0 11.2 2.0 1.0 1.05
meuble bedside_table 27.3 11.0 0.5 0.5 0.7
meuble bed_iron 28.9 11.2 2.0 1.0 1.05
meuble bedside_table 30.2 11.0 0.5 0.5 0.7
meuble bed_iron 26.5 14.3 2.0 1.0 1.05
meuble chair_child 25.0 12.15 0.45 0.4 0.8
meuble medicine_cabinet 30.35 13.35 1.0 0.5 1.8
meuble washbasin_stand 29.3 14.55 0.6 0.5 1.0
meuble infirmary_desk 23.9 14.2 1.3 0.8 1.0
fenetre infirmerie E 11.8 window_curtains_open 1.2
mural wallitem_day_calendar infirmerie E 14.4 1.4 0.3
mural wallitem_labcoat infirmerie O 12.0 0.7 0.5
objet vase_flowers 27.3 11.0
point infirmerie_lit_a 26.0 12.4
point infirmerie_fenetre 29.4 12.4
point infirmerie_bureau 24.0 13.0
# --- sorties ---
sortie vers_dehors 12 15 14 16 entrepot from_entrepot_rdc ""
sortie vers_arriere 0 9 1 10 entrepot from_entrepot_rdc_service ""
sortie vers_etage 16.7 5.55 18.3 6.15 entrepot_etage from_entrepot_rdc "Monter"
sortie vers_armes 20.85 1.15 22.15 1.7 salle_des_armes from_entrepot_rdc "Ouvrir"
# --- marqueurs ---
marqueur Spawn 13 12.8 N
marqueur from_entrepot 13 14.0 N
marqueur from_entrepot_service 2.2 9.5 E
marqueur from_entrepot_etage 17.5 6.8 S
marqueur from_salle_des_armes 21.5 2.4 S
# --- lumières ---
lumiere suspension_1 9 3.95 2.2 cristal
lumiere suspension_2 13 7.15 2.2 cristal
lumiere fourneau 2.0 1.5 0.6 cristal_ambre
lumiere applique_escalier 16.6 6.8 1.6 cristal
lumiere applique_armes 20.6 4.5 1.6 cristal
lumiere lampe_archives 23.35 3.9 1.0 cristal_eteint
lumiere lampe_lecture 28.2 4.3 1.0 cristal
lumiere applique_refectoire 5.6 2.6 1.6 cristal
```

### 3.2 Étage (`entrepot_etage`)

<!-- ascii:entrepot_etage -->
```text
entrepot_etage : 32 × 16 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10        15        20        25        30
    0 
      
        +-o----+--o---+--------+---o---+-------+--o--+---o---+-o----+
        |...EEE|.III..|LLMMMNNN|UU..VVV|escalie|b.UUU|....YYY|..cccc|
    2   |Willem|Chthol|Nygglath|soeur..|.......|Ithea|absente|Nephre|
        |......|......|PP......|.......|Z*Z....|.....|.......|......|
        |......|......|PP..RRRR|...BBBB|ZZZ....|.....|FFFF...|......|
        |G.....|JJJJ..|PP..RRRR|FFFFBBB|ZZZ....|aaa..|FFFF...|aaa...|
    4   |G.....|JJJJ..|QQ......|FFFFBBB|ZZZ....|aaa..|FFFF...|aaa...|
        |......|......|QQ......|.......|ZZZ....|.....|.......|......|
        |......|......|........|.CCCC..|ZZZ....|.....|.......|......o
        |FFFF..|......|........|.CCCC..|.......|.....|..FFFFF|......|
    6   |FFFF..|...KKK|........|.CCCC..|.......|.....|..FFFFF|......|
        |......|...KKK|SSSS....|.CCCC..|.......|.....|.......|b.....|
        |......|......|SSSSAAA.|....YYY|.......|.....|.......|b.....|
        |......|......|SSSSAAA.|....YYY|.......|.....|.......|......|
    8   |......|......|...AAAA.|.......|.......|.....|.......|......|
        +----=-+--==--+-----=--+--==---+---     --=--+--=----+-=----+
        |.DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD....dd|
        |.DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD@DDDDDDDDDDDDDDDD...*eeo
   10   |couloir..................................................ee|
        +-----=-----+------=---+-=-+-=-+------=----+-=-+-----==-----+
        |ggg.....UUU|ggg.......|pl.|wc.|ggg........|lin|ggg....ggggg|
        |ggg........|ggg.......|...|...|ggg........|...|ggg....ggggg|
   12   |dortoir A..|dortoir B.|...|...|dortoir C..|...|dortoir D...|
        |...........|..........|...|...|...........|...|............|
        |...........|..........|...|...|...........|...|............|
        |ggg....hhhh|aaa...gggg|...|...|aaaa...gggg|...|aaaa...ggggg|
   14   |ggg.iiihhhh|aaa...gggg|jj.|...|aaaa...gggg|kk.|aaaa...ggggg|
        |ggg.iiihhhh|aaa...gggg|jj.|...|aaaa...gggg|kk.|aaaa...ggggg|
        +-----------+----------+---+---+-----------+---+------------+
      
```
Légende des lettres : `A` rug_brown ; `B` cards_floor ; `C` clothes_floor ; `D` runner_rug ; `E` wardrobe_plain ; `F` bed_plain ; `G` footlocker ; `I` desk_chtholly ; `J` bed_chtholly ; `K` wardrobe_chtholly ; `L` fireplace ; `M` comm_crystal ; `N` shelf_nygglatho ; `P` tea_table ; `Q` chair_guest ; `R` desk_nygglatho ; `S` bed_nygglatho ; `U` dresser_child ; `V` desk_clean_brooch ; `Y` clothes_chest ; `Z` stairs_down ; `a` bed_child ; `b` book_pile ; `c` bookshelf_low ; `d` roof_ladder ; `e` leak_bucket ; `f` repair_planks ; `g` bunk_bed ; `h` bed_child_messy ; `i` plush_pile ; `j` supply_cupboard ; `k` towel_shelf.
<!-- /ascii:entrepot_etage -->

**Bornes de caméra** `Rect2(8, 4, 16, 6)`. Au nord, les chambres des grands et des aînées ; au
sud, contre la façade, les dortoirs des petites. Les murs sont minces : on entend tout (V4, « La
fille aux cheveux cramoisis »). La nuit, la lumière filtre sous la porte de Nygglatho (V2,
épilogue). Le plancher des chambres (`floor_planks_dark`) semble pouvoir céder (V5, épilogue).

| Pièce | Cotes (m) | Ce que dit l'œuvre | Portes et fenêtres | Mobilier (images) | À examiner |
| --- | --- | --- | --- | --- | --- |
| **Chambre de Willem** | 3,5 × 7,5 (x 1 → 4,5) | presque vide : un lit, une armoire vide, une lampe murale, plancher nu, **pas de rideaux, pas de chaise** ; la nuit, la fenêtre ne montre qu'un noir profond ; les draps sentent le soleil ; il s'assoit au rebord de la fenêtre (V1) | porte (3,6) ; **fenêtre nue au nord** (`window_bare`, x 2) | `bed_plain`, `wardrobe_plain`, `footlocker` (sa malle, original) ; mur : `wallitem_wall_lamp` | la fenêtre (le noir de la forêt, la nuit) ; l'armoire vide |
| **Chambre de Chtholly** | 3,5 × 7,5 | un calendrier où elle raye les jours ; une armoire au fond de laquelle dort le chapeau offert par Willem ; un miroir, un lit, un oreiller (V1 ; VEX) ; un bureau, une chaise, une fenêtre à rideaux, une porte jamais verrouillée ; chambre bien rangée (V2 ; V3) | porte (6,2) ; fenêtre à rideaux au nord (x 6,2) | `bed_chtholly`, `desk_chtholly`, `wardrobe_chtholly` ; mur : **`wallitem_calendar`** (x 7,45) | **le calendrier : le journal du jeu** (une ligne par jour, ACTE1.md) ; l'armoire (le chapeau acheté par Willem sur l'île n° 28, qu'elle cache au fond) ; le miroir |
| **Chambre de Nygglatho** | 4,5 × 7,5 | petite pièce : table simple, deux chaises, étagère, lit, toutes sortes d'objets ; service à thé ; tapis devant la porte où s'écroule l'avalanche (V1) ; cheminée, bouilloire, petite table à thé, chaise de l'invité, bureau où elle pose le menton, dernière lampe à huile (V2) ; cristal de communication, devant lequel elle s'assoit dos à la porte (V1 ; V5) | porte (11,0) ; pas de fenêtre visible (la cheminée occupe le mur nord) | `fireplace` (feu `anim/hearth_fire`), `comm_crystal` (appel : `anim/comm_crystal_call`), `shelf_nygglatho`, `tea_table` (`tea_tray_cheesecake`), `chair_guest`, `desk_nygglatho` (`oil_lamp`), `bed_nygglatho` ; décalque `rug_brown` devant la porte | le cristal ; la boîte à thé ; le cheese-cake |
| **Chambre de la grande sœur** | 3,5 × 7,5 | porte non verrouillée ; grand désordre, jeu de cartes éparpillé, seul le bureau est propre, une broche d'argent posée dessus (V1, « Entrepôt de fées ») | porte (14,3) ; rideaux tirés au nord | `bed_plain`, `dresser_child`, `desk_clean_brooch` (la broche ne s'y voit que dans le souvenir du jour 6 : au présent, Chtholly la porte ; variante sans broche, section 12), `clothes_chest` ; décalques `cards_floor`, `clothes_floor` (sans sous-vêtements visibles) | le bureau propre ; les cartes |
| **Trémie et palier** | 4 × 7,5 | (original) | ouverte sur le couloir (x 18,4 → 20,4) | `stairs_down` (x 16,7 → 18,3, z 2,5 → 5,5) ; murs : `wallitem_notice_a` (« toilettes de l'étage hors service », V1), un second planning de corvées, applique | l'écriteau des toilettes |
| **Chambre d'Ithea** | 3 × 7,5 | (V1 : chambre non décrite ; elle lit des romans d'amour, *Triade Passionnelle*) | porte (22,0) ; fenêtre à rideaux | `bed_child`, `dresser_child`, `book_pile` (ses romans) | le tome 3 de son roman |
| **Chambre des deux aînées absentes** | 4 × 7,5 | l'entrepôt compte cinq fées adultes, deux non nommées (V1) ; la chambre de l'une jouxte celle d'Ithea (V4) | porte (25,0) ; rideaux tirés | deux `bed_plain`, `clothes_chest` | « elles sont en mission longue » (clin d'œil, sans nom à l'acte 1) |
| **Chambre de Nephren** | 3,5 × 7,5 | (V1 : non décrite ; elle lit sans cesse) | porte (28,6) ; fenêtre au nord et à l'est | `bed_child`, `bookshelf_low`, `book_pile` | ses livres |
| **Couloir** | 30 × 2 | **le bout du couloir fuit sous la pluie** ; planches et clous de la dernière réparation (V2 ; V3) ; embuscades, espionnage au coin (V2 ; V3) | fenêtre au pignon est ; au bout est, **l'échelle de meunier vers la trappe du toit** (original : la trappe ferme mal, d'où la fuite) | `runner_rug`, `roof_ladder` (**nom proposé**), `leak_bucket` et `anim/leak_drip` sous la trappe, `repair_planks` | le seau ; la trappe |
| **Dortoirs A à D** | 6 × 4,5, 5,5 × 4,5, 6 × 4,5, 6,5 × 4,5 | les petites ont des chambres d'enfants avec fenêtres ; elles dorment en pyjama, couchées tôt (V3 ; VEX) | une porte chacun | `bunk_bed` (deux ou trois par dortoir), `bed_child`, `bed_child_messy`, `dresser_child`, `plush_pile` | — |
| **Placard, toilettes, lingerie** | 2 × 4,5 chacun | placards aux deux niveaux (V2 ; V3) ; le linge de Nygglatho (V2) | une porte chacun | `supply_cupboard`, `towel_shelf` | — |

**Qui dort où (original)** : dortoir A, le quatuor Tiat, Collon, Pannibal, Lakhesh (VEX, final :
« quatuor soudé ») ; dortoir B, Almita, Kana, Giniette et deux fées génériques ; dortoirs C et D,
les autres fées génériques (`fairy_01` à `fairy_12` et celles de la communauté).

**Points nommés** : `willem_fenetre`, `willem_lit`, `willem_porte`, `chtholly_bureau`,
`chtholly_calendrier`, `chtholly_lit`, `chtholly_porte`, `nygglatho_cristal`, `nygglatho_the`,
`nygglatho_bureau`, `nygglatho_tapis`, `grande_soeur_bureau`, `palier`, `couloir_ouest`,
`couloir_fuite`, `dortoir_a` à `dortoir_d`.

```plan
carte entrepot_etage 32 16 dedans
nom "L'entrepôt — étage"
region entrepot
# même cadre que le rez-de-chaussée (bâtiment x 1 → 31, z 1 → 15)
# --- bande nord : chambres des grands et des aînées (mur nord haut, fenêtres visibles) ---
piece willem 1 1 4.5 8.5 floor_planks_dark wall_plaster_worn "Willem"
piece chtholly 4.5 1 8 8.5 floor_planks_dark wall_wallpaper_faded "Chtholly"
piece nygglatho 8 1 12.5 8.5 floor_planks_dark wall_wallpaper_faded "Nygglatho"
piece grande_soeur 12.5 1 16.5 8.5 floor_planks_dark wall_wallpaper_faded "soeur"
piece tremie 16.5 1 20.5 8.5 floor_planks_worn wall_plaster_worn "escalier"
piece ithea 20.5 1 23.5 8.5 floor_planks_dark wall_wallpaper_faded "Ithea"
piece absentes 23.5 1 27.5 8.5 floor_planks_dark wall_wallpaper_faded "absentes"
piece nephren 27.5 1 31 8.5 floor_planks_dark wall_wallpaper_faded "Nephren"
piece couloir 1 8.5 31 10.5 floor_planks_worn wall_plaster_worn "couloir"
# --- bande sud : dortoirs des petites ---
piece dortoir_a 1 10.5 7 15 floor_planks_dark wall_wallpaper_faded "dortoir A"
piece dortoir_b 7 10.5 12.5 15 floor_planks_dark wall_wallpaper_faded "dortoir B"
piece placard 12.5 10.5 14.5 15 floor_planks_worn wall_plaster_worn "pl."
piece toilettes 14.5 10.5 16.5 15 floor_tiles_bath wall_plaster_worn "wc"
piece dortoir_c 16.5 10.5 22.5 15 floor_planks_dark wall_wallpaper_faded "dortoir C"
piece lingerie 22.5 10.5 24.5 15 floor_planks_worn wall_plaster_worn "linge"
piece dortoir_d 24.5 10.5 31 15 floor_planks_dark wall_wallpaper_faded "dortoir D"
# --- portes ---
porte willem couloir 3.6 8.5 1.2 door_room
porte chtholly couloir 6.2 8.5 1.2 door_room
porte nygglatho couloir 11.0 8.5 1.2 door_room
porte grande_soeur couloir 14.3 8.5 1.2 door_room
ouverture tremie couloir 19.4 8.5 2.0
porte ithea couloir 22.0 8.5 1.2 door_room
porte absentes couloir 25.0 8.5 1.2 door_room
porte nephren couloir 28.6 8.5 1.2 door_room
porte dortoir_a couloir 4.0 10.5 1.2 door_room
porte dortoir_b couloir 10.6 10.5 1.2 door_room
porte placard couloir 13.5 10.5 1.2 door_room
porte toilettes couloir 15.5 10.5 1.2 door_room
porte dortoir_c couloir 20.0 10.5 1.2 door_room
porte lingerie couloir 23.5 10.5 1.2 door_room
porte dortoir_d couloir 27.8 10.5 1.2 door_room
# --- chambre de Willem (V1, « L'Homme sans Marque » ; « Directeur en carton ») ---
fenetre willem N 2.0 window_bare 1.1
mural wallitem_wall_lamp willem E 5.5 1.5 0.3
meuble wardrobe_plain 3.8 1.45 1.0 0.6 2.0
meuble bed_plain 2.25 6.0 2.0 0.95 0.95
meuble footlocker 1.6 4.2 0.8 0.5 0.5
point willem_fenetre 2.0 2.4
point willem_lit 2.25 7.2
point willem_porte 3.6 7.8
# --- chambre de Chtholly (V1 ; V2 ; V3 ; VEX) ---
fenetre chtholly N 6.2 window_curtains_open 1.2
mural wallitem_calendar chtholly N 7.45 1.3 0.4
meuble desk_chtholly 6.2 1.45 1.1 0.6 1.05
meuble bed_chtholly 5.65 4.0 2.0 0.95 0.95
meuble wardrobe_chtholly 7.35 6.6 1.0 0.6 2.0
point chtholly_bureau 6.2 2.4
point chtholly_calendrier 7.25 2.4
point chtholly_lit 5.65 5.1
point chtholly_porte 6.2 7.8
# --- chambre de Nygglatho (V1 ; V2 ; V3 ; V5) ---
meuble fireplace 9.0 1.45 1.6 0.6 1.4
objet hearth_fire 9.0 1.45
meuble comm_crystal 10.3 1.35 0.7 0.4 1.4
meuble shelf_nygglatho 11.65 1.35 1.2 0.4 1.8
meuble tea_table 9.0 3.4 0.9 0.9 0.8
meuble chair_guest 9.0 4.4 0.7 0.6 1.05
meuble desk_nygglatho 11.65 3.6 1.4 0.8 1.1
objet oil_lamp 11.65 3.6
objet tea_tray_cheesecake 9.0 3.4
meuble bed_nygglatho 9.25 7.2 2.1 1.1 1.1
meuble rug_brown 11.0 7.6 2 1.2 0 libre
point nygglatho_cristal 10.3 2.35
point nygglatho_the 10.2 4.7
point nygglatho_bureau 11.65 4.7
point nygglatho_tapis 11.0 7.5
# --- chambre de la grande sœur (V1, « Entrepôt de fées ») ---
fenetre grande_soeur N 14.4 window_curtains_closed 1.2
meuble dresser_child 13.3 1.45 0.9 0.5 0.9
meuble desk_clean_brooch 15.6 1.45 1.1 0.6 1.05
meuble bed_plain 13.65 4.0 2.0 0.95 0.95
meuble cards_floor 15.5 3.8 1.5 1.0 0 libre
meuble clothes_floor 14.5 6.0 2 1.5 0 libre
meuble clothes_chest 15.8 7.5 0.9 0.5 0.6
point grande_soeur_bureau 15.6 2.4
# --- trémie de l'escalier (original) ---
meuble stairs_down 17.5 4.0 1.6 3.0 1.1
mural wallitem_crystal_sconce tremie N 19.6 1.6 0.3
mural wallitem_notice_a tremie E 7.2 1.4 0.4
mural wallitem_chore_chart tremie E 4.0 1.2 1.0
point palier 19.4 4.0
# --- Ithea, les deux aînées absentes, Nephren (V1 ; V4) ---
fenetre ithea N 21.8 window_curtains_open 1.2
meuble bed_child 21.45 4.0 1.6 0.8 0.85
meuble dresser_child 22.75 1.45 0.9 0.5 0.9
meuble book_pile 21.0 1.5 0.5 0.5 0.5
fenetre absentes N 25.5 window_curtains_closed 1.2
meuble bed_plain 24.65 3.6 2.0 0.95 0.95
meuble bed_plain 26.35 6.0 2.0 0.95 0.95
meuble clothes_chest 26.6 1.45 0.9 0.5 0.6
fenetre nephren N 28.6 window_curtains_open 1.2
fenetre nephren E 5.0 window_cross_small 0.8
meuble bed_child 28.45 4.0 1.6 0.8 0.85
meuble bookshelf_low 30.05 1.4 1.4 0.5 0.9
meuble book_pile 28.0 6.8 0.5 0.5 0.5
# --- couloir : la fuite au bout (V2 ; V3) ---
meuble runner_rug 15 9.5 26 1.0 0 libre
meuble roof_ladder 30.45 9.1 0.8 0.9 3.0
meuble leak_bucket 30.45 10.0 0.5 0.45 0.45
objet leak_drip 30.45 10.0
meuble repair_planks 29.6 8.85 0.7 0.3 1.8
fenetre couloir E 9.5 window_cross_small 0.8
mural wallitem_crystal_sconce couloir O 9.5 1.6 0.3
point couloir_ouest 3 9.5
point couloir_fuite 28.9 9.6
# --- dortoirs (original : une trentaine de fées dans de petites chambres, V1 ; V3) ---
meuble bunk_bed 2.1 11.2 1.8 0.9 1.9
meuble bunk_bed 2.1 14.2 1.8 0.9 1.9
meuble bed_child_messy 5.8 14.3 1.6 0.9 0.9
meuble dresser_child 6.4 11.1 0.9 0.5 0.9
meuble plush_pile 4.4 14.5 1.0 0.5 0.6
point dortoir_a 4.2 12.6
meuble bunk_bed 8.1 11.2 1.8 0.9 1.9
meuble bunk_bed 11.4 14.2 1.8 0.9 1.9
meuble bed_child 8.0 14.3 1.6 0.8 0.85
point dortoir_b 10.0 12.6
meuble supply_cupboard 13.5 14.4 1.0 0.5 2.0
meuble bunk_bed 17.6 11.2 1.8 0.9 1.9
meuble bunk_bed 21.4 14.2 1.8 0.9 1.9
meuble bed_child 18.0 14.3 1.6 0.8 0.85
point dortoir_c 19.8 12.8
meuble towel_shelf 23.5 14.4 1.0 0.5 1.6
meuble bunk_bed 25.6 11.2 1.8 0.9 1.9
meuble bunk_bed 29.8 11.2 1.8 0.9 1.9
meuble bunk_bed 29.8 14.2 1.8 0.9 1.9
meuble bed_child 26.0 14.3 1.6 0.8 0.85
point dortoir_d 27.8 12.8
# --- sorties ---
sortie vers_rdc 16.7 2.2 18.3 2.5 entrepot_rdc from_entrepot_etage "Descendre"
sortie vers_toit 29.4 9.0 30.0 9.6 entrepot_toit from_entrepot_etage "Monter sur le toit"
# --- marqueurs ---
marqueur Spawn 19.4 9.5 N
marqueur from_entrepot_rdc 17.4 1.8 E
marqueur from_entrepot_toit 28.9 9.5 O
lumiere cheminee 9.2 1.45 0.6 feu
lumiere lampe_huile 11.55 4.0 1.0 huile
lumiere applique_palier 19.6 1.2 1.6 cristal
lumiere applique_couloir 1.2 9.5 1.6 cristal
lumiere lampe_willem 4.4 5.5 1.5 cristal
```

### 3.3 Le toit (`entrepot_toit`)

<!-- ascii:entrepot_toit -->
```text
entrepot_toit : 16 × 16 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0                   10
    0 //////HHHHHHHHHHHHHHHHHHHHHHHHHH
      //////HHHHHHHHHHHHHHHHHHHHHHHHHH
      //////========================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////=======CCCCCCCC=========HH
      //////=======CCCCCCCC=========HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////=====================EEEHH
      //////==================@==E*EHH
      //////========================HH
   10 //////========================HH
      //////=======CCCCCCCC=========HH
      //////=======CCCCCCCC=========HH
      //////========================HH
      //////========================HH
      //////===DD===================HH
      //////===DD===================HH
      //////========================HH
      //////========================HH
      //////========================HH
      //////HHHHHHHHHHHHHHHHHHHHHHHHHH
      //////HHHHHHHHHHHHHHHHHHHHHHHHHH
```
Légende des lettres : `A` roof_railing_broken ; `B` chimney_brick ; `C` drying_frame ; `D` laundry_basket ; `E` roof_hatch.
<!-- /ascii:entrepot_toit -->

- **Ce que dit l'œuvre** : un séchoir où flotte beaucoup de linge le jour ; la nuit, le poste
  d'observation des étoiles ; une rambarde de métal laide, abîmée, branlante, à la taille des fées,
  trop basse pour Nygglatho ; on y décroche les draps avec un panier tressé (V2, « De ce côté-ci de
  l'écran » ; V3 ; VEX, « Le cas de la fée aux cheveux gris »).
- **La carte** : 16 × 16 m, **dehors** (ciel, vent) ; la terrasse de 12 × 14 m est le toit plat du
  volume est (toit = bâtiment − (15 ; −1)) ; sol `floor_roof_deck` (**à confirmer**, cahier 9.4) ;
  le sol courant (y = 0) est la terrasse : la cour est 6,5 m plus bas.
- **Bords** : rambarde `roof_railing` (livrée, modules de 2 m) au nord, à l'est et au sud ; au
  sud, un module tordu `roof_railing_broken` (x 10 → 12) ; à l'ouest, le pan d'ardoise du volume
  ouest qui monte vers le faîte (`roof_edge_slate`, à confirmer), avec la cheminée.
- **Décors** : deux séchoirs `drying_frame` (livrés, 4 m) en (8,5 ; 6) et (8,5 ; 11), linge animé
  (`anim/drying_frame_wave`) ; panier `laundry_basket` ; la trappe `roof_hatch` en (14,45 ; 9,1),
  au-dessus de l'échelle du couloir.
- **Sortie** `trappe` → `entrepot_etage`, `from_entrepot_toit`, « Descendre » ; marqueur
  `from_entrepot_etage` (12,2 ; 9,1) O.
- **Points** : `toit_balustrade_nord` (Nephren la nuit, VEX), `toit_sechoir`, `toit_bord_sud`,
  `toit_coin_est`.
- **Vue au nord** (le point de vue de la carte) : par-dessus la rambarde nord, la cime des arbres
  6,5 m plus bas (`treeline_autumn_a/b` posées hors carte au nord, à y = −6,5), le champ au
  nord-est, la clairière au nord-ouest ; la nuit, le ciel : pour la scène du toit (ACTE1.md), la
  caméra lève les yeux (tangage 15°) et montre le ciel étoilé (`sky_night`).
- **Lumière** : jour, plein ciel ; nuit, la lueur de la trappe ouverte (cristal, par-dessous) et
  les étoiles. **Densité** : 25 à 40 éléments (linge, pinces, seau, panier, mousse sur les planches).
- **Bornes de caméra** `Rect2(6, 4, 4, 4)`.

```plan
carte entrepot_toit 16 16 dehors
nom "L'entrepôt — le toit"
region entrepot
echelle 0.5 0.5
# terrasse = toit plat du volume est (bâtiment x 18 → 30, z 0 → 14) ; toit = bâtiment − (15, −1)
sol floor_roof_deck 3 1 15 15
sol rock 0 0 3 16
bord toit 0 0 3 16 3.5
bord rambarde 3 0 16 1 0.8
bord rambarde 15 1 16 16 0.8
bord rambarde 3 15 15 16 0.8 pp
decor roof_railing_broken 11 15.4 2 0.4 0.8 libre pp
decor drying_frame 8.5 6.0 4 0.3 2.2
decor drying_frame 8.5 11.0 4 0.3 2.2
decor laundry_basket 5.2 13.0 0.6 0.5 0.5
decor chimney_brick 1.5 4.0 1.0 1.0 1.6 libre
decor roof_hatch 14.45 9.1 1.0 0.6 0.4
sortie trappe 13.6 8.8 13.95 9.4 entrepot_etage from_entrepot_toit "Descendre"
marqueur Spawn 12.2 9.1 O
marqueur from_entrepot_etage 12.2 9.1 O
point toit_balustrade_nord 12.6 2.6
point toit_sechoir 8.5 7.1
point toit_bord_sud 11.0 13.2
point toit_coin_est 13.5 3.0
lumiere trappe 14.45 9.1 0.3 cristal_dessous
```

### 3.4 La salle des armes (`salle_des_armes`)

<!-- ascii:salle_des_armes -->
```text
salle_des_armes : 14 × 10 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10
    0 
      
        +-----------------------+
        |AAAA..BBBBBBBBCCCCCCCCC|
    2   |AAAAcrypte.............|
        |AAAA...................|
        |AAAA...................|
        |AAAA...................|
    4   |..*....................|
        |.......................|
        |..@...DD.......DD......|
        |......DD.......DD......|
    6   |.......................|
        |.......................|
        |.................EEEE..|
        |...........FF....EEEE..|
    8   |...........FF..........|
        |.......................|
        +-----------------------+
      
```
Légende des lettres : `A` crypt_stairs ; `B` sword_rack_a ; `C` sword_rack_b ; `D` crypt_pillar ; `E` swords_wrapped ; `F` talisman_chest.
<!-- /ascii:salle_des_armes -->

- **Ce que dit l'œuvre** : derrière la porte rivetée à cinq serrures, un son grave ; une odeur
  d'humidité, de moisi et de poussière ; une **crypte sans lumière** ; une dizaine d'épées contre un
  mur, presque toutes de la taille d'une personne, longues poignées, lames de pièces assemblées
  fissurées, de couleurs différentes d'un côté à l'autre ; les épées en service rentrent
  emmaillotées de tissu blanc (V1, « Entrepôt de fées ») ; des talismans en réserve (V3).
- **La pièce** : 12 × 8 m (x 1 → 13, z 1 → 9), dalles `floor_flagstone_cellar`, murs
  `wall_cellar_stone`, coupe `wallcut_stone` ; deux piliers `crypt_pillar` (5 ; 5,5) et
  (9,5 ; 5,5).
- **L'escalier** `crypt_stairs` contre le mur nord (x 1,7 → 3,3) remonte vers la porte rivetée,
  vue de dedans (`door_armory_inside`, en haut des marches) ; sortie `remonter` à son pied →
  `entrepot_rdc`, `from_salle_des_armes`, « Remonter » ; marqueur `from_entrepot_rdc` (2,5 ; 5) S.
- **Les épées** : `sword_rack_a` et `sword_rack_b` (livrés, 4 m chacun) contre le mur nord,
  x 4,6 → 12,7 ; `swords_wrapped` sur un tréteau (11 ; 7,6) ; `talisman_chest` (7,4 ; 7,9) ;
  toiles d'araignée (`wallitem_cobweb`).
- **Lumière** : aucune (préréglage `noir`, E9) ; seulement celle qu'on apporte : la lumière de fée
  de Chtholly ou la lampe à cristal de Nygglatho (rayon de 4 m).
- **À examiner** : les râteliers (« Percival, Dindrane, Locus Solus, Mulsum Aurea » : les noms ne
  s'affichent que si Willem est là, V1) ; les épées emmaillotées.
- **Points** : `armes_rateliers`, `armes_tissu`, `armes_coffret`, `armes_centre`.
- **Bornes de caméra** `Rect2(5, 3, 4, 3)`. **Densité** : 20 à 30 éléments (épées, poussière,
  salpêtre, toiles, tréteau) ; le vide et le noir sont le sujet.

```plan
carte salle_des_armes 14 10 dedans
nom "La salle des armes"
region entrepot
piece crypte 1 1 13 9 floor_flagstone_cellar wall_cellar_stone "crypte"
meuble crypt_stairs 2.5 2.4 1.6 2.5 2.5
mural door_armory_inside crypte N 2.5 2.5 1.3
meuble sword_rack_a 6.6 1.45 4 0.6 1.9
meuble sword_rack_b 10.7 1.45 4 0.6 1.9
meuble crypt_pillar 5.0 5.5 0.6 0.6 3.0
meuble crypt_pillar 9.5 5.5 0.6 0.6 3.0
meuble swords_wrapped 11.0 7.6 1.6 0.8 1.0
meuble talisman_chest 7.4 7.9 0.8 0.6 0.6
mural wallitem_cobweb crypte N 12.6 2.4 0.5
mural wallitem_cobweb crypte O 7.5 2.4 0.5
sortie remonter 1.7 3.7 3.3 4.2 entrepot_rdc from_salle_des_armes "Remonter"
marqueur Spawn 2.5 5.0 S
marqueur from_entrepot_rdc 2.5 5.0 S
point armes_rateliers 8.6 2.6
point armes_tissu 11.0 6.5
point armes_coffret 7.4 6.8
point armes_centre 7.2 4.5
```

## 4. Le sentier et le marais (`sentier`)

### 4.1 Ce que dit l'œuvre

- Un sentier étroit qui s'enfonce dans une forêt noire, **sans lampadaire ni aucune lumière** ; la
  nuit, si couvert que seule la lumière des étoiles filtre par endroits et qu'on ne voit pas ses
  pieds (V1, « L'Homme sans Marque »).
- En s'en écartant, Willem a les pieds dans l'eau : le marais sent l'eau, la terre et le vent ; il
  y tombe à la renverse dans une gerbe ; une lumière zigzague, Pannibal bondit de l'ombre avec son
  épée de bois et une petite lumière dans la main, puis Chtholly arrive avec la sienne (même
  chapitre).
- De jour, un petit sentier forestier aux pierres clairsemées, mal entretenues, mangées d'herbe, où
  l'on ne se perd pas tant qu'on le suit ; le soleil filtre entre les arbres (V3, « Je suis à la
  maison ») ; on y court de l'entrepôt au bord de l'île (V1, « La fille errante… ») ; de l'entrepôt
  on **descend** vers la ville (V5, « La fin imminente »).

### 4.2 Plan

<!-- ascii:sentier -->
```text
sentier : 80 × 40 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50        60        70        80
    0 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^wwwwAAAAwwwwwwwwAAAAwwwwwwwwAAAAwwwwAAAAww^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^wwwwTwwwwwwwwwwwwwIIIIwwwwwJJwwwwwwTwwwwww^^^^^^^^^^^^^^^^^^^^^^
   10 ^^^^^^^^^^^^^^^^wwwwwwwwwwwBBwwwwwIIIEEEFFwJJwwwwwwwwwwwww^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^wwwwwwwwwwwwwwwwwwwwwEEEFFwwwCCwwwwwwwwwww^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^wwwwwwwwwwwwwwwCCwwwwwwwDDwwwwwwwwwwwwwwww^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^wwwwwwwwGGwwwwwwwwwwwwwwDDwwwwwwwwwwwwwwww^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww;;;;;;;;;;;;;;;;;;;;;;
   20 ;;;;;;;;PPPPPPPP;;;;;;;;;;;;;;;;KK;;;;;;;;;;;;;;;;;;;;;;;;;;;;PPPPPPPP;;;;;;;;;;
      ::::::::KKPPPPPP::::LL::::::::::KK::::::::::::LL::::::::::::KK:::::::::::::::::>
      <:::::@:KK::::MM::::::::::::::::::::::::::::::::::::::::::::KK:::::::::::QQ:::::
      ;;;;NNNN;;;;;;;;;;;;;;;;;;NNNN;;;;;;;;;;;;;;;;;;;;NNNN;;;;::::::::::::::;;;;^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^;;::::::::::::::;;;;^^^^
   30 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^;;::::::::::::::;;^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::;;^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::;;^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^::::::::::;;^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^:::::::v::;;^^^^^^
```
Légende des lettres : `A` marsh_reed_wall ; `B` marsh_snag ; `C` marsh_hummock_a ; `D` marsh_hummock_b ; `E` reeds ; `F` reeds_b ; `G` cattails ; `I` bog_pool_a ; `J` lily_pads ; `K` path_stones_a ; `L` path_stones_b ; `M` path_root_step ; `N` path_edge_ferns ; `P` fg_canopy_a ; `Q` thicket_b.
<!-- /ascii:sentier -->

- **Taille** 80 × 40 m ; **bornes** `Rect2(10, 9, 60, 23)`. Le sentier court d'ouest en est sur
  une levée de terre ; le marais s'étend **au nord** (on le contemple, on peut y entrer) ; au sud,
  sous-bois bas et premier plan. À l'est, la bifurcation : le chemin de la ville descend vers le
  sud-est.
- **Paliers** : sentier à 0 ; marais à −0,5 (eau au ras, berge `cliff/step_marsh`) ; lisière nord
  à +1 (`cliff/wall_earth_1m`) ; le chemin de la ville descend à −0,5 par une rampe (62 → 70 ;
  26 → 30).
- **Matières** : sentier `path_overgrown` (cahier n° 3, **à confirmer** : en attendant
  `path_dirt_b` et `grass_edge_*`), 1,5 m de terre visible au milieu d'une bande libre de 3 m ;
  pierres plates `path_stones_a/b` ; marais `peat` et eau ; sous-bois `forest_floor`,
  `leaf_litter`.
- **Grands décors** : rideaux de roseaux `marsh_reed_wall` au fond du marais ; deux aulnes
  (`alder`) ; souche noyée `marsh_snag` ; touradons `marsh_hummock_a/b` ; mare de tourbe
  `bog_pool_a`, nénuphars `lily_pads` ; la racine qui fait marche `path_root_step` ; la voûte de
  feuillage en premier plan suspendu `fg_canopy_a` (**à confirmer** par E10) au-dessus du sentier.
- **Kits** : bord de chemin (`path_edge_ferns` hors de la bande libre, `fern_*`, `grass_clump_*`,
  `stepping_stones`) ; marais (roseaux, massettes `cattails`, brume `mist_patch`, libellules) ;
  lisière (`forest_wall_*` au nord) ; sous-bois sud (`fg_trunk_a/b`, `fg_bush`, `fg_fern`, premier
  plan).
- **Place réservée** `embuscade` (30 → 44, 13 → 21,5) : le bord du marais où tombe Willem ;
  points `marais_chute` (35,5 ; 16,5), `lumiere_pannibal` (40 ; 12,5) (d'où part la lumière qui
  zigzague), `chtholly_arrivee` (30 ; 21,8), `premiere_embuscade` (16 ; 23 : Pannibal y bondit sur Chtholly, ACTE1.md 1.2), `bifurcation`, `vue_marais`.
- **Sorties** : `vers_entrepot` (ouest) → `entrepot`, `from_sentier` ; `vers_port` (est) → `port`,
  `from_sentier` ; `vers_ville` (sud-est) → `ville_haute`, `from_sentier`. Marqueurs `from_entrepot`,
  `from_port`, `from_ville_haute`.
- **Lumière** : **aucune**. La nuit, préréglage `nuit_sans_lune` (E9) : seules les étoiles par les
  trouées (`light_shaft_a` en bleu pâle) et les lumières de fée. Le jour, rais de soleil
  (`light_shaft_a/b`, `sun_dapple`).
- **Vue au nord** : le marais, ses roseaux, ses aulnes et la lisière noire ; la nuit, des
  lucioles au-dessus de l'eau (`anim/fireflies`, **original**, absentes en fin d'automne : à garder
  pour le printemps de l'acte 4).
- **Densité** : 80 à 120 éléments par écran ; de la vie : grenouilles, libellules, corbeau (VIE.md).

```plan
carte sentier 80 40 dehors
nom "Le sentier et le marais"
region sentier
sol forest_floor 0 0 80 40
sol leaf_litter 0 26 80 34
sol peat 16 5 58 19
sol path_overgrown 0 22 80 26
sol path_overgrown 58 24 72 40
sol moss 58 18 80 22
palier 1.0 0 0 80 5
palier -0.5 16 5 58 18
palier -0.5 62 30 74 40
rampe 62 26 70 30 0 -0.5 S
# --- bords : forêt dense, marais au nord du sentier (V1, « L'Homme sans Marque ») ---
bord foret 0 0 80 5 11
bord foret 0 5 16 19 10
bord foret 58 5 80 18 10
bord foret 0 29 56 40 9 pp
bord foret 76 26 80 40 9 pp
bord foret 56 32 62 40 9 pp
bord foret 74 30 76 40 9 pp
eau 16 5 58 19
decor marsh_reed_wall 22 6.5 4 0.6 2 libre
decor marsh_reed_wall 34 6.5 4 0.6 2 libre
decor marsh_reed_wall 46 6.5 4 0.6 2 libre
decor marsh_reed_wall 54 7 4 0.6 2 libre
arbre alder 20 7.5 4 7
arbre alder 51 8 4 7
decor marsh_snag 28 11 2 1.2 2 libre
decor marsh_hummock_a 32 15 1.2 0.8 0.8 libre
decor marsh_hummock_b 41 16 0.9 0.6 0.6 libre
decor marsh_hummock_a 46 13 1.2 0.8 0.8 libre
decor reeds 38.5 11.5 1.5 1.5 1.4 libre
decor reeds_b 40.5 12.5 1.5 1.5 1.4 libre
decor cattails 25 16.5 1.5 1 1.4 libre
decor bog_pool_a 36 9.5 3 2 0 libre
decor lily_pads 44 10 2 1.5 0 libre
# --- le sentier : pierres clairsemées, herbes (V3, « Je suis à la maison ») ---
decor path_stones_a 9 24 2 1.5 0 libre
decor path_stones_b 21 22.5 1.5 1 0 libre
decor path_stones_a 33 21.8 2 1.5 0 libre
decor path_stones_b 47 23 1.5 1 0 libre
decor path_stones_a 61 23.5 2 1.5 0 libre
decor path_root_step 15 24.6 2 0.6 0.6 libre
decor path_edge_ferns 6 27 4 0.8 1.1 libre pp
decor path_edge_ferns 28 26.4 4 0.8 1.1 libre pp
decor path_edge_ferns 52 27 4 0.8 1.1 libre pp
decor fg_canopy_a 12 22 8 1 4 libre pp
decor fg_canopy_a 66 21 8 1 4 libre pp
decor thicket_b 74 25.5 2 0.8 1.4
# --- chemins ---
chemin sentier 3 1;24 12;23.5 24;22 36;22.3 48;23.4 58;23.5 68;22 79;21.5
chemin vers_ville 3 58;23.5 64;28 68;33 69;39
place embuscade 30 13 44 21.5
# --- sorties et marqueurs ---
sortie vers_entrepot 0 22 0.6 26 entrepot from_sentier ""
sortie vers_port 79.4 19.5 80 23.5 port from_sentier ""
sortie vers_ville 67 39.4 71 40 ville_haute from_sentier ""
marqueur Spawn 6 24 E
marqueur from_entrepot 2.5 24 E
marqueur from_port 77.5 21.5 O
marqueur from_ville_haute 69 37.5 N
point marais_chute 35.5 16.5
point lumiere_pannibal 40 12.5
point chtholly_arrivee 30 21.8
point premiere_embuscade 16 23
point bifurcation 58 23.5
point vue_marais 46 21.5
```

## 5. Le village des hommes-bêtes (`village`, `cafe`, `maison_limashenka`)

### 5.1 Ce que dit l'œuvre

- À quelques pas de l'entrepôt, au bord de l'île ; pas très grand, mais pas assez petit pour que
  les fées connaissent tout le monde ; la campagne : presque personne n'y porte de beaux habits,
  les gens élégants viennent d'ailleurs (VEX, « Cinq cents ans »).
- Le café fait tout, faute d'autre endroit où manger : café le jour, alcool le soir ; une sonnette
  à la porte ; une arrière-boutique ; l'après-midi, on y mange ou on y prend le thé ; une tablée
  d'hommes-bêtes éméchés rit fort ; le serveur homme-chat en tablier offre des jus « pour la
  maison » en cachette du patron (même chapitre).
- La maison Limashenka : un salon, une vieille horloge murale purement mécanique, peigne doré dans
  une caisse de résonance qui joue une comptine ; les pièces de rechange commandées (VEX,
  « L'homme-chat »).

### 5.2 Le village (`village`)

<!-- ascii:village -->
```text
village : 56 × 40 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50
    0 
         H########HHH#######HHHHHHHHH        HHHHHHHHHHHHHHHHH
      www.########...#######..#####..^^^FF^^^..######..#####..
      www.#grange#...#cafe##..#mai#..^^^^^^^^..#lima#..#cha#..
      www.########.D.#######..#G###..^^^^^^^^..######..#####..
   10 www::::::::::D::::*::::::G::::::::::::::::::*:::::::::::
      www:::::::::::::::::::::::::::::::::::::::::::::::@::::>
      www:::::::::::::::::::::::::::::::::::::::::::::::::::::
      www...........::::..BBBB==========....::::..............
      www...........::::..=========II===....::::..............
   20 www...........::::..===JJJJ=======....::::..............
      wMMM..#######.::::..===JJJJ=======....::::..####..####..
      wMMM..#chaum#.::::..BBBB=======EEEEEE.::::..#ch#..#ap#..
      www.::#######::::::::::::::::::EEEEEE:::::::####::......
      www.::::::::::::::::::::::::::::::::::::::::::::::......
   30 www,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^^KK^^
      www,,,LLLL,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,^^^^^^
      wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
      wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
```
Légende des lettres : `A` edge_waterfall ; `B` fence_wattle ; `C` wall_lantern ; `D` hanging_sign_key ; `E` laundry_line ; `F` bench_stone ; `G` flower_pots ; `I` haystack ; `J` cart_hay ; `K` beehives ; `L` washing_trough ; `M` firewood_pile.
<!-- /ascii:village -->

- **Taille** 56 × 40 m ; **bornes** `Rect2(10, 9, 36, 23)`. **Composition (original)** : une
  rue est-ouest ; au nord, une rangée de maisons tournées vers elle, **le vide derrière elles**
  (on le voit entre les maisons et depuis le belvédère) ; au sud, une seconde rangée basse, des
  jardins, la rivière et le lavoir ; la rivière tombe du bord en cascade à l'ouest.
- **Bâtiments** (façades livrées ou du cahier) : `village_barn` (x 4 → 12), **`cafe`** (livré,
  x 15 → 22, porte à clochette `anim/cafe_door_bell`), `village_house_stone` (x 24 → 29),
  **`limashenka_house`** (livrée, x 41 → 47, volets clos qui se rouvrent le jour 11),
  `cottage_thatch_a` (x 49 → 54) ; seconde rangée `cottage_thatch_b` (x 6 → 13, z 22 → 27),
  `cottage_thatch_c` (x 44 → 48), appentis `village_shed` (x 50 → 54). Les façades du cahier n° 3
  ont des fenêtres éteintes, que la nuit allume (`window_lit_*`, lot N).
- **Paliers** : rue et jardins à 0 ; le belvédère, un ressaut de rocher à +1 (31 → 39 ;
  3,5 → 9) avec un banc de pierre ; la rivière à −0,5.
- **Grands décors** : garde-fou bas au bord (`edge_parapet`, livré) ; cascade du bord
  (`anim/edge_waterfall`) ; meule (`haystack`), charrette de foin (`cart_hay`), ruches
  (`beehives`), lavoir (`washing_trough`), clôtures tressées (`fence_wattle`), corde à linge
  (`laundry_line`, premier plan), bûches.
- **Kits** : rue (`cart_ruts`, `hay_scatter`, `pebbles_*`, `flower_pots`, `window_box`) ;
  jardins (`garden_bed`, `vegetable_patch`, `scarecrow`, `watering_can`) ; bord de l'île
  (`edge_rocks_a/b`, `edge_grass`, `edge_roots`) ; sud (`fg_bush`, `fg_grass`, premier plan).
- **Places** : `devant_cafe` (13 → 25, 10 → 15), `belvedere` (32 → 38,5 ; 5,5 → 8,5). **Points** :
  `cafe_porte`, `cafe_terrasse`, `limashenka_porte`, `belvedere_vue`, `cascade_vue`, `lavoir`,
  `ruche`.
- **Sorties** : `vers_entrepot` (est) ; `porte_cafe` → `cafe`, « Entrer » ; `porte_limashenka` →
  `maison_limashenka`, « Entrer » (fermée hors du jour 11 : « La maison est close. »).
- **Lumière** : le jour ; le soir, les fenêtres du café et la lanterne à cristal de sa porte.
- **Vue au nord** : le vide et la mer de nuages entre les maisons, des îles lointaines
  (`distant_island_*`), la cascade qui se perd dans les nuages.
- **Densité** : 70 à 100 éléments par écran ; habitants (VIE.md, section 2.6).

```plan
carte village 56 40 dehors
nom "Le village"
region village
sol grass 0 0 56 40
sol path_dirt 0 10 56 15.5
sol path_dirt_b 4 27 50 31
sol path_dirt_b 14 15.5 18 27
sol path_dirt_b 38 15.5 42 27
sol garden_soil 20 17 34 25
sol grass_dry 0 31 56 40
sol stream_bed 0 3 3 37
sol stream_bed 3 34 56 37
sol rock 31 3.5 39 9
palier 1.0 31 3.5 39 9
palier -0.5 0 3 3 37
palier -0.5 3 34 56 37
rampe 33 9 37 11 1.0 0 S
# --- le bord de l'île : vide au nord, garde-fou bas (VEX : « au bord de l'île ») ---
vide 0 0 56 3
bord parapet 3 3 31 3.5 0.7
bord parapet 39 3 56 3.5 0.7
eau 0 3 3 37
eau 3 34 56 37
decor edge_waterfall 1.5 2.0 3 1 0 libre
# --- rangée nord : les maisons tournées vers la rue, le vide derrière (original) ---
bati grange 4 3.5 12 9.5 7 village_barn
bati cafe 15 3.5 22 9.5 7.5 cafe
bati maison_pierre 24 4 29 9 6 village_house_stone
bati limashenka 41 4 47 9 6 limashenka_house
bati chaumiere_est 49 4 54 9 5.5 cottage_thatch_a
decor bench_stone 35 4.6 1.6 0.5 0.6
decor fence_wattle 32 3.9 1.8 0.3 0.9 libre
decor wall_lantern 17 9.6 0.4 0.2 0.6 libre
decor flower_pots 25.6 10.0 0.7 0.5 0.6
decor hanging_sign_key 13.5 9.9 0.4 0.3 2.2 libre
# --- seconde rangée, basse (original) ---
bati chaumiere_longue 6 22 13 27 5 cottage_thatch_b
bati chaumiere_penchee 44 23 48 27 5 cottage_thatch_c
bati appentis 50 22 54 25 3.5 village_shed
decor haystack 30 19 2 1.6 1.6
decor cart_hay 25 22.5 3 1.5 2
decor beehives 53 31.4 1.6 0.8 1.0
decor washing_trough 8 32.5 3 1 1.0
decor fence_wattle 22 16.8 4 0.3 0.9
decor fence_wattle 22 25.2 4 0.3 0.9
decor laundry_line 34 26 6 0.3 2.2 libre pp
decor firewood_pile 2.8 24 2 0.8 1.2
# --- bord sud, bas (premier plan) ---
bord haie 0 38 56 40 1.5 pp
bord foret 50 31 56 34 6 pp
# --- chemins et places ---
chemin rue 4 4;12.5 55;12.5
chemin ruelle_ouest 3 16;14 16;29
chemin ruelle_est 3 40;14 40;29
chemin chemin_bas 3 5;29 49;29
place devant_cafe 13 10 25 15
place belvedere 32 5.5 38.5 8.5
# --- sorties ---
sortie vers_entrepot 55.4 10.5 56 14.5 entrepot from_village ""
sortie porte_cafe 17.8 9.5 19.2 10.1 cafe from_village "Entrer"
sortie porte_limashenka 43.3 9 44.7 9.6 maison_limashenka from_village "Entrer"
marqueur Spawn 50 12.5 O
marqueur from_entrepot 53 12.5 O
marqueur from_cafe 18.5 12 S
marqueur from_maison_limashenka 44 11.5 S
point cafe_porte 18.5 11
point cafe_terrasse 22.5 13
point limashenka_porte 44 10.6
point belvedere_vue 35 6.2
point cascade_vue 5 12.5
point lavoir 8 30.4
point ruche 53 29.6
lumiere lanterne_cafe 17 9.6 2.0 cristal
lumiere fenetres_cafe 18.5 9.5 2.0 fenetres
```

### 5.3 Le café (`cafe`) et la maison Limashenka (`maison_limashenka`)

<!-- ascii:cafe -->
```text
cafe : 12 × 10 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10
    0 
      
        +--------------+----+
        |...BBBBsalle..|III.|
    2   |..............|arri|
        |..CCCCCC......:....|
        |..CCCCCC......:....|
        |..............:....|
    4   |..............|....|
        |.EE.....EE....|....|
        o.EED.AA.EED...|KKK.|
        |.DDD.AA.DDD...|KKK.|
    6   |.FFD....FFD...|KKK.|
        |.FF.....FF....|....|
        |..............|....|
        |GGG...........|JJJ.|
    8   |GGG....@......|JJJ.|
        |..............|JJJ.|
        +------==------+----+
                v
```
Légende des lettres : `A` crystal_pendant ; `B` cafe_bottle_shelf ; `C` cafe_counter ; `D` cafe_table_heavy ; `E` chair_wood ; `F` chair_wood_back ; `G` cafe_drinkers_table ; `I` pantry_cupboard ; `J` sacks_vegetables ; `K` crates_barrels.
<!-- /ascii:cafe -->

| Pièce | Cotes (m) | Mobilier (images) | À examiner |
| --- | --- | --- | --- |
| **Salle du café** | 7,5 × 8 | comptoir `cafe_counter` (cafetière de cuivre, réchaud de cristal) et vitrine `cafe_cake_case` ; étagères `cafe_bottle_shelf` derrière ; deux tables `cafe_table_heavy` et leurs chaises `chair_wood` ; la table des buveurs `cafe_drinkers_table` ; menu à la craie `wallitem_menu_cafe` ; suspension à cristal | le menu (dessins de tasse, de chope, de gâteau) ; la clochette |
| **Arrière-boutique** | 2,5 × 8 | rideau rayé `door_backroom` ; garde-manger, sacs, caisses | « Réservé au personnel » (le serveur y prend les jus) |

Sortie au sud (mur coupé) vers `village`, `from_cafe` ; points `comptoir`, `table_fees` (la table
des trois aînées, jour 9), `table_buveurs`, `arriere`. **Bornes** : la pièce entière.

<!-- ascii:maison_limashenka -->
```text
maison_limashenka : 10 × 8 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10
    0 
      
        +----+----------+
        |entr|BBBsalon..|
    2   |....|...CCC....|
        |....|...CCC.EEE|
        |....|.AAAAAAEEE|
        |....:.AAAAAAA..o
    4   |....:.AAAAAAA..|
        |....:.ADDDDAA..|
        |....|.ADDDDAAFF|
        |....|..DDDD..FF|
    6   |.@..|..........|
        |....|..........|
        +-==-+----------+
          v
```
Légende des lettres : `A` rug_salon ; `B` display_cabinet ; `C` toolbox_gears ; `D` sofa_salon ; `E` armchair_sheeted ; `F` side_table_salon.
<!-- /ascii:maison_limashenka -->

| Pièce | Cotes (m) | Mobilier (images) | À examiner |
| --- | --- | --- | --- |
| **Vestibule** | 2,5 × 6 | patères `wallitem_coat_hooks` | — |
| **Salon** | 5,5 × 6 | **horloge `wallitem_clock_limashenka`** (fermée), puis `_open` (engrenages et peigne doré) pendant la réparation, puis le balancier qui va (`anim/clock_limashenka_swing`) ; boîte à outils `toolbox_gears` ; canapé `sofa_salon` ; fauteuil sous un drap `armchair_sheeted` ; vitrine de bibelots `display_cabinet` (boîtes à tabac) ; guéridon ; portrait de famille ; tapis `rug_salon` ; volets `window_shutters` | l'horloge ; le portrait (une mère et son petit) |

Points `horloge` (Willem au travail), `rami`, `canape`. Maison fermée depuis le deuil (draps sur
les meubles, **original**).

```plan
carte cafe 12 10 dedans
nom "Le café du village"
region village
piece salle 1 1 8.5 9 floor_terracotta wall_panel_dark "salle"
piece arriere 8.5 1 11 9 floor_planks_worn wall_plaster_worn "arrière"
porte salle arriere 8.5 3.0 1.2 door_backroom
porte salle dehors 4.75 9 1.4 door_room
meuble cafe_bottle_shelf 4.0 1.45 2 0.6 2.0
meuble cafe_counter 4.0 3.0 3 0.8 1.2
objet cafe_cake_case 4.8 3.0
mural wallitem_menu_cafe salle N 6.8 1.2 0.8
fenetre salle O 5.0 window_cross_small 0.8
meuble cafe_table_heavy 2.6 5.6 1.2 1.0 0.8
meuble chair_wood 2.6 4.85 0.5 0.5 1.0
meuble chair_wood_back 2.6 6.35 0.5 0.5 1.0
meuble cafe_table_heavy 6.2 5.6 1.2 1.0 0.8
meuble chair_wood 6.2 4.85 0.5 0.5 1.0
meuble chair_wood_back 6.2 6.35 0.5 0.5 1.0
objet juice_glasses 6.2 5.6
meuble cafe_drinkers_table 2.2 8.0 1.6 0.9 0.8
meuble crystal_pendant 4.4 5.6 0.8 0.3 0 libre
meuble pantry_cupboard 9.75 1.45 1.1 0.6 2.0
meuble sacks_vegetables 9.75 8.2 1.2 0.7 0.7
meuble crates_barrels 9.75 5.6 1.2 1.0 1.2
sortie vers_village 4.05 9 5.45 10 village from_cafe ""
marqueur Spawn 4.75 8.2 N
marqueur from_village 6.8 7.8 N
point comptoir 4.0 4.1
point table_fees 7.6 5.6
point table_buveurs 3.4 7.2
point arriere 9.75 3.6
lumiere suspension 4.4 5.6 2.2 cristal
lumiere comptoir 4.0 3.0 1.2 cristal
```


```plan
carte maison_limashenka 10 8 dedans
nom "La maison Limashenka"
region village
piece vestibule 1 1 3.5 7 floor_planks_worn wall_plaster_worn "entrée"
piece salon 3.5 1 9 7 floor_planks_worn wall_wallpaper_floral "salon"
porte vestibule salon 3.5 4.0 1.2 door_room
porte vestibule dehors 2.25 7 1.2 door_room
mural wallitem_coat_hooks vestibule O 3.0 0.9 1.2
mural wallitem_clock_limashenka salon N 6.2 0.9 0.8
mural wallitem_family_portrait salon N 8.0 1.4 0.6
fenetre salon E 3.5 window_shutters 1.2
meuble display_cabinet 4.5 1.4 1.2 0.5 1.9
meuble toolbox_gears 6.2 2.6 0.8 0.5 0.4
meuble sofa_salon 6.0 5.2 2.0 0.9 1.0
meuble armchair_sheeted 8.2 3.0 1.0 0.9 1.05
meuble side_table_salon 8.3 5.5 0.6 0.5 0.7
meuble rug_salon 6.3 4.3 3 2 0 libre
sortie vers_village 1.65 7 2.85 8 village from_maison_limashenka ""
marqueur Spawn 2.25 6.0 N
marqueur from_village 2.25 6.0 N
point horloge 6.2 3.6
point rami 8.0 4.4
point canape 6.0 6.25
lumiere fenetre 9 3.5 1.2 jour
```

## 6. Le port (`port`, `transport_garde`, `barocupot`)

### 6.1 Ce que dit l'œuvre

- La rue du port, au bord du vide, porte le panneau usé par les vents violents, aux flèches
  rouges (V1, « L'Homme sans Marque ») ; le port garde ce qu'il faut aux dirigeables ; on s'y tient
  au bord du vide et l'on voit, sous quelques nuages, la surface grise (V1, « Entrepôt de fées »).
- Le transport de la Garde descend d'au-dessus de la mer de nuages précédé d'une lumière si forte
  qu'on ne voit pas sa silhouette ; il est petit ; l'amarrage fait un lourd bruit de métal ; une
  passerelle ; **trois bras d'ancrage** qui se fixent de l'arrière vers l'avant ; deux pales de
  rotor qui ralentissent ; la chaudière enchantée qui se tait ; la trappe qui s'ouvre sous la
  pression ; le lézard qui se fait petit pour sortir (même chapitre).
- Rampe, sifflet à vapeur, charrettes de sacs qui filent sur l'aire-port (V2, « Le chemin du
  retour… ») ; une colline toujours ventée juste à côté, d'où l'on voit tout arriver (V3, « La
  Fille sans visage ») ; une pluie fine au crépuscule (V1).
- Le Barocupot : au moins deux ponts, une petite salle du conseil de guerre où l'on est à l'étroit
  avec un lézard deux fois plus grand qu'une fée ; une serviette prêtée ; un thé chaud, amer et
  piquant, dans des tasses minuscules (V1, « La fille errante et le lézard volant »).

### 6.2 Le port (`port`)

<!-- ascii:port -->
```text
port : 70 × 40 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50        60        70
    0 
      
      HHH#####H####HHHHHHHHHHD  G  D   GG DHHHHHHHHH##########HH
      ===#####=####==II==FF==D==G==D=B*GG=D==EE=JJJ=##########,,,,,,,,,,U,,,
      ===#bur#=#ca#==II====CC===================JJJ=##########,,,,,,,,VV,,,,
   10 ===#####=####==KKK============================#hangar###,,,,,,,,VV,,,,
      ====================LL================LL======##########,,,,,,,,,,,,,,
      ________________________________________________________,,,,,,,,,,,,,,
      <___@___________________________________________________,,,,,,,,,,,,,,
      ________________________________________________________,,,,,,,,,,,,,,
   20 _____MM__________NNNN__________________NN_____________::::::::::::::::
      ______________________________________________________::::::::::::::::
      _______________________________________________QQ_____::::::::::::::::
      ___________SS_____________PPPP___RR____________QQ_____::::XXXXXXXXXXXX
      __________________________PPPP________________________::::::::::::::::
   30 ......................................................................
      .....................................................................>
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^....^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
Légende des lettres : `A` garde_transport_side ; `B` gangway ; `C` rope_coil ; `D` mooring_arm_open ; `E` steam_whistle ; `F` capstan ; `G` bollard ; `I` crates_barrels ; `J` crystal_crates ; `K` cargo_cart_a ; `L` dock_lamp ; `M` signpost_port ; `N` wind_fence ; `P` cargo_cart_b ; `Q` hand_cart ; `R` sacks_pile ; `S` pallet_sacks ; `U` wind_sock ; `V` bench.
<!-- /ascii:port -->

- **Taille** 70 × 40 m ; **bornes** `Rect2(10, 6, 50, 17)`. **Composition** : au nord, le **vide**
  et le poste d'amarrage ; le quai de tôle (z 5 → 14) ; la rue du port (z 14 → 20) ; au sud,
  l'aire-port des charrettes ; à l'est, la colline ventée (+1, +2, +3) et la route de la ville qui
  la contourne par le sud.
- **Le navire au nord du quai** (`docs/REFONTE.md`, 3.1) : le transport de la Garde s'amarre
  **de flanc**, son flanc (`ships/garde_transport_side`, 16 × 7 m, **à confirmer** par E7) face à
  la caméra, de x 22 à 38, la quille sous le niveau du quai ; trois bras `mooring_arm_open`
  (x 23,5, 29,5, 36,5 ; animation `anim/mooring_arm_clamp`) ; la passerelle `gangway` (x 32,5) ; la
  trappe ronde (`anim/garde_transport_hatch`) au droit de la passerelle ; rotors
  (`anim/garde_transport_rotor`). **En dehors des scènes, le poste est vide** : le passeur ne
  vient que la nuit d'arrivée, et l'île n'a pas de ligne publique (V1).
- **Bâtiments** : `harbor_office` (livré, x 3 → 8), la cabane du gardien `port_house_b` (x 9 → 13),
  le hangar `port_hangar` (livré, x 46 → 56), tous sur le quai, **au nord de la rue** : rien de haut
  au sud d'où l'on marche.
- **Grands décors** : garde-corps `edge_railing` (livré) au bord, sauf au poste ; sifflet à vapeur
  `steam_whistle` (vapeur `anim/furnace_steam`) ; cabestan `capstan` ; bittes `bollard` ; caisses
  `crates_barrels`, `crystal_crates` ; charrettes `cargo_cart_a/b`, `hand_cart` ; brise-vent
  `wind_fence` ; **le panneau aux flèches rouges** `signpost_port` (6 ; 21,2) : la flèche de droite
  (est) montre de petites maisons de pierre (la ville), celle de gauche un bâtiment de bois dans
  les arbres (l'entrepôt) ; sur la colline, la manche à air `wind_sock` (`anim/windsock_wave`) et
  un banc.
- **Paliers** : quai et rue à 0 ; colline ventée +1 → +3 (talus `cliff/wall_earth_1m` au sud et à
  l'ouest) ; au-delà du bord, la falaise (`cliff/lip`, `cliff`) et la mer de nuages.
- **Kits** : quai (`rope_coil`, `cargo_net`, `chain_pile`, `oil_stain`, `rust_streak`,
  `drain_grate`, `fuel_barrels`) ; rue (`cobble`, `cart_ruts`, `puddle_*` sous la pluie) ;
  aire-port (`sacks_pile`, `pallet_sacks`, `luggage`) ; colline (`wind_grass_a/b`, `grass_tuft`,
  `rock_small_*`) ; sud (`fg_*`, premier plan).
- **Places et points** : `accostage` (24 → 37, 7 → 13 : Willem attend, Limeskin jette les
  épées) ; `aire_port` ; points `bord_du_vide` (17,5 ; 6,3 : Willem seul au bord), `accostage`,
  `panneau`, `guichet`, `colline_sommet`, `charrettes`.
- **Sorties** : `vers_sentier` (ouest) ; `vers_ville` (est, la route de 2 000 marmer) → `ville_marche`,
  `from_port` ; `passerelle` → `transport_garde`, « Monter à bord » (seulement quand un navire est à
  quai et que l'histoire le permet ; à l'acte 1, jamais).
- **Lumière** : deux lanternes de quai à cristal `dock_lamp` (**original**), la fenêtre du bureau ;
  le **projecteur du navire** (`sky/ship_searchlight`) qui perce les nuages à la descente ; au
  crépuscule du jour 7, pluie fine (`anim/rain_drizzle`, flaques `anim/puddle_rain_a`).
- **Vue au nord** : le vide, la mer de nuages, la surface grise par les trouées, des îles
  lointaines et des dirigeables de passage (`airship_far_*`) ; le navire à quai.
- **Densité** : 60 à 100 éléments par écran ; dockers et employés (VIE.md).

```plan
carte port 70 40 dehors
nom "Le port"
region port
sol cobble 0 14 58 20
sol metal 0 5 58 14
sol gravel 0 20 58 30
sol grass_dry 56 5 70 30
sol path_dirt 54 20 70 34
sol grass 0 30 70 40
palier 1.0 58 5 70 27
palier 2.0 61 5 70 22
palier 3.0 63 5 70 16
rampe 58 22 61 26 2.0 1.0 O
rampe 61 16 64 20 3.0 2.0 O
# --- le vide au nord : les navires s'amarrent au nord du quai (REFONTE, 3.1) ---
vide 0 0 70 5
bord rambarde 0 5 23 5.4 1.1
bord rambarde 37 5 58 5.4 1.1
decor garde_transport_side 30 2.6 16 1 7 libre
decor mooring_arm_open 23.5 5.9 1 0.8 4
decor mooring_arm_open 29.5 5.9 1 0.8 4
decor mooring_arm_open 36.5 5.9 1 0.8 4
decor gangway 32.5 6.4 2 1.6 1.1 libre
decor steam_whistle 40 6.4 0.8 0.6 2
decor capstan 20 6.6 1 0.9 0.9
decor bollard 26.5 5.9 0.5 0.5 0.6
decor bollard 34 5.9 0.5 0.5 0.6
decor crates_barrels 16 8 2 1.5 1.5
decor crystal_crates 43.5 8.5 2 1.2 1.2
decor cargo_cart_a 16.5 11.2 3 1.6 1.8
decor rope_coil 22 9 0.8 0.8 0.4 libre
decor dock_lamp 21 12.6 0.5 0.5 3.2
decor dock_lamp 39 12.6 0.5 0.5 3.2
# --- le bureau du port et la cabane du gardien, sur le quai (cahiers n° 2 et 3) ---
bati bureau_port 3 5.4 8 10.4 6 harbor_office
bati cabane_gardien 9 5.4 13 10.4 6.5 port_house_b
bati hangar 46 5.4 56 13.4 7 port_hangar
# --- la rue du port et l'aire-port (V1 ; V2) ---
decor signpost_port 6 21.2 1.6 0.4 3 pp
decor wind_fence 18 21 2 0.3 1.4
decor wind_fence 20 21 2 0.3 1.4
decor wind_fence 40 21 2 0.3 1.4
decor cargo_cart_b 28 28.5 2.5 1.2 1.4
decor hand_cart 48 26 1.6 1 1.2
decor sacks_pile 34 27 1.6 1 1
decor pallet_sacks 12 27 1.6 1.2 1.1
# --- la colline toujours ventée, à côté de l'aire-port (V3, « La Fille sans visage ») ---
decor wind_sock 66.5 7 0.4 0.4 4
decor bench 65 10 1.6 0.5 0.9
bord falaise 58 27 70 28 1.0
# --- bords ---
bord foret 0 34 54 40 8 pp
bord foret 58 34 70 40 8 pp
bord foret 54 37 58 40 8 pp
# --- chemins, places ---
chemin rue_du_port 5 1;17 57;17
chemin route_ville 4 55.5;18 55.5;31 62;32 69;32
chemin montee_colline 3 57;20 60;24 63;18 65;12
place accostage 24 7 37 13
place aire_port 22 22 46 25
# --- sorties ---
sortie vers_sentier 0 14 0.6 20 sentier from_port ""
sortie vers_ville 69.4 30 70 34 ville_marche from_port ""
sortie passerelle 31.5 6.6 33.5 7.2 transport_garde from_port "Monter à bord"
marqueur Spawn 4 17 E
marqueur from_sentier 2.5 17 E
marqueur from_ville_marche 67.5 32 O
marqueur from_transport_garde 32.5 9.5 S
point bord_du_vide 17.5 6.3
point accostage 30 9.5
point panneau 6 19.5
point guichet 5.5 11.6
point colline_sommet 65 12.2
point charrettes 30 23.5
lumiere lampe_quai_1 21 12.6 3.2 cristal
lumiere lampe_quai_2 39 12.6 3.2 cristal
lumiere bureau 5.5 10.4 2.0 fenetres
lumiere projecteur_navire 30 0 12 projecteur
```

### 6.3 À bord : le transport de la Garde (`transport_garde`) et le Barocupot (`barocupot`)

<!-- ascii:transport_garde -->
```text
transport_garde : 20 × 11 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0                   10                  20
    0 
      
          HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
          ===EE======DDDD=====CCCCCCCC====
          ===EE======DDDD=====CCCCCCCC====
          ===========DDDD=====CCCCCCCC====
          ================================
          ================================
          =====FFFF=======================
          =====FFFF=======@===============
          ================================
          HHHHHHHHHHHHHH====HHHHHHHHHHHHHH
      
      
      ========================================
      ========================================
      ========================================
      ========================================
      ========================================
      ========================================
   10 ========================================
      ====================v===================
```
Légende des lettres : `A` gangway ; `B` garde_transport_rotor ; `C` deck_bridge ; `D` deck_crates_lashed ; `E` deck_vent ; `F` deck_hatch.
<!-- /ascii:transport_garde -->

- **Le pont du transport** (20 × 11 m, dehors) : le pont vu de dessus (`ships/garde_transport_deck`,
  **à confirmer**) de x 2 à 18, proue à l'est ; bastingage `deck_railing` ; passerelle au sud vers
  le quai ; passerelle de commandement `deck_bridge` ; caisses arrimées `deck_crates_lashed` ;
  manche à air `deck_vent` ; écoutille `deck_hatch` ; rotors en bout de bras. Pont étroit :
  passages de 1,2 m (instruction `passage 1.2`). **À l'acte 1, on n'y monte pas** (V1 : seuls les
  guerriers entrent là où se tiennent les guerriers) ; la carte sert aux actes suivants.

<!-- ascii:barocupot -->
```text
barocupot : 14 × 8 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10
    0 
      
        +--o-------o--+---------+
        |....BBBB..CCC|..DDsas..|
    2   |.BB.AAAA.....|..DD.....|
        |.BB.AAAA.....|...*.....|
        |....AAAA.....|.........|
        |conseil......|.........|
    4   |.............|.........|
        |.............|.........|
        +------=------+----=----+
        |coursive...............|
    6   |......@................|
        |.......................|
        +-----------------------+
      
```
Légende des lettres : `A` war_table ; `B` war_chair ; `C` map_cabinet ; `D` ship_ladder.
<!-- /ascii:barocupot -->

- **La salle du conseil de guerre** (6,75 × 3,75 m utiles) : la table aux cartes `war_table`, trois
  chaises lourdes `war_chair` (Limeskin reste debout, la tête sous le plafond), le petit service
  `tea_set_tiny` et sa serviette pliée, deux hublots `window_porthole` sur les nuages, l'aile
  peinte `wallitem_garde_emblem`, le porte-voix `wallitem_speaking_tube`, le meuble à cartes
  `map_cabinet` ; le **sas** et l'échelle `ship_ladder` vers le pont ; la **coursive** au sud. Sols
  et murs : `floor_ship_planks`, `wall_ship_plate`, `wallcut_ship`, portes `door_bulkhead`.
- **On y arrive par une scène** (fondu au blanc depuis la chute dans les nuages, ACTE1.md jour 8)
  et l'on en repart par l'échelle : « Remonter sur le pont » ouvre la scène du retour en volant
  (`entrepot`, `from_barocupot`). Points `conseil_chtholly`, `conseil_limeskin`.
- **Lumière** : jour gris des nuages par les hublots, lampe à cristal ; le grondement des fours
  enchantés (son).

```plan
carte transport_garde 20 11 dehors
nom "Le transport de la Garde"
region port
passage 1.2
echelle 0.5 0.5
sol metal 2 1 18 6
sol metal 0 7 20 11
vide 0 0 20 1
vide 0 6 9 7
vide 11 6 20 7
vide 0 1 2 6
vide 18 1 20 6
bord rambarde 2 1 18 1.4 1.1
bord rambarde 2 5.6 9 6 1.1 pp
bord rambarde 11 5.6 18 6 1.1 pp
decor gangway 10 6.5 2 1 1.1 libre
decor deck_bridge 14 2.2 4 1.4 3
decor deck_crates_lashed 8.5 2.2 1.6 1.2 1.2
decor deck_vent 4 2 0.6 0.6 1.4
decor deck_hatch 5.5 4.4 1.2 0.6 0.4
decor garde_transport_rotor 1.5 3.5 1 1 2 libre
decor garde_transport_rotor 18.5 3.5 1 1 2 libre
sortie vers_port 9 10.4 11 11 port from_transport_garde "Descendre à quai"
marqueur Spawn 10 4.4 N
marqueur from_port 10 4.4 N
point trappe 5.5 3.6
point proue 16.5 4.4
```


```plan
carte barocupot 14 8 dedans
nom "Le Barocupot"
region ciel
piece conseil 1 1 8 5 floor_ship_planks wall_ship_plate "conseil"
piece sas 8 1 13 5 floor_ship_planks wall_ship_plate "sas"
piece coursive 1 5 13 7 floor_ship_planks wall_ship_plate "coursive"
porte conseil coursive 4.5 5 1.2 door_bulkhead
porte sas coursive 10.5 5 1.2 door_bulkhead
fenetre conseil N 2.5 window_porthole 0.6
fenetre conseil N 6.5 window_porthole 0.6
mural wallitem_garde_emblem conseil N 4.5 1.5 0.8
mural wallitem_speaking_tube conseil O 3.0 1.4 0.3
mural wallitem_ship_pipes sas N 12.0 1.6 1.6
meuble war_table 4.5 2.7 2 1 0.8
objet tea_set_tiny 4.5 2.7
meuble war_chair 3.9 1.65 0.6 0.5 1.1
meuble war_chair 5.1 1.65 0.6 0.5 1.1
meuble war_chair 2.6 2.7 0.6 0.5 1.1
meuble map_cabinet 7.2 1.45 1.2 0.5 1.1
meuble ship_ladder 10.0 1.65 1.0 1.0 3.0
sortie echelle 9.5 2.1 10.5 2.6 entrepot from_barocupot "Remonter sur le pont"
marqueur Spawn 4.5 6.0 N
point conseil_chtholly 2.6 3.9
point conseil_limeskin 6.8 3.6
point coursive 7 6
lumiere hublots 4.5 1 1.2 jour
lumiere lampe 4.5 2.7 2.0 cristal
```

## 7. La colline des étoiles (`colline`)

- **Ce que dit l'œuvre** : une petite colline à la périphérie de l'île, au vent calme, à l'air
  limpide, sous une douce lumière d'étoiles, assez près de l'entrepôt pour y aller à pied la nuit
  avec Seniorious ; herbe (V1, « Le ciel étoilé sous le ciel étoilé » ; ill.) ; les 41 talismans
  flottent à environ cinq pas autour d'un petit cristal et tintent comme un métallophone (même
  chapitre). **À ne pas confondre** avec la colline toujours ventée de l'aire-port (V3), posée au
  port.

<!-- ascii:colline -->
```text
colline : 40 × 40 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40
    0 
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      ^^^^........''''''''''''''''........^^^^
      ^^^^........''''''''''''''''........^^^^
      ^^^^........''''''''''''''''..T.....^^^^
   10 ^^^^........'''''''''''CC'''........^^^^
      ^^^^....DDD.'''''''''''CC'''........^^^^
      ^^^^....DDD.''''''''''''''''........^^^^
      ^^^^........''''''''''''''FF........^^^^
      ^^^^........''''''''''''''''........^^^^
   20 ^^^^............................EE..^^^^
      ^^^^.....AA.....................EE..^^^^
      ^^^^.....AA.........................^^^^
      ^^^^........::::::::::::::::........^^^^
      ^^^^........::::::::::::::::.BB.....^^^^
   30 ^^^^..............::::.......BB.....^^^^
      ^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^;;;;;;;;;;;;;;;;@;;;;;;;;;;;;;;;^^^^
      ^^^^^^^^^^^^^^^^^^;;v;^^^^^^^^^^^^^^^^^^
```
Légende des lettres : `A` heather ; `B` tall_grass ; `C` wildflowers_a ; `D` boulder_a ; `E` mossy_rock ; `F` rock_small_a.
<!-- /ascii:colline -->

- **Taille** 40 × 40 m ; **bornes** `Rect2(10, 6, 20, 23)`. La colline est un cap : elle monte du
  sud (entrée depuis l'entrepôt) en trois terrasses (+1, +2, +3, talus `cliff/wall_earth_1m` et
  `cliff/step_rock` face au sud) jusqu'au sommet, qui finit au nord **sur le vide**.
- **Le sommet** : la place `cercle_talismans` (14 → 26, 6 → 18), 12 × 12 m d'herbe rase ; le petit
  cristal au centre (`talismans_centre`, 20 ; 12) ; les talismans (`anim/talisman_float`) sur un
  cercle de 3,5 m ; le point `dos_a_dos` (Willem et Chtholly assis dos à dos) ; `vue_nord` au bord.
- **Grands décors** : l'arbre noueux solitaire `lone_tree` (livré) en (30 ; 9) ; un rocher
  `boulder_a` (où l'on s'assoit, `rocher`) ; herbes hautes, bruyère, fleurs d'automne. Pas de
  belvédère ni de myosotis : c'étaient des inventions de l'ancienne bible.
- **Kits** : herbe (`tall_grass`, `wind_grass_a/b`, `heather`, `wildflowers_*`), rochers
  (`rock_small_*`, `mossy_rock`), lisières est et ouest (`forest_wall_*`), bord (`edge_rocks_*`).
- **Lumière** : de nuit (préréglage `nuit_claire`) ; la lueur du cristal et des talismans. **Vue
  au nord** : la mer de nuages argentée sous les étoiles (`cloud_sea_night`) ; pour la scène, la
  caméra lève les yeux vers le ciel (`sky_night`). **Densité** : 40 à 70 éléments par écran (une
  colline nue, voulue) ; grillons et chouette la nuit.

```plan
carte colline 40 40 dehors
nom "La colline des étoiles"
region colline
sol grass_dry 0 0 40 40
sol grass 4 4 36 32
sol meadow_flowers 12 4 28 20
sol path_dirt_b 12 26 28 30
sol path_dirt_b 18 30 22 40
sol forest_floor 0 32 40 40
palier 1.0 4 4 36 32
palier 2.0 8 4 32 26
palier 3.0 12 4 28 20
rampe 12 30 16 34 1.0 0 S
rampe 24 26 28 29 2.0 1.0 S
rampe 14 20 18 23 3.0 2.0 S
# --- la pointe de l'île : le vide au nord (V1 : « petite colline à la périphérie ») ---
vide 0 0 40 3
bord falaise 0 3 40 4 0.6
bord foret 0 4 4 40 10
bord foret 36 4 40 40 10
bord foret 4 38 17.5 40 9 pp
bord foret 22.5 38 36 40 9 pp
arbre lone_tree 30 9 4 5
decor boulder_a 9.5 14 2 1.5 1.5
decor mossy_rock 33 22 1.5 1 1
decor rock_small_a 27 17 0.6 0.5 0.4
decor heather 10 24 1.5 1 0.5 libre
decor tall_grass 30 30 2 1 0.8 libre
decor wildflowers_a 24 12 1.5 1 0.3 libre
# --- montée et sommet ---
chemin montee 3 20;39 20;35 14;31 14;28 26;28 26;24 16;24 16;19 20;14
place cercle_talismans 14 6 26 18
sortie vers_entrepot 18 39.4 22 40 entrepot from_colline ""
marqueur Spawn 20 36.5 N
marqueur from_entrepot 20 37 N
point talismans_centre 20 12
point dos_a_dos 20 13.2
point vue_nord 20 5.0
point rocher 9.5 15.6
lumiere cristal_reglage 20 12 0.5 cristal
lumiere talismans 20 12 1.5 etoiles
```

## 8. La forêt profonde (`foret_profonde`)

- **Ce que dit l'œuvre** : des bosquets profonds, des fourrés aux petites branches qui percent la
  peau (V1, « Entrepôt de fées ») ; une forêt assez dense où l'eau s'accumule dans des creux
  difficiles à voir, dangereux pour les enfants (V5, épilogue) ; la rivière où l'on puise l'eau du
  bain (V3) ; Chtholly s'y enfuit quand c'est trop (VEX, « Des émotions sans nom ») ; un petit
  animal grimpeur poursuivi par une fillette (V5, épilogue). Le **refuge** de Chtholly est
  **original**.

<!-- ascii:foret_profonde -->
```text
foret_profonde : 80 × 60 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50        60        70        80
    0 ^^^^^^wwww^^^^^^^^^^^^^^^^^^^^^^^^^^^;::^:;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^wwww^^^^^^^^^^^^^^^^^^^^^^^^^^^;::::;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^wwww^^^^^^^^^^^JJJJJJ^^^^^^^^^^;::@:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;wwwwwwwwww;;;JJJJJJ;;;;;;;;;;;::::;;;;;;;;;;;;;;;;;;T;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;wwwwwwwwww;;;;;;;;;;;;T;;;;;;;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
   10 ^^^^^^;;wwwwwwwwww;;;;;;;;;;;;;;;;;;;;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;wwwwwwwwww;;;;;;;;;;;;;;;;;;;;::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;;;;;;;;;;;wwwwwwwwwwww;;;;;;;;;;::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;;;;;;;;;;;wwwwwwwwwwww;;;;;;;;;;::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;;;;;;;;;;;wwwwwwwwwwww;;;;;;;;;;::::::;;;;;;;;;;;BBw;;;;;;;;;;;;;;;;^^^^
   20 ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::;;;;;;;;;;;BBw;;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;wwwwwwwwwwwwww::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;wwwwwwwwwwwwww::;;;;;;;;;;;;;;;;;;;KK;;;;;;;;;^^^^
      ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::CCCCCwwwwwwwwwwwww;;;;;KK;;;;;;;;;^^^^
      ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::CCCCCwwwwwwwwwwwww;;;;;;;;;;;;;;;;^^^^
   30 ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::^^^^
      ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;II;;;;;;;::::::::::::::::wwwwwwwwwwwwwwwwwwww
      ^^^^^^;;;;;;;;EEEE;;;;;;;;;;;;;;;;;II;;;;;;;:::::::::LL:::::wwwwwwwwwwwwwwwwwwww
      ^^^^^^;;;;;;;;EEEE;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::^^^^
      ^^^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::^^^^
   40 ^^^^^^;;;;;;;;;;;DD;;;;;;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::T:::::^^^^
      ^^^^^^;;;;;;;;;;;DD;;;;;;;;;AAA;;;;;;;;;;;;;::::::::::::::::::::::::::::::::^^^^
      ^^^^^^;;;;;;;;;;;;;;;;;;;;;;www;;;;;;;;;;;;;::::::::::::::::::::::::::::::::::::
      ^^^^;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::::::::::::>
      ^^^^;;;;;;;;;;;;;;;;~~~~~~~~;;;;;;;;;;;;;;;;;;;;GGGG;;;;;;;;;;;;;;;;;;;;;;;;^^^^
   50 ^^^^;;;;;;;;;;;;;;;;~~~~~~~~;;;;;;;;;;;;;;;;;;;;GGGG;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^;;;;;;;;;;;;;;;;~~~~~~~~;;;;;;;;;FFFFFF;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^;;T;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;FFFFFF;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
Légende des lettres : `A` hidden_pool_a ; `B` hidden_pool_b ; `C` log_bridge_b ; `D` mushroom_cep ; `E` refuge_oak ; `F` fallen_pine ; `G` thicket_a ; `I` thicket_b ; `J` grove_dense ; `K` rowan ; `L` log_hollow.
<!-- /ascii:foret_profonde -->

- **Taille** 80 × 60 m ; **bornes** `Rect2(10, 9, 60, 43)`. On entre par le nord (depuis
  l'entrepôt) et l'on descend vers le sud, la rivière en travers ; un sentier mène à l'est vers la
  montagne, trois branches mènent au refuge (ouest), à la clairière des cerfs (nord-est) et à la
  souille (sud-ouest).
- **Paliers** : sol à 0 ; lit de la rivière à −0,5 ; deux ressauts rocheux à +1 (nord-est,
  sud-ouest).
- **Grands décors** : **le refuge** `refuge_oak` (chêne creux de 8 × 10 m, cahier n° 3) en
  (16 ; 36), son creux tourné vers le sud ; place `refuge` devant ; le gué et son tronc
  `log_bridge_b` ; sapin immense `tree_old_pine`, chênes `oak_c`, `oak_d`, hêtre `beech_a` ;
  bosquet `grove_dense` ; sapin abattu `fallen_pine` ; sorbier `rowan` ; tronc creux `log_hollow` ;
  **mares cachées** `hidden_pool_a/b` (eau au ras, sous les feuilles).
- **Kits** : sous-bois (`forest_wall_deep`, `fern_*`, `nettles`, `mushroom_*`, `needles_patch`,
  `leaves_*`, `roots_a/b`) ; fourrés (`thicket_*`, `bramble_hedge`) ; rivière (`river_bank`,
  `pebbles_*`, `anim/river_rapids`) ; **tout arbre à moins de 12 m au sud d'un sentier est un
  panneau de premier plan**.
- **Places** : `refuge` (10 → 22, 38 → 46), `clairiere_cerfs` (54 → 72, 8 → 18),
  `clairiere_loups` (62 → 74, 50 → 55). **Points** : `refuge_creux`, `mare_cachee`, `gue`,
  `cerfs`, `souille`, `loups`, `lisiere_riviere`.
- **Sorties** : `vers_entrepot` (nord) ; `vers_montagne` (est) → `montagne`, `from_foret_profonde`.
- **Lumière** : pénombre verte et or ; rais de lumière (`light_shaft_a/b`) ; au crépuscule, bleu
  sombre (les loups, VIE.md). **Vue au nord** : la lisière et le grand sapin. **Densité** : 90 à
  120 éléments par écran.

```plan
carte foret_profonde 80 60 dehors
nom "La forêt profonde"
region foret_profonde
sol forest_floor 0 0 80 60
sol leaf_litter 30 30 70 50
sol moss 8 34 24 46
sol path_overgrown 38 0 42 14
sol path_overgrown 40 14 46 30
sol path_overgrown 44 30 80 48
sol mud 20 48 28 54
sol stream_bed 60 32 80 36
sol stream_bed 44 26 60 30
sol stream_bed 30 22 44 26
sol stream_bed 18 14 30 20
sol stream_bed 8 6 18 14
sol stream_bed 6 0 10 6
palier -0.5 60 32 80 36
palier -0.5 44 26 60 30
palier -0.5 30 22 44 26
palier -0.5 18 14 30 20
palier -0.5 8 6 18 14
palier 1.0 52 0 80 8
palier 1.0 0 46 12 60
# --- la rivière (V3 : on y puise l'eau du bain) ; mares cachées (V5, épilogue) ---
eau 60 32 80 36
eau 44 26 60 30
eau 30 22 44 26
eau 18 14 30 20
eau 8 6 18 14
eau 6 0 10 6
eau 28 42 31 44.5
eau 57 19.5 59.5 21
decor hidden_pool_a 29.5 43.2 2 1.5 0 libre
decor hidden_pool_b 58.2 20.2 1.5 1.2 0 libre
decor log_bridge_b 44.5 28 4 1 0.5 libre
# --- bords : forêt dense tout autour ---
bord foret 0 0 6 46 11
bord foret 10 0 37 6 11
bord foret 43 0 80 4 11
bord foret 76 4 80 32 10
bord foret 76 36 80 44 10
bord foret 76 49 80 60 10 pp
bord foret 0 56 76 60 10 pp
bord foret 0 46 4 56 10
# --- le refuge de Chtholly (original, VEX : elle s'enfuit dans la forêt) ---
decor refuge_oak 16 36 3 2 10
place refuge 10 38 22 46
# --- clairière des cerfs, souille, meute (faune, original) ---
place clairiere_cerfs 54 8 72 18
place clairiere_loups 62 50 74 55
arbre tree_old_pine 60 5.5 5 12
arbre oak_c 30 8 7 10
arbre oak_d 70 40 7 10
arbre beech_a 6 54 6 9
decor fallen_pine 40 54 6 1.2 1.6
decor thicket_a 50 50 2.5 1 1.6
decor thicket_b 36 34 2 1 1.4
decor grove_dense 24 6 6 2 9
decor rowan 66 26 1 1 5
decor log_hollow 54 35 2 0.8 0.8
decor mushroom_cep 18 42 0.5 0.5 0.3 libre
# --- sentiers ---
chemin sentier 3 40;1 40;12 43;22 44.5;28 50;38 64;46 79;46.5
chemin vers_refuge 3 43;22 32;30 20;40
chemin vers_cerfs 3 40;12 52;12 62;13
chemin vers_souille 3 50;38 36;46 25;51
sortie vers_entrepot 37 0 43 0.6 entrepot from_foret_profonde ""
sortie vers_montagne 79.4 44.5 80 48.5 montagne from_foret_profonde ""
marqueur Spawn 40 3 S
marqueur from_entrepot 40 3 S
marqueur from_montagne 77.5 46.5 O
point refuge_creux 16 38.6
point mare_cachee 29.5 45.2
point gue 44.5 28
point cerfs 63 13
point souille 24 51
point loups 68 52.5
point lisiere_riviere 52 30.8
```

## 9. Le centre-ville (`ville_haute`, `ville_marche` et six intérieurs)

### 9.1 Ce que dit l'œuvre

- Des **centaines de bâtiments de pierre sur une légère pente**, une atmosphère idyllique, des
  passants qui ne se soucient pas qu'on n'ait pas de traits (V1, « Directeur en carton ») ; on y
  descend de l'entrepôt par un sentier (V5) ; un vent froid (V2).
- Le **snack-bar** du jeune lycanthrope à tête de chien, qui fait sauter sa poêle (V1) ; une
  librairie, un horloger, une salle de projection, un magasin d'accessoires, un café, un boucher
  (V2, « Temps écoulé depuis lors ») ; la **boulangerie** au patron grincheux où travaille
  Lakhesh, le **marché du matin** (V3, « Je suis à la maison ») ; le **café habituel**, la
  librairie au coin de la rue (V3, « Le grand et jeune lézard ») ; un apothicaire **(déduction)**.

### 9.2 La ville haute (`ville_haute`)

<!-- ascii:ville_haute -->
```text
ville_haute : 60 × 60 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50        60
    0 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      ####________######_####_____________#####_########______####
      ####________######_####_____________#####_########______####
      ####________#mais#_#ma#___E_________#mai#_#maison#______####
   10 ______________CC________II________GG____________________####
      <___@___________________________________________________####
      ____________________________________________JJ__________####
      """"""""""""""""""""""""""________""""""""""""""""""""""""""
      """"""""""""""""""""""""""________""""""""""""""""""""""""""
   20 """"""""""""""""""""""""""________""""""""""""""""""""""""""
      """"""""""""""""""""""""""________""""""""""""""""""""""""""
      """"________#####_#######_________"#####"####"######""""""""
      """"________#####_#######__________#####_####_######____""""
      """"________#lib#_#cafe_#__________#sna#_#ac#_#mais#____""""
   30 """"__________*__B____*_______________*_A_______________""""
      """"____________________________________________________""""
      ####"""""""""""""""""""""F________""""""""""""""""""""""####
      ####""""""""""""""""""""""________""""""""""""""""""""""####
      ####""""""""""""""""""""""________""""""""""""""""""""""####
   40 ####""""""""""""""""""""""________""""""""""""""""""""""####
      ####""""""""""""""""""""""________""""""""""""""""""""""####
      ####____________#######___________""""""""""""""""""""""####
      ####______####__#######_____________#####_####_######___####
      ####______#ap#__#salle#_____________#col#_#ma#_#mais#___####
   50 ####_KK___####__#######_____________#####_####_######___####
      ####_KK_____________*__________________________DD_______####
      ####____________________________________________________####
      ####____________________________________________________####
      ####__________________________v_________________________####
```
Légende des lettres : `A` hanging_sign_pan ; `B` hanging_sign_cup ; `C` town_doorsteps ; `D` town_cellar_hatch ; `E` wall_lantern ; `F` street_lamp_double ; `G` town_planter_stone ; `I` town_wall_fountain ; `J` bench_stone ; `K` crate_apples.
<!-- /ascii:ville_haute -->

- **Taille** 60 × 60 m ; **bornes** `Rect2(10, 9, 40, 43)`. **La ville monte vers le nord** par
  trois terrasses (+2, +1, 0) ; la **grand-rue** descend du nord au sud (x 26 → 34), coupée de
  deux volées de marches (`town_stairs_b`, rampes en données) ; chaque terrasse porte une ruelle
  est-ouest devant une rangée de maisons, et **derrière chaque rangée, des jardins clos** (jamais
  un endroit où l'on marche : la règle de caméra). C'est la composition d'*Octopath* : on regarde
  la ville monter, façades au sud, toits étagés.
- **Terrasse haute** (+2) : la rue haute, d'où arrive le chemin de la forêt (ouest) ; `town_house_e`
  (la plus haute, girouette en poisson volant), `house_narrow`, `town_house_a`, `town_house_b` ;
  la fontaine murale `town_wall_fountain` ; la lisière au-dessus de la ville.
- **Terrasse du milieu** (+1), **la rue du café** : la **librairie** `shop_bookshop` (x 12 → 17),
  le **café habituel** `cafe_town` (x 18 → 25, au coin de la grand-rue), le **snack-bar** `shop_snack`
  (x 35 → 40, comptoir ouvert sur la rue, enseigne en poêle `hanging_sign_pan`), le magasin
  d'**accessoires** `shop_accessories` (x 41 → 45), `town_house_f` ; place `carrefour` devant.
- **Terrasse basse** (0) : l'**apothicaire** `shop_apothecary` (x 10 → 14), la **salle de
  projection** `projection_hall` (livrée, x 16 → 23), `house_timber_a`, `town_house_c`,
  `town_house_d` ; la rue basse et le **bas de la ville** (place `bas_de_ville`), d'où l'on descend
  vers la place du marché.
- **Façades à deux paliers** : les maisons du cahier n° 3 ont un socle de 0,5 m (**à confirmer**,
  E2) ; murs de soutènement `cliff/town_retaining_wall` entre les terrasses, muret
  `town_wall_low` des jardins, garde-corps `town_railing` au bord des terrasses.
- **Kits** : rues (`cobble`, `drain_grate`, `cart_ruts`, `town_doorsteps`, `town_cellar_hatch`,
  `window_box`, `flower_pots`) ; jardins (`town_planter_stone`, arbres d'or entre les toits) ;
  lointains au nord (`town_roofs_a/b` au-delà de la lisière, **sans** cacher la grand-rue).
- **Sorties** : `vers_sentier` (ouest, terrasse haute) ; `vers_marche` (sud) ; portes de la
  librairie, du café, du snack et de la salle de projection (« Entrer »). Les autres boutiques sont
  closes à l'acte 1 (invite « Fermé », **original**).
- **Points** : `snack_comptoir`, `cafe_porte`, `librairie_porte`, `projection_porte`,
  `haut_de_rue`, `fontaine`.
- **Lumière** : lanternes à cristal aux portes, un réverbère double au carrefour (**original**) ;
  fenêtres allumées le soir. **Vue au nord** : la ville qui monte, ses toits, la lisière.
  **Densité** : 80 à 120 éléments par écran ; passants (VIE.md).

```plan
carte ville_haute 60 60 dehors
nom "Le centre-ville"
region ville
# la ville monte vers le nord par terrasses (V1 : « une légère pente » ; cahier n° 3, 5.5)
sol cobble 0 0 60 60
sol flagstone 26 10 34 60
sol cobble_b 4 10 56 16
sol cobble_b 4 30 56 34
sol cobble_b 4 51 56 60
sol garden_soil 4 16 26 24
sol garden_soil 34 16 56 25
sol garden_soil 4 34 26 44
sol garden_soil 34 34 56 46
palier 2.0 0 0 60 16
palier 1.0 0 16 60 34
rampe 26 15 34 18 2.0 1.0 S
rampe 26 33 34 36 1.0 0 S
# --- lisière de la forêt au-dessus de la ville, et les rangs de maisons (façades au sud) ---
bord foret 0 0 60 4 11
bord jardins 4 16 26 24 1.2
bord jardins 34 16 56 25 1.2
bord jardins 4 34 26 44 1.2
bord jardins 34 34 56 46 1.2
bord jardins 0 16 4 34 1.2
bord maisons 0 34 4 60 7
bord maisons 56 4 60 16 7
bord jardins 56 16 60 34 1.2
bord maisons 56 34 60 60 7
bord maisons 0 4 4 10 7
bati maison_haute 12 4 18 10 10 town_house_e
bati maison_etroite 19 5 23 10 8 house_narrow
bati maison_a 36 4 41 10 9 town_house_a
bati maison_b 42 4 50 10 8.5 town_house_b
bati librairie 12 25 17 30 6 shop_bookshop
bati cafe_habituel 18 24 25 30 6 cafe_town
bati snack 35 25 40 30 6 shop_snack
bati accessoires 41 25 45 30 6.5 shop_accessories
bati maison_f 46 25 52 30 6 town_house_f
bati apothicaire 10 46 14 51 6.5 shop_apothecary
bati salle_projection 16 44 23 51 7.5 projection_hall
bati colombages 36 46.5 41 51 6 house_timber_a
bati maison_c 42 46 46 51 7.5 town_house_c
bati maison_d 47 46 53 51 7 town_house_d
decor hanging_sign_pan 40.3 30.3 0.4 0.3 2.2 libre
decor hanging_sign_cup 17.7 30.3 0.4 0.3 2.2 libre
decor street_lamp_double 25.4 34.6 0.4 0.4 3.6 pp
decor town_planter_stone 35 10.4 1.6 0.6 0.8
decor town_wall_fountain 25 10.4 1.2 0.6 1.6
decor bench_stone 45 15.6 1.6 0.5 0.6
decor town_doorsteps 15 10.4 1.2 0.5 0.3 libre
decor town_cellar_hatch 48 52.2 1.2 0.6 0.3 libre
decor crate_apples 6 52.0 1 0.8 0.8
decor wall_lantern 26.5 9.8 0.4 0.2 0.6 libre
# --- rues ---
chemin rue_haute 4 1;13 53;13
chemin grand_rue 6 30;10 30;59
chemin rue_du_cafe 3 6;32 54;32
chemin rue_basse 4 6;55 54;55
place carrefour 18 30.5 42 34
place bas_de_ville 24 52 36 58
sortie vers_sentier 0 11 0.6 15 sentier from_ville_haute ""
sortie vers_marche 26 59.4 34 60 ville_marche from_ville_haute ""
sortie porte_cafe 20.8 30 22.2 30.6 ville_cafe from_ville_haute "Entrer"
sortie porte_snack 36.8 30 38.2 30.6 ville_snack from_ville_haute "Entrer"
sortie porte_librairie 13.8 30 15.2 30.6 ville_librairie from_ville_haute "Entrer"
sortie porte_projection 18.8 51 20.2 51.6 ville_projection from_ville_haute "Entrer"
marqueur Spawn 4 13 E
marqueur from_sentier 2.5 13 E
marqueur from_ville_marche 30 57.5 N
marqueur from_ville_cafe 21.5 32.2 S
marqueur from_ville_snack 37.5 32.2 S
marqueur from_ville_librairie 14.5 32.2 S
marqueur from_ville_projection 19.5 53 S
point snack_comptoir 37.5 31.6
point cafe_porte 21.5 31.6
point librairie_porte 14.5 31.6
point projection_porte 19.5 52.8
point haut_de_rue 30 13
point fontaine 25 11.8
lumiere reverbere 25.4 34.6 3.6 cristal
lumiere lanterne_haut 26.5 9.8 2.0 cristal
```

### 9.3 La place du marché (`ville_marche`)

<!-- ascii:ville_marche -->
```text
ville_marche : 56 × 44 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50
    0 ########################____^___########################
      ########################________########################
      ####____#####_#######_______@_____######_#####_#########
      ####____#bou#_#maiso#_____________#bouc#_#hor#_#mai#####
      ####______*___________LL____________________*_______####
   10 ####__AAA______________________________________DDD__####
      ####__AAA______________________________________DDD__####
      ####________________________________________________####
      ####__BBB______________________________________EEE__####
      ####________________________________________________####
   20 ####__CCC______________________________________FFF__####
      ####__CCC______________________________________FFF__####
      ####________________________________________________####
      ####________________________________________________####
      _____________________________________________GG_____####
   30 <____________________________________________GG_____####
      ####_____II________________________________JJ_______####
      ####_______________________KK______________JJ_______####
      ####_______________________KK_______________________####
      ####________________________________________________####
   40 ____----------------------------------------------------
      ____----------------------------------------------------
```
Légende des lettres : `A` market_stall_dairy ; `B` market_stall_honey ; `C` market_stall_flour ; `D` market_stall_veg ; `E` market_stall_fruit ; `F` market_stall_cloth ; `G` hand_cart ; `I` crate_stack ; `J` sack_apples ; `K` bench_stone ; `L` street_lamp_double.
<!-- /ascii:ville_marche -->

- **Taille** 56 × 44 m ; **bornes** `Rect2(10, 6, 36, 21)`. La place dallée du **marché du matin**
  (V3), au pied de la ville ; au nord, la rangée de boutiques : la **boulangerie** `shop_bakery`
  (livrée, x 8 → 13), `house_timber_b`, la **boucherie** `butcher` (livrée), l'**horloger**
  `clockmaker` (livré), `house_stone_b` ; la grand-rue y descend entre elles (x 24 → 32) ; la
  route du port arrive à l'ouest.
- **Étals** (le matin seulement, VIE.md) : `market_stall_dairy`, `_honey`, `_flour` à l'ouest,
  `market_stall_veg`, `_fruit`, `_cloth` (livrés) à l'est ; l'après-midi, les bâches pliées
  (`market_stall_cloth` seul) et la place nue.
- **Place** `marche` (12 → 44, 10 → 32) ; points `boulangerie_porte`, `horloger_porte`,
  `boucherie`, `etal_lait`, `place_centre`, `banc`.
- **Sorties** : `vers_haute` (nord) ; `vers_port` (ouest) ; portes de la boulangerie et de
  l'horloger.
- **Densité** : 60 à 90 éléments le matin (étals, paniers, caisses, marchands), 40 à 60 l'après-midi.

```plan
carte ville_marche 56 44 dehors
nom "La place du marché"
region ville
sol cobble 0 0 56 44
sol flagstone 10 8 46 34
sol cobble_b 0 28 10 32
bord maisons 0 0 24 3 7
bord maisons 32 0 56 3 7
bati boulangerie 8 3 13 8 6 shop_bakery
bati maison_colombages 14 3 21 8 7.5 house_timber_b
bati boucherie 34 3 40 8 5.5 butcher
bati horloger 41 3 46 8 6.5 clockmaker
bati maison_pierre 47 3.5 52 8 5 house_stone_b
bord maisons 0 3 4 28 7
bord maisons 0 32 4 40 7 pp
bord maisons 52 3 56 40 7
bord muret 4 40 56 44 1.0 pp
decor market_stall_dairy 7.5 12 2.5 1.5 2.4
decor market_stall_honey 7.5 17 2.5 1.5 2.4
decor market_stall_flour 7.5 22 2.5 1.5 2.4
decor market_stall_veg 48.5 12 2.5 1.5 2.4
decor market_stall_fruit 48.5 17 2.5 1.5 2.4
decor market_stall_cloth 48.5 22 2.5 1.5 2.4
decor hand_cart 46 30 1.6 1 1.2
decor crate_stack 10 33 1.5 1 1.2
decor sack_apples 44 34 0.8 0.6 0.6
decor bench_stone 28 36 1.6 0.5 0.6
decor street_lamp_double 23 9.2 0.4 0.4 3.6
chemin descente 6 28;0 28;20
chemin route_port 4 1;30 20;30
place marche 12 10 44 32
sortie vers_haute 24 0 32 0.6 ville_haute from_ville_marche ""
sortie vers_port 0 28 0.6 32 port from_ville_marche ""
sortie porte_boulangerie 9.8 8 11.2 8.6 ville_boulangerie from_ville_marche "Entrer"
sortie porte_horloger 42.8 8 44.2 8.6 ville_horloger from_ville_marche "Entrer"
marqueur Spawn 28 3 S
marqueur from_ville_haute 28 2.5 S
marqueur from_port 2.5 30 E
marqueur from_ville_boulangerie 10.5 10.2 S
marqueur from_ville_horloger 43.5 10.2 S
point boulangerie_porte 10.5 9.6
point horloger_porte 43.5 9.6
point boucherie 37 9.6
point etal_lait 10 12
point place_centre 28 21
point banc 28 37.3
lumiere reverbere 23 9.2 3.6 cristal
```

### 9.4 Les six intérieurs de la ville

| Carte | Cotes (m) | Ce que dit l'œuvre | Mobilier (images) | Points |
| --- | --- | --- | --- | --- |
| `ville_snack` | 7 × 5 | le lycanthrope fait sauter sa poêle ; pommes de terre frites, légumes, lard épais, petit pain, soupe dans une tasse (V1) | `snack_counter`, `snack_shelf`, `snack_stools`, `cafe_table_heavy`, `snack_meal_tray` | `snack_tabouret`, `snack_table` |
| `ville_cafe` | 9 × 6 | pas de thé ; café, boisson médicinale piquante, sandwich au bacon ; petites chaises trop petites pour un lézard ; serveur demi-bête terrifié (V3) ; lourdes tables de bois, thé amer « affreux » (V5) | `cafe_town_counter`, `cafe_town_table` ×3, `wallitem_menu_town` | `cafe_comptoir`, `cafe_table_nygglatho` |
| `ville_librairie` | 7 × 5 | tout l'entrepôt y passe ses commandes (V3) | `bookshop_shelves` ×2, `bookshop_counter` (commandes ficelées), `bookshop_table` | `librairie_rayons`, `librairie_comptoir` |
| `ville_projection` | 10 × 8 | films muets aux images floues, tirées de cristaux enregistreurs ; la lumière revient à la fin ; romances de lézards (V2) | `cinema_screen`, `anim/projection_flicker`, six `cinema_benches` (dossiers vers la caméra), `crystal_projector` (premier plan) | `projection_allee`, `ecran` |
| `ville_boulangerie` | 5 × 5 + 4 × 5 | le patron grincheux ; Lakhesh y travaille le matin (V3) | boutique : `bread_shelves`, `bakery_counter` ; fournil : `bakery_oven` (`anim/oven_glow`), `kneading_trough` | `boulangerie_comptoir`, `boulangerie_lakhesh`, `fournil_four` |
| `ville_horloger` | 7 × 5 | (V2 ; les horloges modernes marchent aux cristaux, VEX) | `wallitem_clocks`, `longcase_clock`, `watch_workbench` | `horloger_etabli` |

<!-- ascii:ville_snack -->
```text
ville_snack : 9 × 7 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5
    0 
      
        +-------------+
        |....AAAAsnack|
    2   |...BBBBBB....|
        |...BBBBBB....|
        |....CCCC.....|
        |....CCCC.....|
    4   |DDD..........|
        |DDD..........|
        |DDD......@...|
        |.............|
    6   +---------=---+
                  v
```
Légende des lettres : `A` snack_shelf ; `B` snack_counter ; `C` snack_stools ; `D` cafe_table_heavy.
<!-- /ascii:ville_snack -->

<!-- ascii:ville_boulangerie -->
```text
ville_boulangerie : 11 × 7 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10
    0 
      
        +---------+-------+
        |..AAAA...|.CCCC..|
    2   |boutique.|.CCCC..|
        |.........|fournil|
        |..BBBB...:.......|
        |..BBBB...:.......|
    4   |.........:.DDDD..|
        |.........|.DDDD..|
        |....@....|.......|
        |.........|.......|
    6   +----=----+-------+
             v
```
Légende des lettres : `A` bread_shelves ; `B` bakery_counter ; `C` bakery_oven ; `D` kneading_trough.
<!-- /ascii:ville_boulangerie -->

<!-- ascii:ville_cafe -->
```text
ville_cafe : 11 × 8 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10
    0 
      
        +-----------------+
        |café.............|
    2   |.....AAAAAA......|
        |.....AAAAAA......|
        |.................|
        |.................|
    4   |BBBB........BBB..|
        |BBBB..BBBB..BBB..|
        |BBBB..BBBB..BBB..|
        |......BBBB.......|
    6   |.................|
        |........@........|
        +--------=--------+
                 v
```
Légende des lettres : `A` cafe_town_counter ; `B` cafe_town_table.
<!-- /ascii:ville_cafe -->

<!-- ascii:ville_librairie -->
```text
ville_librairie : 9 × 7 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5
    0 
      
        +-------------+
        |AAAA....AAAA.|
    2   |librairie....|
        |.............|
        |.............|
        |.CCCC...BBBB.|
    4   |.CCCC...BBBB.|
        |.............|
        |......@......|
        |.............|
    6   +------=------+
               v
```
Légende des lettres : `A` bookshop_shelves ; `B` bookshop_counter ; `C` bookshop_table.
<!-- /ascii:ville_librairie -->

<!-- ascii:ville_projection -->
```text
ville_projection : 12 × 10 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5         10
    0 
      
        +-------------------+
        |.....AAAAAAAA......|
    2   |projection.........|
        |...................|
        |...................|
        |BBBBBBB....BBBBBBB.|
    4   |BBBBBBB....BBBBBBB.|
        |...................|
        |BBBBBBB....BBBBBBB.|
        |BBBBBBB....BBBBBBB.|
    6   |...................|
        |BBBBBBB....BBBBBBB.|
        |BBBBBBB....BBBBBBB.|
        |BBBBBBB....BBBBBBB.|
    8   |.........@......CCC|
        |................CCC|
        +---------=---------+
                  v
```
Légende des lettres : `A` cinema_screen ; `B` cinema_benches ; `C` crystal_projector.
<!-- /ascii:ville_projection -->

<!-- ascii:ville_horloger -->
```text
ville_horloger : 9 × 7 m ; un caractère = 0.5 m (est-ouest) × 0.5 m (nord-sud) ; nord en haut
      0         5
    0 
      
        +-------------+
        |horloger..AA.|
    2   |.............|
        |...BBBB......|
        |...BBBB......|
        |...BBBB......|
    4   |.............|
        |.............|
        |......@......|
        |.............|
    6   +------=------+
               v
```
Légende des lettres : `A` longcase_clock ; `B` watch_workbench.
<!-- /ascii:ville_horloger -->

```plan
carte ville_snack 9 7 dedans
nom "Le snack-bar"
region ville
piece salle 1 1 8 6 floor_stone_town wall_stone_inside "snack"
porte salle dehors 6.0 6 1.4 door_room
meuble snack_shelf 4.5 1.4 1.6 0.5 1.6
meuble snack_counter 4.5 2.4 3 0.8 1.2
meuble snack_stools 4.5 3.3 1.6 0.5 0.8
meuble cafe_table_heavy 2.0 4.6 1.2 1.0 0.8
objet snack_meal_tray 2.0 4.6
sortie vers_rue 5.3 6 6.7 7 ville_haute from_ville_snack ""
marqueur Spawn 6.0 5.0 N
marqueur from_ville_haute 6.0 5.0 N
point snack_tabouret 4.5 4.3
point snack_table 3.4 4.6
```


```plan
carte ville_cafe 11 8 dedans
nom "Le café habituel"
region ville
piece salle 1 1 10 7 floor_stone_town wall_plaster_ochre "café"
porte salle dehors 5.5 7 1.4 door_room
meuble cafe_town_counter 5.5 2.4 3 0.8 1.2
mural wallitem_menu_town salle N 8.5 1.1 1.0
meuble cafe_town_table 2.5 4.6 1.4 1.0 0.8
meuble cafe_town_table 5.5 5.2 1.4 1.0 0.8
meuble cafe_town_table 8.3 4.6 1.4 1.0 0.8
sortie vers_rue 4.8 7 6.2 8 ville_haute from_ville_cafe ""
marqueur Spawn 5.5 6.3 N
marqueur from_ville_haute 4.0 6.3 N
point cafe_comptoir 5.5 3.6
point cafe_table_nygglatho 8.3 6.0
```


```plan
carte ville_librairie 9 7 dedans
nom "La librairie"
region ville
piece salle 1 1 8 6 floor_stone_town wall_plaster_ochre "librairie"
porte salle dehors 4.5 6 1.2 door_room
meuble bookshop_shelves 2.5 1.4 2 0.5 2.4
meuble bookshop_shelves 6.5 1.4 2 0.5 2.4
meuble bookshop_counter 6.6 4.0 1.6 0.7 1.1
meuble bookshop_table 3.0 4.0 1.6 0.8 0.9
sortie vers_rue 3.9 6 5.1 7 ville_haute from_ville_librairie ""
marqueur Spawn 4.5 5.2 N
marqueur from_ville_haute 4.5 5.2 N
point librairie_rayons 4.5 2.4
point librairie_comptoir 6.6 5.1
```


```plan
carte ville_projection 12 10 dedans
nom "La salle de projection"
region ville
piece salle 1 1 11 9 floor_planks_dark wall_panel_dark "projection"
porte salle dehors 6.0 9 1.4 door_room
meuble cinema_screen 6.0 1.35 4 0.4 3.0
objet projection_flicker 6.0 1.35
meuble cinema_benches 3.4 4.0 3 0.8 0.9
meuble cinema_benches 8.6 4.0 3 0.8 0.9
meuble cinema_benches 3.4 5.6 3 0.8 0.9
meuble cinema_benches 8.6 5.6 3 0.8 0.9
meuble cinema_benches 3.4 7.2 3 0.8 0.9
meuble cinema_benches 8.6 7.2 3 0.8 0.9
meuble crystal_projector 10.3 8.3 0.8 0.6 1.6 pp
sortie vers_rue 5.3 9 6.7 10 ville_haute from_ville_projection ""
marqueur Spawn 6.0 8.2 N
marqueur from_ville_haute 6.0 8.2 N
point projection_allee 6.0 5.0
point ecran 6.0 2.4
```


```plan
carte ville_boulangerie 11 7 dedans
nom "La boulangerie"
region ville
piece boutique 1 1 6 6 floor_stone_town wall_stone_inside "boutique"
piece fournil 6 1 10 6 floor_stone_town wall_stone_inside "fournil"
porte boutique fournil 6 3.5 1.2 door_room
porte boutique dehors 3.5 6 1.2 door_room
meuble bread_shelves 3.5 1.45 2 0.6 2.2
meuble bakery_counter 3.5 3.3 2 0.6 1.1
meuble bakery_oven 8.0 1.65 2 1 2.0
objet oven_glow 8.0 1.65
meuble kneading_trough 8.0 4.4 1.6 0.7 1.0
sortie vers_place 2.9 6 4.1 7 ville_marche from_ville_boulangerie ""
marqueur Spawn 3.5 5.2 N
marqueur from_ville_marche 3.5 5.2 N
point boulangerie_comptoir 3.5 4.6
point boulangerie_lakhesh 3.5 2.375
point fournil_four 8.0 2.9
```


```plan
carte ville_horloger 9 7 dedans
nom "L'horloger"
region ville
piece salle 1 1 8 6 floor_stone_town wall_stone_inside "horloger"
porte salle dehors 4.5 6 1.2 door_room
mural wallitem_clocks salle N 3.0 1.2 2.0
meuble longcase_clock 6.8 1.35 0.6 0.4 2.2
meuble watch_workbench 4.0 3.3 1.6 0.7 1.1
sortie vers_place 3.9 6 5.1 7 ville_marche from_ville_horloger ""
marqueur Spawn 4.5 5.2 N
marqueur from_ville_marche 4.5 5.2 N
point horloger_etabli 4.0 4.4
```

## 10. La montagne (`montagne`)

- **Ce que dit l'œuvre** : des montagnes où vivent les ours, qui hibernent l'hiver ; Nygglatho y
  part frapper les arbres et les ours quand le chagrin déborde, et en rapporte de quoi faire un
  ragoût (V2, « Qu'est-il advenu de la promesse ? ») ; elle chasse « de l'autre côté de la
  montagne » (V5, « Faire face au passé »). Le reste est **original** (cahier n° 3, 7.5).

<!-- ascii:montagne -->
```text
montagne : 80 × 60 m ; un caractère = 1 m (est-ouest) × 2 m (nord-sud) ; nord en haut
      0         10        20        30        40        50        60        70        80
    0 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^EEEE^^^^^^^^^XXX
      ^^^^^^^^^^T^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^EEEE^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^GGGG^^^^^^^^^^^^^^^^^^^^^^^XXX
   10 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^wwwwww^^^^^^^^FFFFFF^^^^^^^::::::::::::::::::^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^wwwwww^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::^^^^^^^^T^^^^XXX
   20 ^^^^^^^^^^^^^^^^^^^wwwwww^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^wwwwww^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^wwwwww^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^wwwwww^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^wwwwww^^^^^^^^^^^^^^^^^^^^^::::::::::::::::::^^^^^^^^^^^^^XXX
   30 ^^^,,,,,,,,,,,,,,,wwww,,,,,,,,::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^,,,T,,,,,,,,,,,wwww,,,,IIII::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^,,,,,,,,,,,,,,,wwww,,,,IIII::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^,,,,,,,,,,,,,,,wwww,,,,,,,,::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^,,,,,,,,,,,,,,,wwww,,,,,,,,::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
   40 ^^^,,,,,,,,,,,,,,,wwww,,,,,,,,:::::::DD:::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^,,,,,,,,,,,,,,,wwww,,,,,,,,::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^,,,,,,,wwwwwwwwww,,,,,,,,,,::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ::::::::::wwBBBBwwww::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      <::@::::::wwwwwwwwww::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
   50 ^^^wwwwwww,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^wwwwwww,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,XXX
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^XXX
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^XXX
```
Légende des lettres : `A` small_waterfall ; `B` log_bridge_b ; `C` scree ; `D` animal_tracks ; `E` bear_den ; `F` rock_overhang ; `G` boulder_mountain_a ; `I` boulder_mountain_b.
<!-- /ascii:montagne -->

- **Taille** 80 × 60 m ; **bornes** `Rect2(10, 6, 60, 37)`. On entre par l'ouest, en remontant
  le torrent ; la montagne **monte vers le nord** en quatre paliers (0, +1, +2,5, +4,5 ; parois
  `cliff/cliff_mountain` et `cliff/wall_rock_1m` face au sud) ; au fond, la chaîne en lointain
  (`sky/mountain_backdrop_a/b`) : **l'autre côté de la montagne**, où l'on ne va pas.
- **Grands décors** : la **tanière** `bear_den` (66 ; 5,5) sur le palier haut, place `taniere`
  devant ; le surplomb `rock_overhang` (36 ; 17) où s'abriter ; la petite cascade
  `anim/small_waterfall` (22 ; 15,5), source du torrent qui devient la rivière de la forêt
  profonde ; le tronc-passerelle `log_bridge_b` (14 ; 47,5) ; rochers `boulder_mountain_a/b`,
  éboulis `scree`, sapins tordus `mountain_pine_a/b`, traces `animal_tracks`.
- **Kits** : roche (`rock_*`, `boulder_*`), herbe rase (`grass_dry`, `heather`), torrent
  (`anim/river_rapids`, `river_bank`), sous-bois clairsemé à l'ouest.
- **Points** : `taniere`, `surplomb`, `cascade`, `belvedere_haut`, `gue`. **Sortie** `vers_foret`
  (ouest).
- **Lumière** : air froid, lumière plus blanche ; premières neiges sur les sommets du lointain
  (fin d'automne). **Vue au nord** : les pics. **Densité** : 50 à 80 éléments par écran (une
  montagne plus nue, voulue) ; ours, corbeaux, cerfs (VIE.md).

```plan
carte montagne 80 60 dehors
nom "La montagne"
region montagne
sol grass_dry 0 0 80 60
sol rock 0 0 80 16
sol rock_b 0 16 80 30
sol path_dirt_b 0 46 34 50
sol path_dirt_b 30 30 50 46
sol path_dirt_b 46 16 64 30
sol stream_bed 19 16 25 30
sol stream_bed 18 30 22 44
sol stream_bed 10 44 20 50
sol stream_bed 0 50 10 54
palier 1.0 0 30 77 44
palier 2.5 0 16 77 30
palier 4.5 0 4 77 16
rampe 30 44 34 47 1.0 0 S
rampe 44 30 48 33 2.5 1.0 S
rampe 58 16 62 20 4.5 2.5 S
# --- la montagne, ses ours (V2, « Qu'est-il advenu de la promesse ? » ; V5) ---
bord falaise 0 0 80 4 12
bord foret 0 4 3 46 10
bord foret 0 50 3 60 10 pp
bord falaise 77 4 80 60 10
bord foret 3 57 77 60 9 pp
eau 19 16 25 30
eau 18 30 22 44
eau 10 44 20 50
eau 0 50 10 54
decor small_waterfall 22 15.5 2 0.5 3 libre
decor log_bridge_b 14 47.5 4 1 0.5 libre
decor bear_den 66 5.5 4 1.5 3
decor rock_overhang 36 17.2 5 1.5 3.5
decor boulder_mountain_a 52 9 4 2 3
decor boulder_mountain_b 28 34 2.5 1.5 2
decor scree 40 24 3 2 0 libre
arbre mountain_pine_a 10 6 2.5 6
arbre mountain_pine_b 72 18 2 4.5
arbre mountain_pine_a 6 32 2.5 6
decor animal_tracks 38 41 1.5 2 0 libre
chemin sentier 3 1;48 14;48 26;48 32;45 32;40 44;36 46;32 48;26 58;22 60;18 62;12 66;10
place taniere 58 8 74 14
sortie vers_foret 0 46 0.6 50 foret_profonde from_montagne ""
marqueur Spawn 3 48 E
marqueur from_foret_profonde 2.5 48 E
point taniere 66 8.4
point surplomb 36 19.5
point cascade 22.5 19
point belvedere_haut 48 6
point gue 14 47.5
```

## 11. Ce que les lots du moteur doivent savoir

- **E1 (cartes)** : 23 cartes ; marqueurs `from_<carte>` et, quand deux sorties relient les mêmes
  cartes, `from_<carte>_<suffixe>` (`from_entrepot_service`) ; les bornes de caméra sont données
  par carte ; la carte `barocupot` se quitte par une scène (pas de marche vers le ciel) ; les
  portes des boutiques closes à l'acte 1 ont l'invite « Fermé » sans sortie.
- **E2 (sol)** : paliers de 0,5 et 1 m, rampes données ; la ville et la montagne montent vers le
  nord (faces de paliers visibles) ; eau « basse » au ras du sol où l'on marche (marais, rivière),
  eau « profonde » nulle part à l'acte 1 sauf les mares cachées, qui font glisser (VIE.md).
- **E3 (intérieurs)** : cartes à plusieurs pièces (rez-de-chaussée et étage) : murs est-ouest
  coupés, mur nord du bâtiment haut ; portes sur des murs coupés dessinées en panneau ; éléments de
  mur et fenêtres sur les murs nord, est, ouest ; ouvertures de 1,2 m (2 m pour l'entrée).
- **E4 (vie)** et **E6 (récit)** : les points nommés de ce document sont les lieux des emplois du
  temps (VIE.md) et des scènes (ACTE1.md).
- **E7 (navires)** : le transport de la Garde s'amarre de flanc au nord du quai du port ; le
  Barocupot ne vient jamais au port à l'acte 1.
- **E9 (lumière)** : préréglages cités : `interieur`, `noir` (crypte), `nuit_sans_lune` (sentier),
  `nuit_claire` (colline), crépuscule de pluie fine (port, jour 7).
- **E10 (densité)** : les kits de chaque carte et les densités visées ; les arbres près des
  chemins en premier plan.

## 12. Images : inventaire et commandes

### 12.1 Noms proposés, à ajouter au cahier n° 3

| Nom | Taille (px) | Genre | Consigne |
| --- | --- | --- | --- |
| `assets/hd2d/buildings/warehouse_front_a.png` | 1728 × 624 (18 × 6,5 m) | façade, type `long` | façade sud du volume ouest de l’entrepôt (section 2.4) : bardage brun foncé rapiécé sur soubassement de pierre, de l’ouest à l’est deux fenêtres dépolies, une petite, un pan plein, puis la porte d’entrée à deux battants **centrée à 12 m du bord gauche** (le porche `warehouse_porch` se pose devant) ; à l’étage, deux fenêtres par dortoir et une petite ; plannings punaisés et plaque de bronze près de la porte ; même rendu que `warehouse_main` |
| `assets/hd2d/buildings/warehouse_front_b.png` | 1152 × 624 (12 × 6,5 m) | façade, type `long` à toit plat | façade sud du volume est : même bardage, au rez-de-chaussée deux fenêtres (salle de jeux) puis deux (infirmerie), à l’étage deux fenêtres par dortoir ; en haut, le rebord plat du toit-terrasse (la rambarde et le linge sont des panneaux posés dessus) |
| `assets/hd2d/buildings/warehouse_front_a_side.png` | 1344 × 960 (14 × 10 m) | flanc, pignon | pignon ouest : la porte de service à 8 m de l’angle sud (bord gauche de l’image), une fenêtre par niveau, lierre, une gouttière |
| `assets/hd2d/buildings/warehouse_front_b_side.png` | 1344 × 624 (14 × 6,5 m) | flanc, gouttereau | flanc est : au rez-de-chaussée, la fenêtre de la salle de lecture vue de dehors (banquette en saillie) à 3,5 m du bord droit, une petite fenêtre ; à l’étage, deux fenêtres ; une échelle de bois appuyée |
| `assets/hd2d/interior/props/roof_ladder.png` | 77 × 288 (0,8 × 3 m) | meuble | échelle de meunier de bois, raide, contre le mur, qui monte à une trappe ouverte au plafond (haut de l’image) ; un rai de jour par la trappe |
| `assets/hd2d/interior/props/desk_clean.png` | 106 × 101 (1,1 × 1,05 m) | meuble | `desk_clean_brooch` **sans la broche** : le bureau propre et vide de la grande sœur, au présent (à l’acte 1, Chtholly porte la broche) |
| `assets/hd2d/interior/props/desk_chtholly_mirror_up.png` | 106 × 101 | meuble | `desk_chtholly` avec le miroir à main **debout** : le miroir face contre le bureau est un détail du V2, à garder pour l’acte 2 |

### 12.2 Inventaire

Toutes les images et matières citées dans les données de pose, avec leur état à la date de ce
document (livrée dans `assets/`, à livrer d'après un cahier, ou nom proposé ici). Les noms proposés
sont à ajouter au cahier n° 3 avant d'être commandés.

<!-- inventaire -->
378 images ou matières citées : 186 livrées ; 3 proposées ; 189 à livrer.

| Image ou matière | Cartes | État |
| --- | --- | --- |
| `alder` | entrepot, sentier | à livrer (cahier n° 3) |
| `animal_tracks` | montagne | à livrer (cahier n° 3) |
| `archive_shelves` | entrepot_rdc | livrée : `assets/hd2d/interior/props/archive_shelves.png` |
| `armchair_reading` | entrepot_rdc | à livrer (cahier n° 3) |
| `armchair_sheeted` | maison_limashenka | à livrer (cahier n° 3) |
| `bakery_counter` | ville_boulangerie | à livrer (cahier n° 3) |
| `bakery_oven` | ville_boulangerie | à livrer (cahier n° 3) |
| `ball` | entrepot | livrée : `assets/hd2d/props/ball.png` |
| `ball_white` | entrepot_rdc | livrée : `assets/hd2d/interior/props/ball_white.png` |
| `bath_puddles` | entrepot_rdc | à livrer (cahier n° 3) |
| `bath_tub` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bath_tub.png` |
| `bear_den` | montagne | à livrer (cahier n° 3) |
| `bed_child` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_child.png` |
| `bed_child_messy` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_child_messy.png` |
| `bed_chtholly` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_chtholly.png` |
| `bed_iron` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bed_iron.png` |
| `bed_nygglatho` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_nygglatho.png` |
| `bed_plain` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_plain.png` |
| `bedside_table` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bedside_table.png` |
| `beech_a` | foret_profonde | livrée : `assets/hd2d/props/beech_a.png` |
| `beehives` | village | à livrer (cahier n° 3) |
| `bench` | port | livrée : `assets/hd2d/props/bench.png` |
| `bench_b` | entrepot | livrée : `assets/hd2d/props/bench_b.png` |
| `bench_stone` | village, ville_haute, ville_marche | livrée : `assets/hd2d/props/bench_stone.png` |
| `board_games_shelf` | entrepot_rdc | livrée : `assets/hd2d/interior/props/board_games_shelf.png` |
| `boardwalk` | entrepot | livrée : `assets/hd2d/decals/boardwalk.png` |
| `bog_pool_a` | sentier | à livrer (cahier n° 3) |
| `bollard` | port | livrée : `assets/hd2d/props/bollard.png` |
| `book_pile` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `bookshelf_low` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/props/bookshelf_low.png` |
| `bookshelf_tall` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bookshelf_tall.png` |
| `bookshelf_tall_b` | entrepot_rdc | à livrer (cahier n° 3) |
| `bookshop_counter` | ville_librairie | à livrer (cahier n° 3) |
| `bookshop_shelves` | ville_librairie | à livrer (cahier n° 3) |
| `bookshop_table` | ville_librairie | à livrer (cahier n° 3) |
| `boulder_a` | colline | livrée : `assets/hd2d/props/boulder_a.png` |
| `boulder_mountain_a` | montagne | à livrer (cahier n° 3) |
| `boulder_mountain_b` | montagne | à livrer (cahier n° 3) |
| `bramble_hedge` | entrepot | à livrer (cahier n° 3) |
| `bread_shelves` | ville_boulangerie | à livrer (cahier n° 3) |
| `bunk_bed` | entrepot_etage | à livrer (cahier n° 3) |
| `bush_c` | entrepot | livrée : `assets/hd2d/props/bush_c.png` |
| `butcher` | ville_marche | livrée : `assets/hd2d/buildings/butcher.png` |
| `cafe` | village | livrée : `assets/hd2d/buildings/cafe.png` |
| `cafe_bottle_shelf` | cafe | à livrer (cahier n° 3) |
| `cafe_cake_case` | cafe | à livrer (cahier n° 3) |
| `cafe_counter` | cafe | à livrer (cahier n° 3) |
| `cafe_drinkers_table` | cafe | à livrer (cahier n° 3) |
| `cafe_table_heavy` | cafe, ville_snack | à livrer (cahier n° 3) |
| `cafe_town` | ville_haute | à livrer (cahier n° 3) |
| `cafe_town_counter` | ville_cafe | à livrer (cahier n° 3) |
| `cafe_town_table` | ville_cafe | à livrer (cahier n° 3) |
| `capstan` | port | à livrer (cahier n° 3) |
| `cards_floor` | entrepot_etage | à livrer (cahier n° 3) |
| `cargo_cart_a` | port | à livrer (cahier n° 3) |
| `cargo_cart_b` | port | à livrer (cahier n° 3) |
| `cart_hay` | village | à livrer (cahier n° 3) |
| `cattails` | sentier | livrée : `assets/hd2d/props/cattails.png` |
| `chair_child` | entrepot_rdc | livrée : `assets/hd2d/interior/props/chair_child.png` |
| `chair_guest` | entrepot_etage | livrée : `assets/hd2d/interior/props/chair_guest.png` |
| `chair_wood` | cafe, entrepot_rdc | livrée : `assets/hd2d/interior/props/chair_wood.png` |
| `chair_wood_back` | cafe, entrepot_rdc | livrée : `assets/hd2d/interior/props/chair_wood_back.png` |
| `chalk_hopscotch` | entrepot | livrée : `assets/hd2d/decals/chalk_hopscotch.png` |
| `chimney_brick` | entrepot_toit | livrée : `assets/hd2d/props/chimney_brick.png` |
| `china_cabinet` | entrepot_rdc | livrée : `assets/hd2d/interior/props/china_cabinet.png` |
| `cinema_benches` | ville_projection | à livrer (cahier n° 3) |
| `cinema_screen` | ville_projection | à livrer (cahier n° 3) |
| `cleaning_set` | entrepot_rdc | à livrer (cahier n° 3) |
| `climbing_tree` | entrepot | livrée : `assets/hd2d/props/climbing_tree.png` |
| `clockmaker` | ville_marche | livrée : `assets/hd2d/buildings/clockmaker.png` |
| `clothes_chest` | entrepot_etage | à livrer (cahier n° 3) |
| `clothes_floor` | entrepot_etage | à livrer (cahier n° 3) |
| `cobble` | port, ville_haute, ville_marche | livrée : `assets/hd2d/ground/cobble.png` |
| `cobble_b` | ville_haute, ville_marche | livrée : `assets/hd2d/ground/cobble_b.png` |
| `coffee_tray` | entrepot_rdc | à livrer (cahier n° 3) |
| `comm_crystal` | entrepot_etage | livrée : `assets/hd2d/interior/props/comm_crystal.png` |
| `cottage_thatch_a` | village | à livrer (cahier n° 3) |
| `cottage_thatch_b` | village | à livrer (cahier n° 3) |
| `cottage_thatch_c` | village | à livrer (cahier n° 3) |
| `crate_apples` | ville_haute | livrée : `assets/hd2d/props/crate_apples.png` |
| `crate_stack` | ville_marche | livrée : `assets/hd2d/props/crate_stack.png` |
| `crates_barrels` | cafe, port | livrée : `assets/hd2d/props/crates_barrels.png` |
| `crypt_pillar` | salle_des_armes | livrée : `assets/hd2d/interior/props/crypt_pillar.png` |
| `crypt_stairs` | salle_des_armes | à livrer (cahier n° 3) |
| `crystal_crates` | port | livrée : `assets/hd2d/props/crystal_crates.png` |
| `crystal_lamp_table` | entrepot_rdc | à livrer (cahier n° 3) |
| `crystal_pendant` | cafe, entrepot_rdc | à livrer (cahier n° 3) |
| `crystal_projector` | ville_projection | à livrer (cahier n° 3) |
| `crystal_stove` | entrepot_rdc | livrée : `assets/hd2d/interior/props/crystal_stove.png` |
| `deck_bridge` | transport_garde | à livrer (cahier n° 3) |
| `deck_crates_lashed` | transport_garde | à livrer (cahier n° 3) |
| `deck_hatch` | transport_garde | à livrer (cahier n° 3) |
| `deck_vent` | transport_garde | à livrer (cahier n° 3) |
| `desk_buried` | entrepot_rdc | livrée : `assets/hd2d/interior/props/desk_buried.png` |
| `desk_chtholly` | entrepot_etage | livrée : `assets/hd2d/interior/props/desk_chtholly.png` |
| `desk_clean_brooch` | entrepot_etage | à livrer (cahier n° 3) |
| `desk_nygglatho` | entrepot_etage | livrée : `assets/hd2d/interior/props/desk_nygglatho.png` |
| `dining_table_long` | entrepot_rdc | livrée : `assets/hd2d/interior/props/dining_table_long.png` |
| `dining_table_set` | entrepot_rdc | livrée : `assets/hd2d/interior/props/dining_table_set.png` |
| `display_cabinet` | maison_limashenka | à livrer (cahier n° 3) |
| `dock_lamp` | port | livrée : `assets/hd2d/props/dock_lamp.png` |
| `door_armory` | entrepot_rdc | à livrer (cahier n° 3) |
| `door_armory_inside` | salle_des_armes | à livrer (cahier n° 3) |
| `door_backroom` | cafe | à livrer (cahier n° 3) |
| `door_bulkhead` | barocupot | à livrer (cahier n° 3) |
| `door_double` | entrepot_rdc | livrée : `assets/hd2d/interior/door_double.png` |
| `door_room` | cafe, entrepot_etage, entrepot_rdc, maison_limashenka, ville_boulangerie, ville_cafe, ville_horloger, ville_librairie, ville_projection, ville_snack | livrée : `assets/hd2d/interior/door_room.png` |
| `door_service` | entrepot_rdc | à livrer (cahier n° 3) |
| `dresser_child` | entrepot_etage | livrée : `assets/hd2d/interior/props/dresser_child.png` |
| `drying_frame` | entrepot_toit | livrée : `assets/hd2d/interior/props/drying_frame.png` |
| `edge_waterfall` | village | livrée : `assets/hd2d/anim/edge_waterfall.png` |
| `fallen_pine` | foret_profonde | à livrer (cahier n° 3) |
| `fence_wattle` | village | à livrer (cahier n° 3) |
| `fern_a` | entrepot | livrée : `assets/hd2d/props/fern_a.png` |
| `fg_canopy_a` | sentier | à livrer (cahier n° 3) |
| `filing_cabinet` | entrepot_rdc | à livrer (cahier n° 3) |
| `fireplace` | entrepot_etage | livrée : `assets/hd2d/interior/props/fireplace.png` |
| `firewood_pile` | entrepot, village | livrée : `assets/hd2d/props/firewood_pile.png` |
| `flagstone` | ville_haute, ville_marche | livrée : `assets/hd2d/ground/flagstone.png` |
| `floor_cushions` | entrepot_rdc | à livrer (cahier n° 3) |
| `floor_flagstone_cellar` | salle_des_armes | à livrer (cahier n° 3) |
| `floor_kitchen_tiles` | entrepot_rdc | livrée : `assets/hd2d/interior/floor_kitchen_tiles.png` |
| `floor_planks_dark` | entrepot_etage, ville_projection | livrée : `assets/hd2d/interior/floor_planks_dark.png` |
| `floor_planks_worn` | cafe, entrepot_etage, entrepot_rdc, maison_limashenka | livrée : `assets/hd2d/interior/floor_planks_worn.png` |
| `floor_roof_deck` | entrepot_toit | à livrer (cahier n° 3) |
| `floor_ship_planks` | barocupot | à livrer (cahier n° 3) |
| `floor_stone_town` | ville_boulangerie, ville_cafe, ville_horloger, ville_librairie, ville_snack | à livrer (cahier n° 3) |
| `floor_terracotta` | cafe | à livrer (cahier n° 3) |
| `floor_tiles_bath` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/floor_tiles_bath.png` |
| `flower_bed` | entrepot | livrée : `assets/hd2d/props/flower_bed.png` |
| `flower_pots` | entrepot, village | livrée : `assets/hd2d/props/flower_pots.png` |
| `footlocker` | entrepot_etage | à livrer (cahier n° 3) |
| `forest_floor` | colline, entrepot, foret_profonde, sentier | livrée : `assets/hd2d/ground/forest_floor.png` |
| `game_table` | entrepot_rdc | livrée : `assets/hd2d/interior/props/game_table.png` |
| `gangway` | port, transport_garde | livrée : `assets/hd2d/props/gangway.png` |
| `garde_transport_rotor` | transport_garde | à livrer (cahier n° 3) |
| `garde_transport_side` | port | à livrer (cahier n° 3) |
| `garden_soil` | entrepot, village, ville_haute | livrée : `assets/hd2d/ground/garden_soil.png` |
| `garden_tools` | entrepot | livrée : `assets/hd2d/props/garden_tools.png` |
| `grass` | colline, entrepot, port, village | livrée : `assets/hd2d/ground/grass.png` |
| `grass_b` | entrepot | livrée : `assets/hd2d/ground/grass_b.png` |
| `grass_dry` | colline, entrepot, montagne, port, village | livrée : `assets/hd2d/ground/grass_dry.png` |
| `gravel` | port | livrée : `assets/hd2d/ground/gravel.png` |
| `grove_dense` | foret_profonde | à livrer (cahier n° 3) |
| `hamper` | entrepot_rdc | à livrer (cahier n° 3) |
| `hand_cart` | port, ville_marche | livrée : `assets/hd2d/props/hand_cart.png` |
| `hanging_sign_cup` | ville_haute | à livrer (cahier n° 3) |
| `hanging_sign_key` | village | livrée : `assets/hd2d/props/hanging_sign_key.png` |
| `hanging_sign_pan` | ville_haute | à livrer (cahier n° 3) |
| `harbor_office` | port | livrée : `assets/hd2d/buildings/harbor_office.png` |
| `haystack` | village | à livrer (cahier n° 3) |
| `hearth_fire` | entrepot_etage | livrée : `assets/hd2d/anim/hearth_fire.png` |
| `heather` | colline | livrée : `assets/hd2d/props/heather.png` |
| `hidden_pool_a` | foret_profonde | à livrer (cahier n° 3) |
| `hidden_pool_b` | foret_profonde | à livrer (cahier n° 3) |
| `house_narrow` | ville_haute | livrée : `assets/hd2d/buildings/house_narrow.png` |
| `house_stone_b` | ville_marche | livrée : `assets/hd2d/buildings/house_stone_b.png` |
| `house_timber_a` | ville_haute | livrée : `assets/hd2d/buildings/house_timber_a.png` |
| `house_timber_b` | ville_marche | livrée : `assets/hd2d/buildings/house_timber_b.png` |
| `infirmary_desk` | entrepot_rdc | livrée : `assets/hd2d/interior/props/infirmary_desk.png` |
| `juice_glasses` | cafe | à livrer (cahier n° 3) |
| `kitchen_counter` | entrepot_rdc | livrée : `assets/hd2d/interior/props/kitchen_counter.png` |
| `kitchen_table_ingredients` | entrepot_rdc | livrée : `assets/hd2d/interior/props/kitchen_table_ingredients.png` |
| `kneading_trough` | ville_boulangerie | à livrer (cahier n° 3) |
| `laundry_basket` | entrepot_toit | livrée : `assets/hd2d/props/laundry_basket.png` |
| `laundry_line` | village | livrée : `assets/hd2d/props/laundry_line.png` |
| `leaf_litter` | foret_profonde, sentier | livrée : `assets/hd2d/ground/leaf_litter.png` |
| `leak_bucket` | entrepot_etage | à livrer (cahier n° 3) |
| `leak_drip` | entrepot_etage | à livrer (cahier n° 3) |
| `lily_pads` | sentier | livrée : `assets/hd2d/decals/lily_pads.png` |
| `limashenka_house` | village | livrée : `assets/hd2d/buildings/limashenka_house.png` |
| `log_bridge_b` | foret_profonde, montagne | à livrer (cahier n° 3) |
| `log_hollow` | foret_profonde | livrée : `assets/hd2d/props/log_hollow.png` |
| `lone_tree` | colline | livrée : `assets/hd2d/props/lone_tree.png` |
| `longcase_clock` | ville_horloger | à livrer (cahier n° 3) |
| `map_cabinet` | barocupot | à livrer (cahier n° 3) |
| `market_stall_cloth` | ville_marche | livrée : `assets/hd2d/props/market_stall_cloth.png` |
| `market_stall_dairy` | ville_marche | à livrer (cahier n° 3) |
| `market_stall_flour` | ville_marche | à livrer (cahier n° 3) |
| `market_stall_fruit` | ville_marche | livrée : `assets/hd2d/props/market_stall_fruit.png` |
| `market_stall_honey` | ville_marche | à livrer (cahier n° 3) |
| `market_stall_veg` | ville_marche | livrée : `assets/hd2d/props/market_stall_veg.png` |
| `marsh_hummock_a` | sentier | à livrer (cahier n° 3) |
| `marsh_hummock_b` | sentier | à livrer (cahier n° 3) |
| `marsh_reed_wall` | sentier | à livrer (cahier n° 3) |
| `marsh_snag` | entrepot, sentier | à livrer (cahier n° 3) |
| `meadow_flowers` | colline, entrepot | livrée : `assets/hd2d/ground/meadow_flowers.png` |
| `meal_lunch` | entrepot_rdc | livrée : `assets/hd2d/interior/props/meal_lunch.png` |
| `medicine_cabinet` | entrepot_rdc | livrée : `assets/hd2d/interior/props/medicine_cabinet.png` |
| `metal` | port, transport_garde | livrée : `assets/hd2d/ground/metal.png` |
| `mirror_large` | entrepot_rdc | livrée : `assets/hd2d/interior/props/mirror_large.png` |
| `mooring_arm_open` | port | à livrer (cahier n° 3) |
| `moss` | foret_profonde, sentier | livrée : `assets/hd2d/ground/moss.png` |
| `mossy_rock` | colline | livrée : `assets/hd2d/props/mossy_rock.png` |
| `mountain_pine_a` | montagne | à livrer (cahier n° 3) |
| `mountain_pine_b` | montagne | à livrer (cahier n° 3) |
| `mud` | foret_profonde | livrée : `assets/hd2d/ground/mud.png` |
| `mushroom_cep` | foret_profonde | livrée : `assets/hd2d/props/mushroom_cep.png` |
| `oak_a` | entrepot | livrée : `assets/hd2d/props/oak_a.png` |
| `oak_c` | foret_profonde | livrée : `assets/hd2d/props/oak_c.png` |
| `oak_d` | foret_profonde | livrée : `assets/hd2d/props/oak_d.png` |
| `oil_lamp` | entrepot_etage | à livrer (cahier n° 3) |
| `oven_glow` | ville_boulangerie | à livrer (cahier n° 3) |
| `pallet_sacks` | port | livrée : `assets/hd2d/props/pallet_sacks.png` |
| `pantry_cupboard` | cafe, entrepot_rdc | à livrer (cahier n° 3) |
| `paper_pile_a` | entrepot_rdc | livrée : `assets/hd2d/interior/props/paper_pile_a.png` |
| `paper_pile_b` | entrepot_rdc | livrée : `assets/hd2d/interior/props/paper_pile_b.png` |
| `paper_pile_c` | entrepot_rdc | livrée : `assets/hd2d/interior/props/paper_pile_c.png` |
| `papers_floor` | entrepot_rdc | à livrer (cahier n° 3) |
| `path_dirt` | entrepot, port, village | livrée : `assets/hd2d/ground/path_dirt.png` |
| `path_dirt_b` | colline, entrepot, montagne, village | livrée : `assets/hd2d/ground/path_dirt_b.png` |
| `path_edge_ferns` | sentier | à livrer (cahier n° 3) |
| `path_overgrown` | foret_profonde, sentier | à livrer (cahier n° 3) |
| `path_root_step` | sentier | à livrer (cahier n° 3) |
| `path_stones_a` | sentier | à livrer (cahier n° 3) |
| `path_stones_b` | sentier | à livrer (cahier n° 3) |
| `peat` | entrepot, sentier | livrée : `assets/hd2d/ground/peat.png` |
| `piano_old` | entrepot_rdc | à livrer (cahier n° 3) |
| `play_goal` | entrepot | livrée : `assets/hd2d/props/play_goal.png` |
| `play_goal_red` | entrepot | livrée : `assets/hd2d/props/play_goal_red.png` |
| `plush_blue` | entrepot_rdc | livrée : `assets/hd2d/interior/props/plush_blue.png` |
| `plush_pile` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/props/plush_pile.png` |
| `port_hangar` | port | livrée : `assets/hd2d/buildings/port_hangar.png` |
| `port_house_b` | port | à livrer (cahier n° 3) |
| `pot_steam` | entrepot_rdc | à livrer (cahier n° 3) |
| `projection_flicker` | ville_projection | à livrer (cahier n° 3) |
| `projection_hall` | ville_haute | livrée : `assets/hd2d/buildings/projection_hall.png` |
| `rain_barrel` | entrepot | livrée : `assets/hd2d/props/rain_barrel.png` |
| `reading_table` | entrepot_rdc | livrée : `assets/hd2d/interior/props/reading_table.png` |
| `reeds` | entrepot, sentier | livrée : `assets/hd2d/props/reeds.png` |
| `reeds_b` | entrepot, sentier | livrée : `assets/hd2d/props/reeds_b.png` |
| `refuge_oak` | foret_profonde | à livrer (cahier n° 3) |
| `repair_planks` | entrepot_etage | à livrer (cahier n° 3) |
| `rock` | entrepot_toit, montagne, village | livrée : `assets/hd2d/ground/rock.png` |
| `rock_b` | montagne | livrée : `assets/hd2d/ground/rock_b.png` |
| `rock_overhang` | montagne | à livrer (cahier n° 3) |
| `rock_small_a` | colline | livrée : `assets/hd2d/props/rock_small_a.png` |
| `roof_hatch` | entrepot_toit | à livrer (cahier n° 3) |
| `roof_ladder` | entrepot_etage | **nom proposé** (absent des cahiers) |
| `roof_railing_broken` | entrepot_toit | à livrer (cahier n° 3) |
| `rope_coil` | port | livrée : `assets/hd2d/props/rope_coil.png` |
| `rowan` | foret_profonde | à livrer (cahier n° 3) |
| `rug_brown` | entrepot_etage | livrée : `assets/hd2d/decals/rug_brown.png` |
| `rug_playroom` | entrepot_rdc | livrée : `assets/hd2d/decals/rug_playroom.png` |
| `rug_salon` | maison_limashenka | à livrer (cahier n° 3) |
| `runner_rug` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `sack_apples` | ville_marche | livrée : `assets/hd2d/props/sack_apples.png` |
| `sacks_pile` | port | livrée : `assets/hd2d/props/sacks_pile.png` |
| `sacks_vegetables` | cafe, entrepot_rdc | à livrer (cahier n° 3) |
| `scree` | montagne | à livrer (cahier n° 3) |
| `shelf_nygglatho` | entrepot_etage | livrée : `assets/hd2d/interior/props/shelf_nygglatho.png` |
| `ship_ladder` | barocupot | à livrer (cahier n° 3) |
| `shoe_rack` | entrepot_rdc | livrée : `assets/hd2d/interior/props/shoe_rack.png` |
| `shop_accessories` | ville_haute | à livrer (cahier n° 3) |
| `shop_apothecary` | ville_haute | à livrer (cahier n° 3) |
| `shop_bakery` | ville_marche | livrée : `assets/hd2d/buildings/shop_bakery.png` |
| `shop_bookshop` | ville_haute | livrée : `assets/hd2d/buildings/shop_bookshop.png` |
| `shop_snack` | ville_haute | à livrer (cahier n° 3) |
| `side_table_salon` | maison_limashenka | à livrer (cahier n° 3) |
| `signpost_port` | port | à livrer (cahier n° 3) |
| `sink_stone` | entrepot_rdc | livrée : `assets/hd2d/interior/props/sink_stone.png` |
| `small_waterfall` | montagne | à livrer (cahier n° 3) |
| `snack_counter` | ville_snack | à livrer (cahier n° 3) |
| `snack_meal_tray` | ville_snack | à livrer (cahier n° 3) |
| `snack_shelf` | ville_snack | à livrer (cahier n° 3) |
| `snack_stools` | ville_snack | à livrer (cahier n° 3) |
| `sofa_beige` | entrepot_rdc | livrée : `assets/hd2d/interior/props/sofa_beige.png` |
| `sofa_salon` | maison_limashenka | à livrer (cahier n° 3) |
| `stairs_down` | entrepot_etage | à livrer (cahier n° 3) |
| `stairs_up` | entrepot_rdc | livrée : `assets/hd2d/interior/props/stairs_up.png` |
| `steam_whistle` | port | à livrer (cahier n° 3) |
| `stick_rack` | entrepot | livrée : `assets/hd2d/props/stick_rack.png` |
| `stream_bed` | entrepot, foret_profonde, montagne, village | livrée : `assets/hd2d/ground/stream_bed.png` |
| `street_lamp_double` | ville_haute, ville_marche | livrée : `assets/hd2d/props/street_lamp_double.png` |
| `stump_a` | entrepot | livrée : `assets/hd2d/props/stump_a.png` |
| `stump_axe` | entrepot | livrée : `assets/hd2d/props/stump_axe.png` |
| `stump_b` | entrepot | livrée : `assets/hd2d/props/stump_b.png` |
| `supply_cupboard` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `sword_rack_a` | salle_des_armes | livrée : `assets/hd2d/interior/props/sword_rack_a.png` |
| `sword_rack_b` | salle_des_armes | livrée : `assets/hd2d/interior/props/sword_rack_b.png` |
| `swords_wrapped` | salle_des_armes | livrée : `assets/hd2d/interior/props/swords_wrapped.png` |
| `tableware_a` | entrepot_rdc | livrée : `assets/hd2d/interior/props/tableware_a.png` |
| `talisman_chest` | salle_des_armes | à livrer (cahier n° 3) |
| `tall_grass` | colline | livrée : `assets/hd2d/props/tall_grass.png` |
| `tea_set_tiny` | barocupot | à livrer (cahier n° 3) |
| `tea_table` | entrepot_etage | livrée : `assets/hd2d/interior/props/tea_table.png` |
| `tea_tray_cheesecake` | entrepot_etage | à livrer (cahier n° 3) |
| `thicket_a` | entrepot, foret_profonde | à livrer (cahier n° 3) |
| `thicket_b` | entrepot, foret_profonde, sentier | à livrer (cahier n° 3) |
| `thicket_c` | entrepot | à livrer (cahier n° 3) |
| `toolbox_gears` | maison_limashenka | à livrer (cahier n° 3) |
| `towel_shelf` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/props/towel_shelf.png` |
| `town_cellar_hatch` | ville_haute | à livrer (cahier n° 3) |
| `town_doorsteps` | ville_haute | à livrer (cahier n° 3) |
| `town_house_a` | ville_haute | à livrer (cahier n° 3) |
| `town_house_b` | ville_haute | à livrer (cahier n° 3) |
| `town_house_c` | ville_haute | à livrer (cahier n° 3) |
| `town_house_d` | ville_haute | à livrer (cahier n° 3) |
| `town_house_e` | ville_haute | à livrer (cahier n° 3) |
| `town_house_f` | ville_haute | à livrer (cahier n° 3) |
| `town_planter_stone` | ville_haute | à livrer (cahier n° 3) |
| `town_wall_fountain` | ville_haute | à livrer (cahier n° 3) |
| `toy_chest` | entrepot_rdc | livrée : `assets/hd2d/interior/props/toy_chest.png` |
| `toys_a` | entrepot | livrée : `assets/hd2d/props/toys_a.png` |
| `tree_old_pine` | foret_profonde | livrée : `assets/hd2d/props/tree_old_pine.png` |
| `vase_flowers` | entrepot_rdc | à livrer (cahier n° 3) |
| `vegetable_patch` | entrepot | livrée : `assets/hd2d/props/vegetable_patch.png` |
| `village_barn` | village | à livrer (cahier n° 3) |
| `village_house_stone` | village | à livrer (cahier n° 3) |
| `village_shed` | village | à livrer (cahier n° 3) |
| `wall_cellar_stone` | salle_des_armes | à livrer (cahier n° 3) |
| `wall_kitchen_tiles` | entrepot_rdc | livrée : `assets/hd2d/interior/wall_kitchen_tiles.png` |
| `wall_lantern` | entrepot, village, ville_haute | livrée : `assets/hd2d/props/wall_lantern.png` |
| `wall_panel_dark` | cafe, ville_projection | à livrer (cahier n° 3) |
| `wall_plaster_ochre` | ville_cafe, ville_librairie | à livrer (cahier n° 3) |
| `wall_plaster_worn` | cafe, entrepot_etage, entrepot_rdc, maison_limashenka | livrée : `assets/hd2d/interior/wall_plaster_worn.png` |
| `wall_ship_plate` | barocupot | à livrer (cahier n° 3) |
| `wall_stone_inside` | ville_boulangerie, ville_horloger, ville_snack | à livrer (cahier n° 3) |
| `wall_wainscot` | entrepot_rdc | livrée : `assets/hd2d/interior/wall_wainscot.png` |
| `wall_wallpaper_faded` | entrepot_etage | livrée : `assets/hd2d/interior/wall_wallpaper_faded.png` |
| `wall_wallpaper_floral` | maison_limashenka | à livrer (cahier n° 3) |
| `wallitem_apron_hook` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_bath_rules` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_bath_rules.png` |
| `wallitem_bronze_plaque` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_bronze_plaque.png` |
| `wallitem_calendar` | entrepot_etage | livrée : `assets/hd2d/interior/wallitem_calendar.png` |
| `wallitem_chore_chart` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_chore_chart.png` |
| `wallitem_clippings` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_clock_limashenka` | maison_limashenka | à livrer (cahier n° 3) |
| `wallitem_clocks` | ville_horloger | à livrer (cahier n° 3) |
| `wallitem_coat_hooks` | entrepot_rdc, maison_limashenka | livrée : `assets/hd2d/interior/wallitem_coat_hooks.png` |
| `wallitem_cobweb` | salle_des_armes | à livrer (cahier n° 3) |
| `wallitem_crystal_sconce` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_day_calendar` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_day_calendar.png` |
| `wallitem_family_portrait` | maison_limashenka | à livrer (cahier n° 3) |
| `wallitem_frame_landscape` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_garde_emblem` | barocupot | à livrer (cahier n° 3) |
| `wallitem_height_marks` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_kids_drawings` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_labcoat` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_menu_board` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_menu_board.png` |
| `wallitem_menu_cafe` | cafe | à livrer (cahier n° 3) |
| `wallitem_menu_town` | ville_cafe | à livrer (cahier n° 3) |
| `wallitem_notice_a` | entrepot_etage | livrée : `assets/hd2d/interior/wallitem_notice_a.png` |
| `wallitem_notice_b` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_notice_b.png` |
| `wallitem_notices_mix` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_ship_pipes` | barocupot | à livrer (cahier n° 3) |
| `wallitem_speaking_tube` | barocupot | à livrer (cahier n° 3) |
| `wallitem_spice_shelf` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_utensils` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_utensils.png` |
| `wallitem_wall_clock` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_wall_clock.png` |
| `wallitem_wall_lamp` | entrepot_etage | livrée : `assets/hd2d/interior/wallitem_wall_lamp.png` |
| `war_chair` | barocupot | à livrer (cahier n° 3) |
| `war_table` | barocupot | à livrer (cahier n° 3) |
| `wardrobe_chtholly` | entrepot_etage | livrée : `assets/hd2d/interior/props/wardrobe_chtholly.png` |
| `wardrobe_plain` | entrepot_etage | livrée : `assets/hd2d/interior/props/wardrobe_plain.png` |
| `warehouse_front_a` | entrepot | **nom proposé** (absent des cahiers) |
| `warehouse_front_b` | entrepot | **nom proposé** (absent des cahiers) |
| `warehouse_porch` | entrepot | livrée : `assets/hd2d/buildings/warehouse_porch.png` |
| `wash_tub` | entrepot_rdc | livrée : `assets/hd2d/interior/props/wash_tub.png` |
| `washbasin_stand` | entrepot_rdc | à livrer (cahier n° 3) |
| `washing_trough` | village | à livrer (cahier n° 3) |
| `washstand_corridor` | entrepot_rdc | livrée : `assets/hd2d/interior/props/washstand_corridor.png` |
| `watch_workbench` | ville_horloger | à livrer (cahier n° 3) |
| `water_tub` | entrepot_rdc | livrée : `assets/hd2d/interior/props/water_tub.png` |
| `watering_can` | entrepot | livrée : `assets/hd2d/props/watering_can.png` |
| `wheelbarrow` | entrepot | livrée : `assets/hd2d/props/wheelbarrow.png` |
| `wildflowers_a` | colline | livrée : `assets/hd2d/props/wildflowers_a.png` |
| `wind_fence` | port | à livrer (cahier n° 3) |
| `wind_sock` | port | livrée : `assets/hd2d/props/wind_sock.png` |
| `window_bare` | entrepot_etage | à livrer (cahier n° 3) |
| `window_cross_large` | entrepot_rdc | livrée : `assets/hd2d/interior/window_cross_large.png` |
| `window_cross_small` | cafe, entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/window_cross_small.png` |
| `window_curtains_closed` | entrepot_etage | à livrer (cahier n° 3) |
| `window_curtains_open` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `window_dusty` | entrepot_rdc | à livrer (cahier n° 3) |
| `window_porthole` | barocupot | à livrer (cahier n° 3) |
| `window_reading_seat` | entrepot_rdc | livrée : `assets/hd2d/interior/window_reading_seat.png` |
| `window_shutters` | maison_limashenka | à livrer (cahier n° 3) |
<!-- /inventaire -->
