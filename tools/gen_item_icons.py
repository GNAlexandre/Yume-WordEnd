#!/usr/bin/env python3
"""Icônes des objets (64 × 64, fond transparent) : formes simples et couleurs douces (Pillow).

Dessine chaque icône à 4 fois la taille (contours lissés), avec un contour foncé et une ombre
portée floue, puis la réduit. Résultat déterministe ; les PNG générés sont versionnés dans
assets/items/<item_id>.png et référencés par data/items/<item_id>.tres.

Usage (Python 3.9+, pip install Pillow) :

    python3 tools/gen_item_icons.py              # toutes les icônes dans assets/items/
    python3 tools/gen_item_icons.py --size 128   # autre taille (aperçu)
"""

import argparse
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUPERSAMPLE = 4


def rotate(points, degrees, center=(0.5, 0.5)):
    """Tourne des points (unités : côté de l'icône = 1) autour de center, sens horaire à l'écran."""
    a = math.radians(degrees)
    cx, cy = center
    return [
        (cx + (x - cx) * math.cos(a) - (y - cy) * math.sin(a), cy + (x - cx) * math.sin(a) + (y - cy) * math.cos(a))
        for x, y in points
    ]


class Canvas:
    """Dessin en unités normalisées (0..1) sur une image suréchantillonnée."""

    def __init__(self, size):
        self.size = size
        self.image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image)

    def px(self, points):
        return [(x * self.size, y * self.size) for x, y in points]

    def w(self, width):
        return max(1, round(width * self.size))

    def polygon(self, points, fill, outline, width=0.03):
        self.draw.polygon(self.px(points), fill=fill)
        self.draw.line(self.px(points + points[:1]), fill=outline, width=self.w(width), joint="curve")

    def circle(self, cx, cy, r, fill, outline=None, width=0.03):
        box = [(cx - r) * self.size, (cy - r) * self.size, (cx + r) * self.size, (cy + r) * self.size]
        self.draw.ellipse(box, fill=fill, outline=outline, width=self.w(width) if outline else 0)

    def line(self, points, fill, width):
        self.draw.line(self.px(points), fill=fill, width=self.w(width), joint="curve")
        r = width / 2
        for x, y in (points[0], points[-1]):
            self.circle(x, y, r, fill)


def page_fragment(c):
    """Page du livre d'images : feuille crème au coin corné, bas déchiré, une image naïve (un
    Brave à l'épée sous un soleil) et deux lignes de texte."""
    page = [(0.22, 0.13), (0.64, 0.13), (0.78, 0.27), (0.78, 0.80), (0.71, 0.85), (0.64, 0.79),
            (0.56, 0.87), (0.47, 0.80), (0.39, 0.88), (0.31, 0.81), (0.22, 0.86)]
    tilt = -10
    c.polygon(rotate(page, tilt), (255, 247, 226, 255), (170, 124, 86, 255))
    c.polygon(rotate([(0.64, 0.13), (0.64, 0.27), (0.78, 0.27)], tilt), (236, 214, 178, 255),
              (170, 124, 86, 255), 0.025)
    c.polygon(rotate([(0.30, 0.24), (0.62, 0.24), (0.62, 0.55), (0.30, 0.55)], tilt), (196, 228, 246, 255),
              (150, 176, 196, 255), 0.02)
    c.circle(*rotate([(0.55, 0.32)], tilt)[0], 0.045, (255, 214, 92, 255))
    c.polygon(rotate([(0.30, 0.55), (0.30, 0.47), (0.45, 0.43), (0.62, 0.48), (0.62, 0.55)], tilt),
              (124, 196, 112, 255), (124, 196, 112, 255), 0.01)
    c.line(rotate([(0.40, 0.50), (0.40, 0.40)], tilt), (196, 80, 80, 255), 0.045)
    c.circle(*rotate([(0.40, 0.36)], tilt)[0], 0.03, (255, 224, 199, 255))
    c.line(rotate([(0.43, 0.43), (0.50, 0.30)], tilt), (150, 156, 170, 255), 0.025)
    for y, x1 in ((0.65, 0.70), (0.73, 0.58)):
        c.line(rotate([(0.30, y), (x1, y)], tilt), (208, 176, 138, 255), 0.03)


def flower_blue(c):
    """Myosotis : cinq pétales ronds, cœur jaune, tige et feuille."""
    green, dark_green = (110, 186, 104, 255), (62, 130, 70, 255)
    c.line([(0.50, 0.55), (0.48, 0.74), (0.45, 0.92)], dark_green, 0.05)
    c.line([(0.50, 0.55), (0.48, 0.74), (0.45, 0.92)], green, 0.03)
    leaf = [(0.47, 0.80), (0.56, 0.70), (0.70, 0.67), (0.63, 0.78)]
    c.polygon(leaf, green, dark_green, 0.02)
    cx, cy = 0.50, 0.40
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        c.circle(cx + 0.17 * math.cos(a), cy + 0.17 * math.sin(a), 0.15, (112, 164, 242, 255),
                 (64, 104, 196, 255), 0.025)
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        c.circle(cx + 0.19 * math.cos(a), cy + 0.19 * math.sin(a), 0.06, (168, 204, 255, 255))
    c.circle(cx, cy, 0.09, (255, 214, 92, 255), (214, 150, 46, 255), 0.022)
    c.circle(cx - 0.025, cy - 0.025, 0.025, (255, 240, 180, 255))


def laundry_sheet(c):
    """Drap envolé : drap blanc froissé aux plis bleutés, pince à linge de bois."""
    cloth = [(0.16, 0.30), (0.34, 0.22), (0.52, 0.28), (0.70, 0.20), (0.86, 0.30), (0.80, 0.52),
             (0.84, 0.74), (0.66, 0.80), (0.48, 0.74), (0.30, 0.82), (0.14, 0.72), (0.20, 0.50)]
    c.polygon(cloth, (250, 250, 246, 255), (128, 140, 170, 255))
    for points in (((0.34, 0.30), (0.30, 0.52), (0.36, 0.72)), ((0.56, 0.32), (0.60, 0.54), (0.52, 0.70)),
                   ((0.74, 0.30), (0.70, 0.50), (0.74, 0.68))):
        c.line(list(points), (190, 204, 228, 255), 0.025)
    c.polygon([(0.46, 0.08), (0.56, 0.08), (0.55, 0.36), (0.47, 0.36)], (198, 150, 98, 255),
              (130, 90, 56, 255), 0.02)
    c.line([(0.47, 0.20), (0.55, 0.20)], (130, 90, 56, 255), 0.02)


def eggs(c):
    """Œufs frais : trois œufs calés dans un nid de paille."""
    c.polygon([(0.12, 0.62), (0.88, 0.62), (0.80, 0.84), (0.20, 0.84)], (226, 190, 110, 255),
              (160, 120, 60, 255))
    for x0, x1 in ((0.16, 0.36), (0.40, 0.62), (0.66, 0.84)):
        c.line([(x0, 0.70), (x1, 0.76)], (190, 150, 80, 255), 0.02)
    for cx, cy, tone in ((0.34, 0.50, (250, 238, 220, 255)), (0.66, 0.50, (244, 222, 196, 255)),
                         (0.50, 0.46, (255, 246, 232, 255))):
        box = [(cx - 0.14) * c.size, (cy - 0.19) * c.size, (cx + 0.14) * c.size, (cy + 0.17) * c.size]
        c.draw.ellipse(box, fill=tone, outline=(176, 140, 108, 255), width=c.w(0.025))
    c.circle(0.45, 0.36, 0.03, (255, 255, 255, 255))


def wild_berries(c):
    """Baies sauvages : grappe de baies rouges, tige et deux feuilles."""
    green, dark_green = (110, 186, 104, 255), (62, 130, 70, 255)
    c.line([(0.50, 0.12), (0.52, 0.30), (0.46, 0.44)], dark_green, 0.04)
    c.polygon([(0.52, 0.22), (0.70, 0.12), (0.84, 0.18), (0.68, 0.30)], green, dark_green, 0.02)
    c.polygon([(0.50, 0.24), (0.32, 0.12), (0.18, 0.20), (0.34, 0.30)], green, dark_green, 0.02)
    for cx, cy in ((0.40, 0.48), (0.60, 0.46), (0.30, 0.64), (0.50, 0.62), (0.70, 0.62), (0.40, 0.78),
                   (0.60, 0.78)):
        c.circle(cx, cy, 0.105, (214, 52, 70, 255), (130, 24, 44, 255), 0.022)
        c.circle(cx - 0.03, cy - 0.03, 0.025, (255, 170, 176, 255))


def fresh_cream(c):
    """Crème fraîche : pot de grès, crème qui déborde en dôme, étiquette bleue."""
    c.polygon([(0.24, 0.40), (0.76, 0.40), (0.72, 0.86), (0.28, 0.86)], (214, 168, 120, 255),
              (140, 96, 60, 255))
    c.polygon([(0.26, 0.56), (0.74, 0.56), (0.735, 0.64), (0.265, 0.64)], (90, 130, 200, 255),
              (60, 90, 150, 255), 0.015)
    c.circle(0.50, 0.40, 0.27, (255, 252, 240, 255), (196, 186, 166, 255))
    c.polygon([(0.20, 0.42), (0.80, 0.42), (0.80, 0.48), (0.20, 0.48)], (255, 252, 240, 255),
              (255, 252, 240, 255), 0.01)
    c.circle(0.40, 0.30, 0.05, (255, 255, 255, 255))


def clock_gear(c):
    """Engrenage de laiton : douze dents, rayons ajourés, moyeu."""
    brass, dark = (226, 178, 84, 255), (150, 104, 40, 255)
    teeth = []
    for k in range(48):
        a = 2 * math.pi * k / 48
        r = 0.40 if (k // 2) % 2 == 0 else 0.33
        teeth.append((0.5 + r * math.cos(a), 0.5 + r * math.sin(a)))
    c.polygon(teeth, brass, dark, 0.025)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        c.circle(0.5 + 0.17 * math.cos(a), 0.5 + 0.17 * math.sin(a), 0.07, (120, 84, 36, 255))
    c.circle(0.5, 0.5, 0.09, (246, 214, 132, 255), dark, 0.02)
    c.circle(0.5, 0.5, 0.035, (120, 84, 36, 255))


def clock_comb(c):
    """Peigne de carillon : lames d'acier de longueurs décroissantes sur un talon de laiton."""
    c.polygon([(0.14, 0.18), (0.30, 0.18), (0.30, 0.84), (0.14, 0.84)], (214, 168, 80, 255),
              (140, 100, 40, 255))
    for k in range(8):
        y = 0.22 + 0.08 * k
        length = 0.56 - 0.045 * k
        c.polygon([(0.30, y), (0.30 + length, y + 0.012), (0.30 + length, y + 0.048), (0.30, y + 0.06)],
                  (214, 226, 238, 255), (110, 124, 142, 255), 0.012)
    c.circle(0.22, 0.30, 0.03, (140, 100, 40, 255))
    c.circle(0.22, 0.72, 0.03, (140, 100, 40, 255))


def picture_book(c):
    """Le livre d'images : couverture rouge à étoile dorée, dos et tranche de pages."""
    c.polygon([(0.20, 0.14), (0.78, 0.18), (0.78, 0.86), (0.20, 0.82)], (250, 240, 214, 255),
              (170, 124, 86, 255))
    c.polygon([(0.16, 0.12), (0.72, 0.14), (0.72, 0.84), (0.16, 0.82)], (204, 70, 70, 255),
              (120, 36, 44, 255))
    c.polygon([(0.16, 0.12), (0.24, 0.12), (0.24, 0.82), (0.16, 0.82)], (150, 46, 52, 255),
              (120, 36, 44, 255), 0.02)
    star = []
    for k in range(10):
        a = math.radians(-90 + 36 * k)
        r = 0.16 if k % 2 == 0 else 0.07
        star.append((0.48 + r * math.cos(a), 0.44 + r * math.sin(a)))
    c.polygon(star, (255, 214, 92, 255), (200, 140, 40, 255), 0.02)
    c.line([(0.34, 0.70), (0.62, 0.70)], (255, 214, 92, 255), 0.03)


def dessert_cup(c):
    """Dessert spécial : coupe de verre, couches de crème et de gelée, baies sur le dessus."""
    glass = [(0.20, 0.24), (0.80, 0.24), (0.70, 0.62), (0.30, 0.62)]
    c.polygon(glass, (226, 240, 250, 255), (120, 150, 180, 255))
    c.polygon([(0.24, 0.40), (0.76, 0.40), (0.72, 0.54), (0.28, 0.54)], (246, 200, 210, 255),
              (246, 200, 210, 255), 0.01)
    c.polygon([(0.28, 0.54), (0.72, 0.54), (0.70, 0.60), (0.30, 0.60)], (214, 80, 96, 255),
              (214, 80, 96, 255), 0.01)
    c.circle(0.50, 0.26, 0.20, (255, 252, 240, 255), (200, 190, 170, 255), 0.02)
    for cx, cy in ((0.42, 0.16), (0.56, 0.14), (0.50, 0.08)):
        c.circle(cx, cy, 0.055, (214, 52, 70, 255), (130, 24, 44, 255), 0.015)
    c.line([(0.50, 0.62), (0.50, 0.80)], (150, 180, 206, 255), 0.05)
    c.polygon([(0.32, 0.80), (0.68, 0.80), (0.66, 0.86), (0.34, 0.86)], (200, 220, 236, 255),
              (120, 150, 180, 255), 0.02)


def cheesecake_slice(c):
    """Part de cheese-cake : triangle crème, croûte biscuitée, coulis et une baie."""
    c.polygon([(0.14, 0.62), (0.86, 0.46), (0.86, 0.72), (0.14, 0.86)], (250, 232, 190, 255),
              (176, 140, 90, 255))
    c.polygon([(0.14, 0.62), (0.86, 0.46), (0.62, 0.30), (0.14, 0.52)], (255, 244, 214, 255),
              (176, 140, 90, 255))
    c.polygon([(0.14, 0.80), (0.86, 0.66), (0.86, 0.72), (0.14, 0.86)], (190, 130, 70, 255),
              (140, 90, 46, 255), 0.02)
    c.polygon([(0.22, 0.52), (0.62, 0.32), (0.74, 0.40), (0.30, 0.58)], (214, 70, 90, 255),
              (170, 40, 60, 255), 0.015)
    c.circle(0.56, 0.36, 0.06, (214, 52, 70, 255), (130, 24, 44, 255), 0.015)


def tiat_drawing(c):
    """Dessin de Tiat : feuille au crayon, une fée et une épée qui dépasse de la feuille."""
    c.polygon([(0.14, 0.18), (0.80, 0.14), (0.84, 0.84), (0.18, 0.88)], (255, 252, 244, 255),
              (160, 150, 130, 255))
    c.circle(0.40, 0.42, 0.08, (255, 224, 199, 255), (90, 120, 200, 255), 0.02)
    c.line([(0.32, 0.36), (0.30, 0.56)], (110, 150, 230, 255), 0.04)
    c.line([(0.40, 0.50), (0.40, 0.70)], (90, 120, 200, 255), 0.025)
    c.line([(0.40, 0.70), (0.34, 0.80)], (90, 120, 200, 255), 0.025)
    c.line([(0.40, 0.70), (0.46, 0.80)], (90, 120, 200, 255), 0.025)
    c.line([(0.44, 0.58), (0.98, 0.04)], (180, 186, 200, 255), 0.07)
    c.line([(0.44, 0.58), (0.98, 0.04)], (236, 240, 248, 255), 0.035)
    c.line([(0.40, 0.56), (0.50, 0.64)], (196, 150, 60, 255), 0.04)
    c.circle(0.66, 0.70, 0.05, (240, 120, 140, 255))


def rami_card(c):
    """Carte de M. Rami : carton crème à liseré bordeaux, silhouette d'homme-chat, lignes."""
    c.polygon([(0.10, 0.26), (0.90, 0.20), (0.92, 0.74), (0.12, 0.80)], (252, 244, 226, 255),
              (122, 36, 48, 255))
    c.polygon([(0.15, 0.30), (0.86, 0.25), (0.87, 0.70), (0.17, 0.75)], (252, 244, 226, 255),
              (176, 120, 90, 255), 0.012)
    c.circle(0.32, 0.48, 0.10, (122, 36, 48, 255))
    c.polygon([(0.24, 0.42), (0.26, 0.30), (0.31, 0.39)], (122, 36, 48, 255), (122, 36, 48, 255), 0.01)
    c.polygon([(0.33, 0.39), (0.38, 0.29), (0.40, 0.41)], (122, 36, 48, 255), (122, 36, 48, 255), 0.01)
    for y, x1 in ((0.40, 0.80), (0.50, 0.74), (0.60, 0.78)):
        c.line([(0.48, y), (x1, y - 0.01)], (150, 110, 90, 255), 0.025)


def pressed_forget_me_not(c):
    """Myosotis séché : fleur bleue pâlie, aplatie sur une page."""
    c.polygon([(0.14, 0.16), (0.84, 0.12), (0.88, 0.84), (0.18, 0.88)], (246, 236, 212, 255),
              (176, 150, 112, 255))
    c.line([(0.48, 0.52), (0.40, 0.70), (0.34, 0.80)], (126, 160, 110, 255), 0.03)
    c.polygon([(0.40, 0.70), (0.30, 0.62), (0.26, 0.70)], (150, 184, 130, 255), (110, 140, 96, 255), 0.015)
    cx, cy = 0.52, 0.44
    for k in range(5):
        a = math.radians(-90 + 72 * k + 12)
        c.circle(cx + 0.13 * math.cos(a), cy + 0.13 * math.sin(a), 0.11, (150, 182, 236, 255),
                 (100, 130, 196, 255), 0.02)
    c.circle(cx, cy, 0.06, (246, 216, 120, 255), (200, 160, 70, 255), 0.015)


def butter_cake_promise(c):
    """La promesse du gâteau au beurre : gâteau rond doré aux noix, ruban noué, petite étoile."""
    gold, crust, edge = (250, 214, 130, 255), (226, 170, 80, 255), (160, 110, 46, 255)
    body = [(0.16, 0.46)]
    body += [(0.5 - 0.34 * math.cos(math.pi * k / 16), 0.74 + 0.12 * math.sin(math.pi * k / 16))
             for k in range(17)]
    body += [(0.84, 0.46)]
    c.polygon(body, crust, edge)
    box = c.px([(0.16, 0.34), (0.84, 0.58)])
    c.draw.ellipse([box[0][0], box[0][1], box[1][0], box[1][1]], fill=gold, outline=edge, width=c.w(0.03))
    for cx, cy in ((0.34, 0.45), (0.50, 0.40), (0.66, 0.45), (0.50, 0.50)):
        c.circle(cx, cy, 0.04, (150, 96, 50, 255))
    c.polygon([(0.46, 0.57), (0.54, 0.57), (0.54, 0.86), (0.46, 0.86)], (90, 140, 220, 255),
              (60, 96, 170, 255), 0.015)
    c.polygon([(0.50, 0.62), (0.34, 0.52), (0.36, 0.70)], (110, 160, 236, 255), (60, 96, 170, 255), 0.015)
    c.polygon([(0.50, 0.62), (0.66, 0.52), (0.64, 0.70)], (110, 160, 236, 255), (60, 96, 170, 255), 0.015)
    star = []
    for k in range(8):
        a = math.radians(-90 + 45 * k)
        r = 0.08 if k % 2 == 0 else 0.03
        star.append((0.80 + r * math.cos(a), 0.18 + r * math.sin(a)))
    c.polygon(star, (255, 240, 160, 255), (220, 180, 60, 255), 0.012)


def unknown(c):
    """Objet sans données : point d'interrogation sur une tuile lavande."""
    c.draw.rounded_rectangle(c.px([(0.16, 0.16), (0.84, 0.84)]), radius=0.16 * c.size,
                             fill=(208, 198, 240, 255), outline=(126, 110, 190, 255), width=c.w(0.03))
    ink = (104, 88, 168, 255)
    box = c.px([(0.36, 0.26), (0.64, 0.54)])
    c.draw.arc([box[0][0], box[0][1], box[1][0], box[1][1]], 180, 90, fill=ink, width=c.w(0.07))
    c.line([(0.50, 0.54), (0.50, 0.60)], ink, 0.07)
    c.circle(0.50, 0.71, 0.045, ink)


ICONS = {
    "page_fragment": page_fragment,
    "flower_blue": flower_blue,
    "laundry_sheet": laundry_sheet,
    "eggs": eggs,
    "wild_berries": wild_berries,
    "fresh_cream": fresh_cream,
    "clock_gear": clock_gear,
    "clock_comb": clock_comb,
    "picture_book": picture_book,
    "dessert_cup": dessert_cup,
    "cheesecake_slice": cheesecake_slice,
    "tiat_drawing": tiat_drawing,
    "rami_card": rami_card,
    "pressed_forget_me_not": pressed_forget_me_not,
    "butter_cake_promise": butter_cake_promise,
    "unknown": unknown,
}


def render(painter, size):
    canvas = Canvas(size * SUPERSAMPLE)
    painter(canvas)
    icon = canvas.image
    alpha = icon.getchannel("A").filter(ImageFilter.GaussianBlur(canvas.size * 0.025))
    alpha = alpha.point(lambda a: a * 0.4)
    shadow = Image.new("RGBA", icon.size, (58, 36, 64, 0))
    shadow.putalpha(alpha)
    offset = round(canvas.size * 0.025)
    result = Image.new("RGBA", icon.size, (0, 0, 0, 0))
    result.alpha_composite(shadow, (offset, offset))
    result.alpha_composite(icon)
    return result.resize((size, size), Image.LANCZOS)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", default=os.path.join(ROOT, "assets", "items"))
    parser.add_argument("--size", type=int, default=64)
    args = parser.parse_args()
    os.makedirs(args.out, exist_ok=True)
    for item_id, painter in ICONS.items():
        path = os.path.join(args.out, item_id + ".png")
        render(painter, args.size).save(path, optimize=True)
        print(os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
