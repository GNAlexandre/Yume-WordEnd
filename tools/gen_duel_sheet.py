#!/usr/bin/env python3
"""(E8b) Planche de remplacement de `willem/willem_duel` : Willem et le Carillon de série Percival
(le duel du jour 8, l'entraînement avec Seniorious du jour 11 ; docs/lore/ACTE1.md 3.3 et 3.4 ;
commandée au cahier n° 6, C.10). Appelé par `python3 tools/gen_placeholders.py duel`.

Tirée au pixel près de `willem_home` (trois vues : profil, `_front`, `_back`), à laquelle on ajoute
une longue épée de fées dessinée ici (plaques de métal gris acier assemblées, quelques runes
éteintes, garde courte, poignée sombre) :
- `repos` (2 à 2), `marche` (6 à 10), `parle` (2 à 6) : les images de `willem_home`, l'épée posée sur
  l'épaule, la pointe vers l'arrière ;
- `attaque` (4 à 14, non bouclée, `coup` [2]) : la déviation qui retourne l'élan, sur le corps de la
  première image de repos : 0 garde basse, 1 la lame croise, 2 le geste (la lame balaie vers
  l'extérieur, un trait clair), 3 retour au calme ;
- `pare` (2 à 2, boucle) : garde haute, la lame en travers.
Écrit aussi src/games/fx/seniorious.png : Seniorious seule (l'épée arrachée de l'entraînement du
jour 11), une image d'effet comme celles de src/combat/fx/.
Mêmes animations, cadences, « coup » dans les trois vues ; la hauteur debout (de l'ancre au haut de
la 1re image de repos) reste celle de `willem_home` (168 px : 1,75 m à 96 px par mètre). Le résultat
est déterministe ; les fichiers générés sont versionnés. À remplacer par la vraie planche (C.10).
"""

import json
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE_DIR = os.path.join(ROOT, "assets", "characters", "willem")
BASE_ID = "willem_home"
OUT_ID = "willem_duel"
VIEWS = ("", "_front", "_back")
SPACING = 2
# Marge ajoutée à gauche et à droite de chaque image (la lame dépasse du corps) ; jamais en haut :
# la hauteur debout du repos donne l'échelle (SheetLoader.pixel_size).
PAD = 104
ANIMS = [
    ("repos", {"ips": 2, "boucle": True}),
    ("marche", {"ips": 10, "boucle": True}),
    ("parle", {"ips": 6, "boucle": True}),
    ("attaque", {"ips": 14, "boucle": False, "coup": [2]}),
    ("pare", {"ips": 2, "boucle": True}),
]
OUTLINE = (34, 38, 46, 255)
STEEL = (146, 154, 166, 255)
STEEL_LIGHT = (205, 211, 220, 255)
STEEL_DARK = (98, 104, 116, 255)
RUNE = (78, 84, 98, 255)
GRIP = (64, 44, 34, 255)
GUARD = (120, 112, 96, 255)
TRAIL = (255, 250, 236, 200)

# Poses de l'épée par vue, relatives à l'ancre (dx, dy : px ; dy < 0 vers le haut) : poignée,
# angle de la lame (degrés, 0 = vers la droite de l'image, 90 = vers le bas), longueur, devant le
# corps ou derrière.
SHOULDER = {
    "": ((8, -98), 200.0, 104, False),
    "_front": ((-17, -100), 222.0, 92, False),
    "_back": ((15, -100), 318.0, 92, True),
}
STRIKE = {
    "": [((12, -64), 18.0, 100), ((12, -78), 300.0, 100), ((6, -74), 168.0, 100), ((12, -60), 62.0, 92)],
    "_front": [((14, -62), 150.0, 92), ((12, -76), 235.0, 92), ((18, -74), 345.0, 98), ((16, -60), 75.0, 84)],
    "_back": [((-14, -62), 30.0, 92), ((-12, -76), 305.0, 92), ((-18, -74), 195.0, 98), ((-16, -60), 105.0, 84)],
}
GUARD_POSE = {
    "": ((16, -88), 196.0, 104),
    "_front": ((26, -96), 182.0, 104),
    "_back": ((-26, -96), 358.0, 104),
}


def read(view):
    base = os.path.join(BASE_DIR, BASE_ID + view)
    with open(base + ".json", encoding="utf-8") as handle:
        meta = json.load(handle)
    return meta, Image.open(base + ".png").convert("RGBA")


def crop(image, entry):
    x, y, w, h = entry[:4]
    return image.crop((x, y, x + w, y + h))


def blade(layer, hilt, angle_deg, length, glint=False):
    """Dessine le Carillon : poignée et pommeau derrière la main, garde courte, lame de plaques."""
    draw = ImageDraw.Draw(layer)
    a = math.radians(angle_deg)
    d = (math.cos(a), math.sin(a))
    n = (-d[1], d[0])
    hx, hy = hilt

    def at(t, s=0.0):
        return (hx + d[0] * t + n[0] * s, hy + d[1] * t + n[1] * s)

    # Poignée (derrière la main) et pommeau.
    draw.line([at(-14), at(0)], fill=OUTLINE, width=5)
    draw.line([at(-13), at(-1)], fill=GRIP, width=3)
    draw.ellipse([at(-16)[0] - 2.5, at(-16)[1] - 2.5, at(-16)[0] + 2.5, at(-16)[1] + 2.5], fill=GUARD,
                 outline=OUTLINE)
    # Lame : plaques assemblées, un fil clair, une pointe.
    tip = length
    body = [at(2, -3.2), at(tip - 10, -3.2), at(tip, 0), at(tip - 10, 3.2), at(2, 3.2)]
    draw.polygon(body, fill=STEEL, outline=OUTLINE)
    draw.line([at(4, -1.2), at(tip - 9, -1.2)], fill=STEEL_LIGHT, width=1)
    draw.line([at(4, 1.6), at(tip - 9, 1.6)], fill=STEEL_DARK, width=1)
    for t in range(18, int(tip) - 12, 17):
        draw.line([at(t, -3), at(t, 3)], fill=OUTLINE, width=1)
        # Runes éteintes, une sur deux plaques.
        if (t // 17) % 2 == 0:
            rx, ry = at(t + 8, 0.2)
            draw.point([(rx, ry), (rx + d[0], ry + d[1])], fill=RUNE)
    # Garde courte.
    draw.line([at(1, -7), at(1, 7)], fill=OUTLINE, width=4)
    draw.line([at(1, -6), at(1, 6)], fill=GUARD, width=2)
    if glint:
        # Le geste : un trait clair le long de la lame (la déviation).
        draw.line([at(10, -7), at(tip + 6, -9)], fill=TRAIL, width=2)


def seniorious_blade(path):
    """(E8b) Seniorious seule, pointe à droite, 1,3 m (125 px à 96 px par mètre) : l'épée arrachée
    par la troisième Grue, qui tourne en l'air et plonge dans le marais (src/games/
    seniorious_training.gd). Une lame faite de plaques rapiécées, gris argent bleuté, ses fissures
    d'un bleu clair (la lumière du venenum), garde sombre."""
    image = Image.new("RGBA", (132, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    y = 12
    # Poignée et pommeau.
    draw.rectangle([3, y - 2, 18, y + 2], fill=OUTLINE)
    draw.rectangle([4, y - 1, 17, y + 1], fill=(52, 46, 62, 255))
    draw.ellipse([0, y - 3, 6, y + 3], fill=(88, 120, 170, 255), outline=OUTLINE)
    # Garde.
    draw.rectangle([18, y - 8, 22, y + 8], fill=OUTLINE)
    draw.rectangle([19, y - 7, 21, y + 7], fill=(96, 104, 128, 255))
    # Lame : plaques, fil clair, fissures lumineuses.
    body = [(22, y - 4), (118, y - 4), (130, y), (118, y + 4), (22, y + 4)]
    draw.polygon(body, fill=(170, 184, 206, 255), outline=OUTLINE)
    draw.line([(24, y - 2), (118, y - 2)], fill=(228, 236, 248, 255), width=1)
    draw.line([(24, y + 2), (118, y + 2)], fill=(118, 130, 156, 255), width=1)
    for x in range(36, 116, 13):
        draw.line([(x, y - 3), (x + 2, y + 3)], fill=OUTLINE, width=1)
        draw.line([(x + 5, y - 1), (x + 8, y + 1)], fill=(120, 214, 255, 255), width=1)
    image.save(path, optimize=True)
    print("lame %s : %d x %d" % (os.path.relpath(path, ROOT), image.width, image.height))


def armed_frame(body, anchor, pose, behind):
    """Une image : le corps élargi de PAD de chaque côté, l'épée devant ou derrière."""
    w, h = body.size
    canvas = Image.new("RGBA", (w + 2 * PAD, h), (0, 0, 0, 0))
    sword = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    (dx, dy), angle, length = pose[:3]
    glint = len(pose) > 3 and pose[3]
    blade(sword, (PAD + anchor[0] + dx, anchor[1] + dy), angle, length, glint)
    if behind:
        canvas.alpha_composite(sword)
        canvas.alpha_composite(body, (PAD, 0))
    else:
        canvas.alpha_composite(body, (PAD, 0))
        canvas.alpha_composite(sword)
    # Rogne les marges vides à gauche et à droite (jamais en haut ni en bas).
    box = canvas.getbbox() or (0, 0, canvas.width, h)
    left, right = box[0], box[2]
    return canvas.crop((left, 0, right, h)), (PAD + anchor[0] - left, anchor[1])


def view_frames(view):
    meta, image = read(view)
    anims = meta["animations"]
    frames = {}
    hilt, angle, length, front = SHOULDER[view]
    for name in ("repos", "marche", "parle"):
        frames[name] = []
        for entry in anims[name]["images"]:
            frames[name].append(armed_frame(crop(image, entry), entry[4:6], (hilt, angle, length), not front))
    still = anims["repos"]["images"][0]
    body = crop(image, still)
    frames["attaque"] = [
        armed_frame(body, still[4:6], (pose[0], pose[1], pose[2], index == 2), False)
        for index, pose in enumerate(STRIKE[view])
    ]
    guard = GUARD_POSE[view]
    frames["pare"] = []
    for lift in (0, 1):
        pose = ((guard[0][0], guard[0][1] - lift), guard[1], guard[2])
        frames["pare"].append(armed_frame(body, still[4:6], pose, False))
    return frames


def pack(frames):
    """Planche : une rangée par animation ; JSON au format de l'easter egg."""
    rows = []
    width = 0
    y = SPACING
    for name, _ in ANIMS:
        row = frames[name]
        row_w = SPACING + sum(f.width + SPACING for f, _ in row)
        row_h = max(f.height for f, _ in row)
        rows.append((name, row, y))
        width = max(width, row_w)
        y += row_h + SPACING
    sheet = Image.new("RGBA", (width, y), (0, 0, 0, 0))
    animations = {}
    for (name, settings), (_, row, top) in zip(ANIMS, rows):
        x = SPACING
        images = []
        for frame, anchor in row:
            sheet.alpha_composite(frame, (x, top))
            images.append([x, top, frame.width, frame.height, int(anchor[0]), int(anchor[1])])
            x += frame.width + SPACING
        entry = dict(settings)
        entry["images"] = images
        animations[name] = entry
    meta = {
        "version": 1,
        "echelle": 1,
        "planche": [sheet.width, sheet.height],
        "direction": "right",
        "format": "images: [x,y,width,height,anchor_x,anchor_y] in atlas pixels",
        "status": "placeholder (E8b) : willem_home et une épée dessinée par tools/gen_duel_sheet.py ; "
                  "la vraie planche est commandée au cahier n° 6, C.10",
        "animations": animations,
    }
    return sheet, meta


def make_all(out_dir=None):
    out_dir = out_dir or BASE_DIR
    os.makedirs(out_dir, exist_ok=True)
    for view in VIEWS:
        sheet, meta = pack(view_frames(view))
        png = os.path.join(out_dir, OUT_ID + view + ".png")
        sheet.save(png, optimize=True)
        with open(os.path.join(out_dir, OUT_ID + view + ".json"), "w", encoding="utf-8") as handle:
            handle.write(json.dumps(meta, ensure_ascii=False, separators=(",", ":")) + "\n")
        print("planche %s : %d x %d" % (os.path.relpath(png, ROOT), sheet.width, sheet.height))
    fx_dir = os.path.join(ROOT, "src", "games", "fx")
    os.makedirs(fx_dir, exist_ok=True)
    seniorious_blade(os.path.join(fx_dir, "seniorious.png"))


if __name__ == "__main__":
    make_all()
