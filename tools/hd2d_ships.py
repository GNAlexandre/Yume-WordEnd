"""Recettes HD-2D des navires volants (docs/ASSETS_HD2D_MONDE.md, section 11, lot C).

Les dirigeables de l'univers sont des navires sans ballon, portés par un four enchanté et des
hélices : à quai, de profil, proue à droite, vus très légèrement d'en haut, à 96 px/m, avec le
moyeu des hélices latérales mais sans leurs pales (bandes animées de tools/hd2d_anim.py, posées
par le jeu sur le moyeu) ; en vol (sky/), à 24 px/m, adoucis et violacés par la distance."""

import math

from PIL import Image, ImageDraw

from hd2d_art import Canvas, darker, mix, ramp, rgba, rotate_points

COPPER = "#B0703A"
HULL_WOOD = "#5A3A2A"
STEEL = "#4A5466"
GARDE = "#AE4A3E"


def hull_shape(w, h, x0, x1, deck_y, keel_y, bow_rise=0.12, stern_rise=0.06):
    """Profil de coque, proue à droite : pont, étrave courbe qui plonge vers la quille, quille
    presque droite, poupe qui remonte en voûte."""
    top_bow = deck_y - h * bow_rise
    top_stern = deck_y - h * stern_rise
    pts = [(x0, top_stern), (x1 - (x1 - x0) * 0.06, deck_y - h * bow_rise * 0.4), (x1, top_bow)]
    steps = 24
    for k in range(1, steps + 1):
        t = k / float(steps)
        x = x1 - (x1 - x0) * t
        if t < 0.28:
            u = t / 0.28
            y = top_bow + (keel_y - top_bow) * (1 - (1 - u) ** 2.2)
        elif t < 0.78:
            y = keel_y
        else:
            u = (t - 0.78) / 0.22
            y = keel_y - (keel_y - (deck_y + (keel_y - deck_y) * 0.25)) * u ** 1.8
        pts.append((x, y))
    return pts


def clip_details(c, saved, pts):
    """Remet hors de la coque ce qui y était avant les détails (bordages, bandes, tôles)."""
    from PIL import ImageChops
    mask = Image.new("L", (c.w, c.h), 0)
    ImageDraw.Draw(mask).polygon([(round(x), round(y)) for x, y in pts], fill=255)
    c.img.paste(saved, (0, 0), ImageChops.invert(mask))


def portholes(c, xs, y, r, lit=True):
    brass = ramp("brass", 4)
    glass = ramp("crystal", 5)
    for x in xs:
        c.ellipse(x, y, r + 2, r + 2, brass[1])
        c.ellipse(x, y, r, r, glass[3] if lit else "#2A2E3A")
        c.ellipse(x - r * 0.3, y - r * 0.3, r * 0.35, r * 0.35, glass[4] if lit else "#4A5060")


def hub(c, x, y, r, base=COPPER):
    tones = ramp(base, 5)
    c.ellipse(x, y, r * 1.25, r * 1.25, darker(base, 0.5))
    c.blob(x, y, r, r, tones[1:])
    c.ellipse(x, y, r * 0.35, r * 0.35, tones[0])
    for k in range(6):
        a = k / 6.0 * 2 * math.pi
        c.rect(x + math.cos(a) * r * 0.75 - 1, y + math.sin(a) * r * 0.75 - 1, x + math.cos(a) * r * 0.75 + 2,
               y + math.sin(a) * r * 0.75 + 2, tones[4])


def grille(c, x, y, w, h):
    c.rect(x, y, x + w, y + h, "#3A1E14")
    for k in range(int(w / 6)):
        c.rect(x + 2 + k * 6, y + 2, x + 5 + k * 6, y + h - 2, rnd_glow(k))


def rnd_glow(k):
    return ["#E86A2A", "#F4A040", "#D8502A", "#F4B860"][k % 4]


def railing(c, x0, x1, y, height, base="brass"):
    tones = ramp(base, 4)
    c.rect(x0, y - height, x1, y - height + 3, tones[2])
    x = x0
    while x <= x1:
        c.rect(x, y - height, x + 2, y, tones[1])
        x += 14


def airship_ferry(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    deck = h * 0.52
    keel = h - 8
    x0, x1 = w * 0.06, w * 0.92
    wood = ramp(HULL_WOOD, 6, spread=0.5)
    copper = ramp(COPPER, 5)
    # Ailerons stabilisateurs (poupe), sous la coque et au-dessus.
    c.poly([(x0 + w * 0.02, deck + h * 0.02), (x0 - w * 0.04, deck - h * 0.24), (x0 + w * 0.1, deck - h * 0.04)], copper[1])
    c.poly([(x0 + w * 0.04, deck + h * 0.12), (x0 - w * 0.05, deck + h * 0.02), (x0 + w * 0.08, deck + h * 0.2)], copper[2])
    pts = hull_shape(w, h, x0, x1, deck, keel)
    c.poly(pts, wood[2])
    upper = [(x, min(y, deck + h * 0.12)) for x, y in pts]
    c.poly(upper, wood[3])
    saved = c.img.copy()
    for k in range(6):
        y = deck + h * 0.06 + k * h * 0.06
        c.line([(x0 + w * 0.03 + k * 4, y), (x1 - w * 0.06 - k * 14, y)], wood[1], 2)
    for frac in (0.02, 0.16):
        y = deck + h * frac
        c.line([(x0, y - h * 0.06 if frac < 0.1 else y), (x1 - w * 0.02, y - h * 0.04 if frac < 0.1 else y)], copper[2], 5)
    clip_details(c, saved, pts)
    iron = ramp("iron", 4)
    keel_line = [(x, y) for x, y in pts[3:] if y >= keel - 1]
    c.rect(keel_line[-1][0], keel - 2, keel_line[0][0], h, iron[1])
    c.rect(keel_line[-1][0], h - 3, keel_line[0][0], h, iron[0])
    # Pont vu un peu d'en haut, rambarde.
    c.poly([(x0, deck - h * 0.06), (x1 - w * 0.04, deck - h * 0.04), (x1 - w * 0.06, deck - h * 0.0), (x0 + 6, deck - h * 0.02)],
           ramp("#A08060", 4)[2])
    railing(c, x0 + w * 0.3, x1 - w * 0.08, deck - h * 0.04, h * 0.06)
    # Cabine à hublots (poupe), four enchanté derrière, cheminée.
    cab0, cab1 = x0 + w * 0.06, x0 + w * 0.3
    c.rect(cab0, deck - h * 0.3, cab1, deck - h * 0.04, wood[3])
    c.rect(cab0 - 6, deck - h * 0.34, cab1 + 6, deck - h * 0.3, wood[1])
    portholes(c, [cab0 + (cab1 - cab0) * f for f in (0.2, 0.5, 0.8)], deck - h * 0.18, h * 0.035)
    fx = cab1 + w * 0.08
    c.blob(fx, deck - h * 0.14, w * 0.06, h * 0.12, copper[1:])
    grille(c, fx - w * 0.035, deck - h * 0.16, w * 0.07, h * 0.06)
    c.rect(fx - 10, deck - h * 0.42, fx + 10, deck - h * 0.22, iron[1])
    c.rect(fx - 13, deck - h * 0.44, fx + 13, deck - h * 0.41, iron[2])
    # Rampe d'embarquement relevée (milieu), moyeu de cuivre au milieu de la coque.
    c.line([(w * 0.58, deck - h * 0.04), (w * 0.66, deck - h * 0.26)], ramp("#A08060", 4)[2], 10)
    c.line([(w * 0.6, deck - h * 0.03), (w * 0.68, deck - h * 0.25)], ramp("#A08060", 4)[1], 2)
    hub(c, w * 0.5, deck + h * 0.2, h * 0.07)
    # Étrave : lanterne de proue.
    c.rect(x1 - 8, deck - h * 0.22, x1 - 4, deck - h * 0.1, iron[1])
    c.blob(x1 - 6, deck - h * 0.24, 7, 8, ramp("crystal", 4))
    return c.finish(darker(HULL_WOOD, 0.5))


def rivets(c, x0, y0, x1, y1, step, color):
    y = y0
    while y < y1:
        x = x0
        while x < x1:
            if c.img.getpixel((int(x), int(y)))[3]:
                c.rect(x, y, x + 2, y + 2, color)
            x += step
        y += step * 2.2


def airship_barocupot(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    deck = h * 0.32
    keel = h * 0.74
    x0, x1 = w * 0.04, w * 0.95
    steel = ramp(STEEL, 6, spread=0.5)
    iron = ramp("iron", 5)
    # Ailerons de queue.
    c.poly([(x0 + w * 0.02, deck + h * 0.02), (x0 - w * 0.02, deck - h * 0.24), (x0 + w * 0.1, deck)], steel[1])
    c.poly([(x0 + w * 0.03, keel - h * 0.1), (x0 - w * 0.01, keel + h * 0.08), (x0 + w * 0.1, keel - h * 0.06)], steel[1])
    pts = hull_shape(w, h, x0, x1, deck, keel, bow_rise=0.08, stern_rise=0.04)
    c.poly(pts, steel[2])
    c.poly([(x, min(y, deck + h * 0.18)) for x, y in pts], steel[3])
    saved = c.img.copy()
    # Tôles rivetées.
    for k in range(1, 20):
        x = x0 + (x1 - x0) * k / 20.0
        c.line([(x, deck), (x - 6, keel)], steel[1], 2)
    for y in (deck + h * 0.1, deck + h * 0.24, deck + h * 0.36):
        c.line([(x0 + w * 0.02, y), (x1 - w * 0.04, y)], steel[1], 2)
    rivets(c, x0 + 10, deck + 6, x1 - 20, keel - 10, 14, steel[5])
    # Bande rouge de la Garde, aile peinte à la proue.
    c.line([(x0, deck + h * 0.04), (x1 - w * 0.02, deck - h * 0.0)], GARDE, 12)
    clip_details(c, saved, pts)
    red = ramp(GARDE, 4)
    bx, by = x1 - w * 0.1, deck + h * 0.18
    for k in range(5):
        c.poly([(bx, by), (bx - w * 0.05 + k * 8, by - h * 0.08 + k * 6), (bx - w * 0.035 + k * 8, by - h * 0.04 + k * 6)], red[2 + k % 2])
    # Deux ponts de hublots ronds éclairés.
    for row, y in enumerate((deck + h * 0.12, deck + h * 0.26)):
        xs = [x0 + w * (0.16 + 0.045 * k) for k in range(15 - row * 2)]
        portholes(c, [x for x in xs if x < x1 - w * 0.16], y, h * 0.022)
    # Passerelle de commandement vitrée (avant), trappe de soute (arrière).
    bx0, bx1 = x1 - w * 0.24, x1 - w * 0.08
    c.rect(bx0, deck - h * 0.2, bx1, deck, steel[3])
    c.rect(bx0 + 8, deck - h * 0.17, bx1 - 8, deck - h * 0.06, ramp("crystal", 5)[3])
    for k in range(5):
        x = bx0 + 8 + (bx1 - bx0 - 16) * k / 4.0
        c.rect(x - 2, deck - h * 0.17, x + 2, deck - h * 0.06, steel[1])
    c.rect(bx0 - 8, deck - h * 0.23, bx1 + 8, deck - h * 0.2, steel[1])
    c.rect(x0 + w * 0.1, deck + h * 0.08, x0 + w * 0.22, deck + h * 0.38, steel[1])
    c.rect(x0 + w * 0.1 + 6, deck + h * 0.08 + 6, x0 + w * 0.22 - 6, deck + h * 0.38 - 6, steel[2])
    railing(c, x0 + w * 0.06, bx0 - 10, deck, h * 0.05, "iron")
    # Canon court sous bâche (pont).
    c.blob(x0 + w * 0.5, deck - h * 0.05, w * 0.05, h * 0.05, ramp("#6A6A50", 4))
    c.line([(x0 + w * 0.53, deck - h * 0.05), (x0 + w * 0.58, deck - h * 0.08)], iron[1], 8)
    # Deux fours enchantés en nacelles sous la coque.
    for fx in (w * 0.34, w * 0.66):
        c.rect(fx - 30, keel - h * 0.04, fx - 20, keel + h * 0.1, iron[1])
        c.rect(fx + 20, keel - h * 0.04, fx + 30, keel + h * 0.1, iron[1])
        c.blob(fx, h - h * 0.1, w * 0.07, h * 0.1, ramp(COPPER, 5)[1:])
        grille(c, fx - w * 0.04, h - h * 0.13, w * 0.08, h * 0.05)
        c.rect(fx - w * 0.04, h - 8, fx + w * 0.04, h, iron[0])
    # Deux moyeux, au tiers et aux deux tiers.
    for f in (1.0 / 3.0, 2.0 / 3.0):
        hub(c, x0 + (x1 - x0) * f, deck + h * 0.2, h * 0.06, "iron")
    return c.finish(darker(STEEL, 0.5))


def propeller(size, rnd, blades, base, tips=None, step=0.0, frames=4, hub_base=COPPER):
    """Hélice latérale vue de face (axe vers la caméra), moyeu au centre exact de chaque image ;
    tourne de step (radians) d'une image à l'autre."""
    w, h = size
    out = []
    tones = ramp(base, 5)
    for f in range(frames):
        c = Canvas(w, h, rnd)
        cx, cy = w / 2.0, h / 2.0
        r = min(w, h) * 0.46
        for k in range(blades):
            a = 2 * math.pi * k / blades + f * step
            blade = [(cx, cy - r * 0.08), (cx + r * 0.25, cy - r * 0.16), (cx + r, cy - r * 0.1), (cx + r * 0.98, cy + r * 0.12),
                     (cx + r * 0.25, cy + r * 0.1), (cx, cy + r * 0.08)]
            pts = rotate_points(blade, cx, cy, a)
            c.poly(pts, tones[2])
            lit = rotate_points([(cx + r * 0.25, cy - r * 0.16), (cx + r, cy - r * 0.1), (cx + r * 0.9, cy - r * 0.02),
                                 (cx + r * 0.25, cy - r * 0.04)], cx, cy, a)
            c.poly(lit, tones[3])
            if tips:
                tip = rotate_points([(cx + r * 0.8, cy - r * 0.13), (cx + r, cy - r * 0.1), (cx + r * 0.98, cy + r * 0.12),
                                     (cx + r * 0.8, cy + r * 0.11)], cx, cy, a)
                c.poly(tip, tips)
        hub(c, cx, cy, r * 0.18, hub_base)
        out.append(c.finish(darker(base, 0.5)))
    return out


def far_ship(size, rnd, kind):
    """Navire en vol au loin (24 px/m) : silhouette violacée, hublots, hélices floues, fumée."""
    w, h = size
    c = Canvas(w, h, rnd)
    haze = "#8A7A9A"
    if kind == "line":
        hull = mix("#C8C0B0", haze, 0.45)
    elif kind == "patrol":
        hull = mix("#3A4050", haze, 0.35)
    elif kind == "whale":
        hull = mix("#7A6A60", haze, 0.4)
    else:
        hull = mix("#6A4A3A", haze, 0.4)
    tones = ramp(hull, 5, spread=0.4)
    x0, x1 = w * 0.1, w * 0.88
    deck, keel = h * 0.46, h * (0.8 if kind != "whale" else 0.86)
    pts = hull_shape(w, h, x0, x1, deck, keel, bow_rise=0.08, stern_rise=0.05)
    c.poly(pts, tones[2])
    c.poly([(x, min(y, deck + h * 0.12)) for x, y in pts], tones[3])
    c.rect(x0 + w * 0.12, deck - h * 0.16, x0 + w * 0.36, deck, tones[3])
    if kind == "patrol":
        c.line([(x0, deck + h * 0.06), (x1, deck + h * 0.03)], mix(GARDE, haze, 0.3), max(2, int(h * 0.05)))
    glass = mix("crystal", haze, 0.25)
    rows = 1 if kind != "whale" else 2
    for row in range(rows):
        for k in range(10):
            x = x0 + w * (0.08 + 0.065 * k)
            if x < x1 - w * 0.08:
                c.rect(x, deck + h * (0.16 + 0.12 * row), x + max(2, w * 0.012), deck + h * (0.16 + 0.12 * row) + 2, glass)
    props = {"line": 2, "patrol": 1, "whale": 4, "ferry": 1}[kind]
    for k in range(props):
        x = x0 + (x1 - x0) * (k + 1) / (props + 1)
        y = deck + h * 0.2
        r = h * 0.14
        blur = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        bd = ImageDraw.Draw(blur)
        bd.ellipse((x - r, y - r, x + r, y + r), fill=rgba(tones[1]))
        mask = Image.new("L", (w, h), 0)
        mask.putdata([255 if (xx + yy) % 2 == 0 else 0 for yy in range(h) for xx in range(w)])
        c.img.paste(blur, (0, 0), Image.composite(mask, Image.new("L", (w, h), 0), blur.getchannel("A")))
        c.ellipse(x, y, 2, 2, tones[0])
    smoke = mix("#D8D0D8", haze, 0.3)
    for k in range(5):
        c.blob(x0 + w * 0.24 - k * w * 0.03, deck - h * 0.2 - k * h * 0.035, h * (0.04 + 0.008 * k), h * 0.035,
               [smoke, mix(smoke, "#FFFFFF", 0.3)])
    return c.finish(darker(hull, 0.45))


RECIPES = {
    "props/airship_ferry": airship_ferry, "props/airship_barocupot": airship_barocupot,
    "sky/airship_far_a": lambda s, r: far_ship(s, r, "line"),
    "sky/airship_far_b": lambda s, r: far_ship(s, r, "patrol"),
    "sky/airship_far_c": lambda s, r: far_ship(s, r, "whale"),
    "sky/airship_far_d": lambda s, r: far_ship(s, r, "ferry"),
}
