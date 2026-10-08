#!/usr/bin/env python3
"""Outils de dessin du pixel art HD-2D de remplacement (tools/hd2d_assets.py) : couleurs de
MONDE.md 5.4 en paliers, bruit sans raccord, tramage ordonné, formes ombrées, contours ; pour le
cahier n° 2, lecture des images livrées, dessin sans raccord à gauche et à droite, alpha doux en
paliers, recoloration."""

import colorsys
import math
import os
import zlib

from PIL import Image, ImageChops, ImageDraw, ImageFilter

PPM = 96

# --- Couleurs (docs/lore/MONDE.md, section 5.4) -------------------------------------------------

PALETTE = {
    "grass": "#87A35E", "grass_dry": "#AFA764", "grass_gold": "#C2AA66",
    "leaf_gold": "#CC9446", "leaf_rust": "#A95A3A", "leaf_yellow": "#D2B45C", "pine": "#3D5946",
    "stone": "#C2B49F", "stone_dark": "#837667", "sand": "#D6C19E",
    "wood": "#A57C58", "wood_dark": "#654D3C", "plaster": "#EAE0CB",
    "slate": "#5E6C86", "tile": "#B65E4B", "iron": "#717B84", "brass": "#B4955E",
    "marsh": "#4A675F", "reed": "#9C9563", "myosotis": "#7F9CCF", "crystal": "#FFE6A6",
    "pennant": "#AE4A3E", "sky_top": "#6E5C86", "sky_low": "#EBA676",
    "cloud_crest": "#F4DCC6", "cloud_hollow": "#BBA3BF", "cloud_deep": "#82769C",
}


def rgb(value):
    if isinstance(value, tuple):
        return value[:3]
    value = PALETTE.get(value, value).lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def rgba(value, alpha=255):
    return rgb(value) + (alpha,)


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _toward(h, target, max_step):
    """Teinte h décalée vers target d'au plus max_step (par le plus court chemin)."""
    diff = (target - h + 0.5) % 1.0 - 0.5
    return (h + max(-max_step, min(max_step, diff))) % 1.0


def ramp(base, n=5, spread=0.5, shift=0.03):
    """Paliers du plus sombre au plus clair, avec un léger glissement de teinte du pixel art :
    ombres vers le bleu-violet, lumières vers le jaune chaud."""
    r, g, b = [c / 255.0 for c in rgb(base)]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    out = []
    for i in range(n):
        t = (i - (n - 1) / 2.0) / ((n - 1) / 2.0) if n > 1 else 0.0
        hh = _toward(h, 0.68 if t < 0 else 0.14, abs(t) * shift)
        vv = min(1.0, max(0.0, v * (1.0 + t * spread * (0.9 if t < 0 else 0.6))))
        ss = min(1.0, max(0.0, s * (1.0 - t * 0.12)))
        rr, gg, bb = colorsys.hsv_to_rgb(hh, ss, vv)
        out.append((round(rr * 255), round(gg * 255), round(bb * 255)))
    return out


def darker(color, factor=0.55):
    return ramp(color, 5, spread=(1.0 - factor) / 0.45 * 0.5)[0]


# --- Bruit, tramage, palettes --------------------------------------------------------------------

BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def noise(size, cells, rnd, smooth=Image.BICUBIC):
    """Bruit de valeurs sans raccord (L), cells = (colonnes, rangées) de la grille de départ."""
    w, h = size
    cw, ch = cells
    small = Image.new("L", (cw, ch))
    small.putdata([rnd.randrange(256) for _ in range(cw * ch)])
    big = Image.new("L", (cw * 3, ch * 3))
    for i in range(3):
        for j in range(3):
            big.paste(small, (i * cw, j * ch))
    big = big.resize((w * 3, h * 3), smooth)
    return big.crop((w, h, 2 * w, 2 * h))


def fractal(size, base_cells, rnd, octaves=3, gain=0.5):
    """Somme d'octaves de noise(), étirée sur 0..255."""
    w, h = size
    total = None
    weight = 1.0
    weights = 0.0
    for o in range(octaves):
        cells = (max(1, base_cells[0] * 2 ** o), max(1, base_cells[1] * 2 ** o))
        layer = noise(size, cells, rnd)
        if total is None:
            total = layer
        else:
            total = Image.blend(total, layer, weight / (weights + weight))
        weights += weight
        weight *= gain
    return stretch(total)


def stretch(gray):
    lo, hi = gray.getextrema()
    if hi <= lo:
        return gray
    return gray.point(lambda v: round((v - lo) * 255 / (hi - lo)))


def bayer(size, amount):
    """Trame ordonnée 4 × 4 (valeurs centrées sur 128, amplitude amount)."""
    tile = Image.new("L", (4, 4))
    tile.putdata([round(128 + (BAYER4[y][x] / 15.0 - 0.5) * amount) for y in range(4) for x in range(4)])
    out = Image.new("L", size)
    for x in range(0, size[0], 4):
        for y in range(0, size[1], 4):
            out.paste(tile, (x, y))
    return out


def posterize(gray, colors, dither=40, bias=0):
    """Niveaux de gris → couleurs (du sombre au clair), tramage ordonné : du pixel art."""
    n = len(colors)
    g = ImageChops.add(gray, bayer(gray.size, dither), 1.0, -128 + bias)
    idx = g.point(lambda v: min(n - 1, v * n // 256))
    pal = Image.frombytes("P", gray.size, idx.tobytes())
    flat = []
    for c in colors:
        flat.extend(rgb(c))
    pal.putpalette(flat + [0] * (768 - len(flat)))
    return pal.convert("RGBA")


def threshold(gray, level):
    return gray.point(lambda v: 255 if v >= level else 0)


def paste_wrap(dst, src, x, y, mask=None):
    """Colle src en (x, y) et ses copies décalées d'une largeur ou d'une hauteur : sans raccord."""
    w, h = dst.size
    mask = mask if mask is not None else (src if src.mode == "RGBA" else None)
    for dx in (-w, 0, w):
        for dy in (-h, 0, h):
            px, py = x + dx, y + dy
            if px < w and py < h and px + src.width > 0 and py + src.height > 0:
                dst.paste(src, (px, py), mask)


def outline(img, color, alpha_level=128):
    """Contour de 1 px autour de la silhouette (alpha seuillé)."""
    a = img.getchannel("A").point(lambda v: 255 if v >= alpha_level else 0)
    ring = ImageChops.subtract(a.filter(ImageFilter.MaxFilter(3)), a)
    out = img.copy()
    out.paste(Image.new("RGBA", img.size, rgba(color)), (0, 0), ring)
    return out


def inner_edge(img, color, side="br", alpha_level=128):
    """Liseré intérieur d'un côté (bas-droite : ombre ; haut-gauche : lumière)."""
    a = img.getchannel("A").point(lambda v: 255 if v >= alpha_level else 0)
    dx, dy = (1, 1) if side == "br" else (-1, -1)
    shifted = ImageChops.offset(a, -dx, -dy)
    edge = ImageChops.subtract(a, shifted)
    out = img.copy()
    out.paste(Image.new("RGBA", img.size, rgba(color)), (0, 0), edge)
    return out


def hard_alpha(img):
    a = img.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    out = img.copy()
    out.putalpha(a)
    return out


def tile_fill(size, tile, offset=(0, 0)):
    out = Image.new("RGBA", size)
    tw, th = tile.size
    for x in range(-offset[0] % tw - tw, size[0], tw):
        for y in range(-offset[1] % th - th, size[1], th):
            out.paste(tile, (x, y))
    return out


def seed_for(name):
    return zlib.crc32(name.encode("utf-8"))


# --- Formes ombrées ------------------------------------------------------------------------------


class Canvas:
    """Image RGBA et outils de dessin en pixels (y vers le bas, origine en haut à gauche)."""

    def __init__(self, w, h, rnd):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.w, self.h = w, h
        self.rnd = rnd
        self.draw = ImageDraw.Draw(self.img)

    def blob(self, cx, cy, rx, ry, colors, light=(-0.5, -0.6), rim=True):
        """Ellipse ombrée en paliers décalés vers la lumière (sphère de pixel art)."""
        rx, ry = max(1.0, rx), max(1.0, ry)
        x0, y0 = int(cx - rx) - 1, int(cy - ry) - 1
        lw, lh = int(2 * rx) + 3, int(2 * ry) + 3
        layer = Image.new("RGBA", (lw, lh), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        lcx, lcy = cx - x0, cy - y0
        d.ellipse((lcx - rx, lcy - ry, lcx + rx, lcy + ry), fill=rgba(colors[0]))
        n = len(colors)
        for i in range(1, n):
            t = i / float(n)
            sx, sy = rx * (1.0 - 0.32 * t), ry * (1.0 - 0.32 * t)
            ox, oy = lcx + light[0] * rx * 0.42 * t, lcy + light[1] * ry * 0.42 * t
            d.ellipse((ox - sx, oy - sy, ox + sx, oy + sy), fill=rgba(colors[i]))
        mask = Image.new("L", (lw, lh), 0)
        ImageDraw.Draw(mask).ellipse((lcx - rx, lcy - ry, lcx + rx, lcy + ry), fill=255)
        self.img.paste(layer, (x0, y0), mask)

    def poly(self, points, color, outline_color=None):
        self.draw.polygon([(round(x), round(y)) for x, y in points], fill=rgba(color),
                          outline=rgba(outline_color) if outline_color else None)

    def rect(self, x0, y0, x1, y1, color):
        x0, x1 = sorted((round(x0), round(x1)))
        y0, y1 = sorted((round(y0), round(y1)))
        if x1 > x0 and y1 > y0:
            self.draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=rgba(color))

    def line(self, points, color, width=1):
        self.draw.line([(round(x), round(y)) for x, y in points], fill=rgba(color), width=width)

    def ellipse(self, cx, cy, rx, ry, color):
        self.draw.ellipse((round(cx - rx), round(cy - ry), round(cx + rx), round(cy + ry)), fill=rgba(color))

    def pixel(self, x, y, color):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((int(x), int(y)), rgba(color))

    def cylinder(self, x0, y0, x1, y1, colors, vertical=True):
        """Rectangle ombré comme un cylindre (bandes du clair à gauche au sombre à droite)."""
        n = len(colors)
        order = [colors[min(n - 1, max(0, k))] for k in (n - 2, n - 1, n - 2, n - 3, n - 4, 0)]
        if vertical:
            w = x1 - x0
            bands = [0.0, 0.12, 0.32, 0.62, 0.82, 0.92, 1.0]
            for i in range(6):
                self.rect(x0 + w * bands[i], y0, x0 + w * bands[i + 1] + 0.999, y1, order[i])
        else:
            h = y1 - y0
            bands = [0.0, 0.12, 0.32, 0.62, 0.82, 0.92, 1.0]
            for i in range(6):
                self.rect(x0, y0 + h * bands[i], x1, y0 + h * bands[i + 1] + 0.999, order[i])

    def speckle(self, mask_img, count, colors, size=(1, 2)):
        """Points de couleur tirés au hasard dans la silhouette (alpha) : texture."""
        a = mask_img.getchannel("A")
        for _ in range(count):
            x, y = self.rnd.randrange(self.w), self.rnd.randrange(self.h)
            if a.getpixel((x, y)) >= 128:
                s = self.rnd.randint(size[0], size[1])
                c = self.rnd.choice(colors)
                self.rect(x, y, x + s, y + max(1, s - 1), c)

    def finish(self, outline_color, alpha_level=128):
        self.img = hard_alpha(self.img)
        self.img = outline(self.img, outline_color, alpha_level)
        return self.img


def shade_texture(img, rnd, amount=0.08, cells=8):
    """Assombrit et éclaircit doucement l'image par grandes taches (bruit sans raccord)."""
    n = fractal(img.size, (cells, cells), rnd, 2)
    dark = Image.new("RGBA", img.size, (40, 30, 60, 255))
    light = Image.new("RGBA", img.size, (255, 240, 200, 255))
    lo = n.point(lambda v: round(max(0, 120 - v) * amount * 2.2))
    hi = n.point(lambda v: round(max(0, v - 136) * amount * 2.2))
    out = img.copy()
    out.paste(dark, (0, 0), lo)
    out.paste(light, (0, 0), hi)
    a = img.getchannel("A")
    out.putalpha(a)
    return out


# --- Cahier n° 2 : images livrées, dessin sans raccord, alpha doux --------------------------------

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def asset(key):
    """Image du jeu (« props/laundry_line », « buildings/materials/wall_stone ») en RGBA, ou None :
    les remplaçants du cahier n° 2 partent des images livrées quand ils en dérivent (variante de
    tuile, flanc d'une façade, bande animée d'un panneau)."""
    path = os.path.join(ROOT, "assets", "hd2d", key + ".png")
    if not os.path.exists(path):
        return None
    return Image.open(path).convert("RGBA")


class WrapCanvas(Canvas):
    """Canvas dont chaque trait est aussi posé une largeur à gauche et à droite : le dessin se
    raccorde à gauche et à droite (lisières, bordures, modules de clôture)."""

    def blob(self, cx, cy, rx, ry, colors, light=(-0.5, -0.6), rim=True):
        for dx in (-self.w, 0, self.w):
            if -rx - 2 <= cx + dx <= self.w + rx + 2:
                Canvas.blob(self, cx + dx, cy, rx, ry, colors, light, rim)

    def poly(self, points, color, outline_color=None):
        for dx in (-self.w, 0, self.w):
            Canvas.poly(self, [(x + dx, y) for x, y in points], color, outline_color)

    def rect(self, x0, y0, x1, y1, color):
        for dx in (-self.w, 0, self.w):
            Canvas.rect(self, x0 + dx, y0, x1 + dx, y1, color)

    def line(self, points, color, width=1):
        for dx in (-self.w, 0, self.w):
            Canvas.line(self, [(x + dx, y) for x, y in points], color, width)

    def ellipse(self, cx, cy, rx, ry, color):
        for dx in (-self.w, 0, self.w):
            Canvas.ellipse(self, cx + dx, cy, rx, ry, color)

    def pixel(self, x, y, color):
        Canvas.pixel(self, int(x) % self.w, y, color)

    def finish(self, outline_color, alpha_level=128):
        self.img = wrap_x(hard_alpha(self.img), lambda im: outline(im, outline_color, alpha_level))
        return self.img


def wrap_x(img, fn):
    """Applique fn (filtre de voisinage) comme si l'image se répétait à gauche et à droite."""
    w, h = img.size
    big = Image.new(img.mode, (3 * w, h))
    for k in range(3):
        big.paste(img, (k * w, 0))
    return fn(big).crop((w, 0, 2 * w, h))


def wrap_y(img, fn):
    w, h = img.size
    big = Image.new(img.mode, (w, 3 * h))
    for k in range(3):
        big.paste(img, (0, k * h))
    return fn(big).crop((0, h, w, 2 * h))


def steps_alpha(img, levels=8):
    """Alpha doux en paliers (pixel art) : levels niveaux de 0 à 255."""
    a = img.getchannel("A").point(lambda v: min(255, round(v * levels / 255.0) * 255 // levels))
    out = img.copy()
    out.putalpha(a)
    return out


def recolor(img, color, keep=0.35):
    """Recoloration d'une image (variation de teinte d'une matière livrée) : la luminance garde le
    dessin, la teinte vient de color ; keep garde une part de la couleur d'origine."""
    gray = img.convert("L")
    lo, hi = gray.getextrema()
    tones = ramp(color, 7, spread=0.6)
    span = max(1, hi - lo)
    lut = []
    for c in range(3):
        for v in range(256):
            t = max(0.0, min(1.0, (v - lo) / float(span)))
            pos = t * (len(tones) - 1)
            i = min(len(tones) - 2, int(pos))
            f = pos - i
            lut.append(round(tones[i][c] + (tones[i + 1][c] - tones[i][c]) * f))
    tinted = Image.merge("RGB", [gray.point(lut[c * 256:(c + 1) * 256]) for c in range(3)])
    out = Image.blend(tinted, img.convert("RGB"), keep).convert("RGBA")
    out.putalpha(img.getchannel("A"))
    return out


def rotate_points(points, cx, cy, angle):
    ca, sa = math.cos(angle), math.sin(angle)
    return [(cx + (x - cx) * ca - (y - cy) * sa, cy + (x - cx) * sa + (y - cy) * ca) for x, y in points]
