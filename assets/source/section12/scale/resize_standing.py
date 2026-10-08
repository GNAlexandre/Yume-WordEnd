#!/usr/bin/env python3
"""Exact nearest-neighbour format corrections; restores real dialogue, never draws poses.
Run from anywhere with Pillow: python assets/source/section12/scale/resize_standing.py
Source snapshots make the operation repeatable and preserve the pre-correction assets.
"""
import copy
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
import hd2d_sheets as sheets

# Animations not listed here retain their RGBA crop and local anchor exactly.
CASES = {
    'pannibal': {'repos': 120, 'marche': 120, 'parle': 120},
    'chtholly_front': {'uniform_scale': 144 / 130},
    'tiat': {'marche': 106, 'parle': 106},
    'tiat_front': {'marche': 106, 'parle': 106},
    'tiat_back': {'marche': 106, 'parle': 106},
    'egg_vendor_back': {'marche': 149, 'parle': 149},
    'egg_vendor': {'marche': 'idle'},
    'collon_front': {'marche': 'idle'},
    'collon_back': {'marche': 'idle'},
    'almita': {'marche': 'idle'},
    'almita_back': {'marche': 'idle'},
    'ramikeldi_front': {'marche': 'idle'},
    'ramikeldi_back': {'marche': 'idle'},
    'garde_lookout_back': {'marche': 'idle'},
}
RESTORE_DIALOGUE = {'tiat', 'tiat_front', 'tiat_back', 'egg_vendor_back'}
SOURCE_REV = '4475ff1'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def stem_for(name):
    identifier = name.removesuffix('_front').removesuffix('_back')
    return Path('assets/characters') / identifier / name


def snapshot(path, dest):
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(path.read_bytes())
    return dest.read_bytes()


def crop(image, rect):
    return image.crop((rect[0], rect[1], rect[0] + rect[2], rect[1] + rect[3]))


def height(image, rect):
    return int(rect[5]) - sheets.top_of(image)


def fit(image, anchor, target):
    """Scale the drawing relative to its foot anchor, not its total bbox height.
    Rounded NN geometry may shift the foot's pixel boundary by <=1px. Explicit target
    anchor restores that boundary; it never makes a miniature sprite pass via JSON alone.
    """
    original = anchor[1] - sheets.top_of(image)
    factor = target / original
    size = (max(1, round(image.width * factor)), max(1, round(image.height * factor)))
    resized = image.resize(size, Image.Resampling.NEAREST)
    result = [round(anchor[0] * factor), target + sheets.top_of(resized)]
    assert abs(result[1] - anchor[1] * factor) <= 1.1
    assert result[1] <= resized.height + 2
    return resized, result, factor


def run():
    report = {'operation': 'nearest-neighbour format correction, no newly drawn art',
              'standing_measure': 'foot anchor y minus first opaque row',
              'restore_source_revision': SOURCE_REV, 'sheets': []}
    previews = []
    for name, config in CASES.items():
        stem = stem_for(name)
        before_png = snapshot(ROOT / stem.with_suffix('.png'), HERE / 'before' / (name + '.png'))
        before_json = snapshot(ROOT / stem.with_suffix('.json'), HERE / 'before' / (name + '.json'))
        data = json.loads(before_json)
        image = Image.open(io.BytesIO(before_png)).convert('RGBA')
        original = copy.deepcopy(data)
        source_data, source_image = None, None
        if name in RESTORE_DIALOGUE:
            # Main's JSON aliases talk to idle, and its trim removed the actual talk pixels.
            # Read the historical drawing, never copy idle frames to fabricate dialogue.
            native = HERE / 'historical' / name
            native.parent.mkdir(parents=True, exist_ok=True)
            for suffix in ('.png', '.json'):
                dest = native.with_suffix(suffix)
                if not dest.exists():
                    dest.write_bytes(subprocess.check_output(['git', 'show', SOURCE_REV + ':' + str(stem.with_suffix(suffix))], cwd=ROOT))
            source_data = json.loads(native.with_suffix('.json').read_text())
            source_image = Image.open(native.with_suffix('.png')).convert('RGBA')
        first_idle = data['animations']['repos']['images'][0]
        idle_height = height(crop(image, first_idle), first_idle)
        entries, rows, untouched = [], [], []
        for animation, info in data['animations'].items():
            restored = animation == 'parle' and name in RESTORE_DIALOGUE
            frames = source_data['animations'][animation]['images'] if restored else info['images']
            src_image = source_image if restored else image
            row = []
            for index, frame in enumerate(frames):
                part = crop(src_image, frame)
                anchor = frame[4:6]
                if restored:
                    anchor = sheets.compute_anchor(part, feet='dark', axis=True)
                old_height = anchor[1] - sheets.top_of(part)
                target = config.get(animation)
                if target == 'idle':
                    target = idle_height
                if 'uniform_scale' in config:
                    factor = config['uniform_scale']
                    adjusted = part.resize((round(part.width * factor), round(part.height * factor)), Image.Resampling.NEAREST)
                    new_anchor = [round(anchor[0] * factor), round(anchor[1] * factor)]
                elif target is not None:
                    adjusted, new_anchor, factor = fit(part, anchor, target)
                else:
                    adjusted, new_anchor, factor = part.copy(), anchor[:], 1
                    untouched.append((animation, index, sha(part.tobytes()), new_anchor))
                record = {'animation': animation, 'index': index,
                          'historical_drawing_restored': restored,
                          'source_standing_height': old_height,
                          'standing_height': new_anchor[1] - sheets.top_of(adjusted),
                          'factor': factor,
                          'source_pixels_sha256': sha(part.tobytes()),
                          'result_pixels_sha256': sha(adjusted.tobytes())}
                entries.append(record)
                row.append((adjusted, new_anchor))
                if target is not None and index == 0:
                    previews.append((name + ' / ' + animation, part.copy(), anchor[:], adjusted.copy(), new_anchor[:]))
            rows.append((animation, row))
        # Pack each row on a shared ground line, preserve all native crop pixels outside edits.
        packed = []
        atlas_w, atlas_h = 0, 0
        for animation, row in rows:
            baseline = max(a[1] for _, a in row)
            row_bottom = max(im.height - a[1] for im, a in row)
            row_height = baseline + row_bottom
            x = 0
            updated = []
            for im, anchor in row:
                y = atlas_h + baseline - anchor[1]
                updated.append([x, y, im.width, im.height, *anchor])
                packed.append((im, x, y))
                x += im.width + 4
            data['animations'][animation]['images'] = updated
            atlas_w = max(atlas_w, x - 4)
            atlas_h += row_height + 4
        atlas_h -= 4
        assert atlas_w <= 2048 and atlas_h <= 2048
        output = Image.new('RGBA', (atlas_w, atlas_h), (0, 0, 0, 0))
        for im, x, y in packed:
            output.paste(im, (x, y))
        data['planche'] = list(output.size)
        assert set(output.getchannel('A').get_flattened_data()) <= {0, 255}
        assert len(output.getcolors(9999999)) <= 65
        for animation, index, digest, anchor in untouched:
            rect = data['animations'][animation]['images'][index]
            assert sha(crop(output, rect).tobytes()) == digest
            assert rect[4:6] == anchor
        # Animation contract is unchanged (only rects and transformed anchors vary).
        for animation, info in original['animations'].items():
            assert {k: v for k, v in info.items() if k != 'images'} == {k: v for k, v in data['animations'][animation].items() if k != 'images'}
            assert len(info['images']) == len(data['animations'][animation]['images'])
        output.save(ROOT / stem.with_suffix('.png'))
        sheets.write_json(str(ROOT / stem.with_suffix('.json')), data)
        report['sheets'].append({'name': name, 'runtime_png': str(stem.with_suffix('.png')),
                                 'before_png_sha256': sha(before_png),
                                 'before_json_sha256': sha(before_json),
                                 'result_png_sha256': sha((ROOT / stem.with_suffix('.png')).read_bytes()),
                                 'dimensions': output.size, 'unchanged_frame_count': len(untouched),
                                 'frames': entries})
        if 'uniform_scale' in config:
            f0 = original['animations']['repos']['images'][0]
            f1 = data['animations']['repos']['images'][0]
            previews.append((name + ' / repos', crop(image, f0), f0[4:6], crop(output, f1), f1[4:6]))
    (HERE / 'report.json').write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
    # Technical comparison only: actual crops aligned by their anchors, no drawn character art.
    chunk_size = 8
    for number, start in enumerate(range(0, len(previews), chunk_size), 1):
        chunk = previews[start:start + chunk_size]
        panel = Image.new('RGB', (1000, len(chunk) * 250), '#292634')
        draw = ImageDraw.Draw(panel)
        for row, (label, before, old_anchor, after, new_anchor) in enumerate(chunk):
            y = row * 250
            draw.text((15, y + 12), label, fill='#f1e7d8')
            for x, im, anchor, caption in [(370, before, old_anchor, 'AVANT'), (725, after, new_anchor, 'APRES')]:
                base = y + 235
                draw.line((x-110, base, x+110, base), fill='#a2a0af')
                panel.paste(im, (x-anchor[0], base-anchor[1]), im)
                draw.text((x-80, y+15), caption + ' / ' + str(anchor[1]-sheets.top_of(im)) + ' px', fill='#f1e7d8')
        panel.save(HERE / ('comparison-%02d.png' % number))
    print('Adjusted %d atlases; real dialogue restored on %d. Before/after previews: %d.' % (len(CASES), len(RESTORE_DIALOGUE), len(previews)))


if __name__ == '__main__':
    run()
