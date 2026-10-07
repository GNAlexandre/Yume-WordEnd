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

