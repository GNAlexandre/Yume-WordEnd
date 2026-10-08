"""Recettes HD-2D du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md, lot A) : arbres et lisières
(section 6), arbustes, herbes, fleurs, champignons et premier plan (7), rochers et bords de
l'île (8).

Des panneaux debout, collés au bord bas et centrés, lumière de gauche ; les variantes d'une
famille ont chacune leur silhouette (port, taille, penché, cassé…), pas une autre couleur. Les
lisières et les bordures se raccordent à gauche et à droite (WrapCanvas)."""

import math

from PIL import Image, ImageChops, ImageDraw

from hd2d_art import Canvas, WrapCanvas, darker, fractal, mix, posterize, ramp, rgba, shade_texture
from hd2d_props import crown, pine_tiers, rock_shape, trunk

BARK = "wood_dark"
LEAF_COPPER = "#B8642E"
LEAF_RED = "#B8402E"
LEAF_YELLOW = "#D8B848"
GREEN = "#5E7A3A"
DARK_GREEN = "#3E5A34"


# --- Briques ------------------------------------------------------------------------------------


def limb(c, x0, y0, x1, y1, w0, w1, base=BARK):
    """Branche effilée de (x0, y0) à (x1, y1), éclairée sur son flanc gauche-haut."""
    tones = ramp(base, 5, spread=0.45)
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy) or 1.0
    px, py = -dy / n, dx / n
    c.poly([(x0 + px * w0 / 2, y0 + py * w0 / 2), (x1 + px * w1 / 2, y1 + py * w1 / 2),
            (x1 - px * w1 / 2, y1 - py * w1 / 2), (x0 - px * w0 / 2, y0 - py * w0 / 2)], tones[1])
    side = 1 if px * -1 + py * -1 > 0 else -1
    c.poly([(x0 + side * px * w0 / 2, y0 + side * py * w0 / 2), (x1 + side * px * w1 / 2, y1 + side * py * w1 / 2),
            (x1 + side * px * w1 * 0.05, y1 + side * py * w1 * 0.05), (x0 + side * px * w0 * 0.05, y0 + side * py * w0 * 0.05)],
           tones[3])


def twigs(c, x, y, angle, length, depth, rnd, base=BARK, width=3.0):
    """Ramure nue récursive (arbres morts, feuillus dégarnis)."""
    if depth == 0 or length < 4:
        return []
    x1, y1 = x + math.cos(angle) * length, y + math.sin(angle) * length
    limb(c, x, y, x1, y1, width, max(1.0, width * 0.6), base)
    tips = [(x1, y1)]
    for k in range(rnd.randint(2, 3)):
        a = angle + rnd.uniform(-0.75, 0.75)
        tips += twigs(c, x1, y1, a, length * rnd.uniform(0.55, 0.75), depth - 1, rnd, base, max(1.0, width * 0.6))
    return tips


def leaf_mass(c, cx, cy, rx, ry, base, density=1.0, grain=1.0, dark=0.0):
    """Masse de feuillage : beaucoup de petites touffes (rayon proportionnel à grain), ombrées selon
    leur place (lumière en haut à gauche, creux sombres en bas à droite), bord dentelé de feuilles."""
    tones = ramp(mix(base, "#2A2234", dark) if dark else base, 6, spread=0.55)
    r0 = max(4.0, min(13.0, min(rx, ry) * 0.16)) * grain
    n = int(density * 1.3 * rx * ry / (r0 * r0)) + 4
    blobs = []
    for _ in range(n):
        a = c.rnd.uniform(0, 2 * math.pi)
        d = math.sqrt(c.rnd.random())
        x = cx + math.cos(a) * rx * d * 0.86
        y = cy + math.sin(a) * ry * d * 0.86
        blobs.append((y, x, r0 * c.rnd.uniform(0.7, 1.3)))
    blobs.sort()
    for y, x, r in blobs:
        lit = -((x - cx) / rx) * 0.6 - ((y - cy) / ry) * 0.9
        k = max(0, min(2, int(round(1 + lit * 1.2 + c.rnd.uniform(-0.4, 0.4)))))
        c.blob(x, y, r, r * 0.82, tones[k:k + 4], (-0.5, -0.65))
    for _ in range(int(n * 3)):
        a = c.rnd.uniform(0, 2 * math.pi)
        d = c.rnd.uniform(0.75, 1.02)
        x = cx + math.cos(a) * rx * d
        y = cy + math.sin(a) * ry * d
        ix, iy = int(x - math.cos(a) * 3), int(y - math.sin(a) * 3)
        if 0 <= x < c.w and 0 <= y < c.h and 0 <= ix < c.w and 0 <= iy < c.h and c.img.getpixel((ix, iy))[3]:
            lit = -math.cos(a) * 0.6 - math.sin(a) * 0.9
            c.rect(x, y, x + 2, y + 2, tones[3 if lit > 0.3 else (1 if lit < -0.3 else 2)])
    for _ in range(int(rx * ry / 6)):
        a = c.rnd.uniform(0, 2 * math.pi)
        d = math.sqrt(c.rnd.random())
        x = cx + math.cos(a) * rx * d
        y = cy + math.sin(a) * ry * d
        if 0 <= x < c.w and 0 <= y < c.h and c.img.getpixel((int(x), int(y)))[3]:
            lit = -((x - cx) / rx) * 0.6 - ((y - cy) / ry) * 0.9
            c.rect(x, y, x + 2, y + 1, tones[5] if lit > 0.35 and c.rnd.random() < 0.7 else tones[0 if lit < 0 else 2])


def foliage(w, h, rnd, clusters, holes=(), grain=1.0):
    """Couche de feuillage : grappes (cx, cy, rx, ry, couleur, densité), trouées transparentes."""
    layer = Canvas(w, h, rnd)
    for cx, cy, rx, ry, color, count in clusters:
        leaf_mass(layer, cx, cy, rx, ry, color, density=0.6 + count / 30.0, grain=grain)
    for hx, hy, hr in holes:
        cut = Image.new("L", (w, h), 0)
        ImageDraw.Draw(cut).ellipse((hx - hr, hy - hr * 0.8, hx + hr, hy + hr * 0.8), fill=255)
        layer.img.paste(Image.new("RGBA", (w, h), (0, 0, 0, 0)), (0, 0), cut)
    return layer.img


def tree(size, rnd, build, outline_base):
    """Arbre en deux couches : bois (tronc, branches) puis feuillage, contour commun."""
    w, h = size
    wood = Canvas(w, h, rnd)
    leaves = build(wood, w, h)
    if leaves is not None:
        wood.img.alpha_composite(leaves)
    return wood.finish(darker(outline_base, 0.4))


def foot(c, cx, y, half, base=GREEN):
    """Touffes d'herbe au pied (petits brins)."""
    tones = ramp(base, 4)
    for _ in range(int(half / 2)):
        x = cx + c.rnd.uniform(-half, half)
        c.line([(x, y), (x + c.rnd.uniform(-3, 3), y - c.rnd.uniform(3, 9))], tones[c.rnd.randint(1, 3)])


# --- Arbres (section 6) -------------------------------------------------------------------------


def oak_a(size, rnd):
    def build(c, w, h):
        trunk(c, w * 0.5, h, h * 0.56, w * 0.2, w * 0.12)
        for x1, y1, wd in ((0.16, 0.42, 26), (0.84, 0.4, 26), (0.32, 0.22, 18), (0.68, 0.2, 18), (0.5, 0.12, 14)):
            limb(c, w * 0.5, h * 0.62, w * x1, h * y1, wd, wd * 0.35)
        return foliage(w, h, rnd, [(w * 0.2, h * 0.4, w * 0.18, h * 0.14, "leaf_gold", 10),
                                   (w * 0.8, h * 0.38, w * 0.18, h * 0.15, "leaf_gold", 10),
                                   (w * 0.5, h * 0.18, w * 0.3, h * 0.15, "leaf_gold", 12),
                                   (w * 0.32, h * 0.28, w * 0.2, h * 0.14, "#B07E3A", 8),
                                   (w * 0.68, h * 0.3, w * 0.2, h * 0.14, "leaf_gold", 8),
                                   (w * 0.5, h * 0.44, w * 0.22, h * 0.09, "#9A6A36", 6)],
                       holes=[(w * 0.42, h * 0.33, w * 0.035), (w * 0.62, h * 0.24, w * 0.03), (w * 0.26, h * 0.46, w * 0.028)])
    return tree(size, rnd, build, "leaf_gold")


def oak_b(size, rnd):
    def build(c, w, h):
        trunk(c, w * 0.46, h, h * 0.5, w * 0.17, w * 0.1, lean=-w * 0.14)
        limb(c, w * 0.42, h * 0.7, w * 0.94, h * 0.66, 28, 10)
        limb(c, w * 0.32, h * 0.52, w * 0.12, h * 0.32, 18, 7)
        limb(c, w * 0.32, h * 0.52, w * 0.44, h * 0.2, 16, 6)
        return foliage(w, h, rnd, [(w * 0.26, h * 0.3, w * 0.24, h * 0.17, "leaf_gold", 10),
                                   (w * 0.46, h * 0.16, w * 0.2, h * 0.12, "#B07E3A", 8),
                                   (w * 0.12, h * 0.44, w * 0.11, h * 0.1, "leaf_gold", 6),
                                   (w * 0.86, h * 0.58, w * 0.13, h * 0.08, "leaf_gold", 6),
                                   (w * 0.68, h * 0.62, w * 0.1, h * 0.05, "#9A6A36", 4)],
                       holes=[(w * 0.3, h * 0.32, w * 0.03)])
    return tree(size, rnd, build, "leaf_gold")


def oak_c(size, rnd):
    def build(c, w, h):
        trunk(c, w * 0.5, h, h * 0.52, w * 0.24, w * 0.14)
        c.ellipse(w * 0.5, h * 0.8, w * 0.06, h * 0.08, "#2A1E1C")
        c.ellipse(w * 0.5, h * 0.82, w * 0.04, h * 0.055, "#1A1214")
        for a in (-2.5, -2.0, -1.55, -1.1, -0.65):
            twigs(c, w * 0.5, h * 0.56, a, h * 0.15, 3, rnd, width=16)
        return foliage(w, h, rnd, [(w * 0.24, h * 0.32, w * 0.15, h * 0.1, "leaf_rust", 5),
                                   (w * 0.72, h * 0.28, w * 0.16, h * 0.1, "leaf_rust", 5),
                                   (w * 0.48, h * 0.14, w * 0.15, h * 0.08, "#9A5A36", 4),
                                   (w * 0.84, h * 0.44, w * 0.09, h * 0.06, "leaf_rust", 3)],
                       holes=[(w * 0.3, h * 0.3, w * 0.04), (w * 0.7, h * 0.26, w * 0.035)])
    return tree(size, rnd, build, "leaf_rust")


def oak_d(size, rnd):
    def build(c, w, h):
        trunk(c, w * 0.5, h, h * 0.56, w * 0.19, w * 0.11)
        for a in (-0.25, -0.65, -1.05):
            twigs(c, w * 0.53, h * 0.6, a, h * 0.17, 3, rnd, base="#8A7A6A", width=14)
        limb(c, w * 0.5, h * 0.62, w * 0.18, h * 0.36, 22, 8)
        limb(c, w * 0.5, h * 0.62, w * 0.38, h * 0.16, 18, 6)
        return foliage(w, h, rnd, [(w * 0.24, h * 0.32, w * 0.22, h * 0.16, "leaf_gold", 10),
                                   (w * 0.4, h * 0.16, w * 0.16, h * 0.11, "leaf_gold", 7),
                                   (w * 0.28, h * 0.48, w * 0.14, h * 0.07, "#B07E3A", 5)],
                       holes=[(w * 0.26, h * 0.3, w * 0.028)])
    return tree(size, rnd, build, "leaf_gold")


def _beech(size, rnd, twin=False, extras=False):
    def build(c, w, h):
        grey = "#8E8C86"
        if twin:
            trunk(c, w * 0.45, h, h * 0.36, w * 0.1, w * 0.055, base=grey, lean=-w * 0.1)
            trunk(c, w * 0.56, h, h * 0.32, w * 0.09, w * 0.05, base=grey, lean=w * 0.1)
        else:
            trunk(c, w * 0.5, h, h * 0.36, w * 0.12, w * 0.065, base=grey)
        for x1, y1 in ((0.26, 0.34), (0.74, 0.3), (0.5, 0.12)):
            limb(c, w * 0.5, h * 0.48, w * x1, h * y1, 11, 4, grey)
        if extras:
            shelf = ramp("#C8A878", 4)
            for y, side in ((0.74, -1), (0.68, 1), (0.62, -1)):
                c.ellipse(w * 0.5 + side * w * 0.07, h * y, w * 0.04, h * 0.009, shelf[2])
                c.rect(w * 0.5 + side * w * 0.07 - w * 0.035, h * y, w * 0.5 + side * w * 0.07 + w * 0.035, h * y + 3, shelf[0])
            ivy = ramp(DARK_GREEN, 4)
            for k in range(46):
                c.blob(w * 0.5 + math.sin(k * 0.7) * w * 0.05, h * (0.98 - 0.0075 * k), 4, 3, ivy)
        colors = [LEAF_COPPER, "#D08A3A"] if not twin else [LEAF_COPPER, "leaf_gold"]
        return foliage(w, h, rnd, [(w * 0.5, h * 0.3, w * 0.4, h * 0.25, colors[0], 12),
                                   (w * 0.42, h * 0.13, w * 0.24, h * 0.11, colors[1], 8),
                                   (w * 0.64, h * 0.42, w * 0.24, h * 0.1, colors[1], 6),
                                   (w * 0.3, h * 0.44, w * 0.16, h * 0.08, colors[0], 5)],
                       holes=[(w * 0.6, h * 0.24, w * 0.035)])
    return tree(size, rnd, build, LEAF_COPPER)


def beech_a(size, rnd):
    return _beech(size, rnd)


def beech_b(size, rnd):
    return _beech(size, rnd, twin=True)


def beech_c(size, rnd):
    return _beech(size, rnd, extras=True)


def maple_a(size, rnd):
    def build(c, w, h):
        trunk(c, w * 0.5, h, h * 0.55, w * 0.11, w * 0.065)
        for x1, y1 in ((0.26, 0.4), (0.74, 0.38), (0.5, 0.2)):
            limb(c, w * 0.5, h * 0.62, w * x1, h * y1, 13, 5)
        return foliage(w, h, rnd, [(w * 0.5, h * 0.36, w * 0.45, h * 0.3, LEAF_RED, 14),
                                   (w * 0.36, h * 0.22, w * 0.2, h * 0.12, "leaf_rust", 5),
                                   (w * 0.68, h * 0.48, w * 0.18, h * 0.1, "leaf_rust", 5)])
    return tree(size, rnd, build, LEAF_RED)


def maple_b(size, rnd):
    def build(c, w, h):
        trunk(c, w * 0.5, h, h * 0.6, w * 0.08, w * 0.045)
        limb(c, w * 0.5, h * 0.66, w * 0.32, h * 0.5, 8, 3)
        limb(c, w * 0.5, h * 0.66, w * 0.68, h * 0.48, 8, 3)
        return foliage(w, h, rnd, [(w * 0.34, h * 0.46, w * 0.22, h * 0.18, LEAF_RED, 8),
                                   (w * 0.66, h * 0.44, w * 0.22, h * 0.18, "leaf_gold", 8),
                                   (w * 0.5, h * 0.32, w * 0.18, h * 0.12, "#C8702E", 5)])
    return tree(size, rnd, build, LEAF_RED)


def maple_c(size, rnd):
    def build(c, w, h):
        trunk(c, w * 0.5, h - 5, h * 0.52, w * 0.11, w * 0.065)
        for a in (-2.7, -2.2, -1.7, -1.25, -0.8, -0.4):
            twigs(c, w * 0.5, h * 0.56, a, h * 0.16, 3, rnd, width=10)
        red = ramp(LEAF_RED, 4)
        for _ in range(160):
            x = w * 0.5 + rnd.gauss(0, w * 0.18)
            c.rect(x, h - rnd.randint(1, 5), x + 2, h, red[rnd.randint(0, 3)])
        return foliage(w, h, rnd, [(w * 0.26, h * 0.32, w * 0.08, h * 0.05, LEAF_RED, 2),
                                   (w * 0.72, h * 0.26, w * 0.07, h * 0.05, LEAF_RED, 2),
                                   (w * 0.55, h * 0.16, w * 0.06, h * 0.04, "leaf_rust", 2)])
    return tree(size, rnd, build, LEAF_RED)


def _birch_trunk(c, x0, y0, x1, y1, width, rnd):
    """Tronc de bouleau : blanc, taches noires, un peu courbé."""
    pts = [(x0 + (x1 - x0) * t + math.sin(t * 3.0) * width * 0.6, y0 + (y1 - y0) * t) for t in [k / 8.0 for k in range(9)]]
    white = ramp("#E8E4DA", 4, spread=0.3)
    for k in range(8):
        wd = width * (1.0 - 0.55 * k / 8.0)
        limb(c, pts[k][0], pts[k][1], pts[k + 1][0], pts[k + 1][1], wd, wd * 0.93, "#E2DED2")
    for k in range(int(abs(y1 - y0) / 9)):
        t = rnd.random()
        x = x0 + (x1 - x0) * t + math.sin(t * 3.0) * width * 0.6
        y = y0 + (y1 - y0) * t
        c.rect(x - width * 0.3 + rnd.uniform(-1, 1), y, x + rnd.uniform(0, width * 0.3), y + 2, "#2E2A2A")
    del white


def birch_a(size, rnd):
    def build(c, w, h):
        _birch_trunk(c, w * 0.5, h, w * 0.46, h * 0.12, w * 0.07, rnd)
        for y, side in ((0.5, -1), (0.42, 1), (0.32, -1), (0.24, 1)):
            limb(c, w * 0.48, h * y, w * (0.48 + side * 0.28), h * (y - 0.1), 4, 2, "#C8C4B8")
        return foliage(w, h, rnd, [(w * 0.3, h * 0.36, w * 0.16, h * 0.08, LEAF_YELLOW, 8),
                                   (w * 0.68, h * 0.3, w * 0.16, h * 0.08, LEAF_YELLOW, 8),
                                   (w * 0.46, h * 0.16, w * 0.2, h * 0.1, LEAF_YELLOW, 10),
                                   (w * 0.6, h * 0.45, w * 0.12, h * 0.05, "#E2C860", 5)],
                       holes=[(w * 0.5, h * 0.3, w * 0.07)])
    return tree(size, rnd, build, LEAF_YELLOW)


def birch_b(size, rnd):
    def build(c, w, h):
        _birch_trunk(c, w * 0.48, h, w * 0.24, h * 0.14, w * 0.05, rnd)
        _birch_trunk(c, w * 0.52, h, w * 0.78, h * 0.2, w * 0.05, rnd)
        return foliage(w, h, rnd, [(w * 0.24, h * 0.18, w * 0.18, h * 0.1, LEAF_YELLOW, 9),
                                   (w * 0.78, h * 0.24, w * 0.18, h * 0.1, LEAF_YELLOW, 9),
                                   (w * 0.3, h * 0.32, w * 0.12, h * 0.06, "#E2C860", 5),
                                   (w * 0.72, h * 0.38, w * 0.12, h * 0.06, "#E2C860", 5)])
    return tree(size, rnd, build, LEAF_YELLOW)


def needles(c, base, density=0.12):
    """Texture d'aiguilles sur les étages d'un sapin : petits traits clairs (à gauche) et sombres."""
    tones = ramp(base, 5, spread=0.55)
    alpha = c.img.getchannel("A")
    for _ in range(int(c.w * c.h * density / 6)):
        x, y = c.rnd.randrange(c.w), c.rnd.randrange(c.h)
        if alpha.getpixel((x, y)) > 128:
            r, g, b, _a = c.img.getpixel((x, y))
            if abs(r - tones[1][0]) + abs(g - tones[1][1]) + abs(b - tones[1][2]) > 120:
                continue
            col = tones[4] if x < c.w * 0.45 and c.rnd.random() < 0.6 else tones[0]
            c.line([(x, y), (x + c.rnd.choice([-2, -1, 1, 2]), y + 1)], col)


def pine_small_a(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w / 2.0, h, h * 0.6, w * 0.1, w * 0.06, base="#5A4436")
    pine_tiers(c, w / 2.0, h * 0.01, h * 0.9, w * 0.47, 7)
    needles(c, "pine")
    return c.finish(darker("pine", 0.4))


def pine_small_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w * 0.5, h, h * 0.4, w * 0.1, w * 0.05, base="#5A4436", lean=w * 0.1)
    tones = ramp("pine", 5, spread=0.55)
    tiers = [(0.06, 0.24, 0.16, 0.58), (0.18, 0.4, 0.26, 0.6), (0.32, 0.58, 0.36, 0.54), (0.5, 0.78, 0.46, 0.42),
             (0.66, 0.9, 0.3, 0.9)]
    for k, (t0, t1, half, cxf) in enumerate(tiers):
        yt, yb = h * t0, h * t1
        cx = w * cxf
        left = w * half * (1.3 if k == 3 else 1.0)
        right = w * half * (0.6 if k == 3 else 1.0)
        c.poly([(cx, yt), (cx + right, yb), (cx + right * 0.4, yb - 6), (cx, yb), (cx - left * 0.5, yb - 5), (cx - left, yb)], tones[1])
        c.poly([(cx, yt), (cx - left, yb), (cx - left * 0.5, yb - 5), (cx, yb)], tones[3])
        c.poly([(cx, yt + 4), (cx - left * 0.5, yb - 8), (cx - left * 0.15, yb - 8)], tones[4])
    needles(c, "pine")
    return c.finish(darker("pine", 0.4))


def pine_tall_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    trunk(c, w / 2.0, h, h * 0.05, w * 0.1, w * 0.03, base="#5A4436")
    tones = ramp(mix("pine", "#2E3E3A", 0.3), 5, spread=0.55)
    y = h * 0.02
    k = 0
    while y < h * 0.7:
        th = h * rnd.uniform(0.07, 0.1)
        half = w * (0.12 + 0.28 * (y / (h * 0.7))) * rnd.uniform(0.75, 1.15)
        off = rnd.uniform(-0.04, 0.04) * w
        cx = w / 2.0 + off
        c.poly([(cx, y), (cx + half, y + th), (cx + half * 0.3, y + th - 5), (cx - half * 0.4, y + th - 4), (cx - half, y + th)], tones[1])
        c.poly([(cx, y), (cx - half, y + th), (cx - half * 0.4, y + th - 4), (cx, y + th - 2)], tones[3])
        c.poly([(cx, y + 3), (cx - half * 0.5, y + th - 7), (cx - half * 0.15, y + th - 8)], tones[4])
        y += th * 0.72
        k += 1
    needles(c, mix("pine", "#2E3E3A", 0.3))
    return c.finish(darker("pine", 0.4))


def pine_dead(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    silver = "#A8A49C"
    trunk(c, w / 2.0, h, h * 0.02, w * 0.12, w * 0.03, base=silver)
    for k in range(9):
        y = h * (0.12 + 0.08 * k)
        side = -1 if k % 2 else 1
        length = w * rnd.uniform(0.12, 0.4) * (1.0 - 0.3 * (k < 2))
        droop = rnd.uniform(0.0, 0.25)
        limb(c, w / 2.0, y, w / 2.0 + side * length, y + length * droop + rnd.uniform(-8, 8), 5, 2, silver)
    lichen = ramp("#9AA08A", 3)
    for _ in range(40):
        c.rect(w / 2.0 + rnd.uniform(-w * 0.05, w * 0.04), h * rnd.uniform(0.3, 0.95), w / 2.0 + rnd.uniform(-w * 0.04, w * 0.05),
               h * rnd.uniform(0.3, 0.95) + 2, lichen[rnd.randint(0, 2)])
    return c.finish(darker(silver, 0.4))


def dead_tree_a(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    pale = "#B8AC98"
    pts = [(w * 0.4, h), (w * 0.36, h * 0.8), (w * 0.42, h * 0.62), (w * 0.4, h * 0.48), (w * 0.48, h * 0.36)]
    for k in range(4):
        limb(c, pts[k][0], pts[k][1], pts[k + 1][0], pts[k + 1][1], w * (0.12 - 0.02 * k), w * (0.1 - 0.02 * k), pale)
    for x, y, a in ((0.42, 0.62, -0.5), (0.4, 0.5, -0.9), (0.48, 0.38, -0.3), (0.46, 0.4, -1.3), (0.4, 0.7, -0.15)):
        twigs(c, w * x, h * y, a, h * rnd.uniform(0.12, 0.18), 3, rnd, base=pale, width=7)
    return c.finish(darker(pale, 0.4))


def dead_tree_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    pale = "#A89C88"
    trunk(c, w * 0.5, h, h * 0.42, w * 0.18, w * 0.13, base=pale)
    tones = ramp(pale, 5)
    c.poly([(w * 0.43, h * 0.43), (w * 0.47, h * 0.34), (w * 0.5, h * 0.4), (w * 0.53, h * 0.3), (w * 0.57, h * 0.43)], tones[2])
    twigs(c, w * 0.45, h * 0.58, -2.4, h * 0.16, 2, rnd, base=pale, width=7)
    twigs(c, w * 0.55, h * 0.66, -0.5, h * 0.18, 3, rnd, base=pale, width=7)
    return c.finish(darker(pale, 0.4))


def sapling_a(size, rnd):
    def build(c, w, h):
        stake = ramp("#B8946A", 4)
        c.rect(w * 0.62, h * 0.3, w * 0.62 + 5, h, stake[2])
        c.rect(w * 0.62, h * 0.3, w * 0.62 + 2, h, stake[3])
        limb(c, w * 0.5, h, w * 0.5, h * 0.2, 6, 2)
        c.rect(w * 0.5, h * 0.55, w * 0.62 + 5, h * 0.55 + 3, "#C8B48A")
        limb(c, w * 0.5, h * 0.4, w * 0.3, h * 0.26, 3, 1)
        limb(c, w * 0.5, h * 0.34, w * 0.7, h * 0.2, 3, 1)
        return foliage(w, h, rnd, [(w * 0.3, h * 0.24, w * 0.12, h * 0.06, "leaf_gold", 4),
                                   (w * 0.68, h * 0.18, w * 0.12, h * 0.06, "leaf_gold", 4),
                                   (w * 0.5, h * 0.12, w * 0.12, h * 0.06, LEAF_YELLOW, 4)])
    return tree(size, rnd, build, "leaf_gold")


def sapling_b(size, rnd):
    def build(c, w, h):
        limb(c, w * 0.5, h, w * 0.48, h * 0.4, 6, 3)
        return foliage(w, h, rnd, [(w * 0.5, h * 0.3, w * 0.36, h * 0.24, LEAF_RED, 12)])
    return tree(size, rnd, build, LEAF_RED)


def willow(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    pts = [(w * 0.46, h), (w * 0.42, h * 0.82), (w * 0.48, h * 0.66), (w * 0.44, h * 0.5)]
    for k in range(3):
        limb(c, pts[k][0], pts[k][1], pts[k + 1][0], pts[k + 1][1], w * (0.12 - 0.02 * k), w * (0.1 - 0.02 * k), "#6A5440")
    leaf_mass(c, w * 0.5, h * 0.3, w * 0.36, h * 0.17, "#A8B048", density=1.1, grain=0.8)
    tones = ramp("#A8B048", 5)
    for k in range(60):
        x = w * (0.12 + 0.76 * k / 59.0) + rnd.uniform(-4, 4)
        top = h * 0.25 + abs(x - w * 0.5) / w * h * 0.3
        length = h * rnd.uniform(0.25, 0.55)
        bend = rnd.uniform(-6, 10)
        for s in range(int(length / 3)):
            y = top + s * 3
            xx = x + bend * (s * 3 / length) ** 2
            if y < h - 2:
                c.rect(xx, y, xx + 2, y + 3, tones[1 + (s + k) % 3])
                if s % 3 == 0:
                    c.pixel(xx + 2, y + 1, tones[4])
    return c.finish(darker("#A8B048", 0.4))


def lone_tree_b(size, rnd):
    def build(c, w, h):
        pts = [(w * 0.36, h), (w * 0.4, h * 0.8), (w * 0.5, h * 0.66), (w * 0.62, h * 0.56)]
        for k in range(3):
            limb(c, pts[k][0], pts[k][1], pts[k + 1][0], pts[k + 1][1], w * (0.1 - 0.02 * k), w * (0.08 - 0.02 * k))
        limb(c, w * 0.5, h * 0.66, w * 0.88, h * 0.5, 9, 3)
        limb(c, w * 0.46, h * 0.72, w * 0.22, h * 0.62, 7, 3)
        return foliage(w, h, rnd, [(w * 0.66, h * 0.44, w * 0.26, h * 0.09, "leaf_rust", 14),
                                   (w * 0.86, h * 0.48, w * 0.12, h * 0.06, "leaf_gold", 6),
                                   (w * 0.46, h * 0.5, w * 0.14, h * 0.07, "leaf_rust", 8),
                                   (w * 0.22, h * 0.6, w * 0.08, h * 0.04, "leaf_gold", 4)])
    return tree(size, rnd, build, "leaf_rust")


# --- Lisières (sans raccord à gauche et à droite) ------------------------------------------------


def _wall(size, rnd, palette, trunks, pines, light_rays=0, dark=0.0, gaps=0, bottom="fern", treeline=False):
    """Pan de forêt de 16 m, sans raccord à gauche et à droite : fond sombre et feuillages lointains,
    troncs dans la pénombre, feuillages de l'avant qui se chevauchent, sous-bois en bas."""
    w, h = size
    c = WrapCanvas(w, h, rnd)
    canopy = h * (0.42 if treeline else 0.1)
    shade = mix("#2A2232", "#1A1620", dark * 3)
    # 1. Fond : pénombre tramée (bas) et feuillages lointains, désaturés et violacés.
    gloom = posterize(fractal((w, h), (12, 6), rnd, 3), [shade, mix(shade, "#3A3448", 0.5), mix(shade, "#2E3A30", 0.6)],
                      dither=90)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rectangle((0, int(canopy + h * 0.16), w, h), fill=255)
    c.img.paste(gloom, (0, 0), mask)
    far = [mix(col, "#4A4060", 0.5 + dark) for col in palette]
    step = 150 if not treeline else 190
    for k in range(int(w / step) + 1):
        x = k * step + rnd.uniform(-30, 30)
        leaf_mass(c, x, canopy + h * rnd.uniform(0.1, 0.2), rnd.uniform(110, 150), h * rnd.uniform(0.14, 0.2),
                  rnd.choice(far), density=0.9, grain=1.2)
    for _ in range(pines):
        x = rnd.uniform(0, w)
        pine_tiers(c, x, canopy + h * rnd.uniform(-0.08, 0.04), h * rnd.uniform(0.55, 0.75), rnd.uniform(36, 60), 6,
                   base=mix("pine", "#2E3040", 0.3 + dark))
    # 2. Troncs du milieu, sombres, du sol jusque dans les feuillages.
    for _ in range(trunks):
        x = rnd.uniform(0, w)
        width = rnd.uniform(12, 26)
        trunk(c, x, h, canopy + h * rnd.uniform(0.15, 0.3), width, width * 0.6, base=mix(BARK, "#2A2230", 0.45 + dark))
    # 3. Étage du milieu : feuillages assombris sous la voûte ; puis feuillages de l'avant, plus
    # clairs, qui se chevauchent.
    mid_step = 170 if not treeline else 260
    for k in range(int(w / mid_step) + 1):
        x = k * mid_step + rnd.uniform(-50, 50)
        y = canopy + (h - canopy) * rnd.uniform(0.35, 0.6)
        leaf_mass(c, x, y, rnd.uniform(60, 100), (h - canopy) * rnd.uniform(0.1, 0.16), rnd.choice(palette), density=0.9,
                  dark=0.45 + dark)
    step = 120 if not treeline else 150
    for k in range(int(w / step) + 1):
        x = k * step + rnd.uniform(-40, 40)
        y = canopy + h * rnd.uniform(0.02, 0.2) if not treeline else canopy + h * rnd.uniform(-0.12, 0.08)
        leaf_mass(c, x, y, rnd.uniform(70, 110), h * rnd.uniform(0.09, 0.15), rnd.choice(palette), density=1.0,
                  dark=0.15 + dark)
    for _ in range(trunks // 3):
        x = rnd.uniform(0, w)
        width = rnd.uniform(20, 34)
        trunk(c, x, h, canopy + h * rnd.uniform(0.3, 0.45), width, width * 0.7, base=mix(BARK, "#3A2E30", 0.2 + dark))
    # 4. Rais de lumière dorée (un pixel sur deux en damier, sur ce qui est déjà dessiné).
    stripes = Image.new("L", (w, h), 0)
    stripes.putdata([255 if (x + y) % 2 == 0 else 0 for y in range(h) for x in range(w)])
    for _ in range(light_rays):
        x = rnd.uniform(w * 0.05, w * 0.85)
        ray = Image.new("L", (w, h), 0)
        ImageDraw.Draw(ray).polygon([(x, canopy + h * 0.15), (x + 18, canopy + h * 0.15), (x + 96, h - 30), (x + 60, h - 30)],
                                    fill=255)
        mask = ImageChops.multiply(ImageChops.multiply(ray, stripes), c.img.getchannel("A"))
        c.img.paste(Image.new("RGBA", (w, h), rgba("#B8945A")), (0, 0), mask)
    # 5. Trouée au milieu (lisière claire) : le ciel passe entre les cimes.
    for _ in range(gaps):
        cut = Image.new("L", (w, h), 0)
        cd = ImageDraw.Draw(cut)
        for _ in range(90):
            t = rnd.random()
            x = w * 0.5 + rnd.uniform(-1, 1) * 110 * (1.0 - 0.6 * t)
            y = -10 + t * (canopy + h * 0.2)
            r = rnd.uniform(10, 26)
            cd.ellipse((x - r, y - r, x + r, y + r), fill=255)
        c.img.paste(Image.new("RGBA", (w, h), (0, 0, 0, 0)), (0, 0), cut)
    # 6. Sous-bois : fougères et buissons sombres le long du sol.
    under = [mix(GREEN, "#1E2A20", 0.35 + dark), mix("leaf_rust", "#2A1E1C", 0.35 + dark), mix(DARK_GREEN, "#1E2A20", 0.2)]
    for k in range(int(w / 70) + 1):
        x = k * 70 + rnd.uniform(-25, 25)
        tall = rnd.uniform(0.06, 0.12) * h
        leaf_mass(c, x, h - tall * 0.9, rnd.uniform(40, 70), tall, rnd.choice(under), density=0.9, grain=0.8, dark=0.15)
    for k in range(int(w / 40) + 1):
        x = k * 40 + rnd.uniform(-15, 15)
        leaf_mass(c, x, h - rnd.uniform(14, 34), rnd.uniform(26, 48), rnd.uniform(16, 30), rnd.choice(under), density=0.9,
                  grain=0.7)
    if bottom == "reeds":
        tones = ramp("reed", 4)
        for _ in range(int(w / 3)):
            x = rnd.uniform(0, w)
            c.line([(x, h), (x + rnd.uniform(-3, 5), h - rnd.uniform(20, 70))], tones[rnd.randint(0, 3)], 2)
        mist = Image.new("L", (w, 48), 0)
        md = ImageDraw.Draw(mist)
        for yy in range(48):
            for xx in range(0, w, 2):
                if (xx // 2 + yy) % 2 == 0 and yy > 20 - 8 * math.sin(xx / 90.0):
                    md.point((xx + (yy % 2), yy), fill=255)
        alpha = c.img.getchannel("A").crop((0, h - 48, w, h))
        c.img.paste(Image.new("RGBA", (w, 48), rgba("#D6C8D6")), (0, h - 48), ImageChops.multiply(mist, alpha))
    c.rect(0, h - 3, w, h, mix(under[0], "#141018", 0.4))
    return c.finish(darker(palette[0], 0.35))


def forest_wall_a(size, rnd):
    return _wall(size, rnd, ["leaf_gold", "leaf_rust", "#A87A3A", mix("pine", "grass", 0.2)], 26, 8, light_rays=3)


def forest_wall_b(size, rnd):
    return _wall(size, rnd, [mix("pine", "#2E3A34", 0.1), "leaf_rust", mix("pine", "grass", 0.2), "#3E5040"], 22, 22,
                 light_rays=1, dark=0.1)


def forest_wall_c(size, rnd):
    return _wall(size, rnd, [LEAF_YELLOW, "leaf_gold", "#E2C860", LEAF_COPPER], 30, 3, light_rays=4, gaps=1)


def forest_wall_d(size, rnd):
    return _wall(size, rnd, ["#A8B048", "#8A9A48", "leaf_gold", "#6E8A4A"], 18, 2, bottom="reeds", dark=0.05)


def treeline_autumn_a(size, rnd):
    return _wall(size, rnd, ["leaf_gold", "leaf_rust", "#A87A3A", mix("pine", "grass", 0.2)], 16, 4, treeline=True)


def treeline_autumn_b(size, rnd):
    return _wall(size, rnd, ["leaf_rust", LEAF_YELLOW, LEAF_RED, "leaf_gold"], 16, 2, treeline=True)


# --- Arbustes, herbes, fleurs (section 7) -------------------------------------------------------


def shrub(size, rnd, colors, shape="dome", stems=0, berries=None, bare=0, outline_base=GREEN, dark=0.0):
    """Buisson : silhouette (dome, upright, low, cone, arch), tiges, baies, branches nues."""
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#6A5038", 4)
    for k in range(stems):
        x = w * (0.3 + 0.4 * k / max(1, stems - 1))
        c.line([(w * 0.5, h), (x + rnd.uniform(-6, 6), h * rnd.uniform(0.1, 0.4))], wood[1], 2)
    if shape == "cone":
        for k in range(7):
            t = k / 6.0
            leaf_mass(c, w * 0.5 + rnd.uniform(-3, 3), h * (0.16 + 0.68 * t), w * (0.12 + 0.3 * t), h * 0.14, colors[0],
                      density=1.2, grain=0.45)
    else:
        clusters = {
            "dome": [(0.5, 0.56, 0.44, 0.42)],
            "upright": [(0.5, 0.42, 0.34, 0.4), (0.34, 0.62, 0.2, 0.3), (0.66, 0.6, 0.2, 0.3)],
            "low": [(0.3, 0.62, 0.28, 0.34), (0.66, 0.6, 0.3, 0.36), (0.5, 0.52, 0.22, 0.3)],
            "arch": [(0.28, 0.5, 0.24, 0.36), (0.6, 0.42, 0.3, 0.38), (0.82, 0.62, 0.16, 0.3)],
        }[shape]
        for k, (x, y, rx, ry) in enumerate(clusters):
            leaf_mass(c, w * x, h * y, w * rx, h * ry, colors[k % len(colors)], density=1.2, grain=0.55, dark=dark)
    for _ in range(bare):
        x = rnd.uniform(w * 0.2, w * 0.8)
        y = rnd.uniform(h * 0.2, h * 0.5)
        c.line([(x, y), (x + rnd.uniform(-10, 10), y - rnd.uniform(6, 14))], wood[0], 1)
    if berries:
        tones = ramp(berries, 4)
        for _ in range(int(w * h / 260)):
            x, y = rnd.uniform(w * 0.12, w * 0.88), rnd.uniform(h * 0.2, h * 0.9)
            if c.img.getpixel((int(x), int(y)))[3]:
                c.rect(x, y, x + 3, y + 3, tones[1])
                c.pixel(x, y, tones[3])
    c.rect(w * 0.15, h - 2, w * 0.85, h, ramp(outline_base, 4)[0])
    return c.finish(darker(outline_base, 0.35))


def fern(size, rnd, colors, fronds=7, spread=1.0, outline_base=GREEN):
    """Fougère : frondes arquées depuis le pied, folioles de plus en plus courtes vers la pointe."""
    w, h = size
    c = Canvas(w, h, rnd)
    for k in range(fronds):
        t = (k + 0.5) / fronds
        angle = math.pi * (1.08 - 1.16 * t) * spread + (1 - spread) * math.pi / 2
        length = h * rnd.uniform(0.85, 1.05) * (0.8 + 0.4 * math.sin(math.pi * t))
        tones = ramp(colors[k % len(colors)], 4)
        x, y = w / 2.0, h - 1.0
        pts = []
        for s in range(14):
            u = s / 13.0
            a = angle - (u ** 1.6) * 0.9 * (1 if math.cos(angle) > 0 else -1) * 0.6
            x += math.cos(a) * length / 13.0 * min(1.0, (w * 0.5) / max(1.0, length * abs(math.cos(angle)) + 1))
            y -= math.sin(a) * length / 13.0 * 0.95
            pts.append((x, max(1.0, y + (u ** 2) * h * 0.25)))
        prev = (w / 2.0, h - 1.0)
        for s, p in enumerate(pts):
            c.line([prev, p], tones[1], 2 if s < 6 else 1)
            u = s / 13.0
            leaflet = (1.0 - u) * w * 0.07 + 2
            dx, dy = p[0] - prev[0], p[1] - prev[1]
            n = math.hypot(dx, dy) or 1.0
            nx, ny = -dy / n, dx / n
            for side in (1, -1):
                c.line([p, (p[0] + side * nx * leaflet + dx * 0.4, p[1] + side * ny * leaflet + dy * 0.4)],
                       tones[3 if side * nx < 0 else 2], 2)
            prev = p
    return c.finish(darker(outline_base, 0.35))


def grass_clump(size, rnd, base, count=24, ears=0, droop=0.0, slant=0.0):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(base, 5)
    for _ in range(count):
        x = w * 0.5 + rnd.gauss(0, w * 0.16)
        top = h * rnd.uniform(0.02, 0.45)
        lean = rnd.uniform(-w * 0.18, w * 0.18) + slant * w
        mid = (x + lean * 0.5, (h + top) / 2.0)
        tip = (x + lean, top + droop * h * rnd.uniform(0.2, 0.5))
        c.line([(x, h), mid, tip], tones[rnd.randint(1, 4)], 1 if rnd.random() < 0.5 else 2)
    for _ in range(ears):
        x = w * 0.5 + rnd.gauss(0, w * 0.15)
        top = h * rnd.uniform(0.0, 0.2)
        lean = rnd.uniform(-w * 0.1, w * 0.2)
        c.line([(x, h), (x + lean, top + 6)], tones[2], 1)
        for k in range(4):
            c.rect(x + lean + (k % 2) - 1, top + k * 2, x + lean + (k % 2) + 1, top + k * 2 + 2, ramp("grass_gold", 4)[3])
    return c.finish(darker(base, 0.4))


def flowers_tuft(size, rnd, petal, center, count, stem="grass", plume=False):
    w, h = size
    c = Canvas(w, h, rnd)
    lt = ramp(stem, 4)
    pt = ramp(petal, 4)
    heads = []
    for _ in range(count):
        x = w * 0.5 + rnd.gauss(0, w * 0.18)
        top = h * rnd.uniform(0.05, 0.45)
        tip = (x + rnd.uniform(-5, 5), top)
        c.line([(x, h), tip], lt[rnd.randint(1, 3)], 1)
        heads.append(tip)
    for x, y in heads:
        if plume:
            for k in range(6):
                c.rect(x - 2 + rnd.randint(-1, 1), y + k * 2, x + 1 + rnd.randint(0, 2), y + k * 2 + 2, pt[rnd.randint(2, 3)])
        else:
            for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
                c.rect(x + dx - 1, y + dy - 1, x + dx + 1, y + dy + 1, pt[rnd.randint(2, 3)])
            c.rect(x - 1, y - 1, x + 1, y + 1, center)
    return c.finish(darker(stem, 0.35))


def heather(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    leaf_mass(c, w * 0.5, h * 0.62, w * 0.46, h * 0.4, "#8A5A6E", density=1.3, grain=0.4)
    for _ in range(int(w * h / 10)):
        x, y = rnd.uniform(4, w - 4), rnd.uniform(4, h - 2)
        if c.img.getpixel((int(x), int(y)))[3]:
            c.rect(x, y, x + 1, y + 1, rnd.choice(["#B07AA0", "#C88AB0", "#A8603E", "#8A4A6A"]))
    return c.finish(darker("#8A5A6E", 0.4))


def cattails(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    leaves = ramp("#7A8A4A", 4)
    for _ in range(16):
        x = w * 0.5 + rnd.gauss(0, w * 0.15)
        tip = (x + rnd.uniform(-w * 0.35, w * 0.35), h * rnd.uniform(0.15, 0.5))
        c.line([(x, h), ((x + tip[0]) / 2, (h + tip[1]) / 2 - 4), tip], leaves[rnd.randint(1, 3)], 2)
    brown = ramp("#6E4A2E", 4)
    for k in range(5):
        x = w * (0.3 + 0.1 * k) + rnd.uniform(-3, 3)
        top = h * rnd.uniform(0.02, 0.15)
        c.line([(x, h), (x + rnd.uniform(-2, 2), top)], leaves[1], 1)
        c.rect(x - 3, top + 6, x + 3, top + 24, brown[1])
        c.rect(x - 3, top + 6, x - 1, top + 24, brown[3])
    return c.finish(darker("#6E4A2E", 0.4))


def reeds_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(mix("reed", "#E0D8B0", 0.35), 5)
    for _ in range(18):
        x = rnd.uniform(w * 0.15, w * 0.85)
        top = h * rnd.uniform(0.02, 0.35)
        bend = rnd.uniform(-14, 14)
        c.line([(x, h), (x + bend * 0.4, (h + top) / 2), (x + bend, top)], tones[rnd.randint(1, 4)], 2)
        if rnd.random() < 0.4:
            c.line([(x + bend, top), (x + bend + rnd.uniform(-8, 8), top - 6)], tones[4], 1)
    return c.finish(darker("reed", 0.4))


def mushrooms(size, rnd, cap, stem, kind="cep"):
    w, h = size
    c = Canvas(w, h, rnd)
    caps = ramp(cap, 5)
    stems = ramp(stem, 4)
    if kind == "cep":
        for x, s in ((0.28, 1.0), (0.58, 0.82), (0.8, 0.6)):
            cx = w * x
            c.ellipse(cx, h - 7 * s, 5 * s, 7 * s, stems[2])
            c.rect(cx - 4 * s, h - 3, cx + 4 * s, h, stems[1])
            c.blob(cx, h - 14 * s, 8 * s, 6 * s, caps[1:5])
    else:
        for k in range(6):
            cx = w * (0.15 + 0.14 * k) + rnd.uniform(-2, 2)
            s = rnd.uniform(0.6, 1.0)
            c.poly([(cx - 2, h), (cx + 2, h), (cx + 6 * s, h - 12 * s), (cx - 6 * s, h - 12 * s)], caps[2])
            c.rect(cx - 6 * s, h - 13 * s, cx + 6 * s, h - 11 * s, caps[3])
    return c.finish(darker(cap, 0.4))


def ivy_ground(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#7A5A40", 5)
    c.cylinder(w * 0.3, h * 0.3, w * 0.7, h, wood)
    c.ellipse(w * 0.5, h * 0.3, w * 0.2, h * 0.08, ramp("#C8A070", 4)[2])
    ivy = ramp(DARK_GREEN, 5)
    for _ in range(46):
        x = w * 0.5 + rnd.gauss(0, w * 0.25)
        y = h - rnd.uniform(2, h * 0.75) * (1.0 - min(1.0, abs(x - w * 0.5) / (w * 0.5)) * 0.7)
        c.blob(x, y, rnd.uniform(3, 5), rnd.uniform(2.5, 4), ivy[1:])
    return c.finish(darker(DARK_GREEN, 0.4))


def nettles(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp("#5E7A3A", 5)
    for k in range(6):
        x = w * (0.2 + 0.12 * k) + rnd.uniform(-3, 3)
        top = h * rnd.uniform(0.05, 0.3)
        c.line([(x, h), (x, top)], tones[1], 2)
        y = top + 4
        while y < h - 6:
            for side in (-1, 1):
                c.poly([(x, y), (x + side * 9, y - 3), (x + side * 11, y + 3), (x + side * 3, y + 4)], tones[2 if side > 0 else 3])
            y += rnd.randint(8, 12)
    return c.finish(darker("#5E7A3A", 0.4))


def thistle(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    dry = ramp("#A89A70", 5)
    c.line([(w * 0.5, h), (w * 0.5, h * 0.2)], dry[1], 2)
    for y, side in ((0.7, -1), (0.55, 1), (0.42, -1)):
        c.line([(w * 0.5, h * y), (w * 0.5 + side * w * 0.3, h * (y - 0.15))], dry[1], 1)
        c.blob(w * 0.5 + side * w * 0.3, h * (y - 0.17), 4, 5, ramp("#8A6A5A", 4))
    c.blob(w * 0.5, h * 0.14, 7, 8, ramp("#8A6A5A", 4))
    for k in range(7):
        a = -math.pi * (0.1 + 0.8 * k / 6.0)
        c.line([(w * 0.5, h * 0.1), (w * 0.5 + math.cos(a) * 10, h * 0.1 + math.sin(a) * 10)], dry[4], 1)
    return c.finish(darker("#8A6A5A", 0.4))


# --- Premier plan : grandes masses sombres --------------------------------------------------------


def fg_trunk(size, rnd, base, ivy=True):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(base, 5, spread=0.5)
    c.rect(w * 0.08, 0, w * 0.92, h, tones[0])
    c.rect(w * 0.14, 0, w * 0.4, h, tones[1])
    c.rect(w * 0.18, 0, w * 0.26, h, tones[2])
    for _ in range(int(h / 14)):
        x = rnd.uniform(w * 0.12, w * 0.85)
        y = rnd.uniform(0, h)
        c.line([(x, y), (x + rnd.uniform(-3, 3), y + rnd.uniform(20, 60))], darker(tones[0], 0.7), rnd.randint(2, 4))
    c.poly([(w * 0.08, h), (w * 0.0, h), (w * 0.08, h * 0.9)], tones[0])
    c.poly([(w * 0.92, h), (w * 1.0, h), (w * 0.92, h * 0.88)], tones[0])
    c.poly([(w * 0.6, h * 0.06), (w * 1.0, 0), (w * 1.0, h * 0.04), (w * 0.62, h * 0.12)], tones[1])
    if ivy:
        leaves = ramp(mix(DARK_GREEN, "#1A2418", 0.35), 4)
        for k in range(70):
            y = h * (1.0 - k / 70.0)
            c.blob(w * 0.5 + math.sin(k * 0.45) * w * 0.3, y, rnd.uniform(5, 8), rnd.uniform(4, 6), leaves)
    return c.finish(darker(base, 0.5))


def fg_fern(size, rnd):
    return fern(size, rnd, [mix(DARK_GREEN, "#141A14", 0.45), mix(GREEN, "#141A14", 0.5)], fronds=9, outline_base="#141A14")


def fg_grass(size, rnd):
    return grass_clump(size, rnd, mix("grass_gold", "#2A2420", 0.62), count=70, ears=10, droop=0.2)


def fg_bush(size, rnd):
    return shrub(size, rnd, [mix("leaf_rust", "#1E1418", 0.35), mix("leaf_rust", "#2A1A18", 0.3)], shape="low",
                 outline_base="#1E1418", dark=0.45)


# --- Rochers et bords (section 8) ---------------------------------------------------------------


def _block(c, pts, base, rnd, moss=0, lichen=0):
    """Bloc de pierre polygonal : face, dessus éclairé, arêtes émoussées, mousse et lichen."""
    tones = ramp(base, 6, spread=0.45)
    c.poly(pts, tones[2])
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    cx, top = (min(xs) + max(xs)) / 2.0, min(ys)
    lit = [(x, y) for x, y in pts if x < cx + (max(xs) - cx) * 0.2]
    if len(lit) >= 3:
        c.poly(lit + [(cx - (cx - min(xs)) * 0.1, max(ys))], tones[3])
    upper = [(x, y) for x, y in pts if y < top + (max(ys) - top) * 0.3]
    if len(upper) >= 2:
        c.poly(upper + [(max(xs) - (max(xs) - cx) * 0.4, top + (max(ys) - top) * 0.32),
                        (min(xs) + (cx - min(xs)) * 0.3, top + (max(ys) - top) * 0.35)], tones[4])
    for _ in range(3):
        x = rnd.uniform(min(xs) + 6, max(xs) - 6)
        y = rnd.uniform(top + 8, max(ys) - 8)
        c.line([(x, y), (x + rnd.uniform(-6, 6), y + rnd.uniform(6, 16))], tones[0])
    mt = ramp("#6E8C4A", 4)
    placed = 0
    for _ in range(moss * 6):
        if placed >= moss:
            break
        x = rnd.uniform(min(xs) + 8, max(xs) - 8)
        y = top + rnd.uniform(2, (max(ys) - top) * 0.3)
        if 0 <= x < c.w and 0 <= y + 4 < c.h and c.img.getpixel((int(x), int(y) + 4))[3] and c.img.getpixel((int(x), max(0, int(y) - 6)))[3] == 0:
            c.blob(x, y, rnd.uniform(4, 10), rnd.uniform(3, 5), mt)
            placed += 1
    for _ in range(lichen):
        x = rnd.uniform(min(xs) + 4, max(xs) - 4)
        y = rnd.uniform(top + 4, max(ys) - 4)
        if 0 <= x < c.w and 0 <= y < c.h and c.img.getpixel((int(x), int(y)))[3]:
            c.rect(x, y, x + 2, y + 2, rnd.choice(["#D8D0A0", "#C8C88A"]))


def textured_stone(c, rnd, amount=0.18):
    """Grain de la pierre : taches claires et sombres en paliers sur tout le dessin, pied assombri."""
    c.img = shade_texture(c.img, rnd, amount, cells=5)
    foot_shade = Image.new("L", (c.w, c.h), 0)
    foot_shade.putdata([70 if (y > c.h * 0.86 or (y > c.h * 0.78 and (x + y) % 2 == 0)) else 0
                        for y in range(c.h) for x in range(c.w)])
    c.img.paste(Image.new("RGBA", (c.w, c.h), (40, 30, 50, 255)), (0, 0), ImageChops.multiply(foot_shade, c.img.getchannel("A")))
    alpha = c.img.getchannel("A")
    for _ in range(int(c.w * c.h / 40)):
        x, y = rnd.randrange(c.w), rnd.randrange(c.h)
        if alpha.getpixel((x, y)) > 128:
            r, g, b, _a = c.img.getpixel((x, y))
            f = rnd.choice([0.86, 0.9, 1.08])
            c.img.putpixel((x, y), (min(255, int(r * f)), min(255, int(g * f)), min(255, int(b * f)), 255))


def boulder_a(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _block(c, [(w * 0.04, h), (w * 0.02, h * 0.55), (w * 0.12, h * 0.2), (w * 0.4, h * 0.04), (w * 0.72, h * 0.06),
               (w * 0.92, h * 0.28), (w * 0.98, h * 0.7), (w * 0.95, h)], "stone", rnd, moss=10, lichen=24)
    textured_stone(c, rnd)
    return c.finish(darker("stone_dark", 0.45))


def boulder_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _block(c, [(w * 0.04, h), (w * 0.06, h * 0.3), (w * 0.2, h * 0.04), (w * 0.46, h * 0.02), (w * 0.47, h)], "stone",
           rnd, moss=4, lichen=10)
    _block(c, [(w * 0.53, h), (w * 0.52, h * 0.08), (w * 0.78, h * 0.1), (w * 0.94, h * 0.34), (w * 0.97, h)],
           mix("stone", "stone_dark", 0.2), rnd, moss=4, lichen=10)
    c.rect(w * 0.47, h * 0.1, w * 0.53, h, ramp("stone_dark", 4)[0])
    fern_img = fern((int(w * 0.5), int(h * 0.5)), rnd, [GREEN, "#7A9A48"], fronds=5)
    c.img.alpha_composite(fern_img, (int(w * 0.25), int(h * 0.12)))
    textured_stone(c, rnd)
    return c.finish(darker("stone_dark", 0.45))


def boulder_c(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _block(c, [(w * 0.02, h), (w * 0.08, h * 0.62), (w * 0.5, h * 0.12), (w * 0.86, h * 0.04), (w * 0.98, h * 0.3),
               (w * 0.96, h)], mix("stone", "stone_dark", 0.15), rnd, moss=6, lichen=16)
    grass = ramp(GREEN, 4)
    for _ in range(30):
        x = rnd.uniform(0, w)
        c.line([(x, h), (x + rnd.uniform(-3, 3), h - rnd.uniform(4, 12))], grass[rnd.randint(1, 3)])
    textured_stone(c, rnd)
    return c.finish(darker("stone_dark", 0.45))


def boulder_d(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    rock_shape(c, w * 0.5, h, w * 0.95, h * 0.92, mix("stone", "stone_dark", 0.4), moss=True)
    for x in (0.2, 0.62):
        fern_img = fern((int(w * 0.36), int(h * 0.42)), rnd, [GREEN, DARK_GREEN], fronds=6)
        c.img.alpha_composite(fern_img, (int(w * x), int(h * 0.02)))
    ivy = ramp(DARK_GREEN, 4)
    for k in range(40):
        c.blob(w * (0.75 + 0.1 * math.sin(k)), h * (0.3 + 0.017 * k), 4, 3, ivy)
    textured_stone(c, rnd)
    return c.finish(darker("stone_dark", 0.45))


def rock_small(size, rnd, base, count=1, flat=False, moss=False, angular=False):
    w, h = size
    c = Canvas(w, h, rnd)
    for k in range(count):
        ww = w * (0.96 if count == 1 else 0.55)
        x = w * (0.5 if count == 1 else 0.3 + 0.42 * k)
        hh = h * (0.95 if count == 1 or k == 0 else 0.7)
        if angular:
            _block(c, [(x - ww / 2, h), (x - ww * 0.42, h - hh * 0.6), (x - ww * 0.1, h - hh), (x + ww * 0.3, h - hh * 0.75),
                       (x + ww / 2, h)], base, rnd)
        else:
            rock_shape(c, x, h, ww, hh * (0.55 if flat else 1.0), base, moss)
    return c.finish(darker(base, 0.4))


def rock_pile(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for k in range(9):
        row = 0 if k < 5 else (1 if k < 8 else 2)
        x = w * (0.14 + 0.18 * (k if row == 0 else (k - 5 + 0.5) if row == 1 else 2)) * (1 if row == 0 else 0.92) + rnd.uniform(-4, 4)
        rock_shape(c, x, h - row * h * 0.3, rnd.uniform(36, 50), rnd.uniform(22, 32), rnd.choice(["stone", mix("stone", "stone_dark", 0.4)]))
    return c.finish(darker("stone_dark", 0.45))


def edge_rocks(size, rnd, crack=False):
    w, h = size
    c = Canvas(w, h, rnd)
    x = rnd.uniform(10, 30)
    while x < w - 10:
        bw = rnd.uniform(60, 120)
        bh = h * rnd.uniform(0.35, 0.8)
        base = rnd.choice(["stone", mix("stone", "stone_dark", 0.3), mix("stone", "sand", 0.2)])
        if rnd.random() < 0.6:
            rock_shape(c, x + bw / 2, h, bw, bh, base, moss=rnd.random() < 0.4)
        else:
            _block(c, [(x, h), (x + bw * 0.08, h - bh * 0.7), (x + bw * 0.35, h - bh), (x + bw * 0.8, h - bh * 0.9),
                       (x + bw, h - bh * 0.3), (x + bw * 0.95, h)], base, rnd, lichen=4)
        x += bw * rnd.uniform(0.7, 0.95)
    if crack:
        c.line([(w * 0.55, h), (w * 0.53, h * 0.6), (w * 0.57, h * 0.3)], ramp("stone_dark", 4)[0], 3)
    textured_stone(c, rnd)
    grass = ramp(GREEN, 5)
    for _ in range(int(w / 2)):
        x = rnd.uniform(0, w - 1)
        y = h * rnd.uniform(0.1, 0.6)
        if c.img.getpixel((int(x), int(y)))[3] and not c.img.getpixel((int(x), max(0, int(y) - 6)))[3]:
            c.line([(x, y + 3), (x + rnd.uniform(-4, 4), y - rnd.uniform(4, 12))], grass[rnd.randint(1, 4)])
    root = ramp("#5C4030", 4)
    for _ in range(3):
        x = rnd.uniform(w * 0.1, w * 0.9)
        c.line([(x, h * 0.35), (x + rnd.uniform(-10, 10), h * 0.7), (x + rnd.uniform(-6, 6), h)], root[1], 2)
    return c.finish(darker("stone_dark", 0.45))


def edge_roots(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    soil = ramp("#6A4E36", 5)
    c.poly([(0, h * 0.22), (w * 0.1, h * 0.08), (w * 0.9, h * 0.06), (w, h * 0.2), (w * 0.86, h * 0.36), (w * 0.14, h * 0.38)], soil[2])
    c.rect(0, h * 0.04, w, h * 0.1, ramp(GREEN, 4)[2])
    for _ in range(5):
        rock_shape(c, rnd.uniform(w * 0.1, w * 0.9), h * 0.36, rnd.uniform(16, 30), rnd.uniform(10, 18), "stone")
    root = ramp("#5C4030", 5)
    for k in range(9):
        x = w * (0.1 + 0.8 * k / 8.0)
        pts = [(x, h * 0.3)]
        y = h * 0.3
        length = h * rnd.uniform(0.4, 0.7) if k != 4 else h * 0.7
        while y < h * 0.3 + length:
            y += 8
            x += rnd.uniform(-5, 5)
            pts.append((x, min(h, y)))
        c.line(pts, root[rnd.randint(1, 2)], 3 if k % 3 == 0 else 2)
    return c.finish(darker("#5C4030", 0.45))


def edge_grass(size, rnd):
    w, h = size
    c = WrapCanvas(w, h, rnd)
    tones = ramp("grass_gold", 5)
    green = ramp(GREEN, 5)
    for _ in range(int(w * 0.9)):
        x = rnd.uniform(0, w)
        top = h * rnd.uniform(0.0, 0.5)
        lean = rnd.uniform(4, 22)
        col = rnd.choice(tones[1:] + green[2:])
        c.line([(x, h), (x + lean * 0.6, (h + top) / 2.0), (x + lean, top + rnd.uniform(0, 8))], col, 1 if rnd.random() < 0.6 else 2)
    return c.finish(darker("grass_gold", 0.4))


def wind_rock_d(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _block(c, [(w * 0.06, h), (w * 0.02, h * 0.5), (w * 0.2, h * 0.12), (w * 0.62, h * 0.04), (w * 0.94, h * 0.24),
               (w * 0.98, h * 0.7), (w * 0.9, h)], mix("stone", "sand", 0.3), rnd, lichen=8)
    dark = ramp("stone_dark", 4)
    for x, y, r in ((0.3, 0.42, 12), (0.6, 0.3, 9), (0.74, 0.6, 14), (0.45, 0.7, 7)):
        c.ellipse(w * x, h * y, r, r * 0.85, dark[0])
        c.ellipse(w * x + 1, h * y + 1, r * 0.6, r * 0.5, dark[1])
    cut = Image.new("L", size, 0)
    ImageDraw.Draw(cut).ellipse((w * 0.44, h * 0.48, w * 0.58, h * 0.68), fill=255)
    c.img.paste(Image.new("RGBA", size, (0, 0, 0, 0)), (0, 0), cut)
    textured_stone(c, rnd)
    return c.finish(darker("stone_dark", 0.45))


def floating_rock_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(mix("stone", "#7A6A80", 0.3), 5)
    c.poly([(w * 0.12, h * 0.3), (w * 0.88, h * 0.28), (w * 0.7, h * 0.62), (w * 0.52, h * 0.72), (w * 0.34, h * 0.6)], tones[1])
    c.poly([(w * 0.14, h * 0.3), (w * 0.56, h * 0.3), (w * 0.44, h * 0.62)], tones[3])
    c.rect(w * 0.12, h * 0.24, w * 0.88, h * 0.3, ramp(GREEN, 4)[2])
    c.line([(w * 0.6, h * 0.24), (w * 0.62, h * 0.1)], ramp(GREEN, 4)[3], 2)
    root = ramp("#5C4030", 3)
    for k in range(5):
        x = w * (0.3 + 0.1 * k)
        c.line([(x, h * 0.6), (x + rnd.uniform(-6, 6), h * 0.8), (x + rnd.uniform(-4, 4), h * (0.92 if k == 2 else rnd.uniform(0.82, 0.98)))], root[1], 2)
    c.line([(w * 0.5, h * 0.7), (w * 0.5, h)], root[1], 2)
    return c.finish(darker("stone_dark", 0.4))


def floating_rock_c(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(mix("stone", "#7A6A80", 0.3), 5)
    c.poly([(w * 0.06, h * 0.46), (w * 0.94, h * 0.44), (w * 0.72, h * 0.8), (w * 0.5, h), (w * 0.36, h * 0.82)], tones[1])
    c.poly([(w * 0.08, h * 0.46), (w * 0.56, h * 0.46), (w * 0.44, h * 0.84)], tones[3])
    c.rect(w * 0.06, h * 0.4, w * 0.94, h * 0.46, ramp(GREEN, 4)[2])
    limb(c, w * 0.56, h * 0.42, w * 0.56, h * 0.22, 6, 3)
    leaf_mass(c, w * 0.56, h * 0.18, w * 0.17, h * 0.13, "leaf_gold", density=1.1, grain=0.6)
    root = ramp("#5C4030", 3)
    for k in range(4):
        x = w * (0.32 + 0.1 * k)
        c.line([(x, h * 0.78), (x + rnd.uniform(-6, 6), h * 0.94)], root[1], 2)
    return c.finish(darker("stone_dark", 0.4))


RECIPES = {
    "props/oak_a": oak_a, "props/oak_b": oak_b, "props/oak_c": oak_c, "props/oak_d": oak_d,
    "props/beech_a": beech_a, "props/beech_b": beech_b, "props/beech_c": beech_c,
    "props/maple_a": maple_a, "props/maple_b": maple_b, "props/maple_c": maple_c,
    "props/birch_a": birch_a, "props/birch_b": birch_b,
    "props/pine_small_a": pine_small_a, "props/pine_small_b": pine_small_b, "props/pine_tall_b": pine_tall_b,
    "props/pine_dead": pine_dead, "props/dead_tree_a": dead_tree_a, "props/dead_tree_b": dead_tree_b,
    "props/sapling_a": sapling_a, "props/sapling_b": sapling_b, "props/willow": willow,
    "props/lone_tree_b": lone_tree_b,
    "props/forest_wall_a": forest_wall_a, "props/forest_wall_b": forest_wall_b, "props/forest_wall_c": forest_wall_c,
    "props/forest_wall_d": forest_wall_d, "props/treeline_autumn_a": treeline_autumn_a,
    "props/treeline_autumn_b": treeline_autumn_b,
    "props/bush_b": lambda s, r: shrub(s, r, ["#B8A848", "#7A9A48"], "upright", stems=5),
    "props/bush_c": lambda s, r: shrub(s, r, ["leaf_rust", "#9A5A36"], "dome", bare=7, outline_base="leaf_rust"),
    "props/bush_d": lambda s, r: shrub(s, r, ["#A8402E", "#8A3A2E", "#6E7A3A"], "low", berries="#2A2030",
                                       outline_base="#6E3A2E"),
    "props/bush_e": lambda s, r: shrub(s, r, ["#3E5A44"], "cone", outline_base="#2E4234"),
    "props/bush_f": lambda s, r: shrub(s, r, ["#C8763A", "#B8603A"], "arch", berries="#C0302A", stems=4,
                                       outline_base="#8A4A2E"),
    "props/fern_a": lambda s, r: fern(s, r, ["#B8642E", "#A8582E", "#C87A3A"], fronds=8, outline_base="#8A4A2E"),
    "props/fern_b": lambda s, r: fern(s, r, ["#6E8A3A", "#B8642E"], fronds=7),
    "props/fern_c": lambda s, r: fern(s, r, ["#6E9A48", "#5E8A3A"], fronds=6),
    "props/fern_d": lambda s, r: fern(s, r, [DARK_GREEN, "#2E4A2E"], fronds=10, outline_base="#1E2A1E"),
    "props/grass_clump_a": lambda s, r: grass_clump(s, r, "#A8A848", count=26, ears=4),
    "props/grass_clump_b": lambda s, r: grass_clump(s, r, "grass_gold", count=18),
    "props/grass_clump_c": lambda s, r: grass_clump(s, r, "#9AA048", count=36, ears=6, droop=0.35),
    "props/grass_clump_d": lambda s, r: grass_clump(s, r, "#7A8A48", count=14),
    "props/wildflowers_a": lambda s, r: flowers_tuft(s, r, "#E2B830", "#C89020", 9, plume=True),
    "props/wildflowers_b": lambda s, r: flowers_tuft(s, r, "#A88AC8", "#E8C048", 10),
    "props/heather": heather,
    "props/myosotis_b": lambda s, r: flowers_tuft(s, r, "myosotis", "#F2D06B", 16),
    "props/myosotis_c": lambda s, r: flowers_tuft(s, r, "myosotis", "#F2D06B", 6),
    "props/cattails": cattails, "props/reeds_b": reeds_b,
    "props/mushroom_cep": lambda s, r: mushrooms(s, r, "#7A4A2A", "#E2D6B8"),
    "props/mushroom_chanterelle": lambda s, r: mushrooms(s, r, "#E2962E", "#E2A64E", kind="chanterelle"),
    "props/ivy_ground": ivy_ground, "props/nettles": nettles, "props/thistle": thistle,
    "props/berry_bush_b": lambda s, r: shrub(s, r, ["#5E7A3A", "#6E8A44"], "dome", berries="#3A4A8A"),
    "props/fg_trunk_a": lambda s, r: fg_trunk(s, r, "#3A2A24"),
    "props/fg_trunk_b": lambda s, r: fg_trunk(s, r, "#5A3426", ivy=False),
    "props/fg_fern": fg_fern, "props/fg_grass": fg_grass, "props/fg_bush": fg_bush,
    "props/boulder_a": boulder_a, "props/boulder_b": boulder_b, "props/boulder_c": boulder_c, "props/boulder_d": boulder_d,
    "props/rock_small_a": lambda s, r: rock_small(s, r, "stone"),
    "props/rock_small_b": lambda s, r: rock_small(s, r, mix("stone", "stone_dark", 0.2), count=2),
    "props/rock_small_c": lambda s, r: rock_small(s, r, "stone", flat=True, moss=True),
    "props/rock_small_d": lambda s, r: rock_small(s, r, mix("stone_dark", "#4A4448", 0.3), angular=True),
    "props/rock_pile": rock_pile, "props/edge_rocks_a": edge_rocks,
    "props/edge_rocks_b": lambda s, r: edge_rocks(s, r, crack=True),
    "props/edge_roots": edge_roots, "props/edge_grass": edge_grass, "props/wind_rock_d": wind_rock_d,
    "sky/floating_rock_b": floating_rock_b, "sky/floating_rock_c": floating_rock_c,
}
