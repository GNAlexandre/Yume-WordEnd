#!/usr/bin/env python3
"""Images des effets de combat HD-2D (lot H7) : pixel art à 96 px par mètre, PNG RGBA, alpha en
paliers. Ce sont des remplaçants : une image dessinée à la main peut prendre la place de chacune
(même nom, même taille, mêmes images par bande) sans toucher au code.

    python3 src/combat/fx/make_fx.py            # réécrit les images de src/combat/fx/
    python3 src/combat/fx/make_fx.py --check    # vérifie tailles et alpha, sans rien écrire

Puis tools/import.sh (fichiers .import à commiter). Les bandes (glint, impact, bite, whip, dust,
slash, wave) portent plusieurs images de même taille côte à côte, de gauche à droite ; le jeu les
découpe d'après STRIPS dans src/combat/combat_fx.gd. Les images blanches ou grises (impact,
bite, dust) sont teintées par le jeu (modulate) : un seul dessin sert à l'épée, à l'onde et aux
crocs des Timeres.
"""

import math
import os
import sys

from PIL import Image

PPM = 96
HERE = os.path.dirname(os.path.abspath(__file__))

# Couleurs (MONDE.md 5.4, réchauffées par le couchant ; jamais de noir ni de blanc purs).
SHADOW = (40, 26, 44)
INK = (58, 36, 52)
WARM_WHITE = (255, 246, 222)
LIGHT = (232, 226, 214)
MID = (176, 168, 160)
GRAY = (104, 96, 100)
GOLD = (255, 214, 120)
GOLD_DARK = (176, 110, 52)
ORANGE = (255, 160, 80)
RED = (214, 74, 52)
RED_DARK = (110, 34, 38)
CORE_BLUE = (236, 248, 255)
SKY_BLUE = (150, 206, 246)
BLUE = (84, 150, 222)
DEEP_BLUE = (44, 78, 150)

# nom : (largeur d'une image, hauteur, nombre d'images)
SPECS = {
    "shadow": (64, 64, 1),
    "lock_ring": (96, 96, 1),
    "aim": (32, 32, 1),
    "danger_ring": (64, 64, 1),
    "danger_fill": (64, 64, 1),
    "rush_lane": (48, 192, 1),
    "glint": (32, 32, 3),
    "impact": (48, 48, 4),
    "bite": (48, 48, 3),
    "whip": (64, 32, 3),
    "dust": (32, 32, 4),
    "slash": (240, 120, 3),
    "wave": (192, 96, 2),
    "wave_trace": (192, 80, 1),
}


def blank(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def put(img, x, y, color, alpha=255):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), tuple(color[:3]) + (alpha,))


def disk(img, cx, cy, r, color, alpha=255):
    for y in range(img.height):
        for x in range(img.width):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                put(img, x, y, color, alpha)


def ring(img, cx, cy, r_in, r_out, color, alpha=255, a0=None, a1=None):
    """Anneau entre r_in et r_out ; a0..a1 (degrés, 0 = haut, sens horaire) le limite à un arc."""
    for y in range(img.height):
        for x in range(img.width):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = math.hypot(dx, dy)
            if not r_in <= d <= r_out:
                continue
            if a0 is not None:
                ang = math.degrees(math.atan2(dx, -dy))
                if not a0 <= ang <= a1:
                    continue
            put(img, x, y, color, alpha)


def line(img, x0, y0, x1, y1, color, alpha=255, width=1):
    steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
    for i in range(steps + 1):
        t = i / steps
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        for ox in range(-(width // 2), width - width // 2):
            for oy in range(-(width // 2), width - width // 2):
                put(img, int(round(x)) + ox, int(round(y)) + oy, color, alpha)


def outline(img, color, alpha=255):
    """Contour de 1 px autour des pixels opaques (jamais par-dessus)."""
    src = img.copy()
    px = src.load()
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < img.width and 0 <= ny < img.height and px[nx, ny][3] >= 160:
                    put(img, x, y, color, alpha)
                    break


def star(img, cx, cy, arm, core, ray, edge, diagonal=0):
    """Étoile à quatre branches (croix effilée) et, si diagonal, quatre branches courtes."""
    for i in range(-arm, arm + 1):
        thick = 1 if abs(i) > arm * 0.45 else 2
        color = core if abs(i) <= max(1, arm // 4) else ray
        for t in range(-(thick // 2), thick - thick // 2):
            put(img, cx + i, cy + t, color)
            put(img, cx + t, cy + i, color)
    for i in range(1, diagonal + 1):
        for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
            put(img, cx + sx * i, cy + sy * i, ray)
    disk(img, cx + 0.5, cy + 0.5, max(1.2, arm / 5), core)
    outline(img, edge)


def strip(frames):
    w, h = frames[0].size
    out = blank(w * len(frames), h)
    for i, frame in enumerate(frames):
        out.paste(frame, (i * w, 0))
    return out


# --- Images ---------------------------------------------------------------------------------


def make_shadow():
    """Ombre nette au sol : cœur sombre et bord plus clair, sans flou."""
    img = blank(64, 64)
    disk(img, 32, 32, 31.5, SHADOW, 92)
    disk(img, 32, 32, 23.5, SHADOW, 150)
    return img


def make_lock_ring():
    """Réticule de verrouillage posé au sol : quatre arcs dorés et quatre crans vers le centre."""
    img = blank(96, 96)
    for a in (-35, 55, 145, 235):
        lo, hi = a, a + 70
        if hi > 180:
            ring(img, 48, 48, 39, 44, GOLD, 255, lo - 360 if lo > 180 else lo, 180)
            ring(img, 48, 48, 39, 44, GOLD, 255, -180, hi - 360)
        else:
            ring(img, 48, 48, 39, 44, GOLD, 255, lo, hi)
    for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        for i in range(6):
            half = 5 - i
            for j in range(-half, half + 1):
                x = 48 + dx * (45 - i) + (j if dx == 0 else 0)
                y = 48 + dy * (45 - i) + (j if dy == 0 else 0)
                put(img, x - (1 if dx < 0 else 0), y - (1 if dy < 0 else 0), GOLD)
    ring(img, 48, 48, 41, 42, WARM_WHITE, 255)
    outline(img, GOLD_DARK)
    return img


def make_aim():
    """Chevron de visée au sol, pointe vers le haut de l'image (devant)."""
    img = blank(32, 32)
    for i in range(10):
        for t in range(4):
            put(img, 16 - 1 - i, 9 + i + t, GOLD)
            put(img, 16 + i, 9 + i + t, GOLD)
    for i in range(6):
        put(img, 16 - 1 - i, 10 + i, WARM_WHITE)
        put(img, 16 + i, 10 + i, WARM_WHITE)
    outline(img, GOLD_DARK)
    return img


def make_danger_ring():
    """Bord de la zone d'un coup de Timere (portée exacte de la Hitbox) : trait rouge net."""
    img = blank(64, 64)
    ring(img, 32, 32, 28.5, 31.5, RED, 235)
    ring(img, 32, 32, 29.5, 30.5, ORANGE, 255)
    return img


def make_danger_fill():
    """Remplissage de la zone, tramé (il grandit jusqu'au bord quand le coup part)."""
    img = blank(64, 64)
    for y in range(64):
        for x in range(64):
            if (x + 0.5 - 32) ** 2 + (y + 0.5 - 32) ** 2 <= 29 * 29:
                put(img, x, y, RED, 120 if (x // 2 + y // 2) % 2 == 0 else 72)
    return img


def make_rush_lane():
    """Couloir de la charge du Timere bondissant : deux rails et des chevrons vers l'avant."""
    img = blank(48, 192)
    for y in range(192):
        for x in range(4, 44):
            put(img, x, y, RED, 46 if (x // 2 + y // 2) % 2 == 0 else 26)
        for x in (3, 4, 43, 44):
            put(img, x, y, RED, 220)
    for top in range(14, 192, 32):
        for i in range(14):
            for t in range(3):
                put(img, 24 - 1 - i, top + i + t, ORANGE, 230)
                put(img, 24 + i, top + i + t, ORANGE, 230)
    return img


def make_glint():
    """Éclat avant l'attaque : petite étoile, grande étoile, étoile moyenne."""
    frames = []
    for arm, diag in ((5, 0), (13, 4), (9, 2)):
        img = blank(32, 32)
        star(img, 16, 16, arm, WARM_WHITE, ORANGE, RED_DARK, diag)
        frames.append(img)
    return strip(frames)


def make_impact():
    """Éclats d'impact (blanc et gris, teintés par le jeu)."""
    frames = []
    img = blank(48, 48)
    disk(img, 24, 24, 6, LIGHT)
    disk(img, 24, 24, 3.5, WARM_WHITE)
    for a in range(0, 360, 90):
        r = math.radians(a + 45)
        line(img, 24 + math.cos(r) * 6, 24 + math.sin(r) * 6,
             24 + math.cos(r) * 11, 24 + math.sin(r) * 11, LIGHT)
    outline(img, GRAY)
    frames.append(img)
    img = blank(48, 48)
    for a in range(0, 360, 45):
        r = math.radians(a + 22.5 * (a // 45 % 2))
        length = 20 if a % 90 == 0 else 14
        line(img, 24, 24, 24 + math.cos(r) * length, 24 + math.sin(r) * length, LIGHT, width=2)
    disk(img, 24, 24, 7.5, WARM_WHITE)
    outline(img, GRAY)
    frames.append(img)
    img = blank(48, 48)
    ring(img, 24, 24, 13, 15.5, LIGHT)
    for a in range(0, 360, 45):
        r = math.radians(a)
        line(img, 24 + math.cos(r) * 15, 24 + math.sin(r) * 15,
             24 + math.cos(r) * 22, 24 + math.sin(r) * 22, MID)
    disk(img, 24, 24, 3, WARM_WHITE)
    outline(img, GRAY)
    frames.append(img)
    img = blank(48, 48)
    for a in range(10, 360, 60):
        r = math.radians(a)
        disk(img, 24 + math.cos(r) * 19, 24 + math.sin(r) * 19, 1.6, MID)
    for a in range(40, 360, 90):
        r = math.radians(a)
        put(img, int(24 + math.cos(r) * 13), int(24 + math.sin(r) * 13), LIGHT)
    frames.append(img)
    return strip(frames)


def _jaw(img, y, upper, teeth_len):
    """Mâchoire : arc de 30 px et dents triangulaires tournées vers l'autre mâchoire."""
    for x in range(9, 39):
        bend = int(((x - 24) / 15.0) ** 2 * 5)
        yy = y - bend if upper else y + bend
        for t in range(3):
            put(img, x, yy + (-t if upper else t), LIGHT)
    for tx in range(11, 38, 5):
        bend = int(((tx + 1 - 24) / 15.0) ** 2 * 5)
        base = y - bend if upper else y + bend
        for i in range(teeth_len):
            for j in range(-max(0, 1 - i // 2), max(0, 1 - i // 2) + 1):
                put(img, tx + 1 + j, base + (i + 1 if upper else -(i + 1)), WARM_WHITE)


def make_bite():
    """Crocs qui se referment : ouverts, mi-clos, fermés avec éclats (blanc, teinté par le jeu)."""
    frames = []
    for upper_y, lower_y, sparks in ((9, 39, False), (16, 32, False), (21, 27, True)):
        img = blank(48, 48)
        _jaw(img, upper_y, True, 5)
        _jaw(img, lower_y, False, 5)
        if sparks:
            for sx, sy in ((5, 24), (42, 24), (24, 4), (24, 44)):
                star(img, sx, sy, 3, WARM_WHITE, LIGHT, GRAY)
        outline(img, RED_DARK)
        frames.append(img)
    return strip(frames)


def make_whip():
    """Coup de fouet : la langue se déroule vers la droite et claque au bout."""
    frames = []
    for reach, crack in ((0.45, 0), (0.85, 0), (1.0, 6)):
        img = blank(64, 32)
        end = int(4 + 56 * reach)
        for x in range(4, end):
            t = (x - 4) / 56.0
            y = 20 - math.sin(t * math.pi) * 8 + math.sin(t * math.pi * 3) * 2
            w = 3 if t < 0.5 else 2
            for k in range(w):
                put(img, x, int(y) + k, LIGHT)
        if crack:
            star(img, min(end, 58), 17, crack, WARM_WHITE, LIGHT, GRAY, 2)
        outline(img, RED_DARK)
        frames.append(img)
    return strip(frames)


def make_dust():
    """Bouffée de poussière (sable, teintée par le jeu) : recul, élan du Timere bondissant."""
    frames = []
    puffs = (
        ((16, 22, 3.5), (11, 24, 2.5), (21, 24, 2.5)),
        ((16, 20, 5.5), (9, 23, 4), (23, 23, 4)),
        ((16, 18, 6.5), (7, 21, 5), (25, 21, 5)),
        ((16, 14, 3), (5, 18, 2.5), (27, 18, 2.5)),
    )
    for i, frame in enumerate(puffs):
        img = blank(32, 32)
        for cx, cy, r in frame:
            disk(img, cx, cy, r, LIGHT if i < 2 else MID)
            if i < 3:
                disk(img, cx - r * 0.3, cy - r * 0.3, r * 0.45, WARM_WHITE)
        if i == 2:
            for hx, hy in ((14, 17), (8, 21), (24, 20)):
                put(img, hx, hy, (0, 0, 0), 0)
                put(img, hx + 1, hy, (0, 0, 0), 0)
        outline(img, GRAY)
        frames.append(img)
    return strip(frames)


def make_slash():
    """Coup d'épée posé au sol, à sa portée exacte : secteur de 90° jusqu'à 1,2 m de la pointe
    (milieu du bord bas), le haut de l'image devant. Traînée de la lame balayée de droite à
    gauche : épaisse et blanche au bord d'attaque, fine et bleue derrière ; puis pleine, puis
    effacée (le jeu la retourne pour le coup suivant)."""
    frames = []
    cx, cy = 120, 120
    r_out = 1.2 * PPM - 0.5
    for sweep, alpha, scale in ((0.55, 240, 1.0), (1.0, 240, 1.0), (1.0, 200, 0.6)):
        img = blank(240, 120)
        lo = 45 - 90 * sweep
        for y in range(120):
            for x in range(240):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                d = math.hypot(dx, dy)
                ang = math.degrees(math.atan2(dx, -dy))
                if not lo <= ang <= 45:
                    continue
                age = (ang - lo) / max(1.0, 45 - lo)  # 0 : bord d'attaque, 1 : début du coup
                thick = (6 + 34 * (1.0 - age) ** 1.4) * scale
                if not r_out - thick <= d <= r_out:
                    continue
                depth = (r_out - d) / max(1.0, thick)  # 0 : pointe de la lame
                if depth < 0.12:
                    color = SKY_BLUE
                elif depth < 0.5 and age < 0.55:
                    color = CORE_BLUE
                elif depth < 0.8:
                    color = SKY_BLUE if age < 0.8 else BLUE
                else:
                    color = BLUE
                put(img, x, y, color, alpha if age < 0.7 else alpha * 2 // 3)
        outline(img, DEEP_BLUE, alpha)
        frames.append(img)
    return strip(frames)


def _crescent(x, y, outer, inner):
    """Profondeur (0 au bord extérieur, 1 au bord intérieur) d'un point dans le croissant
    compris entre le cercle outer (dedans) et le cercle inner (dehors), ou None."""
    (ox, oy, orad), (ix, iy, irad) = outer, inner
    d_out = math.hypot(x - ox, y - oy)
    d_in = math.hypot(x - ix, y - iy)
    if d_out > orad or d_in < irad:
        return None
    gap = (orad - d_out) + (d_in - irad)
    return (orad - d_out) / gap if gap > 0 else 0.0


def make_wave():
    """Onde de la charge, debout : croissant « ⌒ » de 2 m sur 1 m, bosse vers le haut (là où elle
    file), pointes effilées ; bord avant bleu clair, cœur blanc, arrière bleu ; étincelles qui
    scintillent d'une image à l'autre sous le croissant."""
    frames = []
    outer, inner = (96, 106, 100), (96, 162.9, 134.9)
    for flicker in (0, 1):
        img = blank(192, 96)
        for y in range(96):
            for x in range(192):
                t = _crescent(x + 0.5, y + 0.5, outer, inner)
                if t is None:
                    continue
                if t < 0.15:
                    color = SKY_BLUE
                elif t < 0.55:
                    color = CORE_BLUE
                elif t < 0.8:
                    color = SKY_BLUE
                else:
                    color = BLUE
                put(img, x, y, color)
        sparks = ((40, 58), (66, 40), (96, 46), (126, 40), (152, 58), (80, 70), (112, 72))
        for i, (sx, sy) in enumerate(sparks):
            if (i + flicker) % 2 == 0:
                star(img, sx, sy + 3 * flicker, 2 + (i % 2), CORE_BLUE, SKY_BLUE, DEEP_BLUE)
        outline(img, DEEP_BLUE)
        frames.append(img)
    return strip(frames)


def make_wave_trace():
    """Trace de l'onde au sol : son empreinte (2 m de large), bord avant clair, arrière tramé."""
    img = blank(192, 80)
    outer, inner = (96, 106, 100), (96, 160.45, 130.45)
    for y in range(80):
        for x in range(192):
            t = _crescent(x + 0.5, y + 0.5, outer, inner)
            if t is None:
                continue
            if t < 0.2:
                put(img, x, y, CORE_BLUE, 230)
            elif t < 0.5:
                put(img, x, y, SKY_BLUE, 160)
            else:
                put(img, x, y, BLUE, 100 if (x // 2 + y // 2) % 2 else 64)
    return img


MAKERS = {
    "shadow": make_shadow,
    "lock_ring": make_lock_ring,
    "aim": make_aim,
    "danger_ring": make_danger_ring,
    "danger_fill": make_danger_fill,
    "rush_lane": make_rush_lane,
    "glint": make_glint,
    "impact": make_impact,
    "bite": make_bite,
    "whip": make_whip,
    "dust": make_dust,
    "slash": make_slash,
    "wave": make_wave,
    "wave_trace": make_wave_trace,
}


def check():
    problems = []
    for name, (w, h, n) in SPECS.items():
        path = os.path.join(HERE, name + ".png")
        if not os.path.exists(path):
            problems.append(f"{name}.png absent")
            continue
        img = Image.open(path)
        if img.mode != "RGBA":
            problems.append(f"{name}.png : mode {img.mode} (RGBA attendu)")
        if img.size != (w * n, h):
            problems.append(f"{name}.png : {img.size} au lieu de {(w * n, h)}")
    for problem in problems:
        print(problem)
    return 1 if problems else 0


def main(argv):
    if "--check" in argv:
        return check()
    for name, maker in MAKERS.items():
        img = maker()
        w, h, n = SPECS[name]
        assert img.size == (w * n, h), (name, img.size)
        img.save(os.path.join(HERE, name + ".png"), optimize=True)
        print(f"src/combat/fx/{name}.png {img.width} × {img.height}")
    return check()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
