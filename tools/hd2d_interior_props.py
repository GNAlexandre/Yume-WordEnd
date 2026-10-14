#!/usr/bin/env python3
"""Remplaçants du lot I pour les cartes de l'entrepôt (lot T2) : meubles, objets posés, portes,
fenêtres, éléments de mur, décalques et bandes animées que les plans de docs/lore/CARTE.md
(section 3) nomment et que la livraison n'a pas encore. Tailles et consignes : cahier n° 3
(docs/ASSETS_HD2D_SUKASUKA.md, section 3) ; roof_ladder, hors cahier : CARTE.md, 12.1.

Chaque recette dessine l'image à sa taille exacte, en pixel art (vue de face légèrement
plongeante pour les meubles, de dessus pour les décalques), d'après la consigne du cahier. Une
vraie image livrée sous le même nom remplace le remplaçant sans toucher au code ; aucune image
livrée n'est retouchée (bookshelf_tall_b, roof_railing_broken et drying_frame_wave partent d'une
copie de l'image livrée dont ils dérivent, qui reste intacte). Liste et entrées du manifeste :
tools/hd2d_interior.py ; génération : python3 tools/hd2d_assets.py gen --lot I.
"""

import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hd2d_art import (  # noqa: E402
    Canvas, WrapCanvas, asset, darker, fractal, mix, noise, posterize, ramp, rgba, steps_alpha, wrap_y)

PPM = 96
HONEY = "#A57C58"
DARK = "#654D3C"
MID = "#86603F"
PALE = "#B89A72"
LINEN = "#E6DCC6"
CRYSTAL = "#FFE6A6"
IRON = "#5C636B"
BRASS = "#B4955E"
GLASS = "#A9B9C6"
FOLIAGE = "#C9A04E"
OUT_WOOD = darker(DARK, 0.45)


# --- Outils de dessin -------------------------------------------------------------------------


def wood(c, x0, y0, x1, y1, base, top=0, grain=4, edge=True):
    """Pièce de bois : face, dessus clair (vue plongeante), arêtes, fil du bois."""
    t = ramp(base, 5, spread=0.45)
    c.rect(x0, y0, x1, y1, t[2])
    for _ in range(grain):
        gx = c.rnd.uniform(x0 + 2, max(x0 + 2.5, x1 - 3))
        gy = c.rnd.uniform(y0 + top, max(y0 + top + 0.5, y1 - 4))
        c.rect(gx, gy, gx + 1, min(y1 - 1, gy + c.rnd.uniform(4, 14)), t[1] if c.rnd.random() < 0.6 else t[3])
    if top:
        c.rect(x0, y0, x1, y0 + top, t[3])
        c.rect(x0, y0, x1, y0 + 1, t[4])
        c.rect(x0, y0 + top - 1, x1, y0 + top, t[1])
    if edge:
        c.rect(x0, y0, x0 + 1, y1, t[3])
        c.rect(x1 - 1, y0, x1, y1, t[1])
        c.rect(x0, y1 - 1, x1, y1, t[0])
    return t


def inset(c, x0, y0, x1, y1, t):
    """Panneau en creux (porte d'armoire) : ombre en haut à gauche, lumière en bas à droite."""
    c.rect(x0, y0, x1, y1, t[1])
    c.rect(x0 + 1, y0 + 1, x1, y1, t[3])
    c.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, t[2])


def knob(c, x, y, color=BRASS):
    t = ramp(color, 4, spread=0.5)
    c.rect(x, y, x + 3, y + 3, t[1])
    c.rect(x, y, x + 2, y + 2, t[3])


def books(c, x0, x1, ybot, hmin, hmax, colors=None, lean=0.0):
    """Rangée de livres debout, dos colorés, filet doré, haut éclairé ; renvoie x de fin."""
    colors = colors or ["#7A2E26", "#2F4A3A", "#3B3F6A", "#8A5A2A", "#5E3A52", "#A08A4A", "#2E5A62"]
    x = x0
    while x < x1 - 2:
        w = c.rnd.randint(3, 7)
        h = c.rnd.randint(hmin, hmax)
        if x + w > x1:
            w = int(x1 - x)
        t = ramp(c.rnd.choice(colors), 4, spread=0.5)
        c.rect(x, ybot - h, x + w, ybot, t[1])
        c.rect(x, ybot - h, x + w - 1, ybot, t[2])
        c.rect(x, ybot - h, x + 1, ybot, t[3])
        c.rect(x, ybot - h, x + w, ybot - h + 1, t[3])
        if h > 10 and w > 3:
            c.rect(x + 1, ybot - h + 3, x + w - 1, ybot - h + 4, "#C8A860")
            c.rect(x + 1, ybot - 4, x + w - 1, ybot - 3, "#C8A860")
        x += w + (1 if c.rnd.random() < 0.15 else 0)
    return x


def lying_books(c, x0, ybot, count, wmin=14, wmax=24):
    """Pile de livres couchés, du plus large au plus étroit."""
    y = ybot
    for k in range(count):
        w = c.rnd.randint(wmin, wmax) - k * 2
        h = c.rnd.randint(3, 5)
        dx = c.rnd.randint(-2, 2)
        t = ramp(c.rnd.choice(["#7A2E26", "#2F4A3A", "#3B3F6A", "#8A5A2A", "#5E3A52"]), 4, spread=0.5)
        c.rect(x0 + dx, y - h, x0 + dx + w, y, t[2])
        c.rect(x0 + dx, y - h, x0 + dx + w, y - h + 1, t[3])
        c.rect(x0 + dx + w - 2, y - h + 1, x0 + dx + w, y, "#E8DEC4")
        y -= h
    return y


def paper(c, x0, y0, x1, y1, base="#EEE6D2", lines=True):
    t = ramp(base, 4, spread=0.25)
    c.rect(x0, y0, x1, y1, t[2])
    c.rect(x1 - 1, y0, x1, y1, t[1])
    c.rect(x0, y1 - 1, x1, y1, t[1])
    if lines:
        y = y0 + 3
        while y < y1 - 2:
            c.rect(x0 + 2, y, x0 + 2 + (x1 - x0 - 4) * c.rnd.uniform(0.5, 1.0), y + 1, "#A9A49A")
            y += 3


def glass(c, x0, y0, x1, y1, night=False):
    """Vitre gris bleuté, reflet en diagonale, masse de feuillage d'or devinée en bas."""
    t = ramp(GLASS, 4, spread=0.35)
    c.rect(x0, y0, x1, y1, t[2])
    h = y1 - y0
    c.rect(x0, y0 + h * 0.62, x1, y1, mix(t[1], FOLIAGE, 0.45))
    for k in range(int(x1 - x0) + int(h)):
        x = x0 + k
        y = y0 + k * 0.9
        if x0 <= x < x1 - 1 and y0 <= y < y1 and (k // 3) % 3 == 0:
            c.rect(x, y, x + 1, y + 1, t[3])
    c.rect(x0, y0, x1, y0 + 1, t[1])


def cross_window(c, x0, y0, x1, y1, cols=2, rows=3, frame=MID, bar=3):
    """Fenêtre à croisillons : cadre, vitres, barreaux."""
    t = wood(c, x0, y0, x1, y1, frame, grain=0)
    ix0, iy0, ix1, iy1 = x0 + bar + 1, y0 + bar + 1, x1 - bar - 1, y1 - bar - 1
    glass(c, ix0, iy0, ix1, iy1)
    for k in range(1, cols):
        x = ix0 + (ix1 - ix0) * k / cols
        c.rect(x - 1, iy0, x + 1, iy1, t[2])
        c.rect(x - 1, iy0, x, iy1, t[3])
    for k in range(1, rows):
        y = iy0 + (iy1 - iy0) * k / rows
        c.rect(ix0, y - 1, ix1, y + 1, t[2])
        c.rect(ix0, y - 1, ix1, y, t[3])
    return t


def crystal(c, cx, cy, rx, ry):
    """Cristal lumineux (#FFE6A6 : la lueur du jeu s'y allume)."""
    c.poly([(cx, cy - ry), (cx + rx, cy), (cx, cy + ry), (cx - rx, cy)], "#E8C27A")
    c.poly([(cx, cy - ry + 1), (cx + rx - 1, cy), (cx, cy + ry - 1), (cx - rx + 1, cy)], CRYSTAL)
    c.rect(cx - 1, cy - ry + 2, cx, cy - 1, "#FFF6DA")


def cloth(c, x0, y0, x1, y1, base, folds=3, stripe=None):
    t = ramp(base, 4, spread=0.35)
    c.rect(x0, y0, x1, y1, t[2])
    for k in range(folds):
        x = x0 + (x1 - x0) * (k + 1) / (folds + 1) + c.rnd.uniform(-2, 2)
        c.rect(x, y0 + 2, x + 1, y1, t[1])
        c.rect(x + 1, y0 + 2, x + 2, y1, t[3])
    if stripe:
        c.rect(x0, y1 - 5, x1, y1 - 3, stripe)
    c.rect(x0, y1 - 1, x1, y1, t[0])


def outline_finish(c, color=OUT_WOOD):
    return c.finish(color)


# --- Portes et fenêtres -----------------------------------------------------------------------


def door_service(size, rnd):
    """Porte de service vers la clairière d'entraînement : planches, moitié haute vitrée à
    croisillons, loquet de fer, paillasson usé au pied."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 0, 0, w, h, DARK, grain=0)
    c.rect(0, 0, w, 8, t[3])
    c.rect(0, 0, w, 2, t[4])
    leaf = ramp(HONEY, 5, spread=0.42)
    x0, x1, y0, y1 = 8, w - 8, 9, h - 6
    for k, x in enumerate(range(x0, x1, 10)):
        c.rect(x, y0, min(x1, x + 10), y1, leaf[2 if k % 2 else 3])
        c.rect(x, y0, x + 1, y1, leaf[1])
    for _ in range(18):
        gx, gy = rnd.uniform(x0, x1 - 1), rnd.uniform(y0 + 90, y1 - 8)
        c.rect(gx, gy, gx + 1, gy + rnd.uniform(4, 12), leaf[1])
    # Moitié haute vitrée, six carreaux.
    gx0, gy0, gx1, gy1 = x0 + 6, y0 + 8, x1 - 6, y0 + 88
    c.rect(gx0 - 3, gy0 - 3, gx1 + 3, gy1 + 3, leaf[1])
    glass(c, gx0, gy0, gx1, gy1)
    for k in (1, 2):
        y = gy0 + (gy1 - gy0) * k / 3
        c.rect(gx0, y - 1, gx1, y + 1, leaf[2])
    c.rect((gx0 + gx1) / 2 - 1, gy0, (gx0 + gx1) / 2 + 1, gy1, leaf[2])
    # Traverses et loquet.
    for y in (y0 + 100, y1 - 30):
        c.rect(x0, y, x1, y + 5, leaf[1])
        c.rect(x0, y, x1, y + 1, leaf[3])
    iron = ramp(IRON, 4, spread=0.5)
    c.rect(x1 - 18, 118, x1 - 6, 122, iron[1])
    c.rect(x1 - 18, 118, x1 - 6, 119, iron[3])
    c.rect(x1 - 9, 114, x1 - 6, 128, iron[2])
    for y in (y0 + 20, y1 - 22):
        c.rect(x0, y, x0 + 18, y + 4, iron[1])
        c.rect(x0, y, x0 + 18, y + 1, iron[3])
    # Paillasson usé.
    mat = ramp("#8A6A3E", 4, spread=0.4)
    c.rect(4, h - 7, w - 4, h, mat[1])
    for x in range(5, w - 5, 2):
        c.rect(x, h - 6, x + 1, h - 1, mat[2 if (x // 2) % 3 else 3])
    return outline_finish(c)


def door_armory_inside(size, rnd):
    """La porte rivetée vue de la crypte : barres de renfort, gros gonds, cinq pênes, rouille."""
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("#6E665E", 5, spread=0.4)
    c.rect(0, 0, w, h, stone[1])
    y = 0
    while y < h:
        bh = rnd.randint(18, 28)
        for x0, x1 in ((0, 11), (w - 11, w)):
            c.rect(x0 + 1, y + 1, x1 - 1, min(h, y + bh) - 1, stone[rnd.choice([1, 2])])
            c.rect(x0 + 1, y + 1, x1 - 1, y + 2, stone[3])
        y += bh
    x = 0
    while x < w:
        bw = rnd.randint(22, 34)
        c.rect(x + 1, 1, min(w, x + bw) - 1, 10, stone[rnd.choice([1, 2])])
        x += bw
    metal = ramp("#43474C", 5, spread=0.5)
    x0, x1, y0, y1 = 11, w - 11, 11, h - 3
    c.rect(x0, y0, x1, y1, metal[2])
    for k in range(6):
        yy = y0 + (y1 - y0) * k / 6
        c.rect(x0, yy, x1, yy + 1, metal[1])
    # Barres de renfort en Z et cornières.
    for yy in (y0 + 18, (y0 + y1) / 2, y1 - 22):
        c.rect(x0, yy, x1, yy + 7, metal[1])
        c.rect(x0, yy, x1, yy + 1, metal[3])
    c.line([(x0 + 3, y0 + 25), (x1 - 3, (y0 + y1) / 2 - 2)], metal[1], width=5)
    c.line([(x0 + 3, (y0 + y1) / 2 + 9), (x1 - 3, y1 - 24)], metal[1], width=5)
    # Gros gonds à gauche, cinq pênes à droite.
    for yy in (y0 + 30, y1 - 40):
        c.rect(x0 - 4, yy, x0 + 10, yy + 14, metal[0])
        c.rect(x0 - 4, yy, x0 + 10, yy + 2, metal[3])
    brass = ramp(BRASS, 4, spread=0.5)
    for k in range(5):
        ly = h * 0.3 + k * h * 0.085
        c.rect(x1 - 22, ly, x1 + 2, ly + 5, metal[0])
        c.rect(x1 - 22, ly, x1 + 2, ly + 1, metal[3])
        c.rect(x1 - 26, ly - 1, x1 - 20, ly + 6, brass[1])
    # Rouille et humidité.
    rust = fractal((x1 - x0, y1 - y0), (10, 18), rnd, 3).point(lambda v: 150 if v > 205 else 0)
    c.img.paste(Image.new("RGBA", rust.size, rgba("#6A4632")), (x0, y0), rust)
    for _ in range(40):
        rx, ry = rnd.uniform(x0 + 2, x1 - 3), rnd.uniform(y0 + 2, y1 - 3)
        c.rect(rx, ry, rx + 1, ry + rnd.randint(1, 3), rnd.choice(["#7A4A2E", "#5A3A28", "#8A5A38"]))
    return c.finish(darker("#2E3034", 0.5))


def window_curtains_open(size, rnd):
    return _curtain_window(size, rnd, closed=False)


def window_curtains_closed(size, rnd):
    return _curtain_window(size, rnd, closed=True)


def _curtain_window(size, rnd, closed):
    """Fenêtre à croisillons et rideaux de lin beige (#D9CBB0), ouverts sur des embrasses ou tirés,
    un peu de lumière filtrée au milieu."""
    w, h = size
    c = Canvas(w, h, rnd)
    cross_window(c, 16, 8, w - 16, h - 8, cols=2, rows=3)
    # Appui et tringle.
    t = ramp(MID, 5, spread=0.42)
    c.rect(10, h - 9, w - 10, h, t[3])
    c.rect(10, h - 9, w - 10, h - 8, t[4])
    c.rect(10, h - 2, w - 10, h, t[1])
    c.rect(4, 2, w - 4, 5, ramp(BRASS, 4)[1])
    c.rect(2, 1, 6, 6, ramp(BRASS, 4)[2])
    c.rect(w - 6, 1, w - 2, 6, ramp(BRASS, 4)[2])
    lin = ramp("#D9CBB0", 5, spread=0.35)
    if closed:
        for side in (0, 1):
            x0 = 6 if side == 0 else w / 2
            x1 = w / 2 if side == 0 else w - 6
            c.rect(x0, 5, x1, h - 10, lin[2])
            for k in range(6):
                fx = x0 + (x1 - x0) * (k + 0.5) / 6
                c.rect(fx, 6, fx + 2, h - 10, lin[1])
                c.rect(fx + 2, 6, fx + 3, h - 10, lin[3])
        c.rect(w / 2 - 2, 8, w / 2 + 2, h - 12, mix(lin[4], CRYSTAL, 0.4))
    else:
        for side in (0, 1):
            x0 = 4 if side == 0 else w - 20
            x1 = 20 if side == 0 else w - 4
            c.poly([(x0, 5), (x1, 5), (x1 - (4 if side == 0 else -4), h * 0.55), (x0 + (2 if side == 0 else 0), h - 10),
                    (x0, h - 10)], lin[2])
            for k in range(3):
                fx = x0 + 3 + k * 5
                c.rect(fx, 6, fx + 1, h * 0.5, lin[1])
                c.rect(fx, h * 0.6, fx + 1, h - 11, lin[1])
            c.rect(x0, h * 0.55, x1, h * 0.55 + 3, ramp("#8A5A3A", 4)[2])
    return outline_finish(c)


def window_bare(size, rnd):
    """Fenêtre nue de la chambre de Willem, sans rideaux, rebord de bois large où s'asseoir."""
    w, h = size
    c = Canvas(w, h, rnd)
    cross_window(c, 8, 0, w - 8, h - 14, cols=2, rows=3, frame=DARK)
    t = ramp(HONEY, 5, spread=0.42)
    c.rect(0, h - 14, w, h - 4, t[3])
    c.rect(0, h - 14, w, h - 12, t[4])
    c.rect(0, h - 4, w, h, t[1])
    c.rect(4, h - 4, 8, h, t[0])
    c.rect(w - 8, h - 4, w - 4, h, t[0])
    return outline_finish(c)


def window_dusty(size, rnd):
    """Petite fenêtre haute des archives : vitres grises de poussière, toile d'araignée, loquet
    rouillé."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = cross_window(c, 4, 4, w - 4, h - 4, cols=2, rows=2, frame=DARK)
    dust = fractal((w - 18, h - 18), (3, 3), rnd, 2)
    layer = Image.new("RGBA", dust.size, rgba("#8E8A80"))
    c.img.paste(layer, (9, 9), dust.point(lambda v: int(v * 0.75)))
    c.rect(9, 9, w - 9, 10, t[1])
    for k in range(6):
        a = math.radians(5 + k * 16)
        c.line([(9, 9), (9 + math.cos(a) * 22, 9 + math.sin(a) * 22)], "#D8D4CC")
    for r in (8, 14, 20):
        pts = [(9 + math.cos(math.radians(a)) * r, 9 + math.sin(math.radians(a)) * r) for a in range(5, 90, 16)]
        c.line(pts, "#C8C4BC")
    c.rect(w / 2 - 2, h / 2 + 2, w / 2 + 6, h / 2 + 5, "#7A4A2E")
    c.rect(4, h - 6, w - 4, h, t[3])
    return outline_finish(c)


# --- Éléments de mur ---------------------------------------------------------------------------


def wallitem_notices_mix(size, rnd):
    """Papiers dépareillés punaisés en désordre : dessins d'enfants, demande de réparation, coin
    de feuille arraché ; lignes grises, aucune lettre."""
    w, h = size
    c = Canvas(w, h, rnd)
    paper(c, 2, 4, 30, 40, "#EFE7D4")
    paper(c, 26, 10, 54, h - 2, "#E6DCB8")
    c.rect(44, 2, w - 2, 30, "#F2EEE4")
    for k in range(5):
        c.rect(47, 6 + k * 4, w - 6, 7 + k * 4, "#9AA0A8")
    c.ellipse(14, 22, 5, 5, "#E8B040")
    c.rect(8, 32, 22, 34, "#4E8A50")
    c.poly([(58, 34), (w - 3, 34), (w - 6, h - 1), (60, 48)], "#E8E0CC")
    for x, y in ((15, 6), (40, 12), (60, 4), (66, 36)):
        c.rect(x, y, x + 2, y + 2, rnd.choice(["#B5443A", "#4E7A9A", "#5A8A50"]))
    return c.finish(darker("#8A7A5A", 0.5))


def wallitem_frame_landscape(size, rnd):
    """Petit tableau naïf dans un cadre de bois : une île flottante couverte d'arbres au-dessus
    d'une mer de nuages."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 0, 0, w, h, MID, grain=0)
    c.rect(4, 4, w - 4, h - 4, "#9CB6CC")
    c.rect(4, 4, w - 4, 14, "#C6B4CC")
    for k in range(4):
        c.ellipse(8 + k * 13, h - 10, 8, 4, "#F0E2D2")
    c.poly([(16, 24), (42, 24), (36, 33), (24, 34)], "#7A6656")
    for k in range(5):
        c.ellipse(19 + k * 5, 21, 3, 4, rnd.choice(["#C99A46", "#A95A3A", "#6E8A4A"]))
    c.rect(0, 0, w, 2, t[3])
    return outline_finish(c)


def wallitem_crystal_sconce(size, rnd):
    """Applique de laiton terni tenant un cristal lumineux jaune pâle dans une petite cage."""
    w, h = size
    c = Canvas(w, h, rnd)
    b = ramp(BRASS, 5, spread=0.5)
    c.rect(w / 2 - 4, h - 12, w / 2 + 4, h, b[1])
    c.rect(w / 2 - 4, h - 12, w / 2 + 4, h - 10, b[3])
    c.rect(w / 2 - 1, h - 22, w / 2 + 1, h - 11, b[2])
    c.rect(4, h - 26, w - 4, h - 22, b[2])
    c.rect(4, h - 26, w - 4, h - 25, b[4])
    crystal(c, w / 2, h - 36, 6, 9)
    for x in (5, w / 2 - 0.5, w - 6):
        c.rect(x, 6, x + 1, h - 25, b[1])
    c.rect(5, 4, w - 5, 7, b[2])
    c.rect(w / 2 - 2, 0, w / 2 + 2, 4, b[1])
    return c.finish(darker(BRASS, 0.4))


def wallitem_spice_shelf(size, rnd):
    """Étagère murale de bocaux d'épices et d'herbes ; au bout, un petit pot de moutarde à
    l'étiquette couverte d'un gribouillis d'enfant."""
    w, h = size
    c = Canvas(w, h, rnd)
    for y in (h - 34, h - 4):
        wood(c, 0, y, w, y + 4, HONEY, top=2, grain=0)
    c.rect(2, 4, 6, h - 2, ramp(MID, 4)[1])
    c.rect(w - 6, 4, w - 2, h - 2, ramp(MID, 4)[1])
    for row, ybot in enumerate((h - 34, h - 4)):
        x = 8
        while x < w - 22:
            jw = rnd.randint(9, 13)
            jh = rnd.randint(14, 22)
            col = rnd.choice(["#A8642E", "#6E8A3A", "#C8A040", "#8A3A2A", "#C8B890", "#5A4030"])
            c.rect(x, ybot - jh, x + jw, ybot, "#C8D4D8")
            c.rect(x + 1, ybot - jh + 5, x + jw - 1, ybot - 1, col)
            c.rect(x + 1, ybot - jh, x + jw - 1, ybot - jh + 3, "#7A5A3A")
            c.rect(x + 2, ybot - jh + 8, x + jw - 2, ybot - jh + 12, "#EEE6D2")
            x += jw + 2
    # Le pot de moutarde, au bout de l'étagère du bas.
    x0 = w - 20
    c.rect(x0, h - 20, x0 + 12, h - 4, "#D8B830")
    c.rect(x0, h - 22, x0 + 12, h - 19, "#7A5A3A")
    c.rect(x0 + 1, h - 16, x0 + 11, h - 9, "#F2EEE2")
    c.line([(x0 + 2, h - 11), (x0 + 5, h - 15), (x0 + 7, h - 11), (x0 + 10, h - 14)], "#3A3AA0")
    return outline_finish(c)


def wallitem_apron_hook(size, rnd):
    """Tablier de toile blanche taché pendu à un crochet de fer."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4, spread=0.5)
    c.rect(w / 2 - 2, 0, w / 2 + 2, 6, iron[1])
    c.rect(w / 2 - 1, 4, w / 2 + 1, 10, iron[2])
    t = ramp("#ECE6D8", 5, spread=0.3)
    c.line([(w / 2 - 6, 18), (w / 2, 8), (w / 2 + 6, 18)], t[1], width=2)
    c.poly([(w / 2 - 8, 18), (w / 2 + 8, 18), (w - 3, 40), (w - 4, h - 1), (3, h - 1), (2, 40)], t[2])
    c.rect(2, 38, w - 2, 42, t[1])
    for k in range(3):
        fx = 8 + k * 9
        c.rect(fx, 44, fx + 1, h - 2, t[1])
    c.rect(8, 52, 26, 64, t[3])
    c.rect(8, 52, 26, 53, t[1])
    for _ in range(4):
        sx, sy = rnd.uniform(6, w - 8), rnd.uniform(46, h - 6)
        c.ellipse(sx, sy, 2, 1.5, rnd.choice(["#C8A070", "#B07A5A", "#D0B890"]))
    return c.finish(darker("#B8B0A0", 0.5))


def wallitem_clippings(size, rnd):
    """Coupures de magazines pour filles épinglées : dessins de robes et de chapeaux, sans texte."""
    w, h = size
    c = Canvas(w, h, rnd)
    spots = [(1, 6, 26, 34), (24, 1, 52, 30), (50, 8, w - 1, 38), (12, 32, 40, h - 1), (40, 34, 68, h - 2)]
    for k, (x0, y0, x1, y1) in enumerate(spots):
        paper(c, x0, y0, x1, y1, rnd.choice(["#F2EEE6", "#F0E2E2", "#E8EEF0"]), lines=False)
        cx = (x0 + x1) / 2
        dress = rnd.choice(["#C86A7A", "#6A8AC8", "#E8B040", "#8AA86A", "#B07AC0"])
        if k % 2 == 0:
            c.rect(cx - 2, y0 + 5, cx + 2, y0 + 9, "#E8C8A8")
            c.poly([(cx - 3, y0 + 9), (cx + 3, y0 + 9), (cx + 8, y1 - 3), (cx - 8, y1 - 3)], dress)
        else:
            c.ellipse(cx, y0 + 14, 10, 3, dress)
            c.ellipse(cx, y0 + 10, 5, 5, dress)
            c.rect(cx - 6, y0 + 11, cx + 6, y0 + 13, "#F2EEE6")
        c.rect(cx - 1, y0 + 1, cx + 1, y0 + 3, "#B5443A")
    return c.finish(darker("#A09080", 0.5))


def wallitem_labcoat(size, rnd):
    """Longue blouse blanche de laboratoire pendue à une patère, à la taille d'une très grande
    femme."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#F0EEE8", 5, spread=0.3)
    wood(c, w / 2 - 4, 0, w / 2 + 4, 6, DARK, grain=0)
    c.poly([(w / 2 - 10, 8), (w / 2 + 10, 8), (w - 4, 22), (w - 2, h - 1), (2, h - 1), (4, 22)], t[2])
    c.poly([(w / 2 - 10, 8), (w / 2, 30), (w / 2 + 10, 8)], t[1])
    c.rect(w / 2 - 1, 30, w / 2 + 1, h - 1, t[1])
    for y in (40, 56, 72):
        c.rect(w / 2 + 2, y, w / 2 + 4, y + 2, t[0])
    c.rect(7, 60, 17, 70, t[3])
    c.rect(7, 60, 17, 61, t[1])
    c.rect(3, 26, 6, 80, t[1])
    c.rect(w - 6, 26, w - 3, 80, t[1])
    return c.finish(darker("#B8B4AC", 0.5))


def wallitem_kids_drawings(size, rnd):
    """Dessins d'enfants punaisés : un soleil, des fées aux cheveux de toutes les couleurs, un grand
    monsieur aux cheveux noirs, une grande dame aux cheveux roses qui sourit ; aucune lettre."""
    w, h = size
    c = Canvas(w, h, rnd)
    paper(c, 1, 4, 38, h - 4, "#F4F0E6", lines=False)
    paper(c, 36, 1, 78, h - 8, "#F0ECE0", lines=False)
    paper(c, 76, 6, w - 1, h - 1, "#F4EEE4", lines=False)
    c.ellipse(12, 16, 6, 6, "#F0B030")
    for a in range(0, 360, 45):
        c.line([(12, 16), (12 + math.cos(math.radians(a)) * 10, 16 + math.sin(math.radians(a)) * 10)], "#F0B030")
    for k, hair in enumerate(["#7AB04A", "#E890A8", "#9A6AC8", "#F0B898"]):
        x = 6 + k * 8
        c.ellipse(x, 38, 3, 3, hair)
        c.rect(x - 2, 41, x + 2, 50, rnd.choice(["#6A8AC8", "#C86A6A", "#E8C060"]))
    # Le grand monsieur aux cheveux noirs et la grande dame aux cheveux roses.
    c.ellipse(50, 10, 4, 4, "#E8C8A8")
    c.rect(46, 5, 55, 9, "#2A2A30")
    c.poly([(45, 16), (55, 16), (57, 36), (43, 36)], "#3A4A6A")
    c.line([(45, 18), (40, 30)], "#3A4A6A", width=2)
    c.line([(55, 18), (60, 30)], "#3A4A6A", width=2)
    c.rect(46, 36, 48, 46, "#3A3A40")
    c.rect(52, 36, 54, 46, "#3A3A40")
    c.ellipse(66, 12, 5, 5, "#F090B0")
    c.poly([(61, 17), (71, 17), (74, 44), (58, 44)], "#4E9A5A")
    c.line([(64, 13), (66, 14), (68, 13)], "#B04040")
    for k in range(3):
        c.ellipse(86 + k * 9, 30, 3, 3, rnd.choice(["#E8A040", "#60B0C8", "#C8C040"]))
        c.rect(84 + k * 9, 33, 88 + k * 9, 42, "#B0A0D0")
    c.rect(86, 46, 108, 48, "#5A9A4A")
    for x, y in ((19, 5), (57, 2), (95, 7)):
        c.rect(x, y, x + 2, y + 2, "#B5443A")
    return c.finish(darker("#A09080", 0.5))


def wallitem_cobweb(size, rnd):
    """Toile d'araignée grise dans un angle, chargée de poussière (posée haut sur le mur)."""
    w, h = size
    c = Canvas(w, h, rnd)
    col = "#B8B4AC"
    spokes = [math.radians(a) for a in (2, 18, 34, 50, 66, 82, 88)]
    for a in spokes:
        c.line([(0, 0), (math.cos(a) * 70, math.sin(a) * 70)], col)
    for r in (8, 15, 23, 32, 42):
        pts = [(math.cos(a) * r * rnd.uniform(0.9, 1.05), math.sin(a) * r * rnd.uniform(0.9, 1.05)) for a in spokes]
        c.line(pts, "#A8A49C")
    c.line([(w * 0.55, h - 12), (w * 0.6, h - 1)], col)
    c.ellipse(w * 0.6, h - 3, 1.5, 2, "#3A3430")
    img = c.img
    a = img.getchannel("A")
    img.putalpha(a.point(lambda v: 255 if v > 0 else 0))
    return img


# --- Meubles -----------------------------------------------------------------------------------


def _top_band(c, x0, y0, x1, depth_px, base):
    """Dessus d'un meuble vu en plongée (une bande claire)."""
    t = ramp(base, 5, spread=0.45)
    c.rect(x0, y0, x1, y0 + depth_px, t[3])
    c.rect(x0, y0, x1, y0 + 1, t[4])
    c.rect(x0, y0 + depth_px - 1, x1, y0 + depth_px, t[1])


def pantry_cupboard(size, rnd):
    """Garde-manger de bois à portes garnies de grillage fin, une porte entrouverte : bocaux,
    fromages, jambon pendu, pots de confiture."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 2, 8, w - 2, h, MID, top=6, grain=10)
    c.rect(0, 2, w, 9, t[3])
    c.rect(0, 2, w, 3, t[4])
    c.rect(4, h - 8, w - 4, h, t[1])
    # Intérieur visible derrière la porte droite entrouverte.
    ix0, ix1, iy0, iy1 = w / 2 + 2, w - 8, 18, h - 14
    c.rect(ix0, iy0, ix1, iy1, "#2E2218")
    for y in (iy0 + 40, iy0 + 82, iy0 + 124):
        c.rect(ix0, y, ix1, y + 3, t[1])
    c.rect(ix0 + 8, iy0 + 4, ix0 + 10, iy0 + 14, "#C8B890")
    c.poly([(ix0 + 4, iy0 + 14), (ix0 + 14, iy0 + 14), (ix0 + 16, iy0 + 34), (ix0 + 2, iy0 + 34)], "#A85A4A")
    for k in range(3):
        x = ix0 + 3 + k * 10
        c.rect(x, iy0 + 64, x + 8, iy0 + 82, "#C8D4D8")
        c.rect(x + 1, iy0 + 69, x + 7, iy0 + 81, rnd.choice(["#A8302A", "#D8A030", "#6A2A4A"]))
        c.rect(x, iy0 + 62, x + 8, iy0 + 65, "#E8E0D0")
    c.ellipse(ix0 + 12, iy0 + 116, 10, 7, "#E8C860")
    c.rect(ix0 + 2, iy0 + 116, ix0 + 22, iy0 + 124, "#E8C860")
    c.rect(ix0 + 12, iy0 + 112, ix0 + 20, iy0 + 116, "#F2DC90")
    # Porte gauche fermée : cadre et grillage fin.
    for x0, x1, ajar in ((6, w / 2 - 1, False), (w - 16, w - 4, True)):
        inset(c, x0, 16, x1, h - 12, t)
        if not ajar:
            for yy in range(24, h - 18, 3):
                c.rect(x0 + 5, yy, x1 - 5, yy + 1, "#8A8478")
            for xx in range(int(x0) + 5, int(x1) - 5, 3):
                c.rect(xx, 22, xx + 1, h - 16, "#8A8478")
    knob(c, w / 2 - 7, h / 2, BRASS)
    return outline_finish(c)


def sacks_vegetables(size, rnd):
    """Gros sacs de toile ouverts, l'un de carottes, l'autre de pommes de terre, quelques-unes
    roulées par terre."""
    w, h = size
    c = Canvas(w, h, rnd)
    jute = ramp("#B49A6A", 5, spread=0.4)
    for x0, x1, fill in ((4, 56, "carrot"), (52, 108, "potato")):
        c.poly([(x0 + 4, 14), (x1 - 4, 14), (x1, h - 4), (x0, h - 4)], jute[2])
        c.ellipse((x0 + x1) / 2, 15, (x1 - x0) / 2 - 2, 6, jute[1])
        for k in range(3):
            fx = x0 + 10 + k * 14
            c.rect(fx, 24, fx + 1, h - 6, jute[1])
        c.rect(x0 + 2, h - 6, x1 - 2, h - 4, jute[0])
        for _ in range(9):
            cx = rnd.uniform(x0 + 8, x1 - 8)
            cy = rnd.uniform(8, 16)
            if fill == "carrot":
                c.poly([(cx - 3, cy), (cx + 3, cy), (cx, cy + 9)], "#E07A28")
                c.rect(cx - 1, cy - 4, cx + 1, cy, "#5A8A3A")
            else:
                c.ellipse(cx, cy, 4, 3, "#B08A58")
                c.rect(cx - 1, cy - 1, cx, cy, "#7A5A38")
    for cx in (20, 88, 98):
        c.ellipse(cx, h - 3, 4, 3, "#B08A58")
    c.poly([(30, h - 6), (38, h - 3), (30, h - 1)], "#E07A28")
    return c.finish(darker("#6A5434", 0.5))


def filing_cabinet(size, rnd):
    """Meuble à casiers et à tiroirs de bois, étiquettes vierges, un tiroir entrouvert plein de
    fiches."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 2, 6, w - 2, h, HONEY, top=6, grain=6)
    rows, cols = 6, 3
    cw = (w - 12) / cols
    rh = (h - 18) / rows
    for r in range(rows):
        for k in range(cols):
            x0 = 6 + k * cw
            y0 = 14 + r * rh
            inset(c, x0, y0, x0 + cw - 2, y0 + rh - 2, t)
            c.rect(x0 + cw / 2 - 5, y0 + 4, x0 + cw / 2 + 4, y0 + 8, "#EEE6D2")
            knob(c, x0 + cw / 2 - 2, y0 + rh / 2 + 1, BRASS)
    # Tiroir entrouvert, plein de fiches.
    x0, y0 = 6 + cw, 14 + 3 * rh
    c.rect(x0 - 2, y0 - 2, x0 + cw + 2, y0 + rh + 2, t[3])
    c.rect(x0 - 2, y0 - 6, x0 + cw + 2, y0, "#E8E0CC")
    for k in range(8):
        c.rect(x0 + k * 3.5, y0 - 9 + (k % 3), x0 + k * 3.5 + 2, y0, "#F2EEE4")
    return outline_finish(c)


def bookshelf_tall_b(size, rnd):
    """La même bibliothèque que bookshelf_tall (livrée), en désordre : livres couchés, grands livres
    d'images, un trou dans une rangée, un livre ouvert à plat. Part d'une copie de l'image livrée."""
    base = asset("interior/props/bookshelf_tall")
    w, h = size
    c = Canvas(w, h, rnd)
    if base is not None and base.size == (w, h):
        c.img = base.copy()
        c.draw = ImageDraw.Draw(c.img)
    else:
        t = wood(c, 4, 10, w - 4, h, DARK, grain=8)
        for y in (60, 112, 164, h - 6):
            c.rect(10, y, w - 10, y + 5, t[3])
    # Étagères de l'image : on cherche les rangées de livres et on y met du désordre.
    shelf_rows = [(30, 92), (95, 145), (152, 205)]
    for k, (y0, y1) in enumerate(shelf_rows):
        if k == 0:
            # Un trou dans la rangée, deux livres penchés.
            c.rect(70, y0 + 2, 96, y1 - 2, "#2A1E16")
            c.poly([(72, y1 - 2), (76, y1 - 2), (92, y0 + 14), (88, y0 + 12)], "#7A2E26")
            c.poly([(78, y1 - 2), (83, y1 - 2), (95, y0 + 24), (91, y0 + 22)], "#2F4A3A")
        elif k == 1:
            # Grands livres d'images couchés.
            c.rect(22, y0 + 4, 64, y1 - 2, "#2A1E16")
            lying_books(c, 26, y1 - 2, 5, 30, 38)
        else:
            # Un livre ouvert posé à plat sur des romans minces.
            c.rect(84, y0 + 6, 132, y1 - 2, "#2A1E16")
            books(c, 86, 130, y1 - 2, 18, 26, ["#C86A7A", "#E8B040", "#6A8AC8", "#8AA86A"])
            c.poly([(88, y0 + 22), (110, y0 + 18), (110, y0 + 24), (88, y0 + 28)], "#F2EEE2")
            c.poly([(110, y0 + 18), (132, y0 + 22), (132, y0 + 28), (110, y0 + 24)], "#E8E2D2")
    return c.img


def armchair_reading(size, rnd):
    """Fauteuil de cuir brun craquelé, affaissé, un plaid de laine à carreaux sur l'accoudoir."""
    w, h = size
    c = Canvas(w, h, rnd)
    leather = ramp("#7A4A30", 5, spread=0.45)
    c.blob(w / 2, 32, 34, 30, leather[1:4])
    c.rect(8, 40, w - 8, h - 12, leather[2])
    c.blob(16, 56, 12, 18, leather[1:4])
    c.blob(w - 16, 56, 12, 18, leather[1:4])
    c.ellipse(w / 2, 62, 28, 10, leather[3])
    c.rect(20, 62, w - 20, h - 14, leather[2])
    for _ in range(14):
        x, y = rnd.uniform(12, w - 12), rnd.uniform(14, h - 16)
        c.line([(x, y), (x + rnd.uniform(-3, 3), y + rnd.uniform(1, 4))], leather[0])
    # Plaid à carreaux sur l'accoudoir droit.
    plaid = [(w - 30, 42), (w - 4, 44), (w - 2, 78), (w - 26, 76)]
    c.poly(plaid, "#8A2E2E")
    for k in range(4):
        c.line([(w - 28 + k * 7, 42), (w - 24 + k * 7, 78)], "#2E4A3A")
        c.line([(w - 30, 50 + k * 8), (w - 2, 52 + k * 8)], "#C8A060")
    wood(c, 12, h - 12, 18, h, DARK, grain=0)
    wood(c, w - 18, h - 12, w - 12, h, DARK, grain=0)
    return outline_finish(c)


def book_pile(size, rnd):
    """Pile de livres posée par terre, un livre ouvert à plat dessus."""
    w, h = size
    c = Canvas(w, h, rnd)
    y = lying_books(c, 8, h, 6, 30, 36)
    c.poly([(6, y + 1), (w / 2, y - 3), (w / 2, y + 2), (6, y + 5)], "#F2EEE2")
    c.poly([(w / 2, y - 3), (w - 6, y + 1), (w - 6, y + 5), (w / 2, y + 2)], "#E6E0D0")
    c.rect(w / 2 - 1, y - 3, w / 2, y + 2, "#B0A890")
    return outline_finish(c)


def supply_cupboard(size, rnd):
    """Placard à fournitures ouvert : balais, seaux, chiffons, un marteau et une boîte de clous sur
    l'étagère, quelques planches."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 0, 4, w, h, MID, top=5, grain=6)
    c.rect(8, 14, w - 8, h - 6, "#2A2018")
    for y in (60, 100):
        c.rect(8, y, w - 8, y + 3, t[3])
        c.rect(8, y + 3, w - 8, y + 4, t[0])
    # Étagère du haut : boîte de clous et marteau.
    c.rect(14, 46, 34, 60, "#8A6A40")
    c.rect(14, 46, 34, 48, "#A88A5A")
    for k in range(6):
        c.rect(16 + k * 3, 44, 17 + k * 3, 47, "#8A8E94")
    c.rect(40, 54, 70, 57, "#A0703A")
    c.rect(64, 48, 74, 58, "#5C636B")
    c.rect(64, 48, 74, 50, "#8A8E94")
    c.rect(18, 22, 40, 44, "#C8C0B0")
    for k in range(3):
        c.rect(46 + k * 12, 26, 56 + k * 12, 44, rnd.choice(["#C86A5A", "#6A8AC8", "#D8D0B8"]))
    # Étagère du milieu : chiffons pliés et un seau.
    cloth(c, 14, 84, 40, 100, "#C8B898", folds=2)
    iron = ramp("#8A8E94", 4, spread=0.4)
    c.rect(48, 78, 72, 100, iron[2])
    c.rect(48, 78, 72, 80, iron[3])
    c.line([(48, 80), (60, 70), (72, 80)], iron[1])
    # En bas : balai, seau de bois, planches.
    c.rect(18, 104, 21, h - 6, "#B08A50")
    c.poly([(12, h - 30), (28, h - 30), (32, h - 6), (8, h - 6)], "#D8B860")
    for k in range(5):
        c.rect(12 + k * 4, h - 28, 13 + k * 4, h - 7, "#B89848")
    c.rect(56, h - 30, 80, h - 6, "#8A6040")
    c.rect(56, h - 24, 80, h - 22, "#5C636B")
    c.rect(56, h - 12, 80, h - 10, "#5C636B")
    c.rect(38, 104, 44, h - 6, PALE)
    c.rect(45, 110, 50, h - 6, HONEY)
    # Porte ouverte rabattue à gauche.
    c.rect(0, 10, 7, h - 2, t[3])
    c.rect(0, 10, 2, h - 2, t[4])
    return outline_finish(c)


def cleaning_set(size, rnd):
    """Balai de paille, serpillière sur un manche, seau de bois et pelle appuyés ensemble."""
    w, h = size
    c = Canvas(w, h, rnd)
    c.line([(16, 0), (24, h - 34)], "#B08A50", width=3)
    c.poly([(12, h - 38), (34, h - 38), (40, h - 2), (6, h - 2)], "#D8B860")
    for k in range(8):
        c.line([(14 + k * 3, h - 36), (8 + k * 4.2, h - 3)], "#B89848")
    c.rect(10, h - 40, 36, h - 36, "#8A5A30")
    c.line([(48, 2), (42, h - 38)], "#A07A48", width=3)
    for k in range(7):
        c.line([(42, h - 38), (34 + k * 3, h - 14 + rnd.randint(-3, 3))], "#C8C4B8", width=2)
    c.rect(36, h - 22, 62, h, "#8A6040")
    c.rect(36, h - 22, 62, h - 20, "#A88050")
    c.rect(36, h - 16, 62, h - 14, "#5C636B")
    c.rect(36, h - 6, 62, h - 4, "#5C636B")
    c.ellipse(49, h - 22, 13, 2, "#4A6A7A")
    c.poly([(54, h - 46), (64, h - 44), (62, h - 30), (52, h - 32)], "#7A7E84")
    c.line([(58, h - 46), (60, h - 70)], "#A07A48", width=2)
    return outline_finish(c)


def hamper(size, rnd):
    """Panier à linge sale en osier, une serviette qui pend par-dessus le bord."""
    w, h = size
    c = Canvas(w, h, rnd)
    osier = ramp("#B08A50", 5, spread=0.45)
    c.poly([(6, 14), (w - 6, 14), (w - 2, h - 2), (2, h - 2)], osier[2])
    for y in range(16, h - 2, 4):
        for x in range(4, w - 2, 6):
            c.rect(x + (y // 4 % 2) * 3, y, x + (y // 4 % 2) * 3 + 4, y + 2, osier[3])
            c.rect(x + (y // 4 % 2) * 3, y + 2, x + (y // 4 % 2) * 3 + 4, y + 3, osier[1])
    c.ellipse(w / 2, 14, w / 2 - 5, 5, osier[1])
    c.ellipse(w / 2, 14, w / 2 - 8, 3, "#5A4030")
    c.poly([(30, 10), (46, 12), (48, 40), (40, 44), (36, 18)], "#5A8AB0")
    c.rect(38, 30, 47, 33, "#F0EEE6")
    return outline_finish(c)


def piano_old(size, rnd):
    """Vieux piano droit de bois sombre, couvercle ouvert, touches jaunies, une partition sans
    notes lisibles, bougeoirs vides, tabouret rond."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 10, 10, w - 10, h - 4, "#4A3428", grain=10)
    c.rect(6, 6, w - 6, 14, t[3])
    c.rect(6, 6, w - 6, 7, t[4])
    inset(c, 18, 18, w - 18, 56, t)
    # Partition et bougeoirs.
    c.rect(w / 2 - 16, 22, w / 2 + 16, 46, "#EEE6D2")
    for y in range(26, 44, 5):
        c.rect(w / 2 - 13, y, w / 2 + 13, y + 1, "#A9A49A")
    for x in (24, w - 30):
        c.rect(x, 28, x + 6, 32, ramp(BRASS, 4)[2])
        c.rect(x + 2, 20, x + 4, 28, ramp(BRASS, 4)[1])
    # Clavier, touches jaunies.
    c.rect(10, 60, w - 10, 76, "#E8DCB0")
    c.rect(10, 60, w - 10, 62, "#F4ECC8")
    for x in range(12, w - 12, 5):
        c.rect(x, 60, x + 1, 76, "#B8A880")
    for x in range(14, w - 14, 10):
        c.rect(x, 60, x + 3, 69, "#2A2420")
    c.rect(10, 76, w - 10, 80, t[0])
    inset(c, 18, 86, w - 18, h - 10, t)
    # Tabouret rond devant.
    c.ellipse(w / 2, h - 30, 16, 5, ramp("#7A2E26", 4)[2])
    c.rect(w / 2 - 2, h - 26, w / 2 + 2, h - 2, t[1])
    c.rect(w / 2 - 10, h - 4, w / 2 + 10, h - 1, t[1])
    return outline_finish(c)


def floor_cushions(size, rnd):
    """Trois gros coussins rapiécés posés par terre."""
    w, h = size
    c = Canvas(w, h, rnd)
    for k, col in enumerate(["#B5443A", "#4E7A9A", "#C8A040"]):
        cx = 20 + k * 37
        tt = ramp(col, 5, spread=0.45)
        c.blob(cx, h - 16, 19, 14, tt[1:4])
        c.rect(cx - 6, h - 22, cx + 4, h - 15, ramp(rnd.choice(["#7AB04A", "#E8C060", "#9A6AC8"]), 4)[2])
        c.line([(cx - 6, h - 22), (cx + 4, h - 22)], tt[0])
    return outline_finish(c)


def washbasin_stand(size, rnd):
    """Lave-mains sur pied de fer : cuvette, broc, savon, serviette pendue."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4, spread=0.5)
    for x in (8, w - 10):
        c.rect(x, 40, x + 3, h, iron[1])
    c.rect(8, h - 30, w - 8, h - 28, iron[1])
    c.ellipse(w / 2, 38, w / 2 - 4, 6, "#E8ECEE")
    c.ellipse(w / 2, 38, w / 2 - 8, 3, "#9AB0C0")
    c.rect(6, 38, w - 6, 44, "#D8DCE0")
    c.poly([(20, 12), (34, 12), (36, 34), (18, 34)], "#E0E4E8")
    c.rect(34, 16, 39, 26, "#C8CCD0")
    c.rect(40, 30, 48, 34, "#E8C8A0")
    cloth(c, 12, 46, 30, 74, "#F0EEE6", folds=2, stripe="#6A8AC8")
    return outline_finish(c)


def bunk_bed(size, rnd):
    """Lits superposés de bois brut vus de flanc, tête à gauche : échelle au pied, deux couvertures
    de couleurs différentes, un ruban noué au montant."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp(PALE, 5, spread=0.42)
    for x in (2, w - 10):
        wood(c, x, 4, x + 8, h, PALE, grain=3)
    for y0, blanket in ((24, "#5A8AB0"), (h - 70, "#B5603A")):
        c.rect(10, y0 + 30, w - 10, y0 + 38, t[2])
        c.rect(10, y0 + 30, w - 10, y0 + 31, t[3])
        c.rect(10, y0 + 18, w - 10, y0 + 30, "#ECE6D8")
        c.ellipse(26, y0 + 16, 12, 6, "#F4F0E8")
        c.rect(40, y0 + 12, w - 12, y0 + 30, ramp(blanket, 4)[2])
        c.rect(40, y0 + 12, w - 12, y0 + 14, ramp(blanket, 4)[3])
        for k in range(4):
            c.rect(52 + k * 26, y0 + 14, 53 + k * 26, y0 + 30, ramp(blanket, 4)[1])
        c.rect(10, y0, 18, y0 + 30, t[2])
    c.rect(10, 4, w - 10, 10, t[3])
    # Échelle au pied (à droite), ruban au montant.
    for y in range(30, h - 6, 16):
        c.rect(w - 26, y, w - 10, y + 3, t[3])
    c.rect(w - 28, 26, w - 25, h, t[1])
    c.poly([(4, 60), (10, 58), (8, 66), (12, 74), (6, 70)], "#C8487A")
    c.rect(10, h - 6, w - 10, h, t[1])
    return outline_finish(c)


def clothes_chest(size, rnd):
    """Coffre à vêtements entrouvert, une manche qui dépasse."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 4, 18, w - 4, h, MID, grain=5)
    c.poly([(2, 12), (w - 2, 8), (w - 2, 18), (2, 18)], t[3])
    c.rect(2, 16, w - 2, 19, t[1])
    c.rect(8, 18, w - 8, 21, "#2A2018")
    c.poly([(30, 19), (40, 19), (42, 40), (34, 42)], "#7A9AC8")
    c.rect(33, 40, 41, 43, "#F0EEE6")
    iron = ramp(IRON, 4)
    for x in (10, w - 14):
        c.rect(x, 18, x + 4, h, iron[1])
    c.rect(w / 2 - 3, 26, w / 2 + 3, 32, ramp(BRASS, 4)[2])
    return outline_finish(c)


def desk_clean_brooch(size, rnd):
    """Bureau de bois sombre parfaitement propre et vide, sauf une broche d'argent à pierre bleue en
    goutte posée au centre."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 4, 20, w - 4, 40, DARK, top=10, grain=3)
    c.rect(6, 40, 14, h, t[1])
    c.rect(w - 14, 40, w - 6, h, t[1])
    inset(c, w - 40, 40, w - 14, 62, t)
    knob(c, w - 28, 50)
    c.rect(14, 40, w - 40, 44, t[1])
    # La broche, au centre du plateau.
    c.ellipse(w / 2, 25, 4, 3, "#C8CCD4")
    c.poly([(w / 2, 22), (w / 2 + 3, 26), (w / 2, 30), (w / 2 - 3, 26)], "#3A6AC8")
    c.rect(w / 2 - 1, 24, w / 2, 25, "#B8D8F8")
    # Chaise rangée sous le bureau.
    ch = ramp(DARK, 4, spread=0.4)
    c.rect(24, 30, 28, h, ch[1])
    c.rect(48, 30, 52, h, ch[1])
    c.rect(24, 30, 52, 34, ch[2])
    c.rect(22, 60, 54, 64, ch[3])
    return outline_finish(c)


def footlocker(size, rnd):
    """Malle de voyage cabossée cerclée de cuir ; dessus, un rasoir, une grande cuillère et une
    grande bouteille d'épices."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 2, 20, w - 2, h, "#5A4A3A", top=5, grain=4)
    for x in (12, w - 16):
        c.rect(x, 20, x + 5, h, "#7A4A2A")
        c.rect(x, 20, x + 1, h, "#9A6A42")
    c.rect(w / 2 - 4, 26, w / 2 + 4, 34, ramp(BRASS, 4)[2])
    c.line([(20, 30), (28, 34)], t[0])
    # Objets posés : bouteille d'épices, cuillère, rasoir.
    c.rect(54, 2, 64, 20, "#7A3A20")
    c.rect(56, 0, 62, 3, "#3A2A20")
    c.rect(55, 9, 63, 14, "#E8DCC0")
    c.rect(20, 16, 44, 18, "#A88A5A")
    c.ellipse(46, 17, 4, 2, "#A88A5A")
    c.rect(10, 17, 18, 19, "#C8CCD4")
    return outline_finish(c)


def leak_bucket(size, rnd):
    """Seau de bois cerclé posé sous la fuite, un fond d'eau, une petite flaque autour."""
    w, h = size
    c = Canvas(w, h, rnd)
    c.ellipse(w / 2, h - 3, w / 2 - 1, 3, "#7A9AAE")
    t = ramp("#8A6040", 5, spread=0.45)
    c.poly([(10, 8), (w - 10, 8), (w - 13, h - 3), (13, h - 3)], t[2])
    for x in range(14, w - 12, 5):
        c.rect(x, 9, x + 1, h - 4, t[1])
    for y in (14, h - 10):
        c.rect(10, y, w - 10, y + 2, "#5C636B")
    c.ellipse(w / 2, 8, w / 2 - 10, 3, t[1])
    c.ellipse(w / 2, 9, w / 2 - 13, 2, "#4A6A80")
    return outline_finish(c)


def repair_planks(size, rnd):
    """Planches et lattes appuyées contre le mur, une boîte de clous et un marteau au pied : la
    dernière réparation de la fuite."""
    w, h = size
    c = Canvas(w, h, rnd)
    for k, (x, top, col) in enumerate([(8, 4, PALE), (20, 12, HONEY), (32, 0, "#A88A62"), (44, 20, PALE)]):
        tt = ramp(col, 5, spread=0.4)
        c.poly([(x, h - 6), (x + 11, h - 6), (x + 15, top), (x + 4, top)], tt[2])
        c.line([(x + 1, h - 7), (x + 5, top + 1)], tt[3])
        c.line([(x + 10, h - 7), (x + 14, top + 1)], tt[1])
        for _ in range(3):
            gy = rnd.uniform(top + 10, h - 20)
            c.rect(x + 6 + (h - gy) * 0.02, gy, x + 7 + (h - gy) * 0.02, gy + 8, tt[1])
    c.rect(4, h - 14, 26, h, "#8A6A40")
    c.rect(4, h - 14, 26, h - 12, "#A88A5A")
    for k in range(5):
        c.rect(7 + k * 4, h - 16, 8 + k * 4, h - 12, "#8A8E94")
    c.rect(34, h - 5, 58, h - 2, "#A0703A")
    c.rect(54, h - 10, 63, h - 1, "#5C636B")
    return outline_finish(c)


def roof_ladder(size, rnd):
    """Échelle de meunier de bois, raide, contre le mur, qui monte à une trappe ouverte au plafond
    (haut de l'image) ; un rai de jour par la trappe (nom proposé, CARTE.md 12.1)."""
    w, h = size
    c = Canvas(w, h, rnd)
    # Trappe ouverte au plafond : cadre sombre, ciel pâle, couvercle rabattu.
    c.rect(4, 0, w - 4, 26, "#2A2018")
    c.rect(10, 2, w - 10, 22, "#C8D8E8")
    c.rect(10, 2, w - 10, 8, "#E8EEF4")
    c.rect(2, 22, w - 2, 28, ramp(DARK, 4)[2])
    # Rai de jour (pixels clairs alignés en diagonale).
    for y in range(30, h - 40, 3):
        x = 22 + (y - 30) * 0.06
        if (y // 3) % 2 == 0:
            c.rect(x, y, x + 10, y + 1, "#F4E8C8")
    t = ramp(HONEY, 5, spread=0.42)
    for x in (10, w - 18):
        c.rect(x, 24, x + 8, h, t[2])
        c.rect(x, 24, x + 2, h, t[3])
        c.rect(x + 6, 24, x + 8, h, t[1])
    for y in range(40, h - 4, 22):
        c.rect(18, y, w - 18, y + 6, t[3])
        c.rect(18, y, w - 18, y + 1, t[4])
        c.rect(18, y + 5, w - 18, y + 6, t[0])
        c.rect(18 + (w - 36) * 0.4, y + 1, 18 + (w - 36) * 0.6, y + 2, t[4])
    return outline_finish(c)


def stairs_down(size, rnd):
    """Trémie de l'escalier vue de l'étage : rambarde de bois en équerre à barreaux tournés, les
    premières marches qui descendent dans la pénombre."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp(MID, 5, spread=0.45)
    # Marches qui s'enfoncent (de plus en plus sombres vers le bas de l'image).
    for k in range(6):
        y = 40 + k * 10
        shade = mix(t[3], "#1A1410", k / 6.0)
        c.rect(14, y, w - 14, y + 6, shade)
        c.rect(14, y + 6, w - 14, y + 10, mix(t[1], "#100C0A", k / 6.0))
    c.rect(14, 100, w - 14, h, "#100C0A")
    # Rambarde en équerre : main courante, barreaux tournés, poteaux.
    c.rect(4, 22, w - 4, 28, t[3])
    c.rect(4, 22, w - 4, 23, t[4])
    for x in range(14, w - 10, 12):
        c.rect(x, 28, x + 4, h - 2, t[2])
        c.rect(x, 40, x + 4, 44, t[3])
        c.rect(x, 64, x + 4, 68, t[3])
        c.rect(x + 3, 28, x + 4, h - 2, t[1])
    for x in (2, w - 12):
        wood(c, x, 14, x + 10, h, t[2], grain=0)
        c.rect(x - 1, 10, x + 11, 15, t[3])
    c.rect(4, h - 4, w - 4, h, t[1])
    return outline_finish(c)


def crypt_stairs(size, rnd):
    """Escalier de pierre vu de face qui remonte vers le fond jusqu'à la porte rivetée, marches
    creusées et humides."""
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("#6E665E", 5, spread=0.42)
    # La porte rivetée en haut des marches (petite, au fond).
    c.rect(w / 2 - 22, 0, w / 2 + 22, 54, stone[1])
    c.rect(w / 2 - 17, 5, w / 2 + 17, 54, "#3A3E44")
    for k in range(5):
        c.rect(w / 2 + 8, 14 + k * 7, w / 2 + 13, 17 + k * 7, ramp(BRASS, 4)[1])
    for x in range(int(w / 2 - 15), int(w / 2 + 16), 6):
        c.rect(x, 7, x + 1, 8, "#8A8E94")
    # Marches de plus en plus larges vers le bas (perspective vers le fond).
    steps = 9
    for k in range(steps):
        y0 = 54 + k * (h - 54) / steps
        y1 = 54 + (k + 1) * (h - 54) / steps
        inset_px = 22 - k * 2.4
        c.rect(inset_px, y0, w - inset_px, y1, stone[2])
        c.rect(inset_px, y0, w - inset_px, y0 + 3, stone[3])
        c.rect(w / 2 - 14, y0 + 1, w / 2 + 14, y0 + 3, stone[4])
        c.rect(inset_px, y1 - 2, w - inset_px, y1, stone[0])
        c.ellipse(w / 2 + rnd.uniform(-6, 6), y0 + 2, 9, 1.5, "#4A5560")
    # Murs latéraux de moellons.
    for x0, x1 in ((0, 14), (w - 14, w)):
        y = 30
        while y < h:
            bh = rnd.randint(12, 20)
            c.rect(x0 + 1, y + 1, x1 - 1, min(h, y + bh) - 1, stone[rnd.choice([1, 2])])
            y += bh
    damp = fractal((w, h), (4, 6), rnd, 2).point(lambda v: int(max(0, v - 150) * 1.2))
    c.img.paste(Image.blend(c.img, Image.new("RGBA", (w, h), rgba("#2A2A2E")), 0.5), (0, 0), damp)
    return c.finish(darker("#2E2C2A", 0.5))


def talisman_chest(size, rnd):
    """Coffret ouvert garni de velours sombre, en casiers : des éclats de métal blanc gravés, les
    talismans en réserve."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 2, 26, w - 2, h, "#4A3428", grain=3)
    c.poly([(4, 4), (w - 4, 4), (w - 2, 14), (2, 14)], t[3])
    c.rect(2, 12, w - 2, 15, t[1])
    c.rect(6, 18, w - 6, 30, "#2A1A2E")
    for k in range(4):
        x0 = 8 + k * 16
        c.rect(x0, 19, x0 + 14, 29, "#3A2440")
        c.poly([(x0 + 3, 27), (x0 + 7, 20), (x0 + 11, 27)], "#E8ECF0")
        c.line([(x0 + 6, 24), (x0 + 8, 24)], "#8A9AB0")
    for x in (2, w - 6):
        c.rect(x, 26, x + 4, h, ramp(BRASS, 4)[1])
    return outline_finish(c)


def roof_hatch(size, rnd):
    """Trappe d'accès au toit ouverte, le haut d'une échelle de bois qui dépasse, couvercle
    rabattu."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#7A6A58", 5, spread=0.4)
    c.rect(8, h - 16, w - 8, h, t[1])
    c.rect(14, h - 14, w - 14, h, "#1A1410")
    # Couvercle rabattu derrière (vu de face, debout).
    lid = ramp("#8A7A64", 5, spread=0.4)
    c.rect(18, 4, w - 18, h - 16, lid[2])
    for x in range(20, w - 18, 9):
        c.rect(x, 4, x + 1, h - 16, lid[1])
    c.rect(18, 4, w - 18, 6, lid[3])
    c.rect(w / 2 - 6, 24, w / 2 + 6, 28, "#5C636B")
    # Haut de l'échelle qui dépasse.
    wt = ramp(HONEY, 4, spread=0.4)
    for x in (30, w - 36):
        c.rect(x, 20, x + 5, h - 2, wt[2])
        c.rect(x, 20, x + 1, h - 2, wt[3])
    c.rect(30, h - 10, w - 31, h - 7, wt[3])
    c.rect(8, h - 16, w - 8, h - 14, t[3])
    return outline_finish(c)


def roof_railing_broken(size, rnd):
    """Le module de rambarde (roof_railing, livré) dont un pan est tordu vers le dehors et un
    barreau manque. Part d'une copie de l'image livrée."""
    base = asset("interior/props/roof_railing")
    w, h = size
    if base is None or base.size != (w, h):
        c = Canvas(w, h, rnd)
        c.rect(0, 8, w, 14, "#4E7A5A")
        return c.img
    img = base.copy()
    # Pan tordu : la moitié droite de la main courante penche vers le bas, un barreau effacé.
    right = img.crop((w // 2, 0, w, h))
    bent = Image.new("RGBA", right.size, (0, 0, 0, 0))
    for x in range(right.width):
        dy = int(round(x * 0.12))
        column = right.crop((x, 0, x + 1, h - dy))
        bent.paste(column, (x, dy))
    img.paste(Image.new("RGBA", right.size, (0, 0, 0, 0)), (w // 2, 0))
    img.alpha_composite(bent, (w // 2, 0))
    # Un barreau manque : on efface une bande verticale au-dessous de la main courante.
    clear = Image.new("RGBA", (6, h - 30), (0, 0, 0, 0))
    img.paste(clear, (int(w * 0.72), 22))
    d = ImageDraw.Draw(img)
    d.rectangle((int(w * 0.72), h - 9, int(w * 0.72) + 5, h - 1), fill=rgba("#4E5A50"))
    return img


def crystal_pendant(size, rnd):
    """Suspension de fer forgé à trois cristaux lumineux (#FFE6A6) dans des cages, pendue à une
    chaîne (le haut de l'image est le crochet du plafond)."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("#3E4248", 5, spread=0.5)
    c.rect(w / 2 - 4, 0, w / 2 + 4, 3, iron[1])
    for y in range(3, 70, 5):
        c.rect(w / 2 - 1, y, w / 2 + 2, y + 3, iron[2 if (y // 5) % 2 else 3])
    c.rect(8, 76, w - 8, 80, iron[1])
    c.rect(8, 76, w - 8, 77, iron[3])
    c.line([(w / 2, 70), (12, 78)], iron[1])
    c.line([(w / 2, 70), (w - 12, 78)], iron[1])
    for cx in (14, w / 2, w - 14):
        crystal(c, cx, 98, 6, 11)
        for x in (cx - 8, cx + 7):
            c.rect(x, 82, x + 1, 112, iron[2])
        c.rect(cx - 8, 82, cx + 8, 84, iron[2])
        c.rect(cx - 8, 112, cx + 8, 115, iron[1])
        c.rect(cx - 1, 115, cx + 1, 122, iron[1])
    c.rect(w / 2 - 6, 124, w / 2 + 6, 128, iron[1])
    return c.finish(darker("#2A2C30", 0.5))


# --- Objets posés ------------------------------------------------------------------------------


def crystal_lamp_table(size, rnd):
    """Lampe de table : petit cristal lumineux dans une cloche de verre, pied de laiton."""
    w, h = size
    c = Canvas(w, h, rnd)
    b = ramp(BRASS, 4, spread=0.5)
    c.rect(4, h - 4, w - 4, h, b[1])
    c.rect(w / 2 - 2, h - 14, w / 2 + 2, h - 4, b[2])
    c.ellipse(w / 2, h - 26, 11, 13, "#D8E4EA")
    crystal(c, w / 2, h - 25, 5, 8)
    c.rect(w / 2 - 5, h - 40, w / 2 - 3, h - 30, "#F4F8FA")
    c.rect(w / 2 - 2, 0, w / 2 + 2, 4, b[1])
    return c.finish(darker(BRASS, 0.4))


def coffee_tray(size, rnd):
    """Plateau : grande tasse de café noir épais comme du sirop, sandwich sur pain sec."""
    w, h = size
    c = Canvas(w, h, rnd)
    c.rect(1, h - 5, w - 1, h, ramp(MID, 4)[2])
    c.rect(1, h - 5, w - 1, h - 4, ramp(MID, 4)[3])
    c.rect(6, 6, 18, h - 5, "#E8E4DC")
    c.rect(6, 6, 18, 8, "#2A1810")
    c.rect(18, 9, 21, 15, "#E8E4DC")
    c.rect(26, 11, 44, h - 5, "#C8A060")
    c.rect(26, 13, 44, 15, "#7AA04A")
    c.rect(26, 15, 44, 16, "#8A4A3A")
    return outline_finish(c)


def vase_flowers(size, rnd):
    """Vase de terre vernissée avec un bouquet de fleurs des champs d'automne."""
    w, h = size
    c = Canvas(w, h, rnd)
    c.poly([(7, 18), (w - 7, 18), (w - 4, h - 3), (4, h - 3)], "#6A8A9A")
    c.rect(4, h - 3, w - 4, h, "#4A6A7A")
    c.rect(8, 20, 10, h - 6, "#9ABACA")
    for _ in range(9):
        x, y = rnd.uniform(4, w - 4), rnd.uniform(3, 16)
        c.line([(w / 2, 18), (x, y)], "#5A7A3A")
        c.ellipse(x, y, 2, 2, rnd.choice(["#E8B040", "#C85A3A", "#B07AC0", "#F0E6C8"]))
    return outline_finish(c)


def oil_lamp(size, rnd):
    """Petite lampe à huile de lecture en laiton, verre bombé, mèche."""
    w, h = size
    c = Canvas(w, h, rnd)
    b = ramp(BRASS, 5, spread=0.5)
    c.rect(3, h - 4, w - 3, h, b[1])
    c.ellipse(w / 2, h - 9, 8, 5, b[2])
    c.rect(w / 2 - 5, h - 9, w / 2 + 5, h - 6, b[3])
    c.ellipse(w / 2, 14, 6, 10, "#E0E8EC")
    crystal(c, w / 2, 16, 2, 4)
    c.rect(w / 2 - 3, 2, w / 2 + 3, 4, b[1])
    return c.finish(darker(BRASS, 0.4))


def tea_tray_cheesecake(size, rnd):
    """Plateau de thé : théière, petites tasses, pot à lait, sucrier, et un cheese-cake dont il
    manque deux parts."""
    w, h = size
    c = Canvas(w, h, rnd)
    c.rect(1, h - 4, w - 1, h, ramp(MID, 4)[2])
    c.ellipse(11, h - 12, 8, 7, "#F0ECE4")
    c.rect(18, h - 16, 23, h - 13, "#F0ECE4")
    c.ellipse(11, h - 19, 3, 2, "#C85A6A")
    for x in (24, 30):
        c.rect(x, h - 8, x + 5, h - 4, "#F0ECE4")
    c.rect(33, h - 13, 37, h - 4, "#E8E8F0")
    # Cheese-cake entamé.
    c.poly([(40, h - 4), (56, h - 4), (56, h - 12), (46, h - 12), (40, h - 7)], "#F4E2A8")
    c.rect(40, h - 6, 56, h - 4, "#C8A060")
    c.rect(46, h - 13, 56, h - 12, "#E8C880")
    return outline_finish(c)


# --- Décalques --------------------------------------------------------------------------------


def runner_rug(size, rnd):
    """Tapis de couloir tissé brun et rouge passé, liseré ocre, usé au milieu en un chemin plus
    clair, une tache ; il se répète en longueur sans couture (raccord en haut et en bas)."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, x1 = 8, w - 8
    d.rectangle((x0, 0, x1 - 1, h - 1), fill=rgba("#8A3A2E"))
    d.rectangle((x0 + 4, 0, x1 - 5, h - 1), fill=rgba("#6A4030"))
    d.rectangle((x0 + 8, 0, x1 - 9, h - 1), fill=rgba("#9A4A36"))
    for y in range(0, h, 24):
        for k in range(3):
            cx = w / 2
            d.polygon([(cx, y + 4 + k), (cx + 12 - k * 3, y + 12), (cx, y + 20 - k), (cx - 12 + k * 3, y + 12)],
                      fill=rgba(["#C89A4A", "#7A3026", "#B0703A"][k]))
    for x in (x0 + 2, x1 - 3):
        d.rectangle((x, 0, x, h - 1), fill=rgba("#C8A050"))
    # Usure claire au milieu (bruit qui se raccorde en haut et en bas).
    wear = noise((x1 - x0 - 16, h), (3, 12), rnd).point(lambda v: int(max(0, v - 110) * 0.9))
    img.paste(Image.blend(img.crop((x0 + 8, 0, x1 - 8, h)), Image.new("RGBA", wear.size, rgba("#C8A888")), 0.6),
              (x0 + 8, 0), wear)
    d = ImageDraw.Draw(img)
    d.ellipse((w / 2 - 10, 230, w / 2 + 6, 244), fill=rgba("#5A3A2A"))
    # Bords effilochés à gauche et à droite.
    for y in range(0, h, 2):
        if rnd.random() < 0.35:
            d.rectangle((x0 - 2, y, x0 - 1, y), fill=rgba("#B07A40"))
        if rnd.random() < 0.35:
            d.rectangle((x1, y, x1 + 1, y), fill=rgba("#B07A40"))
    return img


def _scatter_decal(size, rnd, pieces):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    c = Canvas(size[0], size[1], rnd)
    c.img = img
    c.draw = ImageDraw.Draw(img)
    for piece in pieces:
        piece(c)
    return c.img


def _sheet(c, cx, cy, w, h, angle, color, lines="#A9A49A"):
    from hd2d_art import rotate_points
    pts = rotate_points([(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
                         (cx - w / 2, cy + h / 2)], cx, cy, angle)
    c.poly(pts, color)
    for k in range(int(h // 4) - 1):
        a = (cx - w / 2 + 3, cy - h / 2 + 4 + k * 4)
        b = (cx + w / 2 - 3 - c.rnd.uniform(0, w / 3), a[1])
        c.line(rotate_points([a, b], cx, cy, angle), lines)


def papers_floor(size, rnd):
    """Feuilles éparses par terre vues de dessus : un rapport, une coupure de magazine, un bon de
    commande, une enveloppe ; lignes grises, aucune lettre."""
    w, h = size
    pieces = []
    for k in range(9):
        cx, cy = rnd.uniform(28, w - 28), rnd.uniform(24, h - 24)
        col = rnd.choice(["#F0EAD8", "#E8E0C8", "#F2EEE6", "#E8DCC8"])
        pieces.append(lambda c, cx=cx, cy=cy, col=col: _sheet(c, cx, cy, rnd.uniform(26, 34), rnd.uniform(32, 42),
                                                               rnd.uniform(-0.6, 0.6), col))
    pieces.append(lambda c: _sheet(c, w * 0.7, h * 0.3, 28, 34, 0.3, "#F0D8E0", "#C86A7A"))
    pieces.append(lambda c: c.poly([(40, 100), (72, 96), (74, 116), (42, 120)], "#D8C8A0"))
    return _scatter_decal(size, rnd, pieces)


def bath_puddles(size, rnd):
    """Flaques et éclaboussures d'eau savonneuse sur le carrelage, quelques bulles, empreintes de
    petits pieds mouillés qui s'en vont."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    field = fractal(size, (5, 4), rnd, 3)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    for _ in range(5):
        cx, cy = rnd.uniform(40, w - 40), rnd.uniform(30, h - 50)
        md.ellipse((cx - rnd.uniform(18, 34), cy - rnd.uniform(10, 18), cx + rnd.uniform(18, 34),
                    cy + rnd.uniform(10, 18)), fill=255)
    from PIL import ImageChops
    puddle = ImageChops.multiply(mask, field.point(lambda v: 255 if v > 70 else 0))
    water = Image.new("RGBA", size, rgba("#9AC0D0", 170))
    img.paste(water, (0, 0), puddle)
    d = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = rnd.uniform(30, w - 30), rnd.uniform(20, h - 40)
        r = rnd.uniform(1, 3)
        d.ellipse((x - r, y - r, x + r, y + r), outline=rgba("#F4F8FA", 220))
    for k in range(4):
        x, y = w * 0.62 + k * 14, h - 28 - k * 6
        for dx in (0, 6):
            d.ellipse((x + dx, y + (dx // 3), x + dx + 4, y + 7 + (dx // 3)), fill=rgba("#8AB0C0", 150))
    return steps_alpha(img, 6)


def cards_floor(size, rnd):
    """Jeu de cartes éparpillé par terre vu de dessus, dos rouges, figures sans lettres ni
    chiffres."""
    w, h = size
    pieces = []
    for k in range(13):
        cx, cy = rnd.uniform(18, w - 18), rnd.uniform(16, h - 16)
        face = rnd.random() < 0.35

        def card(c, cx=cx, cy=cy, face=face, a=rnd.uniform(-1.2, 1.2)):
            from hd2d_art import rotate_points
            pts = rotate_points([(cx - 7, cy - 10), (cx + 7, cy - 10), (cx + 7, cy + 10), (cx - 7, cy + 10)], cx, cy, a)
            c.poly(pts, "#F4F0E8" if face else "#B03030")
            if face:
                c.ellipse(cx, cy, 3, 3, c.rnd.choice(["#B03030", "#2A2A30"]))
            else:
                c.poly(rotate_points([(cx - 5, cy - 8), (cx + 5, cy - 8), (cx + 5, cy + 8), (cx - 5, cy + 8)], cx, cy, a),
                       "#D06050")
        pieces.append(card)
    return _scatter_decal(size, rnd, pieces)


def clothes_floor(size, rnd):
    """Vêtements jetés par terre vus de dessus : chemise, jupe, chaussettes dépareillées, une
    écharpe ; aucun sous-vêtement visible."""
    w, h = size

    def shirt(c):
        c.poly([(40, 30), (80, 26), (96, 40), (88, 46), (86, 92), (46, 96), (44, 50), (30, 48)], "#E8ECF0")
        c.poly([(56, 28), (66, 40), (72, 27)], "#C8D0D8")
        for y in (52, 64, 76):
            c.rect(64, y, 66, y + 2, "#A0A8B0")

    def skirt(c):
        c.poly([(118, 70), (150, 66), (172, 118), (108, 124)], "#4E6A9A")
        for k in range(5):
            c.line([(124 + k * 7, 70), (116 + k * 12, 120)], "#3A527A")

    def socks(c):
        c.poly([(20, 106), (30, 104), (34, 126), (46, 128), (44, 136), (24, 132)], "#C85A5A")
        c.poly([(150, 20), (160, 22), (158, 40), (170, 46), (164, 52), (150, 42)], "#E8C060")

    def scarf(c):
        c.line([(70, 112), (100, 104), (120, 132), (150, 128)], "#6A8A4A", width=8)
        for x in (150, 154):
            c.line([(x, 126), (x + 4, 138)], "#4A6A3A")
    return _scatter_decal(size, rnd, [shirt, skirt, socks, scarf])


# --- Bandes animées ---------------------------------------------------------------------------


def pot_steam(size, rnd, frames):
    """Vapeur blanche qui monte d'une marmite et s'étire (alpha doux) ; le bas de l'image est le
    bord de la marmite (non dessinée)."""
    w, h = size
    out = []
    puffs = [(rnd.uniform(-6, 6), rnd.uniform(0, 1), rnd.uniform(6, 10)) for _ in range(5)]
    for f in range(frames):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        for k, (dx, phase, r) in enumerate(puffs):
            t = (f / float(frames) + phase + k / 5.0) % 1.0
            y = h - 4 - t * (h - 16)
            x = w / 2 + dx * (0.3 + t) + math.sin((t + k) * 6.0) * 4
            rr = r * (0.6 + t * 0.9)
            alpha = int(170 * (1.0 - t) ** 0.8)
            d.ellipse((x - rr, y - rr * 0.8, x + rr, y + rr * 0.8), fill=(244, 244, 240, alpha))
        d.ellipse((w / 2 - 12, h - 7, w / 2 + 12, h + 2), fill=(240, 240, 236, 150))
        out.append(steps_alpha(img, 8))
    return out


def leak_drip(size, rnd, frames):
    """Une goutte d'eau qui se forme au plafond (haut de l'image) et tombe jusqu'au bas (le bord du
    seau) ; image 4 : une petite gerbe ; fond transparent."""
    w, h = size
    out = []
    for f in range(frames):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle((w / 2 - 3, 0, w / 2 + 2, 1), fill=rgba("#8AB0C8"))
        if f == 0:
            d.ellipse((w / 2 - 2, 1, w / 2 + 2, 6), fill=rgba("#A8CCE0"))
        elif f in (1, 2):
            y = 20 + (f - 1) * 40
            d.ellipse((w / 2 - 2, y, w / 2 + 2, y + 6), fill=rgba("#A8CCE0"))
            d.rectangle((w / 2 - 1, y - 6, w / 2, y), fill=rgba("#C8E0F0"))
        else:
            for dx, dy in ((-6, -6), (-3, -9), (3, -9), (6, -6)):
                d.rectangle((w / 2 + dx, h - 3 + dy, w / 2 + dx + 1, h - 2 + dy), fill=rgba("#A8CCE0"))
            d.rectangle((w / 2 - 5, h - 2, w / 2 + 4, h - 1), fill=rgba("#8AB0C8"))
        out.append(img)
    return out


def drying_frame_wave(size, rnd, frames):
    """drying_frame (livré) dont le linge ondule au vent vers la droite, poteaux et cordes
    immobiles : chaque image décale les colonnes de linge d'une onde. Part d'une copie de l'image
    livrée."""
    w, h = size
    base = asset("interior/props/drying_frame")
    if base is None or base.size != (w, h):
        return [Image.new("RGBA", size, (0, 0, 0, 0)) for _ in range(frames)]
    # Poteaux : les colonnes très opaques sur toute la hauteur aux deux bouts restent fixes.
    alpha = base.getchannel("A")
    fixed = set()
    for x in range(w):
        col = alpha.crop((x, h // 3, x + 1, h))
        if col.histogram()[255] > (h - h // 3) * 0.85:
            fixed.add(x)
    out = []
    for f in range(frames):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        for x in range(w):
            if x in fixed:
                img.paste(base.crop((x, 0, x + 1, h)), (x, 0))
                continue
            phase = (f / float(frames) + x / 96.0) * 2.0 * math.pi
            # Le haut du linge (pinces, cordes) bouge peu, le bas ondule.
            col = base.crop((x, 0, x + 1, h))
            shifted = Image.new("RGBA", (1, h), (0, 0, 0, 0))
            for y in range(h):
                px = col.getpixel((0, y))
                if px[3] == 0:
                    continue
                dy = int(round(math.sin(phase) * 2.0 * min(1.0, y / (h * 0.6))))
                yy = max(0, min(h - 1, y + dy))
                shifted.putpixel((0, yy), px)
            img.alpha_composite(shifted, (x, 0))
        out.append(img)
    return out


# --- Table des recettes ------------------------------------------------------------------------

PANELS = ["door_service", "door_armory_inside", "window_curtains_open", "window_curtains_closed", "window_bare",
          "window_dusty", "wallitem_notices_mix", "wallitem_frame_landscape", "wallitem_crystal_sconce",
          "wallitem_spice_shelf", "wallitem_apron_hook", "wallitem_clippings", "wallitem_labcoat",
          "wallitem_kids_drawings", "wallitem_cobweb"]
PROPS = ["pantry_cupboard", "sacks_vegetables", "filing_cabinet", "bookshelf_tall_b", "armchair_reading", "book_pile",
         "supply_cupboard", "cleaning_set", "hamper", "piano_old", "floor_cushions", "washbasin_stand", "bunk_bed",
         "clothes_chest", "desk_clean_brooch", "footlocker", "leak_bucket", "repair_planks", "roof_ladder",
         "stairs_down", "crypt_stairs", "talisman_chest", "roof_hatch", "roof_railing_broken", "crystal_pendant",
         "crystal_lamp_table", "coffee_tray", "vase_flowers", "oil_lamp", "tea_tray_cheesecake"]
DECALS = ["runner_rug", "papers_floor", "bath_puddles", "cards_floor", "clothes_floor"]
ANIMS = ["pot_steam", "leak_drip", "drying_frame_wave"]

RECIPES = {}
for _name in PANELS:
    RECIPES["interior/" + _name] = globals()[_name]
for _name in PROPS:
    RECIPES["interior/props/" + _name] = globals()[_name]
for _name in DECALS:
    RECIPES["decals/" + _name] = globals()[_name]
for _name in ANIMS:
    RECIPES["anim/" + _name] = globals()[_name]

# Pour les outils (rien à exporter d'autre) : posterize, WrapCanvas, wrap_y restent disponibles.
_UNUSED = (posterize, WrapCanvas, wrap_y)
