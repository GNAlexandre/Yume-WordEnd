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
    python3 tools/hd2d_sheets.py anchors <json>… --write [--feet dark|alpha]
    python3 tools/hd2d_sheets.py strip <out.png> <json>…  # contrôle : images alignées sur l'ancre

Règles vérifiées (check) : PNG RGBA à alpha net, taille = « planche », animations et cadences
du tableau du cahier (3.1 fée, 3.2 PNJ, 3.3 Timere), images dans la planche et non vides, ancre
dans l'image, hauteur debout de la 1re image de « repos » (de l'ancre au haut de la silhouette)
= taille × 96 px à 6 % près dans chaque vue, même échelle d'une image debout à l'autre (12 %),
et mêmes animations, nombres d'images, cadences, « coup » et « onde » dans toutes les vues.

Ancres (anchors) : le point au sol entre les deux pieds. « dark » (personnages chaussés de
sombre) : les pixels sombres épais du bas de la silhouette (l'ouverture morphologique écarte les
contours fins de l'épée) ; « alpha » (Timere, pattes) : les pixels les plus bas de la silhouette.
x = milieu des pieds dans la bande basse, y = sous le pied le plus bas. « mort » (allongé) :
milieu de la masse sombre. Le résultat se juge sur la planche de contrôle (strip).
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
STANDING_TOLERANCE = 0.06
SCALE_TOLERANCE = 0.12
# Ancres : bande basse où l'on cherche les deux pieds (px au-dessus du pied le plus bas).
FEET_BAND = {"dark": 18, "alpha": 8}
# Taille de l'ouverture morphologique (px) : « dark » écarte les contours sombres de l'épée (3 px
# au plus) et garde les bottes ; « alpha » écarte les pointes fines.
OPENING = {"dark": 5, "alpha": 3}
DARK_LUMA = 70
LYING = ("mort",)


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


def compute_anchor(frame_image, feet="dark", lying=False):
    """Ancre (x, y) d'une image : entre les pieds, au sol (voir l'en-tête)."""
    mask = _mask(frame_image, feet)
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


def cmd_anchors(paths, write, feet):
    for path in paths:
        data = read_json(path)
        image = Image.open(sheet_png(path)).convert("RGBA")
        moved = 0
        for name, anim in data["animations"].items():
            for frame in anim["images"]:
                anchor = compute_anchor(crop(image, frame), feet, name in LYING)
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


def check_view(json_path, table, height_px):
    """Problèmes d'une vue (liste vide si elle est conforme)."""
    problems = []
    png = sheet_png(json_path)
    if not os.path.exists(png) or not os.path.exists(json_path):
        return ["absente"]
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
        return problems + ["JSON illisible : %s" % error]
    if data.get("planche") != list(image.size):
        problems.append("planche %s au lieu de %s" % (data.get("planche"), list(image.size)))
    anims = data.get("animations", {})
    for name, (count, fps, loops, hits, wave) in TABLES[table].items():
        anim = anims.get(name)
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
            if not (0 <= ax <= w and 0 <= ay <= h):
                problems.append("%s/%d : ancre hors de l'image" % (name, index))
            part = crop(image, frame)
            if part.getchannel("A").getbbox() is None:
                problems.append("%s/%d vide" % (name, index))
                continue
            standing.setdefault(name, []).append(standing_height(part, frame))
    idle = standing.get("repos", [0.0])[0]
    if idle and abs(idle - height_px) > STANDING_TOLERANCE * height_px:
        problems.append("hauteur debout %.0f px au lieu de %.0f (repos, 1re image)" % (idle, height_px))
    if idle:
        for name, heights in standing.items():
            if name in UPRIGHT or name == "course":
                low = 0.0 if name == "course" else idle * (1 - SCALE_TOLERANCE)
                bad = [i for i, v in enumerate(heights) if v > idle * (1 + SCALE_TOLERANCE) or v < low]
                if bad:
                    problems.append("%s : échelle différente de repos (images %s)" % (name, bad))
    return problems


def _signature(json_path):
    anims = read_json(json_path).get("animations", {})
    return {
        name: (len(a.get("images", [])), a.get("ips"), a.get("boucle"), a.get("coup"), a.get("onde"))
        for name, a in anims.items()
    }


def check_sheet(entry):
    """Problèmes d'une planche du manifeste, toutes vues confondues : {vue: [problèmes]}."""
    base = os.path.join(ROOT, entry["dir"], entry["id"])
    height_px = entry["height_m"] * PX_PER_M
    report = {}
    side = base + ".json"
    for view in entry.get("views", [""]):
        path = base + view + ".json"
        problems = check_view(path, entry["table"], height_px)
        if view and not problems and os.path.exists(side) and _signature(path) != _signature(side):
            problems.append("animations, cadences, coup ou onde différents du profil")
        if problems:
            report[view or "profil"] = problems
    return report


def check_all(manifest=None):
    """Nombre de planches en écart (et le détail imprimé)."""
    manifest = manifest or load_manifest()
    bad = 0
    for entry in manifest.get("sheets", []):
        report = check_sheet(entry)
        for view, problems in report.items():
            print("%s (%s) : %s" % (os.path.join(entry["dir"], entry["id"]), view, " ; ".join(problems)))
        bad += 1 if report else 0
    return bad


def cmd_check():
    manifest = load_manifest()
    bad = check_all(manifest)
    print("%d planche(s), %d à reprendre" % (len(manifest.get("sheets", [])), bad))
    return 1 if bad else 0


# --- Planche de contrôle --------------------------------------------------------------------


def cmd_strip(out_path, paths, scale=2):
    """Chaque animation sur une rangée, images posées sur la même ancre (ligne de sol, axe
    vertical), et en dernière colonne toutes les images superposées : un pied qui glisse ou une
    échelle qui saute se voient tout de suite."""
    rows = []
    for path in paths:
        data = read_json(path)
        image = Image.open(sheet_png(path)).convert("RGBA")
        for name, anim in data["animations"].items():
            frames = [(crop(image, f), (float(f[4]), float(f[5]))) for f in anim["images"]]
            rows.append(("%s %s" % (os.path.basename(path), name), frames))
    above = max(max(a[1] for _, a in fr) for _, fr in rows)
    below = max(max(im.height - a[1] for im, a in fr) for _, fr in rows)
    left = max(max(a[0] for _, a in fr) for _, fr in rows)
    right = max(max(im.width - a[0] for im, a in fr) for _, fr in rows)
    cell_w, cell_h = int(left + right) + 8, int(above + below) + 16
    cols = max(len(fr) for _, fr in rows) + 1
    sheet = Image.new("RGBA", (cols * cell_w, len(rows) * cell_h), (86, 92, 104, 255))
    draw = ImageDraw.Draw(sheet)
    for r, (label, frames) in enumerate(rows):
        y0 = r * cell_h
        ground = y0 + 12 + int(above)
        draw.text((2, y0 + 1), label, fill=(255, 255, 255, 255))
        onion = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        for c, (part, (ax, ay)) in enumerate(frames + [(None, (0, 0))]):
            x0 = c * cell_w
            origin = x0 + 4 + int(left)
            draw.line((x0, ground, x0 + cell_w - 2, ground), fill=(170, 170, 170, 255))
            draw.line((origin, y0 + 12, origin, y0 + cell_h - 2), fill=(120, 200, 255, 255))
            if part is None:
                sheet.alpha_composite(onion, (x0, y0))
                continue
            pos = (origin - int(round(ax)), ground - int(round(ay)))
            sheet.alpha_composite(part, pos)
            ghost = part.copy()
            ghost.putalpha(part.getchannel("A").point(lambda v: v * 90 // 255))
            onion.alpha_composite(ghost, (pos[0] - x0, pos[1] - y0))
            draw.line((origin - 3, ground, origin + 3, ground), fill=(255, 40, 40, 255), width=1)
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
    strip = sub.add_parser("strip", help="planche de contrôle alignée sur les ancres")
    strip.add_argument("out")
    strip.add_argument("files", nargs="+")
    strip.add_argument("--scale", type=int, default=2)
    args = parser.parse_args()
    if args.command == "check":
        return cmd_check()
    if args.command == "anchors":
        return cmd_anchors(args.files, args.write, args.feet)
    return cmd_strip(args.out, args.files, args.scale)


if __name__ == "__main__":
    sys.exit(main())
