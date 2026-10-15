#!/usr/bin/env python3
"""(C1) Les cartes du dehors de l'île n° 68, écrites d'après leurs plans : docs/lore/CARTE.md (blocs
```plan, lus par tools/carte_plans.py). L'équivalent de tools/interior_maps.py pour le dehors.

Pour une carte, l'outil écrit :
- le sol : data/maps/<id>/plan.json, puis (comme tools/map_build.py gen) map.json, heights.png,
  materials.png et structures.png ;
- la scène src/world/maps/<id>/<id>.tscn : Map (nom, lieu, taille, bornes de caméra), Ground,
  Edges (les bords du plan, des boîtes invisibles), Geometry et ses groupes de décors, Scatter (les
  familles posées par des PropScatter), Markers, Exits, Life/Places (les points nommés), Life/Areas
  (les places réservées), Lights, Ambience ;
- le décor : l'ossature du plan (bâtiments, grands décors, arbres, bords), puis les kits par bande
  (tirés au hasard, graine fixe : la scène est la même à chaque appel) avec la règle de caméra de
  CARTE.md 0.3 : un décor qui se dresse au-dessus de la tête du joueur (1,4 m) devant une case où
  l'on marche prend sa variante de premier plan (« _forest » ou « _fg », qui s'efface autour du
  joueur) ; faute de variante, il n'est pas posé en cet endroit et l'outil le dit.

Deux sortes de cartes :
- les cartes construites, une recette par carte dans tools/exterior_recipes/<id>.py (entrepot,
  sentier, village, colline) : le sol, la pose, la vie ambiante, les places de la vie que le plan ne nomme pas ;
- les cartes d'attente (WAITING plus bas : foret_profonde, port) : un sol plat de la
  bonne matière, une lisière, l'écriteau « Plus loin, bientôt », la sortie de retour et le
  marqueur d'arrivée du plan. Provisoires : le lot de la carte les remplace par une recette
  (ajouter la carte à RECIPES, retirer l'attente).

Usage (Python 3.9+, Pillow) :

    python3 tools/exterior_maps.py gen [map_id ...]      # écrit les cartes (toutes sans argument)
    python3 tools/exterior_maps.py check [map_id ...]    # les cartes écrites sont-elles à jour ? écarts
                                                         # au plan, avertissements de la règle de caméra
    python3 tools/exterior_maps.py places [map_id ...]   # réécrit, dans CARTE.md, la liste des places de
                                                         # la vie de chaque carte (points, zones, extras)
    python3 tools/exterior_maps.py props                 # écrit les scènes de décor nouvelles (exterior_props.py)

Après gen : tools/hd2d_assets.py gen (images absentes), tools/import.sh (.uid, .import à commiter),
puis tools/test.sh tests/unit/test_maps.gd, test_entrepot.gd, test_sentier.gd, test_world_atlas.gd.
Une carte nouvelle entre aussi dans l'île : data/world/islands/ile_68.json (`maps`, et son lieu).

Ajouter une carte du dehors : son bloc ```plan dans CARTE.md (python3 tools/carte_plans.py check),
puis exterior_recipes/<id>.py (modèle : sentier.py, plus court ; entrepot.py, plus riche) :
    SETTINGS    groupes de décors (l'ordre des nœuds), sorties provisoires, places de la vie en plus ;
                (C3) aussi camera_bounds (les bornes de la caméra, si elles ne sont pas celles de la règle),
                light_preset (le préréglage de lumière de la carte), no_lights (le plan nomme des lumières,
                la carte n'en porte aucune), fauna (la carte porte le nœud Life/Fauna d'E5) ;
    ground_plan(plan_map) -> dict    le plan.json du sol (ground_from_plan(...) le déduit du plan) ;
    prepare(p), pose(p), ambient(p)  voir tools/exterior_pose.py (Pose : place, scatter, poisson…).
Ce que le plan ne dit pas va dans docs/DECISIONS.md ; un écart au plan se reporte dans le plan.
"""

import importlib
import json
import os
import re
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import carte_plans  # noqa: E402
import exterior_ground  # noqa: E402
import exterior_pose  # noqa: E402
import life_zones  # noqa: E402
import map_build  # noqa: E402
from exterior_pose import Pose, prop  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARTE = os.path.join(ROOT, "docs", "lore", "CARTE.md")
DATA = os.path.join(ROOT, "data", "maps")
SCENES = os.path.join(ROOT, "src", "world", "maps")
GROUND_FILES = ["plan.json", "map.json", "heights.png", "materials.png", "structures.png"]

# Cartes construites : une recette par carte (tools/exterior_recipes/<id>.py).
RECIPES = ["entrepot", "sentier", "village", "colline"]

# Lot qui a écrit la liste des places d'une carte (C1 par défaut : l'outil).
PLACES_LOT = {"village": "C2", "colline": "C3"}

# Cartes d'attente (lots de la phase 3 : elles les remplacent). Taille 32 × 24 m. ground : matière du
# sol ; path : matière du chemin ; back : la sortie du plan (son nom, sa cible, le marqueur du retour)
# qui ramène à une carte construite ; exit (x0, z0, x1, z1) : sa zone ; marker et spawn : (x, z, regard)
# du marqueur d'arrivée (`from_<carte d'origine>`) et du Spawn ; path_pts : le chemin ; sign : l'écriteau ;
# gap : (x0, x1) d'une trouée de la lisière au nord.
WAITING = {
    "foret_profonde": {
        "ground": "sous_bois", "path": "chemin", "back": "vers_entrepot",
        "exit": (14, 0, 18, 0.6), "marker": (16, 2.5, "S"), "spawn": (16, 4.0, "S"),
        "path_pts": [[16, 0], [16, 13]], "sign": (17.8, 13.6), "gap": (13, 19),
    },
    "port": {
        "ground": "sous_bois", "path": "chemin", "back": "vers_sentier",
        "exit": (0, 10, 0.6, 14), "marker": (2.5, 12, "E"), "spawn": (5.0, 12, "E"),
        "path_pts": [[0, 12], [19, 12]], "sign": (19.8, 10.6), "gap": None,
    },
}
WAITING_SIZE = (32, 24)

BASIS = {"N": "1, 0, 0, 0, 1, 0, 0, 0, 1", "S": "-1, 0, 0, 0, 1, 0, 0, 0, -1",
         "E": "0, 0, -1, 0, 1, 0, 1, 0, 0", "O": "0, 0, 1, 0, 1, 0, -1, 0, 0"}


def f(v):
    s = ("%.3f" % v).rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def plans():
    with open(CARTE, encoding="utf-8") as handle:
        return {m.id: m for m in carte_plans.parse(handle.read())}


def recipe_of(map_id):
    return importlib.import_module("exterior_recipes." + map_id)


def exists(map_id):
    """La carte existe-t-elle dans le dépôt (une scène écrite) ?"""
    return os.path.exists(os.path.join(SCENES, map_id, map_id + ".tscn"))


def is_waiting(map_id):
    return map_id in WAITING


# --- Le sol d'une carte d'attente ------------------------------------------------------------------


def waiting_ground(map_id, spec, m):
    w, d = WAITING_SIZE
    layer = {"herbe": "grass", "prairie": "meadow_flowers", "sous_bois": "forest_floor"}[spec["ground"]]
    plan = {
        "_comment": "Carte d'attente (lot T1, provisoire jusqu'à la phase 3 : docs/DECISIONS.md) : sol plat, un "
                    "chemin vers l'entrepôt. Lu par tools/map_build.py gen %s." % map_id,
        "size": [w, d], "seed": 68, "materials_scale": 1,
        "edges": {"north": "land", "east": "land", "south": "land", "west": "land"},
        "skirt": 16, "spawn": [int(spec["spawn"][0]), int(spec["spawn"][1])],
        "base": {"level": 0, "material": "sobre"},
        "materials": {
            "sobre": {"label": "Sol de la carte d'attente, assourdi", "layer": layer, "color": "#7a8a6a",
                      "tint": [0.78, 0.78, 0.8]},
            "chemin": {"label": "Chemin de terre (path_dirt_b)", "layer": "path_dirt_b", "color": "#d0a060",
                       "variant": False, "path": True},
        },
        "steps": [{"op": "path", "material": spec["path"], "width": 3.0, "points": spec["path_pts"],
                   "noise": 0.3, "noise_scale": 1.6}],
    }
    return plan


def waiting_scene(map_id, spec, m):
    """La scène d'une carte d'attente."""
    w, d = WAITING_SIZE
    back = [e for e in m.exits if e.name == spec["back"]][0]
    target, target_marker = back.extra["cible"], back.extra["marqueur"]
    arrival = "from_" + target
    ext = [("Script", "res://src/world/map.gd", "1_map"), ("Script", "res://src/world/map_ground.gd", "2_ground"),
           ("Script", "res://src/world/prop_batcher.gd", "3_batcher"),
           ("Script", "res://src/world/map_exit.gd", "4_exit"),
           ("PackedScene", "res://src/world/props/waiting_sign.tscn", "5_sign"),
           ("PackedScene", "res://src/world/props/forest_wall_a.tscn", "6_wall_a"),
           ("PackedScene", "res://src/world/props/forest_wall_c.tscn", "7_wall_c"),
           ("PackedScene", "res://src/world/props/bush_b.tscn", "8_bush"),
           ("PackedScene", "res://src/world/props/fern_b.tscn", "9_fern"),
           ("PackedScene", "res://src/world/props/fg_bush.tscn", "10_fg_bush")]
    x0, z0, x1, z1 = spec["exit"]
    lines = ["[gd_scene format=3]", ""]
    lines += ['[ext_resource type="%s" path="%s" id="%s"]' % e for e in ext]
    lines += ["", '[sub_resource type="BoxShape3D" id="BoxShape3D_exit"]',
              "size = Vector3(%s, 3, %s)" % (f(max(x1 - x0, 0.6)), f(max(z1 - z0, 0.6))), ""]
    lines += ['[node name="%s" type="Node3D"]' % map_id, 'script = ExtResource("1_map")',
              'display_name = "%s"' % m.meta["nom"][0], 'region = &"%s"' % m.meta["region"][0],
              "size = Vector2(%d, %d)" % (w, d), "camera_bounds = Rect2(10, 9, %d, %d)" % (w - 20, d - 17), "",
              '[node name="Ground" type="StaticBody3D" parent="."]', 'script = ExtResource("2_ground")', "",
              '[node name="Geometry" type="Node3D" parent="."]', 'script = ExtResource("3_batcher")', ""]
    # La lisière au nord (deux pans de 16 m ; une trouée pour un chemin qui part au nord).
    walls = [(8.0, "6_wall_a"), (24.0, "7_wall_c")]
    if spec["gap"]:
        walls = [(5.0, "6_wall_a"), (27.0, "7_wall_c")]
    for k, (x, rid) in enumerate(walls):
        lines += ['[node name="Lisiere%d" parent="Geometry" instance=ExtResource("%s")]' % (k + 1, rid),
                  "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, 2.6)" % f(x), ""]
    for k, (x, z) in enumerate(((3.5, 5.0), (11.0, 4.6), (21.5, 4.8), (28.5, 5.2))):
        if spec["gap"] and spec["gap"][0] - 1 < x < spec["gap"][1] + 1:
            continue
        lines += ['[node name="Fern%d" parent="Geometry" instance=ExtResource("9_fern")]' % (k + 1),
                  "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, %s)" % (f(x), f(z)), ""]
    for k, (x, z) in enumerate(((1.6, 18.0), (30.4, 17.0), (2.0, 7.5), (30.0, 7.0))):
        lines += ['[node name="Bush%d" parent="Geometry" instance=ExtResource("8_bush")]' % (k + 1),
                  "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, %s)" % (f(x), f(z)), ""]
    for k, x in enumerate((4.0, 26.0)):
        lines += ['[node name="FrontBush%d" parent="Geometry" instance=ExtResource("10_fg_bush")]' % (k + 1),
                  "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, 23.4)" % f(x), ""]
    sx, sz = spec["sign"]
    lines += ['[node name="Sign" parent="Geometry" instance=ExtResource("5_sign")]',
              "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 0, %s)" % (f(sx), f(sz)), ""]
    mx, mz, look = spec["marker"]
    px, pz, plook = spec["spawn"]
    lines += ['[node name="Markers" type="Node3D" parent="."]', "",
              '[node name="Spawn" type="Marker3D" parent="Markers"]',
              "transform = Transform3D(%s, %s, 0.2, %s)" % (BASIS[plook], f(px), f(pz)), "",
              '[node name="%s" type="Marker3D" parent="Markers"]' % arrival,
              "transform = Transform3D(%s, %s, 0.2, %s)" % (BASIS[look], f(mx), f(mz)), "",
              '[node name="Exits" type="Node3D" parent="."]', "",
              '[node name="%s" type="Area3D" parent="Exits"]' % back.name,
              "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 1.5, %s)" % (f((x0 + x1) / 2), f((z0 + z1) / 2)),
              "collision_layer = 0", "collision_mask = 2", 'script = ExtResource("4_exit")',
              'target_map = &"%s"' % target, 'target_marker = &"%s"' % target_marker, "",
              '[node name="CollisionShape3D" type="CollisionShape3D" parent="Exits/%s"]' % back.name,
              'shape = SubResource("BoxShape3D_exit")', "",
              '[node name="Life" type="Node3D" parent="."]', ""]
    return "\n".join(lines)


# --- La scène d'une carte construite ----------------------------------------------------------------


class Writer:
    """Écrit la scène d'une carte du dehors posée (Pose) : le texte d'un .tscn."""

    def __init__(self, p, recipe, settings):
        self.p = p
        self.recipe = recipe
        self.settings = settings
        self.ext = {}
        self.sub = []
        self.nodes = []

    def ext_id(self, kind, path):
        key = (kind, path)
        if key not in self.ext:
            self.ext[key] = "%d_%s" % (len(self.ext) + 1, re.sub(r"[^a-z0-9]+", "_",
                                                                  os.path.basename(path).split(".")[0].lower()))
        return self.ext[key]

    def node(self, text):
        self.nodes.append(text)

    def box_shape(self, sid, size):
        self.sub.append('[sub_resource type="BoxShape3D" id="BoxShape3D_%s"]\nsize = Vector3(%s, %s, %s)\n'
                        % (sid, f(size[0]), f(size[1]), f(size[2])))
        return "BoxShape3D_%s" % sid

    def text(self, ambient):
        p, m = self.p, self.p.map
        h = p.height
        map_script = self.ext_id("Script", "res://src/world/map.gd")
        ground_script = self.ext_id("Script", "res://src/world/map_ground.gd")
        batcher = self.ext_id("Script", "res://src/world/prop_batcher.gd")
        scatter_script = self.ext_id("Script", "res://src/world/prop_scatter.gd")
        exit_script = self.ext_id("Script", "res://src/world/map_exit.gd")
        ambient_script = self.ext_id("Script", "res://src/world/ambient_sprites.gd") if ambient else ""
        bounds = self.settings.get("camera_bounds") or (10, 9, p.W - 20, p.D - 17)
        preset = 'light_preset = &"%s"\n' % self.settings["light_preset"] if self.settings.get("light_preset") else ""
        self.node('[node name="%s" type="Node3D"]\nscript = ExtResource("%s")\ndisplay_name = "%s"\n'
                  'region = &"%s"\n%ssize = Vector2(%d, %d)\ncamera_bounds = Rect2(%s, %s, %s, %s)\n'
                  % (m.id, map_script, m.meta["nom"][0], m.meta["region"][0], preset, p.W, p.D, f(bounds[0]),
                     f(bounds[1]), f(bounds[2]), f(bounds[3])))
        self.node('[node name="Ground" type="StaticBody3D" parent="."]\nscript = ExtResource("%s")\n' % ground_script)
        # Bords du plan (bord) : ce qui ferme la carte, en boîtes invisibles (couche 1).
        self.node('[node name="Edges" type="StaticBody3D" parent="."]\ncollision_mask = 0\n')
        for k, e in enumerate(p.edges):
            cx, cz = (e.x0 + e.x1) / 2.0, (e.z0 + e.z1) / 2.0
            y = max(h(min(max(cx, 0.1), p.W - 0.1), min(max(cz, 0.1), p.D - 0.1)), -0.5)
            sid = self.box_shape("edge%d" % (k + 1), (e.x1 - e.x0, 4.0, e.z1 - e.z0))
            self.node('[node name="Edge%d" type="CollisionShape3D" parent="Edges"]\n'
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\nshape = SubResource("%s")\n'
                      % (k + 1, f(cx), f(y + 2.0), f(cz), sid))
        self.node('[node name="Geometry" type="Node3D" parent="."]\nscript = ExtResource("%s")\ncell_size = %.1f\n'
                  % (batcher, self.settings.get("cell_size", 24.0)))
        for g in [g for g in self.settings["groups"] if any(s[0] == g for s in p.singles)]:
            self.node('[node name="%s" type="Node3D" parent="Geometry"]\n' % g)
        for group, name, scene, x, y, z, scale, flip, extra in p.singles:
            rid = self.ext_id("PackedScene", "res://src/world/props/%s.tscn" % scene)
            text = '[node name="%s" parent="Geometry/%s" instance=ExtResource("%s")]\n' % (name, group, rid)
            text += "transform = Transform3D(%s, 0, 0, 0, %s, 0, 0, 0, %s, %s, %s, %s)\n" % (
                f(scale), f(scale), f(scale), f(x), f(y), f(z))
            if flip and not prop(scene).building:
                text += "flip_h = true\n"
            self.node(text)
        self.node('[node name="Scatter" type="Node3D" parent="Geometry"]\n')
        for fname, fam in p.families.items():
            scenes = fam["scenes"]
            ids = [self.ext_id("PackedScene", "res://src/world/props/%s.tscn" % s) for s in scenes]
            pts = ", ".join("%s, 0, %s" % (f(q[0]), f(q[1])) for q in fam["points"])
            text = '[node name="%s" type="Node3D" parent="Geometry/Scatter"]\nscript = ExtResource("%s")\n' % (
                fname, scatter_script)
            text += 'prop = ExtResource("%s")\n' % ids[0]
            text += "points = PackedVector3Array(%s)\n" % pts
            if all(len(q) > 2 for q in fam["points"]):
                text += "yaw_degrees = PackedFloat32Array(%s)\n" % ", ".join(f(q[2]) for q in fam["points"])
            elif any(prop(s).blocks for s in scenes):
                text += "yaw_degrees = PackedFloat32Array(%s)\n" % ", ".join("0" for _ in fam["points"])
            text += "scale_range = Vector2(%s, %s)\nrandom_seed = %d\n" % (f(fam["scale"][0]), f(fam["scale"][1]),
                                                                            fam["seed"])
            if len(ids) > 1:
                text += "variants = Array[PackedScene]([%s])\n" % ", ".join('ExtResource("%s")' % i for i in ids[1:])
            text += "random_flip = true\n"
            self.node(text)
        # Marqueurs (2.7) : regard N, S, E ou O ; à 0,2 m au-dessus du sol.
        self.node('[node name="Markers" type="Node3D" parent="."]\n')
        for name, item in m.markers.items():
            x, z = item.rect.x0, item.rect.z0
            self.node('[node name="%s" type="Marker3D" parent="Markers"]\ntransform = Transform3D(%s, %s, %s, %s)\n'
                      % (name, BASIS[item.extra["regard"]], f(x), f(h(x, z) + 0.2), f(z)))
        # Sorties. Vers une carte absente : la sortie provisoire de SETTINGS, ou rien (la recette pose
        # alors ce qui ferme le chemin : p.missing_exits).
        self.node('[node name="Exits" type="Node3D" parent="."]\n')
        for e in m.exits:
            if e.name in p.missing_exits:
                continue
            r = e.rect
            cx, cz = (r.x0 + r.x1) / 2.0, (r.z0 + r.z1) / 2.0
            y = h(min(max(cx, 0.3), p.W - 0.3), min(max(cz, 0.3), p.D - 0.3))
            target, marker = e.extra["cible"], e.extra["marqueur"]
            meta = ""
            if e.name in p.provisional_exits:
                meta = 'metadata/plan_target_map = &"%s"\nmetadata/plan_target_marker = &"%s"\n' % (target, marker)
                target, marker = p.provisional_exits[e.name]
            meta += self.settings.get("exit_meta", {}).get(e.name, "")
            depth = max(r.z1 - r.z0, 0.6)
            width = max(r.x1 - r.x0, 0.6)
            sid = self.box_shape("exit_%s" % e.name, (width, 3.0, depth))
            prompt = 'prompt = "%s"\n' % e.extra["invite"] if e.extra["invite"] else ""
            self.node('[node name="%s" type="Area3D" parent="Exits"]\n'
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n'
                      'collision_layer = 0\ncollision_mask = 2\nscript = ExtResource("%s")\ntarget_map = &"%s"\n'
                      'target_marker = &"%s"\n%s%s' % (e.name, f(cx), f(y + 1.5), f(cz), exit_script, target, marker,
                                                       prompt, meta))
            self.node('[node name="CollisionShape3D" type="CollisionShape3D" parent="Exits/%s"]\nshape = SubResource("%s")\n'
                      % (e.name, sid))
        # La vie (E4, E5) : points nommés (Life/Places) et places réservées (Life/Areas : Marker3D au
        # centre, rectangle en métadonnée).
        self.node('[node name="Life" type="Node3D" parent="."]\n')
        self.node('[node name="Places" type="Node3D" parent="Life"]\n')
        for name, (x, z) in p.points.items():
            yaw = life_zones.point_yaw(m.id, name)
            basis = "1, 0, 0, 0, 1, 0, 0, 0, 1" if not yaw else _yaw_basis(yaw)
            self.node('[node name="%s" type="Marker3D" parent="Life/Places"]\n'
                      'transform = Transform3D(%s, %s, %s, %s)\n' % (name, basis, f(x), f(h(x, z)), f(z)))
        for name, x, z, yaw in self.settings.get("extra_places", []):
            basis = "1, 0, 0, 0, 1, 0, 0, 0, 1" if not yaw else _yaw_basis(yaw)
            self.node('[node name="%s" type="Marker3D" parent="Life/Places"]\n'
                      'transform = Transform3D(%s, %s, %s, %s)\n' % (name, basis, f(x), f(h(x, z)), f(z)))
        # (V1) Les zones et les départs de la vie (tools/life_zones.py) : un marqueur et ses points enfants,
        # posés au sol (la hauteur du palier, plus dy pour une branche d'arbre).
        for entry in life_zones.zones_of(m.id):
            x, z, yaw, _dy = life_zones.anchor(entry)
            y0 = h(x, z)
            basis = "1, 0, 0, 0, 1, 0, 0, 0, 1" if not yaw else _yaw_basis(yaw)
            self.node('[node name="%s" type="Marker3D" parent="Life/Places"]\n'
                      'transform = Transform3D(%s, %s, %s, %s)\n' % (entry["name"], basis, f(x), f(y0), f(z)))
            for k, (px, pz, pyaw, dy) in enumerate(entry["pts"]):
                pb = "1, 0, 0, 0, 1, 0, 0, 0, 1" if not pyaw else _yaw_basis(pyaw)
                self.node('[node name="p%d" type="Marker3D" parent="Life/Places/%s"]\n'
                          'transform = Transform3D(%s, %s, %s, %s)\n'
                          % (k + 1, entry["name"], pb, f(px - x), f(h(px, pz) + dy - y0), f(pz - z)))
        self.node('[node name="Areas" type="Node3D" parent="Life"]\n')
        for pl in m.places:
            r = pl.rect
            cx, cz = (r.x0 + r.x1) / 2.0, (r.z0 + r.z1) / 2.0
            self.node('[node name="%s" type="Marker3D" parent="Life/Areas"]\n'
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n'
                      'metadata/area = Rect2(%s, %s, %s, %s)\n' % (pl.name, f(cx), f(h(cx, cz)), f(cz), f(r.x0), f(r.z0),
                                                                    f(r.x1 - r.x0), f(r.z1 - r.z0)))
        # Objets à examiner (Examinable ; textes : settings["texts"], format de data/texts/village.json) : (clé, x, z,
        # taille de la zone) ; text_key = « carte/clé ».
        examine = self.settings.get("examine", [])
        if examine:
            script = self.ext_id("Script", "res://src/world/examinable.gd")
            self.node('[node name="Examine" type="Node3D" parent="."]\n')
        for key, x, z, size in examine:
            self.node('[node name="%s" type="Area3D" parent="Examine"]\n'
                      'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\nscript = ExtResource("%s")\n'
                      'text_key = "%s/%s"\nsize = Vector3(%s, %s, %s)\ntexts_path = "%s"\n'
                      % (key, f(x), f(h(x, z)), f(z), script, m.id, key, f(size[0]), f(size[1]), f(size[2]),
                         self.settings["texts"]))
        # Lumières : la lanterne à cristal (une lampe OmniLight3D que Atmosphere règle selon le moment,
        # lamp_energy) ; les autres, des repères (Marker3D). Aucune carte du dehors n'a de lampadaire.
        lights = [] if self.settings.get("no_lights") else m.lights
        if lights:
            self.node('[node name="Lights" type="Node3D" parent="."]\n')
        for light in lights:
            x, z = light.rect.x0, light.rect.z0
            y = h(x, z) + light.h
            if light.extra["type"] == "cristal":
                self.node('[node name="%s" type="OmniLight3D" parent="Lights"]\n'
                          'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n'
                          'light_color = Color(1, 0.86, 0.62, 1)\nlight_energy = 0.7\nomni_range = 7.0\n'
                          'omni_attenuation = 1.4\nmetadata/kind = &"%s"\n'
                          % (light.name, f(x), f(y), f(z + 0.6), light.extra["type"]))
            else:
                self.node('[node name="%s" type="Marker3D" parent="Lights"]\n'
                          'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\nmetadata/kind = &"%s"\n'
                          % (light.name, f(x), f(y), f(z), light.extra["type"]))
        if self.settings.get("fauna"):
            fauna = self.ext_id("PackedScene", "res://src/fauna/fauna.tscn")
            self.node('[node name="Fauna" parent="Life" instance=ExtResource("%s")]\n' % fauna)
        amb = []
        if ambient:
            self.node('[node name="Ambience" type="Node3D" parent="."]\n')
        for entry in ambient:
            name, tex, frames, fps, motion, count, area, lift, region, speed, sway, seed, at = entry[:13]
            extra = entry[13] if len(entry) > 13 else ""
            tid = self.ext_id("Texture2D", "res://assets/hd2d/anim/%s.png" % tex)
            amb.append('[node name="%s" type="Node3D" parent="Ambience"]\n'
                       'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)\n'
                       'script = ExtResource("%s")\ntexture = ExtResource("%s")\nframes = %d\nfps = %s\nmotion = %d\n'
                       'count = %d\narea = Vector3(%s, %s, %s)\nlift = %s\nregion_size = Vector2(%s, %s)\n'
                       'speed = %s\nsway = %s\nrandom_seed = %d\n%s'
                       % (name, f(at[0]), f(at[1]), f(at[2]), ambient_script, tid, frames, f(fps), motion, count,
                          f(area[0]), f(area[1]), f(area[2]), f(lift), f(region[0]), f(region[1]), f(speed), f(sway),
                          seed, extra))
        head = ["[gd_scene format=3]", ""]
        for (kind, path), rid in self.ext.items():
            head.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, rid))
        head.append("")
        return "\n".join(head) + "\n" + "\n".join(self.sub) + "\n" + "\n".join(self.nodes + amb)


def _yaw_basis(yaw):
    import math
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    return "%s, 0, %s, 0, 1, 0, %s, 0, %s" % (f(c), f(s), f(-s), f(c))


# --- Écrire, comparer ------------------------------------------------------------------------------


def ground_outputs(map_id, plan, tmp):
    """Écrit plan.json dans tmp/<id>, génère le sol (map_build), rend {fichier: octets}."""
    folder = os.path.join(tmp, map_id)
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, "plan.json"), "w", encoding="utf-8") as handle:
        handle.write(json.dumps(plan, ensure_ascii=False, indent=1) + "\n")
    saved = map_build.DATA
    map_build.DATA = tmp
    try:
        map_build.generate(map_id)
    finally:
        map_build.DATA = saved
    out = {}
    for name in GROUND_FILES:
        path = os.path.join(folder, name)
        if os.path.exists(path):
            with open(path, "rb") as handle:
                out[name] = handle.read()
    return out


class Built:
    """Ce qu'une carte écrit : fichiers (chemin relatif au dépôt → octets), avertissements, écarts."""

    def __init__(self):
        self.files = {}
        self.warnings = []
        self.deviations = []
        self.pose = None
        self.scene_text = ""


def build(map_id, all_plans, tmp):
    m = all_plans[map_id]
    result = Built()
    if is_waiting(map_id):
        spec = WAITING[map_id]
        ground = ground_outputs(map_id, waiting_ground(map_id, spec, m), tmp)
        scene = waiting_scene(map_id, spec, m)
    else:
        recipe = recipe_of(map_id)
        settings = dict(recipe.SETTINGS)
        ground = ground_outputs(map_id, recipe.ground_plan(m), tmp)
        p = Pose(m, ground=map_build.MapData(map_id, root=tmp))
        result.pose = p
        # Sorties vers une carte qui n'existe pas encore : provisoire (SETTINGS) ou omise.
        p.provisional_exits = {}
        p.missing_exits = set()
        for e in m.exits:
            target = e.extra["cible"]
            if not exists(target):
                if target in settings.get("provisional", {}):
                    p.provisional_exits[e.name] = settings["provisional"][target]
                elif e.name in settings.get("omit_if_missing", ()):
                    p.missing_exits.add(e.name)
                else:
                    result.warnings.append("sortie %s : la carte %s n'existe pas" % (e.name, target))
        if hasattr(recipe, "prepare"):
            recipe.prepare(p)
        exterior_pose.forget_catalog()
        settings["extra_places"] = [(n, x, z, yaw) for n, x, z, yaw, _why in getattr(recipe, "PLACES_WHY", [])]
        recipe.pose(p)
        ambient = recipe.ambient(p) if hasattr(recipe, "ambient") else []
        writer = Writer(p, recipe, settings)
        scene = writer.text(ambient)
        result.warnings += p.warnings
        result.deviations = list(getattr(recipe, "DEVIATIONS", []))
        result.deviations += plan_gaps(m, writer, p)
    result.scene_text = scene
    for name, content in ground.items():
        result.files["data/maps/%s/%s" % (map_id, name)] = content
    result.files["src/world/maps/%s/%s.tscn" % (map_id, map_id)] = scene.encode("utf-8")
    return result


def plan_gaps(m, writer, p):
    """Écarts entre le plan et la scène écrite : ce que le plan nomme et que la scène n'a pas."""
    gaps = []
    scene = writer.nodes
    joined = "\n".join(scene)
    for e in m.exits:
        if e.name in p.missing_exits:
            gaps.append("sortie %s omise : la carte %s n'existe pas encore (écriteau en attendant)"
                        % (e.name, e.extra["cible"]))
        elif '[node name="%s" type="Area3D" parent="Exits"]' % e.name not in joined:
            gaps.append("sortie %s absente de la scène" % e.name)
    for name in m.markers:
        if '[node name="%s" type="Marker3D" parent="Markers"]' % name not in joined:
            gaps.append("marqueur %s absent" % name)
    for name in m.points:
        if '[node name="%s" type="Marker3D" parent="Life/Places"]' % name not in joined:
            gaps.append("point %s absent" % name)
    for pl in m.places:
        if '[node name="%s" type="Marker3D" parent="Life/Areas"]' % pl.name not in joined:
            gaps.append("place %s absente" % pl.name)
    used = {path for (_kind, path) in writer.ext}
    for item in m.decors + m.trees:
        if item.name in ("wall_lantern",):
            continue
        scenes = [s for s in (item.name, item.name + "_fg", item.name + "_forest")
                  if "res://src/world/props/%s.tscn" % s in used]
        if not scenes:
            gaps.append("%s %s (ligne %d) n'est posé par aucune scène" % (item.kind, item.name, item.line))
    return gaps


def changed(map_id, built):
    out = []
    for rel, content in built.files.items():
        path = os.path.join(ROOT, rel)
        old = open(path, "rb").read() if os.path.exists(path) else None
        if old != content:
            out.append(rel)
    return out


def write(built, rels):
    for rel in rels:
        path = os.path.join(ROOT, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as handle:
            handle.write(built.files[rel])


# --- CARTE.md : la liste des places -----------------------------------------------------------------


def places_markdown(map_id, m, extras):
    named = list(m.points)
    lines = ["<!-- places:%s -->" % map_id,
             "**Places de la vie** (lot %s ; `Marker3D` de `Life/Places` et `Life/Areas` dans la carte, pour E4, "
             "E5 et E6) : les points nommés ci-dessus, à leur nom (`%s`)" % (PLACES_LOT.get(map_id, "C1"),
                                                                           "`, `".join(named))]
    if m.places:
        lines[-1] += " ; les places réservées, en `Life/Areas` avec leur rectangle (`%s`)" % "`, `".join(
            p.name for p in m.places)
    if extras:
        lines[-1] += " ; et, en plus du plan : %s" % ", ".join(
            "`%s` (%s ; %s)" % (name, "%g ; %g" % (x, z), why) for name, x, z, _yaw, why in extras)
    lines[-1] += "."
    zones = life_zones.zones_of(map_id)
    if zones:
        lines.append("")
        lines.append("**Zones et départs de la vie** (lot V1 ; un point enfant `p1`, `p2`… par case, regard au −Z, "
                     "posé au sol ; `vers_<carte>` : par où l'on part vers une carte, et d'où l'on en arrive) :")
        lines.append("")
        for entry in zones:
            count = len(entry["pts"])
            lines.append("- `%s`%s : %s" % (entry["name"], " (%d points)" % count if count else "", entry["why"]))
    lines.append("<!-- /places:%s -->" % map_id)
    return "\n".join(lines)


def cmd_places(ids):
    with open(CARTE, encoding="utf-8") as handle:
        text = handle.read()
    all_plans = plans()
    for map_id in ids:
        if is_waiting(map_id):
            continue
        extras = getattr(recipe_of(map_id), "PLACES_WHY", [])
        extras = [(n, x, z, yaw, why) for n, x, z, yaw, why in extras]
        block = places_markdown(map_id, all_plans[map_id], extras)
        start = "<!-- places:%s -->" % map_id
        end = "<!-- /places:%s -->" % map_id
        if start in text:
            head, rest = text.split(start, 1)
            tail = rest.split(end, 1)[1]
            text = head + block + tail
            continue
        at = text.index("carte %s " % map_id)
        close = text.index("```\n", at) + 4
        after = text[close:]
        # Après le bloc ```plan et, s'il y en a un, sa liste de places écrite par un autre outil.
        text = text[:close] + "\n" + block + "\n" + after
    with open(CARTE, "w", encoding="utf-8") as handle:
        handle.write(text)
    print("CARTE.md : places de %s" % ", ".join(i for i in ids if not is_waiting(i)))


# --- Commandes --------------------------------------------------------------------------------------


def all_ids():
    return RECIPES + list(WAITING)


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("gen", "check", "places", "props"):
        print(__doc__)
        return 2
    if args[0] == "props":
        import exterior_props
        exterior_props.write_all()
        return 0
    ids = args[1:] or all_ids()
    unknown = [i for i in ids if i not in all_ids()]
    if unknown:
        print("cartes inconnues : %s (connues : %s)" % (", ".join(unknown), ", ".join(all_ids())))
        return 2
    if args[0] == "places":
        cmd_places(ids)
        return 0
    import exterior_props
    all_plans = plans()
    status = 0
    for map_id in ids:
        if not is_waiting(map_id):
            exterior_props.write_all(quiet=True)
            exterior_pose.forget_catalog()
        with tempfile.TemporaryDirectory() as tmp:
            built = build(map_id, all_plans, tmp)
            rels = changed(map_id, built)
            for line in built.warnings:
                print("%s : avertissement, %s" % (map_id, line))
            for line in built.deviations:
                print("%s : écart au plan, %s" % (map_id, line))
            if args[0] == "check":
                if rels:
                    print("%s : à réécrire (%s)" % (map_id, ", ".join(rels)))
                    status = 1
                else:
                    print("%s : à jour" % map_id)
            else:
                write(built, rels)
                print("%s : %s" % (map_id, ", ".join(rels) if rels else "à jour"))
    return status


if __name__ == "__main__":
    sys.exit(main())
