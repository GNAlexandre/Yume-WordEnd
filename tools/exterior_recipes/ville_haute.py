"""(CV) Le centre-ville, la ville haute : la pose de la carte `ville_haute` d'après docs/lore/CARTE.md, section 9.2
(bloc ```plan lu par tools/carte_plans.py).

Ce que dit l'œuvre (9.1) : des centaines de bâtiments de pierre sur une légère pente, une atmosphère idyllique, des
passants qui ne se soucient pas qu'on n'ait pas de traits ; on y descend de l'entrepôt par un sentier ; le
snack-bar du jeune lycanthrope, la librairie, le café habituel, la salle de projection, l'apothicaire (déduction).
Composition (plan), vue de la caméra qui regarde le nord (CARTE.md 0.3) :
- la ville monte vers le nord par trois terrasses (+2, +1, 0), la grand-rue de dalles descend du nord au sud par deux
  volées de marches, trois ruelles pavées la coupent d'est en ouest (la rue haute, la rue du café, la rue basse) ;
- chaque terrasse a sa rangée de maisons, façades au sud, et derrière elle des jardins clos (jamais un endroit où
  l'on marche : un toit de 6 m cache 9 m au nord de lui) ; muret de pierre (face « muret » des paliers) et garde-corps
  de fer au bord des terrasses ;
- au nord, la lisière de la forêt et, par-dessus elle, les toits de la ville qui continue de monter.

Aucune lumière dans la scène (comme toutes les cartes du dehors : la nuit est celle d'Atmosphere, E9) : les lanternes
du plan (réverbère double, lanterne du haut) ne sont que des images ; leurs lumières sont des repères que la carte
n'écrit pas.
"""

import exterior_ground
from exterior_pose import Rect, along, poisson

SETTINGS = {
    "groups": ["Houses", "Facade", "Roof", "Street", "Garden", "Edge", "Woods", "Backdrop", "Sky"],
    "no_lights": True,
    "texts": "res://data/texts/ville.json",
    # Objets à examiner du dehors (data/texts/ville.json, section « ville_haute »).
    "examine": [
        ("fontaine", 25.0, 11.6, (1.6, 2.0, 1.0)),
        ("enseigne_poele", 40.2, 31.3, (1.2, 2.0, 1.2)),
        ("enseigne_tasse", 17.5, 31.3, (1.2, 2.0, 1.2)),
        ("porte_accessoires", 43.0, 30.9, (1.6, 2.0, 1.0)),
        ("porte_apothicaire", 12.5, 51.8, (1.6, 2.0, 1.0)),
        ("trappe_cave", 48.0, 53.0, (1.4, 2.0, 1.0)),
        ("caisses_pommes", 6.0, 53.2, (1.4, 2.0, 1.2)),
        ("banc_haut", 45.0, 14.7, (1.8, 2.0, 1.0)),
    ],
    # La salle de projection ne s'ouvre qu'au jour 5 (ACTE1.md, 1.3 : « Pas sans un adulte. » jusqu'au jour 5) : la
    # sortie est posée, la condition est dite en métadonnée pour le récit (StoryStage.apply_doors, E6).
    "exit_meta": {
        "porte_projection": 'metadata/open_from_day = 5\nmetadata/closed_text_key = "ville/projection_close"\n',
    },
}

# Places de la vie que le plan ne nomme pas : (nom, x, z, regard en degrés, à quoi elles servent). Écrites en
# Life/Places (Marker3D) et listées dans CARTE.md par `exterior_maps.py places`. Regard : 0 vers le nord, 180 vers le
# sud, 90 vers l'ouest, −90 vers l'est.
PLACES_WHY = [
    ("rue_haute_ouest", 8.0, 13.0, 0.0, "la rue haute, côté sentier : le passant qui arrive de la forêt ou y retourne"),
    ("rue_haute_est", 47.0, 13.0, 0.0, "la rue haute, devant les grandes maisons de l'est : les passants s'y croisent"),
    ("rue_haute_trottoir_nord", 9.0, 11.6, 0.0, "le trottoir nord de la rue haute : le passant qui change de trottoir à la vue des trois fées (ACTE1.md 3.2)"),
    ("rue_haute_trottoir_sud", 9.0, 14.4, 0.0, "le trottoir sud de la rue haute, où il passe pour les éviter (ACTE1.md 3.2)"),
    ("banc_haut", 45.0, 14.7, 180.0, "le banc de pierre au bord de la terrasse haute : on s'y assoit face à la rue"),
    ("grand_rue_nord", 30.0, 20.0, 0.0, "la grand-rue, sous la volée du haut : le promeneur qui descend vers la ville"),
    ("grand_rue_milieu", 30.0, 27.0, 0.0, "la grand-rue entre la librairie et le snack : les passants qui descendent vers le marché"),
    ("carrefour_centre", 30.0, 32.0, 0.0, "le milieu du carrefour de la rue du café : on s'y croise, on s'y arrête pour discuter"),
    ("carrefour_ouest", 14.0, 32.0, 0.0, "la rue du café devant la librairie : le client qui hésite devant la vitrine"),
    ("carrefour_est", 47.0, 32.0, 0.0, "la rue du café devant l'accessoiriste : la cliente qui regarde les chapeaux"),
    ("snack_terrasse", 38.8, 32.2, 180.0, "devant le comptoir du snack, sur la rue : le client qui attend sa part"),
    ("porte_snack", 37.5, 32.2, 0.0, "devant la porte du snack-bar : où l'on entre, d'où l'on sort (ACTE1.md 3.3 : `ville_haute:porte_snack`)"),
    ("cafe_devant", 23.0, 32.2, 180.0, "devant le café, au coin de la grand-rue : le buveur qui sort fumer"),
    ("bas_de_ville_centre", 30.0, 55.0, 0.0, "la place du bas de la ville : on s'y retrouve avant de descendre au marché"),
    ("rue_basse_ouest", 12.0, 55.0, 0.0, "la rue basse devant l'apothicaire : les passants du matin"),
    ("rue_basse_est", 47.0, 55.0, 0.0, "la rue basse devant les maisons de l'est : le passant qui rentre chez lui"),
    ("vers_marche", 30.0, 58.0, 180.0, "le bas de la grand-rue : d'ici on part vers la place du marché (ville_marche)"),
    ("depuis_sentier", 4.0, 13.0, -90.0, "l'entrée de la ville côté sentier : le passant qui arrive de l'entrepôt"),
]

DEVIATIONS = [
    "les deux volées de la grand-rue sont de vrais escaliers (marches de 0,1 m, joues en muret : `stairs` du sol en "
    "relief) au lieu de rampes : même rectangle, même sens ; les faces des paliers sont en muret de pierre",
    "la rue haute, la rue du café, la rue basse et la grand-rue sont pavées en entier (la bande de terre que les "
    "autres cartes peignent le long de leurs chemins n'est pas peinte ici)",
    "un muret de pierre (`town_wall_low`) ferme le haut de la grand-rue au nord (x 23 → 37, z 9,6) : la fontaine murale "
    "et la lanterne du plan y sont adossées ; derrière, le bois",
    "maisons du bord de la carte (les `bord maisons` du plan) posées avec les images de maisons du plan, leurs emprises "
    "à la taille des bords ; la salle de projection et la librairie sont celles du cahier n° 2",
    "la lanterne à cristal et le réverbère du plan (`lumiere`) ne sont pas écrits : aucune lumière dans les cartes, "
    "Atmosphere éclaire ; le réverbère double est une image de premier plan",
]

TREES_GOLD = ["tree_autumn_yellow", "beech_a", "maple_b", "oak_b", "beech_c", "maple_c"]
TREES_RUST = ["tree_autumn_rust", "maple_a", "oak_c", "beech_b", "oak_d", "tree_autumn"]
BUSHES = ["bush", "bush_b", "bush_c", "bush_d", "bush_e", "bush_f", "berry_bush", "berry_bush_b"]
FERNS = ["fern_a", "fern_b", "fern_c", "fern_d"]
GRASSES = ["grass_clump_a", "grass_clump_b", "grass_clump_c", "grass_clump_d", "tall_grass"]
FLOWERS = ["wildflowers_a", "wildflowers_b", "myosotis_b"]


def pascal(text):
    return "".join(part.capitalize() for part in text.split("_"))


def ground_plan(m):
    """Le sol : le plan (trois terrasses à +2, +1 et 0, pavés, dalles, jardins) ; les volées de la grand-rue en
    vrais escaliers ; les faces des paliers en muret de pierre ; pas de chemin de terre (tout est pavé)."""
    # Pavés et dalles de la ville : les matières « chemin » de la bibliothèque interdisent une marche de plus de
    # 0,5 m ; ici les terrasses en ont de 1 m (les escaliers sont les seuls passages, les murets font le reste).
    saved = dict(exterior_ground.SOL)
    exterior_ground.SOL.update({"cobble": "paves_v", "flagstone": "dalles_v", "cobble_b": "paves_vb"})
    try:
        plan = exterior_ground.ground_from_plan(
            m, noise=0.25, ramp_material="dalles_v",
            comment="Sol en relief de la ville haute (lot CV), d'après docs/lore/CARTE.md, section 9.2 : trois "
                    "terrasses (+2, +1, 0), grand-rue de dalles et ruelles pavées, deux volées d'escalier, faces en "
                    "muret. Lu par tools/map_build.py gen ville_haute ; le jeu ne lit pas ce fichier.")
    finally:
        exterior_ground.SOL.clear()
        exterior_ground.SOL.update(saved)
    plan["materials"].update({
        "paves_v": {"label": "Pavés de la ville (cobble)", "layer": "cobble", "color": "#7c7c86", "variant": False},
        "paves_vb": {"label": "Pavés des ruelles (cobble_b)", "layer": "cobble_b", "color": "#8a8070",
                     "variant": False},
        "dalles_v": {"label": "Dalles de la grand-rue (flagstone)", "layer": "flagstone", "color": "#b0b0a8",
                     "variant": False},
    })
    plan["base"]["material"] = "paves_v"
    steps = plan["steps"]
    # Au nord, derrière les maisons : le sous-bois de la lisière, puis l'herbe (le plan pave toute la carte ; on ne
    # voit ce sol que dans l'entre-deux des maisons et au pied du muret de la fontaine).
    first = exterior_ground.step_index(steps, "ramp")
    steps[first:first] = [
        {"op": "material", "material": "herbe",
         "shape": {"rect": [0, 4, int(m.w), 6], "noise": 0.5, "noise_scale": 2.0, "seed": 7}},
        {"op": "material", "material": "sous_bois",
         "shape": {"rect": [0, 0, int(m.w), 4.5], "noise": 0.6, "noise_scale": 2.0, "seed": 8}},
    ]
    steps[:] = [s for s in steps if s["op"] != "path"]
    for s in steps:
        if s["op"] == "ramp":
            s["op"] = "stairs"
    face = exterior_ground.step_index(steps, "face")
    steps.insert(face + 1, {"op": "face", "face": "wall", "shape": {"rect": [0, 0, int(m.w), int(m.d)]}})
    return plan


def prepare(p):
    # Les jardins clos et les bords du plan sont déjà des `bord`. Le haut de la grand-rue, au nord, est fermé par le
    # muret de la fontaine (x 23 → 37) : rien n'y passe.
    p.edges.append(Rect(23.0, 4.0, 37.0, 9.9))
    # Les bandes de 1 à 2 m entre les jardins clos et le pied des maisons derrière eux : le plan les laisse libres, un
    # toit de 6 m y cacherait le joueur (CARTE.md 0.3) ; on les ferme (écart au plan).
    p.edges.append(Rect(4.0, 24.0, 26.0, 25.0))
    p.edges.append(Rect(9.5, 44.0, 16.0, 46.0))
    p.edges.append(Rect(17.5, 4.0, 24.0, 4.95))
    # Les cours de l'est, vues à travers le toit de la maison voisine par la caméra, bornée à x 50.
    p.edges.append(Rect(52.0, 25.0, 56.5, 29.5))
    p.edges.append(Rect(52.5, 46.0, 56.5, 51.0))
    p.edges.append(Rect(52.5, 4.0, 56.5, 10.0))


def pose(p):
    M, W, D = p.map, p.W, p.D
    rng = p.rng
    place, scatter = p.place, p.scatter
    in_map, outside_edges = p.in_map, p.outside_edges
    free, height, walk_grid = p.free, p.height, p.walk_grid
    PATHS = p.paths
    BUILDINGS = p.buildings

    walk_grid()

    # === 1. Ossature du plan (9.2) ======================================================================

    for b in M.buildings:
        cx, cz = (b.rect.x0 + b.rect.x1) / 2.0, (b.rect.z0 + b.rect.z1) / 2.0
        place("Houses", b.extra["img"], cx, cz, name=pascal(b.name), check=False)

    for d in M.decors:
        x, z = (d.rect.x0 + d.rect.x1) / 2.0, (d.rect.z0 + d.rect.z1) / 2.0
        n = d.name
        if n in ("hanging_sign_pan", "hanging_sign_cup"):
            place("Facade", n, x, z, y=height(x, z) + 1.0, name=pascal(n), check=False)
        elif n == "street_lamp_double":
            place("Street", "street_lamp_double_fg", x, z, name="Reverbere", check=False)
        elif n in ("town_planter_stone", "town_wall_fountain"):
            place("Street", n, x, z, name=pascal(n), check=False)
        elif n == "bench_stone":
            place("Street", n, x, z, name="BancHaut", check=False)
        elif n in ("town_doorsteps", "town_cellar_hatch"):
            place("Facade", n, x, z, name=pascal(n), check=False)
        elif n == "crate_apples":
            place("Street", n, x, z, name="CaissesPommes", check=False)
        elif n == "wall_lantern":
            place("Facade", n, x, 9.7, y=height(x, 9.7) + 0.8, name="LanterneHaut", check=False)
        else:
            p.warnings.append("décor du plan non posé : %s" % n)

    # Le muret qui ferme le haut de la grand-rue (la fontaine murale et la lanterne s'y adossent).
    for k, x in enumerate((24.0, 26.0, 28.0, 30.0, 32.0, 34.0, 36.0)):
        place("Edge", "town_wall_low", x, 9.4, name="MuretHaut%d" % (k + 1), flip=k % 2 == 1, check=False)
    walk_grid()
    # Derrière le muret, le jardin qu'il ferme (le bois en arrière-plan) : des arbres d'or, des buissons, des fleurs.
    for k, (x, z, scene) in enumerate(((25.5, 6.6, "tree_autumn_yellow"), (31.0, 5.6, "maple_b"), (35.2, 7.0, "tree_autumn_rust"),
                                       (28.4, 8.2, "sapling_a"), (33.2, 8.4, "sapling_b"))):
        place("Garden", scene, x, z, name="ArbreJardinHaut%d" % (k + 1), check=False)
    pocket = poisson(Rect(23.8, 5.0, 36.2, 8.9), 1.3, 22, lambda x, z: True, seed=96)
    scatter("JardinHaut", BUSHES[:5] + FLOWERS + ["heather", "grass_clump_c"], pocket, seed=97, check=False)
    place("Garden", "bench", 30.0, 8.9, name="BancJardinHaut", check=False)

    # Maisons du bord de la carte (les `bord maisons` du plan) : des façades qu'on voit de loin, de part et d'autre.
    for k, (scene, x, z) in enumerate((("town_house_c", 2.0, 7.5), ("town_house_c", 58.0, 7.0),
                                       ("town_house_f", 57.0, 13.2), ("town_house_c", 2.0, 38.5),
                                       ("shop_accessories", 2.0, 44.5), ("town_house_c", 2.0, 51.0),
                                       ("town_house_c", 58.0, 38.0), ("shop_apothecary", 58.0, 44.0),
                                       ("town_house_c", 58.0, 50.5), ("town_house_c", 2.0, 57.0),
                                       ("shop_accessories", 58.0, 57.0))):
        place("Houses", scene, x, z, name="MaisonBord%d" % (k + 1), check=False)

    # === 2. La lisière au nord et les toits au-delà (9.2, « vue au nord ») ===============================

    for k, (x, scene) in enumerate(((8.0, "forest_wall_c"), (24.0, "forest_wall_a"), (40.0, "forest_wall_b"),
                                    (56.0, "forest_wall_c"))):
        place("Woods", scene, x, 2.4, y=2.0, name="LisiereBois%d" % (k + 1), flip=k % 2 == 1, check=False)
    for k, (x, scene) in enumerate(((10.0, "town_roofs_a"), (26.0, "town_roofs_b"), (42.0, "town_roofs_a"),
                                    (58.0, "town_roofs_b"))):
        place("Sky", scene, x, -5.5, y=5.0, name="ToitsLointains%d" % (k + 1), flip=k % 2 == 1, check=False)
    row = []
    x = 2.0
    while x < W - 1:
        row.append((x + rng.uniform(-0.6, 0.6), rng.uniform(1.4, 3.0)))
        x += rng.uniform(3.4, 5.0)
    for k, (x, z) in enumerate(row):
        place("Woods", (TREES_GOLD + TREES_RUST)[k % 12] + "_forest", x, z, y=2.0, name="ArbreLisiere%d" % (k + 1), check=False)

    # === 3. La rue haute (terrasse +2) ====================================================================

    place("Street", "barrel_group", 5.6, 10.3, name="TonneauxOuest")
    place("Street", "crate_stack", 8.4, 10.2, name="CaissesOuest")
    place("Street", "rain_barrel", 11.0, 10.2, name="TonneauMaisonHaute")
    place("Street", "flower_pots", 13.4, 10.4, name="PotsMaisonHaute", check=False)
    place("Street", "flower_pots", 17.0, 10.4, name="PotsMaisonHaute2", flip=True, check=False)
    place("Street", "planter_long", 19.6, 10.4, name="BacEtroite")
    place("Street", "bucket", 22.6, 10.3, name="SeauEtroite", check=False)
    place("Street", "flower_pots", 36.9, 10.4, name="PotsMaisonA", check=False)
    place("Street", "sack_apples", 40.2, 10.3, name="SacsMaisonA", check=False)
    place("Street", "barrel_group", 42.4, 10.3, name="TonneauxMaisonB")
    place("Street", "hand_cart", 51.2, 10.5, name="CharretteEst")
    place("Street", "flower_pots", 49.6, 10.4, name="PotsMaisonB", flip=True, check=False)
    place("Facade", "ivy_wall_a", 13.0, 9.55, y=height(13.0, 9.6), name="LierreMaisonHaute", check=False)
    place("Facade", "ivy_wall_b", 44.5, 9.55, y=height(44.5, 9.6) + 0.3, name="LierreMaisonB", flip=True, check=False)
    place("Facade", "drainpipe", 18.15, 9.7, y=height(18.2, 9.7), name="DescenteHaute", check=False)
    place("Facade", "drainpipe", 41.5, 9.7, y=height(41.5, 9.7), name="DescenteMaisonA", check=False)
    # Le garde-corps au bord de la terrasse haute (le plan en parle : « garde-corps `town_railing` au bord des
    # terrasses »), sauf devant les marches de la grand-rue.
    for k, x in enumerate([5.0 + 2.0 * i for i in range(10)] + [35.0 + 2.0 * i for i in range(11) if i != 5]):
        place("Edge", "town_railing", x, 15.55, name="GardeCorpsHaut%d" % (k + 1), flip=k % 2 == 1, check=False)
    # Le linge d'une fenêtre à l'autre, la guirlande de la rue haute.
    place("Roof", "bunting_wave", 14.0, 11.6, y=height(14.0, 11.6) + 3.0, name="GuirlandeHaute", check=False)
    place("Roof", "bunting_wave", 44.0, 11.6, y=height(44.0, 11.6) + 3.0, name="GuirlandeEst", flip=True, check=False)
    for k, (cx, cz, ridge, scene) in enumerate(((15.0, 7.0, 9.4, "chimney_stone"), (38.5, 7.0, 8.4, "chimney_stone"),
                                                (46.0, 7.5, 7.9, "chimney_brick"))):
        place("Roof", scene, cx, cz, y=2.0 + ridge - 0.5, name="CheminéeHaute%d" % (k + 1), check=False)
        place("Roof", "chimney_smoke", cx, cz, y=2.0 + ridge + 1.3, name="FuméeHaute%d" % (k + 1), check=False)

    # === 4. La rue du café (terrasse +1) ====================================================================

    place("Street", "book_cart", 11.4, 31.0, name="ChariotLivres")
    place("Street", "flower_pots", 16.3, 30.5, name="PotsLibrairie", check=False)
    place("Street", "menu_slate", 23.4, 30.6, name="ArdoiseCafe")
    place("Street", "flower_pots", 24.4, 30.5, name="PotsCafe", flip=True, check=False)
    place("Street", "bench_stone", 34.6, 31.0, name="BancCarrefour", check=False)
    place("Street", "barrel_group", 40.8, 30.45, name="TonneauxSnack")
    place("Street", "bread_rack", 41.7, 30.55, name="ChevaletAccessoires")
    place("Street", "flower_pots", 46.6, 30.5, name="PotsMaisonF", check=False)
    place("Street", "rain_barrel", 51.6, 30.6, name="TonneauMaisonF")
    place("Street", "crate_stack", 7.5, 31.0, name="CaissesOuest2")
    place("Street", "planter_long", 53.0, 30.9, name="BacEst2")
    place("Facade", "town_doorsteps", 14.5, 30.3, name="MarchesLibrairie", check=False)
    place("Facade", "town_doorsteps", 21.5, 30.3, name="MarchesCafe", check=False)
    place("Facade", "town_doorsteps", 49.0, 30.3, name="MarchesMaisonF", check=False)
    place("Facade", "awning_green", 43.0, 30.45, y=height(43.0, 30.4) + 2.6, name="AuventAccessoires", check=False)
    for k, (cx, cz, ridge, scene) in enumerate(((21.5, 27.0, 6.0, "chimney_stone"), (49.0, 27.5, 5.6, "chimney_brick"))):
        place("Roof", scene, cx, cz, y=1.0 + ridge - 0.5, name="CheminéeCafé%d" % (k + 1), check=False)
        place("Roof", "chimney_smoke", cx, cz, y=1.0 + ridge + 1.3, name="FuméeCafé%d" % (k + 1), check=False)
    # Le bord de la terrasse du milieu, au sud : garde-corps de fer, sauf devant les marches.
    for k, x in enumerate([5.0 + 2.0 * i for i in range(10)] + [35.0 + 2.0 * i for i in range(11)]):
        place("Edge", "town_railing", x, 33.85, name="GardeCorpsCafé%d" % (k + 1), flip=k % 2 == 0, check=False)

    # === 5. La grand-rue, le bas de la ville et la rue basse =============================================

    place("Street", "bench_stone", 25.0, 23.0, name="BancGrandRue", check=False)
    place("Street", "planter_long", 35.2, 23.0, name="BacGrandRue")
    place("Street", "rain_barrel", 25.0, 29.0, name="TonneauGrandRue")
    place("Street", "planter_long", 38.2, 54.0, name="BacBas")
    place("Street", "flower_pots", 25.0, 54.0, name="PotsBas", check=False)
    place("Street", "barrel_group", 6.5, 54.0, name="TonneauxBas")
    place("Street", "crate_stack", 52.0, 53.5, name="CaissesBas")
    place("Street", "flower_pots", 12.4, 52.2, name="PotsApothicaire", check=False)
    place("Street", "flower_pots", 49.8, 52.0, name="PotsMaisonD", flip=True, check=False)
    place("Street", "barrel_group", 21.5, 52.4, name="TonneauxProjection")
    place("Street", "bench_stone", 38.5, 52.2, name="BancColombages", check=False)
    place("Facade", "town_doorsteps", 19.5, 51.3, name="MarchesProjection", check=False)
    place("Facade", "town_doorsteps", 13.0, 51.3, name="MarchesApothicaire", check=False)
    place("Facade", "town_doorsteps", 44.0, 51.3, name="MarchesMaisonC", check=False)
    for k, (cx, cz, ridge, scene) in enumerate(((20.0, 47.5, 7.5, "chimney_stone"), (44.0, 48.5, 7.4, "chimney_stone"),
                                                (50.0, 48.5, 6.8, "chimney_brick"))):
        place("Roof", scene, cx, cz, y=ridge - 0.5, name="CheminéeBasse%d" % (k + 1), check=False)
        place("Roof", "chimney_smoke", cx, cz, y=ridge + 1.3, name="FuméeBasse%d" % (k + 1), check=False)
    # Le bord sud, au premier plan : un muret bas, sauf devant la sortie de la grand-rue.
    for k, x in enumerate([5.0 + 2.0 * i for i in range(10)] + [37.0 + 2.0 * i for i in range(10)]):
        place("Edge", "town_wall_low", x, 59.3, name="MuretSud%d" % (k + 1), flip=k % 2 == 1, check=False)

    # === 6. Les jardins clos derrière les rangées (le plan : « jamais un endroit où l'on marche ») =========

    gardens = [(4.0, 16.0, 26.0, 24.0), (34.0, 16.0, 56.0, 25.0), (4.0, 34.0, 26.0, 44.0), (34.0, 34.0, 56.0, 46.0)]
    for gi, (x0, z0, x1, z1) in enumerate(gardens):
        place("Garden", "garden_bed", (x0 + x1) / 2.0 + rng.uniform(-3, 3), z0 + (z1 - z0) * 0.55, name="PlateBande%d" % (gi + 1), check=False)
        count = int((x1 - x0) / 2.0)
        for k in range(count):
            place("Garden", "fence_wattle", x0 + 1.0 + k * 2.0, z1 - 0.4 if z0 > 30 else z1 - 0.3, name="Clôture%d_%d" % (gi + 1, k + 1),
                  flip=k % 2 == 1, check=False)
        pts = poisson(Rect(x0 + 1.0, z0 + 0.8, x1 - 1.0, z1 - 1.6), 4.2, 7, lambda x, z: True, seed=60 + gi)
        # Des jeunes arbres : un grand arbre au sud de la rue haute ou de la rue du café couvrirait le bas de l'écran.
        scatter("Garden%dTrees" % (gi + 1), ["sapling_a", "sapling_b", "berry_bush", "berry_bush_b", "thicket_c"], pts,
                seed=61 + gi, check=False)
        low = poisson(Rect(x0 + 0.6, z0 + 0.6, x1 - 0.6, z1 - 0.8), 1.6, 26, lambda x, z: True, seed=70 + gi)
        scatter("Garden%dLow" % (gi + 1), BUSHES[:6] + FLOWERS + ["vegetable_patch", "grass_clump_a"], low, seed=71 + gi, check=False)

    # === 7. Les bords est et ouest (les `bord jardins` et `bord maisons` du plan) ==========================

    for k, z in enumerate((17.5, 21.0, 24.5, 28.0, 31.0)):
        place("Edge", "thicket_a_fg" if k % 2 else "thicket_b_fg", 1.6, z, name="HaieOuest%d" % (k + 1), check=False)
        place("Edge", "thicket_b_fg" if k % 2 else "thicket_a_fg", 58.4, z, name="HaieEst%d" % (k + 1), check=False)
    for k, (x, z, scene) in enumerate(((2.0, 24.0, "tree_autumn_yellow_forest"), (58.0, 22.0, "maple_a_forest"),
                                       (58.0, 28.0, "beech_b_forest"), (1.6, 19.5, "oak_b_forest"))):
        place("Woods", scene, x, z, name="ArbreBord%d" % (k + 1), check=False)

    # === 8. Le sol et les petits détails (kits « rues », « façades ») =====================================

    for k, (x, z, scene) in enumerate(((9.0, 12.2, "drain_grate"), (24.0, 14.6, "drain_grate"), (46.0, 13.0, "drain_grate"),
                                       (30.0, 29.0, "drain_grate"), (12.0, 32.6, "drain_grate"), (48.0, 32.0, "drain_grate"),
                                       (30.0, 44.0, "drain_grate"), (30.0, 55.0, "drain_grate"), (14.0, 55.5, "puddle_a"),
                                       (44.0, 33.0, "puddle_b"), (36.0, 12.6, "leaves_rust_a"), (16.0, 14.4, "leaves_gold_b"),
                                       (8.0, 32.4, "leaves_gold_a"), (40.0, 54.6, "leaves_rust_b"), (30.0, 20.0, "leaves_gold_a"),
                                       (28.5, 38.0, "leaves_rust_a"), (6.0, 55.0, "leaves_gold_b"), (52.0, 55.4, "leaves_rust_a"))):
        place("Street", scene, x, z, name="RueDecal%d" % (k + 1), flip=k % 2 == 1, check=False)
    foot = []
    for x0, x1, z in ((4.0, 56.0, 10.1), (6.0, 54.0, 30.2), (6.0, 54.0, 51.1)):
        x = x0
        while x < x1:
            foot.append((x + rng.uniform(-0.3, 0.3), z + rng.uniform(0.0, 0.5)))
            x += rng.uniform(1.5, 2.6)
    foot = [q for q in foot if free()(q[0], q[1]) and outside_edges(q[0], q[1], 0.2)]
    scatter("FacadeFoot", ["grass_clump_d", "wildflowers_b", "heather", "myosotis_b", "grass_clump_b"], foot, seed=18,
            check=False)
    borders = []
    for name, width, pts in PATHS:
        if name in ("rue_haute", "rue_du_cafe", "rue_basse"):
            borders += along(pts, 3.4, width / 2.0 + 0.1, 0.1, seed=64 + len(borders), with_yaw=True)
    borders = [q for q in borders if in_map(q[0], q[1], 0.5) and outside_edges(q[0], q[1], 0.2)
               and not any(b.has(q[0], q[1], 0.2) for b in BUILDINGS)]
    scatter("StreetEdges", ["grass_edge_a", "grass_edge_b"], borders[::2], scale=(0.9, 1.1), seed=65, check=False)
    # Les cours latérales, de part et d'autre des rangées (le plan les laisse ouvertes) : un puits, des bûches, des
    # caisses, des tonneaux, de jeunes arbres ; jamais plus de 6 × 6 m de sol nu.
    yards = [(4.0, 4.5, 12.0, 9.8), (50.0, 4.5, 56.0, 9.8), (4.0, 25.2, 12.0, 29.8), (52.5, 25.2, 56.0, 29.8),
             (4.0, 46.2, 10.0, 51.0), (53.5, 46.2, 56.0, 51.0)]
    place("Street", "flower_bed", 6.4, 6.6, name="PlatebandeOuest", check=False)
    place("Street", "firewood_pile_front", 10.2, 5.6, name="BuchesOuest", check=False)
    place("Street", "wheelbarrow", 8.6, 8.8, name="BrouetteOuest", check=False)
    place("Street", "laundry_basket", 53.0, 8.4, name="PanierLinge", check=False)
    for yi, (x0, z0, x1, z1) in enumerate(yards):
        pts = poisson(Rect(x0, z0, x1, z1), 1.9, 7, free(), seed=90 + yi)
        scatter("Yard%d" % (yi + 1), ["crate_stack", "barrel_group", "rain_barrel", "sapling_b", "bush_c", "flower_bed",
                                       "hay_scatter", "log_pile_forest"], pts, seed=91 + yi, check=False)
    for k, (x, z, scene) in enumerate(((28.0, 56.2, "pebbles_a"), (33.0, 54.0, "leaves_gold_a"),
                                       (26.5, 53.4, "footprints"), (31.0, 57.2, "puddle_a"), (34.5, 56.6, "leaves_rust_b"),
                                       (27.0, 57.4, "pebbles_b"))):
        place("Street", scene, x, z, name="BasDecal%d" % (k + 1), flip=k % 2 == 0, check=False)
    # Le long de la grand-rue (8 m de large entre les façades et les jardins) : des feuilles, des cailloux, une grille
    # d'égout, de part et d'autre de la bande qu'on suit, tous les 5 m (pas de sol nu de 6 × 6 m).
    cycle = ["leaves_gold_a", "pebbles_a", "leaves_rust_a", "moss_patch_a", "pebbles_b", "leaves_gold_b", "roots_a"]
    for k, z in enumerate(range(13, 59, 5)):
        for side, x in enumerate((26.8, 33.2)):
            place("Street", cycle[(k + side) % len(cycle)], x, z + (side * 2.5) % 4, name="GrandRueDecal%d_%d" % (k + 1, side),
                  flip=(k + side) % 2 == 1, check=False)
    place("Street", "pigeons", 29.0, 32.6, name="Pigeons1", check=False)
    place("Street", "pigeons", 20.0, 54.6, name="Pigeons2", flip=True, check=False)


def ambient(p):
    """Vie ambiante : des oiseaux qui traversent, des feuilles d'automne qui tombent (la ville est sans animaux, VIE.md :
    pas de gibier ; les passants sont ceux de V2)."""
    return [
        ("Birds", "birds_flock", 6, 10, 1, 3, (40, 6, 24), 6.0, (0, 0), 4.0, 0.8, 3, (30, 0, 30)),
        ("LeavesGold", "falling_leaf_gold", 8, 10, 0, 8, (30, 9, 30), 0.0, (0, 0), 0.9, 0.8, 4, (30, 0, 30)),
        ("LeavesRust", "falling_leaf_rust", 8, 10, 0, 8, (30, 9, 30), 0.0, (0, 0), 1.1, 0.8, 5, (30, 0, 30)),
    ]
