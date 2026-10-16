"""(CP) Le port : la pose de la carte `port` d'après docs/lore/CARTE.md, section 6.2 (bloc ```plan lu par
tools/carte_plans.py). Elle remplace la carte d'attente du même nom.

Ce que dit l'œuvre (6.1) : la rue du port, au bord du vide, porte le panneau usé aux flèches rouges ; le port garde ce
qu'il faut aux dirigeables ; on s'y tient au bord du vide et l'on voit, sous quelques nuages, la surface grise ;
l'amarrage fait un lourd bruit de métal (une passerelle, trois bras d'ancrage) ; une rampe, un sifflet à vapeur, des
charrettes de sacs qui filent sur l'aire-port ; une colline toujours ventée juste à côté.

Composition vue de la caméra (elle regarde le nord ; CARTE.md 0.3) :
- au nord, le vide : la mer de nuages loin en contrebas, des rochers qui flottent, des îles et des dirigeables de
  passage ; le quai de tôle le borde d'un garde-corps, sauf au poste d'amarrage (E7 : le nœud `Berth`, extra_nodes), où
  le transport de la Garde en volume s'amarre de flanc entre ses trois bras d'ancrage quand le récit le fait descendre
  (vide hors des scènes), sa passerelle posée au droit du point `navire_quai` ;
- sur le quai, au nord de la rue : le bureau du port, la cabane du gardien, le hangar (rien de haut au sud d'où l'on
  marche) ; caisses, cordages, filets, tonneaux de mazout, cristaux, sifflet à vapeur, cabestan, lanternes de quai ;
- la rue du port (pavés), le panneau aux flèches rouges, l'aire-port (gravier) et ses charrettes de sacs, ses palettes,
  la route de la ville qui part vers le sud-est ;
- à l'est, la colline toujours ventée : trois terrasses (+1, +2, +3 m) montées par trois rampes, la manche à air et le
  banc au sommet, de l'herbe couchée par le vent ; au sud, la forêt, en premier plan.

Aucune lumière dans la scène : les lanternes de quai et les fenêtres du bureau sont des images (les lanternes brillent
la nuit par leur `glow`), la lumière est celle d'Atmosphere (E9).
"""

import math

import exterior_ground
import exterior_kits as kits
from exterior_pose import Rect, along, poisson, prop

SETTINGS = {
    "groups": ["Ship", "Quay", "Houses", "Rail", "Street", "Yard", "Hill", "Edge", "Hedge", "Woods", "Backdrop", "Sky",
               "Middle", "Foreground"],
    # La caméra monte jusqu'au vide (z = 6) et descend jusqu'au bas de la route de la ville (z = 30 pour le point
    # visé, la vue va jusqu'à z = 37) : CARTE.md disait Rect2(10, 6, 50, 17).
    "camera_bounds": (10, 6, 50, 24),
    "no_lights": True,
    # (QC2) Le point `panneau` est le panneau lui-même (la cible de la caméra et de l'examen, récit du jour 1) : on
    # le lit du sud, à `panneau_sud` ; le panneau de premier plan peut le couvrir (docs/QUALITE.md, QC-37).
    # (RC) Les vues du quai dont le bas de l'écran est la rue du port (on y passe : rien ne s'y dresse, CARTE.md 0.5).
    "south_allowed": {
        "quai_ouest": "le bas de l'écran est la rue du port, où l'on passe ; rien ne s'y dresse",
        "hangar": "le bas de l'écran est la rue du port, où l'on passe ; rien ne s'y dresse",
    },
    "masks_allowed": {"PanneauFlechesRouges": (("point panneau",),
                                               "le point est le panneau même ; on s'y tient au sud (panneau_sud)")},
    "texts": "res://data/texts/port.json",
    # Objets à examiner (data/texts/port.json, section « port ») : (clé, x, z, taille de la zone).
    "examine": [
        ("panneau", 6.0, 20.2, (2.2, 2.0, 1.6)),
        ("bord_du_vide", 17.5, 5.9, (3.2, 2.0, 1.2)),
        ("guichet", 5.5, 11.1, (2.4, 2.0, 1.4)),
        ("longue_vue", 11.0, 11.0, (2.2, 2.0, 1.4)),
        ("bras_d_ancrage", 29.5, 7.0, (2.2, 2.0, 1.4)),
        ("sifflet", 40.0, 7.3, (1.8, 2.0, 1.4)),
        ("caisses_cristaux", 43.5, 9.6, (2.6, 2.0, 1.4)),
        ("manche_a_air", 66.4, 8.3, (2.0, 2.0, 1.6)),
    ],
    # La passerelle monte à bord, et la route de la ville mène à la place du marché : tant que ces cartes n'existent
    # pas, leurs sorties sont omises (le plan les garde) ; un écriteau ferme la route de la ville.
    "omit_if_missing": ("passerelle", "vers_ville"),
}

# Places de la vie que le plan ne nomme pas : (nom, x, z, regard en degrés, à quoi elles servent). Écrites en
# Life/Places (Marker3D) et listées dans CARTE.md par `exterior_maps.py places`.
PLACES_WHY = [
    ("quai_ouest", 16.0, 12.6, 0.0, "le quai devant les caisses : le docker qui range, le commis qui attend (VIE.md 2.7)"),
    ("quai_est", 43.0, 11.4, 0.0, "le quai devant les caisses de cristaux : le docker de l'après-midi"),
    ("rue_ouest", 11.0, 17.0, 0.0, "la rue devant la cabane du gardien : un passant, le gardien qui sort fumer"),
    ("rue_centre", 30.0, 17.0, 0.0, "le milieu de la rue du port : les passants s'y croisent"),
    ("rue_est", 50.0, 17.0, 0.0, "la rue devant le hangar, avant la route de la ville"),
    ("bureau_porte", 5.5, 11.2, 180.0, "devant la porte du bureau du port : le commis (VIE.md 2.7)"),
    ("cabane_porte", 11.0, 11.2, 180.0, "devant la porte de la cabane : le gardien du port"),
    ("sifflet_poste", 40.0, 7.6, 180.0, "au pied du sifflet à vapeur : qui tire la chaîne à l'arrivée d'un navire"),
    ("bitte_corbeau_1", 26.5, 6.3, 0.0, "la bitte de l'ouest : le corbeau du port (VIE.md, faune)"),
    ("bitte_corbeau_2", 34.0, 6.3, 0.0, "la bitte de l'est : le corbeau du port (VIE.md, faune)"),
    ("hangar_porte", 51.0, 14.2, 180.0, "devant la grande porte du hangar : on charge et on décharge"),
    ("aire_ouest", 12.0, 25.5, 0.0, "l'ouest de l'aire-port, près des palettes : le docker qui trie"),
    ("aire_est", 46.0, 27.0, 0.0, "l'est de l'aire-port, près de la charrette à bras"),
    ("route_depart", 60.0, 31.5, 0.0, "le départ de la route de la ville : le marchand de passage qui s'en va"),
    ("banc_colline", 65.0, 11.0, 180.0, "le banc du sommet de la colline : on s'y assoit pour voir arriver les navires"),
    ("colline_pied", 57.0, 24.0, 0.0, "le pied de la montée : le guetteur de la Garde qui monte à son poste"),
    ("panneau_sud", 6.0, 22.8, 0.0, "au sud du panneau, regard au nord : le panneau aux flèches rouges derrière Willem, hors du premier plan qui s'efface autour de lui (ACTE1.md 1.1)"),
]

DEVIATIONS = [
    "bornes de la caméra `Rect2(10, 6, 50, 24)` au lieu de `Rect2(10, 6, 50, 17)` : le plan arrêtait le point visé à "
    "z = 23, la vue ne descendait plus qu'à z = 30 et le joueur sortait de l'écran sur l'aire-port et la route de la "
    "ville (jusqu'en z = 34)",
    "le relief de la colline (CARTE.md 6.2 : `rampe 58 22 61 26 2.0 1.0 O` et `rampe 61 16 64 20 3.0 2.0 O`) menait nulle "
    "part (les rampes finissaient devant des terrasses de +1 m, sans route de 0 à +1) : trois rampes qui montent vers le "
    "nord, aux flancs est et ouest (la caméra les voit de face : un flanc au sud d'une rampe laisse un trou dans les "
    "faces), 0 → +1 en z 27 → 24 (x 59 → 63), +1 → +2 en z 25 → 22 (x 64 → 68), +2 → +3 en z 19 → 16 (x 65 → 69), la "
    "falaise du sud n'occupe plus que x 63 → 70 et la montée `montee_colline` passe par elles, tout se marche",
    "point `navire_quai` (32,5 ; 7,6) ajouté au plan : le pied de la passerelle, où la scène fait descendre Willem du "
    "transport de la Garde",
    "(E7) le transport de la Garde, sa passerelle et les trois bras d'ancrage sont dans le poste d'amarrage `Berth` "
    "(ShipBerth ; navire en volume `ships/garde_transport`, bras `ships/mooring_arm_clamp`), hors de Geometry : vide hors "
    "des scènes ; le bord du vide (`vide 0 0 70 5` et la barrière de la côte, `barrier_gaps`) s'ouvre de x 31,4 à 33,6 "
    "devant la passerelle, que la porte du poste ferme tant qu'elle n'est pas posée ; marqueurs `navire_trappe` et "
    "`navire_passerelle` sur la passerelle posée, pour le récit",
    "les sorties `passerelle` (→ transport_garde) et `vers_ville` (→ ville_marche) sont posées dès que leur carte existe ; "
    "la passerelle reste fermée (ni invite ni signe) tant que le navire n'est pas à quai, sa passerelle posée et "
    "l'embarquement permis par le récit (à l'acte 1, jamais : CARTE.md 6.2) ; la route de la ville est fermée d'un "
    "écriteau « Plus loin, bientôt » tant que sa carte n'existe pas",
    "les lumières du plan (`lampe_quai_1`, `lampe_quai_2`, `bureau`, `projecteur_navire`) ne sont pas écrites : aucune "
    "lumière dans les cartes (mission CP), Atmosphere éclaire ; les lanternes de quai sont l'image `dock_lamp` (elle brille "
    "la nuit par son `glow`), le projecteur du navire est celui de la scène 7.4",
    "le panneau aux flèches rouges, la palissade brise-vent, les deux charrettes, le bras d'ancrage déployé, le "
    "sifflet, le cabestan, la cabane du gardien et le transport de la Garde sont des remplaçants (tools/hd2d_port.py, "
    "manifeste, lots R3 et R7) : une image livrée les remplace sans toucher au code",
    "la manche à air de la colline est l'image animée `windsock_wave` (le plan cite les deux) ; sa pose est celle du plan",
]

TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c"]
TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn"]
TREES_DARK = ["pine_tall_b", "tree_old_pine", "tree_pine", "oak_a", "beech_a", "pine_dead"]
BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f"]
GRASSES = ["wind_grass_a", "wind_grass_b", "tall_grass", "grass_clump_a", "grass_clump_c"]
ROCKS = ["rock_small_a", "rock_small_b", "rock_small_c", "rock_small_d"]
# Scène de chaque bâtiment du plan quand elle n'a pas le nom de son image.
BUILDING_SCENES = {}
# Scène posée à la place de l'image du plan (tools/exterior_maps.py, plan_gaps) : la manche à air animée.
SCENE_ALIASES = {"wind_sock": "windsock_wave", "gangway": "ships/garde_transport",
                 "garde_transport_side": "ships/garde_transport", "mooring_arm_open": "ships/mooring_arm_clamp"}
# (E7) Le transport de la Garde en volume (src/world/props/ships/garde_transport.tscn, Ship) dans son poste d'amarrage
# (nœud Berth, ShipBerth) : la quille au milieu du flanc en (30 ; 3), 1,5 m sous le quai, le pont (2,5 m au-dessus de la
# quille) à 1 m au-dessus du quai ; la passerelle part du seuil de la trappe (x 32,5) et se pose sur le quai en z 6,6.
SHIP_AT = (30.0, -1.5, 3.0)
# L'ouverture du bord du vide devant la passerelle (x 31,4 → 33,6) : la porte du poste (Gate) la ferme tant que la
# passerelle n'est pas posée.
GATE = (31.4, 33.6)


def pascal(text):
    return "".join(part.capitalize() for part in text.split("_"))


def ground_plan(m):
    """Le sol : le plan (quai de tôle, rue de pavés, aire-port de gravier, herbe sèche de la colline et ses trois
    terrasses, route de terre), le vide au nord (une côte droite devant le quai, la roche à l'est), des plaques de boue,
    de mousse et de feuilles."""
    plan = exterior_ground.ground_from_plan(
        m, noise=0.35, ramp_material="terre_battue",
        comment="Sol en relief du port (lot CP), d'après docs/lore/CARTE.md, section 6.2 : quai de tôle, rue de pavés, "
                "aire-port de gravier à 0, la colline ventée en trois terrasses (+1, +2, +3 m) montées par trois "
                "rampes, le vide de l'île au nord (la mer de nuages). Lu par tools/map_build.py gen port ; le jeu ne "
                "lit pas ce fichier.")
    plan["edges"]["north"] = "void"
    # (E7) Le mur invisible de la côte s'ouvre devant la passerelle (GATE) : la porte du poste d'amarrage le referme tant
    # que la passerelle n'est pas posée.
    plan["barrier_gaps"] = [[GATE[0], 3.0, GATE[1] - GATE[0], 3.0]]
    steps = plan["steps"]
    # Le quai est de tôle aux bords francs (le plan : sol metal 0 5 58 14) ; là où le bruit des autres matières en laisse un
    # trou, c'est du pavé, pas de l'herbe.
    plan["base"]["material"] = "paves"
    for s in steps:
        if s["op"] == "material" and s["material"] == "tole":
            s["shape"].pop("noise", None)
    # La rue est de pavés : pas de bande de terre sur eux (la montée de la colline et la route de la ville, si).
    steps[:] = [s for s in steps if not (s["op"] == "path" and s["points"][0] == [1, 17])]
    # La route de la ville longe le pied de la colline (x 58) : sa terre reste à 2 m de large, aux bords francs (un chemin
    # ne longe pas une marche de plus de 0,5 m).
    for s in steps:
        if s["op"] == "path" and s["points"][0] == [55.5, 18]:
            s["width"], s["noise"] = 2.0, 0.1
    # La terre battue du plan (x 54 → 70, z 20 → 34) recouvre le pied de la colline : elle ne se peint qu'au niveau du sol
    # (la colline reste d'herbe sèche ; une matière de chemin ne longe pas une marche de plus de 0,5 m).
    for s in steps:
        if s["op"] == "material" and s["material"] == "terre_battue":
            s["where"] = {"level": 0}
    first = exterior_ground.step_index(steps, "face")
    steps[first:first] = [
        {"op": "void", "shape": {"rect": [-3, -3, 64, 8]}},
        {"op": "void", "shape": {"poly": [[58, -3], [73, -3], [73, 5.3], [69, 4.5], [65.5, 5.4], [61.5, 4.7], [58, 5.0]],
                                 "noise": 0.25, "noise_scale": 2.0, "seed": 5}},
    ]
    # Plaques : boue au pied des charrettes, mousse et feuilles au bord de la rue, herbe sèche sur la colline.
    patches = [("mousse", 62.0, 14.0, 2.4, 1.4, 6), ("mousse", 67.0, 21.0, 2.2, 1.0, 4),
               ("feuilles", 12.0, 32.0, 4.0, 1.0, 0), ("feuilles", 44.0, 32.4, 4.0, 1.0, 0),
               ("feuilles", 28.0, 31.4, 3.0, 0.8, 0)]
    first_path = exterior_ground.step_index(steps, "path")
    for k, (name, cx, cz, rx, rz, lv) in enumerate(patches):
        steps.insert(first_path, {"op": "material", "material": name,
                                  "shape": {"ellipse": [cx, cz, rx, rz], "noise": 0.5, "noise_scale": 1.6, "seed": 70 + k},
                                  "where": {"level": lv}})
    return plan


def prepare(p):
    # (E7) Le bord du vide (le plan : vide 0 0 70 5) s'ouvre devant la passerelle (GATE) : le poste d'amarrage y pose sa
    # porte, ouverte quand la passerelle est posée sur le quai.
    for k, e in enumerate(p.edges):
        if (e.x0, e.z0, e.x1, e.z1) == (0, 0, 70, 5):
            p.edges[k] = Rect(0.0, 0.0, GATE[0], 5.0)
            p.edges.append(Rect(GATE[1], 0.0, 70.0, 5.0))
            break
    p.arms = []
    # Le poste d'amarrage n'a pas de garde-fou (x 23 → 37) : la bande du bord (z 5 → 5,9), derrière les bras d'ancrage et les
    # bittes, est fermée par des chaînes que la scène ne pose pas (rien n'y marche : un bras de 4 m cacherait le joueur, et
    # le bord du vide n'est pas un lieu de passage) ; le pied du sifflet de même (z 5,4 → 6,3).
    p.edges.append(Rect(22.5, 5.0, 31.4, 5.9))
    p.edges.append(Rect(33.6, 5.0, 37.5, 5.9))
    p.edges.append(Rect(37.0, 5.4, 46.0, 6.8))
    # Le pylône (6 m) et la grue (6 m) aux deux bouts du quai, le fanion et la manche à air du sommet : rien n'y marche
    # derrière eux (un décor de 6 m cache 8,8 m au nord de lui).
    p.edges.append(Rect(0.0, 5.0, 3.0, 10.4))
    # Entre le bureau et la cabane, un passage d'un mètre (x 8 → 9) sous deux toits : fermé (des tonneaux et des caisses le
    # montrent fermé) ; la caméra, bornée à x ≥ 10, le voit en biais à travers la tôle.
    p.edges.append(Rect(8.0, 5.0, 9.0, 10.4))
    p.edges.append(Rect(56.0, 5.0, 59.6, 7.4))
    p.edges.append(Rect(65.5, 5.0, 70.0, 7.6))


def pose(p):
    M, W, D = p.map, p.W, p.D
    rng = p.rng
    place, scatter = p.place, p.scatter
    in_map, outside_edges = p.in_map, p.outside_edges
    free, height, walk_grid = p.free, p.height, p.walk_grid
    PATHS = p.paths
    BUILDINGS = p.buildings

    walk_grid()

    # === 1. Ossature du plan (6.2) =====================================================================

    for b in M.buildings:
        cx, cz = (b.rect.x0 + b.rect.x1) / 2.0, (b.rect.z0 + b.rect.z1) / 2.0
        place("Houses", BUILDING_SCENES.get(b.extra["img"], b.extra["img"]), cx, cz, name=pascal(b.name), check=False)

    lamps = 0
    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        if n == "garde_transport_side":
            # (E7) Le navire et sa passerelle sont dans le poste d'amarrage (extra_nodes).
            continue
        elif n == "gangway":
            # La passerelle posée (du seuil de la trappe, z 3,15, au quai, z 6,6) : rien ne se pose à son pied.
            hx, hz = prop("gangway_quay").half
            p.blockers.append(Rect(x - hx, 5.1 - hz, x + hx, 5.1 + hz))
        elif n == "mooring_arm_open":
            # (E7) Les bras d'ancrage aussi : leur bande se referme sur le navire (extra_nodes).
            p.arms.append((x, z))
            hx, hz = prop(n).half
            p.blockers.append(Rect(x - hx, z - hz, x + hx, z + hz))
        elif n == "dock_lamp":
            lamps += 1
            place("Quay", n, x, z, name="LanterneQuai%d" % lamps)
        elif n == "wind_sock":
            place("Hill", "windsock_wave", x, z, name="MancheAAir", check=False)
        elif n == "bench":
            place("Hill", n, x, z, name="BancColline", check=False)
        elif n == "signpost_port":
            place("Street", n, x, z, name="PanneauFlechesRouges")
        elif n == "wind_fence":
            place("Street", n, x, z, name="Palissade_%d" % round(x), flip=round(x) % 40 == 0)
        elif n == "steam_whistle":
            place("Quay", n, x, z, name="SiffletVapeur")
        elif n == "rope_coil":
            place("Quay", n, x, z, name="CordageGalerie", check=False)
        else:
            place("Yard" if z > 14 else "Quay", n, x, z, name=pascal(n) + "_%d" % round(x * 10))

    # La vapeur du sifflet, qui fume au repos (la bande animée du cahier n° 2).
    place("Quay", "furnace_steam", 40.0, 6.4, y=1.8, name="VapeurSifflet", check=False)
    walk_grid()

    # === 2. Le garde-fou, le bord du vide et la coque du navire =========================================

    # Garde-fou de fonte tout le long du quai, sauf au poste d'amarrage (x 23 → 37) ; des roches au bord de la colline.
    # (RC) Le garde-fou en rangée irrégulière (exterior_kits.row) : pièces qui se chevauchent un peu (jamais de trou au
    # bord du vide), reculées vers le quai seulement (0 à 0,25 m), retournées au hasard ; un pan rapiécé de cordage ou
    # de rambarde de tôle tous les quatre à sept éléments (une fonte livrée plus tard, famille port_rail, y entre).
    for k, (xa, xb) in enumerate(((0.0, 22.0), (38.0, 58.0))):
        kits.place_row(p, "Rail", "GardeFou%d_" % (k + 1),
                       kits.row([(xa + 1.0, 5.2), (xb - 1.0, 5.2)], kits.family("port_rail"), seed=1201 + k,
                                spread=0.08, depth_range=(0.0, 0.25), skip=0.0, overlap=0.95,
                                accents=kits.family("port_rail_accents"), accent_every=(2, 4), scale=(0.96, 1.04),
                                tone=(0.03, 0.0)), check=False)
    for k, (x, z, scene) in enumerate(((59.5, 4.6, "edge_rocks_b"), (63.5, 4.8, "edge_rocks_a"), (67.5, 4.6, "edge_rocks_b"))):
        place("Edge", scene, x, z, name="RocheBord%d" % (k + 1), flip=k % 2 == 1, check=False)
    for k, x in enumerate((2.5, 9.0, 20.0, 41.0, 49.0, 56.5)):
        place("Edge", "edge_grass", x, 4.9, name="HerbeBord%d" % (k + 1), flip=k % 2 == 0, check=False)

    # === 3. Le quai : tout ce qui est contre un dirigeable (6.2, kits « quai ») ============================

    # Les décalques du quai : taches de mazout, coulures de rouille, bouches d'égout.
    for k, (x, z, scene) in enumerate(((19.0, 10.4, "oil_stain"), (41.5, 11.8, "rust_streak"), (28.0, 11.4, "drain_grate"),
                                       (35.0, 10.2, "oil_stain"), (49.0, 14.6, "rust_streak"), (14.0, 13.4, "drain_grate"),
                                       (25.5, 8.6, "rust_streak"), (44.0, 6.6, "oil_stain"), (7.5, 13.2, "oil_stain"),
                                       (22.5, 12.2, "drain_grate"), (31.0, 12.4, "rust_streak"), (36.2, 8.0, "drain_grate"),
                                       (26.5, 10.4, "oil_stain"), (52.0, 12.6, "oil_stain"), (11.0, 13.2, "rust_streak"),
                                       (33.0, 9.8, "pebbles_a"), (29.0, 7.9, "leaves_rust_a"), (47.0, 14.9, "leaves_gold_a"))):
        place("Quay", scene, x, z, name="QuaiDecal%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Le sol de tôle, tout le long : des taches, des fentes, des feuilles et des papiers que le vent amène, des bouches
    # d'égout ; des décalques seulement (rien n'y bloque : la place de l'accostage reste libre).
    plates = poisson(Rect(3.2, 5.8, 57.6, 13.8), 2.5, 140, lambda x, z: free(decal=True)(x, z) and not any(
        b.has(x, z, 0.3) for b in BUILDINGS), seed=81)
    scatter("QuayStains", ["oil_stain", "rust_streak", "cracks_a", "cracks_b", "drain_grate"], plates[0::2], seed=82, check=False)
    scatter("QuayLitter", ["pebbles_b", "puddle_b", "pebbles_a", "cracks_b", "leaves_gold_a"], plates[1::2], seed=83,
            check=False)
    # Les bouts du quai : tonneaux de mazout, filet de charge, chaîne, bagages, caisses de la Garde, tuyaux, grue.
    place("Quay", "mooring_tower", 1.2, 7.6, name="Pylone")
    place("Quay", "crate_stack", 1.7, 11.6, name="CaissesBoutQuai")
    place("Quay", "barrel_group", 2.2, 13.2, name="TonneauxBoutQuai")
    place("Quay", "fuel_barrels", 14.0, 6.9, name="Mazout1")
    place("Quay", "cargo_net", 18.8, 7.6, name="FiletCargo")
    place("Quay", "chain_pile", 24.6, 8.1, name="Chaine", check=False)
    place("Quay", "garde_crate", 20.6, 10.8, name="CaisseGarde1")
    place("Quay", "rope_coil", 38.6, 8.6, name="Cordage2", flip=True, check=False)
    place("Quay", "garde_crate", 38.2, 10.6, name="CaisseGarde2", flip=True)
    place("Quay", "steam_pipes", 42.2, 7.0, name="Tuyaux")
    place("Quay", "deck_crates_lashed", 44.8, 12.2, name="CaissesSanglees")
    place("Quay", "luggage", 47.4, 14.0, name="Bagages")
    place("Quay", "fuel_barrels", 41.2, 13.2, name="Mazout2", flip=True)
    place("Quay", "cargo_crane", 57.0, 7.0, name="Grue")
    place("Quay", "bucket", 9.0, 10.8, name="SeauCabane", check=False)
    place("Quay", "barrel_group", 8.5, 9.4, name="TonneauxPassage")
    place("Quay", "crate_stack", 8.5, 7.2, name="CaissesPassage")
    junk = poisson(Rect(3.4, 6.0, 57.4, 13.8), 3.2, 40, lambda x, z: free(blocking=True)(x, z) and not (
        3.0 < x < 13.4 and z < 10.6) and not (45.5 < x < 56.5 and z < 13.8), seed=84)
    scatter("QuayJunk", ["crate", "bucket", "rope_coil", "chain_pile", "sack_apples", "crate_apples", "rain_barrel",
                         "deck_crates_lashed"], junk, seed=89)
    place("Quay", "rain_barrel", 13.8, 10.3, name="TonneauCabane")

    # === 4. La rue du port et l'aire-port (6.2, kits « rue » et « aire-port ») =============================

    # Feuilles, cailloux et flaques sur les pavés (pas d'ornières : le décalque livré se lit comme un sillon de labour,
    # R0.8) ; un banc au pied de la cabane, côté quai.
    for k, (x, z, scene) in enumerate(((20.0, 15.4, "leaves_rust_a"), (44.0, 19.0, "leaves_gold_b"),
                                       (27.0, 18.6, "pebbles_a"), (46.0, 16.0, "pebbles_b"), (14.0, 19.0, "puddle_a"),
                                       (38.0, 15.4, "puddle_b"), (4.0, 15.2, "leaves_rust_b"), (33.0, 17.8, "pebbles_b"),
                                       (53.0, 15.6, "leaves_gold_a"), (22.0, 19.0, "pebbles_a"), (8.0, 17.4, "pebbles_a"),
                                       (49.0, 18.6, "mud_patch"), (30.0, 14.8, "leaves_scatter"), (17.0, 16.4, "footprints"))):
        place("Street", scene, x, z, name="RueDecal%d" % (k + 1), flip=k % 2 == 1, check=False)
    street = poisson(Rect(0.8, 14.5, 57.6, 19.8), 2.4, 120, lambda x, z: free(decal=True, paths=False)(x, z), seed=85)
    scatter("StreetStains", ["oil_stain", "rust_streak", "cracks_a", "cracks_b", "mud_patch"], street[0::3], seed=86, check=False)
    scatter("StreetLitter", ["pebbles_a", "pebbles_b", "leaves_gold_a", "pebbles_a", "puddle_a"],
            street[1::3], seed=87, check=False)
    scatter("StreetWeeds", ["grass_tuft", "grass_clump_a", "clover_patch"], street[2::3], seed=88, check=False)
    place("Yard", "bench", 9.6, 14.1, name="BancCabane", check=False)
    place("Yard", "crate", 42.6, 14.1, name="CaisseRue")
    place("Yard", "crate_apples", 12.6, 14.1, name="CaissePommes", check=False)
    place("Yard", "notice_board", 55.4, 14.6, name="Affichage")

    # L'aire-port : charrettes, sacs, palettes, bagages et caisses ; la brouette ; des tas de ferraille ; des traces.
    place("Yard", "sack_apples", 31.0, 27.6, name="SacsAire", check=False)
    place("Yard", "luggage", 38.0, 28.2, name="BagagesAire")
    place("Yard", "crate_stack", 52.0, 27.4, name="CaissesAire")
    place("Yard", "barrel_group", 8.0, 28.0, name="TonneauxAire")
    place("Yard", "wheelbarrow", 18.0, 28.4, name="BrouetteAire")
    place("Yard", "scrap_pile", 24.4, 28.9, name="Ferraille")
    place("Yard", "propeller_spare", 3.6, 24.4, name="HeliceDeRechange")
    place("Yard", "garde_crate", 44.4, 28.4, name="CaisseGardeAire")
    place("Yard", "sandbags", 14.6, 23.4, name="SacsDeSable")
    place("Yard", "crate_stack", 1.8, 28.4, name="CaissesOuest")
    for k, (x, z, scene) in enumerate(((10.0, 21.8, "hay_scatter"), (33.0, 21.6, "mud_patch"), (48.0, 23.4, "puddle_a"),
                                       (16.0, 26.0, "puddle_b"), (40.0, 26.4, "mud_patch"), (26.0, 26.6, "hay_scatter"),
                                       (52.0, 29.2, "leaves_rust_b"), (6.0, 26.6, "leaves_gold_a"), (36.0, 24.4, "pebbles_a"),
                                       (20.0, 22.2, "pebbles_b"), (45.0, 21.8, "pebbles_a"), (13.0, 29.0, "pebbles_b"),
                                       (29.0, 24.0, "footprints"), (43.0, 25.2, "footprints"), (22.0, 25.6, "leaves_scatter"),
                                       (4.0, 22.2, "hay_scatter"), (55.0, 24.6, "mud_patch"), (50.0, 21.2, "leaves_gold_b"))):
        place("Yard", scene, x, z, name="AireDecal%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Entre les deux, le long du pied de la colline : des herbes folles qui poussent entre les graviers.
    yard = poisson(Rect(0.8, 20.6, 57.0, 29.8), 2.6, 90, lambda x, z: free(half=(0.3, 0.2))(x, z) and not (
        22.0 < x < 46.0 and 22.0 < z < 25.0), seed=41)
    scatter("YardGrass", ["grass_clump_a", "grass_clump_c", "tall_grass", "grass_tuft", "wild_grass" if False else "grass_clump_d"],
            yard[0::2], seed=42, check=False)
    scatter("YardStones", ROCKS + ["fern_c"], yard[1::3], seed=43, check=False)
    yard_decals = poisson(Rect(0.8, 20.6, 57.0, 29.8), 3.4, 100, lambda x, z: free(decal=True)(x, z), seed=44)
    scatter("YardMud", ["mud_patch", "puddle_a", "puddle_b", "hay_scatter", "leaves_rust_b", "leaves_scatter", "pebbles_a",
                        "pebbles_b", "footprints"], yard_decals, seed=45, check=False)
    # Le pied de la route de la ville, avant la sortie : des buissons, des herbes, des cailloux.
    route = poisson(Rect(55.0, 29.4, 69.4, 34.0), 1.7, 40, lambda x, z: free()(x, z) and outside_edges(x, z, 0.1), seed=46)
    scatter("RouteBrush", BUSHES[:4] + ["fern_c", "tall_grass", "heather"] + ROCKS[:2], route, seed=47, check=False)
    for k, (x, z, scene) in enumerate(((60.0, 32.6, "leaves_rust_a"), (63.6, 33.2, "leaves_gold_b"), (58.6, 30.6, "pebbles_a"),
                                       (65.0, 30.8, "pebbles_b"), (61.6, 30.4, "mud_patch"), (64.4, 34.8, "leaves_scatter"))):
        place("Street", scene, x, z, name="RouteDecal%d" % (k + 1), flip=k % 2 == 1, check=False)

    # === 5. La colline ventée : herbes couchées, cailloux, bruyère (6.2, kits « colline ») ==================

    hill = poisson(Rect(56.5, 5.8, 69.6, 29.6), 1.3, 130, free(), seed=31)
    scatter("HillGrass", ["wind_grass_a", "wind_grass_b", "grass_tuft", "grass_clump_d", "grass_clump_b"], hill[0::2], seed=32,
            check=False)
    scatter("HillRocks", ROCKS + ["heather", "thistle"], hill[1::4], seed=33, check=False)
    scatter("HillTufts", ["grass_tuft", "wind_grass_a", "wildflowers_b"], hill[3::4], seed=34, check=False)
    place("Hill", "stump_a", 61.0, 8.4, name="SoucheColline", check=False)
    place("Hill", "rock_pile", 68.0, 14.4, name="CairnColline", check=False)
    place("Hill", "old_telescope", 63.8, 8.6, name="LongueVueGuetteur")
    place("Hill", "garde_pennant", 68.6, 6.8, name="FanionGarde")
    # La falaise au sud de la colline (le plan : bord falaise) : des roches.
    for k, x in enumerate((64.6, 67.4)):
        place("Edge", ["edge_rocks_a", "edge_rocks_b"][k % 2], x, 27.4, name="RocheSud%d" % (k + 1), flip=k % 2 == 0, check=False)

    # === 6. Le sud, les bords, la forêt qui continue ====================================================

    south = poisson(Rect(0.5, 30.2, 56.0, 33.6), 1.3, 70, lambda x, z: free()(x, z) and outside_edges(x, z, 0.1), seed=60)
    scatter("SouthGrass", GRASSES, south[0::3], seed=61, check=False)
    scatter("SouthFlowers", ["wildflowers_a", "wildflowers_b", "heather", "fern_c"], south[1::3], seed=62, check=False)
    scatter("SouthStones", ROCKS + ["bush_d"], south[2::6], seed=63, check=False)
    scatter("SouthBushes", BUSHES, south[5::6], seed=64, check=False)
    front = poisson(Rect(0.5, 34.4, 54.0, 39.2), 4.0, 14, lambda x, z: True, seed=70)
    scatter("SouthTrunks", ["fg_trunk_a", "fg_trunk_b"], front[0::5], seed=71, check=False)
    scatter("SouthBrush", ["fg_bush", "fg_fern", "fg_grass"], [q for k, q in enumerate(front) if k % 5], seed=72, check=False)
    # (RC) Une haie irrégulière (exterior_kits.row) : quatre sortes de fourrés, jamais deux fois de suite la même.
    kits.place_row(p, "Hedge", "HaieSud", kits.row([(0.8, 38.7), (53.6, 38.7)],
                                                   ["thicket_a_fg", "thicket_b_fg", "thicket_c", "bramble_hedge"],
                                                   seed=1210, spread=0.3, depth=0.4, skip=0.12, scale=(0.9, 1.1),
                                                   overlap=1.0))
    # Les arbres au-delà du bord sud-est (bord foret 58 → 70 ; 34 → 40) et la forêt qui continue à l'ouest.
    # (QC2) Au bas de la route de la ville, un jeune pin : un grand arbre y couvrait le départ de la route
    # (docs/QUALITE.md, QC-37).
    for k, (x, z, scene) in enumerate(((60.0, 39.0, "pine_small_a_forest"), (66.0, 39.4, "maple_a_forest"),
                                       (72.0, 36.4, "beech_c_forest"))):
        place("Woods", scene, x, z, name="ArbreSudEst%d" % (k + 1), check=False)
    backdrop = [(-3.0, z + rng.uniform(-1.0, 1.0)) for z in (8.0, 14.0, 20.0, 26.0, 32.0)]
    backdrop += [(74.0, z + rng.uniform(-1.0, 1.0)) for z in (10.0, 18.0, 26.0, 33.0)]
    trees = TREES_DARK + TREES_RUST
    for k, (x, z) in enumerate(backdrop):
        place("Backdrop", trees[k % len(trees)], x, z, y=0.0, name="Fond%d" % (k + 1), flip=k % 2 == 1, check=False)

    # La route de la ville est fermée tant que la place du marché n'existe pas : un écriteau (CARTE.md 6.2).
    if "vers_ville" in p.missing_exits:
        place("Street", "waiting_sign", 66.4, 34.6, name="EcriteauVille")

    # === 7. Le ciel au nord : des rochers qui flottent, des îles, des dirigeables de passage =============

    for k, (x, y, z, scale, scene) in enumerate(SKY):
        place("Sky", scene, x, z, y=y, scale=scale, name="Vide%d" % (k + 1), flip=k % 3 == 1, check=False)

    # === 8. (RC) Les plans (CARTE.md 0.5) ================================================================
    # Plan moyen : des piles de caisses, de sacs et une charrette sur l'aire-port, hors de sa place (on y décharge) et
    # loin de la route ; premier plan : au bas de chaque vue (feuillages au sud, charrettes et hélice sur l'aire).
    walk_grid()
    kits.middle_kit(p, [(Rect(2.0, 21.0, 21.0, 29.5), 3), (Rect(47.0, 21.0, 54.0, 29.5), 2),
                        (Rect(22.0, 26.2, 46.0, 29.6), 2)], kits.family("mid_port"), seed=1221, spacing=5.0)
    kits.foreground_views(p, "port", seed=1231,
                        foliage=kits.family("fg_foliage", ["fg_grass", "cargo_cart_a_fg", "propeller_spare_fg"]))


# Le ciel et le vide : (x, y, z, échelle, scène). La nappe de nuages est à y = −60 ; le quai est à y = 0.
SKY = [
    (-12.0, -52.0, -112.0, 0.55, "distant_island_a"), (46.0, -45.0, -96.0, 0.5, "distant_island_b"),
    (31.0, -33.0, -72.0, 0.4, "distant_island_e"), (12.0, -58.0, -140.0, 0.6, "distant_island_f"),
    (64.0, -58.0, -150.0, 0.65, "distant_island_c"), (-36.0, -58.0, -175.0, 0.8, "distant_island_d"),
    (20.0, -58.0, -240.0, 4.5, "horizon_islands"),
    (14.0, -56.0, -128.0, 1.8, "cloud_c"), (44.0, -56.0, -148.0, 2.0, "cloud_a"), (-12.0, -57.0, -166.0, 2.2, "cloud_b"),
    (28.0, -57.0, -186.0, 2.5, "cloud_c"), (60.0, -58.0, -206.0, 2.7, "cloud_a"),
    (18.0, -50.0, -110.0, 2.2, "mist_band"), (44.0, -54.0, -150.0, 3.2, "mist_band"),
    (52.0, -22.0, -70.0, 1.0, "airship_far_a"), (10.0, -30.0, -104.0, 1.0, "airship_far_b"),
    (5.5, -9.0, -20.0, 0.9, "floating_rock_b"), (58.0, -12.0, -30.0, 1.0, "floating_rock_c"),
    (-3.0, -17.0, -42.0, 1.2, "floating_rock"), (40.0, -21.0, -60.0, 1.1, "floating_rock_b"),
]


def ambient(p):
    """Vie ambiante : des oiseaux qui traversent, quelques feuilles d'automne que le vent emporte."""
    return [
        ("Birds", "birds_flock", 6, 10, 1, 3, (40, 6, 20), 6.0, (0, 0), 4.0, 0.8, 3, (30, 0, 14)),
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 6, (28, 9, 18), 0.0, (0, 0), 1.6, 0.8, 4, (30, 0, 22)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 6, (28, 9, 18), 0.0, (0, 0), 1.8, 0.8, 5, (30, 0, 22)),
    ]


def extra_nodes(p, w):
    """(E7) Le poste d'amarrage du transport de la Garde (nœud Berth, ShipBerth, après les sorties : il règle la sortie
    « Monter à bord ») : le navire en volume (vide hors des scènes : ShipControl le fait descendre), les trois bras
    d'ancrage (leur bande se referme de la poupe à la proue), la porte du vide devant la passerelle, et deux marqueurs
    pour le récit sur la passerelle posée (navire_trappe, au seuil de la trappe ; navire_passerelle, à mi-pente)."""
    from exterior_maps import f
    script = w.ext_id("Script", "res://src/world/ships/ship_berth.gd")
    ship = w.ext_id("PackedScene", "res://src/world/props/ships/garde_transport.tscn")
    arm = w.ext_id("PackedScene", "res://src/world/props/ships/mooring_arm_clamp.tscn")
    gate = w.box_shape("berth_gate", (GATE[1] - GATE[0], 4.0, 1.4))
    exit_path = "" if "passerelle" in p.missing_exits else "../Exits/passerelle"
    sx, sy, sz = SHIP_AT
    nodes = ['[node name="Berth" type="Node3D" parent="."]\nscript = ExtResource("%s")\nship_id = &"transport_garde"\n'
             'exit_path = NodePath("%s")\n' % (script, exit_path),
             '[node name="TransportGarde" parent="Berth" instance=ExtResource("%s")]\n'
             'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n' % (ship, f(sx), f(sy), f(sz)),
             '[node name="Arms" type="Node3D" parent="Berth"]\n']
    for k, (x, z) in enumerate(p.arms):
        nodes.append('[node name="BrasAncrage%d" parent="Berth/Arms" instance=ExtResource("%s")]\n'
                     'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n'
                     % (k + 1, arm, f(x), f(p.height(x, z)), f(z)))
    nodes += ['[node name="Gate" type="StaticBody3D" parent="Berth"]\ncollision_mask = 0\n',
              '[node name="Shape" type="CollisionShape3D" parent="Berth/Gate"]\n'
              'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 2, 4.3)\nshape = SubResource("%s")\n'
              % (f((GATE[0] + GATE[1]) / 2.0), gate)]
    # Seuil de la trappe (le pont à 1 m) et mi-pente de la passerelle posée, regard au sud (vers le quai).
    for name, z, y in (("navire_trappe", 3.6, 1.05), ("navire_passerelle", 5.0, 0.6)):
        nodes.append('[node name="%s" type="Marker3D" parent="Markers"]\n'
                     'transform = Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, 32.5, %s, %s)\n' % (name, f(y + 0.2), f(z)))
    return nodes
