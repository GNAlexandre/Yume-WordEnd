#!/usr/bin/env python3
"""Planches de personnages HD-2D (docs/ASSETS_HD2D.md section 3) : vérification, ancres, contrôle.

Une planche par vue : `<id>.png` + `.json` (profil, tourné vers la droite ; le jeu le retourne pour
la gauche), et, facultatives, `<id>_front` (face) et `<id>_back` (dos). Le JSON est celui de
l'easter egg, repris tel quel : { "planche": [l, h], "animations": { nom: { "ips", "boucle",
"images": [[x, y, l, h, ancre x, ancre y], …], "coup"?, "onde"? } } }. Les planches à vérifier
sont listées dans tools/hd2d_manifest.json (« sheets »).

Usage (Python 3.9+, Pillow) :

    python3 tools/hd2d_sheets.py check                  # planches du manifeste
    python3 tools/hd2d_sheets.py anchors <json>…        # ancres recalculées (aperçu des écarts)
    python3 tools/hd2d_sheets.py anchors <json>… --write [--feet dark|alpha] [--no-axis] [--torso]
    python3 tools/hd2d_sheets.py alias parle repos <json>…   # parle joue les images de repos
    python3 tools/hd2d_sheets.py trim repos,marche,parle <json>…  # retire les autres animations
    python3 tools/hd2d_sheets.py strip <out.png> <json>… [--anims repos,parle] [--scale 1]

Manifeste (« sheets ») : id, dir, table (fairy : fée jouable ou soldate, 3.1 ; npc : PNJ, 3.2 ;
timere, 3.3), height_m, views ; facultatifs : feet (alpha), axis (false :
pieds cherchés sur toute la largeur), torso (vues recalées sur le buste), aliases (vue →
{animation : animation dont elle joue les images}, à faire redessiner).

Règles vérifiées (check). Problèmes (code 1) : PNG RGBA à alpha net, taille = « planche »,
animations et cadences du tableau du cahier, images dans la planche et non vides, ancre dans
l'image (± 2 px), hauteur debout de la 1re image de « repos » du profil (de l'ancre au haut de la
silhouette) = taille × 96 px à 6 % près, même échelle que « repos » (12 %) pour les animations
debout que le jeu joue (USED), mêmes animations, nombres d'images, cadences, « coup » et « onde »
dans toutes les vues. Remarques (images à faire refaire, sans bloquer) : face ou dos dessinés plus
petits ou plus grands que le profil (le jeu garde la hauteur debout du profil), échelle des
animations que le jeu ne joue pas, « parle » absente ou remplacée.

Ancres (anchors) : le point au sol entre les deux pieds. « dark » (personnages chaussés de
sombre) : les pixels sombres épais du bas de la silhouette (l'ouverture morphologique écarte les
contours fins de l'épée) ; « alpha » (Timere, pattes, chaussures claires) : les pixels les plus
bas de la silhouette. x = milieu des pieds dans la bande basse, y = sous le pied le plus bas ;
pour les images debout, les pieds sont cherchés près de l'axe du corps (une épée posée au sol, une
queue ou un plateau à côté ne comptent pas). Images immobiles (repos, parle) : x recalé sur la 1re
image de « repos » par superposition des jambes (ou du buste avec --torso), y sous leurs pieds.
« mort » (allongé) : milieu de la masse sombre. Le résultat se juge sur la planche de contrôle
(strip : ligne de sol, axe de l'ancre, hauteur debout du repos en orange, images superposées).
"""

import argparse
import json
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "hd2d_manifest.json")
PX_PER_M = 96
VIEWS = ("", "_front", "_back")
# Tableaux du cahier des charges : nom → (images, ips, boucle, coup, onde). Pour les PNJ, « parle »
# a 2 à 4 images (liste des nombres admis) et les animations en plus sont permises.
TABLES = {
    "fairy": {
        "repos": (2, 2, True, None, None),
        "marche": (6, 10, True, None, None),
        "course": (5, 14, True, None, None),
        "attaque": (4, 14, False, [1, 2, 3], None),
        "charge": (4, 10, False, None, 3),
        "degats": (1, 1, False, None, None),
        "mort": (1, 1, False, None, None),
    },
    "npc": {
        "repos": (2, 2, True, None, None),
        "marche": (6, 10, True, None, None),
        "parle": ([2, 3, 4], 6, True, None, None),
    },
    "timere": {
        "repos": (5, 6, True, None, None),
        "marche": (4, 7, True, None, None),
        "course": (6, 12, True, None, None),
        "fouet": (4, 8, False, [1, 2], None),
        "morsure": (4, 8, False, [1, 2], None),
        "degats": (5, 12, False, None, None),
        "mort": (6, 8, False, None, None),
    },
}
# Animations debout (même échelle que « repos ») ; « course » peut être plus basse, pas plus haute.
UPRIGHT = ("repos", "marche", "parle")
# Animations debout que le jeu joue, par tableau : une échelle fausse y bloque (ailleurs : une
# remarque). Les PNJ ne marchent pas ; le Timere, sans pieds ni tête fixes, n'est pas mesuré.
USED = {"fairy": ("repos", "marche", "parle"), "npc": ("repos", "parle"), "timere": ()}
# Une ancre peut dépasser du cadre de l'image de quelques px (pied coupé au ras du cadre).
ANCHOR_MARGIN = 2
STANDING_TOLERANCE = 0.06
SCALE_TOLERANCE = 0.12
# Ancres : bande basse où l'on cherche les deux pieds (px au-dessus du pied le plus bas).
FEET_BAND = {"dark": 18, "alpha": 8}
# Taille de l'ouverture morphologique (px) : « dark » écarte les contours sombres de l'épée (3 px
# au plus) et garde les bottes ; « alpha » écarte les pointes fines.
OPENING = {"dark": 5, "alpha": 3}
DARK_LUMA = 70
LYING = ("mort",)
# Animations où les pieds ne bougent pas : leurs images sont recalées sur la 1re de « repos ».
STILL = ("repos", "parle")
# Axe du corps : rangées de la silhouette (part de sa hauteur, depuis le haut) dont on prend la
# médiane ; pieds cherchés à FEET_WINDOW × hauteur de part et d'autre.
AXIS_BAND = (0.15, 0.5)
FEET_WINDOW = 0.22
# Recalage des images immobiles : bas de la silhouette comparé (part de la hauteur debout) et
# décalage cherché (px, en x et en y).
ALIGN_BAND = 0.3
ALIGN_SEARCH = (20, 8)
# Recalage sur le buste (--torso) : rangées comparées (part de la hauteur debout depuis le haut)
# et décalage cherché en x (px).
TORSO_BAND = (0.3, 0.62)
TORSO_SEARCH = 30
# Planche réduite (trim) : espace transparent entre deux rangées (px).
TRIM_GAP = 4


def load_manifest():
    with open(MANIFEST, encoding="utf-8") as handle:
        return json.load(handle)


def read_json(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def write_json(path, data):
    """Réécrit le JSON d'une planche : une image par ligne, comme les planches livrées."""
    lines = ["{"]
    keys = [k for k in data if k != "animations"]
    for key in keys:
        lines.append("  %s: %s," % (json.dumps(key), json.dumps(data[key], ensure_ascii=False)))
    lines.append('  "animations": {')
    names = list(data["animations"])
    for i, name in enumerate(names):
        anim = data["animations"][name]
        lines.append("    %s: {" % json.dumps(name))
        fields = [k for k in anim if k != "images"]
        for key in fields:
            lines.append("      %s: %s," % (json.dumps(key), json.dumps(anim[key])))
        lines.append('      "images": [')
        images = anim["images"]
        for j, image in enumerate(images):
            lines.append("        %s%s" % (json.dumps(image), "," if j < len(images) - 1 else ""))
        lines.append("      ]")
        lines.append("    }%s" % ("," if i < len(names) - 1 else ""))
    lines.append("  }")
    lines.append("}")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def sheet_png(json_path):
    return os.path.splitext(json_path)[0] + ".png"


def crop(image, frame):
    x, y, w, h = [int(v) for v in frame[:4]]
    return image.crop((x, y, x + w, y + h))


def top_of(frame_image):
    """Première rangée opaque d'une image (0 si vide)."""
    box = frame_image.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()
    return box[1] if box else 0


def standing_height(frame_image, frame):
    """Hauteur debout (px) : de l'ancre au haut de la silhouette."""
    return float(frame[5]) - top_of(frame_image)


# --- Ancres --------------------------------------------------------------------------------


def _mask(frame_image, feet):
    alpha = frame_image.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    if feet == "dark":
        luma = frame_image.convert("L").point(lambda v: 255 if v < DARK_LUMA else 0)
        mask = ImageChops.multiply(alpha, luma)
    else:
        mask = alpha
    # Ouverture : les contours fins (lame, bords) disparaissent, les bottes et les pattes restent.
    size = OPENING[feet]
    opened = mask.filter(ImageFilter.MinFilter(size)).filter(ImageFilter.MaxFilter(size))
    return opened if opened.getbbox() else mask


def _rows(mask):
    """Pixels allumés du masque, par rangée : {y: [x…]}."""
    w, h = mask.size
    data = mask.load()
    rows = {}
    for y in range(h):
        xs = [x for x in range(w) if data[x, y]]
        if xs:
            rows[y] = xs
    return rows


def _alpha(frame_image):
    return frame_image.getchannel("A").point(lambda v: 255 if v >= 128 else 0)


def body_axis(frame_image):
    """Axe du corps (x) : médiane des pixels opaques des épaules à la taille (AXIS_BAND de la
    hauteur de la silhouette), où ni l'épée qui pend ni la queue ne pèsent."""
    alpha = _alpha(frame_image)
    box = alpha.getbbox()
    if box is None:
        return frame_image.width / 2.0
    height = box[3] - box[1]
    first = box[1] + int(AXIS_BAND[0] * height)
    last = max(first + 1, box[1] + int(AXIS_BAND[1] * height))
    rows = _rows(alpha.crop((0, first, alpha.width, last)))
    xs = sorted(x for row in rows.values() for x in row)
    return float(xs[len(xs) // 2]) if xs else frame_image.width / 2.0


def compute_anchor(frame_image, feet="dark", lying=False, axis=False):
    """Ancre (x, y) d'une image : entre les pieds, au sol (voir l'en-tête). Avec axis (images
    debout), les pieds sont cherchés à moins de FEET_WINDOW × hauteur de l'axe du corps : une
    épée qui touche le sol à côté, une queue ou un plateau ne les déplacent pas."""
    mask = _mask(frame_image, feet)
    if axis and not lying:
        box = _alpha(frame_image).getbbox()
        if box is not None:
            half = FEET_WINDOW * (box[3] - box[1])
            axis = body_axis(frame_image)
            window = Image.new("L", mask.size, 0)
            window.paste(255, (max(0, int(axis - half)), 0, min(mask.width, int(axis + half) + 1), mask.height))
            inside = ImageChops.multiply(mask, window)
            if inside.getbbox():
                mask = inside
    rows = _rows(mask)
    if not rows:
        w, h = frame_image.size
        return [round(w / 2), h]
    lowest = max(rows)
    if lying:
        xs = [x for xs in rows.values() for x in xs]
        return [round((min(xs) + max(xs) + 1) / 2), lowest + 1]
    band = [x for y, xs in rows.items() if y >= lowest - FEET_BAND[feet] for x in xs]
    return [round((min(band) + max(band) + 1) / 2), lowest + 1]


def align_anchor(ref_image, ref_anchor, frame_image, feet="dark", guess=None):
    """Ancre d'une image immobile (repos, parle) recalée sur l'image de référence : décalage qui
    superpose le mieux le bas de la silhouette (masque des pieds : sombre ou alpha ; ALIGN_BAND
    de la hauteur debout au-dessus de l'ancre, FEET_WINDOW de part et d'autre : jambes, pieds,
    bas de la robe), cherché à ± ALIGN_SEARCH px. Les pieds ne glissent plus d'une image à
    l'autre, même quand le bras, la tête ou l'arme bougent (anchor_sheet ne garde que son x : le
    y est pris sous les pieds de l'image). guess : ancre estimée par les pieds ; la recherche
    reste alors à ± ALIGN_SEARCH[1] px d'elle (sinon un pied se superpose à l'autre)."""
    box = _alpha(ref_image).getbbox()
    if box is None:
        return None
    ref = _mask(ref_image, feet)
    ax, ay = int(round(ref_anchor[0])), int(round(ref_anchor[1]))
    top = max(0, int(ay - ALIGN_BAND * (ay - box[1])))
    # Autour des pieds seulement : une épée ou une queue qui bouge à côté ne compte pas.
    half = int(FEET_WINDOW * (ay - box[1]))
    region = (max(0, ax - half), top, min(ref.width, ax + half + 1), min(ref.height, ay + 2))
    target = ref.crop(region)
    frame = _mask(frame_image, feet)
    best = None
    dx_range = range(-ALIGN_SEARCH[0], ALIGN_SEARCH[0] + 1)
    dy_range = range(-ALIGN_SEARCH[1], ALIGN_SEARCH[1] + 1)
    if guess is not None:
        gx, gy = int(round(guess[0])) - ax, int(round(guess[1])) - ay
        dx_range = range(gx - ALIGN_SEARCH[1], gx + ALIGN_SEARCH[1] + 1)
        dy_range = range(gy - ALIGN_SEARCH[1], gy + ALIGN_SEARCH[1] + 1)
    for dy in dy_range:
        for dx in dx_range:
            # canvas(x, y) = frame(x + dx, y + dy) : l'image décalée dans le repère de la référence.
            canvas = Image.new("L", ref.size, 0)
            canvas.paste(frame, (-dx, -dy))
            score = ImageChops.difference(canvas.crop(region), target).histogram()[255]
            if best is None or score < best[0] or (score == best[0] and abs(dx) + abs(dy) < best[1]):
                best = (score, abs(dx) + abs(dy), dx, dy)
    return [ax + best[2], ay + best[3]]


def anchor_sheet(data, image, feet, axis=True):
    """Ancres de toutes les images d'une planche : la 1re image de « repos » et les images en
    mouvement par compute_anchor (axe du corps pour les images debout, UPRIGHT, si axis), les
    autres images immobiles (STILL) recalées sur elle."""
    anims = data["animations"]
    ref = None
    idle = anims.get("repos", {}).get("images", [])
    if idle:
        ref_image = crop(image, idle[0])
        ref = (ref_image, compute_anchor(ref_image, feet, axis=axis))
    result = {}
    for name, anim in anims.items():
        anchors = []
        for index, frame in enumerate(anim["images"]):
            part = crop(image, frame)
            anchor = None
            if ref is not None and name == "repos" and index == 0:
                anchor = ref[1]
            elif ref is not None and name in STILL:
                # x recalé sur la référence ; y sous les pieds de l'image (ils ne se lèvent pas).
                guess = compute_anchor(part, feet, False, axis)
                aligned = align_anchor(ref[0], ref[1], part, feet, guess)
                if aligned is not None:
                    anchor = [aligned[0], guess[1]]
            upright = axis and name in UPRIGHT
            anchors.append(anchor or compute_anchor(part, feet, name in LYING, upright))
        result[name] = anchors
    return result


def torso_anchors(data, image, anchors):
    """Variante pour une vue où une queue, un bras ou un pan de vêtement cache un pied (dos d'un
    homme-chat, d'un ours) : x des images immobiles recalé sur le buste de la 1re image de
    « repos » (rangées TORSO_BAND de sa hauteur debout, alpha), x de référence = axe du corps ; les
    y restent sous les pieds."""
    idle = data["animations"].get("repos", {}).get("images", [])
    if not idle:
        return anchors
    ref_image = crop(image, idle[0])
    ref = _alpha(ref_image)
    box = ref.getbbox()
    if box is None:
        return anchors
    height = anchors["repos"][0][1] - box[1]
    region = (0, box[1] + int(TORSO_BAND[0] * height), ref.width, box[1] + int(TORSO_BAND[1] * height))
    target = ref.crop(region)
    axis = round(body_axis(ref_image))
    for name in STILL:
        for index, frame in enumerate(data["animations"].get(name, {}).get("images", [])):
            part = _alpha(crop(image, frame))
            best = None
            for dy in range(-ALIGN_SEARCH[1], ALIGN_SEARCH[1] + 1):
                for dx in range(-TORSO_SEARCH, TORSO_SEARCH + 1):
                    canvas = Image.new("L", ref.size, 0)
                    canvas.paste(part, (-dx, -dy))
                    score = ImageChops.difference(canvas.crop(region), target).histogram()[255]
                    if best is None or score < best[0]:
                        best = (score, dx)
            anchors[name][index] = [axis + best[1], anchors[name][index][1]]
    return anchors


def cmd_anchors(paths, write, feet, axis=True, torso=False):
    for path in paths:
        data = read_json(path)
        image = Image.open(sheet_png(path)).convert("RGBA")
        anchors = anchor_sheet(data, image, feet, axis)
        if torso:
            anchors = torso_anchors(data, image, anchors)
        moved = 0
        for name, anim in data["animations"].items():
            for frame, anchor in zip(anim["images"], anchors[name]):
                if [round(float(frame[4])), round(float(frame[5]))] != anchor:
                    moved += 1
                    if not write:
                        print("  %-8s %s -> %s" % (name, frame[4:6], anchor))
                frame[4:6] = anchor
        print("%s : %d ancre(s) %s" % (os.path.relpath(path, ROOT), moved, "réécrite(s)" if write else "à changer"))
        if write:
            write_json(path, data)
    return 0


# --- Vérification ---------------------------------------------------------------------------


def _expected_count_ok(want, count):
    return count in want if isinstance(want, list) else count == want


def check_view(json_path, table, height_px, profile_height=0.0):
    """(problèmes, remarques) d'une vue. Les problèmes bloquent (format, animations du tableau,
    images, ancres, hauteur du profil, échelle des animations jouées : USED) ; les remarques
    (échelle des autres animations, vue dessinée plus petite ou plus grande que le profil, que
    le jeu compense) vont dans la liste des images à refaire. profile_height : hauteur debout du
    profil (0 pour le profil lui-même, comparé à height_px)."""
    problems, notes = [], []
    png = sheet_png(json_path)
    if not os.path.exists(png) or not os.path.exists(json_path):
        return ["absente"], notes
    image = Image.open(png)
    if image.mode != "RGBA":
        problems.append("PNG %s au lieu de RGBA" % image.mode)
    image = image.convert("RGBA")
    soft = sum(image.getchannel("A").histogram()[1:255])
    if soft:
        problems.append("alpha flou (%d px entre 1 et 254)" % soft)
    try:
        data = read_json(json_path)
    except ValueError as error:
        return problems + ["JSON illisible : %s" % error], notes
    if data.get("planche") != list(image.size):
        problems.append("planche %s au lieu de %s" % (data.get("planche"), list(image.size)))
    anims = data.get("animations", {})
    for name, (count, fps, loops, hits, wave) in TABLES[table].items():
        anim = anims.get(name)
        if anim is None and table == "npc" and name == "parle":
            notes.append("parle absente (le PNJ garde repos en conversation)")
            continue
        if anim is None:
            problems.append("%s absente" % name)
            continue
        if not _expected_count_ok(count, len(anim.get("images", []))):
            problems.append("%s : %d images au lieu de %s" % (name, len(anim.get("images", [])), count))
        if anim.get("ips") != fps or anim.get("boucle") != loops:
            problems.append("%s : ips %s, boucle %s" % (name, anim.get("ips"), anim.get("boucle")))
        if anim.get("coup") != hits or anim.get("onde") != wave:
            problems.append("%s : coup %s, onde %s" % (name, anim.get("coup"), anim.get("onde")))
    standing = {}
    for name, anim in anims.items():
        for index, frame in enumerate(anim.get("images", [])):
            x, y, w, h, ax, ay = [float(v) for v in frame[:6]]
            if w <= 0 or h <= 0 or x < 0 or y < 0 or x + w > image.width or y + h > image.height:
                problems.append("%s/%d hors de la planche" % (name, index))
                continue
            margin = ANCHOR_MARGIN
            if not (-margin <= ax <= w + margin and -margin <= ay <= h + margin):
                problems.append("%s/%d : ancre hors de l'image" % (name, index))
            part = crop(image, frame)
            if part.getchannel("A").getbbox() is None:
                problems.append("%s/%d vide" % (name, index))
                continue
            standing.setdefault(name, []).append(standing_height(part, frame))
    idle = standing.get("repos", [0.0])[0]
    if idle and not profile_height and abs(idle - height_px) > STANDING_TOLERANCE * height_px:
        problems.append("hauteur debout %.0f px au lieu de %.0f (repos, 1re image)" % (idle, height_px))
    if idle and profile_height and abs(idle - profile_height) > STANDING_TOLERANCE * profile_height:
        notes.append(
            "dessinée à %d %% du profil (%.0f px debout au lieu de %.0f ; le jeu compense)"
            % (round(100 * idle / profile_height), idle, profile_height)
        )
    if idle and table != "timere":
        for name, heights in standing.items():
            if name not in UPRIGHT and name != "course":
                continue
            low = 0.0 if name == "course" else idle * (1 - SCALE_TOLERANCE)
            bad = [i for i, v in enumerate(heights) if v > idle * (1 + SCALE_TOLERANCE) or v < low]
            if bad:
                text = "%s : échelle différente de repos (images %s)" % (name, bad)
                (problems if name in USED[table] else notes).append(text)
    return problems, notes


def _signature(json_path):
    anims = read_json(json_path).get("animations", {})
    return {
        name: (len(a.get("images", [])), a.get("ips"), a.get("boucle"), a.get("coup"), a.get("onde"))
        for name, a in anims.items()
    }


def _idle_height(json_path):
    data = read_json(json_path)
    idle = data.get("animations", {}).get("repos", {}).get("images", [])
    if not idle:
        return 0.0
    image = Image.open(sheet_png(json_path)).convert("RGBA")
    return standing_height(crop(image, idle[0]), idle[0])


def check_sheet(entry):
    """Problèmes et remarques d'une planche du manifeste, par vue : {vue: ([problèmes],
    [remarques])} (seulement les vues qui en ont)."""
    base = os.path.join(ROOT, entry["dir"], entry["id"])
    height_px = entry["height_m"] * PX_PER_M
    report = {}
    side = base + ".json"
    profile = _idle_height(side) if os.path.exists(side) and os.path.exists(sheet_png(side)) else 0.0
    for view in entry.get("views", [""]):
        path = base + view + ".json"
        problems, notes = check_view(path, entry["table"], height_px, profile if view else 0.0)
        if view and not problems and os.path.exists(side) and _signature(path) != _signature(side):
            problems.append("animations, cadences, coup ou onde différents du profil")
        for anim, source in entry.get("aliases", {}).get(view or "side", {}).items():
            notes.append("%s remplacée par les images de %s (dessins à refaire)" % (anim, source))
        if problems or notes:
            report[view or "profil"] = (problems, notes)
    return report


def check_all(manifest=None):
    """Nombre de planches à reprendre (problèmes) ; le détail et les remarques sont imprimés."""
    manifest = manifest or load_manifest()
    bad = 0
    for entry in manifest.get("sheets", []):
        report = check_sheet(entry)
        label = os.path.join(entry["dir"], entry["id"])
        for view, (problems, notes) in report.items():
            if problems:
                print("%s (%s) : %s" % (label, view, " ; ".join(problems)))
            for note in notes:
                print("  remarque %s (%s) : %s" % (label, view, note))
        bad += 1 if any(problems for problems, _ in report.values()) else 0
    return bad


def cmd_check():
    manifest = load_manifest()
    bad = check_all(manifest)
    print("%d planche(s), %d à reprendre" % (len(manifest.get("sheets", [])), bad))
    return 1 if bad else 0


def cmd_alias(paths, anim, source):
    """Remplace les images de anim par celles de source (cadence et boucle de anim gardées) :
    une animation dessinée à une autre échelle cède la place à une animation juste."""
    for path in paths:
        data = read_json(path)
        anims = data["animations"]
        anims[anim]["images"] = [list(frame) for frame in anims[source]["images"]]
        write_json(path, data)
        print("%s : %s ← images de %s" % (os.path.relpath(path, ROOT), anim, source))
    return 0


def cmd_trim(paths, keep):
    """Ne garde dans la planche (PNG et JSON) que les animations keep, que le jeu joue : les
    autres sont retirées et les rangées restantes resserrées (x inchangés, TRIM_GAP px entre deux
    rangées ; une image partagée par deux animations, « parle » remplacée par « repos », n'est
    copiée qu'une fois). Le budget de l'export Web en profite ; les planches complètes restent
    dans l'historique (livraison)."""
    for path in paths:
        data = read_json(path)
        image = Image.open(sheet_png(path)).convert("RGBA")
        anims = data["animations"]
        kept = {name: anim for name, anim in anims.items() if name in keep}
        placed = {}
        offset = 0
        for anim in kept.values():
            todo = [tuple(int(v) for v in f[:4]) for f in anim["images"]]
            todo = [rect for rect in todo if rect not in placed]
            if not todo:
                continue
            top = min(r[1] for r in todo)
            bottom = max(r[1] + r[3] for r in todo)
            for rect in todo:
                placed[rect] = (rect[0], offset + rect[1] - top)
            offset += bottom - top + TRIM_GAP
        width = max(r[0] + r[2] for r in placed)
        height = max(placed[r][1] + r[3] for r in placed)
        sheet = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        for rect, (x, y) in placed.items():
            sheet.paste(image.crop((rect[0], rect[1], rect[0] + rect[2], rect[1] + rect[3])), (x, y))
        for anim in kept.values():
            for frame in anim["images"]:
                frame[1] = placed[tuple(int(v) for v in frame[:4])][1]
        dropped = [name for name in anims if name not in keep]
        data["animations"] = kept
        data["planche"] = [width, height]
        sheet.save(sheet_png(path), optimize=True)
        write_json(path, data)
        print(
            "%s : %s retirées, %d × %d → %d × %d"
            % (os.path.relpath(path, ROOT), ", ".join(dropped) or "rien", image.width, image.height, width, height)
        )
    return 0


# --- Planche de contrôle --------------------------------------------------------------------


def cmd_strip(out_path, paths, scale=2, only=None):
    """Chaque animation sur une rangée, images posées sur la même ancre (ligne de sol grise, axe
    vertical bleu), et en dernière colonne toutes les images superposées : un pied qui glisse ou
    une échelle qui saute se voient tout de suite. Ligne orange : hauteur debout de la 1re image
    de « repos » de la planche (même échelle attendue pour repos, marche et parle). Cases à la
    taille de chaque planche (plusieurs vues côte à côte restent lisibles)."""
    blocks = []
    for path in paths:
        data = read_json(path)
        image = Image.open(sheet_png(path)).convert("RGBA")
        rows = []
        idle = 0.0
        for name, anim in data["animations"].items():
            frames = [(crop(image, f), (float(f[4]), float(f[5]))) for f in anim["images"]]
            if name == "repos" and frames:
                idle = standing_height(frames[0][0], anim["images"][0])
            if only and name not in only:
                continue
            rows.append(("%s %s" % (os.path.basename(path), name), frames))
        above = max(max(a[1] for _, a in fr) for _, fr in rows)
        below = max(max(im.height - a[1] for im, a in fr) for _, fr in rows)
        left = max(max(a[0] for _, a in fr) for _, fr in rows)
        right = max(max(im.width - a[0] for im, a in fr) for _, fr in rows)
        cell = (int(left + right) + 8, int(above + below) + 16)
        blocks.append((rows, idle, above, left, cell))
    width = max(cell[0] * (max(len(fr) for _, fr in rows) + 1) for rows, _, _, _, cell in blocks)
    height = sum(cell[1] * len(rows) for rows, _, _, _, cell in blocks)
    sheet = Image.new("RGBA", (width, height), (86, 92, 104, 255))
    draw = ImageDraw.Draw(sheet)
    y0 = 0
    for rows, idle, above, left, (cell_w, cell_h) in blocks:
        for label, frames in rows:
            ground = y0 + 12 + int(above)
            draw.text((2, y0 + 1), label, fill=(255, 255, 255, 255))
            onion = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
            for c, (part, (ax, ay)) in enumerate(frames + [(None, (0, 0))]):
                x0 = c * cell_w
                origin = x0 + 4 + int(left)
                draw.line((x0, ground, x0 + cell_w - 2, ground), fill=(170, 170, 170, 255))
                draw.line((origin, y0 + 12, origin, y0 + cell_h - 2), fill=(120, 200, 255, 255))
                if idle:
                    top = ground - int(round(idle))
                    draw.line((x0, top, x0 + cell_w - 2, top), fill=(240, 150, 60, 255))
                if part is None:
                    sheet.alpha_composite(onion, (x0, y0))
                    continue
                pos = (origin - int(round(ax)), ground - int(round(ay)))
                sheet.alpha_composite(part, pos)
                ghost = part.copy()
                ghost.putalpha(part.getchannel("A").point(lambda v: v * 90 // 255))
                onion.alpha_composite(ghost, (pos[0] - x0, pos[1] - y0))
                draw.line((origin - 3, ground, origin + 3, ground), fill=(255, 40, 40, 255), width=1)
            y0 += cell_h
    if scale != 1:
        sheet = sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST)
    sheet.save(out_path)
    print(out_path)
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("check", help="vérifie les planches du manifeste")
    anchors = sub.add_parser("anchors", help="recalcule les ancres des pieds")
    anchors.add_argument("files", nargs="+")
    anchors.add_argument("--write", action="store_true")
    anchors.add_argument("--feet", choices=("dark", "alpha"), default="dark")
    anchors.add_argument("--no-axis", action="store_true", help="pieds cherchés sur toute la largeur")
    anchors.add_argument("--torso", action="store_true", help="images immobiles recalées sur le buste")
    alias = sub.add_parser("alias", help="remplace les images d'une animation par celles d'une autre")
    alias.add_argument("anim")
    alias.add_argument("source")
    alias.add_argument("files", nargs="+")
    trim = sub.add_parser("trim", help="ne garde que les animations données (PNG et JSON)")
    trim.add_argument("keep", help="animations gardées, séparées par des virgules")
    trim.add_argument("files", nargs="+")
    strip = sub.add_parser("strip", help="planche de contrôle alignée sur les ancres")
    strip.add_argument("out")
    strip.add_argument("files", nargs="+")
    strip.add_argument("--scale", type=int, default=2)
    strip.add_argument("--anims", default="", help="animations à montrer (repos,parle…), toutes par défaut")
    args = parser.parse_args()
    if args.command == "check":
        return cmd_check()
    if args.command == "anchors":
        return cmd_anchors(args.files, args.write, args.feet, not args.no_axis, args.torso)
    if args.command == "alias":
        return cmd_alias(args.files, args.anim, args.source)
    if args.command == "trim":
        return cmd_trim(args.files, args.keep.split(","))
    only = [name for name in args.anims.split(",") if name]
    return cmd_strip(args.out, args.files, args.scale, only)


if __name__ == "__main__":
    sys.exit(main())
