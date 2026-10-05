#!/usr/bin/env python3
"""Placeholders P0 : planches de sprites au format de l'easter egg, et textures simples (Pillow).

Deux jeux d'animations, exactement ceux des planches de l'easter egg (mêmes noms, nombres
d'images, cadences, boucles, "coup" et "onde") :
- personnage (skins, PNJ), comme chtholly.json : repos 2, marche 6, course 5, attaque 4
  (coup 1, 2, 3), charge 4 (onde 3), degats 1, mort 1 ;
- ennemi, comme timere.json : repos 5, marche 4, course 6, fouet 4 et morsure 4 (coup 1, 2),
  degats 5, mort 6.
Images [x, y, largeur, hauteur, ancre x, ancre y] ; l'ancre est au milieu des pieds, au sol.
Échelle : 0,0104 m par pixel de planche (Chtholly : 144 px pour 1,5 m), donc un personnage de
1,6 m mesure 154 px debout. Silhouettes chibi en pixel art (bords nets pour l'alpha scissor,
contours sombres) : le bras frappe à l'attaque, un halo grandit pendant la charge et l'onde
part à l'image 3, le personnage tombe à la mort ; l'ennemi mord, fouette et s'effondre.
Chaque skin reçoit aussi un portrait carré (<id>_portrait.png) pour la boîte de dialogue.

Usage (Python 3.9+, pip install Pillow) :

    # un skin : assets/characters/<id>/<id>.png, .json, _portrait.png (+ data/skins/<id>.tres)
    python3 tools/gen_placeholders.py skin <id> --name "Nom" --color "#8e6cc9" --height 1.6 --tres
    # les trois PNJ du village (bibliothecaire, forgeron, enfant), avec leurs .tres
    python3 tools/gen_placeholders.py npcs
    # un ennemi : assets/enemies/<id>/<id>.png + .json (son SkinData va dans data/enemies/visuals/)
    python3 tools/gen_placeholders.py enemy <id> --color "#6f8f4f" --height 1.0
    # damier (sol de la greybox)
    python3 tools/gen_placeholders.py checker assets/textures/checker.png

--out <dossier> écrit la planche ailleurs (essais). Le résultat est déterministe (aucun
hasard) ; les fichiers générés sont versionnés.
"""

import argparse
import json
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
METERS_PER_PIXEL = 1.5 / 144.0
SPACING = 2
PORTRAIT_SIZE = 128
FORMAT_NOTE = "images : [x, y, largeur, hauteur, ancre x, ancre y] en px de la planche"

# Nom, réglages copiés des planches de l'easter egg, nombre d'images.
CHARACTER_ANIMATIONS = [
    ("repos", {"ips": 2, "boucle": True}, 2),
    ("marche", {"ips": 10, "boucle": True}, 6),
    ("course", {"ips": 14, "boucle": True}, 5),
    ("attaque", {"ips": 14, "boucle": False, "coup": [1, 2, 3]}, 4),
    ("charge", {"ips": 10, "boucle": False, "onde": 3}, 4),
    ("degats", {"ips": 1, "boucle": False}, 1),
    ("mort", {"ips": 1, "boucle": False}, 1),
]
ENEMY_ANIMATIONS = [
    ("repos", {"ips": 6, "boucle": True}, 5),
    ("marche", {"ips": 7, "boucle": True}, 4),
    ("course", {"ips": 12, "boucle": True}, 6),
    ("fouet", {"ips": 8, "boucle": False, "coup": [1, 2]}, 4),
    ("morsure", {"ips": 8, "boucle": False, "coup": [1, 2]}, 4),
    ("degats", {"ips": 12, "boucle": False}, 5),
    ("mort", {"ips": 8, "boucle": False}, 6),
]

# Identifiant, nom, tenue, taille (m), cheveux, objet tenu, accessoire.
NPCS = [
    ("bibliothecaire", "Bibliothécaire", "#8e6cc9", 1.6, "#d8d0e8", "book", "glasses"),
    ("forgeron", "Forgeron", "#c8643c", 1.75, "#4a3022", "hammer", "apron"),
    ("enfant", "Enfant", "#3fae8c", 1.1, "#e39a3b", "stick", "cap"),
]

SKIN_TONE = (255, 224, 199, 255)
EYE = (52, 40, 64, 255)
WHITE = (255, 255, 255, 255)
SHOE = (70, 52, 46, 255)
STEEL = (206, 222, 238, 255)
WOOD = (150, 98, 54, 255)
GLOW = (143, 208, 255, 255)
GLOW_LIGHT = (222, 242, 255, 255)
HIP = 0.25
LEG = 0.25


def hex_color(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4)) + (255,)


def shade(color, factor):
    """factor < 1 assombrit, > 1 éclaircit (vers le blanc)."""
    if factor <= 1.0:
        return tuple(int(c * factor) for c in color[:3]) + (255,)
    return tuple(int(c + (255 - c) * (factor - 1.0)) for c in color[:3]) + (255,)


class Pose:
    """Pose paramétrique ; angles des membres : 0 = vers le bas, pi/2 = vers l'avant."""

    def __init__(self, **values):
        defaults = dict(bob=0.0, lean=0.0, front_leg=0.0, back_leg=0.0, front_arm=0.2,
                        back_arm=-0.2, prop=None, glow=0.0, burst=False, eyes="open",
                        lying=False, neck=(0.42, 0.84), mouth=0.0, whip=None, sink=0.0,
                        flash=False, legs=0.0)
        defaults.update(values)
        self.__dict__.update(defaults)


class Pen:
    """Dessine en unités (hauteur debout = 1, x vers l'avant, y vers le haut, origine = ancre)."""

    def __init__(self, img, origin, unit, pose):
        self.draw = ImageDraw.Draw(img)
        self.origin = origin
        self.unit = unit
        self.pose = pose
        self.stroke = max(1, round(unit / 90))

    def pt(self, x, y):
        p = self.pose
        if y > HIP:
            y += p.bob
        if p.lying:  # sur le dos, tête en arrière, centré sur l'ancre
            x, y = 0.45 - y, x + 0.2
        a = p.lean
        x, y = x * math.cos(a) + y * math.sin(a), y * math.cos(a) - x * math.sin(a)
        return (self.origin[0] + x * self.unit, self.origin[1] - y * self.unit)

    def poly(self, points, fill, outline=True):
        outline_color = shade(fill, 0.5) if outline else None
        self.draw.polygon([self.pt(x, y) for x, y in points], fill=fill, outline=outline_color,
                          width=self.stroke)

    def ellipse(self, cx, cy, rx, ry, fill, outline=True):
        steps = [2 * math.pi * i / 32 for i in range(32)]
        self.poly([(cx + rx * math.cos(t), cy + ry * math.sin(t)) for t in steps], fill, outline)

    def capsule(self, x0, y0, x1, y1, width, fill):
        r, a = width / 2.0, math.atan2(y1 - y0, x1 - x0)
        points = [(x1 + r * math.cos(a - math.pi / 2 + math.pi * i / 8),
                   y1 + r * math.sin(a - math.pi / 2 + math.pi * i / 8)) for i in range(9)]
        points += [(x0 + r * math.cos(a + math.pi / 2 + math.pi * i / 8),
                    y0 + r * math.sin(a + math.pi / 2 + math.pi * i / 8)) for i in range(9)]
        self.poly(points, fill)

    def limb(self, x0, y0, angle, length, width, fill):
        """Segment arrondi depuis (x0, y0) dans la direction angle ; renvoie l'extrémité."""
        x1, y1 = x0 + math.sin(angle) * length, y0 - math.cos(angle) * length
        self.capsule(x0, y0, x1, y1, width, fill)
        return x1, y1

    def spark(self, x, y, r, fill):
        self.poly([(x, y + r), (x + r * 0.3, y + r * 0.3), (x + r, y), (x + r * 0.3, y - r * 0.3),
                   (x, y - r), (x - r * 0.3, y - r * 0.3), (x - r, y), (x - r * 0.3, y + r * 0.3)],
                  fill, outline=False)


# --- Personnage chibi --------------------------------------------------------------------------


def character_poses(anim, count):
    result = []
    for i in range(count):
        s = math.sin(2 * math.pi * i / count)
        if anim == "repos":
            result.append(Pose(bob=-0.012 * i))
        elif anim == "marche":
            result.append(Pose(bob=0.012 * abs(s), front_leg=0.38 * s, back_leg=-0.38 * s,
                               front_arm=-0.45 * s, back_arm=0.45 * s))
        elif anim == "course":
            result.append(Pose(bob=0.025 * abs(s), lean=0.16, front_leg=0.7 * s, back_leg=-0.7 * s,
                               front_arm=1.2 - 0.9 * s, back_arm=-0.8 + 0.6 * s))
        elif anim == "attaque":  # élan, puis le bras frappe de haut en bas (images 1 à 3)
            result.append(Pose(lean=[-0.06, 0.04, 0.12, 0.14][i], prop=[2.7, 2.0, 1.25, 0.55][i],
                               back_arm=[-0.6, -0.3, 0.2, 0.4][i], front_leg=0.25 * (i > 0),
                               back_leg=-0.2 * (i > 0)))
        elif anim == "charge":  # le halo grandit, l'onde part à l'image 3
            result.append(Pose(prop=1.45 if i == 3 else 1.1, back_arm=1.0, glow=[0.3, 0.6, 0.9, 0][i],
                               burst=i == 3, lean=0.1 if i == 3 else 0.0, front_leg=0.2 * (i == 3)))
        elif anim == "degats":
            result.append(Pose(lean=-0.28, eyes="hurt", front_arm=2.4, back_arm=2.9, front_leg=0.35,
                               mouth=1.0))
        else:
            result.append(Pose(lying=True, eyes="closed", front_arm=1.2, back_arm=-1.0))
    return result


def draw_prop(pen, kind, hand, angle):
    hx, hy = hand
    dx, dy = math.sin(angle), -math.cos(angle)
    if kind == "sword":
        pen.capsule(hx, hy, hx + dx * 0.5, hy + dy * 0.5, 0.06, STEEL)
        pen.capsule(hx + dy * 0.07, hy - dx * 0.07, hx - dy * 0.07, hy + dx * 0.07, 0.035, (214, 170, 64, 255))
    elif kind == "hammer":
        pen.capsule(hx - dx * 0.04, hy - dy * 0.04, hx + dx * 0.32, hy + dy * 0.32, 0.04, WOOD)
        cx, cy = hx + dx * 0.32, hy + dy * 0.32
        pen.poly([(cx + dy * 0.1 + dx * 0.05, cy - dx * 0.1 + dy * 0.05),
                  (cx + dy * 0.1 - dx * 0.05, cy - dx * 0.1 - dy * 0.05),
                  (cx - dy * 0.1 - dx * 0.05, cy + dx * 0.1 - dy * 0.05),
                  (cx - dy * 0.1 + dx * 0.05, cy + dx * 0.1 + dy * 0.05)], (120, 124, 134, 255))
    elif kind == "book":
        cx, cy = hx + dx * 0.08, hy + dy * 0.08
        pen.poly([(cx + dy * 0.08 + dx * 0.1, cy - dx * 0.08 + dy * 0.1),
                  (cx + dy * 0.08 - dx * 0.05, cy - dx * 0.08 - dy * 0.05),
                  (cx - dy * 0.08 - dx * 0.05, cy + dx * 0.08 - dy * 0.05),
                  (cx - dy * 0.08 + dx * 0.1, cy + dx * 0.08 + dy * 0.1)], (126, 52, 48, 255))
    else:
        pen.capsule(hx - dx * 0.05, hy - dy * 0.05, hx + dx * 0.4, hy + dy * 0.4, 0.04, WOOD)
        pen.ellipse(hx + dx * 0.4, hy + dy * 0.4, 0.035, 0.035, (120, 190, 90, 255))


def draw_head(pen, p, look):
    hair, extra = look["hair"], look["extra"]
    long_hair = extra == "glasses"
    pen.ellipse(-0.05, 0.69 if long_hair else 0.74, 0.2, 0.27 if long_hair else 0.21, hair)
    pen.ellipse(0.02, 0.72, 0.19, 0.19, SKIN_TONE)
    for ex in (0.08, 0.16):
        if p.eyes == "open":
            pen.ellipse(ex, 0.7, 0.026, 0.042, EYE, outline=False)
            pen.ellipse(ex + 0.008, 0.715, 0.009, 0.012, WHITE, outline=False)
        elif p.eyes == "hurt":  # > <
            pen.poly([(ex - 0.03, 0.73), (ex + 0.02, 0.705), (ex - 0.03, 0.68)], EYE, outline=False)
        else:
            pen.capsule(ex - 0.025, 0.695, ex + 0.025, 0.695, 0.014, EYE)
    if p.mouth:
        pen.ellipse(0.15, 0.615, 0.025, 0.03, (150, 60, 70, 255))
    else:
        pen.capsule(0.13, 0.62, 0.16, 0.62, 0.01, (150, 60, 70, 255))
    pen.poly([(-0.2, 0.76), (-0.12, 0.9), (0.02, 0.94), (0.16, 0.89), (0.22, 0.77), (0.16, 0.79),
              (0.11, 0.75), (0.06, 0.8), (0.0, 0.76), (-0.06, 0.81), (-0.1, 0.74)], hair)
    if extra == "glasses":
        for ex in (0.08, 0.16):
            pen.draw.ellipse(_box(pen, ex, 0.7, 0.056), outline=(150, 112, 52, 255), width=pen.stroke)
    elif extra == "apron":  # barbe
        pen.poly([(0.0, 0.66), (0.08, 0.57), (0.16, 0.56), (0.21, 0.63), (0.19, 0.66), (0.1, 0.62)], hair)
    elif extra == "cap":
        pen.poly([(-0.2, 0.8), (-0.15, 0.93), (0.02, 0.98), (0.17, 0.92), (0.2, 0.84), (0.31, 0.83),
                  (0.3, 0.8)], (210, 64, 64, 255))


def _box(pen, x, y, r):
    x0, y0 = pen.pt(x - r, y + r)
    x1, y1 = pen.pt(x + r, y - r)
    return [min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)]


def draw_character(pen, p, look):
    color, prop = look["color"], look["prop"]
    if p.glow:
        r = 0.3 + 0.18 * p.glow
        pen.ellipse(0.05, 0.55, r, r, GLOW, outline=False)
        pen.ellipse(0.05, 0.55, r - 0.05, r - 0.05, (0, 0, 0, 0), outline=False)
        for k in range(int(2 + 4 * p.glow)):
            t = 2 * math.pi * k / 6 + p.glow
            pen.spark(0.05 + r * math.cos(t), 0.55 + r * math.sin(t), 0.05, GLOW_LIGHT)
    pen.limb(-0.03, 0.47, p.back_arm, 0.18, 0.065, shade(color, 0.8))
    for x, angle, tone in ((-0.05, p.back_leg, 0.65), (0.05, p.front_leg, 0.8)):
        fx, fy = pen.limb(x, HIP + 0.02, angle, LEG - 0.03, 0.08, shade(color, tone))
        pen.ellipse(fx + 0.025, max(fy, 0.0) + 0.02, 0.055, 0.03, SHOE)
    pen.poly([(-0.15, 0.2), (0.16, 0.2), (0.1, 0.52), (-0.09, 0.52)], color)
    pen.poly([(-0.13, 0.3), (0.145, 0.3), (0.14, 0.33), (-0.135, 0.33)], shade(color, 0.6), outline=False)
    if look["extra"] == "apron":
        pen.poly([(-0.02, 0.21), (0.15, 0.21), (0.11, 0.45), (0.0, 0.45)], (96, 84, 80, 255))
    draw_head(pen, p, look)
    angle = p.front_arm if p.prop is None else p.prop
    hand = pen.limb(0.03, 0.47, angle, 0.18, 0.065, color)
    if p.prop is not None:
        draw_prop(pen, prop, hand, angle)
    pen.ellipse(hand[0], hand[1], 0.035, 0.035, SKIN_TONE)
    if p.burst:  # croissant de l'onde, devant le personnage
        outer = [(0.45 + 0.32 * math.cos(t), 0.5 + 0.38 * math.sin(t))
                 for t in [math.radians(a) for a in range(-75, 80, 10)]]
        inner = [(0.36 + 0.24 * math.cos(t), 0.5 + 0.3 * math.sin(t))
                 for t in [math.radians(a) for a in range(75, -80, -10)]]
        pen.poly(outer + inner, GLOW)
        pen.spark(0.82, 0.62, 0.06, GLOW_LIGHT)
        pen.spark(0.78, 0.34, 0.05, GLOW_LIGHT)


# --- Ennemi (créature à quatre pattes et long cou, comme un Timere) ---------------------------


def enemy_poses(anim, count):
    result = []
    for i in range(count):
        s = math.sin(2 * math.pi * i / count)
        if anim == "repos":
            result.append(Pose(bob=0.015 * s, neck=(0.42, 0.84 + 0.02 * s)))
        elif anim == "marche":
            result.append(Pose(legs=0.25 * s, neck=(0.44, 0.83 + 0.02 * abs(s))))
        elif anim == "course":
            result.append(Pose(legs=0.45 * s, lean=0.12, neck=(0.58, 0.72), bob=0.02 * abs(s)))
        elif anim == "fouet":  # la langue fouette devant (images 1 et 2)
            result.append(Pose(neck=[(0.34, 0.9), (0.46, 0.84), (0.48, 0.82), (0.42, 0.85)][i],
                               mouth=0.6, whip=[0.2, 0.85, 0.75, 0.35][i]))
        elif anim == "morsure":  # la tête plonge, gueule ouverte puis refermée (images 1 et 2)
            result.append(Pose(neck=[(0.34, 0.9), (0.66, 0.66), (0.7, 0.62), (0.48, 0.78)][i],
                               mouth=[0.0, 1.0, 0.2, 0.0][i], lean=[-0.06, 0.1, 0.12, 0.0][i]))
        elif anim == "degats":
            result.append(Pose(lean=[-0.2, -0.12, 0.04, -0.08, 0.0][i], flash=i in (0, 2),
                               eyes="hurt", neck=(0.36, 0.86)))
        else:  # s'effondre, puis s'aplatit
            k = i / (count - 1)
            result.append(Pose(sink=0.3 * k, legs=-0.9 * k, eyes="closed" if i > 1 else "hurt",
                               neck=(0.45 + 0.2 * k, 0.84 - 0.66 * k), lean=0.0))
    return result


def draw_enemy(pen, p, look):
    color = shade(look["color"], 1.45) if p.flash else look["color"]
    dark, belly = shade(color, 0.7), shade(color, 1.25)
    cy, ry = 0.45 - p.sink, 0.26 - 0.1 * (p.sink / 0.3)

    def leg(k, x, side, tone):
        """Patte d'araignée : genou haut, hors du corps ; en marche, les pattes alternent."""
        spread = p.legs * (1 if k % 2 else -1) if p.legs >= 0 else -p.legs * side
        kx, ky = x + side * 0.2 + 0.06 * spread, cy + 0.12
        pen.capsule(x, cy - 0.06, kx, ky, 0.065, tone)
        pen.capsule(kx, ky, x + side * 0.3 + 0.12 * spread, 0.02, 0.05, tone)

    leg(0, -0.28, -1, dark)
    leg(1, 0.06, 1, dark)
    pen.ellipse(0.0, cy, 0.36, ry, color)
    leg(2, -0.12, -1, color)
    leg(3, 0.22, 1, color)
    pen.ellipse(0.04, cy - ry * 0.45, 0.24, ry * 0.4, belly, outline=False)
    for k in range(4):
        x = -0.24 + 0.14 * k
        top = cy + ry * math.sqrt(max(0.0, 1 - (x / 0.36) ** 2))
        pen.poly([(x - 0.04, top - 0.02), (x - 0.06, top + 0.07), (x + 0.04, top - 0.02)], dark)
    hx, hy = p.neck
    pen.capsule(0.18, cy + 0.1, hx - 0.05, hy - 0.03, 0.13, color)
    if p.whip is not None:  # langue en fouet, sa longueur suit l'élan
        points = [(hx + 0.1 + p.whip * t, hy - 0.05 + 0.12 * math.sin(math.pi * t) * (1 - p.whip))
                  for t in [j / 6 for j in range(7)]]
        for (x0, y0), (x1, y1) in zip(points, points[1:]):
            pen.capsule(x0, y0, x1, y1, 0.045, (200, 80, 110, 255))
    pen.ellipse(hx, hy, 0.15, 0.11, color)
    jaw = 0.02 + 0.09 * p.mouth
    pen.poly([(hx + 0.02, hy - 0.03), (hx + 0.17, hy - 0.02 - jaw), (hx + 0.02, hy - 0.06 - jaw)],
             (120, 30, 40, 255))
    for k in range(3):
        tx = hx + 0.06 + 0.035 * k
        pen.poly([(tx, hy - 0.03), (tx + 0.02, hy - 0.03), (tx + 0.01, hy - 0.06)], WHITE, outline=False)
    for ex in (hx + 0.02, hx + 0.08):
        if p.eyes == "open":
            pen.ellipse(ex, hy + 0.04, 0.025, 0.025, (250, 226, 90, 255))
        else:
            pen.capsule(ex - 0.02, hy + 0.04, ex + 0.02, hy + 0.04, 0.015, EYE)


# --- Planches ----------------------------------------------------------------------------------


def render(draw_fn, pose, look, unit):
    """Toile RGBA et ancre (px) d'une pose ; unit = px par unité de hauteur."""
    size = int(unit * 2.6)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    origin = (size // 2, int(unit * 1.8))
    draw_fn(Pen(img, origin, unit, pose), pose, look)
    return img, origin


def frame(draw_fn, pose, look, unit):
    """Image recadrée et ancre (x, y) ; le cadre englobe toujours l'ancre (comme l'easter egg)."""
    img, (ax, ay) = render(draw_fn, pose, look, unit)
    box = img.getbbox()
    box = (min(box[0], ax), min(box[1], ay), max(box[2], ax + 1), max(box[3], ay))
    return img.crop(box), (ax - box[0], ay - box[1])


def build_sheet(draw_fn, poses_fn, animations, look, height_m):
    """Planche et JSON ; la 1re image de repos mesure height_m à 0,0104 m par pixel (densité de
    Chtholly), donc pixel_size = height_m / sa hauteur est le même pour toutes les planches."""
    height_px = round(height_m / METERS_PER_PIXEL)
    idle = frame(draw_fn, poses_fn("repos", 1)[0], look, height_px)[0]
    unit = height_px * height_px / float(idle.height)
    rows = [(name, settings, [frame(draw_fn, p, look, unit) for p in poses_fn(name, count)])
            for name, settings, count in animations]
    width = max(sum(img.width + SPACING for img, _ in frames) for _, _, frames in rows)
    total_h = sum(max(img.height for img, _ in frames) + SPACING for _, _, frames in rows)
    sheet = Image.new("RGBA", (width, total_h), (0, 0, 0, 0))
    meta_anims = {}
    y = 0
    for name, settings, frames in rows:
        x, images = 0, []
        for img, (anchor_x, anchor_y) in frames:
            sheet.paste(img, (x, y))
            images.append([x, y, img.width, img.height, anchor_x, anchor_y])
            x += img.width + SPACING
        meta_anims[name] = dict(settings, images=images)
        y += max(img.height for img, _ in frames) + SPACING
    meta = {"version": 1, "echelle": 2, "planche": [sheet.width, sheet.height], "format": FORMAT_NOTE,
            "animations": meta_anims}
    return sheet, meta


def portrait(look):
    """Buste carré sur un fond rond teinté de la couleur du personnage."""
    unit = PORTRAIT_SIZE / 0.62
    img, (ax, ay) = render(draw_character, Pose(front_arm=0.6), look, unit)
    cx, cy = ax + 0.03 * unit, ay - 0.68 * unit
    half = PORTRAIT_SIZE / 2
    bust = img.crop((int(cx - half), int(cy - half), int(cx - half) + PORTRAIT_SIZE,
                     int(cy - half) + PORTRAIT_SIZE))
    result = Image.new("RGBA", (PORTRAIT_SIZE, PORTRAIT_SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(result).ellipse([2, 2, PORTRAIT_SIZE - 3, PORTRAIT_SIZE - 3],
                                   fill=shade(look["color"], 1.7), outline=shade(look["color"], 0.6), width=3)
    return Image.alpha_composite(result, bust)


def write_sheet(out_dir, asset_id, sheet, meta):
    os.makedirs(out_dir, exist_ok=True)
    png = os.path.join(out_dir, asset_id + ".png")
    sheet.save(png, optimize=True)
    with open(os.path.join(out_dir, asset_id + ".json"), "w", encoding="utf-8") as handle:
        handle.write(json.dumps(meta, ensure_ascii=False, separators=(",", ":")) + "\n")
    print("planche %s : %d x %d" % (png, sheet.width, sheet.height))


def write_tres(skin_id, display_name, height_m):
    path = os.path.join(ROOT, "data", "skins", skin_id + ".tres")
    base = "res://assets/characters/%s/%s" % (skin_id, skin_id)
    text = "\n".join([
        '[gd_resource type="Resource" script_class="SkinData" format=3]',
        "",
        '[ext_resource type="Script" path="res://src/visuals/skin_data.gd" id="1_skin"]',
        '[ext_resource type="Texture2D" path="%s.png" id="2_sheet"]' % base,
        '[ext_resource type="JSON" path="%s.json" id="3_frames"]' % base,
        '[ext_resource type="Texture2D" path="%s_portrait.png" id="4_portrait"]' % base,
        "",
        "[resource]",
        'script = ExtResource("1_skin")',
        'id = &"%s"' % skin_id,
        'display_name = "%s"' % display_name,
        'sprite_sheet = ExtResource("2_sheet")',
        'frames_json = ExtResource("3_frames")',
        'portrait = ExtResource("4_portrait")',
        "height_m = %s" % repr(float(height_m)),
        "",
    ])
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    print("skin %s" % os.path.relpath(path, ROOT))


def make_skin(skin_id, display_name, look, height_m, with_tres, out_dir=None):
    out_dir = out_dir or os.path.join(ROOT, "assets", "characters", skin_id)
    sheet, meta = build_sheet(draw_character, character_poses, CHARACTER_ANIMATIONS, look, height_m)
    write_sheet(out_dir, skin_id, sheet, meta)
    portrait(look).save(os.path.join(out_dir, skin_id + "_portrait.png"), optimize=True)
    if with_tres:
        write_tres(skin_id, display_name, height_m)


def make_enemy(enemy_id, color, height_m, out_dir=None):
    out_dir = out_dir or os.path.join(ROOT, "assets", "enemies", enemy_id)
    sheet, meta = build_sheet(draw_enemy, enemy_poses, ENEMY_ANIMATIONS, {"color": color}, height_m)
    write_sheet(out_dir, enemy_id, sheet, meta)


def make_checker(path, size, cells, colors):
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    step = size // cells
    for cy in range(cells):
        for cx in range(cells):
            draw.rectangle([cx * step, cy * step, (cx + 1) * step - 1, (cy + 1) * step - 1],
                           fill=hex_color(colors[(cx + cy) % 2])[:3])
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    img.save(path, optimize=True)
    print("damier %s" % path)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    skin = sub.add_parser("skin", help="une planche de personnage et son portrait")
    skin.add_argument("skin_id")
    skin.add_argument("--name", required=True)
    skin.add_argument("--color", default="#7f8fd6", help="tenue")
    skin.add_argument("--hair", default="#5c4033")
    skin.add_argument("--prop", default="sword", choices=["sword", "hammer", "book", "stick"])
    skin.add_argument("--extra", default="", choices=["", "glasses", "apron", "cap"])
    skin.add_argument("--height", type=float, default=1.5, help="taille debout en mètres")
    skin.add_argument("--tres", action="store_true", help="écrit aussi data/skins/<id>.tres")
    skin.add_argument("--out", help="dossier de sortie (défaut : assets/characters/<id>)")
    sub.add_parser("npcs", help="les trois PNJ du village, avec leurs .tres")
    enemy = sub.add_parser("enemy", help="une planche d'ennemi (animations du Timere)")
    enemy.add_argument("enemy_id")
    enemy.add_argument("--color", default="#6f8f4f")
    enemy.add_argument("--height", type=float, default=1.0, help="hauteur au repos en mètres")
    enemy.add_argument("--out", help="dossier de sortie (défaut : assets/enemies/<id>)")
    checker = sub.add_parser("checker", help="damier PNG")
    checker.add_argument("path")
    checker.add_argument("--size", type=int, default=64)
    checker.add_argument("--cells", type=int, default=2)
    checker.add_argument("--colors", nargs=2, default=["#8ccf6e", "#7cc061"])
    args = parser.parse_args()
    if args.command == "skin":
        look = {"color": hex_color(args.color), "hair": hex_color(args.hair), "prop": args.prop,
                "extra": args.extra}
        make_skin(args.skin_id, args.name, look, args.height, args.tres, args.out)
    elif args.command == "npcs":
        for skin_id, name, color, height, hair, prop, extra in NPCS:
            look = {"color": hex_color(color), "hair": hex_color(hair), "prop": prop, "extra": extra}
            make_skin(skin_id, name, look, height, True)
    elif args.command == "enemy":
        make_enemy(args.enemy_id, hex_color(args.color), args.height, args.out)
    else:
        make_checker(args.path, args.size, args.cells, args.colors)


if __name__ == "__main__":
    main()
