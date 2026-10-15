#!/usr/bin/env python3
"""Remplaçants du lot I pour les cartes de l'entrepôt que la livraison n'a pas encore : les vues de flanc
du canapé des archives, d'une grande bibliothèque et de l'armoire de Chtholly (cahier n° 5, R0.3) et les
outils de dessin que tools/hd2d_village.py réemploie (wood, paper, inset, outline_finish).

Depuis la livraison du lot R1 (PR n° 37, I2), toutes les autres recettes de ce fichier (petite fenêtre
des archives, coupures, vieux piano, échelle et trappe du toit, module de rambarde tordu, décalques,
vapeur, goutte, linge au vent) sont parties : une image livrée sous le nom d'un remplaçant fait foi, et sa
recette s'en va avec lui. Chaque recette restante dessine l'image à sa taille exacte, en pixel art ; une
vraie image livrée sous le même nom la remplace sans toucher au code, et gen --force ne réécrit jamais un
fichier livré. Liste et entrées du manifeste : tools/hd2d_interior.py ; génération :
python3 tools/hd2d_assets.py gen --lot R0.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hd2d_art import Canvas, WrapCanvas, darker, posterize, ramp, wrap_y  # noqa: E402

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


def outline_finish(c, color=OUT_WOOD):
    return c.finish(color)


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

RECIPES = {}
for _name in VIEW_RECIPES:
    RECIPES["interior/props/" + _name] = globals()[_name]

# Pour les outils (rien à exporter d'autre) : posterize, WrapCanvas, wrap_y restent disponibles.
_UNUSED = (posterize, WrapCanvas, wrap_y)
