"""Remplaçants HD-2D du port de l'île n° 68 (lot CP ; cahier n° 5, docs/ASSETS_HD2D_ILE68.md, lot R3, section 5.6, et
lot R7, section 9.1), pour les noms que le plan de la carte `port` (docs/lore/CARTE.md, section 6.2) cite et que le
cahier n'a pas encore livrés :

- le quai : le bras d'ancrage déployé (`mooring_arm_open`), le sifflet à vapeur, le cabestan ;
- la rue du port : le panneau aux flèches rouges (`signpost_port`, dérivé du panneau livré `signpost` : les flèches
  portent une ville de pierre à droite, un bâtiment de bois dans les arbres à gauche), la palissade brise-vent, les
  deux charrettes de l'aire-port ;
- la cabane du gardien (`port_house_b`, façade et flanc) ;
- le transport de la Garde (`ships/garde_transport_side`, lot R7), vu du quai : un remplaçant dérivé du flanc livré
  du Barocupot (`props/airship_barocupot`), ramené à 16 × 7 m et un peu bleui. Le lot E7 (navires en volume) le
  remplace par la coque, le pont, les rotors et la trappe animés du cahier.

Une image livrée (ChatGPT) remplace le remplaçant du même nom, sans toucher au code, et sa recette s'en va avec lui.
Ces recettes sont lues par tools/hd2d_assets.py (recipes) ; leurs entrées du manifeste (lots R3 et R7) sont MANIFEST
ci-dessous (`python3 tools/hd2d_port.py manifest` les inscrit). Le résultat est déterministe (graine tirée du nom de
chaque image)."""

import math

from PIL import Image, ImageChops, ImageDraw

from hd2d_art import Canvas, asset, darker, mix, ramp, rgba
from hd2d_props import boards
from hd2d_village import cottage, cottage_side, dark_window, plank_door

PPM = 96
IRON = "#5A626C"
IRON_DARK = "#3C424C"
COPPER = "#B0703A"
BRASS = "#B4955E"
WOOD = "#A57C58"
GREY_WOOD = "#8C8A86"
SACK = "#C8B084"
STONE = "#B8AE9C"


def _outline(c, color="#2A2630"):
    return c.finish(color)


# --- Le quai -----------------------------------------------------------------------------------------------


def mooring_arm_open(size, rnd):
    """Bras d'ancrage déployé : un socle de pierre cerclé de fer, un fût de fer rivé, un vérin de cuivre, une flèche
    horizontale qui porte, à son bout, une pince ouverte (deux mâchoires) prête à saisir une coque ; câbles."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 6, spread=0.55)
    dark = ramp(IRON_DARK, 5)
    copper = ramp(COPPER, 6)
    stone = ramp(STONE, 5)
    # Socle de pierre : trois assises, joints, deux cerclages de fer.
    base_top = h - 112
    c.rect(24, base_top, 150, h, stone[2])
    for row, y in enumerate((base_top, base_top + 38, base_top + 76)):
        c.rect(24, y, 150, y + 3, stone[4])
        c.rect(24, y + 35 - 3, 150, y + 35, stone[0]) if row < 2 else None
        shift = 22 if row % 2 else 0
        for x in range(24 + shift, 150, 44):
            c.rect(x, y, x + 3, min(y + 38, h), stone[1])
    c.rect(24, base_top, 28, h, stone[4])
    c.rect(146, base_top, 150, h, stone[0])
    for y in (base_top + 6, h - 14):
        c.rect(20, y, 154, y + 10, iron[2])
        c.rect(20, y, 154, y + 3, iron[4])
        c.rect(20, y + 8, 154, y + 10, dark[0])
        for x in (30, 87, 138):
            c.rect(x, y + 3, x + 4, y + 7, copper[4])
    # Fût de fer : cylindre rivé, deux colliers.
    col_x0, col_x1 = 66, 108
    c.cylinder(col_x0, 120, col_x1, base_top + 6, iron)
    for y in (150, 205, 262):
        c.rect(col_x0 - 4, y, col_x1 + 4, y + 9, iron[1])
        c.rect(col_x0 - 4, y, col_x1 + 4, y + 2, iron[4])
        for x in (col_x0 + 4, (col_x0 + col_x1) // 2 - 1, col_x1 - 8):
            c.rect(x, y + 3, x + 3, y + 6, copper[4])
    # Moyeu de la flèche (cuivre) en haut du fût.
    c.blob(87, 112, 30, 26, copper[1:])
    c.ellipse(87, 112, 9, 9, dark[1])
    c.ellipse(87, 112, 4, 4, iron[4])
    # La flèche : un caisson de fer horizontal vers la droite, plus étroit au bout.
    c.poly([(80, 92), (258, 76), (262, 100), (84, 134)], iron[2])
    c.poly([(80, 92), (258, 76), (259, 82), (82, 100)], iron[4])
    c.poly([(84, 126), (262, 94), (262, 100), (84, 134)], dark[1])
    for k in range(1, 7):
        x = 80 + k * 28
        c.line([(x, 92 - k * 2.2), (x + 2, 128 - k * 5.0)], iron[1], 2)
    for k in range(8):
        x = 96 + k * 22
        c.rect(x, 90 - k * 2.0, x + 3, 93 - k * 2.0, copper[4])
    # Le vérin : cylindre de cuivre du fût au dessous de la flèche, tige chromée.
    c.poly([(92, 230), (150, 150), (166, 160), (108, 244)], copper[2])
    c.poly([(92, 230), (150, 150), (156, 154), (100, 236)], copper[4])
    c.poly([(150, 150), (200, 112), (206, 120), (160, 160)], iron[4])
    c.ellipse(96, 236, 9, 9, dark[0])
    c.ellipse(96, 236, 4, 4, iron[3])
    # La pince : deux mâchoires ouvertes au bout de la flèche, un anneau de fer au bout d'un câble.
    c.poly([(246, 84), (278, 94), (280, 120), (262, 124), (252, 108)], iron[1])
    c.poly([(262, 124), (280, 120), (276, 168), (258, 150)], iron[2])
    c.poly([(246, 98), (226, 120), (232, 170), (250, 154), (246, 126)], iron[2])
    c.poly([(262, 124), (276, 168), (268, 172), (252, 134)], dark[1])
    c.poly([(226, 120), (232, 170), (238, 166), (234, 124)], iron[4])
    c.ellipse(262, 100, 10, 10, copper[3])
    c.ellipse(262, 100, 4, 4, dark[0])
    # Câbles : de la flèche au fût, un mou de chaîne, et la poulie.
    pts = [(190 + 56 * t / 12.0, 84 + t * 1.2 + 10 * math.sin(math.pi * t / 12.0)) for t in range(13)]
    c.line(pts, dark[0], 2)
    c.line([(150, 150), (190, 94)], dark[1], 2)
    return _outline(c)


def steam_whistle(size, rnd):
    """Sifflet à vapeur de laiton terni au bout d'un tuyau de cuivre qui sort du quai, petite chaîne de manœuvre."""
    w, h = size
    c = Canvas(w, h, rnd)
    copper = ramp(COPPER, 6)
    brass = ramp(BRASS, 6)
    iron = ramp(IRON, 5)
    # Bride de fonte au pied.
    c.rect(14, h - 22, 54, h, iron[2])
    c.rect(14, h - 22, 54, h - 19, iron[4])
    c.rect(14, h - 4, 54, h, iron[0])
    for x in (18, 28, 38, 48):
        c.rect(x, h - 17, x + 3, h - 13, copper[4])
    # Tuyau de cuivre : montant, coude à droite, deuxième montant.
    c.cylinder(26, 76, 42, h - 22, copper)
    for y in (h - 60, h - 108):
        c.rect(22, y, 46, y + 7, copper[1])
        c.rect(22, y, 46, y + 2, copper[4])
    c.blob(40, 76, 17, 13, copper[1:])
    c.rect(24, 70, 40, 82, copper[2])
    # La volute et le vase du sifflet : un pavillon de laiton évasé, la bouche vers le haut.
    c.cylinder(34, 40, 50, 76, brass)
    c.poly([(30, 44), (56, 44), (64, 22), (22, 22)], brass[2])
    c.poly([(30, 44), (38, 44), (30, 22), (22, 22)], brass[4])
    c.poly([(48, 44), (56, 44), (64, 22), (56, 22)], brass[0])
    c.ellipse(43, 22, 21, 6, brass[3])
    c.ellipse(43, 22, 15, 4, darker(BRASS, 0.4))
    c.rect(40, 12, 46, 22, brass[1])
    c.ellipse(43, 10, 5, 4, brass[3])
    # Le levier et la chaîne de manœuvre : une manette, une chaîne qui pend et se balance un peu.
    c.line([(44, 62), (62, 54)], iron[3], 3)
    c.ellipse(63, 54, 4, 4, copper[3])
    links = [(63 + 1.5 * math.sin(k * 0.5), 58 + k * 4) for k in range(12)]
    for k, (x, y) in enumerate(links):
        c.rect(x - 2, y, x + 2, y + 3, iron[2] if k % 2 == 0 else iron[4])
    c.ellipse(links[-1][0], links[-1][1] + 6, 4, 4, brass[3])
    c.ellipse(links[-1][0], links[-1][1] + 6, 2, 2, iron[0])
    return _outline(c)


def capstan(size, rnd):
    """Cabestan de fer à barres de bois, un cordage enroulé : un tambour évasé, une tête à quatre mortaises, deux
    barres, un bout de corde qui retombe sur la dalle."""
    w, h = size
    c = Canvas(w, h, rnd)
    iron = ramp(IRON, 6, spread=0.55)
    wood = ramp(WOOD, 5)
    rope = ramp("#BFA676", 5)
    # Socle de fonte : un disque aplati.
    c.ellipse(48, h - 8, 36, 8, iron[1])
    c.ellipse(48, h - 11, 32, 7, iron[3])
    c.ellipse(48, h - 12, 22, 4, iron[2])
    # Tambour : cône tronqué de fer, évasé en bas, bandé de corde.
    c.poly([(30, h - 14), (66, h - 14), (62, 34), (34, 34)], iron[2])
    c.poly([(30, h - 14), (40, h - 14), (38, 34), (34, 34)], iron[4])
    c.poly([(58, h - 14), (66, h - 14), (62, 34), (57, 34)], iron[0])
    for k, y in enumerate(range(40, h - 22, 6)):
        c.rect(33 - (k < 1) + (k > 4), y, 63 - (k > 4) * 2, y + 4, rope[2])
        c.rect(33, y, 63, y + 1, rope[4])
        c.rect(33, y + 3, 63, y + 4, rope[0])
    # Tête : un plateau avec ses mortaises.
    c.ellipse(48, 32, 24, 7, iron[1])
    c.ellipse(48, 30, 22, 6, iron[3])
    for x in (34, 44, 54, 62):
        c.rect(x, 28, x + 4, 31, iron[0])
    # Deux barres de bois : une plantée à gauche, une à droite, bout ferré.
    c.poly([(30, 32), (6, 18), (8, 12), (34, 26)], wood[2])
    c.poly([(30, 32), (6, 18), (7, 15), (31, 28)], wood[4])
    c.rect(4, 12, 10, 20, iron[2])
    c.poly([(66, 32), (90, 18), (88, 12), (62, 26)], wood[1])
    c.rect(86, 12, 92, 20, iron[2])
    # Le bout de corde qui retombe.
    c.line([(60, h - 20), (74, h - 14), (80, h - 8), (70, h - 4)], rope[2], 3)
    return _outline(c)


# --- La rue du port ------------------------------------------------------------------------------------------


def signpost_port(size, rnd):
    """Le panneau aux flèches rouges de l'œuvre : le poteau fendu du panneau livré (`props/signpost`), flèches rouges
    écaillées vers la droite et vers la gauche ; sur celle de droite, de petites maisons de pierre peintes (la ville),
    sur celle de gauche un bâtiment de bois dans des arbres (l'entrepôt) ; aucun texte, aucun chiffre."""
    w, h = size
    src = asset("props/signpost")
    c = Canvas(w, h, rnd)
    scale = h / float(src.height)
    big = src.resize((round(src.width * scale), h), Image.NEAREST)
    c.img.alpha_composite(big, ((w - big.width) // 2, 0))
    ox = (w - big.width) // 2

    def sx(x):
        return ox + x * scale

    def sy(y):
        return y * scale

    cream = "#EAD9B2"
    shade = "#8A7458"
    # À droite (planche du haut, la pointe vers la droite ; en pixels du panneau livré : x 24 → 100, y 32 → 62) : une
    # ville de petites maisons de pierre, toits pentus, peintes de la couleur du bois nu sur le rouge.
    for x0, wd, ht in ((38, 12, 11), (52, 15, 15), (69, 12, 10), (83, 11, 8)):
        left, right = sx(x0), sx(x0 + wd)
        base = sy(60)
        top = base - ht * scale
        c.rect(left, top, right, base, cream)
        c.rect(left, base - 2, right, base, shade)
        c.poly([(left - 2, top), ((left + right) / 2.0, top - 6 * scale), (right + 2, top)], shade)
        c.rect((left + right) / 2.0 - 1, top + 3 * scale, (left + right) / 2.0 + 2, top + 7 * scale, shade)
        c.rect((left + right) / 2.0 - 2, base - 6 * scale, (left + right) / 2.0 + 2, base - 1, shade)
    # À gauche (planche du bas, la pointe vers la gauche ; x 14 → 86, y 78 → 108) : un bâtiment de bois à deux pans
    # entre deux sapins.
    cx = sx(50)
    base = sy(106)
    c.rect(cx - 10 * scale, base - 15 * scale, cx + 10 * scale, base, cream)
    for k in range(1, 4):
        c.rect(cx - 10 * scale, base - k * 4 * scale, cx + 10 * scale, base - k * 4 * scale + 1, shade)
    c.poly([(cx - 13 * scale, base - 15 * scale), (cx, base - 24 * scale), (cx + 13 * scale, base - 15 * scale)], shade)
    c.rect(cx - 2 * scale, base - 11 * scale, cx + 2 * scale, base, shade)
    for tx, ht in ((cx - 24 * scale, 20), (cx + 24 * scale, 22), (cx + 34 * scale, 14)):
        c.poly([(tx - 6 * scale, base), (tx, base - ht * scale), (tx + 6 * scale, base)], "#5E7A48")
        c.poly([(tx - 4 * scale, base - ht * scale * 0.5), (tx, base - ht * scale), (tx + 4 * scale, base - ht * scale * 0.5)],
               "#86A468")
    return c.img


def wind_fence(size, rnd):
    """Palissade brise-vent de planches grises le long de la rue du port, deux planches cassées, un poteau penché."""
    w, h = size
    c = Canvas(w, h, rnd)
    grey = ramp(GREY_WOOD, 6, spread=0.5)
    dark = ramp("#4A4642", 4)
    # Traverses derrière les planches (deux), poteaux : un droit à gauche, un penché à droite.
    top = 18
    planks = [(x, x + 17) for x in range(6, 178, 17)]
    broken = {3: 46, 7: 70}
    for k, (x0, x1) in enumerate(planks):
        y0 = top + rnd.randint(-4, 6)
        if k in broken:
            y0 = h - 92 + broken[k] // 2
        tone = grey[rnd.choice([1, 2, 2, 3])]
        c.rect(x0, y0, x1 - 1, h, tone)
        c.rect(x0, y0, x0 + 1, h, grey[5])
        c.rect(x1 - 2, y0, x1 - 1, h, grey[0])
        if k in broken:
            # Une cassure irrégulière en haut, une écharde.
            c.poly([(x0, y0), (x0 + 5, y0 - 8), (x0 + 9, y0 - 3), (x0 + 13, y0 - 12), (x1 - 1, y0)], tone)
        for nail in (top + 30, h - 30):
            if nail > y0 + 6:
                c.rect(x0 + 6, nail, x0 + 8, nail + 2, dark[0])
        for _ in range(3):
            gx = rnd.randint(x0 + 3, x1 - 5)
            gy = rnd.randint(max(y0 + 4, top), h - 6)
            c.rect(gx, gy, gx + 1, gy + rnd.randint(6, 14), grey[0])
    for y in (top + 22, h - 38):
        c.rect(0, y, w, y + 8, grey[2])
        c.rect(0, y, w, y + 2, grey[4])
        c.rect(0, y + 6, w, y + 8, dark[0])
    # Poteau droit à gauche, poteau penché à droite.
    c.cylinder(0, 8, 10, h, grey)
    c.poly([(w - 22, h), (w - 8, h), (w + 0, 4), (w - 12, 0)], grey[1])
    c.poly([(w - 22, h), (w - 18, h), (w - 8, 0), (w - 12, 0)], grey[4])
    return _outline(c)


def _wheel(c, cx, cy, r, rim, wood, spokes=8):
    c.ellipse(cx, cy, r, r, rim[1])
    c.ellipse(cx, cy, r - 4, r - 4, wood[2])
    c.ellipse(cx, cy, r - 7, r - 7, wood[1])
    for k in range(spokes):
        a = k / float(spokes) * math.pi
        c.line([(cx - math.cos(a) * (r - 5), cy - math.sin(a) * (r - 5)),
                (cx + math.cos(a) * (r - 5), cy + math.sin(a) * (r - 5))], wood[3], 2)
    c.ellipse(cx, cy, 6, 6, rim[3])
    c.ellipse(cx, cy, 2, 2, rim[0])
    c.line([(cx - r * 0.7, cy - r * 0.7), (cx + r * 0.1, cy - r * 0.9)], rim[4], 1)


def cargo_cart_a(size, rnd):
    """Charrette à bras à deux roues cerclées de fer, chargée de sacs de toile ficelés, brancards levés (V2)."""
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 6, spread=0.5)
    iron = ramp(IRON, 6)
    sack = ramp(SACK, 6, spread=0.45)
    rope = ramp("#7A5E3C", 4)
    # Brancards levés à gauche, deux longues perches, entretoise.
    c.poly([(8, 28), (16, 24), (190, 108), (182, 118)], wood[2])
    c.poly([(8, 28), (16, 24), (20, 26), (12, 32)], wood[4])
    c.poly([(34, 18), (42, 14), (206, 98), (198, 108)], wood[1])
    c.line([(24, 22), (36, 34)], wood[0], 3)
    # Caisse : plancher et ridelle visible (de flanc).
    c.poly([(70, 96), (252, 108), (252, 142), (70, 132)], wood[2])
    c.rect(70, 96, 252, 100, wood[4])
    for x in range(78, 250, 22):
        c.rect(x, 100, x + 2, 138, wood[0])
    c.rect(70, 126, 252, 130, wood[1])
    # Sacs : un tas de huit, deux rangs et un sur le dessus, ficelés d'une corde en croix.
    sacks = [(96, 90, 22, 18), (128, 92, 24, 17), (160, 92, 24, 17), (192, 94, 24, 16), (222, 98, 22, 14),
             (112, 70, 24, 19), (146, 68, 24, 20), (180, 72, 24, 18), (132, 48, 24, 20), (166, 46, 22, 20)]
    for k, (x, y, rx, ry) in enumerate(sacks):
        c.blob(x + rx / 2.0, y + ry / 2.0, rx / 2.0 + 4, ry / 2.0 + 4, sack[1:] if k % 2 == 0 else sack[:5], light=(-0.4, -0.7))
        c.line([(x + 4, y + ry / 2.0), (x + rx, y + ry / 2.0 - 2)], sack[0], 1)
        c.rect(x + rx / 2.0 - 5, y - 2, x + rx / 2.0 + 5, y + 2, sack[4])
    c.line([(90, 118), (140, 48), (200, 62), (246, 112)], rope[1], 2)
    c.line([(100, 120), (170, 46), (214, 70)], rope[1], 2)
    # Un essieu et une roue cerclée de fer, plus grande que la caisse.
    c.rect(138, 126, 164, 132, iron[1])
    _wheel(c, 150, 128, 38, iron, wood)
    # Les pieds d'appui en bout de caisse (côté brancards) : un tréteau.
    c.rect(64, 130, 72, 168, wood[1])
    c.rect(60, 164, 76, 172, wood[0])
    return _outline(c)


def cargo_cart_b(size, rnd):
    """Diable de bois et de fer chargé de trois caisses, une sangle."""
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp(WOOD, 6, spread=0.5)
    iron = ramp(IRON, 6)
    dark = ramp("#3C2C20", 4)
    # Plateforme de bois, petite roue de fer cerclée, deux montants de fer qui montent en poignée.
    c.rect(20, h - 24, 214, h - 14, wood[2])
    c.rect(20, h - 24, 214, h - 22, wood[4])
    c.rect(20, h - 16, 214, h - 14, wood[0])
    _wheel(c, 96, h - 24, 24, iron, wood, spokes=6)
    # Caisses : deux en bas, une dessus, planches, bandes de fer, sangle.
    for k, (x, y, cw, ch) in enumerate(((30, h - 70, 74, 46), (108, h - 66, 72, 42), (62, h - 112, 80, 42))):
        c.rect(x, y, x + cw, y + ch, wood[2 if k != 1 else 1])
        c.rect(x, y, x + cw, y + 3, wood[4])
        c.rect(x, y + ch - 3, x + cw, y + ch, wood[0])
        for bx in (x + 8, x + cw - 14):
            c.rect(bx, y, bx + 6, y + ch, iron[2])
            c.rect(bx, y, bx + 1, y + ch, iron[4])
        c.line([(x + 4, y + 12), (x + cw - 4, y + ch - 14)], wood[0], 2)
        c.line([(x + 4, y + ch - 14), (x + cw - 4, y + 12)], wood[0], 2)
        for nx in (x + 3, x + cw - 6):
            c.rect(nx, y + 3, nx + 2, y + 5, dark[0])
    c.rect(184, h - 124, 190, h - 24, iron[2])
    c.rect(184, h - 124, 186, h - 24, iron[4])
    c.rect(210, h - 122, 216, h - 24, iron[1])
    c.rect(184, h - 128, 216, h - 120, iron[3])
    c.rect(184, h - 128, 216, h - 126, iron[4])
    # La sangle : une bande de toile qui ceint les trois caisses jusqu'au montant.
    c.rect(22, h - 80, 190, h - 74, rnd and ramp("#7A4A3A", 4)[2])
    c.rect(22, h - 80, 190, h - 79, ramp("#7A4A3A", 4)[3])
    c.rect(130, h - 78, 134, h - 60, iron[3])
    return _outline(c)


# --- La cabane du gardien ----------------------------------------------------------------------------------------


def port_house_b(size, rnd):
    """La cabane du gardien du port : planches grises, toit de tôle, une girouette sur le pignon, une longue-vue posée
    sur l'appui de la fenêtre, deux câbles d'ancrage scellés au mur (cahier n° 5, 5.6)."""
    def features(c, w, h, top):
        plank_door(c, 70, h - 160, 70, 160, "#5E4A3C")
        dark_window(c, 232, h - 218, 62, 72, "#5A5048")
        # La longue-vue sur l'appui : un tube de laiton sur deux tasseaux.
        brass = ramp(BRASS, 5)
        c.rect(226, h - 140, 300, h - 134, ramp(GREY_WOOD, 4)[1])
        c.poly([(236, h - 148), (292, h - 168), (296, h - 162), (240, h - 142)], brass[2])
        c.poly([(236, h - 148), (292, h - 168), (293, h - 166), (238, h - 147)], brass[4])
        c.rect(288, h - 172, 298, h - 160, brass[1])
        # Girouette : un fer en flèche cloué sur le pignon, sous le faîtage.
        iron = ramp(IRON, 4)
        c.rect(w // 2 - 1, 64, w // 2 + 1, 130, iron[1])
        c.poly([(w // 2 - 22, 82), (w // 2 + 8, 76), (w // 2 + 8, 88)], iron[2])
        c.poly([(w // 2 + 8, 70), (w // 2 + 24, 82), (w // 2 + 8, 94), (w // 2 + 12, 82)], iron[0])
        # Deux câbles d'ancrage : des anneaux scellés dans le mur, un câble qui descend vers le quai.
        for x in (30, 350):
            c.ellipse(x, h - 250, 7, 7, iron[2])
            c.ellipse(x, h - 250, 3, 3, iron[0])
            c.line([(x, h - 244), (x - 4, h - 150), (x + 2, h - 60)], iron[1], 3)
            c.line([(x - 1, h - 244), (x - 5, h - 150), (x + 1, h - 60)], iron[3], 1)
        # Le seuil : une planche et un seau.
        c.rect(60, h - 12, 150, h - 6, ramp(GREY_WOOD, 4)[2])
    return cottage(size, rnd, "wall_planks_b", "roof_tin", "pignon", 4.0, 30, 0, features)


def port_house_b_side(size, rnd):
    def features(c, w, h, top):
        dark_window(c, 108, h - 238, 56, 66, "#5A5048")
        dark_window(c, 300, h - 238, 56, 66, "#5A5048")
    return cottage_side(size, rnd, "wall_planks_b", "roof_tin", None, 28, 0, features)


# --- Le transport de la Garde --------------------------------------------------------------------------------


def garde_transport_side(size, rnd):
    """Le transport de la Garde vu du quai (remplaçant, lot R7 ; E7 le remplace par la coque en volume) : le flanc livré
    du Barocupot (`props/airship_barocupot`, mêmes tôles d'acier gris-vert, bande rouge de la Garde, deux moyeux de
    laiton) ramené à 16 × 7 m, la teinte un peu bleuie (« gris-bleu sombre »), la proue à droite."""
    w, h = size
    src = asset("props/airship_barocupot")
    scale = w / float(src.width)
    big = src.resize((w, round(src.height * scale)), Image.LANCZOS)
    big = big.crop((0, big.height - h, w, big.height))
    r, g, b, a = big.split()
    r = r.point(lambda v: round(v * 0.93))
    g = g.point(lambda v: round(v * 0.98))
    b = b.point(lambda v: min(255, round(v * 1.10 + 4)))
    return Image.merge("RGBA", (r, g, b, a))


RECIPES = {
    "props/mooring_arm_open": mooring_arm_open,
    "props/steam_whistle": steam_whistle,
    "props/capstan": capstan,
    "props/signpost_port": signpost_port,
    "props/wind_fence": wind_fence,
    "props/cargo_cart_a": cargo_cart_a,
    "props/cargo_cart_b": cargo_cart_b,
    "buildings/port_house_b": port_house_b,
    "buildings/port_house_b_side": port_house_b_side,
    "ships/garde_transport_side": garde_transport_side,
}

# Entrées du manifeste (tools/hd2d_manifest.json) : chemin, taille, genre, priorité, lot, drapeaux.
MANIFEST = [
    {"path": "assets/hd2d/props/mooring_arm_open.png", "size": [288, 384], "kind": "panel", "prio": 1, "lot": "R3"},
    {"path": "assets/hd2d/props/steam_whistle.png", "size": [77, 192], "kind": "panel", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/props/capstan.png", "size": [96, 86], "kind": "panel", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/props/signpost_port.png", "size": [154, 288], "kind": "panel", "prio": 1, "lot": "R3"},
    {"path": "assets/hd2d/props/wind_fence.png", "size": [192, 134], "kind": "panel", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/props/cargo_cart_a.png", "size": [288, 173], "kind": "panel", "prio": 2, "lot": "R3"},
    {"path": "assets/hd2d/props/cargo_cart_b.png", "size": [240, 134], "kind": "panel", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/buildings/port_house_b.png", "size": [384, 624], "kind": "facade", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/buildings/port_house_b_side.png", "size": [480, 384], "kind": "side", "prio": 3, "lot": "R3",
     "roof": "eaves"},
    {"path": "assets/hd2d/ships/garde_transport_side.png", "size": [1536, 672], "kind": "panel", "prio": 1,
     "lot": "R7"},
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
        print("manifeste à jour (%d images du port)" % len(MANIFEST))
        return 0
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(new)
    print("manifeste : %d images du port" % len(MANIFEST))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(cmd_manifest() if sys.argv[1:] == ["manifest"] else print(__doc__) or 2)
