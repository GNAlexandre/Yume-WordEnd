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
- **Budget Web** : moins de 60 Mo compressés (wasm + pck), avec un écran de chargement ; relevé de 25 à 60 Mo à M2.5 pour garder toutes les images sans perte de qualité (docs/DECISIONS.md).
- **Audio Web** : le navigateur exige un geste utilisateur avant tout son, d'où un écran « Cliquer pour jouer ».
- **Sauvegarde Web** : `user://` est persisté dans IndexedDB par Godot ; une sauvegarde est perdue si le joueur vide les données du site, d'où la synchronisation avec le compte WordPress en M4.

## 3. Architecture du projet

Le projet est découpé en **systèmes indépendants reliés par un bus de signaux**, chacun dans son dossier, pour que plusieurs agents travaillent en même temps sans se marcher dessus. Les contrats ci-dessous sont figés au Lot 0 : un agent qui a besoin de les changer ouvre une PR dédiée avant de continuer.

&#91;embedded content: architecture · 4 systèmes de jeu, EventBus, 4 autoloads et UI, fondations\]

Les quatre systèmes de jeu émettent leurs signaux dans `EventBus` ; HUD, `GameState`, `SaveManager` et `WorldManager` les écoutent. Objets et quêtes appellent aussi l'API de `GameState` (`add_item`, `set_flag`), l'arène appelle `record_score`, et `SaveManager` sérialise `GameState` par `to_dict` / `from_dict`. Chaque boîte est un lot qu'une session cloud peut prendre seule.

### Arborescence

```
Yume-WordEnd/
├── project.godot              # autoloads, input map, couches de collision, renderer
├── export_presets.cfg         # preset "Web" (commit, sans secret)
├── CLAUDE.md                  # règles pour les agents (section 11)
├── PLAN.md                    # ce document, exporté en Markdown
├── .gitignore / .gitattributes
├── gdlintrc                   # (L0) réglages de gdlint (défauts sauf max-public-methods)
├── .claude/settings.json      # hook SessionStart → tools/session_start.sh
├── .github/workflows/ci.yml   # lint + tests + export web + déploiement Pages
├── addons/gut/                # GUT vendoré
├── docs/
│   ├── DECISIONS.md           # choix faits par les agents quand le plan ne suffit pas
│   └── CONTRACT_REQUESTS.md   # besoins de contrat hors périmètre d'un lot
├── tools/
│   ├── setup.sh               # installe Godot + templates (cloud et CI)
│   ├── fetch_templates.py     # (L0) extrait seulement les templates Web du .tpz (requêtes Range)
│   ├── session_start.sh       # reprise de session cloud : LFS, import
│   ├── godot                  # wrapper: binaire natif ou docker ; user:// isolé par worktree (build/xdg)
│   ├── check.sh               # import + gdlint + tests + smoke + export (le "vert" du projet)
│   ├── test.sh                # (L0) tests GUT ciblés (fichier, dossier, test)
│   ├── import.sh              # (L0) import + .uid/.import à commiter + orphelins
│   ├── smoke.gd               # compile src/, tests/, tools/ ; instancie chaque .tscn de src/ et tests/
│   ├── warnings_allow.txt     # avertissements Godot tolérés à l'import
│   ├── screenshot.sh          # rend une scène en PNG sous Xvfb
│   ├── screenshot.gd          # script Godot appelé par screenshot.sh
│   ├── hd2d_shots.sh          # (HD-2D) captures de la vraie partie : menu, cinq zones, conversation, veille
│   ├── hd2d_assets.py         # (HD-2D) images de remplacement : gen, check, fit, atlas (Pillow)
│   ├── hd2d_manifest.json     # (HD-2D) liste exacte des images du décor (chemin, taille, genre)
│   ├── hd2d_art.py, hd2d_ground.py, hd2d_props.py, hd2d_sky.py   # recettes de pixel art
│   └── gen_placeholders.py    # planches de remplacement au format de l'easter egg (Pillow)
├── web/
│   ├── CNAME                  # jeu.yumenovel.fr (copié dans build/web par la CI)
│   └── embed-test.html        # page de test de l'iframe (section 10)
├── src/
│   ├── main.tscn              # racine : menu, chargement, puis game.tscn
│   ├── game.tscn              # (L0) Island + Player + QuestTracker + UI (HUD, dialogue, inventaire…)
│   ├── autoload/              # EventBus, GameState, SaveManager, SkinRegistry, WorldManager
│   ├── player/                # player.tscn, player.gd (déplacement), camera_rig.tscn (caméra fixe HD-2D),
│   │                          # post_fx.gdshader (flou de profondeur, lueur, étalonnage)
│   ├── combat/                # health.gd, hitbox.tscn, hurtbox.tscn, attack_data.gd,
│   │                          # player_combat.gd (épée, charge), charge_wave.tscn (onde)
│   ├── enemies/               # enemy.tscn, enemy.gd (machine à états), enemy_data.gd,
│   │                          # wave_director.gd, arena.tscn, arena.gd, placements/<zone>.tscn
│   ├── visuals/               # character_visual.tscn (billboard de la planche), sheet_loader.gd, skin_data.gd
│   ├── world/                 # island.tscn, zone.gd, zones/<zone>/<zone>.tscn, terrain.gd (relief), island_rock.gd,
│   │                          # (HD-2D) decor_panel.gd, building.gd, prop_batcher.gd, prop_scatter.gd,
│   │                          # props/<nom>.tscn (un décor = un panneau ou un bâtiment), shaders/, materials/
│   ├── npc/                   # npc.tscn, npc.gd, npc_data.gd, dialogue_runner.gd, placements/<zone>.tscn
│   ├── items/                 # item_data.gd (Resource), pickup.tscn, placements/<zone>.tscn
│   ├── quests/                # quest_data.gd, quest_step.gd, quest_tracker.gd, quest_trigger.tscn (Lot Q)
│   └── ui/                    # hud, dialogue_box, inventory, main_menu, loading, touch_controls,
│                              # arena_end, credits, journal (Lot Q, enfant du HUD)
├── data/
│   ├── attacks/*.tres         # sword_1..3, charge_wave, bite, whip, rush
│   ├── enemies/*.tres         # timere_small, timere_normal, timere_runner, timere_big ; visuals/timere.tres
│   ├── waves/*.json           # composition des vagues par arène
│   ├── items/*.tres
│   ├── npcs/*.tres
│   ├── quests/*.json          # (Lot Q) quêtes en étapes, format : docs/QUETES.md
│   ├── skins/*.tres
│   ├── dialogues/*.json
│   └── texts/story.json       # (Systèmes et textes) textes de l'histoire hors dialogues :
│                              # arène, chute, défaite (DialogueRunner.story_text)
├── assets/
│   ├── CREDITS.md             # assets tiers (URL, licence)
│   ├── characters/CREDITS.md  # dessins des membres (auteur, accord)
│   ├── characters/<skin_id>/  # planche PNG + .json (format de l'easter egg)
│   ├── enemies/<enemy_id>/    # idem pour les Timeres
│   ├── hd2d/                  # (HD-2D) ground/ (+ atlas/), cliff/, buildings/ (+ materials/), props/, sky/, fx/
│   ├── items/, ui/            # icônes 64 × 64, interface
│   └── audio/
├── tests/
│   ├── stubs/                 # joueur factice, visuel factice, mannequins pour les tests
│   ├── unit/                  # test_*.gd (GUT)
│   └── integration/           # scènes de fumée et démos par lot (demo_l<N>.tscn), (HD-2D) demo_hd2d.tscn
└── build/                     # ignoré par git
```

### Autoloads (singletons)

| Autoload | Rôle | Propriétaire (lot) |
| --- | --- | --- |
| `EventBus` | Tous les signaux transverses ; aucune logique | L0 |
| `GameState` | PV max, inventaire, drapeaux (`flags`), état des quêtes, (Lot Q) étape courante et compteur de chaque quête active, quête suivie, skin actif, meilleurs scores par arène ; sérialisable en Dictionary | L7 |
| `SaveManager` | Écrit/lit `user://save_v1.json` (nom historique ; schéma v2 depuis le Lot Q), versionne le schéma, migre | L8 |
| `SkinRegistry` | Charge `data/skins/*.tres`, expose la liste et le skin par défaut (Chtholly) | L3 |
| `WorldManager` | Charge/décharge les zones, gère les points d'apparition, la téléportation et la réapparition après la mort | L2 |

### Contrats d'interface

```gdscript
# src/autoload/event_bus.gd — signaux (émis par le système source, écoutés partout).
# (L0) = ajouté ou précisé au Lot 0 ; l'émetteur de chaque signal est aussi documenté dans le fichier.
# Combat
signal player_health_changed(current: int, max_value: int)   # PlayerCombat ; 1re émission différée après _ready (valeur initiale du HUD)
signal player_damaged(amount: int, source: Node3D)            # PlayerCombat
signal player_died()                                          # PlayerCombat ; WorldManager appelle respawn() respawn_delay s plus tard
signal player_respawned()                                     # WorldManager.respawn() ; PlayerCombat remet alors les PV au maximum
signal player_heal_requested(amount: int)                     # (L0) WaveDirector → PlayerCombat (1 PV toutes les deux vagues)
signal enemy_spawned(enemy: Node3D, enemy_id: StringName)     # Enemy, dans son _ready
signal enemy_damaged(enemy: Node3D, amount: int)              # Enemy
signal enemy_killed(enemy_id: StringName, points: int)        # Enemy ; le WaveDirector actif compte les points
signal wave_started(arena_id: StringName, wave: int, enemy_count: int)   # WaveDirector
signal wave_cleared(arena_id: StringName, wave: int, bonus: int)         # WaveDirector
signal arena_score_changed(arena_id: StringName, score: int)  # (L0) WaveDirector → HUD (score courant)
signal arena_finished(arena_id: StringName, score: int, best: bool)      # WaveDirector, après GameState.record_score
signal charge_progress(ratio: float)        # 0..1, jauge de la charge magique (PlayerCombat)
# Monde et interaction
signal item_collected(item_id: StringName, quantity: int)    # Pickup, après GameState.add_item
signal inventory_changed()                                    # GameState (add_item, remove_item, from_dict, reset)
signal interaction_available(prompt: String)   # "" = aucune ; émis par le joueur
signal dialogue_started(npc_id: StringName)                   # DialogueRunner (le joueur s'arrête)
signal dialogue_line(speaker: String, text: String, choices: Array[String])   # DialogueRunner
signal dialogue_choice_made(index: int)       # (L0) DialogueBox → DialogueRunner actif ; -1 = « suite » sans choix
signal dialogue_ended(npc_id: StringName)                     # DialogueRunner (le joueur repart)
signal quest_updated(quest_id: StringName, state: StringName)  # available|active|done ; GameState.set_quest_state
signal zone_entered(zone_id: StringName)                      # Zone (Area3D « Bounds ») ; (M2) au changement de zone seulement
signal day_phase_changed(phase: StringName)   # morning|day|evening|night (M3)
signal skin_changed(skin_id: StringName)                      # GameState, quand skin_id change ; le joueur l'applique
signal max_hp_changed(max_value: int)          # (L0) GameState, quand max_hp change → PlayerCombat
signal save_requested()                                       # n'importe qui → SaveManager.save()
signal game_loaded()                                          # SaveManager (new_game, load_game, import_json) → main.gd
# (Lot Q) Quêtes en étapes — format et règles : docs/QUETES.md
signal flag_changed(flag: StringName, value: bool)            # GameState.set_flag, si la valeur change
signal quest_step_updated(quest_id: StringName, step_id: StringName, count: int)   # GameState.set_quest_step (QuestTracker) ; step_id &"" : plus d'étape
signal quest_step_completed(quest_id: StringName, step_id: StringName)   # QuestTracker, étape validée (auto-sauvegarde)
signal quest_advance_requested(quest_id: StringName, step_id: StringName)   # DialogueRunner (advance_quest) ou autre → QuestTracker ; &"" : l'étape courante
signal trigger_entered(trigger_id: StringName)                # QuestTrigger, le joueur y entre → QuestTracker (étapes reach)
signal tracked_quest_changed(quest_id: StringName)            # GameState, quand tracked_quest change → HUD

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
# (L0) Relais à conserver : Health du joueur → player_health_changed / player_damaged / player_died ;
# player_respawned → Health.reset() ; player_heal_requested → Health.heal() ; max_hp_changed → Health.max_hp ;
# au départ Health.max_hp = GameState.max_hp. Voisins par nom (../Health, ../Visual, ../Hurtbox, SwordHitbox),
# données par chemin (data/attacks/*.tres).

# src/enemies/enemy.gd — machine à états commune (class_name Enemy, extends CharacterBody3D, @export var data: EnemyData)
# états : idle → chase → attack → hurt → dead ; rush pour le coureur ; stoic = pas de recul sauf onde
class_name EnemyData : id, display_name, visual: SkinData, scale: float, max_hp: int, speed: float,
                       points: int, attacks: Array[AttackData], rush: bool, stoic: bool,
                       aggro_range_m: float, drops: Dictionary[StringName, float]   # item_id → probabilité

# src/enemies/wave_director.gd — un par arène (enfant "WaveDirector" de arena.tscn), lit data/waves/<arena_id>.json
func start() -> void
func stop() -> void
func current_wave() -> int
func compose(wave: int) -> Array[StringName]   # ids d'ennemis de la vague (liste explicite ou generator)
# (L0) class_name Arena (racine de arena.tscn) : @export var arena_id: StringName ;
#      func spawn_point(marker_name: StringName) -> Marker3D   # Marker3D frère de l'Arena dans sa zone

# src/autoload/game_state.gd — API publique
func add_item(item_id: StringName, quantity: int = 1) -> void
func remove_item(item_id: StringName, quantity: int = 1) -> bool
func count(item_id: StringName) -> int
func items() -> Dictionary                                       # (L0) copie item_id → quantité, pour l'UI
func set_flag(flag: StringName, value: bool = true) -> void
func has_flag(flag: StringName) -> bool
func quest_state(quest_id: StringName) -> StringName             # (L0) &"" si inconnue
func set_quest_state(quest_id: StringName, state: StringName) -> void   # (L0) émet quest_updated si l'état change
func mark_pickup_collected(pickup_id: StringName) -> void        # (L0)
func is_pickup_collected(pickup_id: StringName) -> bool          # (L0)
func record_score(arena_id: StringName, score: int, wave: int) -> bool   # true si meilleur score (strictement)
func best_score(arena_id: StringName) -> int
func reset() -> void                                             # (L0) nouvelle partie
func to_dict() -> Dictionary                # (L0) exactement les champs du schéma de sauvegarde, sauf version et saved_at
func from_dict(data: Dictionary) -> void     # (Lot Q) n'émet ni quest_updated ni quest_step_updated : QuestTracker relit tout sur game_loaded
func quests() -> Dictionary                  # (L7) copie quest_id → état, dans l'ordre où chaque quête a reçu son premier état
func quest_step(quest_id: StringName) -> StringName        # (Lot Q) étape courante enregistrée (QuestStep.id), &"" sinon
func quest_step_count(quest_id: StringName) -> int         # (Lot Q) compteur de l'étape (ennemis vaincus, vague ou score atteints)
func set_quest_step(quest_id: StringName, step_id: StringName, step_count: int = 0) -> void   # (Lot Q) émet quest_step_updated si quelque chose change ; &"" efface
func quest_progress() -> Dictionary          # (Lot Q) copie quest_id → {"step", "count"}
var tracked_quest: StringName                # (Lot Q) quête suivie par le HUD ; émet tracked_quest_changed ; &"" = la première quête active
var skin_id: StringName      # (L0) &"" = skin par défaut ; émet skin_changed
var max_hp: int              # (L0) 5, puis 6 (acte 1 : la promesse du gâteau au beurre), 7 (registre des veilles) ; émet max_hp_changed
var zone: StringName         # (L0) tenue par WorldManager (zone_entered) ; &"" = nouvelle partie pas encore placée
var position: Vector3        # (L0) tenue par le joueur quand il est au sol

# src/autoload/save_manager.gd
func has_save() -> bool
func save() -> Error
func load_game() -> Error                 # remplit GameState, émet game_loaded
func new_game(skin_id: StringName) -> void   # (L0) GameState.reset() puis émet game_loaded
func export_json() -> String / func import_json(text: String) -> Error   # menu, section 13 ; import émet game_loaded
var save_path: String = "user://save_v1.json"   # (L0) les tests en utilisent un autre ; (Lot Q) le nom ne suit pas la version
const SAVE_VERSION := 2                   # (Lot Q) v2 : quest_progress et tracked_quest ; v1 → v2 migrée (quête active : 1re étape)
func save_on_leave() -> Error             # (M2) focus perdu, fermeture, page masquée : écriture en attente, sinon état s'il a changé
func has_unsaved_changes(tolerance: float = 0.05) -> bool   # (M2) GameState diffère de la dernière écriture (position : au-delà de tolerance m)
var checkpoint_interval: float = 5.0      # (M2) position écrite toutes les 5 s de jeu si le joueur a bougé de checkpoint_distance (1 m)

# src/autoload/skin_registry.gd
func all() -> Array[SkinData]
func get_skin(skin_id: StringName) -> SkinData
func default_skin() -> SkinData

# src/autoload/world_manager.gd
func load_zone(zone_id: StringName) -> void
func teleport(zone_id: StringName, marker: StringName = &"Spawn") -> void
func respawn() -> void                    # village, PV pleins, émet player_respawned
func current_zone() -> StringName
func zone_display_name(zone_id: StringName) -> String   # (L0) Zone.display_name, pour le HUD
func is_zone_safe(zone_id: StringName) -> bool   # (M1) Zone.safe de la zone (faux si inconnue) ; IA des Timeres
var respawn_delay: float = 2.2            # (L0) délai entre player_died et respawn()
signal rescued(zone_id: StringName)       # (Systèmes et textes) rescue() a rattrapé le joueur au Spawn de
                                          # zone_id → HUD : fondu au blanc et « Tes ailes se sont ouvertes… »

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
signal frame_changed(anim: StringName, frame: int)   # permet à la Hitbox de s'activer sur les images "coup"
signal animation_finished(anim: StringName)

# data/*.tres — ressources
class_name ItemData   : id, display_name, icon, stackable, max_stack, description
class_name SkinData   : id, display_name, sprite_sheet, frames_json: JSON, portrait, height_m   # (HD-2D) sans mesh_scene
class_name NpcData    : id, display_name, skin, dialogue_path, quest_id, home_zone
                        # (Systèmes et textes) visible_if: Dictionary (présence, même grammaire que les « if »
                        # de dialogue) ; is_present() (faux aussi si skin = celui du joueur), is_player_skin(),
                        # visible_if_problem()
class_name QuestData  : id, title, giver_npc, required_items: Dictionary[StringName, int], required_flags: Array[StringName],
                        reward_items: Dictionary[StringName, int]
                        # (L7) objective, reward_max_hp ; (Lot Q) lue dans data/quests/<id>.json : summary, main, auto_start,
                        # prereq_quests, prereq_flags, prereq_not_flags, steps: Array[QuestStep], reward_flags ;
                        # static find(id), all(), problem(data, file_id), state_of(id), npc_marker(npc_id), active_ids(),
                        # done_ids(), shown_quest() ; status() (&"available" calculé, jamais écrit), current_step(),
                        # current_objective(), current_progress() ; required_* : héritage L7 (quêtes construites en code)
class_name QuestStep  : (Lot Q) id, type (talk|reach|kill|collect|arena|flag), objective, hint, npc, zone, trigger, enemy
                        (&"any"), item, count, consume, arena, wave, score, flag, reward_items, reward_flags, reward_max_hp

# (L0) Autres classes partagées
class_name Zone            # racine d'une zone : @export display_name: String, @export safe: bool ; func zone_id() -> StringName
class_name Player          # player.gd (L1)
class_name Pickup          # @export item_id: StringName, quantity: int, persistent: bool ; func collect(), pickup_id()
class_name Npc             # @export data: NpcData ; (Systèmes et textes) is_present(), refresh_presence() :
                           # absent = caché, process_mode DISABLED (ni collision ni InteractArea), sans invite,
                           # dialogue ni marqueur ; réévalué en fin d'image sur les signaux de quête, drapeaux,
                           # inventaire, game_loaded, skin_changed, arena_finished (après le dialogue en cours)
class_name DialogueRunner  # start(npc: NpcData), stop(), is_running() ; un par PNJ
                           # (Systèmes et textes) statiques : current_speaker_id() (speaker_id du nœud ou PNJ
                           # du dialogue, fixé avant dialogue_line), find_npc(id), add_npc_dir / remove_npc_dir,
                           # format_text() ({player}, {count:…}, {left:…}, {best:…}), player_name(), player_skin(),
                           # evaluate(), condition_problem(), story_text(chemin), arena_text(arène, clé),
                           # load_story_texts(), story_problem(), clear_story_cache()
class_name QuestTracker    # Node unique de game.tscn (seul le 1er du groupe quest_tracker agit) ; (Lot Q) fait avancer les étapes
                           # par l'EventBus, récompenses, enchaînement (prérequis, auto_start), quête suivie ; à &"done" posé
                           # par un autre système (complete_quest) : étapes restantes validées si les objets des étapes collect
                           # restantes sont là, sinon remise à &"active" (completion_refused) ; signal quest_completed(quest_id)
class_name QuestTrigger    # (Lot Q) src/quests/quest_trigger.tscn, Area3D couche 0 / masque 2 : trigger_id (défaut : nom du
                           # nœud), radius, height, set_flag ; émet trigger_entered ; à poser dans src/npc/placements/<zone>.tscn
class_name SheetLoader     # lecture des planches (read_sheet, build_frames, hit_frames, wave_frame, pixel_size)
# (HD-2D) Décor et caméra
class_name DecorPanel      # src/world/decor_panel.gd : racine d'un décor en panneau ; @export texture, pixels_per_meter (96),
                           # shadow_width, shadow_depth, keep_orientation, image_offset, tint, glow ; size_m() ; statiques
                           # quad_mesh(size), material_for(image, tint, glow), PIXELS_PER_METER, PANEL_SHADER ; l'image se
                           # tourne vers le sud, la collision (enfant « Collision », couche 1) garde la rotation du nœud
class_name Building        # src/world/building.gd : volume (murs, toit long ou pignon) en matières sans raccord + façade sud
                           # en image ; @export facade, wall_texture, roof_texture, footprint, wall_height, ridge_height,
                           # gable_front, overhang, window_glow ; surface_material(texture, relief)
class_name PropBatcher     # src/world/prop_batcher.gd, nœud « Geometry » des zones : fond les MeshInstance3D à
                           # material_override en un mesh par image et par case (« Batch… ») ; @export cell_size
# src/player/camera_rig.gd (racine CameraRig de camera_rig.tscn, sans class_name) : caméra fixe vers le nord
@export pitch_deg (32), fov_deg (30), focus_height, distance (21), min_distance, max_distance, follow_speed, lead_time,
        limits: Rect2 (bornes du point visé), lock_focus, lock_focus_max
var lock_target: Node3D, follow_velocity: Vector3   # posés par le joueur à chaque image physique
func update_camera(delta, zoom_axis := 0.0), focus_goal(with_lead := true) -> Vector3, snap(), snap_behind(_dir) (= snap),
     recenter_behind(_dir) (sans effet), zoom(amount), zoom_distance(), focus(), yaw() (0), pitch(), forward() (le nord)
```

### Conventions

- Nœuds et fichiers en `snake_case`, classes en `PascalCase` via `class_name`, signaux au passé (`item_collected`).
- Un système ne lit jamais un autre système directement : il passe par `EventBus` ou par l'API de `GameState`.
- Couches de collision fixées au Lot 0 : 1 `world`, 2 `player`, 3 `enemy`, 4 `hitbox`, 5 `hurtbox`, 6 `interactable`, 7 `pickup`. Le joueur et les ennemis ne se traversent pas ; les hitbox ne touchent que les hurtbox.
- Les chiffres de combat vivent dans `data/attacks` et `data/enemies`, jamais en dur dans un script : l'équilibrage se fait sans toucher au code.
- Le joueur est toujours le nœud unique du groupe `player` ; les ennemis vivants sont dans le groupe `enemies`.
- Les zones sont des scènes racine `Node3D` nommées comme leur `zone_id`, avec un `Marker3D` nommé `Spawn` ; une arène est une zone qui contient un `WaveDirector`.
- Toute scène doit s'ouvrir et se fermer sans erreur en headless : c'est le test de fumée minimal (section 9).
- (HD-2D) Le décor est fait d'images à 96 px par mètre : un décor de `src/world/props/` a pour racine un `DecorPanel` ou un `Building` (ou un nœud qui en contient, comme la passerelle), sa collision dans un enfant `Collision` (StaticBody3D, couche 1). Aucun maillage modélisé ni forme calculée pour l'apparence. La caméra regarde toujours le nord : le haut de l'écran est le nord.

### Structure figée au Lot 0

Les lots tournent en parallèle et référencent les scènes des autres par leur chemin définitif. Les fichiers ci-dessous existent depuis le Lot 0, à leur chemin final, avec leur `class_name`, leurs nœuds nommés et leurs groupes. **Chaque lot remplit les squelettes de ses dossiers ; personne ne déplace ni ne renomme un fichier ou un nœud nommé de cette liste** (le propriétaire peut ajouter des nœuds et des fichiers). Les scènes `main` et `game` sont des fichiers d'intégration : elles ne changent que dans une PR « contrats » ou d'intégration.

| Fichier | Racine (type, `class_name`) | Nœuds nommés | Groupe, couches | Lot |
| --- | --- | --- | --- | --- |
| `src/main.tscn` + `main.gd` | `Main` (Node) | menu, chargement et partie ajoutés à l'exécution | — | L0 |
| `src/game.tscn` + `game.gd` | `Game` (Node3D) | `Island`, `Player`, `QuestTracker`, `UI` (CanvasLayer) avec `UI/HUD`, `UI/DialogueBox`, `UI/Inventory`, `UI/ArenaEnd`, `UI/TouchControls` | — | L0 |
| `src/player/player.tscn` + `player.gd` | `Player` (CharacterBody3D, `Player`) | `CollisionShape3D`, `Visual`, `Combat` (`PlayerCombat`) et `Combat/SwordHitbox` (`Hitbox`), `Health` (5 PV, 1,2 s), `Hurtbox`, `CameraRig` ((HD-2D) aux pieds du joueur) | `player` ; couche 2, masque 1+3 | L1 (L4 : valeurs du nœud `Health`) |
| `src/player/camera_rig.tscn` | `CameraRig` (Node3D) | (HD-2D) `Camera3D` (courante, `top_level`), `PostFX` (CanvasLayer, couche −1) et `PostFX/Screen` (ColorRect, `post_fx.gdshader`) ; plus de `SpringArm3D` | — | L1 |
| `src/combat/hitbox.tscn` + `hitbox.gd` | `Hitbox` (Area3D) | `CollisionShape3D` (forme locale à la scène) | couche 4, masque 5 | L4 |
| `src/combat/hurtbox.tscn` + `hurtbox.gd` | `Hurtbox` (Area3D) | `CollisionShape3D` (forme locale à la scène) | couche 5 | L4 |
| `src/combat/charge_wave.tscn` | `ChargeWave` (Node3D) | `Hitbox` (attaque `charge_wave`, équipe `player`), `Mesh` | — | L4 |
| `src/combat/health.gd`, `attack_data.gd`, `player_combat.gd` | `Health`, `AttackData`, `PlayerCombat` | — | — | L4 |
| `src/visuals/character_visual.tscn` + `.gd` | `CharacterVisual` (Node3D) | `Sprite` (AnimatedSprite3D billboard) | — | L3 |
| `src/visuals/skin_data.gd`, `sheet_loader.gd` | `SkinData`, `SheetLoader` | — | — | L3 |
| `src/enemies/enemy.tscn` + `enemy.gd` | `Enemy` (CharacterBody3D) | `CollisionShape3D`, `Visual`, `Health`, `Hurtbox`, `Hitbox` | `enemies` (vivants) ; couche 3, masque 1+2+8 | L5 |
| `src/enemies/arena.tscn` + `arena.gd` | `Arena` (Node3D) | `WaveDirector` | — | L5 |
| `src/enemies/enemy_data.gd`, `wave_director.gd` | `EnemyData`, `WaveDirector` | — | — | L5 |
| `src/items/pickup.tscn` + `pickup.gd` | `Pickup` (Area3D) | `CollisionShape3D`, `Mesh` | `interactable` ; couche 7, masque 2 | L7 |
| `src/items/item_data.gd`, `src/quests/quest_data.gd`, `quest_tracker.gd` | `ItemData`, `QuestData`, `QuestTracker` | — | — | L7 |
| (Lot Q) `src/quests/quest_step.gd`, `quest_trigger.tscn` + `quest_trigger.gd` | `QuestStep` (Resource), `QuestTrigger` (Area3D) | `CollisionShape3D` (cylindre propre à chaque déclencheur) | couche 0, masque 2 | Lot Q |
| `src/npc/npc.tscn` + `npc.gd` | `Npc` (CharacterBody3D) | `CollisionShape3D`, `Visual`, `InteractArea` (Area3D, couche 6), `DialogueRunner`, (Lot Q) `QuestMarker` (Label3D « ! » / « ? ») | `interactable` ; couche 1 | L6 |
| `src/npc/npc_data.gd`, `dialogue_runner.gd` | `NpcData`, `DialogueRunner` | — | — | L6 |
| `src/world/island.tscn` + `island.gd` | `Island` (Node3D) | `WorldEnvironment` ((HD-2D) ciel panoramique `assets/hd2d/sky/sky.png`), `Sun`, `OverviewCamera`, `Ground` (relief, tuiles de l'atlas du sol), `Water` (mer de nuages texturée), `Walls`, `KillZone`, `Zones` et `Zones/<zone_id>` pour les 5 zones | — | L2 |
| `src/world/zones/<zone_id>/<zone_id>.tscn` + `src/world/zone.gd` (`village`, `dunes`, `forest`, `beach`, `hill`) | `<zone_id>` (Node3D, `Zone`) | `Spawn` (Marker3D), `Bounds` (Area3D, masque 2), `Geometry` ((HD-2D) `PropBatcher` : décors `src/world/props/` en images), `NPCs`, `Enemies`, `Pickups` ; dunes : `SpawnN`, `SpawnS`, `SpawnE`, `SpawnW`, `Arena` (`arena_id = &"dunes"`) ; village : `EnemyBarrier` (couche 8), `safe = true` | `zones` | L2 |
| `src/npc/placements/<zone_id>.tscn` | `NPCs` (Node3D), instancié dans chaque zone | PNJ de la zone et (Lot Q) déclencheurs de quête `QuestTrigger` (coordonnées locales à la zone) | — | L6 |
| `src/enemies/placements/<zone_id>.tscn` | `Enemies` (Node3D ; (acte 1) script `src/enemies/free_enemies.gd`) | ennemis libres de la zone (forêt : 4 Timeres), qui reviennent pendant une étape « vaincre » qui les vise | — | L5 |
| `src/items/placements/<zone_id>.tscn` | `Pickups` (Node3D) | objets uniques, nommés `<zone>_<objet>_<n>` (ex. `forest_page_1`) | — | L7 |
| `src/ui/main_menu.tscn` + `.gd` | `MainMenu` (Control) | `%NewGameButton` | — | L10 |
| `src/ui/hud.tscn`, `arena_end.tscn`, `credits.tscn` | `HUD`, `ArenaEnd`, `Credits` (Control) | `HUD/PauseMenu` (L10), (Lot Q) `HUD/Journal` (`src/ui/journal.tscn`, PROCESS_MODE_ALWAYS ; (Systèmes et textes) script `src/ui/hud_journal.gd`, qui étend journal.gd : textes de quête avec `{player}`) | — | L10 |
| `src/ui/dialogue_box.tscn` | `DialogueBox` (Control) | — | — | L6 |
| `src/ui/inventory.tscn` | `Inventory` (Control) | — | — | L7 |
| `src/ui/loading.tscn`, `touch_controls.tscn` | `Loading`, `TouchControls` (Control) | `Loading` : `set_progress(ratio: float)` facultatif, appelé par main.gd ; (M2) `load_scene(path, budget_ms)` qui charge la partie en plusieurs images, utilisée par main.gd si présente | — | L9 |

**Données présentes au Lot 0** : `data/attacks/{sword_1,sword_2,sword_3,charge_wave,bite,whip,rush}.tres` (L4) ; `data/enemies/timere_{small,normal,runner,big}.tres` et `data/enemies/visuals/timere.tres` (L5, visuel hors de `data/skins/` pour ne pas être jouable) ; `data/skins/chtholly.tres` et trois skins de PNJ de remplacement (L3 ; silhouettes de `tools/gen_placeholders.py`, retirés à l'acte 1 : les PNJ ont leurs visuels non jouables dans `data/npcs/visuals/`) ; `data/waves/dunes.json` (L5, sans `music` tant qu'il n'y a pas d'audio). `data/items/`, `data/quests/` (L7), `data/npcs/` et `data/dialogues/` (L6) sont à créer. Le nom de fichier d'une donnée est son `id`. (Lot Q) Les quêtes sont des JSON (`data/quests/<id>.json`, `pages.json` remplace `pages.tres`) ; les quêtes, PNJ, dialogues et emplacements d'exemple des tests vivent dans `tests/data/`.

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
| Barrière du village | 8 `enemy_barrier` (128) | — |
| `Bounds` des zones, `KillZone` | — | 2 (2) |

**Actions d'entrée** : `move_left`, `move_right`, `move_forward`, `move_back`, `run`, `jump`, `attack`, `charge`, `interact`, `lock_target`, `inventory`, `journal` (Lot Q : Tab, L, bouton Select / Back), `pause`, `camera_left`, `camera_right`, `camera_up`, `camera_down` (stick droit ; la souris se lit dans le code). Les contrôles tactiles (L9) émettent ces actions.

**Repères de l'île** : sol à y = 0, île de 160 × 160 m centrée sur l'origine, nord = −Z, ouest = −X. Village au centre (`Bounds` ±22 m, `Spawn` local (0, 0,2, 9)) ; dunes à x = −51 (`Spawn` côté village (24, 0,2, 0), arène de 12 m de rayon au centre, `SpawnN/S/E/W` à 13 m) ; forêt à z = −51 ; plage à z = +51 ; colline à x = +51. Les cinq zones pavent l'île : chaque pas sur l'île est dans une zone.

**Tests** : (Lot Q) base des tests de quêtes `tests/stubs/q_quest_test.gd`, contenu des quêtes vérifié par `tests/unit/test_quest_content.gd` ; stubs dans `tests/stubs/` (`visual_stub.tscn` hérite de `character_visual.tscn` et émet `frame_changed` / `animation_finished` à la demande, `player_stub.tscn` du groupe `player` avec Health et Hurtbox, `dummy.tscn` mannequin du groupe `enemies`), sans `class_name`. `tests/unit/test_contracts.gd` vérifie tout ce qui précède : un lot qui le fait échouer a cassé un contrat. Propriété des tests du Lot 0 : `test_health.gd` passe à L4, `test_game_state.gd` à L7, `test_save_roundtrip_l0.gd` à L8 (ils peuvent les adapter à leur implémentation) ; `test_contracts.gd`, `test_stubs_l0.gd`, `tests/integration/test_game_flow_l0.gd` et les stubs existants ne changent que dans une PR « contrats ». Un lot qui a besoin d'un autre stub en crée un nouveau fichier (`tests/stubs/<lot>_<nom>.gd`/`.tscn`, sans `class_name`).

## 4. Tranche verticale : WordEnd en HD-2D

La tranche verticale **recrée l'easter egg dans un monde en relief** ((HD-2D) personnages en sprites, décor en images, caméra fixe) (Chtholly contre des vagues de Timeres sur les dunes au couchant, mêmes règles, même score) **et l'entoure d'un début de monde** : un village sûr avec trois PNJ, une quête, des objets, et une forêt où quelques Timeres rôdent librement. Elle est jouable dans le navigateur à la fin du jalon M2 et fixe la sensation de combat pour tout ce qui suit.

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
| Caméra | `src/player/camera_rig.tscn` (`Camera3D` + `PostFX`) | (HD-2D) Fixe, à la manière d'*Octopath Traveler* : regarde le nord, inclinée de 32°, champ vertical de 30°, à 21 m du point visé ; suit le joueur avec un léger retard (et un peu en avant de sa marche), bornée à l'île ; molette ou stick droit : léger zoom (14 à 25 m) ; **verrouillage de cible** (clic molette / R3) : le point visé avance vers la cible, le joueur lui fait face ; post-traitement sous l'interface : flou de profondeur, lueur, étalonnage chaud |
| Visuel | `src/visuals/character_visual.tscn` | `AnimatedSprite3D` billboard axe Y (face à la caméra fixe), 7 animations de la planche (`repos`, `marche`, `course`, `attaque`, `charge`, `degats`, `mort`), (HD-2D) `parle` pour les PNJ en conversation, retournement gauche/droite selon la direction, ombre disque ; `frame_changed` et `animation_finished` |
| Timeres | `src/enemies/enemy.tscn` + `data/enemies/timere_*.tres` | Machine à états : `idle` (errance) → `chase` (droit vers le joueur, séparation entre ennemis) → `attack` à portée (morsure/fouet, dégâts sur images `coup`) → `hurt` (recul 0,35 s, sauf Grand) → `dead` (animation 6 images, disparaît après 2,2 s, points). Coureur : `rush` en ligne droite dès 8 m |
| Arène des dunes | `src/world/zones/dunes/dunes.tscn` + `src/enemies/arena.tscn` | Zone ouest, coucher de soleil (ciel inspiré de `decor.webp`), 4 points d'apparition, `WaveDirector` lisant `data/waves/dunes.json` ; un panneau `Interactable` lance les vagues et la musique (invite « Sonner la cloche de veille », titre de fin « Fin de la veille » : `data/texts/story.json`) ; sortir de l'arène entre deux vagues met fin à la série et enregistre le score |
| Forêt | `src/world/zones/forest/` | 4 Timeres (2 petits, 1 normal, 1 coureur) en libre, sans vagues ; tués, ils restent morts jusqu'au rechargement de la partie, sauf pendant une étape « vaincre » qui les vise (rejetons de l'acte 1) : ils reviennent quand elle commence et quand le joueur rentre dans les bois ; (Systèmes et textes) noms de l'acte 1 (rejeton, fragment, Timere bondissant, grand fragment) et aucun drop : Timere ignore les objets (V3) |
| Île | `src/world/island.tscn` | Île flottante de 160 × 160 m (relief calculé, places de HISTOIRE.md 3.3 garanties) : village (centre), dunes (ouest), forêt (nord), port (sud), colline (est). (HD-2D) Sol en tuiles de pixel art mélangées par zone et par masque (atlas `assets/hd2d/ground/atlas/ground_atlas.png`, `terrain.gdshader`), falaises et dessous texturés (`rock.gdshader`), bâtiments en volumes avec façades en images (`Building`), décors en panneaux avec ombre douce (`DecorPanel`), fondus par image (`PropBatcher`), ciel panoramique, mer de nuages texturée, lanternes éclairées ; murs invisibles et rattrapage sous l'île |
| Zones | `src/world/zones/*` | Chaque zone = scène fille avec `Area3D` qui émet `zone_entered` ; `WorldManager` charge toutes les zones au départ en M2 (streaming en M3) ; le village est une zone `safe` où aucun ennemi n'entre |
| PNJ | `src/npc/npc.tscn` | (acte 1) les PNJ de docs/lore/HISTOIRE.md 3.3 dans les cinq zones (Nygglatho, Willem et les fées à l'entrepôt, Pannibal aux bois, le guetteur au Couchant, Limeskin et les gens du bourg au port), visuels non jouables `data/npcs/visuals/` ; présents selon l'histoire (`NpcData.visible_if`) ; regardent le joueur à moins de 4 m ; `interact()` lance `DialogueRunner` |
| Dialogue | `src/ui/dialogue_box.tscn` + `src/npc/dialogue_runner.gd` | Boîte en bas d'écran, portrait (celui de l'orateur du nœud, `speaker_id`), texte lettre par lettre, choix (2 max), conditions sur `flags`, `count` et état de quête ; `{player}` : prénom de la protagoniste (skin choisi) |
| Objets | `src/items/pickup.tscn` | Objet flottant, ramassage par `interact()` ou contact ; émet `item_collected` ; les drops des ennemis restent possibles (`EnemyData.drops`), mais les corps de Timere n'en ont aucun |
| Quête | `src/quests/quest_tracker.gd` | (acte 1, docs/lore/HISTOIRE.md 3.1 et 3.2) la quête principale `act1_main`, « Dans la forêt céleste » (13 étapes, de Nygglatho sous le porche à la promesse sur la colline ; récompense : la promesse du gâteau au beurre, PV max portés à 6) et six quêtes secondaires. (Lot Q) Quêtes en étapes écrites en JSON (`data/quests/`), journal de quêtes, marqueurs « ! » / « ? » : docs/QUETES.md |
| HUD | `src/ui/hud.tscn` | Cœurs, jauge de charge, numéro de vague et score dans l'arène, nom de la zone à l'entrée, invite d'interaction, objectif de quête |
| Inventaire | `src/ui/inventory.tscn` | Grille d'icônes, touche I / bouton Y, quantité, description |
| Menu | `src/ui/main_menu.tscn` | Choix du skin (vignettes, « Ta fée prend la place de Chtholly dans l'histoire. »), Nouvelle partie / Continuer, crédits ; écran « Cliquer pour jouer » avant tout son |
| Sauvegarde | `SaveManager` | Auto-sauvegarde à `arena_finished`, `item_collected`, `quest_updated`, `zone_entered` ; chargement au menu (pas de sauvegarde « à la fermeture » : le navigateur ne la garantit pas) ; (M2) position écrite toutes les 5 s de jeu si le joueur a bougé, et au départ (focus perdu, page masquée) quand l'état a changé |

### Format des vagues (JSON, `data/waves/dunes.json`)

```json
{
  "arena": "dunes",
  "music": "res://assets/audio/scarborough_fair.ogg",
  "heal_every_waves": 2,
  "bonus_per_wave": 50,
  "spawn_points": ["SpawnN", "SpawnS", "SpawnE", "SpawnW"],
  "waves": [
    { "enemies": { "timere_small": 3, "timere_normal": 2 } },
    { "enemies": { "timere_small": 3, "timere_normal": 2, "timere_runner": 2 } },
    { "enemies": { "timere_small": 4, "timere_normal": 3, "timere_runner": 1, "timere_big": 1 } }
  ],
  "generator": {
    "count": "3 + 2 * n",
    "weights": { "timere_small": 4, "timere_normal": 3, "timere_runner": 2, "timere_big": 1 },
    "max_simultaneous": { "timere_big": 1 },
    "speed_bonus_per_wave": 0.04,
    "speed_bonus_max": 0.5,
    "hp_bonus": { "timere_normal": { "from_wave": 6, "amount": 1 } }
  }
}
```

Les vagues listées sont jouées telles quelles ; au-delà, `generator` produit la vague *n* en tirant `count` ennemis selon `weights`, avec `max_simultaneous` pour le Grand, une vitesse qui augmente de 4 % par vague jusqu'à +50 % et un PV de plus pour le Normal dès la vague 6 : exactement la montée en difficulté de `jeu.js`. `WaveDirector.compose(n)` renvoie cette liste, ce qui la rend testable sans scène.

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
        { "text": "Je les trouve.", "set_flag": "picture_book_asked", "start_quest": "picture_book", "next": null },
        { "text": "Plus tard.", "next": null }
      ]
    },
    "done": {
      "if": { "count": ["page_fragment", 5] },
      "speaker": "Nephren",
      "text": "Cinq. Merci. Maintenant, un lecteur.",
      "complete_quest": "picture_book",
      "next": null
    }
  }
}
```

`DialogueRunner` choisit le premier nœud dont la condition `if` est vraie parmi `["done", start]`. Les conditions acceptées : `flag`, `not_flag`, `count` (objet, minimum), `quest` (id, état), `best_score` (arène, minimum). (Lot Q) En plus : condition `quest_step` (quête, étape), état `available` calculé par les prérequis, effets `advance_quest`, `give_item`, `take_item`, `clear_flag`, clés vérifiées à la lecture ; liste complète et ordre d'évaluation : docs/QUETES.md. (Systèmes et textes) Clé de nœud `speaker_id` (portrait et nom par défaut d'un autre PNJ : scènes à plusieurs voix), jeton `{player}` (prénom de la protagoniste : nom affiché du skin choisi sans sa variante « · 3D », premier mot) dans les répliques, les choix et `speaker`, conditions `quest_step` / `not_quest_step` avec une liste d'étapes ; la même grammaire décide de la présence des PNJ (`NpcData.visible_if`).

### Sauvegarde (JSON, `user://save_v1.json`)

```json
{
  "version": 2,
  "saved_at": "2026-10-05T10:00:00Z",
  "skin": "chtholly",
  "max_hp": 5,
  "position": [12.0, 1.0, -4.5],
  "zone": "village",
  "inventory": { "page_fragment": 3, "flower_blue": 1 },
  "flags": { "quest_pages_accepted": true },
  "quests": { "pages": "active" },
  "collected_pickups": ["forest_page_1", "beach_shell_2"],
  "best_scores": { "dunes": { "score": 640, "wave": 6, "games": 4 } },
  "quest_progress": { "pages": { "step": "deliver", "count": 0 } },
  "tracked_quest": "pages"
}
```

(Lot Q) Schéma v2 : `quest_progress` (étape courante et compteur de chaque quête active) et
`tracked_quest` (quête suivie par le HUD). Une sauvegarde v1 est migrée au chargement : chaque
quête active reprend à sa première étape, la première quête active est suivie. Le nom du fichier
ne change pas.

`collected_pickups` liste les `name` uniques des `pickup` déjà pris ; `best_scores` reprend ce que l'easter egg garde dans `localStorage['yn.wordend']` (meilleur score, nombre de parties), par arène.

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
| `tools/screenshot.sh res://src/world/island.tscn build/shots/island.png` | Rendu réel d'une scène (Xvfb + Mesa llvmpipe, 1280 × 720) ; l'agent ouvre ensuite le PNG avec son outil de lecture d'images | 5 à 15 s |
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
| **H1 Images livrées** | Intégrer les images commandées à ChatGPT (ou à un artiste) selon `docs/ASSETS_HD2D.md`, dans l'ordre de sa section 11 : vérifier, recadrer, reconstruire l'atlas du sol, créditer ; corriger le cahier des charges quand une consigne donne de mauvais résultats | `assets/hd2d/**`, `tools/hd2d_assets.py`, `tools/hd2d_manifest.json`, `tools/hd2d_art.py`, `tools/hd2d_ground.py`, `tools/hd2d_props.py`, `tools/hd2d_sky.py`, `docs/ASSETS_HD2D.md`, `tests/unit/test_hd2d_assets.gd`, `assets/CREDITS.md` (ajouts en bas) | socle | `python3 tools/hd2d_assets.py check` sans écart ; atlas à jour ; images à leur taille exacte (96 px/m) ; export Web < 60 Mo ; planche avant/après par livraison (`tools/hd2d_shots.sh`) |
| **H2 Décor de l'entrepôt** | Village de l'entrepôt : composition des volumes et des façades, cour, potager, linge, palissade, lampes ; occlusion de l'entrepôt quand on passe derrière | `src/world/zones/village/` et les décors qui ne servent qu'au village (`warehouse_main`, `warehouse_wing`, `warehouse_porch`, `armory_door`, `tool_shed`, `palisade`, `palisade_gate`, `laundry_line`, `vegetable_patch`, `well`, `flower_bed`, `climbing_tree`), `src/items/placements/village.tscn` | socle (images de H1 quand elles arrivent) | Lieux de MONDE.md section 2 reconnaissables sur `hd2d_village.png` et `hd2d_dialogue.png` ; aucun panneau ne cache le joueur ou un PNJ plus d'une seconde ; collisions testées ; ≤ 200 draw calls |
| **H3 Décor du port** | La ville du port : rue des boutiques, café, salle de projection, maison de Limeskin, quais, grue, passerelle et aéronefs ; plans successifs de la rue | `src/world/zones/beach/` et ses décors propres (`cafe`, `shop_bakery`, `shop_bookshop`, `projection_hall`, `stone_house`, `limashenka_house`, `market_stall`, `market_stall_veg`, `snack_stall`, `scrap_pile`, `signpost`, `wind_sock`, `gangway`, `cargo_crane`, `mooring_arm`, `bollard`, `crates_barrels`, `edge_railing`, `airship_barocupot`, `airship_ferry`), `src/items/placements/beach.tscn` | socle | `hd2d_beach.png` lisible (rue, quais, navires vus d'en haut) ; scène du thé de Limeskin cadrée ; collisions testées ; ≤ 200 draw calls |
| **H4 Décor des bois, du Couchant et de la colline** | Bois du marais (sous-bois, lisière, ruisseau), bord du Couchant (cercle de veille, cloche, rochers du vent, ruines) et colline des étoiles (pente, sommet, belvédère) | `src/world/zones/forest/`, `src/world/zones/dunes/`, `src/world/zones/hill/` et leurs décors propres (`tree_old_pine`, `tree_old_pine_clawed`, `mushroom`, `reeds`, `log_bridge`, `berry_bush`, `mossy_rock`, `bear_rock`, `stick_rack`, `play_goal`, `play_goal_red`, `ring_stone`, `vigil_bell`, `wind_rock_a`, `wind_rock_b`, `wind_rock_c`, `watch_post_ruin`, `ruined_wall`, `garde_pennant`, `signal_pillar`, `fallen_lantern`, `grass_tuft`, `lone_tree`, `lookout`, `tall_grass`), `src/items/placements/forest.tscn`, `dunes.tscn`, `hill.tscn` | socle | Sentiers lisibles en vue fixe ; rejetons visibles entre les troncs ; arène lisible pendant trois vagues (`hd2d_vigil.png`) ; rien de plus haut que 0,3 m dans le cercle de veille ; ≤ 200 draw calls par zone |
| **H5 Caméra, image et post-traitement** | Réglages de la caméra fixe (cadrages, verrouillage, zoom), flou de profondeur, lueur, étalonnage, lumières chaudes, ombres, ciel et mer de nuages, sol et falaises (masques du sol, tramage) ; éclairage de nuit pour M3 | `src/player/camera_rig.gd`, `src/player/camera_rig.tscn`, `src/player/post_fx.gdshader`, `src/world/shaders/`, `src/world/materials/`, `src/world/island.tscn` (hors `Zones`), `src/world/island_rock.gd`, `src/world/terrain.gd`, `src/world/decor_panel.gd`, `src/world/building.gd`, `src/world/prop_batcher.gd`, `tests/unit/test_camera_rig.gd`, `tests/unit/test_hd2d_decor.gd` | socle | Shaders compilés (fumée, tests) ; 50 images/s par zone dans `tools/web_m2.js` ; ≤ 200 draw calls ; captures avant/après ; API de `DecorPanel`, `Building` et `CameraRig` inchangée (sinon PR « contrats ») |
| **H6 Personnages et planches** | Planches HD-2D de Chtholly (tenue de l'acte 1), des PNJ, des fées jouables et portraits 256 px selon `docs/ASSETS_HD2D.md` section 3 ; échelles du tableau des hauteurs ; ombre et retournement du billboard | `assets/characters/**`, `data/skins/`, `src/visuals/`, `src/autoload/skin_registry.gd`, `tools/gen_placeholders.py`, `assets/characters/CREDITS.md`, `tests/unit/test_skin_registry.gd`, `tests/unit/test_visual_sprite.gd` | socle | Planches lues par `SheetLoader` sans changement du format JSON ; hauteurs à ± 5 % du tableau ; `parle` joué en conversation ; portraits 256 px ; capture de chaque skin |
| **H7 Combat et Timeres en HD-2D** | Lisibilité du combat en vue fixe : planches de Timere, onde de charge et éclats en sprites, signes avant l'attaque, ombres, indicateur de cible, secousse et arrêt sur image réglés pour la caméra fixe | `src/combat/`, `src/enemies/` (hors `placements/`), `data/attacks/`, `data/enemies/`, `data/waves/`, `assets/enemies/**`, `tests/unit/test_combat*.gd`, `tests/unit/test_enemy.gd`, `tests/unit/test_wave_director.gd`, `docs/REGLAGES_COMBAT.md` | socle | Règles de la section 4 inchangées (tests) ; un coup, une onde et une morsure lisibles sur capture ; vague 5 atteignable ; sensation jugée à la manette |
| **H8 Acte 1 de bout en bout et navigateur** (après les autres) | Rejouer l'acte 1 entier dans la vraie partie et dans le navigateur, corriger les frottements entre lots, mettre à jour la recette, les mesures et les captures | `tests/integration/test_m2_*.gd`, `tests/integration/test_act1*.gd`, `tests/integration/demo_hd2d.*`, `tests/stubs/m1_game_test.gd`, `tests/stubs/m2_game_test.gd`, `src/test_shortcuts.gd`, `tools/web_m2.js`, `tools/web_m1.js`, `tools/hd2d_shots.sh`, `docs/web.md`, `docs/RECETTE_M2.md` | H1 à H7 | `tools/check.sh` vert ; `node tools/web_m2.js … tout` vert ; recette de l'acte 1 cochée en HD-2D ; captures `hd2d_*` |

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
| **M5 Bureau** (après) | Export Windows/macOS/Linux, catégorie Jeu dans l'application Yume, zones streamées, deuxième donjon | Décidé après M4 selon l'usage réel |

Après M4, le rythme devient **une « saison » par trimestre** : une zone, des PNJ, des objets et un événement lié à la communauté, produits majoritairement en données.

## 9. Qualité, tests et CI

**« Vert » veut dire : import sans erreur, lint propre, tests GUT verts, scènes de fumée OK, export Web produit sous le budget.** La même commande `tools/check.sh` donne ce verdict sur la VM cloud, sur ta machine et dans GitHub Actions, de sorte qu'un agent n'ouvre une PR que quand elle passera la CI.

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
| `check` | Toute PR et tout push sur `main` | Conteneur `barichello/godot-ci:4.7.2` + bibliothèques X11/Mesa + Xvfb ; `pip install gdtoolkit` ; `tools/check.sh` ; étape « taille du build » qui échoue au-delà du budget du jalon (60 Mo) et écrit la taille dans le résumé du job ; artefacts `build/web/`, `build/shots/`, `build/junit.xml` |
| `deploy` | Push sur `main`, après `check` | Copie `web/` (CNAME, page de test) dans `build/web/`, puis publie sur GitHub Pages via `actions/upload-pages-artifact` + `actions/deploy-pages` |

Les captures d'écran en CI utilisent `xvfb-run` dans le conteneur ; si Mesa manque dans l'image, le job `check` installe `libgl1-mesa-dri xvfb` au préalable.

### Budgets de performance (build Web, Compatibility)

| Mesure | Cible M2 | Cible M4 |
| --- | --- | --- |
| Taille compressée (wasm + pck) | < 60 Mo | < 60 Mo |
| Temps jusqu'au menu (fibre) | < 10 s | < 15 s |
| Images/s portable | 60 | 60 |
| Images/s téléphone récent | 30 | 30 |
| Draw calls en vue village | < 150 ((HD-2D) mesuré : 50) | < 200 |
| Triangles affichés | < 150 000 ((HD-2D) mesuré : 17 000) | < 400 000 |

(HD-2D) Mesures du 7 octobre 2026 (`tools/hd2d_shots.sh`, rendu natif) : 32 à 70 draw calls selon
la zone, une conversation ou une veille (43 à 67 dans le navigateur, au Spawn de chaque zone) ;
export 12,4 Mo compressés (18,4 avant la purge des modèles 3D). `tools/check.sh` échoue au-delà de 60 Mo compressés (25 Mo jusqu'au cahier des charges n° 2).

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
| Version bureau | M5 | Exports Windows/macOS/Linux depuis le même dépôt ; l'application Yume ouvre l'exécutable ou embarque le build Web dans une WebView |

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
- Capture d'une scène : `tools/screenshot.sh res://src/world/island.tscn build/shots/island.png`, puis ouvre le PNG
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
tools/screenshot.sh res://src/world/island.tscn build/shots/island.png || echo "capture indisponible (pas de Xvfb ou binaire docker)"

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
          [ "$size" -lt 62914560 ] || { echo "build > 60 Mo"; exit 1; }
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
