# Cahier des charges des images HD-2D

Ce document se donne tel quel à ChatGPT (ou à tout outil d'images). Il remplace les anciens
cahiers 3D. Le jeu n'utilise **que des images 2D** : des personnages en planches de sprites, un
sol en tuiles, des bâtiments en façades, des décors en panneaux debout et un ciel peint, vus par
une caméra fixe inclinée, comme dans *Octopath Traveler*. Chaque image a déjà un remplaçant
généré (`tools/hd2d_assets.py`) au même chemin et au même format : une image livrée prend sa
place sans toucher au code.

## 1. Bloc de style (à coller au début de chaque conversation)

```text
Tu produis des images pour WordEnd, un jeu d'action-aventure en « HD-2D » à la manière
d'Octopath Traveler : du pixel art posé dans un petit décor en relief, vu de face par une caméra
inclinée. Univers : l'île flottante n° 68 du roman SukaSuka (traduction Yume Novel), une dalle
de pierre au-dessus d'une mer de nuages, couverte d'une forêt d'automne ; un vieil entrepôt de
bois où vivent des fées (des fillettes aux cheveux de couleurs vives), un petit port à
dirigeables, un bord rocheux face au couchant, une colline à myosotis. Toujours la fin d'un
après-midi d'automne.
Style obligatoire :
- pixel art net : 1 pixel de l'image = 1 pixel d'art, aucun flou, aucun anticrénelage vers le
  fond, aucun dégradé lisse de peinture numérique ; aplats et dégradés en paliers, tramage léger
  permis ; contours de 1 px d'une teinte sombre de la couleur voisine (jamais noir pur) ;
- échelle fixe : 96 pixels par mètre (un personnage de 1,5 m mesure 144 px) ;
- éclairage plat et doux dans l'image, lumière venant de la gauche (le couchant à l'ouest) ;
  aucune ombre portée au sol (le jeu ajoute les ombres et la lumière) ;
- palette naturelle, un peu désaturée, réchauffée par le couchant (or, rouille, mousse, pierre
  claire, bois brun) ; peu de couleurs vives ; ni blanc pur ni noir pur ;
- univers européen rustique et usé (bois patiné, pierre, ardoise, tuiles rouges, cuivre, fer
  riveté) ; rien d'asiatique (ni torii, ni lanterne de papier, ni cerisier), rien de moderne ;
- aucun texte, chiffre, logo ni signature dans l'image ;
- fond transparent (PNG RGBA, alpha 0 ou 255 seulement) pour tout ce qui n'est pas une tuile ;
- respecte exactement la taille en pixels et le cadrage demandés.
Pour chaque image, je te donnerai : son nom de fichier, sa taille exacte, son cadrage et son sujet.
```

Couleurs de référence (MONDE.md, section 5.4) : herbe `#87A35E`, herbe sèche `#AFA764`, herbe
dorée `#C2AA66` ; feuillages or `#CC9446`, rouille `#A95A3A`, jaune `#D2B45C`, sapins `#3D5946` ;
pierre claire `#C2B49F`, ombre `#837667` ; sable `#D6C19E` ; bois clair `#A57C58`, foncé
`#654D3C` ; murs crème `#EAE0CB` ; ardoise `#5E6C86`, tuiles `#B65E4B` ; fer `#717B84`, laiton
`#B4955E` ; eau du marais `#4A675F`, roseaux `#9C9563` ; myosotis `#7F9CCF` ; cristaux lumineux
`#FFE6A6` ; fanion de la Garde `#AE4A3E` ; ciel `#6E5C86` → `#EBA676` ; nuages `#F4DCC6`,
`#BBA3BF`, `#82769C`.

## 2. Règles communes

| Règle | Valeur |
| --- | --- |
| Densité | **96 px par mètre** partout dans le monde (sol, falaises, façades, décors, personnages) ; décor lointain (dirigeables, îles au loin) : 48 px/m |
| Format | PNG RGBA 8 bits ; tuiles et textures sans raccord : opaques |
| Taille | exacte au pixel près (tableaux ci-dessous) ; si l'outil ne sait pas la produire, livre l'image la plus nette possible en plus grand et lance `python3 tools/hd2d_assets.py fit <fichier>` (réduction au plus proche voisin, alpha seuillé) |
| Cadrage des panneaux | objet entier, collé au bord bas (aucune ligne vide sous le pied), centré horizontalement ; **ancre = milieu du bord bas = point posé au sol** (pied du tronc, base du mur) |
| Angle de vue | tuiles : vue strictement de dessus ; façades : élévation de face, sans perspective ; décors et personnages : vue de face, très légèrement plongeante (on devine le dessus des objets, 10 à 15°) |
| Orientation | personnages et animaux dessinés **tournés vers la droite** (le jeu les retourne) ; tout le reste vu de face |
| Poids | moins de 1 Mo par image ; le jeu entier vise moins de 25 Mo |

Le jeu filtre les images au plus proche voisin (pixels nets) et les éclaire lui-même (lanternes,
fenêtres, couchant). Une image livrée remplace le fichier du même nom ; vérification :
`python3 tools/hd2d_assets.py check` (tailles, transparence, raccords), puis `tools/check.sh`.

## 3. Personnages (planches de sprites)

Format de l'easter egg, repris tel quel : une planche PNG et son JSON, comme
`assets/characters/chtholly/chtholly.png` et `chtholly.json`.

```json
{ "version": 1, "echelle": 2, "planche": [largeur, hauteur],
  "format": "images : [x, y, largeur, hauteur, ancre x, ancre y] en px de la planche",
  "animations": {
    "repos":   { "ips": 2,  "boucle": true,  "images": [[x, y, l, h, ax, ay], …] },
    "attaque": { "ips": 14, "boucle": false, "images": […], "coup": [1, 2, 3] },
    "charge":  { "ips": 10, "boucle": false, "images": […], "onde": 3 } } }
```

- Une rangée par animation, de haut en bas dans l'ordre des tableaux ; les images d'une rangée
  de gauche à droite, séparées d'au moins 2 px transparents.
- `ancre` : le point entre les deux pieds, au sol, en px depuis le coin haut gauche de l'image ;
  il ne bouge pas d'une image à l'autre quand le personnage ne se déplace pas.
- **Hauteur** : la 1re image de `repos` mesure exactement la taille du personnage × 96 (tableau
  3.4) ; les autres images peuvent dépasser (épée, bras levés, chute).
- `coup` : images où l'épée ou la gueule touche ; `onde` : image qui lance l'onde.
- **Trois vues par personnage** (depuis la livraison de priorité 1) : `<id>.png` + `.json` est le
  profil tourné vers la droite (le jeu en fait le profil gauche en miroir), `<id>_front` la face
  (vers la caméra) et `<id>_back` le dos, chacune avec son JSON. Les trois vues ont exactement
  les mêmes animations, nombres d'images, `ips`, `boucle`, `coup` et `onde` (le jeu passe d'une
  vue à l'autre sans changer d'image), et **la même hauteur debout** : de face comme de dos, le
  personnage mesure sa taille × 96 px (la livraison de priorité 1 a dessiné Chtholly de face à
  130 px au lieu de 144).
- **Même échelle dans toute la planche** : chaque image de `repos`, `marche` et `parle` a la
  même taille de personnage que la 1re image de `repos` (les livraisons ont dessiné des `parle`
  et des `marche` 10 à 36 % plus petites ou plus grandes : le personnage rapetisse en parlant) ;
  **une seule silhouette par case** (pas de figure en double empilée au-dessus de l'autre).
- Vérification : `python3 tools/hd2d_sheets.py check` (planches listées dans
  `tools/hd2d_manifest.json`, clé `sheets`), ancres recalculées par `python3 tools/hd2d_sheets.py
  anchors <json>… --write`, planche de contrôle par `python3 tools/hd2d_sheets.py strip`.
- Outil de découpe d'une planche dessinée : `tools/wordend/decouper-planche.py` (dépôt
  Yume-WordPress) ; planches de remplacement : `python3 tools/gen_placeholders.py`.

### 3.1 Fée jouable (Chtholly et les skins)

| Animation | Images | ips | Boucle | Contenu |
| --- | --- | --- | --- | --- |
| `repos` | 2 | 2 | oui | debout, Seniorious tenue basse, respiration |
| `marche` | 6 | 10 | oui | cycle de marche |
| `course` | 5 | 14 | oui | course penchée |
| `attaque` | 4 | 14 | non | coup d'épée horizontal ; `coup` : [1, 2, 3] |
| `charge` | 4 | 10 | non | l'épée s'illumine (lumière bleutée dans les fissures de la lame), puis l'onde part ; `onde` : 3 |
| `degats` | 1 | 1 | non | touchée, recule |
| `mort` | 1 | 1 | non | à terre, épuisée : une défaite, pas une mort (ni sang, ni disparition) |

Portrait : `assets/characters/<id>/<id>_portrait.png`, **256 × 256**, buste de la tête aux
épaules, visage de trois quarts tourné vers la droite, fond transparent.

### 3.2 PNJ

`repos` (2 images, 2 ips, boucle), `marche` (6 images, 10 ips, boucle), `parle` (2 à 4 images,
6 ips, boucle : bouche et petit geste) ; portrait 256 × 256. Ithea et Nephren sont aussi des
skins jouables à venir : leur planche porte les 7 animations de 3.1 **et** `parle`.

### 3.3 Corps de Timere

`assets/enemies/timere/timere.png` + `.json` : `repos` 5 (6 ips), `marche` 4 (7), `course` 6 (12),
`fouet` 4 (8, `coup` [1, 2]), `morsure` 4 (8, `coup` [1, 2]), `degats` 5 (12), `mort` 6 (8) ;
corps moyen de 1,03 m (99 px) au repos, le jeu l'agrandit ou le réduit (0,8 à 1,3) pour les
autres corps.

### 3.4 Liste et consignes

Chaque ligne se colle après le bloc de style : « Planches de sprites `<chemin>` (profil tourné
vers la droite), `<chemin>_front` (de face) et `<chemin>_back` (de dos), fond transparent, mêmes
animations et nombres d'images dans les trois : <3.1 ou 3.2>, une rangée par animation, une seule
silhouette par case, le personnage à la même taille dans toutes les images debout et dans les
trois vues. » puis la description.

| Prio | Fichier (`assets/characters/…`) | Taille (repos) | Description à coller |
| --- | --- | --- | --- |
| 1 | `chtholly/chtholly` (remplace l'actuelle, qui sert à l'acte 3) | 1,5 m = 144 px | Chtholly à l'acte 1, fée soldate de 15 ans, proportions des sprites d'*Octopath Traveler* (environ deux têtes et demie à trois têtes de haut), dans la continuité de la planche actuelle : longs cheveux céruléen clair (#6C89BB à #92B6DB) **sans aucune mèche rouge**, deux petites couettes hautes, yeux bleu océan ; uniforme de la Garde ailée (veste bleu marine à col droit et boutons argentés, jupe plissée sombre, bottines), broche d'argent à pierre bleue en goutte sur la poitrine ; Seniorious : grande épée presque aussi haute qu'elle, lame blanc argenté faite de plaques fissurées, garde sombre hérissée |
| 2 | `willem/willem` | 1,75 m = 168 px | Willem Kmetsch, jeune homme maigre, cheveux noirs en bataille, yeux sombres, sourire fatigué ; uniforme militaire bleu nuit croisé à boutons dorés un peu trop étroit, ceinturon, bottes |
| 2 | `nygglatho/nygglatho` | 1,85 m = 178 px | Nygglatho, troll à l'air de jeune femme, une tête de plus que tous ; longs cheveux rose saumon, yeux vert printanier, chemisier vert vif à volants, tablier blanc, coiffe blanche à volants ; sourire doux |
| 2 | `ithea/ithea` (7 animations + `parle`) | 1,45 m = 139 px | Ithea, fée soldate de 14 ans : cheveux blond paille, longue tresse à perle bleue, yeux ambre au regard félin, écharpe rouge, veste vert pâle sur robe brun-rouge, bas vert olive ; Carillon Valgulious dans le dos |
| 2 | `nephren/nephren` (7 animations + `parle`) | 1,3 m = 125 px | Nephren, fée soldate de 13 ans, toute petite : cheveux gris cendré à reflets lavande en deux couettes ondulées à rubans noirs, yeux gris anthracite, visage impassible, tunique violette à capuche et frise de triangles blancs, livre rouge |
| 2 | `tiat/tiat` | 1,1 m = 106 px | Tiat, petite fée de moins de dix ans : cheveux et yeux vert feuille (#78B89E), blouse blanche, gilet vert sombre, air enthousiaste |
| 2 | `pannibal/pannibal` | 1,25 m = 120 px | Pannibal, petite fée d'une dizaine d'années : cheveux violet vif sur un œil, petite cape, épée de bois, brindille à la bouche, air pince-sans-rire |
| 3 | `collon/collon` | 1,2 m = 115 px | Collon, petite fée intenable : longs cheveux roses, bandeau rouge, une canine qui dépasse, tunique lacée |
| 3 | `lakhesh/lakhesh` | 1,2 m = 115 px | Lakhesh, petite fée polie : cheveux pêche à petite couette sur le côté, gilet brun clouté |
| 3 | `almita/almita` | 0,95 m = 91 px | Almita, toute petite fée : cheveux crépus jaune citron, robe simple |
| 2 | `limeskin/limeskin` | 2,8 m = 269 px | Limeskin, lézard géant aux écailles blanc laiteux, tête draconique cornue, tresse à plumes, collier tribal, uniforme d'officier de la Garde ailée |
| 3 | `cat_waiter/cat_waiter` | 1,65 m = 158 px | serveur homme-chat du café, tablier, canines visibles, aimable |
| 3 | `ramikeldi/ramikeldi` | 1,7 m = 163 px | M. Rami, homme-chat d'âge mûr, chemise blanche, gilet rouge foncé, chapeau, yeux ambrés |
| 3 | `snack_vendor/snack_vendor` | 1,6 m = 154 px | jeune lycanthrope à tête de chien, tablier taché, jovial |
| 3 | `baker/baker` | 2,0 m = 192 px | boulanger homme-bête massif à tête d'ours, farine partout, bourru |
| 3 | `ferryman/ferryman` | 1,7 m = 163 px | passeur reptilien en ciré, casquette de pilote, lunettes |
| 3 | `egg_vendor/egg_vendor` | 1,55 m = 149 px | marchande sang-mêlé mouton : oreilles et laine bouclée, fichu, panier de paille |
| 3 | `garde_lookout/garde_lookout` | 1,9 m = 182 px | guetteur, lézard en uniforme de la Garde, longue-vue |
| 1 | `../enemies/timere/timere` | 1,03 m = 99 px | un corps de Timere : masse vert sombre amorphe, long cou terminé par une gueule dentée, six pattes de crustacé épineuses, griffes ; inquiétant mais lisible, ne ressemble à aucun animal réel |
| 4 | `nopht/nopht` (skin) | 1,4 m = 134 px | Nopht, fée soldate de 15 ans : cheveux vermillon courts et hérissés, yeux rouges, sweat à capuche brun foncé, bretelles rouges, short bordeaux à ourlet déchiqueté sur jambières noires ; Carillon Desperatio |
| 4 | `rhantolk/rhantolk` (skin) | 1,48 m = 142 px | Rhantolk, fée soldate de 15 ans : longs cheveux indigo à frange droite (#868BBF), fichu blanc, robe bleu ciel lacée à pèlerine, ceinture sombre ; Carillon Historia |

Fées de la communauté : mêmes règles (MONDE.md 1.2, HISTOIRE.md 5.3), 7 animations + `parle`,
dossier `assets/characters/fairy_<prénom>/`.

## 4. Sol : tuiles sans raccord

`assets/hd2d/ground/<nom>.png`, **384 × 384 px = 4 × 4 m**, vue strictement de dessus, opaque,
**sans raccord sur les quatre bords**, sans objet ni ombre portée. Le jeu les répète et les
mélange par zone et par masque (chemins, cour, rue, marais…) : livre chaque matière seule, sans
transition vers une autre.

Consigne : « Tuile de sol `<nom>.png`, 384 × 384 px, vue strictement de dessus, sans raccord sur
les quatre bords (elle se répète en damier), pixel art à 96 px/m : » puis :

| Prio | Nom | Description à coller |
| --- | --- | --- |
| 1 | `grass` | herbe d'automne rase vert-jaune (#87A35E), brins plus clairs par petites touffes, quelques taches d'herbe sèche (#AFA764) et rares feuilles mortes |
| 1 | `path_dirt` | chemin de terre battue ocre (#A57C58 éclairci), petits cailloux, traces de pas, quelques brins d'herbe |
| 1 | `flagstone` | vieilles dalles de pierre grise rectangulaires de 60 à 90 cm, joints envahis d'herbe et de terre |
| 1 | `forest_floor` | sous-bois : terre sombre, mousse, feuilles mortes rousses (#A95A3A) et dorées (#CC9446), aiguilles de sapin |
| 2 | `grass_dry` | herbe haute dorée de colline (#C2AA66) couchée par le vent, quelques épis |
| 2 | `sand` | sable pâle ocre gris (#D6C19E) en rides de vent, petits graviers de pierre claire |
| 2 | `rock` | dalle de pierre claire de l'île à nu (#C2B49F) en grandes plaques fissurées, sable dans les joints |
| 2 | `cobble` | pavés gris usés de 20 cm en rangées décalées, joints sombres |
| 2 | `peat` | tourbe et vase brun-vert du marais, flaques sombres, brins de roseaux couchés |
| 3 | `water` | eau sombre et peu profonde du marais (#4A675F), reflets clairs en petits traits, quelques lentilles d'eau |
| 3 | `mud` | terre boueuse brune piétinée, petites flaques (aire de jeux, potager) |
| 3 | `metal` | quai de tôle rivetée (#717B84) en plaques de 2 m, rivets, rouille aux joints |

## 5. Falaises et dessous de l'île

`assets/hd2d/cliff/`, vues de face, opaques, sans raccord à gauche et à droite (et en haut et en
bas pour les deux premières).

| Prio | Fichier | Taille | Description à coller |
| --- | --- | --- | --- |
| 2 | `cliff.png` | 384 × 384 | paroi de falaise verticale de pierre claire (#C2B49F → #837667) en strates horizontales, cassures franches, touffes d'herbe et petites racines ; sans raccord sur les quatre bords |
| 2 | `underside.png` | 384 × 384 | dessous de l'île flottante : cône de roche aux strates claires et sombres (#837667 et plus sombre, nuancé de violet par l'ombre), racines qui pendent ; sans raccord sur les quatre bords |
| 3 | `lip.png` | 384 × 96 | lèvre du bord de l'île vue de face, 1 m de haut : bord de dalle ébréché, herbe qui déborde en haut, première strate de roche en bas ; sans raccord à gauche et à droite |

## 6. Bâtiments : façades et matières

Un bâtiment du jeu est un volume simple (murs, toit) recouvert de matières sans raccord, avec sa
**façade sud** en image debout devant le volume (la caméra regarde le nord).

### 6.1 Façades

`assets/hd2d/buildings/<nom>.png` : **élévation de face** (sans perspective, sans dessus de toit),
fond transparent, mur collé aux bords gauche, droit et bas de l'image ; ancre = milieu du bord bas.
Type `long` : le faîtage est parallèle à la façade, l'image s'arrête à l'égout du toit (avec la
bordure du toit, 10 à 20 cm) ; type `pignon` : le faîtage part vers le fond, l'image comprend le
triangle du pignon jusqu'au faîtage (fond transparent de part et d'autre du triangle). Fenêtres
éclairées d'un jaune chaud (#FFE6A6), portes et volets peints dans l'image.

Consigne : « Façade de bâtiment `<nom>.png`, <taille>, élévation de face sans perspective, fond
transparent, mur collé aux bords gauche, droit et bas, pixel art à 96 px/m : » puis :

| Prio | Nom | Taille (px) | Type, mur / faîte (m) | Matières du volume | Description à coller |
| --- | --- | --- | --- | --- | --- |
| 1 | `warehouse_main` | 1536 × 624 | long, 6,5 / 9 ; prof. 8 | `wall_planks`, `roof_slate` | façade sud de l'entrepôt des fées, 16 m de large, deux étages : bardage de planches brun foncé délavé rapiécé de teintes différentes sur soubassement de pierre grise, petites fenêtres à croisillons éclairées (6 en haut, 4 en bas), au milieu une porte d'entrée en bois à deux battants, plannings punaisés à côté, plaque de bronze sans texte, à l'extrémité est la fenêtre à banc de la salle de lecture |
| 1 | `warehouse_porch` | 576 × 312 | panneau devant l'entrée | — | porche à auvent de bois sur deux poteaux, marches de pierre, banc de bois, toit d'ardoise vu de face (bande inclinée) |
| 1 | `warehouse_wing` | 576 × 624 | pignon, 3,5 / 6,5 ; prof. 9 | `wall_planks`, `roof_slate` | pignon sud de l'aile ouest de l'entrepôt, 6 m de large : planches brun foncé, porte de l'infirmerie au milieu, petite fenêtre ronde dans le pignon |
| 1 | `armory_door` | 240 × 240 | panneau | — | descente de pierre (quelques marches qui s'enfoncent) vers une porte de métal rivetée à cinq serrures, la seule chose froide de la cour |
| 2 | `tool_shed` | 288 × 216 | long, 2,25 / 2,6 ; prof. 2,5 | `wall_planks`, `roof_tin` | remise à outils en planches, porte entrouverte, râteau et pelle appuyés |
| 2 | `cafe` | 672 × 528 | long, 5,5 / 7,5 ; prof. 6 | `wall_plaster`, `roof_tiles` | café « La Clochette » : deux niveaux de pierre et colombages crème, grande vitrine, porte à clochette, auvent rayé, enseigne sans texte (une clochette peinte) |
| 2 | `shop_bakery` | 480 × 576 | pignon, 4 / 6 ; prof. 5 | `wall_stone`, `roof_tiles` | boulangerie de pierre, vitrine de pains, porte, enseigne en forme de pain sans texte |
| 2 | `shop_bookshop` | 480 × 576 | pignon, 4 / 6 ; prof. 5 | `wall_plaster`, `roof_tiles` | librairie de pierre peinte vert sombre, vitrine de livres, porte, enseigne en forme de livre ouvert |
| 2 | `projection_hall` | 672 × 576 | long, 6 / 7,5 ; prof. 7 | `wall_stone`, `roof_slate` | salle de projection : façade de pierre haute, porte double, affiche sans texte, volets clos |
| 3 | `stone_house` | 480 × 480 | pignon, 3,25 / 5 ; prof. 4,5 | `wall_stone`, `roof_tiles` | maison de pierre du bourg, porte, deux fenêtres, jardinière |
| 3 | `limashenka_house` | 576 × 576 | pignon, 3,75 / 6 ; prof. 5 | `wall_plaster`, `roof_tiles` | vieille maison aux volets clos qui se rouvrent, porte d'entrée, lierre |

### 6.2 Matières des volumes

`assets/hd2d/buildings/materials/<nom>.png`, **192 × 192 px = 2 × 2 m**, opaques, sans raccord
sur les quatre bords, vues de face (murs) ou de dessus dans le sens de la pente (toits : rangées
parallèles au bas de l'image).

| Prio | Nom | Description à coller |
| --- | --- | --- |
| 1 | `wall_planks` | bardage de planches verticales brun foncé (#654D3C) délavé, planches rapiécées de teintes différentes, clous |
| 1 | `roof_slate` | toit d'ardoise bleu-gris (#5E6C86) en rangées d'écailles, quelques ardoises plus claires, mousse |
| 2 | `wall_stone` | mur de moellons gris-beige (#C2B49F) jointoyés |
| 2 | `wall_plaster` | enduit crème (#EAE0CB) un peu sali, colombages de bois brun |
| 2 | `roof_tiles` | toit de tuiles rouges (#B65E4B) en rangées, tuiles plus claires et plus sombres |
| 3 | `roof_tin` | toit de tôle ondulée grise et rouillée |

## 7. Décors en panneaux

`assets/hd2d/props/<nom>.png` : objet debout vu de face (très légèrement plongeant), fond
transparent, collé au bord bas, centré ; ancre = milieu du bord bas (pied du tronc, base des
poteaux). Le jeu pose l'image debout face à la caméra, ajoute son ombre au sol et sa collision.

Consigne : « Décor `<nom>.png`, <taille>, objet debout vu de face, fond transparent, collé au bord
bas et centré, pixel art à 96 px/m : » puis :

| Prio | Nom | Taille (px) | Zone | Description à coller |
| --- | --- | --- | --- | --- |
| 1 | `well` | 168 × 240 | entrepôt | puits de pierre grise au toit de bardeaux sur deux poteaux, seau |
| 1 | `palisade` | 192 × 154 | entrepôt | module de palissade de rondins pointus de 2 m, liens de corde |
| 1 | `palisade_gate` | 384 × 288 | entrepôt | portail de bois à deux montants et linteau, lanterne de cristal suspendue, battants ouverts |
| 1 | `crystal_lamp` | 64 × 250 | partout | lampadaire de fer forgé, cristal lumineux jaune pâle (#FFE6A6) dans une cage |
| 1 | `tree_autumn` | 480 × 672 | partout | feuillu d'automne, feuillage or (#CC9446) en grandes masses, tronc brun |
| 1 | `tree_autumn_rust` | 480 × 672 | partout | même feuillu, feuillage rouille (#A95A3A) |
| 1 | `tree_autumn_yellow` | 480 × 672 | partout | même feuillu, feuillage jaune (#D2B45C) |
| 1 | `climbing_tree` | 768 × 960 | entrepôt | grand arbre d'automne aux branches basses, balançoire de corde |
| 1 | `bush` | 134 × 106 | partout | buisson d'automne roux et vert |
| 2 | `bench` | 154 × 86 | partout | banc de bois patiné |
| 2 | `laundry_line` | 576 × 211 | entrepôt | deux poteaux, une corde, trois draps blancs qui flottent au vent |
| 2 | `vegetable_patch` | 480 × 96 | entrepôt | rangée de potager d'automne : choux, citrouilles, tuteurs |
| 2 | `flower_bed` | 120 × 48 | entrepôt | parterre de fleurs d'automne le long d'un mur |
| 2 | `crate` | 77 × 77 | entrepôt | caisse de bois (but de fortune de l'aire de jeux) |
| 2 | `ball` | 32 × 32 | entrepôt, bois | ballon de cuir cousu |
| 2 | `myosotis` | 58 × 38 | partout | petit massif de myosotis bleus (#7F9CCF) |
| 1 | `tree_old_pine` | 384 × 1056 | bois | très grand sapin aux étages sombres (#3D5946), tronc moussu |
| 2 | `tree_old_pine_clawed` | 384 × 1056 | bois | même sapin, griffures d'ours sur l'écorce |
| 2 | `tree_pine` | 288 × 672 | bois, port | sapin moyen |
| 2 | `reeds` | 144 × 134 | bois | touffe de roseaux (#9C9563) |
| 2 | `log_bridge` | 384 × 77 | bois | tronc couché en passerelle, mousse |
| 2 | `berry_bush` | 125 × 96 | bois | buisson à baies rouges |
| 2 | `bear_rock` | 576 × 384 | bois | gros rocher moussu arrondi de 4 m de haut |
| 2 | `mossy_rock` | 192 × 115 | bois | rocher moussu |
| 2 | `mushroom` | 58 × 48 | bois | champignons rouges à pois blancs |
| 2 | `stick_rack` | 115 × 115 | bois | râtelier de bâtons d'entraînement |
| 2 | `play_goal` | 288 × 192 | bois | but de fortune : deux poteaux, une barre, chiffons blancs |
| 2 | `play_goal_red` | 288 × 192 | bois | le même, chiffons rouges |
| 1 | `vigil_bell` | 134 × 230 | Couchant | cloche de bronze sous un portique de bois |
| 2 | `watch_post_ruin` | 576 × 336 | Couchant | base effondrée d'une tour de guet de pierre, escalier tronqué |
| 2 | `ruined_wall` | 384 × 192 | Couchant | pan de mur de pierre effondré |
| 2 | `signal_pillar` | 77 × 336 | Couchant | pilier de pierre portant une cage de lanterne vide |
| 2 | `garde_pennant` | 96 × 336 | Couchant | mât et fanion rouge de la Garde (#AE4A3E) qui claque au vent |
| 2 | `wind_rock_a` | 288 × 192 | Couchant | rocher clair sculpté par le vent, creusé à la base |
| 2 | `wind_rock_b` | 192 × 144 | Couchant | rocher sculpté par le vent, plus petit |
| 2 | `wind_rock_c` | 115 × 96 | Couchant | petit rocher sculpté par le vent |
| 2 | `edge_parapet` | 192 × 58 | Couchant, colline | parapet bas de pierre ébréché |
| 3 | `fallen_lantern` | 96 × 48 | Couchant | vieille lanterne de signal tombée, mécanisme apparent |
| 3 | `grass_tuft` | 58 × 38 | Couchant | touffe d'herbe dure couchée vers la droite |
| 3 | `ring_stone` | 58 × 20 | Couchant | pierre sombre et plate de l'anneau du cercle de veille (20 cm de haut : rien ne dépasse 0,3 m dans le cercle) |
| 2 | `signpost` | 115 × 230 | port | panneau usé par le vent, deux flèches rouges, sans texte |
| 2 | `market_stall` | 240 × 230 | port | étal sous bâche beige, paniers d'œufs et d'épices |
| 2 | `market_stall_veg` | 240 × 230 | port | étal sous bâche beige, légumes |
| 2 | `snack_stall` | 192 × 230 | port | échoppe du snack : comptoir, brasero, frites |
| 2 | `cargo_crane` | 288 × 576 | port | grue de chargement à treuil, fer et bois |
| 2 | `crates_barrels` | 192 × 144 | port | pile de caisses et de tonneaux |
| 2 | `scrap_pile` | 192 × 96 | port | tas de ferraille, engrenages, tuyaux |
| 2 | `mooring_arm` | 192 × 384 | port | bras d'ancrage articulé de fer et de cuivre |
| 2 | `gangway` | 192 × 115 | port | passerelle d'embarquement de planches et de fer vue de face, garde-corps |
| 2 | `edge_railing` | 192 × 106 | port | module de garde-corps de fer riveté |
| 3 | `bollard` | 38 × 58 | port | bitte d'amarrage de fer |
| 3 | `wind_sock` | 115 × 384 | port | manche à air rayée sur mât |
| 3 | `rock` | 144 × 96 | partout | rocher gris clair |
| 2 | `lone_tree` | 384 × 480 | colline | arbre noueux solitaire, feuillage clairsemé |
| 1 | `lookout` | 384 × 384 | colline | vieux belvédère de bois patiné, plancher et rambarde, toit pointu |
| 3 | `tall_grass` | 96 × 77 | colline | touffe d'herbe haute dorée |

Décor lointain (48 px/m) :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 3 | `airship_ferry` | 576 × 336 | petit dirigeable du passeur : coque de bois et de cuivre, ballon allongé beige, deux rotors |
| 3 | `airship_barocupot` | 1056 × 480 | Barocupot, transport militaire de la Garde ailée : coque sombre, deux pales de rotor, trappe |

## 8. Ciel, mer de nuages et horizon

`assets/hd2d/sky/` :

| Prio | Fichier | Taille | Description à coller |
| --- | --- | --- | --- |
| 2 | `sky.png` | 2048 × 1024 | panorama équirectangulaire (360° × 180°, horizon à mi-hauteur, raccord gauche-droite) : ciel de fin d'après-midi d'automne, violet en haut (#6E5C86), pêche et or à l'horizon (#EBA676), gros soleil orange bas à l'ouest (quart gauche), quelques nuages en pixel art ; sous l'horizon, la mer de nuages |
| 2 | `cloud_sea.png` | 1024 × 1024 | mer de nuages vue de dessus, sans raccord sur les quatre bords : crêtes pêche (#F4DCC6), creux lavande (#BBA3BF), profondeurs (#82769C), quelques trouées très sombres |
| 3 | `distant_island_a.png` | 768 × 384 | île flottante lointaine en silhouette violacée : dalle boisée, dessous en cône de roche ; fond transparent |
| 3 | `distant_island_b.png` | 768 × 384 | autre île lointaine, plus plate, avec un village ; fond transparent |
| 3 | `distant_island_c.png` | 768 × 384 | petite île lointaine rocheuse ; fond transparent |

Les îles lointaines sont **seules dans l'image** : ni îlot fantôme pâle ni nuage détaché autour
(la livraison les a ajoutés en silhouettes lavande, effacées depuis) ; les petits rochers qui
flottent juste sous l'île sont permis.
| 3 | `floating_rock.png` | 192 × 192 | petit rocher flottant détaché, racines ; fond transparent |

## 9. Petites images

- **Icônes d'objets** : `assets/items/<id>.png`, **64 × 64**, fond transparent, objet centré,
  contour de 1 px (liste des objets : HISTOIRE.md, section 6) ; le nom du fichier est l'id de
  l'objet dans `data/items/` (`wild_berries`, `clock_gear`, `laundry_sheet`… : les livraisons
  ont repris les noms d'une ancienne liste, `berries`, `gear`, `cloth`).
- **Portraits** : 256 × 256 (3.1).
- **Effets** (`assets/hd2d/fx/`, générés par le jeu, facultatifs) : `shadow.png` (ombre douce,
  128 × 64), `glow.png` (halo de lumière chaude, 128 × 128), `light_pool.png` (flaque de lumière au
  sol, 256 × 256).

## 10. Où déposer, comment remplacer

1. Dépose l'image au chemin exact de ce document : elle écrase le remplaçant du même nom (les
   fichiers `.import` ne changent pas).
2. `python3 tools/hd2d_assets.py check` : taille, alpha, raccord des tuiles (planches de
   personnages : `python3 tools/hd2d_sheets.py check`, section 3) ;
   `python3 tools/hd2d_assets.py fit <fichier>` ramène une image trop grande à sa taille ; après
   une tuile de sol, `python3 tools/hd2d_assets.py atlas` (le jeu lit les douze tuiles réunies
   dans `assets/hd2d/ground/atlas/ground_atlas.png` ; `fit` et `gen` le refont d'eux-mêmes).
3. `tools/screenshot.sh res://src/world/island.tscn build/shots/hd2d.png` pour voir le résultat,
   puis `tools/check.sh`.
4. Note la provenance dans `assets/CREDITS.md` (« généré avec ChatGPT le … », licence accordée).

Les remplaçants se régénèrent par `python3 tools/hd2d_assets.py gen` (seulement les fichiers
absents ; `--force` pour tout refaire) ; la liste exacte des fichiers et de leurs tailles est
dans `tools/hd2d_manifest.json`, que les tests confrontent à ce document.

## 11. Ordre de commande pour l'acte 1

1. **Priorité 1** : la planche de Chtholly de l'acte 1, le corps de Timere ; les tuiles `grass`,
   `path_dirt`, `flagstone`, `forest_floor` ; les façades et matières de l'entrepôt
   (`warehouse_main`, `warehouse_porch`, `warehouse_wing`, `armory_door`, `wall_planks`,
   `roof_slate`) ; les décors de la cour (`well`, `palisade`, `palisade_gate`, `crystal_lamp`,
   `climbing_tree`, les trois `tree_autumn*`, `bush`, `tree_old_pine`, `vigil_bell`, `lookout`).
2. **Priorité 2** : les PNJ principaux (Willem, Nygglatho, Ithea, Nephren, Tiat, Pannibal,
   Limeskin) ; les autres tuiles, les falaises ; les façades du port ; les décors des bois, du
   Couchant et du port ; le ciel et la mer de nuages.
3. **Priorité 3** : les gens du bourg et les petites fées ; les petits décors ; l'horizon.
4. **Priorité 4** : les skins de Nopht et de Rhantolk ; les fées de la communauté.
