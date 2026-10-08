#!/usr/bin/env python3
"""Icônes de l'interface (menu, HUD, fin d'arène) : formes simples, contour prune, style rond.

Chaque icône est dessinée à 4 fois sa taille (contours lissés), avec un contour foncé et un
reflet clair, puis réduite. Résultat déterministe ; les PNG générés sont versionnés dans
assets/ui/ et chargés par src/ui/hud.tscn, arena_end.tscn (Lot 10).

Usage (Python 3.9+, pip install Pillow) :

    python3 tools/gen_ui_icons.py                 # toutes les icônes dans assets/ui/
    python3 tools/gen_ui_icons.py --out /tmp/ui   # ailleurs (aperçu)
"""

import argparse
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUPERSAMPLE = 4
OUTLINE = (59, 35, 64, 255)
HEART_RED = (240, 98, 130, 255)
HEART_SHINE = (255, 205, 220, 255)
HEART_EMPTY = (74, 59, 110, 150)
GOLD = (255, 205, 96, 255)
GOLD_SHINE = (255, 241, 196, 255)


def heart_points(cx, cy, r, steps=96):
    """Cœur paramétrique centré en (cx, cy), demi-largeur r (unités 0..1)."""
    points = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        points.append((cx + x / 17 * r, cy - y / 17 * r))
    return points


class Canvas:
    """Dessin en unités normalisées (0..1) sur une image suréchantillonnée."""

    def __init__(self, size):
        self.size = size * SUPERSAMPLE
        self.image = Image.new("RGBA", (self.size, self.size), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image)

    def px(self, points):
        return [(x * self.size, y * self.size) for x, y in points]

    def w(self, width):
        return max(1, round(width * self.size))

    def shape(self, points, fill, outline=OUTLINE, width=0.07):
        """Polygone plein entouré d'un contour épais aux angles arrondis."""
        self.draw.polygon(self.px(points), fill=fill)
        if outline is not None:
            self.draw.line(self.px(points + points[:1]), fill=outline, width=self.w(width), joint="curve")

    def ellipse(self, box, fill):
        x0, y0, x1, y1 = box
        self.draw.ellipse([x0 * self.size, y0 * self.size, x1 * self.size, y1 * self.size], fill=fill)

    def result(self, size):
        return self.image.resize((size, size), Image.LANCZOS)


def heart_full(c):
    c.shape(heart_points(0.5, 0.5, 0.40), HEART_RED)
    c.ellipse((0.24, 0.27, 0.40, 0.40), HEART_SHINE)


def heart_empty(c):
    c.shape(heart_points(0.5, 0.5, 0.40), HEART_EMPTY)


def lock_marker(c):
    """Flèche dorée pointée vers le bas, posée au-dessus de l'ennemi verrouillé."""
    arrow = [(0.18, 0.22), (0.82, 0.22), (0.5, 0.82)]
    c.shape(arrow, GOLD, width=0.08)
    c.shape([(0.32, 0.30), (0.52, 0.30), (0.38, 0.52)], GOLD_SHINE, outline=None)


def saved(c):
    """Petit livre rose fermé, ruban doré : la partie est écrite."""
    c.shape([(0.18, 0.16), (0.78, 0.16), (0.78, 0.84), (0.18, 0.84)], (243, 166, 200, 255))
    c.shape([(0.26, 0.16), (0.30, 0.16), (0.30, 0.84), (0.26, 0.84)], (214, 120, 160, 255), outline=None)
    c.shape([(0.56, 0.16), (0.68, 0.16), (0.68, 0.94), (0.62, 0.86), (0.56, 0.94)], GOLD, width=0.05)
    c.ellipse((0.38, 0.30, 0.50, 0.42), HEART_SHINE)


def quest(c):
    """Page de quête crème au coin corné, deux lignes de texte."""
    page = [(0.2, 0.12), (0.64, 0.12), (0.82, 0.30), (0.82, 0.88), (0.2, 0.88)]
    c.shape(page, (255, 247, 226, 255))
    c.shape([(0.64, 0.12), (0.64, 0.30), (0.82, 0.30)], (236, 214, 178, 255), width=0.05)
    for y, x1 in ((0.46, 0.68), (0.60, 0.68), (0.74, 0.52)):
        c.shape([(0.32, y - 0.025), (x1, y - 0.025), (x1, y + 0.025), (0.32, y + 0.025)], (196, 120, 110, 255), outline=None)


def star(c):
    """Étoile dorée à cinq branches (nouveau record)."""
    points = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 0.44 if i % 2 == 0 else 0.2
        points.append((0.5 + r * math.cos(a), 0.54 + r * math.sin(a)))
    c.shape(points, GOLD)
    c.ellipse((0.36, 0.34, 0.48, 0.46), GOLD_SHINE)


ICONS = {
    "heart_full": (heart_full, 48),
    "heart_empty": (heart_empty, 48),
    "lock_marker": (lock_marker, 48),
    "saved": (saved, 32),
    "quest": (quest, 32),
    "star": (star, 40),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=os.path.join(ROOT, "assets", "ui"))
    args = parser.parse_args()
    os.makedirs(args.out, exist_ok=True)
    for name, (draw, size) in ICONS.items():
        canvas = Canvas(size)
        draw(canvas)
        path = os.path.join(args.out, name + ".png")
        canvas.result(size).save(path, optimize=True)
        print(path)


if __name__ == "__main__":
    main()
