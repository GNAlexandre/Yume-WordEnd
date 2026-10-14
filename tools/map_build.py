#!/usr/bin/env python3
"""Sol en relief des cartes extérieures (lot E2 de la refonte) : vérifier, générer, voir de dessus.

Une carte extérieure décrit son sol dans data/maps/<map_id>/ (format : PLAN.md, « Format du sol
des cartes extérieures ») : map.json, heights.png (un pixel par case, gris = palier de 0,5 m,
transparent = le vide), materials.png (une couleur par matière), structures.png (escaliers,
rampes, style des faces). MapGround (src/world/map_ground.gd) en bâtit le sol au chargement.

Usage (Python 3.9+, Pillow) :

    python3 tools/map_build.py check [map_id ...]   # vérifie (toutes les cartes si aucune)
    python3 tools/map_build.py gen <map_id>         # data/maps/<id>/plan.json → images + map.json
    python3 tools/map_build.py view <map_id> [--out build/maps/<id>_dessus.png] [--scale 12]
    python3 tools/map_build.py --root tests/data/maps check   # les cartes des tests

check relève ce que MapGround refuse (tailles d'images, palette, paliers, escaliers et rampes qui
ne relient pas deux cases plates, pentes de plus de 40°, escalier ou rampe au bord de la carte ou
à moins de 2 m du vide, volées voisines de profils différents, marche de plus de 0,5 m sans
escalier entre deux cases de chemin, départ hors de la terre) et avertit des cases praticables
qu'on n'atteint pas depuis le départ (spawn) et de celles qu'on n'atteint qu'en sautant une
marche de 0,5 m.

gen lit un plan (plan.json) : taille, bords, matière et palier de base, puis des opérations
appliquées dans l'ordre sur des formes (rect, poly, ellipse, band) au bord éventuellement bruité :
void, level, material, path, stairs, ramp, face. Voir PLAN.md pour le détail.

view dessine la carte vue de dessus : couleurs moyennes des tuiles de l'atlas, relief ombré,
falaises (roche, talus, muret), escaliers et rampes fléchés, côte, départ, légende.
"""

import argparse
import json
import math
import os
import random
import re
import sys
from collections import deque

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data", "maps")
LIBRARY = os.path.join(DATA, "ground_materials.json")
GROUND = os.path.join(ROOT, "assets", "hd2d", "ground")

FORMAT = "map_ground"
VERSION = 1
LEVEL_HEIGHT = 0.5
MAX_SLOPE_DEG = 40.0
DEFAULT_STEP_VALUE = 16
DEFAULT_SKIRT = 16
RIM_ZONE = 2
SIDES = ["north", "east", "south", "west"]
DIRECTIONS = [(0, -1), (1, 0), (0, 1), (-1, 0)]
MAP_KEYS = ["format", "version", "size", "heights_image", "height_step_value", "height_zero_value",
            "materials_image", "materials_scale", "structures_image", "palette", "materials", "edges",
            "skirt", "barrier", "spawn"]
MATERIAL_KEYS = ["label", "layer", "color", "tint", "variant", "edge", "path", "walkable", "ripple", "border"]
GROUND_LAYERS = ["grass", "grass_dry", "forest_floor", "path_dirt", "flagstone", "cobble", "sand",
                 "rock", "peat", "water", "mud", "metal",
                 "grass_b", "forest_floor_b", "path_dirt_b", "leaf_litter", "moss", "grass_dry_b",
                 "flagstone_b", "cobble_b", "meadow_flowers", "gravel", "garden_soil", "sand_b",
                 "rock_b", "planks", "stream_bed"]
FLAT, STAIRS, RAMP = 0, 1, 2
FACE_COLORS = {"rock": (88, 72, 60), "earth": (104, 72, 44), "wall": (150, 150, 150)}


def load_json(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def library():
    return load_json(LIBRARY)


def hex_rgb(color):
    color = color.lstrip("#")
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))


def rgb_hex(rgb):
    return "#%02x%02x%02x" % tuple(rgb[:3])


# --- Lecture et vérification ---------------------------------------------------------------------


class MapData:
    """Une carte lue et vérifiée (mêmes règles que MapGroundData, src/world/map_ground_data.gd)."""

    def __init__(self, map_id, root=None):
        self.map_id = map_id
        self.folder = os.path.join(root or DATA, map_id)
        self.problems = []
        self.warnings = []
        self.lib = library()
        self.w = self.d = 0
        self.scale = 1
        self.spec = {}
        path = os.path.join(self.folder, "map.json")
        if not os.path.exists(path):
            self.problems.append("%s absent" % path)
            return
        self.spec = load_json(path)
        self._parse_spec()
        self._parse_materials()
        if self.w <= 0 or self.d <= 0:
            return
        heights = self._image(self.spec.get("heights_image", "heights.png"), (self.w, self.d))
        materials = self._image(self.spec.get("materials_image", "materials.png"),
                                (self.w * self.scale, self.d * self.scale))
        structures = None
        if "structures_image" in self.spec:
            structures = self._image(self.spec["structures_image"], (self.w, self.d))
        if heights is None or materials is None:
            return
        self._read_heights(heights)
        self._read_materials(materials)
        self._read_structures(structures)
        self._runs()
        self._validate()
        self._reachability()

    # Description ----------------------------------------------------------------------------

    def _parse_spec(self):
        spec = self.spec
        for key in spec:
            if not key.startswith("_") and key not in MAP_KEYS:
                self.problems.append("map.json : clé inconnue « %s »" % key)
        if spec.get("format") != FORMAT:
            self.problems.append("map.json : format « %s » attendu" % FORMAT)
        if spec.get("version") != VERSION:
            self.problems.append("map.json : version %d attendue" % VERSION)
        size = spec.get("size", [])
        if isinstance(size, list) and len(size) == 2:
            self.w, self.d = int(size[0]), int(size[1])
        if self.w < 4 or self.d < 4:
            self.problems.append("map.json : size [largeur, profondeur] de 4 m au moins")
            self.w = self.d = 0
        self.scale = int(spec.get("materials_scale", 1))
        if self.scale not in (1, 2, 4):
            self.problems.append("map.json : materials_scale vaut 1, 2 ou 4")
            self.scale = 1
        self.step = int(spec.get("height_step_value", DEFAULT_STEP_VALUE))
        if self.step < 1:
            self.problems.append("map.json : height_step_value ≥ 1")
            self.step = 1
        self.zero = int(spec.get("height_zero_value", 0))
        self.edges = {side: "land" for side in SIDES}
        for side, kind in spec.get("edges", {}).items():
            if side not in SIDES or kind not in ("void", "land"):
                self.problems.append("map.json : edges %s = %s (north|east|south|west : void|land)" % (side, kind))
            else:
                self.edges[side] = kind
        spawn = spec.get("spawn")
        self.spawn = tuple(int(v) for v in spawn) if isinstance(spawn, list) and len(spawn) == 2 else None

    def _parse_materials(self):
        known = {name: dict(value) for name, value in self.lib.get("materials", {}).items()}
        for name, value in self.spec.get("materials", {}).items():
            if not name.startswith("_"):
                merged = dict(known.get(name, {}))
                merged.update(value)
                known[name] = merged
        self.names = []
        self.specs = []
        self.color_index = {}
        self.paint = {}
        palette = self.spec.get("palette", {})
        if not palette:
            self.problems.append("map.json : palette vide")
        for color, name in palette.items():
            if color.startswith("_"):
                continue
            if len(color) != 7 or not color.startswith("#"):
                self.problems.append("palette : couleur « %s » (#rrggbb)" % color)
                continue
            if name not in known:
                self.problems.append("palette : matière inconnue « %s »" % name)
                continue
            if name not in self.names:
                self.names.append(name)
                self.specs.append(self._resolve(name, known[name]))
            index = self.names.index(name)
            self.color_index[hex_rgb(color)] = index
            self.paint.setdefault(index, hex_rgb(color))

    def _resolve(self, name, raw):
        for key in raw:
            if not key.startswith("_") and key not in MATERIAL_KEYS:
                self.problems.append("matière %s : clé inconnue « %s »" % (name, key))
        if raw.get("layer") not in GROUND_LAYERS:
            self.problems.append("matière %s : tuile « %s » absente de l'atlas" % (name, raw.get("layer")))
        if raw.get("edge", "soft") not in ("soft", "sharp"):
            self.problems.append("matière %s : edge soft ou sharp" % name)
        border = raw.get("border")
        if border is not None and border.get("layer") not in GROUND_LAYERS:
            self.problems.append("matière %s : tuile de bordure inconnue" % name)
        return {
            "layer": raw.get("layer", "grass"),
            "tint": tuple(raw.get("tint", [1.0, 1.0, 1.0])),
            "path": bool(raw.get("path", False)),
            "walkable": bool(raw.get("walkable", True)),
            "border": border,
            "label": raw.get("label", name),
        }

    def _image(self, file_name, want):
        path = os.path.join(self.folder, file_name)
        if not os.path.exists(path):
            self.problems.append("%s absente" % path)
            return None
        img = Image.open(path).convert("RGBA")
        if img.size != want:
            self.problems.append("%s : %d × %d px au lieu de %d × %d" % (file_name, img.size[0], img.size[1], want[0], want[1]))
            return None
        return img

    # Images ---------------------------------------------------------------------------------

    def _read_heights(self, img):
        px = img.load()
        self.levels = [None] * (self.w * self.d)
        bad = []
        for j in range(self.d):
            for i in range(self.w):
                r, _g, _b, a = px[i, j]
                if a < 128:
                    continue
                value = r - self.zero
                if value % self.step != 0:
                    bad.append((i, j))
                self.levels[j * self.w + i] = round(value / self.step)
        if bad:
            self.problems.append("heights.png : %d case(s) hors palier (gris multiple de %d), dont %s" % (len(bad), self.step, bad[0]))

    def _read_materials(self, img):
        px = img.load()
        w, h = img.size
        self.pixels = [None] * (w * h)
        unknown = {}
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                cell = (y // self.scale) * self.w + x // self.scale
                if a < 128:
                    if self.levels[cell] is not None:
                        unknown.setdefault("transparent", (x, y))
                    continue
                index = self.color_index.get((r, g, b))
                if index is None:
                    if self.levels[cell] is not None:
                        unknown.setdefault(rgb_hex((r, g, b)), (x, y))
                    continue
                self.pixels[y * w + x] = index
        for color, at in unknown.items():
            self.problems.append("materials.png : couleur %s hors palette, en %s" % (color, at))

    def _read_structures(self, img):
        n = self.w * self.d
        self.kinds = [FLAT] * n
        self.dirs = [0] * n
        self.faces = [None] * n
        if img is None:
            return
        table = {hex_rgb(color): entry for color, entry in self.lib.get("structures", {}).items()}
        px = img.load()
        for j in range(self.d):
            for i in range(self.w):
                r, g, b, a = px[i, j]
                if a < 128 or (r, g, b) == (0, 0, 0):
                    continue
                entry = table.get((r, g, b))
                c = j * self.w + i
                if entry is None:
                    self.problems.append("structures.png : couleur %s inconnue en (%d, %d)" % (rgb_hex((r, g, b)), i, j))
                elif "face" in entry:
                    self.faces[c] = entry["face"]
                else:
                    self.kinds[c] = STAIRS if entry.get("kind") == "stairs" else RAMP
                    self.dirs[c] = SIDES.index(entry.get("dir", "north"))

    # Cases ----------------------------------------------------------------------------------

    def in_map(self, i, j):
        return 0 <= i < self.w and 0 <= j < self.d

    def lookup(self, i, j):
        """Case qui vaut pour (i, j), prolongement compris ; None dans le vide d'un bord « void »."""
        if i < 0:
            if self.edges["west"] == "void":
                return None
            i = 0
        elif i >= self.w:
            if self.edges["east"] == "void":
                return None
            i = self.w - 1
        if j < 0:
            if self.edges["north"] == "void":
                return None
            j = 0
        elif j >= self.d:
            if self.edges["south"] == "void":
                return None
            j = self.d - 1
        return j * self.w + i

    def is_void(self, i, j):
        c = self.lookup(i, j)
        return c is None or self.levels[c] is None

    def void_within(self, i, j, reach):
        return any(self.is_void(i + di, j + dj) for dj in range(-reach, reach + 1) for di in range(-reach, reach + 1))

    def cell_material(self, i, j):
        half = self.scale // 2
        w = self.w * self.scale
        return self.pixels[(j * self.scale + half) * w + i * self.scale + half]

    def walkable(self, c):
        if self.levels[c] is None:
            return False
        m = self.cell_material(c % self.w, c // self.w)
        return m is not None and self.specs[m]["walkable"]

    # Volées ---------------------------------------------------------------------------------

    def _same_run(self, i, j, kind, direction):
        if not self.in_map(i, j):
            return False
        c = j * self.w + i
        return self.kinds[c] == kind and self.dirs[c] == direction and self.levels[c] is not None

    def _runs(self):
        n = self.w * self.d
        self.run = [None] * n
        for c in range(n):
            if self.kinds[c] == FLAT or self.run[c] is not None or self.levels[c] is None:
                continue
            kind, direction = self.kinds[c], self.dirs[c]
            dx, dz = DIRECTIONS[direction]
            si, sj = c % self.w, c // self.w
            while self._same_run(si - dx, sj - dz, kind, direction):
                si, sj = si - dx, sj - dz
            count = 0
            while self._same_run(si + dx * count, sj + dz * count, kind, direction):
                count += 1
            low = self._end(si - dx, sj - dz)
            high = self._end(si + dx * count, sj + dz * count)
            label = "escalier" if kind == STAIRS else "rampe"
            if low is None or high is None or high <= low:
                self.problems.append("%s en (%d, %d) : il relie une case plate au bas et une case plate plus haute au bout" % (label, si, sj))
            elif math.degrees(math.atan((high - low) * LEVEL_HEIGHT / count)) > MAX_SLOPE_DEG + 0.001:
                slope = math.degrees(math.atan((high - low) * LEVEL_HEIGHT / count))
                self.problems.append("%s en (%d, %d) : pente de %.0f° (%.1f m sur %d m ; %.0f° au plus)" % (label, si, sj, slope, (high - low) * LEVEL_HEIGHT, count, MAX_SLOPE_DEG))
            for k in range(count):
                cell = (sj + dz * k) * self.w + si + dx * k
                self.run[cell] = (k, count, low, high, (si, sj))

    def _end(self, i, j):
        if not self.in_map(i, j):
            return None
        c = j * self.w + i
        if self.levels[c] is None or self.kinds[c] != FLAT:
            return None
        return self.levels[c]

    # Règles ---------------------------------------------------------------------------------

    def _validate(self):
        near_void = on_border = twisted = 0
        steps = []
        for j in range(self.d):
            for i in range(self.w):
                c = j * self.w + i
                if self.levels[c] is None:
                    continue
                if self.kinds[c] != FLAT:
                    if i in (0, self.w - 1) or j in (0, self.d - 1):
                        on_border += 1
                    if self.void_within(i, j, RIM_ZONE):
                        near_void += 1
                    if not self._parallel_ok(i, j):
                        twisted += 1
                    continue
                for ni, nj in ((i + 1, j), (i, j + 1)):
                    if self._path_cliff(c, ni, nj):
                        steps.append((i, j))
        if on_border:
            self.problems.append("%d case(s) d'escalier ou de rampe au bord de la carte" % on_border)
        if near_void:
            self.problems.append("%d case(s) d'escalier ou de rampe à moins de %d m du vide" % (near_void, RIM_ZONE))
        if twisted:
            self.problems.append("%d case(s) d'escalier ou de rampe collées à une volée d'un autre profil" % twisted)
        if steps:
            self.problems.append("%d marche(s) de plus de %.1f m sans escalier sur un chemin, dont en %s" % (len(steps), LEVEL_HEIGHT, steps[0]))
        if self.spawn is not None:
            i, j = self.spawn
            if not self.in_map(i, j) or not self.walkable(j * self.w + i):
                self.problems.append("spawn %s : hors de la carte ou pas praticable" % (self.spawn,))

    def _parallel_ok(self, i, j):
        c = j * self.w + i
        dx, dz = DIRECTIONS[self.dirs[c]]
        for si, sj in ((dz, dx), (-dz, -dx)):
            ni, nj = i + si, j + sj
            if not self.in_map(ni, nj):
                continue
            k = nj * self.w + ni
            if self.kinds[k] == FLAT or self.levels[k] is None:
                continue
            a, b = self.run[c], self.run[k]
            if self.kinds[k] != self.kinds[c] or self.dirs[k] != self.dirs[c] or a is None or b is None or a[:4] != b[:4]:
                return False
        return True

    def _path_cliff(self, c, ni, nj):
        if not self.in_map(ni, nj):
            return False
        k = nj * self.w + ni
        if self.levels[k] is None or self.kinds[k] != FLAT or abs(self.levels[k] - self.levels[c]) <= 1:
            return False
        a = self.cell_material(c % self.w, c // self.w)
        b = self.cell_material(ni, nj)
        if a is None or b is None:
            return False
        sa, sb = self.specs[a], self.specs[b]
        return sa["path"] and sb["path"] and sa["walkable"] and sb["walkable"]

    def _reachability(self):
        """Cases praticables atteintes depuis le départ : à pied (paliers égaux, escaliers, rampes),
        puis en sautant aussi les marches d'un palier."""
        if self.spawn is None or self.problems:
            return
        start = self.spawn[1] * self.w + self.spawn[0]
        walk = self._reach(start, jump=False)
        jump = self._reach(start, jump=True)
        walkable = [c for c in range(self.w * self.d) if self.walkable(c)]
        lost = [c for c in walkable if c not in jump]
        hop = [c for c in walkable if c in jump and c not in walk]
        if lost:
            c = lost[0]
            self.warnings.append("%d case(s) praticable(s) hors d'atteinte du départ, dont (%d, %d)" % (len(lost), c % self.w, c // self.w))
        if hop:
            c = hop[0]
            self.warnings.append("%d case(s) qu'on n'atteint qu'en sautant une marche de %.1f m, dont (%d, %d)" % (len(hop), LEVEL_HEIGHT, c % self.w, c // self.w))

    def _reach(self, start, jump):
        seen = {start}
        todo = deque([start])
        while todo:
            c = todo.popleft()
            i, j = c % self.w, c // self.w
            for side, (dx, dz) in enumerate(DIRECTIONS):
                ni, nj = i + dx, j + dz
                if not self.in_map(ni, nj):
                    continue
                k = nj * self.w + ni
                if k in seen or not self.walkable(k) or not self._passable(c, k, side, jump):
                    continue
                seen.add(k)
                todo.append(k)
        return seen

    def _passable(self, c, k, side, jump):
        """Peut-on passer de la case c à sa voisine k (côté side) ?"""
        hc = self._edge_height(c, side)
        hk = self._edge_height(k, (side + 2) % 4)
        if hc is None or hk is None:
            return False
        if abs(hc - hk) < 1e-6:
            return True
        return jump and abs(hc - hk) <= LEVEL_HEIGHT + 1e-6

    def _edge_height(self, c, side):
        """Hauteur (m) du sol de la case c le long de son côté side (None : varie le long du côté,
        joue d'une volée)."""
        if self.kinds[c] == FLAT:
            return self.levels[c] * LEVEL_HEIGHT
        k, count, low, high, _start = self.run[c]
        if low is None or high is None:
            return None
        if side == self.dirs[c]:
            return (low + (high - low) * (k + 1) / count) * LEVEL_HEIGHT
        if side == (self.dirs[c] + 2) % 4:
            return (low + (high - low) * k / count) * LEVEL_HEIGHT
        return None

    def ok(self):
        return not self.problems


def all_maps():
    out = []
    if not os.path.isdir(DATA):
        return out
    for name in sorted(os.listdir(DATA)):
        path = os.path.join(DATA, name, "map.json")
        if os.path.isfile(path):
            try:
                if load_json(path).get("format") == FORMAT:
                    out.append(name)
            except (OSError, ValueError):
                out.append(name)
    return out


def cmd_check(map_ids):
    ids = map_ids or all_maps()
    failed = 0
    for map_id in ids:
        data = MapData(map_id)
        state = "ok" if data.ok() else "À REPRENDRE"
        print("%-24s %s" % (map_id, state))
        for problem in data.problems:
            print("  - " + problem)
        for warning in data.warnings:
            print("  ~ " + warning)
        failed += 0 if data.ok() else 1
    print("%d carte(s), %d à reprendre" % (len(ids), failed))
    return 1 if failed else 0


# --- Génération d'après un plan --------------------------------------------------------------------


def _value_noise(seed):
    rnd = random.Random(seed)
    table = [rnd.random() for _ in range(4096)]

    def lattice(i, j):
        return table[(i * 73856093 ^ j * 19349663) & 4095]

    def noise(x, z):
        i, j = math.floor(x), math.floor(z)
        fx, fz = x - i, z - j
        fx, fz = fx * fx * (3 - 2 * fx), fz * fz * (3 - 2 * fz)
        top = lattice(i, j) + (lattice(i + 1, j) - lattice(i, j)) * fx
        bottom = lattice(i, j + 1) + (lattice(i + 1, j + 1) - lattice(i, j + 1)) * fx
        return (top + (bottom - top) * fz) * 2 - 1

    return noise


def _segment_distance(px, pz, a, b):
    ax, az = a
    bx, bz = b
    vx, vz = bx - ax, bz - az
    length = vx * vx + vz * vz
    t = 0.0 if length == 0 else max(0.0, min(1.0, ((px - ax) * vx + (pz - az) * vz) / length))
    return math.hypot(px - ax - vx * t, pz - az - vz * t)


def _inside_polygon(px, pz, points):
    inside = False
    n = len(points)
    for k in range(n):
        x1, z1 = points[k]
        x2, z2 = points[(k + 1) % n]
        if (z1 > pz) != (z2 > pz) and px < (x2 - x1) * (pz - z1) / (z2 - z1) + x1:
            inside = not inside
    return inside


def shape_distance(shape, px, pz):
    """Distance signée (m) du point à la forme : négative dedans."""
    if "rect" in shape:
        x, z, w, d = shape["rect"]
        dx = max(x - px, px - (x + w))
        dz = max(z - pz, pz - (z + d))
        outside = math.hypot(max(dx, 0.0), max(dz, 0.0))
        return outside if outside > 0 else max(dx, dz)
    if "ellipse" in shape:
        cx, cz, rx, rz = shape["ellipse"]
        k = math.hypot((px - cx) / rx, (pz - cz) / rz)
        return (k - 1.0) * min(rx, rz)
    if "poly" in shape:
        points = shape["poly"]
        edge = min(_segment_distance(px, pz, points[k], points[(k + 1) % len(points)]) for k in range(len(points)))
        return -edge if _inside_polygon(px, pz, points) else edge
    if "band" in shape:
        points = shape["band"]
        edge = min(_segment_distance(px, pz, points[k], points[k + 1]) for k in range(len(points) - 1))
        return edge - shape.get("width", 2.0) / 2.0
    raise ValueError("forme inconnue : %s" % sorted(shape))


def shape_contains(shape, px, pz, noise):
    """Vrai si le point est dans la forme, bord bruité de shape["noise"] m (échelle noise_scale)."""
    amplitude = shape.get("noise", 0.0)
    distance = shape_distance(shape, px, pz)
    if amplitude > 0.0:
        scale = shape.get("noise_scale", 3.0)
        distance += amplitude * noise(px / scale + shape.get("seed", 0) * 17.3, pz / scale)
    return distance < 0.0


def _where_ok(step, level, material):
    where = step.get("where", {})
    if "level" in where and level != where["level"]:
        return False
    if "levels" in where and level not in where["levels"]:
        return False
    if "material" in where and material != where["material"]:
        return False
    if "not_material" in where and material in where["not_material"]:
        return False
    return True


def generate(map_id, plan_path=None):
    folder = os.path.join(DATA, map_id)
    plan = load_json(plan_path or os.path.join(folder, "plan.json"))
    lib = library()
    materials_lib = dict(lib["materials"])
    materials_lib.update(plan.get("materials", {}))
    w, d = plan["size"]
    scale = int(plan.get("materials_scale", 1))
    step_value = int(plan.get("height_step_value", DEFAULT_STEP_VALUE))
    noise = _value_noise(plan.get("seed", 1))
    base = plan.get("base", {})
    levels = [base.get("level", 0)] * (w * d)
    mats = [base.get("material", "herbe")] * (w * d * scale * scale)
    structures = [None] * (w * d)
    for step in plan.get("steps", []):
        op = step["op"]
        if op in ("stairs", "ramp"):
            x, z, sw, sd = step["rect"]
            for j in range(z, z + sd):
                for i in range(x, x + sw):
                    structures[j * w + i] = ("stairs" if op == "stairs" else "ramp", step["dir"])
                    if "material" in step:
                        for b in range(scale):
                            for a in range(scale):
                                mats[(j * scale + b) * w * scale + i * scale + a] = step["material"]
            continue
        shape = step.get("shape") or {"band": step["points"], "width": step.get("width", 2.0),
                                      "noise": step.get("noise", 0.0), "noise_scale": step.get("noise_scale", 3.0),
                                      "seed": step.get("seed", 0)}
        if op == "material" or op == "path":
            for y in range(d * scale):
                for x in range(w * scale):
                    px, pz = (x + 0.5) / scale, (y + 0.5) / scale
                    cell = (y // scale) * w + x // scale
                    p = y * w * scale + x
                    if _where_ok(step, levels[cell], mats[p]) and shape_contains(shape, px, pz, noise):
                        mats[p] = step["material"]
            continue
        for j in range(d):
            for i in range(w):
                c = j * w + i
                material = mats[(j * scale + scale // 2) * w * scale + i * scale + scale // 2]
                if not _where_ok(step, levels[c], material) or not shape_contains(shape, i + 0.5, j + 0.5, noise):
                    continue
                if op == "void":
                    levels[c] = None
                elif op == "level":
                    levels[c] = step["level"]
                elif op == "raise":
                    if levels[c] is not None:
                        levels[c] += step.get("by", 1)
                elif op == "face":
                    structures[c] = ("face", step["face"])
                else:
                    raise ValueError("opération inconnue : %s" % op)
    # Hauteur peinte sous une volée (ignorée par le jeu) : celle de la case du haut.
    table = {}
    for color, entry in lib["structures"].items():
        key = ("face", entry["face"]) if "face" in entry else (entry["kind"], entry["dir"])
        table[key] = hex_rgb(color)
    for c, entry in enumerate(structures):
        if entry is None or entry[0] == "face":
            continue
        dx, dz = DIRECTIONS[SIDES.index(entry[1])]
        i, j = c % w, c // w
        while 0 <= i < w and 0 <= j < d and structures[j * w + i] == entry:
            i, j = i + dx, j + dz
        if 0 <= i < w and 0 <= j < d and levels[j * w + i] is not None:
            levels[c] = levels[j * w + i]
    os.makedirs(folder, exist_ok=True)
    heights = Image.new("RGBA", (w, d), (0, 0, 0, 0))
    hp = heights.load()
    for c, level in enumerate(levels):
        if level is not None:
            v = max(0, min(255, level * step_value))
            hp[c % w, c // w] = (v, v, v, 255)
    heights.save(os.path.join(folder, "heights.png"), optimize=True)
    used = []
    image = Image.new("RGBA", (w * scale, d * scale), (0, 0, 0, 0))
    mp = image.load()
    for p, name in enumerate(mats):
        x, y = p % (w * scale), p // (w * scale)
        if levels[(y // scale) * w + x // scale] is None:
            continue
        if name not in materials_lib:
            raise ValueError("matière inconnue : %s" % name)
        if name not in used:
            used.append(name)
        mp[x, y] = hex_rgb(materials_lib[name]["color"]) + (255,)
    image.save(os.path.join(folder, "materials.png"), optimize=True)
    spec = {
        "_comment": "Sol en relief de la carte %s, écrit par tools/map_build.py gen d'après plan.json avec "
                    "heights.png, materials.png et structures.png : modifier le plan et relancer gen "
                    "(format : PLAN.md, « Format du sol des cartes extérieures »)." % map_id,
        "format": FORMAT,
        "version": VERSION,
        "size": [w, d],
        "heights_image": "heights.png",
        "height_step_value": step_value,
        "materials_image": "materials.png",
        "materials_scale": scale,
        "palette": {materials_lib[name]["color"]: name for name in used},
        "edges": {side: plan.get("edges", {}).get(side, "land") for side in SIDES},
        "skirt": plan.get("skirt", DEFAULT_SKIRT),
        "barrier": plan.get("barrier", True),
    }
    if plan.get("materials"):
        spec["materials"] = plan["materials"]
    if any(entry is not None for entry in structures):
        struct = Image.new("RGBA", (w, d), (0, 0, 0, 0))
        sp = struct.load()
        for c, entry in enumerate(structures):
            if entry is not None:
                sp[c % w, c // w] = table[entry] + (255,)
        struct.save(os.path.join(folder, "structures.png"), optimize=True)
        spec["structures_image"] = "structures.png"
    if "spawn" in plan:
        spec["spawn"] = plan["spawn"]
    with open(os.path.join(folder, "map.json"), "w", encoding="utf-8") as handle:
        handle.write(compact_json(spec) + "\n")
    return folder


def compact_json(value):
    """JSON indenté, listes de nombres sur une ligne."""
    text = json.dumps(value, ensure_ascii=False, indent=2)
    return re.sub(r"\[\s+([-0-9.,\s]+?)\s+\]", lambda m: "[" + ", ".join(v.strip() for v in m.group(1).split(",")) + "]", text)


def cmd_gen(map_id, plan_path):
    folder = generate(map_id, plan_path)
    print("carte générée : %s" % os.path.relpath(folder, ROOT))
    return cmd_check([map_id])


# --- Vue de dessus ----------------------------------------------------------------------------------


FONTS = ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/truetype/freefont/FreeSans.ttf",
         "/Library/Fonts/Arial.ttf", "C:/Windows/Fonts/arial.ttf"]


def font(size):
    """Police à accents (DejaVu Sans…), sinon celle de Pillow."""
    for path in FONTS:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


def tile_color(layer, cache={}):
    if layer not in cache:
        path = os.path.join(GROUND, layer + ".png")
        if os.path.exists(path):
            cache[layer] = Image.open(path).convert("RGB").resize((1, 1), Image.BOX).getpixel((0, 0))
        else:
            cache[layer] = (128, 128, 128)
    return cache[layer]


def _shade(rgb, factor):
    return tuple(max(0, min(255, round(v * factor))) for v in rgb[:3])


def _arrow(draw, x0, z0, x1, z1, color, width=2):
    draw.line((x0, z0, x1, z1), fill=color, width=width)
    angle = math.atan2(z1 - z0, x1 - x0)
    for side in (-1, 1):
        a = angle + math.pi + side * 0.5
        draw.line((x1, z1, x1 + 7 * math.cos(a), z1 + 7 * math.sin(a)), fill=color, width=width)


def render_view(data, scale=12, tiles=False):
    """Vue de dessus de la carte (Image) : couleurs de peinture des matières (ou, tiles, couleurs
    moyennes des tuiles de l'atlas), plus claires en montant ; falaises (roche, talus, muret) et
    leur ombre ; côte ; escaliers et rampes fléchés vers le haut ; départ ; légende."""
    w, d = data.w, data.d
    legend_w = 340
    title_h = 40
    width = w * scale + legend_w + 36
    height = max(d * scale + title_h + 24, 600)
    img = Image.new("RGB", (width, height), (24, 26, 34))
    draw = ImageDraw.Draw(img)
    big = font(17)
    small = font(13)
    ox, oz = 14, title_h
    levels = [lv for lv in data.levels if lv is not None] or [0]
    low, high = min(levels), max(levels)
    s = data.scale
    sub = scale / s
    # Sol : couleur de la matière, plus claire en montant.
    for y in range(d * s):
        for x in range(w * s):
            c = (y // s) * w + x // s
            x0, z0 = ox + x * sub, oz + y * sub
            if data.levels[c] is None:
                tone = (30, 36, 54) if ((x // 2) + (y // 2)) % 2 else (36, 43, 64)
                draw.rectangle((x0, z0, x0 + sub - 1, z0 + sub - 1), fill=tone)
                continue
            m = data.pixels[y * w * s + x]
            if m is None:
                rgb = (255, 0, 255)
            elif tiles:
                spec = data.specs[m]
                rgb = tuple(v * t for v, t in zip(tile_color(spec["layer"]), spec["tint"]))
            else:
                rgb = data.paint[m]
            level = data.levels[c] if data.kinds[c] == FLAT else data.levels[c] - 0.5
            lift = 0.0 if high == low else (level - low) / (high - low)
            draw.rectangle((x0, z0, x0 + sub - 1, z0 + sub - 1), fill=_shade(rgb, 0.7 + 0.5 * lift))
    # Ombre au pied des falaises, côté bas.
    band = max(2, scale // 4)
    for j in range(d):
        for i in range(w):
            c = j * w + i
            if data.levels[c] is None or data.kinds[c] != FLAT:
                continue
            for dx, dz in DIRECTIONS:
                ni, nj = i + dx, j + dz
                if not data.in_map(ni, nj):
                    continue
                k = nj * w + ni
                if data.levels[k] is None or data.kinds[k] != FLAT or data.levels[k] <= data.levels[c]:
                    continue
                x0, z0 = ox + i * scale, oz + j * scale
                box = {(1, 0): (x0 + scale - band, z0, x0 + scale, z0 + scale),
                       (-1, 0): (x0, z0, x0 + band, z0 + scale),
                       (0, 1): (x0, z0 + scale - band, x0 + scale, z0 + scale),
                       (0, -1): (x0, z0, x0 + scale, z0 + band)}[(dx, dz)]
                draw.rectangle(box, fill=(20, 18, 24))
    # Grille tous les 5 m, cotes tous les 10 m.
    for i in range(0, w + 1, 5):
        draw.line((ox + i * scale, oz, ox + i * scale, oz + d * scale),
                  fill=(250, 250, 250) if i % 10 == 0 else (150, 150, 150))
        if i % 10 == 0:
            draw.text((ox + i * scale + 2, oz + d * scale + 3), str(i), font=small, fill=(200, 200, 200))
    for j in range(0, d + 1, 5):
        draw.line((ox, oz + j * scale, ox + w * scale, oz + j * scale),
                  fill=(250, 250, 250) if j % 10 == 0 else (150, 150, 150))
    # Falaises : trait sur la ligne de la grille, épais selon la hauteur, couleur du style.
    for j in range(d):
        for i in range(w):
            c = j * w + i
            if data.levels[c] is None or data.kinds[c] != FLAT:
                continue
            for side in (1, 2):
                dx, dz = DIRECTIONS[side]
                ni, nj = i + dx, j + dz
                if not data.in_map(ni, nj):
                    continue
                k = nj * w + ni
                if data.levels[k] is None or data.kinds[k] != FLAT or data.levels[k] == data.levels[c]:
                    continue
                upper = c if data.levels[c] > data.levels[k] else k
                diff = abs(data.levels[c] - data.levels[k]) * LEVEL_HEIGHT
                style = data.faces[upper] or ("earth" if diff <= LEVEL_HEIGHT + 1e-6 else "rock")
                thick = max(3, min(6, round(diff * 2.5)))
                if side == 1:
                    x = ox + (i + 1) * scale
                    draw.line((x, oz + j * scale, x, oz + (j + 1) * scale), fill=FACE_COLORS[style], width=thick)
                else:
                    z = oz + (j + 1) * scale
                    draw.line((ox + i * scale, z, ox + (i + 1) * scale, z), fill=FACE_COLORS[style], width=thick)
    # Côte : liseré clair entre la terre et le vide.
    for j in range(d):
        for i in range(w):
            if data.is_void(i, j):
                continue
            for side, (dx, dz) in enumerate(DIRECTIONS):
                if data.is_void(i + dx, j + dz):
                    x0, z0 = ox + i * scale, oz + j * scale
                    edge = [(x0, z0, x0 + scale, z0), (x0 + scale, z0, x0 + scale, z0 + scale),
                            (x0, z0 + scale, x0 + scale, z0 + scale), (x0, z0, x0, z0 + scale)][side]
                    draw.line(edge, fill=(240, 228, 204), width=2)
    # Escaliers (marches) et rampes, flèche vers le haut.
    for c in range(w * d):
        if data.kinds[c] == FLAT or data.run[c] is None:
            continue
        i, j = c % w, c // w
        x0, z0 = ox + i * scale, oz + j * scale
        dx, dz = DIRECTIONS[data.dirs[c]]
        if data.kinds[c] == STAIRS:
            for t in range(0, 5):
                f = t / 5.0
                if dx == 0:
                    z = z0 + f * scale
                    draw.line((x0, z, x0 + scale, z), fill=(50, 42, 36))
                else:
                    x = x0 + f * scale
                    draw.line((x, z0, x, z0 + scale), fill=(50, 42, 36))
        k, count, _low, _high, start = data.run[c]
        if k == count - 1:
            ax0 = ox + (start[0] + 0.5) * scale - dx * 0.3 * scale
            az0 = oz + (start[1] + 0.5) * scale - dz * 0.3 * scale
            ax1 = ox + (i + 0.5) * scale + dx * 0.3 * scale
            az1 = oz + (j + 0.5) * scale + dz * 0.3 * scale
            _arrow(draw, ax0, az0, ax1, az1, (235, 40, 40) if data.kinds[c] == STAIRS else (60, 110, 240))
    if data.spawn is not None:
        sx, sz = ox + (data.spawn[0] + 0.5) * scale, oz + (data.spawn[1] + 0.5) * scale
        draw.ellipse((sx - 7, sz - 7, sx + 7, sz + 7), outline=(255, 60, 60), width=3)
    # Titre et légende.
    title = "%s : %d × %d m, paliers de %.1f m (%d à %d, soit %.1f à %.1f m)" % (
        data.map_id, w, d, LEVEL_HEIGHT, low, high, low * LEVEL_HEIGHT, high * LEVEL_HEIGHT)
    draw.text((ox, 10), title, font=big, fill=(240, 236, 226))
    lx = ox + w * scale + 18
    ly = oz
    draw.text((lx, ly), "↑ nord    grille : 5 m", font=small, fill=(220, 220, 220))
    ly += 26
    draw.text((lx, ly), "Matières", font=big, fill=(240, 236, 226))
    ly += 24
    for index, spec in enumerate(data.specs):
        if tiles:
            rgb = tuple(round(v * t) for v, t in zip(tile_color(spec["layer"]), spec["tint"]))
        else:
            rgb = data.paint[index]
        draw.rectangle((lx, ly + 1, lx + 18, ly + 14), fill=rgb, outline=(10, 10, 10))
        label = spec["label"] + ("" if spec["walkable"] else " (non praticable)")
        draw.text((lx + 26, ly), label, font=small, fill=(220, 220, 220))
        ly += 19
    ly += 10
    draw.text((lx, ly), "Relief", font=big, fill=(240, 236, 226))
    ly += 24
    for style, label in (("rock", "falaise de roche"), ("earth", "talus de terre"), ("wall", "muret")):
        draw.line((lx, ly + 8, lx + 18, ly + 8), fill=FACE_COLORS[style], width=5)
        draw.text((lx + 26, ly), label, font=small, fill=(220, 220, 220))
        ly += 19
    for color, label in (((235, 40, 40), "escalier (flèche vers le haut)"),
                         ((60, 110, 240), "rampe (flèche vers le haut)")):
        _arrow(draw, lx, ly + 8, lx + 18, ly + 8, color)
        draw.text((lx + 26, ly), label, font=small, fill=(220, 220, 220))
        ly += 19
    draw.line((lx, ly + 8, lx + 18, ly + 8), fill=(240, 228, 204), width=3)
    draw.text((lx + 26, ly), "côte (le vide au-delà)", font=small, fill=(220, 220, 220))
    ly += 19
    draw.ellipse((lx + 2, ly + 1, lx + 16, ly + 15), outline=(255, 60, 60), width=3)
    draw.text((lx + 26, ly), "départ (spawn)", font=small, fill=(220, 220, 220))
    ly += 19
    draw.text((lx, ly), "plus clair = plus haut ; ombre au pied des faces", font=small, fill=(200, 200, 200))
    ly += 28
    for problem in data.problems[:6]:
        for line in _wrap("! " + problem, 44):
            draw.text((lx, ly), line, font=small, fill=(255, 120, 100))
            ly += 16
    for warning in data.warnings[:4]:
        for line in _wrap("~ " + warning, 44):
            draw.text((lx, ly), line, font=small, fill=(250, 210, 120))
            ly += 16
    return img


def _wrap(text, width):
    """Coupe text en lignes de width caractères au plus (suites en retrait)."""
    lines = []
    line = ""
    for word in text.split():
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = "  " + word
        else:
            line = word if not line else line + " " + word
    if line:
        lines.append(line)
    return lines


def cmd_view(map_id, out, scale, tiles=False):
    data = MapData(map_id)
    if data.w <= 0:
        for problem in data.problems:
            print("  - " + problem)
        return 1
    out = out or os.path.join(ROOT, "build", "maps", "%s_dessus.png" % map_id)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    render_view(data, scale, tiles).save(out)
    print("vue de dessus : %s" % out)
    return 0 if data.ok() else 1


def main():
    global DATA
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--root", default=DATA,
                        help="dossier des cartes (défaut : data/maps ; les tests : tests/data/maps)")
    sub = parser.add_subparsers(dest="command", required=True)
    check = sub.add_parser("check", help="vérifie les cartes (toutes si aucune)")
    check.add_argument("maps", nargs="*")
    gen = sub.add_parser("gen", help="génère une carte d'après son plan")
    gen.add_argument("map")
    gen.add_argument("--plan", default=None, help="plan (défaut : data/maps/<carte>/plan.json)")
    view = sub.add_parser("view", help="vue de dessus en PNG")
    view.add_argument("map")
    view.add_argument("--out", default=None)
    view.add_argument("--scale", type=int, default=12, help="pixels par mètre")
    view.add_argument("--tiles", action="store_true",
                      help="couleurs moyennes des tuiles au lieu des couleurs de peinture")
    args = parser.parse_args()
    DATA = os.path.abspath(args.root)
    if args.command == "check":
        return cmd_check(args.maps)
    if args.command == "gen":
        return cmd_gen(args.map, args.plan)
    return cmd_view(args.map, args.out, args.scale, args.tiles)


if __name__ == "__main__":
    sys.exit(main())
