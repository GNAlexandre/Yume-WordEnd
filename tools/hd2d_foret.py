"""Remplaçants HD-2D de la forêt profonde (lot CF ; cahier n° 5, docs/ASSETS_HD2D_ILE68.md, lot R5, sections 7.1 et 7.2),
pour les noms que le plan de la carte `foret_profonde` (docs/lore/CARTE.md, section 8) cite et que le cahier n'a pas
encore livrés :

- le refuge de Chtholly (`props/refuge_oak`, original) : le vieux chêne creux `oak_c` livré, agrandi, un creux à sa base ;
- les lisières et les bosquets : `props/forest_wall_deep` (pan de forêt sombre de 16 m), `props/grove_dense` (trois arbres
  serrés et leur taillis, faits des arbres livrés, assombris), `props/fallen_pine` (le sapin abattu, d'après
  `props/fallen_tree`), `props/rowan` (le sorbier aux baies rouges) ;
- l'eau : les mares cachées `decals/hidden_pool_a` et `_b` (eau noire sous les feuilles), `anim/river_rapids` (remous autour
  d'un rocher), `props/river_bank` (berge de galets et de racines), `props/log_bridge_b` (le tronc du gué, avec sa corde).

Une image livrée (ChatGPT) remplace le remplaçant du même nom, sans toucher au code, et sa recette s'en va avec lui. Ces
recettes sont lues par tools/hd2d_assets.py (recipes) ; leurs entrées du manifeste (lot R5) sont MANIFEST ci-dessous
(`python3 tools/hd2d_foret.py manifest` les inscrit). Le résultat est déterministe (graine tirée du nom de chaque image)."""

import math

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

from hd2d_art import Canvas, asset, darker, mix, outline, ramp, recolor, rgba
from hd2d_decals import fill, organic, place, rim, texture
from hd2d_ground import AUTUMN, leaf_sprite
from hd2d_nature import _wall, foliage, limb, tree


def _need(key):
    img = asset(key)
    if img is None:
        raise SystemExit("%s : image livrée absente (le remplaçant en dérive)" % key)
    return img


def _bottom_center(img, size, dx=0, margin=0):
    """Pose img (son cadre utile) en bas au milieu d'un cadre de taille size."""
    box = img.getchannel("A").getbbox()
    part = img.crop(box)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(part, ((size[0] - part.width) // 2 + dx, size[1] - part.height - margin))
    return out


def _darken(img, factor, tint=None, amount=0.0):
    """Assombrit img (RGB × factor), vers une teinte si tint ; l'alpha ne change pas."""
    rgb = ImageEnhance.Brightness(img.convert("RGB")).enhance(factor)
    if tint is not None:
        rgb = Image.blend(rgb, Image.new("RGB", img.size, tint if isinstance(tint, tuple) else mix(tint, tint, 0)), amount)
    out = rgb.convert("RGBA")
    out.putalpha(img.getchannel("A"))
    return out


# --- Les lisières et les bosquets ---------------------------------------------------------------------


def forest_wall_deep(size, rnd):
    """Pan de forêt de 16 m, profond et sombre : le pan de sapins et de feuillus `props/forest_wall_b` livré, assombri et
    refroidi, plus sombre encore vers le bas (sous-bois noir) ; se raccorde à gauche et à droite comme son modèle."""
    base = _need("props/forest_wall_b")
    if base.size != tuple(size):
        base = base.resize(size, Image.NEAREST)
    img = _darken(base, 0.72, "#18241E", 0.22)
    w, h = size
    shade = Image.new("RGBA", size, (10, 16, 14, 255))
    ramp_mask = Image.linear_gradient("L").resize((w, h)).point(lambda v: v * 90 // 255)
    shade.putalpha(ImageChops.multiply(ramp_mask, img.getchannel("A")))
    img.alpha_composite(shade)
    return img


def grove_dense(size, rnd):
    """Bosquet profond : un sapin, un chêne et un hêtre serrés, leurs troncs mêlés, un taillis et des fougères noires au
    pied, l'ombre dense ; faits des arbres livrés, assombris."""
    w, h = size
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    parts = [("props/tree_pine", 0.80, 0, 0.74), ("props/oak_d", 1.0, -150, 0.62), ("props/beech_c", 0.92, 150, 0.7),
             ("props/oak_b", 0.8, 30, 0.56)]
    for key, scale, dx, bright in parts:
        img = _bottom_center(_need(key), (1536, 1536))
        box = img.getchannel("A").getbbox()
        img = img.crop(box)
        img = img.resize((max(1, round(img.width * scale * 0.72)), max(1, round(img.height * scale * 0.72))), Image.NEAREST)
        img = _darken(img, bright, "#1E2A24", 0.18)
        out.alpha_composite(img, (w // 2 + dx - img.width // 2, h - img.height - 8))
    for key, x, scale in (("props/thicket_b", 0.2, 1.3), ("props/thicket_a", 0.78, 1.45), ("props/fern_d", 0.45, 1.4),
                          ("props/bush_e", 0.62, 1.5), ("props/fern_d", 0.12, 1.2), ("props/thicket_c", 0.5, 1.1)):
        img = _need(key)
        img = img.crop(img.getchannel("A").getbbox())
        img = img.resize((round(img.width * scale), round(img.height * scale)), Image.NEAREST)
        img = _darken(img, 0.66, "#1E2A24", 0.15)
        out.alpha_composite(img, (round(w * x - img.width / 2), h - img.height))
    # L'ombre dense au pied : un voile sombre qui monte d'un mètre.
    mask = Image.new("L", size, 0)
    mask.paste(Image.linear_gradient("L").resize((w, 130)).point(lambda v: v * 90 // 255), (0, h - 130))
    shade = Image.new("RGBA", size, (14, 18, 16, 255))
    shade.putalpha(ImageChops.multiply(mask, out.getchannel("A")))
    out.alpha_composite(shade)
    return out


def fallen_pine(size, rnd):
    """Sapin abattu par le vent, couché vers la droite, la motte de racines à gauche, des aiguilles rousses : le tronc
    couché `props/fallen_tree` livré, aplati, recoloré, des brins d'aiguilles."""
    base = _need("props/fallen_tree")
    base = base.crop(base.getchannel("A").getbbox())
    img = base.resize(size, Image.NEAREST)
    img = recolor(img, "#7A5A3A", keep=0.5)
    img = _darken(img, 0.92)
    px = img.load()
    w, h = size
    needles = [rgba("#B8642E"), rgba("#9A4E2C"), rgba("#C88A3A")]
    for _ in range(260):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if px[x, y][3] >= 128 and y < h * 0.7 and rnd.random() < 0.5:
            px[x, y] = needles[rnd.randrange(3)]
            if x + 1 < w and px[x + 1, y][3] >= 128:
                px[x + 1, y] = needles[rnd.randrange(3)]
    return outline(img, darker("wood_dark", 0.4))


def rowan(size, rnd):
    """Sorbier : un tronc gris et fin, un feuillage orangé, des grappes de baies rouge vif."""
    def build(c, w, h):
        trunk = [(w * 0.5, h), (w * 0.52, h * 0.78), (w * 0.47, h * 0.58), (w * 0.52, h * 0.4)]
        for k in range(3):
            limb(c, trunk[k][0], trunk[k][1], trunk[k + 1][0], trunk[k + 1][1], w * (0.1 - 0.02 * k),
                 w * (0.08 - 0.02 * k), base="#7A7470")
        limb(c, w * 0.48, h * 0.6, w * 0.16, h * 0.42, 8, 3, base="#7A7470")
        limb(c, w * 0.5, h * 0.5, w * 0.86, h * 0.34, 8, 3, base="#7A7470")
        limb(c, w * 0.52, h * 0.42, w * 0.6, h * 0.16, 7, 3, base="#7A7470")
        return foliage(w, h, rnd, [(w * 0.5, h * 0.2, w * 0.26, h * 0.1, "leaf_gold", 16),
                                   (w * 0.3, h * 0.36, w * 0.2, h * 0.09, "leaf_rust", 14),
                                   (w * 0.72, h * 0.32, w * 0.2, h * 0.09, "leaf_gold", 14),
                                   (w * 0.5, h * 0.4, w * 0.2, h * 0.08, "leaf_rust", 12),
                                   (w * 0.66, h * 0.5, w * 0.14, h * 0.06, "leaf_gold", 10)], grain=0.55)
    img = tree(size, rnd, build, "leaf_rust")
    # Les grappes : des baies rouge vif, trois ou quatre points serrés, aux bouts du feuillage.
    px = img.load()
    w, h = size
    reds = [rgba("#D8281E"), rgba("#B81E1C"), rgba("#E8503A")]
    for _ in range(26):
        for _try in range(30):
            cx, cy = rnd.randrange(int(w * 0.1), int(w * 0.9)), rnd.randrange(int(h * 0.08), int(h * 0.55))
            if px[cx, cy][3] >= 128:
                break
        else:
            continue
        for _berry in range(rnd.randint(3, 6)):
            bx, by = cx + rnd.randint(-5, 5), cy + rnd.randint(-4, 5)
            if 0 <= bx < w - 2 and 0 <= by < h - 2 and px[bx, by][3] >= 128:
                px[bx, by] = reds[rnd.randrange(3)]
                px[bx + 1, by] = reds[rnd.randrange(3)]
                px[bx, by + 1] = reds[2]
    return img


def refuge_oak(size, rnd):
    """Le refuge de Chtholly (original) : un énorme vieux chêne creux, ses racines comme des bras, un creux à sa base où une
    fée peut s'asseoir à l'abri, le feuillage or et rouille. Le vieux chêne creux `props/oak_c` livré, agrandi (×1,75) ;
    le creux est ouvert à sa base, la mousse au seuil, des feuilles au fond."""
    w, h = size
    base = _need("props/oak_c")
    box = base.getchannel("A").getbbox()
    part = base.crop(box)
    part = part.resize((round(part.width * 1.75), round(part.height * 1.75)), Image.NEAREST)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    ox, oy = (w - part.width) // 2, h - part.height
    out.alpha_composite(part, (ox, oy))
    # Le pied du tronc : milieu du bas de l'image d'origine (x ≈ 255 sur 576, à gauche du bord de la silhouette).
    trunk_x = ox + round((255 - box[0]) * 1.75)
    c = Canvas(w, h, rnd)
    top = h - 138
    arch = [(trunk_x - 52, h - 4), (trunk_x - 58, h - 52), (trunk_x - 40, top + 14), (trunk_x - 14, top - 4),
            (trunk_x + 14, top - 4), (trunk_x + 40, top + 14), (trunk_x + 56, h - 52), (trunk_x + 50, h - 4)]
    # Le bord éclairé du creux (écorce claire), puis l'ouverture sombre, plus profonde vers le haut.
    rimcol = ramp("#8A6A44", 5)
    c.poly([(x, y) for x, y in arch], rimcol[0])
    inner = [(trunk_x - 40, h - 6), (trunk_x - 46, h - 48), (trunk_x - 30, top + 22), (trunk_x - 10, top + 6),
             (trunk_x + 10, top + 6), (trunk_x + 30, top + 22), (trunk_x + 44, h - 48), (trunk_x + 38, h - 6)]
    c.poly(inner, "#1E1410")
    c.poly([(x * 0.0 + trunk_x + (x - trunk_x) * 0.62, top + 22 + (y - top - 22) * 0.62 + 10) for x, y in inner],
           "#2E2018")
    c.poly([(trunk_x + (x - trunk_x) * 0.3, top + 36 + (y - top - 36) * 0.3 + 26) for x, y in inner], "#120C0A")
    # Le seuil : de la mousse et des feuilles mortes dans le creux, des racines qui le bordent.
    moss = ramp("#6E8A3A", 4)
    for _ in range(46):
        x = trunk_x + rnd.uniform(-52, 52)
        y = h - rnd.uniform(1, 9)
        c.rect(x, y, x + rnd.randint(3, 7), y + rnd.randint(2, 4), moss[rnd.randint(0, 3)])
    for _ in range(18):
        x = trunk_x + rnd.uniform(-34, 34)
        y = h - rnd.uniform(6, 20)
        c.rect(x, y, x + rnd.randint(3, 5), y + 2, rnd.choice(["#B8642E", "#C88A3A", "#9A4E2C"]))
    layer = c.img
    # Le creux ne sort pas de la silhouette du tronc : le masque est celui de l'arbre.
    mask = out.getchannel("A")
    hole = layer.getchannel("A")
    hole = ImageChops.multiply(hole, mask.filter(ImageFilter.MaxFilter(3)))
    out.paste(layer, (0, 0), hole)
    return out


# --- L'eau --------------------------------------------------------------------------------------------


def hidden_pool(size, rnd, leaves_count):
    """Petite mare dans un creux, presque couverte de feuilles mortes flottantes : on devine à peine l'eau noire, un bord
    de mousse."""
    w, h = size
    mask = organic(size, rnd, 80, 3, inset=0.1)
    a = mask.point(lambda v: 255 if v >= 128 else 0)
    inner = a.filter(ImageFilter.MinFilter(9))
    img = fill(mask, texture(size, rnd, "#46603A", 3, cells=6, dither=40))
    water = texture(size, rnd, "#16222A", 3, cells=4, dither=30)
    img.paste(water, (0, 0), inner)
    d = ImageDraw.Draw(img)
    ip = inner.load()
    for _ in range(int(w * h / 500)):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if ip[x, y]:
            d.point((x, y), fill=rgba("#5A7A86"))
    colors = ["leaf_gold", "leaf_rust", "#8A5A36", "leaf_yellow"]
    for _ in range(leaves_count):
        x, y = rnd.gauss(w * 0.5, w * 0.2), rnd.gauss(h * 0.5, h * 0.2)
        if 4 < x < w - 4 and 4 < y < h - 4 and ip[int(x), int(y)]:
            place(img, leaf_sprite(rnd, rnd.choice([8, 10, 12]), rnd.choice(colors)), x, y)
    img.putalpha(ImageChops.lighter(mask, img.getchannel("A")).point(lambda v: 255 if v >= 128 else 0))
    return rim(img, "#1A2418")


def river_bank(size, rnd):
    """Berge de galets ronds et de racines vue de face, le bas de l'image au ras de l'eau : un tas bas de galets gris, bruns et
    verdis tassés en désordre sur un peu de terre, des racines, de la mousse ; la silhouette est un dos de talus qui
    s'abaisse jusqu'au sol aux deux bouts (sans raccord)."""
    w, h = size
    c = Canvas(w, h, rnd)
    earth = ramp("#46382A", 4)
    # Le profil : un dos arrondi, plein au milieu, à zéro aux bouts.
    top = [h - (h * 0.62) * max(0.0, math.sin(math.pi * x / (w - 1))) ** 0.55 + rnd.uniform(-1.5, 1.5) for x in range(w)]
    for x in range(4, w - 4):
        for y in range(int(top[x]) + 5, h):
            c.img.putpixel((x, y), rgba(earth[1 + ((x // 3 + y // 2) % 7 == 0)]))
    tones = [ramp("#8E877A", 5), ramp("#6E6A62", 5), ramp("#7A6A56", 5), ramp("#6E7458", 5)]
    stones = []
    for _ in range(70):
        x = rnd.uniform(10, w - 10)
        r = rnd.uniform(6, 13)
        floor = top[int(x)] + r * 0.55
        if floor > h - r * 0.3:
            continue
        stones.append((rnd.uniform(floor, h - r * 0.3), x, r))
    for y, x, r in sorted(stones):
        c.blob(x, y, r, r * 0.66, rnd.choice(tones), light=(-0.4, -0.6))
    roots = ramp("#5A4230", 4)
    for _ in range(3):
        x = rnd.uniform(60, w - 60)
        c.line([(x, top[int(x)] + 2), (x + rnd.uniform(-8, 8), (top[int(x)] + h) / 2.0), (x + rnd.uniform(-14, 14), h - 3)],
               roots[rnd.randint(1, 3)], 3)
    moss = ramp("#5E7A34", 4)
    for _ in range(50):
        x = rnd.uniform(14, w - 14)
        y = top[int(x)] + rnd.uniform(-1, 4)
        c.rect(x, y, x + rnd.randint(3, 8), y + rnd.randint(2, 4), moss[rnd.randint(0, 3)])
    return c.finish(darker("#46382A", 0.5))


def log_bridge_b(size, rnd):
    """Tronc équarri jeté en passerelle au-dessus d'un torrent, une main courante de corde : le tronc `props/log_bridge`
    livré (corde comprise), retourné, plus moussu, posé au bas de l'image."""
    w, h = size
    base = _need("props/log_bridge")
    base = base.crop(base.getchannel("A").getbbox()).transpose(Image.FLIP_LEFT_RIGHT)
    base = recolor(base, "#6A5A38", keep=0.55)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(base, ((w - base.width) // 2, h - base.height))
    return out


def river_rapids(size, rnd, n):
    """Remous blancs et écume autour d'un rocher à fleur d'eau, le rocher immobile : n images de la bande."""
    w, h = size
    frames = []
    rock = Canvas(w, h, rnd)
    rock.blob(w * 0.5, h * 0.66, w * 0.17, h * 0.33, ramp("#7E7A70", 5), light=(-0.4, -0.6))
    rock.blob(w * 0.46, h * 0.5, w * 0.1, h * 0.1, ramp("#6E8A3A", 4), light=(-0.4, -0.6))
    rock_img = rock.finish(darker("#5E5A52", 0.4))
    for f in range(n):
        phase = f / float(n)
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        for k in range(14):
            t = (phase + k / 14.0) % 1.0
            a = math.pi * 0.05 + math.pi * 1.0 * (k / 13.0)
            rx, ry = w * (0.2 + 0.24 * t), h * (0.3 + 0.2 * t)
            x0, y0 = w * 0.5 + math.cos(a) * rx, h * 0.8 + math.sin(a) * ry * 0.6
            length = 10 + 12 * (1.0 - t)
            alpha = round(255 * (1.0 - t) ** 0.7)
            col = (240, 248, 250, alpha) if t < 0.55 else (176, 204, 214, alpha)
            d.line((x0, y0, x0 + length * 0.9, y0 + 2), fill=col, width=3 if t < 0.4 else 2)
        for k in range(10):
            t = (phase * 2 + k / 10.0) % 1.0
            x = w * (0.08 + 0.84 * ((k * 0.37 + phase) % 1.0))
            y = h * (0.25 + 0.65 * ((k * 0.61 + t) % 1.0))
            d.rectangle((x, y, x + 2, y + 1), fill=(255, 255, 255, 230))
        img.alpha_composite(rock_img)
        frames.append(img)
    return frames


RECIPES = {
    "props/forest_wall_deep": forest_wall_deep,
    "props/grove_dense": grove_dense,
    "props/fallen_pine": fallen_pine,
    "props/rowan": rowan,
    "props/refuge_oak": refuge_oak,
    "props/log_bridge_b": log_bridge_b,
    "props/river_bank": river_bank,
    "decals/hidden_pool_a": lambda s, r: hidden_pool(s, r, 34),
    "decals/hidden_pool_b": lambda s, r: hidden_pool(s, r, 20),
    "anim/river_rapids": river_rapids,
}

# Entrées du manifeste (tools/hd2d_manifest.json) : chemin, taille, genre, priorité, lot R5, drapeaux.
MANIFEST = [
    {"path": "assets/hd2d/props/forest_wall_deep.png", "size": [1536, 1056], "kind": "panel", "prio": 2, "lot": "R5",
     "wrap": "x"},
    {"path": "assets/hd2d/props/grove_dense.png", "size": [768, 864], "kind": "panel", "prio": 2, "lot": "R5"},
    {"path": "assets/hd2d/props/fallen_pine.png", "size": [576, 154], "kind": "panel", "prio": 3, "lot": "R5"},
    {"path": "assets/hd2d/props/rowan.png", "size": [288, 480], "kind": "panel", "prio": 3, "lot": "R5"},
    {"path": "assets/hd2d/props/refuge_oak.png", "size": [768, 960], "kind": "panel", "prio": 1, "lot": "R5"},
    {"path": "assets/hd2d/props/log_bridge_b.png", "size": [384, 96], "kind": "panel", "prio": 3, "lot": "R5"},
    {"path": "assets/hd2d/props/river_bank.png", "size": [384, 96], "kind": "panel", "prio": 3, "lot": "R5"},
    {"path": "assets/hd2d/decals/hidden_pool_a.png", "size": [192, 144], "kind": "decal", "prio": 2, "lot": "R5"},
    {"path": "assets/hd2d/decals/hidden_pool_b.png", "size": [144, 115], "kind": "decal", "prio": 3, "lot": "R5"},
    {"path": "assets/hd2d/anim/river_rapids.png", "size": [192, 96], "kind": "anim", "prio": 3, "lot": "R5",
     "frames": 4, "fps": 8},
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
        print("manifeste à jour (%d images de la forêt)" % len(MANIFEST))
        return 0
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(new)
    print("manifeste : %d images de la forêt" % len(MANIFEST))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(cmd_manifest() if sys.argv[1:] == ["manifest"] else print(__doc__) or 2)
