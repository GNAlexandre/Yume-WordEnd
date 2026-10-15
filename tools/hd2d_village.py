"""Remplaçants HD-2D du village des hommes-bêtes, du café à clochette et de la maison Limashenka (lot C2 ;
cahier n° 5, docs/ASSETS_HD2D_ILE68.md, lot R3, sections 5.3 à 5.5), pour les noms que les plans des cartes
`village`, `cafe` et `maison_limashenka` (docs/lore/CARTE.md, section 5) citent et que le cahier n'a pas
encore livrés :

- le dehors : six chaumières, maisons et granges avec leur flanc (`buildings/`), deux matières de volume
  (`buildings/materials/roof_thatch`, `wall_wattle_daub`), la clôture, les ruches, la charrette de foin, la
  meule et le lavoir (`props/`) ;
- le café : le sol de terre cuite, le lambris sombre, la porte à rideau, le comptoir, les tables, l'étagère
  aux bouteilles, la vitrine à gâteaux, les verres de jus, l'ardoise du menu ;
- la maison Limashenka : le papier peint, les volets, l'horloge (fermée, ouverte, son balancier), la boîte
  à outils, le guéridon, le portrait de famille, le tapis du salon.

Une image livrée (ChatGPT) remplace le remplaçant du même nom, sans toucher au code, et sa recette s'en va
avec lui. Ces recettes sont lues par tools/hd2d_assets.py (recipes) ; leurs entrées du manifeste (lot R3) sont
MANIFEST ci-dessous (les images d'intérieur passent par les listes de tools/hd2d_interior.py : tailles,
profondeurs, scènes). Le résultat est déterministe (graine tirée du nom de chaque image)."""

import math
import random

from PIL import Image, ImageChops, ImageDraw

import hd2d_ground
from hd2d_art import Canvas, darker, fractal, mix, noise, paste_wrap, posterize, ramp, rgba, threshold
from hd2d_interior_props import DARK, HONEY, IRON, MID, PALE, inset, outline_finish, paper, wood
from hd2d_props import boards
from hd2d_town import material, roof_edge, soft_shade, wall_area

PPM = 96
THATCH = "#A38E5C"
DAUB = "#CFB68C"
BEAM = "#6A4A32"
SLATE_GLASS = "#2E4058"
COPPER = "#B0703A"


# --- Matières de volume (192 × 192, sans raccord) ----------------------------------------------------------


def roof_thatch(size, rnd):
    """Chaume de paille dorée grisée par la pluie, en rangées de bottes parallèles au bas de l'image, mousse
    verte par plaques, quelques brins plus clairs."""
    w, h = size
    tones = ramp(THATCH, 6, spread=0.4)
    img = posterize(fractal(size, (6, 6), rnd, 3), tones[1:5], dither=44)
    d = ImageDraw.Draw(img)
    rows = h // 24
    for r in range(rows):
        y0 = r * 24
        d.rectangle((0, y0, w, y0 + 1), fill=rgba(tones[0]))
        d.rectangle((0, y0 + 2, w, y0 + 3), fill=rgba(tones[5]))
        for _ in range(56):
            x = rnd.randrange(w)
            y = y0 + rnd.randint(4, 18)
            length = rnd.randint(5, 12)
            col = tones[rnd.choice([1, 2, 3, 4, 5])]
            tilt = rnd.choice([-1, 0, 0, 1])
            for dx in (-w, 0, w):
                d.line((x + dx, y, x + dx + tilt, min(y + length, y0 + 23)), fill=rgba(col))
    moss = threshold(fractal(size, (7, 7), rnd, 3, gain=0.7), 214)
    img.paste(Image.new("RGBA", size, rgba("#6A7F3E")), (0, 0), moss.point(lambda v: int(v * 0.8)))
    return img


def wall_wattle_daub(size, rnd):
    """Torchis ocre clair grumeleux, brins de paille visibles, petites fissures, sans colombages (ils sont dans
    les façades)."""
    w, h = size
    tones = ramp(DAUB, 6, spread=0.3)
    img = posterize(fractal(size, (5, 5), rnd, 3), tones[1:5], dither=42)
    d = ImageDraw.Draw(img)
    for _ in range(110):
        x, y = rnd.randrange(w), rnd.randrange(h)
        length = rnd.randint(3, 8)
        col = tones[rnd.choice([0, 0, 5, 5, 4])]
        angle = rnd.uniform(0, math.pi)
        for dx in (-w, 0, w):
            for dy in (-h, 0, h):
                d.line((x + dx, y + dy, x + dx + math.cos(angle) * length, y + dy + math.sin(angle) * length),
                       fill=rgba(col))
    crack = rgba(mix(tones[0], "#5A4630", 0.4))
    for _ in range(5):
        x, y = rnd.randrange(w), rnd.randrange(h)
        pts = [(x, y)]
        for _k in range(rnd.randint(3, 5)):
            x += rnd.randint(-8, 8)
            y += rnd.randint(5, 14)
            pts.append((x, y))
        for dx in (-w, 0, w):
            for dy in (-h, 0, h):
                d.line([(px + dx, py + dy) for px, py in pts], fill=crack)
    return img


hd2d_ground.RECIPES.update({
    "buildings/materials/roof_thatch": roof_thatch,
    "buildings/materials/wall_wattle_daub": wall_wattle_daub,
})


# --- Chaumières, grange, maison de pierre, appentis : façade et flanc ------------------------------------------


def _fringe(c, p0, p1, thick, rnd):
    """Brins de chaume qui dépassent sous la bordure du toit (effiloché : le chaume ne finit pas net)."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    n = math.hypot(dx, dy) or 1.0
    nx, ny = dy / n, -dx / n
    if ny < 0:
        nx, ny = -nx, -ny
    tones = ramp(THATCH, 6, spread=0.4)
    k = 0.0
    while k < n:
        x = p0[0] + dx * k / n + nx * thick
        y = p0[1] + dy * k / n + ny * thick
        length = rnd.randint(3, 8)
        c.line([(x, y), (x + nx * length + rnd.uniform(-1, 1), y + ny * length)], tones[rnd.choice([0, 1, 2, 3, 4])],
               1 + (rnd.random() < 0.3))
        k += rnd.uniform(2, 5)


def _roof_long(c, w, roof, thick, rnd, fringe=True):
    """Bordure d'un toit long (faîtage parallèle à la façade) en haut de l'image."""
    mask = Image.new("L", (c.w, c.h), 0)
    ImageDraw.Draw(mask).rectangle((0, 0, w, thick), fill=255)
    c.img.paste(material(roof, (c.w, c.h)), (0, 0), mask)
    tones = ramp(DARK, 4)
    c.rect(0, thick - 2, w, thick + 1, tones[0])
    if fringe:
        _fringe(c, (0, thick - 4), (w, thick - 4), 4, rnd)
        c.rect(0, thick - 2, w, thick + 1, tones[0])


def _plinth(c, w, h, plinth, rnd):
    if not plinth:
        return
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rectangle((0, h - plinth, w, h), fill=255)
    c.img.paste(material("wall_stone", (w, h)), (0, 0), mask)
    c.rect(0, h - plinth, w, h - plinth + 3, ramp("stone", 4)[3])
    c.rect(0, h - plinth + 3, w, h - plinth + 4, ramp("stone", 4)[0])


def _timber(c, rnd, x0, x1, y0, y1, posts, rails, braces=True):
    """Colombages bruns un peu de travers : poteaux, lisses, quelques écharpes."""
    beam = ramp(BEAM, 5, spread=0.4)
    for y in rails:
        j = rnd.randint(-2, 2)
        c.rect(x0, y + j, x1, y + j + 8, beam[1])
        c.rect(x0, y + j, x1, y + j + 2, beam[3])
    xs = []
    for x in posts:
        j = rnd.randint(-3, 3)
        xs.append(x + j)
        c.rect(x + j, y0, x + j + 9, y1, beam[1])
        c.rect(x + j, y0, x + j + 2, y1, beam[3])
        c.rect(x + j + 7, y0, x + j + 9, y1, beam[0])
    if braces and len(xs) > 1 and len(rails) > 0:
        low = rails[-1]
        for a, b in zip(xs[:-1], xs[1:]):
            if rnd.random() < 0.7:
                c.line([(a + 9, low), (b, y0 + (low - y0) * 0.4)], beam[1], 6)


def dark_window(c, x, y, w, h, shutters=None, rnd=None):
    """Fenêtre éteinte : vitres sombres bleutées, un reflet clair ; volets de bois si demandé."""
    frame = ramp(DARK, 5)
    glass = ramp(SLATE_GLASS, 5, spread=0.4)
    if shutters:
        boards(c, x - 3 - w * 0.42, y - 2, x - 3, y + h + 3, shutters, width=6)
        boards(c, x + w + 3, y - 2, x + w + 3 + w * 0.42, y + h + 3, shutters, width=6)
    c.rect(x - 3, y - 3, x + w + 3, y + h + 5, frame[1])
    c.rect(x, y, x + w, y + h, glass[1])
    c.rect(x, y, x + w, y + h * 0.4, glass[2])
    c.line([(x + 3, y + h * 0.5), (x + w * 0.45, y + 3)], glass[4], 2)
    c.line([(x + w * 0.5, y + h * 0.55), (x + w * 0.8, y + 4)], glass[3], 1)
    c.rect(x + w / 2.0 - 1, y, x + w / 2.0 + 1, y + h, frame[2])
    c.rect(x, y + h / 2.0 - 1, x + w, y + h / 2.0 + 1, frame[2])
    c.rect(x - 5, y + h + 3, x + w + 5, y + h + 7, frame[3])


def plank_door(c, x, y, w, h, base="wood_dark", handle=True, arch=False):
    """Porte de planches, chambranle de pierre ; poignée de laiton."""
    wood_tones = ramp(base, 5)
    c.rect(x - 4, y - 4, x + w + 4, y + h, ramp("stone_dark", 4)[2])
    boards(c, x, y, x + w, y + h, base, width=9)
    c.rect(x, y + h * 0.2, x + w, y + h * 0.2 + 4, wood_tones[0])
    c.rect(x, y + h * 0.75, x + w, y + h * 0.75 + 4, wood_tones[0])
    if handle:
        c.rect(x + w * 0.76, y + h * 0.5, x + w * 0.76 + 4, y + h * 0.5 + 4, ramp("brass", 3)[2])


def pots(c, x, y_base, rnd, count=3):
    """Pots de fleurs au seuil."""
    for k in range(count):
        px = x + k * 20 + rnd.randint(-2, 2)
        pot = ramp("#A8552E", 4)
        c.rect(px, y_base - 14, px + 14, y_base, pot[2])
        c.rect(px, y_base - 14, px + 14, y_base - 12, pot[3])
        petal = rnd.choice(["#D86A5A", "#E8C84A", "#8A7ACF", "#F0E0D0"])
        for _ in range(4):
            c.ellipse(px + rnd.randint(2, 12), y_base - 18 - rnd.randint(0, 6), 3, 3, petal)
        c.line([(px + 7, y_base - 14), (px + 7, y_base - 20)], "#4E7A3A", 1)


def cottage(size, rnd, wall, roof, kind, wall_m, thick, plinth=0, features=None, beams=None):
    """Façade sud : long (jusqu'à l'égout) ou pignon (jusqu'au faîtage), mur d'une matière de volume, soubassement,
    colombages (beams : (poteaux, lisses)), détails, puis le toit : bordure épaisse (le chaume descend bas)."""
    w, h = size
    c = Canvas(w, h, rnd)
    wall_px = round(wall_m * PPM)
    if kind == "long":
        top = thick
        pts = [(0, h), (0, 0), (w, 0), (w, h)]
    else:
        top = h - wall_px
        pts = [(0, h), (0, top), (w / 2.0, 0), (w, top), (w, h)]
    mask = wall_area(c, pts, wall)
    _plinth(c, w, h, plinth, rnd)
    if beams:
        posts, rails = beams
        _timber(c, rnd, 0, w, top, h - plinth, posts, rails)
    if features:
        features(c, w, h, top)
    if kind == "long":
        _roof_long(c, w, roof, thick, rnd, fringe=roof == "roof_thatch")
    else:
        for p0, p1 in (((0, top + 2), (w / 2.0, 0)), ((w, top + 2), (w / 2.0, 0))):
            roof_edge(c, p0, p1, roof, thick)
            if roof == "roof_thatch":
                _fringe(c, p0, p1, thick, rnd)
    c.img.alpha_composite(Image.new("RGBA", (w, 6), (30, 24, 36, 70)), (0, h - 6))
    img = c.img
    img.putalpha(mask)
    return img


def cottage_side(size, rnd, wall, roof, gable_wall_m, thick, plinth=0, features=None):
    """Flanc est : pignon jusqu'au faîtage (gable_wall_m : mur plein sur cette hauteur) ou mur gouttereau jusqu'à
    l'égout ; modelé doux et symétrique (rien qui ne supporte d'être retourné)."""
    w, h = size
    c = Canvas(w, h, rnd)
    if gable_wall_m is not None:
        wall_top = h - round(gable_wall_m * PPM)
        pts = [(0, h), (0, wall_top), (w / 2.0, 0), (w, wall_top), (w, h)]
    else:
        wall_top = thick
        pts = [(0, h), (0, 0), (w, 0), (w, h)]
    mask = wall_area(c, pts, wall)
    _plinth(c, w, h, plinth, rnd)
    if features:
        features(c, w, h, wall_top)
    if gable_wall_m is not None:
        for p0, p1 in (((0, wall_top + 2), (w / 2.0, 0)), ((w, wall_top + 2), (w / 2.0, 0))):
            roof_edge(c, p0, p1, roof, thick)
            if roof == "roof_thatch":
                _fringe(c, p0, p1, thick, rnd)
    else:
        _roof_long(c, w, roof, thick, rnd, fringe=roof == "roof_thatch")
    soft_shade(c, mask)
    img = c.img
    img.putalpha(mask)
    return img


# Chaumière de torchis ocre clair sur soubassement de pierres, colombages bruns irréguliers, toit de chaume épais
# qui descend bas, porte basse de planches, une petite fenêtre éteinte, pots de fleurs au seuil.
def cottage_thatch_a(size, rnd):
    def features(c, w, h, top):
        plank_door(c, 96, h - 154, 66, 154 - 56 + 56)
        dark_window(c, 296, h - 226, 56, 64, "#6E7A58", rnd)
        c.rect(88, h - 62, 170, h - 56, ramp("stone", 4)[2])
        pots(c, 300, h - 56, rnd, 2)
        pots(c, 70, h - 56, rnd, 1)
    return cottage(size, rnd, "wall_wattle_daub", "roof_thatch", "pignon", 2.5, 34, 56, features,
                   beams=([0, 150, 270, 471], [h_ for h_ in (300, 380)]))


def cottage_thatch_a_side(size, rnd):
    def features(c, w, h, top):
        dark_window(c, 300, h - 150, 46, 50, "#6E7A58", rnd)
        _timber(c, rnd, 0, w, top, h - 44, [0, 160, 330, 471], [h - 120])
    return cottage_side(size, rnd, "wall_wattle_daub", "roof_thatch", None, 30, 44, features)


# Longue chaumière basse : deux portes, trois petites fenêtres éteintes à volets, un banc de bois contre le mur,
# une corde à linge tendue d'un crochet à l'autre (sans linge), la bordure du chaume en haut de l'image.
def cottage_thatch_b(size, rnd):
    def features(c, w, h, top):
        for x in (96, 470):
            plank_door(c, x, h - 156, 62, 156, "wood")
        for x in (250, 360, 570):
            dark_window(c, x, h - 170, 44, 50, "#7A5A46", rnd)
        bench = ramp(HONEY, 5)
        c.rect(180, h - 62, 300, h - 54, bench[3])
        c.rect(180, h - 62, 300, h - 60, bench[4])
        c.rect(186, h - 54, 192, h - 20, bench[1])
        c.rect(288, h - 54, 294, h - 20, bench[1])
        # La corde à linge : deux crochets, une corde qui plonge au milieu.
        c.rect(10, 60, 16, 68, ramp("iron", 4)[1])
        c.rect(w - 16, 60, w - 10, 68, ramp("iron", 4)[1])
        pts = [(13 + (w - 26) * k / 24.0, 64 + 14 * math.sin(math.pi * k / 24.0)) for k in range(25)]
        c.line(pts, ramp("#B8A47A", 4)[2], 1)
    return cottage(size, rnd, "wall_wattle_daub", "roof_thatch", "long", 2.5, 40, 36, features,
                   beams=([0, 180, 360, 540, 663], [150]))


def cottage_thatch_b_side(size, rnd):
    def features(c, w, h, top):
        dark_window(c, 214, h - 150, 52, 56, "#7A5A46", rnd)
        _timber(c, rnd, 0, w, top, h - 36, [0, 235, 471], [top + 30])
    return cottage_side(size, rnd, "wall_wattle_daub", "roof_thatch", 2.5, 36, 36, features)


# Petite chaumière penchée, torchis fissuré rapiécé, une lucarne dans le chaume, porte peinte en vert passé.
def cottage_thatch_c(size, rnd):
    def features(c, w, h, top):
        # Pièces de torchis rapiécé, plus claires ou plus sombres.
        for (x0, y0, x1, y1, col) in ((20, h - 230, 90, h - 170, "#B89E76"), (290, h - 160, 360, h - 100, "#DBC49C"),
                                       (110, h - 110, 160, h - 70, "#C2A87E")):
            c.rect(x0, y0, x1, y1, col)
            c.rect(x0, y0, x1, y0 + 2, darker(col, 0.8))
            c.rect(x0, y1 - 2, x1, y1, darker(col, 0.7))
        plank_door(c, 160, h - 154, 62, 154, "#5E8A5A")
        dark_window(c, 280, h - 250, 44, 48, "#8A6A4E", rnd)
        # La lucarne dans le chaume : un petit toit, une vitre sombre.
        cx = w / 2.0
        c.poly([(cx - 30, 150), (cx + 30, 150), (cx + 26, 112), (cx, 92), (cx - 26, 112)], ramp(BEAM, 5)[1])
        c.rect(cx - 20, 118, cx + 20, 150, ramp(SLATE_GLASS, 5)[1])
        c.line([(cx - 20, 150), (cx - 6, 122)], ramp(SLATE_GLASS, 5)[4], 2)
        c.line([(cx - 32, 114), (cx, 90)], ramp(THATCH, 5)[2], 6)
        c.line([(cx + 32, 114), (cx, 90)], ramp(THATCH, 5)[1], 6)
        pots(c, 238, h - 4, rnd, 1)
    return cottage(size, rnd, "wall_wattle_daub", "roof_thatch", "pignon", 2.25, 32, 44, features,
                   beams=([0, 130, 250, 375], [h_ for h_ in (340,)]))


def cottage_thatch_c_side(size, rnd):
    def features(c, w, h, top):
        _timber(c, rnd, 0, w, top, h - 30, [0, 120, 250, 375], [h - 90])
    return cottage_side(size, rnd, "wall_wattle_daub", "roof_thatch", None, 28, 30, features)


# Grange de planches brunes délavées, grande porte à deux battants entrouverte sur la pénombre et le foin, petite
# porte à côté, fourche appuyée.
def village_barn(size, rnd):
    def features(c, w, h, top):
        x0, x1 = 250, 510
        c.rect(x0 - 8, h - 232, x1 + 8, h, ramp(DARK, 5)[1])
        c.rect(x0, h - 224, x1, h, (26, 20, 18, 255))
        # Le foin dans la pénombre.
        hay = ramp("#C8A850", 5)
        for k in range(70):
            px = rnd.randint(x0 + 6, x1 - 6)
            py = rnd.randint(h - 110, h - 4)
            c.line([(px, py), (px + rnd.randint(-8, 8), py - rnd.randint(4, 14))], hay[rnd.choice([1, 2, 3])], 1)
        c.rect(x0, h - 30, x1, h, hay[1])
        for k in range(50):
            px = rnd.randint(x0, x1)
            c.line([(px, h - 30), (px + rnd.randint(-6, 6), h - rnd.randint(34, 70))], hay[rnd.choice([2, 3, 4])], 1)
        # Les deux battants : celui de gauche presque fermé, celui de droite grand ouvert (de biais).
        boards(c, x0, h - 224, x0 + 118, h, "wood_dark", width=10)
        c.rect(x0, h - 190, x0 + 118, h - 182, ramp(DARK, 5)[0])
        c.rect(x0, h - 70, x0 + 118, h - 62, ramp(DARK, 5)[0])
        c.poly([(x1 - 4, h - 224), (x1 + 38, h - 214), (x1 + 38, h - 18), (x1 - 4, h)], ramp(DARK, 5)[2])
        c.line([(x1 + 4, h - 190), (x1 + 34, h - 184)], ramp(DARK, 5)[0], 5)
        plank_door(c, 590, h - 168, 70, 168, "wood")
        # La fourche appuyée contre le mur, à gauche.
        iron = ramp(IRON, 4)
        c.line([(140, h - 10), (160, h - 190)], ramp(HONEY, 5)[2], 5)
        for dx in (-9, 0, 9):
            c.line([(160 + dx * 0.5, h - 190), (160 + dx * 1.4, h - 226)], iron[2], 2)
        c.line([(148, h - 190), (172, h - 190)], iron[2], 3)
    return cottage(size, rnd, "wall_planks", "roof_thatch", "long", 3.5, 38, 28, features)


def village_barn_side(size, rnd):
    def features(c, w, h, top):
        # La lucarne du fenil, foin qui dépasse.
        cx = w / 2.0
        c.rect(cx - 36, h - 450, cx + 36, h - 366, (26, 20, 18, 255))
        c.rect(cx - 40, h - 456, cx + 40, h - 450, ramp(DARK, 5)[2])
        c.rect(cx - 40, h - 366, cx + 40, h - 360, ramp(DARK, 5)[2])
        hay = ramp("#C8A850", 5)
        for _ in range(40):
            px = rnd.randint(int(cx) - 30, int(cx) + 30)
            c.line([(px, h - 380), (px + rnd.randint(-5, 5), h - 360 + rnd.randint(2, 14))], hay[rnd.choice([2, 3, 4])], 1)
        for x in (60, w - 72):
            c.rect(x, top + 10, x + 12, h - 24, ramp(DARK, 5)[1])
    return cottage_side(size, rnd, "wall_planks", "roof_thatch", 3.5, 38, 24, features)


# Maison de pierre un peu plus aisée, toit de bardeaux, porte à heurtoir, deux fenêtres à volets, une plus petite à
# l'étage dans le pignon, lierre au coin.
def village_house_stone(size, rnd):
    def features(c, w, h, top):
        plank_door(c, 200, h - 168, 78, 168, "wood_dark", handle=False)
        c.ellipse(240, h - 92, 5, 5, ramp("iron", 4)[1])
        c.ellipse(240, h - 92, 2, 2, ramp("iron", 4)[3])
        dark_window(c, 60, h - 184, 56, 66, "#6E7A8A", rnd)
        dark_window(c, 366, h - 184, 56, 66, "#6E7A8A", rnd)
        dark_window(c, 224, top + 40, 32, 40, "#6E7A8A", rnd)
        # Lierre au coin.
        green = ["#4F6B3A", "#3E5A34", "#A85A3A"]
        for _ in range(120):
            px = rnd.randint(w - 40, w - 2)
            py = rnd.randint(top + 60, h - 4)
            c.ellipse(px, py, rnd.randint(2, 4), rnd.randint(2, 3), rnd.choice(green))
    return cottage(size, rnd, "wall_stone", "roof_shingles", "pignon", 3.0, 20, 0, features)


def village_house_stone_side(size, rnd):
    def features(c, w, h, top):
        dark_window(c, 130, h - 170, 50, 60, "#6E7A8A", rnd)
        dark_window(c, 310, h - 170, 50, 60, "#6E7A8A", rnd)
    return cottage_side(size, rnd, "wall_stone", "roof_shingles", None, 22, 0, features)


# Appentis à bois de planches grises, bûches empilées sous l'avancée, une hache plantée dans un billot devant.
def village_shed(size, rnd):
    def features(c, w, h, top):
        # Les bûches empilées sous l'avancée.
        logs = ramp(HONEY, 5)
        for row in range(4):
            for k in range(11):
                lx = 30 + k * 28 + (row % 2) * 14
                ly = h - 18 - row * 26
                if lx > w - 150:
                    continue
                c.ellipse(lx, ly, 12, 12, logs[1])
                c.ellipse(lx, ly, 9, 9, logs[3])
                c.ellipse(lx, ly, 4, 4, logs[2])
        # Billot et hache à droite, devant.
        c.rect(w - 100, h - 44, w - 52, h, ramp(HONEY, 5)[2])
        c.rect(w - 100, h - 44, w - 52, h - 38, ramp(HONEY, 5)[4])
        c.line([(w - 76, h - 44), (w - 64, h - 110)], ramp(HONEY, 5)[1], 4)
        c.poly([(w - 78, h - 108), (w - 50, h - 100), (w - 52, h - 82), (w - 70, h - 84)], ramp(IRON, 4)[2])
    return cottage(size, rnd, "wall_planks_b", "roof_shingles", "long", 2.25, 22, 0, features)


def village_shed_side(size, rnd):
    def features(c, w, h, top):
        for x in (20, w - 32):
            c.rect(x, top + 30, x + 12, h - 16, ramp(DARK, 5)[1])
        c.line([(w * 0.2, h - 30), (w * 0.8, h - 120)], ramp(DARK, 5)[1], 6)
    return cottage_side(size, rnd, "wall_planks_b", "roof_shingles", 2.25, 22, 0, features)


# --- Panneaux du village ---------------------------------------------------------------------------------------


def fence_wattle(size, rnd):
    """Clôture de branches tressées entre des piquets, quelques brins cassés ; sans raccord à gauche et à droite."""
    w, h = size
    c = Canvas(w, h, rnd)
    stake = ramp(HONEY, 5, spread=0.45)
    twig = [ramp("#8E6A44", 5)[k] for k in (1, 2, 3)] + [ramp("#B8905C", 5)[2]]
    posts = [6, 54, 102, 150, 186]
    top = 14
    for row in range(8):
        y = top + 8 + row * 8
        for k in range(len(posts) - 1):
            x0, x1 = posts[k], posts[k + 1]
            if rnd.random() < 0.06:
                continue
            over = (row + k) % 2
            col = twig[rnd.randrange(len(twig))]
            c.line([(x0, y + (2 if over else 0)), ((x0 + x1) / 2.0, y + (0 if over else 2)), (x1, y + (2 if over else 0))],
                   col, 4)
    for x in posts:
        c.cylinder(x - 3, top - 6 - rnd.randint(0, 6), x + 3, h, stake)
    for _ in range(3):
        x = rnd.randint(10, w - 12)
        c.line([(x, top + 6), (x + rnd.randint(-8, 8), top - 4)], twig[3], 1)
    return c.finish(darker(HONEY, 0.4))


def beehives(size, rnd):
    """Trois ruches de paille tressée sur une planche (le miel du marché, V3)."""
    w, h = size
    c = Canvas(w, h, rnd)
    board = ramp(DARK, 5)
    c.rect(2, h - 20, w - 2, h - 8, board[2])
    c.rect(2, h - 20, w - 2, h - 18, board[4])
    c.rect(8, h - 8, 18, h, board[1])
    c.rect(w - 18, h - 8, w - 8, h, board[1])
    straw = ramp("#C8A650", 6, spread=0.45)
    for k, cx in enumerate((28, 77, 126)):
        r = 22 - (k % 2) * 2
        for band in range(6):
            y1 = h - 20 - band * 10
            half = r * (1 - band * 0.13)
            c.poly([(cx - half, y1), (cx + half, y1), (cx + half * 0.88, y1 - 10), (cx - half * 0.88, y1 - 10)],
                   straw[2 + (band % 2)])
            c.rect(cx - half, y1 - 1, cx + half, y1, straw[0])
            c.rect(cx - half, y1 - 9, cx - half * 0.2, y1 - 2, straw[4])
        c.ellipse(cx, h - 20 - 60 - 1, 4, 3, straw[1])
        c.ellipse(cx, h - 30, 6, 5, (40, 28, 20, 255))
    return c.finish(darker("#A08040", 0.5))


def cart_hay(size, rnd):
    """Charrette de bois à deux grandes roues chargée de foin, brancards posés au sol."""
    w, h = size
    c = Canvas(w, h, rnd)
    wd = ramp(HONEY, 5, spread=0.45)
    hay = ramp("#C8A650", 6, spread=0.45)
    # Brancards au sol, à gauche.
    c.line([(6, h - 6), (110, h - 52)], wd[1], 7)
    c.line([(6, h - 12), (110, h - 58)], wd[2], 4)
    # Caisse et chargement de foin.
    c.rect(96, h - 86, w - 18, h - 52, wd[2])
    c.rect(96, h - 86, w - 18, h - 82, wd[3])
    for x in range(100, w - 18, 14):
        c.rect(x, h - 82, x + 1, h - 54, wd[0])
    c.poly([(90, h - 80), (96, h - 118), (150, h - 160), (214, h - 164), (w - 24, h - 128), (w - 14, h - 84)], hay[2])
    for _ in range(180):
        x = rnd.randint(96, w - 22)
        y = rnd.randint(h - 160, h - 84)
        c.line([(x, y), (x + rnd.randint(-9, 9), y - rnd.randint(3, 10))], hay[rnd.choice([1, 2, 3, 4, 5])], 1)
    # Les roues : la plus proche est vue de face.
    wheel_x, wheel_y, r = 176, h - 30, 30
    c.ellipse(wheel_x, wheel_y, r, r, wd[0])
    c.ellipse(wheel_x, wheel_y, r - 5, r - 5, (0, 0, 0, 0))
    c.ellipse(wheel_x, wheel_y, r - 5, r - 5, wd[2])
    c.ellipse(wheel_x, wheel_y, r - 12, r - 12, (0, 0, 0, 0))
    for k in range(8):
        a = k * math.pi / 4.0
        c.line([(wheel_x, wheel_y), (wheel_x + math.cos(a) * (r - 4), wheel_y + math.sin(a) * (r - 4))], wd[1], 3)
    c.ellipse(wheel_x, wheel_y, 6, 6, wd[0])
    c.ellipse(wheel_x, wheel_y, 3, 3, ramp(IRON, 4)[2])
    return c.finish(darker("#8A6A44", 0.4))


def haystack(size, rnd):
    """Meule de foin ronde, une fourche plantée dedans."""
    w, h = size
    c = Canvas(w, h, rnd)
    hay = ramp("#C8A650", 6, spread=0.5)
    c.blob(w / 2.0, h * 0.6, w * 0.46, h * 0.38, hay[1:5])
    c.poly([(w * 0.04, h * 0.6), (w * 0.96, h * 0.6), (w * 0.99, h - 8), (w * 0.01, h - 8)], hay[2])
    c.ellipse(w / 2.0, h - 9, w * 0.49, 9, hay[2])
    c.rect(w * 0.04, h * 0.6, w * 0.16, h - 8, hay[1])
    for _ in range(150):
        x = rnd.uniform(w * 0.08, w * 0.92)
        y = rnd.uniform(h * 0.2, h - 6)
        if c.img.getpixel((int(x), int(y)))[3]:
            c.line([(x, y), (x + rnd.uniform(-6, 6), y - rnd.uniform(3, 9))], hay[rnd.choice([1, 3, 4, 5])], 1)
    c.line([(w * 0.7, h * 0.3), (w * 0.82, h * 0.02)], ramp(HONEY, 5)[2], 4)
    for dx in (-8, 0, 8):
        c.line([(w * 0.82 + dx * 0.4, h * 0.04), (w * 0.82 + dx * 0.8, 0)], ramp(IRON, 4)[2], 2)
    return c.finish(darker("#8A6A34", 0.4))


def washing_trough(size, rnd):
    """Lavoir : longue auge de pierre pleine d'eau, planche à laver, un panier de linge mouillé (original)."""
    w, h = size
    c = Canvas(w, h, rnd)
    st = ramp("stone", 6, spread=0.45)
    c.rect(4, h * 0.42, w - 4, h, st[2])
    c.rect(4, h * 0.42, w - 4, h * 0.42 + 6, st[4])
    c.rect(4, h * 0.42 + 6, w - 4, h * 0.42 + 8, st[0])
    for x in range(10, w - 10, 40):
        c.rect(x, h * 0.42 + 10, x + 1, h - 2, st[1])
    c.rect(4, h - 6, w - 4, h, st[1])
    # L'eau : un liseré bleuté sous le bord, reflet.
    water = ramp("#6E94B0", 5)
    c.rect(12, h * 0.42 + 6, w - 12, h * 0.42 + 14, water[2])
    c.rect(18, h * 0.42 + 7, w * 0.5, h * 0.42 + 8, water[4])
    # Planche à laver, inclinée dans l'auge.
    c.poly([(w * 0.4, h * 0.46), (w * 0.4 + 46, h * 0.46), (w * 0.4 + 54, h * 0.9), (w * 0.4 + 6, h * 0.9)],
           ramp(HONEY, 5)[2])
    for k in range(7):
        c.rect(w * 0.4 + 8 + k * 0.7, h * 0.52 + k * 8, w * 0.4 + 48 + k * 0.7, h * 0.52 + k * 8 + 2, ramp(HONEY, 5)[0])
    # Panier de linge mouillé, à droite.
    basket = ramp("#B08A50", 5)
    c.rect(w - 76, h * 0.12, w - 24, h * 0.44, basket[2])
    for y in range(int(h * 0.16), int(h * 0.44), 6):
        c.rect(w - 76, y, w - 24, y + 1, basket[0])
    c.ellipse(w - 50, h * 0.12, 26, 6, "#E6E0D2")
    c.ellipse(w - 56, h * 0.1, 12, 5, "#C8D4E0")
    return c.finish(darker("stone_dark", 0.5))


# --- Le café : sol, mur, porte, mobilier ----------------------------------------------------------------------


def floor_terracotta(size, rnd):
    """Carreaux carrés de terre cuite, rouge-brun et ocre mêlés, usés, quelques-uns fêlés."""
    w, h = size
    cell = w / 20.0
    img = Image.new("RGBA", size, rgba("#5A3A2E"))
    d = ImageDraw.Draw(img)
    palette = ["#A8553A", "#B8643E", "#9A4A36", "#C07A4A", "#B06A46", "#8E4632"]
    for j in range(20):
        for i in range(20):
            base = rnd.choice(palette)
            tones = ramp(base, 5, spread=0.3)
            x0, y0 = round(i * cell), round(j * cell)
            x1, y1 = round((i + 1) * cell), round((j + 1) * cell)
            tile = posterize(noise((x1 - x0, y1 - y0), (2, 2), rnd), tones[1:4], dither=50)
            img.paste(tile, (x0, y0))
            d.rectangle((x0, y0, x1 - 1, y0), fill=rgba(tones[4]))
            d.rectangle((x0, y0, x0, y1 - 1), fill=rgba(tones[3]))
            d.rectangle((x0, y1 - 1, x1 - 1, y1 - 1), fill=rgba(tones[0]))
            d.rectangle((x1 - 1, y0, x1 - 1, y1 - 1), fill=rgba(tones[0]))
            if rnd.random() < 0.07:
                cx, cy = rnd.randint(x0 + 3, x1 - 4), rnd.randint(y0 + 3, y1 - 4)
                d.line((cx, cy, cx + rnd.randint(-8, 8), cy + rnd.randint(4, 12)), fill=rgba(tones[0]))
    worn = threshold(fractal(size, (4, 4), rnd, 2), 215)
    img.paste(Image.new("RGBA", size, rgba("#8A7A66")), (0, 0), worn.point(lambda v: int(v * 0.25)))
    return img


def wall_panel_dark(size, rnd):
    """Lambris de bois sombre jusqu'à 1,4 m, cimaise, enduit ocre au-dessus enfumé, plinthe (le café) ; se raccorde à
    gauche et à droite."""
    w, h = size
    img = Image.new("RGBA", size, rgba("#C9A878"))
    plaster = ramp("#C9A878", 6, spread=0.3)
    upper = posterize(noise((w, h), (8, 4), rnd), plaster[1:4], dither=40)
    img.paste(upper, (0, 0))
    # La fumée : le haut de l'enduit s'assombrit.
    smoke = Image.linear_gradient("L").rotate(180).resize((w, 80)).point(lambda v: int(v * 0.5))
    img.paste(Image.new("RGBA", (w, 80), rgba("#4A3A30")), (0, 0), smoke)
    d = ImageDraw.Draw(img)
    wd = ramp("#5A3E2C", 6, spread=0.45)
    wainscot_top = h - 134
    # La corniche.
    d.rectangle((0, 0, w, 6), fill=rgba(wd[2]))
    d.rectangle((0, 6, w, 8), fill=rgba(wd[0]))
    # Le lambris : panneaux de 64 px (6 par largeur), cimaise au-dessus, plinthe en bas.
    d.rectangle((0, wainscot_top, w, h), fill=rgba(wd[2]))
    for k in range(6):
        x0 = k * 64
        d.rectangle((x0 + 6, wainscot_top + 14, x0 + 58, h - 22), fill=rgba(wd[1]))
        d.rectangle((x0 + 7, wainscot_top + 15, x0 + 57, wainscot_top + 16), fill=rgba(wd[0]))
        d.rectangle((x0 + 7, wainscot_top + 15, x0 + 8, h - 23), fill=rgba(wd[0]))
        d.rectangle((x0 + 57, h - 24, x0 + 58, h - 23), fill=rgba(wd[4]))
        d.rectangle((x0 + 8, h - 24, x0 + 57, h - 23), fill=rgba(wd[3]))
        d.rectangle((x0 + 58, wainscot_top + 15, x0 + 59, h - 23), fill=rgba(wd[3]))
        for _ in range(3):
            gx = x0 + rnd.randint(12, 52)
            d.line((gx, wainscot_top + 20, gx + rnd.randint(-1, 1), h - 28), fill=rgba(wd[2]))
    d.rectangle((0, wainscot_top, w, wainscot_top + 7), fill=rgba(wd[3]))
    d.rectangle((0, wainscot_top, w, wainscot_top), fill=rgba(wd[5]))
    d.rectangle((0, wainscot_top + 7, w, wainscot_top + 8), fill=rgba(wd[0]))
    d.rectangle((0, h - 14, w, h), fill=rgba(wd[3]))
    d.rectangle((0, h - 14, w, h - 13), fill=rgba(wd[4]))
    d.rectangle((0, h - 2, w, h), fill=rgba(wd[0]))
    return img


def door_backroom(size, rnd):
    """Passage vers l'arrière-boutique masqué d'un rideau de toile rayée, chambranle de bois (VEX)."""
    w, h = size
    c = Canvas(w, h, rnd)
    frame = ramp(DARK, 5, spread=0.42)
    c.rect(0, 0, w, 12, frame[2])
    c.rect(0, 0, w, 2, frame[4])
    for x0 in (0, w - 9):
        c.rect(x0, 0, x0 + 9, h, frame[2])
        c.rect(x0, 0, x0 + 2, h, frame[3])
    # Tringle, rideau de toile rayée écru et bleu passé qui tombe en plis.
    c.rect(6, 12, w - 6, 16, ramp(IRON, 4)[1])
    cream, blue = ramp("#E6DCC6", 4, spread=0.2), ramp("#5E7EA0", 4, spread=0.3)
    for x in range(9, w - 9):
        stripe = ((x - 9) // 8) % 2
        fold = 0.5 + 0.5 * math.sin((x - 9) * 0.55)
        tone = (blue if stripe else cream)[1 + int(fold * 2)]
        c.rect(x, 16, x + 1, h - 3 - (4 if (x // 11) % 2 else 0), tone)
    c.rect(9, h - 8, w - 9, h - 3, ramp("#E6DCC6", 4)[0])
    return outline_finish(c)


def cafe_counter(size, rnd):
    """Comptoir de bois sombre ciré, usé au bord : une grande cafetière de cuivre sur un réchaud de cristal, des
    tasses retournées, un bocal de biscuits, un tonnelet à robinet de bois au bout."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 2, 34, w - 2, h, "#4A3326", top=14, grain=14)
    # Face à panneaux.
    for x0 in range(10, w - 40, 62):
        inset(c, x0, 56, x0 + 54, h - 12, t)
    c.rect(2, h - 6, w - 2, h, t[0])
    # Réchaud de cristal et cafetière de cuivre.
    cu = ramp(COPPER, 5)
    c.rect(40, 26, 74, 36, ramp("#8A7A68", 4)[2])
    c.rect(48, 20, 66, 30, ramp("#FFE6A6", 5)[3])
    c.rect(38, 4, 76, 26, cu[2])
    c.rect(38, 4, 46, 26, cu[3])
    c.rect(70, 4, 76, 26, cu[1])
    c.rect(40, 0, 74, 6, cu[3])
    c.rect(54, 0, 60, 3, cu[4])
    c.rect(76, 10, 90, 14, cu[2])
    c.rect(32, 8, 38, 20, cu[1])
    # Tasses retournées, bocal de biscuits.
    cup = ramp("#EAE2D0", 4)
    for x in (110, 126, 142):
        c.rect(x, 22, x + 12, 34, cup[2])
        c.rect(x, 22, x + 12, 24, cup[3])
        c.rect(x + 12, 26, x + 15, 31, cup[1])
    c.rect(168, 12, 196, 34, ramp("#A9B9C6", 4)[2])
    c.rect(166, 8, 198, 13, ramp(DARK, 4)[2])
    for _ in range(6):
        c.ellipse(rnd.randint(172, 192), rnd.randint(20, 32), 3, 2, ramp("#C8964A", 4)[2])
    # Tonnelet à robinet de bois, au bout (à droite).
    barrel = ramp("#8A5A3A", 5)
    c.cylinder(w - 78, 6, w - 28, 34, barrel)
    for y in (12, 28):
        c.rect(w - 78, y, w - 28, y + 3, ramp(IRON, 4)[0])
    c.rect(w - 30, 22, w - 20, 26, ramp(HONEY, 4)[2])
    return outline_finish(c)


def cafe_table_heavy(size, rnd):
    """Table carrée de bois épais, nappe à carreaux rouges et blancs, deux tasses."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#5A3E2C", 5, spread=0.4)
    for x in (6, w - 14):
        c.rect(x, h - 38, x + 8, h, t[1])
        c.rect(x, h - 38, x + 2, h, t[3])
    c.rect(2, 22, w - 2, h - 34, ramp("#C8503E", 5)[2])
    # Carreaux : rouge et blanc, un peu en perspective.
    red, white = ramp("#C8503E", 4), ramp("#F0E8DA", 4)
    for j in range(4):
        for i in range(8):
            c.rect(4 + i * 13.5, 24 + j * 6, 4 + (i + 1) * 13.5, 24 + (j + 1) * 6,
                   white[2] if (i + j) % 2 else red[2])
    c.rect(2, 22, w - 2, 24, white[3])
    c.rect(2, h - 38, w - 2, h - 34, red[0])
    for k in range(w // 6):
        c.rect(2 + k * 6, h - 34, 2 + k * 6 + 3, h - 28 - (k % 2) * 2, red[1])
    cup = ramp("#EAE2D0", 4)
    for x in (34, 74):
        c.rect(x, 12, x + 12, 24, cup[2])
        c.rect(x, 12, x + 12, 14, cup[3])
        c.rect(x + 12, 15, x + 15, 20, cup[1])
        c.rect(x + 2, 14, x + 10, 15, "#3A2418")
    return outline_finish(c)


def juice_glasses(size, rnd):
    """Trois verres de jus de fruits (orange, rouge, jaune) et une carafe (VEX : les jus offerts « pour la maison »)."""
    w, h = size
    c = Canvas(w, h, rnd)
    glass = ramp("#C8D8E4", 4, spread=0.3)
    for x, juice in ((4, "#E8902E"), (14, "#B8383E"), (24, "#E8C440")):
        c.rect(x, 12, x + 8, h, glass[2])
        c.rect(x + 1, 15, x + 7, h - 2, juice)
        c.rect(x + 1, 15, x + 7, 17, mix(juice, "#FFFFFF", 0.35))
        c.rect(x, 12, x + 1, h, glass[3])
    c.rect(36, 6, 46, h, glass[2])
    c.rect(37, 14, 45, h - 2, "#E8902E")
    c.rect(34, 4, 48, 8, glass[3])
    c.rect(46, 10, 49, 18, glass[2])
    return outline_finish(c)


def cafe_bottle_shelf(size, rnd):
    """Étagères de bois derrière le comptoir : bouteilles d'alcool de toutes formes (le soir), pots de café, piles de
    tasses, chopes pendues."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 4, 4, w - 4, h, "#4A3326", grain=0)
    inner = ramp("#2E2018", 4)
    c.rect(10, 12, w - 10, h - 8, inner[1])
    shelves = [h * 0.28, h * 0.52, h * 0.76]
    for y in shelves:
        c.rect(8, y, w - 8, y + 6, t[3])
        c.rect(8, y, w - 8, y + 1, t[4])
        c.rect(8, y + 5, w - 8, y + 6, t[0])
    colors = ["#2E6A4A", "#8A3A2E", "#B8863E", "#3E5A8A", "#6A3A5A", "#C8B46A", "#4A3A2E"]
    rows = [(12, shelves[0]), (shelves[0] + 6, shelves[1]), (shelves[1] + 6, shelves[2])]
    # Rangée du haut : chopes pendues.
    for k in range(6):
        x = 18 + k * 28
        c.rect(x, 14, x + 2, 24, ramp(IRON, 4)[1])
        c.rect(x - 4, 24, x + 10, 38, ramp("#8A8678", 4)[2])
        c.rect(x - 4, 24, x + 10, 27, ramp("#8A8678", 4)[3])
        c.rect(x + 10, 28, x + 14, 34, ramp("#8A8678", 4)[1])
    # Rangées : bouteilles, pots de café, piles de tasses.
    for r, (y0, y1) in enumerate(rows[1:]):
        x = 16
        while x < w - 28:
            kind = rnd.choice(["bottle", "bottle", "jar", "cups"]) if r == 0 else rnd.choice(["jar", "cups", "bottle"])
            if kind == "bottle":
                bh = rnd.randint(34, int(y1 - y0 - 6))
                col = rnd.choice(colors)
                bt = ramp(col, 4)
                c.rect(x, y1 - bh, x + 12, y1, bt[1])
                c.rect(x + 3, y1 - bh - 10, x + 9, y1 - bh, bt[2])
                c.rect(x + 3, y1 - bh - 13, x + 9, y1 - bh - 10, ramp("#C8B890", 3)[1])
                c.rect(x + 1, y1 - bh + 8, x + 3, y1 - 6, bt[3])
                x += 16
            elif kind == "jar":
                c.rect(x, y1 - 30, x + 20, y1, ramp("#A9B9C6", 4)[2])
                c.rect(x + 2, y1 - 24, x + 18, y1 - 2, ramp("#5A3A26", 4)[2])
                c.rect(x - 1, y1 - 34, x + 21, y1 - 30, ramp(DARK, 4)[2])
                x += 26
            else:
                for k in range(4):
                    c.rect(x, y1 - 8 - k * 7, x + 18, y1 - 2 - k * 7, ramp("#EAE2D0", 4)[2 - k % 2])
                x += 24
    return outline_finish(c)


def cafe_cake_case(size, rnd):
    """Vitrine à gâteaux sous cloche de verre : une tarte aux pommes, des petits gâteaux à la crème."""
    w, h = size
    c = Canvas(w, h, rnd)
    c.rect(8, h - 10, w - 8, h, ramp("#EAE2D0", 4)[2])
    c.rect(8, h - 10, w - 8, h - 8, ramp("#EAE2D0", 4)[3])
    # La tarte aux pommes.
    c.rect(16, h - 22, 52, h - 10, ramp("#C8964A", 5)[2])
    c.ellipse(34, h - 22, 18, 5, ramp("#D8A85A", 4)[3])
    for k in range(5):
        c.ellipse(24 + k * 7, h - 22, 3, 2, ramp("#E8D8A0", 4)[3])
    # Petits gâteaux à la crème.
    for x in (60, 72, 82):
        c.rect(x, h - 20, x + 8, h - 10, ramp("#C8864A", 4)[2])
        c.ellipse(x + 4, h - 22, 5, 3, "#F4ECD8")
    # La cloche de verre.
    glass = ramp("#C8D8E4", 4, spread=0.3)
    c.line([(10, h - 10), (10, 24), (20, 8), (w - 20, 8), (w - 10, 24), (w - 10, h - 10)], glass[3], 2)
    c.line([(20, 20), (24, 14)], "#FFFFFF", 2)
    c.ellipse(w / 2.0, 6, 3, 3, ramp(DARK, 4)[2])
    return outline_finish(c)


def cafe_drinkers_table(size, rnd):
    """La table des buveurs : chopes renversées, cartes à jouer, un plat de saucisses entamé, flaques de bière."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#5A3E2C", 5, spread=0.4)
    for x in (8, w - 16):
        c.rect(x, h - 40, x + 8, h, t[1])
        c.rect(x, h - 40, x + 2, h, t[3])
    top = wood(c, 2, 24, w - 2, h - 34, "#6A4A34", top=8, grain=8)
    # Flaques de bière.
    beer = ramp("#C8963E", 4)
    c.ellipse(30, 44, 12, 4, beer[2])
    c.ellipse(112, 50, 14, 4, beer[2])
    # Chopes renversées.
    mug = ramp("#8A8678", 4)
    for x, y in ((50, 36), (96, 30), (128, 44)):
        c.rect(x, y, x + 14, y + 10, mug[2])
        c.rect(x + 14, y + 2, x + 18, y + 8, mug[1])
        c.rect(x, y, x + 3, y + 10, mug[3])
        c.ellipse(x + 14, y + 5, 1, 4, "#E8C060")
    # Cartes à jouer et plat de saucisses.
    for k, x in enumerate((70, 78, 86)):
        c.rect(x, 38 + k, x + 8, 48 + k, "#EAE2D0")
        c.rect(x + 2, 40 + k, x + 6, 44 + k, "#B03A3A")
    c.ellipse(24, 34, 18, 5, "#EAE2D0")
    for k in range(3):
        c.ellipse(18 + k * 6, 32 - k % 2, 7, 2, "#A8553A")
    return outline_finish(c)


def wallitem_menu_cafe(size, rnd):
    """Ardoise du menu : dessins à la craie d'une tasse fumante, d'une chope et d'une part de gâteau, traits de craie
    à la place des mots."""
    w, h = size
    c = Canvas(w, h, rnd)
    frame = ramp(DARK, 5, spread=0.42)
    c.rect(0, 0, w, h, frame[2])
    c.rect(0, 0, w, 2, frame[4])
    c.rect(4, 4, w - 4, h - 6, "#2C3A36")
    c.rect(4, 4, w - 4, 6, "#3A4A44")
    chalk = "#EAE6D8"
    # Une tasse fumante.
    c.rect(12, 22, 28, 34, chalk)
    c.rect(14, 24, 26, 32, "#2C3A36")
    c.line([(28, 25), (32, 25), (32, 30), (28, 30)], chalk, 1)
    c.line([(16, 18), (18, 12), (16, 8)], chalk, 1)
    c.line([(22, 18), (24, 12), (22, 8)], chalk, 1)
    c.line([(36, 22), (w - 10, 22)], chalk, 1)
    c.line([(36, 28), (w - 18, 28)], chalk, 1)
    # Une chope.
    c.rect(12, 46, 26, 62, chalk)
    c.rect(14, 48, 24, 60, "#2C3A36")
    c.line([(26, 50), (31, 50), (31, 58), (26, 58)], chalk, 1)
    c.line([(36, 52), (w - 10, 52)], chalk, 1)
    c.line([(36, 58), (w - 22, 58)], chalk, 1)
    # Une part de gâteau.
    c.poly([(12, 84), (30, 84), (24, 74), (12, 76)], chalk)
    c.line([(14, 80), (28, 80)], "#2C3A36", 1)
    c.line([(36, 80), (w - 10, 80)], chalk, 1)
    return c.finish(darker(DARK, 0.5))


# --- La maison Limashenka -------------------------------------------------------------------------------------


def wall_wallpaper_floral(size, rnd):
    """Papier peint à grandes fleurs fanées vert d'eau et rose sur fond crème, auréoles, plinthe et moulure (le salon
    des Limashenka) ; se raccorde à gauche et à droite."""
    w, h = size
    cream = ramp("#EEE4CC", 6, spread=0.22)
    img = posterize(noise(size, (8, 5), rnd), cream[1:4], dither=36)
    d = ImageDraw.Draw(img)
    # Moulure en haut, plinthe en bas.
    wd = ramp("#7A5A40", 5, spread=0.4)
    d.rectangle((0, 0, w, 7), fill=rgba(wd[3]))
    d.rectangle((0, 0, w, 1), fill=rgba(wd[4]))
    d.rectangle((0, 7, w, 8), fill=rgba(wd[0]))
    d.rectangle((0, h - 20, w, h), fill=rgba(wd[2]))
    d.rectangle((0, h - 20, w, h - 18), fill=rgba(wd[4]))
    d.rectangle((0, h - 18, w, h - 17), fill=rgba(wd[0]))
    d.rectangle((0, h - 2, w, h), fill=rgba(wd[0]))
    green, rose = ramp("#8AA896", 4, spread=0.3), ramp("#D89AA0", 4, spread=0.3)
    # Les fleurs : un motif de 96 px de large, en quinconce.
    for row, y in enumerate(range(34, h - 44, 66)):
        for col in range(4):
            cx = 24 + col * 96 + (48 if row % 2 else 0)
            cx %= w
            for dx in (-w, 0, w):
                x = cx + dx
                for k in range(5):
                    a = k * 2 * math.pi / 5 + 0.3 * row
                    px, py = x + math.cos(a) * 10, y + math.sin(a) * 10
                    d.ellipse((px - 6, py - 6, px + 6, py + 6), fill=rgba(rose[1 + (k % 2)]))
                d.ellipse((x - 4, y - 4, x + 4, y + 4), fill=rgba("#E8C86A"))
                for sx in (-1, 1):
                    d.polygon([(x, y + 12), (x + sx * 20, y + 24), (x + sx * 8, y + 32)], fill=rgba(green[1]))
                    d.line((x, y + 12, x + sx * 14, y + 26), fill=rgba(green[3]))
    # Auréoles d'humidité.
    damp = threshold(fractal(size, (3, 3), rnd, 2), 200)
    img.paste(Image.new("RGBA", size, rgba("#B8A07A")), (0, 0), damp.point(lambda v: int(v * 0.35)))
    return img


def window_shutters(size, rnd):
    """Fenêtre aux volets intérieurs de bois entrouverts, rais de lumière entre les lames (la maison qui se rouvre,
    cahier n° 1)."""
    w, h = size
    c = Canvas(w, h, rnd)
    frame = wood(c, 2, 2, w - 2, h, "#6A4A34", grain=0)
    # Le jour entre les volets : bande claire au milieu.
    c.rect(10, 10, w - 10, h - 12, ramp("#F4E8C0", 5)[3])
    c.rect(10, 10, w - 10, 30, ramp("#F4E8C0", 5)[4])
    # Les deux volets, entrouverts : des lames de bois de chaque côté.
    for x0, x1 in ((10, 40), (w - 40, w - 10)):
        boards(c, x0, 10, x1, h - 12, "#7A5A40", width=6)
    for y in (30, h - 44):
        c.rect(10, y, 40, y + 4, ramp(DARK, 5)[0])
        c.rect(w - 40, y, w - 10, y + 4, ramp(DARK, 5)[0])
    # Rais de lumière entre les lames.
    for x in (46, 54, 62, 70):
        c.line([(x, 14), (x + 6, h - 16)], "#FFF4C8", 1)
    c.rect(2, h - 10, w - 2, h, frame[3])
    return outline_finish(c)


def toolbox_gears(size, rnd):
    """Boîte à outils de bois ouverte posée par terre : pinces, tournevis, burette, et un sachet de papier d'où sortent
    des engrenages neufs (VEX : les pièces de rechange commandées)."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 4, 20, w - 4, h, "#7A5A40", top=6, grain=4)
    c.rect(4, 20, 8, h, t[2])
    c.rect(w - 8, 20, w - 4, h, t[1])
    c.rect(4, h - 8, w - 4, h, t[1])
    iron = ramp(IRON, 5)
    # Outils qui dépassent : pinces, tournevis, burette.
    c.line([(14, 22), (10, 6)], iron[2], 2)
    c.line([(18, 22), (22, 8)], iron[2], 2)
    c.rect(26, 8, 31, 22, ramp("#B8863E", 4)[2])
    c.rect(26, 4, 31, 9, iron[3])
    c.rect(36, 12, 42, 22, ramp("#B03A3A", 4)[2])
    c.line([(39, 12), (39, 4)], iron[3], 1)
    # Le sachet de papier et ses engrenages de laiton neufs.
    c.poly([(48, 26), (w - 10, 26), (w - 12, h - 8), (50, h - 8)], ramp("#D8C8A0", 4)[2])
    brass = ramp("#B4955E", 5)
    for cx, cy, r in ((58, 14, 8), (70, 8, 6), (66, 22, 5)):
        c.ellipse(cx, cy, r, r, brass[3])
        c.ellipse(cx, cy, r - 3, r - 3, brass[1])
        c.ellipse(cx, cy, 1, 1, brass[4])
        for k in range(8):
            a = k * math.pi / 4.0
            c.rect(cx + math.cos(a) * (r + 1) - 1, cy + math.sin(a) * (r + 1) - 1,
                   cx + math.cos(a) * (r + 1) + 1, cy + math.sin(a) * (r + 1) + 1, brass[2])
    return outline_finish(c)


def _clock(size, rnd, opened=False, swing=0):
    """Vieille horloge murale dans une grande caisse de bois sculpté de feuilles, cadran de laiton marqué de traits
    (aucun chiffre), aiguilles ouvragées, porte vitrée sur un balancier de laiton ; arrêtée (fermée), ou la caisse
    ouverte : engrenages de laiton, ressorts, vis, et au fond un peigne doré dans sa caisse de résonance."""
    w, h = size
    rnd = random.Random(4242)  # la même caisse dans les trois états et les quatre images du balancier
    c = Canvas(w, h, rnd)
    case = wood(c, 2, 2, w - 2, h, "#6A4A34", grain=6)
    # Le dessus et le pied de la caisse : corniche de feuilles sculptées.
    c.rect(0, 0, w, 10, case[3])
    c.rect(0, 0, w, 2, case[4])
    for k in range(7):
        c.ellipse(6 + k * 11, 12, 4, 3, case[3])
    brass = ramp("#C8A850", 6, spread=0.5)
    # Le cadran, en haut.
    cx, cy, r = w / 2.0, 40, 26
    c.ellipse(cx, cy, r + 3, r + 3, ramp("#4A3426", 4)[1])
    c.ellipse(cx, cy, r, r, brass[3])
    c.ellipse(cx, cy, r - 3, r - 3, brass[4])
    for k in range(12):
        a = k * math.pi / 6.0
        c.line([(cx + math.cos(a) * (r - 4), cy + math.sin(a) * (r - 4)),
                (cx + math.cos(a) * (r - 9), cy + math.sin(a) * (r - 9))], "#3A2A1E", 1 + (k % 3 == 0))
    if opened:
        # Caisse ouverte : engrenages, ressorts et vis à la place du cadran, le peigne doré au fond.
        c.ellipse(cx, cy, r - 3, r - 3, "#2A2018")
        for gx, gy, gr in ((cx - 9, cy - 4, 11), (cx + 11, cy + 5, 9), (cx + 2, cy + 14, 6)):
            c.ellipse(gx, gy, gr, gr, brass[3])
            c.ellipse(gx, gy, gr - 4, gr - 4, "#2A2018")
            c.ellipse(gx, gy, 2, 2, brass[5])
            for k in range(10):
                a = k * math.pi / 5.0
                c.rect(gx + math.cos(a) * (gr + 1) - 1, gy + math.sin(a) * (gr + 1) - 1,
                       gx + math.cos(a) * (gr + 1) + 1, gy + math.sin(a) * (gr + 1) + 1, brass[4])
        for k in range(6):
            c.rect(cx - 16 + k * 6, cy - 22, cx - 15 + k * 6, cy - 18, brass[5])
    else:
        # Aiguilles ouvragées, arrêtées.
        c.line([(cx, cy), (cx + 2, cy - 15)], "#2A2018", 2)
        c.line([(cx, cy), (cx + 11, cy + 5)], "#2A2018", 2)
        c.ellipse(cx, cy, 2, 2, "#2A2018")
    # La porte vitrée et le balancier de laiton, en bas.
    c.rect(10, 74, w - 10, h - 14, ramp("#2A2018", 4)[1])
    if opened:
        c.rect(14, 78, w - 14, h - 18, ramp("#5A4630", 4)[1])
        # Le peigne doré, dans sa petite caisse de résonance.
        c.rect(16, 80, w - 16, 96, ramp("#8A6A44", 4)[2])
        for k in range(13):
            c.rect(19 + k * 3.2, 82, 20 + k * 3.2, 82 + 6 + (k % 4) * 2, brass[5])
        c.rect(16, 80, w - 16, 82, ramp("#8A6A44", 4)[3])
    else:
        c.rect(14, 78, w - 14, h - 18, ramp("#A9B9C6", 4)[1])
        c.line([(18, 82), (28, 104)], "#E8F0F4", 1)
    sx = w / 2.0 + (swing if not opened else 0)
    c.line([(w / 2.0, 80), (sx, h - 30)], brass[3], 2)
    c.ellipse(sx, h - 28, 9, 9, brass[3])
    c.ellipse(sx - 2, h - 30, 4, 4, brass[5])
    c.rect(2, h - 12, w - 2, h, case[1])
    return outline_finish(c)


def wallitem_clock_limashenka(size, rnd):
    return _clock(size, rnd)


def wallitem_clock_limashenka_open(size, rnd):
    return _clock(size, rnd, opened=True)


def clock_limashenka_swing(size, rnd, frames):
    """L'horloge réparée : le balancier va et vient, le reste identique au pixel près."""
    sweep = (-9, 0, 9, 0)
    return [_clock(size, rnd, swing=sweep[k % len(sweep)]) for k in range(frames)]


def side_table_salon(size, rnd):
    """Guéridon à napperon, une petite boîte à couture et un portrait encadré posé."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#6A4A34", 5, spread=0.4)
    c.rect(w / 2 - 3, 28, w / 2 + 3, h - 6, t[1])
    c.rect(w / 2 - 3, 28, w / 2 - 1, h - 6, t[3])
    c.ellipse(w / 2, h - 5, 14, 4, t[1])
    c.ellipse(w / 2, 26, w / 2 - 2, 6, t[2])
    c.ellipse(w / 2, 24, w / 2 - 2, 6, t[3])
    c.ellipse(w / 2, 24, w / 2 - 8, 4, "#EEE4D2")
    # Boîte à couture, portrait encadré.
    c.rect(w / 2 - 20, 12, w / 2 - 6, 24, ramp("#9A6A8A", 4)[2])
    c.rect(w / 2 - 20, 12, w / 2 - 6, 14, ramp("#9A6A8A", 4)[3])
    c.rect(w / 2 + 2, 8, w / 2 + 16, 24, ramp("#B4955E", 4)[2])
    c.rect(w / 2 + 4, 10, w / 2 + 14, 22, "#D8C8A8")
    c.ellipse(w / 2 + 9, 15, 3, 3, "#8A6A50")
    c.rect(w / 2 + 6, 18, w / 2 + 12, 22, "#6A4A3A")
    return outline_finish(c)


def wallitem_family_portrait(size, rnd):
    """Portrait peint d'une famille d'hommes-chats, une mère et un petit garçon, dans un cadre doré terni ; aucun
    texte."""
    w, h = size
    c = Canvas(w, h, rnd)
    gold = ramp("#B4955E", 5, spread=0.4)
    c.rect(0, 0, w, h, gold[2])
    c.rect(0, 0, w, 3, gold[4])
    c.rect(0, h - 3, w, h, gold[0])
    c.rect(4, 4, w - 4, h - 4, "#4A3A32")
    # Le fond du tableau, puis la mère et le petit (oreilles de chat, museaux).
    c.rect(6, 6, w - 6, h - 6, "#6A5A4A")
    fur, fur2 = ramp("#C89A60", 4), ramp("#8A7A6A", 4)
    cx = w * 0.38
    c.rect(cx - 12, h * 0.6, cx + 12, h - 6, "#5A6E88")
    c.ellipse(cx, h * 0.42, 12, 12, fur[2])
    c.poly([(cx - 11, h * 0.34), (cx - 6, h * 0.22), (cx - 2, h * 0.32)], fur[1])
    c.poly([(cx + 11, h * 0.34), (cx + 6, h * 0.22), (cx + 2, h * 0.32)], fur[1])
    c.ellipse(cx - 4, h * 0.41, 1, 1, "#2A2018")
    c.ellipse(cx + 4, h * 0.41, 1, 1, "#2A2018")
    c.ellipse(cx, h * 0.46, 2, 1, "#8A4A3A")
    cx2 = w * 0.72
    c.rect(cx2 - 8, h * 0.68, cx2 + 8, h - 6, "#8A5A4A")
    c.ellipse(cx2, h * 0.55, 8, 8, fur2[2])
    c.poly([(cx2 - 7, h * 0.5), (cx2 - 4, h * 0.42), (cx2 - 1, h * 0.49)], fur2[1])
    c.poly([(cx2 + 7, h * 0.5), (cx2 + 4, h * 0.42), (cx2 + 1, h * 0.49)], fur2[1])
    c.ellipse(cx2 - 3, h * 0.54, 1, 1, "#2A2018")
    c.ellipse(cx2 + 3, h * 0.54, 1, 1, "#2A2018")
    return outline_finish(c)


def rug_salon(size, rnd):
    """Tapis à médaillon central bordeaux et vert, usé, franges ; décalque à bord plein."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    wine, green, cream = ramp("#8A2E3A", 5, spread=0.35), ramp("#4E7A58", 5, spread=0.35), ramp("#D8C8A0", 4)
    m = 10
    # Franges aux deux bouts.
    for y in range(m + 4, h - m - 2, 4):
        d.line((2, y, m, y + rnd.randint(-1, 1)), fill=rgba(cream[2]))
        d.line((w - m, y, w - 2, y + rnd.randint(-1, 1)), fill=rgba(cream[2]))
    body = Image.new("RGBA", (w - 2 * m, h - 2 * m), rgba(wine[2]))
    bw, bh = body.size
    bd = ImageDraw.Draw(body)
    bd.rectangle((0, 0, bw - 1, bh - 1), outline=rgba(cream[1]))
    bd.rectangle((6, 6, bw - 7, bh - 7), outline=rgba(green[2]), width=3)
    bd.rectangle((14, 14, bw - 15, bh - 15), outline=rgba(wine[0]))
    # Médaillon central.
    cx, cy = bw / 2.0, bh / 2.0
    bd.ellipse((cx - 44, cy - 28, cx + 44, cy + 28), fill=rgba(green[2]))
    bd.ellipse((cx - 36, cy - 22, cx + 36, cy + 22), fill=rgba(wine[3]))
    bd.ellipse((cx - 20, cy - 12, cx + 20, cy + 12), fill=rgba(cream[2]))
    bd.ellipse((cx - 10, cy - 6, cx + 10, cy + 6), fill=rgba(green[1]))
    for k in range(10):
        a = k * math.pi / 5.0
        bd.line((cx + math.cos(a) * 24, cy + math.sin(a) * 16, cx + math.cos(a) * 34, cy + math.sin(a) * 21),
                fill=rgba(cream[1]))
    for corner in ((14, 14), (bw - 30, 14), (14, bh - 30), (bw - 30, bh - 30)):
        bd.polygon([(corner[0], corner[1] + 8), (corner[0] + 8, corner[1]), (corner[0] + 16, corner[1] + 8),
                    (corner[0] + 8, corner[1] + 16)], fill=rgba(green[3]))
    # Usure : plaques claires, coins arrondis et mités.
    worn = threshold(fractal(body.size, (4, 4), rnd, 3), 205)
    body.paste(Image.new("RGBA", body.size, rgba("#B8A488")), (0, 0), worn.point(lambda v: int(v * 0.3)))
    mask = Image.new("L", body.size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, bw - 1, bh - 1), radius=18, fill=255)
    # Bords mités : de petites morsures le long des quatre côtés.
    for _ in range(70):
        side = rnd.randrange(4)
        t = rnd.uniform(14, (bw if side < 2 else bh) - 14)
        x, y = (t, 0 if side == 0 else bh) if side < 2 else (0 if side == 2 else bw, t)
        r = rnd.uniform(2, 6)
        md.ellipse((x - r, y - r, x + r, y + r), fill=0)
    img.paste(body, (m, m), mask)
    # Le bord de l'image reste libre : bord irrégulier, franges comprises.
    return img


# --- Table des recettes et entrées du manifeste (lot R3) ------------------------------------------------------


RECIPES = {
    "buildings/materials/roof_thatch": roof_thatch,
    "buildings/materials/wall_wattle_daub": wall_wattle_daub,
    "buildings/cottage_thatch_a": cottage_thatch_a,
    "buildings/cottage_thatch_a_side": cottage_thatch_a_side,
    "buildings/cottage_thatch_b": cottage_thatch_b,
    "buildings/cottage_thatch_b_side": cottage_thatch_b_side,
    "buildings/cottage_thatch_c": cottage_thatch_c,
    "buildings/cottage_thatch_c_side": cottage_thatch_c_side,
    "buildings/village_barn": village_barn,
    "buildings/village_barn_side": village_barn_side,
    "buildings/village_house_stone": village_house_stone,
    "buildings/village_house_stone_side": village_house_stone_side,
    "buildings/village_shed": village_shed,
    "buildings/village_shed_side": village_shed_side,
    "props/fence_wattle": fence_wattle,
    "props/beehives": beehives,
    "props/cart_hay": cart_hay,
    "props/haystack": haystack,
    "props/washing_trough": washing_trough,
    "interior/floor_terracotta": floor_terracotta,
    "interior/wall_panel_dark": wall_panel_dark,
    "interior/door_backroom": door_backroom,
    "interior/props/cafe_counter": cafe_counter,
    "interior/props/cafe_table_heavy": cafe_table_heavy,
    "interior/props/juice_glasses": juice_glasses,
    "interior/props/cafe_bottle_shelf": cafe_bottle_shelf,
    "interior/props/cafe_cake_case": cafe_cake_case,
    "interior/props/cafe_drinkers_table": cafe_drinkers_table,
    "interior/wallitem_menu_cafe": wallitem_menu_cafe,
    "interior/wall_wallpaper_floral": wall_wallpaper_floral,
    "interior/window_shutters": window_shutters,
    "interior/props/toolbox_gears": toolbox_gears,
    "interior/wallitem_clock_limashenka": wallitem_clock_limashenka,
    "interior/wallitem_clock_limashenka_open": wallitem_clock_limashenka_open,
    "anim/clock_limashenka_swing": clock_limashenka_swing,
    "interior/props/side_table_salon": side_table_salon,
    "interior/wallitem_family_portrait": wallitem_family_portrait,
    "decals/rug_salon": rug_salon,
}

# Entrées du manifeste hors intérieurs (tools/hd2d_interior.py écrit celles des images d'intérieur) : chemin, taille,
# genre, priorité, lot R3, drapeaux (roof, wall_m : flancs ; wrap : sans raccord).
MANIFEST = [
    {"path": "assets/hd2d/buildings/materials/roof_thatch.png", "size": [192, 192], "kind": "tile", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/buildings/materials/wall_wattle_daub.png", "size": [192, 192], "kind": "tile", "prio": 2,
     "lot": "R3"},
    {"path": "assets/hd2d/buildings/cottage_thatch_a.png", "size": [480, 528], "kind": "facade", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/buildings/cottage_thatch_a_side.png", "size": [480, 240], "kind": "side", "prio": 2, "lot": "R3",
     "roof": "eaves"},
    {"path": "assets/hd2d/buildings/cottage_thatch_b.png", "size": [672, 240], "kind": "facade", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/buildings/cottage_thatch_b_side.png", "size": [480, 480], "kind": "side", "prio": 2, "lot": "R3",
     "roof": "gable", "wall_m": 2.5},
    {"path": "assets/hd2d/buildings/cottage_thatch_c.png", "size": [384, 480], "kind": "facade", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/buildings/cottage_thatch_c_side.png", "size": [384, 216], "kind": "side", "prio": 2, "lot": "R3",
     "roof": "eaves"},
    {"path": "assets/hd2d/buildings/village_barn.png", "size": [768, 336], "kind": "facade", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/buildings/village_barn_side.png", "size": [576, 672], "kind": "side", "prio": 2, "lot": "R3",
     "roof": "gable", "wall_m": 3.5},
    {"path": "assets/hd2d/buildings/village_house_stone.png", "size": [480, 576], "kind": "facade", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/buildings/village_house_stone_side.png", "size": [480, 288], "kind": "side", "prio": 2,
     "lot": "R3", "roof": "eaves"},
    {"path": "assets/hd2d/buildings/village_shed.png", "size": [384, 216], "kind": "facade", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/buildings/village_shed_side.png", "size": [288, 336], "kind": "side", "prio": 3, "lot": "R3",
     "roof": "gable", "wall_m": 2.25},
    {"path": "assets/hd2d/props/fence_wattle.png", "size": [192, 86], "kind": "panel", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/props/beehives.png", "size": [154, 96], "kind": "panel", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/props/cart_hay.png", "size": [288, 192], "kind": "panel", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/props/haystack.png", "size": [192, 154], "kind": "panel", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/props/washing_trough.png", "size": [288, 96], "kind": "panel", "prio": 3, "lot": "R3"},
]
# Hors manifeste ici : les images d'intérieur (tools/hd2d_interior.py, listes C2 : sol, mur, porte, mobilier, objets,
# horloge, bande animée du balancier, tapis) ; leurs recettes sont dans RECIPES.


def cmd_manifest():
    """Inscrit MANIFEST au manifeste (une ligne par image, à la fin de la liste), sans toucher aux autres lignes."""
    import json
    import os
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    path = os.path.join(root, "tools", "hd2d_manifest.json")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    marker = "\n ],\n \"sheets\""
    head, tail = text[:text.index(marker)], text[text.index(marker):]
    managed = ['"path": "%s"' % entry["path"] for entry in MANIFEST]
    lines = [line for line in head.split("\n") if not any(m in line for m in managed)]
    if lines[-1].endswith(","):
        lines[-1] = lines[-1][:-1]
    new = "\n".join(lines) + "".join(",\n  " + json.dumps(e, ensure_ascii=False) for e in MANIFEST) + tail
    json.loads(new)
    if new == text:
        print("manifeste à jour (%d images du village)" % len(MANIFEST))
        return 0
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(new)
    print("manifeste : %d images du village" % len(MANIFEST))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(cmd_manifest() if sys.argv[1:] == ["manifest"] else print(__doc__) or 2)
