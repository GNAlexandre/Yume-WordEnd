"""Remplaçant HD-2D de la colline des étoiles (lot C3 ; cahier n° 5, docs/ASSETS_HD2D_ILE68.md, lot R6,
section 8.4), pour le seul nom que la section 7 de docs/lore/CARTE.md cite et que le cahier n'a pas encore
livré : `anim/talisman_float`, l'éclat de talisman que la scène de l'acte 1 (8.8) fait flotter autour du
petit cristal. Les images que le plan de la colline pose (lone_tree, boulder_a, mossy_rock, heather,
tall_grass, wildflowers_a, rock_small_a, les herbes et les rochers du bord) sont toutes livrées.
Une image livrée (ChatGPT) remplace le remplaçant du même nom, sans toucher au code. Inscrit au manifeste
(tools/hd2d_manifest.json) ; tools/hd2d_assets.py gen le crée."""

import math

from PIL import Image, ImageDraw

from hd2d_art import mix, rgba


def anim_talisman_float(size, rnd, n):
    """Un éclat de talisman : un fragment de métal blanc gravé qui flotte et tourne lentement sur lui-même
    (sa largeur varie d'une image à l'autre, comme s'il tournait), un halo d'étoile en alpha doux."""
    w, h = size
    cx, cy = w / 2.0, h / 2.0
    frames = []
    for f in range(n):
        turn = f / float(n) * 2.0 * math.pi
        # Largeur apparente du fragment : pleine de face, mince de profil.
        half_w = 1.2 + 3.6 * abs(math.cos(turn))
        half_h = 6.0
        bob = math.sin(turn) * 0.8
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        px = img.load()
        for y in range(h):
            for x in range(w):
                r = math.hypot(x + 0.5 - cx, y + 0.5 - cy - bob) / (w * 0.5)
                halo = max(0.0, 1.0 - r) ** 2.4
                if halo > 0.0:
                    px[x, y] = mix("#BFD4FF", "#FFFFFF", halo) + (round(150 * halo),)
        d = ImageDraw.Draw(img)
        top, bottom = cy - half_h + bob, cy + half_h + bob
        # Le fragment : un losange allongé, le côté éclairé plus clair que l'autre.
        body = [(cx, top), (cx + half_w, cy + bob - 1.0), (cx + half_w * 0.8, bottom - 1.0), (cx, bottom),
                (cx - half_w * 0.8, bottom - 1.0), (cx - half_w, cy + bob - 1.0)]
        d.polygon(body, fill=rgba("#DDE6F2"))
        d.polygon([(cx, top), (cx + half_w, cy + bob - 1.0), (cx + half_w * 0.8, bottom - 1.0), (cx, bottom)],
                  fill=rgba("#F8FBFF"))
        # La gravure : deux traits sombres, plus courts quand le fragment est de profil.
        if half_w > 2.4:
            d.line((cx - half_w * 0.4, cy + bob - 2.0, cx + half_w * 0.4, cy + bob - 2.0), fill=rgba("#7F93B4"))
            d.line((cx - half_w * 0.3, cy + bob + 1.0, cx + half_w * 0.5, cy + bob + 1.0), fill=rgba("#7F93B4"))
        d.point((cx + half_w * 0.2, top + 1.5), fill=rgba("#FFFFFF"))
        frames.append(img)
    return frames


RECIPES = {
    "anim/talisman_float": anim_talisman_float,
}

# Entrées du manifeste (tools/hd2d_manifest.json) : chemin, taille, genre, priorité, drapeaux.
MANIFEST = [
    {"path": "assets/hd2d/anim/talisman_float.png", "size": [24, 24], "kind": "anim", "prio": 1, "lot": "R6",
     "frames": 4, "fps": 6, "anchor": "center", "soft_alpha": True},
]
