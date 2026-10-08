#!/usr/bin/env python3
"""Build the Chtholly/Willem concept review and preservation gallery."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def board(section, title, relative_path, caption):
    url = '../../assets/source/' + relative_path
    return f'<section id="{section}"><h2>{title}</h2><a href="{url}" target="_blank" rel="noopener"><img class="board" src="{url}" alt="{title}" /></a><p class="caption"><span>{caption}</span><a class="download" href="{url}" download>Télécharger la planche</a></p></section>'


def main():
    rows = json.loads((ROOT / 'assets/source/legacy_2d/manifest.json').read_text())
    cards = []
    for entry in rows:
        url = '../../assets/source/legacy_2d/' + entry['file']
        name, description, limitations = (html.escape(entry[k]) for k in ('name', 'description', 'limitations'))
        cards.append(f'''<article class="card"><h3>{name}</h3><a href="{url}" target="_blank" rel="noopener"><img loading="lazy" src="{url}" alt="{name}" /></a><p>{description}</p><p class="muted">{limitations}</p><a class="download" href="{url}" download>Télécharger l’original · {entry['dimensions'][0]} × {entry['dimensions'][1]}</a></article>''')
    template = '''<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Chtholly et Willem · Concepts militaires</title>
<style>
:root{color-scheme:light;font:16px/1.55 system-ui;color:#20314a;background:#f0f3f7}body{margin:0}main{max-width:1400px;margin:auto;padding:clamp(16px,3vw,40px)}h1{font-size:clamp(24px,4vw,38px);line-height:1.2}h2{font-size:26px}a{color:#345f98}nav{display:flex;gap:12px;flex-wrap:wrap;margin:24px 0}nav a,.download{display:inline-block;border:1px solid #afbdd0;border-radius:7px;padding:8px 12px;background:white;text-decoration:none}.lead{max-width:950px}.note{padding:14px 20px;border-left:4px solid #668ebd;background:#e5edf7}.board{display:block;width:100%;height:auto;background:#d2d0cc;border-radius:12px}.caption{display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap}.muted{color:#55647b;font-size:14px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,340px),1fr));gap:22px}.card{background:white;border:1px solid #d7dfeb;border-radius:12px;padding:18px}.card h3{margin-top:0}.card img{display:block;width:100%;height:320px;object-fit:contain;background-color:#f5f5f5;background-image:linear-gradient(45deg,#e4e7eb 25%,transparent 25%),linear-gradient(-45deg,#e4e7eb 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#e4e7eb 75%),linear-gradient(-45deg,transparent 75%,#e4e7eb 75%);background-size:24px 24px;background-position:0 0,0 12px,12px -12px,-12px 0}section{scroll-margin-top:20px;margin:40px 0}.swatches{display:flex;gap:12px;flex-wrap:wrap}.swatch{display:flex;align-items:center;gap:8px;border:1px solid #c7d2df;background:white;padding:8px 12px;border-radius:8px}.swatch i{width:28px;height:28px;border-radius:4px;display:block}.status{font-weight:600;color:#345f98}
</style></head><body><main>
<p class="status">Chtholly et Willem · Concepts à examiner</p><h1>Chtholly et Willem · Uniformes militaires</h1>
<p class="lead">Proportions naturelles stylisées, visages anime sobres et matières détaillées. Ces images sont des <strong>planches concept 2D pour préparer de futurs modèles</strong>. Les nouveaux GLB, rigs et animations restent à réaliser.</p>
<nav><a href="#turnaround">Chtholly sans plastron</a><a href="#armure">Chtholly avec plastron</a><a href="#willem">Willem</a><a href="#historique">Premiers concepts</a><a href="#archives">11 planches 2D conservées</a><a href="ATELIER_3D.html">Ancien lot 3D</a></nav>
<p class="note">Révision demandée : même Chtholly, veste militaire fermée à galons dorés et deux variantes d’équipement d’après le scan p017 (folio 016). La base de Seniorious est élargie. Les bas sombres et bottines brunes du concept précédent sont conservés. Willem et Percival suivent les scans p005–p007. Les autres personnages attendent leur validation.</p>
__CURRENT_BOARDS__
<div class="swatches">__SWATCHES__</div><p class="muted">Sorties natives : 1536 × 1024. La cible de 2048 px de haut reste à atteindre. Cohérence des détails entre les vues et fidélité à revoir avant modélisation.</p>
<section id="historique"><h2>Premiers concepts conservés</h2><p>Ces deux planches restent disponibles à l’identique. Leur tenue, broche et ancienne largeur de lame sont remplacées par les variantes militaires ci-dessus ; les études du visage et des cheveux servent toujours de référence.</p></section>
__HISTORY_BOARDS__
<section id="archives"><h2>Planches 2D conservées</h2><p>Les 11 PNG d’origine sont conservés sans modification. Le fond quadrillé permet de voir leur vraie transparence. Les noms identifiés et limites sont indiqués pour faciliter leur réutilisation ; ces essais ne sont pas des atlas de jeu validés.</p><div class="grid">__CARDS__</div><p><a href="../../assets/source/legacy_2d/manifest.json">Manifeste des originaux et empreintes SHA-256</a></p></section>
<footer><p class="muted">Concepts générés avec image_gen à partir des références fournies · 7 octobre 2026. Designs SukaSuka, droits non transférés. Les scans officiels restent hors du dépôt.</p></footer></main></body></html>
'''
    palette = json.loads((ROOT / 'assets/source/chtholly/palette.json').read_text())
    swatches = ''.join(f'<div class="swatch"><i style="background:{color}"></i><code>{color}</code></div>' for color in palette.values())
    destination = ROOT / 'docs/sprites/ATELIER_CHTHOLLY.html'
    current = '\n'.join([
        board('turnaround', 'Chtholly · Sans plastron', 'chtholly/concept/chtholly_turnaround.png', 'Face, profil, dos et Seniorious · Uniforme militaire'),
        board('armure', 'Chtholly · Avec plastron', 'chtholly/concept/chtholly_with_plastron.png', 'Même tenue équipée du plastron, des protections et du harnais'),
        board('willem', 'Willem Kmetsch · Uniforme militaire', 'willem/concept/willem_turnaround.png', 'Face, profil, dos, portraits, détails du costume et Percival'),
    ])
    history = '\n'.join([
        board('initial', 'Chtholly · Première proposition', 'chtholly/concept/history/chtholly_turnaround_initial.png', 'Historique · Tenue et lame remplacées'),
        board('details', 'Chtholly · Premières études de détail', 'chtholly/concept/chtholly_details.png', 'Historique · Visage et coiffure conservés ; accessoires remplacés'),
    ])
    destination.write_text(template.replace('__CARDS__', '\n'.join(cards)).replace('__SWATCHES__', swatches).replace('__CURRENT_BOARDS__', current).replace('__HISTORY_BOARDS__', history))
    print(f'{destination}: 3 current concepts, 2 initial concepts, {len(cards)} preserved 2D sheets')


if __name__ == '__main__':
    main()
