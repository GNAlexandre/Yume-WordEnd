"""(C1) Le sentier et le marais : la pose de la carte `sentier` d'après docs/lore/CARTE.md, section 4
(bloc ```plan lu par tools/carte_plans.py).

Ce que dit l'œuvre (4.1) : un sentier étroit qui s'enfonce dans une forêt noire, sans lampadaire ni
aucune lumière ; au nord, un marais où l'on a vite les pieds dans l'eau (la chute de Willem, V1,
« L'Homme sans Marque ») ; de jour, un petit sentier aux pierres clairsemées, mangées d'herbe, où
le soleil filtre. Aucune lumière dans la scène : la nuit est celle d'Atmosphere (E9), la lumière
des fées du joueur éclaire 4 m autour de lui.

Composition vue de la caméra (elle regarde le nord ; CARTE.md 0.3) :
- au nord de la scène, la lisière (pans de forêt de 16 m, un rang d'arbres devant) ferme la vue ; les
  roseaux, les aulnes et les touradons du marais sont devant elle ;
- à l'ouest et à l'est du marais, deux pans de forêt dressés derrière le sentier ;
- au sud, rien de haut qui ne s'efface : la forêt est en premier plan (variantes `_forest`, `fg_*`),
  (QC) pas de voûte de feuillage (`fg_canopy_a`) suspendue : vue par la caméra, une masse sombre au
  milieu de l'écran ; elle attend le premier plan accroché à l'écran (E10) ;
- à l'est, la bifurcation : le chemin de la ville descend vers le sud-est par sa rampe.

Écarts et ajouts (docs/DECISIONS.md, C1) : voir DEVIATIONS ; le chemin de la ville (vers_ville) n'a pas de
sortie tant que la carte `ville_haute` n'existe pas (un écriteau « Plus loin, bientôt » à sa place).
"""

import math

import exterior_ground
from exterior_pose import Rect, along, poisson

SETTINGS = {
    "groups": ["Lisiere", "Marsh", "Trail", "Bank", "Woods", "Fork", "Backdrop"],
    # Le chemin de la ville : sans sortie tant que ville_haute n'existe pas.
    "omit_if_missing": ("vers_ville",),
}

# Places de la vie que le plan ne nomme pas : (nom, x, z, regard en degrés, à quoi elles servent). Écrites
# en Life/Places (Marker3D) et listées dans CARTE.md par `exterior_maps.py places`.
PLACES_WHY = [
    ("sentier_ouest", 4.0, 24.0, 0.0, "l'entrée du sentier, côté entrepôt : le passant qui arrive ou repart"),
    ("sentier_milieu", 40.0, 22.8, 0.0, "le milieu du sentier, devant le marais : les passants s'y croisent"),
    ("sentier_est", 74.0, 21.8, 0.0, "le sentier avant la sortie vers le port"),
    ("fourche_ville", 62.5, 26.9, 0.0, "le départ du chemin de la ville : le facteur, Willem au marché"),
    ("marais_berge_ouest", 24.0, 20.4, 0.0, "la berge où se tiennent les grenouilles (VIE.md, faune)"),
    ("marais_berge_est", 52.0, 20.2, 0.0, "la berge est, libellules les jours doux (VIE.md, faune)"),
    ("corbeau_perchoir", 28.0, 11.6, 0.0, "la souche noyée où se perche le corbeau (VIE.md, faune)"),
    ("lisiere_renard", 6.0, 20.6, 0.0, "la lisière ouest où le renard s'arrête avant de traverser (VIE.md)"),
    ("merle_sol", 30.0, 26.4, 0.0, "l'herbe au sud du sentier où le merle picore, à l'aube (VIE.md)"),
]

DEVIATIONS = [
    "rampes ajoutées au plan : deux descentes de la levée dans le marais, x 33 → 36 et x 52 → 55, z 18 → 20 "
    "(on y descend sans sauter : les PNJ d'E4 ne sautent pas les marches de 0,5 m)",
    "la matière `path_overgrown` (à confirmer, cahier n° 5) est peinte en `chemin` (path_dirt_b) sur la bande du "
    "chemin seulement (1,8 m de terre visible dans la bande libre de 3 m), au lieu du rectangle de 14 × 16 m "
    "du plan au sud-est",
    "pas de lucioles (CARTE.md 4.2 : absentes en fin d'automne) ; pas de rais de lumière (leur image de nuit "
    "n'existe pas : le sentier de nuit reste noir)",
]

CANOPY_LIFT = 2.6
TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c"]
TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn"]
TREES_DARK = ["pine_tall_b", "tree_old_pine", "tree_pine", "oak_a", "beech_a", "pine_dead"]
BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f", "berry_bush", "berry_bush_b"]
FERNS = ["fern_a", "fern_b", "fern_c", "fern_d"]
GRASSES = ["grass_clump_a", "grass_clump_b", "grass_clump_c", "grass_clump_d", "tall_grass"]


def ground_plan(m):
    """Le sol : le plan (paliers, matières, eau, rampes, chemins), plus les berges, les îlots de tourbe et
    l'eau libre du marais, les descentes de la levée, des plaques de mousse et de feuilles au bord du
    sentier."""
    plan = exterior_ground.ground_from_plan(
        m, noise=0.7, skip=("path_overgrown",), ramp_material="mousse",
        comment="Sol en relief du sentier et du marais (lot C1), d'après docs/lore/CARTE.md, section 4 : "
                "lisière nord à +1 m, marais à −0,5 m (tourbe, eau basse où l'on marche, îlots), levée du "
                "sentier à 0, chemin de la ville qui descend à −0,5 m par sa rampe. Lu par tools/map_build.py "
                "gen sentier ; le jeu ne lit pas ce fichier.")
    steps = plan["steps"]
    # L'eau basse du plan est un rectangle franc : le marais a de l'eau libre au milieu, de la tourbe sur
    # les berges, des îlots où poussent les touradons.
    steps[:] = [s for s in steps if s.get("material") != "eau_basse"]
    first_ramp = exterior_ground.step_index(steps, "ramp")
    marsh = [
        {"op": "material", "material": "eau_basse",
         "shape": {"rect": [17, 6, 40, 11.5], "noise": 1.5, "noise_scale": 2.2, "seed": 41}, "where": {"level": -1}},
    ]
    for k, (cx, cz, rx, rz) in enumerate(((32, 15, 1.8, 1.1), (41, 16, 1.4, 1.0), (46, 13, 1.8, 1.1),
                                          (22, 15, 2.0, 1.2), (53, 12.5, 2.2, 1.3), (27, 9.5, 1.6, 1.0))):
        marsh.append({"op": "material", "material": "tourbe",
                      "shape": {"ellipse": [cx, cz, rx, rz], "noise": 0.6, "noise_scale": 1.5, "seed": 50 + k},
                      "where": {"level": -1}})
    steps[first_ramp:first_ramp] = marsh
    # Les deux descentes de la levée dans le marais (la tourbe).
    for x in (33, 52):
        steps.insert(exterior_ground.step_index(steps, "ramp") + 1,
                     {"op": "ramp", "dir": "south", "rect": [x, 18, 3, 2], "material": "tourbe"})
    # Le creux du chemin de la ville : berges irrégulières (± 1 m autour du rectangle du plan), franches au
    # pied de la rampe (sinon une tranchée rectangulaire).
    steps[:] = [s for s in steps if not (s["op"] == "level" and s["shape"].get("rect") == [62.0, 30.0, 12.0, 10.0])]
    first = exterior_ground.step_index(steps, "face")
    steps[first:first] = [
        {"op": "level", "level": -1, "shape": {"rect": [62, 30, 12, 10], "noise": 1.6, "noise_scale": 2.4,
                                                "seed": 91}},
        {"op": "level", "level": -1, "shape": {"rect": [62, 30, 8, 3]}},
        {"op": "level", "level": -1, "shape": {"rect": [63, 32, 8, 8]}},
    ]
    # Mousse et feuilles au bord du sentier (le sol du plan est un sous-bois uni).
    patches = [("mousse", 9, 21, 3.4, 1.2), ("mousse", 27, 27.5, 3.0, 1.1), ("mousse", 44, 20.4, 3.6, 1.2),
               ("mousse", 70, 27, 2.6, 1.3), ("feuilles", 18, 27.2, 3.4, 1.2), ("feuilles", 36, 26.8, 3.6, 1.1),
               ("feuilles", 50, 20.6, 3.0, 1.1), ("feuilles", 4, 26.8, 2.4, 1.0), ("feuilles", 74, 22.6, 2.8, 1.1)]
    for k, (name, cx, cz, rx, rz) in enumerate(patches):
        steps.insert(exterior_ground.step_index(steps, "path"),
                     {"op": "material", "material": name,
                      "shape": {"ellipse": [cx, cz, rx, rz], "noise": 0.7, "noise_scale": 1.6, "seed": 80 + k},
                      "where": {"level": 0}})
    return plan


def prepare(p):
    pass


def pose(p):
    M, W = p.map, p.W
    rng = p.rng
    place, scatter = p.place, p.scatter
    in_map, outside_edges = p.in_map, p.outside_edges
    free, height, walk_grid = p.free, p.height, p.walk_grid
    PLACES, PATHS = p.places, p.paths

    # === 1. Ossature du plan (4.2) ===================================================================

    walk_grid()
    counters = {}

    def named(base):
        counters[base] = counters.get(base, 0) + 1
        return "%s_%d" % (base, counters[base])

    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        flip = len(p.singles) % 2 == 1
        if n == "marsh_reed_wall":
            place("Marsh", n, x, z, name=named("ReedWall"), flip=flip)
        elif n in ("marsh_snag", "marsh_hummock_a", "marsh_hummock_b", "reeds", "reeds_b", "cattails", "bog_pool_a",
                   "lily_pads"):
            place("Marsh", n, x, z, name=named(n.title().replace("_", "") + "_plan"), flip=flip, check=False)
        elif n in ("path_stones_a", "path_stones_b", "path_root_step", "path_edge_ferns"):
            place("Trail", n, x, z, name=named(n.title().replace("_", "") + "_plan"), flip=flip, check=False)
        elif n == "fg_canopy_a":
            place("Trail", n, x, z, y=height(x, z) + CANOPY_LIFT, name=named("Canopy"), check=False)
        elif n == "thicket_b":
            place("Fork", n, x, z, name="Thicket_plan")
        else:
            p.warnings.append("décor du plan non posé : %s" % n)
    for t in M.trees:
        x, z = (t.rect.x0 + t.rect.x1) / 2.0, (t.rect.z0 + t.rect.z1) / 2.0
        place("Marsh", t.name, x, z, name=named("Alder_plan"))

    # La lisière : des pans de 16 m au nord, bout à bout, un rang d'arbres devant ; au-delà, la forêt qui
    # continue. (QC-S) Pans et rideaux à raccord : un bout libre se voit comme une bande coupée net
    # (docs/QUALITE.md, QC-33) ; les rangs débordent donc de la carte, d'un pan de chaque côté.
    for k, (x, scene) in enumerate(((-8.0, "forest_wall_b"), (8.0, "forest_wall_c"), (24.0, "forest_wall_a"),
                                    (40.0, "forest_wall_b"), (56.0, "forest_wall_c"), (72.0, "forest_wall_a"),
                                    (88.0, "forest_wall_b"))):
        place("Lisiere", scene, x, 3.7, y=1.0, name="ForestWall%d" % k, flip=k % 2 == 0, check=False)
    for k, x in enumerate((-4.0, 12.0, 28.0, 44.0, 60.0, 76.0)):
        scene = "treeline_autumn_a_village" if k % 2 == 0 else "treeline_autumn_b_village"
        place("Lisiere", scene, x, -5.0, y=1.0, name="TreelineBeyond%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Les pans de forêt à l'ouest et à l'est du marais (les bords du plan), dressés derrière le sentier ; au
    # bord de la carte, un pan de plus ; côté marais, leur bout est caché par un saule (plus bas).
    place("Lisiere", "forest_wall_c", -8.0, 18.2, name="ForestWallWest0", flip=True, check=False)
    place("Lisiere", "forest_wall_d", 8.0, 18.2, name="ForestWallWest", check=False)
    place("Lisiere", "forest_wall_a", 66.0, 17.0, name="ForestWallEast1", check=False)
    place("Lisiere", "forest_wall_a", 82.0, 17.0, name="ForestWallEast2", check=False)

    walk_grid()

    # === 2. Kits par bande (4.2) =========================================================================

    # Lisière nord : un rang d'arbres tous les 3 à 5 m devant les pans, sur le palier de +1 m.
    row = []
    x = 1.5
    while x < W - 1:
        row.append((x + rng.uniform(-0.6, 0.6), rng.uniform(4.0, 4.6)))
        x += rng.uniform(3.2, 4.8)
    scatter("LisiereGold", TREES_GOLD, [q for k, q in enumerate(row) if k % 3 == 0], seed=11)
    scatter("LisiereRust", TREES_RUST, [q for k, q in enumerate(row) if k % 3 == 1], seed=12)
    scatter("LisiereDark", TREES_DARK, [q for k, q in enumerate(row) if k % 3 == 2], seed=13)

    # Les forêts à l'ouest et à l'est du marais : un rang de grands arbres devant leur pan, des buissons au
    # pied (le bord du plan : on n'y entre pas).
    west = [(2.5, 17.4), (7.0, 16.8), (11.5, 17.6), (14.8, 15.4), (14.6, 11.0), (14.4, 7.2)]
    scatter("WestTrees", TREES_DARK[:3] + TREES_RUST[:2], west, seed=21)
    east = [(60.0, 16.2), (64.5, 16.8), (69.0, 16.0), (73.5, 16.6), (78.0, 16.4), (59.6, 11.0), (59.6, 7.4)]
    scatter("EastTrees", TREES_GOLD[:3] + TREES_DARK[:2], east, seed=22)
    foot = [(1.2 + k * 1.9 + rng.uniform(-0.3, 0.3), rng.uniform(18.6, 19.3)) for k in range(8)]
    foot += [(58.5 + k * 1.8 + rng.uniform(-0.3, 0.3), rng.uniform(17.6, 18.3)) for k in range(12)]
    scatter("WestEastFerns", FERNS + ["bush_e", "heather"], foot, seed=23, check=False)

    # Le marais (4.2) : rideau de roseaux au fond, touffes, touradons, mares, brume.
    for x in (18.0, 26.0, 30.0, 38.0, 42.0, 50.0, 57.0):
        place("Marsh", "marsh_reed_wall", x, 6.4 + rng.uniform(0.0, 0.5), name=named("ReedWallKit"),
              flip=int(x) % 8 < 4)
    reeds = poisson(Rect(16.8, 7.2, 57.2, 17.6), 1.7, 125, free(), seed=31)
    scatter("MarshReeds", ["reeds", "reeds_b", "cattails", "reeds_sway"], reeds[::2], seed=32, check=False)
    scatter("MarshHummocks", ["marsh_hummock_a", "marsh_hummock_b"], reeds[1::3], scale=(0.9, 1.15), seed=33,
            check=False)
    north = poisson(Rect(16.8, 5.3, 57.2, 7.2), 1.15, 70, free(), seed=34)
    scatter("MarshNorth", ["reeds", "reeds_b", "cattails", "reeds_sway", "marsh_hummock_b"], north, seed=35,
            check=False)
    mid = poisson(Rect(16.8, 7.4, 57.2, 12.4), 1.7, 40, free(), seed=36)
    scatter("MarshMid", ["reeds_b", "cattails", "marsh_hummock_a", "reeds"], mid, seed=37, check=False)
    for q in ((22.0, 15.0), (53.0, 12.5), (50.0, 15.5)):
        place("Marsh", "marsh_snag", q[0], q[1], name=named("Snag"), flip=int(q[0]) % 2 == 0, check=False)
    for q in ((21.0, 10.0), (51.5, 11.0), (25.0, 13.2)):
        place("Marsh", "bog_pool_a", q[0], q[1], name=named("BogPool"), flip=int(q[0]) % 2 == 1, check=False)
    for q in ((27.0, 7.8), (54.0, 9.0), (18.5, 14.0), (56.0, 14.5)):
        place("Marsh", "lily_pads", q[0], q[1], name=named("LilyPads"), flip=int(q[0]) % 2 == 0, check=False)
    for q in ((24.0, 9.0), (47.0, 8.0), (54.0, 15.5)):
        place("Marsh", "mist_patch", q[0], q[1], name=named("Mist"), flip=int(q[1]) % 2 == 0, check=False)
    # Saules sur les berges (de grands arbres : premier plan quand ils cachent quelqu'un). (QC-S) Aux deux
    # coins du marais, un grand chêne se dresse devant le bout du pan de forêt (x 16 et 58), qui sans lui
    # se voyait comme une bande de feuillage coupée net (docs/QUALITE.md, QC-33) : son tronc et sa
    # couronne pleine le couvrent du pied à 6,4 m ; les saules s'écartent d'autant vers le marais.
    place("Marsh", "oak_a", 15.7, 18.7, name="CornerOakWest")
    place("Marsh", "oak_a", 57.7, 17.6, name="CornerOakEast")
    place("Marsh", "willow", 20.6, 16.9, name="WillowWest")
    place("Marsh", "willow", 54.4, 16.5, name="WillowEast")

    # Le sentier : pierres plates clairsemées (4.1), herbe au bord, racines, feuilles mortes.
    stones = []
    for name, width, pts in PATHS:
        if name in ("sentier", "vers_ville"):
            for k in range(len(pts) - 1):
                (ax, az), (bx, bz) = pts[k], pts[k + 1]
                n = int(math.hypot(bx - ax, bz - az) / 6.0)
                for s in range(n):
                    t = (s + 0.5) / max(n, 1)
                    stones.append((ax + (bx - ax) * t + rng.uniform(-0.5, 0.5), az + (bz - az) * t))
    scatter("PathStonesKit", ["path_stones_a", "path_stones_b"], stones, scale=(0.9, 1.1), seed=41, check=False)
    borders = []
    for name, width, pts in PATHS:
        if name in ("sentier", "vers_ville"):
            borders += along(pts, 4.2, width / 2.0 + 0.1, 0.1, seed=42 + len(borders), with_yaw=True)
    borders = [q for q in borders if in_map(q[0], q[1], 0.5)]
    scatter("PathEdges", ["grass_edge_a", "grass_edge_b"], borders, scale=(0.9, 1.1), seed=43, check=False)
    verge = []
    for name, width, pts in PATHS:
        verge += along(pts, 2.1, width / 2.0 + 0.8, 0.5, seed=44 + len(verge))
    verge = [q for q in verge if free()(q[0], q[1]) and outside_edges(q[0], q[1], 0.2) and in_map(q[0], q[1], 0.5)]
    scatter("PathGrass", ["grass_clump_a", "grass_clump_c", "tall_grass", "grass_clump_d"], verge[::3], seed=45,
            check=False)
    scatter("PathFerns", FERNS[:3] + ["fern_c"], verge[1::3], seed=46, check=False)
    scatter("PathStones", ["rock_small_a", "rock_small_b", "rock_small_c", "rock_small_d", "mushroom"], verge[2::3],
            seed=47, check=False)
    # Bordures de fougères et de ronces au sud du sentier et au nord (basses : rien ne cache).
    for k, x in enumerate((20.0, 38.0, 44.0, 66.0)):
        z = 20.2 if k % 2 == 0 else 26.6
        place("Trail", "path_edge_ferns", x, z, name=named("PathEdgeFerns"), flip=k % 2 == 1, check=False)
    place("Trail", "path_root_step", 56.0, 23.4, name="RootStepEast", flip=True, check=False)

    # La berge entre le sentier et le marais (z 18 → 22) : buissons, fougères, touffes, mousse.
    bank = poisson(Rect(0.5, 19.0, 79.5, 22.4), 2.1, 48, lambda x, z: free()(x, z) and outside_edges(x, z, 0.1)
                   and not (14.0 < x < 58.0 and z < 19.6), seed=50)
    scatter("BankBushes", BUSHES, bank[0::4], seed=51, check=False)
    scatter("BankFerns", FERNS + ["fern_c"], bank[1::4], seed=52, check=False)
    scatter("BankGrass", GRASSES, bank[2::4], seed=53, check=False)
    scatter("BankMoss", ["moss_patch_a", "moss_patch_b", "leaves_rust_a", "clover_patch"], bank[3::8],
            scale=(0.8, 1.05), seed=54, check=False)
    place("Bank", "log_hollow", 10.0, 20.4, name="LogWest")
    place("Bank", "stump_a", 47.0, 20.2, name="StumpMid")
    place("Bank", "stump_b", 72.0, 20.6, name="StumpEast")
    place("Fork", "cairn", 57.0, 26.0, name="Cairn")

    # Le sud du sentier (z 26 → 29) : touffes et herbes ; les grands décors passent en premier plan.
    south = poisson(Rect(0.5, 26.0, 56.0, 28.9), 1.45, 60, lambda x, z: free()(x, z) and outside_edges(x, z, 0.1),
                    seed=60)
    scatter("SouthGrass", GRASSES, south[0::3], seed=61, check=False)
    scatter("SouthFerns", FERNS, south[1::3], seed=62, check=False)
    scatter("SouthMushrooms", ["mushroom", "mushroom_cep", "mushroom_chanterelle", "fern_c", "nettles"],
            south[2::6], seed=63, check=False)
    scatter("SouthBushes", BUSHES, south[5::6], seed=64, check=False)
    # Feuilles, racines et ombres de feuillage posées au sol, de part et d'autre du sentier.
    decals = poisson(Rect(0.5, 19.0, 79.5, 29.0), 4.2, 34,
                     lambda x, z: in_map(x, z, 0.6) and outside_edges(x, z, 0.0) and not (14.0 < x < 58.0 and z < 19.6),
                     seed=65)
    scatter("LeafDecals", ["leaves_gold_a", "leaves_rust_a", "leaves_gold_b", "leaves_rust_b", "leaves_scatter"],
            decals[0::2], scale=(0.9, 1.15), seed=66, check=False)
    scatter("RootDecals", ["roots_a", "roots_b", "canopy_shadow_a", "canopy_shadow_b"], decals[1::2],
            scale=(0.9, 1.1), seed=67, check=False)

    # La forêt noire au sud : buissons et fougères de premier plan sur le bord, des arbres plus loin qui
    # s'effacent devant le joueur. (QC2) Ni grand tronc ni grand arbre à moins de 10 m au sud du sentier :
    # vus de la caméra, ils couvraient le sentier et ses places (l'érable rouge sur Chtholly à la première
    # embuscade, docs/QUALITE.md, QC-37) ; les arbres du fond (z 34 → 38) ne montrent que leur couronne au
    # bas de l'écran (tools/exterior_maps.py check : aucune place masquée).
    brush = poisson(Rect(0.5, 28.6, 56.0, 29.8), 2.6, 24, lambda x, z: in_map(x, z, 0.4), seed=71)
    scatter("SouthBrush", ["fg_bush", "fg_fern", "fg_grass"], brush, seed=72, check=False)
    deep = poisson(Rect(0.5, 34.0, 56.0, 38.5), 7.0, 12, lambda x, z: True, seed=73)
    scatter("SouthTrees", ["tree_pine", "birch_a", "birch_b", "pine_small_a", "pine_small_b", "maple_a",
                           "tree_autumn_rust", "sapling_a"], deep, seed=74)
    understory = poisson(Rect(0.5, 29.4, 56.0, 33.5), 1.7, 55, lambda x, z: True, seed=76)
    scatter("SouthUnder", BUSHES[:6] + FERNS, understory, seed=77, check=False)

    # La bifurcation et le chemin de la ville (x 56 → 76) : forêt des deux côtés, sol de mousse.
    # (QC2) À l'ouest du chemin de la ville, au sud de la bifurcation, de jeunes pins : un grand arbre y
    # couvrait la bifurcation et le départ du chemin (docs/QUALITE.md, QC-37).
    scatter("ForkTreesWest", ["pine_small_a", "pine_small_b", "sapling_a"], [(58.6, 35.4), (59.2, 38.8)], seed=80)
    corridor_trees = [(75.2, 36.0), (75.4, 39.0), (78.4, 33.0), (78.6, 38.0)]
    scatter("ForkTrees", TREES_DARK + TREES_RUST[:2], corridor_trees, seed=81)
    fork = poisson(Rect(56.5, 24.0, 79.0, 39.5), 2.5, 30,
                   lambda x, z: free()(x, z) and outside_edges(x, z, 0.1) and in_map(x, z, 0.4), seed=82)
    scatter("ForkBrush", BUSHES[:5] + FERNS + GRASSES[:3], fork, seed=83, check=False)
    scatter("ForkLeaves", ["leaves_rust_a", "leaves_gold_b", "roots_a", "moss_patch_a"], fork[::7], seed=84,
            check=False)
    east = poisson(Rect(58.0, 18.6, 79.5, 23.4), 1.9, 26,
                   lambda x, z: free()(x, z) and outside_edges(x, z, 0.1) and in_map(x, z, 0.4), seed=85)
    scatter("EastBank", BUSHES[:4] + FERNS + GRASSES[:3], east, seed=86, check=False)
    # Le sentier s'arrête là tant que la ville n'existe pas : un écriteau, à la place de la sortie.
    if "vers_ville" in p.missing_exits:
        place("Fork", "waiting_sign", 66.6, 37.2, name="SignVille")

    # Au-delà des bords est et ouest : la forêt continue (on n'y passe pas, la barrière du sol ferme la carte).
    backdrop = [(-2.0, z + rng.uniform(-1.0, 1.0)) for z in (8.0, 14.0, 20.0, 27.0, 33.0, 39.0)]
    backdrop += [(82.0, z + rng.uniform(-1.0, 1.0)) for z in (10.0, 16.0, 22.0, 29.0, 35.0)]
    for k, (x, z) in enumerate(backdrop):
        scene = (TREES_DARK + TREES_RUST)[k % 12]
        place("Backdrop", scene, x, z, y=0.0, name="Backdrop%d" % (k + 1), flip=k % 2 == 1, check=False)


def ambient(p):
    """Vie ambiante : feuilles d'automne qui tombent, oiseaux qui traversent ; pas de lucioles (fin
    d'automne), pas de papillons."""
    return [
        ("Birds", "birds_flock", 6, 10, 1, 3, (40, 6, 24), 6.0, (0, 0), 4.0, 0.8, 3, (40, 0, 20)),
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 10, (26, 9, 20), 0.0, (0, 0), 0.9, 0.8, 4, (40, 0, 20)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 8, (26, 9, 20), 0.0, (0, 0), 1.1, 0.8, 5, (40, 0, 20)),
    ]
