"""Recettes HD-2D : décors en panneaux, façades et panneaux des bâtiments.

Un panneau est un objet debout vu de face (très légèrement plongeant), fond transparent, collé
au bord bas et centré ; une façade est une élévation de face collée aux bords gauche, droit et bas
(docs/ASSETS_HD2D.md, sections 6 et 7). Chaque recette reçoit (taille, générateur aléatoire)."""

import math

from PIL import Image, ImageDraw

import hd2d_ground
from hd2d_art import Canvas, darker, mix, ramp, rgba, tile_fill

OUTLINE = "#2E2630"


# --- Briques communes ---------------------------------------------------------------------------


def trunk(c, cx, y_base, y_top, w_base, w_top, base="wood_dark", lean=0.0):
    tones = ramp(base, 5, spread=0.45)
    lx0, lx1 = cx - w_base / 2.0, cx + w_base / 2.0
    tx0, tx1 = cx - w_top / 2.0 + lean, cx + w_top / 2.0 + lean
    c.poly([(lx0 - 4, y_base), (tx0, y_top), (tx1, y_top), (lx1 + 4, y_base)], tones[1])
    c.poly([(lx0 - 2, y_base), (tx0, y_top), (tx0 + (tx1 - tx0) * 0.45, y_top),
            (lx0 + (lx1 - lx0) * 0.45, y_base)], tones[3])
    c.poly([(lx0 + 1, y_base), (tx0 + 1, y_top), (tx0 + (tx1 - tx0) * 0.18, y_top),
            (lx0 + (lx1 - lx0) * 0.18, y_base)], tones[4])
    for _ in range(int((y_base - y_top) / 9)):
        y = c.rnd.uniform(y_top, y_base)
        t = (y - y_top) / max(1.0, y_base - y_top)
        x0 = tx0 + (lx0 - tx0) * t
        x1 = tx1 + (lx1 - tx1) * t
        x = c.rnd.uniform(x0 + 2, max(x0 + 3, x1 - 3))
        c.line([(x, y), (x + c.rnd.uniform(-1, 1), y + c.rnd.randint(3, 8))], tones[0])


def crown(c, cx, cy, rx, ry, base, count=40, size=(0.18, 0.32), light=(-0.55, -0.6)):
    """Feuillage en masses : boules ombrées, de l'arrière (haut) vers l'avant (bas)."""
    tones = ramp(base, 5, spread=0.5)
    blobs = []
    for _ in range(count):
        a = c.rnd.uniform(0, 2 * math.pi)
        d = math.sqrt(c.rnd.random())
        x = cx + math.cos(a) * rx * d * 0.8
        y = cy + math.sin(a) * ry * d * 0.8
        r = c.rnd.uniform(*size) * (rx + ry)
        blobs.append((y, x, r))
    blobs.sort()
    for y, x, r in blobs:
        low = (y - (cy - ry)) / (2 * ry)
        shift = 1 if low > 0.7 else 0
        cols = tones[0:4] if shift else tones[0:5]
        c.blob(x, y, r, r * 0.86, cols, light)
    # Texture : petites touches de feuilles claires et sombres.
    for _ in range(int(rx * ry / 12)):
        a = c.rnd.uniform(0, 2 * math.pi)
        d = math.sqrt(c.rnd.random())
        x = cx + math.cos(a) * rx * d
        y = cy + math.sin(a) * ry * d
        if c.img.getpixel((int(x) % c.w, int(y) % c.h))[3] > 0:
            col = tones[4] if (x - cx) + (y - cy) < 0 and c.rnd.random() < 0.6 else tones[1]
            c.rect(x, y, x + 2, y + 1, col)


def pine_tiers(c, cx, y_top, y_bottom, half_w, tiers, base="pine"):
    tones = ramp(base, 5, spread=0.55)
    height = y_bottom - y_top
    for k in range(tiers):
        t0 = k / float(tiers)
        t1 = (k + 1.4) / float(tiers)
        yt = y_top + height * t0 * 0.92
        yb = min(y_bottom, y_top + height * t1)
        w = half_w * (0.25 + 0.75 * min(1.0, t1))
        jag = []
        steps = 9
        for s in range(steps + 1):
            x = cx - w + 2 * w * s / steps
            jag.append((x, yb - (c.rnd.uniform(0, height / tiers * 0.25) if s % 2 else 0)))
        c.poly([(cx, yt)] + jag[::-1][::1][::-1], tones[1])
        c.poly([(cx, yt)] + [(x, y) for x, y in jag if x <= cx + w * 0.05], tones[3])
        c.poly([(cx, yt + 4), (cx - w * 0.55, yb - 6), (cx - w * 0.2, yb - 8)], tones[4])
        c.poly([(cx + w * 0.3, yb - 2), (cx + w, yb), (cx + w * 0.6, yb - height / tiers * 0.3)],
               tones[0])


def rock_shape(c, cx, y_base, w, h, base="stone", moss=False, seed_shape=0):
    tones = ramp(base, 6, spread=0.45)
    pts = []
    n = 14
    for i in range(n + 1):
        a = math.pi + math.pi * i / n
        r = 1.0 + c.rnd.uniform(-0.12, 0.08)
        pts.append((cx + math.cos(a) * w / 2.0 * r, y_base + math.sin(a) * h * r))
    c.poly(pts, tones[1])
    inner = [(cx + (x - cx) * 0.82 - w * 0.06, y_base + (y - y_base) * 0.86 - h * 0.05) for x, y in pts]
    c.poly(inner, tones[3])
    top = [(cx + (x - cx) * 0.5 - w * 0.14, y_base + (y - y_base) * 0.6 - h * 0.28) for x, y in pts]
    c.poly(top, tones[4])
    for _ in range(3):
        x = c.rnd.uniform(cx - w * 0.3, cx + w * 0.3)
        y = c.rnd.uniform(y_base - h * 0.8, y_base - h * 0.2)
        c.line([(x, y), (x + c.rnd.uniform(-8, 8), y + c.rnd.uniform(6, 16))], tones[0])
    c.rect(cx - w / 2.0, y_base - 3, cx + w / 2.0, y_base, tones[0])
    if moss:
        mt = ramp("#6E8C4A", 4)
        for _ in range(int(w / 6)):
            x = c.rnd.uniform(cx - w * 0.42, cx + w * 0.3)
            y = y_base - h * c.rnd.uniform(0.75, 0.98)
            c.blob(x, y, c.rnd.uniform(4, 9), c.rnd.uniform(3, 5), mt)


def boards(c, x0, y0, x1, y1, base="wood", vertical=True, width=12):
    tones = ramp(base, 5, spread=0.45)
    if vertical:
        x = x0
        while x < x1:
            w = min(width, x1 - x)
            col = tones[c.rnd.choice([2, 2, 3, 1])]
            c.rect(x, y0, x + w, y1, col)
            c.rect(x, y0, x + 1, y1, tones[4])
            c.rect(x + w - 1, y0, x + w, y1, tones[0])
            x += w
    else:
        y = y0
        while y < y1:
            h = min(width, y1 - y)
            col = tones[c.rnd.choice([2, 2, 3, 1])]
            c.rect(x0, y, x1, y + h, col)
            c.rect(x0, y, x1, y + 1, tones[4])
            c.rect(x0, y + h - 1, x1, y + h, tones[0])
            y += h


def post(c, x, y0, y1, w, base="wood"):
    c.cylinder(x - w / 2.0, y0, x + w / 2.0, y1, ramp(base, 5, spread=0.45))


def glow(c, cx, cy, r):
    tones = ramp("crystal", 5, spread=0.25)
    c.blob(cx, cy, r, r * 1.2, [tones[1], tones[2], tones[3], tones[4], (255, 252, 236)], (-0.3, -0.5))


def textured(size, recipe_key, rnd):
    """Une matière de tools/hd2d_ground.py (mur, toit) répétée sur size."""
    tile = hd2d_ground.RECIPES[recipe_key]((192, 192) if "materials" in recipe_key else (384, 384), rnd)
    return tile_fill(size, tile)


def fill_mask(c, mask, image):
    c.img.paste(image, (0, 0), mask)


# --- Arbres et végétation -----------------------------------------------------------------------


def _tree(size, rnd, leaf, trunk_w=0.11, crown_ry=0.3, crown_cy=0.4, count=52):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w / 2.0, h, h * 0.42, w * trunk_w, w * trunk_w * 0.55)
    for k in (-1, 1):
        c.line([(w / 2.0, h * 0.62), (w / 2.0 + k * w * 0.18, h * 0.45)], ramp("wood_dark", 4)[1], max(3, int(w * 0.025)))
    crown(c, w / 2.0, h * crown_cy, w * 0.36, h * crown_ry, leaf, count, size=(0.13, 0.22))
    return c.finish(darker(leaf, 0.4))


def tree_autumn(size, rnd):
    return _tree(size, rnd, "leaf_gold")


def tree_autumn_rust(size, rnd):
    return _tree(size, rnd, "leaf_rust")


def tree_autumn_yellow(size, rnd):
    return _tree(size, rnd, "leaf_yellow")


def climbing_tree(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w / 2.0, h, h * 0.4, w * 0.12, w * 0.07)
    wood = ramp("wood_dark", 5)
    # Branches basses : la balançoire pend sous celle de droite.
    c.line([(w * 0.5, h * 0.62), (w * 0.82, h * 0.5)], wood[2], 18)
    c.line([(w * 0.5, h * 0.66), (w * 0.2, h * 0.52)], wood[2], 16)
    rope = ramp("#C9B48A", 3)
    c.line([(w * 0.66, h * 0.57), (w * 0.66, h * 0.86)], rope[1], 2)
    c.line([(w * 0.78, h * 0.52), (w * 0.78, h * 0.86)], rope[1], 2)
    boards(c, w * 0.64, h * 0.86, w * 0.80, h * 0.875, "wood", vertical=False, width=8)
    crown(c, w / 2.0, h * 0.36, w * 0.38, h * 0.27, "leaf_gold", 80, size=(0.12, 0.2))
    for _ in range(14):
        x, y = rnd.uniform(w * 0.2, w * 0.8), rnd.uniform(h * 0.2, h * 0.52)
        c.blob(x, y, rnd.uniform(14, 26), rnd.uniform(12, 20), ramp("leaf_rust", 5)[1:])
    return c.finish(darker("leaf_gold", 0.4))


def lone_tree(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w * 0.48, h, h * 0.35, w * 0.12, w * 0.05, lean=w * 0.08)
    wood = ramp("wood_dark", 5)
    c.line([(w * 0.52, h * 0.55), (w * 0.8, h * 0.38)], wood[2], 9)
    c.line([(w * 0.5, h * 0.48), (w * 0.24, h * 0.3)], wood[2], 8)
    for x, y, r in ((0.3, 0.27, 0.13), (0.62, 0.22, 0.16), (0.8, 0.34, 0.11), (0.45, 0.17, 0.12)):
        crown(c, w * x, h * y, w * r * 1.3, h * r, "leaf_rust", 14)
    return c.finish(darker("leaf_rust", 0.4))


def tree_old_pine(size, rnd, clawed=False):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w / 2.0, h, h * 0.1, w * 0.13, w * 0.04, base="#5A4436")
    pine_tiers(c, w / 2.0, h * 0.02, h * 0.82, w * 0.49, 8)
    moss = ramp("#6E8C4A", 4)
    for _ in range(10):
        c.rect(w * 0.45 + rnd.uniform(-6, 6), h * rnd.uniform(0.84, 0.98), w * 0.45 + 6, h * 0.99, moss[rnd.randint(1, 2)])
    if clawed:
        light = ramp("wood", 5)[4]
        for k in range(3):
            x = w * 0.47 + k * 5
            c.line([(x, h * 0.86), (x + 3, h * 0.93)], light, 2)
    return c.finish(darker("pine", 0.4))


def tree_old_pine_clawed(size, rnd):
    return tree_old_pine(size, rnd, clawed=True)


def tree_pine(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w / 2.0, h, h * 0.2, w * 0.1, w * 0.04, base="#5A4436")
    pine_tiers(c, w / 2.0, h * 0.02, h * 0.86, w * 0.48, 6, base=mix("pine", "grass", 0.15))
    return c.finish(darker("pine", 0.4))


def bush(size, rnd, leaf="leaf_rust", berries=False):
    w, h = size
    c = Canvas(w, h, rnd)
    crown(c, w / 2.0, h * 0.58, w * 0.42, h * 0.4, mix(leaf, "grass", 0.45), 12, size=(0.22, 0.34))
    if berries:
        red = ramp("#C0392B", 4)
        for _ in range(26):
            x, y = rnd.uniform(w * 0.15, w * 0.85), rnd.uniform(h * 0.25, h * 0.85)
            if c.img.getpixel((int(x), int(y)))[3]:
                c.rect(x, y, x + 3, y + 3, red[2])
                c.pixel(x, y, red[3])
    c.rect(w * 0.1, h - 2, w * 0.9, h, ramp("grass", 4)[0])
    return c.finish(darker("grass", 0.35))


def berry_bush(size, rnd):
    return bush(size, rnd, leaf="grass", berries=True)


def _flowers(size, rnd, petal, center, leaf="grass", count=14):
    w, h = size
    c = Canvas(w, h, rnd)
    lt = ramp(leaf, 4)
    for _ in range(count * 2):
        x = rnd.uniform(4, w - 6)
        c.line([(x, h), (x + rnd.uniform(-3, 3), h * rnd.uniform(0.2, 0.6))], lt[rnd.randint(1, 3)], 2)
    pt = ramp(petal, 4)
    for _ in range(count):
        x, y = rnd.uniform(5, w - 7), rnd.uniform(4, h * 0.65)
        for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
            c.rect(x + dx, y + dy, x + dx + 2, y + dy + 2, pt[rnd.randint(2, 3)])
        c.rect(x, y, x + 2, y + 2, center)
    return c.finish(darker(leaf, 0.35))


def myosotis(size, rnd):
    return _flowers(size, rnd, "myosotis", "#F2D06B", count=9)


def flower_bed(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    soil = ramp("#6E5A40", 4)
    c.rect(0, h - 10, w, h, soil[1])
    c.rect(0, h - 10, w, h - 8, soil[3])
    img = _flowers((w, h - 6), rnd, "#C8653A", "#F2D06B", count=10)
    c.img.paste(img, (0, 0), img)
    img2 = _flowers((w, h - 6), rnd, "#8E6CC9", "#F2D06B", count=6)
    c.img.paste(img2, (0, 0), img2)
    return c.finish(darker("wood_dark", 0.5))


def reeds(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp("reed", 5)
    for _ in range(40):
        x = rnd.uniform(w * 0.15, w * 0.85)
        top = h * rnd.uniform(0.05, 0.4)
        bend = rnd.uniform(-10, 10)
        c.line([(x, h), (x + bend * 0.5, (h + top) / 2), (x + bend, top)], tones[rnd.randint(1, 4)], 2)
        if rnd.random() < 0.25:
            c.rect(x + bend - 2, top - 10, x + bend + 2, top + 2, ramp("#6E4A2E", 3)[1])
    return c.finish(darker("reed", 0.4))


def tall_grass(size, rnd, base="grass_gold"):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(base, 5)
    for _ in range(30):
        x = rnd.uniform(w * 0.1, w * 0.9)
        top = h * rnd.uniform(0.0, 0.5)
        c.line([(x, h), (x + rnd.uniform(4, 12), top)], tones[rnd.randint(1, 4)], 2)
    return c.finish(darker(base, 0.4))


def grass_tuft(size, rnd):
    return tall_grass(size, rnd, base="grass_dry")


def mushroom(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    red = ramp("#C0392B", 5)
    stem = ramp("#EDE3CF", 4)
    for x, s in ((0.3, 1.0), (0.62, 0.8), (0.82, 0.6)):
        cx = w * x
        c.rect(cx - 3 * s, h - 16 * s, cx + 3 * s, h, stem[2])
        c.blob(cx, h - 16 * s, 10 * s, 7 * s, red[1:])
        for _ in range(3):
            c.rect(cx + rnd.uniform(-6, 4) * s, h - 19 * s + rnd.uniform(-2, 3), cx + rnd.uniform(-6, 4) * s + 2,
                   h - 17 * s + rnd.uniform(-2, 3), stem[3])
    return c.finish(darker("#C0392B", 0.4))


# --- Rochers ------------------------------------------------------------------------------------


def _rock(size, rnd, base="stone", moss=False, hollow=False):
    w, h = size
    c = Canvas(w, h, rnd)
    rock_shape(c, w / 2.0, h, w * 0.96, h * 0.97, base, moss)
    if hollow:
        cav = Image.new("L", (w, h), 0)
        ImageDraw.Draw(cav).ellipse((w * 0.28, h * 0.62, w * 0.72, h * 1.1), fill=255)
        c.img.paste(Image.new("RGBA", (w, h), rgba(ramp(base, 5)[0])), (0, 0), cav)
        inner = Image.new("L", (w, h), 0)
        ImageDraw.Draw(inner).ellipse((w * 0.34, h * 0.72, w * 0.68, h * 1.14), fill=255)
        c.img.paste(Image.new("RGBA", (w, h), (0, 0, 0, 0)), (0, 0), inner)
    return c.finish(darker(base, 0.35))


def rock(size, rnd):
    return _rock(size, rnd)


def mossy_rock(size, rnd):
    return _rock(size, rnd, mix("stone", "stone_dark", 0.4), moss=True)


def bear_rock(size, rnd):
    return _rock(size, rnd, mix("stone", "stone_dark", 0.5), moss=True)


def wind_rock_a(size, rnd):
    return _rock(size, rnd, "stone", hollow=True)


def wind_rock_b(size, rnd):
    return _rock(size, rnd, mix("stone", "sand", 0.3), hollow=True)


def wind_rock_c(size, rnd):
    return _rock(size, rnd, mix("stone", "sand", 0.2))


def ring_stone(size, rnd):
    return _rock(size, rnd, "stone_dark")


def floating_rock(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(mix("stone", "#7A6A80", 0.3), 5)
    c.poly([(w * 0.08, h * 0.35), (w * 0.92, h * 0.32), (w * 0.62, h * 0.95), (w * 0.5, h), (w * 0.4, h * 0.9)], tones[1])
    c.poly([(w * 0.1, h * 0.35), (w * 0.6, h * 0.34), (w * 0.45, h * 0.86)], tones[3])
    c.poly([(w * 0.08, h * 0.35), (w * 0.92, h * 0.32), (w * 0.84, h * 0.24), (w * 0.2, h * 0.24)], ramp("grass", 4)[2])
    root = ramp("#5C4030", 3)
    for _ in range(6):
        x = rnd.uniform(w * 0.3, w * 0.7)
        c.line([(x, h * 0.6), (x + rnd.uniform(-8, 8), h * 0.98)], root[1], 2)
    return c.finish(darker("stone_dark", 0.4))


# --- Bois et objets de l'entrepôt ----------------------------------------------------------------


def palisade(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    logs = 7
    lw = w / float(logs)
    for k in range(logs):
        top = h * rnd.uniform(0.0, 0.1)
        x0 = k * lw
        tones = ramp(mix("wood", "wood_dark", rnd.uniform(0.3, 0.7)), 5)
        c.cylinder(x0 + 1, top + lw * 0.6, x0 + lw - 1, h, tones)
        c.poly([(x0 + 1, top + lw * 0.6), (x0 + lw / 2.0, top), (x0 + lw - 1, top + lw * 0.6)], tones[3])
        c.poly([(x0 + lw / 2.0, top), (x0 + lw - 1, top + lw * 0.6), (x0 + lw / 2.0, top + lw * 0.6)], tones[1])
    rope = ramp("#B49870", 4)
    for y in (h * 0.3, h * 0.72):
        c.rect(0, y, w, y + 4, rope[2])
        c.rect(0, y + 3, w, y + 4, rope[0])
    return c.finish(darker("wood_dark", 0.5))


def palisade_gate(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("wood_dark", 5)
    # Battants ouverts, rabattus contre les poteaux (vus par la tranche, en biais).
    boards(c, w * 0.12, h * 0.22, w * 0.24, h, "wood", width=10)
    boards(c, w * 0.76, h * 0.22, w * 0.88, h, "wood", width=10)
    post(c, w * 0.1, h * 0.08, h, w * 0.08, "wood_dark")
    post(c, w * 0.9, h * 0.08, h, w * 0.08, "wood_dark")
    c.cylinder(w * 0.02, h * 0.07, w * 0.98, h * 0.15, wood, vertical=False)
    c.rect(w * 0.48, h * 0.15, w * 0.52, h * 0.22, ramp("iron", 4)[0])
    c.rect(w * 0.45, h * 0.22, w * 0.55, h * 0.36, ramp("iron", 4)[1])
    glow(c, w * 0.5, h * 0.29, w * 0.035)
    return c.finish(darker("wood_dark", 0.5))


def crystal_lamp(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("iron", 5, spread=0.5)
    c.rect(w * 0.25, h - 10, w * 0.75, h, iron[1])
    c.cylinder(w * 0.4, h * 0.2, w * 0.6, h - 8, [mix(x, (40, 40, 50), 0.4) for x in iron])
    c.rect(w * 0.18, h * 0.06, w * 0.82, h * 0.1, iron[1])
    c.rect(w * 0.22, h * 0.21, w * 0.78, h * 0.24, iron[1])
    glow(c, w * 0.5, h * 0.155, w * 0.22)
    for x in (0.22, 0.75):
        c.rect(w * x, h * 0.08, w * x + 3, h * 0.23, iron[0])
    c.poly([(w * 0.3, h * 0.06), (w * 0.5, 0), (w * 0.7, h * 0.06)], iron[2])
    return c.finish(darker("iron", 0.4))


def well(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = textured((w, h), "buildings/materials/wall_stone", rnd)
    body = Image.new("L", (w, h), 0)
    bd = ImageDraw.Draw(body)
    bd.rectangle((w * 0.06, h * 0.62, w * 0.94, h), fill=255)
    bd.ellipse((w * 0.06, h * 0.55, w * 0.94, h * 0.69), fill=255)
    c.img.paste(stone, (0, 0), body)
    tones = ramp("stone", 5)
    c.ellipse(w * 0.5, h * 0.62, w * 0.44, h * 0.07, tones[4])
    c.ellipse(w * 0.5, h * 0.625, w * 0.36, h * 0.05, ramp("marsh", 4)[0])
    for x in (0.12, 0.88):
        post(c, w * x, h * 0.2, h * 0.62, 12, "wood")
    c.cylinder(w * 0.1, h * 0.26, w * 0.9, h * 0.29, ramp("wood_dark", 5), vertical=False)
    roof = ramp("#7A5A40", 5)
    c.poly([(w * 0.0, h * 0.24), (w * 0.5, h * 0.02), (w * 1.0, h * 0.24)], roof[1])
    c.poly([(w * 0.04, h * 0.22), (w * 0.5, h * 0.04), (w * 0.5, h * 0.22)], roof[3])
    for k in range(1, 5):
        y = h * (0.04 + 0.05 * k)
        c.line([(w * 0.5 - (y - h * 0.02) * 2.1, y), (w * 0.5 + (y - h * 0.02) * 2.1, y)], roof[0])
    c.line([(w * 0.5, h * 0.29), (w * 0.5, h * 0.45)], ramp("#C9B48A", 3)[1], 2)
    c.cylinder(w * 0.44, h * 0.45, w * 0.56, h * 0.53, ramp("wood", 5))
    return c.finish(darker("stone_dark", 0.45))


def bench(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("wood", 5)
    for x in (0.12, 0.88):
        c.rect(w * x - 4, h * 0.5, w * x + 4, h, wood[1])
    boards(c, 0, h * 0.45, w, h * 0.62, "wood", vertical=False, width=6)
    boards(c, w * 0.04, 0, w * 0.96, h * 0.3, "wood", vertical=False, width=8)
    for x in (0.12, 0.88):
        c.rect(w * x - 3, 0, w * x + 3, h * 0.5, wood[2])
    return c.finish(darker("wood_dark", 0.5))


def laundry_line(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (12, w - 12):
        post(c, x, 6, h, 10, "wood")
    rope = ramp("#C9B48A", 3)
    pts = [(12 + (w - 24) * t / 20.0, 16 + math.sin(math.pi * t / 20.0) * 14) for t in range(21)]
    c.line(pts, rope[1], 2)
    cloth = ramp("#F2EEE6", 5, spread=0.25)
    for k in range(3):
        x0 = w * (0.12 + 0.27 * k)
        x1 = x0 + w * 0.22
        y0 = 18 + math.sin(math.pi * ((x0 + x1) / 2 - 12) / (w - 24)) * 14
        wave = [(x1 - (x1 - x0) * s / 8.0, y0 + h * 0.55 + math.sin(s * 1.3 + k) * 6) for s in range(9)]
        c.poly([(x0, y0), (x1, y0)] + wave, cloth[3])
        c.poly([(x0 + (x1 - x0) * 0.6, y0), (x1, y0)] + wave[:4], cloth[1])
        c.rect(x0 + 4, y0 - 3, x0 + 7, y0 + 3, ramp("wood", 3)[1])
        c.rect(x1 - 7, y0 - 3, x1 - 4, y0 + 3, ramp("wood", 3)[1])
    return c.finish(darker("wood_dark", 0.5))


def vegetable_patch(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    soil = ramp("#6E5A40", 5)
    c.rect(0, h * 0.62, w, h, soil[1])
    c.rect(0, h * 0.62, w, h * 0.68, soil[3])
    for k in range(9):
        x = w * (0.06 + 0.11 * k)
        if k % 3 == 1:
            c.blob(x, h * 0.66, 18, 14, ramp("#D67A2A", 5)[1:])
            c.rect(x - 1, h * 0.46, x + 2, h * 0.52, ramp("grass", 4)[1])
        else:
            c.blob(x, h * 0.6, 20, 16, ramp("#7FA05A", 5)[1:])
    for k in range(6):
        x = w * (0.1 + 0.16 * k)
        c.rect(x, h * 0.05, x + 3, h * 0.66, ramp("wood", 4)[2])
    return c.finish(darker("#6E5A40", 0.5))


def crate(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    boards(c, 0, h * 0.1, w, h, "wood", vertical=True, width=13)
    wood = ramp("wood_dark", 5)
    c.rect(0, h * 0.1, w, h * 0.2, wood[2])
    c.rect(0, h - 8, w, h, wood[2])
    c.line([(4, h - 8), (w - 4, h * 0.2)], wood[2], 6)
    c.poly([(0, h * 0.1), (w * 0.15, 0), (w, 0), (w, h * 0.1)], ramp("wood", 5)[4])
    return c.finish(darker("wood_dark", 0.5))


def ball(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    c.blob(w / 2.0, h / 2.0 + 1, w * 0.44, h * 0.44, ramp("#A0643A", 5)[0:4])
    c.line([(w * 0.3, h * 0.2), (w * 0.45, h * 0.9)], ramp("#A0643A", 5)[0], 1)
    return c.finish(darker("#A0643A", 0.4))


def stick_rack(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("wood", 5)
    c.line([(w * 0.1, h), (w * 0.3, h * 0.2)], wood[1], 6)
    c.line([(w * 0.9, h), (w * 0.7, h * 0.2)], wood[1], 6)
    c.rect(w * 0.15, h * 0.32, w * 0.85, h * 0.37, wood[2])
    for k in range(5):
        x = w * (0.22 + 0.14 * k)
        c.line([(x, h), (x + 8, h * 0.08)], ramp("#C9A06A", 4)[rnd.randint(1, 3)], 4)
    return c.finish(darker("wood_dark", 0.5))


def _goal(size, rnd, rag):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (0.06, 0.94):
        post(c, w * x, h * 0.05, h, 12, "wood")
    c.cylinder(w * 0.03, h * 0.05, w * 0.97, h * 0.12, ramp("wood", 5), vertical=False)
    cloth = ramp(rag, 4, spread=0.3)
    for k in range(5):
        x = w * (0.15 + 0.17 * k)
        c.poly([(x, h * 0.1), (x + 18, h * 0.1), (x + 14, h * 0.32 + rnd.uniform(0, 12)), (x + 3, h * 0.28)], cloth[rnd.randint(1, 3)])
    return c.finish(darker("wood_dark", 0.5))


def play_goal(size, rnd):
    return _goal(size, rnd, "#F2EEE6")


def play_goal_red(size, rnd):
    return _goal(size, rnd, "#B5443A")


# --- Couchant -----------------------------------------------------------------------------------


def _ruin_wall(c, x0, x1, y_base, heights, rnd):
    """Mur de pierre au sommet effondré : profil en marches, moellons."""
    w = int(x1 - x0)
    stone = textured((c.w, c.h), "buildings/materials/wall_stone", rnd)
    mask = Image.new("L", (c.w, c.h), 0)
    pts = [(x0, y_base)]
    n = len(heights)
    for i, hh in enumerate(heights):
        xa = x0 + w * i / n
        xb = x0 + w * (i + 1) / n
        pts += [(xa, y_base - hh), (xb, y_base - hh)]
    pts.append((x1, y_base))
    ImageDraw.Draw(mask).polygon(pts, fill=255)
    c.img.paste(stone, (0, 0), mask)
    tones = ramp("stone", 5)
    for i, hh in enumerate(heights):
        xa = x0 + w * i / n
        xb = x0 + w * (i + 1) / n
        c.rect(xa, y_base - hh, xb, y_base - hh + 3, tones[4])


def vigil_bell(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (0.1, 0.9):
        post(c, w * x, h * 0.12, h, 12, "wood_dark")
    c.cylinder(0, h * 0.1, w, h * 0.17, ramp("wood_dark", 5), vertical=False)
    c.poly([(0, h * 0.11), (w * 0.5, 0), (w, h * 0.11)], ramp("#7A5A40", 5)[2])
    bronze = ramp("#B07A3A", 6, spread=0.5)
    c.rect(w * 0.48, h * 0.17, w * 0.52, h * 0.24, bronze[0])
    bell = [(w * 0.38, h * 0.24), (w * 0.62, h * 0.24), (w * 0.68, h * 0.5), (w * 0.76, h * 0.58),
            (w * 0.24, h * 0.58), (w * 0.32, h * 0.5)]
    c.poly(bell, bronze[2])
    c.poly([(w * 0.38, h * 0.24), (w * 0.47, h * 0.24), (w * 0.42, h * 0.56), (w * 0.28, h * 0.57), (w * 0.33, h * 0.5)], bronze[4])
    c.rect(w * 0.24, h * 0.56, w * 0.76, h * 0.6, bronze[1])
    c.line([(w * 0.5, h * 0.6), (w * 0.52, h * 0.85)], ramp("#C9B48A", 3)[1], 2)
    return c.finish(darker("wood_dark", 0.5))


def watch_post_ruin(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _ruin_wall(c, 0, w * 0.72, h, [h * 0.95, h * 0.82, h * 0.6, h * 0.66, h * 0.4, h * 0.3], rnd)
    steps = ramp("stone", 5)
    for k in range(5):
        x = w * (0.72 + 0.055 * k)
        c.rect(x, h - h * (0.45 - 0.08 * k), w * 0.99, h, steps[2 + (k % 2)])
        c.rect(x, h - h * (0.45 - 0.08 * k), w * 0.99, h - h * (0.45 - 0.08 * k) + 3, steps[4])
    for _ in range(6):
        rock_shape(c, rnd.uniform(w * 0.05, w * 0.95), h, rnd.uniform(20, 46), rnd.uniform(10, 22), "stone")
    return c.finish(darker("stone_dark", 0.45))


def ruined_wall(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _ruin_wall(c, 0, w, h, [h * 0.6, h * 0.92, h * 0.98, h * 0.7, h * 0.45, h * 0.62], rnd)
    for _ in range(3):
        rock_shape(c, rnd.uniform(w * 0.05, w * 0.95), h, rnd.uniform(18, 36), rnd.uniform(8, 18), "stone")
    return c.finish(darker("stone_dark", 0.45))


def edge_parapet(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _ruin_wall(c, 0, w, h, [h * 0.9, h * 0.98, h * 0.7, h * 0.95], rnd)
    return c.finish(darker("stone_dark", 0.45))


def signal_pillar(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _ruin_wall(c, w * 0.1, w * 0.9, h, [h * 0.78], rnd)
    iron = ramp("iron", 5)
    c.rect(w * 0.05, h * 0.2, w * 0.95, h * 0.23, iron[1])
    for x in (0.12, 0.38, 0.62, 0.86):
        c.rect(w * x - 2, h * 0.05, w * x + 2, h * 0.21, iron[0])
    c.rect(w * 0.05, h * 0.04, w * 0.95, h * 0.07, iron[1])
    c.poly([(w * 0.1, h * 0.04), (w * 0.5, 0), (w * 0.9, h * 0.04)], iron[2])
    return c.finish(darker("stone_dark", 0.45))


def garde_pennant(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    post(c, w * 0.12, h * 0.02, h, 7, "wood_dark")
    red = ramp("pennant", 5)
    pts = [(w * 0.15, h * 0.06)] + [(w * 0.15 + w * 0.82 * s / 6.0, h * 0.06 + math.sin(s * 1.1) * 5) for s in range(1, 7)]
    bottom = [(w * 0.15 + w * 0.82 * s / 6.0, h * 0.3 + math.sin(s * 1.1 + 0.6) * 6) for s in range(6, -1, -1)]
    c.poly(pts + bottom, red[2])
    c.poly(pts[:3] + bottom[-3:], red[3])
    c.rect(w * 0.15, h * 0.14, w * 0.9, h * 0.16, ramp("brass", 3)[2])
    return c.finish(darker("pennant", 0.4))


def fallen_lantern(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("iron", 5)
    c.rect(w * 0.1, h * 0.35, w * 0.9, h, iron[1])
    c.rect(w * 0.18, h * 0.45, w * 0.82, h * 0.9, ramp("#8FA8B0", 4)[1])
    brass = ramp("brass", 4)
    for x, r in ((0.35, 9), (0.6, 7)):
        c.blob(w * x, h * 0.68, r, r, brass)
        c.ellipse(w * x, h * 0.68, 2, 2, brass[0])
    return c.finish(darker("iron", 0.4))


# --- Port ---------------------------------------------------------------------------------------


def signpost(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    post(c, w * 0.5, h * 0.05, h, 12, "wood")
    red = ramp("#B5443A", 5)
    c.poly([(w * 0.35, h * 0.14), (w * 0.88, h * 0.14), (w * 1.0, h * 0.22), (w * 0.88, h * 0.3), (w * 0.35, h * 0.3)], red[2])
    c.poly([(w * 0.65, h * 0.36), (w * 0.12, h * 0.36), (w * 0.0, h * 0.44), (w * 0.12, h * 0.52), (w * 0.65, h * 0.52)], red[2])
    for y in (0.15, 0.37):
        c.rect(w * 0.12, h * y, w * 0.88, h * y + 2, red[4])
    return c.finish(darker("wood_dark", 0.5))


def _awning_stall(size, rnd, goods):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (0.06, 0.94):
        post(c, w * x, h * 0.12, h, 8, "wood")
    boards(c, w * 0.04, h * 0.62, w * 0.96, h * 0.7, "wood", vertical=False, width=8)
    boards(c, w * 0.08, h * 0.7, w * 0.92, h, "wood_dark", vertical=True, width=16)
    goods(c, w, h)
    cloth = ramp("#E2D3B0", 5, spread=0.3)
    c.poly([(0, h * 0.18), (w * 0.08, 0), (w * 0.92, 0), (w, h * 0.18)], cloth[3])
    for k in range(8):
        x = w * k / 8.0
        c.poly([(x, h * 0.18), (x + w / 8.0, h * 0.18), (x + w / 16.0, h * 0.26)], cloth[2 if k % 2 else 3])
    c.rect(0, h * 0.17, w, h * 0.19, cloth[1])
    return c.finish(darker("wood_dark", 0.5))


def market_stall(size, rnd):
    def goods(c, w, h):
        for k in range(4):
            x = w * (0.18 + 0.2 * k)
            c.blob(x, h * 0.6, 18, 9, ramp("#B08A50", 4))
            for _ in range(5):
                c.blob(x + rnd.uniform(-10, 10), h * 0.56 + rnd.uniform(-4, 2), 4, 5,
                       ramp("#F2EADA" if k % 2 else "#C8653A", 3))
    return _awning_stall(size, rnd, goods)


def market_stall_veg(size, rnd):
    def goods(c, w, h):
        for _ in range(16):
            col = rnd.choice(["#7FA05A", "#D67A2A", "#B5443A", "#E0C050"])
            c.blob(rnd.uniform(w * 0.12, w * 0.88), h * 0.58 + rnd.uniform(-4, 4), rnd.uniform(6, 11), rnd.uniform(5, 9), ramp(col, 4))
    return _awning_stall(size, rnd, goods)


def snack_stall(size, rnd):
    def goods(c, w, h):
        iron = ramp("iron", 4)
        c.rect(w * 0.6, h * 0.5, w * 0.9, h * 0.62, iron[1])
        c.blob(w * 0.75, h * 0.52, 18, 6, ["#7A2A1A", "#C8501E", "#F09A3A", "#FFE08A"])
        c.blob(w * 0.3, h * 0.56, 10, 9, ramp("#E0C050", 4))
    return _awning_stall(size, rnd, goods)


def cargo_crane(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("iron", 5)
    c.rect(w * 0.15, h * 0.9, w * 0.55, h, iron[1])
    post(c, w * 0.35, h * 0.08, h * 0.92, 18, "wood_dark")
    c.line([(w * 0.35, h * 0.12), (w * 0.95, h * 0.08)], ramp("wood_dark", 4)[2], 12)
    c.line([(w * 0.35, h * 0.35), (w * 0.85, h * 0.1)], iron[1], 4)
    c.line([(w * 0.9, h * 0.1), (w * 0.9, h * 0.62)], ramp("#C9B48A", 3)[1], 2)
    c.rect(w * 0.84, h * 0.62, w * 0.96, h * 0.66, iron[0])
    box = Canvas(int(w * 0.24), int(h * 0.12), rnd)
    box.img = crate((int(w * 0.24), int(h * 0.12)), rnd)
    c.img.paste(box.img, (int(w * 0.78), int(h * 0.66)), box.img)
    c.blob(w * 0.35, h * 0.82, 14, 14, ramp("brass", 4))
    return c.finish(darker("iron", 0.4))


def crates_barrels(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    small = crate((int(w * 0.42), int(h * 0.55)), rnd)
    c.img.paste(small, (0, h - small.height), small)
    top = crate((int(w * 0.36), int(h * 0.45)), rnd)
    c.img.paste(top, (int(w * 0.04), h - small.height - top.height + 4), top)
    for x in (0.58, 0.82):
        tones = ramp("#8A5A3A", 5)
        c.cylinder(w * x - 18, h * 0.42, w * x + 18, h, tones)
        for y in (0.5, 0.92):
            c.rect(w * x - 18, h * y, w * x + 18, h * y + 3, ramp("iron", 4)[0])
        c.ellipse(w * x, h * 0.42, 18, 5, tones[3])
    return c.finish(darker("wood_dark", 0.5))


def scrap_pile(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for _ in range(14):
        base = rnd.choice(["iron", "#8A5A3A", "brass", "iron"])
        rock_shape(c, rnd.uniform(w * 0.15, w * 0.85), h, rnd.uniform(24, 60), rnd.uniform(14, 40), base)
    for _ in range(3):
        x, y = rnd.uniform(w * 0.2, w * 0.8), rnd.uniform(h * 0.4, h * 0.8)
        c.blob(x, y, 9, 9, ramp("brass", 4))
        c.ellipse(x, y, 3, 3, ramp("brass", 4)[0])
    return c.finish(darker("iron", 0.4))


def mooring_arm(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("iron", 5)
    copper = ramp("#B0703A", 5)
    c.rect(w * 0.2, h * 0.85, w * 0.6, h, iron[1])
    c.line([(w * 0.4, h * 0.88), (w * 0.4, h * 0.4)], iron[2], 16)
    c.line([(w * 0.4, h * 0.42), (w * 0.85, h * 0.12)], copper[2], 12)
    c.blob(w * 0.4, h * 0.42, 12, 12, copper)
    c.poly([(w * 0.82, h * 0.08), (w * 0.98, h * 0.12), (w * 0.9, h * 0.22)], iron[1])
    return c.finish(darker("iron", 0.4))


def gangway(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    boards(c, 0, h * 0.62, w, h * 0.8, "wood", vertical=True, width=12)
    iron = ramp("iron", 5)
    c.rect(0, h * 0.8, w, h, iron[1])
    for x in (0.04, 0.5, 0.96):
        c.rect(w * x - 3, 0, w * x + 3, h * 0.62, iron[2])
    c.rect(0, 0, w, 5, iron[3])
    c.rect(0, h * 0.3, w, h * 0.3 + 3, iron[1])
    return c.finish(darker("iron", 0.4))


def edge_railing(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("iron", 5)
    for x in (0.04, 0.5, 0.96):
        c.cylinder(w * x - 4, 0, w * x + 4, h, iron)
    for y in (0.05, 0.45):
        c.rect(0, h * y, w, h * y + 6, iron[3])
        c.rect(0, h * y + 5, w, h * y + 7, iron[0])
        for x in range(8, w, 16):
            c.pixel(x, h * y + 2, iron[4])
    return c.finish(darker("iron", 0.45))


def bollard(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("iron", 5)
    c.cylinder(w * 0.15, h * 0.25, w * 0.85, h, iron)
    c.ellipse(w * 0.5, h * 0.25, w * 0.45, h * 0.12, iron[3])
    return c.finish(darker("iron", 0.45))


def wind_sock(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    post(c, w * 0.15, h * 0.03, h, 7, "iron")
    for k in range(4):
        x0 = w * (0.18 + 0.19 * k)
        col = "#C8423B" if k % 2 == 0 else "#F2EEE6"
        sag = k * 2
        c.poly([(x0, h * 0.05 + sag), (x0 + w * 0.19, h * 0.06 + sag + 2), (x0 + w * 0.19, h * 0.13 + sag), (x0, h * 0.14 + sag)],
               ramp(col, 4)[2])
    return c.finish(darker("iron", 0.45))


def lookout(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#8A6A4C", 5)
    for x in (0.08, 0.92):
        post(c, w * x, h * 0.3, h, 14, "#8A6A4C")
    boards(c, w * 0.04, h * 0.62, w * 0.96, h * 0.68, "#8A6A4C", vertical=False, width=6)
    for k in range(9):
        x = w * (0.08 + 0.105 * k)
        c.rect(x - 2, h * 0.42, x + 2, h * 0.62, wood[2])
    c.rect(w * 0.04, h * 0.42, w * 0.96, h * 0.45, wood[3])
    for x in (0.2, 0.8):
        c.line([(w * x, h * 0.68), (w * (x + (0.12 if x < 0.5 else -0.12)), h)], wood[1], 6)
    roof = ramp("#6A5A4A", 5)
    c.poly([(0, h * 0.32), (w * 0.5, 0), (w, h * 0.32)], roof[1])
    c.poly([(w * 0.03, h * 0.31), (w * 0.5, h * 0.02), (w * 0.5, h * 0.31)], roof[3])
    c.rect(0, h * 0.3, w, h * 0.33, roof[0])
    return c.finish(darker("wood_dark", 0.5))


def airship_ferry(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    c.blob(w * 0.5, h * 0.32, w * 0.42, h * 0.28, ramp("#D8C8A0", 5))
    for k in range(1, 6):
        x = w * (0.1 + 0.16 * k)
        c.line([(x, h * 0.08), (x, h * 0.56)], ramp("#D8C8A0", 5)[1], 1)
    rope = ramp("#8A7A5A", 3)
    for x in (0.3, 0.45, 0.6, 0.72):
        c.line([(w * x, h * 0.55), (w * (x * 0.9 + 0.05), h * 0.72)], rope[1], 1)
    hull = ramp("#8A5A3A", 5)
    c.poly([(w * 0.2, h * 0.72), (w * 0.82, h * 0.72), (w * 0.72, h), (w * 0.3, h)], hull[2])
    c.rect(w * 0.2, h * 0.72, w * 0.82, h * 0.76, ramp("#B0703A", 4)[3])
    for x in (0.12, 0.9):
        c.rect(w * x - 2, h * 0.5, w * x + 2, h * 0.7, ramp("iron", 3)[1])
        c.ellipse(w * x, h * 0.5, w * 0.06, h * 0.02, ramp("iron", 3)[2])
    return c.finish(darker("#8A5A3A", 0.4))


def airship_barocupot(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    hull = ramp("#3E4656", 5)
    c.poly([(w * 0.05, h * 0.45), (w * 0.2, h * 0.3), (w * 0.85, h * 0.3), (w * 0.98, h * 0.5),
            (w * 0.82, h), (w * 0.18, h)], hull[1])
    c.poly([(w * 0.06, h * 0.45), (w * 0.2, h * 0.32), (w * 0.85, h * 0.32), (w * 0.95, h * 0.45)], hull[3])
    c.rect(w * 0.42, h * 0.55, w * 0.55, h * 0.75, hull[0])
    for x in (0.3, 0.7):
        c.rect(w * x - 3, h * 0.1, w * x + 3, h * 0.3, ramp("iron", 3)[1])
        c.poly([(w * x - w * 0.12, h * 0.1), (w * x + w * 0.12, h * 0.08), (w * x + w * 0.12, h * 0.11), (w * x - w * 0.12, h * 0.13)],
               ramp("iron", 4)[2])
    for k in range(6):
        c.rect(w * (0.25 + 0.08 * k), h * 0.4, w * (0.25 + 0.08 * k) + 8, h * 0.44, ramp("crystal", 3)[1])
    c.rect(w * 0.15, h * 0.58, w * 0.85, h * 0.6, ramp("pennant", 3)[1])
    return c.finish(darker("#3E4656", 0.4))


# --- Bâtiments : panneaux et façades -------------------------------------------------------------


def window(c, x, y, w, h, frame="wood_dark", shutters=None, round_top=False):
    wood = ramp(frame, 5)
    glass = ramp("crystal", 5, spread=0.4)
    c.rect(x - 3, y - 3, x + w + 3, y + h + 5, wood[1])
    c.rect(x, y, x + w, y + h, glass[2])
    c.rect(x, y, x + w, y + h * 0.4, glass[3])
    c.rect(x + 2, y + 2, x + w * 0.4, y + h * 0.3, glass[4])
    c.rect(x + w / 2.0 - 1, y, x + w / 2.0 + 1, y + h, wood[2])
    c.rect(x, y + h / 2.0 - 1, x + w, y + h / 2.0 + 1, wood[2])
    c.rect(x - 5, y + h + 3, x + w + 5, y + h + 7, wood[3])
    if shutters:
        sh = ramp(shutters, 4)
        boards(c, x - 3 - w * 0.45, y - 2, x - 3, y + h + 3, shutters, width=6)
        boards(c, x + w + 3, y - 2, x + w + 3 + w * 0.45, y + h + 3, shutters, width=6)
        del sh


def door(c, x, y, w, h, base="wood_dark", double=False, metal=False):
    wood = ramp(base, 5)
    c.rect(x - 4, y - 4, x + w + 4, y + h, ramp("stone_dark", 4)[2])
    if metal:
        c.rect(x, y, x + w, y + h, ramp("iron", 5)[2])
        for yy in range(int(y) + 6, int(y + h), 14):
            for xx in (x + 4, x + w - 7):
                c.rect(xx, yy, xx + 3, yy + 3, ramp("iron", 5)[0])
    else:
        boards(c, x, y, x + w, y + h, base, width=8 if w < 60 else 12)
    if double:
        c.rect(x + w / 2.0 - 1, y, x + w / 2.0 + 1, y + h, wood[0])
    c.rect(x + w * (0.4 if double else 0.78), y + h * 0.5, x + w * (0.4 if double else 0.78) + 4, y + h * 0.5 + 4,
           ramp("brass", 3)[2])


def facade_base(size, rnd, wall_key, kind, wall_h, plinth=0, roof_base="slate"):
    """Mur (matière répétée), soubassement de pierre, bordure du toit (long) ou pignon."""
    w, h = size
    c = Canvas(w, h, rnd)
    wall = textured(size, wall_key, rnd)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    roof = ramp(roof_base, 5)
    eave = 14
    if kind == "long":
        md.rectangle((0, eave, w, h), fill=255)
        c.img.paste(wall, (0, 0), mask)
        c.rect(0, 0, w, eave, roof[1])
        c.rect(0, 0, w, 3, roof[3])
        c.rect(0, eave - 3, w, eave, ramp("wood_dark", 4)[0])
    else:
        top = h - wall_h
        md.polygon([(0, h), (0, top), (w / 2.0, 0), (w, top), (w, h)], fill=255)
        c.img.paste(wall, (0, 0), mask)
        board = ramp("wood_dark", 5)
        c.line([(0, top + 6), (w / 2.0, 0)], board[1], 12)
        c.line([(w, top + 6), (w / 2.0, 0)], board[1], 12)
        c.line([(0, top + 1), (w / 2.0, -2)], roof[2], 4)
        c.line([(w, top + 1), (w / 2.0, -2)], roof[2], 4)
    if plinth:
        stone = textured(size, "buildings/materials/wall_stone", rnd)
        c.img.paste(stone.crop((0, 0, w, plinth)), (0, h - plinth))
        c.rect(0, h - plinth, w, h - plinth + 3, ramp("stone", 4)[3])
    # Pied du mur un peu plus sombre (contact avec le sol).
    shade = Image.new("RGBA", (w, 6), (30, 24, 36, 70))
    c.img.alpha_composite(shade, (0, h - 6))
    return c


def _finish_facade(c):
    img = c.img
    a = img.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    img.putalpha(a)
    return img


def warehouse_main(size, rnd):
    w, h = size
    c = facade_base(size, rnd, "buildings/materials/wall_planks", "long", h, plinth=72)
    for k in range(6):
        window(c, w * (0.06 + 0.16 * k), h * 0.16, 56, 64)
    for k, x in enumerate((0.06, 0.22, 0.66, 0.82)):
        window(c, w * x, h * 0.55, 56, 64, shutters="wood" if k == 3 else None)
    door(c, w * 0.5 - 60, h * 0.52, 120, h * 0.48, double=True)
    board = ramp("#D9D0B8", 4)
    for k in range(3):
        c.rect(w * 0.42 - 26 + k * 10, h * 0.58 + k * 6, w * 0.42 - 8 + k * 10, h * 0.58 + 22 + k * 6, board[2 + k % 2])
    c.rect(w * 0.6, h * 0.62, w * 0.6 + 26, h * 0.62 + 18, ramp("brass", 4)[1])
    window(c, w * 0.92, h * 0.58, 70, 50)
    return _finish_facade(c)


def warehouse_wing(size, rnd):
    w, h = size
    wall_h = round(3.5 * 96)
    c = facade_base(size, rnd, "buildings/materials/wall_planks", "pignon", wall_h, plinth=48)
    door(c, w * 0.5 - 44, h - 230, 88, 230 - 0)
    window(c, w * 0.12, h - 220, 56, 64)
    window(c, w * 0.76, h - 220, 56, 64)
    glass = ramp("crystal", 4)
    c.blob(w * 0.5, h - wall_h - 70, 26, 26, [ramp("wood_dark", 4)[0], glass[1], glass[2], glass[3]])
    return _finish_facade(c)


def warehouse_porch(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    steps = ramp("stone", 5)
    for k in range(3):
        c.rect(w * (0.12 + 0.04 * k), h - 18 * (k + 1), w * (0.88 - 0.04 * k), h - 18 * k, steps[2 + k % 2])
        c.rect(w * (0.12 + 0.04 * k), h - 18 * (k + 1), w * (0.88 - 0.04 * k), h - 18 * (k + 1) + 3, steps[4])
    for x in (0.08, 0.92):
        post(c, w * x, h * 0.3, h, 16, "wood_dark")
    slate = textured((w, int(h * 0.32)), "buildings/materials/roof_slate", rnd)
    c.img.paste(slate, (0, 0))
    c.rect(0, h * 0.3, w, h * 0.34, ramp("wood_dark", 4)[0])
    bench_img = bench((154, 86), rnd)
    c.img.paste(bench_img, (int(w * 0.68), h - 54 - 86), bench_img)
    return c.finish(darker("wood_dark", 0.5))


def armory_door(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = textured(size, "buildings/materials/wall_stone", rnd)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon([(0, h), (0, h * 0.25), (w * 0.5, 0), (w, h * 0.25), (w, h)], fill=255)
    c.img.paste(stone, (0, 0), mask)
    dark = ramp("stone_dark", 5)
    c.rect(w * 0.18, h * 0.3, w * 0.82, h, dark[0])
    door(c, w * 0.26, h * 0.36, w * 0.48, h * 0.5, base="iron", metal=True)
    brass = ramp("brass", 4)
    for k in range(5):
        y = h * (0.42 + 0.08 * k)
        c.rect(w * 0.64, y, w * 0.64 + 8, y + 10, brass[2])
        c.rect(w * 0.64 + 3, y + 4, w * 0.64 + 5, y + 7, brass[0])
    for k in range(4):
        y = h - 14 * (k + 1)
        c.rect(w * 0.18, y, w * 0.82, y + 14, dark[1 + k % 2])
        c.rect(w * 0.18, y, w * 0.82, y + 2, dark[3])
    return c.finish(darker("stone_dark", 0.45))


def tool_shed(size, rnd):
    w, h = size
    c = facade_base(size, rnd, "buildings/materials/wall_planks", "long", h, roof_base="iron")
    door(c, w * 0.3, h * 0.25, w * 0.34, h * 0.75)
    c.rect(w * 0.3, h * 0.25, w * 0.36, h, ramp("wood_dark", 4)[0])
    for x, col in ((0.75, "wood"), (0.85, "iron")):
        c.line([(w * x, h), (w * x + 10, h * 0.3)], ramp(col, 4)[2], 4)
    return _finish_facade(c)


def cafe(size, rnd):
    w, h = size
    c = facade_base(size, rnd, "buildings/materials/wall_plaster", "long", h, plinth=40, roof_base="tile")
    for k in range(3):
        window(c, w * (0.1 + 0.3 * k), h * 0.12, 64, 72, shutters="#5A7A5A")
    window(c, w * 0.08, h * 0.58, 200, 120)
    door(c, w * 0.66, h * 0.55, 96, h * 0.45)
    awn = ramp("#B5443A", 4)
    for k in range(10):
        x = w * 0.04 + k * 24
        c.poly([(x, h * 0.5), (x + 24, h * 0.5), (x + 24, h * 0.56), (x + 12, h * 0.58), (x, h * 0.56)], awn[2] if k % 2 else "#F2EEE6")
    c.blob(w * 0.9, h * 0.52, 12, 14, ramp("brass", 4))
    return _finish_facade(c)


def _shop(size, rnd, wall_key, goods_color, sign):
    w, h = size
    wall_h = 4 * 96
    c = facade_base(size, rnd, wall_key, "pignon", wall_h, plinth=36, roof_base="tile")
    window(c, w * 0.08, h - 200, 210, 120)
    for _ in range(9):
        c.blob(w * 0.08 + rnd.uniform(20, 190), h - 100 + rnd.uniform(-12, 0), rnd.uniform(9, 14), 8, ramp(goods_color, 4))
    door(c, w * 0.68, h - 230, 96, 230)
    window(c, w * 0.5 - 40, h - wall_h + 30, 80, 72)
    c.blob(w * 0.5, h - wall_h - 70, 30, 22, ramp(sign, 4))
    return _finish_facade(c)


def shop_bakery(size, rnd):
    return _shop(size, rnd, "buildings/materials/wall_stone", "#C89050", "#C89050")


def shop_bookshop(size, rnd):
    w, h = size
    img = _shop(size, rnd, "buildings/materials/wall_plaster", "#7A3A3A", "#5A7A5A")
    return img


def projection_hall(size, rnd):
    w, h = size
    c = facade_base(size, rnd, "buildings/materials/wall_stone", "long", h, plinth=40)
    door(c, w * 0.5 - 70, h * 0.55, 140, h * 0.45, double=True)
    poster = ramp("#C8A050", 4)
    c.rect(w * 0.1, h * 0.5, w * 0.1 + 90, h * 0.5 + 130, poster[2])
    c.rect(w * 0.1 + 8, h * 0.5 + 8, w * 0.1 + 82, h * 0.5 + 80, ramp("#6E5C86", 4)[2])
    for k in range(4):
        x = w * (0.08 + 0.23 * k)
        boards(c, x, h * 0.15, x + 90, h * 0.38, "#5A6E5A", width=8)
    return _finish_facade(c)


def stone_house(size, rnd):
    w, h = size
    wall_h = round(3.25 * 96)
    c = facade_base(size, rnd, "buildings/materials/wall_stone", "pignon", wall_h, roof_base="tile")
    door(c, w * 0.38, h - 210, 90, 210)
    window(c, w * 0.08, h - 200, 60, 70)
    window(c, w * 0.76, h - 200, 60, 70)
    c.rect(w * 0.04, h - 118, w * 0.36, h - 106, ramp("wood", 4)[1])
    for _ in range(6):
        c.blob(w * 0.06 + rnd.uniform(0, w * 0.28), h - 120, 7, 6, ramp(rnd.choice(["#C8653A", "#8E6CC9"]), 4))
    return _finish_facade(c)


def limashenka_house(size, rnd):
    w, h = size
    wall_h = round(3.75 * 96)
    c = facade_base(size, rnd, "buildings/materials/wall_plaster", "pignon", wall_h, plinth=30, roof_base="tile")
    door(c, w * 0.42, h - 220, 96, 220)
    window(c, w * 0.08, h - 210, 64, 80, shutters="#4A5A6E")
    window(c, w * 0.76, h - 210, 64, 80, shutters="#4A5A6E")
    window(c, w * 0.44, h - wall_h + 20, 64, 70, shutters="#4A5A6E")
    ivy = ramp("#4F6B3A", 4)
    for _ in range(40):
        c.blob(rnd.uniform(0, w * 0.2), h - rnd.uniform(40, wall_h), rnd.uniform(5, 10), rnd.uniform(4, 8), ivy)
    return _finish_facade(c)


RECIPES = {
    "props/well": well, "props/palisade": palisade, "props/palisade_gate": palisade_gate,
    "props/crystal_lamp": crystal_lamp, "props/tree_autumn": tree_autumn,
    "props/tree_autumn_rust": tree_autumn_rust, "props/tree_autumn_yellow": tree_autumn_yellow,
    "props/climbing_tree": climbing_tree, "props/bush": bush, "props/bench": bench,
    "props/laundry_line": laundry_line, "props/vegetable_patch": vegetable_patch,
    "props/flower_bed": flower_bed, "props/crate": crate, "props/ball": ball,
    "props/myosotis": myosotis, "props/tree_old_pine": tree_old_pine,
    "props/tree_old_pine_clawed": tree_old_pine_clawed, "props/tree_pine": tree_pine,
    "props/reeds": reeds, "props/log_bridge": None, "props/berry_bush": berry_bush,
    "props/bear_rock": bear_rock, "props/mossy_rock": mossy_rock, "props/mushroom": mushroom,
    "props/stick_rack": stick_rack, "props/play_goal": play_goal, "props/play_goal_red": play_goal_red,
    "props/vigil_bell": vigil_bell, "props/watch_post_ruin": watch_post_ruin,
    "props/ruined_wall": ruined_wall, "props/signal_pillar": signal_pillar,
    "props/garde_pennant": garde_pennant, "props/wind_rock_a": wind_rock_a,
    "props/wind_rock_b": wind_rock_b, "props/wind_rock_c": wind_rock_c,
    "props/edge_parapet": edge_parapet, "props/fallen_lantern": fallen_lantern,
    "props/grass_tuft": grass_tuft, "props/ring_stone": ring_stone, "props/signpost": signpost,
    "props/market_stall": market_stall, "props/market_stall_veg": market_stall_veg,
    "props/snack_stall": snack_stall, "props/cargo_crane": cargo_crane,
    "props/crates_barrels": crates_barrels, "props/scrap_pile": scrap_pile,
    "props/mooring_arm": mooring_arm, "props/gangway": gangway, "props/edge_railing": edge_railing,
    "props/bollard": bollard, "props/wind_sock": wind_sock, "props/rock": rock,
    "props/lone_tree": lone_tree, "props/lookout": lookout, "props/tall_grass": tall_grass,
    "props/airship_ferry": airship_ferry, "props/airship_barocupot": airship_barocupot,
    "sky/floating_rock": floating_rock,
    "buildings/warehouse_main": warehouse_main, "buildings/warehouse_porch": warehouse_porch,
    "buildings/warehouse_wing": warehouse_wing, "buildings/armory_door": armory_door,
    "buildings/tool_shed": tool_shed, "buildings/cafe": cafe, "buildings/shop_bakery": shop_bakery,
    "buildings/shop_bookshop": shop_bookshop, "buildings/projection_hall": projection_hall,
    "buildings/stone_house": stone_house, "buildings/limashenka_house": limashenka_house,
}


def log_bridge(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp("#7A5A40", 5)
    c.cylinder(w * 0.04, h * 0.15, w * 0.96, h, tones, vertical=False)
    for x in (0.04, 0.96):
        c.ellipse(w * x, h * 0.58, h * 0.3, h * 0.42, ramp("#C9A06A", 4)[2])
        c.ellipse(w * x, h * 0.58, h * 0.15, h * 0.2, ramp("#C9A06A", 4)[1])
    moss = ramp("#6E8C4A", 4)
    for _ in range(10):
        c.blob(rnd.uniform(w * 0.1, w * 0.9), h * 0.2, rnd.uniform(6, 14), 5, moss)
    return c.finish(darker("#7A5A40", 0.45))


RECIPES["props/log_bridge"] = log_bridge
