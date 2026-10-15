"""(T1, C1) L'entrepôt vu du dehors : la pose de la carte `entrepot` d'après docs/lore/CARTE.md,
section 2 (blocs ```plan lus par tools/carte_plans.py). Ossature du plan (bâtiment, grands décors,
bords, sorties, marqueurs, places, points, lumières), puis kits par bande (2.6) tirés au hasard
(graine fixe), vie ambiante. Écrite par T1 (scripts de travail hors dépôt), reprise telle quelle
par tools/exterior_maps.py : `gen entrepot` redonne la scène du dépôt, à l'octet.

Chaque recette de ce dossier donne à tools/exterior_maps.py :
- `SETTINGS` : ce que le plan ne dit pas (graines, groupes de décors, lumière…) ;
- `ground_plan(plan_map)` : le plan.json du sol (ou rien : le sol est déduit du plan) ;
- `prepare(p)` : ce que le plan ne ferme pas (bords ajoutés, chemins ajoutés) ;
- `pose(p)` : les décors, par bande, avec la règle de caméra de tools/exterior_pose.py ;
- `ambient(p)` : la vie ambiante (papillons, oiseaux, feuilles) ;
- `lights(p)` : les lumières propres à la carte.
"""

import json
import math

from exterior_pose import Rect, along, poisson, prop

SETTINGS = {
    "groups": ["Building", "Roof", "Facade", "Porch", "Yard", "Garden", "Clearing", "Field", "Marsh", "Trees",
               "Lisiere", "Woods", "Meadow"],
    "provisional": {"entrepot_rdc": ("entrepot_rdc_essai", "Spawn")},
}


def prepare(p):
    # (T1) Le replat d'un mètre entre la lisière et la clairière (x 6 → 12, z 4 → 5) est fermé comme
    # elle : un passage d'un mètre de large où rien ne se passe.
    p.edges.append(Rect(6, 4, 12, 5))
    # Le chemin de la clairière passe par sa rampe (data/maps/entrepot/plan.json).
    p.paths.append(("rampe_clairiere", 3.0, [(28, 28), (26.2, 26.2), (24, 25.2), (24, 21.5), (22, 19)]))


def pose(p):
    M, W, D = p.map, p.W, p.D
    EDGES, BUILDINGS, PLACES, POINTS, MARKERS, PATHS = p.edges, p.buildings, p.places, p.points, p.markers, p.paths
    rng, blockers = p.rng, p.blockers
    place, scatter = p.place, p.scatter
    keep_out, path_distance, in_map, outside_edges = p.keep_out, p.path_distance, p.in_map, p.outside_edges
    free, height, walk_grid = p.free, p.height, p.walk_grid
    # === 1. Ossature du plan (2.4, 2.5) =================================================================

    # Cases où l'on marche (bords et bâtiment seulement : les décors n'en retirent pas, la règle de
    # caméra reste prudente).
    walk_grid()

    # Le bâtiment : deux volumes, origine au centre de l'emprise.
    place("Building", "warehouse_front_a", 39.0, 19.0, y=0.0, name="EntrepotOuest", check=False)
    place("Building", "warehouse_front_b", 54.0, 19.0, y=0.0, name="EntrepotEst", check=False)
    FACADE_Z = 26.0 + 0.05

    # Toit : cheminée de briques au-dessus de la cheminée de Nygglatho (x = 38), sa fumée.
    roof_y = 10.0 - (21.6 - 19.0) / 7.0 * 3.5
    place("Roof", "chimney_brick", 38.0, 21.6, y=roof_y - 0.35, name="Chimney", check=False)
    place("Roof", "chimney_smoke", 38.0, 21.6, y=roof_y + 1.55, name="ChimneySmoke", check=False)
    # Toit-terrasse du volume est (le toit à linge) : rambarde au bord sud, séchoirs et linge.
    for k, x in enumerate((49.0, 51.0, 53.0, 55.0, 57.0, 59.0)):
        place("Roof", "warehouse_roof_railing", x, 25.85, y=6.5, name="Railing%d" % (k + 1), check=False)
    place("Roof", "warehouse_drying_frame", 51.2, 21.0, y=6.5, name="DryingFrameWest", check=False)
    place("Roof", "warehouse_drying_frame", 57.0, 17.5, y=6.5, name="DryingFrameEast", flip=True, check=False)
    place("Roof", "laundry_wave", 54.6, 23.4, y=6.5, name="Laundry", check=False)

    # Façade : lanterne à cristal de la porte (la seule lumière du dehors), gouttières aux angles,
    # lierre à l'ouest, jardinières sous quelques fenêtres de l'étage.
    place("Facade", "wall_lantern", 40.6, FACADE_Z, y=1.6, name="DoorLantern", check=False)
    for k, x in enumerate((30.2, 47.8, 59.8)):
        place("Facade", "drainpipe", x, FACADE_Z, y=0.0, name="Drainpipe%d" % (k + 1), check=False)
        place("Facade", "drainpipe", x, FACADE_Z, y=2.5, name="DrainpipeTop%d" % (k + 1), check=False)
    place("Facade", "ivy_wall_a", 31.1, FACADE_Z, y=0.0, name="IvyWest", check=False)
    place("Facade", "ivy_wall_b", 58.4, FACADE_Z, y=3.8, name="IvyEast", check=False)
    # Jardinières sous les fenêtres de l'étage (warehouse_front_a et _b, x en m depuis le bord gauche).
    upper = [30 + x for x in (1.55, 4.45, 7.35, 10.2, 14.5, 16.6)] + [48 + x for x in (1.8, 5.0, 7.4, 10.2)]
    for k, x in enumerate(upper):
        place("Facade", "window_box", x, FACADE_Z, y=3.62, name="WindowBox%d" % (k + 1), check=False)

    # Porche et banc, parterres, pots, tonneau (2.5).
    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        if n == "warehouse_porch":
            place("Porch", "warehouse_porch", x, z, y=0.0, name="Porch")
        elif n == "flower_bed":
            w = d.rect.x1 - d.rect.x0
            count = int(round(w / prop("flower_bed").w))
            for k in range(count):
                fx = d.rect.x0 + (k + 0.5) * w / count
                place("Porch", "flower_bed", fx, z, y=0.0, flip=k % 2 == 1)
        elif n in ("flower_pots", "rain_barrel"):
            place("Porch", n, x, z, name=n.title().replace("_", ""))
        elif n == "wall_lantern":
            pass
        elif n == "climbing_tree":
            place("Yard", "climbing_tree_fg", x, z, name="ClimbingTree")
        elif n == "vegetable_patch":
            place("Garden", n, x, z)
        elif n in ("garden_tools", "wheelbarrow", "watering_can", "firewood_pile"):
            place("Garden", n, x, z, name=n.title().replace("_", ""))
        elif n == "chalk_hopscotch":
            place("Yard", n, x, z, name="Hopscotch")
        elif n == "toys_a":
            place("Yard", n, x, z, name="Toys")
        elif n in ("stump_axe", "stump_a", "stump_b"):
            place("Woods", n, x, z, name=n.title().replace("_", ""))
        elif n in ("bench_b", "stick_rack"):
            place("Clearing", n, x, z, name=n.title().replace("_", ""))
        elif n in ("reeds", "reeds_b", "marsh_snag"):
            place("Marsh", n, x, z, name=n.title().replace("_", ""))
        elif n == "play_goal":
            place("Field", n, x, z, name="GoalWhite")
        elif n == "play_goal_red":
            place("Field", "play_goal_red_fg", x, z, name="GoalRed")
        elif n in ("thicket_a", "thicket_b", "thicket_c"):
            group = "Field" if x > 80 else "Woods"
            place(group, n, x, z, name="%s_%d_%d" % (n.title().replace("_", ""), x, z))
        elif n == "bramble_hedge":
            place("Field", n, x, z, name="Hedge%d" % x)
        elif n == "ball":
            place("Field", n, x, z, name="Ball", check=False)
        elif n == "boardwalk":
            place("Marsh", n, x, z, name="Boardwalk")
        elif n in ("fern_a", "bush_c"):
            place("Woods", n, x, z, name="%s_plan" % n)
        else:
            p.warnings.append("décor du plan non posé : %s" % n)

    for t in M.trees:
        x, z = (t.rect.x0 + t.rect.x1) / 2.0, (t.rect.z0 + t.rect.z1) / 2.0
        place("Trees", t.name, x, z, name="%s_plan" % t.name.title().replace("_", ""))

    # Murs d'arrière-plan du nord : la lisière (16 m), une trouée pour le chemin de la colline.
    lisiere_y = 1.0
    for k, (x, scene) in enumerate(((4.0, "forest_wall_c"), (24.0, "forest_wall_a"), (40.0, "forest_wall_b"),
                                    (56.0, "forest_wall_c"), (72.0, "forest_wall_a"), (88.0, "forest_wall_b"))):
        place("Lisiere", scene, x, 3.7, y=lisiere_y, name="ForestWall%d" % (k + 1), flip=k % 2 == 1, check=False)
    place("Lisiere", "treeline_autumn_a_village", 14.0, -5.0, y=lisiere_y, name="TreelineBeyond", check=False)

    walk_grid()

    # === 2. Kits par bande (2.6) =========================================================================

    TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c"]
    TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn"]
    BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f", "berry_bush", "berry_bush_b"]
    FERNS = ["fern_a", "fern_b", "fern_c", "fern_d"]
    GRASSES = ["grass_clump_a", "grass_clump_b", "grass_clump_c", "grass_clump_d", "tall_grass"]
    FLOWERS = ["wildflowers_a", "wildflowers_b", "myosotis_b"]


    def free(blocking=False, decal=False, places=True, paths=True, half=(0.4, 0.3)):
        def ok(x, z):
            if not in_map(x, z, 0.2):
                return False
            return not keep_out(x, z, half, blocking, places=places, paths=paths, decal=decal)
        return ok


    def outside_edges(x, z, margin=0.0):
        return not any(e.has(x, z, margin) for e in EDGES)


    # Lisière : un rang d'arbres devant les pans de forêt, un tous les 3 à 5 m, puis un second rang
    # derrière le bâtiment (au-dessus de son toit, la lisière d'or et de rouille).
    row = []
    x = 1.5
    while x < W - 1:
        if not (10.0 < x < 18.0):
            row.append((x + rng.uniform(-0.6, 0.6), rng.uniform(4.2, 4.7)))
        x += rng.uniform(3.2, 4.8)
    scatter("LisiereGold", TREES_GOLD, [p for k, p in enumerate(row) if k % 2 == 0], seed=11)
    scatter("LisiereRust", TREES_RUST, [p for k, p in enumerate(row) if k % 2 == 1], seed=12)
    behind = poisson(Rect(27, 5.5, 63, 11.2), 4.2, 14, lambda x, z: not any(b.has(x, z, 0.6) for b in BUILDINGS)
                     and abs(x - 28) + abs(z - 12.8) > 2.5, seed=13)
    scatter("BehindTrees", ["pine_tall_b", "tree_old_pine", "beech_a", "oak_a", "maple_a"], behind, seed=14)
    scatter("BehindBushes", BUSHES[:6], poisson(Rect(26.5, 9, 63.5, 11.8), 2.0, 16,
                                                 lambda x, z: not any(b.has(x, z, 0.3) for b in BUILDINGS + blockers),
                                                 seed=15), seed=16, check=False)
    # Fougères et buissons au pied du talus de la lisière (bas, on passe devant).
    foot = []
    x = 0.8
    while x < W:
        z = rng.uniform(5.15, 5.7)
        if not (11.0 < x < 17.0) and not (30 < x < 60) and keep_out(x, z, (0.5, 0.3), False, places=False) is False:
            foot.append((x, z))
        x += rng.uniform(1.4, 2.4)
    scatter("LisiereFerns", FERNS + ["bush_e", "heather"], foot, seed=17, check=False)

    # Abords du bâtiment : rien de plus de 1,2 m devant la façade ; seau, panier, balai.
    place("Facade", "bucket", 33.2, 26.75, name="Bucket")
    # Le long du pignon ouest (chemin de terre battue de la clairière à la porte de service).
    place("Facade", "rain_barrel", 29.35, 15.4, name="RainBarrelWest")
    place("Facade", "laundry_basket", 29.4, 17.2, name="BasketWest")
    place("Facade", "flower_pots", 29.3, 24.6, name="FlowerPotsWest")
    place("Facade", "bucket", 26.6, 14.6, name="BucketWest")
    garden_rim = poisson(Rect(16.0, 24.4, 27.5, 30.6), 1.1, 18,
                         lambda x, z: free()(x, z) and not Rect(18.6, 25.2, 24.4, 29.8).has(x, z), seed=30)
    scatter("GardenRim", ["wildflowers_b", "grass_clump_d", "myosotis_b", "grass_clump_b", "heather"], garden_rim,
            seed=31, check=False)
    foot = [(x + rng.uniform(-0.2, 0.2), rng.uniform(26.45, 26.9)) for x in
            [30.5, 31.4, 38.9] + [52.9 + k * 0.85 for k in range(8)]]
    foot = [p for p in foot if free()(p[0], p[1])]
    scatter("FacadeFoot", ["grass_clump_d", "wildflowers_b", "grass_clump_b", "myosotis_b"], foot, seed=32,
            check=False)
    place("Facade", "flower_pots", 34.6, 27.1, name="FlowerPotsMid")
    place("Facade", "flower_pots", 46.8, 27.05, name="FlowerPotsPorch")
    place("Facade", "toys_b", 36.8, 27.4, name="ToysFacade")
    flank = [(26.4 + rng.uniform(-0.1, 0.25), z) for z in (13.6, 15.8, 17.6, 19.4, 21.6, 23.4)]
    scatter("FlankGrass", ["grass_clump_b", "grass_clump_d", "wildflowers_b", "fern_c"], flank, seed=19, check=False)
    # Le bord de la cour, où l'herbe mange la terre battue (hors de la place).
    rim_cour = []
    for k in range(64):
        angle = k / 40.0 * math.tau
        x = 44 + math.cos(angle) * rng.uniform(13.2, 14.6)
        z = 36.6 + math.sin(angle) * rng.uniform(8.6, 9.6)
        if not PLACES["cour"].has(x, z, 0.3) and free()(x, z) and outside_edges(x, z) and z > 28.6:
            rim_cour.append((x, z))
    scatter("YardRimGrass", ["grass_clump_a", "grass_clump_d", "grass_clump_b", "wildflowers_a", "tall_grass"],
            rim_cour, seed=20, check=False)
    place("Facade", "laundry_basket", 45.7, 26.95, name="LaundryBasket")
    place("Facade", "broom_bucket", 29.45, 22.6, name="BroomBucket")
    place("Facade", "flower_pots", 57.5, 26.9, name="FlowerPotsEast")
    place("Facade", "bush_e", 60.8, 25.2, name="CornerBush")
    place("Facade", "fern_c", 29.3, 25.4, name="CornerFern")

    # Cour en terre : décalques seulement, la place du duel nue ; au plus un jouet par 20 m².
    duel = PLACES["duel"]


    def yard_ok(x, z):
        return PLACES["cour"].has(x, z) and not duel.has(x, z, 0.8) and path_distance(x, z) > -10


    for k, (x, z, scene) in enumerate(((53.4, 34.0, "chalk_drawings"), (33.5, 41.5, "pebbles_a"),
                                        (54.5, 31.5, "pebbles_b"), (50.2, 41.2, "footprints"),
                                        (34.0, 34.0, "footprints"), (55.0, 43.0, "pebbles_a"),
                                        (33.6, 37.6, "leaves_rust_a"), (54.8, 39.4, "leaves_gold_b"),
                                        (31.6, 28.6, "puddle_a"), (51.4, 29.6, "pebbles_b"),
                                        (34.2, 29.2, "chalk_drawings"), (50.8, 31.4, "leaves_scatter"),
                                        (37.0, 44.2, "pebbles_a"), (46.8, 44.6, "leaves_gold_a"))):
        place("Yard", scene, x, z, name="YardDecal%d" % (k + 1), flip=k % 2 == 1)
    # Dans la place du duel, rien que des décalques : traces de pas, cailloux, quelques feuilles.
    for k, (x, z, scene) in enumerate(((39.2, 36.4, "footprints"), (45.6, 39.6, "footprints"),
                                        (38.4, 41.8, "pebbles_a"), (46.4, 32.6, "pebbles_b"),
                                        (41.6, 32.2, "leaves_rust_b"))):
        place("Yard", scene, x, z, name="DuelDecal%d" % (k + 1), flip=k % 2 == 0)
    yard_decals = poisson(Rect(31.5, 28.6, 56.5, 45.0), 1.7, 40,
                          lambda x, z: not duel.has(x, z, 1.2) and not PLACES["coin_soleil"].has(x, z), seed=21)
    # (QC) Pas de traces de pas tirées au hasard : la même traînée, à dix angles, faisait des
    # pistes de fourmis en travers de la cour (docs/QUALITE.md, QC-04) ; restent les quatre posées.
    scatter("YardDecals", ["pebbles_a", "leaves_rust_a", "pebbles_b", "leaves_gold_b"], yard_decals,
            scale=(0.8, 1.1), seed=22, check=False)
    duel_decals = poisson(Rect(36.5, 31.5, 47.5, 42.5), 2.3, 14,
                          lambda x, z: abs(x - 42) + abs(z - 37) > 2.0, seed=23)
    scatter("DuelDecals", ["pebbles_b", "pebbles_a"], duel_decals, scale=(0.8, 1.0), seed=24,
            check=False)
    place("Yard", "toys_b", 33.6, 31.0, name="ToysWest")
    place("Yard", "ball", 54.2, 37.6, name="YardBall", check=False)
    place("Yard", "toys_a", 33.2, 43.4, name="ToysSouthWest")
    # Au plus un jouet par 20 m² de cour (2.6) : ballons et jouets qui traînent hors du duel.
    for k, (x, z, scene) in enumerate(((52.6, 35.8, "toys_b"), (34.4, 38.8, "ball"), (55.0, 41.2, "toys_a"),
                                        (50.2, 30.0, "ball"), (32.6, 35.6, "toys_b"))):
        place("Yard", scene, x, z, name="YardToy%d" % (k + 1), flip=k % 2 == 1, check=False)

    # Champ : la place nue (on y court), deux usures de boue aux buts, des traces ; fourrés serrés à
    # l'est et au nord, rien de haut au sud.
    place("Field", "mud_patch", 75.2, 9.6, name="MudNorth")
    place("Field", "mud_patch", 74.6, 26.3, name="MudSouth", flip=True)
    place("Field", "footprints", 70.5, 17.0, name="FieldPrints")
    place("Field", "footprints", 79.8, 21.5, name="FieldPrints2", flip=True)
    place("Field", "footprints", 72.4, 24.0, name="FieldPrints3")
    place("Field", "leaves_rust_b", 82.6, 12.0, name="FieldLeaves")
    place("Field", "leaves_gold_a", 81.8, 25.2, name="FieldLeaves2")
    place("Field", "clover_patch", 68.6, 21.4, name="FieldClover")
    field_decals = poisson(Rect(66.5, 8.5, 83.5, 27.5), 3.2, 16,
                           lambda x, z: abs(x - 75) + abs(z - 18) > 2.5 and abs(x - 75) > 2.0, seed=25)
    # (QC) Ni traces ni boue tirées au hasard : sur l'herbe sèche, les plaques de boue se lisaient
    # comme des carrés bêchés (docs/QUALITE.md, QC-05) ; restent les usures des buts et trois traces.
    scatter("FieldDecals", ["leaves_gold_a", "clover_patch", "leaves_rust_b"], field_decals,
            scale=(0.8, 1.05), seed=26, check=False)
    field_rim = []
    for z in [6.3 + k * 1.15 for k in range(21)]:
        field_rim.append((64.9 + rng.uniform(-0.4, 0.5), z))
        if not 9.0 < z < 11.0 and not 16.0 < z < 18.0 and not 23.0 < z < 25.0:
            field_rim.append((84.2 + rng.uniform(-0.3, 0.3), z))
    for x in [66.5 + k * 1.2 for k in range(15)]:
        field_rim.append((x, 29.4 + rng.uniform(-0.6, 0.6)))
        if not 72.0 < x < 78.0:
            field_rim.append((x, 6.9 + rng.uniform(-0.3, 0.3)))
    field_rim = [p for p in field_rim if free()(p[0], p[1]) and outside_edges(p[0], p[1], 0.2)]
    scatter("FieldRim", ["grass_clump_a", "grass_clump_c", "wildflowers_a", "grass_clump_d", "tall_grass", "fern_b"],
            field_rim, seed=27, check=False)
    for k, (x, z, scene) in enumerate(((67.6, 5.7, "thicket_b"), (76.0, 5.5, "thicket_a"), (84.0, 5.8, "thicket_b"))):
        place("Field", scene, x, z, name="NorthThicket%d" % (k + 1))
    place("Field", "bush_d", 85.6, 13.6, name="EastBush1")
    place("Field", "berry_bush", 85.4, 20.6, name="EastBush2")
    place("Field", "bush_f", 85.5, 27.4, name="EastBush3")
    grove = [(87.0 + rng.uniform(-0.3, 0.6), z) for z in (6.5, 10.2, 14.0, 18.2, 22.0, 26.0, 30.0, 33.6)]
    scatter("Grove", ["oak_d", "beech_b", "pine_tall_b", "maple_c", "oak_a"], grove, seed=19)
    south_field = poisson(Rect(64.5, 29.0, 86.0, 31.5), 1.6, 18, free(), seed=20)
    scatter("FieldSouthGrass", GRASSES + FLOWERS, south_field, seed=21, check=False)
    west_field = poisson(Rect(62.6, 6.0, 65.6, 29.0), 1.8, 12, free(), seed=22)
    scatter("FieldWestGrass", GRASSES[:4] + ["bush_e", "fern_b"], west_field, seed=23, check=False)

    # Clairière d'entraînement : la place nue ; mousse, trèfle et fleurs au bord ; bâtons au sol près
    # du râtelier.
    for k, (x, z, scene) in enumerate(((24.0, 10.2, "branches_a"), (25.2, 9.0, "branches_b"),
                                        (8.4, 21.4, "moss_patch_a"), (24.6, 17.4, "clover_patch"),
                                        (7.8, 9.6, "moss_patch_b"), (22.5, 7.2, "clover_patch"),
                                        (12.0, 12.5, "clover_patch"), (18.2, 19.2, "moss_patch_b"),
                                        (21.0, 10.4, "leaves_rust_a"), (10.4, 17.6, "pebbles_b"))):
        place("Clearing", scene, x, z, name="ClearingDecal%d" % (k + 1), flip=k % 2 == 1)
    clearing_decals = poisson(Rect(7.5, 8.5, 22.5, 22.5), 3.0, 12, lambda x, z: abs(x - 15) + abs(z - 15) > 2.0,
                              seed=28)
    scatter("ClearingDecals", ["moss_patch_a", "clover_patch", "leaves_rust_a", "moss_patch_b", "pebbles_b"],
            clearing_decals, scale=(0.8, 1.05), seed=29, check=False)
    rim = []
    for x in [6.5 + k * 1.2 for k in range(17)]:
        rim.append((x + rng.uniform(-0.3, 0.3), 23.6 + rng.uniform(-0.2, 0.25)))
    for z in [6.4 + k * 1.3 for k in range(13)]:
        rim.append((6.45 + rng.uniform(-0.1, 0.2), z + rng.uniform(-0.3, 0.3)))
    for z in (6.4, 8.2, 9.8, 16.6, 18.0, 19.0, 21.0):
        rim.append((25.4 + rng.uniform(-0.2, 0.2), z))
    for x in [7.0 + k * 1.4 for k in range(13)]:
        rim.append((x + rng.uniform(-0.3, 0.3), 7.3 + rng.uniform(-0.3, 0.4)))
    rim = [p for p in rim if free()(p[0], p[1])]
    scatter("ClearingRim", GRASSES[:4] + FLOWERS + ["fern_b", "fern_c"], rim, seed=24, check=False)

    # Marais de l'ouest : roseaux en touffes tous les 2 m, massettes, touradons, nénuphars, brume.
    marsh = poisson(Rect(0.4, 4.6, 5.8, 29.6), 1.9, 40, free(), seed=25)
    scatter("MarshReeds", ["reeds", "reeds_b", "cattails", "reeds_sway"], marsh[::2], seed=26, check=False)
    scatter("MarshHummocks", ["marsh_hummock_a", "marsh_hummock_b"], marsh[1::2], scale=(0.9, 1.15), seed=27,
            check=False)
    for k, (x, z) in enumerate(((2.6, 7.0), (3.3, 13.4), (2.3, 18.2), (3.0, 24.0))):
        place("Marsh", "lily_pads", x, z, name="LilyPads%d" % (k + 1), flip=k % 2 == 1)
    for k, (x, z) in enumerate(((3.0, 10.0), (3.0, 21.0), (6.5, 50.0), (3.0, 56.0))):
        place("Marsh", "mist_patch", x, z, name="Mist%d" % (k + 1), flip=k % 2 == 0)
    # Au-delà du bord ouest, des saules et des aulnes en toile de fond (on ne passe pas derrière).
    for k, (x, z, scene) in enumerate(((-3.5, 8.0, "willow"), (-3.0, 16.0, "alder"), (-3.6, 24.5, "willow"))):
        place("Marsh", scene, x, z, y=-0.5, name="MarshBackdrop%d" % (k + 1), check=False)

    # Bord ouest (forêt du village, 2.12 : bord foret 0 30 2 38 et 0 42 2 44).
    west = [(1.0, 31.0), (1.2, 34.5), (0.8, 37.4), (1.1, 43.3)]
    scatter("WestTrees", ["oak_b", "beech_c", "maple_a", "tree_autumn"], west, seed=28)
    scatter("WestBushes", BUSHES[2:], [(2.6, 32.6), (2.4, 36.2), (2.8, 43.6)], seed=29, check=False)

    # Coin d'herbe au soleil : un gros tronc et un seau à son bord (VEX, prologue, ill.).
    place("Meadow", "log_hollow", 15.4, 34.0, name="SunLog")
    place("Meadow", "bucket", 27.7, 32.3, name="SunBucket")
    sun_rim = poisson(Rect(15.0, 29.5, 29.5, 37.5), 1.5, 20,
                      lambda x, z: free()(x, z) and not PLACES["coin_soleil"].has(x, z, 0.2), seed=30)
    scatter("SunFlowers", FLOWERS + ["grass_clump_d", "grass_clump_b"], sun_rim, seed=31, check=False)

    # Prés (au sud de la clairière, autour du potager, à l'est de la cour) : touffes et fleurs, pas
    # de sol nu de plus de 6 × 6 m.
    meadow = []
    for area, n, seed in ((Rect(6.5, 24.6, 18.5, 30.5), 22, 32), (Rect(2.5, 30.5, 16.0, 37.5), 22, 33),
                          (Rect(2.5, 42.6, 37.0, 44.6), 14, 34), (Rect(57.5, 30.5, 64.0, 36.0), 10, 35),
                          (Rect(57.5, 40.6, 86.0, 44.4), 22, 36), (Rect(46.0, 44.8, 57.0, 46.0), 6, 37),
                          (Rect(31.0, 26.6, 60.0, 28.3), 0, 38), (Rect(60.5, 12.5, 64.0, 16.0), 4, 39),
                          (Rect(26.2, 28.5, 31.0, 30.0), 3, 40), (Rect(84.0, 31.5, 87.0, 44.0), 8, 41)):
        if n:
            meadow += poisson(area, 1.45, n, free(), seed=seed)
    scatter("MeadowGrass", GRASSES, meadow[::2], seed=42, check=False)
    scatter("MeadowFlowers", FLOWERS + ["heather", "thistle"], meadow[1::2], seed=43, check=False)
    low_bushes = poisson(Rect(2.5, 30.5, 16.0, 37.5), 3.5, 4, free(blocking=False), seed=44) + \
        poisson(Rect(57.5, 40.6, 86.0, 44.4), 4.0, 6, free(), seed=45)
    scatter("MeadowBushes", ["bush_b", "bush_d", "berry_bush_b", "bush_f"], low_bushes, seed=46, check=False)

    # Bords de chemin : une touffe tous les 1 à 2 m, jamais dans la bande libre ; pierres plates.
    edge = []
    for name, width, pts in PATHS:
        if name in ("vers_clairiere",):
            continue
        edge += along(pts, 1.6, width / 2.0 + 0.7, 0.4, seed=len(edge) + 50)
    edge = [p for p in edge if free()(p[0], p[1]) and outside_edges(p[0], p[1], 0.2)]
    scatter("PathGrass", ["grass_clump_a", "grass_clump_c", "tall_grass", "grass_clump_d"], edge[::3], seed=60,
            check=False)
    scatter("PathFlowers", ["wildflowers_a", "wildflowers_b"], edge[1::3], seed=61, check=False)
    scatter("PathStones", ["rock_small_a", "rock_small_b", "rock_small_c", "rock_small_d", "fern_c"], edge[2::3],
            seed=62, check=False)
    # (QC) Les pierres de gué (`stepping_stones` : quatre pierres dans l'eau claire) ne vont que
    # dans l'eau : semées tous les 7 m sur les chemins secs, elles faisaient des flaques bleues en
    # travers de la terre (docs/QUALITE.md, QC-03). Un seul gué, sur la rivière, en aval du
    # puisage.
    place("Marsh", "stepping_stones", 4.3, 49.4, name="GueRiviere", check=False)
    borders = []
    for name, width, pts in PATHS:
        if name in ("vers_village", "vers_sentier"):
            borders += along(pts, 3.6, width / 2.0 + 0.2, 0.1, seed=64 + len(borders), with_yaw=True)
    borders = [p for p in borders if not PLACES["cour"].has(p[0], p[1], 0.5) and in_map(p[0], p[1], 0.5)]
    scatter("PathEdges", ["grass_edge_a", "grass_edge_b"], borders, scale=(0.9, 1.1), seed=65, check=False)

    # Bois du sud (z 44 → 60) : sous-bois bas, souches, champignons, feuilles ; jeunes arbres et
    # grands troncs en premier plan seulement ; rien de haut près des chemins.


    def woods_ok(min_path=1.0):
        def ok(x, z):
            if not in_map(x, z, 0.4) or z < 44.5:
                return False
            if x < 14.5 and z > 43.5:
                return False
            return free()(x, z) and path_distance(x, z) > min_path and outside_edges(x, z, 0.3)
        return ok


    under = poisson(Rect(14.5, 44.5, 87.5, 58.0), 1.55, 170, woods_ok(0.3), seed=70)
    scatter("WoodsBushes", BUSHES, under[0::4], seed=71, check=False)
    scatter("WoodsFerns", FERNS + ["fern_a"], under[1::4], seed=72, check=False)
    scatter("WoodsGrass", ["grass_clump_c", "nettles", "ivy_ground", "thistle", "grass_clump_a"], under[2::4],
            seed=73, check=False)
    scatter("WoodsMushrooms", ["mushroom", "mushroom_cep", "mushroom_chanterelle", "fern_c"], under[3::8], seed=74,
            check=False)
    logs = poisson(Rect(16, 46, 86, 56.5), 9.0, 7, lambda x, z: free(blocking=True, half=(1.6, 0.5))(x, z)
                   and woods_ok(1.5)(x, z), seed=75)
    scatter("WoodsLogs", ["log_hollow", "stump_b", "log_pile_forest", "stump_a"], logs, scale=(0.9, 1.05), seed=76)
    young = poisson(Rect(16, 47.5, 86, 56.5), 5.5, 16, lambda x, z: woods_ok(2.5)(x, z)
                    and free(blocking=True, half=(0.4, 0.4))(x, z), seed=77)
    scatter("WoodsYoung", ["sapling_a", "birch_a", "pine_small_a", "birch_b", "pine_small_b"], young, seed=78)
    leaves = poisson(Rect(15, 45, 87, 59), 4.0, 30, lambda x, z: in_map(x, z, 0.8) and path_distance(x, z) > -0.5,
                     seed=79)
    scatter("WoodsLeaves", ["leaves_gold_a", "leaves_rust_a", "leaves_gold_b", "leaves_rust_b", "leaves_scatter"],
            leaves, scale=(0.9, 1.15), seed=80, check=False)
    shade = poisson(Rect(16, 47, 86, 58), 9.0, 8, lambda x, z: True, seed=81)
    scatter("WoodsShade", ["canopy_shadow_a", "canopy_shadow_b", "sun_dapple"], shade, scale=(0.9, 1.1), seed=82,
            check=False)
    # Bord sud : grands troncs, buissons et fougères de premier plan.
    south = []
    x = 15.0
    while x < W - 1:
        if not 35.5 < x < 44.5:
            south.append((x + rng.uniform(-0.5, 0.5), rng.uniform(58.6, 59.5)))
        x += rng.uniform(4.0, 6.0)
    scatter("SouthTrunks", ["fg_trunk_a", "fg_trunk_b"], south[::4], seed=83, check=False)
    scatter("SouthBrush", ["fg_bush", "fg_fern", "fg_grass"], [p for k, p in enumerate(south) if k % 4], seed=84,
            check=False)
    scatter("SouthBrushWest", ["fg_bush", "fg_fern"], [(2.0, 59.2), (8.5, 59.4), (12.8, 58.8)], seed=85, check=False)

    # Marais du sud-ouest et rivière : roseaux, massettes, touradons ; l'aulne du plan.
    sw = poisson(Rect(0.4, 44.6, 13.8, 59.4), 2.1, 24, lambda x, z: free()(x, z) and abs(x - 9.5) + abs(z - 49.5) > 2.2,
                 seed=90)
    scatter("SouthMarshReeds", ["reeds", "cattails", "reeds_b", "reeds_sway"], sw[::2], seed=91, check=False)
    scatter("SouthMarshHummocks", ["marsh_hummock_a", "marsh_hummock_b", "fern_d"], sw[1::2], seed=92, check=False)

    # Est : entre le chemin du sentier et les bois, sous la lisière du bosquet.
    east = poisson(Rect(84.5, 41.0, 87.5, 57.5), 2.4, 6, free(), seed=93)
    scatter("EastBrush", ["bush_d", "fern_d", "bush_b"], east, seed=94, check=False)

    # Ombres des arbres et taches de soleil sous la lisière et le grand arbre (2.9).
    for k, (x, z, scene) in enumerate(((62.4, 33.6, "canopy_shadow_a"), (20.0, 8.0, "canopy_shadow_b"),
                                        (8.0, 6.6, "sun_dapple"), (46.0, 7.2, "canopy_shadow_a"))):
        place("Trees", scene, x, z, name="Shade%d" % (k + 1))
    place("Yard", "leaves_gold_a", 61.0, 34.6, name="TreeLeaves")
    place("Yard", "leaves_rust_b", 64.0, 33.4, name="TreeLeaves2")

    # (QO, docs/QUALITE.md, QC-27) Bordures habitées : le duel (place duel), le jeu de balle (place champ :
    # buts, centre, places de la vie) et les places de la vie restent nus, mais le pourtour de la cour (entre
    # le duel et le bord de la cour) et le bord du champ sont ceux d'une maison d'enfants : bancs, jouets,
    # lessive, seaux, brouette, bûches. Posés en dernier, à la main et sans tirage (le reste de la carte ne
    # bouge pas), loin des chemins, des points et des places de la vie ; rien de plus haut que 1,2 m ; dans
    # les places cour et champ, rien qui bloque (bancs, jouets, seaux, paniers), le reste juste au dehors.
    life = [(42.5, 30.75), (42.5, 31.75), (44.0, 37.0), (51.0, 40.0), (44.2, 28.8), (42.0, 28.2),
            (73.5, 23.0), (75.0, 19.5), (75.0, 16.5), (75.3, 18.2), (75.0, 9.2), (75.0, 26.6), (75.0, 18.0),
            (83.3, 10.0), (83.6, 17.0)]
    rim = [
        # Cour, à l'ouest du duel : le coin de la lessive (baquet au bord, panier, seau) au nord, un banc
        # tourné vers le duel ; au sud, des bûches et des souches pour s'asseoir ; à l'est, un banc entre le
        # duel et la marelle, la brouette et une caisse au bord, un seau.
        ("Yard", "wash_tub", 31.3, 32.6), ("Yard", "laundry_basket", 34.7, 33.0), ("Yard", "bucket", 32.6, 33.8),
        ("Yard", "bench_b", 33.6, 36.8),
        ("Yard", "log_pile_forest", 35.2, 45.0), ("Yard", "stump_a", 38.2, 44.6), ("Yard", "stump_b", 49.8, 44.6),
        ("Yard", "bench", 52.2, 31.8), ("Yard", "wheelbarrow", 57.0, 33.4), ("Yard", "crate", 56.6, 43.0),
        ("Yard", "bucket", 54.2, 43.4),
        # Champ, au bord ouest (où l'on ne joue pas) : les bancs des spectatrices, des jouets, le seau d'eau
        # et un ballon de rechange ; au sud, une souche et des jouets, des bûches hors du champ ; au nord,
        # derrière la cage blanche, une souche.
        ("Field", "bench", 67.0, 12.4), ("Field", "toys_a", 67.2, 14.4), ("Field", "bucket", 67.6, 15.6),
        ("Field", "bench_b", 67.0, 22.4), ("Field", "ball", 67.8, 24.2),
        ("Field", "stump_b", 69.2, 28.7), ("Field", "toys_b", 80.8, 27.0), ("Field", "log_pile_forest", 65.6, 29.6),
        ("Field", "stump_a", 81.2, 7.0),
    ]
    duel = PLACES["duel"]
    for k, (group, scene, x, z) in enumerate(rim):
        half = prop(scene).half if prop(scene).blocks else (prop(scene).w / 2.0, 0.2)
        crowded = any(abs(x - lx) < half[0] + 1.2 and abs(z - lz) < half[1] + 1.2 for lx, lz in life)
        if crowded or duel.hits(Rect(x - half[0], z - half[1], x + half[0], z + half[1]), 0.6) or keep_out(
                x, z, half, prop(scene).blocks, places=False):
            p.warnings.append("bordure : %s en (%.1f ; %.1f) gêne le duel, la vie, un chemin ou un point" % (scene, x, z))
        place(group, scene, x, z, name="Rim%s%d" % (group, k + 1), flip=k % 2 == 1)


def ground_plan(M):
    """Le plan.json du sol (CARTE.md 2.3 et 2.12) : paliers, rampes, matières, eau basse."""
    def rect(r):
        return [r.x0, r.z0, r.x1 - r.x0, r.z1 - r.z0]


    # Matières du plan (tuiles de l'atlas) → matières de la carte (bibliothèque ou propres).
    MATERIALS = {
        "herbe_drue": {"label": "Herbe drue et molle de la clairière (grass_b)", "layer": "grass_b",
                       "color": "#4f9a46", "variant": False},
        "chemin": {"label": "Chemin de terre (path_dirt_b)", "layer": "path_dirt_b", "color": "#d0a060",
                   "variant": False, "path": True},
        "eau_basse": {"label": "Eau basse du marais : on y marche (VEX)", "layer": "water", "color": "#3a70b0",
                      "walkable": True, "ripple": True, "tint": [0.78, 0.86, 0.8]},
    }

    steps = []


    def level(lv, shape, where=None):
        step = {"op": "level", "level": lv, "shape": shape}
        if where:
            step["where"] = where
        steps.append(step)


    def material(name, shape, where=None):
        step = {"op": "material", "material": name, "shape": shape}
        if where:
            step["where"] = where
        steps.append(step)


    # --- Paliers (2.12 : palier ; 0,5 m = un palier) -------------------------------------------------
    # Lisière nord à +1,0 m.
    level(2, {"rect": [0, 0, 88, 5]})
    # Clairière d'entraînement à +0,5 m, jusqu'au talus de la lisière (pas de fossé d'un mètre entre
    # elles : la rangée z 5 → 6 suit la clairière).
    level(1, {"rect": [6, 5, 20, 19]})
    # Champ, marais de l'ouest et du sud-ouest, creux des bois du sud à −0,5 m.
    level(-1, {"rect": [64, 5, 24, 26]})
    # Marais et creux des bois : berges irrégulières (± 1 m autour du rectangle du plan), gardées
    # franches au pied des rampes.
    level(-1, {"rect": [0, 4, 6, 26], "noise": 1.6, "noise_scale": 2.2, "seed": 41}, {"levels": [0]})
    # (QC) Le cœur du marais de l'ouest s'arrête à x = 5 : à 6, sa berge était une droite de 20 m,
    # une couture visible du pré au marais (docs/QUALITE.md, QC-06) ; le bruit fait la berge.
    level(-1, {"rect": [0, 4, 5, 20]})
    level(-1, {"rect": [0, 4, 4.5, 26]})
    level(-1, {"rect": [0, 26, 6, 4]})
    level(-1, {"rect": [0, 44, 14, 16], "noise": 1.8, "noise_scale": 2.6, "seed": 42}, {"levels": [0]})
    level(-1, {"rect": [0, 45.5, 11.5, 14.5]})
    level(-1, {"rect": [30, 56, 30, 4], "noise": 1.5, "noise_scale": 2.4, "seed": 43}, {"levels": [0]})
    level(-1, {"rect": [31, 57, 28, 3]})
    level(-1, {"rect": [29, 56, 3, 4]})
    level(-1, {"rect": [36, 56, 12, 1]})
    # Toutes les faces en talus de terre (cliff/step_earth, wall_earth_1m, step_marsh à venir).
    steps.append({"op": "face", "face": "earth", "shape": {"rect": [0, 0, 88, 60]}})

    # --- Sol (2.12 : sol ; le dernier posé l'emporte) -------------------------------------------------
    material("sous_bois", {"rect": [0, 0, 88, 6], "noise": 0.8, "noise_scale": 2.5, "seed": 1})
    material("sous_bois", {"rect": [0, 44, 88, 16], "noise": 1.2, "noise_scale": 3, "seed": 2})
    material("sous_bois", {"rect": [84, 6, 4, 38], "noise": 0.8, "noise_scale": 2.5, "seed": 3})
    material("feuilles", {"ellipse": [24, 52, 7, 3.5], "noise": 1.4, "noise_scale": 2.5, "seed": 4},
             {"material": "sous_bois"})
    material("feuilles", {"ellipse": [62, 50, 9, 3.5], "noise": 1.4, "noise_scale": 2.5, "seed": 5},
             {"material": "sous_bois"})
    material("feuilles", {"ellipse": [78, 55, 7, 3], "noise": 1.4, "noise_scale": 2.5, "seed": 6},
             {"material": "sous_bois"})
    material("mousse", {"ellipse": [50, 53, 4, 2], "noise": 1.0, "noise_scale": 2, "seed": 7},
             {"material": "sous_bois"})
    material("mousse", {"ellipse": [8, 3, 4, 1.5], "noise": 0.8, "noise_scale": 2, "seed": 8})
    # Derrière le bâtiment (bord arriere) et aux coins boisés : broussailles et sous-bois.
    material("sous_bois", {"rect": [26, 4, 38, 8.5], "noise": 1.0, "noise_scale": 2.5, "seed": 16})
    material("herbe_drue", {"rect": [6, 6, 20, 18], "noise": 0.7, "noise_scale": 2.2, "seed": 9},
             {"level": 1})
    material("herbe_drue", {"rect": [6, 5, 20, 1]}, {"level": 1})
    material("herbe_haute", {"rect": [64, 6, 22, 25], "noise": 0.9, "noise_scale": 2.5, "seed": 10},
             {"level": -1})
    material("prairie", {"ellipse": [22, 33.5, 6.2, 3.6], "noise": 1.0, "noise_scale": 2, "seed": 11})
    material("potager", {"rect": [19, 25.5, 5, 4]})
    # Terre battue : la cour (V1) et les bandes le long des flancs du bâtiment.
    # La cour (31 → 57, 28 → 45) : une terre battue aux bords mangés par l'herbe, la place du duel
    # (36 → 48, 31 → 43) toujours en terre ; des îlots d'herbe et du gravier hors du duel.
    material("terre_battue", {"ellipse": [44, 36.6, 14.2, 9.4], "noise": 1.6, "noise_scale": 2.6, "seed": 12})
    material("terre_battue", {"rect": [35.4, 30.4, 13.2, 13.2], "noise": 0.4, "noise_scale": 1.8, "seed": 17})
    material("terre_battue", {"rect": [31, 28, 26, 4], "noise": 0.8, "noise_scale": 2.2, "seed": 18})
    for k, (cx, cz, rx, rz) in enumerate(((32.6, 43.2, 2.6, 1.8), (55.6, 43.0, 2.2, 2.0), (55.2, 31.8, 1.6, 1.2),
                                          (32.4, 32.6, 1.3, 1.6), (50.8, 44.4, 1.8, 0.9))):
        material("herbe", {"ellipse": [cx, cz, rx, rz], "noise": 0.7, "noise_scale": 1.5, "seed": 60 + k})
    material("gravier", {"ellipse": [38.4, 29.6, 2.4, 1.0], "noise": 0.5, "noise_scale": 1.4, "seed": 66})
    material("gravier", {"ellipse": [52.6, 39.6, 1.6, 1.2], "noise": 0.5, "noise_scale": 1.4, "seed": 67})
    material("boue", {"ellipse": [31.8, 28.0, 1.2, 0.7], "noise": 0.4, "noise_scale": 1.2, "seed": 68})
    # Le champ : l'herbe sèche usée en terre devant les cages et au milieu (V1 : le ballon).
    for k, (cx, cz, rx, rz) in enumerate(((75, 9.4, 3.0, 1.6), (75, 26.6, 3.2, 1.7), (75, 18, 3.4, 2.4),
                                          (70, 15, 1.6, 1.2), (80, 22, 1.8, 1.1))):
        material("terre_battue", {"ellipse": [cx, cz, rx, rz], "noise": 0.9, "noise_scale": 1.6, "seed": 70 + k},
                 {"level": -1})
    material("boue", {"ellipse": [75, 27.0, 1.6, 0.8], "noise": 0.5, "noise_scale": 1.2, "seed": 76}, {"level": -1})
    # La clairière : herbe drue, plaques de mousse et de feuilles sous l'arbre, herbe usée au milieu
    # (on s'y entraîne au bâton, VEX).
    for k, (name, cx, cz, rx, rz) in enumerate((("mousse", 9.0, 20.5, 2.2, 1.6), ("mousse", 23.5, 9.0, 1.8, 1.2),
                                                ("feuilles", 20.0, 8.0, 3.6, 1.8), ("herbe", 15.0, 15.5, 4.2, 3.2),
                                                ("herbe", 10.5, 11.0, 2.0, 1.4), ("feuilles", 8.5, 7.0, 2.0, 1.0))):
        material(name, {"ellipse": [cx, cz, rx, rz], "noise": 0.8, "noise_scale": 1.6, "seed": 80 + k}, {"level": 1})
    material("terre_battue", {"rect": [26, 14, 4, 16], "noise": 0.5, "noise_scale": 2, "seed": 13})
    material("terre_battue", {"rect": [60, 16, 4, 14], "noise": 0.5, "noise_scale": 2, "seed": 14})
    material("terre_battue", {"rect": [30, 26, 30, 2.4]})
    # Tourbe des marais.
    material("tourbe", {"rect": [0, 4, 6, 26]}, {"level": -1})
    material("tourbe", {"rect": [0, 44, 14, 16], "noise": 1.0, "noise_scale": 2.5, "seed": 15}, {"level": -1})
    # Eau basse du marais de l'ouest (on y marche) : des mares au milieu de la tourbe.
    for k, (cx, cz, rx, rz) in enumerate([(2.6, 7.5, 2.4, 2.8), (3.4, 13.0, 2.2, 3.0), (2.4, 18.5, 2.2, 2.6),
                                          (3.2, 23.5, 2.3, 2.8), (2.2, 28.0, 2.0, 1.8)]):
        material("eau_basse", {"ellipse": [cx, cz, rx, rz], "noise": 0.6, "noise_scale": 1.6, "seed": 20 + k},
                 {"level": -1})
    # Rivière : lit de galets et eau basse (V3 : on y puise l'eau du bain).
    steps.append({"op": "material", "material": "lit_ruisseau",
                  "shape": {"band": [[0, 45], [3.5, 47.5], [5.2, 51.5], [8, 55], [8, 61]], "width": 3.6,
                            "noise": 0.5, "noise_scale": 1.6, "seed": 30}, "where": {"level": -1}})
    # Chemins (bande libre du plan) en terre.
    for path in M.paths:
        if path.name in ("vers_clairiere", "vers_champ"):
            continue
        steps.append({"op": "path", "material": "chemin", "width": max(2.6, path.extra["l"] - 0.6),
                      "points": [list(p) for p in path.extra["pts"]], "noise": 0.35, "noise_scale": 1.6,
                      "where": {"not_material": ["potager"]}})
    # Le chemin du champ passe par sa rampe ; celui de la clairière monte par la rampe du sud-est
    # (22 → 26 ; 22 → 25), entre le potager et les outils (le tracé du plan, 27,6 ; 22 → 24 ; 19,
    # franchirait le talus de 0,5 m).
    for path in M.paths:
        if path.name == "vers_champ":
            steps.append({"op": "path", "material": "terre_battue", "width": 2.6,
                          "points": [list(p) for p in path.extra["pts"]], "noise": 0.3, "noise_scale": 1.6})
    steps.append({"op": "path", "material": "terre_battue", "width": 2.4,
                  "points": [[32, 29.5], [28, 28], [26.2, 26.2], [24, 25.2], [24, 21.5], [22, 19]],
                  "noise": 0.3, "noise_scale": 1.6, "where": {"not_material": ["potager"]}})

    # --- Rampes (2.12 : rampe x0 z0 x1 z1 Y0 Y1 sens ; une rampe monte vers le haut du palier) -----------
    for ramp in M.ramps:
        r = ramp.extra
        sens = r["sens"]
        y0, y1 = r["y0"], r["y1"]
        # Le sens est celui de la marche de Y0 vers Y1 ; la rampe « monte » vers le plus haut.
        going = {"N": "north", "S": "south", "E": "east", "O": "west"}[sens]
        opposite = {"north": "south", "south": "north", "east": "west", "west": "east"}
        direction = going if y1 > y0 else opposite[going]
        x0, z0, w, d = rect(ramp.rect)
        steps.append({"op": "ramp", "dir": direction, "rect": [int(x0), int(z0), int(w), int(d)],
                      "material": "terre_battue"})

    # (T1) Rampes ajoutées au plan : on descend au marais de l'ouest depuis le pré au sud de la
    # clairière, et au marais du sud-ouest (le puisage) depuis le chemin du village, sans sauter
    # (les PNJ de E4 ne sautent pas les marches de 0,5 m).
    steps.append({"op": "level", "level": 0, "shape": {"rect": [0, 30, 8, 3]}})
    steps.append({"op": "ramp", "dir": "south", "rect": [2, 30, 4, 2], "material": "tourbe"})
    steps.append({"op": "ramp", "dir": "north", "rect": [7, 43, 3, 2], "material": "chemin"})

    plan = {
        "_comment": "Sol en relief de l'entrepôt vu du dehors (lot T1), d'après docs/lore/CARTE.md 2.3 et 2.12 : "
                    "lisière nord à +1 m, clairière d'entraînement à +0,5 m, champ, marais et creux des bois du sud "
                    "à −0,5 m, rampes du plan, eau basse du marais (on y marche), rivière. Lu par "
                    "tools/map_build.py gen entrepot ; le jeu ne lit pas ce fichier.",
        "size": [88, 60],
        "seed": 68,
        "materials_scale": 2,
        "height_zero_value": 16,
        "edges": {"north": "land", "east": "land", "south": "land", "west": "land"},
        "skirt": 16,
        "spawn": [42, 33],
        "base": {"level": 0, "material": "herbe"},
        "materials": MATERIALS,
        "steps": steps,
    }
    return plan


def ambient(p):
    """Vie ambiante (2.11) : papillons orange au champ, au coin de soleil et au potager, oiseaux,
    feuilles qui tombent, lucioles au marais."""
    return [
        ("ButterfliesField", "butterfly", 4, 12, 2, 6, (18, 1.6, 18), 0.3, (24, 26), 0.6, 0.6, 1, (75, -0.5, 18)),
        ("ButterfliesSun", "butterfly", 4, 12, 2, 5, (12, 1.6, 10), 0.3, (16, 14), 0.6, 0.6, 2, (22, 0, 31)),
        ("Birds", "birds_flock", 6, 10, 1, 3, (40, 6, 24), 6.0, (0, 0), 4.0, 0.8, 3, (44, 0, 30)),
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 10, (26, 9, 20), 0.0, (0, 0), 0.9, 0.8, 4, (44, 0, 30)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 8, (26, 9, 20), 0.0, (0, 0), 1.1, 0.8, 5, (44, 0, 30)),
        ("Fireflies", "fireflies", 6, 8, 3, 10, (10, 2, 14), 0.2, (12, 30), 0.3, 0.6, 6, (3, -0.5, 17),
         "glow = 1.6\n"),
    ]
