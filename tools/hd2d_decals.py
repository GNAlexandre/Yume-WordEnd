"""Recettes HD-2D des décalques au sol (docs/ASSETS_HD2D_MONDE.md, section 5).

Un décalque est vu strictement de dessus, à 96 px/m, fond transparent, bord irrégulier et
effiloché qui ne touche pas les bords de l'image (sauf les bordures et les modules qui se
raccordent) ; le jeu le couche sur le sol, ancre au centre. Les ombres de feuillage, les taches
de soleil, les congères et la brume ont un alpha doux en paliers."""

import math
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from hd2d_art import Canvas, asset, darker, fractal, mix, posterize, ramp, rgba, seed_for, threshold, wrap_y
from hd2d_ground import AUTUMN, leaf_sprite

SOIL = "#5A4632"


# --- Masques ---------------------------------------------------------------------------------------


def radial(size, inset=0.06, center=(0.5, 0.5), scale=(1.0, 1.0)):
    """Dégradé elliptique : 255 au centre, 0 au bord de l'ellipse (rentrée de inset)."""
    w, h = size
    img = Image.new("L", size, 0)
    d = ImageDraw.Draw(img)
    rx = w * (0.5 - inset) * scale[0]
    ry = h * (0.5 - inset) * scale[1]
    cx, cy = w * center[0], h * center[1]
    steps = 48
    for k in range(steps):
        t = 1.0 - k / float(steps)
        d.ellipse((cx - rx * t, cy - ry * t, cx + rx * t, cy + ry * t), fill=round(255 * (1.0 - t ** 1.6)))
    return img


def organic(size, rnd, level=110, cells=6, inset=0.06, center=(0.5, 0.5), scale=(1.0, 1.0)):
    """Masque irrégulier (bruit × dégradé elliptique, seuillé) : bord effiloché, jamais au bord."""
    n = fractal(size, (cells, cells), rnd, 3)
    weight = radial(size, inset, center, scale)
    mixed = ImageChops.multiply(ImageChops.add(n, Image.new("L", size, 60)), weight)
    mask = threshold(mixed, level)
    return _clear_border(mask)


def _clear_border(mask, keep=()):
    w, h = mask.size
    d = ImageDraw.Draw(mask)
    if "left" not in keep:
        d.line((0, 0, 0, h), fill=0)
    if "right" not in keep:
        d.line((w - 1, 0, w - 1, h), fill=0)
    if "top" not in keep:
        d.line((0, 0, w, 0), fill=0)
    if "bottom" not in keep:
        d.line((0, h - 1, w, h - 1), fill=0)
    return mask


def inside(img, margin=3):
    """Ramène un dessin qui touche les bords à l'intérieur de l'image (réduction au plus proche)."""
    w, h = img.size
    box = img.getchannel("A").getbbox()
    if box is None or (box[0] >= margin and box[1] >= margin and box[2] <= w - margin and box[3] <= h - margin):
        return img
    part = img.crop(box)
    scale = min((w - 2 * margin) / float(part.width), (h - 2 * margin) / float(part.height), 1.0)
    part = part.resize((max(1, int(part.width * scale)), max(1, int(part.height * scale))), Image.NEAREST)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(part, ((w - part.width) // 2, (h - part.height) // 2))
    return out


def fill(mask, texture):
    out = Image.new("RGBA", mask.size, (0, 0, 0, 0))
    out.paste(texture, (0, 0), mask)
    return out


def rim(img, color, inner=True):
    """Liseré de 1 px au bord de la silhouette (intérieur : contour sombre du décalque)."""
    a = img.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    if inner:
        ring = ImageChops.subtract(a, a.filter(ImageFilter.MinFilter(3)))
    else:
        ring = ImageChops.subtract(a.filter(ImageFilter.MaxFilter(3)), a)
    out = img.copy()
    out.paste(Image.new("RGBA", img.size, rgba(color)), (0, 0), ring)
    return out


def texture(size, rnd, base, n=4, cells=10, dither=80):
    return posterize(fractal(size, (cells, cells), rnd, 3), ramp(base, n + 1, spread=0.45)[0:n], dither=dither)


def place(img, sprite, x, y):
    """Colle un petit dessin centré en (x, y)."""
    img.alpha_composite(sprite, (int(x - sprite.width / 2), int(y - sprite.height / 2))) if (
        0 <= int(x - sprite.width / 2) and 0 <= int(y - sprite.height / 2)
        and int(x - sprite.width / 2) + sprite.width <= img.width
        and int(y - sprite.height / 2) + sprite.height <= img.height) else None


# --- Feuilles, racines, branches (lot A) ----------------------------------------------------------


def leaves(size, rnd, colors, count, spread=(0.22, 0.22), shape="pile", empty_center=False):
    """Tas de feuilles : dense au centre, feuilles isolées autour ; traînée, croissant ou épars."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    for _ in range(count):
        if shape == "crescent":
            a = rnd.uniform(math.pi * 0.1, math.pi * 0.9)
            r = rnd.gauss(1.0, 0.12)
            x = w * 0.5 + math.cos(a) * w * 0.36 * r
            y = h * 0.25 + math.sin(a) * h * 0.55 * r
        elif shape == "streak":
            t = rnd.random()
            x = w * (0.12 + 0.76 * t) + rnd.gauss(0, w * 0.04)
            y = h * (0.62 - 0.26 * t) + rnd.gauss(0, h * 0.1 * (1.2 - t))
        elif shape == "scatter":
            x, y = rnd.uniform(w * 0.06, w * 0.94), rnd.uniform(h * 0.06, h * 0.94)
            if empty_center and ((x - w / 2) / (w * 0.22)) ** 2 + ((y - h / 2) / (h * 0.22)) ** 2 < 1:
                continue
        else:
            x = w * 0.5 + rnd.gauss(0, w * spread[0])
            y = h * 0.5 + rnd.gauss(0, h * spread[1])
        leaf = leaf_sprite(rnd, rnd.choice([6, 8, 9, 10, 11, 12]), rnd.choice(colors))
        place(img, leaf, x, y)
    return img


def roots(size, rnd, thick=True):
    """Racines : grosses racines qui sortent du sol et s'y renfoncent (tronçons et bourrelets de
    terre), ou racines fines en étoile."""
    w, h = size
    c = Canvas(w, h, rnd)
    bark = ramp("#6A4C36", 5)
    soil = ramp(SOIL, 4)
    if thick:
        for k in range(3):
            y0 = h * (0.3 + 0.2 * k) + rnd.uniform(-8, 8)
            pts = [(w * 0.06 + s * w * 0.11, y0 + math.sin(s * 0.9 + k * 2) * h * 0.08) for s in range(9)]
            width = rnd.uniform(14, 20) * (1.0 - 0.15 * k)
            hidden = {rnd.randint(2, 3), rnd.randint(5, 6)}
            for s in range(8):
                wd = width * (1.0 - s / 12.0)
                c.line([pts[s], pts[s + 1]], bark[1], int(wd))
                c.line([(pts[s][0], pts[s][1] - wd * 0.3), (pts[s + 1][0], pts[s + 1][1] - wd * 0.3)], bark[3], max(1, int(wd * 0.3)))
            # La racine plonge sous un bourrelet de terre puis ressort.
            for s in hidden:
                mx, my = (pts[s][0] + pts[s + 1][0]) / 2.0, (pts[s][1] + pts[s + 1][1]) / 2.0
                c.blob(mx, my, width * 0.95, width * 0.62, soil[0:4])
            for _ in range(3):
                p = pts[rnd.randrange(8)]
                if c.img.getpixel((int(p[0]), int(p[1])))[3]:
                    c.blob(p[0], p[1] - 3, rnd.uniform(4, 7), rnd.uniform(3, 4), ramp("#6E8C4A", 4))
    else:
        cx, cy = w * 0.5, h * 0.5
        for k in range(7):
            a = (k / 7.0) * 2 * math.pi + rnd.uniform(-0.3, 0.3)
            length = min(w, h) * rnd.uniform(0.32, 0.44)
            pts = [(cx + math.cos(a) * length * t - math.sin(a) * math.sin(t * 3 + k) * 5,
                    cy + math.sin(a) * length * t + math.cos(a) * math.sin(t * 3 + k) * 5) for t in [s / 8.0 for s in range(9)]]
            for s in range(8):
                c.line([pts[s], pts[s + 1]], bark[1], max(2, int(7 * (1.0 - s / 9.0))))
        c.blob(cx, cy, 14, 12, bark[1:5])
    return inside(c.finish(darker("#6A4C36", 0.5)))


def branches(size, rnd, big=False):
    w, h = size
    c = Canvas(w, h, rnd)
    bark = ramp("#7A5A42", 5)
    sticks = 1 if big else 6
    for k in range(sticks):
        if big:
            x0, y0, x1, y1 = w * 0.06, h * 0.62, w * 0.92, h * 0.4
            width = 12
        else:
            x0, y0 = rnd.uniform(w * 0.1, w * 0.5), rnd.uniform(h * 0.2, h * 0.8)
            a = rnd.uniform(-0.5, 0.5)
            length = rnd.uniform(w * 0.3, w * 0.6)
            x1, y1 = x0 + math.cos(a) * length, y0 + math.sin(a) * length * 0.6
            width = rnd.randint(2, 4)
        c.line([(x0, y0), (x1, y1)], bark[1], width)
        c.line([(x0, y0 - width * 0.3), (x1, y1 - width * 0.3)], bark[3], max(1, width // 3))
        for _ in range(4 if not big else 9):
            t = rnd.uniform(0.2, 0.9)
            bx, by = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            a = rnd.choice([-1, 1]) * rnd.uniform(0.5, 1.1) + math.atan2(y1 - y0, x1 - x0)
            length = rnd.uniform(8, 22) * (2.0 if big else 1.0)
            ex, ey = bx + math.cos(a) * length, by + math.sin(a) * length
            ex, ey = min(w - 4, max(3, ex)), min(h - 4, max(3, ey))
            c.line([(bx, by), (ex, ey)], bark[2], 2 if big else 1)
            if big:
                for _ in range(3):
                    lf = leaf_sprite(rnd, rnd.randint(6, 10), rnd.choice(AUTUMN))
                    c.img.alpha_composite(lf, (int(min(w - lf.width - 1, max(1, ex - lf.width / 2 + rnd.uniform(-6, 6)))),
                                               int(min(h - lf.height - 1, max(1, ey - lf.height / 2 + rnd.uniform(-6, 6))))))
    return inside(c.finish(darker("#7A5A42", 0.5)))


def shadow(size, rnd, sparse=False):
    """Ombre de feuillage : taches brun violacé (alpha 30 à 60 %) percées de trouées rondes."""
    w, h = size
    n = fractal(size, (6, 6), rnd, 4, gain=0.6)
    weight = radial(size, 0.02).point(lambda v: min(255, v * 3))
    blot = ImageChops.multiply(n, weight)
    level = 130 if sparse else 100
    a = blot.point(lambda v: 0 if v < level else (77 if v < level + 20 else (115 if v < level + 45 else 150)))
    holes = Image.new("L", size, 0)
    hd = ImageDraw.Draw(holes)
    for _ in range(26 if sparse else 16):
        x, y, r = rnd.uniform(0, w), rnd.uniform(0, h), rnd.uniform(6, 26)
        hd.ellipse((x - r, y - r * 0.85, x + r, y + r * 0.85), fill=255)
    a = ImageChops.subtract(a, holes)
    img = Image.new("RGBA", size, rgba("#3A2A40"))
    img.putalpha(_clear_border(a))
    return img


def sun_dapple(size, rnd):
    w, h = size
    a = Image.new("L", size, 0)
    d = ImageDraw.Draw(a)
    weight = radial(size, 0.04)
    for _ in range(42):
        x, y = rnd.uniform(w * 0.08, w * 0.92), rnd.uniform(h * 0.08, h * 0.92)
        r = rnd.uniform(5, 30)
        if weight.getpixel((int(x), int(y))) < 40:
            continue
        d.ellipse((x - r, y - r * rnd.uniform(0.6, 1.0), x + r, y + r * rnd.uniform(0.6, 1.0)), fill=90)
        d.ellipse((x - r * 0.55, y - r * 0.45, x + r * 0.55, y + r * 0.45), fill=125)
    img = Image.new("RGBA", size, rgba("crystal"))
    img.putalpha(_clear_border(a))
    return img


def patch(size, rnd, base, accents=(), accent_count=0, level=110, cells=6, dots=None):
    """Plaque végétale (mousse, trèfle, fleurs, aiguilles) : masque irrégulier, texture, touches."""
    w, h = size
    mask = organic(size, rnd, level, cells)
    img = fill(mask, texture(size, rnd, base))
    alpha = mask
    for _ in range(accent_count):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if alpha.getpixel((x, y)):
            col = rnd.choice(accents)
            if dots == "flower":
                for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                    if 0 <= x + dx < w and 0 <= y + dy < h:
                        img.putpixel((x + dx, y + dy), rgba(col))
                img.putpixel((x, y), rgba("#F2D06B"))
            elif dots == "needle":
                d = ImageDraw.Draw(img)
                a = rnd.uniform(0, math.pi)
                d.line((x, y, x + math.cos(a) * 5, y + math.sin(a) * 5), fill=rgba(col))
            else:
                img.putpixel((x, y), rgba(col))
    img = rim(img, darker(base, 0.6))
    return img


# --- Sol : cailloux, flaques, fissures (lot B) -----------------------------------------------------


def pebbles(size, rnd, count, streak=False):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    for _ in range(count):
        if streak:
            t = rnd.random()
            x = w * (0.1 + 0.8 * t)
            y = h * 0.5 + math.sin(t * 3) * h * 0.15 + rnd.gauss(0, h * 0.12)
        else:
            x, y = w * 0.5 + rnd.gauss(0, w * 0.2), h * 0.5 + rnd.gauss(0, h * 0.2)
        r = rnd.uniform(1.5, 4.0) if streak else rnd.uniform(2, 4)
        c = Canvas(int(2 * r) + 4, int(2 * r) + 4, rnd)
        base = rnd.choice([mix("stone", "stone_dark", 0.35), mix("stone", "stone_dark", 0.6), "stone_dark"])
        c.blob(c.w / 2.0, c.h / 2.0, r, r * rnd.uniform(0.7, 0.95), ramp(base, 5, spread=0.35)[0:4])
        place(img, c.finish(darker(base, 0.55)), x, y)
    return img


def puddle(size, rnd):
    w, h = size
    mask = organic(size, rnd, 120, 5, inset=0.05)
    inner = mask.filter(ImageFilter.MinFilter(5))
    img = fill(mask, texture(size, rnd, "#4A3A2A", 3))
    water = texture(size, rnd, mix("marsh", "#5A5060", 0.4), 3, cells=4, dither=40)
    img.paste(water, (0, 0), inner)
    d = ImageDraw.Draw(img)
    for _ in range(int(w * h / 300)):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if inner.getpixel((x, y)):
            n = rnd.randint(2, 6)
            col = rnd.choice(["#F2C8A8", "#E8B898", "#C8A8B8"])
            d.line((x, y, min(w - 1, x + n), y), fill=rgba(col))
    img.putalpha(mask)
    return rim(img, "#3A2A20")


def mud_patch(size, rnd):
    w, h = size
    mask = organic(size, rnd, 110, 6)
    img = fill(mask, texture(size, rnd, "#6A5038", 4))
    d = ImageDraw.Draw(img)
    for k in range(8):
        x = w * (0.2 + 0.08 * k) + rnd.uniform(-4, 4)
        y = h * (0.7 - 0.05 * k) + (6 if k % 2 else -6)
        if mask.getpixel((int(x), int(y))):
            d.ellipse((x - 3, y - 5, x + 3, y + 5), fill=rgba("#3E2E22"))
            d.ellipse((x - 2, y - 7, x + 2, y - 5), fill=rgba("#3E2E22"))
    img.putalpha(mask)
    return rim(img, "#4A3626")


def cracks(size, rnd, count=4, grass=True):
    w, h = size
    c = Canvas(w, h, rnd)
    dark = ramp("#2E2620", 3)

    def crack(x, y, a, length, width, depth):
        if depth == 0 or length < 4:
            return
        pts = [(x, y)]
        for _ in range(int(length / 6)):
            a += rnd.uniform(-0.4, 0.4)
            x += math.cos(a) * 6
            y += math.sin(a) * 6
            pts.append((min(w - 3, max(2, x)), min(h - 3, max(2, y))))
        c.line(pts, dark[1], max(1, int(width)))
        if grass and width >= 3:
            for px, py in pts[1:-1:2]:
                c.line([(px, py), (px + rnd.uniform(-3, 3), py - rnd.uniform(2, 5))], ramp("#6E8C4A", 3)[1])
        for _ in range(2):
            k = rnd.randrange(len(pts))
            crack(pts[k][0], pts[k][1], a + rnd.choice([-1, 1]) * rnd.uniform(0.5, 1.2), length * 0.5, width * 0.6, depth - 1)

    for _ in range(count):
        crack(w * 0.5 + rnd.uniform(-w * 0.15, w * 0.15), h * 0.5 + rnd.uniform(-h * 0.15, h * 0.15),
              rnd.uniform(0, 2 * math.pi), min(w, h) * 0.45, 4 if count > 2 else 3, 3)
    return inside(c.finish(darker("#2E2620", 0.8)))


def stepping_stones(size, rnd):
    w, h = size
    mask = organic(size, rnd, 90, 5, scale=(1.0, 0.8))
    img = fill(mask, texture(size, rnd, mix("marsh", "#8AB0A8", 0.3), 3, cells=5, dither=40))
    d = ImageDraw.Draw(img)
    for _ in range(int(w * h / 200)):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if mask.getpixel((x, y)):
            d.line((x, y, min(w - 1, x + rnd.randint(2, 6)), y), fill=rgba(mix("marsh", "#F0F0E0", 0.6)))
    img.putalpha(mask)
    img = rim(img, darker("marsh", 0.6))
    for k in range(4):
        x = w * (0.18 + 0.21 * k) + rnd.uniform(-6, 6)
        y = h * 0.5 + rnd.uniform(-h * 0.12, h * 0.12)
        c = Canvas(64, 50, rnd)
        c.blob(32, 25, rnd.uniform(20, 28), rnd.uniform(14, 19), ramp(mix("stone", "stone_dark", 0.3), 5)[1:])
        place(img, c.finish(darker("stone_dark", 0.5)), x, y)
    return img


def lily_pads(size, rnd):
    w, h = size
    mask = organic(size, rnd, 105, 5)
    img = fill(mask, texture(size, rnd, mix("marsh", "#2A3A34", 0.4), 3, cells=6, dither=40))
    for _ in range(int(w * h / 22)):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if mask.getpixel((x, y)):
            img.putpixel((x, y), rgba(rnd.choice(["#7A9A48", "#8AAA50", "#6E8A40"])))
    for _ in range(7):
        x, y = w * 0.5 + rnd.gauss(0, w * 0.18), h * 0.5 + rnd.gauss(0, h * 0.16)
        r = rnd.uniform(6, 11)
        c = Canvas(int(2 * r) + 4, int(2 * r) + 4, rnd)
        c.blob(c.w / 2.0, c.h / 2.0, r, r * 0.9, ramp("#5E8A3A", 5)[1:])
        cut = [(c.w / 2.0, c.h / 2.0), (c.w / 2.0 + r + 2, c.h / 2.0 - 3), (c.w / 2.0 + r + 2, c.h / 2.0 + 3)]
        ImageDraw.Draw(c.img).polygon(cut, fill=(0, 0, 0, 0))
        place(img, c.finish(darker("#5E8A3A", 0.5)), x, y)
    img.putalpha(ImageChops.lighter(mask, img.getchannel("A")).point(lambda v: 255 if v >= 128 else 0))
    return rim(img, darker("marsh", 0.5))


def sand_drift(size, rnd):
    """Congère : sable pâle opaque au cœur, bords en alpha doux, rides allongées vers la droite."""
    w, h = size
    n = fractal(size, (6, 4), rnd, 3)
    weight = radial(size, 0.04, center=(0.46, 0.52), scale=(1.0, 0.9))
    v = ImageChops.multiply(ImageChops.add(n, Image.new("L", size, 40)), weight)
    a = v.point(lambda x: 0 if x < 60 else (80 if x < 85 else (150 if x < 105 else 255)))
    img = texture(size, rnd, "sand", 3, cells=12, dither=60)
    d = ImageDraw.Draw(img)
    tones = ramp("sand", 5)
    for _ in range(int(h / 5)):
        y = rnd.uniform(0, h)
        x = rnd.uniform(0, w * 0.6)
        d.line((x, y, x + rnd.uniform(w * 0.2, w * 0.5), y + rnd.uniform(-2, 2)), fill=rgba(tones[rnd.choice([1, 4])]))
    img.putalpha(_clear_border(a))
    return img


def ring_stone_flat(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(mix("stone_dark", "#4A4448", 0.4), 5)
    pts = []
    n = 11
    for k in range(n):
        a = 2 * math.pi * k / n
        r = rnd.uniform(0.82, 1.0)
        pts.append((w / 2.0 + math.cos(a) * (w / 2.0 - 3) * r, h / 2.0 + math.sin(a) * (h / 2.0 - 3) * r))
    c.poly(pts, tones[2])
    c.poly([(x * 0.85 + w * 0.06, y * 0.85 + h * 0.05) for x, y in pts], tones[3])
    for _ in range(int(w * h / 30)):
        x, y = rnd.uniform(4, w - 4), rnd.uniform(4, h - 4)
        if c.img.getpixel((int(x), int(y)))[3]:
            c.rect(x, y, x + rnd.randint(1, 3), y + 1, rnd.choice(["#C8C49A", "#A8A88A", tones[1]]))
    return c.finish(darker("stone_dark", 0.4))


def chalk(size, rnd, kind):
    w, h = size
    c = Canvas(w, h, rnd)
    colors = ["#ECE6D8", "#E8D0D8", "#D8E0EC", "#ECE6D8"]

    def stroke(points, col=None):
        col = col or colors[0]
        c.line(points, col, 2)

    if kind == "drawings":
        cx, cy = w * 0.28, h * 0.3
        pts = [(cx + math.cos(a / 20.0 * 2 * math.pi) * 16, cy + math.sin(a / 20.0 * 2 * math.pi) * 16) for a in range(21)]
        stroke(pts, "#F0E0A0")
        for k in range(8):
            a = k / 8.0 * 2 * math.pi
            stroke([(cx + math.cos(a) * 22, cy + math.sin(a) * 22), (cx + math.cos(a) * 30, cy + math.sin(a) * 30)], "#F0E0A0")
        fx, fy = w * 0.72, h * 0.32
        for k in range(5):
            a = k / 5.0 * 2 * math.pi
            stroke([(fx + math.cos(a) * 5 + math.cos(a + 0.6) * 8, fy + math.sin(a) * 5 + math.sin(a + 0.6) * 8),
                    (fx + math.cos(a) * 14, fy + math.sin(a) * 14), (fx + math.cos(a) * 5 + math.cos(a - 0.6) * 8,
                                                                    fy + math.sin(a) * 5 + math.sin(a - 0.6) * 8)], colors[1])
        stroke([(fx, fy + 14), (fx, fy + 40)], "#C8E0C0")
        gx, gy = w * 0.5, h * 0.72
        stroke([(gx, gy - 20), (gx, gy + 12)])
        stroke([(gx - 7, gy - 26), (gx + 7, gy - 26), (gx + 7, gy - 14), (gx - 7, gy - 14), (gx - 7, gy - 26)])
        stroke([(gx, gy + 12), (gx - 8, gy + 24)])
        stroke([(gx, gy + 12), (gx + 8, gy + 24)])
        stroke([(gx - 10, gy - 4), (gx + 10, gy - 4)])
        for side in (-1, 1):
            stroke([(gx, gy - 8), (gx + side * 26, gy - 26), (gx + side * 30, gy - 6), (gx, gy - 4)], colors[2])
    else:
        bw, bh = w * 0.34, h * 0.13
        cx = w / 2.0
        boxes = []
        y = h * 0.86
        for row, double in enumerate((False, False, True, False, True, False)):
            if double:
                boxes += [(cx - bw, y - bh, cx, y), (cx, y - bh, cx + bw, y)]
            else:
                boxes.append((cx - bw / 2, y - bh, cx + bw / 2, y))
            y -= bh
        for x0, y0, x1, y1 in boxes:
            stroke([(x0, y0), (x1, y0), (x1, y1), (x0, y1), (x0, y0)])
        arc = [(cx + math.cos(math.pi + a / 12.0 * math.pi) * bw / 2, y + math.sin(math.pi + a / 12.0 * math.pi) * bh * 0.8)
               for a in range(13)]
        stroke(arc)
        px, py = boxes[2][0] + bw / 2, (boxes[2][1] + boxes[2][3]) / 2
        c.blob(px, py, 4, 3, ramp("stone", 4))
    img = c.img
    alpha = img.getchannel("A")
    holes = Image.new("L", size, 0)
    holes.putdata([0 if rnd.random() < 0.82 else 255 for _ in range(w * h)])
    img.putalpha(ImageChops.subtract(alpha, holes))
    return inside(img)


def stain(size, rnd, kind):
    w, h = size
    if kind == "oil":
        mask = organic(size, rnd, 120, 5)
        img = fill(mask, texture(size, rnd, "#2A2830", 3, cells=6, dither=50))
        for _ in range(int(w * h / 40)):
            x, y = rnd.randrange(w), rnd.randrange(h)
            if mask.getpixel((x, y)):
                img.putpixel((x, y), rgba(rnd.choice(["#5A4A7A", "#3A6A6A", "#6A5A3A", "#4A5A8A"])))
        return img
    mask = organic(size, rnd, 115, 6, scale=(1.0, 0.7))
    img = fill(mask, texture(size, rnd, "#8A4A2A", 4, cells=8))
    d = ImageDraw.Draw(img)
    d.line((w * 0.12, h * 0.5, w * 0.88, h * 0.5), fill=rgba("#3A3434"), width=2)
    for x in range(int(w * 0.16), int(w * 0.86), 12):
        d.rectangle((x, h * 0.5 - 4, x + 1, h * 0.5 - 3), fill=rgba("#5A5050"))
    for _ in range(14):
        x = rnd.uniform(w * 0.2, w * 0.8)
        d.line((x, h * 0.5, x + rnd.uniform(-3, 3), h * 0.5 + rnd.uniform(8, h * 0.3)), fill=rgba("#7A3A22"))
    img.putalpha(mask)
    return img


def footprints(size, rnd):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for k in range(7):
        x = w * 0.5 + (10 if k % 2 else -10) + rnd.uniform(-2, 2)
        y = h - 24 - k * 38
        col = rgba("#4A3828")
        d.ellipse((x - 5, y - 8, x + 5, y + 4), fill=col)
        d.ellipse((x - 4, y + 7, x + 4, y + 14), fill=col)
        d.point((x - 2, y - 4), fill=rgba("#6A5440"))
    return img


def cart_ruts(size, rnd):
    w, h = size
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    n = fractal(size, (2, 12), rnd, 2)
    px = n.load()
    for y in range(h):
        for cx in (w * 0.24, w * 0.76):
            wob = (px[int(cx), y] - 128) / 128.0 * 5
            half = 11 + (px[int(cx) + 6, y] - 128) / 128.0 * 4
            md.line((cx + wob - half, y, cx + wob + half, y), fill=255)
    img = fill(mask, texture(size, rnd, "#5A4430", 4, cells=8))
    d = ImageDraw.Draw(img)
    for y in range(0, h, 7):
        for cx in (w * 0.24, w * 0.76):
            if mask.getpixel((int(cx), y)):
                d.line((cx - 7, y, cx + 7, y), fill=rgba("#3E2E22"))
    img = wrap_y(img, lambda im: rim(im, "#3A2A1E"))
    img.putalpha(_clear_border(img.getchannel("A"), keep=("top", "bottom")))
    return img


def drain_grate(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp(mix("stone", "stone_dark", 0.6), 5)
    for k in range(10):
        a = k / 10.0 * 2 * math.pi
        x, y = w / 2.0 + math.cos(a) * w * 0.34, h / 2.0 + math.sin(a) * h * 0.34
        c.blob(x, y, rnd.uniform(9, 12), rnd.uniform(7, 10), stone[1:])
    iron = ramp("#6A5048", 5)
    c.rect(w * 0.28, h * 0.28, w * 0.72, h * 0.72, iron[1])
    c.rect(w * 0.3, h * 0.3, w * 0.7, h * 0.7, "#1A1418")
    for k in range(5):
        x = w * (0.31 + 0.095 * k)
        c.rect(x, h * 0.3, x + 3, h * 0.7, iron[2 + k % 2])
    c.rect(w * 0.28, h * 0.28, w * 0.72, h * 0.3, iron[3])
    return c.finish(darker("#4A4448", 0.6))


def hay(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp("#D8B860", 5)
    for _ in range(140):
        x, y = w * 0.5 + rnd.gauss(0, w * 0.18), h * 0.5 + rnd.gauss(0, h * 0.16)
        a = rnd.uniform(0, math.pi)
        length = rnd.uniform(5, 14)
        x1, y1 = x + math.cos(a) * length, y + math.sin(a) * length
        if 2 < x < w - 3 and 2 < y < h - 3 and 2 < x1 < w - 3 and 2 < y1 < h - 3:
            c.line([(x, y), (x1, y1)], tones[rnd.randint(1, 4)])
    return c.img


def boardwalk(size, rnd):
    """Caillebotis : planches en travers sur deux longerons ; la suite des planches et des jours
    fait exactement la hauteur de l'image (sans raccord en haut et en bas)."""
    w, h = size
    c = Canvas(w, h, rnd)
    beam = ramp("#4A3A2E", 4)
    for x in (w * 0.22, w * 0.72):
        c.rect(x, 0, x + 8, h, beam[1])
        c.rect(x, 0, x + 2, h, beam[2])
    heights = []
    while sum(heights) < h:
        heights.append(rnd.randint(18, 24))
    heights[-1] -= sum(heights) - h
    if heights[-1] < 12:
        heights[-2] += heights.pop()
    y = 0
    for ph in heights:
        x0 = rnd.uniform(3, 8)
        x1 = w - rnd.uniform(3, 8)
        tones = ramp(mix("wood", "#8A8070", rnd.uniform(0.2, 0.6)), 5)
        top = y + rnd.randint(2, 3)
        c.rect(x0, top, x1, y + ph, tones[2])
        c.rect(x0, top, x1, top + 2, tones[3])
        c.rect(x0, y + ph - 2, x1, y + ph, tones[1])
        for nx in (w * 0.25, w * 0.75):
            c.rect(nx, (top + y + ph) / 2 - 1, nx + 2, (top + y + ph) / 2 + 1, ramp("iron", 3)[0])
        y += ph
    return wrap_y(c.img, lambda im: rim(im, darker("#4A3A2E", 0.6)))


def mist(size, rnd):
    w, h = size
    n = fractal(size, (8, 4), rnd, 3)
    weight = radial(size, 0.03)
    v = ImageChops.multiply(ImageChops.add(n, Image.new("L", size, 30)), weight)
    a = v.point(lambda x: 0 if x < 50 else (51 if x < 80 else (77 if x < 110 else 102)))
    img = Image.new("RGBA", size, rgba("#F0E0E6"))
    img.putalpha(_clear_border(a))
    return img


def garden_bed(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    soil = ramp("#4E3826", 5)
    rows = [h * 0.24, h * 0.5, h * 0.76]
    for k, y in enumerate(rows):
        pts = []
        for s in range(13):
            x = w * (0.05 + 0.9 * s / 12.0)
            pts.append((x, y - h * 0.09 + rnd.uniform(-3, 3)))
        for s in range(12, -1, -1):
            x = w * (0.05 + 0.9 * s / 12.0)
            pts.append((x, y + h * 0.09 + rnd.uniform(-3, 3)))
        c.poly(pts, soil[1])
        for _ in range(200):
            x, y2 = rnd.uniform(w * 0.06, w * 0.94), y + rnd.uniform(-h * 0.08, h * 0.08)
            c.rect(x, y2, x + 2, y2 + 1, soil[rnd.choice([0, 2, 3])])
        for s in range(9):
            x = w * (0.1 + 0.1 * s) + rnd.uniform(-4, 4)
            if k == 0:
                c.blob(x, y, 13, 11, ramp("#6E9A5A", 5)[1:])
                c.blob(x - 2, y - 2, 6, 5, ramp("#A8C890", 4)[1:])
            elif k == 1:
                for j in range(3):
                    c.line([(x - 6 + j * 6, y + 6), (x - 8 + j * 6, y - 8)], "#5E8A4A", 3)
                    c.rect(x - 7 + j * 6, y + 2, x - 4 + j * 6, y + 7, "#E0E0C8")
            elif s in (2, 6):
                c.blob(x, y, 15, 12, ramp("#D67A2A", 5)[1:])
                c.rect(x - 1, y - 14, x + 2, y - 9, "#5E7A3A")
            else:
                lf = leaf_sprite(rnd, 12, rnd.choice(["#8A7A3A", "#7A6A3A", "#A8803A"]))
                c.img.alpha_composite(lf, (int(x - lf.width / 2), int(y - lf.height / 2)))
    wood = ramp("#A08060", 4)
    c.line([(w * 0.2, h * 0.38), (w * 0.62, h * 0.4)], wood[2], 3)
    c.line([(w * 0.5, h * 0.64), (w * 0.86, h * 0.6)], wood[2], 3)
    img = c.finish(darker("#4E3826", 0.6))
    return img


# --- Table -------------------------------------------------------------------------------------------


def _edge_pair(name):
    """Bordure d'herbe (sans raccord à gauche et à droite, bord haut plein) ; grass_edge_b reprend
    les colonnes de bord de grass_edge_a pour s'y raccorder."""

    def recipe(size, rnd):
        img = grass_edge(size, rnd)
        if name == "b":
            a = grass_edge(size, random.Random(seed_for("decals/grass_edge_a")))
            band = 10
            img.paste(a.crop((0, 0, band, size[1])), (0, 0))
            img.paste(a.crop((size[0] - band, 0, size[0], size[1])), (size[0] - band, 0))
        return img
    return recipe


def grass_edge(size, rnd):
    """Bordure d'herbe : le haut reprend la tuile d'herbe livrée (même couleur que le sol voisin,
    sans raccord à gauche et à droite comme elle), touffes et brins qui avancent sur le chemin."""
    w, h = size
    grass_tile = asset("ground/grass")
    if grass_tile is None or grass_tile.width != w:
        base = posterize(fractal(size, (16, 4), rnd, 3), ramp("grass", 5, spread=0.45)[1:4], dither=90)
    else:
        base = grass_tile.crop((0, 0, w, h))
    mean = base.convert("RGB").resize((1, 1), Image.BOX).getpixel((0, 0))
    tones = ramp(mean, 5, spread=0.5)
    depth = fractal((w, 1), (12, 1), rnd, 2)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    for x in range(w):
        md.line((x, 0, x, 24 + depth.getpixel((x, 0)) * 26 // 255), fill=255)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    img.paste(base, (0, 0), mask)
    d = ImageDraw.Draw(img)
    for _ in range(int(w * 1.4)):
        x = rnd.uniform(0, w)
        y0 = 20 + depth.getpixel((int(x) % w, 0)) * 26 // 255
        length = min(rnd.uniform(6, 34), h - 4 - y0)
        lean = rnd.uniform(-6, 6)
        col = rgba(tones[rnd.randint(1, 4)])
        for dx in (-w, 0, w):
            d.line((x + dx, y0, x + dx + lean, y0 + length), fill=col, width=1)
    img.putalpha(img.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
    return img


RECIPES = {
    "decals/leaves_gold_a": lambda s, r: leaves(s, r, ["leaf_gold", "leaf_gold", "leaf_yellow", "#B88A3A"], 260),
    "decals/leaves_gold_b": lambda s, r: leaves(s, r, ["leaf_gold", "leaf_yellow"], 110, shape="streak"),
    "decals/leaves_rust_a": lambda s, r: leaves(s, r, ["leaf_rust", "leaf_rust", "#8A5A36", "#7A4A2E"], 260),
    "decals/leaves_rust_b": lambda s, r: leaves(s, r, ["leaf_rust", "#8A5A36"], 110, shape="crescent"),
    "decals/leaves_scatter": lambda s, r: leaves(s, r, AUTUMN, 150, shape="scatter", empty_center=True),
    "decals/grass_edge_a": _edge_pair("a"), "decals/grass_edge_b": _edge_pair("b"),
    "decals/canopy_shadow_a": shadow, "decals/canopy_shadow_b": lambda s, r: shadow(s, r, sparse=True),
    "decals/sun_dapple": sun_dapple,
    "decals/roots_a": roots, "decals/roots_b": lambda s, r: roots(s, r, thick=False),
    "decals/branches_a": branches, "decals/branches_b": lambda s, r: branches(s, r, big=True),
    "decals/pebbles_a": lambda s, r: pebbles(s, r, 40), "decals/pebbles_b": lambda s, r: pebbles(s, r, 120, streak=True),
    "decals/garden_bed": garden_bed,
    "decals/moss_patch_a": lambda s, r: patch(s, r, "#4F6B3A", ["#8A9440", "#6E8C4A", "#A8A848"], 500),
    "decals/moss_patch_b": lambda s, r: patch(s, r, "#566E3A", ["#8A9440", "#A8A848"], 220, level=120),
    "decals/clover_patch": lambda s, r: patch(s, r, "#6E9A48", ["#F2EEE0", "#E8E4D8"], 60, dots="flower"),
    "decals/flowers_patch_a": lambda s, r: patch(s, r, "#7A9A4A", ["#E8C048", "#F2EEE0", "#B88AC8"], 120, dots="flower"),
    "decals/flowers_patch_b": lambda s, r: patch(s, r, "#6E8A48", ["myosotis", "#6A88C0"], 180, dots="flower"),
    "decals/needles_patch": lambda s, r: patch(s, r, "#8A5A36", ["#A8683A", "#6E4A2E", "#C87A3A"], 900, dots="needle"),
    "decals/puddle_a": puddle, "decals/puddle_b": puddle, "decals/mud_patch": mud_patch,
    "decals/cracks_a": cracks, "decals/cracks_b": lambda s, r: cracks(s, r, count=1, grass=False),
    "decals/stepping_stones": stepping_stones, "decals/lily_pads": lily_pads,
    "decals/sand_drift_a": sand_drift, "decals/sand_drift_b": sand_drift,
    "decals/ring_stone_flat_a": ring_stone_flat, "decals/ring_stone_flat_b": ring_stone_flat,
    "decals/ring_stone_flat_c": ring_stone_flat,
    "decals/chalk_drawings": lambda s, r: chalk(s, r, "drawings"),
    "decals/chalk_hopscotch": lambda s, r: chalk(s, r, "hopscotch"),
    "decals/oil_stain": lambda s, r: stain(s, r, "oil"), "decals/rust_streak": lambda s, r: stain(s, r, "rust"),
    "decals/footprints": footprints, "decals/cart_ruts": cart_ruts, "decals/drain_grate": drain_grate,
    "decals/hay_scatter": hay, "decals/boardwalk": boardwalk, "decals/mist_patch": mist,
}
