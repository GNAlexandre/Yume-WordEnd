"""(C1) Le sol des cartes du dehors, déduit du plan de docs/lore/CARTE.md : `ground_from_plan` rend le
plan.json que tools/map_build.py gen transforme en images (data/maps/<id>/, format : PLAN.md,
« Format du sol des cartes extérieures »). Une recette y ajoute ce que le plan ne dit pas (berges
bruitées, ellipses de matière, rampes en plus) en modifiant la liste `steps`.
"""

# Matières du plan (tuiles de l'atlas : CARTE.md 0.1) → matières du sol (data/maps/ground_materials.json,
# ou propres à la carte : MY_MATERIALS).
SOL = {
    "grass": "herbe", "grass_b": "herbe_drue", "grass_dry": "herbe_haute", "forest_floor": "sous_bois",
    "forest_floor_b": "sous_bois", "leaf_litter": "feuilles", "moss": "mousse", "path_dirt": "terre_battue",
    "path_dirt_b": "chemin", "path_overgrown": "chemin", "peat": "tourbe", "meadow_flowers": "prairie",
    "garden_soil": "potager", "stream_bed": "lit_ruisseau", "flagstone": "dalles", "cobble": "paves",
    "sand": "sable", "rock": "roche", "mud": "boue", "gravel": "gravier", "planks": "planches", "metal": "tole",
    "water": "eau",
}
MY_MATERIALS = {
    "herbe_drue": {"label": "Herbe drue et molle (grass_b)", "layer": "grass_b", "color": "#4f9a46",
                   "variant": False},
    "chemin": {"label": "Chemin de terre (path_dirt_b)", "layer": "path_dirt_b", "color": "#d0a060",
               "variant": False, "path": True},
    "eau_basse": {"label": "Eau basse du marais : on y marche (VEX)", "layer": "water", "color": "#3a70b0",
                  "walkable": True, "ripple": True, "tint": [0.78, 0.86, 0.8]},
}
OPPOSITE = {"north": "south", "south": "north", "east": "west", "west": "east"}
GOING = {"N": "north", "S": "south", "E": "east", "O": "west"}


def rect_of(r):
    return [r.x0, r.z0, r.x1 - r.x0, r.z1 - r.z0]


def ground_from_plan(m, seed=68, scale=2, comment="", noise=0.0, skip=(), path_material="chemin",
                     path_inset=1.2, path_min=1.8, ramp_material="terre_battue", spawn=None):
    """Le plan.json du sol d'une carte du dehors d'après son plan :
    - paliers (`palier`), puis les faces en talus de terre sur toute la carte ;
    - matières (`sol`, le dernier posé l'emporte ; `skip` : celles qu'on ne peint pas en rectangle),
      au bord bruité de `noise` m si noise > 0 ; l'eau (`eau` basse : praticable ; profonde : non) ;
    - rampes (`rampe`, de matière `ramp_material`) ;
    - chemins (`chemin`) : une bande de terre de l − path_inset m (au moins path_min), peinte après les
      rampes pour qu'elle les traverse.
    Les paliers négatifs demandent height_zero_value (16 par palier)."""
    steps = []
    levels = sorted({lv.h for lv in m.levels} | {0.0})
    zero_value = 16 * max(1, int(round(-min(levels) / 0.5))) if min(levels) < 0 else 0
    for lv in m.levels:
        steps.append({"op": "level", "level": int(round(lv.h / 0.5)), "shape": {"rect": rect_of(lv.rect)}})
    steps.append({"op": "face", "face": "earth", "shape": {"rect": [0, 0, int(m.w), int(m.d)]}})
    for k, g in enumerate(m.grounds):
        if g.name in skip:
            continue
        shape = {"rect": rect_of(g.rect)}
        if noise > 0:
            shape.update({"noise": noise, "noise_scale": 2.5, "seed": 1 + k})
        steps.append({"op": "material", "material": SOL[g.name], "shape": shape})
    for k, w in enumerate(m.waters):
        shape = {"rect": rect_of(w.rect)}
        if noise > 0:
            shape.update({"noise": noise, "noise_scale": 2.2, "seed": 40 + k})
        steps.append({"op": "material", "material": "eau" if w.block else "eau_basse", "shape": shape})
    for ramp in m.ramps:
        r = ramp.extra
        going = GOING[r["sens"]]
        direction = going if r["y1"] > r["y0"] else OPPOSITE[going]
        x0, z0, w, d = rect_of(ramp.rect)
        steps.append({"op": "ramp", "dir": direction, "rect": [int(x0), int(z0), int(w), int(d)],
                      "material": ramp_material})
    for path in m.paths:
        steps.append({"op": "path", "material": path_material, "width": max(path_min, path.extra["l"] - path_inset),
                      "points": [list(p) for p in path.extra["pts"]], "noise": 0.35, "noise_scale": 1.6})
    plan = {
        "_comment": comment or "Sol en relief de la carte %s (lot C1), d'après docs/lore/CARTE.md ; écrit par "
                               "tools/exterior_maps.py gen, lu par tools/map_build.py gen %s ; le jeu ne lit "
                               "pas ce fichier." % (m.id, m.id),
        "size": [int(m.w), int(m.d)],
        "seed": seed,
        "materials_scale": scale,
        "edges": {"north": "land", "east": "land", "south": "land", "west": "land"},
        "skirt": 16,
        "spawn": spawn or [int(m.markers["Spawn"].rect.x0), int(m.markers["Spawn"].rect.z0)],
        "base": {"level": 0, "material": "herbe"},
        "materials": {k: dict(v) for k, v in MY_MATERIALS.items()},
        "steps": steps,
    }
    if zero_value:
        plan["height_zero_value"] = zero_value
    return plan


def step_index(steps, op, **match):
    """Rang de la première opération `op` dont les clés valent `match` (-1 : aucune)."""
    for i, s in enumerate(steps):
        if s["op"] == op and all(s.get(k) == v for k, v in match.items()):
            return i
    return -1
