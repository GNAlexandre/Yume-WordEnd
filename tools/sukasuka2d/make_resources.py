#!/usr/bin/env python3
"""Expose preserved generated PNGs and directional animation drafts in Godot.

Only headers and supplied frame JSON are read; no pixel data is changed. Measured
frame rectangles take precedence over declared grids. Archived art stays in the
HTML gallery and is excluded from Godot resources.
"""

from __future__ import annotations

import argparse
import json
import re
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG = ROOT / "assets/source/resumed_2d/catalog.json"
OUTPUT = ROOT / "data/visuals2d/generated"
PLAYABLE_PIXEL_IDS = ("chtholly", "ithea", "lillia", "nephren", "nopht", "rhantolk", "willem")
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
COMBAT_CLIPS = [
    ("repos", 0, 2, 2, True), ("marche", 2, 6, 10, True),
    ("course", 8, 5, 14, True), ("attaque", 13, 4, 14, False),
    ("charge", 17, 4, 10, False), ("degats", 21, 1, 1, False),
    ("mort", 22, 1, 1, False),
]
NPC_CLIPS = [
    ("repos", 0, 2, 2, True), ("marche", 2, 4, 8, True),
    ("course", 6, 4, 12, True), ("parle", 10, 2, 3, True),
]
ROWS_NPC_CLIPS = [
    ("repos", 0, 2, 2, True), ("marche", 6, 6, 10, True),
    ("course", 12, 4, 12, True), ("parle", 18, 2, 6, True),
]
ENEMY_CLIPS = [
    ("repos", 0, 5, 6, True), ("marche", 6, 4, 7, True),
    ("course", 12, 6, 12, True), ("fouet", 18, 4, 8, False),
    ("morsure", 24, 4, 8, False), ("degats", 30, 5, 12, False),
    ("mort", 36, 6, 8, False),
]


def clips_for(entry: dict, npc: bool) -> list:
    kind = entry["layout"]["kind"]
    if kind == "directional_rows_enemy":
        return ENEMY_CLIPS
    if kind == "directional_rows_npc":
        return ROWS_NPC_CLIPS
    if kind == "directional_rows_combat":
        clips = [(name, row * 6, count, fps, loop)
                 for row, (name, _, count, fps, loop) in enumerate(COMBAT_CLIPS)]
        if entry["layout"]["rows"] == 8:
            clips.append(("parle", 42, 2, 6, True))
        return clips
    return NPC_CLIPS if npc else COMBAT_CLIPS


def supplied_frame_json(entry: dict, direction: str) -> dict | None:
    """Read and validate actual packed rectangles before any resource is written."""
    supplied_path = entry.get("frames_json_paths", {}).get(direction, entry.get("frames_json_path"))
    if not supplied_path:
        return None
    supplied = json.loads((ROOT / supplied_path.removeprefix("res://")).read_text(encoding="utf-8"))
    supplied = supplied.get("directions", {}).get(direction, supplied)
    width, height = entry["dimensions"]
    if supplied.get("planche") != [width, height]:
        raise ValueError(f"PNG/JSON dimension mismatch for {entry['id']} / {direction}")
    animations = supplied.get("animations")
    if not isinstance(animations, dict) or not animations:
        raise ValueError(f"Missing animations for {entry['id']} / {direction}")
    for name, animation in animations.items():
        if not isinstance(animation.get("images"), list) or not animation["images"]:
            raise ValueError(f"Empty animation {entry['id']} / {name}")
        for frame in animation["images"]:
            if len(frame) != 6 or any(type(value) not in (int, float) for value in frame):
                raise ValueError(f"Invalid frame {entry['id']} / {name}: {frame}")
            x, y, frame_width, frame_height, anchor_x, anchor_y = frame
            if (min(x, y) < 0 or min(frame_width, frame_height) <= 0
                    or x + frame_width > width or y + frame_height > height
                    or not 0 <= anchor_x <= frame_width or not 0 <= anchor_y <= frame_height):
                raise ValueError(f"Frame outside PNG or invalid anchor {entry['id']} / {name}: {frame}")
    return {**supplied, "direction": direction, "status": "measured_crops_animation_review",
            "anchors_validated": False, "combat_timing_validated": False}


def frame_json(entry: dict, direction: str, npc: bool) -> dict:
    """Declared grid frames with provisional anchors at the bottom of each cell."""
    width, height = entry["dimensions"]
    columns, rows = entry["layout"]["columns"], entry["layout"]["rows"]
    supplied = supplied_frame_json(entry, direction)
    if supplied is not None:
        return supplied
    kind = entry["layout"]["kind"]
    offset = 0
    if kind == "directional_npc":
        offset = {"front": 0, "back": 12, "right": 24}[direction]
    elif kind == "directional_rows_npc" and rows == 12:
        offset = {"front": 0, "back": 24, "right": 48}[direction]
    animations = {}
    for name, start, count, fps, loop in clips_for(entry, npc):
        images = []
        for index in range(offset + start, offset + start + count):
            column, row = index % columns, index // columns
            x, y = column * width // columns, row * height // rows
            cell_width = (column + 1) * width // columns - x
            cell_height = (row + 1) * height // rows - y
            images.append([x, y, cell_width, cell_height, cell_width / 2, cell_height])
        animations[name] = {"ips": fps, "boucle": loop, "images": images}
    if kind == "directional_rows_enemy":
        for attack in ("fouet", "morsure"):
            animations[attack]["coup"] = [1, 2]
    elif not npc:
        animations["attaque"]["coup"] = [1, 2, 3]
        animations["charge"]["onde"] = 3
    return {
        "version": 1, "echelle": 1, "planche": [width, height],
        "direction": direction, "status": "directional_animation_draft",
        "anchors_validated": False, "combat_timing_validated": False,
        "animations": animations,
    }


def make_character_resources(entries: list[dict]) -> tuple[list[dict], list[str]]:
    groups = {}
    for entry in entries:
        layout = entry.get("layout") or {}
        kind = layout.get("kind")
        if kind not in (
            "directional_npc", "directional_combat", "directional_rows_npc", "directional_rows_combat",
            "directional_rows_enemy",
        ):
            continue
        ids = entry.get("character_ids", [])
        if len(ids) != 1 or not re.fullmatch(r"[a-z0-9_-]+", ids[0]):
            raise ValueError(f"A directional sheet must identify one character: {entry['id']}")
        group = groups.setdefault(ids[0], {"kind": kind, "directions": {}})
        if group["kind"] != kind:
            raise ValueError(f"Mixed NPC and combat layouts for {ids[0]}")
        valid_rows = {
            "directional_npc": (6,), "directional_combat": (4,),
            "directional_rows_npc": (4, 12), "directional_rows_combat": (7, 8),
            "directional_rows_enemy": (7,),
        }[kind]
        if layout["columns"] != 6 or layout["rows"] not in valid_rows:
            raise ValueError(f"Unexpected directional layout for {entry['id']}")
        combined = kind == "directional_npc" or (kind == "directional_rows_npc" and layout["rows"] == 12)
        for direction in ("front", "back", "right") if combined else [layout.get("direction")]:
            if direction not in ("front", "back", "right"):
                raise ValueError(f"Invalid direction for {entry['id']}: {direction}")
            if direction in group["directions"]:
                raise ValueError(f"Duplicate {direction} sheet for {ids[0]}")
            group["directions"][direction] = entry
    characters, pending = [], []
    for identifier, group in sorted(groups.items()):
        directions = group["directions"]
        if len(directions) != 3:
            pending.append(identifier)
            continue
        npc = group["kind"] in ("directional_npc", "directional_rows_npc")
        sheets = {direction: frame_json(entry, direction, npc)
                  for direction, entry in directions.items()}
        def timing(sheet: dict) -> dict:
            return {name: (len(animation["images"]), animation["ips"], animation["boucle"],
                           tuple(animation.get("coup", [])), animation.get("onde", -1))
                    for name, animation in sheet["animations"].items()}
        expected_timing = timing(sheets["right"])
        if any(timing(sheet) != expected_timing for sheet in sheets.values()):
            raise ValueError(f"Direction changes would alter animation timing or combat windows for {identifier}")
        directory = OUTPUT / "characters" / identifier
        directory.mkdir(parents=True, exist_ok=True)
        right = directions["right"]
        declared_height = right.get("height_m", 1.5)
        if not isinstance(declared_height, (int, float)) or declared_height <= 0:
            raise ValueError(f"Invalid height_m for {identifier}")
        external = [
            '[ext_resource type="Script" path="res://src/visuals/skin_data.gd" id="1_skin"]'
        ]
        textures = {}
        texture_refs = {}
        json_refs = {}
        for direction in ("front", "back", "right"):
            entry = directions[direction]
            texture_path = entry["texture_path"]
            if texture_path not in textures:
                texture_id = "texture_" + direction
                textures[texture_path] = texture_id
                external.append(
                    f'[ext_resource type="Texture2D" path={json.dumps(texture_path)} id="{texture_id}"]'
                )
            texture_refs[direction] = textures[texture_path]
            json_path = directory / f"{direction}.json"
            json_path.write_text(
                json.dumps(sheets[direction], ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            json_refs[direction] = "json_" + direction
            resource_path = "res://" + json_path.relative_to(ROOT).as_posix()
            external.append(
                f'[ext_resource type="JSON" path={json.dumps(resource_path)} id="json_{direction}"]'
            )
        portrait_line = ""
        portrait_path = right.get("portrait_path")
        if not portrait_path:
            candidate = ROOT / f"assets/characters/{identifier}/{identifier}_portrait.png"
            if candidate.is_file():
                portrait_path = "res://" + candidate.relative_to(ROOT).as_posix()
        if portrait_path:
            portrait_path = "res://" + portrait_path.removeprefix("res://")
        elif group["kind"] == "directional_combat":
            portrait_path = right["atlas_resources"][23]["path"]
        if portrait_path:
            external.append(
                f'[ext_resource type="Texture2D" path={json.dumps(portrait_path)} id="portrait"]'
            )
            portrait_line = 'portrait = ExtResource("portrait")\n'

        def references(values: dict) -> str:
            return "{\n" + ",\n".join(
                f'{json.dumps(key)}: ExtResource("{value}")' for key, value in values.items()
            ) + "\n}"

        display_name = right.get("character_name", right.get("name", identifier))
        measured = all(entry.get("frames_json_path") or entry.get("frames_json_paths")
                       for entry in directions.values())
        status = "measured_crops_animation_review" if measured else "directional_animation_draft"
        text = (
            '[gd_resource type="Resource" script_class="SkinData" '
            f'load_steps={len(external) + 1} format=3]\n\n'
            + "\n".join(external) + "\n\n[resource]\n"
            + 'script = ExtResource("1_skin")\n'
            + f'id = &"{identifier}"\n'
            + f'display_name = {json.dumps(display_name, ensure_ascii=False)}\n'
            + f'sprite_sheet = ExtResource("{texture_refs["right"]}")\n'
            + 'frames_json = ExtResource("json_right")\n'
            + f'directional_sheets = {references(texture_refs)}\n'
            + f'directional_frames_json = {references(json_refs)}\n'
            + f'texture_filter = {int(right.get("texture_filter", 0 if "rows" in group["kind"] else 1))}\n'
            + portrait_line + f'height_m = {float(declared_height)}\n'
            + f'metadata/status = "{status}"\n'
            + 'metadata/validated_for_animation = false\n'
        )
        resource = directory / f"{identifier}.tres"
        resource.write_text(text, encoding="utf-8")
        characters.append({
            "id": identifier, "name": display_name,
            "skin_path": "res://" + resource.relative_to(ROOT).as_posix(),
            "status": status, "height_m": float(declared_height),
            "directions": ["front", "back", "right"], "left": "mirror_right",
            "animations": list(frame_json(right, "right", npc)["animations"]),
            "combat": not npc, "enemy": group["kind"] == "directional_rows_enemy",
            "registered_as_playable_skin": False,
            "limitations": [
                "Measured rectangles are supplied; review visual order and complete limbs."
                if measured else "Grid frames are draft crops; check pose order and overlap.",
                "Foot contact and animation anchors still require visual review.",
                "Review animation cycles, scale, direction consistency and combat timing before live use.",
            ],
        })
    return characters, pending


def png_dimensions(path: Path) -> tuple[int, int]:
    with path.open("rb") as stream:
        header = stream.read(24)
    if len(header) != 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise ValueError(f"Not a PNG with an IHDR header: {path}")
    width, height = struct.unpack(">II", header[16:24])
    if width == 0 or height == 0:
        raise ValueError(f"Empty PNG dimensions: {path}")
    return width, height


def resource_text(texture_path: str, region: tuple[int, int, int, int]) -> str:
    x, y, width, height = region
    quoted = json.dumps(texture_path, ensure_ascii=False)
    return (
        '[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
        f'[ext_resource type="Texture2D" path={quoted} id="1_texture"]\n\n'
        '[resource]\n'
        'atlas = ExtResource("1_texture")\n'
        f'region = Rect2({x}, {y}, {width}, {height})\n'
        'filter_clip = true\n'
        'metadata/validated_for_animation = false\n'
    )


def make_resources(catalog_path: Path) -> dict:
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    entries = catalog.get("entries")
    if not isinstance(entries, list):
        raise ValueError("The source catalogue must contain an entries array.")
    prepared = []
    pending_textures = []
    archived_entries = []
    seen = set()
    for source in entries:
        entry = dict(source)
        identifier = entry["id"]
        if entry.get("archived") or entry.get("style") == "anime_archive":
            archived_entries.append(identifier)
            continue
        if not isinstance(identifier, str) or not re.fullmatch(r"[a-z0-9_-]+", identifier):
            raise ValueError(f"Invalid resource id: {identifier!r}")
        relative_path = entry["path"].removeprefix("res://")
        image = (ROOT / relative_path).resolve()
        image.relative_to((ROOT / "assets").resolve())
        if not image.is_file():
            pending_textures.append(identifier)
            continue
        ignored = False
        for folder in image.parents:
            if folder == ROOT:
                break
            if (folder / ".gdignore").exists():
                ignored = True
                break
        if ignored:
            archived_entries.append(identifier)
            continue
        if identifier in seen:
            raise ValueError(f"Duplicate resource id: {identifier}")
        seen.add(identifier)
        width, height = png_dimensions(image)
        entry["dimensions"] = [width, height]
        entry["texture_path"] = "res://" + image.relative_to(ROOT).as_posix()
        entry["atlas_resources"] = []
        entry["validated_for_animation"] = False
        if isinstance(entry.get("limitations"), str):
            entry["limitations"] = [entry["limitations"]]
        layout = entry.get("layout")
        direction = (layout or {}).get("direction", "right")
        supplied = supplied_frame_json(entry, direction)
        if supplied is not None:
            entry["status"] = "measured_crops_animation_review"
            for animation_name, animation in supplied["animations"].items():
                if not re.fullmatch(r"[a-z0-9_-]+", animation_name):
                    raise ValueError(f"Invalid animation name for {identifier}: {animation_name}")
                for frame_number, frame in enumerate(animation["images"]):
                    resource_name = f"{identifier}/{animation_name}_{frame_number:02d}.tres"
                    entry["atlas_resources"].append({
                        "animation": animation_name, "frame": frame_number,
                        "path": "res://data/visuals2d/generated/" + resource_name,
                        "region": frame[:4], "anchor": frame[4:],
                    })
        elif layout is not None:
            columns, rows = layout["columns"], layout["rows"]
            if (
                type(columns) is not int or type(rows) is not int
                or not 1 <= columns <= width or not 1 <= rows <= height
                or columns * rows > 1024
            ):
                raise ValueError(f"Invalid declared grid for {identifier}: {layout}")
            for row in range(rows):
                for column in range(columns):
                    x, y = column * width // columns, row * height // rows
                    right = (column + 1) * width // columns
                    bottom = (row + 1) * height // rows
                    resource_name = f"{identifier}/r{row + 1:02d}_c{column + 1:02d}.tres"
                    entry["atlas_resources"].append({
                        "row": row, "column": column,
                        "path": "res://data/visuals2d/generated/" + resource_name,
                        "region": [x, y, right - x, bottom - y],
                    })
        prepared.append(entry)

    # Validate all inputs before writing any resources.
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for entry in prepared:
        for atlas in entry["atlas_resources"]:
            destination = ROOT / atlas["path"].removeprefix("res://")
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(
                resource_text(entry["texture_path"], tuple(atlas["region"])), encoding="utf-8"
            )
    characters, pending = make_character_resources(prepared)
    result = {
        "status": "review_only",
        "source_catalog": catalog_path.relative_to(ROOT).as_posix(),
        "limitations": [
            "Regular regions follow declared layout; poses and effects may cross cell edges.",
            "Animations, timing, feet anchors and gameplay hit frames are not validated.",
            "No existing SkinData, sprites or game scenes are replaced.",
        ],
        "entries": prepared,
        "characters": characters,
        "pending_directional_characters": pending,
        "pending_textures": pending_textures,
        "archived_entries": archived_entries,
        "stats": {
            "textures": len(prepared),
            "atlas_resources": sum(len(entry["atlas_resources"]) for entry in prepared),
            "complete_directional_characters": len(characters),
            "combat_characters": sum(character["combat"] and not character["enemy"] for character in characters),
            "npc_characters": sum(not character["combat"] for character in characters),
            "enemy_characters": sum(character["enemy"] for character in characters),
        },
    }
    (OUTPUT / "catalog.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    # This directory is generated exclusively by this tool. Remove previews from
    # obsolete uniform grids and characters now retained only in the art archive.
    current_paths = {OUTPUT / "catalog.json"}
    current_paths.update(ROOT / atlas["path"].removeprefix("res://")
                         for entry in prepared for atlas in entry["atlas_resources"])
    for character in characters:
        skin_path = ROOT / character["skin_path"].removeprefix("res://")
        current_paths.add(skin_path)
        current_paths.update(skin_path.parent / f"{direction}.json"
                             for direction in character["directions"])
    for generated_path in OUTPUT.rglob("*"):
        if (generated_path.is_file() and generated_path.suffix in (".tres", ".json")
                and generated_path not in current_paths):
            generated_path.unlink()
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--activate-pixel-skins", action="store_true",
                        help="Replace the seven registered SukaSuka skins and Timere using complete measured sheets.")
    args = parser.parse_args()
    result = make_resources(args.catalog.resolve())
    if args.activate_pixel_skins:
        activate_pixel_skins(result)
        publish_npc_resources(result)
        result["activation"] = {
            "playable_skin_ids": ["sukasuka_" + identifier for identifier in PLAYABLE_PIXEL_IDS],
            "default_skin_id": "chtholly", "enemy_visual_id": "timere",
            "animation_review_pending": True,
        }
        result["limitations"][-1] = "Registered pixel skins are active; animation cycles still require visual review."
        (OUTPUT / "catalog.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                                             encoding="utf-8")
    count = sum(len(entry["atlas_resources"]) for entry in result["entries"])
    print(
        f"{len(result['entries'])} textures, {count} review-only AtlasTexture resources, "
        f"{len(result['characters'])} complete directional animation drafts."
    )


def activate_pixel_skins(result: dict) -> None:
    """Explicit activation preserves registry identities and enemy scale variants."""
    characters = {character["id"]: character for character in result["characters"]}
    for identifier in (*PLAYABLE_PIXEL_IDS, "timere"):
        if (identifier not in characters or characters[identifier]["status"]
                != "measured_crops_animation_review"):
            raise ValueError(f"Activation requires three measured views for {identifier}")
        if identifier != "timere":
            portrait = ROOT / f"assets/characters/{identifier}/{identifier}_portrait.png"
            if not portrait.is_file() or png_dimensions(portrait) != (256, 256):
                raise ValueError(f"Activation requires the 256 x 256 portrait for {identifier}")
    updates = []
    for identifier in (*PLAYABLE_PIXEL_IDS, "timere"):
        generated = ROOT / characters[identifier]["skin_path"].removeprefix("res://")
        targets = [ROOT / (f"data/enemies/visuals/{identifier}.tres" if identifier == "timere"
                           else f"data/skins/sukasuka_{identifier}.tres")]
        if identifier == "chtholly":
            targets.append(ROOT / "data/skins/chtholly.tres")
        for target in targets:
            previous = target.read_text(encoding="utf-8")
            skin_id = re.search(r'^id = (&".*")$', previous, re.MULTILINE).group(1)
            name = json.loads(re.search(r'^display_name = (".*")$', previous, re.MULTILINE).group(1))
            name = name.removesuffix(" · 3D")
            text = generated.read_text(encoding="utf-8")
            text = re.sub(r'^id = .*$', lambda _: "id = " + skin_id, text, flags=re.MULTILINE)
            text = re.sub(r'^display_name = .*$', lambda _: "display_name = " + json.dumps(name, ensure_ascii=False),
                          text, flags=re.MULTILINE)
            for direction in ("front", "back", "right"):
                basename = identifier + ("" if direction == "right" else "_" + direction)
                asset_directory = "enemies" if identifier == "timere" else "characters"
                actual_json = f"assets/{asset_directory}/{identifier}/{basename}.json"
                if not (ROOT / actual_json).is_file():
                    raise ValueError(f"Activation frame JSON missing: {actual_json}")
                text = text.replace(f"res://data/visuals2d/generated/characters/{identifier}/{direction}.json",
                                    "res://" + actual_json)
            updates.append((target, text))
    for target, text in updates:
        target.write_text(text, encoding="utf-8")
    for identifier in PLAYABLE_PIXEL_IDS:
        characters[identifier]["registered_as_playable_skin"] = True
        characters[identifier]["runtime_skin_path"] = f"res://data/skins/sukasuka_{identifier}.tres"
    characters["timere"]["runtime_skin_path"] = "res://data/enemies/visuals/timere.tres"
    print("Activated seven pixel skins, default Chtholly and shared directional Timere visual.")


def publish_npc_resources(result: dict) -> None:
    """Keep NPC dependencies available when the review workshop is excluded from Web."""
    published = 0
    for character in result["characters"]:
        if character["combat"] or character["status"] != "measured_crops_animation_review":
            continue
        identifier = character["id"]
        generated = ROOT / character["skin_path"].removeprefix("res://")
        text = generated.read_text(encoding="utf-8")
        for direction in character["directions"]:
            basename = identifier + ("" if direction == "right" else "_" + direction)
            json_path = f"assets/characters/{identifier}/{basename}.json"
            if not (ROOT / json_path).is_file():
                raise ValueError(f"NPC frame JSON missing: {json_path}")
            text = text.replace(f"res://data/visuals2d/generated/characters/{identifier}/{direction}.json",
                                "res://" + json_path)
        destination = ROOT / f"data/visuals2d/characters/{identifier}/{identifier}.tres"
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(text, encoding="utf-8")
        character["runtime_skin_path"] = "res://" + destination.relative_to(ROOT).as_posix()
        published += 1
    print(f"Published {published} measured NPC resources outside the review directory.")


if __name__ == "__main__":
    main()
