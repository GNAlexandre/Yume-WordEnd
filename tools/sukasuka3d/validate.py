#!/usr/bin/env python3
"""Validate real GLB outputs and their animation contracts without changing assets."""
import argparse
import json
import math
import struct
from pathlib import Path


def read_glb(path):
    raw = path.read_bytes()
    magic, version, size = struct.unpack_from('<III', raw)
    assert magic == 0x46546C67 and version == 2 and size == len(raw), 'invalid GLB header'
    offset = 12
    document = None
    binary = b''
    while offset < size:
        length, kind = struct.unpack_from('<II', raw, offset)
        payload = raw[offset + 8:offset + 8 + length]
        if kind == 0x4E4F534A:
            document = json.loads(payload)
        elif kind == 0x004E4942:
            binary = payload
        offset += 8 + length
    assert document is not None and binary, 'GLB needs embedded geometry'
    return document, binary


def values(document, binary, accessor_id):
    accessor = document['accessors'][accessor_id]
    view = document['bufferViews'][accessor['bufferView']]
    component = {5120: 'b', 5121: 'B', 5122: 'h', 5123: 'H', 5125: 'I', 5126: 'f'}[accessor['componentType']]
    components = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[accessor['type']]
    fmt = '<' + component * components
    stride = view.get('byteStride', struct.calcsize(fmt))
    offset = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
    return [struct.unpack_from(fmt, binary, offset + i * stride) for i in range(accessor['count'])]


def validate(directory):
    name = directory.name
    metadata = json.loads((directory / f'{name}.anim.json').read_text())
    document, binary = read_glb(directory / f'{name}.glb')
    assert not document.get('cameras'), 'cameras must not be exported'
    assert 'KHR_draco_mesh_compression' not in document.get('extensionsUsed', []), 'Draco unsupported'
    assert 'KHR_lights_punctual' not in document.get('extensionsUsed', []), 'lights must not be exported'
    assert len(document.get('materials', [])) <= 2, 'material budget exceeded'
    assert document.get('skins'), 'no skeleton/skin in 3D character'
    for image in document.get('images', []):
        assert 'uri' not in image and image.get('mimeType') == 'image/png', 'textures must be embedded PNG'
        view = document['bufferViews'][image['bufferView']]
        offset = view.get('byteOffset', 0)
        assert binary[offset:offset + 8] == b'\x89PNG\r\n\x1a\n', 'invalid PNG texture'
        width, height = struct.unpack_from('>II', binary, offset + 16)
        assert width <= 1024 and height <= 1024 and width & (width - 1) == 0 and height & (height - 1) == 0, 'texture dimensions exceed contract'
    for node_id in document['scenes'][document.get('scene', 0)]['nodes']:
        node = document['nodes'][node_id]
        assert node.get('translation', [0, 0, 0]) == [0, 0, 0], 'root must be at origin'
        assert node.get('scale', [1, 1, 1]) == [1, 1, 1], 'root scale must be applied'
        assert node.get('rotation', [0, 0, 0, 1]) == [0, 0, 0, 1], 'root rotation must be applied'
    bone_count = max(len(s['joints']) for s in document['skins'])
    assert bone_count <= 64, 'bone budget exceeded'
    triangles = 0
    positions = []
    for mesh in document['meshes']:
        for primitive in mesh['primitives']:
            assert primitive.get('mode', 4) == 4, 'expected triangulated mesh'
            attrs = primitive['attributes']
            assert not any(k.startswith('TEXCOORD_') and k != 'TEXCOORD_0' for k in attrs), 'multiple UV sets'
            assert 'JOINTS_1' not in attrs and 'WEIGHTS_1' not in attrs, 'more than four weights'
            count = document['accessors'][primitive.get('indices', attrs['POSITION'])]['count']
            triangles += count // 3
            positions.extend(values(document, binary, attrs['POSITION']))
            if 'WEIGHTS_0' in attrs:
                weights = values(document, binary, attrs['WEIGHTS_0'])
                if document['accessors'][attrs['WEIGHTS_0']]['componentType'] == 5126:
                    assert all(abs(sum(w) - 1.0) < 0.002 for w in weights), 'unnormalized bone weights'
    kind = metadata.get('usage', 'npc')
    triangle_limit = 15000 if name == 'chtholly' else 12000 if kind == 'combat' else 8000
    assert triangles <= triangle_limit, f'{triangles} triangles exceeds {triangle_limit}'
    byte_limit = 3_000_000 if kind == 'combat' else 1_500_000
    assert (directory / f'{name}.glb').stat().st_size <= byte_limit, 'file budget exceeded'
    clips = {a['name']: a for a in document.get('animations', [])}
    expected = metadata['animations']
    assert set(expected).issubset(clips), f'missing clips {set(expected) - set(clips)}'
    movement = {}
    for clip_name, description in expected.items():
        clip = clips[clip_name]
        end_times = [max(t[0] for t in values(document, binary, s['input'])) for s in clip['samplers']]
        duration = description['images'] / description['ips']
        assert abs(max(end_times) - duration) <= 0.001, f'{clip_name}: duration mismatch'
        varied = any(len(set(values(document, binary, s['output']))) > 1 for s in clip['samplers'])
        assert varied, f'{clip_name}: static clip'
        for channel in clip['channels']:
            target = channel['target']
            if document['nodes'][target['node']].get('name') in ('hips', 'root') and target['path'] == 'translation':
                translation = values(document, binary, clip['samplers'][channel['sampler']]['output'])
                assert all(max(v[axis] for v in translation) - min(v[axis] for v in translation) < 0.0001 for axis in (0, 2)), f'{clip_name}: horizontal root motion'
        movement[clip_name] = {'duration': round(max(end_times), 6), 'animated': varied}
    if kind == 'combat':
        assert set(expected) == {'repos', 'marche', 'course', 'attaque', 'charge', 'degats', 'mort'}
        assert expected['attaque']['coup'] == [1, 2, 3]
        assert expected['charge']['onde'] == 3
    from PIL import Image
    with Image.open(directory / f'{name}_portrait.png') as portrait:
        assert portrait.size == (256, 256), 'portrait must be 256 square'
        assert portrait.mode == 'RGBA', 'portrait needs alpha'
        alpha = portrait.getchannel('A')
        assert alpha.getextrema()[0] == 0 and alpha.getextrema()[1] > 0, 'portrait transparency/content missing'
    return dict(id=name, triangles=triangles, bones=bone_count, materials=len(document.get('materials', [])),
                bytes=(directory / f'{name}.glb').stat().st_size, animations=movement)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path('assets/models/characters'))
    parser.add_argument('--report', type=Path, default=Path('build/sukasuka3d-validation.json'))
    args = parser.parse_args()
    report = {'passed': [], 'failed': []}
    inventory_path = Path(__file__).resolve().parents[2] / 'docs/sprites/reference_inventory.json'
    required_ids = {entry['id'] for entry in json.loads(inventory_path.read_text())['entries']}
    present_ids = {path.parent.name for path in args.root.glob('*/*.glb')}
    for missing in sorted(required_ids - present_ids):
        report['failed'].append({'id': missing, 'error': 'required 3D model missing'})
    for path in sorted(args.root.glob('*/*.glb')):
        try:
            report['passed'].append(validate(path.parent))
        except (AssertionError, ValueError, KeyError, OSError) as error:
            report['failed'].append({'id': path.parent.name, 'error': str(error)})
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(f"3D contracts: {len(report['passed'])} passed, {len(report['failed'])} failed")
    for failure in report['failed']:
        print(failure)
    return 1 if report['failed'] or not report['passed'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
