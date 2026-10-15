# Cahier des charges n° 5 : l'île n° 68, ce qui reste à dessiner

> **Les commandes encore ouvertes sont reprises, à jour et autonomes, dans le cahier n° 6 : `docs/ASSETS_HD2D_ILE68_LIVRAISON6.md`** (état au 15 octobre 2026 : R0, R1 et une partie de R2 sont livrés ; ce cahier-ci reste l'archive de la commande, ses inventaires et ses consignes d'origine).

Ce document se donne à ChatGPT (ou à Codex), **lot par lot**. Il termine la première île, l'**île
n° 68** de *SukaSuka* (traduction Yume Novel), avant qu'on en ouvre d'autres : il commande **tout ce
qui manque encore** pour que ses lieux, ses gens, sa faune et son ciel soient complets, et rien de plus
(ni autre île, ni surface). Il est établi le 14 octobre 2026 par un inventaire fait par script de ce
que les documents de lieux et de vie réclament, comparé à ce que le dépôt contient.

Il **complète** les cahiers précédents, dont il garde l'échelle, le rendu et les règles de livraison :

| Cahier | Fichier | État |
| --- | --- | --- |
| n° 1 | `docs/ASSETS_HD2D.md` | livré ; ses corrections (section 12) sont intégrées |
| n° 2 | `docs/ASSETS_HD2D_MONDE.md` | livré (lots A à G) |
| n° 3 | `docs/ASSETS_HD2D_SUKASUKA.md` | livré en partie : lots I priorités 1 et 2, J priorité 1, N priorité 1, une partie de L ; **le reste est repris ici** |
| n° 4 | `docs/ASSETS_HD2D_COMPLEMENTS.md` | livré en entier (24 accessoires, lots O1, O2, P, Q) |
| compléments | `docs/ASSETS_HD2D_NAVIRES.md` | livré (50 images : deux silhouettes, intérieurs de bord) |

Les consignes du cahier n° 3 qui n'ont pas été livrées sont **recopiées dans les lots ci-dessous**
(l'utilisateur colle un lot seul dans ChatGPT), corrigées quand l'inventaire ou les livraisons ont
appris quelque chose. Les conventions de `docs/REFONTE.md` (section 8.1) font foi. Ce que le dessin
dit des lieux et des gens vient de l'œuvre, d'après les dossiers du canon
(`docs/lore/canon/`), **paraphrasé** : le dépôt est public, on ne recopie jamais les volumes ; ce que
l'œuvre ne dit pas est marqué **(original)**.

## 0. Mode d'emploi

### 0.1 Ce que l'inventaire a trouvé

Méthode : tous les noms d'image et de planche cités par `docs/lore/CARTE.md` (inventaire de la
section 12 et plans des 23 cartes), `docs/lore/VIE.md`, `docs/lore/ACTE1.md`, les cahiers n° 3 et 4
et `docs/CONTRACT_REQUESTS.md` ont été relevés, puis comparés à `assets/**`, à
`tools/hd2d_manifest.json` et aux JSON des planches. Une image est **livrée** (un vrai dessin),
**remplaçant provisoire** (dessinée par nos outils : pixels identiques au rendu de la recette de
`tools/hd2d_assets.py` ou de `tools/hd2d_interior.py`) ou **absente**.

| Source | Noms relevés | Livrés | Remplaçants | Absents |
| --- | --- | --- | --- | --- |
| `CARTE.md`, 12.2 (images et matières des 23 cartes) | 378 | 242 | 3 | 133 (tous couverts par une ligne du cahier n° 3 ou de `CARTE.md` 12.1) |
| manifeste (cahiers n° 1, 2, lots I et N) | 480 | 468 | 12 | 0 |
| cahier n° 3, images (lots I, K, L, M, N) | 406 | 164 | 6 | 236 |
| cahier n° 3, planches de personnages et d'animaux | 90 | 23 | 0 | 67 |
| `CARTE.md` 12.1 (noms proposés) | 7 | 0 | 0 | 7 |

Les **remplaçants encore en place** : `door_frame_wood`, `floor_flagstone_cellar`, `wall_cellar_stone`,
`wallcut_stone`, `wallitem_height_marks` (intérieurs, lot R1), `rain_curtain` et `rain_drizzle` (pluie,
lot R6), `bank_earth` (talus de terre du cahier n° 1, lot R3) et les quatre effets `fx/shadow`, `fx/glow`,
`fx/light_pool`, `fx/rain_drop`, que le jeu génère exprès (facultatifs : on ne les commande pas).

Les **animations manquantes des planches livrées** : les planches des 17 habitants et des aînées
(`repos`, `marche`, `parle`, `attaque`…) sont complètes ; les 23 planches du cahier n° 3 ont toutes les
animations commandées. Manquent seulement celles que les scènes de l'acte 1 demandent en plus (lot R2) :
Willem qui tombe dans le marais (`willem_marsh`), qui porte une petite ou Chtholly (`willem_carry`,
`willem_piggyback`), qui joue au ballon (`willem_life`) ; le geste de métier du lycanthrope, du serveur
homme-chat et du boulanger (`*_work`) ; `travaille` de la cuisinière du jour (`fairy_12`).

Les **dessins faux et les vues manquantes** (lot R0, à commander en premier) : en jouant, l'utilisateur a vu des tables mal
faites et un canapé posé bizarrement. Six tables et comptoirs sont dessinés en perspective conique (plateau en trapèze, pieds
trop courts), l'angle de dessin varie d'un meuble à l'autre, et **aucun meuble n'existe de côté** : 60 meubles des plans sont collés à
un mur est ou ouest et font face au sud. Le lot R0 corrige 13 images (11 meubles, 2 décors du dehors) et en commande 41 (vues de flanc, de dos, par le pied).

### 0.2 Les lots, dans l'ordre du jeu

L'ordre suit `docs/REFONTE.md` (section 9) : la phase 2 joue l'entrepôt (jours 1 à 4) ; la phase 3, le
sentier, le village, le café, le port, les navires et la colline (jours 5 à 12) ; la phase 4, la forêt
profonde, la faune, le centre-ville et la montagne.

| Lot | Section | Contenu | Prio 1 | Prio 2 | Prio 3 |
| --- | --- | --- | --- | --- | --- |
| **R0** | 2 bis | **Corrections et vues manquantes** : tables mal faites, canapé et meubles sans vue de flanc ou de dos, lits par le pied, bancs ; (C3b) piliers de la mer de nuages et dalles du sentier de la colline | 28 images | 23 images | 8 images |
| **R1** | 3 | **L'entrepôt complet** : façades et flancs, toit, pièces, dehors, remplaçants | 12 images | 19 images | 8 images |
| **R2** | 4 | **Les personnages de l'acte 1** : tenues, gestes, scènes, fées, bâton | 10 planches | 2 images, 23 planches | 2 planches |
| **R3** | 5 | **Le chemin du port** : sentier et marais, village, café, maison Limashenka, port, paliers | 19 images | 30 images | 26 images |
| **R4** | 6 | **Les hommes-bêtes et la ville** | — | 14 images, 6 planches | 66 images, 23 planches |
| **R5** | 7 | **La nature et la faune** : forêt profonde, montagne, rivière, animaux | — | 4 images, 1 planche | 23 images, 9 planches |
| **R6** | 8 | **Le temps et la lumière** restants | 5 images | 11 images | 3 images |
| **R7** | 9 | **Les navires en volume** (transport de la Garde, Barocupot) | 3 images | — | 6 images |

**Priorités** (échelle de ce cahier, qui remplace celle du cahier n° 3) :

- **1** : une scène de l'acte 1 (`docs/lore/ACTE1.md`) cite l'image, ou elle est le décor principal d'une
  scène, et sans elle on joue avec un repli visible (un remplaçant, le sprite d'un autre personnage) ;
- **2** : la densité et la vie des lieux de l'acte 1 (`CARTE.md`, `VIE.md`) ;
- **3** : le bonus : le monde autour de l'acte 1 (ville, montagne, faune) et ce qui peut attendre.

### 0.3 Découper et joindre

**Découper.** Une conversation par lot, ou par famille d'images dans un lot (sections 3.1, 3.2…) :
colle d'abord le **bloc de style** (section 1), puis la section du lot, de son « Rappel du format » jusqu'à
la fin de son dernier tableau. Chaque lot se suffit à lui-même avec le bloc de style. Pour les
personnages, **une conversation par planche** (section 2.6).

**Joindre.** Chaque lot dit quelles images existantes joindre comme référence de rendu. Une capture du
jeu (`docs/img/`) aide aussi à montrer le cadrage.

**« Format à confirmer par le moteur ».** Quelques images supposent un format que le jeu n'a pas encore
(planches composites, faces des paliers, navires en volume…). Elles sont signalées à leur ligne et
récapitulées en section 10.5 ; celles qui sont marquées « après accord » attendent la décision du lot du
moteur concerné.

## 1. Bloc de style v5 (à coller au début de chaque conversation)

C'est le bloc v3 du cahier n° 3, avec quatre ajouts nés des livraisons et du jeu : la projection des meubles (orthographique oblique, deux vues
quand on peut les voir de côté), la pointe d'une arme ne passe pas sous les pieds, le JSON n'a que les clés du format, rien
n'est retouché ni renommé.

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
- projection des meubles, tables, lits, bancs et objets : **orthographique oblique à 32°**, comme la caméra du jeu, jamais en perspective conique : aucun point de fuite, les arêtes parallèles restent parallèles, les arêtes verticales restent
  verticales, le dessus d'un plateau est un rectangle ; une surface horizontale de profondeur p apparaît avec une hauteur de
  0,53 × p × 96 px, une face verticale de hauteur h avec 0,85 × h × 96 px ; un meuble qu'on peut voir de côté a une vue de face
  et une vue de flanc de même hauteur, de même échelle et de même matière ;
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
  les fichiers demandés ; ne retouche, ne « améliore » ni ne renomme aucune image déjà livrée ;
- un sprite ou un décalque qui flotte (centré) garde une marge transparente d'au moins 4 px tout
  autour ; un panneau touche le bord bas, jamais le haut ni les côtés sauf s'il se raccorde.
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
- rien sous la ligne des pieds (ni pointe d'épée, ni queue, ni ombre) : une arme ou un bâton tenu vers le
  bas se raccourcit ou se relève pour que sa pointe touche la ligne du sol sans la dépasser ;
- le JSON d'une planche ne contient que les clés du format (version, echelle, planche, direction, format,
  animations) : aucune clé de suivi, aucun commentaire.
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

## 2. Règles communes et conventions

### 2.1 Les règles

Elles valent pour toutes les images de ce cahier (cahiers n° 1 à 3 ; `docs/REFONTE.md`, section 8.1).

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
| Livraison | seulement les fichiers listés, à leur chemin exact (section 10.3) |

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
| **Planche de sprites** | `assets/characters/<dossier>/<id>.png` + `.json`, `_front`, `_back` ; animaux : `assets/fauna/<id>/` | format du rappel du lot R2, section 4.0 | `assets/characters/tiat/tiat_life.png` |

**Calcul des tailles** : mètres × 96, arrondis au pixel (0,45 m = 43 px ; 1,25 m = 120 px ;
2,4 m = 230 px). Les tableaux donnent toujours les pixels ; les mètres entre parenthèses servent au
dessinateur pour l'échelle des détails (une marche fait 17 cm, une poignée de porte est à 1 m du
sol, une chaise a son assise à 45 cm, une table son plateau à 75 cm, un lit son matelas à 50 cm).

### 2.3 Les animations des personnages (`docs/REFONTE.md`, 8.1)

Le format des planches ne change pas (cahier n° 1, section 3) : trois vues, mêmes animations,
même hauteur debout. Les animations de la refonte portent ces noms (fiche complète, image par
image, dans le rappel du lot R2) :

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

### 2.4 Ce que les livraisons des cahiers n° 1 à 3 ont mal compris

Défauts relevés dans les livraisons des cahiers n° 1 et 2 (cahier n° 1, section 12 ; `docs/DECISIONS.md`) et
repris du cahier n° 3 (section 2.4). Chaque consigne de ce cahier les prévient ; les relire avant de
commander.

| Ce qui est arrivé | Ce qu'on demande |
| --- | --- |
| `parle` et `marche` dessinées 6 à 36 % plus grandes ou plus petites que `repos` (13 vues) : le personnage rapetissait en parlant | chaque image debout à la hauteur debout donnée en px ; les planches complémentaires recopient la rangée `repos` en tête, comme étalon (rappel du lot R2, section 4.0) |
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
| 380 Mo de sources, galeries, aperçus, outils, changements de code et 35 personnages non demandés dans une livraison | seulement les PNG et les JSON listés (section 10.3) |
| avancée du toit dessinée plus bas que le haut du mur aux angles de quatre flancs en pignon | le toit ne descend pas sous le haut du mur |
| enseigne d'horloger qui pouvait se lire comme une heure | cadrans sans chiffres ni aiguilles lisibles ; écriteaux sans lettres |

### 2.5 Ce que les livraisons du cahier n° 3 ont appris (14 octobre 2026)

Mesures faites par script sur les 244 images et les 23 planches livrées depuis le cahier n° 3 (taille,
mode, alpha, raccords et ancrage par les règles de `tools/hd2d_assets.py` et `tools/hd2d_sheets.py`,
appliquées aussi aux images que le manifeste ne connaît pas), et lecture de leurs notes de livraison
(`assets/CREDITS.md`, `assets/characters/CREDITS.md`).

**Ce qui est acquis (à ne pas relâcher).** Les 244 images ont la taille exacte, le mode RGBA, un alpha
net, le bon ancrage et leurs raccords ; aucune image non demandée, aucun nom de fichier erroné, aucun
fichier de source dans la livraison. Les 23 planches ont les trois vues, leurs animations, `ips`,
`boucle` et `coup` identiques au tableau, une hauteur debout à 98 % ou plus de la consigne, et la
rangée `repos` recopiée au pixel près dans les planches `_life`.

**Ce qui a été mal compris, et la consigne qui le corrige.**

| Ce qui est arrivé | Où | Ce qu'on demande |
| --- | --- | --- |
| La pointe de l'arme passe sous la ligne des pieds : 16 px (Seniorious de `chtholly_front`, au repos), 10 px (l'épée de bois de `pannibal`, `repos` image 0, recopiée dans `pannibal_life`), 5 à 7 px (`willem_front`, `limeskin_back`) ; le moteur mesure désormais la hauteur debout à l'ancre, mais le personnage « flotte » de quelques pixels | planches livrées | rien sous la ligne des pieds : relever ou raccourcir la pointe ; le contrôle se lit sur `python3 tools/hd2d_sheets.py strip` |
| Les JSON de `fairy_04`, `fairy_05` et `fairy_06` portent quatre clés en plus (`status`, `anchors_validated`, `combat_timing_validated`, `density_px_m`) et sont mis en forme autrement que les autres | JSON | seulement les clés du format de l'easter egg ; une image par ligne |
| Le sommeil (`dort`) de la face et du dos est la vue de profil recopiée telle quelle | les 23 planches | c'est la consigne (« les trois vues reprennent la même image couchée ») : à signaler dans la livraison, pas à redessiner |
| Des images livrées ne sont inscrites à aucun contrôle : 146 images et 23 planches échappent à `hd2d_assets.py check` et `hd2d_sheets.py check`, qui ne lisent que le manifeste | contrôles | le contrôle à la main de la section 10.3, tant que le moteur ne les inscrit pas |
| Trois images de la priorité 1 du lot N n'ont pas été livrées : les deux rideaux de pluie (`rain_curtain`, `rain_drizzle`) et la flaque animée (`puddle_rain_a`), des bandes de 4 images dont **chaque image se raccorde sur ses quatre bords** | lot N | demander **une** tuile de pluie sans raccord, puis les 4 images par décalage vertical d'un quart (lot R6) ; le remplaçant du moteur reste acceptable en attendant |
| Les bandes animées et les décalques sont ce qu'on livre le moins : 5 bandes sur 26 et 3 décalques sur 18 du cahier n° 3 sont livrés | lots I, K, L, M, N | les commander dans une conversation à part, une bande à la fois, en joignant l'image du meuble ou du lieu qu'elle anime |
| Le cahier n° 4 annonce « à produire » trois lots (O2, P, Q) qui étaient déjà livrés (commit `f76ac1d`) | documents | tenir l'état des lots à jour à chaque livraison (section 10.3) |
| Des images « cadrées au plus juste » touchaient leur bord sur 1 à 5 % de sa longueur (lots A à G) | cahier n° 2 | une marge transparente de 4 px autour de tout ce qui flotte ou se centre (ajoutée au bloc de style) |

### 2.6 Pour des planches cohérentes


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

### 2.7 Un meuble qu'on peut voir de côté se livre en deux vues (règle apprise en jouant)

Un panneau (`DecorPanel`, `InteriorPanel`) **se tourne toujours vers le sud** : la caméra regarde le nord, le
meuble n'a que l'image qu'on lui donne. Un canapé, une bibliothèque ou un classeur posé contre le mur est ou
ouest ne peut donc que faire face au sud, perpendiculaire au mur, comme une péninsule : c'est le canapé « posé
bizarrement » des archives, et les armoires de la salle de jeux et de l'infirmerie. Les plans de `CARTE.md` placent
soixante meubles contre un mur est ou ouest (inventaire par script, section R0.0) et aucune image n'existe
de côté.

**La règle.** **Chaque meuble qu'on peut voir de côté est livré en deux vues, face et flanc, de même hauteur
au sol, de même échelle, de même matière** : `<nom>.png` (de face, tourné vers le sud) et `<nom>_side.png` (de flanc,
la face du meuble tournée vers l'**est** ; le moteur retourne l'image pour le mur ouest). Un meuble qu'on peut voir de dos (un
fauteuil qui regarde la fenêtre, une chaise qui regarde la cheminée) a aussi `<nom>_back.png`, de dos, la face
cachée. Un lit dont la tête touche le mur nord a `<nom>_foot.png`, vu par le pied.

**Les cotes d'une vue de flanc** : la **largeur de l'image** est la profondeur du meuble (sa profondeur de face, en m
× 96) ; sa **hauteur** est celle de la vue de face plus 0,53 × (largeur − profondeur) × 96, parce que la largeur du
meuble se déroule maintenant vers le fond ; l'ancre reste le milieu du bord bas. Une vue de dos garde la taille de la
vue de face.

**La projection** (même règle pour toutes les vues, des tables aux bancs) : **orthographique oblique, comme la caméra
du jeu** (inclinée de 32°). Aucun point de fuite : les arêtes parallèles restent parallèles, les arêtes verticales
restent verticales, le dessus d'un plateau est un rectangle ; une surface horizontale de profondeur *p* apparaît avec une
hauteur de **0,53 × p × 96 px**, une face verticale de hauteur *h* avec **0,85 × h × 96 px**. Une table de 0,75 m de
haut et 0,9 m de profondeur fait donc 46 px de plateau et 61 px de pieds, soit 107 px avec la tranche.

**Exemple de consigne** (à adapter) : « Image d'intérieur `assets/hd2d/interior/props/sofa_beige_side.png`, 86 × 175 px,
meuble : le canapé beige à trois places de `sofa_beige.png` (jointe), **vu de flanc**, la face du canapé tournée vers
l'est, même tissu usé et mêmes coussins, accoudoir au premier plan, couverture à carreaux pliée sur l'accoudoir ; mêmes
hauteurs que la vue de face (assise à 45 cm, dossier à 0,9 m), même échelle ; sa largeur de 2 m se déroule vers le fond
(dessus visible sur 102 px), sa profondeur de 0,9 m fait la largeur de l'image (86 px) ; projection orthographique oblique à
32°, aucun point de fuite ; fond transparent, ancre au milieu du bord bas. »


## 2 bis. Lot R0 : corrections et vues manquantes (priorité 1, à commander en premier)

Ce lot passe avant tous les autres : il corrige des images **déjà livrées** et dessine les **vues qui manquent**. En jouant
l'entrepôt, l'utilisateur a vu des **tables mal faites** et un **canapé posé bizarrement**. Les deux ont la même
cause : les meubles du lot I sont des images fixes, dessinées chacune pour elle-même, sans règle commune de projection ni de
vues. Chaque ligne ci-dessous dit le fichier, ce qui ne va pas (constaté), ce qu'il faut redessiner et la consigne prête à
copier ; un fichier corrigé garde son nom et sa taille, sauf raison donnée.

### R0.0 Comment ces cas ont été trouvés

1. **Les vues qui manquent.** Les plans de `docs/lore/CARTE.md` (171 lignes `meuble`) ont été rapprochés des murs de
   leur pièce par script : **60 meubles sont collés à un mur est ou ouest** (à moins de 0,9 m), tous avec l'emprise de leur vue de face,
   donc face au sud. Les scènes de `src/world/maps/` n'ont **aucune rotation** (toutes les transformations sont l'identité) et aucun
   `flip_h` ; `tools/hd2d_interior.py` (liste `FURNITURE`, 41 meubles) ne connaît qu'une vue par meuble, sauf `chair_wood_back`. Les
   captures `t2_entrepot_rdc_archives_apres_midi.png`, `t2_entrepot_rdc_jeux_apres_midi.png`,
   `t2_entrepot_rdc_infirmerie_apres_midi.png` et `t2_entrepot_rdc_bains_apres_midi.png` le montrent : le canapé des archives
   fait face au sud au lieu de s'adosser au mur ; le classeur, la bibliothèque de lecture, l'étagère de jeux, la pharmacie et
   l'étagère à serviettes sortent du mur est ou ouest comme des péninsules.
2. **Les dessins faux.** Une soixantaine de meubles livrés (`assets/hd2d/interior/props/`) ont été ouverts un par un ; les
   tables, comptoirs, chaises, lits, canapés et bureaux en détail, à 3 et 4 fois leur taille, et jugés pour la caméra fixe
   (inclinée de 32°, elle regarde le nord) : perspective, échelle (96 px par mètre, personnages de 1,4 à 1,7 m), ombres
   peintes, fonds, découpe. Captures regardées : `interieur_refectoire.png`, `interieur_archives.png` (E3) et les captures
   `t2_entrepot_*` (T2).
3. **Le dehors.** Échantillon de 24 panneaux (`props/`), de 9 façades et flancs et des deux silhouettes de navires.

**Ce que la revue a trouvé** (détail aux tableaux ci-dessous) :

- **Les tables et comptoirs** (`dining_table_long`, `dining_table_set`, `reading_table`, `game_table`,
  `kitchen_table_ingredients`, `kitchen_counter`) sont dessinés en **perspective conique** : le plateau est un trapèze dont
  un bord est en biais, il occupe les deux tiers de l'image, les pieds ne font que 0,3 à 0,5 m. Une table de 0,75 m paraît un banc
  bas ; deux tables côte à côte ne se raccordent pas. Le jeu regarde avec un champ étroit (30°), presque sans fuite : il faut une projection oblique,
  sans point de fuite.
- **L'angle de dessin change d'un meuble à l'autre** : tables et comptoirs vus de 55° au-dessus, canapé, lits et bancs en
  élévation pure (le dessus est invisible), chaises à 40°, chaise de l'invité et chaise du bureau de l'infirmerie de trois quarts.
- **Des meubles n'existent que de face** : canapé, bibliothèques, classeur, bureaux, armoires, pharmacie, coffres,
  fauteuils, chaises, baignoire, bancs.
- **Rien à signaler** sur les fonds (tous détourés), les ombres peintes (aucune) et l'échelle générale (96 px par mètre :
  tous les meubles comparés à la petite fée de 1,1 m et à l'adulte de 1,75 m sont à la bonne taille) ; le défaut est la projection et les
  vues, pas la taille.

### R0.1 Rappel du format (à coller avec le lot)

Images d'intérieur, panneaux debout, fond transparent (PNG RGBA, alpha 0 ou 255), ancre au milieu du bord bas ; 96 px par
mètre ; lumière douce de la gauche et d'un peu au-dessus, aucune ombre portée au sol.

**La règle des vues** (section 2.7) : chaque meuble qu'on peut voir de côté est livré en **deux vues, face et flanc**, de même
hauteur au sol et de même échelle ; un meuble qu'on peut voir de dos a sa vue de dos ; un lit a sa vue par le pied. Noms :
`<nom>.png` (de face, tourné vers le sud), `<nom>_side.png` (de flanc, face tournée vers l'**est** ; le moteur retourne l'image pour le
mur ouest), `<nom>_back.png` (de dos), `<nom>_foot.png` (lit vu par le pied).

**La projection** : orthographique oblique à 32°, sans point de fuite ; une surface horizontale de profondeur *p* a une hauteur
apparente de 0,53 × *p* × 96 px, une face verticale de hauteur *h* de 0,85 × *h* × 96 px ; les arêtes verticales sont verticales ; le
dessus d'un plateau est un rectangle.

**Cotes d'une vue de flanc** : largeur = profondeur du meuble × 96 ; hauteur = hauteur de la vue de face + 0,53 × (largeur − profondeur)
× 96. Vue de dos : taille de la vue de face.

**Consigne** : colle le bloc de style, ce rappel, joins l'image de face (et, pour une vue de flanc ou de dos, la face déjà
corrigée), puis « Image d'intérieur `<chemin>`, <taille> px, <genre> : » et la description de la ligne. Pour un meuble, **commande
la face corrigée d'abord, puis ses vues dans la même conversation**.

### R0.2 Les dessins à refaire (même nom)

| Prio | Fichier | Taille (px) | Constat (ce qui ne va pas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/chair_guest.png` | 77 × 101 (inchangée) | dessinée de trois quarts : elle ne s'aligne sur aucun mur et se tourne vers nulle part | chaise rembourrée à dossier arrondi, velours vert usé, coussin brodé, vue **de face** (axe de la chaise vertical dans l'image), projection orthographique oblique à 32° ; sa vue de flanc et sa vue de dos suivent (tableaux R0.3 et R0.4) ; même nom, même taille |
| 1 | `assets/hd2d/interior/props/dining_table_long.png` | 384 × 106 (inchangée) | le plateau est un trapèze à point de fuite (bord gauche en biais), il occupe les deux tiers de l'image et les pieds ne mesurent que 0,3 m : la table se lit comme un banc bas ; deux tables côte à côte ne se raccordent pas (capture `interieur_refectoire.png` (E3) et `t2_entrepot_rdc_derriere_chaises_apres_midi.png` (T2)) | longue table de ferme de 4 m de long, 0,9 m de profondeur, 0,75 m de haut, vide ; projection **orthographique oblique** comme la caméra du jeu (inclinée de 32°) : aucun point de fuite, les arêtes parallèles restent parallèles et les arêtes verticales restent verticales ; le plateau est un **rectangle** (ses côtés gauche et droit sont verticaux), de profondeur apparente 46 px, avec une tranche de 5 px, puis les pieds sur 55 px ; plateau de bois massif taché, entaillé, brûlé par une casserole ; pieds tournés et traverse basse ; mêmes bois et rendu que `china_cabinet.png` (jointe) ; même nom, même taille |
| 1 | `assets/hd2d/interior/props/dining_table_set.png` | 384 × 115 (inchangée) | même défaut que `dining_table_long` (trapèze, pieds de 0,3 m) ; la vaisselle, trop grosse, cache le plateau | la même table, dressée, mêmes proportions que `dining_table_long.png` corrigée (jointe) ; assiettes de faïence dépareillées, fourchettes, gobelets d'étain et chopes, deux corbeilles de pain, deux pichets ; tout à l'échelle (une assiette = 22 cm = 21 px), la vaisselle dépasse de 9 px au plus le bord arrière du plateau ; même nom, même taille |
| 1 | `assets/hd2d/interior/props/game_table.png` | 115 × 76 (était 115 × 58) | plateau en trapèze et pieds de 0,2 m ; les pions, plus hauts que la table n'est épaisse, la font paraître minuscule | table basse de 1,2 m de long, 0,6 m de profondeur, 0,4 m de haut, avec une partie en cours ; projection **orthographique oblique** comme la caméra du jeu (inclinée de 32°) : aucun point de fuite, les arêtes parallèles restent parallèles et les arêtes verticales restent verticales ; le plateau est un **rectangle** (ses côtés gauche et droit sont verticaux), de profondeur apparente 31 px, avec une tranche de 4 px, puis les pieds sur 33 px ; damier plié, pions de bois (2 cm de large, 5 cm de haut), cartes retournées, deux dés ; **taille portée à 115 × 76** (table 68 px, pions 8 px) |
| 1 | `assets/hd2d/interior/props/kitchen_counter.png` | 192 × 132 (était 192 × 101) | plateau en trapèze et pieds de 0,5 m : un comptoir de cuisine doit arriver à la taille d'une adulte (0,9 m) | comptoir de bois épais de 2 m de long, 0,65 m de profondeur, 0,9 m de haut, étagère basse (bols empilés) ; projection **orthographique oblique** comme la caméra du jeu (inclinée de 32°) : aucun point de fuite, les arêtes parallèles restent parallèles et les arêtes verticales restent verticales ; le plateau est un **rectangle** (ses côtés gauche et droit sont verticaux), de profondeur apparente 33 px, avec une tranche de 5 px, puis les pieds sur 76 px ; sur le plateau : planche à découper, couteaux, bols empilés, sac de farine ouvert, pot à ustensiles, épluchures ; **taille portée à 192 × 132** |
| 1 | `assets/hd2d/interior/props/kitchen_table_ingredients.png` | 154 × 135 (était 154 × 106) | dessus vu presque à plat et pieds de 0,45 m ; les ingrédients rendent la table haute de 1,1 m dans l'image | table de travail de 1,6 m de long, 0,9 m de profondeur, 0,85 m de haut, chargée des ingrédients du dessert (œufs dans un panier, sac de sucre, pot de lait, jatte de crème, bol de baies, motte de beurre, pot de miel, noix, un bol et un fouet) ; projection **orthographique oblique** comme la caméra du jeu (inclinée de 32°) : aucun point de fuite, les arêtes parallèles restent parallèles et les arêtes verticales restent verticales ; le plateau est un **rectangle** (ses côtés gauche et droit sont verticaux), de profondeur apparente 46 px, avec une tranche de 5 px, puis les pieds sur 70 px ; **taille portée à 154 × 135** |
| 1 | `assets/hd2d/interior/props/reading_table.png` | 173 × 130 (était 173 × 91) | plateau en trapèze, pieds de 0,4 m, un tabouret dessiné sous la table (il ne bouge pas) ; livres et lampe plus grands que nature ; l'image ne mesure que 91 px : trop peu pour une table de 0,75 m chargée | table de lecture de 1,8 m de long, 0,8 m de profondeur, 0,75 m de haut ; projection **orthographique oblique** comme la caméra du jeu (inclinée de 32°) : aucun point de fuite, les arêtes parallèles restent parallèles et les arêtes verticales restent verticales ; le plateau est un **rectangle** (ses côtés gauche et droit sont verticaux), de profondeur apparente 41 px, avec une tranche de 5 px, puis les pieds sur 61 px ; **sans tabouret** ; sur le plateau : deux livres ouverts (un livre = 25 × 18 cm), deux piles, un papier roulé en bâton (celui de Nephren), une lampe de table à cristal de 30 cm ; **taille portée à 173 × 130** : la table (107 px) plus les objets posés (23 px) |
| 1 | `assets/hd2d/interior/props/sofa_beige.png` | 192 × 119 (était 192 × 86) | dessiné en élévation pure (0°) alors que le jeu regarde à 32° : le dessus des coussins et des accoudoirs est invisible, il paraît plus plat que les tables ; il n'existe qu'en vue de face, donc il fait face au sud même contre un mur (capture `t2_entrepot_rdc_archives_apres_midi.png` (T2)) | canapé beige à trois places, 2 m de large, 0,9 m de profondeur, assise à 45 cm, dossier à 0,9 m, vu **de face** en projection orthographique oblique à 32° : le dessus des trois coussins et des accoudoirs est visible (profondeur apparente 46 px), tissu usé, assise affaissée au milieu, une couverture pliée sur l'accoudoir ; **taille portée à 192 × 119** ; ses vues de flanc et de dos sont aux tableaux R0.3 et R0.4 et se commandent dans la même conversation |
| 2 | `assets/hd2d/interior/props/chair_child.png` | 43 × 77 (inchangée) | même perspective conique que `chair_wood` (assise trop visible) | petite chaise d'enfant de bois peint en vert passé, vue de face en projection orthographique oblique à 32°, assise à 35 cm ; même nom, même taille |
| 2 | `assets/hd2d/interior/props/chair_wood.png` | 48 × 96 (inchangée) | l'assise est vue de trop haut, son bord avant plus large que son bord arrière (perspective conique) ; la rangée de 14 chaises du réfectoire ressemble à une palissade | chaise de bois à dossier à barreaux et assise paillée, vue **de face** en projection orthographique oblique à 32° : l'assise est un rectangle de 0,45 m de profondeur (23 px de haut apparente), assise à 45 cm, dossier à 1 m ; même nom, même taille |
| 2 | `assets/hd2d/interior/props/infirmary_desk.png` | 125 × 96 (inchangée) | la chaise est dessinée de trois quarts, décalée à gauche, devant le bureau vu de face | bureau simple et sa chaise : la chaise est dessinée **de dos**, centrée devant le bureau (la personne assise regarde le mur nord), le bureau de face en projection orthographique oblique ; tableau de notes à pince, plume, éprouvette de poudre argentée, lampe à cristal ; même nom, même taille |

Les tables qui seront livrées au lot R3 (`cafe_table_heavy`, `cafe_drinkers_table`, `cafe_town_table`) et R4
(`bookshop_table`, `kitchen`…) suivent la même projection : elle est dans le bloc de style v5.

### R0.3 Les vues de flanc (face tournée vers l'est)

Chaque ligne est une **image nouvelle** ; la colonne « Où » dit la pièce et le mur où les plans de `CARTE.md` posent le meuble.
Tailles calculées par la règle de R0.1 (largeur = profondeur, hauteur = face + 0,53 × (largeur − profondeur)).

| Prio | Fichier | Taille (px) | Où | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/armchair_reading_side.png` | 86 × 106 | salle de lecture, mur est | `armchair_reading.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (101 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1 m) devient sa profondeur à l'écran, sa profondeur (0,9 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 51 px |
| 1 | `assets/hd2d/interior/props/board_games_shelf_side.png` | 48 × 190 | salle de jeux, mur est | `board_games_shelf.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (154 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,2 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 61 px |
| 1 | `assets/hd2d/interior/props/bookshelf_low_side.png` | 48 × 132 | salle de lecture, mur ouest | `bookshelf_low.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (86 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,4 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 71 px |
| 1 | `assets/hd2d/interior/props/bookshelf_tall_b_side.png` | 58 × 272 | salle de lecture, mur ouest | `bookshelf_tall_b.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (221 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,6 m) devient sa profondeur à l'écran, sa profondeur (0,6 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 81 px |
| 1 | `assets/hd2d/interior/props/bookshelf_tall_side.png` | 58 × 272 | salle de lecture et archives | `bookshelf_tall.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (221 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,6 m) devient sa profondeur à l'écran, sa profondeur (0,6 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 81 px |
| 1 | `assets/hd2d/interior/props/chair_guest_side.png` | 58 × 106 | chambre de Nygglatho, près de la table à thé | `chair_guest.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (101 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (0,7 m) devient sa profondeur à l'écran, sa profondeur (0,6 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 36 px |
| 1 | `assets/hd2d/interior/props/desk_buried_side.png` | 77 × 156 | archives, mur ouest | `desk_buried.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (125 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,4 m) devient sa profondeur à l'écran, sa profondeur (0,8 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 71 px |
| 1 | `assets/hd2d/interior/props/desk_nygglatho_side.png` | 77 × 137 | chambre de Nygglatho, mur est | `desk_nygglatho.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (106 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,4 m) devient sa profondeur à l'écran, sa profondeur (0,8 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 71 px |
| 1 | `assets/hd2d/interior/props/filing_cabinet_side.png` | 48 × 159 | archives, mur est | `filing_cabinet.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (134 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 51 px |
| 1 | `assets/hd2d/interior/props/infirmary_desk_side.png` | 77 × 121 | infirmerie, mur ouest | `infirmary_desk.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (96 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,3 m) devient sa profondeur à l'écran, sa profondeur (0,8 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 66 px |
| 1 | `assets/hd2d/interior/props/medicine_cabinet_side.png` | 48 × 198 | infirmerie, mur est | `medicine_cabinet.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (173 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 51 px |
| 1 | `assets/hd2d/interior/props/pantry_cupboard_side.png` | 58 × 217 | cuisine, mur ouest | `pantry_cupboard.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (192 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,1 m) devient sa profondeur à l'écran, sa profondeur (0,6 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 56 px |
| 1 | `assets/hd2d/interior/props/shoe_rack_side.png` | 38 × 99 | entrée, mur est | `shoe_rack.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (58 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1,2 m) devient sa profondeur à l'écran, sa profondeur (0,4 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 61 px |
| 1 | `assets/hd2d/interior/props/sofa_beige_side.png` | 86 × 175 | archives, mur ouest | `sofa_beige.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (119 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (2 m) devient sa profondeur à l'écran, sa profondeur (0,9 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 102 px |
| 1 | `assets/hd2d/interior/props/towel_shelf_side.png` | 48 × 179 | salle de bains, mur est | `towel_shelf.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (154 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 51 px |
| 1 | `assets/hd2d/interior/props/toy_chest_side.png` | 58 × 97 | salle de jeux, mur est | `toy_chest.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (77 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1 m) devient sa profondeur à l'écran, sa profondeur (0,6 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 51 px |
| 1 | `assets/hd2d/interior/props/wardrobe_chtholly_side.png` | 58 × 212 | chambre de Chtholly, mur est | `wardrobe_chtholly.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (192 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (1 m) devient sa profondeur à l'écran, sa profondeur (0,6 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 51 px |
| 2 | `assets/hd2d/interior/props/chair_child_side.png` | 43 × 77 | chevet de l'infirmerie | `chair_child.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (77 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (0,45 m) devient sa profondeur à l'écran, sa profondeur (0,45 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 23 px |
| 2 | `assets/hd2d/interior/props/chair_wood_side.png` | 48 × 96 | bout des tables du réfectoire | `chair_wood.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (96 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (0,5 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 25 px |
| 2 | `assets/hd2d/interior/props/clothes_chest_side.png` | 48 × 78 | chambre de la grande sœur, mur est | `clothes_chest.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (58 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (0,9 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 46 px |
| 2 | `assets/hd2d/interior/props/dresser_child_side.png` | 48 × 106 | dortoirs, mur est | `dresser_child.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (86 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (0,9 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 46 px |
| 2 | `assets/hd2d/interior/props/footlocker_side.png` | 48 × 63 | chambre de Willem, mur ouest | `footlocker.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (48 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (0,8 m) devient sa profondeur à l'écran, sa profondeur (0,5 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 41 px |
| 3 | `assets/hd2d/interior/props/bath_tub_side.png` | 96 × 167 | salle de bains, vue par le bout | `bath_tub.png` (jointe) **vu de flanc**, la face du meuble tournée vers l'est (le moteur retourne l'image pour le mur ouest) : même meuble, mêmes bois, mêmes objets, même hauteur (96 px de dessin vertical, comme la vue de face), même échelle (96 px par mètre) ; sa largeur de face (2,4 m) devient sa profondeur à l'écran, sa profondeur (1 m) devient la largeur de l'image ; projection orthographique oblique à 32°, dessus visible sur 122 px |

### R0.4 Les vues de dos

| Prio | Fichier | Taille (px) | Où | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/sofa_beige_back.png` | 192 × 119 | archives : le canapé peut faire face au nord, vers le bureau et la porte | `sofa_beige.png` (jointe) **vu de dos** : le dossier ou l'arrière du meuble vers la caméra, même hauteur, même largeur, même échelle, mêmes matières ; ce qu'on ne voit que de face (coussin d'assise, devant du meuble) disparaît ; projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/armchair_reading_back.png` | 96 × 101 | salle de lecture : le lecteur regarde la fenêtre à banc, au nord | `armchair_reading.png` (jointe) **vu de dos** : le dossier ou l'arrière du meuble vers la caméra, même hauteur, même largeur, même échelle, mêmes matières ; ce qu'on ne voit que de face (coussin d'assise, devant du meuble) disparaît ; projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/chair_child_back.png` | 43 × 77 | infirmerie : la petite chaise au chevet, tournée vers le lit | `chair_child.png` (jointe) **vu de dos** : le dossier ou l'arrière du meuble vers la caméra, même hauteur, même largeur, même échelle, mêmes matières ; ce qu'on ne voit que de face (coussin d'assise, devant du meuble) disparaît ; projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/chair_guest_back.png` | 77 × 101 | chambre de Nygglatho : la chaise de l'invité fait face à la cheminée, au nord | `chair_guest.png` (jointe) **vu de dos** : le dossier ou l'arrière du meuble vers la caméra, même hauteur, même largeur, même échelle, mêmes matières ; ce qu'on ne voit que de face (coussin d'assise, devant du meuble) disparaît ; projection orthographique oblique à 32° |

### R0.5 Les lits vus par le pied (tête contre le mur nord)

Les lits n'existent qu'en vue de flanc, tête à gauche (retournée, tête à droite). Un lit dont la tête touche le mur nord, comme
dans les dortoirs et à l'infirmerie, se voit par le pied. Taille : largeur du lit, hauteur = hauteur du lit de flanc
+ 0,53 × (longueur − largeur) × 96.

| Prio | Fichier | Taille (px) | Hauteur de la vue de flanc (px) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/bed_child_foot.png` | 77 × 118 | 77 | `bed_child.png` (jointe) **vu par le pied du lit**, la tête contre le mur nord (derrière), le pied vers la caméra : même lit, mêmes draps et couvertures, même hauteur de matelas ; largeur de l'image = largeur du lit (77 px), hauteur = 77 px de lit + 0,53 × la longueur du lit (1,6 m) ; projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/bed_chtholly_foot.png` | 91 × 144 | 91 | `bed_chtholly.png` (jointe) **vu par le pied du lit**, la tête contre le mur nord (derrière), le pied vers la caméra : même lit, mêmes draps et couvertures, même hauteur de matelas ; largeur de l'image = largeur du lit (91 px), hauteur = 91 px de lit + 0,53 × la longueur du lit (2 m) ; projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/bed_iron_foot.png` | 96 × 152 | 101 | `bed_iron.png` (jointe) **vu par le pied du lit**, la tête contre le mur nord (derrière), le pied vers la caméra : même lit, mêmes draps et couvertures, même hauteur de matelas ; largeur de l'image = largeur du lit (96 px), hauteur = 101 px de lit + 0,53 × la longueur du lit (2 m) ; projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/bed_plain_foot.png` | 91 × 144 | 91 | `bed_plain.png` (jointe) **vu par le pied du lit**, la tête contre le mur nord (derrière), le pied vers la caméra : même lit, mêmes draps et couvertures, même hauteur de matelas ; largeur de l'image = largeur du lit (91 px), hauteur = 91 px de lit + 0,53 × la longueur du lit (2 m) ; projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/bunk_bed_foot.png` | 86 × 228 | 182 | `bunk_bed.png` (jointe) **vu par le pied du lit**, la tête contre le mur nord (derrière), le pied vers la caméra : même lit, mêmes draps et couvertures, même hauteur de matelas ; largeur de l'image = largeur du lit (86 px), hauteur = 182 px de lit + 0,53 × la longueur du lit (1,8 m) ; projection orthographique oblique à 32° |

### R0.6 À commander avec leur image de face (lots R3 et R4)

Les meubles de la maison Limashenka et de la librairie, pas encore livrés, se commandent **avec** leurs vues, dans la même
conversation que leur face (lot R3, sections 5.5 ; lot R4, section 6.7).

| Prio | Fichier | Taille (px) | Où | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/armchair_sheeted_side.png` | 86 × 106 | maison Limashenka, salon, mur est | `armchair_sheeted.png` (à commander avec elle, lot R3) **vu de flanc, face tournée vers l'est (le moteur retourne l'image pour l'ouest)** : même meuble, même hauteur, même échelle, projection orthographique oblique à 32° |
| 1 | `assets/hd2d/interior/props/sofa_salon_side.png` | 86 × 152 | maison Limashenka, salon | `sofa_salon.png` (à commander avec elle, lot R3) **vu de flanc, face tournée vers l'est (le moteur retourne l'image pour l'ouest)** : même meuble, même hauteur, même échelle, projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/display_cabinet_side.png` | 58 × 213 | maison Limashenka, mur ouest | `display_cabinet.png` (à commander avec elle, lot R3) **vu de flanc, face tournée vers l'est (le moteur retourne l'image pour l'ouest)** : même meuble, même hauteur, même échelle, projection orthographique oblique à 32° |
| 2 | `assets/hd2d/interior/props/sofa_salon_back.png` | 192 × 96 | maison Limashenka : le canapé fait face à l'horloge, au nord | `sofa_salon.png` (à commander avec elle, lot R3) **vu de dos** : même meuble, même hauteur, même échelle, projection orthographique oblique à 32° |
| 3 | `assets/hd2d/interior/props/bookshop_counter_side.png` | 67 × 152 | librairie, mur est | `bookshop_counter.png` (à commander avec elle, lot R3) **vu de flanc, face tournée vers l'est (le moteur retourne l'image pour l'ouest)** : même meuble, même hauteur, même échelle, projection orthographique oblique à 32° |
| 3 | `assets/hd2d/interior/props/crystal_projector_back.png` | 77 × 154 | salle de projection : le projecteur regarde la toile, au nord | `crystal_projector.png` (à commander avec elle, lot R3) **vu de dos** : même meuble, même hauteur, même échelle, projection orthographique oblique à 32° |

### R0.7 Les décors du dehors

Échantillon des cahiers n° 2 à 4 (props, façades, navires) : peu de défauts. Les façades, matières et flancs de bâtiments sont
en élévation de face, sans perspective, comme demandé ; les fontaines, puits, étals, tonneaux et caisses sont bien à l'échelle.
Défauts relevés :

| Prio | Fichier | Taille (px) | Constat | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/props/gangway.png` | (inchangée) | dessinée en plongée à plus de 50° (on voit le dessus des planches) alors que le port la montre de profil, du quai au navire | passerelle d'embarquement de bois et de fer, **vue de flanc** montant vers la droite, garde-corps à main courante, projection orthographique oblique à 32° (planches vues de dessus sur 17 px seulement) ; même nom, même taille ; sa rampe de tôle est `gangway_ramp` (lot R3) |
| 3 | `assets/hd2d/props/airship_ferry.png` | (inchangée ; les nouvelles vues sont au lot R7) | les silhouettes du passeur et du Barocupot sont dessinées de trois quarts du dessus (le pont est visible) : ce n'est pas un flanc sans perspective ; elles restent pour les plans lointains, mais ne se raccordent pas aux vues `ships/*_side` du lot R7 | rien à redessiner : le lot R7 demande des flancs en élévation, dans la même palette ; joindre ces deux silhouettes comme référence de rendu seulement |
| 3 | `assets/hd2d/props/bench.png` | (inchangée) | banc en élévation pure (le dessus de l'assise est invisible) alors que les tables voisines sont vues de trop haut ; il n'existe qu'en vue de face : un banc contre un mur est ou ouest ou tourné vers la rue n'a pas d'image | banc de bois à dossier ajouré, vu de face en projection orthographique oblique à 32° (assise visible sur 18 px) ; même nom, même taille ; ses vues de flanc sont les lignes `bench_side`, `bench_b_side` et `bench_stone_side` ci-dessous |
| 3 | `assets/hd2d/props/bench_b_side.png` | 48 × 160 | n'existe pas : un banc contre un mur est ou ouest, ou tourné vers la rue, n'a pas d'image | `bench_b.png` (jointe) **vu de flanc**, face tournée vers l'est (le moteur retourne l'image pour l'ouest) : même banc, même matière, même échelle ; l'assise se déroule vers le fond sur 81 px (longueur du banc × 0,53) ; projection orthographique oblique à 32° |
| 3 | `assets/hd2d/props/bench_side.png` | 48 × 140 | n'existe pas : un banc contre un mur est ou ouest, ou tourné vers la rue, n'a pas d'image | `bench.png` (jointe) **vu de flanc**, face tournée vers l'est (le moteur retourne l'image pour l'ouest) : même banc, même matière, même échelle ; l'assise se déroule vers le fond sur 81 px (longueur du banc × 0,53) ; projection orthographique oblique à 32° |
| 3 | `assets/hd2d/props/bench_stone_side.png` | 48 × 104 | n'existe pas : un banc contre un mur est ou ouest, ou tourné vers la rue, n'a pas d'image | `bench_stone.png` (jointe) **vu de flanc**, face tournée vers l'est (le moteur retourne l'image pour l'ouest) : même banc, même matière, même échelle ; l'assise se déroule vers le fond sur 71 px (longueur du banc × 0,53) ; projection orthographique oblique à 32° |

Les chaises de bistrot de `cafe_table.png` (bois cintré) sont les seules de style plus tardif : à garder si le café du village reste
rustique, sinon les remplacer par `chair_wood`.


### R0.8 Les ornières des rues (constaté en jouant, 15 octobre 2026)

**Constat** : `assets/hd2d/decals/cart_ruts.png` (cahier n° 2, lot B, 192 × 384) montre deux sillons
profonds et sombres, bordés de cailloux, **coupés net aux deux bouts**. Posé par morceaux de 4 m dans
la rue du village, il se lit comme des **sillons de labour** en travers du chemin. Il est retiré du
village en attendant (recette `tools/exterior_recipes/village.py`).

| Priorité | Fichier | Taille | Genre, ancre | Consigne |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/decals/cart_ruts.png` (même nom, **remplace** l'actuel) | 192 × 384 (2 × 4 m) | décalque de sol, **raccordable en longueur** (le bord haut se raccorde au bord bas), alpha doux sur les bords gauche et droit | deux traces de roues de charrette **discrètes** dans la terre battue, parallèles, écartées de 1,2 m, vues de dessus : un léger creux plus foncé de 15 à 20 cm de large, terre tassée un peu plus lisse, quelques graviers épars sans bordure de cailloux ; contraste faible avec `path_dirt` (le chemin doit rester un chemin, pas un champ labouré) ; **aucun bout visible** : la trace continue hors de l'image en haut et en bas ; pas d'ombre portée, pas de relief marqué |
| 2 | `assets/hd2d/decals/cart_ruts_end.png` | 192 × 192 (2 × 2 m) | décalque de sol, alpha doux, bord haut raccordé à `cart_ruts` | la fin des deux traces : elles s'estompent et disparaissent dans la terre sur 1,5 m (pour finir une traînée sans coupure) |

**À ne pas faire** : des sillons profonds, des bourrelets de cailloux, des bouts coupés droits, une
couleur plus sombre que la terre de plus de 15 %.

### R0.9 Les façades du village la nuit (constaté par le garant de la qualité, 15 octobre 2026)

**Constat** (`docs/QUALITE.md`, QC-16 ; capture `build/qc/2026-10-15-avant/village_cafe_nuit.png`) : la
nuit, toutes les façades du village sont éteintes. Le café, qui sert l'alcool le soir (VEX), a l'air
fermé : vitrine bleu-noir, lanterne sans flamme. Le moteur sait déjà remplacer une image par sa version
de nuit : une sœur `<nom>_night.png` au même cadrage, prise quand la nuit tombe
(`HD2DLightTargets`, cahier n° 3, section 8.4) ; il ne manque que les images.

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/buildings/cafe_night.png` | 672 × 528 (comme `cafe.png`) | façade, même cadrage au pixel près | `cafe.png` (jointe) **la nuit, café ouvert** : même dessin, mêmes contours ; la vitrine et la porte vitrée éclairées de l'intérieur, lumière chaude **en aplat #FFE6A6** sur les carreaux (silhouettes des tables et des lampes suspendues en contre-jour plus sombre), la lanterne de façade allumée (flamme et verre #FFE6A6), un halo doux peint autour d'elle sur le mur ; le reste de la façade dans la pénombre bleue de la nuit (pierre et colombages assombris, bleutés, sans noir pur) ; store replié |
| 2 | `assets/hd2d/buildings/limashenka_house_night.png` | 576 × 576 | idem | `limashenka_house.png` (jointe) la nuit : une seule fenêtre du rez-de-chaussée allumée (carreaux #FFE6A6, rideau à demi tiré), les autres sombres ; pénombre bleue |
| 2 | `assets/hd2d/buildings/village_house_stone_night.png` | 480 × 576 | idem | `village_house_stone.png` (jointe) la nuit : une fenêtre de l'étage allumée (#FFE6A6), les volets du bas fermés ; pénombre bleue |
| 2 | `assets/hd2d/buildings/cottage_thatch_a_night.png` | 480 × 528 | idem | `cottage_thatch_a.png` (jointe) la nuit : la petite fenêtre allumée d'une lueur de bougie (#FFE6A6 au centre, plus orangé seulement sur le cadre de bois) ; chaume et torchis bleutés |
| 3 | `assets/hd2d/buildings/cottage_thatch_b_night.png` | 672 × 240 | idem | `cottage_thatch_b.png` (jointe) la nuit : une des trois fenêtres allumée (#FFE6A6), volets des deux autres fermés |
| 3 | `assets/hd2d/buildings/cottage_thatch_c_night.png` | 384 × 480 | idem | `cottage_thatch_c.png` (jointe) la nuit : la lucarne du chaume allumée (#FFE6A6) |

**À ne pas faire** : changer le cadrage, la taille ou le dessin (l'image de nuit remplace celle du jour
au pixel près) ; peindre les vitres allumées en orangé (le moteur n'allume que les pixels proches de la
couleur de lueur du bâtiment : voir 3.6 ; (QO) à la livraison, régler `Building.window_glow_color` sur
#FFE6A6 pour ces façades, la règle par défaut allumant en fait #FFCA63) ; un ciel ou un fond (transparence
inchangée) ; tout allumer (un village de campagne dort : une fenêtre ou deux par maison au plus).

### R0.10 Les remplaçants qui se voient au premier rang (priorités relevées)

**Constat** (`docs/QUALITE.md`, QC-17 et QC-18 ; captures `village_chaumieres_matin.png`,
`village_jardin_matin.png`, `village_lavoir_matin.png`) : au village, quatre remplaçants du lot R3 sont au
premier rang d'une vue nommée et se voient tout de suite. Ils sont déjà commandés (section 5.3) ; leur
priorité passe avant le reste du lot R3. Consignes : celles de la section 5.3, inchangées.

| Prio (était) | Fichier | Ce qui se voit |
| --- | --- | --- |
| 1 (2) | `assets/hd2d/buildings/materials/roof_thatch.png` | le toit des trois chaumières et de la grange : des rayures régulières de planches et les mêmes taches vertes répétées tous les 2 m, un toit de tôle plutôt qu'un chaume |
| 1 (3) | `assets/hd2d/props/washing_trough.png` | le lavoir, point nommé du plan : un rectangle pâle à liseré bleu au premier plan |
| 2 (3) | `assets/hd2d/props/haystack.png`, `assets/hd2d/props/cart_hay.png` | la meule et la charrette à foin du grand jardin : des aplats jaunes sans paille |
| 2 (3) | `assets/hd2d/props/beehives.png` | les ruches, point nommé du plan |

### R0.11 Les traces de pas (bouts coupés)

**Constat** (`docs/QUALITE.md`, QC-28 ; capture `entrepot_cour_matin.png`) : `assets/hd2d/decals/footprints.png`
(96 × 288, six empreintes de bottes d'adulte) commence et finit net ; posée plusieurs fois dans la cour et au
champ, elle fait des pointillés de 3 m qui s'arrêtent au milieu de rien, comme les ornières (R0.8). Le moteur
n'en garde que quatre dans la cour et trois au champ en attendant.

| Prio | Fichier | Taille | Genre, ancre | Consigne |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/decals/footprints.png` (même nom, **remplace** l'actuel) | 96 × 288 (1 × 3 m) | décalque de sol, alpha doux | une traînée de **petits pas d'enfant** (pieds de 18 cm, pas de 45 cm) et de pas d'adulte mêlés, en léger zigzag, sur la terre battue : les premières et les dernières empreintes **s'estompent** (moins marquées, à demi couvertes de poussière) ; contraste faible, aucune ombre portée |

**À ne pas faire** : six empreintes identiques en file, des bouts nets, un contraste plus fort que les
cailloux du sol.

### R0.12 La colline des étoiles : le vide et le sentier (reprise visuelle C3b, 15 octobre 2026)

**Constat** (carte `colline`, vues `bord` et `large` de `tests/integration/demo_c3.gd` ; captures `build/c3b/avant/` et
`build/c3b/apres/`). La caméra regarde le nord à 32° : au sommet, **elle ne voit jamais la falaise du cap** (elle est au
nord de la terre, face à l'ombre). Le vide se lit par la côte, la mer de nuages, des rochers qui flottent et des îles
lointaines (images déjà livrées, posées par la recette). Ce qui manque pour **sentir la falaise** : des **piliers de
roche qui sortent de la mer de nuages**, à 20 ou 40 m au nord du bord, dont la face tournée vers le sud, elle, se voit : on
y lit la hauteur du cap et la profondeur de la mer de nuages. Et le sentier de la colline n'a que des cailloux
épars : il lui faut des **dalles plates claires** (les `ring_stone_flat_*` livrées sont des ovales sombres : posées sur
l'herbe, elles se lisent comme des trous ; la colline les a retirées).

| Prio | Fichier | Taille (px) | Genre, ancre | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/sky/sea_stack_a.png` | 288 × 1152 (6 × 24 m à 48 px/m) | pilier dans la mer de nuages, **alpha doux** dans les 4 derniers mètres du bas, ancre milieu du bord bas | pilier de roche claire (#C2B49F) en strates horizontales et fissures verticales, vu de face (la face tournée vers le sud, lumière de la gauche), haut de 24 m, large de 6 m à la base et de 4,5 m au milieu, une couronne d'herbe d'automne (#A8B040) et de bruyère au sommet avec un petit arbre noueux ; la base se dissout dans une brume rose pâle et gris lavande (alpha doux), aucun sol sous le pilier |
| 2 | `assets/hd2d/sky/sea_stack_b.png` | 384 × 1344 (8 × 28 m à 48 px/m) | idem | pilier plus massif, deux ressauts (une corniche à mi-hauteur, des racines pendantes), mousse dans les fissures, herbe haute au sommet ; même lumière, même brume au pied |
| 3 | `assets/hd2d/sky/sea_stack_c.png` | 192 × 768 (4 × 16 m à 48 px/m) | idem | aiguille de roche étroite et penchée, quelques touffes d'herbe, une arche naturelle à mi-hauteur ; même brume au pied |
| 2 | `assets/hd2d/decals/path_flagstones_a.png` | 192 × 192 (2 × 2 m) | décalque de sol, **alpha doux** sur le bord, centre = point posé | quatre dalles plates de calcaire clair (#C8BBA6), vues de dessus, de 40 à 70 cm, aux bords arrondis, jointoyées d'herbe courte et de mousse, un peu de terre battue (#C89A5A) autour ; contraste modéré avec la terre du sentier (plus clair, pas blanc), aucune ombre portée, **aucun contour noir** |
| 2 | `assets/hd2d/decals/path_flagstones_b.png` | 144 × 144 (1,5 × 1,5 m) | idem | deux dalles et un caillou, même matière, même terre autour |

**À ne pas faire** : un pilier posé sur un sol (il flotte dans la brume : sa base est invisible) ; une silhouette plate
sans strates ; des dalles en ovales sombres ou cernées de noir comme `ring_stone_flat_*` ; des dalles régulières
alignées comme un dallage (le sentier est de terre, les dalles y sont posées ça et là).

### R0.13 Les signes d'interaction (constaté en jouant, 15 octobre 2026)

**Constat** : l'invite « E / A : Parler » était une pastille de texte au milieu de l'écran, lourde et
toujours la même. Le lot U1 (interface « Nuit douce ») la remplace par un **petit signe posé au-dessus
de la cible** à portée (`src/ui/interact_signs.gd`) : plein sur la cible du joueur, pâle sur les autres.
Il est dessiné **à taille fixe à l'écran** (20 à 28 px dans une image de 1280 × 720, 30 à 42 px en
1920 × 1080), en fondu, il respire et rebondit à l'appui. Les images actuelles sont des remplaçants
dessinés par `tools/hd2d_sky.py` (formes simples à l'outil).

| Priorité | Fichier | Taille | Genre, ancre | Consigne |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/fx/sign_talk.png` | 64 × 64 | icône, fond transparent, alpha doux, centrée, bas du dessin à 4 px du bord bas | **parler** : une petite bulle de dialogue arrondie, sa pointe en bas à gauche, trois points « … » au milieu ; bulle crème #F6EEE4, contour doré #E8C98A fin (3 à 4 px), points prune #3A2A40 ; une ombre douce prune en dessous (2 px, floue) pour se détacher d'un sol clair |
| 2 | `assets/hd2d/fx/sign_examine.png` | 64 × 64 | idem | **examiner** : une étincelle à quatre branches fines (étoile de lumière), crème au cœur et dorée au bord, une seconde étincelle plus petite en haut à droite ; aucun œil ni loupe |
| 2 | `assets/hd2d/fx/sign_take.png` | 64 × 64 | idem | **prendre** : une petite main ouverte, paume vers le spectateur, doigts serrés et pouce écarté, crème au contour doré, dessinée simplement (pas de jointures, pas d'ongles) |
| 2 | `assets/hd2d/fx/sign_enter.png` | 64 × 64 | idem | **entrer, sortir, embarquer** : une porte cintrée vue de face, encadrement doré, intérieur prune #3A2A40, une flèche crème qui monte au milieu (on passe la porte) |

Les quatre se commandent dans la même conversation : même épaisseur de contour, même ombre, même
poids visuel (chacune remplit environ 80 % du carré). Elles doivent rester lisibles **réduites à
20 px** (vérifier en réduisant l'image) et sur un sol clair comme sur un mur sombre.

**À ne pas faire** : du texte ou une lettre de touche dans l'image (le rappel « E » ou « A » est dessiné
par le jeu à côté du signe) ; un fond ou un cadre carré ; des couleurs vives ou saturées (rouge, bleu
électrique) ; du pixel art grossier (ces images sont réduites, pas agrandies) ; un contour noir épais.

## 3. Lot R1 : l'entrepôt complet

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
  (les versions de nuit sont au lot R6) ;
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

Ce lot ajoute deux genres au rappel du cahier n° 3 :

- **façade** (`buildings/<nom>.png`) et **flanc** (`buildings/<nom>_side.png`) : élévations sans
  perspective, fond transparent, mur collé aux bords gauche, droit et bas ; type `long` (faîtage parallèle à
  la façade) : l'image s'arrête à l'égout du toit, bordure du toit comprise (10 à 20 cm) ; flanc en pignon
  (profondeur × faîte) ou gouttereau (profondeur × hauteur du mur), **modelé doux et symétrique**, l'avancée du
  toit ne descend jamais sous le haut du mur ; fenêtres **toujours éclairées**, comme celles de
  `warehouse_main.png` ;
- **panneau extérieur** (`props/<nom>.png`) : objet debout vu de face, légèrement plongeant, fond
  transparent, collé au bord bas et centré ; **premier plan** : grandes masses sombres et contrastées, peu de
  petits détails (le flou de profondeur du jeu les adoucit).

**Références supplémentaires à joindre** : `assets/hd2d/buildings/warehouse_main.png`,
`warehouse_main_side.png` et `warehouse_porch.png` pour les façades ; `assets/hd2d/props/bush_c.png` et
`tree_old_pine.png` pour les fourrés et la haie.

**Pour les remplaçants** : une image livrée sous le nom du remplaçant le remplace sans toucher au code.
Joindre l'image du remplaçant actuel quand la ligne le dit (elle donne le cadrage voulu).


### 3.1 Les façades et les flancs de l'entrepôt (30 × 14 m)

**Le bâtiment** (`CARTE.md`, 2.4) : 30 × 14 m, deux niveaux, façade sud à z = 26 **(original : l'œuvre ne
décrit ni façade ni toit)** ; il tient les pièces de l'œuvre : un bâtiment de bois ancien, prévu pour une
cinquantaine de personnes, si délabré qu'un visiteur le compare à une étable en ruine (V2, V5). Deux
volumes :

| Volume | Emprise (m) | Murs, toit | Façade sud | Flanc |
| --- | --- | --- | --- | --- |
| ouest | x 30 → 48, z 12 → 26 | murs de 6,5 m, faîte à 10 m, long, ardoise | `warehouse_front_a`, 1728 × 624 px (18 × 6,5 m) | `warehouse_front_a_side`, pignon, 1344 × 960 px (14 × 10 m) |
| est | x 48 → 60, z 12 → 26 | murs de 6,5 m, **toit plat en terrasse** (le toit à linge) | `warehouse_front_b`, 1152 × 624 px (12 × 6,5 m) | `warehouse_front_b_side`, gouttereau, 1344 × 624 px (14 × 6,5 m) |

**Ce que montrent les façades** : bardage de planches brun foncé rapiécé sur soubassement de pierre,
comme `warehouse_main` (jointe) ; au rez-de-chaussée, de l'ouest à l'est : deux fenêtres dépolies (salle de
bains), une petite (toilettes), un mur plein (placard), **la porte d'entrée à deux battants** (centre de la
pièce de l'entrée), le porche devant (`warehouse_porch`, livré : il se pose devant, ne le dessine pas), deux
fenêtres (salle de jeux), deux fenêtres (infirmerie) ; à l'étage, deux fenêtres par dortoir, une petite aux
toilettes ; plannings punaisés près de la porte et plaque de bronze **sans texte** (V1). Le flanc ouest
montre la porte de service ; le flanc est, la fenêtre à banc de la salle de lecture vue de dehors et une
échelle de bois contre le mur.

**Consigne** : commande la façade puis son flanc dans la même conversation, façade d'abord, et joins la
façade au flanc.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/buildings/warehouse_front_a.png` | 1728 × 624 (18 × 6,5 m) | façade, type `long` | façade sud du volume ouest de l’entrepôt (`CARTE.md`, 2.4) : bardage brun foncé rapiécé sur soubassement de pierre, de l’ouest à l’est deux fenêtres dépolies, une petite, un pan plein, puis la porte d’entrée à deux battants **centrée à 12 m du bord gauche** (le porche `warehouse_porch` se pose devant) ; à l’étage, deux fenêtres par dortoir et une petite ; plannings punaisés et plaque de bronze près de la porte ; même rendu que `warehouse_main` |
| 1 | `assets/hd2d/buildings/warehouse_front_a_side.png` | 1344 × 960 (14 × 10 m) | flanc, pignon | pignon ouest : la porte de service à 8 m de l’angle sud (bord gauche de l’image), une fenêtre par niveau, lierre, une gouttière |
| 1 | `assets/hd2d/buildings/warehouse_front_b.png` | 1152 × 624 (12 × 6,5 m) | façade, type `long` à toit plat | façade sud du volume est : même bardage, au rez-de-chaussée deux fenêtres (salle de jeux) puis deux (infirmerie), à l’étage deux fenêtres par dortoir ; en haut, le rebord plat du toit-terrasse (la rambarde et le linge sont des panneaux posés dessus) |
| 1 | `assets/hd2d/buildings/warehouse_front_b_side.png` | 1344 × 624 (14 × 6,5 m) | flanc, gouttereau | flanc est : au rez-de-chaussée, la fenêtre de la salle de lecture vue de dehors (banquette en saillie) à 3,5 m du bord droit, une petite fenêtre ; à l’étage, deux fenêtres ; une échelle de bois appuyée |


### 3.2 Les remplaçants à remplacer

Cinq images que le moteur dessine lui-même en attendant (`tools/hd2d_interior.py`) ; les lignes
`door_frame_wood` et `wallitem_height_marks` sont les seules à ne plus venir telles quelles du cahier
n° 3 (le chambranle a été demandé par le moteur ; les marques de taille deviennent celles de l'acte 1).
Joindre le remplaçant actuel de chaque image : il donne le cadrage voulu.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/door_frame_wood.png` | 126 × 221 (1,3 × 2,3 m) | porte, chambranle seul, ancre au milieu du bord bas | chambranle de bois brun patiné autour d'une ouverture de **106 × 211 px (1,1 × 2,2 m) entièrement transparente** : deux montants de 10 px de large, un linteau de 10 px de haut, une petite moulure à l'angle haut, usure aux arêtes ; **aucun battant, aucune porte, aucun seuil dessiné dans l'ouverture** (alpha 0 partout dedans : on voit la pièce voisine à travers). C'est la porte qu'on franchit en marchant, entre deux pièces ; même bois et même rendu que `door_room.png` (jointe) |
| 2 | `assets/hd2d/interior/floor_flagstone_cellar.png` | 384 × 384 | tuile de sol | dalles de la crypte des armes : grandes dalles de pierre gris sombre irrégulières de 50 à 80 cm, usées en creux, joints de terre et de mousse noire, taches d'humidité, poussière (V1, « Entrepôt de fées ») |
| 2 | `assets/hd2d/interior/wall_cellar_stone.png` | 384 × 288 | mur | mur de la crypte : moellons gris sombre jointoyés d'un mortier humide, traînées de salpêtre blanc, mousse noire au pied, aucune plinthe ; froid, la seule pièce sans bois (V1, « Entrepôt de fées ») |
| 2 | `assets/hd2d/interior/wallcut_stone.png` | 384 × 24 | haut de mur | coupe d'un mur de pierre vu de dessus : moellons gris et mortier, bord intérieur un peu plus clair ; raccord à gauche et à droite |
| 3 | `assets/hd2d/interior/wallitem_height_marks.png` | 38 × 154 (0,4 × 1,6 m) | élément de mur, bas au sol | marques de taille sur le plâtre : traits gravés au couteau et traits de crayon entre 0,9 et 1,5 m de haut, à côté de chacun un petit signe (étoile, fleur, cœur, épée) au lieu d'un nom ; deux traits presque au même niveau (V5, épilogue : les tailles de Nopht et de Rhantolk) ; les petites marquent leur taille depuis l'arrivée de Willem ; version au présent de l'acte 1 : traits plus rares, une dizaine de signes |


### 3.3 Le toit et le séchoir

Séchoir où flotte le linge le jour ; la nuit, poste d'observation des étoiles ; rambarde de métal abîmée et
trop basse pour Nygglatho (V2, V3, VEX). Le panier à linge (`laundry_basket`), la cheminée
(`chimney_brick`), le séchoir (`drying_frame`) et la rambarde (`roof_railing`) sont livrés. **Le toit est
une carte du dehors** (`CARTE.md`, 3.3) : `floor_roof_deck` y sert de matière de sol, et `roof_edge_slate`
et `floor_roof_deck` sont à confirmer par le moteur (une 28e couche de l'atlas du sol, E2).
Joindre `assets/hd2d/interior/props/roof_railing.png` et `drying_frame.png`.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/floor_roof_deck.png` | 384 × 384 | tuile de sol, **nom proposé, à confirmer par le moteur** | sol du toit-terrasse : planches grises délavées par la pluie, joints calfatés de goudron noir, taches de mousse et de lichen, une planche neuve plus claire, clous rouillés (V2, « De ce côté-ci de l'écran » : le toit à linge) |
| 1 | `assets/hd2d/interior/props/roof_hatch.png` | 96 × 58 (1 × 0,6 m) | meuble | trappe d'accès au toit ouverte, le haut d'une échelle de bois qui dépasse, couvercle rabattu (original) |
| 1 | `assets/hd2d/interior/props/roof_ladder.png` | 77 × 288 (0,8 × 3 m) | meuble | échelle de meunier de bois, raide, contre le mur, qui monte à une trappe ouverte au plafond (haut de l’image) ; un rai de jour par la trappe |
| 2 | `assets/hd2d/anim/drying_frame_wave.png` | 384 × 211, 4 images, 4 ips | bande animée | `drying_frame.png` (jointe) : le linge ondule au vent vers la droite, poteaux et cordes immobiles |
| 2 | `assets/hd2d/interior/props/roof_edge_slate.png` | 384 × 96 (4 × 1 m) | meuble, sans raccord à gauche et à droite, **format à confirmer par le moteur** | bord du toit en pente qui borde la terrasse : rangées d'ardoises bleu-gris (#5E6C86) qui descendent vers le bas de l'image, mousse, une ardoise cassée, gouttière de cuivre vert-de-grisé en bas |
| 2 | `assets/hd2d/interior/props/roof_railing_broken.png` | 192 × 77 | meuble, se raccorde à `roof_railing` | le même module dont un pan est tordu vers le dehors et un barreau manque (V3 : Almita tombe du toit) |


### 3.4 Les pièces : ce qui manque aux sols, aux lits et au mobilier

Du lot I, les priorités 1 et la plupart des priorités 2 sont livrées ; restent des bandes animées, des
décalques et quelques meubles. **Une bande animée à la fois** (section 2.5) : joindre l'image du meuble
qu'elle anime (`kitchen`, `clock`, `fireplace`…) et demander seulement les images qui bougent, le reste
identique au pixel près. Deux noms viennent de `CARTE.md` (12.1) : `desk_clean` (le bureau de la grande sœur, sans la
broche) et `desk_chtholly_mirror_up` (le bureau de Chtholly au miroir relevé, réservé à l'acte 2).

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/bed_iron_cover.png` | 192 × 67 (2 × 0,7 m) | même cadrage que `bed_iron`, **à confirmer par le moteur** | la couverture seule du même lit, à poser par-dessus un personnage couché : couverture grise et drap rabattu, à la même place au pixel près que dans `bed_iron.png` (bas de l'image = pied du lit au sol) ; transparent partout ailleurs (ni lit, ni oreiller) |
| 2 | `assets/hd2d/anim/bath_steam.png` | 192 × 144 (2 × 1,5 m), 6 images, 6 ips | bande animée, **alpha doux** | vapeur qui monte de l'eau chaude en volutes lentes ; le bas de l'image est la surface de l'eau (non dessinée) |
| 2 | `assets/hd2d/anim/comm_crystal_call.png` | 67 × 134, 4 images, 6 ips | bande animée | le même cristal qui s'allume et pulse d'un bleu clair lumineux (la lueur est dans le cristal, alpha net ; le jeu ajoute le halo), console identique au pixel près |
| 2 | `assets/hd2d/anim/leak_drip.png` | 24 × 96 (0,25 × 1 m), 4 images, 8 ips | bande animée, suspendue | une goutte d'eau qui se forme au plafond (haut de l'image) et tombe jusqu'au bas de l'image (le bord du seau) ; image 4 : une petite gerbe ; fond transparent |
| 2 | `assets/hd2d/anim/pot_steam.png` | 48 × 96 (0,5 × 1 m), 6 images, 8 ips | bande animée, **alpha doux** | vapeur blanche qui monte d'une marmite et s'étire ; le bas de l'image est le bord de la marmite (non dessinée) |
| 2 | `assets/hd2d/decals/bath_puddles.png` | 192 × 144 (2 × 1,5 m) | décalque | flaques et éclaboussures d'eau savonneuse sur le carrelage, quelques bulles, empreintes de petits pieds mouillés qui s'en vont |
| 2 | `assets/hd2d/decals/cards_floor.png` | 144 × 96 (1,5 × 1 m) | décalque | jeu de cartes éparpillé par terre vu de dessus, dos rouges, figures sans lettres ni chiffres ; sert aussi dans la chambre de la grande sœur (V1, « Entrepôt de fées ») |
| 2 | `assets/hd2d/decals/clothes_floor.png` | 192 × 144 (2 × 1,5 m) | décalque | vêtements jetés par terre vus de dessus : chemise, jupe, chaussettes dépareillées, une écharpe ; aucun sous-vêtement visible (V1 : le grand désordre de la grande sœur) |
| 2 | `assets/hd2d/decals/papers_floor.png` | 192 × 144 (2 × 1,5 m) | décalque | feuilles éparses par terre vues de dessus : un rapport, une coupure de magazine, un bon de commande, une enveloppe ; lignes grises, aucune lettre |
| 2 | `assets/hd2d/decals/runner_rug.png` | 96 × 384 (1 × 4 m) | décalque à bord plein, **sans raccord en haut et en bas** | tapis de couloir tissé brun et rouge passé, liseré ocre, usé au milieu en un chemin plus clair, une tache ; il se répète en longueur sans couture |
| 2 | `assets/hd2d/interior/props/desk_clean.png` | 106 × 101 (1,1 × 1,05 m) | meuble | `desk_clean_brooch` **sans la broche** : le bureau propre et vide de la grande sœur, au présent (à l’acte 1, Chtholly porte la broche) ; joindre `desk_clean_brooch.png` (livrée) : cette image en reprend le bureau au pixel près, moins la broche |
| 3 | `assets/hd2d/anim/wall_clock_swing.png` | 48 × 106, 4 images, 2 ips | bande animée | la même horloge : le balancier va et vient (la 4e image s'enchaîne sur la 1re), le reste identique au pixel près |
| 3 | `assets/hd2d/interior/props/desk_chtholly_mirror_up.png` | 106 × 101 | meuble | `desk_chtholly` avec le miroir à main **debout** : le miroir face contre le bureau est un détail du V2, à garder pour l’acte 2 |
| 3 | `assets/hd2d/interior/props/piano_old.png` | 154 × 134 (1,6 × 1,4 m) | meuble | vieux piano droit de bois sombre, couvercle ouvert, touches jaunies, une partition sans notes lisibles, bougeoirs vides, tabouret rond (V4, « La fille aux cheveux cramoisis » III) |
| 3 | `assets/hd2d/interior/props/polishing_trestle.png` | 115 × 86 (1,2 × 0,9 m) | meuble | tréteau de bois : un linge étendu, un seau d'eau, des chiffons pour polir les lames (VEX, prologue : on polit Seniorious avec de l'eau et un linge) |
| 3 | `assets/hd2d/interior/props/potted_plant.png` | 38 × 58 (0,4 × 0,6 m) | meuble | plante verte dans un pot de terre ébréché (V5 : les pots de fleurs qu'on casse) |
| 3 | `assets/hd2d/interior/wallitem_clippings.png` | 77 × 58 (0,8 × 0,6 m) | élément de mur, bas à 1,3 m | coupures de magazines pour filles épinglées : dessins de robes et de chapeaux, sans texte (V1) |
| 3 | `assets/hd2d/interior/window_dusty.png` | 96 × 96 (1 × 1 m) | fenêtre, appui à 1,3 m | petite fenêtre haute des archives, vitres grises de poussière, toile d'araignée dans un coin, loquet rouillé |


### 3.5 Le dehors : fourrés, haie, aulne et souche noyée

Le champ de ballon est bordé d'un bosquet profond et de fourrés où le ballon se perd ; une petite y plonge et
se lacère la cuisse sur les branches (V1, « Entrepôt de fées » ; scène 7.2). Autour de l'entrepôt, des
marécages sombres (VEX). Ces six panneaux sont aussi ceux du sentier et de la forêt profonde (lots R3 et R5 :
ne pas les recommander). Joindre `assets/hd2d/props/tree_old_pine.png` et `bush_c.png` pour le rendu.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/props/bramble_hedge.png` | 384 × 144 (4 × 1,5 m) | panneau, sans raccord à gauche et à droite | haie de ronces et d'églantiers qui borde le champ, mûres noires, cynorhodons rouges |
| 1 | `assets/hd2d/props/thicket_a.png` | 240 × 154 (2,5 × 1,6 m) | panneau | fourré de prunellier et d'aubépine : petites branches épineuses enchevêtrées, baies sombres, feuilles rousses ; dense, on n'y voit pas à travers |
| 1 | `assets/hd2d/props/thicket_b.png` | 192 × 134 (2 × 1,4 m) | panneau | fourré plus bas et plus large, ronces mêlées |
| 2 | `assets/hd2d/props/alder.png` | 384 × 672 (4 × 7 m) | panneau | aulne du marais : tronc sombre penché, racines qui plongent dans l'eau, feuillage vert-brun clairsemé d'automne |
| 2 | `assets/hd2d/props/marsh_snag.png` | 192 × 192 (2 × 2 m) | panneau | souche noyée, branches mortes grises qui sortent de l'eau, mousse et champignons |
| 2 | `assets/hd2d/props/thicket_c.png` | 288 × 173 (3 × 1,8 m) | panneau | grand fourré avec un trou sombre au ras du sol (là où roule le ballon, où plonge une petite) |

**Cote d'usage** : un fourré est **impénétrable à l'œil** (on n'y voit pas à travers) sauf le trou au ras du
sol de `thicket_c` ; `bramble_hedge` borde le champ sur 4 m sans raccord à gauche et à droite.


### 3.6 État de la livraison du lot R1 (15 octobre 2026) et correction à commander

Les 39 images du lot R1 sont livrées (PR n° 37), inscrites au manifeste et posées par les plans
(`docs/INTERIEURS.md`, « Le lot R1, posé ») : façades et flancs, sol et bord du toit, vapeur du bain, horloge
des archives, appel du cristal, bureaux, plante, tréteau. **Format tranché par le moteur** : `floor_roof_deck` n'est
pas une 28e couche de l'atlas du sol (ce serait changer le contrat du cahier n° 2 : atlas, deux shaders, `terrain.gd`,
tests) mais une tuile de 4 m posée en décalques sur la terrasse ; `roof_edge_slate` est un panneau de plein air
de 4 × 1 m, sans raccord à gauche et à droite (`docs/DECISIONS.md`, I2).

**Correction à commander (priorité 2) : les vitres des quatre façades ne s'allument presque pas la nuit.** Le moteur
allume les pixels dont la couleur est **proche de #FFE6A6 (255, 230, 166)** (`glow_color` de
`panel_core.gdshaderinc` : pleine lueur à moins de 0,05, nulle à plus de 0,12, distance en RVB linéaire) ; les
carreaux livrés sont plus orangés (de #FBD367 à #FCE496, dégradés) : seuls 15 % (façade ouest, pignon ouest) et 1 à 2 %
(façade est, flanc est) des pixels de vitre atteignent le seuil, et de nuit les fenêtres restent ternes, alors que celles des remplaçants de T1, peints près de #FFE6A6,
brillaient. À redemander **sans toucher au dessin** : mêmes images (`warehouse_front_a`, `warehouse_front_a_side`,
`warehouse_front_b`, `warehouse_front_b_side`), mêmes tailles, mais carreaux **en aplat #FFE6A6 (±6 par canal)** ;
le reflet en diagonale et le dégradé vers l'orange se font en dehors de ce vert-jaune (croisillons et ombres plus
foncés, reflets plus blancs que #FFFFF0, jamais d'orangé sur les carreaux). Variante côté moteur, si l'on préfère ne
rien redessiner : une couleur de lueur par bâtiment (`Building.window_glow_color`, PR « contrats » : demande dans
`docs/CONTRACT_REQUESTS.md`). Les fenêtres des intérieurs (`window_cross_*` et leurs versions de nuit du lot N) ne sont
pas concernées.

**(QO, 15 octobre 2026) Commande annulée** : la variante moteur est retenue (`Building.window_glow_color` et
`window_glow_tolerance`, réglées sur les carreaux livrés ; docs/QUALITE.md, QC-02). Ne rien redemander. Constat au
passage : le rendu lit l'image sans la convertir en linéaire, et la règle par défaut allume en fait les pixels
proches de #FFCA63 ; des carreaux en aplat #FFE6A6 resteraient éteints sans règle propre.

## 4. Lot R2 : les personnages de l'acte 1

### 4.0 Rappel du format (à coller avec le lot)

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

**Consigne** : colle le bloc de style, ce rappel, la fiche des animations (ci-dessous), puis « Planches de
sprites `assets/characters/<dossier>/<id>.png` (profil tourné vers la droite), `<id>_front.png` (de
face) et `<id>_back.png` (de dos), avec leurs JSON, fond transparent, mêmes animations et nombres
d'images dans les trois vues, une rangée par animation dans l'ordre du tableau, une seule
silhouette par case, hauteur debout **<n> px** dans toutes les images debout et les trois vues : »
puis le bloc de la planche (qui elle est, son tableau d'animations).

### 4.0 bis La fiche des animations, image par image

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

**Ce lot par ordre de scène** : 4.1 Willem (marais, bras, dos, ballon, marteau) ; 4.2 Nygglatho (blouse,
linge) ; 4.3 les gestes de métier des habitants déjà livrés ; 4.4 Kana et Giniette ; 4.5 les six fées
génériques restantes ; 4.6 les pyjamas ; 4.7 les tenues de pluie ; 4.8 le bâton ; 4.9 les reprises de
planches livrées.


### 4.1 Willem

Environ dix-huit ans, grand et mince, cheveux noirs en bataille, yeux noirs, sourire fatigué ; uniforme
militaire bleu nuit croisé à boutons dorés, un peu trop étroit (V1). Ses planches font **168 px** de
hauteur debout (1,75 m). Joindre `willem.png`, `willem_front.png`, `willem_back.png`, et la tenue de la
planche (`willem_coat` ou `willem_home`, trois vues). Aucune des planches ci-dessous n'a d'épée.

**Quatre planches de scène sont nouvelles** : la fiche des animations ne les connaît pas, mais l'acte 1 les
joue (`ACTE1.md`, scènes 1.3, 7.2, 7.4 et le ballon, `VIE.md`, 2.1) et le moteur n'a aucun repli : sans
elles, Willem tombe, porte et joue avec le sprite d'un autre geste. **Le format (planche d'un seul
dessin qui contient Willem et la personne qu'il porte) est à confirmer par le moteur** ; l'autre voie est de
poser deux sprites l'un sur l'autre, et alors seules `willem_marsh` et `willem_life` servent.

#### `willem/willem_marsh` : Willem dans le marais (prio 1)

Scène 1.3 : Willem avance à tâtons sur la levée, esquive deux fois l'embuscade de Pannibal, glisse à la
troisième et tombe dans l'eau basse, puis se relève trempé (V1, « L'Homme sans Marque »). Tenue de
`willem_coat` (long pardessus gris-brun à capuche par-dessus l'uniforme), même visage, mêmes cheveux. La
gerbe d'eau et Pannibal assise sur son dos sont posées par le jeu : **ne les dessine pas**.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de `willem_coat` (étalon de taille, ne pas redessiner) |
| `effondre` | 4, 8 | 0 le pied glisse, les bras battent ; 1 il bascule en avant, les mains devant ; 2 il plonge, à genoux dans l'eau basse ; 3 à plat ventre dans l'eau, la joue de côté, les bras écartés, immobile (c'est le dos sur lequel s'assoit Pannibal) ; ni sang, ni blessure |
| `assis` | 2, 2 | assis dans l'eau basse, pardessus trempé et collé au corps, cheveux plaqués, une main sur le front, l'air accablé ; image 1 : il secoue la tête d'1 px |

#### `willem/willem_carry` : Willem porte une petite (prio 1)

Scène 7.2 : une petite (`fairy_06`, cheveux framboise courts, tunique ocre, jambière à la cuisse **bandée de
blanc**) s'est lacéré la cuisse dans le fourré ; Willem la prend dans ses bras et court vers l'entrée (V1,
« Entrepôt de fées »). Uniforme de `willem_home`, sans arme. **La petite fait partie du dessin** : une seule
silhouette par case, la hauteur debout de 168 px est celle de Willem. Joindre aussi `fairy_06.png`,
`fairy_06_front.png`, `fairy_06_back.png`. Pudeur : la petite est habillée, portée comme un enfant blessé, la
tête contre l'épaule de Willem ; on voit un bandage, jamais une plaie.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, la petite dans les bras, sa jambe bandée qui pend, son bras autour du cou de Willem ; image 1 : respiration |
| `marche` | 6, 10 | pas rapides et soutenus, la petite qui ballotte un peu |
| `course` | 5, 14 | il court, penché, la petite serrée contre lui, la tête jamais plus haute que la hauteur debout |

#### `willem/willem_piggyback` : Willem porte Chtholly sur le dos (prio 1)

Scène 7.4 : Chtholly, empoisonnée par le venenum, tombe à genoux sur la passerelle ; Willem la prend sur son
dos et rentre sous la pluie, Ithea à côté, Nephren derrière avec les épées (V1, « Entrepôt de fées »). Willem
dans la tenue de `willem_coat` ; **Chtholly est dessinée sur son dos** : cheveux bleus longs et deux couettes
hautes, uniforme bleu marine, la tête posée sur son épaule, les bras croisés devant son cou, les yeux mi-clos ;
**sans Seniorious** (Nephren porte les épées). Hauteur debout : celle de Willem, **168 px** ; ses jambes à elle
pendent des deux côtés de la taille. Joindre `willem_coat` et `chtholly_home` (trois vues chacune). La pluie
n'est pas dessinée.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, Chtholly sur le dos, qui respire doucement ; image 1 : la tête de Chtholly glisse d'1 px |
| `marche` | 6, 10 | marche lente, épaules rentrées, un peu penché sous le poids (« elle pèse moins que les épées ») |
| `parle` | 2, 6 | Willem tourne un peu la tête vers elle en parlant ; Chtholly ne bouge pas |

#### `willem/willem_life` : Willem joue au ballon (prio 2)

Willem fait des passes avec les petites, sans jamais marquer (`VIE.md`, 2.1 ; V1, « Les filles de l'entrepôt »).
Planche complémentaire de `willem_home` (uniforme sans arme) : joindre `willem_home.png`, `_front`, `_back`.

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de `willem_home` (étalon) |
| `frappe` | 4, 14 | passe du pied nonchalante, sans élan ; 0 la jambe en arrière ; 1 pied d'appui planté ; 2 **frappe** : la jambe tendue devant, à 20 cm du sol (`coup` : [2]) ; 3 accompagnement, bras un peu écartés ; le ballon n'est pas dessiné |

#### `willem/willem_repair` : Willem répare (prio 2)

Scène 12 (il répare le plafond qui fuit) : uniforme, manches retroussées, un clou entre les dents (V4, transposé).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | debout, marteau à la main, l'autre main sur la hanche |
| `travaille` | 4, 6 | martèle au-dessus de sa tête, bras levé, comme pour clouer une planche au plafond qui fuit (V2 ; V3) |
| `porte` | 6, 10 | marche avec trois planches sur l'épaule et le marteau à la ceinture |


### 4.2 Nygglatho

Une troll à l'air de jeune femme, une tête de plus que tout le monde ; longs cheveux rose saumon, yeux vert
printanier, chemisier vert vif, tablier blanc, coiffe blanche à volants (V1). Ses planches font **178 px** de
hauteur debout (1,85 m). Joindre `nygglatho.png`, `nygglatho_front.png`, `nygglatho_back.png`. La planche
de pluie (`nygglatho_rain`) est au tableau de la section 4.7.

#### `nygglatho/nygglatho_labcoat` : à l'infirmerie (prio 1)

Longue blouse blanche de laboratoire par-dessus ses vêtements, cheveux attachés (V1 ; V3). Scène 7.5 : Nygglatho soigne Chtholly en blouse.

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


### 4.3 Les gestes de métier des habitants déjà livrés

Les habitants du village et de la ville n'ont que `repos`, `marche` et `parle` (`CONTRACT_REQUESTS.md`, D2 ;
`VIE.md`, 2.6 et 2.7). Chaque geste est une **planche de geste** `<id>_work` (même nom que `willem_cook`,
`nygglatho_tea`) : sa 1re rangée est `repos`, **recopiée au pixel près** de la planche existante de la même
vue, puis seulement `travaille` (et `porte` quand la ligne le dit). Joindre les trois vues du personnage ;
le moteur peut aussi les fondre dans la planche existante (**nom `_work` et format à confirmer par le
moteur**). Fiche des animations : celle de 4.0 bis.

#### `snack_vendor/snack_vendor_work` : le lycanthrope à la poêle (prio 1)

Hauteur debout : **154 px** (1,6 m). Homme-loup brun au pelage hirsute, gilet de cuir sur chemise de lin
retroussée, tablier ; ses oreilles tombent quand les fées entrent (V1, « Directeur en carton » ; scène 3.3).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante |
| `travaille` | 4, 6 | il fait sauter une poêle de fonte à long manche d'un coup de poignet : 0 la poêle posée, du lard qui grésille ; 1 elle monte ; 2 en l'air, le lard qui tourne ; 3 il la rattrape ; la poêle est dessinée, le réchaud et le comptoir ne le sont pas |

#### `cat_waiter/cat_waiter_work` : le serveur homme-chat (prio 2)

Hauteur debout : **158 px** (1,65 m). Homme-chat gris au long tablier blanc, gilet brun ; il balaie la
terrasse le matin et offre des jus aux fées en cachette du patron (VEX, « Cinq cents ans » ; scène 9.3).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante (plateau et tasse en main) |
| `travaille` | 4, 6 | il balaie d'un balai de paille, de gauche à droite et retour ; balai dessiné, sol non dessiné |
| `porte` | 6, 10 | marche en portant un plateau de trois verres de jus (orange, rouge, jaune) et une carafe |

#### `baker/baker_work` : le boulanger grincheux (prio 2)

Hauteur debout : **192 px** (2 m). Homme-ours brun, bedonnant, tablier de farine, manches retroussées ;
patron grincheux de la boulangerie où travaille Lakhesh (V3, « Je suis à la maison »).

| Animation | Images, ips | Consigne propre |
| --- | --- | --- |
| `repos` | 2, 2 | recopiée au pixel près de la vue existante (une miche à la main) |
| `travaille` | 4, 6 | il pétrit une grosse pâte de ses deux pattes, penché, puis la retourne ; la pâte et le pétrin ne sont pas dessinés |
| `porte` | 6, 10 | marche en portant une pile de six miches rondes contre le ventre |


### 4.4 Kana et Giniette

#### `kana/kana` : Kana (prio 1)

Hauteur debout : **110 px** (1,15 m). Nommée dans la tour de fées (VEX, « Le cas de la fée aux
cheveux gris ») ; plus tard parieuse qui chipe le butin (V5, épilogue). Apparence **(original)** :
une dizaine d'années, cheveux turquoise vif coupés court en épis, taches de rousseur, sourire de
chipeuse ; salopette de toile brune rapiécée sur une chemise jaune moutarde, poches pleines,
bottines usées. Planche neuve : rangées des petites (`repos` 2/2, `marche` 6/10, `parle` 2/6, `course` 5/14, `saut` 4/12, `frappe` 4/14 [2], `lance` 4/12 [2], `grimpe` 4/8, `assis` 2/2, `lit` 2/2, `dort` 2/1, `tombe` 4/10) ; consignes propres : `repos` mains dans les poches, l'œil
malin ; `parle` un clin d'œil ; `course` elle file en serrant quelque chose contre elle ; `saut`
elle saute sur la pile (tour de fées) ; `lit` elle cache une friandise derrière le livre ;
`tombe` elle rit en tombant. Portrait 256 × 256 (tableau ci-dessous).

#### `giniette/giniette` : Giniette (prio 1)

Hauteur debout : **101 px** (1,05 m). Nommée dans la tour de fées (VEX). Apparence **(original)** :
huit ans environ, cheveux miel doré en deux nattes nouées de rubans verts, grands yeux bruns ; robe
chasuble vert bouteille sur une chemise crème, tablier à poches, chaussettes qui tombent. Planche neuve : rangées des petites (`repos` 2/2, `marche` 6/10, `parle` 2/6, `course` 5/14, `saut` 4/12, `frappe` 4/14 [2], `lance` 4/12 [2], `grimpe` 4/8, `assis` 2/2, `lit` 2/2, `dort` 2/1, `tombe` 4/10) ; consignes propres : `repos` timide, les mains derrière le dos ; `parle` elle tortille
une natte ; `course` elle suit les autres en retard ; `saut` elle saute en dernier sur la pile ;
`grimpe` prudente ; `dort` serrée contre une peluche dessinée. Portrait 256 × 256 (tableau ci-dessous).

Elles sont de la tour de fées de la scène 10.5 (`ACTE1.md`) : sans elles, le repli est `fairy_03` et
`fairy_05`.

**Portraits** (`assets/characters/<id>/<id>_portrait.png`, **256 × 256**, buste de la tête aux épaules, visage
de trois quarts tourné vers la droite, fond transparent, même rendu que les portraits livrés ; joindre
`assets/characters/tiat/tiat_portrait.png`) :

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/characters/giniette/giniette_portrait.png` | 256 × 256 | portrait, fond transparent, buste de trois quarts vers la droite | Giniette (section 4.4) : nattes miel dorées à rubans verts, grands yeux bruns, timide |
| 2 | `assets/characters/kana/kana_portrait.png` | 256 × 256 | portrait, fond transparent, buste de trois quarts vers la droite | Kana (section 4.4) : cheveux turquoise en épis, taches de rousseur, sourire de chipeuse, col de la chemise jaune moutarde |


### 4.5 Les six fées génériques restantes

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

Dossier `assets/characters/fairy_NN/`. Les joueurs pourront les renommer ; leurs tenues varient pour qu'une
foule de dix ne montre jamais deux fois la même. Consignes propres communes : elles jouent avec entrain ;
chacune garde son accessoire (ruban, bandage, livre) du même côté dans toutes les images. Les six premières
sont livrées (`fairy_01` à `fairy_06`) ; **demande d'abord une planche d'ensemble des six, côte à côte à
l'échelle**, puis chaque planche à part (section 2.6).

| Prio | Planche | Âge, hauteur debout | Rangées | Apparence (original) |
| --- | --- | --- | --- | --- |
| 1 | `fairy_11/fairy_11` | 14 ans, 134 px (1,4 m) | grandes | cheveux vert mousse mi-longs à frange, blouse et longue jupe brune, un livre sous le bras gauche |
| 1 | `fairy_12/fairy_12` | 15 ans, 139 px (1,45 m) | grandes | cheveux aigue-marine argentée en chignon bas, tablier de cuisine (la cuisinière du jour), manches retroussées |
| 2 | `fairy_07/fairy_07` | 10 ans, 110 px | petites | cheveux vert d'eau tressés en couronne, robe de lainage bleu canard, châle croisé |
| 2 | `fairy_08/fairy_08` | 11 ans, 115 px (1,2 m) | petites | cheveux ambre cuivré en queue de cheval, chemise à carreaux trop grande, pantalon roulé aux chevilles |
| 2 | `fairy_09/fairy_09` | 12 ans, 120 px (1,25 m) | petites | cheveux jaune paille lisses au carré, robe-tablier rayée bleu et blanc |
| 2 | `fairy_10/fairy_10` | 13 ans, 130 px (1,35 m) | grandes | cheveux rose poudré longs noués d'un ruban, robe de lainage gris-mauve, gilet |

**Ajout pour `fairy_12`** (la cuisinière du jour, scène 4.1 : elle regarde Willem faire et s'indigne du
règlement ; `VIE.md`, 2.5) : en plus des rangées des grandes, **`travaille` (4 images, 6 ips, boucle)** :
elle remue une marmite avec une grande louche, tablier de cuisine, manches retroussées ; la marmite n'est
pas dessinée, la louche l'est (**le nom `travaille` pour une fée de cuisine est à confirmer par le moteur**,
c'est celui de la toilette des pyjamas).


### 4.6 Les pyjamas

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
| 1 | `chtholly/chtholly_pajamas` | 144 px | aînées | pyjama bleu ciel et gilet de laine gris passé par-dessus, cheveux en bataille, sans couettes (VEX) |
| 2 | `almita/almita_pajamas` | 91 px | petites | combinaison de nuit en flanelle jaune pâle, bonnet de nuit qui tombe sur un œil |
| 2 | `ithea/ithea_pajamas` | 139 px | aînées | chemise de nuit crème, cheveux lâchés, bâille à l'image 1 du `repos` |
| 2 | `nephren/nephren_pajamas` | 125 px | aînées | pyjama gris lavande trop grand, manches qui couvrent les mains, le livre rouge sous le bras |
| 3 | `fairy_02/fairy_02_pajamas` | 101 px | petites | la fée `fairy_02` en chemise de nuit blanche à pois bleus |
| 3 | `fairy_06/fairy_06_pajamas` | 110 px | petites | la fée `fairy_06` en pyjama de flanelle à carreaux verts |

Les quatre pyjamas des petites nommées (`tiat`, `collon`, `pannibal`, `lakhesh`) sont livrés. Joindre, pour
chaque planche, les trois vues de la planche de base du personnage.


### 4.7 Les tenues de pluie

Les averses sont soudaines : le vent devient humide, la pluie tombe comme un seau renversé, il fait
nuit en plein jour, et après la pluie le terrain est boueux (V2, « De ce côté-ci de l'écran » ;
« L'écoulement du temps depuis lors »). Pèlerines de toile cirée à capuche, bottes de cuir graissé
(rien de plastique ni de caoutchouc brillant). Willem met son pardessus (`willem_coat`, section 4.1).
Rangées : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `course` (5, 14) ; les petites ont en
plus `saut` (4, 12 : **à pieds joints dans une flaque**, original).

| Prio | Planche | Hauteur debout | Consigne propre |
| --- | --- | --- | --- |
| 2 | `almita/almita_rain` | 91 px | pèlerine jaune citron jusqu'aux chevilles, grosses bottes |
| 2 | `chtholly/chtholly_rain` | 144 px | pèlerine bleu marine à capuche relevée, quelques mèches bleues mouillées qui dépassent ; pas d'épée |
| 2 | `collon/collon_rain` | 115 px | pèlerine rouge, capuche rabattue en arrière exprès, cheveux trempés |
| 2 | `lakhesh/lakhesh_rain` | 115 px | pèlerine ocre jaune bien boutonnée, elle tient le bord de sa capuche à deux mains |
| 2 | `nygglatho/nygglatho_rain` | 178 px | châle de laine sur les épaules et grand parapluie de toile noire à manche de bois tenu au-dessus d'elle (rangées sans `course`, sans `saut`) |
| 2 | `pannibal/pannibal_rain` | 120 px | pèlerine violette, la brindille à la bouche, l'épée de bois sous la pèlerine (seule la poignée dépasse, du même côté que d'habitude) |
| 2 | `tiat/tiat_rain` | 106 px | pèlerine verte trop grande, capuche qui lui tombe sur les yeux |

Joindre les trois vues de la planche de base (et `willem_coat`, déjà livré, pour le ton de la pèlerine).


### 4.8 Entraînement au bâton (format à confirmer par le moteur, lot E8)

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
| 2 | `chtholly/chtholly_stick` | 144 px | Chtholly en tenue d'exercice : sa tenue de `_home` sans la veste, manches retroussées, cheveux attachés ; concentrée, rageuse quand elle rate (VEX, « Des émotions sans nom ») |
| 2 | `ithea/ithea_stick` | 139 px | Ithea, écharpe nouée serré, sourire ; elle s'allonge par terre après l'effort (son `mort`) |
| 2 | `nephren/nephren_stick` | 125 px | Nephren, couettes nouées en arrière, visage impassible même quand elle encaisse |
| 2 | `willem/willem_stick` | 168 px | Willem en tenue d'entraînement ample et terne (chemise de toile, pantalon serré aux chevilles), bâton sous le bras au `repos` ; il pare et contre « comme un serpent » sous des angles désagréables (VEX) ; son `mort` : assis, essoufflé, il se gratte la tête |

Scènes 9.2, 10.1 et 11.4. En attendant, le jeu garde la planche `chtholly` et un bâton dessiné
(`ACTE1.md`, section 6) : ces planches sont de **priorité 2** dans ce cahier.


### 4.9 Les reprises de planches livrées (priorité 3)

Mesurées sur les planches livrées (section 2.5). **Seules les images citées changent**, les autres restent
identiques au pixel près ; commence par `python3 tools/hd2d_sheets.py strip <out.png> <json>` pour voir la
ligne du sol. Pour chaque ligne : coller le bloc de style, puis « Corrige la planche `<fichier>` (format de la
section 4.0, JSON compris) : » et la consigne.

| Prio | Fichier (`assets/characters/…`) | Défaut | Consigne à coller |
| --- | --- | --- | --- |
| 3 | `chtholly/chtholly_front.png` | la pointe de Seniorious passe 16 px sous la ligne des pieds au `repos` et 10 px en `marche` | relève ou raccourcis la pointe de l'épée : elle touche la ligne du sol sans la dépasser, dans toutes les images debout ; le reste de la silhouette ne bouge pas |
| 3 | `pannibal/pannibal.png` (et `pannibal_life.png`, dont le `repos` est recopié) | la pointe de l'épée de bois passe 10 px sous les pieds dans la 1re image de `repos` | raccourcis la pointe pour qu'elle touche la ligne du sol ; recopie ensuite la rangée `repos` dans `pannibal_life` |
| 3 | `willem/willem_front.png` | la pointe de l'arme passe 4 à 7 px sous les pieds au `repos` | même correction |
| 3 | `limeskin/limeskin_back.png` | la queue passe 5 à 6 px sous les pieds au `repos` et au `parle` | relève la queue au ras du sol |
| 3 | `snack_vendor/snack_vendor_front.png` | la dernière image de `marche` (image 5) est dessinée plus grande que `repos` (remarque de `hd2d_sheets.py check`) | image 5 de `marche` à la hauteur de la 1re image de `repos` : 154 px |
| 3 | `tiat/tiat_front.png`, `tiat/tiat_back.png` | une image de `marche` (image 2 de la face, image 3 du dos) a l'ancre 10 à 12 px au-dessus des pieds | **pas de redessin** : `python3 tools/hd2d_sheets.py anchors <json> --write`, puis vérifier la planche de contrôle |


## 5. Lot R3 : le chemin du port

### 5.0 Rappel du format (à coller avec le lot)

Ce lot dessine le trajet de l'acte 1 : le sentier sans lumière et le marais de nuit, le village des
hommes-bêtes, son café, la maison Limashenka, le port. (La colline des étoiles n'a plus d'image à
commander ; les gens du village et du port sont au lot R4, section 6.1 ; les navires, au lot R7.)

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
- **tuile de sol** (`ground/`) : 384 × 384, vue de dessus, opaque, sans raccord sur les quatre bords ;
  **face de palier** (`cliff/`) : de face, opaque, sans raccord à gauche et à droite, le haut de l'image au
  niveau du palier supérieur, le bas au niveau du palier inférieur ;
- **premier plan suspendu** : accroché par le haut (le haut de l'image est le haut de l'écran), ancre libre ;
  **panneau sans raccord** : bords gauche et droit libres, il se pose en rangée ;
- **décalque de marais ou de mare** : bord irrégulier et effiloché qui se fond dans n'importe quel sol ;
  **bande animée de ce lot** : le pied de ce qui est posé reste immobile au pixel près.

Les fenêtres des **nouvelles façades** sont **éteintes** : vitres sombres bleutées avec un reflet clair ; le
jeu les allume la nuit avec les vitres éclairées du lot R6. Les enseignes sont des objets, jamais des mots.

**Références à joindre** : `assets/hd2d/buildings/cafe.png`, `limashenka_house.png`, `shop_bakery.png`,
`clockmaker.png`, `assets/hd2d/props/market_stall.png`, `tree_autumn.png`, `willow.png`,
`assets/hd2d/decals/lily_pads.png`, `assets/hd2d/ground/forest_floor.png`,
`assets/hd2d/props/mooring_arm.png`, `gangway.png`, `assets/hd2d/buildings/port_hangar.png`, et
`assets/hd2d/interior/props/china_cabinet.png` pour les intérieurs.

**Consigne** : colle le bloc de style, ce rappel, puis « Image `<chemin>`, <taille> px, <genre> : » et la
description de la ligne. Pour un bâtiment, commande la façade et son flanc dans la même conversation,
façade d'abord.

### 5.1 Le sentier sans lumière et le marais de nuit

Un sentier étroit qui s'enfonce dans une forêt noire, sans lampadaire ni aucune lumière (V1,
« L'Homme sans Marque ») ; un petit sentier forestier aux pierres clairsemées et mal entretenues,
envahies de mauvaises herbes, où l'on ne se perd pas tant qu'on le suit (V3, « Je suis à la
maison »).

Willem s'écarte du sentier et a les pieds dans l'eau ; il tombe à la renverse dans une grande gerbe
(V1, « L'Homme sans Marque ») ; plus tard, une épée projetée dans un marais en ressort couverte de
boue jusqu'à la garde (VEX, « L'endroit où je veux retourner »). Autour de l'entrepôt, des marécages
sombres de toutes formes (même source) ; dans la forêt, de l'eau qui s'accumule dans des creux
difficiles à voir (V5, épilogue).

Les scènes 1.2 à 1.4 s'y jouent (jour 1, nuit, l'embuscade de Pannibal) ; `alder` et `marsh_snag` sont
au lot R1 (section 3.5).

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/decals/bog_pool_a.png` | 288 × 192 (3 × 2 m) | décalque | mare de tourbe à l'eau noire (#4A675F assombri), bord de sphaignes rouges et vertes, quelques reflets d'étoiles en points clairs |
| 1 | `assets/hd2d/decals/path_stones_a.png` | 192 × 144 (2 × 1,5 m) | décalque | pierres plates clairsemées et mal posées, à demi enfoncées, herbe et mauvaises herbes dans les interstices (V3) |
| 1 | `assets/hd2d/ground/path_overgrown.png` | 384 × 384 | tuile de sol, **à confirmer par le moteur** (une 28e couche dans l'atlas du sol, lot E2) | sentier étroit de terre tassée envahi d'herbe : deux bandes de terre usée par les pas, herbe et mousse au milieu et sur les bords, racines, feuilles mortes |
| 1 | `assets/hd2d/props/fg_canopy_a.png` | 768 × 384 (8 × 4 m) | premier plan **suspendu** (accroché par le haut, ancre libre), **format à confirmer par le moteur** | masse de feuillage sombre qui pend du haut de l'image, vue d'en dessous : la voûte au-dessus du sentier, branches, feuilles d'automne presque noires, quelques trouées par où passent les étoiles (V1) |
| 1 | `assets/hd2d/props/marsh_hummock_a.png` | 115 × 77 (1,2 × 0,8 m) | panneau | touradon : grosse motte d'herbe dure et de carex qui sort de l'eau noire, le pied mouillé |
| 1 | `assets/hd2d/props/marsh_reed_wall.png` | 384 × 192 (4 × 2 m) | panneau, sans raccord à gauche et à droite | rideau dense de roseaux pâles (#9C9563) et de massettes brunes, quelques tiges cassées |
| 2 | `assets/hd2d/decals/path_stones_b.png` | 144 × 96 (1,5 × 1 m) | décalque | deux pierres plates seules, l'une fendue, mangées par l'herbe |
| 2 | `assets/hd2d/props/path_edge_ferns.png` | 384 × 106 (4 × 1,1 m) | panneau, sans raccord à gauche et à droite | bordure basse et serrée de fougères, d'herbes hautes et de ronces qui étrangle le sentier |
| 3 | `assets/hd2d/decals/bog_pool_b.png` | 192 × 144 (2 × 1,5 m) | décalque | mare plus petite, allongée, lentilles d'eau sur un bord |
| 3 | `assets/hd2d/props/fg_canopy_b.png` | 576 × 288 (6 × 3 m) | premier plan suspendu, **à confirmer** | même chose, plus clairsemé, une grosse branche en travers |
| 3 | `assets/hd2d/props/marsh_hummock_b.png` | 86 × 58 (0,9 × 0,6 m) | panneau | touradon plus petit, à moitié couché |
| 3 | `assets/hd2d/props/path_root_step.png` | 192 × 58 (2 × 0,6 m) | panneau | grosse racine moussue en travers du sentier, qui fait marche |
| 3 | `assets/hd2d/props/willow_pollard.png` | 288 × 384 (3 × 4 m) | panneau | saule têtard : tronc court noueux, tête hérissée de longs rameaux jaunes |


### 5.2 Les paliers et les talus (format à confirmer par le moteur, lot E2)

Le sol des nouvelles cartes monte par paliers de 0,5 m (`docs/REFONTE.md`, section 7.1) ; le lot
E2 habille leurs faces d'images. Faces vues de face, opaques, **sans raccord à gauche et à
droite**, le haut de l'image au niveau du palier supérieur, le bas au niveau du palier inférieur.

`bank_earth` est le **remplaçant** du talus de terre d'un mètre (cahier n° 1, prio 3, dessiné par le moteur) :
il fait double emploi avec `wall_earth_1m` ; à ne commander que si ce dernier n'est pas livré.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/cliff/step_earth.png` | 384 × 48 (4 × 0,5 m) | face de palier | talus de terre brune d'un demi-mètre, racines fines, cailloux, touffes d'herbe qui débordent du haut |
| 2 | `assets/hd2d/cliff/step_marsh.png` | 384 × 48 | face de palier | berge de tourbe noire et de racines au bord d'un marais, herbe qui retombe |
| 2 | `assets/hd2d/cliff/step_rock.png` | 384 × 48 | face de palier | petite marche de roche claire (#C2B49F) en strates, mousse dans les fissures |
| 2 | `assets/hd2d/cliff/wall_earth_1m.png` | 384 × 96 (4 × 1 m) | face de palier | talus de terre d'un mètre, grosses racines qui sortent, fougères accrochées |
| 3 | `assets/hd2d/cliff/bank_earth.png` | 384 × 96 (4 × 1 m) | face de palier, sans raccord à gauche et à droite | talus de terre vu de face, 1 m de haut, la face d'un petit palier : en haut l'herbe du pré qui déborde en touffes et ses racines qui pendent, puis une terre brune (#56402C) en strates molles, quelques cailloux et mottes ; en bas, les tons de la terre de potager ; **remplaçant du moteur en place** (cahier n° 1) : inutile si `wall_earth_1m` est livré |
| 3 | `assets/hd2d/cliff/step_drystone.png` | 384 × 48 | face de palier | muret de pierres sèches d'un demi-mètre (bord de champ, village) |
| 3 | `assets/hd2d/cliff/wall_rock_1m.png` | 384 × 96 | face de palier | ressaut de roche d'un mètre, lichen, une fissure avec une fougère |


### 5.3 Le village des hommes-bêtes

À quelques pas de l'entrepôt, entre la forêt et les marais, un village campagnard pas très grand,
mais pas assez petit pour que les fées y connaissent tout le monde ; presque personne n'y porte de
beaux habits (VEX, « Cinq cents ans »). On y bâtit en bois, en torchis et en chaume **(original,
dans l'esprit de l'œuvre)** ; le café à clochette (façade livrée `cafe.png`) et la maison
Limashenka (`limashenka_house.png`) en font partie.

**Façades et flancs** (format du lot K : façade, puis flanc dans la même conversation) :

| Prio | Nom (`assets/hd2d/buildings/<nom>.png`) | Façade (px) | Flanc `<nom>_side.png` (px) | Type, mur / faîte (m), profondeur | Matières | Consigne à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `cottage_thatch_a` | 480 × 528 | 480 × 240 | pignon, 2,5 / 5,5 ; prof. 5 | `wall_wattle_daub`, `roof_thatch` | chaumière de torchis ocre clair sur soubassement de pierres, colombages bruns irréguliers, toit de chaume épais et arrondi qui descend bas, porte basse de planches, une petite fenêtre éteinte, pots de fleurs au seuil |
| 2 | `cottage_thatch_b` | 672 × 240 | 480 × 480 | long, 2,5 / 5 ; prof. 5 | `wall_wattle_daub`, `roof_thatch` | longue chaumière basse : deux portes, trois petites fenêtres éteintes à volets, un banc de bois contre le mur, une corde à linge tendue d'un crochet à l'autre (sans linge), la bordure du chaume en haut de l'image |
| 2 | `cottage_thatch_c` | 384 × 480 | 384 × 216 | pignon, 2,25 / 5 ; prof. 4 | `wall_wattle_daub`, `roof_thatch` | petite chaumière penchée, torchis fissuré rapiécé, une lucarne dans le chaume, porte peinte en vert passé |
| 2 | `village_barn` | 768 × 336 | 576 × 672 | long, 3,5 / 7 ; prof. 6 | `wall_planks`, `roof_thatch` | grange de planches brunes délavées, grande porte à deux battants entrouverte sur la pénombre et le foin, petite porte à côté, fourche appuyée |
| 2 | `village_house_stone` | 480 × 576 | 480 × 288 | pignon, 3 / 6 ; prof. 5 | `wall_stone`, `roof_shingles` | maison de pierre un peu plus aisée, toit de bardeaux, porte à heurtoir, deux fenêtres à volets, une plus petite à l'étage dans le pignon, lierre au coin |
| 3 | `village_shed` | 384 × 216 | 288 × 336 | long, 2,25 / 3,5 ; prof. 3 | `wall_planks_b`, `roof_shingles` | appentis à bois de planches grises, bûches empilées sous l'avancée, une hache plantée dans un billot devant |

**Matières nouvelles** (`buildings/materials/`, 192 × 192, opaques, sans raccord) et panneaux du village :

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/buildings/materials/roof_thatch.png` | 192 × 192 | matière | chaume de paille dorée grisée par la pluie, en rangées de bottes parallèles au bas de l'image, mousse verte par plaques, quelques brins plus clairs |
| 2 | `assets/hd2d/buildings/materials/wall_wattle_daub.png` | 192 × 192 | matière | torchis ocre clair grumeleux, brins de paille visibles, petites fissures, sans colombages (ils sont dans les façades) |
| 2 | `assets/hd2d/props/fence_wattle.png` | 192 × 86 (2 × 0,9 m) | panneau, **sans raccord à gauche et à droite** | clôture de branches tressées entre des piquets, quelques brins cassés |
| 3 | `assets/hd2d/props/beehives.png` | 154 × 96 (1,6 × 1 m) | panneau | trois ruches de paille tressée sur une planche (le miel du marché, V3) |
| 3 | `assets/hd2d/props/cart_hay.png` | 288 × 192 (3 × 2 m) | panneau | charrette de bois à deux grandes roues chargée de foin, brancards posés au sol |
| 3 | `assets/hd2d/props/haystack.png` | 192 × 154 (2 × 1,6 m) | panneau | meule de foin ronde, une fourche plantée dedans |
| 3 | `assets/hd2d/props/washing_trough.png` | 288 × 96 (3 × 1 m) | panneau | lavoir : longue auge de pierre pleine d'eau, planche à laver, un panier de linge mouillé (original) |


### 5.4 Le café à clochette

Il fait tout, faute d'autre endroit où manger : café le jour, alcool le soir ; une sonnette tinte à
la porte ; une arrière-boutique ; l'après-midi, on y mange ou on y prend le thé ; une tablée
d'hommes-bêtes éméchés rit fort ; le serveur homme-chat offre des jus de fruits en cachette du
patron (VEX, « Cinq cents ans »). Dehors, la façade, le flanc et la clochette existent
(`cafe.png`, `cafe_side.png`, `anim/cafe_door_bell.png`).

Matières des intérieurs du village (sol, mur, comme au lot I) et mobilier : joindre `china_cabinet.png`,
`chair_wood.png` et `dining_table_long.png` pour le rendu du bois.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/floor_terracotta.png` | 384 × 384 | tuile de sol | carreaux carrés de terre cuite de 20 cm, rouge-brun et ocre mêlés, usés, quelques-uns fêlés |
| 1 | `assets/hd2d/interior/props/cafe_counter.png` | 288 × 115 (3 × 1,2 m) | meuble | comptoir de bois sombre ciré, usé au bord : une grande cafetière de cuivre sur un réchaud de cristal, des tasses retournées, un bocal de biscuits, un tonnelet à robinet de bois au bout |
| 1 | `assets/hd2d/interior/props/cafe_table_heavy.png` | 115 × 96 (1,2 × 1 m) | meuble | table carrée de bois épais, nappe à carreaux rouges et blancs, deux tasses ; avec les chaises `chair_wood` du lot I |
| 1 | `assets/hd2d/interior/props/juice_glasses.png` | 48 × 29 (0,5 × 0,3 m) | objet posé sur une table | trois verres de jus de fruits (orange, rouge, jaune) et une carafe (VEX : les jus offerts « pour la maison ») |
| 1 | `assets/hd2d/interior/wall_panel_dark.png` | 384 × 288 | mur | lambris de bois sombre jusqu'à 1,4 m, cimaise, enduit ocre au-dessus enfumé, plinthe (le café) |
| 2 | `assets/hd2d/interior/door_backroom.png` | 106 × 211 (1,1 × 2,2 m) | porte | passage vers l'arrière-boutique masqué d'un rideau de toile rayée, chambranle de bois (VEX) |
| 2 | `assets/hd2d/interior/props/cafe_bottle_shelf.png` | 192 × 192 (2 × 2 m) | meuble | étagères de bois derrière le comptoir : bouteilles d'alcool de toutes formes (le soir), pots de café, piles de tasses, chopes pendues |
| 2 | `assets/hd2d/interior/props/cafe_cake_case.png` | 96 × 58 (1 × 0,6 m) | objet posé sur le comptoir | vitrine à gâteaux sous cloche de verre : une tarte aux pommes, des petits gâteaux à la crème |
| 2 | `assets/hd2d/interior/props/cafe_drinkers_table.png` | 154 × 106 (1,6 × 1,1 m) | meuble | la table des buveurs : chopes renversées, cartes à jouer, un plat de saucisses entamé, flaques de bière (VEX : la tablée éméchée) |
| 2 | `assets/hd2d/interior/wallitem_menu_cafe.png` | 77 × 96 (0,8 × 1 m) | élément de mur, bas à 1,2 m | ardoise du menu : dessins à la craie d'une tasse fumante, d'une chope et d'une part de gâteau, traits de craie à la place des mots |
| 3 | `assets/hd2d/props/cafe_backyard_crates.png` | 154 × 96 (1,6 × 1 m) | panneau (dehors) | derrière le café, près de la porte de service : caisses de bouteilles vides, deux tonnelets, un balai |


### 5.5 La maison Limashenka

Une vieille maison du village dont la mère de Ramikeldi vient de mourir ; dans le salon, une vieille
horloge murale purement mécanique, sans cristal, pleine de ressorts, de vis et d'engrenages, dont
un peigne doré dans une caisse de résonance joue une comptine ; les pièces de rechange ont été
commandées ; Willem la répare jusqu'à deux heures (VEX, « L'homme-chat »). La façade aux volets
clos existe (`limashenka_house.png`).

Le salon n'ouvre que le jour 11 (scène 11.3) : Willem y répare l'horloge devant Ramikeldi et Chtholly, et
l'on s'assoit sur le canapé.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/interior/props/armchair_sheeted.png` | 96 × 101 (1 × 1,05 m) | meuble | fauteuil recouvert d'un drap blanc poussiéreux, maison fermée depuis le deuil (original) |
| 1 | `assets/hd2d/interior/props/sofa_salon.png` | 192 × 96 (2 × 1 m) | meuble | canapé à dossier sculpté, velours vert passé, napperons de dentelle |
| 1 | `assets/hd2d/interior/props/toolbox_gears.png` | 77 × 48 (0,8 × 0,5 m) | meuble | boîte à outils de bois ouverte posée par terre : pinces, tournevis, burette, et un sachet de papier d'où sortent des engrenages neufs (VEX : les pièces de rechange commandées) |
| 1 | `assets/hd2d/interior/wallitem_clock_limashenka.png` | 77 × 134 (0,8 × 1,4 m) | élément de mur, bas à 0,9 m | vieille horloge murale dans une grande caisse de bois sculpté de feuilles, cadran de laiton marqué de traits (aucun chiffre), aiguilles ouvragées, porte vitrée sur un balancier de laiton ; arrêtée |
| 1 | `assets/hd2d/interior/wallitem_clock_limashenka_open.png` | 77 × 134 | élément de mur, bas à 0,9 m | la même horloge, caisse ouverte : engrenages de laiton, ressorts, vis, et au fond un peigne doré posé dans une petite caisse de résonance (celui d'une boîte à musique) ; même cadrage au pixel près |
| 2 | `assets/hd2d/interior/props/display_cabinet.png` | 115 × 182 (1,2 × 1,9 m) | meuble | vitrine de bibelots : tasses de porcelaine, petits animaux de verre, une pipe, des boîtes à tabac (le fils est marchand de tabac, VEX) |
| 2 | `assets/hd2d/interior/wall_wallpaper_floral.png` | 384 × 288 | mur | papier peint à grandes fleurs fanées vert d'eau et rose sur fond crème, auréoles, plinthe et moulure (le salon des Limashenka) |
| 2 | `assets/hd2d/interior/window_shutters.png` | 115 × 154 (1,2 × 1,6 m) | fenêtre, appui à 0,8 m | fenêtre aux volets intérieurs de bois entrouverts, rais de lumière entre les lames (la maison qui se rouvre, cahier n° 1) |
| 3 | `assets/hd2d/anim/clock_limashenka_swing.png` | 77 × 134, 4 images, 2 ips | bande animée | l'horloge réparée : le balancier va et vient, le reste identique au pixel près |
| 3 | `assets/hd2d/decals/rug_salon.png` | 288 × 192 (3 × 2 m) | décalque à bord plein | tapis à médaillon central bordeaux et vert, usé, franges |
| 3 | `assets/hd2d/interior/props/side_table_salon.png` | 58 × 67 (0,6 × 0,7 m) | meuble | guéridon à napperon, une petite boîte à couture et un portrait encadré posé |
| 3 | `assets/hd2d/interior/wallitem_family_portrait.png` | 256 × 256 | portrait, fond transparent, buste de trois quarts vers la droite | portrait peint d'une famille d'hommes-chats, une mère et un petit garçon, dans un cadre doré terni ; aucun texte |


### 5.6 Le port et la rue du port

La rue du port, au bord du vide, où le vent souffle fort ; un panneau abîmé par les vents violents,
aux flèches rouges : le centre-ville à 2 000 marmer à droite, l'entrepôt à 500 marmer dans l'autre
direction (V1, « L'Homme sans Marque ») ; l'amarrage, un lourd bruit de métal, une passerelle, trois
bras d'ancrage qui se fixent de l'arrière vers l'avant (V1, « Entrepôt de fées ») ; une rampe, un
sifflet à vapeur, des charrettes chargées de sacs qui filent sur l'aire-port (V2, « Le chemin du
retour, toujours si loin ») ; une colline toujours ventée juste à côté (V3, « La Fille sans
visage ») ; une pluie fine au crépuscule (V1). Les panneaux du port des cahiers n° 1 et 2 restent
(quai de tôle, bras d'ancrage replié, pylône, passerelle, caisses de cristaux, tonneaux, cordages,
guichet, lampadaires).

Les scènes 1.1 (Willem et le panneau aux flèches rouges, de nuit) et 7.4 (le transport de la Garde sous la
pluie fine) s'y jouent. Les navires eux-mêmes sont au lot R7 ; les dockers et la Garde, au lot R4.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/mooring_arm_clamp.png` | 288 × 384, 4 images, 6 ips | bande animée | `mooring_arm_open.png` (jointe) : le bras s'abaisse et la pince se referme sur un anneau non dessiné ; image 3 : fermé ; le pied immobile au pixel près |
| 1 | `assets/hd2d/props/mooring_arm_open.png` | 288 × 384 (3 × 4 m) | panneau | bras d'ancrage de fer et de cuivre **déployé**, pince ouverte prête à saisir une coque, vérins, câbles, rivets ; complète `mooring_arm.png` (replié) |
| 1 | `assets/hd2d/props/signpost_port.png` | 154 × 288 (1,6 × 3 m) | panneau | le panneau du port d'après l'œuvre : poteau de bois fendu et penché par le vent, deux planches taillées en flèches et peintes d'un rouge écaillé, l'une vers la droite, l'autre vers la gauche ; sur celle de droite, de petites maisons de pierre peintes, sur celle de gauche un bâtiment de bois dans des arbres ; aucun texte, aucun chiffre ; usé, délavé, un clou qui tient mal (V1, « L'Homme sans Marque ») |
| 2 | `assets/hd2d/props/cargo_cart_a.png` | 288 × 173 (3 × 1,8 m) | panneau | charrette à bras à deux roues cerclées de fer, chargée de sacs de toile ficelés, brancards levés (V2) |
| 2 | `assets/hd2d/props/gangway_ramp.png` | 288 × 154 (3 × 1,6 m) | panneau | rampe d'embarquement inclinée de tôle striée, garde-corps de fer, vue de flanc, qui monte vers la droite (V2 : on monte par une passerelle et une rampe) |
| 2 | `assets/hd2d/props/steam_whistle.png` | 77 × 192 (0,8 × 2 m) | panneau | sifflet à vapeur de laiton terni au bout d'un tuyau de cuivre qui sort du quai, petite chaîne de manœuvre (V2) ; la vapeur est la bande `anim/furnace_steam.png` du cahier n° 2 |
| 3 | `assets/hd2d/props/capstan.png` | 96 × 86 (1 × 0,9 m) | panneau | cabestan de fer à barres de bois, un cordage enroulé |
| 3 | `assets/hd2d/props/cargo_cart_b.png` | 240 × 134 (2,5 × 1,4 m) | panneau | diable de bois et de fer chargé de trois caisses, une sangle |
| 3 | `assets/hd2d/props/wind_fence.png` | 192 × 134 (2 × 1,4 m) | panneau, sans raccord à gauche et à droite | palissade brise-vent de planches grises le long de la rue du port, deux planches cassées, un poteau penché |

Deux maisons de la rue du port (façade et flanc, format du lot K) :

| Prio | Nom (`assets/hd2d/buildings/<nom>.png`) | Façade (px) | Flanc `<nom>_side.png` (px) | Type, mur / faîte (m), profondeur | Matières | Consigne à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | `port_house_a` | 576 × 336 | 480 × 576 | long, 3,5 / 6 ; prof. 5 | `wall_stone`, `roof_slate_b` | maison basse de pierre au bord du vide, volets fermés par le vent, câbles d'ancrage scellés au mur, fenêtres éteintes |
| 3 | `port_house_b` | 384 × 624 | 480 × 384 | pignon, 4 / 6,5 ; prof. 5 | `wall_planks_b`, `roof_tin` | cabane du gardien du port en planches grises, girouette, longue-vue posée sur l'appui de la fenêtre |

Flancs des deux maisons (lot CP : remplaçants inscrits au manifeste, l'image livrée les remplace) : `port_house_a_side` et
`port_house_b_side` (480 × 384 px, mur gouttereau jusqu'à l'égout, dans le format ci-dessus).

### 5.7 Ce qui n'est pas dans ce lot

- **Le Barocupot, côté intérieur** : conseil de guerre, coursive et pont sont livrés (`docs/ASSETS_HD2D_NAVIRES.md`,
  50 images) ; le navire en volume est au lot R7.
- **La colline des étoiles** : toutes ses images sont livrées ; la lumière des talismans et le clair de lune
  sont au lot R6.
- **Les gens** du village, du café et du port : lot R4 (section 6.1), à commander **en même temps** que ce lot.


## 6. Lot R4 : les hommes-bêtes et la ville

### 6.0 Rappel du format (à coller avec le lot)

**Les planches** (sections 6.1 à 6.3) sont au format de l'easter egg, comme au lot R2 :

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

**Consigne** : colle le bloc de style, ce rappel, la fiche des animations (ci-dessous), puis « Planches de
sprites `assets/characters/<dossier>/<id>.png` (profil tourné vers la droite), `<id>_front.png` (de
face) et `<id>_back.png` (de dos), avec leurs JSON, fond transparent, mêmes animations et nombres
d'images dans les trois vues, une rangée par animation dans l'ordre du tableau, une seule
silhouette par case, hauteur debout **<n> px** dans toutes les images debout et les trois vues : »
puis le bloc de la planche (qui elle est, son tableau d'animations).

**La fiche des animations** :

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

**Les images de la ville** (sections 6.4 à 6.7) :

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

Les fenêtres des **nouvelles façades** sont **éteintes** : vitres sombres bleutées avec un reflet clair ; le
jeu les allume la nuit avec les vitres éclairées du lot R6. Les fenêtres font 0,8 × 1 m (petites) ou
1,4 × 1,4 m (grandes), ou un œil-de-bœuf de 0,6 m. Les enseignes sont des objets peints ou découpés
(pain, tasse, chapeau), jamais des mots.

**Références à joindre** : pour les planches d'hommes-bêtes, `assets/characters/cat_waiter/cat_waiter.png`,
`baker.png`, `snack_vendor.png` (rendu, palette et proportions) ; pour la ville,
`assets/hd2d/buildings/shop_bakery.png`, `clockmaker.png`, `shop_bookshop.png`, `butcher.png`,
`assets/hd2d/props/market_stall.png`, et pour les intérieurs `assets/hd2d/interior/props/china_cabinet.png`.

### 6.1 Les gens du village et du port (priorité 2, à commander avec le lot R3)

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

Ces six planches peuplent le café du village (scène 9.3), le port (scène 7.4 : le transport de la Garde) et
l'aire-port (`VIE.md`, 2.6 et 2.7). Le patron et les buveurs n'existent que dans le café du village (les
buveurs le soir).

| Prio | Planche | Hauteur debout | Qui | Apparence et consignes propres |
| --- | --- | --- | --- | --- |
| 2 | `cafe_owner/cafe_owner` | 187 px (1,95 m) | patron du café du village (VEX : le serveur offre les jus en cachette du patron) | homme-ours brun bedonnant, chemise aux manches retroussées, long tablier, torchon sur l'épaule ; `travaille` : il essuie une chope au torchon ; `porte` : un plateau de chopes |
| 2 | `drinker_cat/drinker_cat` | 158 px (1,65 m) | autre buveur | homme-chat roux balourd, casquette de travers, veste de velours râpée ; `assis` : il chante, une patte levée |
| 2 | `drinker_dog/drinker_dog` | 163 px (1,7 m) | buveur du café, le soir (VEX : une tablée éméchée rit fort) | homme-chien hirsute gris, chemise ouverte, gilet déboutonné, une chope de bois dans la même main dans toutes les images ; `parle` : rire bruyant, chope levée ; `assis` : affalé |
| 2 | `porter/porter` | 192 px (2 m) | docker de l'aire-port (V2 : les charrettes de sacs qui filent) | homme-lézard costaud gris-vert, chemise sans manches de toile épaisse, sangle, gants de cuir ; `porte` : un gros sac sur l'épaule ; `travaille` : il pousse une charrette non dessinée |

**Les visiteurs de la Garde** (rangées `repos` 2/2, `marche` 6/10, `parle` 2/6, `porte` 6/10 ; les lézards de
la Garde débarquent au port, V1, « Entrepôt de fées ») :

| Prio | Planche | Hauteur debout | Apparence et consignes propres |
| --- | --- | --- | --- |
| 2 | `garde_porter/garde_porter` | 202 px (2,1 m) | lézard de la Garde en tenue de bord (veste courte, gants) ; `porte` : deux grandes épées emmaillotées de tissu blanc sur l'épaule (V1 : les épées qu'on rapporte du combat) |
| 2 | `garde_soldier/garde_soldier` | 211 px (2,2 m) | soldat lézard de la Garde ailée, écailles gris-vert, uniforme bleu nuit à liserés rouges (#AE4A3E), aile stylisée brodée sur l'épaule (sans texte), ceinturon, sabre court au fourreau ; aucune arme à feu ; `porte` : une caisse ferrée |


### 6.2 Les métiers et les passants de la ville (priorité 3)

Même format qu'en 6.1. **Les familles** (hommes-chiens, chats, lézards, ours, oiseaux, grenouilles) se
commandent en deux temps (section 2.6) : une **planche d'ensemble** de l'espèce, à l'échelle, côte à côte, puis
chaque personnage à part, de formes vraiment différentes et de même rendu.

| Prio | Planche | Hauteur debout | Qui | Apparence et consignes propres |
| --- | --- | --- | --- | --- |
| 3 | `apothecary/apothecary` | 134 px (1,4 m) | apothicaire (déduction : Nygglatho va chercher des médicaments en ville, V3) | homme-grenouille trapu vert olive, petites lunettes rondes, blouse vert sombre ; `travaille` : il pile au mortier (mortier et pilon dessinés) |
| 3 | `bookseller/bookseller` | 144 px (1,5 m) | libraire (V2 ; V3) | vieille femme-chatte tigrée, lunettes au bout du museau, châle, cardigan ; `travaille` : elle range des livres sur une étagère haute ; `porte` : une pile de livres ficelés (les commandes de l'entrepôt) |
| 3 | `butcher/butcher` | 173 px (1,8 m) | boucher de la ville (V2) | homme-chien massif à tête de dogue, tablier de cuir, avant-bras épais ; `travaille` : il tranche au couperet sur un billot non dessiné (viande déjà parée, aucune bête entière, aucun sang) ; `porte` : un jambon emballé de papier sur l'épaule |
| 3 | `cafe_town_waiter/cafe_town_waiter` | 163 px (1,7 m) | serveur du café habituel de la ville, terrifié par une troll et un lézard géant (V3, « Le grand et jeune lézard ») | jeune demi-bête : visage presque humain, oreilles et queue de chien beige, mince, gilet noir, long tablier ; `travaille` : il pose une tasse d'une main tremblante ; `porte` : un plateau |
| 3 | `market_farmer/market_farmer` | 154 px (1,6 m) | marchande du marché du matin (V3 : farine, beurre, œufs, lait) | femme-chienne à longues oreilles d'épagneul, fichu, tablier, sabots ; `travaille` : elle pèse des œufs dans une petite balance tenue à la main ; `porte` : un cageot de légumes |
| 3 | `market_honey/market_honey` | 163 px (1,7 m) | marchand de miel et de noix (V3) | homme-lézard trapu aux écailles vert-brun, gilet de cuir, chapeau de paille ; `porte` : une caisse de pots de miel |
| 3 | `milliner/milliner` | 154 px (1,6 m) | marchande d'accessoires (V2) | femme-oiseau au plumage gris-bleu et à petite crête, robe simple et soignée, un chapeau à plume ; `travaille` : elle noue un ruban sur un chapeau tenu dans ses mains |
| 3 | `projectionist/projectionist` | 168 px (1,75 m) | projectionniste de la salle de projection (V2) | homme-lézard maigre aux écailles brun-vert, visière de toile, gilet à manchettes ; `travaille` : il tourne la manivelle d'un appareil non dessiné |
| 3 | `villager_bear_f/villager_bear_f` | 182 px (1,9 m) | passante | femme-ourse, tablier, manches retroussées, foulard |
| 3 | `villager_bear_m/villager_bear_m` | 192 px (2 m) | passant | homme-ours bûcheron, chemise à carreaux, hache au manche posée sur l'épaule (même côté partout) |
| 3 | `villager_bird_f/villager_bird_f` | 149 px (1,55 m) | passante | femme-oiseau à tête de pie, robe noire et blanche, petit chapeau |
| 3 | `villager_bird_m/villager_bird_m` | 154 px (1,6 m) | passant | homme-oiseau à tête de corneille, veste sombre, sacoche de cuir en bandoulière (le facteur, original) |
| 3 | `villager_cat_f/villager_cat_f` | 149 px (1,55 m) | passante | femme-chatte tricolore, robe à fleurs passées, tablier |
| 3 | `villager_cat_m/villager_cat_m` | 158 px (1,65 m) | passant | homme-chat noir aux yeux jaunes, veste de velours râpée, casquette |
| 3 | `villager_dog_f/villager_dog_f` | 154 px (1,6 m) | passante | femme-chienne au pelage roux, robe de travail, châle, panier au bras (dessiné, même côté partout) |
| 3 | `villager_dog_m/villager_dog_m` | 168 px (1,75 m) | passant | homme-chien fermier brun et blanc, chemise de lin, gilet, pantalon à bretelles, bâton de marche |
| 3 | `villager_frog_f/villager_frog_f` | 130 px (1,35 m) | passante | femme-grenouille, robe verte, panier de cresson |
| 3 | `villager_frog_m/villager_frog_m` | 134 px (1,4 m) | passant | homme-grenouille pêcheur des marais, ciré olive, nasse d'osier au dos |
| 3 | `villager_lizard_f/villager_lizard_f` | 173 px (1,8 m) | passante | femme-lézard aux écailles vert pâle, robe longue, foulard noué sur la tête |
| 3 | `villager_lizard_m/villager_lizard_m` | 182 px (1,9 m) | passant | homme-lézard aux écailles ocre, blouse de charretier, chapeau de feutre |
| 3 | `watchmaker/watchmaker` | 149 px (1,55 m) | horloger (V2) | vieil homme-oiseau à tête de chouette, plumes grises, lorgnon et loupe vissée à l'œil, gilet brun ; `travaille` : il règle un petit mécanisme à la pince, penché |


### 6.3 Les visiteurs de passage (priorité 3)

Les gens élégants viennent toujours d'ailleurs, le plus souvent des marchands de grandes compagnies
(VEX, « Cinq cents ans ») ; les lézards de la Garde ailée débarquent au port (V1, « Entrepôt de
fées »). Rangées : `repos` (2, 2), `marche` (6, 10), `parle` (2, 6), `assis` (2, 2) pour les
marchands ; `repos`, `marche`, `parle`, `porte` (6, 10) pour la Garde.

| Prio | Planche | Hauteur debout | Apparence et consignes propres |
| --- | --- | --- | --- |
| 3 | `merchant_cat/merchant_cat` | 163 px (1,7 m) | marchand homme-chat au pelage gris argenté lustré, costume trois pièces bleu sombre, chapeau melon, canne à pommeau (même côté partout), sacoche de cuir ; poli et pressé |
| 3 | `merchant_lizard/merchant_lizard` | 178 px (1,85 m) | marchand reptilien aux écailles bleu-vert, redingote bordeaux, gilet brodé, lorgnon, registre sous le bras |


### 6.4 Le centre-ville en pente

À 2 000 marmer du port, des centaines de bâtiments de pierre alignés sur une légère pente, dans une
atmosphère idyllique (V1, « Directeur en carton ») ; on y descend de l'entrepôt par un sentier
(V5, « La fin imminente ») ; un vent froid y souffle (V2, « De ce côté-ci de l'écran »). Deux ou
trois cartes : une rue en pente coupée d'escaliers, une place du marché, des ruelles. Le jeu monte
le sol par paliers de 0,5 m : chaque façade de ville a en bas un **socle de pierre nue de 0,5 m**,
compris dans la hauteur du mur, pour s'asseoir sur deux paliers (**format à confirmer par le
moteur**, lot E2). Les façades livrées des cahiers n° 1 et 2 (boulangerie, librairie, horloger,
boucherie, salle de projection, maisons à colombages, maison étroite) restent ; celles-ci les
complètent.

`CARTE.md` (section 9) ne pose que `town_house_a` à `town_house_f` ; **`town_house_g` et `town_house_h` sont à
commander en dernier**.

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

### 6.5 Les boutiques

Les commerces de l'œuvre : le snack-bar du jeune lycanthrope (V1, « Directeur en carton ») ; la
librairie, l'horloger, la salle de projection, le magasin d'accessoires, un café, le boucher (V2,
« Temps écoulé depuis lors ») ; la boulangerie au patron grincheux où travaille Lakhesh et le marché
du matin (V3, « Je suis à la maison ») ; le café habituel, avec la librairie au coin de la rue (V3,
« Le grand et jeune lézard » ; V5) ; un apothicaire **(déduction)**. Façades déjà livrées :
`shop_bakery`, `shop_bookshop`, `clockmaker`, `butcher`, `projection_hall`. Nouvelles :

| Prio | Nom (`assets/hd2d/buildings/<nom>.png`) | Façade (px) | Flanc `<nom>_side.png` (px) | Type, mur / faîte (m), profondeur | Matières | Consigne à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | `cafe_town` | 672 × 384 | 576 × 576 | long, 4 / 6 ; prof. 6 | `wall_stone_town`, `roof_slate_b` | le café habituel de la ville, au coin d'une rue : grandes fenêtres, porte vitrée, deux tables rondes dehors, enseigne en forme de tasse (V3 ; V5) |
| 2 | `shop_snack` | 480 × 336 | 480 × 576 | long, 3,5 / 6 ; prof. 5 | `wall_stone_town`, `roof_tiles` | snack-bar : petite boutique de pierre au comptoir ouvert sur la rue sous un auvent de toile, plaque de cuisson derrière, trois tabourets hauts devant, enseigne en forme de poêle (V1) |
| 3 | `shop_accessories` | 384 × 624 | 480 × 384 | pignon, 4 / 6,5 ; prof. 5 | `wall_plaster`, `roof_tiles` | magasin d'accessoires : vitrine de chapeaux sur des têtes de bois, rubans et broches, auvent vert, enseigne en forme de chapeau |
| 3 | `shop_apothecary` | 384 × 624 | 480 × 384 | pignon, 4 / 6,5 ; prof. 5 | `wall_stone_town`, `roof_slate` | apothicaire : vitrine de bocaux de verre colorés, porte vitrée, enseigne en forme de mortier et de pilon |

**Enseignes et étals du marché** (panneaux) :

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/props/hanging_sign_pan.png` | 96 × 115 | panneau | enseigne en forme de poêle à frire |
| 3 | `assets/hd2d/props/hanging_sign_cup.png` | 96 × 115 (1 × 1,2 m) | panneau (potence au mur, ancre au bas de la potence) | enseigne de fer pendue à une potence, découpée en tasse fumante |
| 3 | `assets/hd2d/props/hanging_sign_hat.png` | 96 × 115 | panneau | enseigne en forme de chapeau à ruban |
| 3 | `assets/hd2d/props/hanging_sign_mortar.png` | 96 × 115 | panneau | enseigne en forme de mortier et de pilon |
| 3 | `assets/hd2d/props/market_stall_dairy.png` | 240 × 230 (2,5 × 2,4 m) | panneau | étal du marché du matin sous bâche crème : mottes de beurre, bidons de lait, fromages, paniers d'œufs (V3) |
| 3 | `assets/hd2d/props/market_stall_flour.png` | 240 × 230 | panneau | étal sous bâche grise : sacs de farine et de sucre, une balance à plateaux, une pelle (V3) |
| 3 | `assets/hd2d/props/market_stall_honey.png` | 240 × 230 | panneau | étal sous bâche ocre : pots de miel, sacs de noix et de fruits secs ouverts (V3) |

### 6.6 Le décor de la pente : toits, escaliers, murs

Joindre les maisons déjà livrées (`house_stone_b.png`, `house_narrow.png`).

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/cliff/town_retaining_wall.png` | 384 × 96 (4 × 1 m) | mur sans raccord à gauche et à droite, opaque, **format à confirmer par le moteur** (E2 : faces des paliers) | mur de soutènement de pierre appareillée entre deux paliers de la rue, barbacanes, traînées d'humidité, lierre qui retombe du haut |
| 3 | `assets/hd2d/props/town_arch.png` | 288 × 336 (3 × 3,5 m) | panneau | passage voûté de pierre entre deux maisons, l'ombre du passage, une lanterne de fer au sommet de l'arc |
| 3 | `assets/hd2d/props/town_cellar_hatch.png` | 115 × 58 (1,2 × 0,6 m) | panneau | trappe de cave de bois inclinée contre un mur, pentures de fer |
| 3 | `assets/hd2d/props/town_doorsteps.png` | 115 × 48 (1,2 × 0,5 m) | panneau | trois marches de pierre devant une porte, un paillasson |
| 3 | `assets/hd2d/props/town_planter_stone.png` | 154 × 77 (1,6 × 0,8 m) | panneau | bac de pierre fleuri d'asters et de bruyère |
| 3 | `assets/hd2d/props/town_railing.png` | 192 × 96 (2 × 1 m) | panneau, sans raccord à gauche et à droite | garde-corps de fer forgé d'une terrasse, volutes simples, rouille |
| 3 | `assets/hd2d/props/town_roofs_a.png` | 1536 × 768 (16 × 8 m) | lisière, raccord à gauche et à droite | la ville qui descend au-delà du bord de la carte, vue de haut et de loin : rangées serrées de toits d'ardoise et de tuiles en écailles, cheminées qui fument, lucarnes, un clocher de pierre, quelques arbres dorés entre les toits ; pour fermer l'horizon des rues |
| 3 | `assets/hd2d/props/town_roofs_b.png` | 1536 × 768 | lisière, raccord | même chose, toits plus bas et plus épars, jardins et murets entre eux, le bord de la ville qui rejoint la forêt |
| 3 | `assets/hd2d/props/town_stairs_a.png` | 192 × 192 (2 × 2 m) | panneau, **format à confirmer par le moteur** (E2) | volée de six marches de pierre de 2 m de large qui monte d'1 m vers le fond (le nord) entre deux murets, marches usées au milieu, herbe dans les joints |
| 3 | `assets/hd2d/props/town_stairs_b.png` | 384 × 192 (4 × 2 m) | panneau, **à confirmer** (E2) | grand escalier de place, plus large, rampe de fer au milieu |
| 3 | `assets/hd2d/props/town_wall_fountain.png` | 115 × 154 (1,2 × 1,6 m) | panneau | fontaine murale : bec de cuivre vert-de-grisé, auge de pierre, une tasse de fer à une chaînette |
| 3 | `assets/hd2d/props/town_wall_low.png` | 192 × 77 (2 × 0,8 m) | panneau, sans raccord à gauche et à droite | muret de pierre sèche à couronnement de dalles, mousse |
| 3 | `assets/hd2d/sky/town_roofs_far.png` | 2048 × 384 (à 48 px/m) | lointain, raccord à gauche et à droite | silhouette lointaine de la ville sur sa pente, toits et cheminées adoucis et violacés par la distance |

### 6.7 Les intérieurs des boutiques

Chaque boutique est une petite pièce encombrée ; joindre une façade livrée de la même boutique quand elle existe (`shop_bakery`, `shop_bookshop`, `clockmaker`, `butcher`, `projection_hall`).

Matières de la ville (sol, mur), puis mobilier et objets :

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/buildings/materials/wall_stone_town.png` | 192 × 192 | matière | pierre de taille gris-beige appareillée en assises régulières, joints fins, quelques blocs plus clairs ou ébréchés (la ville) |
| 3 | `assets/hd2d/interior/floor_stone_town.png` | 384 × 384 | tuile de sol | dalles de pierre claire polies par les pas, joints fins, une dalle fendue (boutiques de la ville) |
| 3 | `assets/hd2d/interior/wall_plaster_ochre.png` | 384 × 288 | mur | enduit ocre clair, propre mais vieilli, plinthe de bois peint (boutiques) |
| 3 | `assets/hd2d/interior/wall_stone_inside.png` | 384 × 288 | mur | pierre apparente jointoyée, moellons beiges, une poutre en haut (boulangerie, boucherie) |

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/props/bakery_counter.png` | 192 × 106 (2 × 1,1 m) | meuble | comptoir de boulangerie : balance, panier de petits pains, papier d'emballage (V3 : Lakhesh y sert le matin) |
| 2 | `assets/hd2d/interior/props/bakery_oven.png` | 192 × 192 (2 × 2 m) | meuble | four à pain de briques, gueule voûtée fermée d'une porte de fonte entrouverte, braises au fond, pelle à enfourner appuyée |
| 2 | `assets/hd2d/interior/props/bread_shelves.png` | 192 × 211 (2 × 2,2 m) | meuble | étagères de pains : miches rondes, pains longs, brioches, petits pains en paniers |
| 2 | `assets/hd2d/interior/props/cafe_town_counter.png` | 288 × 115 (3 × 1,2 m) | meuble | comptoir du café habituel : grosse cafetière de cuivre, tasses, sandwichs au bacon sous cloche (V3 : on n'y sert pas de thé) |
| 2 | `assets/hd2d/interior/props/cafe_town_table.png` | 134 × 96 (1,4 × 1 m) | meuble | lourde table de bois et deux petites chaises trop petites pour un lézard géant (V3 ; V5) |
| 2 | `assets/hd2d/interior/props/kneading_trough.png` | 154 × 96 (1,6 × 1 m) | meuble | pétrin de bois plein de pâte, farine partout, un rouleau |
| 2 | `assets/hd2d/interior/props/snack_counter.png` | 288 × 115 (3 × 1,2 m) | meuble | comptoir du snack-bar : plaque de cuisson de fonte sur un réchaud de cristal, une poêle où grésille du lard, une bassine de friture, des pommes de terre, un pot de soupe (V1 : le lycanthrope fait sauter sa poêle) |
| 2 | `assets/hd2d/interior/props/snack_meal_tray.png` | 48 × 24 (0,5 × 0,25 m) | objet posé sur une table | plateau : pommes de terre frites, légumes, lard frit épais, petit pain, soupe dans une tasse (V1) |
| 2 | `assets/hd2d/interior/props/snack_stools.png` | 154 × 77 (1,6 × 0,8 m) | meuble | rangée de trois tabourets hauts de bois devant le comptoir |
| 3 | `assets/hd2d/anim/oven_glow.png` | 96 × 58 (1 × 0,6 m), 4 images, 6 ips | bande animée | lueur des braises dans la gueule du four, qui pulse doucement (sans le four) |
| 3 | `assets/hd2d/anim/projection_flicker.png` | 288 × 192 (3 × 2 m), 4 images, 8 ips | bande animée, **alpha doux** | le film muet projeté sur la toile : un rectangle de lumière grise qui tremble, deux silhouettes floues de lézards sur un pont voûté entre des lampes (V2 : une romance de lézards) ; sans écran ni cadre |
| 3 | `assets/hd2d/interior/props/accessories_counter.png` | 154 × 173 (1,6 × 1,8 m) | meuble | comptoir surmonté d'un grand miroir ovale à cadre doré (verre gris bleuté uni) |
| 3 | `assets/hd2d/interior/props/apothecary_counter.png` | 192 × 106 (2 × 1,1 m) | meuble | comptoir d'apothicaire : balance de précision, mortier, fioles, papier plié |
| 3 | `assets/hd2d/interior/props/apothecary_shelves.png` | 192 × 230 (2 × 2,4 m) | meuble | étagères de bocaux de faïence à étiquettes vierges et de fioles colorées |
| 3 | `assets/hd2d/interior/props/bookshop_counter.png` | 154 × 106 (1,6 × 1,1 m) | meuble | comptoir : piles de commandes ficelées (celles de l'entrepôt, V3), une loupe, une sonnette de comptoir |
| 3 | `assets/hd2d/interior/props/bookshop_shelves.png` | 192 × 230 (2 × 2,4 m) | meuble | rayonnages de librairie du sol au plafond, échelle roulante accrochée à une tringle |
| 3 | `assets/hd2d/interior/props/bookshop_table.png` | 154 × 86 (1,6 × 0,9 m) | meuble | table de nouveautés : livres d'images et romans en piles, couvertures colorées sans titres |
| 3 | `assets/hd2d/interior/props/butcher_block.png` | 96 × 96 (1 × 1 m) | meuble | billot de bois sur pieds, couperet planté, torchon ; aucun sang |
| 3 | `assets/hd2d/interior/props/butcher_counter.png` | 192 × 106 (2 × 1,1 m) | meuble | comptoir à dessus de marbre, balance, papier d'emballage, couteaux rangés |
| 3 | `assets/hd2d/interior/props/cinema_benches.png` | 288 × 86 (3 × 0,9 m) | meuble | rangée de bancs de bois vus de dos (dossiers vers la caméra), pour la salle de projection |
| 3 | `assets/hd2d/interior/props/cinema_screen.png` | 384 × 288 (4 × 3 m) | meuble | toile blanche tendue sur un cadre de bois, rideaux de velours rouge passé de part et d'autre, estrade basse (V2) |
| 3 | `assets/hd2d/interior/props/crystal_projector.png` | 77 × 154 (0,8 × 1,6 m) | meuble | appareil de projection : boîte de laiton à lentille sur un trépied de bois, un cristal enregistreur dans son logement, une manivelle (V2) |
| 3 | `assets/hd2d/interior/props/hat_stands.png` | 154 × 154 (1,6 × 1,6 m) | meuble | présentoir de chapeaux sur des têtes de bois, dont un grand chapeau bleu foncé |
| 3 | `assets/hd2d/interior/props/herb_drawers.png` | 154 × 173 (1,6 × 1,8 m) | meuble | meuble d'herboriste à dizaines de petits tiroirs à boutons de laiton, étiquettes vierges |
| 3 | `assets/hd2d/interior/props/longcase_clock.png` | 58 × 211 (0,6 × 2,2 m) | meuble | horloge de parquet en bois sombre, cadran de laiton sans chiffres, balancier visible |
| 3 | `assets/hd2d/interior/props/ribbon_display.png` | 115 × 134 (1,2 × 1,4 m) | meuble | vitrine de rubans en bobines, broches, peignes, gants |
| 3 | `assets/hd2d/interior/props/snack_shelf.png` | 154 × 154 (1,6 × 1,6 m) | meuble | étagère de pots, de sacs de pommes de terre et de bouteilles d'huile |
| 3 | `assets/hd2d/interior/props/watch_workbench.png` | 154 × 106 (1,6 × 1,1 m) | meuble | établi d'horloger : loupe sur bras, engrenages, ressorts, pinces fines, une horloge démontée |
| 3 | `assets/hd2d/interior/wallitem_clocks.png` | 192 × 115 (2 × 1,2 m) | élément de mur, bas à 1,2 m | mur d'horloges de formes variées (rondes, carrées, à coucou de bois), cadrans sans chiffres, aiguilles à des heures différentes |
| 3 | `assets/hd2d/interior/wallitem_dried_herbs.png` | 154 × 77 (1,6 × 0,8 m) | élément de mur, bas à 1,6 m | bouquets d'herbes séchées pendus tête en bas à une perche |
| 3 | `assets/hd2d/interior/wallitem_meat_hooks.png` | 192 × 106 (2 × 1,1 m) | élément de mur, bas à 1,2 m | barre à crochets : jambons, saucisses, flèches de lard, paquets emballés ; aucune bête entière, aucun sang |
| 3 | `assets/hd2d/interior/wallitem_menu_town.png` | 96 × 115 (1 × 1,2 m) | élément de mur, bas à 1,1 m | carte affichée dans un cadre : lignes peintes illisibles, dessins d'une tasse et d'un sandwich (V3) |

## 7. Lot R5 : la nature et la faune

### 7.0 Rappel du format (à coller avec le lot)

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
- **planche d'animal** : le format des personnages (lot R2, section 4.0), trois vues, tourné vers
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


**Les planches d'animaux** (section 7.3) suivent le format des personnages :

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

**Consigne** : colle le bloc de style, ce rappel, la fiche des animations (ci-dessous), puis « Planches de
sprites `assets/characters/<dossier>/<id>.png` (profil tourné vers la droite), `<id>_front.png` (de
face) et `<id>_back.png` (de dos), avec leurs JSON, fond transparent, mêmes animations et nombres
d'images dans les trois vues, une rangée par animation dans l'ordre du tableau, une seule
silhouette par case, hauteur debout **<n> px** dans toutes les images debout et les trois vues : »
puis le bloc de la planche (qui elle est, son tableau d'animations).

**Consigne** : colle le bloc de style, ce rappel, puis « Image `<chemin>`, <taille> px, <genre> : » et la
description de la ligne. Les fourrés, la haie, l'aulne et la souche noyée sont au lot R1 (section 3.5) ; le
sentier et le marais, au lot R3.

### 7.1 La forêt profonde

Bosquets profonds, fourrés aux branches qui percent la peau (V1, « Entrepôt de fées ») ; de l'eau cachée
dans des creux, dangereuse pour les enfants (V5, épilogue) ; Chtholly s'enfuit dans la forêt quand c'est
trop (VEX, « Des émotions sans nom ») : son refuge est **(original)**. La scène 10.2 s'y joue.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/decals/hidden_pool_a.png` | 192 × 144 (2 × 1,5 m) | décalque | petite mare dans un creux, presque couverte de feuilles mortes flottantes : on devine à peine l'eau noire entre les feuilles, bord de mousse (V5 : le danger qu'on ne voit pas) |
| 2 | `assets/hd2d/props/forest_wall_deep.png` | 1536 × 1056 (16 × 11 m) | lisière, raccord à gauche et à droite | forêt profonde et sombre : vieux chênes moussus et sapins à trois profondeurs, troncs couverts de lierre, très peu de lumière, sous-bois de fougères noires |
| 2 | `assets/hd2d/props/grove_dense.png` | 768 × 864 (8 × 9 m) | panneau | bosquet profond : trois arbres serrés (chêne, hêtre, sapin), taillis, lierre, ombre dense au pied ; on n'y voit que la pénombre |
| 3 | `assets/hd2d/decals/hidden_pool_b.png` | 144 × 115 (1,5 × 1,2 m) | décalque | même chose, plus petite, une branche tombée en travers |
| 3 | `assets/hd2d/props/fallen_pine.png` | 576 × 154 (6 × 1,6 m) | panneau | sapin abattu par le vent, couché en travers vers la droite, motte de racines à gauche, aiguilles rousses |
| 3 | `assets/hd2d/props/pool_ferns.png` | 192 × 115 (2 × 1,2 m) | panneau | fougères penchées au-dessus d'une mare, leurs frondes qui touchent l'eau (le bas de l'image est le bord de l'eau) |
| 3 | `assets/hd2d/props/refuge_oak.png` | 768 × 960 (8 × 10 m) | panneau | le refuge de Chtholly **(original)** : un énorme vieux chêne creux, racines comme des bras, un creux à sa base où une fée peut s'asseoir à l'abri, feuillage or et rouille |
| 3 | `assets/hd2d/props/rowan.png` | 288 × 480 (3 × 5 m) | panneau | sorbier aux grappes de baies rouge vif et au feuillage orangé, tronc gris fin |


### 7.2 La montagne et la rivière

Une montagne où vivent les ours, qui hibernent l'hiver (V2, V5) ; Nygglatho y chasse quand elle a du chagrin ;
une rivière où l'on puise l'eau du bain (V3). Les premières neiges seulement sur les sommets (fin
d'automne).

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/anim/river_rapids.png` | 192 × 96 (2 × 1 m), 4 images, 8 ips | bande animée | remous blancs et écume autour d'un rocher à fleur d'eau, le rocher immobile |
| 3 | `assets/hd2d/anim/small_waterfall.png` | 192 × 288 (2 × 3 m), 6 images, 10 ips | bande animée, **alpha doux** sur les bords | petite cascade de torrent sur des rochers moussus, eau claire et écume ; le haut de l'image est la lèvre de pierre |
| 3 | `assets/hd2d/cliff/cliff_mountain.png` | 384 × 384 | tuile, sans raccord sur les quatre bords | paroi de falaise de montagne, comme `cliff.png` mais grise et sombre, strates verticales, lichens, une touffe d'herbe |
| 3 | `assets/hd2d/decals/animal_tracks.png` | 144 × 192 (1,5 × 2 m) | décalque | empreintes de cerf et de sanglier mêlées dans la boue, qui traversent l'image de bas en haut |
| 3 | `assets/hd2d/decals/scree.png` | 288 × 192 (3 × 2 m) | décalque | éboulis de pierres grises anguleuses de 5 à 30 cm |
| 3 | `assets/hd2d/ground/river_water.png` | 384 × 384 | tuile de sol, **à confirmer par le moteur** (lot E2) | eau de rivière courante, plus profonde que `stream_bed.png` : vert sombre et bleu-gris, reflets clairs en traits allongés dans le sens horizontal (le courant), quelques galets devinés au fond |
| 3 | `assets/hd2d/props/bear_den.png` | 384 × 288 (4 × 3 m) | panneau | tanière d'ours : entrée sombre sous un surplomb de rocher et de racines, feuilles tassées au seuil ; aucun os, aucun sang (les ours y hibernent, V2) |
| 3 | `assets/hd2d/props/boulder_mountain_a.png` | 384 × 288 (4 × 3 m) | panneau | gros rocher gris anguleux, lichens jaunes et gris, une fissure |
| 3 | `assets/hd2d/props/boulder_mountain_b.png` | 240 × 192 (2,5 × 2 m) | panneau | rocher plus petit, posé de travers sur des éboulis |
| 3 | `assets/hd2d/props/log_bridge_b.png` | 384 × 96 (4 × 1 m) | panneau | tronc équarri jeté en passerelle au-dessus d'un torrent, une main courante de corde |
| 3 | `assets/hd2d/props/mountain_pine_a.png` | 240 × 576 (2,5 × 6 m) | panneau | sapin de montagne tordu par le vent, branches d'un seul côté, écorce grise |
| 3 | `assets/hd2d/props/mountain_pine_b.png` | 192 × 432 (2 × 4,5 m) | panneau | petit sapin rabougri sur un rocher, racines à nu |
| 3 | `assets/hd2d/props/river_bank.png` | 384 × 96 (4 × 1 m) | panneau, sans raccord à gauche et à droite | berge de galets ronds et de racines vue de face, le bas de l'image au ras de l'eau (V3 : on puise l'eau du bain à la rivière) |
| 3 | `assets/hd2d/props/rock_overhang.png` | 480 × 336 (5 × 3,5 m) | panneau | surplomb rocheux moussu sous lequel on peut s'abriter, fougères au pied |
| 3 | `assets/hd2d/sky/mountain_backdrop_a.png` | 2048 × 512 (42 × 10 m à 48 px/m) | lointain, raccord à gauche et à droite | la montagne de l'île en arrière-plan : pentes couvertes de sapins sombres, crêtes de roche claire, premières neiges sur les sommets, adoucie et violacée par la distance (V2 ; V5) |
| 3 | `assets/hd2d/sky/mountain_backdrop_b.png` | 2048 × 512 | lointain, raccord | même chaîne sous un autre angle : une gorge, une cascade lointaine en fil blanc |


### 7.3 Les animaux

Ce que dit l'œuvre : des **ours** dans les montagnes, chassés par Nygglatho et qui hibernent l'hiver
(V2 ; V5 ; VEX) ; des **oiseaux** bruyants au matin (V3) ; un petit animal grimpeur poursuivi par
une fillette (V5, épilogue) ; des **papillons orange** (ill. VEX) ; des **loups**, seulement une
crainte de Willem (V1). Ce qu'on ajoute (original) : loups de la forêt profonde, sangliers, cerfs,
renards, écureuils, grenouilles, corbeaux, une chouette, des libellules (`docs/REFONTE.md`,
section 4.4). On ne les croise ni à l'entrepôt, ni au village, ni en ville. **Jamais de sang** : une
bête vaincue s'enfuit ou reste couchée, sans blessure visible.

**Planches** (`assets/fauna/<id>/<id>.png` + `.json`, `_front`, `_back`) : format des personnages
(rappel du lot R2, section 4.0), trois vues, profil tourné vers la droite, mêmes animations dans les trois vues. La
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

Aucune planche d'animal n'est encore livrée : joindre `assets/characters/tiat/tiat.png` pour le contour et
l'ombrage, et demander d'abord une planche d'ensemble des animaux du lot, côte à côte à l'échelle (section
2.6, point 9), puis chaque planche à part. Les trois vues, profil tourné vers la droite.

| Prio | Planche | Hauteur au repos | Animations | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `blackbird/blackbird` | 19 px (0,2 m) | `repos`, `marche`, `course`, `fuite` | merle noir au bec jaune (les oiseaux bruyants du matin, V3) ; `repos` : il chante, bec ouvert à l'image 1 |
| 3 | `bear/bear` | 115 px (1,2 m à quatre pattes ; 2,2 m de long) | `repos`, `marche`, `course`, `attaque`, `degats`, `mort` | ours brun massif, pelage d'automne épais brun-roux plus sombre aux pattes, bosse aux épaules ; `attaque` : il se dresse à moitié et frappe de la patte (l'image 2 dépasse la hauteur au repos) ; `mort` : couché sur le flanc, comme endormi |
| 3 | `boar/boar` | 86 px (0,9 m ; 1,5 m de long) | `repos`, `marche`, `course`, `attaque`, `degats`, `mort`, `broute` | sanglier noir-brun aux soies hérissées sur l'échine, défenses courtes ; `attaque` : charge tête baissée et coup de boutoir ; `broute` : il fouille le sol du groin |
| 3 | `crow/crow` | 38 px (0,4 m) | `repos`, `marche`, `course`, `fuite` | corbeau noir aux reflets bleutés, bec fort ; `repos` : il tourne la tête ; `fuite` : envol lourd |
| 3 | `deer/deer` | 182 px (1,9 m bois compris ; 2 m de long) | `repos`, `marche`, `course`, `broute` | cerf roux d'automne aux grands bois ; paisible, il s'enfuit au galop (sa `course`) |
| 3 | `fox/fox` | 43 px (0,45 m ; 1,1 m queue comprise) | `repos`, `marche`, `course`, `fuite` | renard roux à gorge blanche et pattes noires, queue en panache ; `fuite` : un bond dans les fourrés |
| 3 | `frog/frog` | 12 px (0,12 m) | `repos`, `marche`, `course`, `fuite` | grenouille verte et brune du marais, gorge qui palpite au `repos` ; `fuite` : plongeon (image 3 : il ne reste qu'une petite gerbe) |
| 3 | `owl/owl` | 38 px (0,4 m) | `repos`, `fuite` | chouette hulotte brun-roux aux grands yeux noirs, pour la nuit (original) ; `repos` : la tête qui pivote ; `fuite` : envol silencieux |
| 3 | `squirrel/squirrel` | 24 px (0,25 m, assis) | `repos`, `marche`, `course`, `fuite` | écureuil roux, queue en panache, oreilles à pinceaux ; `repos` : assis, une noisette dans les pattes ; `fuite` : il bondit et file vers le haut, comme vers un tronc (V5 : le petit animal grimpeur) |
| 3 | `wolf/wolf` | 82 px (0,85 m ; 1,5 m de long) | `repos`, `marche`, `course`, `attaque`, `degats`, `mort` | loup gris aux flancs fauves, queue basse, regard jaune ; ils vont en meute au crépuscule dans la forêt profonde ; `attaque` : bond et morsure |

### 7.4 Les insectes (bandes animées)

Papillons et libellules restent des **bandes animées** (`anim/`, format du cahier n° 2), comme le papillon
déjà livré (`anim/butterfly.png`) : centrés dans chaque image, marge transparente tout autour.

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/anim/butterfly_orange_b.png` | 24 × 24, 4 images, 12 ips | bande animée, centrée | autre papillon orange vu de dessus, ailes plus arrondies bordées de brun, qui bat des ailes (ill. VEX : les papillons orange dans les hautes herbes) |
| 3 | `assets/hd2d/anim/dragonfly_amber.png` | 32 × 24, 4 images, 16 ips | bande animée, centrée | libellule ambrée vue de dessus, même mouvement |
| 3 | `assets/hd2d/anim/dragonfly_blue.png` | 32 × 24, 4 images, 16 ips | bande animée, centrée | libellule bleue vue de dessus, ailes transparentes nervurées (alpha net), qui vibrent |

## 8. Lot R6 : le temps et la lumière restants

### 8.0 Rappel du format (à coller avec le lot)

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

**Livré** (priorité 1 du cahier n° 3) : `sky_morning`, `sky_day`, `sky_rain`, `sky_night_wind`,
`cloud_sea_night`, `rain_splash`, `fairy_light`, `sun_window` et les trois fenêtres de nuit de l'intérieur
(`window_cross_small_night`, `window_cross_large_night`, `window_reading_seat_night`). Ce lot reprend le
reste, y compris les trois images de priorité 1 qui n'ont pas été livrées (section 2.5). Formats **confirmés
par le moteur** (E9, `docs/DECISIONS.md`) : le rideau de pluie, la lumière des fées, l'éclaboussure, les
fenêtres de nuit (`<nom>_night.png` posée à côté de `<nom>.png`, même cadrage) et les vitres éclairées
(`window_lit_*`, qui ne se montrent que la nuit) ; seuls les décalques animés (flaques) attendent un
`GroundDecal` animé.

**Références à joindre** : `assets/hd2d/sky/sky.png`, `sky_night.png`, `cloud_sea.png`, `cloud_a.png` ; pour
les fenêtres, `assets/hd2d/buildings/warehouse_main.png` et les fenêtres de jour du lot I
(`assets/hd2d/interior/window_curtains_open.png`, `window_bare.png`).

**Consigne** : colle le bloc de style, ce rappel, puis « Image `<chemin>`, <taille> px, <genre> : » et la
description de la ligne.

### 8.1 Pluie, gouttes et flaques

Une pluie fine au crépuscule sur le port (V1, « Entrepôt de fées ») ; des averses qui tombent comme
un seau renversé ; il pleut à verse à l'aube, puis tout s'arrête net avant midi et le terrain reste
boueux (V2, « L'écoulement du temps depuis lors »).

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/puddle_rain_a.png` | 192 × 115 (2 × 1,2 m), 4 images, 8 ips | décalque animé, vu de dessus, **format à confirmer par le moteur** (E9) | flaque d'eau boueuse sous la pluie : petits cercles qui naissent et s'élargissent à des endroits différents d'une image à l'autre, reflets gris du ciel, bord de boue sombre irrégulier ; non livrée avec le lot N priorité 1 ; décalque animé, **format à confirmer par le moteur** (E9 : un `GroundDecal` animé) ; chaque image garde le même contour de flaque, seuls les cercles changent |
| 1 | `assets/hd2d/anim/rain_curtain.png` | 384 × 384 (4 × 4 m), 4 images, 12 ips | bande animée, **alpha doux**, chaque image **sans raccord sur les quatre bords**, **format à confirmer par le moteur** (E9) | averse : traits de pluie fins et obliques (vers la droite en tombant), gris clair à 30-60 % d'opacité, de longueurs variées ; d'une image à l'autre, chaque trait descend d'un quart de l'image, la boucle tombe sans saut ; remplaçant du moteur en place (4 images de 384 × 384, confirmées par E9) ; non livré avec le lot N priorité 1 : **dessine d'abord UNE tuile de pluie de 384 × 384 sans raccord sur les quatre bords**, puis fais les 4 images en décalant les traits vers le bas d'un quart de l'image à chaque fois (les traits qui sortent en bas rentrent en haut) |
| 1 | `assets/hd2d/anim/rain_drizzle.png` | 384 × 384, 4 images, 10 ips | bande animée, alpha doux, sans raccord, **à confirmer** (E9) | pluie fine : traits courts, plus rares et plus pâles (20 à 40 %), presque verticaux ; remplaçant du moteur en place ; même méthode que `rain_curtain` : une tuile sans raccord, puis quatre décalages d'un quart ; traits plus courts, plus rares et plus pâles |
| 2 | `assets/hd2d/anim/eave_drip.png` | 48 × 192 (0,5 × 2 m), 4 images, 8 ips | bande animée, suspendue (le haut de l'image est l'égout du toit) | trois gouttes qui tombent d'un bord de toit à des moments décalés, sur toute la hauteur de l'image |
| 2 | `assets/hd2d/anim/puddle_rain_b.png` | 134 × 96 (1,4 × 1 m), 4 images, 8 ips | décalque animé, **à confirmer** | petite flaque sous la pluie, même mouvement |


### 8.2 Ciels, mer de nuages et nuages de pluie

L'automne de l'île : un matin couvert de nuages de pluie, comme toujours, que la lueur du matin
traverse avant un bleu d'automne sans nuages (V1, « Les valeureux et leurs successeurs ») ; un jour
nuageux où la pluie menace (VEX, « Des émotions sans nom ») ; des averses soudaines sous des nuages
couleur de cendre, nuit noire en plein jour (V2, « De ce côté-ci de l'écran ») ; la nuit de
l'arrivée, vent violent qui hurle sous un ciel étoilé (V1, « L'Homme sans Marque ») ; des comètes
dans le ciel du nord (V3, « Des journées chaudes… »). Restent : `sky.png` (fin d'après-midi),
`sky_dusk.png` (couchant), `sky_night.png` (nuit claire, voie lactée, la nuit de la colline).

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/sky/cloud_rain_a.png` | 768 × 256 (à 48 px/m) | nuage, **alpha doux** | gros nuage de pluie gris, base plate et sombre d'où pendent des traînées de pluie |
| 2 | `assets/hd2d/sky/cloud_rain_b.png` | 576 × 192 (à 48 px/m) | nuage, **alpha doux** | nuage de pluie plus petit, effiloché, gris-mauve |
| 2 | `assets/hd2d/sky/cloud_sea_rain.png` | 1024 × 1024 | mer de nuages | la mer de nuages sous la pluie : crêtes gris cendre ternes, creux mauve sombre, nappes de bruine |
| 2 | `assets/hd2d/sky/sky_overcast.png` | 2048 × 1024 | ciel | jour nuageux, la pluie menace : plafond gris cendre uniforme et bas, quelques nuages plus sombres qui pendent, lumière plate sans soleil ; mer de nuages grise |
| 3 | `assets/hd2d/sky/cloud_sea_morning.png` | 1024 × 1024 | mer de nuages | la mer de nuages au matin : crêtes pêche pâle et gris rosé, creux lavande froid |
| 3 | `assets/hd2d/sky/sky_night_comets.png` | 2048 × 1024 | ciel | nuit d'hiver claire et vive, étoiles très denses, deux comètes à longue queue pâle au nord (au milieu de l'image) (V3) |


### 8.3 Fenêtres de nuit et vitres éclairées

**Dehors**, les fenêtres éteintes des nouvelles façades du lot K s'allument la nuit : ces **vitres
éclairées** se posent exactement sur elles (seulement les carreaux et les croisillons, pas le
cadre ni le mur). Les façades des cahiers n° 1 et 2, elles, ont leurs fenêtres toujours éclairées.
**Dedans**, les fenêtres du lot I ont leur version de nuit, au même cadrage au pixel près : la nuit,
la fenêtre de Willem ne montre qu'un noir profond (V1, « L'Homme sans Marque »).
**(Format à confirmer par le moteur, lot E9.)**

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 2 | `assets/hd2d/interior/window_bare_night.png` | 106 × 134 | fenêtre, appui à 0,7 m | `window_bare.png` (jointe) la nuit : vitres d'un noir profond bleuté, sans étoile, un seul reflet (V1) |
| 2 | `assets/hd2d/interior/window_curtains_open_night.png` | 115 × 154 | fenêtre, appui à 0,8 m | `window_curtains_open.png` (jointe) la nuit : vitres bleu nuit, rideaux plus sombres |
| 2 | `assets/hd2d/props/window_lit_large.png` | 134 × 134 (1,4 × 1,4 m) | vitre éclairée | carreaux d'une grande fenêtre à croisillons (neuf carreaux) éclairés, l'ombre d'un rideau sur un côté |
| 2 | `assets/hd2d/props/window_lit_small.png` | 77 × 96 (0,8 × 1 m) | vitre éclairée | carreaux d'une petite fenêtre à croisillons (six carreaux) éclairés de l'intérieur d'un jaune chaud (#FFE6A6), plus clair au centre, croisillons sombres ; rien autour |
| 3 | `assets/hd2d/props/window_lit_round.png` | 58 × 58 (0,6 m) | vitre éclairée | œil-de-bœuf éclairé, croisillon en croix |


### 8.4 Lumières

Les fées font une petite lumière magique dans la main ; la nuit du marais, une lumière qui
zigzague annonce Pannibal, puis Chtholly arrive avec la sienne (V1, « L'Homme sans Marque »). Sur la
colline, les quarante et un talismans de Seniorious flottent autour d'un petit cristal comme une
lumière d'étoiles et tintent comme un métallophone (V1, « Le ciel étoilé sous le ciel étoilé »). Le
transport de la Garde descend précédé d'une lumière si forte qu'on ne voit pas sa silhouette (V1,
« Entrepôt de fées »). La lueur du matin passe par la fenêtre (V1, « Les valeureux… »).

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/talisman_float.png` | 24 × 24 (0,25 m), 4 images, 6 ips | bande animée, centrée | un éclat de talisman : fragment de métal blanc gravé qui flotte et tourne lentement sur lui-même en luisant comme une étoile (le halo en alpha doux) |
| 1 | `assets/hd2d/sky/ship_searchlight.png` | 384 × 768 (4 × 8 m) | lointain, **alpha doux**, ancre libre | cône de lumière blanche très forte qui descend à travers les nuages, plus intense en haut, qui s'élargit vers le bas ; aucun navire dessiné (V1) |
| 2 | `assets/hd2d/decals/moon_window.png` | 192 × 144 | décalque de lumière, **alpha doux** | la même tache la nuit : lumière bleu pâle (20 à 35 %), contours plus doux |

## 9. Lot R7 : les navires en volume

### 9.0 Rappel du format (à coller avec le lot)

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

Les navires sont un genre nouveau, **en volume** : **format à confirmer par le moteur** (lot E7, après
accord).

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

**Ce qui existe déjà** : les flancs plats et leurs hélices (`props/airship_ferry.png`,
`props/airship_barocupot.png`, `anim/airship_*_propeller.png`, refaits d'après les planches officielles) ; les
quais, bras d'ancrage replié, pylône et passerelle ; **tous les intérieurs de bord** (conseil de guerre,
coursive, cabines, machines, infirmerie, soute, panneaux du pont : `docs/ASSETS_HD2D_NAVIRES.md`). Ce lot
ne dessine que le **volume extérieur** des deux navires de l'acte 1 : le transport de la Garde (il se pose
au port au crépuscule du jour 7, scène 7.4 : descente, amarrage, trappe, départ ; on n'y monte pas à
l'acte 1) et le Barocupot (vu de l'intérieur à la scène 8.7, comme une ombre dans les nuages à la scène 8.6 :
il ne vient jamais au port).

### 9.1 Le transport de la Garde

Le navire qui ramène les fées du combat : il descend d'au-dessus de la mer de nuages, précédé d'une
lumière si forte qu'on ne voit pas sa silhouette ; il est **petit**, militaire, et ne ressemble ni à
un dirigeable de banlieue ni à celui d'un passeur ; deux pales de rotor s'arrêtent peu à peu, le
bruit de la chaudière enchantée décroît, la trappe de sortie s'ouvre sous la pression, et le lézard
géant doit se faire petit pour en sortir (V1, « Entrepôt de fées »). **(Format à confirmer par le
moteur.)**

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 1 | `assets/hd2d/anim/garde_transport_hatch.png` | 192 × 192 (2 m), 4 images, 8 ips, non bouclée | bande animée | la trappe ronde du flanc qui s'ouvre sous la pression : 0 fermée ; 1 le volant tourne, un jet de vapeur ; 2 entrouverte, vapeur ; 3 grande ouverte sur l'intérieur sombre (V1) |
| 1 | `assets/hd2d/anim/garde_transport_rotor.png` | 192 × 192 (2 m), 4 images, 12 ips | bande animée, centrée | rotor à deux pales de fer sombre aux bouts rouges, vu de face, qui tourne d'un huitième de tour (45°) d'une image à l'autre : en 4 images, chaque pale prend la place de l'autre, boucle sans à-coup ; moyeu au centre exact de chaque image |
| 1 | `assets/hd2d/ships/garde_transport_side.png` | 1536 × 672 (16 × 7 m) | flanc, proue à droite | petit transport militaire de la Garde ailée, de flanc : coque trapue de tôle d'acier rivetée gris-bleu sombre, bande rouge de la Garde (#AE4A3E) le long du bordage, aile stylisée peinte à la proue (sans texte), quille de fer ; au milieu, une cabine basse à hublots ronds éclairés et une cheminée courte ; à l'arrière, la chaudière enchantée en nacelle sous la coque, grilles rougeoyantes ; **deux moyeux de rotor** au bout de bras courts qui sortent du flanc au-dessus du bordage, à un quart et aux trois quarts de la longueur, axe tourné vers la caméra (comme les hélices latérales du cahier n° 2), **sans pales** ; une trappe ronde fermée sur le flanc à l'arrière ; massif, sérieux, entretenu ; **aucun ballon** |
| 3 | `assets/hd2d/ships/garde_transport_34.png` | 1536 × 864 (16 × 9 m) | trois quarts avant | le même navire de trois quarts avant, en léger surplomb, rotors **avec** leurs pales immobiles, bande rouge, hublots éclairés |
| 3 | `assets/hd2d/ships/garde_transport_deck.png` | 1536 × 480 (16 × 5 m) | pont, vu de dessus | le pont du même navire vu de dessus, proue à droite : tôles rivetées, passavants, toit de la cabine, les bras des deux rotors qui dépassent de chaque bord, écoutille, bastingage de fer, caisses arrimées ; fond transparent autour de la coque |
| 3 | `assets/hd2d/ships/garde_transport_stern.png` | 480 × 672 (5 × 7 m) | poupe, de face | le même navire vu de l'arrière : poupe arrondie de tôle, gouvernails de direction, la nacelle de la chaudière sous la coque, de chaque côté, un bras de rotor et ses deux pales vues par la tranche, immobiles |

### 9.2 Le Barocupot

Le navire de la Garde ailée où Chtholly est recueillie après sa chute dans les nuages : au moins
deux ponts ; au deuxième, une petite salle du conseil de guerre prévue pour plusieurs personnes, où
l'on est à l'étroit avec un lézard deux fois plus grand qu'une fée ; on y prête une serviette et on
y sert un thé chaud, amer et piquant, dans des tasses minuscules pour un lézard (V1, « La fille
errante et le lézard volant »). Son flanc existe (`props/airship_barocupot.png`, 24 × 11 m, deux
moyeux). **(Format à confirmer par le moteur.)**

| Prio | Fichier | Taille (px) | Genre, ancre (sauf mention : milieu du bord bas) | Consigne à coller |
| --- | --- | --- | --- | --- |
| 3 | `assets/hd2d/ships/barocupot_34.png` | 2688 × 1248 (28 × 13 m) | trois quarts avant | le Barocupot de trois quarts avant, en léger surplomb, dans les nuages : hélices latérales avec leurs pales, bande rouge, hublots éclairés ; massif |
| 3 | `assets/hd2d/ships/barocupot_deck.png` | 2304 × 576 (24 × 6 m) | pont, vu de dessus | le pont supérieur du Barocupot vu de dessus, proue à droite, dans le style de `airship_barocupot.png` (joint) : tôles d'acier rivetées gris-bleu, bande rouge au bordage, toit de la passerelle de commandement vitrée à l'avant, écoutilles, canon court sous bâche, manches à air, rambardes ; fond transparent autour |
| 3 | `assets/hd2d/ships/barocupot_stern.png` | 576 × 1056 (6 × 11 m) | poupe, de face | le Barocupot vu de l'arrière : poupe haute, deux ponts de hublots, ailerons de queue, la grande trappe de soute fermée, les deux nacelles des fours sous la coque |

Le **passeur** (`props/airship_ferry.png`, 1344 × 672) garde son flanc plat : on ne le voit qu'au loin
(scène 1.1), il n'a pas de vues en volume.


## 10. Commander, vérifier, livrer

### 10.1 En résumé

| Lot | Images | Planches | Prio 1 | Prio 2 | Prio 3 |
| --- | --- | --- | --- | --- | --- |
| **R0** | 54 | 0 | 28 images | 19 images | 7 images |
| **R1** | 39 | 0 | 12 images | 19 images | 8 images |
| **R2** | 2 | 35 | 10 planches | 2 images, 23 planches | 2 planches |
| **R3** | 75 | 0 | 19 images | 30 images | 26 images |
| **R4** | 80 | 29 | — | 14 images, 6 planches | 66 images, 23 planches |
| **R5** | 27 | 10 | — | 4 images, 1 planche | 23 images, 9 planches |
| **R6** | 19 | 0 | 5 images | 11 images | 3 images |
| **R7** | 9 | 0 | 3 images | — | 6 images |
| **Total** | **305** | **74** | 67 image(s), 10 planche(s) | 99 image(s), 30 planche(s) | 139 image(s), 34 planche(s) |

Les images comptées sont celles à **dessiner** : 8 remplaçants et les corrections du lot R0 (fichiers livrés à refaire) y figurent ; les planches de personnages comptent pour **trois PNG et trois JSON** chacune. Les effets
`fx/*` et les 24 accessoires du cahier n° 4 ne sont pas recommandés.

### 10.2 Ordre de commande

Une conversation (ou une PR de livraison) par lot, ou par famille d'images dans un lot ; dans chaque lot, la
priorité 1 d'abord. L'ordre suit les phases de la refonte (`docs/REFONTE.md`, section 9) :

| Étape | Quoi | Pour quoi |
| --- | --- | --- |
| 0 | **R0** priorités 1 et 2 (corrections des tables, des chaises et du canapé ; vues de flanc et de dos des meubles collés aux murs est et ouest ; lits par le pied ; passerelle) | les tables et le canapé que l'utilisateur voit mal ; sans ces vues, les meubles des murs est et ouest font face au sud |
| 1 | **R1** priorité 1 (façades et flancs, chambranle, fourrés et haie, toit, couverture du lit de fer) ; **R2** priorité 1 (Willem dans le marais, Willem qui porte, `fairy_11`, `fairy_12`, Kana, Giniette, `chtholly_pajamas`, blouse, geste du lycanthrope) | la tranche « l'entrepôt » (jours 1 à 4) et ses scènes qui n'ont pas de repli |
| 2 | **R1** et **R2** priorité 2 (le reste des pièces, les gestes, les pyjamas et la pluie, les fées 07 à 10, Willem au ballon) | la vie de la maison |
| 3 | **R6** priorité 1 (pluie, flaques, projecteur du navire, talismans) ; **R3** priorité 1 (sentier, marais, panneau du port, café, horloge) ; **R7** priorité 1 (transport de la Garde : flanc, rotor, trappe) | les jours 1, 7, 9 et 11 : l'embuscade au marais, le port sous la pluie, le café, l'horloge |
| 4 | **R3** priorité 2, **R4** section 6.1 (gens du village et du port), **R6** priorité 2 | les jours 5 à 12 complets |
| 5 | **R4** priorité 2 (snack-bar, café de la ville), puis **R0** à **R7** priorité 3, dans l'ordre : le monde autour (ville, forêt profonde, montagne, faune) | l'île n° 68 complète |

Une partie des images « à confirmer par le moteur » attend l'accord du lot qui les intègre (section 10.5).

### 10.3 Vérifier avant de livrer

1. Pars de la **dernière version de `main`**.
2. Dépose chaque image à son **chemin exact** ; pour une planche, les trois PNG et les trois JSON.
   Ne livre **que** les fichiers de ce document : ni sources, ni galeries, ni aperçus, ni outils,
   ni code, ni autre personnage, ni changement des fichiers existants.
3. Lance `python3 tools/hd2d_assets.py check` (tailles, transparence, raccords des tuiles et des
   bordures, ancrage au bord bas, bandes animées, alpha doux) et
   `python3 tools/hd2d_sheets.py check` (planches : format, animations et cadences, hauteur debout à
   6 % près, même échelle que `repos`, mêmes animations dans les trois vues). Ces deux outils ne
   vérifient que les images inscrites dans `tools/hd2d_manifest.json` (clés `images` et `sheets`) :
   les lots du moteur y inscrivent celles de ce cahier (avec la clé `lot` : `R0` à `R7`) en même temps
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
   planches) : « généré avec ChatGPT le …, cahier n° 5, lot R… ».
7. Dans la description de la PR : les fichiers livrés, ceux qui manquent, les écarts connus
   (taille, cadrage, côté d'un accessoire).

8. **Tenir l'état à jour** : à chaque livraison, la description de la PR distingue produit, contrôlé
   techniquement, placé dans le jeu et validé en jeu ; l'état des lots (cahier n° 4, ce cahier) ne change
   qu'après la livraison effective.

**Contrôle des images que le manifeste ne connaît pas** (la plupart des images de ce cahier) :

```text
python3 -I - <<'PY'
from PIL import Image
import sys
for p in sys.argv[1:]:
    im = Image.open(p); a = im.getchannel("A") if im.mode == "RGBA" else None
    print(p, im.size, im.mode, "alpha net" if a is None or not sum(a.histogram()[1:255]) else "ALPHA FLOU")
PY
```

(à lancer avec les chemins livrés en arguments) ; pour une planche : `python3 tools/hd2d_sheets.py strip
<out.png> <json>` et regarder la ligne du sol, l'axe de l'ancre et la hauteur debout en orange. Les lots du
moteur inscrivent ensuite ces images au manifeste (clé `lot` : `R0` à `R7`).

### 10.4 Un fichier livré remplace le remplaçant du même nom

**Rappel : une image livrée à son chemin exact remplace le remplaçant du même nom, sans changer le code.**
`tools/import.sh` crée les `.import` des nouvelles images (à livrer avec elles) ; une nouvelle tuile de sol
demande `python3 tools/hd2d_assets.py atlas`. Les remplaçants de ce cahier : `door_frame_wood`, `floor_flagstone_cellar`, `wall_cellar_stone`, `wallcut_stone`, `wallitem_height_marks`, `rain_curtain`, `rain_drizzle`, `bank_earth`.

### 10.5 Formats à confirmer par le moteur

| Format | Images | Lot du moteur | Ce qu'il faut trancher | Commander |
| --- | --- | --- | --- | --- |
| Vues de flanc, de dos et par le pied des meubles (`_side`, `_back`, `_foot`) | 41 images (R0) | E3 Intérieurs | le moteur choisit l'image d'après la rotation du meuble (`_side` tournée vers l'est, retournée pour l'ouest) et la place dans `tools/hd2d_interior.py` | tout de suite (seul le choix de l'image change) |
| Planches composites de scène : Willem et la personne qu'il porte (`willem_carry`, `willem_piggyback`) | 2 planches (R2) | E4 Vie, E6 Récit | une planche à deux personnages dans un seul dessin, ou deux sprites l'un sur l'autre | après accord |
| Planches complémentaires et de geste (`willem_marsh`, `willem_life`, `*_work`) et nom `travaille` pour une fée de cuisine (`fairy_12`) | 5 planches et 1 animation (R2) | E4 Vie | fusion dans la planche existante ou seconde planche ; nom `_work` | tout de suite (seul l'usage change) |
| Tenues de pluie, de nuit, blouse, linge | 14 planches (R2) | E4 Vie, E6 Récit | quand le jeu passe d'une planche à l'autre | tout de suite |
| Entraînement au bâton (`_stick`, animation `pare`) | 4 planches (R2) | E8 Jeux | animations de parade et de rythme | après accord |
| Toit-terrasse : `floor_roof_deck`, `roof_edge_slate` | 2 images (R1) | E2, E3 | le toit est une carte du dehors : une 28e couche de l'atlas du sol, un panneau de bord de toit | après accord |
| Couverture de lit en surimpression : `bed_iron_cover` | 1 image (R1) | E3, E4 | un personnage couché sous une couverture | après accord |
| Décalques dans les pièces (tapis, papiers, flaques, cartes) | 5 décalques (R1) | E3 | décalques posés sur le sol d'une `InteriorRoom` | tout de suite |
| Sol des sentiers et de la rivière : `ground/path_overgrown`, `ground/river_water` | 2 tuiles (R3, R5) | E2 Sol en relief | l'atlas du sol a 27 couches (`GROUND_LAYERS`) | après accord |
| Faces des paliers : `cliff/step_*`, `cliff/wall_*_1m` ; `town_retaining_wall` | 7 images (R3, R4) | E2 | hauteur des faces (0,5 et 1 m), raccords, coins | après accord |
| Socle des façades de ville, escaliers : `town_house_*`, `town_stairs_*` | 10 images (R4) | E2 | façades sur deux paliers, escaliers entre paliers | après accord |
| Premier plan suspendu : `fg_canopy_a`, `fg_canopy_b` | 2 images (R3) | E10 Densité | un panneau accroché en haut de l'écran au-dessus du joueur | après accord |
| Planches d'animaux : nombres d'images, cadences, `broute` | 10 planches (R5) | E5 Faune | la section 8.1 de la refonte ne donne que les noms | après accord |
| Navires en volume (flanc, pont, poupe, trois quarts), rotor et trappe | 9 images (R7) | E7 Navires | navire en volume au nord du quai, pont où l'on marche | après accord |
| Flaques animées : `puddle_rain_a`, `puddle_rain_b` | 2 images (R6) | E9 Lumière et temps | un décalque animé (`GroundDecal` à bande) | après accord |

### 10.6 Ce que ce cahier ne commande pas

- Les 24 accessoires du cahier n° 4 et les 50 images de bord (déjà livrés).
- Les effets `fx/shadow`, `fx/glow`, `fx/light_pool`, `fx/rain_drop`, générés par le jeu.
- Les images de l'ancienne île seule (palissade, arène, Couchant, dunes), de la surface et des autres îles.
- Les portraits des habitants de métier (facultatifs : `<id>_portrait.png`, 256 × 256, comme au cahier n° 3,
  4.13) ; les icônes d'objets des anciennes quêtes.
