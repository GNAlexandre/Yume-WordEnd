#!/usr/bin/env python3
"""Package completed 3D assets, Godot resources and reproducible tooling."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'build/SukaSuka_personnages_3D.zip')
    args = parser.parse_args()
    files = []
    for folder in ('assets/models/characters', 'tools/sukasuka3d', 'docs/sprites'):
        files.extend(p for p in (ROOT / folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
    files.extend((ROOT / 'data/skins').glob('sukasuka_*.tres'))
    files.extend(ROOT / name for name in ('assets/CREDITS.md', 'assets/characters/CREDITS.md', 'docs/ASSETS_3D.md'))
    files.extend(ROOT / name for name in ('tests/unit/test_skin_registry.gd', 'tests/integration/test_sukasuka_models.gd', 'tests/integration/test_sukasuka_models.gd.uid'))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        manifest = []
        for path in sorted(set(files)):
            name = str(path.relative_to(ROOT))
            package.write(path, name)
            manifest.append({'path': name, 'bytes': path.stat().st_size, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
        package.writestr('MANIFEST.json', json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    with zipfile.ZipFile(args.output) as package:
        assert package.testzip() is None, 'archive integrity failed'
    print(f'{args.output}: {len(files)} files, {args.output.stat().st_size:,} bytes; CRC verified')


if __name__ == '__main__':
    main()
