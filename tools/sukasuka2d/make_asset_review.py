#!/usr/bin/env python3
"""Build an isolated HTML review from the actual corrected runtime assets."""

import argparse
import base64
import html
import io
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "docs/sprites/CORRECTIONS_ASSETS.html"


def image_uri(data):
    return "data:image/png;base64," + base64.b64encode(data).decode("ascii")


def pose_uri(identifier, direction, animation, index=0):
    suffix = "" if direction == "right" else "_" + direction
    path = ROOT / f"assets/characters/{identifier}/{identifier}{suffix}.png"
    metadata = json.loads(path.with_suffix(".json").read_text())
    x, y, width, height = metadata["animations"][animation]["images"][index][:4]
    with Image.open(path) as sheet:
        pose = sheet.crop((x, y, x + width, y + height))
    data = io.BytesIO()
    pose.save(data, format="PNG", optimize=True)
    return image_uri(data.getvalue()), height


def build(destination=DEFAULT_OUTPUT):
    sections = []
    for identifier, title, explanation in [
        ("nephren", "Nephren — prise d’Insania",
         "Les deux mains tiennent le manche derrière la garde. Les quatre poses d’attaque sont présentées dans les trois orientations."),
        ("ithea", "Ithea — Carillon Valgulious",
         "La lame droite s’élargit vers l’extrémité arrondie. Cheveux blond paille, perles bleues, écharpe rouge, veste vert pâle et robe brun-rouge suivent les détails de la bible fournis."),
    ]:
        groups = []
        for direction, label in [("front", "Face"), ("back", "Dos"), ("right", "Profil droit")]:
            suffix = "" if direction == "right" else "_" + direction
            path = ROOT / f"assets/characters/{identifier}/{identifier}{suffix}.png"
            metadata_path = path.with_suffix(".json")
            metadata = json.loads(metadata_path.read_text())
            with Image.open(path) as sheet:
                frames = []
                for index, rectangle in enumerate(metadata["animations"]["attaque"]["images"]):
                    x, y, width, height = rectangle[:4]
                    crop = sheet.crop((x, y, x + width, y + height))
                    data = io.BytesIO()
                    crop.save(data, format="PNG", optimize=True)
                    frames.append(f'<figure><img src="{image_uri(data.getvalue())}" '
                                  f'alt="{identifier} {direction} attaque {index + 1}">'
                                  f'<figcaption>Pose {index + 1}</figcaption></figure>')
            native = image_uri(path.read_bytes())
            json_uri = "data:application/json;base64," + base64.b64encode(metadata_path.read_bytes()).decode("ascii")
            groups.append(f'<h3>{label}</h3><div class="poses">{"".join(frames)}</div>'
                          f'<details><summary>Atlas complet et données d’animation — {label}</summary>'
                          f'<img class="sheet" src="{native}" alt="Atlas {identifier} {direction}">'
                          f'<p><a class="native-download" data-image href="#" download="{path.name}">Télécharger le PNG</a> · '
                          f'<a href="{json_uri}" download="{metadata_path.name}">Télécharger le JSON</a></p></details>')
        sections.append(f'<section><h2>{title}</h2><p>{explanation}</p>{"".join(groups)}</section>')
    identities = []
    for identifier, title, detail in [
        ("lakhesh", "Lakhesh", "Cheveux pêche, petite couette latérale et gilet brun clouté."),
        ("nygglatho", "Nygglatho", "Chemisier vert vif à volants ; coiffe et tablier blancs."),
        ("collon", "Collon", "Bandeau rouge et canine visible dans les expressions."),
        ("pannibal", "Pannibal", "Épée de bois et brindille."),
        ("limeskin", "Limeskin", "Cornes, tresse à plumes et collier tribal."),
    ]:
        poses = []
        for direction, label in [("front", "Face"), ("back", "Dos"), ("right", "Profil")]:
            uri, height = pose_uri(identifier, direction, "repos")
            poses.append(f'<figure><img src="{uri}" alt="{identifier} repos {direction}"><figcaption>{label} · {height} px</figcaption></figure>')
        portrait = ROOT / f"assets/characters/{identifier}/{identifier}_portrait.png"
        poses.append(f'<figure><img src="{image_uri(portrait.read_bytes())}" alt="Portrait {identifier}"><figcaption>Portrait</figcaption></figure>')
        identities.append(f'<h3>{title}</h3><p>{detail}</p><div class="poses">{"".join(poses)}</div>')
    sections.append('<section><h2>Détails des personnages</h2>' + "".join(identities) + '</section>')
    repairs = []
    for identifier, animation, indices, label in [
        ("nygglatho", "marche", [0], "Nygglatho — premier pas de profil"),
        ("cat_waiter", "course", [0, 1, 2, 3], "Serveur — course de profil"),
        ("baker", "parle", [0, 1], "Boulanger — dialogue de profil"),
        ("knight_feline", "parle", [0, 1], "Chevalier félin — dialogue de profil"),
    ]:
        poses = []
        for index in indices:
            uri, height = pose_uri(identifier, "right", animation, index)
            poses.append(f'<figure><img src="{uri}" alt="{identifier} {animation} {index + 1}"><figcaption>Pose {index + 1} · {height} px</figcaption></figure>')
        repairs.append(f'<h3>{label}</h3><div class="poses">{"".join(poses)}</div>')
    sections.append('<section><h2>Corrections des poses</h2>' + "".join(repairs) + '</section>')
    scenery = []
    for relative, label in [
        ("sky/distant_island_b.png", "Île B — village lointain, détourage nettoyé"),
        ("sky/distant_island_c.png", "Île C — rocher, détourage nettoyé"),
        ("buildings/materials/wall_plaster.png", "Enduit crème sans grille de colombages"),
    ]:
        path = ROOT / "assets/hd2d" / relative
        scenery.append(f'<figure><img class="capture" src="{image_uri(path.read_bytes())}" '
                       f'alt="{html.escape(label)}"><figcaption>{label}</figcaption>'
                       f'<p><a data-figure-image href="#" download="{path.name}">Télécharger le PNG</a></p></figure>')
        if relative.endswith("wall_plaster.png"):
            with Image.open(path) as tile:
                repeated = Image.new("RGBA", (tile.width * 3, tile.height * 3))
                for y in range(3):
                    for x in range(3):
                        repeated.paste(tile, (x * tile.width, y * tile.height))
            data = io.BytesIO()
            repeated.save(data, format="PNG", optimize=True)
            scenery.append(f'<figure><img class="capture" src="{image_uri(data.getvalue())}" alt="Enduit répété 3 par 3"><figcaption>Répétition 3 × 3</figcaption></figure>')
    sections.append('<section><h2>Îles et enduit</h2>' + "".join(scenery) + '</section>')
    captures = []
    for filename, title in [
        ("nephren-attaque-directions.png", "Nephren — rendu des 12 poses dans Godot"),
        ("ithea-attaque-directions.png", "Ithea — rendu des 12 poses dans Godot"),
        ("priorite1-cour.png", "Cour de l’entrepôt — rendu Godot"),
        ("priorite2-marais.png", "Marais — rendu Godot"),
        ("priorite3-port.png", "Port — rendu Godot"),
    ]:
        path = ROOT / "docs/sprites/previews" / filename
        if path.exists():
            captures.append(f'<figure><img class="capture" src="{image_uri(path.read_bytes())}" '
                            f'alt="{html.escape(title)}"><figcaption>{title}</figcaption></figure>')
    document = '''<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="data:,"><title>Yume-WorldEnd · Corrections des assets</title>
<style>body{margin:0;background:#242333;color:#eee;font:16px/1.6 system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:24px}h1,h2{color:#ffe5a8}section{border-top:1px solid #555;margin-top:40px;padding-top:20px}.poses{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px}figure{margin:0;text-align:center}figure img{width:100%;height:310px;object-fit:contain;image-rendering:pixelated;background:#343447}figcaption{padding:8px}.sheet{display:block;max-width:100%;max-height:900px;image-rendering:pixelated;margin-top:16px}.capture{height:auto;width:100%;image-rendering:auto;margin-top:20px}a{color:#b4d5ff}details{margin:16px 0;padding:12px;background:#343447}summary{cursor:pointer}.note{background:#343447;padding:14px;border-left:3px solid #d6b66c}@media(max-width:600px){main{padding:14px}.poses{grid-template-columns:repeat(2,minmax(0,1fr))}figure img{height:240px}.capture{height:auto}}</style></head><body><main>
<h1>Yume-WorldEnd · Corrections des assets</h1>
<p>Les poses ci-dessous sont découpées dans les PNG et JSON utilisés par le jeu.</p>
<p class="note">Cette page contient ses images et ses téléchargements. Elle fonctionne seule, sans accès au dépôt. Les sources précédentes restent conservées. La fluidité des cycles et les ancres des pieds restent à valider visuellement.</p>
''' + "".join(sections) + '<section><h2>Captures du projet</h2>' + "".join(captures) + '''</section></main>
<script>document.querySelectorAll('[data-image]').forEach(link=>{link.href=link.closest('details').querySelector('img').src;});document.querySelectorAll('[data-figure-image]').forEach(link=>{link.href=link.closest('figure').querySelector('img').src;});</script>
</body></html>'''
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(document, encoding="utf-8")
    print(f"{destination}: 24 poses d’attaque, 6 atlas PNG/JSON, {len(captures)} captures, {destination.stat().st_size / 1e6:.1f} Mo")
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    build(args.output)


if __name__ == "__main__":
    main()
