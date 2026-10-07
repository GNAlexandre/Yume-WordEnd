"""Recettes HD-2D : tuiles de sol, falaises et matières des bâtiments (sans raccord).

Chaque recette reçoit (taille, générateur aléatoire) et rend une image RGBA opaque qui se répète
sans raccord (tools/hd2d_assets.py, docs/ASSETS_HD2D.md sections 4, 5 et 6.2)."""

import math

from PIL import Image, ImageDraw

from hd2d_art import (Canvas, darker, fractal, mix, noise, paste_wrap, posterize, ramp, rgb, rgba,
                      shade_texture, stretch, threshold)


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


def grass(size, rnd, base="grass", blades=2600, dry=True):
    tones = ramp(base, 5, spread=0.45)
    img = posterize(fractal(size, (12, 12), rnd, 4, gain=0.7), tones[1:4], dither=90)
    if dry:
        patch = threshold(fractal(size, (4, 4), rnd, 3, gain=0.7), 178)
        dry_img = posterize(fractal(size, (16, 16), rnd, 2), ramp("grass_dry", 5)[1:4], dither=80)
        img.paste(dry_img, (0, 0), patch)
    _blades(img, rnd, blades // 3, [tones[0], tones[1], tones[1]], (2, 5))
    _blades(img, rnd, blades, [tones[1], tones[2], tones[3], tones[4]], (3, 6))
    _leaves(img, rnd, 14, [rgb("leaf_rust"), rgb("leaf_gold")])
    return img


def grass_dry(size, rnd):
    tones = ramp("grass_gold", 5, spread=0.5)
    img = posterize(fractal(size, (6, 6), rnd, 3), tones[1:4], dither=70)
    _blades(img, rnd, 1600, tones[1:], (6, 11), slant=0.35)
    _blades(img, rnd, 500, [tones[0], tones[1], tones[2]], (4, 8), slant=0.3)
    _dots(img, rnd, 60, [mix("grass_gold", "#F2E3A4", 0.6)], (2, 2))
    return img


def path_dirt(size, rnd):
    base = mix("wood", "sand", 0.5)
    tones = ramp(base, 5, spread=0.4)
    img = posterize(fractal(size, (10, 10), rnd, 4, gain=0.7), tones[1:4], dither=90)
    ruts = threshold(fractal(size, (2, 8), rnd, 2), 185)
    img.paste(Image.new("RGBA", size, rgba(tones[1])), (0, 0), ruts)
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
    img = posterize(fractal(size, (10, 10), rnd, 4, gain=0.7), tones[0:4], dither=90)
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
    "cliff/cliff": cliff, "cliff/underside": underside, "cliff/lip": lip,
    "buildings/materials/wall_planks": wall_planks, "buildings/materials/roof_slate": roof_slate,
    "buildings/materials/wall_stone": wall_stone, "buildings/materials/wall_plaster": wall_plaster,
    "buildings/materials/roof_tiles": roof_tiles, "buildings/materials/roof_tin": roof_tin,
}
