#!/usr/bin/env python3
"""Check the HD-2D delivery contract and fit explicitly supplied PNG artwork.

No artwork or placeholders are generated. Original inputs are archived before
replacement. Pixel art uses nearest-neighbour sampling and binary transparency.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tools/hd2d_manifest.json"


def load_manifest(path: Path = MANIFEST) -> dict:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    entries = manifest.get("entries")
    if not isinstance(entries, list) or not entries:
        raise ValueError("Le manifeste doit contenir au moins un asset attendu.")
    paths = [entry["path"] for entry in entries]
    if len(paths) != len(set(paths)):
        raise ValueError("Chemins dupliqués dans le manifeste.")
    return manifest


def safe_path(root: Path, relative: str) -> Path:
    path = (root / relative.removeprefix("res://")).resolve()
    path.relative_to(root.resolve())
    return path


def _sheet_errors(image: Image.Image, data: dict, entry: dict) -> list[str]:
    errors = []
    if data.get("planche") != list(image.size):
        errors.append("Dimensions PNG et planche JSON différentes.")
    animations = data.get("animations")
    if not isinstance(animations, dict):
        return errors + ["animations JSON absentes ou invalides."]
    previous_bottom = -1
    alpha = image.convert("RGBA").getchannel("A")
    for name, expected in entry.get("animations", {}).items():
        animation = animations.get(name)
        if not isinstance(animation, dict):
            errors.append(f"Animation absente : {name}.")
            continue
        images = animation.get("images", [])
        if not isinstance(images, list) or len(images) != expected["frames"]:
            errors.append(f"Nombre d'images incorrect : {name}.")
            continue
        if animation.get("ips") != expected["fps"] or animation.get("boucle") != expected["loop"]:
            errors.append(f"Cadence ou boucle incorrecte : {name}.")
        if "hit_frames" in expected and animation.get("coup") != expected["hit_frames"]:
            errors.append(f"Images de coup incorrectes : {name}.")
        if "wave_frame" in expected and animation.get("onde") != expected["wave_frame"]:
            errors.append(f"Image d'onde incorrecte : {name}.")
        boxes = []
        for index, frame in enumerate(images):
            if (
                not isinstance(frame, list) or len(frame) < 6
                or any(not isinstance(value, (int, float)) or not math.isfinite(value) for value in frame[:6])
            ):
                errors.append(f"Rectangle/ancre invalide : {name}/{index}.")
                continue
            x, y, width, height, ax, ay = frame[:6]
            if (
                min(x, y) < 0 or min(width, height) <= 0
                or x + width > image.width or y + height > image.height
                or not 0 <= ax <= width or not 0 <= ay <= height
            ):
                errors.append(f"Rectangle/ancre hors planche : {name}/{index}.")
                continue
            if name == "repos" and index == 0 and height != entry["idle_height_px"]:
                errors.append(f"Hauteur repos : {height} px, attendu {entry['idle_height_px']} px.")
            box = (int(x), int(y), int(x + width), int(y + height))
            if alpha.crop(box).getbbox() is None:
                errors.append(f"Image vide : {name}/{index}.")
            boxes.append(box)
        if not boxes:
            continue
        if entry.get("row_format") == "one_animation_per_row":
            top, bottom = min(box[1] for box in boxes), max(box[3] for box in boxes)
            if top < previous_bottom:
                errors.append(f"Rangées d'animations superposées ou désordonnées : {name}.")
            previous_bottom = bottom
            for left, right in zip(boxes, boxes[1:]):
                if right[0] - left[2] < entry.get("frame_gap_px", 2):
                    errors.append(f"Moins de deux pixels entre images : {name}.")
                elif alpha.crop((left[2], top, right[0], bottom)).getbbox() is not None:
                    errors.append(f"Pixels non transparents entre images : {name}.")
    return errors


def inspect_image(root: Path, entry: dict, manifest: dict) -> dict:
    path = safe_path(root, entry["path"])
    result = {"path": entry["path"], "status": "missing", "errors": [], "warnings": []}
    if not path.is_file():
        if entry.get("required", True):
            result["errors"].append("Fichier requis manquant.")
        return result
    result["status"] = "provided"
    result["bytes"] = path.stat().st_size
    if result["bytes"] >= manifest.get("max_image_bytes", 1_000_000):
        result["errors"].append("Image de 1 Mo ou plus.")
    try:
        with Image.open(path) as original:
            original.load()
            if original.format != "PNG":
                result["errors"].append("Le fichier n'est pas un PNG.")
            if original.mode != "RGBA":
                result["errors"].append(f"Mode {original.mode}, RGBA 8 bits requis.")
            if path.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n" and path.read_bytes()[24] != 8:
                result["errors"].append("PNG non 8 bits.")
            image = original.convert("RGBA")
    except (OSError, ValueError, IndexError) as error:
        result["errors"].append(f"PNG illisible : {error}")
        return result
    result["dimensions"] = list(image.size)
    if entry.get("size") and list(image.size) != entry["size"]:
        result["errors"].append(f"Taille {list(image.size)}, attendu {entry['size']}.")
    alpha = image.getchannel("A")
    low, high = alpha.getextrema()
    policy = entry.get("alpha", "binary")
    if policy == "opaque" and low != 255:
        result["errors"].append("Texture opaque requise, transparence détectée.")
    elif policy != "opaque":
        if low != 0 or high == 0:
            result["errors"].append("Fond transparent et sujet visible requis.")
        if policy == "binary" and sum(alpha.histogram()[1:255]) > 0:
            result["errors"].append("Alpha intermédiaire détecté : seules les valeurs 0 et 255 sont admises.")
    placement = entry.get("placement")
    box = alpha.getbbox()
    if box and placement in ("bottom_center", "facade_edges") and box[3] != image.height:
        result["errors"].append("Ligne vide sous le pied : le sujet doit toucher le bord bas.")
    if box and placement == "facade_edges" and (box[0] != 0 or box[2] != image.width):
        result["errors"].append("La façade doit toucher les bords gauche et droit.")
    for axis in entry.get("seamless_axes", []):
        edges = (
            (image.crop((0, 0, 1, image.height)), image.crop((image.width - 1, 0, image.width, image.height)))
            if axis == "x" else
            (image.crop((0, 0, image.width, 1)), image.crop((0, image.height - 1, image.width, image.height)))
        )
        if edges[0].tobytes() != edges[1].tobytes():
            result["errors"].append(f"Raccord {axis} non exact : pixels des bords opposés différents.")
    if entry.get("kind") == "sprite":
        json_path = safe_path(root, entry["json_path"])
        try:
            data = json.loads(json_path.read_text(encoding="utf-8"))
            if not isinstance(data, dict):
                raise ValueError("racine JSON invalide")
            result["errors"].extend(_sheet_errors(image, data, entry))
        except (OSError, ValueError, TypeError) as error:
            result["errors"].append(f"JSON de découpe absent ou invalide : {error}")
        result["warnings"].append("Le contrôle technique ne valide pas le dessin, les cycles ni le contact des pieds.")
    return result


def check_assets(root: Path, manifest: dict, allow_missing: bool = False) -> dict:
    files = [inspect_image(root, entry, manifest) for entry in manifest["entries"]]
    provided = [file for file in files if file["status"] == "provided"]
    errors = []
    if not provided:
        errors.append("Aucun asset fourni : le contrôle ne peut pas être vert.")
    total = sum(file.get("bytes", 0) for file in files)
    if total >= manifest.get("max_total_image_bytes", 25_000_000):
        errors.append("Les images du manifeste atteignent ou dépassent 25 Mo.")
    failures = [file for file in files if file["errors"] and not (allow_missing and file["status"] == "missing")]
    return {
        "ok": not failures and not errors, "scope": manifest.get("scope", "Explicit HD-2D document assets"),
        "expected": len(files), "provided": len(provided),
        "missing_required": sum(file["status"] == "missing" and bool(file["errors"]) for file in files),
        "failed_provided": sum(file["status"] == "provided" and bool(file["errors"]) for file in files),
        "total_image_bytes": total, "errors": errors, "files": files,
        "allow_missing": allow_missing,
    }


def _archive(root: Path, path: Path, relative: str) -> str:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    directory = root / "assets/source/hd2d_raw" / Path(relative).with_suffix("")
    directory.mkdir(parents=True, exist_ok=True)
    destination = directory / (digest + path.suffix.lower())
    if not destination.exists():
        destination.write_bytes(path.read_bytes())
    ignore = root / "assets/source/.gdignore"
    ignore.parent.mkdir(parents=True, exist_ok=True)
    ignore.touch(exist_ok=True)
    return destination.relative_to(root).as_posix()


def _resize(image: Image.Image, size: tuple[int, int], resample: str) -> Image.Image:
    if resample == "nearest":
        return image.resize(size, Image.Resampling.NEAREST)
    # Premultiplied alpha avoids dark fringes around transparent artwork.
    return image.convert("RGBa").resize(size, Image.Resampling.BILINEAR).convert("RGBA")


def pixel_palette(image: Image.Image, colors: int = 64) -> Image.Image:
    """Limit raster shades without dithering; preserve geometry and binary alpha."""
    alpha = image.getchannel("A")
    rgb = image.convert("RGB").quantize(colors=colors, method=Image.Quantize.MEDIANCUT,
                                        dither=Image.Dither.NONE).convert("RGBA")
    rgb.putalpha(alpha)
    return rgb


def fit_asset(
    root: Path, manifest: dict, relative: str, source: Path | None = None,
    resample: str = "nearest", mode: str = "contain", frames_json: Path | None = None,
    allow_upscale: bool = False, alpha_threshold: int = 128, wrap_edges: bool = False,
    palette_colors: int = 0,
) -> dict:
    entry = next((item for item in manifest["entries"] if item["path"] == relative), None)
    if entry is None:
        raise ValueError(f"Chemin absent du manifeste : {relative}")
    destination = safe_path(root, relative)
    source = (source or destination).resolve()
    if resample not in ("nearest", "linear") or mode not in ("contain", "stretch"):
        raise ValueError("Rééchantillonnage ou cadrage inconnu.")
    if not 1 <= alpha_threshold <= 255:
        raise ValueError("Le seuil alpha doit être compris entre 1 et 255.")
    with Image.open(source) as original:
        if original.format != "PNG":
            raise ValueError("fit accepte uniquement des PNG bruts.")
        original.load()
        image = original.convert("RGBA")
    alpha = image.getchannel("A")
    policy = entry.get("alpha", "binary")
    if policy == "opaque" and alpha.getextrema()[0] != 255:
        raise ValueError("La source d'une texture opaque contient de la transparence.")
    if policy != "opaque" and (alpha.getextrema()[0] != 0 or alpha.getbbox() is None):
        raise ValueError("La source doit déjà avoir un vrai fond transparent et un sujet visible.")
    if policy == "binary":
        image.putalpha(alpha.point(lambda value: 255 if value >= alpha_threshold else 0))
        if image.getchannel("A").getbbox() is None:
            raise ValueError("Le seuil alpha efface tout le sujet.")
    json_data = None
    json_source = None
    upscaling = False
    if entry.get("kind") == "sprite":
        json_source = (frames_json or safe_path(root, entry["json_path"])).resolve()
        json_data = json.loads(json_source.read_text(encoding="utf-8"))
        if json_data.get("planche") != list(image.size):
            raise ValueError("Le JSON fourni doit décrire exactement la taille de la source PNG.")
        first = json_data["animations"]["repos"]["images"][0]
        source_height = first[3]
        if source_height <= 0:
            raise ValueError("Hauteur de repos invalide dans le JSON.")
        factor = entry["idle_height_px"] / source_height
        upscaling = factor > 1
        target_size = (max(1, round(image.width * factor)), max(1, round(image.height * factor)))
        fitted = _resize(image, target_size, resample)
        json_data = copy.deepcopy(json_data)
        json_data["planche"] = list(target_size)
        for animation in json_data["animations"].values():
            for frame in animation["images"]:
                x, y, width, height, ax, ay = frame[:6]
                left, top = round(x * factor), round(y * factor)
                frame[:6] = [
                    left, top, round((x + width) * factor) - left,
                    round((y + height) * factor) - top, round(ax * factor), round(ay * factor),
                ]
        json_data["anchors_validated"] = json_data.get("anchors_validated", False)
    else:
        target_size = tuple(entry["size"])
        if policy != "opaque":
            image = image.crop(image.getchannel("A").getbbox())
        if mode == "stretch" or policy == "opaque":
            upscaling = target_size[0] > image.width or target_size[1] > image.height
            fitted = _resize(image, target_size, resample)
        else:
            scale = min(target_size[0] / image.width, target_size[1] / image.height)
            upscaling = scale > 1
            inner = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
            resized = _resize(image, inner, resample)
            fitted = Image.new("RGBA", target_size, (0, 0, 0, 0))
            x = (target_size[0] - inner[0]) // 2
            y = target_size[1] - inner[1] if entry.get("placement") else (target_size[1] - inner[1]) // 2
            fitted.paste(resized, (x, y))
    if not allow_upscale and upscaling:
        raise ValueError("La source est trop petite ; fournissez une image plus grande ou --allow-upscale.")
    if policy == "binary":
        fitted.putalpha(fitted.getchannel("A").point(lambda value: 255 if value >= alpha_threshold else 0))
    if palette_colors:
        if not 2 <= palette_colors <= 256:
            raise ValueError("Palette : choisir entre2 et256 couleurs.")
        fitted = pixel_palette(fitted, palette_colors)
    normalized_axes = []
    if wrap_edges:
        if policy != "opaque":
            raise ValueError("La fermeture des bords concerne uniquement les textures opaques périodiques.")
        # Mechanical one-pixel border alignment after the explicitly requested fit.
        # Interior artwork and native input are preserved; composition still needs review.
        for axis in entry.get("seamless_axes", []):
            if axis == "x":
                fitted.paste(fitted.crop((0, 0, 1, fitted.height)), (fitted.width - 1, 0))
            elif axis == "y":
                fitted.paste(fitted.crop((0, 0, fitted.width, 1)), (0, fitted.height - 1))
            normalized_axes.append(axis)
    archives = {"source_png": _archive(root, source, relative)}
    if destination.exists():
        archives["previous_png"] = _archive(root, destination, relative)
    if json_data is not None:
        archives["source_json"] = _archive(root, json_source, entry["json_path"])
        json_destination = safe_path(root, entry["json_path"])
        if json_destination.exists():
            archives["previous_json"] = _archive(root, json_destination, entry["json_path"])
        json_destination.parent.mkdir(parents=True, exist_ok=True)
        json_destination.write_text(json.dumps(json_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    destination.parent.mkdir(parents=True, exist_ok=True)
    fitted.save(destination, format="PNG", optimize=True)
    result = {
        "path": relative, "source": str(source), "archives": archives,
        "resample": resample, "mode": mode, "alpha_threshold": alpha_threshold,
        "upscaled": upscaling,
        "periodic_border_alignment": normalized_axes,
        "palette_colors": palette_colors or None,
        "dimensions": list(fitted.size), "source_pixels_preserved_in_archive": True,
        "check": inspect_image(root, entry, manifest),
        "limitations": ["Resizing cannot certify art direction, seamless composition or animation quality."],
    }
    archive_dir = root / "assets/source/hd2d_raw" / Path(relative).with_suffix("")
    record_hash = hashlib.sha256(destination.read_bytes()).hexdigest()
    (archive_dir / (record_hash + ".fit.json")).write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    subparsers = parser.add_subparsers(dest="command", required=True)
    check = subparsers.add_parser("check", help="Contrôle strict, y compris les fichiers manquants.")
    check.add_argument("--allow-missing", action="store_true", help="Contrôle partiel explicite des fichiers déjà fournis.")
    check.add_argument("--json", type=Path, help="Journal JSON complet.")
    fit = subparsers.add_parser("fit", help="Adapter une image fournie ; conserver les originaux.")
    fit.add_argument("file", help="Chemin cible exact du manifeste.")
    fit.add_argument("--source", type=Path)
    fit.add_argument("--frames-json", type=Path)
    fit.add_argument("--resample", choices=("nearest", "linear"), default="nearest")
    fit.add_argument("--mode", choices=("contain", "stretch"), default="contain")
    fit.add_argument("--allow-upscale", action="store_true")
    fit.add_argument("--alpha-threshold", type=int, default=128)
    fit.add_argument("--wrap-edges", action="store_true", help="Aligner le dernier pixel des bords périodiques avec le premier ; conserver le dessin intérieur et le natif.")
    fit.add_argument("--palette-colors", type=int, default=0, help="Limiter les teintes en paliers sans tramage ;0 conserve les couleurs natives.")
    args = parser.parse_args()
    try:
        manifest = load_manifest(args.manifest)
        if args.command == "check":
            result = check_assets(ROOT, manifest, args.allow_missing)
            if args.json:
                args.json.parent.mkdir(parents=True, exist_ok=True)
                args.json.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(
                f"{'VERT' if result['ok'] else 'ROUGE'} : {result['provided']}/{result['expected']} fournis, "
                f"{result['missing_required']} manquants requis, {result['failed_provided']} fournis non conformes."
            )
            messages = result["errors"] + [
                file["path"] + ": " + error for file in result["files"]
                if not (args.allow_missing and file["status"] == "missing") for error in file["errors"]
            ]
            for message in messages[:20]:
                print("- " + message)
            if len(messages) > 20:
                print(f"… {len(messages) - 20} autres erreurs ; utilisez --json pour le détail.")
            return 0 if result["ok"] else 1
        target = Path(args.file)
        relative = target.resolve().relative_to(ROOT).as_posix() if target.is_absolute() else target.as_posix()
        result = fit_asset(
            ROOT, manifest, relative, args.source, args.resample, args.mode,
            args.frames_json, args.allow_upscale, args.alpha_threshold, args.wrap_edges,
            args.palette_colors,
        )
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 1 if result["check"]["errors"] else 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"ERREUR : {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
