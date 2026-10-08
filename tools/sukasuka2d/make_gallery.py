#!/usr/bin/env python3
"""Build a portable review gallery from the 2D catalog and preserved originals."""

import argparse
import html
import json
import os
from pathlib import Path
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "assets/source/resumed_2d/catalog.json"
ARCHIVE_MANIFEST = ROOT / "assets/source/legacy_2d/manifest.json"
DEFAULT_OUTPUT = ROOT / "docs/sprites/ATELIER_2D.html"
CATEGORIES = {
    "characters": "Personnages",
    "ground": "Sols",
    "cliff": "Falaises",
    "buildings": "Façades",
    "materials": "Matières",
    "props": "Objets et accessoires",
    "sky": "Ciel et horizon",
    "environments": "Décors et ambiances",
    "terrain": "Terrain et éléments modulaires",
    "enemies": "Ennemis",
}


def project_path(relative):
    """Reject absolute paths and symlink/path traversal outside this repository."""
    relative = Path(relative)
    resolved = (ROOT / relative).resolve()
    if relative.is_absolute() or not resolved.is_relative_to(ROOT):
        raise ValueError(f"Chemin hors du projet : {relative}")
    return resolved


def read_catalog():
    if not CATALOG.exists():
        return {"status": "Génération en préparation", "entries": []}
    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    if not isinstance(catalog, dict) or not isinstance(catalog.get("entries"), list):
        raise ValueError("Le catalogue doit contenir une liste entries.")
    seen = set()
    for entry in catalog["entries"]:
        identity = entry["id"]
        if identity in seen:
            raise ValueError(f"Identifiant en double : {identity}")
        seen.add(identity)
        if entry["category"] not in CATEGORIES:
            raise ValueError(f"Catégorie inconnue : {entry['category']}")
        project_path(entry["path"])
    return catalog


def read_archives():
    archives = json.loads(ARCHIVE_MANIFEST.read_text(encoding="utf-8"))
    return [dict(entry, path="assets/source/legacy_2d/" + entry["file"]) for entry in archives]


def is_archived(entry):
    """Keep earlier anime generations available alongside the unchanged originals."""
    if entry.get("archived"):
        return True
    style = str(entry.get("style", entry.get("art_style", ""))).lower()
    if "anime" in style:
        return True
    if "pixel" in style:
        return False
    status = str(entry.get("status", ""))
    return status.startswith(("archived", "superseded")) or entry["path"].startswith((
        "assets/sprites2d/generated/", "assets/source/resumed_2d/interim/"
    ))


def escaped(value):
    if isinstance(value, (list, tuple)):
        value = ", ".join(map(str, value))
    if isinstance(value, dict):
        value = json.dumps(value, ensure_ascii=False)
    return html.escape(str(value), quote=True)


def relative_url(path, destination):
    return quote(Path(os.path.relpath(path, destination.parent)).as_posix(), safe="/-._")


def card(entry, destination, archived=False):
    name = escaped(entry["name"])
    path = project_path(entry["path"])
    url = relative_url(path, destination)
    available = path.is_file()
    if available:
        visual = f'<a class="preview" href="{url}" target="_blank" rel="noopener"><img loading="lazy" src="{url}" alt="{name}"></a>'
        download = f'<a class="download" href="{url}" download>Télécharger la planche PNG</a>'
    else:
        visual = '<div class="pending">Image en préparation</div>'
        download = ""
    dimensions = entry.get("dimensions")
    size = f"{dimensions[0]} × {dimensions[1]} px" if isinstance(dimensions, (list, tuple)) and len(dimensions) == 2 else ""
    status = ("Original conservé" if entry.get("file") else "Archive anime") if archived else escaped(entry.get("status", "À examiner"))
    details = []
    for field, label in (("reference_pages", "Pages de référence"), ("character_ids", "Personnages identifiés")):
        if entry.get(field):
            details.append(f"<p class=\"metadata\"><strong>{label} :</strong> {escaped(entry[field])}</p>")
    limits = entry.get("limitations")
    if limits:
        details.append(f'<p class="limits">{escaped(limits)}</p>')
    return f'''<article class="card" data-id="{escaped(entry.get('id', entry.get('file')))}">
<header><h3>{name}</h3><span class="badge">{status}</span></header>
{visual}<p>{escaped(entry.get('description', ''))}</p>
{''.join(details)}<footer><span class="metadata">{size}</span>{download}</footer></article>'''


STYLE = """
:root{color-scheme:light;font:16px/1.55 system-ui,sans-serif;color:#20314a;background:#f0f3f7}*{box-sizing:border-box}body{margin:0}main{max-width:1500px;padding:clamp(16px,3vw,44px);margin:auto}h1{font-size:clamp(27px,4vw,43px);line-height:1.15}h2{font-size:27px}h3{margin:0;font-size:20px}a{color:#315f9b}nav,.filters{display:flex;gap:10px;flex-wrap:wrap;margin:25px 0}nav a,.filters button,.download{display:inline-block;background:white;border:1px solid #b4c2d3;border-radius:7px;padding:8px 12px;text-decoration:none}.filters button{font:inherit;color:#315f9b;cursor:pointer}.filters button[aria-pressed=true]{background:#315f9b;color:white;border-color:#315f9b}.intro{max-width:960px}.note{border-left:4px solid #5d83b5;padding:12px 18px;background:#e3edf9}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,350px),1fr));gap:22px}.card{display:flex;flex-direction:column;border:1px solid #d5deea;border-radius:12px;background:white;padding:18px;min-width:0}.card header{margin-bottom:14px}.badge{display:inline-block;font-size:13px;color:#425c7e;background:#eef3f9;border-radius:5px;margin-top:7px;padding:3px 7px}.preview{display:block}.card img,.pending{display:block;width:100%;height:340px;object-fit:contain;border-radius:7px;background-color:#fafafa;background-image:linear-gradient(45deg,#e2e6eb 25%,transparent 25%),linear-gradient(-45deg,#e2e6eb 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#e2e6eb 75%),linear-gradient(-45deg,transparent 75%,#e2e6eb 75%);background-size:24px 24px;background-position:0 0,0 12px,12px -12px,-12px 0}.pending{display:flex;align-items:center;justify-content:center;color:#5b6a80}.metadata,.limits{font-size:14px;color:#52637a;overflow-wrap:anywhere}.limits{border-left:3px solid #c9a359;padding-left:10px}.card footer{display:flex;gap:12px;align-items:center;justify-content:space-between;flex-wrap:wrap;margin-top:auto;padding-top:12px}.card .download{font-size:14px}section{margin:40px 0;scroll-margin-top:20px}section[hidden]{display:none}.count{font-weight:400;color:#687991;font-size:18px}.footer{font-size:14px;color:#52637a;margin-top:35px}@media(max-width:480px){.card img,.pending{height:280px}.card{padding:14px}}
"""

FILTER_SCRIPT = """
document.querySelectorAll('[data-filter]').forEach(button => {
  button.addEventListener('click', () => {
    const category = button.dataset.filter;
    document.querySelectorAll('[data-filter]').forEach(other => {
      other.setAttribute('aria-pressed', String(other === button));
    });
    document.querySelectorAll('section[data-category]').forEach(section => {
      section.hidden = category !== 'all' && section.dataset.category !== category;
    });
    document.getElementById('filter-status').textContent = 'Affichage : ' + button.textContent;
  });
});
document.querySelectorAll('nav a').forEach(link => {
  link.addEventListener('click', () => document.querySelector('[data-filter="all"]').click());
});
"""


def build(destination=DEFAULT_OUTPUT):
    destination = Path(destination).resolve()
    catalog = read_catalog()
    archives = read_archives() + [entry for entry in catalog["entries"] if is_archived(entry)]
    active_entries = [entry for entry in catalog["entries"] if not is_archived(entry)]
    sections = []
    navigation = []
    filters = ['<button type="button" data-filter="all" aria-pressed="true">Tout afficher</button>']
    for category, label in CATEGORIES.items():
        entries = [entry for entry in active_entries if entry["category"] == category]
        if not entries:
            continue
        navigation.append(f'<a href="#{category}">{label} · {len(entries)}</a>')
        filters.append(f'<button type="button" data-filter="{category}" aria-pressed="false">{label}</button>')
        cards = "\n".join(card(entry, destination) for entry in entries)
        sections.append(f'<section id="{category}" data-category="{category}"><h2>{label} <span class="count">({len(entries)})</span></h2><div class="grid">{cards}</div></section>')
    navigation.append(f'<a href="#archives">Archives anime · {len(archives)}</a>')
    filters.append('<button type="button" data-filter="archives" aria-pressed="false">Archives anime</button>')
    archive_cards = "\n".join(card(entry, destination, archived=True) for entry in archives)
    sections.append(f'<section id="archives" data-category="archives"><h2>Archives anime · Premières planches 2D <span class="count">({len(archives)})</span></h2><p>Les onze PNG d’origine et les générations anime suivantes sont conservés sans modification, avec leurs limites de découpage documentées. Ils restent téléchargeables ; la nouvelle livraison suit le cahier pixel art HD-2D.</p><div class="grid">{archive_cards}</div></section>')
    catalog_link = f'<a href="{relative_url(CATALOG, destination)}">Catalogue des nouvelles planches</a> · ' if CATALOG.exists() else ""
    document = f'''<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Yume-WorldEnd · Atelier 2D</title><style>{STYLE}</style></head>
<body><main><h1>Yume-WorldEnd · Atelier HD-2D</h1>
<p class="intro">Nouveaux personnages, décors et accessoires en pixel art selon ASSETS_HD2D. Les premières planches anime restent dans les archives. Chaque image s’ouvre en taille native et peut être téléchargée séparément.</p>
<p class="note">Les planches sont des images 2D. Le statut et les limites de chaque image indiquent les vérifications nécessaires avant son utilisation en jeu. Le quadrillage affiche la transparence du PNG.</p>
<p class="metadata">État du catalogue : {escaped(catalog.get('status', 'À examiner'))}</p>
<div class="filters" role="group" aria-label="Filtrer les catégories">{''.join(filters)}</div><p id="filter-status" class="metadata" aria-live="polite">Affichage : Tout afficher</p>
<nav aria-label="Aller à une catégorie">{''.join(navigation)}</nav>{''.join(sections)}
<footer class="footer"><p>{catalog_link}<a href="{relative_url(ARCHIVE_MANIFEST, destination)}">Manifeste des premières planches</a></p><p>Designs SukaSuka à partir des références fournies. Les scans de référence ne sont pas inclus dans cette galerie.</p></footer>
</main><script>{FILTER_SCRIPT}</script></body></html>'''
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(document, encoding="utf-8")
    available = sum(project_path(entry["path"]).is_file() for entry in catalog["entries"])
    print(f"{destination}: {available}/{len(catalog['entries'])} images du catalogue disponibles, {len(archives)} archives anime")
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    build(args.output)


if __name__ == "__main__":
    main()
