# Cahier des charges n° 3 : l'île n° 68 de *SukaSuka*

Ce document se donne à ChatGPT (ou à Codex), **lot par lot**. Il commande les images de la refonte
(`docs/REFONTE.md`, section 8) : l'intérieur de l'entrepôt, les personnages qui vivent leur
journée, le village et la ville, le port et ses navires en volume, la forêt, sa faune et le temps
qu'il fait. Ses noms, ses tailles et ses animations suivent les **conventions d'images de la
refonte** (`docs/REFONTE.md`, section 8.1), qui font foi.

Il **complète** les cahiers n° 1 (`docs/ASSETS_HD2D.md`) et n° 2 (`docs/ASSETS_HD2D_MONDE.md`) :
même échelle, même rendu, mêmes règles de livraison. Les images qu'ils ont commandées **restent**
(arbres, rochers, façades, flancs, décalques, bandes animées, ciel) ; la pose les reprend dans les
nouveaux lieux. Ce cahier ne commande que ce qui manque.

Ce qu'il dit des lieux et des gens vient de l'œuvre, d'après les dossiers du canon
(`docs/lore/canon/v1_vex.md`, `v2_v3.md`, `v4_v5.md`) : la source est donnée entre parenthèses,
`(V1, « L'Homme sans Marque »)`, quand elle aide le dessinateur. Ce que l'œuvre ne dit pas et
qu'on ajoute est marqué **(original)**. Tout est paraphrasé : le dépôt est public, on ne recopie
jamais le texte des volumes.

## 0. Mode d'emploi

**Découper.** Une conversation par lot (ou par famille d'images) : colle d'abord le **bloc de
style** (section 1), puis la section du lot, de son « Rappel du format » jusqu'à la fin de son
tableau. Chaque section de lot (3 à 8) se suffit à elle-même avec le bloc de style. Pour les
personnages (lot J), une conversation par planche est plus sûre.

**Joindre.** Chaque lot dit quelles images existantes joindre comme référence de rendu (un
personnage déjà livré, la façade de l'entrepôt, un meuble du cahier n° 2). Une capture du jeu
(`docs/img/`) aide aussi à montrer le cadrage.

**Les lots et leur taille**, dans l'ordre de commande :

| Lot | Section | Contenu | Images |
| --- | --- | --- | --- |
| **I** | 3 | Intérieur de l'entrepôt : matières, portes, fenêtres, mobilier de chaque pièce | 160 images |
| **J** | 4 | Personnages : animations nouvelles, tenues (maison, pyjama, pluie), fées sans planche, hommes-bêtes, visiteurs | 80 planches (trois vues chacune) et 2 portraits |
| **K** | 5 | Village des hommes-bêtes, café à clochette, maison Limashenka, ville de pierre en pente, boutiques et leurs intérieurs, marché | 122 images |
| **L** | 6 | Port, rue du port, navires en volume (transport de la Garde, Barocupot), salle du conseil de guerre | 40 images |
| **M** | 7 | Sentier sans lumière, marais de nuit, mares cachées, fourrés, bosquets, montagne, rivière, paliers ; faune | 52 images et 10 planches d'animaux |
| **N** | 8 | Ciels, mer de nuages de nuit, pluie, flaques animées, fenêtres éclairées, lumières | 30 images |

En tout, **404 images**, **90 planches** (80 personnages et 10 animaux) et **2 portraits**. Le lot J
dépasse l'ordre de grandeur de `docs/REFONTE.md` (40 à 60 planches) parce qu'il vise
l'exhaustivité : la colonne « Prio » de chaque tableau dit quoi commander d'abord (section 9.1).

**Priorités.** **1** : la première tranche, « l'entrepôt » (dehors, dedans, vie des petites,
jours 1 à 4 de l'acte 1) ; **2** : le reste de l'acte 1 (sentier, port, village, colline) ;
**3** : le monde autour (ville, forêt profonde, montagne) et ce qui peut attendre.

**« Format à confirmer par le moteur ».** Quelques genres d'images n'existent pas encore dans le jeu
(navires en volume, faces des paliers, planches complémentaires…). Ce cahier leur donne des
tailles raisonnables ; le lot du moteur qui les intègre peut encore les changer. Ils sont
signalés à la ligne concernée et récapitulés en section 9.4, qui dit lesquels attendre.

## 1. Bloc de style v3 (à coller au début de chaque conversation)

```text
Tu produis des images pour WordEnd, un jeu d'action-aventure en « HD-2D » à la manière
d'Octopath Traveler : des personnages et des décors en pixel art posés dans de petits lieux en
relief, vus par une caméra fixe inclinée qui regarde le nord. Univers : l'île flottante n° 68 du
roman SukaSuka (traduction Yume Novel), une dalle de pierre au-dessus d'une mer de nuages,
presque entièrement couverte d'une forêt dense semée de marais. Au cœur de la forêt, dans une
clairière défrichée, un vieil entrepôt de bois délabré où vivent une trentaine de fées (des
fillettes de 7 à 15 ans aux cheveux de couleurs vives), la jeune troll qui les élève et le
jeune homme qui veille sur elles ; à quelques pas, un village campagnard d'hommes-bêtes
(hommes-chiens, hommes-chats, lézards, ours, oiseaux, grenouilles) ; plus loin, une petite ville
de maisons de pierre sur une pente douce, et un port au bord du vide où se posent des navires
volants à coque de métal, à rotors et à chaudière enchantée, sans aucun ballon. Saison : la fin
de l'automne, qui tourne à l'hiver.
Style obligatoire :
- pixel art net : 1 pixel de l'image = 1 pixel d'art, aucun flou, aucun anticrénelage vers le
  fond, aucun dégradé lisse de peinture numérique ; aplats et dégradés en paliers, tramage léger
  permis ; contours de 1 px d'une teinte sombre de la couleur voisine (jamais noir pur) ;
- échelle fixe : 96 pixels par mètre partout (une porte de 2,2 m mesure 211 px, une petite fée
  de 1,2 m mesure 115 px, un adulte de 1,75 m mesure 168 px) ; chaque objet a sa taille réelle ;
- modelé marqué, comme dans Octopath Traveler : volumes lisibles, lumière douce de jour venant de
  la gauche et d'un peu au-dessus, reflets chauds sur les arêtes éclairées, ombres propres
  froides (brun violacé), assombrissement au contact ; aucune ombre portée au sol (le jeu ajoute
  les ombres, l'heure, la nuit, la pluie et la lueur des lampes) ;
- matières crédibles et usées : bois patiné, fendu, rapiécé ; pierre ébréchée et moussue ; fer
  riveté rouillé aux joints ; tissu reprisé ; rien de neuf, rien de symétrique au pixel près ;
- palette naturelle, un peu désaturée et chaude : or, rouille, mousse, pierre claire, bois brun,
  laiton ; lumière des cristaux jaune pâle (#FFE6A6) ; ni blanc pur ni noir pur ;
- univers européen rustique : village de bois, de torchis et de chaume, ville de pierre,
  ardoise, tuiles, cuivre, fer riveté, mobilier de ferme et de vieille pension ; rien d'asiatique
  dans l'architecture ni le mobilier (ni torii, ni lanterne de papier, ni cerisier en fleurs, ni
  toit recourbé, ni cloison ou porte de papier, ni tatami, ni bambou) ; rien de moderne (ni
  plastique, ni ampoule, ni prise, ni robinet chromé, ni affichage) ; la lumière vient de
  cristaux, du feu et des fenêtres ;
- aucun texte, chiffre, logo ni signature : un écriteau, un menu, un livre, une carte ou un
  cadran porte des lignes grises, des traits ou de petits dessins, jamais de lettres ni de
  chiffres lisibles ;
- fond transparent (PNG RGBA, alpha 0 ou 255 seulement) pour tout ce qui n'est pas une tuile ;
  alpha continu seulement pour les images marquées « alpha doux » (vapeur, brume, pluie,
  lumière, nuages) ;
- respecte exactement le chemin du fichier, sa taille en pixels et son cadrage, et ne livre que
  les fichiers demandés.
Personnages et animaux (planches de sprites) :
- proportions des sprites d'Octopath Traveler : deux têtes et demie à trois têtes de haut, jamais
  une grosse tête sur un corps minuscule ; le profil est tourné vers la droite ;
- la même échelle dans toute la planche : chaque image debout mesure la « hauteur debout »
  demandée, du sol sous les pieds au sommet de la tête (cheveux compris) ; le personnage ne
  grandit ni ne rapetisse quand il marche, court ou parle ;
- trois vues (profil, face, dos) à la même hauteur debout, avec exactement les mêmes animations
  et les mêmes nombres d'images ;
- une seule silhouette par case : jamais deux figures empilées, jamais de double fantôme ;
- un accessoire porté d'un seul côté (couette, tresse, arme, queue, sac) reste du même côté du
  corps dans toutes les images et les trois vues (de dos, il passe donc de l'autre côté de
  l'image) ;
- rien sous la ligne des pieds (ni pointe d'épée, ni queue, ni ombre).
Pour chaque image, je te donnerai : son chemin, sa taille exacte, son genre, son ancrage et son
sujet.
```

**Couleurs de référence** (cahiers n° 1 et 2) : herbe `#87A35E`, herbe sèche `#AFA764` ;
feuillages or `#CC9446`, rouille `#A95A3A`, sapins `#3D5946` ; pierre claire `#C2B49F`, ombre
`#837667` ; bois clair `#A57C58`, foncé `#654D3C` ; plâtre crème `#EAE0CB` ; ardoise `#5E6C86`,
tuiles `#B65E4B` ; fer `#717B84`, laiton `#B4955E` ; eau du marais `#4A675F`, roseaux `#9C9563` ;
cristaux lumineux `#FFE6A6` ; rouge de la Garde ailée `#AE4A3E` ; nuages `#F4DCC6`, `#BBA3BF`,
`#82769C`. Nouvelles pour ce cahier : bleu nuit `#2E3552` (ciel et vitres de nuit), gris de pluie
`#7D7F86`, lin beige `#D9CBB0` (rideaux, draps), vert sauge `#8E9E82` (papier peint fané).

## 2. Règles communes et conventions de la refonte

### 2.1 Les règles

Elles valent pour toutes les images de ce cahier (cahiers n° 1 et 2 ; `docs/REFONTE.md`,
section 8.1).

| Règle | Valeur |
| --- | --- |
| Densité | **96 px par mètre** ; lointain (montagnes, nuages) : 48 px/m, précisé à la ligne |
| Format | PNG RGBA 8 bits ; tuiles et matières : opaques |
| Taille | exacte au pixel près ; si l'outil ne sait pas la produire, livre plus grand et plus net, puis `python3 tools/hd2d_assets.py fit <fichier>` (réduction au plus proche voisin) |
| Transparence | découpée (alpha 0 ou 255), sauf « alpha doux » annoncé |
| Ancre | **milieu du bord bas = point posé au sol** : l'objet touche le bord bas de l'image, centré ; exceptions dites à la ligne (ce qui vole : centré ; ce qui pend : ancre libre, accroché par le haut ; décalques : centre) |
| Angle de vue | tuiles, matières de sol et décalques : strictement de dessus ; murs, portes, fenêtres, façades et flancs : de face, sans perspective ; meubles, objets, personnages et animaux : de face, très légèrement plongeant (10 à 15° : on devine le dessus des objets) |
| Orientation | personnages, animaux et navires tournés **vers la droite** (le jeu les retourne) ; tout le reste vu de face |
| Lumière | jour doux venant de la gauche ; le jeu fait le matin, le couchant, la nuit, la pluie et la lueur des lampes, sauf pour les ciels et les lumières du lot N, qui disent leur heure |
| Qualité avant poids | ni compression avec perte, ni réduction de couleurs ; une image de plus de 1,5 Mo (3 Mo pour les grands navires, les lisières et les ciels) n'est souvent pas du pixel art net : vérifie-la |
| Livraison | seulement les fichiers listés, à leur chemin exact (section 9.3) |

### 2.2 Les genres d'images, avec des exemples

| Genre | Où | Cadrage | Exemple |
| --- | --- | --- | --- |
| **Sol** (`tile`) | `assets/hd2d/interior/floor_<matière>.png`, `assets/hd2d/ground/<nom>.png` | 384 × 384 (4 × 4 m), vue de dessus, opaque, **sans raccord sur les quatre bords**, sans objet ni ombre | `floor_planks_worn.png` : 4 × 4 m de parquet usé ; colle-la à côté d'elle-même dans les deux sens : aucune couture ne doit se voir |
| **Mur** (`tile_h`) | `assets/hd2d/interior/wall_<matière>.png` | 384 × 288 (4 m de long × 3 m de haut), de face sans perspective, opaque, **sans raccord à gauche et à droite**, plinthe en bas et corniche en haut comprises, ni porte ni objet | `wall_wainscot.png` : lambris bas et plâtre, répété le long du mur nord d'une pièce |
| **Haut de mur coupé** (`tile_h`) | `assets/hd2d/interior/wallcut_<matière>.png` | 384 × 24 (4 × 0,25 m), le dessus d'un mur vu d'en haut, raccord à gauche et à droite | le jeu ne dessine pas le mur sud d'une pièce (la caméra regarde à travers) : il pose seulement son épaisseur au ras du sol, comme une coupe |
| **Porte, fenêtre, élément de mur** (`panel`) | `assets/hd2d/interior/door_<nom>.png`, `window_<nom>.png`, `wallitem_<nom>.png` | à l'échelle, de face, collé contre le mur, ancre au milieu du bord bas ; une porte touche le sol, une fenêtre et un élément de mur sont posés à la hauteur donnée à la ligne | porte de 1,1 × 2,2 m = **106 × 211 px** ; écriteau de 0,35 × 0,45 m = 34 × 43 px, posé à 1,4 m |
| **Meuble, objet** (`panel`) | `assets/hd2d/interior/props/<nom>.png` | à l'échelle, de face légèrement plongeante ; la hauteur de l'image comprend le dessus de l'objet vu en léger surplomb | table de 0,75 m de haut et 0,9 m de profondeur : environ 1 m de haut dans l'image ; un objet « posé sur un meuble » a son ancre sur le plateau |
| **Panneau extérieur** (`panel`) | `assets/hd2d/props/<nom>.png` | comme au cahier n° 1, section 7 | `thicket_a.png`, fourré de 2,5 × 1,6 m = 240 × 154 |
| **Façade et flanc** (`facade`, `side`) | `assets/hd2d/buildings/<nom>.png`, `<nom>_side.png` | élévations du cahier n° 1 (6.1) et du cahier n° 2 (3.5) : mur collé aux bords gauche, droit et bas | type `long` : façade = largeur × hauteur du mur, flanc en pignon = profondeur × faîte ; type `pignon` : façade = largeur × faîte, flanc gouttereau = profondeur × hauteur du mur |
| **Matière de volume** (`tile`) | `assets/hd2d/buildings/materials/<nom>.png` | 192 × 192 (2 × 2 m), opaque, sans raccord | `roof_thatch.png`, chaume vu dans le sens de la pente |
| **Décalque** (`decal`) | `assets/hd2d/decals/<nom>.png` | vu de dessus, fond transparent, bord irrégulier ; un tapis a un **bord plein** voulu (rectangle aux coins usés) | `rug_playroom.png`, tapis de 4 × 3 m = 384 × 288 |
| **Bande animée** (`anim`) | `assets/hd2d/anim/<nom>.png` | les images côte à côte sur une ligne, sans marge, toutes de la taille donnée (la bande fait `n ×` la largeur), boucle sans saut, seul ce qui bouge change | `hearth_fire.png` : 6 images de 77 × 48 = 462 × 48 px |
| **Lointain** (`panel`, `panorama`) | `assets/hd2d/sky/<nom>.png` | 48 px/m, teintes adoucies par la distance ; ciels : panorama de 2048 × 1024 au cadrage de `sky.png` | `mountain_backdrop_a.png` |
| **Planche de sprites** | `assets/characters/<dossier>/<id>.png` + `.json`, `_front`, `_back` ; animaux : `assets/fauna/<id>/` | format de la section 4.1 | `assets/characters/tiat/tiat_life.png` |

**Calcul des tailles** : mètres × 96, arrondis au pixel (0,45 m = 43 px ; 1,25 m = 120 px ;
2,4 m = 230 px). Les tableaux donnent toujours les pixels ; les mètres entre parenthèses servent au
dessinateur pour l'échelle des détails (une marche fait 17 cm, une poignée de porte est à 1 m du
sol, une chaise a son assise à 45 cm, une table son plateau à 75 cm, un lit son matelas à 50 cm).

### 2.3 Les animations nouvelles des personnages (`docs/REFONTE.md`, 8.1)

Le format des planches ne change pas (cahier n° 1, section 3) : trois vues, mêmes animations,
même hauteur debout. Les animations de la refonte portent ces noms (fiche complète, image par
image, en section 4.2) :

| Animation | Images | ips | Boucle | Qui | Contenu |
| --- | --- | --- | --- | --- | --- |
| `course` | 5 | 14 | oui | petites, aînées, habitants | course |
| `saut` | 4 | 12 | non | petites | élan, saut, réception |
| `frappe` | 4 | 14 | non | petites, aînées | frappe du pied dans le ballon ; `coup` : [2] |
| `lance` | 4 | 12 | non | petites | lancer à deux mains par-dessus la tête ; `coup` : [2] |
| `grimpe` | 4 | 8 | oui | petites | grimper à un tronc (vue de dos surtout) |
| `assis` | 2 | 2 | oui | tous | assis sur un banc ou une chaise, respiration |
| `lit` | 2 | 2 | oui | tous | assis, un livre ouvert, page qui tourne |
| `dort` | 2 | 1 | oui | tous | couché sur le côté, respiration |
| `tombe` | 4 | 10 | non | petites | chute en avant à plat ventre (avalanche, embuscade ratée) |
| `porte` | 6 | 10 | oui | Willem, Nygglatho, habitants | marche en portant un panier, un plateau ou une caisse (objet dessiné) |
| `travaille` | 4 | 6 | oui | Willem, Nygglatho, habitants | geste de métier : remuer une marmite, marteler, balayer, servir (une planche par geste et par personnage) |
| `effondre` | 4 | 8 | non | Willem | chancelle et tombe assis, puis à terre |
| `hanches` | 2 | 2 | oui | Nygglatho, Chtholly | poings sur les hanches, réprimande |

Restent celles des cahiers précédents : `repos` (2, 2 ips), `marche` (6, 10), `parle` (2 à 4, 6),
`attaque` (4, 14, `coup` [1, 2, 3]), `charge`, `degats`, `mort`. Ce cahier propose en plus,
**à confirmer par le moteur** : `etreinte` (Nygglatho), `pare` (entraînement au bâton) et
`broute` (animaux paisibles) ; il donne aussi `travaille` aux fées en pyjama pour la toilette du
matin (même nom, autre geste).

### 2.4 Ce que les livraisons précédentes ont mal compris

Défauts relevés dans les livraisons des cahiers n° 1 et 2 (cahier n° 1, section 12 ;
`docs/DECISIONS.md`). Chaque consigne de ce cahier les prévient ; les relire avant de commander.

| Ce qui est arrivé | Ce qu'on demande |
| --- | --- |
| `parle` et `marche` dessinées 6 à 36 % plus grandes ou plus petites que `repos` (13 vues) : le personnage rapetissait en parlant | chaque image debout à la hauteur debout donnée en px ; les planches complémentaires recopient la rangée `repos` en tête, comme étalon (section 4.1) |
| Chtholly de face à 130 px au lieu de 144 ; Pannibal de profil à 111 px au lieu de 120 | les trois vues à la même hauteur debout, mesurée de l'ancre au sommet de la tête |
| deux figures empilées dans une même case | une seule silhouette par case |
| la couette de Lakhesh et la queue de Limeskin changent de côté d'une image à l'autre et entre la face et le dos | un accessoire reste du même côté du corps ; de dos, il passe de l'autre côté de l'image |
| Valgulious pointe vers l'arrière au `repos` et vers l'avant en `marche` : l'arme saute | même prise de l'objet d'une animation à l'autre |
| la pointe de l'épée de bois de Pannibal 10 px sous ses pieds : le jeu la mesurait plus grande | rien sous la ligne des pieds |
| ancres qui glissaient jusqu'à 50 px d'une image à l'autre | les pieds au même endroit dans les images immobiles ; les ancres se recalculent par `python3 tools/hd2d_sheets.py anchors <json> --write` |
| `fouet` du Timere dessiné de trois quarts dos | toutes les animations du profil de profil, tournées vers la droite |
| portail dessiné entrouvert (1 m de passage au lieu de 2,5 m) ; pierre de 0,3 m dessinée plus haute | les cotes d'usage (passage, hauteur d'appui, hauteur d'assise) sont des contraintes, pas des suggestions |
| îles « fantômes » et nuages ajoutés autour d'une île lointaine | seulement le sujet demandé, rien autour |
| icônes livrées sous les noms d'une ancienne liste (`berries` au lieu de `wild_berries`) | le nom exact de ce document |
| 380 Mo de sources, galeries, aperçus, outils, changements de code et 35 personnages non demandés dans une livraison | seulement les PNG et les JSON listés (section 9.3) |
| avancée du toit dessinée plus bas que le haut du mur aux angles de quatre flancs en pignon | le toit ne descend pas sous le haut du mur |
| enseigne d'horloger qui pouvait se lire comme une heure | cadrans sans chiffres ni aiguilles lisibles ; écriteaux sans lettres |

## 3. Lot I : l'intérieur de l'entrepôt

### 3.0 Rappel du format (à coller avec le lot)

Le jeu entre dans l'entrepôt des fées, pièce par pièce. Une pièce est faite de **son sol** (tuile
répétée), de **ses murs** (bandes raccordables posées sur les murs nord, est et ouest), du **haut de
mur coupé** au sud (la caméra regarde à travers le mur sud, qui n'est pas dessiné) et de
**panneaux** debout : portes, fenêtres, éléments de mur, meubles et objets. La lumière chaude des
cristaux, de la cheminée et des fenêtres est ajoutée par le jeu.

Chaque ligne donne le chemin complet du fichier (`assets/hd2d/…`). Genres :
- **tuile de sol** : 384 × 384 (4 × 4 m), vue strictement de dessus, opaque, sans raccord sur les
  quatre bords, sans objet ni ombre ;
- **mur** : 384 × 288 (4 m de long, 3 m de haut), vu de face sans perspective, opaque, sans raccord
  à gauche et à droite ; plinthe en bas et corniche ou moulure en haut, comprises dans l'image ;
  ni porte, ni fenêtre, ni objet ;
- **haut de mur** : 384 × 24 (4 × 0,25 m), le dessus d'un mur de 25 cm d'épaisseur vu d'en haut,
  comme une coupe, sans raccord à gauche et à droite ;
- **porte** : de face, fond transparent, collée au bord bas (le seuil), chambranle compris ;
- **fenêtre** et **élément de mur** : de face, fond transparent, ancre au milieu du bord bas ; le
  jeu les pose à la hauteur donnée (« appui à 0,9 m », « bas à 1,4 m ») ; les vitres sont d'un
  gris bleuté clair avec un reflet en diagonale, et laissent deviner une masse de feuillage d'or
  (les versions de nuit sont au lot N) ;
- **meuble** : de face, très légèrement plongeant (on devine le plateau, l'assise, le dessus),
  fond transparent, collé au bord bas et centré ; ancre = point posé au sol ;
- **objet posé** : comme un meuble, mais son ancre est sur le plateau du meuble qui le porte ;
- **suspendu** : accroché par le haut (le haut de l'image est le plafond ou le crochet), ancre
  libre ;
- **lit vu de flanc** : le long côté vers la caméra, la tête à gauche, le matelas visible en léger
  surplomb ;
- **décalque** : vu strictement de dessus, fond transparent, bord irrégulier, ou bord plein pour
  un tapis (rectangle aux coins usés, franges) ;
- **bande animée** : `n` images côte à côte, chacune de la taille donnée, sans marge, boucle sans
  saut, seul ce qui bouge change.

**Références à joindre** : `assets/hd2d/buildings/warehouse_main.png` (l'entrepôt vu dehors : bois
sombre rapiécé, soubassement de pierre, fenêtres à croisillons), `assets/hd2d/props/bench_b.png`,
`assets/hd2d/props/laundry_basket.png` et `assets/hd2d/ground/planks.png` (rendu du bois).

**L'esprit des lieux.** Un bâtiment de bois à deux niveaux, ancien, prévu pour une cinquantaine de
personnes (V2, « De ce côté-ci de l'écran »), si délabré qu'un visiteur le compare à une étable en
ruine (V5, « La fin imminente ») ; rien de militaire, sauf la porte de la salle des armes (V1,
« Entrepôt de fées »). Un logement de pension plein d'enfants : parquet usé, murs plâtrés, petites
pièces régulières, papiers punaisés partout (V1, « L'Homme sans Marque »), meubles dépareillés,
réparés, rayés, jouets qui traînent. Ni luxe, ni saleté : une maison tenue par Nygglatho, usée par
trente fillettes.

**Consigne** : colle le bloc de style, ce rappel, puis « Image d'intérieur `<chemin>`, <taille> px,
<genre> : » et la description de la ligne.

### 3.1 Matières des pièces

Les noms sont fixés par `docs/REFONTE.md` (section 8.1). Une matière ne dessine que sa surface :
pas de meuble, pas d'ombre, pas de lumière de fenêtre.

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/floor_planks_worn.png` | 384 × 384 | tuile de sol | parquet du couloir et des pièces communes : lames de pin brun miel (#A57C58) larges de 15 à 20 cm, posées dans le sens vertical de l'image, chemins d'usure plus clairs au milieu, nœuds sombres, têtes de clous, une lame plus foncée remplacée, joints poussiéreux, rayures de chaises ; mat, jamais vernis brillant ni chevrons (V1, « L'Homme sans Marque ») |
| 1 | `assets/hd2d/interior/floor_planks_dark.png` | 384 × 384 | tuile de sol | plancher des chambres de l'étage : lames plus étroites (12 cm) et plus sombres (#654D3C), mates, quelques lames qui jouent et laissent une fente noire, une planche fendue, traces de pas plus claires ; un plancher qui semble pouvoir céder (V5, épilogue) |
| 1 | `assets/hd2d/interior/floor_tiles_bath.png` | 384 × 384 | tuile de sol | carrelage de la salle de bains : carreaux de grès de 10 cm en damier crème et vert d'eau passé, joints gris, quelques carreaux fêlés ou ébréchés, traces de calcaire blanchâtre ; aucun motif moderne |
| 2 | `assets/hd2d/interior/floor_flagstone_cellar.png` | 384 × 384 | tuile de sol | dalles de la crypte des armes : grandes dalles de pierre gris sombre irrégulières de 50 à 80 cm, usées en creux, joints de terre et de mousse noire, taches d'humidité, poussière (V1, « Entrepôt de fées ») |
| 1 | `assets/hd2d/interior/floor_kitchen_tiles.png` | 384 × 384 | tuile de sol | tomettes de cuisine : petits carreaux hexagonaux de terre cuite rouge-brun (#B65E4B) de 15 cm, usés et ternes, quelques-uns cassés ou remplacés par un carreau plus clair, farine et poussière dans les joints |
| 1 | `assets/hd2d/interior/wall_plaster_worn.png` | 384 × 288 | mur | mur de plâtre crème (#EAE0CB) sali, fissures fines, un éclat qui montre le lattis de bois, traces de petites mains vers 1 m de haut, plinthe de bois brun de 15 cm en bas, moulure simple en haut ; couloir, archives, infirmerie (V1, « L'Homme sans Marque » : murs plâtrés) |
| 1 | `assets/hd2d/interior/wall_wainscot.png` | 384 × 288 | mur | lambris bas de planches verticales brun moyen jusqu'à 1,1 m, cimaise de bois, plâtre crème au-dessus, plinthe ; le lambris éraflé par les dossiers de chaises et les coups de pied ; réfectoire, salle de lecture, salle de jeux |
| 1 | `assets/hd2d/interior/wall_wallpaper_faded.png` | 384 × 288 | mur | papier peint fané des chambres : petites fleurs et rayures vert sauge (#8E9E82) et crème passées par le soleil, une auréole d'humidité, un lé un peu décollé en haut, plinthe de bois sombre, moulure étroite |
| 1 | `assets/hd2d/interior/wall_kitchen_tiles.png` | 384 × 288 | mur | mur de cuisine : carreaux de faïence blanc cassé de 15 cm jusqu'à 1,5 m de haut, frise de carreaux bleu passé, quelques carreaux fêlés, plâtre crème au-dessus taché de vapeur ; pas de suie (le fourneau est à cristal) |
| 2 | `assets/hd2d/interior/wall_cellar_stone.png` | 384 × 288 | mur | mur de la crypte : moellons gris sombre jointoyés d'un mortier humide, traînées de salpêtre blanc, mousse noire au pied, aucune plinthe ; froid, la seule pièce sans bois (V1, « Entrepôt de fées ») |
| 1 | `assets/hd2d/interior/wallcut_wood.png` | 384 × 24 | haut de mur | coupe d'une cloison de bois vue de dessus : deux planches de parement brun clair et, entre elles, l'âme sombre de la cloison ; raccord à gauche et à droite |
| 2 | `assets/hd2d/interior/wallcut_stone.png` | 384 × 24 | haut de mur | coupe d'un mur de pierre vu de dessus : moellons gris et mortier, bord intérieur un peu plus clair ; raccord à gauche et à droite |
| 2 | `assets/hd2d/interior/floor_roof_deck.png` | 384 × 384 | tuile de sol, **nom proposé, à confirmer par le moteur** | sol du toit-terrasse : planches grises délavées par la pluie, joints calfatés de goudron noir, taches de mousse et de lichen, une planche neuve plus claire, clous rouillés (V2, « De ce côté-ci de l'écran » : le toit à linge) |

### 3.2 Portes et fenêtres

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/door_room.png` | 106 × 211 (1,1 × 2,2 m) | porte | porte de chambre en planches assemblées, peinte d'un brun-rouge écaillé, chambranle de bois, poignée de laiton à 1 m, fente sous la porte ; les petites se collent contre elle pour épier (ill. V1 : l'avalanche devant une porte de bois à poignée de laiton) |
| 1 | `assets/hd2d/interior/door_room_open.png` | 106 × 211 | porte | la même porte grande ouverte : chambranle, embrasure sombre (la pénombre de la pièce d'à côté), battant rabattu vu de chant contre le montant gauche ; pour l'avalanche qui s'écroule à l'ouverture (V1, « L'Homme sans Marque ») |
| 1 | `assets/hd2d/interior/door_double.png` | 192 × 230 (2 × 2,4 m) | porte | double porte d'entrée vue de l'intérieur : grosses planches, pentures de fer noir, verrou à barre, petit carreau à croisillons en haut de chaque battant ; même style que la porte de `warehouse_main.png` (jointe) |
| 2 | `assets/hd2d/interior/door_service.png` | 96 × 211 (1 × 2,2 m) | porte | porte de service vers la clairière d'entraînement, à l'arrière : planches, moitié haute vitrée à croisillons, loquet de fer, paillasson usé au pied (VEX, « Chtholly Nota Seniorious » : on s'entraîne à l'arrière) |
| 2 | `assets/hd2d/interior/door_armory.png` | 125 × 221 (1,3 × 2,3 m) | porte | porte de la salle des armes, côté couloir : grande porte robuste de métal gris sombre, rivetée tout autour, **cinq serrures** alignées, poignée lourde, usure brillante autour des serrures ; la seule chose militaire de la maison (V1, « Entrepôt de fées ») |
| 2 | `assets/hd2d/interior/door_armory_inside.png` | 125 × 221 | porte | la même porte vue de l'intérieur de la crypte : barres de renfort, gros gonds, les cinq pênes, rouille et humidité ; aucune lumière ne passe |
| 1 | `assets/hd2d/interior/window_cross_small.png` | 77 × 96 (0,8 × 1 m) | fenêtre, appui à 1 m | petite fenêtre à croisillons de six carreaux, cadre de bois brun écaillé, appui de bois ; chambres, couloir, cuisine |
| 1 | `assets/hd2d/interior/window_cross_large.png` | 230 × 173 (2,4 × 1,8 m) | fenêtre, appui à 0,8 m | grande fenêtre du réfectoire : trois vantaux à croisillons, appui large où traînent une tasse et un pot de fleurs (V3, « Des journées chaudes dans une saison froide ») |
| 1 | `assets/hd2d/interior/window_reading_seat.png` | 192 × 211 (2 × 2,2 m) | fenêtre posée au sol | fenêtre à banc de la salle de lecture : embrasure profonde en saillie, banquette de bois garnie de coussins usés, grande fenêtre à croisillons au-dessus ; tout le monde s'y agglutine pour regarder le champ (V1, « Les filles de l'entrepôt ») ; c'est l'intérieur de la fenêtre en saillie de `warehouse_main.png` |
| 2 | `assets/hd2d/interior/window_curtains_open.png` | 115 × 154 (1,2 × 1,6 m) | fenêtre, appui à 0,8 m | fenêtre à croisillons, rideaux de lin beige (#D9CBB0) ouverts et retenus par des embrasses ; infirmerie et chambres de fées (V3, « La Fin d'un rêve, le début d'un rêve » : on ouvre les rideaux de l'infirmerie chaque matin) |
| 2 | `assets/hd2d/interior/window_curtains_closed.png` | 115 × 154 | fenêtre, appui à 0,8 m | la même, rideaux tirés, un peu de lumière filtrée au milieu (V2, « L'écoulement du temps depuis lors » : Chtholly seule dans le noir) |
| 2 | `assets/hd2d/interior/window_bare.png` | 106 × 134 (1,1 × 1,4 m) | fenêtre, appui à 0,7 m | fenêtre nue de la chambre de Willem, **sans rideaux**, rebord de bois large de 30 cm où un adulte peut s'asseoir (V1, « L'Homme sans Marque » ; « Directeur en carton ») |
| 3 | `assets/hd2d/interior/window_dusty.png` | 96 × 96 (1 × 1 m) | fenêtre, appui à 1,3 m | petite fenêtre haute des archives, vitres grises de poussière, toile d'araignée dans un coin, loquet rouillé |

### 3.3 Couloirs, entrée et escalier

Le couloir du bas et celui de l'étage : parquet usé, murs plâtrés, portes de petites pièces à
intervalles réguliers, papiers aux murs, plannings de corvées, écriteaux (V1, « L'Homme sans
Marque ») ; un point d'eau froide pour la toilette du matin (VEX, « L'homme-chat » ; emplacement
déduit) ; au bout du couloir de l'étage, une fuite sous la pluie et les planches de la dernière
réparation (V2, « Temps écoulé depuis lors » ; V3, « Des journées chaudes… ») ; un manteau à la
patère près de l'entrée (V5, « La fin imminente »). Aucun escalier n'est décrit : celui-ci est
**(original)**.

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/wallitem_chore_chart.png` | 96 × 72 (1 × 0,75 m) | élément de mur, bas à 1,2 m | planning des corvées : grande feuille punaisée sur une planchette, grille de cases tracée à la main, pastilles de couleur et petits dessins (balai, seau, marmite, panier de linge), lignes grises à la place des noms ; coins cornés |
| 1 | `assets/hd2d/interior/wallitem_notice_a.png` | 34 × 43 (0,35 × 0,45 m) | élément de mur, bas à 1,4 m | écriteau jauni punaisé, lignes grises, un petit dessin de seau barré : les toilettes de l'étage hors service (V1) ; aucune lettre |
| 1 | `assets/hd2d/interior/wallitem_notice_b.png` | 34 × 43 | élément de mur, bas à 1,4 m | écriteau : dessin d'une petite silhouette qui court, barrée d'un trait rouge, lignes grises dessous : on ne court pas dans les couloirs (V1) ; aucune lettre |
| 2 | `assets/hd2d/interior/wallitem_notices_mix.png` | 77 × 58 (0,8 × 0,6 m) | élément de mur, bas à 1,2 m | papiers dépareillés punaisés en désordre : dessins d'enfants, une demande de réparation, une feuille arrachée dont il reste un coin ; lignes grises, aucune lettre |
| 1 | `assets/hd2d/interior/wallitem_coat_hooks.png` | 115 × 106 (1,2 × 1,1 m) | élément de mur, bas à 0,9 m | planche à patères de bois près de l'entrée : un grand manteau gris, un chapeau, une écharpe, trois petits manteaux d'enfants, un pardessus d'homme |
| 2 | `assets/hd2d/interior/wallitem_frame_landscape.png` | 58 × 48 (0,6 × 0,5 m) | élément de mur, bas à 1,4 m | petit tableau peint naïvement dans un cadre de bois : une île flottante couverte d'arbres au-dessus d'une mer de nuages (original) |
| 2 | `assets/hd2d/interior/wallitem_crystal_sconce.png` | 29 × 48 (0,3 × 0,5 m) | élément de mur, bas à 1,6 m | applique de laiton terni tenant un cristal lumineux jaune pâle (#FFE6A6) dans une petite cage ; on s'éclaire aux cristaux (V4, « La nuit de la fin… ») |
| 1 | `assets/hd2d/interior/props/washstand_corridor.png` | 173 × 110 (1,8 × 1,15 m) | meuble | point d'eau du couloir : longue auge de pierre sur un bâti de bois, deux cuvettes de fer émaillé ébréchées, un broc, un gobelet plein de brosses à dents, un savon, un seau d'eau froide au pied ; pas de robinet (VEX, « L'homme-chat » : la toilette à l'eau glacée) |
| 2 | `assets/hd2d/interior/props/towel_rack.png` | 96 × 106 (1 × 1,1 m) | meuble | porte-serviettes de bois à trois barres, serviettes rayées d'enfants pendues de travers |
| 2 | `assets/hd2d/interior/props/supply_cupboard.png` | 96 × 192 (1 × 2 m) | meuble | placard à fournitures ouvert : balais, seaux, chiffons, un marteau et une boîte de clous sur l'étagère, quelques planches (V3 : le marteau rangé dans le placard d'en bas) |
| 2 | `assets/hd2d/interior/props/leak_bucket.png` | 48 × 43 (0,5 × 0,45 m) | meuble | seau de bois cerclé posé sous la fuite, un fond d'eau, une petite flaque autour (V2 : le bout du couloir de l'étage fuit sous la pluie) |
| 2 | `assets/hd2d/anim/leak_drip.png` | 24 × 96 (0,25 × 1 m), 4 images, 8 ips | bande animée, suspendue | une goutte d'eau qui se forme au plafond (haut de l'image) et tombe jusqu'au bas de l'image (le bord du seau) ; image 4 : une petite gerbe ; fond transparent |
| 2 | `assets/hd2d/interior/props/repair_planks.png` | 67 × 173 (0,7 × 1,8 m) | meuble | planches et lattes appuyées contre le mur, une boîte de clous et un marteau au pied : la dernière réparation de la fuite (V2 ; V3) |
| 1 | `assets/hd2d/interior/props/stairs_up.png` | 154 × 288 (1,6 × 3 m) | meuble (sortie vers l'étage) | escalier de bois droit vu de face qui monte vers le fond (le nord) : marches usées au milieu, contremarches éraflées par les petites bottines, rampe de bois à gauche, le haut qui se perd dans la pénombre d'un palier (original) |
| 2 | `assets/hd2d/interior/props/stairs_down.png` | 154 × 106 (1,6 × 1,1 m) | meuble (sortie vers le bas) | trémie de l'escalier vue de l'étage : rambarde de bois en équerre à barreaux tournés, les premières marches qui descendent dans la pénombre (original) |
| 1 | `assets/hd2d/interior/props/shoe_rack.png` | 115 × 58 (1,2 × 0,6 m) | meuble | étagère basse à chaussures près de l'entrée : une rangée de petites bottines boueuses de toutes les couleurs, une paire de pantoufles d'adulte (V3 : Nygglatho chausse ses pantoufles en entrant) |
| 2 | `assets/hd2d/interior/props/cleaning_set.png` | 67 × 134 (0,7 × 1,4 m) | meuble | les outils de la corvée : balai de paille, serpillière sur un manche, seau de bois et pelle appuyés ensemble contre le mur (V1 : les plannings de corvées) |
| 2 | `assets/hd2d/decals/runner_rug.png` | 96 × 384 (1 × 4 m) | décalque à bord plein, **sans raccord en haut et en bas** | tapis de couloir tissé brun et rouge passé, liseré ocre, usé au milieu en un chemin plus clair, une tache ; il se répète en longueur sans couture |

### 3.4 Le réfectoire

Tout le monde y mange ensemble ; une grande fenêtre ; des chaises autour de tables de bois
massives ; un grand vaisselier vitré (ill. VEX, « Cinq cents ans ») ; un évier où l'on rapporte sa
tasse (VEX, « Cinq cents ans ») ; un menu affiché où Willem fait ajouter une ligne pour le dessert
du jour (V1, « Directeur en carton » ; V4) ; des marques de taille au mur (V5, épilogue). Près de
vingt fées s'y réunissent pour écouter Nygglatho (V1, « Celui qui ne devrait pas être en vie ») ;
avant le repas, on prie ensemble et on lève les fourchettes en même temps (V3, « Je suis à la
maison »).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/dining_table_long.png` | 384 × 106 (4 × 1,1 m) | meuble | longue table de bois massif pour une dizaine de personnes, vue de face légèrement plongeante (on voit le plateau), plateau épais taché, entaillé, brûlé par une casserole, pieds tournés ; vide |
| 1 | `assets/hd2d/interior/props/dining_table_set.png` | 384 × 115 (4 × 1,2 m) | meuble | la même table dressée : assiettes de faïence dépareillées, fourchettes, gobelets d'étain et chopes de bois, deux corbeilles de pain, deux pichets ; tout à l'échelle, assiettes vides |
| 1 | `assets/hd2d/interior/props/chair_wood.png` | 48 × 96 (0,5 × 1 m) | meuble | chaise de bois à dossier à barreaux et assise paillée usée, vue de face (le dossier derrière l'assise, assise à 45 cm) |
| 1 | `assets/hd2d/interior/props/chair_wood_back.png` | 48 × 96 | meuble | la même chaise vue de dos : le dossier à barreaux vers la caméra, l'assise derrière ; pour le côté sud des tables |
| 1 | `assets/hd2d/interior/props/chair_child.png` | 43 × 77 (0,45 × 0,8 m) | meuble | petite chaise d'enfant de bois peint en vert passé, assise à 35 cm, un barreau recollé ; sert aussi au chevet de l'infirmerie (V1, « Entrepôt de fées » : la petite chaise près du lit) |
| 1 | `assets/hd2d/interior/props/china_cabinet.png` | 154 × 211 (1,6 × 2,2 m) | meuble | grand vaisselier : bas à portes pleines, haut vitré à croisillons rempli de bols, de bocaux et d'assiettes en rangées, chopes pendues à des crochets, une vitre fêlée recollée ; bois brun ciré usé (ill. VEX, « Cinq cents ans ») |
| 1 | `assets/hd2d/interior/props/sink_stone.png` | 134 × 101 (1,4 × 1,05 m) | meuble | évier de pierre posé sur un meuble de bois : un broc, un seau d'eau, un égouttoir de bois avec des tasses retournées, un torchon ; pas de robinet (VEX, « Cinq cents ans » ; V3 : on puise l'eau à la rivière) |
| 1 | `assets/hd2d/interior/wallitem_menu_board.png` | 77 × 96 (0,8 × 1 m) | élément de mur, bas à 1,1 m | tableau du menu : ardoise dans un cadre de bois, colonnes de traits de craie (aucune lettre), et en bas une ligne à part, encadrée à la craie et ornée d'une petite étoile : la ligne du dessert du jour que Willem a fait ajouter (V1, « Directeur en carton » ; V4) |
| 2 | `assets/hd2d/interior/wallitem_height_marks.png` | 38 × 154 (0,4 × 1,6 m) | élément de mur, bas au sol | marques de taille sur le plâtre : traits gravés au couteau et traits de crayon entre 0,9 et 1,5 m de haut, à côté de chacun un petit signe (étoile, fleur, cœur, épée) au lieu d'un nom ; deux traits presque au même niveau (V5, épilogue : les tailles de Nopht et de Rhantolk) |
| 2 | `assets/hd2d/interior/props/crystal_pendant.png` | 77 × 134 (0,8 × 1,4 m) | suspendu, ancre libre | suspension de fer forgé à trois cristaux lumineux (#FFE6A6) dans des cages, pendue à une chaîne (le haut de l'image est le crochet du plafond) |
| 1 | `assets/hd2d/interior/props/tableware_a.png` | 96 × 29 (1 × 0,3 m) | objet posé sur une table | un couvert pour trois : assiettes, fourchettes, deux chopes, un quignon de pain |
| 1 | `assets/hd2d/interior/props/meal_lunch.png` | 96 × 29 | objet posé sur une table | le déjeuner : un plat de purée, du porc sauté, une soupière de soupe aux herbes, une coupe d'oranges (VEX, intermède) |
| 1 | `assets/hd2d/interior/props/dessert_flans.png` | 77 × 24 (0,8 × 0,25 m) | objet posé sur une table | le dessert spécial de Willem : petites coupelles de flan doré nappé de caramel brillant, sur un plateau de bois, une cuillère (V1, « Directeur en carton ») |
| 2 | `assets/hd2d/interior/props/butter_cake.png` | 58 × 34 (0,6 × 0,35 m) | objet posé sur une table | un gros gâteau au beurre doré, déjà entamé, sur un plat de faïence, assez grand pour toute la maison (V3, « Je suis à la maison ») |
| 2 | `assets/hd2d/interior/props/tea_tray_cheesecake.png` | 58 × 29 (0,6 × 0,3 m) | objet posé sur une table | plateau de thé : théière, petites tasses, pot à lait, sucrier, et un cheese-cake cuit dont il manque deux parts (VEX, « Cinq cents ans ») |

### 3.5 La cuisine

Seule la fée de cuisine du jour y entre ; les autres regardent de loin (V1, « Directeur en
carton »). Un fourneau de cristal, un comptoir, un tablier ; les ingrédients du dessert : œufs,
sucre, lait, crème, baies (V1) ; une marmite et une louche (V3, « Des journées chaudes… ») ; un
pot de moutarde étiqueté d'une écriture d'enfant (VEX, « Cinq cents ans »). L'entrepôt n'a sans
doute pas l'eau courante (V3).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/crystal_stove.png` | 134 × 115 (1,4 × 1,2 m) | meuble | fourneau de fonte noire sur un socle de briques ; dans le foyer, derrière une petite porte à grille, un gros cristal ambré qui luit (#FFE6A6) au lieu de flammes ; deux plaques, une marmite et une petite casserole de caramel dessus, barre de laiton pour les torchons ; pas de bois, pas de tuyau de fumée (V1, « Directeur en carton » ; V5 : le réchaud de cristal) |
| 2 | `assets/hd2d/anim/pot_steam.png` | 48 × 96 (0,5 × 1 m), 6 images, 8 ips | bande animée, **alpha doux** | vapeur blanche qui monte d'une marmite et s'étire ; le bas de l'image est le bord de la marmite (non dessinée) |
| 1 | `assets/hd2d/interior/props/kitchen_counter.png` | 192 × 101 (2 × 1,05 m) | meuble | comptoir de bois épais à étagère basse : planche à découper, couteaux, bols empilés, un sac de farine ouvert, un pot à ustensiles, des épluchures |
| 1 | `assets/hd2d/interior/props/kitchen_table_ingredients.png` | 154 × 106 (1,6 × 1,1 m) | meuble | table de travail chargée des ingrédients du dessert : œufs dans un panier, sac de sucre, pot de lait, jatte de crème, bol de baies rouges, motte de beurre, pot de miel, noix ; un bol et un fouet (V1 ; V3) |
| 1 | `assets/hd2d/interior/wallitem_utensils.png` | 115 × 77 (1,2 × 0,8 m) | élément de mur, bas à 1,4 m | barre de fer où pendent une louche, une écumoire, deux poêles, une passoire et une très grande cuillère de bois |
| 2 | `assets/hd2d/interior/wallitem_spice_shelf.png` | 115 × 67 (1,2 × 0,7 m) | élément de mur, bas à 1,5 m | étagère murale de bocaux d'épices et d'herbes ; au bout, un petit pot de moutarde à l'étiquette couverte d'un gribouillis d'enfant illisible (VEX, « Cinq cents ans ») |
| 1 | `assets/hd2d/interior/props/water_tub.png` | 96 × 86 (1 × 0,9 m) | meuble | tonneau d'eau cerclé de fer avec une louche, deux seaux pleins posés à côté : l'eau puisée à la rivière (V3, « Des journées chaudes… ») |
| 2 | `assets/hd2d/interior/props/sacks_vegetables.png` | 115 × 67 (1,2 × 0,7 m) | meuble | gros sacs de toile ouverts, l'un de carottes, l'autre de pommes de terre, quelques-unes roulées par terre (V1 : le bon de commande retrouvé aux archives) |
| 2 | `assets/hd2d/interior/props/pantry_cupboard.png` | 106 × 192 (1,1 × 2 m) | meuble | garde-manger de bois à portes garnies de grillage fin, une porte entrouverte : bocaux, fromages, jambon pendu, pots de confiture |
| 2 | `assets/hd2d/interior/wallitem_apron_hook.png` | 38 × 86 (0,4 × 0,9 m) | élément de mur, bas à 0,9 m | tablier de toile blanche taché pendu à un crochet de fer (V1 : Willem apporte son tablier) |

### 3.6 La salle de lecture

Le silence y est obligatoire ; Nephren le rappelle en tapant sur les têtes avec un papier roulé
(V1, « Les filles de l'entrepôt ») ; un siège à la fenêtre avec vue sur le champ (même source) ;
des tables, des étagères de gros livres (V2, « L'écoulement du temps depuis lors » ; V4, « La fille
aux cheveux cramoisis » III). Les livres comptent beaucoup : on en commande à la librairie (V3).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/bookshelf_tall.png` | 154 × 221 (1,6 × 2,3 m) | meuble | haute bibliothèque de bois sombre pleine de gros livres reliés de cuir brun, rouge et vert, dos ornés de filets dorés sans titres lisibles, rangés serré |
| 2 | `assets/hd2d/interior/props/bookshelf_tall_b.png` | 154 × 221 | meuble | la même bibliothèque en désordre : livres couchés, grands livres d'images, romans minces, un trou dans une rangée, un livre ouvert posé à plat |
| 1 | `assets/hd2d/interior/props/bookshelf_low.png` | 134 × 86 (1,4 × 0,9 m) | meuble | étagère basse de livres d'images pour les petites, dos de toutes les couleurs, un coussin posé dessus |
| 1 | `assets/hd2d/interior/props/reading_table.png` | 173 × 91 (1,8 × 0,95 m) | meuble | table de lecture : deux livres ouverts, des piles, un papier roulé en bâton (celui de Nephren), une lampe de table à cristal (V1) |
| 2 | `assets/hd2d/interior/props/armchair_reading.png` | 96 × 101 (1 × 1,05 m) | meuble | fauteuil de cuir brun craquelé, affaissé, un plaid de laine à carreaux sur l'accoudoir |
| 2 | `assets/hd2d/interior/props/book_pile.png` | 48 × 48 (0,5 × 0,5 m) | meuble | pile de livres posée par terre, un livre ouvert à plat dessus |

### 3.7 Les archives (salle de stockage)

Une plaque de bronze à la porte ; une pièce assez grande envahie par un océan de papiers mêlés
(rapports, directives, bons de commande, coupures de magazines pour filles) ; un bureau et une
chaise sous les piles ; une horloge murale dont on entend la trotteuse et qui sonne les heures ; un
canapé beige à trois places (V1, « Les valeureux et leurs successeurs » ; ill. V1) où Willem et
Nephren s'endorment (V3, « Le béguin d'une fille… »).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/wallitem_bronze_plaque.png` | 48 × 19 (0,5 × 0,2 m) | élément de mur, bas à 1,6 m | plaque de bronze vissée près de la porte, verdie aux bords, gravée de lignes ornées qui ne forment aucune lettre (V1 : la plaque de la salle de stockage) |
| 1 | `assets/hd2d/interior/props/paper_pile_a.png` | 115 × 134 (1,2 × 1,4 m) | meuble | montagne de papiers : liasses ficelées, chemises cartonnées, cartons ouverts qui débordent, feuilles qui glissent ; lignes grises, aucune lettre (V1 : un océan de papiers) |
| 1 | `assets/hd2d/interior/props/paper_pile_b.png` | 77 × 86 (0,8 × 0,9 m) | meuble | pile plus petite, un registre relié posé de travers dessus |
| 1 | `assets/hd2d/interior/props/paper_pile_c.png` | 58 × 48 (0,6 × 0,5 m) | meuble | petite pile de dossiers effondrée |
| 1 | `assets/hd2d/interior/props/archive_shelves.png` | 192 × 230 (2 × 2,4 m) | meuble | rayonnages de bois brut chargés jusqu'en haut de cartons, de registres reliés et de rouleaux de papier, étiquettes vierges |
| 1 | `assets/hd2d/interior/props/desk_buried.png` | 134 × 125 (1,4 × 1,3 m) | meuble | bureau enfoui sous les piles de papiers, chaise tirée de travers, encrier, lampe à cristal éteinte (V1) |
| 1 | `assets/hd2d/interior/props/sofa_beige.png` | 192 × 86 (2 × 0,9 m) | meuble | canapé beige à trois places, tissu usé, assise affaissée au milieu, une couverture pliée sur l'accoudoir (ill. V1 ; V3) |
| 1 | `assets/hd2d/interior/wallitem_wall_clock.png` | 48 × 106 (0,5 × 1,1 m) | élément de mur, bas à 1,2 m | horloge murale à balancier dans une caisse de bois sombre, cadran crème marqué de traits pour les heures (aucun chiffre), aiguilles fines, balancier de laiton derrière une vitre (V1 : la trotteuse, les douze coups de minuit) |
| 3 | `assets/hd2d/anim/wall_clock_swing.png` | 48 × 106, 4 images, 2 ips | bande animée | la même horloge : le balancier va et vient (la 4e image s'enchaîne sur la 1re), le reste identique au pixel près |
| 2 | `assets/hd2d/interior/props/filing_cabinet.png` | 96 × 134 (1 × 1,4 m) | meuble | meuble à casiers et à tiroirs de bois, étiquettes vierges, un tiroir entrouvert plein de fiches |
| 2 | `assets/hd2d/decals/papers_floor.png` | 192 × 144 (2 × 1,5 m) | décalque | feuilles éparses par terre vues de dessus : un rapport, une coupure de magazine, un bon de commande, une enveloppe ; lignes grises, aucune lettre |
| 2 | `assets/hd2d/interior/props/coffee_tray.png` | 48 × 24 (0,5 × 0,25 m) | objet posé sur une table | plateau : grande tasse de café noir épais comme du sirop, sandwich sur pain sec (V1, « Les valeureux… » : l'en-cas que Nephren apporte la nuit) |
| 3 | `assets/hd2d/interior/wallitem_clippings.png` | 77 × 58 (0,8 × 0,6 m) | élément de mur, bas à 1,3 m | coupures de magazines pour filles épinglées : dessins de robes et de chapeaux, sans texte (V1) |

### 3.8 L'infirmerie

Des lits, une petite chaise au chevet, des bandages, une serviette humide, une couverture, un
oreiller qu'on lance contre le mur ; Nygglatho y soigne en blouse (V1, « Entrepôt de fées » ;
« Les valeureux… ») ; des rideaux et une fenêtre, un vase de fleurs dont on change l'eau, un
calendrier dont on tourne la feuille chaque matin, un bureau ; un équipement limité : tableau de
notes, éprouvette de poudre d'argent (V3, « La Fin d'un rêve, le début d'un rêve » ; « Je suis à la
maison »).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/bed_iron.png` | 192 × 101 (2 × 1,05 m) | lit vu de flanc, tête à gauche | lit de fer peint en blanc écaillé, tête à barreaux plus haute que le pied, matelas, drap blanc, couverture de laine grise, oreiller ; un lit qui craque (V1) |
| 2 | `assets/hd2d/interior/props/bed_iron_cover.png` | 192 × 67 (2 × 0,7 m) | même cadrage que `bed_iron`, **à confirmer par le moteur** | la couverture seule du même lit, à poser par-dessus un personnage couché : couverture grise et drap rabattu, à la même place au pixel près que dans `bed_iron.png` (bas de l'image = pied du lit au sol) ; transparent partout ailleurs (ni lit, ni oreiller) |
| 1 | `assets/hd2d/interior/props/bedside_table.png` | 48 × 67 (0,5 × 0,7 m) | meuble | table de chevet : bassine émaillée, serviette humide pliée, bandages roulés, carafe et verre |
| 2 | `assets/hd2d/interior/props/bed_curtain.png` | 154 × 202 (1,6 × 2,1 m) | meuble | rideau de toile blanche sur une tringle portée par deux pieds de fer, à moitié tiré |
| 1 | `assets/hd2d/interior/wallitem_day_calendar.png` | 29 × 38 (0,3 × 0,4 m) | élément de mur, bas à 1,4 m | éphéméride : bloc de feuillets sur un carton, la feuille du jour marquée d'un gros signe rouge qui n'est pas un chiffre (V3 : on tourne le jour chaque matin) |
| 2 | `assets/hd2d/interior/props/vase_flowers.png` | 24 × 38 (0,25 × 0,4 m) | objet posé sur un meuble | vase de terre vernissée avec un bouquet de fleurs des champs d'automne (V3) |
| 1 | `assets/hd2d/interior/props/medicine_cabinet.png` | 96 × 173 (1 × 1,8 m) | meuble | armoire à pharmacie vitrée : fioles, bocaux de poudres, rouleaux de bandages, une trousse de premiers secours de cuir, des éprouvettes sur un support ; étiquettes vierges (V1 ; V3) |
| 1 | `assets/hd2d/interior/props/infirmary_desk.png` | 125 × 96 (1,3 × 1 m) | meuble | bureau simple et sa chaise : un tableau de notes à pince, une plume, une éprouvette où brille une poudre argentée (V3 : la poudre d'argent purificateur), une lampe à cristal |
| 2 | `assets/hd2d/interior/props/washbasin_stand.png` | 58 × 96 (0,6 × 1 m) | meuble | lave-mains sur pied de fer : cuvette, broc, savon, serviette pendue |
| 2 | `assets/hd2d/interior/wallitem_labcoat.png` | 48 × 106 (0,5 × 1,1 m) | élément de mur, bas à 0,7 m | longue blouse blanche de laboratoire pendue à une patère, à la taille d'une très grande femme (V1 : Nygglatho soigne en blouse) |

### 3.9 La salle de jeux

Un tapis et des peluches ; Collon s'entraîne aux clés de bras sur une peluche bleue, Pannibal
frappe une balle blanche contre le mur, Tiat s'étale sur le tapis (V2, « Qu'est-il advenu de la
promesse ? ») ; des jeux de société, et les petites s'empilent sur le dos de Willem (VEX, « Le cas
de la fée aux cheveux gris »). Le vieux piano vient du V4 ; on le place ici.

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/decals/rug_playroom.png` | 384 × 288 (4 × 3 m) | décalque à bord plein | grand tapis tissé vu de dessus : rayures et frise de losanges rouge passé, ocre et bleu, usé en plaques claires, une tache, franges aux deux bouts (V2) |
| 1 | `assets/hd2d/interior/props/plush_blue.png` | 48 × 48 (0,5 × 0,5 m) | meuble | grand ours en peluche bleu assis, reprisé de fils d'autres couleurs, une oreille pendante (V2 : la peluche bleue de Collon) |
| 1 | `assets/hd2d/interior/props/plush_pile.png` | 96 × 58 (1 × 0,6 m) | meuble | tas de peluches : lapin gris, chat de chiffon, petit ours, poupée de laine |
| 1 | `assets/hd2d/interior/props/toy_chest.png` | 96 × 77 (1 × 0,8 m) | meuble | coffre à jouets de bois au couvercle ouvert : épées de bois, balles, cerceau, une poupée qui pend dehors |
| 1 | `assets/hd2d/interior/props/board_games_shelf.png` | 115 × 154 (1,2 × 1,6 m) | meuble | étagère de jeux de société : boîtes empilées aux couvercles colorés sans texte, un damier plié, des sacs de pions, des jeux de cartes ficelés (VEX) |
| 1 | `assets/hd2d/interior/props/game_table.png` | 115 × 58 (1,2 × 0,6 m) | meuble | table basse avec une partie en cours : damier, pions de bois, cartes retournées, deux dés |
| 2 | `assets/hd2d/interior/props/floor_cushions.png` | 115 × 38 (1,2 × 0,4 m) | meuble | trois gros coussins rapiécés posés par terre |
| 1 | `assets/hd2d/interior/props/ball_white.png` | 19 × 19 (0,2 × 0,2 m) | meuble | petite balle blanche de toile cousue, salie (V2) |
| 2 | `assets/hd2d/interior/wallitem_kids_drawings.png` | 115 × 58 (1,2 × 0,6 m) | élément de mur, bas à 1,1 m | dessins d'enfants punaisés : un soleil, des fées aux cheveux de toutes les couleurs, un grand monsieur aux cheveux noirs, une grande dame aux cheveux roses qui sourit ; aucune lettre |
| 2 | `assets/hd2d/decals/cards_floor.png` | 144 × 96 (1,5 × 1 m) | décalque | jeu de cartes éparpillé par terre vu de dessus, dos rouges, figures sans lettres ni chiffres ; sert aussi dans la chambre de la grande sœur (V1, « Entrepôt de fées ») |
| 3 | `assets/hd2d/interior/props/piano_old.png` | 154 × 134 (1,6 × 1,4 m) | meuble | vieux piano droit de bois sombre, couvercle ouvert, touches jaunies, une partition sans notes lisibles, bougeoirs vides, tabouret rond (V4, « La fille aux cheveux cramoisis » III) |

### 3.10 La salle de bains

Un grand miroir installé par Nygglatho (V3, « Des journées chaudes… ») ; un bain d'eau chaude, qu'on
remplit à la rivière ou qu'on chauffe au venenum ; on se savonne les cheveux, puis on doit les
sécher à la serviette (même source) ; un règlement du bain affiché, avec des clauses ajoutées du
temps de Willem (V4, « La fille aux cheveux cramoisis » III).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/bath_tub.png` | 230 × 96 (2,4 × 1 m) | meuble | grande cuve de bain de bois cerclée de fer, assez large pour plusieurs enfants, eau chaude un peu trouble, un marchepied de bois devant, un savon sur le bord ; aucun robinet |
| 2 | `assets/hd2d/anim/bath_steam.png` | 192 × 144 (2 × 1,5 m), 6 images, 6 ips | bande animée, **alpha doux** | vapeur qui monte de l'eau chaude en volutes lentes ; le bas de l'image est la surface de l'eau (non dessinée) |
| 1 | `assets/hd2d/interior/props/wash_tub.png` | 77 × 48 (0,8 × 0,5 m) | meuble | baquet de bois et deux seaux d'eau |
| 1 | `assets/hd2d/interior/props/mirror_large.png` | 115 × 202 (1,2 × 2,1 m) | meuble | grand miroir en pied à cadre de bois doré terni, fixé au mur ; le verre est un gris bleuté uni avec un reflet en diagonale (n'y dessine ni personnage ni reflet de la pièce) (V3) |
| 1 | `assets/hd2d/interior/wallitem_bath_rules.png` | 38 × 53 (0,4 × 0,55 m) | élément de mur, bas à 1,3 m | règlement du bain : feuille encadrée de bois, lignes grises bien alignées, puis en bas trois lignes ajoutées d'une autre encre, plus serrées (V4) ; aucune lettre |
| 1 | `assets/hd2d/interior/props/towel_shelf.png` | 96 × 154 (1 × 1,6 m) | meuble | étagère de bois : serviettes pliées de toutes les couleurs, savons, brosses à cheveux, peignes, un bocal de rubans |
| 2 | `assets/hd2d/interior/props/hamper.png` | 58 × 67 (0,6 × 0,7 m) | meuble | panier à linge sale en osier, une serviette qui pend par-dessus le bord |
| 2 | `assets/hd2d/decals/bath_puddles.png` | 192 × 144 (2 × 1,5 m) | décalque | flaques et éclaboussures d'eau savonneuse sur le carrelage, quelques bulles, empreintes de petits pieds mouillés qui s'en vont |

### 3.11 La chambre de Nygglatho

Une petite pièce : table simple, deux chaises, une étagère, un lit, toutes sortes d'objets, un tapis
devant la porte où s'écroule l'avalanche, le service à thé (V1, « L'Homme sans Marque ») ; une
cheminée qu'elle allume, une bouilloire sur le feu, une petite table à thé, la chaise de l'invité,
un bureau où elle pose le menton sur ses bras croisés, la dernière petite lampe à huile de lecture
(V2, « De ce côté-ci de l'écran » ; « Qu'est-il advenu de la promesse ? ») ; des scones et trois
confitures aux réunions (V3) ; le cristal de communication devant lequel elle s'assoit (V1, « La
femme forte et robotique » ; V5). La nuit, la lumière filtre sous sa porte (V2, épilogue).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/fireplace.png` | 154 × 134 (1,6 × 1,4 m) | meuble | cheminée de pierre claire à manteau de bois, âtre noirci, une bouilloire de cuivre pendue à la crémaillère, bûches dans l'âtre ; **sans flammes** (elles sont à part) ; sur le manteau, une boîte à thé et une petite pendule sans chiffres (V2) |
| 1 | `assets/hd2d/anim/hearth_fire.png` | 77 × 48 (0,8 × 0,5 m), 6 images, 10 ips | bande animée | flammes et braises d'un feu de bûches, sans l'âtre : orange et jaune, quelques étincelles ; le bas de l'image est la sole du foyer |
| 1 | `assets/hd2d/interior/props/tea_table.png` | 86 × 77 (0,9 × 0,8 m) | meuble | petite table ronde nappée : service à thé de porcelaine fleurie (théière, tasses, pot à lait, sucrier), assiette de scones, trois pots de confiture dont un d'abricot (V2 ; V3) |
| 1 | `assets/hd2d/interior/props/chair_guest.png` | 77 × 101 (0,8 × 1,05 m) | meuble | chaise de l'invité : chaise rembourrée à dossier arrondi, velours vert usé, coussin brodé de fleurs (V2) |
| 1 | `assets/hd2d/interior/props/desk_nygglatho.png` | 134 × 106 (1,4 × 1,1 m) | meuble | bureau de bois clair bien rangé : registres, plume et encrier, papiers en piles nettes, la petite lampe à huile, un tiroir fermé à clé (V2 ; V5) |
| 1 | `assets/hd2d/interior/props/comm_crystal.png` | 67 × 134 (0,7 × 1,4 m) | meuble | cristal de communication : gros cristal taillé bleu pâle, éteint, sur un socle de laiton à griffes, posé sur une console de bois étroite (V1 ; V5 : il montre le visage de qui appelle) |
| 2 | `assets/hd2d/anim/comm_crystal_call.png` | 67 × 134, 4 images, 6 ips | bande animée | le même cristal qui s'allume et pulse d'un bleu clair lumineux (la lueur est dans le cristal, alpha net ; le jeu ajoute le halo), console identique au pixel près |
| 1 | `assets/hd2d/interior/props/bed_nygglatho.png` | 202 × 106 (2,1 × 1,1 m) | lit vu de flanc, tête à gauche | grand lit de bois à couvre-lit à volants rose passé, coussins brodés, plus long que les autres lits (elle est très grande) |
| 1 | `assets/hd2d/interior/props/shelf_nygglatho.png` | 115 × 173 (1,2 × 1,8 m) | meuble | étagère chargée de toutes sortes d'objets : boîtes à thé, bocaux de confiture, livres de médecine et de cuisine, trousse de premiers secours, petite bouteille d'alcool, bibelots, un ruban (V1 ; V2) |
| 2 | `assets/hd2d/interior/props/oil_lamp.png` | 24 × 38 (0,25 × 0,4 m) | objet posé sur un meuble | petite lampe à huile de lecture en laiton, verre bombé, mèche (V2) |
| 1 | `assets/hd2d/decals/rug_brown.png` | 192 × 115 (2 × 1,2 m) | décalque à bord plein | tapis brun à bordure ocre, usé, devant la porte (V1 ; ill. V1 : l'avalanche de petites s'y écroule) |

### 3.12 La chambre de Willem

Presque vide : un lit, une armoire vide, une lampe murale, un plancher nu, pas de rideaux, pas de
chaise ; les draps sentent le soleil (V1, « L'Homme sans Marque ») ; il s'assoit au rebord de la
fenêtre (V1, « Directeur en carton ») ; plus tard, on y retrouve un cintre d'uniforme, un rasoir,
une grande cuillère, une grande bouteille d'épices (V4).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/bed_plain.png` | 192 × 91 (2 × 0,95 m) | lit vu de flanc, tête à gauche | lit de bois simple et étroit, draps blancs bien tirés, couverture brune pliée au pied |
| 1 | `assets/hd2d/interior/props/wardrobe_plain.png` | 96 × 192 (1 × 2 m) | meuble | armoire de bois nu, une porte entrouverte sur l'intérieur vide : un seul cintre avec une veste d'uniforme bleu nuit |
| 1 | `assets/hd2d/interior/wallitem_wall_lamp.png` | 29 × 43 (0,3 × 0,45 m) | élément de mur, bas à 1,5 m | lampe murale : petit cristal sous un abat-jour de laiton cabossé, potence de fer (V1) |
| 2 | `assets/hd2d/interior/props/footlocker.png` | 77 × 48 (0,8 × 0,5 m) | meuble | malle de voyage cabossée cerclée de cuir ; posés dessus, un rasoir, une grande cuillère et une grande bouteille d'épices (V4) |

### 3.13 Les chambres des fées

Les petites ont des chambres d'enfants avec des fenêtres (V3) ; les murs sont minces, on entend tout
(V4). La **chambre de Chtholly** : un lit et sa couverture, une fenêtre à rideaux, une porte jamais
verrouillée, un bureau où un miroir est posé face contre le bois, une chaise (V2, « L'écoulement du
temps depuis lors » ; V3), un calendrier où elle raye les jours, une armoire au fond de laquelle
dort le chapeau offert par Willem (V1, « Les filles de l'entrepôt »). La **chambre de la grande
sœur** morte : grand désordre, jeu de cartes éparpillé, seul le bureau est propre, avec une broche
d'argent posée dessus (V1, « Entrepôt de fées »).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/bed_child.png` | 154 × 77 (1,6 × 0,8 m) | lit vu de flanc, tête à gauche | petit lit de bois peint en bleu passé, couverture en patchwork de tissus dépareillés, oreiller |
| 1 | `assets/hd2d/interior/props/bed_child_messy.png` | 154 × 86 (1,6 × 0,9 m) | lit vu de flanc, tête à gauche | le même lit défait : couverture en boule, oreiller tombé par terre au pied, une peluche coincée contre la tête de lit |
| 2 | `assets/hd2d/interior/props/bunk_bed.png` | 173 × 182 (1,8 × 1,9 m) | lit vu de flanc, tête à gauche | lits superposés de bois brut, échelle au pied, deux couvertures de couleurs différentes, un ruban noué au montant (original : une trentaine de fées dans de petites chambres) |
| 1 | `assets/hd2d/interior/props/dresser_child.png` | 86 × 86 (0,9 × 0,9 m) | meuble | commode basse peinte : rubans, peigne, boîte à trésors, petit miroir posé debout |
| 2 | `assets/hd2d/interior/props/clothes_chest.png` | 86 × 58 (0,9 × 0,6 m) | meuble | coffre à vêtements entrouvert, une manche qui dépasse |
| 1 | `assets/hd2d/interior/props/bed_chtholly.png` | 192 × 91 (2 × 0,95 m) | lit vu de flanc, tête à gauche | lit simple bien fait, couverture bleu passé, oreiller blanc ; la chambre d'une aînée sérieuse (VEX ; V2) |
| 1 | `assets/hd2d/interior/props/desk_chtholly.png` | 106 × 101 (1,1 × 1,05 m) | meuble | petit bureau rangé et sa chaise : un miroir à main posé face contre le bureau, deux livres empilés, une plume (V2 ; V3) |
| 1 | `assets/hd2d/interior/wallitem_calendar.png` | 38 × 48 (0,4 × 0,5 m) | élément de mur, bas à 1,3 m | calendrier mural : une petite gravure de paysage en haut, puis une grille de cases dont les premières sont barrées d'une croix au crayon ; aucun chiffre ni mot (V1 : elle y raye les jours ; le jeu s'en sert de journal) |
| 1 | `assets/hd2d/interior/props/wardrobe_chtholly.png` | 96 × 192 (1 × 2 m) | meuble | armoire de bois clair, une porte entrouverte : quelques robes, un manteau gris souris, et sur l'étagère du haut, tout au fond, une boîte à chapeau (V1 : le chapeau caché au fond de l'armoire) |
| 2 | `assets/hd2d/interior/props/hat_blue.png` | 48 × 24 (0,5 × 0,25 m) | objet posé sur un meuble | grand chapeau élégant bleu foncé à large bord et ruban (V1 ; V3 : posé sur le coin du bureau) |
| 2 | `assets/hd2d/interior/props/desk_clean_brooch.png` | 106 × 101 | meuble | bureau de bois sombre parfaitement propre et vide, sauf une broche d'argent à pierre bleue en goutte posée au centre (V1, « Entrepôt de fées ») |
| 2 | `assets/hd2d/decals/clothes_floor.png` | 192 × 144 (2 × 1,5 m) | décalque | vêtements jetés par terre vus de dessus : chemise, jupe, chaussettes dépareillées, une écharpe ; aucun sous-vêtement visible (V1 : le grand désordre de la grande sœur) |

### 3.14 Le toit et le séchoir

Un séchoir où flotte beaucoup de linge le jour (V2, « De ce côté-ci de l'écran ») ; la nuit, le
poste d'observation des étoiles ; une rambarde de métal laide, abîmée et branlante, trop basse pour
Nygglatho et à la hauteur des fées, d'où une petite tombe (VEX, « Le cas de la fée aux cheveux
gris » ; V3, « Des journées chaudes… ») ; un panier tressé pour décrocher les draps (V2). Le panier
existe déjà (`assets/hd2d/props/laundry_basket.png`), comme la cheminée (`chimney_brick.png`).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/roof_railing.png` | 192 × 77 (2 × 0,8 m) | meuble, **sans raccord à gauche et à droite** | module de rambarde de fer basse, à hauteur de fée (0,7 m) : main courante et barreaux, deux barreaux tordus, peinture verte écaillée, rouille ; laide et fragile (V3 ; VEX) |
| 2 | `assets/hd2d/interior/props/roof_railing_broken.png` | 192 × 77 | meuble, se raccorde à `roof_railing` | le même module dont un pan est tordu vers le dehors et un barreau manque (V3 : Almita tombe du toit) |
| 1 | `assets/hd2d/interior/props/drying_frame.png` | 384 × 211 (4 × 2,2 m) | meuble | séchoir à linge : deux poteaux de fer en T, quatre cordes, draps blancs, serviettes, petites robes et chaussettes d'enfants, pinces de bois (V2) |
| 2 | `assets/hd2d/anim/drying_frame_wave.png` | 384 × 211, 4 images, 4 ips | bande animée | `drying_frame.png` (jointe) : le linge ondule au vent vers la droite, poteaux et cordes immobiles |
| 2 | `assets/hd2d/interior/props/roof_hatch.png` | 96 × 58 (1 × 0,6 m) | meuble | trappe d'accès au toit ouverte, le haut d'une échelle de bois qui dépasse, couvercle rabattu (original) |
| 2 | `assets/hd2d/interior/props/roof_edge_slate.png` | 384 × 96 (4 × 1 m) | meuble, sans raccord à gauche et à droite, **format à confirmer par le moteur** | bord du toit en pente qui borde la terrasse : rangées d'ardoises bleu-gris (#5E6C86) qui descendent vers le bas de l'image, mousse, une ardoise cassée, gouttière de cuivre vert-de-grisé en bas |

### 3.15 La salle des armes

Derrière la porte rivetée à cinq serrures, une crypte sans lumière qui sent l'humidité, le moisi et
la poussière ; une dizaine d'épées appuyées contre un mur, presque toutes de la taille d'une
personne, à longue poignée pour deux mains, aux lames faites de pièces de métal assemblées comme un
puzzle, d'où des fissures et des couleurs différentes d'un côté et de l'autre ; les épées en service
rentrent emmaillotées de tissu blanc (V1, « Entrepôt de fées ») ; des talismans de réserve (V3).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/sword_rack_a.png` | 384 × 182 (4 × 1,9 m) | meuble | cinq épées antiques debout contre un râtelier de bois sombre, chacune presque de la taille d'une personne (1,6 à 1,8 m), longues poignées à deux mains, lames faites de plaques de métal assemblées et fissurées, de couleurs différentes de part et d'autre (argent, bronze, bleuté, ivoire), gardes sombres ; vieilles, poussiéreuses ; aucune ne ressemble à une arme moderne |
| 1 | `assets/hd2d/interior/props/sword_rack_b.png` | 384 × 182 | meuble | cinq autres épées du même genre, d'autres formes : lame large, lame fine, garde en croix, garde ronde, une lame à moitié noircie |
| 1 | `assets/hd2d/interior/props/swords_wrapped.png` | 154 × 154 (1,6 × 1,6 m) | meuble | trois grandes épées emmaillotées de tissu blanc, couchées sur un tréteau de bois, seules les poignées dépassent (V1) |
| 2 | `assets/hd2d/interior/props/talisman_chest.png` | 77 × 58 (0,8 × 0,6 m) | meuble | coffret ouvert garni de velours sombre, en casiers : des éclats de métal blanc gravés, les talismans en réserve (V3, « Le béguin d'une fille… ») |
| 1 | `assets/hd2d/interior/props/crypt_pillar.png` | 58 × 288 (0,6 × 3 m) | meuble | pilier de pierre trapu (base, fût, chapiteau simple) qui porte la voûte, humidité, salpêtre |
| 2 | `assets/hd2d/interior/props/crypt_stairs.png` | 154 × 240 (1,6 × 2,5 m) | meuble (sortie) | escalier de pierre vu de face qui remonte vers le fond jusqu'à la porte rivetée, marches creusées et humides |
| 2 | `assets/hd2d/interior/wallitem_cobweb.png` | 48 × 48 (0,5 × 0,5 m) | élément de mur, bas à 2,4 m | toile d'araignée grise dans un angle, chargée de poussière |
| 3 | `assets/hd2d/interior/props/polishing_trestle.png` | 115 × 86 (1,2 × 0,9 m) | meuble | tréteau de bois : un linge étendu, un seau d'eau, des chiffons pour polir les lames (VEX, prologue : on polit Seniorious avec de l'eau et un linge) |

### 3.16 Objets communs

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/crystal_lamp_table.png` | 29 × 48 (0,3 × 0,5 m) | objet posé sur un meuble | lampe de table : petit cristal lumineux (#FFE6A6) dans une cloche de verre, pied de laiton |
| 3 | `assets/hd2d/interior/props/potted_plant.png` | 38 × 58 (0,4 × 0,6 m) | meuble | plante verte dans un pot de terre ébréché (V5 : les pots de fleurs qu'on casse) |

### 3.17 Ce qu'on doit voir, pièce par pièce

Pour garder la cohérence des images et guider leur pose :

- **Le couloir** : parquet usé, murs plâtrés, une porte tous les 3 ou 4 m, plannings et écriteaux
  entre les portes, appliques à cristal, le point d'eau et ses serviettes, des bottines qui
  traînent ; à l'étage, le seau sous la fuite et les planches de la réparation.
- **Le réfectoire** : deux ou trois longues tables et leurs chaises, la grande fenêtre, le
  vaisselier, l'évier, le menu, les marques de taille, une suspension au-dessus de chaque table.
- **La cuisine** : le fourneau de cristal contre le mur du fond, le comptoir, la table des
  ingrédients, le tonneau d'eau, les ustensiles pendus ; petite, encombrée.
- **La salle de lecture** : la fenêtre à banc, deux bibliothèques hautes, l'étagère basse, la table
  de lecture, un fauteuil, des piles de livres par terre.
- **Les archives** : on ne voit presque plus le sol ; piles, rayonnages, le bureau enfoui, le
  canapé beige, l'horloge.
- **L'infirmerie** : deux ou trois lits de fer, une table de chevet chacun, l'armoire à pharmacie,
  le bureau, le vase, l'éphéméride, les rideaux.
- **La salle de jeux** : le grand tapis, les peluches, le coffre à jouets, l'étagère de jeux, la
  table basse et sa partie en cours, les dessins au mur, le vieux piano.
- **La salle de bains** : la cuve, le grand miroir, l'étagère de serviettes, le règlement, des
  flaques.
- **Chez Nygglatho** : la cheminée allumée, la table à thé et la chaise de l'invité devant, le
  bureau, le cristal de communication, le lit, l'étagère, le tapis brun devant la porte.
- **Chez Willem** : un lit, une armoire, une lampe, la fenêtre nue ; le vide est le sujet.
- **Les chambres des fées** : deux à quatre petits lits, une commode, des peluches ; chez Chtholly,
  un seul lit, le bureau, le calendrier, l'armoire.
- **Le toit** : la terrasse de planches, le séchoir et son linge, la rambarde basse sur tout le
  tour, la trappe, la cheminée ; la nuit, rien que les étoiles.
- **La salle des armes** : dalles, piliers, les deux râteliers d'épées contre le mur du fond, le
  tréteau aux épées emmaillotées ; aucune lumière, sauf celle qu'on apporte.

## 4. Lot J : les personnages

### 4.1 Rappel du format (à coller avec le lot)

Les personnages sont des **planches de sprites** au format de l'easter egg, repris tel quel
(cahier n° 1, section 3) : une planche PNG et son JSON **par vue**.

- `<id>.png` + `<id>.json` : le **profil**, tourné vers la droite (le jeu en fait la gauche en
  miroir) ; `<id>_front.png` + `.json` : la **face** (vers la caméra) ; `<id>_back.png` + `.json` :
  le **dos**. Les trois vues ont exactement les mêmes animations, nombres d'images, `ips`,
  `boucle`, `coup` et `onde`.
- Une **rangée par animation**, de haut en bas dans l'ordre du tableau de la planche ; les images
  d'une rangée de gauche à droite, séparées d'au moins 2 px transparents. Fond transparent, alpha 0
  ou 255.
- Le JSON :

```json
{ "version": 1, "echelle": 1, "planche": [largeur, hauteur], "direction": "right",
  "format": "images: [x,y,width,height,anchor_x,anchor_y] in atlas pixels",
  "animations": {
    "repos":  { "ips": 2,  "boucle": true,  "images": [[x, y, l, h, ax, ay], [x, y, l, h, ax, ay]] },
    "course": { "ips": 14, "boucle": true,  "images": [ … 5 images … ] },
    "frappe": { "ips": 14, "boucle": false, "images": [ … 4 images … ], "coup": [2] } } }
```

- `ancre` (`ax`, `ay`) : le point au sol entre les deux pieds, en px depuis le coin haut gauche de
  l'image ; il ne bouge pas d'une image à l'autre quand le personnage ne se déplace pas. Les
  ancres se recalculent par `python3 tools/hd2d_sheets.py anchors <json> --write`.
- Les images sont **numérotées à partir de 0**, comme dans le JSON : `coup : [2]` désigne la
  troisième image de la rangée.
- **Hauteur debout** : la 1re image de `repos` mesure exactement la hauteur donnée en px, de
  l'ancre au sommet de la tête (cheveux compris). Toutes les images debout (`repos`, `marche`,
  `parle`, `porte`, `travaille`, `hanches`) gardent cette taille ; `course` peut être un peu plus
  basse (penchée), jamais plus haute ; les autres (saut, chute, assis, couché) dépassent ou
  descendent librement, à la même échelle.
- **Trois vues de même hauteur**, **une seule silhouette par case**, **accessoires du même côté**
  (de dos, ils passent de l'autre côté de l'image), **rien sous la ligne des pieds**.
- Ce qu'on tient (ballon, livre, plateau, panier, outil) est dessiné dans la main quand la
  consigne le dit ; le siège, le lit, l'arbre, la marmite ou la table ne le sont **jamais** : le
  jeu pose le personnage dessus ou devant.

**Les quatre sortes de planches de ce lot** :

| Sorte | Nom | Ce qu'elle contient |
| --- | --- | --- |
| **Complémentaire** | `<id>_life` | pour un personnage déjà livré qui garde sa tenue : sa 1re rangée est `repos`, **recopiée au pixel près** de la planche existante de la même vue (c'est l'étalon de taille, ne la redessine pas), puis seulement les animations nouvelles. Le jeu la fusionne avec la planche existante ou la charge à part : **format à confirmer par le moteur** |
| **De tenue** | `<id>_home`, `<id>_pajamas`, `<id>_rain`, `willem_coat`… | le même personnage dans une autre tenue (sans arme, en pyjama, en pèlerine) : planche complète, avec ses propres `repos`, `marche` et `parle`, à la même hauteur debout, mêmes cheveux, même visage, mêmes couleurs |
| **De geste** | `willem_cook`, `nygglatho_tea`… | une planche par geste de métier (`travaille`) et par personnage, comme le veut la section 8.1 de la refonte, avec le `repos` de la tenue de ce geste |
| **Neuve** | `kana`, `fairy_01`, `butcher`… | un personnage qui n'a pas encore de planche |

Toutes les planches de ce lot ont leurs trois vues (`<id>`, `<id>_front`, `<id>_back`) et leurs
trois JSON, dans `assets/characters/<dossier>/`. Une planche de tenue ou de geste va dans le
dossier du personnage (`assets/characters/willem/willem_cook.png`).

**Références à joindre** : les trois vues existantes du personnage (par exemple
`assets/characters/tiat/tiat.png`, `tiat_front.png`, `tiat_back.png`), et pour une planche neuve
deux planches livrées de même genre (une petite fée : `tiat.png` et `lakhesh.png` ; un homme-bête :
`cat_waiter.png` et `baker.png`) pour le rendu, la palette et les proportions.

**Consigne** : colle le bloc de style, ce rappel, la fiche des animations (4.2), puis « Planches de
sprites `assets/characters/<dossier>/<id>.png` (profil tourné vers la droite), `<id>_front.png` (de
face) et `<id>_back.png` (de dos), avec leurs JSON, fond transparent, mêmes animations et nombres
d'images dans les trois vues, une rangée par animation dans l'ordre du tableau, une seule
silhouette par case, hauteur debout **<n> px** dans toutes les images debout et les trois vues : »
puis le bloc de la planche (qui elle est, son tableau d'animations).

### 4.2 Les animations, image par image

La fiche commune ; chaque planche y ajoute ses consignes propres.

| Animation | Images | ips | Boucle | Consigne commune |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | debout, le poids sur les deux pieds, bras le long du corps ou tenant l'objet de la tenue ; image 1 : épaules soulevées d'1 px, cheveux qui bougent d'1 px (respiration) ; pieds immobiles |
| `marche` | 6 | 10 | oui | cycle de marche complet (contact, passage, contact de l'autre pied…), bras opposés aux jambes, tête qui monte et descend d'1 à 2 px, jamais plus grande que `repos` |
| `parle` | 2 | 6 | oui | debout comme `repos`, pieds à la même place ; image 0 bouche fermée, image 1 bouche ouverte et petit geste de la main |
| `course` | 5 | 14 | oui | course penchée en avant, grandes foulées, un instant où les deux pieds quittent le sol, bras pliés qui balancent ; la tête jamais plus haute que la hauteur debout |
| `saut` | 4 | 12 | non | 0 élan accroupi, bras en arrière ; 1 détente, bras levés, pieds qui quittent le sol ; 2 au plus haut, genoux repliés (le corps monte dans la case, l'ancre reste au sol) ; 3 réception accroupie |
| `frappe` | 4 | 14 | non | 0 élan, la jambe de frappe en arrière ; 1 pied d'appui planté à côté du ballon ; 2 **frappe** : la jambe de frappe tendue devant, à 20 cm du sol (`coup`) ; 3 accompagnement, bras écartés pour l'équilibre ; **le ballon n'est pas dessiné** (le jeu le pose) |
| `lance` | 4 | 12 | non | lancer à deux mains par-dessus la tête : 0 ballon de cuir (20 cm) tenu à deux mains devant le ventre ; 1 ballon derrière la tête, dos cambré ; 2 **lâcher** : bras tendus en avant au-dessus de la tête, le ballon vient de partir et n'est plus dessiné (`coup`) ; 3 suivi, buste penché |
| `grimpe` | 4 | 8 | oui | grimper à un tronc **non dessiné** : de dos (la vue principale), bras et jambes qui s'agrippent en alternance, le corps qui se hisse ; de profil, le tronc invisible juste à droite du personnage ; de face, comme de dos mais vu de face ; l'ancre est sous le pied le plus bas |
| `assis` | 2 | 2 | oui | assis sur un siège **non dessiné** dont l'assise est à 45 cm (43 px au-dessus de l'ancre) : cuisses horizontales, dos droit, mains sur les genoux ; les petites laissent pendre les pieds ; image 1 : respiration ; l'ancre est au sol sous le milieu de l'assise |
| `lit` | 2 | 2 | oui | assis comme `assis`, un livre ouvert tenu à deux mains ; image 1 : une page qui se soulève, les yeux qui descendent |
| `dort` | 2 | 1 | oui | couché sur le côté sur une surface **non dessinée** (lit, canapé, herbe), la tête à gauche de l'image, genoux un peu repliés, une main sous la joue ; image 1 : respiration (1 px) ; l'ancre au milieu du corps, sur la surface ; **les trois vues reprennent la même image couchée** (recopiée telle quelle) |
| `tombe` | 4 | 10 | non | chute en avant à plat ventre : 0 le pied accroche, buste en avant, bras qui partent ; 1 en l'air, presque à l'horizontale ; 2 impact, à plat ventre, bras écartés ; 3 étalée, la joue contre le sol, les jambes qui retombent (V1 : l'avalanche ; V2 : l'embuscade ratée, le nez rouge) ; ni sang, ni larmes |
| `porte` | 6 | 10 | oui | le cycle de `marche`, en portant l'objet de la planche (dessiné) à deux mains devant soi ou sur l'épaule ; l'objet monte et descend avec le corps |
| `travaille` | 4 | 6 | oui | le geste de métier de la planche, sur place (pieds immobiles), avec l'outil dessiné ; l'objet travaillé (marmite, plafond, table) n'est pas dessiné, sauf s'il tient dans les mains |
| `effondre` | 4 | 8 | non | 0 chancelle, une main sur la poitrine ; 1 un genou à terre ; 2 assis lourdement, le buste qui part en arrière ; 3 étendu au sol, immobile (V1, « Les valeureux… » : Willem s'effondre après le duel) ; ni sang |
| `hanches` | 2 | 2 | oui | debout, les poings sur les hanches, le buste un peu penché en avant, moue sévère ; image 1 : un hochement de tête d'1 px |
| `attaque` | 4 | 14 | non | (cahier n° 1, 3.1) coup d'arme de haut en bas ; `coup` : [1, 2, 3] |
| `etreinte` | 4 | 8 | non | **nom proposé, à confirmer par le moteur** : 0 bras qui s'ouvrent ; 1 elle se penche ; 2 et 3 les bras refermés sur une personne **non dessinée** devant elle (à droite), sourire |

### 4.3 Les petites : planches complémentaires

Tiat, Collon, Pannibal, Lakhesh et Almita jouent pour de vrai (`docs/REFONTE.md`, section 4.2) :
le ballon en équipes rouge et blanche, le chat dans les hautes herbes, l'avalanche contre les
portes, l'escalade interdite du grand arbre, les embuscades, les courses dans le couloir et dans la
boue. Chaque planche `<id>_life` a ces rangées : `repos` (2, recopiée), `course` (5, 14 ips),
`saut` (4, 12), `frappe` (4, 14, `coup` [2]), `lance` (4, 12, `coup` [2]), `grimpe` (4, 8),
`assis` (2, 2), `lit` (2, 2), `dort` (2, 1), `tombe` (4, 10) ; Pannibal a en plus `attaque`.

#### `tiat/tiat_life` : Tiat (prio 1)

Hauteur debout : **106 px** (1,1 m). Joindre `tiat.png`, `tiat_front.png`, `tiat_back.png`. L'une
des plus jeunes, cheveux et yeux vert feuille, blouse blanche et gilet vert sombre ; elle admire
Chtholly et l'imite, s'émerveille de tout, lève le pouce, gonfle les joues, s'étale sur le tapis
(V1 ; V2 ; V3 ; VEX).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante (étalon, ne pas redessiner) |
| `course` | 5, 14 | elle court en agitant un bras en l'air, bouche ouverte d'enthousiasme, gilet qui vole |
| `saut` | 4, 12 | saut de joie, bras levés à l'image 2, comme pour voir par une fenêtre trop haute (V5) |
| `frappe` | 4, 14 | frappe appliquée, langue tirée de concentration, petits poings serrés |
| `lance` | 4, 12 | lancer de toutes ses forces, sur la pointe des pieds à l'image 2 |
| `grimpe` | 4, 8 | grimpe vite et sans peur, les cheveux verts en bataille |
| `assis` | 2, 2 | assise les jambes qui se balancent, mains posées à plat de chaque côté |
| `lit` | 2, 2 | un livre emprunté à Chtholly, tenu très près, les yeux écarquillés (V3) |
| `dort` | 2, 1 | roulée en boule, la bouche entrouverte |
| `tombe` | 4, 10 | s'étale bras en croix, joues gonflées à l'image 3 (V2 : on s'étale sur le plancher, le nez rouge) |

#### `collon/collon_life` : Collon (prio 1)

Hauteur debout : **115 px** (1,2 m). Joindre `collon.png`, `collon_front.png`, `collon_back.png`.
Longs cheveux roses, bandeau rouge, une canine qui dépasse, tunique lacée ; la plus intenable et la
plus bruyante, première à sauter sur les piles, tout en haut de l'arbre une main en visière (V1 ;
V2 ; V5).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `course` | 5, 14 | course de tête brûlée, buste très penché, les longs cheveux à l'horizontale derrière elle |
| `saut` | 4, 12 | saut d'assaut, un bras pointé vers le ciel à l'image 2, poitrine gonflée (V5) |
| `frappe` | 4, 14 | tir puissant et désordonné, la jambe montée très haut à l'image 2 |
| `lance` | 4, 12 | lancer en criant, bouche grande ouverte, canine visible |
| `grimpe` | 4, 8 | grimpe vite, sans regarder en bas ; les cheveux pendent dans le dos |
| `assis` | 2, 2 | assise de travers, un pied replié sous elle, incapable de rester droite |
| `lit` | 2, 2 | livre tenu à bout de bras, l'air de s'ennuyer |
| `dort` | 2, 1 | bras et jambes écartés, bandeau de travers |
| `tombe` | 4, 10 | la première de l'avalanche : chute franche à plat ventre, elle rit à l'image 3 |

#### `pannibal/pannibal_life` : Pannibal (prio 1)

Hauteur debout : **120 px** (1,25 m). Joindre `pannibal.png`, `pannibal_front.png`,
`pannibal_back.png`. Une dizaine d'années, cheveux violet vif qui cachent un œil, petite cape à
capuche, brindille à la bouche, épée de bois ; pince-sans-rire, curieuse, elle renifle, frappe la
balle contre le mur, monte à mi-hauteur de l'arbre (V1 ; V2 ; V5). **L'épée de bois** reste du même
côté que dans la planche existante : en main pour `course`, `saut`, `tombe` et `attaque` ; glissée
à la ceinture pour `frappe`, `lance`, `grimpe`, `lit` ; posée sur les genoux pour `assis` ;
absente pour `dort` ; **jamais sous la ligne des pieds**.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `course` | 5, 14 | course d'éclaireuse, l'épée de bois tenue basse, la cape qui flotte, visage impassible |
| `saut` | 4, 12 | bond d'embuscade, l'épée levée à deux mains à l'image 2 |
| `frappe` | 4, 14 | frappe sèche et précise, sans expression |
| `lance` | 4, 12 | lancer net, brindille toujours à la bouche |
| `grimpe` | 4, 8 | grimpe avec méthode, une prise après l'autre (V5 : elle appelle ça un exercice d'agilité) |
| `assis` | 2, 2 | assise droite, l'épée de bois en travers des genoux, elle triture sa frange à l'image 1 |
| `lit` | 2, 2 | lit sérieusement, un sourcil levé |
| `dort` | 2, 1 | couchée sur le dos d'un côté, la brindille toujours aux lèvres |
| `tombe` | 4, 10 | l'embuscade ratée : elle s'étale, l'épée de bois lui échappe et glisse devant elle |
| `attaque` | 4, 14 | coup d'épée de bois de haut en bas, poussé d'un cri de guerre, avec une vraie maîtrise ; `coup` : [1, 2, 3] (V1, « L'Homme sans Marque » : l'embuscade au marais) |

#### `lakhesh/lakhesh_life` : Lakhesh (prio 1)

Hauteur debout : **115 px** (1,2 m). Joindre `lakhesh.png`, `lakhesh_front.png`, `lakhesh_back.png`.
Cheveux pêche, **petite couette du côté gauche de sa tête** (à droite de l'image de face, à gauche
de l'image de dos, derrière la tête de profil), gilet brun clouté ; polie, attentionnée, craintive,
elle essaie de calmer les autres, pleure facilement, tremble sur une branche basse (V1 ; V5).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `course` | 5, 14 | course un peu raide, mains serrées devant la poitrine, pour rattraper les autres |
| `saut` | 4, 12 | petit saut prudent, réception sur la pointe des pieds |
| `frappe` | 4, 14 | frappe appliquée mais maladroite, les bras qui moulinent pour l'équilibre |
| `lance` | 4, 12 | lancer sérieux, sourcils froncés |
| `grimpe` | 4, 8 | grimpe en hésitant : à l'image 2, elle s'arrête et regarde en bas (V5 : tremblante sur une branche basse) |
| `assis` | 2, 2 | assise bien droite, mains jointes sur les genoux |
| `lit` | 2, 2 | absorbée dans un roman, les joues un peu roses |
| `dort` | 2, 1 | sagement couchée, les mains sous la joue |
| `tombe` | 4, 10 | se recroqueville en tombant, les yeux fermés |

#### `almita/almita_life` : Almita (prio 1)

Hauteur debout : **91 px** (0,95 m). Joindre `almita.png`, `almita_front.png`, `almita_back.png`.
Toute petite, cheveux crépus jaune citron en désordre, robe simple ; elle répète ce que disent les
grandes, éternue, oublie vite ses frayeurs (V3).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `course` | 5, 14 | petites jambes très rapides, foulées courtes, bras écartés |
| `saut` | 4, 12 | saut à pieds joints, les cheveux crépus qui rebondissent |
| `frappe` | 4, 14 | elle frappe trop tôt, le pied passe à côté, elle chancelle à l'image 3 |
| `lance` | 4, 12 | lancer à deux mains qui part à peine, tout le corps penché en avant |
| `grimpe` | 4, 8 | grimpe en s'aidant des genoux, joues gonflées d'effort |
| `assis` | 2, 2 | assise, les pieds loin du sol, qui pendent |
| `lit` | 2, 2 | un grand livre d'images qui lui cache le buste |
| `dort` | 2, 1 | couchée en étoile, une main sur le ventre |
| `tombe` | 4, 10 | culbute en avant, se retrouve assise à l'image 3, étonnée |

### 4.4 Les aînées à la maison : planches de tenue `<id>_home`

À l'entrepôt, les fées ne portent pas leurs épées : les Carillons dorment dans la salle des armes
(V1, « Entrepôt de fées »). Les planches livrées de Chtholly, Ithea et Nephren tiennent leur épée
dans chaque image ; leur planche `_home` est la **même tenue sans l'épée**, mains libres, pour la
vie de tous les jours. Quand le jeu passe de l'une à l'autre est à confirmer par le moteur
(lots E4 et E6).

#### `chtholly/chtholly_home` : Chtholly à la maison (prio 1)

Hauteur debout : **144 px** (1,5 m) **dans les trois vues** (la face livrée mesurait 130 px).
Joindre `chtholly.png`, `chtholly_front.png`, `chtholly_back.png`. Quinze ans, l'aînée sévère :
longs cheveux bleus et deux petites couettes hautes, exactement comme la planche livrée ; uniforme
bleu marine, broche d'argent à pierre bleue en goutte sur la poitrine, **sans Seniorious**. Elle
renifle quand elle est émue, serre sa broche, se met les poings sur les hanches pour gronder (V1 ;
VEX).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout droite, mains jointes devant elle, posture d'aînée ; à l'image 1, la main droite effleure la broche |
| `marche` | 6, 10 | pas vifs et nets (elle trottine un peu) |
| `parle` | 2, 6 | petit geste de l'index, sourcils légèrement froncés |
| `course` | 5, 14 | course rapide, couettes qui flottent |
| `frappe` | 4, 14 | frappe franche et précise (elle joue au ballon avec les petites) |
| `assis` | 2, 2 | assise sur le rebord de la banquette, dos droit, mains sur les genoux |
| `lit` | 2, 2 | lit à la fenêtre, le livre à hauteur de poitrine, le regard qui s'échappe vers le dehors à l'image 1 (V1, « Les filles de l'entrepôt ») |
| `dort` | 2, 1 | couchée sur le côté, une main sur la broche |
| `hanches` | 2, 2 | poings sur les hanches, joues un peu gonflées : la grande sœur qui gronde (V3 ; VEX) |

#### `ithea/ithea_home` : Ithea à la maison (prio 1)

Hauteur debout : **139 px** (1,45 m). Joindre `ithea.png`, `ithea_front.png`, `ithea_back.png`.
Quatorze ans ; cheveux orange ébouriffés, deux mèches pointues, petites nattes à perles bleues,
regard félin ambré, écharpe orange, veste crème à garnitures vertes sur robe brun-rouge, comme la
planche livrée, **sans Valgulious**. Elle rit en « nya-ha », s'étire, enlace par derrière, balance
les pieds sur sa chaise, pose le menton dans la paume, lit des romans d'amour (V1 ; V2 ; V3 ; VEX).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | hanchée, les mains croisées derrière la tête, sourire en coin |
| `marche` | 6, 10 | démarche nonchalante, un peu chaloupée |
| `parle` | 2, 6 | rit, les yeux plissés, une main levée |
| `course` | 5, 14 | course souple, l'écharpe qui flotte derrière elle |
| `frappe` | 4, 14 | frappe nonchalante mais efficace |
| `assis` | 2, 2 | assise, balançant un pied à l'image 1, le menton dans la paume |
| `lit` | 2, 2 | un petit roman d'amour à couverture rose (sans titre), sourire rêveur |
| `dort` | 2, 1 | affalée sur le côté, l'écharpe en oreiller |

#### `nephren/nephren_home` : Nephren à la maison (prio 1)

Hauteur debout : **125 px** (1,3 m). Joindre `nephren.png`, `nephren_front.png`,
`nephren_back.png`. Treize ans, minuscule et impassible ; cheveux gris cendré à reflets lavande en
deux couettes ondulées à rubans noirs, yeux gris anthracite, tunique violette à capuche et frise de
triangles blancs, son livre rouge à la main, **sans Insania**. Elle lit sans cesse, impose le
silence avec un papier roulé, penche la tête d'un côté puis de l'autre, s'endort sur le canapé ou
sur les genoux des autres (V1 ; V3 ; V4).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, le livre rouge serré contre la poitrine ; à l'image 1, la tête penche d'un côté |
| `marche` | 6, 10 | petits pas réguliers, le livre contre elle |
| `parle` | 2, 6 | presque rien ne bouge : la bouche, et le papier roulé levé d'un doigt |
| `course` | 5, 14 | course courte et raide, visage inchangé |
| `frappe` | 4, 14 | frappe exacte et sans élan, comme on résout un problème |
| `assis` | 2, 2 | assise, les pieds loin du sol, le livre fermé sur les genoux |
| `lit` | 2, 2 | lit son livre rouge, les yeux à demi fermés |
| `dort` | 2, 1 | endormie en chien de fusil, le livre serré contre elle (V4) |

### 4.5 Willem

Environ dix-huit ans, grand et mince, cheveux noirs en bataille, yeux noirs, sourire fatigué ;
uniforme militaire bleu nuit croisé à boutons dorés, un peu trop étroit (V1). Il se gratte la tête,
donne des pichenettes sur le front, pose la main sur la tête des petites (V1 ; V3). Ses planches
font **168 px** de hauteur debout (1,75 m). Joindre `willem.png`, `willem_front.png`,
`willem_back.png`. Dans la planche livrée, il tient une épée : aucune des planches ci-dessous n'en
a, sauf mention.

#### `willem/willem_home` : Willem à la maison (prio 1)

Uniforme bleu nuit sans arme, col un peu ouvert, manches parfois retroussées.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, une main qui se gratte la nuque à l'image 1, air un peu perdu |
| `marche` | 6, 10 | pas longs et tranquilles, mains dans le dos |
| `parle` | 2, 6 | petit geste de la main ouverte, sourire fatigué |
| `course` | 5, 14 | il court après le ballon avec les petites (V1, « Les filles de l'entrepôt ») |
| `assis` | 2, 2 | assis au rebord de la fenêtre, une jambe pendante, le regard dehors (V1, « Directeur en carton ») |
| `lit` | 2, 2 | lit à voix basse un grand livre d'images tenu ouvert vers l'extérieur (V1 : le livre sur les emnetwiht) |
| `dort` | 2, 1 | endormi sur le côté, un bras replié sous la tête (V1 ; V3 : sur le canapé des archives) |
| `porte` | 6, 10 | il rentre du marché du matin avec un grand sac de toile à l'épaule (farine, œufs, beurre qui dépassent) (V3, « Je suis à la maison ») |
| `effondre` | 4, 8 | à bout de forces après le duel : il chancelle, tombe assis, puis s'étend (V1, « Les valeureux… ») ; ni sang |

#### `willem/willem_cook` : Willem en cuisine (prio 1)

Tablier de toile blanche par-dessus l'uniforme, mouchoir noué sur la tête, manches retroussées (V1,
« Directeur en carton » ; V3, « Je suis à la maison »).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout en tablier, un torchon sur l'épaule |
| `marche` | 6, 10 | marche affairée |
| `parle` | 2, 6 | parle en tenant une cuillère de bois levée |
| `travaille` | 4, 6 | bat au fouet dans un grand bol tenu au creux du bras gauche (bol et fouet dessinés) |
| `porte` | 6, 10 | porte à deux mains un plateau de coupelles de flan au caramel (le dessert spécial, V1) |

#### `willem/willem_repair` : Willem répare (prio 2)

Uniforme, manches retroussées, un clou entre les dents (V4, transposé).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, marteau à la main, l'autre main sur la hanche |
| `travaille` | 4, 6 | martèle au-dessus de sa tête, bras levé, comme pour clouer une planche au plafond qui fuit (V2 ; V3) |
| `porte` | 6, 10 | marche avec trois planches sur l'épaule et le marteau à la ceinture |

#### `willem/willem_coat` : Willem en pardessus (prio 1)

Long pardessus usé gris-brun à capuche par-dessus l'uniforme, col relevé ; la nuit de son arrivée,
dans le vent qui hurle (V1, « L'Homme sans Marque »), le matin où il part en ville (VEX,
« L'homme-chat »), les jours de pluie.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, mains dans les poches, le bas du manteau qui claque au vent à l'image 1 |
| `marche` | 6, 10 | marche contre le vent, épaules rentrées |
| `parle` | 2, 6 | parle en remontant son col |
| `course` | 5, 14 | court, le manteau qui flotte derrière lui |

### 4.6 Nygglatho

Une troll à l'air de jeune femme, une tête de plus que tout le monde ; longs cheveux rose saumon,
yeux vert printanier, chemisier vert vif, tablier blanc, coiffe blanche à volants (V1). Elle joint
les mains près du visage, se met les poings sur les hanches, sourit comme une fleur, menace de
manger les petites, porte le plateau du thé et le panier de linge (V1 ; V2 ; V5). Ses planches
font **178 px** de hauteur debout (1,85 m). Joindre `nygglatho.png`, `nygglatho_front.png`,
`nygglatho_back.png`.

#### `nygglatho/nygglatho_life` : Nygglatho, planche complémentaire (prio 1)

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `course` | 5, 14 | elle court après les petites, une main qui retient sa coiffe (V5) |
| `porte` | 6, 10 | marche en portant à deux mains un grand panier tressé plein de draps (V2 ; VEX, « L'homme-chat ») |
| `hanches` | 2, 2 | poings sur les hanches, sourire terrible : celui qui fait fuir les petites (V1 ; V5) |
| `assis` | 2, 2 | assise très droite, mains jointes sur les genoux |
| `lit` | 2, 2 | feuillette un registre, un doigt sur la joue (V5) |
| `dort` | 2, 1 | couchée sur le côté, une main sous la joue |
| `etreinte` | 4, 8 | **nom proposé, à confirmer par le moteur** : l'étreinte « guimauve », douce mais impossible à fuir (V5, « La fin imminente ») |

#### `nygglatho/nygglatho_tea` : le thé (prio 1)

Même tenue. Elle sert le thé, verse le lait et tourne la cuillère (VEX, « Cinq cents ans »).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, une théière de porcelaine fleurie à la main |
| `parle` | 2, 6 | parle en penchant la tête, les mains jointes près du visage |
| `travaille` | 4, 6 | verse le thé de la théière (dessinée) dans une tasse tenue de l'autre main, puis tourne la cuillère |
| `porte` | 6, 10 | marche avec un plateau : théière, tasses, pot à lait, un cheese-cake |

#### `nygglatho/nygglatho_labcoat` : à l'infirmerie (prio 2)

Longue blouse blanche de laboratoire par-dessus ses vêtements, cheveux attachés (V1 ; V3).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, un tableau de notes à pince contre la poitrine |
| `marche` | 6, 10 | marche rapide de soignante |
| `parle` | 2, 6 | parle, un crayon levé |
| `travaille` | 4, 6 | examine une patiente non dessinée devant elle : une petite lumière tenue vers ses yeux, puis des notes sur le tableau (V3, « Je suis à la maison ») |

#### `nygglatho/nygglatho_laundry` : le linge (prio 2)

Même tenue que la planche livrée.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `travaille` | 4, 6 | décroche un drap d'une corde (bras levés, corde non dessinée), le plie et le laisse tomber dans un panier à ses pieds (panier dessiné) (V2 : on rentre les draps avant l'averse) |

### 4.7 Entraînement au bâton (format à confirmer par le moteur, lot E8)

Dans la clairière derrière l'entrepôt, Willem entraîne les trois aînées avec des bâtons ramassés par
terre : bloquer, dévier, parer, esquiver sans casser le rythme, puis à trois contre un ; les
genoux lâchent (VEX, « Chtholly Nota Seniorious » ; « Cinq cents ans »). Planches de tenue à la
hauteur debout de chacun, avec un **bâton de bois brut de 1,2 m** à la place de l'arme, tenu du même
côté que l'épée dans la planche livrée. Rangées : `repos` (2, 2), `marche` (6, 10), `course`
(5, 14), `attaque` (4, 14, `coup` [1, 2, 3] : coup de bâton), `pare` (**nom proposé** : 3 images,
12 ips, non : 0 garde, 1 le bâton tenu à deux mains en travers pour bloquer, 2 retour en garde),
`degats` (1, 1 : touché, recule), `mort` (1, 1 : assise par terre, à bout de souffle, sans
blessure). **Ne les commande qu'après accord du lot E8.**

| Prio | Planche | Hauteur debout | Consigne propre |
| --- | --- | --- | --- |
| 3 | `chtholly/chtholly_stick` | 144 px | Chtholly en tenue d'exercice : sa tenue de `_home` sans la veste, manches retroussées, cheveux attachés ; concentrée, rageuse quand elle rate (VEX, « Des émotions sans nom ») |
| 3 | `ithea/ithea_stick` | 139 px | Ithea, écharpe nouée serré, sourire ; elle s'allonge par terre après l'effort (son `mort`) |
| 3 | `nephren/nephren_stick` | 125 px | Nephren, couettes nouées en arrière, visage impassible même quand elle encaisse |
| 3 | `willem/willem_stick` | 168 px | Willem en tenue d'entraînement ample et terne (chemise de toile, pantalon serré aux chevilles), bâton sous le bras au `repos` ; il pare et contre « comme un serpent » sous des angles désagréables (VEX) ; son `mort` : assis, essoufflé, il se gratte la tête |

### 4.8 Les fées sans planche

Près de trente fées vivent à l'entrepôt, toutes des filles de 7 à 15 ans pour la plupart, aux
cheveux de couleurs vives et naturelles (V1, « Directeur en carton »). Les tenues sont celles d'un
orphelinat de campagne : robes simples, blouses, gilets tricotés, tabliers, salopettes, tout reprisé
et un peu trop grand ou trop petit, bottines. **Aucune fée générique n'a les cheveux rouges** (le
rouge est la couleur de l'empiètement, V3) ni les couleurs exactes des fées nommées (céruléen,
orange, gris cendré, vert feuille, rose, violet, pêche, jaune citron, vermillon, indigo).

Rangées des petites (planche neuve) : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `course`
(5, 14), `saut` (4, 12), `frappe` (4, 14, [2]), `lance` (4, 12, [2]), `grimpe` (4, 8), `assis`
(2, 2), `lit` (2, 2), `dort` (2, 1), `tombe` (4, 10). Rangées des grandes (13 à 15 ans) : `repos`,
`marche`, `parle`, `course`, `frappe`, `assis`, `lit`, `dort`.

#### `kana/kana` : Kana (prio 2)

Hauteur debout : **110 px** (1,15 m). Nommée dans la tour de fées (VEX, « Le cas de la fée aux
cheveux gris ») ; plus tard parieuse qui chipe le butin (V5, épilogue). Apparence **(original)** :
une dizaine d'années, cheveux turquoise vif coupés court en épis, taches de rousseur, sourire de
chipeuse ; salopette de toile brune rapiécée sur une chemise jaune moutarde, poches pleines,
bottines usées. Rangées des petites ; consignes propres : `repos` mains dans les poches, l'œil
malin ; `parle` un clin d'œil ; `course` elle file en serrant quelque chose contre elle ; `saut`
elle saute sur la pile (tour de fées) ; `lit` elle cache une friandise derrière le livre ;
`tombe` elle rit en tombant. Portrait 256 × 256 (section 4.13).

#### `giniette/giniette` : Giniette (prio 2)

Hauteur debout : **101 px** (1,05 m). Nommée dans la tour de fées (VEX). Apparence **(original)** :
huit ans environ, cheveux miel doré en deux nattes nouées de rubans verts, grands yeux bruns ; robe
chasuble vert bouteille sur une chemise crème, tablier à poches, chaussettes qui tombent. Rangées
des petites ; consignes propres : `repos` timide, les mains derrière le dos ; `parle` elle tortille
une natte ; `course` elle suit les autres en retard ; `saut` elle saute en dernier sur la pile ;
`grimpe` prudente ; `dort` serrée contre une peluche dessinée. Portrait 256 × 256.

#### Les douze fées génériques `fairy_01` à `fairy_12`

Dossier `assets/characters/fairy_NN/`. Les joueurs pourront les renommer ; leurs tenues varient pour
qu'une foule de dix ne montre jamais deux fois la même. Consignes propres communes : elles jouent
avec entrain ; chacune garde son accessoire (ruban, bandage, livre) du même côté dans toutes les
images.

| Prio | Planche | Âge, hauteur debout | Rangées | Apparence (original) |
| --- | --- | --- | --- | --- |
| 1 | `fairy_01/fairy_01` | 7 ans, 96 px (1 m) | petites | cheveux bleu glacier en carré court à frange, robe chasuble grise à col blanc, chaussettes hautes |
| 1 | `fairy_02/fairy_02` | 8 ans, 101 px (1,05 m) | petites | cheveux corail bouclés en boule, salopette de toile bleu passé aux genoux rapiécés |
| 1 | `fairy_03/fairy_03` | 8 ans, 101 px | petites | cheveux vert menthe en deux couettes basses, gilet tricoté jaune moutarde, jupe brune |
| 1 | `fairy_04/fairy_04` | 9 ans, 106 px (1,1 m) | petites | cheveux lilas longs et raides, robe prune à col claudine, tablier blanc |
| 1 | `fairy_05/fairy_05` | 9 ans, 106 px | petites | cheveux bleu pervenche ondulés, blouse crème, jupe-culotte vert sapin à bretelles |
| 1 | `fairy_06/fairy_06` | 10 ans, 110 px (1,15 m) | petites | cheveux framboise courts ébouriffés, tunique ocre ceinturée, jambières, un bandage au genou gauche |
| 2 | `fairy_07/fairy_07` | 10 ans, 110 px | petites | cheveux vert d'eau tressés en couronne, robe de lainage bleu canard, châle croisé |
| 2 | `fairy_08/fairy_08` | 11 ans, 115 px (1,2 m) | petites | cheveux ambre cuivré en queue de cheval, chemise à carreaux trop grande, pantalon roulé aux chevilles |
| 2 | `fairy_09/fairy_09` | 12 ans, 120 px (1,25 m) | petites | cheveux jaune paille lisses au carré, robe-tablier rayée bleu et blanc |
| 2 | `fairy_10/fairy_10` | 13 ans, 130 px (1,35 m) | grandes | cheveux rose poudré longs noués d'un ruban, robe de lainage gris-mauve, gilet |
| 2 | `fairy_11/fairy_11` | 14 ans, 134 px (1,4 m) | grandes | cheveux vert mousse mi-longs à frange, blouse et longue jupe brune, un livre sous le bras gauche |
| 2 | `fairy_12/fairy_12` | 15 ans, 139 px (1,45 m) | grandes | cheveux aigue-marine argentée en chignon bas, tablier de cuisine (la cuisinière du jour), manches retroussées |

### 4.9 Les pyjamas

Le soir et le matin : les petites couchées tôt, les sorties dans le couloir en se frottant les yeux
(V2, épilogue), la toilette du visage à l'eau glacée que Collon refuse (VEX, « L'homme-chat »),
Chtholly en pyjama et en gilet, les cheveux en bataille, quand Willem frappe à sa porte (VEX,
« Chtholly Nota Seniorious »). Planches de tenue `<id>_pajamas`, à la hauteur debout du personnage,
pieds nus ou en chaussons, cheveux défaits.

Rangées des petites : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `course` (5, 14), `tombe`
(4, 10), `assis` (2, 2), `dort` (2, 1), `travaille` (4, 6 : **la toilette du matin**, même nom,
autre geste : elle s'asperge le visage d'eau au-dessus d'une cuvette non dessinée, puis s'essuie
d'une serviette dessinée). Rangées des aînées : `repos`, `marche`, `parle`, `assis`, `dort`,
`travaille` (toilette).

| Prio | Planche | Hauteur debout | Rangées | Pyjama et consigne propre |
| --- | --- | --- | --- | --- |
| 1 | `tiat/tiat_pajamas` | 106 px | petites | chemise de nuit vert pâle, chaussons ; elle court partout avec une serviette pour sécher les cheveux des autres (V3) |
| 1 | `collon/collon_pajamas` | 115 px | petites | pyjama rose à rayures, sans bandeau, cheveux défaits ; sa `travaille` : elle trempe un doigt dans l'eau, recule en grimaçant et refuse (VEX) |
| 1 | `pannibal/pannibal_pajamas` | 120 px | petites | chemise de nuit violet sombre trop longue, sans cape ni épée, mèche toujours sur l'œil |
| 1 | `lakhesh/lakhesh_pajamas` | 115 px | petites | chemise de nuit pêche à petits volants, couette du côté gauche de sa tête |
| 2 | `almita/almita_pajamas` | 91 px | petites | combinaison de nuit en flanelle jaune pâle, bonnet de nuit qui tombe sur un œil |
| 2 | `chtholly/chtholly_pajamas` | 144 px | aînées | pyjama bleu ciel et gilet de laine gris passé par-dessus, cheveux en bataille, sans couettes (VEX) |
| 2 | `ithea/ithea_pajamas` | 139 px | aînées | chemise de nuit crème, cheveux lâchés, bâille à l'image 1 du `repos` |
| 2 | `nephren/nephren_pajamas` | 125 px | aînées | pyjama gris lavande trop grand, manches qui couvrent les mains, le livre rouge sous le bras |
| 3 | `fairy_02/fairy_02_pajamas` | 101 px | petites | la fée `fairy_02` en chemise de nuit blanche à pois bleus |
| 3 | `fairy_06/fairy_06_pajamas` | 110 px | petites | la fée `fairy_06` en pyjama de flanelle à carreaux verts |

### 4.10 Les tenues de pluie

Les averses sont soudaines : le vent devient humide, la pluie tombe comme un seau renversé, il fait
nuit en plein jour, et après la pluie le terrain est boueux (V2, « De ce côté-ci de l'écran » ;
« L'écoulement du temps depuis lors »). Pèlerines de toile cirée à capuche, bottes de cuir graissé
(rien de plastique ni de caoutchouc brillant). Willem met son pardessus (`willem_coat`, 4.5).
Rangées : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `course` (5, 14) ; les petites ont en
plus `saut` (4, 12 : **à pieds joints dans une flaque**, original).

| Prio | Planche | Hauteur debout | Consigne propre |
| --- | --- | --- | --- |
| 2 | `chtholly/chtholly_rain` | 144 px | pèlerine bleu marine à capuche relevée, quelques mèches bleues mouillées qui dépassent ; pas d'épée |
| 2 | `tiat/tiat_rain` | 106 px | pèlerine verte trop grande, capuche qui lui tombe sur les yeux |
| 2 | `collon/collon_rain` | 115 px | pèlerine rouge, capuche rabattue en arrière exprès, cheveux trempés |
| 2 | `pannibal/pannibal_rain` | 120 px | pèlerine violette, la brindille à la bouche, l'épée de bois sous la pèlerine (seule la poignée dépasse, du même côté que d'habitude) |
| 2 | `lakhesh/lakhesh_rain` | 115 px | pèlerine ocre jaune bien boutonnée, elle tient le bord de sa capuche à deux mains |
| 2 | `almita/almita_rain` | 91 px | pèlerine jaune citron jusqu'aux chevilles, grosses bottes |
| 2 | `nygglatho/nygglatho_rain` | 178 px | châle de laine sur les épaules et grand parapluie de toile noire à manche de bois tenu au-dessus d'elle (rangées sans `course`, sans `saut`) |

### 4.11 Les hommes-bêtes : métiers et passants

Le village est campagnard : presque personne n'y porte de beaux habits (VEX, « Cinq cents ans ») ;
la ville est faite de commerces tenus par des hommes-bêtes et des demi-bêtes (V2 ; V3). Ils
craignent l'entrepôt à cause de Nygglatho et ne montrent aucune hostilité envers les fées (V1 ;
V5). Chaque espèce a sa silhouette : hommes-chiens et hommes-chats à museau, oreilles et queue,
lézards massifs à écailles et longue queue, ours larges et lents, hommes-oiseaux à bec et plumes
(bras humains, pas d'ailes), hommes-grenouilles trapus à grande bouche. Vêtements de travail de
campagne : chemises de lin, gilets, tabliers, fichus, bottes, chapeaux de feutre ou de paille.

Rangées des **passants** : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `course` (5, 14),
`assis` (2, 2). Rangées des **métiers** : celles des passants, plus `travaille` (4, 6, leur geste)
et, quand la ligne le dit, `porte` (6, 10, leur objet). Une queue reste du même côté dans toutes
les images et ne passe jamais sous la ligne des pieds.

| Prio | Planche | Hauteur debout | Qui | Apparence et consignes propres |
| --- | --- | --- | --- | --- |
| 2 | `cafe_owner/cafe_owner` | 187 px (1,95 m) | patron du café du village (VEX : le serveur offre les jus en cachette du patron) | homme-ours brun bedonnant, chemise aux manches retroussées, long tablier, torchon sur l'épaule ; `travaille` : il essuie une chope au torchon ; `porte` : un plateau de chopes |
| 2 | `drinker_dog/drinker_dog` | 163 px (1,7 m) | buveur du café, le soir (VEX : une tablée éméchée rit fort) | homme-chien hirsute gris, chemise ouverte, gilet déboutonné, une chope de bois dans la même main dans toutes les images ; `parle` : rire bruyant, chope levée ; `assis` : affalé |
| 2 | `drinker_cat/drinker_cat` | 158 px (1,65 m) | autre buveur | homme-chat roux balourd, casquette de travers, veste de velours râpée ; `assis` : il chante, une patte levée |
| 3 | `butcher/butcher` | 173 px (1,8 m) | boucher de la ville (V2) | homme-chien massif à tête de dogue, tablier de cuir, avant-bras épais ; `travaille` : il tranche au couperet sur un billot non dessiné (viande déjà parée, aucune bête entière, aucun sang) ; `porte` : un jambon emballé de papier sur l'épaule |
| 3 | `watchmaker/watchmaker` | 149 px (1,55 m) | horloger (V2) | vieil homme-oiseau à tête de chouette, plumes grises, lorgnon et loupe vissée à l'œil, gilet brun ; `travaille` : il règle un petit mécanisme à la pince, penché |
| 3 | `bookseller/bookseller` | 144 px (1,5 m) | libraire (V2 ; V3) | vieille femme-chatte tigrée, lunettes au bout du museau, châle, cardigan ; `travaille` : elle range des livres sur une étagère haute ; `porte` : une pile de livres ficelés (les commandes de l'entrepôt) |
| 3 | `apothecary/apothecary` | 134 px (1,4 m) | apothicaire (déduction : Nygglatho va chercher des médicaments en ville, V3) | homme-grenouille trapu vert olive, petites lunettes rondes, blouse vert sombre ; `travaille` : il pile au mortier (mortier et pilon dessinés) |
| 3 | `cafe_town_waiter/cafe_town_waiter` | 163 px (1,7 m) | serveur du café habituel de la ville, terrifié par une troll et un lézard géant (V3, « Le grand et jeune lézard ») | jeune demi-bête : visage presque humain, oreilles et queue de chien beige, mince, gilet noir, long tablier ; `travaille` : il pose une tasse d'une main tremblante ; `porte` : un plateau |
| 3 | `projectionist/projectionist` | 168 px (1,75 m) | projectionniste de la salle de projection (V2) | homme-lézard maigre aux écailles brun-vert, visière de toile, gilet à manchettes ; `travaille` : il tourne la manivelle d'un appareil non dessiné |
| 3 | `milliner/milliner` | 154 px (1,6 m) | marchande d'accessoires (V2) | femme-oiseau au plumage gris-bleu et à petite crête, robe simple et soignée, un chapeau à plume ; `travaille` : elle noue un ruban sur un chapeau tenu dans ses mains |
| 3 | `market_farmer/market_farmer` | 154 px (1,6 m) | marchande du marché du matin (V3 : farine, beurre, œufs, lait) | femme-chienne à longues oreilles d'épagneul, fichu, tablier, sabots ; `travaille` : elle pèse des œufs dans une petite balance tenue à la main ; `porte` : un cageot de légumes |
| 3 | `market_honey/market_honey` | 163 px (1,7 m) | marchand de miel et de noix (V3) | homme-lézard trapu aux écailles vert-brun, gilet de cuir, chapeau de paille ; `porte` : une caisse de pots de miel |
| 2 | `porter/porter` | 192 px (2 m) | docker de l'aire-port (V2 : les charrettes de sacs qui filent) | homme-lézard costaud gris-vert, chemise sans manches de toile épaisse, sangle, gants de cuir ; `porte` : un gros sac sur l'épaule ; `travaille` : il pousse une charrette non dessinée |
| 3 | `villager_dog_m/villager_dog_m` | 168 px (1,75 m) | passant | homme-chien fermier brun et blanc, chemise de lin, gilet, pantalon à bretelles, bâton de marche |
| 3 | `villager_dog_f/villager_dog_f` | 154 px (1,6 m) | passante | femme-chienne au pelage roux, robe de travail, châle, panier au bras (dessiné, même côté partout) |
| 3 | `villager_cat_m/villager_cat_m` | 158 px (1,65 m) | passant | homme-chat noir aux yeux jaunes, veste de velours râpée, casquette |
| 3 | `villager_cat_f/villager_cat_f` | 149 px (1,55 m) | passante | femme-chatte tricolore, robe à fleurs passées, tablier |
| 3 | `villager_lizard_m/villager_lizard_m` | 182 px (1,9 m) | passant | homme-lézard aux écailles ocre, blouse de charretier, chapeau de feutre |
| 3 | `villager_lizard_f/villager_lizard_f` | 173 px (1,8 m) | passante | femme-lézard aux écailles vert pâle, robe longue, foulard noué sur la tête |
| 3 | `villager_bear_m/villager_bear_m` | 192 px (2 m) | passant | homme-ours bûcheron, chemise à carreaux, hache au manche posée sur l'épaule (même côté partout) |
| 3 | `villager_bear_f/villager_bear_f` | 182 px (1,9 m) | passante | femme-ourse, tablier, manches retroussées, foulard |
| 3 | `villager_bird_m/villager_bird_m` | 154 px (1,6 m) | passant | homme-oiseau à tête de corneille, veste sombre, sacoche de cuir en bandoulière (le facteur, original) |
| 3 | `villager_bird_f/villager_bird_f` | 149 px (1,55 m) | passante | femme-oiseau à tête de pie, robe noire et blanche, petit chapeau |
| 3 | `villager_frog_m/villager_frog_m` | 134 px (1,4 m) | passant | homme-grenouille pêcheur des marais, ciré olive, nasse d'osier au dos |
| 3 | `villager_frog_f/villager_frog_f` | 130 px (1,35 m) | passante | femme-grenouille, robe verte, panier de cresson |

### 4.12 Les visiteurs

Les gens élégants viennent toujours d'ailleurs, le plus souvent des marchands de grandes compagnies
(VEX, « Cinq cents ans ») ; les lézards de la Garde ailée débarquent au port (V1, « Entrepôt de
fées »). Rangées : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `assis` (2, 2) pour les
marchands ; `repos`, `marche`, `parle`, `porte` (6, 10) pour la Garde.

| Prio | Planche | Hauteur debout | Apparence et consignes propres |
| --- | --- | --- | --- |
| 3 | `merchant_cat/merchant_cat` | 163 px (1,7 m) | marchand homme-chat au pelage gris argenté lustré, costume trois pièces bleu sombre, chapeau melon, canne à pommeau (même côté partout), sacoche de cuir ; poli et pressé |
| 3 | `merchant_lizard/merchant_lizard` | 178 px (1,85 m) | marchand reptilien aux écailles bleu-vert, redingote bordeaux, gilet brodé, lorgnon, registre sous le bras |
| 2 | `garde_soldier/garde_soldier` | 211 px (2,2 m) | soldat lézard de la Garde ailée, écailles gris-vert, uniforme bleu nuit à liserés rouges (#AE4A3E), aile stylisée brodée sur l'épaule (sans texte), ceinturon, sabre court au fourreau ; aucune arme à feu ; `porte` : une caisse ferrée |
| 2 | `garde_porter/garde_porter` | 202 px (2,1 m) | lézard de la Garde en tenue de bord (veste courte, gants) ; `porte` : deux grandes épées emmaillotées de tissu blanc sur l'épaule (V1 : les épées qu'on rapporte du combat) |

### 4.13 Portraits

`assets/characters/<id>/<id>_portrait.png`, **256 × 256**, buste de la tête aux épaules, visage de
trois quarts tourné vers la droite, fond transparent, même rendu que les portraits livrés
(`assets/characters/tiat/tiat_portrait.png`).

| Prio | Fichier | Consigne à coller |
| --- | --- | --- |
| 2 | `assets/characters/kana/kana_portrait.png` | Kana (4.8) : cheveux turquoise en épis, taches de rousseur, sourire de chipeuse, col de la chemise jaune moutarde |
| 2 | `assets/characters/giniette/giniette_portrait.png` | Giniette (4.8) : nattes miel dorées à rubans verts, grands yeux bruns, timide |

## 5. Lot K : le village et la ville

### 5.1 Rappel du format (à coller avec le lot)

Chaque ligne donne le chemin complet du fichier (`assets/hd2d/…`). Genres :
- **façade** (`buildings/<nom>.png`) : élévation de la face sud, sans perspective, fond
  transparent, mur collé aux bords gauche, droit et bas ; type `long` (faîtage parallèle à la
  façade) : l'image s'arrête à l'égout du toit, bordure du toit comprise (10 à 20 cm), et mesure
  largeur × hauteur du mur ; type `pignon` (faîtage qui part vers le fond) : l'image va jusqu'au
  faîtage avec le triangle du pignon, transparente de part et d'autre, et mesure largeur ×
  faîte ;
- **flanc** (`buildings/<nom>_side.png`) : le mur est en élévation, le côté gauche de l'image à
  l'angle de la façade ; pignon (pour un bâtiment `long`) ou mur gouttereau (pour un `pignon`) ;
  **modelé doux et symétrique**, rien qui ne supporte d'être retourné (le jeu le plaque aussi sur
  le flanc ouest) ; l'avancée du toit ne descend jamais sous le haut du mur ;
- **matière de volume** (`buildings/materials/<nom>.png`) : 192 × 192 (2 × 2 m), opaque, sans
  raccord sur les quatre bords, de face (murs) ou dans le sens de la pente (toits : rangées
  parallèles au bas de l'image) ;
- **panneau** (`props/<nom>.png`) : objet debout vu de face, légèrement plongeant, fond
  transparent, collé au bord bas et centré ;
- **lisière** : pan de 16 m de large (1536 px), bords gauche et droit qui s'enchaînent, bas collé
  au sol sur toute la largeur ;
- **intérieurs** (`interior/…`) : mêmes genres qu'au lot I (sol 384 × 384, mur 384 × 288 de face
  avec plinthe et corniche, porte, fenêtre et élément de mur posés à la hauteur donnée, meuble de
  face légèrement plongeant collé au bord bas, objet posé sur un meuble avec son ancre sur le
  plateau) ;
- **décalque** (`decals/`) : vu strictement de dessus, fond transparent, ancre au centre ; un
  tapis a un bord plein (rectangle aux coins usés, franges) ;
- **bande animée** (`anim/`) : `n` images côte à côte, chacune de la taille donnée, sans marge,
  boucle sans saut, seul ce qui bouge change ;
- **lointain** (`sky/`) : à 48 px/m, adouci et violacé par la distance, raccord à gauche et à
  droite quand la ligne le dit.

Les fenêtres des **nouvelles façades** sont **éteintes** : vitres sombres bleutées avec un reflet
clair ; le jeu les allume la nuit avec les vitres éclairées du lot N (`window_lit_*`). Les
fenêtres font 0,8 × 1 m (petites) ou 1,4 × 1,4 m (grandes), ou un œil-de-bœuf de 0,6 m, pour que
les vitres éclairées s'y posent. Les enseignes sont des objets peints ou découpés (pain, tasse,
chapeau), jamais des mots.

**Références à joindre** : `assets/hd2d/buildings/cafe.png`, `limashenka_house.png`,
`shop_bakery.png`, `clockmaker.png` (le rendu des façades livrées),
`assets/hd2d/props/market_stall.png`, et pour les intérieurs
`assets/hd2d/interior/props/china_cabinet.png` une fois livré (lot I).

**Consigne** : colle le bloc de style, ce rappel, puis « Image `<chemin>`, <taille> px, <genre> : »
et la description de la ligne. Pour un bâtiment, commande la façade et son flanc dans la même
conversation, façade d'abord.

### 5.2 Le village des hommes-bêtes

À quelques pas de l'entrepôt, entre la forêt et les marais, un village campagnard pas très grand,
mais pas assez petit pour que les fées y connaissent tout le monde ; presque personne n'y porte de
beaux habits (VEX, « Cinq cents ans »). On y bâtit en bois, en torchis et en chaume **(original,
dans l'esprit de l'œuvre)** ; le café à clochette (façade livrée `cafe.png`) et la maison
Limashenka (`limashenka_house.png`) en font partie.

| Prio | Nom (`assets/hd2d/buildings/<nom>.png`) | Façade (px) | Flanc `<nom>_side.png` (px) | Type, mur / faîte (m), profondeur | Matières | Consigne à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `cottage_thatch_a` | 480 × 528 | 480 × 240 | pignon, 2,5 / 5,5 ; prof. 5 | `wall_wattle_daub`, `roof_thatch` | chaumière de torchis ocre clair sur soubassement de pierres, colombages bruns irréguliers, toit de chaume épais et arrondi qui descend bas, porte basse de planches, une petite fenêtre éteinte, pots de fleurs au seuil |
| 2 | `cottage_thatch_b` | 672 × 240 | 480 × 480 | long, 2,5 / 5 ; prof. 5 | `wall_wattle_daub`, `roof_thatch` | longue chaumière basse : deux portes, trois petites fenêtres éteintes à volets, un banc de bois contre le mur, une corde à linge tendue d'un crochet à l'autre (sans linge), la bordure du chaume en haut de l'image |
| 2 | `cottage_thatch_c` | 384 × 480 | 384 × 216 | pignon, 2,25 / 5 ; prof. 4 | `wall_wattle_daub`, `roof_thatch` | petite chaumière penchée, torchis fissuré rapiécé, une lucarne dans le chaume, porte peinte en vert passé |
| 2 | `village_house_stone` | 480 × 576 | 480 × 288 | pignon, 3 / 6 ; prof. 5 | `wall_stone`, `roof_shingles` | maison de pierre un peu plus aisée, toit de bardeaux, porte à heurtoir, deux fenêtres à volets, une plus petite à l'étage dans le pignon, lierre au coin |
| 2 | `village_barn` | 768 × 336 | 576 × 672 | long, 3,5 / 7 ; prof. 6 | `wall_planks`, `roof_thatch` | grange de planches brunes délavées, grande porte à deux battants entrouverte sur la pénombre et le foin, petite porte à côté, fourche appuyée |
| 3 | `village_shed` | 384 × 216 | 288 × 336 | long, 2,25 / 3,5 ; prof. 3 | `wall_planks_b`, `roof_shingles` | appentis à bois de planches grises, bûches empilées sous l'avancée, une hache plantée dans un billot devant |

Matières nouvelles (`buildings/materials/`, 192 × 192, opaques, sans raccord) et panneaux du
village :

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/buildings/materials/roof_thatch.png` | 192 × 192 | matière | chaume de paille dorée grisée par la pluie, en rangées de bottes parallèles au bas de l'image, mousse verte par plaques, quelques brins plus clairs |
| 2 | `assets/hd2d/buildings/materials/wall_wattle_daub.png` | 192 × 192 | matière | torchis ocre clair grumeleux, brins de paille visibles, petites fissures, sans colombages (ils sont dans les façades) |
| 3 | `assets/hd2d/buildings/materials/wall_stone_town.png` | 192 × 192 | matière | pierre de taille gris-beige appareillée en assises régulières, joints fins, quelques blocs plus clairs ou ébréchés (la ville) |
| 2 | `assets/hd2d/props/fence_wattle.png` | 192 × 86 (2 × 0,9 m) | panneau, **sans raccord à gauche et à droite** | clôture de branches tressées entre des piquets, quelques brins cassés |
| 3 | `assets/hd2d/props/haystack.png` | 192 × 154 (2 × 1,6 m) | panneau | meule de foin ronde, une fourche plantée dedans |
| 3 | `assets/hd2d/props/cart_hay.png` | 288 × 192 (3 × 2 m) | panneau | charrette de bois à deux grandes roues chargée de foin, brancards posés au sol |
| 3 | `assets/hd2d/props/washing_trough.png` | 288 × 96 (3 × 1 m) | panneau | lavoir : longue auge de pierre pleine d'eau, planche à laver, un panier de linge mouillé (original) |
| 3 | `assets/hd2d/props/beehives.png` | 154 × 96 (1,6 × 1 m) | panneau | trois ruches de paille tressée sur une planche (le miel du marché, V3) |

### 5.3 Le café à clochette

Il fait tout, faute d'autre endroit où manger : café le jour, alcool le soir ; une sonnette tinte à
la porte ; une arrière-boutique ; l'après-midi, on y mange ou on y prend le thé ; une tablée
d'hommes-bêtes éméchés rit fort ; le serveur homme-chat offre des jus de fruits en cachette du
patron (VEX, « Cinq cents ans »). Dehors, la façade, le flanc et la clochette existent
(`cafe.png`, `cafe_side.png`, `anim/cafe_door_bell.png`).

Matières des intérieurs de la ville et du village (sol, mur, comme au lot I) :

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/floor_terracotta.png` | 384 × 384 | tuile de sol | carreaux carrés de terre cuite de 20 cm, rouge-brun et ocre mêlés, usés, quelques-uns fêlés |
| 3 | `assets/hd2d/interior/floor_stone_town.png` | 384 × 384 | tuile de sol | dalles de pierre claire polies par les pas, joints fins, une dalle fendue (boutiques de la ville) |
| 2 | `assets/hd2d/interior/wall_panel_dark.png` | 384 × 288 | mur | lambris de bois sombre jusqu'à 1,4 m, cimaise, enduit ocre au-dessus enfumé, plinthe (le café) |
| 3 | `assets/hd2d/interior/wall_stone_inside.png` | 384 × 288 | mur | pierre apparente jointoyée, moellons beiges, une poutre en haut (boulangerie, boucherie) |
| 2 | `assets/hd2d/interior/wall_wallpaper_floral.png` | 384 × 288 | mur | papier peint à grandes fleurs fanées vert d'eau et rose sur fond crème, auréoles, plinthe et moulure (le salon des Limashenka) |
| 3 | `assets/hd2d/interior/wall_plaster_ochre.png` | 384 × 288 | mur | enduit ocre clair, propre mais vieilli, plinthe de bois peint (boutiques) |

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/cafe_counter.png` | 288 × 115 (3 × 1,2 m) | meuble | comptoir de bois sombre ciré, usé au bord : une grande cafetière de cuivre sur un réchaud de cristal, des tasses retournées, un bocal de biscuits, un tonnelet à robinet de bois au bout |
| 2 | `assets/hd2d/interior/props/cafe_bottle_shelf.png` | 192 × 192 (2 × 2 m) | meuble | étagères de bois derrière le comptoir : bouteilles d'alcool de toutes formes (le soir), pots de café, piles de tasses, chopes pendues |
| 2 | `assets/hd2d/interior/props/cafe_table_heavy.png` | 115 × 96 (1,2 × 1 m) | meuble | table carrée de bois épais, nappe à carreaux rouges et blancs, deux tasses ; avec les chaises `chair_wood` du lot I |
| 2 | `assets/hd2d/interior/props/cafe_drinkers_table.png` | 154 × 106 (1,6 × 1,1 m) | meuble | la table des buveurs : chopes renversées, cartes à jouer, un plat de saucisses entamé, flaques de bière (VEX : la tablée éméchée) |
| 2 | `assets/hd2d/interior/props/cafe_cake_case.png` | 96 × 58 (1 × 0,6 m) | objet posé sur le comptoir | vitrine à gâteaux sous cloche de verre : une tarte aux pommes, des petits gâteaux à la crème |
| 2 | `assets/hd2d/interior/props/juice_glasses.png` | 48 × 29 (0,5 × 0,3 m) | objet posé sur une table | trois verres de jus de fruits (orange, rouge, jaune) et une carafe (VEX : les jus offerts « pour la maison ») |
| 2 | `assets/hd2d/interior/door_backroom.png` | 106 × 211 (1,1 × 2,2 m) | porte | passage vers l'arrière-boutique masqué d'un rideau de toile rayée, chambranle de bois (VEX) |
| 2 | `assets/hd2d/interior/wallitem_menu_cafe.png` | 77 × 96 (0,8 × 1 m) | élément de mur, bas à 1,2 m | ardoise du menu : dessins à la craie d'une tasse fumante, d'une chope et d'une part de gâteau, traits de craie à la place des mots |
| 3 | `assets/hd2d/props/cafe_backyard_crates.png` | 154 × 96 (1,6 × 1 m) | panneau (dehors) | derrière le café, près de la porte de service : caisses de bouteilles vides, deux tonnelets, un balai |

### 5.4 La maison Limashenka

Une vieille maison du village dont la mère de Ramikeldi vient de mourir ; dans le salon, une vieille
horloge murale purement mécanique, sans cristal, pleine de ressorts, de vis et d'engrenages, dont
un peigne doré dans une caisse de résonance joue une comptine ; les pièces de rechange ont été
commandées ; Willem la répare jusqu'à deux heures (VEX, « L'homme-chat »). La façade aux volets
clos existe (`limashenka_house.png`).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/wallitem_clock_limashenka.png` | 77 × 134 (0,8 × 1,4 m) | élément de mur, bas à 0,9 m | vieille horloge murale dans une grande caisse de bois sculpté de feuilles, cadran de laiton marqué de traits (aucun chiffre), aiguilles ouvragées, porte vitrée sur un balancier de laiton ; arrêtée |
| 2 | `assets/hd2d/interior/wallitem_clock_limashenka_open.png` | 77 × 134 | élément de mur, bas à 0,9 m | la même horloge, caisse ouverte : engrenages de laiton, ressorts, vis, et au fond un peigne doré posé dans une petite caisse de résonance (celui d'une boîte à musique) ; même cadrage au pixel près |
| 3 | `assets/hd2d/anim/clock_limashenka_swing.png` | 77 × 134, 4 images, 2 ips | bande animée | l'horloge réparée : le balancier va et vient, le reste identique au pixel près |
| 2 | `assets/hd2d/interior/props/armchair_sheeted.png` | 96 × 101 (1 × 1,05 m) | meuble | fauteuil recouvert d'un drap blanc poussiéreux, maison fermée depuis le deuil (original) |
| 2 | `assets/hd2d/interior/props/sofa_salon.png` | 192 × 96 (2 × 1 m) | meuble | canapé à dossier sculpté, velours vert passé, napperons de dentelle |
| 3 | `assets/hd2d/interior/props/side_table_salon.png` | 58 × 67 (0,6 × 0,7 m) | meuble | guéridon à napperon, une petite boîte à couture et un portrait encadré posé |
| 2 | `assets/hd2d/interior/props/display_cabinet.png` | 115 × 182 (1,2 × 1,9 m) | meuble | vitrine de bibelots : tasses de porcelaine, petits animaux de verre, une pipe, des boîtes à tabac (le fils est marchand de tabac, VEX) |
| 2 | `assets/hd2d/interior/props/toolbox_gears.png` | 77 × 48 (0,8 × 0,5 m) | meuble | boîte à outils de bois ouverte posée par terre : pinces, tournevis, burette, et un sachet de papier d'où sortent des engrenages neufs (VEX : les pièces de rechange commandées) |
| 3 | `assets/hd2d/interior/wallitem_family_portrait.png` | 58 × 72 (0,6 × 0,75 m) | élément de mur, bas à 1,4 m | portrait peint d'une famille d'hommes-chats, une mère et un petit garçon, dans un cadre doré terni ; aucun texte |
| 3 | `assets/hd2d/decals/rug_salon.png` | 288 × 192 (3 × 2 m) | décalque à bord plein | tapis à médaillon central bordeaux et vert, usé, franges |
| 2 | `assets/hd2d/interior/window_shutters.png` | 115 × 154 (1,2 × 1,6 m) | fenêtre, appui à 0,8 m | fenêtre aux volets intérieurs de bois entrouverts, rais de lumière entre les lames (la maison qui se rouvre, cahier n° 1) |

### 5.5 Le centre-ville en pente

À 2 000 marmer du port, des centaines de bâtiments de pierre alignés sur une légère pente, dans une
atmosphère idyllique (V1, « Directeur en carton ») ; on y descend de l'entrepôt par un sentier
(V5, « La fin imminente ») ; un vent froid y souffle (V2, « De ce côté-ci de l'écran »). Deux ou
trois cartes : une rue en pente coupée d'escaliers, une place du marché, des ruelles. Le jeu monte
le sol par paliers de 0,5 m : chaque façade de ville a en bas un **socle de pierre nue de 0,5 m**,
compris dans la hauteur du mur, pour s'asseoir sur deux paliers (**format à confirmer par le
moteur**, lot E2). Les façades livrées des cahiers n° 1 et 2 (boulangerie, librairie, horloger,
boucherie, salle de projection, maisons à colombages, maison étroite) restent ; celles-ci les
complètent.

| Prio | Nom (`assets/hd2d/buildings/<nom>.png`) | Façade (px) | Flanc `<nom>_side.png` (px) | Type, mur / faîte (m), profondeur | Matières | Consigne à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `town_house_a` | 480 × 864 | 576 × 576 | pignon, 6 / 9 ; prof. 6 | `wall_stone_town`, `roof_slate_b` | haute maison de pierre de taille à trois niveaux, porte en haut de trois marches, fenêtres à volets bleu passé, corniche de pierre, socle nu de 0,5 m |
| 3 | `town_house_b` | 768 × 576 | 576 × 816 | long, 6 / 8,5 ; prof. 6 | `wall_stone_town`, `roof_tiles_b` | maison bourgeoise à deux étages, rez-de-chaussée de boutique fermée par des volets de bois, balcon de fer forgé à l'étage, jardinières |
| 3 | `town_house_c` | 384 × 720 | 480 × 432 | pignon, 4,5 / 7,5 ; prof. 5 | `wall_plaster`, `roof_tiles` | maison étroite : pierre au rez-de-chaussée, étage à colombages en encorbellement, porte bleue, une fenêtre par niveau |
| 3 | `town_house_d` | 576 × 432 | 480 × 672 | long, 4,5 / 7 ; prof. 5 | `wall_stone_b`, `roof_slate` | maison basse de pierre claire avec une porte cochère au milieu (arc de pierre sur un passage sombre), deux fenêtres de part et d'autre |
| 3 | `town_house_e` | 576 × 960 | 576 × 720 | pignon, 7,5 / 10 ; prof. 6 | `wall_stone_town`, `roof_slate_b` | grande maison de quatre niveaux en haut de la pente, chaînages d'angle, lucarne dans le pignon, girouette en forme de poisson volant (original) |
| 3 | `town_house_f` | 576 × 336 | 480 × 576 | long, 3,5 / 6 ; prof. 5 | `wall_plaster_b`, `roof_tiles_b` | maison d'un niveau à enduit ocre, porte entre deux fenêtres, un banc et des pots de géraniums |
| 3 | `town_house_g` | 480 × 768 | 480 × 480 | pignon, 5 / 8 ; prof. 5 | `wall_brick`, `roof_tiles` | maison de briques rouge-brun à deux niveaux, fenêtres à linteaux de pierre, linge à une fenêtre |
| 3 | `town_house_h` | 672 × 480 | 576 × 720 | long, 5 / 7,5 ; prof. 6 | `wall_plaster_c`, `roof_slate` | maison d'enduit rose pâle écaillé à deux niveaux, pierre visible par plaques, escalier extérieur de pierre vers la porte de l'étage |

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/props/town_roofs_a.png` | 1536 × 768 (16 × 8 m) | lisière, raccord à gauche et à droite | la ville qui descend au-delà du bord de la carte, vue de haut et de loin : rangées serrées de toits d'ardoise et de tuiles en écailles, cheminées qui fument, lucarnes, un clocher de pierre, quelques arbres dorés entre les toits ; pour fermer l'horizon des rues |
| 3 | `assets/hd2d/props/town_roofs_b.png` | 1536 × 768 | lisière, raccord | même chose, toits plus bas et plus épars, jardins et murets entre eux, le bord de la ville qui rejoint la forêt |
| 3 | `assets/hd2d/sky/town_roofs_far.png` | 2048 × 384 (à 48 px/m) | lointain, raccord à gauche et à droite | silhouette lointaine de la ville sur sa pente, toits et cheminées adoucis et violacés par la distance |
| 3 | `assets/hd2d/props/town_stairs_a.png` | 192 × 192 (2 × 2 m) | panneau, **format à confirmer par le moteur** (E2) | volée de six marches de pierre de 2 m de large qui monte d'1 m vers le fond (le nord) entre deux murets, marches usées au milieu, herbe dans les joints |
| 3 | `assets/hd2d/props/town_stairs_b.png` | 384 × 192 (4 × 2 m) | panneau, **à confirmer** (E2) | grand escalier de place, plus large, rampe de fer au milieu |
| 3 | `assets/hd2d/props/town_wall_low.png` | 192 × 77 (2 × 0,8 m) | panneau, sans raccord à gauche et à droite | muret de pierre sèche à couronnement de dalles, mousse |
| 3 | `assets/hd2d/cliff/town_retaining_wall.png` | 384 × 96 (4 × 1 m) | mur sans raccord à gauche et à droite, opaque, **format à confirmer par le moteur** (E2 : faces des paliers) | mur de soutènement de pierre appareillée entre deux paliers de la rue, barbacanes, traînées d'humidité, lierre qui retombe du haut |
| 3 | `assets/hd2d/props/town_railing.png` | 192 × 96 (2 × 1 m) | panneau, sans raccord à gauche et à droite | garde-corps de fer forgé d'une terrasse, volutes simples, rouille |
| 3 | `assets/hd2d/props/town_arch.png` | 288 × 336 (3 × 3,5 m) | panneau | passage voûté de pierre entre deux maisons, l'ombre du passage, une lanterne de fer au sommet de l'arc |
| 3 | `assets/hd2d/props/town_planter_stone.png` | 154 × 77 (1,6 × 0,8 m) | panneau | bac de pierre fleuri d'asters et de bruyère |
| 3 | `assets/hd2d/props/town_wall_fountain.png` | 115 × 154 (1,2 × 1,6 m) | panneau | fontaine murale : bec de cuivre vert-de-grisé, auge de pierre, une tasse de fer à une chaînette |
| 3 | `assets/hd2d/props/town_doorsteps.png` | 115 × 48 (1,2 × 0,5 m) | panneau | trois marches de pierre devant une porte, un paillasson |
| 3 | `assets/hd2d/props/town_cellar_hatch.png` | 115 × 58 (1,2 × 0,6 m) | panneau | trappe de cave de bois inclinée contre un mur, pentures de fer |

### 5.6 Les boutiques

Les commerces de l'œuvre : le snack-bar du jeune lycanthrope (V1, « Directeur en carton ») ; la
librairie, l'horloger, la salle de projection, le magasin d'accessoires, un café, le boucher (V2,
« Temps écoulé depuis lors ») ; la boulangerie au patron grincheux où travaille Lakhesh et le marché
du matin (V3, « Je suis à la maison ») ; le café habituel, avec la librairie au coin de la rue (V3,
« Le grand et jeune lézard » ; V5) ; un apothicaire **(déduction)**. Façades déjà livrées :
`shop_bakery`, `shop_bookshop`, `clockmaker`, `butcher`, `projection_hall`. Nouvelles :

| Prio | Nom (`assets/hd2d/buildings/<nom>.png`) | Façade (px) | Flanc `<nom>_side.png` (px) | Type, mur / faîte (m), profondeur | Matières | Consigne à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `shop_snack` | 480 × 336 | 480 × 576 | long, 3,5 / 6 ; prof. 5 | `wall_stone_town`, `roof_tiles` | snack-bar : petite boutique de pierre au comptoir ouvert sur la rue sous un auvent de toile, plaque de cuisson derrière, trois tabourets hauts devant, enseigne en forme de poêle (V1) |
| 3 | `shop_apothecary` | 384 × 624 | 480 × 384 | pignon, 4 / 6,5 ; prof. 5 | `wall_stone_town`, `roof_slate` | apothicaire : vitrine de bocaux de verre colorés, porte vitrée, enseigne en forme de mortier et de pilon |
| 3 | `shop_accessories` | 384 × 624 | 480 × 384 | pignon, 4 / 6,5 ; prof. 5 | `wall_plaster`, `roof_tiles` | magasin d'accessoires : vitrine de chapeaux sur des têtes de bois, rubans et broches, auvent vert, enseigne en forme de chapeau |
| 2 | `cafe_town` | 672 × 384 | 576 × 576 | long, 4 / 6 ; prof. 6 | `wall_stone_town`, `roof_slate_b` | le café habituel de la ville, au coin d'une rue : grandes fenêtres, porte vitrée, deux tables rondes dehors, enseigne en forme de tasse (V3 ; V5) |

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/props/hanging_sign_cup.png` | 96 × 115 (1 × 1,2 m) | panneau (potence au mur, ancre au bas de la potence) | enseigne de fer pendue à une potence, découpée en tasse fumante |
| 3 | `assets/hd2d/props/hanging_sign_mortar.png` | 96 × 115 | panneau | enseigne en forme de mortier et de pilon |
| 3 | `assets/hd2d/props/hanging_sign_hat.png` | 96 × 115 | panneau | enseigne en forme de chapeau à ruban |
| 2 | `assets/hd2d/props/hanging_sign_pan.png` | 96 × 115 | panneau | enseigne en forme de poêle à frire |
| 3 | `assets/hd2d/props/market_stall_dairy.png` | 240 × 230 (2,5 × 2,4 m) | panneau | étal du marché du matin sous bâche crème : mottes de beurre, bidons de lait, fromages, paniers d'œufs (V3) |
| 3 | `assets/hd2d/props/market_stall_honey.png` | 240 × 230 | panneau | étal sous bâche ocre : pots de miel, sacs de noix et de fruits secs ouverts (V3) |
| 3 | `assets/hd2d/props/market_stall_flour.png` | 240 × 230 | panneau | étal sous bâche grise : sacs de farine et de sucre, une balance à plateaux, une pelle (V3) |

### 5.7 Les intérieurs des boutiques

Sols et murs : section 5.3 (et les matières du lot I). Chaque boutique est une petite pièce
encombrée.

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/snack_counter.png` | 288 × 115 (3 × 1,2 m) | meuble | comptoir du snack-bar : plaque de cuisson de fonte sur un réchaud de cristal, une poêle où grésille du lard, une bassine de friture, des pommes de terre, un pot de soupe (V1 : le lycanthrope fait sauter sa poêle) |
| 2 | `assets/hd2d/interior/props/snack_stools.png` | 154 × 77 (1,6 × 0,8 m) | meuble | rangée de trois tabourets hauts de bois devant le comptoir |
| 2 | `assets/hd2d/interior/props/snack_meal_tray.png` | 48 × 24 (0,5 × 0,25 m) | objet posé sur une table | plateau : pommes de terre frites, légumes, lard frit épais, petit pain, soupe dans une tasse (V1) |
| 3 | `assets/hd2d/interior/props/snack_shelf.png` | 154 × 154 (1,6 × 1,6 m) | meuble | étagère de pots, de sacs de pommes de terre et de bouteilles d'huile |
| 2 | `assets/hd2d/interior/props/bakery_oven.png` | 192 × 192 (2 × 2 m) | meuble | four à pain de briques, gueule voûtée fermée d'une porte de fonte entrouverte, braises au fond, pelle à enfourner appuyée |
| 3 | `assets/hd2d/anim/oven_glow.png` | 96 × 58 (1 × 0,6 m), 4 images, 6 ips | bande animée | lueur des braises dans la gueule du four, qui pulse doucement (sans le four) |
| 2 | `assets/hd2d/interior/props/kneading_trough.png` | 154 × 96 (1,6 × 1 m) | meuble | pétrin de bois plein de pâte, farine partout, un rouleau |
| 2 | `assets/hd2d/interior/props/bread_shelves.png` | 192 × 211 (2 × 2,2 m) | meuble | étagères de pains : miches rondes, pains longs, brioches, petits pains en paniers |
| 2 | `assets/hd2d/interior/props/bakery_counter.png` | 192 × 106 (2 × 1,1 m) | meuble | comptoir de boulangerie : balance, panier de petits pains, papier d'emballage (V3 : Lakhesh y sert le matin) |
| 3 | `assets/hd2d/interior/props/bookshop_shelves.png` | 192 × 230 (2 × 2,4 m) | meuble | rayonnages de librairie du sol au plafond, échelle roulante accrochée à une tringle |
| 3 | `assets/hd2d/interior/props/bookshop_counter.png` | 154 × 106 (1,6 × 1,1 m) | meuble | comptoir : piles de commandes ficelées (celles de l'entrepôt, V3), une loupe, une sonnette de comptoir |
| 3 | `assets/hd2d/interior/props/bookshop_table.png` | 154 × 86 (1,6 × 0,9 m) | meuble | table de nouveautés : livres d'images et romans en piles, couvertures colorées sans titres |
| 3 | `assets/hd2d/interior/props/watch_workbench.png` | 154 × 106 (1,6 × 1,1 m) | meuble | établi d'horloger : loupe sur bras, engrenages, ressorts, pinces fines, une horloge démontée |
| 3 | `assets/hd2d/interior/wallitem_clocks.png` | 192 × 115 (2 × 1,2 m) | élément de mur, bas à 1,2 m | mur d'horloges de formes variées (rondes, carrées, à coucou de bois), cadrans sans chiffres, aiguilles à des heures différentes |
| 3 | `assets/hd2d/interior/props/longcase_clock.png` | 58 × 211 (0,6 × 2,2 m) | meuble | horloge de parquet en bois sombre, cadran de laiton sans chiffres, balancier visible |
| 3 | `assets/hd2d/interior/props/butcher_block.png` | 96 × 96 (1 × 1 m) | meuble | billot de bois sur pieds, couperet planté, torchon ; aucun sang |
| 3 | `assets/hd2d/interior/wallitem_meat_hooks.png` | 192 × 106 (2 × 1,1 m) | élément de mur, bas à 1,2 m | barre à crochets : jambons, saucisses, flèches de lard, paquets emballés ; aucune bête entière, aucun sang |
| 3 | `assets/hd2d/interior/props/butcher_counter.png` | 192 × 106 (2 × 1,1 m) | meuble | comptoir à dessus de marbre, balance, papier d'emballage, couteaux rangés |
| 3 | `assets/hd2d/interior/props/cinema_benches.png` | 288 × 86 (3 × 0,9 m) | meuble | rangée de bancs de bois vus de dos (dossiers vers la caméra), pour la salle de projection |
| 3 | `assets/hd2d/interior/props/cinema_screen.png` | 384 × 288 (4 × 3 m) | meuble | toile blanche tendue sur un cadre de bois, rideaux de velours rouge passé de part et d'autre, estrade basse (V2) |
| 3 | `assets/hd2d/anim/projection_flicker.png` | 288 × 192 (3 × 2 m), 4 images, 8 ips | bande animée, **alpha doux** | le film muet projeté sur la toile : un rectangle de lumière grise qui tremble, deux silhouettes floues de lézards sur un pont voûté entre des lampes (V2 : une romance de lézards) ; sans écran ni cadre |
| 3 | `assets/hd2d/interior/props/crystal_projector.png` | 77 × 154 (0,8 × 1,6 m) | meuble | appareil de projection : boîte de laiton à lentille sur un trépied de bois, un cristal enregistreur dans son logement, une manivelle (V2) |
| 3 | `assets/hd2d/interior/props/hat_stands.png` | 154 × 154 (1,6 × 1,6 m) | meuble | présentoir de chapeaux sur des têtes de bois, dont un grand chapeau bleu foncé |
| 3 | `assets/hd2d/interior/props/ribbon_display.png` | 115 × 134 (1,2 × 1,4 m) | meuble | vitrine de rubans en bobines, broches, peignes, gants |
| 3 | `assets/hd2d/interior/props/accessories_counter.png` | 154 × 173 (1,6 × 1,8 m) | meuble | comptoir surmonté d'un grand miroir ovale à cadre doré (verre gris bleuté uni) |
| 2 | `assets/hd2d/interior/props/cafe_town_counter.png` | 288 × 115 (3 × 1,2 m) | meuble | comptoir du café habituel : grosse cafetière de cuivre, tasses, sandwichs au bacon sous cloche (V3 : on n'y sert pas de thé) |
| 2 | `assets/hd2d/interior/props/cafe_town_table.png` | 134 × 96 (1,4 × 1 m) | meuble | lourde table de bois et deux petites chaises trop petites pour un lézard géant (V3 ; V5) |
| 3 | `assets/hd2d/interior/wallitem_menu_town.png` | 96 × 115 (1 × 1,2 m) | élément de mur, bas à 1,1 m | carte affichée dans un cadre : lignes peintes illisibles, dessins d'une tasse et d'un sandwich (V3) |
| 3 | `assets/hd2d/interior/props/apothecary_counter.png` | 192 × 106 (2 × 1,1 m) | meuble | comptoir d'apothicaire : balance de précision, mortier, fioles, papier plié |
| 3 | `assets/hd2d/interior/props/apothecary_shelves.png` | 192 × 230 (2 × 2,4 m) | meuble | étagères de bocaux de faïence à étiquettes vierges et de fioles colorées |
| 3 | `assets/hd2d/interior/props/herb_drawers.png` | 154 × 173 (1,6 × 1,8 m) | meuble | meuble d'herboriste à dizaines de petits tiroirs à boutons de laiton, étiquettes vierges |
| 3 | `assets/hd2d/interior/wallitem_dried_herbs.png` | 154 × 77 (1,6 × 0,8 m) | élément de mur, bas à 1,6 m | bouquets d'herbes séchées pendus tête en bas à une perche |

## 6. Lot L : le port et les navires

### 6.1 Rappel du format (à coller avec le lot)

Chaque ligne donne le chemin complet du fichier (`assets/hd2d/…`). Genres :
- **panneau** (`props/`) : objet debout vu de face, légèrement plongeant, fond transparent, collé
  au bord bas et centré (ancre au milieu du bord bas) ;
- **façade** et **flanc** (`buildings/`) : élévations sans perspective, mur collé aux bords
  gauche, droit et bas ; type `long` : façade = largeur × hauteur du mur, flanc en pignon =
  profondeur × faîte ; type `pignon` : façade = largeur × faîte, flanc gouttereau = profondeur ×
  hauteur du mur ; flanc au modelé doux et symétrique ;
- **intérieur** (`interior/`) : sol 384 × 384 vu de dessus sans raccord ; mur 384 × 288 de face,
  raccord à gauche et à droite, plinthe et corniche comprises ; haut de mur 384 × 24 (coupe du mur
  vue de dessus) ; porte collée au bord bas ; fenêtre et élément de mur posés à la hauteur donnée ;
  meuble de face légèrement plongeant, collé au bord bas ; objet posé : ancre sur le plateau du
  meuble ;
- **bande animée** (`anim/`) : `n` images côte à côte sans marge, boucle sans saut, seul ce qui
  bouge change ; ce qui tourne (rotor) est centré dans chaque image.

Les navires sont un genre nouveau, **en volume** : **format à confirmer par le moteur** (lot E7).

**Les navires de l'œuvre.** Ce ne sont **jamais des ballons** : aucune enveloppe de gaz n'est
mentionnée. Ce sont des navires volants à **coque de métal**, portés par une **chaudière enchantée**
(un four enchanté qui gronde et fait vibrer la coque) et poussés par des **rotors** ou des hélices,
avec des **bras d'ancrage**, une **passerelle** et une rampe, une **trappe** qui s'ouvre sous la
pression, plusieurs **ponts** et salles, un sifflet à vapeur (V1, « Entrepôt de fées » ; V2, « Le
chemin du retour, toujours si loin » ; V3 ; V4, prologue). Les images du cahier n° 2 (le navire du
passeur et le Barocupot de profil, `props/airship_ferry.png`, `props/airship_barocupot.png`, leurs
hélices) restent ; celles-ci leur donnent un volume.

**Le format d'un navire en volume** (dossier `ships/`, à 96 px/m, proue à droite) :
- `<navire>_side.png` : le **flanc** vu de face, sans perspective, de la quille au sommet des
  superstructures, fond transparent, la quille collée au bord bas de l'image (ancre au milieu du
  bord bas) ; les moyeux des rotors dessinés **sans pales** (les pales sont une bande animée à
  part) ;
- `<navire>_deck.png` : le **pont** vu strictement de dessus, proue à droite : plancher, écoutilles,
  toits des superstructures, bastingage ; fond transparent autour de la coque, ancre au centre
  (c'est le sol où l'on marche à bord) ;
- `<navire>_stern.png` : la **poupe** vue de face, sans perspective, fond transparent, quille
  collée au bord bas (le navire vu de l'arrière, quand il est amarré face au quai) ;
- `<navire>_34.png` : le navire **de trois quarts avant**, en léger surplomb, pour les plans de
  loin (arrivée, départ) ; fond transparent, centré, marge transparente tout autour.

La caméra regarde le nord : les navires s'amarrent **au nord des quais**, de flanc ou par la poupe,
jamais entre la caméra et le joueur (`docs/REFONTE.md`, section 3.1).

**Références à joindre** : `assets/hd2d/props/airship_barocupot.png`, `airship_ferry.png`,
`mooring_arm.png`, `mooring_tower.png`, `gangway.png`, `assets/hd2d/buildings/port_hangar.png`.

**Consigne** : colle le bloc de style, ce rappel, puis « Image `<chemin>`, <taille> px, <genre> : »
et la description de la ligne. Pour un navire, commande ses vues dans la même conversation, flanc
d'abord, et joins le flanc aux suivantes.

### 6.2 Le port et la rue du port

La rue du port, au bord du vide, où le vent souffle fort ; un panneau abîmé par les vents violents,
aux flèches rouges : le centre-ville à 2 000 marmer à droite, l'entrepôt à 500 marmer dans l'autre
direction (V1, « L'Homme sans Marque ») ; l'amarrage, un lourd bruit de métal, une passerelle, trois
bras d'ancrage qui se fixent de l'arrière vers l'avant (V1, « Entrepôt de fées ») ; une rampe, un
sifflet à vapeur, des charrettes chargées de sacs qui filent sur l'aire-port (V2, « Le chemin du
retour, toujours si loin ») ; une colline toujours ventée juste à côté (V3, « La Fille sans
visage ») ; une pluie fine au crépuscule (V1). Les panneaux du port des cahiers n° 1 et 2 restent
(quai de tôle, bras d'ancrage replié, pylône, passerelle, caisses de cristaux, tonneaux, cordages,
guichet, lampadaires).

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/props/signpost_port.png` | 154 × 288 (1,6 × 3 m) | panneau | le panneau du port d'après l'œuvre : poteau de bois fendu et penché par le vent, deux planches taillées en flèches et peintes d'un rouge écaillé, l'une vers la droite, l'autre vers la gauche ; sur celle de droite, de petites maisons de pierre peintes, sur celle de gauche un bâtiment de bois dans des arbres ; aucun texte, aucun chiffre ; usé, délavé, un clou qui tient mal (V1, « L'Homme sans Marque ») |
| 2 | `assets/hd2d/props/cargo_cart_a.png` | 288 × 173 (3 × 1,8 m) | panneau | charrette à bras à deux roues cerclées de fer, chargée de sacs de toile ficelés, brancards levés (V2) |
| 3 | `assets/hd2d/props/cargo_cart_b.png` | 240 × 134 (2,5 × 1,4 m) | panneau | diable de bois et de fer chargé de trois caisses, une sangle |
| 2 | `assets/hd2d/props/mooring_arm_open.png` | 288 × 384 (3 × 4 m) | panneau | bras d'ancrage de fer et de cuivre **déployé**, pince ouverte prête à saisir une coque, vérins, câbles, rivets ; complète `mooring_arm.png` (replié) |
| 3 | `assets/hd2d/anim/mooring_arm_clamp.png` | 288 × 384, 4 images, 6 ips | bande animée | `mooring_arm_open.png` (jointe) : le bras s'abaisse et la pince se referme sur un anneau non dessiné ; image 3 : fermé ; le pied immobile au pixel près |
| 2 | `assets/hd2d/props/steam_whistle.png` | 77 × 192 (0,8 × 2 m) | panneau | sifflet à vapeur de laiton terni au bout d'un tuyau de cuivre qui sort du quai, petite chaîne de manœuvre (V2) ; la vapeur est la bande `anim/furnace_steam.png` du cahier n° 2 |
| 3 | `assets/hd2d/props/capstan.png` | 96 × 86 (1 × 0,9 m) | panneau | cabestan de fer à barres de bois, un cordage enroulé |
| 2 | `assets/hd2d/props/gangway_ramp.png` | 288 × 154 (3 × 1,6 m) | panneau | rampe d'embarquement inclinée de tôle striée, garde-corps de fer, vue de flanc, qui monte vers la droite (V2 : on monte par une passerelle et une rampe) |
| 3 | `assets/hd2d/props/wind_fence.png` | 192 × 134 (2 × 1,4 m) | panneau, sans raccord à gauche et à droite | palissade brise-vent de planches grises le long de la rue du port, deux planches cassées, un poteau penché |

Deux maisons de la rue du port (façade et flanc, format du lot K) :

| Prio | Nom (`assets/hd2d/buildings/<nom>.png`) | Façade (px) | Flanc `<nom>_side.png` (px) | Type, mur / faîte (m), profondeur | Matières | Consigne à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `port_house_a` | 576 × 336 | 480 × 576 | long, 3,5 / 6 ; prof. 5 | `wall_stone`, `roof_slate_b` | maison basse de pierre au bord du vide, volets fermés par le vent, câbles d'ancrage scellés au mur, fenêtres éteintes |
| 3 | `port_house_b` | 384 × 624 | 480 × 384 | pignon, 4 / 6,5 ; prof. 5 | `wall_planks_b`, `roof_tin` | cabane du gardien du port en planches grises, girouette, longue-vue posée sur l'appui de la fenêtre |

### 6.3 Le transport de la Garde

Le navire qui ramène les fées du combat : il descend d'au-dessus de la mer de nuages, précédé d'une
lumière si forte qu'on ne voit pas sa silhouette ; il est **petit**, militaire, et ne ressemble ni à
un dirigeable de banlieue ni à celui d'un passeur ; deux pales de rotor s'arrêtent peu à peu, le
bruit de la chaudière enchantée décroît, la trappe de sortie s'ouvre sous la pression, et le lézard
géant doit se faire petit pour en sortir (V1, « Entrepôt de fées »). **(Format à confirmer par le
moteur.)**

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/ships/garde_transport_side.png` | 1536 × 672 (16 × 7 m) | flanc, proue à droite | petit transport militaire de la Garde ailée, de flanc : coque trapue de tôle d'acier rivetée gris-bleu sombre, bande rouge de la Garde (#AE4A3E) le long du bordage, aile stylisée peinte à la proue (sans texte), quille de fer ; au milieu, une cabine basse à hublots ronds éclairés et une cheminée courte ; à l'arrière, la chaudière enchantée en nacelle sous la coque, grilles rougeoyantes ; **deux moyeux de rotor** au bout de bras courts qui sortent du flanc au-dessus du bordage, à un quart et aux trois quarts de la longueur, axe tourné vers la caméra (comme les hélices latérales du cahier n° 2), **sans pales** ; une trappe ronde fermée sur le flanc à l'arrière ; massif, sérieux, entretenu ; **aucun ballon** |
| 2 | `assets/hd2d/ships/garde_transport_deck.png` | 1536 × 480 (16 × 5 m) | pont, vu de dessus | le pont du même navire vu de dessus, proue à droite : tôles rivetées, passavants, toit de la cabine, les bras des deux rotors qui dépassent de chaque bord, écoutille, bastingage de fer, caisses arrimées ; fond transparent autour de la coque |
| 3 | `assets/hd2d/ships/garde_transport_stern.png` | 480 × 672 (5 × 7 m) | poupe, de face | le même navire vu de l'arrière : poupe arrondie de tôle, gouvernails de direction, la nacelle de la chaudière sous la coque, de chaque côté, un bras de rotor et ses deux pales vues par la tranche, immobiles |
| 3 | `assets/hd2d/ships/garde_transport_34.png` | 1536 × 864 (16 × 9 m) | trois quarts avant | le même navire de trois quarts avant, en léger surplomb, rotors **avec** leurs pales immobiles, bande rouge, hublots éclairés |
| 2 | `assets/hd2d/anim/garde_transport_rotor.png` | 192 × 192 (2 m), 4 images, 12 ips | bande animée, centrée | rotor à deux pales de fer sombre aux bouts rouges, vu de face, qui tourne d'un huitième de tour (45°) d'une image à l'autre : en 4 images, chaque pale prend la place de l'autre, boucle sans à-coup ; moyeu au centre exact de chaque image |
| 3 | `assets/hd2d/anim/garde_transport_hatch.png` | 192 × 192 (2 m), 4 images, 8 ips, non bouclée | bande animée | la trappe ronde du flanc qui s'ouvre sous la pression : 0 fermée ; 1 le volant tourne, un jet de vapeur ; 2 entrouverte, vapeur ; 3 grande ouverte sur l'intérieur sombre (V1) |

### 6.4 Le Barocupot

Le navire de la Garde ailée où Chtholly est recueillie après sa chute dans les nuages : au moins
deux ponts ; au deuxième, une petite salle du conseil de guerre prévue pour plusieurs personnes, où
l'on est à l'étroit avec un lézard deux fois plus grand qu'une fée ; on y prête une serviette et on
y sert un thé chaud, amer et piquant, dans des tasses minuscules pour un lézard (V1, « La fille
errante et le lézard volant »). Son flanc existe (`props/airship_barocupot.png`, 24 × 11 m, deux
moyeux). **(Format à confirmer par le moteur.)**

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/ships/barocupot_deck.png` | 2304 × 576 (24 × 6 m) | pont, vu de dessus | le pont supérieur du Barocupot vu de dessus, proue à droite, dans le style de `airship_barocupot.png` (joint) : tôles d'acier rivetées gris-bleu, bande rouge au bordage, toit de la passerelle de commandement vitrée à l'avant, écoutilles, canon court sous bâche, manches à air, rambardes ; fond transparent autour |
| 3 | `assets/hd2d/ships/barocupot_stern.png` | 576 × 1056 (6 × 11 m) | poupe, de face | le Barocupot vu de l'arrière : poupe haute, deux ponts de hublots, ailerons de queue, la grande trappe de soute fermée, les deux nacelles des fours sous la coque |
| 3 | `assets/hd2d/ships/barocupot_34.png` | 2688 × 1248 (28 × 13 m) | trois quarts avant | le Barocupot de trois quarts avant, en léger surplomb, dans les nuages : hélices latérales avec leurs pales, bande rouge, hublots éclairés ; massif |

La salle du conseil de guerre et la coursive (format du lot I) :

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/interior/floor_ship_planks.png` | 384 × 384 | tuile de sol | plancher de bord : lames étroites de bois sombre verni, clous de cuivre, joints serrés, une plaque de tôle vissée par endroits |
| 3 | `assets/hd2d/interior/wall_ship_plate.png` | 384 × 288 | mur | cloison de tôle rivetée peinte gris-bleu, plinthe de tuyaux de cuivre, rangées de rivets, une couture soudée, traces d'usure |
| 3 | `assets/hd2d/interior/wallcut_ship.png` | 384 × 24 | haut de mur | coupe d'une cloison double de tôle vue de dessus, isolant brun entre les deux |
| 3 | `assets/hd2d/interior/props/war_table.png` | 192 × 106 (2 × 1,1 m) | meuble | table du conseil de guerre : une carte de l'archipel déroulée (îles dessinées, sans chiffres ni noms), compas, règles, pions de laiton |
| 3 | `assets/hd2d/interior/props/war_chair.png` | 58 × 106 (0,6 × 1,1 m) | meuble | chaise lourde de bord à pied vissé au plancher, cuir brun |
| 3 | `assets/hd2d/interior/props/tea_set_tiny.png` | 48 × 24 (0,5 × 0,25 m) | objet posé sur une table | théière de fonte et tasses minuscules, une serviette pliée à côté (V1) |
| 3 | `assets/hd2d/interior/window_porthole.png` | 58 × 58 (0,6 m) | fenêtre, appui à 1,2 m | hublot rond riveté de laiton, verre épais, les nuages derrière |
| 3 | `assets/hd2d/interior/door_bulkhead.png` | 106 × 211 (1,1 × 2,2 m) | porte | porte étanche de tôle à coins arrondis, volant de fermeture, seuil haut |
| 3 | `assets/hd2d/interior/props/ship_ladder.png` | 96 × 288 (1 × 3 m) | meuble (sortie vers le pont supérieur) | échelle de coupée de fer raide vers une écoutille ouverte au plafond, mains courantes |
| 3 | `assets/hd2d/interior/wallitem_ship_pipes.png` | 192 × 96 (2 × 1 m) | élément de mur, bas à 1,6 m | tuyaux de cuivre, vannes à volant, deux manomètres sans chiffres, un porte-voix |
| 3 | `assets/hd2d/interior/wallitem_garde_emblem.png` | 77 × 77 (0,8 m) | élément de mur, bas à 1,5 m | aile stylisée de la Garde ailée peinte en rouge (#AE4A3E) sur une plaque de tôle ; aucun texte |
| 3 | `assets/hd2d/interior/props/map_cabinet.png` | 115 × 106 (1,2 × 1,1 m) | meuble | meuble à cartes à larges tiroirs plats, rouleaux de cartes dessus |
| 3 | `assets/hd2d/interior/wallitem_speaking_tube.png` | 29 × 58 (0,3 × 0,6 m) | élément de mur, bas à 1,4 m | porte-voix de cuivre en pavillon au bout d'un tuyau, bouchon à chaînette |

Le pont où l'on marche (panneaux posés sur `<navire>_deck.png`) :

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/props/deck_railing.png` | 192 × 106 (2 × 1,1 m) | panneau, sans raccord à gauche et à droite | bastingage de fer riveté avec main courante et filières, peinture gris-bleu écaillée |
| 3 | `assets/hd2d/props/deck_hatch.png` | 115 × 58 (1,2 × 0,6 m) | panneau | écoutille fermée à surbau de tôle et volant |
| 3 | `assets/hd2d/props/deck_vent.png` | 58 × 134 (0,6 × 1,4 m) | panneau | manche à air de bord en col de cygne, peinte en rouge à l'intérieur |
| 3 | `assets/hd2d/props/deck_bridge.png` | 384 × 288 (4 × 3 m) | panneau | la passerelle de commandement vue depuis le pont : cabine de tôle et de verre, vitres en bandeau, porte étanche, barre visible à travers les vitres |
| 3 | `assets/hd2d/props/deck_crates_lashed.png` | 154 × 115 (1,6 × 1,2 m) | panneau | caisses de la Garde arrimées sous un filet de cordage, sangles, aile peinte sans texte |

## 7. Lot M : la nature et la faune

### 7.1 Rappel du format (à coller avec le lot)

Chaque ligne donne le chemin complet (`assets/hd2d/…` ; la faune dans `assets/fauna/`).
Genres, comme aux cahiers n° 1 et 2 :
- **panneau** (`props/`) : debout, vu de face légèrement plongeant, fond transparent, collé au
  bord bas et centré ; **premier plan** : grandes masses sombres et contrastées, peu de petits
  détails (le flou de profondeur du jeu les adoucit) ;
- **lisière** : pan de forêt de 16 m (1536 px), plusieurs profondeurs, bords gauche et droit qui
  s'enchaînent, bas collé au sol sur toute la largeur ;
- **décalque** (`decals/`) : vu strictement de dessus, fond transparent, bord irrégulier et
  effiloché qui se fond dans n'importe quel sol, ancre au centre ;
- **tuile de sol** (`ground/`) : 384 × 384, vue de dessus, opaque, sans raccord sur les quatre
  bords ; **face de palier** (`cliff/`) : de face, opaque, sans raccord à gauche et à droite ;
- **lointain** (`sky/`) : 48 px/m, teintes adoucies et violacées par la distance, le pied des
  montagnes collé au bord bas ;
- **bande animée** (`anim/`) : `n` images côte à côte, boucle sans saut ; ce qui vole est centré
  dans chaque image ;
- **planche d'animal** : le format des personnages (lot J, section 4.1), trois vues, tourné vers
  la droite.

**L'esprit des lieux.** Une forêt dense couvre presque toute l'île, semée de marais de toutes
tailles dans ses trouées (VEX, « Cinq cents ans ») ; aucun nom d'arbre dans l'œuvre : on garde les
essences du cahier n° 2 (chênes, hêtres, bouleaux, érables, sapins, saules). La nuit, le sentier
est si couvert qu'on ne voit pas ses pieds ; le marais sent l'eau, la terre et le vent (V1,
« L'Homme sans Marque ») ; des fourrés aux petites branches qui percent la peau, des bosquets
profonds (V1, « Entrepôt de fées ») ; de l'eau cachée dans des creux, dangereuse pour les enfants
(V5, épilogue) ; une montagne où vivent les ours, qui hibernent l'hiver (V2, « Qu'est-il advenu de
la promesse ? » ; V5) ; une rivière où l'on puise l'eau du bain (V3). Les lisières, arbres, plantes,
rochers et décalques du cahier n° 2 restent ; ce lot ajoute ce qui manque.

**Références à joindre** : `assets/hd2d/props/tree_autumn.png`, `forest_wall_a.png`,
`bear_rock.png`, `willow.png`, `assets/hd2d/decals/lily_pads.png`,
`assets/hd2d/ground/forest_floor.png`.

**Consigne** : colle le bloc de style, ce rappel, puis « Image `<chemin>`, <taille> px, <genre> : »
et la description de la ligne.

### 7.2 Le sentier sans lumière

Un sentier étroit qui s'enfonce dans une forêt noire, sans lampadaire ni aucune lumière (V1,
« L'Homme sans Marque ») ; un petit sentier forestier aux pierres clairsemées et mal entretenues,
envahies de mauvaises herbes, où l'on ne se perd pas tant qu'on le suit (V3, « Je suis à la
maison »).

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/ground/path_overgrown.png` | 384 × 384 | tuile de sol, **à confirmer par le moteur** (une 28e couche dans l'atlas du sol, lot E2) | sentier étroit de terre tassée envahi d'herbe : deux bandes de terre usée par les pas, herbe et mousse au milieu et sur les bords, racines, feuilles mortes |
| 2 | `assets/hd2d/decals/path_stones_a.png` | 192 × 144 (2 × 1,5 m) | décalque | pierres plates clairsemées et mal posées, à demi enfoncées, herbe et mauvaises herbes dans les interstices (V3) |
| 2 | `assets/hd2d/decals/path_stones_b.png` | 144 × 96 (1,5 × 1 m) | décalque | deux pierres plates seules, l'une fendue, mangées par l'herbe |
| 2 | `assets/hd2d/props/path_edge_ferns.png` | 384 × 106 (4 × 1,1 m) | panneau, sans raccord à gauche et à droite | bordure basse et serrée de fougères, d'herbes hautes et de ronces qui étrangle le sentier |
| 2 | `assets/hd2d/props/fg_canopy_a.png` | 768 × 384 (8 × 4 m) | premier plan **suspendu** (accroché par le haut, ancre libre), **format à confirmer par le moteur** | masse de feuillage sombre qui pend du haut de l'image, vue d'en dessous : la voûte au-dessus du sentier, branches, feuilles d'automne presque noires, quelques trouées par où passent les étoiles (V1) |
| 3 | `assets/hd2d/props/fg_canopy_b.png` | 576 × 288 (6 × 3 m) | premier plan suspendu, **à confirmer** | même chose, plus clairsemé, une grosse branche en travers |
| 3 | `assets/hd2d/props/path_root_step.png` | 192 × 58 (2 × 0,6 m) | panneau | grosse racine moussue en travers du sentier, qui fait marche |

### 7.3 Le marais de nuit et les mares cachées

Willem s'écarte du sentier et a les pieds dans l'eau ; il tombe à la renverse dans une grande gerbe
(V1, « L'Homme sans Marque ») ; plus tard, une épée projetée dans un marais en ressort couverte de
boue jusqu'à la garde (VEX, « L'endroit où je veux retourner »). Autour de l'entrepôt, des marécages
sombres de toutes formes (même source) ; dans la forêt, de l'eau qui s'accumule dans des creux
difficiles à voir (V5, épilogue).

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/props/marsh_hummock_a.png` | 115 × 77 (1,2 × 0,8 m) | panneau | touradon : grosse motte d'herbe dure et de carex qui sort de l'eau noire, le pied mouillé |
| 3 | `assets/hd2d/props/marsh_hummock_b.png` | 86 × 58 (0,9 × 0,6 m) | panneau | touradon plus petit, à moitié couché |
| 2 | `assets/hd2d/props/marsh_snag.png` | 192 × 192 (2 × 2 m) | panneau | souche noyée, branches mortes grises qui sortent de l'eau, mousse et champignons |
| 2 | `assets/hd2d/props/marsh_reed_wall.png` | 384 × 192 (4 × 2 m) | panneau, sans raccord à gauche et à droite | rideau dense de roseaux pâles (#9C9563) et de massettes brunes, quelques tiges cassées |
| 2 | `assets/hd2d/decals/bog_pool_a.png` | 288 × 192 (3 × 2 m) | décalque | mare de tourbe à l'eau noire (#4A675F assombri), bord de sphaignes rouges et vertes, quelques reflets d'étoiles en points clairs |
| 3 | `assets/hd2d/decals/bog_pool_b.png` | 192 × 144 (2 × 1,5 m) | décalque | mare plus petite, allongée, lentilles d'eau sur un bord |
| 2 | `assets/hd2d/props/alder.png` | 384 × 672 (4 × 7 m) | panneau | aulne du marais : tronc sombre penché, racines qui plongent dans l'eau, feuillage vert-brun clairsemé d'automne |
| 3 | `assets/hd2d/props/willow_pollard.png` | 288 × 384 (3 × 4 m) | panneau | saule têtard : tronc court noueux, tête hérissée de longs rameaux jaunes |
| 2 | `assets/hd2d/decals/hidden_pool_a.png` | 192 × 144 (2 × 1,5 m) | décalque | petite mare dans un creux, presque couverte de feuilles mortes flottantes : on devine à peine l'eau noire entre les feuilles, bord de mousse (V5 : le danger qu'on ne voit pas) |
| 3 | `assets/hd2d/decals/hidden_pool_b.png` | 144 × 115 (1,5 × 1,2 m) | décalque | même chose, plus petite, une branche tombée en travers |
| 3 | `assets/hd2d/props/pool_ferns.png` | 192 × 115 (2 × 1,2 m) | panneau | fougères penchées au-dessus d'une mare, leurs frondes qui touchent l'eau (le bas de l'image est le bord de l'eau) |

### 7.4 Fourrés et bosquets profonds

Le champ de ballon est bordé d'un bosquet profond et de fourrés où le ballon se perd ; une petite y
plonge et se lacère la cuisse sur les branches (V1, « Entrepôt de fées »). Chtholly s'enfuit dans la
forêt quand c'est trop (VEX, « Des émotions sans nom ») : son refuge est **(original)**.

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/thicket_a.png` | 240 × 154 (2,5 × 1,6 m) | panneau | fourré de prunellier et d'aubépine : petites branches épineuses enchevêtrées, baies sombres, feuilles rousses ; dense, on n'y voit pas à travers |
| 1 | `assets/hd2d/props/thicket_b.png` | 192 × 134 (2 × 1,4 m) | panneau | fourré plus bas et plus large, ronces mêlées |
| 2 | `assets/hd2d/props/thicket_c.png` | 288 × 173 (3 × 1,8 m) | panneau | grand fourré avec un trou sombre au ras du sol (là où roule le ballon, où plonge une petite) |
| 1 | `assets/hd2d/props/bramble_hedge.png` | 384 × 144 (4 × 1,5 m) | panneau, sans raccord à gauche et à droite | haie de ronces et d'églantiers qui borde le champ, mûres noires, cynorhodons rouges |
| 2 | `assets/hd2d/props/grove_dense.png` | 768 × 864 (8 × 9 m) | panneau | bosquet profond : trois arbres serrés (chêne, hêtre, sapin), taillis, lierre, ombre dense au pied ; on n'y voit que la pénombre |
| 2 | `assets/hd2d/props/forest_wall_deep.png` | 1536 × 1056 (16 × 11 m) | lisière, raccord à gauche et à droite | forêt profonde et sombre : vieux chênes moussus et sapins à trois profondeurs, troncs couverts de lierre, très peu de lumière, sous-bois de fougères noires |
| 3 | `assets/hd2d/props/refuge_oak.png` | 768 × 960 (8 × 10 m) | panneau | le refuge de Chtholly **(original)** : un énorme vieux chêne creux, racines comme des bras, un creux à sa base où une fée peut s'asseoir à l'abri, feuillage or et rouille |
| 3 | `assets/hd2d/props/fallen_pine.png` | 576 × 154 (6 × 1,6 m) | panneau | sapin abattu par le vent, couché en travers vers la droite, motte de racines à gauche, aiguilles rousses |
| 3 | `assets/hd2d/props/rowan.png` | 288 × 480 (3 × 5 m) | panneau | sorbier aux grappes de baies rouge vif et au feuillage orangé, tronc gris fin |

### 7.5 La montagne et la rivière

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/sky/mountain_backdrop_a.png` | 2048 × 512 (42 × 10 m à 48 px/m) | lointain, raccord à gauche et à droite | la montagne de l'île en arrière-plan : pentes couvertes de sapins sombres, crêtes de roche claire, premières neiges sur les sommets, adoucie et violacée par la distance (V2 ; V5) |
| 3 | `assets/hd2d/sky/mountain_backdrop_b.png` | 2048 × 512 | lointain, raccord | même chaîne sous un autre angle : une gorge, une cascade lointaine en fil blanc |
| 3 | `assets/hd2d/props/mountain_pine_a.png` | 240 × 576 (2,5 × 6 m) | panneau | sapin de montagne tordu par le vent, branches d'un seul côté, écorce grise |
| 3 | `assets/hd2d/props/mountain_pine_b.png` | 192 × 432 (2 × 4,5 m) | panneau | petit sapin rabougri sur un rocher, racines à nu |
| 3 | `assets/hd2d/props/boulder_mountain_a.png` | 384 × 288 (4 × 3 m) | panneau | gros rocher gris anguleux, lichens jaunes et gris, une fissure |
| 3 | `assets/hd2d/props/boulder_mountain_b.png` | 240 × 192 (2,5 × 2 m) | panneau | rocher plus petit, posé de travers sur des éboulis |
| 3 | `assets/hd2d/decals/scree.png` | 288 × 192 (3 × 2 m) | décalque | éboulis de pierres grises anguleuses de 5 à 30 cm |
| 3 | `assets/hd2d/props/bear_den.png` | 384 × 288 (4 × 3 m) | panneau | tanière d'ours : entrée sombre sous un surplomb de rocher et de racines, feuilles tassées au seuil ; aucun os, aucun sang (les ours y hibernent, V2) |
| 3 | `assets/hd2d/props/rock_overhang.png` | 480 × 336 (5 × 3,5 m) | panneau | surplomb rocheux moussu sous lequel on peut s'abriter, fougères au pied |
| 3 | `assets/hd2d/cliff/cliff_mountain.png` | 384 × 384 | tuile, sans raccord sur les quatre bords | paroi de falaise de montagne, comme `cliff.png` mais grise et sombre, strates verticales, lichens, une touffe d'herbe |
| 3 | `assets/hd2d/ground/river_water.png` | 384 × 384 | tuile de sol, **à confirmer par le moteur** (lot E2) | eau de rivière courante, plus profonde que `stream_bed.png` : vert sombre et bleu-gris, reflets clairs en traits allongés dans le sens horizontal (le courant), quelques galets devinés au fond |
| 3 | `assets/hd2d/props/river_bank.png` | 384 × 96 (4 × 1 m) | panneau, sans raccord à gauche et à droite | berge de galets ronds et de racines vue de face, le bas de l'image au ras de l'eau (V3 : on puise l'eau du bain à la rivière) |
| 3 | `assets/hd2d/anim/river_rapids.png` | 192 × 96 (2 × 1 m), 4 images, 8 ips | bande animée | remous blancs et écume autour d'un rocher à fleur d'eau, le rocher immobile |
| 3 | `assets/hd2d/anim/small_waterfall.png` | 192 × 288 (2 × 3 m), 6 images, 10 ips | bande animée, **alpha doux** sur les bords | petite cascade de torrent sur des rochers moussus, eau claire et écume ; le haut de l'image est la lèvre de pierre |
| 3 | `assets/hd2d/props/log_bridge_b.png` | 384 × 96 (4 × 1 m) | panneau | tronc équarri jeté en passerelle au-dessus d'un torrent, une main courante de corde |
| 3 | `assets/hd2d/decals/animal_tracks.png` | 144 × 192 (1,5 × 2 m) | décalque | empreintes de cerf et de sanglier mêlées dans la boue, qui traversent l'image de bas en haut |

### 7.6 Paliers et talus (format à confirmer par le moteur, lot E2)

Le sol des nouvelles cartes monte par paliers de 0,5 m (`docs/REFONTE.md`, section 7.1) ; le lot
E2 habille leurs faces d'images. Faces vues de face, opaques, **sans raccord à gauche et à
droite**, le haut de l'image au niveau du palier supérieur, le bas au niveau du palier inférieur.

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/cliff/step_earth.png` | 384 × 48 (4 × 0,5 m) | face de palier | talus de terre brune d'un demi-mètre, racines fines, cailloux, touffes d'herbe qui débordent du haut |
| 2 | `assets/hd2d/cliff/step_rock.png` | 384 × 48 | face de palier | petite marche de roche claire (#C2B49F) en strates, mousse dans les fissures |
| 2 | `assets/hd2d/cliff/wall_earth_1m.png` | 384 × 96 (4 × 1 m) | face de palier | talus de terre d'un mètre, grosses racines qui sortent, fougères accrochées |
| 3 | `assets/hd2d/cliff/wall_rock_1m.png` | 384 × 96 | face de palier | ressaut de roche d'un mètre, lichen, une fissure avec une fougère |
| 2 | `assets/hd2d/cliff/step_marsh.png` | 384 × 48 | face de palier | berge de tourbe noire et de racines au bord d'un marais, herbe qui retombe |
| 3 | `assets/hd2d/cliff/step_drystone.png` | 384 × 48 | face de palier | muret de pierres sèches d'un demi-mètre (bord de champ, village) |

### 7.7 La faune

Ce que dit l'œuvre : des **ours** dans les montagnes, chassés par Nygglatho et qui hibernent l'hiver
(V2 ; V5 ; VEX) ; des **oiseaux** bruyants au matin (V3) ; un petit animal grimpeur poursuivi par
une fillette (V5, épilogue) ; des **papillons orange** (ill. VEX) ; des **loups**, seulement une
crainte de Willem (V1). Ce qu'on ajoute (original) : loups de la forêt profonde, sangliers, cerfs,
renards, écureuils, grenouilles, corbeaux, une chouette, des libellules (`docs/REFONTE.md`,
section 4.4). On ne les croise ni à l'entrepôt, ni au village, ni en ville. **Jamais de sang** : une
bête vaincue s'enfuit ou reste couchée, sans blessure visible.

**Planches** (`assets/fauna/<id>/<id>.png` + `.json`, `_front`, `_back`) : format des personnages
(4.1), trois vues, profil tourné vers la droite, mêmes animations dans les trois vues. La
« hauteur au repos » est celle de la 1re image de `repos`, de l'ancre (le sol sous les pattes) au
point le plus haut de la silhouette (oreilles, bois). Animations (`docs/REFONTE.md`, 8.1) :
`repos`, `marche`, `course` pour tous ; `attaque` (avec `coup`), `degats` et `mort` pour les bêtes
dangereuses ; `fuite` (envol, bond) pour les oiseaux et le petit gibier. **Les nombres d'images et
les cadences ci-dessous sont proposés : à confirmer par le moteur** (lot E5), comme `broute`.

| Animation | Images | ips | Boucle | Consigne commune |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | à l'arrêt sur ses pattes, la tête qui bouge un peu (oreille, regard), respiration |
| `marche` | 6 | 8 | oui | pas lent à quatre pattes (pattes en diagonale) ; oiseaux et grenouille : 4 images de petits sauts |
| `course` | 5 | 14 | oui | galop, pattes rassemblées puis étendues ; oiseaux et grenouille : 4 images de bonds rapides |
| `attaque` | 4 | 12 | non | 0 ramassé ; 1 élan ; 2 **coup** (coup de patte, morsure, coup de boutoir) ; 3 retour ; `coup` : [2] |
| `degats` | 1 | 1 | non | touché, il recule, tête rentrée |
| `mort` | 2 | 4 | non | 0 il vacille ; 1 couché sur le flanc, immobile, les yeux fermés ; aucun sang |
| `fuite` | 4 | 12 | oui (oiseaux), non (les autres) | oiseaux : envol puis battements d'ailes sur place (le jeu le déplace) ; renard, écureuil : grand bond vers la droite ; grenouille : plongeon |
| `broute` | 4 | 4 | oui | **nom proposé** : la tête baissée au ras du sol, il broute, relève la tête à l'image 3 |

| Prio | Planche | Hauteur au repos | Animations | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `bear/bear` | 115 px (1,2 m à quatre pattes ; 2,2 m de long) | `repos`, `marche`, `course`, `attaque`, `degats`, `mort` | ours brun massif, pelage d'automne épais brun-roux plus sombre aux pattes, bosse aux épaules ; `attaque` : il se dresse à moitié et frappe de la patte (l'image 2 dépasse la hauteur au repos) ; `mort` : couché sur le flanc, comme endormi |
| 3 | `wolf/wolf` | 82 px (0,85 m ; 1,5 m de long) | `repos`, `marche`, `course`, `attaque`, `degats`, `mort` | loup gris aux flancs fauves, queue basse, regard jaune ; ils vont en meute au crépuscule dans la forêt profonde ; `attaque` : bond et morsure |
| 3 | `boar/boar` | 86 px (0,9 m ; 1,5 m de long) | `repos`, `marche`, `course`, `attaque`, `degats`, `mort`, `broute` | sanglier noir-brun aux soies hérissées sur l'échine, défenses courtes ; `attaque` : charge tête baissée et coup de boutoir ; `broute` : il fouille le sol du groin |
| 3 | `deer/deer` | 182 px (1,9 m bois compris ; 2 m de long) | `repos`, `marche`, `course`, `broute` | cerf roux d'automne aux grands bois ; paisible, il s'enfuit au galop (sa `course`) |
| 3 | `fox/fox` | 43 px (0,45 m ; 1,1 m queue comprise) | `repos`, `marche`, `course`, `fuite` | renard roux à gorge blanche et pattes noires, queue en panache ; `fuite` : un bond dans les fourrés |
| 3 | `squirrel/squirrel` | 24 px (0,25 m, assis) | `repos`, `marche`, `course`, `fuite` | écureuil roux, queue en panache, oreilles à pinceaux ; `repos` : assis, une noisette dans les pattes ; `fuite` : il bondit et file vers le haut, comme vers un tronc (V5 : le petit animal grimpeur) |
| 3 | `frog/frog` | 12 px (0,12 m) | `repos`, `marche`, `course`, `fuite` | grenouille verte et brune du marais, gorge qui palpite au `repos` ; `fuite` : plongeon (image 3 : il ne reste qu'une petite gerbe) |
| 3 | `crow/crow` | 38 px (0,4 m) | `repos`, `marche`, `course`, `fuite` | corbeau noir aux reflets bleutés, bec fort ; `repos` : il tourne la tête ; `fuite` : envol lourd |
| 2 | `blackbird/blackbird` | 19 px (0,2 m) | `repos`, `marche`, `course`, `fuite` | merle noir au bec jaune (les oiseaux bruyants du matin, V3) ; `repos` : il chante, bec ouvert à l'image 1 |
| 3 | `owl/owl` | 38 px (0,4 m) | `repos`, `fuite` | chouette hulotte brun-roux aux grands yeux noirs, pour la nuit (original) ; `repos` : la tête qui pivote ; `fuite` : envol silencieux |

Les insectes restent des **bandes animées** (`anim/`, format du cahier n° 2), comme le papillon déjà
livré (`anim/butterfly.png`) : centrés dans chaque image, marge transparente tout autour.

| Prio | Fichier | Une image (px) | Images, ips | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/anim/butterfly_orange_b.png` | 24 × 24 | 4, 12 | autre papillon orange vu de dessus, ailes plus arrondies bordées de brun, qui bat des ailes (ill. VEX : les papillons orange dans les hautes herbes) |
| 3 | `assets/hd2d/anim/dragonfly_blue.png` | 32 × 24 | 4, 16 | libellule bleue vue de dessus, ailes transparentes nervurées (alpha net), qui vibrent |
| 3 | `assets/hd2d/anim/dragonfly_amber.png` | 32 × 24 | 4, 16 | libellule ambrée vue de dessus, même mouvement |

## 8. Lot N : le temps et la lumière

### 8.1 Rappel du format (à coller avec le lot)

Les grandes scènes du volume 1 sont de nuit ou sous la pluie (`docs/REFONTE.md`, lot E9). Le jeu
fait le matin, l'après-midi, le couchant, la nuit, la pluie fine et l'averse par l'étalonnage de
l'image ; ce lot lui donne les ciels, la pluie et les lumières. Chemins complets à chaque ligne.
Genres :
- **ciel** (`sky/`) : panorama équirectangulaire de 2048 × 1024 (360° × 180°), horizon à
  mi-hauteur, **raccord gauche-droite**, au cadrage de `sky.png` (l'ouest dans le quart gauche,
  l'est dans le quart droit) ; sous l'horizon, la mer de nuages ; opaque ;
- **mer de nuages** (`sky/`) : 1024 × 1024 vue de dessus, sans raccord sur les quatre bords,
  comme `cloud_sea.png` ;
- **nuage** (`sky/`) : à 48 px/m, **alpha doux**, centré, marge transparente tout autour ;
- **bande animée** (`anim/`) : `n` images côte à côte, sans marge, boucle sans saut ; la pluie et
  la lumière sont en **alpha doux** ;
- **vitre éclairée**, **fenêtre de nuit** : de face, fond transparent, au cadrage exact de la
  fenêtre de jour qu'elle remplace ou qu'elle recouvre ;
- **décalque de lumière** (`decals/`) : vu de dessus, alpha doux.

Contrairement au reste du cahier, ces images **disent leur heure** : leur lumière est dessinée.

**Références à joindre** : `assets/hd2d/sky/sky.png`, `sky_night.png`, `cloud_sea.png`,
`cloud_a.png` ; pour les fenêtres, `assets/hd2d/buildings/warehouse_main.png` et les fenêtres de
jour du lot I.

**Consigne** : colle le bloc de style, ce rappel, puis « Image `<chemin>`, <taille> px, <genre> : »
et la description de la ligne.

### 8.2 Ciels, mer de nuages et nuages de pluie

L'automne de l'île : un matin couvert de nuages de pluie, comme toujours, que la lueur du matin
traverse avant un bleu d'automne sans nuages (V1, « Les valeureux et leurs successeurs ») ; un jour
nuageux où la pluie menace (VEX, « Des émotions sans nom ») ; des averses soudaines sous des nuages
couleur de cendre, nuit noire en plein jour (V2, « De ce côté-ci de l'écran ») ; la nuit de
l'arrivée, vent violent qui hurle sous un ciel étoilé (V1, « L'Homme sans Marque ») ; des comètes
dans le ciel du nord (V3, « Des journées chaudes… »). Restent : `sky.png` (fin d'après-midi),
`sky_dusk.png` (couchant), `sky_night.png` (nuit claire, voie lactée, la nuit de la colline).

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/sky/sky_morning.png` | 2048 × 1024 | ciel | matin d'automne : ciel couvert de nuages de pluie gris-mauve en couches, que la lueur du matin perce à l'est (quart droit) d'une bande d'or pâle et de rose ; en bas, la mer de nuages grise et rosée |
| 1 | `assets/hd2d/sky/sky_day.png` | 2048 × 1024 | ciel | après-midi clair : bleu d'automne presque sans nuages, plus pâle vers l'horizon, soleil haut et blanc-or, quelques cirrus fins ; la mer de nuages blanche et lumineuse en dessous |
| 2 | `assets/hd2d/sky/sky_overcast.png` | 2048 × 1024 | ciel | jour nuageux, la pluie menace : plafond gris cendre uniforme et bas, quelques nuages plus sombres qui pendent, lumière plate sans soleil ; mer de nuages grise |
| 1 | `assets/hd2d/sky/sky_rain.png` | 2048 × 1024 | ciel | averse : nuages couleur de cendre très sombres (#7D7F86 et plus sombre), presque la nuit en plein jour, traînées de pluie qui tombent au loin en rideaux obliques, une éclaircie pâle tout au fond |
| 1 | `assets/hd2d/sky/sky_night_wind.png` | 2048 × 1024 | ciel | la nuit de l'arrivée : ciel bleu nuit (#2E3552) plein d'étoiles, des nuages déchirés par le vent qui filent en lambeaux sombres devant elles, pas de lune ; mer de nuages noire et argentée |
| 3 | `assets/hd2d/sky/sky_night_comets.png` | 2048 × 1024 | ciel | nuit d'hiver claire et vive, étoiles très denses, deux comètes à longue queue pâle au nord (au milieu de l'image) (V3) |
| 1 | `assets/hd2d/sky/cloud_sea_night.png` | 1024 × 1024 | mer de nuages | la mer de nuages la nuit, vue de dessus : crêtes argentées par les étoiles, creux indigo, profondeurs presque noires, quelques trouées |
| 2 | `assets/hd2d/sky/cloud_sea_rain.png` | 1024 × 1024 | mer de nuages | la mer de nuages sous la pluie : crêtes gris cendre ternes, creux mauve sombre, nappes de bruine |
| 3 | `assets/hd2d/sky/cloud_sea_morning.png` | 1024 × 1024 | mer de nuages | la mer de nuages au matin : crêtes pêche pâle et gris rosé, creux lavande froid |
| 2 | `assets/hd2d/sky/cloud_rain_a.png` | 768 × 256 (à 48 px/m) | nuage, **alpha doux** | gros nuage de pluie gris, base plate et sombre d'où pendent des traînées de pluie |
| 2 | `assets/hd2d/sky/cloud_rain_b.png` | 576 × 192 (à 48 px/m) | nuage, **alpha doux** | nuage de pluie plus petit, effiloché, gris-mauve |

### 8.3 Pluie, gouttes et flaques

Une pluie fine au crépuscule sur le port (V1, « Entrepôt de fées ») ; des averses qui tombent comme
un seau renversé ; il pleut à verse à l'aube, puis tout s'arrête net avant midi et le terrain reste
boueux (V2, « L'écoulement du temps depuis lors »).

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/rain_curtain.png` | 384 × 384 (4 × 4 m), 4 images, 12 ips | bande animée, **alpha doux**, chaque image **sans raccord sur les quatre bords**, **format à confirmer par le moteur** (E9) | averse : traits de pluie fins et obliques (vers la droite en tombant), gris clair à 30-60 % d'opacité, de longueurs variées ; d'une image à l'autre, chaque trait descend d'un quart de l'image, la boucle tombe sans saut |
| 1 | `assets/hd2d/anim/rain_drizzle.png` | 384 × 384, 4 images, 10 ips | bande animée, alpha doux, sans raccord, **à confirmer** (E9) | pluie fine : traits courts, plus rares et plus pâles (20 à 40 %), presque verticaux |
| 1 | `assets/hd2d/anim/rain_splash.png` | 48 × 24 (0,5 × 0,25 m), 4 images, 12 ips, non bouclée | bande animée, ancre au milieu du bas | une goutte qui s'écrase au sol : petite couronne d'eau qui jaillit puis retombe ; image 3 presque vide |
| 2 | `assets/hd2d/anim/eave_drip.png` | 48 × 192 (0,5 × 2 m), 4 images, 8 ips | bande animée, suspendue (le haut de l'image est l'égout du toit) | trois gouttes qui tombent d'un bord de toit à des moments décalés, sur toute la hauteur de l'image |
| 1 | `assets/hd2d/anim/puddle_rain_a.png` | 192 × 115 (2 × 1,2 m), 4 images, 8 ips | décalque animé, vu de dessus, **format à confirmer par le moteur** (E9) | flaque d'eau boueuse sous la pluie : petits cercles qui naissent et s'élargissent à des endroits différents d'une image à l'autre, reflets gris du ciel, bord de boue sombre irrégulier |
| 2 | `assets/hd2d/anim/puddle_rain_b.png` | 134 × 96 (1,4 × 1 m), 4 images, 8 ips | décalque animé, **à confirmer** | petite flaque sous la pluie, même mouvement |

### 8.4 Fenêtres de nuit

**Dehors**, les fenêtres éteintes des nouvelles façades du lot K s'allument la nuit : ces **vitres
éclairées** se posent exactement sur elles (seulement les carreaux et les croisillons, pas le
cadre ni le mur). Les façades des cahiers n° 1 et 2, elles, ont leurs fenêtres toujours éclairées.
**Dedans**, les fenêtres du lot I ont leur version de nuit, au même cadrage au pixel près : la nuit,
la fenêtre de Willem ne montre qu'un noir profond (V1, « L'Homme sans Marque »).
**(Format à confirmer par le moteur, lot E9.)**

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/props/window_lit_small.png` | 77 × 96 (0,8 × 1 m) | vitre éclairée | carreaux d'une petite fenêtre à croisillons (six carreaux) éclairés de l'intérieur d'un jaune chaud (#FFE6A6), plus clair au centre, croisillons sombres ; rien autour |
| 2 | `assets/hd2d/props/window_lit_large.png` | 134 × 134 (1,4 × 1,4 m) | vitre éclairée | carreaux d'une grande fenêtre à croisillons (neuf carreaux) éclairés, l'ombre d'un rideau sur un côté |
| 3 | `assets/hd2d/props/window_lit_round.png` | 58 × 58 (0,6 m) | vitre éclairée | œil-de-bœuf éclairé, croisillon en croix |
| 1 | `assets/hd2d/interior/window_cross_small_night.png` | 77 × 96 | fenêtre, appui à 1 m | `window_cross_small.png` (jointe) la nuit : même cadre au pixel près, vitres bleu nuit presque noires (#2E3552), un reflet froid de la lampe en diagonale, deux étoiles |
| 1 | `assets/hd2d/interior/window_cross_large_night.png` | 230 × 173 | fenêtre, appui à 0,8 m | `window_cross_large.png` (jointe) la nuit : vitres bleu nuit, reflet de la suspension à cristal, la silhouette noire des arbres |
| 1 | `assets/hd2d/interior/window_reading_seat_night.png` | 192 × 211 | fenêtre posée au sol | `window_reading_seat.png` (jointe) la nuit : vitres bleu nuit et étoiles, banquette dans la pénombre |
| 2 | `assets/hd2d/interior/window_curtains_open_night.png` | 115 × 154 | fenêtre, appui à 0,8 m | `window_curtains_open.png` (jointe) la nuit : vitres bleu nuit, rideaux plus sombres |
| 2 | `assets/hd2d/interior/window_bare_night.png` | 106 × 134 | fenêtre, appui à 0,7 m | `window_bare.png` (jointe) la nuit : vitres d'un noir profond bleuté, sans étoile, un seul reflet (V1) |

### 8.5 Lumières

Les fées font une petite lumière magique dans la main ; la nuit du marais, une lumière qui
zigzague annonce Pannibal, puis Chtholly arrive avec la sienne (V1, « L'Homme sans Marque »). Sur la
colline, les quarante et un talismans de Seniorious flottent autour d'un petit cristal comme une
lumière d'étoiles et tintent comme un métallophone (V1, « Le ciel étoilé sous le ciel étoilé »). Le
transport de la Garde descend précédé d'une lumière si forte qu'on ne voit pas sa silhouette (V1,
« Entrepôt de fées »). La lueur du matin passe par la fenêtre (V1, « Les valeureux… »).

| Prio | Fichier | Taille (px) | Genre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/fairy_light.png` | 48 × 48 (0,5 m), 4 images, 6 ips | bande animée, **alpha doux**, centrée | petite lumière magique de fée : orbe blanc bleuté au cœur presque blanc, halo doux, deux ou trois étincelles qui tournent autour ; elle pulse d'une image à l'autre |
| 2 | `assets/hd2d/anim/talisman_float.png` | 24 × 24 (0,25 m), 4 images, 6 ips | bande animée, centrée | un éclat de talisman : fragment de métal blanc gravé qui flotte et tourne lentement sur lui-même en luisant comme une étoile (le halo en alpha doux) |
| 2 | `assets/hd2d/sky/ship_searchlight.png` | 384 × 768 (4 × 8 m) | lointain, **alpha doux**, ancre libre | cône de lumière blanche très forte qui descend à travers les nuages, plus intense en haut, qui s'élargit vers le bas ; aucun navire dessiné (V1) |
| 1 | `assets/hd2d/decals/sun_window.png` | 192 × 144 (2 × 1,5 m) | décalque de lumière, **alpha doux** | tache de soleil sur un parquet à travers une fenêtre à croisillons : rectangle de lumière dorée (#FFE6A6, 30 à 50 %) découpé par l'ombre des croisillons, étiré en biais vers la droite |
| 2 | `assets/hd2d/decals/moon_window.png` | 192 × 144 | décalque de lumière, **alpha doux** | la même tache la nuit : lumière bleu pâle (20 à 35 %), contours plus doux |

## 9. Commander, garder la cohérence, vérifier

### 9.1 Ordre de commande

Une conversation (ou une PR de livraison) par lot ; dans chaque lot, la priorité 1 d'abord. L'ordre
suit les phases de la refonte (`docs/REFONTE.md`, section 9) :

| Étape | Quoi | Pour quoi |
| --- | --- | --- |
| 1 | **Lot I**, priorité 1 (matières, portes et fenêtres, mobilier des pièces du rez-de-chaussée, de la chambre de Nygglatho, de celle de Willem et des chambres des fées) | la tranche « l'entrepôt » : l'intérieur complet des jours 1 à 4 |
| 2 | **Lot J**, priorité 1 : les cinq `_life` des petites, les trois `_home` des aînées, `willem_home`, `willem_cook`, `willem_coat`, `nygglatho_life`, `nygglatho_tea`, les six premières fées génériques, les pyjamas des quatre petites | la vie de l'entrepôt : jeux, repas, dessert spécial, nuit d'arrivée |
| 3 | **Lot N**, priorité 1 : `sky_morning`, `sky_day`, `sky_rain`, `sky_night_wind`, `cloud_sea_night`, la pluie, les fenêtres de nuit de l'intérieur, la lumière des fées, le soleil par la fenêtre | le jour 1 se joue de nuit, le jour 6 sous la pluie |
| 4 | **Lot I** et **lot J**, priorité 2 ; **lot M**, priorités 1 et 2 (sentier, marais, fourrés, paliers) | fin de la tranche, puis les jours 5 à 8 |
| 5 | **Lot L**, priorité 2 (port, transport de la Garde) ; **lot K**, priorité 2 (village, café, maison Limashenka, snack-bar, café de la ville) | les jours 5 à 12 : le port sous la pluie, le café du village, l'horloge |
| 6 | **Lots K, L, M** et **N**, priorité 3 ; **lot J**, priorité 3 (hommes-bêtes, visiteurs, bâton) ; la faune | le monde autour : la ville, la forêt profonde, la montagne, le Barocupot |

Une partie des images « à confirmer par le moteur » attend l'accord du lot qui les intègre
(section 9.4, colonne « Commander »).

### 9.2 Pour des planches cohérentes

Les livraisons précédentes ont surtout péché par l'échelle et la cohérence d'une image à l'autre
(section 2.4). Pour les éviter :

1. **Une conversation par planche**, et dans l'ordre : le profil d'abord ; la face puis le dos
   ensuite, en joignant le profil fini (« même personnage, même hauteur, mêmes animations, vu de
   face »).
2. **Donne toujours la hauteur debout en pixels**, pas seulement en mètres, et rappelle-la à chaque
   correction (« la 1re image de `repos` mesure 115 px de l'ancre au sommet des cheveux »).
3. **Fais dessiner sur un gabarit** : des cases de même taille, une ligne de sol commune à toute la
   rangée, un trait horizontal à la hauteur debout ; puis fais effacer le gabarit. Une planche
   complémentaire part de la rangée `repos` recopiée : elle sert d'étalon visible.
4. **Joins toujours les vues déjà livrées** du personnage : même palette (les planches livrées ont
   environ 64 couleurs), mêmes contours, mêmes proportions. Ne laisse pas l'outil « améliorer » une
   image existante : une rangée recopiée reste identique au pixel près.
5. **Une animation à la fois** si la planche dérive : demande la rangée seule, vérifie-la, puis
   assemble les rangées dans l'ordre du tableau.
6. **Nomme le côté des accessoires** dans chaque demande (« la couette du côté gauche de sa tête :
   à droite de l'image de face, à gauche de l'image de dos ») et vérifie-le sur chaque image.
7. **Laisse calculer les ancres** : `python3 tools/hd2d_sheets.py anchors <json> --write`, puis
   regarde la planche de contrôle (`python3 tools/hd2d_sheets.py strip <out.png> <json>`) : ligne
   de sol, axe de l'ancre, hauteur debout en orange.
8. **Après toute correction, repasse toute la vérification** : une vue redessinée pour un détail
   change souvent d'échelle ailleurs (cahier n° 1, section 3).
9. Pour les **familles** (fées génériques, hommes-bêtes d'une même espèce, maisons de la ville),
   demande d'abord une planche d'ensemble à l'échelle, côte à côte, puis chaque personnage ou
   bâtiment à part : formes vraiment différentes, même rendu.

### 9.3 Vérifier avant de livrer

1. Pars de la **dernière version de `main`**.
2. Dépose chaque image à son **chemin exact** ; pour une planche, les trois PNG et les trois JSON.
   Ne livre **que** les fichiers de ce document : ni sources, ni galeries, ni aperçus, ni outils,
   ni code, ni autre personnage, ni changement des fichiers existants.
3. Lance `python3 tools/hd2d_assets.py check` (tailles, transparence, raccords des tuiles et des
   bordures, ancrage au bord bas, bandes animées, alpha doux) et
   `python3 tools/hd2d_sheets.py check` (planches : format, animations et cadences, hauteur debout à
   6 % près, même échelle que `repos`, mêmes animations dans les trois vues). Ces deux outils ne
   vérifient que les images inscrites dans `tools/hd2d_manifest.json` (clés `images` et `sheets`) :
   les lots du moteur y inscrivent celles de ce cahier (avec la clé `lot` : `I` à `N`) en même temps
   que leurs remplaçants ; `check --lot I` ne vérifie alors que le lot I. Une image de ce cahier pas
   encore inscrite se vérifie à la main : taille exacte, mode RGBA, alpha 0 ou 255 hors « alpha
   doux », objet collé au bord bas (`python3 -c "from PIL import Image; im = Image.open('<png>');
   print(im.size, im.mode)"`).
4. Une image trop grande se ramène à sa taille par `python3 tools/hd2d_assets.py fit <fichier>`
   (une fois inscrite au manifeste) ; une nouvelle tuile de sol demande
   `python3 tools/hd2d_assets.py atlas`.
5. `tools/import.sh` (il crée les `.import` des nouvelles images, à livrer avec elles), puis
   `tools/check.sh`.
6. Note la provenance en bas de `assets/CREDITS.md` (et de `assets/characters/CREDITS.md` pour les
   planches) : « généré avec ChatGPT le …, cahier n° 3, lot … ».
7. Dans la description de la PR : les fichiers livrés, ceux qui manquent, les écarts connus
   (taille, cadrage, côté d'un accessoire).

### 9.4 Formats à confirmer par le moteur

Ces images supposent un format que le jeu n'a pas encore. Leurs tailles sont raisonnables mais
peuvent changer. Celles dont seul l'usage reste à trancher se commandent tout de suite ; les
autres attendent l'accord du lot du moteur indiqué (colonne « Commander »).

| Format | Images | Lot du moteur | Ce qu'il faut trancher | Commander |
| --- | --- | --- | --- | --- |
| Planche complémentaire `<id>_life` | 6 planches (lot J, 4.3 et 4.6) | E4 Vie | fusion dans la planche existante (rangées ajoutées) ou chargement d'une seconde planche ; `hd2d_sheets.py` ne connaît pas encore les animations de la section 8.1 de la refonte | tout de suite (seul l'usage change) |
| Planches de tenue et de geste (`_home`, `_pajamas`, `_rain`, `willem_cook`…) | 27 planches (lot J) | E4 Vie, E6 Récit | quand le jeu passe d'une planche à l'autre (à la maison, la nuit, sous la pluie, au travail) | tout de suite |
| Noms d'animation hors de la section 8.1 de la refonte : `etreinte`, `pare`, `broute` ; `travaille` des fées (toilette) | Nygglatho, bâton, faune, pyjamas | E4, E5, E8 | ajout au tableau de la section 8.1 de la refonte | tout de suite (seul le nom peut changer) |
| Entraînement au bâton (`_stick`) | 4 planches (lot J, 4.7) | E8 Jeux | animations de parade et de rythme | après accord |
| Nombres d'images et cadences des animaux | 10 planches (lot M, 7.7) | E5 Faune | la section 8.1 de la refonte ne donne que les noms | après accord |
| Couverture de lit en surimpression | `bed_iron_cover` | E3, E4 | un personnage couché sous une couverture | après accord |
| Toit-terrasse | `floor_roof_deck`, `roof_edge_slate` | E3 Intérieurs | le toit est-il une pièce ou une carte du dehors | après accord |
| Décalques dans les pièces (tapis, papiers, flaques, soleil) | 10 décalques (lots I, K, N) | E3 | décalques posés sur le sol d'une `InteriorRoom` | tout de suite |
| Socle des façades de ville, escaliers et murs de soutènement | `town_house_*`, `town_stairs_*`, `town_retaining_wall` | E2 Sol en relief | façades sur deux paliers, escaliers entre paliers | après accord |
| Faces des paliers | `cliff/step_*`, `cliff/wall_*_1m` (6 images) | E2 | hauteur des faces (0,5 et 1 m), raccords, coins | après accord |
| Nouvelles tuiles de sol | `ground/path_overgrown`, `ground/river_water` | E2 | l'atlas du sol a 27 couches (`GROUND_LAYERS`) | après accord |
| Premier plan suspendu | `fg_canopy_a`, `fg_canopy_b` | E10 Densité | un panneau accroché en haut de l'écran au-dessus du joueur | après accord |
| Navires en volume (flanc, pont, poupe, trois quarts), pont praticable, rotors et trappe | `ships/*` (7 images), `anim/garde_transport_*` | E7 Navires | navire en volume au nord du quai, pont où l'on marche | après accord |
| Pluie en rideau, flaques animées | `rain_curtain`, `rain_drizzle`, `puddle_rain_*` | E9 Lumière et temps | bande animée répétée sur l'écran, décalque animé | après accord |
| Vitres éclairées et fenêtres de nuit | `window_lit_*`, `*_night` | E9 | allumer les façades et changer les fenêtres selon l'heure | tout de suite (même cadrage que les fenêtres de jour) |

### 9.5 En résumé

| Lot | Images | Planches | Prio 1 | Prio 2 | Prio 3 |
| --- | --- | --- | --- | --- | --- |
| I | 160 | — | 91 images | 63 images | 6 images |
| J | 2 portraits | 80 | 23 planches | 28 planches, 2 portraits | 29 planches |
| K | 122 | — | — | 45 images | 77 images |
| L | 40 | — | — | 8 images | 32 images |
| M | 52 | 10 | 3 images | 19 images, 1 planche | 30 images, 9 planches |
| N | 30 | — | 14 images | 13 images | 3 images |
| **Total** | **406** | **90** | **108 images, 23 planches** | **150 images, 29 planches** | **148 images, 38 planches** |
