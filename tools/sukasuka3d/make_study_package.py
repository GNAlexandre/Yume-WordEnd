#!/usr/bin/env python3
"""Package intact 2D originals and the Chtholly/Willem concept studies."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'build/Chtholly_Willem_et_planches_2D.zip')
    args = parser.parse_args()
    files = [p for p in (ROOT / 'assets/source').rglob('*') if p.is_file()]
    files.extend(ROOT / name for name in ('docs/ASSETS_3D.md', 'docs/lore/MONDE.md', 'docs/sprites/ATELIER_CHTHOLLY.html', 'docs/sprites/REFERENCES.md', 'assets/CREDITS.md', 'tools/sukasuka3d/make_study_gallery.py', 'tools/sukasuka3d/make_study_package.py'))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    manifest = []
    with zipfile.ZipFile(args.output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        for path in sorted(set(files)):
            name = str(path.relative_to(ROOT))
            data = path.read_bytes()
            if name == 'docs/sprites/ATELIER_CHTHOLLY.html':
                data = data.replace(b'<a href="ATELIER_3D.html">Ancien lot 3D</a>', b'')
            package.writestr(name, data)
            manifest.append({'path': name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
        package.writestr('MANIFEST.json', json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
        package.writestr('LISEZMOI.txt', 'Ouvrir docs/sprites/ATELIER_CHTHOLLY.html pour voir Chtholly avec et sans plastron, Willem, les premiers concepts conservés et les 11 PNG 2D originaux. Ce pack contient des concepts 2D ; aucun nouveau modèle 3D, rig ou animation n’est livré.\n')
    with zipfile.ZipFile(args.output) as package:
        assert package.testzip() is None
        for entry in manifest:
            assert hashlib.sha256(package.read(entry['path'])).hexdigest() == entry['sha256']
    print(f'{args.output}: {len(files)} files, {args.output.stat().st_size:,} bytes; CRC/SHA-256 verified')


if __name__ == '__main__':
    main()
