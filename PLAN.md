# WordEnd — Plan complet (Godot 4, HD-2D, Claude Code cloud)

Oct 5, 2026 · @Alexandre

## 1. Vision et périmètre

WordEnd passe d'un easter egg 2D (Chtholly et son épée Seniorious contre des vagues de Timeres) à un **action-aventure en « HD-2D » à la manière d'*Octopath Traveler*, centré sur le combat** : des personnages en sprites de pixel art (les planches de l'easter egg) dans un petit monde en relief construit **uniquement avec des images** (sol en tuiles, falaises texturées, façades de bâtiments et décors en panneaux debout, ciel peint), vu par une **caméra fixe inclinée** au champ étroit, avec flou de profondeur, lueur et lumière chaude du couchant ; cahier des charges des images : `docs/ASSETS_HD2D.md`. Il est jouable dans une page de yumenovel.fr et développé dans Godot 4 par des sessions Claude Code cloud en parallèle. Le combat à l'épée et la charge magique de l'easter egg restent le cœur du jeu ; le village, les PNJ et la collecte sont la respiration entre deux zones hostiles.

> **Changement de cap HD-2D (7 octobre 2026).** Les outils d'images de l'utilisateur (ChatGPT) ne produisent que des images et le monde en 3D calculée était trop ambitieux : les modèles 3D (PR n° 1), les décors en formes calculées, l'herbe en MultiMesh et la caméra en orbite libre sont retirés (ils restent dans l'historique, commit `f6ccce9`). L'architecture (monde 3D, personnages en billboards 2D) était déjà celle du HD-2D : le code de jeu, les données, les quêtes, l'interface et les tests sont gardés ; le décor et la caméra sont remplacés. Choix détaillés : `docs/DECISIONS.md`, « HD-2D ».

**Nom de travail** : WordEnd. Dépôt conseillé : `Yume-WordEnd` (séparé de Yume-WordPress et Yume-Trad), licence MIT pour le code, assets sous licence propre (voir section 5).

### Ce que le joueur fait dans la tranche verticale (M2)

1. Il choisit un **skin** : Chtholly par défaut, puis les fées dessinées par la communauté, en planches de sprites.
2. Il explore une **île** vue par une caméra fixe inclinée (HD-2D, le haut de l'écran est le nord) : village sûr au centre, **dunes au couchant** à l'ouest (l'arène de l'easter egg), forêt infestée au nord.
3. Il **combat des Timeres** à l'épée (enchaînement de 3 coups) et à la **charge magique** (onde qui traverse les ennemis), avec 5 PV, recul et invincibilité : les règles de l'easter egg, transposées dans le monde en relief.
4. Il **survit à des vagues** dans l'arène des dunes, avec score et meilleur score, comme aujourd'hui.
5. Il **parle à des PNJ** qui donnent une quête (nettoyer la forêt, rapporter des fragments) et **ramasse des objets**.
6. Sa progression est **sauvegardée** et reprise à la prochaine visite.

### Ce qui rend le jeu évolutif

- Le monde est découpé en **zones** chargées depuis des scènes séparées : ajouter une zone, une arène ou un donjon = ajouter un dossier, sans toucher au reste.
- Ennemis, attaques, vagues, PNJ, objets, dialogues et quêtes sont des **données** (`.tres` et JSON), pas du code : un agent ou un contributeur ajoute un corps de Timere, un ennemi ou une vague sans modifier les systèmes.
- Les skins sont une **liste de ressources** : un nouveau dessin = une entrée de plus, avec les mêmes animations que la planche de Chtholly (repos, marche, course, attaque, charge, dégâts, mort).
- À partir de M4, des contenus se débloquent selon l'actualité de la communauté (parution d'un tome, événement), via l'API REST de WordPress.

### Hors périmètre jusqu'à M4

Multijoueur, génération procédurale, application mobile native, monétisation. Les donjons et les boss arrivent à M3, une fois le combat de base validé. Le mode bureau (section 10) reste possible à tout moment puisque Godot exporte le même projet vers Windows, macOS et Linux.

## 2. Choix techniques

**Godot 4.7.2-stable, GDScript typé, rendu Compatibility, export Web mono-thread.** Ces quatre choix sont liés : ils sont les seuls qui permettent à la fois un build jouable dans une iframe sur n'importe quel hébergement et un projet entièrement lisible et modifiable par des agents sans écran.

| Choix | Décision | Pourquoi |
| --- | --- | --- |
| Moteur | Godot 4.7.2-stable (figé dans `project.godot` et `tools/setup.sh`) | Dernière maintenance de la branche 4.7 ([annonce 4.7.2](https://gamedev.net/news/5172-godot-engine-472-stable-released/)) ; gratuit, MIT, binaire Linux headless de \~60 Mo utilisable dans les VM Claude Code |
| Langage | GDScript avec annotations de type (`var hp: int`, `-> void`) | L'export Web des projets C# reste expérimental en 2026 ([état 2026](https://gtstu.com/?p=4758)) ; GDScript s'exporte proprement et `gdlint`/`gdformat` (PyPI `gdtoolkit`) tournent sans éditeur |
| Rendu | Compatibility (OpenGL 3 / WebGL 2) | Seul renderer disponible à l'export Web ; le flou de profondeur, la lueur et l'étalonnage HD-2D tiennent dans un shader d'écran (`src/player/post_fx.gdshader`) |
| Export Web | Thread Support **désactivé** | Évite les en-têtes COOP/COEP (SharedArrayBuffer) : le build se sert depuis GitHub Pages ou WordPress sans configuration serveur |
| Scènes et ressources | Format texte (`.tscn`, `.tres`), jamais binaire | Diff lisibles, fusion Git possible, agents capables de créer une scène sans éditeur |
| Tests | GUT (Godot Unit Test), vendoré dans `addons/gut/` | S'exécute en ligne de commande : `godot --headless -s addons/gut/gut_cmdln.gd` |
| Build et CI | Image Docker `barichello/godot-ci` (Godot + templates d'export) | Même binaire en CI GitHub Actions et dans la VM Claude Code ([godot-ci](https://hub.docker.com/r/barichello/godot-ci)) |
| Images | PNG de pixel art à 96 px par mètre (`docs/ASSETS_HD2D.md`, `tools/hd2d_manifest.json`) ; personnages en planches au format JSON de l'easter egg | (HD-2D) Les outils de l'utilisateur ne produisent que des images ; un PNG livré remplace le remplaçant du même nom sans toucher au code |

### Pourquoi pas les autres options

- **Python (Ursina, Panda3D)** : pas d'export navigateur, donc pas d'intégration au site.
- **Unity 6** : export Web plus lourd, scènes YAML difficiles à écrire à la main, et l'éditeur reste nécessaire ; le MCP officiel Unity suppose un éditeur ouvert sur ta machine, incompatible avec des sessions cloud.
- **Three.js / Babylon.js** : excellent pour Claude Code mais sans éditeur de niveaux ni système de scènes, ce qui coûte cher sur un monde ouvert.

### Contraintes à connaître dès le départ

- **Pas d'écran dans le cloud** : les agents valident par import headless, tests, export et captures d'écran rendues sous Xvfb (section 6). Un contrôle visuel humain reste nécessaire à chaque jalon.
- **Budget Web** : moins de 150 Mo compressés (wasm + pck), avec un écran de chargement ; relevé de 25 à 60 Mo à M2.5, à 100 Mo avec les images du cahier n° 2, puis à 150 Mo avec celles du cahier n° 3, pour garder toutes les images sans perte de qualité (docs/DECISIONS.md). L'application de bureau n'a pas de budget de taille.
- **Audio Web** : le navigateur exige un geste utilisateur avant tout son, d'où un écran « Cliquer pour jouer ».
- **Sauvegarde Web** : `user://` est persisté dans IndexedDB par Godot ; une sauvegarde est perdue si le joueur vide les données du site, d'où la synchronisation avec le compte WordPress en M4.

## 3. Architecture du projet

Le projet est découpé en **systèmes indépendants reliés par un bus de signaux**, chacun dans son dossier, pour que plusieurs agents travaillent en même temps sans se marcher dessus. Les contrats ci-dessous sont figés au Lot 0 : un agent qui a besoin de les changer ouvre une PR dédiée avant de continuer.

&#91;embedded content: architecture · 4 systèmes de jeu, EventBus, 4 autoloads et UI, fondations\]

Les quatre systèmes de jeu émettent leurs signaux dans `EventBus` ; HUD, `GameState`, `SaveManager` et `WorldManager` les écoutent. Objets, dialogues et scènes appellent aussi l'API de `GameState` (`add_item`, `set_flag`), et `SaveManager` sérialise `GameState` par `to_dict` / `from_dict`. Chaque boîte est un lot qu'une session cloud peut prendre seule. (F1) L'ancienne île (ses zones, son arène et ses vagues, ses quêtes, ses PNJ et ses images) est retirée : docs/DECISIONS.md, section F1.

### Arborescence

```
Yume-WordEnd/
├── project.godot              # autoloads, input map, couches de collision, renderer
├── export_presets.cfg         # preset "Web" (commit, sans secret) ; (bureau) "Windows Desktop" et "Linux"
├── CLAUDE.md                  # règles pour les agents (section 11)
├── PLAN.md                    # ce document, exporté en Markdown
├── .gitignore / .gitattributes
├── gdlintrc                   # (L0) réglages de gdlint (défauts sauf max-public-methods)
├── .claude/settings.json      # hook SessionStart → tools/session_start.sh
├── .github/workflows/ci.yml   # lint + tests + export web + déploiement Pages ; (bureau) installateur, Release sur tag v*
├── addons/gut/                # GUT vendoré
├── docs/
│   ├── DECISIONS.md           # choix faits par les agents quand le plan ne suffit pas
│   ├── bureau.md              # (bureau) application Windows : construire, publier, installer, SmartScreen
│   └── CONTRACT_REQUESTS.md   # besoins de contrat hors périmètre d'un lot
├── tools/
│   ├── setup.sh               # installe Godot + templates (cloud et CI) ; (bureau) Windows, Linux, NSIS, zip
│   ├── fetch_templates.py     # (L0) extrait seulement les templates utiles du .tpz (requêtes Range)
│   ├── build_desktop.sh       # (bureau) export Windows → installateur NSIS + zip portable (build/dist)
│   ├── desktop_boot.sh        # (bureau) build Linux du même pck lancé sans écran (ou Xvfb) : menu, partie, reprise
│   ├── installer/             # (bureau) wordend.nsi, wordend.ico, welcome.bmp, make_installer_art.py (.gdignore)
│   ├── session_start.sh       # reprise de session cloud : LFS, import
│   ├── godot                  # wrapper: binaire natif ou docker ; user:// isolé par worktree (build/xdg)
│   ├── check.sh               # import + gdlint + tests + smoke + export (le "vert" du projet)
│   ├── test.sh                # (L0) tests GUT ciblés (fichier, dossier, test)
│   ├── import.sh              # (L0) import + .uid/.import à commiter + orphelins
│   ├── smoke.gd               # compile src/, tests/, tools/ ; instancie chaque .tscn de src/ et tests/
│   ├── warnings_allow.txt     # avertissements Godot tolérés à l'import
│   ├── screenshot.sh          # rend une scène en PNG sous Xvfb
│   ├── screenshot.gd          # script Godot appelé par screenshot.sh
│   ├── hd2d_shots.sh          # (HD-2D) captures de la vraie partie : menu, cartes de l'île n° 68, conversation,
│   │                          # combat à la surface, (E1) sortie d'essai, fondu, arrivée, retour (cartes)
│   ├── map_bench.gd           # (E1) temps de chargement et mémoire des changements de carte
│   ├── e9_shots.sh            # (E9) captures sous chaque préréglage de lumière (moment × temps), luminance
│   ├── web_atmosphere.js      # (E9) images/s et draw calls de chaque préréglage dans le build Web
│   ├── hd2d_assets.py         # (HD-2D) images de remplacement : gen, check, fit, atlas (Pillow)
│   ├── hd2d_manifest.json     # (HD-2D) liste exacte des images du décor (chemin, taille, genre)
│   ├── hd2d_art.py, hd2d_ground.py, hd2d_props.py, hd2d_sky.py   # recettes de pixel art
│   ├── map_build.py           # (E2) sol en relief des cartes : check, gen (d'après plan.json), view (vue de dessus)
│   ├── carte_plans.py         # (D2) vérifie et dessine les plans ```plan de docs/lore/CARTE.md (check, ascii)
│   └── gen_placeholders.py    # planches de remplacement au format de l'easter egg (Pillow)
├── web/
│   ├── CNAME                  # jeu.yumenovel.fr (copié dans build/web par la CI)
│   └── embed-test.html        # page de test de l'iframe (section 10)
├── src/
│   ├── main.tscn              # racine : menu, chargement, puis game.tscn
│   ├── game.tscn              # (L0) World + Player + UI (HUD, dialogue, inventaire…) ; (F1) sans QuestTracker ;
│   │                          # (E1) World porte la carte courante (avant : Island, l'île entière)
│   ├── autoload/              # EventBus, GameState, SaveManager, SkinRegistry, WorldManager, (bureau) DesktopApp,
│   │                          # (E9) Atmosphere (lumière et temps)
│   ├── desktop_check.gd       # (bureau) vérification du jeu exporté (--desktop-check), sans effet sinon
│   ├── player/                # player.tscn, player.gd (déplacement), camera_rig.tscn (caméra fixe HD-2D),
│   │                          # post_fx.gdshader (flou de profondeur, lueur, étalonnage)
│   ├── combat/                # health.gd, hitbox.tscn, hurtbox.tscn, attack_data.gd,
│   │                          # player_combat.gd (épée, charge), charge_wave.tscn (onde)
│   ├── enemies/               # enemy.tscn, enemy.gd (machine à états), enemy_data.gd, telegraph.gd ;
│   │                          # (F1) l'arène, les vagues et les emplacements de l'ancienne île sont retirés
│   ├── visuals/               # character_visual.tscn (billboard de la planche), sheet_loader.gd, skin_data.gd
│   ├── world/                 # (F1) ground_atlas.gd (atlas du sol, GroundAtlas : l'île, ses zones et son relief
│   │                          # sont retirés) ; (HD-2D) decor_panel.gd, building.gd, prop_batcher.gd, prop_scatter.gd,
│   │                          # props/<nom>.tscn (un décor = un panneau ou un bâtiment), shaders/, materials/
│   │                          # (H9) ground_decal.gd, sky_drift.gd, ambient_sprites.gd (formats du cahier n° 2)
│   │                          # (E1) map.gd, map_exit.gd, maps/<map_id>/<map_id>.tscn (une
│   │                          # carte par lieu ; maps/essai : carte d'essai)
│   │                          # (E2) map_ground.gd (+ _data, _builder, _coast) : sol en relief des cartes
│   │                          # extérieures ; maps/essai_relief : démonstration du relief
│   │                          # (E9) atmosphere_rig.gd (lumière d'une carte, lumière du joueur, pluie),
│   │                          # rain_fall.gd ; materials/hd2d_lighting.gd, hd2d_weather.gd,
│   │                          # hd2d_light_targets.gd ; shaders/sky, rain, rain_curtain (map_light.tscn retiré)
│   │                          # (X1) world_atlas.gd (mondes, îles, règles), island_rules.gd, airship_dock.gd
│   │                          # (quais), travel_view.tscn (vue du ciel d'un voyage) ; maps/quai_essai (l'île
│   │                          # d'essai), maps/surface_essai (la surface)
│   ├── fauna/                 # (E5) animal.tscn + animal.gd (Animal, hérite d'Enemy), animal_data.gd, animal_pack.gd
│   │                          # (meute), fauna_rules.gd, fauna_nav.gd, fauna_populator.gd + fauna.tscn (nœud Fauna)
│   ├── npc/                   # npc.tscn, npc.gd, npc_data.gd, dialogue_runner.gd
│   ├── story/                 # (E6) le récit : story_director.gd (autoload StoryDirector), story_data.gd (format,
│   │                          # vérification), story_runner.gd (étapes), story_stage.gd (places, joueur, voile,
│   │                          # suiveurs), story_dialogue.gd, story_prompt.gd (invites « Dormir »…)
│   ├── life/                  # (E4) la vie : life_director.gd (autoload LifeDirector), life_data.gd (emplois du
│   │                          # temps, activités), life_slots.gd, life_places.gd, life_nav.gd, life_actor.gd,
│   │                          # life_game.gd, life_texts.gd ; games/<jeu>.gd (chat, course, avalanche, tour, ballon)
│   ├── games/                 # (E8) les jeux : ball.gd (GameBall), ball_play.gd + ball_kid.gd (BallPlay, BallKid), staff_training.gd
│   │                          # (StaffTraining), mini_games.gd (MiniGames : lancer un jeu), game_rules.gd, game_score.gd ;
│   │                          # (E8c) ambush.gd ; (E8b) duel.gd, game_vision.gd, seniorious_training.gd,
│   │                          # seniorious_sword.gd, fx/seniorious.png
│   ├── items/                 # item_data.gd (Resource), pickup.tscn
│   └── ui/                    # hud, dialogue_box, inventory, main_menu, loading, touch_controls,
│                              # credits, (E1) map_fade, (E6) calendar ; (F1) arena_end et journal retirés
├── data/
│   ├── attacks/*.tres         # sword_1..3, charge_wave, bite, whip, rush ; (E8) stick_1..3, stick_guard (le bâton)
│   ├── games/*.json           # (E8) les chiffres des jeux : ballon.json, staff_training.json (GameRules) ; embuscade.json, (E8b) duel.json, seniorious.json
│   ├── enemies/*.tres         # timere_small, timere_normal, timere_runner, timere_big ; visuals/timere.tres
│   ├── fauna/<île>/           # (E5) une espèce par fichier <id>.tres (AnimalData), attacks/, visuals/<id>.tres,
│   │                          # peuplement.json (où, combien, quand) ; format : « (E5) Ajouter un animal »
│   ├── items/*.tres           # (F1) vide : les objets de l'ancienne île sont retirés
│   ├── npcs/*.tres            # (E4) + outfits/<planche>.tres (tenues, SkinData), generic/<id>.tres (fées génériques)
│   ├── life/*.json            # (E4) emplois du temps data/life/<npc_id>.json, activities.json
│   ├── scenes/<île>/          # (E6) act.json (l'acte en jours) et une scène par fichier ; textes des scènes :
│   │                          # dialogues/<île>/ (et talk/<pnj>.json), texts/<île>/story.json
│   ├── skins/*.tres
│   ├── dialogues/<île>/       # conversations (format : docs/DIALOGUES.md) ; (F1) celles de l'ancienne île retirées
│   ├── maps/<map_id>/         # (E2) sol en relief d'une carte : map.json, heights.png, materials.png,
│   │                          # structures.png, plan.json ; maps/ground_materials.json (matières, structures)
│   ├── world/                 # (X1) worlds/<world_id>.json (regule_aire, surface : îles, règles communes),
│   │                          # islands/<island_id>.json (cartes, lieux, ports, règles) ; contenu propre à une
│   │                          # île : data/<kind>/<island_id>/ (life, texts, fauna, scenes : WorldAtlas.data_path)
│   ├── texts/story.json       # (Systèmes et textes) textes de l'histoire hors dialogues :
│   │                          # chute, défaite, (F1) save/migrated (DialogueRunner.story_text) ; (E4) texts/life.json
│   └── lighting/*.tres        # (E9) préréglages de lumière : aube, matin, apres_midi, couchant, nuit,
│                              # interieur, interieur_nuit (HD2DLighting) ; pluie, averse (HD2DWeather)
├── assets/
│   ├── CREDITS.md             # assets tiers (URL, licence)
│   ├── characters/CREDITS.md  # dessins des membres (auteur, accord)
│   ├── characters/<skin_id>/  # planche PNG + .json (format de l'easter egg)
│   ├── enemies/<enemy_id>/    # idem pour les Timeres
│   ├── fauna/<animal_id>/     # (E5) planches de remplacement des animaux (tools/gen_fauna.py), idem
│   ├── hd2d/                  # (HD-2D) ground/ (+ atlas/), cliff/, buildings/ (+ materials/), props/, sky/, fx/
│   ├── items/, ui/            # icônes 64 × 64, interface
│   └── audio/
├── tests/
│   ├── stubs/                 # joueur factice, visuel factice, mannequins pour les tests
│   ├── unit/                  # test_*.gd (GUT)
│   └── integration/           # scènes de fumée et démos par lot (demo_l<N>.tscn), (HD-2D) demo_hd2d.tscn
│                              # (H9) demo_formats.tscn : chaque format du cahier n° 2, images faites à l'exécution
└── build/                     # ignoré par git
```

### Autoloads (singletons)

| Autoload | Rôle | Propriétaire (lot) |
| --- | --- | --- |
| `EventBus` | Tous les signaux transverses ; aucune logique | L0 |
| `GameState` | PV max, inventaire, drapeaux (`flags`), skin actif ; (E1) carte et position ; (E9) moment et temps ; (X1) île courante et îles connues ; (E4, E6) jour, créneau, scènes jouées, calendrier ; sérialisable en Dictionary ; (F1) quêtes, scores et zone retirés | L7 |
| `SaveManager` | Écrit/lit `user://save_v1.json` (nom historique ; (F1) schéma v4), versionne le schéma ; une partie de l'ancienne île devient une nouvelle partie de l'acte 1 | L8 |
| `SkinRegistry` | Charge `data/skins/*.tres`, expose la liste et le skin par défaut (Chtholly) | L3 |
| `WorldManager` | Points d'apparition et réapparition après la mort ; (E1) une carte à la fois : changement de carte (fondu, chargement découpé, marqueur d'arrivée), carte courante, bornes de la caméra ; (X1) île courante (`island_entered`), voyage entre îles (`travel` : vue du ciel, port d'arrivée), chute au dernier point sûr | L2, E1, X1 |
| `DesktopApp` | (bureau) Application de bureau, sans effet sur le Web : fenêtre de départ, plein écran (F11, Alt+Entrée, bouton) mémorisé dans `user://settings.cfg`, boutons « Plein écran » et « Quitter » des menus, sauvegarde avant de quitter (docs/bureau.md) | bureau |
| `LifeDirector` | (E4) La vie : emplois du temps (`data/life/`) appliqués à la carte courante (PNJ posés dans `Life`, trajets à chaque changement de créneau, sorties vers les autres cartes), navigation, jeux de groupe, réactions au joueur ; créneaux (`set_slot`, F6, `?creneau=`) ; mesures (`?vie=trace`) | E4 |
| `StoryDirector` | (E6) Le récit : l'acte en jours et ses scènes (`data/scenes/<île>/`), jouées par `StoryRunner` ; le jour et le créneau (dormir, laisser passer le temps), l'indice discret, le calendrier, les séquences déjà vues, le crochet des jeux (E8). Mode d'emploi : « (E6) Le récit » | E6 |
| `Atmosphere` | (E9) La lumière et le temps : préréglage effectif de la carte courante (`light_preset`, intérieur ou moment de la journée, modifié par le temps qu'il fait), transitions douces, pose (environnement, ciel, soleil ou lune, mer de nuages, lanternes, lueurs, images de nuit, sol mouillé, post-traitement ; (R1) lumière des intérieurs, soleil du sol en relief, teinte des personnages), lumière magique du joueur, pluie ; raccourcis `?moment=` / `?temps=`, F7 / F8 ; le moment et le temps eux-mêmes sont dans `GameState` (sauvegardés) | E9 |

### Contrats d'interface

```gdscript
# src/autoload/event_bus.gd — signaux (émis par le système source, écoutés partout).
# (L0) = ajouté ou précisé au Lot 0 ; l'émetteur de chaque signal est aussi documenté dans le fichier.
# Combat
signal player_health_changed(current: int, max_value: int)   # PlayerCombat ; 1re émission différée après _ready (valeur initiale du HUD)
signal player_damaged(amount: int, source: Node3D)            # PlayerCombat
signal player_died()                                          # PlayerCombat ; WorldManager appelle respawn() respawn_delay s plus tard
signal player_respawned()                                     # WorldManager.respawn() ; PlayerCombat remet alors les PV au maximum
signal player_heal_requested(amount: int)                     # (L0) n'importe qui → PlayerCombat ((F1) émis par le WaveDirector, retiré)
signal enemy_spawned(enemy: Node3D, enemy_id: StringName)     # Enemy, dans son _ready
signal enemy_damaged(enemy: Node3D, amount: int)              # Enemy
signal enemy_killed(enemy_id: StringName, points: int)        # Enemy
# (F1) wave_started, wave_cleared, arena_score_changed, arena_finished : retirés avec l'arène
signal charge_progress(ratio: float)        # 0..1, jauge de la charge magique (PlayerCombat)
# Monde et interaction
signal item_collected(item_id: StringName, quantity: int)    # Pickup, après GameState.add_item
signal inventory_changed()                                    # GameState (add_item, remove_item, from_dict, reset)
signal interaction_available(prompt: String)   # "" = aucune ; émis par le joueur
signal dialogue_started(npc_id: StringName)                   # DialogueRunner (le joueur s'arrête)
signal dialogue_line(speaker: String, text: String, choices: Array[String])   # DialogueRunner
signal dialogue_choice_made(index: int)       # (L0) DialogueBox → DialogueRunner actif ; -1 = « suite » sans choix
signal dialogue_ended(npc_id: StringName)                     # DialogueRunner (le joueur repart)
# (F1) quest_updated et zone_entered : retirés avec les quêtes et les zones de l'ancienne île
signal day_phase_changed(phase: StringName)   # morning|day|evening|night (M3) ; (E9) ancien nom : Atmosphere le traduit
                                              # en moment (matin, apres_midi, couchant, nuit : HD2DLighting.PHASE_MOMENTS)
signal skin_changed(skin_id: StringName)                      # GameState, quand skin_id change ; le joueur l'applique
signal max_hp_changed(max_value: int)          # (L0) GameState, quand max_hp change → PlayerCombat
signal save_requested()                                       # n'importe qui → SaveManager.save()
signal game_loaded()                                          # SaveManager (new_game, load_game, import_json) → main.gd
# (Lot Q) Drapeaux — format des dialogues : docs/DIALOGUES.md
signal flag_changed(flag: StringName, value: bool)            # GameState.set_flag, si la valeur change
# (F1) quest_step_updated, quest_step_completed, quest_advance_requested, trigger_entered,
# tracked_quest_changed : retirés avec le moteur de quêtes
# (E1) Cartes — docs/REFONTE.md, section 7.1
signal map_entered(map_id: StringName)        # WorldManager (go_to, enter_map) : carte posée, joueur placé (sous le
                                              # noir pendant un go_to) → caméra (bornes, recalage), joueur (élan), SaveManager
                                              # (E9) → Atmosphere : lumière de la carte posée tout de suite
# (X1) Îles et surface — data/world/, PLAN.md « (X1) Ajouter une île »
signal island_entered(island_id: StringName)  # WorldManager, juste après le map_entered d'une carte d'une autre île
                                              # (voyage, sortie, début de partie), GameState.island et îles connues à
                                              # jour ; jamais pour une carte hors de toute île
# (E9) Lumière et temps
signal atmosphere_changed(moment: StringName, weather: StringName)   # GameState, quand moment ou weather change
                                              # (setters, from_dict, reset) → Atmosphere (transition douce)

# src/combat/health.gd — composant commun joueur / ennemis (class_name Health, extends Node)
@export var max_hp: int = 1
@export var invincibility_time: float = 0.0   # 1,2 s sur le joueur seulement ; 0 sur les ennemis (comme jeu.js)
var current: int                              # (L0) PV courants (pleins à la création)
signal changed(current: int, max_value: int)
signal damaged(amount: int, source: Node3D)   # (L0) émis avant changed
signal died()
func take_damage(amount: int, source: Node3D) -> bool   # false si invincible, mort ou amount <= 0
func heal(amount: int) -> void                          # sans effet sur un mort
func reset() -> void                                    # (L0) PV pleins, plus d'invincibilité
func is_dead() -> bool                                  # (L0)
func is_invincible() -> bool                            # (L0) ; invincibility_left() -> float

# src/combat/hitbox.tscn (Area3D, couche "hitbox", masque "hurtbox") et hurtbox.tscn (Area3D, couche "hurtbox")
# Une Hitbox porte un AttackData ; elle est activée par CharacterVisual.frame_changed sur les
# images "coup" de l'animation de l'attaque (lues dans le JSON de la planche, qui fait foi).
# Règle : une Hitbox ne touche chaque Hurtbox qu'une fois par activation (liste des touchés, comme jeu.js).
# Le contact hitbox → hurtbox appelle Health.take_damage et applique le recul (knockback).
class_name Hitbox  : @export attack: AttackData, @export team: StringName, var source: Node3D   # (L0)
                     func activate() -> void, deactivate() -> void, is_active() -> bool ; signal hit_landed(hurtbox: Hurtbox)
class_name Hurtbox : @export health: Health, @export team: StringName                          # (L0)
                     func receive_hit(attack: AttackData, source: Node3D) -> bool ; signal hit_taken(attack: AttackData, source: Node3D)
# (L0) Équipes &"player" / &"enemy" : une Hitbox ne touche pas une Hurtbox de son équipe. Le recul est
# appliqué par le script du corps (player.gd, enemy.gd) sur hit_taken : attack.knockback m/s dans la
# direction source → corps ; un ennemi stoic l'ignore sauf si attack.pierces.
class_name AttackData : id, animation: StringName, damage: int, knockback: float, pierces: bool, range_m: float, cooldown: float,
                        arc_deg: float, width_m: float, charge_time: float, duration: float, speed: float   # (L0) 5 derniers champs

# src/combat/player_combat.gd — enfant "Combat" de player.tscn (class_name PlayerCombat, extends Node3D)
func attack() -> void                      # enchaînement sword_1 → sword_2 → sword_3 si la touche est répétée
func charge_begin() -> void                # démarre la jauge (0,55 s minimum)
func charge_release() -> void              # lance l'onde si la jauge est pleine, recharge 1,2 s
func is_busy() -> bool                     # true pendant attaque/charge/dégâts (bloque le déplacement)
# (E8) L'arme : set_weapon(&"baton" | &"seniorious") -> bool (le récit choisit ; Seniorious par défaut), weapon(),
# can_charge() (faux bâton en main : pas de charge de venenum), is_guarding() / guard_animation() (bâton en main,
# la touche de charge tient la parade), signaux weapon_changed(arme), guard_changed(levée). Player.set_weapon /
# weapon() les relaient ; Player.hold_pose(anim, s, remplaçantes) / is_posing() tiennent une pose (essoufflée).
# (L0) Relais à conserver : Health du joueur → player_health_changed / player_damaged / player_died ;
# player_respawned → Health.reset() ; player_heal_requested → Health.heal() ; max_hp_changed → Health.max_hp ;
# au départ Health.max_hp = GameState.max_hp. Voisins par nom (../Health, ../Visual, ../Hurtbox, SwordHitbox),
# données par chemin (data/attacks/*.tres).

# src/enemies/enemy.gd — machine à états commune (class_name Enemy, extends CharacterBody3D, @export var data: EnemyData)
# états : idle → chase → attack → hurt → dead ; rush pour le coureur ; stoic = pas de recul sauf onde
class_name EnemyData : id, display_name, visual: SkinData, scale: float, max_hp: int, speed: float,
                       points: int, attacks: Array[AttackData], rush: bool, stoic: bool,
                       aggro_range_m: float, drops: Dictionary[StringName, float]   # item_id → probabilité

# (X1) Enemy._ready : un Timere que les règles de l'île de sa carte n'admettent pas (WorldAtlas.enemies_allowed_at :
# l'île n° 68) se retire aussitôt, sans enemy_spawned. (F1) FreeEnemies est retiré.
# (E5) La faune — src/fauna/, data/fauna/<île>/ ; mode d'emploi : « (E5) Ajouter un animal »
class_name AnimalData extends EnemyData   # une espèce : data/fauna/<île>/<id>.tres (+ attacks/, visuals/)
   behavior: StringName    # &"paisible" | &"fuyard" | &"dangereux" | &"ambiant" (AnimalData.BEHAVIORS)
   flies, body_radius_m, moments: Array[StringName]                      # espèce
   alert_range_m, flee_range_m, calm_distance_m, flee_speed, graze_animation, graze_ratio,
   flee_animation, startle_animation, startle_s, vanish_s                # paisibles et fuyards
   noise_run_factor, noise_still_factor, run_speed_m_s, combat_noise_m   # réactions (bruit, combat)
   leash_m, wander_radius_m, windup_animation, stun_s, ring_radius_m, ring_speed, attack_gap_s   # dangereux
   defeat_flee_s, defeat_flee_m                                          # fuite du vaincu
   ambient_texture, ambient_frames, ambient_fps, ambient_motion, ambient_count, ambient_speed,
   ambient_sway, ambient_lift, ambient_region_m, ambient_weather         # behavior ambiant : AmbientSprites
   func active_at(moment) -> bool ; has_body() ; is_dangerous() ; calm_distance() ; escape_speed()
class_name Animal extends Enemy           # src/fauna/animal.tscn (enemy.tscn + animal.gd) ; data: AnimalData
   signal fled(animal: Animal)             # vaincu ou débandé : il s'enfuit (jamais EventBus.enemy_killed)
   var pack: AnimalPack
   func species() -> AnimalData ; mode_name() -> StringName   # &"graze", &"alert", &"flee", &"leave"
   func is_leaving() -> bool ; is_stunned() -> bool ; is_flying() -> bool
   func dismiss() -> void                  # renvoyé (hors de saison) : il s'éloigne et disparaît
   func rout(from: Node3D) -> void         # débandade de la meute
# Groupes : tout animal est dans « fauna » ; un dangereux est aussi dans « enemies » (verrouillage, HUD).
# (E5) Enemy._is_admitted() : la garde d'Enemy._ready ; Enemy demande enemies_allowed (Timere), Animal
# redéfinit la question (FaunaRules.allowed_at : liste fauna de l'île, régions sans animaux) : la garde
# des Timeres (X1) ne retire donc jamais un animal, et la faune ne passe pas outre les règles de l'île.
class_name AnimalPack extends RefCounted  # meute : add(animal), active(), request_attack(animal) (un seul
   # porteur du jeton à la fois), release(animal), ring_point(animal, centre, rayon, vitesse) (encerclement),
   # report_fled(animal) (la moitié partie : le reste suit), raise_alert() / is_alert()
class_name FaunaRules extends RefCounted  # fonctions statiques : species(île, id), species_ids(île),
   # island_allows(carte, espèce), is_banned(carte, région), allowed_at(nœud, espèce), population(île),
   # entries_for(carte), entry_wanted(groupe, espèce, moment, temps), entry_problem(groupe),
   # problems(île) -> PackedStringArray (tout le format), set_population(île, données) (tests), clear_cache()
class_name FaunaNav extends RefCounted    # praticabilité du sol : ground_of(nœud), can_stand(sol, point),
   # can_step(sol, de, à) (MapGround.is_walkable, level_at : un cran de palier au plus), steer(sol, de, but),
   # random_spot(sol, centre, rayon, rng), on_ground(sol, point)
class_name FaunaPopulator extends Node3D  # le nœud « Fauna » (src/fauna/fauna.tscn) sous « Life » d'une carte
   signal group_filled(group_id, count)
   func animals(group_id := &"") -> Array[Animal] ; group_ids() ; ambient_of(group_id) ; is_wanted(group_id)
   func refresh(fill_all := false) -> void  # EventBus.atmosphere_changed (moment, temps) l'appelle seul

# (F1) src/enemies/wave_director.gd (WaveDirector) et arena.gd (Arena) : retirés avec l'ancienne île ; les
# Timeres restent possibles là où les règles de l'île les admettent (la surface : enemies_allowed).

# src/autoload/game_state.gd — API publique
func add_item(item_id: StringName, quantity: int = 1) -> void
func remove_item(item_id: StringName, quantity: int = 1) -> bool
func count(item_id: StringName) -> int
func items() -> Dictionary                                       # (L0) copie item_id → quantité, pour l'UI
func set_flag(flag: StringName, value: bool = true) -> void
func has_flag(flag: StringName) -> bool
func mark_pickup_collected(pickup_id: StringName) -> void        # (L0)
func is_pickup_collected(pickup_id: StringName) -> bool          # (L0)
func reset() -> void                                             # (L0) nouvelle partie
func to_dict() -> Dictionary                # (L0) exactement les champs du schéma de sauvegarde, sauf version et saved_at
func from_dict(data: Dictionary) -> void     # n'émet pas flag_changed (inventory_changed, oui) ; ignore les champs inconnus
# (F1) quest_state, set_quest_state, quests, quest_step, quest_step_count, set_quest_step, quest_progress,
# record_score, best_score, arena_record, tracked_quest et zone : retirés avec l'ancienne île
var skin_id: StringName      # (L0) &"" = skin par défaut ; émet skin_changed
var max_hp: int              # (L0) 5, puis 6 (acte 1 : la promesse du gâteau au beurre), 7 (registre des veilles) ; émet max_hp_changed
var map: StringName          # (E1) carte courante, tenue par WorldManager ; &"" = nouvelle partie pas encore placée
var position: Vector3        # (L0) tenue par le joueur quand il est au sol ; (E1) dans le repère de la carte
var moment: StringName       # (E9) moment de la journée, un de MOMENTS (aube, matin, apres_midi, couchant, nuit ; défaut
                             # DEFAULT_MOMENT = couchant) ; une autre valeur est refusée (avertissement) ; émet atmosphere_changed
var weather: StringName      # (E9) temps qu'il fait, un de WEATHERS (clair, pluie, averse ; défaut DEFAULT_WEATHER = clair)
                             # ; émet atmosphere_changed ; moment et weather sont écrits par to_dict (après collected_pickups)
var island: StringName       # (X1) île courante (WorldAtlas.island_of(map)), tenue par WorldManager ; &"" : pas placée
func known_islands() -> Array[StringName] / func knows_island(id) -> bool / func discover_island(id) -> bool
                             # (X1) îles où le joueur est allé (ordre de découverte) ; discover : vrai si nouvelle
                             # ; island et known_islands sont écrits par to_dict après weather
var day: int                 # (E4) jour de l'acte (ACTE1.md : 1 à 12), tenu par le récit (E6) ; 0 (défaut) : aucun, les
                             # lignes d'emploi du temps à « day » ne s'appliquent pas ; sauvegardé (facultatif, absent : 0)
var slot: StringName         # (E4) créneau de la vie (SLOTS : aube, matin, midi, apres_midi, soir, nuit) ; &"" : celui du
                             # moment (LifeSlots.default_for) ; posé par LifeDirector.set_slot ; sauvegardé (facultatif)
func story_running() -> bool # (E6) day ≥ 1 : l'acte en jours
func is_scene_done(id) / mark_scene_done(id) / forget_scene(id) / scenes_done() -> Array[StringName]   # (E6)
func write_calendar(day, line := &"") / has_calendar_line(day) / calendar() -> Dictionary[int, StringName]   # (E6)
var story_scene: StringName  # (E6) scène en cours (rejouée depuis son début à la reprise) ; scenes_done, calendar et
                             # story_scene : champs facultatifs du schéma v4 (absents : vides)

# src/autoload/save_manager.gd
func has_save() -> bool
func save() -> Error
func load_game() -> Error                 # remplit GameState, émet game_loaded
func new_game(skin_id: StringName) -> void   # (L0) GameState.reset() puis émet game_loaded
func export_json() -> String / func import_json(text: String) -> Error   # menu, section 13 ; import émet game_loaded
var save_path: String = "user://save_v1.json"   # (L0) les tests en utilisent un autre ; (Lot Q) le nom ne suit pas la version
const SAVE_VERSION := 4                   # (F1) v4 : sans zone, quests, quest_progress, tracked_quest ni best_scores.
                                          # Une partie de l'ancienne île (v0 à v2, ou v3 hors de l'acte : day absent ou 0)
                                          # ne se reprend pas : load_game() la copie dans legacy_backup_path() (.ancienne),
                                          # démarre une nouvelle partie de l'acte 1 avec son skin (started_new) et pose
                                          # notice (story.json, save/migrated), que le menu affiche ; renvoie OK. Une v3 de
                                          # l'acte passe en v4 sans perte (champs de l'ancienne île retirés).
                                          # (E9) moment, weather ; (X1) island, known_islands : champs facultatifs
var notice: String                        # (F1) avis du chargement ("" : rien à dire)
func legacy_backup_path() -> String       # (F1) save_path + ".ancienne"
func save_on_leave() -> Error             # (M2) focus perdu, fermeture, page masquée : écriture en attente, sinon état s'il a changé
func has_unsaved_changes(tolerance: float = 0.05) -> bool   # (M2) GameState diffère de la dernière écriture (position : au-delà de tolerance m)
var checkpoint_interval: float = 5.0      # (M2) position écrite toutes les 5 s de jeu si le joueur a bougé de checkpoint_distance (1 m)

# src/autoload/skin_registry.gd
func all() -> Array[SkinData]
func get_skin(skin_id: StringName) -> SkinData
func default_skin() -> SkinData

# src/autoload/world_manager.gd
func respawn() -> void                    # au marqueur d'arrivée de la carte, PV pleins, émet player_respawned
var respawn_delay: float = 2.2            # (L0) délai entre player_died et respawn()
signal rescued(map_id: StringName)        # (Systèmes et textes) rescue() a rattrapé le joueur (dernier point sûr ou
                                          # marqueur d'arrivée) → HUD : fondu au blanc et « Tes ailes se sont ouvertes… »
# (F1) load_zone, teleport, current_zone, zone_display_name, is_zone_safe, LEGACY_MAP : retirés avec les zones
# (E1) Cartes (docs/REFONTE.md, section 7.1) : une seule carte chargée, enfant unique de game.tscn « World »
func go_to(map_id: StringName, marker: StringName = &"Spawn") -> void   # coroutine : fondu au noir (fade_time), chargement
                                          # découpé (load_budget_ms par image), ancienne carte libérée, nouvelle ajoutée,
                                          # joueur posé au sol sous le marqueur (Spawn s'il manque), tourné comme son −Z,
                                          # map_entered, fondu de retour ; joueur figé (process_mode DISABLED) tout du long ;
                                          # ignoré (avertissement) pendant un autre changement, erreur pour une carte inconnue
func enter_map(map_id: StringName, marker: StringName = &"Spawn", at: Variant = null) -> bool   # sans fondu, d'un bloc
                                          # (début de partie, démonstrations) ; at : Vector3 (position sauvegardée)
func current_map() -> StringName / func current_map_node() -> Map   # carte posée (à défaut, 1re carte de l'arbre)
func starting_map() -> StringName         # GameState.map si elle existe, sinon START_MAP (main.gd, game.gd)
func map_display_name(map_id: StringName) -> String   # Map.display_name, sans instancier la carte
func camera_bounds() -> Rect2             # Map.bounds() de la carte courante ; DEFAULT_CAMERA_BOUNDS sans carte
func is_transitioning() -> bool           # fondus, chargement, et SETTLE_FRAMES (3) images physiques après l'arrivée
func fade_alpha() -> float                # opacité du noir (0..1), dessinée par UI/MapFade
func last_transition() -> Dictionary      # mesures du dernier go_to : fade_out_ms, load_ms, load_frames, install_ms, total_ms
var fade_time: float = 0.35 / var load_budget_ms: float = 100.0   # sous le noir, le monde 3D n'est pas dessiné
signal transition_started(map_id: StringName) / signal transition_finished(map_id: StringName)
const START_MAP := &"entrepot"            # (E6) une nouvelle partie ouvre l'acte 1 à l'entrepôt de l'île n° 68
                                          # (arrival_map de ile_68.json)
var start_map: StringName = START_MAP     # (E6) carte d'une nouvelle partie (les tests en prennent une autre) ;
                                          # starting_map() : GameState.map si elle existe, sinon start_map
# (X1) Îles (data/world/, WorldAtlas) : chaque carte posée donne l'île courante (island_entered si elle change)
func travel(island_id: StringName, port: StringName = &"") -> void   # coroutine : comme go_to, mais sous le noir la vue
                                          # du ciel (src/world/travel_view.tscn, au moins travel_time s ; la carte
                                          # se charge pendant ce temps par tranches de travel_load_budget_ms), puis
                                          # WorldAtlas.arrival(île, port) : le port nommé, sinon le premier, sinon
                                          # arrival_map au Spawn ; île ou port inconnus : erreur ; pendant un autre
                                          # changement : ignoré (avertissement)
func current_island() -> StringName / func is_traveling() -> bool / func travel_view() -> TravelView
func next_island() -> StringName          # île suivante de l'atlas, touche F6 en version de débogage
func last_safe_point() -> Vector3         # dernier point sûr (Vector3.INF sans) : au sol, à plus de SAFE_MARGIN (1,5 m)
                                          # du vide ; rescue() y ramène si la règle void_fall
                                          # de l'île est last_safe (sinon : marqueur d'arrivée)
var travel_time: float = 3.2 / var travel_load_budget_ms: float = 12.0 / var debug_keys: bool
signal travel_started(island_id: StringName) / signal travel_finished(island_id: StringName)
# last_transition() a aussi « island » (l'île du voyage, &"" pour un go_to).

# (bureau) src/autoload/desktop_app.gd — tout est sans effet sur le Web (OS.has_feature("web"))
func is_web() -> bool / func is_desktop() -> bool   # vraie plateforme, ou simulated_web (tests : 0 bureau, 1 Web)
func is_fullscreen() -> bool / func set_fullscreen(enabled: bool) -> void / func toggle_fullscreen() -> void
                                          # choix écrit dans user://settings.cfg (SETTINGS_PATH), rétabli au lancement
func setup_menu_buttons(fullscreen_button: Button, quit_button: Button, quit_text: String) -> void
                                          # boutons montrés et branchés sur le bureau, cachés sur le Web
func text(key: String) -> String          # data/texts/story.json, section « desktop »
func quit_game() -> void                  # SaveManager.save() si une partie est suivie, close_game(), puis quit()
signal fullscreen_changed(enabled: bool) / signal quit_requested

# (E9) src/autoload/atmosphere.gd — la lumière et le temps (docs/REFONTE.md, lot E9). Le moment et le temps sont dans
# GameState (sauvegardés) ; Atmosphere en fait la lumière de la carte courante (WorldManager.current_map_node()).
func set_moment(moment_id: StringName, duration: float = -1.0) -> void   # GameState.MOMENTS ; duration < 0 :
                                          # transition_time (4 s), 0 : tout de suite ; sans effet s'il est déjà celui-là
func set_weather(weather_id: StringName, duration: float = -1.0) -> void # GameState.WEATHERS (clair, pluie, averse)
func set_atmosphere(moment_id, weather_id, duration = -1.0) -> void      # les deux, une seule transition
func moment() -> StringName / func weather() -> StringName              # ceux de GameState
func preset_id() -> StringName            # préréglage effectif : Map.light_preset s'il est rempli (un moment,
                                          # « interieur » ou tout data/lighting/<id>), sinon « interieur » pour une
                                          # carte intérieure (Map.interior), sinon (X1) le ciel par défaut de son île
                                          # (règle sky, WorldAtlas.rules_for), sinon le moment
func resolve(map: Node = null, moment_id := &"", weather_id := &"") -> HD2DLighting   # réglage effectif (nouveau) :
                                          # préréglage, « interieur » = interieur mêlé à interieur_nuit selon la nuit
                                          # du dehors (interior_for ; (R1) le jour des fenêtres, window_light et
                                          # window_tint, est celui du moment du dehors), puis le temps
                                          # (HD2DWeather.applied_to ; dedans : seulement la lumière des fenêtres, ni
                                          # pluie ni sol mouillé)
func current() -> HD2DLighting            # réglage posé (copie ; mélange en cours pendant une transition)
func is_transitioning() -> bool / func transition_progress() -> float / func step(delta: float) -> void (tests)
func dress(map: Node3D) -> void / func snap() -> void   # habille une carte (AtmosphereRig, relevé) et pose tout de
                                          # suite ; fait à map_entered (sous le noir), et à l'image suivante pour une
                                          # carte ajoutée à la main (démonstration, capture) ; game_loaded : tout de suite
                                          # (R1) la pose (et chaque image d'une transition) règle aussi les intérieurs
                                          # (InteriorRoom.apply_lighting), le soleil du sol en relief (MapGround.set_sun)
                                          # et la teinte des personnages (HD2DLighting.active_sprite_tint)
func player_light_amount() -> float / func is_player_light_on() -> bool   # lumière magique du joueur (la nuit dehors)
var player_light_mode: StringName         # LIGHT_AUTO (préréglage), LIGHT_ON, LIGHT_OFF (une scène : Willem sans lumière)
func is_raining() -> bool / func sprite_tint() -> Color / func rig() -> AtmosphereRig / func targets() -> HD2DLightTargets
                                          # (R1) sprite_tint : celle que CharacterVisual pose ; blanche et current() null
                                          # sans carte (menu) ; static interior_for(dehors) : « interieur » sous un moment
var transition_time: float = 4.0 / var debug_keys: bool / var dev_parameters: Dictionary
signal preset_applied(preset_id: StringName)   # préréglage posé en entier (fin de transition, arrivée, chargement)
# Raccourcis : ?moment=nuit&temps=pluie (Web) ou -- --moment=nuit --temps=pluie, posés à chaque partie chargée ;
# F7 moment suivant, F8 temps suivant (Maj : tout de suite), en version de débogage ou avec l'un de ces paramètres.

# Interactable — tout nœud du groupe "interactable" implémente :
func get_prompt() -> String            # "Parler", "Ramasser"
func interact(player: Node3D) -> void
# (L0) Détection : le joueur masque les couches 6 (interactable) et 7 (pickup) ; l'interactable est le
# premier nœud du groupe "interactable" en remontant depuis l'objet détecté (lui compris).

# src/visuals/character_visual.gd — planche en billboard axe Y (class_name CharacterVisual, extends Node3D) ;
# (HD-2D) la variante « mesh » est retirée : un personnage est toujours une planche
func set_skin(skin: SkinData) -> void
func play(anim: StringName, restart: bool = false) -> void    # repos|marche|course|attaque|charge|degats|mort (+ fouet|morsure) ; (L0) restart
func set_facing(direction: Vector3) -> void
func hit_frames(anim: StringName) -> Array[int]   # le "coup" du JSON de la planche
func wave_frame(anim: StringName) -> int          # (L0) l'"onde" du JSON, -1 si absente
func show_frame(anim: StringName, frame: int) -> void   # (L0) fige une image (charge maintenue)
func has_animation(anim: StringName) -> bool      # (L0) ; current_animation() -> StringName
# (R1) La planche, non éclairée, prend la teinte de la lumière : Sprite.modulate = couleur posée par d'autres
# (EnemyData.tint) × HD2DLighting.active_sprite_tint() (Atmosphere : la nuit, plus sombre ; blanche au couchant et
# sans carte), à chaque advance(), dehors comme dedans
signal frame_changed(anim: StringName, frame: int)   # permet à la Hitbox de s'activer sur les images "coup"
signal animation_finished(anim: StringName)

# data/*.tres — ressources
class_name ItemData   : id, display_name, icon, stackable, max_stack, description
class_name SkinData   : id, display_name, sprite_sheet, frames_json: JSON, portrait, height_m   # (HD-2D) sans mesh_scene
                        # (E4) extra_sheet / extra_json (+ extra_front_*, extra_back_*) : planche complémentaire
                        # `<id>_life`, fusionnée par SheetLoader (ses animations absentes de la planche principale)
class_name NpcData    : id, display_name, skin, dialogue_path   # (F1) quest_id et home_zone retirés
                        # (Systèmes et textes) visible_if: Dictionary (présence, même grammaire que les « if »
                        # de dialogue) ; is_present() (faux aussi si skin = celui du joueur), is_player_skin(),
                        # visible_if_problem()
                        # (E4) outfits: Dictionary[StringName, String] (tenue → chemin d'une SkinData de
                        # data/npcs/outfits/, chargée à la demande) ; outfit_path(), has_outfit(), load_outfit()
# (F1) QuestData et QuestStep : retirées avec le moteur de quêtes.

# (L0) Autres classes partagées
# (F1) Zone (racine d'une zone de l'ancienne île) : retirée.
class_name Map             # (E1) src/world/map.gd, racine d'une carte (Node3D, groupe "maps") : @export display_name: String,
                           # region: StringName, interior: bool, size: Vector2, camera_bounds: Rect2 (Rect2() : la carte ;
                           # (QO) plat ou réduit à un point : une ligne, une caméra fixe),
                           # light_preset: StringName, (X1) island: StringName (&"ile_68" ; celle dont le fichier de
                           # l'île nomme la carte) ; map_id(), area() (Rect2(0, 0, size) ; île héritée : centrée),
                           # bounds(), marker(name), spawn(), marker_names(), exits() ; statiques scene_path(id), exists(id),
                           # is_valid_id(id), all_ids(), problems(carte), exit_problems(carte, marqueurs) ; MAPS_DIR,
                           # REQUIRED_CHILDREN (Ground, Geometry, Markers, Exits, Life), SPAWN_MARKER, FROM_PREFIX ("from_")
class_name MapExit         # (E1) src/world/map_exit.gd, Area3D enfant de « Exits » : @export target_map: StringName,
                           # target_marker: StringName (&"Spawn"), prompt: String ; vide : on passe en marchant (couche 0,
                           # masque 2) ; rempli : interactable (couche 6, groupe "interactable", get_prompt(), interact())
                           # posé par son _ready ; needs_interaction(), use() (sans effet si WorldManager.is_transitioning())
class_name ShipControl     # (E7) src/world/ships/ship_control.gd, statique : les navires pour le récit (descend,
                           # open_hatch, deploy_gangway, depart, pass_shadow…), état dans les drapeaux ship_<id>_* de
                           # GameState ; Ship (le navire en volume), ShipBerth (poste d'amarrage d'une carte, groupe
                           # "ship_berths"), ShipStrip, ShipShadow. Mode d'emploi : « (E7) Les navires » (plus bas)
# (X1) Îles et surface (data/world/ ; mode d'emploi : « (X1) Ajouter une île »)
class_name WorldAtlas      # src/world/world_atlas.gd, classe statique (RefCounted, aucun autoload) : worlds(), world_name(id),
                           # islands(monde = tous), has_island(id), world_of(île), island_name(île), island_number(île)
                           # (0 sans numéro), is_legacy(île), island_of(map_id) (&"" hors de toute île), maps_of(île),
                           # arrival_map(île), ports_of(île) (ids), port(île, id) -> {id, name, map, marker},
                           # arrival(île, port = &"") -> {map, marker, port} ({} inconnu), places_of(île), place(île,
                           # lieu) -> {id, name, maps, links (lieu → marmer, deux sens), start_known}, place_of(map_id),
                           # rules_for(map_id), rules_of_island(île) -> IslandRules, map_of_node(nœud),
                           # enemies_allowed_at(nœud) (carte de ses ancêtres, sinon la courante ; sans carte : vrai),
                           # data_path(kind, île, fichier), find_data(kind, île, fichier), data_dirs(kind, île),
                           # problems() (tout : formats, cartes, marqueurs des ports, île dans un seul monde, carte
                           # dans une seule île), island_problems(données, id, scènes), world_problems(données, id),
                           # scene_markers(map_id), scene_island(map_id), clear_cache(), set_data_dirs(mondes, îles) ;
                           # WORLDS_DIR, ISLANDS_DIR, DEFAULT_ISLAND (ile_68), PORT_MARKER (from_dirigeable)
class_name IslandRules     # src/world/island_rules.gd (RefCounted) : enemies_allowed: bool, fauna: Array[StringName],
                           # void_below (VOID_CLOUDS, VOID_GROUND), sky: StringName, void_fall (FALL_LAST_SAFE,
                           # FALL_ARRIVAL), island ; clouds_below(), ground_below(), to_dict() ; statiques merged(couches,
                           # île) (monde puis île, par-dessus UNRULED), unruled(), problem(rules) ; KEYS, UNRULED
class_name AirshipDock     # src/world/airship_dock.gd, Area3D sous « Docks » d'une carte : @export island, port, prompt
                           # (vide : story.json travel/dock_prompt) ; interactable (couche 6, masque 2) ; board()
                           # (WorldManager.travel), destination_problem()
class_name TravelView      # src/world/travel_view.tscn (CanvasLayer, couche LAYER = 90) : la vue du ciel d'un voyage,
                           # posée et libérée par WorldManager ; begin(île, fondu), close(durée) (coroutine), elapsed(),
                           # black_alpha(), caption, island_id ; signal closed
class_name Player          # player.gd (L1)
class_name Pickup          # @export item_id: StringName, quantity: int, persistent: bool ; func collect(), pickup_id()
class_name Npc             # @export data: NpcData ; (Systèmes et textes) is_present(), refresh_presence() :
                           # absent = caché, process_mode DISABLED (ni collision ni InteractArea), sans invite,
                           # dialogue ; réévalué en fin d'image sur flag_changed, inventory_changed,
                           # game_loaded, skin_changed (après le dialogue en cours) ; (F1) plus de marqueur de quête
                           # (E4) life: LifeActor (null : immobile) ; enter_life(acteur),
                           # set_outfit(skin) (à chaud), set_moving(bool) (couche 0 en marche), say(texte, s) /
                           # hide_bubble() / bubble_text() (enfant Bubble, Label3D) ; (QC2) bubble_height(),
                           # place_bubble() : la bulle monte au-dessus de la tête du joueur quand, vue de la
                           # caméra, elle tomberait sur lui ; sans dialogue : une bulle
class_name DialogueRunner  # start(npc: NpcData), stop(), is_running() ; un par PNJ
                           # (Systèmes et textes) statiques : current_speaker_id() (speaker_id du nœud ou PNJ
                           # du dialogue, fixé avant dialogue_line), find_npc(id), add_npc_dir / remove_npc_dir,
                           # format_text() ({player}, {count:…}, {left:…}), player_name(), player_skin(),
                           # evaluate(), condition_problem(), story_text(chemin) ; (F1) arena_text retiré ;
                           # load_story_texts(), story_problem(), clear_story_cache()
# (F1) QuestTracker et QuestTrigger : retirées avec le moteur de quêtes.
class_name SheetLoader     # lecture des planches (read_sheet, build_frames, hit_frames, wave_frame, pixel_size)
                           # (E4) merge_sheets, add_frames, extra_view_texture/json, cached_count, EXTRA_KEY ;
                           # cache des SpriteFrames en références faibles (libérés avec la carte quittée)
# (HD-2D) Décor et caméra
class_name DecorPanel      # src/world/decor_panel.gd : racine d'un décor en panneau ; @export texture, pixels_per_meter (96),
                           # shadow_width, shadow_depth, keep_orientation, image_offset, tint, glow ; size_m() ; statiques
                           # quad_mesh(size), material_for(image, tint, glow), PIXELS_PER_METER, PANEL_SHADER ; l'image se
                           # tourne vers le sud, la collision (enfant « Collision », couche 1) garde la rotation du nœud
class_name Building        # src/world/building.gd : volume (murs, toit long ou pignon) en matières sans raccord + façade sud
                           # en image ; @export facade, wall_texture, roof_texture, footprint, wall_height, ridge_height,
                           # gable_front, overhang, window_glow ; surface_material(texture, relief)
class_name PropBatcher     # src/world/prop_batcher.gd, nœud « Geometry » des cartes : fond les MeshInstance3D à
                           # material_override en un mesh par image et par case (« Batch… ») ; @export cell_size
# (H9) Formats du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md, sections 3 et 17) : ajouts, l'existant ne change pas.
# Données propres à chaque exemplaire dans UV2 des sommets (le PropBatcher les garde) : un draw call par image.
class_name DecorPanel      # (H9) @export frames, fps (bande animée : size_m() = une image ; phase strip_phase(),
                           # phase_at(position), dans UV2.x ; l'image change dans le shader, TIME), flip_h,
                           # depth_offset (m vers la caméra, UV2.y : panneau contre un mur ou sur un toit),
                           # foreground (panel_foreground.gdshader : s'efface en trame autour du joueur) ;
                           # soft_alpha (panel_soft.gdshader : transparence mélangée, fumée, brume, nuages) ;
                           # material_for(image, tint, glow, frame_count, frame_rate, in_foreground, soft),
                           # panel_mesh(size, flip, phase, offset), update_foreground(tree), displayed_transform(node)
                           # (place affichée, lissage physique) ; FOREGROUND_SHADER, PHASE_STEPS, PLAYER_GROUP
class_name DecorPanel      # (I1) Vues d'un meuble (cahier n° 5, section 2.7) : @export facing (south, east, west, north ;
                           # vide : d'après la rotation du nœud, sa face est son +Z) choisit l'image : <nom>_side (flanc,
                           # face tournée vers l'est) à l'est, retournée à l'ouest ; <nom>_back (dos), ou <nom>_foot (lit par
                           # le pied), au nord ; la face au sud et quand l'image de la vue n'existe pas. view_texture(base,
                           # vue) trouve l'image par son nom, à côté de la face ; displayed_texture(), view_name() (&"front",
                           # &"side", &"back", &"foot"), view_flipped(), current_facing(), resolve_view() ; size_m() est celle
                           # de l'image affichée ; statique facing_of(front: Vector3) ; FACING_*, VIEW_*. Rien ne change pour
                           # keep_orientation ni pour une bande animée. La collision suit la rotation du nœud : ce qui pose
                           # le meuble le tourne quand la vue existe (tools/interior_maps.py)
class_name GroundDecal     # (H9) src/world/ground_decal.gd, racine possible d'un décor, sans collision : image vue
                           # de dessus, ancre au centre, couchée sur les triangles du sol ; @export texture,
                           # pixels_per_meter (96), soft_alpha, tint, flip_h, layer (0..7, UV2.y), follow_ground ;
                           # size_m(), draped_mesh(), material_for(image, tint, soft, layer) ; HARD_SHADER,
                           # SOFT_SHADER (ground_decal*.gdshader), SOFT_PRIORITY (−9 + couche) ; (E2) follow_ground
                           # drape sur le `MapGround` (enfant `Ground`) du premier ancêtre qui en a un
                           # (MapGround.triangles_in), sinon (F1) à plat à y = 0
class_name Building        # (H9) @export side_facade (flanc est, retourné à l'ouest ; enfant interne « Sides ») ;
                           # side_size_m(), side_contract_size() (pignon : profondeur × faîtage ; gouttereau :
                           # profondeur × mur), side_material(texture, glow, glow_color, glow_tolerance) ; (QO)
                           # @export window_glow_color (couleur des carreaux, sRGB de l'image), window_glow_tolerance
                           # (défaut : celle du shader, #FFCA63 à 0,12) ; DecorPanel.set_glow_rule(material, couleur,
                           # tolérance), glow_shader_color(couleur), glow_weight(pixel, couleur, tolérance) (jumeau du
                           # shader), GLOW_COLOR, GLOW_TOLERANCE ; material_for(…, glow_color, glow_tolerance)
class_name PropScatter     # (H9) @export variants: Array[PackedScene], random_flip ; pool(), variant_indices(),
                           # pick_variants(points, count, seed) (jamais la variante du plus proche voisin),
                           # nearest_neighbor(points, i) ; (T1) follow_ground : sur une carte de la refonte,
                           # le MapGround (enfant « Ground ») du premier ancêtre qui en a un, sinon l'île
class_name IslandTerrain   # (H9) GROUND_LAYERS (27 tuiles, ordre du contrat), GROUND_FALLBACK, ATLAS_COLUMNS,
                           # atlas_tile_count(size), ground_layer(layer, tile_count), triangles_in(rect),
                           # surface_height(x, z) ; terrain.gdshader : rangées lues dans la taille de l'atlas
                           # (B1) bord : edge_radius(angle) (rayon euclidien, plus en norme 4), edge_point(angle),
                           # edge_distance(x, z) (approchée), is_land(x, z), distance_to_edge(x, z) (exacte :
                           # marges des décors), rim_loop() (bord du sol en une boucle, depuis le nord)
class_name IslandEdge      # (B1) src/world/island_edge.gd : la forme du bord, une table de EDGE_SAMPLES rayons
                           # (radius, smooth_radius, point, normal(angle, smooth), distance, exact_distance,
                           # table, texture (shader du sol : edge_table), arc, length, base_radius : tracé
                           # d'origine, fade_distance) ; EDGE_LIMIT (±79,2 m), PORT_SECTOR, WATERFALL_ANGLE,
                           # CAPES, LEDGES, COVES ; IslandRock.uv_turn() (périmètre en textures de 4 m)
# (E2, refonte) Sol en relief des cartes extérieures : format et mode d'emploi en section 4, « Format du sol
# des cartes extérieures ». Coordonnées de la carte (origine au coin nord-ouest, x est, z sud, 1 case = 1 m).
class_name MapGround       # src/world/map_ground.gd (StaticBody3D, couche 1) : le nœud « Ground » d'une Map
                           # extérieure (docs/REFONTE.md 7.1) ; @export map_id (vide : nom de la Map parente),
                           # data_root (res://data/maps) ; build(), build_from(data) ; height_at(x, z) (VOID_HEIGHT
                           # dans le vide), material_at(x, z) -> StringName, is_walkable(x, z), level_at(x, z),
                           # map_size() -> Vector2i, triangles_in(rect) (décalques), set_sun(vers_le_soleil)
                           # ((R1) appelé par Atmosphere à chaque pose, transitions comprises ; plus de recherche
                           # de la première DirectionalLight3D), stats() (build_msec, triangles, draw_calls), ground_mesh(), cliff_mesh(),
                           # collision_faces(), barrier_faces(), rim_segments() ; var data: MapGroundData ;
                           # enfants internes Mesh (sol, 1 draw call), Cliffs (faces et rideau, 1), CloudSea (si le
                           # vide ; (R1) la seule mer de nuages de la carte, réglée par Atmosphere), CollisionShape3D (les triangles mêmes du sol et des faces), Barrier (côte, eau
                           # dormante, bords « land ») ; (X1) la mer de nuages n'est posée que si l'île a
                           # void_below = clouds ; void_below = ground : FarGround (le sol jusqu'à l'horizon, cadre de
                           # FAR_GROUND_SIZE m, matière du bord, 1 draw call) ; island_rules(), has_far_ground()
class_name MapGroundData   # src/world/map_ground_data.gd : lecture et vérification de data/maps/<id>/ ; statiques
                           # load_map(id, root), from_images(spec, heights, materials, structures), library() ;
                           # problems (vide : carte valide) ; surface_height, material_index_at, is_walkable,
                           # level_at, coast_value ; LEVEL_HEIGHT (0,5), STAIR_RISER (0,1), MAX_SLOPE_DEG (40)
class_name MapGroundBuilder # src/world/map_ground_builder.gd : triangles du sol, faces, collision (MapGround)
class_name MapGroundCoast  # src/world/map_ground_coast.gd : chaînes de la côte, rideau de roche, barrières
class_name SkyDrift        # (H9) src/world/sky_drift.gd (Island/Decor/SkyDrift) : panneaux lointains qui dérivent
                           # d'ouest en est en boucle (shader, TIME) ; @export textures, pixels_per_meter (48),
                           # count, span, fade, distance_range, height_range, speed_range, scale_range, tint,
                           # random_seed ; meshes(), drift_x(start, speed, time, length) ; matériau dans le mesh
class_name AmbientSprites  # (H9) src/world/ambient_sprites.gd : enum Motion { FALL, CROSS, FLUTTER, HOVER } ;
                           # @export texture, frames, fps, pixels_per_meter, motion, count, density, area, lift,
                           # region_size, speed, sway, tint, glow, random_seed ; sprite_count(), sprite_size(),
                           # focus_point(), update_box(focus), sprites_mesh(total, seed) ; un draw call
# (E9) Lumière et temps (src/world/materials/, src/world/) : ajouts, l'API de H5 reste (apply, apply_post, for_phase,
# active_sprite_tint)
class_name HD2DLighting    # préréglage (data/lighting/<id>.tres) : soleil (couleur, énergie, hauteur, azimut), ciel
                           # (sky_texture, vide : sky.png ; sky_tint, sky_energy), mer de nuages (clouds_texture,
                           # clouds_tint, clouds_warm, clouds_stars), ambiance, brouillard, lamp_energy, window_glow
                           # (× glow des panneaux), (R1) window_light et window_tint (jour qui entre par les
                           # fenêtres d'un intérieur : énergie, couleur ; celui du moment du dehors), night_amount (≥ NIGHT_IMAGES_FROM : images de nuit), player_light,
                           # rain, wetness, sprite_tint, étalonnage et flou (post_parameters : grade… glow_tint,
                           # top_blur_px, bottom_blur_px) ; statiques preset(id), has_preset(id), preset_path(id),
                           # for_phase(phase), blend_into(out, from, to, t), post_material(camera), own(resource) ;
                           # blended(other, t), copy(), sky_image(), uses_night_images(), toward_sun(), sun_basis() ;
                           # PRESETS_DIR, DEFAULT_PRESET (couchant), INTERIOR, INTERIOR_NIGHT, PHASE_MOMENTS
class_name HD2DWeather     # temps qu'il fait (data/lighting/pluie|averse.tres ; clair : aucun) : rain, wetness,
                           # facteurs et teintes (soleil, ambiance, gris, ciel, nuages, lanternes, brouillard,
                           # étalonnage), window_light_scale (dedans) ; preset(id), applied_to(base, outdoors)
class_name HD2DLightTargets   # relevé d'une carte (scan(map)) puis pose (apply(lighting, sky_from, mix, clouds_from)) :
                           # environnement (copié ; ciel en sky.gdshader, deux panoramas fondus), soleil, mers de
                           # nuages (cloud_sea.gdshader, copiées), Light3D × lamp_energy, glow_strength × window_glow
                           # (sauf les panneaux d'intérieur, glow_follows : leur pièce), (R1) intérieurs
                           # (rooms : InteriorRoom.apply_lighting) et sols en relief (grounds : MapGround.set_sun),
                           # hd2d_wetness (hd2d_light.gdshaderinc) et StandardMaterial3D mouillés, images de nuit
                           # (<nom>_night.png à côté de <nom>.png) et vitres éclairées (window_lit_*, la nuit seulement) ;
                           # IGNORE_GROUP (atmosphere_rig) ; counts()
class_name AtmosphereRig   # enfant « AtmosphereRig » de la carte courante (dress(map)) : WorldEnvironment et Sun si la
                           # carte n'en a pas (les cartes ne portent plus de lumière ; l'île garde les siens ;
                           # (R1) carte intérieure : fond uni InteriorRoom.VOID_COLOR, aucun ciel),
                           # PlayerLight (OmniLight3D) et Orb (fairy_light.png) à côté du joueur, Rain (RainFall),
                           # RainCurtain (CanvasLayer 0 : rain_drizzle.png et rain_curtain.png répétés à l'écran) ;
                           # apply(lighting, light_part), light_amount(), is_raining() ; light_energy, light_range…
class_name RainFall        # gouttes (fx/rain_drop.png) et éclaboussures (anim/rain_splash.png) dans une boîte autour
                           # du point visé, un draw call chacune (rain.gdshader) ; intensity (0..1), tint, focus_point()
# src/player/camera_rig.gd (racine CameraRig de camera_rig.tscn, sans class_name) : caméra fixe vers le nord
@export pitch_deg (32), fov_deg (30), focus_height, focus_ahead (2,5 m au nord du joueur), talk_ahead (0, en
        conversation), ahead_smoothing, distance (21), min_distance, max_distance, follow_speed, lead_time (0,2),
        lead_smoothing, limits: Rect2 (bornes du point visé ; (E1) celles de la carte courante à chaque map_entered,
        WorldManager.camera_bounds(), avec make_current() et snap()), lock_focus, lock_focus_max
var lock_target: Node3D, follow_velocity: Vector3   # posés par le joueur à chaque image physique
func update_camera(delta, zoom_axis := 0.0), focus_goal(with_lead := true) -> Vector3, anchor() -> Vector3 (place
     affichée du joueur, interpolée), snap(), snap_behind(_dir) (= snap), recenter_behind(_dir) (sans effet),
     zoom(amount), zoom_distance(), focus(), yaw() (0), pitch() (toujours pitch_deg), forward() (le nord)
# (recette du 8 octobre 2026) Cadrage constant : plus de cadrage automatique des bâtiments. Lissage physique
# (project.godot physics/common/physics_interpolation) limité au monde 3D : src/game.tscn Game ON, UI OFF ;
# src/main.tscn Main OFF. Un nœud 3D déplacé dans _process est en physics_interpolation_mode OFF et lit la place
# affichée de ce qu'il suit (get_global_transform_interpolated()).
```

### Conventions

- Nœuds et fichiers en `snake_case`, classes en `PascalCase` via `class_name`, signaux au passé (`item_collected`).
- Un système ne lit jamais un autre système directement : il passe par `EventBus` ou par l'API de `GameState`.
- Couches de collision fixées au Lot 0 : 1 `world`, 2 `player`, 3 `enemy`, 4 `hitbox`, 5 `hurtbox`, 6 `interactable`, 7 `pickup`. Le joueur et les ennemis ne se traversent pas ; les hitbox ne touchent que les hurtbox.
- Les chiffres de combat vivent dans `data/attacks` et `data/enemies`, jamais en dur dans un script : l'équilibrage se fait sans toucher au code.
- Le joueur est toujours le nœud unique du groupe `player` ; les ennemis vivants sont dans le groupe `enemies`.
- (E1) Le monde est une suite de cartes (`Map`, une par lieu, `src/world/maps/<map_id>/<map_id>.tscn`) : une seule chargée à la fois, sous `game.tscn` « World ». (F1) Les zones, l'arène et la carte héritée `ile_ancienne` sont retirées. Mode d'emploi pour créer une carte : plus bas, « (E1) Créer une carte ».
- Toute scène doit s'ouvrir et se fermer sans erreur en headless : c'est le test de fumée minimal (section 9).
- (HD-2D) Le décor est fait d'images à 96 px par mètre : un décor de `src/world/props/` a pour racine un `DecorPanel` ou un `Building` (ou un nœud qui en contient, comme la passerelle), sa collision dans un enfant `Collision` (StaticBody3D, couche 1). Aucun maillage modélisé ni forme calculée pour l'apparence. La caméra regarde toujours le nord : le haut de l'écran est le nord.

### Structure figée au Lot 0

Les lots tournent en parallèle et référencent les scènes des autres par leur chemin définitif. Les fichiers ci-dessous existent depuis le Lot 0, à leur chemin final, avec leur `class_name`, leurs nœuds nommés et leurs groupes. **Chaque lot remplit les squelettes de ses dossiers ; personne ne déplace ni ne renomme un fichier ou un nœud nommé de cette liste** (le propriétaire peut ajouter des nœuds et des fichiers). Les scènes `main` et `game` sont des fichiers d'intégration : elles ne changent que dans une PR « contrats » ou d'intégration.

| Fichier | Racine (type, `class_name`) | Nœuds nommés | Groupe, couches | Lot |
| --- | --- | --- | --- | --- |
| `src/main.tscn` + `main.gd` | `Main` (Node) | menu, chargement et partie ajoutés à l'exécution | — | L0 |
| `src/game.tscn` + `game.gd` | `Game` (Node3D) | (E1) `World` (Node3D, groupe `map_slot` : la carte courante, posée par game.gd, remplace `Island`), `Player`, `UI` (CanvasLayer) avec `UI/HUD`, `UI/DialogueBox`, `UI/Inventory`, `UI/TouchControls`, (E1) `UI/MapFade` (`src/ui/map_fade.tscn` : fondu et nom des cartes) ; (F1) `QuestTracker` et `UI/ArenaEnd` retirés | — | L0, E1, F1 |
| `src/player/player.tscn` + `player.gd` | `Player` (CharacterBody3D, `Player`) | `CollisionShape3D`, `Visual`, `Combat` (`PlayerCombat`) et `Combat/SwordHitbox` (`Hitbox`), `Health` (5 PV, 1,2 s), `Hurtbox`, `CameraRig` ((HD-2D) aux pieds du joueur) | `player` ; couche 2, masque 1+3 | L1 (L4 : valeurs du nœud `Health`) |
| `src/player/camera_rig.tscn` | `CameraRig` (Node3D) | (HD-2D) `Camera3D` (courante, `top_level`), `PostFX` (CanvasLayer, couche −1) et `PostFX/Screen` (ColorRect, `post_fx.gdshader`) ; plus de `SpringArm3D` | — | L1 |
| `src/combat/hitbox.tscn` + `hitbox.gd` | `Hitbox` (Area3D) | `CollisionShape3D` (forme locale à la scène) | couche 4, masque 5 | L4 |
| `src/combat/hurtbox.tscn` + `hurtbox.gd` | `Hurtbox` (Area3D) | `CollisionShape3D` (forme locale à la scène) | couche 5 | L4 |
| `src/combat/charge_wave.tscn` | `ChargeWave` (Node3D) | `Hitbox` (attaque `charge_wave`, équipe `player`), `Mesh` | — | L4 |
| `src/combat/health.gd`, `attack_data.gd`, `player_combat.gd` | `Health`, `AttackData`, `PlayerCombat` | — | — | L4 |
| `src/visuals/character_visual.tscn` + `.gd` | `CharacterVisual` (Node3D) | `Sprite` (AnimatedSprite3D billboard) | — | L3 |
| `src/visuals/skin_data.gd`, `sheet_loader.gd` | `SkinData`, `SheetLoader` | — | — | L3 |
| `src/enemies/enemy.tscn` + `enemy.gd` | `Enemy` (CharacterBody3D) | `CollisionShape3D`, `Visual`, `Health`, `Hurtbox`, `Hitbox` | `enemies` (vivants) ; couche 3, masque 1+2+8 | L5 |
| `src/enemies/enemy_data.gd` | `EnemyData` ; (F1) `Arena` et `WaveDirector` retirés | — | — | L5 |
| `src/items/pickup.tscn` + `pickup.gd` | `Pickup` (Area3D) | `CollisionShape3D`, `Mesh` | `interactable` ; couche 7, masque 2 | L7 |
| `src/items/item_data.gd` | `ItemData` ; (F1) `src/quests/` (`QuestData`, `QuestStep`, `QuestTracker`, `QuestTrigger`) retiré | — | — | L7 |
| `src/npc/npc.tscn` + `npc.gd` | `Npc` (CharacterBody3D) | `CollisionShape3D`, `Visual`, `InteractArea` (Area3D, couche 6), `DialogueRunner`, (E4) `Bubble` (Label3D, bulle de la vie) | `interactable` ; couche 1 | L6 |
| `src/npc/npc_data.gd`, `dialogue_runner.gd` | `NpcData`, `DialogueRunner` | — | — | L6 |
| (F1) `src/world/island.tscn`, `zones/`, `maps/ile_ancienne/` | retirés avec l'ancienne île (`Island`, `Zone`, `IslandTerrain` ; l'atlas du sol est dans `GroundAtlas`, `src/world/ground_atlas.gd`) | — | — | F1 |
| (E1) `src/world/map.gd`, `map_exit.gd`, `maps/<map_id>/<map_id>.tscn` | `Map`, `MapExit` ; racine `<map_id>` (`Map`) | `Ground` (sol, couche 1), `Geometry` (`PropBatcher`), `Markers` (`Spawn` + `from_<carte>`), `Exits` (`MapExit`), `Life` ((E4) `Life/Places` : les places des emplois du temps ; les PNJ de la vie y sont ajoutés) | `maps` ; sorties : couche 0 (6 si invite), masque 2 | E1 |
| (X1) `src/world/world_atlas.gd`, `island_rules.gd`, `airship_dock.gd`, `travel_view.tscn` + `.gd`, `data/world/worlds/`, `data/world/islands/` | `WorldAtlas`, `IslandRules`, `AirshipDock` (Area3D sous `Docks`), `TravelView` (CanvasLayer) | `TravelView` : `View`, `Caption`, `Black` | quais : couche 6, masque 2 | X1 |
| (E5) `src/fauna/animal.tscn` + `animal.gd`, `animal_data.gd`, `animal_pack.gd`, `fauna_rules.gd`, `fauna_nav.gd`, `fauna_populator.gd` + `fauna.tscn` | `Animal` (CharacterBody3D, hérite d'`Enemy`), `AnimalData`, `AnimalPack`, `FaunaRules`, `FaunaNav`, `FaunaPopulator` (Node3D, nœud `Fauna` sous `Life`) | ceux d'`enemy.tscn` | comme `Enemy` (couche 4) ; groupes `fauna`, `enemies` (dangereux) | E5 |
| (F1) `src/npc|enemies|items/placements/<zone_id>.tscn` | retirés avec les zones (`FreeEnemies` aussi) | — | — | F1 |
| `src/ui/main_menu.tscn` + `.gd` | `MainMenu` (Control) | `%NewGameButton` ; (bureau) `%FullscreenButton`, `%ExitGameButton` (cachés sur le Web) | — | L10 |
| `src/ui/hud.tscn`, `credits.tscn` | `HUD`, `Credits` (Control) | `HUD/PauseMenu` (L10 ; (bureau) `%FullscreenButton`, `%ExitGameButton`, cachés sur le Web) ; (F1) `ArenaEnd`, `HUD/Journal`, le panneau de l'arène, les bannières et l'encadré de quête retirés | — | L10 |
| `src/ui/dialogue_box.tscn` | `DialogueBox` (Control) | — | — | L6 |
| `src/ui/inventory.tscn` | `Inventory` (Control) | — | — | L7 |
| `src/ui/loading.tscn`, `touch_controls.tscn` | `Loading`, `TouchControls` (Control) | `Loading` : `set_progress(ratio: float)` facultatif, appelé par main.gd ; (M2) `load_scene(path, budget_ms)` qui charge la partie en plusieurs images, utilisée par main.gd si présente | — | L9 |

**Données présentes au Lot 0** : `data/attacks/{sword_1,sword_2,sword_3,charge_wave,bite,whip,rush}.tres` (L4) ; `data/enemies/timere_{small,normal,runner,big}.tres` et `data/enemies/visuals/timere.tres` (L5, visuel hors de `data/skins/` pour ne pas être jouable) ; `data/skins/chtholly.tres` et trois skins de PNJ de remplacement (L3 ; silhouettes de `tools/gen_placeholders.py`, retirés à l'acte 1 : les PNJ ont leurs visuels non jouables dans `data/npcs/visuals/`). `data/items/` (L7), `data/npcs/` et `data/dialogues/` (L6) sont à créer. Le nom de fichier d'une donnée est son `id`. (F1) `data/waves/`, `data/quests/`, les objets de `data/items/` et les dialogues de l'ancienne île sont retirés ; les PNJ, dialogues, objets et mondes d'exemple des tests vivent dans `tests/data/`.

**Couches et masques** (valeur = 2^(couche − 1)) :

| Objet | Couche | Masque |
| --- | --- | --- |
| Décor, sol, murs, PNJ | 1 `world` (1) | — |
| Joueur | 2 `player` (2) | 1 + 3 (5) |
| Ennemis | 3 `enemy` (4) | 1 + 2 + 8 (131) ; ils ne se bloquent pas entre eux |
| Hitbox | 4 `hitbox` (8) | 5 (16) |
| Hurtbox | 5 `hurtbox` (16) | — |
| Zone d'interaction (PNJ, panneau) | 6 `interactable` (32) | — |
| Pickup | 7 `pickup` (64) | 2 (2) |
| Barrière (couche réservée ; (F1) la barrière du village de l'ancienne île est retirée) | 8 `enemy_barrier` (128) | — |

**Actions d'entrée** : `move_left`, `move_right`, `move_forward`, `move_back`, `run`, `jump`, `attack`, `charge`, `interact`, `lock_target`, `inventory`, `journal` (Tab, L, bouton Select / Back ; (F1) le journal de quêtes est retiré, (E6) l'action ouvre le calendrier), `pause`, `camera_left`, `camera_right`, `camera_up`, `camera_down` (stick droit ; la souris se lit dans le code). Les contrôles tactiles (L9) émettent ces actions.

**Repères** : (F1) l'ancienne île et ses repères sont retirés ; chaque carte a les siens (origine au coin nord-ouest, nord = −Z, ouest = −X : « (E1) Créer une carte »).

**Tests** : (F1) les tests de quêtes et leur base sont retirés ; `tests/unit/test_no_dead_paths.gd` vérifie qu'aucun fichier de `src/`, `data/` ou `tools/` ne cite un chemin disparu ; stubs dans `tests/stubs/` (`visual_stub.tscn` hérite de `character_visual.tscn` et émet `frame_changed` / `animation_finished` à la demande, `player_stub.tscn` du groupe `player` avec Health et Hurtbox, `dummy.tscn` mannequin du groupe `enemies`), sans `class_name`. `tests/unit/test_contracts.gd` vérifie tout ce qui précède : un lot qui le fait échouer a cassé un contrat. Propriété des tests du Lot 0 : `test_health.gd` passe à L4, `test_game_state.gd` à L7, `test_save_roundtrip_l0.gd` à L8 (ils peuvent les adapter à leur implémentation) ; `test_contracts.gd`, `test_stubs_l0.gd`, `tests/integration/test_game_flow_l0.gd` et les stubs existants ne changent que dans une PR « contrats ». Un lot qui a besoin d'un autre stub en crée un nouveau fichier (`tests/stubs/<lot>_<nom>.gd`/`.tscn`, sans `class_name`).

### (E1) Créer une carte : mode d'emploi

Contrat : `docs/REFONTE.md`, section 7.1 ; exemple complet : `src/world/maps/essai/essai.tscn`.
(D2) Le plan de chaque lieu est dans `docs/lore/CARTE.md` (cotes, pièces, portes, meubles par
nom d'image, sorties, marqueurs, places) : ses blocs ```plan se vérifient par
`python3 tools/carte_plans.py check docs/lore/CARTE.md` (chevauchements, portes alignées,
passages de 1,2 m dedans et 3 m dehors, accès depuis `Spawn`, règle de caméra). Une carte
construite suit son plan à la lettre ; un écart se reporte dans le plan et repasse le `check`.

1. **Fichier et racine.** `src/world/maps/<map_id>/<map_id>.tscn`, `map_id` en `snake_case`
   ASCII qui commence par une lettre (`entrepot_rdc`, `sentier`). Racine `Node3D` nommée
   `<map_id>`, script `res://src/world/map.gd` (`Map`), avec ses exports :
   - `display_name` : annoncé à l'entrée par `UI/MapFade` (vide : rien) ; (QC2) seulement en jeu
     libre (`MapFade.is_free_play()` : ni scène, ni sommeil, ni jeu, ni conversation) : il attend la
     fin de la scène, et s'efface si une scène commence pendant qu'il est affiché ;
   - `region` (lieu de la carte de l'île), `interior`, `light_preset` (E9) ;
   - `size` (largeur x, profondeur z, en m) ;
   - `camera_bounds` : bornes du **point visé** (2,5 m au nord du joueur), pas de l'image. La vue
     montre environ 10 m de part et d'autre du point visé, 7 m au sud et 21 m au nord : pour ne
     rien montrer au-delà des bords est, ouest et sud d'une carte de L × P m, prendre à peu près
     `Rect2(10, 9, L − 20, P − 17)` (carte d'essai, 40 × 30 : `Rect2(10, 9, 20, 13)`) ; au nord,
     c'est le décor haut du bord (lisière, façades, falaise) qui ferme la vue, ou ce qu'on
     contemple au-delà (ciel, mer de nuages). Vide : la carte entière.
2. **Repères.** Coin nord-ouest à l'origine, x vers l'est, z vers le sud, 1 unité = 1 m, sol
   courant à y = 0, paliers de 0,5 m ; tout dans [0, size.x] × [0, size.y]. La caméra regarde le
   nord : le haut de l'écran est le nord ; rien de haut au sud d'un endroit où l'on marche, ce
   qu'on contemple au-delà d'un bord se pose au nord.
3. **Enfants figés** (`Map.REQUIRED_CHILDREN`, tous des `Node3D`) :
   - `Ground` : le sol et sa collision, couche 1 (`MapGround` d'E2 dehors, `InteriorRoom` d'E3
     dedans ; en attendant, un `StaticBody3D` plat avec ses murs invisibles, comme la carte
     d'essai). La carte doit être fermée : murs, falaises ou décor tout autour ;
   - `Geometry` : script `res://src/world/prop_batcher.gd` ; les décors de `src/world/props/`
     (instances), fondus en un draw call par image. Un `GroundDecal` (`follow_ground`) y suit
     le relief du `MapGround` de la carte (E2) ; sur une carte au sol plat provisoire, le
     mettre à faux ((F1) sans `MapGround`, il se couche à plat à y = 0) ;
   - `Markers` : des `Marker3D`. `Spawn` obligatoire (nouvelle partie, réapparition par défaut) ;
     un marqueur `from_<carte d'origine>` par sortie qui mène ici (`from_<carte>_<suffixe>` si
     plusieurs). Le joueur est posé au sol sous le marqueur, tourné vers son −Z : un marqueur
     se place à 2 ou 3 m de la sortie qui y ramène, hors de sa forme et de toute collision, à
     y = 0,2 au-dessus du sol ;
   - `Exits` : des `Area3D` au script `res://src/world/map_exit.gd`, chacune avec une
     `CollisionShape3D` qui couvre le passage (une boîte de 2 à 4 m), `collision_layer = 0`,
     `collision_mask = 2` ; exports `target_map`, `target_marker` (`from_<cette carte>`),
     `prompt` (vide : bout de sentier, on passe en marchant ; rempli : « Entrer », « Monter à
     bord », on passe par E ou A). Une sortie à pied se pose au bord, devant un mur ;
   - `Life` : PNJ, animaux, objets (E4, E5 ; un déclencheur de quête `QuestTrigger` marche
     partout).
   D'autres enfants sont permis. (E9) Une carte ne porte pas sa lumière : Atmosphere lui ajoute
   un enfant `AtmosphereRig` (environnement et soleil si elle n'en a pas, lumière du joueur,
   pluie) et pose le préréglage de son `light_preset` (un moment, `interieur`, ou un autre
   préréglage de `data/lighting/`), sinon `interieur` si `interior`, sinon celui du moment de la
   journée. Une lampe (`OmniLight3D`), une fenêtre ou un cristal qui luit (`glow` d'un
   `DecorPanel`) suivent le préréglage ; une image `<nom>_night.png` posée à côté de
   `<nom>.png` la remplace la nuit, une vitre `window_lit_*` ne se montre que la nuit.
4. **Les deux bouts d'une sortie.** Une sortie de A vers B demande le marqueur `from_A` dans B ;
   d'ordinaire, B a aussi la sortie de retour, avec le marqueur `from_B` dans A.
5. **Vérifier.**
   - `tools/import.sh`, puis `tools/test.sh tests/unit/test_maps.gd` : `Map.problems()` et
     `Map.exit_problems()` sur chaque carte (enfants, Spawn, sol sur la couche 1, Geometry,
     marqueurs dans la carte, sorties, cibles et marqueurs d'arrivée) ;
   - (E9) la lumière : `tools/e9_shots.sh essai:nuit:clair essai:couchant:averse` (sur le modèle
     des vues `essai` et `dedans` de `tests/integration/demo_e9.gd`) ;
   - une démonstration : instancier `src/game.tscn` puis `WorldManager.enter_map(&"<map_id>")`
     (sans fondu) ou `await WorldManager.go_to(&"<map_id>")` ; modèle : les vues `essai`,
     `fondu` et `retour` de `tests/integration/demo_hd2d.gd` (`tools/hd2d_shots.sh essai`) ;
     au plus 200 draw calls par vue ;
   - le temps de chargement : `tools/godot --headless --script tools/map_bench.gd -- --bench-maps=<map_id>,essai`
     (et sous Xvfb, voir l'en-tête du fichier), puis dans le navigateur
     `index.html?maps=<map_id>,essai` et `tools/web_maps.js` (docs/web.md).
6. **Pièges.**
   - Une carte n'est jamais préchargée (`preload`) par du code qui dure : elle resterait en
     mémoire. Les caches de matériaux des décors sont en références faibles (une carte quittée
     libère ses images) ; un nouveau cache statique doit l'être aussi.
   - Dans un test, `WorldManager.fade_time = 0.0` (rétabli dans `after_each`) ;
     `await WorldManager.go_to(…)` attend la fin du fondu de retour, `is_transitioning()` encore
     trois images physiques. Le joueur est figé (`process_mode` DISABLED) pendant le changement.
   - Une carte s'annonce par son `display_name` ((F1) les zones de l'ancienne île sont retirées).
   - Une démonstration n'ajoute jamais une carte à côté d'une autre : une seule carte à la fois,
     posée par WorldManager.

### (X1) Ajouter une île : mode d'emploi

Contrat : `docs/REFONTE.md`, sections 7.1 (`Map.island`) et 11.1 ; exemple complet : l'île d'essai
(`data/world/islands/ile_essai.json`, `src/world/maps/quai_essai/`), reliée au port provisoire de
l'île n° 68 (carte `essai`). Une île est **des données** : rien dans le code ne connaît son nom.

1. **Le fichier de l'île** : `data/world/islands/<island_id>.json` (`snake_case`, comme une carte) :
   - `name` (affiché : « L'île n° 68 »), `number` (facultatif, entier ≥ 1) ;
   - `maps` : ses cartes (chacune dans une seule île) ; `arrival_map` : l'une d'elles, la carte
     d'arrivée par défaut (un voyage sans port, une île sans port) ;
   - `places` : le graphe des lieux pour la carte de l'île (`docs/lore/CARTE.md`, section 1) ; un
     lieu par `region` de carte : `name`, `maps` (cartes de l'île ; vide : lieu à venir), `links`
     (lieu → distance en marmer, déclarée une fois, valable dans les deux sens), `start_known` ;
   - `ports` : `<port_id>` → `name`, `map` (une carte de l'île), `marker` (`from_dirigeable`, ou
     `from_dirigeable_<suffixe>` s'il y en a plusieurs sur la carte) ;
   - `rules` (facultatif) : ce qui change par rapport aux règles de son monde ;
   - (F1) la clé `legacy` de l'ancienne île est retirée. Une clé inconnue rend le fichier invalide
     (ignoré, avec un avertissement) ; une clé `_…` est un commentaire.
2. **La ranger dans un monde** : ajouter son id à `islands` de `data/world/worlds/regule_aire.json`
   (ou d'un autre monde). Les **règles** du monde valent pour ses îles (`IslandRules`) :
   `enemies_allowed` (Timeres permis : jamais sur Regule Aire), `fauna` (ids de `data/fauna/`),
   `void_below` (`clouds` : la mer de nuages sous le bord ; `ground` : le sol jusqu'à l'horizon),
   `sky` (préréglage de lumière d'une carte sans `light_preset` ; vide : le moment de la journée),
   `void_fall` (`last_safe` : une chute ramène au dernier point sûr ; `arrival` : au marqueur
   d'arrivée). Les systèmes les lisent par `WorldAtlas.rules_for(map_id)`, jamais par un nom.
3. **Ses cartes** : selon « (E1) Créer une carte » plus haut, avec `island = &"<island_id>"` à la
   racine (le défaut est `ile_68`) et `region` = l'id de son lieu. Au bord du vide, le nord : la mer
   de nuages vient seule (`MapGround`, si l'île a `void_below = clouds`).
4. **Le port** : sur la carte du port, le marqueur `from_dirigeable` (à 2 ou 3 m du quai, tourné
   vers la terre) et un quai pour repartir : un nœud `Docks` (Node3D) à la racine de la carte, avec
   un `Area3D` au script `res://src/world/airship_dock.gd` (`island`, `port` de la destination ;
   `prompt` vide : « Embarquer pour <île> ») et une `CollisionShape3D` (une boîte de 2 à 3 m à
   hauteur d'homme) ; le dirigeable lui-même en décor au **nord** du quai (règle de caméra).
5. **Le relier** : un quai vers elle dans un port d'une île existante (aujourd'hui la carte `essai`
   de l'île n° 68) ; le récit (E6) peut aussi appeler `WorldManager.travel(&"<island_id>", &"<port>")`.
6. **Son contenu** (vie, faune, scènes, textes) : `data/<kind>/<island_id>/`, par
   `WorldAtlas.data_path(kind, île, fichier)` ; `find_data` retombe sur `data/<kind>/<fichier>`
   (contenu commun) ; `data_dirs(kind, île)` donne les dossiers à lire, le sien d'abord.
7. **Vérifier** : `tools/import.sh`, puis `tools/test.sh tests/unit/test_world_atlas.gd` (format,
   cartes existantes et rangées, `Map.island`, régions des lieux, marqueurs des ports, un quai par
   port, destinations des quais) et `tests/unit/test_maps.gd` ; le voyage dans la vraie partie sur le
   modèle de `tests/integration/test_x1_travel.gd` ; des captures par
   `X1_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_x1.tscn build/shots/x1_<vue>.png 90`
   (vues `quai`, `surface`, `horizon`, `port`, `voyage` ; draw calls dans le journal, 200 au plus).
   Dans le navigateur : `index.html?island=<island_id>&port=<port>` (docs/web.md), F6 dans une
   version de débogage.

### (X1) Ajouter la surface : mode d'emploi

La surface est un **monde** (`data/world/worlds/surface.json`) dont les règles diffèrent de Regule
Aire : Timeres permis (leurs nids), `void_below = ground` (pas de mer de nuages : le sol continue
jusqu'à l'horizon, `MapGround.FarGround`), `sky = apres_midi` (« désert gris sous un ciel bleu »,
V5). Exemple : `data/world/islands/surface_essai.json` et `src/world/maps/surface_essai/`.

1. Une terre de la surface est une « île » de ce monde : même fichier que plus haut, sans `number`
   (`island_number` rend 0), rangée dans `islands` de `surface.json`.
2. Ses cartes : `MapGround` aux bords `land` (le sol et sa jupe se prolongent ; aucun vide, ou des
   gouffres seulement), au moins deux paliers ; matières grises (une teinte sur les tuiles de
   l'atlas, `tint` dans `materials` de `plan.json` : la surface a perdu ses couleurs) ; décors
   teintés (`DecorPanel.tint`) tant que le cahier n'a pas livré les siens.
3. Son port : un terrain plat où se pose le dirigeable (V2 : « sans port, un petit dirigeable peut
   se poser sur un terrain plat et dégagé ») : `from_dirigeable`, `Docks`, comme plus haut.
4. Ses Timeres : posés dans `Life` de ses cartes ou par une arène (`arena.tscn`) : ses règles les
   admettent ; les mêmes, posés sur l'île n° 68, disparaissent aussitôt (`Enemy._ready`).
5. Vérifier comme une île : `test_world_atlas.gd`, `test_island_rules.gd` (règles appliquées :
   Timeres, mer de nuages ou sol, ciel), et la vue `surface` / `horizon` de `demo_x1.tscn`.

### (E5) Ajouter un animal : mode d'emploi

Contrat : `docs/REFONTE.md`, sections 4.4 et 5 ; chiffres et comportements : `docs/lore/VIE.md`, section 6,
et `docs/lore/ACTE1.md`, section 3.5. La faune est **des données** : l'île n° 68 n'a aucun Timere, mais des
animaux sauvages ; rien dans le code ne connaît le nom d'une espèce.

1. **Le choix du format** : une espèce est une ressource `.tres` (`AnimalData`, qui hérite d'`EnemyData`),
   pas un JSON : ses attaques sont des `AttackData` (`data/fauna/<île>/attacks/*.tres`) et sa planche un
   `SkinData` (`data/fauna/<île>/visuals/<id>.tres`), comme un Timere. Seul le **peuplement**, une liste par
   carte, est un JSON (`peuplement.json`, vérifié clé par clé, comme les quêtes).
2. **La planche** : `assets/fauna/<id>/<id>.png` + `.json`, au format des personnages (profil tourné vers la
   droite, 96 px par mètre, ancres par image, `coup`). Les remplaçants se font par
   `python3 tools/gen_placeholders.py fauna [<id>…]` (`tools/gen_fauna.py` ; contrôle visuel :
   `python3 tools/gen_fauna.py preview <id>` → `build/e5/preview_<id>.png`) ; ils ont le profil seulement
   (`front_*` et `back_*` du `SkinData` sont facultatifs). La vraie planche du cahier n° 5 la remplace au même
   chemin, sans toucher au code. Animations (cahier, 7.3, confirmées telles quelles par le moteur) :
   `repos` 2 images à 2 ips, `marche` 6 à 8 (4 pour oiseaux et grenouille), `course` 5 à 14 (4), `attaque` 4 à
   12 avec `coup` [2], `degats` 1, `mort` 2 à 4 (jamais jouée : un vaincu s'enfuit), `fuite` 4 à 12 (boucle pour
   les oiseaux), `broute` 4 à 4 ips. Un animal n'a que celles de son comportement (`tests/unit/test_fauna_data.gd`) ;
   elles sont déclarées dans `tools/hd2d_manifest.json` (« sheets », tableaux `fauna` et `fauna_bird` de
   `tools/hd2d_sheets.py`, clé `anims`) : `python3 tools/hd2d_sheets.py check`.
3. **L'espèce** : `data/fauna/<île>/<id>.tres`, `script_class="AnimalData"` (modèle : `deer.tres`, `wolf.tres`).
   Elle donne la planche (`visual`), les PV (`max_hp` : coups avant de fuir), les vitesses (`speed` : course ;
   `walk_speed` : marche), `body_radius_m` (corps, Hurtbox, ombre) et `moments` (où dans la journée : `aube`,
   `matin`, `apres_midi`, `couchant`, `nuit` ; vide : toujours), puis, selon `behavior` :
   - `paisible` : `alert_range_m` (il lève la tête), `flee_range_m` (il fuit), `calm_distance_m`,
     `flee_speed`, `graze_animation` (`broute`) ; `fuyard` : pareil sans l'alerte ; les oiseaux ont `flies`
     (ils s'envolent) et `vanish_s` (ils quittent la scène), la grenouille un `vanish_s` court (plongeon) ;
     le bruit du joueur (`noise_run_factor` × 1,5 s'il court, `noise_still_factor` × 0,6 immobile) et celui
     d'un combat proche (`combat_noise_m`) règlent les distances ;
   - `dangereux` : l'IA d'`Enemy` (`aggro_range_m`, `attacks`, `rush` : un bond ou une charge en ligne droite
     dont l'attaque sans dégâts donne la portée de déclenchement), plus `leash_m` (la tanière de l'ours : 15 m),
     `stoic`, `windup_animation` et `stun_s` (le sanglier), `ring_radius_m`, `ring_speed` et `attack_gap_s`
     (la meute encercle et attaque un par un) ; les dégâts, la préparation (`windup`), la recharge sont dans
     les `AttackData` ;
   - `ambiant` : pas de corps, une bande animée (`ambient_*`) que le peuplement pose en `AmbientSprites`
     (papillons, libellules) ; `ambient_weather` (par beau temps seulement).
   Un animal vaincu (PV à zéro) **s'enfuit** : `defeat_flee_s` et `defeat_flee_m`, puis il disparaît ; ni sang,
   ni cadavre, ni `EventBus.enemy_killed`. Le signal est `Animal.fled`.
4. **Les règles de l'île** : l'id de l'espèce dans `rules.fauna` de son île (`data/world/islands/ile_68.json`) ;
   sans elle, l'animal n'apparaît pas. `peuplement.json` a aussi `banned_regions` : l'entrepôt, le village, la
   ville, le port (`Map.region` ou lieu du fichier de l'île) n'ont jamais d'animaux ; les oiseaux et les papillons
   d'ambiance de ces cartes restent des `AmbientSprites` de la carte.
5. **Le peuplement d'une carte** : un nœud `Fauna` (instance de `res://src/fauna/fauna.tscn`) sous `Life`, des
   marqueurs `Marker3D` sous `Life/Places`, et la liste de la carte dans `maps` de `peuplement.json` :
   `{"id": "loups", "species": "wolf", "count": 3, "at": "loups", "radius": 3.5, "pack": true}` (`at` : nom d'un
   marqueur de la carte ; ou `"rect": [x0, z0, x1, z1]` ; `moments` restreint ceux de l'espèce ; `weather` ;
   `respawn_s` : délai avant de regarnir un groupe qui a fui). Au chargement, tout est posé ; ensuite
   `GameState.moment` et `weather` (`EventBus.atmosphere_changed`) renvoient un groupe hors de saison (les bêtes
   s'éloignent) et en font venir un autre, toujours hors du champ de la caméra et à 14 m du joueur au moins ; les
   bêtes qui ont fui reviennent au bout de `respawn_s`. `planned` : le peuplement prévu des cartes qui n'ont pas
   encore leur nœud `Fauna` (sentier, forêt profonde, montagne ; (C3) la colline l'a, ses groupes sont dans `maps`) ; on le passe dans `maps` avec la carte.
   `FaunaRules.problems(&"ile_68")` en dit tout le format ; le test marche sur toutes les cartes de `maps`.
6. **Le sol** : les animaux marchent sur ce que `FaunaNav` permet (`MapGround.is_walkable`, `level_at` : ni eau
   dormante, ni vide, ni falaise de plus d'un cran) et contournent les décors par la collision.
7. **Vérifier** : `tools/import.sh`, `tools/test.sh tests/unit/test_fauna_data.gd` (format), `test_fauna_population.gd`
   (peuplement), `test_fauna_behavior.gd` (comportements), `test_fauna_guard.gd` (garde des Timeres et de la
   faune), puis les captures : `tools/e5_shots.sh [cerfs|ecureuils|meute|sanglier|ours|troupeau]` →
   `build/shots/e5/e5_<vue>.png` (carte `foret_essai`, `tests/integration/demo_e5.tscn` ; draw calls dans le
   journal, `test_e5_captures.gd` : 12 animaux dans le champ, 200 draw calls au plus). Dans le navigateur :
   `index.html?map=foret_essai` (docs/web.md) pose la partie dans la forêt d'essai.

### (E3) Intérieurs : `InteriorRoom`

Le nœud `Ground` d'une carte intérieure (`docs/REFONTE.md`, section 7.1) : un étage d'un bâtiment,
décrit par des données, bâti en images, vu par la caméra fixe qui regarde le nord. Mode d'emploi
détaillé, format complet et liste des images : `docs/INTERIEURS.md`. Exemple :
`data/maps/entrepot_rdc_essai/interior.json` et `src/world/maps/entrepot_rdc_essai/`, démo
`tests/integration/demo_interieur.tscn` (`game.tscn` et `WorldManager.enter_map` ;
`INTERIOR_VIEW=<vue>`, `INTERIOR_MOMENT`, `INTERIOR_CUT=0`) ; (R1) lumière : celle d'`Atmosphere`,
seule (la carte n'en porte aucune).

**Format** (`data/maps/<map_id>/interior.json`) : `size` (m, = `Map.size`), `wall_height` (3),
`wall_thickness` (0,25), `rooms.<id>` (`name`, `rects` : `[x, z, largeur, profondeur]` sur la grille
d'un mètre, `floor`, `wall`, `wallcut` : noms d'images de `assets/hd2d/interior/`), `doors[]`
(`between` : deux pièces, ou `room` + `side` N/S/E/W ; `x` ou `z` : centre le long du mur ; `width`,
`height`, `image` `door_*`, `passable`, `id`), `windows[]` (`room`, `side`, `x`/`z`, `image`
`window_*`, `sill`), `wall_items[]` (idem, `wallitem_*`, `y`), `lights[]` (`room`, `at` [x, z],
`radius`, `color`, `energy`). Les murs se déduisent des pièces (un mur partout où deux cases voisines
ne sont pas de la même pièce, le vide compris), centrés sur la ligne de grille ; une clé inconnue
est une faute (`_…` : commentaire). (T2) La grille est d'un demi-mètre (`InteriorLayout.GRID` =
0,5) : rectangles, cases, lignes de murs et coupe au demi-mètre (cloison en x = 5,5) ; un plan au
mètre reste valide.

```gdscript
# src/world/interior_layout.gd (class_name InteriorLayout, RefCounted) : lecture et vérification
static func from_data(data) -> InteriorLayout   # .problems : fautes (vide : valide)
var map_size: Vector2i, wall_height, wall_thickness, rooms, doors, windows, wall_items, lights, pieces
func cell(x, z) -> int / room_at(local) -> StringName / room_index(id) / door(id) -> Dictionary
func cut_line_at(local: Vector3) -> float   # première limite de pièce au sud de la case (NO_CUT)
func facing_against_wall(footprint: Rect2, tolerance := 0.25) -> StringName   # (I1) &"east" au mur ouest, &"west" à
     # l'est, &"south" au nord (le mur le plus proche), &"" sinon : l'orientation que les murs donnent à un meuble
func piece_box(piece) -> AABB ; static opening_center(opening), image_path(name)
const HORIZONTAL, VERTICAL, NO_CUT, DOOR_WIDTH (1,1), DOOR_HEIGHT (2,2), WINDOW_SILL (0,9)

# src/world/interior_room.gd (class_name InteriorRoom, extends StaticBody3D, @tool) : Ground
@export var layout: JSON, cut_enabled: bool, window_tint: Color, window_energy, lamp_energy
     # (R1) posées par Atmosphere (apply_lighting) ; valeurs de départ : un jour clair (éditeur)
var plan: InteriorLayout
func rebuild(), surfaces() -> Array[MeshInstance3D]   # un mesh par matière (+ « Void »)
func cut_target() -> float, cut_line() -> float, snap_cut()   # coupe (z du monde)
func apply_lighting(lighting: HD2DLighting)   # (R1) HD2DLightTargets, à chaque pose et chaque image d'une
     # transition : set_daylight(window_tint, window_light), set_lamps(lamp_energy)
func set_daylight(tint: Color, energy: float), set_lamps(energy: float)   # à la main (tests)
func apply_phase(phase)   # (R1) ancienne API : la phase (morning, day, evening, night) devient le moment
     # d'Atmosphere (HD2DLighting.PHASE_MOMENTS), tout de suite ; plus de PHASES ni de day_phase_changed ici
func height_at(x, z), material_at(x, z) -> StringName, room_at(x, z), is_walkable(x, z)
     # mêmes requêtes que MapGround (E2), repère de la carte
func door_position(id) -> Vector3, light_at(local) -> Color
func footprint_of(panel: Node3D) -> Rect2, facing_against_wall(panel) -> StringName   # (I1) emprise d'un meuble (sa
     # boîte de collision, tournée comme son nœud) dans le repère de la carte, et l'orientation que les murs lui donnent
func occluder_triangles(cut_world, player := Vector3.INF) -> PackedVector3Array   # tests
static func panel_material(texture, glow, tint, follows) -> ShaderMaterial, share_uniform(key, value),
     panel_mesh(size, cut, keep, flip := false), part_code(part, line)   # caches en références faibles (WeakRef) ;
     # (I1) flip : image retournée (flanc d'un meuble qui regarde l'ouest)
const CUT_HEIGHT (0,15), PROP_CUT_HEIGHT (1), CUT_MARGIN (0,3), CUT_SPEED (14 m/s), COLUMN_HALF,
      COLUMN_FRONT, COLUMN_LENGTH, LIGHT_TEXELS (4/m), VOID_COLOR, PLAYER_GROUP

# src/world/interior_panel.gd (class_name InteriorPanel, extends DecorPanel, @tool) : meuble
@export var cut_height: float = 1.0   # hauteur gardée quand la coupe passe
@export var cut_offset: float = 0.0   # (T2) ligne de coupe reculée vers le sud (meuble adossé au
                                      # mur sud : il se coupe avec lui) ; l'image ne bouge pas
func front_z() -> float, cut_z() -> float, occluder_triangles(cut_world) -> PackedVector3Array
```

**Règles du rendu.**
- *Coupe, rien ne cache le joueur* : la ligne de coupe est la première limite de pièce au sud de
  la case du joueur, dans sa colonne. Tout ce qui est au sud de cette ligne moins 0,3 m n'est
  dessiné que sous sa hauteur de coupe : murs (0,15 m, leur épaisseur `wallcut_*`), portes,
  fenêtres, éléments, meubles `InteriorPanel` (1 m). Le mur sud de la pièce du joueur n'est donc
  jamais dessiné ; ses murs nord, est et ouest le sont. Les meubles suivent aussi le z du joueur :
  au sud de lui, leur sommet est coupé à `cut_height`, y compris dans sa propre pièce. Les
  matériaux de meubles sont distincts des panneaux de murs et de portes. Dans la porte d’une
  cloison nord-sud, la colonne de coupe abaisse aussi la cloison sur 4,5 m au sud du joueur. La ligne glisse d'une
  limite à l'autre (14 m/s). Les collisions ne changent jamais. Shaders :
  `src/world/shaders/interior.gdshader`, `interior_panel.gdshader`, `interior_core.gdshaderinc`.
- *Lumière* (R1) : celle d'`Atmosphere`, seule. Le préréglage `interieur` (`data/lighting/interieur.tres`
  le jour, `interieur_nuit.tres` la nuit, mêlés selon la part de nuit du moment du dehors : ambiance,
  lumière d'ensemble, étalonnage, teinte des personnages) et deux cartes de lumière vues de dessus,
  bornées à leur pièce, ajoutées en émission : le jour des fenêtres (`window_light`, `window_tint`
  du moment du dehors : flaques de soleil le matin, orangées au couchant, un peu de lune bleue la
  nuit ; la vitre s'assombrit et bleuit, `night_view`) et les lampes, cheminées et cristaux
  (`lamp_energy` : 0,25 le jour, 2,7 la nuit). `Atmosphere` les pose à l'arrivée et à chaque image
  d'une transition (`InteriorRoom.apply_lighting`) ; aucune lumière du moteur ni ombre portée, pas
  un draw call de plus.
- *Draw calls* : un par matière de sol, de mur, de dessus de mur, par image de panneau et de meuble
  (le `PropBatcher` garde la coordonnée de coupe dans UV2), plus le vide : 36 à 67 par vue
  meublée dans l'étage d'essai, dans la vraie partie, interface comprise.

**Mode d'emploi pour décrire et meubler un intérieur** (détails : `docs/INTERIEURS.md`, section 1).
1. Dessiner le plan sur une grille d'un mètre (origine au nord-ouest), 2 m de vide autour.
2. Écrire `data/maps/<map_id>/interior.json` : pièces et matières, portes, fenêtres, éléments,
   lampes ; `InteriorLayout.from_data(...).problems` doit être vide.
3. Carte `src/world/maps/<map_id>/<map_id>.tscn` : racine `Map` (`interior = true`,
   `light_preset = &"interieur"`, `camera_bounds` : (QO) les pignons aux bords de l'écran, le joueur
   jamais hors du cadre ; une pièce qui tient à l'écran a une caméra fixe, `Rect2(x, z, 0, 0)`) ; `Ground` = `StaticBody3D` de script
   `interior_room.gd` (masque 0) avec `layout` ; `Geometry` (`PropBatcher`) ; `Markers` (`Spawn`,
   `from_<carte>` à y = 0,2, à 2 ou 3 m des sorties) ; `Exits` (`MapExit` devant chaque porte
   qui a un `id` : `door_position(id)` ; zone qui couvre la porte quand on la franchit en marchant ;
   carte cible et marqueur existants, `tests/unit/test_maps.gd`) ; `Life`. (R1) Aucune lumière :
   ni `WorldEnvironment`, ni `DirectionalLight3D`, ni lampe du moteur ; `Atmosphere` éclaire la
   carte (préréglage `interieur`, fond uni) et ses lampes viennent de `lights[]` (`interior.json`).
4. Meubler sous `Geometry` avec les scènes `InteriorPanel` de `src/world/props/` : nœud au milieu
   de l'emprise, image au bord sud ; au-delà d'1 m de haut, contre un mur nord ; au milieu d'une
   pièce, profondeur d'emprise ≥ `(h − 0,25) / 0,78 − 0,35` m (dans les 5 m nord, où la caméra
   bute sur ses bornes, moins de 0,7 m derrière un meuble haut) ; chaises `chair_wood` au nord
   des tables, `chair_wood_back` au sud ; lits vus de flanc, tête à l'ouest ; 0,8 m de passage ;
   tapis : `GroundDecal` de `assets/hd2d/decals/rug_*`. Portes qu'on franchit : image à
   ouverture transparente (`door_frame_wood`) ou aucune ; `door_room` aux portes fermées.
5. Tester l'étage sur le modèle de `tests/unit/test_interior_entrepot.gd` (circulation, portes,
   occlusion depuis chaque case, draw calls), dans la vraie partie sur le modèle de
   `tests/integration/test_interior_in_game.gd`, et le capturer sur le modèle de
   `tests/integration/demo_interieur.gd` (`game.tscn`, puis `WorldManager.enter_map`).
Images : celles du cahier n° 3 (`docs/ASSETS_HD2D_SUKASUKA.md`, section 3), jamais retouchées.
Une image qu'une carte emploie entre dans les listes de `tools/hd2d_interior.py` (taille réelle ;
profondeur et lueur d'un meuble ; recette pour un remplaçant seulement), puis `python3
tools/hd2d_interior.py manifest`, `python3 tools/hd2d_assets.py gen --lot I` (remplaçants),
`python3 tools/hd2d_interior.py scenes`, `tools/import.sh`, `python3 tools/hd2d_assets.py check
--lot I`.

### (T2) L'entrepôt des fées, dedans

Quatre cartes, du plan de `docs/lore/CARTE.md`, section 3 : `entrepot_rdc` (3.1), `entrepot_etage`
(3.2), `entrepot_toit` (3.3, une carte du dehors : `MapGround` dont le niveau 0 est la terrasse,
la cour 6,5 m plus bas), `salle_des_armes` (3.4). Région `entrepot` ; aucune lumière dans les
cartes (Atmosphere, E9 ; lampes et cheminées en cartes de lumière d'`InteriorRoom`). Écarts au
plan : docs/DECISIONS.md (« T2 »).

- **Outil** : `python3 tools/interior_maps.py gen [id…]` relit les blocs ```plan et écrit
  `data/maps/<id>/interior.json` (ou le sol du toit) et `src/world/maps/<id>/<id>.tscn` (pièces,
  portes, fenêtres, meubles, objets, sorties, marqueurs, places, objets à examiner, fermetures
  « <meuble>_arriere » des places où un meuble haut cacherait le joueur) ; `check` dit si une
  carte est à réécrire ; `places` réécrit les listes de places dans CARTE.md. Les images :
  `tools/hd2d_interior.py` (listes, scènes) et `tools/hd2d_interior_props.py` (remplaçants).
- **Orientation des meubles (I1)** : une ligne `meuble` du plan porte `regard=E|O|N|S` (un meuble
  adossé au mur ouest regarde l'est ; `tools/carte_plans.py` en vérifie l'état tourné) ; le générateur
  écrit `facing` sur le meuble et, quand l'image de sa vue existe (`<nom>_side`, `_back` ou `_foot` :
  cahier n° 5, lot R0 ; liste `VIEWS` de `tools/hd2d_interior.py`), le tourne d'un quart de tour autour
  du milieu de son bord arrière (emprise, collision, ombre, occlusion, examen suivent) ; sans la vue,
  il garde sa face. Une vue qui arrive : `interior_maps.py gen` ; `test_panel_facing.gd` le vérifie.
  Objets du cahier n° 4 (lots O1, O2, P) posés par des lignes `objet` sur les meubles de la cuisine, de
  la lecture, des archives, de l'infirmerie et des chambres (docs/DECISIONS.md, I1).
- **Le lot R1 posé (I2)** : bandes animées par `objet` (`bath_steam`, `comm_crystal_call` : nœud caché
  `visible = false`, que l'histoire montre quand le cristal sonne) ou `mural` (`wall_clock_swing` : DecorPanel
  accroché au mur ouest, à la place de l'élément de mur statique) ; `desk_clean`, `potted_plant`,
  `polishing_trestle` au plan ; le sol de la terrasse (`floor_roof_deck`) en `GroundDecal` de 4 × 3,5 m,
  le bord d'ardoise (`roof_edge_slate`) en panneau (docs/INTERIEURS.md, docs/DECISIONS.md, I2).
- **Places de la vie** : `Life/Places/<nom>` (`Marker3D`, regard vers ce qu'on y fait) : les
  `point` du plan, chaque chaise (`refectoire_chaise_a01`…), chaque lit, quelques sièges ; liste
  après chaque plan dans CARTE.md.
- **Sorties** : `vers_dehors` / `vers_arriere` (à pied) → `entrepot` (`from_entrepot_rdc`,
  `from_entrepot_rdc_service`) ; `vers_etage` « Monter », `vers_rdc` « Descendre », `vers_toit`
  « Monter sur le toit », `trappe` « Descendre », `vers_armes` « Ouvrir », `remonter`
  « Remonter ». Tant que `entrepot` (T1) n'existe pas, les portes du dehors mènent à `essai`.
- **Objets à examiner** (colonne « À examiner » des plans) :

```gdscript
# src/world/examinable.gd (class_name Examinable, extends Area3D) : interactable (couche 6,
# groupe « interactable »), zone BoxShape3D de taille size posée sur le sol au-dessus du nœud
signal examined(text_key: String)                 # fin de la lecture
@export var text_key: String                      # « entrepot_rdc/cuisine_fourneau »
@export var prompt: String = ""                   # vide : clé « prompt » du fichier (« Examiner »)
@export var size: Vector3, texts_path: String     # défaut res://data/texts/entrepot.json
func get_prompt() -> String, interact(player), show_text() -> bool, text_value() -> String
func dialogue_id() -> StringName                  # « examine_<clé> » (aucun PNJ : pas de portrait)
static func lookup(path, key_path) -> String, forget_texts()
```
  Textes : `data/texts/entrepot.json`, format des textes de l'histoire (une clé par carte, puis
  par objet ; ligne vide = page suivante ; `{player}`) ; affichés par le protocole de
  DialogueRunner (dialogue_started, dialogue_line sans nom, dialogue_ended).
- **Tests** : `tests/unit/test_entrepot_rdc.gd`, `test_entrepot_etage.gd`,
  `test_entrepot_toit.gd`, `test_salle_des_armes.gd` (base `tests/stubs/t2_map_test.gd` : plan
  complet, circulation, portes, rien ne cache le joueur de chaque case, draw calls par vue,
  textes) ; `tests/integration/test_entrepot_in_game.gd` ; captures
  `tests/integration/demo_entrepot.tscn` (`T2_VIEWS`, `T2_SHOTS`).

### (C1) Les cartes du dehors : `tools/exterior_maps.py`

L'équivalent de `tools/interior_maps.py` pour le dehors : il écrit une carte du dehors **d'après son
plan** (bloc ```plan de `docs/lore/CARTE.md`, lu par `tools/carte_plans.py`). Cartes construites :
`entrepot` (T1, reprise sans perte : `gen entrepot` redonne la scène du dépôt à l'octet),
`sentier` (C1), `village` (C2), `colline` (C3), `port` (CP) et `foret_profonde` (CF) ; carte d'attente (provisoire, un lot de la
phase 3 la remplace) : `ville_marche`.

```text
python3 tools/exterior_maps.py gen [map_id…]      # écrit les cartes (toutes sans argument)
python3 tools/exterior_maps.py check [map_id…]    # à jour ? écarts au plan, avertissements de la règle de caméra
python3 tools/exterior_maps.py places [map_id…]   # réécrit dans CARTE.md la liste des places de la vie
python3 tools/exterior_maps.py props              # écrit les scènes de décor nouvelles (exterior_props.py)
```

- **Ce qu'il écrit** : le sol (`data/maps/<id>/plan.json`, puis `map.json`, `heights.png`,
  `materials.png`, `structures.png` comme `tools/map_build.py gen`) et la scène
  `src/world/maps/<id>/<id>.tscn` : `Map` (nom, lieu, taille, bornes `Rect2(10, 9, L − 20, P − 17)`),
  `Ground`, `Edges` (les `bord` du plan en boîtes invisibles), `Geometry` (groupes de décors, `Scatter`
  des `PropScatter`), `Markers`, `Exits`, `Life/Places` (points du plan et places de la vie en plus),
  `Life/Areas` (places réservées, `metadata/area` = `Rect2`), `Lights` (seulement s'il y en a),
  `Ambience`. Les sorties vers une carte absente sont provisoires (`SETTINGS["provisional"]`) ou
  omises (`omit_if_missing` : l'outil les remet dès que la carte existe).
- **La pose** (`tools/exterior_pose.py`, classe `Pose`) : catalogue des décors (image, taille,
  emprise qui bloque, lue dans `src/world/props/`), hauteur exacte du sol, `place`, `scatter`,
  `poisson`, `along`, graines fixes. **Règle de caméra** (CARTE.md 0.3) : un décor qui se dresse
  au-dessus de la tête (1,4 m) devant une case où l'on marche prend sa variante de premier plan
  (`<décor>_forest` ou `<décor>_fg`, qui s'efface autour du joueur), faute de quoi il n'est pas posé
  et l'outil le dit. (QC2) **Places masquées** : `check` refuse aussi un décor de 2 m ou plus qui, vu
  de la caméra du jeu au cadrage par défaut, couvre la place d'un personnage debout (1 m de part et
  d'autre, du pied à la tête) sur un chemin (un point par mètre), un point, une place ou un marqueur
  du plan, une place de la vie (`PLACES_WHY`, `tools/life_zones.py`) ou une vue de
  `tools/qc_views.json` ; les places à moins de 4,5 m d'une sortie ne comptent pas
  (`exterior_pose.masked_places`). Une famille se tire sans masquer par
  `p.clear_of_places(scènes, points, échelle)` ; un décor que le plan veut là se déclare dans
  `SETTINGS["masks_allowed"] = {nœud: (places, pourquoi)}` (dit par `check`, sans erreur).
- **Une recette par carte** (`tools/exterior_recipes/<id>.py`) : `SETTINGS` (groupes de décors,
  sorties provisoires ; (C3) `camera_bounds`, `light_preset`, `no_lights`, `fauna` : bornes de caméra qui
  diffèrent de la règle, préréglage de lumière de la `Map`, plan à lumières que la carte ne porte pas, nœud
  `Life/Fauna`), `ground_plan(plan_map)` (`tools/exterior_ground.py` :
  `ground_from_plan` déduit le sol du plan, la recette y ajoute berges, îlots, rampes), `prepare(p)`,
  `pose(p)`, `ambient(p)`, `PLACES_WHY` (places de la vie que le plan ne nomme pas). Modèle court :
  `sentier.py` ; riche : `entrepot.py`. Ajouter une carte : son bloc ```plan, sa recette, son nom dans
  `RECIPES` (et le retirer de `WAITING`), `gen`, `tools/hd2d_assets.py gen`, `tools/import.sh`, ses
  tests (`tests/stubs/c1_exterior_test.gd` en base : plan, sorties, marqueurs, points, marche, caméra,
  densité, sol nu, draw calls, aucune lumière), son entrée dans `ile_68.json` (`maps` et son lieu).
- **Les images** que le plan cite et que les cahiers n'ont pas livrées : un remplaçant inscrit au
  manifeste (`tools/hd2d_sentier.py` : lot `R3`, `props/marsh_reed_wall`, `path_edge_ferns`,
  `path_root_step`, `fg_canopy_a`, `decals/bog_pool_a`, `path_stones_a`, `path_stones_b`), et sa
  scène dans `tools/exterior_props.py` (`PROPS`) ; une image livrée remplace le remplaçant du même
  nom sans toucher au code, une image livrée n'est jamais retouchée.
- **Le sentier et le marais** (`sentier`, CARTE.md section 4, 80 × 40 m) : lisière nord à +1 m, marais
  à −0,5 m (tourbe, eau basse où l'on marche, îlots de touradons), levée du sentier à 0, chemin de la
  ville qui descend à −0,5 m par sa rampe ; sorties à pied vers `entrepot` (`from_sentier`) et `port`
  (`from_sentier`, carte d'attente) ; la sortie vers `ville_haute` n'existe qu'avec cette carte, un
  écriteau « Plus loin, bientôt » au bout du chemin en attendant ; points du plan
  (`premiere_embuscade` pour `ACTE1.md`, `marais_chute`, `lumiere_pannibal`…), place `embuscade`,
  places de la vie en plus (`sentier_ouest`, `corbeau_perchoir`, `lisiere_renard`…). **Aucune
  lumière** (V1) : la nuit est celle d'`Atmosphere` (préréglage `nuit`) et de la lumière des fées du
  joueur (4 m), qui suffit à lire le sentier.
- **La colline des étoiles** (`colline`, CARTE.md section 7, 40 × 40 m, lot C3) : un cap de trois terrasses
  (+1, +2, +3 m) montées par trois rampes, un sommet plat de 12 × 12 m (la place `cercle_talismans`, libre,
  herbe rase, le petit cristal en `talismans_centre`, `dos_a_dos`, `vue_nord`, `rocher` : les points de la
  scène de l'acte 1, 8.8), le **vide au nord** (bord `void` de `MapGround` : la mer de nuages nocturne, les
  paliers vont jusqu'à la côte) ; sortie à pied vers `entrepot` (`from_colline`) ; bornes de caméra
  `Rect2(10, 6, 20, 26)` ; **`light_preset = &"nuit"`** (la nuit claire d'E9, quel que soit le moment de la
  journée ; CARTE.md l'appelle `nuit_claire`) et **aucune lumière** dans la carte (la lueur du cristal et des
  talismans est celle de la scène) ; faune d'E5 (`Life/Fauna`, `merles`, `papillons`, `chouette` : groupes dans
  `data/fauna/ile_68/peuplement.json`, `maps`) ; places de la vie en plus (`vers_entrepot`, `pied_de_colline`,
  `arbre_seul`…). Toutes les images du plan sont livrées ; `lone_tree_fg` et `boulder_a_fg` (premier plan,
  `tools/exterior_props.py`) ; remplaçant du talisman de la scène : `anim/talisman_float` (`tools/hd2d_colline.py`,
  manifeste, lot R6 du cahier n° 5).
- **Le port** (`port`, CARTE.md section 6.2, 70 × 40 m, lot CP, `tools/exterior_recipes/port.py`, remplace la carte
  d'attente) : le quai de tôle au bord du **vide** (garde-fou, poste d'amarrage ouvert, trois bras d'ancrage
  `mooring_arm_open`), le transport de la Garde en **grand panneau de coque** `ships/garde_transport_side` (16 × 7 m,
  `Geometry/Ship/TransportGarde`, sans collision ; remplaçant dérivé du flanc du Barocupot : E7 le remplace par le navire
  en volume), la passerelle (`Geometry/Quay/Passerelle`, un plancher) et le point `navire_quai` à son pied, la rue du
  port (pavés), le panneau aux flèches rouges (`signpost_port`, premier plan : `panneau_sud` pour le gros plan), l'aire-port
  (gravier), la colline ventée (+1, +2, +3 m, trois rampes qui montent vers le nord), la route de la ville ; sortie à pied
  `vers_sentier` (`from_port`) ; `vers_ville` (→ `ville_marche`) et `passerelle` (→ `transport_garde`) sont omises tant que
  leur carte n'existe pas (écriteau sur la route de la ville) ; bornes de caméra `Rect2(10, 6, 50, 24)` ; **aucune
  lumière** ; objets à examiner (`data/texts/port.json`) ; places de la vie en plus (`quai_ouest`, `sifflet_poste`,
  `bitte_corbeau_1`, `banc_colline`…) ; remplaçants d'images (`tools/hd2d_port.py`, manifeste, lots R3 et R7).
  **Après chaque `gen`, `tools/import.sh`** : le sol lit `materials.png` par l'import, un import périmé donne des
  rectangles d'herbe sur les pavés.
- **Tests** : `tests/unit/test_sentier.gd`, `tests/unit/test_port.gd` (28 : plan, vide, navire, passerelle, relief,
  bâtiments, images, premier plan, vie, textes, lumière, marche, caméra, densité, draw calls),
  `tests/integration/test_port_in_game.gd` (du sentier au port, le panneau, la montée de la colline, l'écriteau, le
  retour), `tests/unit/test_colline.gd` (28 : plan, relief, vide et mer de
  nuages, sommet libre, lumière, faune, marche, caméra, densité, draw calls),
  `tests/integration/test_colline_in_game.gd` (de l'entrepôt à la colline de jour et de nuit, la montée par
  les trois rampes, le bord, le retour ; captures `tests/integration/demo_c3.tscn` : `C3_VIEW=<vue>
  [C3_MOMENT=couchant C3_FREE=1] tools/screenshot.sh res://tests/integration/demo_c3.tscn
  build/shots/c3_<vue>.png 60`), `tests/unit/test_exterior_maps.gd` (`check` de l'outil,
  cartes d'attente, `port` dans l'île), `tests/integration/test_sentier_in_game.gd` (de l'entrepôt au
  sentier, au marais, à la rampe de la ville, au port, et retour) ; captures
  `C1_MAP=sentier C1_VIEW=<vue> [C1_MOMENT=nuit] [C1_LIGHT=off] tools/screenshot.sh
  res://tests/integration/demo_c1.tscn build/shots/c1_<vue>.png 60` (vues : `entree`, `ouest`,
  `milieu`, `marais`, `embuscade`, `berge`, `est`, `fourche`, `ville`, `large` ; draw calls dans le
  journal).

### (C2) Le village, le café et la maison Limashenka

Trois cartes d'après CARTE.md, section 5 : `village` (extérieur, 58 × 40 m, `tools/exterior_recipes/village.py`,
remplace la carte d'attente), `cafe` et `maison_limashenka` (intérieurs, `tools/interior_maps.py`, pièces
`salle` / `arriere` et `vestibule` / `salon`). Les trois sont dans `ile_68.json` (lieu `village`).

- **Réglages ajoutés à `exterior_maps.py`** (pour toute carte du dehors) : `no_lights` (aucun nœud `Lights` :
  la nuit est celle d'`Atmosphere`), `examine` (objets à examiner posés dans la carte : nœuds `Examine`,
  `text_key`, `texts`), `exit_meta` (métadonnées d'une sortie). Les bâtiments se posent par `BUILDING_SCENES`
  (le café a sa scène `cafe_village`, sans terrasse en cylindres).
- **La porte de la maison Limashenka** ne s'ouvre qu'au jour 11 (ACTE1.md 11.3) : la sortie `porte_limashenka`
  du village porte `open_from_day = 11` et `closed_text_key = "village/maison_close"` en métadonnées ; `MapExit`
  ne sait pas encore fermer une porte (demande dans `docs/CONTRACT_REQUESTS.md`), le récit (E6) lit ces
  métadonnées. Sans cela, la porte s'ouvre.
- **Le village** : rue d'est en ouest (entrée de l'entrepôt à l'est), chaumières, grange, café, maison close,
  lavoir, ruches, belvédère au nord-est, ruisseau et jardins au sud, île flottante en toile de fond. Aucune
  lumière dans la carte ; 14 places de la vie en plus du plan (`rue_ouest`, `rue_centre`, `terrasse_banc_1`,
  `etal_rue`, `jardins_sud`…). Clôtures, haies et buissons ferment les cases que la règle de caméra cache ;
  `Edges` bloque le reste.
- **Le café** : comptoir à vitrine à gâteaux, étagère aux bouteilles, deux tables de deux chaises, table des
  buveurs, arrière-boutique derrière un rideau rayé, clochette à la porte. Porte du mur sud (x = 4,75).
- **La maison** : vestibule, salon, horloge à peigne doré (trois états : fermée, ouverte, balancier de 4 images
  à 2 images/s, au manifeste, pour Willem au jour 11), canapé et fauteuil sous un drap, portrait de famille.
- **Les images** : 38 remplaçants au manifeste (lot `R3`), recettes Pillow dans `tools/hd2d_village.py`
  (`python3 tools/hd2d_village.py manifest` les inscrit ; `tools/hd2d_assets.py gen` les écrit) ; une image
  livrée du même nom remplace le remplaçant sans toucher au code.
- **Tests** : `tests/unit/test_village.gd`, `test_cafe.gd`, `test_maison_limashenka.gd`,
  `tests/integration/test_village_in_game.gd` (entrepôt, village, café, maison, retour) ; captures
  `build/c2/shots.sh <carte>:<lieu>:<moment>` sur `tests/integration/demo_c2.tscn` (voir DECISIONS.md, « C2 »).

### (CV) La ville haute et le snack-bar

`ville_haute` (dehors, 60 × 60 m, `tools/exterior_recipes/ville_haute.py`, CARTE.md 9.2 : trois terrasses, grand-rue et deux volées d'escalier, six sorties, portes « Entrer » du snack, du café, de la librairie et de la salle de projection, close avant le jour 5 par `open_from_day = 5` / `closed_text_key = "ville/projection_close"`), `ville_snack` (`tools/interior_maps.py`, 9.4, place `snack_vendor`) et les cartes d'attente `ville_marche`, `ville_cafe`, `ville_librairie`, `ville_projection` (`WAITING`, `WAITING_INTERIORS`) ; lieu `ville` de `ile_68.json` ; 38 remplaçants (lot R4, `tools/hd2d_ville.py`) ; tests `test_ville_haute.gd`, `test_ville_snack.gd`, `test_ville_attente.gd`, `tests/integration/test_ville_in_game.gd` ; textes `data/texts/ville.json` ; décisions : docs/DECISIONS.md (« CV »).

### (E9) Lumière et temps : mode d'emploi

Contrat : l'API d'`Atmosphere` ci-dessus ; détails et choix dans docs/DECISIONS.md (« E9 »).

1. **Changer l'heure ou le temps** (récit, E6) : `Atmosphere.set_moment(&"nuit")` (transition
   de 4 s), `set_weather(&"pluie", 8.0)`, `set_atmosphere(&"couchant", &"pluie", 0.0)` (tout de
   suite, par exemple sous un fondu). `GameState.moment` / `weather` peuvent aussi être posés
   directement (transition par défaut) ; ils sont sauvegardés. Moments : `aube`, `matin`,
   `apres_midi`, `couchant` (le monde de toujours, celui d'une nouvelle partie), `nuit` ; temps :
   `clair`, `pluie` (fine), `averse`. Écouter `EventBus.atmosphere_changed(moment, weather)`.
2. **Une carte** choisit sa lumière par `light_preset` : vide (le moment de la journée ;
   `interieur` si `interior`), un moment (`nuit` : la colline, une nuit claire, quel que soit
   le moment), `interieur`, ou un préréglage ajouté à `data/lighting/`. Le temps s'y ajoute
   dehors ; dedans, il ne pleut pas et seule la lumière des fenêtres baisse. Aucune lumière dans
   la scène de la carte (plus de `map_light.tscn` ni, R1, d'`interior_light.tscn`) :
   `AtmosphereRig` fournit environnement et soleil. Les lampes (`OmniLight3D`) suivent
   `lamp_energy`, les lueurs des panneaux (`glow`) `window_glow`.
   **(R1) Un intérieur** (`interior = true`, `Ground` = `InteriorRoom`) ne porte aucune lumière :
   `Atmosphere` pose le préréglage `interieur` (fond uni, ambiance) et règle la pièce à chaque
   pose et à chaque image d'une transition (`InteriorRoom.apply_lighting`) : le jour de ses
   fenêtres est celui du moment du dehors (`window_light`, `window_tint` de `matin.tres`,
   `nuit.tres`…), ses lampes, cheminées et cristaux (`lights[]` de `interior.json`, et la lueur
   des appliques et du fourneau) suivent `lamp_energy` (part de nuit : `interieur.tres` le jour,
   `interieur_nuit.tres` la nuit). Le sol en relief d'une carte du dehors reçoit la direction du
   soleil ou de la lune (`MapGround.set_sun`), sa mer de nuages est la seule de la carte. Les
   personnages prennent `sprite_tint` (`CharacterVisual`).
3. **Un préréglage** est un `HD2DLighting` (`data/lighting/<id>.tres`, champs commentés dans
   `src/world/materials/hd2d_lighting.gd`) ; un temps, un `HD2DWeather` qui modifie le
   préréglage du moment. Vérifier : `tools/test.sh tests/unit/test_atmosphere.gd` et
   `tests/unit/test_light_links.gd` (R1 : intérieurs, sol en relief, personnages), puis
   `tools/e9_shots.sh` (une capture par préréglage, luminance et draw calls dans
   `build/shots/e9/e9.log` ; lieux `village`, `bord`, `essai`, `dedans`, (R1) `refectoire`,
   `couloir`, `relief` ; `tests/integration/test_e9_captures.gd` refuse une vue trop sombre et un
   intérieur dont la nuit ne se distingue pas du matin).
4. **Images** (cahier n° 3, lot N) : les ciels (`sky_texture`) et mers de nuages
   (`clouds_texture`) d'un préréglage se fondent pendant les transitions ; `<nom>_night.png` à
   côté de `<nom>.png` le remplace la nuit (`night_amount` ≥ 0,5) ; `window_lit_*` ne se montre
   que la nuit ; `rain_curtain` / `rain_drizzle` (rideau à l'écran), `rain_splash`,
   `fairy_light` remplacent leurs remplaçants sans toucher au code.
5. **Tests** : un test qui change le moment ou le temps rétablit `GameState.reset()` (couchant,
   clair) ; un test qui habille une carte à la main appelle `Atmosphere.dress(null)` dans
   `after_each` ; `Atmosphere.step(s)` avance une transition sans attendre.

### (E4) La vie : format, API et mode d'emploi

La journée des habitants (docs/REFONTE.md, section 4 ; docs/lore/VIE.md) : chaque personnage a un
emploi du temps écrit à la main ; un autoload, `LifeDirector`, l'applique à la carte courante.
Démonstration : les cartes d'essai `entrepot_rdc_essai` et `essai_relief`
(`tests/integration/demo_e4.tscn`, `LIFE_VIEW=<vue>`) ; décisions : docs/DECISIONS.md (« E4 »).

**Créneaux.** Six (`GameState.SLOTS`) : `aube`, `matin`, `midi`, `apres_midi`, `soir`, `nuit` ;
leur lumière est un moment d'E9 (`LifeSlots.MOMENT_OF` : midi garde la lumière du matin, le soir
est le couchant). Le créneau courant (`LifeSlots.current()`) est `GameState.slot` s'il va avec
`GameState.moment`, sinon celui du moment (`LifeSlots.default_for`) : changer le moment par
`Atmosphere.set_moment` change le créneau ; `LifeDirector.set_slot(&"midi")` pose les deux.

**Emploi du temps** (`data/life/<npc_id>.json`, le nom du fichier est l'id du PNJ ; clé inconnue
refusée, `_…` : commentaire) :

```json
{
  "_comment": "Tiat : la toilette en pyjama, le chat dans les hautes herbes…",
  "gait": "course",
  "lines": [
    {"slot": "aube", "map": "entrepot_rdc_essai", "place": "point_eau", "activity": "toilette", "outfit": "pyjama"},
    {"slot": ["matin", "midi"], "map": "entrepot_rdc_essai", "place": "refectoire_table_b", "activity": "manger", "outfit": "vie"},
    {"slot": "matin", "day": [3, 12], "away": "ville_boulangerie"},
    {"slot": "apres_midi", "if": {"flag": "pluie_du_jour"}, "map": "entrepot_rdc_essai", "place": "jeux_tapis", "activity": "jouer"},
    {"slot": "soir", "map": "entrepot_rdc_essai", "place": "jeux_tour", "activity": "tour_de_fees", "role": "pile_2"},
    {"slot": "nuit", "away": "entrepot_etage"}
  ]
}
```

- `slot` (obligatoire) : un créneau ou une liste ; `day` : un jour (`GameState.day`, tenu par E6 ;
  0 = aucun) ou `[premier, dernier]` ; `if` : une condition sur l'histoire, grammaire des « if »
  de dialogue (drapeaux, objets, jours, scènes : docs/DIALOGUES.md).
- `map` + `place` : la carte et une place de son `Life/Places` ; ou `away` : hors des cartes
  construites (l'id de la carte à venir) ; sans ligne pour un créneau, le PNJ n'est nulle part.
- `activity` (`activities.json`, défaut `attendre`), `outfit` (une tenue de `NpcData.outfits` ;
  défaut : `NpcData.skin`), `gait` (allure du trajet : `marche`, `course`, `porte`), `role` (dans
  un jeu de groupe).
- **Choix** : les lignes à `day` ou `if` passent d'abord, puis les autres ; la première qui va
  l'emporte. On écrit la journée de base, puis les variations (VIE.md, section 3), où l'on veut.
- Le PNJ : `data/npcs/<id>.tres` (ou `data/npcs/generic/<id>.tres`, les fées génériques, nommées
  par `data/texts/life.json`, « fairy_names ») ; ses tenues : `NpcData.outfits` (nom → SkinData de
  `data/npcs/outfits/`, trois vues, une planche complémentaire `<id>_life` en `extra_*`).

**Places** : un `Marker3D` nommé sous `Life/Places` de la carte (posé au sol, à la hauteur du
palier dehors ; tourné vers où l'on regarde : son −Z). Ses enfants `Marker3D` en font une zone :
les sièges d'une table (un PNJ par point, le premier libre), les deux bouts d'une conversation, les
points où l'on erre, le terrain d'un jeu. Un siège se pose devant l'image d'une chaise vue de face
(+0,4 m au sud), derrière celle d'une chaise vue de dos, derrière la table. `vers_<carte>` : par où
l'on part vers une carte (et d'où l'on en arrive), avant la `MapExit` vers cette carte ; une carte
à venir (`away`) n'a que sa place `vers_`.

**Activités** (`data/life/activities.json`) : `speeds` (allure → m/s ; `rattrape` : l'allure de poursuite des suiveurs, 5,5 m/s, animation de course), `anim_speeds` (allure → vitesse de l'animation, 1 par défaut ; `rattrape` 1,4), `fallbacks` (animation →
remplaçantes, si la planche portée ne l'a pas), `activities.<id>` : `poses` (`[{anim, time}]`,
enchaînées en boucle, ou au hasard avec `order: "random"` ; `time` en s ou `[min, max]`, sans
`time` jusqu'au créneau suivant), `arrive` / `leave` (s'asseoir, se lever), `wander` (errer entre
les points de la place : `{pause, gait}`), `pair` (à deux, face à face, à tour de rôle), `look`,
`greet`, `step_aside` (regarder le joueur, le saluer d'une bulle, s'écarter s'il pousse : vrais par
défaut), `gait`, `game` + `params` (jeu de groupe). Activités livrées : attendre, manger, lire,
balayer, toilette, porter_linge, servir, cuisiner, the, dormir, gronder, errer, bavarder, jouer,
balle_mur, regarder, jeu_chat, course_couloir, avalanche, tour_de_fees.

```gdscript
# src/life/life_director.gd — autoload LifeDirector (project.godot, seul ajout d'E4)
signal slot_changed(slot: StringName)          # créneau appliqué (trajets lancés)
signal populated(map_id: StringName)           # PNJ de la carte posés (entrée)
func slot() -> StringName / func set_slot(slot, duration := -1.0) / func next_slot(duration := -1.0)
func where(npc_id) -> Dictionary               # ligne du créneau courant (consultation, hors carte compris)
func refresh(walk := true) -> void             # relit les lignes (le récit a changé un drapeau)
func attach(map: Map) -> void                  # peuple une carte (fait à map_entered ; démonstrations)
func actor(npc_id) -> LifeActor / func npc(npc_id) -> Npc / func actors() / func games()
func spawn_actor(npc_id, at: Vector3) -> LifeActor   # un PNJ hors emploi du temps (scène du récit, tests)
func game_at(game_id, place) -> LifeGame / func nav() -> LifeNav / func places() -> LifePlaces
func build_nav_now() / func stats() -> Dictionary / func stats_text() -> String / func reset_stats()
func player_home_outfit(map, skin) -> SkinData  # tenue de la maison du joueur (null : il garde sa planche)
var enabled, nav_budget_usec (3000), paths_per_frame (2), debug_keys, trace, cycle
# Raccourcis : F6 créneau suivant (Maj : tout de suite) ; ?creneau=<créneau>, ?vie=trace|off|cycle
# (Web) ou -- --creneau=… --vie=… ; trace : « [vie] … » toutes les 2 s dans le journal.

# src/life/ — classes
class_name LifeSlots   # MOMENT_OF, SLOT_OF ; all(), is_slot(), moment_of(), default_for(), current(),
                       # resolve(slot, moment), next()
class_name LifeData    # cast(), schedule(id), schedule_path(id), line_for(id, slot, day, evaluate), current_line(id),
                       # find_npc(id), schedule_problems(id, raw, check_world), all_problems(), activities_data(),
                       # activity(id), has_activity(id), speed(gait), is_gait(), fallbacks(anim), pose_time(pose, rng),
                       # activities_problems(raw), map_places(map_id), add_dir / remove_dir, clear_cache() ;
                       # DATA_DIR, PLACES_PATH (Life/Places), ANIMS, GAMES_DIR (src/life/games)
class_name LifePlaces  # read(map) ; has, names, points, size, point(place, i), center, radius, departure(map_id) ;
                       # facing_of(xform) (−Z au sol) ; DEPARTURE_PREFIX (vers_)
class_name LifeNav     # for_map(map) ; build_step(budget_usec) -> bool, build_now(), ready, cell (1 m dehors, 0,5 m
                       # dedans), cell_of, center, is_open, is_walkable_point, height_at, line_clear, cells_clear,
                       # nearest_open, find_path(from, to, avoid) -> PackedVector3Array (lissé), open_count ;
                       # AStar2D ; MAX_RISE (0,3 m d'un point au suivant), PROP_MARGIN (0,2 m) ; (E8c)
                       # MAX_STEP (0,105 m : une marche franche plus haute arrête, une pente ou une
                       # contremarche d'escalier de 0,1 m passe ; le bord d'une rampe taillée dans un palier)
class_name LifeActor   # un PNJ vivant : place_now(ligne), walk_to_line(ligne, délai), leave_by(sortie, délai),
                       # arrive_from(entrée, ligne, délai), walk_to(point, regard, allure, à l'arrivée, direct),
                       # hold(anim, s), stop(), play(anim), face(dir), position(), is_moving(), on_interact(),
                       # set_talking() ; state (ACTIVITY, WALKING, LEAVING, GAME, ASIDE, GONE), line, activity,
                       # place, spot, outfit, role, game, stuck_time (7 s : puis il se replace au but)
class_name LifeGame    # cadre des jeux de groupe (ci-dessous) ; signal event(kind, detail), events
class_name LifeTexts   # data/texts/life.json : text(chemin, défaut, rng), greeting(id), fairy_names(), fairy_name(id)
```

**Ce que fait le directeur.** À `EventBus.map_entered` (sous le fondu) : chaque PNJ dont la ligne
courante est sur la carte est ajouté au nœud `Life` (`npc.tscn`, `Npc.life` = son `LifeActor`),
posé à sa place, déjà en activité, dans sa tenue (aucun trajet : ce qui a changé pendant
l'absence du joueur est déjà fait). Puis la navigation se construit par morceaux. Quand le créneau
(ou `GameState.day`) change, chacun part à pied après un délai tiré (0,2 à 2,6 s) : vers sa
nouvelle place par un chemin (portes comprises), ou vers sa sortie s'il change de carte (il
disparaît en l'atteignant) ; qui arrive d'ailleurs entre par la sortie de sa carte d'origine. Hors
de la carte, rien ne tourne (`where()`). Le PNJ en marche quitte la couche 1 (il ne bloque jamais
le joueur, il l'évite) ; arrêté, il y revient. Évitement : on garde sa droite face à un PNJ qui
vient, on contourne d'un pas de côté un PNJ arrêté ou le joueur, puis on cherche un autre chemin ;
sans progrès 7 s, on se replace au but. Le joueur : à 3,5 m on le regarde ; à 3 m, parfois une
bulle (`greetings/<id>`, une à la fois) ; s'il pousse un PNJ debout, celui-ci s'écarte puis revient ;
en conversation, l'activité s'arrête et reprend. Une fée générique sans dialogue répond d'une bulle.

**Jeux de groupe** (`src/life/games/<jeu>.gd`, `extends LifeGame`). Les PNJ dont l'activité nomme
le même jeu à la même place forment le groupe ; le jeu mène leurs gestes. Le cadre :
- `members`, `roles` (rôle de la ligne, ou donné : `set_role`, `role_of`, `with_role`), `teams`
  (`assign_teams([&"rouge", &"blanc"])`, `team_of` : pour le ballon d'E8), `formation(n)` (points
  de la place, ou un cercle) ;
- `start()` à `min_members`, `finish()` en deçà ; `_tick(delta, joueur)` ; `events` / `event` ;
- le joueur : `join_distance`, `leave_distance` (`_player_close` / `_player_far` à redéfinir),
  `_accepts_player()`, `join_player()` / `leave_player()` (`player_in`), `on_player_interact(PNJ)`
  (vrai : remplace le dialogue), `on_player_attack(joueur)` (un coup d'épée, sans mal) ;
- `param(clé, défaut)` (`activities.json`, `params`), `text(clé)` (`life.json`, `games/<jeu>/`).
Jeux livrés : **chat** (une chasseuse court après les autres ; touchée, on devient le chat ; le
joueur entre en approchant, c'est lui le chat, il touche au contact ou d'un coup d'épée, on le
poursuit ; manches de 90 s, puis tout le monde s'effondre dans l'herbe), **course** (départ,
arrivée, poste de celle qui gronde : elles courent, Nygglatho les gronde, poings sur les hanches,
elles finissent en marchant ; le joueur sur la ligne de départ court avec elles), **avalanche**
(collées à une porte, `door` : un id ou `[pièce, pièce]`, `InteriorRoom.door_position` ; le joueur
l'ouvre ou les bouscule : elles tombent, s'excusent, s'enfuient, reviennent plus tard), **tour**
(la base assise, rôle `base` ; les autres, `pile_1`, `pile_2`… sautent sur la pile, décalées en
hauteur et vers la caméra (ordre d'affichage) ; la pile s'écroule ; parler à l'une : le gag).

**Mode d'emploi : écrire la journée d'un personnage**
1. Le PNJ existe (`data/npcs/<id>.tres`) et a ses tenues (`outfits`, SkinData de
   `data/npcs/outfits/`, planche inscrite au manifeste `tools/hd2d_manifest.json`, « sheets »,
   table `life` : `python3 tools/hd2d_sheets.py check`).
2. Les places existent dans la carte (`Life/Places`, un `Marker3D` par place, ses points enfants).
3. Écrire `data/life/<id>.json` (ci-dessus), une ligne par créneau, puis les variations (`day`,
   `if`) ; vérifier : `tools/test.sh tests/unit/test_life_data.gd` (tous les fichiers de
   `data/life/` : clés, cartes, places, activités, tenues) ;
4. Voir : `LIFE_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_e4.tscn sortie.png 120`
   (ou une vue à soi sur ce modèle), F6 pour passer les créneaux.

**Mode d'emploi : écrire un jeu**
1. `src/life/games/<jeu>.gd` : `extends LifeGame`, redéfinir `_setup`, `_started`, `_tick`,
   `_member_added` / `_member_removed`, et pour le joueur `_accepts_player`, `_player_joined`,
   `_player_left`, `on_player_interact`, `on_player_attack` ; mener les PNJ par
   `LifeActor.walk_to(point, regard, allure, rappel, direct)`, `hold(anim, s)`, `play`, `face`,
   `say(texte)` (bulle) ; noter ce qui compte par `_emit(&"…", détail)`.
2. Une activité dans `activities.json` : `{"game": "<jeu>", "params": {…}}` ; ses répliques dans
   `data/texts/life.json`, `games/<jeu>/` ; une place avec ses points (le terrain).
3. Les lignes des joueuses nomment l'activité (et leur `role`).
4. Tester sur le modèle de `tests/integration/test_life.gd` (`game.tscn`, `enter_map`,
   `LifeDirector.game_at`).
Le ballon (E8) : un jeu `ballon` sur ce cadre (`assign_teams`, `formation`, un `ball` dans `Life`,
le joueur qui entre dans le champ) ; la place `champ` porte les positions (buts, coup d'envoi).

**Mesures** (fin d'E4, rez-de-chaussée d'essai, petit-déjeuner, 15 PNJ). Natif (Xvfb) : 89 draw
calls (vue du réfectoire) ; directeur 0,25 à 0,6 ms/image ; grille intérieure 105 à 125 ms de
travail, extérieure (`essai_relief`) 420 à 580 ms, découpée à 3 ms par image (pas le plus long :
1,3 ms) ; un chemin 2,5 ms au plus. Build Web (`tools/web_life.js`, Chromium sans GPU, SwiftShader) :
vie coupée 74 draw calls, vie en marche 106 (max 111, sous 200) ; directeur 0,34 à 0,5 ms/image une
fois la grille prête ; pendant les 70 images de sa construction (225 ms de travail), 2,2 ms/image,
8 ms au plus (avant le découpage en petits pas : 50 ms d'un coup) ; chemins 0,9 ms au plus. Le
rendu logiciel tourne à environ 1 image/s, vie coupée comme en marche : la durée d'image du
navigateur (≤ 25 ms visés) se vérifie sur une vraie carte graphique, pas ici.

**(V1) La vie de l'entrepôt sur les vraies cartes.** Les emplois du temps de l'île n° 68 sont dans
`data/life/ile_68/` (`LifeData` lit `data/life/<île>/` : l'île de la carte peuplée, `LifeData.enter_island`,
puis `GameState.island`, puis l'île n° 68 ; `activities.json` reste commun ; `LifeData.use_content(&"essai")`
ou `?contenu=essai` : les démonstrations d'E4, `data/life/essai/`). Les places (zones, départs `vers_<carte>`,
orientations) viennent de `tools/life_zones.py`, lu par `tools/interior_maps.py` et `tools/exterior_maps.py`
(sous-commandes `gen` et `places` ; liste dans CARTE.md). `LifeDirector` tient les drapeaux de la pluie
(`pluie_du_jour`, `apres_pluie`) d'après `GameState.weather`. Les jours, les décisions et les manques :
docs/DECISIONS.md (« V1 »), docs/CONTRACT_REQUESTS.md. Tests : `tests/unit/test_life_ile_68_nav.gd`,
`tests/integration/test_life_ile_68.gd` ; vues : `tests/integration/demo_v1.tscn` (`V1_VIEW=<vue>`).

**Pièges.** Un test qui change le créneau rétablit `GameState.reset()` ; un test qui pose une carte
à la main et l'habite appelle `LifeDirector.attach(null)` dans `after_each`. Le directeur ne peuple
que les cartes posées par WorldManager (ou `attach`) : une carte instanciée seule par un test reste
vide. `LifeData` garde ce qu'il a lu (`clear_cache()`, `add_dir` / `remove_dir`).


### (E6) Le récit : format, API et mode d'emploi

L'acte 1 joué en jours et en scènes (docs/REFONTE.md, section 6 ; docs/lore/ACTE1.md, 0.1 et
0.2) : une île qui a `data/scenes/<île>/act.json` a un récit, mené par l'autoload
`StoryDirector`. Une nouvelle partie posée sur cette île (`WorldManager.start_map`, l'entrepôt)
l'ouvre ; `GameState.day` ≥ 1 tant qu'il dure (`GameState.story_running()`) ; une île sans acte
(la surface) n'a pas de récit. Décisions : docs/DECISIONS.md (« E6 »).

**Les données d'une île** (convention X1) :
- `data/scenes/<île>/act.json` : `start` (`map`, `marker`, `day`, `slot`, `weather` : la
  nouvelle partie), `departure_day` (entouré au calendrier dès le jour 1), `sleep` (`map`,
  `point`, `prompt`, `slots` où l'on se couche, `wake_slot`), `rest` (`prompt`, `points` :
  `{map, point}` où l'on laisse passer le temps ; le lit aussi), `calendar.examine` (l'objet à
  examiner qui ouvre le calendrier), `days.<n>` (`weather`, `sleep_after` : scènes à jouer avant
  de se coucher, `sleep_hint`) ;
- `data/scenes/<île>/<scène>.json` : une scène par fichier, son id est le nom du fichier (les
  jours 1 à 4 : `j1_1_port` … `j4_2_diner`) ;
- `data/dialogues/<île>/<scène>.json` : les dialogues de la scène (format de DialogueRunner :
  `speaker_id` et portraits, `"speaker": "{player}"` pour la protagoniste, choix, effets) ;
  `data/dialogues/<île>/talk/<pnj>.json` : ce que dit un personnage hors des scènes (entrées par
  jour) ;
- `data/texts/<île>/story.json` : indices, cartons, bulles, invites (`ui/…`), jours
  (`days/<n>/calendar` : la ligne écrite au coucher, `sleep_hint`) ; une clé sans « / » se lit
  sous l'id de la scène.

**Une scène** (clé inconnue refusée, `_…` : commentaire) :

```json
{
  "title": "La lumière dans la nuit",
  "day": 1,                       // un jour ou [premier, dernier] (facultatif)
  "slot": ["nuit"],               // créneau(x) où elle peut partir (facultatif)
  "after": ["j1_1_port"],         // scènes jouées avant (facultatif)
  "if": {"flag": "…"},            // condition de dialogue (+ day, slot, scene, not_scene)
  "map": "entrepot",              // sa carte (où « ready » part, où elle reprend)
  "marker": "Spawn",              // (facultatif) où la reprendre
  "trigger": {"on": "ready"},     // ready | enter (marker) | reach (point, radius) | talk (npc)
                                  // | examine (key) | prompt (point, prompt, size)
  "present": ["nygglatho"],       // PNJ réservés (hors de leur emploi du temps)
  "sequence": false,              // séquence sans contrôle : se passe d'Échap une fois vue
  "key": true,                    // scène clé : « laisser passer le temps » s'arrête à son créneau
  "hint": "hint",                 // indice tant qu'elle attend son déclencheur
  "steps": [ … ]
}
```

**Les étapes** (`"do"`, toutes avec un `"if"` facultatif ; `who` : `player` ou un PNJ de
`present` ; un point : une place `Life/Places`, un marqueur `Markers`, `player`, un PNJ présent ou
`[x, z]`, avec `offset` `[dx, dz]` ; `toward` : un point ou north / south / east / west) :

| Étape | Clés | Ce qu'elle fait |
| --- | --- | --- |
| `place` | who, at, offset, facing, outfit, anim, lift | fait paraître (ou pose) le personnage ; (S2) `lift` : à cette hauteur (m), sans collision (la pile de la tour de fées) |
| `walk` | who, to, offset, gait (marche, course), wait (vrai), facing, direct | marche par la navigation (le joueur : vraie physique) et l'attend |
| `follow` / `unfollow` | who, distance (2), stop_beyond (8), gait | le PNJ suit le joueur, d'une carte à l'autre, sans le gêner ; (L3) au pas du joueur : `gait` (marche par défaut) près de la garde, course au-delà de garde + 1,5 m, `rattrape` au-delà de 6 m (hystérésis), le but qui bouge ne l'arrête jamais (`LifeActor.follow_to`), perdu (au-delà de `stop_beyond`) il s'arrête, ou, si `StoryStage.repose_lost` (rythme libre), hors de la vue il est reposé derrière le joueur hors du champ de la caméra (`follower_reposed`) |
| `face` | who, toward | le tourne |
| `anim` | who, anim, time, wait | joue une animation (planche ou remplaçant d'activities.json) |
| `outfit` | who, outfit | change sa tenue (`NpcData.outfits`) |
| `leave` / `release` | who | le fait disparaître / le rend tout de suite à la vie |
| `bubble` | who, text, time | une bulle |
| `dialogue` | node, file (la scène), npc, presentation | un dialogue (choix : deux au plus) ; présentation « bandeau » (sans boîte) ou « nuit » (la boîte), par défaut bandeau tant que la scène tient le joueur (`DialogueBox.set_presentation` du lot U1 ; « nuit » rendue à la fin de la scène) |
| `camera` / `camera_reset` | to, offset, distance, pitch, time, wait | cadrage, gros plan (9 m), lever les yeux (15°) ; rendre la caméra |
| `fade` | to (black, white, clear), time | fondu |
| `card` | text, time | un carton sur l'écran (résumé d'une carte à venir) |
| `go_to` | map, marker | change de carte (WorldManager.go_to) |
| `moment` / `slot` / `next_day` | moment, weather, time / slot (ou next) | lumière, temps, créneau, jour suivant |
| `flag` | set, clear | drapeaux |
| `wait` / `wait_for` | time / reach (+ radius, map), map, examine, talk ; timeout, timeout_flag | attend un temps, ou le joueur (il garde la main) |
| `control` | on | rend ou reprend le contrôle (la scène le prend au début, le rend à la fin) |
| `game` | game, params, fallback | crochet d'E8 (`StoryDirector.register_game`) ; sans jeu inscrit, ou si l'appel rend `false` (le jeu n'a pas pu démarrer : carte d'essai, personnage absent), ses étapes de repli ; (E8c) « embuscade_pannibal », (E8b) « duel_willem » et « entrainement_seniorious » sont inscrits au démarrage (`MiniGames.register_story_games`) |
| `hint` / `calendar` | text (vide : rien) / line | l'indice de la scène ; une ligne du calendrier |
| `show` | node (chemin dans la carte), visible | montre ou cache un nœud de la carte courante (le cristal qui sonne : `Geometry/Nygglatho/comm_crystal_call_1` d'`entrepot_etage`) |
| (S2) `player` / `props` | visible / id, image, at, count, radius, lift, frames, fps, light, color, clear | cache la protagoniste le temps d'une séquence sans elle (rendue à la fin) ; pose un cercle d'images animées et sa lueur (les talismans de 8.8), retiré à la fin ; une `anim` du joueur est une pose tenue (jusqu'à la suivante, une marche ou la main rendue) ; jours 7 et 8 : `j7_*`, `j8_*`, tests `test_s2_day7.gd`, `test_s2_day8.gd`, captures `demo_s2.tscn` |

```gdscript
# src/story/story_director.gd — autoload StoryDirector (project.godot, seul ajout d'E6)
signal scene_started(id) / scene_finished(id) / hint_changed(text) / day_started(day)
signal game_requested(game_id, params) / calendar_requested
func island() / current_scene() / is_playing() / runner() -> StoryRunner / stage() -> StoryStage
func hint() -> String / day_count() / departure_day() / calendar_line(day) / ui_text(clé, défaut)
func play(id) -> bool (tests) / skip() / is_skippable() / has_seen(id) / mark_seen(id) / forget_seen()
func register_game(id, appel) / has_game(id)          # E8 : l'étape « game » attend appel.call(params)
func can_sleep() / sleep() / can_rest() / pass_time() / advance_day()   # sleep et pass_time : coroutines
func prompts() -> Array[StoryPrompt] / refresh()
var enabled := true / seen_path := "user://story_seen.cfg"   # séquences vues, hors sauvegarde
# src/story/ — classes
class_name StoryData   # use_root(chemin) (tests), file_path, dialogue_path, talk_path, has_act, act, scene_ids,
                       # scene, texts, text, day_data ; scene_problems(id, brut, île, monde), act_problems,
                       # all_problems(île) ; STEPS, TRIGGERS, SCENE_KEYS…
class_name StoryRunner # run(id, données, île) (coroutine), stop(), skip(), current_step() ; signal step_started
class_name StoryStage  # resolve(point, offset) -> Transform3D, direction(), player_within(), place_player(),
                       # walk_player() (coroutine), route() (portes, murs), set_control(), camera_rig(),
                       # overlay(), fade_overlay(), wait_overlay(), add_follower(), followers(),
                       # apply_doors(carte) (portes fermées jusqu'à un jour)…
class_name StoryDialogue  # play(chemin, nœud, id, pnj) : un dialogue ouvert à un nœud
class_name StoryPrompt    # invite du récit (couche 6) posée sur la carte : Dormir, Laisser passer le temps…
# Ajouts ailleurs : LifeDirector.reserve / stage / release / release_all / dismiss / is_reserved /
# talk_handler (LifeActor.State.SCENE) ; Player.set_story_hold / story_drive ; CameraRig.frame_story /
# release_story ; conditions de dialogue day, slot, scene, not_scene ; HUD/StoryOverlay,
# HUD/StoryHint, HUD/Calendar ; bouton « Calendrier » du menu pause.
```

**Le temps.** Le jour et le créneau n'avancent que par les scènes (`slot`, `next_day`) et par le
joueur : « Dormir » dans son lit (`sleep`) le soir ou la nuit quand les scènes de `sleep_after`
sont jouées (fondu, la ligne du jour écrite au calendrier, aube du jour suivant, temps du jour) ;
« Laisser passer le temps » (un créneau, jamais au-delà de celui de la prochaine scène clé du
jour, jamais au-delà de la nuit). La lumière suit le créneau (`LifeDirector.set_slot`).

**L'interface.** L'indice discret (`HUD/StoryHint`, en bas) paraît quelques secondes quand il
change et se rappelle à la fermeture du calendrier ; le calendrier (`HUD/Calendar`) s'ouvre par
Tab / L / Select pendant l'acte (à la place du journal), par le menu pause ou en examinant celui
de la chambre ; le voile des scènes (`HUD/StoryOverlay`) porte les fondus, les cartons et
« Échap : passer ». Pendant l'acte : ni encadré de quête, ni journal, ni « ! » / « ? ».
Pendant une scène, les signes d'interaction (U1) sont cachés : `InteractSign.suppress(&"scene")`.
Le calendrier prend le thème (type `Calendar` de `wordend_theme.tres` : case prune, encre crème,
rayure et cercle or) ; « Calendrier » est au menu pause, au-dessus d'« Options ». (QC2) Sous les
lignes écrites, un filet d'or, « Aujourd'hui : jour N » et le compte jusqu'au départ (« Départ dans
N jours », « Départ demain », « C'est le jour du départ » : clés `ui/today`, `ui/departure_in`,
`ui/departure_tomorrow`, `ui/departure_today` des textes du récit, repli en dur), puis l'indice ; la
page se resserre sur son contenu (au plus 640 px, lignes défilées au-delà de 220 px).

**Les portes fermées jusqu'à un jour.** Une sortie (`MapExit`) qui porte les métadonnées
`open_from_day` (jour d'ouverture) et `closed_text_key` (« village/maison_close » : la clé de
`data/texts/village.json`, fichier nommé par le premier segment) ne mène nulle part avant ce jour :
`StoryStage.apply_doors` la remplace par une zone à examiner (`ClosedDoor`, même invite) qui lit
le texte. Appliqué à chaque arrivée sur une carte et à chaque changement de `GameState.day`.

**Mode d'emploi : écrire une scène** (lot S2 : jours 5 à 12 ; jours 9 à 12 faits : `j9_1_porte` … `j12_3_epilogue`, « entrainement_baton » = `MiniGames.play_story_staff`, fin de l'acte : drapeau `acte1_fini`, docs/DECISIONS.md « S2 »).
1. Lire sa fiche dans ACTE1.md (lieu, présents, déclencheur, déroulé, choix, idées de
   répliques, contrôle, indice). Vérifier que les places existent (`Life/Places` de la carte :
   LifeData.map_places) ; une place qui manque se demande au lot de la carte
   (docs/CONTRACT_REQUESTS.md), en attendant `[x, z]`.
2. Écrire `data/scenes/ile_68/jN_k_nom.json` (déclencheur, conditions, présents, étapes), puis
   ses répliques dans `data/dialogues/ile_68/jN_k_nom.json` (paraphrasées, jamais recopiées ;
   `{player}`, jamais « Chtholly » en dur) et ses textes courts dans `data/texts/ile_68/story.json`
   (section de la scène). Une carte qui n'existe pas encore : un fondu et des cartons (plus aucune
   scène des jours 1 à 4 n'en a : lot S1b), jamais une carte inventée. Un combat : une étape `game` et son repli.
3. Le jour : sa ligne du calendrier (`days/<n>/calendar`), `sleep_after` et `sleep_hint` dans
   `act.json`.
4. Vérifier : `tools/test.sh tests/unit/test_story_data.gd` (format et monde de toutes les
   scènes) ; jouer la journée sur le modèle de `tests/integration/test_e6_days.gd` (poses et
   dialogues lus) ou de `test_e6_day1.gd` (vrais appuis, base `tests/stubs/e6_story_test.gd`) ;
   voir : `E6_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_e6.tscn sortie.png 60`.

**(S1b) Les jours 1 à 4 sur les vraies cartes** : `j1_1_port` au port (Willem descend de la passerelle, la protagoniste posée hors du champ à `from_ville_marche`), `j3_2_chemin` du sentier à la ville haute (le passant `villager_cat_m`), `j3_3_snack` dans `ville_snack` ; l'indice se tait dès le début d'une scène et pendant une étape `game` ; `wait_for` prend `map` avec `reach` ; captures : vue `sequence` de `demo_e6` (`E6_FROM`, `E6_UNTIL`, une image toutes les 0,5 s) ; tests : `tests/integration/test_e6_scenes.gd`.

**Pièges.** Une séquence (`sequence`) n'a ni choix, ni effet dans ses répliques, ni `control`, ni
`wait_for` (elle se passe d'une touche). `ready` part sur la carte de la scène seulement. Une
étape `hint` en fin de scène s'efface avec elle : l'indice de ce qui suit est le `hint` de la
scène suivante. Les tests : `StoryData.use_root("res://tests/data/story")` (acte d'essai),
`StoryDirector.seen_path` propre au test, `WorldManager.start_map` rétabli ; (F1) la base M1
(`tests/stubs/m1_game_test.gd`) part de la carte d'essai, le récit coupé (`story_for_test()`).

**(S2) Jours 5 et 6** (`j5_1_jeu_willem` … `j6_4_souvenir`, ACTE1.md 5.1 à 6.4) : le ballon n'est pas une étape `game` mais la vie : la séquence de midi (5.1) finit au créneau de l'après-midi (`slot`), les lignes `ballon` des jours 5 et 6 (`data/life/ile_68/`, arbitre, rouge, blanc) lancent le match d'E8 ; entrer dans le champ suffit pour jouer. Démonstration : `S2_DAY=5|6 tools/godot … res://tests/integration/demo_s2.tscn` (une image toutes les 0,5 s) puis `python3 tools/s2_sheet.py <dossier>` (planches) ; tests : `tests/integration/test_s2_day5.gd` et `test_s2_day6.gd` (base `tests/stubs/s2_story_test.gd` : reprise au réveil d'un jour, `rest_until`, `sleep_by_prompt`).

### (U1) L'interface « Nuit douce » : thème, dialogue et signes

- **Thème unique** : `src/ui/wordend_theme.tres`, à la racine de chaque écran (`theme`). Tout Control ajouté
  dessous en prend le style : `PanelContainer` = panneau prune translucide aux coins arrondis, ombre douce et
  filet doré (`NuitBox`, `src/ui/nuit_box.gd`) ; `Button` = entrée en texte simple, halo et point doré au
  focus ; `Label` crème ombré ; variations `HeaderLabel` (serif doré), `TitleLabel`, `SubtitleLabel`,
  `DayLabel` (italique doré), `MutedLabel`, `ErrorLabel`, `AccentLabel`, `HudPanel`, `HudLabel`, `HudAccent`,
  `HudMuted`, `HudTitle`, `PrimaryButton` (entrée dorée), `SkinCard(Selected)`, `InventorySlot`, `SlotCount`,
  voiles `Dim`, `FadeBlack`, `FlashWhite`, `GoldRule`, `BandeauVeil` (des `Panel`). Polices : Nunito (texte),
  Cormorant Garamond (noms, titres), `assets/fonts/`.
- **Jetons** (`UiStyle`, `src/ui/ui_style.gd`) : `UiStyle.color(&"gold" | &"cream" | &"ink" | &"panel" | &"muted" |
  &"error" | &"black")`, `UiStyle.constant(&"slide_px" | &"heart_px")`, `UiStyle.seconds(&"appear_ms" |
  &"breath_ms")` ; aides `UiStyle.frost(panneau)` (verre dépoli : flou de l'arrière-plan, `frost.gdshader`),
  `UiStyle.appear(noeud, direction)` (fondu et glissement d'entrée), `UiStyle.settle(noeud)`. Aucune `Color(`
  dans une scène de `src/ui/` (`tests/unit/test_ui_nuit.gd`).
- **Dialogue** : deux présentations. `DialogueBox.set_presentation(&"nuit")` (défaut : verre dépoli, nom serif
  doré, portrait en buste qui déborde et s'estompe, triangle doré qui respire) ou `&"bandeau"` (scènes du
  récit sans contrôle du joueur : dégradé sombre depuis le bas, nom en capitales serif espacées, texte blanc
  ombré) ; vaut pour la boîte ouverte et les suivantes jusqu'au prochain appel ; `DialogueBox.presentation()`,
  `shown_presentation()`. Le récit (E6) demande `bandeau` au début d'une scène et `nuit` à sa fin.
- **Signes d'interaction** (`HUD/InteractSigns`, `src/ui/interact_signs.gd`, API `InteractSign`) : un signe
  posé au-dessus de la cible du joueur (plein) et des autres cibles proches, à moins de 3,5 m (pâles), à la place de l'invite
  « E / A : Parler » ; genre `InteractSign.kind_of(cible)` (`&"talk"`, `&"examine"`, `&"take"`, `&"enter"`, `&""`
  sans invite) ; cacher une cible : `InteractSign.set_hidden(cible, true)` (méta `interact_sign` = `&"none"`) ;
  cacher tous les signes : `InteractSign.suppress(&"raison", true)` ; réglage « toujours montrer la touche » :
  `InteractSign.always_show_key()` (Options de la pause). Tests : `full_target()`, `full_kind()`,
  `pale_targets()`, `is_key_hint_shown()`, `hovered_target()` du nœud (`HUD.interact_signs()`).

### (E8) Les jeux : le ballon, l'entraînement au bâton, l'arme de Chtholly

Trois choses (docs/REFONTE.md, 4.2 et 5 ; docs/lore/VIE.md, 5.1 ; docs/lore/ACTE1.md, 3.0 et 3.2) :
le **ballon** des petites (un jeu de groupe de LifeGame), l'**entraînement au bâton** à trois contre un,
et **le bâton** que Chtholly porte hors des scènes de combat réel (pas de charge de venenum : décision de
D2). Les chiffres vivent dans `data/games/` (`GameRules`), jamais dans un script. Démonstration :
`tests/integration/demo_e8.tscn` (`E8_VIEW=ballon|ballon_bord|ballon_banc|baton_a|baton_b`,
`E8_SEQUENCE=<dossier>` : une image toutes les 0,5 s) ; raccourci de développement : `?jeu=ballon` ou
`?jeu=baton` (Web) / `-- --jeu=baton` (src/test_shortcuts.gd). Décisions : docs/DECISIONS.md (« E8 »).

**Lancer un jeu depuis le récit (E6)** — `MiniGames` (src/games/mini_games.gd, fonctions statiques ; ni
autoload ni PR « contrats » : la carte doit être peuplée par LifeDirector et son créneau déjà posé par
`LifeDirector.set_slot`) :

```gdscript
# Le match : les blanches (Tiat, Lakhesh, 3 fées), les rouges (Collon, Pannibal, 3 fées), Willem arbitre.
var game: BallMatch = MiniGames.start_ball_match({
	"place": &"champ_centre",                  # la place du terrain (défaut)
	"white": [&"tiat", ...], "red": [&"collon", ...], "referee": &"willem",   # ids de PNJ (défauts ci-dessus)
	"overrides": {"half_time": 20, "team_size": 4},   # chemins de data/games/ballon.json
	"muddy": false,                            # après la pluie : le ballon ralentit, elles glissent
	"with_player": false, "player_at": Vector3(...),   # le joueur entre tout de suite / est posé là
})
game.match_finished.connect(func(result: Dictionary) -> void: ...)   # la fin
# result : {winner: &"rouge"|&"blanc"|&"egalite", score: {rouge, blanc}, scorers: {id: buts},
#           player_team, player_goals, player_touches, duration, halves, aborted}
MiniGames.ball_match() -> BallMatch ; MiniGames.stop_ball_match()   # disperse : retour aux emplois du temps

# L'entraînement : Willem seul (phase A), puis avec Ithea et Nephren (phase B).
var training: StaffTraining = MiniGames.start_staff_training({
	"variant": &"default",                     # ou &"jour10" : phase A seule, la fenêtre de déviation se ferme à 15 s
	"place_player": true,                      # pose le joueur face à Willem
	"restore_weapon": true, "with_hud": true, "overrides": {...},   # chemins de data/games/staff_training.json
})
training.finished.connect(func(result: Dictionary) -> void: ...)   # la scène continue toujours
# result : {success, ended_by: &"success"|&"fatigue"|&"touches"|&"misses"|&"stopped", phase_reached,
#           phase_a: {success, best_streak, deflections, hits, blocked, dodged},
#           phase_b: {success, counters, touched_willem, survived}, touches, duration, variant}
# Signaux : phase_changed(&"intro"|&"a"|&"link"|&"b"|&"ended"), resolved(sorte, issue), touches_changed(n, limite),
# window_closed (jour 10 : le rythme tremble : effet d'E9). MiniGames.staff_training() ; stop_staff_training().
```

**(E8c) L'embuscade de Pannibal** (src/games/ambush.gd, class Ambush, un Node3D ajouté à `Life` ; ACTE1.md 3.1 ;
`data/games/embuscade.json`, textes `games/embuscade/…` de life.json) — `MiniGames.start_ambush({npc (pannibal),
day (GameState.day), help, seed, overrides, outfit (vie), with_hud, restore_weapon}) -> Ambush` (null sans joueur,
sans carte peuplée ou sans le PNJ) ; `ambush.finished(résultat)` après la pose de fin, tout rendu : {success,
ended_by: &"streak"|&"riposte"|&"points"|&"time"|&"fled"|&"stopped", points, touch_limit, best_streak, parried,
dodged, hits, leaps, feints, touched, duration, day} ; signaux `phase_changed(&"intro"|&"leap"|&"slash"|&"rest"|
&"ended")`, `resolved(&"leap"|&"slash"|&"riposte", &"parried"|&"dodged"|&"hit"|&"feint"|&"touched"|&"evaded")`,
`touches_changed(points, limite)`, `help_shown(&"dodge"|&"guard")` ; `MiniGames.ambush()`, `stop_ambush()`. Le bond
(annoncé 0,8 s par la lumière qui zigzague et un cercle au sol, lancé de 4 m) s'esquive en sortant du cercle (la
parade n'y suffit pas ; une feinte sur trois dès le jour 5) ; trois taillades à 0,35 s, parées (parade tenue à
l'impact) ou esquivées (hors de portée) ; une touche reçue : un point, recul de 0,5 m, fin de la série ; après une
esquive, une riposte au bâton la touche (0,8 s), couverte elle l'esquive. Réussite : cinq de suite ou la riposte
(`tombe`) ; échec : trois points (`lance`). Pendant le jeu : le joueur a la main, bâton en main, Pannibal muette
(Hush : `blocks_talk`, `InteractSign.set_hidden`), signes cachés (`InteractSign.suppress(&"embuscade")`),
présentation « nuit » ; à la fin, l'arme, la main de la scène, la présentation et les signes reviennent. Au récit :
`MiniGames.register_story_games()` (appelé par `StoryDirector._ready`) inscrit `play_story_ambush(params)` sous
« embuscade_pannibal » (params de la scène : day, help, seed, overrides, success_flag : posé si Chtholly l'emporte).

**(E8b) Le duel ingagnable** (src/games/duel.gd, class Duel, un Node3D ajouté à `Life` ; ACTE1.md 3.3 et 8.3 ;
`data/games/duel.json`, textes `games/duel/…` de life.json) — `MiniGames.start_duel({reprise, place (Willem à
cour_willem, le joueur à cour_chtholly, face à face), seed, overrides, with_hud, restore_weapon}) -> Duel` (null sans
joueur, sans carte peuplée ou sans Willem) ; `duel.finished(résultat)` après la pose de fin, tout rendu : {success
(toujours faux), ended_by: &"thrown"|&"stopped", reprise, phases (dans l'ordre), strikes, dodges, beckons, vision_by:
&"charge"|&"time", dash_distance, thrown_distance, duration} ; signaux `phase_changed(&"intro"|&"dodge"|&"ready"|
&"vision"|&"reversal"|&"ended")`, `resolved((&"strike", &"dodged"|&"missed"), (&"beckon", &"waiting"), (&"venenum",
&"charge"|&"time"), (&"dash", &"started"), (&"reversal", &"deflected"), (&"thrown", &"landed"))`, `vision_changed(actif)`,
`heartbeat(index)` (pour un futur lot du son) ; `MiniGames.duel()`, `stop_duel()`. Phase 1 (`dodge`, 30 s au plus) :
chaque coup à portée (2,4 m, dans l'arc) passe à côté, Willem fait un pas de côté de 1,2 m, jamais une parade ; sans
attaque pendant 8 s, il fait signe d'approcher (`parle`). Phase 2 (`vision`) : la touche de charge tenue 2 s
(Seniorious en main) ; l'image pâlit de 60 % sauf autour de Chtholly, Willem et les PNJ à 25 m à × 0,6, des éclats
sortent de la lame ; au premier coup (frappe ou onde), l'élan (8 m au plus, deux foulées, arrêté à 0,9 m de Willem ;
le duel mène alors le joueur : `set_story_hold`). Phase 3 (`reversal`) : écran blanc 0,6 s, deux battements (le blanc
se voile), puis il dévie (`attaque` de willem_duel), elle est projetée à 6 m (`degats`, tenue jusqu'à la fin), Percival
brille (halo additif `Duel.make_glow`). Reprise (`reprise: true`, « Encore une fois ! ») : `intro` (Willem en `pare`) →
`ready` (la charge tenue 1,2 s) → `vision` → `reversal`, durées ÷ 1,5. **Aucun point de vie perdu, aucun écran de
défaite.** Au récit : « duel_willem » → `play_story_duel(params)` (reprise, place, seed, overrides, flag : posé quand le
duel est joué) ; la scène 8.3 pose le choix « Encore une fois ! » / « … D'accord. » après l'étape « game » et rappelle
le jeu avec `{"reprise": true}`.

**(E8b) Les effets** (src/games/game_vision.gd, class GameVision) — deux réglages du post-traitement
(`src/player/post_fx.gdshader`, nuls par défaut, hors de l'étalonnage d'Atmosphere) : `pale_amount`, `pale_center`,
`pale_radius` (désaturation sauf un disque, en hauteurs d'écran) et `flash_color` (l'écran blanc, alpha = force).
`GameVision.post_material(player)` ; `begin(matériau)` retient leur état, `set_pale(part, centre, rayon)`,
`set_flash(force, couleur)`, `end()` le rend tel quel ; `slow(visuels, échelle)` / `tick(delta)` / `unslow()` mènent
l'horloge de CharacterVisual (le ralenti). Sans caméra du joueur, les réglages sont seulement retenus.

**(E8b) L'entraînement avec Seniorious** (src/games/seniorious_training.gd, class SenioriousTraining ; l'épée arrachée :
seniorious_sword.gd, class SenioriousSword ; ACTE1.md 3.4 et 11.4 ; `data/games/seniorious.json`, textes
`games/seniorious/…`) — `MiniGames.start_seniorious_training({start_stage (1 à 3 ; 2 après la réussite du jour 9),
pickup (vrai : l'invite « Ramasser Seniorious » dans le marais ; faux : fini quand l'épée tombe), place_player (à
l'ouest de Willem, à clairiere_centre), seed, overrides, with_hud, restore_weapon}) -> SenioriousTraining` ;
`finished(résultat)` : {success, ended_by: &"grues"|&"fatigue"|&"stopped", stage_reached (1 à 4), start_stage, breaths
{good, early, late, missed, cycles}, moves {done, missed, announced}, grues, fends, parried, hits, picked_up, duration} ;
signaux `stage_changed(&"intro"|&"breath"|&"moves"|&"crane"|&"pickup"|&"ended")`, `resolved((&"breath", &"good"|
&"early"|&"late"|&"missed"), (&"move", &"done"|&"missed"), (&"fend", &"crane"|&"parried"|&"hit"|&"dodged"),
(&"sword", &"flew"|&"landed"|&"picked"))`, `announced(&"trois_coups"|&"pare"|&"cote")` ; `MiniGames.
seniorious_training()`, `stop_seniorious_training()`. Le souffle : la touche de charge tenue à l'inspiration (2 s),
relâchée à la fin de l'expiration (2 s) à 0,3 s près, cinq cycles, sans échec (Willem corrige). Les gestes : neuf
annonces (trois de chaque, ordre tiré), 1,5 s pour « Trois coups. » (trois attaques), « Pare. » (la touche de charge),
« Côté. » (un pas de 0,8 m de travers). La Grue : Willem fend de côté, annoncé 0,6 s (garde `pare`, cercle au sol) ; la
touche de charge pressée dans les 0,2 s avant l'impact puis une attaque en 0,7 s : Grue (Willem recule) ; trois
Grues : Seniorious tourne et plonge dans `marais_epee`. Échec : douze fends sans trois Grues ou 150 s : Chtholly
s'assoit. Au récit : « entrainement_seniorious » → `play_story_seniorious(params)` (start_stage, pickup, place_player,
seed, overrides, success_flag : posé si réussi, retiré sinon).

**(E8b) Willem au Carillon** — tenue « duel » de Willem (`data/npcs/outfits/willem_duel.tres`) : la planche de
remplacement `assets/characters/willem/willem_duel*.png` (repos, marche, parle avec Percival sur l'épaule ; attaque
`coup` [2] ; pare), tirée de willem_home par `python3 tools/gen_placeholders.py duel` (tools/gen_duel_sheet.py, qui
dessine aussi `src/games/fx/seniorious.png`), en attendant la vraie (cahier n° 6, C.10). Démonstration :
`tests/integration/demo_e8b.tscn` (`E8B_VIEW=duel|duel_reprise|seniorious|seniorious_grue`, `E8B_SEQUENCE=<dossier>`,
`E8B_STEP`, `E8B_COUNT` : une image toutes les 0,5 s ; un joueur automatique par les vraies actions) ; raccourcis
`?jeu=duel`, `?jeu=seniorious`. Mesures (Xvfb, Mesa logiciel) : duel 104 à 124 draw calls (124 au plus, la vision et
la reprise comprises), entraînement avec Seniorious 60 à 117 : sous 200.

**L'arme** — `Player.set_weapon(&"baton" | &"seniorious")`, `Player.weapon()` (PlayerCombat : voir le contrat
ci-dessus). Par défaut **Seniorious** (l'ancienne île et ses Timeres gardent l'épée et la charge) : c'est le
récit (E6) qui donne le bâton au début de l'acte 1 (`set_weapon(&"baton")`) et Seniorious aux scènes qu'il
désigne (duel, entraînement spécial, colline). L'arme n'est pas dans GameState : à refaire au chargement
d'une partie (`EventBus.game_loaded`). Bâton en main : les trois coups de `data/attacks/stick_1..3.tres`
(mêmes chiffres que l'épée : la faune de E5 reste combattable, un animal vaincu s'enfuit), **pas de charge**
(`can_charge()` faux) ; la touche de charge (clic droit, L2/gâchette) tient la **parade** (`is_guarding()`,
`guard_changed`), qui interdit de frapper tant qu'elle est levée. Animation de la parade : `pare`
(`data/attacks/stick_guard.tres`) si la planche l'a, sinon la charge, image 0. **Sans planche `_stick`**
(cahier n° 5, lot R2) : le bâton garde l'animation d'épée (`attaque`) et n'est pas dessiné en main ; les
planches `_stick` demandent `pare` (2 images, 2 ips, boucle) et un `mort` assis sans blessure.

**Le ballon (src/life/games/ballon.gd, class BallMatch ; base : src/games/ball_play.gd)** — un jeu `ballon`
sur le cadre de LifeGame (activité `ballon` d'activities.json, `game: "ballon"`) :
- *Groupe* : les PNJ dont la ligne nomme l'activité `ballon` à la même place (`champ_centre` : une place d'un
  seul point suffit) ; la clé `role` de leur ligne donne l'équipe (`rouge`, `blanc`) ou l'arbitre (`arbitre`),
  sans rôle : à l'équipe qui en a le moins. `LifeGame.assign_teams(équipes, except_roles)` répartit. Il faut
  `min_members` (6) ; on attend les retardataires `assemble_wait` s avant de composer les équipes.
- *Terrain* : `field/width` × `field/length` (18 × 20 m) centré sur la place ; les places `champ_but_nord`
  (cages des blanches, qui défendent le nord en première mi-temps) et `champ_but_sud` donnent le poste des
  gardiennes. Le ballon est un `GameBall` (src/games/ball.gd, `top_level`, ajouté à `Life`) ; le ballon
  décoratif du plan (un panneau fondu au rond central) en est retiré à l'exécution (`GameBall.hide_decor_ball`).
- *Équipes* : au plus `team_size` (5) sur le terrain, une gardienne chacune, les autres assises au bord ouest
  (le banc, `assis`) ; à la mi-temps on change de côté, les meilleures buteuses restent (`keep_top_scorers`) et
  les remplaçantes entrent. Un anneau au sol (`TeamRing`, rouge ou blanc) marque l'équipe de qui joue.
- *Déroulé* (`BallMatch.Phase`) : ASSEMBLE → GATHER (on s'aligne) → KICKOFF (l'arbitre : « Coup d'envoi ! ») → PLAY
  (2 × 180 s ; un but : GOAL, 3 s, remise en jeu par l'équipe qui l'a encaissé ; le ballon perdu : LOST) →
  HALFTIME (8 s) → ... → ENDED (`match_finished`, puis `finish()` ; le groupe se disperse au créneau suivant).
- *IA* : toutes les 0,25 s, chaque petite choisit : la ou les deux plus proches du ballon (avec un avantage à
  qui l'a le moins touché : le jeu de Willem, V1) courent après lui, les autres tiennent leur poste en suivant
  le ballon ; au pied, elle tire près des cages, passe (de préférence à qui a le moins touché), dribble ou le
  lance haut à deux mains (`lance` : il retombe au hasard à 6 m), avec une erreur de visée ; elles tombent
  (`tombe`) en courant ou en se bousculant ; la gardienne arrête trois tirs sur quatre et dégage un ballon qui
  traîne. Les marches sont `LifeActor.walk_to(..., direct)` ; `LifeActor.stuck_time` à 3,5 s : jamais coincées.
- *Le ballon* : image claire `assets/hd2d/interior/props/ball_white.png` agrandie à 0,4 m, ombre nette au sol
  (`ball/image`, `ball/size_m`, `ball/shadow_radius`) : lisible sur l'herbe sèche.
- *Pas de conversation pendant le jeu* : `LifeGame.blocks_talk()` (vrai pour le ballon tant que le joueur y joue,
  pour l'entraînement jusqu'à sa fin) ; `LifeActor.talk_blocked()` ; `Npc.get_prompt()` rend alors `""` et
  `Npc.interact` ne fait rien ; tout revient quand le jeu s'arrête.
- *Le ballon perdu* : frappant le mur est près de `fourre_ballon`, il se perd dans le fourré une fois sur deux ;
  une petite va le chercher (`saut`, puis `lance`), ou le joueur, en y entrant (`thicket/player_reach`).
- *Le joueur* : il entre en entrant dans le champ (`player/join_margin`, 1,5 m du bord), rejoint l'équipe qui a
  le moins de joueuses (les blanches à égalité : une petite lui laisse sa place sur le banc), frappe avec la
  touche d'attaque (`LifeGame.on_player_attack` : le ballon part dans sa visée s'il est à 1,6 m devant, sans mal
  pour personne), pousse le ballon en courant contre lui, sort à `player/leave_margin` (4,5 m) ou par
  `leave_player()`. Un score sobre (`GameScore`, une ligne en haut de l'écran) s'affiche tant qu'il joue.
  (QC2) `GameScore` ne couvre jamais le coin haut gauche du HUD (`HUD.top_left_rect()`, groupe `hud` :
  cœurs et jauge de charge) : centré s'il y a la place, poussé à droite du coin, replié sinon.
- *Événements* (`LifeGame.event`) : `match_started`, `kickoff`, `goal [équipe, marqueuse, score]`, `save`,
  `kick [qui, sorte]`, `fall`, `half_time`, `ball_lost`, `ball_found`, `player_kick`, `match_ended [résultat]`.

**L'entraînement (src/games/staff_training.gd, class StaffTraining, un Node3D ajouté à `Life`)** — au pas de
`advance(delta)` (le nœud s'avance seul à chaque image physique ; les tests le coupent). La **parade est la
touche de charge** bâton en main (pas de nouvelle action : project.godot ne change pas). Phase A : un coup toutes
les 1,2 s (0,8 s au bout de 60 s), annoncé 0,5 s avant (cercle au sol, flèche, posture de Willem) ; **bloquer** =
parade tenue à l'impact ; **dévier** = parade relâchée dans les 0,15 s avant (la garde de Willem s'ouvre 0,5 s) ;
**esquiver** = hors du cercle (0,9 m) ; coup reçu = enchaînement à zéro et une touche de plus (jauge 6) ; la
fenêtre rétrécit d'un cinquième toutes les 30 s ; à 90 s Chtholly s'assoit (`Player.hold_pose`, `assis`, sinon
`degats`) ; réussite : 12 réponses de suite dont 3 déviations. Phase B : les aînées se lèvent et se placent de
part et d'autre de Willem ; elles l'attaquent toutes les 2 à 3 s, il contre toutes les 2 s l'une des trois
(annoncé 0,4 s avant ; sur Chtholly : esquive ou déviation, la parade tenue n'y suffit pas ; une déviation
d'une aînée ou de Chtholly découvre Willem 0,4 s) ; réussite : tenir 60 s avec trois contres au plus, ou
toucher Willem découvert d'un coup de bâton (`touch_reach`, `touch_arc_deg`). **Aucun vrai dégât** : jamais de
`Health` touchée ; les PNJ sont menés par l'exercice (`LifeActor.state = GAME`, un `Hush` muet : leur parler ne
fait rien) et rendus à leur emploi du temps (`end_time` s après la fin). Variante du jour 10 : phase A seule.

**Données** : `data/games/ballon.json` (durées, terrain, balle, frappes, IA, chutes, gardiennes, fourré, boue,
joueur) et `data/games/staff_training.json` (rythme, fenêtres, fatigue, réussites, variantes, animations,
chacun avec un `_comment`) ; `GameRules.value(jeu, "kick/reach", défaut, surcharges)` / `number()` /
`problems()` ; l'activité `ballon` peut surcharger des chemins par ses `params` ; les répliques :
`data/texts/life.json`, `games/ballon/…` et `games/baton/…` (`{player}` accepté).

**Mesures** (après la fusion de V1, quinze PNJ sur la carte). Natif (Xvfb, Mesa logiciel), vue du jeu au plus
fort du match (dix petites, l'arbitre, le joueur dans la partie, score compris) : 125 draw calls, 144 au plus
(ballon) ; 111 à 127 au plus (spectateur, banc) ; 94 à 111 (entraînement), 130 au plus (phase B) : sous 200. Le
match pose 35 objets dessinables de plus que la carte seule ; directeur 0,4 ms par image (9 à 21 ms au plus, aux
changements d'équipe). Build Web (`tools/web_jeux.js`, Chromium sans GPU, SwiftShader : 0,3 à 0,9 image/s, les
images/s ne valent pas dans l'absolu) : ballon 95 draw calls (97 au plus), entraînement 99 (107 au plus).

**Pièges.** Un test qui lance un match règle le créneau (`LifeDirector.set_slot`) *avant* d'entrer dans la
carte ou appelle `LifeDirector.refresh(false)` : sinon le directeur applique le créneau à l'image suivante et
renvoie les joueuses à leur emploi du temps. Les tests avancent le jeu à la main (`LifeDirector._physics_process(1/60)`
et `StaffTraining.advance`) : deux minutes de match en une seconde. GDScript : une classe de plus de 1000
lignes échoue au lint : BallMatch hérite de BallPlay. Le ballon du décor fondu n'est retiré qu'à l'exécution
(docs/CONTRACT_REQUESTS.md, « E8 »).

### (E7) Les navires : le transport de la Garde, le Barocupot, et leur API pour le récit

Ce que le récit en demande (docs/lore/ACTE1.md, 6, ligne E7 ; CARTE.md 6.2 et 6.3) : le **transport de la Garde**
ne paraît qu'au crépuscule du jour 7 (scène 7.4 : il descend, s'amarre aux bras du port, ouvre sa trappe, pose
sa passerelle, puis repart) ; le **Barocupot** n'est vu que de l'intérieur (8.7) et comme une **ombre dans les
nuages** (8.6). Hors des scènes, le poste d'amarrage du port est **vide**. Décisions : docs/DECISIONS.md (« E7 »).

**Le navire en volume** (`src/world/ships/`, propriétaire E7) — un assemblage de panneaux, jamais un maillage :
`Ship` (racine de `src/world/props/ships/<id>.tscn`, origine : la quille au milieu du flanc sud, proue à l'est)
et ses enfants nommés `Hull` (le flanc, `ships/<id>_side`), `Deck` (le pont vu de dessus, couché derrière le
flanc), `Rotors/*` (bandes sur les moyeux), `Hatch` (la trappe), `Searchlight` et `Glare` (le projecteur et
l'éblouissement, alpha doux), `Gangway` (pivot au seuil de la trappe ; `Ramp/Tread`, un Building, et sa
`Collision`, active une fois posée) et `Collision` (la coque). `ShipStrip` (un `DecorPanel`) est une bande dont
l'image est choisie par le code (rotors qui ralentissent, trappe, bras) et dont l'opacité varie (alpha doux) :
jamais sous `Geometry` (le PropBatcher figerait l'image). `ShipBerth` est le **poste d'amarrage** d'une carte (au
port : le nœud `Berth`, écrit par `tools/exterior_recipes/port.py`, *après* les sorties) : il tient le navire,
les bras d'ancrage (`Arms/BrasAncrage1..3`, la bande `anim/mooring_arm_clamp`, image 0 = le bras ouvert), la
porte du vide devant la passerelle (`Gate`) et règle la sortie `Exits/passerelle`. Les données (durées,
vitesses, hauteurs) : `data/ships/<id>.json` (`transport_garde.json` : descent, searchlight, mooring, rotor,
hatch, gangway, departure ; `barocupot.json` : shadow).

**L'API du récit** — `ShipControl` (src/world/ships/ship_control.gd, fonctions statiques ; ni autoload ni PR
« contrats »). Chaque action est une ligne de temps du poste de la carte chargée, jouée à l'image physique ;
sans poste dans la carte (le récit est ailleurs), seul l'état change. L'**état** (à quai, trappe, passerelle,
embarquement) est dans les drapeaux de GameState, `ship_<id>_docked|hatch|gangway|boarding` (sauvegardés) : une
carte du port chargée plus tard le retrouve.

```gdscript
await ShipControl.descend(&"transport_garde")         # le projecteur perce les nuages et aveugle, il descend
                                                      # en roulant un peu, les bras se referment de la poupe à
                                                      # la proue, les pales ralentissent : à quai (~14 s)
await ShipControl.open_hatch(&"transport_garde")      # la trappe s'ouvre sous la pression (~0,8 s)
await ShipControl.deploy_gangway(&"transport_garde")  # la passerelle sort et se pose sur le quai (1,6 s) :
                                                      # le bord du vide s'ouvre devant elle, on y marche
await ShipControl.stow_gangway(&"transport_garde") ; await ShipControl.close_hatch(&"transport_garde")
await ShipControl.depart(&"transport_garde")          # rentre la passerelle, ferme la trappe, ouvre les bras
                                                      # de la proue à la poupe, relance les pales, remonte
ShipControl.dock(&"transport_garde")                  # à quai d'un coup (une scène qui commence navire posé)
ShipControl.pose(&"transport_garde", &"deploy_gangway")   # un état d'un coup : absent, docked, open_hatch,
                                                          # deploy_gangway (captures, reprise)
ShipControl.allow_boarding(&"transport_garde", true)  # « Monter à bord » au pied de la passerelle posée ;
                                                      # jamais à l'acte 1 (CARTE.md 6.2)
await ShipControl.pass_shadow(&"barocupot")           # 8.6 : une silhouette sombre traverse la vue d'ouest en
                                                      # est dans les nuages, devant la caméra, en fondu (7 s) ; rend ShipShadow
ShipControl.play(id, action, wait) ; ShipControl.finish(id, action)   # générique ; finish : l'état final
ShipControl.is_docked(id), has_flag(id, &"hatch"), is_playing(id, action), berth(id), ship(id), data(id)
```

Signaux du poste (`ShipControl.berth(id)`) pour le son et le récit : `action_started(action)`,
`action_finished(action)`, `ship_event(event)` — `landed`, `clamp_1` … `clamp_3` (le lourd bruit de métal),
`moored`, `rotors_stopped`, `hatch_opened`, `gangway_down`, `gangway_up`, `released`, `gone`. Points pour la
scène, au port : `Life/Places/navire_quai` (pied de la passerelle), `Markers/navire_trappe` (le seuil de la
trappe, en haut de la passerelle posée, regard au sud), `Markers/navire_passerelle` (mi-pente),
`Markers/from_transport_garde` (le quai, regard au sud).

**L'étape « ship » des scènes** (data/scenes/ ; StoryData.STEPS) : `{"do": "ship", "ship": "transport_garde",
"action": "descend"}`, `"wait": false` pour ne pas attendre ; actions : `ShipControl.ACTIONS` (descend, dock,
open_hatch, close_hatch, deploy_gangway, stow_gangway, depart, clear, allow_boarding, forbid_boarding, shadow).
Une séquence passée pose l'état final d'un coup. Exemple pour la scène 7.4 (lot S2) :

```json
{"do": "ship", "ship": "transport_garde", "action": "descend"},
{"do": "ship", "ship": "transport_garde", "action": "open_hatch"},
{"do": "place", "who": "limeskin", "at": "navire_trappe"},
{"do": "ship", "ship": "transport_garde", "action": "deploy_gangway"},
{"do": "walk", "who": "limeskin", "to": "navire_quai"}, ...
{"do": "ship", "ship": "transport_garde", "action": "depart", "wait": false}
```

**Les cartes de bord** : `transport_garde` (dehors, `tools/exterior_recipes/transport_garde.py` : le pont
praticable au-dessus du vide, sa coque dessous, la passerelle vers une bande du quai ; « Descendre à quai » en
haut de la passerelle ; lieu `port`) ; `barocupot` (dedans, `tools/interior_maps.py` : la salle du conseil de
guerre, le sas de l'échelle, la coursive, avec les images du lot L ; « Remonter sur le pont » →
`entrepot:from_barocupot` ; objets à examiner, data/texts/barocupot.json ; lieu `ciel`, hors de la carte de
l'île). Au port, la sortie `passerelle` (« Monter à bord ») existe mais reste fermée (ni invite ni signe) tant
que le navire n'est pas à quai, sa passerelle posée et l'embarquement permis.

**Le sol** (E2) : `barrier_gaps` du plan.json d'une carte du dehors (`[[x, z, largeur, profondeur], …]`, recopié
dans map.json) ouvre la barrière invisible de la côte (MapGroundCoast) ; ce qui referme l'ouverture est à la
scène (le `Gate` du poste).

**Démonstration** : `tools/e7_shots.sh [descente|depart|cartes|ombre]` (tests/integration/demo_e7.tscn) : la
descente au crépuscule sous la pluie, une image toutes les 0,5 s de jeu, la trappe, la passerelle, le départ,
le pont, le Barocupot, l'ombre ; vues QC (`tools/qc_views.json`, clé `ships` d'une vue : id → état posé par
`ShipControl.pose`). Tests : tests/unit/test_ships.gd, test_transport_garde.gd, test_barocupot.gd,
test_port.gd ; tests/integration/test_ships_in_game.gd (on monte la passerelle, on embarque, on redescend).

## 4. Tranche verticale : WordEnd en HD-2D

La tranche verticale **recrée l'easter egg dans un monde en relief** ((HD-2D) personnages en sprites, décor en images, caméra fixe) (Chtholly contre des vagues de Timeres sur les dunes au couchant, mêmes règles, même score) **et l'entoure d'un début de monde** : un village sûr avec trois PNJ, une quête, des objets, et une forêt où quelques Timeres rôdent librement. Elle est jouable dans le navigateur à la fin du jalon M2 et fixe la sensation de combat pour tout ce qui suit.

(F1) Cette section décrit la tranche verticale telle qu'elle a été livrée sur l'ancienne île : l'île, ses zones, son arène et ses vagues, sa quête et ses objets sont retirés (docs/DECISIONS.md, F1). Restent valables les règles de combat, le joueur, la caméra, les visuels, les Timeres (permis là où les règles de l'île les admettent : la surface), le dialogue, l'inventaire et la sauvegarde ci-dessous (v4).

### Règles de combat reprises de l'easter egg

Les valeurs viennent de `jeu.js` et de `docs/wordend.md` du dépôt Yume-WordPress. Deux conversions : les **distances** à l'échelle du personnage (Chtholly debout = 72 px logiques = 1,5 m), les **vitesses** rapportées à la marche (72 px/s en 2D = 4 m/s en 3D, pour garder les mêmes rapports entre Chtholly et les Timeres). Elles vivent dans `data/attacks` et `data/enemies`, donc réglables sans code.

| Règle | Easter egg 2D | Transposition 3D (M2) |
| --- | --- | --- |
| PV de Chtholly | 5 ; 1 PV rendu toutes les deux vagues | Identique ; cœurs dans le HUD |
| Dégâts subis | 1 par morsure ou fouet, 1,2 s d'invincibilité, recul ; les ennemis n'ont pas d'invincibilité, un coup ne touche chaque cible qu'une fois | Identique ; clignotement 1,2 s, recul 3 m/s en s'éloignant de l'ennemi ; `invincibility_time` = 0 sur les ennemis |
| Coup d'épée | 1 dégât, touche sur les images 1 à 3 de l'animation `attaque` (4 images, 14 ips) | Enchaînement `sword_1` → `sword_2` → `sword_3` si la touche est répétée, 1 dégât chacun, arc de 90° et 1,2 m devant le joueur, le 3e coup repousse davantage |
| Charge magique | Maintenir 0,55 s puis relâcher : onde de 3 dégâts qui traverse, dure 0,42 s, recharge 1,2 s | Identique ; l'onde est un projectile de 8 m de portée, 2 m de large, qui traverse tous les ennemis ; jauge `charge_progress` dans le HUD |
| Vagues | Vague *n* = 3 + 2*n* Timeres, des deux côtés ; vitesse × (1 + 0,04 *n*), plafonnée à +50 % ; le Normal gagne 1 PV dès la vague 6 ; bonus 50 × *n* | Même formule, mêmes bonus (dans `generator` du JSON de vagues) ; les Timeres sortent de 4 points d'apparition autour de l'arène |
| Mort | Animation puis écran de fin avec score et meilleur score | Animation `mort`, fondu, score de l'arène comparé au meilleur, réapparition au `Spawn` du village avec PV pleins |
| Score | 10/15/20/40 points par type ; meilleur score en `localStorage` | Identique ; meilleur score par arène dans la sauvegarde |

| Timere | Échelle | PV | Vitesse 2D → 3D | Attaques | Points | Particularité |
| --- | --- | --- | --- | --- | --- | --- |
| Petit | 0,8 | 1 | 54 px/s → 3,0 m/s | morsure (portée 0,8 m) | 10 | — |
| Normal | 1 | 2 | 38 px/s → 2,1 m/s | morsure, fouet (portée 1,0 m) | 15 | — |
| Coureur | 0,9 | 1 | 112 px/s → 6,2 m/s | charge en ligne droite dès 8 m, puis morsure | 20 | dès la vague 2 |
| Grand | 1,3 | 5 | 28 px/s → 1,6 m/s | fouet longue portée (1,4 m) | 40 | dès la vague 3, un à la fois, ne recule que sous l'onde |

Les attaques ennemies ne touchent que sur leurs images `coup` (images 1 et 2 de `fouet` et `morsure`), comme dans le JSON de la planche `timere.json`.

### Scènes et comportements attendus

| Élément | Scène | Comportement M2 |
| --- | --- | --- |
| Joueur | `src/player/player.tscn` (`CharacterBody3D`) | Déplacement relatif à l'écran ((HD-2D) haut = nord : la caméra fixe ne tourne pas), course (Maj), saut, gravité, pente jusqu'à 45°, marche 4 m/s, course 7 m/s ; ZQSD/WASD + flèches + manette ; déplacement bloqué pendant `Combat.is_busy()` ; détection d'`Interactable` devant le joueur, touche E / bouton A |
| Combat joueur | `src/combat/player_combat.gd` (enfant `Combat` du joueur) | Épée J/X ou bouton X ; charge K/C ou bouton B maintenu ; `Hitbox` de l'épée activée par `frame_changed` sur les images `coup` ; `Health` 5 PV ; recul ; mort et réapparition |
| Caméra | `src/player/camera_rig.tscn` (`Camera3D` + `PostFX`) | (HD-2D) Fixe, à la manière d'*Octopath Traveler* : regarde le nord, inclinée de 32°, champ vertical de 30°, à 21 m du point visé (2,5 m au nord du joueur, qui se tient sous le milieu de l'écran) ; cadrage constant (ni tangage ni recul automatiques) ; suit la place affichée du joueur (lissage physique) avec un léger retard (et un peu en avant de sa marche, sans à-coup), bornée à l'île ; molette ou stick droit : léger zoom (14 à 25 m) ; **verrouillage de cible** (clic molette / R3) : le point visé avance vers la cible, le joueur lui fait face ; post-traitement sous l'interface : flou de profondeur, lueur, étalonnage chaud |
| Visuel | `src/visuals/character_visual.tscn` | `AnimatedSprite3D` billboard axe Y (face à la caméra fixe), 7 animations de la planche (`repos`, `marche`, `course`, `attaque`, `charge`, `degats`, `mort`), (HD-2D) `parle` pour les PNJ en conversation, retournement gauche/droite selon la direction, ombre disque ; `frame_changed` et `animation_finished` |
| Timeres | `src/enemies/enemy.tscn` + `data/enemies/timere_*.tres` | Machine à états : `idle` (errance) → `chase` (droit vers le joueur, séparation entre ennemis) → `attack` à portée (morsure/fouet, dégâts sur images `coup`) → `hurt` (recul 0,35 s, sauf Grand) → `dead` (animation 6 images, disparaît après 2,2 s, points). Coureur : `rush` en ligne droite dès 8 m |
| Arène des dunes | `src/world/zones/dunes/dunes.tscn` + `src/enemies/arena.tscn` | Zone ouest, coucher de soleil (ciel inspiré de `decor.webp`), 4 points d'apparition, `WaveDirector` lisant `data/waves/dunes.json` ; un panneau `Interactable` lance les vagues et la musique (invite « Sonner la cloche de veille », titre de fin « Fin de la veille » : `data/texts/story.json`) ; sortir de l'arène entre deux vagues met fin à la série et enregistre le score |
| Forêt | `src/world/zones/forest/` | 4 Timeres (2 petits, 1 normal, 1 coureur) en libre, sans vagues ; tués, ils restent morts jusqu'au rechargement de la partie, sauf pendant une étape « vaincre » qui les vise (rejetons de l'acte 1) : ils reviennent quand elle commence et quand le joueur rentre dans les bois ; (Systèmes et textes) noms de l'acte 1 (rejeton, fragment, Timere bondissant, grand fragment) et aucun drop : Timere ignore les objets (V3) |
| Île | `src/world/island.tscn` | Île flottante de 160 × 160 m (relief calculé, places de HISTOIRE.md 3.3 garanties) : village (centre), dunes (ouest), forêt (nord), port (sud), colline (est). (HD-2D) Sol en tuiles de pixel art mélangées par zone et par masque (atlas `assets/hd2d/ground/atlas/ground_atlas.png`, `terrain.gdshader`), falaises et dessous texturés (`rock.gdshader`), bâtiments en volumes avec façades en images (`Building`), décors en panneaux avec ombre douce (`DecorPanel`), fondus par image (`PropBatcher`), ciel panoramique, mer de nuages texturée, lanternes éclairées ; murs invisibles et rattrapage sous l'île |
| Zones | `src/world/zones/*` | Chaque zone = scène fille avec `Area3D` qui émet `zone_entered` ; `WorldManager` charge toutes les zones au départ en M2 (streaming en M3) ; le village est une zone `safe` où aucun ennemi n'entre |
| PNJ | `src/npc/npc.tscn` | (acte 1) les PNJ de docs/lore/HISTOIRE.md 3.3 dans les cinq zones (Nygglatho, Willem et les fées à l'entrepôt, Pannibal aux bois, le guetteur au Couchant, Limeskin et les gens du bourg au port), visuels non jouables `data/npcs/visuals/` ; présents selon l'histoire (`NpcData.visible_if`) ; regardent le joueur à moins de 4 m ; `interact()` lance `DialogueRunner` |
| Dialogue | `src/ui/dialogue_box.tscn` + `src/npc/dialogue_runner.gd` | (U1) Nuit douce ou Bandeau (`DialogueBox.set_presentation`) ; boîte en bas d'écran, portrait (celui de l'orateur du nœud, `speaker_id`), texte lettre par lettre, choix (2 max), conditions sur `flags`, `count` et état de quête ; `{player}` : prénom de la protagoniste (skin choisi) |
| Objets | `src/items/pickup.tscn` | Objet flottant, ramassage par `interact()` ou contact ; émet `item_collected` ; les drops des ennemis restent possibles (`EnemyData.drops`), mais les corps de Timere n'en ont aucun |
| Quête | `src/quests/quest_tracker.gd` | (acte 1, docs/lore/HISTOIRE.md 3.1 et 3.2) la quête principale `act1_main`, « Dans la forêt céleste » (13 étapes, de Nygglatho sous le porche à la promesse sur la colline ; récompense : la promesse du gâteau au beurre, PV max portés à 6) et six quêtes secondaires. (Lot Q) Quêtes en étapes écrites en JSON (`data/quests/`), journal de quêtes, marqueurs « ! » / « ? » : docs/QUETES.md |
| HUD | `src/ui/hud.tscn` | Cœurs, jauge de charge, numéro de vague et score dans l'arène, nom de la zone à l'entrée, (U1) signes d'interaction posés au-dessus des cibles, objectif de quête |
| Inventaire | `src/ui/inventory.tscn` | Grille d'icônes, touche I / bouton Y, quantité, description |
| Menu | `src/ui/main_menu.tscn` | Choix du skin (vignettes, « Ta fée prend la place de Chtholly dans l'histoire. »), Nouvelle partie / Continuer, crédits ; écran « Cliquer pour jouer » avant tout son |
| Sauvegarde | `SaveManager` | Auto-sauvegarde à `arena_finished`, `item_collected`, `quest_updated`, `zone_entered` ; chargement au menu (pas de sauvegarde « à la fermeture » : le navigateur ne la garantit pas) ; (M2) position écrite toutes les 5 s de jeu si le joueur a bougé, et au départ (focus perdu, page masquée) quand l'état a changé |

### Format des vagues

(F1) Retiré avec l'arène de l'ancienne île (`data/waves/`, `WaveDirector`).

### Format du sol des cartes extérieures (refonte, lot E2, `data/maps/<map_id>/`)

Le sol d'une carte extérieure (le nœud `Ground` d'une `Map`, un `MapGround` : section 3) est
**décrit par des données, peintes en images**, et bâti au chargement (moins de 50 ms pour une
carte de 80 × 60 m). Repères de la carte : origine au coin nord-ouest, x vers l'est, z vers le
sud ; **un pixel = une case de 1 m** ; la case (i, j) couvre [i, i + 1] × [j, j + 1].

| Fichier | Contenu |
| --- | --- |
| `map.json` | `format` (`"map_ground"`), `version` (1), `size` [largeur, profondeur], `palette` (couleur `#rrggbb` → matière), et en option : `heights_image`, `materials_image`, `structures_image` (noms des images), `height_step_value` (16), `height_zero_value` (0), `materials_scale` (1, 2 ou 4 pixels par mètre), `materials` (matières propres à la carte, ou surcharges), `edges` (`north`/`east`/`south`/`west` : `void` le bord de l'île, `land` le sol continue, défaut), `skirt` (16 m de sol prolongé au-delà d'un bord `land`), `barrier` (vrai), `spawn` [i, j] (départ des vérifications d'accès). Une clé inconnue est une erreur (`_commentaire` permis). |
| `heights.png` | Un pixel par case. **Transparent = le vide.** Gris (rouge) R : palier (R − `height_zero_value`) / `height_step_value`, de **0,5 m** chacun (16 par palier : 0 noir = 0 m, 16 = 0,5 m, 48 = 1,5 m…). La hauteur peinte sous un escalier ou une rampe est ignorée. |
| `materials.png` | `materials_scale` pixels par mètre, une couleur de la palette par pixel. Matières de `data/maps/ground_materials.json` (chacune : tuile de l'atlas du sol, couleur de peinture, et en option teinte, alternance `_b`, bord `soft` tramé ou `sharp` net, `path` chemin, `walkable`, `ripple` eau qui ondule, `border` bordure) : `herbe`, `herbe_haute`, `prairie`, `sous_bois`, `feuilles`, `mousse`, `terre_battue`, `sentier` (bordé de pierres), `gravier`, `paves`, `dalles`, `planches`, `tole`, `boue`, `tourbe`, `potager`, `eau` (dormante, **non praticable** : une barrière la borde), `lit_ruisseau`, `sable`, `roche`. |
| `structures.png` | Facultative, un pixel par case, transparent ou noir = rien. Couleurs de la bibliothèque : **escalier** qui monte vers le nord, l'est, le sud ou l'ouest (`#e02020`, `#e06020`, `#e0a020`, `#e02080`), **rampe** (`#2040e0`, `#2080e0`, `#20c0e0`, `#6020e0`), et **style des faces qui descendent de la case** : muret `#404040`, roche `#806040`, talus `#40a040`. |
| `plan.json` | Facultatif, lu par `tools/map_build.py gen` seulement (pas par le jeu) : la description d'où sortent les trois images et `map.json`. |

**Le relief.**
- Entre deux cases de paliers différents, une **face verticale** sur la ligne de la grille,
  tournée vers la plus basse : **talus de terre** jusqu'à 0,5 m (`assets/hd2d/cliff/bank_earth.png`
  puis la terre de potager), **falaise de roche** au-delà (`lip.png` sur le premier mètre, puis
  `cliff.png`), ou le style imposé par `structures.png` (**muret** : `wall_stone_b.png`). Les
  faces tournées vers le nord, que la caméra fixe ne voit jamais, ne sont que dans la collision.
- **Escalier** : une volée = des cases d'escalier à la suite dans leur sens de montée ; elle relie la
  case plate d'avant (le bas) à la case plate d'après (le haut, plus haute), en **vraies marches de
  0,1 m** (la capsule du joueur les monte sans sauter), contremarches dans la tuile de la matière
  peinte sous l'escalier, joues en muret. **Rampe** : même règle, plan incliné. Pente de **40° au
  plus** (une case par palier : 26,6°). Une volée large = des colonnes voisines de même profil.
  Escalier et rampe restent à 2 m au moins du vide et ne touchent pas le bord de la carte.
- Une marche de 0,5 m sans escalier se saute (le joueur saute 1 m) ; plus haut, c'est une falaise.
  **Un chemin (`path`) ne franchit jamais plus de 0,5 m sans escalier ni rampe** (vérifié).
- **La côte** (bord du vide) n'est pas en escalier : une ligne irrégulière (champ lisse tiré des cases
  vides, plus un bruit), qui déborde jusqu'à une case sur le vide. Dessous : la lèvre, la falaise et
  le rideau de roche qui se resserre jusqu'à 38 m sous l'île, la mer de nuages (`CloudSea`), une
  barrière invisible (on ne tombe pas). Les bords `land` ont aussi leur barrière : une sortie
  (`MapExit`) se pose en deçà du bord.
- **Le sol** : un draw call (tuiles de l'atlas à 96 px/m, bords tramés, bordures, eau qui ondule,
  lèvre de pierre et liseré sombre au bord du vide, ombres portées des falaises et ombre de contact à
  leur pied) ; **les faces** : un draw call ; la **mer de nuages** : un. La collision est faite des
  triangles mêmes du sol et des faces : on marche exactement sur ce qu'on voit.

**Mode d'emploi : dessiner une carte.**
1. Créer `data/maps/<map_id>/plan.json` (modèle : `data/maps/essai_relief/plan.json`) : `size`,
   `edges`, `base` (palier et matière de départ), `spawn`, puis `steps`, appliqués dans l'ordre :
   `level` (palier), `void` (le vide), `material`, `path` (bande le long de `points`, `width`),
   `stairs` et `ramp` (`rect` [x, z, largeur, profondeur] de cases, `dir`, `material` facultative),
   `face` (`wall`, `rock`, `earth` sur les cases hautes d'une falaise). Formes : `rect`, `poly`,
   `ellipse` [cx, cz, rx, rz], `band` ; `noise` (m) et `noise_scale` brouillent leur bord ; `where`
   (`level`, `levels`, `material`, `not_material`) restreint une opération. (T1) Des paliers sous
   le sol courant (−0,5 m : champ, marais de l'entrepôt) demandent `height_zero_value` (16 : le
   palier −1 est le gris 0), recopié dans `map.json`.
2. `python3 tools/map_build.py gen <map_id>` écrit `map.json`, `heights.png`, `materials.png` et
   `structures.png` et vérifie la carte ; `python3 tools/map_build.py view <map_id>` en fait la vue de
   dessus (`build/maps/<map_id>_dessus.png`) ; `check` revérifie (toutes les cartes sans argument).
   On peut aussi peindre les images à la main (pixels purs, sans anticrénelage), puis `check`.
3. `tools/import.sh`, et commiter les images avec leurs `.import`.
4. La scène `src/world/maps/<map_id>/<map_id>.tscn`, selon « (E1) Créer une carte » (section 3 ;
   modèle : `src/world/maps/essai_relief/essai_relief.tscn`) : racine `Map`, `size` = `size` de
   `map.json`, `camera_bounds`, la lumière (`src/world/map_light.tscn`, en attendant E9) ; `Ground`
   est un `StaticBody3D` au script `src/world/map_ground.gd` (rien d'autre à régler : il lit
   `data/maps/<nom de la Map>/`). Les décors vont dans `Geometry` à la hauteur de leur palier
   (`MapGround.height_at`, ou la vue de dessus) ; un décalque au sol (`GroundDecal`) suit le relief
   de lui-même. Les marqueurs (`Spawn`, `from_<carte>`) et les sorties se posent sur des cases
   praticables, en deçà de la barrière des bords.
5. Vérifier : `tools/test.sh tests/unit/test_map_ground_data.gd` (chaque carte de `data/maps` au format
   du sol en relief s'y lit sans problème), `tools/test.sh tests/unit/test_maps.gd` (la `Map`) et des
   captures dans la vraie partie (modèle : `tests/integration/demo_e2_relief.gd`, qui instancie
   `game.tscn` puis `WorldManager.enter_map` ; `E2_VIEW=<vue> tools/screenshot.sh
   res://tests/integration/demo_e2_relief.tscn build/shots/e2_<vue>.png 60`).

### Format de dialogue (JSON)

```json
{
  "id": "nephren_book",
  "start": "hello",
  "nodes": {
    "hello": {
      "speaker": "Nephren",
      "text": "Livre. Vent. Pages.",
      "next": "ask"
    },
    "ask": {
      "speaker": "Nephren",
      "text": "Cinq pages, dans les bois. Pour la lecture du soir.",
      "choices": [
        { "text": "Je les trouve.", "set_flag": "picture_book_asked", "next": null },
        { "text": "Plus tard.", "next": null }
      ]
    },
    "done": {
      "if": { "count": ["page_fragment", 5] },
      "speaker": "Nephren",
      "text": "Cinq. Merci. Maintenant, un lecteur.",
      "take_item": ["page_fragment", 5],
      "next": null
    }
  }
}
```

`DialogueRunner` choisit le premier nœud dont la condition `if` est vraie parmi `["done", entries…, start]`. Les conditions acceptées : `flag`, `not_flag`, `count` (objet, minimum), (E6) `day`, `slot`, `scene`, `not_scene` ; les effets : `take_item`, `give_item`, `set_flag`, `clear_flag` ; clés vérifiées à la lecture ; liste complète et ordre d'évaluation : docs/DIALOGUES.md. (F1) Les conditions `quest`, `quest_step`, `not_quest_step`, `best_score` et les effets `start_quest`, `advance_quest`, `complete_quest` sont retirés avec le moteur de quêtes. (Systèmes et textes) Clé de nœud `speaker_id` (portrait et nom par défaut d'un autre PNJ : scènes à plusieurs voix), jeton `{player}` (prénom de la protagoniste : nom affiché du skin choisi sans sa variante « · 3D », premier mot) dans les répliques, les choix et `speaker` ; la même grammaire décide de la présence des PNJ (`NpcData.visible_if`).

### Sauvegarde (JSON, `user://save_v1.json`)

```json
{
  "version": 4,
  "saved_at": "2026-10-16T10:00:00Z",
  "skin": "chtholly",
  "max_hp": 5,
  "position": [20.0, 0.2, 16.0],
  "map": "entrepot",
  "inventory": { "page_fragment": 3 },
  "flags": { "met_willem": true },
  "collected_pickups": ["entrepot_bougie_1"],
  "moment": "couchant",
  "weather": "clair",
  "island": "ile_68",
  "known_islands": ["ile_68"],
  "day": 2,
  "slot": "matin",
  "scenes_done": ["j1_1_port"],
  "calendar": { "1": "" },
  "story_scene": ""
}
```

(F1) Schéma v4 : sans `zone`, `quests`, `quest_progress`, `tracked_quest` ni `best_scores` (l'ancienne
île, ses quêtes et son arène sont retirées). Le nom du fichier ne change pas.

- Une partie de l'ancienne île — versions 0 à 2 (dont le `localStorage['yn.wordend']` de l'easter
  egg et la vraie sauvegarde d'avant la refonte, `tests/data/saves/save_v2_avant_refonte.json`), ou
  v3 hors de l'acte en jours (`day` absent ou 0) — ne se reprend pas : `load_game()` la copie à côté
  (`legacy_backup_path()`, `user://save_v1.json.ancienne`), démarre une nouvelle partie de l'acte 1
  avec son skin et pose `SaveManager.notice` (« Ta partie se passait sur l'ancienne île, qui
  n'existe plus : l'histoire reprend au premier jour. », `data/texts/story.json`, `save/migrated`),
  que le menu affiche au chargement ; rien ne plante, `load_game()` renvoie OK.
- Une partie v3 de l'acte en jours passe en v4 sans perte (les champs de l'ancienne île sont
  retirés) ; une carte inconnue au chargement ramène au Spawn de `WorldManager.START_MAP`.
- (E1) `map` : la carte courante (`position` est dans son repère). (E9) `moment`, `weather` ; (X1)
  `island`, `known_islands` ; (E4) `day`, `slot` ; (E6) `scenes_done`, `calendar`, `story_scene` :
  champs facultatifs (absents : valeurs par défaut). Mal typés : la sauvegarde est refusée.

`collected_pickups` liste les `name` uniques des `pickup` déjà pris.

### Critères d'acceptation de la tranche verticale

- [ ] Le build Web se charge en moins de 10 s sur une connexion fibre, sans erreur console.
- [ ] **Combat** : un coup d'épée ne touche que sur ses images `coup` ; l'onde traverse plusieurs Timeres ; le Grand ne recule que sous l'onde ; le joueur ne subit pas deux dégâts en moins de 1,2 s.
- [ ] **Arène** : la vague 5 est atteignable par un joueur moyen ; la vague 3 fait apparaître un Grand, jamais deux à la fois ; le score et le bonus 50 × *n* correspondent à l'easter egg.
- [ ] Mourir dans l'arène ou la forêt ramène au village avec PV pleins et conserve inventaire et quêtes ; le meilleur score est gardé.
- [ ] 60 images/s sur un portable de bureau courant avec 12 Timeres à l'écran, 30 sur un téléphone récent.
- [ ] On peut jouer la quête principale de l'acte 1 de bout en bout (dialogues, bois, veille, promesse et sa récompense) au clavier et à la manette (au jalon M2 d'origine : la quête des pages) ; recette : docs/RECETTE_M2.md.
- [ ] Fermer l'onglet puis revenir restaure position, inventaire, quête et meilleur score.
- [ ] Les 5 zones déclenchent leur nom dans le HUD ; aucun ennemi n'entre dans le village ; aucun endroit ne laisse tomber le joueur hors de l'île.
- [ ] Tests GUT verts sur `Health`, `AttackData`/hitbox, `WaveDirector`, `GameState`, `SaveManager`, `DialogueRunner` et `QuestTracker`.

## 5. Assets et placeholders

**Règle : aucun lot n'attend un asset.** Chaque élément visuel a un remplaçant généré par script le jour même, et un chemin de remplacement défini pour qu'un vrai asset se branche sans toucher au code.

### Trois niveaux, du plus rapide au plus beau

| Niveau | Personnages et ennemis | Décor | Quand |
| --- | --- | --- | --- |
| **P0 – planches existantes + généré** | `chtholly.png/.json` (7 animations : repos 2, marche 6, course 5, attaque 4, charge 4, dégâts 1, mort 1) et `timere.png/.json` (repos 5, marche 4, course 6, fouet 4, morsure 4, dégâts 5, mort 6), copiés depuis `wp-content/plugins/yume-core/includes/wordend/assets/` de Yume-WordPress ; les autres skins et les PNJ = silhouettes produites par `tools/gen_placeholders.py` avec les mêmes animations (et `parle` pour les PNJ) | (HD-2D) Images de remplacement en pixel art générées par `tools/hd2d_assets.py` (tuiles de sol, falaises, matières et façades des bâtiments, décors en panneaux, ciel, horizon), aux chemins et tailles exacts de `tools/hd2d_manifest.json` | En place (HD-2D) |
| **P1 – images commandées** | Planches dessinées ou générées (ChatGPT) puis découpées par `tools/wordend/decouper-planche.py` (Yume-WordPress), même JSON : d'abord Chtholly de l'acte 1, les PNJ, le corps de Timere (`docs/ASSETS_HD2D.md`, section 3) | (HD-2D) Les images de `docs/ASSETS_HD2D.md` (sections 4 à 9), déposées au chemin de leur remplaçant, vérifiées par `python3 tools/hd2d_assets.py check` ; musique `Scarborough Fair` convertie en OGG | Lots H1 et H6 (section 7) |
| **P2 – retouche** | Planches retouchées à la main ou dessinées par la communauté (fées jouables) | Images retouchées par un artiste ; variantes de lumière (nuit, M3), animations de décor (linge, fanion, cascade) en petites planches | M3 et après |

### Comment les sprites 2D vivent dans le monde HD-2D

`CharacterVisual` n'expose que `set_skin`, `play`, `set_facing` et les signaux `frame_changed` / `animation_finished`. Il lit la planche PNG et le JSON du skin et construit un `SpriteFrames` à l'exécution (un `AtlasTexture` par image, décalé selon son ancre), affiché par un `AnimatedSprite3D` en billboard axe Y, face à la caméra fixe. (HD-2D) La variante « mesh » (modèles 3D) est retirée. Échelle : Chtholly debout fait 144 px de planche pour 1,5 m, soit un `pixel_size` de 0,0104 m par pixel de planche, le même pour tous les sprites **et pour tout le décor** (96 px par mètre) ; l'échelle d'un Timere (0,8 à 1,3) s'applique par-dessus.

Le JSON des planches est **celui de l'easter egg, repris tel quel** (`version`, `echelle`, `planche`, puis par animation `ips`, `boucle`, `images` en `[x, y, largeur, hauteur, ancreX, ancreY]`, `coup` = images qui touchent, `onde` = image qui lance l'onde) : les planches déjà découpées pour le site se copient sans conversion, et `tools/wordend/decouper-planche.py` reste l'outil pour en produire de nouvelles.

```json
{ "version": 1, "echelle": 2, "planche": [809, 1048],
  "animations": {
    "repos":   { "ips": 2,  "boucle": true,  "images": [[x, y, l, h, ancreX, ancreY], …] },
    "marche":  { "ips": 10, "boucle": true,  "images": […] },
    "course":  { "ips": 14, "boucle": true,  "images": […] },
    "attaque": { "ips": 14, "boucle": false, "images": […], "coup": [1, 2, 3] },
    "charge":  { "ips": 10, "boucle": false, "images": […], "onde": 3 },
    "degats":  { "ips": 1,  "boucle": false, "images": […] },
    "mort":    { "ips": 1,  "boucle": false, "images": […] }
  } }
```

Un skin de joueur doit fournir ces 7 animations ; un ennemi fournit `repos`, `marche`, `course`, `degats`, `mort` et une animation par attaque (`fouet`, `morsure`). `gen_placeholders.py` produit exactement ce jeu d'animations pour les silhouettes de remplacement.

### Ce que Claude Code peut et ne peut pas produire

- **Peut** : placeholders P0 (planches, images HD-2D en pixel art par `tools/hd2d_assets.py`), icônes d'objets simples, shaders (sol en tuiles, post-traitement), projectile de l'onde (mesh + shader), découpe et assemblage de planches à partir d'images fournies (comme `decouper-planche.py`), ajustement d'une image livrée à son format (`tools/hd2d_assets.py fit`).
- **Ne peut pas** : dessiner une nouvelle pose dans le style des planches, modéliser un personnage, télécharger un pack Kenney ou une musique (hors de la liste réseau autorisée des sessions cloud : tu les ajoutes toi-même au dépôt).

### Licences et crédits

- Dessins des membres : accord écrit de chaque auteur conservé dans `assets/characters/CREDITS.md` (nom, œuvre, licence accordée au projet, par exemple CC BY-NC 4.0). Les planches générées (Gemini) sont notées comme telles.
- Tiers : uniquement CC0 (Kenney, Poly Haven, Quaternius) listés dans `assets/CREDITS.md` avec URL et licence ; `Scarborough Fair` est un air traditionnel, mais l'enregistrement utilisé doit avoir sa licence notée.
- **Point juridique** : Chtholly, Seniorious et Timere sont des éléments de SukaSuka. Un easter egg discret et un jeu mis en avant sur le site ne portent pas le même risque ; décision à prendre avant M4 (section 13) : rester un hommage non commercial clairement crédité, ou basculer les héros vers des personnages originaux des membres en gardant Timere comme clin d'œil.

### Budgets par asset

| Type | Limite |
| --- | --- |
| Sprite sheet personnage | 2048 × 2048 max, PNG, moins de 1 Mo ; 96 px par mètre (Chtholly : 144 px debout) |
| (HD-2D) Image de décor | taille exacte de `tools/hd2d_manifest.json` (96 px par mètre ; 48 pour le lointain), PNG, moins de 1 Mo ; toutes les images HD-2D : moins de 8 Mo (`tests/unit/test_hd2d_assets.gd`) |
| Audio | OGG Vorbis, musique 96 kb/s, effets mono |
| Git LFS | activé pour `.glb .vrm .blend .wav .ogg` (plus de modèles depuis le HD-2D) ; les PNG restent dans Git |

## 6. Environnement Claude Code cloud

> **Mise à jour du Lot 0** : dans l'environnement réel, les releases GitHub de godotengine/godot sont joignables et docker n'a pas de démon. `tools/setup.sh` télécharge donc le binaire et n'extrait du .tpz que les templates Web, par requêtes HTTP Range (`tools/fetch_templates.py`, une quinzaine de secondes en tout), puis se replie sur docker. Le script du dépôt fait foi ; celui ci-dessous est la version d'origine. `tools/check.sh` dure environ 25 s.

**Une session cloud n'a ni écran ni accès aux releases GitHub de Godot** : Godot arrive par l'image Docker `barichello/godot-ci` (Docker Hub est dans la liste réseau « Trusted »), et les agents vérifient leur travail par import headless, tests, export et captures rendues sous Xvfb. Tout cela est installé une fois par le script de setup, puis mis en cache environ sept jours ([doc des environnements cloud](https://code.claude.com/docs/en/cloud-environments.md)).

### Ce que la VM offre et impose

| Point | Valeur | Conséquence pour le projet |
| --- | --- | --- |
| Machine | Ubuntu 24.04 x86\_64, 4 vCPU, 16 Go RAM, 30 Go disque | Export Web et tests tiennent largement ; pas de build de moteur |
| Réseau « Trusted » | Registres de paquets, Docker Hub, `raw.githubusercontent.com` | `docker pull` et `pip install` fonctionnent ; `godotengine.org`, `kenney.nl` et `itch.io` ne sont pas joignables |
| Proxy GitHub | Les assets de release ne sont servis que pour les dépôts attachés à la session | Télécharger Godot depuis `godotengine/godot` renvoie 403 : d'où l'image Docker. Autre option : attacher le binaire comme asset d'une release de **ton** dépôt |
| Script de setup | Bash exécuté en root, doit finir en moins de 5 min pour être mis en cache | Le `docker pull` (3 à 4 Go, l'image embarque aussi un JDK et le SDK Android) tient en général dans la fenêtre ; si le cache ne se construit pas, publier le binaire et les templates comme asset d'une release du dépôt |
| Hooks | `.claude/settings.json` du dépôt est lu si la session n'a qu'un dépôt | Le hook `SessionStart` relance l'import Godot à chaque reprise |
| Commandes | 2 min par défaut, 10 min max au premier plan | Mettre `BASH_DEFAULT_TIMEOUT_MS=600000` dans les variables d'environnement pour les exports |

### Configuration de l'environnement (à faire une fois sur claude.ai/code)

1. Sélecteur d'environnement → **Add cloud environment**, nom `wordend-godot`.
2. Network access : **Trusted** (suffisant). Passer en **Custom** avec la liste par défaut cochée seulement si un domaine supplémentaire devient nécessaire.
3. Environment variables : `BASH_DEFAULT_TIMEOUT_MS=600000` et `GODOT_VERSION=4.7.2`.
4. Setup script : le contenu ci-dessous (identique à `tools/setup.sh` du dépôt, pour que la CI et le cloud partagent le même binaire).

```bash
#!/bin/bash
# tools/setup.sh — Godot headless + templates + outils, pour VM Claude Code et CI
set -u
GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
IMG="barichello/godot-ci:${GODOT_VERSION}"

# 1. Bibliothèques runtime, Xvfb et Mesa logiciel pour les captures d'écran
apt-get update -qq && apt-get install -y -qq --no-install-recommends \
  xvfb libgl1 libgl1-mesa-dri libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
  libasound2t64 libpulse0 libfontconfig1 libdbus-1-3 libudev1 git-lfs unzip >/dev/null || true

# 2. Godot et ses templates d'export, extraits de l'image godot-ci
if ! command -v godot >/dev/null; then
  docker pull "$IMG" || true
  cid=$(docker create "$IMG") || true
  if [ -n "${cid:-}" ]; then
    docker cp "$cid":/usr/local/bin/godot /usr/local/bin/godot || true
    mkdir -p /root/.local/share/godot
    docker cp "$cid":/root/.local/share/godot/export_templates /root/.local/share/godot/ || true
    docker rm "$cid" >/dev/null || true
  fi
  chmod +x /usr/local/bin/godot || true
fi

# 3. Lint et formatage GDScript
pip install --break-system-packages -q "gdtoolkit==4.*" || true

godot --headless --version || echo "ATTENTION: godot absent, le wrapper tools/godot passera par docker"
exit 0
```

Si `docker cp` échoue parce que les chemins de l'image ont changé, `docker run --rm "$IMG" sh -c 'which godot; ls ~/.local/share/godot/export_templates'` donne les bons chemins ; le wrapper `tools/godot` sait de toute façon exécuter Godot dans le conteneur (`docker run --rm -v "$PWD":/project -w /project $IMG godot "$@"`). Dans ce mode de repli, import, tests et export fonctionnent, mais pas les captures d'écran (pas d'affichage Xvfb partagé avec le conteneur) : le binaire natif reste l'objectif.

### Boucle de vérification sans écran

| Commande | Vérifie | Durée |
| --- | --- | --- |
| `tools/godot --headless --import` | Import des assets, erreurs de syntaxe des `.tscn`/`.tres`/`.gd` | 10 à 60 s |
| `gdlint src tests && gdformat --check src tests` | Style et erreurs statiques GDScript | 5 s |
| `tools/godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` | Tests unitaires et d'intégration | 10 à 30 s |
| `tools/godot --headless --script tools/smoke.gd` | Instancie chaque scène de `src/` et la libère sans erreur | 10 s |
| `tools/godot --headless --export-release Web build/web/index.html` | Export complet, taille du build | 30 à 90 s |
| `tools/screenshot.sh res://src/world/maps/essai/essai.tscn build/shots/essai.png` | Rendu réel d'une scène (Xvfb + Mesa llvmpipe, 1280 × 720) ; l'agent ouvre ensuite le PNG avec son outil de lecture d'images | 5 à 15 s |
| `tools/check.sh` | Enchaîne tout ce qui précède ; c'est la définition de « vert » | 2 à 4 min |

`tools/screenshot.gd` étend `SceneTree` : il charge la scène passée en argument, l'ajoute à la racine, attend trois frames, écrit `get_root().get_viewport().get_texture().get_image().save_png(path)` et quitte. Lancé par `xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 --script tools/screenshot.gd -- <scene> <png>` avec `LIBGL_ALWAYS_SOFTWARE=1`. Un agent qui touche au rendu joint la capture à sa PR.

### Travailler en parallèle sans se gêner

- Une session cloud = un lot = une branche `feat/l<N>-<slug>` = une PR vers `main`. Le prompt de chaque session nomme son lot (section 12).
- Un agent ne modifie que les dossiers de son lot (section 7). Un besoin hors périmètre devient une PR « contrats » minuscule, fusionnée en priorité par toi.
- `project.godot`, `export_presets.cfg`, `src/autoload/event_bus.gd` et les couches de collision ne sont modifiés qu'au Lot 0 et dans les PR « contrats » : ce sont les points de conflit Git classiques d'un projet Godot.
- Les fichiers `.uid` et `.import` générés par Godot sont commités avec la scène qui les crée ; les agents ne les éditent jamais à la main.
- Tu fusionnes dans l'ordre des dépendances (L0, puis L1–L5 et L8, puis L6–L7 et L9, puis L10) et tu lances un contrôle visuel dans l'éditeur à chaque jalon, en commençant par la sensation de combat à M1.

## 7. Lots de travail parallélisables

> **(HD-2D)** Les lots L0 à L10 et Q ci-dessous ont construit M0 à M2 dans la première direction
> (3D) ; ils sont fusionnés et leurs dossiers restent la carte des propriétaires du code. La suite
> se fait en HD-2D par les lots H1 à H8 décrits en fin de section (« Lots HD-2D, la suite »).

**Onze lots : L0 seul d'abord, puis six à huit sessions en parallèle.** Chaque lot a un propriétaire de dossiers exclusif, des dépendances explicites et des critères d'acceptation vérifiables par `tools/check.sh`. Un lot ne dépend que des contrats de la section 3, jamais du code d'un autre lot en cours ; le combat (L4) et les ennemis (L5) sont dans la première vague parce qu'ils fixent la sensation du jeu.

| Lot | Objet | Dossiers possédés | Dépend de | Critères d'acceptation |
| --- | --- | --- | --- | --- |
| **L0 Socle** | Squelette du projet, autoloads vides mais conformes aux contrats, couches de collision, `Health`/`Hitbox`/`Hurtbox` vides, `tools/`, CI, GUT, planches Chtholly et Timere copiées, placeholders P0, scène `main.tscn` qui charge le menu puis l'île greybox | tout, une seule fois | — | `tools/check.sh` vert ; export Web produit ; capture `island.png` montre le sol et le ciel ; CI GitHub verte |
| **L1 Joueur et caméra** | `CharacterBody3D`, input map, caméra (`SpringArm3D` à l'origine, caméra fixe HD-2D depuis), verrouillage de cible, détection d'`Interactable` ; appelle `Combat.is_busy()` sur un stub | `src/player/`, `tests/unit/test_player*.gd` | L0 | Se déplace, saute, ne traverse pas les CSG ; verrouillage sur l'ennemi le plus proche ; test du vecteur relatif caméra ; capture avec le joueur sur la plage |
| **L2 Monde** | Île greybox, 5 zones dont l'arène des dunes (points d'apparition) et la forêt, `WorldEnvironment`, eau, murs invisibles, rattrapage sous l'eau, `WorldManager` avec réapparition | `src/world/`, `src/autoload/world_manager.gd`, `assets/textures/` | L0 | Chaque zone émet `zone_entered` ; chute hors île → retour au `Spawn` ; `respawn()` ramène au village ; moins de 150 draw calls en capture |
| **L3 Visuel et skins** | `CharacterVisual` sprite et mesh, chargeur de planche JSON → `SpriteFrames`, `frame_changed`, `SkinRegistry`, `SkinData`, `gen_placeholders.py` | `src/visuals/`, `src/autoload/skin_registry.gd`, `data/skins/`, `assets/characters/`, `assets/enemies/` | L0 | Les 7 animations de Chtholly et les 7 du Timere jouent à la bonne cadence ; `frame_changed` émis par image ; billboard face caméra ; changement de skin à chaud ; test de parsing du JSON |
| **L4 Combat** | `Health`, `Hitbox`/`Hurtbox`, `AttackData`, `player_combat.gd` (enchaînement épée, charge, onde projectile), recul, invincibilité, mort du joueur, `data/attacks/` | `src/combat/`, `data/attacks/`, `tests/unit/test_combat*.gd` | L0 (visuel stub qui émet `frame_changed`) | Tests : dégâts seulement sur images `coup`, invincibilité 1,2 s, charge refusée sous 0,55 s, recharge 1,2 s, onde traverse N hurtbox ; scène de test avec mannequins |
| **L5 Ennemis et vagues** | `Enemy` (machine à états), 4 `EnemyData` Timere, `WaveDirector`, `arena.tscn`, `data/waves/dunes.json`, drops, ennemis libres de la forêt | `src/enemies/`, `data/enemies/`, `data/waves/`, `tests/unit/test_enemy*.gd`, `tests/unit/test_wave*.gd` | L0 (joueur factice, `Health` stub) | Tests : composition 3 + 2*n*, Grand un à la fois dès la vague 3, Coureur dès la vague 2, bonus 50 × *n*, soin toutes les 2 vagues ; les 4 types poursuivent et attaquent un mannequin |
| **L6 PNJ et dialogues** | `npc.tscn`, `DialogueRunner`, boîte de dialogue, format JSON, 3 PNJ de données | `src/npc/`, `src/ui/dialogue_box*`, `data/npcs/`, `data/dialogues/` | L0 (joueur factice) | Tests GUT : conditions `flag`/`count`/`quest`/`best_score`, choix, fin de dialogue ; dialogue jouable avec le joueur stub |
| **L7 Objets, inventaire, quête** | `ItemData`, `pickup.tscn`, `GameState` complet (dont `record_score`), inventaire, `QuestTracker`, `QuestData`, récompense PV max | `src/items/`, `src/quests/`, `src/ui/inventory*`, `src/autoload/game_state.gd`, `data/items/`, `data/quests/` | L0 | Tests : `add/remove/count`, `record_score`, quête complétée quand `count >= required` ; inventaire mis à jour par `EventBus` seulement |
| **L8 Sauvegarde** | `SaveManager`, schéma v1 (dont `best_scores`, `max_hp`), migration, auto-save, `collected_pickups` | `src/autoload/save_manager.gd`, `tests/unit/test_save*.gd` | L0 (travaille sur `to_dict/from_dict` du stub) | Aller-retour sauvegarde/chargement identique ; fichier corrompu → nouvelle partie sans crash ; test de migration v0→v1 |
| **L9 Export Web et site** | `export_presets.cfg` final, écran de chargement, page `web/`embed-test.html pour tester l'iframe, web/CNAME, déploiement GitHub Pages, snippet iframe WordPress, détection mobile et contrôles tactiles de base | `.github/workflows/`, `export_presets.cfg`, `web/`, `src/ui/loading*`, `src/ui/touch*` | L0 | Pages déployées à chaque fusion sur `main` ; build < 25 Mo ; iframe fonctionne sur une page de test du site |
| **L10 Menu et HUD** | Menu principal, sélection de skin, « Cliquer pour jouer », Continuer/Nouvelle partie, crédits ; HUD (cœurs, jauge de charge, vague, score, zone, invite, objectif) ; écran de fin d'arène | `src/ui/main_menu*`, `src/ui/hud*`, `src/ui/arena_end*`, `src/ui/credits*` | L3, L8 | Choix de skin persistant ; Continuer absent sans sauvegarde ; HUD alimenté uniquement par `EventBus` |
| **Lot Q Moteur de quêtes** (après M2, PR « contrats ») | Quêtes en étapes écrites en JSON (talk, reach, kill, collect, arena, flag), `QuestTracker` par l'EventBus, prérequis et enchaînement, déclencheurs de lieu, conditions et effets de dialogue, sauvegarde v2 migrée, quête suivie dans le HUD, journal de quêtes, marqueurs « ! » / « ? » des PNJ, `docs/QUETES.md` | `src/quests/`, `src/ui/journal*`, `data/quests/`, `tests/data/`, `docs/QUETES.md` (et, pour ce lot : `game_state.gd`, `save_manager.gd`, `dialogue_runner.gd`, `npc.gd`/`npc.tscn`, `hud*`) | M2 | Chaque type d'étape, enchaînement, récompenses, prérequis, migration v1 → v2 testés ; quête de démonstration jouée dans la vraie partie ; quête des pages inchangée ; contenu vérifié par `test_quest_content.gd` |

### Ordre et parallélisme

1. **Vague 0** : L0 seul (une session, 1 à 2 jours).
2. **Vague 1** : L1, L2, L3, L4, L5 et L8 en parallèle (six sessions). L6 et L7 peuvent aussi démarrer, car ils testent contre des stubs.
3. **Vague 2** : L6, L7, L9 (si non démarrés), puis L10 quand L3 et L8 sont fusionnés.
4. **Intégration M1** : une session « intégration combat » branche joueur + combat + ennemis + visuel dans l'arène des dunes ; tu juges la sensation dans l'éditeur et dans le navigateur avant d'ouvrir la vague 2.
5. **Intégration M2** : une session assemble la quête de bout en bout, corrige les frottements entre lots, et tu valides.

### Règles communes à tous les lots

- La branche part de `main` à jour ; la PR reste sous 1 500 lignes modifiées, sinon le lot est scindé.
- Chaque PR contient : ce qui a été fait, comment c'est testé, une capture si le rendu change, et la liste des contrats touchés (idéalement aucun).
- Un agent bloqué par un contrat manquant écrit le besoin dans `docs/CONTRACT_REQUESTS.md` et continue avec un stub local plutôt que de modifier le contrat.
- Les données (`data/*.tres`, JSON) sont ajoutées, jamais réécrites en masse, pour que deux lots puissent en créer en même temps.

### Lots HD-2D, la suite

**Huit lots après le socle HD-2D : sept en parallèle dès sa fusion, le huitième pour fermer la
vague.** Le socle (PR « contrats ») a posé la caméra fixe, le décor en images (`DecorPanel`,
`Building`, `PropBatcher`, sol en atlas, falaises, ciel), le post-traitement, les 99 images de
remplacement en pixel art et leur outil, et le cahier des charges `docs/ASSETS_HD2D.md`. Chaque lot
possède des fichiers disjoints ; un lot de décor ne touche que ses zones et les décors qui ne
servent qu'à elles.

| Lot | Objet | Fichiers possédés | Dépend de | Critères d'acceptation |
| --- | --- | --- | --- | --- |
| **H1 Images livrées** | Intégrer les images commandées à ChatGPT (ou à un artiste) selon `docs/ASSETS_HD2D.md`, dans l'ordre de sa section 11 : vérifier, recadrer, reconstruire l'atlas du sol, créditer ; corriger le cahier des charges quand une consigne donne de mauvais résultats | `assets/hd2d/**`, `tools/hd2d_assets.py`, `tools/hd2d_manifest.json`, `tools/hd2d_art.py`, `tools/hd2d_ground.py`, `tools/hd2d_props.py`, `tools/hd2d_sky.py`, `docs/ASSETS_HD2D.md`, `tests/unit/test_hd2d_assets.gd`, `assets/CREDITS.md` (ajouts en bas) | socle | `python3 tools/hd2d_assets.py check` sans écart ; atlas à jour ; images à leur taille exacte (96 px/m) ; export Web sous le budget (section 9) ; planche avant/après par livraison (`tools/hd2d_shots.sh`) |
| **H2 Décor de l'entrepôt** | Village de l'entrepôt : composition des volumes et des façades, cour, potager, linge, palissade, lampes ; occlusion de l'entrepôt quand on passe derrière | `src/world/zones/village/` et les décors qui ne servent qu'au village (`warehouse_main`, `warehouse_wing`, `warehouse_porch`, `armory_door`, `tool_shed`, `palisade`, `palisade_gate`, `laundry_line`, `vegetable_patch`, `well`, `flower_bed`, `climbing_tree`), `src/items/placements/village.tscn` | socle (images de H1 quand elles arrivent) | Lieux de MONDE.md section 2 reconnaissables sur `hd2d_village.png` et `hd2d_dialogue.png` ; aucun panneau ne cache le joueur ou un PNJ plus d'une seconde ; collisions testées ; ≤ 200 draw calls |
| **H3 Décor du port** | La ville du port : rue des boutiques, café, salle de projection, maison de Limeskin, quais, grue, passerelle et aéronefs ; plans successifs de la rue | `src/world/zones/beach/` et ses décors propres (`cafe`, `shop_bakery`, `shop_bookshop`, `projection_hall`, `stone_house`, `limashenka_house`, `market_stall`, `market_stall_veg`, `snack_stall`, `scrap_pile`, `signpost`, `wind_sock`, `gangway`, `cargo_crane`, `mooring_arm`, `bollard`, `crates_barrels`, `edge_railing`, `airship_barocupot`, `airship_ferry`), `src/items/placements/beach.tscn` | socle | `hd2d_beach.png` lisible (rue, quais, navires vus d'en haut) ; scène du thé de Limeskin cadrée ; collisions testées ; ≤ 200 draw calls |
| **H4 Décor des bois, du Couchant et de la colline** | Bois du marais (sous-bois, lisière, ruisseau), bord du Couchant (cercle de veille, cloche, rochers du vent, ruines) et colline des étoiles (pente, sommet, belvédère) | `src/world/zones/forest/`, `src/world/zones/dunes/`, `src/world/zones/hill/` et leurs décors propres (`tree_old_pine`, `tree_old_pine_clawed`, `mushroom`, `reeds`, `log_bridge`, `berry_bush`, `mossy_rock`, `bear_rock`, `stick_rack`, `play_goal`, `play_goal_red`, `ring_stone`, `vigil_bell`, `wind_rock_a`, `wind_rock_b`, `wind_rock_c`, `watch_post_ruin`, `ruined_wall`, `garde_pennant`, `signal_pillar`, `fallen_lantern`, `grass_tuft`, `lone_tree`, `lookout`, `tall_grass`), `src/items/placements/forest.tscn`, `dunes.tscn`, `hill.tscn` | socle | Sentiers lisibles en vue fixe ; rejetons visibles entre les troncs ; arène lisible pendant trois vagues (`hd2d_vigil.png`) ; rien de plus haut que 0,3 m dans le cercle de veille ; ≤ 200 draw calls par zone |
| **H5 Caméra, image et post-traitement** | Réglages de la caméra fixe (cadrages, verrouillage, zoom), flou de profondeur, lueur, étalonnage, lumières chaudes, ombres, ciel et mer de nuages, sol et falaises (masques du sol, tramage) ; éclairage de nuit pour M3 | `src/player/camera_rig.gd`, `src/player/camera_rig.tscn`, `src/player/post_fx.gdshader`, `src/world/shaders/`, `src/world/materials/`, `src/world/island.tscn` (hors `Zones`), `src/world/island_rock.gd`, `src/world/terrain.gd`, `src/world/decor_panel.gd`, `src/world/building.gd`, `src/world/prop_batcher.gd`, `tests/unit/test_camera_rig.gd`, `tests/unit/test_hd2d_decor.gd` | socle | Shaders compilés (fumée, tests) ; 50 images/s par zone dans `tools/web_m2.js` ; ≤ 200 draw calls ; captures avant/après ; API de `DecorPanel`, `Building` et `CameraRig` inchangée (sinon PR « contrats ») |
| **H6 Personnages et planches** | Planches HD-2D de Chtholly (tenue de l'acte 1), des PNJ, des fées jouables et portraits 256 px selon `docs/ASSETS_HD2D.md` section 3 ; échelles du tableau des hauteurs ; ombre et retournement du billboard | `assets/characters/**`, `data/skins/`, `src/visuals/`, `src/autoload/skin_registry.gd`, `tools/gen_placeholders.py`, `assets/characters/CREDITS.md`, `tests/unit/test_skin_registry.gd`, `tests/unit/test_visual_sprite.gd` | socle | Planches lues par `SheetLoader` sans changement du format JSON ; hauteurs à ± 5 % du tableau ; `parle` joué en conversation ; portraits 256 px ; capture de chaque skin |
| **H7 Combat et Timeres en HD-2D** | Lisibilité du combat en vue fixe : planches de Timere, onde de charge et éclats en sprites, signes avant l'attaque, ombres, indicateur de cible, secousse et arrêt sur image réglés pour la caméra fixe | `src/combat/`, `src/enemies/` (hors `placements/`), `data/attacks/`, `data/enemies/`, `data/waves/`, `assets/enemies/**`, `tests/unit/test_combat*.gd`, `tests/unit/test_enemy.gd`, `tests/unit/test_wave_director.gd`, `docs/REGLAGES_COMBAT.md` | socle | Règles de la section 4 inchangées (tests) ; un coup, une onde et une morsure lisibles sur capture ; vague 5 atteignable ; sensation jugée à la manette |
| **H8 Acte 1 de bout en bout et navigateur** (après les autres) | Rejouer l'acte 1 entier dans la vraie partie et dans le navigateur, corriger les frottements entre lots, mettre à jour la recette, les mesures et les captures | `tests/integration/test_m2_*.gd`, `tests/integration/test_act1*.gd`, `tests/integration/demo_hd2d.*`, `tests/stubs/m1_game_test.gd`, `tests/stubs/m2_game_test.gd`, `src/test_shortcuts.gd`, `tools/web_m2.js`, `tools/web_m1.js`, `tools/hd2d_shots.sh`, `docs/web.md`, `docs/RECETTE_M2.md` | H1 à H7 | `tools/check.sh` vert ; `node tools/web_m2.js … tout` vert ; recette de l'acte 1 cochée en HD-2D ; captures `hd2d_*` |
| **H9 Formats du décor (moteur)** (cahier n° 2) | Le moteur apprend les formats de `docs/ASSETS_HD2D_MONDE.md` (section 3 et 17) : bandes animées dans `DecorPanel`, décalques au sol (`GroundDecal`), flancs des `Building`, variantes et retournement dans `PropScatter`, sol à 27 tuiles avec alternance des tuiles `_b` et nouveaux masques, premier plan transparent devant le joueur, ciel qui dérive, petites vies (feuilles, oiseaux) ; tout reste fondu par image | `src/world/decor_panel.gd`, `building.gd`, `prop_batcher.gd`, `prop_scatter.gd`, `terrain.gd`, `island_rock.gd`, nouveaux scripts de `src/world/` (`ground_decal.gd`, `sky_drift.gd`, `ambient_sprites.gd`…), `src/world/shaders/`, `src/world/materials/`, `src/world/island.tscn` (hors `Zones`), `tests/unit/test_hd2d_decor.gd`, `tests/unit/test_hd2d_formats.gd`, `tests/integration/demo_formats.*`, API ajoutées dans la section 3 | H1 à H8 | API existantes inchangées (ajouts seulement) ; chaque format testé et montré par `demo_formats` (capture) ; un draw call par image et par case, animations comprises ; ≤ 200 draw calls dans toutes les vues de `tools/hd2d_shots.sh` ; 50 images/s par zone dans le navigateur |
| **H10 Images du cahier n° 2 : manifeste et remplaçants** | Les ~300 images de `docs/ASSETS_HD2D_MONDE.md` entrent au manifeste (genres `decal`, `anim`, `side`, alpha doux, lot A à G), `check` les vérifie, `gen` leur donne un remplaçant en pixel art au bon format, l'atlas du sol passe à 27 tuiles | `tools/hd2d_manifest.json`, `tools/hd2d_*.py`, `assets/hd2d/**`, `docs/ASSETS_HD2D.md`, `docs/ASSETS_HD2D_MONDE.md`, `tests/unit/test_hd2d_assets.gd`, `assets/CREDITS.md` (ajouts en bas) | H1 | `python3 tools/hd2d_assets.py check` sans écart sur les ~400 images ; atlas de 27 tuiles à jour ; planches de contrôle par lot ; export Web sous le budget (section 9) |

Règles propres à cette phase :

- Un décor partagé par plusieurs zones (`ball`, `bench`, `bush`, `crate`, `crystal_lamp`,
  `edge_parapet`, `myosotis`, `rock`, `tree_autumn*`, `tree_pine`, `distant_island_*`,
  `floating_rock`) ne change que par H1 (son image) ou H5 (son matériau) ; un lot de zone qui en
  veut une variante crée `src/world/props/<id>_<zone>.tscn` au lieu de modifier l'original.
- Les masques du sol (chemins, cour, marais…) sont dans `src/world/shaders/terrain.gdshader`
  (H5) : un lot de zone qui veut un chemin déplacé le demande dans `docs/CONTRACT_REQUESTS.md`.
- Les PNJ, ennemis libres et déclencheurs restent dans `src/npc|enemies/placements/<zone>.tscn`,
  hors de ces lots : leurs positions sont tenues par les quêtes et `test_world_story_spots.gd`.
- Toute PR de rendu joint la vue `tools/hd2d_shots.sh` de ses zones avant et après, et le nombre
  de draw calls lu dans le journal de la capture.

### Application de bureau (bureau, PR « contrats »)

**En plus du Web, inchangé, une application Windows avec son installateur** (docs/bureau.md),
faite avant M5 parce que le Web grossit avec les images du cahier n° 2. Même projet, même rendu
(Compatibility), même pck (38 Mo, celui du Web à quelques octets près) ; le Web reste le
préréglage par défaut de `tools/check.sh` et du déploiement.

| Lot | Objet | Fichiers possédés | Dépend de | Critères d'acceptation |
| --- | --- | --- | --- | --- |
| **D1 Bureau Windows** (PR « contrats ») | Préréglages « Windows Desktop » (x86_64, pck dans l'exe, icône et métadonnées écrites par Godot, sans rcedit) et « Linux » (même pck, pour vérifier le démarrage ici) ; gabarits Windows et Linux dans `tools/setup.sh` ; dossier utilisateur `WordEnd` hors Web ; autoload `DesktopApp` (fenêtre, plein écran F11 / Alt+Entrée / bouton mémorisé, « Quitter » qui écrit la partie) ; installateur NSIS par utilisateur ; tâches `bureau` et `release` de la CI | `export_presets.cfg` (préréglages 1 et 2), `project.godot` (version, dossier utilisateur, autoload), `src/autoload/desktop_app.gd`, `src/desktop_check.gd`, boutons de `src/ui/main_menu.*` et `src/ui/pause_menu.*`, section « desktop » de `data/texts/story.json`, `tools/build_desktop.sh`, `tools/desktop_boot.sh`, `tools/installer/**`, `tools/setup.sh`, `tools/fetch_templates.py`, `.github/workflows/ci.yml` (tâches `bureau`, `release`), `tests/unit/test_desktop.gd`, `docs/bureau.md` | M2.5 | `tools/check.sh` vert (préréglages vérifiés) ; `tools/build_desktop.sh --linux` : exe, installateur, zip, et le build Linux du même pck démarre sans écran jusqu'à une partie puis la reprend ; capture Xvfb du menu avec « Quitter » ; Web inchangé (préréglage, taille, chemin des sauvegardes) |

## 8. Feuille de route

**Six jalons, dont trois avant la première mise en ligne (M2, vers la semaine 5).** Les durées sont des estimations pour un rythme soirées et week-ends avec plusieurs sessions Claude Code en parallèle ; elles glissent sans casser le plan, car chaque jalon n'ouvre le suivant que sur sa porte de passage.

&#91;embedded content: feuille de route · 6 jalons M0 à M5, une porte de passage par jalon\]

Chaque losange est une porte que tu valides toi-même avant d'ouvrir le jalon suivant ; M2 (en couleur) est la première version mise en ligne sur le site.

| Jalon | Ce qui existe à la fin | Porte de passage (validée par toi) |
| --- | --- | --- |
| **M0 Socle** (semaine 1) | Dépôt, L0 fusionné, CI verte, export Web déployé sur GitHub Pages avec l'île greybox vide | Tu ouvres le build dans un navigateur et vois l'île ; `tools/check.sh` vert sur une session cloud neuve |
| **M1 Combat** (semaines 2–3) | L1 à L5 et L8 fusionnés : Chtholly se déplace sur l'île et affronte des vagues de Timeres dans l'arène des dunes avec les règles de l'easter egg | Sensation de combat (coups, recul, onde, verrouillage) jugée agréable à la manette et au clavier ; la vague 5 est atteignable |
| **M2 Tranche verticale** (semaines 4–5) | L6, L7, L9, L10 fusionnés : village, quête des pages dans la forêt, sauvegarde, menu, HUD, page d'intégration | Critères de la section 4 cochés ; test par 3 membres de la communauté |
| **M2.5 HD-2D** (après M2) | Socle HD-2D fusionné (caméra fixe, décor en images, post-traitement), puis lots H1 à H8 : l'acte 1 entier dans les images commandées d'après `docs/ASSETS_HD2D.md` | Tu joues l'acte 1 dans le navigateur et juges le rendu proche d'*Octopath Traveler* ; 50 images/s par zone ; export < 60 Mo |
| **M3 Monde vivant et premier donjon** (semaines 6–10) | Cycle jour/nuit, 2 zones de plus, **grotte-donjon** avec clés et boss (Grand Timere renforcé), 2 nouveaux types d'ennemis, équipement (épée améliorée, cœurs supplémentaires), 10 PNJ, 3 quêtes, musique et sons, contrôles tactiles complets | Session de 20 min sans bug bloquant ; le donjon se termine en 10 à 15 min ; 30 images/s sur mobile |
| **M4 Yume** (semaines 11–14) | Lien avec yumenovel.fr : sauvegarde liée au compte WordPress, classement des meilleurs scores de l'arène, déblocages liés aux parutions, page officielle du jeu, mise en ligne | Deux semaines de « bêta ouverte » sur le site sans incident de sauvegarde ; décision prise sur les personnages (section 13) |
| **M5 Bureau** (après) | Export Windows/macOS/Linux, catégorie Jeu dans l'application Yume, zones streamées, deuxième donjon ; ((bureau) l'application Windows et son installateur existent déjà : docs/bureau.md) | Décidé après M4 selon l'usage réel |

Après M4, le rythme devient **une « saison » par trimestre** : une zone, des PNJ, des objets et un événement lié à la communauté, produits majoritairement en données.

## 9. Qualité, tests et CI

**« Vert » veut dire : import sans erreur, lint propre, tests GUT verts, scènes de fumée OK, préréglages de bureau présents, export Web produit sous le budget.** La même commande `tools/check.sh` donne ce verdict sur la VM cloud, sur ta machine et dans GitHub Actions, de sorte qu'un agent n'ouvre une PR que quand elle passera la CI.

### Niveaux de test

| Niveau | Outil | Ce qu'on y met | Exemple |
| --- | --- | --- | --- |
| Unitaire | GUT, `tests/unit/test_*.gd` | Logique pure : `Health`, `AttackData` et images `coup`, enchaînement d'épée, jauge de charge, composition des vagues, `GameState`, `SaveManager`, `DialogueRunner`, `QuestTracker`, parsing des planches, vecteur de déplacement | `assert_false(health.take_damage(1, src))` pendant l'invincibilité ; `assert_eq(director.compose(4).size(), 11)` |
| Intégration | GUT avec scènes, `tests/integration/` | Hitbox → hurtbox → `enemy_killed` → score ; onde qui traverse 3 mannequins ; joueur → PNJ → dialogue → quête ; pickup → inventaire ; sauvegarde après `arena_finished` | Instancier `arena.tscn`, lancer `start()`, avancer 200 frames, vérifier le nombre d'ennemis vivants |
| Fumée | `tools/smoke.gd` | Chaque `.tscn` de `src/` s'instancie et se libère sans erreur ni avertissement bloquant | Détecte les références cassées après un renommage |
| Visuel | `tools/screenshot.sh` + relecture humaine | Une capture par scène clé jointe aux PR qui touchent au rendu | `island.png`, `dunes_wave3.png`, `village_npc.png` |
| Performance | Mesure dans le build Web avec `Performance.get_monitor()` affiché par F3 | Draw calls, triangles, mémoire vidéo, temps de frame avec 12 Timeres | Alerte dans le HUD debug si > 300 draw calls |

### GUT en ligne de commande

```bash
tools/godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs -gprefix=test_ -gexit -gjunit_xml_file=build/junit.xml
```

Le code de retour est non nul si un test échoue ; la CI publie `build/junit.xml`.

### Pipeline GitHub Actions (`.github/workflows/ci.yml`)

| Job | Déclencheur | Contenu |
| --- | --- | --- |
| `check` | Toute PR et tout push sur `main` | Conteneur `barichello/godot-ci:4.7.2` + bibliothèques X11/Mesa + Xvfb ; `pip install gdtoolkit` ; `tools/check.sh` ; étape « taille du build » qui échoue au-delà du budget du jalon (150 Mo) et écrit la taille dans le résumé du job ; artefacts `build/web/`, `build/shots/`, `build/junit.xml` |
| `deploy` | Push sur `main`, après `check` | Copie `web/` (CNAME, page de test) dans `build/web/`, puis publie sur GitHub Pages via `actions/upload-pages-artifact` + `actions/deploy-pages` |
| `bureau` | (bureau) Toute PR, tout push sur `main` et tout tag `v*` | Même conteneur ; NSIS ; `tools/build_desktop.sh --linux` : export Windows, installateur `WordEnd-Setup-<version>.exe`, zip portable, build Linux du même pck lancé sans écran jusqu'à une partie ; tailles dans le résumé du job (pas de budget : celui de 60 Mo ne vaut que pour le Web) ; artefact `bureau` (7 jours). Un tag `vX.Y.Z` fixe la version (project.godot, `application/config/version`, sinon) |
| `release` | (bureau) Tag `v*`, ou « Run workflow » avec `release` coché ; après `check` et `bureau` | Seule tâche avec `contents: write` : Release GitHub `vX.Y.Z` avec l'installateur et le zip (`softprops/action-gh-release`) |

Les captures d'écran en CI utilisent `xvfb-run` dans le conteneur ; si Mesa manque dans l'image, le job `check` installe `libgl1-mesa-dri xvfb` au préalable.

### Budgets de performance (build Web, Compatibility)

| Mesure | Cible M2 | Cible M4 |
| --- | --- | --- |
| Taille compressée (wasm + pck) | < 60 Mo | < 150 Mo |
| Temps jusqu'au menu (fibre) | < 10 s | < 15 s |
| Images/s portable | 60 | 60 |
| Images/s téléphone récent | 30 | 30 |
| Draw calls en vue village | < 150 ((HD-2D) mesuré : 50) | < 200 |
| Triangles affichés | < 150 000 ((HD-2D) mesuré : 17 000) | < 400 000 |

(HD-2D) Mesures du 7 octobre 2026 (`tools/hd2d_shots.sh`, rendu natif) : 32 à 70 draw calls selon
la zone, une conversation ou une veille (43 à 67 dans le navigateur, au Spawn de chaque zone) ;
export 12,4 Mo compressés (18,4 avant la purge des modèles 3D). `tools/check.sh` échoue au-delà de 150 Mo compressés (25 Mo jusqu'au cahier des charges n° 2, 60 Mo jusqu'à ses lots A et F, 100 Mo jusqu'aux premiers lots du cahier n° 3 ; 73,5 Mo mesurés avec toutes les images du cahier n° 2, 101,3 Mo avec les lots I et J de priorité 1 du n° 3).

(F0, PR « contrats ») Export allégé sans perte visible, de 141,3 à 132,2 Mo compressés : images importées « Lossless » (WebP sans perte), sans mipmaps ni détection 3D (`[importer_defaults]` de project.godot pour les nouvelles, `tools/import.sh` ramène les autres, `tests/unit/test_texture_imports.gd` le vérifie) ; encodeur WebP sans perte à l'effort 4 / 90 (`rendering/textures/webp_compression/*`, −5 Mo) ; les 25 tuiles du sol que seul l'atlas lit et les plans des cartes (`data/maps/*/plan.json`) hors des trois préréglages d'export (−4,4 Mo) ; détail et mesures : docs/DECISIONS.md, F0.

### Hygiène du dépôt

- `gdformat` passe avant chaque commit (hook `pre-commit` facultatif en local, obligatoire en CI).
- Les avertissements Godot sont traités comme des erreurs dans `tools/check.sh` (`--quit-after` + grep sur `WARNING`), sauf liste blanche dans `tools/warnings_allow.txt`.
- Une PR qui change un contrat de la section 3 met à jour `PLAN.md` et `CLAUDE.md` dans le même commit.

## 10. Intégration à yumenovel.fr

**Le jeu est un dossier de fichiers statiques servi par GitHub Pages et affiché dans une page du site via une iframe ; WordPress n'exécute rien.** Le Raspberry Pi n'apporte rien à ce schéma (fichiers statiques, pas de serveur de jeu) et l'application de bureau Yume reçoit plus tard un export natif du même projet.

### Étapes

| Étape | Jalon | Détail |
| --- | --- | --- |
| Hébergement du build | M0 | GitHub Pages du dépôt `Yume-WordEnd`, branche `gh-pages` ou artefact Pages ; URL `https://<compte>.github.io/Yume-WordEnd/` |
| Sous-domaine | M2 | `jeu.yumenovel.fr` en CNAME vers GitHub Pages dans la zone DNS OVH, fichier `CNAME` dans `web/` ; HTTPS automatique |
| Page du site | M2 | Modèle de page `page-jeu.php` dans le thème Yume-WordPress (fait main, sans constructeur) contenant l'iframe ci-dessous, plein écran par bouton, note « nécessite WebGL 2 » |
| Sauvegarde locale | M2 | `user://` persisté par Godot dans IndexedDB du domaine `jeu.yumenovel.fr` : indépendante de WordPress |
| Pont page ↔ jeu | M4 | `JavaScriptBridge` côté Godot et `window.postMessage` côté page : la page transmet l'état de connexion WordPress (nonce REST) au jeu après consentement du joueur |
| Sauvegarde liée au compte | M4 | Endpoint `POST/GET /wp-json/yume/v1/game/save` dans le plugin Yume-WordPress, authentifié par cookie + nonce, une sauvegarde JSON par utilisateur (`user_meta`), fusion « la plus récente gagne » avec la locale |
| Déblocages communautaires | M4 | Endpoint `GET /wp-json/yume/v1/game/unlocks` renvoyant la liste des contenus ouverts (tome publié, événement) ; le jeu met des `flags` correspondants |
| Version bureau | M5 | Exports Windows/macOS/Linux depuis le même dépôt ; l'application Yume ouvre l'exécutable ou embarque le build Web dans une WebView ; (bureau) Windows fait : installateur publié en Release GitHub à chaque tag `vX.Y.Z` (docs/bureau.md) |

### Snippet iframe

```html
<div class="yume-game" style="aspect-ratio:16/9;max-width:1280px;margin:0 auto">
  <iframe src="https://jeu.yumenovel.fr/" title="WordEnd"
          allow="fullscreen; gamepad; autoplay" loading="lazy"
          style="width:100%;height:100%;border:0;border-radius:12px"></iframe>
</div>
```

Thread Support désactivé à l'export : aucun en-tête `Cross-Origin-Opener-Policy`/`Embedder-Policy` à configurer, ni sur Pages ni sur WordPress.

### Pourquoi ni Raspberry Pi ni serveur maison

- Un build Web est un dossier statique : GitHub Pages le sert gratuitement, avec CDN et HTTPS, sans exposer ton réseau.
- Un Pi ne deviendrait utile que pour un **serveur de jeu multijoueur**, hors périmètre ; même alors, un petit VPS serait plus simple à exploiter.
- Le seul traitement serveur nécessaire (sauvegarde liée au compte, déblocages) tient dans deux endpoints REST du plugin WordPress existant.

### Application de bureau Yume

Godot exporte le même projet en exécutable natif : meilleures performances, pas de limite de taille, manette et plein écran natifs. La « catégorie Jeux » de l'application de lecture peut d'abord pointer vers la page Web (M2), puis lancer l'export natif (M5). Rien à décider avant M4.

## 11. Fichiers de démarrage

> **Mise à jour du Lot 0** : ces fichiers ont servi de point de départ ; les versions du dépôt (CLAUDE.md, project.godot, tools/, ci.yml…) font foi et les complètent (voir docs/DECISIONS.md).

**Ces fichiers vont tels quels dans le dépôt vide, avant la première session Claude Code** : ils fixent le moteur, les règles des agents, la CI et la boucle de vérification. Commite aussi `PLAN.md` (ce document exporté en Markdown) et les quatre fichiers de planches de l'easter egg (`chtholly.png`, `chtholly.json`, `timere.png`, `timere.json`, depuis `wp-content/plugins/yume-core/includes/wordend/assets/` de Yume-WordPress) dans `assets/characters/chtholly/` et `assets/enemies/timere/` : une session cloud n'a pas accès à un autre dépôt sans perdre ses hooks. Le Lot 0 crée tout le reste.

### `CLAUDE.md`

```markdown
# Yume-WordEnd — règles pour Claude Code

## Le projet
Jeu d'action-aventure en HD-2D dans Godot 4.7.2 (GDScript typé, export Web) : Chtholly et son
épée contre des vagues de Timeres, un village, des PNJ et des quêtes. Direction artistique : HD-2D
à la manière d'*Octopath Traveler* (sprites dans un décor en relief fait d'images, caméra fixe
inclinée, flou de profondeur, lumière chaude) ; détail dans docs/ASSETS_HD2D.md.
Le plan complet est dans PLAN.md. Ses contrats d'interface (section 3 : signaux, API, ressources,
couches de collision) font foi : on code contre eux, on ne les change pas sans PR « contrats ».

## Avant de commencer
1. Lis PLAN.md section 3 (contrats) et section 7 (ton lot : dossiers possédés, critères).
2. Lance `tools/check.sh` pour vérifier que l'environnement est sain.
3. Travaille sur la branche `feat/l<N>-<slug>` de ton lot ; une PR par lot vers `main`.

## Commandes
- Vérification complète (= « vert ») : `tools/check.sh`
- Tests seuls : `tools/godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
- Capture d'une scène : `tools/screenshot.sh res://src/world/maps/essai/essai.tscn build/shots/essai.png`, puis ouvre le PNG
- Export Web : `tools/godot --headless --export-release Web build/web/index.html`
- Lint : `gdlint src tests && gdformat --check src tests` (`gdformat src tests` pour corriger)

## Règles
- GDScript typé partout (`var hp: int`, `-> void`), `class_name` pour les ressources, signaux au passé.
- Scènes et ressources au format texte (.tscn, .tres). Jamais d'édition manuelle des .uid et .import ;
  commite-les avec la scène qui les crée.
- Les chiffres de combat vivent dans data/attacks et data/enemies, jamais en dur dans un script.
- Un système ne lit jamais un autre système directement : EventBus ou API de GameState.
- Ne modifie que les dossiers de ton lot. Hors périmètre : note le besoin dans docs/CONTRACT_REQUESTS.md
  et continue avec un stub local.
- project.godot, export_presets.cfg, src/autoload/event_bus.gd et les couches de collision ne changent
  qu'au Lot 0 ou dans une PR « contrats ».
- Toute scène doit passer tools/smoke.gd ; tout changement de rendu joint une capture à la PR.
- Commits conventionnels préfixés par le lot : `feat(l4): onde de charge magique`.
- Avant d'ouvrir la PR : `tools/check.sh` vert, description = fait / testé / capture / contrats touchés.

## Pièges connus
- Pas d'écran : valide par tests, smoke, export et captures Xvfb, jamais « ça devrait marcher ».
- Export Web mono-thread : pas de `Thread`, pas de `OS.execute`, pas de `SharedArrayBuffer`.
- Les planches de sprites utilisent le JSON de l'easter egg (ancres par image, `coup`, `onde`) : ne
  les reformate pas.
```

### `.gitignore`

```gitignore
.godot/
build/
*.tmp
*.log
.DS_Store
__pycache__/
```

### `.gitattributes`

```gitattributes
*.glb   filter=lfs diff=lfs merge=lfs -text
*.vrm   filter=lfs diff=lfs merge=lfs -text
*.blend filter=lfs diff=lfs merge=lfs -text
*.wav   filter=lfs diff=lfs merge=lfs -text
*.ogg   filter=lfs diff=lfs merge=lfs -text
*.mp3   filter=lfs diff=lfs merge=lfs -text
*.tscn  text eol=lf
*.tres  text eol=lf
*.gd    text eol=lf
*.cfg   text eol=lf
```

### `project.godot` (extrait des clés qui comptent)

```ini
config_version=5

[application]
config/name="WordEnd"
run/main_scene="res://src/main.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[autoload]
EventBus="*res://src/autoload/event_bus.gd"
GameState="*res://src/autoload/game_state.gd"
SaveManager="*res://src/autoload/save_manager.gd"
SkinRegistry="*res://src/autoload/skin_registry.gd"
WorldManager="*res://src/autoload/world_manager.gd"

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[layer_names]
3d_physics/layer_1="world"
3d_physics/layer_2="player"
3d_physics/layer_3="enemy"
3d_physics/layer_4="hitbox"
3d_physics/layer_5="hurtbox"
3d_physics/layer_6="interactable"
3d_physics/layer_7="pickup"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
```

Actions de l'input map à déclarer au Lot 0 (une entrée `[input]` par action, syntaxe `Object(InputEventKey, … "physical_keycode": 65 …)` générée par l'éditeur ou écrite par l'agent) :

| Action | Clavier (touche physique) | Manette |
| --- | --- | --- |
| `move_left` / `move_right` / `move_forward` / `move_back` | A/D/W/S (= Q/D/Z/S en AZERTY) + flèches | Stick gauche |
| `run` | Maj | Stick gauche enfoncé (L3) |
| `jump` | Espace | A (bouton 0) |
| `attack` | J ou X | X (bouton 2) |
| `charge` | K ou C (maintenu) | B (bouton 1) |
| `interact` | E | A (bouton 0), prioritaire sur `jump` si une invite est affichée |
| `lock_target` | Clic molette | R3 (bouton 8) |
| `inventory` | I | Y (bouton 3) |
| `pause` | Échap | Start (bouton 6) |
| `camera_left` / `camera_right` / `camera_up` / `camera_down` (L0, au lieu de `camera_x` / `camera_y`) | Souris (lue dans le code) | Stick droit |

### `export_presets.cfg`

```ini
[preset.0]
name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/web/index.html"

[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=true
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
```

`thread_support=false` est la clé qui évite les en-têtes COOP/COEP. L'éditeur complète les clés manquantes à la première ouverture ; commite le fichier résultant.

### `.claude/settings.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR\"/tools/session_start.sh", "timeout": 300 }
        ]
      }
    ]
  }
}
```

### `tools/session_start.sh`

```bash
#!/bin/bash
# Reprise de session : LFS, import Godot. Ne fait rien hors du cloud.
[ "$CLAUDE_CODE_REMOTE" = "true" ] || exit 0
cd "$CLAUDE_PROJECT_DIR" || exit 0
git lfs pull >/dev/null 2>&1 || true
tools/godot --headless --import >/dev/null 2>&1 || true
exit 0
```

### `tools/godot`

```bash
#!/bin/bash
# Exécute Godot : binaire natif s'il existe, sinon l'image docker godot-ci.
if command -v godot >/dev/null 2>&1; then
  exec godot "$@"
fi
exec docker run --rm -v "$PWD":/project -w /project -e HOME=/root \
  "barichello/godot-ci:${GODOT_VERSION:-4.7.2}" godot "$@"
```

### `tools/check.sh`

```bash
#!/bin/bash
# Le « vert » du projet : même commande en cloud, en local et en CI.
set -uo pipefail
cd "$(dirname "$0")/.."
G=tools/godot
mkdir -p build/shots
fail() { echo "ROUGE: $1"; exit 1; }

echo "== import"
$G --headless --import 2>&1 | tee build/import.log
grep -Eq "SCRIPT ERROR|ERROR:" build/import.log && fail "erreurs à l'import (build/import.log)"
touch tools/warnings_allow.txt
grep "WARNING" build/import.log | grep -v -F -f tools/warnings_allow.txt \
  && fail "avertissements non tolérés (ajoute-les à tools/warnings_allow.txt s'ils sont légitimes)"

echo "== lint"
gdlint src tests || fail "gdlint"
gdformat --check src tests || fail "gdformat --check (lance gdformat src tests)"

echo "== tests"
$G --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit \
  -gjunit_xml_file=build/junit.xml || fail "tests GUT"

echo "== smoke"
$G --headless --script tools/smoke.gd || fail "scène qui ne s'instancie pas"

echo "== export web"
$G --headless --export-release Web build/web/index.html || fail "export Web"
du -sh build/web

echo "== capture"
tools/screenshot.sh res://src/world/maps/essai/essai.tscn build/shots/essai.png || echo "capture indisponible (pas de Xvfb ou binaire docker)"

echo "VERT"
```

### `tools/screenshot.sh`

```bash
#!/bin/bash
# Usage : tools/screenshot.sh res://chemin/scene.tscn build/shots/nom.png
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p "$(dirname "$2")"
command -v xvfb-run >/dev/null || { echo "xvfb-run absent"; exit 2; }
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
  tools/godot --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/screenshot.gd -- "$1" "$2"
```

### `tools/screenshot.gd`

```gdscript
extends SceneTree
# Charge une scène, attend un vrai rendu, écrit un PNG et quitte.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <scene.tscn> <sortie.png>")
		quit(2)
		return
	var packed: PackedScene = load(args[0])
	if packed == null:
		push_error("scène introuvable: %s" % args[0])
		quit(2)
		return
	get_root().add_child(packed.instantiate())
	for i in 3:
		await process_frame
		await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	var err := image.save_png(args[1])
	quit(0 if err == OK else 1)
```

### `.github/workflows/ci.yml`

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

env:
  GODOT_VERSION: "4.7.2"

jobs:
  check:
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.7.2
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true
      - name: Outils
        run: |
          apt-get update -qq && apt-get install -y -qq --no-install-recommends \
            xvfb libgl1 libgl1-mesa-dri libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
            libfontconfig1 libasound2t64 libpulse0 libdbus-1-3 libudev1 python3-pip >/dev/null
          pip3 install --break-system-packages -q "gdtoolkit==4.*"
      - name: Vérification
        run: tools/check.sh
      - name: Taille du build
        run: |
          size=$(tar -czf - build/web | wc -c)
          echo "build/web compressé : $((size / 1048576)) Mo" >> "$GITHUB_STEP_SUMMARY"
          [ "$size" -lt 157286400 ] || { echo "build > 150 Mo"; exit 1; }
      - uses: actions/upload-artifact@v4
        with: { name: web, path: build/web }
      - uses: actions/upload-artifact@v4
        if: always()
        with: { name: shots, path: build/shots }
      - uses: actions/upload-artifact@v4
        if: always()
        with: { name: junit, path: build/junit.xml }

  deploy:
    if: github.ref == 'refs/heads/main'
    needs: check
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { name: web, path: build/web }
      - name: Fichiers du site (CNAME, page de test)
        run: cp -r web/. build/web/
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with: { path: build/web }
      - id: deployment
        uses: actions/deploy-pages@v4
```

Activer GitHub Pages (Settings → Pages → Source : GitHub Actions) avant le premier push sur `main`. Si l'image `barichello/godot-ci` n'a pas encore de tag `4.7.2`, prendre le dernier tag 4.7.x disponible et aligner `GODOT_VERSION` partout.

## 12. Prompts de lancement

> **(HD-2D)** Le prompt du Lot 0 est celui de la phase 3D, gardé pour l'histoire. Pour un lot H,
> le modèle « lot N » ci-dessous s'applique avec la section 7, « Lots HD-2D, la suite » (exemple
> rempli : Lot H2).

**Deux prompts suffisent : un pour la session Lot 0, un modèle pour chaque lot suivant.** Avant la première session : dépôt `Yume-WordEnd` créé avec les fichiers de la section 11 et `PLAN.md`, Git LFS activé, GitHub Pages sur « GitHub Actions », environnement cloud `wordend-godot` configuré (section 6).

### Session 1 — Lot 0 (socle)

```text
Tu démarres le projet Yume-WordEnd (Godot 4.7.2, GDScript typé, export Web). Lis CLAUDE.md puis
PLAN.md en entier ; les contrats de la section 3 font foi. Tu es le Lot 0 (section 7) : tu crées le
socle sur la branche feat/l0-socle et tu ouvres une PR vers main.

À livrer, dans cet ordre, en commitant à chaque étape :
1. Vérifie l'environnement : `godot --headless --version`, `gdlint --version`, `docker --version`.
   Si godot manque, exécute tools/setup.sh (section 6) et note dans la PR ce qu'il a fallu adapter.
2. project.godot complet (autoloads, input map de la section 11, couches de collision, renderer
   Compatibility), export_presets.cfg, src/main.tscn qui charge src/ui/main_menu.tscn puis
   src/world/island.tscn.
3. src/autoload/* : les cinq autoloads avec exactement les signaux et signatures de la section 3
   (corps minimal, pas de logique métier), plus src/combat/health.gd, hitbox.tscn, hurtbox.tscn,
   attack_data.gd et les class_name de ressources (ItemData, SkinData, NpcData, QuestData,
   EnemyData, AttackData) avec leurs champs exportés.
4. src/world/island.tscn en greybox CSG (160 × 160 m, village/dunes/forêt/plage/colline), sol,
   WorldEnvironment, DirectionalLight3D, eau plane, murs invisibles, Marker3D Spawn par zone,
   quatre Marker3D SpawnN/S/E/W dans la zone dunes.
5. src/player/player.tscn minimal (capsule qui se déplace, caméra SpringArm3D) pour pouvoir
   voir l'île ; le vrai joueur est le Lot 1.
6. Les planches chtholly.* et timere.* sont déjà dans assets/characters/chtholly/ et
   assets/enemies/timere/ : vérifie qu'elles s'importent, crée data/skins/chtholly.tres et
   data/enemies/timere_*.tres qui pointent dessus, et assets/characters/CREDITS.md.
7. tools/gen_placeholders.py (Pillow) qui produit une planche + JSON au format de l'easter egg pour
   un skin de remplacement, et tools/smoke.gd qui instancie chaque .tscn de src/.
8. addons/gut vendoré (dernière version compatible 4.7), tests/stubs/ (joueur et visuel factices),
   tests/unit/test_contracts.gd qui vérifie que chaque autoload expose les signaux et méthodes
   de la section 3.
9. tools/check.sh vert de bout en bout, capture build/shots/island.png jointe à la PR, CI verte.

Contraintes : format texte partout, GDScript typé, aucun chiffre de combat en dur, pas de Thread.
Si un élément du plan est impossible tel quel, fais le choix le plus simple, note-le dans
docs/DECISIONS.md et continue. Termine par un résumé : ce qui est fait, ce qui a été adapté,
ce que les lots suivants doivent savoir.
```

### Sessions suivantes — modèle pour un lot N

```text
Projet Yume-WordEnd (Godot 4.7.2). Lis CLAUDE.md, puis PLAN.md sections 3 (contrats) et 7 ; tu es
le Lot <N> — <nom du lot>. Branche feat/l<N>-<slug> depuis main, une PR vers main à la fin.

Périmètre : uniquement les dossiers possédés par ton lot dans la section 7. Les autres systèmes
n'existent peut-être pas encore : code contre les contrats et crée les stubs dont tes tests ont
besoin dans tests/stubs/, jamais dans src/.

À livrer : les éléments de ton lot décrits dans les sections 4 et 7, les tests GUT listés dans
tes critères d'acceptation, une scène de démonstration tests/integration/demo_l<N>.tscn, et une
capture build/shots/l<N>.png si ton lot touche au rendu.

Boucle de travail : petit incrément → tools/check.sh → commit. Avant la PR : tools/check.sh vert,
gdformat appliqué, description = fait / testé / capture / contrats touchés (idéalement aucun).
Un besoin hors contrat va dans docs/CONTRACT_REQUESTS.md avec une proposition de signature.
```

### Exemple rempli — Lot 4 (combat)

```text
… tu es le Lot 4 — Combat. Branche feat/l4-combat.
Règles à respecter à la lettre (section 4, tableau « Règles de combat ») : 5 PV, invincibilité 1,2 s,
enchaînement sword_1/2/3 à 1 dégât, hitbox active seulement sur les images « coup » transmises par
CharacterVisual.frame_changed, charge 0,55 s minimum, onde 3 dégâts qui traverse (projectile 8 m,
2 m de large), recharge 1,2 s, recul 3 m/s. Tout en data/attacks/*.tres.
Tests obligatoires : dégâts hors images coup refusés ; deux dégâts en moins de 1,2 s refusés ;
charge relâchée à 0,4 s = rien ; onde touche 3 mannequins alignés ; stoic = pas de recul sauf onde.
Démo : tests/integration/demo_l4.tscn avec un joueur stub et 3 mannequins (Health + Hurtbox).
```

### Exemple rempli — Lot H2 (décor de l'entrepôt)

```text
… tu es le Lot H2 — Décor de l'entrepôt. Branche feat/h2-entrepot.
Lis docs/ASSETS_HD2D.md (règles d'échelle, façades) et docs/lore/MONDE.md section 2 (le village).
Tu ne modifies que src/world/zones/village/, les décors du village listés en section 7 et
src/items/placements/village.tscn. Un décor = DecorPanel ou Building (section 3), sa collision
dans l'enfant Collision ; jamais de maillage modélisé. Les PNJ ne bougent pas.
À chaque étape : tools/hd2d_shots.sh village dialogue, ouvre les PNG, compare à l'avant.
Tests : test_hd2d_decor.gd, test_world_story_spots.gd, test_m2_quest.gd verts ; draw calls ≤ 200.
```

### Conseils d'orchestration

- Lance les sessions de la vague 1 le même jour depuis `main` fraîchement fusionné avec L0, pour que toutes partent du même socle.
- Une session par onglet claude.ai/code, chacune dans l'environnement `wordend-godot` ; garde le nom du lot dans le titre de la session.
- Fusionne dès qu'une PR est verte plutôt que par paquet : les suivantes se rebasent sur moins de changements.
- Quand deux lots demandent le même contrat, tranche toi-même dans une PR « contrats » de quelques lignes et demande aux deux sessions de rebaser (`git fetch && git rebase origin/main`).

## 13. Risques, points ouverts et décisions

**Le risque principal n'est pas technique : c'est la sensation de combat, qu'aucun agent sans écran ne peut juger.** Le plan le traite en plaçant le combat au jalon M1, avec ta validation manette en main avant d'ouvrir le reste. Les autres risques ont chacun une parade prévue.

| Risque | Impact | Parade |
| --- | --- | --- |
| Sensation de combat fade ou injuste (timing des coups, recul, caméra) | Le jeu ne donne pas envie de rejouer | Chiffres en données, scène `demo_l4.tscn` jouable dans l'éditeur, itérations courtes avec toi à M1 ; les valeurs de l'easter egg comme point de départ |
| Godot indisponible dans la VM cloud (chemins de l'image docker changés, `docker cp` refusé) | Les sessions ne peuvent rien vérifier | Wrapper `tools/godot` qui bascule sur `docker run` ; repli : publier le binaire Linux et les templates comme asset d'une release du dépôt `Yume-WordEnd` (le proxy GitHub les sert pour un dépôt attaché) |
| Performances Web avec 12 Timeres et des billboards animés | Saccades sur mobile | `AnimatedSprite3D` est peu coûteux ; limiter les lumières à une directionnelle, pas d'ombres temps réel sur mobile, budget draw calls dans la CI |
| Export Web mono-thread et physique | Pics de temps de frame sur les gros groupes | Jolt est le moteur physique par défaut depuis 4.6 ; capsules simples, pas de `SoftBody`, séparation des ennemis par calcul léger |
| Mélange sprites 2D / décor 3D jugé incohérent | Direction artistique floue | (HD-2D) Tout est image à 96 px par mètre, comme les planches : personnages et décor partagent l'échelle, le pixel art et la lumière ; cahier des charges unique `docs/ASSETS_HD2D.md` |
| Images livrées incohérentes entre elles (échelle, lumière, style) | Décor disparate | Bloc de style commun à coller avant chaque consigne, tailles exactes vérifiées par `tools/hd2d_assets.py check` et `test_hd2d_assets.gd`, ordre de commande par priorité ; les remplaçants restent tant qu'une image ne convient pas |
| Propriété intellectuelle (Chtholly, Seniorious, Timere) | Retrait demandé, image de la communauté | Décision avant M4 (ci-dessous) ; architecture qui permet de changer les héros par des données |
| Musique `Scarborough Fair` : enregistrement sans licence claire | Idem | Vérifier l'origine du MP3 ; sinon version libre (Musopen, ccMixter) ou composition originale |
| Compatibilité GUT / gdtoolkit avec 4.7.2 | CI bloquée | Lot 0 fige les versions qui marchent ; repli sur 4.6.3 si une dépendance manque |
| Conflits Git entre lots | Temps perdu en rebases | Propriété exclusive des dossiers, fichiers de contrat gelés, PR courtes, fusion au fil de l'eau |
| Sauvegarde perdue (IndexedDB vidé) | Frustration des joueurs | Export/import JSON de la sauvegarde dans le menu dès M2, synchronisation compte WordPress à M4 |

### Décisions à prendre

- [ ] **Nom et visibilité du dépôt** : `Yume-WordEnd`, public (GitHub Pages gratuit, CI illimitée) ou privé (Pages et minutes CI sous conditions du plan GitHub).
- [ ] **Licence du code** : MIT proposé ; les assets sous licence séparée.
- [ ] **Héros** : rester sur Chtholly en hommage non commercial crédité, ou créer des personnages originaux de la communauté pour le jeu public (Timere peut rester le clin d'œil). À trancher avant M4.
- [ ] **Musique** : conserver l'enregistrement actuel ou le remplacer.
- [x] **Caméra** : (HD-2D, 7 octobre 2026) fixe et inclinée à la manière d'*Octopath Traveler*, léger zoom, verrouillage de cible sans rotation ; l'orbite libre du Lot 1 est retirée.
- [x] **Direction artistique** : (HD-2D, 7 octobre 2026) HD-2D à la manière d'*Octopath Traveler*, uniquement des images ; les modèles 3D sont abandonnés.
- [ ] **Tactile** : contrôles de base à M2 (L9) ou report complet à M3.
- [ ] **Sous-domaine** : `jeu.yumenovel.fr` ou page du site uniquement.

### Points ouverts côté contenu

- Quels skins de la communauté existent déjà sous forme de planches au format de l'easter egg, et lesquels restent à découper.
- Liste des PNJ du village et de leurs liens avec les œuvres traduites (noms, portraits).
- Scénario du premier donjon (M3) et nature du boss.

### Sources

- [Easter egg WordEnd — docs/wordend.md et jeu.js du dépôt Yume-WordPress](https://github.com/GNAlexandre/Yume-WordPress)
- [Configurer les environnements cloud de Claude Code](https://code.claude.com/docs/en/cloud-environments.md)
- [Image Docker godot-ci](https://hub.docker.com/r/barichello/godot-ci)
- [Godot 4.7.2 — annonce de la version de maintenance](https://gamedev.net/news/5172-godot-engine-472-stable-released/)
- [État du support C# et de l'export Web dans Godot 4 en 2026](https://gtstu.com/?p=4758)
- [Unity 6 — plateformes et Web](https://discussions.unity.com/t/unity-6-updates-for-platforms/1529798)
