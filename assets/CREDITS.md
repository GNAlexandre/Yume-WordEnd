# Crédits des assets tiers

Uniquement des assets CC0 (Kenney, Poly Haven, Quaternius…) ou sous licence explicitement
compatible, une ligne par asset ou par pack, ajoutée en bas (fusion par union entre lots).
Les dessins des membres et les planches de personnages sont listés dans
`assets/characters/CREDITS.md`.

| Fichier(s) | Auteur / source | URL | Licence | Ajouté par |
| --- | --- | --- | --- | --- |
| `assets/textures/checker.png` | généré par `tools/gen_placeholders.py checker` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | L0 |

Aucun fichier audio pour l'instant : l'enregistrement de *Scarborough Fair* utilisé par l'easter
egg n'a pas de licence établie (PLAN.md section 13) et n'est pas copié.

| Fichier(s) | Auteur / source | URL | Licence | Ajouté par |
| --- | --- | --- | --- | --- |
| `assets/items/*.png` | généré par `tools/gen_item_icons.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | L7 |
| `assets/ui/*.png` (cœurs, marqueur de cible, livre de sauvegarde, page de quête, étoile) | généré par `tools/gen_ui_icons.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | L10 |
| `assets/ui/icon.png`, `assets/ui/boot_splash.png` (icône du jeu, écran de démarrage) | généré par `tools/gen_branding.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | M2 |

<!-- sukasuka 3D provenance -->

## Personnages SukaSuka en 3D

Pack du 7 octobre 2026. Adaptations procédurales Blender 4.3.2 assistées par Codex, à partir des 162 scans du recueil SukaSuka fournis par l’utilisateur. Les scans restent hors du dépôt. Les designs et dessins sources appartiennent à leurs ayants droit ; les pièces fournies ne contiennent pas de licence accordée au projet. La licence du code ne transfère pas les droits sur ces designs.

Les fichiers `.import` et `.uid` sont des métadonnées techniques créées par Godot 4.7.2. Les palettes PNG extraites par Godot sont également incorporées aux GLB. Les fichiers JSON, TSCN et TRES sont générés par les scripts du projet. Les palettes absentes des planches au trait sont des adaptations signalées dans les spécifications.

| Fichier | Auteur / outil | Référence | Licence / statut |
| --- | --- | --- | --- |
| `assets/models/characters/model_metadata.gd` | GDScript du projet / Codex | Cadences, boucles et événements des GLB | Code d’intégration : régime du code du projet |
| `assets/models/characters/willem/willem.anim.json` | Scripts Python du projet / Codex | Willem Kmetsch, pages 5, 6, 7, 8, 9, 10 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/willem/willem.glb` | Blender 4.3.2 / Codex | Willem Kmetsch, pages 5, 6, 7, 8, 9, 10 | Design SukaSuka : droits non transférés |
| `assets/models/characters/willem/willem.tres` | Scripts Python du projet / Codex | Willem Kmetsch, pages 5, 6, 7, 8, 9, 10 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/willem/willem.tscn` | Scripts Python du projet / Codex | Willem Kmetsch, pages 5, 6, 7, 8, 9, 10 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/willem/willem_portrait.png` | Blender 4.3.2 / Codex | Willem Kmetsch, pages 5, 6, 7, 8, 9, 10 | Design SukaSuka : droits non transférés |
| `assets/models/characters/willem/willem_willem_palette.png` | Blender 4.3.2 / Codex | Willem Kmetsch, pages 5, 6, 7, 8, 9, 10 | Design SukaSuka : droits non transférés |
| `data/skins/sukasuka_willem.tres` | Scripts Python du projet / Codex | Willem Kmetsch, pages 5, 6, 7, 8, 9, 10 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/chtholly/chtholly.anim.json` | Scripts Python du projet / Codex | Chtholly Nota Seniorious, pages 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/chtholly/chtholly.glb` | Blender 4.3.2 / Codex | Chtholly Nota Seniorious, pages 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 | Design SukaSuka : droits non transférés |
| `assets/models/characters/chtholly/chtholly.tres` | Scripts Python du projet / Codex | Chtholly Nota Seniorious, pages 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/chtholly/chtholly.tscn` | Scripts Python du projet / Codex | Chtholly Nota Seniorious, pages 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/chtholly/chtholly_chtholly_palette.png` | Blender 4.3.2 / Codex | Chtholly Nota Seniorious, pages 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 | Design SukaSuka : droits non transférés |
| `assets/models/characters/chtholly/chtholly_portrait.png` | Blender 4.3.2 / Codex | Chtholly Nota Seniorious, pages 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 | Design SukaSuka : droits non transférés |
| `data/skins/sukasuka_chtholly.tres` | Scripts Python du projet / Codex | Chtholly Nota Seniorious, pages 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ithea/ithea.anim.json` | Scripts Python du projet / Codex | Ithea Myse Valgulious, pages 21, 22, 23, 24, 25, 26 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ithea/ithea.glb` | Blender 4.3.2 / Codex | Ithea Myse Valgulious, pages 21, 22, 23, 24, 25, 26 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ithea/ithea.tres` | Scripts Python du projet / Codex | Ithea Myse Valgulious, pages 21, 22, 23, 24, 25, 26 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ithea/ithea.tscn` | Scripts Python du projet / Codex | Ithea Myse Valgulious, pages 21, 22, 23, 24, 25, 26 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ithea/ithea_ithea_palette.png` | Blender 4.3.2 / Codex | Ithea Myse Valgulious, pages 21, 22, 23, 24, 25, 26 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ithea/ithea_portrait.png` | Blender 4.3.2 / Codex | Ithea Myse Valgulious, pages 21, 22, 23, 24, 25, 26 | Design SukaSuka : droits non transférés |
| `data/skins/sukasuka_ithea.tres` | Scripts Python du projet / Codex | Ithea Myse Valgulious, pages 21, 22, 23, 24, 25, 26 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nephren/nephren.anim.json` | Scripts Python du projet / Codex | Nephren Ruq Insania, pages 27, 28, 29, 30, 31, 32 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nephren/nephren.glb` | Blender 4.3.2 / Codex | Nephren Ruq Insania, pages 27, 28, 29, 30, 31, 32 | Design SukaSuka : droits non transférés |
| `assets/models/characters/nephren/nephren.tres` | Scripts Python du projet / Codex | Nephren Ruq Insania, pages 27, 28, 29, 30, 31, 32 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nephren/nephren.tscn` | Scripts Python du projet / Codex | Nephren Ruq Insania, pages 27, 28, 29, 30, 31, 32 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nephren/nephren_nephren_palette.png` | Blender 4.3.2 / Codex | Nephren Ruq Insania, pages 27, 28, 29, 30, 31, 32 | Design SukaSuka : droits non transférés |
| `assets/models/characters/nephren/nephren_portrait.png` | Blender 4.3.2 / Codex | Nephren Ruq Insania, pages 27, 28, 29, 30, 31, 32 | Design SukaSuka : droits non transférés |
| `data/skins/sukasuka_nephren.tres` | Scripts Python du projet / Codex | Nephren Ruq Insania, pages 27, 28, 29, 30, 31, 32 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nopht/nopht.anim.json` | Scripts Python du projet / Codex | Nopht Keh Desperatio, pages 33, 34, 35, 36 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nopht/nopht.glb` | Blender 4.3.2 / Codex | Nopht Keh Desperatio, pages 33, 34, 35, 36 | Design SukaSuka : droits non transférés |
| `assets/models/characters/nopht/nopht.tres` | Scripts Python du projet / Codex | Nopht Keh Desperatio, pages 33, 34, 35, 36 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nopht/nopht.tscn` | Scripts Python du projet / Codex | Nopht Keh Desperatio, pages 33, 34, 35, 36 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nopht/nopht_nopht_palette.png` | Blender 4.3.2 / Codex | Nopht Keh Desperatio, pages 33, 34, 35, 36 | Design SukaSuka : droits non transférés |
| `assets/models/characters/nopht/nopht_portrait.png` | Blender 4.3.2 / Codex | Nopht Keh Desperatio, pages 33, 34, 35, 36 | Design SukaSuka : droits non transférés |
| `data/skins/sukasuka_nopht.tres` | Scripts Python du projet / Codex | Nopht Keh Desperatio, pages 33, 34, 35, 36 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rhantolk/rhantolk.anim.json` | Scripts Python du projet / Codex | Rhantolk Ytri Historia, pages 37, 38, 39, 40 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rhantolk/rhantolk.glb` | Blender 4.3.2 / Codex | Rhantolk Ytri Historia, pages 37, 38, 39, 40 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rhantolk/rhantolk.tres` | Scripts Python du projet / Codex | Rhantolk Ytri Historia, pages 37, 38, 39, 40 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rhantolk/rhantolk.tscn` | Scripts Python du projet / Codex | Rhantolk Ytri Historia, pages 37, 38, 39, 40 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rhantolk/rhantolk_portrait.png` | Blender 4.3.2 / Codex | Rhantolk Ytri Historia, pages 37, 38, 39, 40 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rhantolk/rhantolk_rhantolk_palette.png` | Blender 4.3.2 / Codex | Rhantolk Ytri Historia, pages 37, 38, 39, 40 | Design SukaSuka : droits non transférés |
| `data/skins/sukasuka_rhantolk.tres` | Scripts Python du projet / Codex | Rhantolk Ytri Historia, pages 37, 38, 39, 40 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/tiat/tiat.anim.json` | Scripts Python du projet / Codex | Tiat, pages 41, 42, 43, 44 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/tiat/tiat.glb` | Blender 4.3.2 / Codex | Tiat, pages 41, 42, 43, 44 | Design SukaSuka : droits non transférés |
| `assets/models/characters/tiat/tiat.tres` | Scripts Python du projet / Codex | Tiat, pages 41, 42, 43, 44 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/tiat/tiat.tscn` | Scripts Python du projet / Codex | Tiat, pages 41, 42, 43, 44 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/tiat/tiat_portrait.png` | Blender 4.3.2 / Codex | Tiat, pages 41, 42, 43, 44 | Design SukaSuka : droits non transférés |
| `assets/models/characters/tiat/tiat_tiat_palette.png` | Blender 4.3.2 / Codex | Tiat, pages 41, 42, 43, 44 | Design SukaSuka : droits non transférés |
| `assets/models/characters/pannibal/pannibal.anim.json` | Scripts Python du projet / Codex | Pannibal, pages 45, 46 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/pannibal/pannibal.glb` | Blender 4.3.2 / Codex | Pannibal, pages 45, 46 | Design SukaSuka : droits non transférés |
| `assets/models/characters/pannibal/pannibal.tres` | Scripts Python du projet / Codex | Pannibal, pages 45, 46 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/pannibal/pannibal.tscn` | Scripts Python du projet / Codex | Pannibal, pages 45, 46 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/pannibal/pannibal_pannibal_palette.png` | Blender 4.3.2 / Codex | Pannibal, pages 45, 46 | Design SukaSuka : droits non transférés |
| `assets/models/characters/pannibal/pannibal_portrait.png` | Blender 4.3.2 / Codex | Pannibal, pages 45, 46 | Design SukaSuka : droits non transférés |
| `assets/models/characters/collon/collon.anim.json` | Scripts Python du projet / Codex | Collon, pages 47, 48 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/collon/collon.glb` | Blender 4.3.2 / Codex | Collon, pages 47, 48 | Design SukaSuka : droits non transférés |
| `assets/models/characters/collon/collon.tres` | Scripts Python du projet / Codex | Collon, pages 47, 48 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/collon/collon.tscn` | Scripts Python du projet / Codex | Collon, pages 47, 48 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/collon/collon_collon_palette.png` | Blender 4.3.2 / Codex | Collon, pages 47, 48 | Design SukaSuka : droits non transférés |
| `assets/models/characters/collon/collon_portrait.png` | Blender 4.3.2 / Codex | Collon, pages 47, 48 | Design SukaSuka : droits non transférés |
| `assets/models/characters/lakhesh/lakhesh.anim.json` | Scripts Python du projet / Codex | Lakhesh, pages 49, 50 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/lakhesh/lakhesh.glb` | Blender 4.3.2 / Codex | Lakhesh, pages 49, 50 | Design SukaSuka : droits non transférés |
| `assets/models/characters/lakhesh/lakhesh.tres` | Scripts Python du projet / Codex | Lakhesh, pages 49, 50 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/lakhesh/lakhesh.tscn` | Scripts Python du projet / Codex | Lakhesh, pages 49, 50 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/lakhesh/lakhesh_lakhesh_palette.png` | Blender 4.3.2 / Codex | Lakhesh, pages 49, 50 | Design SukaSuka : droits non transférés |
| `assets/models/characters/lakhesh/lakhesh_portrait.png` | Blender 4.3.2 / Codex | Lakhesh, pages 49, 50 | Design SukaSuka : droits non transférés |
| `assets/models/characters/nygglatho/nygglatho.anim.json` | Scripts Python du projet / Codex | Nygglatho, pages 51, 52, 53 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nygglatho/nygglatho.glb` | Blender 4.3.2 / Codex | Nygglatho, pages 51, 52, 53 | Design SukaSuka : droits non transférés |
| `assets/models/characters/nygglatho/nygglatho.tres` | Scripts Python du projet / Codex | Nygglatho, pages 51, 52, 53 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nygglatho/nygglatho.tscn` | Scripts Python du projet / Codex | Nygglatho, pages 51, 52, 53 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/nygglatho/nygglatho_nygglatho_palette.png` | Blender 4.3.2 / Codex | Nygglatho, pages 51, 52, 53 | Design SukaSuka : droits non transférés |
| `assets/models/characters/nygglatho/nygglatho_portrait.png` | Blender 4.3.2 / Codex | Nygglatho, pages 51, 52, 53 | Design SukaSuka : droits non transférés |
| `assets/models/characters/grick/grick.anim.json` | Scripts Python du projet / Codex | Grick, pages 54 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/grick/grick.glb` | Blender 4.3.2 / Codex | Grick, pages 54 | Design SukaSuka : droits non transférés |
| `assets/models/characters/grick/grick.tres` | Scripts Python du projet / Codex | Grick, pages 54 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/grick/grick.tscn` | Scripts Python du projet / Codex | Grick, pages 54 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/grick/grick_grick_palette.png` | Blender 4.3.2 / Codex | Grick, pages 54 | Design SukaSuka : droits non transférés |
| `assets/models/characters/grick/grick_portrait.png` | Blender 4.3.2 / Codex | Grick, pages 54 | Design SukaSuka : droits non transférés |
| `assets/models/characters/limeskin/limeskin.anim.json` | Scripts Python du projet / Codex | Limeskin, pages 55, 56 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/limeskin/limeskin.glb` | Blender 4.3.2 / Codex | Limeskin, pages 55, 56 | Design SukaSuka : droits non transférés |
| `assets/models/characters/limeskin/limeskin.tres` | Scripts Python du projet / Codex | Limeskin, pages 55, 56 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/limeskin/limeskin.tscn` | Scripts Python du projet / Codex | Limeskin, pages 55, 56 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/limeskin/limeskin_limeskin_palette.png` | Blender 4.3.2 / Codex | Limeskin, pages 55, 56 | Design SukaSuka : droits non transférés |
| `assets/models/characters/limeskin/limeskin_portrait.png` | Blender 4.3.2 / Codex | Limeskin, pages 55, 56 | Design SukaSuka : droits non transférés |
| `assets/models/characters/almaria/almaria.anim.json` | Scripts Python du projet / Codex | Almaria, pages 57 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/almaria/almaria.glb` | Blender 4.3.2 / Codex | Almaria, pages 57 | Design SukaSuka : droits non transférés |
| `assets/models/characters/almaria/almaria.tres` | Scripts Python du projet / Codex | Almaria, pages 57 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/almaria/almaria.tscn` | Scripts Python du projet / Codex | Almaria, pages 57 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/almaria/almaria_almaria_palette.png` | Blender 4.3.2 / Codex | Almaria, pages 57 | Design SukaSuka : droits non transférés |
| `assets/models/characters/almaria/almaria_portrait.png` | Blender 4.3.2 / Codex | Almaria, pages 57 | Design SukaSuka : droits non transférés |
| `assets/models/characters/lillia/lillia.anim.json` | Scripts Python du projet / Codex | Lillia Asplay, pages 58 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/lillia/lillia.glb` | Blender 4.3.2 / Codex | Lillia Asplay, pages 58 | Design SukaSuka : droits non transférés |
| `assets/models/characters/lillia/lillia.tres` | Scripts Python du projet / Codex | Lillia Asplay, pages 58 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/lillia/lillia.tscn` | Scripts Python du projet / Codex | Lillia Asplay, pages 58 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/lillia/lillia_lillia_palette.png` | Blender 4.3.2 / Codex | Lillia Asplay, pages 58 | Design SukaSuka : droits non transférés |
| `assets/models/characters/lillia/lillia_portrait.png` | Blender 4.3.2 / Codex | Lillia Asplay, pages 58 | Design SukaSuka : droits non transférés |
| `data/skins/sukasuka_lillia.tres` | Scripts Python du projet / Codex | Lillia Asplay, pages 58 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/souwong_young/souwong_young.anim.json` | Scripts Python du projet / Codex | Souwong Kandel — jeune, pages 59 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/souwong_young/souwong_young.glb` | Blender 4.3.2 / Codex | Souwong Kandel — jeune, pages 59 | Design SukaSuka : droits non transférés |
| `assets/models/characters/souwong_young/souwong_young.tres` | Scripts Python du projet / Codex | Souwong Kandel — jeune, pages 59 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/souwong_young/souwong_young.tscn` | Scripts Python du projet / Codex | Souwong Kandel — jeune, pages 59 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/souwong_young/souwong_young_portrait.png` | Blender 4.3.2 / Codex | Souwong Kandel — jeune, pages 59 | Design SukaSuka : droits non transférés |
| `assets/models/characters/souwong_young/souwong_young_souwong_young_palette.png` | Blender 4.3.2 / Codex | Souwong Kandel — jeune, pages 59 | Design SukaSuka : droits non transférés |
| `assets/models/characters/souwong_sage/souwong_sage.anim.json` | Scripts Python du projet / Codex | Souwong Kandel — Grand Sage, pages 60 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/souwong_sage/souwong_sage.glb` | Blender 4.3.2 / Codex | Souwong Kandel — Grand Sage, pages 60 | Design SukaSuka : droits non transférés |
| `assets/models/characters/souwong_sage/souwong_sage.tres` | Scripts Python du projet / Codex | Souwong Kandel — Grand Sage, pages 60 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/souwong_sage/souwong_sage.tscn` | Scripts Python du projet / Codex | Souwong Kandel — Grand Sage, pages 60 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/souwong_sage/souwong_sage_portrait.png` | Blender 4.3.2 / Codex | Souwong Kandel — Grand Sage, pages 60 | Design SukaSuka : droits non transférés |
| `assets/models/characters/souwong_sage/souwong_sage_souwong_sage_palette.png` | Blender 4.3.2 / Codex | Souwong Kandel — Grand Sage, pages 60 | Design SukaSuka : droits non transférés |
| `assets/models/characters/eboncandle_ancient/eboncandle_ancient.anim.json` | Scripts Python du projet / Codex | Eboncandle — ancien corps, pages 61 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/eboncandle_ancient/eboncandle_ancient.glb` | Blender 4.3.2 / Codex | Eboncandle — ancien corps, pages 61 | Design SukaSuka : droits non transférés |
| `assets/models/characters/eboncandle_ancient/eboncandle_ancient.tres` | Scripts Python du projet / Codex | Eboncandle — ancien corps, pages 61 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/eboncandle_ancient/eboncandle_ancient.tscn` | Scripts Python du projet / Codex | Eboncandle — ancien corps, pages 61 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/eboncandle_ancient/eboncandle_ancient_eboncandle_ancient_palette.png` | Blender 4.3.2 / Codex | Eboncandle — ancien corps, pages 61 | Design SukaSuka : droits non transférés |
| `assets/models/characters/eboncandle_ancient/eboncandle_ancient_portrait.png` | Blender 4.3.2 / Codex | Eboncandle — ancien corps, pages 61 | Design SukaSuka : droits non transférés |
| `assets/models/characters/eboncandle_skull/eboncandle_skull.anim.json` | Scripts Python du projet / Codex | Eboncandle — crâne, pages 62 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/eboncandle_skull/eboncandle_skull.glb` | Blender 4.3.2 / Codex | Eboncandle — crâne, pages 62 | Design SukaSuka : droits non transférés |
| `assets/models/characters/eboncandle_skull/eboncandle_skull.tres` | Scripts Python du projet / Codex | Eboncandle — crâne, pages 62 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/eboncandle_skull/eboncandle_skull.tscn` | Scripts Python du projet / Codex | Eboncandle — crâne, pages 62 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/eboncandle_skull/eboncandle_skull_eboncandle_skull_palette.png` | Blender 4.3.2 / Codex | Eboncandle — crâne, pages 62 | Design SukaSuka : droits non transférés |
| `assets/models/characters/eboncandle_skull/eboncandle_skull_portrait.png` | Blender 4.3.2 / Codex | Eboncandle — crâne, pages 62 | Design SukaSuka : droits non transférés |
| `assets/models/characters/elq/elq.anim.json` | Scripts Python du projet / Codex | Elq Hrqstn, pages 63 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/elq/elq.glb` | Blender 4.3.2 / Codex | Elq Hrqstn, pages 63 | Design SukaSuka : droits non transférés |
| `assets/models/characters/elq/elq.tres` | Scripts Python du projet / Codex | Elq Hrqstn, pages 63 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/elq/elq.tscn` | Scripts Python du projet / Codex | Elq Hrqstn, pages 63 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/elq/elq_elq_palette.png` | Blender 4.3.2 / Codex | Elq Hrqstn, pages 63 | Design SukaSuka : droits non transférés |
| `assets/models/characters/elq/elq_portrait.png` | Blender 4.3.2 / Codex | Elq Hrqstn, pages 63 | Design SukaSuka : droits non transférés |
| `assets/models/characters/almita/almita.anim.json` | Scripts Python du projet / Codex | Almita, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/almita/almita.glb` | Blender 4.3.2 / Codex | Almita, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/almita/almita.tres` | Scripts Python du projet / Codex | Almita, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/almita/almita.tscn` | Scripts Python du projet / Codex | Almita, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/almita/almita_almita_palette.png` | Blender 4.3.2 / Codex | Almita, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/almita/almita_portrait.png` | Blender 4.3.2 / Codex | Almita, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/sarya/sarya.anim.json` | Scripts Python du projet / Codex | Sarya / サリャ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/sarya/sarya.glb` | Blender 4.3.2 / Codex | Sarya / サリャ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/sarya/sarya.tres` | Scripts Python du projet / Codex | Sarya / サリャ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/sarya/sarya.tscn` | Scripts Python du projet / Codex | Sarya / サリャ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/sarya/sarya_portrait.png` | Blender 4.3.2 / Codex | Sarya / サリャ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/sarya/sarya_sarya_palette.png` | Blender 4.3.2 / Codex | Sarya / サリャ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/willemia/willemia.anim.json` | Scripts Python du projet / Codex | Willemia / ウィレミア, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/willemia/willemia.glb` | Blender 4.3.2 / Codex | Willemia / ウィレミア, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/willemia/willemia.tres` | Scripts Python du projet / Codex | Willemia / ウィレミア, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/willemia/willemia.tscn` | Scripts Python du projet / Codex | Willemia / ウィレミア, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/willemia/willemia_portrait.png` | Blender 4.3.2 / Codex | Willemia / ウィレミア, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/willemia/willemia_willemia_palette.png` | Blender 4.3.2 / Codex | Willemia / ウィレミア, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ecluecla/ecluecla.anim.json` | Scripts Python du projet / Codex | Ecluecla / エクルエクラ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ecluecla/ecluecla.glb` | Blender 4.3.2 / Codex | Ecluecla / エクルエクラ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ecluecla/ecluecla.tres` | Scripts Python du projet / Codex | Ecluecla / エクルエクラ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ecluecla/ecluecla.tscn` | Scripts Python du projet / Codex | Ecluecla / エクルエクラ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ecluecla/ecluecla_ecluecla_palette.png` | Blender 4.3.2 / Codex | Ecluecla / エクルエクラ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ecluecla/ecluecla_portrait.png` | Blender 4.3.2 / Codex | Ecluecla / エクルエクラ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/jorget/jorget.anim.json` | Scripts Python du projet / Codex | Jorget / ジョルゼット, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/jorget/jorget.glb` | Blender 4.3.2 / Codex | Jorget / ジョルゼット, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/jorget/jorget.tres` | Scripts Python du projet / Codex | Jorget / ジョルゼット, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/jorget/jorget.tscn` | Scripts Python du projet / Codex | Jorget / ジョルゼット, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/jorget/jorget_jorget_palette.png` | Blender 4.3.2 / Codex | Jorget / ジョルゼット, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/jorget/jorget_portrait.png` | Blender 4.3.2 / Codex | Jorget / ジョルゼット, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/tilfey/tilfey.anim.json` | Scripts Python du projet / Codex | Tilfey / ティルフェイ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/tilfey/tilfey.glb` | Blender 4.3.2 / Codex | Tilfey / ティルフェイ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/tilfey/tilfey.tres` | Scripts Python du projet / Codex | Tilfey / ティルフェイ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/tilfey/tilfey.tscn` | Scripts Python du projet / Codex | Tilfey / ティルフェイ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/tilfey/tilfey_portrait.png` | Blender 4.3.2 / Codex | Tilfey / ティルフェイ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/tilfey/tilfey_tilfey_palette.png` | Blender 4.3.2 / Codex | Tilfey / ティルフェイ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/bitora/bitora.anim.json` | Scripts Python du projet / Codex | Bitora / ビトゥラ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/bitora/bitora.glb` | Blender 4.3.2 / Codex | Bitora / ビトゥラ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/bitora/bitora.tres` | Scripts Python du projet / Codex | Bitora / ビトゥラ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/bitora/bitora.tscn` | Scripts Python du projet / Codex | Bitora / ビトゥラ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/bitora/bitora_bitora_palette.png` | Blender 4.3.2 / Codex | Bitora / ビトゥラ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/bitora/bitora_portrait.png` | Blender 4.3.2 / Codex | Bitora / ビトゥラ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/illustote/illustote.anim.json` | Scripts Python du projet / Codex | Illustote / イルストート, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/illustote/illustote.glb` | Blender 4.3.2 / Codex | Illustote / イルストート, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/illustote/illustote.tres` | Scripts Python du projet / Codex | Illustote / イルストート, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/illustote/illustote.tscn` | Scripts Python du projet / Codex | Illustote / イルストート, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/illustote/illustote_illustote_palette.png` | Blender 4.3.2 / Codex | Illustote / イルストート, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/illustote/illustote_portrait.png` | Blender 4.3.2 / Codex | Illustote / イルストート, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rinsha/rinsha.anim.json` | Scripts Python du projet / Codex | Rinsha / リンシャ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rinsha/rinsha.glb` | Blender 4.3.2 / Codex | Rinsha / リンシャ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rinsha/rinsha.tres` | Scripts Python du projet / Codex | Rinsha / リンシャ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rinsha/rinsha.tscn` | Scripts Python du projet / Codex | Rinsha / リンシャ, pages 64 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rinsha/rinsha_portrait.png` | Blender 4.3.2 / Codex | Rinsha / リンシャ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rinsha/rinsha_rinsha_palette.png` | Blender 4.3.2 / Codex | Rinsha / リンシャ, pages 64 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ballman/ballman.anim.json` | Scripts Python du projet / Codex | Ballman / ボールマン, pages 65 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ballman/ballman.glb` | Blender 4.3.2 / Codex | Ballman / ボールマン, pages 65 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ballman/ballman.tres` | Scripts Python du projet / Codex | Ballman / ボールマン, pages 65 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ballman/ballman.tscn` | Scripts Python du projet / Codex | Ballman / ボールマン, pages 65 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/ballman/ballman_ballman_palette.png` | Blender 4.3.2 / Codex | Ballman / ボールマン, pages 65 | Design SukaSuka : droits non transférés |
| `assets/models/characters/ballman/ballman_portrait.png` | Blender 4.3.2 / Codex | Ballman / ボールマン, pages 65 | Design SukaSuka : droits non transférés |
| `assets/models/characters/golem/golem.anim.json` | Scripts Python du projet / Codex | Golem domestique, pages 65 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/golem/golem.glb` | Blender 4.3.2 / Codex | Golem domestique, pages 65 | Design SukaSuka : droits non transférés |
| `assets/models/characters/golem/golem.tres` | Scripts Python du projet / Codex | Golem domestique, pages 65 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/golem/golem.tscn` | Scripts Python du projet / Codex | Golem domestique, pages 65 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/golem/golem_golem_palette.png` | Blender 4.3.2 / Codex | Golem domestique, pages 65 | Design SukaSuka : droits non transférés |
| `assets/models/characters/golem/golem_portrait.png` | Blender 4.3.2 / Codex | Golem domestique, pages 65 | Design SukaSuka : droits non transférés |
| `assets/models/characters/cyclops_doctor/cyclops_doctor.anim.json` | Scripts Python du projet / Codex | Médecin cyclope, pages 66 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/cyclops_doctor/cyclops_doctor.glb` | Blender 4.3.2 / Codex | Médecin cyclope, pages 66 | Design SukaSuka : droits non transférés |
| `assets/models/characters/cyclops_doctor/cyclops_doctor.tres` | Scripts Python du projet / Codex | Médecin cyclope, pages 66 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/cyclops_doctor/cyclops_doctor.tscn` | Scripts Python du projet / Codex | Médecin cyclope, pages 66 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/cyclops_doctor/cyclops_doctor_cyclops_doctor_palette.png` | Blender 4.3.2 / Codex | Médecin cyclope, pages 66 | Design SukaSuka : droits non transférés |
| `assets/models/characters/cyclops_doctor/cyclops_doctor_portrait.png` | Blender 4.3.2 / Codex | Médecin cyclope, pages 66 | Design SukaSuka : droits non transférés |
| `assets/models/characters/phyr/phyr.anim.json` | Scripts Python du projet / Codex | Phyracorlybia Dorio, pages 67 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/phyr/phyr.glb` | Blender 4.3.2 / Codex | Phyracorlybia Dorio, pages 67 | Design SukaSuka : droits non transférés |
| `assets/models/characters/phyr/phyr.tres` | Scripts Python du projet / Codex | Phyracorlybia Dorio, pages 67 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/phyr/phyr.tscn` | Scripts Python du projet / Codex | Phyracorlybia Dorio, pages 67 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/phyr/phyr_phyr_palette.png` | Blender 4.3.2 / Codex | Phyracorlybia Dorio, pages 67 | Design SukaSuka : droits non transférés |
| `assets/models/characters/phyr/phyr_portrait.png` | Blender 4.3.2 / Codex | Phyracorlybia Dorio, pages 67 | Design SukaSuka : droits non transférés |
| `assets/models/characters/kaiya/kaiya.anim.json` | Scripts Python du projet / Codex | Kaiya, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/kaiya/kaiya.glb` | Blender 4.3.2 / Codex | Kaiya, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/kaiya/kaiya.tres` | Scripts Python du projet / Codex | Kaiya, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/kaiya/kaiya.tscn` | Scripts Python du projet / Codex | Kaiya, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/kaiya/kaiya_kaiya_palette.png` | Blender 4.3.2 / Codex | Kaiya, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/kaiya/kaiya_portrait.png` | Blender 4.3.2 / Codex | Kaiya, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/knight_canine/knight_canine.anim.json` | Scripts Python du projet / Codex | Chevalier canin anonyme, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/knight_canine/knight_canine.glb` | Blender 4.3.2 / Codex | Chevalier canin anonyme, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/knight_canine/knight_canine.tres` | Scripts Python du projet / Codex | Chevalier canin anonyme, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/knight_canine/knight_canine.tscn` | Scripts Python du projet / Codex | Chevalier canin anonyme, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/knight_canine/knight_canine_knight_canine_palette.png` | Blender 4.3.2 / Codex | Chevalier canin anonyme, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/knight_canine/knight_canine_portrait.png` | Blender 4.3.2 / Codex | Chevalier canin anonyme, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/knight_feline/knight_feline.anim.json` | Scripts Python du projet / Codex | Chevalier félin anonyme, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/knight_feline/knight_feline.glb` | Blender 4.3.2 / Codex | Chevalier félin anonyme, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/knight_feline/knight_feline.tres` | Scripts Python du projet / Codex | Chevalier félin anonyme, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/knight_feline/knight_feline.tscn` | Scripts Python du projet / Codex | Chevalier félin anonyme, pages 68 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/knight_feline/knight_feline_knight_feline_palette.png` | Blender 4.3.2 / Codex | Chevalier félin anonyme, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/knight_feline/knight_feline_portrait.png` | Blender 4.3.2 / Codex | Chevalier félin anonyme, pages 68 | Design SukaSuka : droits non transférés |
| `assets/models/characters/police_golem/police_golem.anim.json` | Scripts Python du projet / Codex | Golem policier, pages 69 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/police_golem/police_golem.glb` | Blender 4.3.2 / Codex | Golem policier, pages 69 | Design SukaSuka : droits non transférés |
| `assets/models/characters/police_golem/police_golem.tres` | Scripts Python du projet / Codex | Golem policier, pages 69 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/police_golem/police_golem.tscn` | Scripts Python du projet / Codex | Golem policier, pages 69 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/police_golem/police_golem_police_golem_palette.png` | Blender 4.3.2 / Codex | Golem policier, pages 69 | Design SukaSuka : droits non transférés |
| `assets/models/characters/police_golem/police_golem_portrait.png` | Blender 4.3.2 / Codex | Golem policier, pages 69 | Design SukaSuka : droits non transférés |
| `assets/models/characters/godrey/godrey.anim.json` | Scripts Python du projet / Codex | Godrey Mogutaman, pages 69 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/godrey/godrey.glb` | Blender 4.3.2 / Codex | Godrey Mogutaman, pages 69 | Design SukaSuka : droits non transférés |
| `assets/models/characters/godrey/godrey.tres` | Scripts Python du projet / Codex | Godrey Mogutaman, pages 69 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/godrey/godrey.tscn` | Scripts Python du projet / Codex | Godrey Mogutaman, pages 69 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/godrey/godrey_godrey_palette.png` | Blender 4.3.2 / Codex | Godrey Mogutaman, pages 69 | Design SukaSuka : droits non transférés |
| `assets/models/characters/godrey/godrey_portrait.png` | Blender 4.3.2 / Codex | Godrey Mogutaman, pages 69 | Design SukaSuka : droits non transférés |
| `assets/models/characters/baroni/baroni.anim.json` | Scripts Python du projet / Codex | Baroni Makish, pages 70 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/baroni/baroni.glb` | Blender 4.3.2 / Codex | Baroni Makish, pages 70 | Design SukaSuka : droits non transférés |
| `assets/models/characters/baroni/baroni.tres` | Scripts Python du projet / Codex | Baroni Makish, pages 70 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/baroni/baroni.tscn` | Scripts Python du projet / Codex | Baroni Makish, pages 70 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/baroni/baroni_baroni_palette.png` | Blender 4.3.2 / Codex | Baroni Makish, pages 70 | Design SukaSuka : droits non transférés |
| `assets/models/characters/baroni/baroni_portrait.png` | Blender 4.3.2 / Codex | Baroni Makish, pages 70 | Design SukaSuka : droits non transférés |
| `assets/models/characters/frog_soldier/frog_soldier.anim.json` | Scripts Python du projet / Codex | Soldat grenouille, pages 70 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/frog_soldier/frog_soldier.glb` | Blender 4.3.2 / Codex | Soldat grenouille, pages 70 | Design SukaSuka : droits non transférés |
| `assets/models/characters/frog_soldier/frog_soldier.tres` | Scripts Python du projet / Codex | Soldat grenouille, pages 70 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/frog_soldier/frog_soldier.tscn` | Scripts Python du projet / Codex | Soldat grenouille, pages 70 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/frog_soldier/frog_soldier_frog_soldier_palette.png` | Blender 4.3.2 / Codex | Soldat grenouille, pages 70 | Design SukaSuka : droits non transférés |
| `assets/models/characters/frog_soldier/frog_soldier_portrait.png` | Blender 4.3.2 / Codex | Soldat grenouille, pages 70 | Design SukaSuka : droits non transférés |
| `assets/models/characters/bird_soldier/bird_soldier.anim.json` | Scripts Python du projet / Codex | Soldat aviaire, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/bird_soldier/bird_soldier.glb` | Blender 4.3.2 / Codex | Soldat aviaire, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/bird_soldier/bird_soldier.tres` | Scripts Python du projet / Codex | Soldat aviaire, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/bird_soldier/bird_soldier.tscn` | Scripts Python du projet / Codex | Soldat aviaire, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/bird_soldier/bird_soldier_bird_soldier_palette.png` | Blender 4.3.2 / Codex | Soldat aviaire, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/bird_soldier/bird_soldier_portrait.png` | Blender 4.3.2 / Codex | Soldat aviaire, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/wolf_soldier/wolf_soldier.anim.json` | Scripts Python du projet / Codex | Soldat loup, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/wolf_soldier/wolf_soldier.glb` | Blender 4.3.2 / Codex | Soldat loup, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/wolf_soldier/wolf_soldier.tres` | Scripts Python du projet / Codex | Soldat loup, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/wolf_soldier/wolf_soldier.tscn` | Scripts Python du projet / Codex | Soldat loup, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/wolf_soldier/wolf_soldier_portrait.png` | Blender 4.3.2 / Codex | Soldat loup, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/wolf_soldier/wolf_soldier_wolf_soldier_palette.png` | Blender 4.3.2 / Codex | Soldat loup, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/hawk_soldier/hawk_soldier.anim.json` | Scripts Python du projet / Codex | Soldat rapace, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/hawk_soldier/hawk_soldier.glb` | Blender 4.3.2 / Codex | Soldat rapace, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/hawk_soldier/hawk_soldier.tres` | Scripts Python du projet / Codex | Soldat rapace, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/hawk_soldier/hawk_soldier.tscn` | Scripts Python du projet / Codex | Soldat rapace, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/hawk_soldier/hawk_soldier_hawk_soldier_palette.png` | Blender 4.3.2 / Codex | Soldat rapace, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/hawk_soldier/hawk_soldier_portrait.png` | Blender 4.3.2 / Codex | Soldat rapace, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/cat_soldier/cat_soldier.anim.json` | Scripts Python du projet / Codex | Soldat félin, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/cat_soldier/cat_soldier.glb` | Blender 4.3.2 / Codex | Soldat félin, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/cat_soldier/cat_soldier.tres` | Scripts Python du projet / Codex | Soldat félin, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/cat_soldier/cat_soldier.tscn` | Scripts Python du projet / Codex | Soldat félin, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/cat_soldier/cat_soldier_cat_soldier_palette.png` | Blender 4.3.2 / Codex | Soldat félin, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/cat_soldier/cat_soldier_portrait.png` | Blender 4.3.2 / Codex | Soldat félin, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rabbit_soldier/rabbit_soldier.anim.json` | Scripts Python du projet / Codex | Soldat lapin, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rabbit_soldier/rabbit_soldier.glb` | Blender 4.3.2 / Codex | Soldat lapin, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rabbit_soldier/rabbit_soldier.tres` | Scripts Python du projet / Codex | Soldat lapin, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rabbit_soldier/rabbit_soldier.tscn` | Scripts Python du projet / Codex | Soldat lapin, pages 71 | Métadonnées du projet ; design référencé, droits non transférés |
| `assets/models/characters/rabbit_soldier/rabbit_soldier_portrait.png` | Blender 4.3.2 / Codex | Soldat lapin, pages 71 | Design SukaSuka : droits non transférés |
| `assets/models/characters/rabbit_soldier/rabbit_soldier_rabbit_soldier_palette.png` | Blender 4.3.2 / Codex | Soldat lapin, pages 71 | Design SukaSuka : droits non transférés |
| `assets/items/*.png` de l'acte 1 (13 nouvelles icônes, `page_fragment` redessinée ; `shell` et `bookmark` retirées) | généré par `tools/gen_item_icons.py` | — | licence du code du projet (MIT proposée, PLAN.md section 13) | Acte 1 |
