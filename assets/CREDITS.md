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

| `assets/hd2d/buildings/warehouse_main_side.png`, `assets/hd2d/buildings/warehouse_wing_side.png`, `assets/hd2d/buildings/cafe_side.png`, `assets/hd2d/buildings/shop_bakery_side.png`, `assets/hd2d/buildings/shop_bookshop_side.png`, `assets/hd2d/buildings/stone_house_side.png`, `assets/hd2d/buildings/projection_hall_side.png`, `assets/hd2d/buildings/limashenka_house_side.png`, `assets/hd2d/buildings/tool_shed_side.png`, `assets/hd2d/buildings/house_timber_a.png`, `assets/hd2d/buildings/house_timber_a_side.png`, `assets/hd2d/buildings/house_timber_b.png`, `assets/hd2d/buildings/house_timber_b_side.png`, `assets/hd2d/buildings/clockmaker.png`, `assets/hd2d/buildings/clockmaker_side.png`, `assets/hd2d/buildings/house_narrow.png`, `assets/hd2d/buildings/house_narrow_side.png`, `assets/hd2d/buildings/butcher.png`, `assets/hd2d/buildings/butcher_side.png`, `assets/hd2d/buildings/inn.png`, `assets/hd2d/buildings/inn_side.png`, `assets/hd2d/buildings/harbor_office.png`, `assets/hd2d/buildings/harbor_office_side.png`, `assets/hd2d/buildings/port_hangar.png`, `assets/hd2d/buildings/port_hangar_side.png`, `assets/hd2d/buildings/boiler_workshop.png`, `assets/hd2d/buildings/boiler_workshop_side.png`, `assets/hd2d/buildings/house_stone_b.png`, `assets/hd2d/buildings/house_stone_b_side.png`, `assets/hd2d/buildings/materials/roof_tiles_b.png`, `assets/hd2d/buildings/materials/roof_slate_b.png`, `assets/hd2d/buildings/materials/wall_plaster_b.png`, `assets/hd2d/buildings/materials/wall_stone_b.png`, `assets/hd2d/buildings/materials/wall_brick.png`, `assets/hd2d/buildings/materials/roof_shingles.png`, `assets/hd2d/buildings/materials/wall_tin.png`, `assets/hd2d/buildings/materials/roof_tin_b.png`, `assets/hd2d/buildings/materials/wall_planks_b.png`, `assets/hd2d/buildings/materials/wall_plaster_c.png`, `assets/hd2d/props/chimney_brick.png`, `assets/hd2d/props/chimney_stone.png`, `assets/hd2d/props/dormer_slate.png`, `assets/hd2d/props/dormer_tiles.png`, `assets/hd2d/props/ivy_wall_a.png`, `assets/hd2d/props/ivy_wall_b.png`, `assets/hd2d/props/warehouse_roof_deck.png`, `assets/hd2d/props/wall_lantern.png`, `assets/hd2d/props/window_box.png`, `assets/hd2d/props/hanging_sign_key.png`, `assets/hd2d/props/hanging_sign_propeller.png`, `assets/hd2d/props/drainpipe.png`, `assets/hd2d/props/outdoor_stairs.png`, `assets/hd2d/props/awning_green.png` | généré avec ChatGPT le 8 octobre 2026, lot D (outil image_gen) ; mise au format nearest-neighbor et adaptation technique des masques/raccords, sans quantification RGB | — | images générées pour le projet ; univers inspiré de SukaSuka, droits des ayants droit réservés | Monde D |
| `assets/hd2d/decals/*.png`, `assets/hd2d/anim/*.png`, `assets/hd2d/buildings/*_side.png` et les autres images du cahier n° 2 (`docs/ASSETS_HD2D_MONDE.md`, lots A à G : 300 remplaçants, dont les deux dirigeables refaits) | générés par `tools/hd2d_assets.py gen` (recettes `tools/hd2d_nature.py`, `hd2d_decals.py`, `hd2d_town.py`, `hd2d_ships.py`, `hd2d_anim.py`, `hd2d_sky.py`, `hd2d_ground.py`) ; les tuiles `_b`, la prairie fleurie, les matières `_b`, les flancs des bâtiments existants et les bandes du linge, du fanion, de la manche à air, des roseaux, de l'herbe haute et de la cloche reprennent des morceaux des images livrées (ChatGPT/Codex, ligne H1 ci-dessus) | — | licence du code du projet (MIT proposée, PLAN.md section 13) pour les recettes ; morceaux d'images livrées : comme ci-dessus | H10 |
| `assets/hd2d/props/palisade_gate.png`, `ring_stone.png` (section 12) | régénérées avec ChatGPT/Codex (`image_gen`), le 8 octobre 2026 ; portail à battants rabattus (292 px libres = 3,04 m), pierre plate livrée en 58 × 20 px ; sources, prompts et mesures dans `assets/source/section12/props/` | — | images générées pour le projet ; mêmes réserves que les décors ci-dessus | H1 |

| `assets/hd2d/sky/cloud_a.png`, `assets/hd2d/sky/cloud_b.png`, `assets/hd2d/sky/cloud_c.png`, `assets/hd2d/sky/distant_island_d.png`, `assets/hd2d/sky/island_53.png`, `assets/hd2d/sky/cloud_d.png`, `assets/hd2d/sky/cloud_e.png`, `assets/hd2d/sky/distant_island_e.png`, `assets/hd2d/sky/distant_island_f.png`, `assets/hd2d/sky/horizon_islands.png`, `assets/hd2d/sky/mist_band.png`, `assets/hd2d/sky/light_shaft_a.png`, `assets/hd2d/sky/light_shaft_b.png`, `assets/hd2d/sky/sky_dusk.png`, `assets/hd2d/sky/sky_night.png` | généré avec ChatGPT le 8 octobre 2026, lot G (outil image_gen) ; mise au format nearest-neighbor et adaptation technique des masques/raccords, sans quantification RGB | — | images générées pour le projet ; univers inspiré de SukaSuka, droits des ayants droit réservés | Monde G |

| `assets/hd2d/props/wheelbarrow.png`, `assets/hd2d/props/firewood_pile.png`, `assets/hd2d/props/stump_axe.png`, `assets/hd2d/props/rain_barrel.png`, `assets/hd2d/props/laundry_basket.png`, `assets/hd2d/props/toys_a.png`, `assets/hd2d/props/toys_b.png`, `assets/hd2d/props/bench_b.png`, `assets/hd2d/props/fence_low.png`, `assets/hd2d/props/bucket.png`, `assets/hd2d/props/watering_can.png`, `assets/hd2d/props/garden_tools.png`, `assets/hd2d/props/scarecrow.png`, `assets/hd2d/props/kids_table.png`, `assets/hd2d/props/flower_pots.png`, `assets/hd2d/props/crate_stack.png`, `assets/hd2d/props/bench_stone.png`, `assets/hd2d/props/sack_apples.png`, `assets/hd2d/props/cafe_table.png`, `assets/hd2d/props/barrel_group.png`, `assets/hd2d/props/sacks_pile.png`, `assets/hd2d/props/hand_cart.png`, `assets/hd2d/props/fountain.png`, `assets/hd2d/props/notice_board.png`, `assets/hd2d/props/market_stall_fruit.png`, `assets/hd2d/props/market_stall_cloth.png`, `assets/hd2d/props/bread_rack.png`, `assets/hd2d/props/book_cart.png`, `assets/hd2d/props/menu_slate.png`, `assets/hd2d/props/street_lamp_double.png`, `assets/hd2d/props/planter_long.png`, `assets/hd2d/props/bunting.png`, `assets/hd2d/props/crate_apples.png`, `assets/hd2d/props/broom_bucket.png`, `assets/hd2d/props/mooring_tower.png`, `assets/hd2d/props/cargo_net.png`, `assets/hd2d/props/crystal_crates.png`, `assets/hd2d/props/fuel_barrels.png`, `assets/hd2d/props/rope_coil.png`, `assets/hd2d/props/steam_pipes.png`, `assets/hd2d/props/workbench.png`, `assets/hd2d/props/luggage.png`, `assets/hd2d/props/ticket_booth.png`, `assets/hd2d/props/dock_lamp.png`, `assets/hd2d/props/pallet_sacks.png`, `assets/hd2d/props/chain_pile.png`, `assets/hd2d/props/tool_rack.png`, `assets/hd2d/props/propeller_spare.png`, `assets/hd2d/props/ruined_wall_b.png`, `assets/hd2d/props/ruined_wall_c.png`, `assets/hd2d/props/dead_shrub_a.png`, `assets/hd2d/props/wind_grass_a.png`, `assets/hd2d/props/dead_shrub_b.png`, `assets/hd2d/props/wind_grass_b.png`, `assets/hd2d/props/sandbags.png`, `assets/hd2d/props/broken_spears.png`, `assets/hd2d/props/ruined_arch.png`, `assets/hd2d/props/cart_wreck.png`, `assets/hd2d/props/broken_pillar.png`, `assets/hd2d/props/garde_crate.png`, `assets/hd2d/props/fallen_tree.png`, `assets/hd2d/props/stump_a.png`, `assets/hd2d/props/stump_b.png`, `assets/hd2d/props/log_hollow.png`, `assets/hd2d/props/training_dummy.png`, `assets/hd2d/props/target_board.png`, `assets/hd2d/props/hunting_stand.png`, `assets/hd2d/props/cairn.png`, `assets/hd2d/props/rope_fence.png`, `assets/hd2d/props/stone_steps.png`, `assets/hd2d/props/old_telescope.png`, `assets/hd2d/props/log_pile_forest.png` | généré avec ChatGPT le 8 octobre 2026, lot E (outil image_gen) ; mise au format nearest-neighbor et adaptation technique des masques/raccords, sans quantification RGB | — | images générées pour le projet ; univers inspiré de SukaSuka, droits des ayants droit réservés | Monde E |

| `assets/hd2d/props/airship_ferry.png`, `assets/hd2d/anim/airship_ferry_propeller.png`, `assets/hd2d/props/airship_barocupot.png`, `assets/hd2d/anim/airship_barocupot_propeller.png`, `assets/hd2d/sky/airship_far_a.png`, `assets/hd2d/sky/airship_far_b.png`, `assets/hd2d/sky/airship_far_c.png`, `assets/hd2d/sky/airship_far_d.png` | généré avec ChatGPT le 8 octobre 2026, lot C (outil image_gen) ; mise au format nearest-neighbor et adaptation technique des masques/raccords, sans quantification RGB | — | images générées pour le projet ; univers inspiré de SukaSuka, droits des ayants droit réservés | Monde C |

| `assets/hd2d/ground/grass_b.png`, `assets/hd2d/ground/forest_floor_b.png`, `assets/hd2d/ground/path_dirt_b.png`, `assets/hd2d/ground/leaf_litter.png`, `assets/hd2d/ground/moss.png`, `assets/hd2d/ground/grass_dry_b.png`, `assets/hd2d/ground/flagstone_b.png`, `assets/hd2d/ground/cobble_b.png`, `assets/hd2d/ground/meadow_flowers.png`, `assets/hd2d/ground/gravel.png`, `assets/hd2d/ground/garden_soil.png`, `assets/hd2d/ground/sand_b.png`, `assets/hd2d/ground/rock_b.png`, `assets/hd2d/ground/planks.png`, `assets/hd2d/ground/stream_bed.png`, `assets/hd2d/decals/grass_edge_a.png`, `assets/hd2d/decals/grass_edge_b.png`, `assets/hd2d/decals/pebbles_a.png`, `assets/hd2d/decals/garden_bed.png`, `assets/hd2d/decals/clover_patch.png`, `assets/hd2d/decals/flowers_patch_a.png`, `assets/hd2d/decals/flowers_patch_b.png`, `assets/hd2d/decals/puddle_a.png`, `assets/hd2d/decals/puddle_b.png`, `assets/hd2d/decals/mud_patch.png`, `assets/hd2d/decals/cracks_a.png`, `assets/hd2d/decals/cracks_b.png`, `assets/hd2d/decals/pebbles_b.png`, `assets/hd2d/decals/stepping_stones.png`, `assets/hd2d/decals/lily_pads.png`, `assets/hd2d/decals/sand_drift_a.png`, `assets/hd2d/decals/sand_drift_b.png`, `assets/hd2d/decals/ring_stone_flat_a.png`, `assets/hd2d/decals/ring_stone_flat_b.png`, `assets/hd2d/decals/ring_stone_flat_c.png`, `assets/hd2d/decals/chalk_drawings.png`, `assets/hd2d/decals/chalk_hopscotch.png`, `assets/hd2d/decals/oil_stain.png`, `assets/hd2d/decals/rust_streak.png`, `assets/hd2d/decals/footprints.png`, `assets/hd2d/decals/cart_ruts.png`, `assets/hd2d/decals/drain_grate.png`, `assets/hd2d/decals/hay_scatter.png`, `assets/hd2d/decals/boardwalk.png`, `assets/hd2d/decals/mist_patch.png` | généré avec ChatGPT le 8 octobre 2026, lot B (outil image_gen) ; mise au format nearest-neighbor et adaptation technique des masques/raccords, sans quantification RGB | — | images générées pour le projet ; univers inspiré de SukaSuka, droits des ayants droit réservés | Monde B |

### Lot G — corrections des raccords et détourages

Six PNG corrigés avec ChatGPT / image_gen : `assets/hd2d/sky/sky_dusk.png`, `assets/hd2d/sky/sky_night.png`, `assets/hd2d/sky/horizon_islands.png`, `assets/hd2d/sky/mist_band.png`, `assets/hd2d/sky/distant_island_d.png`, `assets/hd2d/sky/distant_island_f.png`. Sources conservées hors du dépôt ; assemblage et détourage sans réduction de palette.

### Cahier n° 3 — lot I, priorité 1

91 PNG générés avec ChatGPT / image_gen le 9 octobre 2026, cahier n° 3, lot I. Références : les planches officielles de SukaSuka fournies par l’utilisateur (21 ZIP, 162 pages ; intérieurs p99–111), les descriptions paraphrasées des romans du cahier, et les assets HD-2D déjà livrés. Sources et aperçus conservés hors du dépôt. Mise au format au plus proche voisin, transparence découpée, raccords corrigés avec image_gen ; aucune réduction de palette ni compression avec perte.
| Lot J priorité 1 : `tiat_life`, `collon_life`, `pannibal_life`, `lakhesh_life`, `almita_life`, `chtholly_home`, `ithea_home`, `nephren_home`, `willem_home`, `willem_cook`, `willem_coat`, `nygglatho_life`, `nygglatho_tea`, `fairy_01`, `fairy_02`, `fairy_03`, `fairy_04`, `fairy_05`, `fairy_06`, `tiat_pajamas`, `collon_pajamas`, `pannibal_pajamas`, `lakhesh_pajamas` (profil, face, dos, PNG et JSON ; 23 variantes, 69 planches) | ChatGPT/Codex (`image_gen`), 9 octobre 2026, cahier fourni `ASSETS_HD2D_SUKASUKA.md` ; pages officielles des 21 ZIP et planches existantes utilisées comme références, variantes domestiques et six fées secondaires originales ; couleurs visibles natives conservées sans réduction de palette ; masques/cadrage au plus proche voisin, repos des `_life` recopiés exactement. Provenance par planche dans `assets/characters/CREDITS.md` | — (images générées) | Images pour le projet ; personnages/univers inspirés de *SukaSuka*, droits des ayants droit réservés | SukaSuka J P1 |

## Cahier n° 3 — Lot I, priorité 2 : maison, entretien, lecture et chambres

32 images originales générées avec ChatGPT le 2026-10-10 selon `docs/ASSETS_HD2D_SUKASUKA.md`, lot I, priorité 2. Les dessins officiels des ZIP p082, p084 et p105 servent de référence pour les accessoires, la vaisselle et les matériaux ; les illustrations ajoutées sont des adaptations, pas des scans. Les autres compositions suivent les consignes du cahier et les PNG du projet `bed_iron` et `desk_chtholly`. Les variantes anciennes restent conservées. Sources générées, rectangles de découpe et aperçus conservés hors dépôt. Découpe mesurée, alpha binaire et réduction uniforme au plus proche voisin, sans remappage des couleurs RGB. PNG isolés : aucun placement, animation ou carte jouable ajouté.

- `assets/hd2d/interior/wallitem_notices_mix.png` — 77 × 58 px.
- `assets/hd2d/interior/wallitem_frame_landscape.png` — 58 × 48 px.
- `assets/hd2d/interior/wallitem_crystal_sconce.png` — 29 × 48 px.
- `assets/hd2d/interior/props/towel_rack.png` — 96 × 106 px.
- `assets/hd2d/interior/props/supply_cupboard.png` — 96 × 192 px.
- `assets/hd2d/interior/props/leak_bucket.png` — 48 × 43 px.
- `assets/hd2d/interior/props/repair_planks.png` — 67 × 173 px.
- `assets/hd2d/interior/props/cleaning_set.png` — 67 × 134 px.
- `assets/hd2d/interior/props/butter_cake.png` — 58 × 34 px.
- `assets/hd2d/interior/props/tea_tray_cheesecake.png` — 58 × 29 px.
- `assets/hd2d/interior/wallitem_spice_shelf.png` — 115 × 67 px.
- `assets/hd2d/interior/props/sacks_vegetables.png` — 115 × 67 px.
- `assets/hd2d/interior/props/pantry_cupboard.png` — 106 × 192 px.
- `assets/hd2d/interior/wallitem_apron_hook.png` — 38 × 86 px.
- `assets/hd2d/interior/props/armchair_reading.png` — 96 × 101 px.
- `assets/hd2d/interior/props/book_pile.png` — 48 × 48 px.
- `assets/hd2d/interior/props/filing_cabinet.png` — 96 × 134 px.
- `assets/hd2d/interior/props/coffee_tray.png` — 48 × 24 px.
- `assets/hd2d/interior/props/bed_curtain.png` — 154 × 202 px.
- `assets/hd2d/interior/props/vase_flowers.png` — 24 × 38 px.
- `assets/hd2d/interior/props/washbasin_stand.png` — 58 × 96 px.
- `assets/hd2d/interior/wallitem_labcoat.png` — 48 × 106 px.
- `assets/hd2d/interior/props/floor_cushions.png` — 115 × 38 px.
- `assets/hd2d/interior/wallitem_kids_drawings.png` — 115 × 58 px.
- `assets/hd2d/interior/props/hamper.png` — 58 × 67 px.
- `assets/hd2d/interior/props/oil_lamp.png` — 24 × 38 px.
- `assets/hd2d/interior/props/footlocker.png` — 77 × 48 px.
- `assets/hd2d/interior/props/bunk_bed.png` — 173 × 182 px.
- `assets/hd2d/interior/props/clothes_chest.png` — 86 × 58 px.
- `assets/hd2d/interior/props/hat_blue.png` — 48 × 24 px.
- `assets/hd2d/interior/props/desk_clean_brooch.png` — 106 × 101 px.
- `assets/hd2d/interior/props/crystal_lamp_table.png` — 29 × 48 px.

## Cahier n° 5 — Île 68, R0 : premier lot de mobilier

27 PNG générés avec ChatGPT / image_gen le 14 octobre 2026 : neuf corrections de face, dix-sept vues de flanc et une vue de dos. Références : les PNG existants du même mobilier et les cotes du cahier fourni `ASSETS_HD2D_ILE68.md`, sections 1, 2.7 et R0. Sources générées et anciens PNG conservés hors dépôt. Recalage géométrique autorisé par l’utilisateur : cadrage, projection des plateaux et bandes de hauteur, échantillonnage au plus proche voisin, alpha binaire ; aucune nouvelle couleur RGB visible ni réduction de palette. Les profils montrent la face du meuble vers l’est ; le dos du canapé conserve la couverture du côté opposé à la vue de face. Les nouvelles vues sont livrées comme images importables : leur sélection et leur placement dans les pièces restent à intégrer par le moteur.

- `assets/hd2d/interior/props/chair_guest.png` — 77 × 101 px.
- `assets/hd2d/interior/props/dining_table_long.png` — 384 × 106 px.
- `assets/hd2d/interior/props/dining_table_set.png` — 384 × 115 px.
- `assets/hd2d/interior/props/game_table.png` — 115 × 76 px.
- `assets/hd2d/interior/props/kitchen_counter.png` — 192 × 132 px.
- `assets/hd2d/interior/props/kitchen_table_ingredients.png` — 154 × 135 px.
- `assets/hd2d/interior/props/reading_table.png` — 173 × 130 px.
- `assets/hd2d/interior/props/sofa_beige.png` — 192 × 119 px.
- `assets/hd2d/interior/props/armchair_reading_side.png` — 86 × 106 px.
- `assets/hd2d/interior/props/board_games_shelf_side.png` — 48 × 190 px.
- `assets/hd2d/interior/props/bookshelf_low_side.png` — 48 × 132 px.
- `assets/hd2d/interior/props/bookshelf_tall_b_side.png` — 58 × 272 px.
- `assets/hd2d/interior/props/bookshelf_tall_side.png` — 58 × 272 px.
- `assets/hd2d/interior/props/chair_guest_side.png` — 58 × 106 px.
- `assets/hd2d/interior/props/desk_buried_side.png` — 77 × 156 px.
- `assets/hd2d/interior/props/desk_nygglatho_side.png` — 77 × 137 px.
- `assets/hd2d/interior/props/filing_cabinet_side.png` — 48 × 159 px.
- `assets/hd2d/interior/props/infirmary_desk_side.png` — 77 × 121 px.
- `assets/hd2d/interior/props/medicine_cabinet_side.png` — 48 × 198 px.
- `assets/hd2d/interior/props/pantry_cupboard_side.png` — 58 × 217 px.
- `assets/hd2d/interior/props/shoe_rack_side.png` — 38 × 99 px.
- `assets/hd2d/interior/props/sofa_beige_side.png` — 86 × 175 px.
- `assets/hd2d/interior/props/towel_shelf_side.png` — 48 × 179 px.
- `assets/hd2d/interior/props/toy_chest_side.png` — 58 × 97 px.
- `assets/hd2d/interior/props/wardrobe_chtholly_side.png` — 58 × 212 px.
- `assets/hd2d/interior/props/sofa_beige_back.png` — 192 × 119 px.
- `assets/hd2d/interior/props/infirmary_desk.png` — 125 × 96 px.

## Cahier n° 5 — Île 68, R0 : fin du mobilier et faces associées

32 PNG générés avec ChatGPT / image_gen le 14 octobre 2026 : les 27 images restantes de R0 (quatre corrections, vingt-trois vues nouvelles) et cinq faces R3 nécessaires à leur cohérence. Références : PNG du mobilier déjà livré ; bloc de style v5, sections 2.7 et R0 du cahier Île 68. Recalage géométrique autorisé au plus proche voisin, alpha binaire, sans nouvelle couleur RGB visible. Originaux et anciens PNG conservés hors dépôt. Les hauteurs des profils du fauteuil sous drap (106 px), du canapé du salon (152 px), de la vitrine (213 px) et du comptoir de librairie (152 px) suivent la formule 2.7, avec accord de l’utilisateur. Le cristal et la manivelle du projecteur changent de côté dans la vue arrière. Les nouvelles images sont importables ; leur enregistrement au catalogue moteur, leur sélection et leur placement dans les cartes restent à intégrer. R0 totalise désormais 54 PNG livrés ; les cinq faces associées ne constituent pas le lot R3 complet.

- `assets/hd2d/interior/props/chair_child.png` — 43 × 77 px.
- `assets/hd2d/interior/props/chair_wood.png` — 48 × 96 px.
- `assets/hd2d/interior/props/chair_child_side.png` — 43 × 77 px.
- `assets/hd2d/interior/props/chair_wood_side.png` — 48 × 96 px.
- `assets/hd2d/interior/props/clothes_chest_side.png` — 48 × 78 px.
- `assets/hd2d/interior/props/dresser_child_side.png` — 48 × 106 px.
- `assets/hd2d/interior/props/footlocker_side.png` — 48 × 63 px.
- `assets/hd2d/interior/props/bath_tub_side.png` — 96 × 167 px.
- `assets/hd2d/interior/props/armchair_reading_back.png` — 96 × 101 px.
- `assets/hd2d/interior/props/chair_child_back.png` — 43 × 77 px.
- `assets/hd2d/interior/props/chair_guest_back.png` — 77 × 101 px.
- `assets/hd2d/interior/props/bed_child_foot.png` — 77 × 118 px.
- `assets/hd2d/interior/props/bed_chtholly_foot.png` — 91 × 144 px.
- `assets/hd2d/interior/props/bed_iron_foot.png` — 96 × 152 px.
- `assets/hd2d/interior/props/bed_plain_foot.png` — 91 × 144 px.
- `assets/hd2d/interior/props/bunk_bed_foot.png` — 86 × 228 px.
- `assets/hd2d/interior/props/armchair_sheeted_side.png` — 86 × 106 px.
- `assets/hd2d/interior/props/sofa_salon_side.png` — 86 × 152 px.
- `assets/hd2d/interior/props/display_cabinet_side.png` — 58 × 213 px.
- `assets/hd2d/interior/props/sofa_salon_back.png` — 192 × 96 px.
- `assets/hd2d/interior/props/bookshop_counter_side.png` — 67 × 152 px.
- `assets/hd2d/interior/props/crystal_projector_back.png` — 77 × 154 px.
- `assets/hd2d/props/gangway.png` — 192 × 115 px.
- `assets/hd2d/props/bench.png` — 154 × 86 px.
- `assets/hd2d/props/bench_b_side.png` — 48 × 160 px.
- `assets/hd2d/props/bench_side.png` — 48 × 140 px.
- `assets/hd2d/props/bench_stone_side.png` — 48 × 104 px.
- `assets/hd2d/interior/props/armchair_sheeted.png` — 96 × 101 px.
- `assets/hd2d/interior/props/sofa_salon.png` — 192 × 96 px.
- `assets/hd2d/interior/props/display_cabinet.png` — 115 × 182 px.
- `assets/hd2d/interior/props/bookshop_counter.png` — 154 × 106 px.
- `assets/hd2d/interior/props/crystal_projector.png` — 77 × 154 px.

## Cahier n° 5 — Île 68, R1 : entrepôt, toit, crypte et fourrés

39 PNG livrés le 15 octobre 2026 : 29 remplaçants remplacés et dix nouvelles images, dont six bandes animées. Dessins générés avec ChatGPT / image_gen à partir du bloc de style v5, des références PNG livrées et des cadrages des remplaçants R1. Les planches officielles des ZIP (pages 98 à 105) ont été consultées pour l’ambiance ; la construction en bois à deux volumes et ses façades suivent l’adaptation originale du cahier, sans reprendre le manoir de l’anime. Originaux et générations conservés hors dépôt. Découpes et recalage géométrique au plus proche voisin, montage local par calques autorisé par l’utilisateur : bureau sans broche, miroir relevé, console et boîtier immobiles, linge et balancier animés. Les pixels hors des masques de retouche sont contrôlés identiques aux références. Alpha 0/255, sauf les deux vapeurs en alpha doux. Les trois formats préparatoires (sol de terrasse, bord d’ardoises, couverture) ont été validés pour la production des PNG ; leur intégration moteur reste à faire. La porte de service du flanc ouest est placée à 6 m de l’angle sud conformément aux données de la carte et à la demande T1 de CONTRACT_REQUESTS.md, plutôt qu’aux 8 m encore écrits au cahier.

- `assets/hd2d/buildings/warehouse_front_a.png` — 1728 × 624 px.
- `assets/hd2d/buildings/warehouse_front_a_side.png` — 1344 × 960 px.
- `assets/hd2d/buildings/warehouse_front_b.png` — 1152 × 624 px.
- `assets/hd2d/buildings/warehouse_front_b_side.png` — 1344 × 624 px.
- `assets/hd2d/interior/door_frame_wood.png` — 126 × 221 px.
- `assets/hd2d/interior/floor_flagstone_cellar.png` — 384 × 384 px.
- `assets/hd2d/interior/wall_cellar_stone.png` — 384 × 288 px.
- `assets/hd2d/interior/wallcut_stone.png` — 384 × 24 px.
- `assets/hd2d/interior/wallitem_height_marks.png` — 38 × 154 px.
- `assets/hd2d/interior/floor_roof_deck.png` — 384 × 384 px.
- `assets/hd2d/interior/props/roof_hatch.png` — 96 × 58 px.
- `assets/hd2d/interior/props/roof_ladder.png` — 77 × 288 px.
- `assets/hd2d/anim/drying_frame_wave.png` — 384 × 211 px par image, 4 images à 4 ips.
- `assets/hd2d/interior/props/roof_edge_slate.png` — 384 × 96 px.
- `assets/hd2d/interior/props/roof_railing_broken.png` — 192 × 77 px.
- `assets/hd2d/interior/props/bed_iron_cover.png` — 192 × 67 px.
- `assets/hd2d/anim/bath_steam.png` — 192 × 144 px par image, 6 images à 6 ips.
- `assets/hd2d/anim/comm_crystal_call.png` — 67 × 134 px par image, 4 images à 6 ips.
- `assets/hd2d/anim/leak_drip.png` — 24 × 96 px par image, 4 images à 8 ips.
- `assets/hd2d/anim/pot_steam.png` — 48 × 96 px par image, 6 images à 8 ips.
- `assets/hd2d/decals/bath_puddles.png` — 192 × 144 px.
- `assets/hd2d/decals/cards_floor.png` — 144 × 96 px.
- `assets/hd2d/decals/clothes_floor.png` — 192 × 144 px.
- `assets/hd2d/decals/papers_floor.png` — 192 × 144 px.
- `assets/hd2d/decals/runner_rug.png` — 96 × 384 px.
- `assets/hd2d/interior/props/desk_clean.png` — 106 × 101 px.
- `assets/hd2d/anim/wall_clock_swing.png` — 48 × 106 px par image, 4 images à 2 ips.
- `assets/hd2d/interior/props/desk_chtholly_mirror_up.png` — 106 × 101 px.
- `assets/hd2d/interior/props/piano_old.png` — 154 × 134 px.
- `assets/hd2d/interior/props/polishing_trestle.png` — 115 × 86 px.
- `assets/hd2d/interior/props/potted_plant.png` — 38 × 58 px.
- `assets/hd2d/interior/wallitem_clippings.png` — 77 × 58 px.
- `assets/hd2d/interior/window_dusty.png` — 96 × 96 px.
- `assets/hd2d/props/bramble_hedge.png` — 384 × 144 px.
- `assets/hd2d/props/thicket_a.png` — 240 × 154 px.
- `assets/hd2d/props/thicket_b.png` — 192 × 134 px.
- `assets/hd2d/props/alder.png` — 384 × 672 px.
- `assets/hd2d/props/marsh_snag.png` — 192 × 192 px.
- `assets/hd2d/props/thicket_c.png` — 288 × 173 px.


### Île 68 — cahier n° 5, R2 priorité 2 : gestes (15 octobre 2026)

Généré avec ChatGPT le 15 octobre 2026, cahier n° 5, lot R2, sous-lot des gestes :
`willem_life`, `willem_repair`, `nygglatho_laundry`, `cat_waiter_work`, `baker_work`.
Quinze PNG et quinze JSON (profil droit, face, dos), 144 poses ; rangées de repos
complémentaires recopiées au pixel près des vues existantes. Références : les sprites
existants de Willem, Nygglatho, du serveur et du boulanger, et les consignes des
sections 4.0 à 4.3 du cahier. Recalage au plus proche voisin et montages localisés
autorisés, originaux conservés hors dépôt. Les objets tenus font partie du dessin ;
le ballon, le plafond, la corde à linge, le comptoir et le pétrin ne sont pas dessinés.
Le chargement et les cadres sont contrôlés séparément de l'intégration : ensembles
non inscrits au manifeste et non placés dans les scènes ; transitions à valider après
intégration. La hauteur debout exclut les mains, le marteau et le drap levés au-dessus
de la tête. Les autres ensembles de priorité 2 restent à produire.
