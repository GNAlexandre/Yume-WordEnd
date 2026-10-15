"""(C3b) Le relief de la colline des étoiles : des contours irréguliers, pas des rectangles.

Le sol est une grille de cases d'un mètre à paliers de 0,5 m (PLAN.md, « Format du sol des cartes
extérieures ») : le relief se dessine donc en contours (polygones à bord bruité) posés du plus bas au
plus haut, plus des rampes (volées de cases) qui relient deux cases plates de même hauteur.

Hauteurs : pied 0 ; terrasse basse +1 m ; terrasse haute +2,5 m (falaise de 1,5 m) ; sommet +3,5 m
(falaise de 1 m) ; sur les flancs ouest et est la pente se défait en marches de 0,5 m (talus de
terre, +1,5 puis +2 m). Les faces (talus de terre jusqu'à 0,5 m, roche au-delà) se déduisent des
hauteurs : le moteur n'a pas besoin d'autre réglage.
"""

import math

import exterior_ground

# Paliers de 0,5 m : +1 m, +2,5 m, +3,5 m.
LEVEL_LOW, LEVEL_MID, LEVEL_HIGH = 2, 5, 7
# Contours (x, z) ; le nord est prolongé au-delà de la côte (le vide les recoupe).
LOW_TERRACE = [(6.0, 16.0), (33.0, 16.0), (35.8, 23), (37.2, 28.5), (34, 32.4), (30.5, 33.6), (27, 31.8),
               (22.5, 33.2), (18, 32.2), (14, 33.8), (9.5, 32.0), (6.5, 33.4), (3.6, 31.0), (3.1, 25), (5.0, 19.5)]
MID_TERRACE = [(3.8, -3), (36.6, -3), (36.8, 8), (36.6, 13.5), (36.8, 19), (36.4, 24.6), (31.6, 27.4), (28.4, 25.8),
               (24.6, 27.6), (20.8, 26.0), (17.0, 28.0), (13.0, 26.2), (9.2, 28.0), (6.4, 25.4), (3.8, 19.5),
               (3.6, 13), (3.8, 7)]
SUMMIT = [(8.6, -3), (30.8, -3), (31.6, 6), (31.0, 12), (31.6, 16.5), (30.0, 19.8), (27.6, 20.8), (24.2, 19.8),
          (20.2, 21.6), (16.6, 20.2), (12.4, 21.8), (9.2, 19.6), (7.8, 15.8), (7.6, 11), (8.2, 6)]
# Marches de 0,5 m de la pente ouest et est (talus de terre) : de la terrasse basse à la haute.
STEPS_WEST = [([(5.6, 19), (10.0, 20.5), (12.8, 24.0), (12.6, 26.6), (9.2, 27.6), (5.6, 27.8), (4.0, 30.4), (4.2, 22)], 3)]
STEPS_EAST = [([(33.5, 21), (30.5, 23.5), (29.2, 29.0), (33.2, 30.8), (36.4, 29.5), (36.4, 22)], 3)]
# Les rampes : ((x, z, largeur, profondeur) en cases, palier du bas, palier du haut). Montée vers le nord.
# Larges et longues (11 à 14° de pente) : le plan d'origine les faisait de 4 sur 3 ou 4 cases.
RAMPS = [((10, 30, 5, 4), 0, LEVEL_LOW), ((23, 24, 5, 6), LEVEL_LOW, LEVEL_MID), ((14, 19, 5, 5), LEVEL_MID, LEVEL_HIGH)]
# Pans de roche des faces : (palier de la case haute, x de, x à). Les autres faces sont en talus de terre.
ROCK_FACES = [(LEVEL_MID, 5, 13.5), (LEVEL_MID, 18, 26.5), (LEVEL_MID, 31, 36), (LEVEL_HIGH, 14, 21.5),
              (LEVEL_HIGH, 26, 31.5), (LEVEL_LOW, 17, 27)]
# Le cercle des talismans : le bord du cercle (anneau de dalles de roche, à bord rompu), centre et rayon.
RING = (20.0, 12.0, 6.15)
# La côte : un cap arrondi, plus avancé au centre qu'aux épaules.
COAST = [(-3, -3), (43, -3), (43, 9.0), (38, 8.4), (36.0, 7.0), (33.5, 5.2), (31, 4.0), (28.2, 3.5), (25.0, 2.7),
         (22.0, 3.2), (19.5, 2.2), (16.5, 2.9), (13.6, 2.4), (11.0, 3.8), (8.6, 4.6), (6.2, 6.2), (4.0, 7.8),
         (-3, 8.6)]


def ground_plan(m):
    """Le sol : le plan donne l'ossature (matières, chemin) ; le relief est dessiné ici en contours."""
    plan = exterior_ground.ground_from_plan(
        m, noise=0.8, ramp_material="herbe", skip=("path_dirt_b",),
        comment="Sol en relief de la colline des étoiles (lots C3 et C3b), d'après docs/lore/CARTE.md, section 7 : "
                "des terrasses aux contours irréguliers (+1, +2,5 puis +3,5 m, des marches de 0,5 m sur les flancs), "
                "trois rampes larges, le sommet à 3,5 m, le cap qui finit sur le vide (la mer de nuages), le chemin "
                "qui zigzague. Lu par tools/map_build.py gen colline ; le jeu ne lit pas ce fichier.")
    plan["edges"]["north"] = "void"
    path_steps = [s for s in plan["steps"] if s["op"] == "path"]
    for s in path_steps:
        s["noise"] = 0.0
    steps = []

    def level(poly, lv, seed, noise=0.55):
        steps.append({"op": "level", "level": lv, "shape": {"poly": [list(q) for q in poly], "noise": noise,
                                                            "noise_scale": 3.4, "seed": seed}})

    def material(shape, name, seed, noise=0.9, scale=2.2, where=None):
        step = {"op": "material", "material": name, "shape": dict(shape, noise=noise, noise_scale=scale, seed=seed)}
        if where:
            step["where"] = where
        steps.append(step)

    level(LOW_TERRACE, LEVEL_LOW, 21)
    for poly, lv in STEPS_WEST:
        level(poly, lv, 30 + lv)
    for poly, lv in STEPS_EAST:
        level(poly, lv, 40 + lv)
    level(MID_TERRACE, LEVEL_MID, 23)
    level(SUMMIT, LEVEL_HIGH, 24, noise=0.6)
    # Un replat de 0,5 m au pied, de chaque côté de l'entrée (le sol de la forêt n'est pas plat).
    level([(0, 29), (8.5, 32.6), (9.4, 37.4), (4.6, 39), (0, 37)], 1, 51, noise=0.5)
    level([(40, 30), (31.8, 33.6), (30.4, 38.2), (35.2, 39.4), (40, 37.6)], 1, 52, noise=0.5)
    # Les aplombs des rampes : une bande plate en bas, une en haut, pour que chaque colonne de la volée
    # relie deux cases plates de même hauteur.
    for (x, z, w, d), low, high in RAMPS:
        steps.append({"op": "level", "level": low, "shape": {"rect": [x, z + d, w, 1]}})
        steps.append({"op": "level", "level": high, "shape": {"rect": [x, z - 1, w, 1]}})
    # Les faces : du talus de terre partout (le moteur met de la roche au-delà de 0,5 m si rien n'est imposé ; ici
    # on impose la terre, plus naturelle sur une colline d'herbe), de la roche par pans, de longueur et de place
    # différentes d'une terrasse à l'autre : jamais une longue ligne d'un seul style.
    steps.append({"op": "face", "face": "earth", "shape": {"rect": [0, 0, 40, 40]}})
    for k, (lv, x0, x1) in enumerate(ROCK_FACES):
        steps.append({"op": "face", "face": "rock", "where": {"level": lv},
                      "shape": {"rect": [x0, 0, x1 - x0, 40], "noise": 0.9, "noise_scale": 2.2, "seed": 140 + k}})
    # Le vide : le cap finit sur une côte irrégulière.
    steps.append({"op": "void", "shape": {"poly": [list(q) for q in COAST], "noise": 0.5, "noise_scale": 2.5,
                                          "seed": 3}})
    # Les matières : de l'herbe, de l'herbe haute en nappes, des fleurs en bouquets, de la roche au bord des
    # falaises, du sous-bois et des feuilles aux flancs et au pied.
    material({"rect": [0, 0, 40, 40]}, "herbe", 1, noise=0.0)
    material({"poly": [list(q) for q in SUMMIT]}, "herbe_haute", 61, noise=2.4, scale=3.4)
    material({"ellipse": [20, 12, 6.6, 6.6]}, "herbe", 62, noise=0.8, scale=2.4)
    material({"ellipse": [20, 12, 7.6, 7.6]}, "prairie", 63, noise=1.2, scale=2.0, where={"material": "herbe_haute"})
    for k, (cx, cz, rx, rz) in enumerate(((10.5, 8.5, 2.6, 2.0), (30.5, 15.5, 2.8, 2.2), (26.5, 6.0, 2.2, 1.4),
                                          (12.0, 17.0, 2.0, 1.6), (22.5, 17.8, 3.0, 1.2))):
        material({"ellipse": [cx, cz, rx, rz]}, "prairie", 70 + k, noise=1.0, scale=1.8, where={"level": LEVEL_HIGH})
    for k, (cx, cz, rx, rz) in enumerate(((12, 24, 3.2, 1.4), (30, 22.8, 3.4, 1.6), (21, 24, 2.4, 1.0),
                                          (9, 30, 3.0, 1.6), (33, 30, 2.6, 1.8))):
        material({"ellipse": [cx, cz, rx, rz]}, "herbe_haute", 80 + k, noise=1.2, scale=2.2)
    for k, (cx, cz, rx, rz) in enumerate(((16, 25.2, 2.4, 1.0), (28, 31.0, 2.2, 1.0), (19, 30.6, 2.0, 1.0),
                                          (8, 22, 2.0, 1.2), (31.5, 17.5, 1.6, 1.2))):
        material({"ellipse": [cx, cz, rx, rz]}, "prairie", 90 + k, noise=1.0, scale=1.8)
    # La roche à nu au pied des grands rochers et le long du bord.
    for k, (cx, cz, rx, rz) in enumerate(((9.6, 14.5, 2.6, 1.6), (33.0, 22.0, 1.8, 1.2), (28.0, 8.0, 1.6, 1.0),
                                          (13.0, 4.6, 2.2, 0.9), (27.0, 4.0, 2.2, 0.9))):
        material({"ellipse": [cx, cz, rx, rz]}, "roche", 100 + k, noise=0.8, scale=1.6)
    material({"ellipse": [8.4, 9.0, 1.8, 1.2]}, "mousse", 110, noise=0.8, scale=1.6)
    material({"ellipse": [30, 12.5, 4.5, 3.0]}, "mousse", 111, noise=1.4, scale=2.0, where={"material": "herbe_haute"})
    material({"rect": [-1, 3, 5.4, 38]}, "sous_bois", 11, noise=1.4, scale=2.6)
    material({"rect": [34.6, 3, 6.8, 38]}, "sous_bois", 12, noise=1.4, scale=2.6)
    material({"rect": [0, 33.4, 40, 7]}, "sous_bois", 13, noise=1.2, scale=2.8, where={"level": 0})
    for k, (cx, cz, rx, rz) in enumerate(((3.2, 26, 2.2, 3.0), (36.5, 14, 2.0, 2.6), (30.0, 36.0, 3.0, 1.4),
                                          (9.0, 36.0, 3.2, 1.3), (7.0, 33.8, 1.8, 1.0), (33.5, 34.0, 1.8, 1.0))):
        material({"ellipse": [cx, cz, rx, rz]}, "feuilles", 120 + k, noise=0.7, scale=1.6)
    # Le cercle des talismans, dessiné au sol : un anneau de dalles rompu par endroits.
    cx, cz, r = RING
    ring = [[round(cx + r * math.cos(math.radians(a)), 2), round(cz + r * math.sin(math.radians(a)), 2)]
            for a in range(0, 361, 15)]
    steps.append({"op": "material", "material": "roche",
                  "shape": {"band": ring, "width": 0.8, "noise": 0.55, "noise_scale": 1.3, "seed": 150}})
    # Les rampes, puis le chemin par-dessus.
    for (x, z, w, d), _low, _high in RAMPS:
        steps.append({"op": "ramp", "dir": "north", "rect": [x, z, w, d], "material": "herbe"})
    steps += path_steps
    plan["steps"] = steps
    return plan
