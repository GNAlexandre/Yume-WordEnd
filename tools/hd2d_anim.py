"""Recettes HD-2D des bandes animées (docs/ASSETS_HD2D_MONDE.md, sections 11 et 12, lots C et F).

Chaque recette reçoit (taille d'une image, générateur aléatoire, nombre d'images) et rend la liste
des images ; tools/hd2d_assets.py les met côte à côte. Seul ce qui bouge change d'une image à
l'autre, et la dernière s'enchaîne sur la première (mouvements périodiques). Les animations d'un
panneau livré (linge, fanion, manche à air, roseaux, herbe haute, cloche) partent de son image :
le même dessin, mis en mouvement. Cadences : clé fps du manifeste."""

import math
import random

from PIL import Image, ImageDraw

from hd2d_art import Canvas, asset, darker, mix, ramp, rgba, rotate_points, seed_for, steps_alpha

import hd2d_ships
import hd2d_town


def _source(key, size):
    """Panneau livré (ou son remplaçant) dont la bande animée reprend le dessin."""
    img = asset(key)
    if img is None or img.size != size:
        import hd2d_assets
        table = hd2d_assets.recipes()
        img = table[key](size, random.Random(seed_for(key)))
    return img


def _shift_rows(img, region, offsets):
    """Décale horizontalement les rangées de region = (x0, y0, x1, y1) de offsets[y - y0] px."""
    x0, y0, x1, y1 = region
    out = img.copy()
    out.paste(Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0)), (x0, y0))
    for y in range(y0, y1):
        row = img.crop((x0, y, x1, y + 1))
        dx = offsets[y - y0]
        out.alpha_composite(row.crop((max(0, -dx), 0, row.width - max(0, dx), 1)), (x0 + max(0, dx), y))
    return out


def _shift_cols(img, region, offsets):
    """Décale verticalement les colonnes de region de offsets[x - x0] px."""
    x0, y0, x1, y1 = region
    out = img.copy()
    out.paste(Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0)), (x0, y0))
    for x in range(x0, x1):
        col = img.crop((x, y0, x + 1, y1))
        dy = offsets[x - x0]
        out.alpha_composite(col.crop((0, max(0, -dy), 1, col.height - max(0, dy))), (x, y0 + max(0, dy)))
    return out


# --- Panneaux livrés mis en mouvement ----------------------------------------------------------


def laundry_wave(size, rnd, n):
    w, h = size
    src = _source("props/laundry_line", size)
    region = (int(w * 0.09), 0, int(w * 0.91), h)
    frames = []
    for f in range(n):
        offs = []
        for y in range(h):
            depth = max(0.0, min(1.0, (y - h * 0.2) / (h * 0.72)))
            wave = 0.5 + 0.5 * math.sin(2 * math.pi * f / n + y * 0.05)
            offs.append(int(round(9 * depth ** 1.2 * wave)))
        frames.append(_shift_rows(src, region, offs))
    return frames


def pennant_wave(size, rnd, n):
    w, h = size
    src = _source("props/garde_pennant", size)
    x0 = int(w * 0.24)
    region = (x0, int(h * 0.38), w, int(h * 0.84))
    frames = []
    for f in range(n):
        offs = [int(round(5 * ((x - x0) / float(w - x0)) * math.sin(2 * math.pi * f / n - (x - x0) * 0.13)))
                for x in range(x0, w)]
        frames.append(_shift_cols(src, region, offs))
    return frames


def windsock_wave(size, rnd, n):
    w, h = size
    src = _source("props/wind_sock", size)
    x0 = int(w * 0.26)
    region = (x0, int(h * 0.3), w, int(h * 0.52))
    frames = []
    for f in range(n):
        offs = [int(round(3 * ((x - x0) / float(w - x0)) * math.sin(2 * math.pi * f / n - (x - x0) * 0.16)))
                for x in range(x0, w)]
        frames.append(_shift_cols(src, region, offs))
    return frames


def sway(key, amplitude):
    """Roseaux, herbe : le haut se balance vers la droite (0, 1, 2, 1 × amplitude), pied immobile."""

    def recipe(size, rnd, n):
        w, h = size
        src = _source(key, size)
        frames = []
        for f in range(n):
            s = [0, 1, 2, 1][f % 4] if n == 4 else (1 - math.cos(2 * math.pi * f / n))
            offs = [int(round(amplitude * s * ((h - 1 - y) / float(h)) ** 1.5)) for y in range(h)]
            frames.append(_shift_rows(src, (0, 0, w, h), offs))
        return frames
    return recipe


# Cloche de veille livrée : la cloche (contour ci-dessous, en px de l'image de 134 × 230) se
# balance autour de son anneau ; portique, poutre et ferrure immobiles.
BELL_SHAPE = [(56, 84), (76, 84), (78, 98), (88, 102), (92, 130), (100, 150), (100, 162), (72, 163), (73, 176),
              (61, 176), (62, 163), (33, 162), (33, 150), (42, 130), (46, 102), (56, 98)]
BELL_PIVOT = (66.5, 86)


def vigil_bell_ring(size, rnd, n):
    w, h = size
    src = _source("props/vigil_bell", size)
    sx, sy = w / 134.0, h / 230.0
    shape = [(x * sx, y * sy) for x, y in BELL_SHAPE]
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(shape, fill=255)
    bell = Image.new("RGBA", size, (0, 0, 0, 0))
    bell.paste(src, (0, 0), mask)
    erase = Image.new("L", size, 0)
    ImageDraw.Draw(erase).polygon(shape, fill=255)
    ImageDraw.Draw(erase).rectangle((0, 0, int(37 * sx), h), fill=0)
    ImageDraw.Draw(erase).rectangle((int(97 * sx), 0, w, h), fill=0)
    base = src.copy()
    base.paste(Image.new("RGBA", size, (0, 0, 0, 0)), (0, 0), erase)
    frames = []
    pivot = (BELL_PIVOT[0] * sx, BELL_PIVOT[1] * sy)
    for f in range(n):
        angle = 10.0 * math.sin(2 * math.pi * (f + 0.5) / n)
        swung = bell.rotate(angle, resample=Image.NEAREST, center=pivot)
        frame = base.copy()
        frame.alpha_composite(swung)
        frames.append(frame)
    return frames


def bunting_wave(size, rnd, n):
    return [hd2d_town.bunting(size, random.Random(seed_for("props/bunting")), phase=f / float(n)) for f in range(n)]


def fountain_water(size, rnd, n):
    return [hd2d_town.fountain(size, random.Random(seed_for("props/fountain")), water_phase=f / float(n))
            for f in range(n)]


# --- Fumée, vapeur, feu, eau (alpha doux en paliers sauf le feu) ------------------------------------


def _puff(img, x, y, r, color, alpha):
    """Bouffée douce : disques concentriques de plus en plus opaques vers le centre."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k in range(4):
        t = 1.0 - k / 4.0
        a = int(alpha * (0.35 + 0.65 * (1.0 - t)))
        col = mix(color, "#FFFFFF", 0.08 * k)
        d.ellipse((x - r * t, y - r * t * 0.85, x + r * t, y + r * t * 0.85), fill=col + (a,))
    img.alpha_composite(layer)


def smoke(size, rnd, n, color="#8A8088", puffs=12, drift=0.45, grow=26, alpha=150):
    w, h = size
    frames = []
    seeds = [rnd.uniform(-0.04, 0.04) for _ in range(puffs)]
    for f in range(n):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        for i in range(puffs):
            u = (i / float(puffs) + f / float(n)) % 1.0
            x = w * (0.32 + seeds[i]) + (u ** 1.5) * w * drift
            y = h - 6 - u * (h - grow - 14)
            r = 7 + u * grow
            _puff(img, x, y, r, mix(color, "#C8A890", 0.2 * (1 - u)), alpha * (1.0 - u) ** 0.8)
        _puff(img, w * 0.32, h - 4, 5, color, alpha)
        frames.append(steps_alpha(img, 6))
    return frames


def chimney_smoke(size, rnd, n):
    return smoke(size, rnd, n)


def furnace_steam(size, rnd, n):
    return smoke(size, rnd, n, color="#E8E4EC", puffs=12, drift=0.05, grow=18, alpha=170)


def brazier_fire(size, rnd, n):
    w, h = size
    frames = []
    tongues = [(rnd.uniform(0.2, 0.8), rnd.uniform(0.45, 0.8), rnd.uniform(0, 2 * math.pi), rnd.uniform(0.09, 0.14))
               for _ in range(6)]
    sparks = [(rnd.uniform(0.25, 0.75), rnd.random()) for _ in range(4)]
    for f in range(n):
        c = Canvas(w, h, rnd)
        for x, height, phase, half in sorted(tongues, key=lambda t: -t[1]):
            hh = height + 0.12 * math.sin(2 * math.pi * f / n + phase)
            lean = 0.06 * math.sin(2 * math.pi * f / n + phase * 1.7)
            pts = [(w * (x - half), h - 4), (w * (x + lean), h * (1 - hh)), (w * (x + half), h - 4)]
            c.poly(pts, "#D8502A")
            inner = [(w * (x - half * 0.55), h - 4), (w * (x + lean * 0.7), h * (1 - hh * 0.65)), (w * (x + half * 0.55), h - 4)]
            c.poly(inner, "#F4A040")
            core = [(w * (x - half * 0.25), h - 4), (w * (x + lean * 0.4), h * (1 - hh * 0.35)), (w * (x + half * 0.25), h - 4)]
            c.poly(core, "#FFE08A")
        for x, ph in sparks:
            u = (ph + f / float(n)) % 1.0
            c.rect(w * x + math.sin(u * 6) * 3, h * (0.7 - 0.62 * u), w * x + math.sin(u * 6) * 3 + 2, h * (0.7 - 0.62 * u) + 2,
                   "#FFD070")
        embers = ramp("#A83A1A", 4)
        for k in range(8):
            c.ellipse(w * (0.12 + 0.1 * k), h - 3, 4, 3, embers[(k + f) % 4])
        frames.append(c.finish(darker("#7A2A1A", 0.6)))
    return frames


def edge_waterfall(size, rnd, n):
    """Cascade : lèvre de pierre en haut (immobile), filets d'eau qui défilent vers le bas (période
    multiple de la hauteur parcourue en une boucle), écume et brume en bas ; bords en alpha doux."""
    w, h = size
    lip = Canvas(w, h, rnd)
    stone = ramp(mix("stone", "stone_dark", 0.3), 5)
    lip.poly([(w * 0.06, 34), (w * 0.12, 8), (w * 0.4, 2), (w * 0.62, 6), (w * 0.9, 4), (w * 0.95, 30), (w * 0.8, 44), (w * 0.2, 46)],
             stone[2])
    lip.poly([(w * 0.12, 10), (w * 0.4, 4), (w * 0.62, 8), (w * 0.5, 22), (w * 0.2, 24)], stone[3])
    lip.rect(w * 0.1, 0, w * 0.9, 6, mix("grass", "#5E7A3A", 0.5))
    lip_img = lip.finish(darker("stone_dark", 0.45))
    period = 48
    streaks = [(rnd.uniform(0.0, 1.0), rnd.randrange(period), rnd.randint(8, 22), rnd.choice([0, 1, 2])) for _ in range(46)]
    water = ramp(mix("marsh", "#B8D8D8", 0.55), 4)
    frames = []
    for f in range(n):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        body = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(body)
        for y in range(30, h):
            t = (y - 30) / float(h - 30)
            half = w * (0.16 + 0.12 * t)
            core = w * (0.11 + 0.08 * t)
            d.line((w / 2 - half, y, w / 2 + half, y), fill=water[1] + (120,))
            d.line((w / 2 - core, y, w / 2 + core, y), fill=water[1] + (230,))
        shift = int(f * period / n)
        for u, y0, length, tone in streaks:
            for rep in range(-1, h // period + 2):
                y = 30 + y0 + rep * period + shift
                t = max(0.0, min(1.0, (y - 30) / float(h - 30)))
                x = w / 2 + (u - 0.5) * 2 * w * (0.11 + 0.08 * t)
                if 30 <= y < h - 30:
                    d.line((x, y, x, min(h - 30, y + length)), fill=water[2 + tone % 2] + (255,))
        img.alpha_composite(body)
        for k in range(7):
            ph = (k / 7.0 + f / float(n)) % 1.0
            _puff(img, w * (0.2 + 0.1 * k), h - 18 - 10 * math.sin(math.pi * ph), 26 + 8 * ph, "#E8E8F0", 150)
        img.alpha_composite(lip_img)
        frames.append(steps_alpha(img, 6))
    return frames


# --- Petites vies (centrées : elles volent) ---------------------------------------------------------


def birds_flock(size, rnd, n):
    w, h = size
    birds = [(0.22, 0.5, 0.0), (0.38, 0.36, 0.3), (0.5, 0.56, 0.55), (0.64, 0.4, 0.15), (0.78, 0.58, 0.8)]
    frames = []
    for f in range(n):
        c = Canvas(w, h, rnd)
        for bx, by, phase in birds:
            x, y = w * bx, h * by + math.sin(2 * math.pi * (f / float(n) + phase)) * 1.5
            wing = math.sin(2 * math.pi * (f / float(n) + phase))
            col = "#3A3440"
            c.ellipse(x, y, 5, 2.5, col)
            c.rect(x + 4, y - 2, x + 7, y + 1, col)
            c.poly([(x - 6, y), (x - 10, y - 2), (x - 9, y + 2)], col)
            tip = (x - 2, y - 9 * wing)
            c.line([(x + 1, y - 1), tip], "#4A4450", 2)
            c.line([(x - 1, y - 1), (x - 5, y - 6 * wing)], "#2E2834", 1)
        frames.append(c.finish("#2A2430"))
    return frames


def falling_leaf(color):
    def recipe(size, rnd, n):
        w, h = size
        frames = []
        tones = ramp(color, 5)
        for f in range(n):
            t = f / float(n)
            angle = 2 * math.pi * t
            flip = math.cos(2 * math.pi * t * 2)
            sx = max(0.18, abs(flip))
            c = Canvas(w, h, rnd)
            cx, cy = w / 2.0 - 0.5, h / 2.0 - 0.5
            leaf = [(0, -4.5), (2.2, -2.5), (3.0, 0), (2.2, 2.5), (0, 4.5), (-2.2, 2.5), (-3.0, 0), (-2.2, -2.5)]
            pts = [(cx + x * sx, cy + y) for x, y in leaf]
            pts = rotate_points(pts, cx, cy, angle)
            c.poly(pts, tones[3] if flip > 0 else tones[1])
            rib = rotate_points([(cx, cy - 4), (cx, cy + 5)], cx, cy, angle)
            c.line(rib, tones[0] if flip > 0 else tones[2])
            frames.append(c.finish(darker(color, 0.55)))
        return frames
    return recipe


def pigeons(size, rnd, n):
    w, h = size
    frames = []
    grey = ramp("#8A8C98", 5)
    for f in range(n):
        dip = [0, 3, 6, 3][f % 4]
        c = Canvas(w, h, rnd)
        c.line([(w * 0.42, h - 6), (w * 0.4, h)], "#C8603A", 1)
        c.line([(w * 0.56, h - 6), (w * 0.58, h)], "#C8603A", 1)
        c.blob(w * 0.48, h * 0.6, w * 0.26, h * 0.24, grey[1:])
        c.poly([(w * 0.24, h * 0.56), (w * 0.04, h * 0.5), (w * 0.08, h * 0.66)], grey[1])
        c.poly([(w * 0.3, h * 0.5), (w * 0.62, h * 0.48), (w * 0.5, h * 0.68)], grey[2])
        hx, hy = w * 0.74 + dip * 0.4, h * 0.36 + dip
        c.line([(w * 0.64, h * 0.5), (hx, hy)], "#6A7A8A", 4)
        c.blob(hx, hy, 4, 3.5, grey[1:])
        c.rect(hx + 3, hy, hx + 6, hy + 1, "#C8A070")
        c.pixel(hx + 1, hy - 1, "#E8A030")
        frames.append(c.finish(darker("#8A8C98", 0.5)))
    return frames


def butterfly(size, rnd, n):
    w, h = size
    frames = []
    orange = ramp("#D8782A", 5)
    for f in range(n):
        span = [1.0, 0.6, 0.2, 0.6][f % 4]
        c = Canvas(w, h, rnd)
        cx, cy = w / 2.0, h / 2.0
        for side in (-1, 1):
            c.poly([(cx, cy - 1), (cx + side * 9 * span, cy - 6), (cx + side * 8 * span, cy + 1)], orange[3])
            c.poly([(cx, cy + 1), (cx + side * 7 * span, cy + 2), (cx + side * 5 * span, cy + 7)], orange[2])
            c.pixel(cx + side * 6 * span, cy - 3, "#3A2A20")
        c.rect(cx - 1, cy - 5, cx + 1, cy + 6, "#3A2A20")
        frames.append(c.finish("#4A2A1A"))
    return frames


def fireflies(size, rnd, n):
    w, h = size
    frames = []
    for f in range(n):
        level = [0.35, 0.7, 1.0, 0.7][f % 4]
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        r = 1.5 + 2.5 * level
        cx, cy = w / 2.0 - 0.5, h / 2.0 - 0.5
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba("#D8F080")[:3] + (int(90 * level),))
        d.ellipse((cx - r / 2, cy - r / 2, cx + r / 2, cy + r / 2), fill=rgba("#F0FFA0")[:3] + (int(200 * level),))
        d.rectangle((cx - 0.5, cy - 0.5, cx + 0.5, cy + 0.5), fill=rgba("#FFFFD0"))
        frames.append(steps_alpha(img, 6))
    return frames


def cafe_door_bell(size, rnd, n):
    w, h = size
    frames = []
    iron = ramp("iron", 4)
    brass = ramp("brass", 5)
    for f in range(n):
        angle = [0.0, 0.22, 0.0, -0.22][f % 4]
        c = Canvas(w, h, rnd)
        c.rect(6, 4, 10, h, iron[1])
        c.rect(6, 4, w * 0.7, 8, iron[1])
        c.line([(10, 18), (22, 8)], iron[0], 2)
        px, py = w * 0.62, 8
        bell = [(px - 2, py + 2), (px + 2, py + 2), (px + 4, py + 8), (px + 8, py + 20), (px - 8, py + 20), (px - 4, py + 8)]
        c.poly(rotate_points(bell, px, py, angle), brass[2])
        c.poly(rotate_points([(px - 2, py + 2), (px, py + 2), (px - 3, py + 18), (px - 7, py + 19), (px - 4, py + 8)], px, py, angle),
               brass[4])
        cl = rotate_points([(px, py + 22)], px, py, angle * 1.4)[0]
        c.ellipse(cl[0], cl[1], 2, 2, brass[0])
        frames.append(c.finish(darker("brass", 0.45)))
    return frames


def propeller(blades, base, tips, step, hub):
    def recipe(size, rnd, n):
        return hd2d_ships.propeller(size, rnd, blades, base, tips, step, n, hub)
    return recipe


RECIPES = {
    "anim/laundry_wave": laundry_wave, "anim/pennant_wave": pennant_wave, "anim/chimney_smoke": chimney_smoke,
    "anim/brazier_fire": brazier_fire, "anim/edge_waterfall": edge_waterfall, "anim/birds_flock": birds_flock,
    "anim/falling_leaf_gold": falling_leaf("leaf_gold"), "anim/falling_leaf_rust": falling_leaf("leaf_rust"),
    "anim/reeds_sway": sway("props/reeds", 3), "anim/grass_sway": sway("props/tall_grass", 3),
    "anim/windsock_wave": windsock_wave, "anim/bunting_wave": bunting_wave, "anim/vigil_bell_ring": vigil_bell_ring,
    "anim/fountain_water": fountain_water, "anim/pigeons": pigeons, "anim/butterfly": butterfly,
    "anim/fireflies": fireflies, "anim/furnace_steam": furnace_steam, "anim/cafe_door_bell": cafe_door_bell,
    "anim/airship_ferry_propeller": propeller(4, "#8A5A3A", "#B0703A", math.pi / 8, "#B0703A"),
    "anim/airship_barocupot_propeller": propeller(5, "#3A3A42", "#AE4A3E", math.pi / 10, "iron"),
}
