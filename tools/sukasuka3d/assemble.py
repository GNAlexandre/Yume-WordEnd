#!/usr/bin/env python3
"""Build Godot mesh resources and a catalog from completed 3D assets."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def godot_string(value):
    return json.dumps(value, ensure_ascii=False)


def main():
    inventory = json.loads((ROOT / 'docs/sprites/reference_inventory.json').read_text())['entries']
    spec_paths = [ROOT / 'tools/sukasuka3d' / f'{name}.json' for name in ('heroes', 'humanoids', 'species')]
    specs = {s['id']: s for path in spec_paths for s in json.loads(path.read_text())}
    catalog = []
    for entry in inventory:
        ident = entry['id']
        directory = ROOT / 'assets/models/characters' / ident
        required = [directory / f'{ident}.{suffix}' for suffix in ('glb', 'anim.json')]
        required.append(directory / f'{ident}_portrait.png')
        if not all(p.is_file() for p in required):
            raise FileNotFoundError(f'3D output incomplete: {ident}')
        prefix = f'res://assets/models/characters/{ident}'
        scene = f'''[gd_scene format=3]\n\n[ext_resource type="PackedScene" path="{prefix}/{ident}.glb" id="1_mesh"]\n[ext_resource type="Script" path="res://assets/models/characters/model_metadata.gd" id="2_metadata"]\n[ext_resource type="JSON" path="{prefix}/{ident}.anim.json" id="3_clips"]\n\n[node name="Character3D" type="Node3D"]\nscript = ExtResource("2_metadata")\nanimation_metadata = ExtResource("3_clips")\n\n[node name="Model" parent="." instance=ExtResource("1_mesh")]\n'''
        (directory / f'{ident}.tscn').write_text(scene)
        resource = f'''[gd_resource type="Resource" script_class="SkinData" format=3]\n\n[ext_resource type="Script" path="res://src/visuals/skin_data.gd" id="1_skin"]\n[ext_resource type="PackedScene" path="{prefix}/{ident}.tscn" id="2_mesh"]\n[ext_resource type="Texture2D" path="{prefix}/{ident}_portrait.png" id="3_portrait"]\n\n[resource]\nscript = ExtResource("1_skin")\nid = &"sukasuka_{ident}"\ndisplay_name = {godot_string(entry['name'] + ' · 3D')}\nmesh_scene = ExtResource("2_mesh")\nportrait = ExtResource("3_portrait")\nheight_m = {float(specs[ident]['height'])}\n'''
        (directory / f'{ident}.tres').write_text(resource)
        if entry['kind'] == 'combat':
            (ROOT / 'data/skins' / f'sukasuka_{ident}.tres').write_text(resource)
        clips = json.loads((directory / f'{ident}.anim.json').read_text())['animations']
        catalog.append(dict(id=ident, name=entry['name'], kind=entry['kind'], reference_pages=entry['pages'],
                            model=f'assets/models/characters/{ident}/{ident}.glb',
                            scene=f'assets/models/characters/{ident}/{ident}.tscn',
                            portrait=f'assets/models/characters/{ident}/{ident}_portrait.png',
                            animations=list(clips), height_m=specs[ident]['height'],
                            fidelity='Adaptation chibi low-poly construite dans Blender à partir des scans ; revue visuelle requise.'))
    (ROOT / 'docs/sprites/catalog3d.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
    print(f'{len(catalog)} 3D resources; {sum(e["kind"] == "combat" for e in catalog)} playable mesh skins')


if __name__ == '__main__':
    main()
