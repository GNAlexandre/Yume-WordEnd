# Cahier des charges n° 2 : un monde plus riche

Ce document se donne tel quel à ChatGPT (ou à Codex). Il **complète** le cahier n° 1
(`docs/ASSETS_HD2D.md`) : mêmes chemins, même échelle, même rendu. Les images déjà livrées
restent toutes ; celles qui sont listées ici **s'ajoutent** pour que l'île soit plus réaliste,
plus variée et plus belle, et les dirigeables sont **entièrement refaits** (section 11). Les
retouches de personnages restent dans le cahier n° 1, section 12.

## 0. Pourquoi ce cahier

Les images livrées sont bonnes une à une, mais le monde paraît vide et répétitif. Captures du
jeu actuel, à joindre à la conversation pour montrer le cadrage : `docs/img/monde_actuel_cour.jpg`,
`monde_actuel_bourg.jpg`, `monde_actuel_bois.jpg`, `monde_actuel_quai.jpg`.

- **Trop peu d'images par famille** : un seul buisson, un seul rocher, trois feuillus qui sont le
  même arbre recoloré, deux sapins ; la même image revient partout.
- **Le sol est nu** : de grandes surfaces d'une seule tuile répétée, des bords francs entre deux
  matières, rien par terre (ni feuilles, ni cailloux, ni flaques, ni ombre de feuillage).
- **Les bois sont une clairière** : des arbres isolés sur un tapis de feuilles, sans sous-bois,
  sans lisière, sans troncs au premier plan.
- **Les bâtiments n'ont qu'une face** : leurs flancs sont un mur uni, leurs toits une seule
  matière, sans cheminée ni lucarne.
- **Les dirigeables sont invisibles et mal dessinés** : la caméra regarde le nord, ils étaient
  amarrés au sud du quai (hors champ) ; le Barocupot ne se lit pas comme un navire, et le ballon de
  gaz du petit dirigeable ne correspond pas à l'univers (des navires à four enchanté et à
  hélices).
- **Rien ne bouge** : ni linge, ni fanion, ni fumée, ni oiseau.

Objectifs mesurables pour l'intégration :

| But | Valeur |
| --- | --- |
| Variété | chaque famille en 3 à 6 variantes de **forme** différente (silhouette, taille, détail), jamais une simple recoloration |
| Densité | à l'écran (environ 20 m de large autour du joueur) : 40 à 80 éléments dans les bois, 25 à 50 dans la cour et le bourg, 15 à 30 au Couchant et sur la colline ; jamais deux images identiques côte à côte |
| Sol | chaque surface de plus de 4 × 4 m cassée par des décalques (section 5) ; chaque chemin bordé |
| Bâtiments | flancs dessinés, toits habillés (cheminées, lucarnes, mousse), enseignes et objets devant les portes |
| Mouvement | au moins un élément animé par écran (section 12) |
| Profondeur | lisières denses au fond, troncs et fougères flous au premier plan, nuages et dirigeables dans le ciel |

## 1. Bloc de style v2 (à coller au début de chaque conversation)

```text
Tu produis des images pour WordEnd, un jeu d'action-aventure en « HD-2D » à la manière
d'Octopath Traveler : du pixel art posé dans un petit décor en relief, vu par une caméra
inclinée qui regarde le nord. Univers : l'île flottante n° 68 du roman SukaSuka (traduction Yume
Novel), une dalle de pierre au-dessus d'une mer de nuages, couverte d'une forêt d'automne ; un
vieil entrepôt de bois où vivent des fées (des fillettes aux cheveux de couleurs vives), un bourg
d'hommes-bêtes et son petit port à dirigeables, un bord rocheux face au couchant, une colline à
myosotis. Toujours la fin d'un après-midi d'automne.
Style obligatoire :
- pixel art net : 1 pixel de l'image = 1 pixel d'art, aucun flou, aucun anticrénelage vers le
  fond ; aplats et dégradés en paliers, tramage léger permis ; contours de 1 px d'une teinte
  sombre de la couleur voisine (jamais noir pur) ;
- échelle fixe : 96 pixels par mètre (un personnage de 1,5 m mesure 144 px) ;
- modelé marqué, comme dans Octopath Traveler : volumes lisibles, lumière chaude venant de la
  gauche et d'un peu au-dessus (le couchant à l'ouest), reflets dorés sur les arêtes éclairées,
  ombres propres froides (brun violacé), assombrissement au contact (pied des murs, sous les
  toits, creux des feuillages) ; mais aucune ombre portée au sol (le jeu ajoute les ombres) ;
- réalisme : matières crédibles et usées (bois fendu et délavé, pierre ébréchée et moussue,
  métal rouillé aux joints, tissu reprisé), irrégularités naturelles, objets à la bonne taille
  pour un monde à l'échelle humaine ; rien de symétrique au pixel près, rien de neuf ;
- palette naturelle, un peu désaturée, réchauffée par le couchant (or, rouille, mousse, pierre
  claire, bois brun) ; peu de couleurs vives ; ni blanc pur ni noir pur ;
- univers européen rustique (bois patiné, pierre, ardoise, tuiles rouges, cuivre, fer riveté) ;
  rien d'asiatique (ni torii, ni lanterne de papier, ni cerisier), rien de moderne ;
- aucun texte, chiffre, logo ni signature dans l'image ;
- fond transparent (PNG RGBA) pour tout ce qui n'est pas une tuile ; alpha 0 ou 255 seulement,
  sauf pour les images marquées « alpha doux » (fumée, brume, lumière, nuages, ombres) ;
- même rendu que les images de référence jointes ; respecte exactement la taille en pixels et
  le cadrage demandés.
Pour chaque image, je te donnerai : son nom de fichier, sa taille exacte, son cadrage et son sujet.
```

Couleurs de référence : celles du cahier n° 1, section 1 (herbe `#87A35E`, feuillages or
`#CC9446`, rouille `#A95A3A`, sapins `#3D5946`, pierre claire `#C2B49F`, bois `#A57C58` /
`#654D3C`, ardoise `#5E6C86`, tuiles `#B65E4B`, fer `#717B84`, laiton `#B4955E`, cristaux
`#FFE6A6`, fanion de la Garde `#AE4A3E`, myosotis `#7F9CCF`).

## 2. Règles communes

| Règle | Valeur |
| --- | --- |
| Densité | **96 px par mètre** ; lointain (nuages, îles, dirigeables en vol) : 48 ou 24 px/m, précisé à chaque ligne |
| Format | PNG RGBA 8 bits ; tuiles : opaques et sans raccord |
| Taille | exacte au pixel près ; si l'outil ne sait pas la produire, livre plus grand et plus net, puis `python3 tools/hd2d_assets.py fit <fichier>` (réduction au plus proche voisin) |
| Ancre | panneaux, flancs, lisières, bandes animées : milieu du bord bas = point posé au sol (image collée au bord bas, centrée) ; décalques : centre de l'image |
| Angle de vue | panneaux : vue de face très légèrement plongeante (10 à 15°, on devine le dessus des objets) ; tuiles et décalques : **strictement de dessus** ; flancs et façades : élévation sans perspective |
| Orientation | animaux et navires dessinés **tournés vers la droite** (le jeu les retourne) ; le reste vu de face |
| Palette | 64 couleurs au plus par image (128 pour les arbres, les lisières, les bâtiments et les dirigeables ; libre pour le ciel) : les images légères tiennent dans le navigateur |
| Poids | 400 Ko au plus par image ; 1,2 Mo pour les lisières, les grands bâtiments, le ciel et les dirigeables à quai |

**Images de référence à joindre** (même rendu attendu) : `assets/hd2d/props/tree_autumn.png`,
`assets/hd2d/props/bear_rock.png`, `assets/hd2d/buildings/cafe.png`,
`assets/hd2d/ground/forest_floor.png`, `assets/hd2d/props/market_stall.png`, et une capture de
`docs/img/`.

**Familles de variantes** : demande d'abord une **planche** avec toutes les variantes d'une
famille côte à côte, à l'échelle, sur fond uni, puis découpe chaque variante à sa taille. Elles
auront ainsi le même rendu et des formes vraiment différentes.

## 3. Les formats

### 3.1 Panneau (comme au cahier n° 1)

`assets/hd2d/props/<nom>.png` : objet debout vu de face, fond transparent, collé au bord bas et
centré. Le jeu le pose debout face à la caméra, lui ajoute son ombre et sa collision.

### 3.2 Variante

Même famille, autre forme : `<famille>_a.png`, `<famille>_b.png`… Toutes les variantes d'une
famille ont la même taille d'image (sauf mention), mais leur silhouette remplit l'image
différemment (plus haute, plus large, penchée, cassée…).

### 3.3 Décalque au sol (nouveau)

`assets/hd2d/decals/<nom>.png` : ce qui est **posé à plat sur le sol** (feuilles, flaques,
fissures, ombres), vu **strictement de dessus**, fond transparent, à 96 px/m. Le jeu le couche sur
le sol par-dessus les tuiles ; la caméra inclinée l'écrase en perspective, ne le dessine donc pas
en perspective. Bord **irrégulier et effiloché** (jamais un rectangle ni un cercle net) qui se
fond dans n'importe quelle tuile ; pas de fond, pas de tuile sous l'objet. Ancre : le centre.

### 3.4 Bande animée (nouveau)

`assets/hd2d/anim/<nom>.png` : les images d'une animation **côte à côte sur une seule ligne**,
toutes de la même taille (la taille d'**une** image est donnée ; la bande fait `n ×` sa largeur),
sans marge entre elles. Chaque image est cadrée comme un panneau (collée au bas, même ancre) : seul
ce qui bouge change, le reste reste identique au pixel près. La dernière image s'enchaîne sur la
première (boucle sans saut).

### 3.5 Flanc de bâtiment (nouveau)

`assets/hd2d/buildings/<nom>_side.png` : le mur **est** du bâtiment en élévation (sans
perspective), à 96 px/m, fond transparent, mur collé aux bords gauche, droit et bas. Le jeu le
plaque sur le flanc est et, retourné, sur le flanc ouest : **pas de lumière dirigée** dans les
flancs (modelé doux et symétrique), et rien qui ne supporte d'être retourné (pas d'enseigne
lisible, pas de cheminée d'un seul côté). Le côté gauche de l'image est l'angle de la façade sud,
le côté droit l'angle nord. Deux formes selon le toit :

- **pignon** (bâtiment `long` : le faîtage est parallèle à la façade) : l'image va jusqu'au
  faîtage, avec le triangle du pignon et la bordure du toit (fond transparent de part et d'autre
  du triangle) ;
- **mur gouttereau** (bâtiment `pignon` : le faîtage part vers le fond) : l'image s'arrête à
  l'égout du toit, avec la bordure du toit (10 à 20 cm).

### 3.6 Lisière (nouveau)

`assets/hd2d/props/<nom>.png` : un **pan de forêt** de 16 m de large, comme un décor de théâtre :
plusieurs troncs à des profondeurs différentes, feuillages qui se chevauchent, sous-bois sombre
en bas, trouées de lumière ; bas de l'image collé au sol sur toute la largeur (racines, fougères),
**bords gauche et droit qui s'enchaînent** d'une lisière à l'autre (feuillages coupés de façon
à se raccorder à n'importe quelle autre variante). Le jeu les aligne au fond des zones pour
fermer l'horizon.

### 3.7 Premier plan (nouveau)

Panneaux ordinaires (section 3.1), placés entre la caméra et le joueur : le flou de profondeur
du jeu les adoucit. Ils doivent rester lisibles une fois flous : grandes masses sombres et
contrastées, bords découpés, peu de petits détails.

### 3.8 Lointain et ciel

`assets/hd2d/sky/<nom>.png` : nuages, îles, dirigeables en vol, brume. Densité réduite (48 ou
24 px/m), teintes adoucies et un peu violacées par la distance, comme `distant_island_a.png`.

## 4. Sol : nouvelles tuiles et variantes

`assets/hd2d/ground/<nom>.png`, **384 × 384 px = 4 × 4 m**, vue strictement de dessus, opaque,
**sans raccord sur les quatre bords**, sans objet ni ombre portée. Une variante `_b` a la même
matière et les mêmes couleurs que la tuile d'origine, mais un autre dessin (le jeu alterne les
deux pour casser la répétition) : elle doit se raccorder **aussi** avec la tuile d'origine, bord
à bord.

Consigne : « Tuile de sol `<nom>.png`, 384 × 384 px, vue strictement de dessus, sans raccord sur
les quatre bords, pixel art à 96 px/m : » puis :

| Prio | Nom | Description à coller |
| --- | --- | --- |
| 1 | `grass_b` | variante de `grass.png` (jointe) : herbe d'automne rase vert-jaune, autre répartition des touffes claires, des taches sèches et des feuilles mortes ; se raccorde à `grass.png` |
| 1 | `forest_floor_b` | variante de `forest_floor.png` (jointe) : sous-bois, terre sombre, mousse, feuilles rousses et dorées, aiguilles, autre dessin ; se raccorde à `forest_floor.png` |
| 1 | `path_dirt_b` | variante de `path_dirt.png` : terre battue, autres cailloux et traces ; se raccorde à `path_dirt.png` |
| 1 | `leaf_litter` | épais tapis de feuilles mortes d'automne (or, rouille, brun, quelques jaunes), feuilles entières bien lisibles de 5 à 12 cm, un peu de terre visible |
| 1 | `moss` | mousse épaisse vert sombre et vert doré, en coussins, quelques brindilles et feuilles tombées |
| 2 | `grass_dry_b` | variante de `grass_dry.png` : herbe haute dorée couchée par le vent, autre dessin |
| 2 | `flagstone_b` | variante de `flagstone.png` : vieilles dalles grises de tailles différentes, une dalle fendue, herbe dans les joints |
| 2 | `cobble_b` | variante de `cobble.png` : pavés usés, quelques pavés manquants comblés de terre |
| 2 | `meadow_flowers` | herbe d'automne fleurie : trèfle, pâquerettes, petites fleurs jaunes et quelques myosotis (#7F9CCF) en touches de 1 à 3 px |
| 2 | `gravel` | gravier gris-beige tassé, cailloux de 1 à 4 cm, brins d'herbe sur les bords |
| 2 | `garden_soil` | terre de potager brun sombre fraîchement retournée, en mottes, sans sillons |
| 3 | `sand_b` | variante de `sand.png` : sable pâle en rides de vent, autre dessin |
| 3 | `rock_b` | variante de `rock.png` : dalle claire à nu, autres plaques et fissures |
| 3 | `planks` | plancher de planches de bois patinées vues de dessus, larges de 20 à 25 cm, dans le sens vertical de l'image, clous, une planche plus claire |
| 3 | `stream_bed` | eau claire et peu profonde d'un ruisseau sur galets ronds (#4A675F éclairci), reflets clairs en petits traits dans le sens horizontal |

## 5. Décalques au sol

`assets/hd2d/decals/<nom>.png`, vue strictement de dessus, fond transparent, bord irrégulier
(section 3.3). Consigne : « Décalque au sol `<nom>.png`, <taille>, vu strictement de dessus, fond
transparent, bords irréguliers qui se fondent sur n'importe quel sol, pixel art à 96 px/m : »
puis :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `leaves_gold_a` | 288 × 192 (3 × 2 m) | tas de feuilles mortes or (#CC9446) et jaunes, plus dense au centre, feuilles isolées sur le pourtour |
| 1 | `leaves_gold_b` | 192 × 144 | même chose, plus petit, allongé en traînée |
| 1 | `leaves_rust_a` | 288 × 192 | tas de feuilles rouille (#A95A3A) et brunes |
| 1 | `leaves_rust_b` | 192 × 144 | même chose, plus petit, en croissant |
| 1 | `leaves_scatter` | 384 × 288 (4 × 3 m) | feuilles éparses, une tous les 20 à 40 cm, toutes couleurs d'automne, rien au centre |
| 1 | `grass_edge_a` | 384 × 96 (4 × 1 m) | bordure d'herbe qui déborde sur un chemin de terre : touffes et brins qui avancent vers le bas de l'image, bord haut plein ; **sans raccord à gauche et à droite** |
| 1 | `grass_edge_b` | 384 × 96 | même bordure, autre dessin, se raccorde à `grass_edge_a` |
| 1 | `canopy_shadow_a` | 576 × 576 (6 × 6 m) | **alpha doux** : ombre de feuillage vue de dessus, taches sombres brun violacé (opacité 30 à 60 %) avec des trouées rondes de lumière |
| 1 | `canopy_shadow_b` | 576 × 576 | même chose, autre forme, plus clairsemée |
| 1 | `sun_dapple` | 384 × 384 | **alpha doux** : taches de soleil dorées (#FFE6A6, opacité 30 à 50 %), rondes et ovales, de 10 à 60 cm |
| 1 | `roots_a` | 288 × 192 | grosses racines qui sortent du sol et s'y renfoncent, écorce brune, mousse |
| 1 | `roots_b` | 192 × 192 | racines plus fines en étoile |
| 1 | `branches_a` | 192 × 96 | branches mortes et brindilles tombées |
| 1 | `pebbles_a` | 144 × 144 | cailloux gris clair de 2 à 8 cm éparpillés |
| 1 | `garden_bed` | 480 × 288 (5 × 3 m) | potager d'automne vu de dessus : trois rangs de terre sombre, choux, poireaux, deux citrouilles, feuilles fanées, tuteurs couchés |
| 2 | `moss_patch_a` | 192 × 144 | plaque de mousse vert sombre et dorée |
| 2 | `moss_patch_b` | 144 × 96 | même chose, plus petite |
| 2 | `clover_patch` | 192 × 144 | tache de trèfle vert plus frais, quelques fleurs blanches |
| 2 | `flowers_patch_a` | 192 × 144 | petites fleurs sauvages d'automne dans l'herbe (jaunes, blanches, mauves), en touches de 2 à 4 px |
| 2 | `flowers_patch_b` | 144 × 96 | myosotis bleus (#7F9CCF) en tapis |
| 2 | `needles_patch` | 192 × 144 | aiguilles de sapin rousses et petites pommes de pin |
| 2 | `puddle_a` | 192 × 115 | flaque d'eau boueuse, reflets du ciel pêche en petits traits, bord de boue sombre |
| 2 | `puddle_b` | 134 × 96 | petite flaque |
| 2 | `mud_patch` | 192 × 144 | boue piétinée, empreintes de petits pieds |
| 2 | `cracks_a` | 192 × 192 | fissures sombres dans la pierre ou la terre sèche, ramifiées, herbe dans les plus larges |
| 2 | `cracks_b` | 144 × 96 | fissure courte |
| 2 | `pebbles_b` | 192 × 96 | traînée de gravier et de petits cailloux |
| 2 | `branches_b` | 288 × 115 | grosse branche tombée avec ses rameaux et quelques feuilles |
| 2 | `stepping_stones` | 288 × 192 | quatre pierres plates qui traversent un ruisseau, eau claire autour (bord transparent) |
| 2 | `lily_pads` | 192 × 144 | lentilles d'eau et petites feuilles de nénuphar sur eau sombre, bord transparent |
| 2 | `sand_drift_a` | 288 × 192 | **alpha doux** sur les bords : congère de sable pâle (#D6C19E) poussée par le vent sur la pierre, rides allongées vers la droite |
| 2 | `sand_drift_b` | 192 × 115 | plus petite |
| 2 | `ring_stone_flat_a` | 96 × 77 | pierre sombre plate enfoncée au ras du sol (l'anneau du cercle de veille), usée, lichen clair |
| 2 | `ring_stone_flat_b` | 115 × 67 | même chose, autre forme |
| 2 | `ring_stone_flat_c` | 77 × 77 | même chose, presque ronde |
| 2 | `chalk_drawings` | 192 × 192 | dessins de craie d'enfants sur la terre battue : soleil, fleur, petite fée ailée, sans lettre ni chiffre |
| 2 | `chalk_hopscotch` | 192 × 384 | marelle tracée à la craie, cases vides **sans chiffres**, un caillou dans une case |
| 2 | `oil_stain` | 144 × 96 | tache d'huile sombre irisée sur la tôle |
| 2 | `rust_streak` | 192 × 96 | coulure de rouille autour d'un joint de tôle |
| 2 | `footprints` | 96 × 288 | trace de pas de petites bottes qui monte vers le haut de l'image, dans la terre |
| 3 | `cart_ruts` | 192 × 384 | deux ornières parallèles de charrette dans la terre, **sans raccord en haut et en bas** |
| 3 | `drain_grate` | 96 × 96 | grille d'égout de fer rouillé entre des pavés |
| 3 | `hay_scatter` | 144 × 96 | foin éparpillé |
| 3 | `boardwalk` | 96 × 384 (1 × 4 m) | caillebotis de planches sur le marais, vu de dessus, planches transversales, **sans raccord en haut et en bas** |
| 3 | `mist_patch` | 384 × 192 | **alpha doux** : brume basse blanche rosée (opacité 20 à 40 %) en nappe effilochée, pour le marais |

## 6. Arbres et lisières

Panneaux (section 3.1). Pour chaque espèce, une planche de toutes ses variantes d'abord
(section 2). Consigne : « Arbre `<nom>.png`, <taille>, debout vu de face, fond transparent, collé
au bord bas et centré, pixel art à 96 px/m : » puis :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `oak_a` | 576 × 768 (6 × 8 m) | grand chêne d'automne : tronc massif et court, branches tortueuses, houppier large et irrégulier en grosses masses de feuilles or et brunes, quelques trouées par où passe le ciel |
| 1 | `oak_b` | 576 × 768 | chêne penché vers la gauche, une grosse branche basse horizontale |
| 1 | `oak_c` | 576 × 768 | vieux chêne au tronc creux, feuillage plus clairsemé et roux |
| 1 | `beech_a` | 480 × 864 (5 × 9 m) | hêtre élancé : tronc lisse gris argenté, houppier haut et ovale, feuilles cuivrées et orangées |
| 1 | `beech_b` | 480 × 864 | hêtre à deux troncs jumeaux, feuillage cuivre et or |
| 1 | `maple_a` | 480 × 672 (5 × 7 m) | érable : houppier rond, feuilles rouge vif et rouille, tronc brun |
| 1 | `maple_b` | 480 × 672 | érable plus jeune, feuillage moitié rouge moitié or |
| 1 | `birch_a` | 288 × 720 (3 × 7,5 m) | bouleau : tronc blanc tacheté de noir, fin et un peu courbé, feuillage jaune vif léger et clairsemé |
| 1 | `birch_b` | 288 × 720 | groupe de deux bouleaux minces qui s'écartent |
| 1 | `pine_small_a` | 192 × 432 (2 × 4,5 m) | jeune sapin sombre (#3D5946) dense et pointu |
| 1 | `pine_small_b` | 192 × 432 | jeune sapin un peu tordu, branches basses inégales |
| 1 | `forest_wall_a` | 1536 × 1056 (16 × 11 m) | **lisière** (section 3.6) : forêt d'automne dense vue de face, chênes, hêtres et sapins mêlés à trois profondeurs, feuillages or, rouille et vert sombre qui se chevauchent, troncs dans la pénombre, sous-bois sombre de fougères en bas, deux ou trois rais de lumière dorée ; bords gauche et droit raccordables |
| 1 | `forest_wall_b` | 1536 × 1056 | lisière plus sombre, dominée par les sapins, quelques feuillus rouille |
| 1 | `forest_wall_c` | 1536 × 1056 | lisière plus claire, bouleaux et hêtres dorés, une trouée au milieu |
| 2 | `oak_d` | 576 × 768 | chêne foudroyé : moitié du houppier morte et nue, l'autre moitié dorée |
| 2 | `beech_c` | 480 × 864 | hêtre dont le tronc porte des polypores et du lierre |
| 2 | `maple_c` | 480 × 672 | érable au feuillage presque tombé, branches visibles, tapis rouge à son pied compris dans l'image (5 cm de haut au plus) |
| 2 | `pine_tall_b` | 384 × 1056 (4 × 11 m) | très grand sapin plus étroit que `tree_old_pine`, tronc nu sur 3 m, étages sombres irréguliers |
| 2 | `pine_dead` | 240 × 672 (2,5 × 7 m) | sapin mort gris argenté, branches cassées, lichen |
| 2 | `dead_tree_a` | 384 × 480 (4 × 5 m) | arbre mort tordu par le vent, branches nues vers la droite (vent d'ouest), écorce claire (Couchant) |
| 2 | `dead_tree_b` | 288 × 384 | arbre mort plus petit, cassé à mi-hauteur |
| 2 | `sapling_a` | 144 × 240 (1,5 × 2,5 m) | jeune feuillu frêle, quelques feuilles or, tuteur de bois |
| 2 | `sapling_b` | 115 × 211 | jeune érable rouge sans tuteur |
| 2 | `treeline_autumn_a` | 1536 × 768 (16 × 8 m) | **lisière** basse pour le pourtour de la cour et du bourg : rangée de feuillus or et rouille et de quelques sapins, plus aérée que `forest_wall_*`, ciel visible entre les cimes ; bords raccordables |
| 2 | `treeline_autumn_b` | 1536 × 768 | même chose, dominante rouille et jaune |
| 2 | `forest_wall_d` | 1536 × 1056 | lisière du marais : saules et aulnes penchés, roseaux et brume en bas |
| 2 | `willow` | 576 × 672 (6 × 7 m) | saule du marais, branches retombantes jaune-vert, tronc noueux penché |
| 3 | `lone_tree_b` | 384 × 480 | arbre noueux solitaire de la colline, autre silhouette que `lone_tree.png`, couché par le vent vers la droite |

## 7. Arbustes, herbes, fleurs, champignons

Panneaux. Consigne : « Plante `<nom>.png`, <taille>, debout vue de face, fond transparent, collée
au bord bas et centrée, pixel art à 96 px/m : » puis :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `bush_b` | 154 × 115 | buisson de noisetier, feuilles jaunes et vertes |
| 1 | `bush_c` | 125 × 96 | buisson rond de feuillage rouille, quelques branches nues |
| 1 | `bush_d` | 173 × 106 | buisson large et bas de ronces, mûres noires, feuilles rouges |
| 1 | `bush_e` | 106 × 96 | petit genévrier vert sombre |
| 1 | `fern_a` | 144 × 106 | grande fougère rousse d'automne, frondes arquées |
| 1 | `fern_b` | 115 × 86 | fougère moitié verte moitié rousse |
| 1 | `fern_c` | 96 × 67 | petite fougère verte |
| 1 | `grass_clump_a` | 96 × 77 | touffe d'herbe sauvage vert-jaune, quelques épis |
| 1 | `grass_clump_b` | 77 × 58 | touffe plus petite, brins secs dorés |
| 1 | `grass_clump_c` | 115 × 86 | touffe large et haute, épis qui retombent |
| 2 | `bush_f` | 144 × 125 | églantier : baies rouges (cynorhodons), feuillage orangé |
| 2 | `fern_d` | 192 × 134 | fougère géante du sous-bois, très sombre |
| 2 | `grass_clump_d` | 58 × 48 | petite touffe d'herbe dure |
| 2 | `wildflowers_a` | 77 × 48 | bouquet de fleurs sauvages jaunes (verge d'or) |
| 2 | `wildflowers_b` | 77 × 38 | asters mauves |
| 2 | `heather` | 115 × 48 | coussin de bruyère mauve et rousse |
| 2 | `myosotis_b` | 77 × 48 | massif de myosotis bleus plus étalé que `myosotis.png` |
| 2 | `myosotis_c` | 48 × 38 | petite touffe de myosotis |
| 2 | `cattails` | 96 × 154 | massettes du marais (quenouilles brunes) et feuilles longues |
| 2 | `reeds_b` | 115 × 125 | touffe de roseaux pâles plus clairsemée que `reeds.png` |
| 2 | `mushroom_cep` | 48 × 38 | trois cèpes bruns |
| 2 | `mushroom_chanterelle` | 58 × 29 | petit groupe de girolles orangées |
| 2 | `ivy_ground` | 144 × 58 | lierre rampant sur une souche basse |
| 3 | `nettles` | 96 × 77 | touffe d'orties |
| 3 | `thistle` | 58 × 86 | chardon sec |
| 3 | `berry_bush_b` | 125 × 96 | buisson à baies bleues (myrtilles) |

**Premier plan** (section 3.7) :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `fg_trunk_a` | 192 × 960 (2 × 10 m) | énorme tronc de chêne au premier plan, écorce profonde sombre, lierre, départ de branche en haut ; masses très sombres et contrastées |
| 1 | `fg_trunk_b` | 144 × 960 | tronc de sapin au premier plan, écorce rouge-brun |
| 1 | `fg_fern` | 288 × 192 | grosse touffe de fougères sombres, frondes larges découpées |
| 2 | `fg_grass` | 288 × 144 | herbes hautes et épis sombres à contre-jour |
| 2 | `fg_bush` | 288 × 192 | buisson sombre au feuillage rouille, grandes feuilles |

## 8. Rochers et bords de l'île

Panneaux, sauf mention. Consigne : « Rocher `<nom>.png`, <taille>, debout vu de face, fond
transparent, collé au bord bas et centré, pixel art à 96 px/m : » puis :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `boulder_a` | 288 × 192 (3 × 2 m) | bloc de pierre claire de l'île (#C2B49F), arêtes émoussées, lichen et mousse sur le dessus |
| 1 | `boulder_b` | 240 × 211 | bloc plus haut, fendu en deux, fougère dans la fente |
| 1 | `boulder_c` | 336 × 154 | dalle couchée et inclinée, à demi enterrée |
| 1 | `rock_small_a` | 58 × 38 | caillou clair |
| 1 | `rock_small_b` | 77 × 48 | deux cailloux |
| 1 | `rock_small_c` | 48 × 29 | caillou plat moussu |
| 1 | `edge_rocks_a` | 384 × 154 (4 × 1,6 m) | bord de l'île vu de face : pierres cassées, touffes d'herbe et racines qui dépassent de la lèvre ; bas de l'image = niveau du sol |
| 1 | `edge_rocks_b` | 384 × 115 | même chose, plus bas, avec une fissure |
| 2 | `boulder_d` | 384 × 288 | gros rocher moussu couvert de fougères et de lierre (sous-bois) |
| 2 | `rock_small_d` | 67 × 48 | caillou anguleux sombre |
| 2 | `rock_pile` | 192 × 96 | tas de pierres ramassées au bord d'un champ |
| 2 | `edge_roots` | 288 × 192 | racines d'un arbre qui débordent de la lèvre et pendent dans le vide, terre et cailloux |
| 2 | `edge_grass` | 384 × 96 | herbe haute couchée qui déborde de la lèvre, **sans raccord à gauche et à droite** |
| 2 | `wind_rock_d` | 240 × 154 | rocher clair sculpté par le vent, creusé de trous ronds, plus trapu que `wind_rock_a` |
| 3 | `floating_rock_b` | 144 × 144 | (dossier `sky/`) petit rocher flottant sous le bord, racines qui pendent, brin d'herbe dessus |
| 3 | `floating_rock_c` | 240 × 240 | (dossier `sky/`) rocher flottant plus grand, un petit arbre dessus |

## 9. Bâtiments

### 9.1 Flancs des bâtiments existants

`assets/hd2d/buildings/<nom>_side.png` (section 3.5), dans la matière et le style de la façade
livrée (à joindre à la conversation). Consigne : « Flanc est du bâtiment `<nom>` (façade sud
jointe), `<nom>_side.png`, <taille>, élévation sans perspective, fond transparent, mur collé aux
bords gauche, droit et bas, modelé doux et symétrique, pixel art à 96 px/m : » puis :

| Prio | Nom | Taille (px) | Forme | Description à coller |
| --- | --- | --- | --- | --- |
| 1 | `warehouse_main_side` | 768 × 864 (8 × 9 m) | pignon | pignon est de l'entrepôt des fées : bardage de planches brun foncé rapiécé, soubassement de pierre, deux étages de petites fenêtres à croisillons éclairées, une lucarne ronde dans le triangle, échelle de bois contre le mur |
| 1 | `warehouse_wing_side` | 864 × 336 (9 × 3,5 m) | gouttereau | mur est de l'aile ouest : planches brun foncé, soubassement de pierre, grande fenêtre du réfectoire éclairée, porte basse de l'infirmerie au bout gauche |
| 1 | `cafe_side` | 576 × 720 (6 × 7,5 m) | pignon | pignon du café : pierre en bas, colombages crème en haut, une fenêtre par étage avec jardinière, petite fenêtre dans le triangle |
| 1 | `shop_bakery_side` | 480 × 384 (5 × 4 m) | gouttereau | mur de pierre de la boulangerie, une fenêtre à volets, soupirail du four, tas de bûches contre le mur |
| 1 | `shop_bookshop_side` | 480 × 384 | gouttereau | mur d'enduit vert sombre écaillé de la librairie, une fenêtre haute, lierre |
| 1 | `stone_house_side` | 432 × 312 (4,5 × 3,25 m) | gouttereau | mur de moellons, une petite fenêtre, banc de pierre contre le mur |
| 2 | `projection_hall_side` | 672 × 720 (7 × 7,5 m) | pignon | pignon de pierre haute de la salle de projection, volets clos, porte de service, affiches déchirées sans texte |
| 2 | `limashenka_house_side` | 480 × 360 (5 × 3,75 m) | gouttereau | mur crème de la vieille maison, fenêtre aux volets clos, lierre épais |
| 2 | `tool_shed_side` | 240 × 250 (2,5 × 2,6 m) | pignon | pignon de planches de la remise, outils pendus au mur |

### 9.2 Nouveaux bâtiments du bourg et du port

Façade (`<nom>.png`, consigne de la section 6.1 du cahier n° 1) **et** flanc (`<nom>_side.png`,
section 3.5) ; les matières du volume sont celles de la colonne (existantes ou section 9.3). Type
`long` : façade jusqu'à l'égout, flanc en pignon ; type `pignon` : façade jusqu'au faîtage, flanc
gouttereau. Le bourg est celui d'hommes-bêtes ordinaires : portes un peu plus larges, rien de
luxueux. Les noms de commerces restent sans texte (enseignes en forme d'objet).

| Prio | Nom | Façade (px) | Flanc (px) | Type, mur / faîte (m), profondeur | Matières | Description à coller |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `house_timber_a` | 480 × 576 | 432 × 336 | pignon, 3,5 / 6 ; prof. 4,5 | `wall_plaster`, `roof_tiles` | maison à colombages bruns sur enduit crème, rez-de-chaussée de pierre, porte bleu passé, deux fenêtres à volets, encorbellement de l'étage |
| 1 | `house_timber_b` | 672 × 528 | 480 × 720 | long, 5,5 / 7,5 ; prof. 5 | `wall_plaster_b`, `roof_tiles_b` | longue maison à étage, enduit ocre et colombages, trois fenêtres à l'étage, porte et fenêtre de boutique fermée en bas, linge à une fenêtre |
| 1 | `clockmaker` | 480 × 624 | 480 × 384 | pignon, 4 / 6,5 ; prof. 5 | `wall_stone`, `roof_slate` | boutique de l'horloger : pierre grise, vitrine pleine d'horloges et d'engrenages de laiton, enseigne en forme d'horloge **sans chiffres ni aiguilles lisibles comme une heure**, porte vitrée |
| 1 | `house_narrow` | 384 × 768 | 480 × 576 | pignon, 6 / 8 ; prof. 5 | `wall_stone_b`, `roof_slate` | haute maison étroite de pierre à trois niveaux, une fenêtre par niveau, balconnet de fer, fleurs en pots |
| 2 | `butcher` | 576 × 336 | 480 × 528 | long, 3,5 / 5,5 ; prof. 5 | `wall_brick`, `roof_tiles` | boucherie de briques à un niveau, auvent de toile rayée rouge et crème, étal fermé, enseigne en forme de jambon |
| 2 | `inn` | 864 × 576 | 672 × 816 | long, 6 / 8,5 ; prof. 7 | `wall_plaster`, `roof_shingles` | auberge du port à deux étages, colombages, balcon de bois à l'étage, grande porte à deux battants, enseigne en forme de chope, lanternes de cristal de part et d'autre |
| 2 | `harbor_office` | 480 × 576 | 480 × 384 | pignon, 4 / 6 ; prof. 5 | `wall_stone`, `roof_tin` | bureau du port : pierre et tôle, guichet à grille, horloge murale sans chiffres, girouette en forme d'hélice sur le faîtage |
| 2 | `port_hangar` | 960 × 480 | 768 × 672 | long, 5 / 7 ; prof. 8 | `wall_tin`, `roof_tin_b` | hangar du port en tôle ondulée et charpente de fer, grande porte coulissante entrouverte sur la pénombre, caisses dedans, traces de rouille |
| 3 | `boiler_workshop` | 576 × 624 | 576 × 384 | pignon, 4 / 6,5 ; prof. 6 | `wall_brick`, `roof_tin` | atelier de chaudronnerie : briques noircies, grande porte de fer, un four enchanté démonté devant la porte (cuivre et rivets), tuyaux, lueur orange par une fenêtre |
| 3 | `house_stone_b` | 480 × 480 | 432 × 312 | pignon, 3,25 / 5 ; prof. 4,5 | `wall_stone_b`, `roof_shingles` | petite maison de pierre claire au toit de bardeaux, porte rouge passé, banc |

### 9.3 Nouvelles matières

`assets/hd2d/buildings/materials/<nom>.png`, **192 × 192 px = 2 × 2 m**, opaques, sans raccord
sur les quatre bords (consigne de la section 6.2 du cahier n° 1) :

| Prio | Nom | Description à coller |
| --- | --- | --- |
| 1 | `roof_tiles_b` | tuiles rouges plus sombres et moussues, quelques tuiles cassées ou remplacées |
| 1 | `roof_slate_b` | ardoises bleu-gris plus claires, lichen jaune |
| 1 | `wall_plaster_b` | enduit ocre jaune un peu sali, sans colombages |
| 1 | `wall_stone_b` | moellons clairs irréguliers, joints creusés |
| 2 | `wall_brick` | briques rouge-brun usées, quelques briques plus sombres |
| 2 | `roof_shingles` | bardeaux de bois gris-brun en rangées, mousse |
| 2 | `wall_tin` | tôle ondulée grise verticale, rouille aux recouvrements |
| 2 | `roof_tin_b` | tôle ondulée rouillée, plaques rapiécées |
| 3 | `wall_planks_b` | planches horizontales grises délavées (cabanes du port) |
| 3 | `wall_plaster_c` | enduit rose pâle écaillé, pierre visible par endroits |

### 9.4 Détails de toits et de murs

Panneaux posés contre un mur ou sur un toit. Consigne de la section 7 du cahier n° 1 :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `chimney_brick` | 96 × 192 (1 × 2 m) | cheminée de briques sur un pan de toit, chapeau de tôle, suie |
| 1 | `chimney_stone` | 96 × 173 | cheminée de pierre, pots de terre cuite |
| 1 | `dormer_slate` | 154 × 154 | lucarne à toit d'ardoise, fenêtre éclairée, vue de face |
| 1 | `dormer_tiles` | 154 × 154 | lucarne à toit de tuiles, volets ouverts |
| 1 | `ivy_wall_a` | 192 × 288 | **alpha 0/255** : lierre grimpant plaqué contre un mur, feuilles vertes et rouges, sans mur derrière |
| 1 | `ivy_wall_b` | 288 × 192 | lierre qui court sous un toit et retombe |
| 2 | `warehouse_roof_deck` | 576 × 154 (6 × 1,6 m) | terrasse à linge sur le toit de l'entrepôt : rambarde de fer basse, deux cordes, trois draps |
| 2 | `wall_lantern` | 48 × 77 | applique de fer à cristal lumineux (#FFE6A6) |
| 2 | `window_box` | 115 × 48 | jardinière de fleurs d'automne sous une fenêtre |
| 2 | `hanging_sign_key` | 96 × 115 | enseigne de fer pendue à une potence, en forme de clé (serrurier) |
| 2 | `hanging_sign_propeller` | 96 × 115 | enseigne en forme d'hélice (port) |
| 2 | `drainpipe` | 29 × 384 | gouttière et descente de cuivre vert-de-grisé, coude en bas |
| 3 | `outdoor_stairs` | 192 × 288 | escalier de bois extérieur qui monte vers une porte d'étage, rampe |
| 3 | `awning_green` | 288 × 96 | auvent de toile verte délavée à festons |

## 10. Objets de la vie, par zone

Panneaux. Consigne de la section 7 du cahier n° 1. Ce sont eux qui font croire au lieu : ce que les
fées, les marchands et les dockers laissent traîner.

### 10.1 La cour de l'entrepôt (`village`)

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `wheelbarrow` | 154 × 86 | brouette de bois chargée de feuilles mortes |
| 1 | `firewood_pile` | 240 × 192 | bûches empilées sous un petit auvent de planches |
| 1 | `stump_axe` | 115 × 96 | billot de bois, hache plantée dedans, copeaux |
| 1 | `rain_barrel` | 77 × 106 | tonneau à eau de pluie cerclé de fer, louche |
| 1 | `laundry_basket` | 86 × 58 | panier d'osier plein de draps et de pinces |
| 1 | `toys_a` | 96 × 58 | jouets d'enfants : deux épées de bois, un cerceau |
| 1 | `toys_b` | 77 × 58 | poupée de chiffon assise contre un seau renversé |
| 1 | `bench_b` | 154 × 106 | banc à dossier de bois sculpté, coussin rapiécé |
| 1 | `fence_low` | 192 × 77 | clôture basse de piquets du potager (module de 2 m), **sans raccord à gauche et à droite** |
| 2 | `bucket` | 38 × 38 | seau de bois cerclé |
| 2 | `watering_can` | 48 × 38 | arrosoir de cuivre cabossé |
| 2 | `garden_tools` | 77 × 154 | râteau, fourche et pelle appuyés ensemble |
| 2 | `scarecrow` | 115 × 192 | épouvantail du potager : vieux manteau, chapeau de paille, écharpe rouge |
| 2 | `kids_table` | 192 × 96 | petite table de bois et trois tabourets d'enfant, tasses |
| 2 | `flower_pots` | 115 × 58 | pots de terre cuite fleuris et un pot cassé |
| 2 | `crate_stack` | 115 × 125 | deux caisses empilées et un sac |
| 3 | `bench_stone` | 134 × 58 | banc de pierre moussu |
| 3 | `sack_apples` | 67 × 58 | sac de toile ouvert, pommes rouges qui roulent |

### 10.2 Le bourg et le marché (`beach`, nord)

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `cafe_table` | 134 × 96 | table ronde de bistrot en fer et bois, deux chaises, deux tasses |
| 1 | `barrel_group` | 154 × 106 | trois tonneaux de bois, l'un ouvert plein de pommes |
| 1 | `sacks_pile` | 134 × 77 | sacs de farine et de grain empilés |
| 1 | `hand_cart` | 240 × 134 | charrette à bras chargée de caisses et de légumes, brancards posés au sol |
| 1 | `fountain` | 288 × 240 | fontaine de pierre ronde du marché, bec de cuivre, eau qui tombe dans le bassin |
| 1 | `notice_board` | 154 × 192 | panneau d'affichage de bois sous un petit toit, affiches et papiers punaisés **sans texte lisible** (lignes grises) |
| 1 | `market_stall_fruit` | 240 × 230 | étal sous bâche verte délavée : pommes, poires, courges, paniers |
| 1 | `market_stall_cloth` | 240 × 230 | étal sous bâche bordeaux : rouleaux de tissu, écharpes pendues |
| 2 | `bread_rack` | 134 × 115 | présentoir de pains devant la boulangerie, miches et baguettes |
| 2 | `book_cart` | 134 × 96 | bac de livres d'occasion sur tréteaux devant la librairie |
| 2 | `menu_slate` | 58 × 106 | ardoise sur chevalet, dessin de tasse fumante, **sans texte** |
| 2 | `street_lamp_double` | 115 × 288 | lampadaire de fer à deux cristaux lumineux |
| 2 | `planter_long` | 154 × 77 | longue jardinière de bois, fleurs et herbes |
| 2 | `bunting` | 576 × 96 | guirlande de petits fanions de tissu (rouge, crème, vert) tendue entre deux crochets (aucun mât dans l'image) |
| 3 | `crate_apples` | 96 × 67 | cageot de pommes |
| 3 | `broom_bucket` | 58 × 134 | balai de paille et seau appuyés |

### 10.3 Le port (`beach`, sud)

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `mooring_tower` | 288 × 576 (3 × 6 m) | triple bras d'ancrage du Barocupot : pylône de fer riveté, trois bras articulés de fer et de cuivre repliés, câbles, échelle |
| 1 | `cargo_net` | 192 × 154 | filet de chargement plein de caisses et de sacs, crochet de grue au-dessus |
| 1 | `crystal_crates` | 154 × 115 | caisses à claire-voie pleines de cristaux lumineux jaune pâle (#FFE6A6) qui brillent entre les planches |
| 1 | `fuel_barrels` | 134 × 106 | tonneaux cerclés de fer à huile de four, taches sombres |
| 1 | `rope_coil` | 96 × 48 | gros cordage enroulé sur le quai |
| 1 | `steam_pipes` | 192 × 192 | tuyaux de cuivre qui sortent de la tôle du quai, vanne à volant, manomètre sans chiffres |
| 2 | `workbench` | 192 × 115 | établi de mécanicien : étau, clés, engrenages, chiffons |
| 2 | `luggage` | 115 × 77 | malles et valises de voyageurs empilées, sangles |
| 2 | `ticket_booth` | 192 × 240 | guichet des lignes de dirigeables, petite cabine de bois et de verre, **sans texte** |
| 2 | `dock_lamp` | 77 × 336 | lampadaire du quai : mât de fer, cristal lumineux dans une cage, crochet |
| 2 | `pallet_sacks` | 154 × 96 | palette de bois chargée de sacs de toile |
| 2 | `chain_pile` | 96 × 48 | tas de grosses chaînes rouillées |
| 3 | `tool_rack` | 115 × 154 | râtelier de grosses clés et de palans |
| 3 | `propeller_spare` | 192 × 192 | hélice de rechange à quatre pales appuyée contre des caisses |

### 10.4 Le bord du Couchant (`dunes`)

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `ruined_wall_b` | 288 × 154 | pan de mur effondré plus bas que `ruined_wall.png`, pierres tombées au pied, sable |
| 1 | `ruined_wall_c` | 192 × 134 | angle de mur en ruine, une meurtrière |
| 1 | `dead_shrub_a` | 96 × 77 | arbuste sec couché par le vent vers la droite |
| 1 | `wind_grass_a` | 77 × 48 | herbe dure couchée vers la droite, sable au pied |
| 2 | `dead_shrub_b` | 115 × 86 | arbuste sec plus touffu, une branche cassée |
| 2 | `wind_grass_b` | 96 × 38 | longue touffe couchée |
| 2 | `sandbags` | 192 × 77 | muret de sacs de sable de la Garde, à demi ensablé |
| 2 | `broken_spears` | 115 × 154 | râtelier de bois renversé, lances d'entraînement brisées |
| 2 | `ruined_arch` | 384 × 336 | arche de pierre effondrée du poste de guet, une moitié debout |
| 2 | `cart_wreck` | 288 × 154 | épave de charrette de la Garde, roue cassée, ensablée |
| 3 | `broken_pillar` | 96 × 192 | tronçon de pilier de pierre brisé |
| 3 | `garde_crate` | 96 × 77 | caisse de la Garde, ferrures, aile stylisée peinte en rouge délavé (sans texte) |

### 10.5 La colline des étoiles (`hill`) et les bois (`forest`)

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `fallen_tree` | 576 × 192 (6 × 2 m) | arbre tombé couché vers la droite, motte de racines dressée à gauche, mousse, champignons |
| 1 | `stump_a` | 115 × 77 | souche coupée, cernes visibles sur le dessus, mousse |
| 1 | `stump_b` | 134 × 96 | vieille souche pourrie, creuse, fougère qui en sort |
| 1 | `log_hollow` | 288 × 115 | tronc creux couché, mousse et lierre |
| 1 | `training_dummy` | 96 × 192 | mannequin d'entraînement de paille sur un poteau, toile rapiécée, entailles |
| 2 | `target_board` | 115 × 154 | cible de bois ronde sur trépied, sans chiffres |
| 2 | `hunting_stand` | 192 × 384 | affût de chasse de Nygglatho : plate-forme de bois sur quatre perches, échelle (bois) |
| 2 | `cairn` | 96 × 115 | tas de pierres plates empilées (colline) |
| 2 | `rope_fence` | 192 × 86 | piquets de bois et corde le long du chemin en lacets (module de 2 m), **sans raccord à gauche et à droite** |
| 2 | `stone_steps` | 192 × 77 | trois marches de pierre plates enfoncées dans la pente |
| 3 | `old_telescope` | 77 × 154 | vieille lunette de cuivre sur trépied de bois, tournée vers le ciel (colline) |
| 3 | `log_pile_forest` | 192 × 115 | grumes empilées au bord du sentier |

## 11. Dirigeables (refonte complète)

Les dirigeables de l'univers ne sont **pas** des ballons : ce sont des **navires volants** que
portent un **four enchanté** qui gronde et fait vibrer la coque, et des **hélices** (ou pales)
(BIBLE, section 3.9) ; ils ont des bras d'ancrage, des stabilisateurs, une rampe, un sifflet. Les
deux images actuelles sont remplacées.

**Vue** : la caméra regarde le nord ; à quai, les navires sont amarrés **de flanc**, à l'est et
à l'ouest du quai, au bord du vide : ils se dessinent **de profil, proue à droite**, vus très
légèrement d'en haut (on voit un peu le pont), à **96 px/m** comme le quai. Leurs **hélices
latérales** (axe tourné vers la caméra, un disque de pales vu de face, comme une roue à aubes de
bateau à vapeur) sont des bandes animées à part : la coque est dessinée **avec le moyeu mais
sans les pales**. Le jeu place les pales sur le moyeu.

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `airship_ferry` | 1344 × 672 (14 × 7 m) | petit navire volant du passeur de l'île n° 53, de profil, proue à droite : coque de bateau de 12 m en bois verni sombre cerclée de cuivre, pont avec rambarde, petite cabine à hublots éclairés à l'arrière, four enchanté de cuivre derrière la cabine qui rougeoie par des grilles, courte cheminée, deux ailerons stabilisateurs à la poupe, quille de fer, rampe d'embarquement relevée ; **un moyeu de cuivre** sur le flanc au milieu de la coque, **sans pales** ; usé, rapiécé, sympathique |
| 1 | `airship_ferry_propeller` | 192 × 192 (2 m), 4 images | **bande animée** : hélice latérale à quatre pales de bois et de cuivre vue de face, qui tourne d'un huitième de tour d'une image à l'autre ; moyeu au centre exact de chaque image ; fond transparent |
| 1 | `airship_barocupot` | 2304 × 1056 (24 × 11 m) | le Barocupot, transport militaire de la Garde ailée, de profil, proue à droite : coque de tôle d'acier rivetée gris-bleu sombre, bande rouge de la Garde (#AE4A3E) le long du bordage, aile stylisée peinte sur la proue (sans texte), deux ponts de hublots ronds éclairés, passerelle de commandement vitrée à l'avant, grande trappe de soute à l'arrière (fermée), deux fours enchantés en nacelles sous la coque avec des grilles rougeoyantes, ailerons de queue, canon court sous bâche, **deux moyeux** sur le flanc (à un tiers et aux deux tiers de la longueur), **sans pales** ; massif, sérieux, entretenu |
| 1 | `airship_barocupot_propeller` | 288 × 288 (3 m), 4 images | **bande animée** : hélice latérale à cinq pales de fer sombre, bout des pales rouge, vue de face, qui tourne d'une image à l'autre ; moyeu au centre exact |
| 2 | `airship_far_a` | 480 × 192 (20 × 8 m à **24 px/m**) | dossier `sky/` : navire de ligne publique en vol, de profil vers la droite, coque claire et longue, rangée de hublots éclairés, deux hélices floues, fumée légère ; silhouette adoucie et violacée par la distance |
| 2 | `airship_far_b` | 288 × 144 (12 × 6 m à 24 px/m) | dossier `sky/` : patrouilleur de la Garde en vol, coque sombre à bande rouge, vers la droite ; violacé par la distance |
| 2 | `airship_far_c` | 768 × 288 (32 × 12 m à 24 px/m) | dossier `sky/` : gros transport « de classe semi-grande baleine » en vol, coque ventrue de tôles d'acier, de cuivre et d'étain, quatre hélices, vers la droite ; violacé par la distance |
| 3 | `airship_far_d` | 192 × 96 (8 × 4 m à 24 px/m) | dossier `sky/` : petit navire de passeur en vol, vers la droite |

## 12. Animations

Bandes animées (section 3.4), dossier `assets/hd2d/anim/`. La taille est celle d'**une** image.
Consigne : « Bande animée `<nom>.png` de <n> images de <taille> chacune, côte à côte sur une ligne,
sans marge, qui bouclent sans saut ; seul ce qui bouge change ; fond transparent, pixel art à
96 px/m : » puis :

| Prio | Nom | Une image (px) | Images | Description à coller |
| --- | --- | --- | --- | --- |
| 1 | `laundry_wave` | 576 × 211 | 4 | `laundry_line.png` (jointe) : les trois draps ondulent au vent vers la droite, poteaux et corde immobiles |
| 1 | `pennant_wave` | 96 × 336 | 6 | `garde_pennant.png` (joint) : le fanion rouge claque au vent vers la droite, mât immobile |
| 1 | `chimney_smoke` | 96 × 288 | 8 | **alpha doux** : volutes de fumée grise et chaude qui montent et s'étirent vers la droite, sans cheminée (le bas de l'image est la sortie du conduit) |
| 1 | `brazier_fire` | 48 × 58 | 6 | flammes et braises d'un brasero (sans le brasero), orange et jaune, étincelles |
| 1 | `edge_waterfall` | 288 × 576 (3 × 6 m) | 6 | **alpha doux** sur les bords : le ruisseau qui tombe du bord de l'île dans le vide, eau claire et écume blanche, brume en bas ; le haut de l'image est la lèvre de pierre |
| 1 | `birds_flock` | 192 × 96 | 6 | cinq petits oiseaux sombres en vol, battements d'ailes décalés, vus de côté vers la droite |
| 1 | `falling_leaf_gold` | 16 × 16 | 8 | une feuille d'automne or qui tournoie en tombant (rotation et retournement, la feuille reste au centre) |
| 1 | `falling_leaf_rust` | 16 × 16 | 8 | même chose, feuille rouille |
| 2 | `reeds_sway` | 144 × 134 | 4 | `reeds.png` (jointe) : les roseaux se balancent doucement vers la droite, pied immobile |
| 2 | `grass_sway` | 96 × 77 | 4 | `tall_grass.png` (jointe) : l'herbe haute ondule vers la droite, pied immobile |
| 2 | `windsock_wave` | 115 × 384 | 4 | `wind_sock.png` (jointe) : la manche à air se gonfle et ondule vers la droite, mât immobile |
| 2 | `bunting_wave` | 576 × 96 | 4 | `bunting.png` (section 10.2) : les fanions de la guirlande flottent |
| 2 | `vigil_bell_ring` | 134 × 230 | 6 | `vigil_bell.png` (jointe) : la cloche se balance (gauche, centre, droite, centre…), portique immobile |
| 2 | `fountain_water` | 288 × 240 | 4 | `fountain.png` (section 10.2) : l'eau tombe du bec et ride le bassin |
| 2 | `pigeons` | 38 × 29 | 4 | pigeon gris au sol qui picore, tourné vers la droite |
| 2 | `butterfly` | 24 × 24 | 4 | papillon orangé qui bat des ailes, vu de dessus |
| 3 | `fireflies` | 12 × 12 | 4 | **alpha doux** : petite lueur jaune-vert qui pulse (marais, colline au crépuscule) |
| 3 | `furnace_steam` | 96 × 192 | 6 | **alpha doux** : jets de vapeur blanche d'un four enchanté, vers le haut |
| 3 | `cafe_door_bell` | 48 × 48 | 4 | clochette de laiton au-dessus d'une porte qui oscille |

## 13. Ciel, nuages et lointain

`assets/hd2d/sky/`. Consigne de la section 8 du cahier n° 1, puis :

| Prio | Nom | Taille (px) | Description à coller |
| --- | --- | --- | --- |
| 1 | `cloud_a` | 768 × 256 (48 px/m) | **alpha doux** : gros cumulus isolé en pixel art, sommet pêche éclairé par le couchant (#F4DCC6), base lavande (#BBA3BF), dégradés en paliers |
| 1 | `cloud_b` | 576 × 192 | **alpha doux** : nuage étiré horizontalement, effiloché à droite |
| 1 | `cloud_c` | 384 × 128 | **alpha doux** : petit nuage rond |
| 1 | `distant_island_d` | 768 × 384 | île lointaine en silhouette violacée, reliée à une autre île par deux grosses **chaînes** et un pont suspendu (les îles centrales sont reliées ainsi) ; fond transparent |
| 1 | `island_53` | 1024 × 512 | l'île n° 53, au loin, au sud : île plate avec un petit port plaqué de métal, quelques maisons et deux minuscules dirigeables amarrés ; silhouette violacée, détails dorés par le couchant ; fond transparent |
| 2 | `cloud_d` | 960 × 288 | **alpha doux** : banc de nuages bas, long et plat |
| 2 | `cloud_e` | 480 × 192 | **alpha doux** : nuage en forme d'enclume lointaine, sombre en bas |
| 2 | `distant_island_e` | 768 × 384 | île lointaine en aiguille de roche, un phare de pierre au sommet ; fond transparent |
| 2 | `distant_island_f` | 768 × 384 | île lointaine boisée de sapins, cascade qui tombe du bord ; fond transparent |
| 2 | `horizon_islands` | 2048 × 192 | rangée de minuscules îles en silhouette sur l'horizon, très violacées, fond transparent, **sans raccord à gauche et à droite** |
| 2 | `mist_band` | 1024 × 128 | **alpha doux** : bande de brume rose et lavande, **sans raccord à gauche et à droite** (pied des falaises, marais) |
| 2 | `light_shaft_a` | 192 × 768 (2 × 8 m) | **alpha doux** : rai de lumière dorée qui tombe en biais du haut à gauche vers le bas à droite, opacité 15 à 35 %, poussière en suspension (bois) |
| 2 | `light_shaft_b` | 288 × 960 | **alpha doux** : rai plus large et plus pâle |
| 3 | `sky_dusk` | 2048 × 1024 | même cadrage que `sky.png` (équirectangulaire, horizon à mi-hauteur, raccord gauche-droite) : juste après le coucher, soleil disparu, bande orange à l'ouest, violet profond au zénith, premières étoiles |
| 3 | `sky_night` | 2048 × 1024 | même cadrage : nuit d'automne claire, voie lactée en pixel art, mer de nuages bleu nuit éclairée par la lune (colline des étoiles, actes suivants) |

## 14. Ce qu'on doit voir, zone par zone

Pour garder la cohérence des images (et guider leur pose dans le jeu) :

- **La cour de l'entrepôt** : la façade et son flanc, cheminée qui fume, terrasse à linge sur le
  toit ; la cour en terre battue et vieilles dalles bordée d'herbe (`grass_edge_*`), feuilles
  sous le grand arbre, marelle et dessins de craie près de l'aire de jeux ; le potager vu de
  dessus avec son épouvantail et sa clôture ; brouette, bûches, billot, tonneau, jouets, panier à
  linge, linge qui flotte ; derrière la palissade, une lisière continue (`treeline_autumn_*`).
- **Les bois du marais** : une **vraie forêt** : lisières au fond (`forest_wall_*`), dix à vingt
  arbres de quatre espèces à l'écran, fougères, ronces, souches, troncs couchés, rochers moussus,
  racines et tapis de feuilles, ombre de feuillage et taches de soleil, rais de lumière, troncs
  flous au premier plan ; seul le terrain d'entraînement reste dégagé (mannequin, cible, buts) ;
  le marais avec saules, massettes, caillebotis, nénuphars, brume ; le ruisseau et ses pierres de
  gué ; la cascade au bord nord.
- **Le bord du Couchant** : la dalle à nu et ses congères de sable, herbes couchées par le vent,
  arbres morts tordus, ruines du poste de guet (arche, pans de mur, sacs de sable, épave de
  charrette), l'anneau de pierres plates au ras du sol, le fanion qui claque, la cloche ; au bord,
  rochers et racines qui débordent dans le vide.
- **Le bourg et le port** : une **vraie rue** : les façades d'un seul tenant de chaque côté, sans
  trou d'herbe entre les maisons, enseignes, jardinières, lierre, lampadaires ; le marché (étals,
  fontaine, charrette, tonneaux, guirlande) ; le quai de tôle encombré (cordages, caisses de
  cristaux, filets, tuyaux, tonneaux d'huile, malles des voyageurs) ; le petit navire du passeur à
  quai à l'est, le Barocupot à son pylône à l'ouest, leurs hélices qui tournent ; d'autres
  dirigeables qui passent dans le ciel.
- **La colline des étoiles** : herbe dorée qui ondule, bruyère, myosotis en tapis, cairns,
  marches de pierre et corde le long des lacets, l'arbre noueux couché par le vent, le belvédère ;
  au loin, nuages et îles ; au crépuscule, lucioles.
- **Le ciel partout** : trois à six nuages qui dérivent lentement, des oiseaux, un dirigeable qui
  passe de temps en temps, l'île n° 53 au sud et des îles reliées par des chaînes au loin.

## 15. Ordre de commande

Une PR par lot. Dans chaque lot, la priorité 1 d'abord.

| Lot | Contenu | Sections | Gain |
| --- | --- | --- | --- |
| A | Forêt : arbres, lisières, plantes, premier plan, rochers, décalques de sous-bois | 6, 7, 8, 5 (feuilles, racines, branches, ombres, soleil, mousse) | les bois deviennent une forêt ; tout le pourtour gagne une lisière |
| B | Sol : nouvelles tuiles et variantes, bordures, flaques, fissures, cailloux, potager | 4, 5 (le reste) | fin des grandes surfaces nues et des bords francs |
| C | Dirigeables | 11 | le port prend vie |
| D | Bâtiments : flancs, nouvelles maisons, matières, détails | 9 | une vraie rue, des volumes crédibles |
| E | Objets de la vie | 10 | chaque lieu raconte quelque chose |
| F | Animations | 12 | le monde bouge |
| G | Ciel et lointain | 13 | profondeur et horizon |

## 16. Livraison

1. Pars de la **dernière version de `main`** (pas d'une ancienne branche).
2. Ne livre **que** les PNG de ce document, à leurs chemins exacts : ni sources, ni galeries, ni
   aperçus, ni outils, ni code, ni changement des fichiers existants (sauf les images que ce
   document remplace : les deux dirigeables).
3. Vérifie chaque image : taille exacte, fond transparent (alpha 0 ou 255 hors « alpha doux »),
   tuiles et bordures sans raccord (colle l'image à côté d'elle-même pour le voir), bandes animées
   à `n ×` la largeur annoncée, poids et palette de la section 2.
4. Note la provenance en bas de `assets/CREDITS.md` (« généré avec ChatGPT le …, lot … »).
5. Dans la description de la PR : la liste des fichiers livrés, ceux qui manquent, et les écarts
   connus (taille, cadrage).

L'intégration (placement dans les zones, nouveaux formats dans le moteur, vérifications
`tools/hd2d_assets.py`) se fait ensuite de notre côté.

## 17. Pour l'intégration (le jeu, pas l'image)

Ce que le moteur doit apprendre pour utiliser ce cahier, à faire par un lot de code pendant que
les images se préparent :

- **Variantes** : tirage d'une variante par emplacement (`PropScatter`), sans deux voisines
  identiques ; atlas du sol à 4 colonnes agrandi (27 tuiles), alternance des tuiles `_b`.
- **Décalques** : quads couchés sur le relief (au-dessus du sol, sous les panneaux), fondus par
  image comme les panneaux (`PropBatcher`) ; alpha doux pour les ombres et la lumière.
- **Bandes animées** : un `DecorPanel` à images (nombre d'images, cadence), décalage de phase
  aléatoire entre deux instances ; particules de feuilles et oiseaux.
- **Flancs** : `Building.side_facade`, plaqué sur les flancs est et ouest (retourné à l'ouest),
  pignon ou gouttereau selon le type ; panneaux de toit (cheminées, lucarnes).
- **Lisières et premier plan** : rangées au fond des zones, troncs flous devant le chemin sans
  gêner la lecture du joueur (transparence comme les façades).
- **Ciel** : nuages et dirigeables qui dérivent sur des trajets lointains au nord, île n° 53 au
  sud visible depuis le quai.
- **Port** : navires à quai à l'est et à l'ouest du quai, de flanc, dans le champ de la caméra ;
  hélices posées sur les moyeux.
- **Poids** : ce cahier commande environ 300 images, soit 40 à 45 Mo de PNG au rendu des
  livraisons actuelles (moins si la palette de la section 2 est tenue), et 15 à 20 Mo de plus
  dans l'export Web compressé (23,7 Mo aujourd'hui pour un budget de 25 Mo) : le budget est à
  revoir avant l'intégration (le relever, compresser les grandes images ou charger par zone).
