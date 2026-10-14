# Intérieurs : décrire et meubler un étage

Lot E3 de la refonte (`docs/REFONTE.md`, sections 7.1 et 8.1). Un étage d'un bâtiment est une
carte (`Map`, `interior = true`) dont le nœud `Ground` est une **`InteriorRoom`**. L'étage se
décrit dans un fichier de données, se meuble dans la scène de la carte et se voit comme dans
*Octopath Traveler* : caméra fixe inclinée vers le nord, mur sud jamais dessiné, sols et murs en
images, lumière chaude. Exemple complet : `data/maps/entrepot_rdc_essai/interior.json` et
`src/world/maps/entrepot_rdc_essai/entrepot_rdc_essai.tscn` (rez-de-chaussée de l'entrepôt des
fées), démonstration `tests/integration/demo_interieur.tscn` (la vraie partie, `game.tscn`, posée dans
l'étage par `WorldManager.enter_map`), test dans la vraie partie
`tests/integration/test_interior_in_game.gd`.

## 1. Mode d'emploi

1. **Dessiner le plan** sur une grille d'un mètre, origine au coin nord-ouest, x vers l'est,
   z vers le sud. Une pièce, un couloir : un ou plusieurs rectangles. Laisser 2 m de vide autour
   du bâtiment (au sud : la place de la sortie).
2. **Écrire `data/maps/<map_id>/interior.json`** (format en section 2) : pièces et matières,
   portes, fenêtres, éléments de mur, lampes. Les murs se déduisent tout seuls : il y en a un
   partout où deux cases voisines ne sont pas de la même pièce.
3. **Créer la carte** `src/world/maps/<map_id>/<map_id>.tscn` selon le contrat (racine `Map`,
   `interior = true`, `light_preset = &"interieur"`, enfants `Ground`, `Geometry`, `Markers`,
   `Exits`, `Life`) ; `Ground` est un `StaticBody3D` de script `src/world/interior_room.gd`
   (couche 1, masque 0) dont `layout` pointe sur le JSON.
4. **Meubler** : instancier les meubles de `src/world/props/` sous `Geometry` (le
   `PropBatcher` les fond par image). Un meuble est une scène dont la racine est un
   `InteriorPanel` : son nœud est **au milieu de son emprise**, son image au bord sud. Contre un
   mur nord : `z = ligne du mur + 0,125 + profondeur / 2 + 0,02`. Règles :
   - ce qui dépasse 1 m (armoires, rayonnages, vaisselier, cheminée) **contre un mur nord** ;
   - au milieu d'une pièce, un meuble de hauteur `h` a une emprise d'au moins
     `(h − 0,25) / 0,78 − 0,35` m de profondeur, sinon il cache les pieds du joueur derrière lui
     (`test_interior_entrepot.gd` le vérifie de toute case praticable) ; dans les 5 m nord d'un
     étage, la caméra butée sur `camera_bounds` voit plus à plat : y préférer les meubles bas, ou
     ne laisser derrière un meuble haut que moins de 0,7 m (le joueur ne s'y tient pas : les
     chaises au nord des tables du réfectoire) ;
   - une table et ses chaises : `chair_wood` (de face) au nord, `chair_wood_back` (de dos) au sud,
     emprises jointives (0,5 m de chaise, rien où se glisser) ;
   - un lit (`bed_*`) se voit de flanc, tête à gauche : sa table de chevet à l'ouest de la tête ;
   - un meuble plaqué au mur (emprise de moins de 0,3 m : le grand miroir) se coupe comme le mur
     (`cut_height = 0,15`, écrit par `tools/hd2d_interior.py`) ;
   - garder 0,8 m de passage (le joueur a 0,35 m de rayon) et dégager les portes ;
   - les tapis sont des `GroundDecal` (`assets/hd2d/decals/rug_*`), sans collision.
5. **Marqueurs, sorties, lumière** (contrat et pièges : `PLAN.md`, section 3, « (E1) Créer une
   carte ») : `Markers/Spawn` et un `from_<carte>` par arrivée, à y = 0,2, à 2 ou 3 m d'une
   sortie, tournés vers où l'on regarde (−Z : le nord). Une porte vers une autre carte a un `id` ;
   son `MapExit` se pose devant elle (`InteriorRoom.door_position(id)` donne son centre), sa forme
   couvre la porte : `prompt` vide pour une porte qu'on franchit en marchant (porte sud, ouverte),
   « Descendre », « Entrer »… pour une porte fermée (`passable: false`) ; la carte cible et son
   marqueur doivent exister (`tests/unit/test_maps.gd`). La lumière de l'étage est un enfant
   `Light`, instance de `src/world/interior_light.tscn` : le préréglage `interieur` à l'entrée,
   le réglage par défaut (couchant) rendu à la caméra et aux personnages en partant.
6. **Bornes de la caméra** (`camera_bounds`) : celles du point visé, à 2,5 m au nord du joueur.
   En x, tout le bâtiment (de 2 à L − 2 pour un étage de L m) : la caméra reste au droit du
   joueur, aucune cloison nord-sud ne le cache en biais. En z, de 5 à P − 5 (P : profondeur) :
   moins de vide noir au-dessus du mur nord, sans trop aplatir la vue.
7. **Vérifier** : `tools/test.sh tests/unit/test_interior_room.gd` (format, coupe, lumière) et un
   test d'étage sur le modèle de `tests/unit/test_interior_entrepot.gd` (collisions, portes,
   occlusion depuis chaque case, draw calls) ; captures par une démo sur le modèle de
   `tests/integration/demo_interieur.gd`.

Nouvelle matière, porte, fenêtre, élément de mur ou meuble (livré, ou à dessiner en remplaçant) :
l'ajouter aux listes de `tools/hd2d_interior.py` (section 4 de ce document), puis
`python3 tools/hd2d_interior.py manifest`, `python3 tools/hd2d_assets.py gen --lot I`
(remplaçants seulement), `python3 tools/hd2d_interior.py scenes` (meubles et tapis),
`tools/import.sh`, `python3 tools/hd2d_assets.py check --lot I`.

## 2. Format de `interior.json`

```json
{
  "size": [40, 24],
  "wall_height": 3.0,
  "wall_thickness": 0.25,
  "rooms": {
    "couloir": {"name": "Couloir", "rects": [[2, 10, 36, 3], [35, 6, 3, 4]],
                "floor": "floor_planks_worn", "wall": "wall_plaster_worn", "wallcut": "wallcut_wood"}
  },
  "doors": [
    {"between": ["couloir", "cuisine"], "x": 18.0, "image": "door_frame_wood"},
    {"between": ["refectoire", "cuisine"], "z": 4.0},
    {"id": "entree", "room": "entree", "side": "S", "x": 19.0, "width": 2.0, "height": 2.4, "image": "door_double"},
    {"id": "crypte", "room": "descente", "side": "N", "x": 36.5, "width": 1.3, "height": 2.3, "image": "door_armory", "passable": false}
  ],
  "windows": [{"room": "refectoire", "side": "N", "x": 8.5, "image": "window_cross_large", "sill": 0.8}],
  "wall_items": [{"room": "couloir", "side": "N", "x": 5.0, "y": 1.2, "image": "wallitem_chore_chart"}],
  "lights": [{"room": "cuisine", "at": [16.2, 3.2], "radius": 3.6, "color": "#ffb062", "energy": 1.0}]
}
```

| Clé | Sens |
| --- | --- |
| `size` | largeur et profondeur de la carte (m), égales à `Map.size` |
| `wall_height`, `wall_thickness` | 3 m et 0,25 m par défaut ; un mur est centré sur sa ligne de grille |
| `rooms.<id>` | `name`, `rects` (`[x, z, largeur, profondeur]`, entiers, sans chevauchement), `floor` (`floor_*`), `wall` (`wall_*`), `wallcut` (`wallcut_*`, défaut `wallcut_wood`) |
| `doors[]` | entre deux pièces (`between`) ou sur un côté d'une pièce (`room` + `side` : `N`, `S`, `E`, `W`) ; centre le long du mur : `x` (mur est-ouest) ou `z` (mur nord-sud) ; `width` (1,1 m), `height` (2,2 m), `image` (`door_*`, facultative : posée sur les deux faces), `passable` (vrai : ouverture qu'on franchit ; faux : le mur reste, l'image le couvre), `id` (sortie). Une porte qu'on franchit prend une image à ouverture transparente (`door_frame_wood`) ou aucune : un battant opaque (`door_room`, `door_room_open`) cacherait le joueur sur le seuil, il va aux portes fermées |
| `windows[]` | `room`, `side`, `x` ou `z`, `image` (`window_*`), `sill` (bas, 0,9 m ; celui que donne le cahier n° 3 : 1 m pour `window_cross_small`, 0,8 m pour `window_cross_large`, 0 pour `window_reading_seat`, posée au sol) ; posée sur la face de sa pièce ; laisse entrer le jour (flaque devant elle) |
| `wall_items[]` | `room`, `side`, `x` ou `z`, `image` (`wallitem_*`), `y` (bas, 1,2 m ; celui que donne le cahier n° 3, « bas à 1,4 m ») : écriteaux, plannings, horloge, patères, lampe de mur |
| `lights[]` | `room`, `at` `[x, z]`, `radius` (3,5 m), `color` (`#ffc98a`), `energy` (1) : halo sur le sol et les murs de sa pièce |

Une clé inconnue est une faute, sauf `_…` (commentaire). Une porte, une fenêtre ou un élément ne
touche jamais un angle (0,175 m au moins d'un mur perpendiculaire) et ne chevauche rien sur sa
face. `InteriorLayout.from_data(data).problems` liste les fautes ; `InteriorRoom` les écrit en
erreurs au chargement.

## 3. Ce que fait `InteriorRoom`

- **Sols** : un mesh par matière, tuiles de 4 m alignées sur la carte.
- **Murs** : un mesh par matière ; chaque face prend la matière de la pièce qu'elle regarde ; le
  mur nord-sud porte le poteau des angles ; dessus des murs en `wallcut_*` ; portes praticables
  trouées, linteau au-dessus.
- **Coupe** (rien ne cache le joueur) : la *ligne de coupe* est la première limite de pièce au
  sud de la case du joueur, dans sa colonne (porte comprise). Tout ce qui est au sud de cette
  ligne moins 0,3 m (murs est-ouest et nord-sud, portes, fenêtres, éléments, meubles
  `InteriorPanel`) n'est dessiné que sous sa hauteur de coupe : 0,15 m pour les murs (leur
  épaisseur au ras du sol, `wallcut_*`), 1 m pour les meubles (`InteriorPanel.cut_height`). Le
  mur sud de la pièce du joueur et tout ce qui est au-delà sont donc coupés ; ses murs nord, est et
  ouest sont entiers. Dans la porte d'une cloison nord-sud, la *colonne de coupe* abaisse aussi
  cette cloison sur 4,5 m au sud du joueur (vue par la tranche, elle le cacherait). La ligne glisse d'une limite à l'autre (14 m/s) quand on passe une porte.
  La tranche d'un mur coupé est sombre, comme sur un plan. Les collisions ne changent pas.
- **Lumière** : préréglage `interieur` (`src/world/materials/lighting_interieur.tres`, posé par
  l'enfant `Light` de la carte, `src/world/interior_light.tscn`) plus deux cartes de lumière vues de dessus (4 texels par mètre),
  bornées à leur pièce : le jour des fenêtres et les lampes ; elles s'ajoutent en émission aux
  sols, aux murs, aux portes et fenêtres et aux meubles (`interior_core.gdshaderinc`). Aucune
  lumière du moteur, aucune ombre portée : pas un draw call de plus.
- **Moment de la journée** : `set_daylight(teinte, énergie)`, `set_lamps(énergie)`,
  `apply_phase(phase)` (`morning`, `day`, `evening`, `night`), appelée sur
  `EventBus.day_phase_changed` ; la lueur des vitres suit le jour, celle des appliques et du
  fourneau suit les lampes.
- **Collisions** (couche 1) : une dalle sous toute la carte, une boîte par morceau de mur et par
  linteau.
- **Draw calls** : un par matière de sol, de mur, de dessus de mur, par image de porte, fenêtre,
  élément et meuble, plus le vide autour du bâtiment.

## 4. Images du lot I

Les images sont celles du cahier n° 3 (`docs/ASSETS_HD2D_SUKASUKA.md`, section 3 : noms, tailles,
ancres, consignes ; conventions : `docs/REFONTE.md`, section 8.1, 96 px par mètre), livrées dans
`assets/hd2d/interior/` (matières, portes, fenêtres, éléments de mur), `assets/hd2d/interior/props/`
(meubles) et `assets/hd2d/decals/` (tapis). `tools/hd2d_interior.py` tient la liste de celles
qu'emploient les intérieurs (entrées du manifeste, lot I, à leur taille réelle), la profondeur et
la lueur de chaque meuble, et écrit leurs scènes (`src/world/props/<nom>.tscn`). Il ne redessine
jamais une image livrée : il ne garde des remplaçants que pour les noms que la livraison n'a pas
encore, et une vraie image livrée sous le même nom les remplace sans toucher au code.

| Remplaçant | Taille (px) | Genre | Contenu |
| --- | --- | --- | --- |
| `floor_flagstone_cellar` | 384 × 384 | tile | dalles de la crypte (cahier, prio 2) |
| `wall_cellar_stone` | 384 × 288 | tile_h | moellons de la crypte (cahier, prio 2) |
| `wallcut_stone` | 384 × 24 | tile_h | dessus d'un mur de pierre (cahier, prio 2) |
| `door_armory` | 125 × 221 | panel | porte rivetée de la salle des armes, cinq serrures (cahier, prio 2) |
| `wallitem_height_marks` | 38 × 154 | panel | marques de taille des petites, bas au sol (cahier, prio 2) |
| `door_frame_wood` | 126 × 221 | panel | chambranle seul, ouverture de 1,1 × 2,2 m transparente : porte qu'on franchit (hors cahier, demandé dans `docs/CONTRACT_REQUESTS.md`) |

Images livrées qu'emploie la carte d'essai (tailles : celles du cahier) :

| Pièce | Murs et sol | Portes, fenêtres, éléments de mur | Meubles (emprise en m, vers le nord) |
| --- | --- | --- | --- |
| couloir | `floor_planks_worn`, `wall_plaster_worn`, `wallcut_wood` | `door_room` (fermée), `wallitem_chore_chart`, `wallitem_notice_a`, `wallitem_notice_b`, `wallitem_bronze_plaque`, `wallitem_wall_lamp` (lueur) | `washstand_corridor` (0,6) |
| réfectoire | `wall_wainscot` | `window_cross_large`, `wallitem_menu_board` | `dining_table_set`, `dining_table_long` (1), `chair_wood`, `chair_wood_back` (0,65), `china_cabinet` (0,55), `sink_stone` (0,65) |
| cuisine | `floor_kitchen_tiles`, `wall_kitchen_tiles` | `window_cross_small`, `wallitem_utensils` | `crystal_stove` (0,75, lueur), `kitchen_counter` (0,65), `kitchen_table_ingredients` (0,9), `water_tub` (0,7) |
| lecture | `floor_planks_dark` | `window_reading_seat` | `bookshelf_tall` (0,45), `bookshelf_low` (0,5), `reading_table` (0,9, lueur) |
| archives | | `wallitem_wall_clock` | `archive_shelves` (0,55), `desk_buried` (1,05), `sofa_beige` (0,9), `paper_pile_a` (1,15), `paper_pile_b` (0,6), `paper_pile_c` (0,45) |
| bains | `floor_tiles_bath` | `wallitem_bath_rules` | `bath_tub` (1), `mirror_large` (0,12, coupé comme le mur), `towel_shelf` (0,4), `wash_tub` (0,5) |
| infirmerie | | `wallitem_day_calendar` | `bed_iron` (1), `bedside_table` (0,45), `medicine_cabinet` (0,4), `infirmary_desk` (0,75, lueur), `chair_child` (0,45) |
| entrée | | `door_double`, `wallitem_coat_hooks` | `shoe_rack` (0,4), tapis `rug_brown` |
| salle de jeux | | | `board_games_shelf` (0,4), `toy_chest` (0,6), `plush_pile` (0,6), `plush_blue` (0,4), `game_table` (0,6), tapis `rug_playroom` |
| chambre de Nygglatho | `wall_wallpaper_faded` | | `fireplace` (0,6), `comm_crystal` (0,4), `shelf_nygglatho` (0,4), `chair_guest` (0,7), `tea_table` (0,7), `desk_nygglatho` (0,8), `bed_nygglatho` (1,1), tapis `rug_brown` |

Les autres images livrées du lot I (chambres de l'étage, toit, salle des armes, `door_room_open`,
`wallitem_calendar`…) attendent leurs cartes : les ajouter aux listes de `tools/hd2d_interior.py`
le jour où une carte les emploie.
