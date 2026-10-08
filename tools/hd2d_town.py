"""Recettes HD-2D du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md) : flancs des bâtiments (9.1),
nouvelles maisons du bourg et du port, façade et flanc (9.2), détails de toits et de murs (9.4),
objets de la vie (10).

Les flancs (`<nom>_side.png`) reprennent la matière du volume (assets/hd2d/buildings/materials/,
celle que le jeu plaque sur les murs) et les fenêtres de la façade livrée (découpées dans
`<nom>.png`) ; modelé doux et symétrique, rien qui ne supporte d'être retourné. Les objets sont des
panneaux debout, collés au bord bas, lumière de gauche."""

import math
import random

from PIL import Image, ImageDraw

from hd2d_art import Canvas, WrapCanvas, asset, darker, mix, ramp, seed_for, tile_fill
from hd2d_props import boards, crate, door, glow, post, rock_shape, window

WOOD = "wood"
DARK = "wood_dark"
IRON = "iron"
COPPER = "#B0703A"


# --- Matières et morceaux de façades livrées -------------------------------------------------------


def material(name, size):
    """Matière du volume répétée sur size : l'image livrée, sinon son remplaçant."""
    tile = asset("buildings/materials/" + name)
    if tile is None:
        import hd2d_ground
        tile = hd2d_ground.RECIPES["buildings/materials/" + name]((192, 192), random.Random(seed_for("buildings/materials/" + name)))
    return tile_fill(size, tile)


def facade_piece(name, box):
    """Morceau d'une façade livrée (fenêtre, lucarne), ou None si l'image manque."""
    img = asset("buildings/" + name)
    if img is None or box[2] > img.width or box[3] > img.height:
        return None
    return img.crop(box)


def paste_piece(c, piece, cx, bottom):
    if piece is not None:
        c.img.alpha_composite(piece, (int(cx - piece.width / 2), int(bottom - piece.height)))


def wall_area(c, mask_pts, name):
    """Remplit le polygone mask_pts avec la matière name."""
    mask = Image.new("L", (c.w, c.h), 0)
    ImageDraw.Draw(mask).polygon([(round(x), round(y)) for x, y in mask_pts], fill=255)
    c.img.paste(material(name, (c.w, c.h)), (0, 0), mask)
    return mask


def roof_edge(c, p0, p1, roof, thick=16):
    """Bordure du toit vue de côté : bande de la matière du toit sur une planche de rive."""
    tones = ramp(DARK, 5)
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    n = math.hypot(dx, dy) or 1.0
    nx, ny = dy / n, -dx / n
    if ny < 0:
        nx, ny = -nx, -ny
    band = [p0, p1, (p1[0] + nx * thick, p1[1] + ny * thick), (p0[0] + nx * thick, p0[1] + ny * thick)]
    mask = Image.new("L", (c.w, c.h), 0)
    ImageDraw.Draw(mask).polygon([(round(x), round(y)) for x, y in band], fill=255)
    c.img.paste(material(roof, (c.w, c.h)), (0, 0), mask)
    c.line([p0, p1], tones[2], 4)
    c.line([(p0[0] + nx * thick, p0[1] + ny * thick), (p1[0] + nx * thick, p1[1] + ny * thick)], tones[0], 3)


def soft_shade(c, mask):
    """Modelé doux et symétrique : bords et pied du mur un peu plus sombres."""
    w, h = c.w, c.h
    shade = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(shade)
    for k, (dist, val) in enumerate(((10, 30), (5, 45), (2, 60))):
        sd.rectangle((0, 0, dist, h), fill=val)
        sd.rectangle((w - 1 - dist, 0, w, h), fill=val)
        sd.rectangle((0, h - 1 - dist, w, h), fill=val)
    from PIL import ImageChops
    c.img.paste(Image.new("RGBA", (w, h), (40, 30, 50, 255)), (0, 0), ImageChops.multiply(shade, mask))


def building_side(size, rnd, wall, roof, gable_wall_m=None, plinth=0, plinth_mat="wall_stone", features=None):
    """Flanc est : mur (pignon jusqu'au faîtage, ou gouttereau jusqu'à l'égout), bordure du toit,
    soubassement, puis les détails (features(c, w, h, wall_top))."""
    w, h = size
    c = Canvas(w, h, rnd)
    if gable_wall_m is not None:
        wall_top = h - round(gable_wall_m * 96)
        pts = [(0, h), (0, wall_top), (w / 2.0, 0), (w, wall_top), (w, h)]
    else:
        wall_top = 14
        pts = [(0, h), (0, 0), (w, 0), (w, h)]
    mask = wall_area(c, pts, wall)
    if plinth:
        pm = Image.new("L", (w, h), 0)
        ImageDraw.Draw(pm).rectangle((0, h - plinth, w, h), fill=255)
        c.img.paste(material(plinth_mat, size), (0, 0), pm)
        c.rect(0, h - plinth, w, h - plinth + 3, ramp("stone", 4)[3])
    if features:
        features(c, w, h, wall_top)
    if gable_wall_m is not None:
        roof_edge(c, (0, wall_top + 2), (w / 2.0, 0), roof)
        roof_edge(c, (w, wall_top + 2), (w / 2.0, 0), roof)
    else:
        mt = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mt).rectangle((0, 0, w, 12), fill=255)
        c.img.paste(material(roof, size), (0, 0), mt)
        c.rect(0, 10, w, 14, ramp(DARK, 4)[0])
    soft_shade(c, mask)
    img = c.img
    img.putalpha(mask)
    return img


def ladder(c, x, y0, y1, width=34):
    wood = ramp(WOOD, 5)
    c.rect(x, y0, x + 5, y1, wood[2])
    c.rect(x + width, y0, x + width + 5, y1, wood[2])
    y = y1 - 12
    while y > y0 + 6:
        c.rect(x + 2, y, x + width + 3, y + 4, wood[3])
        c.rect(x + 2, y + 3, x + width + 3, y + 4, wood[0])
        y -= 30


def log_pile(c, x0, x1, y_base, rows=3, r=10):
    wood = ramp("#8A6A4A", 5)
    end = ramp("#C8A070", 4)
    for row in range(rows):
        y = y_base - r - row * r * 1.7
        x = x0 + r + (row % 2) * r
        while x < x1 - r - row * r:
            c.ellipse(x, y, r, r * 0.95, wood[1])
            c.ellipse(x, y, r - 2, r * 0.95 - 2, end[2])
            c.ellipse(x - 1, y - 1, r * 0.45, r * 0.4, end[1])
            x += 2 * r + 1


def ivy(c, rnd, x0, x1, y0, y1, count, colors=("#4F6B3A", "#3E5A34", "#A85A3A")):
    for _ in range(count):
        x = rnd.uniform(x0, x1)
        y = rnd.uniform(y0, y1)
        c.blob(x, y, rnd.uniform(4, 7), rnd.uniform(3, 5), ramp(rnd.choice(colors), 4))


def shutters_closed(c, x, y, w, h, color):
    wood = ramp(DARK, 4)
    c.rect(x - 4, y - 4, x + w + 4, y + h + 6, wood[1])
    boards(c, x, y, x + w / 2.0, y + h, color, width=6)
    boards(c, x + w / 2.0, y, x + w, y + h, color, width=6)
    c.rect(x + w / 2.0 - 1, y, x + w / 2.0 + 1, y + h, wood[0])
    for yy in (y + h * 0.2, y + h * 0.75):
        c.rect(x + 2, yy, x + w - 2, yy + 3, ramp(IRON, 4)[0])


# --- 9.1 Flancs des bâtiments existants ------------------------------------------------------------


def warehouse_main_side(size, rnd):
    def features(c, w, h, top):
        win = facade_piece("warehouse_main", (150, 80, 250, 232))
        low = facade_piece("warehouse_main", (125, 335, 237, 500))
        for x in (0.25, 0.75):
            paste_piece(c, win, w * x, top + 210)
            paste_piece(c, low, w * x, h - 110)
        paste_piece(c, facade_piece("warehouse_wing", (245, 105, 332, 192)), w / 2.0, top - 40)
        ladder(c, w * 0.46, top + 30, h, 40)
    return building_side(size, rnd, "wall_planks", "roof_slate", gable_wall_m=6.5, plinth=110, features=features)


def warehouse_wing_side(size, rnd):
    def features(c, w, h, top):
        bay = facade_piece("warehouse_main", (1236, 322, 1484, 528))
        paste_piece(c, bay, w * 0.6, h - 60)
        door(c, w * 0.06, h - 170, 72, 170)
    return building_side(size, rnd, "wall_planks", "roof_slate", plinth=60, features=features)


def cafe_side(size, rnd):
    def features(c, w, h, top):
        stone = Image.new("L", (w, h), 0)
        ImageDraw.Draw(stone).rectangle((0, h - 250, w, h), fill=255)
        c.img.paste(material("wall_stone", (w, h)), (0, 0), stone)
        beam = ramp(DARK, 5)
        c.rect(0, h - 256, w, h - 246, beam[1])
        for x in (8, w / 2.0 - 5, w - 18):
            c.rect(x, top, x + 10, h - 250, beam[1])
        c.line([(18, top + 10), (w / 2.0 - 6, h - 256)], beam[1], 8)
        c.line([(w - 18, top + 10), (w / 2.0 + 6, h - 256)], beam[1], 8)
        win = facade_piece("cafe", (108, 26, 290, 195))
        paste_piece(c, win, w / 2.0, h - 290)
        paste_piece(c, win, w / 2.0, h - 40)
        paste_piece(c, facade_piece("shop_bakery", (182, 148, 300, 248)), w / 2.0, top - 30)
    return building_side(size, rnd, "wall_plaster", "roof_tiles", gable_wall_m=5.5, features=features)


def shop_bakery_side(size, rnd):
    def features(c, w, h, top):
        paste_piece(c, facade_piece("shop_bakery", (182, 148, 300, 248)), w * 0.35, h - 150)
        dark = ramp("stone_dark", 4)
        c.ellipse(w * 0.75, h - 46, 30, 22, dark[0])
        c.rect(w * 0.75 - 30, h - 46, w * 0.75 + 30, h - 20, dark[0])
        c.ellipse(w * 0.75, h - 36, 20, 12, "#C8602A")
        c.ellipse(w * 0.75, h - 34, 12, 7, "#F0A040")
        log_pile(c, w * 0.04, w * 0.5, h, rows=3, r=11)
    return building_side(size, rnd, "wall_stone", "roof_tiles", features=features)


def shop_bookshop_side(size, rnd):
    def features(c, w, h, top):
        green = Image.new("L", (w, h), 0)
        ImageDraw.Draw(green).rectangle((0, 0, w, h), fill=255)
        from hd2d_art import recolor
        plaster = recolor(material("wall_plaster", (w, h)), "#3E5A4A", keep=0.15)
        c.img.paste(plaster, (0, 0), green)
        for _ in range(9):
            x, y = rnd.uniform(10, w - 40), rnd.uniform(top + 10, h - 40)
            chip = material("wall_stone", (int(rnd.uniform(16, 36)), int(rnd.uniform(10, 20))))
            c.img.paste(chip, (int(x), int(y)))
        paste_piece(c, facade_piece("shop_bookshop", (165, 148, 320, 252)), w / 2.0, h - 170)
        ivy(c, rnd, 0, w * 0.25, top, h, 90)
        ivy(c, rnd, w * 0.75, w, top + 40, h, 60)
    return building_side(size, rnd, "wall_plaster", "roof_tiles", plinth=30, features=features)


def stone_house_side(size, rnd):
    def features(c, w, h, top):
        paste_piece(c, facade_piece("stone_house", (196, 145, 292, 235)), w / 2.0, h - 130)
        stone = ramp("stone", 5)
        c.rect(w * 0.18, h - 44, w * 0.82, h - 32, stone[3])
        c.rect(w * 0.18, h - 33, w * 0.82, h - 30, stone[1])
        for x in (0.22, 0.75):
            c.rect(w * x, h - 30, w * x + 18, h, stone[2])
    return building_side(size, rnd, "wall_stone", "roof_tiles", features=features)


def projection_hall_side(size, rnd):
    def features(c, w, h, top):
        win = facade_piece("projection_hall", (58, 68, 162, 252))
        for x in (0.25, 0.75):
            paste_piece(c, win, w * x, top + 250)
        door(c, w * 0.42, h - 190, 96, 190)
        paper = ramp("#D8C8A0", 4)
        for k, (x, y) in enumerate(((0.12, 0.72), (0.2, 0.76), (0.72, 0.7))):
            c.poly([(w * x, h * y), (w * x + 52, h * y + 4), (w * x + 48, h * y + 70), (w * x + 6, h * y + 64)], paper[1 + k % 2])
            for ly in range(10, 56, 9):
                c.rect(w * x + 10, h * y + ly, w * x + 40 - (ly % 3) * 4, h * y + ly + 2, paper[0])
        paste_piece(c, facade_piece("warehouse_wing", (245, 105, 332, 192)), w / 2.0, top - 30)
    return building_side(size, rnd, "wall_stone", "roof_slate", gable_wall_m=6.0, plinth=40, features=features)


def limashenka_house_side(size, rnd):
    def features(c, w, h, top):
        paste_piece(c, facade_piece("limashenka_house", (128, 188, 238, 318)), w / 2.0, h - 120)
        ivy(c, rnd, 0, w, top + 10, h, 260, ("#4F6B3A", "#3E5A34", "#A85A3A", "#C8823A"))
    return building_side(size, rnd, "wall_plaster", "roof_tiles", plinth=30, features=features)


def tool_shed_side(size, rnd):
    def features(c, w, h, top):
        tools = ramp(WOOD, 4)
        iron = ramp(IRON, 4)
        c.rect(w * 0.1, top + 20, w * 0.9, top + 26, tools[1])
        c.line([(w * 0.2, top + 24), (w * 0.2, h - 30)], tools[2], 4)
        c.rect(w * 0.12, h - 36, w * 0.28, h - 28, iron[1])
        for k in range(5):
            c.rect(w * 0.12 + k * 7, h - 30, w * 0.12 + k * 7 + 2, h - 22, iron[0])
        c.poly([(w * 0.42, top + 30), (w * 0.62, top + 30), (w * 0.62, top + 44), (w * 0.46, top + 66)], iron[2])
        c.rect(w * 0.6, top + 26, w * 0.66, top + 34, tools[1])
        c.line([(w * 0.8, top + 24), (w * 0.8, h - 40)], tools[2], 4)
        c.poly([(w * 0.74, h - 40), (w * 0.86, h - 40), (w * 0.84, h - 14), (w * 0.76, h - 14)], iron[2])
        c.ellipse(w * 0.48, h - 70, 16, 16, iron[0])
        c.ellipse(w * 0.48, h - 70, 12, 12, "#3A2E2A")
    return building_side(size, rnd, "wall_planks", "roof_tin", gable_wall_m=2.25, plinth=24, features=features)


# --- 9.2 Nouvelles maisons : façade et flanc -------------------------------------------------------


def new_facade(size, rnd, wall, roof, kind, wall_m, plinth=0, plinth_mat="wall_stone", features=None, timber=False):
    """Façade sud : long (jusqu'à l'égout, bordure du toit en haut) ou pignon (triangle jusqu'au
    faîtage, bordures du toit sur les rampants), soubassement, puis les détails."""
    w, h = size
    c = Canvas(w, h, rnd)
    wall_px = round(wall_m * 96)
    if kind == "long":
        pts = [(0, h), (0, 0), (w, 0), (w, h)]
        top = 16
    else:
        top = h - wall_px
        pts = [(0, h), (0, top), (w / 2.0, 0), (w, top), (w, h)]
    mask = wall_area(c, pts, wall)
    if timber:
        beam = ramp(DARK, 5)
        for y in (top + 4, h - plinth - 8 if plinth else h - 8, top + (h - top) * 0.48):
            c.rect(0, y, w, y + 9, beam[1])
            c.rect(0, y, w, y + 2, beam[3])
        for k in range(5):
            x = w * k / 4.0 - (0 if k < 4 else 10)
            c.rect(x, top, x + 10, h, beam[1])
        for k in range(4):
            x0 = w * k / 4.0 + 10
            c.line([(x0, top + (h - top) * 0.48 + 9), (x0 + w / 4.0 - 14, h - (plinth or 0) - 8)], beam[1], 7)
    if plinth:
        pm = Image.new("L", (w, h), 0)
        ImageDraw.Draw(pm).rectangle((0, h - plinth, w, h), fill=255)
        c.img.paste(material(plinth_mat, size), (0, 0), pm)
        c.rect(0, h - plinth, w, h - plinth + 3, ramp("stone", 4)[3])
    if features:
        features(c, w, h, top)
    if kind == "long":
        mt = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mt).rectangle((0, 0, w, 14), fill=255)
        c.img.paste(material(roof, size), (0, 0), mt)
        c.rect(0, 12, w, 16, ramp(DARK, 4)[0])
    else:
        roof_edge(c, (0, top + 2), (w / 2.0, 0), roof, 18)
        roof_edge(c, (w, top + 2), (w / 2.0, 0), roof, 18)
    shade = Image.new("RGBA", (w, 6), (30, 24, 36, 70))
    c.img.alpha_composite(shade, (0, h - 6))
    img = c.img
    img.putalpha(mask)
    return img


def sign_shape(c, x, y, shape, rnd):
    """Enseigne de fer forgé en forme d'objet (sans texte), pendue à une potence."""
    iron = ramp(IRON, 4)
    c.rect(x - 30, y - 4, x + 6, y, iron[0])
    c.line([(x - 26, y), (x - 6, y - 14)], iron[1], 2)
    c.rect(x - 2, y, x, y + 10, iron[0])
    cx, cy = x - 1, y + 28
    if shape == "clock":
        c.ellipse(cx, cy, 18, 18, ramp("brass", 4)[2])
        c.ellipse(cx, cy, 13, 13, "#F0E8D0")
        for k in range(12):
            a = k / 12.0 * 2 * math.pi
            c.pixel(cx + math.cos(a) * 10, cy + math.sin(a) * 10, "#4A3A2E")
    elif shape == "ham":
        c.blob(cx, cy, 16, 11, ramp("#B05A4A", 4))
        c.rect(cx + 12, cy - 3, cx + 22, cy + 3, "#F0E8D0")
    elif shape == "mug":
        c.rect(cx - 12, cy - 14, cx + 10, cy + 14, ramp("#C8A060", 4)[2])
        c.rect(cx - 12, cy - 18, cx + 10, cy - 12, "#F2EEE0")
        c.ellipse(cx + 14, cy, 6, 8, ramp("#C8A060", 4)[1])
    elif shape == "propeller":
        for k in range(3):
            a = k / 3.0 * 2 * math.pi
            c.poly([(cx, cy), (cx + math.cos(a - 0.3) * 18, cy + math.sin(a - 0.3) * 18),
                    (cx + math.cos(a + 0.2) * 20, cy + math.sin(a + 0.2) * 20)], ramp(COPPER, 4)[2])
        c.ellipse(cx, cy, 4, 4, iron[2])


def house_timber_a(size, rnd):
    def features(c, w, h, top):
        door(c, w * 0.42, h - 200, 90, 200, base="#4A6A8A")
        window(c, w * 0.1, h - 180, 60, 70, shutters="#5A7A5A")
        window(c, w * 0.74, h - 180, 60, 70, shutters="#5A7A5A")
        c.rect(0, top - 6, w, top + 4, ramp(DARK, 4)[0])
        window(c, w * 0.18, top + 60, 56, 64)
        window(c, w * 0.66, top + 60, 56, 64)
    return new_facade(size, rnd, "wall_plaster", "roof_tiles", "pignon", 3.5, plinth=110, timber=True, features=features)


def house_timber_a_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 150, 56, 64)
    return building_side(size, rnd, "wall_plaster", "roof_tiles", plinth=110, features=features)


def house_timber_b(size, rnd):
    def features(c, w, h, top):
        for k in range(3):
            window(c, w * (0.12 + 0.3 * k), top + 50, 64, 72, shutters="#6A4A3A")
        cloth = ramp("#F2EEE6", 4)
        c.poly([(w * 0.42 + 70, top + 70), (w * 0.42 + 112, top + 70), (w * 0.42 + 106, top + 140), (w * 0.42 + 76, top + 132)], cloth[2])
        door(c, w * 0.12, h - 210, 90, 210)
        shutters_closed(c, w * 0.5, h - 200, 200, 130, "#6A5A4A")
    return new_facade(size, rnd, "wall_plaster_b", "roof_tiles_b", "long", 5.5, plinth=40, timber=True, features=features)


def house_timber_b_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 360, 64, 72)
        window(c, w * 0.42, h - 160, 64, 72)
    return building_side(size, rnd, "wall_plaster_b", "roof_tiles_b", gable_wall_m=5.5, plinth=40, features=features)


def clockmaker(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.06, h - 230, 230, 150)
        brass = ramp("brass", 4)
        for _ in range(14):
            x, y = w * 0.06 + rnd.uniform(10, 220), h - 230 + rnd.uniform(14, 140)
            r = rnd.uniform(6, 14)
            c.ellipse(x, y, r, r, brass[rnd.randint(1, 3)])
            c.ellipse(x, y, r * 0.5, r * 0.5, brass[0])
        door(c, w * 0.66, h - 230, 100, 230)
        c.rect(w * 0.66 + 14, h - 210, w * 0.66 + 86, h - 120, ramp("crystal", 4)[2])
        window(c, w * 0.5 - 40, top + 40, 80, 80)
        sign_shape(c, w * 0.6, h - 280, "clock", rnd)
    return new_facade(size, rnd, "wall_stone", "roof_slate", "pignon", 4.0, plinth=30, features=features)


def clockmaker_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 170, 64, 80)
    return building_side(size, rnd, "wall_stone", "roof_slate", plinth=30, features=features)


def house_narrow(size, rnd):
    def features(c, w, h, top):
        door(c, w * 0.36, h - 210, 100, 210)
        iron = ramp(IRON, 4)
        for k, y in enumerate((h - 400, top + 70)):
            window(c, w * 0.5 - 36, y, 72, 90)
            if k == 0:
                c.rect(w * 0.2, y + 104, w * 0.8, y + 110, iron[1])
                for x in range(int(w * 0.2), int(w * 0.8), 10):
                    c.rect(x, y + 80, x + 2, y + 106, iron[0])
                c.rect(w * 0.2, y + 78, w * 0.8, y + 82, iron[2])
                for x in (0.28, 0.66):
                    c.rect(w * x, y + 86, w * x + 22, y + 104, ramp("#B8603A", 4)[2])
                    c.blob(w * x + 11, y + 80, 14, 10, ramp("#C8503A", 4))
    return new_facade(size, rnd, "wall_stone_b", "roof_slate", "pignon", 6.0, plinth=30, features=features)


def house_narrow_side(size, rnd):
    def features(c, w, h, top):
        for y in (h - 180, h - 380):
            window(c, w * 0.44, y, 60, 76)
    return building_side(size, rnd, "wall_stone_b", "roof_slate", plinth=30, features=features)


def butcher(size, rnd):
    def features(c, w, h, top):
        shutters_closed(c, w * 0.08, h - 170, 260, 110, "#7A5A4A")
        door(c, w * 0.66, h - 220, 96, 220)
        for k in range(12):
            x = w * k / 12.0
            c.poly([(x, top + 30), (x + w / 12.0, top + 30), (x + w / 12.0, top + 70), (x + w / 24.0, top + 80), (x, top + 70)],
                   "#B5443A" if k % 2 else "#F2EEE0")
        c.rect(0, top + 26, w, top + 32, ramp(DARK, 4)[0])
        sign_shape(c, w * 0.62, top + 100, "ham", rnd)
    return new_facade(size, rnd, "wall_brick", "roof_tiles", "long", 3.5, plinth=24, features=features)


def butcher_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 170, 60, 70, shutters="#7A5A4A")
    return building_side(size, rnd, "wall_brick", "roof_tiles", gable_wall_m=3.5, plinth=24, features=features)


def inn(size, rnd):
    def features(c, w, h, top):
        for k in range(4):
            window(c, w * (0.08 + 0.24 * k), top + 40, 64, 76, shutters="#6A4A3A")
        boards(c, w * 0.04, h * 0.5, w * 0.96, h * 0.53, WOOD, vertical=False, width=8)
        for x in range(int(w * 0.05), int(w * 0.95), 14):
            c.rect(x, h * 0.42, x + 4, h * 0.5, ramp(WOOD, 4)[2])
        c.rect(w * 0.04, h * 0.41, w * 0.96, h * 0.43, ramp(WOOD, 4)[3])
        door(c, w * 0.5 - 70, h - 220, 140, 220, double=True)
        for k in range(2):
            window(c, w * (0.1 + 0.62 * k), h - 190, 120, 90)
        for x in (0.36, 0.64):
            c.rect(w * x - 2, h - 200, w * x + 2, h - 160, ramp(IRON, 4)[0])
            glow(c, w * x, h - 214, 9)
        sign_shape(c, w * 0.5 + 100, h - 260, "mug", rnd)
    return new_facade(size, rnd, "wall_plaster", "roof_shingles", "long", 6.0, plinth=30, timber=True, features=features)


def inn_side(size, rnd):
    def features(c, w, h, top):
        for x in (0.25, 0.65):
            window(c, w * x, h - 400, 60, 76)
            window(c, w * x, h - 170, 60, 76)
    return building_side(size, rnd, "wall_plaster", "roof_shingles", gable_wall_m=6.0, plinth=30, features=features)


def harbor_office(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.08, h - 200, 150, 110)
        iron = ramp(IRON, 4)
        for x in range(int(w * 0.08), int(w * 0.08 + 150), 12):
            c.rect(x, h - 200, x + 2, h - 90, iron[0])
        door(c, w * 0.62, h - 220, 96, 220)
        c.ellipse(w * 0.5, top + 70, 26, 26, ramp("brass", 4)[2])
        c.ellipse(w * 0.5, top + 70, 20, 20, "#F0E8D0")
        c.rect(w * 0.5 - 1, top + 56, w * 0.5 + 1, top + 70, "#3A2E2A")
        c.rect(w * 0.5, top + 69, w * 0.5 + 12, top + 71, "#3A2E2A")
        for k in range(3):
            a = k / 3.0 * 2 * math.pi
            c.poly([(w * 0.5, 14), (w * 0.5 + math.cos(a - 0.3) * 14, 14 + math.sin(a - 0.3) * 8),
                    (w * 0.5 + math.cos(a + 0.2) * 14, 14 + math.sin(a + 0.2) * 8)], ramp(COPPER, 4)[2])
    return new_facade(size, rnd, "wall_stone", "roof_tin", "pignon", 4.0, plinth=30, features=features)


def harbor_office_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.4, h - 170, 70, 80)
    return building_side(size, rnd, "wall_stone", "roof_tin", plinth=30, features=features)


def port_hangar(size, rnd):
    def features(c, w, h, top):
        iron = ramp(IRON, 5)
        for x in range(0, w, 160):
            c.rect(x, top, x + 10, h, iron[1])
            c.rect(x, top, x + 3, h, iron[3])
        c.rect(w * 0.3, h - 330, w * 0.7, h, "#1E1A20")
        boards(c, w * 0.3, h - 330, w * 0.45, h, "#7A848C", width=16)
        for k in range(3):
            small = crate((70, 60), rnd)
            c.img.alpha_composite(small, (int(w * 0.48 + k * 66), h - 60 - (k % 2) * 6))
        c.rect(w * 0.28, h - 340, w * 0.72, h - 330, iron[0])
        window(c, w * 0.08, h - 300, 90, 60)
        window(c, w * 0.82, h - 300, 90, 60)
    return new_facade(size, rnd, "wall_tin", "roof_tin_b", "long", 5.0, features=features)


def port_hangar_side(size, rnd):
    def features(c, w, h, top):
        iron = ramp(IRON, 5)
        for x in range(0, w, 128):
            c.rect(x, top, x + 8, h, iron[1])
        door(c, w * 0.44, h - 200, 90, 200, base=IRON, metal=True)
    return building_side(size, rnd, "wall_tin", "roof_tin_b", gable_wall_m=5.0, features=features)


def boiler_workshop(size, rnd):
    def features(c, w, h, top):
        door(c, w * 0.08, h - 260, 150, 260, base=IRON, metal=True, double=True)
        window(c, w * 0.7, h - 230, 100, 90)
        c.rect(w * 0.7, h - 230, w * 0.7 + 100, h - 140, "#E07A30")
        c.rect(w * 0.7 + 10, h - 220, w * 0.7 + 50, h - 190, "#F4B060")
        copper = ramp(COPPER, 5)
        c.cylinder(w * 0.42, h - 120, w * 0.66, h, copper)
        for y in range(int(h - 116), int(h), 12):
            for x in (w * 0.44, w * 0.64):
                c.rect(x, y, x + 3, y + 3, copper[0])
        c.rect(w * 0.46, h - 80, w * 0.62, h - 60, "#C8502A")
        pipe = ramp(COPPER, 4)
        c.line([(w * 0.66, h - 100), (w * 0.95, h - 100), (w * 0.95, top + 40)], pipe[2], 8)
        c.rect(0, top - 2, w, top + 4, ramp("#4A3A30", 4)[0])
        window(c, w * 0.5 - 30, top + 40, 60, 60)
    return new_facade(size, rnd, "wall_brick", "roof_tin", "pignon", 4.0, plinth=20, features=features)


def boiler_workshop_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 180, 70, 70)
        c.rect(w * 0.42, h - 180, w * 0.42 + 70, h - 110, "#D06A2A")
    return building_side(size, rnd, "wall_brick", "roof_tin", plinth=20, features=features)


def house_stone_b(size, rnd):
    def features(c, w, h, top):
        door(c, w * 0.4, h - 200, 90, 200, base="#9A4A3A")
        window(c, w * 0.1, h - 180, 56, 64)
        window(c, w * 0.76, h - 180, 56, 64)
        stone = ramp("stone", 4)
        c.rect(w * 0.68, h - 40, w * 0.94, h - 30, stone[3])
        for x in (0.7, 0.88):
            c.rect(w * x, h - 30, w * x + 12, h, stone[2])
        window(c, w * 0.5 - 28, top + 40, 56, 56)
    return new_facade(size, rnd, "wall_stone_b", "roof_shingles", "pignon", 3.25, features=features)


def house_stone_b_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.44, h - 160, 52, 60)
    return building_side(size, rnd, "wall_stone_b", "roof_shingles", features=features)


# --- 9.4 Détails de toits et de murs --------------------------------------------------------------


def chimney(size, rnd, kind="brick"):
    w, h = size
    c = Canvas(w, h, rnd)
    if kind == "brick":
        body = material("wall_brick", size)
        mask = Image.new("L", size, 0)
        ImageDraw.Draw(mask).polygon([(w * 0.18, h * 0.18), (w * 0.82, h * 0.18), (w * 0.82, h), (w * 0.18, h)], fill=255)
        c.img.paste(body, (0, 0), mask)
        iron = ramp(IRON, 4)
        c.poly([(w * 0.08, h * 0.12), (w * 0.5, 0), (w * 0.92, h * 0.12)], iron[2])
        for x in (0.22, 0.74):
            c.rect(w * x, h * 0.1, w * x + 4, h * 0.2, iron[0])
        c.rect(w * 0.18, h * 0.18, w * 0.82, h * 0.3, "#2A2226")
    else:
        stone = material("wall_stone", size)
        mask = Image.new("L", size, 0)
        ImageDraw.Draw(mask).rectangle((w * 0.12, h * 0.2, w * 0.88, h), fill=255)
        c.img.paste(stone, (0, 0), mask)
        pot = ramp("#B8603A", 4)
        for x in (0.32, 0.66):
            c.cylinder(w * x - 9, h * 0.04, w * x + 9, h * 0.22, pot)
        c.rect(w * 0.08, h * 0.18, w * 0.92, h * 0.22, ramp("stone", 4)[3])
    c.rect(w * 0.18, h - 6, w * 0.82, h, "#2E2630")
    return c.finish(darker("#5A4A42", 0.5))


def dormer(size, rnd, roof):
    w, h = size
    c = Canvas(w, h, rnd)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon([(w * 0.14, h), (w * 0.14, h * 0.42), (w * 0.86, h * 0.42), (w * 0.86, h)], fill=255)
    c.img.paste(material("wall_plaster", size), (0, 0), mask)
    window(c, w * 0.32, h * 0.5, w * 0.36, h * 0.4, shutters=None if roof == "roof_slate" else "#5A7A5A")
    rm = Image.new("L", size, 0)
    ImageDraw.Draw(rm).polygon([(0, h * 0.48), (w * 0.5, 0), (w, h * 0.48), (w * 0.86, h * 0.48), (w * 0.5, h * 0.12),
                                (w * 0.14, h * 0.48)], fill=255)
    c.img.paste(material(roof, size), (0, 0), rm)
    c.line([(0, h * 0.48), (w * 0.5, 0), (w, h * 0.48)], ramp(DARK, 4)[1], 3)
    return c.finish(darker("#4A3A30", 0.5))


def ivy_wall(size, rnd, hanging=False):
    w, h = size
    c = Canvas(w, h, rnd)
    stem = ramp("#5A4A30", 3)
    leaves = [ramp(col, 4) for col in ("#4F6B3A", "#3E5A34", "#A84A2E", "#C8603A")]
    if hanging:
        c.line([(0, 6), (w, 8)], stem[1], 3)
        for k in range(30):
            x = rnd.uniform(4, w - 4)
            length = rnd.uniform(h * 0.3, h * 0.98)
            for s in range(int(length / 8)):
                y = 6 + s * 8
                c.blob(x + math.sin(s * 0.8 + k) * 4, min(h - 4, y), rnd.uniform(4, 6), rnd.uniform(3, 5), rnd.choice(leaves))
        c.blob(w * 0.5, h - 4, 5, 4, leaves[0])
    else:
        for k in range(5):
            x = w * (0.2 + 0.15 * k)
            pts = [(x + math.sin(y / 30.0 + k) * 12, y) for y in range(h, -1, -12)]
            c.line(pts, stem[1], 2)
            for px, py in pts:
                for _ in range(3):
                    c.blob(px + rnd.uniform(-14, 14), py + rnd.uniform(-6, 6), rnd.uniform(4, 6), rnd.uniform(3, 5),
                           rnd.choice(leaves))
    return c.finish(darker("#3E5A34", 0.5))


def roof_deck(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4)
    c.rect(0, h - 26, w, h - 22, iron[2])
    for x in range(0, w, 24):
        c.rect(x, h - 26, x + 3, h, iron[1])
    c.rect(0, h - 4, w, h, iron[0])
    for x in (8, w - 12):
        post(c, x, 6, h, 6, WOOD)
    cloth = ramp("#F2EEE6", 4)
    rope = ramp("#C9B48A", 3)
    for k, y in enumerate((14, 30)):
        c.line([(8, y), (w / 2.0, y + 8), (w - 8, y)], rope[1], 2)
    for k in range(3):
        x0 = w * (0.12 + 0.28 * k)
        c.poly([(x0, 18 + k), (x0 + w * 0.2, 20 + k), (x0 + w * 0.2 - 4, h * 0.72), (x0 + 6, h * 0.7)], cloth[2])
        c.poly([(x0, 18 + k), (x0 + w * 0.06, 19 + k), (x0 + 10, h * 0.7), (x0 + 6, h * 0.7)], cloth[3])
    return c.finish(darker("#4A4448", 0.5))


def wall_lantern(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4)
    c.rect(w * 0.42, h * 0.4, w * 0.58, h, iron[1])
    c.line([(w * 0.5, h * 0.75), (w * 0.85, h * 0.6), (w * 0.85, h * 0.2)], iron[0], 3)
    glow(c, w * 0.5, h * 0.3, w * 0.22)
    c.rect(w * 0.22, h * 0.12, w * 0.78, h * 0.16, iron[1])
    c.rect(w * 0.22, h * 0.44, w * 0.78, h * 0.48, iron[1])
    c.poly([(w * 0.22, h * 0.12), (w * 0.5, 0), (w * 0.78, h * 0.12)], iron[2])
    return c.finish(darker(IRON, 0.4))


def window_box(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    boards(c, 0, h * 0.5, w, h, WOOD, vertical=False, width=8)
    for _ in range(16):
        x = rnd.uniform(6, w - 6)
        c.blob(x, h * 0.42 + rnd.uniform(-6, 4), rnd.uniform(5, 8), rnd.uniform(4, 6),
               ramp(rnd.choice(["#C8503A", "#E0A040", "#B060A0", "#5E7A3A", "#5E7A3A"]), 4))
    return c.finish(darker("#4A3A30", 0.5))


def hanging_sign(size, rnd, shape):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4)
    c.rect(w * 0.08, 0, w * 0.14, h, iron[1])
    c.rect(w * 0.08, h * 0.08, w * 0.94, h * 0.13, iron[1])
    c.line([(w * 0.12, h * 0.4), (w * 0.6, h * 0.13)], iron[0], 2)
    for x in (0.4, 0.82):
        c.rect(w * x, h * 0.13, w * x + 2, h * 0.3, iron[0])
    cx, cy = w * 0.61, h * 0.58
    if shape == "key":
        brass = ramp("brass", 4)
        c.ellipse(cx, cy - 18, 14, 14, brass[2])
        c.ellipse(cx, cy - 18, 7, 7, (0, 0, 0, 0)[:3] if False else brass[0])
        c.rect(cx - 4, cy - 6, cx + 4, cy + 36, brass[2])
        c.rect(cx + 4, cy + 20, cx + 16, cy + 26, brass[2])
        c.rect(cx + 4, cy + 30, cx + 12, cy + 36, brass[2])
    else:
        copper = ramp(COPPER, 4)
        for k in range(3):
            a = k / 3.0 * 2 * math.pi - math.pi / 2
            c.poly([(cx, cy), (cx + math.cos(a - 0.35) * 30, cy + math.sin(a - 0.35) * 30),
                    (cx + math.cos(a + 0.15) * 34, cy + math.sin(a + 0.15) * 34)], copper[2])
        c.ellipse(cx, cy, 6, 6, iron[2])
    c.rect(w * 0.05, h - 4, w * 0.18, h, iron[0])
    return c.finish(darker(IRON, 0.4))


def drainpipe(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    verd = ramp(mix(COPPER, "#5A9A8A", 0.55), 5)
    c.cylinder(w * 0.25, 0, w * 0.75, h - 18, verd)
    c.rect(0, 0, w, 10, verd[2])
    c.poly([(w * 0.25, h - 20), (w * 0.75, h - 20), (w, h - 4), (w, h), (w * 0.5, h)], verd[1])
    for y in range(40, h - 20, 90):
        c.rect(w * 0.15, y, w * 0.85, y + 4, verd[0])
    return c.finish(darker("#3A5A50", 0.5))


def outdoor_stairs(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    for k in range(9):
        x = w * 0.05 + k * w * 0.09
        y = h - k * h * 0.09
        c.rect(x, y - h * 0.09, x + w * 0.2, y - h * 0.09 + 8, wood[3])
        c.rect(x, y - h * 0.09 + 8, x + w * 0.2, y, wood[1])
    c.rect(w * 0.82, h * 0.12, w, h * 0.2, wood[2])
    post(c, w * 0.84, h * 0.2, h, 10, WOOD)
    c.line([(w * 0.06, h - 50), (w * 0.84, h * 0.06)], wood[2], 4)
    for k in range(5):
        x = w * (0.1 + 0.18 * k)
        c.line([(x, h - 50 - k * h * 0.15), (x, h - k * h * 0.15 - 10)], wood[1], 3)
    door(c, w * 0.84, 0, w * 0.15, h * 0.12)
    return c.finish(darker("#4A3A30", 0.5))


def awning_green(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    cloth = ramp("#6E8A6A", 4)
    c.poly([(0, h * 0.06), (w, h * 0.06), (w, h * 0.62), (0, h * 0.62)], cloth[2])
    for k in range(0, w, 24):
        c.rect(k, h * 0.06, k + 12, h * 0.62, cloth[1])
    for k in range(12):
        x = w * k / 12.0
        c.poly([(x, h * 0.6), (x + w / 12.0, h * 0.6), (x + w / 24.0, h)], cloth[3 if k % 2 else 2])
    c.rect(0, 0, w, h * 0.08, ramp(IRON, 4)[1])
    return c.finish(darker("#3A4A3A", 0.5))


# --- 10. Objets de la vie ---------------------------------------------------------------------------


def barrel(c, x, y_base, w, h, base="#8A5A3A", lid=True):
    tones = ramp(base, 5)
    c.cylinder(x - w / 2, y_base - h, x + w / 2, y_base, tones)
    for frac in (0.12, 0.5, 0.88):
        c.rect(x - w / 2, y_base - h * frac - 2, x + w / 2, y_base - h * frac + 1, ramp(IRON, 4)[0])
    if lid:
        c.ellipse(x, y_base - h, w / 2, w / 7, tones[3])


def sack(c, x, y_base, w, h, base="#B8A47A"):
    tones = ramp(mix(base, "#8A7A5A", 0.25), 5, spread=0.4)
    c.blob(x, y_base - h * 0.45, w / 2, h * 0.5, tones[0:4])
    c.rect(x - w * 0.15, y_base - h - 2, x + w * 0.15, y_base - h * 0.85, tones[2])
    c.rect(x - w * 0.42, y_base - 3, x + w * 0.42, y_base, tones[0])


def basket(c, x, y_base, w, h, base="#B08A50"):
    tones = ramp(base, 5)
    c.poly([(x - w / 2, y_base - h), (x + w / 2, y_base - h), (x + w * 0.4, y_base), (x - w * 0.4, y_base)], tones[2])
    for k in range(int(h / 4)):
        c.rect(x - w * 0.45, y_base - h + k * 4, x + w * 0.45, y_base - h + k * 4 + 1, tones[1])
    c.rect(x - w / 2, y_base - h, x + w / 2, y_base - h + 3, tones[3])


def fruit(c, x, y, r, color):
    c.blob(x, y, r, r * 0.9, ramp(color, 4))


def wheelbarrow(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    c.line([(w * 0.3, h * 0.55), (w * 0.02, h * 0.42)], wood[2], 4)
    c.poly([(w * 0.24, h * 0.3), (w * 0.86, h * 0.26), (w * 0.74, h * 0.7), (w * 0.32, h * 0.7)], wood[2])
    boards(c, w * 0.3, h * 0.32, w * 0.8, h * 0.66, WOOD, vertical=False, width=7)
    for _ in range(24):
        c.blob(w * rnd.uniform(0.3, 0.82), h * rnd.uniform(0.14, 0.32), rnd.uniform(4, 7), rnd.uniform(3, 5),
               ramp(rnd.choice(["leaf_gold", "leaf_rust", "#8A5A36"]), 4))
    c.ellipse(w * 0.78, h * 0.78, h * 0.21, h * 0.21, wood[1])
    c.ellipse(w * 0.78, h * 0.78, h * 0.08, h * 0.08, ramp(IRON, 4)[1])
    c.line([(w * 0.38, h * 0.7), (w * 0.34, h)], wood[1], 4)
    return c.finish(darker(DARK, 0.5))


def firewood_pile(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (0.06, 0.94):
        post(c, w * x, h * 0.16, h, 8, DARK)
    log_pile(c, w * 0.08, w * 0.92, h, rows=6, r=12)
    boards(c, 0, h * 0.04, w, h * 0.16, "#7A6A5A", vertical=True, width=16)
    c.poly([(0, h * 0.16), (w, h * 0.16), (w, h * 0.19), (0, h * 0.19)], ramp(DARK, 4)[0])
    return c.finish(darker(DARK, 0.5))


def stump_axe(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#7A5A40", 5)
    c.cylinder(w * 0.18, h * 0.4, w * 0.82, h, wood)
    c.ellipse(w * 0.5, h * 0.4, w * 0.32, h * 0.1, ramp("#C8A070", 4)[2])
    for r in (0.22, 0.14, 0.06):
        c.ellipse(w * 0.5, h * 0.4, w * r, h * r / 3.2, ramp("#C8A070", 4)[1])
    c.line([(w * 0.56, h * 0.36), (w * 0.86, h * 0.02)], ramp(WOOD, 4)[2], 4)
    c.poly([(w * 0.42, h * 0.3), (w * 0.62, h * 0.24), (w * 0.62, h * 0.42), (w * 0.48, h * 0.4)], ramp(IRON, 4)[2])
    for _ in range(10):
        x = rnd.uniform(w * 0.05, w * 0.95)
        c.rect(x, h - 4, x + 4, h - 2, ramp("#D8B880", 3)[1])
    return c.finish(darker(DARK, 0.5))


def rain_barrel(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    barrel(c, w * 0.5, h, w * 0.8, h * 0.86)
    c.ellipse(w * 0.5, h * 0.15, w * 0.34, w * 0.09, ramp("marsh", 4)[1])
    c.line([(w * 0.62, h * 0.14), (w * 0.86, h * 0.0 + 4)], ramp(WOOD, 4)[2], 3)
    return c.finish(darker(DARK, 0.5))


def laundry_basket(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    cloth = ramp("#F2EEE6", 4)
    c.blob(w * 0.5, h * 0.38, w * 0.4, h * 0.3, cloth)
    basket(c, w * 0.5, h, w * 0.9, h * 0.6)
    for x in (0.3, 0.6):
        c.rect(w * x, h * 0.2, w * x + 2, h * 0.32, ramp(WOOD, 4)[1])
    return c.finish(darker("#5A4A3A", 0.5))


def toys_a(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#C8A070", 4)
    c.ellipse(w * 0.66, h * 0.55, h * 0.42, h * 0.42, ramp("#B5443A", 4)[2])
    c.ellipse(w * 0.66, h * 0.55, h * 0.34, h * 0.34, (0, 0, 0))
    c.img = c.img.copy()
    hole = Image.new("L", size, 0)
    ImageDraw.Draw(hole).ellipse((w * 0.66 - h * 0.34, h * 0.55 - h * 0.34, w * 0.66 + h * 0.34, h * 0.55 + h * 0.34), fill=255)
    c.img.paste(Image.new("RGBA", size, (0, 0, 0, 0)), (0, 0), hole)
    c.draw = ImageDraw.Draw(c.img)
    for k in range(2):
        y = h * (0.76 + 0.14 * k)
        c.rect(w * 0.04, y, w * 0.56, y + 4, wood[2])
        c.rect(w * 0.1 + k * 6, y - 4, w * 0.13 + k * 6, y + 8, wood[1])
    return c.finish(darker(DARK, 0.5))


def toys_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    c.cylinder(w * 0.5, h * 0.5, w * 0.95, h, ramp("#8A9298", 5))
    c.ellipse(w * 0.72, h * 0.5, w * 0.23, h * 0.08, ramp("#8A9298", 4)[3])
    cloth = ramp("#C88A7A", 4)
    c.blob(w * 0.3, h * 0.72, w * 0.18, h * 0.24, cloth)
    c.blob(w * 0.3, h * 0.32, w * 0.13, h * 0.16, ramp("#E8D0B0", 4))
    c.rect(w * 0.2, h * 0.16, w * 0.42, h * 0.22, ramp("#8A5A3A", 4)[2])
    c.rect(w * 0.12, h * 0.88, w * 0.48, h, cloth[1])
    return c.finish(darker("#5A4A42", 0.5))


def bench_b(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    for x in (0.1, 0.9):
        c.rect(w * x - 5, h * 0.5, w * x + 5, h, wood[1])
    boards(c, 0, h * 0.48, w, h * 0.62, WOOD, vertical=False, width=7)
    c.blob(w * 0.36, h * 0.44, w * 0.2, h * 0.08, ramp("#8A6AA0", 4))
    for x in (0.1, 0.9):
        c.rect(w * x - 4, h * 0.02, w * x + 4, h * 0.5, wood[2])
    c.poly([(w * 0.08, h * 0.08), (w * 0.5, 0), (w * 0.92, h * 0.08), (w * 0.92, h * 0.3), (w * 0.08, h * 0.3)], wood[2])
    for k in range(6):
        x = w * (0.18 + 0.12 * k)
        c.ellipse(x, h * 0.18, 5, 7, wood[0])
    return c.finish(darker(DARK, 0.5))


def fence_module(size, rnd, rope=False):
    """Clôture de 2 m sans raccord à gauche et à droite (un piquet à cheval sur le bord)."""
    w, h = size
    c = WrapCanvas(w, h, rnd)
    wood = ramp("#9A7A58", 5)
    if rope:
        for x in (0, w / 2.0):
            post(c, x, h * 0.04, h, 9, "#8A6A4C")
            c.poly([(x - 5, h * 0.06), (x, 0), (x + 5, h * 0.06)], wood[2])
        cord = ramp("#C9B48A", 3)
        for y in (h * 0.25, h * 0.55):
            pts = [(x, y + math.sin(math.pi * (x % (w / 2.0)) / (w / 2.0)) * 8) for x in range(0, w + 1, 8)]
            c.line(pts, cord[1], 2)
    else:
        for y in (h * 0.3, h * 0.66):
            c.rect(0, y, w, y + 6, wood[2])
            c.rect(0, y, w, y + 2, wood[3])
        for k in range(8):
            x = k * w / 8.0
            top = h * (0.02 + 0.06 * ((k * 7) % 3) / 2.0)
            c.rect(x - 4, top + 6, x + 4, h, wood[1 + k % 2])
            c.poly([(x - 4, top + 6), (x, top), (x + 4, top + 6)], wood[3])
    return c.finish(darker(DARK, 0.5))


def bucket(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    tones = ramp(WOOD, 5)
    c.poly([(w * 0.1, h * 0.2), (w * 0.9, h * 0.2), (w * 0.8, h), (w * 0.2, h)], tones[2])
    c.rect(w * 0.12, h * 0.3, w * 0.88, h * 0.36, ramp(IRON, 4)[0])
    c.rect(w * 0.16, h * 0.78, w * 0.84, h * 0.84, ramp(IRON, 4)[0])
    c.ellipse(w * 0.5, h * 0.2, w * 0.4, h * 0.08, tones[0])
    return c.finish(darker(DARK, 0.5))


def watering_can(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    copper = ramp(COPPER, 5)
    c.cylinder(w * 0.28, h * 0.3, w * 0.72, h, copper)
    c.line([(w * 0.7, h * 0.7), (w * 0.98, h * 0.2)], copper[2], 3)
    c.line([(w * 0.34, h * 0.3), (w * 0.5, h * 0.06), (w * 0.66, h * 0.3)], copper[1], 2)
    c.ellipse(w * 0.6, h * 0.62, 3, 2, copper[0])
    return c.finish(darker(COPPER, 0.4))


def garden_tools(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 4)
    iron = ramp(IRON, 4)
    c.line([(w * 0.2, h), (w * 0.42, h * 0.08)], wood[2], 3)
    c.rect(w * 0.26, h * 0.06, w * 0.62, h * 0.1, iron[1])
    for k in range(6):
        c.rect(w * 0.27 + k * 4, h * 0.1, w * 0.27 + k * 4 + 1, h * 0.15, iron[0])
    c.line([(w * 0.5, h), (w * 0.5, h * 0.1)], wood[2], 3)
    for k in range(3):
        c.line([(w * 0.44 + k * 6, h * 0.1), (w * 0.44 + k * 6, h * 0.0 + 2)], iron[1], 2)
    c.line([(w * 0.82, h * 0.8), (w * 0.6, h * 0.12)], wood[2], 3)
    c.poly([(w * 0.7, h * 0.78), (w * 0.96, h * 0.72), (w * 0.96, h * 0.98), (w * 0.76, h)], iron[2])
    return c.finish(darker(DARK, 0.5))


def scarecrow(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 4)
    c.rect(w * 0.47, h * 0.2, w * 0.53, h, wood[1])
    c.rect(w * 0.06, h * 0.32, w * 0.94, h * 0.36, wood[2])
    coat = ramp("#6A5A4A", 5)
    c.poly([(w * 0.2, h * 0.32), (w * 0.8, h * 0.32), (w * 0.74, h * 0.72), (w * 0.26, h * 0.72)], coat[2])
    c.poly([(w * 0.04, h * 0.32), (w * 0.2, h * 0.32), (w * 0.2, h * 0.44), (w * 0.08, h * 0.46)], coat[1])
    c.poly([(w * 0.8, h * 0.32), (w * 0.96, h * 0.32), (w * 0.92, h * 0.46), (w * 0.8, h * 0.44)], coat[1])
    c.rect(w * 0.24, h * 0.24, w * 0.76, h * 0.3, ramp("#B5443A", 4)[2])
    c.line([(w * 0.7, h * 0.27), (w * 0.84, h * 0.46)], ramp("#B5443A", 4)[2], 5)
    c.blob(w * 0.5, h * 0.16, w * 0.16, h * 0.08, ramp("#D8C8A0", 4))
    straw = ramp("#D8B860", 4)
    c.poly([(w * 0.18, h * 0.1), (w * 0.82, h * 0.1), (w * 0.66, h * 0.06), (w * 0.6, 0), (w * 0.4, 0), (w * 0.34, h * 0.06)], straw[2])
    for x in (0.08, 0.92):
        for k in range(3):
            c.line([(w * x, h * 0.44), (w * x + (k - 1) * 4, h * 0.5)], straw[3], 1)
    return c.finish(darker("#4A3A30", 0.5))


def kids_table(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    boards(c, w * 0.25, h * 0.36, w * 0.75, h * 0.46, WOOD, vertical=False, width=5)
    for x in (0.28, 0.7):
        c.rect(w * x, h * 0.46, w * x + 5, h, wood[1])
    for x in (0.08, 0.86, 0.5):
        c.rect(w * x - 12, h * 0.62, w * x + 12, h * 0.68, wood[3])
        for dx in (-10, 8):
            c.rect(w * x + dx, h * 0.68, w * x + dx + 3, h, wood[1])
    for x in (0.38, 0.6):
        c.rect(w * x, h * 0.26, w * x + 8, h * 0.36, "#F2EEE0")
        c.rect(w * x + 8, h * 0.28, w * x + 10, h * 0.33, "#F2EEE0")
    return c.finish(darker(DARK, 0.5))


def flower_pots(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    pot = ramp("#B8603A", 5)
    for k, x in enumerate((0.16, 0.42, 0.66)):
        c.poly([(w * x - 12, h * 0.46), (w * x + 12, h * 0.46), (w * x + 9, h), (w * x - 9, h)], pot[2])
        c.rect(w * x - 13, h * 0.44, w * x + 13, h * 0.52, pot[3])
        c.blob(w * x, h * 0.3, 12, 10, ramp(rnd.choice(["#C8503A", "#E0A040", "#B060A0"]), 4))
    c.poly([(w * 0.82, h * 0.7), (w * 0.98, h * 0.76), (w * 0.94, h), (w * 0.8, h)], pot[1])
    c.poly([(w * 0.84, h * 0.72), (w * 0.9, h * 0.6), (w * 0.94, h * 0.74)], pot[2])
    return c.finish(darker("#5A3A2A", 0.5))


def crate_stack(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    a = crate((int(w * 0.62), int(h * 0.5)), rnd)
    c.img.alpha_composite(a, (0, h - a.height))
    b = crate((int(w * 0.54), int(h * 0.46)), rnd)
    c.img.alpha_composite(b, (int(w * 0.04), h - a.height - b.height + 4))
    sack(c, w * 0.8, h, w * 0.34, h * 0.42)
    return c.finish(darker(DARK, 0.5))


def bench_stone(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp(mix("stone", "stone_dark", 0.2), 5)
    c.rect(0, h * 0.2, w, h * 0.5, stone[2])
    c.rect(0, h * 0.2, w, h * 0.28, stone[3])
    for x in (0.1, 0.78):
        c.rect(w * x, h * 0.5, w * x + w * 0.14, h, stone[1])
    for _ in range(14):
        c.blob(rnd.uniform(4, w - 4), h * 0.22 + rnd.uniform(-3, 2), rnd.uniform(3, 6), 3, ramp("#6E8C4A", 4))
    return c.finish(darker("stone_dark", 0.45))


def sack_apples(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    sack(c, w * 0.4, h, w * 0.6, h * 0.9)
    c.ellipse(w * 0.4, h * 0.22, w * 0.2, h * 0.06, ramp("#C8B48A", 4)[0])
    for x, y in ((0.36, 0.2), (0.46, 0.18), (0.74, 0.88), (0.88, 0.9), (0.66, 0.92)):
        fruit(c, w * x, h * y, 5, "#B83A2E")
    return c.finish(darker("#5A4A3A", 0.5))


def cafe_table(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4)
    wood = ramp(WOOD, 5)
    for x in (0.12, 0.88):
        side = -1 if x < 0.5 else 1
        c.rect(w * x - 12, h * 0.56, w * x + 12, h * 0.62, wood[3])
        c.line([(w * x - side * 10, h * 0.56), (w * x - side * 12, h * 0.1)], iron[1], 3)
        for dx in (-10, 10):
            c.line([(w * x + dx, h * 0.62), (w * x + dx * 1.1, h)], iron[1], 2)
    c.ellipse(w * 0.5, h * 0.42, w * 0.3, h * 0.08, wood[3])
    c.rect(w * 0.2, h * 0.42, w * 0.8, h * 0.46, wood[1])
    c.line([(w * 0.5, h * 0.46), (w * 0.5, h)], iron[1], 4)
    c.rect(w * 0.4, h - 3, w * 0.6, h, iron[0])
    for x in (0.4, 0.58):
        c.rect(w * x, h * 0.32, w * x + 7, h * 0.4, "#F2EEE0")
    return c.finish(darker(IRON, 0.45))


def barrel_group(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    barrel(c, w * 0.22, h, w * 0.4, h * 0.72)
    barrel(c, w * 0.78, h, w * 0.4, h * 0.7)
    barrel(c, w * 0.5, h, w * 0.42, h * 0.82, lid=False)
    c.ellipse(w * 0.5, h * 0.18, w * 0.2, h * 0.06, ramp("#4A3A30", 4)[0])
    for _ in range(9):
        fruit(c, w * 0.5 + rnd.uniform(-w * 0.15, w * 0.15), h * 0.16 + rnd.uniform(-5, 2), 5,
              rnd.choice(["#B83A2E", "#C8A030", "#B83A2E"]))
    return c.finish(darker(DARK, 0.5))


def sacks_pile(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for x, y, s in ((0.2, 1.0, 0.36), (0.5, 1.0, 0.36), (0.8, 1.0, 0.36), (0.35, 0.55, 0.34), (0.65, 0.55, 0.34)):
        sack(c, w * x, h * y, w * s, h * 0.5, rnd.choice(["#E0D4B8", "#C8B48A", "#D8C8A0"]))
    return c.finish(darker("#5A4A3A", 0.5))


def hand_cart(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    c.line([(w * 0.7, h * 0.66), (w * 0.99, h * 0.98)], wood[2], 5)
    boards(c, w * 0.04, h * 0.42, w * 0.74, h * 0.7, WOOD, vertical=False, width=9)
    for k in range(3):
        b = crate((int(w * 0.18), int(h * 0.34)), rnd)
        c.img.alpha_composite(b, (int(w * (0.08 + 0.2 * k)), int(h * 0.42 - b.height + 4)))
    for _ in range(7):
        fruit(c, w * rnd.uniform(0.12, 0.66), h * rnd.uniform(0.04, 0.12), rnd.uniform(5, 8),
              rnd.choice(["#D67A2A", "#7FA05A", "#B5443A"]))
    c.ellipse(w * 0.36, h * 0.78, h * 0.22, h * 0.22, wood[1])
    c.ellipse(w * 0.36, h * 0.78, h * 0.06, h * 0.06, ramp(IRON, 4)[1])
    for k in range(6):
        a = k / 6.0 * 2 * math.pi
        c.line([(w * 0.36, h * 0.78), (w * 0.36 + math.cos(a) * h * 0.2, h * 0.78 + math.sin(a) * h * 0.2)], wood[0], 2)
    return c.finish(darker(DARK, 0.5))


def fountain(size, rnd, water_phase=None):
    """Fontaine du marché : bassin rond de pierre, pilier, bec de cuivre, eau qui tombe."""
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("stone", 5)
    c.rect(w * 0.43, h * 0.18, w * 0.57, h * 0.6, stone[2])
    c.rect(w * 0.43, h * 0.18, w * 0.47, h * 0.6, stone[3])
    c.rect(w * 0.4, h * 0.14, w * 0.6, h * 0.2, stone[3])
    c.blob(w * 0.5, h * 0.1, 14, 10, stone[1:])
    copper = ramp(COPPER, 4)
    c.rect(w * 0.56, h * 0.3, w * 0.66, h * 0.34, copper[2])
    body = material("wall_stone", size)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    md.rectangle((w * 0.04, h * 0.62, w * 0.96, h), fill=255)
    md.ellipse((w * 0.04, h * 0.52, w * 0.96, h * 0.72), fill=255)
    c.img.paste(body, (0, 0), mask)
    c.ellipse(w * 0.5, h * 0.62, w * 0.46, h * 0.1, stone[4])
    c.ellipse(w * 0.5, h * 0.63, w * 0.4, h * 0.075, ramp("marsh", 4)[1])
    phase = 0.0 if water_phase is None else water_phase
    water = ramp(mix("marsh", "#B8D8D0", 0.5), 4)
    for k in range(5):
        y = h * 0.34 + k * h * 0.05 + (phase * h * 0.05)
        if y < h * 0.62:
            c.rect(w * 0.64, y, w * 0.68, y + h * 0.04, water[2 + k % 2])
    for k in range(3):
        r = (0.06 + 0.1 * ((k + phase) % 3)) * w
        c.ellipse(w * 0.66, h * 0.635, r, r * 0.18, water[3])
        c.ellipse(w * 0.66, h * 0.635, max(1, r - 2), max(1, r * 0.18 - 1), ramp("marsh", 4)[1])
    c.rect(w * 0.64, h * 0.62, w * 0.68, h * 0.64, water[3])
    return c.finish(darker("stone_dark", 0.45))


def notice_board(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (0.1, 0.9):
        post(c, w * x, h * 0.1, h, 10, WOOD)
    boards(c, w * 0.12, h * 0.2, w * 0.88, h * 0.7, DARK, width=12)
    paper = ramp("#E8DCC0", 4)
    for _ in range(7):
        x, y = w * rnd.uniform(0.16, 0.62), h * rnd.uniform(0.22, 0.5)
        pw, ph = rnd.uniform(18, 30), rnd.uniform(22, 34)
        c.rect(x, y, x + pw, y + ph, paper[rnd.randint(1, 3)])
        for ly in range(5, int(ph) - 4, 5):
            c.rect(x + 3, y + ly, x + pw - 3 - (ly % 3) * 3, y + ly + 1, "#8A8478")
        c.rect(x + pw / 2 - 1, y + 1, x + pw / 2 + 1, y + 3, "#B5443A")
    c.poly([(0, h * 0.2), (w * 0.5, 0), (w, h * 0.2)], ramp("#7A5A40", 4)[2])
    c.poly([(w * 0.04, h * 0.19), (w * 0.5, h * 0.02), (w * 0.5, h * 0.19)], ramp("#7A5A40", 4)[3])
    return c.finish(darker(DARK, 0.5))


def stall(size, rnd, cloth, goods):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (0.06, 0.94):
        post(c, w * x, h * 0.14, h, 8, WOOD)
    boards(c, w * 0.04, h * 0.58, w * 0.96, h * 0.66, WOOD, vertical=False, width=8)
    boards(c, w * 0.08, h * 0.66, w * 0.92, h, DARK, vertical=True, width=16)
    goods(c, w, h)
    tones = ramp(cloth, 5, spread=0.35)
    c.poly([(0, h * 0.2), (w * 0.08, 0), (w * 0.92, 0), (w, h * 0.2)], tones[3])
    for k in range(10):
        x = w * k / 10.0
        c.poly([(x, h * 0.2), (x + w / 10.0, h * 0.2), (x + w / 20.0, h * 0.27)], tones[2 if k % 2 else 3])
    c.rect(0, h * 0.19, w, h * 0.21, tones[1])
    return c.finish(darker(DARK, 0.5))


def market_stall_fruit(size, rnd):
    def goods(c, w, h):
        for k in range(4):
            basket(c, w * (0.18 + 0.21 * k), h * 0.58, 40, 18)
            col = ["#B83A2E", "#C8B040", "#D67A2A", "#7FA05A"][k]
            for _ in range(6):
                fruit(c, w * (0.18 + 0.21 * k) + rnd.uniform(-14, 14), h * 0.5 + rnd.uniform(-4, 2), 5, col)
    return stall(size, rnd, "#7A9A7A", goods)


def market_stall_cloth(size, rnd):
    def goods(c, w, h):
        for k in range(5):
            col = rnd.choice(["#8A3A4A", "#4A6A8A", "#C8A050", "#6A8A5A", "#E8DCC0"])
            c.cylinder(w * (0.14 + 0.16 * k), h * 0.48, w * (0.14 + 0.16 * k) + 30, h * 0.58, ramp(col, 5), vertical=False)
        for k in range(6):
            x = w * (0.12 + 0.14 * k)
            col = rnd.choice(["#B5443A", "#4A6A8A", "#C8A050", "#8A5AA0"])
            c.poly([(x, h * 0.22), (x + 10, h * 0.22), (x + 12, h * 0.42), (x - 2, h * 0.44)], ramp(col, 4)[2])
    return stall(size, rnd, "#7A2E3A", goods)


def bread_rack(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    for x in (0.08, 0.92):
        c.rect(w * x - 3, h * 0.06, w * x + 3, h, wood[1])
    for y in (0.36, 0.68):
        c.rect(w * 0.05, h * y, w * 0.95, h * y + 5, wood[3])
    crust = ramp("#C89050", 5)
    for k in range(5):
        c.blob(w * (0.16 + 0.17 * k), h * 0.62, 11, 8, crust[1:])
    for k in range(6):
        c.line([(w * (0.14 + 0.14 * k), h * 0.34), (w * (0.18 + 0.14 * k), h * 0.08)], crust[2], 6)
    return c.finish(darker(DARK, 0.5))


def book_cart(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    for x in (0.12, 0.82):
        c.line([(w * x, h * 0.5), (w * x - 8, h)], wood[1], 4)
        c.line([(w * x + 6, h * 0.5), (w * x + 16, h)], wood[1], 4)
    boards(c, w * 0.04, h * 0.3, w * 0.96, h * 0.52, WOOD, vertical=False, width=7)
    x = w * 0.08
    while x < w * 0.9:
        bw = rnd.randint(5, 9)
        bh = rnd.uniform(h * 0.14, h * 0.26)
        c.rect(x, h * 0.3 - bh, x + bw, h * 0.3, ramp(rnd.choice(["#7A3A3A", "#3A5A7A", "#5A7A4A", "#8A6A3A", "#6A4A7A"]), 4)[2])
        c.rect(x, h * 0.3 - bh, x + 1, h * 0.3, "#E8DCC0")
        x += bw + 1
    return c.finish(darker(DARK, 0.5))


def menu_slate(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 4)
    c.line([(w * 0.2, h), (w * 0.4, h * 0.02)], wood[1], 3)
    c.line([(w * 0.8, h), (w * 0.6, h * 0.02)], wood[1], 3)
    c.rect(w * 0.1, h * 0.08, w * 0.9, h * 0.66, wood[2])
    c.rect(w * 0.16, h * 0.12, w * 0.84, h * 0.62, "#2E3432")
    cup = "#E8E4D8"
    c.rect(w * 0.34, h * 0.36, w * 0.62, h * 0.5, cup)
    c.rect(w * 0.62, h * 0.38, w * 0.7, h * 0.46, cup)
    for k in range(3):
        c.line([(w * (0.38 + 0.08 * k), h * 0.32), (w * (0.4 + 0.08 * k), h * 0.2)], cup, 1)
    return c.finish(darker("#3A2E2A", 0.5))


def street_lamp_double(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 5)
    c.cylinder(w * 0.45, h * 0.16, w * 0.55, h, [mix(x, (40, 40, 50), 0.4) for x in iron])
    c.rect(w * 0.36, h - 12, w * 0.64, h, iron[1])
    c.line([(w * 0.5, h * 0.2), (w * 0.14, h * 0.14)], iron[1], 4)
    c.line([(w * 0.5, h * 0.2), (w * 0.86, h * 0.14)], iron[1], 4)
    for x in (0.14, 0.86):
        glow(c, w * x, h * 0.2, w * 0.1)
        c.poly([(w * x - 12, h * 0.15), (w * x, h * 0.11), (w * x + 12, h * 0.15)], iron[2])
        c.rect(w * x - 9, h * 0.25, w * x + 9, h * 0.26, iron[1])
    c.poly([(w * 0.44, h * 0.18), (w * 0.5, h * 0.12), (w * 0.56, h * 0.18)], iron[2])
    return c.finish(darker(IRON, 0.4))


def planter_long(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    boards(c, 0, h * 0.42, w, h, WOOD, vertical=True, width=12)
    c.rect(0, h * 0.42, w, h * 0.48, ramp(WOOD, 4)[3])
    for _ in range(22):
        x = rnd.uniform(6, w - 6)
        c.blob(x, h * 0.32 + rnd.uniform(-8, 6), rnd.uniform(5, 9), rnd.uniform(4, 7),
               ramp(rnd.choice(["#5E7A3A", "#6E8A44", "#C8503A", "#E0A040", "#A070B0"]), 4))
    return c.finish(darker(DARK, 0.5))


def bunting(size, rnd, phase=None):
    """Guirlande de fanions entre deux crochets ; phase : flottement (bande animée)."""
    w, h = size
    c = Canvas(w, h, rnd)
    rope = ramp("#C9B48A", 3)
    def sag(x):
        return 8 + math.sin(math.pi * x / w) * h * 0.42
    c.line([(x, sag(x)) for x in range(0, w + 1, 8)], rope[1], 2)
    colors = ["#B5443A", "#F2EEE0", "#5E8A5A"]
    n = 14
    for k in range(n):
        x = w * (k + 0.5) / n
        y = sag(x)
        sway = 0.0 if phase is None else math.sin(2 * math.pi * phase + k * 0.9) * 4
        tip_y = min(h - 1, y + h * 0.36)
        if k == n // 2:
            tip_y = h - 1
            sway = 0.0
        c.poly([(x - 9, y), (x + 9, y), (x + sway, tip_y)], ramp(colors[k % 3], 4)[2])
        c.poly([(x - 9, y), (x - 2, y), (x + sway, tip_y)], ramp(colors[k % 3], 4)[3])
    c.rect(0, 2, 6, 10, ramp(IRON, 4)[0])
    c.rect(w - 6, 2, w, 10, ramp(IRON, 4)[0])
    return c.finish(darker("#5A3A3A", 0.5))


def crate_apples(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    boards(c, 0, h * 0.4, w, h, WOOD, vertical=False, width=7)
    for _ in range(11):
        fruit(c, rnd.uniform(8, w - 8), h * 0.34 + rnd.uniform(-5, 3), 6, "#B83A2E")
    return c.finish(darker(DARK, 0.5))


def broom_bucket(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    c.line([(w * 0.62, h * 0.72), (w * 0.4, 0)], ramp(WOOD, 4)[2], 3)
    straw = ramp("#D8B860", 4)
    c.poly([(w * 0.5, h * 0.7), (w * 0.8, h * 0.7), (w * 0.96, h), (w * 0.4, h)], straw[2])
    for k in range(6):
        c.line([(w * (0.5 + 0.05 * k), h * 0.72), (w * (0.44 + 0.09 * k), h)], straw[1], 1)
    tones = ramp(WOOD, 5)
    c.poly([(w * 0.02, h * 0.74), (w * 0.46, h * 0.74), (w * 0.42, h), (w * 0.06, h)], tones[2])
    c.rect(w * 0.04, h * 0.8, w * 0.44, h * 0.82, ramp(IRON, 4)[0])
    return c.finish(darker(DARK, 0.5))


def mooring_tower(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("#5A6270", 5)
    copper = ramp(COPPER, 5)
    c.poly([(w * 0.3, h), (w * 0.42, h * 0.08), (w * 0.58, h * 0.08), (w * 0.7, h)], iron[1])
    for k in range(9):
        y0 = h * (0.08 + 0.1 * k)
        y1 = y0 + h * 0.1
        c.line([(w * (0.42 - 0.012 * k), y0), (w * (0.58 + 0.012 * k), y1)], iron[3], 3)
        c.line([(w * (0.58 + 0.012 * k), y0), (w * (0.42 - 0.012 * k), y1)], iron[3], 3)
        for x in (0.42 - 0.012 * k, 0.58 + 0.012 * k):
            c.rect(w * x - 2, y0, w * x + 2, y0 + 3, iron[4])
    for k, y in enumerate((0.16, 0.34, 0.52)):
        side = -1 if k % 2 else 1
        c.line([(w * 0.5, h * y), (w * (0.5 + side * 0.4), h * (y - 0.06))], copper[2], 9)
        c.line([(w * (0.5 + side * 0.4), h * (y - 0.06)), (w * (0.5 + side * 0.32), h * (y + 0.06))], copper[2], 7)
        c.blob(w * 0.5, h * y, 9, 9, copper[1:])
        c.line([(w * (0.5 + side * 0.32), h * (y + 0.06)), (w * (0.5 + side * 0.3), h * (y + 0.2))], "#3A3434", 1)
    c.rect(w * 0.47, h * 0.08, w * 0.53, h, iron[0])
    for y in range(int(h * 0.12), h, 12):
        c.rect(w * 0.47, y, w * 0.53, y + 2, iron[3])
    c.rect(w * 0.26, h - 18, w * 0.74, h, iron[2])
    return c.finish(darker("#3A4048", 0.45))


def cargo_net(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4)
    c.line([(w * 0.5, 0), (w * 0.5, h * 0.18)], iron[0], 3)
    c.poly([(w * 0.44, h * 0.16), (w * 0.56, h * 0.16), (w * 0.54, h * 0.26), (w * 0.5, h * 0.22)], iron[2])
    for k in range(4):
        b = crate((int(w * 0.34), int(h * 0.32)), rnd)
        c.img.alpha_composite(b, (int(w * (0.1 + 0.26 * (k % 3))), int(h * (0.66 - 0.3 * (k // 3)) - 0)))
    sack(c, w * 0.78, h * 0.66, w * 0.24, h * 0.3)
    rope = ramp("#B49870", 3)
    for k in range(9):
        x = w * (0.06 + 0.11 * k)
        c.line([(w * 0.5, h * 0.24), (x, h * 0.6), (x + 4, h)], rope[1], 1)
    for y in (0.5, 0.7, 0.9):
        c.line([(w * 0.06, h * y), (w * 0.94, h * y)], rope[1], 1)
    return c.finish(darker(DARK, 0.5))


def crystal_crates(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for k, (x, y, cw, ch) in enumerate(((0.0, 0.42, 0.56, 0.58), (0.48, 0.48, 0.52, 0.52), (0.14, 0.0, 0.5, 0.46))):
        x0, y0, x1, y1 = w * x, h * y, w * (x + cw), h * (y + ch)
        c.rect(x0, y0, x1, y1, "#2A2420")
        glow(c, (x0 + x1) / 2, (y0 + y1) / 2, min(x1 - x0, y1 - y0) * 0.36)
        wood = ramp(WOOD, 5)
        for yy in range(int(y0), int(y1), 10):
            c.rect(x0, yy, x1, yy + 5, wood[2 + (yy // 10) % 2])
        c.rect(x0, y0, x0 + 5, y1, wood[1])
        c.rect(x1 - 5, y0, x1, y1, wood[1])
    return c.finish(darker(DARK, 0.5))


def fuel_barrels(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    barrel(c, w * 0.26, h, w * 0.42, h * 0.84, base="#5A5A5A")
    barrel(c, w * 0.72, h, w * 0.42, h * 0.8, base="#6A5A4A")
    for _ in range(8):
        x = rnd.uniform(w * 0.1, w * 0.9)
        c.line([(x, h * 0.3), (x + rnd.uniform(-2, 2), h * 0.3 + rnd.uniform(6, 20))], "#2A2622", 2)
    return c.finish(darker("#3A3434", 0.5))


def rope_coil(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    rope = ramp("#B49870", 5)
    for k in range(6):
        c.ellipse(w * 0.5, h * (0.7 - 0.07 * k), w * (0.46 - 0.04 * k), h * 0.24, rope[1 + k % 3])
        c.ellipse(w * 0.5, h * (0.7 - 0.07 * k), w * (0.46 - 0.04 * k) - 3, h * 0.24 - 3, rope[0])
    c.ellipse(w * 0.5, h * 0.36, w * 0.18, h * 0.1, "#3A2E26")
    c.line([(w * 0.8, h * 0.7), (w * 0.98, h * 0.94)], rope[2], 3)
    c.rect(w * 0.06, h - 4, w * 0.94, h, rope[1])
    return c.finish(darker("#5A4A3A", 0.5))


def steam_pipes(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    copper = ramp(COPPER, 5)
    c.rect(0, h * 0.86, w, h, ramp(IRON, 4)[1])
    for x0, y_top, bend in ((0.2, 0.2, 0.5), (0.5, 0.36, 0.86), (0.8, 0.12, 0.6)):
        c.cylinder(w * x0 - 9, h * y_top, w * x0 + 9, h * 0.88, copper)
        c.rect(w * x0 - 11, h * 0.5, w * x0 + 11, h * 0.54, copper[0])
    c.cylinder(w * 0.2, h * 0.2, w * 0.8, h * 0.28, copper, vertical=False)
    c.ellipse(w * 0.5, h * 0.52, 16, 16, ramp(IRON, 4)[1])
    for k in range(6):
        a = k / 6.0 * 2 * math.pi
        c.line([(w * 0.5, h * 0.52), (w * 0.5 + math.cos(a) * 15, h * 0.52 + math.sin(a) * 15)], ramp(IRON, 4)[3], 2)
    c.ellipse(w * 0.8, h * 0.36, 13, 13, ramp("brass", 4)[2])
    c.ellipse(w * 0.8, h * 0.36, 10, 10, "#F0E8D0")
    c.line([(w * 0.8, h * 0.36), (w * 0.8 + 6, h * 0.36 - 5)], "#3A2E2A", 1)
    return c.finish(darker(COPPER, 0.4))


def workbench(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 5)
    boards(c, 0, h * 0.4, w, h * 0.52, WOOD, vertical=False, width=6)
    for x in (0.06, 0.9):
        c.rect(w * x, h * 0.52, w * x + 10, h, wood[1])
    c.rect(w * 0.06, h * 0.84, w * 0.96, h * 0.88, wood[1])
    iron = ramp(IRON, 4)
    c.rect(w * 0.06, h * 0.22, w * 0.2, h * 0.4, iron[2])
    c.rect(w * 0.04, h * 0.18, w * 0.22, h * 0.24, iron[1])
    for k in range(3):
        c.ellipse(w * (0.4 + 0.12 * k), h * 0.34, 8, 8, ramp("brass", 4)[2])
        c.ellipse(w * (0.4 + 0.12 * k), h * 0.34, 3, 3, ramp("brass", 4)[0])
    c.line([(w * 0.76, h * 0.38), (w * 0.9, h * 0.32)], iron[2], 3)
    c.blob(w * 0.28, h * 0.36, 10, 5, ramp("#C8B8A0", 4))
    return c.finish(darker(DARK, 0.5))


def luggage(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for x, y, bw, bh, col in ((0.0, 0.5, 0.56, 0.5, "#6A4A3A"), (0.5, 0.56, 0.5, 0.44, "#4A5A6A"),
                              (0.1, 0.12, 0.44, 0.38, "#8A6A4A"), (0.56, 0.2, 0.32, 0.36, "#7A3A3A")):
        tones = ramp(col, 4)
        c.rect(w * x, h * y, w * (x + bw), h * (y + bh), tones[2])
        c.rect(w * x, h * y, w * (x + bw), h * y + 3, tones[3])
        c.rect(w * (x + bw * 0.3), h * y, w * (x + bw * 0.3) + 3, h * (y + bh), ramp("#C8A060", 4)[1])
        c.rect(w * (x + bw * 0.4), h * y - 4, w * (x + bw * 0.6), h * y, tones[0])
    return c.finish(darker("#3A2E2A", 0.5))


def ticket_booth(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    boards(c, w * 0.06, h * 0.56, w * 0.94, h, DARK, vertical=True, width=14)
    c.rect(w * 0.06, h * 0.2, w * 0.94, h * 0.56, ramp(WOOD, 4)[1])
    c.rect(w * 0.12, h * 0.24, w * 0.88, h * 0.52, ramp("crystal", 5)[2])
    c.rect(w * 0.12, h * 0.24, w * 0.88, h * 0.32, ramp("crystal", 5)[3])
    for x in (0.37, 0.62):
        c.rect(w * x, h * 0.24, w * x + 3, h * 0.52, ramp(WOOD, 4)[1])
    c.rect(w * 0.3, h * 0.52, w * 0.7, h * 0.58, ramp(WOOD, 4)[3])
    c.poly([(0, h * 0.2), (w * 0.5, 0), (w, h * 0.2)], ramp("#5A6A7A", 4)[2])
    c.rect(0, h * 0.18, w, h * 0.22, ramp(DARK, 4)[0])
    return c.finish(darker(DARK, 0.5))


def dock_lamp(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 5)
    c.cylinder(w * 0.4, h * 0.14, w * 0.6, h, [mix(x, (40, 40, 50), 0.4) for x in iron])
    c.rect(w * 0.24, h - 10, w * 0.76, h, iron[1])
    glow(c, w * 0.5, h * 0.08, w * 0.24)
    for x in (0.24, 0.72):
        c.rect(w * x, h * 0.02, w * x + 3, h * 0.14, iron[0])
    c.rect(w * 0.2, h * 0.13, w * 0.8, h * 0.15, iron[1])
    c.rect(w * 0.2, 0, w * 0.8, h * 0.02, iron[1])
    c.line([(w * 0.6, h * 0.3), (w * 0.92, h * 0.3), (w * 0.92, h * 0.36)], iron[0], 2)
    return c.finish(darker(IRON, 0.4))


def pallet_sacks(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    boards(c, 0, h * 0.8, w, h, WOOD, vertical=True, width=16)
    c.rect(0, h * 0.8, w, h * 0.84, ramp(WOOD, 4)[3])
    for x, y in ((0.18, 0.8), (0.5, 0.8), (0.82, 0.8), (0.34, 0.45), (0.66, 0.45)):
        sack(c, w * x, h * y, w * 0.32, h * 0.38, rnd.choice(["#C8B48A", "#B8A47A"]))
    return c.finish(darker("#5A4A3A", 0.5))


def chain_pile(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    rust = ramp("#7A5A4A", 5)
    for _ in range(40):
        x = w * 0.5 + rnd.gauss(0, w * 0.2)
        y = h - abs(rnd.gauss(0, h * 0.3)) - 6
        if rnd.random() < 0.5:
            c.ellipse(x, y, 6, 4, rust[rnd.randint(1, 3)])
            c.ellipse(x, y, 3, 1.5, rust[0])
        else:
            c.ellipse(x, y, 3, 5, rust[rnd.randint(1, 3)])
            c.ellipse(x, y, 1, 2.5, rust[0])
    c.rect(w * 0.1, h - 4, w * 0.9, h, rust[1])
    return c.finish(darker("#3A2E2A", 0.5))


def tool_rack(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for x in (0.1, 0.9):
        post(c, w * x, 0, h, 8, WOOD)
    c.rect(0, h * 0.1, w, h * 0.16, ramp(WOOD, 4)[2])
    iron = ramp(IRON, 4)
    for k in range(4):
        x = w * (0.24 + 0.17 * k)
        c.line([(x, h * 0.16), (x, h * 0.7)], iron[2], 4)
        c.ellipse(x, h * 0.72, 7, 5, iron[1])
        c.ellipse(x, h * 0.72, 3, 2, "#2A2622")
    c.line([(w * 0.84, h * 0.16), (w * 0.84, h * 0.5)], "#3A3434", 1)
    c.blob(w * 0.84, h * 0.54, 7, 6, iron)
    return c.finish(darker(DARK, 0.5))


def propeller_spare(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for k, (x, y) in enumerate(((0.02, 0.56), (0.5, 0.6))):
        b = crate((int(w * 0.46), int(h * 0.4)), rnd)
        c.img.alpha_composite(b, (int(w * x), int(h * y)))
    cx, cy = w * 0.5, h * 0.46
    wood = ramp("#8A5A3A", 5)
    for k in range(4):
        a = k / 4.0 * 2 * math.pi + 0.3
        pts = [(cx, cy), (cx + math.cos(a - 0.18) * w * 0.44, cy + math.sin(a - 0.18) * h * 0.44),
               (cx + math.cos(a + 0.12) * w * 0.46, cy + math.sin(a + 0.12) * h * 0.46)]
        pts = [(x, min(h - 2, y)) for x, y in pts]
        c.poly(pts, wood[2])
        c.poly(pts[:2] + [(cx + math.cos(a) * w * 0.3, cy + math.sin(a) * h * 0.3)], wood[3])
    c.blob(cx, cy, 12, 12, ramp(COPPER, 4))
    return c.finish(darker(DARK, 0.5))


def ruin_wall(size, rnd, heights, slit=False):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = material("wall_stone", size)
    mask = Image.new("L", size, 0)
    pts = [(0, h)]
    n = len(heights)
    for i, hh in enumerate(heights):
        pts += [(w * i / n, h - hh * h), (w * (i + 1) / n, h - hh * h)]
    pts.append((w, h))
    ImageDraw.Draw(mask).polygon([(round(x), round(y)) for x, y in pts], fill=255)
    c.img.paste(stone, (0, 0), mask)
    for i, hh in enumerate(heights):
        c.rect(w * i / n, h - hh * h, w * (i + 1) / n, h - hh * h + 3, ramp("stone", 4)[3])
    if slit:
        c.rect(w * 0.6, h * 0.3, w * 0.64, h * 0.62, "#2A2226")
    for _ in range(4):
        rock_shape(c, rnd.uniform(w * 0.05, w * 0.95), h, rnd.uniform(16, 30), rnd.uniform(8, 16), "stone")
    sand = ramp("sand", 4)
    c.poly([(0, h), (w * 0.2, h - 10), (w * 0.5, h - 6), (w * 0.8, h - 12), (w, h)], sand[2])
    return c.finish(darker("stone_dark", 0.45))


def dead_shrub(size, rnd, dense=False):
    w, h = size
    c = Canvas(w, h, rnd)
    dry = ramp("#8A7A60", 4)
    for k in range(10 if dense else 6):
        a = -math.pi / 2 + rnd.uniform(0.1, 0.9)
        length = h * rnd.uniform(0.6, 0.95)
        x1, y1 = w * 0.3 + math.cos(a) * length * 1.3, h + math.sin(a) * length
        c.line([(w * 0.3, h), (min(w - 2, x1), max(2, y1))], dry[rnd.randint(1, 3)], 2)
        for s in range(3):
            t = rnd.uniform(0.3, 0.9)
            bx, by = w * 0.3 + (x1 - w * 0.3) * t, h + (y1 - h) * t
            c.line([(bx, by), (min(w - 2, bx + rnd.uniform(4, 12)), by - rnd.uniform(2, 8))], dry[2], 1)
    if dense:
        c.line([(w * 0.3, h), (w * 0.05, h * 0.5)], dry[0], 2)
    return c.finish(darker("#5A4A3A", 0.5))


def sandbags(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    for row in range(3):
        for k in range(6 - row):
            x = w * (0.1 + 0.16 * k + 0.08 * row)
            y = h - row * h * 0.3
            sack(c, x, y, w * 0.17, h * 0.34, rnd.choice(["#C8B48A", "#B8A47A", "#A8946A"]))
    sand = ramp("sand", 4)
    c.poly([(0, h), (w * 0.1, h * 0.7), (w * 0.4, h * 0.8), (w * 0.7, h * 0.9), (w, h)], sand[2])
    return c.finish(darker("#5A4A3A", 0.5))


def broken_spears(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 4)
    c.poly([(w * 0.04, h * 0.7), (w * 0.94, h * 0.84), (w * 0.94, h * 0.9), (w * 0.04, h * 0.76)], wood[2])
    c.line([(w * 0.1, h), (w * 0.2, h * 0.7)], wood[1], 5)
    c.line([(w * 0.86, h), (w * 0.8, h * 0.84)], wood[1], 5)
    for k in range(5):
        x = w * (0.16 + 0.17 * k)
        top = h * rnd.uniform(0.0, 0.5)
        c.line([(x, h), (x + rnd.uniform(-12, 12), top)], ramp("#C8A06A", 4)[rnd.randint(1, 3)], 3)
    c.line([(w * 0.2, h * 0.96), (w * 0.9, h * 0.6)], ramp("#C8A06A", 4)[2], 3)
    return c.finish(darker(DARK, 0.5))


def ruined_arch(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = material("wall_stone", size)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    md.rectangle((w * 0.06, h * 0.3, w * 0.26, h), fill=255)
    md.pieslice((w * 0.06, h * 0.06, w * 0.94, h * 0.9), 180, 248, fill=255)
    md.ellipse((w * 0.26, h * 0.26, w * 0.74, h * 1.1), fill=0)
    md.rectangle((w * 0.66, h * 0.62, w * 0.86, h), fill=255)
    c.img.paste(stone, (0, 0), mask)
    for _ in range(9):
        rock_shape(c, rnd.uniform(w * 0.3, w * 0.98), h, rnd.uniform(20, 46), rnd.uniform(10, 26), "stone")
    sand = ramp("sand", 4)
    c.poly([(0, h), (w * 0.3, h - 8), (w * 0.7, h - 14), (w, h)], sand[2])
    return c.finish(darker("stone_dark", 0.45))


def cart_wreck(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#8A7A60", 5)
    c.poly([(w * 0.06, h * 0.5), (w * 0.8, h * 0.36), (w * 0.84, h * 0.6), (w * 0.1, h * 0.76)], wood[2])
    boards(c, w * 0.12, h * 0.44, w * 0.76, h * 0.62, "#8A7A60", vertical=True, width=14)
    c.ellipse(w * 0.66, h * 0.66, h * 0.3, h * 0.3, wood[1])
    c.ellipse(w * 0.66, h * 0.66, h * 0.2, h * 0.2, (0, 0, 0))
    hole = Image.new("L", size, 0)
    ImageDraw.Draw(hole).ellipse((w * 0.66 - h * 0.2, h * 0.66 - h * 0.2, w * 0.66 + h * 0.2, h * 0.66 + h * 0.2), fill=255)
    c.img.paste(Image.new("RGBA", size, (0, 0, 0, 0)), (0, 0), hole)
    c.draw = ImageDraw.Draw(c.img)
    for k in range(3):
        a = k / 3.0 * 2 * math.pi + 0.4
        c.line([(w * 0.66, h * 0.66), (w * 0.66 + math.cos(a) * h * 0.28, h * 0.66 + math.sin(a) * h * 0.28)], wood[0], 3)
    c.line([(w * 0.06, h * 0.6), (w * 0.0 + 2, h * 0.9)], wood[1], 4)
    c.poly([(w * 0.24, h * 0.4), (w * 0.3, h * 0.46), (w * 0.27, h * 0.5)], "#AE4A3E")
    sand = ramp("sand", 4)
    c.poly([(0, h), (w * 0.2, h * 0.76), (w * 0.5, h * 0.82), (w * 0.9, h * 0.86), (w, h)], sand[2])
    return c.finish(darker("#5A4A3A", 0.5))


def broken_pillar(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("stone", 5)
    c.cylinder(w * 0.2, h * 0.16, w * 0.8, h, stone)
    c.poly([(w * 0.2, h * 0.16), (w * 0.36, h * 0.06), (w * 0.5, h * 0.14), (w * 0.64, 0), (w * 0.8, h * 0.12)], stone[3])
    for y in (0.4, 0.7):
        c.rect(w * 0.2, h * y, w * 0.8, h * y + 2, stone[0])
    c.rect(w * 0.1, h - 10, w * 0.9, h, stone[1])
    return c.finish(darker("stone_dark", 0.45))


def garde_crate(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    a = crate(size, rnd)
    c.img = a
    c.draw = ImageDraw.Draw(c.img)
    red = ramp("#AE4A3E", 4)
    c.poly([(w * 0.5, h * 0.5), (w * 0.2, h * 0.4), (w * 0.28, h * 0.56)], red[1])
    c.poly([(w * 0.5, h * 0.5), (w * 0.8, h * 0.4), (w * 0.72, h * 0.56)], red[1])
    c.ellipse(w * 0.5, h * 0.52, 4, 4, red[2])
    for x, y in ((0.04, 0.2), (0.86, 0.2), (0.04, 0.84), (0.86, 0.84)):
        c.rect(w * x, h * y, w * x + 8, h * y + 8, ramp(IRON, 4)[1])
    return c.finish(darker(DARK, 0.5))


def fallen_tree(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    bark = ramp("#6A5440", 5)
    c.cylinder(w * 0.16, h * 0.56, w * 0.98, h, bark, vertical=False)
    c.ellipse(w * 0.98, h * 0.78, 10, h * 0.22, ramp("#C8A070", 4)[2])
    soil = ramp("#5A4632", 5)
    c.blob(w * 0.12, h * 0.5, w * 0.11, h * 0.48, soil[1:])
    for k in range(9):
        a = -math.pi / 2 + (k - 4) * 0.35
        c.line([(w * 0.12, h * 0.5), (w * 0.12 + math.cos(a) * w * 0.12, h * 0.5 + math.sin(a) * h * 0.5)], bark[1], 3)
    for _ in range(14):
        c.blob(rnd.uniform(w * 0.2, w * 0.9), h * 0.58 + rnd.uniform(-2, 3), rnd.uniform(5, 10), 4, ramp("#6E8C4A", 4))
    for x in (0.4, 0.62):
        c.rect(w * x, h * 0.48, w * x + 3, h * 0.58, "#E8DCC0")
        c.blob(w * x + 1, h * 0.46, 7, 4, ramp("#B8643A", 4))
    return c.finish(darker("#3A2E26", 0.5))


def stump(size, rnd, rotten=False):
    w, h = size
    c = Canvas(w, h, rnd)
    bark = ramp("#6A5440", 5)
    c.cylinder(w * 0.15, h * 0.3, w * 0.85, h, bark)
    c.poly([(w * 0.05, h), (w * 0.15, h * 0.7), (w * 0.2, h)], bark[1])
    c.poly([(w * 0.95, h), (w * 0.85, h * 0.7), (w * 0.8, h)], bark[1])
    if rotten:
        c.poly([(w * 0.15, h * 0.3), (w * 0.3, h * 0.12), (w * 0.44, h * 0.3), (w * 0.6, h * 0.08), (w * 0.85, h * 0.3)], bark[2])
        c.ellipse(w * 0.5, h * 0.36, w * 0.24, h * 0.1, "#2A2018")
        f = Image.new("RGBA", size, (0, 0, 0, 0))
        fc = Canvas(w, h, rnd)
        for k in range(5):
            a = math.pi * (0.15 + 0.7 * k / 4.0)
            fc.line([(w * 0.5, h * 0.36), (w * 0.5 - math.cos(a) * w * 0.4, h * 0.36 - math.sin(a) * h * 0.34)], "#5E8A3A", 3)
        c.img.alpha_composite(fc.img)
        del f
    else:
        c.ellipse(w * 0.5, h * 0.3, w * 0.35, h * 0.12, ramp("#C8A070", 4)[2])
        for r in (0.26, 0.17, 0.08):
            c.ellipse(w * 0.5, h * 0.3, w * r, h * r * 0.34, ramp("#C8A070", 4)[1 + int(r * 10) % 2])
        for _ in range(6):
            c.blob(rnd.uniform(w * 0.2, w * 0.8), h * rnd.uniform(0.5, 0.9), 5, 4, ramp("#6E8C4A", 4))
    return c.finish(darker("#3A2E26", 0.5))


def log_hollow(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    bark = ramp("#6A5440", 5)
    c.cylinder(w * 0.04, h * 0.2, w * 0.96, h, bark, vertical=False)
    c.ellipse(w * 0.06, h * 0.6, h * 0.24, h * 0.4, bark[3])
    c.ellipse(w * 0.06, h * 0.6, h * 0.16, h * 0.3, "#1E1814")
    for _ in range(20):
        c.blob(rnd.uniform(w * 0.15, w * 0.9), h * 0.22 + rnd.uniform(-2, 4), rnd.uniform(5, 10), 4,
               ramp(rnd.choice(["#6E8C4A", "#3E5A34"]), 4))
    return c.finish(darker("#3A2E26", 0.5))


def training_dummy(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    post(c, w * 0.5, h * 0.4, h, 12, WOOD)
    straw = ramp("#D8B860", 5)
    cloth = ramp("#B8A88A", 5)
    c.blob(w * 0.5, h * 0.42, w * 0.32, h * 0.2, cloth[1:])
    c.rect(w * 0.08, h * 0.32, w * 0.92, h * 0.38, straw[2])
    c.blob(w * 0.5, h * 0.14, w * 0.18, h * 0.11, cloth[1:])
    for x, y in ((0.36, 0.4), (0.6, 0.48), (0.46, 0.12)):
        c.line([(w * x, h * y), (w * x + 8, h * y + 6)], "#5A4A3A", 1)
    c.rect(w * 0.6, h * 0.36, w * 0.74, h * 0.46, ramp("#8A6A8A", 4)[2])
    for x in (0.08, 0.92):
        for k in range(3):
            c.line([(w * x, h * 0.36), (w * x + (k - 1) * 4, h * 0.42)], straw[3], 1)
    return c.finish(darker("#4A3A30", 0.5))


def target_board(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 4)
    c.line([(w * 0.2, h), (w * 0.4, h * 0.4)], wood[1], 4)
    c.line([(w * 0.8, h), (w * 0.6, h * 0.4)], wood[1], 4)
    c.line([(w * 0.5, h * 0.98), (w * 0.5, h * 0.5)], wood[1], 4)
    for k, col in enumerate(("#E8DCC0", "#B5443A", "#E8DCC0", "#B5443A", "#E8DCC0")):
        r = w * 0.44 * (1.0 - 0.2 * k)
        c.ellipse(w * 0.5, h * 0.38, r, r, ramp(col, 4)[2])
    c.line([(w * 0.52, h * 0.36), (w * 0.7, h * 0.26)], wood[2], 2)
    return c.finish(darker(DARK, 0.5))


def hunting_stand(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#8A6A4C", 5)
    for x0, x1 in ((0.1, 0.22), (0.9, 0.78), (0.3, 0.34), (0.7, 0.66)):
        c.line([(w * x0, h), (w * x1, h * 0.3)], wood[1 if x0 in (0.3, 0.7) else 2], 6)
    boards(c, w * 0.12, h * 0.28, w * 0.88, h * 0.34, "#8A6A4C", vertical=False, width=6)
    for x in range(int(w * 0.14), int(w * 0.86), 12):
        c.rect(x, h * 0.16, x + 4, h * 0.28, wood[2])
    c.rect(w * 0.12, h * 0.14, w * 0.88, h * 0.17, wood[3])
    c.poly([(w * 0.06, h * 0.06), (w * 0.94, h * 0.06), (w * 0.88, h * 0.14), (w * 0.12, h * 0.14)], ramp("#6A5A4A", 4)[2])
    c.line([(w * 0.44, h), (w * 0.46, h * 0.34)], wood[2], 3)
    c.line([(w * 0.58, h), (w * 0.56, h * 0.34)], wood[2], 3)
    for y in range(int(h * 0.4), h, 26):
        c.rect(w * 0.45, y, w * 0.57, y + 3, wood[3])
    c.line([(w * 0.22, h * 0.6), (w * 0.78, h * 0.6)], wood[1], 3)
    return c.finish(darker(DARK, 0.5))


def cairn(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    y = h
    for k in range(6):
        sw = w * (0.9 - 0.12 * k) * rnd.uniform(0.9, 1.05)
        sh = h * rnd.uniform(0.12, 0.17)
        x = w * 0.5 + rnd.uniform(-4, 4)
        rock_shape(c, x, y, sw, sh, rnd.choice(["stone", mix("stone", "stone_dark", 0.3)]))
        y -= sh * 0.95
    return c.finish(darker("stone_dark", 0.45))


def stone_steps(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp(mix("stone", "stone_dark", 0.2), 5)
    for k in range(3):
        y1 = h - k * h * 0.3
        y0 = y1 - h * 0.34
        x0, x1 = w * (0.04 + 0.06 * k), w * (0.96 - 0.06 * k)
        c.rect(x0, y0, x1, y1, stone[2])
        c.rect(x0, y0, x1, y0 + 4, stone[4])
        c.rect(x0, y1 - 3, x1, y1, stone[0])
    grass = ramp("#87A35E", 4)
    for _ in range(40):
        x = rnd.uniform(0, w)
        c.line([(x, h), (x + rnd.uniform(-3, 3), h - rnd.uniform(4, 10))], grass[rnd.randint(1, 3)])
    return c.finish(darker("stone_dark", 0.45))


def old_telescope(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 4)
    for x in (0.12, 0.88, 0.5):
        c.line([(w * x, h), (w * 0.5, h * 0.52)], wood[1], 4)
    copper = ramp(COPPER, 5)
    c.line([(w * 0.24, h * 0.62), (w * 0.84, h * 0.06)], copper[2], 12)
    c.line([(w * 0.24, h * 0.62), (w * 0.84, h * 0.06)], copper[3], 4)
    c.line([(w * 0.8, h * 0.1), (w * 0.92, h * 0.0 + 2)], copper[1], 14)
    c.blob(w * 0.5, h * 0.52, 6, 6, ramp(IRON, 4))
    return c.finish(darker(COPPER, 0.4))


def log_pile_forest(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    log_pile(c, 0, w, h, rows=4, r=14)
    return c.finish(darker("#3A2E26", 0.5))


def wind_grass(size, rnd, long=False):
    """Herbe dure couchée vers la droite par le vent, sable au pied."""
    import hd2d_nature
    img = hd2d_nature.grass_clump(size, rnd, "#B8A868", count=30 if long else 22, slant=0.35 if long else 0.25)
    w, h = size
    c = Canvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(img)
    c.poly([(w * 0.1, h), (w * 0.4, h - 4), (w * 0.8, h - 3), (w * 0.95, h)], ramp("sand", 4)[2])
    return c.img


RECIPES = {
    "buildings/warehouse_main_side": warehouse_main_side, "buildings/warehouse_wing_side": warehouse_wing_side,
    "buildings/cafe_side": cafe_side, "buildings/shop_bakery_side": shop_bakery_side,
    "buildings/shop_bookshop_side": shop_bookshop_side, "buildings/stone_house_side": stone_house_side,
    "buildings/projection_hall_side": projection_hall_side, "buildings/limashenka_house_side": limashenka_house_side,
    "buildings/tool_shed_side": tool_shed_side,
    "buildings/house_timber_a": house_timber_a, "buildings/house_timber_a_side": house_timber_a_side,
    "buildings/house_timber_b": house_timber_b, "buildings/house_timber_b_side": house_timber_b_side,
    "buildings/clockmaker": clockmaker, "buildings/clockmaker_side": clockmaker_side,
    "buildings/house_narrow": house_narrow, "buildings/house_narrow_side": house_narrow_side,
    "buildings/butcher": butcher, "buildings/butcher_side": butcher_side,
    "buildings/inn": inn, "buildings/inn_side": inn_side,
    "buildings/harbor_office": harbor_office, "buildings/harbor_office_side": harbor_office_side,
    "buildings/port_hangar": port_hangar, "buildings/port_hangar_side": port_hangar_side,
    "buildings/boiler_workshop": boiler_workshop, "buildings/boiler_workshop_side": boiler_workshop_side,
    "buildings/house_stone_b": house_stone_b, "buildings/house_stone_b_side": house_stone_b_side,
    "props/chimney_brick": chimney, "props/chimney_stone": lambda s, r: chimney(s, r, "stone"),
    "props/dormer_slate": lambda s, r: dormer(s, r, "roof_slate"),
    "props/dormer_tiles": lambda s, r: dormer(s, r, "roof_tiles"),
    "props/ivy_wall_a": ivy_wall, "props/ivy_wall_b": lambda s, r: ivy_wall(s, r, hanging=True),
    "props/warehouse_roof_deck": roof_deck, "props/wall_lantern": wall_lantern, "props/window_box": window_box,
    "props/hanging_sign_key": lambda s, r: hanging_sign(s, r, "key"),
    "props/hanging_sign_propeller": lambda s, r: hanging_sign(s, r, "propeller"),
    "props/drainpipe": drainpipe, "props/outdoor_stairs": outdoor_stairs, "props/awning_green": awning_green,
    "props/wheelbarrow": wheelbarrow, "props/firewood_pile": firewood_pile, "props/stump_axe": stump_axe,
    "props/rain_barrel": rain_barrel, "props/laundry_basket": laundry_basket, "props/toys_a": toys_a,
    "props/toys_b": toys_b, "props/bench_b": bench_b, "props/fence_low": fence_module,
    "props/bucket": bucket, "props/watering_can": watering_can, "props/garden_tools": garden_tools,
    "props/scarecrow": scarecrow, "props/kids_table": kids_table, "props/flower_pots": flower_pots,
    "props/crate_stack": crate_stack, "props/bench_stone": bench_stone, "props/sack_apples": sack_apples,
    "props/cafe_table": cafe_table, "props/barrel_group": barrel_group, "props/sacks_pile": sacks_pile,
    "props/hand_cart": hand_cart, "props/fountain": fountain, "props/notice_board": notice_board,
    "props/market_stall_fruit": market_stall_fruit, "props/market_stall_cloth": market_stall_cloth,
    "props/bread_rack": bread_rack, "props/book_cart": book_cart, "props/menu_slate": menu_slate,
    "props/street_lamp_double": street_lamp_double, "props/planter_long": planter_long, "props/bunting": bunting,
    "props/crate_apples": crate_apples, "props/broom_bucket": broom_bucket,
    "props/mooring_tower": mooring_tower, "props/cargo_net": cargo_net, "props/crystal_crates": crystal_crates,
    "props/fuel_barrels": fuel_barrels, "props/rope_coil": rope_coil, "props/steam_pipes": steam_pipes,
    "props/workbench": workbench, "props/luggage": luggage, "props/ticket_booth": ticket_booth,
    "props/dock_lamp": dock_lamp, "props/pallet_sacks": pallet_sacks, "props/chain_pile": chain_pile,
    "props/tool_rack": tool_rack, "props/propeller_spare": propeller_spare,
    "props/ruined_wall_b": lambda s, r: ruin_wall(s, r, [0.5, 0.8, 0.6, 0.35, 0.45]),
    "props/ruined_wall_c": lambda s, r: ruin_wall(s, r, [0.9, 0.98, 0.7, 0.5], slit=True),
    "props/dead_shrub_a": dead_shrub, "props/dead_shrub_b": lambda s, r: dead_shrub(s, r, dense=True),
    "props/wind_grass_a": wind_grass, "props/wind_grass_b": lambda s, r: wind_grass(s, r, long=True),
    "props/sandbags": sandbags, "props/broken_spears": broken_spears, "props/ruined_arch": ruined_arch,
    "props/cart_wreck": cart_wreck, "props/broken_pillar": broken_pillar, "props/garde_crate": garde_crate,
    "props/fallen_tree": fallen_tree, "props/stump_a": stump, "props/stump_b": lambda s, r: stump(s, r, rotten=True),
    "props/log_hollow": log_hollow, "props/training_dummy": training_dummy, "props/target_board": target_board,
    "props/hunting_stand": hunting_stand, "props/cairn": cairn,
    "props/rope_fence": lambda s, r: fence_module(s, r, rope=True), "props/stone_steps": stone_steps,
    "props/old_telescope": old_telescope, "props/log_pile_forest": log_pile_forest,
}
