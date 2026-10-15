"""(CF) La forêt profonde : la pose de la carte `foret_profonde` d'après docs/lore/CARTE.md, section 8 (bloc
```plan lu par tools/carte_plans.py). Elle remplace la carte d'attente du même nom.

Ce que dit l'œuvre (8) : des bosquets profonds, des fourrés aux petites branches qui percent la peau (V1, « Entrepôt de
fées ») ; une forêt assez dense où l'eau s'accumule dans des creux difficiles à voir, dangereux pour les enfants (V5,
épilogue) ; la rivière où l'on puise l'eau du bain (V3) ; Chtholly s'y enfuit quand c'est trop (VEX, « Des émotions sans
nom ») ; un petit animal grimpeur poursuivi par une fillette (V5). Le refuge de Chtholly (un chêne creux) est original.

Composition vue de la caméra (elle regarde le nord ; CARTE.md 0.3) :
- on entre par le nord (le sentier de l'entrepôt) et l'on descend vers le sud ; la rivière traverse la carte du nord-ouest
  au sud-est, en méandres, son lit à −0,5 m, ses berges de galets ; on la passe au gué (un tronc, des rampes de gravier) ;
  trois branches du sentier : le refuge (ouest), la clairière des cerfs (nord-est), la souille (sud-ouest) ; un sentier
  mène à l'est, vers la montagne ;
- deux ressauts rocheux à +1 m : au nord-est (la clairière des cerfs s'adosse à sa falaise) et au sud-ouest ;
- la forêt ferme la carte : au nord, à l'ouest et à l'est des pans de forêt (images de 16 m) posés en chaînes qui se
  chevauchent, dont aucun bout n'est à découvert (CARTE.md 8, écarts : la règle de pose des lisières) ; un rang d'arbres
  devant ; au sud, du premier plan (troncs, buissons, fougères) qui s'efface devant le joueur ;
- au milieu, une futaie d'arbres isolés (chênes, hêtres, érables, sapins) sur un sous-bois de fougères, de fourrés, de
  ronces, de champignons, de feuilles et de racines ; des taches de lumière et des rais ; des bosquets, un sapin abattu,
  un sorbier ; le refuge, un grand chêne creux, à l'ouest, creux tourné vers le sud.

Aucune lumière dans la carte : la lumière est celle d'Atmosphere (le jour vert et or, le soir bleu sombre).
"""

import math
import random

import exterior_ground
import map_build
from exterior_pose import Rect, along, poisson, prop, seg_distance

SETTINGS = {
    "groups": ["Wall", "Belt", "River", "Trees", "Groves", "Under", "Path", "Refuge", "Clearing", "Sky"],
    "no_lights": True,
    # Le nœud Life/Fauna d'E5 (cerfs, loups, sanglier, renard, écureuils, corbeaux, grenouilles, chouette).
    "fauna": True,
    # La montagne n'existe pas encore : sa sortie est omise, un écriteau ferme le sentier de l'est.
    "omit_if_missing": ("vers_montagne",),
    "texts": "res://data/texts/foret_profonde.json",
    # Objets à examiner (data/texts/foret_profonde.json, section « foret_profonde ») : (clé, x, z, taille de la zone).
    "examine": [
        ("refuge_creux", 16.0, 38.4, (2.6, 2.0, 1.6)),
        ("mare_cachee", 29.5, 45.4, (3.0, 2.0, 1.6)),
        ("gue", 44.5, 30.0, (3.2, 2.0, 1.6)),
        ("lisiere_riviere", 52.0, 30.6, (3.0, 2.0, 1.6)),
        ("cerfs", 63.0, 13.4, (3.2, 2.0, 2.0)),
        ("souille", 24.0, 48.8, (3.0, 2.0, 1.6)),
        ("loups", 68.0, 52.6, (3.0, 2.0, 1.8)),
    ],
}

# Places de la vie que le plan ne nomme pas : (nom, x, z, regard en degrés, à quoi elles servent). Écrites en
# Life/Places (Marker3D) et listées dans CARTE.md par `exterior_maps.py places`.
PLACES_WHY = [
    ("vers_entrepot", 40.0, 2.6, 0.0, "le haut du sentier, devant la sortie : par où l'on part vers l'entrepôt, et d'où l'on en arrive"),
    ("course_entree", 40.0, 9.0, 0.0, "le sentier au sortir de l'entrepôt : le début de la course libre de Chtholly (ACTE1.md 10.2)"),
    ("fourche_refuge", 42.4, 21.0, 0.0, "la fourche du refuge, au nord du gué : on quitte le sentier de la montagne vers l'ouest"),
    ("gue_nord", 43.4, 22.8, 0.0, "la rive nord du gué : on y puise l'eau du bain (V3), les petites s'y mouillent les pieds"),
    ("gue_sud", 45.6, 31.2, 0.0, "la rive sud du gué, au pied du sentier de la montagne"),
    ("refuge_seuil", 16.0, 41.2, 0.0, "devant le creux du chêne, regard au nord : où Chtholly s'écroule et s'assied (ACTE1.md 10.2, `refuge_creux`)"),
    ("refuge_ithea", 18.8, 40.6, 0.0, "à côté du creux : où Ithea s'assoit sans rien demander (ACTE1.md 10.2)"),
    ("refuge_retour", 22.6, 41.0, 0.0, "la sortie du refuge vers le sentier : par où Ithea ramène Chtholly"),
    ("renard_berge", 50.0, 31.4, 0.0, "la berge sud où le renard s'arrête avant de traverser (VIE.md, faune)"),
    ("clairiere_cerfs_centre", 63.0, 13.0, 0.0, "le milieu de la clairière : les cerfs y broutent à l'aube et au soir (VIE.md, faune)"),
]

DEVIATIONS = [
    "la rivière est peinte au niveau du sol, sans lit à −0,5 m : le plan donne six rectangles de lit (palier −0,5) ; "
    "sur une rivière qui court en diagonale, la grille d'un mètre en faisait une scie de marches de 0,5 m (faces de terre "
    "à lèvre d'herbe tous les deux mètres), lue comme des terrasses en plaques (docs/QUALITE.md, QC-29 ; C3b) ; le lit "
    "(`stream_bed`) et l'eau basse restent peints en méandres sur les centres des rectangles du plan, on y marche, le "
    "gué n'a plus besoin de rampes (le tronc `log_bridge_b` et des pierres plates y restent) ; les deux ressauts à +1 m "
    "gardent le relief de la carte",
    "les deux ressauts rocheux (+1 m) ne sont plus des rectangles : leurs contours sont irréguliers (tronçons de 3 à 6 m "
    "décalés d'un ou deux mètres), leurs faces sont des talus de terre (la roche en briques se lisait comme un mur de "
    "soutènement) habillés de fougères, de buissons et de rochers moussus ; on ne les gravit pas (1 m)",
    "les chemins ne sont plus des rectangles de `path_overgrown` : la terre (`sentier_ombre`, la tuile `path_dirt` "
    "assombrie) est peinte sur la bande du chemin seulement (1,8 m dans la bande libre de 3 m), sauf sur l'eau",
    "la sortie `vers_montagne` n'est pas posée tant que la carte `montagne` n'existe pas ; un écriteau « Plus loin, "
    "bientôt » ferme le sentier de l'est",
    "les lisières (règle de pose, CARTE.md 0.3 et docs/QUALITE.md) : `bord foret` est posé en trois chaînes de pans de "
    "forêt qui se chevauchent (nord : un rideau continu derrière à z −2, un rang à la lisière ; ouest ; est), aucun bout de "
    "pan n'est à découvert : chaque bout est couvert par un pan plus proche ou par un grand tronc de premier plan "
    "(`SeamTrunk*`) et son buisson ; le sud est du premier plan (troncs, buissons, fougères) comme le plan le dit",
    "les décors du plan sont des remplaçants du lot R5 (tools/hd2d_foret.py, manifeste) : `refuge_oak` (dérivé du chêne creux "
    "`oak_c` livré), `grove_dense`, `fallen_pine`, `rowan`, `hidden_pool_a` et `_b`, `log_bridge_b`, `river_bank`, "
    "`river_rapids`, `forest_wall_deep` ; une image livrée les remplace sans toucher au code",
    "les rais de lumière (`light_shaft_a` et `_b`) sont posés sur le refuge et sur la clairière des cerfs ; pas d'ombres de "
    "feuillage ni de taches de soleil au sol (`canopy_shadow_*`, `sun_dapple` : des fantômes grisâtres) ; aucune lumière dans "
    "la carte, la pénombre est celle d'Atmosphere (le couchant bleu sombre des loups, VIE.md)",
    "les mares cachées (`hidden_pool_a` et `_b`) sont de l'eau basse (le plan ne dit pas « profonde ») : la glissade dans la "
    "mare (VIE.md 6.4) est au moteur (CONTRACT_REQUESTS.md, CF)",
]

# La rivière : la ligne du milieu de son lit (x, z), de la lisière nord-ouest au bord est ; le plan la dessine en six
# rectangles (CARTE.md 8 : x 6 → 80), les méandres passent par leurs centres.
RIVER = [(8.0, -4.0), (8.4, 4.0), (12.0, 9.2), (18.0, 13.2), (24.0, 17.4), (30.0, 20.8), (37.0, 24.0), (44.0, 26.6),
         (52.0, 28.2), (60.0, 30.6), (68.0, 33.2), (75.0, 34.2), (84.0, 34.6)]
BED = 5.2
WATER = 3.6
BAND = BED + 0.4


def river_z(x):
    """Ordonnée de la ligne du milieu de la rivière en x (interpolation de RIVER)."""
    for (x0, z0), (x1, z1) in zip(RIVER, RIVER[1:]):
        if x0 <= x <= x1:
            return z0 + (z1 - z0) * (x - x0) / (x1 - x0)
    return RIVER[0][1] if x < RIVER[0][0] else RIVER[-1][1]


def ground_plan(m):
    plan = exterior_ground.ground_from_plan(
        m, noise=1.0, comment="Sol en relief de la forêt profonde (lot CF), d'après docs/lore/CARTE.md, section 8 : "
                              "la rivière en méandres (peinte au niveau du sol), deux ressauts rocheux (+1 m) aux contours "
                              "irréguliers, des nappes de feuilles, de mousse et de boue. Lu "
                              "par tools/map_build.py gen foret_profonde ; le jeu ne lit pas ce fichier.")
    plan["materials"].update({
        "sous_bois_sombre": {"label": "Sous-bois sombre (forest_floor)", "layer": "forest_floor", "color": "#2f5a30",
                             "tint": [1.12, 1.15, 1.12]},
        "mousse_claire": {"label": "Mousse claire (moss)", "layer": "moss", "color": "#3aa86c", "tint": [1.2, 1.2, 1.18]},
        "sentier_ombre": {"label": "Sentier de sous-bois (path_dirt)", "layer": "path_dirt", "color": "#b48a56",
                          "variant": False, "path": True, "tint": [0.78, 0.76, 0.7]},
    })
    plan["base"]["material"] = "sous_bois_sombre"
    path_steps = [s for s in plan["steps"] if s["op"] == "path"]
    steps = []

    def level(poly, lv, seed, noise=0.5):
        steps.append({"op": "level", "level": lv, "shape": {"poly": [list(q) for q in poly], "noise": noise,
                                                            "noise_scale": 3.2, "seed": seed}})

    def material(shape, name, seed, noise=0.9, scale=2.2, where=None):
        step = {"op": "material", "material": name, "shape": dict(shape, noise=noise, noise_scale=scale, seed=seed)}
        if where:
            step["where"] = where
        steps.append(step)

    # Les ressauts à +1 m (palier 2) : contours irréguliers, tronçons de 3 à 6 m décalés d'un ou deux mètres.
    level([(51.0, -3), (83, -3), (83, 7.6), (78.4, 7.6), (78.4, 8.8), (73.0, 8.8), (73.0, 7.4), (67.6, 7.4),
           (67.6, 8.6), (62.2, 8.6), (62.2, 7.8), (58.0, 7.8), (58.0, 8.9), (54.4, 8.9), (54.4, 7.0), (51.0, 7.0)],
          2, 11)
    level([(-3, 45.0), (3.6, 45.0), (3.6, 46.4), (8.4, 46.4), (8.4, 45.4), (11.6, 45.4), (11.6, 48.6), (12.8, 48.6),
           (12.8, 53.4), (11.4, 53.4), (11.4, 59.0), (-3, 63)], 2, 12)
    steps.append({"op": "face", "face": "earth", "shape": {"rect": [0, 0, 80, 60]}})
    # Les matières : un sous-bois sombre ; de la mousse le long de la rivière et autour du refuge ; des feuilles en
    # grandes nappes ; la clairière des cerfs en herbe ; la souille en boue ; le lit et l'eau de la rivière.
    band = [list(q) for q in RIVER]
    material({"band": band, "width": BAND + 7.0}, "mousse", 21, noise=2.0, scale=3.0, where={"level": 0})
    material({"ellipse": [16, 40, 9.5, 6.5]}, "mousse_claire", 22, noise=1.6, scale=2.6, where={"level": 0})
    for k, (cx, cz, rx, rz) in enumerate(((36, 40, 8.0, 5.0), (56, 42, 9.0, 5.5), (66, 22, 6.0, 4.5), (26, 6, 6.5, 3.5),
                                          (24, 32, 5.0, 3.0), (48, 17, 6.0, 3.2), (70, 56, 7.0, 3.0), (44, 55, 6.0, 2.5))):
        material({"ellipse": [cx, cz, rx, rz]}, "feuilles", 30 + k, noise=1.3, scale=2.4, where={"level": 0})
    material({"ellipse": [63, 13.2, 10.0, 5.2]}, "herbe", 40, noise=1.4, scale=2.4, where={"level": 0})
    material({"ellipse": [60, 12.4, 4.6, 2.4]}, "prairie", 41, noise=1.0, scale=1.8, where={"material": "herbe"})
    material({"ellipse": [24, 51, 4.6, 3.1]}, "boue", 42, noise=0.9, scale=1.8, where={"level": 0})
    material({"ellipse": [68, 52.5, 6.0, 2.6]}, "feuilles", 43, noise=1.2, scale=2.0, where={"level": 0})
    material({"band": band, "width": BED}, "lit_ruisseau", 44, noise=0.7, scale=2.8, where={"level": 0})
    material({"band": band, "width": WATER}, "eau_basse", 45, noise=0.6, scale=2.8, where={"level": 0})
    # Les chemins (qui ne se peignent pas sur l'eau).
    for s in path_steps:
        s = dict(s, material="sentier_ombre", noise=0.3, where={"not_material": ["eau_basse", "lit_ruisseau"]})
        steps.append(s)
    plan["steps"] = steps
    return plan




TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c", "birch_a", "birch_b"]
TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn", "oak_a"]
TREES_DARK = ["tree_pine", "tree_pine", "pine_tall_b", "oak_a", "oak_d", "beech_b", "tree_old_pine"]
CONIFERS = ["tree_pine", "pine_tall_b", "tree_old_pine"]
SMALL_TREES = ["pine_small_a", "pine_small_b", "sapling_a", "birch_a", "birch_b"]
BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f", "berry_bush", "berry_bush_b"]
FERNS = ["fern_a", "fern_b", "fern_c", "fern_d", "fern_d"]
GRASSES = ["grass_clump_a", "grass_clump_b", "grass_clump_c", "grass_clump_d", "tall_grass"]
ROCKS = ["rock_small_a", "rock_small_b", "rock_small_c", "rock_small_d"]
WALLS = ["forest_wall_deep", "forest_wall_b", "forest_wall_a", "forest_wall_deep", "forest_wall_c"]


def prepare(p):
    pass


def pose(p):
    M, W, D = p.map, p.W, p.D
    place, scatter = p.place, p.scatter
    in_map, outside_edges, path_distance = p.in_map, p.outside_edges, p.path_distance
    levels, kinds = p.ground.levels, p.ground.kinds
    p.walk_grid()
    counters = {}

    def named(base):
        counters[base] = counters.get(base, 0) + 1
        return "%s_%d" % (base, counters[base])

    def sect(name):
        return random.Random("foret_profonde/" + name)

    def cell(x, z):
        i, j = int(math.floor(x)), int(math.floor(z))
        if not (0 <= i < W and 0 <= j < D):
            return None
        return j * W + i

    def level_of(x, z):
        c = cell(x, z)
        return None if c is None else levels[c]

    def river_d(x, z):
        """Distance au bord du lit de la rivière (négative dans le lit)."""
        best = 99.0
        for a, b in zip(RIVER, RIVER[1:]):
            best = min(best, seg_distance(x, z, a, b))
        return best - BAND / 2.0

    def dry(x, z, bank=0.7):
        """Terre ferme à +0 m (ni le ressaut ni la rivière), loin de la berge."""
        c = cell(x, z)
        return c is not None and levels[c] == 0 and kinds[c] == map_build.FLAT and river_d(x, z) > bank

    reserved = list(p.points.values()) + list(p.markers.values())
    # Les endroits où le joueur se tient : points, marqueurs, places (en grille de 3 m) et chemins (tous les 3 m). Un grand
    # arbre à moins de 9 m au sud d'eux, à moins de 3,6 m de leur colonne, cacherait le joueur (docs/QUALITE.md : pas
    # d'arbre de premier plan qui cache le joueur) : la futaie les évite, il n'y reste que des arbres de côté.
    keys = list(reserved)
    for pl in p.places.values():
        kx = pl.x0
        while kx <= pl.x1:
            kz = pl.z0
            while kz <= pl.z1:
                keys.append((kx, kz))
                kz += 3.0
            kx += 3.0
    for _name, _width, pts in p.paths:
        for (ax, az), (bx, bz) in zip(pts, pts[1:]):
            length = math.hypot(bx - ax, bz - az)
            for k in range(int(length / 3.0) + 1):
                f = min(1.0, k * 3.0 / max(length, 0.01))
                keys.append((ax + (bx - ax) * f, az + (bz - az) * f))

    def shadows_a_player(x, z):
        return any(0.0 < z - kz < 9.0 and abs(x - kx) < 3.6 for kx, kz in keys)

    def usable(x, z, way=0.6, bank=0.7, standing=True, edge=0.0):
        """Un point où l'on peut poser un décor : terre ferme, dans la carte, hors des bords, loin du chemin et de la
        rivière, hors des places réservées (pour ce qui se dresse), loin des points, des marqueurs et des sorties."""
        if not in_map(x, z, 0.5) or not dry(x, z, bank) or not outside_edges(x, z, edge):
            return False
        if path_distance(x, z) < way:
            return False
        for px, pz in reserved:
            if abs(px - x) < 1.3 and abs(pz - z) < 1.3:
                return False
        if any(e.has(x, z, 1.4) for e in p.exits):
            return False
        if standing and any(pl.has(x, z, 0.0) for pl in p.places.values()):
            return False
        return True

    # === 1. L'ossature du plan (8) ==============================================================================

    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        flip = len(p.singles) % 2 == 1
        if n in ("hidden_pool_a", "hidden_pool_b"):
            place("River", n, x, z, name=named(n.title().replace("_", "")), flip=flip, check=False)
        elif n == "log_bridge_b":
            place("River", n, x, z, name="LogBridge", check=False)
        elif n == "refuge_oak":
            place("Refuge", n, x, z, name="RefugeOak")
        elif n in ("fallen_pine", "grove_dense", "rowan", "log_hollow", "thicket_a", "thicket_b"):
            place("Groves", n, x, z, name=named(n.title().replace("_", "") + "_plan"), flip=flip)
        elif n == "mushroom_cep":
            place("Under", n, x, z, name="Cep_plan", check=False)
        else:
            p.warnings.append("décor du plan non posé : %s" % n)
    for t in M.trees:
        x, z = (t.rect.x0 + t.rect.x1) / 2.0, (t.rect.z0 + t.rect.z1) / 2.0
        place("Trees", t.name, x, z, name=named("Tree_plan"))
    p.walk_grid()

    # === 2. Les pans de forêt : trois chaînes (nord, ouest, est) qui se chevauchent ===============================
    # Règle de pose (QC) : une image de lisière dont le bord vertical est opaque ne paraît jamais seule dans le champ, où sa
    # tranche se lirait comme une bande à bord franc. Un pan de 16 m a un corps opaque qui va de 0,7 m à 15,3 m ; deux pans
    # voisins se recouvrent de 2 à 3 m (le plus proche de la caméra cache le bout de l'autre), le bout du pan de devant est
    # caché par un grand arbre planté sur la ligne de la lisière (§ 3), les bouts des chaînes sont hors du champ de la
    # caméra (au-delà de la carte). L'image est pleine jusqu'à ses bords dans sa moitié basse (le sous-bois, ±8 m) et son
    # corps haut (la voûte) s'arrête à ±7,3 m : les bouts sont à ±8 m, un pan plus proche ne les recouvre que là où son
    # corps haut les couvre (à 1,2 m de ses bords). `walls` garde (nom, x du centre, z, y) de chaque pan.
    walls = []

    def wall(name, scene, x, z, y=0.0, flip=False):
        place("Wall", scene, x, z, y=y, name=name, flip=flip, check=False)
        walls.append((name, x, z, y))

    # Au nord : un rideau continu derrière (z −2), un rang devant à la lisière (z 5 à 5,6 à l'ouest de la trouée de
    # l'entrée, 3 à 3,9 à l'est, où la lisière est à z 4).
    for k in range(9):
        x = -4.0 + 12.5 * k
        wall("WallNorthBack%d" % (k + 1), WALLS[(k + 1) % len(WALLS)], x, -2.0 - 0.3 * (k % 2), 1.0 if x > 56 else 0.0,
             k % 2 == 1)
    front = [(18.0, 5.2, 0.0), (29.0, 5.5, 0.0), (51.2, 3.0, 0.0), (63.7, 3.3, 1.0), (76.2, 3.6, 1.0), (88.7, 3.9, 1.0)]
    for k, (x, z, y) in enumerate(front):
        wall("WallNorth%d" % (k + 1), WALLS[k % len(WALLS)], x, z, y, k % 2 == 0)
    # À l'ouest : x −2 (leur collision s'arrête à x 6, la lisière), du nord au sud, chacun un peu devant le précédent.
    west = [(-2.0, 12.0, 0.0), (-2.6, 23.4, 0.0), (-2.0, 34.8, 0.0), (-2.6, 46.2, 0.0), (-4.0, 57.0, 1.0)]
    for k, (x, z, y) in enumerate(west):
        wall("WallWest%d" % (k + 1), WALLS[(k + 2) % len(WALLS)], x, z, y, k % 2 == 1)
    # À l'est : x 84 au nord du passage de la rivière, x 88 au sud (le sentier de la montagne reste vu).
    east = [(84.0, 14.0, 0.0), (84.0, 26.0, 0.0), (88.0, 41.0, 0.0), (88.0, 55.0, 0.0)]
    for k, (x, z, y) in enumerate(east):
        wall("WallEast%d" % (k + 1), WALLS[(k + 3) % len(WALLS)], x, z, y, k % 2 == 0)
    p.walls = walls
    p.walk_grid()

    # === 3. Le rang d'arbres de la lisière : il cache les bouts des pans =========================================
    rng = sect("lisiere")
    # (x, z, scène) : les grands arbres exactement sur les bouts des pans de devant, puis un rang régulier entre eux.
    belt = [(12.6, 6.8, "willow"), (21.7, 6.6, "pine_tall_b"), (35.6, 6.6, "tree_old_pine"), (44.8, 4.9, "tree_old_pine"),
            (56.6, 5.0, "pine_tall_b"), (69.2, 5.2, "tree_old_pine"), (79.6, 5.4, "pine_tall_b")]
    for k, (x, z, scene) in enumerate(belt):
        place("Belt", scene, x, z, name="BeltNorth%d" % (k + 1), flip=k % 2 == 1)
    row = [(15.2, 7.0), (27.8, 7.0), (31.6, 6.9), (47.6, 5.2), (52.2, 4.8), (62.0, 5.6), (65.6, 5.4), (73.0, 5.8)]
    scatter("BeltNorthRow", TREES_RUST[:4] + TREES_DARK[:3] + ["oak_c"], row, seed=31)
    # Entre les pans de l'ouest et de l'est, au sud : un rang plus serré et plus petit (les pans y sont hors champ).
    col_w = [(4.6, 8.8), (4.0, 17.8), (4.8, 29.4), (4.2, 40.6), (3.6, 50.0), (6.0, 53.8)]
    col_e = [(77.8, 9.0), (77.4, 20.0), (77.8, 30.0), (77.2, 38.4), (77.8, 51.6)]
    scatter("BeltWestMid", TREES_RUST[:3] + TREES_DARK[:3], col_w, seed=32)
    scatter("BeltEastMid", TREES_GOLD[:3] + TREES_DARK[:3], col_e, seed=33)
    p.walk_grid()

    # === 4. La futaie : des arbres isolés, plus serrés au nord et à l'ouest, plus clairs à l'est =====================
    rng = sect("futaie")
    field = Rect(6.5, 6.5, 74.5, 55.0)
    spots = poisson(field, 9.0, 120, lambda x, z: usable(x, z, way=3.8, bank=2.4) and not shadows_a_player(x, z) and not any(
        math.hypot(x - px, z - pz) < 4.6 for px, pz in reserved), seed=41)
    broad_gold, broad_rust, conifers = [], [], []
    for k, (x, z) in enumerate(spots):
        kind = rng.random()
        east = x > 46.0
        if kind < (0.34 if east else 0.5):
            conifers.append((x, z))
        elif kind < 0.68:
            broad_rust.append((x, z))
        else:
            broad_gold.append((x, z))
    scatter("TreesConifers", ["tree_pine", "pine_tall_b", "tree_pine", "tree_old_pine"], conifers, scale=(0.9, 1.1), seed=42)
    scatter("TreesRust", TREES_RUST, broad_rust, scale=(0.9, 1.1), seed=43)
    scatter("TreesGold", TREES_GOLD, broad_gold, scale=(0.9, 1.1), seed=44)
    # De jeunes arbres entre les grands.
    young = poisson(field, 6.0, 90, lambda x, z: usable(x, z, way=1.6, bank=1.4) and not shadows_a_player(x, z) and all(
        math.hypot(x - sx, z - sz) > 4.2 for sx, sz in spots), seed=45)
    scatter("TreesYoung", SMALL_TREES, young, scale=(0.9, 1.15), seed=46)
    p.walk_grid()

    # === 5. Les fourrés, les ronces, les bosquets ====================================================================
    rng = sect("fourres")
    thick = poisson(field, 11.0, 30, lambda x, z: usable(x, z, way=2.0, bank=1.5), seed=51)
    scatter("Thickets", ["thicket_a", "thicket_b"], thick[::2], scale=(0.85, 1.1), seed=52)
    scatter("Brambles", ["bramble_hedge"], thick[1::2], scale=(0.7, 0.85), seed=53, check=False)
    p.walk_grid()

    # === 6. Le sous-bois : des bouquets, pas une semence uniforme =====================================================
    themes = {
        "fougeres": ["fern_a", "fern_b", "fern_c", "fern_d", "fern_d", "fern_b", "mushroom_cep"],
        "orties": ["nettles", "nettles", "grass_clump_d", "fern_c", "thistle", "nettles"],
        "buissons": BUSHES[:6] + ["fern_a", "bush_e"],
        "champignons": ["mushroom", "mushroom_cep", "mushroom_chanterelle", "fern_d", "leaves_rust_a", "mushroom"],
        "herbes": GRASSES + ["fern_b", "heather"],
        "baies": ["berry_bush", "berry_bush_b", "bush_d", "bush_f", "fern_a", "grass_clump_b"],
    }
    names = list(themes)
    centres = poisson(field, 5.2, 400, lambda x, z: usable(x, z, way=1.1, bank=1.2, standing=False), seed=61)
    for k, (cx, cz) in enumerate(centres):
        r = random.Random("foret_profonde/bouquet %d" % k)
        theme = names[(k * 7 + int(cx) // 9) % len(names)]
        n = r.randint(3, 4)
        pts, scenes = [], []
        for _ in range(n * 6):
            if len(pts) >= n:
                break
            a, d = r.uniform(0, math.tau), 1.9 * math.sqrt(r.random())
            x, z = cx + d * math.cos(a) * 1.25, cz + d * math.sin(a)
            if usable(x, z, way=0.9, bank=1.0, standing=False):
                pts.append((x, z))
                scenes.append(r.choice(themes[theme]))
        for q, scene in zip(pts, scenes):
            place("Under", scene, q[0], q[1], scale=round(r.uniform(0.9, 1.2), 2) if not scene.startswith("bush") else
                  round(r.uniform(0.85, 1.05), 2), flip=r.random() < 0.5, check=False)
    p.walk_grid()

    # === 3b. Les troncs des jointures : un grand tronc de premier plan couvre chaque bout de pan à découvert =============
    # Un bout est à découvert s'il est dans le champ de la caméra (x de −6,5 à 86,5 : 10 m de part et d'autre du point visé,
    # 16 m en haut de l'écran) et qu'aucun pan plus proche de la caméra ne le recouvre (son corps, à 1,2 m des bords).
    seams = 0
    for name, xc, z, y in walls:
        for side in (-1, 1):
            end = xc + 8.0 * side
            if not -6.5 < end < 86.5:
                continue
            if any(z2 > z + 0.05 and x2 - 7.3 + 1.2 < end < x2 + 7.3 - 1.2 for _n, x2, z2, _y in walls):
                continue
            seams += 1
            inside = -0.35 * side
            if z < 8.0 or name.startswith("WallNorth"):
                # Au nord : un grand tronc de premier plan (sa cime est au-delà du haut de l'écran).
                place("Belt", ["fg_trunk_a", "fg_trunk_b"][seams % 2], end + inside, z + 0.7, y=y,
                      name="SeamTrunk%d" % seams, flip=seams % 3 == 0, check=False)
            else:
                # À l'ouest et à l'est : un grand conifère (sa pointe se voit : un tronc coupé en l'air se verrait) et un feuillu
                # qui l'épaule, sur la ligne de la lisière.
                place("Belt", ["tree_old_pine", "pine_tall_b"][seams % 2], end + inside, z + 1.0, y=y,
                      name="SeamPine%d" % seams, flip=seams % 2 == 0)
                place("Belt", ["oak_a", "beech_b", "oak_d", "beech_c"][seams % 4], end + 3.0 * inside, z + 2.4,
                      y=y, name="SeamBroad%d" % seams, flip=seams % 2 == 1)
            for k, (dx, scene) in enumerate(((-1.3, "bush_e"), (1.2, "fern_d"), (0.1, "thicket_b"))):
                place("Belt", scene, end + dx, z + 1.5 + 0.3 * k, y=y, name="SeamBrush%d_%d" % (seams, k + 1),
                      flip=k % 2 == 1, check=False)
    p.seam_trunks = seams

    # === 7. La rivière : berges, remous, nénuphars, saules, gué ======================================================
    rng = sect("riviere")
    # La berge nord (celle que la caméra voit de face) : des panneaux de galets et de racines, au ras de l'eau.
    t = 0.0
    bank_pts = []
    for (ax, az), (bx, bz) in zip(RIVER, RIVER[1:]):
        length = math.hypot(bx - ax, bz - az)
        nx, nz = (bz - az) / length, -(bx - ax) / length  # la normale qui regarde le nord
        if nz > 0:
            nx, nz = -nx, -nz
        s = rng.uniform(0.0, 3.0)
        while s < length:
            f = s / length
            q = (ax + (bx - ax) * f + nx * (WATER / 2.0 + 0.55), az + (bz - az) * f + nz * (WATER / 2.0 + 0.55))
            bank_pts.append(q)
            s += rng.uniform(7.0, 10.0)
    for k, (x, z) in enumerate(bank_pts):
        if 4.5 < x < 77.0 and path_distance(x, z) > 1.0 and not any(abs(x - px) < 3.0 and abs(z - pz) < 3.0 for px, pz in reserved):
            place("River", "river_bank", x, z, name="RiverBank%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Les remous autour des rochers à fleur d'eau (un par tronçon), des nénuphars et des galets.
    for k, x in enumerate((15.0, 21.5, 27.0, 33.0, 50.0, 56.0, 64.0, 72.0)):
        z = [q for q in RIVER if q[0] >= x][0][1] + rng.uniform(-0.6, 0.6)
        place("River", "river_rapids", x, z, name="Rapids%d" % (k + 1), flip=k % 2 == 1, check=False)
    water = poisson(Rect(6.0, 0.5, 80.0, 38.0), 3.4, 80, lambda x, z: river_d(x, z) < -0.2 and 4.5 < x < 79 and
                    path_distance(x, z) > 1.5, seed=71)
    scatter("LilyPads", ["lily_pads"], [(x, z, rng.uniform(0, 360)) for x, z in water[::3]], scale=(0.8, 1.1), seed=72,
            check=False)
    scatter("RiverStones", ROCKS + ["rock_pile", "mossy_rock"], water[1::6], scale=(0.9, 1.2), seed=73, check=False)
    shore = poisson(Rect(6.0, 0.5, 80.0, 40.0), 2.6, 120, lambda x, z: 0.3 < river_d(x, z) < 1.3 and usable(
        x, z, way=1.4, bank=0.2, standing=False), seed=74)
    scatter("ShoreReeds", ["reeds", "cattails", "reeds_b", "cattails"], shore[::3], scale=(0.9, 1.15), seed=75, check=False)
    scatter("ShorePebbles", ["pebbles_a", "pebbles_b"], [(x, z, rng.uniform(0, 360)) for x, z in shore[1::3]],
            scale=(0.9, 1.2), seed=76, check=False)
    scatter("ShoreMoss", ["moss_patch_a", "moss_patch_b"], [(x, z, rng.uniform(0, 360)) for x, z in shore[2::3]],
            scale=(0.9, 1.2), seed=77, check=False)
    # Deux saules et un aulne sur les berges, loin des gués (de grands arbres : premier plan quand ils cachent quelqu'un).
    for k, (x, z, scene) in enumerate(((19.5, 11.0, "willow"), (31.0, 18.6, "alder"), (58.0, 24.6, "willow"))):
        if usable(x, z, way=2.0, bank=0.2):
            place("River", scene, x, z, name="Bank%s%d" % (scene.title(), k + 1), flip=k % 2 == 1)
    # Le gué : des pierres plates à fleur d'eau de part et d'autre du tronc, et la vase du passage.
    for k, (x, z) in enumerate(((42.4, 27.6), (46.6, 27.4), (43.6, 29.4), (45.8, 25.8))):
        place("River", "stepping_stones", x, z, name="FordStones%d" % (k + 1), flip=k % 2 == 1, check=False)
    p.walk_grid()

    # === 8. Les chemins : racines, cailloux, feuilles, un jalon aux fourches =====================================
    rng = sect("chemins")
    verge = []
    for name, width, pts in p.paths:
        verge += along(pts, 3.4, width / 2.0 + 0.5, 0.5, seed=81 + len(verge))
    verge = [q for q in verge if usable(q[0], q[1], way=0.9, bank=0.3, standing=False) and in_map(q[0], q[1], 0.6)]
    scatter("PathRoots", ["roots_a", "roots_b", "path_root_step"], [(q[0], q[1], rng.uniform(0, 360)) for q in verge[::5]],
            scale=(0.85, 1.1), seed=82, check=False)
    scatter("PathStones", ROCKS + ["mushroom", "fern_c"], verge[1::5], seed=83, check=False)
    scatter("PathLeaves", ["leaves_gold_a", "leaves_rust_a", "leaves_gold_b", "leaves_rust_b"],
            [(q[0], q[1], rng.uniform(0, 360)) for q in verge[2::4]], scale=(0.9, 1.15), seed=84, check=False)
    scatter("PathGrass", GRASSES[:4] + FERNS[:3], verge[3::5], seed=85, check=False)
    for k, (x, z) in enumerate(((38.4, 12.6), (42.0, 22.6), (48.6, 37.8), (26.8, 49.0))):
        if in_map(x, z, 1.0):
            place("Path", "trail_ribbon_stake", x, z, name="PathStake%d" % (k + 1), check=False)

    # === 9. Le sol : des feuilles, des racines, des taches d'ombre et de soleil =====================================
    rng = sect("sol")
    floor_pts = poisson(Rect(4.0, 4.0, 77.0, 57.0), 3.3, 400, lambda x, z: usable(x, z, way=0.6, bank=0.4, standing=False),
                        seed=91)
    yawed = [(x, z, rng.uniform(0, 360)) for x, z in floor_pts]
    scatter("FloorLeaves", ["leaves_gold_a", "leaves_rust_a", "leaves_gold_b", "leaves_rust_b", "leaves_scatter"],
            yawed[0::3], scale=(0.9, 1.2), seed=92, check=False)
    scatter("FloorRoots", ["roots_a", "roots_b", "needles_patch", "moss_patch_a"], yawed[1::7], scale=(0.9, 1.15), seed=93,
            check=False)
    p.walk_grid()

    # === 10. Le refuge : mousse, champignons, rochers moussus, rais de lumière ====================================
    rng = sect("refuge")
    rx, rz = 16.0, 36.0
    for k, (dx, dz, scene) in enumerate(((-7.4, 2.4, "mossy_rock"), (7.8, 3.4, "boulder_c"), (-6.0, 1.0, "bush_e"),
                                          (6.2, 1.6, "fern_d"), (-5.0, 5.8, "fern_a"), (5.6, 6.2, "mushroom_cep"),
                                          (2.4, 5.4, "mushroom"), (-2.6, 6.2, "mushroom_chanterelle"),
                                          (-7.6, 5.6, "thicket_b"), (7.6, 6.0, "bush_b"))):
        x, z = rx + dx, rz + dz
        if dry(x, z, 0.5):
            place("Refuge", scene, x, z, name="Refuge%d" % (k + 1), flip=k % 2 == 1, check=False)
    for k, (dx, dz, scene, yaw) in enumerate(((0.0, 3.0, "moss_patch_a", 20), (-2.4, 5.2, "leaves_gold_a", 70),
                                               (2.8, 4.6, "leaves_rust_a", 140), (0.4, 6.4, "leaves_gold_b", 200),
                                               (-4.2, 3.0, "roots_a", 30), (4.0, 2.6, "roots_b", 100))):
        place("Refuge", scene, rx + dx, rz + dz, name="RefugeDecal%d" % (k + 1), check=False)
    # De petites plantes dans la place (rien de bloquant : la place reste franche), en bouquets espacés.
    littler = poisson(Rect(10.6, 38.6, 21.4, 45.4), 2.3, 14, lambda x, z: usable(x, z, way=0.6, bank=0.3, standing=False)
                      and math.hypot(x - 16.0, z - 41.2) > 2.2, seed=101)
    scatter("RefugeLow", ["fern_a", "fern_b", "mushroom", "mushroom_cep", "fern_c", "grass_clump_d", "mushroom_chanterelle"],
            littler, scale=(0.9, 1.15), seed=102, check=False)
    # Les rais de lumière (la scène 10.2 les cadre) : deux panneaux de lumière douce derrière et à côté du chêne.
    place("Sky", "light_shaft_b", 12.0, 33.0, name="RayRefuge1", check=False)
    place("Sky", "light_shaft_a", 20.2, 34.0, name="RayRefuge2", flip=True, check=False)
    p.walk_grid()

    # === 11. Les clairières, la souille, la tanière des loups ==========================================================
    rng = sect("clairieres")
    # Les cerfs : une clairière d'herbe adossée à la falaise du ressaut ; des fleurs, des pierres, des champignons, un
    # rai de lumière ; la base de la falaise est habillée (racines, fougères, rochers moussus).
    for k, (x, z, scene) in enumerate(((56.0, 10.4, "wildflowers_a"), (60.4, 12.6, "wildflowers_b"), (66.6, 11.2, "heather"),
                                       (70.2, 15.6, "wildflowers_a"), (57.6, 16.2, "grass_clump_c"), (63.8, 16.8, "tall_grass"),
                                       (69.0, 9.6, "wildflowers_b"), (62.0, 9.8, "grass_clump_b"), (55.6, 13.4, "heather"))):
        place("Clearing", scene, x, z, name="DeerGrass%d" % (k + 1), flip=k % 2 == 1, check=False)
    for k, (x, z, scene) in enumerate(((52.0, 9.8, "boulder_c"), (60.6, 9.4, "fern_d"), (65.0, 7.5, "mossy_rock"),
                                       (70.6, 9.4, "fern_a"), (57.6, 9.5, "bush_e"), (73.6, 9.8, "boulder_d"),
                                       (62.8, 9.6, "mushroom_cep"), (67.8, 9.6, "fern_b"), (52.6, 10.6, "thicket_b"))):
        place("Clearing", scene, x, z, name="DeerCliff%d" % (k + 1), flip=k % 2 == 0, check=False)
    flowers = poisson(Rect(55.0, 9.5, 71.5, 17.5), 2.8, 20, lambda x, z: usable(x, z, way=0.8, bank=0.3, standing=False),
                      seed=111)
    scatter("DeerFlowers", ["wildflowers_a", "wildflowers_b", "heather", "grass_clump_c", "tall_grass", "flowers_patch_a"],
            flowers, scale=(0.9, 1.2), seed=112, check=False)
    place("Sky", "light_shaft_b", 58.4, 11.6, name="RayDeer1", check=False)
    place("Sky", "light_shaft_a", 68.8, 12.2, name="RayDeer2", flip=True, check=False)
    # La souille : de la boue piétinée, des fougères écrasées, un tronc couché.
    for k, (dx, dz, scene) in enumerate(((-2.6, -1.2, "mud_patch"), (1.8, 0.8, "mud_patch"), (-0.4, 1.6, "puddle_a"),
                                          (3.2, -1.4, "puddle_b"), (-3.8, 1.8, "mud_patch"))):
        place("Clearing", scene, 24.0 + dx, 51.0 + dz, name="Wallow%d" % (k + 1), flip=k % 2 == 0, check=False)
    for k, (dx, dz, scene) in enumerate(((-5.6, -2.8, "fern_d"), (5.4, -2.4, "bush_c"), (4.6, 3.4, "fern_b"),
                                          (-4.6, 3.6, "thicket_b"), (0.6, -3.8, "mossy_rock"), (-6.6, 0.2, "stump_b"))):
        place("Clearing", scene, 24.0 + dx, 51.0 + dz, name="WallowEdge%d" % (k + 1), check=False)
    # Les loups : une clairière sombre de feuilles, des rochers en tas, deux arbres morts, des ossements d'écorce.
    for k, (x, z, scene) in enumerate(((59.6, 52.4, "pine_dead"), (75.6, 53.0, "pine_dead"), (64.0, 57.0, "boulder_d"),
                                       (71.0, 48.6, "rock_pile"), (60.4, 50.0, "thicket_a"), (74.8, 50.6, "fern_d"),
                                       (69.4, 57.2, "mossy_rock"), (62.4, 55.4, "fern_a"))):
        place("Clearing", scene, x, z, name="WolfDen%d" % (k + 1), flip=k % 2 == 1, check=scene == "pine_dead")
    # Les mares cachées : des feuilles et des fougères penchées sur leur bord.
    for k, (x, z, scene) in enumerate(((27.4, 43.0, "fern_b"), (31.8, 43.6, "fern_a"), (28.0, 45.4, "fern_c"),
                                       (31.4, 45.6, "fern_b"), (57.0, 21.6, "fern_d"), (60.4, 21.0, "fern_a"),
                                       (56.4, 19.2, "fern_c"), (59.8, 19.0, "fern_b"))):
        place("River", scene, x, z, name="PoolFern%d" % (k + 1), flip=k % 2 == 1, check=False)
    p.walk_grid()

    # === 12. Le sud : du premier plan qui s'efface devant le joueur ===================================================
    rng = sect("sud")
    south = []
    x = 5.0
    while x < 76.0:
        if not 28.0 < x < 52.0:
            south.append((x + rng.uniform(-0.5, 0.5), rng.uniform(56.4, 57.6)))
        x += rng.uniform(2.4, 3.8)
    big = [q for q in south if (q[0] < 15.0 or q[0] > 66.0) and not shadows_a_player(q[0], q[1])]
    scatter("SouthPines", ["tree_old_pine_forest", "pine_tall_b_forest", "tree_pine_forest"], big[::2], seed=121, check=False)
    scatter("SouthBrush", ["fg_bush", "fg_fern", "fg_grass"], [q for k, q in enumerate(south) if k % 3], seed=122, check=False)
    deep = poisson(Rect(6.0, 52.0, 76.0, 56.0), 4.0, 24, lambda x, z: usable(x, z, way=1.6, bank=0.5) and not shadows_a_player(x, z)
                   and not (28.0 < x < 52.0 and z > 52.5), seed=123)
    scatter("SouthTrees", SMALL_TREES[:3], deep, seed=124)
    # === 13. Combler le sol nu : aucun carré de 6 × 6 m vide hors des places (docs/REFONTE.md, 2) ==================
    rng = sect("comblement")
    elems = [(q[3], q[5]) for q in p.singles] + [(pt[0], pt[1]) for fam in p.families.values() for pt in fam["points"]]
    filled = 0
    for cx in range(3, W - 2, 2):
        for cz in range(3, D - 2, 2):
            if any(pl.hits(Rect(cx - 3.0, cz - 3.0, cx + 3.0, cz + 3.0)) for pl in p.places.values()):
                continue
            if not (p.walkable_here(cx, cz) and outside_edges(cx, cz, 0.0)) or level_of(cx, cz) is None:
                continue
            if any(abs(ex - cx) <= 3.0 and abs(ez - cz) <= 3.0 for ex, ez in elems):
                continue
            wet = river_d(cx, cz) < 0.2
            spot = None
            for _try in range(40):
                x, z = cx + rng.uniform(-1.8, 1.8), cz + rng.uniform(-1.8, 1.8)
                if wet and river_d(x, z) < 0.0 and path_distance(x, z) > 1.0:
                    spot = (x, z)
                    break
                if not wet and usable(x, z, way=0.9, bank=0.3, standing=False):
                    spot = (x, z)
                    break
            if spot is None:
                continue
            x, z = spot
            if wet:
                place("River", "lily_pads", x, z, name="Fill%d" % (filled + 1), flip=filled % 2 == 0, check=False)
                place("River", "reeds", x + 1.1, z - 0.9, name="FillReeds%d" % (filled + 1), check=False)
            else:
                for k, scene in enumerate((rng.choice(FERNS), rng.choice(BUSHES[:4]), rng.choice(["mushroom_cep", "nettles"]))):
                    place("Under", scene, x + (k - 1) * 1.0, z + rng.uniform(-0.6, 0.6), name="Fill%d_%d" % (filled + 1, k + 1),
                          flip=k % 2 == 1, check=False)
                place("Under", rng.choice(["leaves_gold_a", "leaves_rust_a", "roots_a"]), x, z + 0.4,
                      name="FillDecal%d" % (filled + 1), check=False)
            elems.append((x, z))
            filled += 1
    p.filled = filled

    # Le sentier de l'est s'arrête là tant que la montagne n'existe pas : un écriteau, à la place de la sortie.
    if "vers_montagne" in p.missing_exits:
        place("Path", "waiting_sign", 77.0, 44.6, name="SignMontagne")
    p.walk_grid()


def ambient(p):
    """Vie ambiante : des feuilles d'automne que le vent porte à travers la futaie, quelques oiseaux de jour ; ni lucioles
    (fin d'automne), ni papillons (la forêt est sombre)."""
    return [
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 8, (60, 9, 44), 0.0, (0, 0), 0.7, 0.8, 4, (40, 0, 30)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 8, (60, 9, 44), 0.0, (0, 0), 0.8, 0.8, 5, (40, 0, 30)),
    ]
