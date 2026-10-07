#!/usr/bin/env python3
"""Embed the catalog, real GLBs and a compiled Three.js viewer into an offline gallery."""
import argparse
import base64
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bundle', type=Path, required=True)
    args = parser.parse_args()
    entries = json.loads((ROOT / 'docs/sprites/catalog3d.json').read_text())
    for entry in entries:
        entry['glb'] = base64.b64encode((ROOT / entry['model']).read_bytes()).decode('ascii')
    data = json.dumps(entries, ensure_ascii=False).replace('<', '\\u003c')
    code = args.bundle.read_text().replace('</script', '<\\/script')
    license_text = (ROOT / 'docs/sprites/THREE_LICENSE.txt').read_text()
    html = '''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Personnages SukaSuka · Atelier 3D</title>
<style>body{margin:0;font:16px system-ui;color:#17283e;background:#f3f6f9}main{max-width:1200px;margin:auto;padding:20px}h1{font-size:26px}nav{display:flex;gap:12px;flex-wrap:wrap;align-items:center}select,button{font:inherit;padding:7px;border:1px solid #acbbca;border-radius:6px;background:white}canvas{display:block;width:100%;height:65vh;min-height:360px;margin-top:16px;border-radius:12px;touch-action:none}p{line-height:1.5}small{color:#43566f}</style>
<main><h1>Personnages SukaSuka · Atelier 3D</h1><p>45 adaptations chibi low-poly issues des références fournies. Chaque personnage possède un volume, un squelette et des animations. Les détails des dessins sont simplifiés ; ces modèles demandent une revue artistique.</p>
<nav><label>Personnage <select id="person"></select></label><label>Animation <select id="animation"></select></label><button id="pause">Pause</button><label><input id="bones" type="checkbox"> Squelette</label><label><input id="wire" type="checkbox"> Maillage</label></nav>
<canvas id="canvas" aria-label="Modèle 3D interactif"></canvas><p id="info">Chargement…</p><small>Glisser pour tourner · molette ou pincement pour zoomer · glisser avec le bouton droit pour déplacer la vue. Fonctionne hors ligne dans un navigateur avec WebGL 2. Les cartes attendent les volumes du récit.</small></main>
<!-- __LICENSE__ -->
<script id="models" type="application/json">__DATA__</script><script>__CODE__</script></html>'''
    destination = ROOT / 'docs/sprites/ATELIER_3D.html'
    html = html.replace('__DATA__', data).replace('__CODE__', code).replace('__LICENSE__', license_text)
    destination.write_text('\n'.join(line.rstrip() for line in html.split('\n')))
    print(f'{destination}: {len(entries)} models, {destination.stat().st_size:,} bytes')


if __name__ == '__main__':
    main()
