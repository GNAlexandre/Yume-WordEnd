#!/usr/bin/env python3
"""Icône du jeu et écran de démarrage (intégration M2) : couchant sur les dunes, épée plantée.

Mêmes couleurs que le shell HTML (web/shell.html, dégradé de #status) et l'écran de chargement
(src/ui/loading.gd) : ciel violet → corail → or, soleil, trois rangs de dunes, pétales de sakura.
L'épée plantée dans la dune évoque Seniorious (l'image ne porte aucun texte). Dessin
suréchantillonné (×4) puis réduit : contours lisses. Résultat déterministe ; les PNG sont
versionnés et branchés dans project.godot :
application/config/icon (aussi l'icône de l'export Web : index.icon.png, apple-touch-icon) et
application/boot_splash/image (fond #1b1231, comme le shell).

Usage (Python 3.9+, pip install Pillow) :

    python3 tools/gen_branding.py                  # assets/ui/icon.png et boot_splash.png
    python3 tools/gen_branding.py --out /tmp/brand # ailleurs (aperçu)
"""

import argparse
import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUPERSAMPLE = 4
ICON_SIZE = 256
SPLASH_SIZE = (1280, 720)

# Ciel du shell (web/shell.html) : position verticale (0..1) → couleur.
SKY = [
    (0.00, (0x29, 0x21, 0x4F)),
    (0.34, (0x6E, 0x2F, 0x57)),
    (0.52, (0xC4, 0x47, 0x3F)),
    (0.62, (0xF3, 0x88, 0x3C)),
    (0.70, (0xFE, 0xCE, 0x55)),
]
SUN = (0xFF, 0xDF, 0x78)
DUNES = [(0xA8, 0x3D, 0x2B), (0x84, 0x1F, 0x1D), (0x4A, 0x0F, 0x12)]
PETAL = (0xF3, 0xA6, 0xC8)
OUTLINE = (0x2A, 0x12, 0x40)
BLADE = (0xF4, 0xEC, 0xFF)
BLADE_SHADE = (0xC9, 0xBC, 0xE6)
GUARD = (0xFF, 0xCD, 0x60)
GRIP = (0x6B, 0x3F, 0x8F)
BACKGROUND = (0x1B, 0x12, 0x31)


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def sky_color(v):
    """Couleur du ciel à la hauteur relative v (0 = haut)."""
    if v <= SKY[0][0]:
        return SKY[0][1]
    for (v0, c0), (v1, c1) in zip(SKY, SKY[1:]):
        if v <= v1:
            return lerp(c0, c1, (v - v0) / (v1 - v0))
    return SKY[-1][1]


def gradient(width, height, top, bottom):
    """Image du ciel entre les hauteurs relatives top et bottom de la scène."""
    image = Image.new("RGBA", (width, height))
    draw = ImageDraw.Draw(image)
    for y in range(height):
        color = sky_color(top + (bottom - top) * y / max(height - 1, 1))
        draw.line([(0, y), (width, y)], fill=color + (255,))
    return image


def dune(width, height, base, amplitude, waves, phase):
    """Silhouette d'une dune : liste de points (sommet sinusoïdal, bas de l'image)."""
    points = []
    steps = 96
    for s in range(steps + 1):
        t = s / steps
        y = base + amplitude * math.sin(2 * math.pi * waves * t + phase)
        points.append((width * t, height * y))
    points += [(width, height), (0, height)]
    return points


def petal(draw, cx, cy, r, angle, color):
    """Pétale de sakura : ellipse pointue tournée de angle radians."""
    points = []
    for i in range(48):
        t = 2 * math.pi * i / 48
        x = math.cos(t) * r
        y = math.sin(t) * r * 0.55 * (1.0 - 0.35 * math.cos(t))
        points.append(
            (
                cx + x * math.cos(angle) - y * math.sin(angle),
                cy + x * math.sin(angle) + y * math.cos(angle),
            )
        )
    draw.polygon(points, fill=color + (235,))


def sword(draw, tip, length, width, angle, outline_width):
    """Épée plantée, pointe en tip (enfouie), lame vers le haut, tournée de angle radians."""
    ux, uy = math.sin(angle), -math.cos(angle)  # vers le haut de la lame
    px, py = -uy, ux  # perpendiculaire

    def at(along, across):
        return (tip[0] + ux * along + px * across, tip[1] + uy * along + py * across)

    blade = [
        at(0, 0),
        at(length * 0.08, -width / 2),
        at(length * 0.78, -width / 2),
        at(length * 0.78, width / 2),
        at(length * 0.08, width / 2),
    ]
    shade = [at(length * 0.08, 0), at(length * 0.78, 0), at(length * 0.78, width / 2),
             at(length * 0.08, width / 2)]
    guard = [
        at(length * 0.78, -width * 2.1),
        at(length * 0.83, -width * 2.1),
        at(length * 0.83, width * 2.1),
        at(length * 0.78, width * 2.1),
    ]
    grip = [
        at(length * 0.83, -width * 0.33),
        at(length * 0.96, -width * 0.33),
        at(length * 0.96, width * 0.33),
        at(length * 0.83, width * 0.33),
    ]
    pommel = at(length, 0)
    for shape, fill in ((blade, BLADE), (guard, GUARD), (grip, GRIP)):
        draw.polygon(shape, fill=fill + (255,))
        draw.line(shape + shape[:1], fill=OUTLINE + (255,), width=outline_width, joint="curve")
    draw.polygon(shade, fill=BLADE_SHADE + (255,))
    r = width * 0.62
    box = [pommel[0] - r, pommel[1] - r, pommel[0] + r, pommel[1] + r]
    draw.ellipse(box, fill=GUARD + (255,), outline=OUTLINE + (255,), width=outline_width)
    # Reflet le long de la lame.
    draw.line([at(length * 0.12, -width * 0.22), at(length * 0.74, -width * 0.22)],
              fill=(255, 255, 255, 200), width=max(1, outline_width // 2))


def sun(image, cx, cy, r):
    """Soleil et halo (cercles translucides flous)."""
    halo = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(halo)
    for k in range(4):
        rr = r * (1.45 + 0.45 * k)
        draw.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=SUN + (28,))
    halo = halo.filter(ImageFilter.GaussianBlur(r * 0.25))
    image.alpha_composite(halo)
    ImageDraw.Draw(image).ellipse([cx - r, cy - r, cx + r, cy + r], fill=SUN + (255,))


def scene(width, height, sword_scale, petals):
    """Couchant sur les dunes avec l'épée : image RGBA width × height (déjà suréchantillonnée)."""
    image = gradient(width, height, 0.0, 1.0)
    sun(image, width * 0.5, height * 0.655, height * 0.115)
    draw = ImageDraw.Draw(image)
    layers = [(0.70, 0.030, 1.3, 0.0), (0.79, 0.040, 0.9, 1.7), (0.90, 0.035, 1.6, 3.4)]
    for index, (base, amplitude, waves, phase) in enumerate(layers):
        draw.polygon(dune(width, height, base, amplitude, waves, phase), fill=DUNES[index] + (255,))
        if index == 0:
            # Plantée dans la dune du milieu (dessinée ensuite) : sa pointe est cachée dessous.
            length = height * 0.62 * sword_scale
            sword(
                draw,
                (width * 0.5 - length * 0.02, height * 0.8),
                length,
                length * 0.085,
                math.radians(9),
                max(2, round(length * 0.012)),
            )
    for cx, cy, r, angle in petals:
        petal(draw, width * cx, height * cy, height * r, angle, PETAL)
    return image


def icon(size):
    """Icône carrée aux coins arrondis."""
    big = size * SUPERSAMPLE
    art = scene(
        big,
        big,
        1.05,
        [(0.2, 0.22, 0.035, 0.6), (0.79, 0.3, 0.03, 2.2), (0.68, 0.12, 0.025, 1.1)],
    )
    mask = Image.new("L", (big, big), 0)
    radius = round(big * 0.22)
    margin = round(big * 0.02)
    ImageDraw.Draw(mask).rounded_rectangle(
        [margin, margin, big - margin - 1, big - margin - 1], radius=radius, fill=255
    )
    result = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    result.paste(art, (0, 0), mask)
    ImageDraw.Draw(result).rounded_rectangle(
        [margin, margin, big - margin - 1, big - margin - 1],
        radius=radius,
        outline=BACKGROUND + (255,),
        width=round(big * 0.018),
    )
    return result.resize((size, size), Image.LANCZOS)


def splash(width, height):
    """Écran de démarrage plein cadre (étiré en « Cover » par Godot)."""
    big = (width * SUPERSAMPLE, height * SUPERSAMPLE)
    art = scene(
        big[0],
        big[1],
        0.85,
        [
            (0.12, 0.18, 0.012, 0.4),
            (0.27, 0.42, 0.009, 2.0),
            (0.71, 0.24, 0.011, 1.2),
            (0.86, 0.47, 0.008, 2.8),
            (0.58, 0.1, 0.007, 0.9),
        ],
    )
    return art.resize((width, height), Image.LANCZOS).convert("RGB")


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", default=os.path.join(ROOT, "assets", "ui"))
    args = parser.parse_args()
    os.makedirs(args.out, exist_ok=True)
    targets = {
        "icon.png": icon(ICON_SIZE),
        "boot_splash.png": splash(*SPLASH_SIZE),
    }
    for name, image in targets.items():
        path = os.path.join(args.out, name)
        image.save(path, optimize=True)
        print(path, image.size)


if __name__ == "__main__":
    main()
