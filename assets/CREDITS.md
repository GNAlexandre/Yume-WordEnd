# Crédits des assets tiers

Uniquement des assets CC0 (Kenney, Poly Haven, Quaternius…) ou sous licence explicitement
compatible, une ligne par asset ou par pack, ajoutée en bas (fusion par union entre lots).
Les dessins des membres et les planches de personnages sont listés dans
`assets/characters/CREDITS.md`.

| Fichier(s) | Auteur / source | URL | Licence | Ajouté par |
| --- | --- | --- | --- | --- |
| `assets/hd2d/**/*.png` (tuiles de sol, falaises, matières, façades, décors en panneaux, ciel, horizon, effets : images de remplacement HD-2D) | généré par `tools/hd2d_assets.py gen` (recettes `tools/hd2d_ground.py`, `hd2d_props.py`, `hd2d_sky.py`) | — | licence du code du projet (MIT proposée, PLAN.md section 13) | HD-2D |

Aucun fichier audio pour l'instant : l'enregistrement de *Scarborough Fair* utilisé par l'easter
egg n'a pas de licence établie (PLAN.md section 13) et n'est pas copié.

| Fichier(s) | Auteur / source | URL | Licence | Ajouté par |
| --- | --- | --- | --- | --- |
| `assets/items/*.png` | généré par `tools/gen_item_icons.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | L7 |
| `assets/ui/*.png` (cœurs, marqueur de cible, livre de sauvegarde, page de quête, étoile) | généré par `tools/gen_ui_icons.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | L10 |
| `assets/ui/icon.png`, `assets/ui/boot_splash.png` (icône du jeu, écran de démarrage) | généré par `tools/gen_branding.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | M2 |
| `assets/items/*.png` de l'acte 1 (13 nouvelles icônes, `page_fragment` redessinée ; `shell` et `bookmark` retirées) | généré par `tools/gen_item_icons.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | Acte 1 |
| `assets/hd2d/**/*.png` livrées (sols, falaises, matières et façades, décors en panneaux, ciel, mer de nuages, horizon ; toutes sauf `ring_stone` et les effets) et l'atlas du sol refait à partir d'elles | générées avec ChatGPT/Codex (outil image_gen, modèle non précisé) d'après `docs/ASSETS_HD2D.md`, livrées le 8 octobre 2026 (PR n° 2 et 3) ; `distant_island_b` recadrée (`hd2d_assets.py fit`), `distant_island_b` et `_c` sans leurs îlots fantômes | — | images générées pour le projet ; décors inspirés de *SukaSuka*, droits des ayants droit réservés | H1 |
| `assets/items/flower_blue.png`, `page_fragment.png`, `unknown.png`, `wild_berries.png`, `clock_gear.png`, `laundry_sheet.png` | générées avec ChatGPT/Codex, livrées le 8 octobre 2026 (PR n° 2 et 3 ; les trois dernières sous les noms `berries`, `gear`, `cloth`) | — | images générées pour le projet | H1 |
| `assets/hd2d/sky/distant_island_b.png`, `distant_island_c.png`, `assets/hd2d/buildings/materials/wall_plaster.png` (corrections) | régénérées avec ChatGPT/Codex, livrées le 8 octobre 2026 (PR n° 4, `main` deca738) : îles B et C d'une seule silhouette violacée (C sans bâtiment), enduit crème sans quadrillage de colombages ; natifs dans l'historique de `main` | — | images générées pour le projet ; décors inspirés de *SukaSuka*, droits des ayants droit réservés | H1 |
| `assets/hd2d/decals/*.png`, `assets/hd2d/anim/*.png`, `assets/hd2d/buildings/*_side.png` et les autres images du cahier n° 2 (`docs/ASSETS_HD2D_MONDE.md`, lots A à G : 300 remplaçants, dont les deux dirigeables refaits) | générés par `tools/hd2d_assets.py gen` (recettes `tools/hd2d_nature.py`, `hd2d_decals.py`, `hd2d_town.py`, `hd2d_ships.py`, `hd2d_anim.py`, `hd2d_sky.py`, `hd2d_ground.py`) ; les tuiles `_b`, la prairie fleurie, les matières `_b`, les flancs des bâtiments existants et les bandes du linge, du fanion, de la manche à air, des roseaux, de l'herbe haute et de la cloche reprennent des morceaux des images livrées (ChatGPT/Codex, ligne H1 ci-dessus) | — | licence du code du projet (MIT proposée, PLAN.md section 13) pour les recettes ; morceaux d'images livrées : comme ci-dessus | H10 |
| `assets/hd2d/props/palisade_gate.png`, `ring_stone.png` (section 12) | régénérées avec ChatGPT/Codex (`image_gen`), le 8 octobre 2026 ; portail à battants rabattus (292 px libres = 3,04 m), pierre plate livrée en 58 × 20 px ; sources, prompts et mesures dans `assets/source/section12/props/` | — | images générées pour le projet ; mêmes réserves que les décors ci-dessus | H1 |

| `assets/hd2d/sky/cloud_a.png`, `assets/hd2d/sky/cloud_b.png`, `assets/hd2d/sky/cloud_c.png`, `assets/hd2d/sky/distant_island_d.png`, `assets/hd2d/sky/island_53.png`, `assets/hd2d/sky/cloud_d.png`, `assets/hd2d/sky/cloud_e.png`, `assets/hd2d/sky/distant_island_e.png`, `assets/hd2d/sky/distant_island_f.png`, `assets/hd2d/sky/horizon_islands.png`, `assets/hd2d/sky/mist_band.png`, `assets/hd2d/sky/light_shaft_a.png`, `assets/hd2d/sky/light_shaft_b.png`, `assets/hd2d/sky/sky_dusk.png`, `assets/hd2d/sky/sky_night.png` | généré avec ChatGPT le 8 octobre 2026, lot G (outil image_gen) ; mise au format nearest-neighbor et adaptation technique des masques/raccords, sans quantification RGB | — | images générées pour le projet ; univers inspiré de SukaSuka, droits des ayants droit réservés | Monde G |
