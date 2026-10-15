"""(C3, C3b) La colline des étoiles : la pose de la carte `colline` d'après docs/lore/CARTE.md, section 7
(bloc ```plan lu par tools/carte_plans.py). Le relief est dans tools/exterior_recipes/colline_relief.py.

Ce que dit l'œuvre (7) : une petite colline à la périphérie de l'île, au vent calme, à l'air limpide,
sous une douce lumière d'étoiles, assez près de l'entrepôt pour y aller à pied la nuit ; de l'herbe ;
les quarante et un talismans de Seniorious flottent autour d'un petit cristal (V1, « Le ciel étoilé
sous le ciel étoilé »). Rien d'autre : pas de belvédère, pas de myosotis.

Composition vue de la caméra (elle regarde le nord ; CARTE.md 0.3) :
- la colline est un cap : des terrasses aux contours irréguliers (+1, +2,5, +3,5 m) qui montent du sud
  vers un sommet d'herbe (la place `cercle_talismans`, 12 × 12 m d'herbe rase, ceinte de pierres plates
  et d'herbe haute), puis le vide au nord : la mer de nuages sous les étoiles ; la caméra, inclinée à 32°,
  ne voit jamais la falaise du cap (elle est au nord) : le vide se lit par la mer de nuages loin en
  contrebas, des rochers qui flottent, des îles dans la brume et l'horizon ;
- les rochers du bord (edge_rocks) bordent le vide sauf devant le cercle : la vue au nord reste ouverte ;
- les faces des terrasses (visibles, tournées vers le sud) sont habillées : herbe qui déborde en haut,
  racines et rochers en bas, buissons et fougères au pied ;
- à l'ouest et à l'est, la lisière (pans de forêt de 16 m dressés au-delà du bord, un rang d'arbres
  devant) ; au sud, au pied de la colline, le bois (variantes de premier plan) ;
- sur les terrasses : bouquets d'herbes hautes, bruyère, fleurs d'automne, pierres, buissons ; des pierres
  plates sur le chemin, qui zigzague de terrasse en terrasse par trois rampes larges.

Aucune lumière dans la carte (mission C3) : la nuit est celle d'Atmosphere (préréglage `nuit`, posé par
`light_preset`) ; les deux lumières du plan (le petit cristal, les talismans) sont la scène de l'acte 1
(8.8), qui pose les talismans au point `talismans_centre`.
"""

import math
import random

import exterior_recipes.colline_relief as relief
import map_build
from exterior_pose import Rect, along, poisson, prop

SETTINGS = {
    "groups": ["Rim", "Summit", "Rocks", "Talus", "Flora", "Ring", "Path", "Trees", "Lisiere", "Woods", "Backdrop",
               "Sky"],
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
    "(C3b) le relief est dessiné en contours irréguliers (tools/exterior_recipes/colline_relief.py), pas en "
    "rectangles : les trois `palier` du plan en donnent l'enveloppe (terrasses à +1, +2,5 et +3,5 m, au lieu "
    "de +1, +2 et +3), les trois `rampe` sont les volées exactes (5 × 4, 5 × 6 et 5 × 5 cases, pentes de 11 à "
    "14°), et sur les flancs la pente se défait en marches de 0,5 m que le plan ne dit pas ; les `sol` du "
    "plan ne sont plus peints en rectangles : l'herbe, l'herbe haute, la prairie, la roche, la mousse, le "
    "sous-bois et les feuilles le sont en nappes à bord bruité",
    "(C3b) la côte n'est plus une bande droite : le cap avance au centre (z ≈ 2,5) et recule aux épaules "
    "(z ≈ 8), le `vide` du plan (z < 3) en est la pointe",
    "la terre du chemin (`path_dirt_b`) est peinte sur la bande du chemin seulement (1,8 m, ses bords francs), "
    "au lieu des rectangles du plan : un chemin ne longe pas une marche de plus de 0,5 m",
    "`lone_tree_fg` et `boulder_a_fg` : variantes de premier plan (CARTE.md 0.3) de l'arbre solitaire et du "
    "rocher, écrites par tools/exterior_props.py ; elles s'effacent devant le joueur",
]

TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c"]
TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn"]
TREES_DARK = ["pine_tall_b", "tree_old_pine", "tree_pine", "oak_a", "beech_a", "pine_dead"]
BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f"]
FERNS = ["fern_a", "fern_b", "fern_c", "fern_d"]
GRASSES = ["tall_grass", "wind_grass_a", "wind_grass_b", "grass_clump_a", "grass_clump_c"]
ROCKS = ["rock_small_a", "rock_small_b", "rock_small_c", "rock_small_d"]

# Bouquets : thème → ce qu'on y pose (des décalques de sol et des plantes basses, mêlés).
THEMES = {
    "bruyere": ["heather", "heather", "wildflowers_b", "rock_small_c", "grass_clump_b", "moss_patch_b"],
    "prairie": ["wildflowers_a", "wildflowers_b", "flowers_patch_a", "flowers_patch_b", "clover_patch",
                "grass_clump_a"],
    "herbes": ["tall_grass", "wind_grass_a", "wind_grass_b", "grass_clump_c", "thistle", "grass_clump_a"],
    "pierres": ["rock_small_a", "rock_small_b", "rock_small_d", "rock_pile", "moss_patch_b", "grass_clump_b"],
    "buissons": ["bush_b", "bush_c", "bush_d", "berry_bush", "fern_a", "thistle", "fern_b"],
    "fougeres": ["fern_a", "fern_b", "fern_d", "mushroom_cep", "leaves_rust_a", "grass_clump_d"],
}

# Le ciel et le vide : (x, y, z, échelle, scène). y et z sont ceux du monde (le sol du sommet est à y = 3,5, le
# bord à z ≈ 2,5) : la caméra, à 32°, voit les rochers proches au-dessus du bord, la mer de nuages à 120 → 250 m
# au nord (la nappe est à y = −60), les îles qui la dépassent.
SKY_ROCKS = [
    (5.5, -4.5, -12.0, 0.9, "floating_rock_b"), (33.5, -6.0, -16.0, 1.0, "floating_rock_c"),
    (-3.0, -9.0, -26.0, 1.2, "floating_rock"), (41.0, -12.0, -30.0, 1.0, "floating_rock_b"),
    (12.0, -17.0, -48.0, 1.3, "floating_rock_c"), (29.0, -20.0, -58.0, 1.1, "floating_rock"),
    (-14.0, -22.0, -72.0, 1.6, "floating_rock_c"), (50.0, -24.0, -76.0, 1.5, "floating_rock_b"),
]
# Les îles lointaines (distant_island_*) mesurent 64 × 32 m à l'échelle 1 (12 px par mètre).
SKY_ISLANDS = [
    (46.0, -45.0, -96.0, 0.5, "distant_island_b"), (-12.0, -52.0, -112.0, 0.55, "distant_island_a"),
    (31.0, -33.0, -72.0, 0.4, "distant_island_e"), (12.0, -58.0, -140.0, 0.6, "distant_island_f"),
    (64.0, -58.0, -150.0, 0.65, "distant_island_c"), (-36.0, -58.0, -175.0, 0.8, "distant_island_d"),
    (20.0, -58.0, -240.0, 4.5, "horizon_islands"),
]
SKY_CLOUDS = [
    (14.0, -56.0, -128.0, 1.8, "cloud_c"), (44.0, -56.0, -148.0, 2.0, "cloud_a"), (-12.0, -57.0, -166.0, 2.2, "cloud_b"),
    (28.0, -57.0, -186.0, 2.5, "cloud_c"), (60.0, -58.0, -206.0, 2.7, "cloud_a"), (-4.0, -58.0, -226.0, 3.0, "cloud_c"),
    (22.0, -58.0, -252.0, 3.4, "cloud_a"),
]
SKY_MIST = [(18.0, -50.0, -110.0, 2.2, "mist_band"), (44.0, -54.0, -150.0, 3.2, "mist_band"),
            (-6.0, -56.0, -190.0, 3.6, "mist_band")]


def prepare(p):
    pass


def pose(p):
    M, W, D = p.map, p.W, p.D
    place, scatter = p.place, p.scatter
    in_map, outside_edges, path_distance = p.in_map, p.outside_edges, p.path_distance
    levels, kinds = p.ground.levels, p.ground.kinds
    circle = p.places["cercle_talismans"]
    centre = ((circle.x0 + circle.x1) / 2.0, (circle.z0 + circle.z1) / 2.0)

    p.walk_grid()
    counters = {}

    def named(base):
        counters[base] = counters.get(base, 0) + 1
        return "%s_%d" % (base, counters[base])

    # --- Ce que dit le sol --------------------------------------------------------------------------

    def cell(x, z):
        i, j = int(math.floor(x)), int(math.floor(z))
        if not (0 <= i < W and 0 <= j < D):
            return None
        return j * W + i

    def land(x, z):
        c = cell(x, z)
        return c is not None and levels[c] is not None

    def flat(x, z):
        c = cell(x, z)
        return c is not None and levels[c] is not None and kinds[c] == map_build.FLAT

    def void_near(x, z, reach):
        r = int(math.ceil(reach / 0.5))
        for a in range(-r, r + 1):
            for b in range(-r, r + 1):
                if a * a + b * b <= r * r and not land(x + a * 0.5, z + b * 0.5):
                    return True
        return False

    def coast_z(x):
        """Première ligne de terre au sud du vide, à la colonne de x (le haut de la côte)."""
        i = min(max(int(x), 0), W - 1)
        for j in range(D):
            if levels[j * W + i] is not None:
                return float(j)
        return 0.0

    def usable(x, z, coast=0.7, way=0.3, standing=True, ring=False):
        """Un point où l'on peut poser un décor : de la terre plate, loin du vide, hors des bords, loin
        du chemin ; hors du cercle pour ce qui se dresse (`ring` : même dedans)."""
        if not in_map(x, z, 0.5) or not flat(x, z) or void_near(x, z, coast):
            return False
        if not outside_edges(x, z, 0.0) or path_distance(x, z) < way:
            return False
        for px, pz in list(p.points.values()) + list(p.markers.values()):
            if abs(px - x) < 1.0 and abs(pz - z) < 1.0:
                return False
        if p.exits and any(e.has(x, z, 1.2) for e in p.exits):
            return False
        if standing and not ring and circle.has(x, z, 0.0):
            return False
        return True

    def sect(name):
        """Un tirage à part par section : changer une section ne déplace pas les autres."""
        return random.Random("colline/" + name)

    def fit(scene, scale):
        """Un buisson ou une fougère haute ne dépasse pas 1,25 m : au-delà il cacherait la tête du joueur au sud de lui."""
        if not scene.startswith(("bush", "fern", "berry", "thicket")):
            return scale
        h = prop(scene).h
        return round(min(scale, 1.25 / h), 2) if h > 1.0 else scale

    def cluster(group, cx, cz, n, radius, theme, ring=False, scale=(0.85, 1.2), stretch=1.3, check=False):
        """Un bouquet : n décors tirés autour de (cx, cz) dans un thème."""
        r = sect("bouquet %s %.1f %.1f" % (group, cx, cz))
        kinds_of = THEMES[theme] if isinstance(theme, str) else theme
        put = 0
        for _ in range(n * 8):
            if put >= n:
                break
            a = r.uniform(0.0, math.tau)
            d = radius * math.sqrt(r.random())
            x, z = cx + d * math.cos(a) * stretch, cz + d * math.sin(a)
            if not usable(x, z, ring=ring):
                continue
            scene = r.choice(kinds_of)
            place(group, scene, x, z, scale=fit(scene, round(r.uniform(*scale), 2)), flip=r.random() < 0.5, check=check)
            put += 1
        return put

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

    p.walk_grid()

    # === 2. La lisière ouest et est (7 : forest_wall_*) =====================================================
    rng = sect("lisiere")

    # Des pans de forêt de 16 m dressés au-delà du bord praticable (x < 4 et x > 36), du nord au sud : le
    # joueur n'y va pas, ils ne le cachent pas (leur emprise reste hors des cases où l'on marche).
    # (C3b) Les pans commencent à z = 9 : au nord, la côte recule aux épaules et le pan flotterait au-dessus du vide.
    for k, (x, z, scene) in enumerate(((-4.5, 17.0, "forest_wall_c"), (-4.5, 33.0, "forest_wall_d"))):
        place("Lisiere", scene, x, z, y=0.0, name="ForestWallWest%d" % (k + 1), flip=k % 2 == 1, check=False)
    for k, (x, z, scene) in enumerate(((44.5, 17.0, "forest_wall_a"), (44.5, 33.0, "forest_wall_c"))):
        place("Lisiere", scene, x, z, y=0.0, name="ForestWallEast%d" % (k + 1), flip=k % 2 == 0, check=False)
    # (QC-S) Le bout des pans, côté colline (x 3,5 et 36,5), se voyait comme une bande de feuillage coupée
    # net (docs/QUALITE.md, QC-33) : un chêne se dresse devant chacun (son tronc et sa couronne pleine le
    # couvrent du pied à 6,4 m).
    for k, z in enumerate((17.0, 33.0)):
        place("Lisiere", "oak_a", 3.17, z + 0.6, name="EndOakWest%d" % (k + 1))
        place("Lisiere", "oak_a", 36.83, z + 0.6, name="EndOakEast%d" % (k + 1), flip=True)

    # Un rang d'arbres devant les pans, sur le bord (x 0 → 3,4 ; x 36,6 → 40), sur la terre seulement.
    west = [(1.2, 13.0), (2.4, 15.5), (1.0, 18.0), (2.6, 22.0), (1.4, 26.0), (2.2, 30.0), (1.0, 34.0), (2.0, 38.0)]
    east = [(38.8, 6.5), (37.6, 12.0), (39.0, 17.5), (37.8, 23.0), (38.6, 28.5), (37.6, 34.0), (39.0, 38.5)]
    scatter("WestTrees", TREES_DARK[:3] + TREES_RUST[:3], [q for q in west if land(*q)], seed=21)
    scatter("EastTrees", TREES_GOLD[:3] + TREES_DARK[:3], [q for q in east if land(*q)], seed=22)
    foot = [(rng.uniform(0.6, 3.6), z + rng.uniform(-1.5, 1.5)) for z in (14.0, 20.0, 26.0, 32.0)]
    foot += [(rng.uniform(36.4, 39.4), z + rng.uniform(-1.5, 1.5)) for z in (9.0, 15.0, 21.0, 27.0, 33.0)]
    scatter("EdgeBrush", BUSHES + FERNS + ["heather"], [q for q in foot if land(*q)], seed=23, check=False)

    # === 3. Le bord : la côte, le cap ====================================================================
    rng = sect("bord")

    # Rochers sur la ligne de la côte, de part et d'autre du cercle ; devant le cercle (x 12,5 → 27,5), pas de
    # rocher : la vue au nord reste ouverte.
    rim = []
    for x in (9.0, 11.4, 29.2, 32.0):
        rim.append((x + rng.uniform(-0.3, 0.3), coast_z(x) + rng.uniform(1.0, 1.6)))
    scatter("RimRocks", ["edge_rocks_a", "edge_rocks_b"], [q for q in rim if usable(q[0], q[1], coast=0.2)], seed=31,
            check=False)
    # Herbe qui déborde du bord, sur toute la côte (basse : elle ne cache pas la vue), et des cailloux.
    x = 9.0
    k = 0
    while x < 33.0:
        z = coast_z(x) + 0.6
        # Là où la côte est à peu près droite sur les quatre mètres du panneau : sinon il flotterait au-dessus du vide.
        straight = all(abs(coast_z(x + d) - coast_z(x)) < 0.9 for d in (-2.0, -1.0, 1.0, 2.0))
        if straight and usable(x, z, coast=0.3, standing=False):
            place("Rim", "edge_grass", x, z, name="RimEdgeGrass%d" % (k + 1), flip=k % 2 == 1, scale=0.85, check=False)
            k += 1
        x += rng.uniform(4.6, 6.0)
    pebbles = poisson(Rect(8.0, 3.0, 33.0, 5.8), 2.0, 14, lambda x, z: usable(x, z, coast=0.5), seed=32)
    scatter("RimPebbles", ROCKS, pebbles[::2], seed=33, check=False)
    scatter("RimGrass", GRASSES[:3] + ["heather"], pebbles[1::2], seed=34, check=False)
    # Les grandes pierres sculptées par le vent, aux épaules du cap, et une borne de pierres.
    place("Rocks", "wind_rock_a", 11.2, 8.6, name="WindRockWest")
    place("Rocks", "wind_rock_b", 28.4, 6.2, name="WindRockEast", flip=True)
    place("Rocks", "cairn", 24.6, 4.5, name="CairnRim", check=False)

    # === 4. Le cercle des talismans : libre, mais beau (7) ====================================================
    rng = sect("cercle")

    cx, cz = centre
    # Le cercle est dessiné dans le sol (colline_relief.py : un anneau de dalles) ; autour, la pose :
    # Autour : l'herbe haute (plus haute au bord), des bruyères, des fleurs en bouquets dehors et dedans.
    for k in range(8):
        a = math.tau * k / 8 + rng.uniform(-0.1, 0.1)
        r = rng.uniform(6.2, 7.6)
        x, z = cx + r * math.cos(a) * 1.05, cz + r * math.sin(a)
        if usable(x, z, ring=True, way=0.8):
            place("Ring", rng.choice(["tall_grass", "heather", "tall_grass", "wildflowers_a", "heather"]), x, z, scale=round(rng.uniform(0.95, 1.35), 2),
                  flip=rng.random() < 0.5, check=False)
    for k, (dx, dz, scene) in enumerate(((-3.6, -3.8, "flowers_patch_a"), (3.9, -3.0, "flowers_patch_b"),
                                         (-4.2, 2.8, "flowers_patch_b"), (4.0, 3.6, "flowers_patch_a"))):
        x, z = cx + dx, cz + dz
        if path_distance(x, z) > 1.2:
            place("Ring", scene, x, z, scale=0.9, flip=k % 2 == 1, check=False)

    # === 5. Les faces des terrasses (talus) ====================================================================
    rng = sect("talus")

    # Chaque ligne où le sol tombe vers le sud : herbe qui déborde en haut, racines et roche au flanc,
    # fougères et pierres au pied.
    runs = []
    for j in range(1, D):
        i = 0
        while i < W:
            a, b = levels[(j - 1) * W + i], levels[j * W + i]
            ka, kb = kinds[(j - 1) * W + i], kinds[j * W + i]
            if a is not None and b is not None and a > b and ka == map_build.FLAT and kb == map_build.FLAT:
                start = i
                while (i < W and levels[(j - 1) * W + i] == a and levels[j * W + i] == b
                       and kinds[(j - 1) * W + i] == map_build.FLAT and kinds[j * W + i] == map_build.FLAT):
                    i += 1
                runs.append((start, i, j, a, b))
            else:
                i += 1
    TOP = {1: ["grass_edge_a", "wind_grass_a", "grass_clump_b", "heather"],
           2: ["grass_edge_b", "bush", "bush_c", "fern_a", "grass_edge_a", "bush_d"],
           3: ["grass_edge_a", "bush_b", "bush_f", "fern_d", "edge_grass", "bush_c"]}
    FOOT = {1: ["rock_small_b", "grass_clump_a", "rock_small_d", "fern_c"],
            2: ["fern_b", "rock_small_a", "rock_pile", "fern_c", "mossy_rock", "fern_a"],
            3: ["rock_pile", "fern_d", "mossy_rock", "bush_e", "boulder_b", "fern_a"]}
    taluses = 0
    for start, stop, j, a, b in runs:
        drop = a - b  # en paliers de 0,5 m
        if stop - start < 2:
            continue
        key = min(drop, 3)
        if drop == 1 and rng.random() < 0.8:
            continue
        x = start + 0.8 + rng.uniform(0.0, 1.2)
        k = 0
        while x < stop - 0.5:
            top_y, foot_y = a * 0.5, b * 0.5
            # Haut : de l'herbe qui déborde, un buisson.
            if usable(x, j - 0.45, coast=0.3, way=0.5):
                scene = rng.choice(TOP[key])
                place("Talus", scene, x + rng.uniform(-0.3, 0.3), j - 0.45, y=top_y, scale=fit(scene, round(rng.uniform(0.9, 1.2), 2)),
                      flip=rng.random() < 0.5, check=False)
                taluses += 1
            # Pied : fougères, pierres.
            if rng.random() < 0.4 and usable(x + 0.6, j + 0.6, coast=0.3, way=0.5):
                FOOT_SCENE = rng.choice(FOOT[key])
                place("Talus", FOOT_SCENE, x + 0.6 + rng.uniform(-0.3, 0.3), j + 0.6, y=foot_y,
                      scale=fit(FOOT_SCENE, round(rng.uniform(0.9, 1.15), 2)), flip=rng.random() < 0.5, check=False)
                taluses += 1
            # Au flanc : des racines qui pendent d'un rocher (falaises d'un mètre au moins).
            if drop >= 2 and rng.random() < 0.6 and usable(x, j + 0.2, coast=0.3, way=0.9):
                hang = "ivy_wall_b" if rng.random() < 0.55 else "edge_roots"
                place("Talus", hang, x, j + 0.07, y=top_y + 0.12 - 2.0, scale=1.0, flip=rng.random() < 0.5,
                      check=False)
                taluses += 1
            x += rng.uniform(4.4, 6.2)
            k += 1
    # Les joues des rampes (les triangles de terre de chaque côté, vus de biais) : une haie de buissons et de
    # fougères qui s'abaisse avec la joue, du haut vers le bas.
    for (rx, rz, rw, rd), _low, _high in relief.RAMPS:
        for side, dx in ((0, -0.5), (1, rw + 0.5)):
            for frac, scene, scale in ((0.2, "bush_c", 1.25),):
                scene = rng.choice([scene, scene.replace("bush_c", "bush_d")]) if scene.startswith("bush") else scene
                x, z = rx + dx + rng.uniform(-0.15, 0.15), rz + rd * frac
                if land(x, z) and path_distance(x, z) > 0.6:
                    place("Talus", scene, x, z, scale=fit(scene, round(scale * rng.uniform(0.92, 1.12), 2)), flip=side == 1,
                          check=False)
                    taluses += 1
    p.talus_count = taluses

    # === 6. Les terrasses : des bouquets, pas une semence uniforme (7) ====================================

    stations = [
        # Le sommet : bruyère à l'ouest, herbes à l'est, fleurs au nord et vers le rocher.
        ("Summit", 10.6, 11.0, 3, 2.0, "bruyere"), ("Summit", 12.4, 5.6, 3, 1.8, "herbes"),
        ("Summit", 30.0, 14.6, 4, 2.0, "herbes"), ("Summit", 26.8, 4.4, 3, 1.4, "prairie"),
        ("Summit", 12.2, 17.2, 3, 2.0, "prairie"), ("Summit", 28.6, 18.6, 3, 1.8, "bruyere"),
        ("Summit", 22.4, 19.2, 3, 2.0, "herbes"), ("Summit", 9.8, 16.6, 3, 1.4, "pierres"),
        ("Summit", 30.6, 6.8, 3, 1.4, "pierres"), ("Summit", 18.0, 4.0, 2, 1.2, "prairie"), ("Summit", 9.4, 7.6, 3, 1.3, "bruyere"), ("Summit", 15.0, 4.6, 3, 1.2, "bruyere"),
        ("Summit", 25.6, 4.6, 3, 1.2, "herbes"),
        ("Flora", 33.0, 7.6, 3, 1.2, "bruyere"), ("Flora", 33.4, 12.8, 3, 1.3, "pierres"), ("Summit", 12.6, 5.0, 3, 1.3, "bruyere"),
        ("Summit", 24.0, 5.2, 3, 1.3, "herbes"), ("Summit", 28.4, 12.8, 3, 1.2, "fougeres"),
        ("Flora", 33.6, 8.4, 4, 1.4, "herbes"),
        # La terrasse haute.
        ("Flora", 8.6, 22.4, 2, 1.8, "bruyere"), ("Flora", 30.6, 23.0, 4, 2.0, "herbes"),
        ("Flora", 21.0, 23.6, 4, 2.0, "prairie"), ("Flora", 12.4, 24.8, 2, 1.6, "pierres"), ("Flora", 17.8, 25.4, 3, 1.4, "herbes"), ("Flora", 22.0, 28.8, 3, 1.1, "pierres"), ("Flora", 28.6, 27.4, 2, 1.0, "herbes"),
        ("Flora", 33.0, 17.5, 3, 1.6, "bruyere"), ("Flora", 6.8, 16.0, 3, 1.3, "herbes"),
        ("Flora", 33.0, 10.0, 3, 1.6, "buissons"), ("Flora", 7.4, 10.0, 3, 1.4, "buissons"), ("Flora", 6.4, 8.2, 2, 1.0, "herbes"),
        # La terrasse basse.
        ("Flora", 8.0, 30.0, 2, 2.0, "buissons"), ("Flora", 32.0, 30.0, 3, 2.2, "herbes"),
        ("Flora", 17.0, 29.2, 2, 1.8, "prairie"), 
        ("Flora", 34.4, 26.0, 3, 1.6, "bruyere"), 
        ("Flora", 27.6, 31.6, 3, 1.5, "bruyere"),
        # Le pied : fougères et buissons, de plus en plus fermés vers le sud.
        ("Woods", 8.0, 35.6, 4, 2.2, "fougeres"), ("Woods", 31.0, 35.6, 4, 2.2, "fougeres"),
        ("Woods", 34.8, 33.2, 3, 1.4, "buissons"),
    ]
    for group, sx, sz, n, radius, theme in stations:
        cluster(group, sx, sz, n, radius, theme)

    # Garde-fou : le chemin ne franchit aucune marche, même de 0,5 m (le joueur ne la monte qu'en sautant) ; seules
    # les rampes changent de hauteur.
    for name, width, pts in p.paths:
        last = None
        for k in range(len(pts) - 1):
            (ax, az), (bx, bz) = pts[k], pts[k + 1]
            n = max(2, int(math.hypot(bx - ax, bz - az) / 0.25))
            for i in range(n + 1):
                x, z = ax + (bx - ax) * i / n, az + (bz - az) * i / n
                if not flat(x, z):
                    last = None
                    continue
                y = p.height(x, z)
                if last is not None and abs(y - last) > 0.05:
                    p.warnings.append("le chemin %s franchit une marche de %.1f m en (%.1f ; %.1f)" % (
                        name, abs(y - last), x, z))
                    break
                last = y

    # === 7. Le chemin : des pierres plates, des cailloux, une bordure d'herbe ============================
    rng = sect("chemin")

    steps = []
    for name, width, pts in p.paths:
        for k in range(len(pts) - 1):
            (ax, az), (bx, bz) = pts[k], pts[k + 1]
            length = math.hypot(bx - ax, bz - az)
            if length < 1.0:
                continue
            t = rng.uniform(0.6, 1.4)
            while t < length - 0.4:
                f = t / length
                steps.append((ax + (bx - ax) * f + rng.uniform(-0.35, 0.35), az + (bz - az) * f + rng.uniform(-0.3, 0.3)))
                t += rng.uniform(4.0, 5.4)
    for k, (x, z) in enumerate(steps):
        if flat(x, z) and not void_near(x, z, 1.0):
            place("Path", ["pebbles_b", "pebbles_a"][k % 2], x, z, scale=round(rng.uniform(0.8, 1.0), 2), flip=k % 2 == 1,
                  check=False)
    verge = []
    for name, width, pts in p.paths:
        verge += along(pts, 3.2, width / 2.0 + 0.8, 0.4, seed=66 + len(verge))
    verge = [q for q in verge if usable(q[0], q[1], way=0.9) and in_map(q[0], q[1], 0.6)]
    scatter("PathGrass", GRASSES, verge[::6], seed=67, check=False)
    scatter("PathFlowers", ["wildflowers_a", "wildflowers_b", "heather"], verge[1::9], seed=68, check=False)
    scatter("PathStones", ROCKS, verge[2::9], seed=69, check=False)
    peb = [q for q in along([pt for _n, _w, pts in p.paths for pt in pts][:6], 6.0, 1.7, 0.3, seed=71)
           if usable(q[0], q[1], way=0.7)]
    scatter("PathPebbles", ["pebbles_b"], peb[:6], scale=(0.8, 1.0), seed=72, check=False)

    # === 8. Le pied de la colline (z 32 → 38) : le sous-bois, de plus en plus fermé ====================
    rng = sect("pied")

    young = [(6.4, 35.4), (12.5, 36.8), (27.8, 36.2), (32.8, 35.2), (5.2, 33.2), (34.6, 33.0), (9.6, 38.0)]
    scatter("FootTrees", ["sapling_a", "birch_a", "birch_b", "pine_small_a", "pine_small_b"],
            [q for q in young if usable(q[0], q[1], way=1.2)], seed=74)
    place("Woods", "fallen_tree", 31.4, 37.2, name="TroncCouche", flip=True)
    place("Woods", "stump_a", 8.6, 37.4, name="Souche", check=False)
    leaves = poisson(Rect(4.5, 32.6, 35.5, 38.0), 3.6, 7, lambda x, z: usable(x, z, way=1.4, standing=False), seed=73)
    scatter("FootLeaves", ["leaves_gold_a", "leaves_rust_a", "leaves_gold_b", "leaves_rust_b", "leaves_scatter"],
            leaves, scale=(0.9, 1.15), seed=75, check=False)

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
    scatter("SouthTrunks", ["fg_trunk_a", "fg_trunk_b"], trunks[::2], seed=76, check=False)
    scatter("SouthBrush", ["fg_bush", "fg_fern", "fg_grass"], [q for k, q in enumerate(south) if k % 3], seed=77,
            check=False)
    place("Woods", "fg_bush", 15.8, 39.0, name="GapBushWest", check=False)
    place("Woods", "fg_fern", 24.4, 39.0, name="GapFernEast", check=False)
    shade = poisson(Rect(4.5, 30.0, 35.5, 37.5), 6.0, 5, lambda x, z: True, seed=78)
    scatter("Shade", ["canopy_shadow_a", "canopy_shadow_b", "sun_dapple"], shade, scale=(0.9, 1.1), seed=79,
            check=False)

    # === 9. Au-delà des bords : la forêt continue ======================================================
    rng = sect("fond")

    backdrop = [(-5.0, z + rng.uniform(-1.0, 1.0)) for z in (12.0, 19.0, 26.0, 33.0, 40.0)]
    backdrop += [(45.0, z + rng.uniform(-1.0, 1.0)) for z in (12.0, 18.0, 24.0, 30.0, 36.0, 41.0)]
    for k, (x, z) in enumerate(backdrop):
        scene = (TREES_DARK + TREES_RUST)[k % 12]
        place("Backdrop", scene, x, z, y=0.0, name="Backdrop%d" % (k + 1), flip=k % 2 == 1, check=False)

    # === 10. Le vide au nord : des rochers qui flottent, des îles, la brume, l'horizon =================

    # De l'arrière à l'avant (les plus lointains d'abord) : ce que la caméra voit sous la ligne du bord se perd
    # derrière la terre, au-dessus, la mer de nuages, des îles qui la dépassent et des rochers plus proches.
    sky = SKY_ISLANDS + SKY_CLOUDS + SKY_MIST + SKY_ROCKS
    for k, (x, y, z, scale, scene) in enumerate(sky):
        place("Sky", scene, x, z, y=y, scale=scale, name="Vide%d" % (k + 1), flip=k % 3 == 1, check=False)


def ambient(p):
    """Vie ambiante : quelques feuilles d'automne que le vent calme porte ; ni lucioles (fin d'automne),
    ni oiseaux de jour (la colline est de nuit : la chouette est un animal d'E5)."""
    return [
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 5, (30, 9, 30), 0.0, (0, 0), 0.7, 0.8, 4, (20, 0, 20)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 4, (30, 9, 30), 0.0, (0, 0), 0.8, 0.8, 5, (20, 0, 20)),
    ]


def ground_plan(m):
    return relief.ground_plan(m)
