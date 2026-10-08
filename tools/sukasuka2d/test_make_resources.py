"""Metadata-only tests: packed atlas rectangles and archive isolation."""
import json
import struct
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import make_resources as resources


class ResourceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.output = self.root / "data/visuals2d/generated"
        self.root_patch = patch.object(resources, "ROOT", self.root)
        self.output_patch = patch.object(resources, "OUTPUT", self.output)
        self.root_patch.start()
        self.output_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.addCleanup(self.output_patch.stop)
        self.addCleanup(self.temporary.cleanup)

    def image_header(self, path, width=120, height=240):
        destination = self.root / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(resources.PNG_SIGNATURE + b"\0\0\0\rIHDR" + struct.pack(">II", width, height))

    def entry(self, direction="right", kind="directional_rows_combat"):
        path = f"assets/characters/example/example_{direction}.png"
        self.image_header(path)
        frame_path = path.replace(".png", ".json")
        sheet = {"version": 1, "planche": [120, 240], "animations": {
            "repos": {"ips": 2, "boucle": True, "images": [[7, 3, 31, 63, 12, 63], [42, 5, 45, 61, 22, 61]]},
        }}
        (self.root / frame_path).write_text(json.dumps(sheet))
        return {"id": "example_" + direction, "path": path, "frames_json_path": frame_path,
                "character_ids": ["example"], "height_m": 1.3,
                "layout": {"kind": kind, "columns": 6, "rows": 7, "direction": direction}}

    def generate(self, entries):
        catalog = self.root / "catalog.json"
        catalog.write_text(json.dumps({"entries": entries}))
        return resources.make_resources(catalog)

    def test_measured_rectangles_replace_equal_grid_previews(self):
        result = self.generate([self.entry()])
        atlas = result["entries"][0]["atlas_resources"]
        self.assertEqual([item["region"] for item in atlas], [[7, 3, 31, 63], [42, 5, 45, 61]])
        self.assertEqual(atlas[0]["anchor"], [12, 63])
        text = (self.root / atlas[0]["path"].removeprefix("res://")).read_text()
        self.assertIn("Rect2(7, 3, 31, 63)", text)
        self.assertEqual(result["entries"][0]["status"], "measured_crops_animation_review")

    def test_archived_duplicate_and_godot_ignored_sources_are_skipped(self):
        active = self.entry()
        archive = {**active, "archived": True}
        ignored_path = "assets/source/old.png"
        self.image_header(ignored_path)
        (self.root / "assets/source/.gdignore").touch()
        ignored = {**active, "id": "ignored", "path": ignored_path}
        result = self.generate([archive, active, ignored])
        self.assertEqual(len(result["entries"]), 1)
        self.assertEqual(result["archived_entries"], [active["id"], "ignored"])

    def test_invalid_measured_rectangles_fail_before_writing(self):
        entry = self.entry()
        frame_file = self.root / entry["frames_json_path"]
        sheet = json.loads(frame_file.read_text())
        sheet["animations"]["repos"]["images"][0][0] = 110
        frame_file.write_text(json.dumps(sheet))
        with self.assertRaisesRegex(ValueError, "outside PNG"):
            self.generate([entry])
        self.assertFalse(self.output.exists())

    def test_json_header_must_match_png_dimensions(self):
        entry = self.entry()
        self.image_header(entry["path"], 121, 240)
        with self.assertRaisesRegex(ValueError, "dimension mismatch"):
            self.generate([entry])

    def test_three_separate_npc_views_keep_supplied_clips_and_portrait(self):
        entries = [self.entry(direction, "directional_rows_npc") for direction in ("front", "back", "right")]
        for entry in entries:
            entry["layout"]["rows"] = 4
        entries[-1]["portrait_path"] = "assets/characters/example/example_portrait.png"
        self.image_header(entries[-1]["portrait_path"], 256, 256)
        result = self.generate(entries)
        self.assertEqual(result["stats"]["npc_characters"], 1)
        character = result["characters"][0]
        self.assertFalse(character["registered_as_playable_skin"])
        self.assertEqual(character["animations"], ["repos"])
        text = (self.root / character["skin_path"].removeprefix("res://")).read_text()
        self.assertIn('portrait = ExtResource("portrait")', text)
        self.assertIn('metadata/status = "measured_crops_animation_review"', text)

    def test_enemy_draft_uses_its_own_timing_and_hit_frames(self):
        entry = {"id": "timere_right", "dimensions": [600, 700],
                 "layout": {"kind": "directional_rows_enemy", "columns": 6, "rows": 7}}
        animations = resources.frame_json(entry, "right", False)["animations"]
        self.assertEqual([len(animation["images"]) for animation in animations.values()], [5, 4, 6, 4, 4, 5, 6])
        self.assertEqual([animation["ips"] for animation in animations.values()], [6, 7, 12, 8, 8, 12, 8])
        self.assertEqual(animations["fouet"]["coup"], [1, 2])
        self.assertEqual(animations["morsure"]["coup"], [1, 2])
        self.assertNotIn("charge", animations)

    def test_direction_changes_cannot_change_supplied_animation_timing(self):
        entries = [self.entry(direction) for direction in ("front", "back", "right")]
        front = self.root / entries[0]["frames_json_path"]
        sheet = json.loads(front.read_text())
        sheet["animations"]["repos"]["ips"] = 3
        front.write_text(json.dumps(sheet))
        with self.assertRaisesRegex(ValueError, "alter animation timing"):
            self.generate(entries)


if __name__ == "__main__":
    unittest.main()
