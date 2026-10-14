"""Recettes HD-2D : tuiles de sol, falaises et matières des bâtiments (sans raccord).

Chaque recette reçoit (taille, générateur aléatoire) et rend une image RGBA opaque qui se répète
sans raccord (tools/hd2d_assets.py, docs/ASSETS_HD2D.md sections 4, 5 et 6.2 ;
docs/ASSETS_HD2D_MONDE.md sections 4 et 9.3)."""

import heapq
import math

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from hd2d_art import (Canvas, asset, darker, fractal, mix, noise, paste_wrap, posterize, ramp, recolor,
                      rgb, rgba, rotate_points, shade_texture, stretch, threshold, wrap_x, wrap_y)


def _soft(gray, amount=0.6):
    """Resserre le bruit autour du milieu : moins de grandes plages uniformes aux extrêmes."""
    return gray.point(lambda v: round(128 + (v - 128) * amount))


def _blades(img, rnd, count, colors, length=(3, 6), slant=0.0, width=1):
    """Brins d'herbe : traits verticaux de 1 px, pointe plus claire, posés sans raccord."""
    for _ in range(count):
        x, y = rnd.randrange(img.width), rnd.randrange(img.height)
        n = rnd.randint(*length)
        blade = Image.new("RGBA", (width + abs(int(slant * n)) + 2, n + 1), (0, 0, 0, 0))
        d = ImageDraw.Draw(blade)
        base = rnd.choice(colors[:-1])
        tip = colors[-1] if rnd.random() < 0.5 else base
        x0 = 1 if slant >= 0 else blade.width - 2
        for k in range(n):
            px = x0 + round(slant * k)
            d.rectangle((px, n - k, px + width - 1, n - k), fill=rgba(tip if k >= n - 2 else base))
        paste_wrap(img, blade, x, y - n)


def _dots(img, rnd, count, colors, size=(1, 2)):
    for _ in range(count):
        s = rnd.randint(*size)
        dot = Image.new("RGBA", (s, s), rgba(rnd.choice(colors)))
        paste_wrap(img, dot, rnd.randrange(img.width), rnd.randrange(img.height))


def _pebbles(img, rnd, count, base, size=(3, 7)):
    tones = ramp(base, 4)
    for _ in range(count):
        rx = rnd.randint(*size) / 2.0
        ry = rx * rnd.uniform(0.6, 0.9)
        w, h = int(2 * rx) + 3, int(2 * ry) + 3
        c = Canvas(w, h, rnd)
        c.blob(w / 2.0, h / 2.0, rx, ry, tones[:3] + [tones[3]])
        c.img = c.finish(darker(tones[0], 0.7))
        paste_wrap(img, c.img, rnd.randrange(img.width), rnd.randrange(img.height))


def _leaves(img, rnd, count, colors):
    shapes = [[(0, 1), (1, 0), (2, 0), (3, 1), (2, 2), (1, 2)], [(0, 0), (2, 0), (3, 1), (1, 2)],
              [(0, 1), (2, 0), (4, 1), (2, 2)]]
    for _ in range(count):
        shape = rnd.choice(shapes)
        leaf = Image.new("RGBA", (6, 4), (0, 0, 0, 0))
        col = rnd.choice(colors)
        ImageDraw.Draw(leaf).polygon(shape, fill=rgba(col), outline=rgba(darker(col, 0.7)))
        if rnd.random() < 0.5:
            leaf = leaf.transpose(Image.FLIP_LEFT_RIGHT)
        paste_wrap(img, leaf, rnd.randrange(img.width), rnd.randrange(img.height))


def _voronoi(size, rnd, count, min_dist=0.0):
    """Cellules de Voronoï sans raccord : (index de cellule, distance au joint) par pixel."""
    w, h = size
    points = []
    while len(points) < count:
        p = (rnd.uniform(0, w), rnd.uniform(0, h))
        if all(min((p[0] - q[0]) % w, (q[0] - p[0]) % w) ** 2 + min((p[1] - q[1]) % h, (q[1] - p[1]) % h) ** 2
               >= min_dist ** 2 for q in points):
            points.append(p)
    ids = [0] * (w * h)
    gaps = [0.0] * (w * h)
    step = 2
    for y in range(0, h, step):
        for x in range(0, w, step):
            best = second = 1e9
            bi = 0
            for i, (px, py) in enumerate(points):
                dx = abs(x - px)
                dx = min(dx, w - dx)
                dy = abs(y - py)
                dy = min(dy, h - dy)
                d = dx * dx + dy * dy
                if d < best:
                    second, best, bi = best, d, i
                elif d < second:
                    second = d
            gap = math.sqrt(second) - math.sqrt(best)
            for yy in range(y, min(h, y + step)):
                for xx in range(x, min(w, x + step)):
                    ids[yy * w + xx] = bi
                    gaps[yy * w + xx] = gap
    return ids, gaps, points


# --- Sol ----------------------------------------------------------------------------------------


def grass(size, rnd, base="grass", blades=2600, dry=False):
    tones = ramp(base, 5, spread=0.45)
    img = posterize(_soft(fractal(size, (12, 12), rnd, 4, gain=0.7)), tones[1:5], dither=110)
    if dry:
        patch = threshold(fractal(size, (4, 4), rnd, 3, gain=0.7), 178)
        dry_img = posterize(fractal(size, (16, 16), rnd, 2), ramp("grass_dry", 5)[1:4], dither=80)
        img.paste(dry_img, (0, 0), patch)
    _blades(img, rnd, blades // 3, [tones[0], tones[1], tones[1]], (2, 5))
    _blades(img, rnd, blades, [tones[1], tones[2], tones[3], tones[4]], (3, 6))
    _leaves(img, rnd, 14, [rgb("leaf_rust"), rgb("leaf_gold")])
    return img


def grass_dry(size, rnd):
    tones = ramp("grass_gold", 5, spread=0.4)
    img = posterize(fractal(size, (12, 12), rnd, 3, gain=0.7), tones[2:5], dither=90)
    _blades(img, rnd, 1600, tones[1:], (6, 11), slant=0.35)
    _blades(img, rnd, 500, [tones[0], tones[1], tones[2]], (4, 8), slant=0.3)
    _dots(img, rnd, 60, [mix("grass_gold", "#F2E3A4", 0.6)], (2, 2))
    return img


def path_dirt(size, rnd):
    base = mix("wood", "sand", 0.5)
    tones = ramp(base, 5, spread=0.4)
    img = posterize(_soft(fractal(size, (10, 10), rnd, 4, gain=0.7)), tones[1:5], dither=110)
    _pebbles(img, rnd, 70, "stone", (3, 7))
    _dots(img, rnd, 400, [tones[0], tones[4]], (1, 2))
    _blades(img, rnd, 60, ramp("grass", 4)[1:], (2, 4))
    return img


def _stones_rows(size, rnd, rows, widths, joint, stone_base, bevel=2, radius=4, grass_in_joints=True):
    """Dalles en rangées décalées, sans raccord : joints, puis pierres biseautées."""
    w, h = size
    img = posterize(fractal(size, (8, 8), rnd, 2), ramp(joint, 4)[0:3], dither=60)
    if grass_in_joints:
        _blades(img, rnd, 500, ramp("grass", 5)[0:4], (2, 4))
    tones = ramp(stone_base, 6, spread=0.35)
    tex = posterize(fractal(size, (10, 10), rnd, 3), tones[1:5], dither=70)
    y = 0
    for row_h in rows:
        x = rnd.randrange(w)
        start = x
        while x < start + w:
            sw = rnd.randint(*widths)
            if x + sw > start + w:
                sw = start + w - x
            if sw < widths[0] // 2:
                break
            shade = rnd.uniform(0.85, 1.12)
            stone = Image.new("RGBA", (sw - 3, row_h - 3), (0, 0, 0, 0))
            mask = Image.new("L", stone.size, 0)
            ImageDraw.Draw(mask).rounded_rectangle((0, 0, stone.width - 1, stone.height - 1), radius, fill=255)
            body = tex.crop((x % w, y, x % w + stone.width, y + stone.height)) if x % w + stone.width <= w else \
                tex.crop((0, y, stone.width, y + stone.height))
            body = body.point(lambda v: min(255, round(v * shade)))
            stone.paste(body, (0, 0), mask)
            d = ImageDraw.Draw(stone)
            light = rgba(tones[5])
            dark = rgba(tones[0])
            for k in range(bevel):
                d.line((radius, k, stone.width - radius, k), fill=light)
                d.line((k, radius, k, stone.height - radius), fill=light)
                d.line((radius, stone.height - 1 - k, stone.width - radius, stone.height - 1 - k), fill=dark)
                d.line((stone.width - 1 - k, radius, stone.width - 1 - k, stone.height - radius), fill=dark)
            stone.putalpha(mask)
            if rnd.random() < 0.35:
                cx = rnd.randrange(4, max(5, stone.width - 4))
                d.line([(cx, 2), (cx + rnd.randint(-6, 6), stone.height // 2),
                        (cx + rnd.randint(-8, 8), stone.height - 3)], fill=dark)
                stone.putalpha(mask)
            paste_wrap(img, stone, x + 1, y + 1)
            x += sw
        y += row_h
    return img


def flagstone(size, rnd):
    return _stones_rows(size, rnd, [72, 80, 64, 88, 80], (58, 92), mix("wood_dark", "grass", 0.4),
                        mix("stone", "stone_dark", 0.35), bevel=2, radius=6)


def cobble(size, rnd):
    return _stones_rows(size, rnd, [24] * 16, (20, 34), "#4E4A48", mix("stone", "stone_dark", 0.6),
                        bevel=2, radius=6, grass_in_joints=False)


def sand(size, rnd):
    w, h = size
    tones = ramp("sand", 5, spread=0.35)
    warp = fractal(size, (4, 4), rnd, 2)
    period = 24
    rip = Image.new("L", size)
    px = []
    wp = warp.load()
    for y in range(h):
        for x in range(w):
            v = math.sin(2 * math.pi * (y + (wp[x, y] - 128) / 255.0 * 18.0) / period)
            px.append(round(128 + 70 * v))
    rip.putdata(px)
    base = Image.blend(rip, fractal(size, (12, 12), rnd, 2), 0.45)
    img = posterize(stretch(base), tones[1:5], dither=70)
    _pebbles(img, rnd, 30, "stone", (2, 5))
    _dots(img, rnd, 250, [tones[0], tones[4]], (1, 1))
    return img


def rock(size, rnd, base="stone", joint="sand", plates=14):
    w, h = size
    ids, gaps, points = _voronoi(size, rnd, plates, min_dist=60)
    tones = ramp(base, 6, spread=0.35)
    tex = fractal(size, (10, 10), rnd, 3)
    shades = [rnd.uniform(-30, 30) for _ in points]
    jt = ramp(joint, 4)
    g = tex.load()
    out = Image.new("RGBA", size)
    data = []
    for y in range(h):
        for x in range(w):
            k = y * w + x
            gap = gaps[k]
            if gap < 2.5:
                data.append(jt[1] + (255,) if gap < 1.5 else jt[2] + (255,))
                continue
            v = g[x, y] + shades[ids[k]] + (18 if gap < 5 else 0)
            dither = (((x & 3) * 4 + (y & 3)) * 37 % 16) * 3 - 24
            idx = max(1, min(5, int((v + dither) * 6 / 256)))
            data.append(tones[idx] + (255,))
    out.putdata(data)
    _dots(out, rnd, 120, [tones[0]], (1, 2))
    return out


def forest_floor(size, rnd):
    soil = ramp("#4E4030", 5, spread=0.4)
    img = posterize(fractal(size, (10, 10), rnd, 4, gain=0.7), soil[0:4], dither=90)
    moss = threshold(fractal(size, (5, 5), rnd, 3, gain=0.7), 168)
    moss_img = posterize(fractal(size, (16, 16), rnd, 2), ramp("#4F6B3A", 4)[0:3], dither=60)
    img.paste(moss_img, (0, 0), moss)
    for _ in range(320):
        x, y = rnd.randrange(size[0]), rnd.randrange(size[1])
        needle = Image.new("RGBA", (7, 7), (0, 0, 0, 0))
        dx, dy = rnd.choice([(5, 1), (1, 5), (4, 4), (4, -3)])
        ImageDraw.Draw(needle).line((1, 3, 1 + dx, 3 + dy // 2), fill=rgba(rnd.choice(soil[2:])))
        paste_wrap(img, needle, x, y)
    _leaves(img, rnd, 520, [rgb("leaf_rust"), rgb("leaf_gold"), rgb("leaf_yellow"), darker("leaf_rust", 0.7)])
    return img


def peat(size, rnd):
    tones = ramp("#5A5236", 5, spread=0.4)
    img = posterize(fractal(size, (10, 10), rnd, 4, gain=0.7), tones[0:4], dither=90)
    puddles = threshold(fractal(size, (3, 3), rnd, 3), 175)
    water_img = posterize(fractal(size, (20, 20), rnd, 2), ramp("marsh", 4)[0:3], dither=50)
    img.paste(water_img, (0, 0), puddles)
    _blades(img, rnd, 260, ramp("reed", 4), (4, 9), slant=0.6)
    _dots(img, rnd, 80, [mix("marsh", "#E8E2C8", 0.55)], (1, 2))
    return img


def water(size, rnd):
    tones = ramp("marsh", 5, spread=0.35)
    img = posterize(fractal(size, (4, 4), rnd, 3), tones[0:3], dither=50)
    light = mix("marsh", "#E8E2C8", 0.45)
    for _ in range(140):
        n = rnd.randint(3, 9)
        streak = Image.new("RGBA", (n, 1), rgba(light if rnd.random() < 0.6 else tones[3]))
        paste_wrap(img, streak, rnd.randrange(size[0]), rnd.randrange(size[1]))
    for _ in range(9):
        c = Canvas(14, 10, rnd)
        c.blob(7, 5, 5.5, 3.5, ramp("#6E8C4A", 4))
        paste_wrap(img, c.finish(darker("#6E8C4A", 0.6)), rnd.randrange(size[0]), rnd.randrange(size[1]))
    return img


def mud(size, rnd):
    tones = ramp("#6E5A40", 5, spread=0.4)
    img = posterize(_soft(fractal(size, (10, 10), rnd, 4, gain=0.7)), tones[0:4], dither=110)
    puddles = threshold(fractal(size, (3, 3), rnd, 3), 185)
    img.paste(posterize(fractal(size, (16, 16), rnd, 2), ramp("#4E4A52", 3), dither=50), (0, 0), puddles)
    for _ in range(18):
        print_img = Image.new("RGBA", (6, 9), (0, 0, 0, 0))
        ImageDraw.Draw(print_img).ellipse((0, 0, 5, 8), fill=rgba(tones[0]))
        paste_wrap(img, print_img, rnd.randrange(size[0]), rnd.randrange(size[1]))
    _blades(img, rnd, 80, ramp("grass", 4)[0:3], (2, 4))
    return img


def metal(size, rnd):
    w, h = size
    tones = ramp("iron", 6, spread=0.35)
    img = posterize(fractal(size, (12, 12), rnd, 2), tones[2:5], dither=50)
    d = ImageDraw.Draw(img)
    plate = 192
    rust = ramp("#8A5A3A", 4)
    rust_mask = threshold(fractal(size, (8, 8), rnd, 3), 175)
    for px in range(0, w, plate):
        for py in range(0, h, plate):
            d.rectangle((px, py, px + plate - 1, py + 1), fill=rgba(tones[5]))
            d.rectangle((px, py, px + 1, py + plate - 1), fill=rgba(tones[5]))
            d.rectangle((px, py + plate - 3, px + plate - 1, py + plate - 1), fill=rgba(tones[0]))
            d.rectangle((px + plate - 3, py, px + plate - 1, py + plate - 1), fill=rgba(tones[0]))
            for k in range(8, plate, 16):
                for rx, ry in ((px + k, py + 7), (px + k, py + plate - 9), (px + 7, py + k), (px + plate - 9, py + k)):
                    d.rectangle((rx, ry, rx + 2, ry + 2), fill=rgba(tones[1]))
                    d.point((rx, ry), fill=rgba(tones[5]))
    seams = Image.new("L", size, 0)
    sd = ImageDraw.Draw(seams)
    for px in range(0, w, plate):
        sd.rectangle((px - 10, 0, px + 10, h), fill=255)
    for py in range(0, h, plate):
        sd.rectangle((0, py - 10, w, py + 10), fill=255)
    from PIL import ImageChops
    mask = ImageChops.multiply(seams, rust_mask)
    img.paste(posterize(fractal(size, (24, 24), rnd, 2), rust[0:3], dither=60), (0, 0), mask)
    return img


# --- Falaises ----------------------------------------------------------------------------------


def _strata(size, rnd, colors, thickness=(10, 40), crack_color=None, roots=0, tufts=0):
    w, h = size
    warp = fractal(size, (3, 2), rnd, 2)
    bands = []
    y = 0
    while y < h:
        t = rnd.randint(*thickness)
        if h - y - t < thickness[0]:
            t = h - y
        bands.append((y, y + t, rnd.choice(colors)))
        y += t
    tex = fractal(size, (12, 6), rnd, 3)
    wp, tp = warp.load(), tex.load()
    data = []
    for yy in range(h):
        for xx in range(w):
            off = (wp[xx, yy] - 128) / 255.0 * 10.0
            yy2 = (yy + off) % h
            for y0, y1, tones in bands:
                if y0 <= yy2 < y1:
                    edge = yy2 - y0
                    v = tp[xx, yy]
                    dither = (((xx & 3) * 4 + (yy & 3)) * 37 % 16) * 3 - 24
                    idx = max(0, min(len(tones) - 1, int((v + dither) * len(tones) / 256)))
                    if edge < 2:
                        idx = len(tones) - 1
                    elif y1 - yy2 < 2:
                        idx = 0
                    data.append(tones[idx] + (255,))
                    break
    img = Image.new("RGBA", size)
    img.putdata(data)
    d = ImageDraw.Draw(img)
    crack = rgba(crack_color or colors[0][0])
    for _ in range(18):
        x, y = rnd.randrange(w), rnd.randrange(h)
        pts = [(x, y)]
        for _ in range(rnd.randint(3, 8)):
            x += rnd.randint(-3, 3)
            y += rnd.randint(4, 10)
            pts.append((x, y))
        for k in range(len(pts) - 1):
            for dx in (-w, 0, w):
                for dy in (-h, 0, h):
                    d.line((pts[k][0] + dx, pts[k][1] + dy, pts[k + 1][0] + dx, pts[k + 1][1] + dy), fill=crack)
    root_tones = ramp("#5C4030", 4)
    for _ in range(roots):
        x, y = rnd.randrange(w), rnd.randrange(h)
        length = rnd.randint(20, 80)
        for k in range(length):
            x += rnd.choice((-1, 0, 0, 1))
            for dx in (-w, 0, w):
                for dy in (-h, 0, h):
                    d.point((x + dx, y + k + dy), fill=rgba(root_tones[1]))
                    d.point((x + 1 + dx, y + k + dy), fill=rgba(root_tones[0]))
    for _ in range(tufts):
        bx, by = rnd.randrange(w), rnd.choice(bands)[0]
        tuft = Image.new("RGBA", (16, 8), (0, 0, 0, 0))
        _blades(tuft, rnd, 12, ramp("grass", 4), (3, 6))
        paste_wrap(img, tuft, bx, by - 7)
    return img


def cliff(size, rnd):
    light = ramp("stone", 5, spread=0.35)
    mid = ramp(mix("stone", "stone_dark", 0.5), 5, spread=0.35)
    dark = ramp("stone_dark", 5, spread=0.35)
    return _strata(size, rnd, [light[1:], mid[1:], dark[1:], mid[0:4]], (14, 44), tufts=10)


def underside(size, rnd):
    a = ramp(mix("stone_dark", "#5A4E6E", 0.45), 5, spread=0.4)
    b = ramp(mix("stone_dark", "#3E3650", 0.6), 5, spread=0.4)
    c = ramp(mix("stone_dark", "#7A6A70", 0.3), 5, spread=0.4)
    return _strata(size, rnd, [a[0:4], b[0:4], c[0:4]], (16, 52), roots=22)


def lip(size, rnd):
    w, h = size
    img = cliff((w, w), rnd).crop((0, 0, w, h))
    tones = ramp("stone", 6, spread=0.3)
    d = ImageDraw.Draw(img)
    # Le bord de la dalle : une bande claire biseautée, ébréchée par endroits.
    top = 26
    for x in range(w):
        chip = 3 if math.sin(x * 0.21) + math.sin(x * 0.057 + 1.3) > 1.4 else 0
        d.line((x, top, x, top + 5 - chip), fill=rgba(tones[5] if chip == 0 else tones[3]))
        d.point((x, top + 6 - chip), fill=rgba(tones[1]))
    grass_tones = ramp("grass", 5, spread=0.45)
    turf = posterize(fractal((w, top + 6), (8, 2), rnd, 2), grass_tones[1:4], dither=60)
    img.paste(turf.crop((0, 0, w, top)), (0, 0))
    # Brins qui débordent sur la lèvre (raccord gauche-droite : posés avec copies décalées).
    for _ in range(170):
        x = rnd.randrange(w)
        n = rnd.randint(3, 9)
        col = rnd.choice(grass_tones[1:])
        for k in range(n):
            for dx in (-w, 0, w):
                d.point((x + dx + (k // 4), top - 2 + k), fill=rgba(col if k < n - 1 else grass_tones[0]))
    return img


def bank_earth(size, rnd):
    """(E2) Talus de terre vu de face, 1 m de haut : la face d'un petit palier du sol en relief
    des cartes (map_ground_cliff.gdshader). En haut, l'herbe qui déborde en touffes ; puis la
    terre en strates molles, racines, cailloux ; en bas, les tons de la terre de potager
    (garden_soil), que le shader prolonge sous un talus plus haut. Sans raccord à gauche et à
    droite."""
    w, h = size
    soil = ramp("#56402C", 6, spread=0.5)
    img = posterize(_soft(fractal(size, (8, 3), rnd, 3, gain=0.6)), soil[0:4], dither=90)
    d = ImageDraw.Draw(img)
    # Strates : lignes ondulées plus sombres, ou plus claires (sable mêlé), sans raccord.
    for band in range(4):
        y0 = 30 + band * 16 + rnd.randint(-3, 3)
        phase = rnd.uniform(0, 2 * math.pi)
        tone = soil[0] if band % 2 == 0 else soil[4]
        for x in range(w):
            y = y0 + round(2.5 * math.sin(2 * math.pi * x * 3 / w + phase))
            if rnd.random() < 0.8:
                d.point((x, y), fill=rgba(tone))
    _pebbles(img, rnd, 26, "stone_dark", (2, 5))
    _dots(img, rnd, 260, [soil[0], soil[5]], (1, 1))
    # Racines qui pendent de l'herbe.
    roots = ramp("#7A5A3E", 4)
    for _ in range(14):
        x = rnd.randrange(w)
        y = rnd.randint(14, 22)
        for _k in range(rnd.randint(12, 34)):
            x += rnd.choice((-1, 0, 0, 0, 1))
            y += 1
            if y >= h - 6:
                break
            for dx in (-w, 0, w):
                d.point((x + dx, y), fill=rgba(roots[1]))
                d.point((x + dx + 1, y), fill=rgba(roots[0]))
    # Mottes plus claires dans la terre.
    for _ in range(18):
        rx = rnd.uniform(2, 4.5)
        c = Canvas(int(2 * rx) + 4, int(1.2 * rx) + 4, rnd)
        c.blob(c.w / 2.0, c.h / 2.0, rx, rx * 0.45, soil[2:6])
        paste_wrap(img, c.finish(soil[0]), rnd.randrange(w), rnd.randint(24, h - 8))
    # L'herbe du palier (tons de la tuile d'herbe du jeu) : un liseré de gazon au bord irrégulier,
    # son ombre sur la terre, puis des brins qui retombent.
    grass_tones = ramp("#7E8A46", 5, spread=0.45)
    for x in range(w):
        edge = 12 + round(3 * math.sin(2 * math.pi * x * 5 / w) + 2 * math.sin(2 * math.pi * x * 13 / w + 1.1))
        d.line((x, edge + 1, x, edge + 3), fill=rgba(darker(soil[0], 0.8)))
    turf = posterize(fractal((w, 24), (8, 2), rnd, 2), grass_tones[1:4], dither=60)
    for x in range(w):
        edge = 12 + round(3 * math.sin(2 * math.pi * x * 5 / w) + 2 * math.sin(2 * math.pi * x * 13 / w + 1.1))
        img.paste(turf.crop((x, 0, x + 1, edge)), (x, 0))
        d.point((x, edge), fill=rgba(grass_tones[0]))
    for _ in range(220):
        x = rnd.randrange(w)
        n = rnd.randint(3, 10)
        col = rnd.choice(grass_tones[1:])
        y0 = 10 + rnd.randint(0, 5)
        for k in range(n):
            for dx in (-w, 0, w):
                d.point((x + dx + (k // 5), y0 + k), fill=rgba(col if k < n - 1 else grass_tones[0]))
    return img


# --- Matières des bâtiments --------------------------------------------------------------------


def wall_planks(size, rnd):
    w, h = size
    tones = ramp("wood_dark", 6, spread=0.45)
    img = Image.new("RGBA", size, rgba(tones[2]))
    d = ImageDraw.Draw(img)
    x = 0
    while x < w:
        bw = 24 if w - x >= 24 else w - x
        hue = rnd.choice([0.0, 0.0, 0.0, 0.07, -0.06])
        base = mix(tones[2], "#7E6A50" if hue > 0 else "#4E4A44", abs(hue) * 6) if hue else tones[2]
        board = ramp(base, 5, spread=0.4)
        grain = noise((bw, h), (2, 12), rnd)
        board_img = posterize(grain, board[1:4], dither=50)
        img.paste(board_img, (x, 0))
        for g in range(2):
            gx = x + rnd.randint(4, bw - 5)
            for y in range(h):
                if (y // 9 + g) % 3:
                    d.point((gx + round(math.sin((y + g * 40) * 0.08)), y), fill=rgba(board[1]))
        d.line((x, 0, x, h), fill=rgba(tones[0]))
        d.line((x + 1, 0, x + 1, h), fill=rgba(board[4]))
        for ny in (20, 116):
            d.rectangle((x + 4, ny, x + 5, ny + 1), fill=rgba(tones[0]))
            d.rectangle((x + bw - 6, ny, x + bw - 5, ny + 1), fill=rgba(tones[0]))
        x += bw
    # Planches rapiécées : un morceau de planche plus claire cloué en travers.
    for _ in range(1):
        px, py = rnd.randrange(w), rnd.randrange(h)
        patch = Image.new("RGBA", (40, 16), rgba(mix(ramp("wood", 4)[1], tones[2], 0.5)))
        pd = ImageDraw.Draw(patch)
        pd.rectangle((0, 0, 39, 15), outline=rgba(ramp("wood", 4)[0]))
        pd.line((1, 1, 38, 1), fill=rgba(ramp("wood", 4)[3]))
        pd.rectangle((3, 6, 4, 7), fill=rgba(tones[0]))
        pd.rectangle((35, 6, 36, 7), fill=rgba(tones[0]))
        paste_wrap(img, patch, px, py)
    return img


def roof_slate(size, rnd):
    w, h = size
    tones = ramp("slate", 6, spread=0.45)
    img = Image.new("RGBA", size, rgba(tones[0]))
    d = ImageDraw.Draw(img)
    row_h, sw = 16, 24
    for r in range(h // row_h):
        y = r * row_h
        off = (r % 2) * sw // 2
        for k in range(-1, w // sw + 1):
            x = k * sw + off
            v = rnd.choice([1, 2, 2, 3, 3, 4])
            slate = Image.new("RGBA", (sw - 1, row_h + 3), (0, 0, 0, 0))
            sd = ImageDraw.Draw(slate)
            sd.rounded_rectangle((0, 0, sw - 2, row_h + 2), 6, fill=rgba(tones[v]))
            sd.line((2, 1, sw - 4, 1), fill=rgba(tones[min(5, v + 1)]))
            sd.line((3, row_h + 1, sw - 5, row_h + 1), fill=rgba(tones[0]))
            if rnd.random() < 0.08:
                sd.ellipse((4, 4, 10, 9), fill=rgba(ramp("#6E8C4A", 3)[1]))
            paste_wrap(img, slate, x, y)
    return img


def wall_stone(size, rnd):
    return _stones_rows(size, rnd, [24, 32, 24, 32, 24, 32, 24], (28, 52), "#9A9080", "stone",
                        bevel=2, radius=3, grass_in_joints=False)


def wall_plaster(size, rnd):
    w, h = size
    tones = ramp("plaster", 5, spread=0.3)
    img = posterize(fractal(size, (6, 6), rnd, 3), tones[1:4], dither=60)
    wood = ramp("wood_dark", 5, spread=0.4)
    c = Canvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(img)
    for x0 in (0, w // 2):
        c.cylinder(x0 - 6, 0, x0 + 6, h, wood)
        c.cylinder(x0 - 6 + w, 0, x0 + 6 + w, h, wood)
    c.cylinder(0, 0, w, 6, wood, vertical=False)
    c.cylinder(0, h - 5, w, h, wood, vertical=False)
    c.cylinder(0, h // 2 - 5, w, h // 2 + 5, wood, vertical=False)
    for x0 in (6, w // 2 + 6):
        c.line([(x0, h // 2 + 5), (x0 + w // 2 - 12, h - 5)], wood[1], 6)
    return img


def roof_tiles(size, rnd):
    w, h = size
    tones = ramp("tile", 6, spread=0.45)
    img = Image.new("RGBA", size, rgba(tones[0]))
    row_h, tw = 16, 16
    for r in range(h // row_h):
        y = r * row_h
        off = (r % 2) * tw // 2
        for k in range(-1, w // tw + 1):
            x = k * tw + off
            v = rnd.choice([0, 0, 1, -1])
            col = [tones[max(0, min(5, i + v))] for i in range(6)]
            tile = Canvas(tw, row_h + 4, rnd)
            tile.cylinder(0, 0, tw - 1, row_h + 2, col)
            tile.rect(1, row_h + 1, tw - 2, row_h + 3, tones[0])
            paste_wrap(img, tile.img, x, y)
    return img


def roof_tin(size, rnd):
    w, h = size
    tones = ramp("iron", 6, spread=0.45)
    img = Image.new("RGBA", size, rgba(tones[2]))
    d = ImageDraw.Draw(img)
    for x in range(w):
        v = math.sin(2 * math.pi * x / 8.0)
        d.line((x, 0, x, h), fill=rgba(tones[1 + round((v + 1) * 1.8)]))
    for y in range(0, h, 96):
        d.rectangle((0, y, w, y + 2), fill=rgba(tones[0]))
    rust = threshold(fractal(size, (8, 8), rnd, 3), 190)
    img.paste(posterize(fractal(size, (20, 20), rnd, 2), ramp("#8A5A3A", 4)[0:3], dither=60), (0, 0), rust)
    return img


RECIPES = {
    "ground/grass": grass, "ground/grass_dry": grass_dry, "ground/path_dirt": path_dirt,
    "ground/flagstone": flagstone, "ground/cobble": cobble, "ground/sand": sand,
    "ground/rock": rock, "ground/forest_floor": forest_floor, "ground/peat": peat,
    "ground/water": water, "ground/mud": mud, "ground/metal": metal,
    "cliff/cliff": cliff, "cliff/underside": underside, "cliff/lip": lip, "cliff/bank_earth": bank_earth,
    "buildings/materials/wall_planks": wall_planks, "buildings/materials/roof_slate": roof_slate,
    "buildings/materials/wall_stone": wall_stone, "buildings/materials/wall_plaster": wall_plaster,
    "buildings/materials/roof_tiles": roof_tiles, "buildings/materials/roof_tin": roof_tin,
}


# --- Cahier n° 2 : variantes _b, nouvelles tuiles et matières ----------------------------------
#
# Une variante _b part de la tuile livrée (assets/hd2d/ground/<origine>.png) : son pourtour reste
# celui de l'origine (raccord bord à bord avec elle et avec elle-même), son intérieur est un autre
# morceau de la même tuile, cousu le long des chemins où les deux images se ressemblent le plus
# (coupe de coût minimal) : même matière, mêmes couleurs, autre dessin.


def _cut(cost, w, h, box, vertical):
    """Chemin de coût minimal (4-connexe, Dijkstra) qui traverse box = (x0, y0, x1, y1) de haut en
    bas (vertical) ou de gauche à droite : il peut suivre les joints dans tous les sens."""
    x0, y0, x1, y1 = box
    dist = {}
    prev = {}
    heap = []
    starts = [(x, y0) for x in range(x0, x1)] if vertical else [(x0, y) for y in range(y0, y1)]
    for p in starts:
        d = cost[p[1] * w + p[0]]
        dist[p] = d
        heapq.heappush(heap, (d, p))
    end = None
    while heap:
        d, p = heapq.heappop(heap)
        if d > dist.get(p, 1e18):
            continue
        if (vertical and p[1] == y1 - 1) or (not vertical and p[0] == x1 - 1):
            end = p
            break
        x, y = p
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if x0 <= q[0] < x1 and y0 <= q[1] < y1:
                nd = d + cost[q[1] * w + q[0]]
                if nd < dist.get(q, 1e18):
                    dist[q] = nd
                    prev[q] = p
                    heapq.heappush(heap, (nd, q))
    path = [end]
    while path[-1] in prev:
        path.append(prev[path[-1]])
    return path


def quilt(base, patch, rect, band, bias=0.5):
    """base dont le rectangle rect est remplacé par patch, cousu par quatre coupes de coût minimal
    (là où base et patch se ressemblent, de préférence dans les joints sombres des deux) dans des
    bandes de band px le long de ses côtés."""
    w, h = base.size
    diff = ImageChops.difference(base.convert("RGB"), patch.convert("RGB")).convert("L")
    dark = ImageChops.lighter(base.convert("L"), patch.convert("L"))
    cost = [1 + a + bias * b for a, b in zip(diff.getdata(), dark.getdata())]
    x0, y0, x1, y1 = [int(v) for v in rect]
    barrier = Image.new("L", (w, h), 0)
    px = barrier.load()
    for box, vertical in (((x0, 0, x0 + band, h), True), ((x1 - band, 0, x1, h), True),
                          ((0, y0, w, y0 + band), False), ((0, y1 - band, w, y1), False)):
        for x, y in _cut(cost, w, h, box, vertical):
            px[x, y] = 255
    ImageDraw.floodfill(barrier, ((x0 + x1) // 2, (y0 + y1) // 2), 128)
    mask = barrier.point(lambda v: 255 if v == 128 else 0)
    out = base.copy()
    out.paste(patch, (0, 0), mask)
    return out


def _origin(name, size):
    """Image livrée (ou, à défaut, remplaçant) d'une tuile ou d'une matière."""
    img = asset(name)
    if img is None or img.size != size:
        import random as _random
        from hd2d_art import seed_for
        img = RECIPES[name](size, _random.Random(seed_for(name)))
    return img


def variant(origin, size, rnd, margin=12, band=72, bias=0.5):
    """Tuile _b : autre dessin de la tuile d'origine, même pourtour (raccord avec elle)."""
    w, h = size
    base = _origin("ground/" + origin, size)
    shift = (w // 2 + rnd.randint(-w // 8, w // 8), h // 2 + rnd.randint(-h // 8, h // 8))
    out = quilt(base, ImageChops.offset(base, *shift), (margin, margin, w - margin, h - margin), band, bias)
    inner = (w * rnd.uniform(0.22, 0.3), h * rnd.uniform(0.22, 0.3), w * rnd.uniform(0.7, 0.78), h * rnd.uniform(0.7, 0.78))
    shift2 = (w // 4 + rnd.randint(0, w // 8), (3 * h) // 4 + rnd.randint(0, h // 8))
    return quilt(out, ImageChops.offset(base, *shift2), inner, band // 2, bias)


def leaf_sprite(rnd, length, color, shape=None, angle=None):
    """Feuille vue de dessus (5 à 12 cm) : ovale, chêne lobé ou érable, nervure, lumière à gauche."""
    shape = shape or rnd.choice(["oval", "oval", "oak", "maple"])
    angle = rnd.uniform(0, 2 * math.pi) if angle is None else angle
    s = int(length * 1.6) + 4
    c = Canvas(s, s, rnd)
    cx = cy = s / 2.0
    half_len = length / 2.0
    if shape == "maple":
        pts = []
        for k in range(10):
            a = -math.pi / 2 + k * math.pi / 5
            r = half_len if k % 2 == 0 else half_len * 0.45
            pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    elif shape == "oak":
        side = []
        for k in range(9):
            t = k / 8.0
            r = half_len * 0.42 * math.sin(math.pi * t) * (1.0 if k % 2 else 0.6)
            side.append((cx + r, cy - half_len + 2 * half_len * t))
        pts = side + [(2 * cx - x, y) for x, y in reversed(side)]
    else:
        side = [(cx + math.sin(math.pi * k / 8.0) * half_len * 0.42, cy - half_len * math.cos(math.pi * k / 8.0))
                for k in range(9)]
        pts = side + [(2 * cx - x, y) for x, y in reversed(side)]
    pts = rotate_points(pts, cx, cy, angle)
    tones = ramp(color, 5, spread=0.45)
    c.poly(pts, tones[2])
    lit = [p for p in pts if (p[0] - cx) + (p[1] - cy) < 0]
    if len(lit) >= 2:
        c.poly(lit + [(cx, cy)], tones[3])
    rib = rotate_points([(cx, cy - half_len * 0.85), (cx, cy + half_len * 0.95)], cx, cy, angle)
    c.line(rib, tones[1])
    return c.finish(darker(color, 0.6))


AUTUMN = ["leaf_gold", "leaf_rust", "#8A5A36", "leaf_yellow", "leaf_gold", "leaf_rust", "#B07040"]


def leaf_litter(size, rnd):
    soil = ramp("#4E4030", 5, spread=0.4)
    img = posterize(fractal(size, (10, 10), rnd, 3, gain=0.7), soil[0:3], dither=80)
    for _ in range(2200):
        leaf = leaf_sprite(rnd, rnd.choice([5, 7, 8, 9, 10, 10, 11, 12, 12]), rnd.choice(AUTUMN))
        paste_wrap(img, leaf, rnd.randrange(size[0]), rnd.randrange(size[1]))
    _dots(img, rnd, 120, [soil[0]], (1, 2))
    return img


def moss(size, rnd):
    w, h = size
    dark = ramp("#34502C", 5, spread=0.4)
    img = posterize(fractal(size, (10, 10), rnd, 3, gain=0.7), [dark[0], dark[1], dark[2]], dither=90)
    golden = ramp("#8A9440", 5, spread=0.4)
    green = ramp("#4F6B3A", 5, spread=0.45)
    for _ in range(520):
        tones = golden if rnd.random() < 0.3 else green
        r = rnd.uniform(8, 18)
        c = Canvas(int(2.6 * r) + 6, int(2.2 * r) + 6, rnd)
        for _ in range(rnd.randint(4, 8)):
            br = rnd.uniform(0.3, 0.55) * r
            c.blob(c.w / 2.0 + rnd.uniform(-0.6, 0.6) * r, c.h / 2.0 + rnd.uniform(-0.45, 0.45) * r, br, br * 0.85,
                   tones[1:5])
        tex = c.img.getchannel("A")
        for _ in range(int(r * r * 0.5)):
            x, y = rnd.randrange(c.w), rnd.randrange(c.h)
            if tex.getpixel((x, y)) > 128:
                c.pixel(x, y, tones[rnd.choice([0, 1, 4])])
        paste_wrap(img, c.finish(dark[1]), rnd.randrange(w), rnd.randrange(h))
    twig = ramp("#6E5038", 4)
    for _ in range(40):
        n = rnd.randint(6, 16)
        a = rnd.uniform(0, math.pi / 2)
        stick = Image.new("RGBA", (n + 2, n + 2), (0, 0, 0, 0))
        ImageDraw.Draw(stick).line((1, 1, 1 + n * math.cos(a), 1 + n * math.sin(a)), fill=rgba(twig[1]))
        paste_wrap(img, stick, rnd.randrange(w), rnd.randrange(h))
    for _ in range(60):
        paste_wrap(img, leaf_sprite(rnd, rnd.randint(5, 9), rnd.choice(AUTUMN)), rnd.randrange(w), rnd.randrange(h))
    return img


def meadow_flowers(size, rnd):
    w, h = size
    img = _origin("ground/grass", size).copy()
    clover = ramp("#6E9A48", 4)
    for _ in range(90):
        patch = Image.new("RGBA", (5, 5), (0, 0, 0, 0))
        d = ImageDraw.Draw(patch)
        for px, py in ((2, 0), (0, 2), (3, 2)):
            d.rectangle((px, py, px + 1, py + 1), fill=rgba(clover[rnd.randint(2, 3)]))
        d.point((2, 3), fill=rgba(clover[0]))
        paste_wrap(img, patch, rnd.randrange(w), rnd.randrange(h))
    flowers = [("#F2EEE0", "#E8C048"), ("#E8C048", "#C89030"), ("myosotis", "#F2D06B"), ("#F2EEE0", "#E8C048"),
               ("#C8A0D0", "#F2D06B")]
    for _ in range(420):
        petal, center = rnd.choice(flowers)
        s = rnd.choice([1, 1, 2, 3])
        f = Image.new("RGBA", (5, 5), (0, 0, 0, 0))
        d = ImageDraw.Draw(f)
        if s == 1:
            d.point((2, 2), fill=rgba(petal))
        elif s == 2:
            d.rectangle((1, 1, 2, 2), fill=rgba(petal))
            d.point((2, 2), fill=rgba(center))
        else:
            for px, py in ((2, 1), (1, 2), (3, 2), (2, 3)):
                d.point((px, py), fill=rgba(petal))
            d.point((2, 2), fill=rgba(center))
        paste_wrap(img, f, rnd.randrange(w), rnd.randrange(h))
    return img


def gravel(size, rnd):
    base = mix("stone", "sand", 0.4)
    tones = ramp(base, 5, spread=0.45)
    img = posterize(_soft(fractal(size, (14, 14), rnd, 3, gain=0.7)), tones[0:3], dither=120)
    _pebbles(img, rnd, 2400, mix(base, "stone_dark", 0.55), (2, 5))
    _pebbles(img, rnd, 600, mix("stone_dark", "#5A5048", 0.4), (2, 4))
    _pebbles(img, rnd, 160, mix("stone", "stone_dark", 0.3), (3, 6))
    _blades(img, rnd, 140, ramp("grass", 5)[1:], (3, 6))
    return img


def garden_soil(size, rnd):
    w, h = size
    tones = ramp("#56402C", 6, spread=0.5)
    img = posterize(fractal(size, (12, 12), rnd, 3), tones[0:2], dither=60)
    for _ in range(950):
        rx = rnd.uniform(3, 9)
        ry = rx * rnd.uniform(0.6, 0.95)
        c = Canvas(int(2 * rx) + 4, int(2 * ry) + 4, rnd)
        v = rnd.randint(0, 1)
        c.blob(c.w / 2.0, c.h / 2.0, rx, ry, tones[1 + v:5 + v])
        paste_wrap(img, c.finish(tones[0]), rnd.randrange(w), rnd.randrange(h))
    _dots(img, rnd, 300, [tones[0]], (1, 1))
    _pebbles(img, rnd, 30, "stone_dark", (2, 4))
    return img


def planks(size, rnd):
    w, h = size
    widths = []
    while sum(widths) < w:
        widths.append(rnd.randint(20, 24))
    widths[-1] -= sum(widths) - w
    if widths[-1] < 14:
        widths[-2] += widths.pop()
    img = Image.new("RGBA", size)
    d = ImageDraw.Draw(img)
    nail = ramp("iron", 4)
    x = 0
    light = rnd.randrange(len(widths))
    for i, bw in enumerate(widths):
        base = mix("wood", "#9A8A76", rnd.uniform(0.2, 0.6))
        if i == light:
            base = mix(base, "#D8C8A8", 0.45)
        tones = ramp(base, 5, spread=0.4)
        img.paste(posterize(noise((bw, h), (max(2, bw // 3), 3), rnd), tones[1:4], dither=40), (x, 0))
        for _ in range(3):
            gx = x + rnd.randint(3, bw - 3)
            y0 = rnd.randrange(h)
            for k in range(rnd.randint(30, 120)):
                d.point((gx, (y0 + k) % h), fill=rgba(tones[1]))
        d.line((x, 0, x, h), fill=rgba(tones[0]))
        d.line((x + bw - 1, 0, x + bw - 1, h), fill=rgba(darker(tones[0], 0.8)))
        d.line((x + 1, 0, x + 1, h), fill=rgba(tones[4]))
        joint = rnd.randrange(h)
        for jy in (joint, (joint + rnd.randint(150, 230)) % h):
            d.line((x, jy, x + bw - 1, jy), fill=rgba(darker(tones[0], 0.8)))
            d.line((x + 1, (jy + 1) % h, x + bw - 2, (jy + 1) % h), fill=rgba(tones[4]))
            for nx in (x + 4, x + bw - 6):
                for ny in ((jy + 4) % h, (jy - 5) % h):
                    d.rectangle((nx, ny, nx + 1, ny + 1), fill=rgba(nail[0]))
                    d.point((nx, ny), fill=rgba(nail[3]))
        x += bw
    return img


def stream_bed(size, rnd):
    w, h = size
    sand_tones = ramp(mix("sand", "stone_dark", 0.5), 4)
    img = posterize(fractal(size, (10, 10), rnd, 2), sand_tones[0:3], dither=60)
    for _ in range(700):
        base = rnd.choice(["stone", "stone_dark", mix("stone", "#8A9AA0", 0.4), "#A08E78", mix("stone", "sand", 0.5)])
        rx = rnd.uniform(4, 13)
        ry = rx * rnd.uniform(0.6, 0.9)
        c = Canvas(int(2 * rx) + 4, int(2 * ry) + 4, rnd)
        c.blob(c.w / 2.0, c.h / 2.0, rx, ry, ramp(base, 5)[1:5])
        paste_wrap(img, c.finish(darker(base, 0.6)), rnd.randrange(w), rnd.randrange(h))
    water_col = mix("marsh", "#9CC0B4", 0.35)
    img = Image.blend(img, Image.new("RGBA", size, rgba(water_col)), 0.42)
    deep = threshold(fractal(size, (4, 4), rnd, 2), 170)
    img.paste(Image.blend(img, Image.new("RGBA", size, rgba("marsh")), 0.35), (0, 0), deep)
    light = mix("marsh", "#F0F0E0", 0.7)
    for _ in range(260):
        n = rnd.randint(3, 10)
        streak = Image.new("RGBA", (n, 1), rgba(light if rnd.random() < 0.6 else mix(water_col, "#FFFFFF", 0.4)))
        paste_wrap(img, streak, rnd.randrange(w), rnd.randrange(h))
    return img


# Matières des volumes : les variantes partent des matières livrées (même rendu que les murs).


def _spots(img, rnd, count, tones, size=(3, 8)):
    for _ in range(count):
        r = rnd.uniform(*size)
        c = Canvas(int(2 * r) + 4, int(1.6 * r) + 4, rnd)
        c.blob(c.w / 2.0, c.h / 2.0, r, r * 0.75, tones)
        paste_wrap(img, c.finish(darker(tones[0], 0.7)), rnd.randrange(img.width), rnd.randrange(img.height))


def roof_tiles_b(size, rnd):
    img = recolor(_origin("buildings/materials/roof_tiles", size), mix("tile", "#6E3428", 0.45), keep=0.45)
    _spots(img, rnd, 26, ramp("#5E7A3A", 4), (3, 7))
    for _ in range(10):
        chip = Image.new("RGBA", (rnd.randint(5, 10), rnd.randint(3, 6)), rgba("#3A2220"))
        paste_wrap(img, chip, rnd.randrange(size[0]), rnd.randrange(size[1]))
    return img


def roof_slate_b(size, rnd):
    img = recolor(_origin("buildings/materials/roof_slate", size), mix("slate", "#9AA8BC", 0.45), keep=0.4)
    lichen = ramp("#C8B040", 4)
    for _ in range(70):
        dot = Image.new("RGBA", (rnd.randint(1, 3), rnd.randint(1, 2)), rgba(lichen[rnd.randint(1, 3)]))
        paste_wrap(img, dot, rnd.randrange(size[0]), rnd.randrange(size[1]))
    _spots(img, rnd, 8, lichen, (2, 4))
    return img


def wall_plaster_b(size, rnd):
    img = recolor(_origin("buildings/materials/wall_plaster", size), "#B8995A", keep=0.4)
    dirt = threshold(fractal(size, (4, 4), rnd, 3), 190)
    img.paste(Image.blend(img, Image.new("RGBA", size, rgba("#7A6440")), 0.25), (0, 0), dirt)
    return img


def wall_stone_b(size, rnd):
    img = _origin("buildings/materials/wall_stone", size)
    gray = img.convert("L")
    lo, hi = gray.getextrema()
    joints = gray.point(lambda v: 255 if v < lo + (hi - lo) * 0.3 else 0)
    img = recolor(img, mix("stone", "#E8DCC8", 0.35), keep=0.45)
    img.paste(Image.new("RGBA", size, rgba("#5A5048")), (0, 0), joints)
    return img


def wall_brick(size, rnd):
    w, h = size
    mortar = ramp("#B8A88C", 4)
    img = posterize(fractal(size, (12, 12), rnd, 2), mortar[1:3], dither=50)
    row_h, bw = 8, 24
    for r in range(h // row_h):
        off = (r % 2) * bw // 2 + rnd.randint(-2, 2)
        for k in range(-1, w // bw + 1):
            tones = ramp(rnd.choice(["#9A4A34", "#A85A3C", "#8A4030", "#B06848", "#7A3A2C"]), 4, spread=0.35)
            brick = Image.new("RGBA", (bw - 2, row_h - 2), rgba(tones[2]))
            bd = ImageDraw.Draw(brick)
            bd.line((0, 0, bw - 3, 0), fill=rgba(tones[3]))
            bd.line((0, row_h - 3, bw - 3, row_h - 3), fill=rgba(tones[0]))
            for _ in range(3):
                bd.point((rnd.randrange(bw - 2), rnd.randrange(1, row_h - 3)), fill=rgba(tones[1]))
            if rnd.random() < 0.12:
                cx = rnd.randrange(bw - 6)
                bd.rectangle((cx, 0, cx + 4, 1), fill=rgba(mortar[1]))
            paste_wrap(img, brick, k * bw + off, r * row_h)
    return img


def roof_shingles(size, rnd):
    w, h = size
    tones = ramp("#7A6A58", 6, spread=0.5)
    img = Image.new("RGBA", size, rgba(tones[0]))
    row_h = 16
    for r in range(h // row_h):
        x = rnd.randrange(w)
        start = x
        while x < start + w:
            sw = min(rnd.randint(12, 20), start + w - x)
            if sw < 6:
                break
            v = rnd.choice([1, 2, 2, 3, 3, 4])
            sh = Image.new("RGBA", (sw - 1, row_h + 4), (0, 0, 0, 0))
            sd = ImageDraw.Draw(sh)
            sd.rectangle((0, 0, sw - 2, row_h + 3), fill=rgba(tones[v]))
            sd.line((0, 0, 0, row_h + 3), fill=rgba(tones[min(5, v + 1)]))
            for gx in range(3, sw - 2, 4):
                sd.line((gx, 2, gx, row_h - 2), fill=rgba(tones[max(0, v - 1)]))
            sd.rectangle((0, row_h + 1, sw - 2, row_h + 3), fill=rgba(tones[0]))
            paste_wrap(img, sh, x, r * row_h)
            x += sw
    _spots(img, rnd, 22, ramp("#5E7A3A", 4), (3, 6))
    return img


def wall_tin(size, rnd):
    w, h = size
    tones = ramp("#8A9298", 6, spread=0.4)
    img = Image.new("RGBA", size, rgba(tones[2]))
    d = ImageDraw.Draw(img)
    for x in range(w):
        v = math.sin(2 * math.pi * x / 12.0)
        d.line((x, 0, x, h), fill=rgba(tones[1 + round((v + 1) * 1.9)]))
    rust_img = posterize(fractal(size, (16, 16), rnd, 2), ramp("#8A5A3A", 4)[0:3], dither=60)
    streaks = Image.new("L", size, 0)
    sd = ImageDraw.Draw(streaks)
    for sx in (0, w // 2):
        for _ in range(14):
            x = (sx + rnd.randint(-6, 6)) % w
            y = rnd.randrange(h)
            n = rnd.randint(10, 60)
            for dy in (-h, 0):
                sd.line((x, y + dy, x, y + n + dy), fill=255, width=rnd.randint(1, 3))
    img = Image.composite(rust_img, img, streaks)
    d = ImageDraw.Draw(img)
    for sx in (0, w // 2):
        d.line((sx, 0, sx, h), fill=rgba(tones[0]))
        for y in range(8, h, 24):
            d.rectangle((sx + 2, y, sx + 3, y + 1), fill=rgba(tones[5]))
    d.line((0, h // 2, w, h // 2), fill=rgba(tones[0]))
    return img


def roof_tin_b(size, rnd):
    img = _origin("buildings/materials/roof_tin", size).copy()
    rust = threshold(fractal(size, (6, 6), rnd, 3), 140)
    img.paste(recolor(img, "#8A4A2A", keep=0.3), (0, 0), rust)
    iron = ramp("iron", 5)
    for _ in range(3):
        pw, ph = rnd.randint(36, 70), rnd.randint(28, 50)
        tones = ramp(rnd.choice(["#7A848C", "#8A6A4A", "#6E7880"]), 4)
        patch = Image.new("RGBA", (pw, ph), rgba(tones[2]))
        pd = ImageDraw.Draw(patch)
        for x in range(pw):
            pd.line((x, 0, x, ph), fill=rgba(tones[1 + round((math.sin(2 * math.pi * x / 8.0) + 1) * 1.0)]))
        pd.rectangle((0, 0, pw - 1, ph - 1), outline=rgba(iron[0]))
        for x in range(3, pw - 2, 8):
            pd.point((x, 2), fill=rgba(iron[4]))
            pd.point((x, ph - 3), fill=rgba(iron[4]))
        paste_wrap(img, patch, rnd.randrange(size[0]), rnd.randrange(size[1]))
    return img


def wall_planks_b(size, rnd):
    img = _origin("buildings/materials/wall_planks", size).transpose(Image.ROTATE_90)
    return recolor(img, "#9A968C", keep=0.2)


def wall_plaster_c(size, rnd):
    img = recolor(_origin("buildings/materials/wall_plaster", size), "#E2B8A8", keep=0.3)
    stone = _origin("buildings/materials/wall_stone", size)
    chips = threshold(fractal(size, (5, 5), rnd, 3, gain=0.7), 182)
    grown = wrap_x(wrap_y(chips, lambda im: im.filter(ImageFilter.MaxFilter(3))), lambda im: im)
    img.paste(stone, (0, 0), chips)
    img.paste(Image.new("RGBA", size, rgba("#8A6A60")), (0, 0), ImageChops.subtract(grown, chips))
    return img


RECIPES.update({
    "ground/grass_b": lambda size, rnd: variant("grass", size, rnd),
    "ground/forest_floor_b": lambda size, rnd: variant("forest_floor", size, rnd),
    "ground/path_dirt_b": lambda size, rnd: variant("path_dirt", size, rnd),
    "ground/grass_dry_b": lambda size, rnd: variant("grass_dry", size, rnd),
    "ground/flagstone_b": lambda size, rnd: variant("flagstone", size, rnd, bias=1.5),
    "ground/cobble_b": lambda size, rnd: variant("cobble", size, rnd, bias=1.5),
    "ground/sand_b": lambda size, rnd: variant("sand", size, rnd),
    "ground/rock_b": lambda size, rnd: variant("rock", size, rnd, bias=1.5),
    "ground/leaf_litter": leaf_litter, "ground/moss": moss, "ground/meadow_flowers": meadow_flowers,
    "ground/gravel": gravel, "ground/garden_soil": garden_soil, "ground/planks": planks,
    "ground/stream_bed": stream_bed,
    "buildings/materials/roof_tiles_b": roof_tiles_b, "buildings/materials/roof_slate_b": roof_slate_b,
    "buildings/materials/wall_plaster_b": wall_plaster_b, "buildings/materials/wall_stone_b": wall_stone_b,
    "buildings/materials/wall_brick": wall_brick, "buildings/materials/roof_shingles": roof_shingles,
    "buildings/materials/wall_tin": wall_tin, "buildings/materials/roof_tin_b": roof_tin_b,
    "buildings/materials/wall_planks_b": wall_planks_b, "buildings/materials/wall_plaster_c": wall_plaster_c,
})
