#!/usr/bin/env python3
"""Intérieurs (lot E3) : remplaçants en pixel art des images du lot I (docs/REFONTE.md, section
8.1 ; docs/INTERIEURS.md), leurs entrées du manifeste et les scènes des meubles.

Les images vivent dans assets/hd2d/interior/ :
- sols floor_<matière> (384 × 384, 4 × 4 m, tile : sans raccord, vue de dessus) ;
- murs wall_<matière> (384 × 288, 4 × 3 m, tile_h : raccord à gauche et à droite, vue de face,
  corniche en haut, plinthe en bas) ;
- dessus de mur coupé wallcut_<matière> (384 × 24, 4 × 0,25 m, tile_h) ;
- portes door_*, fenêtres window_*, éléments de mur wallitem_* (panel, posés contre un mur par
  InteriorRoom) ;
- meubles props/<nom> (panel, vue de face légèrement plongeante, scène InteriorPanel de
  src/world/props/<nom>.tscn) et tapis props/rug_* (decal, scène GroundDecal).
Les vraies images (cahier n° 3) remplaceront les fichiers du même nom, sans toucher au code.
Lumière de gauche, comme les autres remplaçants ; texte jamais lisible (écriteaux, plannings).

Usage :

    python3 tools/hd2d_interior.py manifest   # ajoute au manifeste les entrées absentes (lot I)
    python3 tools/hd2d_assets.py gen --lot I  # dessine les remplaçants (recettes ci-dessous)
    python3 tools/hd2d_interior.py scenes     # écrit les scènes des meubles (src/world/props/)
    python3 tools/hd2d_assets.py check --lot I

Le résultat est déterministe (graine tirée du nom de chaque image).
"""

import json
import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hd2d_art import (  # noqa: E402
    Canvas, WrapCanvas, darker, fractal, mix, noise, paste_wrap, posterize, ramp, rgba, threshold)
from hd2d_props import boards, glow, post  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "hd2d_manifest.json")
PROPS_DIR = os.path.join(ROOT, "src", "world", "props")
PPM = 96
LOT = "I"

WOOD = "wood"
DARK = "wood_dark"
HONEY = "#B08458"
WALNUT = "#6B4A36"
PLASTER = "#E6DAC2"
IRON = "iron"
BRASS = "brass"
PAPER = "#EDE3C9"
INK = "#6C625A"

# --- Liste des images (chemin sous assets/hd2d/interior/, taille, genre) -------------------------
# Meubles : profondeur de l'emprise au sol (m, vers le nord depuis l'image), lueur des pixels
# couleur cristal. Les panneaux debout touchent le bord bas de leur image (ancre au sol).

SURFACES = [
    ("floor_planks_worn", (384, 384), "tile"),
    ("floor_planks_dark", (384, 384), "tile"),
    ("floor_tiles_bath", (384, 384), "tile"),
    ("floor_flagstone_cellar", (384, 384), "tile"),
    ("floor_kitchen_tiles", (384, 384), "tile"),
    ("wall_plaster_worn", (384, 288), "tile_h"),
    ("wall_wainscot", (384, 288), "tile_h"),
    ("wall_wallpaper_faded", (384, 288), "tile_h"),
    ("wall_kitchen_tiles", (384, 288), "tile_h"),
    ("wall_cellar_stone", (384, 288), "tile_h"),
    ("wallcut_wood", (384, 24), "tile_h"),
    ("wallcut_stone", (384, 24), "tile_h"),
]

WALL_PANELS = [
    ("door_wood", (106, 211)),
    ("door_frame_wood", (126, 221)),
    ("door_cellar", (126, 221)),
    ("window_cross", (96, 120)),
    ("window_large", (230, 154)),
    ("wallitem_chores", (58, 77)),
    ("wallitem_notice", (48, 34)),
    ("wallitem_menu", (67, 86)),
    ("wallitem_clock", (38, 48)),
    ("wallitem_calendar", (34, 48)),
    ("wallitem_plaque", (48, 14)),
    ("wallitem_mirror_large", (115, 134)),
    ("wallitem_height_marks", (29, 134)),
    ("wallitem_lamp", (29, 48)),
]

# nom, taille (px), profondeur de l'emprise (m), lueur
FURNITURE = [
    ("dresser_glass", (154, 202), 0.55, 0.0),
    ("sink_counter", (134, 96), 0.6, 0.0),
    ("table_long", (250, 91), 0.9, 0.0),
    ("bench_long", (230, 48), 0.4, 0.0),
    ("crystal_stove", (125, 106), 0.7, 1.4),
    ("kitchen_counter", (192, 96), 0.6, 0.0),
    ("kitchen_table", (154, 86), 0.8, 0.0),
    ("bookshelf", (134, 192), 0.4, 0.0),
    ("window_seat", (154, 58), 0.6, 0.0),
    ("reading_table", (154, 82), 0.8, 0.0),
    ("chair", (48, 91), 0.7, 0.0),
    ("archive_shelf", (154, 202), 0.5, 0.0),
    ("desk_cluttered", (134, 106), 0.8, 0.0),
    ("sofa_beige", (192, 86), 0.9, 0.0),
    ("paper_stacks", (115, 86), 0.8, 0.0),
    ("bed_infirmary", (96, 125), 2.0, 0.0),
    ("nightstand_vase", (48, 86), 0.4, 0.0),
    ("medicine_cabinet", (86, 173), 0.4, 0.0),
    ("desk_small", (115, 86), 0.6, 0.0),
    ("toy_shelf", (115, 134), 0.4, 0.0),
    ("plush_pile", (77, 48), 0.6, 0.0),
    ("board_game_table", (96, 48), 0.8, 0.0),
    ("bathtub", (154, 77), 0.9, 0.0),
    ("washstand", (77, 96), 0.5, 0.0),
    ("water_basin", (86, 96), 0.5, 0.0),
    ("cupboard_supplies", (96, 192), 0.5, 0.0),
    ("toilet_stall", (115, 202), 1.2, 0.0),
    ("shoe_bench", (154, 48), 0.4, 0.0),
]

RUGS = [
    ("rug_play", (240, 173)),
    ("rug_doormat", (115, 67)),
]


def entries():
    """Entrées du manifeste du lot I, dans l'ordre."""
    out = []
    for name, size, kind in SURFACES:
        out.append({"path": "assets/hd2d/interior/%s.png" % name, "size": list(size), "kind": kind, "prio": 1,
                    "lot": LOT})
    for name, size in WALL_PANELS:
        out.append({"path": "assets/hd2d/interior/%s.png" % name, "size": list(size), "kind": "panel", "prio": 1,
                    "lot": LOT})
    for name, size, _depth, _glow in FURNITURE:
        out.append({"path": "assets/hd2d/interior/props/%s.png" % name, "size": list(size), "kind": "panel",
                    "prio": 2, "lot": LOT})
    for name, size in RUGS:
        out.append({"path": "assets/hd2d/interior/props/%s.png" % name, "size": list(size), "kind": "decal",
                    "prio": 2, "lot": LOT})
    return out


# --- Outils de dessin -----------------------------------------------------------------------------


def _grain_rows(img, rnd, x0, y0, w, h, tones, along_x=True):
    """Fibres du bois : bruit étiré dans le sens des planches, posterisé en trois tons."""
    cells = (max(2, w // 40), max(1, h // 6)) if along_x else (max(1, w // 6), max(2, h // 40))
    grain = noise((w, h), cells, rnd)
    img.paste(posterize(grain, tones, dither=36), (x0, y0))


def _wrap_line(d, w, x0, y, x1, color):
    """Trait horizontal de x0 à x1 qui reprend à gauche au-delà de w (raccord)."""
    for dx in (-w, 0, w):
        d.line((x0 + dx, y, x1 + dx, y), fill=rgba(color))


def _plank_floor(size, rnd, base, board_h, wear, worn_color, joints=(80, 200)):
    """Parquet vu de dessus : lames est-ouest de board_h px, joints décalés, clous, usure."""
    w, h = size
    img = Image.new("RGBA", size)
    d = ImageDraw.Draw(img)
    rows = h // board_h
    nail = ramp(IRON, 4)
    for r in range(rows):
        y0 = r * board_h
        # Joints de la lame (positions sur un tour de w px : la lame se raccorde à elle-même).
        cuts = []
        x = rnd.randrange(w)
        while not cuts or (x - cuts[0]) % w > joints[0] or len(cuts) < 2:
            cuts.append(x % w)
            x += rnd.randint(*joints)
            if len(cuts) > 6:
                break
        cuts = sorted(set(cuts))
        segments = list(zip(cuts, cuts[1:] + [cuts[0] + w]))
        for a, b in segments:
            tone = mix(base, rnd.choice(["#8E6E52", "#C09A70", base, base, "#A58060"]), rnd.uniform(0.1, 0.4))
            tones = ramp(tone, 5, spread=0.32)
            seg = Image.new("RGBA", (b - a, board_h))
            _grain_rows(seg, rnd, 0, 0, b - a, board_h, tones[1:4])
            sd = ImageDraw.Draw(seg)
            for _ in range(2):
                gy = rnd.randrange(2, board_h - 1)
                gx = rnd.randrange(max(1, b - a))
                sd.line((gx, gy, min(b - a, gx + rnd.randint(20, 70)), gy), fill=rgba(tones[1]))
            paste_wrap(img, seg, a, y0)
            # Bout de lame : joint sombre, clous.
            for dx in (-w, 0, w):
                d.line((a + dx, y0, a + dx, y0 + board_h - 1), fill=rgba(darker(tones[0], 0.7)))
            for nx in ((a + 3) % w, (b - 4) % w):
                for ny in (y0 + 3, y0 + board_h - 4):
                    d.rectangle((nx, ny, nx + 1, ny + 1), fill=rgba(nail[0]))
                    d.point((nx, ny), fill=rgba(nail[2]))
        # Rainure entre deux rangs et reflet sur le bord haut de la lame.
        _wrap_line(d, w, 0, y0, w - 1, darker(base, 0.42))
        _wrap_line(d, w, 0, y0 + 1, w - 1, mix(base, "#F0D8B0", 0.35))
    # Usure : passages plus clairs et ternis (grandes taches sans raccord), éraflures.
    if wear > 0:
        mask = fractal(size, (3, 3), rnd, 3).point(lambda v: max(0, min(255, int((v - 110) * wear * 2.4))))
        worn = Image.new("RGBA", size, rgba(worn_color))
        img.paste(Image.blend(img, worn, 0.35), (0, 0), mask)
        for _ in range(int(40 * wear)):
            sx, sy = rnd.randrange(w), rnd.randrange(h)
            n = rnd.randint(6, 18)
            for k in range(n):
                d.point(((sx + k) % w, (sy + k // 5) % h), fill=rgba(mix(worn_color, "#FFFFFF", 0.2)))
    return img


def _cornice(c, w, top, height, base):
    """Corniche de bois en haut du mur : moulure claire, ombre dessous."""
    tones = ramp(base, 5, spread=0.42)
    c.rect(0, top, w, top + height, tones[2])
    c.rect(0, top, w, top + 2, tones[4])
    c.rect(0, top + height // 2, w, top + height // 2 + 1, tones[3])
    c.rect(0, top + height - 2, w, top + height, tones[0])
    c.rect(0, top + height, w, top + height + 2, rgba(darker(PLASTER, 0.75))[:3])


def _plinth(c, w, h, height, base):
    """Plinthe de bois au pied du mur : arête claire en haut, ombre au sol."""
    tones = ramp(base, 5, spread=0.42)
    top = h - height
    c.rect(0, top - 2, w, top, rgba(darker(PLASTER, 0.78))[:3])
    c.rect(0, top, w, h, tones[2])
    c.rect(0, top, w, top + 2, tones[4])
    c.rect(0, top + 5, w, top + 6, tones[3])
    c.rect(0, h - 3, w, h, tones[0])


def _plaster(size, rnd, base, stains=0.5, cracks=4):
    """Plâtre sans raccord : taches douces, salissure vers le bas, fissures."""
    w, h = size
    tones = ramp(base, 5, spread=0.22)
    img = posterize(fractal(size, (4, 3), rnd, 3), tones[1:4], dither=30)
    if stains > 0:
        mask = fractal(size, (3, 2), rnd, 2).point(lambda v: max(0, min(255, int((v - 140) * stains * 3))))
        img.paste(Image.blend(img, Image.new("RGBA", size, rgba("#A89070")), 0.3), (0, 0), mask)
    grime = Image.linear_gradient("L").resize(size).point(lambda v: max(0, int((v - 150) * 0.9)))
    img.paste(Image.blend(img, Image.new("RGBA", size, rgba("#7E6A58")), 0.35), (0, 0), grime)
    c = WrapCanvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(c.img)
    for _ in range(cracks):
        x, y = rnd.uniform(0, w), rnd.uniform(h * 0.15, h * 0.8)
        pts = [(x, y)]
        for _k in range(rnd.randint(4, 8)):
            x += rnd.uniform(-6, 6)
            y += rnd.uniform(3, 9)
            pts.append((x, y))
        c.line(pts, darker(base, 0.6))
        c.line([(px + 1, py) for px, py in pts], mix(base, "#FFFFFF", 0.4))
    return c.img


# --- Sols ---------------------------------------------------------------------------------------


def floor_planks_worn(size, rnd):
    return _plank_floor(size, rnd, HONEY, 16, 1.0, "#D2B288")


def floor_planks_dark(size, rnd):
    img = _plank_floor(size, rnd, WALNUT, 12, 0.45, "#8E6A50", joints=(110, 250))
    return img


def floor_tiles_bath(size, rnd):
    w, h = size
    t = 32
    img = Image.new("RGBA", size, rgba("#A39D90"))
    d = ImageDraw.Draw(img)
    cream = ramp("#E9E5D9", 5, spread=0.18)
    blue = ramp("#7F9CB8", 5, spread=0.3)
    for ty in range(h // t):
        for tx in range(w // t):
            accent = (tx % 4 == 0 and ty % 4 == 0)
            tones = blue if accent else cream
            base = tones[rnd.choice([2, 2, 3, 1])] if not accent else tones[2]
            x0, y0 = tx * t + 1, ty * t + 1
            d.rectangle((x0, y0, x0 + t - 3, y0 + t - 3), fill=rgba(base))
            d.line((x0, y0, x0 + t - 3, y0), fill=rgba(tones[4]))
            d.line((x0, y0, x0, y0 + t - 3), fill=rgba(tones[4]))
            d.line((x0, y0 + t - 3, x0 + t - 3, y0 + t - 3), fill=rgba(tones[0]))
            d.line((x0 + t - 3, y0, x0 + t - 3, y0 + t - 3), fill=rgba(tones[0]))
            if accent:
                d.rectangle((x0 + 9, y0 + 9, x0 + t - 12, y0 + t - 12), fill=rgba(cream[3]))
            elif rnd.random() < 0.12:
                d.line((x0 + 4, y0 + rnd.randint(6, 24), x0 + rnd.randint(10, 26), y0 + rnd.randint(4, 26)),
                       fill=rgba(cream[0]))
    # Joints ternis par l'eau, quelques taches.
    mask = fractal(size, (4, 4), rnd, 2).point(lambda v: max(0, int((v - 150) * 1.6)))
    img.paste(Image.blend(img, Image.new("RGBA", size, rgba("#8C8A80")), 0.25), (0, 0), mask)
    return img


def floor_flagstone_cellar(size, rnd):
    w, h = size
    img = posterize(fractal(size, (8, 8), rnd, 2), ramp("#4A443E", 4)[0:3], dither=40)
    y = 0
    rows = [64, 64, 64, 64, 64, 64]
    for rh in rows:
        widths = []
        while sum(widths) < w:
            widths.append(rnd.randint(52, 96))
        widths[-1] -= sum(widths) - w
        if widths[-1] < 40:
            widths[-2] += widths.pop()
        x = rnd.randrange(w)
        for sw in widths:
            base = mix("#8A8076", rnd.choice(["#6E6A66", "#9A8C78", "#7A7468", "#8E8478"]), rnd.uniform(0.2, 0.6))
            tones = ramp(base, 5, spread=0.38)
            c = Canvas(sw, rh, rnd)
            c.rect(2, 2, sw - 2, rh - 2, tones[2])
            pat = posterize(noise((sw - 6, rh - 6), (3, 3), rnd), tones[1:4], dither=50)
            c.img.paste(pat, (3, 3))
            c.rect(2, 2, sw - 2, 4, tones[4])
            c.rect(2, 2, 4, rh - 2, tones[3])
            c.rect(2, rh - 4, sw - 2, rh - 2, tones[0])
            c.rect(sw - 4, 2, sw - 2, rh - 2, tones[0])
            for _ in range(rnd.randint(0, 2)):
                cx, cy = rnd.uniform(8, sw - 8), rnd.uniform(8, rh - 8)
                c.line([(cx, cy), (cx + rnd.uniform(-10, 10), cy + rnd.uniform(4, 14))], tones[0])
            paste_wrap(img, c.img, x % w, y)
            x += sw
        y += rh
    # Humidité : taches sombres et un peu de mousse dans les joints.
    damp = fractal(size, (3, 3), rnd, 2).point(lambda v: max(0, int((v - 140) * 1.8)))
    img.paste(Image.blend(img, Image.new("RGBA", size, rgba("#2E2C2A")), 0.4), (0, 0), damp)
    moss = threshold(fractal(size, (12, 12), rnd, 2), 215)
    img.paste(Image.new("RGBA", size, rgba("#4C5A3C")), (0, 0), moss)
    return img


def floor_kitchen_tiles(size, rnd):
    w, h = size
    t = 48
    img = Image.new("RGBA", size, rgba("#6A5446"))
    d = ImageDraw.Draw(img)
    terra = ramp("#B0614A", 5, spread=0.3)
    cream = ramp("#D9C7A2", 5, spread=0.22)
    for ty in range(h // t):
        for tx in range(w // t):
            tones = terra if (tx + ty) % 2 == 0 else cream
            x0, y0 = tx * t + 2, ty * t + 2
            tile = posterize(noise((t - 4, t - 4), (3, 3), rnd), tones[1:4], dither=40)
            img.paste(tile, (x0, y0))
            d.line((x0, y0, x0 + t - 5, y0), fill=rgba(tones[4]))
            d.line((x0, y0, x0, y0 + t - 5), fill=rgba(tones[4]))
            d.line((x0, y0 + t - 5, x0 + t - 5, y0 + t - 5), fill=rgba(tones[0]))
            d.line((x0 + t - 5, y0, x0 + t - 5, y0 + t - 5), fill=rgba(tones[0]))
            if rnd.random() < 0.15:
                cx, cy = x0 + rnd.randint(0, 1) * (t - 8), y0 + rnd.randint(0, 1) * (t - 8)
                d.rectangle((cx, cy, cx + 3, cy + 3), fill=rgba("#6A5446"))
    wear = fractal(size, (3, 3), rnd, 3).point(lambda v: max(0, int((v - 120) * 1.4)))
    img.paste(Image.blend(img, Image.new("RGBA", size, rgba("#E8D8B8")), 0.25), (0, 0), wear)
    return img


# --- Murs (corniche en haut, plinthe en bas) -----------------------------------------------------


def wall_plaster_worn(size, rnd):
    w, h = size
    img = _plaster(size, rnd, PLASTER, stains=0.35, cracks=5)
    c = WrapCanvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(c.img)
    _cornice(c, w, 0, 14, DARK)
    _plinth(c, w, h, 18, DARK)
    return c.img


def wall_wainscot(size, rnd):
    w, h = size
    img = _plaster(size, rnd, "#DCD6BC", stains=0.35, cracks=2)
    c = WrapCanvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(c.img)
    rail = h - 96
    wood = ramp(HONEY, 5, spread=0.4)
    # Lambris : panneaux à cadre de 64 px (raccord : 6 par largeur).
    c.rect(0, rail, w, h, wood[1])
    for k in range(w // 64):
        x0 = k * 64
        c.rect(x0 + 6, rail + 10, x0 + 58, h - 22, wood[2])
        panel = posterize(noise((48, 64 - 12), (2, 6), rnd), wood[2:5], dither=30)
        c.img.paste(panel, (x0 + 8, rail + 12), None)
        c.rect(x0 + 6, rail + 10, x0 + 58, rail + 12, wood[0])
        c.rect(x0 + 6, rail + 10, x0 + 8, h - 22, wood[0])
        c.rect(x0 + 6, h - 24, x0 + 58, h - 22, wood[4])
        c.rect(x0 + 56, rail + 10, x0 + 58, h - 22, wood[4])
        c.rect(x0, rail, x0 + 2, h, wood[0])
    # Cimaise (moulure à hauteur d'appui) et ombre portée sur le plâtre.
    c.rect(0, rail - 6, w, rail, wood[3])
    c.rect(0, rail - 6, w, rail - 4, wood[4])
    c.rect(0, rail - 1, w, rail + 1, wood[0])
    c.rect(0, rail - 9, w, rail - 6, mix("#DCD6BC", "#7E7058", 0.35))
    _cornice(c, w, 0, 14, DARK)
    _plinth(c, w, h, 16, DARK)
    return c.img


def wall_wallpaper_faded(size, rnd):
    w, h = size
    paper = ramp("#C9BFA0", 5, spread=0.2)
    rose = ramp("#B98A84", 5, spread=0.3)
    leaf = ramp("#8E9A78", 5, spread=0.3)
    img = Image.new("RGBA", size, rgba(paper[2]))
    c = WrapCanvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(c.img)
    # Rayures pâles de 48 px (8 par largeur) et semis de petites fleurs.
    for k in range(w // 48):
        x0 = k * 48
        c.rect(x0 + 20, 0, x0 + 28, h, paper[3])
        c.rect(x0 + 19, 0, x0 + 20, h, paper[1])
        c.rect(x0 + 28, 0, x0 + 29, h, paper[1])
        for j, y in enumerate(range(10, h, 36)):
            fx = x0 + (8 if j % 2 else 38)
            c.rect(fx - 1, y + 3, fx + 1, y + 9, leaf[2])
            c.rect(fx + 1, y + 6, fx + 4, y + 8, leaf[3])
            for ox, oy in ((0, -2), (-2, 0), (2, 0), (0, 2)):
                c.rect(fx + ox - 1, y + oy - 1, fx + ox + 1, y + oy + 1, rose[3])
            c.rect(fx, y, fx + 1, y + 1, rose[1])
    # Fané par le soleil : grandes taches plus claires, auréoles, salissure en bas.
    fade = fractal(size, (3, 2), rnd, 2).point(lambda v: max(0, int((v - 100) * 1.5)))
    c.img.paste(Image.blend(c.img, Image.new("RGBA", size, rgba("#E4DCC6")), 0.45), (0, 0), fade)
    grime = Image.linear_gradient("L").resize(size).point(lambda v: max(0, int((v - 170) * 1.0)))
    c.img.paste(Image.blend(c.img, Image.new("RGBA", size, rgba("#7E6A58")), 0.3), (0, 0), grime)
    c.draw = ImageDraw.Draw(c.img)
    for _ in range(2):
        sx = rnd.uniform(0, w)
        c.line([(sx, 30), (sx + 2, 70), (sx + 1, 120)], mix(paper[2], "#9A8A68", 0.4))
    _cornice(c, w, 0, 14, WALNUT)
    _plinth(c, w, h, 16, WALNUT)
    return c.img


def wall_kitchen_tiles(size, rnd):
    w, h = size
    img = _plaster(size, rnd, "#E2D4B4", stains=0.4, cracks=2)
    c = WrapCanvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(c.img)
    top = h - 134
    t = 24
    white = ramp("#E6E4DA", 5, spread=0.18)
    blue = ramp("#6F8FB0", 5, spread=0.3)
    c.rect(0, top, w, h, "#9C988C")
    for ty in range((h - top) // t + 1):
        for tx in range(w // t):
            x0, y0 = tx * t + 1, top + ty * t + 1
            if y0 >= h - 18:
                continue
            tones = blue if ty == 0 else white
            c.rect(x0, y0, x0 + t - 2, min(y0 + t - 2, h - 18), tones[rnd.choice([2, 2, 3])])
            c.rect(x0, y0, x0 + t - 2, y0 + 1, tones[4])
            c.rect(x0, y0, x0 + 1, min(y0 + t - 2, h - 18), tones[4])
    # Plinthe de carreaux sombres, corniche de bois.
    dark = ramp("#5E6A74", 5, spread=0.3)
    c.rect(0, h - 18, w, h, dark[2])
    for tx in range(w // t):
        c.rect(tx * t, h - 18, tx * t + 1, h, dark[0])
    c.rect(0, h - 18, w, h - 16, dark[4])
    c.rect(0, h - 3, w, h, dark[0])
    _cornice(c, w, 0, 14, DARK)
    return c.img


def wall_cellar_stone(size, rnd):
    w, h = size
    img = Image.new("RGBA", size, rgba("#3A3430"))
    c = WrapCanvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(c.img)
    courses = [26, 40, 38, 42, 36, 40, 34]
    y = 0
    for i, ch in enumerate(courses):
        x = rnd.uniform(0, 40)
        while x < w:
            sw = rnd.uniform(40, 86)
            if i == 0:
                base = "#6E6258"
            elif i == len(courses) - 1:
                base = "#4E4640"
            else:
                base = mix("#7A7066", rnd.choice(["#6A645E", "#8A7C6C", "#5E5852"]), rnd.uniform(0.2, 0.6))
            tones = ramp(base, 5, spread=0.38)
            c.rect(x + 2, y + 2, x + sw - 2, y + ch - 2, tones[2])
            c.rect(x + 2, y + 2, x + sw - 2, y + 4, tones[4])
            c.rect(x + 2, y + 2, x + 4, y + ch - 2, tones[3])
            c.rect(x + 2, y + ch - 4, x + sw - 2, y + ch - 2, tones[0])
            for _ in range(3):
                px, py = rnd.uniform(x + 6, x + sw - 6), rnd.uniform(y + 6, y + ch - 6)
                c.rect(px, py, px + 2, py + 1, tones[rnd.choice([1, 3])])
            x += sw
        y += ch
    damp = Image.linear_gradient("L").resize(size).point(lambda v: max(0, int((v - 120) * 0.9)))
    c.img.paste(Image.blend(c.img, Image.new("RGBA", size, rgba("#1E1C1A")), 0.45), (0, 0), damp)
    return c.img


# --- Dessus de mur coupé (vu d'en haut, 0,25 m) ----------------------------------------------------


def wallcut_wood(size, rnd):
    w, h = size
    c = WrapCanvas(w, h, rnd)
    plaster = ramp(PLASTER, 4, spread=0.2)
    wood = ramp(DARK, 5, spread=0.4)
    c.rect(0, 0, w, h, wood[2])
    c.img.paste(posterize(noise((w, h - 8), (24, 1), rnd), wood[1:4], dither=30), (0, 4))
    c.draw = ImageDraw.Draw(c.img)
    x = 0
    while x < w:
        c.rect(x, 4, x + 1, h - 4, wood[0])
        x += rnd.choice([64, 96, 128])
    c.rect(0, 0, w, 3, plaster[2])
    c.rect(0, 0, w, 1, plaster[3])
    c.rect(0, 3, w, 4, wood[0])
    c.rect(0, h - 3, w, h, plaster[1])
    c.rect(0, h - 4, w, h - 3, wood[0])
    return c.img


def wallcut_stone(size, rnd):
    w, h = size
    c = WrapCanvas(w, h, rnd)
    c.rect(0, 0, w, h, "#3A3430")
    x = 0
    while x < w:
        sw = rnd.choice([32, 48, 48, 64])
        sw = min(sw, w - x)
        tones = ramp(mix("#7A7066", rnd.choice(["#6A645E", "#8A7C6C"]), 0.4), 4, spread=0.35)
        c.rect(x + 1, 1, x + sw - 1, h - 1, tones[2])
        c.rect(x + 1, 1, x + sw - 1, 3, tones[3])
        c.rect(x + 1, h - 3, x + sw - 1, h - 1, tones[0])
        x += sw
    return c.img


# --- Portes, fenêtres, éléments de mur --------------------------------------------------------------


def _frame(c, w, h, jamb, lintel, base, sill=0):
    """Chambranle : montants et linteau moulurés."""
    tones = ramp(base, 5, spread=0.42)
    c.rect(0, 0, w, lintel, tones[2])
    c.rect(0, 0, w, 2, tones[4])
    c.rect(0, lintel - 2, w, lintel, tones[0])
    for x0 in (0, w - jamb):
        c.rect(x0, 0, x0 + jamb, h - sill, tones[2])
        c.rect(x0, lintel, x0 + 2, h - sill, tones[4] if x0 == 0 else tones[3])
        c.rect(x0 + jamb - 2, lintel, x0 + jamb, h - sill, tones[1])
    return tones


def door_wood(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _frame(c, w, h, 7, 9, DARK)
    boards(c, 7, 9, w - 7, h - 5, WOOD, vertical=True, width=12)
    wood = ramp(WOOD, 5, spread=0.4)
    for y in (h * 0.2, h * 0.72):
        c.rect(9, y, w - 9, y + 9, wood[1])
        c.rect(9, y, w - 9, y + 2, wood[3])
    c.line([(12, h * 0.72 + 9), (w - 12, h * 0.2)], wood[1], 6)
    iron = ramp(IRON, 4)
    for y in (h * 0.2, h * 0.72):
        c.rect(9, y + 2, 34, y + 7, iron[1])
        c.rect(9, y + 2, 34, y + 3, iron[3])
    c.rect(w - 24, h * 0.48, w - 16, h * 0.48 + 10, iron[0])
    c.ellipse(w - 20, h * 0.48 + 14, 4, 3, ramp(BRASS, 4)[2])
    c.rect(0, h - 5, w, h, ramp("stone_dark", 4)[2])
    c.rect(0, h - 5, w, h - 4, ramp("stone_dark", 4)[3])
    del tones
    return c.finish(darker(DARK, 0.5))


def door_frame_wood(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _frame(c, w, h, 10, 10, DARK)
    # Seuil de bois usé entre les deux montants.
    c.rect(10, h - 4, w - 10, h, ramp(HONEY, 4)[1])
    c.rect(10, h - 4, w - 10, h - 3, ramp(HONEY, 4)[3])
    return c.finish(darker(DARK, 0.5))


def door_cellar(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("#7A7066", 5, spread=0.4)
    # Arc de pierres autour d'une descente : marches qui s'enfoncent dans le noir.
    arch_top = 26
    c.rect(0, arch_top, w, h, stone[1])
    c.ellipse(w / 2.0, arch_top + 6, w / 2.0, arch_top + 6, stone[1])
    inner_w = w - 28
    steps = 9
    for k in range(steps):
        t = k / float(steps - 1)
        y1 = h - k * (h - arch_top - 20) / steps
        y0 = y1 - (h - arch_top - 20) / steps
        shade = mix("#8A7C6C", "#0C0A0A", min(1.0, t * 1.2))
        inset = 14 + k * 3
        c.rect(inset, y0, w - inset, y1, shade)
        c.rect(inset, y0, w - inset, y0 + 2, mix(shade, "#FFFFFF", 0.18 * (1.0 - t)))
    c.ellipse(w / 2.0, arch_top + 14, inner_w / 2.0, 22, "#0C0A0A")
    c.rect(14 + steps * 3, arch_top + 14, w - 14 - steps * 3, h * 0.45, "#0C0A0A")
    for side in (0, 1):
        x0 = 0 if side == 0 else w - 14
        y = arch_top + 8
        while y < h:
            bh = rnd.randint(16, 26)
            c.rect(x0 + 1, y + 1, x0 + 13, min(h, y + bh) - 1, stone[rnd.choice([2, 3])])
            c.rect(x0 + 1, y + 1, x0 + 13, y + 3, stone[4])
            y += bh
    for k in range(7):
        a = math.pi + math.pi * (k + 0.5) / 7
        cx, cy = w / 2.0 + math.cos(a) * (w / 2.0 - 7), arch_top + 14 + math.sin(a) * 20
        c.blob(cx, cy, 8, 7, stone[1:5])
    c.rect(0, h - 4, w, h, stone[0])
    return c.finish(darker("#5E5852", 0.45))


def _window(c, x0, y0, x1, y1, cols, rows, frame=DARK):
    """Châssis à croisillons, vitres couleur cristal (s'allument avec la lueur des fenêtres)."""
    wood = ramp(frame, 5, spread=0.4)
    glass = ramp("crystal", 5, spread=0.42)
    c.rect(x0, y0, x1, y1, wood[2])
    c.rect(x0, y0, x1, y0 + 2, wood[4])
    pw = (x1 - x0 - 6) / float(cols)
    ph = (y1 - y0 - 6) / float(rows)
    for i in range(cols):
        for j in range(rows):
            gx, gy = x0 + 3 + i * pw + 2, y0 + 3 + j * ph + 2
            c.rect(gx, gy, gx + pw - 4, gy + ph - 4, glass[2])
            c.rect(gx, gy, gx + pw - 4, gy + (ph - 4) * 0.45, glass[3])
            c.rect(gx + 1, gy + 1, gx + (pw - 4) * 0.35, gy + 3, glass[4])
            c.line([(gx + pw * 0.55, gy + ph * 0.25), (gx + pw * 0.3, gy + ph * 0.6)], glass[4])


def window_cross(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _window(c, 4, 4, w - 4, h - 10, 2, 2)
    wood = ramp(DARK, 5, spread=0.4)
    c.rect(0, 0, w, 6, wood[2])
    c.rect(0, 0, w, 2, wood[4])
    c.rect(0, h - 10, w, h, ramp(HONEY, 5)[2])
    c.rect(0, h - 10, w, h - 8, ramp(HONEY, 5)[4])
    c.rect(0, h - 2, w, h, ramp(HONEY, 5)[0])
    return c.finish(darker(DARK, 0.5))


def window_large(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(DARK, 5, spread=0.4)
    c.rect(0, 0, w, 8, wood[2])
    c.rect(0, 0, w, 2, wood[4])
    _window(c, 4, 8, w - 4, 44, 4, 1)
    _window(c, 4, 44, w * 0.5 - 2, h - 12, 2, 2)
    _window(c, w * 0.5 + 2, 44, w - 4, h - 12, 2, 2)
    c.rect(w * 0.5 - 2, 44, w * 0.5 + 2, h - 12, wood[1])
    c.rect(0, h - 12, w, h, ramp(HONEY, 5)[2])
    c.rect(0, h - 12, w, h - 10, ramp(HONEY, 5)[4])
    c.rect(0, h - 2, w, h, ramp(HONEY, 5)[0])
    return c.finish(darker(DARK, 0.5))


def _scribble(c, x0, y0, x1, lines, step, color, rnd, gap=0.7):
    """Lignes d'écriture illisibles."""
    for k in range(lines):
        y = y0 + k * step
        x = x0
        while x < x1:
            n = rnd.randint(3, 9)
            c.rect(x, y, min(x1, x + n), y + 1, color)
            x += n + rnd.randint(2, 4)
            if rnd.random() > gap:
                break


def _paper(c, x0, y0, x1, y1, base=PAPER):
    tones = ramp(base, 4, spread=0.2)
    c.rect(x0, y0, x1, y1, tones[2])
    c.rect(x0, y0, x1, y0 + 1, tones[3])
    c.rect(x1 - 1, y0, x1, y1, tones[0])
    c.rect(x0, y1 - 1, x1, y1, tones[1])


def wallitem_chores(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _paper(c, 0, 0, w, h)
    for k in range(6):
        y = 10 + k * 10
        c.rect(3, y, w - 3, y + 1, "#B8AC92")
    for x in (16, 30, 44):
        c.rect(x, 8, x + 1, h - 6, "#B8AC92")
    _scribble(c, 4, 3, w - 4, 1, 0, "#7A3A34", rnd)
    for k in range(6):
        _scribble(c, 4, 13 + k * 10, 14, 1, 0, INK, rnd)
        for x in (19, 33, 47):
            if rnd.random() < 0.6:
                col = rnd.choice(["#4E7A9A", "#B5443A", "#5A8A50"])
                c.rect(x, 14 + k * 10, x + 5, 16 + k * 10, col)
    c.ellipse(w / 2.0, 2, 2, 2, "#B5443A")
    return c.finish(darker(PAPER, 0.5))


def wallitem_notice(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _paper(c, 0, 0, w, h, "#F0E6CC")
    for k in range(3):
        y = 7 + k * 8
        x = 5
        while x < w - 5:
            n = rnd.randint(4, 7)
            c.rect(x, y, x + n, y + 3, "#3E3632" if k < 2 else "#8A3A32")
            x += n + 2
    c.ellipse(4, 3, 2, 2, "#B5443A")
    c.ellipse(w - 5, 3, 2, 2, "#B5443A")
    return c.finish(darker(PAPER, 0.5))


def wallitem_menu(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(DARK, 5, spread=0.4)
    c.rect(0, 0, w, h, wood[2])
    c.rect(0, 0, w, 2, wood[4])
    slate = ramp("#3E4A48", 4, spread=0.3)
    c.rect(4, 4, w - 4, h - 4, slate[1])
    _scribble(c, 9, 9, w - 9, 1, 0, "#E8E4D6", rnd, gap=1.0)
    for k in range(6):
        _scribble(c, 8, 20 + k * 7, w - 10, 1, 0, "#C8C4B6", rnd)
    # La ligne « dessert du jour », à la craie rose.
    c.rect(7, h - 16, w - 7, h - 15, "#E89AA8")
    _scribble(c, 9, h - 12, w - 12, 1, 0, "#F2B4C0", rnd, gap=1.0)
    return c.finish(darker(DARK, 0.5))


def wallitem_clock(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WALNUT, 5, spread=0.4)
    c.rect(w * 0.18, h * 0.3, w * 0.82, h, wood[2])
    c.rect(w * 0.18, h * 0.3, w * 0.24, h, wood[3])
    c.blob(w / 2.0, h * 0.32, w * 0.46, w * 0.46, wood[1:5])
    c.ellipse(w / 2.0, h * 0.32, w * 0.34, w * 0.34, "#EFE6CE")
    for k in range(12):
        a = k * math.pi / 6
        c.pixel(w / 2.0 + math.cos(a) * w * 0.28, h * 0.32 + math.sin(a) * w * 0.28, INK)
    c.line([(w / 2.0, h * 0.32), (w / 2.0 + 5, h * 0.32 - 6)], "#2E2A28")
    c.line([(w / 2.0, h * 0.32), (w / 2.0 - 3, h * 0.32 + 7)], "#B5443A")
    c.rect(w * 0.3, h * 0.62, w * 0.7, h * 0.95, "#2E2420")
    c.line([(w / 2.0, h * 0.62), (w / 2.0 + 3, h * 0.86)], ramp(BRASS, 4)[2])
    c.ellipse(w / 2.0 + 3, h * 0.87, 3, 3, ramp(BRASS, 4)[3])
    return c.finish(darker(WALNUT, 0.5))


def wallitem_calendar(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _paper(c, 0, 4, w, h)
    c.rect(0, 4, w, 14, "#A84A3E")
    c.rect(0, 4, w, 6, "#C86A5A")
    for x in range(5, w - 3, 6):
        c.rect(x, 1, x + 2, 7, ramp(IRON, 4)[2])
    for j in range(5):
        for i in range(5):
            x, y = 3 + i * 6, 18 + j * 6
            col = INK if (i + j * 5) % 7 else "#B5443A"
            c.rect(x, y, x + 3, y + 2, col)
    c.line([(3, 18), (9, 23)], "#B5443A")
    c.line([(9, 18), (3, 23)], "#B5443A")
    return c.finish(darker(PAPER, 0.5))


def wallitem_plaque(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    brass = ramp("#9A7840", 5, spread=0.4)
    c.rect(0, 0, w, h, brass[2])
    c.rect(0, 0, w, 2, brass[4])
    c.rect(0, h - 2, w, h, brass[0])
    x = 6
    while x < w - 6:
        n = rnd.randint(3, 5)
        c.rect(x, 5, x + n, 9, brass[0])
        x += n + 2
    for px in (2, w - 3):
        c.pixel(px, h / 2.0, brass[4])
    return c.finish(darker("#9A7840", 0.45))


def wallitem_mirror_large(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    gold = ramp("#B08A4A", 5, spread=0.42)
    c.rect(0, 6, w, h, gold[2])
    c.ellipse(w / 2.0, 10, w * 0.3, 10, gold[2])
    c.rect(0, 6, w, 8, gold[4])
    c.rect(0, 6, 3, h, gold[3])
    c.rect(w - 3, 6, w, h, gold[0])
    glass = ramp("#9EB4C0", 5, spread=0.35)
    c.rect(8, 14, w - 8, h - 8, glass[2])
    c.rect(8, 14, w - 8, h * 0.4, glass[3])
    for k in range(3):
        x = 16 + k * 22
        c.line([(x, h - 12), (x + 30, 18)], glass[4], 3)
    c.rect(w * 0.3, h - 6, w * 0.7, h, gold[1])
    return c.finish(darker("#B08A4A", 0.4))


def wallitem_height_marks(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(HONEY, 5, spread=0.35)
    c.rect(w * 0.35, 0, w * 0.65, h, wood[2])
    c.rect(w * 0.35, 0, w * 0.4, h, wood[4])
    for y in range(4, h - 4, 10):
        c.rect(w * 0.35, y, w * 0.55, y + 1, wood[0])
    colors = ["#B5443A", "#4E7A9A", "#5A8A50", "#C88A3A", "#8A5AA0", "#D07890"]
    for k in range(9):
        y = rnd.randint(20, 84)
        col = colors[k % len(colors)]
        side = rnd.choice([0, 1])
        x0 = 0 if side == 0 else w * 0.65
        c.rect(x0, y, x0 + w * 0.35, y + 1, col)
        c.rect(x0 + 2, y - 3, x0 + 6, y - 1, col)
    return c.finish(darker(HONEY, 0.45))


def wallitem_lamp(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(BRASS, 4)
    c.rect(w * 0.42, h * 0.55, w * 0.58, h, iron[1])
    c.rect(w * 0.2, h * 0.5, w * 0.8, h * 0.58, iron[2])
    glow(c, w * 0.5, h * 0.3, w * 0.24)
    c.rect(w * 0.25, h * 0.08, w * 0.75, h * 0.12, iron[1])
    c.line([(w * 0.25, h * 0.12), (w * 0.25, h * 0.5)], iron[0])
    c.line([(w * 0.75, h * 0.12), (w * 0.75, h * 0.5)], iron[0])
    c.poly([(w * 0.25, h * 0.08), (w * 0.5, 0), (w * 0.75, h * 0.08)], iron[2])
    return c.finish(darker(BRASS, 0.4))


# --- Meubles (vue de face légèrement plongeante, lumière de gauche) ----------------------------------


def _top(c, x0, x1, y0, y1, base):
    """Dessus d'un meuble vu à 12° : bande claire."""
    tones = ramp(base, 5, spread=0.42)
    c.rect(x0, y0, x1, y1, tones[3])
    c.rect(x0, y0, x1, y0 + 1, tones[4])
    c.rect(x0, y1 - 1, x1, y1, tones[1])
    return tones


def _carcass(c, x0, x1, y0, y1, base, width=12):
    """Face avant de planches verticales, arêtes éclairées à gauche."""
    boards(c, x0, y0, x1, y1, base, vertical=True, width=width)
    tones = ramp(base, 5, spread=0.42)
    c.rect(x0, y0, x0 + 2, y1, tones[4])
    c.rect(x1 - 2, y0, x1, y1, tones[0])
    return tones


def _legs(c, xs, y0, y1, base, thick=5):
    tones = ramp(base, 5, spread=0.42)
    for x in xs:
        c.rect(x, y0, x + thick, y1, tones[1])
        c.rect(x, y0, x + 1, y1, tones[3])


def _books(c, x0, x1, y_base, height, rnd):
    x = x0
    colors = ["#8A3A34", "#3E5A7A", "#5A7A48", "#B08A3A", "#6A4A7A", "#A86A3A", "#2E4A4A", "#C8B08A"]
    while x < x1 - 3:
        bw = rnd.randint(3, 6)
        bh = int(height * rnd.uniform(0.7, 1.0))
        col = rnd.choice(colors)
        tones = ramp(col, 4, spread=0.3)
        c.rect(x, y_base - bh, x + bw, y_base, tones[2])
        c.rect(x, y_base - bh, x + 1, y_base, tones[3])
        if bw > 3:
            c.rect(x + 1, y_base - bh + 3, x + bw - 1, y_base - bh + 4, tones[3])
        x += bw + (1 if rnd.random() < 0.15 else 0)
        if rnd.random() < 0.06 and x < x1 - 14:
            c.line([(x, y_base), (x + 10, y_base - bh + 2)], ramp(rnd.choice(colors), 4)[2], 3)
            x += 12


def _papers(c, x0, x1, y_base, height, rnd):
    x = x0
    while x < x1 - 4:
        pw = rnd.randint(10, 18)
        ph = int(height * rnd.uniform(0.4, 1.0))
        for k in range(0, ph, 2):
            col = PAPER if (k // 2) % 3 else "#D8CCAE"
            off = rnd.randint(-1, 1)
            c.rect(x + off, y_base - k - 2, x + pw + off, y_base - k, col)
        x += pw + rnd.randint(1, 3)


def dresser_glass(size, rnd):
    """Vaisselier vitré du réfectoire : bols, bocaux, assiettes derrière les vitres."""
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 4, w - 4, 14, h, WALNUT, width=14)
    c.rect(0, 4, w, 16, tones[3])
    c.rect(0, 4, w, 6, tones[4])
    c.rect(4, 0, w - 4, 6, tones[2])
    glass = ramp("#9EB4B0", 5, spread=0.3)
    gx0, gx1, gy0, gy1 = 12, w - 12, 22, int(h * 0.58)
    c.rect(gx0, gy0, gx1, gy1, "#3A2E28")
    for shelf in range(3):
        y = gy0 + (shelf + 1) * (gy1 - gy0) / 3.0
        c.rect(gx0, y - 3, gx1, y, tones[2])
        x = gx0 + 3
        while x < gx1 - 10:
            kind = rnd.choice(["bowl", "jar", "plate", "plate", "cup"])
            if kind == "plate":
                c.ellipse(x + 7, y - 12, 7, 9, "#E8E2D2")
                c.ellipse(x + 7, y - 12, 4, 6, "#C8D0D8")
                x += 15
            elif kind == "jar":
                col = rnd.choice(["#C88A3A", "#8AA05A", "#B5443A"])
                c.rect(x, y - 16, x + 9, y - 3, col)
                c.rect(x, y - 18, x + 9, y - 16, ramp(IRON, 4)[2])
                c.rect(x + 1, y - 14, x + 3, y - 6, mix(col, "#FFFFFF", 0.4))
                x += 11
            elif kind == "bowl":
                c.ellipse(x + 7, y - 6, 7, 4, "#D8D0C0")
                c.rect(x, y - 7, x + 14, y - 5, "#E8E2D2")
                x += 16
            else:
                c.rect(x, y - 9, x + 7, y - 3, "#E8E2D2")
                c.rect(x + 7, y - 8, x + 9, y - 5, "#E8E2D2")
                x += 11
    # Vitres : montants et reflets.
    c.rect(gx0, gy0, gx1, gy0 + 2, tones[1])
    c.rect((gx0 + gx1) / 2.0 - 2, gy0, (gx0 + gx1) / 2.0 + 2, gy1, tones[2])
    for k in range(2):
        x = gx0 + 8 + k * (gx1 - gx0) / 2.0
        c.line([(x, gy1 - 6), (x + 18, gy0 + 6)], glass[4])
    # Bas : portes pleines, tiroirs, poignées.
    c.rect(4, gy1, w - 4, gy1 + 6, tones[3])
    for k in range(2):
        x0 = 10 + k * (w - 20) / 2.0
        c.rect(x0, gy1 + 10, x0 + (w - 20) / 2.0 - 4, gy1 + 22, tones[1])
        c.rect(x0 + (w - 20) / 4.0 - 4, gy1 + 15, x0 + (w - 20) / 4.0 + 2, gy1 + 17, ramp(BRASS, 4)[3])
        c.rect(x0, gy1 + 26, x0 + (w - 20) / 2.0 - 4, h - 8, tones[1])
        c.rect(x0 + 2, gy1 + 28, x0 + (w - 20) / 2.0 - 6, h - 10, tones[2])
    c.rect(0, h - 6, w, h, tones[0])
    return c.finish(darker(WALNUT, 0.45))


def sink_counter(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 2, w - 2, 24, h, WOOD, width=16)
    stone = ramp("#B8B4A8", 5, spread=0.3)
    c.rect(0, 14, w, 26, stone[3])
    c.rect(0, 14, w, 16, stone[4])
    c.rect(w * 0.18, 16, w * 0.62, 24, stone[1])
    c.rect(w * 0.2, 17, w * 0.6, 22, "#7E8A90")
    iron = ramp(IRON, 4)
    c.rect(w * 0.38, 0, w * 0.42, 18, iron[2])
    c.rect(w * 0.38, 0, w * 0.5, 4, iron[2])
    c.rect(w * 0.48, 2, w * 0.51, 8, iron[1])
    for k in range(3):
        c.ellipse(w * 0.72 + k * 7, 12, 6, 3, "#E8E2D2")
    c.rect(w * 0.7, 8, w * 0.92, 14, "#D8D0C0")
    for x0 in (6, w / 2.0 + 2):
        c.rect(x0, 32, x0 + w / 2.0 - 10, h - 8, tones[1])
        c.rect(x0 + 2, 34, x0 + w / 2.0 - 12, h - 10, tones[2])
        c.rect(x0 + w / 4.0 - 5, 46, x0 + w / 4.0 - 1, 52, ramp(BRASS, 4)[3])
    c.rect(0, h - 5, w, h, tones[0])
    return c.finish(darker(WOOD, 0.45))


def table_long(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _top(c, 0, w, 0, 22, HONEY)
    grain = posterize(noise((w - 4, 16), (8, 2), rnd), tones[2:5], dither=30)
    c.img.paste(grain, (2, 3))
    c.rect(0, 22, w, 32, tones[1])
    c.rect(0, 22, w, 24, tones[2])
    _legs(c, (8, w - 18, w / 2.0 - 4), 32, h, HONEY, thick=10)
    c.rect(14, h - 26, w - 14, h - 21, ramp(HONEY, 5)[1])
    # Chopes et un plateau posés.
    for x in (w * 0.2, w * 0.55, w * 0.8):
        c.rect(x, 5, x + 8, 15, "#C8C0B0")
        c.rect(x + 8, 7, x + 11, 12, "#C8C0B0")
        c.rect(x + 1, 5, x + 3, 15, "#E8E2D2")
    return c.finish(darker(HONEY, 0.4))


def bench_long(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _top(c, 0, w, 0, 12, HONEY)
    c.rect(0, 12, w, 18, tones[1])
    _legs(c, (8, w - 18, w / 2.0 - 4), 18, h, HONEY, thick=9)
    return c.finish(darker(HONEY, 0.4))


def crystal_stove(size, rnd):
    """Fourneau de cristal de la cuisine : fonte, plaque, foyer de cristaux qui luisent."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("#4A4644", 5, spread=0.45)
    c.rect(4, 16, w - 4, h, iron[2])
    c.rect(4, 16, 7, h, iron[3])
    c.rect(w - 7, 16, w - 4, h, iron[1])
    c.rect(0, 8, w, 18, iron[3])
    c.rect(0, 8, w, 10, iron[4])
    for x in (w * 0.28, w * 0.68):
        c.ellipse(x, 10, 14, 3, iron[1])
        c.ellipse(x, 10, 9, 2, iron[0])
    c.rect(w * 0.6, 0, w * 0.82, 9, "#6A6460")
    c.rect(w * 0.6, 0, w * 0.82, 2, "#8A8480")
    # Foyer : vitre et cristaux couleur cristal (lueur).
    fx0, fx1, fy0, fy1 = w * 0.18, w * 0.82, h * 0.36, h * 0.72
    c.rect(fx0 - 3, fy0 - 3, fx1 + 3, fy1 + 3, ramp(BRASS, 4)[2])
    c.rect(fx0, fy0, fx1, fy1, "#2A1E18")
    for k in range(5):
        glow(c, fx0 + 8 + k * (fx1 - fx0 - 16) / 4.0, fy1 - 8 - (k % 2) * 6, 6)
    c.rect(w * 0.2, h * 0.8, w * 0.8, h * 0.86, iron[1])
    c.rect(w * 0.45, h * 0.8, w * 0.55, h * 0.83, ramp(BRASS, 4)[3])
    c.rect(0, h - 5, w, h, iron[0])
    return c.finish(darker("#4A4644", 0.5))


def kitchen_counter(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 2, w - 2, 20, h, WOOD, width=16)
    top = _top(c, 0, w, 10, 22, "#C8BCA8")
    del top
    for x0 in range(8, w - 40, 46):
        c.rect(x0, 28, x0 + 40, 40, tones[1])
        c.rect(x0 + 16, 33, x0 + 24, 35, ramp(BRASS, 4)[3])
        c.rect(x0, 46, x0 + 40, h - 8, tones[1])
        c.rect(x0 + 2, 48, x0 + 38, h - 10, tones[2])
    # Œufs, sucre, lait, baies sur le comptoir.
    c.ellipse(w * 0.15, 8, 7, 4, "#B0885A")
    for k in range(3):
        c.ellipse(w * 0.12 + k * 5, 6, 2, 3, "#F2EAD8")
    c.rect(w * 0.35, 0, w * 0.42, 12, "#E8E4DA")
    c.rect(w * 0.35, 0, w * 0.42, 2, "#9EB4C0")
    c.rect(w * 0.55, 3, w * 0.66, 12, "#C8A070")
    c.ellipse(w * 0.8, 9, 9, 3, "#8A3A44")
    c.ellipse(w * 0.8, 8, 7, 2, "#B5445A")
    c.rect(0, h - 5, w, h, tones[0])
    return c.finish(darker(WOOD, 0.45))


def kitchen_table(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _top(c, 0, w, 0, 20, "#C8B090")
    c.rect(0, 20, w, 28, tones[1])
    _legs(c, (6, w - 14), 28, h, HONEY, thick=8)
    c.rect(10, h - 20, w - 10, h - 16, ramp(HONEY, 5)[1])
    c.ellipse(w * 0.3, 8, 12, 5, "#D8D0C0")
    c.ellipse(w * 0.3, 7, 9, 3, "#F2EAD8")
    c.rect(w * 0.55, 2, w * 0.72, 12, "#8A5A3A")
    c.rect(w * 0.6, 0, w * 0.62, 6, "#C8B090")
    return c.finish(darker(HONEY, 0.4))


def bookshelf(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 4, h, WALNUT, width=w)
    c.rect(0, 0, w, 6, tones[3])
    inner = (8, w - 8)
    shelves = 5
    for k in range(shelves):
        y0 = 10 + k * (h - 22) / shelves
        y1 = y0 + (h - 22) / shelves - 4
        c.rect(inner[0], y0, inner[1], y1, "#2E2420")
        _books(c, inner[0] + 1, inner[1] - 1, y1, (y1 - y0) - 3, rnd)
        c.rect(inner[0], y1, inner[1], y1 + 4, tones[3])
        c.rect(inner[0], y1, inner[1], y1 + 1, tones[4])
    c.rect(0, h - 8, w, h, tones[1])
    return c.finish(darker(WALNUT, 0.45))


def window_seat(size, rnd):
    """Siège sous la fenêtre de la salle de lecture : coffre de bois, coussins."""
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 24, h, HONEY, width=w)
    for x0 in range(10, w - 30, 46):
        c.rect(x0, 30, x0 + 38, h - 6, tones[1])
        c.rect(x0 + 2, 32, x0 + 36, h - 8, tones[2])
    cushion = ramp("#7A8A5A", 5, spread=0.35)
    c.rect(2, 10, w - 2, 26, cushion[2])
    c.rect(2, 10, w - 2, 13, cushion[4])
    for x in range(20, w - 10, 38):
        c.rect(x, 12, x + 1, 25, cushion[1])
    c.blob(w * 0.16, 9, 13, 9, ramp("#B98A84", 4))
    c.rect(w * 0.6, 4, w * 0.74, 11, "#8A3A34")
    c.rect(w * 0.6, 4, w * 0.74, 5, "#B5443A")
    return c.finish(darker(HONEY, 0.4))


def reading_table(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _top(c, 0, w, 0, 18, WALNUT)
    c.rect(0, 18, w, 26, tones[1])
    _legs(c, (6, w - 13), 26, h, WALNUT, thick=7)
    c.rect(w * 0.15, 4, w * 0.4, 12, PAPER)
    c.rect(w * 0.27, 4, w * 0.28, 12, "#B8AC92")
    c.rect(w * 0.6, 3, w * 0.8, 10, "#3E5A7A")
    c.rect(w * 0.6, 3, w * 0.8, 4, "#5E7A9A")
    return c.finish(darker(WALNUT, 0.45))


def chair(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WALNUT, 5, spread=0.42)
    post(c, 6, 0, h, 6, WALNUT)
    post(c, w - 6, 0, h, 6, WALNUT)
    for y in (6, 20):
        c.rect(6, y, w - 6, y + 6, wood[2])
        c.rect(6, y, w - 6, y + 1, wood[4])
    c.rect(2, h * 0.52, w - 2, h * 0.6, wood[3])
    c.rect(2, h * 0.52, w - 2, h * 0.54, wood[4])
    c.rect(2, h * 0.6, w - 2, h * 0.64, wood[1])
    c.rect(9, h * 0.64, 13, h, wood[1])
    c.rect(w - 13, h * 0.64, w - 9, h, wood[1])
    return c.finish(darker(WALNUT, 0.45))


def archive_shelf(size, rnd):
    """Rayonnage des archives : un océan de papiers, cartons, classeurs."""
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 4, h, WOOD, width=w)
    c.rect(0, 0, w, 6, tones[3])
    shelves = 5
    for k in range(shelves):
        y0 = 10 + k * (h - 22) / shelves
        y1 = y0 + (h - 22) / shelves - 4
        c.rect(6, y0, w - 6, y1, "#2E2420")
        x = 8
        while x < w - 10:
            kind = rnd.choice(["papers", "box", "binders", "papers"])
            span = rnd.randint(18, 34)
            if kind == "papers":
                _papers(c, x, min(w - 8, x + span), y1, (y1 - y0) - 4, rnd)
            elif kind == "box":
                col = ramp("#A8885A", 4)
                c.rect(x, y1 - (y1 - y0) * 0.7, x + span, y1, col[2])
                c.rect(x, y1 - (y1 - y0) * 0.7, x + span, y1 - (y1 - y0) * 0.7 + 2, col[3])
                c.rect(x + span / 2.0 - 4, y1 - (y1 - y0) * 0.45, x + span / 2.0 + 4, y1 - (y1 - y0) * 0.3,
                       PAPER)
            else:
                _books(c, x, min(w - 8, x + span), y1, (y1 - y0) - 3, rnd)
            x += span + 2
        c.rect(6, y1, w - 6, y1 + 4, tones[3])
        c.rect(6, y1, w - 6, y1 + 1, tones[4])
    # Papiers qui dépassent et pendent.
    for _ in range(5):
        x, y = rnd.uniform(10, w - 20), rnd.uniform(20, h - 30)
        c.rect(x, y, x + 9, y + 12, PAPER)
    c.rect(0, h - 8, w, h, tones[1])
    return c.finish(darker(WOOD, 0.45))


def desk_cluttered(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 40, h, WALNUT, width=w)
    _top(c, 0, w, 30, 42, WALNUT)
    _papers(c, 4, w * 0.55, 36, 30, rnd)
    _papers(c, w * 0.62, w - 4, 36, 22, rnd)
    c.rect(w * 0.56, 20, w * 0.6, 34, ramp(BRASS, 4)[2])
    glow(c, w * 0.58, 16, 5)
    for k in range(3):
        y = 48 + k * 18
        c.rect(6, y, w * 0.35, y + 14, tones[1])
        c.rect(w * 0.17, y + 6, w * 0.2, y + 8, ramp(BRASS, 4)[3])
        c.rect(w * 0.65, y, w - 6, y + 14, tones[1])
        c.rect(w * 0.8, y + 6, w * 0.83, y + 8, ramp(BRASS, 4)[3])
    c.rect(w * 0.37, 46, w * 0.63, h, "#2E2420")
    return c.finish(darker(WALNUT, 0.45))


def sofa_beige(size, rnd):
    """Canapé beige à trois places des archives."""
    w, h = size
    c = Canvas(w, h, rnd)
    cloth = ramp("#C8B496", 5, spread=0.32)
    c.rect(10, 6, w - 10, 44, cloth[2])
    c.rect(10, 6, w - 10, 9, cloth[3])
    for k in range(3):
        x0 = 16 + k * (w - 32) / 3.0
        c.rect(x0, 12, x0 + (w - 32) / 3.0 - 3, 42, cloth[3])
        c.rect(x0, 12, x0 + 2, 42, cloth[4])
        c.rect(x0, 44, x0 + (w - 32) / 3.0 - 3, 58, cloth[3])
        c.rect(x0, 44, x0 + (w - 32) / 3.0 - 3, 46, cloth[4])
    for x0 in (0, w - 18):
        c.rect(x0, 26, x0 + 18, h - 8, cloth[2])
        c.rect(x0, 26, x0 + 18, 30, cloth[4] if x0 == 0 else cloth[3])
        c.rect(x0 + (16 if x0 else 0), 30, x0 + (18 if x0 else 2), h - 8, cloth[1] if x0 else cloth[3])
    c.rect(18, 58, w - 18, h - 8, cloth[1])
    _legs(c, (8, w - 14), h - 8, h, WALNUT, thick=6)
    c.rect(w * 0.6, 34, w * 0.74, 42, PAPER)
    return c.finish(darker("#C8B496", 0.45))


def paper_stacks(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    x = 2
    while x < w - 12:
        pw = rnd.randint(18, 28)
        ph = rnd.randint(int(h * 0.4), h - 4)
        for k in range(0, ph, 2):
            col = PAPER if (k // 2) % 4 else rnd.choice(["#D8CCAE", "#C8B890", "#E8DCC0"])
            off = rnd.randint(-1, 1)
            c.rect(x + off, h - k - 2, x + pw + off, h - k, col)
        c.rect(x, h - ph - 2, x + pw, h - ph, "#F4ECD8")
        if rnd.random() < 0.4:
            c.rect(x + 3, h - ph * 0.5, x + pw - 3, h - ph * 0.5 + 2, "#A84A3E")
        x += pw + rnd.randint(-2, 2)
    return c.finish(darker(PAPER, 0.45))


def bed_infirmary(size, rnd):
    """Lit d'infirmerie vu du pied : tête de lit, oreiller, couverture, pied de fer."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("#D8D4CC", 5, spread=0.3)
    c.rect(4, 0, w - 4, 34, iron[2])
    c.rect(4, 0, w - 4, 3, iron[4])
    for x in range(10, w - 8, 10):
        c.rect(x, 6, x + 2, 32, iron[1])
    c.rect(0, 0, 5, 40, iron[3])
    c.rect(w - 5, 0, w, 40, iron[1])
    sheet = ramp("#EEEAE0", 5, spread=0.2)
    c.rect(6, 34, w - 6, 92, sheet[2])
    c.ellipse(w / 2.0, 42, w * 0.32, 8, sheet[4])
    blanket = ramp("#8EA0B8", 5, spread=0.3)
    c.rect(6, 56, w - 6, 92, blanket[2])
    c.rect(6, 56, w - 6, 60, blanket[4])
    c.rect(6, 92, w - 6, h - 18, blanket[1])
    c.rect(4, 60, 8, h - 18, blanket[3])
    c.rect(0, 88, w, 96, iron[2])
    c.rect(0, 88, w, 90, iron[4])
    for x in (2, w - 7):
        c.rect(x, 88, x + 5, h, iron[1])
    c.rect(8, h - 18, w - 8, h - 14, iron[1])
    return c.finish(darker("#8A8680", 0.5))


def nightstand_vase(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 2, w - 2, 38, h, HONEY, width=w)
    _top(c, 0, w, 32, 40, HONEY)
    c.rect(8, 48, w - 8, 60, tones[1])
    c.rect(w / 2.0 - 2, 53, w / 2.0 + 2, 55, ramp(BRASS, 4)[3])
    vase = ramp("#7F9CCF", 4)
    c.blob(w / 2.0, 26, 7, 8, vase)
    c.rect(w / 2.0 - 3, 12, w / 2.0 + 3, 20, vase[2])
    for k, col in enumerate(["#E8D06A", "#E89AA8", "#F2EEE0", "#E8D06A"]):
        c.line([(w / 2.0, 14), (w / 2.0 - 10 + k * 7, 4 + (k % 2) * 3)], "#5A8A50")
        c.ellipse(w / 2.0 - 10 + k * 7, 4 + (k % 2) * 3, 3, 3, col)
    return c.finish(darker(HONEY, 0.4))


def medicine_cabinet(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 4, h, "#C8C4B8", width=w)
    c.rect(0, 0, w, 6, tones[3])
    glass = ramp("#9EB4C0", 4)
    c.rect(8, 12, w - 8, h * 0.55, "#4A5A60")
    for k in range(3):
        y = 12 + (k + 1) * (h * 0.55 - 12) / 3.0
        c.rect(8, y - 2, w - 8, y, tones[2])
        x = 10
        while x < w - 14:
            col = rnd.choice(["#8A5A3A", "#E8E2D2", "#5A8A50", "#9A6A3A", "#E8E2D2"])
            bh = rnd.randint(8, 14)
            c.rect(x, y - 2 - bh, x + 6, y - 2, col)
            c.rect(x, y - 4 - bh, x + 6, y - 2 - bh, "#3E3632")
            x += 9
    c.line([(14, h * 0.5), (w - 20, 18)], glass[3], 2)
    c.rect(w / 2.0 - 1, 12, w / 2.0 + 1, h * 0.55, tones[2])
    c.rect(8, h * 0.6, w - 8, h - 10, tones[1])
    c.rect(w / 2.0 - 8, h * 0.66, w / 2.0 + 8, h * 0.66 + 16, "#E8E4DA")
    c.rect(w / 2.0 - 2, h * 0.66 + 3, w / 2.0 + 2, h * 0.66 + 13, "#B5443A")
    c.rect(w / 2.0 - 5, h * 0.66 + 6, w / 2.0 + 5, h * 0.66 + 10, "#B5443A")
    return c.finish(darker("#8A867C", 0.5))


def desk_small(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _top(c, 0, w, 10, 22, HONEY)
    c.rect(0, 22, w, 28, tones[1])
    _legs(c, (4, w - 10), 28, h, HONEY, thick=6)
    c.rect(w * 0.45, 28, w - 12, 44, tones[2])
    c.rect(w * 0.7, 34, w * 0.75, 36, ramp(BRASS, 4)[3])
    c.rect(w * 0.1, 2, w * 0.45, 14, "#E8E4DA")
    c.rect(w * 0.12, 4, w * 0.43, 6, INK)
    c.rect(w * 0.6, 0, w * 0.66, 14, "#9EB4C0")
    c.rect(w * 0.61, 8, w * 0.65, 14, "#C8D8E0")
    return c.finish(darker(HONEY, 0.4))


def toy_shelf(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 4, h, HONEY, width=w)
    c.rect(0, 0, w, 6, tones[3])
    for k in range(3):
        y0 = 10 + k * (h - 18) / 3.0
        y1 = y0 + (h - 18) / 3.0 - 4
        c.rect(6, y0, w - 6, y1, "#3A2E28")
        x = 8
        while x < w - 14:
            kind = rnd.choice(["game", "game", "plush", "ball", "blocks"])
            if kind == "game":
                col = rnd.choice(["#B5443A", "#3E5A7A", "#5A8A50", "#C88A3A"])
                bh = rnd.randint(4, 7)
                for j in range(rnd.randint(2, 4)):
                    c.rect(x, y1 - (j + 1) * bh, x + 22, y1 - j * bh, ramp(col, 4)[1 + j % 3])
                x += 25
            elif kind == "plush":
                col = rnd.choice(["#7F9CCF", "#C8A070", "#E89AA8"])
                c.blob(x + 8, y1 - 9, 8, 9, ramp(col, 4))
                c.ellipse(x + 3, y1 - 17, 3, 3, ramp(col, 4)[2])
                c.ellipse(x + 13, y1 - 17, 3, 3, ramp(col, 4)[2])
                x += 18
            elif kind == "ball":
                c.blob(x + 7, y1 - 7, 7, 7, ramp("#E8E2D2", 4))
                x += 16
            else:
                for j in range(3):
                    c.rect(x + j * 6, y1 - 6, x + j * 6 + 5, y1, rnd.choice(["#B5443A", "#E8D06A", "#4E7A9A"]))
                x += 20
        c.rect(6, y1, w - 6, y1 + 4, tones[3])
    c.rect(0, h - 6, w, h, tones[1])
    return c.finish(darker(HONEY, 0.4))


def plush_pile(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for k, (col, x, r) in enumerate([("#7F9CCF", 0.3, 16), ("#C8A070", 0.62, 14), ("#E89AA8", 0.45, 11),
                                       ("#9AB878", 0.8, 9)]):
        tones = ramp(col, 4)
        cy = h - r
        c.blob(w * x, cy, r, r, tones)
        c.ellipse(w * x - r * 0.6, cy - r * 0.85, r * 0.35, r * 0.35, tones[2])
        c.ellipse(w * x + r * 0.6, cy - r * 0.85, r * 0.35, r * 0.35, tones[2])
        c.pixel(w * x - 3, cy - 2, "#2E2A28")
        c.pixel(w * x + 3, cy - 2, "#2E2A28")
        del k
    return c.finish(darker("#7F9CCF", 0.4))


def board_game_table(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _top(c, 0, w, 6, 20, HONEY)
    c.rect(0, 20, w, 26, tones[1])
    _legs(c, (4, w - 10), 26, h, HONEY, thick=6)
    c.rect(w * 0.2, 6, w * 0.62, 17, "#E8DCC0")
    for i in range(6):
        for j in range(2):
            if (i + j) % 2 == 0:
                c.rect(w * 0.2 + 2 + i * 6, 8 + j * 4, w * 0.2 + 7 + i * 6, 11 + j * 4, "#3E3632")
    for k, col in enumerate(["#B5443A", "#4E7A9A", "#E8D06A"]):
        c.rect(w * 0.7 + k * 6, 4, w * 0.7 + k * 6 + 4, 12, col)
    c.rect(w * 0.08, 0, w * 0.18, 10, "#B5443A")
    return c.finish(darker(HONEY, 0.4))


def bathtub(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    enamel = ramp("#E8E6DE", 5, spread=0.2)
    c.ellipse(w / 2.0, 14, w / 2.0 - 2, 12, enamel[3])
    c.ellipse(w / 2.0, 15, w / 2.0 - 10, 8, "#9EB8C8")
    c.ellipse(w / 2.0 - 12, 13, 18, 4, "#C8DCE6")
    c.rect(4, 14, w - 4, h - 12, enamel[2])
    c.rect(4, 14, 8, h - 12, enamel[4])
    c.rect(w - 8, 14, w - 4, h - 12, enamel[0])
    c.rect(4, h - 16, w - 4, h - 12, enamel[1])
    brass = ramp(BRASS, 4)
    for x in (12, w - 20):
        c.rect(x, h - 12, x + 8, h, brass[2])
        c.rect(x, h - 4, x + 10, h, brass[1])
    c.rect(w - 22, 0, w - 18, 10, brass[2])
    for k in range(4):
        c.ellipse(w * 0.3 + k * 9, 10, 4, 3, "#F4F2EC")
    return c.finish(darker("#A8A49A", 0.45))


def washstand(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 4, w - 4, 34, h, HONEY, width=w)
    _top(c, 0, w, 26, 36, "#C8C4B8")
    c.ellipse(w / 2.0, 24, 22, 7, "#E8E6DE")
    c.ellipse(w / 2.0, 23, 17, 4, "#9EB8C8")
    c.rect(w * 0.2, 4, w * 0.36, 22, "#E8E6DE")
    c.rect(w * 0.2, 0, w * 0.36, 6, "#D8D6CE")
    c.rect(w * 0.7, 10, w * 0.76, 22, "#C8A070")
    c.rect(w * 0.6, 40, w * 0.9, 46, "#8EA0B8")
    c.rect(10, 48, w - 10, h - 8, tones[1])
    c.rect(12, 50, w - 12, h - 10, tones[2])
    return c.finish(darker(HONEY, 0.4))


def water_basin(size, rnd):
    """Point d'eau froide du couloir : bassin de pierre, robinet, seau."""
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("#A8A094", 5, spread=0.35)
    c.rect(6, 40, w - 6, h, stone[2])
    c.rect(6, 40, 10, h, stone[4])
    c.rect(w - 10, 40, w - 6, h, stone[0])
    c.rect(0, 30, w, 42, stone[3])
    c.rect(0, 30, w, 32, stone[4])
    c.rect(8, 32, w - 8, 38, "#6E8A98")
    iron = ramp(IRON, 4)
    c.rect(w / 2.0 - 2, 0, w / 2.0 + 2, 30, iron[2])
    c.rect(w / 2.0 - 2, 6, w / 2.0 + 14, 10, iron[2])
    c.rect(w / 2.0 + 12, 10, w / 2.0 + 15, 16, iron[1])
    c.rect(w / 2.0 - 8, 0, w / 2.0 + 8, 3, iron[3])
    c.rect(12, h - 26, 34, h - 4, iron[2])
    c.rect(12, h - 26, 34, h - 24, iron[3])
    c.rect(w - 30, 18, w - 6, 26, "#E8E2D2")
    return c.finish(darker("#A8A094", 0.45))


def cupboard_supplies(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 6, h, WOOD, width=w)
    c.rect(0, 0, w, 8, tones[3])
    for x0 in (6, w / 2.0 + 1):
        c.rect(x0, 14, x0 + w / 2.0 - 7, h - 12, tones[1])
        c.rect(x0 + 3, 18, x0 + w / 2.0 - 10, h * 0.45, tones[2])
        c.rect(x0 + 3, h * 0.5, x0 + w / 2.0 - 10, h - 16, tones[2])
    c.rect(w / 2.0 - 5, h * 0.46, w / 2.0 - 2, h * 0.52, ramp(BRASS, 4)[3])
    c.rect(w / 2.0 + 2, h * 0.46, w / 2.0 + 5, h * 0.52, ramp(BRASS, 4)[3])
    c.rect(w * 0.6, h * 0.3, w * 0.86, h * 0.36, PAPER)
    return c.finish(darker(WOOD, 0.45))


def toilet_stall(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _carcass(c, 0, w, 20, h - 10, "#9AA08C", width=w)
    c.rect(0, 14, w, 22, tones[3])
    boards(c, 10, 28, w - 10, h - 14, "#8A9078", vertical=True, width=12)
    c.rect(w - 24, h * 0.55, w - 16, h * 0.55 + 6, ramp(BRASS, 4)[3])
    c.rect(w * 0.35, 40, w * 0.65, 50, PAPER)
    for x in (4, w - 10):
        c.rect(x, h - 12, x + 6, h, ramp(IRON, 4)[1])
    c.rect(0, 0, w, 14, "#3A3430")
    return c.finish(darker("#7A8070", 0.45))


def shoe_bench(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = _top(c, 0, w, 0, 10, WOOD)
    c.rect(0, 10, w, 16, tones[1])
    _legs(c, (4, w - 12, w / 2.0 - 4), 16, h, WOOD, thick=8)
    for k in range(5):
        x = 14 + k * 26
        col = rnd.choice(["#6A4A36", "#8A3A34", "#3E5A7A", "#5A4A3A"])
        c.rect(x, h - 8, x + 9, h - 2, col)
        c.rect(x + 11, h - 8, x + 20, h - 2, col)
    return c.finish(darker(WOOD, 0.45))


# --- Tapis (vus de dessus, bord à franges) ------------------------------------------------------------


def _rug(size, rnd, field, border, motif):
    w, h = size
    c = Canvas(w, h, rnd)
    m = 14
    f = ramp(field, 5, spread=0.3)
    b = ramp(border, 5, spread=0.3)
    c.rect(m, m, w - m, h - m, b[2])
    c.rect(m + 8, m + 8, w - m - 8, h - m - 8, f[2])
    c.img.paste(posterize(noise((w - 2 * m - 20, h - 2 * m - 20), (6, 4), rnd), f[1:4], dither=40), (m + 10, m + 10))
    for k in range(0, w - 2 * m - 24, 12):
        c.rect(m + 12 + k, m + 3, m + 18 + k, m + 6, b[4])
        c.rect(m + 12 + k, h - m - 6, m + 18 + k, h - m - 3, b[4])
    cx, cy = w / 2.0, h / 2.0
    mt = ramp(motif, 4)
    c.poly([(cx, cy - h * 0.22), (cx + w * 0.16, cy), (cx, cy + h * 0.22), (cx - w * 0.16, cy)], mt[2])
    c.poly([(cx, cy - h * 0.12), (cx + w * 0.08, cy), (cx, cy + h * 0.12), (cx - w * 0.08, cy)], f[3])
    for x0, y0 in ((m, m), (w - m - 6, m), (m, h - m - 5), (w - m - 6, h - m - 5)):
        if rnd.random() < 0.7:
            c.img.paste((0, 0, 0, 0), (int(x0), int(y0), int(x0) + 6, int(y0) + 5))
    img = c.finish(darker(border, 0.5))
    _fringes(img, rnd, m, 11, "#E8DCC0")
    return img


def _fringes(img, rnd, m, length, color):
    """Franges aux petits côtés (dessinées après le contour, un fil tous les 4 px) : bord irrégulier."""
    w, h = img.size
    d = ImageDraw.Draw(img)
    for y in range(m + 2, h - m - 2, 4):
        d.line((m - length + rnd.randint(0, 3), y, m - 1, y), fill=rgba(color))
        d.line((w - m, y, w - m + length - 1 - rnd.randint(0, 3), y), fill=rgba(color))


def rug_play(size, rnd):
    return _rug(size, rnd, "#B07A5A", "#5A6A8A", "#E8C86A")


def rug_doormat(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    m = 11
    coir = ramp("#A8885A", 5, spread=0.35)
    c.rect(m, m, w - m, h - m, coir[2])
    c.img.paste(posterize(noise((w - 2 * m - 4, h - 2 * m - 4), (12, 3), rnd), coir[1:4], dither=60),
                (m + 2, m + 2))
    c.rect(m + 6, m + 6, w - m - 6, m + 8, coir[0])
    c.rect(m + 6, h - m - 8, w - m - 6, h - m - 6, coir[0])
    img = c.finish(darker("#A8885A", 0.5))
    _fringes(img, rnd, m, 8, coir[3])
    return img


RECIPES = {}
for _name, _size, _kind in SURFACES:
    RECIPES["interior/" + _name] = globals()[_name]
for _name, _size in WALL_PANELS:
    RECIPES["interior/" + _name] = globals()[_name]
for _name, _size, _depth, _glow in FURNITURE:
    RECIPES["interior/props/" + _name] = globals()[_name]
for _name, _size in RUGS:
    RECIPES["interior/props/" + _name] = globals()[_name]


# --- Manifeste et scènes ------------------------------------------------------------------------------


def cmd_manifest():
    """Ajoute à la fin de la liste des images les entrées du lot I absentes (une par ligne)."""
    with open(MANIFEST, encoding="utf-8") as handle:
        text = handle.read()
    data = json.loads(text)
    known = {e["path"] for e in data["images"]}
    missing = [e for e in entries() if e["path"] not in known]
    if not missing:
        print("manifeste à jour (%d images du lot %s)" % (len(entries()), LOT))
        return 0
    marker = "\n ],\n \"sheets\""
    at = text.index(marker)
    lines = "".join(",\n  " + json.dumps(e, ensure_ascii=False) for e in missing)
    text = text[:at] + lines + text[at:]
    json.loads(text)
    with open(MANIFEST, "w", encoding="utf-8") as handle:
        handle.write(text)
    print("%d entrée(s) ajoutée(s) au manifeste" % len(missing))
    return 0


def _vec(*values):
    return ", ".join(_num(v) for v in values)


def _num(value):
    text = ("%.4f" % value).rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def furniture_scene(name, size, depth, glow_amount):
    """Texte de la scène d'un meuble : InteriorPanel posé au milieu de son emprise (l'image au bord
    sud, image_offset), ombre sur l'emprise, boîte de collision (couche 1) sur l'emprise."""
    w_m, h_m = size[0] / float(PPM), size[1] / float(PPM)
    shadow_width = 0.9
    shadow_depth = min(2.0, max(0.05, depth / (w_m * shadow_width)))
    box = (round(w_m * 0.94, 3), round(h_m, 3), round(depth, 3))
    lines = [
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Script" path="res://src/world/interior_panel.gd" id="1_panel"]',
        '[ext_resource type="Texture2D" path="res://assets/hd2d/interior/props/%s.png" id="2_image"]' % name,
        "",
        '[sub_resource type="BoxShape3D" id="BoxShape3D_%s"]' % name,
        "size = Vector3(%s)" % _vec(*box),
        "",
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_panel")',
        'texture = ExtResource("2_image")',
        "shadow_width = %s" % _num(shadow_width),
        "shadow_depth = %s" % _num(round(shadow_depth, 3)),
        "image_offset = Vector3(0, 0, %s)" % _num(depth / 2.0),
    ]
    if glow_amount > 0.0:
        lines.append("glow = %s" % _num(glow_amount))
    lines += [
        "",
        '[node name="Collision" type="StaticBody3D" parent="."]',
        "collision_mask = 0",
        "",
        '[node name="CollisionShape3D" type="CollisionShape3D" parent="Collision"]',
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, %s, 0)" % _num(box[1] / 2.0),
        'shape = SubResource("BoxShape3D_%s")' % name,
        "",
    ]
    return "\n".join(lines)


def rug_scene(name):
    return "\n".join([
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Script" path="res://src/world/ground_decal.gd" id="1_decal"]',
        '[ext_resource type="Texture2D" path="res://assets/hd2d/interior/props/%s.png" id="2_image"]' % name,
        "",
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_decal")',
        'texture = ExtResource("2_image")',
        "follow_ground = false",
        "",
    ])


def cmd_scenes(force=False):
    written = 0
    for name, size, depth, glow_amount in FURNITURE:
        written += _write(name, furniture_scene(name, size, depth, glow_amount), force)
    for name, _size in RUGS:
        written += _write(name, rug_scene(name), force)
    print("%d scène(s) écrite(s) dans src/world/props/" % written)
    return 0


def _write(name, text, force):
    path = os.path.join(PROPS_DIR, name + ".tscn")
    if os.path.exists(path) and not force:
        with open(path, encoding="utf-8") as handle:
            if handle.read() == text:
                return 0
        print("%s existe (--force pour la réécrire)" % os.path.relpath(path, ROOT))
        return 0
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    print(os.path.relpath(path, ROOT))
    return 1


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("manifest", "scenes"):
        print(__doc__)
        return 2
    if args[0] == "manifest":
        return cmd_manifest()
    return cmd_scenes("--force" in args)


if __name__ == "__main__":
    sys.exit(main())
