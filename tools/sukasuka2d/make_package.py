#!/usr/bin/env python3
"""Export the 2D catalog, generated PNGs, preserved originals and offline gallery."""

import argparse
import hashlib
import json
import re
import tempfile
import zipfile
from pathlib import Path

from make_gallery import (
    ARCHIVE_MANIFEST,
    CATALOG,
    DEFAULT_OUTPUT,
    ROOT,
    build,
    project_path,
    read_archives,
    read_catalog,
)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def resource_files(catalog):
    """Collect explicitly listed files plus their static Godot res:// dependencies."""
    allowed_suffixes = {".png", ".json", ".gd", ".tscn", ".tres", ".gdshader", ".md", ".txt"}
    seeds = list(catalog.get("package_files", []))
    for entry in catalog["entries"]:
        for field in ("source_path", "metadata_path", "resource_path", "portrait_path", "runtime_path", "scene_path"):
            if entry.get(field):
                seeds.append(entry[field])
    selected = set()
    for seed in seeds:
        path = project_path(seed)
        if path.is_dir():
            selected.update(item for item in path.rglob("*") if item.is_file() and item.suffix in allowed_suffixes)
        elif path.is_file():
            selected.add(path)
        else:
            raise ValueError(f"Fichier de livraison absent : {seed}")
    # The local source archive keeps native outputs and generation metadata, not scans.
    for relative in ("assets/source/resumed_2d", "assets/sprites2d/metadata", "assets/sprites2d/resources", "data/visuals2d/generated"):
        folder = ROOT / relative
        if folder.is_dir():
            selected.update(item for item in folder.rglob("*") if item.is_file() and item.suffix in allowed_suffixes)
    for relative in (
        "tools/hd2d_assets.py", "tools/hd2d_manifest.json",
        "scenes/dev/atelier_2d.gd", "scenes/dev/atelier_2d.tscn",
        "src/visuals/character_visual.gd", "src/visuals/skin_data.gd", "src/visuals/sheet_loader.gd",
    ):
        path = ROOT / relative
        if path.is_file():
            selected.add(path)
    pending = list(selected)
    visited = set()
    while pending:
        path = pending.pop()
        if path in visited or path.suffix not in {".gd", ".tscn", ".tres", ".gdshader"}:
            continue
        visited.add(path)
        for reference in re.findall(r"res://[^\s\"'<>]+", path.read_text(encoding="utf-8")):
            dependency = project_path(reference[6:])
            if dependency.is_file() and dependency.suffix in allowed_suffixes and dependency not in selected:
                selected.add(dependency)
                pending.append(dependency)
    return selected


def make_package(output):
    output = Path(output).resolve()
    if not output.is_relative_to(Path("/workspace")) and not output.is_relative_to(Path("/tmp")):
        raise ValueError("La destination doit être dans /workspace ou /tmp.")
    build()
    catalog = read_catalog()
    entries = catalog["entries"] + read_archives()
    images = {project_path(entry["path"]) for entry in entries if project_path(entry["path"]).is_file()}
    files = images | {ARCHIVE_MANIFEST, DEFAULT_OUTPUT} | resource_files(catalog)
    if CATALOG.exists():
        files.add(CATALOG)
    source_readme = ROOT / "assets/source/legacy_2d/README.md"
    if source_readme.exists():
        files.add(source_readme)
    for relative in ("docs/ASSETS_HD2D.md", "docs/sprites/PRODUCTION_2D.md", "assets/CREDITS.md"):
        document = ROOT / relative
        if document.is_file():
            files.add(document)
    files.update(path for path in (ROOT / "tools/sukasuka2d").iterdir() if path.suffix in {".py", ".cjs"})
    files.add(ROOT / "tools/sukasuka2d/README.md")
    pending = [entry["id"] for entry in catalog["entries"] if not project_path(entry["path"]).is_file()]
    manifest = {
        "status": catalog.get("status"),
        "missing_images": pending,
        "reference_scans_included": False,
        "files": [
            {"path": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size, "sha256": sha256(path)}
            for path in sorted(files)
        ],
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=output.parent, suffix=".zip", delete=False) as temporary:
        temp_path = Path(temporary.name)
    try:
        with zipfile.ZipFile(temp_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
            for path in sorted(files):
                bundle.write(path, path.relative_to(ROOT).as_posix())
            bundle.writestr("MANIFEST_SHA256.json", json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
            bundle.writestr("LISEZMOI.txt", "Yume-WorldEnd — Livraison 2D / HD-2D\n\nDécompressez tout le ZIP puis ouvrez docs/sprites/ATELIER_2D.html.\nLes PNG d’origine sont conservés sans modification.\nLe catalogue décrit les nouvelles planches, leurs identifications et leurs limites.\nLes ressources Godot et scènes d’atelier, lorsqu’elles sont incluses, se copient dans le dépôt en conservant les chemins ; ce ZIP n’est pas un export du jeu complet.\nLes scans officiels ne sont pas inclus. Les droits sur les designs SukaSuka ne sont pas transférés.\nMANIFEST_SHA256.json permet de vérifier chaque fichier.\n")
        with zipfile.ZipFile(temp_path) as bundle:
            bad = bundle.testzip()
            if bad:
                raise ValueError(f"Erreur de CRC : {bad}")
            for entry in manifest["files"]:
                if hashlib.sha256(bundle.read(entry["path"])).hexdigest() != entry["sha256"]:
                    raise ValueError(f"Empreinte incorrecte : {entry['path']}")
        temp_path.replace(output)
    finally:
        temp_path.unlink(missing_ok=True)
    checksum = sha256(output)
    output.with_suffix(output.suffix + ".sha256").write_text(f"{checksum}  {output.name}\n", encoding="utf-8")
    print(f"{output}: {len(images)} images, {output.stat().st_size} octets, CRC et SHA-256 vérifiés")
    if pending:
        print("Images encore en préparation : " + ", ".join(pending))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("/workspace/sukasuka-production/Yume_WorldEnd_2D.zip"))
    args = parser.parse_args()
    make_package(args.output)


if __name__ == "__main__":
    main()
