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
    # les PNJ de l'acte 1 (liste NPCS) : planches et visuels non jouables data/npcs/visuals/<id>.tres
    python3 tools/gen_placeholders.py npcs
    # une fée de la communauté, cheveux longs, écharpe : options d'apparence facultatives
    python3 tools/gen_placeholders.py skin fairy_x --name "X" --hair "#3fc1b0" --style long \
        --wear scarf --accent "#c8423b" --height 1.3
    # portrait d'une planche existante (tête de la 1re image de repos agrandie ×2)
    python3 tools/gen_placeholders.py portrait chtholly --color "#5b7fd0" --side 80 --forward 6
    # un ennemi : assets/enemies/<id>/<id>.png + .json (son SkinData va dans data/enemies/visuals/)
    python3 tools/gen_placeholders.py enemy <id> --color "#6f8f4f" --height 1.0
    # damier (sol de la greybox)
    python3 tools/gen_placeholders.py checker assets/textures/checker.png

--out <dossier> écrit la planche ailleurs (essais). Le résultat est déterministe (aucun
hasard) ; les fichiers générés sont versionnés.

Apparence (facultative, défauts = la silhouette d'origine) : --style (coiffure : short, long,
twintails, braid, side_tail, frizzy, messy, over_eye, none), --species (human, cat, dog, bear,
lizard, sheep : tête d'homme-bête), --skin (peau, fourrure ou écailles), --eyes, --accent
(couleur des accessoires) et --wear (liste séparée par des virgules : apron, headdress, headband,
headscarf, hat, pilot_cap, goggles, scarf, vest, buttons, cape, collar, ribbons, feathers,
flour, book, basket, spyglass). Les PNJ de l'acte 1 (HISTOIRE.md, sections 5.1 et 5.2) en sont faits : des
planches de remplacement, en attendant les vraies.
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

# PNJ de l'acte 1 (docs/lore/HISTOIRE.md, sections 5.1 et 5.2 ; couleurs indicatives de
# docs/lore/BIBLE.md, section 5) : planches de remplacement et visuels non jouables
# (data/npcs/visuals/<id>.tres). Clés : id, nom, taille (m), tenue (color), cheveux ou fourrure
# (hair), puis l'apparence facultative (style, species, skin, eyes, accent, wear : accessoires,
# « nom » ou « nom:#couleur »).
NPCS = [
    dict(id="nygglatho", name="Nygglatho", height=1.85, color="#4fa548", hair="#ec9aa0",
         style="long", eyes="#6cc24a", wear=["apron:#f7f3ea", "headdress:#ffffff"]),
    dict(id="willem", name="Willem", height=1.75, color="#2b3452", hair="#26222c",
         style="messy", eyes="#2c2a33", wear=["buttons:#d9b04a"]),
    dict(id="ithea", name="Ithea", height=1.45, color="#9a4a3c", hair="#f3d49a",
         style="braid", eyes="#c98a2e", wear=["vest:#a9c98f", "scarf:#c8423b"]),
    dict(id="nephren", name="Nephren", height=1.3, color="#7b4fa0", hair="#d6d2e8",
         style="twintails", eyes="#3a3a46", wear=["ribbons:#2b2430", "book:#a33b3b"]),
    dict(id="tiat", name="Tiat", height=1.1, color="#f1ede2", hair="#78b89e",
         eyes="#3e8a5c", wear=["vest:#3f6b4a"]),
    dict(id="pannibal", name="Pannibal", height=1.25, color="#4a3b5c", hair="#9b3fd6",
         style="over_eye", eyes="#7a2fb0", wear=["cape:#5e4a78"]),
    dict(id="collon", name="Collon", height=1.2, color="#d99a5b", hair="#f08cb4",
         style="long", wear=["headband:#d23c3c"]),
    dict(id="lakhesh", name="Lakhesh", height=1.2, color="#eadfcf", hair="#f5a878",
         style="side_tail", eyes="#6b4426", wear=["vest:#8a5a3b", "buttons:#d9b04a"]),
    dict(id="almita", name="Almita", height=0.95, color="#9fc7e8", hair="#f2e03c",
         style="frizzy"),
    dict(id="limeskin", name="Limeskin", height=2.8, color="#38476a", hair="#c9a86a",
         style="braid", species="lizard", skin="#f1ede0", eyes="#d9a21e",
         wear=["buttons:#d9b04a", "collar:#c8423b", "feathers"]),
    dict(id="cat_waiter", name="Serveur", height=1.65, color="#f4f1ea", hair="#7d828c",
         species="cat", skin="#c9ccd2", eyes="#d9a21e", wear=["apron:#34343c"]),
    dict(id="ramikeldi", name="M. Rami", height=1.7, color="#f4f1ea", hair="#b98d5f",
         species="cat", skin="#e2c49c", eyes="#d9a21e", wear=["vest:#7a2430", "hat:#3b2e2a"]),
    dict(id="snack_vendor", name="Cuistot du snack", height=1.6, color="#c06b3a",
         hair="#a87346", species="dog", skin="#e1c49a", wear=["apron:#e9e2d0", "flour"]),
    dict(id="baker", name="Boulanger", height=2.0, color="#f2eee6", hair="#6e4a2e",
         species="bear", skin="#a77b55", wear=["apron:#f7f3ea", "flour"]),
    dict(id="ferryman", name="Passeur", height=1.7, color="#d9b23a", hair="#6e9a5a",
         species="lizard", skin="#7aa364", eyes="#e8c02e", wear=["pilot_cap:#5a4a3a", "goggles"]),
    dict(id="egg_vendor", name="Marchande d’œufs", height=1.55, color="#a8754d",
         hair="#f3ecdc", species="sheep", eyes="#5a3a2a", wear=["headscarf:#d9534f", "basket"]),
    dict(id="garde_lookout", name="Guetteur", height=1.9, color="#34405e", hair="#8ba05a",
         species="lizard", skin="#8ba05a", eyes="#e8c02e", wear=["buttons:#c9a15a", "spyglass"]),
]
# Visuels des PNJ : hors de data/skins/, donc non jouables (comme le visuel du Timere).
NPC_VISUALS_DIR = os.path.join("data", "npcs", "visuals")

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


def _style(look):
    """Coiffure : celle demandée, sinon longue avec les lunettes (bibliothécaire d'origine)."""
    return look.get("style") or ("long" if look.get("extra") == "glasses" else "short")


def _color(look, name, default=(236, 232, 222, 255)):
    """Couleur de l'accessoire name : la sienne (« vest:#a9c98f »), sinon --accent, sinon default."""
    return look.get("wear", {}).get(name) or look.get("accent") or default


def _eyes(pen, p, color, spots=(0.08, 0.16)):
    for ex in spots:
        if p.eyes == "open":
            pen.ellipse(ex, 0.7, 0.026, 0.042, color, outline=False)
            pen.ellipse(ex + 0.008, 0.715, 0.009, 0.012, WHITE, outline=False)
        elif p.eyes == "hurt":  # > <
            pen.poly([(ex - 0.03, 0.73), (ex + 0.02, 0.705), (ex - 0.03, 0.68)], color, outline=False)
        else:
            pen.capsule(ex - 0.025, 0.695, ex + 0.025, 0.695, 0.014, color)


def _mouth(pen, p, x=0.13, y=0.62):
    if p.mouth:
        pen.ellipse(x + 0.02, y - 0.005, 0.025, 0.03, (150, 60, 70, 255))
    else:
        pen.capsule(x, y, x + 0.03, y, 0.01, (150, 60, 70, 255))


def draw_back(pen, p, look):
    """Ce qui passe derrière le corps : cape, cheveux longs, tresse, couettes, queue de côté
    (seulement avec un --style explicite : les silhouettes d'origine n'en ont pas)."""
    hair, style, wear = look["hair"], look.get("style"), look.get("wear", {})
    if "cape" in wear:
        pen.poly([(-0.07, 0.53), (-0.25, 0.2), (-0.12, 0.17), (0.02, 0.5)], _color(look, "cape"))
    if style == "long":
        pen.poly([(-0.1, 0.8), (-0.24, 0.72), (-0.27, 0.4), (-0.14, 0.36), (-0.06, 0.6)], hair)
    elif style == "braid":
        for k in range(7):
            pen.ellipse(-0.16 - 0.012 * k, 0.72 - 0.055 * k, 0.04, 0.034, hair)
        end = (-0.24, 0.33)
        if "feathers" in wear:
            for dx, dy in ((-0.05, -0.08), (0.02, -0.09)):
                pen.poly([end, (end[0] + dx - 0.02, end[1] + dy), (end[0] + dx * 0.6, end[1] + dy * 1.3),
                          (end[0] + dx + 0.02, end[1] + dy)], wear["feathers"] or (246, 242, 230, 255))
        else:
            pen.ellipse(end[0], end[1] + 0.02, 0.028, 0.028, wear.get("pearl") or (90, 140, 220, 255))
    elif style == "twintails":
        for k in range(6):
            wave = 0.02 * math.sin(k * 1.3)
            pen.ellipse(-0.2 - 0.016 * k + wave, 0.76 - 0.06 * k, 0.055, 0.045, hair)
    elif style == "side_tail":
        pen.poly([(-0.16, 0.86), (-0.29, 0.82), (-0.31, 0.66), (-0.21, 0.72)], hair)


def draw_beast_head(pen, p, look, species):
    """Tête d'homme-bête : chat, chien, ours, lézard (reptilien) ou mouton (sang-mêlé)."""
    fur, eye = look["hair"], look.get("eyes", EYE)
    skin = look.get("skin", SKIN_TONE)
    dark = (44, 34, 36, 255)
    if species == "cat":
        pen.poly([(-0.15, 0.82), (-0.11, 1.0), (-0.01, 0.89)], fur)
        pen.ellipse(0.02, 0.73, 0.2, 0.2, fur)
        pen.ellipse(0.07, 0.67, 0.14, 0.12, skin, outline=False)
        pen.poly([(0.03, 0.89), (0.1, 1.04), (0.17, 0.86)], fur)
        pen.poly([(0.07, 0.9), (0.1, 0.98), (0.14, 0.88)], (236, 160, 170, 255), outline=False)
        _eyes(pen, p, eye)
        pen.poly([(0.2, 0.66), (0.23, 0.67), (0.215, 0.645)], (226, 120, 140, 255), outline=False)
        for y, dy in ((0.64, 0.01), (0.62, -0.01)):
            pen.capsule(0.19, y, 0.3, y + dy, 0.006, dark)
        _mouth(pen, p, 0.15, 0.6)
    elif species == "dog":
        pen.ellipse(0.0, 0.74, 0.19, 0.2, fur)
        pen.ellipse(0.19, 0.64, 0.11, 0.075, skin)
        pen.ellipse(0.29, 0.665, 0.032, 0.026, dark, outline=False)
        _eyes(pen, p, eye, (0.05, 0.13))
        pen.poly([(-0.05, 0.9), (-0.19, 0.84), (-0.21, 0.62), (-0.11, 0.65)], shade(fur, 0.75))
        _mouth(pen, p, 0.17, 0.595)
    elif species == "bear":
        for ex, ey in ((-0.11, 0.9), (0.09, 0.93)):
            pen.ellipse(ex, ey, 0.07, 0.07, fur)
            pen.ellipse(ex, ey, 0.035, 0.035, skin, outline=False)
        pen.ellipse(0.02, 0.73, 0.22, 0.2, fur)
        pen.ellipse(0.16, 0.65, 0.1, 0.075, skin)
        pen.ellipse(0.245, 0.68, 0.038, 0.028, dark, outline=False)
        _eyes(pen, p, eye, (0.06, 0.14))
        _mouth(pen, p, 0.16, 0.6)
    elif species == "lizard":
        horn = shade(skin, 0.72)
        pen.poly([(-0.07, 0.86), (-0.27, 1.0), (-0.13, 0.82)], horn)
        pen.poly([(0.0, 0.89), (-0.16, 1.05), (-0.06, 0.86)], horn)
        pen.ellipse(0.0, 0.74, 0.18, 0.17, skin)
        pen.poly([(0.06, 0.82), (0.34, 0.71), (0.34, 0.63), (0.06, 0.6)], skin)
        for k in range(3):
            x = -0.12 + 0.07 * k
            pen.poly([(x - 0.03, 0.88 - 0.02 * k), (x, 0.95 - 0.02 * k), (x + 0.03, 0.89 - 0.02 * k)],
                     horn)
        pen.ellipse(0.3, 0.695, 0.012, 0.01, dark, outline=False)
        pen.capsule(0.12, 0.635, 0.32, 0.645, 0.008, shade(skin, 0.5))
        if p.eyes == "open":
            pen.ellipse(0.1, 0.745, 0.04, 0.04, eye)
            pen.capsule(0.105, 0.72, 0.105, 0.77, 0.012, dark)
        elif p.eyes == "hurt":
            pen.poly([(0.07, 0.77), (0.12, 0.745), (0.07, 0.72)], dark, outline=False)
        else:
            pen.capsule(0.07, 0.745, 0.13, 0.745, 0.014, dark)
    else:  # mouton : laine bouclée, oreilles tombantes, visage de sang-mêlé
        for k in range(9):
            a = math.radians(40 + 30 * k)
            pen.ellipse(-0.03 + 0.19 * math.cos(a), 0.75 + 0.19 * math.sin(a), 0.075, 0.075, fur)
        pen.ellipse(0.02, 0.72, 0.19, 0.19, skin)
        pen.poly([(-0.07, 0.79), (-0.29, 0.73), (-0.27, 0.67), (-0.07, 0.72)], shade(skin, 0.9))
        _eyes(pen, p, eye)
        _mouth(pen, p)
        for k in range(5):
            pen.ellipse(-0.08 + 0.055 * k, 0.88 - 0.012 * k, 0.045, 0.04, fur)


def draw_head_wear(pen, look):
    """Coiffes et accessoires de tête (après la tête, par-dessus les cheveux)."""
    wear = look.get("wear", {})
    if "headdress" in wear:  # coiffe blanche à volants
        pen.poly([(-0.14, 0.86), (-0.1, 0.95), (-0.04, 0.92), (0.0, 0.98), (0.05, 0.93), (0.1, 0.96),
                  (0.14, 0.88), (0.08, 0.89), (-0.08, 0.87)], _color(look, "headdress", WHITE))
    if "headband" in wear:
        pen.capsule(-0.18, 0.84, 0.18, 0.9, 0.04, _color(look, "headband"))
    if "headscarf" in wear:  # fichu noué sous la laine
        cloth = _color(look, "headscarf")
        pen.poly([(-0.16, 0.82), (-0.08, 0.95), (0.06, 0.98), (0.17, 0.9), (0.12, 0.84), (-0.02, 0.86)],
                 cloth)
        pen.poly([(-0.16, 0.82), (-0.26, 0.74), (-0.2, 0.72)], cloth)
    if "hat" in wear:
        felt = _color(look, "hat")
        pen.ellipse(0.0, 0.92, 0.26, 0.035, felt)
        pen.poly([(-0.13, 0.93), (-0.11, 1.07), (0.11, 1.07), (0.13, 0.93)], felt)
        pen.poly([(-0.125, 0.95), (0.125, 0.95), (0.122, 0.975), (-0.122, 0.975)], shade(felt, 0.55),
                 outline=False)
    if "pilot_cap" in wear:
        pen.poly([(-0.17, 0.84), (-0.13, 0.95), (0.02, 0.99), (0.15, 0.94), (0.18, 0.86), (0.32, 0.84),
                  (0.31, 0.81)], _color(look, "pilot_cap"))
    if "goggles" in wear:
        pen.capsule(-0.16, 0.86, 0.16, 0.88, 0.03, (80, 64, 52, 255))
        for gx in (0.07, 0.15):
            pen.ellipse(gx, 0.88, 0.035, 0.035, wear["goggles"] or (176, 214, 226, 255))
    if "ribbons" in wear and _style(look) == "twintails":
        ribbon = _color(look, "ribbons")
        pen.poly([(-0.18, 0.84), (-0.26, 0.9), (-0.25, 0.79)], ribbon)
        pen.poly([(-0.18, 0.84), (-0.1, 0.9), (-0.11, 0.79)], ribbon)


def draw_body_wear(pen, look):
    """Gilet, tablier, farine, boutons, écharpe, collier : par-dessus la tenue."""
    wear = look.get("wear", {})
    if "vest" in wear:
        pen.poly([(-0.135, 0.3), (0.06, 0.3), (0.05, 0.52), (-0.09, 0.52)], _color(look, "vest"))
    if "apron" in wear:
        pen.poly([(-0.03, 0.21), (0.155, 0.21), (0.115, 0.47), (0.0, 0.47)],
                 _color(look, "apron", (247, 243, 234, 255)))
    if "flour" in wear:
        for fx, fy in ((-0.08, 0.42), (0.05, 0.27), (-0.11, 0.25), (0.09, 0.4)):
            pen.ellipse(fx, fy, 0.018, 0.014, (252, 250, 244, 255), outline=False)
    if "buttons" in wear:
        gold = _color(look, "buttons", (217, 176, 74, 255))
        for by in (0.26, 0.34, 0.42):
            pen.ellipse(0.16 - (by - 0.2) * 0.1875 - 0.03, by, 0.015, 0.015, gold, outline=False)
    if "scarf" in wear:
        scarf = _color(look, "scarf")
        pen.capsule(-0.1, 0.53, 0.12, 0.53, 0.06, scarf)
        pen.capsule(-0.08, 0.52, -0.18, 0.38, 0.05, scarf)
    if "collar" in wear:
        for k in range(5):
            pen.ellipse(-0.06 + 0.045 * k, 0.5 - 0.004 * k, 0.016, 0.02, _color(look, "collar"),
                        outline=False)


def draw_hand_item(pen, look, hand):
    """Objet tenu au repos (livre, panier, longue-vue), quand la main n'a pas d'arme."""
    wear, (hx, hy) = look.get("wear", {}), hand
    if "book" in wear:
        pen.poly([(hx - 0.02, hy + 0.04), (hx + 0.09, hy + 0.05), (hx + 0.08, hy - 0.08),
                  (hx - 0.03, hy - 0.09)], wear["book"] or (163, 59, 59, 255))
    if "basket" in wear:
        pen.capsule(hx - 0.04, hy + 0.0, hx + 0.08, hy + 0.0, 0.015, (150, 112, 60, 255))
        pen.poly([(hx - 0.07, hy - 0.04), (hx + 0.11, hy - 0.04), (hx + 0.08, hy - 0.14),
                  (hx - 0.04, hy - 0.14)], wear["basket"] or (214, 178, 110, 255))
        for ex in (hx - 0.01, hx + 0.04):
            pen.ellipse(ex, hy - 0.035, 0.022, 0.026, (250, 244, 228, 255))
    if "spyglass" in wear:
        pen.capsule(hx - 0.02, hy + 0.02, hx + 0.16, hy + 0.12, 0.035, wear["spyglass"] or (201, 161, 90, 255))


def draw_head(pen, p, look):
    hair, extra = look["hair"], look["extra"]
    species = look.get("species", "human")
    if species != "human":
        draw_beast_head(pen, p, look, species)
        draw_head_wear(pen, look)
        return
    style = _style(look)
    long_hair = style == "long"
    if style == "frizzy":
        for k in range(11):
            a = math.radians(20 + 32 * k)
            pen.ellipse(-0.03 + 0.2 * math.cos(a), 0.74 + 0.2 * math.sin(a), 0.085, 0.085, hair)
    elif style != "none":
        pen.ellipse(-0.05, 0.69 if long_hair else 0.74, 0.2, 0.27 if long_hair else 0.21, hair)
    pen.ellipse(0.02, 0.72, 0.19, 0.19, look.get("skin", SKIN_TONE))
    _eyes(pen, p, look.get("eyes", EYE))
    _mouth(pen, p)
    if style == "messy":
        pen.poly([(-0.21, 0.74), (-0.17, 0.92), (-0.08, 0.9), (-0.03, 0.99), (0.04, 0.92), (0.12, 0.96),
                  (0.15, 0.88), (0.24, 0.8), (0.16, 0.8), (0.18, 0.74), (0.1, 0.77), (0.07, 0.72),
                  (0.03, 0.78), (-0.03, 0.74), (-0.07, 0.8), (-0.12, 0.72)], hair)
    elif style == "over_eye":
        pen.poly([(-0.2, 0.76), (-0.12, 0.9), (0.02, 0.94), (0.16, 0.89), (0.23, 0.74), (0.2, 0.64),
                  (0.13, 0.66), (0.12, 0.74), (0.06, 0.8), (0.0, 0.76), (-0.06, 0.81), (-0.1, 0.74)],
                 hair)
    elif style == "frizzy":
        for k in range(5):
            pen.ellipse(-0.06 + 0.06 * k, 0.88 - 0.015 * k, 0.05, 0.05, hair)
    elif style != "none":
        pen.poly([(-0.2, 0.76), (-0.12, 0.9), (0.02, 0.94), (0.16, 0.89), (0.22, 0.77), (0.16, 0.79),
                  (0.11, 0.75), (0.06, 0.8), (0.0, 0.76), (-0.06, 0.81), (-0.1, 0.74)], hair)
    draw_head_wear(pen, look)
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
    draw_back(pen, p, look)
    pen.limb(-0.03, 0.47, p.back_arm, 0.18, 0.065, shade(color, 0.8))
    for x, angle, tone in ((-0.05, p.back_leg, 0.65), (0.05, p.front_leg, 0.8)):
        fx, fy = pen.limb(x, HIP + 0.02, angle, LEG - 0.03, 0.08, shade(color, tone))
        pen.ellipse(fx + 0.025, max(fy, 0.0) + 0.02, 0.055, 0.03, SHOE)
    pen.poly([(-0.15, 0.2), (0.16, 0.2), (0.1, 0.52), (-0.09, 0.52)], color)
    pen.poly([(-0.13, 0.3), (0.145, 0.3), (0.14, 0.33), (-0.135, 0.33)], shade(color, 0.6), outline=False)
    if look["extra"] == "apron":
        pen.poly([(-0.02, 0.21), (0.15, 0.21), (0.11, 0.45), (0.0, 0.45)], (96, 84, 80, 255))
    draw_body_wear(pen, look)
    draw_head(pen, p, look)
    angle = p.front_arm if p.prop is None else p.prop
    hand = pen.limb(0.03, 0.47, angle, 0.18, 0.065, color)
    if p.prop is not None:
        draw_prop(pen, prop, hand, angle)
    elif not p.lying:
        draw_hand_item(pen, look, hand)
    pen.ellipse(hand[0], hand[1], 0.035, 0.035, look.get("hand", SKIN_TONE))
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
    # Oreilles, cornes et chapeaux dépassent du crâne : le cadre remonte un peu pour les garder.
    tall = look.get("species", "human") != "human" or {"hat", "pilot_cap"} & set(look.get("wear", ()))
    cx, cy = ax + 0.03 * unit, ay - (0.74 if tall else 0.68) * unit
    half = PORTRAIT_SIZE / 2
    bust = img.crop((int(cx - half), int(cy - half), int(cx - half) + PORTRAIT_SIZE,
                     int(cy - half) + PORTRAIT_SIZE))
    return Image.alpha_composite(badge(look["color"], PORTRAIT_SIZE), bust)


def badge(color, size):
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(result).ellipse([2, 2, size - 3, size - 3], fill=shade(color, 1.7),
                                   outline=shade(color, 0.6), width=3)
    return result


def sheet_portrait(skin_id, color, side, top, forward):
    """Portrait d'une planche existante (ex. Chtholly) : carré de side px pris dans la 1re image
    de repos (top px sous son bord haut, centré forward px devant l'ancre), agrandi ×2 sans
    lissage, sur le même fond rond que les placeholders."""
    base = os.path.join(ROOT, "assets", "characters", skin_id, skin_id)
    with open(base + ".json", encoding="utf-8") as handle:
        x, y, _, _, ax, _ = json.load(handle)["animations"]["repos"]["images"][0]
    left = x + ax + forward - side // 2
    head = Image.open(base + ".png").convert("RGBA").crop((left, y + top, left + side, y + top + side))
    result = Image.alpha_composite(badge(color, 2 * side), head.resize((2 * side, 2 * side), Image.NEAREST))
    result.save(base + "_portrait.png", optimize=True)
    print("portrait %s_portrait.png" % os.path.relpath(base, ROOT))


def write_sheet(out_dir, asset_id, sheet, meta):
    os.makedirs(out_dir, exist_ok=True)
    png = os.path.join(out_dir, asset_id + ".png")
    sheet.save(png, optimize=True)
    with open(os.path.join(out_dir, asset_id + ".json"), "w", encoding="utf-8") as handle:
        handle.write(json.dumps(meta, ensure_ascii=False, separators=(",", ":")) + "\n")
    print("planche %s : %d x %d" % (png, sheet.width, sheet.height))


def write_tres(skin_id, display_name, height_m, folder=os.path.join("data", "skins")):
    """SkinData du skin : data/skins/<id>.tres (jouable) ou, pour un PNJ, NPC_VISUALS_DIR."""
    os.makedirs(os.path.join(ROOT, folder), exist_ok=True)
    path = os.path.join(ROOT, folder, skin_id + ".tres")
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


def make_skin(skin_id, display_name, look, height_m, with_tres, out_dir=None, tres_dir=None):
    out_dir = out_dir or os.path.join(ROOT, "assets", "characters", skin_id)
    sheet, meta = build_sheet(draw_character, character_poses, CHARACTER_ANIMATIONS, look, height_m)
    write_sheet(out_dir, skin_id, sheet, meta)
    portrait(look).save(os.path.join(out_dir, skin_id + "_portrait.png"), optimize=True)
    if with_tres:
        write_tres(skin_id, display_name, height_m, tres_dir or os.path.join("data", "skins"))


def make_look(color, hair, prop="stick", extra="", **options):
    """Apparence d'un personnage : tenue, cheveux (ou fourrure), objet du combat, accessoire
    d'origine (extra), puis les options facultatives (style, species, skin, eyes, accent, wear)."""
    look = {"color": hex_color(color), "hair": hex_color(hair), "prop": prop, "extra": extra}
    for key in ("skin", "eyes", "accent"):
        if options.get(key):
            look[key] = hex_color(options[key])
    for key in ("style", "species"):
        if options.get(key):
            look[key] = options[key]
    if options.get("wear"):
        # « vest » ou « vest:#a9c98f » : accessoire, avec sa propre couleur s'il en a une.
        look["wear"] = {}
        for item in options["wear"]:
            name, _, color = item.partition(":")
            look["wear"][name] = hex_color(color) if color else None
    if "skin" in look:
        look["hand"] = look["skin"]
    return look


def make_npcs():
    """Planches de remplacement des PNJ de l'acte 1 et leurs visuels non jouables."""
    for npc in NPCS:
        options = {key: npc[key] for key in ("style", "species", "skin", "eyes", "accent", "wear")
                   if key in npc}
        look = make_look(npc["color"], npc["hair"], **options)
        make_skin(npc["id"], npc["name"], look, npc["height"], True, tres_dir=NPC_VISUALS_DIR)


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
    skin.add_argument("--style", choices=["short", "long", "twintails", "braid", "side_tail", "frizzy",
                                          "messy", "over_eye", "none"], help="coiffure")
    skin.add_argument("--species", choices=["human", "cat", "dog", "bear", "lizard", "sheep"])
    skin.add_argument("--skin", help="peau, fourrure du visage ou écailles")
    skin.add_argument("--eyes", help="couleur des yeux")
    skin.add_argument("--accent", help="couleur des accessoires")
    skin.add_argument("--wear", default="", help="accessoires séparés par des virgules (nom[:#couleur])")
    skin.add_argument("--tres", action="store_true", help="écrit aussi data/skins/<id>.tres")
    skin.add_argument("--out", help="dossier de sortie (défaut : assets/characters/<id>)")
    sub.add_parser("npcs", help="les PNJ de l'acte 1, avec leurs visuels data/npcs/visuals/<id>.tres")
    enemy = sub.add_parser("enemy", help="une planche d'ennemi (animations du Timere)")
    enemy.add_argument("enemy_id")
    enemy.add_argument("--color", default="#6f8f4f")
    enemy.add_argument("--height", type=float, default=1.0, help="hauteur au repos en mètres")
    enemy.add_argument("--out", help="dossier de sortie (défaut : assets/enemies/<id>)")
    shot = sub.add_parser("portrait", help="portrait tiré d'une planche existante (Chtholly)")
    shot.add_argument("skin_id")
    shot.add_argument("--color", default="#5b7fd0", help="fond")
    shot.add_argument("--side", type=int, default=64, help="côté du carré pris dans la planche (px)")
    shot.add_argument("--top", type=int, default=0, help="px sous le haut de l'image de repos")
    shot.add_argument("--forward", type=int, default=4, help="px devant l'ancre")
    checker = sub.add_parser("checker", help="damier PNG")
    checker.add_argument("path")
    checker.add_argument("--size", type=int, default=64)
    checker.add_argument("--cells", type=int, default=2)
    checker.add_argument("--colors", nargs=2, default=["#8ccf6e", "#7cc061"])
    args = parser.parse_args()
    if args.command == "skin":
        wear = [item.strip() for item in args.wear.split(",") if item.strip()]
        look = make_look(args.color, args.hair, args.prop, args.extra, style=args.style,
                         species=args.species, skin=args.skin, eyes=args.eyes, accent=args.accent,
                         wear=wear)
        make_skin(args.skin_id, args.name, look, args.height, args.tres, args.out)
    elif args.command == "npcs":
        make_npcs()
    elif args.command == "enemy":
        make_enemy(args.enemy_id, hex_color(args.color), args.height, args.out)
    elif args.command == "portrait":
        sheet_portrait(args.skin_id, hex_color(args.color), args.side, args.top, args.forward)
    else:
        make_checker(args.path, args.size, args.cells, args.colors)


if __name__ == "__main__":
    main()
