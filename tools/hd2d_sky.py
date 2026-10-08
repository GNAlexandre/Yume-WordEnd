"""Recettes HD-2D : ciel peint, mer de nuages, îles lointaines et effets (docs/ASSETS_HD2D.md,
sections 8 et 9). Le ciel est un panorama équirectangulaire : u = 0,5 regarde le nord (−Z),
u = 0,25 l'ouest, où se couche le soleil ; v = 0,5 est l'horizon."""

import math

from PIL import Image, ImageDraw, ImageFilter

from hd2d_art import (Canvas, bayer, darker, fractal, mix, posterize, ramp, rgb, rgba,
                      threshold)

SUN_U = 0.25
SUN_V = 0.47


def sky(size, rnd):
    w, h = size
    stops = [(0.0, "#2E2648"), (0.2, "sky_top"), (0.36, "#A9708A"), (0.44, "#D98A6E"),
             (0.5, "sky_low"), (0.52, "cloud_crest"), (0.62, "cloud_hollow"), (1.0, "cloud_deep")]
    grad = Image.new("RGBA", size)
    gd = ImageDraw.Draw(grad)
    bands = 48
    for b in range(bands):
        v0, v1 = b / bands, (b + 1) / bands
        v = (v0 + v1) / 2.0
        for (a, ca), (bb, cb) in zip(stops, stops[1:]):
            if a <= v <= bb:
                col = mix(ca, cb, (v - a) / (bb - a))
                break
        gd.rectangle((0, round(v0 * h), w, round(v1 * h)), fill=rgba(col))
    img = grad
    d = ImageDraw.Draw(img)
    # Soleil couchant à l'ouest, halo en anneaux tramés.
    sx, sy = SUN_U * w, SUN_V * h
    for k, (r, col) in enumerate(((150, "#E9A070"), (110, "#F2B27A"), (78, "#F7C98A"), (52, "#FFD9A0"))):
        layer = Image.new("RGBA", size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).ellipse((sx - r * 1.6, sy - r, sx + r * 1.6, sy + r), fill=rgba(col))
        mask = layer.getchannel("A").point(lambda a, k=k: a // 255 * (90 + 40 * k))
        dith = bayer(size, 200)
        mask = Image.composite(mask, Image.new("L", size, 0), threshold(dith, 255 - (60 + 45 * k)))
        img.paste(layer, (0, 0), mask)
    d.ellipse((sx - 34, sy - 34, sx + 34, sy + 34), fill=rgba("#FFE9B0"))
    d.ellipse((sx - 26, sy - 26, sx + 26, sy + 26), fill=rgba("#FFF4D2"))
    # Nuages du ciel : bancs allongés dans la bande du couchant, dessus éclairé, dessous violet.
    from PIL import ImageChops
    clouds = fractal(size, (12, 6), rnd, 4)
    profile = Image.new("L", size, 0)
    pd = ImageDraw.Draw(profile)
    for y in range(h):
        t = (y - h * 0.1) / (h * 0.34)
        pd.line((0, y, w, y), fill=round(255 * max(0.0, math.sin(math.pi * t)) ** 0.7) if 0 < t < 1 else 0)
    weighted = ImageChops.multiply(clouds, profile)
    mask = threshold(weighted, 120)
    lit = posterize(ImageChops.offset(weighted, 0, 6), [rgb("#B87A8E"), rgb("#E0A08E"), rgb("#F6C8A6"), rgb("#FFE2C0")], dither=70)
    img.paste(lit, (0, 0), mask)
    # Mer de nuages sous l'horizon : crêtes et creux tramés.
    sea = fractal((w, h // 2), (24, 6), rnd, 4)
    sea_img = posterize(sea, [rgb("cloud_deep"), rgb("cloud_hollow"), mix("cloud_hollow", "cloud_crest", 0.5), rgb("cloud_crest")], dither=80)
    mask = Image.new("L", (w, h // 2), 0)
    md = ImageDraw.Draw(mask)
    for y in range(h // 2):
        t = y / (h / 2.0)
        md.line((0, y, w, y), fill=round(255 * min(1.0, t * 6)))
    mask = Image.composite(Image.new("L", mask.size, 255), Image.new("L", mask.size, 0),
                           threshold(Image.blend(mask, bayer(mask.size, 255), 0.3), 128))
    img.paste(sea_img, (0, h // 2), mask)
    # Reflet du soleil sur la mer de nuages.
    d.ellipse((sx - 140, h * 0.52, sx + 140, h * 0.56), fill=rgba("#F7C98A"))
    return img


def cloud_sea(size, rnd):
    w, h = size
    base = fractal(size, (6, 6), rnd, 5, gain=0.55)
    colors = [darker("cloud_deep", 0.7), rgb("cloud_deep"), rgb("cloud_hollow"),
              mix("cloud_hollow", "cloud_crest", 0.5), rgb("cloud_crest"), mix("cloud_crest", "#FFFFFF", 0.4)]
    img = posterize(base, colors, dither=70)
    holes = threshold(fractal(size, (3, 3), rnd, 3), 222)
    img.paste(Image.new("RGBA", size, rgba("#3E3650")), (0, 0), holes)
    return img


def _island(size, rnd, top_color, flat=False, village=False):
    w, h = size
    c = Canvas(w, h, rnd)
    silhouette = ramp(mix("#5E4E78", top_color, 0.25), 5, spread=0.4)
    top_y = h * (0.38 if flat else 0.32)
    pts = [(w * 0.06, top_y + h * 0.04)]
    for k in range(1, 12):
        x = w * (0.06 + 0.88 * k / 12.0)
        pts.append((x, top_y + rnd.uniform(-h * 0.02, h * 0.03)))
    pts.append((w * 0.94, top_y + h * 0.05))
    cone = pts + [(w * 0.62, h * 0.82), (w * 0.52, h), (w * 0.44, h * 0.86)]
    c.poly(cone, silhouette[1])
    c.poly(pts + [(w * 0.5, h * 0.62)], silhouette[2])
    trees = ramp(mix("#4E5A6E", top_color, 0.35), 4)
    for _ in range(18 if not flat else 8):
        x = rnd.uniform(w * 0.1, w * 0.9)
        c.blob(x, top_y - rnd.uniform(4, 16), rnd.uniform(10, 24), rnd.uniform(10, 20), trees[1:])
    if village:
        for _ in range(6):
            x = rnd.uniform(w * 0.3, w * 0.7)
            c.rect(x, top_y - 22, x + 18, top_y, silhouette[3])
            c.poly([(x - 3, top_y - 22), (x + 9, top_y - 34), (x + 21, top_y - 22)], silhouette[0])
            c.rect(x + 6, top_y - 14, x + 10, top_y - 9, rgb("crystal"))
    img = c.finish(darker("#5E4E78", 0.5))
    return img


def distant_island_a(size, rnd):
    return _island(size, rnd, "#7A5A70")


def distant_island_b(size, rnd):
    return _island(size, rnd, "#8A6A6E", flat=True, village=True)


def distant_island_c(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp("#6E5E80", 5)
    c.poly([(w * 0.3, h * 0.4), (w * 0.45, h * 0.18), (w * 0.62, h * 0.3), (w * 0.7, h * 0.42),
            (w * 0.55, h * 0.9), (w * 0.48, h)], tones[1])
    c.poly([(w * 0.3, h * 0.4), (w * 0.45, h * 0.18), (w * 0.5, h * 0.42), (w * 0.48, h * 0.8)], tones[3])
    return c.finish(darker("#5E4E78", 0.5))


def fx_shadow(size, rnd):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    for k in range(12):
        t = k / 12.0
        a = round(18 + 10 * k)
        layer = Image.new("RGBA", size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).ellipse((w * t * 0.4, h * t * 0.4, w - w * t * 0.4, h - h * t * 0.4), fill=(24, 18, 36, a))
        img = Image.alpha_composite(img, layer)
    return img.filter(ImageFilter.GaussianBlur(2))


def _radial(size, color, power=1.6):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    cr, cg, cb = rgb(color)
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - w / 2.0) / (w / 2.0)
            dy = (y + 0.5 - h / 2.0) / (h / 2.0)
            d = math.sqrt(dx * dx + dy * dy)
            a = max(0.0, 1.0 - d) ** power
            px[x, y] = (cr, cg, cb, round(255 * a))
    return img


def fx_glow(size, rnd):
    return _radial(size, "#FFD9A0", 1.8)


def fx_light_pool(size, rnd):
    return _radial(size, "#FFC880", 1.3)


RECIPES = {
    "sky/sky": sky, "sky/cloud_sea": cloud_sea, "sky/distant_island_a": distant_island_a,
    "sky/distant_island_b": distant_island_b, "sky/distant_island_c": distant_island_c,
    "fx/shadow": fx_shadow, "fx/glow": fx_glow, "fx/light_pool": fx_light_pool,
}


# --- Cahier n° 2 (docs/ASSETS_HD2D_MONDE.md, section 13, lot G) ------------------------------------
#
# Nuages, brume et rais de lumière en alpha doux à paliers ; îles lointaines en silhouettes
# violacées (48 px/m) ; ciels du crépuscule et de la nuit au cadrage de sky.png.


def cloud(size, rnd, bumps, flat=0.62, stretch=1.0, fray=0.0, dark_base=0.0):
    """Nuage en pixel art : bosses (ellipses) sur une base plate, sommet pêche éclairé par le
    couchant, base lavande, paliers de couleur ; bords en alpha doux, jamais coupés par l'image."""
    w, h = size
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    base_y = h * flat
    for k in range(bumps):
        t = (k + 0.5) / bumps
        cx = w * (0.1 + 0.8 * t) + rnd.uniform(-w * 0.03, w * 0.03)
        top = h * (0.12 + 0.3 * abs(t - 0.45) ** 1.2 * 2 + rnd.uniform(-0.04, 0.06))
        rx = min(w * rnd.uniform(0.07, 0.13) * stretch, cx - 4, w - 5 - cx)
        d.ellipse((cx - rx, top, cx + rx, base_y + (base_y - top) * 0.25), fill=255)
    d.rectangle((w * 0.12, base_y - h * 0.08, w * 0.88, base_y), fill=255)
    if fray:
        for _ in range(int(30 * fray)):
            x = w * rnd.uniform(0.7, 0.92)
            y = h * rnd.uniform(0.35, 0.65)
            r = rnd.uniform(2, 6)
            d.ellipse((x - r * 3, y - r, x + r * 3, y + r), fill=255)
    d.rectangle((0, int(base_y + h * 0.04), w, h), fill=0)
    mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    edge = _soft_rim(mask)
    lit = [rgb("cloud_crest"), mix("cloud_crest", "#FFF4E8", 0.5)]
    mid = [rgb("cloud_hollow"), mix("cloud_hollow", "cloud_crest", 0.5)]
    low = [mix("cloud_deep", "#2E2640", dark_base), rgb("cloud_deep")]
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    mp = mask.load()
    ep = edge.load()
    noise = fractal(size, (8, 4), rnd, 2).load()
    top_of = [h] * w
    for x in range(w):
        for y in range(h):
            if mp[x, y]:
                top_of[x] = y
                break
    for y in range(h):
        for x in range(w):
            if not mp[x, y]:
                continue
            depth = (y - top_of[x]) / max(1.0, base_y - top_of[x] + 1)
            v = depth + (noise[x, y] - 128) / 900.0 - 0.14 * (1.0 - x / float(w))
            dither = 0.05 if (x + y) % 2 else -0.05
            v += dither
            if v < 0.18:
                col = lit[1]
            elif v < 0.4:
                col = lit[0]
            elif v < 0.62:
                col = mid[1]
            elif v < 0.82:
                col = mid[0]
            elif v < 0.95:
                col = low[1]
            else:
                col = low[0]
            a = 255 if not ep[x, y] else (150 if (x + y) % 2 else 90)
            px[x, y] = col + (a,)
    return img


def _soft_rim(mask):
    """Bord de 2 px de la silhouette (où l'alpha s'adoucit)."""
    from PIL import ImageChops
    return ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(5)))


def distant_island_d(size, rnd):
    w, h = size
    left = _island((int(w * 0.48), h), rnd, "#7A5A70")
    right = _island((int(w * 0.44), int(h * 0.8)), rnd, "#8A6A6E", flat=True)
    c = Canvas(w, h, rnd)
    c.img.alpha_composite(left, (0, 0))
    c.img.alpha_composite(right, (w - right.width, h - right.height - int(h * 0.12)))
    chain = ramp("#4A4060", 4)
    y0, y1 = h * 0.42, h * 0.5
    for k in range(2):
        pts = [(w * (0.4 + 0.22 * t / 20.0), y0 + k * 12 + math.sin(math.pi * t / 20.0) * 30) for t in range(21)]
        for x, y in pts[::2]:
            c.ellipse(x, y, 3, 2, chain[1])
    deck = [(w * (0.4 + 0.22 * t / 20.0), y1 + math.sin(math.pi * t / 20.0) * 18) for t in range(21)]
    c.line(deck, chain[2], 3)
    for x, y in deck[::3]:
        c.line([(x, y), (x, y - 14 - math.sin(math.pi * (x - w * 0.4) / (w * 0.22)) * 6)], chain[0], 1)
    return c.img


def distant_island_e(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp("#6E5E80", 5)
    c.poly([(w * 0.36, h * 0.46), (w * 0.44, h * 0.16), (w * 0.52, h * 0.12), (w * 0.6, h * 0.3), (w * 0.64, h * 0.48),
            (w * 0.54, h * 0.86), (w * 0.5, h), (w * 0.44, h * 0.8)], tones[1])
    c.poly([(w * 0.36, h * 0.46), (w * 0.44, h * 0.16), (w * 0.48, h * 0.4), (w * 0.47, h * 0.78)], tones[3])
    stone = ramp("#9A8AA0", 4)
    c.rect(w * 0.47, h * 0.02, w * 0.53, h * 0.14, stone[2])
    c.rect(w * 0.46, h * 0.0 + 2, w * 0.54, h * 0.035, stone[1])
    c.rect(w * 0.485, h * 0.04, w * 0.515, h * 0.07, "#FFE6A6")
    return c.finish(darker("#5E4E78", 0.5))


def distant_island_f(size, rnd):
    w, h = size
    img = _island(size, rnd, "#5E6A6E")
    c = Canvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(img)
    pine = ramp(mix("#3D5946", "#6E5E80", 0.45), 4)
    for k in range(9):
        x = w * (0.15 + 0.08 * k)
        c.poly([(x, h * 0.2), (x - 12, h * 0.36), (x + 12, h * 0.36)], pine[1 + k % 2])
    water = ramp("#A8B8D0", 3)
    c.rect(w * 0.86, h * 0.36, w * 0.88, h * 0.9, water[1])
    c.rect(w * 0.865, h * 0.36, w * 0.87, h * 0.9, water[2])
    return c.finish(darker("#5E4E78", 0.5))


def island_53(size, rnd):
    w, h = size
    img = _island(size, rnd, "#8A6A6E", flat=True, village=True)
    c = Canvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(img)
    metal = ramp("#8A8AA0", 4)
    top = h * 0.38
    c.rect(w * 0.62, top - 4, w * 0.9, top + 6, metal[2])
    for x in range(int(w * 0.62), int(w * 0.9), 14):
        c.rect(x, top - 4, x + 2, top + 6, metal[0])
    for k, x in enumerate((0.7, 0.84)):
        c.poly([(w * x - 26, top - 20), (w * x + 26, top - 22), (w * x + 18, top - 8), (w * x - 20, top - 8)], ramp("#6A5A6A", 4)[2])
        c.rect(w * x - 8, top - 30, w * x + 6, top - 20, ramp("#6A5A6A", 4)[3])
        c.rect(w * x - 2, top - 26, w * x + 1, top - 24, rgb("crystal"))
    for _ in range(12):
        x = rnd.uniform(w * 0.25, w * 0.6)
        c.pixel(x, top - rnd.uniform(4, 14), rgb("crystal"))
    return c.finish(darker("#5E4E78", 0.5))


def horizon_islands(size, rnd):
    from hd2d_art import WrapCanvas
    w, h = size
    c = WrapCanvas(w, h, rnd)
    tones = ramp("#7A6E96", 4)
    x = 0.0
    while x < w:
        iw = rnd.uniform(40, 130)
        ih = rnd.uniform(0.25, 0.6) * h
        top = h * rnd.uniform(0.3, 0.55)
        reach = h if rnd.random() < 0.25 else min(h - 2, top + ih)
        c.poly([(x, top), (x + iw * 0.3, top - rnd.uniform(4, 16)), (x + iw * 0.7, top - rnd.uniform(2, 12)), (x + iw, top),
                (x + iw * 0.55, reach)], tones[rnd.randint(1, 2)])
        c.poly([(x, top), (x + iw * 0.3, top - 4), (x + iw * 0.45, reach - (reach - top) * 0.3)], tones[3])
        x += iw + rnd.uniform(30, 160)
    c.poly([(w * 0.5, h * 0.4), (w * 0.52, h * 0.3), (w * 0.55, h * 0.4), (w * 0.53, h)], tones[1])
    return c.finish(darker("#5E4E78", 0.6))


def mist_band(size, rnd):
    w, h = size
    n = fractal(size, (12, 2), rnd, 3)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    npx = n.load()
    for y in range(h):
        v = math.sin(math.pi * (y + 0.5) / h) ** 1.5
        for x in range(w):
            a = v * (0.6 + 0.4 * npx[x, y] / 255.0)
            level = 0 if a < 0.15 else (50 if a < 0.35 else (90 if a < 0.6 else 125))
            if y < 2 or y > h - 3:
                level = 0
            col = mix("#E8C8D8", "#C8B8E0", npx[x, y] / 255.0)
            px[x, y] = col + (level,)
    return img


def light_shaft(size, rnd, wide=False):
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        t = y / float(h - 1)
        cx = w * (0.25 + 0.5 * t)
        half = w * (0.12 + 0.14 * t) * (1.3 if wide else 1.0)
        for x in range(w):
            dx = abs(x - cx) / half
            if dx >= 1:
                continue
            a = (1 - dx) * (0.6 + 0.4 * math.sin(math.pi * min(1.0, t * 1.1 + 0.05)))
            level = 38 if a < 0.4 else (60 if a < 0.7 else (75 if wide else 90))
            if x < 1 or x > w - 2 or y < 1:
                level = 0
            px[x, y] = rgb("#F8D890") + (level if not wide else int(level * 0.8),)
    for _ in range(int(h / 6)):
        y = rnd.uniform(4, h - 4)
        t = y / float(h)
        x = w * (0.25 + 0.5 * t) + rnd.uniform(-1, 1) * w * 0.1
        if 1 <= x < w - 2:
            px[int(x), int(y)] = rgb("#FFF0C0") + (140,)
    return img


def _sky_base(size, stops):
    w, h = size
    img = Image.new("RGBA", size)
    d = ImageDraw.Draw(img)
    bands = 64
    for b in range(bands):
        v0, v1 = b / bands, (b + 1) / bands
        v = (v0 + v1) / 2.0
        for (a, ca), (bb, cb) in zip(stops, stops[1:]):
            if a <= v <= bb:
                col = mix(ca, cb, (v - a) / (bb - a))
                break
        d.rectangle((0, round(v0 * h), w, round(v1 * h)), fill=rgba(col))
    return img


def _stars(img, rnd, count, v_max, colors):
    w, h = img.size
    px = img.load()
    for _ in range(count):
        x, y = rnd.randrange(w), rnd.randrange(int(h * v_max))
        px[x, y] = rgba(rnd.choice(colors))
        if rnd.random() < 0.08 and 0 < x < w - 1 and 0 < y:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                px[x + dx, y + dy] = rgba(mix(colors[0], "#000000", 0.4))


def _sea(img, rnd, colors):
    w, h = img.size
    sea = fractal((w, h // 2), (24, 6), rnd, 4)
    img.paste(posterize(sea, colors, dither=80), (0, h // 2))


def sky_dusk(size, rnd):
    w, h = size
    img = _sky_base(size, [(0.0, "#1E1838"), (0.25, "#3A2A5A"), (0.4, "#6A4A78"), (0.47, "#C86A5A"), (0.5, "#E8945A"),
                           (0.52, "#B8889A"), (0.7, "#6A5A80"), (1.0, "#3E3658")])
    glow = Image.new("L", size, 0)
    gd = ImageDraw.Draw(glow)
    for k in range(6):
        r = 340 - k * 50
        gd.ellipse((w * SUN_U - r * 1.8, h * 0.5 - r * 0.45, w * SUN_U + r * 1.8, h * 0.5 + r * 0.25), fill=40 + k * 30)
    dith = bayer(size, 255)
    mask = Image.composite(glow, Image.new("L", size, 0), threshold(dith, 120))
    img.paste(Image.new("RGBA", size, rgba("#F0A060")), (0, 0), mask)
    _stars(img, rnd, 260, 0.3, ["#F0E8D0", "#D8D0F0", "#F8F0E0"])
    _sea(img, rnd, [rgb("#3E3658"), rgb("#5A4A70"), rgb("#8A6A80"), rgb("#B8889A")])
    return img


def sky_night(size, rnd):
    w, h = size
    img = _sky_base(size, [(0.0, "#0E1024"), (0.3, "#1A2040"), (0.47, "#2A3460"), (0.5, "#3A4A78"), (0.52, "#2A3458"),
                           (1.0, "#141A30")])
    d = ImageDraw.Draw(img)
    milky = Image.new("L", size, 0)
    md = ImageDraw.Draw(milky)
    for x in range(w):
        y = h * (0.22 + 0.12 * math.sin(2 * math.pi * x / w + 0.8))
        md.line((x, y - 26, x, y + 26), fill=70)
        md.line((x, y - 12, x, y + 12), fill=140)
    n = fractal(size, (32, 16), rnd, 3)
    from PIL import ImageChops
    milky = ImageChops.multiply(milky, n.point(lambda v: min(255, v + 60)))
    dots = Image.new("L", size, 0)
    dots.putdata([255 if rnd.random() < 0.18 else 0 for _ in range(w * h)])
    img.paste(Image.new("RGBA", size, rgba("#B8C0E8")), (0, 0), ImageChops.multiply(threshold(milky, 60), dots))
    _stars(img, rnd, 900, 0.48, ["#F0F0FF", "#D8E0FF", "#FFF0D0"])
    d.ellipse((w * 0.62 - 22, h * 0.2 - 22, w * 0.62 + 22, h * 0.2 + 22), fill=rgba("#E8E8D0"))
    d.ellipse((w * 0.62 - 14, h * 0.2 - 20, w * 0.62 + 18, h * 0.2 + 12), fill=rgba("#F8F8E8"))
    _sea(img, rnd, [rgb("#141A30"), rgb("#2A3458"), rgb("#4A5A88"), rgb("#7A8AB8")])
    return img


RECIPES.update({
    "sky/cloud_a": lambda s, r: cloud(s, r, 9, flat=0.7),
    "sky/cloud_b": lambda s, r: cloud(s, r, 7, flat=0.62, stretch=1.2, fray=1.0),
    "sky/cloud_c": lambda s, r: cloud(s, r, 5, flat=0.7, stretch=1.4),
    "sky/cloud_d": lambda s, r: cloud(s, r, 14, flat=0.6, stretch=0.9),
    "sky/cloud_e": lambda s, r: cloud(s, r, 6, flat=0.72, stretch=1.1, dark_base=0.6),
    "sky/distant_island_d": distant_island_d, "sky/distant_island_e": distant_island_e,
    "sky/distant_island_f": distant_island_f, "sky/island_53": island_53, "sky/horizon_islands": horizon_islands,
    "sky/mist_band": mist_band, "sky/light_shaft_a": light_shaft,
    "sky/light_shaft_b": lambda s, r: light_shaft(s, r, wide=True),
    "sky/sky_dusk": sky_dusk, "sky/sky_night": sky_night,
})

