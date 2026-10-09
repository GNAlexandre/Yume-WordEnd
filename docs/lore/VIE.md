# La vie de l'entrepôt et de l'île n° 68

Ce document dit qui est où, à quel moment, et ce qu'il y fait : les **emplois du temps** des
personnages et des habitants, leurs **variations** selon le jour de l'acte 1, les **jeux des
petites** et la **faune**. Il sert aux lots E4 (vie), E5 (faune) et E8 (jeux) de
`docs/REFONTE.md` (section 7). Il prolonge la section 4 de `docs/REFONTE.md` ; les lieux et leurs
**points nommés** sont ceux de `docs/lore/CARTE.md` (`carte:point`) ; les jours et les scènes, ceux
de `docs/lore/ACTE1.md`.

**Sources.** Citées comme dans les dossiers du canon (`docs/lore/canon/`) : `(V1, « L'Homme sans
Marque »)`. Ce que l'œuvre ne dit pas et que ce document décide est marqué **(original)**. Les
volumes 2 à 5 ne servent ici qu'aux gestes et aux habitudes de la maison, jamais à un fait de
l'histoire (`MONDE.md`, 1.5).

## 0. Mode d'emploi

### 0.1 Les moments et les cloches

On compte les heures en **cloches** (V1, « La femme forte et robotique ») ; l'horloge des archives
les sonne **(original)**. Le jeu n'affiche pas d'heure.

| Moment | Cloches (original) | Repères | Lumière (E9) |
| --- | --- | --- | --- |
| **aube** | 1re (vers 6 h) | lever, toilette à l'eau froide, oiseaux bruyants (V3) | brume sur le marais, ciel pâle |
| **matin** | 2e à 4e | petit-déjeuner à la 2e cloche, heure fixe ; corvées, entraînements, linge | matin |
| **midi** | 5e (vers midi) | déjeuner, prière, fourchettes levées ensemble | plein jour |
| **après-midi** | 6e et 7e | ballon, lecture, sieste, goûter, café du village, cinéma en ville | après-midi |
| **soir** | 8e (le couchant) | dîner, jeux de société | couchant |
| **nuit** | — | bain, coucher des petites, veillée des grandes, archives | nuit |

Une cloche toutes les heures et demie depuis l'aube met la huitième au couchant d'automne
**(original)** ; la réparation de l'horloge des Limashenka finit « vers deux heures » (VEX,
« L'homme-chat ») : à la 6e cloche.

### 0.2 Les planches et leurs animations

Chaque case d'emploi du temps nomme une **animation d'une planche livrée** (`assets/characters/<id>/`,
clés lues dans les `.json`) sous la forme `planche:animation`. Une planche encore à livrer est dite
« à livrer » avec sa priorité au cahier n° 3 (`docs/ASSETS_HD2D_SUKASUKA.md`, section 4), suivie de
son repli.

| Planche | Animations livrées | Qui |
| --- | --- | --- |
| `willem` | `repos`, `marche`, `parle` | Willem en uniforme (dehors, en ville) |
| `willem_home` | `repos`, `marche`, `parle`, `course`, `assis`, `lit`, `dort`, `porte`, `effondre` | Willem à la maison |
| `willem_cook` | `repos`, `marche`, `parle`, `travaille`, `porte` | Willem en tablier |
| `willem_coat` | `repos`, `marche`, `parle`, `course` | Willem en pardessus (jour 11, pluie) |
| `nygglatho` | `repos`, `marche`, `parle` | Nygglatho |
| `nygglatho_life` | `repos`, `course`, `porte`, `hanches`, `assis`, `lit`, `dort`, `etreinte` | Nygglatho (complément) |
| `nygglatho_tea` | `repos`, `parle`, `travaille`, `porte` | le thé, le plateau |
| `chtholly_home` | `repos`, `marche`, `parle`, `course`, `frappe`, `assis`, `lit`, `dort`, `hanches` | Chtholly dans une séquence |
| `ithea_home`, `nephren_home` | `repos`, `marche`, `parle`, `course`, `frappe`, `assis`, `lit`, `dort` | les aînées à la maison |
| `ithea`, `nephren`, `chtholly` | `repos`, `marche`, `course`, `attaque`, `charge`, `degats`, `mort` (+ `parle`) | en uniforme, l'épée au dos |
| `tiat_life`, `collon_life`, `lakhesh_life`, `almita_life` | `repos`, `course`, `saut`, `frappe`, `lance`, `grimpe`, `assis`, `lit`, `dort`, `tombe` | les petites nommées (avec `repos`, `marche`, `parle` de leur planche de base) |
| `pannibal_life` | les mêmes, plus `attaque` (l'épée de bois) | Pannibal |
| `tiat_pajamas`, `collon_pajamas`, `pannibal_pajamas`, `lakhesh_pajamas` | `repos`, `marche`, `parle`, `course`, `tombe`, `assis`, `dort`, `travaille` (la toilette) | le soir et le matin |
| `fairy_01` à `fairy_06` | `repos`, `marche`, `parle`, `course`, `saut`, `frappe`, `lance`, `grimpe`, `assis`, `lit`, `dort`, `tombe` | les fées génériques livrées |
| `cat_waiter`, `snack_vendor`, `baker`, `egg_vendor`, `ramikeldi`, `ferryman`, `garde_lookout`, `limeskin` | `repos`, `marche`, `parle` | habitants et visiteurs livrés |

**À livrer** (cahier n° 3) : `kana`, `giniette` (prio 2 ; repli `fairy_03`, `fairy_05`) ;
`fairy_07` à `fairy_12` (prio 2 ; repli : les six premières, répétées telles quelles) ; `almita_pajamas`, les pyjamas des aînées (prio 2) ; les tenues de pluie `_rain` (prio 2) ;
`nygglatho_labcoat`, `nygglatho_rain` (prio 2) ; les planches de bâton `_stick` (prio 3) ; les
hommes-bêtes de métier et les passants (section 4.11, prio 2 et 3) ; la faune (section 7, prio 2 et
3). Les gestes `travaille` des habitants livrés (le serveur, le lycanthrope, le boulanger) sont à
livrer avec leurs planches de métier ; en attendant, `parle` ou `repos`.

### 0.3 Lire une case

Une case donne : **où** (`carte:point`, ou la pièce), **ce qu'il fait**, **l'animation**. Un trajet
entre deux moments se fait à pied, en `marche` (adultes), en `course` (petites, toujours, même dans
les couloirs, où une grande ou Nygglatho les gronde : `nygglatho_life:hanches`). Un personnage
change de carte par les sorties de `CARTE.md`, sans se téléporter sous les yeux du joueur
**(original)** : il part par une sortie et arrive par le marqueur de la carte suivante.

### 0.4 Règles de vie (pour E4)

- **Une vue, de la vie** : au moins un personnage, un animal ou une animation dans chaque écran
  (`docs/REFONTE.md`, 2) ; les emplois du temps sont faits pour cela : le joueur croise toujours
  quelqu'un à l'entrepôt.
- **Réactions au joueur** **(original)** :
  - les petites s'arrêtent, saluent Chtholly (`parle`), lui racontent un ragot (Collon), lui
    montrent quelque chose (Tiat) ; elles repartent à leur activité au bout de 4 s ;
  - une petite qu'on gronde (« On ne court pas ! ») marche 5 s, puis recourt ;
  - les adultes disent une réplique liée au moment et au jour ; les habitants du village et de la
    ville saluent poliment les fées, un peu raides quand Nygglatho est là (V1 ; V5 : ils craignent
    l'entrepôt à cause d'elle), sans aucune hostilité ;
  - personne ne bloque le passage plus de 2 s : on s'écarte.
- **Groupes** : les petites vont par groupes de 3 à 5 ; un groupe garde sa formation (une meneuse,
  les autres à 1,5 m) ; aux repas, chacune a sa place au réfectoire (section 2.4).
- **Densité** : à l'entrepôt, de 15 à 25 fées visibles dehors l'après-midi, de 5 à 10 dans le
  rez-de-chaussée ; jamais les trente au même endroit, sauf au réfectoire et au départ.

## 1. La journée de l'entrepôt

D'après `docs/REFONTE.md` (4.1) et les dossiers (V1 ; V3 ; VEX ; V5), avec les lieux de `CARTE.md`.

| Moment | Ce qui se passe | Où |
| --- | --- | --- |
| Aube | oiseaux bruyants ; lever en pyjama ; toilette du visage à l'eau froide et brosse à dents (Collon refuse l'eau glacée) ; Nygglatho monte le linge ; certains jours, Willem part au marché | dortoirs ; `entrepot_rdc:point_eau` ; `entrepot_toit` ; `sentier` |
| Matin | petit-déjeuner à heure fixe (en retard, plus rien) ; entraînement de base des petites au champ ; à partir du jour 9, entraînement des aînées au bâton dans la clairière ; corvées ; linge sur le toit ; Lakhesh à la boulangerie | réfectoire ; `entrepot:champ`, `clairiere` ; toit ; `ville_boulangerie` |
| Midi | prière collective, fourchettes levées ensemble ; déjeuner (purée, porc sauté, soupe aux herbes, une orange : VEX, intermède) | réfectoire |
| Après-midi | ballon dans le champ ; lecture en silence ; sieste ; goûter au café du village avec l'argent de poche ; cinéma en ville avec un adulte ; thé chez Nygglatho | champ ; salle de lecture ; dortoirs ; `cafe` ; `ville_projection` ; chambre de Nygglatho |
| Soir | dîner de la cuisinière du jour ; course du couloir pour le dessert ; jeux de société, tour de fées | réfectoire ; couloir ; salle de jeux |
| Nuit | bain, séchage des cheveux (on fuit la serviette) ; petites couchées tôt ; aînées et Nygglatho veillent au réfectoire ; Willem aux archives ; Nephren sur le toit ; la lumière sous la porte de Nygglatho | salle de bains ; dortoirs ; réfectoire ; archives ; toit |

## 2. Les emplois du temps

Les tableaux donnent la **journée de base** : celle des jours 4 à 6 et 9 à 11, hors scènes. Les
jours qui la changent sont en section 3 ; une scène de `ACTE1.md` l'emporte toujours sur la case.

### 2.1 Willem

| Moment | Où | Ce qu'il fait | Animation |
| --- | --- | --- | --- |
| Aube | `entrepot_etage:willem_lit`, puis `entrepot_rdc:point_eau` | il se lève avant les petites ; toilette | `willem_home:dort`, puis `repos` |
| Aube (jours 4 et 6) | `sentier` → `ville_marche:place_centre` | il part au marché du matin, un panier au bras, et rentre avant midi (V3, habitude reprise **original** à l'acte 1) | `willem_home:porte` |
| Matin (jours 9 à 12) | `entrepot:clairiere_centre` | l'entraînement des aînées au bâton | `willem_home:repos` (planche `willem_stick`, prio 3) |
| Matin (autres jours) | `entrepot_rdc:archives_bureau`, ou le couloir de l'étage (`couloir_fuite`) | il lit les rapports ; il répare le plafond qui fuit au marteau | `willem_home:lit` ; geste au marteau à livrer, repli `repos` et le bruit |
| Midi | `entrepot_rdc:refectoire_bout_est` | déjeuner ; il lève sa fourchette avec les autres | `willem_home:assis` |
| Après-midi | `entrepot:champ_centre` | le ballon avec les petites ; il fait des passes, ne marque jamais | `willem_home:course` (la passe du pied, `frappe`, à livrer) |
| Après-midi (pluie) | `entrepot_rdc:jeux_tapis` | il lit aux petites, ou répare un jouet | `willem_home:lit`, `assis` |
| Soir (jours 4, 6, 9 et 11) | `entrepot_rdc:cuisine_fourneau` | un dessert, en tablier, la porte fermée | `willem_cook:travaille` |
| Soir | réfectoire, puis `entrepot_rdc:jeux_tapis` | dîner ; jeux de société assis par terre ; la tour de fées s'empile sur lui | `willem_home:assis` |
| Nuit | `entrepot_rdc:archives_bureau`, puis `willem_lit` | il fouille les archives tard ; il se couche | `willem_home:lit`, puis `dort` |

Gestes de Willem (`docs/REFONTE.md`, 4.3) : tablier en cuisine, assis au rebord de la fenêtre,
bâtons sous le bras, marteau au plafond qui fuit, petites portées sur les épaules (`porte`).

### 2.2 Nygglatho

| Moment | Où | Ce qu'elle fait | Animation |
| --- | --- | --- | --- |
| Aube | `entrepot_toit:toit_sechoir` | elle monte le panier de linge et l'étend (VEX, « L'homme-chat ») | `nygglatho_life:porte`, puis `repos` |
| Matin | `entrepot_rdc:infirmerie_bureau` | soins, en blouse | `nygglatho_life:assis` (blouse : `nygglatho_labcoat`, prio 2) |
| Matin | `entrepot_rdc:planning` | elle vérifie les corvées ; une remontrance au passage | `nygglatho_life:hanches` |
| Midi | `entrepot_rdc:refectoire_bout_ouest` | déjeuner ; elle sert les retardataires (s'il en reste) | `nygglatho_tea:porte`, puis `nygglatho_life:assis` |
| Après-midi | `entrepot_etage:nygglatho_the` | le thé : elle verse le lait, tourne la cuillère ; réunions des grandes | `nygglatho_tea:travaille` |
| Après-midi (jours 2 et 9) | `entrepot:porche_banc` | l'argent de poche, en cachette, un clin d'œil (VEX) | `nygglatho:parle` |
| Soir | `entrepot_rdc:refectoire_allee` | elle sert le dîner ; menace gourmande quand on traîne | `nygglatho_tea:porte`, `nygglatho_life:hanches` |
| Nuit | `entrepot_rdc:refectoire_bout_ouest` | la veillée avec les aînées : thé, cheese-cake (VEX) | `nygglatho_tea:travaille` |
| Nuit (tard) | `entrepot_etage:nygglatho_bureau` | elle écrit ; la lumière filtre sous sa porte | `nygglatho_life:lit`, puis `dort` |

Gestes (`docs/REFONTE.md`, 4.3) : mains jointes près du visage (`parle`), poings sur les hanches
(`hanches`), plateau, panier de linge (`porte`), blouse à l'infirmerie, l'étreinte d'une petite qui
pleure (`etreinte`).

### 2.3 Ithea et Nephren

Hors des scènes, les deux aînées vivent comme Chtholly vivrait : leurs cases disent où le joueur
les trouve.

**Ithea** (`ithea_home`) :

| Moment | Où | Ce qu'elle fait | Animation |
| --- | --- | --- | --- |
| Aube | `entrepot_etage:ithea_lit` | elle traîne au lit | `dort` |
| Matin | `entrepot:champ` ; à partir du jour 9, `entrepot:clairiere_banc` | elle mène l'entraînement de base des petites ; puis l'entraînement au bâton, assise sur le banc en balançant le pied entre deux reprises | `course`, `assis` |
| Midi | réfectoire, à côté de Chtholly | déjeuner ; ragots | `assis` |
| Après-midi | `entrepot:porche_banc`, ou `cafe:table_fees` | elle lit un roman d'amour et le recommande à qui passe ; le café du village | `lit` |
| Soir | `entrepot_rdc:jeux_tapis` | jeux de société ; elle triche en riant | `assis` |
| Nuit | `entrepot_rdc:refectoire_bout_ouest`, puis `ithea_lit` | la veillée ; puis au lit avec son roman | `assis`, `lit`, `dort` |

**Nephren** (`nephren_home`) :

| Moment | Où | Ce qu'elle fait | Animation |
| --- | --- | --- | --- |
| Aube | `entrepot_etage:nephren_lit` | elle dort encore | `dort` |
| Matin | `entrepot:champ` ; à partir du jour 9, la clairière | entraînement ; elle encaisse sans changer de visage | `course`, `assis` |
| Midi | réfectoire | elle mange en silence | `assis` |
| Après-midi | `entrepot_rdc:lecture_table` | la lecture ; elle impose le silence d'un papier roulé | `lit` |
| Soir | `entrepot_rdc:jeux_tapis` ; certains soirs, `entrepot_toit:toit_balustrade_nord` | jeux ; ou les nuages, du toit | `assis`, `repos` |
| Nuit | `entrepot_toit:toit_balustrade_nord`, puis `nephren_lit` | les étoiles ; elle s'endort sur les genoux de qui est assis | `repos`, `dort` |

### 2.4 Les petites nommées

Les quatre inséparables, Tiat, Collon, Pannibal et Lakhesh (VEX), dorment au dortoir B
(`entrepot_etage:dortoir_b`) ; Almita, Kana et Giniette au dortoir A (`dortoir_a`) **(original)**.
Au réfectoire, elles ont leur table, au milieu, côté nord. Planches : `<id>_life` et `<id>` le
jour, `<id>_pajamas` à l'aube et la nuit.

**Tiat** (cheveux vert feuille ; admire Chtholly) :

| Moment | Où | Ce qu'elle fait | Animation |
| --- | --- | --- | --- |
| Aube | `dortoir_b`, puis `entrepot_rdc:point_eau` | lever ; elle court partout avec une serviette pour essuyer les autres | `tiat_pajamas:course`, `travaille` |
| Matin | `entrepot:champ` | entraînement de base ; elle veut une épée aussi grande que Seniorious (**clin d'œil**) | `tiat_life:course`, `lance` |
| Midi | réfectoire | déjeuner | `tiat_life:assis` |
| Après-midi | `entrepot:champ` | le ballon, chez les blancs | `tiat_life:course`, `frappe` |
| Soir | réfectoire, puis salle de jeux | à partir du jour 9, elle boit son thé à la moutarde d'un trait en criant, comme Chtholly (VEX) | `tiat_life:assis` |
| Nuit | salle de bains, puis `dortoir_b` | elle essuie les cheveux des autres ; au lit | `tiat_pajamas:travaille`, `dort` |

À partir du jour 9 **(original)** : une fois par moment, Tiat suit Chtholly à 3 m pendant 20 s et
l'imite (elle s'arrête quand Chtholly s'arrête, croise les bras quand elle parle).

**Collon** (cheveux roses ; bruyante, ragots) :

| Moment | Où | Ce qu'elle fait | Animation |
| --- | --- | --- | --- |
| Aube | `entrepot_rdc:point_eau` | elle trempe un doigt, grimace et refuse l'eau glacée (VEX) | `collon_pajamas:travaille` |
| Matin | `entrepot:arbre_vigie` | elle grimpe au grand arbre, interdit, et guette tout en haut, une main en visière (V5) | `collon_life:grimpe`, `repos` |
| Midi | réfectoire | elle répète les nouvelles à voix haute | `collon_life:assis`, `collon:parle` |
| Après-midi | `entrepot:champ` | le ballon, chez les rouges ; la première à crier | `collon_life:course`, `frappe` |
| Soir | salle de jeux | la première à sauter sur la pile | `collon_life:saut` |
| Nuit | `dortoir_b` | elle parle encore après l'extinction | `collon_pajamas:dort` |

**Pannibal** (cheveux violets ; épée de bois) :

| Moment | Où | Ce qu'elle fait | Animation |
| --- | --- | --- | --- |
| Aube | `dortoir_b` | lever, la mèche sur l'œil | `pannibal_pajamas:repos` |
| Matin | les chemins de l'entrepôt, les fourrés de la cour | elle agite un bâton ramassé sur le sentier ; elle prépare ses embuscades (section 5.5) | `pannibal_life:attaque`, `course` |
| Midi | réfectoire | déjeuner, la brindille à la bouche | `pannibal_life:assis` |
| Après-midi | `entrepot:champ`, ou `entrepot:arbre_pied` | le ballon chez les rouges ; ou à mi-hauteur du grand arbre | `pannibal_life:course`, `grimpe` |
| Soir | salle de jeux | clés de bras sur la peluche (V2) ; la pile | `pannibal_life:frappe`, `saut` |
| Nuit | `dortoir_b` | au lit | `pannibal_pajamas:dort` |

**Lakhesh** (cheveux pêche ; polie, calme) :

| Moment | Où | Ce qu'elle fait | Animation |
| --- | --- | --- | --- |
| Aube | `sentier` → `ville_boulangerie:boulangerie_lakhesh` (à partir du jour 3) | elle part tôt aider le boulanger grincheux (V3, habitude reprise à l'acte 1 par `docs/REFONTE.md`, 4.1) | `lakhesh:marche` |
| Matin | `ville_boulangerie:boulangerie_lakhesh` | elle range les pains ; elle rentre avant midi, un petit pain pour chacune | `lakhesh_life:repos`, `lakhesh:marche` |
| Midi | réfectoire | elle propose à manger à qui n'a rien | `lakhesh_life:assis` |
| Après-midi | `entrepot_rdc:lecture_table`, ou `entrepot:arbre_pied` | la lecture ; sur une branche basse du grand arbre, tremblante (V5) | `lakhesh_life:lit`, `grimpe` |
| Soir | salle de jeux | elle essaie de gronder Collon et Pannibal, sans succès | `lakhesh:parle` |
| Nuit | `dortoir_b` | au lit | `lakhesh_pajamas:dort` |

**Almita** (la plus petite), **Kana** (la chipeuse) et **Giniette** (la timide) suivent le groupe
des petites génériques (section 2.5) avec trois différences **(original, d'après le cahier n° 3,
4.8)** : Almita tombe souvent en courant (`almita_life:tombe`) et lit des livres d'images
(`almita_life:lit`) ; Kana chipe une friandise à la cuisine le soir et la cache derrière son livre
(`kana`, à livrer) ; Giniette arrive toujours la dernière et saute la dernière sur la pile
(`giniette`, à livrer). Toutes trois sont de la tour de fées (VEX).

### 2.5 Les fées génériques

Près de trente fées vivent à l'entrepôt (V1) : les dix nommées et une vingtaine de génériques, faites
des planches `fairy_01` à `fairy_12` répétées. Les **petites** (`fairy_01` à `fairy_09`) vont par
groupes de trois à cinq ; les **grandes** (`fairy_10` à `fairy_12`, 13 à 15 ans) ont leurs rôles.

| Moment | Les petites (groupes) | Les grandes |
| --- | --- | --- |
| Aube | dortoirs A, C, D ; point d'eau du couloir (`*_pajamas:travaille`, repli `repos`) | `fairy_12`, cuisinière du jour, à `entrepot_rdc:cuisine_fourneau` (`travaille` à livrer, repli `repos`) |
| Matin | entraînement de base au champ (`course`, `saut`, `lance`) ; un groupe aux corvées (balai, seau : `repos`) ; un groupe au potager (`entrepot:potager`, `assis`) | `fairy_10` étend le linge avec Nygglatho ; `fairy_11` lit à la salle de lecture (`lit`) |
| Midi | réfectoire (`assis`) | réfectoire ; `fairy_12` sert |
| Après-midi | ballon (douze à vingt joueuses) ; le chat dans les hautes herbes (section 5.2) ; sieste au dortoir (`dort`) ; le coin d'herbe au soleil (`entrepot:coin_soleil`, `assis`) | lecture ; café du village (`cafe:table_fees`) |
| Soir | réfectoire ; course du couloir (section 5.6) ; salle de jeux (`assis`, balle contre le mur : `lance`) | réfectoire ; `fairy_12` en cuisine |
| Nuit | bain, séchage (section 5.8) ; dortoirs (`dort`) | veillée au réfectoire avec Nygglatho (`assis`) |

Une fée générique sur trois porte un livre, un ruban ou un bandage du même côté dans toutes ses
images (cahier n° 3, 4.8) ; `fairy_06` garde le bandage au genou qui sert au jour 7.

### 2.6 Les hommes-bêtes du village

Le village est campagnard ; presque personne n'y porte de beaux habits (VEX, « Cinq cents ans »).

| Qui (planche) | Aube | Matin | Midi | Après-midi | Soir | Nuit |
| --- | --- | --- | --- | --- | --- | --- |
| Le serveur homme-chat (`cat_waiter`) | — | `village:cafe_terrasse`, il balaie (`travaille` à livrer, repli `repos`) | `cafe:comptoir` (`parle`) | `cafe:comptoir` ; il offre les jus aux fées en cachette du patron (VEX) | `cafe:table_buveurs`, il sert (`marche`) | café fermé |
| Le patron (`cafe_owner`, prio 2) | — | `cafe:arriere` | `cafe:comptoir` | `cafe:comptoir`, il essuie une chope | `cafe:comptoir` | — |
| Les buveurs (`drinker_dog`, `drinker_cat`, prio 2) | — | — | — | — | `cafe:table_buveurs`, ils rient fort et chantent (`assis`, `parle`) | ils rentrent en titubant par la rue |
| La lavandière (`villager_dog_f`, prio 3) | — | `village:lavoir` | maison | `village:lavoir` | maison | — |
| Le fermier (`villager_dog_m`) | la grange | la meule et la charrette de foin | — | les jardins du sud | — | — |
| Le bûcheron (`villager_bear_m`) | il part vers la forêt par la rue | (hors de vue) | — | (hors de vue) | il rentre, la hache sur l'épaule | — |
| L'apicultrice (`villager_bear_f`) | — | — | — | `village:ruche` | — | — |
| Le pêcheur des marais (`villager_frog_m`) | `village:cascade_vue` | la rivière | — | — | — | — |
| Le facteur (`villager_bird_m`) | — | il parcourt la rue (`village`), puis le sentier | — | — | — | — |
| Ramikeldi (`ramikeldi`) | — | — | — | jour 9 : `village:cafe_terrasse` avec Willem ; jour 11 : `maison_limashenka:rami` | — | — |

La maison Limashenka reste close, volets fermés, sauf le jour 11. Quand Nygglatho traverse le
village, les habitants la saluent un peu trop poliment (V1 ; V5).

### 2.7 Les hommes-bêtes de la ville et du port

| Où | Qui (planche) | Quand | Ce qu'il fait |
| --- | --- | --- | --- |
| `ville_snack`, et son comptoir sur la rue (`ville_haute:snack_comptoir`) | le lycanthrope à la poêle (`snack_vendor`) | matin au soir | il fait sauter sa poêle (`travaille` à livrer, repli `parle`) ; ses oreilles tombent quand entrent des fées (V1) |
| `ville_cafe:cafe_comptoir` | le serveur demi-bête (`cafe_town_waiter`, prio 3) | matin au soir | il pose les tasses d'une main tremblante |
| `ville_librairie:librairie_comptoir` | la libraire (`bookseller`, prio 3) | matin, après-midi | les commandes de l'entrepôt, ficelées (V3) |
| `ville_projection:projection_allee` | le projectionniste (`projectionist`, prio 3) | après-midi (deux séances) | il tourne la manivelle ; la lumière revient à la fin (V2) |
| `ville_boulangerie:boulangerie_comptoir` | le boulanger grincheux (`baker`) | aube à midi | il grogne ; Lakhesh range les pains (`boulangerie_lakhesh`) |
| `ville_horloger:horloger_etabli` | l'horloger (`watchmaker`, prio 3) | matin, après-midi | penché sur un mécanisme |
| `ville_marche:etal_lait` et les étals | la marchande (`market_farmer`), le marchand de miel (`market_honey`), la marchande d'œufs (`egg_vendor`) | aube et matin (le marché du matin, V3) | ils vendent ; l'après-midi, la place est nue, les bâches pliées |
| `ville_marche:boucherie` | le boucher (`butcher`, prio 3) | matin | il tranche (viande parée, aucun sang) |
| `ville_haute:carrefour`, `haut_de_rue`, `fontaine`, `ville_marche:banc` | six à dix passants (`villager_*`, prio 3) ; des marchands de passage (`merchant_cat`, `merchant_lizard`, prio 3) | du matin au soir | ils marchent d'un point à l'autre, s'arrêtent à la fontaine, s'assoient sur le banc |
| `port:charrettes`, `port:aire_port` | deux dockers (`porter`, prio 2) | matin et après-midi | ils portent des sacs et poussent les charrettes (V2) |
| `port:guichet` | le commis du port (`villager_lizard_m`, **original**) | matin et après-midi | derrière son guichet, il ne voit jamais de navire à l'acte 1, sauf le jour 7 |
| `port:colline_sommet` | le guetteur de la Garde (`garde_lookout`) | tous les moments | il regarde le ciel depuis la colline toujours ventée (V3 : d'où l'on voit tout arriver) |

La nuit, la ville dort : les lanternes à cristal aux portes, deux passants au plus ; le snack ferme
au soir.

## 3. Les variations selon le jour

| Jour | Variation | Ce qui change |
| --- | --- | --- |
| 1 | **nuit d'arrivée** | la nuit seulement ; les petites en pyjama, éveillées, collées aux portes (dortoirs, couloir de l'étage) ; Pannibal dehors ; Ithea et Nephren dans leurs chambres ; Nygglatho chez elle, le thé prêt |
| 1 à 3 | **fuite** | les petites détalent quand Willem approche à moins de 6 m : elles se figent, chuchotent (« la cible »), filent vers la porte la plus proche ou derrière le grand arbre (`course`) ; Willem erre autour du bâtiment le matin, s'assoit au rebord de sa fenêtre l'après-midi (`entrepot_etage:willem_fenetre`, `willem_home:assis`), dîne seul ; pas de ballon |
| 3 | **en ville** | Willem et les trois aînées au snack-bar à midi ; l'après-midi, Willem flâne en ville (`willem`) |
| 4 | **dessert** | Willem en cuisine l'après-midi ; les petites collées à la porte de la cuisine ; dès le dîner, la fuite cesse |
| 4 à 12 | **les petites suivent Willem** | deux à quatre petites le suivent à 2 m ; quand il s'assoit, elles s'assoient (`assis`) ; quand il lit, elles se pressent autour (`lit`) |
| 5 à 12 | **ballon** | la partie chaque après-midi (section 5.1), sauf les jours 7 et 8 |
| 6 (soir) | **ordre de mission** | Nygglatho au cristal avant le dîner ; les aînées préparent leurs affaires la nuit |
| 7 | **aînées absentes, pluie** | aube : brume, les aînées partent ; matin : pluie, tout le monde dedans (salle de jeux : balle contre le mur, clés de bras sur la peluche, livres) ; après-midi : le match après la pluie (séquence 7.2), puis la petite blessée à l'infirmerie ; crépuscule : Willem au port ; nuit : infirmerie, archives |
| 7 à 9 | **la petite blessée** | `fairy_06` couchée à l'infirmerie (`infirmerie_lit_a` est à Chtholly la nuit du 7 : elle a l'autre lit), le bandage visible ; à partir du jour 10, elle rejoue au ballon, bandage compris |
| 8 | **Willem malade** | matin : Willem et Nephren endormis aux archives ; après le duel, Willem couché à l'infirmerie (`willem_home:dort`) ; les petites agglutinées devant la porte de l'infirmerie, qui chuchotent ; pas de ballon ; midi : Nygglatho au cristal ; après-midi : la réunion, puis l'infirmerie envahie ; soir : Willem monte à la colline |
| 9 à 12 | **entraînement du matin** | Willem, Ithea et Nephren à la clairière de l'aube à midi ; les petites s'entraînent seules au champ, menées par `fairy_10` |
| 9 | **café et veillée** | après-midi : les aînées au café du village ; Willem et Ramikeldi sur la terrasse ; Nygglatho absente l'après-midi, partie chasser l'ours dans la montagne (**clin d'œil**) : elle rentre au crépuscule, les manches retroussées, d'excellente humeur ; nuit : la veillée |
| 10 | **sous les nuages, averse** | matin : clairière ; le jour reste gris ; fin d'après-midi : l'averse, tout le monde rentre en courant ; après : la boue, puis le bain (section 5.8) ; soir : Nephren sur le toit, puis la tour de fées |
| 11 | **l'horloge** | aube : la toilette à l'eau glacée ; matin : Willem en pardessus (`willem_coat`), Ramikeldi à l'entrée ; jusqu'à la 6e cloche, Willem chez les Limashenka ; trois villageois attendent devant la porte pour entendre l'horloge (**original**) ; fin d'après-midi : Willem et Chtholly seuls à la clairière |
| 12 | **départ** | matin : Nygglatho repasse les uniformes au réfectoire (`nygglatho_tea:travaille`) ; les petites dessinent en secret à la salle de jeux (`assis`) ; Ithea range ses romans ; Nephren sur le toit ; Willem répare le plafond qui fuit ; après-midi : dernier ballon ; couchant : toute la maison dans la cour, en cercle autour de `entrepot:cour_centre`, Nygglatho au porche, Willem à `cour_willem` |
| pluie (7, 10) | **jour de pluie** | dehors, personne sauf qui court d'une porte à l'autre ; dedans, la salle de jeux et la salle de lecture pleines ; après la pluie, flaques et boue (E9) |

## 4. Le joueur et la vie

- **Ce que le joueur peut faire avec la vie** : parler à chacun (une réplique par moment et par jour,
  écrite d'après les cases de la section 2) ; se joindre aux jeux (section 5) ; gronder (les petites
  qui courent, qui grimpent à l'arbre, qui épient) ; aider (la cuisinière du jour, le linge).
- **Ce que la vie fait au joueur** : les embuscades de Pannibal (section 5.5) ; Tiat qui l'imite
  (section 2.4) ; les petites qui viennent lui raconter ce qu'elles ont vu (où est Willem, qui est au
  café) : c'est ainsi que le jeu glisse ses indices quand le joueur se perd **(original)**.
- **Ce que la vie ne fait jamais** : bloquer une scène ; faire rater un moment de vie ; montrer une
  petite blessée sans bandage ; une hostilité des habitants envers les fées.

## 5. Les jeux des petites

Chaque jeu dit qui, où, quand, comment il commence et finit, et comment le joueur s'y mêle. Le lot E8
fait le ballon et les combats ; les autres jeux sont des comportements de groupe du lot E4.

### 5.1 Le ballon (V1 ; V5)

- **Qui** : Willem et douze à vingt petites, en deux équipes : les **rouges** (Collon, Pannibal et des
  génériques) et les **blanches** (Tiat, Lakhesh et des génériques) **(original pour la
  répartition)**.
- **Où** : `entrepot:champ` (18 × 20 m), cages des blanches au nord (`champ_but_nord`, `play_goal`),
  des rouges au sud (`champ_but_sud`, `play_goal_red`).
- **Quand** : l'après-midi, de la 6e à la 7e cloche, du jour 5 au jour 12, sauf les jours 7 et 8.
- **Début** : après le déjeuner, les petites courent au champ, le ballon (`ball`) dans les bras ;
  Willem le pose à `champ_centre` ; coup d'envoi.
- **Règles** **(original pour les chiffres)** : deux mi-temps de trois minutes ; on marque en
  envoyant le ballon dans la cage ; à la mi-temps, on garde les meilleures buteuses pour la seconde
  (V5) ; quand une petite lance le ballon haut dans le ciel à deux mains (`lance`), il retombe au
  hasard dans un rayon de 6 m ; les maladroites touchent la balle aussi (le jeu de Willem, V1) : le
  ballon roule plus souvent vers celle qui ne l'a pas encore eu.
- **Fin** : après la seconde mi-temps, ou à la 7e cloche ; les petites rentrent goûter.
- **Le joueur** : entrer dans le champ pendant la partie, invite « Jouer » : Chtholly rejoint
  l'équipe qui a le moins de joueuses (les blanches à égalité) ; elle court et frappe
  (`chtholly_home:frappe`) ; quitter le champ la fait sortir de la partie. Le ballon perdu dans le
  fourré de l'est (`fourre_ballon`) se récupère en y entrant (pas de blessure, sauf le jour 7).
- **Après la pluie** : flaques et boue dans le champ, le ballon ralentit, les petites glissent
  (`tombe`).

### 5.2 Le chat (VEX, ill.)

- **Qui** : quatre à six petites (Tiat, Collon, deux ou trois génériques) ; parfois Chtholly : sur
  l'illustration, c'est elle le chat, un panier d'osier couvert d'un linge au bras (VEX, ill.).
- **Où** : dans les hautes herbes, au milieu des papillons orange : `entrepot:coin_soleil` et ses
  bords ; les jours 2 à 4 (sans ballon), aussi le bord du champ.
- **Quand** : matin après les corvées, ou après-midi sans ballon.
- **Début** : une petite en touche une autre et crie qu'elle est le chat ; la touchée poursuit les
  autres (`course`) ; celle qu'elle touche devient le chat.
- **Fin** : au bout de trois minutes, ou à l'appel d'un repas ; elles s'effondrent dans l'herbe en
  riant (`tombe`).
- **Le joueur** : s'approcher à moins de 3 m d'un groupe qui joue : une petite le touche, Chtholly
  devient le chat ; toucher trois petites en 60 s (elles esquivent en zigzag) ; ensuite elle rejoue
  ou s'en va. Les papillons s'envolent sur son passage (`anim/butterfly`).

### 5.3 L'avalanche (V1)

- **Qui** : trois à cinq petites collées à une porte pour épier.
- **Où** : les portes des scènes (chambre de Nygglatho, jour 1 ; chambre de Willem, jour 1 ;
  cuisine, jour 4) ; ensuite, au hasard, la chambre de Willem, la cuisine quand Willem y est, les
  archives, l'infirmerie le jour 8.
- **Quand** : au plus une par jour hors des scènes **(original)**.
- **Début** : on voit des pieds sous la porte, on entend chuchoter ; quand le joueur ouvre (ou que
  quelqu'un ouvre de l'autre côté), elles s'écroulent les unes sur les autres (`tombe`), à plat
  ventre sur le tapis.
- **Fin** : elles se relèvent, gênées, et s'enfuient (`course`) ; si Nygglatho est là, sa menace
  les disperse en un instant.
- **Le joueur** : ouvrir la porte ; ou se coller à la porte avec elles (le jour 1, au choix).

### 5.4 L'arbre interdit (V5)

- **Qui** : Collon tout en haut, une main en visière ; Pannibal à mi-hauteur ; Lakhesh tremblante sur
  une branche basse.
- **Où** : le grand arbre de la cour (`climbing_tree`, `entrepot:arbre_pied`, `arbre_vigie`).
- **Quand** : matin ou après-midi sans ballon, un jour sur deux **(original)**.
- **Début** : Collon court à l'arbre et grimpe (`grimpe`, vue de dos) ; les deux autres suivent.
  Les petites sont posées à des hauteurs fixes de l'image de l'arbre (E4).
- **Fin** : une grande, Nygglatho (`hanches`) ou le joueur les fait descendre ; sinon, au bout de
  trois minutes, Nygglatho paraît au porche, et elles descendent d'elles-mêmes, très vite.
- **Le joueur** : au pied de l'arbre, « Descendez ! » ; ou les regarder sans rien dire (Collon lui
  crie ce qu'elle voit : le village, la fumée de la ville, un navire au loin le jour 7).

### 5.5 L'embuscade (V1 ; V2)

- **Qui** : Pannibal, rejointe par Collon à partir du jour 5 ; leur cri de guerre.
- **Où** : les chemins de l'entrepôt (`entrepot`), les fourrés au bord de la cour, l'arrière du grand
  arbre, les angles des couloirs (`entrepot_rdc:couloir_ouest`, `couloir_est`).
- **Quand** : à tout moment du jour, au plus une fois par moment ; jamais pendant une scène.
- **Début** : un froissement, une lumière, le cri ; elles bondissent sur Chtholly ou sur Willem.
- **Fin** : sur Willem, il fait un pas de côté et elles s'étalent (`tombe`) (V2) ; sur Chtholly, le
  combat d'entraînement de `ACTE1.md` (3.1) : vexées et rieuses, ou victorieuses et en fuite.
- **Le joueur** : esquiver et parer ; une réussite donne une réplique (Pannibal promet de faire
  mieux).

### 5.6 La course du couloir (V5 ; V1)

- **Qui** : six à dix petites ; à partir du jour 4.
- **Où** : le couloir du rez-de-chaussée, de `entrepot_rdc:couloir_ouest` à `couloir_est` (28 m).
- **Quand** : le soir, juste avant le dîner.
- **Début** : une générique annonce le dessert ; la première arrivée au point d'eau en aura deux
  (V5) ; elles partent toutes ensemble (`course`).
- **Fin** : la gagnante lève les bras ; ou une grande crie qu'on ne court pas dans les couloirs (V1),
  et tout le monde finit en marchant, exagérément lentement.
- **Le joueur** : se mettre sur la ligne de départ (`couloir_ouest`) : il court avec elles et peut
  gagner (une réplique de la cuisinière du jour, le dessert double) ; ou gronder : la course
  s'arrête.

### 5.7 La tour de fées (VEX)

- **Qui** : Willem assis ; Nephren collée à son dos ; Collon, Pannibal, Kana, Almita et Giniette,
  l'une après l'autre ; Nygglatho en dernier, qui agite les dix doigts avant de sauter.
- **Où** : la salle de jeux, `entrepot_rdc:jeux_tapis`.
- **Quand** : la scène du jour 10 (`ACTE1.md`, 10.5) ; ensuite, les soirs des jours 10 à 12, une fois
  sur deux, avec ou sans Nygglatho.
- **Début** : Willem s'assoit par terre pour un jeu de société ; Nephren s'installe dans son dos.
- **Fin** : la pile s'écroule dans les rires (`tombe`) ; Willem, écrasé, se relève en dernier.
- **Le joueur** : « Sauter sur la pile » : Chtholly prend son élan et s'arrête toujours au bord,
  rouge (gag), puis s'en va.

### 5.8 La boue et le bain (V2 ; V3)

- **Qui** : une dizaine de petites ; Nygglatho ; Tiat et sa serviette.
- **Où** : après la pluie, le champ et la cour (`mud_patch`, flaques) ; puis la salle de bains
  (`entrepot_rdc:bains_baignoire`) et le couloir.
- **Quand** : après une pluie (jour 10 ; le jour 7, sans Chtholly) ; le bain, chaque nuit.
- **Début** : les petites courent dans la boue, sautent à pieds joints dans les flaques (le `saut`
  des planches de pluie, prio 2 ; repli `saut`), s'éclaboussent ; Nygglatho les appelle au bain.
- **Fin** : le bain se passe **hors champ** (pudeur : on ne montre jamais la baignoire occupée) ; on
  voit les petites ressortir enveloppées de serviettes et fuir le séchage des cheveux dans le
  couloir, Tiat à leurs trousses avec une serviette (`tiat_pajamas:course`).
- **Le joueur** : prendre une serviette au portemanteau des bains et rattraper une petite qui fuit
  (comme au chat) ; elle se laisse essuyer en râlant.

### 5.9 La balle contre le mur et la peluche (V2)

- **Qui** : deux à quatre petites, dont Pannibal.
- **Où** : la salle de jeux : le mur à balle (`entrepot_rdc:jeux_mur_balle`) ; la peluche sur le
  tapis.
- **Quand** : les jours de pluie, et le soir.
- **Début et fin** : une petite lance la balle contre le mur et la rattrape (`lance`) ; Pannibal
  enseigne les clés de bras sur la peluche (`frappe`) ; elles s'arrêtent à l'appel du dîner.
- **Le joueur** : rattraper la balle (une interaction) ; ou servir de « peluche » à Pannibal, qui
  renonce aussitôt.

## 6. La faune

### 6.1 Principes

- **Ce que dit l'œuvre** : des ours dans la montagne, que Nygglatho chasse (V2 ; V5 ; VEX) ; des
  oiseaux bruyants au matin (V3) ; un petit animal grimpeur qu'une fillette poursuit (V5) ; des
  papillons orange (VEX, ill.) ; les loups ne sont qu'une crainte de Willem (V1).
- **Ce qu'on ajoute** (`docs/REFONTE.md`, 4.4, **original**) : loups dans la forêt profonde,
  sangliers, cerfs, renards, écureuils, grenouilles et libellules au marais, corbeaux, une chouette.
- **Où on ne les croise pas** : ni à l'entrepôt, ni au village, ni en ville, ni au port ; seuls les
  oiseaux, les papillons et, à la lisière de l'entrepôt, un écureuil s'en approchent.
- **Jamais de sang** ; un animal vaincu s'enfuit (`ACTE1.md`, 3.5). Les planches sont dans
  `assets/fauna/<id>/` (cahier n° 3, section 7 ; toutes à livrer).
- **Fin d'automne** : pas de lucioles ; libellules seulement les jours doux (jours 2, 3, 5, 9) ;
  l'ours n'hiberne pas encore.

### 6.2 Les animaux

| Espèce (planche) | Cartes | Moments | Comportement | Animations |
| --- | --- | --- | --- | --- |
| **Merle** (`blackbird`, prio 2) | `entrepot`, `village`, `sentier`, `colline` | aube et matin | paisible ; il chante sur une branche ou au sol (les oiseaux bruyants du matin, V3) ; s'envole à 3 m | `repos`, `marche`, `fuite` |
| **Corbeau** (`crow`) | `sentier`, `port`, `foret_profonde`, `montagne` | jour | paisible ; perché sur une bitte du port, une souche ; s'envole à 5 m, lourdement | `repos`, `marche`, `fuite` |
| **Chouette** (`owl`) | `colline`, `foret_profonde`, `sentier` | nuit | paisible ; sur une branche, la tête qui pivote ; envol silencieux à 4 m | `repos`, `fuite` |
| **Papillons orange** (`anim/butterfly`, `anim/butterfly_orange_b`) | `entrepot` (champ, coin d'herbe au soleil), `colline` | matin, après-midi, par beau temps | en nuée de 3 à 6 au-dessus des herbes ; s'écartent au passage | bandes animées |
| **Écureuil** (`squirrel`) | lisière de `entrepot` (bois du sud, lisière nord), `foret_profonde` | jour | fuyard ; au sol une noisette dans les pattes ; à 4 m, il file vers le tronc le plus proche ; une petite le poursuit parfois à la lisière (V5) | `repos`, `marche`, `course`, `fuite` |
| **Grenouille** (`frog`) | `sentier` (marais), `entrepot` (marais de la clairière), `foret_profonde` (rivière) | jour ; le soir, elles chantent (son) | fuyarde ; plongeon à 2 m | `repos`, `marche`, `fuite` |
| **Libellules** (`anim/dragonfly_blue`, `_amber`) | `sentier`, `entrepot` (marais) | après-midi des jours doux | au-dessus de l'eau basse | bandes animées |
| **Renard** (`fox`) | `foret_profonde`, `sentier` (lisière) | aube, crépuscule | fuyard ; il traverse un chemin, s'arrête, regarde, et bondit dans un fourré à 6 m | `repos`, `marche`, `course`, `fuite` |
| **Cerf** (`deer`) | `foret_profonde` (`clairiere_cerfs`, `cerfs`), `montagne` | aube et soir | paisible ; trois ou quatre broutent (`broute`, nom proposé) ; à 8 m ils lèvent la tête, à 6 m ils s'enfuient au galop | `repos`, `marche`, `course`, `broute` |
| **Sanglier** (`boar`) | `foret_profonde` (`souille`) | matin et soir | dangereux si on l'approche à moins de 6 m de sa souille, ou si on le frappe : il charge (`ACTE1.md`, 3.5) ; sinon il fouille le sol | `repos`, `marche`, `course`, `attaque`, `degats`, `mort`, `broute` |
| **Loups** (`wolf`) | `foret_profonde` (`clairiere_loups`, `loups`) | crépuscule et nuit | dangereux ; meute de trois ou quatre ; le jour, ils restent cachés et fuient ; au crépuscule, ils sortent et attaquent à 10 m | `repos`, `marche`, `course`, `attaque`, `degats`, `mort` |
| **Ours** (`bear`) | `montagne` (`taniere`) | jour | dangereux ; il erre lentement à moins de 15 m de sa tanière ; il charge qui entre dans ce cercle et ne poursuit pas au-delà | `repos`, `marche`, `course`, `attaque`, `degats`, `mort` |

### 6.3 Par carte et par moment

| Carte | Aube | Matin, midi | Après-midi | Soir | Nuit |
| --- | --- | --- | --- | --- | --- |
| `entrepot` | merles | merles, papillons | papillons, écureuil à la lisière | — | — (le silence ; un hibou au loin, son) |
| `sentier` | merles, brume | corbeau, grenouilles | grenouilles, libellules (jours doux) | renard à la lisière | chouette ; aucune lumière |
| `village` | merles | — | papillons dans les jardins | — | — |
| `colline` | merles | papillons | papillons | — | chouette, grillons (son) |
| `port` | — | corbeaux sur les bittes | corbeaux | — | — |
| `foret_profonde` | cerfs, renard | écureuils, sanglier à la souille | écureuils, corbeaux | cerfs, sanglier ; les loups sortent au crépuscule | loups, chouette |
| `montagne` | cerfs au belvédère | ours près de la tanière, corbeaux | ours, corbeaux | cerfs | — (l'ours dort ; la montagne est noire) |

### 6.4 La nature qui réagit

- **Les mares cachées** de la forêt profonde (`foret_profonde:mare_cachee` ; V5, épilogue) : leur
  bord est glissant ; qui s'approche à moins de 0,5 m de l'eau glisse et tombe dedans **(original)** :
  Chtholly ressort trempée (`degats`), rien de plus ; c'est la seule eau profonde de l'acte 1
  (`CARTE.md`, 11).
- **L'eau basse** (marais, rivière, gué) : on y marche ; éclaboussures à chaque pas ; les grenouilles
  plongent.
- **Les fourrés** dont les branches transpercent (V1) : on ne peut pas y entrer, sauf le fourré du
  ballon (`entrepot:fourre_ballon`), qui rend le ballon.
- **Le vent** : les jours de vent (1, 5), feuilles qui volent, linge qui claque, et le ballon qui
  dévie (V1).

## 7. Ce que les lots du moteur doivent savoir, et ce que ce document invente

- **E4 (vie)** : les tableaux de la section 2 sont des données (personnage × moment → point,
  activité, animation), les variations de la section 3 les surchargent par jour ; les déplacements
  passent par les sorties de `CARTE.md` ; les points nommés ajoutés pour ce document :
  `entrepot_etage:ithea_lit` et `nephren_lit` (`CARTE.md`, 3.2).
- **E8 (jeux)** : le ballon (5.1) ; l'embuscade (5.5) avec `ACTE1.md`, 3.1 ; les autres jeux sont des
  comportements de groupe (E4).
- **E5 (faune)** : section 6 ; les distances de fuite et d'attaque, les moments ; jamais de sang.
- **Planches à livrer en priorité pour la vie** : `kana`, `giniette`, `fairy_07` à `fairy_12`, les
  pyjamas d'Almita et des aînées, `cafe_owner`, `drinker_dog`, `drinker_cat`, `porter` (prio 2) ;
  les gestes `travaille` des habitants livrés ; la faune (prio 2 et 3).
- **Inventions de ce document** : les cloches toutes les heures et demie ; la répartition des
  dortoirs et des équipes ; Willem au marché certains matins de l'acte 1 ; les cases de chaque
  personnage là où l'œuvre ne dit pas l'heure ; Tiat qui imite Chtholly ; Nygglatho à la chasse le
  jour 9 (d'après VEX) ; les villageois de métier et leurs heures ; le commis du port ; les
  villageois devant la maison Limashenka ; les chiffres des jeux (mi-temps, rayons, durées) ; la
  serviette du bain ; les mares qui font glisser ; les distances de fuite des animaux ; l'écureuil
  à la lisière de l'entrepôt.
