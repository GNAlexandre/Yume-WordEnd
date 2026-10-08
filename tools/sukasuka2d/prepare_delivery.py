#!/usr/bin/env python3
"""Fit supplied HD-2D images and cut drawn animation rows, preserving natives.

Implements the fitting and sheet cutting requested in ASSETS_HD2D.md. It never
draws artwork or manufactures missing poses. Ambiguous row cuts remain pending.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

from PIL import Image
import numpy as np
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("hd2d_assets", ROOT / "tools/hd2d_assets.py")
hd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hd)
COMBAT = [("repos", 2, 2, True), ("marche", 6, 10, True),
          ("course", 5, 14, True), ("attaque", 4, 14, False),
          ("charge", 4, 10, False), ("degats", 1, 1, False), ("mort", 1, 1, False)]
NPC = [("repos", 2, 2, True), ("marche", 6, 10, True),
       ("course", 4, 12, True), ("parle", 2, 6, True)]
ENEMY = [("repos", 5, 6, True), ("marche", 4, 7, True),
         ("course", 6, 12, True), ("fouet", 4, 8, False),
         ("morsure", 4, 8, False), ("degats", 5, 12, False), ("mort", 6, 8, False)]
ALIASES = {"grick": "glick", "kaiya": "kaya", "souwong_young": "suowong_young",
           "souwong_sage": "suowong", "eboncandle_ancient": "ebon_candle_ancient",
           "eboncandle_skull": "ebon_candle", "cyclops_doctor": "doctor"}


def replacement_for(entry, direction, animation):
    sources = entry.get("animation_sources", {})
    return sources.get(direction + ":" + animation, sources.get(animation))


def json_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def runs(values):
    result, start = [], None
    for i, value in enumerate([*values, False]):
        if value and start is None:
            start = i
        elif not value and start is not None:
            result.append((start, i))
            start = None
    return result


def row_boundaries(alpha, rows):
    """Choose actual empty gutters close to the declared row boundaries."""
    profile = [bool(alpha.crop((0, y, alpha.width, y + 1)).getbbox()) for y in range(alpha.height)]
    boundaries = [0]
    for index in range(1, rows):
        expected = alpha.height * index / rows
        radius = alpha.height / rows * 0.35
        candidates = [y for y in range(max(boundaries[-1] + 1, int(expected - radius)),
                                      min(alpha.height, int(expected + radius))) if not profile[y]]
        if not candidates:
            raise ValueError(f"No transparent gutter near row {index + 1}; poses may overlap.")
        boundaries.append(min(candidates, key=lambda y: abs(y - expected)))
    return [*boundaries, alpha.height]


def cut_rows(image, entry):
    """Cut actual connected silhouettes, including nonuniformly spaced drawings.

    Source rows may overlap in their rectangular bounds while their painted
    silhouettes stay separate. Connected components isolate those sprites;
    small disconnected particles are attached to the nearest silhouette.
    """
    kind = entry["layout"]["kind"]
    clips = NPC if kind == "directional_rows_npc" else ENEMY if kind == "directional_rows_enemy" else list(COMBAT)
    if kind == "directional_rows_combat" and entry["layout"]["rows"] == 8:
        clips = [*clips, ("parle", 2, 6, True)]
    if entry.get("clip_contract"):
        clips = entry["clip_contract"]
    combined = kind == "directional_rows_npc" and entry["layout"]["rows"] == 12
    directions = ["front", "back", "right"] if combined else [entry["layout"]["direction"]]
    source_rows = []
    for direction in directions:
        for local_row, (name, frame_count, fps, loop) in enumerate(clips):
            replacement = replacement_for(entry, direction, name)
            original_count = replacement.get("original_count", frame_count - 1) if replacement else frame_count
            if original_count:
                source_rows.append((direction, local_row, name, original_count, fps, loop))
    pixels = np.asarray(image)
    labels, count = ndimage.label(pixels[:, :, 3] > 0, structure=np.ones((3, 3)))
    sizes = np.bincount(labels.ravel())
    objects = ndimage.find_objects(labels)
    expected = sum(row[3] for row in source_rows)
    threshold = np.median(sorted(sizes[1:], reverse=True)[:expected]) * 0.22
    major = [index for index in range(1, count + 1) if sizes[index] >= threshold]
    portrait_cell = entry.get("portrait_cell", entry["layout"].get("portrait_cell"))
    has_portrait = bool(portrait_cell)
    if len(major) != expected + int(has_portrait):
        raise ValueError(f"{len(major)} separate full silhouettes, expected {expected}" +
                         (" plus portrait" if has_portrait else "") + "; missing or touching poses need review.")
    centers = {index: ((objects[index - 1][1].start + objects[index - 1][1].stop) / 2,
                       (objects[index - 1][0].start + objects[index - 1][0].stop) / 2) for index in major}
    portrait_index = None
    if has_portrait:
        px = image.width * (portrait_cell[0] + 0.5) / entry["layout"]["columns"]
        py = image.height * (portrait_cell[1] + 0.5) / entry["layout"]["rows"]
        portrait_index = min(major, key=lambda i: (centers[i][0] - px) ** 2 + (centers[i][1] - py) ** 2)
    ordered = sorted([i for i in major if i != portrait_index], key=lambda index: centers[index][1])
    row_count = len(source_rows)
    gaps = sorted(range(len(ordered) - 1),
                  key=lambda i: centers[ordered[i + 1]][1] - centers[ordered[i]][1], reverse=True)
    cuts = sorted([0, *[i + 1 for i in gaps[:row_count - 1]], len(ordered)])
    groups = [sorted(ordered[left:right], key=lambda i: centers[i][0]) for left, right in zip(cuts, cuts[1:])]
    assignments = np.zeros(count + 1, dtype=np.int32)
    for index in major:
        assignments[index] = index
    for index in range(1, count + 1):
        if index in centers:
            continue
        obj = objects[index - 1]
        cx, cy = (obj[1].start + obj[1].stop) / 2, (obj[0].start + obj[0].stop) / 2
        def distance(candidate):
            rect = objects[candidate - 1]
            dx = max(rect[1].start - cx, 0, cx - rect[1].stop)
            dy = max(rect[0].start - cy, 0, cy - rect[0].stop)
            return dx * dx + dy * dy + 0.001 * ((centers[candidate][0] - cx) ** 2 + (centers[candidate][1] - cy) ** 2)
        assignments[index] = min(major, key=distance)
    assigned = assignments[labels]
    def pose(index):
        mask = assigned == index
        ys, xs = np.where(mask)
        left, right, top, bottom = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        data = pixels[top:bottom, left:right].copy()
        data[~mask[top:bottom, left:right]] = 0
        return Image.fromarray(data)
    result = {direction: [(name, fps, loop, []) for name, _, fps, loop in clips] for direction in directions}
    portraits = [pose(portrait_index)] if portrait_index else []
    for spans, (direction, local_row, name, frame_count, fps, loop) in zip(groups, source_rows):
        if len(spans) != frame_count:
            raise ValueError(f"{direction}/{name}: {len(spans)} isolated silhouettes, expected {frame_count}; redraw required.")
        result[direction][local_row] = (name, fps, loop, [pose(index) for index in spans])
    return result, portraits


def pack_direction(rows, height_m, direction, enemy=False):
    """Nearest-neighbour fitting; real source poses are rearranged in clean rows."""
    idle_height = round(height_m * 96)
    scale = idle_height / rows[0][3][0].height
    fitted_rows = []
    for name, fps, loop, frames in rows:
        fitted = [im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))),
                           Image.Resampling.NEAREST) for im in frames]
        fitted_rows.append((name, fps, loop, fitted))
    gap = 4
    width = max(sum(im.width for im in frames) + gap * (len(frames) - 1)
                for _, _, _, frames in fitted_rows)
    height = sum(max(im.height for im in frames) + gap for _, _, _, frames in fitted_rows) - gap
    atlas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    data = {"version": 1, "echelle": 1, "planche": [width, height], "direction": direction,
            "format": "images: [x,y,width,height,anchor_x,anchor_y] in atlas pixels",
            "status": "measured_crops_animation_review", "anchors_validated": False,
            "anchor_method": "bottom of alpha silhouette; horizontal foot centroid",
            "combat_timing_validated": False, "density_px_m": 96, "animations": {}}
    y = 0
    for name, fps, loop, frames in fitted_rows:
        row_height = max(im.height for im in frames)
        animation = {"ips": fps, "boucle": loop, "images": []}
        x = 0
        for im in frames:
            baseline = im.height
            # Only the lowest sole pixels: a low-held sword must not drag the anchor sideways.
            a = im.getchannel("A")
            band = a.crop((0, max(0, im.height - max(2, im.height // 25)), im.width, im.height))
            weights = [sum(band.crop((column, 0, column + 1, band.height)).histogram()[255:])
                       for column in range(im.width)]
            total = sum(weights)
            anchor_x = round(sum((column + 0.5) * weight for column, weight in enumerate(weights)) / total) if total else im.width // 2
            top = y + row_height - im.height
            atlas.paste(im, (x, top))
            animation["images"].append([x, top, im.width, im.height, anchor_x, baseline])
            x += im.width + gap
        if name == "attaque":
            animation["coup"] = [1, 2, 3]
        if name in ("fouet", "morsure"):
            animation["coup"] = [1, 2]
        if name == "charge":
            animation["onde"] = 3
        data["animations"][name] = animation
        y += row_height + gap
    data["palette_colors"] = 64
    return hd.pixel_palette(atlas, 64), data


def prepare_sprite(entry):
    original_id = entry["character_ids"][0]
    identifier = ALIASES.get(original_id, original_id)
    source = ROOT / entry["source_path"]
    with Image.open(source) as opened:
        image = opened.convert("RGBA")
    alpha = image.getchannel("A")
    image.putalpha(alpha.point(lambda v: 255 if v >= 128 else 0))
    directions, portraits = cut_rows(image, entry)
    for direction, rows in directions.items():
        for index, (name, fps, loop, frames) in enumerate(rows):
            replacement = replacement_for(entry, direction, name)
            if not replacement:
                continue
            with Image.open(ROOT / replacement["source_path"]) as opened:
                extra = opened.convert("RGBA")
            extra.putalpha(extra.getchannel("A").point(lambda v: 255 if v >= 128 else 0))
            contract = [("row_" + str(r), replacement["count"], fps, loop) for r in range(replacement["rows"])]
            supplemental, _ = cut_rows(extra, {"layout": {"kind": "directional_rows_strip", "direction": direction,
                                                         "rows": replacement["rows"]}, "clip_contract": contract})
            new_frames = supplemental[direction][replacement["row"]][3]
            reference_frames = frames or rows[0][3] or next(nonempty for _, _, _, nonempty in rows if nonempty)
            ratio = float(np.median([im.height for im in reference_frames])) / float(np.median([im.height for im in new_frames]))
            new_frames = [im.resize((max(1, round(im.width * ratio)), max(1, round(im.height * ratio))), Image.Resampling.NEAREST) for im in new_frames]
            rows[index] = (name, fps, loop, new_frames)
    output = []
    base = "assets/enemies" if entry["category"] == "enemies" else "assets/characters"
    for direction, rows in directions.items():
        atlas, metadata = pack_direction(rows, entry["height_m"], direction)
        suffix = "" if direction == "right" else "_" + direction
        path = f"{base}/{identifier}/{identifier}{suffix}.png"
        target = ROOT / path
        if target.exists():
            hd._archive(ROOT, target, path)
        json_path = Path(path).with_suffix(".json").as_posix()
        if (ROOT / json_path).exists():
            hd._archive(ROOT, ROOT / json_path, json_path)
        target.parent.mkdir(parents=True, exist_ok=True)
        atlas.save(target, optimize=True)
        json_write(ROOT / json_path, metadata)
        new = {**entry, "id": "pixel_" + identifier + "_" + direction,
               "character_ids": [identifier], "aliases": [original_id] if identifier != original_id else [],
               "path": path, "dimensions": list(atlas.size), "frames_json_path": json_path,
               "layout": {**entry["layout"], "direction": direction, "rows": len(rows)},
               "status": "measured_crops_animation_review", "density_px_m": 96,
               "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
               "limitations": ["Découpe mesurée ; cycles, contact des pieds et fenêtres de combat à revoir dans Godot."]}
        output.append(new)
    if portraits:
        portrait = portraits[0]
        raw_path = ROOT / f"assets/source/resumed_2d/pixel/portraits/{identifier}.png"
        raw_path.parent.mkdir(parents=True, exist_ok=True)
        portrait.save(raw_path, optimize=True)
        target = ROOT / f"assets/characters/{identifier}/{identifier}_portrait.png"
        factor = min(256 / portrait.width, 256 / portrait.height)
        portrait = portrait.resize((max(1, round(portrait.width * factor)), max(1, round(portrait.height * factor))), Image.Resampling.NEAREST)
        fitted = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        fitted.paste(portrait, ((256 - portrait.width) // 2, (256 - portrait.height) // 2))
        hd.pixel_palette(fitted, 64).save(target, optimize=True)
        for new in output:
            new["portrait_path"] = target.relative_to(ROOT).as_posix()
    return output


def prepare_portrait(entry, manifest):
    with Image.open(ROOT / entry["source_path"]) as original:
        cropped = original.crop(tuple(entry["source_box"])).convert("RGBA")
    raw = ROOT / "assets/source/resumed_2d/pixel/portraits" / (entry["id"] + ".png")
    raw.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(raw, optimize=True)
    result = hd.fit_asset(ROOT, manifest, entry["path"], raw, allow_upscale=True, palette_colors=64)
    return {**entry, "category": "characters" if entry["category"] == "portraits" else entry["category"], "dimensions": result["dimensions"],
            "status": "fitted_portrait", "fit_report": result}


def prepare_world(entry, manifest):
    mode = "stretch" if entry["category"] == "buildings" else "contain"
    palette = 32 if entry["path"].endswith("/warehouse_main.png") else 64
    result = hd.fit_asset(ROOT, manifest, entry["path"], ROOT / entry["source_path"],
                          mode=mode, allow_upscale=True, wrap_edges=bool(entry.get("seamless_axes")), palette_colors=palette)
    return {**entry, "name": entry.get("name", Path(entry["path"]).stem.replace("_", " ")),
            "dimensions": result["dimensions"], "status": "fitted_review",
            "fit_report": result, "limitations": result["check"]["errors"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fragments", type=Path, default=ROOT / "assets/source/resumed_2d/production_catalogs")
    args = parser.parse_args()
    catalog_path = ROOT / "assets/source/resumed_2d/catalog.json"
    prior = json.loads(catalog_path.read_text())
    archived = [{**j, "archived": True, "style": "anime_archive", "layout": None}
                for j in prior["entries"] if j["path"].startswith(("assets/sprites2d/generated/", "assets/source/resumed_2d/interim/"))]
    manifest = hd.load_manifest()
    entries, failures = [], []
    candidates = sorted(args.fragments.glob("*_catalog.json")) + [ROOT / "assets/source/resumed_2d/timere_catalog.json"]
    seen = set()
    for path in candidates:
        if not path.exists():
            continue
        fragment = json.loads(path.read_text())
        for source in fragment.get("entries", fragment.get("assets", [])):
            source = {**source, "style": "pixel_art"}
            if source.get("category") == "building_materials":
                source["category"] = "materials"
            if source["id"] in seen:
                raise ValueError("Duplicate fragment id: " + source["id"])
            seen.add(source["id"])
            try:
                if (source.get("layout") or {}).get("kind", "").startswith("directional_rows"):
                    entries.extend(prepare_sprite(source))
                elif source.get("source_box"):
                    entries.append(prepare_portrait(source, manifest))
                elif source.get("category") in {"ground", "cliff", "buildings", "materials", "props", "sky"}:
                    entries.append(prepare_world(source, manifest))
                else:
                    entries.append(source)
            except (OSError, ValueError, KeyError) as error:
                failures.append({"id": source["id"], "error": str(error)})
                entries.append({**source, "path": source["source_path"], "dimensions": source.get("native_dimensions", source.get("dimensions")),
                                "layout": None, "status": "native_needs_correction", "limitations": [str(error)]})
    json_write(catalog_path, {"status": "delivery_in_progress", "style": "pixel_art", "entries": archived + entries,
                              "processing_failures": failures, "package_files": ["tools/hd2d_assets.py", "tools/hd2d_manifest.json", "tools/sukasuka2d/prepare_delivery.py", "scenes/hd2d/island68.tscn", "scenes/hd2d/island68.gd", "scenes/hd2d/README.md"]})
    json_write(ROOT / "build/hd2d-preparation.json", {"prepared_entries": len(entries), "failures": failures})
    print(json.dumps({"prepared_entries": len(entries), "failures": failures}, ensure_ascii=False, indent=2))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
