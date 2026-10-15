#!/usr/bin/env python3
"""Planches de remplacement de la faune (lot E5) : un animal = une planche au format des
personnages, tournée vers la droite (docs/ASSETS_HD2D_ILE68.md, section 7.3 ; docs/REFONTE.md 8.1).

Les vraies planches (cahier n° 5, lot R5) remplaceront ces silhouettes sans toucher au code : même
chemin (assets/fauna/<id>/<id>.png et .json), mêmes animations. Chaque planche suit le JSON de
l'easter egg (ancres par image, « coup »), à 96 px par mètre : la 1re image de « repos » mesure
exactement la hauteur au repos du cahier.

Usage (Python 3.9+, Pillow ; gen_placeholders.py appelle ce module) :

    python3 tools/gen_placeholders.py fauna              # toutes les espèces
    python3 tools/gen_placeholders.py fauna wolf deer    # seulement celles-ci
    python3 tools/gen_placeholders.py fauna --list       # les espèces et leurs animations
    python3 tools/gen_fauna.py preview wolf              # planche de contrôle build/e5/preview_wolf.png

Écrit assets/fauna/<id>/<id>.png et .json, et le SkinData data/fauna/ile_68/visuals/<id>.tres
(sans portrait : une bête ne parle pas). Résultat déterministe. Les trois vues (face, dos) du
cahier sont facultatives (SkinData) : les remplaçants n'ont que le profil.

Dessin : les silhouettes sont des ellipses et des capsules (Pen de gen_placeholders.py), en unités
où la hauteur au repos vaut environ 1 ; la planche est ensuite mise à l'échelle par build_sheet.
"""

import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import gen_placeholders as gp  # noqa: E402
from gen_placeholders import Pose, hex_color, shade  # noqa: E402

ROOT = gp.ROOT
FAUNA_DIR = os.path.join(ROOT, "assets", "fauna")
VISUALS_DIR = os.path.join("data", "fauna", "ile_68", "visuals")
EYE = (30, 24, 28, 255)
WHITE = (250, 248, 240, 255)
MOUTH = (140, 42, 52, 255)
SPLASH = (190, 220, 240, 255)

# Animations du cahier (section 7.3) : nom → (images, ips, boucle, coup). marche et course des
# oiseaux et de la grenouille ont 4 images (sauts).
ANIMS = {
    "repos": (2, 2, True, None),
    "marche": (6, 8, True, None),
    "course": (5, 14, True, None),
    "attaque": (4, 12, False, [2]),
    "degats": (1, 1, False, None),
    "mort": (2, 4, False, None),
    "fuite": (4, 12, False, None),
    "broute": (4, 4, True, None),
}
HOPPERS = ("marche", "course")


def beast_look(fur, **extra):
    look = dict(fur=hex_color(fur), len=1.1, ry=0.2, leg=0.4, neck=(0.30, 0.22), head=(0.14, 0.1),
                snout=0.16, ears="pointed", ear=0.14, tail="low", features=())
    for key in ("belly", "dark", "accent", "eye"):
        if key in extra:
            extra[key] = hex_color(extra[key])
    look.update(extra)
    look.setdefault("belly", shade(look["fur"], 1.3))
    look.setdefault("dark", shade(look["fur"], 0.6))
    look.setdefault("accent", WHITE)
    look.setdefault("eye", EYE)
    return look


# Espèces : id → type de dessin, hauteur au repos (m), nom affiché, animations, apparence.
SPECIES = {
    "wolf": dict(kind="beast", height=0.85, name="Loup", anims=["repos", "marche", "course", "attaque", "degats", "mort"],
                 look=beast_look("#7a7c82", belly="#cdbf9e", dark="#4b4c52", len=1.2, ry=0.2, leg=0.44,
                                 neck=(0.34, 0.2), head=(0.15, 0.1), snout=0.2, ear=0.15, tail="low",
                                 eye="#e6c64e", features=("saddle",))),
    "bear": dict(kind="beast", height=1.2, name="Ours", anims=["repos", "marche", "course", "attaque", "degats", "mort"],
                 look=beast_look("#6b4a30", belly="#7f5a3c", dark="#43301f", len=1.5, ry=0.34, leg=0.4,
                                 neck=(0.4, 0.14), head=(0.2, 0.15), snout=0.14, ears="round", ear=0.07, tail="stub",
                                 features=("hump",), leg_width=0.2)),
    "boar": dict(kind="beast", height=0.9, name="Sanglier", anims=["repos", "marche", "course", "attaque", "degats", "mort", "broute"],
                 look=beast_look("#4d3b30", belly="#6d5646", dark="#2a2019", len=1.3, ry=0.27, leg=0.33,
                                 neck=(0.36, 0.0), head=(0.18, 0.13), snout=0.22, ears="small", ear=0.08, tail="thin",
                                 features=("tusks", "bristles"), leg_width=0.1)),
    "deer": dict(kind="beast", height=1.9, name="Cerf", anims=["repos", "marche", "course", "broute"],
                 look=beast_look("#a4622c", belly="#e7cfa0", dark="#5b3a1e", len=1.05, ry=0.17, leg=0.62,
                                 neck=(0.26, 0.5), head=(0.11, 0.07), snout=0.15, ears="long", ear=0.17, tail="stub",
                                 features=("antlers",), leg_width=0.06)),
    "fox": dict(kind="beast", height=0.45, name="Renard", anims=["repos", "marche", "course", "fuite"],
                look=beast_look("#c8622a", belly="#f1e4cf", dark="#2e2420", len=0.9, ry=0.15, leg=0.34,
                                neck=(0.28, 0.16), head=(0.12, 0.08), snout=0.17, ear=0.15, tail="bushy",
                                features=("socks", "throat"), leg_width=0.05)),
    "squirrel": dict(kind="beast", height=0.25, name="Écureuil", anims=["repos", "marche", "course", "fuite"],
                     look=beast_look("#b8582a", belly="#ead8bd", dark="#6b3319", len=0.62, ry=0.17, leg=0.25,
                                     neck=(0.22, 0.2), head=(0.11, 0.09), snout=0.07, ear=0.1, tail="squirrel",
                                     features=("tufts",), leg_width=0.05)),
    "frog": dict(kind="frog", height=0.12, name="Grenouille", anims=["repos", "marche", "course", "fuite"],
                 look=dict(fur=hex_color("#5d8a3a"), dark=hex_color("#2f4a24"), belly=hex_color("#d8e0a0"))),
    "blackbird": dict(kind="bird", height=0.2, name="Merle", anims=["repos", "marche", "course", "fuite"], loop_fuite=True,
                      look=dict(fur=hex_color("#26252b"), belly=hex_color("#37353f"), beak=hex_color("#e8b32a"),
                                tail=0.5, legs=0.3, body=(0.34, 0.22), head=0.15, beak_len=0.17)),
    "crow": dict(kind="bird", height=0.4, name="Corbeau", anims=["repos", "marche", "course", "fuite"], loop_fuite=True,
                 look=dict(fur=hex_color("#1c1d28"), belly=hex_color("#2c3144"), beak=hex_color("#3a3a44"),
                           tail=0.55, legs=0.34, body=(0.36, 0.22), head=0.16, beak_len=0.24)),
    "owl": dict(kind="owl", height=0.4, name="Chouette", anims=["repos", "fuite"], loop_fuite=True,
                look=dict(fur=hex_color("#8a5c3a"), belly=hex_color("#d9c19c"), beak=hex_color("#d8b04a"),
                          dark=hex_color("#4d321f"))),
}


# --- Bêtes à quatre pattes ---------------------------------------------------------------------


def beast_poses(species, anim, count):
    """Poses d'une bête pour l'animation anim (count images)."""
    look = SPECIES[species]["look"]
    tail_swing = 0.0
    result = []
    for i in range(count):
        s = math.sin(2 * math.pi * i / count)
        c = math.cos(2 * math.pi * i / count)
        if anim == "repos":
            result.append(Pose(head=(0.0, 0.015 * i), tail_a=0.1 * i, breath=0.01 * i))
        elif anim == "marche":
            result.append(Pose(legs=0.38 * s, head=(0.0, 0.015 * abs(s)), tail_a=0.1 * s, lift=0.012 * abs(s)))
        elif anim == "course":
            result.append(Pose(legs=0.85 * s, lean=0.06, head=(0.06, -0.03), tail_a=0.35, lift=0.07 * abs(c),
                               spread=1.0))
        elif anim == "attaque":
            # ramassé (0), élan (1), coup (2 : le corps bondit, la gueule se ferme), retour (3)
            crouch = [0.07, 0.0, 0.0, 0.03][i]
            result.append(Pose(crouch=crouch, lean=[-0.04, 0.08, 0.16, 0.05][i], jaw=[0.0, 0.9, 1.0, 0.2][i],
                               head=[(-0.04, -0.03), (0.06, -0.02), (0.14, -0.04), (0.04, 0.0)][i],
                               legs=[0.0, 0.5, 0.9, 0.2][i], lift=[0.0, 0.04, 0.1, 0.0][i], rear=[0.0, 0.0, 0.0, 0.0][i],
                               tail_a=0.2, paw=[0, 0, 1, 0][i]))
        elif anim == "degats":
            result.append(Pose(lean=-0.16, head=(-0.1, 0.0), eyes="hurt", jaw=0.4, flash=True, tail_a=-0.3, crouch=0.02))
        elif anim == "mort":
            result.append(Pose(flat=True, eyes="closed" if i else "hurt", rise=0.25 if i == 0 else 0.0, head=(0.0, 0.0)))
        elif anim == "fuite":
            # grand bond vers la droite : ramassé, détente, vol, réception
            result.append(Pose(lean=[-0.1, 0.34, 0.22, 0.05][i], lift=[0.0, 0.26, 0.38, 0.1][i], legs=[0.0, 0.9, 0.5, 0.3][i],
                               spread=1.0, head=(0.04, 0.02), tail_a=0.4, crouch=[0.06, 0.0, 0.0, 0.02][i]))
        elif anim == "broute":
            # la tête au ras du sol (images 0 à 2), relevée à l'image 3
            down = [1.0, 1.0, 0.85, 0.0][i]
            result.append(Pose(down=down, head=(0.0, 0.0), tail_a=0.1 * (i % 2), chew=1 if i == 1 else 0))
        else:
            result.append(Pose())
    return result


def draw_beast(pen, p, look):
    fur, belly, dark, accent = look["fur"], look["belly"], look["dark"], look["accent"]
    ry, blen, leg_len = look["ry"], look["len"], look["leg"]
    lw = look.get("leg_width", 0.08)
    crouch, lift = getattr(p, "crouch", 0.0), getattr(p, "lift", 0.0)
    if getattr(p, "flat", False):
        return draw_beast_lying(pen, p, look)
    if p.flash:
        fur, belly, dark = shade(fur, 1.5), shade(belly, 1.3), shade(dark, 1.8)
    by = leg_len + ry - crouch + lift
    sx, hx = blen * 0.32, -blen * 0.32
    rear = getattr(p, "rear", 0.0)
    shoulder = (sx, by + ry * 0.35)

    def leg(x, angle, tone, front):
        top_y = by - ry * 0.3
        reach = top_y if lift <= 0.0 else top_y - lift * 0.4
        spread = 1.25 if getattr(p, "spread", 0.0) else 1.0
        fx = x + math.sin(angle) * reach * 0.8 * spread
        fy = max(0.0, top_y - math.cos(angle) * reach) if angle > 0 else 0.0
        if lift > 0.0:
            fy = max(fy, lift * 0.8 * (0.5 + 0.5 * math.sin(angle)))
        if getattr(p, "paw", 0) and front:
            fx, fy = x + 0.28, top_y * 0.6
        pen.capsule(x, top_y, fx, fy + lw * 0.4, lw, tone)
        paw = dark if ("socks" in look["features"] or look["tail"] == "bushy") else tone
        pen.ellipse(fx + 0.01, fy + lw * 0.3, lw * 0.75, lw * 0.4, paw if "socks" in look["features"] else tone)

    # Pattes lointaines, queue, corps, pattes proches.
    a = p.legs
    far_tone, near_tone = shade(fur, 0.72), fur
    leg(sx, a, far_tone, True)
    leg(hx, -a, far_tone, False)
    _draw_tail(pen, p, look, (hx - blen * 0.12, by + ry * 0.25), fur, dark)
    pen.ellipse(0.0, by, blen / 2 + 0.07, ry, fur)
    pen.ellipse(sx * 0.9, by + ry * 0.1, 0.22 + 0.04 * (look["ry"] > 0.3), ry * 1.08, fur, outline=False)
    pen.ellipse(0.04, by - ry * 0.45, blen * 0.38, ry * 0.5, belly, outline=False)
    if "saddle" in look["features"]:
        pen.ellipse(-0.05, by + ry * 0.55, blen * 0.4, ry * 0.45, shade(fur, 0.8), outline=False)
    if "hump" in look["features"]:
        pen.ellipse(sx * 0.7, by + ry * 0.75, 0.3, ry * 0.65, fur)
    if "bristles" in look["features"]:
        for k in range(8):
            x = hx * 0.9 + (sx * 1.3 - hx * 0.9) * k / 7
            top = by + ry * (0.85 + 0.15 * math.sin(k * 1.9))
            pen.poly([(x - 0.045, top - 0.05), (x + 0.005, top + 0.1), (x + 0.05, top - 0.05)], dark, outline=False)
    leg(sx - 0.06, -a, near_tone, True)
    leg(hx + 0.06, a, near_tone, False)
    _draw_head(pen, p, look, shoulder, fur, belly, dark, accent, rear)


def _draw_tail(pen, p, look, root, fur, dark):
    swing = getattr(p, "tail_a", 0.0)
    kind = look["tail"]
    x, y = root
    if kind == "low":  # loup : queue basse, balancée
        pen.capsule(x, y, x - 0.28, y - 0.18 + 0.14 * swing, 0.1, fur)
    elif kind == "bushy":  # renard : panache à bout blanc
        ex, ey = x - 0.42, y + 0.02 + 0.1 * swing
        pen.ellipse((x + ex) / 2, (y + ey) / 2, 0.26, 0.085, fur)
        pen.ellipse(ex - 0.06, ey, 0.1, 0.07, WHITE)
    elif kind == "squirrel":  # écureuil : panache en cimier au-dessus du dos
        for t in range(7):
            u = t / 6.0
            cx = x - 0.04 - 0.12 * math.sin(u * 2.3) + 0.02 * swing
            cy = y + 0.1 + 0.42 * u
            pen.ellipse(cx, cy, 0.12 - 0.03 * u + 0.02 * math.sin(u * math.pi), 0.1, fur)
    elif kind == "thin":  # sanglier : petite queue fine
        pen.capsule(x, y, x - 0.1, y - 0.06 + 0.08 * swing, 0.03, dark)
    else:  # moignon (ours, cerf à miroir blanc)
        pen.ellipse(x - 0.03, y, 0.06, 0.05, WHITE if look["ears"] == "long" else dark)


def _draw_head(pen, p, look, shoulder, fur, belly, dark, accent, rear):
    nx, ny = look["neck"]
    hdx, hdy = p.head
    down = getattr(p, "down", 0.0)
    sx, sy = shoulder
    hx, hy = sx + nx + hdx, sy + ny + hdy
    if down:  # il broute : la tête au ras du sol
        hx = sx + nx * 0.9 + 0.12
        hy = (0.05 + look["head"][1]) * down + hy * (1 - down)
    neck_w = look["head"][1] * 1.7
    pen.capsule(sx, sy - 0.02, hx - look["head"][0] * 0.3, hy - 0.02, neck_w, fur)
    rx, ry = look["head"]
    if look["ears"] == "long" or look["ears"] == "pointed":
        back = look["ear"]
        for off, tone in ((-0.04, shade(fur, 0.7)), (0.02, fur)):
            pen.poly([(hx - rx * 0.4 + off, hy + ry * 0.5), (hx - rx * 0.9 + off - back * 0.4, hy + ry + back),
                      (hx + rx * 0.2 + off, hy + ry * 0.7)], tone)
    elif look["ears"] == "round":
        pen.ellipse(hx - rx * 0.35, hy + ry * 0.85, look["ear"], look["ear"], fur)
    else:
        pen.poly([(hx - rx * 0.4, hy + ry * 0.6), (hx - rx * 0.6, hy + ry + look["ear"]), (hx, hy + ry * 0.75)], fur)
    if "antlers" in look["features"]:
        _draw_antlers(pen, hx - 0.02, hy + ry * 0.7, dark)
    if "tufts" in look["features"]:
        pen.poly([(hx - rx * 0.2, hy + ry * 0.6), (hx - rx * 0.4, hy + ry * 2.1), (hx + rx * 0.1, hy + ry * 0.7)], dark, outline=False)
    pen.ellipse(hx, hy, rx, ry, fur)
    snout = look["snout"]
    jaw = getattr(p, "jaw", 0.0)
    tip = (hx + rx + snout, hy - ry * 0.25)
    pen.poly([(hx + rx * 0.3, hy + ry * 0.7), (tip[0], tip[1] + ry * 0.35), (tip[0], tip[1] - ry * 0.1),
              (hx + rx * 0.3, hy - ry * 0.55)], belly if "throat" in look["features"] else fur)
    if jaw > 0.05:
        open_y = ry * 1.4 * jaw
        pen.poly([(hx + rx * 0.2, hy - ry * 0.3), (tip[0], tip[1] - 0.02), (tip[0] - snout * 0.25, tip[1] - open_y - ry * 0.3),
                  (hx + rx * 0.1, hy - ry * 0.9 - open_y * 0.3)], MOUTH)
        pen.poly([(tip[0] - snout * 0.9, tip[1] - 0.02), (tip[0] - snout * 0.6, tip[1] - 0.06), (tip[0] - snout * 0.75, tip[1] - 0.012)], WHITE, outline=False)
    else:
        pen.poly([(hx + rx * 0.1, hy - ry * 0.55), (tip[0] - 0.01, tip[1] - 0.02), (tip[0] - snout * 0.5, tip[1] - ry * 0.55),
                  (hx + rx * 0.1, hy - ry * 0.95)], belly if look["ears"] != "round" else shade(fur, 1.1))
    if "tusks" in look["features"]:
        pen.poly([(tip[0] - 0.08, tip[1] - 0.05), (tip[0] - 0.02, tip[1] + 0.1), (tip[0] - 0.12, tip[1] - 0.02)], WHITE)
    pen.ellipse(tip[0], tip[1] + 0.01, 0.025, 0.02, EYE, outline=False)
    ex, ey = hx + rx * 0.45, hy + ry * 0.25
    if p.eyes == "closed":
        pen.capsule(ex - 0.03, ey, ex + 0.03, ey, 0.014, EYE)
    else:
        pen.ellipse(ex, ey, 0.026, 0.026, look["eye"], outline=False)
        pen.ellipse(ex + 0.006, ey, 0.012, 0.014, EYE, outline=False)
    if getattr(p, "chew", 0):
        pen.ellipse(tip[0] - 0.03, tip[1] - 0.03, 0.02, 0.012, dark, outline=False)


def _draw_antlers(pen, x, y, tone):
    """Bois de cerf : une perche qui monte en arrière puis en avant, quatre andouillers."""
    points = [(x, y), (x - 0.06, y + 0.14), (x - 0.04, y + 0.3), (x + 0.04, y + 0.44), (x + 0.12, y + 0.52)]
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        pen.capsule(x0, y0, x1, y1, 0.035, tone)
    for k, (bx, by) in enumerate(points[1:4]):
        pen.capsule(bx, by, bx + 0.12, by + 0.1 + 0.02 * k, 0.025, tone)
    pen.capsule(x, y + 0.02, x + 0.12, y + 0.08, 0.025, tone)


def draw_beast_lying(pen, p, look):
    """Couché sur le flanc, immobile, les yeux fermés ; aucun sang (image 0 : il vacille)."""
    fur, belly, dark = look["fur"], look["belly"], look["dark"]
    ry, blen = look["ry"], look["len"]
    rise = getattr(p, "rise", 0.0)
    h = ry * 1.1
    pen.ellipse(0.0, h * 0.8 + rise * 0.4, blen / 2 + 0.05, h * 0.85, fur)
    pen.ellipse(0.05, h * 0.45 + rise * 0.3, blen * 0.38, h * 0.4, belly, outline=False)
    for k in range(2):
        x = -blen * 0.28 + 0.55 * blen * k
        pen.capsule(x, h * 0.7 + rise * 0.3, x + 0.22, 0.04 + rise * 0.3, look.get("leg_width", 0.08), shade(fur, 0.8))
    _draw_tail(pen, p, look, (-blen * 0.5, h * 0.6), fur, dark)
    nx, ny = look["neck"]
    rx, hr = look["head"]
    hx, hy = blen * 0.5 + 0.02, hr + 0.02 + rise * 0.5
    pen.capsule(blen * 0.3, h * 0.9, hx - rx * 0.4, hy, hr * 1.6, fur)
    pen.ellipse(hx, hy, rx, hr, fur)
    pen.ellipse(hx + rx + look["snout"] * 0.45, hy - hr * 0.2, look["snout"] * 0.6, hr * 0.5, belly if "throat" in look["features"] else fur)
    pen.ellipse(hx + rx + look["snout"] * 0.9, hy - hr * 0.1, 0.02, 0.016, EYE, outline=False)
    pen.capsule(hx + rx * 0.3, hy + hr * 0.3, hx + rx * 0.7, hy + hr * 0.3, 0.014, EYE)
    if p.eyes == "hurt":
        pen.capsule(hx + rx * 0.3, hy + hr * 0.4, hx + rx * 0.7, hy + hr * 0.2, 0.014, EYE)
    if "antlers" in look["features"]:
        _draw_antlers(pen, hx - 0.05, hy + hr * 0.6, dark)


# --- Oiseaux ------------------------------------------------------------------------------------


def bird_poses(species, anim, count):
    result = []
    for i in range(count):
        s = math.sin(2 * math.pi * i / count)
        if anim == "repos":
            result.append(Pose(turn=i, sing=(1 if i == 1 else 0), tilt=0.1 * i))
        elif anim == "marche":  # petits sauts : le corps monte et redescend, les pattes alternent
            result.append(Pose(hop=0.04 * max(s, 0.0), step=0.5 * s, tilt=0.05, lean=0.04))
        elif anim == "course":
            result.append(Pose(hop=0.1 * max(s, 0.0), step=0.9 * s, tilt=0.1, lean=0.14))
        elif anim == "fuite":  # envol puis battements sur place
            result.append(Pose(lift=0.3 + 0.08 * (i % 2), wing=[-0.2, 0.9, 1.4, 0.5][i % 4], flying=True, lean=0.12,
                               turn=0, tilt=0.0))
        else:
            result.append(Pose())
    return result


def draw_bird(pen, p, look):
    fur, belly, beak = look["fur"], look["belly"], look["beak"]
    bx, by = look["body"]
    hop = getattr(p, "hop", 0.0)
    lift = getattr(p, "lift", 0.0)
    flying = getattr(p, "flying", False)
    leg_h = look["legs"]
    cy = leg_h + by + hop + lift
    step = getattr(p, "step", 0.0)
    if not flying:  # pattes fines
        for side, tone in ((-1, shade(beak, 0.7)), (1, beak)):
            fx = 0.04 * side + 0.07 * step * side
            fy = max(0.0, 0.06 * step * side) * (hop > 0.0)
            pen.capsule(0.0, cy - by * 0.6, fx, fy, 0.025, tone)
            pen.capsule(fx, fy, fx + 0.07, fy, 0.025, tone)
    # Queue, corps, aile, tête.
    tail = look["tail"]
    pen.poly([(-bx * 0.7, cy + by * 0.2), (-bx * 0.7 - tail * 0.55, cy - by * 0.15 - (0.12 if flying else 0.0)),
              (-bx * 0.7 - tail * 0.45, cy - by * 0.55), (-bx * 0.5, cy - by * 0.4)], shade(fur, 0.8))
    pen.ellipse(0.0, cy, bx, by, fur)
    pen.ellipse(bx * 0.15, cy - by * 0.35, bx * 0.7, by * 0.5, belly, outline=False)
    wing = getattr(p, "wing", None)
    if wing is None:
        pen.ellipse(-bx * 0.12, cy + by * 0.05, bx * 0.62, by * 0.55, shade(fur, 0.75))
    else:  # aile levée, d'un angle wing (0 : repliée vers l'arrière, 1,4 : droite en haut)
        root = (-bx * 0.05, cy + by * 0.35)
        length = bx * 1.5
        tip = (root[0] - math.cos(wing) * length * 0.8, root[1] + math.sin(wing) * length)
        pen.poly([root, (tip[0] - 0.04, tip[1]), (tip[0] + 0.1, tip[1] - 0.05), (root[0] + bx * 0.5, root[1] - by * 0.2)], shade(fur, 0.7))
    hr = look["head"]
    hx, hy = bx * 0.78, cy + by * 0.62 + getattr(p, "tilt", 0.0) * 0.05
    pen.ellipse(hx, hy, hr, hr, fur)
    open_beak = 0.07 if getattr(p, "sing", 0) else 0.0
    blen = look["beak_len"]
    pen.poly([(hx + hr * 0.7, hy + 0.025 + open_beak * 0.3), (hx + hr + blen, hy - 0.004 + open_beak * 0.4),
              (hx + hr * 0.7, hy - 0.02)], beak)
    if open_beak:
        pen.poly([(hx + hr * 0.7, hy - 0.02), (hx + hr + blen * 0.8, hy - 0.02 - open_beak), (hx + hr * 0.6, hy - 0.05)], beak)
    pen.ellipse(hx + hr * 0.3, hy + hr * 0.2, 0.022, 0.022, WHITE if look["fur"][0] > 60 else (210, 200, 120, 255), outline=False)
    pen.ellipse(hx + hr * 0.36, hy + hr * 0.2, 0.012, 0.012, EYE, outline=False)


def draw_owl(pen, p, look):
    fur, belly, beak, dark = look["fur"], look["belly"], look["beak"], look["dark"]
    flying = getattr(p, "flying", False)
    lift = getattr(p, "lift", 0.0)
    cy = 0.34 + lift
    if not flying:
        for side in (-1, 1):
            pen.capsule(0.06 * side, 0.1, 0.07 * side, 0.0, 0.06, beak)
    wing = getattr(p, "wing", None)
    pen.ellipse(0.0, cy, 0.24, 0.34, fur)
    pen.ellipse(0.03, cy - 0.06, 0.14, 0.24, belly, outline=False)
    for k in range(4):
        pen.ellipse(0.04, cy - 0.2 + 0.1 * k, 0.045, 0.02, dark, outline=False)
    if wing is not None:
        root = (-0.05, cy + 0.2)
        tip = (root[0] - math.cos(wing) * 0.5, root[1] + math.sin(wing) * 0.5)
        pen.poly([root, (tip[0] - 0.05, tip[1]), (tip[0] + 0.1, tip[1] - 0.05), (root[0] + 0.2, root[1] - 0.1)], shade(fur, 0.7))
    else:
        pen.ellipse(-0.1, cy + 0.02, 0.1, 0.25, shade(fur, 0.75))
    hy = cy + 0.34
    turn = getattr(p, "turn", 0)
    pen.ellipse(0.0, hy, 0.22, 0.17, fur)
    pen.poly([(-0.17, hy + 0.1), (-0.13, hy + 0.3), (-0.04, hy + 0.15)], fur)
    pen.poly([(0.04, hy + 0.15), (0.13, hy + 0.3), (0.17, hy + 0.1)], fur)
    if turn:  # la tête a pivoté : de profil, un seul œil, le bec à droite
        pen.ellipse(0.1, hy, 0.1, 0.12, belly, outline=False)
        pen.ellipse(0.12, hy + 0.02, 0.055, 0.055, (240, 200, 60, 255))
        pen.ellipse(0.13, hy + 0.02, 0.03, 0.03, EYE, outline=False)
        pen.poly([(0.2, hy - 0.01), (0.27, hy - 0.04), (0.2, hy - 0.07)], beak)
    else:
        pen.ellipse(-0.08, hy, 0.085, 0.1, belly, outline=False)
        pen.ellipse(0.08, hy, 0.085, 0.1, belly, outline=False)
        for ex in (-0.08, 0.08):
            pen.ellipse(ex, hy + 0.01, 0.05, 0.05, (240, 200, 60, 255))
            pen.ellipse(ex, hy + 0.01, 0.028, 0.028, EYE, outline=False)
        pen.poly([(-0.02, hy - 0.01), (0.02, hy - 0.01), (0.0, hy - 0.08)], beak)


# --- Grenouille ---------------------------------------------------------------------------------


def frog_poses(species, anim, count):
    result = []
    for i in range(count):
        s = math.sin(2 * math.pi * i / count)
        if anim == "repos":
            result.append(Pose(throat=0.3 + 0.7 * i, hop=0.0, extend=0.0))
        elif anim == "marche":
            result.append(Pose(hop=[0.0, 0.2, 0.28, 0.0][i], extend=[0.0, 0.6, 1.0, 0.1][i], throat=0.2))
        elif anim == "course":
            result.append(Pose(hop=[0.0, 0.5, 0.65, 0.05][i], extend=[0.0, 0.9, 1.0, 0.2][i], throat=0.2, lean=0.1))
        elif anim == "fuite":  # plongeon : l'image 3 ne montre qu'une gerbe
            result.append(Pose(hop=[0.0, 0.5, -0.4, -1.5][i], extend=[0.3, 1.0, 1.0, 0.0][i], splash=[0, 0, 1, 2][i], lean=0.2,
                               clip=i >= 2))
        else:
            result.append(Pose())
    return result


def draw_frog(pen, p, look):
    fur, dark, belly = look["fur"], look["dark"], look["belly"]
    hop = getattr(p, "hop", 0.0)
    ext = getattr(p, "extend", 0.0)
    cy = 0.28 + hop
    if getattr(p, "splash", 0) < 2:
        # cuisse repliée ou étendue derrière
        hip = (-0.2, cy - 0.05)
        foot = (-0.2 - 0.5 * ext, cy - 0.3 - 0.0 * ext) if ext > 0.4 else (-0.05, 0.03 + max(hop, 0))
        pen.capsule(hip[0], hip[1], -0.45 * (0.4 + ext) + 0.0, max(0.02, cy - 0.28 * (1 - ext)), 0.15, shade(fur, 0.8))
        pen.capsule(-0.45 * (0.4 + ext), max(0.02, cy - 0.28 * (1 - ext)), foot[0] - 0.1, foot[1], 0.07, shade(fur, 0.8))
        pen.ellipse(0.0, cy, 0.42, 0.26, fur)
        pen.ellipse(0.1, cy - 0.12, 0.3, 0.14, belly, outline=False)
        for k in range(3):
            pen.ellipse(-0.2 + 0.18 * k, cy + 0.12, 0.05, 0.04, dark, outline=False)
        pen.ellipse(0.3, cy + 0.02, 0.2, 0.17, fur)
        throat = getattr(p, "throat", 0.0)
        pen.ellipse(0.44, cy - 0.12, 0.09 + 0.07 * throat, 0.06 + 0.07 * throat, belly)
        pen.capsule(0.12, cy - 0.1, 0.22 + 0.2 * ext, max(0.02, cy - 0.3 + 0.1 * ext), 0.07, fur)
        pen.ellipse(0.34, cy + 0.2, 0.07, 0.07, fur)
        pen.ellipse(0.35, cy + 0.21, 0.04, 0.04, (240, 210, 70, 255), outline=False)
        pen.ellipse(0.36, cy + 0.21, 0.02, 0.02, EYE, outline=False)
        pen.capsule(0.3, cy - 0.04, 0.5, cy - 0.04, 0.016, dark)
    splash = getattr(p, "splash", 0)
    if splash:
        for k in range(4 if splash == 1 else 6):
            x = -0.1 + 0.18 * k
            pen.ellipse(x, 0.05 + 0.12 * (k % 2) + 0.05 * (splash - 1), 0.04, 0.05, SPLASH, outline=False)
        pen.ellipse(0.2, 0.02, 0.4, 0.04, SPLASH, outline=False)
    if getattr(p, "clip", False):  # sous l'eau : rien sous la ligne de sol
        oy = pen.origin[1]
        pen.draw.rectangle([0, oy + 1, 10000, 10000], fill=(0, 0, 0, 0))


# --- Planches -----------------------------------------------------------------------------------


def kind_functions(kind):
    if kind == "beast":
        return draw_beast, beast_poses
    if kind == "bird":
        return draw_bird, bird_poses
    if kind == "owl":
        return draw_owl, bird_poses
    return draw_frog, frog_poses


def animations_of(species):
    """Liste (nom, réglages, nombre d'images) des animations de l'espèce, comme build_sheet les veut."""
    spec = SPECIES[species]
    result = []
    for name in spec["anims"]:
        count, ips, loops, hits = ANIMS[name]
        if spec["kind"] in ("bird", "frog") and name in HOPPERS:
            count = 4
        if name == "fuite" and spec.get("loop_fuite"):
            loops = True
        settings = {"ips": ips, "boucle": loops}
        if hits:
            settings["coup"] = list(hits)
        result.append((name, settings, count))
    return result


def make_species(species, out_dir=None, tres_dir=None):
    spec = SPECIES[species]
    draw_fn, poses_fn = kind_functions(spec["kind"])
    out_dir = out_dir or os.path.join(FAUNA_DIR, species)
    look = spec["look"]

    def poses(anim, count):
        return poses_fn(species, anim, count) if poses_fn is not bird_poses else bird_poses(species, anim, count)

    def grounded(pen, pose, look_):
        """Rien ne passe sous le sol : les pieds s'arrêtent à l'ancre, la hauteur au repos reste juste."""
        draw_fn(pen, pose, look_)
        pen.draw.rectangle([0, pen.origin[1] + 1, 10000, 10000], fill=(0, 0, 0, 0))

    sheet, meta = gp.build_sheet(grounded, poses, animations_of(species), look, spec["height"])
    # Les très petites bêtes (grenouille, merle) perdent des pixels à l'arrondi : une 2e passe
    # corrige la hauteur au repos mesurée (ancre − haut de la silhouette) jusqu'à 96 px par mètre.
    want = spec["height"] * 96.0
    for _ in range(3):
        x, y, w, h, ax, ay = meta["animations"]["repos"]["images"][0]
        top = sheet.crop((x, y, x + w, y + h)).getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()[1]
        measured = ay - top
        if abs(measured - want) <= 0.03 * want:
            break
        spec_height = spec["height"] * want / measured
        sheet, meta = gp.build_sheet(grounded, poses, animations_of(species), look, spec_height)
        spec = dict(spec, height=spec["height"])
    meta["format"] = gp.FORMAT_NOTE
    meta["direction"] = "right"
    gp.write_sheet(out_dir, species, sheet, meta)
    write_visual(species, spec, tres_dir or VISUALS_DIR)


def write_visual(species, spec, folder):
    os.makedirs(os.path.join(ROOT, folder), exist_ok=True)
    path = os.path.join(ROOT, folder, species + ".tres")
    base = "res://assets/fauna/%s/%s" % (species, species)
    text = "\n".join([
        '[gd_resource type="Resource" script_class="SkinData" format=3]',
        "",
        '[ext_resource type="Script" path="res://src/visuals/skin_data.gd" id="1_skin"]',
        '[ext_resource type="Texture2D" path="%s.png" id="2_sheet"]' % base,
        '[ext_resource type="JSON" path="%s.json" id="3_frames"]' % base,
        "",
        "[resource]",
        'script = ExtResource("1_skin")',
        'id = &"%s"' % species,
        'display_name = "%s"' % spec["name"],
        'sprite_sheet = ExtResource("2_sheet")',
        'frames_json = ExtResource("3_frames")',
        "height_m = %s" % repr(float(spec["height"])),
        "",
    ])
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    print("visuel %s" % os.path.relpath(path, ROOT))


def make_all(names=None):
    for species in names or SPECIES:
        if species not in SPECIES:
            raise SystemExit("espèce inconnue : %s (%s)" % (species, ", ".join(SPECIES)))
        make_species(species)


def preview(species, scale=2):
    """Planche de contrôle : chaque animation sur une ligne, images côte à côte à leur échelle
    relative (ancre sur la ligne de sol), x2, sur fond sombre."""
    from PIL import Image, ImageDraw

    out_dir = os.path.join(ROOT, "build", "e5")
    os.makedirs(out_dir, exist_ok=True)
    import json

    base = os.path.join(FAUNA_DIR, species, species)
    meta = json.load(open(base + ".json", encoding="utf-8"))
    sheet = Image.open(base + ".png").convert("RGBA")
    rows = []
    for name, anim in meta["animations"].items():
        frames = anim["images"]
        height = max(f[5] + 6 for f in frames)
        rows.append((name, frames, height))
    width = max(sum(f[2] + 14 for f in frames) for _, frames, _ in rows) * scale + 120
    total = sum(h * scale + 14 for _, _, h in rows)
    canvas = Image.new("RGBA", (width, total), (58, 66, 48, 255))
    draw = ImageDraw.Draw(canvas)
    y = 0
    for name, frames, height in rows:
        x = 100
        draw.text((4, y + 4), name, fill=(255, 255, 255, 255))
        ground = y + height * scale
        draw.line([(0, ground), (width, ground)], fill=(255, 255, 255, 60))
        for fx, fy, fw, fh, ax, ay in frames:
            part = sheet.crop((fx, fy, fx + fw, fy + fh)).resize((fw * scale, fh * scale), Image.NEAREST)
            canvas.alpha_composite(part, (x, int(ground - ay * scale)))
            x += (fw + 14) * scale
        y += height * scale + 14
    path = os.path.join(out_dir, "preview_%s.png" % species)
    canvas.save(path)
    print(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    gen = sub.add_parser("gen", help="les planches de remplacement")
    gen.add_argument("species", nargs="*")
    view = sub.add_parser("preview", help="planche de contrôle d'une espèce")
    view.add_argument("species")
    args = parser.parse_args()
    if args.command == "gen":
        make_all(args.species)
    else:
        preview(args.species)


if __name__ == "__main__":
    main()
