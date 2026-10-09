#!/usr/bin/env python3
"""(D2) Vérifie et dessine les plans de docs/lore/CARTE.md.

Les plans sont écrits dans des blocs de code ```plan (une instruction par ligne, mètres,
origine au coin nord-ouest, x vers l'est, z vers le sud ; docs/REFONTE.md, section 7.1).

  python3 tools/carte_plans.py check docs/lore/CARTE.md    # vérifications (code 1 si erreur)
  python3 tools/carte_plans.py ascii docs/lore/CARTE.md    # réécrit les plans ASCII entre
                                                        # <!-- ascii:ID --> et <!-- /ascii:ID -->

Vérifications :
- tout est dans la carte ;
- dedans : pièces qui ne se chevauchent pas, portes posées sur le mur commun des deux pièces
  (alignées), ouvertures d'au moins 1,2 m, meubles dans une pièce et sans chevauchement,
  éléments de mur sur un mur de leur pièce ;
- dehors : bâtiments et grands décors sans chevauchement, places et chemins libres de tout ce qui
  bloque, chemins d'au moins 3 m ;
- passages : depuis le marqueur Spawn, chaque sortie, marqueur, place et seuil de porte est
  atteignable par un disque de 1,2 m de diamètre dedans et de 3 m dehors ; chaque point nommé par
  un disque de 1,2 m ;
- règle de caméra (avertissements) : rien de haut au sud d'un endroit où l'on marche (zone
  cachée de 1,6 × (h − 0,5) m au nord de tout ce qui dépasse 1,2 m, sauf premier plan).
"""

from __future__ import annotations

import glob
import math
import os
import re
import shlex
import sys
from dataclasses import dataclass, field

WALL_HALF = 0.125  # demi-épaisseur d'un mur intérieur (m)
DOOR_MIN = 1.2
OUT_PATH_MIN = 3.0
R_IN = 0.6
R_OUT = 1.5
CAM = 1.6  # 1 / tan(32°) : longueur cachée au nord par mètre de hauteur


@dataclass
class Rect:
    x0: float
    z0: float
    x1: float
    z1: float

    def norm(self) -> "Rect":
        return Rect(min(self.x0, self.x1), min(self.z0, self.z1), max(self.x0, self.x1), max(self.z0, self.z1))

    def inter(self, o: "Rect", eps: float = 1e-6) -> bool:
        return self.x0 < o.x1 - eps and o.x0 < self.x1 - eps and self.z0 < o.z1 - eps and o.z0 < self.z1 - eps

    def contains(self, o: "Rect", eps: float = 1e-6) -> bool:
        return o.x0 >= self.x0 - eps and o.x1 <= self.x1 + eps and o.z0 >= self.z0 - eps and o.z1 <= self.z1 + eps

    def has(self, x: float, z: float, eps: float = 1e-6) -> bool:
        return self.x0 - eps <= x <= self.x1 + eps and self.z0 - eps <= z <= self.z1 + eps

    def shrink(self, d: float) -> "Rect":
        return Rect(self.x0 + d, self.z0 + d, self.x1 - d, self.z1 - d)

    def w(self) -> float:
        return self.x1 - self.x0

    def d(self) -> float:
        return self.z1 - self.z0

    def __str__(self) -> str:
        return f"[{self.x0:g},{self.z0:g} → {self.x1:g},{self.z1:g}]"


def centered(x: float, z: float, l: float, p: float) -> Rect:
    return Rect(x - l / 2, z - p / 2, x + l / 2, z + p / 2)


@dataclass
class Item:
    kind: str
    name: str
    rect: Rect
    h: float = 0.0
    block: bool = True
    fg: bool = False
    extra: dict = field(default_factory=dict)
    line: int = 0


@dataclass
class Map:
    id: str
    w: float
    d: float
    inside: bool
    line: int
    meta: dict = field(default_factory=dict)
    rooms: dict = field(default_factory=dict)  # id -> Item
    doors: list = field(default_factory=list)  # Item(kind porte|ouverture), extra a, b, l, vertical
    windows: list = field(default_factory=list)
    furniture: list = field(default_factory=list)
    walls: list = field(default_factory=list)  # mural
    objects: list = field(default_factory=list)
    exits: list = field(default_factory=list)
    markers: dict = field(default_factory=dict)
    points: dict = field(default_factory=dict)
    lights: list = field(default_factory=list)
    grounds: list = field(default_factory=list)
    levels: list = field(default_factory=list)
    ramps: list = field(default_factory=list)
    buildings: list = field(default_factory=list)
    decors: list = field(default_factory=list)
    trees: list = field(default_factory=list)
    borders: list = field(default_factory=list)
    waters: list = field(default_factory=list)
    places: list = field(default_factory=list)
    paths: list = field(default_factory=list)
    errors: list = field(default_factory=list)
    warnings: list = field(default_factory=list)

    def err(self, line: int, msg: str) -> None:
        self.errors.append(f"{self.id}:{line}: {msg}")

    def warn(self, line: int, msg: str) -> None:
        self.warnings.append(f"{self.id}:{line}: {msg}")

    def bounds(self) -> Rect:
        return Rect(0, 0, self.w, self.d)


def num(s: str) -> float:
    return float(s.replace(",", "."))


def pt(s: str) -> tuple[float, float]:
    a, b = s.split(";") if ";" in s else s.split("/")
    return num(a), num(b)


def parse(md: str) -> list[Map]:
    maps: list[Map] = []
    in_plan = False
    cur: Map | None = None
    for n, raw in enumerate(md.splitlines(), 1):
        if raw.strip().startswith("```"):
            if not in_plan and raw.strip() == "```plan":
                in_plan = True
            elif in_plan:
                in_plan = False
            continue
        if not in_plan:
            continue
        line = raw.split("#", 1)[0].strip() if not raw.strip().startswith("#") else ""
        if not line:
            continue
        try:
            t = shlex.split(line)
        except ValueError as e:
            raise SystemExit(f"ligne {n}: {e}")
        k = t[0]
        if k == "carte":
            cur = Map(t[1], num(t[2]), num(t[3]), t[4] == "dedans", n)
            maps.append(cur)
            continue
        if cur is None:
            raise SystemExit(f"ligne {n}: instruction hors carte")
        m = cur
        try:
            if k in ("nom", "region", "lumieres", "echelle", "passage"):
                m.meta[k] = t[1:]
            elif k == "piece":
                r = Rect(num(t[2]), num(t[3]), num(t[4]), num(t[5])).norm()
                if t[1] in m.rooms:
                    m.err(n, f"pièce {t[1]} en double")
                m.rooms[t[1]] = Item("piece", t[1], r, extra={"sol": t[6], "mur": t[7], "label": t[8] if len(t) > 8 else t[1]}, line=n)
            elif k in ("porte", "ouverture"):
                a, b = t[1], t[2]
                x, z, l = num(t[3]), num(t[4]), num(t[5])
                img = t[6] if len(t) > 6 else ""
                m.doors.append(Item(k, f"{a}|{b}", Rect(x, z, x, z), extra={"a": a, "b": b, "l": l, "img": img}, line=n))
            elif k == "fenetre":
                m.windows.append(Item(k, t[4], Rect(0, 0, 0, 0), extra={"room": t[1], "wall": t[2], "pos": num(t[3]), "img": t[4], "l": num(t[5]) if len(t) > 5 else 1.0}, line=n))
            elif k == "meuble":
                flags = t[7:]
                m.furniture.append(Item(k, t[1], centered(num(t[2]), num(t[3]), num(t[4]), num(t[5])), h=num(t[6]), block="libre" not in flags, fg="pp" in flags, extra={"flags": flags}, line=n))
            elif k == "mural":
                m.walls.append(Item(k, t[1], Rect(0, 0, 0, 0), extra={"room": t[2], "wall": t[3], "pos": num(t[4]), "bas": num(t[5]), "l": num(t[6]) if len(t) > 6 else 0.5}, line=n))
            elif k == "objet":
                m.objects.append(Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[2]), num(t[3])), block=False, line=n))
            elif k == "sortie":
                r = Rect(num(t[2]), num(t[3]), num(t[4]), num(t[5])).norm()
                m.exits.append(Item(k, t[1], r, extra={"cible": t[6], "marqueur": t[7], "invite": t[8] if len(t) > 8 else ""}, line=n))
            elif k == "marqueur":
                m.markers[t[1]] = Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[2]), num(t[3])), extra={"regard": t[4] if len(t) > 4 else "N"}, line=n)
            elif k == "point":
                m.points[t[1]] = Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[2]), num(t[3])), line=n)
            elif k == "lumiere":
                m.lights.append(Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[2]), num(t[3])), h=num(t[4]), extra={"type": t[5] if len(t) > 5 else ""}, line=n))
            elif k == "sol":
                m.grounds.append(Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[4]), num(t[5])).norm(), line=n))
            elif k == "palier":
                m.levels.append(Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[4]), num(t[5])).norm(), h=num(t[1]), line=n))
            elif k == "rampe":
                m.ramps.append(Item(k, "rampe", Rect(num(t[1]), num(t[2]), num(t[3]), num(t[4])).norm(), extra={"y0": num(t[5]), "y1": num(t[6]), "sens": t[7]}, line=n))
            elif k == "bati":
                m.buildings.append(Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[4]), num(t[5])).norm(), h=num(t[6]), extra={"img": t[7] if len(t) > 7 else ""}, line=n))
            elif k == "decor":
                flags = t[7:]
                m.decors.append(Item(k, t[1], centered(num(t[2]), num(t[3]), num(t[4]), num(t[5])), h=num(t[6]), block="libre" not in flags, fg="pp" in flags, extra={"flags": flags}, line=n))
            elif k == "arbre":
                flags = t[6:]
                crown = num(t[4])
                m.trees.append(Item(k, t[1], centered(num(t[2]), num(t[3]), 1.0, 1.0), h=num(t[5]), fg="pp" in flags, extra={"crown": crown, "flags": flags}, line=n))
            elif k == "bord":
                m.borders.append(Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[4]), num(t[5])).norm(), h=num(t[6]) if len(t) > 6 else 0.0, fg="pp" in t[7:], line=n))
            elif k == "vide":
                m.borders.append(Item("bord", "vide", Rect(num(t[1]), num(t[2]), num(t[3]), num(t[4])).norm(), h=0.0, line=n))
            elif k == "eau":
                deep = len(t) > 5 and t[5] == "profonde"
                m.waters.append(Item(k, "profonde" if deep else "basse", Rect(num(t[1]), num(t[2]), num(t[3]), num(t[4])).norm(), block=deep, line=n))
            elif k == "place":
                m.places.append(Item(k, t[1], Rect(num(t[2]), num(t[3]), num(t[4]), num(t[5])).norm(), line=n))
            elif k == "chemin":
                pts = [pt(s) for s in t[3:]]
                m.paths.append(Item(k, t[1], Rect(0, 0, 0, 0), extra={"l": num(t[2]), "pts": pts}, line=n))
            else:
                m.err(n, f"instruction inconnue « {k} »")
        except (IndexError, ValueError) as e:
            m.err(n, f"ligne mal formée ({e}) : {line}")
    return maps


# ---------------------------------------------------------------------------------------------
# Géométrie


def seg_rect(p: tuple[float, float], q: tuple[float, float], half: float) -> list[Rect]:
    """Bande d'un segment de chemin, approchée par des carrés le long du segment."""
    (x0, z0), (x1, z1) = p, q
    length = math.hypot(x1 - x0, z1 - z0)
    steps = max(1, int(length / 0.5))
    out = []
    for i in range(steps + 1):
        f = i / steps
        x, z = x0 + (x1 - x0) * f, z0 + (z1 - z0) * f
        out.append(Rect(x - half, z - half, x + half, z + half))
    return out


def _pt_seg(px: float, pz: float, a: tuple[float, float], b: tuple[float, float]) -> float:
    (x0, z0), (x1, z1) = a, b
    dx, dz = x1 - x0, z1 - z0
    L2 = dx * dx + dz * dz
    t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px - x0) * dx + (pz - z0) * dz) / L2))
    return math.hypot(px - (x0 + t * dx), pz - (z0 + t * dz))


def _segs_cross(a, b, c, d) -> bool:
    def o(p, q, r):
        v = (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
        return 0 if abs(v) < 1e-12 else (1 if v > 0 else -1)
    return o(a, b, c) != o(a, b, d) and o(c, d, a) != o(c, d, b)


def seg_rect_dist(a: tuple[float, float], b: tuple[float, float], r: Rect) -> float:
    """Distance entre le segment ab et le rectangle r (0 s'ils se touchent)."""
    if r.has(*a) or r.has(*b):
        return 0.0
    corners = [(r.x0, r.z0), (r.x1, r.z0), (r.x1, r.z1), (r.x0, r.z1)]
    for i in range(4):
        if _segs_cross(a, b, corners[i], corners[(i + 1) % 4]):
            return 0.0
    dmin = min(_pt_seg(cx, cz, a, b) for cx, cz in corners)
    for px, pz in (a, b):
        ddx = max(r.x0 - px, 0.0, px - r.x1)
        ddz = max(r.z0 - pz, 0.0, pz - r.z1)
        dmin = min(dmin, math.hypot(ddx, ddz))
    return dmin


def door_geometry(m: Map, door: Item) -> tuple[bool, str, tuple[float, float, float, float] | None]:
    """Retourne (ok, message, (x0, z0, x1, z1) du seuil) : la porte doit être sur l'arête commune."""
    a, b = door.extra["a"], door.extra["b"]
    x, z, l = door.rect.x0, door.rect.z0, door.extra["l"]
    ra = m.rooms.get(a)
    if ra is None:
        return False, f"pièce inconnue {a}", None
    A = ra.rect
    if b == "dehors":
        edges = []
        if abs(z - A.z0) < 1e-6 or abs(z - A.z1) < 1e-6:
            edges.append(("h", A.x0, A.x1))
        if abs(x - A.x0) < 1e-6 or abs(x - A.x1) < 1e-6:
            edges.append(("v", A.z0, A.z1))
        if not edges:
            return False, f"porte vers dehors hors du mur de {a}", None
        o, lo, hi = edges[0]
        c = x if o == "h" else z
        if c - l / 2 < lo - 1e-6 or c + l / 2 > hi + 1e-6:
            return False, f"porte de {l} m qui déborde du mur de {a}", None
        return True, o, (x - (l / 2 if o == "h" else 0), z - (l / 2 if o == "v" else 0), x + (l / 2 if o == "h" else 0), z + (l / 2 if o == "v" else 0))
    rb = m.rooms.get(b)
    if rb is None:
        return False, f"pièce inconnue {b}", None
    B = rb.rect
    # arête horizontale commune ?
    for za in (A.z0, A.z1):
        for zb in (B.z0, B.z1):
            if abs(za - zb) < 1e-6 and abs(z - za) < 1e-6:
                lo, hi = max(A.x0, B.x0), min(A.x1, B.x1)
                if hi - lo <= 1e-6:
                    continue
                if x - l / 2 < lo - 1e-6 or x + l / 2 > hi + 1e-6:
                    return False, f"porte {a}|{b} qui déborde du mur commun ({lo:g} → {hi:g})", None
                return True, "h", (x - l / 2, z, x + l / 2, z)
    for xa in (A.x0, A.x1):
        for xb in (B.x0, B.x1):
            if abs(xa - xb) < 1e-6 and abs(x - xa) < 1e-6:
                lo, hi = max(A.z0, B.z0), min(A.z1, B.z1)
                if hi - lo <= 1e-6:
                    continue
                if z - l / 2 < lo - 1e-6 or z + l / 2 > hi + 1e-6:
                    return False, f"porte {a}|{b} qui déborde du mur commun ({lo:g} → {hi:g})", None
                return True, "v", (x, z - l / 2, x, z + l / 2)
    return False, f"porte {a}|{b} en ({x:g}, {z:g}) hors de tout mur commun", None


# ---------------------------------------------------------------------------------------------
# Grille de passage


class Grid:
    def __init__(self, w: float, d: float, res: float) -> None:
        self.res = res
        self.nx = int(math.ceil(w / res))
        self.nz = int(math.ceil(d / res))
        self.block = [[False] * self.nx for _ in range(self.nz)]

    def cell(self, x: float, z: float) -> tuple[int, int]:
        return min(self.nx - 1, max(0, int(x / self.res))), min(self.nz - 1, max(0, int(z / self.res)))

    def fill(self, r: Rect, value: bool = True) -> None:
        i0 = max(0, int(math.floor(r.x0 / self.res + 1e-9)))
        i1 = min(self.nx, int(math.ceil(r.x1 / self.res - 1e-9)))
        j0 = max(0, int(math.floor(r.z0 / self.res + 1e-9)))
        j1 = min(self.nz, int(math.ceil(r.z1 / self.res - 1e-9)))
        for j in range(j0, j1):
            row = self.block[j]
            for i in range(i0, i1):
                row[i] = value

    def edt(self) -> list[list[float]]:
        """Distance (m) du centre de chaque case au centre de la case bloquée la plus proche."""
        inf = 1e18
        nx, nz = self.nx, self.nz
        f = [[0.0 if self.block[j][i] else inf for i in range(nx)] for j in range(nz)]

        big = float("inf")

        def dt1(fv: list[float]) -> list[float]:
            n = len(fv)
            dv = [0.0] * n
            v = [0] * n
            zz = [0.0] * (n + 1)
            k = 0
            zz[0] = -big
            zz[1] = big
            for q in range(1, n):
                s = ((fv[q] + q * q) - (fv[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k])
                while s <= zz[k]:
                    k -= 1
                    s = ((fv[q] + q * q) - (fv[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k])
                k += 1
                v[k] = q
                zz[k] = s
                zz[k + 1] = big
            k = 0
            for q in range(n):
                while zz[k + 1] < q:
                    k += 1
                dv[q] = (q - v[k]) ** 2 + fv[v[k]]
            return dv

        # colonnes puis lignes (Felzenszwalb)
        for i in range(nx):
            col = dt1([f[j][i] for j in range(nz)])
            for j in range(nz):
                f[j][i] = col[j]
        for j in range(nz):
            f[j] = dt1(f[j])
        return [[math.sqrt(v) * self.res if v < inf / 2 else 1e9 for v in row] for row in f]

    def reach(self, ok: list[list[bool]], start: tuple[int, int]) -> list[list[bool]]:
        seen = [[False] * self.nx for _ in range(self.nz)]
        i, j = start
        if not ok[j][i]:
            return seen
        stack = [(i, j)]
        seen[j][i] = True
        while stack:
            i, j = stack.pop()
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                a, b = i + di, j + dj
                if 0 <= a < self.nx and 0 <= b < self.nz and not seen[b][a] and ok[b][a]:
                    seen[b][a] = True
                    stack.append((a, b))
        return seen


def nearest_ok(grid: Grid, ok: list[list[bool]], x: float, z: float, radius: float) -> tuple[int, int] | None:
    """Case libre la plus proche de (x, z), à moins de radius m."""
    ci, cj = grid.cell(x, z)
    rr = int(math.ceil(radius / grid.res))
    best = None
    bd = 1e9
    for j in range(max(0, cj - rr), min(grid.nz, cj + rr + 1)):
        for i in range(max(0, ci - rr), min(grid.nx, ci + rr + 1)):
            if ok[j][i]:
                dd = (i - ci) ** 2 + (j - cj) ** 2
                if dd < bd:
                    bd, best = dd, (i, j)
    return best


# ---------------------------------------------------------------------------------------------
# Vérifications


def check_inside(m: Map) -> None:
    B = m.bounds()
    rooms = list(m.rooms.values())
    for r in rooms:
        if not B.contains(r.rect):
            m.err(r.line, f"pièce {r.name} hors de la carte {r.rect}")
    for i, a in enumerate(rooms):
        for b in rooms[i + 1:]:
            if a.rect.inter(b.rect):
                m.err(b.line, f"les pièces {a.name} et {b.name} se chevauchent")
    seuils = []
    for d in m.doors:
        ok, msg, seg = door_geometry(m, d)
        if not ok:
            m.err(d.line, msg)
            continue
        if d.extra["l"] < DOOR_MIN - 1e-6:
            m.err(d.line, f"{d.kind} {d.name} de {d.extra['l']} m (< {DOOR_MIN} m)")
        d.extra["orient"] = msg
        d.extra["seg"] = seg
        seuils.append(d)
    # meubles
    def room_of(rect: Rect) -> Item | None:
        for r in rooms:
            if r.rect.shrink(WALL_HALF - 0.01).contains(rect):
                return r
        return None

    for f in m.furniture:
        r = room_of(f.rect)
        if r is None:
            m.err(f.line, f"meuble {f.name} {f.rect} hors de toute pièce (murs compris)")
        f.extra["room"] = r.name if r else "?"
    blk = [f for f in m.furniture if f.block]
    for i, a in enumerate(blk):
        for b in blk[i + 1:]:
            if a.rect.inter(b.rect):
                m.err(b.line, f"meubles {a.name} {a.rect} et {b.name} {b.rect} qui se chevauchent")
    for w in m.walls + m.windows:
        r = m.rooms.get(w.extra["room"])
        if r is None:
            m.err(w.line, f"pièce inconnue {w.extra['room']}")
            continue
        R = r.rect
        wall, pos, l = w.extra["wall"], w.extra["pos"], w.extra.get("l", 0.5)
        lo, hi = (R.x0, R.x1) if wall in ("N", "S") else (R.z0, R.z1)
        if pos - l / 2 < lo - 1e-6 or pos + l / 2 > hi + 1e-6:
            m.err(w.line, f"{w.kind} {w.name} hors du mur {wall} de {r.name} ({lo:g} → {hi:g})")
        if wall == "S" and w.kind == "fenetre":
            m.warn(w.line, f"fenêtre {w.name} sur un mur sud (coupé, invisible dedans)")
    for o in m.objects:
        x, z = o.rect.x0, o.rect.z0
        if not any(f.rect.has(x, z) for f in m.furniture):
            m.err(o.line, f"objet {o.name} posé hors de tout meuble")
    reach_check(m, seuils)
    camera_inside(m, seuils)


def camera_inside(m: Map, doors: list) -> None:
    targets = []
    for d in doors:
        x0, z0, x1, z1 = d.extra["seg"]
        targets.append((f"seuil {d.name}", (x0 + x1) / 2, (z0 + z1) / 2))
    for p in list(m.points.values()) + list(m.markers.values()):
        targets.append((p.name, p.rect.x0, p.rect.z0))
    for f in m.furniture:
        if not f.block or f.fg or f.h <= 1.2:
            continue
        shadow = Rect(f.rect.x0, f.rect.z0 - CAM * (f.h - 0.5), f.rect.x1, f.rect.z0)
        for name, x, z in targets:
            if shadow.has(x, z, -1e-6) and not f.rect.has(x, z):
                m.warn(f.line, f"{f.name} (h {f.h:g} m) cache « {name} » au nord")


def check_outside(m: Map) -> None:
    B = m.bounds()
    every = m.buildings + m.decors + m.trees + m.borders + m.waters + m.places + m.grounds + m.levels + m.ramps + m.exits
    for it in every:
        if not B.contains(it.rect):
            m.err(it.line, f"{it.kind} {it.name} {it.rect} hors de la carte")
    blockers = [b for b in m.buildings] + [d for d in m.decors if d.block] + list(m.trees) + [b for b in m.borders] + [w for w in m.waters if w.block]
    solid = [b for b in m.buildings] + [d for d in m.decors if d.block] + list(m.trees)
    for i, a in enumerate(solid):
        for b in solid[i + 1:]:
            if a.rect.inter(b.rect):
                m.err(b.line, f"{a.kind} {a.name} {a.rect} et {b.kind} {b.name} {b.rect} se chevauchent")
    for pl in m.places:
        for b in blockers:
            if b.rect.inter(pl.rect):
                m.err(b.line, f"{b.kind} {b.name} {b.rect} empiète sur la place {pl.name} {pl.rect}")
    for p in m.paths:
        l = p.extra["l"]
        if l < OUT_PATH_MIN - 1e-6:
            m.err(p.line, f"chemin {p.name} de {l} m (< {OUT_PATH_MIN} m)")
        pts = p.extra["pts"]
        hit = set()
        for a, b in zip(pts, pts[1:]):
            for o in blockers:
                if o.line not in hit and seg_rect_dist(a, b, o.rect) < l / 2 - 1e-6:
                    hit.add(o.line)
                    m.err(p.line, f"chemin {p.name} coupé par {o.kind} {o.name} {o.rect} (ligne {o.line})")
    reach_check(m, [])
    camera_outside(m)


def camera_outside(m: Map) -> None:
    walk = []
    for pl in m.places:
        walk.append((f"place {pl.name}", pl.rect))
    for p in m.paths:
        half = p.extra["l"] / 2
        for a, b in zip(p.extra["pts"], p.extra["pts"][1:]):
            for sq in seg_rect(a, b, half * 0.6):
                walk.append((f"chemin {p.name}", sq))
    for p in list(m.points.values()) + list(m.markers.values()):
        walk.append((p.name, Rect(p.rect.x0 - 0.3, p.rect.z0 - 0.3, p.rect.x0 + 0.3, p.rect.z0 + 0.3)))
    occluders = []
    for b in m.buildings:
        occluders.append((b, b.rect, b.h))
    for d in m.decors:
        if not d.fg and d.h > 1.2:
            occluders.append((d, d.rect, d.h))
    for t in m.trees:
        if not t.fg:
            c = t.extra["crown"]
            x = (t.rect.x0 + t.rect.x1) / 2
            z = (t.rect.z0 + t.rect.z1) / 2
            occluders.append((t, Rect(x - c / 2, z - 0.5, x + c / 2, z + 0.5), t.h))
    for b in m.borders:
        if not b.fg and b.h > 1.2:
            occluders.append((b, b.rect, b.h))
    def height_at(x: float, z: float) -> float:
        y = 0.0
        for lv in m.levels:
            if lv.rect.has(x, z, -1e-6):
                y = lv.h
        return y

    seen = set()
    for it, r, h in occluders:
        top = height_at((r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2) + h
        for name, wr in walk:
            eff = top - height_at((wr.x0 + wr.x1) / 2, (wr.z0 + wr.z1) / 2)
            if eff <= 1.2:
                continue
            shadow = Rect(r.x0, r.z0 - CAM * (eff - 0.5), r.x1, r.z0)
            if shadow.inter(wr) and not r.inter(wr):
                key = (it.line, name)
                if key in seen:
                    continue
                seen.add(key)
                m.warn(it.line, f"{it.kind} {it.name} (h {h:g} m) cache « {name} » au nord")


def reach_check(m: Map, doors: list) -> None:
    res = 0.1 if m.inside else 0.25
    g = Grid(m.w, m.d, res)
    g.fill(m.bounds(), True)
    if m.inside:
        for r in m.rooms.values():
            g.fill(r.rect.shrink(WALL_HALF), False)
        for d in doors:
            x0, z0, x1, z1 = d.extra["seg"]
            if d.extra["orient"] == "h":
                rr = Rect(x0, z0 - 0.4, x1, z1 + 0.4)
            else:
                rr = Rect(x0 - 0.4, z0, x1 + 0.4, z1)
            g.fill(rr, False)
        for e in m.exits:  # seuil des sorties (marche hors de la carte)
            g.fill(e.rect, False)
        for f in m.furniture:
            if f.block:
                g.fill(f.rect, True)
    else:
        g.fill(m.bounds(), False)
        for b in m.buildings:
            g.fill(b.rect, True)
        for d in m.decors:
            if d.block:
                g.fill(d.rect, True)
        for t in m.trees:
            g.fill(t.rect, True)
        for b in m.borders:
            g.fill(b.rect, True)
        for w in m.waters:
            if w.block:
                g.fill(w.rect, True)
    dist = g.edt()
    spawn = m.markers.get("Spawn")
    if spawn is None:
        m.err(m.line, "pas de marqueur Spawn")
        return
    r_large = R_IN if m.inside else R_OUT
    if "passage" in m.meta:
        r_large = num(m.meta["passage"][0]) / 2
    for radius, label, need in ((r_large, "large", True), (R_IN, "fin", True)):
        ok = [[dist[j][i] >= radius - 1e-9 for i in range(g.nx)] for j in range(g.nz)]
        s = nearest_ok(g, ok, spawn.rect.x0, spawn.rect.z0, 1.0)
        if s is None:
            m.err(spawn.line, f"Spawn bloqué (disque de {2 * radius:g} m)")
            continue
        seen = g.reach(ok, s)
        targets = []
        if label == "large":
            for e in m.exits:
                cx, cz = (e.rect.x0 + e.rect.x1) / 2, (e.rect.z0 + e.rect.z1) / 2
                targets.append((f"sortie {e.name}", cx, cz, e.line, max(e.rect.w(), e.rect.d()) / 2 + 1.0))
            for mk in m.markers.values():
                targets.append((f"marqueur {mk.name}", mk.rect.x0, mk.rect.z0, mk.line, 1.0))
            for pl in m.places:
                targets.append((f"place {pl.name}", (pl.rect.x0 + pl.rect.x1) / 2, (pl.rect.z0 + pl.rect.z1) / 2, pl.line, 1.0))
            for d in doors:
                x0, z0, x1, z1 = d.extra["seg"]
                cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
                if d.extra["orient"] == "h":
                    sides = [(cx, cz - 0.7), (cx, cz + 0.7)]
                else:
                    sides = [(cx - 0.7, cz), (cx + 0.7, cz)]
                for k, (sx, sz) in enumerate(sides):
                    if d.extra["b"] == "dehors" and not any(r.rect.has(sx, sz) for r in m.rooms.values()):
                        continue
                    targets.append((f"seuil {d.name} ({'ab'[k]})", sx, sz, d.line, 0.6))
        else:
            for p in m.points.values():
                targets.append((f"point {p.name}", p.rect.x0, p.rect.z0, p.line, 0.8))
        for name, x, z, line, tol in targets:
            c = nearest_ok(g, ok, x, z, tol)
            if c is None or not seen[c[1]][c[0]]:
                m.err(line, f"{name} en ({x:g}, {z:g}) inatteignable par un disque de {2 * radius:g} m")


# ---------------------------------------------------------------------------------------------
# Plans ASCII

GROUND_CHARS = {
    "grass": ".", "grass_b": ".", "meadow_flowers": "'", "grass_dry": ",", "grass_dry_b": ",",
    "path_dirt": ":", "path_dirt_b": ":", "path_overgrown": ":", "garden_soil": "=", "mud": "~",
    "water": "w", "stream_bed": "w", "peat": "%", "forest_floor": ";", "forest_floor_b": ";",
    "leaf_litter": ";", "moss": ";", "cobble": "_", "cobble_b": "_", "flagstone": "_",
    "flagstone_b": "_", "gravel": "_", "planks": "=", "metal": "=", "rock": "^", "rock_b": "^",
    "sand": ",", "sand_b": ",", "floor_roof_deck": "=",
}


def codes() -> list[str]:
    return list("ABCDEFGIJKLMNPQRSUVYZabcdefghijkmnpqrstuvxyz123456789")


def render(m: Map) -> list[str]:
    sx, sz = (0.5, 0.5) if m.inside else (1.0, 2.0)
    if "echelle" in m.meta:
        sx, sz = num(m.meta["echelle"][0]), num(m.meta["echelle"][1])
    W = int(math.ceil(m.w / sx))
    H = int(math.ceil(m.d / sz))
    grid = [[" "] * W for _ in range(H)]

    def cells(r: Rect):
        i0 = max(0, int(math.floor(r.x0 / sx + 1e-6)))
        i1 = min(W, max(i0 + 1, int(math.ceil(r.x1 / sx - 1e-6))))
        j0 = max(0, int(math.floor(r.z0 / sz + 1e-6)))
        j1 = min(H, max(j0 + 1, int(math.ceil(r.z1 / sz - 1e-6))))
        for j in range(j0, j1):
            for i in range(i0, i1):
                yield i, j

    def ci(x: float) -> int:
        return min(W - 1, max(0, int(round(x / sx))))

    def cj(z: float) -> int:
        return min(H - 1, max(0, int(round(z / sz))))

    legend = []
    if m.inside:
        for r in m.rooms.values():
            for i, j in cells(r.rect):
                grid[j][i] = "."
        for r in m.rooms.values():
            R = r.rect
            a0, a1, b0, b1 = ci(R.x0), ci(R.x1), cj(R.z0), cj(R.z1)
            a1 = min(a1, W - 1)
            b1 = min(b1, H - 1)
            for i in range(a0, a1 + 1):
                for j in (b0, b1):
                    if grid[j][i] not in "+|":
                        grid[j][i] = "-"
            for j in range(b0, b1 + 1):
                for i in (a0, a1):
                    grid[j][i] = "+" if grid[j][i] in "-+" or j in (b0, b1) else "|"
        for d in m.doors:
            if "seg" not in d.extra:
                ok, msg, seg = door_geometry(m, d)
                if not ok:
                    continue
                d.extra["orient"], d.extra["seg"] = msg, seg
            x0, z0, x1, z1 = d.extra["seg"]
            ch = " " if d.kind == "ouverture" else ("=" if d.extra["orient"] == "h" else ":")
            if d.extra["orient"] == "h":
                j = cj(z0)
                for i in range(ci(x0) + (1 if d.kind == "porte" else 0), ci(x1) + (0 if d.kind == "porte" else 1)):
                    if 0 <= i < W:
                        grid[j][i] = ch
                if d.kind == "porte" and ci(x1) - ci(x0) <= 1:
                    grid[j][ci((x0 + x1) / 2)] = ch
            else:
                i = ci(x0)
                for j in range(cj(z0), cj(z1) + (1 if d.kind == "ouverture" else 1)):
                    if 0 <= j < H and grid[j][i] in "|+-":
                        grid[j][i] = ch
        for w in m.windows:
            r = m.rooms.get(w.extra["room"])
            if r is None:
                continue
            R = r.rect
            wall, pos = w.extra["wall"], w.extra["pos"]
            if wall == "N":
                grid[cj(R.z0)][ci(pos)] = "o"
            elif wall == "S":
                grid[cj(R.z1)][ci(pos)] = "o"
            elif wall == "E":
                grid[cj(pos)][ci(R.x1)] = "o"
            else:
                grid[cj(pos)][ci(R.x0)] = "o"
    else:
        for gnd in m.grounds:
            ch = GROUND_CHARS.get(gnd.name, "?")
            for i, j in cells(gnd.rect):
                grid[j][i] = ch
        for w in m.waters:
            for i, j in cells(w.rect):
                grid[j][i] = "W" if w.block else "w"
        for b in m.borders:
            ch = {"foret": "^", "falaise": "X", "vide": " ", "bosquet": "^", "fourre": "&", "lisiere": "^", "talus": "/", "roche": "X", "mur": "#", "eau": "W", "toit": "/", "marais": "%", "rambarde": "H", "haie": "&", "maisons": "#", "quai": "=", "jardins": "\"", "muret": "-", "parapet": "H", "arriere": "^"}.get(b.name, "^")
            for i, j in cells(b.rect):
                grid[j][i] = ch
        for b in m.buildings:
            for i, j in cells(b.rect):
                grid[j][i] = "#"
            label = b.name
            j = cj((b.rect.z0 + b.rect.z1) / 2)
            i0 = ci(b.rect.x0) + 1
            space = ci(b.rect.x1) - i0 - 1
            for k, c in enumerate(label[:max(0, space)]):
                grid[j][i0 + k] = c
    # meubles / décors / arbres
    pool = codes()
    k = 0
    seen_names: dict[str, str] = {}
    items = (m.furniture if m.inside else m.decors)
    items = [it for it in items if not it.block] + [it for it in items if it.block]
    for it in items:
        key = it.name
        if key not in seen_names:
            if k >= len(pool):
                seen_names[key] = "?"
            else:
                seen_names[key] = pool[k]
                k += 1
        ch = seen_names[key]
        for i, j in cells(it.rect):
            if m.inside and grid[j][i] in "+|-=:o":
                continue
            if not it.block and grid[j][i] not in ".,;:_\x27~%=w":
                continue
            grid[j][i] = ch
    for t in m.trees:
        grid[cj((t.rect.z0 + t.rect.z1) / 2)][ci((t.rect.x0 + t.rect.x1) / 2)] = "T"
    if m.inside:
        # étiquettes de pièces : première rangée où le nom tient sur le sol nu
        for r in m.rooms.values():
            label = r.extra["label"]
            R = r.rect
            i0, i1 = ci(R.x0) + 1, ci(R.x1) - 1
            space = i1 - i0 + 1
            if space <= 0:
                continue
            txt = label[:space]
            placed = False
            for j in range(cj(R.z0) + 1, cj(R.z1)):
                for start in range(i0, i1 - len(txt) + 2):
                    if all(grid[j][start + q] == "." for q in range(len(txt))):
                        for q, c in enumerate(txt):
                            grid[j][start + q] = c
                        placed = True
                        break
                if placed:
                    break
    for e in m.exits:
        cx, cz = (e.rect.x0 + e.rect.x1) / 2, (e.rect.z0 + e.rect.z1) / 2
        if e.rect.z0 <= 0.01:
            ch = "^"
        elif e.rect.z1 >= m.d - 0.01:
            ch = "v"
        elif e.rect.x0 <= 0.01:
            ch = "<"
        elif e.rect.x1 >= m.w - 0.01:
            ch = ">"
        else:
            ch = "*"
        grid[cj(cz) if ch not in "^v" else (0 if ch == "^" else H - 1)][ci(cx) if ch not in "<>" else (0 if ch == "<" else W - 1)] = ch
    for mk in m.markers.values():
        grid[cj(mk.rect.z0)][ci(mk.rect.x0)] = "@" if mk.name == "Spawn" else "o" if False else grid[cj(mk.rect.z0)][ci(mk.rect.x0)]
    # cotes
    step = 5 if m.inside else 10
    head = [" "] * (W + 6)
    for v in range(0, int(m.w) + 1, step):
        s = str(v)
        i = int(round(v / sx))
        for q, c in enumerate(s):
            if i + q < len(head):
                head[i + q] = c
    lines = ["      " + "".join(head).rstrip()]
    for j in range(H):
        z = j * sz
        lab = f"{z:5g} " if abs((j * sz) % (2 if m.inside else 10)) < 1e-6 else "      "
        lines.append(lab + "".join(grid[j]).rstrip())
    legend_items = sorted(seen_names.items(), key=lambda kv: kv[1])
    leg = [f"{c} {n}" for n, c in legend_items]
    return lines, leg


def update_ascii(path: str, maps: list[Map]) -> None:
    text = open(path, encoding="utf-8").read()
    for m in maps:
        lines, leg = render(m)
        sx, sz = (0.5, 0.5) if m.inside else (1.0, 2.0)
        if "echelle" in m.meta:
            sx, sz = num(m.meta["echelle"][0]), num(m.meta["echelle"][1])
        body = [f"<!-- ascii:{m.id} -->", "```text", f"{m.id} : {m.w:g} × {m.d:g} m ; un caractère = {sx:g} m (est-ouest) × {sz:g} m (nord-sud) ; nord en haut"]
        body += lines
        body.append("```")
        if leg:
            chunks = []
            line = "Légende des lettres : "
            for entry in leg:
                c, n = entry.split(" ", 1)
                piece = f"`{c}` {n}"
                chunks.append(piece)
            body.append("Légende des lettres : " + " ; ".join(chunks) + ".")
        body.append(f"<!-- /ascii:{m.id} -->")
        pat = re.compile(rf"<!-- ascii:{re.escape(m.id)} -->.*?<!-- /ascii:{re.escape(m.id)} -->", re.S)
        if pat.search(text):
            text = pat.sub(lambda _m: "\n".join(body), text)
    open(path, "w", encoding="utf-8").write(text)


ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
NOT_IMAGES = {"cristal", "feu", "huile"}
_DOCS: dict[str, str] = {}


def image_status(name: str) -> str:
    hits = glob.glob(os.path.join(ROOT, "assets", "hd2d", "**", name + ".png"), recursive=True)
    if hits:
        return "livrée : `" + os.path.relpath(hits[0], ROOT) + "`"
    for doc, label in (("docs/ASSETS_HD2D_SUKASUKA.md", "cahier n° 3"), ("docs/ASSETS_HD2D_MONDE.md", "cahier n° 2"),
                       ("docs/ASSETS_HD2D.md", "cahier n° 1")):
        if doc not in _DOCS:
            _DOCS[doc] = open(os.path.join(ROOT, doc), encoding="utf-8").read()
        text = _DOCS[doc]
        if f"/{name}.png" in text or f"`{name}`" in text:
            return f"à livrer ({label})"
    return "**nom proposé** (absent des cahiers)"


def used_images(maps: list) -> dict:
    used: dict = {}

    def add(n: str, mid: str) -> None:
        if n and n not in NOT_IMAGES:
            used.setdefault(n, set()).add(mid)

    for m in maps:
        for f in m.furniture + m.decors + m.trees + m.objects:
            add(f.name, m.id)
        for w in m.walls:
            add(w.name, m.id)
        for w in m.windows:
            add(w.extra["img"], m.id)
        for d in m.doors:
            add(d.extra.get("img", ""), m.id)
        for b in m.buildings:
            add(b.extra.get("img", ""), m.id)
        for r in m.rooms.values():
            add(r.extra["sol"], m.id)
            add(r.extra["mur"], m.id)
        for g in m.grounds:
            add(g.name, m.id)
    return used


def update_inventory(path: str, maps: list) -> None:
    used = used_images(maps)
    rows = ["| Image ou matière | Cartes | État |", "| --- | --- | --- |"]
    counts: dict = {}
    for n in sorted(used):
        st = image_status(n)
        key = "livrées" if st.startswith("livrée") else ("à livrer" if st.startswith("à livrer") else "proposées")
        counts[key] = counts.get(key, 0) + 1
        rows.append(f"| `{n}` | {', '.join(sorted(used[n]))} | {st} |")
    summary = (f"{len(used)} images ou matières citées : " + " ; ".join(f"{v} {k}" for k, v in sorted(counts.items())) + ".")
    text = open(path, encoding="utf-8").read()
    block = "<!-- inventaire -->\n" + summary + "\n\n" + "\n".join(rows) + "\n<!-- /inventaire -->"
    text = re.sub(r"<!-- inventaire -->.*?<!-- /inventaire -->", lambda _m: block, text, flags=re.S)
    open(path, "w", encoding="utf-8").write(text)
    print(summary)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    cmd, path = sys.argv[1], sys.argv[2]
    md = open(path, encoding="utf-8").read()
    maps = parse(md)
    only = sys.argv[3] if len(sys.argv) > 3 else None
    if only:
        maps = [m for m in maps if m.id == only]
    if cmd == "ascii":
        update_ascii(path, maps)
        print(f"{len(maps)} plans ASCII réécrits")
        return 0
    if cmd == "inventaire":
        update_inventory(path, maps)
        return 0
    nerr = nwarn = 0
    for m in maps:
        if m.inside:
            check_inside(m)
        else:
            check_outside(m)
        for e in m.errors:
            print("ERREUR", e)
        for w in m.warnings:
            print("avert.", w)
        nerr += len(m.errors)
        nwarn += len(m.warnings)
        nb = len(m.furniture) + len(m.decors) + len(m.trees) + len(m.buildings)
        print(f"-- {m.id} ({'dedans' if m.inside else 'dehors'}, {m.w:g} × {m.d:g} m) : "
              f"{len(m.rooms)} pièces, {len(m.doors)} portes, {nb} éléments posés, {len(m.exits)} sorties, "
              f"{len(m.errors)} erreurs, {len(m.warnings)} avertissements")
    print(f"{len(maps)} cartes, {nerr} erreurs, {nwarn} avertissements")
    return 1 if nerr else 0


if __name__ == "__main__":
    sys.exit(main())
