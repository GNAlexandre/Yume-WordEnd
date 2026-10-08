#!/usr/bin/env python3
"""Check and package a priority batch with actual atlas JSON and provenance."""

import argparse
import hashlib
import importlib.util
import json
import zipfile
from collections import Counter
from pathlib import Path

import make_gallery as gallery

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("hd", ROOT / "tools/hd2d_assets.py")
HD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HD)


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def build(priority, output, include_native=False):
    manifest = HD.load_manifest()
    # Optional effects are produced procedurally by the game. Never claim a
    # missing optional image has been supplied; keep them in the main manifest.
    entries = [e for e in manifest["entries"] if e.get("priority") == priority
               and (e.get("required", True) or (ROOT / e["path"]).is_file())]
    manifest = {**manifest, "entries": entries, "scope": f"HD-2D priority {priority} batch"}
    report = HD.check_assets(ROOT, manifest)
    report_path = ROOT / f"build/hd2d-priority{priority}-check.json"
    write_json(report_path, report)
    if not report["ok"]:
        bad = [f["path"] + ": " + "; ".join(f["errors"]) for f in report["files"] if f["errors"]]
        raise ValueError("Batch not ready: " + "; ".join(report["errors"] + bad))
    manifest_path = ROOT / f"tools/hd2d_priority{priority}_manifest.json"
    write_json(manifest_path, manifest)
    catalog = gallery.read_catalog()
    selected = []
    for e in entries:
        matches = [c for c in catalog["entries"] if c["path"] == e["path"]]
        if not matches:
            raise ValueError("Missing provenance: " + e["path"])
        selected.append(matches[-1])
    json_count = sum(bool(e.get("json_path")) for e in entries)
    catalog_path = ROOT / f"assets/source/resumed_2d/priority{priority}_catalog.json"
    write_json(catalog_path, {"priority": priority, "status": "Livré — contrôle technique réussi ; revue visuelle des cycles et ancres ouverte",
                             "entries": selected, "technical_check": report})
    destination = ROOT / f"docs/sprites/PRIORITE_{priority}.html"
    original_catalog, original_read_archives = gallery.CATALOG, gallery.read_archives
    gallery.CATALOG, gallery.read_archives = catalog_path, lambda: []
    try:
        gallery.build(destination)
    finally:
        gallery.CATALOG, gallery.read_archives = original_catalog, original_read_archives
    html = destination.read_text().replace("Yume-WorldEnd · Atelier HD-2D", f"Yume-WorldEnd · Priorité {priority}")
    html = html.replace("Les onze PNG d’origine et les générations anime suivantes sont conservés sans modification, avec leurs limites de découpage documentées. Ils restent téléchargeables ; la nouvelle livraison suit le cahier pixel art HD-2D.",
                        "Les dessins anime sont conservés dans le projet. Cette archive contient un lot de pixel art distinct.")
    html = html.replace('<a href="../../assets/source/legacy_2d/manifest.json">Manifeste des premières planches</a>', '')
    destination.write_text(html)
    guide_path = ROOT / f"docs/sprites/LIVRAISON_PRIORITE_{priority}.md"
    counts = Counter(e["kind"] for e in entries)
    names = sorted({c for e in selected for c in e.get("character_ids", [])})
    guide_path.write_text(f"""# Livraison HD-2D — priorité {priority}

{len(entries)} PNG, {json_count} JSON d'animation, {report['total_image_bytes'] / 1e6:.1f} Mo de textures.
Personnages : {', '.join(names)}.
Types : {dict(counts)}.

Ouvrir `PRIORITE_{priority}.html` après extraction du ZIP. Copier `assets/` et
`data/visuals2d/characters/` dans le projet en conservant les chemins. Les atlas
de face et dos complètent le profil droit ; le côté gauche est un miroir.
Les PNJ ont repos, marche, course et dialogue. Les combattants ont aussi
attaque, charge, dégâts et chute ; les PNJ ordinaires ne reçoivent pas de combat.
Les portraits mesurent 256 × 256 px. Les JSON décrivent les poses réellement
dessinées, leurs rectangles, cadence, boucles et marqueurs de combat.

Le contrôle technique est strict sur ce lot : aucun fichier requis manquant,
dimensions et densité prévues, alpha binaire, rectangles d'atlas et raccords
des bords. Chaque PNG pèse moins de 1 Mo. Les ancres calculées et cycles restent
signalés pour revue visuelle ; ce contrôle ne certifie pas la qualité artistique.
Les textures répétées doivent aussi être inspectées en contexte.

Les priorités viennent des tableaux de `ASSETS_HD2D.md`. Les orientations et
portraits héritent de celle du personnage. Les personnages et objets demandés
en complément sont des adaptations de travail, sans inventer une liste canonique
issue de HISTOIRE.md. Les effets facultatifs restent procéduraux dans le jeu.
Les sources natives et les premiers dessins anime sont conservés dans le dépôt.

```sh
python tools/hd2d_assets.py --manifest tools/hd2d_priority{priority}_manifest.json check
python tools/sukasuka2d/make_priority_package.py --priority {priority}
```

Le budget de 25 Mo est vérifié pour chaque lot de textures. La bibliothèque
complète couvre plusieurs lots et dépasse ce poids ; l'export Web ne contient
que les personnages utilisés dans ses scènes et possède son propre contrôle
de taille. Une archive de lot n'est pas un export du jeu complet.
""")
    files = {ROOT / e["path"] for e in entries} | {manifest_path, destination, catalog_path, guide_path}
    files.update(ROOT / e["json_path"] for e in entries if e.get("json_path"))
    for name in names:
        resource = ROOT / f"data/visuals2d/characters/{name}/{name}.tres"
        if not resource.exists():
            raise ValueError("Runtime character resource missing: " + name)
        files.add(resource)
    for relative in ["src/visuals/skin_data.gd", "tools/hd2d_assets.py", "tools/sukasuka2d/make_priority_package.py",
                     "tools/sukasuka2d/make_gallery.py", "docs/ASSETS_HD2D.md", "assets/CREDITS.md"]:
        files.add(ROOT / relative)
    if include_native:
        for e in selected:
            if e.get("source_path"):
                files.add(ROOT / e["source_path"])
            files.update(ROOT / c["source_path"] for c in e.get("animation_sources", {}).values())
    details = [{"path": p.relative_to(ROOT).as_posix(), "bytes": p.stat().st_size,
                "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(files)]
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for file in sorted(files):
            bundle.write(file, file.relative_to(ROOT))
        bundle.writestr("MANIFEST_SHA256.json", json.dumps({"priority": priority, "files": details}, ensure_ascii=False, indent=2))
        bundle.writestr("LISEZMOI.txt", f"Lot HD-2D priorité {priority}.\nOuvrir docs/sprites/PRIORITE_{priority}.html après extraction.\nVoir docs/sprites/LIVRAISON_PRIORITE_{priority}.md pour intégration et limites.\nLes sources natives restent dans le dépôt et sont ajoutées avec --include-native.\n")
    with zipfile.ZipFile(output) as bundle:
        if bundle.testzip():
            raise ValueError("CRC failure")
        for d in details:
            if hashlib.sha256(bundle.read(d["path"])).hexdigest() != d["sha256"]:
                raise ValueError("SHA failure: " + d["path"])
    output.with_suffix(".zip.sha256").write_text(hashlib.sha256(output.read_bytes()).hexdigest() + "  " + output.name + "\n")
    print(f"P{priority}: {len(entries)} PNG + {json_count} JSON; all checks, CRC and SHA pass. ZIP: {output} ({output.stat().st_size / 1e6:.1f} MB)")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--priority", type=int, choices=[2, 3, 4], required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--include-native", action="store_true")
    args = parser.parse_args()
    build(args.priority, args.output or ROOT / f"build/Yume_WorldEnd_HD2D_Priorite{args.priority}_Integration.zip", args.include_native)


if __name__ == "__main__":
    main()
