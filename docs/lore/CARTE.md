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
  `< > ^ v` sortie à pied au bord, `@` marqueur `Spawn`, `T` tronc d'arbre, `#` bâtiment, `^`
  forêt ou lisière, `&` fourré, `X` falaise ou roche, `H` rambarde, `/` toit, `W` eau profonde.
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
| `village` | le village des hommes-bêtes (`village`) | 56 × 44 | `entrepot` (est), `cafe`, `maison_limashenka` | 250 marmer de l'entrepôt, 4 min |
| `cafe`, `maison_limashenka` | intérieurs (`village`) | 12 × 10, 10 × 8 | `village` | — |
| `colline` | la colline des étoiles (`colline`) | 40 × 40 | `entrepot` (sud) | 300 marmer, 5 min |
| `sentier` | le sentier et le marais (`sentier`) | 80 × 40 | `entrepot` (ouest), `port` (est), `ville_haute` (sud-est) | 500 marmer de l'entrepôt au port, 7 min |
| `port` | le port et l'aire-port (`port`) | 70 × 40 | `sentier` (ouest), `ville_marche` (est), `transport_garde` (passerelle) | — |
| `transport_garde` | à bord, le pont (`port`) | 20 × 9 | `port` | — |
| `barocupot` | à bord, la salle du conseil de guerre (`ciel`) | 14 × 8 | scène : retour sur l'île (`entrepot`, `from_barocupot`) | — |
| `foret_profonde` | la forêt profonde (`foret_profonde`) | 80 × 60 | `entrepot` (nord), `montagne` (est) | 400 marmer, 6 min |
| `montagne` | la montagne aux ours (`montagne`) | 80 × 60 | `foret_profonde` (ouest) | 900 marmer, 13 min |
| `ville_haute` | le centre-ville, haut (`ville`) | 60 × 52 | `sentier` (nord-ouest), `ville_marche` (sud), 4 portes de boutiques | 1 600 marmer par le chemin de la ville, 23 min depuis l'entrepôt |
| `ville_marche` | le centre-ville, place du marché (`ville`) | 56 × 44 | `ville_haute` (nord), `port` (ouest), 2 portes | 2 000 marmer du port, 28 min |
| `ville_snack`, `ville_cafe`, `ville_librairie`, `ville_projection`, `ville_boulangerie`, `ville_horloger` | intérieurs (`ville`) | 8 × 6 à 12 × 9 | leur rue | — |

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
| **Salle de lecture** | 4,5 × 7,5 | silence imposé (papier roulé de Nephren) ; un siège près du rebord de la fenêtre, avec vue sur le champ, où tout le monde s'agglutine (V1, « Les filles de l'entrepôt ») ; tables, étagères de gros livres (V2 ; V4) | porte au couloir (28,3) ; **fenêtre à banc au nord** (x 29,6), petite fenêtre à l'est (le champ est au nord-est) | `window_reading_seat`, `bookshelf_tall`, `bookshelf_tall_b`, `bookshelf_low` (livres d'images des petites), `reading_table` et sa lampe, `armchair_reading`, `book_pile` | la fenêtre (le champ, les petites au ballon) ; le livre d'images sur les emnetwiht (jour 6) |
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
| **Chambre de Chtholly** | 3,5 × 7,5 | un calendrier où elle raye les jours ; une armoire au fond de laquelle dort le chapeau offert par Willem ; un miroir, un lit, un oreiller (V1 ; VEX) ; un bureau, une chaise, une fenêtre à rideaux, une porte jamais verrouillée ; chambre bien rangée (V2 ; V3) | porte (6,2) ; fenêtre à rideaux au nord (x 6,2) | `bed_chtholly`, `desk_chtholly`, `wardrobe_chtholly` ; mur : **`wallitem_calendar`** (x 7,45) | **le calendrier : le journal du jeu** (une ligne par jour, ACTE1.md) ; l'armoire (le chapeau, après le jour 3) ; le miroir |
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

## 4 à 11. Les autres lieux

Ces lieux sont dessinés dans la suite de ce document.

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
192 images ou matières citées : 127 livrées ; 3 proposées ; 62 à livrer.

| Image ou matière | Cartes | État |
| --- | --- | --- |
| `alder` | entrepot | à livrer (cahier n° 3) |
| `archive_shelves` | entrepot_rdc | livrée : `assets/hd2d/interior/props/archive_shelves.png` |
| `armchair_reading` | entrepot_rdc | à livrer (cahier n° 3) |
| `ball` | entrepot | livrée : `assets/hd2d/props/ball.png` |
| `ball_white` | entrepot_rdc | livrée : `assets/hd2d/interior/props/ball_white.png` |
| `bath_puddles` | entrepot_rdc | à livrer (cahier n° 3) |
| `bath_tub` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bath_tub.png` |
| `bed_child` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_child.png` |
| `bed_child_messy` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_child_messy.png` |
| `bed_chtholly` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_chtholly.png` |
| `bed_iron` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bed_iron.png` |
| `bed_nygglatho` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_nygglatho.png` |
| `bed_plain` | entrepot_etage | livrée : `assets/hd2d/interior/props/bed_plain.png` |
| `bedside_table` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bedside_table.png` |
| `bench_b` | entrepot | livrée : `assets/hd2d/props/bench_b.png` |
| `board_games_shelf` | entrepot_rdc | livrée : `assets/hd2d/interior/props/board_games_shelf.png` |
| `boardwalk` | entrepot | livrée : `assets/hd2d/decals/boardwalk.png` |
| `book_pile` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `bookshelf_low` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/props/bookshelf_low.png` |
| `bookshelf_tall` | entrepot_rdc | livrée : `assets/hd2d/interior/props/bookshelf_tall.png` |
| `bookshelf_tall_b` | entrepot_rdc | à livrer (cahier n° 3) |
| `bramble_hedge` | entrepot | à livrer (cahier n° 3) |
| `bunk_bed` | entrepot_etage | à livrer (cahier n° 3) |
| `bush_c` | entrepot | livrée : `assets/hd2d/props/bush_c.png` |
| `cards_floor` | entrepot_etage | à livrer (cahier n° 3) |
| `chair_child` | entrepot_rdc | livrée : `assets/hd2d/interior/props/chair_child.png` |
| `chair_guest` | entrepot_etage | livrée : `assets/hd2d/interior/props/chair_guest.png` |
| `chair_wood` | entrepot_rdc | livrée : `assets/hd2d/interior/props/chair_wood.png` |
| `chair_wood_back` | entrepot_rdc | livrée : `assets/hd2d/interior/props/chair_wood_back.png` |
| `chalk_hopscotch` | entrepot | livrée : `assets/hd2d/decals/chalk_hopscotch.png` |
| `chimney_brick` | entrepot_toit | livrée : `assets/hd2d/props/chimney_brick.png` |
| `china_cabinet` | entrepot_rdc | livrée : `assets/hd2d/interior/props/china_cabinet.png` |
| `cleaning_set` | entrepot_rdc | à livrer (cahier n° 3) |
| `climbing_tree` | entrepot | livrée : `assets/hd2d/props/climbing_tree.png` |
| `clothes_chest` | entrepot_etage | à livrer (cahier n° 3) |
| `clothes_floor` | entrepot_etage | à livrer (cahier n° 3) |
| `coffee_tray` | entrepot_rdc | à livrer (cahier n° 3) |
| `comm_crystal` | entrepot_etage | livrée : `assets/hd2d/interior/props/comm_crystal.png` |
| `crypt_pillar` | salle_des_armes | livrée : `assets/hd2d/interior/props/crypt_pillar.png` |
| `crypt_stairs` | salle_des_armes | à livrer (cahier n° 3) |
| `crystal_lamp_table` | entrepot_rdc | à livrer (cahier n° 3) |
| `crystal_pendant` | entrepot_rdc | à livrer (cahier n° 3) |
| `crystal_stove` | entrepot_rdc | livrée : `assets/hd2d/interior/props/crystal_stove.png` |
| `desk_buried` | entrepot_rdc | livrée : `assets/hd2d/interior/props/desk_buried.png` |
| `desk_chtholly` | entrepot_etage | livrée : `assets/hd2d/interior/props/desk_chtholly.png` |
| `desk_clean_brooch` | entrepot_etage | à livrer (cahier n° 3) |
| `desk_nygglatho` | entrepot_etage | livrée : `assets/hd2d/interior/props/desk_nygglatho.png` |
| `dining_table_long` | entrepot_rdc | livrée : `assets/hd2d/interior/props/dining_table_long.png` |
| `dining_table_set` | entrepot_rdc | livrée : `assets/hd2d/interior/props/dining_table_set.png` |
| `door_armory` | entrepot_rdc | à livrer (cahier n° 3) |
| `door_armory_inside` | salle_des_armes | à livrer (cahier n° 3) |
| `door_double` | entrepot_rdc | livrée : `assets/hd2d/interior/door_double.png` |
| `door_room` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/door_room.png` |
| `door_service` | entrepot_rdc | à livrer (cahier n° 3) |
| `dresser_child` | entrepot_etage | livrée : `assets/hd2d/interior/props/dresser_child.png` |
| `drying_frame` | entrepot_toit | livrée : `assets/hd2d/interior/props/drying_frame.png` |
| `fern_a` | entrepot | livrée : `assets/hd2d/props/fern_a.png` |
| `filing_cabinet` | entrepot_rdc | à livrer (cahier n° 3) |
| `fireplace` | entrepot_etage | livrée : `assets/hd2d/interior/props/fireplace.png` |
| `firewood_pile` | entrepot | livrée : `assets/hd2d/props/firewood_pile.png` |
| `floor_cushions` | entrepot_rdc | à livrer (cahier n° 3) |
| `floor_flagstone_cellar` | salle_des_armes | à livrer (cahier n° 3) |
| `floor_kitchen_tiles` | entrepot_rdc | livrée : `assets/hd2d/interior/floor_kitchen_tiles.png` |
| `floor_planks_dark` | entrepot_etage | livrée : `assets/hd2d/interior/floor_planks_dark.png` |
| `floor_planks_worn` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/floor_planks_worn.png` |
| `floor_roof_deck` | entrepot_toit | à livrer (cahier n° 3) |
| `floor_tiles_bath` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/floor_tiles_bath.png` |
| `flower_bed` | entrepot | livrée : `assets/hd2d/props/flower_bed.png` |
| `flower_pots` | entrepot | livrée : `assets/hd2d/props/flower_pots.png` |
| `footlocker` | entrepot_etage | à livrer (cahier n° 3) |
| `forest_floor` | entrepot | livrée : `assets/hd2d/ground/forest_floor.png` |
| `game_table` | entrepot_rdc | livrée : `assets/hd2d/interior/props/game_table.png` |
| `garden_soil` | entrepot | livrée : `assets/hd2d/ground/garden_soil.png` |
| `garden_tools` | entrepot | livrée : `assets/hd2d/props/garden_tools.png` |
| `grass` | entrepot | livrée : `assets/hd2d/ground/grass.png` |
| `grass_b` | entrepot | livrée : `assets/hd2d/ground/grass_b.png` |
| `grass_dry` | entrepot | livrée : `assets/hd2d/ground/grass_dry.png` |
| `hamper` | entrepot_rdc | à livrer (cahier n° 3) |
| `hearth_fire` | entrepot_etage | livrée : `assets/hd2d/anim/hearth_fire.png` |
| `infirmary_desk` | entrepot_rdc | livrée : `assets/hd2d/interior/props/infirmary_desk.png` |
| `kitchen_counter` | entrepot_rdc | livrée : `assets/hd2d/interior/props/kitchen_counter.png` |
| `kitchen_table_ingredients` | entrepot_rdc | livrée : `assets/hd2d/interior/props/kitchen_table_ingredients.png` |
| `laundry_basket` | entrepot_toit | livrée : `assets/hd2d/props/laundry_basket.png` |
| `leak_bucket` | entrepot_etage | à livrer (cahier n° 3) |
| `leak_drip` | entrepot_etage | à livrer (cahier n° 3) |
| `marsh_snag` | entrepot | à livrer (cahier n° 3) |
| `meadow_flowers` | entrepot | livrée : `assets/hd2d/ground/meadow_flowers.png` |
| `meal_lunch` | entrepot_rdc | livrée : `assets/hd2d/interior/props/meal_lunch.png` |
| `medicine_cabinet` | entrepot_rdc | livrée : `assets/hd2d/interior/props/medicine_cabinet.png` |
| `mirror_large` | entrepot_rdc | livrée : `assets/hd2d/interior/props/mirror_large.png` |
| `oak_a` | entrepot | livrée : `assets/hd2d/props/oak_a.png` |
| `oil_lamp` | entrepot_etage | à livrer (cahier n° 3) |
| `pantry_cupboard` | entrepot_rdc | à livrer (cahier n° 3) |
| `paper_pile_a` | entrepot_rdc | livrée : `assets/hd2d/interior/props/paper_pile_a.png` |
| `paper_pile_b` | entrepot_rdc | livrée : `assets/hd2d/interior/props/paper_pile_b.png` |
| `paper_pile_c` | entrepot_rdc | livrée : `assets/hd2d/interior/props/paper_pile_c.png` |
| `papers_floor` | entrepot_rdc | à livrer (cahier n° 3) |
| `path_dirt` | entrepot | livrée : `assets/hd2d/ground/path_dirt.png` |
| `path_dirt_b` | entrepot | livrée : `assets/hd2d/ground/path_dirt_b.png` |
| `peat` | entrepot | livrée : `assets/hd2d/ground/peat.png` |
| `piano_old` | entrepot_rdc | à livrer (cahier n° 3) |
| `play_goal` | entrepot | livrée : `assets/hd2d/props/play_goal.png` |
| `play_goal_red` | entrepot | livrée : `assets/hd2d/props/play_goal_red.png` |
| `plush_blue` | entrepot_rdc | livrée : `assets/hd2d/interior/props/plush_blue.png` |
| `plush_pile` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/props/plush_pile.png` |
| `pot_steam` | entrepot_rdc | à livrer (cahier n° 3) |
| `rain_barrel` | entrepot | livrée : `assets/hd2d/props/rain_barrel.png` |
| `reading_table` | entrepot_rdc | livrée : `assets/hd2d/interior/props/reading_table.png` |
| `reeds` | entrepot | livrée : `assets/hd2d/props/reeds.png` |
| `reeds_b` | entrepot | livrée : `assets/hd2d/props/reeds_b.png` |
| `repair_planks` | entrepot_etage | à livrer (cahier n° 3) |
| `rock` | entrepot_toit | livrée : `assets/hd2d/ground/rock.png` |
| `roof_hatch` | entrepot_toit | à livrer (cahier n° 3) |
| `roof_ladder` | entrepot_etage | **nom proposé** (absent des cahiers) |
| `roof_railing_broken` | entrepot_toit | à livrer (cahier n° 3) |
| `rug_brown` | entrepot_etage | livrée : `assets/hd2d/decals/rug_brown.png` |
| `rug_playroom` | entrepot_rdc | livrée : `assets/hd2d/decals/rug_playroom.png` |
| `runner_rug` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `sacks_vegetables` | entrepot_rdc | à livrer (cahier n° 3) |
| `shelf_nygglatho` | entrepot_etage | livrée : `assets/hd2d/interior/props/shelf_nygglatho.png` |
| `shoe_rack` | entrepot_rdc | livrée : `assets/hd2d/interior/props/shoe_rack.png` |
| `sink_stone` | entrepot_rdc | livrée : `assets/hd2d/interior/props/sink_stone.png` |
| `sofa_beige` | entrepot_rdc | livrée : `assets/hd2d/interior/props/sofa_beige.png` |
| `stairs_down` | entrepot_etage | à livrer (cahier n° 3) |
| `stairs_up` | entrepot_rdc | livrée : `assets/hd2d/interior/props/stairs_up.png` |
| `stick_rack` | entrepot | livrée : `assets/hd2d/props/stick_rack.png` |
| `stream_bed` | entrepot | livrée : `assets/hd2d/ground/stream_bed.png` |
| `stump_a` | entrepot | livrée : `assets/hd2d/props/stump_a.png` |
| `stump_axe` | entrepot | livrée : `assets/hd2d/props/stump_axe.png` |
| `stump_b` | entrepot | livrée : `assets/hd2d/props/stump_b.png` |
| `supply_cupboard` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `sword_rack_a` | salle_des_armes | livrée : `assets/hd2d/interior/props/sword_rack_a.png` |
| `sword_rack_b` | salle_des_armes | livrée : `assets/hd2d/interior/props/sword_rack_b.png` |
| `swords_wrapped` | salle_des_armes | livrée : `assets/hd2d/interior/props/swords_wrapped.png` |
| `tableware_a` | entrepot_rdc | livrée : `assets/hd2d/interior/props/tableware_a.png` |
| `talisman_chest` | salle_des_armes | à livrer (cahier n° 3) |
| `tea_table` | entrepot_etage | livrée : `assets/hd2d/interior/props/tea_table.png` |
| `tea_tray_cheesecake` | entrepot_etage | à livrer (cahier n° 3) |
| `thicket_a` | entrepot | à livrer (cahier n° 3) |
| `thicket_b` | entrepot | à livrer (cahier n° 3) |
| `thicket_c` | entrepot | à livrer (cahier n° 3) |
| `towel_shelf` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/props/towel_shelf.png` |
| `toy_chest` | entrepot_rdc | livrée : `assets/hd2d/interior/props/toy_chest.png` |
| `toys_a` | entrepot | livrée : `assets/hd2d/props/toys_a.png` |
| `vase_flowers` | entrepot_rdc | à livrer (cahier n° 3) |
| `vegetable_patch` | entrepot | livrée : `assets/hd2d/props/vegetable_patch.png` |
| `wall_cellar_stone` | salle_des_armes | à livrer (cahier n° 3) |
| `wall_kitchen_tiles` | entrepot_rdc | livrée : `assets/hd2d/interior/wall_kitchen_tiles.png` |
| `wall_lantern` | entrepot | livrée : `assets/hd2d/props/wall_lantern.png` |
| `wall_plaster_worn` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/wall_plaster_worn.png` |
| `wall_wainscot` | entrepot_rdc | livrée : `assets/hd2d/interior/wall_wainscot.png` |
| `wall_wallpaper_faded` | entrepot_etage | livrée : `assets/hd2d/interior/wall_wallpaper_faded.png` |
| `wallitem_apron_hook` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_bath_rules` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_bath_rules.png` |
| `wallitem_bronze_plaque` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_bronze_plaque.png` |
| `wallitem_calendar` | entrepot_etage | livrée : `assets/hd2d/interior/wallitem_calendar.png` |
| `wallitem_chore_chart` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_chore_chart.png` |
| `wallitem_clippings` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_coat_hooks` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_coat_hooks.png` |
| `wallitem_cobweb` | salle_des_armes | à livrer (cahier n° 3) |
| `wallitem_crystal_sconce` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_day_calendar` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_day_calendar.png` |
| `wallitem_frame_landscape` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_height_marks` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_kids_drawings` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_labcoat` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_menu_board` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_menu_board.png` |
| `wallitem_notice_a` | entrepot_etage | livrée : `assets/hd2d/interior/wallitem_notice_a.png` |
| `wallitem_notice_b` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_notice_b.png` |
| `wallitem_notices_mix` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_spice_shelf` | entrepot_rdc | à livrer (cahier n° 3) |
| `wallitem_utensils` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_utensils.png` |
| `wallitem_wall_clock` | entrepot_rdc | livrée : `assets/hd2d/interior/wallitem_wall_clock.png` |
| `wallitem_wall_lamp` | entrepot_etage | livrée : `assets/hd2d/interior/wallitem_wall_lamp.png` |
| `wardrobe_chtholly` | entrepot_etage | livrée : `assets/hd2d/interior/props/wardrobe_chtholly.png` |
| `wardrobe_plain` | entrepot_etage | livrée : `assets/hd2d/interior/props/wardrobe_plain.png` |
| `warehouse_front_a` | entrepot | **nom proposé** (absent des cahiers) |
| `warehouse_front_b` | entrepot | **nom proposé** (absent des cahiers) |
| `warehouse_porch` | entrepot | livrée : `assets/hd2d/buildings/warehouse_porch.png` |
| `wash_tub` | entrepot_rdc | livrée : `assets/hd2d/interior/props/wash_tub.png` |
| `washbasin_stand` | entrepot_rdc | à livrer (cahier n° 3) |
| `washstand_corridor` | entrepot_rdc | livrée : `assets/hd2d/interior/props/washstand_corridor.png` |
| `water_tub` | entrepot_rdc | livrée : `assets/hd2d/interior/props/water_tub.png` |
| `watering_can` | entrepot | livrée : `assets/hd2d/props/watering_can.png` |
| `wheelbarrow` | entrepot | livrée : `assets/hd2d/props/wheelbarrow.png` |
| `window_bare` | entrepot_etage | à livrer (cahier n° 3) |
| `window_cross_large` | entrepot_rdc | livrée : `assets/hd2d/interior/window_cross_large.png` |
| `window_cross_small` | entrepot_etage, entrepot_rdc | livrée : `assets/hd2d/interior/window_cross_small.png` |
| `window_curtains_closed` | entrepot_etage | à livrer (cahier n° 3) |
| `window_curtains_open` | entrepot_etage, entrepot_rdc | à livrer (cahier n° 3) |
| `window_dusty` | entrepot_rdc | à livrer (cahier n° 3) |
| `window_reading_seat` | entrepot_rdc | livrée : `assets/hd2d/interior/window_reading_seat.png` |
<!-- /inventaire -->
