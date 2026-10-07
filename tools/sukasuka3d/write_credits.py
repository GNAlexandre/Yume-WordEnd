#!/usr/bin/env python3
"""Record the provenance of every delivered character asset."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main():
    entries = json.loads((ROOT / 'docs/sprites/reference_inventory.json').read_text())['entries']
    lines = ['# Provenance des assets 3D', '',
             'Pack du 7 octobre 2026. Adaptations procédurales Blender 4.3.2 assistées par Codex, à partir des 162 scans du recueil SukaSuka fournis par l’utilisateur. Les scans restent hors du dépôt. Les designs et dessins sources appartiennent à leurs ayants droit ; les pièces fournies ne contiennent pas de licence accordée au projet. La licence du code ne transfère pas les droits sur ces designs.', '',
             'Les fichiers `.import` et `.uid` sont des métadonnées techniques créées par Godot 4.7.2. Les palettes PNG extraites par Godot sont également incorporées aux GLB. Les fichiers JSON, TSCN et TRES sont générés par les scripts du projet. Les palettes absentes des planches au trait sont des adaptations signalées dans les spécifications.', '',
             '| Fichier | Auteur / outil | Référence | Licence / statut |',
             '| --- | --- | --- | --- |']
    lines.append('| `assets/models/characters/model_metadata.gd` | GDScript du projet / Codex | Cadences, boucles et événements des GLB | Code d’intégration : régime du code du projet |')
    for entry in entries:
        ident = entry['id']
        reference = f'{entry["name"]}, pages {", ".join(map(str,entry["pages"]))}'
        for path in sorted((ROOT / 'assets/models/characters' / ident).iterdir()):
            if path.suffix in ('.import', '.uid'):
                continue
            tool = 'Blender 4.3.2 / Codex' if path.suffix in ('.glb', '.png') else 'Scripts Python du projet / Codex'
            license_status = 'Design SukaSuka : droits non transférés' if path.suffix in ('.glb', '.png') else 'Métadonnées du projet ; design référencé, droits non transférés'
            lines.append(f'| `{path.relative_to(ROOT)}` | {tool} | {reference} | {license_status} |')
        if entry['kind'] == 'combat':
            lines.append(f'| `data/skins/sukasuka_{ident}.tres` | Scripts Python du projet / Codex | {reference} | Métadonnées du projet ; design référencé, droits non transférés |')
    credits = ROOT / 'assets/CREDITS.md'
    marker = '<!-- sukasuka 3D provenance -->'
    previous = credits.read_text().split(marker, 1)[0].rstrip()
    lines[0] = '## Personnages SukaSuka en 3D'
    credits.write_text(previous + '\n\n' + marker + '\n\n' + '\n'.join(lines) + '\n')
    print(f'Provenance: {len(lines) - 9} asset rows')


if __name__ == '__main__':
    main()
