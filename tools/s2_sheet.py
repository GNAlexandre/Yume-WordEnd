#!/usr/bin/env python3
"""(S2) Planches contact des captures de scènes : tools/s2_sheet.py <dossier d'images> [colonnes] [lignes].

Écrit <dossier>/planche_NN.png : les images (triées par nom) en vignettes de 640 × 360, avec leur
nom en légende ; une planche par page de colonnes × lignes vignettes (4 × 3 par défaut).
Usage (Python 3.9+, Pillow)."""

import os
import sys

from PIL import Image, ImageDraw

THUMB = (640, 360)
CAPTION = 18


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    folder = sys.argv[1]
    cols = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    rows = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    names = sorted(
        n for n in os.listdir(folder) if n.endswith(".png") and not n.startswith("planche_")
    )
    per_page = cols * rows
    pages = 0
    for start in range(0, len(names), per_page):
        chunk = names[start : start + per_page]
        sheet = Image.new("RGB", (cols * THUMB[0], rows * (THUMB[1] + CAPTION)), (20, 16, 28))
        draw = ImageDraw.Draw(sheet)
        for i, name in enumerate(chunk):
            image = Image.open(os.path.join(folder, name)).convert("RGB").resize(THUMB)
            x = (i % cols) * THUMB[0]
            y = (i // cols) * (THUMB[1] + CAPTION)
            sheet.paste(image, (x, y + CAPTION))
            draw.text((x + 4, y + 3), name[:-4], fill=(240, 230, 200))
        pages += 1
        sheet.save(os.path.join(folder, "planche_%02d.png" % pages))
    print("%d images, %d planches dans %s" % (len(names), pages, folder))
    return 0


if __name__ == "__main__":
    sys.exit(main())
