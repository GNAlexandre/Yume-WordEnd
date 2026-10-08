#!/usr/bin/env python3
"""Images HD-2D de remplacement du jeu (docs/ASSETS_HD2D.md et docs/ASSETS_HD2D_MONDE.md), en
pixel art généré (Pillow).

La liste exacte des images (chemin, taille, genre) est tools/hd2d_manifest.json ; chaque image a
sa recette dans tools/hd2d_ground.py (sol, falaises, matières), tools/hd2d_props.py (décors,
façades du cahier n° 1), tools/hd2d_sky.py (ciel, horizon, effets), tools/hd2d_nature.py
(arbres, lisières, plantes, rochers), tools/hd2d_town.py (flancs, maisons, détails, objets de la
vie), tools/hd2d_ships.py (navires volants), tools/hd2d_decals.py (décalques au sol) ou
tools/hd2d_anim.py (bandes animées). Une image livrée (ChatGPT…) remplace le remplaçant du même nom, sans toucher au code.
Densité : 96 px par mètre (48 ou 24 pour le lointain, clé ppm du manifeste).

Usage (Python 3.9+, pip install Pillow) :

    python3 tools/hd2d_assets.py gen            # crée les images absentes
    python3 tools/hd2d_assets.py gen --force    # refait tous les remplaçants
    python3 tools/hd2d_assets.py gen well grass # seulement ces images (noms ou chemins), refaites
    python3 tools/hd2d_assets.py check          # tailles, transparence, raccords, ancrage
    python3 tools/hd2d_assets.py check --lot A  # seulement un lot du cahier n° 2 (A à G)
    python3 tools/hd2d_assets.py fit <fichier>  # ramène une image livrée trop grande à sa taille
    python3 tools/hd2d_assets.py atlas          # refait l'atlas du sol après une tuile livrée
    python3 tools/hd2d_assets.py sheet <png>    # planche de contrôle (--dir, --lot, --kind)

Genres (clé kind du manifeste) et règles vérifiées par check :
- tile : opaque, sans raccord sur les quatre bords ; variant_of : raccord bord à bord avec sa
  tuile d'origine (tuiles _b) ; tile_h : opaque, sans raccord à gauche et à droite ; panorama :
  ciel équirectangulaire opaque, raccord gauche-droite ;
- facade : élévation, alpha 0/255, mur collé aux bords gauche, droit et bas ;
- side : flanc est d'un bâtiment, comme une façade ; roof gable (pignon : haut transparent de
  part et d'autre du triangle, mur plein sur wall_m mètres) ou eaves (gouttereau : mur plein) ;
- panel : objet debout, alpha 0/255, collé au bord bas ; anchor center : sprite qui vole, centré,
  coupé par aucun bord ;
- decal : vu de dessus, ancre au centre, bord irrégulier (ni rectangle plein ni ellipse nette),
  coupé par aucun bord (sauf solid_edge et les bords qui se raccordent) ;
- anim : bande de frames images de size px côte à côte (fps : cadence de jeu) ; chaque image
  comme un panneau (ou centrée, anchor center), les images bougent et la boucle est sans saut ;
- fx : effets générés.
Drapeaux : soft_alpha (alpha continu permis : fumée, brume, lumière, nuages, ombres) ; wrap x ou
y (sans raccord à gauche et à droite, ou en haut et en bas) ; pairs_with (se raccorde aussi à
gauche et à droite avec cette image) ; ppm (densité quand elle n'est pas 96 px/m) ; lot (A à G,
cahier n° 2, section 15).

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
# tuiles de assets/hd2d/ground/ dans l'ordre de GROUND_LAYERS, ATLAS_COLUMNS par rangée (les 12 du
# cahier n° 1, puis les 15 du cahier n° 2). Refait par gen, fit et atlas ; check vérifie qu'il est
# à jour.
GROUND_LAYERS = ["grass", "grass_dry", "forest_floor", "path_dirt", "flagstone", "cobble", "sand",
                 "rock", "peat", "water", "mud", "metal",
                 "grass_b", "forest_floor_b", "path_dirt_b", "leaf_litter", "moss", "grass_dry_b",
                 "flagstone_b", "cobble_b", "meadow_flowers", "gravel", "garden_soil", "sand_b",
                 "rock_b", "planks", "stream_bed"]
ATLAS_COLUMNS = 4
TILE = 384
ATLAS = os.path.join(ROOT, "assets", "hd2d", "ground", "atlas", "ground_atlas.png")
# Genres d'images (tools/hd2d_manifest.json).
OPAQUE_KINDS = ("tile", "tile_h", "panorama")
ALPHA_KINDS = ("facade", "panel", "side", "decal", "anim")
STANDING_KINDS = ("facade", "panel", "side", "anim")
# Seuils d'alpha : un pixel « compte » à partir de 128 (alpha net) ou de 16 (alpha doux).
HARD_LEVEL = 128
SOFT_LEVEL = 16
# Raccords : écart des bords rapporté au plus grand écart intérieur (1 environ sans raccord).
SEAM_LIMIT = 1.5
# Boucle d'une bande animée : l'écart de la dernière image à la première ne dépasse pas
# LOOP_LIMIT fois le plus grand écart entre deux images voisines.
LOOP_LIMIT = 2.5


def load_manifest():
    with open(MANIFEST, encoding="utf-8") as handle:
        return json.load(handle)


def entry_name(entry):
    return os.path.splitext(os.path.basename(entry["path"]))[0]


def entry_key(entry):
    """Clé de la recette : chemin sous assets/hd2d/, sans extension (« props/rock »)."""
    return os.path.splitext(entry["path"])[0].split("assets/hd2d/", 1)[1]


def frame_count(entry):
    return int(entry.get("frames", 1))


def file_size(entry):
    """Taille du fichier : une bande animée fait frames × la largeur d'une image."""
    w, h = entry["size"]
    return (w * frame_count(entry), h)


def is_soft(entry):
    return bool(entry.get("soft_alpha", False))


def recipes():
    import hd2d_anim
    import hd2d_decals
    import hd2d_ground
    import hd2d_nature
    import hd2d_props
    import hd2d_ships
    import hd2d_sky
    import hd2d_town
    table = {}
    for module in (hd2d_ground, hd2d_props, hd2d_sky, hd2d_nature, hd2d_town, hd2d_ships, hd2d_decals, hd2d_anim):
        table.update(module.RECIPES)
    return table


def render(entry, table):
    """Image de remplacement d'une entrée (bande assemblée pour une animation)."""
    name = entry_name(entry)
    size = tuple(entry["size"])
    rnd = random.Random(seed_for(entry_key(entry)))
    recipe = table[entry_key(entry)]
    if entry["kind"] == "anim":
        frames = recipe(size, rnd, frame_count(entry))
        img = Image.new("RGBA", file_size(entry), (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            if frame.size != size:
                raise ValueError("%s : image %d de %s au lieu de %s" % (name, i, frame.size, size))
            img.paste(frame, (i * size[0], 0))
        if len(frames) != frame_count(entry):
            raise ValueError("%s : %d images au lieu de %d" % (name, len(frames), frame_count(entry)))
    else:
        img = recipe(size, rnd)
    if img.size != file_size(entry):
        raise ValueError("%s : %s au lieu de %s" % (name, img.size, file_size(entry)))
    if entry["kind"] in OPAQUE_KINDS:
        img = img.convert("RGB").convert("RGBA")
    elif entry["kind"] in ALPHA_KINDS and not is_soft(entry):
        img = img.convert("RGBA")
        img.putalpha(img.getchannel("A").point(lambda v: 255 if v >= HARD_LEVEL else 0))
    return img


def generate(entry, table):
    img = render(entry, table)
    path = os.path.join(ROOT, entry["path"])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    return path


def _differs(a, b):
    """Vrai si deux images RGBA de même taille diffèrent (couleurs ou alpha)."""
    diff = ImageChops.difference(a.convert("RGBA"), b.convert("RGBA"))
    return any(band.getbbox() is not None for band in diff.split())


def _ground_tile(name):
    tile = Image.open(os.path.join(ROOT, "assets", "hd2d", "ground", name + ".png")).convert("RGBA")
    if tile.size != (TILE, TILE):
        tile = tile.resize((TILE, TILE), Image.NEAREST)
    return tile


def build_atlas():
    """Assemble les tuiles de sol en un atlas (rien n'est réécrit s'il est déjà à jour)."""
    rows = (len(GROUND_LAYERS) + ATLAS_COLUMNS - 1) // ATLAS_COLUMNS
    atlas = Image.new("RGBA", (ATLAS_COLUMNS * TILE, rows * TILE), (0, 0, 0, 255))
    for i, name in enumerate(GROUND_LAYERS):
        path = os.path.join(ROOT, "assets", "hd2d", "ground", name + ".png")
        if not os.path.exists(path):
            print("atlas : %s absente (lance : python3 tools/hd2d_assets.py gen)" % name)
            return False
        atlas.paste(_ground_tile(name), ((i % ATLAS_COLUMNS) * TILE, (i // ATLAS_COLUMNS) * TILE))
    if os.path.exists(ATLAS):
        current = Image.open(ATLAS).convert("RGBA")
        if current.size == atlas.size and not _differs(current, atlas):
            return False
    os.makedirs(os.path.dirname(ATLAS), exist_ok=True)
    atlas.save(ATLAS, optimize=True)
    print("atlas %s (%d tuiles)" % (os.path.relpath(ATLAS, ROOT), len(GROUND_LAYERS)))
    return True


def atlas_is_current():
    if not os.path.exists(ATLAS):
        return False
    rows = (len(GROUND_LAYERS) + ATLAS_COLUMNS - 1) // ATLAS_COLUMNS
    current = Image.open(ATLAS).convert("RGBA")
    if current.size != (ATLAS_COLUMNS * TILE, rows * TILE):
        return False
    for i, name in enumerate(GROUND_LAYERS):
        if not os.path.exists(os.path.join(ROOT, "assets", "hd2d", "ground", name + ".png")):
            return False
        tile = _ground_tile(name)
        x, y = (i % ATLAS_COLUMNS) * TILE, (i // ATLAS_COLUMNS) * TILE
        if _differs(current.crop((x, y, x + TILE, y + TILE)), tile):
            return False
    return True


def _select(manifest, names=(), lot=""):
    wanted = set(names)
    for entry in manifest["images"]:
        if lot and entry.get("lot", "") != lot:
            continue
        if wanted and not wanted & {entry_name(entry), entry_key(entry), entry["path"]}:
            continue
        yield entry


def cmd_gen(names, force, lot=""):
    manifest = load_manifest()
    table = recipes()
    done = 0
    for entry in _select(manifest, names, lot):
        path = os.path.join(ROOT, entry["path"])
        if os.path.exists(path) and not force and not names:
            continue
        if entry_key(entry) not in table:
            print("ATTENTION : pas de recette pour %s" % entry_key(entry))
            continue
        generate(entry, table)
        done += 1
        w, h = file_size(entry)
        print("%-56s %d x %d" % (entry["path"], w, h))
    print("%d image(s) générée(s)" % done)
    build_atlas()
    return 0


# --- Vérifications -------------------------------------------------------------------------------


def _flat(img):
    """RGB d'une image RGBA posée sur un gris moyen : couleur et alpha comptent dans les écarts."""
    if img.mode != "RGBA":
        return img.convert("RGB")
    back = Image.new("RGBA", img.size, (128, 128, 128, 255))
    return Image.alpha_composite(back, img).convert("RGB")


def _mean_diff(p, q):
    hist = ImageChops.difference(p, q).convert("L").histogram()
    return sum(i * n for i, n in enumerate(hist)) / max(1, sum(hist))


def _columns(img, axis):
    rgb_img = _flat(img)
    if axis == "y":
        rgb_img = rgb_img.transpose(Image.TRANSPOSE)
    return rgb_img


def _inner(rgb_img):
    w, h = rgb_img.size
    return max(_mean_diff(rgb_img.crop((x, 0, x + 1, h)), rgb_img.crop((x + 1, 0, x + 2, h))) for x in range(w - 1))


def _edge_score(img, axis):
    """Écart moyen entre les deux bords opposés, rapporté au plus grand écart moyen entre deux
    colonnes (ou rangées) voisines de l'intérieur (joints compris) : au plus 1 environ pour une
    image sans raccord."""
    rgb_img = _columns(img, axis)
    w, h = rgb_img.size
    return _mean_diff(rgb_img.crop((w - 1, 0, w, h)), rgb_img.crop((0, 0, 1, h))) / max(4.0, _inner(rgb_img))


def _pair_score(a, b, axis):
    """Raccord bord à bord de deux images de même taille : a puis b, et b puis a."""
    ra, rb = _columns(a, axis), _columns(b, axis)
    w, h = ra.size
    seam = max(_mean_diff(ra.crop((w - 1, 0, w, h)), rb.crop((0, 0, 1, h))),
               _mean_diff(rb.crop((w - 1, 0, w, h)), ra.crop((0, 0, 1, h))))
    return seam / max(4.0, _inner(ra), _inner(rb))


def _mask(img, soft):
    return img.getchannel("A").point(lambda v: 255 if v >= (SOFT_LEVEL if soft else HARD_LEVEL) else 0)


# Part d'un bord (ligne de pixels extérieure) au-delà de laquelle la silhouette y est coupée net :
# une image livrée cadrée au plus juste touche souvent son bord sur quelques pixels (1 à 5 %), ce
# qui ne se voit pas en jeu ; une coupure franche en couvre bien plus.
CUT_COVER = 0.12


def _border_hits(mask, min_cover=0.0):
    """Bords touchés par la silhouette (plus de min_cover de la ligne extérieure couverte) :
    ensemble de « left », « right », « top », « bottom »."""
    w, h = mask.size
    hits = set()
    for side, box in (("left", (0, 0, 1, h)), ("right", (w - 1, 0, w, h)), ("top", (0, 0, w, 1)),
                      ("bottom", (0, h - 1, w, h))):
        if min_cover <= 0.0:
            if mask.crop(box).getbbox() is not None:
                hits.add(side)
        elif _coverage(mask, box) > min_cover:
            hits.add(side)
    return hits


SIDE_NAMES = {"left": "gauche", "right": "droit", "top": "haut", "bottom": "bas"}


def _centroid(mask):
    w, h = mask.size
    cols = [mask.crop((x, 0, x + 1, h)).histogram()[255] for x in range(w)]
    rows = [mask.crop((0, y, w, y + 1)).histogram()[255] for y in range(h)]
    total = float(sum(cols))
    if total == 0:
        return None
    return (sum(x * n for x, n in enumerate(cols)) / total + 0.5, sum(y * n for y, n in enumerate(rows)) / total + 0.5)


def _coverage(mask, box):
    """Part des pixels de box couverts par la silhouette."""
    region = mask.crop(box)
    return region.histogram()[255] / float(max(1, region.width * region.height))


def _check_standing(img, entry, label=""):
    """Panneau, façade, flanc ou image d'une bande : ancre et bords."""
    problems = []
    soft = is_soft(entry)
    mask = _mask(img, soft)
    box = mask.getbbox()
    if box is None:
        return [label + "image vide"]
    kind = entry["kind"]
    wrap = entry.get("wrap", "")
    hits = _border_hits(mask)
    if entry.get("anchor") == "free":
        # Lointain qui flotte (île, rai de lumière) : le jeu le place, pas d'ancre à vérifier.
        return problems
    if entry.get("anchor") == "center":
        cuts = _border_hits(mask, CUT_COVER)
        cut = [SIDE_NAMES[s] for s in ("left", "right", "top", "bottom") if s in cuts
               and not (wrap == "x" and s in ("left", "right")) and not (wrap == "y" and s in ("top", "bottom"))]
        if cut:
            problems.append(label + "coupé par le bord %s (sprite centré : marge tout autour)" % ", ".join(cut))
        w, h = img.size
        if kind == "panel":
            # Nuage, brume, dirigeable lointain : centré par son cadre (un cumulus est plus lourd
            # en bas). Ce qui tourne sur son centre (hélice, feuille : bandes) l'est par sa masse.
            cx, cy = (box[0] + box[2]) / 2.0, (box[1] + box[3]) / 2.0
        else:
            cx, cy = _centroid(mask)
        if (wrap != "x" and abs(cx - w / 2.0) > 0.1 * w) or (wrap != "y" and abs(cy - h / 2.0) > 0.1 * h):
            problems.append(label + "pas centré (masse en %d, %d au lieu de %d, %d)" % (cx, cy, w / 2, h / 2))
        return problems
    if "bottom" not in hits:
        problems.append(label + "ne touche pas le bord bas (ancre au sol)")
    if kind in ("facade", "side") and not {"left", "right"} <= hits:
        problems.append(label + "%s : le mur doit toucher les bords gauche et droit"
                        % ("façade" if kind == "facade" else "flanc"))
    if kind == "side":
        problems += _check_side(mask, entry)
    return problems


def _check_side(mask, entry):
    """Forme du flanc : pignon (triangle, haut transparent sur les côtés) ou gouttereau."""
    w, h = mask.size
    problems = []
    if entry.get("roof") == "gable":
        wall = int(round(float(entry["wall_m"]) * 96))
        gable = h - wall
        corner = max(2, gable // 3)
        for name, box in (("gauche", (0, 0, max(2, w // 8), corner)), ("droit", (w - max(2, w // 8), 0, w, corner))):
            if _coverage(mask, box) > 0.02:
                problems.append("pignon : coin haut %s plein (fond transparent de part et d'autre du triangle)" % name)
        if mask.crop((w // 3, 0, w - w // 3, 2)).getbbox() is None:
            problems.append("pignon : le triangle n'atteint pas le haut de l'image (faîtage)")
        band = (0, h - wall + wall // 8, w, h)
    else:
        band = (0, h // 8, w, h)
    for name, x in (("gauche", 0), ("droit", w - 1)):
        if _coverage(mask, (x, band[1], x + 1, band[3])) < 0.9:
            problems.append("mur : bord %s pas plein sur la hauteur du mur" % name)
    return problems


def _check_decal(img, entry):
    problems = []
    soft = is_soft(entry)
    mask = _mask(img, soft)
    box = mask.getbbox()
    if box is None:
        return ["image vide"]
    wrap = entry.get("wrap", "")
    solid = entry.get("solid_edge", "")
    hits = _border_hits(mask)
    cuts = _border_hits(mask, CUT_COVER)
    allowed = set()
    if wrap == "x":
        allowed |= {"left", "right"}
    if wrap == "y":
        allowed |= {"top", "bottom"}
    if solid:
        allowed.add(solid)
    cut = [SIDE_NAMES[s] for s in ("left", "right", "top", "bottom") if s in cuts and s not in allowed]
    if cut:
        problems.append("coupé par le bord %s (décalque : bord effiloché qui se fond dans le sol)" % ", ".join(cut))
    if solid and solid not in hits:
        problems.append("bord %s plein attendu" % SIDE_NAMES[solid])
    if not wrap and not solid:
        bw, bh = box[2] - box[0], box[3] - box[1]
        fill = _coverage(mask, box)
        if fill > 0.95:
            problems.append("rectangle plein (%.0f %% de sa boîte) : bord irrégulier attendu" % (100 * fill))
        else:
            oval = Image.new("L", mask.size, 0)
            ImageDraw.Draw(oval).ellipse((box[0], box[1], box[2] - 1, box[3] - 1), fill=255)
            both = ImageChops.multiply(oval, mask).crop(box).histogram()[255]
            either = ImageChops.lighter(oval, mask).crop(box).histogram()[255]
            if bw > 8 and bh > 8 and both / float(max(1, either)) > 0.97:
                problems.append("ellipse nette : bord irrégulier attendu")
    return problems


def _frames(img, entry):
    w, h = entry["size"]
    return [img.crop((i * w, 0, (i + 1) * w, h)) for i in range(frame_count(entry))]


def _changed(a, b):
    """Nombre de pixels qui changent d'une image à l'autre (couleur ou alpha)."""
    diff = ImageChops.difference(a, b)
    total = None
    for band in diff.split():
        total = band if total is None else ImageChops.lighter(total, band)
    return sum(total.point(lambda v: 255 if v > 0 else 0).histogram()[255:])


def _check_anim(img, entry):
    problems = []
    frames = _frames(img, entry)
    for i, frame in enumerate(frames):
        problems += _check_standing(frame, entry, "image %d : " % (i + 1))
    if len(frames) > 1:
        steps = [_changed(frames[i], frames[i + 1]) for i in range(len(frames) - 1)]
        loop = _changed(frames[-1], frames[0])
        if max(steps + [loop]) == 0:
            problems.append("rien ne bouge (toutes les images sont identiques)")
        elif 0 in steps:
            problems.append("images %d et %d identiques" % (steps.index(0) + 1, steps.index(0) + 2))
        elif loop > LOOP_LIMIT * max(steps) + 16:
            problems.append("boucle : saut de la dernière image à la première (%d px changent, %d au plus d'une "
                            "image à l'autre)" % (loop, max(steps)))
    return problems


def _load(entry):
    path = os.path.join(ROOT, entry["path"])
    if not os.path.exists(path):
        return None
    return Image.open(path)


def check_image(entry, by_path=None):
    """Problèmes d'une image du manifeste (liste vide si elle est conforme)."""
    problems = []
    img = _load(entry)
    if img is None:
        return ["absente"]
    want = file_size(entry)
    if img.size != want:
        problems.append("taille %d x %d au lieu de %d x %d" % (img.size + want)
                        + (" (%d images de %d x %d)" % ((frame_count(entry),) + tuple(entry["size"]))
                           if entry["kind"] == "anim" else ""))
        return problems
    img = img.convert("RGBA")
    kind = entry["kind"]
    alpha = img.getchannel("A")
    hist = alpha.histogram()
    soft = sum(hist[1:255])
    if kind in OPAQUE_KINDS and hist[255] != img.width * img.height:
        problems.append("doit être opaque")
    if kind in ALPHA_KINDS:
        if not is_soft(entry) and soft > 0.01 * img.width * img.height:
            problems.append("alpha flou (%d px entre 1 et 254) : alpha 0 ou 255 seulement" % soft)
        if hist[255] + soft == 0:
            problems.append("image vide")
            return problems
    if kind in ("facade", "panel", "side"):
        problems += _check_standing(img, entry)
    elif kind == "decal":
        problems += _check_decal(img, entry)
    elif kind == "anim":
        problems += _check_anim(img, entry)
    if kind == "tile":
        for axis in ("x", "y"):
            score = _edge_score(img, axis)
            if score > SEAM_LIMIT:
                problems.append("raccord %s visible (écart %.1f)" % (axis, score))
    if kind in ("tile_h", "panorama") and _edge_score(img, "x") > SEAM_LIMIT:
        problems.append("raccord gauche-droite visible")
    wrap = entry.get("wrap", "")
    if wrap and kind not in OPAQUE_KINDS:
        frames = _frames(img, entry) if kind == "anim" else [img]
        score = max(_edge_score(f, wrap) for f in frames)
        if score > SEAM_LIMIT:
            problems.append("raccord %s visible (écart %.1f)" % ("gauche-droite" if wrap == "x" else "haut-bas", score))
    other_name = entry.get("variant_of") or entry.get("pairs_with")
    # L'image d'origine est dans le même dossier (ground/rock, pas props/rock).
    other_path = os.path.dirname(entry["path"]) + "/" + str(other_name) + ".png"
    if other_name and by_path is not None:
        other = _load(by_path[other_path]) if other_path in by_path else None
        if other is None or other.size != img.size:
            problems.append("%s absente ou d'une autre taille" % other_name)
        else:
            other = other.convert("RGBA")
            axes = ("x", "y") if kind == "tile" else (wrap or "x",)
            for axis in axes:
                score = _pair_score(other, img, axis)
                if score > SEAM_LIMIT:
                    problems.append("raccord %s avec %s visible (écart %.1f)" % (axis, other_name, score))
    return problems


def cmd_check(lot=""):
    manifest = load_manifest()
    by_path = {e["path"]: e for e in manifest["images"]}
    bad = 0
    count = 0
    for entry in _select(manifest, (), lot):
        count += 1
        problems = check_image(entry, by_path)
        if problems:
            bad += 1
            print("%s : %s" % (entry["path"], " ; ".join(problems)))
    if not lot and not atlas_is_current():
        bad += 1
        print("%s : pas à jour (lance : python3 tools/hd2d_assets.py atlas)" % os.path.relpath(ATLAS, ROOT))
    print("%d image(s), %d à reprendre" % (count, bad))
    return 1 if bad else 0


# --- Ajustement d'une image livrée ---------------------------------------------------------------


def _margin(want):
    """Marge transparente gardée autour de ce qui ne touche aucun bord (décalques, sprites centrés)."""
    return max(2, round(0.04 * min(want)))


def _fit_into(img, want, anchor):
    """Recadre img sur sa silhouette, la réduit pour tenir dans want, la pose au bas (ou au centre,
    avec une marge tout autour)."""
    box = img.getchannel("A").getbbox()
    if box:
        img = img.crop(box)
    room = (want[0] - 2 * _margin(want), want[1] - 2 * _margin(want)) if anchor == "center" else want
    scale = min(room[0] / img.width, room[1] / img.height)
    size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
    img = img.resize(size, Image.NEAREST)
    out = Image.new("RGBA", want, (0, 0, 0, 0))
    y = (want[1] - size[1]) // 2 if anchor == "center" else want[1] - size[1]
    out.paste(img, ((want[0] - size[0]) // 2, y))
    return out.crop((0, 0) + want)


def fit_image(img, entry):
    """Image livrée ramenée à la taille du manifeste (au plus proche voisin)."""
    kind = entry["kind"]
    want = tuple(entry["size"])
    img = img.convert("RGBA")
    if kind in OPAQUE_KINDS:
        return img.resize(file_size(entry), Image.NEAREST)
    if not is_soft(entry):
        img.putalpha(img.getchannel("A").point(lambda v: 255 if v >= HARD_LEVEL else 0))
    if kind in ("facade", "side"):
        box = img.getchannel("A").getbbox()
        if box:
            img = img.crop(box)
        scale = want[0] / img.width
        img = img.resize((want[0], max(1, round(img.height * scale))), Image.NEAREST)
        out = Image.new("RGBA", want, (0, 0, 0, 0))
        out.paste(img, (0, want[1] - img.height))
        return out
    anchor = "center" if kind == "decal" or entry.get("anchor") == "center" else "bottom"
    if kind == "anim":
        n = frame_count(entry)
        fw = img.width // n
        frames = [img.crop((i * fw, 0, (i + 1) * fw, img.height)) for i in range(n)]
        union = None
        for f in frames:
            box = f.getchannel("A").getbbox()
            if box:
                union = box if union is None else (min(union[0], box[0]), min(union[1], box[1]),
                                                   max(union[2], box[2]), max(union[3], box[3]))
        out = Image.new("RGBA", file_size(entry), (0, 0, 0, 0))
        room = (want[0] - 2 * _margin(want), want[1] - 2 * _margin(want)) if anchor == "center" else want
        for i, f in enumerate(frames):
            f = f.crop(union) if union else f
            scale = min(room[0] / f.width, room[1] / f.height)
            size = (max(1, round(f.width * scale)), max(1, round(f.height * scale)))
            f = f.resize(size, Image.NEAREST)
            y = (want[1] - size[1]) // 2 if anchor == "center" else want[1] - size[1]
            out.paste(f, (i * want[0] + (want[0] - size[0]) // 2, y))
        return out
    if entry.get("wrap"):
        return img.resize(want, Image.NEAREST)
    return _fit_into(img, want, anchor)


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
        img = fit_image(Image.open(path), entry)
        img.save(os.path.join(ROOT, entry["path"]), optimize=True)
        print("%s -> %s (%d x %d)" % ((file_name, entry["path"]) + file_size(entry)))
    build_atlas()
    return 0


# --- Planche de contrôle -------------------------------------------------------------------------


def _thumb(img, entry, max_side):
    """Vignette : l'image réduite (une bande animée : ses images séparées d'un trait)."""
    if entry["kind"] == "anim":
        frames = _frames(img, entry)
        w, h = entry["size"]
        scale = min(1.0, max_side / float(max(w, h)))
        fw, fh = max(1, round(w * scale)), max(1, round(h * scale))
        out = Image.new("RGBA", (len(frames) * (fw + 3) - 3, fh), (0, 0, 0, 0))
        d = ImageDraw.Draw(out)
        for i, f in enumerate(frames):
            out.paste(f.resize((fw, fh), Image.NEAREST), (i * (fw + 3), 0))
            if i:
                d.line((i * (fw + 3) - 2, 0, i * (fw + 3) - 2, fh), fill=(255, 220, 120, 255))
        return out
    scale = min(1.0, max_side / float(max(img.size)))
    if scale < 1.0:
        img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.NEAREST)
    return img


def cmd_sheet(out_path, filter_dir, lot="", kind="", max_side=256):
    manifest = load_manifest()
    entries = [e for e in manifest["images"]
               if (not filter_dir or ("/%s/" % filter_dir) in e["path"]) and (not lot or e.get("lot", "") == lot)
               and (not kind or e["kind"] == kind)]
    thumbs = []
    for entry in entries:
        img = _load(entry)
        if img is None:
            continue
        thumbs.append((entry_name(entry), _thumb(img.convert("RGBA"), entry, max_side)))
    if not thumbs:
        print("aucune image")
        return 1
    width = max(2112, max(t.width for _, t in thumbs) + 16)
    places = []
    x = y = 8
    row_h = 0
    for name, img in thumbs:
        cell_w = max(img.width, 7 * len(name)) + 12
        if x + cell_w > width:
            x = 8
            y += row_h + 22
            row_h = 0
        places.append((name, img, x, y))
        x += cell_w
        row_h = max(row_h, img.height)
    sheet = Image.new("RGBA", (width, y + row_h + 26), (86, 92, 104, 255))
    d = ImageDraw.Draw(sheet)
    for name, img, x, y in places:
        sheet.paste(img, (x, y), img)
        d.text((x, y + img.height + 3), name, fill=(255, 255, 255, 255))
    sheet.save(out_path)
    print("%s (%d images)" % (out_path, len(thumbs)))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    gen = sub.add_parser("gen", help="génère les remplaçants")
    gen.add_argument("names", nargs="*")
    gen.add_argument("--force", action="store_true")
    gen.add_argument("--lot", default="", help="seulement un lot du cahier n° 2 (A à G)")
    check = sub.add_parser("check", help="vérifie les images du manifeste")
    check.add_argument("--lot", default="", help="seulement un lot du cahier n° 2 (A à G)")
    fit = sub.add_parser("fit", help="ramène une image livrée à sa taille")
    fit.add_argument("files", nargs="+")
    sub.add_parser("atlas", help="refait l'atlas des tuiles de sol")
    sheet = sub.add_parser("sheet", help="planche de contrôle")
    sheet.add_argument("out")
    sheet.add_argument("--dir", default="", help="seulement ground, cliff, buildings, props, sky, fx, decals ou anim")
    sheet.add_argument("--lot", default="", help="seulement un lot du cahier n° 2 (A à G)")
    sheet.add_argument("--kind", default="", help="seulement un genre (anim : images côte à côte)")
    sheet.add_argument("--max", type=int, default=256, help="plus grand côté d'une vignette (px)")
    args = parser.parse_args()
    if args.command == "gen":
        return cmd_gen(args.names, args.force, args.lot)
    if args.command == "check":
        return cmd_check(args.lot)
    if args.command == "fit":
        return cmd_fit(args.files)
    if args.command == "atlas":
        build_atlas()
        return 0
    return cmd_sheet(args.out, args.dir, args.lot, args.kind, args.max)


if __name__ == "__main__":
    sys.exit(main())
