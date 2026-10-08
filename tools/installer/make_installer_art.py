#!/usr/bin/env python3
"""Images de l'installateur Windows (bureau, docs/bureau.md), tirées de l'image du jeu.

- tools/installer/wordend.ico : l'icône du jeu (assets/ui/icon.png) en six tailles, celles
  qu'attend l'export Windows de Godot 4.7 (16, 32, 48, 64, 128 et 256 px ; s'il en manque une,
  l'export avertit « Icon size … is missing », et les avertissements sont des erreurs). Elle sert
  d'icône à WordEnd.exe (export_presets.cfg, application/icon), à l'installateur et au
  désinstalleur, aux raccourcis du menu Démarrer et du Bureau, et à la ligne d'« Applications et
  fonctionnalités » (tools/installer/wordend.nsi). Chaque taille est réduite depuis l'image
  256 × 256 (Lanczos) et rangée en PNG dans l'ICO (Windows Vista et suivants).
- tools/installer/welcome.bmp : le bandeau des pages d'accueil et de fin de l'installateur
  (164 × 314, taille de l'interface « Modern UI » de NSIS), découpé dans l'écran de démarrage
  (assets/ui/boot_splash.png : le couchant et l'épée plantée), en BMP 24 bits.

Résultat déterministe ; les fichiers sont versionnés (tools/installer/.gdignore : Godot ne les
importe pas). À relancer quand assets/ui/icon.png ou boot_splash.png changent
(tests/unit/test_desktop.gd compare l'icône) :

    python3 tools/installer/make_installer_art.py
"""

import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ICON_SOURCE = os.path.join(ROOT, "assets", "ui", "icon.png")
SPLASH_SOURCE = os.path.join(ROOT, "assets", "ui", "boot_splash.png")
HERE = os.path.join(ROOT, "tools", "installer")
ICON_TARGET = os.path.join(HERE, "wordend.ico")
WELCOME_TARGET = os.path.join(HERE, "welcome.bmp")
SIZES = [16, 32, 48, 64, 128, 256]
WELCOME_SIZE = (164, 314)
# Abscisse de l'épée dans l'écran de démarrage (1280 × 720) : centre du bandeau.
SWORD_X = 0.52


def make_icon():
    source = Image.open(ICON_SOURCE).convert("RGBA")
    if source.size != (256, 256):
        source = source.resize((256, 256), Image.Resampling.LANCZOS)
    frames = [source.resize((size, size), Image.Resampling.LANCZOS) for size in SIZES[:-1]]
    source.save(
        ICON_TARGET,
        format="ICO",
        sizes=[(size, size) for size in SIZES],
        append_images=frames,
    )
    print(ICON_TARGET, ", ".join("%d" % size for size in SIZES))


def make_welcome():
    splash = Image.open(SPLASH_SOURCE).convert("RGB")
    width, height = splash.size
    crop_width = round(height * WELCOME_SIZE[0] / WELCOME_SIZE[1])
    left = min(max(round(width * SWORD_X - crop_width / 2), 0), width - crop_width)
    strip = splash.crop((left, 0, left + crop_width, height))
    strip = strip.resize(WELCOME_SIZE, Image.Resampling.LANCZOS)
    strip.save(WELCOME_TARGET, format="BMP")
    print(WELCOME_TARGET, "%d × %d" % WELCOME_SIZE)


def main():
    make_icon()
    make_welcome()


if __name__ == "__main__":
    main()
