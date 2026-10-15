"""Remplaçants HD-2D de la ville haute et du snack-bar (lot CV ; cahier n° 5, docs/ASSETS_HD2D_ILE68.md, lot R4,
sections 6.4 à 6.7), pour les noms que les plans des cartes `ville_haute` et `ville_snack`
(docs/lore/CARTE.md, sections 9.2 et 9.4) citent et que le cahier n'a pas encore livrés :

- le dehors : une matière de volume (`buildings/materials/wall_stone_town`), dix façades de boutiques et de
  maisons de pierre avec leur flanc (`buildings/`), les enseignes, le bac, la fontaine murale, les marches, la
  trappe de cave, le muret, le garde-corps et deux lisières de toits (`props/`) ;
- le dedans : le sol de dalles claires, le mur de pierre apparente, l'enduit ocre, le comptoir, l'étagère, les
  tabourets et le plateau du snack-bar.

Une image livrée (ChatGPT) remplace le remplaçant du même nom, sans toucher au code, et sa recette s'en va avec
lui. Ces recettes sont lues par tools/hd2d_assets.py (recipes) ; leurs entrées du manifeste (lot R4) sont MANIFEST
ci-dessous (les images d'intérieur passent par les listes de tools/hd2d_interior.py : tailles, profondeurs,
scènes). Le résultat est déterministe (graine tirée du nom de chaque image).

    python3 tools/hd2d_ville.py manifest    # inscrit MANIFEST au manifeste, puis : tools/hd2d_assets.py gen
"""

import math

from PIL import Image, ImageDraw

import hd2d_ground
from hd2d_art import Canvas, WrapCanvas, darker, fractal, mix, noise, posterize, ramp, rgba, threshold
from hd2d_interior_props import DARK, IRON
from hd2d_props import boards, door
from hd2d_town import building_side, new_facade, shutters_closed

PPM = 96
STONE = "#C9BCA4"
# Les vitres : la couleur que la lueur de nuit des façades allume par défaut (#FFCA63 à 0,12 : Building.window_glow_color).
GLASS = ["#B8904A", "#E6B455", "#FFCA63", "#FFD06C", "#FFD676"]
BLUE_SHUTTER = "#6F8AA6"
GREEN_SHUTTER = "#5E7A5A"
BRASS = "brass"


# --- Matière de volume (192 × 192, sans raccord) -----------------------------------------------------------------


def wall_stone_town(size, rnd):
    """Pierre de taille gris-beige en assises régulières, joints fins, quelques blocs plus clairs ou ébréchés."""
    img = hd2d_ground._stones_rows(size, rnd, [32] * 6, (44, 70), "#8F8574", mix("stone", "#D6CBB6", 0.35),
                                   bevel=2, radius=2, grass_in_joints=False)
    pale = threshold(fractal(size, (5, 5), rnd, 3, gain=0.7), 222)
    img.paste(Image.new("RGBA", size, rgba("#E8DEC8")), (0, 0), pale.point(lambda v: int(v * 0.22)))
    return img


hd2d_ground.RECIPES.update({"buildings/materials/wall_stone_town": wall_stone_town})


# --- Façades et flancs ----------------------------------------------------------------------------------------------


def window(c, x, y, w, h, frame="wood_dark", shutters=None):
    """Fenêtre à croisillon, vitres aux tons de GLASS, volets pleins de chaque côté si shutters."""
    wood = ramp(frame, 5)
    c.rect(x - 3, y - 3, x + w + 3, y + h + 5, wood[1])
    c.rect(x, y, x + w, y + h, GLASS[2])
    c.rect(x, y, x + w, y + h * 0.4, GLASS[3])
    c.rect(x + 2, y + 2, x + w * 0.4, y + h * 0.3, GLASS[4])
    c.rect(x + w / 2.0 - 1, y, x + w / 2.0 + 1, y + h, wood[2])
    c.rect(x, y + h / 2.0 - 1, x + w, y + h / 2.0 + 1, wood[2])
    c.rect(x - 5, y + h + 3, x + w + 5, y + h + 7, wood[3])
    if shutters:
        boards(c, x - 3 - w * 0.45, y - 2, x - 3, y + h + 3, shutters, width=6)
        boards(c, x + w + 3, y - 2, x + w + 3 + w * 0.45, y + h + 3, shutters, width=6)


def quoins(c, w, h, top, plinth=0, step=64, color="#E2D8C2"):
    """Chaînages d'angle : blocs clairs alternés à gauche et à droite."""
    tones = ramp(color, 4)
    y = h - plinth - step
    k = 0
    while y > top + 8:
        wide = 26 if k % 2 == 0 else 18
        for x0 in (0, w - wide):
            c.rect(x0, y, x0 + wide, y + step - 4, tones[2])
            c.rect(x0, y, x0 + wide, y + 2, tones[3])
            c.rect(x0, y + step - 6, x0 + wide, y + step - 4, tones[0])
        y -= step
        k += 1


def cornice(c, x0, x1, y, color="#E2D8C2", thick=8):
    tones = ramp(color, 4)
    c.rect(x0, y, x1, y + thick, tones[2])
    c.rect(x0, y, x1, y + 2, tones[3])
    c.rect(x0, y + thick, x1, y + thick + 3, tones[0])


def steps(c, cx, y_base, width, count=3, rise=10):
    """Marches de pierre devant une porte (de la plus large, en bas, à la plus étroite)."""
    tones = ramp("#C9BCA4", 5)
    for k in range(count):
        half = width / 2.0 - k * 4
        top = y_base - (k + 1) * rise
        c.rect(cx - half, top, cx + half, y_base - k * rise, tones[2])
        c.rect(cx - half, top, cx + half, top + 2, tones[4])
        c.rect(cx - half, y_base - k * rise - 2, cx + half, y_base - k * rise, tones[0])


def arch_door(c, x, y, w, h, base="#4A6A8A", metal=False):
    """Porte à linteau de pierre, battant planche, poignée de laiton."""
    stone = ramp("#D6CBB6", 5)
    c.rect(x - 8, y - 12, x + w + 8, y, stone[3])
    c.rect(x - 8, y - 12, x + w + 8, y - 10, stone[4])
    c.rect(x - 8, y - 2, x + w + 8, y, stone[0])
    c.rect(x - 8, y, x, y + h, stone[2])
    c.rect(x + w, y, x + w + 8, y + h, stone[1])
    door(c, x, y, w, h, base, metal=metal)


def balcony(c, x0, x1, y, rise=34):
    """Balcon de fer forgé : dalle, barreaux, main courante."""
    iron = ramp(IRON, 4)
    c.rect(x0, y, x1, y + 8, ramp("#C9BCA4", 4)[1])
    c.rect(x0, y + 8, x1, y + 10, ramp("#C9BCA4", 4)[0])
    c.rect(x0, y - rise, x1, y - rise + 4, iron[2])
    for x in range(int(x0) + 4, int(x1) - 2, 12):
        c.rect(x, y - rise + 4, x + 3, y, iron[0])
        c.ellipse(x + 1, y - rise // 2, 3, 3, iron[1])


def pots(c, x, y_base, count=3, colors=("#C8503A", "#E0A040", "#B060A0")):
    for k in range(count):
        px = x + k * 20
        c.rect(px, y_base - 14, px + 14, y_base, ramp("#B8603A", 4)[2])
        c.rect(px - 1, y_base - 16, px + 15, y_base - 13, ramp("#B8603A", 4)[3])
        c.blob(px + 7, y_base - 22, 10, 8, ramp(colors[k % len(colors)], 4))


def town_house_a(size, rnd):
    def features(c, w, h, top):
        quoins(c, w, h, top, plinth=48)
        cx = w * 0.5
        arch_door(c, cx - 36, h - 48 - 30 - 150, 72, 150, "#4A6A8A")
        steps(c, cx, h - 48 + 2, 128, 3, 10)
        for row, y in enumerate((h - 340, h - 520, top + 44)):
            for fx in (0.2, 0.62):
                window(c, w * fx, y, 56, 82, "wood_dark", shutters=BLUE_SHUTTER)
            cornice(c, 0, w, y - 18 if row else y - 20, thick=6)
        cornice(c, 0, w, top + 2, thick=10)
    return new_facade(size, rnd, "wall_stone_town", "roof_slate_b", "pignon", 6.0, plinth=48, plinth_mat="wall_stone",
                      features=features)


def town_house_a_side(size, rnd):
    def features(c, w, h, top):
        for y in (h - 340, h - 180):
            window(c, w * 0.42, y, 60, 82, "wood_dark", shutters=BLUE_SHUTTER)
    return building_side(size, rnd, "wall_stone_town", "roof_slate_b", plinth=48, features=features)


def town_house_b(size, rnd):
    def features(c, w, h, top):
        quoins(c, w, h, top, plinth=40, step=72)
        # Rez-de-chaussée : une boutique fermée par de lourds volets de bois, la porte à droite.
        shutters_closed(c, w * 0.07, h - 250, 330, 200, "#7A5A44")
        arch_door(c, w * 0.62, h - 40 - 200, 90, 200, "#5A4A3A")
        cornice(c, 0, w, h - 270, thick=8)
        # Étage : trois fenêtres, un balcon de fer au droit des deux premières.
        for k in range(3):
            window(c, w * (0.1 + 0.3 * k), top + 70, 64, 100, "wood_dark", shutters=GREEN_SHUTTER)
        balcony(c, w * 0.04, w * 0.62, top + 196, 36)
        pots(c, w * 0.12, top + 196, 3)
        cornice(c, 0, w, top + 4, thick=8)
    return new_facade(size, rnd, "wall_stone_town", "roof_tiles_b", "long", 6.0, plinth=40, plinth_mat="wall_stone",
                      features=features)


def town_house_b_side(size, rnd):
    def features(c, w, h, top):
        for y in (h - 330, h - 170):
            window(c, w * 0.4, y, 60, 84, "wood_dark", shutters=GREEN_SHUTTER)
    return building_side(size, rnd, "wall_stone_town", "roof_tiles_b", gable_wall_m=6.0, plinth=40, features=features)


def town_house_c(size, rnd):
    def features(c, w, h, top):
        # Pierre au rez-de-chaussée ; l'étage, à colombages, avance en encorbellement.
        ground_top = h - 250
        beam = ramp(DARK, 5)
        plaster = ramp("#E2D6BC", 5)
        c.rect(-6, ground_top - 150, w + 6, ground_top + 4, plaster[2])
        for k in range(4):
            x = -6 + (w + 12) * k / 3.0
            c.rect(x, ground_top - 150, x + 10, ground_top + 4, beam[1])
        c.rect(-6, ground_top - 150, w + 6, ground_top - 140, beam[1])
        c.rect(-6, ground_top - 6, w + 6, ground_top + 8, beam[1])
        c.rect(-6, ground_top + 8, w + 6, ground_top + 14, beam[0])
        window(c, w * 0.36, ground_top - 112, 70, 80, "wood_dark", shutters=GREEN_SHUTTER)
        arch_door(c, w * 0.34, h - 28 - 176, 80, 176, "#4F73A8")
        window(c, w * 0.36, top + 90, 60, 76, "wood_dark")
        c.rect(0, top + 40, w, top + 48, beam[2])
    return new_facade(size, rnd, "wall_stone_town", "roof_tiles", "pignon", 4.5, plinth=28, plinth_mat="wall_stone",
                      features=features)


def town_house_c_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 280, 60, 76, "wood_dark", shutters=GREEN_SHUTTER)
        window(c, w * 0.42, h - 150, 60, 76, "wood_dark")
    return building_side(size, rnd, "wall_stone_town", "roof_tiles", plinth=28, features=features)


def town_house_d(size, rnd):
    def features(c, w, h, top):
        quoins(c, w, h, top, plinth=24, step=60)
        cx = w * 0.5
        # Porte cochère : arc de pierre sur un passage sombre.
        stone = ramp("#D6CBB6", 5)
        dark = ramp("#2A2430", 4)
        c.rect(cx - 66, h - 200, cx + 66, h, dark[1])
        c.ellipse(cx, h - 200, 66, 52, dark[1])
        c.rect(cx - 66, h - 200, cx + 66, h - 24, dark[1])
        for k in range(9):
            a0 = math.pi + math.pi * k / 9.0
            a1 = math.pi + math.pi * (k + 1) / 9.0
            c.poly([(cx + math.cos(a0) * 66, h - 200 + math.sin(a0) * 56), (cx + math.cos(a1) * 66, h - 200 + math.sin(a1) * 56),
                    (cx + math.cos(a1) * 84, h - 200 + math.sin(a1) * 72), (cx + math.cos(a0) * 84, h - 200 + math.sin(a0) * 72)],
                   stone[2 + k % 2])
        c.rect(cx - 84, h - 200, cx - 66, h, stone[2])
        c.rect(cx + 66, h - 200, cx + 84, h, stone[1])
        for fx in (0.1, 0.72):
            window(c, w * fx, h - 220, 58, 90, "wood_dark", shutters="#8A8A70")
        c.rect(cx - 40, h - 70, cx + 40, h - 24, dark[2])
        cornice(c, 0, w, top + 2, thick=8)
    return new_facade(size, rnd, "wall_stone_b", "roof_slate", "long", 4.5, plinth=24, plinth_mat="wall_stone",
                      features=features)


def town_house_d_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.4, h - 230, 60, 84, "wood_dark", shutters="#8A8A70")
    return building_side(size, rnd, "wall_stone_b", "roof_slate", gable_wall_m=4.5, plinth=24, features=features)


def town_house_e(size, rnd):
    def features(c, w, h, top):
        quoins(c, w, h, top, plinth=48, step=72)
        cx = w * 0.5
        arch_door(c, cx - 40, h - 48 - 30 - 160, 80, 160, "#4A6A8A")
        steps(c, cx, h - 48 + 2, 136, 3, 10)
        for row, y in enumerate((h - 360, h - 560, h - 760)):
            for fx in (0.17, 0.66):
                window(c, w * fx, y, 56, 86, "wood_dark", shutters=BLUE_SHUTTER)
            cornice(c, 0, w, y - 20, thick=6)
        # Lucarne dans le pignon, girouette en poisson volant au faîte.
        window(c, cx - 26, top + 150, 52, 72, "wood_dark")
        c.poly([(cx - 40, top + 150), (cx, top + 100), (cx + 40, top + 150)], ramp(DARK, 5)[1])
        iron = ramp(IRON, 4)
        c.rect(cx - 1, 0, cx + 2, 40, iron[0])
        c.poly([(cx - 22, 16), (cx - 6, 8), (cx + 8, 12), (cx + 24, 4), (cx + 20, 20), (cx + 8, 22), (cx - 6, 28), (cx - 22, 16)], iron[2])
    return new_facade(size, rnd, "wall_stone_town", "roof_slate_b", "pignon", 7.5, plinth=48, plinth_mat="wall_stone",
                      features=features)


def town_house_e_side(size, rnd):
    def features(c, w, h, top):
        for y in (h - 440, h - 290, h - 140):
            window(c, w * 0.42, y, 60, 84, "wood_dark", shutters=BLUE_SHUTTER)
    return building_side(size, rnd, "wall_stone_town", "roof_slate_b", plinth=48, features=features)


def town_house_f(size, rnd):
    def features(c, w, h, top):
        cx = w * 0.5
        arch_door(c, cx - 38, h - 30 - 190, 76, 190, "#8A5A3A")
        for fx in (0.1, 0.68):
            window(c, w * fx, h - 230, 66, 96, "wood_dark", shutters="#B8603A")
        # Un banc et des pots de géraniums au pied du mur.
        bench = ramp("#A57C58", 5)
        c.rect(w * 0.7, h - 56, w * 0.7 + 110, h - 46, bench[3])
        c.rect(w * 0.7 + 8, h - 46, w * 0.7 + 14, h - 4, bench[1])
        c.rect(w * 0.7 + 96, h - 46, w * 0.7 + 102, h - 4, bench[1])
        pots(c, w * 0.07, h - 4, 3, ("#D8504A", "#E07A5A", "#D8504A"))
        pots(c, cx + 52, h - 4, 2, ("#D8504A", "#E0A040"))
    return new_facade(size, rnd, "wall_plaster_b", "roof_tiles_b", "long", 3.5, plinth=24, features=features)


def town_house_f_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 200, 60, 80, "wood_dark", shutters="#B8603A")
    return building_side(size, rnd, "wall_plaster_b", "roof_tiles_b", gable_wall_m=3.5, plinth=24, features=features)


def sign_bracket(c, x, y, arm, drop):
    """Potence de fer, accrochée au mur : le bras et la chaînette."""
    iron = ramp(IRON, 4)
    c.rect(x, y, x + arm, y + 5, iron[1])
    c.line([(x + 6, y + 36), (x + arm * 0.7, y + 5)], iron[0], 2)
    c.rect(x + arm - 4, y + 5, x + arm - 2, y + drop, iron[0])


def cafe_town(size, rnd):
    def features(c, w, h, top):
        quoins(c, w, h, top, plinth=24, step=70)
        iron = ramp(IRON, 4)
        glass = GLASS
        wd = ramp(DARK, 5)
        # Trois grandes baies, la porte vitrée au milieu.
        for fx in (0.06, 0.66):
            c.rect(w * fx - 5, h - 250, w * fx + 205, h - 28, wd[1])
            c.rect(w * fx, h - 244, w * fx + 200, h - 34, glass[2])
            c.rect(w * fx, h - 244, w * fx + 200, h - 150, glass[3])
            c.rect(w * fx + 98, h - 244, w * fx + 102, h - 34, wd[2])
            c.rect(w * fx, h - 140, w * fx + 200, h - 136, wd[2])
            c.rect(w * fx + 10, h - 236, w * fx + 70, h - 200, glass[4])
        dx = w * 0.41
        c.rect(dx - 5, h - 250, dx + 100, h - 24, wd[1])
        c.rect(dx, h - 244, dx + 95, h - 30, glass[2])
        c.rect(dx, h - 244, dx + 95, h - 150, glass[3])
        c.rect(dx + 46, h - 244, dx + 50, h - 30, wd[2])
        c.rect(dx + 78, h - 140, dx + 84, h - 128, ramp(BRASS, 3)[2])
        # Deux tables rondes dehors, deux chaises chacune.
        for tx in (w * 0.17, w * 0.86):
            c.ellipse(tx, h - 52, 24, 6, ramp("#A57C58", 4)[3])
            c.rect(tx - 2, h - 50, tx + 2, h - 4, ramp(IRON, 4)[1])
            c.rect(tx - 12, h - 6, tx + 12, h - 2, ramp(IRON, 4)[0])
            for cx_ in (-34, 34):
                c.rect(tx + cx_ - 8, h - 42, tx + cx_ + 8, h - 38, ramp("#6F5238", 4)[2])
                c.rect(tx + cx_ - 7, h - 38, tx + cx_ - 4, h - 4, ramp("#6F5238", 4)[1])
                c.rect(tx + cx_ + 4, h - 38, tx + cx_ + 7, h - 4, ramp("#6F5238", 4)[1])
        # L'enseigne en tasse est un décor à part (props/hanging_sign_cup, posé par la carte).
        cornice(c, 0, w, top + 2, thick=8)
    return new_facade(size, rnd, "wall_stone_town", "roof_slate_b", "long", 4.0, plinth=24, plinth_mat="wall_stone",
                      features=features)


def cafe_town_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.4, h - 230, 70, 100, "wood_dark")
        window(c, w * 0.4, h - 370, 70, 90, "wood_dark")
    return building_side(size, rnd, "wall_stone_town", "roof_slate_b", gable_wall_m=4.0, plinth=24, features=features)


def shop_snack(size, rnd):
    def features(c, w, h, top):
        wd = ramp(DARK, 5)
        stone = ramp("#D6CBB6", 5)
        # Le comptoir ouvert sur la rue : une baie sombre, la plaque de cuisson dans le fond, les braises.
        c.rect(w * 0.12 - 8, h - 250, w * 0.88 + 8, h - 6, stone[2])
        c.rect(w * 0.12, h - 242, w * 0.88, h - 70, ramp("#3A2A26", 4)[1])
        c.rect(w * 0.12, h - 242, w * 0.88, h - 232, ramp("#3A2A26", 4)[0])
        # Le fond de la cuisine : une étagère de pots et de bouteilles, des ustensiles pendus à une barre.
        shelf = ramp("#7A5A40", 4)
        c.rect(w * 0.16, h - 176, w * 0.84, h - 170, shelf[3])
        for k, col in enumerate(("#A8785A", "#C8A040", "#8AA050", "#A8785A", "#B8906A", "#C8A040", "#8A6A52", "#8AA050")):
            jx = w * (0.18 + 0.082 * k)
            c.rect(jx, h - 198, jx + 20, h - 176, ramp(col, 4)[2])
            c.rect(jx + 5, h - 206, jx + 15, h - 198, ramp(col, 4)[1])
        c.rect(w * 0.14, h - 226, w * 0.86, h - 222, ramp(IRON, 4)[1])
        for k in range(6):
            ux = w * (0.2 + 0.12 * k)
            c.rect(ux, h - 222, ux + 2, h - 206, ramp(IRON, 4)[0])
            c.ellipse(ux + 1, h - 200 + (k % 2) * 4, 8 if k % 2 else 5, 9 if k % 2 else 7, ramp(IRON, 4)[2])
        # Plaque et poêle au fond : lueur de cristal.
        c.rect(w * 0.3, h - 124, w * 0.7, h - 104, ramp(IRON, 4)[1])
        c.blob(w * 0.5, h - 104, w * 0.16, 14, ramp("#FFB062", 4))
        c.ellipse(w * 0.4, h - 134, 22, 7, ramp(IRON, 4)[2])
        c.rect(w * 0.4 + 16, h - 138, w * 0.4 + 56, h - 134, ramp(IRON, 4)[1])
        # Le comptoir de bois.
        c.rect(w * 0.1, h - 78, w * 0.9, h - 66, ramp("#A57C58", 5)[3])
        boards(c, w * 0.1, h - 66, w * 0.9, h - 8, "wood", vertical=True, width=14)
        c.rect(w * 0.1, h - 10, w * 0.9, h, wd[1])
        # Trois tabourets hauts devant, de dos.
        for k in range(3):
            sx = w * (0.26 + 0.24 * k)
            c.ellipse(sx, h - 62, 15, 5, ramp("#8A6A48", 4)[3])
            c.rect(sx - 10, h - 58, sx - 7, h - 2, ramp("#6F5238", 4)[1])
            c.rect(sx + 7, h - 58, sx + 10, h - 2, ramp("#6F5238", 4)[1])
        # L'auvent de toile rayée.
        cloth = ramp("#C0503A", 4)
        for k in range(10):
            x0 = w * 0.04 + k * (w * 0.92 / 10.0)
            col = cloth[3] if k % 2 else ramp("#F2EEE0", 4)[2]
            c.poly([(x0, h - 262), (x0 + w * 0.092, h - 262), (x0 + w * 0.092, h - 236), (x0 + w * 0.046, h - 222), (x0, h - 236)], col)
        c.rect(w * 0.03, h - 268, w * 0.97, h - 260, ramp(IRON, 4)[1])
        # L'enseigne en poêle est un décor à part (props/hanging_sign_pan, posé par la carte).
        cornice(c, 0, w, top + 2, thick=8)
    return new_facade(size, rnd, "wall_stone_town", "roof_tiles", "long", 3.5, plinth=0, features=features)


def shop_snack_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.4, h - 220, 64, 84, "wood_dark", shutters=GREEN_SHUTTER)
    return building_side(size, rnd, "wall_stone_town", "roof_tiles", gable_wall_m=3.5, plinth=24, features=features)


def shop_accessories(size, rnd):
    def features(c, w, h, top):
        quoins(c, w, h, top, plinth=24, step=64)
        wd = ramp(DARK, 5)
        glass = GLASS
        # La vitrine de chapeaux, sur des têtes de bois.
        c.rect(w * 0.08 - 5, h - 230, w * 0.92 + 5, h - 24, wd[1])
        c.rect(w * 0.08, h - 224, w * 0.92, h - 30, ramp("#CFA9B0", 4)[1])
        c.rect(w * 0.08, h - 224, w * 0.92, h - 150, glass[3])
        for k, col in enumerate(("#3A4A7A", "#B8503A", "#6F8A5A")):
            hx = w * (0.22 + 0.28 * k)
            c.ellipse(hx, h - 96, 14, 20, ramp("#C8A070", 4)[2])
            c.rect(hx - 3, h - 80, hx + 3, h - 32, ramp("#8A6A48", 4)[1])
            c.ellipse(hx, h - 112, 28, 7, ramp(col, 4)[1])
            c.rect(hx - 15, h - 128, hx + 15, h - 112, ramp(col, 4)[2])
            c.rect(hx - 15, h - 118, hx + 15, h - 113, ramp("#E8D8A8", 4)[2])
        c.rect(w * 0.08, h - 30, w * 0.92, h - 24, wd[0])
        # L'auvent vert.
        cloth = ramp("#5E7A5A", 4)
        for k in range(8):
            x0 = w * 0.04 + k * (w * 0.92 / 8.0)
            c.poly([(x0, h - 252), (x0 + w * 0.115, h - 252), (x0 + w * 0.115, h - 232), (x0 + w * 0.0575, h - 218), (x0, h - 232)],
                   cloth[3] if k % 2 else cloth[2])
        c.rect(w * 0.03, h - 258, w * 0.97, h - 251, ramp(IRON, 4)[1])
        # La porte à gauche de l'étage ? non : l'étage a une fenêtre ronde et l'enseigne en chapeau.
        window(c, w * 0.36, top + 70, 64, 80, "wood_dark", shutters="#8A8A70")
        sign_bracket(c, w - 76, h - 330, 58, 28)
        hat = ramp("#3A4A7A", 4)
        c.ellipse(w - 28, h - 296, 22, 6, hat[1])
        c.rect(w - 42, h - 316, w - 14, h - 296, hat[2])
        c.rect(w - 42, h - 306, w - 14, h - 302, ramp("#E8D8A8", 4)[2])
        cornice(c, 0, w, top + 2, thick=8)
    return new_facade(size, rnd, "wall_plaster", "roof_tiles", "pignon", 4.0, plinth=24, features=features)


def shop_accessories_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 220, 60, 80, "wood_dark", shutters="#8A8A70")
    return building_side(size, rnd, "wall_plaster", "roof_tiles", plinth=24, features=features)


def shop_apothecary(size, rnd):
    def features(c, w, h, top):
        quoins(c, w, h, top, plinth=24, step=64)
        wd = ramp(DARK, 5)
        glass = GLASS
        # La vitrine de bocaux de verre colorés, la porte vitrée à droite.
        c.rect(w * 0.06 - 5, h - 236, w * 0.58 + 5, h - 24, wd[1])
        c.rect(w * 0.06, h - 230, w * 0.58, h - 30, glass[2])
        for row in range(3):
            y = h - 214 + row * 62
            c.rect(w * 0.06, y + 44, w * 0.58, y + 50, wd[2])
            for k, col in enumerate(("#6FA06A", "#B8603A", "#5A7AB0", "#C8A040", "#A060A0")):
                jx = w * (0.1 + 0.095 * k)
                c.rect(jx, y + 12, jx + 22, y + 44, ramp(col, 4)[2])
                c.rect(jx + 4, y + 6, jx + 18, y + 12, ramp("#E8D8A8", 4)[1])
        dx = w * 0.66
        c.rect(dx - 5, h - 236, dx + 88, h - 24, wd[1])
        c.rect(dx, h - 230, dx + 83, h - 30, glass[2])
        c.rect(dx, h - 230, dx + 83, h - 150, glass[3])
        c.rect(dx + 38, h - 230, dx + 42, h - 30, wd[2])
        c.rect(dx + 66, h - 130, dx + 72, h - 118, ramp(BRASS, 3)[2])
        window(c, w * 0.3, top + 80, 64, 90, "wood_dark", shutters=GREEN_SHUTTER)
        # Enseigne : un mortier et son pilon, à une potence.
        sign_bracket(c, w - 78, h - 330, 60, 32)
        m = ramp("#8A8A8A", 4)
        c.poly([(w - 50, h - 298), (w - 18, h - 298), (w - 24, h - 270), (w - 44, h - 270)], m[2])
        c.rect(w - 52, h - 302, w - 16, h - 297, m[3])
        c.line([(w - 34, h - 300), (w - 24, h - 326)], ramp("#A57C58", 4)[2], 5)
        cornice(c, 0, w, top + 2, thick=8)
    return new_facade(size, rnd, "wall_stone_town", "roof_slate", "pignon", 4.0, plinth=24, plinth_mat="wall_stone",
                      features=features)


def shop_apothecary_side(size, rnd):
    def features(c, w, h, top):
        window(c, w * 0.42, h - 220, 60, 80, "wood_dark", shutters=GREEN_SHUTTER)
    return building_side(size, rnd, "wall_stone_town", "roof_slate", plinth=24, features=features)


# --- Enseignes et petits décors de rue --------------------------------------------------------------------------


def hanging_sign_shape(size, rnd, shape):
    """Enseigne de fer pendue à une potence, un objet découpé, sans texte."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 4)
    c.rect(w * 0.08, 0, w * 0.14, h, iron[1])
    c.rect(w * 0.08, h * 0.08, w * 0.94, h * 0.13, iron[1])
    c.line([(w * 0.12, h * 0.4), (w * 0.6, h * 0.13)], iron[0], 2)
    for x in (0.4, 0.82):
        c.rect(w * x, h * 0.13, w * x + 2, h * 0.3, iron[0])
    cx, cy = w * 0.6, h * 0.62
    if shape == "pan":
        c.ellipse(cx, cy, 26, 20, iron[0])
        c.ellipse(cx, cy, 22, 16, iron[2])
        c.ellipse(cx - 4, cy - 3, 12, 8, iron[3])
        c.rect(cx - 56, cy - 4, cx - 24, cy + 3, iron[1])
        c.ellipse(cx - 56, cy, 3, 3, iron[0])
    elif shape == "cup":
        copper = ramp("#B0703A", 4)
        c.rect(cx - 16, cy - 12, cx + 14, cy + 16, copper[2])
        c.rect(cx - 18, cy - 14, cx + 16, cy - 9, copper[3])
        c.ellipse(cx + 20, cy + 2, 7, 9, copper[1])
        c.rect(cx - 12, cy + 16, cx + 10, cy + 20, copper[0])
        for k, dx in enumerate((-6, 2, 8)):
            c.line([(cx + dx, cy - 18 - k * 3), (cx + dx + 3, cy - 30 - k * 3)], ramp("#F2EEE0", 4)[2], 2)
    elif shape == "hat":
        hat = ramp("#3A4A7A", 4)
        c.ellipse(cx, cy + 4, 28, 7, hat[1])
        c.rect(cx - 16, cy - 16, cx + 16, cy + 4, hat[2])
        c.rect(cx - 16, cy - 6, cx + 16, cy, ramp("#E8D8A8", 4)[2])
    elif shape == "mortar":
        m = ramp("#8A8A8A", 4)
        c.poly([(cx - 20, cy), (cx + 14, cy), (cx + 8, cy + 24), (cx - 14, cy + 24)], m[2])
        c.rect(cx - 22, cy - 4, cx + 16, cy + 1, m[3])
        c.line([(cx - 2, cy - 2), (cx + 10, cy - 30)], ramp("#A57C58", 4)[2], 5)
    c.rect(w * 0.05, h - 4, w * 0.18, h, iron[0])
    return c.finish(darker(IRON, 0.4))


def stone_trough(c, x0, x1, y0, y1, base="#C9BCA4"):
    tones = ramp(base, 5)
    c.rect(x0, y0, x1, y1, tones[2])
    c.rect(x0, y0, x1, y0 + 4, tones[4])
    c.rect(x0, y0 + 4, x1, y0 + 8, tones[3])
    c.rect(x0, y1 - 5, x1, y1, tones[0])
    for k in range(1, 4):
        x = x0 + (x1 - x0) * k / 4.0
        c.rect(x, y0 + 8, x + 2, y1 - 5, tones[1])


def town_planter_stone(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone_trough(c, 4, w - 4, h * 0.46, h)
    for _ in range(26):
        x = rnd.uniform(12, w - 12)
        col = rnd.choice(["#8A60B0", "#B070C0", "#8A60B0", "#A0508A", "#6E8A4E", "#6E8A4E"])
        c.blob(x, h * 0.34 + rnd.uniform(-10, 4), rnd.uniform(5, 9), rnd.uniform(5, 8), ramp(col, 4))
    return c.finish(darker("#4A3A30", 0.5))


def town_wall_fountain(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("#C9BCA4", 5)
    c.rect(2, 4, w - 2, h * 0.66, stone[2])
    for row in range(5):
        y = 4 + row * (h * 0.62 / 5.0)
        c.rect(2, y, w - 2, y + 2, stone[1])
        for x in range(10 + (row % 2) * 12, w - 6, 28):
            c.rect(x, y, x + 2, y + h * 0.62 / 5.0, stone[1])
    c.rect(2, 2, w - 2, 8, stone[4])
    verd = ramp(mix("#B0703A", "#5A9A8A", 0.55), 5)
    c.rect(w * 0.46, h * 0.24, w * 0.54, h * 0.4, verd[2])
    c.rect(w * 0.44, h * 0.4, w * 0.56, h * 0.46, verd[3])
    c.ellipse(w * 0.5, h * 0.2, 10, 10, verd[2])
    c.rect(w * 0.47, h * 0.46, w * 0.53, h * 0.6, ramp("#7AB0D8", 3)[1])
    stone_trough(c, 6, w - 6, h * 0.62, h)
    c.line([(w * 0.8, h * 0.28), (w * 0.82, h * 0.5)], ramp(IRON, 4)[1], 2)
    c.rect(w * 0.78, h * 0.5, w * 0.88, h * 0.58, ramp(IRON, 4)[2])
    return c.finish(darker("#4A4038", 0.5))


def town_doorsteps(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    steps(c, w / 2.0, h, w - 4, 3, 14)
    c.rect(w * 0.34, 4, w * 0.66, 14, ramp("#8A6A48", 4)[2])
    for x in range(int(w * 0.34), int(w * 0.66), 4):
        c.rect(x, 4, x + 1, 14, ramp("#8A6A48", 4)[1])
    return c.finish(darker("#4A4038", 0.5))


def town_cellar_hatch(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    c.poly([(4, h), (w - 4, h), (w - 14, 6), (14, 6)], ramp("#8A6A48", 5)[2])
    for k in range(1, 6):
        x = 4 + (w - 8) * k / 6.0
        c.line([(x, h), (14 + (w - 28) * k / 6.0, 6)], ramp("#654D3C", 4)[0], 1)
    c.poly([(14, 6), (w - 14, 6), (w - 14, 12), (14, 12)], ramp("#A57C58", 4)[3])
    for y in (h * 0.3, h * 0.68):
        c.rect(8, y, w - 8, y + 5, ramp(IRON, 4)[1])
        c.rect(w * 0.5 - 4, y - 1, w * 0.5 + 4, y + 7, ramp(IRON, 4)[2])
    return c.finish(darker("#4A3A30", 0.5))


def town_wall_low(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    stone = ramp("#B0A58E", 5)
    c.rect(0, h * 0.18, w, h, stone[2])
    y = h * 0.28
    row = 0
    while y < h - 4:
        x = -rnd.randint(0, 20)
        while x < w:
            sw = rnd.randint(26, 46)
            col = stone[rnd.choice([1, 2, 2, 3])]
            c.rect(x + 1, y + 1, min(x + sw, w) - 1, y + 16, col)
            c.rect(x + 1, y + 1, min(x + sw, w) - 1, y + 3, stone[4])
            x += sw
        y += 18
        row += 1
    cap = ramp("#C9BCA4", 5)
    c.rect(0, 0, w, h * 0.2, cap[3])
    c.rect(0, 0, w, 3, cap[4])
    c.rect(0, h * 0.2 - 3, w, h * 0.2, cap[0])
    for x in range(40, w, 48):
        c.rect(x, 0, x + 1, h * 0.2, cap[1])
    for _ in range(8):
        c.blob(rnd.uniform(6, w - 6), rnd.uniform(2, h * 0.3), rnd.uniform(4, 9), 3, ramp("#5E7A3A", 4))
    return c.finish(darker("#4A4038", 0.5))


def town_railing(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp("#5A4A42", 5)
    rust = ramp("#8A5A3A", 4)
    c.rect(0, 6, w, 14, iron[2])
    c.rect(0, h - 10, w, h, iron[1])
    for x in range(8, w - 6, 16):
        c.rect(x, 14, x + 4, h - 10, iron[2])
        c.rect(x + 3, 14, x + 4, h - 10, iron[0])
        c.poly([(x - 2, 14), (x + 2, 2), (x + 6, 14)], iron[3])
    for x in range(20, w - 20, 64):
        c.ellipse(x + 8, h * 0.5, 14, 14, iron[0])
        c.ellipse(x + 8, h * 0.5, 10, 10, iron[2])
        c.rect(x - 6, h * 0.5 - 1, x + 22, h * 0.5 + 1, iron[3])
    for _ in range(16):
        x, y = rnd.randint(4, w - 8), rnd.randint(8, h - 14)
        c.rect(x, y, x + rnd.randint(1, 3), y + rnd.randint(2, 6), rust[1])
    return c.finish(darker("#3A3030", 0.5))


# --- Lisières de toits (les lointains de la ville qui monte au nord) -----------------------------------------------


def _roofs(size, rnd, rows, spread):
    """La ville vue de loin, en rangées de toits qui se recouvrent (les plus éloignées plus hautes, plus petites et
    plus bleutées), cheminées, un clocher de pierre, quelques arbres dorés entre les toits, un mur de jardin au pied ;
    sans raccord à gauche et à droite."""
    w, h = size
    c = WrapCanvas(w, h, rnd)
    slate = ["#5E6C86", "#6A5A62", "#5A6A7A"]
    tiles = ["#B65E4B", "#A8503E", "#C07A4A"]
    step = min(118, (h - 110) // rows)
    tower_row = rows // 2
    tower_x = int(w * rnd.uniform(0.3, 0.6))
    for row in range(rows):
        far = 1.0 - row / float(max(1, rows - 1))
        base_y = h - 36 - (rows - 1 - row) * step
        scale = 1.0 - 0.42 * far
        haze = 0.5 * far
        wall = ramp(mix("#C9BCA4", "#A8A4C4", 0.2 + haze), 4)
        x = rnd.randint(0, 40)
        while x < w + 40:
            house_w = int(rnd.randint(150, 230) * scale)
            wall_h = int(rnd.randint(110, 160) * scale)
            ridge_h = int(rnd.randint(60, 100) * scale)
            gable = rnd.random() < 0.5
            palette = rnd.choice([slate, tiles, slate])
            roof = ramp(mix(rnd.choice(palette), "#9AA0C0", 0.1 + 0.5 * far), 5)
            y1 = base_y
            y0 = y1 - wall_h
            c.rect(x, y0, x + house_w, y1 + 6, wall[1])
            c.rect(x, y0, x + 4, y1 + 6, wall[0])
            if gable:
                c.poly([(x - 6, y0), (x + house_w / 2.0, y0 - ridge_h), (x + house_w + 6, y0)], roof[2])
                c.poly([(x + house_w / 2.0, y0 - ridge_h), (x + house_w + 6, y0), (x + house_w * 0.62, y0)], roof[1])
            else:
                c.poly([(x - 8, y0 + 4), (x + 10, y0 - ridge_h * 0.7), (x + house_w - 10, y0 - ridge_h * 0.7),
                        (x + house_w + 8, y0 + 4)], roof[2])
                c.rect(x + 10, y0 - ridge_h * 0.7, x + house_w - 10, y0 - ridge_h * 0.7 + 4, roof[3])
            for wx in range(int(x + 16 * scale + 8), int(x + house_w - 24), int(46 * scale + 14)):
                c.rect(wx, y0 + 18 * scale, wx + 18 * scale, y0 + 18 * scale + 30 * scale, ramp("#3A4A66", 3)[1])
                c.rect(wx, y0 + 58 * scale, wx + 18 * scale, y0 + 58 * scale + 30 * scale, ramp("#3A4A66", 3)[1])
            if rnd.random() < 0.6:
                chx = x + house_w * rnd.uniform(0.2, 0.7)
                top = y0 - ridge_h * (0.9 if gable else 0.7)
                c.rect(chx, top - 26 * scale, chx + 14 * scale, top + 10, ramp("#A0584A", 4)[1])
                c.rect(chx - 2, top - 30 * scale, chx + 16 * scale, top - 24 * scale, ramp("#A0584A", 4)[3])
            x += house_w + rnd.randint(-14, 8)
        if row == tower_row:
            # Le clocher de pierre, planté dans cette rangée : fût, étage des cloches (arcs sombres), flèche d'ardoise.
            tw = int(74 * scale + 10)
            top = base_y - int(330 * scale)
            c.rect(tower_x, top, tower_x + tw, base_y + 6, ramp("#C9BCA4", 5)[2])
            c.rect(tower_x, top, tower_x + 5, base_y + 6, ramp("#C9BCA4", 5)[3])
            c.rect(tower_x + tw - 6, top, tower_x + tw, base_y + 6, ramp("#C9BCA4", 5)[1])
            for k in range(2):
                ax = tower_x + tw * (0.2 + 0.4 * k)
                c.rect(ax, top + 30 * scale, ax + tw * 0.24, top + 80 * scale, ramp("#2A2430", 3)[1])
                c.ellipse(ax + tw * 0.12, top + 30 * scale, tw * 0.12, 10 * scale, ramp("#2A2430", 3)[1])
            c.rect(tower_x + tw * 0.4, top + 120 * scale, tower_x + tw * 0.6, top + 170 * scale, ramp("#3A4A66", 3)[1])
            c.poly([(tower_x - 8, top + 6), (tower_x + tw / 2.0, top - 150 * scale), (tower_x + tw + 8, top + 6)],
                   ramp("#5E6C86", 5)[2])
            c.poly([(tower_x + tw / 2.0, top - 150 * scale), (tower_x + tw + 8, top + 6), (tower_x + tw * 0.6, top + 6)],
                   ramp("#5E6C86", 5)[1])
    # Le pied de l'image : un mur de jardin et ses haies, qui touche le bas (les lointains se posent au sol).
    c.rect(0, h - 34, w, h, ramp("#8A8070", 5)[2])
    c.rect(0, h - 34, w, h - 30, ramp("#B0A58E", 5)[3])
    for gx in range(0, w, 48):
        c.blob(gx + 24, h - 36, rnd.randint(22, 30), rnd.randint(12, 18),
               ramp(rnd.choice(["#6E8A4E", "#A8883A", "#8A5A3A"]), 4))
    # Des arbres dorés entre les toits : un tronc court, une couronne.
    for k in range(spread):
        gx = rnd.randint(0, w)
        gy = h - 50 - rnd.randint(0, (rows - 1) * step)
        r = rnd.randint(14, 24)
        c.rect(gx - 3, gy, gx + 3, gy + 26, ramp("#6A4A32", 4)[1])
        c.blob(gx, gy - r * 0.2, r, r * 0.9, ramp(rnd.choice(["#CC9446", "#D2B45C", "#A95A3A"]), 4))
    return c.finish(darker("#3A3448", 0.5))


def town_roofs_a(size, rnd):
    return _roofs(size, rnd, 6, 9)


def town_roofs_b(size, rnd):
    return _roofs(size, rnd, 5, 14)


# --- Le snack-bar (intérieur) --------------------------------------------------------------------------------------


def floor_stone_town(size, rnd):
    """Dalles de pierre claire polies par les pas, joints fins, une dalle fendue."""
    img = hd2d_ground._stones_rows(size, rnd, [96, 96, 96, 96], (84, 132), "#8F8574", mix("stone", "#E4DAC6", 0.3),
                                   bevel=1, radius=2, grass_in_joints=False)
    worn = threshold(fractal(size, (4, 4), rnd, 3), 205)
    img.paste(Image.new("RGBA", size, rgba("#F2E8D4")), (0, 0), worn.point(lambda v: int(v * 0.16)))
    d = ImageDraw.Draw(img)
    x, y = rnd.randint(60, 300), rnd.randint(60, 300)
    pts = [(x, y)]
    for _ in range(5):
        x += rnd.randint(-10, 10)
        y += rnd.randint(6, 16)
        pts.append((x, y))
    d.line(pts, fill=rgba("#6A6050"), width=1)
    return img


def wall_stone_inside(size, rnd):
    """Pierre apparente jointoyée, moellons beiges de tailles inégales, une poutre en haut, plinthe de pierre en bas ;
    se raccorde à gauche et à droite."""
    w, h = size
    img = posterize(noise((w, h), (8, 6), rnd), ramp("#8A7E6C", 4)[0:3], dither=50)
    d = ImageDraw.Draw(img)
    y = 30
    row = 0
    while y < h - 18:
        row_h = rnd.choice([26, 30, 34, 28])
        x = rnd.randint(0, 40) - 40
        while x < w + 40:
            sw = rnd.randint(34, 78)
            tones = ramp(rnd.choice(["#C8B898", "#BCAE90", "#D0C2A2", "#B8A888"]), 5, spread=0.35)
            stone = Image.new("RGBA", (sw - 3, row_h - 3), (0, 0, 0, 0))
            sd = ImageDraw.Draw(stone)
            sd.rounded_rectangle((0, 0, sw - 4, row_h - 4), 4, fill=rgba(tones[2]))
            sd.line((3, 1, sw - 6, 1), fill=rgba(tones[4]))
            sd.line((3, row_h - 4, sw - 6, row_h - 4), fill=rgba(tones[0]))
            for dx in (-w, 0, w):
                img.paste(stone, (x + 1 + dx, y + 1), stone)
            x += sw
        y += row_h
        row += 1
    beam = ramp("#5A3E2C", 6, spread=0.45)
    d.rectangle((0, 0, w, 26), fill=rgba(beam[2]))
    d.rectangle((0, 0, w, 3), fill=rgba(beam[4]))
    d.rectangle((0, 24, w, 28), fill=rgba(beam[0]))
    for gx in range(0, w, 11):
        d.line((gx, 4, gx + rnd.randint(-1, 1), 22), fill=rgba(beam[1]))
    plinth = ramp("#B0A48C", 5)
    d.rectangle((0, h - 20, w, h), fill=rgba(plinth[2]))
    d.rectangle((0, h - 20, w, h - 18), fill=rgba(plinth[4]))
    d.rectangle((0, h - 3, w, h), fill=rgba(plinth[0]))
    return img


def wall_plaster_ochre(size, rnd):
    """Enduit ocre clair, propre mais vieilli, corniche en haut, plinthe de bois peint ; se raccorde à gauche et à
    droite."""
    w, h = size
    tones = ramp("#D9B56E", 6, spread=0.14)
    img = Image.new("RGBA", (w, h), rgba(tones[3]))
    d = ImageDraw.Draw(img)
    for _ in range(900):
        x, y = rnd.randrange(w), rnd.randrange(h)
        d.point((x, y), fill=rgba(tones[rnd.choice([2, 2, 4])]))
    for _ in range(40):
        x, y = rnd.randrange(w), rnd.randrange(10, h - 46)
        d.line((x, y, x + rnd.randint(-2, 2), y + rnd.randint(6, 22)), fill=rgba(tones[2]))
    stain = threshold(fractal((w, h), (3, 2), rnd, 3), 200)
    img.paste(Image.new("RGBA", (w, h), rgba("#8A6A40")), (0, 0), stain.point(lambda v: int(v * 0.09)))
    cor = ramp("#E8DCC0", 5)
    d.rectangle((0, 0, w, 8), fill=rgba(cor[3]))
    d.rectangle((0, 8, w, 10), fill=rgba(cor[0]))
    wd = ramp("#6F4A34", 6, spread=0.45)
    d.rectangle((0, h - 46, w, h), fill=rgba(wd[2]))
    d.rectangle((0, h - 46, w, h - 43), fill=rgba(wd[4]))
    d.rectangle((0, h - 43, w, h - 41), fill=rgba(wd[0]))
    for k in range(6):
        x0 = k * 64
        d.rectangle((x0 + 6, h - 36, x0 + 58, h - 10), fill=rgba(wd[1]))
        d.rectangle((x0 + 7, h - 35, x0 + 57, h - 34), fill=rgba(wd[0]))
    d.rectangle((0, h - 6, w, h), fill=rgba(wd[0]))
    return img


def _counter_top(c, x0, x1, y0, y1):
    top = ramp("#C8A878", 5)
    c.rect(x0, y0, x1, y1, top[3])
    c.rect(x0, y0, x1, y0 + 2, top[4])
    c.rect(x0, y1 - 2, x1, y1, top[1])


def snack_counter(size, rnd):
    """Comptoir du snack-bar : plaque de cuisson de fonte sur un réchaud de cristal, une poêle où grésille du lard,
    une bassine de friture, des pommes de terre, un pot de soupe."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 5)
    # Le corps : planches verticales, plinthe sombre, dessus.
    boards(c, 4, 54, w - 4, h - 6, "wood", vertical=True, width=16)
    c.rect(2, h - 8, w - 2, h, ramp("#4A3A2E", 4)[1])
    _counter_top(c, 0, w, 44, 56)
    c.rect(0, 56, w, 60, ramp("#654D3C", 4)[0])
    # La plaque et son réchaud de cristal, à gauche.
    c.rect(18, 28, 120, 44, iron[1])
    c.rect(18, 28, 120, 31, iron[3])
    c.blob(70, 38, 40, 6, ramp("#FFB062", 4))
    # La poêle, son manche, trois tranches de lard.
    c.ellipse(60, 26, 28, 9, iron[0])
    c.ellipse(60, 25, 24, 7, iron[2])
    for k, dx in enumerate((-12, 0, 12)):
        c.rect(52 + dx, 22 + k % 2, 66 + dx, 26 + k % 2, ramp("#C0605A", 4)[2])
        c.rect(52 + dx, 22 + k % 2, 66 + dx, 23 + k % 2, ramp("#F2D0C0", 3)[2])
    c.rect(86, 24, 130, 28, iron[1])
    c.ellipse(130, 26, 3, 3, iron[0])
    # Un filet de fumée.
    c.line([(60, 16), (63, 8), (60, 2)], ramp("#F2EEE0", 4)[2], 2)
    # La bassine de friture, au milieu.
    c.cylinder(140, 24, 174, 46, ramp("#8A8A8A", 5))
    c.ellipse(157, 24, 17, 4, ramp("#C8A040", 4)[2])
    # Les pommes de terre dans un panier, le pot de soupe.
    c.poly([(188, 46), (232, 46), (228, 28), (192, 28)], ramp("#A57C58", 5)[2])
    for dx in (0, 10, 20, 30):
        c.ellipse(196 + dx, 28, 7, 5, ramp("#C8A060", 4)[2 + (dx // 10) % 2])
    c.cylinder(244, 14, 274, 46, ramp("#6A5A50", 5))
    c.ellipse(259, 14, 15, 4, ramp("#7A6A60", 4)[3])
    c.rect(238, 24, 244, 28, iron[1])
    c.rect(274, 24, 280, 28, iron[1])
    return c.finish(darker("#4A3A2E", 0.5))


def snack_shelf(size, rnd):
    """Étagère de pots, de sacs de pommes de terre et de bouteilles d'huile."""
    w, h = size
    c = Canvas(w, h, rnd)
    wd = ramp("#7A5A40", 5)
    c.rect(4, 0, 10, h, wd[1])
    c.rect(w - 10, 0, w - 4, h, wd[1])
    for y in (0, h * 0.34, h * 0.66, h - 8):
        c.rect(4, y, w - 4, y + 8, wd[3])
        c.rect(4, y, w - 4, y + 2, wd[4])
    c.rect(10, 8, w - 10, h * 0.34, ramp("#4A3A2E", 3)[0])
    c.rect(10, h * 0.34 + 8, w - 10, h * 0.66, ramp("#4A3A2E", 3)[0])
    c.rect(10, h * 0.66 + 8, w - 10, h - 8, ramp("#4A3A2E", 3)[0])
    # En haut : des pots de grès et des bouteilles d'huile.
    for k, x in enumerate((18, 40, 62)):
        c.cylinder(x, 26, x + 18, h * 0.34, ramp(rnd.choice(["#A8785A", "#8A6A52", "#B8906A"]), 5))
        c.rect(x + 3, 20, x + 15, 26, ramp("#E8D8A8", 4)[2])
    for x, col in ((90, "#C8A040"), (106, "#8AA050"), (122, "#C8A040")):
        c.rect(x, 22, x + 12, h * 0.34, ramp(col, 4)[2])
        c.rect(x + 3, 10, x + 9, 22, ramp(col, 4)[1])
        c.rect(x + 2, 8, x + 10, 11, ramp("#A57C58", 4)[2])
    # Au milieu : des sacs de pommes de terre.
    for x in (20, 66, 108):
        c.blob(x + 14, h * 0.34 + 36, 17, 18, ramp("#B8A47A", 5)[0:4])
        c.rect(x + 8, h * 0.34 + 14, x + 20, h * 0.34 + 22, ramp("#B8A47A", 4)[2])
    # En bas : des caisses et une jarre.
    c.rect(14, h * 0.66 + 16, 70, h - 8, ramp("#A57C58", 5)[2])
    c.rect(14, h * 0.66 + 16, 70, h * 0.66 + 20, ramp("#A57C58", 5)[4])
    boards(c, 14, h * 0.66 + 20, 70, h - 8, "wood", vertical=True, width=14)
    c.cylinder(88, h * 0.66 + 14, 126, h - 8, ramp("#8A6A52", 5))
    c.ellipse(107, h * 0.66 + 14, 19, 4, ramp("#A8785A", 4)[3])
    return c.finish(darker("#3A2A20", 0.5))


def snack_stools(size, rnd):
    """Rangée de trois tabourets hauts de bois devant le comptoir."""
    w, h = size
    c = Canvas(w, h, rnd)
    for k in range(3):
        cx = w * (0.18 + 0.32 * k)
        wd = ramp("#8A6A48", 5)
        dark = ramp("#5A3E2C", 4)
        for dx in (-13, 13):
            c.line([(cx + dx * 0.7, h * 0.34), (cx + dx, h - 2)], dark[1], 4)
            c.rect(cx + dx - 3, h - 4, cx + dx + 3, h, dark[0])
        c.line([(cx - 11, h * 0.74), (cx + 11, h * 0.74)], dark[2], 3)
        c.ellipse(cx, h * 0.28, 19, 8, wd[1])
        c.ellipse(cx, h * 0.22, 19, 8, wd[3])
        c.ellipse(cx - 3, h * 0.2, 11, 4, wd[4])
    return c.finish(darker("#4A3A2E", 0.5))


def snack_meal_tray(size, rnd):
    """Plateau : pommes de terre frites, légumes, lard frit épais, petit pain, soupe dans une tasse."""
    w, h = size
    c = Canvas(w, h, rnd)
    c.rect(1, h * 0.55, w - 1, h - 1, ramp("#8A6A48", 4)[1])
    c.rect(1, h * 0.45, w - 1, h * 0.6, ramp("#A57C58", 4)[3])
    for k in range(4):
        c.rect(6 + k * 4, h * 0.2, 9 + k * 4, h * 0.5, ramp("#E0B450", 4)[2])
    c.rect(22, h * 0.25, 32, h * 0.5, ramp("#C0605A", 4)[2])
    c.ellipse(36, h * 0.35, 6, 5, ramp("#6E9A4E", 4)[2])
    c.ellipse(42, h * 0.3, 5, 6, ramp("#C8A060", 4)[2])
    c.rect(w - 14, h * 0.2, w - 6, h * 0.5, ramp("#F2EEE0", 4)[2])
    return c.finish(darker("#4A3A2E", 0.5))


# --- Table des recettes et manifeste -----------------------------------------------------------------------------------

RECIPES = {
    "buildings/town_house_a": town_house_a, "buildings/town_house_a_side": town_house_a_side,
    "buildings/town_house_b": town_house_b, "buildings/town_house_b_side": town_house_b_side,
    "buildings/town_house_c": town_house_c, "buildings/town_house_c_side": town_house_c_side,
    "buildings/town_house_d": town_house_d, "buildings/town_house_d_side": town_house_d_side,
    "buildings/town_house_e": town_house_e, "buildings/town_house_e_side": town_house_e_side,
    "buildings/town_house_f": town_house_f, "buildings/town_house_f_side": town_house_f_side,
    "buildings/cafe_town": cafe_town, "buildings/cafe_town_side": cafe_town_side,
    "buildings/shop_snack": shop_snack, "buildings/shop_snack_side": shop_snack_side,
    "buildings/shop_accessories": shop_accessories, "buildings/shop_accessories_side": shop_accessories_side,
    "buildings/shop_apothecary": shop_apothecary, "buildings/shop_apothecary_side": shop_apothecary_side,
    "props/hanging_sign_pan": lambda s, r: hanging_sign_shape(s, r, "pan"),
    "props/hanging_sign_cup": lambda s, r: hanging_sign_shape(s, r, "cup"),
    "props/town_planter_stone": town_planter_stone, "props/town_wall_fountain": town_wall_fountain,
    "props/town_doorsteps": town_doorsteps, "props/town_cellar_hatch": town_cellar_hatch,
    "props/town_wall_low": town_wall_low, "props/town_railing": town_railing,
    "props/town_roofs_a": town_roofs_a, "props/town_roofs_b": town_roofs_b,
    "interior/floor_stone_town": floor_stone_town, "interior/wall_stone_inside": wall_stone_inside,
    "interior/wall_plaster_ochre": wall_plaster_ochre,
    "interior/props/snack_counter": snack_counter, "interior/props/snack_shelf": snack_shelf,
    "interior/props/snack_stools": snack_stools, "interior/props/snack_meal_tray": snack_meal_tray,
}
RECIPES.update({"buildings/materials/wall_stone_town": wall_stone_town})


def _facade(name, size, prio=2):
    return {"path": "assets/hd2d/buildings/%s.png" % name, "size": list(size), "kind": "facade", "prio": prio, "lot": "R4"}


def _side(name, size, roof, wall_m=None, prio=2):
    entry = {"path": "assets/hd2d/buildings/%s_side.png" % name, "size": list(size), "kind": "side", "prio": prio,
             "lot": "R4", "roof": roof}
    if wall_m:
        entry["wall_m"] = wall_m
    return entry


def _panel(name, size, prio=3, kind="panel"):
    return {"path": "assets/hd2d/props/%s.png" % name, "size": list(size), "kind": kind, "prio": prio, "lot": "R4"}


# Entrées du manifeste hors intérieurs (tools/hd2d_interior.py écrit celles des images d'intérieur) : chemin, taille,
# genre, priorité, lot R4, drapeaux (roof, wall_m : flancs).
MANIFEST = [
    {"path": "assets/hd2d/buildings/materials/wall_stone_town.png", "size": [192, 192], "kind": "tile", "prio": 3,
     "lot": "R4"},
    _facade("cafe_town", (672, 384)), _side("cafe_town", (576, 576), "gable", 4.0),
    _facade("shop_snack", (480, 336)), _side("shop_snack", (480, 576), "gable", 3.5),
    _facade("shop_accessories", (384, 624), 3), _side("shop_accessories", (480, 384), "eaves", None, 3),
    _facade("shop_apothecary", (384, 624), 3), _side("shop_apothecary", (480, 384), "eaves", None, 3),
    _facade("town_house_a", (480, 864), 3), _side("town_house_a", (576, 576), "eaves", None, 3),
    _facade("town_house_b", (768, 576), 3), _side("town_house_b", (576, 816), "gable", 6.0, 3),
    _facade("town_house_c", (384, 720), 3), _side("town_house_c", (480, 432), "eaves", None, 3),
    _facade("town_house_d", (576, 432), 3), _side("town_house_d", (480, 672), "gable", 4.5, 3),
    _facade("town_house_e", (576, 960), 3), _side("town_house_e", (576, 720), "eaves", None, 3),
    _facade("town_house_f", (576, 336), 3), _side("town_house_f", (480, 576), "gable", 3.5, 3),
    _panel("hanging_sign_pan", (96, 115), 2), _panel("hanging_sign_cup", (96, 115)),
    _panel("town_planter_stone", (154, 77)), _panel("town_wall_fountain", (115, 154)),
    _panel("town_doorsteps", (115, 48)), _panel("town_cellar_hatch", (115, 58)),
    _panel("town_wall_low", (192, 77)), _panel("town_railing", (192, 96)),
    _panel("town_roofs_a", (1536, 768)), _panel("town_roofs_b", (1536, 768)),
]


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
        print("manifeste à jour (%d images de la ville)" % len(MANIFEST))
        return 0
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(new)
    print("manifeste : %d images de la ville" % len(MANIFEST))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(cmd_manifest() if sys.argv[1:] == ["manifest"] else print(__doc__) or 2)
