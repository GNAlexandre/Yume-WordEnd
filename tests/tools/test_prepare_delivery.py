"""Regression checks for silhouette cutting and lossless source preservation."""

import importlib.util
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("delivery", ROOT / "tools/sukasuka2d/prepare_delivery.py")
DELIVERY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DELIVERY)


class SilhouetteCutTests(unittest.TestCase):
    def sheet(self):
        image = Image.new("RGBA", (32, 30))
        # Separated bent silhouettes whose bounding rectangles overlap.
        for x, y, color in [(2, 2, (160, 40, 20, 255)), (18, 12, (30, 140, 80, 255))]:
            for dy in range(14):
                image.putpixel((x, y + dy), color)
            for dx in range(12):
                image.putpixel((x + dx, y + 13), color)
        return image

    def entry(self, count):
        return {"layout": {"kind": "directional_rows_enemy", "rows": 1, "columns": count, "direction": "right"},
                "clip_contract": [["mort", count, 8, False]]}

    def test_overlapping_bounds_do_not_mix_separate_silhouettes(self):
        source = self.sheet()
        original = source.tobytes()
        rows, portraits = DELIVERY.cut_rows(source, self.entry(2))
        self.assertEqual(portraits, [])
        poses = rows["right"][0][3]
        self.assertEqual(len(poses), 2)
        for pose, expected in zip(poses, [(160, 40, 20, 255), (30, 140, 80, 255)]):
            colors = {p for p in pose.getdata() if p[3]}
            self.assertEqual(colors, {expected})
            self.assertEqual(sum(p[3] > 0 for p in pose.getdata()), 25)
        self.assertEqual(source.tobytes(), original)

    def test_missing_pose_is_rejected_instead_of_duplicated(self):
        with self.assertRaisesRegex(ValueError, "missing or touching"):
            DELIVERY.cut_rows(self.sheet(), self.entry(3))

    def test_palette_fitting_keeps_binary_alpha_and_limits_colors(self):
        image = Image.new("RGBA", (16, 16))
        for y in range(16):
            for x in range(16):
                image.putpixel((x, y), (x * 16, y * 16, (x + y) * 8, 255 if x > 2 else 0))
        alpha = image.getchannel("A").tobytes()
        fitted = DELIVERY.hd.pixel_palette(image, 16)
        self.assertEqual(fitted.mode, "RGBA")
        self.assertEqual(fitted.getchannel("A").tobytes(), alpha)
        self.assertLessEqual(len({p[:3] for p in fitted.getdata()}), 16)


class PoseCorrectionTests(unittest.TestCase):
    def source_sheet(self, small_dialogue=False, stacked_course=False):
        image = Image.new("RGBA", (320, 1000))
        for row, count in enumerate([2, 6, 4, 2]):
            for column in range(count):
                height = 50 if small_dialogue and row == 3 else 100
                if stacked_course and row == 2 and column == 0:
                    height = 200
                pose = Image.new("RGBA", (30, height), (40 + column * 20, 80 + row * 20, 90, 255))
                image.paste(pose, (10 + column * 50, 10 + row * 240))
        return image

    def entry(self, replacement):
        return {"id": "fixture", "name": "Fixture", "category": "characters",
                "character_ids": ["fixture"], "height_m": 2,
                "source_path": "source.png", "animation_sources": replacement,
                "layout": {"kind": "directional_rows_npc", "direction": "right", "rows": 4, "columns": 6}}

    def run_correction(self, directory, source, replacement, count):
        root = Path(directory)
        source.save(root / "source.png")
        strip = Image.new("RGBA", (count * 60, 130))
        for index in range(count):
            strip.paste(Image.new("RGBA", (30, 100), (220, 100, 70, 255)), (index * 60 + 10, 10))
        strip.save(root / "correction.png")
        original_hash = hashlib.sha256((root / "source.png").read_bytes()).hexdigest()
        with patch.object(DELIVERY, "ROOT", root):
            output = DELIVERY.prepare_sprite(self.entry(replacement))
        self.assertEqual(original_hash, hashlib.sha256((root / "source.png").read_bytes()).hexdigest())
        metadata = json.loads((root / output[0]["frames_json_path"]).read_text())
        return metadata

    def test_dialogue_replacement_uses_idle_height_instead_of_miniature_original(self):
        with tempfile.TemporaryDirectory() as directory:
            data = self.run_correction(directory, self.source_sheet(small_dialogue=True),
                                       {"parle": {"source_path": "correction.png", "rows": 1, "row": 0,
                                                  "count": 2, "original_count": 2, "scale_reference": "idle"}}, 2)
        self.assertEqual([frame[3] for frame in data["animations"]["parle"]["images"]], [192, 192])

    def test_single_pose_replacement_preserves_other_running_poses(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = self.source_sheet(stacked_course=True)
            source.save(root / "source.png")
            with patch.object(DELIVERY, "ROOT", root):
                previous = DELIVERY.prepare_sprite(self.entry({}))[0]
            before_metadata = json.loads((root / previous["frames_json_path"]).read_text())
            with Image.open(root / previous["path"]) as image:
                originals = [image.crop((r[0], r[1], r[0] + r[2], r[1] + r[3])).tobytes()
                             for r in before_metadata["animations"]["course"]["images"][1:]]
            data = self.run_correction(directory, source,
                                       {"course": {"source_path": "correction.png", "rows": 1, "row": 0,
                                                   "count": 1, "original_count": 4, "indices": [0],
                                                   "scale_reference": "idle"}}, 1)
            frames = data["animations"]["course"]["images"]
            self.assertEqual(len(frames), 4)
            self.assertEqual(frames[0][3], 192)
            with Image.open(root / previous["path"]) as image:
                retained = [image.crop((r[0], r[1], r[0] + r[2], r[1] + r[3])).tobytes() for r in frames[1:]]
            self.assertEqual(originals, retained)

    def test_invalid_pose_index_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, "invalid replacement frame indices"):
                self.run_correction(directory, self.source_sheet(),
                                    {"course": {"source_path": "correction.png", "rows": 1, "row": 0,
                                                "count": 1, "original_count": 4, "indices": [4]}}, 1)


if __name__ == "__main__":
    unittest.main()
