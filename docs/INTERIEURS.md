# Intérieurs : décrire et meubler un étage

Lot E3 de la refonte (`docs/REFONTE.md`, sections 7.1 et 8.1). Un étage d'un bâtiment est une
carte (`Map`, `interior = true`) dont le nœud `Ground` est une **`InteriorRoom`**. L'étage se
décrit dans un fichier de données, se meuble dans la scène de la carte et se voit comme dans
*Octopath Traveler* : caméra fixe inclinée vers le nord, mur sud jamais dessiné, sols et murs en
images, lumière chaude. Exemple complet : `data/maps/entrepot_rdc_essai/interior.json` et
`src/world/maps/entrepot_rdc_essai/entrepot_rdc_essai.tscn` (rez-de-chaussée de l'entrepôt des
fées), démonstration `tests/integration/demo_interieur.tscn`.

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
   - ce qui dépasse 1 m (armoires, rayonnages, vaisselier, cabines) **contre un mur nord** ;
   - au milieu d'une pièce, un meuble de hauteur `h` a une emprise d'au moins
     `(h − 0,25) / 0,78 − 0,35` m de profondeur, sinon il cache les pieds du joueur derrière lui
     (`test_interior_entrepot.gd` le vérifie de toute case praticable) ;
   - garder 0,8 m de passage (le joueur a 0,35 m de rayon) et dégager les portes ;
   - les tapis sont des `GroundDecal` (`rug_*`), sans collision.
5. **Marqueurs et sorties** : `Markers/Spawn` et un `from_<carte>` par arrivée, à 1,5 m au moins
   d'une sortie, tournés vers où l'on regarde (−Z : le nord). Une porte vers une autre carte a un
   `id` ; son `MapExit` se pose devant elle (`InteriorRoom.door_position(id)` donne son centre) :
   `prompt` vide pour une porte qu'on franchit en marchant (porte sud, ouverte), « Descendre »,
   « Entrer »… pour une porte fermée (`passable: false`).
6. **Bornes de la caméra** (`camera_bounds`) : celles du point visé, à 2,5 m au nord du joueur.
   Pour un étage de L × P m : de x = 10 à L − 10 et de z = 6,5 à P − 6,5 environ, pour que les murs
   remplissent l'écran sans cacher le joueur.
7. **Vérifier** : `tools/test.sh tests/unit/test_interior_room.gd` (format, coupe, lumière) et un
   test d'étage sur le modèle de `tests/unit/test_interior_entrepot.gd` (collisions, portes,
   occlusion depuis chaque case, draw calls) ; captures par une démo sur le modèle de
   `tests/integration/demo_interieur.gd`.

Nouvelle matière, porte, fenêtre, élément de mur ou meuble : l'ajouter à la liste de
`tools/hd2d_interior.py` (et à la section 4 de ce document), puis
`python3 tools/hd2d_interior.py manifest`, `python3 tools/hd2d_assets.py gen --lot I`,
`python3 tools/hd2d_interior.py scenes` (meubles), `tools/import.sh`.

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
    {"id": "entree", "room": "entree", "side": "S", "x": 19.0, "image": "door_wood"},
    {"id": "crypte", "room": "descente", "side": "N", "x": 36.5, "image": "door_cellar", "passable": false}
  ],
  "windows": [{"room": "refectoire", "side": "N", "x": 8.5, "image": "window_large", "sill": 0.8}],
  "wall_items": [{"room": "couloir", "side": "N", "x": 5.0, "y": 1.1, "image": "wallitem_chores"}],
  "lights": [{"room": "cuisine", "at": [16.8, 3.2], "radius": 3.6, "color": "#ffb062", "energy": 1.0}]
}
```

| Clé | Sens |
| --- | --- |
| `size` | largeur et profondeur de la carte (m), égales à `Map.size` |
| `wall_height`, `wall_thickness` | 3 m et 0,25 m par défaut ; un mur est centré sur sa ligne de grille |
| `rooms.<id>` | `name`, `rects` (`[x, z, largeur, profondeur]`, entiers, sans chevauchement), `floor` (`floor_*`), `wall` (`wall_*`), `wallcut` (`wallcut_*`, défaut `wallcut_wood`) |
| `doors[]` | entre deux pièces (`between`) ou sur un côté d'une pièce (`room` + `side` : `N`, `S`, `E`, `W`) ; centre le long du mur : `x` (mur est-ouest) ou `z` (mur nord-sud) ; `width` (1,1 m), `height` (2,2 m), `image` (`door_*`, facultative : posée sur les deux faces), `passable` (vrai : ouverture qu'on franchit ; faux : le mur reste, l'image le couvre), `id` (sortie) |
| `windows[]` | `room`, `side`, `x` ou `z`, `image` (`window_*`), `sill` (bas, 0,9 m) ; posée sur la face de sa pièce ; laisse entrer le jour (flaque devant elle) |
| `wall_items[]` | `room`, `side`, `x` ou `z`, `image` (`wallitem_*`), `y` (bas, 1,2 m) : écriteaux, plannings, horloge, miroir, lampe de mur |
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
  ouest sont entiers. La ligne glisse d'une limite à l'autre (14 m/s) quand on passe une porte.
  La tranche d'un mur coupé est sombre, comme sur un plan. Les collisions ne changent pas.
- **Lumière** : préréglage `interieur` (`src/world/materials/lighting_interieur.tres`, à poser
  par `HD2DLighting.apply`) plus deux cartes de lumière vues de dessus (4 texels par mètre),
  bornées à leur pièce : le jour des fenêtres et les lampes ; elles s'ajoutent en émission aux
  sols, aux murs, aux portes et fenêtres et aux meubles (`interior_core.gdshaderinc`). Aucune
  lumière du moteur, aucune ombre portée : pas un draw call de plus.
- **Moment de la journée** : `set_daylight(teinte, énergie)`, `set_lamps(énergie)`,
  `apply_phase(phase)` (`morning`, `day`, `evening`, `night`), appelée sur
  `EventBus.day_phase_changed`.
- **Collisions** (couche 1) : une dalle sous toute la carte, une boîte par morceau de mur et par
  linteau.
- **Draw calls** : un par matière de sol, de mur, de dessus de mur, par image de porte, fenêtre,
  élément et meuble, plus le vide autour du bâtiment.

## 4. Images du lot I (`assets/hd2d/interior/`)

Conventions : `docs/REFONTE.md`, section 8.1 (96 px par mètre). Remplaçants en pixel art de
`tools/hd2d_interior.py` ; les images du cahier n° 3 les remplaceront sous le même nom.

| Image (meubles et tapis : `props/`) | Taille (px) | Genre | Contenu |
| --- | --- | --- | --- |
| `floor_planks_worn` | 384 × 384 | tile | parquet usé (couloir, réfectoire, infirmerie, salle de jeux) |
| `floor_planks_dark` | 384 × 384 | tile | parquet sombre (chambres, lecture, archives) |
| `floor_tiles_bath` | 384 × 384 | tile | carrelage de salle de bains |
| `floor_flagstone_cellar` | 384 × 384 | tile | dalles de crypte |
| `floor_kitchen_tiles` | 384 × 384 | tile | carreaux de cuisine |
| `wall_plaster_worn` | 384 × 288 | tile_h | plâtre usé, plinthe et corniche |
| `wall_wainscot` | 384 × 288 | tile_h | lambris bas et plâtre |
| `wall_wallpaper_faded` | 384 × 288 | tile_h | papier peint fané (chambres) |
| `wall_kitchen_tiles` | 384 × 288 | tile_h | faïence de cuisine |
| `wall_cellar_stone` | 384 × 288 | tile_h | pierre de crypte |
| `wallcut_wood` | 384 × 24 | tile_h | dessus d'un mur de bois et de plâtre |
| `wallcut_stone` | 384 × 24 | tile_h | dessus d'un mur de pierre |
| `door_wood` | 106 × 211 | panel | porte de planches fermée, avec son chambranle |
| `door_frame_wood` | 126 × 221 | panel | chambranle d'une porte ouverte (ouverture de 1,1 × 2,2 m transparente) |
| `door_cellar` | 126 × 221 | panel | arc de pierre, marches qui descendent dans le noir |
| `window_cross` | 96 × 120 | panel | fenêtre à croisillons et son appui |
| `window_large` | 230 × 154 | panel | grande fenêtre du réfectoire |
| `wallitem_chores` | 58 × 77 | panel | planning des corvées (illisible) |
| `wallitem_notice` | 48 × 34 | panel | écriteau (illisible) |
| `wallitem_menu` | 67 × 86 | panel | menu du réfectoire, ligne du dessert du jour |
| `wallitem_clock` | 38 × 48 | panel | horloge murale à balancier |
| `wallitem_calendar` | 34 × 48 | panel | calendrier |
| `wallitem_plaque` | 48 × 14 | panel | plaque de bronze « salle de stockage » |
| `wallitem_mirror_large` | 115 × 134 | panel | grand miroir de la salle de bains |
| `wallitem_height_marks` | 29 × 134 | panel | marques de taille des petites |
| `wallitem_lamp` | 29 × 48 | panel | applique à cristal (lueur) |
| `dresser_glass` | 154 × 202 | panel | vaisselier vitré |
| `sink_counter` | 134 × 96 | panel | évier |
| `table_long` | 250 × 91 | panel | grande table de bois |
| `bench_long` | 230 × 48 | panel | banc |
| `crystal_stove` | 125 × 106 | panel | fourneau de cristal (lueur) |
| `kitchen_counter` | 192 × 96 | panel | comptoir de cuisine |
| `kitchen_table` | 154 × 86 | panel | table de travail |
| `bookshelf` | 134 × 192 | panel | étagère de livres |
| `window_seat` | 154 × 58 | panel | siège sous la fenêtre |
| `reading_table` | 154 × 82 | panel | table de lecture |
| `chair` | 48 × 91 | panel | chaise |
| `archive_shelf` | 154 × 202 | panel | rayonnage des archives (papiers, cartons) |
| `desk_cluttered` | 134 × 106 | panel | bureau sous les piles |
| `sofa_beige` | 192 × 86 | panel | canapé beige à trois places |
| `paper_stacks` | 115 × 86 | panel | piles de papiers |
| `bed_infirmary` | 96 × 125 | panel | lit d'infirmerie vu du pied |
| `nightstand_vase` | 48 × 86 | panel | table de chevet et vase |
| `medicine_cabinet` | 86 × 173 | panel | armoire à pharmacie |
| `desk_small` | 115 × 86 | panel | petit bureau |
| `toy_shelf` | 115 × 134 | panel | étagère à jeux et peluches |
| `plush_pile` | 77 × 48 | panel | peluches |
| `board_game_table` | 96 × 48 | panel | table basse et jeu de société |
| `bathtub` | 154 × 77 | panel | baignoire |
| `washstand` | 77 × 96 | panel | lavabo |
| `water_basin` | 86 × 96 | panel | point d'eau froide du couloir |
| `cupboard_supplies` | 96 × 192 | panel | placard à fournitures |
| `toilet_stall` | 115 × 202 | panel | cabine de toilettes |
| `shoe_bench` | 154 × 48 | panel | banc à chaussures de l'entrée |
| `rug_play` | 240 × 173 | decal | tapis de la salle de jeux |
| `rug_doormat` | 115 × 67 | decal | paillasson |
