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
    """Fragment de page : feuille crème au coin corné, bas déchiré, lignes de texte."""
    page = [(0.22, 0.13), (0.64, 0.13), (0.78, 0.27), (0.78, 0.80), (0.71, 0.85), (0.64, 0.79),
            (0.56, 0.87), (0.47, 0.80), (0.39, 0.88), (0.31, 0.81), (0.22, 0.86)]
    tilt = -10
    c.polygon(rotate(page, tilt), (255, 247, 226, 255), (170, 124, 86, 255))
    c.polygon(rotate([(0.64, 0.13), (0.64, 0.27), (0.78, 0.27)], tilt), (236, 214, 178, 255),
              (170, 124, 86, 255), 0.025)
    c.line(rotate([(0.30, 0.31), (0.52, 0.31)], tilt), (196, 120, 110, 255), 0.04)
    for y, x1 in ((0.42, 0.70), (0.51, 0.66), (0.60, 0.70), (0.69, 0.58)):
        c.line(rotate([(0.30, y), (x1, y)], tilt), (208, 176, 138, 255), 0.03)


def bookmark(c):
    """Marque-page porte-bonheur : ruban rose à liseré doré, trèfle à quatre feuilles, cordon."""
    tilt = 12
    ribbon = [(0.37, 0.16), (0.63, 0.16), (0.63, 0.90), (0.50, 0.78), (0.37, 0.90)]
    c.line(rotate([(0.50, 0.20), (0.56, 0.10), (0.66, 0.06)], tilt), (226, 178, 70, 255), 0.025)
    c.circle(*rotate([(0.67, 0.07)], tilt)[0], 0.035, (244, 200, 90, 255), (190, 140, 50, 255), 0.015)
    c.polygon(rotate(ribbon, tilt), (236, 96, 116, 255), (150, 50, 72, 255))
    for x in (0.41, 0.59):
        c.line(rotate([(x, 0.21), (x, 0.80)], tilt), (246, 204, 98, 255), 0.022)
    cx, cy = rotate([(0.50, 0.42)], tilt)[0]
    stem_end = rotate([(0.55, 0.56)], tilt)[0]
    c.line([(cx, cy), stem_end], (70, 140, 70, 255), 0.02)
    for k in range(4):
        a = math.radians(45 + 90 * k + tilt)
        c.circle(cx + 0.055 * math.cos(a), cy + 0.055 * math.sin(a), 0.052, (124, 204, 112, 255),
                 (64, 132, 70, 255), 0.012)
    c.circle(*rotate([(0.50, 0.20)], tilt)[0], 0.022, (150, 50, 72, 255))


def shell(c):
    """Coquillage : coquille Saint-Jacques pêche, bord festonné, côtes, charnière."""
    hinge = (0.50, 0.76)
    lobes, radius, bump = 7, 0.44, 0.035
    start, end = math.radians(200), math.radians(340)
    edge = []
    for i in range(lobes * 8 + 1):
        t = i / (lobes * 8)
        a = start + (end - start) * t
        r = radius + bump * math.sin(math.pi * ((t * lobes) % 1.0))
        edge.append((hinge[0] + r * math.cos(a), hinge[1] + r * math.sin(a) * 0.95))
    c.polygon([hinge] + edge, (252, 196, 174, 255), (196, 112, 98, 255))
    for k in range(1, lobes):
        a = start + (end - start) * k / lobes
        inner = (hinge[0] + 0.12 * math.cos(a), hinge[1] + 0.12 * math.sin(a) * 0.95)
        outer = (hinge[0] + (radius - 0.04) * math.cos(a), hinge[1] + (radius - 0.04) * math.sin(a) * 0.95)
        c.line([inner, outer], (226, 142, 126, 255), 0.022)
    c.polygon([(0.38, 0.75), (0.62, 0.75), (0.58, 0.84), (0.42, 0.84)], (240, 168, 150, 255),
              (196, 112, 98, 255), 0.025)
    c.circle(0.36, 0.48, 0.035, (255, 230, 218, 255))


def flower_blue(c):
    """Fleur bleue : cinq pétales ronds, cœur jaune, tige et feuille."""
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
    "bookmark": bookmark,
    "shell": shell,
    "flower_blue": flower_blue,
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
