"""(E7) Remplaçants HD-2D des navires en volume (cahier n° 6, docs/ASSETS_HD2D_ILE68_LIVRAISON6.md, lot C.1 et D.1) :
ce que le transport de la Garde demande pour descendre, s'amarrer, ouvrir sa trappe et repartir, et que le cahier n'a
pas encore livré :

- `anim/garde_transport_rotor` : rotor à deux pales de fer aux bouts rouges, vu de face, qui tourne d'un huitième de
  tour d'une image à l'autre (en quatre images, chaque pale prend la place de l'autre) ; posé sur les moyeux nus du
  flanc (`ships/garde_transport_side`) ;
- `anim/garde_transport_hatch` : la trappe ronde du flanc qui s'ouvre sous la pression (fermée, le volant tourne et la
  vapeur fuse, entrouverte, grande ouverte sur l'intérieur sombre) ; non bouclée ;
- `anim/mooring_arm_clamp` : le bras d'ancrage déployé (`props/mooring_arm_open`, dont elle dérive au pixel près) qui
  s'abaisse et referme sa pince ; le pied ne bouge pas ;
- `sky/ship_searchlight` : le cône de lumière blanche, très forte, qui précède le navire à travers les nuages (alpha
  doux, aucun navire dessiné) ; `sky/ship_glare` (hors cahier, lot E7) : l'éblouissement qui cache sa silhouette ;
- `ships/garde_transport_deck` : le pont du transport vu de dessus, proue à droite (tôles rivetées, passavants de bois,
  toit de la cabine, écoutille, caisses, bras des rotors qui dépassent des deux bords) ; posé à plat derrière le flanc
  au port, et en décalque sur la carte `transport_garde`, au-dessus de `ships/garde_transport_hull` (hors cahier, lot
  E7 : le bas du flanc, sous la ligne du pont, façade de la coque sous le pont praticable).

Une image livrée remplace le remplaçant du même nom sans toucher au code. Ces recettes sont lues par
tools/hd2d_assets.py (recipes) ; leurs entrées du manifeste sont MANIFEST ci-dessous (`python3 tools/hd2d_navires.py
manifest` les inscrit). Le résultat est déterministe (graine tirée du nom de chaque image)."""

import math

from PIL import Image, ImageChops, ImageDraw, ImageFilter

from hd2d_art import Canvas, asset, darker, mix, ramp, rgba, rotate_points, steps_alpha
from hd2d_ships import GARDE, propeller

IRON = "#3C424C"
STEEL = "#5E6878"
PLATE = "#6E7888"
DECK_WOOD = "#9A7454"
BRASS = "#B4955E"
STEAM = "#E8ECF0"


# --- Le rotor -----------------------------------------------------------------------------------------------


def garde_transport_rotor(size, rnd, frames):
    """Rotor à deux pales de fer sombre aux bouts rouges, vu de face, moyeu au centre exact ; un huitième de tour d'une
    image à l'autre."""
    return propeller(size, rnd, 2, "#3A3A42", GARDE, math.pi / 4, frames, "iron")


# --- La trappe ----------------------------------------------------------------------------------------------


def _hatch_rim(c, cx, cy, r):
    """Le cadre riveté de la trappe, collé au bord bas de l'image."""
    tones = ramp(STEEL, 5)
    c.ellipse(cx, cy, r + 9, r + 9, darker(STEEL, 0.45))
    c.ellipse(cx, cy, r + 7, r + 7, tones[1])
    c.ellipse(cx, cy, r + 4, r + 4, tones[3])
    for k in range(16):
        a = 2 * math.pi * k / 16.0
        x, y = cx + math.cos(a) * (r + 5.5), cy + math.sin(a) * (r + 5.5)
        c.rect(x - 1, y - 1, x + 2, y + 2, BRASS)
    # Le seuil de tôle sous la trappe : il touche le bord bas.
    c.rect(cx - r - 10, c.h - 10, cx + r + 10, c.h, tones[0])
    c.rect(cx - r - 10, c.h - 10, cx + r + 10, c.h - 7, tones[2])


def _hatch_door(c, cx, cy, r, squeeze, wheel_angle):
    """Le battant rond (squeeze 1 : fermé, de face ; plus petit : ouvert, vu de biais, charnière à gauche)."""
    tones = ramp(PLATE, 5)
    rx = max(3.0, r * squeeze)
    x = cx - r + rx
    c.ellipse(x, cy, rx, r, tones[1])
    c.ellipse(x - rx * 0.08, cy - r * 0.08, rx * 0.86, r * 0.86, tones[2])
    c.ellipse(x - rx * 0.12, cy - r * 0.14, rx * 0.5, r * 0.5, tones[3])
    if squeeze > 0.5:
        # Le volant de fermeture : quatre rayons qui tournent.
        wr = r * 0.42 * squeeze
        c.ellipse(x, cy, wr, wr * (1.0 if squeeze > 0.9 else 0.9), darker(BRASS, 0.5))
        c.ellipse(x, cy, wr - 3, wr - 3, tones[1])
        for k in range(4):
            a = wheel_angle + k * math.pi / 2.0
            c.line([(x, cy), (x + math.cos(a) * wr, cy + math.sin(a) * wr)], BRASS, 3)
        c.ellipse(x, cy, 5, 5, BRASS)
    else:
        c.rect(x - 1, cy - r * 0.6, x + 2, cy + r * 0.6, darker(PLATE, 0.5))


def _steam(c, cx, cy, spread, rnd):
    """Jet de vapeur en bouffées pâles (alpha franc)."""
    tones = [mix(STEAM, "#B8C0CC", 0.4), STEAM, "#FFFFFF"]
    for k in range(9):
        t = k / 8.0
        x = cx - spread * t + rnd.uniform(-4, 4)
        y = cy - spread * 0.55 * t + rnd.uniform(-4, 4)
        rr = 6 + 10 * t
        c.blob(x, y, rr, rr * 0.85, tones)


def garde_transport_hatch(size, rnd, frames):
    """La trappe ronde du flanc qui s'ouvre sous la pression : 0 fermée ; 1 le volant tourne, un jet de vapeur ;
    2 entrouverte, vapeur ; 3 grande ouverte sur l'intérieur sombre (V1). Le cadre ne bouge pas d'une image à l'autre."""
    w, h = size
    r = 58
    cx, cy = w / 2.0, h - 10 - r - 9
    out = []
    specs = [(1.0, 0.0, 0), (1.0, math.pi / 5, 46), (0.55, math.pi / 5, 34), (0.16, 0.0, 0)]
    for f in range(frames):
        squeeze, angle, spread = specs[min(f, len(specs) - 1)]
        c = Canvas(w, h, rnd)
        _hatch_rim(c, cx, cy, r)
        # L'intérieur sombre, une lueur chaude au fond (le four enchanté).
        c.ellipse(cx, cy, r, r, "#1C1A22")
        if squeeze < 1.0:
            c.ellipse(cx + r * 0.25, cy + r * 0.25, r * 0.45, r * 0.35, "#3A2A26")
            c.ellipse(cx + r * 0.3, cy + r * 0.32, r * 0.22, r * 0.14, "#7A4A2E")
        _hatch_door(c, cx, cy, r, squeeze, angle)
        if spread:
            _steam(c, cx - r * 0.4, cy - r * 0.6, spread, rnd)
            _steam(c, cx + r * 0.7, cy - r * 0.8, spread * 0.7, rnd)
        out.append(c.finish(darker(STEEL, 0.4)))
    return out


# --- Le bras d'ancrage qui se referme ---------------------------------------------------------------------------

# Le pivot du bras sur son pylône, et le pied du vérin (pixels de props/mooring_arm_open, 288 × 384).
ARM_PIVOT = (80, 104)
STRUT_FOOT = (96, 236)
# Ce qui tourne avec le bras : le disque du pivot et tout ce qui est au-dessus du fût, puis le bras à droite du fût (le
# pied et le fût du pylône restent).
ARM_REGIONS = ((44, 0, 288, 128), (110, 128, 288, 214))


def _strut_mask(img):
    """Les pixels orangés du vérin (le cuivre du bras), à redessiner à chaque image."""
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    px = img.load()
    m = mask.load()
    for y in range(110, 250):
        for x in range(84, 230):
            r, g, b, a = px[x, y]
            if a > 128 and r > 150 and 80 < g < 170 and b < 110:
                m[x, y] = 255
    return mask.filter(ImageFilter.MaxFilter(5))


def mooring_arm_clamp(size, rnd, frames):
    """Le bras d'ancrage déployé (props/mooring_arm_open, jointe) qui s'abaisse et referme sa pince sur un anneau non
    dessiné : image 3 fermée ; le pied et le pylône immobiles au pixel près."""
    w, h = size
    base = asset("props/mooring_arm_open")
    if base is None or base.size != (w, h):
        base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(base).rectangle((w // 2 - 40, h - 120, w // 2 + 40, h - 1), fill=rgba(IRON))
    strut = _strut_mask(base)
    # Le bras seul (sans le vérin), et ce qui reste fixe (sans le bras ni le vérin).
    arm_area = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(arm_area)
    for box in ARM_REGIONS:
        draw.rectangle(box, fill=255)
    arm = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    arm.paste(base, (0, 0), arm_area)
    arm.putalpha(Image.composite(Image.new("L", (w, h), 0), arm.getchannel("A"), strut))
    fixed = base.copy()
    fixed.paste((0, 0, 0, 0), (0, 0), arm_area)
    fixed.putalpha(Image.composite(Image.new("L", (w, h), 0), fixed.getchannel("A"), strut))
    # Le haut du vérin sur le bras (pixels), avant rotation.
    head = (196, 126)
    tones = ramp("#C88A3E", 5)
    out = []
    for f in range(frames):
        angle = [0.0, 6.0, 11.0, 15.0][min(f, 3)]
        if angle == 0.0:
            # L'image 0 est le bras déployé lui-même, au pixel près.
            out.append(base.copy())
            continue
        turned = arm.rotate(-angle, resample=Image.NEAREST, center=ARM_PIVOT)
        frame = fixed.copy()
        c = Canvas(w, h, rnd)
        hx, hy = rotate_points([head], ARM_PIVOT[0], ARM_PIVOT[1], math.radians(angle))[0]
        # Le vérin : un tube de cuivre du pied au bras, plus court quand le bras descend.
        c.line([STRUT_FOOT, (hx, hy)], darker("#C88A3E", 0.45), 11)
        c.line([STRUT_FOOT, (hx, hy)], tones[2], 7)
        c.line([(STRUT_FOOT[0] + 1, STRUT_FOOT[1] - 2), (hx + 1, hy - 2)], tones[4], 2)
        c.ellipse(STRUT_FOOT[0], STRUT_FOOT[1], 6, 6, IRON)
        frame.alpha_composite(c.img)
        frame.alpha_composite(turned)
        if f >= 3:
            # La pince refermée : les deux mâchoires se rejoignent sous le bout du bras.
            tip = rotate_points([(262, 150), (236, 132), (284, 128)], ARM_PIVOT[0], ARM_PIVOT[1], math.radians(angle))
            jaw = Canvas(w, h, rnd)
            jaw.poly([tip[1], tip[2], tip[0]], darker(STEEL, 0.6))
            jaw.poly([(tip[1][0] + 4, tip[1][1] + 2), (tip[2][0] - 4, tip[2][1] + 2), (tip[0][0], tip[0][1] - 5)], STEEL)
            jaw.rect(tip[0][0] - 3, tip[0][1] - 3, tip[0][0] + 4, tip[0][1] + 4, BRASS)
            frame.alpha_composite(jaw.img)
        out.append(frame)
    return out


# --- Le projecteur ---------------------------------------------------------------------------------------------


def ship_searchlight(size, rnd):
    """Cône de lumière blanche très forte qui descend à travers les nuages, plus intense en haut, qui s'élargit vers le
    bas ; bords fondus, aucun navire dessiné (V1). Alpha doux en paliers."""
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        t = y / float(h - 1)
        half = 18 + (w / 2.0 - 18) * (t ** 0.8)
        core = 1.0 - 0.72 * t
        for x in range(w):
            d = abs(x + 0.5 - w / 2.0) / half
            if d >= 1.0:
                continue
            a = core * (1.0 - d * d) ** 1.6
            # Des voiles de nuage traversés : la lumière s'y épaissit un peu.
            a *= 0.94 + 0.06 * math.sin(t * 11.0)
            warm = mix("#FFFFFF", "#FFF2D0", min(1.0, d * 1.4))
            px[x, y] = warm + (max(0, min(255, round(a * 255))),)
    blur = img.filter(ImageFilter.GaussianBlur(2))
    return steps_alpha(blur, 24)


def ship_glare(size, rnd):
    """(E7, hors cahier) L'éblouissement du projecteur autour du navire qui descend : une tache de lumière blanche,
    ovale, opaque au cœur et fondue vers les bords, qui cache sa silhouette (V1 : « si forte qu'on ne voit pas la forme
    du navire »). Alpha doux en paliers ; posée devant la coque, agrandie par la scène."""
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - w / 2.0) / (w / 2.0)
            dy = (y + 0.5 - h / 2.0) / (h / 2.0)
            d = math.sqrt(dx * dx + dy * dy)
            if d >= 1.0:
                continue
            a = (1.0 - d) ** 1.4
            color = mix("#FFFFFF", "#FFF4DC", min(1.0, d * 1.3))
            px[x, y] = color + (max(0, min(255, round(min(1.0, a * 1.5) * 255))),)
    return steps_alpha(img.filter(ImageFilter.GaussianBlur(2)), 24)


def garde_transport_hull(size, rnd):
    """(E7, hors cahier) Le bas du flanc du transport (`ships/garde_transport_side`, sous la ligne du pont : 2,5 m), la
    façade de la coque sous le pont praticable de la carte `transport_garde` ; refait d'après le flanc quand il change."""
    w, h = size
    side = asset("ships/garde_transport_side")
    if side is None or side.width != w:
        c = Canvas(w, h, rnd)
        c.poly([(w * 0.04, 0), (w * 0.97, 0), (w * 0.8, h - 1), (w * 0.12, h - 1)], STEEL)
        return c.finish(darker(STEEL, 0.4))
    return side.crop((0, side.height - h, w, side.height))


# --- Le pont vu de dessus --------------------------------------------------------------------------------------


def _deck_outline(w, h, margin):
    """Contour du pont vu de dessus, proue à droite : poupe arrondie, flancs droits, étrave en pointe."""
    top, bottom = margin, h - margin
    mid = h / 2.0
    pts = []
    stern = w * 0.035
    for k in range(13):
        a = math.pi / 2 + math.pi * k / 12.0
        pts.append((stern + 70 + math.cos(a) * 70, mid - math.sin(a) * (mid - margin)))
    pts += [(w * 0.78, bottom), (w * 0.9, bottom - (bottom - mid) * 0.35), (w - 10, mid),
            (w * 0.9, top + (mid - top) * 0.35), (w * 0.78, top)]
    return pts


def garde_transport_deck(size, rnd):
    """Le pont du transport vu de dessus (proue à droite, 16 × 5 m) : tôles d'acier rivetées gris-bleu, passavants de
    bois le long des bords, bande rouge de la Garde au bordage, bastingage, toit de la cabine au milieu, écoutille,
    caisses arrimées ; les bras des deux rotors (aux moyeux du flanc) dépassent des deux bords. Fond transparent."""
    w, h = size
    margin = 40
    c = Canvas(w, h, rnd)
    hull = _deck_outline(w, h, margin)
    plates = ramp(PLATE, 5, spread=0.35)
    # Les bras des rotors, sous la coque : ils dépassent au nord et au sud (moyeux à −2,32 et +3,30 m du milieu).
    for x_m in (-2.32, 3.30):
        x = w / 2.0 + x_m * 96
        c.rect(x - 9, 6, x + 9, h - 6, darker(STEEL, 0.6))
        c.rect(x - 6, 6, x + 6, h - 6, STEEL)
        for y in (14, h - 14):
            c.ellipse(x, y, 13, 9, darker(IRON, 0.7))
            c.ellipse(x, y, 9, 6, BRASS)
    c.poly(hull, darker(STEEL, 0.55))
    inner = [(x + (w * 0.5 - x) * 0.012, y + (h * 0.5 - y) * 0.06) for x, y in hull]
    c.poly(inner, plates[2])
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).polygon([(round(x), round(y)) for x, y in inner], fill=255)
    # Les tôles : un damier de plaques rivetées, chacune d'une valeur un peu différente.
    tile = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    t = Canvas(w, h, rnd)
    for gx in range(0, w, 96):
        for gy in range(0, h, 72):
            tone = plates[rnd.choice((1, 2, 2, 3))]
            t.rect(gx + 1, gy + 1, gx + 95, gy + 71, tone)
            for rx in (gx + 5, gx + 90):
                for ry in range(gy + 6, gy + 70, 16):
                    t.rect(rx, ry, rx + 2, ry + 2, plates[4])
    tile.alpha_composite(t.img)
    c.img.paste(tile, (0, 0), mask)
    # Les passavants de bois le long des deux bords.
    wood = ramp(DECK_WOOD, 5, spread=0.3)
    for y0, y1 in ((margin + 20, margin + 64), (h - margin - 64, h - margin - 20)):
        board = Canvas(w, h, rnd)
        for y in range(int(y0), int(y1), 8):
            board.rect(0, y, w, y + 7, wood[rnd.choice((1, 2, 3))])
            for x in range(rnd.randrange(0, 60), w, 120):
                board.rect(x, y, x + 1, y + 7, wood[0])
        band = Image.new("L", (w, h), 0)
        ImageDraw.Draw(band).rectangle((0, y0, w, y1), fill=255)
        c.img.paste(board.img, (0, 0), ImageChops.multiply(band, mask))
    # La bande rouge de la Garde au bordage, et le bastingage (main courante grise, poteaux).
    d = ImageDraw.Draw(c.img)
    d.line([(round(x), round(y)) for x, y in inner + inner[:1]], fill=rgba(GARDE), width=7)
    d.line([(round(x), round(y)) for x, y in inner + inner[:1]], fill=rgba(plates[4]), width=2)
    for k in range(0, len(inner) - 1):
        (x0, y0), (x1, y1) = inner[k], inner[k + 1]
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / 48))
        for i in range(n):
            px_, py_ = x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n
            c.rect(px_ - 2, py_ - 2, px_ + 3, py_ + 3, IRON)
    # Le toit de la cabine (tôle sombre, hublots de toit, cheminée courte), l'écoutille, les caisses, la manche à air.
    cab = (w * 0.44, h * 0.3, w * 0.66, h * 0.7)
    c.rect(cab[0] - 6, cab[1] - 6, cab[2] + 6, cab[3] + 6, darker(STEEL, 0.5))
    c.rect(cab[0], cab[1], cab[2], cab[3], plates[1])
    c.rect(cab[0] + 6, cab[1] + 6, cab[2] - 6, cab[1] + 18, plates[3])
    for k in range(4):
        x = cab[0] + 30 + k * (cab[2] - cab[0] - 60) / 3.0
        c.ellipse(x, (cab[1] + cab[3]) / 2.0, 9, 9, BRASS)
        c.ellipse(x, (cab[1] + cab[3]) / 2.0, 6, 6, "#FFE6A6")
    c.ellipse(cab[2] - 40, cab[1] + 40, 16, 16, darker(IRON, 0.7))
    c.ellipse(cab[2] - 40, cab[1] + 40, 11, 11, "#2A2A30")
    hatch = (w * 0.24, h * 0.42)
    c.rect(hatch[0] - 50, hatch[1] - 28, hatch[0] + 50, hatch[1] + 28, darker(STEEL, 0.5))
    c.rect(hatch[0] - 44, hatch[1] - 22, hatch[0] + 44, hatch[1] + 22, plates[3])
    c.ellipse(hatch[0], hatch[1], 12, 12, BRASS)
    for k, (x, y) in enumerate(((w * 0.33, h * 0.62), (w * 0.36, h * 0.62), (w * 0.33, h * 0.38))):
        c.rect(x - 22, y - 18, x + 22, y + 18, mix(DECK_WOOD, "#6A5A40", 0.4))
        c.line([(x - 22, y), (x + 22, y)], "#C8B084", 2)
        c.line([(x, y - 18), (x, y + 18)], "#C8B084", 2)
    c.ellipse(w * 0.8, h * 0.36, 18, 18, GARDE)
    c.ellipse(w * 0.8, h * 0.36, 11, 11, "#3A1E1E")
    return c.finish(darker(STEEL, 0.4))


RECIPES = {
    "anim/garde_transport_rotor": garde_transport_rotor,
    "anim/garde_transport_hatch": garde_transport_hatch,
    "anim/mooring_arm_clamp": mooring_arm_clamp,
    "sky/ship_searchlight": ship_searchlight,
    "sky/ship_glare": ship_glare,
    "ships/garde_transport_hull": garde_transport_hull,
    "ships/garde_transport_deck": garde_transport_deck,
}

# Entrées du manifeste (tools/hd2d_manifest.json) : chemin, taille, genre, priorité, lot (« C.1 » et « D.1 » : les groupes
# du cahier n° 6 ; pas les lots C et D du cahier n° 2, dont tools/hd2d_scenes.py écrit une scène par image : ces images-ci
# sont posées par les scènes des navires, src/world/props/ships/, pilotées par le code), drapeaux.
MANIFEST = [
    {"path": "assets/hd2d/anim/garde_transport_rotor.png", "size": [192, 192], "kind": "anim", "prio": 1, "lot": "C.1",
     "frames": 4, "fps": 12, "anchor": "center"},
    {"path": "assets/hd2d/anim/garde_transport_hatch.png", "size": [192, 192], "kind": "anim", "prio": 1, "lot": "C.1",
     "frames": 4, "fps": 8},
    {"path": "assets/hd2d/anim/mooring_arm_clamp.png", "size": [288, 384], "kind": "anim", "prio": 1, "lot": "C.1",
     "frames": 4, "fps": 6},
    {"path": "assets/hd2d/sky/ship_searchlight.png", "size": [384, 768], "kind": "panel", "prio": 1, "lot": "C.1",
     "soft_alpha": True, "anchor": "free"},
    {"path": "assets/hd2d/sky/ship_glare.png", "size": [576, 384], "kind": "panel", "prio": 2, "lot": "E7",
     "soft_alpha": True, "anchor": "free"},
    {"path": "assets/hd2d/ships/garde_transport_hull.png", "size": [1536, 240], "kind": "panel", "prio": 3,
     "lot": "E7"},
    {"path": "assets/hd2d/ships/garde_transport_deck.png", "size": [1536, 480], "kind": "decal", "prio": 3,
     "lot": "D.1"},
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
        print("manifeste à jour (%d images des navires)" % len(MANIFEST))
        return 0
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(new)
    print("manifeste : %d images des navires" % len(MANIFEST))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(cmd_manifest() if sys.argv[1:] == ["manifest"] else print(__doc__) or 2)
