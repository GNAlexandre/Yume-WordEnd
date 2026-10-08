"""Regression checks for silhouette cutting and lossless source preservation."""

import importlib.util
import unittest
from pathlib import Path

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


if __name__ == "__main__":
    unittest.main()
