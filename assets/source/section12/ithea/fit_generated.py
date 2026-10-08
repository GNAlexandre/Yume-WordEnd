#!/usr/bin/env python3
"""Technical fitting of image-generated art; does not draw character content."""
from pathlib import Path
import hashlib
import json
import sys
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import label, find_objects

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
import hd2d_sheets as sheets

BASE = Path(__file__).resolve().parent
TARGET = ROOT / 'assets/characters/ithea'
COUNTS = dict(repos=2, marche=6, course=5, attaque=4, charge=4, degats=1, mort=1, parle=2)
LIMITS = {
    'right': [0,200,400,568,800,974,1160,1240,1424],
    'front': [0,205,400,590,835,1040,1220,1330,1542],
    'back': [0,173,353,525,767,925,1090,1200,1458],
}

def fit_pixel(image, scale):
    size = tuple(max(1, round(n * scale)) for n in image.size)
    image = image.resize(size, Image.Resampling.NEAREST)
    image = image.quantize(colors=64, method=Image.Quantize.FASTOCTREE).convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda v: 255 if v >= 128 else 0))
    return image

report = {'authority': 'user_2026-10-08_anime_override_ofnovel', 'views': {}}
for direction, suffix in [('right',''), ('front','_front'), ('back','_back')]:
    name = 'ithea' + suffix
    old = json.loads((BASE / 'originals' / (name + '.json')).read_text())
    source = Image.open(BASE / 'generated' / (direction + '.png')).convert('RGBA')
    pixels = np.array(source)
    labels, n = label(pixels[:,:,3] >= 200)
    objects, counts = find_objects(labels), np.bincount(labels.ravel())
    components = []
    for identifier, region in enumerate(objects, 1):
        if counts[identifier] < 700:
            continue
        box = [region[1].start, region[0].start, region[1].stop, region[0].stop]
        part = np.array(source.crop(box))
        part[:,:,3] = np.where(labels[region] == identifier, 255, 0)
        components.append((box, Image.fromarray(part)))
    assert len(components) == 25, (direction, len(components))
    grouped = {}
    for row, (clip, count) in enumerate(COUNTS.items()):
        grouped[clip] = sorted([c for c in components if LIMITS[direction][row] <= c[0][1] < LIMITS[direction][row+1]], key=lambda c: c[0][0])
        assert len(grouped[clip]) == count, (direction, clip, len(grouped[clip]))
    idle = grouped['repos'][0][1]
    idle_anchor = sheets.compute_anchor(idle, 'dark', False, True)
    baseline = 139 / (idle_anchor[1] - sheets.top_of(idle))
    fitted = {}
    boxes = {}
    for clip, entries in grouped.items():
        fitted[clip] = []
        boxes[clip] = [b for b, p in entries]
        for box, part in entries:
            upright = clip in ('repos', 'marche', 'parle')
            anchor = sheets.compute_anchor(part, 'dark', clip == 'mort', upright)
            scale = 139 / (anchor[1] - sheets.top_of(part)) if upright else baseline
            native = fit_pixel(part, scale)
            ax, ay = sheets.compute_anchor(native, 'dark', clip == 'mort', upright)
            if upright:
                # Exact top-to-foot distance is the contract, not the sword's bounding box.
                ax, ay = round(anchor[0] * scale), 139
            fitted[clip].append((native, [ax, ay]))
    width = max(sum(p.width + 4 for p,a in entries) - 4 for entries in fitted.values())
    height = sum(max(p.height for p,a in entries) + 4 for entries in fitted.values()) - 4
    atlas = Image.new('RGBA', (width,height))
    y = 0
    for clip, entries in fitted.items():
        rowheight = max(p.height for p,a in entries)
        frames = []
        x = 0
        for image, anchor in entries:
            py = y + rowheight - image.height
            atlas.paste(image, (x, py))
            frames.append([x, py, image.width, image.height, *anchor])
            x += image.width + 4
        old['animations'][clip]['images'] = frames
        y += rowheight + 4
    # A common palette for the atlas avoids per-frame palette inflation.
    atlas = atlas.quantize(colors=64, method=Image.Quantize.FASTOCTREE).convert('RGBA')
    atlas.putalpha(atlas.getchannel('A').point(lambda v: 255 if v >= 128 else 0))
    old.update(planche=list(atlas.size), direction=direction, anchors_validated=False,
        anchor_method='Foot coordinates fitted from generated art; artistic cycle validation pending',
        status='section12_anime_identity_corrected_animation_review', palette_colors=64,
        combat_timing_validated=False)
    atlas.save(TARGET / (name + '.png'), optimize=True)
    sheets.write_json(str(TARGET / (name + '.json')), old)
    report['views'][direction] = {'source_boxes': boxes, 'atlas_size': list(atlas.size),
        'upright_heights': {clip:[sheets.standing_height(sheets.crop(atlas,f),f) for f in old['animations'][clip]['images']] for clip in ('repos','marche','parle')},
        'frames': 25, 'alpha_values': sorted(set(atlas.getchannel('A').getdata())),
        'png_sha256': hashlib.sha256((TARGET / (name + '.png')).read_bytes()).hexdigest()}

portrait = fit_pixel(Image.open(BASE / 'generated/portrait.png').convert('RGBA'), 256/1254)
assert portrait.size == (256,256)
portrait.save(TARGET / 'ithea_portrait.png', optimize=True)
(BASE / 'fit_validation.json').write_text(json.dumps(report, indent=2)+'\n')
preview = Image.new('RGB', (1740,540), '#292737')
draw = ImageDraw.Draw(preview)
draw.text((20,15), 'Ithea - official anime appearance / 139 px standing', fill='#f3e1cb')
for i,(direction,suffix) in enumerate([('front','_front'),('right',''),('back','_back')]):
    data = sheets.read_json(str(TARGET / ('ithea'+suffix+'.json')))
    atlas = Image.open(TARGET / ('ithea'+suffix+'.png')).convert('RGBA')
    frame = data['animations']['repos']['images'][0]
    sprite = sheets.crop(atlas,frame).resize((frame[2]*3,frame[3]*3),Image.Resampling.NEAREST)
    x = 20 + i*450
    preview.paste(sprite,(x,75),sprite)
    draw.text((x,45),direction+' / 139 px',fill='#f3e1cb')
portrait2=portrait.resize((300,300),Image.Resampling.NEAREST)
preview.paste(portrait2,(1430,100),portrait2)
preview.save(BASE/'ithea-anime-preview.png')
print('Ithea: 3 views x 25 frames; all upright poses 139 px; binary alpha; portrait 256 px.')
