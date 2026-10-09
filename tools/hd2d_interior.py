#!/usr/bin/env python3
"""Intérieurs (lot E3) : images du lot I employées par les intérieurs (cahier n° 3,
docs/ASSETS_HD2D_SUKASUKA.md, section 3 ; conventions de docs/REFONTE.md, section 8.1), leurs
entrées du manifeste, les remplaçants des images que la livraison n'a pas encore et les scènes des
meubles. Guide : docs/INTERIEURS.md.

Les images vivent dans assets/hd2d/interior/ :
- sols floor_<matière> (384 × 384, 4 × 4 m, tile : sans raccord, vue de dessus) ;
- murs wall_<matière> (384 × 288, 4 × 3 m, tile_h : raccord à gauche et à droite, vue de face,
  corniche en haut, plinthe en bas) ;
- dessus de mur coupé wallcut_<matière> (384 × 24, 4 × 0,25 m, tile_h) ;
- portes door_*, fenêtres window_*, éléments de mur wallitem_* (panel, posés contre un mur par
  InteriorRoom d'après interior.json) ;
- meubles props/<nom> (panel, vue de face légèrement plongeante, scène InteriorPanel de
  src/world/props/<nom>.tscn) ;
et les tapis dans assets/hd2d/decals/ (decal à bord plein, scène GroundDecal).

Les vraies images (livrées) ne se redessinent jamais : seules celles de PLACEHOLDERS ont une
recette, et une vraie image du même nom les remplacera sans toucher au code.

Usage :

    python3 tools/hd2d_interior.py manifest   # met les entrées du lot I du manifeste à jour
    python3 tools/hd2d_assets.py gen --lot I  # dessine les remplaçants absents (recettes ci-dessous)
    python3 tools/hd2d_interior.py scenes     # écrit les scènes des meubles et des tapis
    python3 tools/hd2d_assets.py check --lot I

Le résultat est déterministe (graine tirée du nom de chaque image).
"""

import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hd2d_art import (  # noqa: E402
    Canvas, WrapCanvas, darker, fractal, mix, noise, paste_wrap, posterize, ramp, rgba, threshold)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "hd2d_manifest.json")
PROPS_DIR = os.path.join(ROOT, "src", "world", "props")
PPM = 96
LOT = "I"
# Meuble plaqué au mur (emprise de moins de 0,3 m, comme le grand miroir) : coupé comme le mur
# (InteriorRoom.CUT_HEIGHT), sinon ce qu'il garde de haut cacherait le joueur de l'autre côté.
WALL_MOUNTED = 0.3
WALL_CUT_HEIGHT = 0.15

DARK = "wood_dark"
HONEY = "#B08458"
IRON = "iron"
BRASS = "brass"

# --- Liste des images (nom, taille en px, priorité du cahier n° 3) ---------------------------------

# Matières (assets/hd2d/interior/) : (nom, taille, genre, priorité).
SURFACES = [
    ("floor_planks_worn", (384, 384), "tile", 1),
    ("floor_planks_dark", (384, 384), "tile", 1),
    ("floor_tiles_bath", (384, 384), "tile", 1),
    ("floor_flagstone_cellar", (384, 384), "tile", 2),
    ("floor_kitchen_tiles", (384, 384), "tile", 1),
    ("wall_plaster_worn", (384, 288), "tile_h", 1),
    ("wall_wainscot", (384, 288), "tile_h", 1),
    ("wall_wallpaper_faded", (384, 288), "tile_h", 1),
    ("wall_kitchen_tiles", (384, 288), "tile_h", 1),
    ("wall_cellar_stone", (384, 288), "tile_h", 2),
    ("wallcut_wood", (384, 24), "tile_h", 1),
    ("wallcut_stone", (384, 24), "tile_h", 2),
]

# Portes, fenêtres et éléments de mur (assets/hd2d/interior/, panel) : (nom, taille, priorité).
WALL_PANELS = [
    ("door_frame_wood", (126, 221), 1),
    ("door_room", (106, 211), 1),
    ("door_double", (192, 230), 1),
    ("door_armory", (125, 221), 2),
    ("window_cross_small", (77, 96), 1),
    ("window_cross_large", (230, 173), 1),
    ("window_reading_seat", (192, 211), 1),
    ("wallitem_chore_chart", (96, 72), 1),
    ("wallitem_notice_a", (34, 43), 1),
    ("wallitem_notice_b", (34, 43), 1),
    ("wallitem_coat_hooks", (115, 106), 1),
    ("wallitem_menu_board", (77, 96), 1),
    ("wallitem_height_marks", (38, 154), 2),
    ("wallitem_utensils", (115, 77), 1),
    ("wallitem_bronze_plaque", (48, 19), 1),
    ("wallitem_wall_clock", (48, 106), 1),
    ("wallitem_day_calendar", (29, 38), 1),
    ("wallitem_bath_rules", (38, 53), 1),
    ("wallitem_wall_lamp", (29, 43), 1),
]

# Meubles (assets/hd2d/interior/props/, panel) : (nom, taille, profondeur de l'emprise au sol en m
# vers le nord depuis l'image, lueur des pixels couleur cristal, priorité). Les panneaux touchent
# le bord bas de leur image (ancre au sol). Au milieu d'une pièce, un meuble de hauteur h a une
# emprise d'au moins (h − 0,25) / 0,78 − 0,35 m (docs/INTERIEURS.md, « Meubler »).
FURNITURE = [
    ("dining_table_long", (384, 106), 1.0, 0.0, 1),
    ("dining_table_set", (384, 115), 1.0, 0.0, 1),
    ("chair_wood", (48, 96), 0.65, 0.0, 1),
    ("chair_wood_back", (48, 96), 0.65, 0.0, 1),
    ("china_cabinet", (154, 211), 0.55, 0.0, 1),
    ("sink_stone", (134, 101), 0.65, 0.0, 1),
    ("crystal_stove", (134, 115), 0.75, 1.4, 1),
    ("kitchen_counter", (192, 101), 0.65, 0.0, 1),
    ("kitchen_table_ingredients", (154, 106), 0.9, 0.0, 1),
    ("water_tub", (96, 86), 0.7, 0.0, 1),
    ("bookshelf_tall", (154, 221), 0.45, 0.0, 1),
    ("bookshelf_low", (134, 86), 0.5, 0.0, 1),
    ("reading_table", (173, 91), 0.9, 1.0, 1),
    ("archive_shelves", (192, 230), 0.55, 0.0, 1),
    ("desk_buried", (134, 125), 1.05, 0.0, 1),
    ("sofa_beige", (192, 86), 0.9, 0.0, 1),
    ("paper_pile_a", (115, 134), 1.15, 0.0, 1),
    ("paper_pile_b", (77, 86), 0.6, 0.0, 1),
    ("paper_pile_c", (58, 48), 0.45, 0.0, 1),
    ("washstand_corridor", (173, 110), 0.6, 0.0, 1),
    ("shoe_rack", (115, 58), 0.4, 0.0, 1),
    ("bath_tub", (230, 96), 1.0, 0.0, 1),
    ("mirror_large", (115, 202), 0.12, 0.0, 1),
    ("towel_shelf", (96, 154), 0.4, 0.0, 1),
    ("wash_tub", (77, 48), 0.5, 0.0, 1),
    ("bed_iron", (192, 101), 1.0, 0.0, 1),
    ("bedside_table", (48, 67), 0.45, 0.0, 1),
    ("medicine_cabinet", (96, 173), 0.4, 0.0, 1),
    ("infirmary_desk", (125, 96), 0.75, 1.0, 1),
    ("chair_child", (43, 77), 0.45, 0.0, 1),
    ("board_games_shelf", (115, 154), 0.4, 0.0, 1),
    ("toy_chest", (96, 77), 0.6, 0.0, 1),
    ("plush_pile", (96, 58), 0.6, 0.0, 1),
    ("plush_blue", (48, 48), 0.4, 0.0, 1),
    ("game_table", (115, 58), 0.6, 0.0, 1),
    ("fireplace", (154, 134), 0.6, 0.0, 1),
    ("tea_table", (86, 77), 0.7, 0.0, 1),
    ("chair_guest", (77, 101), 0.7, 0.0, 1),
    ("desk_nygglatho", (134, 106), 0.8, 0.0, 1),
    ("comm_crystal", (67, 134), 0.4, 0.0, 1),
    ("bed_nygglatho", (202, 106), 1.1, 0.0, 1),
    ("shelf_nygglatho", (115, 173), 0.4, 0.0, 1),
]

# Tapis (assets/hd2d/decals/, decal à bord plein) : (nom, taille, priorité, bord que touche l'image
# livrée : solid_edge du manifeste).
RUGS = [
    ("rug_playroom", (384, 288), 1, ""),
    ("rug_brown", (192, 115), 1, "bottom"),
]

# Remplaçants : images du lot I absentes de la livraison. door_frame_wood (chambranle seul, ouverture
# transparente, pour les portes qu'on franchit) n'est pas encore au cahier n° 3 :
# docs/CONTRACT_REQUESTS.md.
PLACEHOLDERS = [
    "floor_flagstone_cellar",
    "wall_cellar_stone",
    "wallcut_stone",
    "door_frame_wood",
    "door_armory",
    "wallitem_height_marks",
]


def entries():
    """Entrées du manifeste du lot I, dans l'ordre."""
    out = []
    for name, size, kind, prio in SURFACES:
        out.append(_entry("interior/" + name, size, kind, prio))
    for name, size, prio in WALL_PANELS:
        out.append(_entry("interior/" + name, size, "panel", prio))
    for name, size, _depth, _glow, prio in FURNITURE:
        out.append(_entry("interior/props/" + name, size, "panel", prio))
    for name, size, prio, solid in RUGS:
        entry = _entry("decals/" + name, size, "decal", prio)
        if solid:
            entry["solid_edge"] = solid
        out.append(entry)
    return out


def _entry(key, size, kind, prio):
    return {"path": "assets/hd2d/%s.png" % key, "size": list(size), "kind": kind, "prio": prio, "lot": LOT}


# --- Remplaçants : sols et murs de pierre -----------------------------------------------------------


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


# --- Remplaçants : portes et éléments de mur ----------------------------------------------------------


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


def door_frame_wood(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _frame(c, w, h, 10, 10, DARK)
    # Seuil de bois usé entre les deux montants.
    c.rect(10, h - 4, w - 10, h, ramp(HONEY, 4)[1])
    c.rect(10, h - 4, w - 10, h - 3, ramp(HONEY, 4)[3])
    return c.finish(darker(DARK, 0.5))


def door_armory(size, rnd):
    """Porte de la salle des armes, côté couloir : métal gris sombre riveté tout autour, cinq
    serrures alignées, poignée lourde, usure brillante autour des serrures, encadrement de pierre."""
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("#7A7066", 5, spread=0.4)
    # Encadrement de pierre : linteau et deux montants en blocs.
    c.rect(0, 0, w, h, stone[1])
    y = 0
    while y < h:
        bh = rnd.randint(18, 28)
        for x0, x1 in ((0, 11), (w - 11, w)):
            c.rect(x0 + 1, y + 1, x1 - 1, min(h, y + bh) - 1, stone[rnd.choice([2, 3])])
            c.rect(x0 + 1, y + 1, x1 - 1, y + 3, stone[4])
        y += bh
    x = 0
    while x < w:
        bw = rnd.randint(22, 34)
        c.rect(x + 1, 1, min(w, x + bw) - 1, 10, stone[rnd.choice([2, 3])])
        c.rect(x + 1, 1, min(w, x + bw) - 1, 3, stone[4])
        x += bw
    # Battant de métal : plaques, cornières, rivets.
    metal = ramp("#4C5056", 5, spread=0.5)
    x0, x1, y0, y1 = 11, w - 11, 11, h - 3
    c.rect(x0, y0, x1, y1, metal[2])
    plates = [y0, y0 + (y1 - y0) * 0.33, y0 + (y1 - y0) * 0.66, y1]
    for k in range(3):
        c.rect(x0 + 3, plates[k] + 3, x1 - 3, plates[k + 1] - 3, metal[1 + k % 2])
        c.rect(x0 + 3, plates[k] + 3, x1 - 3, plates[k] + 4, metal[3])
    for yy in plates:
        c.rect(x0, yy - 2, x1, yy + 2, metal[0])
        c.rect(x0, yy - 2, x1, yy - 1, metal[3])
    c.rect(x0, y0, x0 + 4, y1, metal[0])
    c.rect(x1 - 4, y0, x1, y1, metal[0])
    rivet = ramp("#8A8E94", 4, spread=0.4)
    for yy in plates:
        for rx in range(x0 + 6, x1 - 4, 9):
            c.rect(rx, yy - 1, rx + 1, yy, rivet[3])
    for rx in (x0 + 2, x1 - 3):
        for ry in range(int(y0) + 6, int(y1) - 4, 10):
            c.rect(rx, ry, rx + 1, ry + 1, rivet[3])
    # Cinq serrures alignées et leur usure brillante.
    lock_x = x1 - 20
    for k in range(5):
        ly = h * 0.3 + k * h * 0.085
        c.ellipse(lock_x + 3, ly + 3, 7, 6, metal[3])
        c.rect(lock_x, ly, lock_x + 7, ly + 7, ramp(BRASS, 4)[1])
        c.rect(lock_x, ly, lock_x + 7, ly + 1, ramp(BRASS, 4)[3])
        c.rect(lock_x + 3, ly + 2, lock_x + 4, ly + 5, metal[0])
    # Poignée lourde.
    iron = ramp(IRON, 4)
    c.rect(x1 - 34, h * 0.52, x1 - 26, h * 0.52 + 26, iron[1])
    c.rect(x1 - 34, h * 0.52, x1 - 32, h * 0.52 + 26, iron[3])
    c.rect(0, h - 3, w, h, stone[0])
    return c.finish(darker("#3A3C40", 0.5))


def wallitem_height_marks(size, rnd):
    """Marques de taille sur le plâtre : traits entre 0,9 et 1,5 m, un signe à côté de chacun."""
    w, h = size
    c = Canvas(w, h, rnd)
    plaster = ramp("#E6DAC2", 4, spread=0.2)
    # Fond transparent : seuls les traits et les signes, posés sur une bande de plâtre éclaircie.
    c.rect(w * 0.3, 0, w * 0.7, h, plaster[2])
    c.rect(w * 0.3, 0, w * 0.34, h, plaster[3])
    colors = ["#B5443A", "#4E7A9A", "#5A8A50", "#C88A3A", "#8A5AA0", "#6C625A"]
    top, bottom = h - 1.5 * PPM, h - 0.9 * PPM
    levels = sorted(rnd.uniform(top, bottom) for _ in range(9))
    levels.append(levels[3] + 2)
    for k, y in enumerate(levels):
        col = colors[k % len(colors)]
        c.rect(w * 0.3, y, w * 0.7, y + 1, col)
        sx = 2 if k % 2 == 0 else w * 0.7 + 2
        sign = k % 4
        if sign == 0:
            c.rect(sx + 2, y - 4, sx + 3, y + 3, col)
            c.rect(sx, y - 1, sx + 5, y, col)
        elif sign == 1:
            c.ellipse(sx + 3, y - 1, 2, 2, col)
        elif sign == 2:
            c.poly([(sx, y - 3), (sx + 6, y - 3), (sx + 3, y + 2)], col)
        else:
            c.line([(sx, y + 3), (sx + 6, y - 4)], col)
    c.rect(w * 0.3, h - 3, w * 0.7, h, darker("#E6DAC2", 0.7))
    return c.finish(darker(HONEY, 0.45))


RECIPES = {"interior/" + _name: globals()[_name] for _name in PLACEHOLDERS}


# --- Manifeste et scènes ------------------------------------------------------------------------------


def cmd_manifest():
    """Remplace les entrées du lot I du manifeste par celles d'entries(), à la fin de la liste des
    images (une par ligne)."""
    with open(MANIFEST, encoding="utf-8") as handle:
        text = handle.read()
    marker = "\n ],\n \"sheets\""
    head, tail = text[:text.index(marker)], text[text.index(marker):]
    lines = head.split("\n")
    kept = [line for line in lines if '"lot": "%s"' % LOT not in line]
    if kept[-1].endswith(","):
        kept[-1] = kept[-1][:-1]
    new = "\n".join(kept) + "".join(",\n  " + json.dumps(e, ensure_ascii=False) for e in entries()) + tail
    json.loads(new)
    if new == text:
        print("manifeste à jour (%d images du lot %s)" % (len(entries()), LOT))
        return 0
    with open(MANIFEST, "w", encoding="utf-8") as handle:
        handle.write(new)
    print("manifeste : %d images du lot %s (%d entrée(s) retirée(s))"
          % (len(entries()), LOT, len(lines) - len(kept)))
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
    if depth < WALL_MOUNTED:
        lines.append("cut_height = %s" % _num(WALL_CUT_HEIGHT))
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
        '[ext_resource type="Texture2D" path="res://assets/hd2d/decals/%s.png" id="2_image"]' % name,
        "",
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_decal")',
        'texture = ExtResource("2_image")',
        "follow_ground = false",
        "",
    ])


def cmd_scenes(force=False):
    written = 0
    for name, size, depth, glow_amount, _prio in FURNITURE:
        written += _write(name, furniture_scene(name, size, depth, glow_amount), force)
    for name, _size, _prio, _solid in RUGS:
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
