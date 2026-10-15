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

    # --- Sol --------------------------------------------------------------------------------

    def height(self, x, z):
        """Hauteur exacte du sol (cases plates et rampes)."""
        ground = self.ground
        i, j = int(math.floor(x)), int(math.floor(z))
        i = min(max(i, 0), self.W - 1)
        j = min(max(j, 0), self.D - 1)
        c = j * self.W + i
        if ground.kinds[c] == map_build.FLAT:
            return ground.levels[c] * 0.5
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
