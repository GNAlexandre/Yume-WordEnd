"""(C3) La colline des étoiles : la pose de la carte `colline` d'après docs/lore/CARTE.md, section 7
(bloc ```plan lu par tools/carte_plans.py).

Ce que dit l'œuvre (7) : une petite colline à la périphérie de l'île, au vent calme, à l'air limpide,
sous une douce lumière d'étoiles, assez près de l'entrepôt pour y aller à pied la nuit ; de l'herbe ;
les quarante et un talismans de Seniorious flottent autour d'un petit cristal (V1, « Le ciel étoilé
sous le ciel étoilé »). Rien d'autre : pas de belvédère, pas de myosotis.

Composition vue de la caméra (elle regarde le nord ; CARTE.md 0.3) :
- la colline est un cap : trois terrasses (+1, +2, +3 m) qui montent du sud vers un sommet de 12 × 12 m
  d'herbe rase (la place `cercle_talismans`), puis le vide au nord : la mer de nuages sous les étoiles ;
- les rochers du bord (edge_rocks) bordent le vide sauf devant le cercle : la vue au nord reste ouverte ;
- à l'ouest et à l'est, la lisière (pans de forêt de 16 m dressés au-delà du bord, un rang d'arbres
  devant) ; au sud, au pied de la colline, le bois (variantes de premier plan) ;
- sur les terrasses : herbes hautes, bruyère, fleurs d'automne, petits rochers ; le chemin zigzague
  de terrasse en terrasse par trois rampes.

Aucune lumière dans la carte (mission C3) : la nuit est celle d'Atmosphere (préréglage `nuit`, posé par
`light_preset`) ; les deux lumières du plan (le petit cristal, les talismans) sont la scène de l'acte 1
(8.8), qui pose les talismans au point `talismans_centre`.
"""

import exterior_ground
from exterior_pose import Rect, along, poisson

SETTINGS = {
    "groups": ["Rim", "Summit", "Rocks", "Trees", "Lisiere", "Woods", "Backdrop"],
    # La caméra monte jusqu'au bord pour la vue au nord (z = 6 au lieu de 9) et descend jusqu'au pied de la
    # colline (z = 32, comme la règle P − 8) : CARTE.md 7 disait Rect2(10, 6, 20, 23), qui arrête la caméra
    # à z = 29 et laisse le joueur hors de l'écran sur les huit derniers mètres du chemin (corrigé dans CARTE.md).
    "camera_bounds": (10, 6, 20, 26),
    # La colline est de nuit (7, « Lumière »). CARTE.md l'appelle `nuit_claire` ; le préréglage d'E9
    # qui est une nuit claire s'appelle `nuit` (docs/DECISIONS.md, C3).
    "light_preset": "nuit",
    # Le plan nomme deux lumières (cristal_reglage, talismans) : la carte n'en porte aucune.
    "no_lights": True,
    # Le nœud Life/Fauna d'E5 (merles, papillons, chouette : data/fauna/ile_68/peuplement.json).
    "fauna": True,
}

# Places de la vie que le plan ne nomme pas : (nom, x, z, regard en degrés, à quoi elles servent). Écrites
# en Life/Places (Marker3D) et listées dans CARTE.md par `exterior_maps.py places`.
PLACES_WHY = [
    ("vers_entrepot", 20.0, 38.4, 0.0, "le pied du chemin, devant la sortie : par où l'on part vers l'entrepôt, et d'où l'on en arrive"),
    ("pied_de_colline", 20.0, 34.0, 0.0, "le bas du chemin, avant la première rampe : on s'y arrête avant de monter"),
    ("arbre_seul", 28.2, 10.8, 0.0, "au pied de l'arbre noueux solitaire, côté sommet (VIE.md, faune : la chouette y guette)"),
    ("merles", 11.0, 22.0, 0.0, "la bruyère de la terrasse haute, à l'ouest : les merles de l'aube (VIE.md, faune)"),
    ("papillons", 24.5, 22.5, 0.0, "l'herbe fleurie au-dessus de la dernière rampe : les papillons des jours doux (VIE.md, faune)"),
    ("chouette", 29.2, 10.2, 0.0, "la branche basse de l'arbre solitaire : la chouette de la nuit (VIE.md, faune)"),
]

DEVIATIONS = [
    "bornes de la caméra `Rect2(10, 6, 20, 26)` au lieu de `Rect2(10, 6, 20, 23)` : le plan arrêtait le point "
    "visé à z = 29, la vue ne descendait plus qu'à z = 36 et le joueur sortait de l'écran sur le bas du chemin "
    "(l'arrivée est en z = 36,5) ; avec z = 32, la vue va jusqu'à la sortie (z = 39)",
    "`nuit_claire` (CARTE.md 7, ACTE1.md 8.8) n'existe pas dans data/lighting/ : `light_preset` vaut `nuit`, la "
    "nuit claire d'E9 (PLAN.md : « `nuit` : la colline, une nuit claire ») ; un préréglage `nuit_claire` plus "
    "doux se demande à E9 (docs/CONTRACT_REQUESTS.md)",
    "les lumières du plan (`cristal_reglage`, `talismans`) ne sont pas écrites : la carte ne porte aucune "
    "lumière (mission C3) ; la lueur du petit cristal et des talismans est celle de la scène (acte 1, 8.8)",
    "les paliers du plan montent jusqu'au bord du vide (z = −1 au lieu de 4) : le cap finit sur la falaise, "
    "sans replat de niveau 0 entre le sommet et la mer de nuages",
    "les lisières est et ouest (x < 4, x > 36) sont peintes en sous-bois (le plan laisse l'herbe sèche)",
    "la terre du chemin (`path_dirt_b`) est peinte sur la bande du chemin seulement (1,8 m, ses bords francs), "
    "au lieu des rectangles du plan : celui de 12 → 28 × 26 → 30 touche le pied du talus de 1 m, et un chemin ne "
    "longe pas une marche de plus de 0,5 m",
    "`lone_tree_fg` et `boulder_a_fg` : variantes de premier plan (CARTE.md 0.3) de l'arbre solitaire et du "
    "rocher, écrites par tools/exterior_props.py ; elles s'effacent devant le joueur",
]

TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c"]
TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn"]
TREES_DARK = ["pine_tall_b", "tree_old_pine", "tree_pine", "oak_a", "beech_a", "pine_dead"]
BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f"]
FERNS = ["fern_a", "fern_b", "fern_c", "fern_d"]
GRASSES = ["tall_grass", "wind_grass_a", "wind_grass_b", "grass_sway"]
FLOWERS = ["wildflowers_a", "wildflowers_b"]
ROCKS = ["rock_small_a", "rock_small_b", "rock_small_c", "rock_small_d"]


def ground_plan(m):
    """Le sol : le plan (paliers, matières, rampes, chemin), plus le vide au nord, les paliers prolongés
    jusqu'à lui, les lisières en sous-bois et des plaques de feuilles."""
    plan = exterior_ground.ground_from_plan(
        m, noise=0.8, ramp_material="herbe", skip=("path_dirt_b",),
        comment="Sol en relief de la colline des étoiles (lot C3), d'après docs/lore/CARTE.md, section 7 : trois "
                "terrasses (+1, +2, +3 m) montées par trois rampes, le sommet à 3 m, le vide au nord (la mer de "
                "nuages), le chemin qui zigzague. Lu par tools/map_build.py gen colline ; le jeu ne lit pas ce "
                "fichier.")
    plan["edges"]["north"] = "void"
    steps = plan["steps"]
    # Le chemin longe les talus de 1 m : sa bande n'a pas de bord irrégulier (sinon une case du talus y entre).
    for s in steps:
        if s["op"] == "path":
            s["noise"] = 0.0
    # Les paliers vont jusqu'au bord de l'île (le plan les arrête à z = 4, le vide commence à z ≈ 3).
    for s in steps:
        if s["op"] == "level":
            x, z, w, d = s["shape"]["rect"]
            s["shape"]["rect"] = [x, -1, w, d + (z + 1)]
    # Le vide : le cap finit sur une côte irrégulière (vide 0 0 40 3 du plan).
    first_face = exterior_ground.step_index(steps, "face")
    steps.insert(first_face, {"op": "void", "shape": {
        "poly": [[-3, -3], [43, -3], [43, 2.6], [38, 3.0], [33, 2.3], [28, 2.9], [22, 2.2], [17, 2.8], [12, 2.3],
                 [7, 3.0], [2, 2.4], [-3, 2.8]], "noise": 0.5, "noise_scale": 2.5, "seed": 3}})
    # Les lisières : du sous-bois à l'ouest et à l'est, au-delà du bord praticable.
    first_path = exterior_ground.step_index(steps, "ramp")
    edge = [
        {"op": "material", "material": "sous_bois", "shape": {"rect": [-1, 3, 5.2, 38], "noise": 1.2,
                                                                "noise_scale": 2.6, "seed": 11}},
        {"op": "material", "material": "sous_bois", "shape": {"rect": [34.8, 3, 6.4, 38], "noise": 1.2,
                                                                "noise_scale": 2.6, "seed": 12}},
        {"op": "material", "material": "feuilles", "shape": {"ellipse": [3.2, 26, 2.2, 3.0], "noise": 0.6,
                                                               "noise_scale": 1.6, "seed": 13}},
        {"op": "material", "material": "feuilles", "shape": {"ellipse": [36.5, 14, 2.0, 2.6], "noise": 0.6,
                                                               "noise_scale": 1.6, "seed": 14}},
        {"op": "material", "material": "feuilles", "shape": {"ellipse": [30.0, 35.0, 3.0, 1.4], "noise": 0.6,
                                                               "noise_scale": 1.6, "seed": 15}},
        {"op": "material", "material": "feuilles", "shape": {"ellipse": [9.0, 35.5, 3.2, 1.3], "noise": 0.6,
                                                               "noise_scale": 1.6, "seed": 16}},
    ]
    steps[first_path:first_path] = edge
    return plan


def prepare(p):
    pass


def pose(p):
    M, W, D = p.map, p.W, p.D
    rng = p.rng
    place, scatter = p.place, p.scatter
    in_map, outside_edges, path_distance = p.in_map, p.outside_edges, p.path_distance
    free, height, walk_grid = p.free, p.height, p.walk_grid

    walk_grid()
    counters = {}

    def named(base):
        counters[base] = counters.get(base, 0) + 1
        return "%s_%d" % (base, counters[base])

    # === 1. Ossature du plan (7) =======================================================================

    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        flip = len(p.singles) % 2 == 1
        if n in ("boulder_a", "mossy_rock"):
            place("Rocks", n, x, z, name=named(n.title().replace("_", "") + "_plan"), flip=flip)
        elif n in ("rock_small_a", "heather", "tall_grass", "wildflowers_a"):
            place("Rocks" if n.startswith("rock") else "Summit", n, x, z,
                  name=named(n.title().replace("_", "") + "_plan"), flip=flip, check=False)
        else:
            p.warnings.append("décor du plan non posé : %s" % n)
    for t in M.trees:
        x, z = (t.rect.x0 + t.rect.x1) / 2.0, (t.rect.z0 + t.rect.z1) / 2.0
        place("Trees", t.name, x, z, name=named("LoneTree_plan"))

    walk_grid()

    # === 2. La lisière ouest et est (7 : forest_wall_*) =====================================================

    # Des pans de forêt de 16 m dressés au-delà du bord praticable (x < 4 et x > 36), du nord au sud : le
    # joueur n'y va pas, ils ne le cachent pas (leur emprise reste hors des cases où l'on marche).
    for k, (x, z, scene) in enumerate(((-4.5, 8.0, "forest_wall_c"), (-4.5, 20.0, "forest_wall_a"),
                                       (-4.5, 32.0, "forest_wall_d"))):
        place("Lisiere", scene, x, z, y=0.0, name="ForestWallWest%d" % (k + 1), flip=k % 2 == 1, check=False)
    for k, (x, z, scene) in enumerate(((44.5, 8.0, "forest_wall_a"), (44.5, 20.0, "forest_wall_d"),
                                       (44.5, 32.0, "forest_wall_c"))):
        place("Lisiere", scene, x, z, y=0.0, name="ForestWallEast%d" % (k + 1), flip=k % 2 == 0, check=False)

    # Un rang d'arbres devant les pans, sur le bord (x 0 → 3,4 ; x 36,6 → 40) : le plan les ferme.
    west = [(1.2, 6.0), (2.4, 11.5), (1.0, 17.0), (2.6, 22.5), (1.4, 28.0), (2.2, 33.5), (1.0, 38.0)]
    east = [(38.8, 6.5), (37.6, 12.0), (39.0, 17.5), (37.8, 23.0), (38.6, 28.5), (37.6, 34.0), (39.0, 38.5)]
    scatter("WestTrees", TREES_DARK[:3] + TREES_RUST[:3], west, seed=21)
    scatter("EastTrees", TREES_GOLD[:3] + TREES_DARK[:3], east, seed=22)
    foot = [(rng.uniform(0.6, 3.6), z + rng.uniform(-1.5, 1.5)) for z in (8.0, 14.0, 20.0, 26.0, 32.0)]
    foot += [(rng.uniform(36.4, 39.4), z + rng.uniform(-1.5, 1.5)) for z in (9.0, 15.0, 21.0, 27.0, 33.0)]
    scatter("EdgeBrush", BUSHES + FERNS + ["heather"], foot, seed=23, check=False)

    # === 3. Le bord : les rochers au-dessus du vide (7 : edge_rocks_*) ======================================

    # Rochers sur la ligne du bord (z ≈ 3,6), de part et d'autre du cercle ; devant le cercle (x 14 → 26),
    # seulement des cailloux : la vue au nord reste ouverte.
    rim = []
    x = 4.5
    while x < 36.0:
        if not 12.5 < x < 27.5:
            rim.append((x + rng.uniform(-0.4, 0.4), rng.uniform(3.4, 3.9)))
        x += rng.uniform(4.2, 5.4)
    scatter("RimRocks", ["edge_rocks_a", "edge_rocks_b"], rim, seed=31, check=False)
    pebbles = poisson(Rect(4.5, 3.4, 35.5, 5.2), 1.3, 30, lambda x, z: outside_edges(x, z, 0.0) or z > 4.0, seed=32)
    scatter("RimPebbles", ROCKS, pebbles[::2], seed=33, check=False)
    scatter("RimGrass", GRASSES[:3] + ["heather"], pebbles[1::2], seed=34, check=False)

    # === 4. Les terrasses (7 : herbes, bruyère, fleurs d'automne, petits rochers) ========================

    def clear(extra=0.0):
        base = free()
        return lambda x, z: base(x, z) and outside_edges(x, z, 0.2) and path_distance(x, z) > 0.2 + extra

    # Le sommet autour du cercle : de l'herbe haute sur le pourtour (la place reste rase et libre).
    summit = poisson(Rect(4.5, 4.4, 35.5, 20.0), 1.3, 170, clear(), seed=40)
    scatter("SummitGrass", GRASSES, summit[0::3], seed=41, check=False)
    scatter("SummitFlowers", FLOWERS, summit[1::5], seed=42, check=False)
    scatter("SummitHeather", ["heather", "wildflowers_a"], summit[2::6], seed=43, check=False)
    scatter("SummitRocks", ROCKS + ["mossy_rock"], summit[4::11], seed=44)

    # La terrasse haute (+2 m) et la basse (+1 m).
    terrace2 = poisson(Rect(8.5, 20.2, 31.5, 26.0), 1.7, 60, clear(), seed=50)
    scatter("UpperGrass", GRASSES, terrace2[0::4], seed=51, check=False)
    scatter("UpperFlowers", FLOWERS + ["heather"], terrace2[1::4], seed=52, check=False)
    scatter("UpperRocks", ROCKS, terrace2[2::7], seed=53, check=False)
    terrace1 = poisson(Rect(4.5, 22.0, 35.5, 32.0), 2.5, 48, clear(), seed=60)
    scatter("LowerGrass", GRASSES, terrace1[0::4], seed=61, check=False)
    scatter("LowerFlowers", FLOWERS + ["heather"], terrace1[1::5], seed=62, check=False)
    scatter("LowerRocks", ROCKS + ["mossy_rock"], terrace1[2::9], seed=63)
    scatter("LowerBushes", BUSHES[:3] + FERNS[:2], terrace1[4::10], seed=64, check=False)

    # Les talus : herbe au pied de chaque face (le sol n'est pas nu).
    talus = []
    for z in (22.0, 26.5, 32.0):
        for k in range(6):
            talus.append((rng.uniform(5.0, 35.0), z + rng.uniform(-0.3, 0.3)))
    scatter("TalusGrass", GRASSES[:3] + FLOWERS[:1], [q for q in talus if clear(-0.1)(q[0], q[1])], seed=65,
            check=False)

    # Le long du chemin : bordure d'herbe et cailloux.
    verge = []
    for name, width, pts in p.paths:
        verge += along(pts, 2.6, width / 2.0 + 0.7, 0.4, seed=66 + len(verge))
    verge = [q for q in verge if clear()(q[0], q[1]) and in_map(q[0], q[1], 0.6)]
    scatter("PathGrass", GRASSES, verge[::5], seed=67, check=False)
    scatter("PathFlowers", FLOWERS, verge[2::9], seed=68, check=False)
    scatter("PathStones", ROCKS, verge[3::9], seed=69, check=False)

    # === 5. Le pied de la colline (z 32 → 38) : le sous-bois, de plus en plus fermé ====================

    foot_zone = poisson(Rect(4.5, 32.4, 35.5, 37.8), 2.3, 34,
                        lambda x, z: clear(0.5)(x, z) and not 16.0 < x < 24.0 or (z < 33.8 and clear(0.5)(x, z)),
                        seed=70)
    scatter("FootBushes", BUSHES + FERNS, foot_zone[0::3], seed=71, check=False)
    scatter("FootGrass", GRASSES[:3] + ["grass_clump_a", "grass_clump_c", "nettles"], foot_zone[1::3], seed=72,
            check=False)
    scatter("FootLeaves", ["leaves_gold_a", "leaves_rust_a", "leaves_gold_b", "leaves_rust_b", "leaves_scatter"],
            foot_zone[2::6], scale=(0.9, 1.15), seed=73, check=False)
    young = [(8.0, 35.2), (12.5, 36.4), (28.0, 36.0), (32.5, 35.0), (6.0, 33.4), (34.0, 33.0)]
    scatter("FootTrees", ["sapling_a", "birch_a", "birch_b", "pine_small_a", "pine_small_b"], young, seed=74)

    # Le bord sud (bord foret ... pp) : grands troncs, buissons et fougères de premier plan, des deux côtés
    # de la trouée du chemin.
    south = []
    x = 4.6
    while x < 36.0:
        if not 16.0 < x < 24.0:
            south.append((x + rng.uniform(-0.4, 0.4), rng.uniform(38.4, 39.3)))
        x += rng.uniform(2.6, 3.8)
    # Les grands troncs seulement aux deux bouts du bord : au milieu, ils cacheraient la montée.
    trunks = [q for q in south if q[0] < 10.5 or q[0] > 29.5]
    scatter("SouthTrunks", ["fg_trunk_a", "fg_trunk_b"], trunks[::2], seed=75, check=False)
    scatter("SouthBrush", ["fg_bush", "fg_fern", "fg_grass"], [q for k, q in enumerate(south) if k % 3], seed=76,
            check=False)
    place("Woods", "fg_bush", 15.8, 39.0, name="GapBushWest", check=False)
    place("Woods", "fg_fern", 24.4, 39.0, name="GapFernEast", check=False)

    # Ombres des arbres et du feuillage posées au sol.
    shade = poisson(Rect(4.5, 30.0, 35.5, 37.5), 6.0, 5, lambda x, z: True, seed=77)
    scatter("Shade", ["canopy_shadow_a", "canopy_shadow_b", "sun_dapple"], shade, scale=(0.9, 1.1), seed=78,
            check=False)

    # === 6. Au-delà des bords : la forêt continue ======================================================

    backdrop = [(-5.0, z + rng.uniform(-1.0, 1.0)) for z in (5.0, 12.0, 19.0, 26.0, 33.0, 40.0)]
    backdrop += [(45.0, z + rng.uniform(-1.0, 1.0)) for z in (6.0, 13.0, 20.0, 27.0, 34.0, 41.0)]
    for k, (x, z) in enumerate(backdrop):
        scene = (TREES_DARK + TREES_RUST)[k % 12]
        place("Backdrop", scene, x, z, y=0.0, name="Backdrop%d" % (k + 1), flip=k % 2 == 1, check=False)


def ambient(p):
    """Vie ambiante : quelques feuilles d'automne que le vent calme porte ; ni lucioles (fin d'automne),
    ni oiseaux de jour (la colline est de nuit : la chouette est un animal d'E5)."""
    return [
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 5, (30, 9, 30), 0.0, (0, 0), 0.7, 0.8, 4, (20, 0, 20)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 4, (30, 9, 30), 0.0, (0, 0), 0.8, 0.8, 5, (20, 0, 20)),
    ]
