#!/usr/bin/env python3
"""Package only document priority 1 plus requested front/back sprite views."""

import argparse
import hashlib
import importlib.util
import json
import zipfile
from pathlib import Path

import make_gallery as gallery

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("hd", ROOT / "tools/hd2d_assets.py")
HD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HD)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "build/Yume_WorldEnd_HD2D_Priorite1.zip")
    parser.add_argument("--runtime-only", action="store_true", help="Small integration ZIP; native sources remain in the full package.")
    args = parser.parse_args()
    manifest_path = ROOT / "tools/hd2d_priority1_manifest.json"
    manifest = HD.load_manifest(manifest_path)
    report = HD.check_assets(ROOT, manifest)
    if not report["ok"]:
        raise ValueError("Priority 1 contract fails: " + json.dumps(report, ensure_ascii=False))
    paths = {entry["path"] for entry in manifest["entries"]}
    all_entries = gallery.read_catalog()["entries"]
    entries = []
    for path in sorted(paths):
        matches = [entry for entry in all_entries if entry["path"] == path]
        if not matches:
            raise ValueError("Missing provenance/catalog entry: " + path)
        # Dedicated portrait entries take precedence over bonus crops.
        entries.append(matches[-1])
    catalog_path = ROOT / "assets/source/resumed_2d/priority1_catalog.json"
    catalog = {"status": "Priorité 1 livrée — contrôle technique réussi ; cycles et ancres à revoir visuellement",
               "entries": entries, "technical_check": report}
    catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
    old_catalog, old_archives = gallery.CATALOG, gallery.read_archives
    gallery.CATALOG, gallery.read_archives = catalog_path, lambda: []
    destination = ROOT / "docs/sprites/PRIORITE_1.html"
    try:
        gallery.build(destination)
    finally:
        gallery.CATALOG, gallery.read_archives = old_catalog, old_archives
    document = destination.read_text().replace("Yume-WorldEnd · Atelier HD-2D", "Yume-WorldEnd · Priorité 1")
    document = document.replace("Les onze PNG d’origine et les générations anime suivantes sont conservés sans modification, avec leurs limites de découpage documentées. Ils restent téléchargeables ; la nouvelle livraison suit le cahier pixel art HD-2D.", "Les dessins anime sont conservés dans le projet et sa galerie complète. Cette archive contient uniquement le lot de priorité 1.")
    document = document.replace('<a href="../../assets/source/legacy_2d/manifest.json">Manifeste des premières planches</a>', '')
    destination.write_text(document)
    files = {ROOT / path for path in paths} | {manifest_path, destination, catalog_path}
    for entry in manifest["entries"]:
        if entry.get("json_path"):
            files.add(ROOT / entry["json_path"])
    for entry in entries:
        if entry.get("source_path") and not args.runtime_only:
            files.add(ROOT / entry["source_path"])
        if not args.runtime_only:
            for replacement in entry.get("animation_sources", {}).values():
                files.add(ROOT / replacement["source_path"])
                provenance = (ROOT / replacement["source_path"]).with_suffix(".provenance.json")
                if provenance.exists():
                    files.add(provenance)
    for relative in ("docs/ASSETS_HD2D.md", "docs/sprites/LIVRAISON_PRIORITE_1.md",
                     "tools/hd2d_assets.py", "tools/sukasuka2d/make_priority1_package.py",
                     "tools/sukasuka2d/make_gallery.py", "assets/CREDITS.md",
                     "docs/sprites/previews/priorite1-cour.png",
                     "docs/sprites/previews/priorite1-chtholly-directions.png"):
        files.add(ROOT / relative)
    details = [{"path": p.relative_to(ROOT).as_posix(), "bytes": p.stat().st_size,
                "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(files)]
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for file in sorted(files):
            bundle.write(file, file.relative_to(ROOT))
        bundle.writestr("MANIFEST_SHA256.json", json.dumps({"priority": 1, "files": details}, ensure_ascii=False, indent=2))
        native_note = "Sources natives dans le paquet complet et le projet." if args.runtime_only else "Sources natives conservées sous assets/source/."
        bundle.writestr("LISEZMOI.txt", "Ouvrir docs/sprites/PRIORITE_1.html après extraction.\nCopier assets/characters/chtholly, assets/enemies/timere et assets/hd2d dans le projet en conservant les chemins.\nLes JSON sont à côté des atlas PNG. " + native_note + "\nVoir docs/sprites/LIVRAISON_PRIORITE_1.md pour contrôles et limites.\n")
    with zipfile.ZipFile(output) as bundle:
        if bundle.testzip() is not None:
            raise ValueError("ZIP CRC failure")
        for item in details:
            if hashlib.sha256(bundle.read(item["path"])).hexdigest() != item["sha256"]:
                raise ValueError("ZIP checksum failure: " + item["path"])
    output.with_suffix(".zip.sha256").write_text(hashlib.sha256(output.read_bytes()).hexdigest() + "  " + output.name + "\n")
    print(f"{len(paths)} PNG, {report['total_image_bytes']} runtime bytes, {len(files)} packaged files; CRC/SHA verified: {output}")


if __name__ == "__main__":
    main()
