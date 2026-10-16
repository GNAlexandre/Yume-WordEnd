"""(C2) Le village des hommes-bêtes : la pose de la carte `village` d'après docs/lore/CARTE.md, section 5.2
(bloc ```plan lu par tools/carte_plans.py). Elle remplace la carte d'attente du même nom.

Ce que dit l'œuvre (5.1) : un village à quelques pas de l'entrepôt, au bord de l'île, pas très grand ; la
campagne, où presque personne ne porte de beaux habits ; un café qui fait tout, à la sonnette de porte ; la maison
Limashenka, fermée depuis le deuil. Composition (original), vue de la caméra qui regarde le nord (CARTE.md 0.3) :
- au nord, une rangée de maisons tournées vers la rue (la grange, le café, la maison de pierre, la maison Limashenka,
  une chaumière), et derrière elles le vide : on le voit entre les maisons et du belvédère, un ressaut de roche au
  bord de l'île avec son banc ; un garde-fou bas (`edge_parapet`) dans les trouées, la cascade du ruisseau à l'angle
  nord-ouest ;
- une rue de terre d'est en ouest, la terrasse du café (la place devant_cafe, nue), les ruelles et le chemin du sud ;
- au sud, des chaumières basses, leurs jardins clos derrière elles (rien où l'on marche derrière un toit :
  CARTE.md 0.3), le grand jardin potager et sa meule, le lavoir, les ruches, le ruisseau et la haie du bord sud.

Aucune lumière dans la scène : la lanterne à cristal et les fenêtres du plan (lumière de la porte du café, la nuit)
sont celles d'Atmosphere (E9) ; seule l'image `wall_lantern` est posée.
"""

import math

import exterior_ground
import exterior_kits as kits
from exterior_pose import Rect, along, poisson

SETTINGS = {
    "groups": ["Houses", "Facade", "Roof", "Street", "Garden", "Yard", "Hedge", "Edge", "River", "Woods", "Meadow",
               "Backdrop", "Sky", "Middle", "Foreground"],
    "no_lights": True,
    "texts": "res://data/texts/village.json",
    # Objets à examiner du dehors (data/texts/village.json, section « village »).
    "examine": [
        ("enseigne_cle", 12.7, 10.9, (1.2, 2.0, 1.0)),
        ("enseigne_cafe", 21.4, 10.9, (1.2, 2.0, 1.0)),
        ("maison_close", 41.8, 10.9, (1.4, 2.0, 1.0)),
        ("lavoir", 8.0, 30.9, (3.0, 2.0, 1.0)),
        ("ruches", 53.0, 30.2, (2.0, 2.0, 1.0)),
        ("belvedere", 35.0, 6.2, (2.0, 2.0, 1.2)),
        ("cascade", 5.0, 12.5, (1.6, 2.0, 1.6)),
        ("meule", 30.0, 20.4, (2.4, 2.0, 1.0)),
    ],
    # La maison Limashenka n'ouvre qu'au jour 11 (ACTE1.md 11.3) : la sortie est posée, la condition est dite en
    # métadonnée pour le récit (E6, S2) ; le moteur de cartes ne sait pas encore fermer une porte
    # (docs/CONTRACT_REQUESTS.md, C2).
    "exit_meta": {
        "porte_limashenka": 'metadata/open_from_day = 11\nmetadata/closed_text_key = "village/maison_close"\n',
    },
}

# Places de la vie que le plan ne nomme pas : (nom, x, z, regard en degrés, à quoi elles servent). Écrites en
# Life/Places (Marker3D) et listées dans CARTE.md par `exterior_maps.py places`.
PLACES_WHY = [
    ("rue_ouest", 8.0, 12.5, 0.0, "la rue devant la grange : le passant, le bûcheron qui part vers la forêt"),
    ("rue_centre", 30.0, 12.5, 0.0, "le milieu de la rue : les passants s'y croisent, le facteur (VIE.md 2.6)"),
    ("rue_est", 47.0, 12.5, 0.0, "la rue avant la sortie vers l'entrepôt"),
    ("grange_porte", 8.0, 10.9, 180.0, "la grande porte de la grange : le fermier (VIE.md 2.6)"),
    ("terrasse_banc_1", 16.8, 10.5, 180.0, "le banc de la terrasse, devant la façade du café : on s'y assoit face à la rue"),
    ("terrasse_banc_2", 22.6, 10.5, 180.0, "le second banc de la terrasse, côté ruelle"),
    ("meule", 30.0, 20.5, 0.0, "au pied de la meule de foin : le fermier (VIE.md 2.6)"),
    ("charrette", 25.0, 24.3, 0.0, "à côté de la charrette de foin : le fermier"),
    ("jardin", 27.0, 21.0, 0.0, "au milieu du grand jardin : on y bêche, on y arrose"),
    ("etal_rue", 36.5, 14.9, 180.0, "la place d'un étal au bord de la rue (un marchand de passage, VIE.md 2.6)"),
    ("etal_grange", 10.5, 14.9, 180.0, "la place d'un étal devant la grange (le fermier vend son foin)"),
    ("porte_limashenka_attente", 41.5, 12.0, 90.0, "devant la maison Limashenka : les villageois qui attendent d'entendre l'horloge (jour 11)"),
    ("ruisseau_berge", 12.0, 33.0, 0.0, "la berge du ruisseau du sud : le pêcheur des marais (VIE.md 2.6)"),
    ("jardins_sud", 40.0, 31.0, 0.0, "les jardins du sud : le fermier, l'après-midi (VIE.md 2.6)"),
]

DEVIATIONS = [
    "la porte du café est déplacée de 1,3 m vers l'est : sortie porte_cafe (19,1 → 20,5), marqueur from_cafe "
    "(19,8 ; 12) et point cafe_porte (19,8 ; 11), au droit de la porte de la façade livrée (cafe.png, x = 19,76 m), "
    "au lieu de 18,5",
    "l'enseigne `hanging_sign_key` est posée au coin de la grange (x 12,7), au lieu de 13,5 : elle ne pendait à rien",
    "le tas de bûches `firewood_pile` est à x 4,5, au lieu de 2,8 : à 2,8 il tombait dans le ruisseau",
    "le café a sa propre scène (`cafe_village`) : celle de T1 (`cafe`) pose trois tables de terrasse bloquantes dans "
    "la place devant_cafe, qui doit rester libre",
    "jardins clos (collision invisible, clôture de branches au nord, haies sur les côtés) derrière les trois "
    "chaumières du sud : un toit de 5 m cache 7 m au nord de lui, et CARTE.md 0.3 veut que rien où l'on marche ne "
    "soit derrière un toit",
    "le grand jardin (x 20 → 34) est ouvert sur ses côtés : le plan ne clôt que x 20 → 24 ; ses grands décors (meule, "
    "charrette, épouvantail) sont des variantes de premier plan",
    "la lanterne à cristal et les fenêtres lumineuses du plan (`lumiere`) ne sont pas écrites : aucune lumière dans "
    "les cartes, Atmosphere éclaire (la nuit, la façade du café n'a pas de vitres allumées : demande dans CONTRACT_REQUESTS.md)",
    "la porte de la maison Limashenka est posée ouverte : la condition du jour 11 est en métadonnée "
    "(`open_from_day`, `closed_text_key`) pour le récit",
]

TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c"]
TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn"]
BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f", "berry_bush", "berry_bush_b"]
FERNS = ["fern_a", "fern_b", "fern_c", "fern_d"]
GRASSES = ["grass_clump_a", "grass_clump_b", "grass_clump_c", "grass_clump_d", "tall_grass"]
FLOWERS = ["wildflowers_a", "wildflowers_b", "myosotis_b"]
# (RC) La haie du bord sud : les fourrés de premier plan et ceux qui ne cachent rien (au bord de la carte).
HEDGES = ["thicket_a_fg", "thicket_b_fg", "thicket_c", "bramble_hedge"]

# Jardins clos derrière les chaumières du sud : (x0, z0, x1, z1).
ENCLOSURES = [(3.2, 15.8, 13.8, 22.0), (43.2, 16.8, 49.2, 23.0), (49.2, 16.8, 55.3, 22.0)]
# Scène de chaque bâtiment du plan quand elle n'a pas le nom de son image.
BUILDING_SCENES = {"cafe": "cafe_village"}


def pascal(text):
    return "".join(part.capitalize() for part in text.split("_"))


def fence_row(x0, x1, z, seed, overgrown=True, pool=None):
    """(RC) Une clôture de plessis de x0 à x1 (bords des pièces de 2 m), en z : pas de 1,6 à 2 m (les pièces se
    chevauchent : jamais de trou, la clôture ferme), recul de ± 0,12 m, retournée au hasard, hauteur ± 6 % ; un
    buisson poussé devant elle tous les trois à six éléments (overgrown). Une seule image de plessis est livrée : une
    variante (cahier n° 7, famille `wattle`) y entrera seule, jamais deux fois de suite."""
    items = kits.row([(x0 + 1.0, z), (x1 - 1.0, z)], pool or kits.family("wattle"), seed=seed, spread=0.1, depth=0.12,
                     skip=0.0, scale=(0.94, 1.06), overlap=0.9, tone=(0.035, 0.0))
    if not overgrown or len(items) < 3:
        return items
    import random
    rng = random.Random(seed + 7)
    bushes = kits.family("wattle_accents")[1:]
    k = rng.randint(1, 3)
    while k < len(items) - 1:
        _scene, x, zz, _f, _s, _t = items[k]
        items.append((bushes[rng.randrange(len(bushes))], round(x + rng.uniform(-0.5, 0.5), 3),
                      round(zz + rng.uniform(0.3, 0.5), 3), rng.random() < 0.5, round(rng.uniform(0.85, 1.05), 3),
                      (round(rng.uniform(-0.05, 0.05), 3), round(rng.uniform(-0.02, 0.02), 3))))
        k += rng.randint(4, 7)
    return items


def ground_plan(m):
    """Le sol : le plan (belvédère à +1 m, ruisseau à −0,5 m, ruelles, rue, jardin) ; le bord nord est le vide de
    l'île (une côte irrégulière, plus avancée au belvédère), la cascade y tombe."""
    plan = exterior_ground.ground_from_plan(
        m, noise=0.5, ramp_material="roche",
        comment="Sol en relief du village (lot C2), d'après docs/lore/CARTE.md, section 5.2 : rue et jardins à 0, "
                "belvédère de roche à +1 m (rampe au sud), ruisseau à −0,5 m (à l'ouest et au sud, eau basse où l'on "
                "marche), le vide de l'île au nord (côte irrégulière, la cascade y tombe). Lu par "
                "tools/map_build.py gen village ; le jeu ne lit pas ce fichier.")
    plan["edges"]["north"] = "void"
    steps = plan["steps"]
    coast = [[-3, -3], [59, -3], [59, 3.0], [-3, 3.0]]
    steps.insert(exterior_ground.step_index(steps, "face"),
                 {"op": "void", "shape": {"poly": coast, "noise": 0.25, "noise_scale": 2.2, "seed": 3}})
    # Mousse sur le haut du belvédère, boue au lavoir, sable au bord des gués : le sol du plan est un pré uni.
    patches = [("mousse", 34.0, 6.4, 2.6, 1.2, 1.0), ("boue", 8.0, 31.6, 2.6, 1.0, 0.0),
               ("feuilles", 27.0, 14.6, 3.0, 1.0, 0.0), ("feuilles", 47.0, 15.0, 3.0, 1.0, 0.0),
               ("feuilles", 11.0, 15.0, 2.4, 0.8, 0.0), ("prairie", 16.0, 19.5, 2.2, 1.6, 0.0),
               ("prairie", 38.0, 20.5, 2.4, 1.8, 0.0), ("prairie", 46.5, 32.0, 4.0, 1.4, 0.0),
               ("mousse", 3.6, 28.0, 0.9, 3.0, 0.0)]
    # La rive ouest du ruisseau (x 0 → 1) est une berge de sous-bois à −0,5 m : le sol se prolonge au-delà du bord de la
    # carte par sa dernière case, et c'est la forêt (pas de l'eau jusqu'à l'horizon).
    steps.insert(exterior_ground.step_index(steps, "ramp"),
                 {"op": "material", "material": "sous_bois", "shape": {"rect": [0, 3, 1.2, 34], "noise": 0.3,
                                                                       "noise_scale": 1.8, "seed": 9}})
    # Le ressaut du belvédère a des faces de roche (pas de talus de terre).
    steps.insert(exterior_ground.step_index(steps, "face") + 1,
                 {"op": "face", "face": "rock", "shape": {"rect": [31, 3.5, 8, 5.5]}, "where": {"level": 2}})
    first_path = exterior_ground.step_index(steps, "path")
    for k, (name, cx, cz, rx, rz, lv) in enumerate(patches):
        steps.insert(first_path, {"op": "material", "material": name,
                                  "shape": {"ellipse": [cx, cz, rx, rz], "noise": 0.5, "noise_scale": 1.6,
                                            "seed": 70 + k},
                                  "where": {"level": int(round(lv / 0.5))}})
    return plan


def prepare(p):
    # Jardins clos : collision invisible derrière les chaumières du sud (leur clôture et leurs haies les montrent).
    for x0, z0, x1, z1 in ENCLOSURES:
        p.edges.append(Rect(x0, z0, x1, z1))
    # Le bout du ruisseau, là où il tombe du bord de l'île : des roches, rien ne se marche (le flanc de la grange, à
    # 1 m, cacherait le joueur).
    p.edges.append(Rect(0.0, 3.0, 4.0, 9.7))
    # Les deux bouts de la rangée du nord : la caméra, bornée à x 10 → 46, voit les cases à côté de la grange et de
    # la dernière chaumière à travers leur toit.
    p.edges.append(Rect(54.0, 3.0, 56.0, 9.7))
    p.edges.append(Rect(47.0, 3.0, 49.0, 9.7))
    # Les flancs ouest de la chaumière longue et est de l'appentis, et l'entre-deux de la chaumière penchée et de
    # l'appentis : mêmes cases cachées, mêmes remèdes (des bûches, des bûches empilées, des buissons).
    p.edges.append(Rect(3.0, 22.0, 6.0, 27.2))
    p.edges.append(Rect(48.0, 22.0, 50.0, 27.0))
    p.edges.append(Rect(54.0, 22.0, 56.0, 26.0))


def pose(p):
    M, W, D = p.map, p.W, p.D
    rng = p.rng
    place, scatter = p.place, p.scatter
    in_map, outside_edges = p.in_map, p.outside_edges
    free, height, walk_grid = p.free, p.height, p.walk_grid
    PATHS = p.paths
    BUILDINGS = p.buildings

    walk_grid()

    # === 1. Ossature du plan (5.2) =====================================================================

    for b in M.buildings:
        cx, cz = (b.rect.x0 + b.rect.x1) / 2.0, (b.rect.z0 + b.rect.z1) / 2.0
        place("Houses", BUILDING_SCENES.get(b.extra["img"], b.extra["img"]), cx, cz, name=pascal(b.name), check=False)

    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        w = d.rect.x1 - d.rect.x0
        if n == "edge_waterfall":
            place("River", n, x, z, y=-0.5, name="Cascade", check=False)
        elif n == "bench_stone":
            place("Street", n, x, z, name="BancBelvedere", check=False)
        elif n == "fence_wattle":
            if d.block:
                # (RC) Une clôture irrégulière (exterior_kits.row) : pas et recul variés, retournée au hasard, un
                # buisson ou une palissade basse par-ci par-là ; jamais de trou (elle ferme le jardin).
                kits.place_row(p, "Garden", "Cloture_%d_" % round(z * 10), fence_row(d.rect.x0, d.rect.x1, z,
                                                                                    seed=1100 + round(z * 10)))
            else:
                place("Edge", "fence_wattle_libre", x, z, name="GardeFouBelvedere", check=False)
        elif n == "wall_lantern":
            place("Facade", n, x, 9.55, y=1.6, name="LanterneCafe", check=False)
        elif n == "flower_pots":
            place("Facade", n, x, z, name="PotsMaisonPierre", check=False)
        elif n == "hanging_sign_key":
            place("Facade", n, x, z, y=1.0, name="EnseigneCle", check=False)
        elif n == "haystack":
            place("Garden", "haystack_fg", x, z, name="Meule")
        elif n == "cart_hay":
            place("Garden", "cart_hay_fg", x, z, name="Charrette")
        elif n == "beehives":
            place("Yard", n, x, z, name="Ruches")
        elif n == "washing_trough":
            place("River", n, x, z, name="Lavoir")
        elif n == "laundry_line":
            place("Garden", n, x, z, name="CordeALinge", check=False)
        elif n == "firewood_pile":
            place("Yard", "firewood_pile_front", x, z, name="Buches")
        else:
            p.warnings.append("décor du plan non posé : %s" % n)

    # La clochette de la porte du café, animée (la sonnette de VEX), devant la façade livrée.
    place("Facade", "cafe_door_bell", 19.78, 9.56, y=1.9, name="ClocheCafe", check=False)

    walk_grid()

    # === 2. Le bord de l'île : garde-fou, roches, cascade (5.2, kits) ==================================

    # Les cases fermées de la rangée du nord et du sud (prepare) : des fourrés, des bûches et des roches les montrent
    # fermées (les toits cacheraient le joueur : CARTE.md 0.3).
    for k, (x, z, scene) in enumerate(((1.6, 8.6, "thicket_b"), (3.0, 6.6, "bush_c"), (1.0, 6.2, "bush_e"),
                                       (2.4, 4.0, "bush_b"), (55.0, 8.4, "thicket_a"), (54.8, 5.8, "thicket_b"),
                                       (55.4, 4.2, "bush_d"), (48.0, 8.4, "thicket_b"), (47.8, 4.4, "bush_c"),
                                       (48.2, 6.4, "log_pile_forest"), (3.5, 26.2, "bush_d"), (3.4, 22.8, "bush_b"),
                                       (49.0, 23.6, "bush_e"), (49.2, 25.8, "thicket_b"), (55.2, 22.9, "thicket_a"),
                                       (55.0, 24.2, "bush_c"))):
        place("Hedge", scene, x, z, name="Haie%d" % (k + 1), flip=k % 2 == 1)

    # Garde-fou bas dans les trouées entre les maisons (les modules derrière les façades ne se voient pas).
    for k, x in enumerate((13.5, 23.0, 30.0, 40.0, 48.0, 55.0)):
        place("Edge", "edge_parapet", x, 3.25, name="Parapet%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Le belvédère : le garde-fou de branches sur toute sa largeur, des roches et de l'herbe au bord du vide.
    for k, x in enumerate((32.0, 34.0, 36.0, 38.0)):
        place("Edge", "fence_wattle_libre", x, 3.9, name="GardeFou%d" % (k + 1), flip=k % 2 == 1, check=False)
    place("Edge", "edge_rocks_b", 31.5, 3.55, name="RocheBelvedereOuest", check=False)
    place("Edge", "edge_rocks_a", 38.6, 3.6, name="RocheBelvedereEst", flip=True, check=False)
    for k, x in enumerate((4.5, 13.0, 23.0, 30.2, 40.0, 48.2, 55.0)):
        place("Edge", "edge_grass", x, 3.15, name="HerbeDuBord%d" % (k + 1), flip=k % 2 == 0, check=False)
    place("Edge", "edge_roots", 2.5, 3.1, y=-0.5, name="RacinesCascade", check=False)
    belvedere_flowers = [(33.0, 5.2), (36.8, 5.4), (32.4, 7.6), (37.6, 7.9), (34.0, 8.3), (35.6, 4.2)]
    scatter("BelvedereFlowers", FLOWERS + ["heather", "grass_clump_d"], belvedere_flowers, seed=11, check=False)

    # === 3. La rue et le pied des façades =================================================================

    # Pied des maisons du nord (z 9,6 → 10,1) : tonneaux, caisses, brouette, pots ; la place devant le café reste
    # nue (rien de bloquant : bancs et pots seulement), les portes et les marqueurs aussi.
    place("Street", "crate_stack", 5.4, 10.05, name="CaissesGrange")
    place("Street", "rain_barrel", 4.2, 10.0, name="TonneauGrange")
    place("Street", "barrel_group", 11.0, 10.1, name="TonneauxGrange")
    place("Street", "wheelbarrow", 9.7, 9.95, name="BrouetteGrange")
    place("Street", "flower_pots", 15.7, 10.1, name="PotsCafeOuest", check=False)
    place("Street", "bench_stone", 16.8, 10.35, name="BancTerrasse1", check=False)
    place("Street", "bench_stone", 22.6, 10.35, name="BancTerrasse2", flip=True, check=False)
    place("Street", "flower_pots", 21.4, 10.1, name="PotsCafeEst", flip=True, check=False)
    place("Street", "rain_barrel", 28.5, 10.0, name="TonneauMaison")
    place("Street", "sack_apples", 29.6, 10.0, name="SacsPommes", check=False)
    place("Street", "bucket", 24.6, 10.1, name="SeauMaison", check=False)
    place("Street", "leaves_rust_a", 43.9, 10.7, name="FeuillesPorteLimashenka", check=False)
    place("Street", "leaves_gold_b", 42.3, 10.5, name="FeuillesLimashenka", flip=True, check=False)
    place("Street", "flower_pots", 52.2, 10.0, name="PotsChaumiere", check=False)
    place("Street", "rain_barrel", 49.6, 10.0, name="TonneauChaumiere")
    place("Street", "wash_tub", 53.9, 10.1, name="BaquetChaumiere")

    # Foin, cailloux, flaques, feuilles : des décalques le long de la rue. (Orchestrateur) Pas
    # d'ornières : le décalque cart_ruts livré (cahier n° 2, lot B) montre deux sillons profonds coupés
    # net, qui, posés par morceaux, se lisaient comme des sillons de labour ; il est recommandé au
    # cahier n° 5 (R0.8) en bande raccordable et discrète, à reposer ici en une seule traînée.
    for k, (x, z, scene) in enumerate(((8.4, 12.6, "hay_scatter"), (10.4, 13.6, "hay_scatter"),
                                       (30.5, 11.2, "puddle_a"), (45.5, 14.0, "puddle_a"),
                                       (14.0, 11.4, "pebbles_a"), (24.0, 14.4, "pebbles_b"),
                                       (36.5, 12.6, "pebbles_a"), (50.5, 11.4, "pebbles_b"),
                                       (6.5, 14.2, "leaves_rust_b"), (17.5, 14.8, "leaves_gold_a"),
                                       (34.5, 14.6, "leaves_rust_a"), (42.0, 12.0, "leaves_gold_b"),
                                       (28.0, 12.4, "mud_patch"), (3.5, 12.0, "footprints"),
                                       (23.0, 11.6, "footprints"), (48.5, 13.2, "footprints"))):
        place("Street", scene, x, z, name="RueDecal%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Bords de la rue : l'herbe mange la terre, une touffe tous les 1 à 2 m, jamais dans la bande libre.
    edge = []
    for name, width, pts in PATHS:
        if name in ("rue", "ruelle_ouest", "ruelle_est", "chemin_bas"):
            edge += along(pts, 1.5, width / 2.0 + 0.8, 0.45, seed=len(edge) + 50)
    edge = [q for q in edge if free()(q[0], q[1]) and outside_edges(q[0], q[1], 0.2)]
    scatter("StreetGrass", ["grass_clump_a", "grass_clump_c", "tall_grass", "grass_clump_d"], edge[::3], seed=60,
            check=False)
    scatter("StreetFlowers", ["wildflowers_a", "wildflowers_b", "myosotis_b"], edge[1::3], seed=61, check=False)
    scatter("StreetStones", ["rock_small_a", "rock_small_b", "rock_small_c", "rock_small_d", "fern_c"], edge[2::3],
            seed=62, check=False)
    borders = []
    for name, width, pts in PATHS:
        if name in ("rue", "chemin_bas"):
            borders += kits.along_irregular(pts, 3.3, width / 2.0 + 0.1, seed=64 + len(borders), spread=0.35, lateral=0.3,
                                            skip=0.1, yaw_jitter=12.0)
    borders = [q for q in borders if in_map(q[0], q[1], 0.5) and outside_edges(q[0], q[1], 0.2)
               and not any(b.has(q[0], q[1], 0.2) for b in BUILDINGS)]
    scatter("StreetEdges", kits.family("grass_edges"), borders, scale=(0.8, 1.15), seed=65, check=False)

    # Le pied des façades du nord : herbe, fleurs et cailloux contre les murs (rien de bloquant : la place devant le café
    # reste nue).
    foot = []
    x = 2.0
    while x < W - 1.5:
        if not (19.0 < x < 20.9 or 43.0 < x < 45.0):
            foot.append((x + rng.uniform(-0.3, 0.3), rng.uniform(9.75, 10.35)))
        x += rng.uniform(1.3, 2.1)
    scatter("FacadeFoot", ["grass_clump_d", "wildflowers_b", "grass_clump_b", "myosotis_b", "heather"], foot, seed=18,
            check=False)

    # === 4. Le grand jardin, les jardins clos, la cour des chaumières (5.2, kits « jardins ») ==========

    # Le potager : lits cultivés, rangs de légumes, épouvantail, arrosoir.
    place("Garden", "garden_bed", 23.5, 20.4, name="PlateBande1")
    place("Garden", "garden_bed", 31.0, 22.8, name="PlateBande2", flip=True)
    for k, (x, z) in enumerate(((28.0, 18.0), (22.5, 23.7), (32.2, 19.6))):
        place("Garden", "vegetable_patch", x, z, name="Legumes%d" % (k + 1), flip=k % 2 == 1)
    place("Garden", "scarecrow_front", 27.2, 21.2, name="Epouvantail")
    place("Garden", "watering_can", 29.0, 24.0, name="Arrosoir", check=False)
    place("Garden", "sack_apples", 33.4, 21.4, name="SacPotager", check=False)
    # Clôtures du grand jardin : le plan clôt x 20 → 24 ; elles se prolongent jusqu'à x 34, côtés ouverts.
    # (RC) En rangées irrégulières (fence_row).
    kits.place_row(p, "Garden", "ClotureNord", fence_row(25.0, 33.0, 16.8, seed=1121))
    # Au sud, le prolongement est une palissade basse de piquets, plus neuve que le plessis du plan (vue sud : douze
    # pièces de plessis dans le même champ).
    kits.place_row(p, "Garden", "ClotureSud", fence_row(25.0, 33.0, 25.2, seed=1122, pool=["fence_low"]))
    # (RC) Fleurs au pied des clôtures du nord du jardin, côté rue.
    for k, (x, z, scene) in enumerate(((21.2, 16.25, "flowers_patch_a"), (27.6, 16.2, "flowers_patch_b"),
                                       (14.8, 15.5, "clover_patch"))):
        place("Garden", scene, x, z, name="FleursCloture%d" % (k + 1), flip=k % 2 == 1, check=False)

    # Les jardins clos des chaumières : clôture de branches au nord, haies de buissons aux côtés, derrière
    # lesquels rien ne se voit ni ne se marche ; lits et légumes de l'autre côté.
    for ei, (x0, z0, x1, z1) in enumerate(ENCLOSURES):
        # (RC) Clôture et haies latérales en rangées irrégulières (exterior_kits.row) : pas ± 30 %, recul, six
        # buissons qui ne se suivent jamais deux fois.
        kits.place_row(p, "Hedge", "CloturePotager%d_" % (ei + 1), fence_row(x0, x1, z0 + 0.1, seed=1130 + ei),
                       check=False)
        for side, xs in (("Ouest", x0 + 0.1), ("Est", x1 - 0.1)):
            kits.place_row(p, "Hedge", "Haie%s%d_" % (side, ei + 1),
                           kits.row([(xs, z0 + 0.8), (xs, z1 - 0.6)], BUSHES[1:7], seed=1140 + ei * 2 + len(side),
                                    step=1.8, depth=0.18, skip=0.0, scale=(0.85, 1.1)), check=False)
    place("Garden", "garden_bed", 9.6, 19.2, name="PlateBandeOuest")
    place("Garden", "vegetable_patch", 11.4, 17.2, name="LegumesOuest")
    place("Garden", "scarecrow_front", 7.6, 17.8, name="EpouvantailOuest")
    place("Garden", "garden_bed", 46.2, 19.6, name="PlateBandeEst")
    place("Garden", "vegetable_patch", 52.4, 18.4, name="LegumesEst")
    place("Garden", "watering_can", 51.4, 20.6, name="ArrosoirEst", check=False)

    # Devant les chaumières, au bord du chemin du sud : pots, seaux, bancs, linge.
    place("Yard", "flower_pots", 7.6, 27.4, name="PotsChaumiereLongue1", check=False)
    place("Yard", "flower_pots", 11.2, 27.4, name="PotsChaumiereLongue2", flip=True, check=False)
    place("Yard", "bucket", 9.3, 27.5, name="SeauChaumiere", check=False)
    place("Yard", "flower_pots", 46.2, 27.3, name="PotsChaumierePenchee", check=False)
    place("Yard", "stump_axe", 55.0, 25.4, name="BillotHache")
    place("Yard", "flower_pots", 51.0, 25.3, name="PotsAppentis", check=False)
    place("Yard", "bench", 38.6, 27.0, name="BancSud", flip=True, check=False)
    place("Yard", "rain_barrel", 5.0, 27.3, name="TonneauChaumiereLongue")
    place("Yard", "hand_cart", 36.0, 24.0, name="CharretteMain")

    # === 5. Le sud : ruisseau, lavoir, ruches, prés, haie (5.2, kits « sud ») =============================

    # Le ruisseau de l'ouest et du sud : roseaux, massettes, nénuphars, pierres de gué.
    west = poisson(Rect(0.5, 6.8, 2.8, 36.4), 1.8, 13, free(), seed=31)
    place("River", "edge_rocks_b", 1.6, 5.4, y=-0.5, name="RochesCascade", check=False)
    place("River", "reeds", 2.4, 6.9, y=-0.5, name="RoseauxCascade", check=False)
    place("River", "cattails", 0.9, 7.2, y=-0.5, name="MassettesCascade", flip=True, check=False)
    scatter("RiverReeds", ["reeds", "reeds_b", "cattails", "reeds_sway"], west[::2], seed=32, check=False)
    scatter("RiverFerns", FERNS + ["lily_pads"], west[1::2], seed=33, check=False)
    south_bank = poisson(Rect(3.5, 33.2, 55.5, 34.3), 2.2, 20, free(), seed=34)
    scatter("StreamReeds", ["reeds", "reeds_b", "cattails", "reeds_sway"], south_bank[::2], seed=35, check=False)
    scatter("StreamGrass", GRASSES + FLOWERS, south_bank[1::2], seed=36, check=False)
    for k, (x, z) in enumerate(((1.6, 8.0), (1.6, 16.0), (1.4, 26.0), (1.6, 33.0), (14.0, 35.6), (30.0, 35.4),
                                (44.0, 35.6))):
        place("River", "lily_pads", x, z, name="Nenuphars%d" % (k + 1), flip=k % 2 == 0, check=False)
    place("River", "stepping_stones", 17.0, 35.4, name="GueSud", check=False)
    place("River", "stepping_stones", 38.0, 35.4, name="GueSud2", flip=True, check=False)
    place("River", "mist_patch", 2.0, 14.0, name="BrumeRuisseau", check=False)
    # Les prés : herbe haute, fleurs sauvages, buissons ; pas de sol nu de plus de 6 × 6 m.
    meadow = []
    for area, n, seed in ((Rect(0.6, 30.8, 55.4, 33.4), 20, 40), (Rect(3.5, 37.0, 55.4, 38.0), 10, 41),
                          (Rect(14.2, 15.8, 19.8, 28.0), 10, 42), (Rect(34.4, 15.8, 41.0, 28.0), 10, 43),
                          (Rect(0.6, 3.6, 3.5, 36.0), 0, 44), (Rect(55.0, 15.5, 55.8, 32.0), 0, 45)):
        if n:
            meadow += poisson(area, 1.25, n, free(), seed=seed)
    scatter("MeadowGrass", GRASSES, meadow[::2], seed=46, check=False)
    scatter("MeadowFlowers", FLOWERS + ["heather", "thistle"], meadow[1::2], seed=47, check=False)
    low = poisson(Rect(1.0, 30.8, 55.0, 33.4), 4.5, 10, free(), seed=48)
    scatter("MeadowBushes", ["bush_b", "bush_d", "berry_bush_b", "bush_f"], low, seed=49, check=False)
    # Feuilles et traces au sud de la rue, près du lavoir et des ruches.
    for k, (x, z, scene) in enumerate(((10.5, 31.4, "footprints"), (6.0, 30.4, "puddle_b"), (52.0, 29.2, "pebbles_a"),
                                       (49.0, 31.6, "leaves_rust_b"), (20.0, 30.8, "leaves_gold_a"),
                                       (30.0, 31.2, "pebbles_b"), (41.0, 30.9, "leaves_rust_a"),
                                       (24.5, 28.6, "footprints"), (2.8, 31.0, "mud_patch"))):
        place("Meadow", scene, x, z, name="PreDecal%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Entre les chaumières : cailloux, mousse, herbes autour des chemins et des ruelles.
    place("Meadow", "log_pile_forest", 14.9, 25.6, name="BuchesRuelle")
    place("Meadow", "stump_a", 40.1, 18.2, name="SoucheRuelle")

    # La haie du bord sud (premier plan), les arbres du coin sud-est (bord foret 50 → 56 ; 31 → 34).
    # (RC) Une haie irrégulière (exterior_kits.row) : quatre sortes de fourrés qui ne se suivent jamais deux fois,
    # pas ± 30 %, recul de ± 0,4 m, quelques trouées (le bord de la carte, fermé par le sol, est derrière).
    kits.place_row(p, "Edge", "HaieSud", kits.row([(0.8, 39.1), (W - 0.8, 39.1)], HEDGES, seed=1150, spread=0.3,
                                                  depth=0.4, skip=0.12, scale=(0.9, 1.1), overlap=1.0))
    # (QC2) Au sud des ruches, un jeune arbre : un grand les couvrait (docs/QUALITE.md, QC-37).
    for k, (x, z, scene) in enumerate(((52.0, 32.6, "sapling_a_forest"), (55.0, 31.8, "maple_a_forest"))):
        place("Woods", scene, x, z, name="ArbreSudEst%d" % (k + 1), check=False)
    place("Woods", "bush_d", 53.6, 33.2, name="BuissonSudEst")
    for k, (x, z) in enumerate(((8.0, 38.6), (24.0, 38.8), (40.0, 38.6))):
        place("Edge", "fg_bush", x, z, name="BuissonPremierPlan%d" % (k + 1), check=False)

    # === 6. Arbres de village et forêt autour ============================================================

    # Un érable au bord de l'est ; les arbres de village s'arrêtent là (trop près de la caméra, un arbre de premier plan
    # cache la rue).
    place("Woods", "maple_c_forest", 54.4, 14.6, name="ArbreEst", check=False)
    place("Woods", "willow_forest", 2.2, 24.0, y=-0.5, name="SauleRuisseau", check=False)
    place("Woods", "alder_fg", 1.8, 9.0, y=-0.5, name="AulneRuisseau", check=False)
    # Toile de fond à l'ouest, à l'est et au sud : la forêt continue (la barrière du sol ferme la carte).
    backdrop = [(-2.5, z + rng.uniform(-1.0, 1.0)) for z in (6.0, 12.0, 18.0, 24.0, 30.0, 36.0)]
    backdrop += [(58.0, z + rng.uniform(-1.0, 1.0)) for z in (8.0, 14.0, 20.0, 26.0, 32.0)]
    trees = TREES_GOLD + TREES_RUST
    for k, (x, z) in enumerate(backdrop):
        place("Backdrop", trees[k % len(trees)], x, z, y=0.0, name="Fond%d" % (k + 1), flip=k % 2 == 1, check=False)
    place("Backdrop", "forest_wall_c", 72.0, 12.0, y=0.0, name="LisiereEst", check=False)

    # === 7. Les maisons : cheminées et fumées (la vie du village), lierre =============================

    for k, (cx, cz, ridge, scene) in enumerate(((26.5, 8.2, 6.0, "chimney_stone"), (51.5, 8.0, 5.5, "chimney_stone"))):
        place("Roof", scene, cx, cz, y=ridge - 0.45, name="Cheminee%d" % (k + 1), check=False)
        place("Roof", "chimney_smoke", cx, cz, y=ridge + 1.35, name="Fumee%d" % (k + 1), check=False)
    place("Facade", "ivy_wall_a", 24.6, 9.55, y=0.0, name="LierreMaisonPierre", check=False)
    place("Facade", "ivy_wall_b", 48.9, 9.55, y=0.4, name="LierreChaumiere", flip=True, check=False)

    # === 8. Le ciel au nord : îles et rochers qui flottent, lointains ====================================

    for k, (x, y, z, scale, scene) in enumerate(((16.0, -22.0, -60.0, 1.0, "floating_rock"),
                                                 (44.0, -30.0, -82.0, 1.3, "floating_rock_b"),
                                                 (4.0, -36.0, -120.0, 1.6, "floating_rock_c"),
                                                 (50.0, -38.0, -170.0, 2.0, "distant_island_a"),
                                                 (-8.0, -34.0, -210.0, 2.4, "distant_island_c"))):
        place("Sky", scene, x, z, y=y, scale=scale, name="Lointain%d" % (k + 1), check=False)

    # === 9. (RC) Les plans (CARTE.md 0.5) ===============================================================
    # Plan moyen : de jeunes arbres, des fourrés, une meule sur les côtés ouverts du grand jardin et dans les prés du
    # sud, loin des ruelles, du chemin du bas et des places de la vie. Premier plan : au bas de chaque vue.
    walk_grid()
    kits.middle_kit(p, [(Rect(17.4, 15.8, 19.9, 28.0), 2), (Rect(34.2, 15.8, 38.6, 28.0), 2),
                        (Rect(1.0, 36.6, 55.0, 38.4), 2), (Rect(14.0, 30.6, 46.0, 33.2), 2)],
                    [s for s in kits.family("mid_nature") if s != "boulder_b"], seed=1161)
    kits.foreground_views(p, "village", seed=1171)


def ambient(p):
    """Vie ambiante : des oiseaux qui traversent, des feuilles d'automne, des papillons dans les jardins (VIE.md 4.4)."""
    return [
        ("Birds", "birds_flock", 6, 10, 1, 3, (40, 6, 20), 6.0, (0, 0), 4.0, 0.8, 3, (28, 0, 14)),
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 8, (28, 9, 18), 0.0, (0, 0), 0.9, 0.8, 4, (28, 0, 14)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 8, (28, 9, 18), 0.0, (0, 0), 1.1, 0.8, 5, (28, 0, 14)),
        ("ButterfliesGarden", "butterfly", 4, 12, 2, 5, (14, 1.6, 8), 0.3, (18, 12), 0.6, 0.6, 1, (27, 0, 21)),
    ]
