#!/usr/bin/env python3
"""Remplaçants du lot I pour les cartes de l'entrepôt (lot T2) que la livraison n'a pas encore : la
petite fenêtre des archives, les coupures de magazine, le vieux piano, l'échelle et la trappe du toit,
le module de rambarde tordu, les décalques (tapis de couloir, papiers, flaques, cartes, vêtements) et
les bandes animées (vapeur, goutte, linge au vent). Tailles et consignes : cahier n° 3
(docs/ASSETS_HD2D_SUKASUKA.md, section 3) ; roof_ladder, hors cahier : CARTE.md, 12.1.

Chaque recette dessine l'image à sa taille exacte, en pixel art (vue de face légèrement
plongeante pour les meubles, de dessus pour les décalques), d'après la consigne du cahier. Une
vraie image livrée sous le même nom remplace le remplaçant sans toucher au code, et sa recette
s'en va avec lui (I1) : le fichier livré fait foi, et gen --force ne le réécrit jamais ; aucune
image livrée n'est retouchée (roof_railing_broken et drying_frame_wave partent d'une copie de
l'image livrée dont ils dérivent, qui reste intacte). Liste et entrées du manifeste :
tools/hd2d_interior.py ; génération : python3 tools/hd2d_assets.py gen --lot I.
"""

import math
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hd2d_art import (  # noqa: E402
    Canvas, WrapCanvas, asset, darker, fractal, mix, noise, posterize, ramp, rgba, steps_alpha, wrap_y)

PPM = 96
HONEY = "#A57C58"
DARK = "#654D3C"
MID = "#86603F"
PALE = "#B89A72"
LINEN = "#E6DCC6"
CRYSTAL = "#FFE6A6"
IRON = "#5C636B"
BRASS = "#B4955E"
GLASS = "#A9B9C6"
FOLIAGE = "#C9A04E"
OUT_WOOD = darker(DARK, 0.45)


# --- Outils de dessin -------------------------------------------------------------------------


def wood(c, x0, y0, x1, y1, base, top=0, grain=4, edge=True):
    """Pièce de bois : face, dessus clair (vue plongeante), arêtes, fil du bois."""
    t = ramp(base, 5, spread=0.45)
    c.rect(x0, y0, x1, y1, t[2])
    for _ in range(grain):
        gx = c.rnd.uniform(x0 + 2, max(x0 + 2.5, x1 - 3))
        gy = c.rnd.uniform(y0 + top, max(y0 + top + 0.5, y1 - 4))
        c.rect(gx, gy, gx + 1, min(y1 - 1, gy + c.rnd.uniform(4, 14)), t[1] if c.rnd.random() < 0.6 else t[3])
    if top:
        c.rect(x0, y0, x1, y0 + top, t[3])
        c.rect(x0, y0, x1, y0 + 1, t[4])
        c.rect(x0, y0 + top - 1, x1, y0 + top, t[1])
    if edge:
        c.rect(x0, y0, x0 + 1, y1, t[3])
        c.rect(x1 - 1, y0, x1, y1, t[1])
        c.rect(x0, y1 - 1, x1, y1, t[0])
    return t


def inset(c, x0, y0, x1, y1, t):
    """Panneau en creux (porte d'armoire) : ombre en haut à gauche, lumière en bas à droite."""
    c.rect(x0, y0, x1, y1, t[1])
    c.rect(x0 + 1, y0 + 1, x1, y1, t[3])
    c.rect(x0 + 1, y0 + 1, x1 - 1, y1 - 1, t[2])


def paper(c, x0, y0, x1, y1, base="#EEE6D2", lines=True):
    t = ramp(base, 4, spread=0.25)
    c.rect(x0, y0, x1, y1, t[2])
    c.rect(x1 - 1, y0, x1, y1, t[1])
    c.rect(x0, y1 - 1, x1, y1, t[1])
    if lines:
        y = y0 + 3
        while y < y1 - 2:
            c.rect(x0 + 2, y, x0 + 2 + (x1 - x0 - 4) * c.rnd.uniform(0.5, 1.0), y + 1, "#A9A49A")
            y += 3


def glass(c, x0, y0, x1, y1, night=False):
    """Vitre gris bleuté, reflet en diagonale, masse de feuillage d'or devinée en bas."""
    t = ramp(GLASS, 4, spread=0.35)
    c.rect(x0, y0, x1, y1, t[2])
    h = y1 - y0
    c.rect(x0, y0 + h * 0.62, x1, y1, mix(t[1], FOLIAGE, 0.45))
    for k in range(int(x1 - x0) + int(h)):
        x = x0 + k
        y = y0 + k * 0.9
        if x0 <= x < x1 - 1 and y0 <= y < y1 and (k // 3) % 3 == 0:
            c.rect(x, y, x + 1, y + 1, t[3])
    c.rect(x0, y0, x1, y0 + 1, t[1])


def cross_window(c, x0, y0, x1, y1, cols=2, rows=3, frame=MID, bar=3):
    """Fenêtre à croisillons : cadre, vitres, barreaux."""
    t = wood(c, x0, y0, x1, y1, frame, grain=0)
    ix0, iy0, ix1, iy1 = x0 + bar + 1, y0 + bar + 1, x1 - bar - 1, y1 - bar - 1
    glass(c, ix0, iy0, ix1, iy1)
    for k in range(1, cols):
        x = ix0 + (ix1 - ix0) * k / cols
        c.rect(x - 1, iy0, x + 1, iy1, t[2])
        c.rect(x - 1, iy0, x, iy1, t[3])
    for k in range(1, rows):
        y = iy0 + (iy1 - iy0) * k / rows
        c.rect(ix0, y - 1, ix1, y + 1, t[2])
        c.rect(ix0, y - 1, ix1, y, t[3])
    return t


def outline_finish(c, color=OUT_WOOD):
    return c.finish(color)


# --- Portes et fenêtres -----------------------------------------------------------------------


def window_dusty(size, rnd):
    """Petite fenêtre haute des archives : vitres grises de poussière, toile d'araignée, loquet
    rouillé."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = cross_window(c, 4, 4, w - 4, h - 4, cols=2, rows=2, frame=DARK)
    dust = fractal((w - 18, h - 18), (3, 3), rnd, 2)
    layer = Image.new("RGBA", dust.size, rgba("#8E8A80"))
    c.img.paste(layer, (9, 9), dust.point(lambda v: int(v * 0.75)))
    c.rect(9, 9, w - 9, 10, t[1])
    for k in range(6):
        a = math.radians(5 + k * 16)
        c.line([(9, 9), (9 + math.cos(a) * 22, 9 + math.sin(a) * 22)], "#D8D4CC")
    for r in (8, 14, 20):
        pts = [(9 + math.cos(math.radians(a)) * r, 9 + math.sin(math.radians(a)) * r) for a in range(5, 90, 16)]
        c.line(pts, "#C8C4BC")
    c.rect(w / 2 - 2, h / 2 + 2, w / 2 + 6, h / 2 + 5, "#7A4A2E")
    c.rect(4, h - 6, w - 4, h, t[3])
    return outline_finish(c)


# --- Éléments de mur ---------------------------------------------------------------------------


def wallitem_clippings(size, rnd):
    """Coupures de magazines pour filles épinglées : dessins de robes et de chapeaux, sans texte."""
    w, h = size
    c = Canvas(w, h, rnd)
    spots = [(1, 6, 26, 34), (24, 1, 52, 30), (50, 8, w - 1, 38), (12, 32, 40, h - 1), (40, 34, 68, h - 2)]
    for k, (x0, y0, x1, y1) in enumerate(spots):
        paper(c, x0, y0, x1, y1, rnd.choice(["#F2EEE6", "#F0E2E2", "#E8EEF0"]), lines=False)
        cx = (x0 + x1) / 2
        dress = rnd.choice(["#C86A7A", "#6A8AC8", "#E8B040", "#8AA86A", "#B07AC0"])
        if k % 2 == 0:
            c.rect(cx - 2, y0 + 5, cx + 2, y0 + 9, "#E8C8A8")
            c.poly([(cx - 3, y0 + 9), (cx + 3, y0 + 9), (cx + 8, y1 - 3), (cx - 8, y1 - 3)], dress)
        else:
            c.ellipse(cx, y0 + 14, 10, 3, dress)
            c.ellipse(cx, y0 + 10, 5, 5, dress)
            c.rect(cx - 6, y0 + 11, cx + 6, y0 + 13, "#F2EEE6")
        c.rect(cx - 1, y0 + 1, cx + 1, y0 + 3, "#B5443A")
    return c.finish(darker("#A09080", 0.5))


# --- Meubles -----------------------------------------------------------------------------------


def piano_old(size, rnd):
    """Vieux piano droit de bois sombre, couvercle ouvert, touches jaunies, une partition sans
    notes lisibles, bougeoirs vides, tabouret rond."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = wood(c, 10, 10, w - 10, h - 4, "#4A3428", grain=10)
    c.rect(6, 6, w - 6, 14, t[3])
    c.rect(6, 6, w - 6, 7, t[4])
    inset(c, 18, 18, w - 18, 56, t)
    # Partition et bougeoirs.
    c.rect(w / 2 - 16, 22, w / 2 + 16, 46, "#EEE6D2")
    for y in range(26, 44, 5):
        c.rect(w / 2 - 13, y, w / 2 + 13, y + 1, "#A9A49A")
    for x in (24, w - 30):
        c.rect(x, 28, x + 6, 32, ramp(BRASS, 4)[2])
        c.rect(x + 2, 20, x + 4, 28, ramp(BRASS, 4)[1])
    # Clavier, touches jaunies.
    c.rect(10, 60, w - 10, 76, "#E8DCB0")
    c.rect(10, 60, w - 10, 62, "#F4ECC8")
    for x in range(12, w - 12, 5):
        c.rect(x, 60, x + 1, 76, "#B8A880")
    for x in range(14, w - 14, 10):
        c.rect(x, 60, x + 3, 69, "#2A2420")
    c.rect(10, 76, w - 10, 80, t[0])
    inset(c, 18, 86, w - 18, h - 10, t)
    # Tabouret rond devant.
    c.ellipse(w / 2, h - 30, 16, 5, ramp("#7A2E26", 4)[2])
    c.rect(w / 2 - 2, h - 26, w / 2 + 2, h - 2, t[1])
    c.rect(w / 2 - 10, h - 4, w / 2 + 10, h - 1, t[1])
    return outline_finish(c)


def roof_ladder(size, rnd):
    """Échelle de meunier de bois, raide, contre le mur, qui monte à une trappe ouverte au plafond
    (haut de l'image) ; un rai de jour par la trappe (nom proposé, CARTE.md 12.1)."""
    w, h = size
    c = Canvas(w, h, rnd)
    # Trappe ouverte au plafond : cadre sombre, ciel pâle, couvercle rabattu.
    c.rect(4, 0, w - 4, 26, "#2A2018")
    c.rect(10, 2, w - 10, 22, "#C8D8E8")
    c.rect(10, 2, w - 10, 8, "#E8EEF4")
    c.rect(2, 22, w - 2, 28, ramp(DARK, 4)[2])
    # Rai de jour (pixels clairs alignés en diagonale).
    for y in range(30, h - 40, 3):
        x = 22 + (y - 30) * 0.06
        if (y // 3) % 2 == 0:
            c.rect(x, y, x + 10, y + 1, "#F4E8C8")
    t = ramp(HONEY, 5, spread=0.42)
    for x in (10, w - 18):
        c.rect(x, 24, x + 8, h, t[2])
        c.rect(x, 24, x + 2, h, t[3])
        c.rect(x + 6, 24, x + 8, h, t[1])
    for y in range(40, h - 4, 22):
        c.rect(18, y, w - 18, y + 6, t[3])
        c.rect(18, y, w - 18, y + 1, t[4])
        c.rect(18, y + 5, w - 18, y + 6, t[0])
        c.rect(18 + (w - 36) * 0.4, y + 1, 18 + (w - 36) * 0.6, y + 2, t[4])
    return outline_finish(c)


def roof_hatch(size, rnd):
    """Trappe d'accès au toit ouverte, le haut d'une échelle de bois qui dépasse, couvercle
    rabattu."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#7A6A58", 5, spread=0.4)
    c.rect(8, h - 16, w - 8, h, t[1])
    c.rect(14, h - 14, w - 14, h, "#1A1410")
    # Couvercle rabattu derrière (vu de face, debout).
    lid = ramp("#8A7A64", 5, spread=0.4)
    c.rect(18, 4, w - 18, h - 16, lid[2])
    for x in range(20, w - 18, 9):
        c.rect(x, 4, x + 1, h - 16, lid[1])
    c.rect(18, 4, w - 18, 6, lid[3])
    c.rect(w / 2 - 6, 24, w / 2 + 6, 28, "#5C636B")
    # Haut de l'échelle qui dépasse.
    wt = ramp(HONEY, 4, spread=0.4)
    for x in (30, w - 36):
        c.rect(x, 20, x + 5, h - 2, wt[2])
        c.rect(x, 20, x + 1, h - 2, wt[3])
    c.rect(30, h - 10, w - 31, h - 7, wt[3])
    c.rect(8, h - 16, w - 8, h - 14, t[3])
    return outline_finish(c)


def roof_railing_broken(size, rnd):
    """Le module de rambarde (roof_railing, livré) dont un pan est tordu vers le dehors et un
    barreau manque. Part d'une copie de l'image livrée."""
    base = asset("interior/props/roof_railing")
    w, h = size
    if base is None or base.size != (w, h):
        c = Canvas(w, h, rnd)
        c.rect(0, 8, w, 14, "#4E7A5A")
        return c.img
    img = base.copy()
    # Pan tordu : la moitié droite de la main courante penche vers le bas, un barreau effacé.
    right = img.crop((w // 2, 0, w, h))
    bent = Image.new("RGBA", right.size, (0, 0, 0, 0))
    for x in range(right.width):
        dy = int(round(x * 0.12))
        column = right.crop((x, 0, x + 1, h - dy))
        bent.paste(column, (x, dy))
    img.paste(Image.new("RGBA", right.size, (0, 0, 0, 0)), (w // 2, 0))
    img.alpha_composite(bent, (w // 2, 0))
    # Un barreau manque : on efface une bande verticale au-dessous de la main courante.
    clear = Image.new("RGBA", (6, h - 30), (0, 0, 0, 0))
    img.paste(clear, (int(w * 0.72), 22))
    d = ImageDraw.Draw(img)
    d.rectangle((int(w * 0.72), h - 9, int(w * 0.72) + 5, h - 1), fill=rgba("#4E5A50"))
    return img


# --- Objets posés ------------------------------------------------------------------------------


# --- Décalques --------------------------------------------------------------------------------


def runner_rug(size, rnd):
    """Tapis de couloir tissé brun et rouge passé, liseré ocre, usé au milieu en un chemin plus
    clair, une tache ; il se répète en longueur sans couture (raccord en haut et en bas)."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, x1 = 8, w - 8
    d.rectangle((x0, 0, x1 - 1, h - 1), fill=rgba("#8A3A2E"))
    d.rectangle((x0 + 4, 0, x1 - 5, h - 1), fill=rgba("#6A4030"))
    d.rectangle((x0 + 8, 0, x1 - 9, h - 1), fill=rgba("#9A4A36"))
    for y in range(0, h, 24):
        for k in range(3):
            cx = w / 2
            d.polygon([(cx, y + 4 + k), (cx + 12 - k * 3, y + 12), (cx, y + 20 - k), (cx - 12 + k * 3, y + 12)],
                      fill=rgba(["#C89A4A", "#7A3026", "#B0703A"][k]))
    for x in (x0 + 2, x1 - 3):
        d.rectangle((x, 0, x, h - 1), fill=rgba("#C8A050"))
    # Usure claire au milieu (bruit qui se raccorde en haut et en bas).
    wear = noise((x1 - x0 - 16, h), (3, 12), rnd).point(lambda v: int(max(0, v - 110) * 0.9))
    img.paste(Image.blend(img.crop((x0 + 8, 0, x1 - 8, h)), Image.new("RGBA", wear.size, rgba("#C8A888")), 0.6),
              (x0 + 8, 0), wear)
    d = ImageDraw.Draw(img)
    d.ellipse((w / 2 - 10, 230, w / 2 + 6, 244), fill=rgba("#5A3A2A"))
    # Bords effilochés à gauche et à droite.
    for y in range(0, h, 2):
        if rnd.random() < 0.35:
            d.rectangle((x0 - 2, y, x0 - 1, y), fill=rgba("#B07A40"))
        if rnd.random() < 0.35:
            d.rectangle((x1, y, x1 + 1, y), fill=rgba("#B07A40"))
    return img


def _scatter_decal(size, rnd, pieces):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    c = Canvas(size[0], size[1], rnd)
    c.img = img
    c.draw = ImageDraw.Draw(img)
    for piece in pieces:
        piece(c)
    return c.img


def _sheet(c, cx, cy, w, h, angle, color, lines="#A9A49A"):
    from hd2d_art import rotate_points
    pts = rotate_points([(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2),
                         (cx - w / 2, cy + h / 2)], cx, cy, angle)
    c.poly(pts, color)
    for k in range(int(h // 4) - 1):
        a = (cx - w / 2 + 3, cy - h / 2 + 4 + k * 4)
        b = (cx + w / 2 - 3 - c.rnd.uniform(0, w / 3), a[1])
        c.line(rotate_points([a, b], cx, cy, angle), lines)


def papers_floor(size, rnd):
    """Feuilles éparses par terre vues de dessus : un rapport, une coupure de magazine, un bon de
    commande, une enveloppe ; lignes grises, aucune lettre."""
    w, h = size
    pieces = []
    for k in range(9):
        cx, cy = rnd.uniform(28, w - 28), rnd.uniform(24, h - 24)
        col = rnd.choice(["#F0EAD8", "#E8E0C8", "#F2EEE6", "#E8DCC8"])
        pieces.append(lambda c, cx=cx, cy=cy, col=col: _sheet(c, cx, cy, rnd.uniform(26, 34), rnd.uniform(32, 42),
                                                               rnd.uniform(-0.6, 0.6), col))
    pieces.append(lambda c: _sheet(c, w * 0.7, h * 0.3, 28, 34, 0.3, "#F0D8E0", "#C86A7A"))
    pieces.append(lambda c: c.poly([(40, 100), (72, 96), (74, 116), (42, 120)], "#D8C8A0"))
    return _scatter_decal(size, rnd, pieces)


def bath_puddles(size, rnd):
    """Flaques et éclaboussures d'eau savonneuse sur le carrelage, quelques bulles, empreintes de
    petits pieds mouillés qui s'en vont."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    field = fractal(size, (5, 4), rnd, 3)
    mask = Image.new("L", size, 0)
    md = ImageDraw.Draw(mask)
    for _ in range(5):
        cx, cy = rnd.uniform(40, w - 40), rnd.uniform(30, h - 50)
        md.ellipse((cx - rnd.uniform(18, 34), cy - rnd.uniform(10, 18), cx + rnd.uniform(18, 34),
                    cy + rnd.uniform(10, 18)), fill=255)
    from PIL import ImageChops
    puddle = ImageChops.multiply(mask, field.point(lambda v: 255 if v > 70 else 0))
    water = Image.new("RGBA", size, rgba("#9AC0D0", 170))
    img.paste(water, (0, 0), puddle)
    d = ImageDraw.Draw(img)
    for _ in range(26):
        x, y = rnd.uniform(30, w - 30), rnd.uniform(20, h - 40)
        r = rnd.uniform(1, 3)
        d.ellipse((x - r, y - r, x + r, y + r), outline=rgba("#F4F8FA", 220))
    for k in range(4):
        x, y = w * 0.62 + k * 14, h - 28 - k * 6
        for dx in (0, 6):
            d.ellipse((x + dx, y + (dx // 3), x + dx + 4, y + 7 + (dx // 3)), fill=rgba("#8AB0C0", 150))
    return steps_alpha(img, 6)


def cards_floor(size, rnd):
    """Jeu de cartes éparpillé par terre vu de dessus, dos rouges, figures sans lettres ni
    chiffres."""
    w, h = size
    pieces = []
    for k in range(13):
        cx, cy = rnd.uniform(18, w - 18), rnd.uniform(16, h - 16)
        face = rnd.random() < 0.35

        def card(c, cx=cx, cy=cy, face=face, a=rnd.uniform(-1.2, 1.2)):
            from hd2d_art import rotate_points
            pts = rotate_points([(cx - 7, cy - 10), (cx + 7, cy - 10), (cx + 7, cy + 10), (cx - 7, cy + 10)], cx, cy, a)
            c.poly(pts, "#F4F0E8" if face else "#B03030")
            if face:
                c.ellipse(cx, cy, 3, 3, c.rnd.choice(["#B03030", "#2A2A30"]))
            else:
                c.poly(rotate_points([(cx - 5, cy - 8), (cx + 5, cy - 8), (cx + 5, cy + 8), (cx - 5, cy + 8)], cx, cy, a),
                       "#D06050")
        pieces.append(card)
    return _scatter_decal(size, rnd, pieces)


def clothes_floor(size, rnd):
    """Vêtements jetés par terre vus de dessus : chemise, jupe, chaussettes dépareillées, une
    écharpe ; aucun sous-vêtement visible."""
    w, h = size

    def shirt(c):
        c.poly([(40, 30), (80, 26), (96, 40), (88, 46), (86, 92), (46, 96), (44, 50), (30, 48)], "#E8ECF0")
        c.poly([(56, 28), (66, 40), (72, 27)], "#C8D0D8")
        for y in (52, 64, 76):
            c.rect(64, y, 66, y + 2, "#A0A8B0")

    def skirt(c):
        c.poly([(118, 70), (150, 66), (172, 118), (108, 124)], "#4E6A9A")
        for k in range(5):
            c.line([(124 + k * 7, 70), (116 + k * 12, 120)], "#3A527A")

    def socks(c):
        c.poly([(20, 106), (30, 104), (34, 126), (46, 128), (44, 136), (24, 132)], "#C85A5A")
        c.poly([(150, 20), (160, 22), (158, 40), (170, 46), (164, 52), (150, 42)], "#E8C060")

    def scarf(c):
        c.line([(70, 112), (100, 104), (120, 132), (150, 128)], "#6A8A4A", width=8)
        for x in (150, 154):
            c.line([(x, 126), (x + 4, 138)], "#4A6A3A")
    return _scatter_decal(size, rnd, [shirt, skirt, socks, scarf])


# --- Bandes animées ---------------------------------------------------------------------------


def pot_steam(size, rnd, frames):
    """Vapeur blanche qui monte d'une marmite et s'étire (alpha doux) ; le bas de l'image est le
    bord de la marmite (non dessinée)."""
    w, h = size
    out = []
    puffs = [(rnd.uniform(-6, 6), rnd.uniform(0, 1), rnd.uniform(6, 10)) for _ in range(5)]
    for f in range(frames):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        for k, (dx, phase, r) in enumerate(puffs):
            t = (f / float(frames) + phase + k / 5.0) % 1.0
            y = h - 4 - t * (h - 16)
            x = w / 2 + dx * (0.3 + t) + math.sin((t + k) * 6.0) * 4
            rr = r * (0.6 + t * 0.9)
            alpha = int(170 * (1.0 - t) ** 0.8)
            d.ellipse((x - rr, y - rr * 0.8, x + rr, y + rr * 0.8), fill=(244, 244, 240, alpha))
        d.ellipse((w / 2 - 12, h - 7, w / 2 + 12, h + 2), fill=(240, 240, 236, 150))
        out.append(steps_alpha(img, 8))
    return out


def leak_drip(size, rnd, frames):
    """Une goutte d'eau qui se forme au plafond (haut de l'image) et tombe jusqu'au bas (le bord du
    seau) ; image 4 : une petite gerbe ; fond transparent."""
    w, h = size
    out = []
    for f in range(frames):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle((w / 2 - 3, 0, w / 2 + 2, 1), fill=rgba("#8AB0C8"))
        if f == 0:
            d.ellipse((w / 2 - 2, 1, w / 2 + 2, 6), fill=rgba("#A8CCE0"))
        elif f in (1, 2):
            y = 20 + (f - 1) * 40
            d.ellipse((w / 2 - 2, y, w / 2 + 2, y + 6), fill=rgba("#A8CCE0"))
            d.rectangle((w / 2 - 1, y - 6, w / 2, y), fill=rgba("#C8E0F0"))
        else:
            for dx, dy in ((-6, -6), (-3, -9), (3, -9), (6, -6)):
                d.rectangle((w / 2 + dx, h - 3 + dy, w / 2 + dx + 1, h - 2 + dy), fill=rgba("#A8CCE0"))
            d.rectangle((w / 2 - 5, h - 2, w / 2 + 4, h - 1), fill=rgba("#8AB0C8"))
        out.append(img)
    return out


def drying_frame_wave(size, rnd, frames):
    """drying_frame (livré) dont le linge ondule au vent vers la droite, poteaux et cordes
    immobiles : chaque image décale les colonnes de linge d'une onde. Part d'une copie de l'image
    livrée."""
    w, h = size
    base = asset("interior/props/drying_frame")
    if base is None or base.size != (w, h):
        return [Image.new("RGBA", size, (0, 0, 0, 0)) for _ in range(frames)]
    # Poteaux : les colonnes très opaques sur toute la hauteur aux deux bouts restent fixes.
    alpha = base.getchannel("A")
    fixed = set()
    for x in range(w):
        col = alpha.crop((x, h // 3, x + 1, h))
        if col.histogram()[255] > (h - h // 3) * 0.85:
            fixed.add(x)
    out = []
    for f in range(frames):
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        for x in range(w):
            if x in fixed:
                img.paste(base.crop((x, 0, x + 1, h)), (x, 0))
                continue
            phase = (f / float(frames) + x / 96.0) * 2.0 * math.pi
            # Le haut du linge (pinces, cordes) bouge peu, le bas ondule.
            col = base.crop((x, 0, x + 1, h))
            shifted = Image.new("RGBA", (1, h), (0, 0, 0, 0))
            for y in range(h):
                px = col.getpixel((0, y))
                if px[3] == 0:
                    continue
                dy = int(round(math.sin(phase) * 2.0 * min(1.0, y / (h * 0.6))))
                yy = max(0, min(h - 1, y + dy))
                shifted.putpixel((0, yy), px)
            img.alpha_composite(shifted, (x, 0))
        out.append(img)
    return out


# --- (I1) Vues de flanc de remplacement (cahier n° 5, R0.3) ----------------------------------------
#
# Pour juger le rendu sans attendre la livraison : le canapé des archives, une bibliothèque et
# l'armoire de Chtholly, vus de flanc, face tournée vers l'est, aux tailles du cahier. Projection
# orthographique oblique comme la caméra du jeu : les arêtes verticales restent verticales, la
# largeur du meuble se déroule vers le fond (une surface horizontale de profondeur p fait 0,53 × p ×
# 96 px de haut, une face verticale de hauteur h, 0,85 × h × 96 px). Un fichier livré sous le même
# nom remplace ces dessins, et sa recette s'en va avec lui.

OBLIQUE_FLAT = 0.53 * PPM
OBLIQUE_UP = 0.85 * PPM


def sofa_beige_side(size, rnd):
    """Le canapé beige à trois places de flanc : dossier à gauche (contre le mur ouest), assise à
    droite ; en bas l'accoudoir du bout vu de côté (couverture à carreaux pliée dessus), au-dessus
    le dessus du dossier, de l'assise et de l'accoudoir du fond, vers le nord."""
    w, h = size
    c = Canvas(w, h, rnd)
    cloth = ramp("#C8A078", 5, spread=0.4)
    worn = ramp("#B08860", 4, spread=0.3)
    leg = ramp("#583018", 4)
    plaid = [ramp("#A04828", 4), ramp("#6A3A20", 4), ramp("#D09050", 4)]
    back_w = 24
    # Hauteur d'écran d'un point : base du bout sud à y = h, h_m de hauteur, d_m de profondeur.
    def sy(height_m, depth_m):
        return h - OBLIQUE_UP * height_m - OBLIQUE_FLAT * depth_m
    arm_h, seat_h, back_h = 0.65, 0.45, 0.9
    # Accoudoir du fond (bout nord) : dessus, puis face intérieure tournée vers le sud.
    c.rect(0, sy(arm_h, 2.0), w, sy(arm_h, 1.8), cloth[3])
    c.rect(0, sy(arm_h, 2.0), w, sy(arm_h, 2.0) + 1, cloth[4])
    c.rect(back_w, sy(arm_h, 1.8), w, sy(seat_h, 1.8), cloth[1])
    # Assise : trois coussins qui se suivent vers le fond, bourrelet rond sur le devant.
    top, bottom = sy(seat_h, 1.8), sy(seat_h, 0.2)
    c.rect(back_w, top, w, bottom, cloth[2])
    for k in range(3):
        y0 = top + (bottom - top) * k / 3.0
        y1 = top + (bottom - top) * (k + 1) / 3.0
        c.rect(back_w + 2, y0 + 1, w - 3, y1 - 1, cloth[3])
        c.rect(back_w + 2, y0 + 1, w - 3, y0 + 2, cloth[4])
        c.rect(back_w + 2, y1 - 2, w - 3, y1 - 1, cloth[1])
    c.rect(w - 14, top, w - 3, bottom, cloth[3])
    c.rect(w - 14, top, w - 13, bottom, cloth[4])
    # Dessus du dossier (les trois coussins de dossier, vus de dessus), du fond au bout sud.
    b0, b1 = sy(back_h, 1.8), sy(back_h, 0.2)
    c.rect(0, b0, back_w, b1, cloth[3])
    for k in range(3):
        y0 = b0 + (b1 - b0) * k / 3.0
        y1 = b0 + (b1 - b0) * (k + 1) / 3.0
        c.rect(1, y0 + 1, back_w - 1, y1 - 1, cloth[4] if k != 1 else cloth[3])
        c.rect(1, y1 - 2, back_w - 1, y1 - 1, cloth[1])
    # Le bout du dossier, face au sud, au-dessus de l'accoudoir.
    c.rect(0, b1, back_w, sy(arm_h, 0.2), cloth[2])
    c.rect(0, b1, back_w, b1 + 1, cloth[4])
    c.rect(back_w - 1, b1, back_w, sy(arm_h, 0.2), cloth[0])
    # Accoudoir du bout : dessus arrondi (rouleau), flanc, pieds courts.
    y_top = sy(arm_h, 0.2)
    y_roll = sy(arm_h, 0.0)
    c.rect(0, y_top, w, y_roll, cloth[4])
    c.rect(0, y_roll - 3, w, y_roll, cloth[3])
    c.rect(0, y_roll, w, h - 8, cloth[2])
    c.rect(2, y_roll + 2, w - 2, y_roll + 4, cloth[3])
    c.rect(2, h - 12, w - 2, h - 9, cloth[1])
    c.rect(0, y_roll, 2, h - 8, cloth[3])
    c.rect(w - 2, y_roll, w, h - 8, cloth[0])
    # Couverture à carreaux pliée sur l'accoudoir : un drap qui passe sur le rouleau et retombe sur
    # le flanc, carreaux de trois couleurs, franges.
    x0, x1 = 30, 64
    y_end = y_roll + 16
    c.rect(x0, y_top - 1, x1, y_end, plaid[0][2])
    for yy in range(int(y_top) - 1, int(y_end), 4):
        c.rect(x0, yy, x1, yy + 1, plaid[1][1])
    for xx in range(x0 + 2, x1, 6):
        c.rect(xx, y_top - 1, xx + 2, y_end, plaid[2][2])
    c.rect(x0, y_top - 1, x0 + 1, y_end, plaid[0][3])
    c.rect(x1 - 1, y_top - 1, x1, y_end, plaid[0][0])
    for xx in range(x0, x1, 3):
        c.rect(xx, y_end, xx + 1, y_end + 3, plaid[1][2])
    # Pieds de bois tourné.
    for px in (6, w - 12):
        c.rect(px, h - 8, px + 6, h, leg[2])
        c.rect(px, h - 8, px + 1, h, leg[3])
    return outline_finish(c)


def bookshelf_tall_b_side(size, rnd):
    """La grande bibliothèque de flanc : le dessus du meuble (planches, corniche) vers le nord, et
    en bas le flanc plein du bout, à panneau en creux, sur un socle."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#703818", 5, spread=0.4)
    top_h = int(OBLIQUE_FLAT * 1.6)
    # Dessus : planches posées dans le sens de la longueur, corniche saillante sur le devant.
    c.rect(0, 2, w, 2 + top_h, t[3])
    for x in range(8, w, 12):
        c.rect(x, 3, x + 1, 2 + top_h, t[2])
    c.rect(0, 2, w, 4, t[4])
    c.rect(0, 2 + top_h - 3, w, 2 + top_h, t[1])
    c.rect(w - 4, 2, w, 2 + top_h, t[2])
    # Flanc plein : bord de la corniche, montant, panneau en creux, socle.
    y0 = 2 + top_h
    c.rect(0, y0, w, h, t[2])
    c.rect(0, y0, w, y0 + 5, t[4])
    c.rect(0, y0 + 5, w, y0 + 7, t[1])
    for _ in range(14):
        gx = rnd.randint(3, w - 4)
        gy = rnd.randint(y0 + 12, h - 20)
        c.rect(gx, gy, gx + 1, gy + rnd.randint(6, 18), t[1] if rnd.random() < 0.6 else t[3])
    inset(c, 6, y0 + 16, w - 6, h - 22, t)
    inset(c, 11, y0 + 24, w - 11, h - 30, t)
    c.rect(0, h - 14, w, h, t[1])
    c.rect(0, h - 14, w, h - 12, t[3])
    c.rect(0, h - 3, w, h, t[0])
    return outline_finish(c)


def wardrobe_chtholly_side(size, rnd):
    """L'armoire de Chtholly de flanc : dessus (corniche arrondie) vers le nord, flanc de bois miel à
    panneau relevé, petits pieds."""
    w, h = size
    c = Canvas(w, h, rnd)
    t = ramp("#C08040", 5, spread=0.4)
    top_h = int(OBLIQUE_FLAT * 1.0)
    c.rect(2, 2, w - 2, 2 + top_h, t[3])
    c.rect(2, 2, w - 2, 4, t[4])
    c.rect(w - 6, 2, w - 2, 2 + top_h, t[2])
    for x in range(12, w - 4, 11):
        c.rect(x, 4, x + 1, 2 + top_h - 2, t[2])
    c.rect(0, 2 + top_h - 5, w, 2 + top_h, t[1])
    # Flanc : corniche, panneau relevé, plinthe, pieds.
    y0 = 2 + top_h
    c.rect(0, y0, w, h - 6, t[2])
    c.rect(0, y0, w, y0 + 4, t[4])
    c.rect(0, y0 + 4, w, y0 + 6, t[1])
    c.rect(2, y0 + 8, w - 2, y0 + 10, t[3])
    for _ in range(12):
        gx = rnd.randint(3, w - 4)
        gy = rnd.randint(y0 + 14, h - 24)
        c.rect(gx, gy, gx + 1, gy + rnd.randint(6, 16), t[1] if rnd.random() < 0.6 else t[3])
    c.rect(7, y0 + 18, w - 7, h - 24, t[3])
    c.rect(9, y0 + 20, w - 9, h - 26, t[2])
    c.rect(9, y0 + 20, w - 9, y0 + 21, t[1])
    c.rect(9, y0 + 20, 10, h - 26, t[1])
    c.rect(w - 10, y0 + 20, w - 9, h - 26, t[4])
    c.rect(0, h - 20, w, h - 12, t[1])
    c.rect(0, h - 20, w, h - 18, t[3])
    for px in (3, w - 11):
        c.rect(px, h - 8, px + 8, h, t[0])
        c.rect(px, h - 8, px + 1, h, t[2])
    return outline_finish(c)


VIEW_RECIPES = ["sofa_beige_side", "bookshelf_tall_b_side", "wardrobe_chtholly_side"]


# --- Table des recettes ------------------------------------------------------------------------

PANELS = ["window_dusty", "wallitem_clippings"]
PROPS = ["piano_old", "roof_ladder", "roof_hatch", "roof_railing_broken"]
DECALS = ["runner_rug", "papers_floor", "bath_puddles", "cards_floor", "clothes_floor"]
ANIMS = ["pot_steam", "leak_drip", "drying_frame_wave"]

RECIPES = {}
for _name in PANELS:
    RECIPES["interior/" + _name] = globals()[_name]
for _name in PROPS:
    RECIPES["interior/props/" + _name] = globals()[_name]
for _name in VIEW_RECIPES:
    RECIPES["interior/props/" + _name] = globals()[_name]
for _name in DECALS:
    RECIPES["decals/" + _name] = globals()[_name]
for _name in ANIMS:
    RECIPES["anim/" + _name] = globals()[_name]

# Pour les outils (rien à exporter d'autre) : posterize, WrapCanvas, wrap_y restent disponibles.
_UNUSED = (posterize, WrapCanvas, wrap_y)
