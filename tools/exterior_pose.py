"""(C1) Le moteur de pose des cartes du dehors : ce que tools/exterior_maps.py emploie pour poser un
décor d'après le plan de docs/lore/CARTE.md. Rien ici n'écrit de fichier.

Un `Pose` rassemble, pour une carte :
- le plan (bords, bâtiments, places, points, marqueurs, sorties, chemins) et le sol construit
  (data/maps/<id>/, relu par tools/map_build.py) pour connaître la hauteur exacte du sol ;
- le catalogue des décors (scènes de src/world/props/ : image, taille, emprise qui bloque) ;
- la règle de caméra (CARTE.md 0.3) : un décor qui se dresse au-dessus de la tête du joueur (1,4 m)
  devant une case où l'on marche prend sa variante de premier plan (qui s'efface autour du
  joueur), ou n'est pas posé, et l'on en avertit ;
- `place` (un décor), `scatter` (une famille posée par un PropScatter), `poisson`, `along` (points
  tirés au hasard, graine fixe : la scène écrite est la même à chaque appel) ;
- les décors posés (`singles`, `families`), les emprises qui bloquent (`blockers`) et les
  avertissements (`warnings`).
"""

import math
import os
import random
import re

from PIL import Image

import map_build

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROPS_DIR = os.path.join(ROOT, "src", "world", "props")
CAMERA = 1.0 / math.tan(math.radians(32.0))
HEAD = 1.4
WALK_STEP = 0.5


class Prop:
    """Une scène de src/world/props/ : l'image, sa taille en m, l'emprise qui bloque."""

    def __init__(self, name):
        self.name = name
        path = os.path.join(PROPS_DIR, name + ".tscn")
        if not os.path.exists(path):
            raise SystemExit("décor %s absent de src/world/props/ (exterior_props.py, ou à écrire)" % name)
        text = open(path, encoding="utf-8").read()
        base = re.search(r'path="res://src/world/props/([^"]+)\.tscn"', text)
        self.fg = "foreground = true" in text
        if base and "decor_panel.gd" not in text and "building.gd" not in text and "ground_decal" not in text:
            parent = Prop(base.group(1))
            self.__dict__.update({k: v for k, v in parent.__dict__.items() if k not in ("name", "fg")})
            self.fg = self.fg or parent.fg
            return
        self.decal = "ground_decal.gd" in text
        self.building = "building.gd" in text
        image = re.search(r'path="res://(assets/[^"]+\.png)"', text)
        frames = re.search(r"\nframes = (\d+)", text)
        f = int(frames.group(1)) if frames else 1
        self.image = image.group(1) if image else ""
        if self.image:
            img = Image.open(os.path.join(ROOT, self.image))
            self.w, self.h = img.width / f / 96.0, img.height / 96.0
        else:
            self.w = self.h = 0.0
        self.frames = f
        self.blocks = "Collision" in text
        # Emprise bloquante (demi-largeur x, demi-profondeur z), d'après les formes de la scène.
        box = re.findall(r"size = Vector3\(([-\d.e]+), ([-\d.e]+), ([-\d.e]+)\)", text)
        radius = re.findall(r"radius = ([\d.]+)", text)
        poles = re.findall(r"Transform3D\(1, 0, 0, 0, 1, 0, 0, 0, 1, ([-\d.]+), [-\d.]+, [-\d.]+\)", text)
        if not self.blocks:
            self.half = (0.0, 0.0)
        elif box:
            self.half = (max(float(b[0]) for b in box) / 2.0, max(float(b[2]) for b in box) / 2.0)
        elif radius:
            r = max(float(v) for v in radius)
            spread = max([abs(float(p)) for p in poles] + [0.0])
            self.half = (r + spread, r)
        else:
            self.half = (0.3, 0.3)


_CATALOG = {}


def prop(name):
    if name not in _CATALOG:
        _CATALOG[name] = Prop(name)
    return _CATALOG[name]


def forget_catalog():
    """Relit les scènes (après que exterior_props.py en a écrit)."""
    _CATALOG.clear()
    FOREGROUND.clear()
    FOREGROUND.update(foreground_variants())


def foreground_variants():
    """Variantes de premier plan : décor → scène (« <décor>_forest » ou « <décor>_fg »)."""
    found = {}
    for name in sorted(os.listdir(PROPS_DIR)):
        if name.endswith("_forest.tscn") or name.endswith("_fg.tscn"):
            base = name[:-len("_forest.tscn")] if name.endswith("_forest.tscn") else name[:-len("_fg.tscn")]
            text = open(os.path.join(PROPS_DIR, name), encoding="utf-8").read()
            if os.path.exists(os.path.join(PROPS_DIR, base + ".tscn")) and "foreground = true" in text:
                found.setdefault(base, name[:-5])
    return found


FOREGROUND = foreground_variants()


class Rect:
    def __init__(self, x0, z0, x1, z1):
        self.x0, self.z0, self.x1, self.z1 = min(x0, x1), min(z0, z1), max(x0, x1), max(z0, z1)

    def has(self, x, z, margin=0.0):
        return self.x0 - margin <= x <= self.x1 + margin and self.z0 - margin <= z <= self.z1 + margin

    def hits(self, o, margin=0.0):
        return self.x0 - margin < o.x1 and o.x0 < self.x1 + margin and self.z0 - margin < o.z1 and o.z0 < self.z1 + margin


def R(r):
    return Rect(r.x0, r.z0, r.x1, r.z1)


def seg_distance(px, pz, a, b):
    (ax, az), (bx, bz) = a, b
    vx, vz = bx - ax, bz - az
    n = vx * vx + vz * vz
    t = 0.0 if n == 0 else max(0.0, min(1.0, ((px - ax) * vx + (pz - az) * vz) / n))
    return math.hypot(px - ax - vx * t, pz - az - vz * t)


def poisson(area, spacing, count_max, ok, seed, tries=40):
    """Points tirés dans area (Rect) à spacing m les uns des autres, acceptés par ok(x, z)."""
    r = random.Random(seed)
    pts = []
    attempts = 0
    while len(pts) < count_max and attempts < count_max * tries:
        attempts += 1
        x = r.uniform(area.x0, area.x1)
        z = r.uniform(area.z0, area.z1)
        if any((x - px) ** 2 + (z - pz) ** 2 < spacing * spacing for px, pz in pts):
            continue
        if ok(x, z):
            pts.append((x, z))
    return pts


def along(points, step, offset, jitter, seed, with_yaw=False):
    """Points le long d'une polyligne, décalés de offset m à gauche et à droite ; with_yaw : avec
    le lacet (degrés) qui aligne l'axe x d'un décalque sur le chemin."""
    r = random.Random(seed)
    out = []
    for k in range(len(points) - 1):
        (ax, az), (bx, bz) = points[k], points[k + 1]
        length = math.hypot(bx - ax, bz - az)
        if length == 0:
            continue
        ux, uz = (bx - ax) / length, (bz - az) / length
        nx, nz = -uz, ux
        yaw = math.degrees(math.atan2(-uz, ux))
        t = r.uniform(0, step)
        while t < length:
            for side in (-1, 1):
                o = offset + r.uniform(-jitter, jitter)
                jx, jz = (0.0, 0.0) if with_yaw else (r.uniform(-0.3, 0.3), r.uniform(-0.3, 0.3))
                p = (ax + ux * t + nx * o * side + jx, az + uz * t + nz * o * side + jz)
                out.append(p + ((yaw + (180.0 if side > 0 else 0.0)),) if with_yaw else p)
            t += step * r.uniform(0.7, 1.3)
    return out


class Pose:
    """Une carte du dehors en cours de pose (voir l'en-tête)."""

    def __init__(self, plan_map, ground=None, seed=68):
        self.map = plan_map
        self.id = plan_map.id
        self.W, self.D = int(plan_map.w), int(plan_map.d)
        self.ground = ground or map_build.MapData(self.id)
        if not self.ground.ok():
            raise SystemExit("%s : sol invalide (%s)" % (self.id, self.ground.problems))
        self.rng = random.Random(seed)
        self.edges = [R(b.rect) for b in plan_map.borders]
        self.buildings = [R(b.rect) for b in plan_map.buildings]
        self.places = {p.name: R(p.rect) for p in plan_map.places}
        self.points = {n: (p.rect.x0, p.rect.z0) for n, p in plan_map.points.items()}
        self.markers = {n: (p.rect.x0, p.rect.z0) for n, p in plan_map.markers.items()}
        self.exits = [R(e.rect) for e in plan_map.exits]
        self.paths = [(p.name, p.extra["l"], p.extra["pts"]) for p in plan_map.paths]
        self.blockers = []  # Rect des emprises bloquantes posées
        self.singles = []  # (groupe, nom, scène, x, y, z, échelle, flip, extra)
        self.families = {}  # nom de famille → {scenes, points, seed, scale}
        self.counts = {}
        self.warnings = []
        self._walk = {}
        # (QC2) Les places où l'on se tient en plus du plan et les bornes du point visé (clear_of_places) ;
        # exterior_maps.build les donne avant la pose.
        self.standing_extra = []
        self.view_bounds = None
        self._stands = None

    # --- Sol --------------------------------------------------------------------------------

    def height(self, x, z):
        """Hauteur exacte du sol (cases plates et rampes)."""
        ground = self.ground
        i, j = int(math.floor(x)), int(math.floor(z))
        i = min(max(i, 0), self.W - 1)
        j = min(max(j, 0), self.D - 1)
        c = j * self.W + i
        if ground.kinds[c] == map_build.FLAT:
            # Le vide (case sans palier : le bord de l'île) n'a pas de sol ; un décor qui y est posé donne son y.
            return 0.0 if ground.levels[c] is None else ground.levels[c] * 0.5
        k, count, low, high, _start = ground.run[c]
        d = ground.dirs[c]
        t = {0: (j + 1) - z, 1: x - i, 2: z - j, 3: (i + 1) - x}[d]
        s = k + min(max(t, 0.0), 1.0)
        return (low + (high - low) * s / count) * 0.5

    # --- Ce qui bloque, ce qui doit rester libre ----------------------------------------------

    def path_distance(self, x, z):
        """Distance au bord de la bande libre du chemin le plus proche (négative dedans)."""
        best = 99.0
        for _name, width, pts in self.paths:
            for k in range(len(pts) - 1):
                best = min(best, seg_distance(x, z, pts[k], pts[k + 1]) - width / 2.0)
        return best

    def in_map(self, x, z, margin=0.0):
        return margin <= x <= self.W - margin and margin <= z <= self.D - margin

    def walkable_here(self, x, z):
        if not self.in_map(x, z, 0.35):
            return False
        for e in self.edges + self.buildings:
            if e.has(x, z, 0.3):
                return False
        for b in self.blockers:
            if b.has(x, z, 0.3):
                return False
        return True

    def keep_out(self, x, z, half, blocking, places=True, paths=True, decal=False):
        """Vrai si un décor d'emprise half (demi-largeur, demi-profondeur) ne peut pas aller en (x, z)."""
        box = Rect(x - half[0], z - half[1], x + half[0], z + half[1])
        if blocking:
            for e in self.exits:
                if e.hits(box, 1.2):
                    return True
            for mx, mz in self.markers.values():
                if box.has(mx, mz, 1.6):
                    return True
            for px, pz in self.points.values():
                if box.has(px, pz, 1.0):
                    return True
            for b in self.buildings:
                if b.hits(box, 0.4):
                    return True
            for b in self.blockers:
                if b.hits(box, 0.6):
                    return True
        if places and not decal:
            for p in self.places.values():
                if p.hits(box, 0.2):
                    return True
        if paths and self.path_distance(x, z) < (max(half) if blocking else 0.1):
            return True
        return False

    def free(self, blocking=False, decal=False, places=True, paths=True, half=(0.4, 0.3)):
        """Test de pose pour poisson() : le point est dans la carte et rien ne l'interdit."""
        def ok(x, z):
            if not self.in_map(x, z, 0.2):
                return False
            return not self.keep_out(x, z, half, blocking, places=places, paths=paths, decal=decal)
        return ok

    def outside_edges(self, x, z, margin=0.0):
        return not any(e.has(x, z, margin) for e in self.edges)

    # --- La règle de caméra -------------------------------------------------------------------

    def walk_grid(self):
        self._walk.clear()
        nx, nz = int(self.W / WALK_STEP), int(self.D / WALK_STEP)
        for a in range(nx):
            for b in range(nz):
                x, z = (a + 0.5) * WALK_STEP, (b + 0.5) * WALK_STEP
                self._walk[(a, b)] = self.walkable_here(x, z)

    def hides_someone(self, x, z, y, w, h):
        """Vrai si un panneau de largeur w, haut de h (pied à y) en (x, z) cache la tête d'un joueur
        sur une case praticable au nord de lui (CARTE.md 0.3)."""
        top = y + h
        reach = CAMERA * (top - (min(y, 0.0) - 0.5 + HEAD))
        if reach <= 0.3:
            return False
        a0 = int(max(0.0, x - w / 2.0) / WALK_STEP)
        a1 = int(min(self.W - 0.01, x + w / 2.0) / WALK_STEP)
        b0 = int(max(0.0, z - reach - 0.2) / WALK_STEP)
        b1 = int(max(0.0, z - 0.25) / WALK_STEP)
        for a in range(a0, a1 + 1):
            for b in range(b0, b1 + 1):
                if not self._walk.get((a, b), False):
                    continue
                cx, cz = (a + 0.5) * WALK_STEP, (b + 0.5) * WALK_STEP
                ground = self.height(cx, cz)
                if z - cz < CAMERA * (top - (ground + HEAD)):
                    return True
        return False

    # --- Pose -------------------------------------------------------------------------------------

    def clear_of_places(self, scenes, points, scale=1.0):
        """(QC2) Les points où aucune des scènes ne masque une place (clear_of_places, plus bas)."""
        return clear_of_places(self, scenes, points, scale)

    def place(self, group, scene, x, z, y=None, scale=1.0, flip=False, name=None, extra=None, check=True):
        p = prop(scene)
        if y is None:
            y = self.height(x, z)
        if check and not p.decal and not p.fg and p.h * scale > 1.2:
            if self.hides_someone(x, z, y, p.w * scale, p.h * scale):
                fg = FOREGROUND.get(scene)
                if fg is None:
                    self.warnings.append("%s en (%.1f ; %.1f) cache un passage, sans premier plan" % (scene, x, z))
                else:
                    scene = fg
        self.counts[group] = self.counts.get(group, 0) + 1
        node = name or "%s_%d" % (scene, self.counts[group])
        self.singles.append((group, node, scene, x, y, z, scale, flip, extra or {}))
        if prop(scene).blocks:
            hx, hz = prop(scene).half
            self.blockers.append(Rect(x - hx * scale, z - hz * scale, x + hx * scale, z + hz * scale))
        return scene

    def scatter(self, family, scenes, points, scale=(0.85, 1.15), seed=0, check=True):
        """Famille posée par un PropScatter : les points (x, z) au sol ; les grands décors qui cachent un
        passage passent en premier plan (une famille à part)."""
        keep, front = [], []
        for point in points:
            x, z = point[0], point[1]
            if check:
                tallest = max(prop(s).h for s in scenes) * scale[1]
                widest = max(prop(s).w for s in scenes) * scale[1]
                if tallest > 1.2 and self.hides_someone(x, z, self.height(x, z), widest, tallest):
                    front.append(point)
                    continue
            keep.append(point)
        if keep:
            self.families[family] = {"scenes": scenes, "points": keep, "seed": seed, "scale": scale}
        if front:
            fg = [FOREGROUND.get(s) for s in scenes]
            if all(fg):
                self.families[family + "Front"] = {"scenes": fg, "points": front, "seed": seed + 500, "scale": scale}
            else:
                self.warnings.append("%d point(s) de %s retirés (cachent un passage)" % (len(front), family))
        for s in scenes:
            if prop(s).blocks:
                hx, hz = max(prop(t).half[0] for t in scenes), max(prop(t).half[1] for t in scenes)
                for point in keep + front:
                    x, z = point[0], point[1]
                    self.blockers.append(Rect(x - hx * scale[1], z - hz * scale[1], x + hx * scale[1],
                                              z + hz * scale[1]))
                break


# --- Les bouts de pans à raccord (QC-S) ------------------------------------------------------------
#
# Un pan « à raccord » (manifeste : wrap x, comme les murs de forêt forest_wall_* et les rideaux
# treeline_*) est peint pour se continuer bord à bord : sa colonne de bord est pleine, un arbre coupé
# net sur 6 m de haut. Posé seul, son bout se voit comme une bande verticale à bord franc plaquée sur
# le décor (docs/QUALITE.md, QC-33). Un bout est sûr s'il touche le bout d'un autre pan à raccord du
# même rang, s'il reste hors du champ de la caméra, ou si un décor posé devant lui, opaque à cet
# endroit, le cache.

MANIFEST = os.path.join(ROOT, "tools", "hd2d_manifest.json")
# Hauteur pleine au bord (m) à partir de laquelle un bout se lit comme une bande coupée : les haies, les
# clôtures et les rideaux de roseaux, plus bas, se lisent comme une rangée qui finit.
SEAM_MIN_HEIGHT = 2.0
# La caméra du jeu (src/player/camera_rig.gd) : tangage, champ vertical (degrés), distances du zoom (la
# plus lointaine voit le plus large), point visé à 0,8 m au-dessus du sol, borné par camera_bounds ;
# écran 16:9.
SEAM_PITCH = 32.0
SEAM_FOV = 30.0
SEAM_DISTANCES = (21.0, 25.0)
SEAM_FOCUS_HEIGHT = 0.8
SEAM_ASPECT = 16.0 / 9.0
# Deux bouts qui se touchent (m) ; même rang (écart en z et en hauteur, m).
SEAM_JOIN = 0.3
SEAM_ROW = 0.6
# Longueur de bord visible d'un tenant (m) qui fait une bande : un trou d'épingle dans une couronne posée
# devant ne compte pas.
SEAM_MIN_RUN = 0.4
_WRAP_X = []
_ALPHA = {}


def wrap_x_images():
    """Chemins (assets/…) des images à raccord gauche-droite du manifeste."""
    if not _WRAP_X:
        import json
        with open(MANIFEST, encoding="utf-8") as handle:
            images = json.load(handle)["images"]
        _WRAP_X.append({e["path"] for e in images if e.get("wrap") == "x"})
    return _WRAP_X[0]


def _alpha(image):
    """(largeur, hauteur, accès aux pixels de l'alpha) d'une image du dépôt."""
    if image not in _ALPHA:
        img = Image.open(os.path.join(ROOT, image)).convert("RGBA").getchannel("A")
        _ALPHA[image] = (img.width, img.height, img.load())
    return _ALPHA[image]


def seam_panel(name, scene, x, y, z, scale=1.0, flip=False):
    """Un panneau pour open_seams : (nom, image, x, y, z, largeur, hauteur, retourné), None sans image
    debout (décalque, bâtiment, bande animée)."""
    p = prop(scene)
    if not p.image or p.decal or p.building or p.frames > 1:
        return None
    return (name, p.image, x, y, z, p.w * scale, p.h * scale, flip)


def focus_points(bounds, size, walkable, step=1.0, ahead=2.5):
    """Points visés (x, z) que le jeu peut prendre : ceux des cases où l'on marche (walkable(x, z)) d'une
    carte de size = (largeur, profondeur) m, le point visé à ahead m au nord du joueur, ramené dans les
    bornes (x, z, largeur, profondeur)."""
    bx, bz, bw, bd = bounds
    out = set()
    x = step / 2.0
    while x < size[0]:
        z = step / 2.0
        while z < size[1]:
            if walkable(x, z):
                out.add((round(min(max(x, bx), bx + bw), 2), round(min(max(z - ahead, bz), bz + bd), 2)))
            z += step
        x += step
    return sorted(out)


def _cameras(focus, height):
    """(point visé x, z, distance, position de la caméra) pour chaque point visé, à chaque distance du
    zoom."""
    s, c = math.sin(math.radians(SEAM_PITCH)), math.cos(math.radians(SEAM_PITCH))
    out = []
    for fx, fz in focus:
        fy = height(fx, fz) + SEAM_FOCUS_HEIGHT
        for d in SEAM_DISTANCES:
            out.append((fx, fz, d, (fx, fy + d * s, fz + d * c)))
    return out


def _on_screen(cam, px, py, pz):
    s, c = math.sin(math.radians(SEAM_PITCH)), math.cos(math.radians(SEAM_PITCH))
    vx, vy, vz = px - cam[0], py - cam[1], pz - cam[2]
    depth = -vy * s - vz * c
    if depth <= 0.1:
        return False
    up = vy * c - vz * s
    half = math.tan(math.radians(SEAM_FOV / 2.0))
    return abs(up) <= depth * half and abs(vx) <= depth * half * SEAM_ASPECT


def _hidden(cam, px, py, pz, occluders):
    """Vrai si un pixel opaque d'un panneau posé devant le point (px, py, pz) le cache à la caméra."""
    for _name, image, ox, oy, oz, ow, oh, oflip in occluders:
        if not pz < oz < cam[2]:
            continue
        t = (oz - cam[2]) / (pz - cam[2])
        qx, qy = cam[0] + (px - cam[0]) * t, cam[1] + (py - cam[1]) * t
        u, v = (qx - ox) / ow + 0.5, (qy - oy) / oh
        if not (0.0 <= u < 1.0 and 0.0 <= v < 1.0):
            continue
        w, h, alpha = _alpha(image)
        col = min(int((1.0 - u if oflip else u) * w), w - 1)
        row = min(int((1.0 - v) * h), h - 1)
        if alpha[col, row] > 128:
            return True
    return False


def open_seams(panels, focus, height=lambda x, z: 0.0, width=None):
    """Bouts de pans à raccord qui se voient : [(nom, côté, x du bout, z, point visé (x, z))], d'après
    les panneaux posés (seam_panel), les points visés possibles (focus_points) et la hauteur du sol.
    Un bout posé au bord de la carte (x ≤ 0,5 ou ≥ width − 0,5 m) ne compte qu'au cadrage par défaut :
    au zoom le plus lointain, le bord du monde se voit de toute façon."""
    panels = [q for q in panels if q is not None]
    wraps = [q for q in panels if q[1] in wrap_x_images()]
    cams = None
    found = []
    for name, image, x, y, z, pw, ph, flip in wraps:
        w, h, alpha = _alpha(image)
        for side, x_end in (("ouest", x - pw / 2.0), ("est", x + pw / 2.0)):
            col = (w - 1 if side == "ouest" else 0) if flip else (0 if side == "ouest" else w - 1)
            rows = [r for r in range(0, h, 4) if alpha[col, r] > 128]
            if len(rows) * 4 * ph / h < SEAM_MIN_HEIGHT:
                continue
            if any(o[0] != name and abs(o[4] - z) <= SEAM_ROW and abs(o[3] - y) <= SEAM_ROW
                   and min(abs(o[2] - o[5] / 2.0 - x_end), abs(o[2] + o[5] / 2.0 - x_end)) <= SEAM_JOIN
                   for o in wraps):
                continue
            if cams is None:
                cams = _cameras(focus, height)
            inward = 0.05 if side == "ouest" else -0.05
            # Ce qui est sous le sol, au pied du bout (un pan posé plus bas que le relief), ne se voit pas.
            ground = height(x_end, z)
            pts = [(x_end + inward, y + (h - r) * ph / h, z) for r in rows[::2] if y + (h - r) * ph / h > ground]
            front = [o for o in panels if o[4] > z + 0.01 and abs(o[2] - x_end) < o[5] / 2.0 + 4.0]
            edge = width is not None and (x_end <= 0.5 or x_end >= width - 0.5)
            run = max(1, int(round(SEAM_MIN_RUN * h / (8.0 * ph))))
            for fx, fz, d, cam in cams:
                if edge and d != SEAM_DISTANCES[0]:
                    continue
                seen = 0
                for pt in pts:
                    seen = seen + 1 if _on_screen(cam, *pt) and not _hidden(cam, *pt, front) else 0
                    if seen >= run:
                        break
                if seen >= run:
                    found.append((name, side, x_end, z, (fx, fz)))
                    break
    return found


def pose_seams(pose, bounds):
    """open_seams pour une carte posée, d'après ses décors uniques (les familles d'un PropScatter ne
    cachent rien ici : leur variante, leur taille et leur sens se tirent au lancement)."""
    panels = [seam_panel(name, scene, x, y, z, scale, flip)
              for _group, name, scene, x, y, z, scale, flip, _extra in pose.singles]
    return open_seams(panels, focus_points(bounds, (pose.W, pose.D), pose.walkable_here), pose.height, pose.W)


# --- Les places masquées par un grand décor (QC2) ----------------------------------------------------
#
# (QC2) Un grand décor posé au sud d'une place où le joueur ou un habitant se tient (sur un chemin, un
# point ou une place du plan, un marqueur d'arrivée, une place de la vie, une vue de la série QC) la
# cache à la caméra : l'érable rouge de premier plan qui couvrait Chtholly au sentier, le grand tronc
# qui fendait l'écran à côté d'elle à la colline (docs/QUALITE.md, QC-37 et QC-38). Sa variante de
# premier plan ne suffit pas : elle ne s'efface qu'autour du joueur, en trame, et jamais autour d'un
# habitant. Règle : aucun décor de 2 m ou plus ne couvre, de ses pixels opaques, la place d'un
# personnage debout (1 m de part et d'autre de lui, du pied à la tête), vue de la caméra du jeu au
# cadrage par défaut. Les décors d'une famille (PropScatter) comptent pour chacune de leurs variantes,
# à leur plus grande taille : la variante se tire au lancement.

MASK_MIN_HEIGHT = 2.0
# La place d'un personnage : colonnes (m, de part et d'autre de lui) et hauteurs (m au-dessus du sol).
MASK_BODY_X = (-1.0, -0.5, 0.0, 0.5, 1.0)
MASK_BODY_Y = (0.25, 0.75, 1.25)
# Points cachés à partir desquels la place est masquée : une colonne entière (un tronc qui frôle le
# personnage) ou le tiers de sa silhouette.
MASK_MIN_HIDDEN = 3
# Le long des chemins, un point par mètre. Près d'une sortie (m : le marqueur d'arrivée est à 2 ou 3 m
# d'elle), on ne fait que passer : on entre et on sort sous la lisière, sous la voûte des arbres qui
# couvrent les bouts des pans à raccord (QC-34) ; ces places-là ne comptent pas.
MASK_PATH_STEP = 1.0
MASK_EXIT_MARGIN = 4.5


def standing_places(pose, extra=()):
    """Les places où quelqu'un se tient : [(nom, x, z)] : marqueurs, points et places (leur centre) du
    plan, le milieu des chemins (un point par mètre), puis extra (places de la vie, vues de la série QC) ;
    sauf près d'une sortie."""
    out = [("marqueur %s" % n, x, z) for n, (x, z) in sorted(pose.markers.items())]
    out += [("point %s" % n, x, z) for n, (x, z) in sorted(pose.points.items())]
    out += [("place %s" % n, (r.x0 + r.x1) / 2.0, (r.z0 + r.z1) / 2.0) for n, r in sorted(pose.places.items())]
    for name, _width, pts in pose.paths:
        for k in range(len(pts) - 1):
            (ax, az), (bx, bz) = pts[k], pts[k + 1]
            n = max(1, int(math.hypot(bx - ax, bz - az) / MASK_PATH_STEP))
            for i in range(n + (1 if k == len(pts) - 2 else 0)):
                out.append(("chemin %s" % name, ax + (bx - ax) * i / n, az + (bz - az) * i / n))
    out += list(extra)
    return [q for q in out if pose.in_map(q[1], q[2], 0.3)
            and not any(e.has(q[1], q[2], MASK_EXIT_MARGIN) for e in pose.exits)]


def _mask_panels(pose):
    """Les grands décors posés (panneaux de open_seams, avec leur scène) : uniques et familles."""
    out = []
    for _group, name, scene, x, y, z, scale, flip, _extra in pose.singles:
        q = seam_panel(name, scene, x, y, z, scale, flip)
        if q is not None and q[6] >= MASK_MIN_HEIGHT:
            out.append((q, scene))
    for family, spec in pose.families.items():
        for point in spec["points"]:
            x, z = point[0], point[1]
            for scene in spec["scenes"]:
                for flip in (False, True):
                    q = seam_panel("%s (%.1f ; %.1f)" % (family, x, z), scene, x, pose.height(x, z), z,
                                   spec["scale"][1], flip)
                    if q is not None and q[6] >= MASK_MIN_HEIGHT:
                        out.append((q, scene))
    return out


def _stand_cameras(pose, bounds, extra):
    """[(place, x, y, z, caméra)] : chaque place où l'on se tient, avec la caméra du jeu quand le joueur y
    est (point visé 2,5 m au nord, borné ; cadrage par défaut)."""
    bx, bz, bw, bd = bounds
    s, c = math.sin(math.radians(SEAM_PITCH)), math.cos(math.radians(SEAM_PITCH))
    d = SEAM_DISTANCES[0]
    out = []
    for label, cx, cz in standing_places(pose, extra):
        fx, fz = min(max(cx, bx), bx + bw), min(max(cz - 2.5, bz), bz + bd)
        fy = pose.height(fx, fz) + SEAM_FOCUS_HEIGHT
        out.append((label, cx, pose.height(cx, cz), cz, (fx, fy + d * s, fz + d * c)))
    return out


def _masks(panel, stand):
    """Vrai si le panneau couvre la place d'un personnage debout là (voir plus haut)."""
    _label, cx, cy, cz, cam = stand
    if not cz + 0.05 < panel[4] < cam[2] or abs(panel[2] - cx) > panel[5] / 2.0 + MASK_BODY_X[-1]:
        return False
    hidden = 0
    for dx in MASK_BODY_X:
        for hy in MASK_BODY_Y:
            if _hidden(cam, cx + dx, cy + hy, cz, [panel]):
                hidden += 1
                if hidden >= MASK_MIN_HIDDEN:
                    return True
    return False


def clear_of_places(pose, scenes, points, scale=1.0):
    """(QC2) Les points (x, z) où aucune des scènes (à l'échelle scale, dans les deux sens) ne masque une
    place : pour tirer une famille de grands arbres sans en poser un devant un chemin. Les places sont
    celles de la carte posée (pose.standing_extra, pose.view_bounds : écrits par exterior_maps.build)."""
    if pose.view_bounds is None:
        return list(points)
    if pose._stands is None:
        pose._stands = _stand_cameras(pose, pose.view_bounds, pose.standing_extra)
    keep = []
    for point in points:
        x, z = point[0], point[1]
        panels = [seam_panel("", scene, x, pose.height(x, z), z, scale, flip) for scene in scenes
                  for flip in (False, True)]
        panels = [q for q in panels if q is not None and q[6] >= MASK_MIN_HEIGHT]
        if not any(_masks(q, stand) for q in panels for stand in pose._stands):
            keep.append(point)
    return keep


def masked_places(pose, bounds, extra=()):
    """Les grands décors qui masquent une place (voir plus haut) : [(décor, scène, x, z, [places])], d'après
    la carte posée, les bornes du point visé (x, z, largeur, profondeur) et les places en plus."""
    stands = _stand_cameras(pose, bounds, extra)
    found = {}
    for q, scene in _mask_panels(pose):
        for stand in stands:
            if _masks(q, stand):
                key = (q[0], scene, round(q[2], 1), round(q[4], 1))
                found.setdefault(key, [])
                if stand[0] not in found[key]:
                    found[key].append(stand[0])
    return [(k[0], k[1], k[2], k[3], v) for k, v in sorted(found.items())]
