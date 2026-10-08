"""Contract checks and destructive-input protection for the HD-2D delivery tools."""

import hashlib
import importlib.util
import json
import re
import tempfile
import unittest
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("hd2d_assets", ROOT / "tools/hd2d_assets.py")
ASSETS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ASSETS)


class ManifestContractTests(unittest.TestCase):
    def setUp(self):
        self.manifest = ASSETS.load_manifest()
        self.entries = {entry["path"]: entry for entry in self.manifest["entries"]}

    def test_explicit_decor_tables_match_manifest_paths_and_dimensions(self):
        document = (ROOT / self.manifest["source_document"]).read_text(encoding="utf-8")
        section, subsection = "", ""
        expected = {}
        for line in document.splitlines():
            if line.startswith("## "):
                section, subsection = line.split()[1].rstrip("."), ""
            elif line.startswith("### "):
                subsection = line.split()[1]
            if not re.match(r"\| [1-4] \|", line):
                continue
            columns = [column.strip() for column in line.strip("|").split("|")]
            filename = re.search(r"`([^`]+)`", columns[1]).group(1)
            if section == "4":
                expected["assets/hd2d/ground/" + filename + ".png"] = [384, 384]
            elif section == "5":
                expected["assets/hd2d/cliff/" + filename] = list(map(int, re.search(r"(\d+) × (\d+)", columns[2]).groups()))
            elif section == "6" and subsection == "6.1":
                expected["assets/hd2d/buildings/" + filename + ".png"] = list(map(int, re.search(r"(\d+) × (\d+)", columns[2]).groups()))
            elif section == "6" and subsection == "6.2":
                expected["assets/hd2d/buildings/materials/" + filename + ".png"] = [192, 192]
            elif section == "7":
                expected["assets/hd2d/props/" + filename + ".png"] = list(map(int, re.search(r"(\d+) × (\d+)", columns[2]).groups()))
            elif section == "8":
                expected["assets/hd2d/sky/" + filename] = list(map(int, re.search(r"(\d+) × (\d+)", columns[2]).groups()))
        actual = {path: entry["size"] for path, entry in self.entries.items() if path.startswith("assets/hd2d/") and "/fx/" not in path}
        self.assertEqual(expected, actual)
        self.assertGreater(len(expected), 90)

    def test_character_resting_heights_and_portraits_match_document(self):
        document = (ROOT / self.manifest["source_document"]).read_text(encoding="utf-8")
        rows = re.findall(r"\| [1-4] \| `([^`]+)`[^|]*\| [\d.,]+ m = (\d+) px", document)
        self.assertEqual(len(rows), 21)
        for stem, height in rows:
            base = str(ROOT / "assets/characters" / stem)
            # The document explicitly uses ../enemies for Timere.
            base = str(Path(base).resolve().relative_to(ROOT))
            self.assertEqual(self.entries[base + ".png"]["idle_height_px"], int(height))
            if "enemies/" not in base:
                self.assertEqual(self.entries[base + "_portrait.png"]["size"], [256, 256])
        self.assertEqual(self.manifest["density_px_m"], 96)
        self.assertEqual(self.entries["assets/characters/ithea/ithea.png"]["animations"]["parle"], {"frames": 2, "fps": 6, "loop": True})


class AssetDeliveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.entry = {"path": "assets/hd2d/props/test.png", "size": [4, 6], "kind": "prop", "alpha": "binary", "placement": "bottom_center", "required": True}
        self.manifest = {"entries": [self.entry], "max_image_bytes": 1_000_000, "max_total_image_bytes": 25_000_000}

    def write(self, image, relative=None):
        path = self.root / (relative or self.entry["path"])
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path, format="PNG")
        return path

    def valid_panel(self):
        image = Image.new("RGBA", (4, 6), (0, 0, 0, 0))
        for y in range(2, 6):
            for x in range(1, 3):
                image.putpixel((x, y), (100, 70, 40, 255))
        return image

    def test_zero_assets_never_pass_even_with_allow_missing(self):
        self.assertFalse(ASSETS.check_assets(self.root, self.manifest)["ok"])
        partial = ASSETS.check_assets(self.root, self.manifest, allow_missing=True)
        self.assertFalse(partial["ok"])
        self.assertTrue(partial["errors"])

    def test_supplied_asset_does_not_hide_other_missing_required_assets(self):
        self.write(self.valid_panel())
        self.manifest["entries"].append({**self.entry, "path": "assets/hd2d/props/absent.png"})
        result = ASSETS.check_assets(self.root, self.manifest)
        self.assertEqual((result["provided"], result["missing_required"]), (1, 1))
        self.assertFalse(result["ok"])
        self.assertTrue(ASSETS.check_assets(self.root, self.manifest, allow_missing=True)["ok"])

    def test_partial_alpha_and_empty_ground_baseline_are_rejected(self):
        image = self.valid_panel()
        image.putpixel((1, 5), (100, 70, 40, 128))
        self.write(image)
        self.assertTrue(any("Alpha intermédiaire" in error for error in ASSETS.inspect_image(self.root, self.entry, self.manifest)["errors"]))
        for x in range(4):
            image.putpixel((x, 5), (0, 0, 0, 0))
        self.write(image)
        self.assertTrue(any("Ligne vide" in error for error in ASSETS.inspect_image(self.root, self.entry, self.manifest)["errors"]))

    def test_seam_checker_detects_opposite_edge_mismatch(self):
        entry = {**self.entry, "size": [4, 4], "kind": "ground", "alpha": "opaque", "placement": None, "seamless_axes": ["x", "y"]}
        image = Image.new("RGBA", (4, 4), (80, 90, 40, 255))
        image.putpixel((0, 1), (180, 90, 40, 255))
        self.write(image)
        self.assertTrue(any("Raccord x" in error for error in ASSETS.inspect_image(self.root, entry, self.manifest)["errors"]))

    def test_fit_archives_originals_and_outputs_exact_binary_alpha(self):
        old = self.write(self.valid_panel())
        old_hash = hashlib.sha256(old.read_bytes()).hexdigest()
        raw = Image.new("RGBA", (20, 30), (0, 0, 0, 0))
        for y in range(5, 25):
            for x in range(5, 15):
                raw.putpixel((x, y), (140, 95, 60, 255 if x > 5 else 90))
        source = self.write(raw, "raw.png")
        source_bytes = source.read_bytes()
        result = ASSETS.fit_asset(self.root, self.manifest, self.entry["path"], source)
        self.assertEqual(result["check"]["errors"], [])
        self.assertEqual(source.read_bytes(), source_bytes)
        previous = self.root / result["archives"]["previous_png"]
        self.assertEqual(hashlib.sha256(previous.read_bytes()).hexdigest(), old_hash)
        with Image.open(old) as fitted:
            self.assertEqual(fitted.size, (4, 6))
            self.assertEqual(fitted.mode, "RGBA")
            self.assertEqual(sum(fitted.getchannel("A").histogram()[1:255]), 0)

    def test_fit_refuses_opaque_background_instead_of_inventing_a_cutout(self):
        source = self.write(Image.new("RGBA", (20, 30), (100, 70, 40, 255)), "raw.png")
        with self.assertRaisesRegex(ValueError, "fond transparent"):
            ASSETS.fit_asset(self.root, self.manifest, self.entry["path"], source)
        self.assertFalse((self.root / self.entry["path"]).exists())

    def test_padding_is_not_mistaken_for_upscaling(self):
        raw = Image.new("RGBA", (20, 30), (0, 0, 0, 0))
        for y in range(2, 28):
            raw.putpixel((10, y), (140, 95, 60, 255))
        source = self.write(raw, "raw.png")
        result = ASSETS.fit_asset(self.root, self.manifest, self.entry["path"], source)
        self.assertFalse(result["upscaled"])

    def test_sheet_fit_scales_metadata_and_preserves_hit_frames(self):
        entry = {"path": "assets/characters/test/test.png", "kind": "sprite", "size": None, "alpha": "binary", "json_path": "assets/characters/test/test.json", "idle_height_px": 2, "animations": {"repos": {"frames": 1, "fps": 2, "loop": True}}}
        self.manifest["entries"] = [entry]
        raw = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
        for y in range(2, 6):
            for x in range(2, 6):
                raw.putpixel((x, y), (100, 70, 40, 255))
        source = self.write(raw, "raw.png")
        frames = self.root / "raw.json"
        frames.write_text(json.dumps({"planche": [10, 10], "animations": {"repos": {"ips": 2, "boucle": True, "images": [[2, 2, 4, 4, 2, 4]], "coup": [0]}}}))
        result = ASSETS.fit_asset(self.root, self.manifest, entry["path"], source, frames_json=frames)
        data = json.loads((self.root / entry["json_path"]).read_text())
        self.assertEqual(result["check"]["errors"], [])
        self.assertEqual(data["planche"], [5, 5])
        self.assertEqual(data["animations"]["repos"]["images"][0], [1, 1, 2, 2, 1, 2])
        self.assertEqual(data["animations"]["repos"]["coup"], [0])


if __name__ == "__main__":
    unittest.main()
