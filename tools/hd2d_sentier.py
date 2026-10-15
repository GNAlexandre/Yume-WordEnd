"""Remplaçants HD-2D du sentier et du marais (lot C1 ; cahier n° 5, docs/ASSETS_HD2D_ILE68.md, lot R3,
section 5.1), pour les noms que le plan de la carte `sentier` (docs/lore/CARTE.md, section 4) cite
et que le cahier n'a pas encore livrés : `props/marsh_reed_wall`, `props/path_edge_ferns`,
`props/path_root_step`, `props/fg_canopy_a`, `decals/bog_pool_a`, `decals/path_stones_a`,
`decals/path_stones_b`. Une image livrée (ChatGPT) remplace le remplaçant du même nom, sans
toucher au code. Inscrits au manifeste (lot R3) ; tools/hd2d_assets.py gen les crée."""

import math

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from hd2d_art import Canvas, WrapCanvas, darker, mix, ramp, rgba
from hd2d_decals import fill, organic, place, rim, texture
from hd2d_nature import foliage, limb


def marsh_reed_wall(size, rnd):
    """Rideau dense de roseaux pâles (#9C9563) et de massettes brunes, quelques tiges cassées ; se
    raccorde à gauche et à droite."""
    w, h = size
    c = WrapCanvas(w, h, rnd)
    pale = ramp("#9C9563", 5)
    dark = ramp("#6E7A3E", 4)
    brown = ramp("#6E4A2E", 4)
    # Le pied : lames sombres et courtes.
    for _ in range(int(w / 5)):
        x = rnd.uniform(0, w)
        top = h * rnd.uniform(0.3, 0.62)
        bend = rnd.uniform(-10, 10)
        c.line([(x, h), (x + bend * 0.4, (h + top) / 2.0), (x + bend, top)], dark[rnd.randint(1, 3)], 2)
    # Les roseaux : hauts, pâles, penchés d'un côté ou de l'autre.
    for _ in range(int(w / 4.2)):
        x = rnd.uniform(0, w)
        top = h * rnd.uniform(0.04, 0.5)
        bend = rnd.uniform(-18, 18)
        color = pale[rnd.randint(1, 4)]
        c.line([(x, h), (x + bend * 0.35, (h + top) / 2.0 + 4), (x + bend, top)], color, 2 if rnd.random() < 0.7 else 3)
        if rnd.random() < 0.1:
            # Tige cassée : un coude sec près du sommet.
            c.line([(x + bend, top), (x + bend + rnd.uniform(-9, 9), top + rnd.uniform(8, 16))], pale[1], 1)
    # Les massettes : une tige brune, son épi.
    for _ in range(int(w / 40)):
        x = rnd.uniform(6, w - 6)
        top = h * rnd.uniform(0.08, 0.3)
        bend = rnd.uniform(-4, 4)
        c.line([(x, h), (x + bend, top)], dark[1], 1)
        c.rect(x + bend - 3, top + 4, x + bend + 3, top + 24, brown[1])
        c.rect(x + bend - 3, top + 4, x + bend - 1, top + 24, brown[3])
    return c.finish(darker("#6E7A3E", 0.4))


def path_edge_ferns(size, rnd):
    """Bordure basse et serrée de fougères, d'herbes hautes et de ronces qui étrangle le sentier ;
    se raccorde à gauche et à droite."""
    w, h = size
    c = WrapCanvas(w, h, rnd)
    greens = ramp("#3E6A34", 5) + ramp("#5E7A34", 4)[1:]
    rust = ramp("#B8642E", 4)
    # Les ronces, au fond : arcs bruns, épines.
    bramble = ramp("#5A3A2E", 4)
    for _ in range(int(w / 40)):
        x = rnd.uniform(0, w)
        top = h * rnd.uniform(0.15, 0.45)
        arc = [(x, h), (x + rnd.uniform(-18, 18), h * 0.55), (x + rnd.uniform(-30, 30), top)]
        c.line(arc, bramble[rnd.randint(1, 2)], 2)
        for _k in range(3):
            tx, ty = arc[2][0] + rnd.uniform(-10, 10), arc[2][1] + rnd.uniform(0, 14)
            c.rect(tx, ty, tx + 2, ty + 2, "#A8302A")
    # Les fougères : frondes qui partent du pied en éventail, folioles de part et d'autre.
    for _ in range(int(w / 22)):
        x = rnd.uniform(0, w)
        for _f in range(rnd.randint(4, 6)):
            angle = rnd.uniform(-1.05, 1.05)
            length = h * rnd.uniform(0.45, 0.95)
            color = rust[rnd.randint(0, 2)] if rnd.random() < 0.07 else greens[rnd.randint(1, len(greens) - 1)]
            prev = (x, h)
            for s in range(1, 7):
                t = s / 6.0
                p = (x + math.sin(angle) * length * t + angle * 5 * t * t * 3, h - math.cos(angle) * length * t)
                c.line([prev, p], color, 2)
                if s > 1:
                    for side in (-1, 1):
                        c.line([p, (p[0] + side * 7 * (1 - t * 0.5), p[1] + 3)], color, 1)
                prev = p
    # Herbes hautes.
    tones = ramp("#8A9440", 4)
    for _ in range(int(w / 6)):
        x = rnd.uniform(0, w)
        top = h * rnd.uniform(0.1, 0.5)
        c.line([(x, h), (x + rnd.uniform(-8, 8), top)], tones[rnd.randint(1, 3)], 1)
    return c.finish(darker("#3E5A34", 0.4))


def path_root_step(size, rnd):
    """Grosse racine moussue en travers du sentier, qui fait marche : un dos de bois sombre noueux
    sur un talus de terre qui épouse le sol, de la mousse sur le dessus."""
    w, h = size
    c = Canvas(w, h, rnd)
    wood = ramp("#4A3626", 5, spread=0.45)
    # Le talus de terre au pied, et la terre qui recouvre les deux bouts.
    c.poly([(0, h), (w * 0.03, h * 0.78), (w * 0.2, h * 0.7), (w * 0.8, h * 0.7), (w * 0.97, h * 0.78), (w, h)],
           "#5A4632")
    # La racine : une bande ondulante, grossie de nœuds, qui plonge dans le sol aux deux bouts.
    spine = []
    for k in range(33):
        t = k / 32.0
        spine.append((w * (0.03 + 0.94 * t), h * (0.66 + 0.1 * math.sin(t * 9.0) - 0.16 * math.sin(math.pi * t))))
    for k in range(len(spine) - 1):
        t = k / 32.0
        thick = h * (0.2 + 0.2 * math.sin(math.pi * t) ** 0.6 + 0.05 * math.sin(t * 23.0))
        limb(c, spine[k][0], spine[k][1], spine[k + 1][0], spine[k + 1][1], thick, thick, "#4A3626")
    for _ in range(3):
        x = rnd.uniform(w * 0.2, w * 0.8)
        c.line([(x, h * 0.6), (x + rnd.uniform(-10, 10), h * 0.95)], wood[rnd.randint(1, 3)], 2)
    moss = ramp("#4E6A34", 4)
    for _ in range(110):
        x = rnd.uniform(w * 0.06, w * 0.94)
        k = min(32, max(0, int(x / w * 32)))
        y = spine[k][1] - rnd.uniform(0, h * 0.22)
        if 0 <= y < h and c.img.getpixel((int(x), int(y)))[3]:
            c.rect(x, y, x + rnd.randint(2, 5), y + 2, moss[rnd.randint(1, 3)])
    return c.finish(darker("#4A3626", 0.4))


def fg_canopy_a(size, rnd):
    """Voûte de feuillage presque noir vue d'en dessous (premier plan suspendu au-dessus du sentier) :
    masses d'automne sombres, une grosse branche en travers, des trouées par où passent les
    étoiles. Faute de premier plan accroché à l'écran (lot E10), elle se pose en l'air, comme un
    panneau de premier plan qui s'efface devant le joueur ; centrée, aucun bord ne la coupe."""
    w, h = size
    c = Canvas(w, h, rnd)
    limb(c, w * 0.06, h * 0.46, w * 0.94, h * 0.36, h * 0.07, h * 0.04, "#2E2420")
    clusters = [
        (w * 0.2, h * 0.45, w * 0.17, h * 0.3, "#3A2E26", 16),
        (w * 0.4, h * 0.4, w * 0.18, h * 0.32, "#2E3A2A", 18),
        (w * 0.6, h * 0.45, w * 0.18, h * 0.3, "#4A3426", 16),
        (w * 0.8, h * 0.42, w * 0.16, h * 0.28, "#3A3A28", 14),
        (w * 0.5, h * 0.3, w * 0.3, h * 0.2, "#2A2E24", 14),
        (w * 0.3, h * 0.65, w * 0.14, h * 0.14, "#3A2A22", 8),
        (w * 0.68, h * 0.66, w * 0.15, h * 0.13, "#4A3A28", 8),
    ]
    holes = [(w * 0.32, h * 0.38, 16), (w * 0.55, h * 0.5, 13), (w * 0.72, h * 0.34, 15), (w * 0.2, h * 0.52, 10),
             (w * 0.46, h * 0.3, 11)]
    c.img.alpha_composite(foliage(w, h, rnd, clusters, holes, grain=0.55))
    return c.finish(darker("#2A2E24", 0.4))


# --- Décalques : la mare de tourbe et les pierres du sentier ------------------------------------------


def bog_pool_a(size, rnd):
    """Mare de tourbe à l'eau noire (#4A675F assombri), bord de sphaignes rouges et vertes, quelques
    reflets d'étoiles en points clairs."""
    w, h = size
    mask = organic(size, rnd, 92, 5, inset=0.08)
    img = fill(mask, texture(size, rnd, "#2E4A44", 3, cells=6, dither=30))
    a = mask.point(lambda v: 255 if v >= 128 else 0)
    inner = a.filter(ImageFilter.MinFilter(13))
    ring = ImageChops.subtract(a, inner)
    px = img.load()
    rp = ring.load()
    sphagnum = [rgba("#8A3A2E"), rgba("#A8483A"), rgba("#6E8A3A"), rgba("#5E7A34"), rgba("#7A5A34")]
    for y in range(h):
        for x in range(w):
            if rp[x, y]:
                px[x, y] = sphagnum[rnd.randrange(len(sphagnum))]
    ip = inner.load()
    for _ in range(int(w * h / 900)):
        x, y = rnd.randrange(w), rnd.randrange(h)
        if ip[x, y]:
            px[x, y] = rgba("#C8DCE0")
            if rnd.random() < 0.4 and x + 1 < w:
                px[x + 1, y] = rgba("#8AA8AC")
    return rim(img, darker("#2E4A44", 0.5))


def path_stones(size, rnd, count):
    """Pierres plates clairsemées et mal posées, à demi enfoncées, de l'herbe dans les interstices."""
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    spots = []
    for k in range(count):
        x = w * (0.16 + 0.68 * (k + 0.5) / count) + rnd.uniform(-w * 0.03, w * 0.03)
        y = h * 0.5 + rnd.uniform(-h * 0.2, h * 0.2)
        rx, ry = rnd.uniform(w * 0.07, w * 0.1), rnd.uniform(h * 0.1, h * 0.15)
        c = Canvas(int(2 * rx) + 8, int(2 * ry) + 8, rnd)
        c.blob(c.w / 2.0, c.h / 2.0, rx, ry, ramp(mix("stone_dark", "#6A685E", 0.5), 5)[1:])
        for _ in range(int(rx)):
            sx, sy = c.w / 2.0 + rnd.uniform(-rx, rx) * 0.7, c.h / 2.0 + rnd.uniform(-ry, ry) * 0.6
            if c.img.getpixel((int(sx), int(sy)))[3]:
                c.rect(sx, sy, sx + rnd.randint(2, 4), sy + 1,
                       "#5E7A3A" if rnd.random() < 0.45 else mix("stone", "#F0F0E0", 0.2))
        place(img, c.finish(darker("stone_dark", 0.5)), x, y)
        spots.append((x, y, rx, ry))
    # Herbe et mauvaises herbes dans les interstices.
    draw = ImageDraw.Draw(img)
    greens = [rgba(v) for v in ramp("#6E8A3A", 4)[1:]]
    for _ in range(count * 7):
        sx, sy, rx, ry = spots[rnd.randrange(len(spots))]
        x = sx + rnd.uniform(-1.3, 1.3) * rx
        y = sy + rnd.uniform(-1.4, 1.4) * ry
        if 4 < x < w - 4 and 6 < y < h - 2:
            for _blade in range(rnd.randint(2, 4)):
                draw.line((x, y, x + rnd.uniform(-3, 3), y - rnd.uniform(3, 7)), fill=greens[rnd.randrange(3)])
    return img


RECIPES = {
    "props/marsh_reed_wall": marsh_reed_wall,
    "props/path_edge_ferns": path_edge_ferns,
    "props/path_root_step": path_root_step,
    "props/fg_canopy_a": fg_canopy_a,
    "decals/bog_pool_a": bog_pool_a,
    "decals/path_stones_a": lambda s, r: path_stones(s, r, 5),
    "decals/path_stones_b": lambda s, r: path_stones(s, r, 2),
}

# Entrées du manifeste (tools/hd2d_manifest.json, lot R3) : chemin, taille, genre, priorité, drapeaux.
MANIFEST = [
    {"path": "assets/hd2d/props/marsh_reed_wall.png", "size": [384, 192], "kind": "panel", "prio": 1, "lot": "R3",
     "wrap": "x"},
    {"path": "assets/hd2d/props/path_edge_ferns.png", "size": [384, 106], "kind": "panel", "prio": 2, "lot": "R3",
     "wrap": "x"},
    {"path": "assets/hd2d/props/path_root_step.png", "size": [192, 58], "kind": "panel", "prio": 3, "lot": "R3"},
    {"path": "assets/hd2d/props/fg_canopy_a.png", "size": [768, 384], "kind": "panel", "prio": 1, "lot": "R3",
     "anchor": "free"},
    {"path": "assets/hd2d/decals/bog_pool_a.png", "size": [288, 192], "kind": "decal", "prio": 1, "lot": "R3"},
    {"path": "assets/hd2d/decals/path_stones_a.png", "size": [192, 144], "kind": "decal", "prio": 1, "lot": "R3"},
    {"path": "assets/hd2d/decals/path_stones_b.png", "size": [144, 96], "kind": "decal", "prio": 2, "lot": "R3"},
]
