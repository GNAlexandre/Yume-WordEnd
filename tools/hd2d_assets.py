#!/usr/bin/env python3
"""Images HD-2D de remplacement du jeu (docs/ASSETS_HD2D.md), en pixel art généré (Pillow).

La liste exacte des images (chemin, taille, genre) est tools/hd2d_manifest.json ; chaque image a
sa recette dans tools/hd2d_ground.py (sol, falaises, matières), tools/hd2d_props.py (décors,
façades) ou tools/hd2d_sky.py (ciel, horizon, effets). Une image livrée (ChatGPT…) remplace le
remplaçant du même nom, sans toucher au code. Densité : 96 px par mètre (48 pour le lointain).

Usage (Python 3.9+, pip install Pillow) :

    python3 tools/hd2d_assets.py gen            # crée les images absentes
    python3 tools/hd2d_assets.py gen --force    # refait tous les remplaçants
    python3 tools/hd2d_assets.py gen well grass # seulement ces images (noms ou chemins), refaites
    python3 tools/hd2d_assets.py check          # tailles, transparence, raccords, ancrage
    python3 tools/hd2d_assets.py fit <fichier>  # ramène une image livrée trop grande à sa taille
    python3 tools/hd2d_assets.py atlas          # refait l'atlas du sol après une tuile livrée
    python3 tools/hd2d_assets.py sheet <png>    # planche de contrôle de toutes les images

Le résultat est déterministe (graine tirée du nom de chaque image).
"""

import argparse
import json
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hd2d_art import seed_for  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "hd2d_manifest.json")
# Atlas des tuiles de sol (lu par le shader du sol, src/world/shaders/terrain.gdshader) : les
# tuiles de assets/hd2d/ground/ dans l'ordre de GROUND_LAYERS, ATLAS_COLUMNS par rangée. Refait
# par gen, fit et atlas ; check vérifie qu'il est à jour.
GROUND_LAYERS = ["grass", "grass_dry", "forest_floor", "path_dirt", "flagstone", "cobble", "sand",
                 "rock", "peat", "water", "mud", "metal"]
ATLAS_COLUMNS = 4
TILE = 384
ATLAS = os.path.join(ROOT, "assets", "hd2d", "ground", "atlas", "ground_atlas.png")
# Genres d'images (tools/hd2d_manifest.json).
OPAQUE_KINDS = ("tile", "tile_h", "panorama")
ALPHA_KINDS = ("facade", "panel")


def load_manifest():
    with open(MANIFEST, encoding="utf-8") as handle:
        return json.load(handle)


def entry_name(entry):
    return os.path.splitext(os.path.basename(entry["path"]))[0]


def entry_key(entry):
    """Clé de la recette : chemin sous assets/hd2d/, sans extension (« props/rock »)."""
    return os.path.splitext(entry["path"])[0].split("assets/hd2d/", 1)[1]


def recipes():
    import hd2d_ground
    import hd2d_props
    import hd2d_sky
    table = {}
    for module in (hd2d_ground, hd2d_props, hd2d_sky):
        table.update(module.RECIPES)
    return table


def generate(entry, table):
    name = entry_name(entry)
    size = tuple(entry["size"])
    rnd = random.Random(seed_for(entry_key(entry)))
    img = table[entry_key(entry)](size, rnd)
    if img.size != size:
        raise ValueError("%s : %s au lieu de %s" % (name, img.size, size))
    if entry["kind"] in OPAQUE_KINDS:
        img = img.convert("RGB").convert("RGBA")
    path = os.path.join(ROOT, entry["path"])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    return path


def build_atlas():
    """Assemble les tuiles de sol en un atlas (rien n'est réécrit s'il est déjà à jour)."""
    rows = (len(GROUND_LAYERS) + ATLAS_COLUMNS - 1) // ATLAS_COLUMNS
    atlas = Image.new("RGBA", (ATLAS_COLUMNS * TILE, rows * TILE), (0, 0, 0, 255))
    for i, name in enumerate(GROUND_LAYERS):
        tile = Image.open(os.path.join(ROOT, "assets", "hd2d", "ground", name + ".png")).convert("RGBA")
        if tile.size != (TILE, TILE):
            tile = tile.resize((TILE, TILE), Image.NEAREST)
        atlas.paste(tile, ((i % ATLAS_COLUMNS) * TILE, (i // ATLAS_COLUMNS) * TILE))
    if os.path.exists(ATLAS):
        current = Image.open(ATLAS).convert("RGBA")
        if current.size == atlas.size and ImageChops.difference(current, atlas).getbbox() is None:
            return False
    os.makedirs(os.path.dirname(ATLAS), exist_ok=True)
    atlas.save(ATLAS, optimize=True)
    print("atlas %s" % os.path.relpath(ATLAS, ROOT))
    return True


def atlas_is_current():
    if not os.path.exists(ATLAS):
        return False
    rows = (len(GROUND_LAYERS) + ATLAS_COLUMNS - 1) // ATLAS_COLUMNS
    current = Image.open(ATLAS).convert("RGBA")
    if current.size != (ATLAS_COLUMNS * TILE, rows * TILE):
        return False
    for i, name in enumerate(GROUND_LAYERS):
        tile = Image.open(os.path.join(ROOT, "assets", "hd2d", "ground", name + ".png")).convert("RGBA")
        x, y = (i % ATLAS_COLUMNS) * TILE, (i // ATLAS_COLUMNS) * TILE
        if tile.size != (TILE, TILE) or ImageChops.difference(current.crop((x, y, x + TILE, y + TILE)), tile).getbbox():
            return False
    return True


def cmd_gen(names, force):
    manifest = load_manifest()
    table = recipes()
    wanted = set(names)
    done = 0
    for entry in manifest["images"]:
        name = entry_name(entry)
        if wanted and not wanted & {name, entry_key(entry), entry["path"]}:
            continue
        path = os.path.join(ROOT, entry["path"])
        if os.path.exists(path) and not force and not wanted:
            continue
        if entry_key(entry) not in table:
            print("ATTENTION : pas de recette pour %s" % entry_key(entry))
            continue
        generate(entry, table)
        done += 1
        print("%-48s %d x %d" % (entry["path"], entry["size"][0], entry["size"][1]))
    print("%d image(s) générée(s)" % done)
    build_atlas()
    return 0


def _edge_score(img, axis):
    """Écart moyen entre les deux bords opposés, rapporté au plus grand écart moyen entre deux
    colonnes (ou rangées) voisines de l'intérieur (joints compris) : au plus 1 environ pour une
    image sans raccord."""
    rgb_img = img.convert("RGB")
    if axis == "y":
        rgb_img = rgb_img.transpose(Image.TRANSPOSE)
    w, h = rgb_img.size

    def column(x):
        return rgb_img.crop((x, 0, x + 1, h))

    def mean_diff(p, q):
        hist = ImageChops.difference(p, q).convert("L").histogram()
        return sum(i * n for i, n in enumerate(hist)) / max(1, sum(hist))

    inner = max(mean_diff(column(x), column(x + 1)) for x in range(w - 1))
    return mean_diff(column(w - 1), column(0)) / max(4.0, inner)


def check_image(entry):
    """Problèmes d'une image du manifeste (liste vide si elle est conforme)."""
    problems = []
    path = os.path.join(ROOT, entry["path"])
    if not os.path.exists(path):
        return ["absente"]
    img = Image.open(path)
    want = tuple(entry["size"])
    if img.size != want:
        problems.append("taille %d x %d au lieu de %d x %d" % (img.size + want))
    img = img.convert("RGBA")
    kind = entry["kind"]
    alpha = img.getchannel("A")
    hist = alpha.histogram()
    soft = sum(hist[1:255])
    if kind in OPAQUE_KINDS and hist[255] != img.width * img.height:
        problems.append("doit être opaque")
    if kind in ALPHA_KINDS:
        if soft > 0.01 * img.width * img.height:
            problems.append("alpha flou (%d px entre 1 et 254) : alpha 0 ou 255 seulement" % soft)
        box = alpha.point(lambda v: 255 if v >= 128 else 0).getbbox()
        if box is None:
            problems.append("image vide")
        else:
            if box[3] != img.height:
                problems.append("ne touche pas le bord bas (ancre au sol)")
            if kind == "facade" and (box[0] > 0 or box[2] < img.width):
                problems.append("façade : le mur doit toucher les bords gauche et droit")
    if kind == "tile":
        for axis in ("x", "y"):
            score = _edge_score(img, axis)
            if score > 1.5:
                problems.append("raccord %s visible (écart %.1f)" % (axis, score))
    if kind in ("tile_h", "panorama") and _edge_score(img, "x") > 1.5:
        problems.append("raccord gauche-droite visible")
    return problems


def cmd_check():
    manifest = load_manifest()
    bad = 0
    for entry in manifest["images"]:
        problems = check_image(entry)
        if problems:
            bad += 1
            print("%s : %s" % (entry["path"], " ; ".join(problems)))
    if not atlas_is_current():
        bad += 1
        print("%s : pas à jour (lance : python3 tools/hd2d_assets.py atlas)" % os.path.relpath(ATLAS, ROOT))
    print("%d image(s), %d à reprendre" % (len(manifest["images"]), bad))
    return 1 if bad else 0


def cmd_fit(files):
    manifest = load_manifest()
    by_path = {os.path.normpath(os.path.join(ROOT, e["path"])): e for e in manifest["images"]}
    by_name = {entry_name(e): e for e in manifest["images"]}
    for file_name in files:
        path = os.path.normpath(os.path.abspath(file_name))
        entry = by_path.get(path) or by_name.get(os.path.splitext(os.path.basename(path))[0])
        if entry is None:
            print("%s : absent du manifeste" % file_name)
            return 1
        img = Image.open(path).convert("RGBA")
        want = tuple(entry["size"])
        if entry["kind"] in ALPHA_KINDS:
            alpha = img.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
            img.putalpha(alpha)
            box = alpha.getbbox()
            if box:
                img = img.crop(box)
            scale = min(want[0] / img.width, want[1] / img.height)
            if entry["kind"] == "facade":
                scale = want[0] / img.width
            size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
            img = img.resize(size, Image.NEAREST)
            out = Image.new("RGBA", want, (0, 0, 0, 0))
            out.paste(img, ((want[0] - size[0]) // 2, want[1] - size[1]))
            img = out.crop((0, 0) + want)
        else:
            img = img.resize(want, Image.NEAREST)
        img.save(os.path.join(ROOT, entry["path"]), optimize=True)
        print("%s -> %s (%d x %d)" % (file_name, entry["path"], want[0], want[1]))
    build_atlas()
    return 0


def cmd_sheet(out_path, filter_dir):
    manifest = load_manifest()
    entries = [e for e in manifest["images"] if not filter_dir or ("/%s/" % filter_dir) in e["path"]]
    thumbs = []
    for entry in entries:
        path = os.path.join(ROOT, entry["path"])
        if not os.path.exists(path):
            continue
        img = Image.open(path).convert("RGBA")
        scale = min(1.0, 256.0 / max(img.size))
        if scale < 1.0:
            img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.NEAREST)
        thumbs.append((entry_name(entry), img))
    if not thumbs:
        print("aucune image")
        return 1
    cols = 8
    cell = 264
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell, rows * (cell + 14)), (86, 92, 104, 255))
    d = ImageDraw.Draw(sheet)
    for i, (name, img) in enumerate(thumbs):
        x, y = (i % cols) * cell, (i // cols) * (cell + 14)
        sheet.paste(img, (x + (cell - img.width) // 2, y + cell - 4 - img.height), img)
        d.text((x + 4, y + cell - 2), name, fill=(255, 255, 255, 255))
    sheet.save(out_path)
    print(out_path)
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    gen = sub.add_parser("gen", help="génère les remplaçants")
    gen.add_argument("names", nargs="*")
    gen.add_argument("--force", action="store_true")
    sub.add_parser("check", help="vérifie les images du manifeste")
    fit = sub.add_parser("fit", help="ramène une image livrée à sa taille")
    fit.add_argument("files", nargs="+")
    sub.add_parser("atlas", help="refait l'atlas des tuiles de sol")
    sheet = sub.add_parser("sheet", help="planche de contrôle")
    sheet.add_argument("out")
    sheet.add_argument("--dir", default="", help="seulement ground, cliff, buildings, props, sky ou fx")
    args = parser.parse_args()
    if args.command == "gen":
        return cmd_gen(args.names, args.force)
    if args.command == "check":
        return cmd_check()
    if args.command == "fit":
        return cmd_fit(args.files)
    if args.command == "atlas":
        build_atlas()
        return 0
    return cmd_sheet(args.out, args.dir)


if __name__ == "__main__":
    sys.exit(main())
