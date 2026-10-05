#!/usr/bin/env python3
"""Placeholders P0 : planches de sprites au format de l'easter egg, et textures simples (Pillow).

Les planches produites ont exactement le format de assets/characters/chtholly/chtholly.json :
mêmes 7 animations et mêmes nombres d'images que Chtholly (repos 2, marche 6, course 5,
attaque 4, charge 4, degats 1, mort 1), mêmes cadences, mêmes champs "coup" (attaque : 1, 2, 3)
et "onde" (charge : 3), images [x, y, largeur, hauteur, ancreX, ancreY] avec l'ancre au milieu
du corps, au niveau des pieds. Échelle : 0,0104 m par pixel de planche (Chtholly : 144 px
pour 1,5 m), donc un personnage de 1,6 m mesure 154 px debout.

Usage (Python 3.9+, pip install Pillow) :

    # un skin : assets/characters/<id>/<id>.png + .json (+ data/skins/<id>.tres avec --tres)
    python3 tools/gen_placeholders.py skin <id> --name "Nom" --color "#8e6cc9" --height 1.6 --tres
    # les trois PNJ du village (bibliothecaire, forgeron, enfant), avec leurs .tres
    python3 tools/gen_placeholders.py npcs
    # damier (sol de la greybox)
    python3 tools/gen_placeholders.py checker assets/textures/checker.png

Le résultat est déterministe (aucun hasard) ; les fichiers générés sont versionnés.
"""

import argparse
import json
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
METERS_PER_PIXEL = 1.5 / 144.0
SUPERSAMPLE = 4
SPACING = 2
FORMAT_NOTE = "images : [x, y, largeur, hauteur, ancre x, ancre y] en px de la planche"

# Nom, cadence, boucle, nombre d'images et repères de jeu : copie de chtholly.json.
ANIMATIONS = [
    ("repos", {"ips": 2, "boucle": True}, 2),
    ("marche", {"ips": 10, "boucle": True}, 6),
    ("course", {"ips": 14, "boucle": True}, 5),
    ("attaque", {"ips": 14, "boucle": False, "coup": [1, 2, 3]}, 4),
    ("charge", {"ips": 10, "boucle": False, "onde": 3}, 4),
    ("degats", {"ips": 1, "boucle": False}, 1),
    ("mort", {"ips": 1, "boucle": False}, 1),
]

NPCS = [
    ("bibliothecaire", "Bibliothécaire", "#8e6cc9", 1.6),
    ("forgeron", "Forgeron", "#c8643c", 1.75),
    ("enfant", "Enfant", "#4fb0a5", 1.1),
]

SKIN_TONE = (255, 222, 196, 255)
HAIR = (92, 64, 51, 255)
WEAPON = (190, 205, 220, 255)
GLOW = (143, 208, 255, 160)


def hex_color(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4)) + (255,)


def darker(color, factor=0.6):
    return tuple(int(c * factor) for c in color[:3]) + (255,)


class Pose:
    """Pose paramétrique d'une silhouette chibi ; unités : hauteur debout = 1, y vers le haut."""

    def __init__(self, bob=0.0, lean=0.0, leg=0.0, arm=0.0, weapon=None, glow=0.0, tilt=0.0,
                 lying=False, eyes_closed=False):
        self.bob = bob
        self.lean = lean
        self.leg = leg
        self.arm = arm
        self.weapon = weapon
        self.glow = glow
        self.tilt = tilt
        self.lying = lying
        self.eyes_closed = eyes_closed


def poses(anim, count):
    result = []
    for i in range(count):
        t = i / float(count)
        if anim == "repos":
            result.append(Pose(bob=0.012 * i))
        elif anim == "marche":
            result.append(Pose(bob=0.015 * abs(math.sin(t * 2 * math.pi)),
                               leg=0.35 * math.sin(t * 2 * math.pi), arm=0.4 * math.sin(t * 2 * math.pi)))
        elif anim == "course":
            result.append(Pose(bob=0.03 * abs(math.sin(t * 2 * math.pi)), lean=0.18,
                               leg=0.6 * math.sin(t * 2 * math.pi), arm=0.8 * math.sin(t * 2 * math.pi)))
        elif anim == "attaque":
            result.append(Pose(lean=0.08, weapon=[-0.9, 0.0, 0.7, 1.2][i]))
        elif anim == "charge":
            result.append(Pose(arm=-1.0, glow=[0.15, 0.3, 0.45, 0.75][i], weapon=1.4 if i == 3 else None))
        elif anim == "degats":
            result.append(Pose(tilt=0.25, eyes_closed=True))
        else:
            result.append(Pose(lying=True, eyes_closed=True))
    return result


def draw_frame(pose, height_px, color):
    """Image RGBA recadrée et ancre (x, y) au milieu des pieds."""
    s = SUPERSAMPLE
    unit = height_px * s
    canvas_w, canvas_h = int(unit * 3), int(unit * 1.6)
    ax, ay = canvas_w // 2, int(unit * 1.4)
    img = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    outline = darker(color)
    line = max(2, int(unit * 0.02))

    def pt(x, y):
        """Point en unités (x vers la droite, y vers le haut) → pixels, avec inclinaison."""
        if pose.lying:
            x, y = y * 0.95 - 0.45, x * 0.6 + 0.12
        elif y > 0.3:
            y += pose.bob  # seul le haut du corps respire : les pieds restent au sol
        angle = pose.tilt + (-pose.lean if not pose.lying else 0.0)
        rx = x * math.cos(angle) - y * math.sin(angle)
        ry = x * math.sin(angle) + y * math.cos(angle)
        return (ax + rx * unit, ay - ry * unit)

    def ellipse(cx, cy, rx, ry, fill):
        x0, y0 = pt(cx - rx, cy + ry)
        x1, y1 = pt(cx + rx, cy - ry)
        draw.ellipse([min(x0, x1), min(y0, y1), max(x0, x1), max(y0, y1)], fill=fill, outline=outline, width=line)

    def limb(x0, y0, x1, y1, width, fill):
        draw.line([pt(x0, y0), pt(x1, y1)], fill=fill, width=int(width * unit))

    if pose.glow > 0.0:
        r = 0.18 + 0.35 * pose.glow
        cx, cy = pt(0.32, 0.55)
        draw.ellipse([cx - r * unit, cy - r * unit, cx + r * unit, cy + r * unit], fill=GLOW)
    # Jambes
    limb(-0.07, 0.30, -0.07 - 0.12 * pose.leg, 0.02, 0.07, outline)
    limb(0.07, 0.30, 0.07 + 0.12 * pose.leg, 0.02, 0.07, outline)
    # Corps (tunique)
    points = [pt(-0.17, 0.28), pt(0.17, 0.28), pt(0.12, 0.62), pt(-0.12, 0.62)]
    draw.polygon(points, fill=color, outline=outline, width=line)
    # Bras
    if pose.weapon is not None:
        angle = pose.weapon
        hx, hy = 0.05 + 0.3 * math.cos(angle), 0.52 + 0.3 * math.sin(angle)
        limb(0.05, 0.56, hx, hy, 0.055, SKIN_TONE)
        limb(hx, hy, hx + 0.45 * math.cos(angle), hy + 0.45 * math.sin(angle), 0.045, WEAPON)
    else:
        swing = pose.arm
        limb(0.1, 0.56, 0.2 + 0.1 * swing, 0.36 - 0.25 * min(0.0, swing), 0.055, SKIN_TONE)
    limb(-0.1, 0.56, -0.2 - 0.1 * pose.arm, 0.36 - 0.25 * min(0.0, -pose.arm), 0.055, SKIN_TONE)
    # Tête chibi, cheveux, yeux (regard vers la droite)
    ellipse(0.0, 0.8, 0.2, 0.2, SKIN_TONE)
    hair = [pt(-0.21, 0.82), pt(-0.12, 0.99), pt(0.12, 1.0), pt(0.21, 0.86), pt(0.05, 0.9)]
    draw.polygon(hair, fill=HAIR)
    for ex in (0.05, 0.13):
        if pose.eyes_closed:
            limb(ex - 0.025, 0.78, ex + 0.025, 0.78, 0.015, outline)
        else:
            ellipse(ex, 0.78, 0.018, 0.03, outline)
    small = img.resize((canvas_w // s, canvas_h // s), Image.LANCZOS)
    anchor = (ax // s, ay // s)
    box = small.getbbox()
    # Le cadre englobe toujours l'ancre (comme les planches de l'easter egg).
    box = (min(box[0], anchor[0]), min(box[1], anchor[1]), max(box[2], anchor[0]), max(box[3], anchor[1]))
    crop = small.crop(box)
    return crop, (anchor[0] - box[0], anchor[1] - box[1])


def build_sheet(height_m, color):
    height_px = round(height_m / METERS_PER_PIXEL)
    rows = []
    for name, settings, count in ANIMATIONS:
        rows.append((name, settings, [draw_frame(p, height_px, color) for p in poses(name, count)]))
    width = max(sum(img.width + SPACING for img, _ in frames) for _, _, frames in rows)
    total_h = sum(max(img.height for img, _ in frames) + SPACING for _, _, frames in rows)
    sheet = Image.new("RGBA", (width, total_h), (0, 0, 0, 0))
    animations = {}
    y = 0
    for name, settings, frames in rows:
        x = 0
        images = []
        for img, (anchor_x, anchor_y) in frames:
            sheet.paste(img, (x, y))
            images.append([x, y, img.width, img.height, anchor_x, anchor_y])
            x += img.width + SPACING
        entry = {"ips": settings["ips"], "boucle": settings["boucle"]}
        for key in ("coup", "onde"):
            if key in settings:
                entry[key] = settings[key]
        entry["images"] = images
        animations[name] = entry
        y += max(img.height for img, _ in frames) + SPACING
    meta = {"version": 1, "echelle": 2, "planche": [sheet.width, sheet.height], "format": FORMAT_NOTE,
            "animations": animations}
    return sheet, meta


def write_tres(skin_id, display_name, height_m):
    path = os.path.join(ROOT, "data", "skins", skin_id + ".tres")
    base = "res://assets/characters/%s/%s" % (skin_id, skin_id)
    text = "\n".join([
        '[gd_resource type="Resource" script_class="SkinData" format=3]',
        "",
        '[ext_resource type="Script" path="res://src/visuals/skin_data.gd" id="1_skin"]',
        '[ext_resource type="Texture2D" path="%s.png" id="2_sheet"]' % base,
        '[ext_resource type="JSON" path="%s.json" id="3_frames"]' % base,
        "",
        "[resource]",
        'script = ExtResource("1_skin")',
        'id = &"%s"' % skin_id,
        'display_name = "%s"' % display_name,
        'sprite_sheet = ExtResource("2_sheet")',
        'frames_json = ExtResource("3_frames")',
        "height_m = %s" % repr(float(height_m)),
        "",
    ])
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    return path


def make_skin(skin_id, display_name, color, height_m, with_tres):
    out_dir = os.path.join(ROOT, "assets", "characters", skin_id)
    os.makedirs(out_dir, exist_ok=True)
    sheet, meta = build_sheet(height_m, hex_color(color))
    png = os.path.join(out_dir, skin_id + ".png")
    sheet.save(png, optimize=True)
    with open(os.path.join(out_dir, skin_id + ".json"), "w", encoding="utf-8") as handle:
        handle.write(json.dumps(meta, ensure_ascii=False, separators=(",", ":")) + "\n")
    print("planche %s : %d x %d" % (os.path.relpath(png, ROOT), sheet.width, sheet.height))
    if with_tres:
        print("skin %s" % os.path.relpath(write_tres(skin_id, display_name, height_m), ROOT))


def make_checker(path, size, cells, colors):
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    step = size // cells
    for cy in range(cells):
        for cx in range(cells):
            draw.rectangle([cx * step, cy * step, (cx + 1) * step - 1, (cy + 1) * step - 1],
                           fill=hex_color(colors[(cx + cy) % 2])[:3])
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    img.save(path, optimize=True)
    print("damier %s" % path)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    skin = sub.add_parser("skin", help="une planche de remplacement")
    skin.add_argument("skin_id")
    skin.add_argument("--name", required=True)
    skin.add_argument("--color", default="#7f8fd6")
    skin.add_argument("--height", type=float, default=1.5, help="taille debout en mètres")
    skin.add_argument("--tres", action="store_true", help="écrit aussi data/skins/<id>.tres")
    sub.add_parser("npcs", help="les trois PNJ du village, avec leurs .tres")
    checker = sub.add_parser("checker", help="damier PNG")
    checker.add_argument("path")
    checker.add_argument("--size", type=int, default=64)
    checker.add_argument("--cells", type=int, default=2)
    checker.add_argument("--colors", nargs=2, default=["#8ccf6e", "#7cc061"])
    args = parser.parse_args()
    if args.command == "skin":
        make_skin(args.skin_id, args.name, args.color, args.height, args.tres)
    elif args.command == "npcs":
        for skin_id, name, color, height in NPCS:
            make_skin(skin_id, name, color, height, True)
    else:
        make_checker(args.path, args.size, args.cells, args.colors)


if __name__ == "__main__":
    main()
