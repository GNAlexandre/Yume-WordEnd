"""Run inside Blender: blender -b -t 2 --python tools/sukasuka3d/build_models.py -- [options]."""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ids', help='Comma-separated character IDs; omission builds all 45.')
    parser.add_argument('--kind', choices=('combat', 'npc'), help='Build only combat heroes or NPCs.')
    parser.add_argument('--skip-render', action='store_true', help='Skip renders; retain existing portraits.')
    parser.add_argument('--output', type=Path, default=ROOT / 'assets/models/characters')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    import core
    specs = [entry for filename in ('heroes', 'humanoids', 'species')
             for entry in json.loads((ROOT / 'tools/sukasuka3d' / f'{filename}.json').read_text())]
    if args.kind:
        specs = [s for s in specs if s.get('kind') == args.kind]
    if args.ids:
        requested = set(args.ids.split(','))
        known = {s['id'] for s in specs}
        if requested - known:
            raise ValueError(f'Unknown IDs: {sorted(requested - known)}')
        specs = [s for s in specs if s['id'] in requested]
    for index, spec in enumerate(specs, 1):
        print(f"MODELS3D {index}/{len(specs)} {spec['id']}", flush=True)
        core.generate(spec, args.output / spec['id'], render=not args.skip_render)
    print(f'MODELS3D COMPLETE: {len(specs)} models', flush=True)


if __name__ == '__main__':
    main()
