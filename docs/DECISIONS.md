# Décisions

Choix faits quand le plan ne suffisait pas. Une entrée par décision, ajoutée en bas (fusion par
union entre lots) : `- **L<N> — sujet** : décision ; raison.`

## Lot 0 — environnement et outils

- **L0 — Godot dans les VM cloud** : `tools/setup.sh` télécharge Godot 4.7.2 et les templates Web
  depuis les releases GitHub de godotengine/godot (joignables, contrairement à ce que prévoyait
  la section 6) ; seuls `templates/web*.zip` et `version.txt` sont extraits du .tpz de 1,3 Go par
  requêtes HTTP Range (`tools/fetch_templates.py`, 14 s pour tout installer), avec repli sur le
  téléchargement complet puis sur l'image docker godot-ci. Raison : pas de démon docker dans la VM.
- **L0 — avertissements GDScript** : Godot 4.7 n'imprime jamais les avertissements GDScript en
  ligne de commande (ni à l'import, ni à l'exécution, ni avec `--check-only`). Ils sont donc réglés
  au niveau 2 (erreur) dans project.godot, dont `untyped_declaration` (GDScript typé obligatoire),
  et apparaissent comme `SCRIPT ERROR … (Warning treated as error.)` ; les addons restent exclus
  (`directory_rules`). Raison : seul moyen de faire respecter « avertissements = erreurs ».
- **L0 — gdtoolkit figé en 4.5.0** et `gdlintrc` aux réglages par défaut sauf `max-public-methods`
  (désactivée) : chaque test GUT est une méthode publique et un fichier de tests en compte vite
  plus de 20. Raison : même formatage partout, pas de faux positifs.
- **L0 — GUT 9.7.1** (dernière version, compatible 4.7.2), sans `.gutconfig.json` : les options
  sont passées par `tools/check.sh` et `tools/test.sh`. GUT ignore sans échouer un fichier de test
  qui ne compile pas : check.sh et test.sh échouent sur `SCRIPT ERROR` dans le journal, et
  `tools/smoke.gd` compile aussi tests/ et tools/.
- **L0 — fumée** : `tools/smoke.gd` compile tous les scripts de src/, tests/, tools/ et instancie
  toutes les scènes de src/ et tests/ (deux images dans l'arbre). Sortie strictement silencieuse
  exigée (ni ERROR ni WARNING non toléré).
- **L0 — isolation des worktrees** : `tools/godot` place `user://`, les réglages et le cache de
  l'éditeur dans `build/xdg/` du worktree (templates d'export liés). Raison : neuf worktrees
  peuvent lancer leurs tests en même temps sans se partager sauvegardes de test ni réglages.
- **L0 — fichiers générés** : en CI (`CI=true`), check.sh échoue si la vérification crée ou modifie
  un fichier suivi (typiquement un `.uid` ou `.import` non commité) ; en local, il l'annonce.
- **L0 — capture** : la capture de l'île reste facultative (code 2 sans Xvfb) mais, si elle a été
  rendue, son journal doit être propre. Le seul avertissement toléré est celui de V-Sync sous Xvfb.
- **L0 — export Web** : `addons/gut/*, tests/*, tools/*, docs/*, build/*` exclus du paquet ;
  `rendering/textures/vram_compression/import_etc2_astc=true` est obligatoire pour exporter.
  Build actuel : 10 Mo compressés (wasm 39,5 Mo brut, pck 1,1 Mo).
- **L0 — build/ ignoré par Godot** : `tools/godot` crée `build/.gdignore` à chaque lancement.
  Sans lui, Godot importait les captures et l'export embarquait `build/xdg` (réglages et cache de
  l'éditeur, keystore de débogage). Un test de test_contracts.gd protège les exclusions.
- **L0 — CI** : `tools/setup.sh` est réutilisé dans le conteneur godot-ci (Ubuntu 24.04, sans
  python3 ni curl) ; git et git-lfs sont installés avant le checkout si besoin.
- **L0 — Jolt Physics** explicite (`physics/3d/physics_engine`), le réglage par défaut d'un projet
  existant (`DEFAULT`) ne garantissant pas Jolt.

## Lot 0 — contrats

- **L0 — input map** : `camera_x` / `camera_y` deviennent `camera_left`, `camera_right`,
  `camera_up`, `camera_down` (stick droit ; une action a une force 0..1, il en faut deux par axe
  pour `Input.get_axis`) ; la souris se lit dans `_unhandled_input` (InputEventMouseMotion).
  Tous les événements ont `device = -1` (tous les périphériques).
- **L0 — couche 8 `enemy_barrier`** : la barrière du village (StaticBody3D, couche 8) arrête les
  ennemis (masque 1 + 2 + 8) mais pas le joueur (masque 1 + 3). Raison : « aucun ennemi n'entre
  dans le village » sans logique dans l'IA.
- **L0 — matrice de collision** : joueur couche 2 / masque 1+3 ; ennemis couche 3 / masque
  1+2+8 (ils ne se bloquent pas entre eux : séparation par calcul, section 13) ; PNJ couche 1 ;
  Hitbox couche 4 / masque 5 ; Hurtbox couche 5 / masque 0 ; zone d'interaction d'un PNJ couche 6 ;
  Pickup couche 7 / masque 2 ; Bounds des zones couche 0 / masque 2 ; barrière couche 8.
- **L0 — signaux ajoutés à EventBus** : `arena_score_changed(arena_id, score)` (HUD),
  `dialogue_choice_made(index)` (boîte → runner, -1 = suite), `player_heal_requested(amount)`
  (WaveDirector → PlayerCombat : 1 PV toutes les deux vagues), `max_hp_changed(max_value)`
  (GameState → PlayerCombat : marque-page de la quête). Raison : chaque paire de lots concernée
  doit se parler sans se lire directement.
- **L0 — qui émet quoi** : PlayerCombat relaie le Health du joueur (`player_health_changed`, avec
  une émission initiale différée pour le HUD, `player_damaged`, `player_died`) et applique
  `player_respawned`, `player_heal_requested`, `max_hp_changed` ; Enemy émet `enemy_spawned`,
  `enemy_damaged`, `enemy_killed` ; WaveDirector émet les signaux de vague et de score ; Pickup émet
  `item_collected` ; GameState émet `inventory_changed`, `quest_updated`, `skin_changed`,
  `max_hp_changed` ; Zone émet `zone_entered` ; WorldManager émet `player_respawned` ;
  DialogueRunner émet les signaux de dialogue ; DialogueBox émet `dialogue_choice_made` ;
  SaveManager émet `game_loaded` ; le joueur émet `interaction_available`.
- **L0 — mort et réapparition** : WorldManager appelle `respawn()` `respawn_delay` secondes
  (2,2 s, durée de la mort dans jeu.js) après `player_died` ; PlayerCombat remet les PV au
  maximum sur `player_respawned`.
- **L0 — GameState** : `skin_id == &""` = skin par défaut ; `zone == &""` = nouvelle partie pas
  encore placée (game.gd téléporte alors au Spawn du village) ; `zone` est tenue par WorldManager
  (zone_entered), `position` par le joueur quand il est au sol ; `record_score` ne renvoie true que
  si le score bat strictement le meilleur (comme jeu.js).
- **L0 — SaveManager** : `import_json` remplace GameState et émet `game_loaded` ; `load_game` =
  lecture du fichier + `import_json` ; version inconnue → `ERR_INVALID_DATA`, texte invalide →
  `ERR_PARSE_ERROR`, GameState inchangé. Pas encore d'auto-sauvegarde (L8).
- **L0 — WorldManager** : `zone_display_name(zone_id)` ajouté pour le HUD (le nom vient de
  `Zone.display_name`) ; les zones sont trouvées par le groupe `zones` ; `load_zone` instancie
  `src/world/zones/<id>/<id>.tscn` si la zone manque.
- **L0 — Health** : ajouts `damaged(amount, source)`, `current`, `reset()`, `is_dead()`,
  `is_invincible()`, `invincibility_left()`. PV pleins à la création ; changer `max_hp` avant le
  premier dégât garde les PV pleins, après il ne fait que plafonner.
- **L0 — Hitbox / Hurtbox** : propriété `team` (&"player" / &"enemy") sur les deux : une Hitbox
  ne touche pas sa propre équipe (une seule couche hurtbox dans le plan). Hitbox : `activate()`,
  `deactivate()`, `is_active()`, `source`, signal `hit_landed(hurtbox)`. Hurtbox : `health`
  (exporté), `receive_hit(attack, source) -> bool`, signal `hit_taken(attack, source)`. Le recul
  est appliqué par le script du corps (player.gd, enemy.gd) sur `hit_taken`.
- **L0 — AttackData** : champs ajoutés `arc_deg`, `width_m`, `charge_time`, `duration`, `speed`
  pour loger les chiffres de la section 4 (arc de 90°, onde de 2 m, 0,55 s, 0,42 s, projectile).
  `range_m` est donné à l'échelle 1 (l'ennemi le multiplie par `EnemyData.scale`). Reculs de
  départ, à régler à M1 : épée 5 m/s (3e coup 8), onde 9, morsure et fouet 3 (section 4).
  `rush` a 0 dégât (déplacement en ligne droite dès 8 m ; le coureur mord ensuite avec `bite`).
- **L0 — EnemyData** : portées d'aggro 10 m (coureur 12) ; `drops` vides (les fragments de la
  forêt restent à câbler par L5/L7) ; visuel commun `data/enemies/visuals/timere.tres`
  (height_m 1,03 : 99 px de repos × 0,0104).
- **L0 — CharacterVisual** : racine Node3D + enfant `Sprite` (AnimatedSprite3D a déjà des
  signaux du même nom). Ajouts au contrat : `play(anim, restart = false)`, `show_frame(anim,
  frame)` (charge maintenue), `wave_frame(anim)` (l'`onde` du JSON), `has_animation(anim)`,
  `current_animation()`. Le chargeur s'appelle `SheetLoader` (`src/visuals/sheet_loader.gd`) au
  lieu de `planche_loader.gd`. `pixel_size = height_m / hauteur de la 1re image de repos`.
- **L0 — emplacements par zone** : chaque zone instancie `NPCs`, `Enemies`, `Pickups`, scènes
  `src/npc|enemies|items/placements/<zone>.tscn` possédées par L6, L5, L7. Raison : peupler une
  zone sans toucher aux scènes de L2.
- **L0 — interaction** : le détecteur du joueur masque les couches 6 et 7 ; l'interactable est le
  premier nœud du groupe `interactable` en remontant depuis l'objet détecté (lui compris).
- **L0 — PNJ** : un DialogueRunner par PNJ (enfant de npc.tscn) ; seul le runner actif réagit à
  `dialogue_choice_made`. `start_quest` / `complete_quest` passent par
  `GameState.set_quest_state(id, &"active" | &"done")` ; QuestTracker (L7) applique retraits et
  récompenses quand il voit `&"done"`.
- **L0 — Pickup** : `pickup_id` = nom du nœud, unique sur l'île (préfixe de zone, ex.
  `forest_page_1`) ; `persistent = false` pour les objets lâchés par un ennemi (non retenus par la
  sauvegarde).
- **L0 — arène** : les Marker3D `SpawnN/S/E/W` sont des frères de l'Arena dans sa zone ;
  `Arena.spawn_point(nom)` les trouve. Le panneau « Affronter les Timeres » ira dans arena.tscn (L5).
- **L0 — joueur** : PlayerCombat trouve ses voisins par nom (`../Health`, `../Visual`,
  `../Hurtbox`, `SwordHitbox`) et ses données par chemin (`data/attacks/*.tres`) ; les PV (5) et
  l'invincibilité (1,2 s) sont des propriétés du nœud Health dans player.tscn, que L4 peut
  modifier (seule exception à la propriété de L1 sur ce fichier).
- **L0 — écrans modaux et pause** : la pause (action `pause`) est gérée par L10 ; les écrans qui
  figent le jeu (pause, inventaire, fin d'arène) utilisent `get_tree().paused` et ont
  `process_mode = PROCESS_MODE_ALWAYS`. Le dialogue ne met pas en pause : le joueur s'arrête entre
  `dialogue_started` et `dialogue_ended`.
- **L0 — contrôles tactiles** (L9) : ils émettent des actions (`Input.parse_input_event` d'un
  `InputEventAction`) ; aucun autre lot ne les connaît.
- **L0 — chargement** : main.gd n'écoute que `game_loaded` ; si la racine de loading.tscn a
  `set_progress(ratio: float)`, elle est appelée (0 puis 1). Chargement synchrone après une image
  (pas de chargement en fil séparé dans le build mono-thread).
- **L0 — caméras** : island.tscn garde une `OverviewCamera` courante (capture de l'île seule) ; la
  caméra du joueur, ajoutée après l'île dans game.tscn, devient la caméra courante.
- **L0 — skins des PNJ** : bibliothecaire, forgeron, enfant sont des skins jouables
  (`data/skins/`), comme prévu (« visuels partagés avec les skins ») ; seuls les visuels d'ennemis
  vivent hors de `data/skins/`.
- **L0 — vagues** : `data/waves/dunes.json` sans champ `music` tant qu'il n'y a pas d'audio
  (licence de l'enregistrement non tranchée, section 13).

## L8 — Sauvegarde

- **L8 — fichier** : `export_json()` écrit `version`, `saved_at` (UTC, `AAAA-MM-JJTHH:MM:SSZ`)
  puis les champs de `GameState.to_dict()` dans leur ordre (indentation de 2 espaces, clés non
  triées). `save()` écrit `<save_path>.tmp`, le ferme puis le renomme en `save_path` : une
  écriture interrompue ou refusée laisse l'ancienne sauvegarde intacte (`push_error`). Chaque
  écriture réussie émet le signal `SaveManager.saved(path)` (indicateur « sauvegardé » du HUD).
- **L8 — Web et IndexedDB** : vérifié dans le source de Godot 4.7.2 (`platform/web/os_web.cpp`,
  `drivers/unix/file_access_unix.cpp` et `dir_access_unix.cpp`, `js/libs/library_godot_os.js`) :
  `user://` est `/userfs`, monté en IDBFS ; Godot copie tout ce dossier vers IndexedDB
  (`FS.syncfs`, asynchrone) au début de l'image qui suit la **fermeture d'un fichier ouvert en
  écriture** sous `user://` ou une suppression (`DirAccess.remove`). Un renommage seul ou un
  fichier resté ouvert ne déclenchent rien. D'où `file.close()` explicite puis renommage dans la
  même image (la copie suivante emporte les deux) ; il faut encore une image après l'écriture
  (un onglet masqué n'en donne plus). IndexedDB indisponible (navigation privée) :
  `OS.is_userfs_persistent()` faux et rien n'est conservé ; `SaveManager.is_persistent()` permet
  au menu de prévenir le joueur et de lui proposer l'export.
- **L8 — fichier corrompu** : vide, JSON invalide, autre chose qu'un objet, `version` ou champ
  d'un mauvais type (un champ absent reste permis : défaut de `from_dict`) → `load_game()`
  renomme le fichier en `<save_path>.bak` (remplace l'ancien), démarre une nouvelle partie avec
  le `GameState.skin_id` courant (`game_loaded`) et renvoie `ERR_FILE_CORRUPT` ; `last_error`
  (texte pour le menu) et `push_error` disent pourquoi et où est la copie.
- **L8 — codes de retour** : `load_game()` : `OK`, `ERR_FILE_NOT_FOUND` (rien ne change),
  `ERR_INVALID_DATA` (version plus récente que le jeu : refusée sans toucher GameState ni le
  fichier, `push_warning`), `ERR_FILE_CORRUPT` (ci-dessus). `import_json()` : `ERR_PARSE_ERROR`
  (pas un objet JSON), `ERR_INVALID_DATA` (version future ou champ invalide), GameState intact
  et pas de `push_error` (erreur de saisie). `last_error` explique tout échec, `""` sinon.
- **L8 — format v0 et migration** : v0 = sauvegarde sans `version` (ou `"version": 0`) ni
  `best_scores`, où le score de l'unique arène de l'easter egg (les dunes) est à plat : `best`,
  `wave`, `games`, ou `meilleur` et `parties` comme `localStorage['yn.wordend']` dans jeu.js
  (nombres ou textes numériques) ; les autres champs comme en v1, tous facultatifs ; clés
  inconnues ignorées (`maj`, `volume`, `muet`). Migration : `best_scores.dunes = {score, wave,
  games}` si score ou parties > 0, puis la partie est réécrite en v1. Le texte de
  `localStorage['yn.wordend']` s'importe donc tel quel (score de l'easter egg repris). Une
  fonction par étape (`_migrate_v0`, puis `_migrate_v1` le jour où v2 existera).
- **L8 — auto-sauvegarde** : `arena_finished`, `item_collected`, `quest_updated`, `zone_entered`
  et `save_requested` (qui n'écrit donc plus immédiatement) demandent une écriture ; la première
  lance un Timer de 0,5 s (`PROCESS_MODE_ALWAYS`, `ignore_time_scale`), les suivantes s'y
  regroupent, une seule écriture à la fin. Au plus une écriture par 0,5 s, et un état complet :
  sur `zone_entered`, SaveManager est servi avant WorldManager qui met `GameState.zone` à jour ;
  QuestTracker donne la récompense après `quest_updated(…, done)`. Rien n'est écrit avant
  `game_loaded` ni après `close_game()`. `new_game`, `load_game` et `import_json` abandonnent
  l'écriture en attente de la partie remplacée (« Charger » n'écrase pas le fichier qu'il relit)
  puis en demandent une pour la nouvelle partie (nouvelle partie, migration, import et reprise
  ainsi écrits). `save()` appelé directement écrit tout de suite.
- **L8 — perte du focus** : sur `NOTIFICATION_WM_CLOSE_REQUEST`, `WM_WINDOW_FOCUS_OUT`,
  `APPLICATION_FOCUS_OUT` et `APPLICATION_PAUSED`, l'écriture en attente est faite aussitôt
  (`flush()`) ; sans attente, rien n'est écrit (toujours pas de sauvegarde « à la fermeture »).
- **L8 — tests** : base commune `tests/stubs/l8_save_test.gd` (fichier
  `user://test_l8_<script>.json`, `close_game(false)` avant et après chaque test ; chemin,
  délai, zone de WorldManager et pause rétablis). Tout test qui émet `game_loaded` arme
  l'auto-sauvegarde pour la suite du processus : `test_game_flow_l0.gd` écrit ainsi
  `user://save_v1.json` dans `build/xdg` (sans effet) ; un test qui vérifie `has_save()` doit
  donc régler son propre `save_path`.
## L4 — combat

- **L4 — onde** : `charge_wave.speed` passe de 14 à 19,05 m/s pour parcourir les 8 m (`range_m`)
  en 0,42 s (`duration`), section 4 ; l'onde se libère à la première des deux limites, le joueur
  reste immobile pendant `duration`, la recharge part du relâcher. `class_name ChargeWave` ;
  ajoutée au parent du joueur, vers le −Z horizontal de Combat ; `Hitbox.source` = le joueur (le
  recul éloigne de lui) ; QuadMesh courbé, shader non éclairé (WebGL 2) et OmniLight3D estompés en
  fin de vol.
- **L4 — enchaînement** : un appui pendant un coup, ou dans les `combo_window` = 0,4 s qui
  suivent, joue le coup suivant ; après sword_3, retour à sword_1 une fois `sword_3.cooldown`
  écoulé ; charge, dégâts et mort cassent l'enchaînement.
- **L4 — épée** : la sphère de `SwordHitbox` (player.tscn) est remplacée à l'exécution par un
  prisme convexe `arc_deg` × `range_m` (pointe sur l'axe du joueur, haut de `sword_height` =
  1,4 m) ; activée à la 1re image « coup » reçue par `Visual.frame_changed`, coupée hors coup et en
  fin d'animation ; `Hitbox.resume()` (ajout) reprend la même activation (images « coup » non
  contiguës) ; `Hitbox.set_sector_shape()` et `sector_points()` servent aussi aux ennemis.
- **L4 — coup refusé** : une Hurtbox qui refuse le coup (joueur invincible) n'entre pas dans la
  liste des touchés : le coup peut porter plus tard dans la même activation, comme dans jeu.js ;
  toujours un seul coup accepté par cible et par activation.
- **L4 — charge** : touche tenue mémorisée (la charge démarre dès que possible, jeu.js) ; images 0
  à onde−2 puis alternance à 8 Hz des deux images avant l'onde ; l'onde part sur l'image
  `wave_frame(&"charge")` affichée par `show_frame` (tout de suite si le skin n'en a pas) ;
  `charge_progress` : 0 au début, le ratio à chaque changement, 0 au relâcher ou à l'interruption ;
  pas de jauge de recharge (`PlayerCombat.wave_cooldown_left()` pour un HUD qui en voudrait une).
  Touche relâchée pendant une pause (aucun « just_released ») : relâchée à la reprise
  (`NOTIFICATION_UNPAUSED` + `Input.is_action_pressed(&"charge")`), sinon le joueur resterait figé.
- **L4 — états du joueur** : dégâts pendant `hurt_time` = 0,35 s (animation `degats`, coup et
  charge interrompus) ; mort (`mort`, occupé jusqu'à `player_respawned`) ; `Visual.visible`
  basculé `blink_rate` = 12 fois/s pendant l'invincibilité, sauf mort ; `animation_timeout` = 2 s
  termine un coup dont le Visual ne signale jamais la fin. Ajouts : `current_state()`,
  `current_attack()`, `wave_cooldown_left()`, signaux `attack_started` et `wave_launched`.
- **L4 — tests et capture** : joueur de test `tests/stubs/l4_player_rig.tscn` (player.tscn sans
  player.gd, hors du groupe player : pas de réapparition par WorldManager) ; la démo passe en mode
  capture sous tools/screenshot.gd :
  `tools/screenshot.sh res://tests/integration/demo_l4.tscn build/shots/l4.png 400`.
## L3 — visuel et skins

- **L3 — horloge des animations** : CharacterVisual tient sa propre horloge, celle de jeu.js
  (image = floor(t × ips), boucle ou blocage sur la dernière image, fin quand t ≥ images / ips) ;
  l'AnimatedSprite3D `Sprite` ne fait qu'afficher (jamais `playing`). `frame_changed` est émis
  pour chaque image affichée, image 0 et tours de boucle compris ; un grand delta émet toutes
  les images sautées dans l'ordre (un tour au plus pour une boucle) : une image « coup » n'est
  jamais manquée. `advance(delta)` est public (tests, temps exact). Raison : AnimatedSprite3D
  n'émet pas l'image 0 quand l'index ne change pas, et une horloge unique sert aussi au mesh.
- **L3 — play / show_frame** : `play(anim)` sur l'animation en cours ne la relance pas (figée par
  `show_frame`, elle reprend à son image) ; une animation sans boucle finie est relancée, comme
  le faisait le squelette (AnimatedSprite3D.play) ; `restart = true` relance toujours.
  `show_frame` n'émet `frame_changed` que si l'image affichée change. Un changement de skin
  n'émet rien si le nouveau skin a l'animation en cours (même instant), sinon `repos` démarre.
- **L3 — ancres** : AtlasTexture sans marge, ancre en métadonnée (`SheetLoader.ANCHOR_META`) ;
  le sprite est non centré et son `offset` est recalculé à chaque image et à chaque retournement
  (`SheetLoader.frame_offset`). Raison : en 3D, `flip_h` retourne l'image mais pas les marges
  d'un AtlasTexture (vérifié dans Godot 4.7.2), l'ancre sauterait. `anchor_extents` et
  `anchor_offset` du squelette sont retirées (inutilisées ailleurs).
- **L3 — rendu du sprite** : `texture_filter = 0` (nearest ; le squelette avait 1 = linéaire),
  billboard axe Y, `alpha_cut` discard (alpha scissor, pas de tri), pas d'ombre portée
  (`cast_shadow = 0`), non éclairé. Retournement par rapport à la caméra courante, réévalué à
  chaque image ; |cos| < 0,1 (face ou dos à la caméra) garde le côté ; sans caméra, droite = +X.
- **L3 — ombre** : nœud `Shadow` (PlaneMesh 1 × 1 m, GradientTexture2D radial, non éclairé,
  mélange alpha, y = 2 cm), compatible WebGL 2 (pas de Decal en Compatibility). Rayon = 0,75 ×
  demi-largeur du corps dans la 1re image de repos (côté sans arme) : Chtholly 0,38 m (18 px
  logiques comme jeu.js), Timere 0,47 m ; mesh : 0,25 × height_m. Enfant du visuel : suit
  `Visual.scale`. Ombres superposées : noir sur noir, l'ordre de mélange ne change rien.
- **L3 — variante mesh** : une seule scène `character_visual.tscn` (pas de
  `character_visual_sprite/mesh.tscn` de la section 5). SkinData avec `mesh_scene` et sans
  planche : scène instanciée sous `Mesh`, premier AnimationPlayer passé en mode manuel, pose
  calée sur l'horloge du visuel ; métadonnées des Animation : `ips` (défaut 10), `coup`,
  `onde` ; images = round(length × ips) ; `set_facing` tourne le mesh (avant = +Z, glTF).
  Exemple : `tests/stubs/l3_mesh_capsule.tscn` + `l3_capsule_skin.tres`.
- **L3 — cache des planches** : `SheetLoader.frames_for(skin)` garde un SpriteFrames par planche
  (chemins de la texture et du JSON) dans une variable statique, partagé par tous les visuels
  (pas de fuite à la sortie, vérifié) ; `clear_cache()` pour les tests.
- **L3 — placeholders** : `gen_placeholders.py` dessine en pixel art sans anticrénelage (alpha
  0/255 pour l'alpha scissor) et règle l'échelle pour que la 1re image de repos mesure height_m
  à 0,0104 m/px : même densité que Chtholly pour tous les skins. Portrait carré
  `<id>_portrait.png` pour chaque skin jouable (PNJ dessinés en 128 px ; Chtholly : tête de sa
  planche agrandie ×2, 160 px) ; mode `enemy` aux animations du Timere ; `--out` pour essayer.
- **L3 — SkinRegistry** : propriété `skins_dir` (relue par `reload()`, les tests en changent) ;
  fichiers non SkinData, sans id ou d'id déjà vu ignorés ; tri Chtholly d'abord, puis nom
  affiché sans casse, puis id.
## L5 — ennemis et vagues

- **L5 — portées** : la portée d'une attaque est `range_m × data.scale` devant le corps ; la
  capsule du corps, la Hurtbox et la Hitbox sont mises à l'échelle du type (formes dupliquées).
  Une attaque part quand le centre de la cible est à moins de rayon du corps + portée ; la Hitbox
  est une sphère qui couvre [corps ; corps + portée] dans la direction de la cible. Raison : les
  corps se touchent en 3D (pas en 2D) et le Petit doit pouvoir mordre.
- **L5 — images « coup »** : la Hitbox s'active une seule fois par attaque, à la première image
  `coup` reçue par `Visual.frame_changed`, et s'éteint à la première image suivante qui n'en est
  pas une (pas de double touche si les images `coup` ne se suivent pas, comme `touche` de jeu.js).
  L'état attack dure l'animation (images / ips du JSON) ou `AttackData.duration` si > 0.
- **L5 — choix et recharges** : fouet si seul le fouet porte, sinon une attaque au hasard parmi
  celles qui portent (jeu.js) ; recharge `cooldown × [0,7 ; 1,3] × EnemyData.cooldown_scale`
  (0,8 à 1,5 s pour 1,15 ; Grand × 1,4), 0,2 à 0,8 s à l'apparition ; hurt dure l'animation
  `degats` bornée à [0,35 ; 0,45] s. Champs ajoutés à EnemyData : `cooldown_scale`, `walk_speed`.
- **L5 — coureur** : le rush est son attaque sans dégâts (`rush.tres`) ; il part quand la cible est
  à moins de `rush.range_m` (8 m, non mis à l'échelle) et au-delà de sa portée + 1 m, file en
  ligne droite vers la position visée au départ (+1,5 m), mord dès qu'il est à portée, puis
  recharge `rush.cooldown`. Hors rush il marche à `walk_speed` = 2,5 m/s (marche plafonnée de
  jeu.js, 46 px/s). Raison : une charge lisible, qu'on peut esquiver.
- **L5 — abandon de la poursuite** : poursuite tant que le joueur est à moins de
  `aggro_range_m × 1,5`, à moins de `leash_m` (20 m, export de l'Enemy) de l'origine, vivant
  (`player_died` / `player_respawned`) et hors zone sûre (zone de `WorldManager.current_zone()`,
  `Zone.safe` lu via le groupe `zones`) ; sinon l'ennemi rentre à son origine puis erre (3 m).
- **L5 — séparation** : poussée calculée vers les autres membres du groupe `enemies` à moins de
  1,1 m × échelle (pas de collision entre ennemis). Un ennemi tombé 30 m sous son origine est
  retiré ; le cadavre rétrécit pendant ses 0,3 dernières secondes (alpha_cut empêche un fondu).
- **L5 — drops et quête des pages** : `page_fragment` à 1,0 dans les données du Petit, du Normal
  et du Coureur ; seuls les ennemis libres lâchent (`drops_enabled = false` pour ceux de l'arène).
  Les 4 Timeres de la forêt donnent donc 4 fragments (en plus des 3 posés par L7) à chaque
  chargement de la zone : la quête des 5 pages se termine toujours. Pickup ajouté en différé au
  parent de l'ennemi, `quantity = 1`, `persistent = false`.
- **L5 — forêt** : 4 Timeres dans la clairière au centre de la zone (local (−3, 1), (3, 2,5),
  (0, −2,5), (1, 4)), nommés `forest_timere_<type>_<n>`.
- **L5 — compose** : pure, graine `random_seed` (export ; 0 = nouvelle graine à chaque série),
  tirage seedé par `hash([graine, n])`. Les vagues listées gardent leur composition mais sont
  mélangées ; `count` est une expression en `n` évaluée par `Expression` ; nouvelle clé
  `generator.min_wave` (`timere_runner` : 2, `timere_big` : 3) pour « Coureur dès la vague 2,
  Grand dès la vague 3 » au-delà des vagues listées.
- **L5 — apparition** : `max_simultaneous` fait attendre le type plafonné (le Grand suivant attend
  que le premier meure) ; les autres types de la file passent devant. Délais dans la clé `timing`
  du JSON (défauts de jeu.js : 1,2 s avant la vague 1, 1,8 s entre deux vagues, 0,8 s avant la
  1re apparition, max(0,5 ; 2,2 − 0,15 n) × [0,7 ; 1,2]) ; `heal_amount` (1). Ennemis de vague :
  enfants de `Arena/Spawned`, `always_chase = true` (ni laisse ni portée d'aggro), à ±1 m d'un
  point d'apparition tiré au hasard.
- **L5 — score et fin de série** : le WaveDirector compte ses propres ennemis par le signal local
  `Enemy.defeated` (un ennemi libre tué ailleurs ne compte pas) ; vague nettoyée dès que le
  dernier meurt. `arena_score_changed` au départ (0), à chaque mort et à chaque bonus. Fin :
  `player_died`, `zone_entered` d'une autre zone que celle de l'arène (à tout moment, sinon une
  fuite au village bloquerait la série), sortie du disque de 12 m pendant la pause entre deux
  vagues (dont celle d'avant la vague 1). `stop()` est cette fin (record_score, arena_finished).
- **L5 — panneau** : nœud `Panel` d'arena.tscn en (9, 0, −2), tourné vers l'est (arrivée du
  village), invite « Affronter les Timeres » ; pendant une série, invite vide et `InteractArea`
  non détectable. Musique : clé facultative `music` (AudioStreamPlayer du WaveDirector), absente
  de dunes.json tant qu'il n'y a pas d'audio.
- **L5 — démo** : `tests/integration/demo_l5.tscn` place aussi un Timere de chaque type autour du
  joueur factice (`showcase`) pour la capture ; ZQSD, J et K y pilotent un joueur minimal.
## L7 — objets, inventaire, quête

- **L7 — piles** : GameState garde le total par objet (champ `inventory` du schéma inchangé) et
  `stacks()` en déduit les cases : une par tranche de `max_stack` si `stackable`, une par
  exemplaire sinon ; un objet sans `data/items/<id>.tres` est accepté avec les valeurs par défaut
  d'ItemData (empilable, 99). Pas de limite de cases ; plafond de sécurité de 999 par objet.
  Raison : la sauvegarde reste celle du plan et `max_stack` garde le sens « par case » du Lot 0.
- **L7 — record d'arène** : `record_score` compte toujours la partie ; `wave` est la vague de la
  partie record (pas la meilleure vague jamais atteinte) ; égalité ou 0 point ne sont pas un
  record ; arène sans id ignorée. Raison : schéma `{score, wave, games}` et test du Lot 0.
- **L7 — relecture d'une sauvegarde** : `from_dict` remplace un champ absent ou mal typé par sa
  valeur par défaut et ignore les entrées invalides (quantité non numérique ou ≤ 0, drapeau ni
  booléen ni nombre, état de quête hors available/active/done) ; sans position valide (absente
  ou au-delà de ±1 000 m), `zone` est vidée et game.gd replace le joueur au Spawn du village ;
  PV max entre 1 et 20 ; jamais de `quest_updated`, pour qu'une quête finie ne redonne pas sa
  récompense au chargement.
- **L7 — QuestTracker** : vérification et récompense synchrones pendant l'émission de
  `quest_updated(id, &"done")`. Refus (objets ou drapeaux manquants) : `set_quest_state(id,
  &"active")` immédiat, signal local `completion_refused(quest_id, missing_items)` et
  `push_warning`. Succès : objets requis retirés, `reward_items` donnés,
  `max_hp = max(max_hp, reward_max_hp)`, signal local `quest_completed`. Seul le premier nœud du
  groupe `quest_tracker` agit. Un écouteur de `quest_updated` branché après lui (HUD) relit
  `GameState.quest_state()` : lors d'un refus, il reçoit `done` après le `active` de la remise.
- **L7 — QuestData** : champs ajoutés `objective` (texte du HUD) et `reward_max_hp` (0 = sans
  effet) ; `QuestData.find(id)` et `ItemData.find(id)` chargent `data/quests|items/<id>.tres`
  (null si l'id est inconnu ou n'est pas un identifiant) ; `GameState.quests()` donne les états
  pour afficher les objectifs au chargement.
- **L7 — pickup** : `Mesh` est un halo face à la caméra (`src/items/pickup_halo.gdshader`, rayons
  qui tournent, teinte `ItemData.color`), `Mesh/Icon` un Sprite3D billboard de l'icône,
  `Shadow` un disque doux au sol ; la rotation demandée est celle des rayons du halo (une icône
  billboard ne peut pas tourner). Objet lâché (`persistent = false`) : petit rebond
  d'apparition. Ramassage une seule fois, invite « Ramasser ».
- **L7 — inventaire** : l'action `inventory` l'ouvre dans `_unhandled_input` ; ouvert, il
  consomme `inventory`, `ui_cancel` et `pause` dans `_input` (le menu pause de L10 ne s'ouvre
  pas par-dessus) ; un clic hors du panneau le ferme ; il ne s'ouvre ni si `get_tree().paused`
  est déjà vrai (pause, fin d'arène) ni entre `dialogue_started` et `dialogue_ended`, et rend la
  pause s'il quitte l'arbre ouvert. Cases triées par item_id, 4 colonnes, 8 cases au moins.
- **L7 — emplacements** : forêt `forest_page_1..3` en (-3, 0, 2), (4, 0, 5), (1, 0, -8) autour de
  la clairière (0, 0) ; plage `beach_shell_1..2` près des rochers ; colline `hill_flower_1..2` au
  pied du cône (sol plat) ; village `village_flower_1` à l'ouest de la place ; dunes : rien.
- **L7 — icônes** : `tools/gen_item_icons.py` (Pillow, déterministe, 64 × 64 dessinées à 4×,
  contour et ombre portée) ; `assets/items/unknown.png` pour un objet sans données.
## L1 — joueur et caméra

- **L1 — commandes injectables** : `Player.read_commands()` lit les actions, `Player.tick(delta,
  commandes)` les applique ; les tests fabriquent des `Player.Commands` et enchaînent les tick()
  dans une même image physique (hors image physique, `move_and_slide()` prend le delta de l'image
  idle, pas 1/60 s). Raison : tests de mouvement déterministes, sans attente.
- **L1 — réglages du mouvement** (tous en @export) : marche 4 m/s, course 7 m/s, accélération
  45 m/s², décélération 60 m/s² (aussi pour les demi-tours : pas de glisse), 18 m/s² en l'air ;
  saut 5,4 m/s avec `gravity_scale` 1,5 (environ 1 m), délai de grâce 0,1 s, appui de saut retenu
  0,12 s ; `floor_constant_speed`, `floor_snap_length` 0,3 m ; stick à moitié incliné = demi-vitesse.
- **L1 — course** : Maj se maintient ; à la manette, L3 lance la course jusqu'à l'arrêt du joueur
  (maintenir le clic du stick en l'inclinant est inconfortable). « course » n'est jouée qu'au-delà
  de la vitesse de marche.
- **L1 — relais de combat** : `attack()` et `charge_begin()` seulement si `Combat.is_busy()` est
  faux et hors dialogue ; `charge_release()` toujours transmis (il termine l'état occupé de la
  charge) ; une charge maintenue pendant une attaque démarre dès que Combat est libre (jeu.js).
  Pour L4 : l'enchaînement sword_1 → 3 se fait sur des appuis reçus quand `is_busy()` est
  redevenu faux (fenêtre d'enchaînement après chaque coup).
- **L1 — visée** : cible verrouillée, sinon dernière direction de déplacement (−Z au départ) ;
  `Combat.rotation.y` et `InteractionArea` la suivent ; `Visual.set_facing(visée)` à chaque image
  où Combat est libre. Le corps du joueur ne tourne jamais.
- **L1 — interaction** : `InteractionArea` (Area3D ajoutée à player.tscn, couche 0, masque 6 + 7,
  sphère de 1 m à 0,6 m devant) ; cône de 120° autour de la visée (un objet à moins de 0,6 m
  compte toujours) ; le plus proche gagne (distance horizontale à la racine de l'interactable) ;
  une invite "" rend un interactable inactif. Invite masquée ("" émis) pendant un dialogue et à la
  mort. Après `dialogue_ended`, interact et jump sont ignorés jusqu'à leur relâchement (la touche
  qui ferme le dialogue ne le relance pas, A ne fait pas sauter). Le joueur se tourne vers
  l'interactable en interagissant (sauf verrou).
- **L1 — verrouillage** : recherche dans 12 m (`lock_radius`), verrou perdu au-delà de 16 m
  (`lock_break_distance`, hystérésis), quand la cible quitte `enemies`, est libérée ou en cours de
  libération, quand son `Health` enfant est mort, ou à la mort du joueur. Sans cible dans le
  rayon, l'appui replace la caméra derrière le joueur (comme le Z-targeting de Zelda).
- **L1 — caméra** : `camera_rig.gd` sans class_name (typé par preload dans player.gd) ; tangage
  −70° à +20° (départ −22° de la scène), zoom 3 à 10 m par crans de 0,75 m lissés ; recentrage
  après 1 s sans toucher la caméra, sauf si le joueur revient vers elle ; verrou : lacet vers la
  cible, tangage −16°, point visé avancé de 35 % de l'écart (4 m au plus), orbite manuelle ignorée.
- **L1 — pointeur** : capturé au clic gauche ou droit dans le jeu (pas un toucher émulé, pas
  pendant un dialogue) ; libéré par l'action pause (lue dans `_input`, avant le menu),
  `NOTIFICATION_PAUSED` (pause, inventaire, fin d'arène), `dialogue_started` (choix à la souris) et
  la sortie de l'arbre (retour au menu). En headless `Input.mouse_mode` ne change pas : l'état
  testé est `is_pointer_captured()`.
- **L1 — réapparition** : `player_respawned` remet vitesse, élan, recul et appui de saut à zéro,
  lève le verrou et place la caméra derrière la visée courante, au tangage par défaut (WorldManager
  ne tourne pas le joueur, la visée est gardée).
- **L1 — scènes de démo** : `tests/integration/demo_l1.tscn` (terrain CSG) et
  `demo_l1.beach.tscn` (capture `l1.png` : île en lecture seule, joueur placé par
  `WorldManager.teleport(&"beach")`, tourné vers la mer) partagent `demo_l1.gd`.
## L6 — PNJ et dialogues

- **L6 — format de dialogue étendu** : `entries` (liste facultative de nœuds d'entrée, essayés
  dans l'ordre après `done` et avant `start`) ; `if` possible sur un choix (choix non proposé
  s'il est faux, l'index reçu désigne les choix proposés) ; `flag`, `not_flag` et `set_flag`
  acceptent un nom ou une liste ; textes à trous `{count:objet}`, `{left:objet:total}`
  (au moins 0) et `{best:arène}`. `done` reste un nom réservé, essayé en premier. Raison : la
  bibliothécaire a quatre états (proposition, quête en cours avec les pages restantes, quête
  terminable, remerciement) que `["done", start]` seul ne distingue pas.
- **L6 — effets** : ceux d'un nœud s'appliquent quand il s'affiche (avant l'émission de sa
  ligne), ceux d'un choix quand il est choisi ; `start_quest` → `set_quest_state(id, &"active")`,
  `complete_quest` → `&"done"` (QuestTracker, L7, retire les pages et donne le marque-page).
  Identifiants de la quête : `pages`, `page_fragment` (5), drapeau `quest_pages_accepted`
  (ceux du schéma de sauvegarde, section 4) ; drapeau du forgeron `blacksmith_tips_heard`.
- **L6 — lecture des dialogues** : `FileAccess` + `JSON.parse` (et non `load()`, qui imprime
  une ERROR moteur sur un JSON invalide), puis validation complète (`start`, `entries`, `next`,
  clés des `if`). Fichier invalide, introuvable ou sans entrée vraie → `push_warning` explicite
  et aucun signal : le joueur n'est jamais bloqué. Une condition mal formée vaut faux (avec
  avertissement).
- **L6 — un seul dialogue à la fois** : `DialogueRunner.is_any_running()` (statique) ;
  `start()` est ignoré pendant un autre dialogue ; un runner n'est branché sur
  `dialogue_choice_made` que pendant son dialogue ; un index hors limites est ignoré (avec
  avertissement) ; un runner qui quitte l'arbre termine son dialogue (`dialogue_ended`).
- **L6 — DialogueBox** : `class_name DialogueBox`. Touches lues dans `_input` et consommées
  tant que la boîte est ouverte : `interact` et `ui_accept` (termine la ligne, puis suite ou
  choix), `ui_up` / `ui_down` et `move_forward` / `move_back` (sélection). Dans Godot 4.7,
  `ui_accept` n'a aucun bouton de manette : c'est `interact` (A) qui sert. Souris : survol =
  sélection, clic = validation, clic sur la boîte = `interact`. Les choix n'apparaissent
  qu'une fois la ligne entière ; 40 caractères/s ; thème `src/ui/dialogue_box_theme.tres`.
- **L6 — portrait** : `SkinData.portrait`, sinon une `AtlasTexture` de la 1re image de
  `repos` de la planche (les skins des trois PNJ n'ont pas de portrait).
- **L6 — Npc** : `interact()` est ignoré `talk_cooldown` = 0,3 s après la fin de son dialogue,
  sinon l'appui qui ferme la dernière réplique la relance si le joueur lit `interact` par
  sondage ; respiration de ±2 % sur `Visual.scale.y` autour de sa valeur de départ ; à
  l'apparition, chute d'au plus 1 s jusqu'au sol (couche 1), puis plus de physique. Raison :
  la place du village dépasse le sol de 0,1 m, les emplacements sont donc à y = 0,2 comme le
  Spawn et chaque PNJ se pose sur ce qu'il y a dessous.
- **L6 — PNJ du village** (`src/npc/placements/village.tscn`) : bibliothécaire (−3,5 ; 4),
  forgeron (4 ; 3), enfant (−5,5 ; 6,5) : autour de la place, à 6–7 m du Spawn, l'allée x = 0
  du Spawn vers le nord restant libre.
- **L6 — démo** : la présentation de `tests/integration/demo_l6.tscn` (terminer la 1re
  réplique, passer à la question, l'afficher en entier) compte les images et non le temps,
  pour que la capture soit identique quelle que soit la vitesse du rendu :
  `tools/screenshot.sh res://tests/integration/demo_l6.tscn build/shots/l6.png 380`.
## L9 — Export Web et site

- **L9 — shell HTML personnalisé** (`web/shell.html`, `html/custom_html_shell`) : celui de
  Godot 4.7.2 en français, aux couleurs du site et du couchant, sans logo Godot : barre de
  téléchargement en Mo, message clair si WebGL 2, HTTPS ou le moteur manquent (bouton
  « Recharger »). Il garde les marqueurs `$GODOT_*` du shell d'origine, donc l'export headless
  marche. Raison : le shell par défaut est en anglais et affiche le logo Godot.
- **L9 — preset Web** au format qu'écrit l'éditeur 4.7.2 (section `[runnable_presets]`, plus de
  `runnable` ni `advanced_options` dans `[preset.0]`) ; `web/*` exclu du pck ; PWA désactivée
  (un service worker garderait en cache de vieilles versions du jeu).
- **L9 — contrôles tactiles** : `InputEventAction` passés à `Input.parse_input_event` (état
  d'Input et événements pour `_input` / `_unhandled_input`). Joystick : intensités brutes par
  axe (la zone morte de `Input.get_vector` s'applique ensuite, comme pour un stick), zone morte
  radiale de 8 %. Caméra : vitesse du doigt / `camera_full_speed` (1000 px/s) = intensité de
  `camera_*`, d'où une rotation proportionnelle au glisser. Ordre : `_input` (doigts sur nos
  contrôles) → interface (boutons d'un dialogue ou d'un menu) → `_unhandled_input` (caméra,
  souris émulée consommée). Mode AUTO : affichés sur écran tactile ou au premier toucher, masqués
  par une touche ou un bouton du jeu ou un clic de souris. Pause : Pause et Sac seulement ;
  dialogue : Parler (« Suite ») et Pause. Tout est relâché quand ils disparaissent, quittent
  l'arbre ou que la fenêtre perd le focus.
- **L9 — chargement sans threads** : vérifié dans le code de 4.7.2, `load_threaded_request()`
  charge tout dans l'appel (WorkerThreadPool sans fil) ; `Loading.load_scene()` découpe le
  chargement (dépendances d'abord, 50 ms par image) pour une vraie progression.
- **L9 — CI** : actions à leur dernière version majeure en Node 24 (checkout v7,
  upload/download-artifact v7, configure-pages v6, upload-pages-artifact v5, deploy-pages v5) ;
  `safe.directory` (sans lui, le contrôle des fichiers générés de check.sh ne voyait rien dans
  le conteneur) ; templates liés plutôt que copiés ; `workflow_dispatch` ; budget par
  `tools/build_size.sh` (gzip -6 de wasm + pck, 1 Mo = 1 048 576 octets, comme check.sh).
- **L9 — snippet iframe** gardé tel quel (sans `allowfullscreen`, que Chrome signale comme
  ignoré) ; le bouton plein écran de la page agit sur l'iframe depuis la page.
- **L9 — vérification dans un navigateur** : le Chromium headless de Playwright (SwiftShader)
  fournit un WebGL 2 logiciel dans la VM ; utilisé à la main (docs/web.md), pas dans check.sh
  (lourd et absent de l'image godot-ci).
## L2 — Monde

- **L2 — `Geometry` sans CSG** : chaque zone garde son nœud `Geometry`, devenu un Node3D
  (`PropBatcher`) qui contient des décors (scènes de `src/world/props/`, meshes unité partagés
  de `props/meshes/` + collision StaticBody3D couche 1) posés un par un ou par `PropScatter`
  (points, lacets, échelles : enfants internes recréés au chargement, visibles dans l'éditeur).
  Au lancement, `PropBatcher` regroupe tous ces meshes en un MultiMeshInstance3D par
  (mesh, éclairé/« glow », ombre), couleur par instance = albedo du matériau d'origine.
  Raison : une quarantaine de draw calls pour toute l'île au lieu de centaines de CSG.
- **L2 — relief** : `Ground` porte `IslandTerrain` (src/world/terrain.gd, @tool) : relief calculé
  (`height_at(x, z)` en coordonnées de l'île), HeightMapShape3D 129 × 129 (taille native de
  Jolt, 1,25 m), mesh visible tiré de la même grille où chaque bloc plat de 5 m ne fait que deux
  triangles (~20 k triangles au lieu de 33 k ; ~150 ms pour bâtir l'île en natif). Couleurs du
  sol au pixel (`shaders/terrain.gdshader` : chemins, place, arène, plage, sous-bois) ; la
  forme de la côte est la même dans terrain.gd, terrain.gdshader et water.gdshader. Pentes
  ≤ 36° (test : < 40° sur chaque facette).
- **L2 — mer et limites** : haut-fond (fond à −1,3 m, eau à −0,6 m) jusqu'aux murs du carré
  (±80,5 m) : on patauge sans jamais se noyer ; des bouées marquent la ligne des murs. La
  KillZone (sous y = −10) et `WorldManager.FALL_LIMIT` (−30 m) ne sont que des filets de
  sécurité, tous deux branchés sur `WorldManager.rescue()` (Spawn de la zone courante).
- **L2 — éclairage (Compatibility 4.7.2)** : une DirectionalLight3D avec ombres est rendue
  dans une passe additive mélangée en espace sRGB (zone éclairée = sRGB(ambiante) + sRGB(soleil),
  mesuré : 0,3608 + 0,3608 = 0,7216). Réglages choisis en conséquence : soleil 0,22, lumière
  ambiante constante lavande 0,32, tonemap linéaire. À revoir si Godot corrige ce mélange (la
  scène deviendrait plus sombre).
- **L2 — ombres** : mode orthogonal, 70 m ; fleurs, buissons, haies, champignons et bouées
  n'en projettent pas (triangles). Vue village mesurée : ~52 draw calls, ~136 k primitives.
- **L2 — noms des zones** : Village, Dunes au couchant, Forêt des Timeres, Plage aux
  coquillages, Colline du belvédère.
- **L2 — village** : les 4 maisons du Lot 0 restent à leur place (tournées vers la place) + 2
  maisons, puits au centre de la place (remplace la fontaine), haies et 4 portes (arches
  vermillon) sur les chemins. `EnemyBarrier` (couche 8) couvre tout le pourtour, portes
  comprises, de y = −2 à 10 m (coins recouverts).
- **L2 — dunes** : arène plate sur 15 m de rayon (anneau peint à 12 m), ruines et poteaux à
  ~17 m, dunes au-delà de 18 m, cuvette ouverte vers le village (est) ; soleil couchant à
  l'ouest-sud-ouest, 24° au-dessus de l'horizon, au-dessus de la mer derrière les dunes.
- **L2 — téléportation** : `teleport()` pose le joueur au ras du décor statique sous le marqueur
  (rayon couche world, corps non statiques comme les PNJ ignorés) ; `ground_position()` et
  `rescue()` ajoutés à l'API (le contrat reste inchangé).
- **L2 — tests** : `tests/stubs/l2_island_fixture.gd` instancie l'île sans le contenu des
  emplacements des autres lots, pour tester le monde seul ; les tests de l'arène ignorent les
  collisions internes à arena.tscn (L5).
- **L2 — captures** : `L2_VIEW=overview|village|dunes tools/screenshot.sh
  res://tests/integration/demo_l2.tscn build/shots/<nom>.png` cadre la vue et écrit draw calls
  et primitives dans le journal.
## L10 — Menu et HUD

- **L10 — thème** : `src/ui/wordend_theme.tres`, commun au menu, aux crédits, au HUD, à la pause
  et à la fin d'arène : police par défaut (grasse synthétique par `FontVariation` pour les titres),
  panneaux crème à coins arrondis et contour corail, boutons pêche (rose pour l'action principale),
  variantes `HudLabel`, `HudTitle`, `HudAccent`, `HudPanel`, `PrimaryButton`, `SkinCard`,
  `SkinCardSelected`, `KeyCap`, `PadA`, `ChargeBarFull`, `ClickPill`. Aucun glyphe hors de la
  police par défaut (pas de police système de secours sur le Web) : le Ⓐ de l'invite est une
  pastille verte dessinée. Icônes générées : `tools/gen_ui_icons.py` → `assets/ui/`.
- **L10 — manette dans les écrans** : Godot 4.7 n'associe aucun bouton de manette à `ui_accept` ni à
  `ui_cancel` (demande dans CONTRACT_REQUESTS). `src/ui/main_menu_input.gd` : A presse le bouton
  qui a le focus, B revient comme Échap, **au relâchement** d'un appui reçu par l'écran (l'appui
  qui ferme la pause n'arrive pas au joueur, qui sonde jump, interact et charge ; le relâchement
  d'un appui commencé ailleurs est ignoré). Le survol de la souris donne le focus (un seul bouton
  en surbrillance).
- **L10 — « Cliquer pour jouer »** : écran de main_menu.tscn, fermé par un clic, un toucher, une
  touche ou un bouton de manette (pas un geste pour le navigateur, mais le joueur ne doit pas rester
  bloqué) ; l'événement est consommé et le clic ou le doigt qui l'a fermé ne presse pas le bouton
  apparu dessous. Le bus Master reste muet jusqu'au geste (rien ne peut jouer avant ; rétabli si le
  menu quitte l'arbre). Geste retenu par la métadonnée `wordend_user_gesture` de la racine : le
  retour au menu (reload_current_scene) ne le redemande pas. `require_gesture` (export) le coupe
  pour les aperçus de capture.
- **L10 — Continuer** : un skin choisi par le joueur avant « Continuer » s'applique à la partie
  reprise. ERR_FILE_CORRUPT : la nouvelle partie de secours prend le skin choisi ; main.gd libère
  le menu dès game_loaded, donc `last_error` est aussi affiché par un avis
  (`main_menu_notice.gd`, CanvasLayer ajouté à la racine, 9 s ou un clic) par-dessus le chargement
  puis le jeu. ERR_INVALID_DATA et ERR_FILE_NOT_FOUND : message au menu.
- **L10 — présélection du skin** : champ `skin` relu dans `SaveManager.save_path` (JSON lu en
  lecture seule, sans charger la partie) ; skin inconnu ou fichier illisible → Chtholly.
- **L10 — export** : au menu, avant tout chargement, GameState est vide : l'export montre le
  fichier de sauvegarde (que SaveManager écrit avec `export_json()`) ; pendant une partie suivie
  (`SaveManager.is_game_loaded()`), `SaveManager.export_json()`. Copie par
  `DisplayServer.clipboard_set` si la fonction existe, texte sélectionné dans tous les cas. Import
  sans confirmation (geste délibéré), erreurs « Import impossible : last_error ». Navigation
  privée : avertissement sous les boutons et dans le panneau, bouton « Exporter ma sauvegarde »
  mis en avant.
- **L10 — HUD alimenté par l'EventBus** : lectures de GameState au départ seulement (PV max pleins
  jusqu'à la 1re émission différée de player_health_changed, `GameState.quests()`), plus
  l'objectif (`QuestData.find`) et sa progression (objets requis, sur inventory_changed).
  quest_updated est relu dans GameState en fin d'image : le résultat ne dépend pas de l'ordre de
  branchement avec le QuestTracker ; « Quête terminée ! » seulement sur un passage à done.
- **L10 — disposition du HUD** (1280 × 720) : cœurs, jauge de charge et objectifs en haut à gauche ;
  vague, score et record en haut au centre ; nom de zone puis bannières au centre-haut ; invite
  « E / A : … » à droite du centre (le joueur, cadré au centre par la caméra L1, n'est pas caché ;
  les boutons tactiles de droite commencent à y = 364) ; « Sauvegardé » et surcouche F3 à droite
  sous le coin Sac / Pause. Rien dans le coin haut droit ni dans les 200 px du bas (test), tout en
  mouse_filter IGNORE. Jauge de charge visible seulement pendant une charge (dorée, « Onde
  prête ! » à 1).
- **L10 — marqueur de cible** : flèche dorée au-dessus de `locked_target()` (nœud du groupe
  player), à la hauteur du visuel d'un Enemy (`EnemyData.visual.height_m × scale + 0,3 m`), sinon
  `lock_marker_height` (1,6 m) ; cachée si la cible est derrière la caméra.
- **L10 — HUD et pause** : le HUD suit la pause (bannières figées) ; seul PauseMenu est en
  PROCESS_MODE_ALWAYS. Le fondu de retour après la mort continue en pause (TWEEN_PAUSE_PROCESS)
  pour ne pas laisser l'écran noir sous la fin d'arène.
- **L10 — menu pause** : action pause dans `_unhandled_input` ; ne s'ouvre ni quand le jeu est déjà
  en pause (inventaire, fin d'arène) ni entre dialogue_started et dialogue_ended ; Échap ou B
  referment (depuis « Commandes » : retour au menu pause). Sauvegarder → save_requested, statut
  sur SaveManager.saved (« Aucune partie… » hors partie suivie). Retour au menu :
  `SaveManager.save()` si une partie est suivie (la position n'est écrite par aucun autre
  événement), `close_game(false)`, pause levée, puis `reload_current_scene()` ; main.gd n'est pas
  modifié (son `show_menu()` n'est pas appelé sur ce chemin : la demande L8 sur close_game y est
  satisfaite par le menu pause). `reload_on_quit` est coupé par les tests (sous GUT, la scène
  courante est celle de GUT).
- **L10 — fin d'arène** : vague atteinte = dernier wave_started de l'arène (« – » si aucune) ;
  meilleur score et nombre de séries par `GameState.arena_record` ; le panneau fige le jeu tant
  qu'il est affiché, mais après une mort il attend player_respawned (décision en fin d'image :
  arena_finished arrive pendant l'émission de player_died, avant que le panneau la reçoive) ; le
  minuteur de réapparition de WorldManager n'est donc jamais arrêté, le panneau s'ouvre au village.
- **L10 — crédits** : RichTextLabel BBCode dans la scène, puis un Label rempli par
  `Engine.get_license_text()` ; défilement aux flèches, à la croix et au stick (`_input`), à la
  molette et au doigt (ScrollContainer).
- **L10 — démo et captures** : `tests/integration/demo_l10.tscn` émet les signaux en boucle (zones
  nues `village` et `dunes` pour les noms affichés) ; aperçus figés
  `tests/stubs/l10_{menu,hud,pause,arena_end,credits}_preview.tscn`, par exemple
  `tools/screenshot.sh res://tests/stubs/l10_hud_preview.tscn build/shots/l10_hud.png 40`.
- **L10 — vérification dans le navigateur** (Chromium headless de Playwright, build exporté servi en
  local) : clic → menu → Nouvelle partie → HUD (cœurs, « Village », « Sauvegardé », invite
  « Parler » près de la bibliothécaire) ; Échap → pause → Retour au menu : menu sans nouvel écran de
  clic, Continuer visible ; page rechargée : écran de clic, puis Continuer (sauvegarde IndexedDB) ;
  téléphone Android simulé : le toucher qui ferme l'écran de clic sur l'emplacement de « Nouvelle
  partie » ne lance rien, le suivant lance la partie, contrôles tactiles et HUD sans chevauchement.
  Aucune erreur dans la console.
## Intégration M1 — combat de bout en bout

- **M1 — enchaînement d'épée** (`src/player/player.gd`, L1) : un appui sur `attack` pendant
  l'état `attack` de Combat est transmis à `PlayerCombat.attack()`, qui le garde pour enchaîner
  le coup suivant (L4 décide) ; pendant la charge, l'onde, les dégâts, la mort ou un dialogue,
  rien ne passe. Cause : player.gd ne transmettait rien tant que `is_busy()`, donc seul un appui
  dans les 0,4 s qui suivent le coup enchaînait ; un joueur qui martèle la touche pendant le coup
  (0,29 s) perdait ses appuis.
- **M1 — zone sûre** (`src/autoload/world_manager.gd`, L2 ; contrat PLAN.md section 3) :
  `WorldManager.is_zone_safe(zone_id) -> bool` (`Zone.safe` de la zone, faux si inconnue),
  demandé par L5 ; `Enemy._player_in_safe_zone()` l'appelle directement (lecture défensive du
  groupe `zones` retirée) ; `tests/unit/test_contracts.gd` vérifie la signature.
- **M1 — contournement des obstacles** (`src/enemies/enemy.gd`, L5) : un Timere qui heurte de
  face un mur du décor statique (cosinus ≥ 0,8 entre sa direction et la normale, pente au-delà
  de `floor_max_angle`) le longe pendant 0,5 s, toujours du même côté jusqu'au changement d'état ;
  le joueur et les corps mobiles ne comptent pas. Cause : dans l'arène, un joueur près du
  panneau (9, 0, −2) gardait derrière son poteau les Timeres venus de l'ouest (bloqués plus de
  4 s : move_and_slide ne glisse pas sur un mur heurté de face) ; même risque contre les troncs
  de la forêt.
- **M1 — emplacements après le décor du L2** (`src/items/placements/beach.tscn` et `hill.tscn`,
  L7 ; `src/enemies/placements/forest.tscn`, L5) : `beach_shell_1` (−13, 0, 22) était dans la
  mer (fond à −1,2 m) → (−25, 0, 13), sable sec ; `beach_shell_2` (27, 0, 18) flottait 0,4 m
  au-dessus de la pente de la plage → (27, 0, 14) ; `hill_flower_1` (−17, 0, 9) était dans le
  tronc d'un arbre rond → (−19, 0, 7) ; `forest_timere_normal_1` (0, −2,5) partait dans un
  champignon du cercle de fées → (3, −2), au centre du cercle. Pages de la forêt, fleur du
  village, PNJ, panneau et points de l'arène étaient déjà bons. Contrôle permanent :
  `tests/integration/test_m1_world.gd` (au sol, hors décor et hors de l'eau, chemin à pied depuis
  le Spawn du village sur une grille de 0,5 m, clairière dégagée sur 6 m, arène plate).
- **M1 — portée du panneau de l'arène** (`src/enemies/arena.tscn`, L5) : sphère `InteractArea`
  du panneau 1,3 → 0,9 m. Cause : avec la sphère d'interaction du joueur (1 m, 0,6 m devant
  lui), l'invite s'affichait jusqu'à 2,9 m du poteau, soit 12,1 m du centre côté village, hors
  des bornes de 12 m : la série démarrait puis s'arrêtait à l'image suivante (sortie du disque
  pendant la pause d'avant la vague 1), avec un `arena_finished` à 0 point compté comme une
  partie. L'invite s'arrête maintenant vers 2,5 m (11,7 m du centre au plus) ; testé sur un
  cercle de positions autour du panneau.
- **M1 — recul des deux premiers coups d'épée** (`data/attacks/sword_1.tres`, `sword_2.tres`,
  L4) : `knockback` 5 → 2,5 m/s (sword_3 reste à 8). Cause : le joueur ne bouge pas pendant
  l'enchaînement et un Normal (2 PV) attaque à 1,2 m ; le premier coup le repoussait de 0,5 m,
  hors de portée du deuxième (1,55 m pour lui) : l'enchaînement donnait coup, vide, coup, à
  chaque fois. À 2,5 m/s, recul de 0,28 m, le deuxième coup porte (marge 0,1 m) et sword_3
  garde le grand recul final (0,9 m). Valeur à juger par le propriétaire (docs/REGLAGES_COMBAT.md).
- **M1 — vue de la réapparition** (`src/autoload/world_manager.gd`, L2) : `respawn()` tourne le
  joueur comme le Marker3D `Spawn` du village (−Z : vers la place), caméra derrière lui, avant
  `player_respawned` : la vue d'une nouvelle partie. Cause : la visée gardée de l'arène (souvent
  verrouillée sur un Timere) plaçait la caméra n'importe où autour du Spawn ; vu dans le
  navigateur, elle s'est retrouvée dans le feuillage d'un cerisier (écran rose). Le contrat L1
  (« caméra derrière le joueur, tangage par défaut ») reste vrai ; seule la visée change.
- **M1 — raccourcis de test** (`src/test_shortcuts.gd`, nouveau ; `src/game.gd`) : `?zone=<id>`
  et `?timeres=<n>` dans l'adresse (Web, `JavaScriptBridge.eval("window.location.search")`) ou
  `--zone=` / `--timeres=` en arguments utilisateur ; game.gd ne crée le nœud que si l'un d'eux
  est présent (sans paramètre, partie inchangée, testé). Journal `[m1] …` pour suivre la partie
  sans écran ; mode d'emploi dans docs/web.md. Raison : vérifier l'arène dans le navigateur sans
  traverser l'île à 1 ou 2 images/s.
- **M1 — tests d'intégration** (`tests/stubs/m1_game_test.gd`) : vraie partie (`SaveManager.
  new_game` puis `src/game.tscn`), sauvegarde `user://test_m1_<script>.json`, appuis réels sur
  les actions (alignés sur l'image physique pour `is_action_just_pressed`). Horloge
  déterministe : chaque CharacterVisual de la partie avance d'une image physique par image
  physique (`advance`, `_process` coupé) ; en jeu, son horloge de temps réel s'écarte du temps
  physique sur une machine chargée (un enchaînement mesuré à 12 images au lieu de 18). Hasard
  semé à chaque test ; branchements sur EventBus défaits après chaque test (`listen`).
- **M1 — barrière du village** : les Timeres de la forêt ont une laisse de 20 m autour de la
  clairière (z = −51) ; ils abandonnent donc ~9 m avant la barrière (z = −22) et ne la touchent
  jamais en poursuivant. La barrière reste le filet de sécurité : testée en y repoussant un Grand
  avec l'onde (il s'arrête contre elle). Aucun changement.
- **M1 — performance** : 12 Timeres à l'écran dans l'arène : 88 draw calls, 94 600 primitives
  (capture native `M1_SHOT=perf`), 68 / 115 000 dans le navigateur ; vue du village : 75 /
  112 000 : sous le budget (< 150 draw calls). Seule la vue du village depuis les dunes dépasse
  l'objectif M2 de 150 000 triangles (156 000, dont 37 000 d'ombres ; 149 000 avec des ombres à
  40 m au lieu de 70) : décor et éclairage du L2, laissés en l'état et signalés pour M2. Chaque
  Timere coûte deux draw calls (sprite et ombre).
- **M1 — démo et captures** : `tests/integration/demo_m1.tscn` (vraie partie, joueur devant le
  panneau) ; `M1_SHOT=dunes|wave|forest|perf|village tools/screenshot.sh
  res://tests/integration/demo_m1.tscn build/shots/m1_<vue>.png 300` fige la scène au bon moment
  (image « coup » de l'épée, onde à 3 m…) et écrit draw calls et primitives au journal.
## Intégration M2 — tranche verticale de bout en bout

- **M2 — frontières de zone** (`src/world/zone.gd`, L2 ; contrat PLAN.md section 3) :
  `zone_entered` n'est émis qu'au changement de zone. La dernière zone annoncée est retenue sur
  le corps du joueur (métadonnée `Zone.LAST_ZONE_META`, oubliée avec lui : une nouvelle partie
  repart de zéro) ; une entrée dans cette même zone est ignorée. Cause : les `Bounds` voisins se
  touchent ; un joueur qui longe une frontière effleurait la zone voisine, revenait sans quitter
  la sienne, l'effleurait encore : nom répété dans le HUD et une auto-sauvegarde par effleurement.
  Filtre à la source (tous les écouteurs en profitent : HUD, SaveManager, WaveDirector, journal)
  plutôt que dans WorldManager, dont la zone courante survit d'une partie à l'autre (après un
  retour au menu, une nouvelle partie au village n'aurait rien annoncé et GameState.zone serait
  resté vide). Limite connue, inchangée : après un effleurement, la zone courante reste la
  voisine jusqu'à l'entrée dans une autre. `tests/unit/test_world_island.gd` (L2) fait oublier
  sa zone au joueur factice avant de tester les cinq entrées.
- **M2 — position sauvegardée** (`src/autoload/save_manager.gd`, L8 ; PLAN.md sections 3 et 4) :
  toutes les `checkpoint_interval` = 5 s de jeu (pas en pause), l'état est écrit s'il a changé
  depuis la dernière écriture, la position seulement au-delà de `checkpoint_distance` = 1 m :
  rien tant que le joueur ne bouge pas ; à la perte du focus, à la fermeture, en arrière-plan
  et quand la page Web est masquée (`visibilitychange`, que Godot 4.7 ne relaie pas : écouté par
  `JavaScriptBridge`), `save_on_leave()` écrit l'attente ou, sans attente, l'état s'il a changé.
  Ces écritures n'émettent pas `saved` (pas de « Sauvegardé » à chaque pas). Ajouts :
  `has_unsaved_changes(tolerance)`, `save_on_leave()`, `checkpoint_interval`,
  `checkpoint_distance`. Cause : seuls les cinq signaux d'auto-sauvegarde écrivaient la
  position ; un joueur qui se promenait puis fermait l'onglet la perdait. Sur le Web, l'écriture
  n'est conservée qu'après la copie vers IndexedDB, lancée à l'image suivante et asynchrone :
  mesurée à 25–70 s dans le Chromium sans écran de la VM (rendu logiciel, fil principal saturé
  à 1 image/s), immédiate avec un vrai GPU ; un onglet fermé avant la fin de cette copie perd la
  dernière écriture, d'où la sauvegarde périodique (au pire les 5 dernières secondes de marche).
  Écarté : une copie de secours dans `localStorage` (synchrone) relue au menu, deux stockages à
  réconcilier pour un gain incertain.
- **M2 — chargement** (`src/main.gd`, L0 ; demande L9) : `start_game()` confie le chargement de
  `src/game.tscn` à `Loading.load_scene(path, loading_budget_ms)` (dépendances d'abord, 50 ms de
  travail par image, sans fil) : la barre avance vraiment ; une demande pendant un chargement est
  servie par lui ; un retour au menu pendant le chargement n'ajoute pas la partie.
  `loading_budget_ms` = 0 dans les tests (une dépendance par image : tout est en cache sous GUT).
  Sur le Web, `show_menu()` pose `window.wordendMenuMs` (ms depuis le début de la page), le
  repère du temps jusqu'au menu lu par `tools/web_m2.js`.
- **M2 — retour au menu** (`src/main.gd` ; demande L8) : le chemin de la pause (L10 : `save()`,
  `close_game(false)`, `reload_current_scene()`) est vérifié dans le vrai jeu (partie écrite à la
  position quittée, plus suivie, aucune écriture ensuite, menu sans écran de clic, Continuer) ;
  `main.show_menu()`, que rien n'appelle en jeu, écrit maintenant la partie si elle a changé et
  appelle `close_game(false)` avant de la libérer.
- **M2 — icône et écran de démarrage** (`tools/gen_branding.py`, `assets/ui/icon.png`,
  `assets/ui/boot_splash.png`, `project.godot` ; demande L9) : couchant du shell (ciel violet,
  corail, or, soleil, trois dunes, pétales) et épée plantée dans la dune, générés par Pillow ;
  `application/config/icon` (aussi favicon et apple-touch-icon de l'export Web) et
  `boot_splash/image` étiré en « Cover » (4) sur `bg_color` #1b1231, le fond du shell : plus de
  logo Godot sur fond gris entre le shell et le menu.
- **M2 — manette dans les menus** (`src/ui/inventory.gd`, L7 ; demande L10) : contournement
  gardé, `ui_accept` / `ui_cancel` sans bouton de manette dans project.godot. Raison : A (saut,
  interaction) et B (charge) sont lus par sondage ; la pause et l'inventaire se ferment sur
  l'**appui** de `ui_cancel`, qui arriverait au joueur dans l'image où la pause est levée. Le
  contournement du L10 (`main_menu_input.gd` : A presse le bouton qui a le focus, B revient, au
  relâchement d'un appui reçu par l'écran) est appliqué à l'inventaire, qui ne se fermait à la
  manette que par Y ou Start ; la boîte de dialogue lisait déjà A par `interact`. Parcours
  complet à la manette testé : `test_m2_menu` (geste, croix, stick, A), `test_m2_quest` (marche,
  dialogue, choix, épée, inventaire Y / B), `test_m2_world` (pause Start / B), `test_m2_arena`
  (fin d'arène A).
- **M2 — fin de dialogue** (demande L6) : rien à changer (L1 ignore `interact` et `jump` jusqu'à
  leur relâchement après `dialogue_ended`, L6 a `talk_cooldown`) ; vérifié dans le vrai jeu :
  la dernière réplique fermée à l'Espace (aussi `ui_accept` et `jump`), à E et à A ne fait ni
  sauter ni repartir la conversation (`test_m2_quest`).
- **M2 — fin d'arène** (L10 + M1) : rien à changer ; parcours réels testés sans refermeture
  automatique (`test_m2_arena`) : mort sous les morsures → panneau en attente, jeu non figé, le
  minuteur de WorldManager fait réapparaître au village PV pleins → panneau (score, vague,
  record) → Entrée ; sortie de l'arène avant la vague 1 → panneau tout de suite → A, sans saut.
- **M2 — budget de primitives** (`src/world/island.tscn`, `props/meshes/bead.tres`,
  `props/palm.tscn`, `props/umbrella.tscn`, L2) : ombre du soleil 70 → 50 m (même carte d'ombre
  sur moins de terrain : ombres proches plus nettes) ; `bead.tres` 3 → 2 anneaux (48 → 36
  triangles : fleurs, boutons, bouées, noix de coco, le mesh le plus nombreux de l'île, dessiné
  deux fois par la passe additive du soleil à ombres du rendu Compatibility) ; noix de coco et
  pointe des parasols sans ombre (cachée par celle des feuilles et de la toile). Mesuré par
  `demo_m1` (nouvelles vues `M1_SHOT=village_<zone>` : le village depuis le Spawn de chaque zone
  voisine ; le journal donne les primitives de la passe d'ombre) :

  | Vue | Avant : draw calls, primitives (ombres) | Après |
  | --- | --- | --- |
  | village (départ) | 81, 112 460 (22 428) | 79, 104 708 (21 432) |
  | village_dunes | 85, 154 562 (37 992) | 80, 141 326 (34 296) |
  | village_forest | 87, 154 968 (36 424) | 84, 142 788 (33 928) |
  | village_beach | 91, 150 832 (34 696) | 87, 132 620 (24 440) |
  | village_hill | 78, 154 286 (36 624) | 75, 142 106 (34 128) |
  | dunes / perf (16 Timeres) / forest | 61 / 94 / 45 ; 65 830 / 94 702 / 59 770 | 60 / 92 / 40 ; 63 634 / 89 254 / 54 022 |

  Le reste de la passe d'ombre vient des lots du PropBatcher, un par mesh et par zone : leur
  boîte couvre toute la zone, la distance d'ombre ne les écarte donc pas ; les découper par
  cellules ferait gagner des triangles au prix de draw calls, plus chers sur le Web.
- **M2 — tests d'intégration** (`tests/stubs/m2_game_test.gd`) : vraie racine `src/main.tscn`,
  événements d'entrée réels passés à `Input.parse_input_event` (`InputEventKey`,
  `InputEventJoypadButton`, `InputEventJoypadMotion`, clics). Pièges trouvés : la fenêtre
  headless fait 64 × 64 px (le canevas de 1280 px y est mis à l'échelle : un clic porte
  `root.get_final_transform() * position`) ; la couche de GUT (`GutLayer`, couche 128) prend les
  clics (cachée pendant ces tests) ; les attentes de GUT sont gelées quand l'arbre est en pause
  (fin d'arène, inventaire, pause : `frames()` et `until()` attendent les images du moteur) ;
  un appui doit durer au moins une image physique, sinon, appuyé et relâché pendant une pause
  sans image physique entre les deux, il est encore « just pressed » à la reprise et B lancerait
  une charge qui ne se relâche plus (impossible pour un vrai joueur : un appui dure 50 ms et
  plus, le moteur compte ses images physiques même en pause).
- **M2 — cœur du marque-page** : inchangé. La quête porte les PV max à 6, mais le cœur gagné
  reste vide jusqu'au prochain soin (toutes les deux vagues) ou à la réapparition : choix du L4
  (« le maximum n'est pas un soin », `test_combat_player.gd`). À juger par le propriétaire.
- **M2 — démo et captures** : `tests/integration/demo_m2.tscn` (F6) : la vraie partie au
  village, Chtholly devant la bibliothécaire, la quête prête à jouer ; aucune sauvegarde écrite.
  `M2_SHOT=menu|village|dialogue|forest|reward|arena_end tools/screenshot.sh
  res://tests/integration/demo_m2.tscn build/shots/m2_<vue>.png 150` (`village` →
  `m2_village_hud.png` dans docs/RECETTE_M2.md).
- **M2 — navigateur** (`tools/web_m2.js`, paramètre `?trace=1` des raccourcis de test : le
  journal seul) : profil neuf → menu en 1,9 à 2,2 s (repère `window.wordendMenuMs`, page servie
  en local, rendu logiciel), partie chargée 3 à 7,6 s après Entrée (la page affiche des images
  pendant ce temps : 12 en 6,6 s, compteur `requestAnimationFrame`), bibliothécaire, quête
  acceptée, perte du focus (position écrite), page rechargée → Continuer à la même position
  (écart 0,00 m) ; menu en 1,6 à 3,6 s au rechargement. Console : aucune erreur ; seuls
  avertissements, ceux du pilote logiciel (« GPU stall due to ReadPixels », SwiftShader).
  Build : 10,6 Mo compressés.

## Lot Q — moteur de quêtes

- **Lot Q — format JSON** : une quête est `data/quests/<id>.json` (id, title, summary, giver, main,
  auto_start, requires, steps, rewards ; format complet : docs/QUETES.md), lue par
  `FileAccess` + `JSON.parse` (comme les dialogues, sans erreur moteur sur un fichier invalide),
  vérifiée entièrement (clé inconnue = erreur, clé `_…` = commentaire) puis gardée en cache
  (`QuestData`, statique). Raison : des agents de contenu écrivent les quêtes à la main ; un
  `.tres` avec des sous-ressources d'étapes typées est trop fragile à écrire. `QuestData` garde
  ses champs du L7 (`required_items`, `required_flags` : héritage, quêtes construites en code).
- **Lot Q — quête des pages** : `pages.tres` devient `pages.json`, une seule étape `collect`
  « rapporter à » (`npc: librarian`, `consume: true`) : même objectif et même progression dans le
  HUD (« Fragment de page : 3/5 »), même fin par `complete_quest` dans le dialogue, mêmes tests de
  bout en bout (`test_m2_quest.gd`, `test_quest_tracker.gd`, `test_hud_quest.gd` inchangés).
- **Lot Q — disponibilité calculée** : `&"available"` n'est jamais écrit dans GameState :
  `QuestData.status()` le déduit des prérequis (quêtes terminées, drapeaux posés ou absents) ;
  la condition de dialogue `quest [id, "available"]` l'utilise, `[id, ""]` garde son sens (jamais
  commencée). Raison : `test_m2_quest` attend un état vide avant la proposition, et des
  prérequis modifiés après publication restent cohérents (rien de périmé dans les sauvegardes).
- **Lot Q — étapes linéaires** : une étape courante par quête active, retenue par son id et un
  compteur (`GameState.quest_step`, `quest_step_count`) ; une étape inconnue au chargement (données
  changées) ramène à la première. Pas de branches ni d'étapes facultatives : deux quêtes et un
  drapeau à la place (docs/QUETES.md, « Limites »).
- **Lot Q — validation des étapes** : talk et collect « rapporter à » à la fin d'un dialogue avec
  le PNJ, seulement si l'étape était déjà l'étape courante au `dialogue_started` (le dialogue qui
  démarre une quête ne valide pas sa première étape ; pas de double validation avec
  `advance_quest`) ; reach zone aussi quand le joueur y est déjà, déclencheur redéclenché si son
  étape commence joueur dedans ; kill compté dans la zone du joueur (`GameState.zone` : le signal
  `enemy_killed` du L0 ne porte pas la zone de l'ennemi) ; arena : meilleure vague commencée ou
  meilleur score de série pendant l'étape (les records d'avant ne comptent pas) ; collect sans
  PNJ et flag par l'état de la partie, dès que l'étape commence.
- **Lot Q — fin forcée** (`complete_quest`, ou `set_quest_state(id, &"done")` par un autre
  système) : compatibilité L7, synchrone pendant `quest_updated` ; les étapes restantes sont
  validées d'office (récompenses d'étape comprises) si les objets des étapes collect restantes
  sont là (comptés dans l'ordre, ceux qu'une étape consomme ne servent plus aux suivantes), sinon
  refus : quête remise à `&"active"` à la même étape, `completion_refused`, `push_warning`.
- **Lot Q — file de traitement** : les signaux que le QuestTracker reçoit pendant un traitement
  (ceux de ses propres changements : `inventory_changed` d'un objet consommé…) attendent leur
  tour ; après chaque traitement, vérifications d'état jusqu'à stabilité (étapes validées par
  l'état, quêtes `auto_start`), 200 tours au plus. Raison : une étape collect qui consomme ne se
  valide jamais deux fois, et deux étapes collect de suite prennent chacune leur part.
- **Lot Q — quête suivie** : `GameState.tracked_quest` (sauvegardé) ; une quête qui démarre devient
  la quête suivie ; à sa fin, la première quête active (principales d'abord, puis ordre de
  démarrage) ; le journal la change (Entrée, A, clic). Le HUD n'affiche plus que cette quête,
  avec « +n quêtes · Tab / Select » s'il y en a d'autres (avant : toutes les quêtes actives ; une
  seule existait).
- **Lot Q — sauvegarde v2** : champs `quest_progress` (quest_id → {step, count}) et
  `tracked_quest` ; `SAVE_VERSION` = 2, fichier inchangé (`user://save_v1.json`, nom historique :
  les parties y sont) ; migration v1 → v2 (`_migrate_v1`) : chaque quête active avec données
  reprend à sa première étape, la première quête active est suivie ; v0 passe par v1. Les
  anciennes versions du jeu refusent une sauvegarde v2 (version future) au lieu de perdre
  l'avancement en silence. Auto-sauvegarde sur `quest_step_completed` ; un compteur qui avance
  (ennemi vaincu) est écrit par le point de contrôle de 5 s (pas une écriture par Timere).
- **Lot Q — signaux** : `flag_changed` (GameState.set_flag, si la valeur change),
  `quest_step_updated` (GameState.set_quest_step), `quest_step_completed` (QuestTracker),
  `quest_advance_requested` (DialogueRunner → QuestTracker : le dialogue ne lit pas le tracker),
  `trigger_entered` (QuestTrigger), `tracked_quest_changed` (GameState). Raison : chaque système
  passe par l'EventBus ; le QuestTracker est un nœud de game.tscn, pas un autoload.
- **Lot Q — dialogues** : condition `quest_step` [quête, étape] ; effets `take_item` (tout ou
  rien), `give_item` (un nom, [objet, n] ou {objet: n}), `clear_flag`, `advance_quest` (id ou
  [quête, étape] : garde) ; ordre fixe d'application `take_item`, `give_item`, `set_flag`,
  `clear_flag`, `start_quest`, `advance_quest`, `complete_quest`, avant le texte et les choix du
  nœud ; clés des nœuds et des choix vérifiées à la lecture (une faute de frappe rend le dialogue
  invalide, comme une condition inconnue au L6). Les dialogues du jeu n'utilisaient que des clés
  connues : aucun ne change.
- **Lot Q — journal** : `src/ui/journal.tscn`, enfant `Journal` du HUD (game.tscn est figé, comme
  `PauseMenu`) ; action `journal` : Tab, L (touches physiques libres ; Tab n'est lu qu'hors focus
  de l'interface, le jeu n'en a pas) et bouton 4 Select / Back (libre) ; modal comme l'inventaire
  (pause, PROCESS_MODE_ALWAYS, fermé par journal, Échap, pause, inventaire, B, clic dehors ;
  jamais pendant un dialogue ni par-dessus une pause) ; étapes suivantes cachées (pas de
  spoiler) ; pastilles des étapes dessinées (le ✓ n'est pas dans la police par défaut).
- **Lot Q — marqueurs des PNJ** : `QuestMarker`, Label3D face à la caméra, doré à contour prune
  (couleurs de `HudAccent`), police par défaut grassie, 0,45 m au-dessus de `SkinData.height_m`,
  flotte de ±6 cm ; « ? » (étape talk, ou collect « rapporter à » objets en poche) prioritaire
  sur « ! » (quête disponible, hors `auto_start`) ; caché pendant le dialogue du PNJ ; recalculé
  en fin d'image sur les signaux de quête, d'inventaire et de drapeaux.
- **Lot Q — déclencheurs** : `QuestTrigger` posé dans `src/npc/placements/<zone>.tscn` (aucun
  nœud ajouté aux zones figées du L2) ; cylindre réglable (`radius`, `height`) propre à chaque
  déclencheur, `trigger_id` (défaut : nom du nœud), `set_flag` facultatif ;
  `test_npc.gd` (`test_village_placement`) ignore les déclencheurs parmi les PNJ du village.
- **Lot Q — quêtes d'exemple** : `example_patrol` (exemple de docs/QUETES.md), `demo_tour` et
  `demo_followup` (test d'intégration, captures), leurs PNJ, dialogues et emplacements vivent dans
  `tests/data/` (exclus de l'export) : le moteur n'ajoute aucun contenu narratif au jeu ; la
  direction narrative écrit l'histoire (docs/lore/PLAN.md).
- **Lot Q — tests de contenu** : `tests/unit/test_quest_content.gd` vérifie chaque quête et ses
  renvois (PNJ avec dialogue, objets, ennemis, zones, arènes, déclencheurs posés, prérequis sans
  cycle, quête proposée par un dialogue ou `auto_start`, quêtes, étapes et objets nommés par les
  dialogues, titres ≤ 40 et objectifs ≤ 70 caractères) : un agent de contenu le lance après
  chaque quête ; `tests/stubs/q_quest_test.gd` donne les raccourcis des tests de scénario.
- **Lot Q — captures** : `tests/integration/demo_q.tscn`, `Q_SHOT=hud|journal tools/screenshot.sh
  res://tests/integration/demo_q.tscn build/shots/q_<vue>.png 150`.
- **Lot Q — navigateur** : build Web exporté rejoué avec `tools/web_m2.js` (Chromium sans écran) :
  « ! » au-dessus de la bibliothécaire (`QuestData.all()` lit `data/quests` dans le paquet
  exporté, par `ResourceLoader.list_directory`), marqueur caché pendant son dialogue, quête
  acceptée, page rechargée puis « Continuer » : quête en cours et position reprises (sauvegarde v2
  dans IndexedDB) ; console sans erreur (seuls avertissements, ceux du pilote logiciel).
- **Systèmes et textes — présence des PNJ** : `visible_if` vit dans `NpcData` (pas sur le nœud
  `Npc`) ; un même personnage à plusieurs endroits = une `NpcData` par emplacement (`willem`,
  `willem_training`, `willem_stars`), chacune avec sa condition. Pour l'exprimer, la grammaire des
  dialogues gagne `quest_step` à liste d'étapes et `not_quest_step` (même évaluateur pour les
  deux usages). Absent : caché et `process_mode` DISABLED (corps et `InteractArea` retirés de la
  physique) plutôt que des couches à zéro ; réévaluation en fin d'image, jamais pendant la
  conversation du PNJ. Skin du joueur : comparaison des `SkinData.id`, skin effectif comme le
  joueur (`GameState.skin_id`, sinon le skin par défaut).
- **Systèmes et textes — orateur** : `event_bus.gd` est figé, `dialogue_line` ne porte pas
  l'orateur ; la boîte de dialogue lit `DialogueRunner.current_speaker_id()` (fixé avant chaque
  ligne). `speaker_id` inconnu : avertissement et repli sur le PNJ du dialogue ; parler par la
  voix d'un autre ne valide pas d'étape `talk` vers lui. `DialogueRunner.find_npc` cherche
  `data/npcs` puis les dossiers ajoutés par `add_npc_dir` (tests).
- **Systèmes et textes — `{player}`** : remplacé en dernier par `format_text` (après `{count:…}`,
  `{left:…}`, `{best:…}`), aussi dans `speaker` ; « Chtholly » si aucun skin n'est chargé.
  Le HUD et le journal passent titres, résumés, objectifs et aides par `format_text`.
- **Systèmes et textes — journal** : `src/ui/journal.gd` est hors du périmètre du lot ; le
  journal du HUD reçoit le script `src/ui/hud_journal.gd` (sous-classe, posé sur `HUD/Journal`
  dans `hud.tscn`) qui remplace les variables après chaque `_show_details`. À replier dans
  `journal.gd` quand ce fichier sera repris.
- **Systèmes et textes — textes de l'histoire** : un seul fichier, `data/texts/story.json`, lu
  par `DialogueRunner.story_text` (le moteur de textes) : clés imbriquées, commentaires `_…`,
  arènes par `arena_id` avec repli sur `default` ; seule l'invite du panneau garde un texte de
  secours dans le code (sans invite, la série ne pourrait plus commencer). Typographie des
  dialogues (apostrophe ’, espace insécable) ; le menu garde l'apostrophe droite de ses textes.
- **Systèmes et textes — chute et défaite** : `WorldManager.rescued(zone_id)` (signal de
  l'autoload, comme `SaveManager.saved` ; l'EventBus est figé) ; le HUD fait le fondu au blanc
  (`FallFlash`) et le message (`StoryMessage`, bas de l'écran, en fondu). Défaite : « Retour à
  l'entrepôt… » pendant le fondu au noir, « Les autres t'ont ramenée à l'entrepôt. » à
  `player_respawned` ; le message reste figé derrière l'écran de fin d'arène (pause).
- **Systèmes et textes — corps de Timere** : `drops = {}` dans les quatre `.tres` ; le mécanisme
  (`EnemyData.drops`, `Enemy.drops_enabled`) reste et se teste sur une copie des données.
- **Systèmes et textes — tests hors liste** : changer une invite, un nom ou les drops casse des
  tests qui les figeaient ; mis à jour d'une ligne (aucun n'appartient aux deux autres agents) :
  `test_arena.gd`, `test_m1_arena.gd`, `test_m1_shortcuts.gd` (invite), `test_quest_example.gd`,
  `test_quest_data.gd` (noms), `test_enemy.gd`, `tests/integration/test_q_quest.gd` (drops : la
  démo ramasse deux pages posées), et le script du navigateur `tools/web_m1.js` (invite). `tests/integration/test_m2_quest.gd` (contenu de l'acte 1) n'est
  pas touché : il joue encore les pages lâchées.
- **Acte 1 — démarrage** : `act1_main` est `auto_start` : tout QuestTracker la démarre et la suit
  (nouvelle partie, anciennes sauvegardes) ; `tests/stubs/q_quest_test.gd` met de côté les quêtes
  `auto_start` du jeu (état `held`) pour les tests du moteur, `release_auto_start()` les rend
  (scénarios `tests/unit/test_act1_*.gd`).
- **Acte 1 — plusieurs scènes chez un PNJ** : une étape `talk` se valide à la fin de toute
  conversation avec son PNJ ; les `entries` mettent donc les scènes d'étape avant les répliques
  d'avancement, les propositions, l'après-acte et les répliques par défaut (HISTOIRE.md 3.6 ;
  vérifié par `test_act1_dialogues.gd`), et la dernière réplique d'une scène propose par des
  choix conditionnels les autres scènes en attente chez le même PNJ (« routeur » : sans choix
  visible, le nœud suit son `next`).
- **Acte 1 — portrait d'un second orateur** : les nœuds à plusieurs voix portent `speaker` et la
  clé provisoire `_speaker_id` (ignorée par le DialogueRunner actuel) ; quand `speaker_id`
  existera (« Systèmes et textes »), l'intégration la renomme (`test_act1_dialogues.gd` échoue
  pour le rappeler).
- **Acte 1 — instances de Willem** : `willem_training` (bois) et `willem_stars` (colline) sont des
  PNJ à part (visuel `willem`, dialogues propres), toujours présents en attendant `visible_if` ;
  les étapes `training` et `promise` les visent, le Willem de l'entrepôt donne les aides.
- **Acte 1 — aides** : des `hint` en plus de HISTOIRE.md sur les étapes de collecte des quêtes
  secondaires (où chercher draps, myosotis, engrenages, baies, pages).
- **Acte 1 — hauteurs** : les objets sont posés au sol actuel (y local ≠ 0 en relief :
  `dunes_gear_2` 0,81, `dunes_flower_1` 0,92, `forest_page_4` 0,17, `forest_berries_3` 0,38,
  `hill_sheet_1` 8) et `couchant_edge` à y = 0,1 ; à revoir avec le terrain du « Monde »
  (`test_m1_world.gd`).
- **Acte 1 — écarts de position (décor actuel)** : le guetteur en (−13 ; 0,2 ; −12) au lieu de
  (−14 ; 0,2 ; −10) (hors de la ruine) et Willem au sommet en (1 ; 8,2 ; −0,8) au lieu de
  (3 ; 8,2 ; 0) (entre la rambarde et le banc du belvédère) ; avec le décor du « Monde », qui
  respecte HISTOIRE.md 3.3, reprendre ces positions (et `tests/unit/test_npc.gd`).
- **Acte 1 — visuels des PNJ** : `data/npcs/visuals/<id>.tres` (SkinData hors de `data/skins`,
  donc non jouables), planches de remplacement de `tools/gen_placeholders.py npcs` (options
  `--style`, `--species`, `--wear`, `--eyes`, `--accent` ; sortie par défaut inchangée) ; seule
  Chtholly reste jouable, les tests qui choisissent un skin prennent un dossier de skins
  temporaire.
- **Acte 1 — objets** : icônes de `tools/gen_item_icons.py` ; souvenirs non empilables (livre,
  dessin, carte, myosotis séché, promesse), dessert et cheese-cake empilables (soins du M3).
- **Acte 1 — anciennes sauvegardes** : coquillages et marque-page restent des objets inconnus
  (nom = id, sans icône) ; la quête `pages`, sans données, n'est plus au journal, mais
  `QuestData.active_ids()` la compte encore (« +1 quête » du HUD) : à filtrer à l'intégration
  (QuestData ou migration de SaveManager).
- **Acte 1 — quête d'exemple des tests** : `example_patrol` requiert le livre d'images et donne
  deux myosotis ; le forgeron d'exemple est posé par `tests/data/placements/village.tscn` ;
  l'exemple commenté de docs/QUETES.md est à aligner.

## Acte 1 — Monde (île n° 68)

- **Monde — île flottante** (`src/world/terrain.gd`, `island_rock.gd`, `island.tscn`) : le bord
  garde le tracé de l'ancienne côte (superellipse, encoche du quai au sud, avancée du Couchant à
  l'ouest) et devient une lèvre de pierre au niveau du sol ; au-delà, le vide. Sous la lèvre :
  falaise, dessous en cône de roche, racines, cascade du ruisseau (un mesh, sans collision). La
  mer de nuages remplace l'eau (nœud `Water` gardé, plan à y = −60 m, shader non éclairé) ; la
  KillZone (y = −15 m) et `WorldManager.FALL_LIMIT` ramènent au Spawn de la zone (`rescue()`).
- **Monde — collision du sol** : ConcavePolygonShape3D tirée des mêmes triangles que le mesh
  visible, coupés sur la ligne exacte du bord (au lieu de la HeightMapShape3D 129 × 129 de L2) :
  on marche sur ce qu'on voit et rien ne porte au-delà du bord. Pentes < 40° sur chaque facette.
- **Monde — barrière du bord** : ruban vertical à 0,8 m en deçà du bord, couche 8
  (`enemy_barrier`), deux faces : les Timeres ne tombent pas, le joueur passe.
- **Monde — décor fondu** (`prop_batcher.gd`) : une zone fond tous ses meshes en ArrayMesh à
  couleurs de sommet, par famille (ombre, sans ombre, lumineux) et par case de 32 m (la caméra
  et la carte d'ombre écartent les cases hors champ) ; matériau `materials/toon.tres`
  (ShaderMaterial `shaders/props.gdshader`) ; un albedo d'alpha 0,5 marque un feuillage.
- **Monde — cloche de veille** (`src/enemies/arena.tscn`, visuel seulement) : le panneau de
  l'arène devient une cloche de bronze à potence sur un poteau (le cahier des charges dit
  « cloche sur un poteau », MONDE.md un portique) ; `arena_panel.gd`, son invite et
  `WaveDirector` sont inchangés (le texte de l'invite revient à l'agent Systèmes et textes).
- **Monde — noms des zones** : ceux de MONDE.md (section 2.1), apostrophe droite comme dans
  MONDE.md (« L'entrepôt des fées ») ; chaînes mises à jour aussi dans `test_m2_quest.gd`,
  `test_m2_resume.gd` et `test_m2_menu.gd` (seulement les noms).
- **Monde — fleur du village** : l'ancienne place de `village_flower_1` (−17, 0, −3) tombe dans
  l'aile ouest de l'entrepôt ; `test_m1_world.gd` l'exempte tant qu'elle y est (`RELOCATED`) et
  la vérifie à sa nouvelle place (17, 0, 5).
- **Monde — places de l'acte 1** (`tests/unit/test_world_story_spots.gd`) : les positions de
  HISTOIRE.md (section 3.3) sont vérifiées sans dépendre des fichiers d'emplacement : à 3 m du
  vide, au sol à la hauteur prévue, hors de toute collision et de tout décor visible tout près
  (les baies restent sur leur buisson), reliées à pied au village. Le belvédère du sommet passe à
  un plancher de Ø 5,2 m pour que Willem soit « à côté du belvédère » et le drap à son entrée.
- **Monde — direction artistique** (demande de l'utilisateur : se rapprocher de Zelda: Breath
  of the Wild dans les limites du rendu Compatibility, à la place du style précédent) : palette
  naturelle un peu désaturée et chaude (herbe vert-jaune, terre ocre, roche gris-bleu, bois
  brun) ; éclairage cel discret partagé (`shaders/cel.gdshaderinc` : deux paliers doux, liseré à
  contre-jour sur les décors, terminateur large sur la roche) ; normales lissées (roche, arbres) ;
  ciel en dégradé bleu doux, halo chaud du soleil et nuages doux (`shaders/sky.gdshader`, sans
  TIME : calculé une fois) ; brume bleutée (densité 0,002, diffusion du soleil 0,3, brume basse
  sous y = −4 m) ; ombres bleutées (ambiante 0,55) ; soleil chaud à 20° à l'ouest-sud-ouest
  (énergie 0,2, ombre sur 40 m) ; mer de nuages blanche, creux gris-bleu, crêtes dorées côté
  soleil ; arbres hauts à tronc élancé et feuillage en masses, marches de 0,15 à 0,2 m, portes de
  2,1 à 2,2 m, champignons à taille réelle.
- **Monde — herbe** (`src/world/grass.gd`, `shaders/grass.gdshader`) : ~20 000 touffes de sept
  brins tirées une fois (graine 68, ~0,15 s en natif au chargement), une MultiMeshInstance3D par
  case de 16 m, sans ombre portée ; balancement au vent ; les touffes s'aplatissent de 18 à 27 m
  de la caméra puis la case disparaît ; jamais sur les chemins, la cour, le cercle de veille
  (15 m), la rue, la place, le quai, le marais, le ruisseau ; tracés recopiés de
  `shaders/terrain.gdshader`.
- **Monde — horizon** : îles en silhouette (n° 53 au sud, sur la route du passeur ; n° 15 à
  l'ouest, au-delà du Couchant ; deux au nord) et huit rochers flottants sous le bord, dans
  `Decor` (sans collision).
- **Monde — budget Web** (`demo_m1`, draw calls et primitives dont la passe d'ombre) :

  | Vue | Avant l'acte 1 (8263efe) | Acte 1, direction naturelle |
  | --- | --- | --- |
  | village (départ) | 79, 104 708 (21 432) | 94, 91 300 (17 328) |
  | village_dunes | 80, 141 326 (34 296) | 102, 107 155 (18 812) |
  | village_forest | 84, 142 788 (33 928) | 103, 93 942 (13 440) |
  | village_beach | 87, 132 620 (24 440) | 111, 111 683 (12 422) |
  | village_hill | 75, 142 106 (34 128) | 108, 118 924 (20 246) |
  | dunes / perf (16 Timeres) / forest | 60 / 92 / 40 ; 63 634 / 89 254 / 54 022 | 74 / 95 / 53 ; 57 223 / 61 144 / 46 940 |

  Les cases de 32 m et l'herbe coûtent des draw calls (une trentaine) mais retirent des
  triangles à la passe d'ombre ; tout reste sous 150 draw calls et 150 000 primitives.
- **Monde — captures** : `MONDE_VIEW=ile|entrepot|bois|couchant|port|colline|bord|dessous
  tools/screenshot.sh res://tests/integration/demo_monde.tscn build/shots/monde_<vue>.png 40`.
- **Monde — terrain d'entraînement** (bois du marais) : herbe rase sans arbre ni rocher sur
  15 m de rayon autour du local (0, 0) de la zone ; les buts de fortune sont à ses deux bouts
  (14 m), le banc et le râtelier en bordure (le banc est la place de `WillemTraining`,
  HISTOIRE.md 3.3) ; `test_m1_world.gd` vérifie plat et sans collision sur 12 m, et la clairière
  des Timeres sur 6 m.
- **Assets 3D — skins jouables** (choix validé par l'utilisateur le 7 octobre 2026,
  `docs/ASSETS_3D.md` section 4.7) : Chtholly, Ithea, Nephren, Nopht, Rhantolk et les fées de la
  communauté sont jouables, toutes avec Seniorious en main ; Willem reste un PNJ ; Lillia sera
  un bonus plus tard.
- **Assets 3D — tenue de Chtholly à l'acte 1** (choix validé par l'utilisateur le 7 octobre 2026,
  section 4.6) : uniforme de fée soldat de la Garde ailée (veste bleu nuit à boutons argentés,
  broche d'argent), d'après la bible, au lieu de la tenue noire et dorée de la planche 2D ; la
  tenue de ville viendra en variante.
- **Assets 3D — identifiants des modèles** (choix validé par l'utilisateur le 7 octobre 2026,
  section 4.9) : orthographe de la traduction (`glick`, `kaya`, `suowong`, `suowong_young`,
  `ebon_candle`, `ebon_candle_ancient`, `doctor`, `baroni_makish`) ; les dossiers de la première
  livraison seront remplacés sous ces noms.

## Acte 1 — intégration (phase D)

- **Intégration acte 1 — présence de Willem et de Limeskin** (`data/npcs/*.tres`, `visible_if`) :
  Willem à l'entrepôt sauf pendant `training` et `promise` (`not_quest_step`), au terrain
  pendant `training` (`quest_step`), au sommet à partir de `promise` et pour toujours (drapeau
  `starry_night`, nouvelle récompense de l'étape `starry_hill` : la grammaire n'a pas de « ou »,
  et `quest_step` est faux une fois la quête terminée) ; Limeskin au port à partir de `the_edge`
  (drapeau `duel_lost`, récompense de `training` : le Barocupot vient la chercher, HISTOIRE.md
  3.3). Après l'acte, Willem est donc à l'entrepôt **et** sur la colline (« Les étoiles… » de
  `test_m2_quest.gd`, demandé pour les derniers soirs avant le départ) : écart assumé à
  HISTOIRE.md 3.3 (« un seul willem ») jusqu'au cycle jour/nuit du M3, qui le mettra au sommet
  la nuit seulement. Pendant l'acte, un seul Willem à la fois (`test_act1_presence.gd`). Les
  répliques d'ambiance de `willem_training` hors de son étape ne s'entendent plus (gardées comme
  repli) ; Willem apparaît au sommet quand le joueur entre dans `hill_summit` (pas de cinématique
  d'arrivée en M2).
- **Intégration acte 1 — quêtes sans données** (`QuestData.active_ids()` / `done_ids()`) : une
  quête de la sauvegarde qui n'a plus de fichier (`pages` restée active dans une partie du jalon
  M2) est ignorée à la source : ni au journal, ni dans le « +n quêtes » du HUD, ni dans les
  boucles du QuestTracker. Son état reste dans GameState (aucune migration ne l'efface : une
  quête rendue au jeu plus tard retrouverait son état). `test_act1_saves.gd`.
- **Intégration acte 1 — `{player}`** (`DialogueRunner.player_name()`, `first_name()`) : le
  prénom de la protagoniste, c'est-à-dire le nom affiché du skin sans sa variante (ce qui suit
  « · », comme « · 3D » des skins de la PR n° 1, qui ne sont pas renommés) réduit à son premier
  mot : « Chtholly » pour « Chtholly Nota Seniorious · 3D ». Les deux répliques qui l'emploient
  sont des apostrophes (« Alors reviens, {player} », « Mlle {player} ») ; le nom complet y
  sonnerait faux. Limite connue : choisir le skin 3D de Willem, d'Ithea ou de Nephren ne cache
  pas leur PNJ (les ids de skins diffèrent : `sukasuka_ithea` contre `ithea`), et les cacher
  rendrait leurs quêtes impossibles ; à trancher avec la reprise des modèles 3D.
- **Intégration acte 1 — rejetons des bois** (`src/enemies/free_enemies.gd`, racine `Enemies`
  des cinq fichiers d'emplacement d'ennemis) : réapparition plutôt que mort comptée pour l'étape
  suivante (le joueur voit qui il doit abattre, et un rejeton tué hors des bois, qui ne compte
  pas, ne bloque plus non plus). Pendant une étape `kill` d'une quête active qui vise la zone
  (`zone` égale ou absente) et ses ennemis (`any` ou leur id), les ennemis libres tués
  réapparaissent à leur place, sous leur nom, avec leurs données : au début de l'étape et à
  chaque retour du joueur dans la zone ; jamais au-delà de la population de départ ; en fin
  d'image (aucun changement d'arbre pendant un signal de mort). Hors de ces étapes, un mort
  reste mort jusqu'au rechargement de la partie (comportement d'avant). Pas de script sur les
  scènes de zone (L2) ; aucun nœud ajouté sous `Enemies` (les tests comptent ses enfants).
  `tests/unit/test_free_enemies.gd`.
- **Intégration acte 1 — places sur l'île n° 68** : le guetteur reprend sa place de HISTOIRE.md
  3.3, (−14 ; 0,2 ; −10), que le décor du monde garantit (l'écart (−13 ; −12) n'avait plus de
  raison) ; `couchant_edge` est posé au sol (y = 0, mesuré sous le cylindre) ;
  `test_m1_world.gd` ne fait plus d'exception pour `village_flower_1` (à sa place (17 ; 0 ; 5)
  depuis le contenu de l'acte 1). Les objets, PNJ et déclencheurs suivent maintenant HISTOIRE.md
  3.3 sans écart (`test_npc.gd`, `test_world_story_spots.gd`).
- **Intégration acte 1 — fin de la veille** : l'écran de fin d'arène montre le nom de la zone de
  MONDE.md 2.1 (« Le bord du Couchant », `Zone.display_name`) et, au Couchant, « Veilles
  tenues » au lieu de « Séries jouées » (nouvelle clé `arenas/<arène>/games` de
  `data/texts/story.json`, comme `end_title`) : le vocabulaire de la veille et du registre de
  Tiat. La cloche de veille (`arena.tscn`, `Panel/Bell`) est la seule chose visible au départ
  des veilles depuis la fusion du monde ; la planche facultative (`Label`) reste lue par
  `arena_panel.gd` pour les arènes qui en auraient une.
- **Intégration acte 1 — quêtes secondaires dans la vraie partie**
  (`tests/integration/test_act1_side_quests.gd`) : les six quêtes jouées l'une après l'autre
  dans `main.tscn`, avec les vrais PNJ (présents, abordés de face, E) et les vrais objets de
  l'île (ramassés en marchant dessus) ; les répliques passent par `dialogue_choice_made` (les
  appuis qui les lisent sont prouvés par `test_m2_quest.gd`) ; le drapeau `first_vigil_done` est
  posé par le test (la première veille est jouée par `test_m2_quest.gd`). Garantie de plus,
  sans scène : `test_act1_items_in_world.gd` (chaque étape collect trouve assez d'objets dans
  l'île ou chez un PNJ, et les quêtes n'en prennent jamais plus qu'il n'y en a).
- **Intégration acte 1 — restes du jalon M2** : la quête d'exemple des tests (`example_patrol`,
  docs/QUETES.md) passe du forgeron au soldat de la Garde (`example_guard`, PNJ de test au
  visuel du guetteur ; fichier nommé comme son id, `find_npc` le trouve) et vise les rejetons
  des bois ; la démo du moteur (`demo_tour`) le salue ; les tests du moteur gardent des ids
  d'objets arbitraires (`shell`), mais plus de textes de l'ancien contenu ; l'exemple de format
  de PLAN.md section 4 et `test_dialogue_runner.gd` font parler Nephren. Restent, assumés comme
  historiques : docs/DECISIONS.md, docs/CONTRACT_REQUESTS.md, docs/lore/ (bible, fiches), les
  dossiers 3D hors périmètre, les fixtures d'anciennes sauvegardes (`test_save_migration.gd`,
  `test_act1_saves.gd`), les listes d'éléments retirés (`test_skin_registry.gd`,
  `test_item_data.gd`) et les gardes contre « Seniolis » (`test_credits.gd`,
  `test_sys_story_content.gd`, `test_act1_dialogues.gd`).
- **Intégration acte 1 — recherche des restes du jalon M2** (critère 16 de docs/RECETTE_M2.md) :
  `git grep -n -i "bibliothécaire\|forgeron\|coquillage\|marque-page\|Seniolis"` ; les
  résultats assumés sont listés à la ligne « restes du jalon M2 » ci-dessus.
- **Intégration acte 1 — menu des fées** (`src/ui/main_menu.*`) : les vignettes défilent dans un
  cadre (`%SkinScroll`, deux rangées et demie au plus : `MAX_SKIN_GRID_HEIGHT`, signe qu'il y en a
  d'autres) et un nom trop long finit par « … » (entier dans l'infobulle). Avec les sept skins
  « · 3D » de la PR n° 1 (huit vignettes, quatre rangées), le panneau sortait de l'écran de
  1280 × 720 : titre « Choisis ta fée » et phrase « Ta fée prend la place de Chtholly dans
  l'histoire. » hors champ, noms débordant des vignettes. La vignette choisie (celle de la
  sauvegarde) est amenée en vue à l'ouverture ; le clavier et la manette font défiler
  (`follow_focus`). Les skins eux-mêmes ne changent pas. `test_menu_story.gd`.
- **Socle HD-2D — changement de direction** (demande de l'utilisateur, PR « contrats ») : la
  direction artistique passe de « au minimum proche de *Breath of the Wild* » (lignes « Monde —
  direction artistique » et suivantes, désormais historiques) à un HD-2D à la manière
  d'*Octopath Traveler* : personnages en sprites, décor en relief fait uniquement d'images, caméra
  fixe inclinée, flou de profondeur, lueur, lumière chaude. Cahier des charges des images :
  docs/ASSETS_HD2D.md (remplace docs/ASSETS_3D.md et docs/TEXTURES_PEINTES.md). Tout le code de
  jeu, les données, les quêtes, l'interface, les ids et le tracé de l'île sont gardés.
- **Socle HD-2D — purge de la 3D** : retirés (avec leurs .uid, .import et lignes de crédits) les
  modèles et leur outil (`assets/models/`, `docs/sprites/`, `tools/sukasuka3d/`, les sept skins
  `sukasuka_*`, `test_sukasuka_models.gd`), la variante mesh de `CharacterVisual` et
  `SkinData.mesh_scene`, le décor calculé (maillages des décors, herbe en MultiMesh et
  `grass.gd`, shaders cel / herbe / décors / ciel, matériaux toon et glow, `assets/textures/`),
  la caméra en orbite (`SpringArm3D`), les démos et tests du seul décor calculé. Ithea et Nephren
  restent des PNJ donneurs de quête ; leur skin jouable revient avec leur planche HD-2D (H6).
  Nopht et Rhantolk, jouables, ont une planche de remplacement générée (`gen_placeholders.py`).
- **Socle HD-2D — échelle** : 96 px d'image par mètre partout (Chtholly 1,5 m = 144 px, la
  planche de l'easter egg), 48 px/m pour le très lointain (îles lointaines à 12 px/m, aéronefs et
  rochers flottants à 48 px/m : vus de loin, moitié moins de mémoire). Filtrage au plus proche
  voisin, sans mipmaps sur les panneaux.
- **Socle HD-2D — décor en panneaux** : `DecorPanel` (racine d'un décor debout) se tourne
  toujours vers le sud (la caméra regarde le nord), sa collision garde la rotation du nœud ;
  ombre au sol = quad d'une image de tache (`assets/hd2d/fx/shadow.png`), pas d'ombre du soleil
  (ombres du DirectionalLight3D coupées : coûteuses en WebGL 2 et fausses sur un panneau).
  Les décors bas qui se traversent (liste `NON_BLOCKING` de `test_hd2d_decor.gd` : herbes,
  fleurs, buissons, champignons, roseaux, potager, pierres de l'anneau, cloche, banc, ballon,
  lanterne tombée, aéronefs et îles du fond) n'ont pas de collision ; les autres ont leur
  `Collision` sur la couche 1.
- **Socle HD-2D — bâtiments** : `Building` = volume simple (murs, toit à deux pans) couvert de
  matières en tuiles de 2 m (`assets/hd2d/buildings/materials/`) et une façade peinte posée sur
  la face sud ; l'image de façade porte fenêtres et portes, la lueur des fenêtres est détectée
  par couleur (proche de `glow_color`) dans `panel.gdshader`, pas par une seconde image.
- **Socle HD-2D — fusion des draw calls** : `PropBatcher` (déjà dans `Geometry`) fond au
  lancement les MeshInstance3D qui portent un `material_override` en un mesh par image et par
  case (« Batch… ») ; mesure (`tools/hd2d_shots.sh`) : 32 à 70 draw calls selon la vue (menu
  38, cour de l'entrepôt 50, entrepôt de face au zoom le plus large 70, bois 51, Couchant 32,
  port 39, colline 50, conversation 53, veille 44), budget 200 ; 43 à 67 dans le navigateur.
- **Socle HD-2D — sol** : les douze tuiles (384 × 384, 4 m) sont réunies dans un atlas
  (`ground_atlas.png`, 4 × 3) plutôt qu'un Texture2DArray (`sampler2DArray` est fragile en
  Compatibility / WebGL 2 et son import n'a pas d'équivalent texte simple) ; le shader tire une
  tuile par pixel d'art (48 par mètre) et trame les bords des masques (Bayer 4 × 4), sans
  mélange flou. Les masques (chemins, cour, rue, marais, cercle de veille) restent calculés dans
  le shader, recopiés de MONDE.md section 2.
- **Socle HD-2D — falaises** : la roche sous l'île garde son maillage calculé (`island_rock.gd`,
  forme, pas apparence) mais prend trois images (lèvre herbeuse, falaise, dessous) en UV de
  mètres (périmètre, couture au nord) ; brouillard tramé en quatre paliers vers le bas.
- **Socle HD-2D — caméra fixe** : tangage 32°, champ 30°, distance 21 m (zoom 14 à 25 m,
  molette ou stick droit), retard de suivi (5 par seconde) et avance de 0,25 s sur la vitesse,
  limites Rect2(-64, -66, 128, 128), visée du verrouillage entre joueur et cible (40 %, 5 m au
  plus) sans tourner ; `yaw()` vaut 0 et `forward()` le nord : les commandes sont relatives à
  l'écran. `recenter_behind` ne fait plus rien ; `snap_behind` recale sans avance (respawn).
- **Socle HD-2D — post-traitement** : un `CanvasLayer` `PostFX` (couche −1, sous l'interface en
  couche 1) dans `camera_rig.tscn`, un ColorRect et un shader canvas_item (`post_fx.gdshader`) :
  flou de profondeur par bandes de l'écran (tilt-shift, 12 échantillons de Poisson : net au
  centre, 5 px en haut, 2,5 px en bas), lueur au-dessus de 0,86, étalonnage chaud, contraste,
  saturation, vignette. Pas de profondeur lue : les bandes suffisent avec une caméra fixe et
  restent bon marché en WebGL 2. Le menu et les captures sans joueur ne l'ont pas.
- **Socle HD-2D — lumières** : les lampes de cristal et le portail de la palissade portent une
  OmniLight3D chaude (portée 5 à 6 m, sans ombre) ; pas de draw call de plus en Compatibility
  tant qu'elles restent peu nombreuses par vue. Soleil 0,75, ambiance lavande chaude, brouillard
  orangé.
- **Socle HD-2D — pierres de l'anneau** : 58 × 20 px (0,6 × 0,2 m), pour que le cercle de veille
  ne bloque ni la vue ni les tests de veille (rien de plus haut que 0,3 m dans le cercle).
  Passerelle du port : un `Building` plat (pont) et la rambarde en panneau ; belvédère de la
  colline : image décalée (`image_offset`) derrière sa collision.
- **Socle HD-2D — fond du menu** : `main_menu_backdrop.gd` découpe le ciel peint, les îles
  lointaines, les dunes et des feuilles qui volent dans les mêmes images que le jeu, au plus
  proche voisin.
- **Socle HD-2D — tests de marche** : avec la caméra fixe, « W après set_aim_direction » ne
  marche plus vers la cible ; les tests passent par `hold_toward()` / `release_move()`
  (`m1_game_test.gd`) et `walk_aim_until()` / `hold_aim()` (`m2_game_test.gd`), et le navigateur
  par `window.wordendAim` (posé par `src/test_shortcuts.gd`) d'où `tools/web_m2.js` tire les
  touches à tenir.
- **Socle HD-2D — budget de l'export** : `tools/check.sh` appelle `tools/build_size.sh` après
  l'export et passe au rouge au-delà de 25 Mo compressés (`test_export_web.gd` le vérifie) ;
  mesure : 12,4 Mo compressés (40,8 Mo bruts) contre 18,4 Mo avant le socle.
- **Socle HD-2D — portraits** : les portraits de remplacement restent à 128 px (tête agrandie
  ×2) ; le cahier des charges demande 256 px pour les vrais (H6), la boîte de dialogue les met à
  l'échelle.
- **Socle HD-2D — contrats changés** (PLAN.md section 3) : structure de `camera_rig.tscn`
  (`CameraRig` > `Camera3D` + `PostFX/Screen`, plus de `SpringArm3D`) et API de `CameraRig`
  (mêmes noms, sens « fixe ») ; `SkinData.mesh_scene` et la variante mesh de `CharacterVisual`
  retirés ; nouvelles classes `DecorPanel` et `Building` ; règle du décor en images (CLAUDE.md) ;
  `tools/check.sh` fait respecter le budget de taille. Ni `project.godot`, ni `event_bus.gd`, ni
  les couches de collision ne changent.
- **H1 — fusion des livraisons d'images (PR n° 2 et 3 de ChatGPT/Codex)** : `main` (7227cf1 puis
  f7933e6) est fusionnée dans la branche HD-2D, qui fait foi pour le code, les outils, les docs,
  les données et `export_presets.cfg` ; seules entrent dans l'arbre les images aux chemins du
  cahier des charges et les planches des personnages de l'acte 1. Restent dans l'historique de
  `main` (`git show f7933e6:<chemin>`, ou `git checkout f7933e6 -- <chemin>` pour les reprendre) :
  `assets/source/**` (natifs, 380 Mo), `docs/sprites/**` (galeries, `LIVRAISON_*.md`, aperçus),
  `assets/sprites2d/**` (trois grandes images d'aperçu : directions de Nygglatho et de Tiat, cour
  du village), `data/visuals2d/**`, `scenes/dev/**`, `scenes/hd2d/**` (promenade de l'ancienne
  version), `tools/sukasuka2d/**` (galeries et paquets ZIP, sans usage dans le jeu),
  `tools/sukasuka3d/**`, `tools/hd2d_priority*_manifest.json`, `tools/hd2d_library_check.gd`, les
  skins `sukasuka_*`, `docs/ASSETS_3D.md`, les changements de code faits pour la version 3D, et les
  35 personnages des actes suivants (`almaria`, `ballman`, `baroni`, `bibliothecaire`,
  `bird_soldier`, `bitora`, `cat_soldier`, `doctor`, `ebon_candle`, `ebon_candle_ancient`,
  `ecluecla`, `elq`, `enfant`, `forgeron`, `frog_soldier`, `glick`, `godrey`, `golem`,
  `hawk_soldier`, `illustote`, `jorget`, `kaya`, `knight_canine`, `knight_feline`, `lillia`,
  `phyr`, `police_golem`, `rabbit_soldier`, `rinsha`, `sarya`, `suowong`, `suowong_young`,
  `tilfey`, `willemia`, `wolf_soldier`) : l'export Web doit rester sous 25 Mo.
- **H1 — images de décor livrées** : 95 des 96 images du manifeste prises telles quelles ;
  `ring_stone` garde son remplaçant (pierre plate de 20 cm : rien ne dépasse 0,3 m dans le cercle
  de veille) ; `distant_island_b` recadrée sur le bord bas (`fit`) ; `distant_island_b` et `_c`
  débarrassées des îles « fantômes » lavande détachées autour de l'île (composantes bleutées
  effacées, le reste intact) ; atlas du sol refait. Icônes d'objets : `flower_blue`,
  `page_fragment`, `unknown` livrées à leur nom ; `berries`, `gear` et `cloth`, livrées sous les
  noms de l'ancienne liste d'objets, deviennent `wild_berries`, `clock_gear` et `laundry_sheet`.
- **H6 — trois vues par planche** (`SkinData.front_sheet`/`front_json`, `back_sheet`/`back_json`,
  facultatives ; `SheetLoader.SIDE`/`FRONT`/`BACK`, `has_view`, `view_problem`, `view_texture`,
  `view_json`, `frames_for(skin, view)` ; `CharacterVisual.current_view()`) : le profil
  (`sprite_sheet` + `frames_json`, tourné vers la droite, en miroir pour la gauche) reste la
  planche de référence et la seule vue des planches de l'easter egg et des remplaçants. La vue
  suit la direction par rapport à la caméra fixe : à plus de 45° de l'axe gauche-droite de
  l'écran, la face (vers le bas de l'écran) ou le dos (vers le haut), sinon le profil, avec une
  zone morte de ± 10° (on ne quitte une vue qu'une fois la diagonale franchement passée). Une vue
  n'est prise que si elle a exactement les animations, nombres d'images, cadences, boucles,
  « coup » et « onde » du profil : l'horloge, les signaux et le combat ignorent la vue affichée,
  et changer de vue n'émet rien. Taille d'un pixel par vue : la hauteur debout du profil est
  gardée (Chtholly de face, dessinée à 130 px au lieu de 144, est agrandie de 11 %). Ombre :
  celle du profil.
- **H6 — ancres des planches livrées** (`tools/hd2d_sheets.py anchors`) : les ancres calculées
  par Codex (« à revoir ») faisaient glisser les pieds (jusqu'à 50 px d'une image à l'autre de
  face) ; elles sont recalculées : pieds sombres (ou alpha pour Nopht et le Timere) cherchés près
  de l'axe du corps pour les images debout, images immobiles (repos, parle) recalées sur la 1re
  image de repos par superposition des jambes, y sous les pieds. Chtholly et le Timere gardent les
  ancres revues à l'œil avant ce recalage ; le dos de Ramikeldi et du boulanger (une queue ou un
  bras cache un pied) est recalé sur le buste (`anchors --torso`, clé `torso` du manifeste).
  Planches de contrôle : `python3 tools/hd2d_sheets.py strip`.
- **H6 — « parle » à une autre échelle** : dans 13 vues (boulanger, serveur, passeur, Nephren,
  vendeur du snack et Tiat de profil ; Nephren et Tiat de face ; marchande d'œufs, Limeskin,
  Nygglatho et Tiat de dos ; Limeskin de profil), « parle » est dessinée 6 à 36 % plus petite ou
  plus grande que « repos » : le personnage rapetissait en se mettant à parler. Ces vues jouent
  les images de « repos » à la cadence de « parle » (`hd2d_sheets.py alias parle repos`) jusqu'à
  ce que les dessins soient refaits (liste dans le manifeste, clé `aliases`). Willem n'a pas de
  « parle » : il garde « repos » en conversation.
- **H6 — PNJ et skins branchés** : les 17 PNJ de l'acte 1 (`data/npcs/visuals/`) et les skins
  Nopht et Rhantolk prennent les planches livrées en trois vues ; Ithea et Nephren deviennent
  jouables (`data/skins/ithea_soldier.tres`, `nephren_soldier.tres`, mêmes planches que leur PNJ,
  sept animations de combat) sous un autre id que leur PNJ : la limite connue demeure (leur PNJ
  reste présent quand on les joue, les cacher rendrait leurs quêtes impossibles ; à trancher avec
  l'histoire). Les planches des PNJ non jouables sont réduites aux animations du cahier (3.2 :
  repos, marche, parle ; `hd2d_sheets.py trim`) : la `course` livrée en plus et le combat de Willem
  (qui n'est pas jouable) sortent de l'arbre (planches complètes dans `main`, f7933e6), 1,3 Mo de
  moins dans l'export ; la marche, que les PNJ ne jouent pas encore, reste (ses défauts d'échelle
  ne sont que signalés). `tests/unit/test_npc.gd` (L6) demandait aux visuels de PNJ les sept
  animations de combat des anciennes silhouettes ; il suit désormais le cahier.
- **H1 — mesures** : export Web 23,5 Mo compressés (12,4 au commit de départ 3fe0c66 ; 24,8 avec
  les planches complètes des PNJ), budget 25 Mo ; arbre du dépôt 36,7 Mo (8,7 au départ, 465 dans
  `main` avec les natifs et les galeries). Réserves possibles : les douze tuiles de sol, inutiles
  à l'exécution (1,1 Mo, docs/CONTRACT_REQUESTS.md), la marche des PNJ (1,4 Mo), l'atlas du sol
  réduit à 256 couleurs (1,1 Mo).
- **H2 — découpe du décor autour du joueur** : plutôt qu'un fondu par décor (il faudrait un
  matériau par bâtiment, donc des draw calls et des images de plus), une découpe tramée (Bayer
  4 × 4 en pixels d'écran) dans une ellipse autour du corps du joueur (0,8 × 1,1 m) efface tout
  décor plus proche de la caméra que lui : entrepôt, arbres, draps, palissade. Le nœud
  `SeeThrough` du village (`see_through.gd`, après `Geometry`) remplace chaque matériau de panneau
  des meshes fondus par une copie dont le shader est le code de `panel.gdshader` (H5) augmenté au
  lancement de `see_through.gdshaderinc` : même nombre de matériaux, aucun draw call de plus, et
  les changements de H5 au panneau sont suivis. Les PNJ ne bougent pas : aucun décor n'est posé
  devant eux (`test_village_decor.gd` le vérifie pixel par pixel depuis la caméra de leur
  conversation), la découpe ne suit que le joueur.
- **H2 — hauteur de l'entrepôt** : murs gardés à 6,5 m et façades à leur taille (les images
  dessinées livrées dans `main` le sont à cette taille ; consigne de l'orchestrateur) ; le
  cadrage de l'entrepôt passe par la caméra (H5).
- **H2 — composition de la cour** : la descente de la salle des armes passe à l'angle sud-est de
  l'aile (−13,9, −1,35), près de Willem, et laisse voir la porte de l'infirmerie au milieu du
  pignon ; la seconde corde à linge passe à l'est d'Almita (15,8, 8,6) : elle la cachait, Almita
  se détache maintenant sur les draps de la première ; la lampe nord-ouest de la place passe au
  porche (−5,5, −8,7), entre Nygglatho et Nephren ; les parterres de façade, posés dans l'aile,
  vont le long des murs libres ; les arbres du premier plan restent contre la palissade sud
  (z ≈ 18 à 19,6) pour encadrer le bas de l'image sans couvrir la cour ; potager en trois rangs,
  deux buts de deux caisses à l'aire de jeux. Le décor n'utilise que des images partagées ou du
  village (pas de décor propre aux bois ou au port).
- **H2 — reprise : composition calée sur les images livrées** (main, PR n° 2 et n° 3, intégrées
  par H1 aux mêmes chemins et tailles) : porche centré sur la double porte de la façade
  (x −10,35, il ne peut aller plus à l'ouest sans entrer dans l'aile), poteaux de collision au
  droit de ceux de l'image et dans son plan ; banc de Nephren sous la fenêtre en saillie
  (x −4,35) ; descente de la salle des armes à x −13,6, juste à l'est de la porte de
  l'infirmerie ; poteaux du portail (±1,49 m), du linge (±2,66 m) et margelle du puits (rayon
  0,8 m) au droit de leur dessin. Les remplaçants encore dans la branche sont décalés de quelques
  décimètres jusqu'à la fusion de H1. Ces réglages remplacent ceux de la ligne « composition de
  la cour » pour la descente, les arbres du sud et le banc de l'aire de jeux.
- **H2 — palissade de profil** : les côtés est et ouest prennent `palisade_side.tscn` (même
  image, `keep_orientation`, ombre allongée le long de la clôture) : vue de biais, la clôture
  fuit vers le fond au lieu de s'empiler en escalier de panneaux tournés vers le sud. Le nord et
  le sud gardent `palisade.tscn` de face.
- **H2 — arrière de l'entrepôt fermé** : deux modules de palissade (`BackFence`) ferment les
  couloirs de 2 m entre le L et la palissade (au nord-est du corps principal, au sud-ouest de
  l'aile). Rien n'y est à voir et la caméra fixe n'y montrait que le toit ; la découpe autour du
  joueur reste pour les arbres, le porche et les draps.
- **H2 — premier plan** : un arbre de 7 m contre la palissade sud cache, quand on longe celle-ci,
  ce qui est 10 à 15 m plus au nord sur la même ligne de visée. Les grands arbres du sud vont donc
  de part et d'autre du portail sud (sapin x −3,9, rouille x −7,8, jaune x 4,4) et aux coins
  (x ±19) ; aucun entre x 7 et 17 (il cachait Almita) ni devant l'aire de jeux.
- **H2 — « pas plus d'une seconde » mesuré** : `test_village_decor.gd` fait marcher la caméra du
  joueur le long de vingt allées (pas de 1 m) qui balaient la cour ; un PNJ dans la part centrale
  de l'écran (80 % du champ : au bord, sous le panneau de quête, il revient au centre dès qu'on va
  vers lui) dont l'axe du corps est caché à 0,25, 0,55 et 0,85 m ne doit pas le rester 4 m d'affilée
  (une seconde à `walk_speed`). Le message nomme l'image en cause ; le test passe avec les
  remplaçants et avec les images livrées.
- **H2 — cheminée** : faite en matières (`warehouse_chimney.tscn`, `Building` 1 × 1 m en
  `wall_stone` / `roof_slate`, au faîtage, x −7,5) plutôt qu'en image : MONDE.md la veut et le
  cahier des charges n'en a pas ; elle n'entre dans le cadre que si la caméra montre le toit (H5).
- **H7 — signes avant l'attaque** : chaque coup et chaque charge d'un Timere passe par un état
  `windup` (`AttackData.windup` : morsure 0,3 s, fouet 0,35 s, charge 0,4 s ; Grand × 1,5 par
  `EnemyData.windup_scale`) : posture tassée, éclat au-dessus de la tête, zone exacte de la
  Hitbox (ou couloir de la charge) au sol (`src/enemies/telegraph.gd`). Pour garder la cadence
  de l'easter egg, la préparation commence quand la recharge n'en est plus qu'à sa durée : au
  contact, rien ne ralentit ; seul le premier coup après l'approche attend. La zone suit le
  joueur pendant la préparation (on s'en sort en reculant, pas d'un pas de côté), puis le coup
  part dans la direction figée. Pas de son : le jeu n'a pas encore de système audio d'effets.
- **H7 — effets en sprites** : onde, éclats, crocs, fouet, poussière, coup d'épée au sol,
  réticule, chevron, ombre nette et signes de préparation sont des images de pixel art à 96 px/m
  dans `src/combat/fx/` (remplaçants de `make_fx.py`, hors de `assets/hd2d/`, qui est à H1), lues
  par `CombatFx` ; ce qui dit « où » est une décalcomanie au sol (portée et zone exactes), ce qui
  dit « quand » un sprite debout. Les éclats et le bord des zones passent devant les corps (sans
  test de profondeur), la poussière et le remplissage restent derrière. L'onde est un croissant
  debout tourné vers la caméra (bosse vers où elle file, aussi large à l'écran que sa trace) plus
  sa trace au sol ; `charge_wave.gdshader` est retiré. Les effets se posent dans la zone, jamais
  dans `Enemies` ni `Spawned`, dont d'autres systèmes comptent les enfants.
- **H7 — arrêt sur image et secousse** : chiffres dans `data/attacks` (`hitstop` 0,05 à 0,08 s,
  `shake` 2,5 à 8 cm) et `EnemyData.strike_shake` (Grand). L'arrêt fige la planche
  (`process_mode` désactivé, minuteur en temps physique) et retarde le recul du corps touché sans
  le raccourcir. La secousse décale `Camera3D.h_offset` / `v_offset` (jamais de rotation, le
  haut de l'écran reste le nord), sans toucher à `camera_rig.*` (H5) : demande d'API dans
  docs/CONTRACT_REQUESTS.md. Pas de chiffres de dégâts : un éclair de la silhouette exacte du
  combattant (`HitFlash`, une copie peinte de l'image affichée), crème pour un Timere, rose
  pour la joueuse.
- **H7 — corps reconnaissables** : tant que les quatre corps partagent la planche du Timere,
  `EnemyData.tint` (multiplie la planche) les distingue avec l'échelle ; le bondissant laisse
  une traînée (poussière, images rémanentes) pendant sa charge, le Grand se prépare plus
  lentement et fait trembler l'image quand il frappe.
- **H7 — déplacements en vue fixe** : à moins de 4 m, un Timere vise un point à au moins 30° de
  l'axe nord-sud du joueur (il arrive par les côtés de l'écran, où l'épée l'atteint encore, au
  lieu de se cacher derrière ou devant le sprite) ; dans la séparation, un écart nord-sud compte
  pour 0,7 fois sa longueur, et deux Timeres alignés nord-sud s'écartent de côté.
- **H7 — ombres nettes** : chaque combattant a sa `GroundShadow` (disque net à la taille du
  corps, pas du dessin), au-dessus de l'ombre douce du `CharacterVisual`, gardée faute de
  pouvoir toucher `src/visuals/` (demande dans docs/CONTRACT_REQUESTS.md) ; celle de la joueuse
  reste au sol pendant un saut. Coût : un draw call par combattant (banc de 12 Timeres au cercle
  de veille : 97 draw calls contre 66, budget 200).
- **H7 — vague 5 atteignable** : vérifiée par un joueur automatique qui ne lit que les signes
  de l'écran (`tests/unit/test_combat_vigil.gd`, vraie partie, rythme réel, 5 PV) : vague 5 en
  76 à 81 s avec 1 à 3 morsures sur quatre graines ; sans lire les signes, 3 à 6 morsures et
  parfois la défaite à la vague 4. Le test dure environ 80 s.
- **H5 — pixel art filtré** : les images du monde (96 px/m) sont plus denses que l'écran
  (≈ 65 px/m au point visé en 1280 × 720) ; au plus proche voisin et sans mipmaps, elles faisaient
  du moiré et scintillaient dès que la caméra glissait. Panneaux, murs, toits et roche passent par
  `src/world/shaders/pixel_art.gdshaderinc` (sampler linéaire) : de près, pixels nets dont seule la
  frontière est lissée sur un pixel d'écran ; de loin, 2 × 2 échantillons bilinéaires sur
  l'empreinte du pixel (sans mipmaps : les images importées n'en ont pas, et en créer une copie
  doublerait leur mémoire). Écart moyen entre deux images à un demi-pixel de caméra (sur 255) :
  7,7 → 2,4 (bois), 9,1 → 2,9 (colline), 7,9 → 2,3 (cour).
- **H5 — sol à mipmaps** : `IslandTerrain.mipmapped_atlas()` refait en jeu l'atlas du sol avec ses
  mipmaps (moyenne 2 × 2 : jamais deux tuiles de 384 px mélangées jusqu'au niveau 7 ; 11 ms, une
  fois ; l'atlas importé est relâché). Le shader lit `textureLod` au niveau tiré des dérivées
  continues de la position et prend deux échantillons le long de l'axe étiré par la perspective
  (anisotrope fait main) : le filtrage anisotrope du pilote, avec le saut de `fract()` d'une
  tuile à l'autre, débordait sur les cases voisines de l'atlas (lignes à chaque tuile). Les fleurs
  d'un pixel s'effacent quand un pixel d'art devient plus petit que l'écran.
- **H5 — tramage du sol** : le tramage au pixel d'écran du travail repris dessinait au loin une
  grille de points et une couture nette au changement de mode ; de près, l'ordre de Bayer 4 × 4
  semait une grille régulière (10 % de touffes vertes sur toute la colline, 30 % dans les taches
  d'herbe sèche). Les masques se calculent une fois (`ground_masks`), la tuile se choisit pour un
  seuil (`pick_layer`) : de près, un seuil par pixel d'art tiré d'un bruit entier (brins épars,
  plus de grille ; le style « une tuile par pixel d'art » du socle reste) ; au loin (plus de deux
  pixels d'art par pixel d'écran), la moyenne des tuiles de quatre seuils décalés par un bruit
  d'écran, masques lus à la position continue : un mélange sans grain ni escalier ; entre les
  deux, un fondu. Une tuile n'est lue qu'une fois par pixel (la même tuile pour deux seuils n'est
  pas relue).
- **H5 — cadrage des façades** (demande de l'orchestrateur : l'entrepôt garde ses murs de 6,5 m et
  son faîtage de 9 m) : avec 32° de tangage et 30° de champ, le haut de l'écran passe à 6,5 m
  au-dessus du joueur et plus bas derrière lui. Devant la façade sud d'un `Building` (groupe
  `Building.GROUP`, ajouté) à moins de 18 m au nord du joueur et dans le champ, la caméra garde sa
  place et lève les yeux (tangage jusqu'à 24°) juste assez pour que le haut du mur + 0,4 m (le
  bas du toit) tienne dans le cadre, les pieds du joueur au-dessus de 85 % de l'écran ; si cela ne
  suffit pas, elle recule du moins possible (jusqu'à 29 m) ; lissage 2,5/s. Calcul exact par les
  angles (quelques arcs tangentes par image, dichotomie pour le recul) au lieu d'une double
  boucle de recherche. La demande d'une façade naît sur son premier mètre et s'éteint sur les 4
  derniers mètres de la portée et les 3 derniers du champ : aucun saut de plus de 1,5° par quart
  de mètre (testé). Lever les yeux garde la taille des personnages (un recul de 29 m les
  réduisait à 72 %) : cour de l'entrepôt 24,6°, vue du village 25,5°, porche 27°, rue du Port
  27,5°, toujours à 21 m ; au Spawn (20 m de la façade) et là où l'on se bat (veille, bois),
  32°. Le faîtage entier (9 m, 4 m derrière la façade) demanderait un recul de 25 à 29 m depuis
  la cour : il n'est pas visé, seul le bas du toit l'est.
- **H5 — cadrage en conversation** : le cadrage d'une façade met les pieds du joueur vers 80 % de
  la hauteur de l'écran, sous la boîte de dialogue (bas 30 %) ; entre `EventBus.dialogue_started`
  et `dialogue_ended`, la caméra garde les pieds au-dessus de 65 % de l'écran et ne recule pas
  (la façade peut être coupée) : le joueur et son interlocuteur restent au-dessus de la boîte.
- **H5 — distance de la caméra** : à 21 m et 30° de champ, l'écran montre 11,25 m de haut au point
  visé : en 1920 × 1080, 96 px par mètre, la densité des images ; les planches s'affichent au
  pixel près en plein écran HD (en 1280 × 720, aux deux tiers). On garde 21 m.
- **H5 — bornes de la caméra** : `limits` = Rect2(−71, −70, 142, 136) (au lieu de −64…64) : au bord
  du Couchant (x = −77) le joueur restait à 13 m du centre, au bord de l'écran ; il en est
  désormais à 6 m au plus et l'on voit la lèvre, la falaise et la mer de nuages.
- **H5 — flou de profondeur** : la bande nette va de 4,5 m devant le joueur à 9 m derrière lui,
  projetés par la caméra à chaque image (`focus_center`, `focus_half` de post_fx.gdshader) : le
  joueur et ceux qui l'entourent ne sont jamais flous, même décentrés (retard, avance,
  verrouillage, bornes, cadrage d'une façade). Le flou lit les mipmaps de l'image
  (`hint_screen_texture, filter_linear_mipmap`, que le rendu Compatibility floute lui-même) :
  quatre lectures en croix au lieu de douze, rayon continu (5,5 px en haut, 2,5 px en bas) ; la
  lueur lit deux niveaux (3 et 5) au-dessus d'un seuil de 0,7. Le matériau est copié par chaque
  caméra.
- **H5 — étalonnage** : en plus de la teinte chaude, du contraste, de la saturation et de la
  vignette : virage des ombres vers le lavande et des hautes lumières vers l'or (12 %), voile de
  brume pêche en haut de l'écran (le lointain) et lumière du couchant au bord gauche (l'ouest).
- **H5 — réglages de lumière** : `HD2DLighting` (`src/world/materials/hd2d_lighting.gd`) réunit
  soleil, ambiance, brouillard, ciel, mer de nuages, lanternes et étalonnage ;
  `lighting_sunset.tres` (valeurs d'island.tscn et de post_fx.gdshader, testé),
  `lighting_dusk.tres`, `lighting_night.tres` (lune froide à l'est-sud-est, lanternes × 2,2) ;
  `apply(island)` les pose sur des copies (environnement, mer de nuages, matériau de la caméra).
  Le nœud `Lighting` d'island.tscn (`day_phase_lighting.gd`) les pose sur
  `EventBus.day_phase_changed` (contrat existant : evening → crépuscule, night → nuit, morning et
  day → couchant) ; rien ne l'émet encore : l'acte 1 reste au couchant, la promesse de nuit sur
  la colline (M3) n'aura qu'à l'émettre. Les planches des personnages ne sont pas éclairées : chaque
  réglage porte leur teinte (`sprite_tint`, nuit 0,6 / 0,66 / 0,86), rendue par
  `HD2DLighting.active_sprite_tint()` pour H6 (CONTRACT_REQUESTS).
- **H5 — ombres et brume** : l'ombre des panneaux (fx/shadow.png, presque opaque) est ramenée à
  55 % au cœur, poussée et allongée de 12 % vers l'est (le couchant à l'ouest) ; le brouillard de
  hauteur passe à 0,015 par mètre sous −8 m (0,04 sous −6 m) : la mer de nuages se voit sous la
  brume au bord de l'île au lieu d'un aplat rose.
- **H5 — mesures** (VM partagée entre plusieurs agents, rendu logiciel : chiffres relatifs) :
  écart moyen entre deux images à un demi-pixel de caméra (sur 255, `build/h5/shimmer.gd`) :
  village 7,9 → 2,0, entrepôt 7,4 → 2,0, bois 7,7 → 2,1, Couchant 6,2 → 2,1, port 8,0 → 2,6,
  colline 9,1 → 2,4. Draw calls (`tools/hd2d_shots.sh`) : menu 38, cour 93 (50 au départ : la
  caméra qui lève les yeux montre la façade et les arbres derrière), entrepôt 79, bois 51,
  Couchant 32, port 52, colline 50, conversation 66, veille 45 ; budget 200. Chromium headless
  (`tools/web_m2.js … zones`, Spawn de chaque zone, deux paires départ / H5) : 0,27 à 0,52
  image/s des deux côtés, sans écart au-delà du bruit. Banc A/B dans un seul processus (Xvfb,
  llvmpipe, shaders du départ et de H5 échangés à chaud) : le post-traitement de H5 coûte moins
  (quatre lectures dans les mipmaps contre douze), le sol et les panneaux filtrés coûtent plus ;
  au total, de −1 % à +9 % selon la vue. Sur un vrai GPU, ces lectures de texture ne pèsent rien.
- **H1 bis — fusion des corrections d'images (PR n° 4, `main` deca738)** : la branche HD-2D fait
  foi pour le code, les outils et `.gitattributes` (la ligne ajoutée pour les galeries n'a pas
  d'objet sans elles) ; entrent les images et JSON corrigés d'Ithea, de Nephren, de Nygglatho,
  Lakhesh, Collon, Pannibal et Limeskin (trois vues et portraits), des profils du serveur et du
  boulanger, des îles lointaines B et C et de l'enduit crème. Restent dans l'historique de `main`
  (`git show deca738:<chemin>`) : `docs/sprites/**` (dont `CORRECTIONS_ASSETS.md`, galeries
  autonomes, aperçus des attaques), `assets/source/**`, `tools/sukasuka2d/**` (dont
  `make_asset_review.py`), `tools/hd2d_weapon_preview.gd`, `tests/tools/test_prepare_delivery.py`
  et le chevalier félin (actes suivants).
- **H1 bis — pipeline de H1 repassé** : ancres recalculées sur les 23 vues corrigées (Collon par
  le bas de la silhouette, `--feet alpha`, clé `feet` du manifeste : son nouveau bandeau rouge
  était pris pour ses pieds) et revues sur planches de contrôle ; planches des PNJ réduites à
  repos, marche et parle. Règle de l'alias `parle` → `repos` rendue explicite : un écart de plus
  de 6 % (`STANDING_TOLERANCE`) entre une image de `parle` et la 1re de `repos` (elle redonne
  exactement les 13 vues de H1 sur les planches de f7933e6). Retiré : boulanger de profil,
  Nygglatho et Limeskin de dos (redessinés à la bonne taille) ; gardé : serveur, passeur, vendeur
  du snack et Limeskin de profil, Nephren de profil et de face, Tiat, marchande d'œufs de dos ;
  ajouté : Nygglatho de profil (115 %), Limeskin de face (108 %), Lakhesh de face (106 %),
  redessinés plus grands par la PR n° 4.
- **H1 bis — profil de Pannibal toléré** : la PR n° 4 l'a redessiné (épée de bois, brindille) à
  111 px au lieu de 120, alors que la face et le dos font 118 et 120 px. Garder l'ancien profil
  ferait apparaître et disparaître l'épée quand il se tourne ; agrandir l'image abîmerait le
  pixel art. Nouvelle clé `accepted` du manifeste (`{"side": ["height"]}`) : `hd2d_sheets.py
  check` en fait une remarque tant que l'écart reste sous 12 % ; le jeu garde 1,25 m (pixels
  8 % plus gros de profil) et met la face et le dos à la hauteur du profil. Dans la liste des
  images à refaire (`docs/ASSETS_HD2D.md` section 12, nouvelle).
- **H1 bis — mesures** : export Web 23,7 Mo compressés (wasm 9,7 + pck 14,0 ; 23,5 à la fin de
  H1), budget 25 Mo ; arbre du dépôt 37,2 Mo (36,7 à 667fd4e) : les planches corrigées sont un peu
  plus lourdes (Ithea, Limeskin), les PNJ restent réduits à repos, marche et parle.
- **Cahier n° 2 du décor** (`docs/ASSETS_HD2D_MONDE.md`) : environ 300 images qui s'ajoutent
  aux livraisons (variantes de forme par famille, sous-bois et lisières, tuiles `_b` et nouvelles
  matières de sol, décalques au sol, flancs de bâtiments, maisons du bourg et du port, objets de
  la vie, bandes animées, nuages et lointain), en lots A à G. Nouveaux formats : décalque au sol
  (`assets/hd2d/decals/`, vu de dessus), bande animée (`assets/hd2d/anim/`, images côte à côte),
  flanc de bâtiment (`<nom>_side.png`, plaqué à l'est et retourné à l'ouest), lisière (pan de
  forêt de 16 m raccordable), premier plan ; « alpha doux » permis pour la fumée, la brume, la
  lumière, les nuages et les ombres. Le moteur les apprendra dans un lot de code (section 17 du
  cahier). Captures de l'état actuel jointes dans `docs/img/` (dossier ignoré par Godot).
- **Dirigeables refaits** : navires volants sans ballon de gaz (BIBLE 3.9 : four enchanté et
  hélices), dessinés de profil proue à droite, à 96 px/m à quai, hélices latérales en bandes
  animées posées sur un moyeu. Ils étaient amarrés au sud du quai, hors du champ de la caméra qui
  regarde le nord : ils iront de flanc à l'est et à l'ouest du quai ; d'autres passent dans le
  ciel (24 px/m).
- **Budget Web** : le cahier n° 2 ajouterait 15 à 20 Mo à l'export (23,7 Mo pour 25 Mo
  aujourd'hui) : à trancher avant son intégration (relever le budget, compresser les grandes
  images ou charger par zone).
- **Budget Web relevé de 25 à 60 Mo compressés** (choix de l'utilisateur : la qualité des images
  passe avant le poids). Les 25 Mo étaient un objectif du plan (temps de premier chargement), pas
  une limite de GitHub Pages ; le plan prévoyait déjà 60 Mo à M4. `tools/build_size.sh`,
  `tools/check.sh`, l'étape de la CI, `PLAN.md` et `docs/web.md` passent à 60 Mo ; le budget des
  images du manifeste (`test_hd2d_assets.gd`) de 16 à 64 Mo de PNG. Les images restent importées
  sans perte (WebP sans perte) ; le cahier n° 2 ne demande plus de réduire les couleurs. Les
  mesures et critères déjà passés (recette M2, lot L9) gardent leurs 25 Mo d'alors.
- **Recette du 8 octobre 2026 : caméra qui pompe et tremblements** (jeu sur GitHub Pages). Deux
  causes mesurées (marche scriptée, journal image par image) : (1) le cadrage automatique des
  bâtiments (H5) faisait varier le tangage de 24,7 à 31,9° et glisser le joueur de 170 px à
  l'écran en passant devant l'entrepôt, ressenti comme un zoom d'avant en arrière ; (2) sans
  lissage physique, le joueur tremblait de 2 à 3 px à l'écran dès que l'affichage ne tournait pas
  à 60 images/s (45 ou 144 : 0, 1 ou 2 pas de physique par image). Corrections : cadrage constant
  (tangage 32°, distance du zoom), point visé à 2,5 m au nord du joueur (un mur de 6,5 m à 2 m
  devant lui tient dans le cadre), avance dans le sens de la marche lissée (0,2 s, 2,5/s),
  conversation : point visé qui glisse vers le joueur ; lissage physique activé
  (`physics/common/physics_interpolation`, PR « contrats »), limité au monde 3D (`Game` ON,
  `UI` et `Main` OFF) ; caméra, anneau de verrouillage et ombre du joueur posés hors lissage sur
  la place affichée (`get_global_transform_interpolated`) ; `WorldManager.teleport` et
  `CameraRig.snap` remettent le lissage à zéro. Mesure après : tremblement < 0,3 px à 45, 60 et
  144 images/s ; tangage et distance fixes. Les tests du cadrage des bâtiments sont remplacés.
- **H9 — données de chaque exemplaire dans UV2** : la phase d'une bande animée (UV2.x) et le
  décalage vers la caméra (UV2.y, m) d'un panneau, la part de l'exemplaire (x) et la couche (y)
  d'un décalque passent par les sommets ; le PropBatcher garde les UV2 : tous les panneaux d'une
  image restent un draw call par case, animés compris. Phase : hachage de la position au centimètre,
  32 pas (peu de meshes) ; l'image change dans le shader avec TIME, qui continue pendant la pause.
- **H9 — panel.gdshader en deux** : son cœur (uniformes, bande, décalage, couleur) passe dans
  `panel_core.gdshaderinc`, partagé avec `panel_foreground.gdshader` ; panel.gdshader garde sa
  fonction fragment écrite en clair (la découpe du village l'augmente) et écrit POSITION (décalage
  vers la caméra) ; rien ne change à l'œil.
- **H9 — premier plan** : shader à part (la découpe du village ne convertit que panel.gdshader),
  ellipse de 1,4 × 1,9 m autour du corps du joueur où il s'efface en trame 4 × 4 en gardant 20 %
  de ses pixels au cœur (le tronc flou devient translucide) ; le centre est posé une fois par image
  par les panneaux de premier plan eux-mêmes, sur la place affichée du joueur (lissage physique).
- **H9 — décalques couchés sur le sol** : le mesh reprend les triangles mêmes du sol sous le
  décalque, découpés à son bord (pas de projection ni de quad flottant) : aucun jour ni scintillement
  sur les pentes ; tiré vers la caméra de 0,1 % de sa distance, plus 0,04 % par couche et 0,02 % ×
  la part de l'exemplaire (ordre stable entre deux décalques superposés). Décalques doux : priorité
  de rendu −9 + couche (sous les ombres des panneaux, −1, et sous les personnages) ; décalques durs :
  un matériau par image quelle que soit la couche. Un décalque déplacé se recouche (notification).
- **H9 — flancs** : quad de la taille de l'image (pas étiré à l'emprise) à FACADE_GAP devant le
  mur, côté gauche au sud des deux côtés (retourné vu de l'ouest), éclairé comme les murs (relief
  0,6 : le flanc ouest, au couchant, plus clair) ; `side_contract_size()` donne la taille attendue
  pour les vérifications de la pose.
- **H9 — petits panneaux de mur et de toit** : cheminées, lucarnes, lierre, enseignes se posent
  sur la surface (contre la façade, à FACADE_GAP devant le mur, ou au pied de la cheminée sur le pan
  sud) avec `depth_offset` 0,05 à 0,1 m et `shadow_width` 0 : dessinés devant le mur ou le toit sans
  bouger à l'écran ; contre un flanc : `keep_orientation` en plus.
- **H9 — variantes** : graphe des plus proches voisins (une forêt) parcouru en largeur, chaque
  point évite la variante du point qui l'atteint (toujours possible dès deux variantes) ; tirages
  des variantes et du retournement sur des suites à part : les lacets et échelles des PropScatter
  existants ne changent pas ; retournement seulement si la racine de la scène est un DecorPanel.
- **H9 — sol à 27 tuiles** : alternance des `_b` par plaques de bruit (deux octaves, environ 8 m)
  au bord tramé comme les autres masques ; masques des nouvelles matières calculés seulement si
  l'atlas a plus de 12 tuiles (le sol coûte ce qu'il coûtait) ; prairie fleurie sur la colline
  seulement si sa tuile existe (son repli, l'herbe verte, trouerait l'herbe dorée) ; potager : teinte
  d'avant tant que `garden_soil` manque ; gravier : chemins entre z = 28 et 58 (le bourg) ; mousse
  et feuilles plus denses à plus de 2 à 9 m d'un chemin.
- **H9 — ciel qui dérive** : mouvement dans le shader, matériau porté par le mesh (le PropBatcher
  de Decor ne le fond pas), boîte du trajet entier (écarté hors champ) ; dans island.tscn, cinq
  voyageurs (floating_rock deux fois, distant_island_c) à 24 px/m, z de −135 à −205, y de −40 à −20 :
  la caméra regarde vers le bas (17° au haut de l'écran), le ciel ne se voit qu'au bord nord de
  l'île, au-dessus de la mer de nuages.
- **H9 — petites vies** : chaque sprite a sa place dans un pavage du monde de période la boîte,
  ramenée dans la boîte qui suit le point visé par la caméra (rien ne glisse avec elle) ; temps
  propre (figé en pause) ; caméra et joueur lus à leur place affichée ; caché hors de sa région.
- **H9 — démo des formats** : l'île sans ses zones et un atlas de 27 tuiles fabriqué à l'exécution
  (les `_b` sont la tuile retournée et éclaircie, les matières des teintes) ; aucune image du
  cahier n° 2 lue (le lot H10 les crée).
- **H10 — manifeste du cahier n° 2** (`tools/hd2d_manifest.json`, version 2, une image par ligne) :
  les 300 images de `docs/ASSETS_HD2D_MONDE.md` s'ajoutent aux 99 du cahier n° 1 (399 en tout ;
  les deux dirigeables gardent leur chemin à leur nouvelle taille). Clés nouvelles : `lot` (A à G),
  genres `decal`, `anim` (`frames`, `fps` : la taille est celle d'une image, le fichier fait
  `frames ×` sa largeur) et `side` (`roof` gable avec `wall_m`, ou eaves), `soft_alpha`, `wrap`
  (x ou y), `anchor` center (ce qui vole : nuages, navires en vol, feuilles, oiseaux, papillon,
  lucioles, hélices), `solid_edge` (bord haut plein des bordures d'herbe), `pairs_with`
  (`grass_edge_b` se raccorde à `grass_edge_a`), `variant_of` (tuile `_b` → tuile d'origine, cherchée
  dans le même dossier : `ground/rock`, pas `props/rock`), `ppm` (48 : nuages, îles, île n° 53,
  `horizon_islands` ; 24 : navires en vol). Les lisières (`forest_wall_*`, `treeline_autumn_*`) se
  raccordent aussi à gauche et à droite, comme les bordures listées par le cahier.
- **H10 — cadences des bandes animées** (`fps`, notées dans le manifeste et la section 12 du
  cahier) : linge 4, fanion 10, fumée 6, brasero 10, cascade 10, oiseaux 10, feuilles 10, roseaux 3,
  herbe 4, manche à air 6, guirlande 5, cloche 6, fontaine 8, pigeon 4, papillon 12, lucioles 4,
  vapeur 8, clochette 6, hélices 12 : un mouvement d'étoffe ou de plante lent, un battement d'ailes
  ou une flamme vifs, une boucle d'une demi-seconde à une seconde et demie.
- **H10 — corrections du cahier n° 2** : (1) les hélices tournaient d'un huitième de tour par
  image : avec quatre pales identiques, 45° rend les images 3 et 4 identiques aux images 1 et 2 et
  le sens de rotation indécidable (l'œil voit aussi bien −45°) ; elles tournent d'un seizième de
  tour (22,5°, 4 pales) et d'un vingtième (18°, 5 pales) : en 4 images une pale prend la place de
  la suivante. (2) La section 3.4 demandait chaque image d'une bande « collée au bas » alors que
  les hélices (« moyeu au centre exact ») et les feuilles (« reste au centre ») sont centrées :
  exception écrite pour ce qui vole (et les nuages), clé `anchor` center. (3) Les flancs des
  maisons de 9.2 sont nommés (`<nom>_side`) dans le tableau ; les chemins des dirigeables et de
  leurs hélices (`props/`, `anim/`) sont écrits ; les densités du ciel (48 ou 96 px/m) sont dites
  pour chaque famille ; `canopy_shadow_b` et `sand_drift_b` sont marqués « alpha doux » comme
  leur famille ; `edge_roots` pend sous la lèvre (haut de l'image = lèvre) ; la clochette du café
  pend à une potence qui part du bas de l'image (l'ancre) ; la cloche de veille se balance sur
  6 images (et non « gauche, centre, droite, centre », qui en fait 4). Cahier n° 1 : lignes des
  dirigeables à leur nouvelle taille, renvoi au cahier n° 2.
- **H10 — remplaçants du cahier n° 2** : une recette par image dans `tools/hd2d_nature.py`
  (lot A), `hd2d_decals.py`, `hd2d_town.py`, `hd2d_ships.py`, `hd2d_anim.py`, `hd2d_sky.py` et
  `hd2d_ground.py` ; `gen` les refait toutes en 25 s environ, à l'octet près d'une passe à l'autre.
  Ils partent des images livrées quand ils en
  dérivent : tuiles `_b` (pourtour de la tuile livrée, intérieur pris ailleurs dans la même tuile et
  cousu par des coupes de coût minimal qui suivent les joints), prairie fleurie (herbe livrée),
  matières `_b` (matières livrées recolorées, moussues, rouillées ou tournées), flancs des neuf
  bâtiments existants (matière du volume, fenêtres découpées dans la façade livrée), bandes du
  linge, du fanion, de la manche à air, des roseaux, de l'herbe haute et de la cloche (le panneau
  livré mis en mouvement : rangées ou colonnes décalées, cloche tournée autour de son anneau).
  14,7 Mo de PNG (29,1 Mo pour tout le manifeste, budget 64).
- **H10 — dirigeables remplacés** : les deux images livrées (ballon, 48 px/m) sont remplacées par
  des remplaçants au format du cahier n° 2 (1344 × 672 et 2304 × 1056 px à 96 px/m) ; leurs scènes
  (`src/world/props/airship_*.tscn`, hors de H10) restent à `pixels_per_meter = 48` et amarrées
  au sud du quai, hors champ : elles les affichent deux fois trop grands jusqu'à la phase de pose
  (docs/CONTRACT_REQUESTS.md).
- **H10 — atlas du sol à 27 tuiles** (1536 × 2688 px, ordre du contrat) : en attendant que H9
  déduise le nombre de rangées de la taille de l'atlas, `ATLAS_ROWS` de `terrain.gdshader` passe
  de 3 à 7 et `test_hd2d_decor.gd` attend 1536 × 2688 (deux lignes hors du périmètre de H10, à
  reprendre telles que H9 les écrit à la fusion) ; les 12 premières cases n'ont pas bougé, le sol
  rend à l'identique.
- **H10 — vérifications** : `hd2d_assets.py check` (et `--lot`) vérifie toutes les règles des
  genres ; `test_hd2d_assets.gd` en reprend l'essentiel (raccords sur colonnes échantillonnées,
  limite 2 au lieu de 1,5) et compare l'atlas sans `assert_eq` sur les octets (13 s gagnées). La
  mesure de raccord reste celle du cahier n° 1 (écart des bords rapporté au plus grand écart
  intérieur) : elle attrape un bord coupé ou décalé, pas deux herbes voisines de teinte proche.
- **H10 — mesures** : export Web 32,7 Mo compressés (wasm 9,7 + pck 23,0 ; 23,7 avant H10),
  budget 60 : `export_filter = all_resources` emporte les 300 nouvelles images bien qu'aucune scène
  ne les utilise encore (vérifié dans le .pck : 45 décalques, 21 bandes, 19 flancs) ; livrées (40
  à 45 Mo de PNG prévus au lieu de 15), elles porteraient l'export vers 40 Mo compressés. Draw calls
  inchangés (`tools/hd2d_shots.sh` : cour 172, port 63, bois 56, Couchant 33, colline 51, avant
  comme après) : les nouvelles images ne sont pas encore posées.
- **Intégration de la PR n° 8 (corrections de la section 12, Codex)** : planches et JSON corrigés
  gardés ; `assets/source/section12/` (40 Mo de sources et de prompts), `docs/sprites/` (30 Mo,
  page d'aperçus) et `tools/hd2d_correction_review.py` (outil ponctuel qui l'alimente) retirés de
  l'arbre, comme les sources des livraisons précédentes : ils restent dans l'historique de `main`
  (commit `28d49f3`). La ligne de `.gitattributes` qui visait la page est retirée aussi.
- **Livraisons du cahier n° 2 par Codex (PR n° 9 à 12 : lots G, E, C, B, 140 images)** intégrées
  par-dessus les remplaçants de H10 (les images livrées prennent leur place, chemins et `.import`
  inchangés) ; atlas du sol refait (27 tuiles, dont 15 livrées). `check` signalait 41 images :
  presque toutes cadrées au plus juste, qui touchent leur bord sur 1 à 5 % de sa longueur (rien
  ne se voit en jeu). L'outil ne parle plus de coupure qu'au-delà de 12 % du bord (`CUT_COVER`),
  l'ancrage au sol reste vérifié au moindre pixel ; les lointains qui flottent (îles, rais de
  lumière) n'ont plus d'ancre au sol (`anchor: free`) ; nuages, brume et dirigeables lointains
  sont centrés par leur cadre (les hélices et les feuilles, qui tournent, par leur masse).
  Retouches sans perte : quatre dirigeables lointains et un nuage recentrés par décalage de
  pixels ; la tache d'huile, coupée au bord droit sur 14 %, effilochée sur 6 px de chaque côté.
- **Taille des sprites : hauteur debout mesurée à l'ancre** (`SheetLoader.pixel_size`). La PR
  n° 8 a redessiné Pannibal de profil avec la pointe de son épée de bois 10 px sous ses pieds :
  sa 1re image de « repos » fait 130 px pour 120 px debout, et `main` est rouge
  (`test_skin_registry` : densité 1/104 au lieu de 1/96). La taille d'un pixel est désormais
  `height_m` / hauteur du haut de l'image aux pieds (l'ancre), ce que dit `SkinData.height_m`
  (« taille debout ») ; seul le Timere change aussi (cadre de 99 px, ancre à 97 : +2 %, à sa
  taille déclarée). Tests du chargeur et du sprite mesurés à l'ancre.
- **Audit (8 octobre 2026) — caméra au chargement** : `CameraRig._ready` prenait pour point visé la
  place de player.tscn (Spawn du village) avant que game.gd ne pose le joueur à la position de la
  sauvegarde (ou au Spawn d'une nouvelle partie) : la vue glissait plus d'une seconde depuis le
  village (sonde : 5,6 m d'écart encore à l'image 30). La première `update_camera()` recale la
  caméra (`_started` remis à faux après le `snap()` du `_ready`) ; le suivi lissé commence ensuite.
- **Audit — place affichée** : avec le lissage physique, tout ce qui suit un corps à chaque image
  lit sa place affichée (`get_global_transform_interpolated`), jamais `global_position` : le
  marqueur de cible du HUD (`HUD.shown_position`) se tenait jusqu'à un pas de physique devant le
  sprite (201 px d'écart mesurés sur une cible qui avance de 2 m par pas).
- **Audit — signes déplacés puis montrés** : Godot remet le lissage à zéro à l'entrée dans l'arbre
  (les éclats et l'onde, posés après `add_child`, sont sains) mais pas quand un nœud redevient
  visible : un décalque déplacé puis montré glisse depuis son ancienne place pendant un pas de
  physique (cercle et couloir du Telegraph, trait du 2e coup d'épée qui s'écrase entre +x et −x).
  Remise à zéro (`reset_physics_interpolation`) à l'apparition seulement : rappelée à chaque pas
  (le cercle suit sa cible pendant la préparation), elle couperait le lissage ; après une remise
  à zéro, le nœud est de nouveau lissé au déplacement suivant (sonde).
- **Audit — docs/sprites** : les PNG de documentation (docs/sprites/section12, 12 Mo) ont un
  `.gdignore` comme docs/img : sans lui, chaque import les convertissait et laissait quinze
  `.import` non commités (CI rouge : « fichiers générés non commités »).
- **Audit — mesures** : scripts du jeu ≈ 0,3 ms de CPU par image en natif (banc headless, 145
  images/s : PNJ 0,06, visuels 0,05, objets à ramasser 0,14, 4 Timeres libres 0,13 ; 45 µs par
  Timere de plus, physique comprise ; 1,0 ms de moteur reste tout script éteint) : la lenteur
  Web n'est pas côté scripts. Rendu logiciel (Xvfb, llvmpipe, cour de l'entrepôt) : 6,1 images/s
  avec tout, 10,9 sans le sol (terrain.gdshader : 25 segments de chemin, 12 du ruisseau et une
  dizaine de bruits par pixel), 23,4 sans le sol ni le post-traitement. Chromium sans écran : à
  devicePixelRatio 2 le canevas passe de 1280 × 720 à 2560 × 1440 (4 × les pixels :
  `display/window/dpi/allow_hidpi`, vrai par défaut, sans gain pour du pixel art à 96 px/m) et la
  page rend 0,41 image/s contre 0,62.
- **P0 — scènes de décor du cahier n° 2** (`tools/hd2d_scenes.py`, table `tools/hd2d_scenes.json`
  lue aussi par `tests/unit/test_hd2d_scenes.gd`) : une scène `src/world/props/<nom>.tscn` par
  image des lots A à G de genre panel, anim, decal ou facade (247 nouvelles, plus les deux
  navires) ; la première catégorie dont un motif (glob sur `props/oak_*`, `decals/*`…) nomme
  l'image fixe le format et la collision, une image sans catégorie est une erreur. La racine porte
  `metadata/hd2d_category` (la catégorie) : `test_hd2d_decor.gd` laisse ces scènes à
  `test_hd2d_scenes.gd`. `gen` ne réécrit une scène qu'avec `--force` (une scène retouchée à la
  main reste) ; `check` vérifie le texte (image, script, format, collision, flancs).
- **P0 — collisions par catégorie** (largeur de l'image à 96 px/m, profondeur de la catégorie,
  forme au pied, centrée sur l'ancre) : troncs en cylindre de 3 m de haut (chênes et saule 0,4 m
  de rayon, hêtres, érables et arbres moyens 0,28, bouleaux et jeunes sapins 0,16, jeunes arbres
  0,07 sur 2 m) ; lisières : boîte de toute la largeur (16 m, elles s'enchaînent), 3 m de haut,
  1,6 m de profondeur ; rochers et blocs (blocs, cairn, tas de pierres, pilier) : cylindre de
  0,42 × la largeur (comme `rock` et `bear_rock`) sur leur hauteur ; pierres de la lèvre : boîte
  pleine largeur de 0,6 m ; objets de la vie : boîte de 0,9 × la largeur, 0,7 m de profondeur
  (1,2 m pour charrettes, filet, guichet, bûcher, table, affût, palette ; 1 m pour troncs couchés
  et souches ; 0,3 m pour les objets plats ou appuyés ; 0,8 m pour ruines et sacs de sable,
  comme `ruined_wall`) ; clôtures en modules : boîte pleine largeur de 0,15 m ; poteaux,
  trépieds, mannequin : cylindre de 0,15 m ; lampadaires 0,12 ; mâts 0,08 ; linge : deux
  poteaux comme `laundry_line` ; étals : le comptoir de `market_stall` ; fontaine : cylindre de
  0,45 × la largeur sur 1 m ; pylône d'ancrage : boîte de la moitié de la largeur, 1,5 m.
  On traverse : plantes, fleurs, herbes, champignons, cailloux, petits objets (image de 0,6 m de
  haut au plus, 58 px : jouets, seau, arrosoir, pots, panier, sac, cordage, chaînes, pigeon), bancs
  (comme `bench`), marches de pierre (on marche dessus), guirlande, cloche animée (l'arène porte
  la collision du poteau), flammes et vapeur, premier plan, détails de mur et de toit, décalques,
  ciel, navires (au bord du vide).
- **P0 — formats** : bande animée = `frames` et `fps` du manifeste ; densité `ppm` du manifeste
  (nuages, îles et île n° 53 à 48, navires en vol à 24) ; ce que le manifeste ancre au centre
  (nuages, navires en vol, brume) a son origine au centre de l'image (`image_offset`), ce qui pend
  sous la lèvre (`edge_roots`, `edge_waterfall`) au bord haut ; ciel, détails, plantes basses,
  premier plan des fougères et herbes sans ombre ; troncs de premier plan avec une petite ombre
  (0,5) ; lampes et caisses de cristaux avec la lueur de `crystal_lamp` (1,6). Décalage vers la
  caméra : 0,1 m sur un toit (cheminée, lucarne, terrasse à linge, fumée), 0,06 m contre un mur
  (lierre, jardinière, applique, enseignes, gouttière, auvent, clochette), 0,05 m sur un brasero
  ou un four, 0,1 m pour l'escalier extérieur (boîte d'1 m devant le mur). Décalques : couche 0
  pour les plaques (mousse, flaques, craie, ornières…), 1 pour ce qui traîne dessus (feuilles,
  branches, cailloux, racines, aiguilles, foin), 2 ombre de feuillage, 3 taches de soleil,
  4 brume.
- **P0 — maisons de la section 9.2** : type, mur, faîte, profondeur et matières écrits dans la table
  (clé `buildings`), largeur de la façade ; l'outil refuse une maison dont la façade ou le flanc
  n'a pas la taille de ces cotes (`side_contract_size()` égale le flanc à 1 cm près pour les
  19 bâtiments). Collision : l'emprise sur la hauteur du mur. Bâtiments du cahier n° 1 : une ligne
  `side_facade` et son `ext_resource` (`5_side`), rien d'autre.
- **P0 — navires à quai** : 96 px/m (14 × 7 m et 24 × 11 m) ; moyeux mesurés dans les images
  livrées au bout de l'axe (là où l'hélice se fixe, pas au centre de la bride, que la coque
  dessine de trois quarts) : passeur (825, 497) px, Barocupot (768, 670) et (1627, 678) px ;
  chaque hélice (DecorPanel animé, 4 images à 12 images/s, sans ombre, `depth_offset` 0,1 pour
  passer devant la coque) a son image centrée sur son moyeu, donc son ancre une demi-image plus
  bas. Pour la pose : la proue est à droite (est) ; un navire tourné vers l'ouest demande
  `flip_h` sur la coque et ses hélices et l'abscisse des hélices opposée (rien ne le fait seul).
- **P0 — ce qui pend sous la lèvre** (`edge_roots`, `edge_waterfall`, `floating_rock_*`) : la
  caméra du jeu (11 m au-dessus et 18 m au sud du point visé) ne voit un point h m sous la lèvre
  que s'il est à plus de 1,6 × h m au-delà du bord (point visé sur la lèvre ; plus loin quand le
  joueur s'en écarte) : 3 m pour le bas des racines, 10 m pour le bas d'une cascade de 6 m. La
  démo les pose 9 m au-delà, vus par une caméra plus basse.
- **P0 — démo** (`tests/integration/demo_props_monde.tscn`, vues `P0_VIEW`) : l'île sans ses
  zones, chaque famille posée sur un lieu à part (bois, cour, bourg, maisons du port, port,
  Couchant, ciel), décors fondus par image dans un `PropBatcher` (cases de 32 m) comme une zone ;
  draw calls : bois 70, cour 43, bourg 103, maisons 124, port 175 (une centaine d'images
  différentes à l'écran), Couchant 39, ciel 31.
- **P0 — budget d'images par zone** (`test_hd2d_decor.gd`, `MAX_IMAGES_PER_ZONE`) : 40 → 48, le
  port en a 44 avec les flancs de ses six bâtiments et les hélices des deux navires ; la pose du
  cahier n° 2 le dépassera (le vrai budget est le nombre de draw calls des vues).
- **Alpha doux des panneaux debout** (`DecorPanel.soft_alpha`, `panel_soft.gdshader`, demande
  de P0) : les panneaux découpaient leur transparence à 0,5 ; fumée, vapeur, cascade et nuages
  perdaient leur dégradé, rais de lumière (15 à 35 % d'opacité) et bande de brume disparaissaient.
  Mélange alpha, sans écriture de profondeur, matériau partagé par image (le batcher les fond
  toujours) ; le premier plan garde sa trame. `tools/hd2d_scenes.py` écrit `soft_alpha` d'après
  le manifeste et le vérifie : 11 scènes régénérées.
- **Intégration de l'audit** : `docs/sprites/` n'est plus dans l'arbre (retiré à l'intégration
  de la PR n° 8) : son `.gdignore` part aussi. Pannibal : la proposition de l'audit (redessiner le
  profil à 120 px) n'est pas retenue, la taille se mesure désormais à l'ancre (« Taille des
  sprites », plus haut) et le profil, 120 px debout, est à l'échelle.
- **Audit, proposition retenue : les Timeres ne chassent pas un joueur en conversation**
  (`Enemy._player_talking`, par `EventBus.dialogue_started` → `dialogue_ended`) : une mort en
  pleine réplique le faisait réapparaître au village figé, la boîte encore ouverte. Plutôt que de
  couper le dialogue à la mort (une étape « parler » interrompue serait validée).
- **Audit, proposition retenue : Web sans haute densité** (`display/window/dpi/allow_hidpi.web =
  false`, PR « contrats ») : sur un écran Retina ou à 150 %, le canevas était rendu à
  devicePixelRatio × la fenêtre (4 × les pixels à DPR 2), sans gain pour du pixel art à 96 px/m.
  Seulement pour le Web : sur le bureau, une application qui n'est pas « DPI-aware » est agrandie
  floue par Windows.
- **Livraison du lot D (Codex, PR n° 15 : 53 images de bâtiments et de matières)** intégrée
  par-dessus les remplaçants. `check` : quatre flancs en pignon (entrepôt, café, salle de
  projection, remise) dessinent l'avancée du toit plus bas que le haut du mur aux angles (21 à
  22 % de sa hauteur) ; le mur du volume, derrière, complète ce coin : l'outil tolère 25 %.
  L'enseigne en hélice, à 1 px du bas, y est collée (décalage sans perte).
- **Livraisons A, D, F et corrections du ciel (G) fusionnées à la main sur `main`** (PR n° 15 à
  18) ; l'intégration de la pose (scènes de P0, alpha doux) les reprend telles quelles (les images
  de `main` font foi, y compris les cadrages du lot D que Codex a corrigés lui-même). Guirlande
  de fanions et clochette du café : objets suspendus, accrochés par le haut, sans ancre au sol
  (`anchor: free`). 399 images, 21 planches, 249 scènes : rien à reprendre.
- **Budget Web relevé de 60 à 100 Mo compressés** (même choix de l'utilisateur : la qualité avant
  le poids ; l'application de bureau devient la version principale). Toutes les images du cahier
  n° 2 livrées (lots A à G) : 74,8 Mo de PNG, export Web de 73,5 Mo compressés (wasm 9,7 Mo,
  pck 63,8 Mo), 250 Mo de textures décompressées. `tools/build_size.sh`, `tools/check.sh`, l'étape
  de la CI, `PLAN.md`, `docs/web.md` passent à 100 Mo, le budget des images du manifeste
  (`test_hd2d_assets.gd`) à 100 Mo de PNG. Si le premier chargement Web devient trop long, une
  version Web allégée (images importées en WebP avec perte pour le seul préréglage Web) reste
  possible sans toucher au bureau.
- **Bureau (D1, PR « contrats ») — préréglages** : « Windows Desktop » (préréglage 1 : x86_64,
  pck intégré à l'exe, S3TC/BPTC, sans console ni signature) et « Linux » (préréglage 2, même
  filtre : pour lancer le même jeu ici, sans écran) à côté du « Web », qui reste le préréglage 0,
  le seul de sa plateforme, celui de `tools/check.sh` et du déploiement. Même rendu
  (Compatibility) : ANGLE, son repli Direct3D 11 sous Windows, est dans le template officiel
  (aucune DLL exportée à côté de l'exe).
- **Bureau — pas de rcedit** : Godot 4.7 écrit lui-même l'icône et les métadonnées dans l'exe
  (`application/modify_resources=true`, sans rcedit ni wine, aucun avertissement à l'export) ;
  vérifié par `7z l` : `.rsrc/version.txt` (0.3.0.0, WordEnd, Yume Novel) et six icônes. L'icône
  `tools/installer/wordend.ico` (16 à 256 px, celles qu'exige l'export) sert aussi aux raccourcis
  de l'installateur.
- **Bureau — version** : `application/config/version` de project.godot (0.3.0 : l'acte 1 en
  HD-2D) est la seule source : Godot la met dans l'exe (`file_version` et `product_version`
  vides), `tools/build_desktop.sh` dans l'installateur et les noms de fichiers. Un tag `vX.Y.Z`
  fait foi pour sa Release : la tâche `bureau` l'écrit dans sa copie de project.godot s'il
  diffère (avertissement), pour que publier se résume à créer le tag depuis GitHub.
- **Bureau — dossier utilisateur** : `use_custom_user_dir=true`, `custom_user_dir_name="WordEnd"`
  (`%APPDATA%\WordEnd`, `~/.local/share/WordEnd`) et `use_custom_user_dir.web=false` : le Web
  garde `/userfs/godot/app_userdata/WordEnd` et ses parties (vérifié dans Chromium). Effet de
  bord sans conséquence : sous `tools/godot`, user:// passe de
  `build/xdg/data/godot/app_userdata/WordEnd` à `build/xdg/data/WordEnd`.
- **Bureau — autoload `DesktopApp`** (dernier des autoloads, sans class_name) plutôt que du code
  dans main.gd ou les menus : fenêtre de départ à 80 % de l'écran en 16:9 (640 × 360 au moins,
  seulement dans le jeu exporté avec un écran), plein écran « fenêtre sans bordure »
  (`WINDOW_MODE_FULLSCREEN`, pas l'exclusif) par F11, Alt+Entrée (signal `window_input` de la
  fenêtre, avant toute scène) ou le bouton des menus, mémorisé dans `user://settings.cfg`, hors de
  la sauvegarde. « Quitter » (menu principal) et « Quitter le jeu » (menu pause) écrivent la
  partie suivie (`SaveManager.save()`, `close_game(false)`) puis ferment ; textes dans la section
  `desktop` de `data/texts/story.json`. Sur le Web : boutons cachés, raccourcis ignorés, aucun
  fichier. Limite acceptée : Alt+Entrée pendant une conversation fait aussi avancer la réplique
  (`dialogue_box.gd` lit `ui_accept` dans `_input`, avant les autoloads).
- **Bureau — contrôles tactiles** : hors Web, `TouchControls.is_touch_device()` ne suppose plus
  d'écran tactile au démarrage (un portable tactile les verrait sinon par-dessus le jeu au
  clavier) ; le mode AUTO les montre au premier toucher, comme avant.
- **Bureau — vérification du jeu exporté** : un jeu exporté ignore `--script` ; la vérification
  voyage donc dans le pck (`src/desktop_check.gd`), créée par DesktopApp seulement avec
  l'argument utilisateur `--desktop-check=<phase>`, comme les raccourcis de test
  (`src/test_shortcuts.gd`). `tools/desktop_boot.sh` lance le build Linux sans écran (ou sous
  Xvfb avec openbox, sans quoi X11 n'a pas de vrai plein écran) : menu, F11, Alt+Entrée,
  nouvelle partie, pause, « Quitter le jeu », puis reprise.
- **Bureau — installateur** : NSIS 3 (`makensis` existe sous Linux, l'image de la CI est une
  Ubuntu 24.04), installateur 64 bits (le jeu est x86_64) en LZMA solide, par utilisateur
  (`RequestExecutionLevel user`, `%LOCALAPPDATA%\Programs\WordEnd`, clés sous HKCU), en
  français ; le désinstalleur garde les sauvegardes par défaut (« Oui », et en mode silencieux).
  Avertissements de makensis = erreurs (`-WX`). Bandeau des pages d'accueil et de fin découpé
  dans l'écran de démarrage (`make_installer_art.py`) ; `tools/installer/.gdignore` évite que
  Godot importe le BMP.
- **Bureau — CI** : tâche `bureau` (PR, `main`, tags `v*`) dans le même conteneur
  `barichello/godot-ci:4.7.2`, qui contient déjà tous les templates (Windows et Linux compris,
  Dockerfile lu) ; NSIS installé par apt ; artefact `bureau` gardé 7 jours, sans recompression.
  Tâche `release` (tag `v*`, ou « Run workflow » avec `release` coché) après `check` et
  `bureau`, seule à avoir `contents: write`, par `softprops/action-gh-release@v2` (texte ajouté
  à celui d'une Release écrite depuis GitHub). Le check et le déploiement Pages ne changent pas.
- **Bureau — wine** : l'installateur a été vérifié sous wine 9.0 (installation et
  désinstallation silencieuses, raccourcis, clé d'« Applications et fonctionnalités », page
  d'accueil) ; le jeu, lui, plante sous ce wine dès le lancement (`kernelbase`, après
  `dinput8`), template officiel nu compris : il n'a pas été lancé sur un vrai Windows.
- **Souris en jeu** (recette du 8 octobre 2026 : « les clics droit et gauche ne font rien »).
  Clic gauche : coup d'épée ; clic droit maintenu : charge magique. Le joueur se tourne d'abord
  vers le point du sol sous le pointeur, même en marchant, sauf avec une cible verrouillée.
  Les clics ne passent pas par l'input map : `Player._unhandled_input` ne reçoit que ceux que
  l'interface n'a pas pris (un clic sur « Reprendre » ne frappe pas à la reprise) et ignore la
  souris émulée par le tactile ; il les envoie en `InputEventAction`, comme les boutons
  tactiles. Un bouton relâché pendant la pause relâche son action à la reprise. Le rappel des
  commandes de la pause n'annonce plus de « caméra à la souris » (vestige de la caméra 3D :
  la caméra HD-2D est fixe) ; le stick droit y est donné pour le zoom.
- **P3 — navires à quai** : la caméra se tient 15 m au sud du joueur et regarde le nord ; un
  navire au-delà du bord sud du quai n'entre dans le champ que par le bas de l'écran, et un navire
  plus au nord serait sur l'île. Les deux navires flottent donc juste au-delà du bord (0,3 à 0,9 m),
  le pont à hauteur du quai (comme un bateau à quai) : on les voit en entier en longeant le
  garde-corps, leur superstructure depuis le milieu du quai. Le Barocupot, proue à l'ouest
  (`airship_barocupot_beach.tscn` : `flip_h` sur la coque et les hélices, abscisses opposées),
  à l'ouest du quai contre son pylône (`mooring_tower`, près de Limeskin), pont 1,6 m au-dessus du
  quai ; le navire du passeur, proue à l'est (`airship_ferry_beach.tscn`), au bout d'une passerelle
  raccourcie à 6,3 m (`gangway_beach.tscn`, tête à 1 m du passeur, inchangé). Les deux scènes sont
  en premier plan (`foreground`) : la coque s'efface autour du joueur quand elle passe devant lui.
- **P3 — rue d'un seul tenant « de chaque côté »** : rang nord jointif (joints ≤ 0,1 m, façades à
  z = −9,5, le café à −9) d'ouest en est : auberge, horloger, café, maison étroite, boulangerie,
  le chemin de l'entrepôt, librairie, salle de projection, maisons à colombages b, Limashenka,
  colombages a ; café et boulangerie glissés de 0,9 m vers l'ouest (le serveur et le boulanger
  restent devant leur porte), la maison de pierre et celle du deuxième rang retirées. Une maison
  bâtie au sud de la rue cacherait le joueur qui y marche : le côté sud est fait des maisons du
  port (bureau du port, chaudronnerie, boucherie, maison de pierre b, hangar), façades sur le bord
  nord du quai, assez loin pour que leurs toits restent sous le joueur à l'écran (le haut d'un
  toit doit être à plus de 1,29 × sa hauteur au sud du joueur) : depuis la rue, leurs toits et
  leurs jardins bordent le bas de l'écran ; depuis le quai, leurs façades ferment la vue.
- **P3 — jardins et arrière-cours clos** : derrière un bâtiment (au nord de lui), le joueur est
  caché par son toit. Les jardins des maisons du port (clôture basse au bord de la rue, z = −3,6,
  clôtures de profil aux bouts, barils entre les maisons) et les arrière-cours du rang nord
  (clôture à z = −25 ; le chemin de l'entrepôt passe entre deux clôtures de profil,
  `keep_orientation`) sont clos ; `test_zone_beach.gd` vérifie qu'aucun mur ni toit ne passe
  devant le joueur où qu'il marche dans le bourg et sur le quai.
- **P3 — détails accordés aux façades livrées** : les façades du cahier n° 2 dessinent déjà
  enseignes, jardinières, lierre, appliques et certaines cheminées ; la pose ajoute la fumée sur
  ces cheminées dessinées (maison étroite, colombages a, maison de pierre b, chaudronnerie), la
  vapeur sur le four dessiné, la clochette du café, des gouttières, des cheminées et lucarnes sur
  les toits (briques sur les tuiles, pierre sur l'ardoise et les bardeaux), du lierre sur un flanc.
- **P3 — étals et lampadaires** : chaque marchand se tient devant (au sud de) son étal : l'étal des
  œufs et le snack passent au nord de leur vendeur, qu'ils cachaient ; les étals restent à plus de
  3 m au sud de la rue. Les lampadaires de la rue sont côté nord (au sud, ils passaient devant le
  joueur) ; guirlandes tendues entre deux maisons, devant les façades. La terrasse du café met une
  table sur chacun des trois pieds de la collision du café (le pied du milieu était invisible).
- **P3 — budget d'images** : 140 matériaux par zone (`test_hd2d_decor.gd`) : 132 au port. Les
  variantes s'en tiennent aux images les plus utiles (feuillus et sapin du cahier n° 1, buissons b
  et c, une lucarne, un lierre) ; une pose plus riche demandera de relever ce plafond (le vrai
  budget, ≤ 200 draw calls par vue, laisse de la marge : 70 à 110 mesurés).
- **P3 — premier plan sur les grands décors de passage** : fontaine, étals, snack, panneaux
  d'affichage, grue, pylône d'ancrage, guichet, tuyaux de vapeur, hélice de rechange et manche à
  air ont `foreground = true` sur leur instance dans `beach.tscn` (scènes partagées inchangées) :
  ils s'effacent en trame autour du joueur qui passe derrière eux ; chaque image reste un seul
  matériau (toutes ses instances au port sont au premier plan).
- **P3 — loin du bord qui va changer** (le bord de l'île deviendra irrégulier, le quai restera
  droit) : hors du quai, aucun décor bloquant à moins de 3 m du bord actuel ni aucun autre à moins
  de 1 m (vérifié par `test_zone_beach.gd`), et rien dans les 4 derniers mètres : l'habillage de la
  lèvre au-delà des bouts du quai est retiré, quelques rochers, touffes et un arbre reculent ; les
  deux navires restent devant le quai (le Barocupot recentré sur sa moitié ouest, x de −32 à −8).
- **P1 — pose des bois du marais** (`src/world/zones/forest/forest.tscn`) : environ 1 100 décors
  en une quarantaine de familles, chacune une `PropScatter` (variantes, retournement, échelles 0,85
  à 1,15) dont chaque image n'appartient qu'à elle : le tirage des variantes (jamais celle du plus
  proche voisin) suffit à ce que deux voisins n'aient jamais la même image (seuls le cercle de
  champignons et le caillebotis répètent une image, par nature). Points tirés par un script de
  travail hors du dépôt, selon des règles écrites dans `tests/unit/test_forest_decor.gd` et
  `test_world_story_spots.gd` : rien de bloquant à moins de 1 m des places de l'acte 1 ni dans le
  cercle d'entraînement (buts et râtelier de H4 gardés ; mannequins et cibles au bord, à 16 m),
  chemins libres sur 3 m, aucun grand décor qui cache à l'écran un chemin, le ruisseau, une place
  ou un repère (rocher aux ours, affût, cercle de champignons, cascade, gués, mannequins), arbres
  à 4,6 m les uns des autres au moins, grands arbres posés avant les jeunes sapins et bouleaux.
- **P1 — un mesh par image dans les bois** (`PropBatcher.cell_size` 32 → 0) : le terrain
  d'entraînement est au coin de quatre cases quelle que soit leur taille ; avec ~110 images, ses
  vues dessinaient chaque image jusqu'à quatre fois. En une seule case, chaque vue des bois coûte au
  plus une fois chaque image (mesures, 21 vues : 55 à 131 draw calls ; 27 à 65 avant). Pour que les vues
  des zones voisines ne dessinent pas tout, chaque famille a une classe d'emprise qui borne sa boîte
  englobante (bande sud des bois, vue de la cour : fougères, herbes, bouleaux, premier plan,
  myosotis, bordures ; sud-est, vu de la colline : en plus hêtres, érables, jeunes sapins, feuilles,
  gués) ; mesuré (hd2d_shots.sh) : cour 59 → 79, entrepôt 78 → 87, dialogue 64 → 82,
  colline 52 → 78, Couchant 34 → 34 draw calls.
- **P1 — arbres des bois en premier plan** : chaque arbre posé dans les bois est une variante
  `src/world/props/<arbre>_forest.tscn` (scène héritée, `foreground = true`) : quand le joueur passe
  derrière, l'arbre s'efface en trame autour de lui (on marche partout dans les bois). Chaque image
  n'existe que sous cette forme dans la zone : pas de draw call de plus.
- **P1 — lisières** : sept pans (`forest_wall_a..d`, d au-dessus du marais) jointifs (1 m de
  recouvrement) le long du bord nord, tournés pour suivre sa courbe (`keep_orientation`, lacet de la
  corde, moins de 40°), à 4,8 m de la lèvre : leur collision reste à 4 m du bord, que le lot B1 rend
  irrégulier (criques de 4 m au plus là où rien n'est posé ; consigne : aucun décor à moins de 1 m
  du bord, aucune collision à moins de 3 m, rien dans les 4 derniers mètres si possible). On peut
  donc passer derrière : ce sont des variantes de premier plan (`forest_wall_*_forest.tscn`), qui
  s'effacent autour du joueur. Deux fenêtres sur le vide, aux angles où le bord tourne trop pour un
  pan de 16 m : au nord-ouest (sortie du ruisseau) et au nord-est ; elles restent nues (pierres et
  herbe de la lèvre, racines, cascade : à poser sur le nouveau bord, docs/CONTRACT_REQUESTS.md).
  Les côtés ouest et est sont fermés par des bois serrés, arrêtés à 4 m du bord.
- **P1 — premier plan** (`fg_trunk_*`, `fg_fern`, `fg_bush`, `fg_grass`) seulement contre la
  palissade de la cour (z local ≥ 25) : au milieu des bois, un tronc de 10 m à 4 m de la caméra
  couvrait le tiers de l'écran.
- **P1 — cercle de champignons** déplacé de (20, −1) à (16,8 ; 1,4) : le ruisseau le traversait.
- **P1 — petites vies** : feuilles or et rouille, papillons autour du terrain, lucioles au marais,
  dans un nœud `Ambient` de la zone, hors de `Geometry` (le PropBatcher ne fond pas leur mesh, et
  `test_hd2d_decor.gd` refuse un mesh non fondu dans `Geometry`) ; régions bornées pour que la cour
  ne les dessine pas.
- **Premier plan : un seul `_process` pour tous les panneaux** (remarque du lot P1 : 175 panneaux
  de premier plan dans les bois, plusieurs centaines dans l'île posée, chacun appelé à chaque
  image pour un travail fait une seule fois). Les panneaux de premier plan s'inscrivent dans
  une liste statique de `DecorPanel` ; seul le premier a un `_process` et pose le centre de
  l'effacement pour tous ; quand il quitte l'arbre, le suivant prend le relais. Même rendu.
- **P2 — pose de la cour de l'entrepôt** (cahier n° 2, section 14) : 386 décors et 105 images au
  lieu de 181 et 24 (82 modules de palissade inchangés). Entrepôt : cheminée de briques
  (`warehouse_chimney.tscn` passe en `wall_brick`, au bout est du faîtage) et sa fumée, terrasse
  à linge, deux lucarnes, lierre, gouttière, deux appliques, trois jardinières, provisions et pots
  au porche. Cour : 31 bordures d'herbe (chemins et place), marelle et craie près de l'aire de
  jeux, fissures, gravier, mousse, feuilles, flaques et boue à l'aire de jeux, pas de petites
  bottes (dont une trace de la place au porche de Nygglatho, faute de chemin au sol) ; potager vu
  de dessus (`garden_bed` sur la terre du potager, un rang de tuteurs derrière), clôture basse
  devant et derrière, épouvantail, outils, brouette, tonneau, arrosoir ; linge animé
  (`laundry_wave`) et flaque sous les draps, panier, bûcher et billot, jouets, table d'enfants,
  seau ; ombre et feuilles sous le grand arbre ; feuillus en variantes (chêne, hêtre, bouleau,
  érable, jeunes arbres), buissons, herbes et fleurs tirés par `PropScatter.variants` et
  `random_flip` ; feuilles qui tombent, oiseaux, papillons au potager (`Ambience`, quatre
  `AmbientSprites`, un draw call chacun).
- **P2 — le toit hors champ** : la caméra fixe (tangage 32°, 17° sous l'horizon en haut de
  l'écran) ne montre ce qui dépasse 6 m que s'il est au sud du joueur : cheminée, fumée, terrasse
  et lucarnes ne se voient qu'en sortant par le portail nord (vue d'ensemble aussi). Posées quand
  même (MONDE.md 2.2), elles ne coûtent un draw call que dans le champ.
- **P2 — lisière nord, toile de fond** : `treeline_autumn_*` derrière la palissade nord (z −22,7,
  quatre pans de 16 m, ouverts au portail), en variantes sans collision
  (`treeline_autumn_*_village.tscn` : la palissade ferme déjà la cour, et 64 m de mur couperaient
  le passage entre les bois et les zones voisines). Un panneau regarde toujours le sud : au sud
  du village une lisière serait entre la caméra et le joueur, à l'est et à l'ouest elle entrerait
  dans les zones voisines ; là, des arbres en variantes le long de la palissade. Quand le joueur
  sort par le nord, la lisière et les arbres du bord nord passent entre la caméra et lui et
  cacheraient 15 m de bois : la découpe du village (`see_through.gd`, `backdrop_textures`)
  efface en trame ces toiles de fond au-delà de la palissade, sur 1,2 m, dès qu'elles sont au sud
  du joueur (images réservées au bord nord, vérifié par `test_village_decor.gd`).
- **P2 — découpe et formats** : seuls les matériaux de `panel.gdshader` reçoivent la découpe ;
  décalques, premier plan et alpha doux gardent leur shader (demande H9 réglée). Dans
  `test_village_decor.gd`, l'occlusion des PNJ ignore décalques et alpha doux, compte le premier
  plan, prend la plus forte opacité des images d'une bande animée, et range les triangles par
  cases de 4 m (le test reste à 4 s).
- **P2 — sud dégagé** : les trois grands arbres du sud de la cour (sapin, rouille, jaune autour
  du portail sud) cachaient la moitié de l'écran quand on longe la palissade sud ; buissons et
  premier plan (`fg_bush`, `fg_grass`, qui s'effacent autour du joueur) les remplacent, les coins
  gardent un arbre.
- **P2 — mesures** (`tools/hd2d_shots.sh`, draw calls avant → après) : cour (vue `village`)
  59 → 110, entrepôt 78 → 120, conversation 64 → 111 ; vues de la pose (`build/shots/p2_*`) :
  sous 135 partout. `test_village_pose.gd` compte les meshes fondus du village dans le champ de
  dix places (sous 140) : densité 29 à 55 décors à moins de 12 m du joueur, aucun voisin à moins
  de 2 m de la même image, aucun trou de 4 m sans décor, couloir de 3 m sur les quatre chemins,
  rien de bloquant à moins de 1 m des PNJ et du myosotis.
- **B1 — un bord d'île irrégulier** (demande de l'utilisateur : « une map carrée ne fait pas très
  réaliste », des irrégularités sauf au port) : la forme du bord quitte terrain.gd pour
  `IslandEdge` (`src/world/island_edge.gd`, terrain.gd dépassait les 1 000 lignes) : un rayon par
  angle (forme étoilée), cuit une fois dans une table de 2 048 rayons et pentes ; le shader du sol
  lit la même table en texture RGF (texelFetch, interpolation refaite à la main, aucune formule
  propre au shader). Le tracé d'origine (superellipse, quai, Couchant) reste la base : la côte
  n'avance qu'au-dehors (minimum adouci), sauf dans deux anses où rien n'était posé à 6 m (sud-est,
  sud du Couchant ; 2,2 m au plus). Grandes avancées décidées à la main (`CAPES` : éperon de 10 m
  au nord-est tourné vers le nord-nord-est, caps de 5 à 7 m autour de la cascade, au sud-ouest, au
  sud-est et au sortir du port), pas sur les diagonales : des caps sur les diagonales remplissaient
  les coins du carré des murs, l'île en devenait plus carrée. Ondulations moyennes (1 à 3 m sur 6
  à 14 m) menées par un bruit de Fourier et une onde à fréquence modulée (le bruit seul laissait des
  tronçons calmes de 20 m), ramenées entre un fond (0,6 m) et la place laissée par les murs (bord à
  ±79,2 m au plus, 0,9 m de marge avant d'adoucir) pour ne jamais aplatir un cap contre un mur ;
  ébréchures anguleuses (ligne brisée de 1,5 à 3,5 m, ±0,45 m) et bruit fin. Mesuré : tronçon de
  20 m le plus droit hors du quai à 0,65 m de sa corde ; périmètre 525 → 584 m.
- **B1 — distance au bord** : `edge_distance()` divise l'écart radial par la pente de la côte
  (première approximation de la distance vraie, juste sur les flancs des caps) ; la distance
  exacte au tracé (`IslandTerrain.distance_to_edge`) sert aux marges. `edge_radius()` est
  désormais un rayon euclidien (il était en norme 4).
- **B1 — relief** : il s'efface toujours vers le tracé d'origine (mêmes hauteurs qu'avant dans
  toutes les zones ; les avancées de la côte sont plates, à y = 0) et vers la côte lissée (les
  anses). Le refaire vers le nouveau bord gonflait les dunes du Couchant (pente de 45°).
- **B1 — cascade** : `Island/Waterfall` tombait 5 m à l'est de la sortie du ruisseau (angle −2,3) :
  elle tombe désormais au point où le lit coupe le tracé d'origine (−2,3532 rad, (−62,0 ; −62,4)),
  au fond d'une ravine (caps de part et d'autre, pas d'ébréchure sur le mètre où l'eau passe) ; le
  lit du ruisseau (`STREAM`) ne change pas et traverse la lèvre de pierre. Le haut du ruban
  affleure sous la lèvre, à 5 cm au-delà du bord (à 0,6 m en deçà et 2 cm au-dessus du sol, il
  traçait un trait clair en travers du lit dans la vue du jeu).
- **B1 — roche** : la lèvre et le premier anneau suivent le bord exact du sol (`rim_loop()`, une
  boucle ordonnée depuis le nord) ; les anneaux plus bas suivent la côte de moins en moins
  ébréchée (384, 256, 192, 192 puis 128 points), raccordés d'un anneau à l'autre par angle
  croissant ; leurs variations viennent d'un bruit lisse le long du tour (128 cases), le même quel
  que soit le nombre de points. UV.x = longueur de bord depuis le nord, `IslandRock.uv_turn()` =
  périmètre arrondi à un nombre entier de textures de 4 m (584 m) ; étirement le long de la lèvre
  ≤ 4 %. Triangles : sol 11 576 → 12 258, roche 3 964 → 6 048 (un draw call chacun) ; vues de
  `tools/hd2d_shots.sh` : mêmes draw calls (village 59, entrepôt 78, bois 65, Couchant 34, port 44,
  colline 52, dialogue 64, veille 50 → 51 ; menu 43 → 46 à cause du bouton Continuer, une partie
  étant enregistrée dans le `user://` du worktree), 2 800 primitives de plus par vue (≈ 16 400 →
  19 200).
- **B1 — lèvre de pierre du sol** : bande de 0,2 à 1,4 m (dalles qui affleurent par plaques,
  herbe ou sous-bois jusqu'au bord ailleurs) au lieu d'un ruban régulier de 0,9 m qui faisait
  bordure pavée ; le ruisseau la traverse.
- **B1 — marges au vide** (`tests/unit/test_world_edge_margins.gd`, island.tscn complète) : ancre
  d'un décor à 1 m, collision d'un décor, PNJ, objet, Timere, point d'apparition et centre d'un
  déclencheur à 3 m, disque d'un déclencheur à 1 m. Mobilier du bord exempté par préfixe de scène
  (`edge_`, `airship_`, `gangway`, `mooring_`, `bollard`, `floating_rock`, `distant_island`). La
  ruine du poste de guet du Couchant (collision à 1,5 m du vide avant B1) a un replat devant elle
  (`LEDGES`, +1,6 m) ; `couchant_edge` reste près du bord (disque à 1,9 m, centre à 4,9 m).
  `EDGE_MARGIN` des places de l'acte 1 reste 3 m (HISTOIRE.md ; 6 m exclurait le passeur, au bout
  de sa passerelle, et `couchant_edge`, « au bord ») ; il se mesure à la distance exacte.
- **Marges au bord sur le quai** (fusion de B1 avec la pose du port) : le quai est un ouvrage
  bordé d'une rambarde, son tracé n'a pas changé. Caisses, filets, tuyaux et flaques y vont
  près du bord : dans le secteur du port (`IslandEdge.PORT_SECTOR`), `test_world_edge_margins`
  demande 0,3 m pour l'ancre d'un décor et 1,5 m pour une collision (au lieu de 1 et 3 m sur la
  côte naturelle). Une caisse de la Garde a reculé de 0,6 m.
- **Refonte de l'île n° 68** (`docs/REFONTE.md`, 9 octobre 2026), à la suite de la recette « monde
  vide, infidèle, quêtes superflues, Timeres sur les îles, personnages statiques, aucun intérieur,
  dirigeables plats ». Relecture intégrale des six volumes (`docs/lore/canon/`, qui priment sur la
  bible quand ils la contredisent). Choix de l'utilisateur, tous selon la recommandation :
  - une carte par lieu, façon *Octopath Traveler*, avec intérieurs et carte de l'île (contrat :
    `docs/REFONTE.md`, section 7.1) ;
  - à l'acte 1, aucun Timere : entraînement, duels et faune de la forêt profonde et de la
    montagne ; Timere et l'arène à vagues passent à l'acte 2 (île n° 15) ;
  - l'acte 1 suit le volume 1 et l'épisode du volume EX en une douzaine de jours et de scènes ;
    les quêtes secondaires, les marqueurs au-dessus des têtes et l'encadré d'objectif permanent
    disparaissent ; le calendrier de Chtholly sert de journal ;
  - première tranche : l'entrepôt (dehors, dedans, vie des petites, jours 1 à 4).
  La « saison des rejetons » et la « veille du Couchant » (`MONDE.md`, section 1.1) sont retirées :
  c'étaient des inventions qui contredisent l'œuvre.
- **E2 — format du sol en relief** (`data/maps/<map_id>/`, PLAN.md section 4) : trois images de
  pixels purs et `map.json`. Paliers : gris de 16 en 16 (0,5 m chacun ; lisible à l'œil, 15
  paliers par défaut, `height_step_value` et `height_zero_value` pour plus), transparent = le vide.
  Matières : une bibliothèque commune (`data/maps/ground_materials.json`, une couleur de peinture
  par matière), la palette de `map.json` dit lesquelles la carte emploie ; `materials_scale` (1, 2 ou
  4 pixels par mètre) pour peindre plus fin. Escaliers, rampes et style des faces dans
  `structures.png`. `plan.json` (rectangles, polygones, ellipses, chemins, paliers, volées) n'est lu
  que par `tools/map_build.py gen`.
- **E2 — escaliers praticables** : la capsule du joueur (rayon 0,35 m, sol à 45° au plus) monte
  sans sauter une marche de moins de 0,1025 m (mesuré : 0,10 m passe, 0,11 m arrête). Les marches
  sont donc réelles, de **0,1 m** (5 par palier, giron de 0,2 m pour une case par palier), et la
  collision est faite d'elles (pas de rampe cachée sous l'escalier). Pente d'une volée 40° au plus.
- **E2 — marches de 0,5 m** : se sautent (le joueur saute 1 m), les PNJ ne les passeront pas ; plus
  haut, c'est une falaise. La règle « aucune marche de plus de 0,5 m sans escalier » vise les
  chemins : deux cases de chemin voisines de plus d'un palier d'écart sont une erreur ; une falaise
  hors des chemins est voulue. `map_build.py check` avertit des cases praticables hors d'atteinte du
  départ et de celles qu'on n'atteint qu'en sautant.
- **E2 — faces** : talus de terre jusqu'à 0,5 m, roche au-delà, muret si `structures.png` le dit ;
  joues d'escalier en muret, de rampe en talus. Les faces tournées vers le nord (jamais vues par la
  caméra fixe) ne sont que dans la collision. Un draw call pour le sol, un pour toutes les faces et
  le rideau de la côte, un pour la mer de nuages.
- **E2 — la côte** : pas en escalier ; ligne coast_value() = 0 d'un champ lisse (part de terre des
  4 × 4 cases autour de chaque coin) plus un bruit de 0,11 (± 0,44 m), échantillonnée tous les 1/3 m
  comme le mesh ; elle déborde d'une case sur le vide quand la terre autour est d'un seul palier.
  Seules les cases qu'elle peut couper sont découpées. Lèvre de pierre peinte (0,1 à 0,5 m) et
  liseré sombre au bord ; rideau de roche (lèvre, falaise, dessous qui se resserre jusqu'à 38 m) sans
  collision ; **barrière invisible le long du vide et des bords « land »** : on ne tombe pas d'une
  carte (une sortie se pose en deçà du bord). Mer de nuages portée par `MapGround` (`CloudSea`) quand
  la carte touche le vide.
- **E2 — eau dormante non praticable** (`walkable: false`) : `is_walkable` dit non et une barrière
  invisible la borde (pixel par pixel de `materials.png`), pour que le joueur ne marche pas là où les
  PNJ ne vont pas. Le lit de ruisseau reste praticable.
- **E2 — prolongement** : au-delà d'un bord « land », le sol continue sur `skirt` m (16 par défaut)
  avec les cases du bord recopiées, pour que la caméra ne voie jamais la fin du monde ; il n'est pas
  praticable (barrière au bord de la carte).
- **E2 — lecture des images** : `load()` de la texture importée (sans perte) puis `get_image()`,
  comme l'atlas du sol de l'île (`IslandTerrain.mipmapped_atlas`) ; aucun réglage d'import
  particulier. Sur le Web, `get_image()` relit la texture (WebGL 2) : à mesurer avec le chargement des
  cartes (E1).
- **E2 — lumière** : `MapGround` suit la première `DirectionalLight3D` de la scène au chargement
  (ombres portées des falaises dans le shader du sol, côté chaud des nuages) ; `set_sun()` pour un
  changement de lumière (E9).
- **E2 — `Map` en attente** : E1 créait `src/world/map.gd` en parallèle ; la carte de démonstration
  `essai_relief` a eu pour racine un remplaçant (`tests/stubs/e2_map_stub.gd`) jusqu'à la fusion
  d'E1, où elle a pris `map.gd` (le remplaçant est retiré).
- **E2 — talus de terre** : image provisoire `assets/hd2d/cliff/bank_earth.png` (384 × 96, recette
  dans `tools/hd2d_ground.py`) ; le muret reprend `wall_stone_b.png`, la roche `lip.png` et
  `cliff.png`.
- **E2 — mesures** (carte de 80 × 60 m, `tests/data/maps/mesure_80x60`, lecture comprise, sans
  écran) : 35 à 40 ms ; sol 3 881 triangles, faces 5 648, collision 4 097, barrière 2 284. Carte de
  démonstration (60 × 45 m) : 33 ms à chaud ; sol 2 358 triangles, faces 3 272 ; 14 à 26 draw calls
  par vue avec ses décors (3 pour le sol).
- **E3 — format des intérieurs** : un étage = une carte, décrit dans
  `data/maps/<map_id>/interior.json` (pièces en rectangles sur la grille d'un mètre, matières par
  pièce, portes, fenêtres, éléments de mur, lampes ; `docs/INTERIEURS.md`), lu et vérifié par
  `InteriorLayout`. Les murs se déduisent des pièces (un mur entre deux cases de pièces
  différentes, le vide compris), centrés sur la ligne de grille, 0,25 m d'épais (la profondeur
  d'un `wallcut_*`) ; aux angles, le mur nord-sud porte le poteau, un mur est-ouest s'arrête contre
  lui. Une porte praticable troue le mur sous un linteau ; une porte fermée (`passable: false`)
  garde le mur et pose son image. Portes et éléments à 0,175 m au moins d'un angle.
- **E3 — rien ne cache le joueur** : la *ligne de coupe* est la première limite de pièce au sud de
  la case du joueur, dans sa colonne (porte comprise) ; ce qui est au sud de la ligne moins 0,3 m
  n'est dessiné que sous 0,15 m (murs, portes, fenêtres, éléments) ou 1 m (meubles
  `InteriorPanel`, `cut_height`) : le mur sud de la pièce n'est jamais dessiné, la pièce reste
  close à l'est, à l'ouest et au nord. Une coupe par z seulement aurait laissé les cloisons
  nord-sud cacher le joueur dans leurs portes (vues par la tranche) : *colonne de coupe* de la
  cloison qui passe sous le joueur, sur 4,5 m au sud de lui. La ligne glisse à 14 m/s (pas de
  saut à la porte), saute au-delà de 9 m (arrivée). Dans le shader : `discard` au-dessus de la
  hauteur gardée, tranche des murs coupés en `section_color` (faces arrière). Vérifié par
  `test_interior_entrepot.gd` depuis 6 791 cases (grille de 0,25 m), 3 points du corps, caméra
  bornée comme `CameraRig.limits`.
- **E3 — lumière des intérieurs** : aucune lumière du moteur (en Compatibility, chaque lumière
  ponctuelle compte par objet, huit au plus par mesh fondu, et traverse les murs) : deux cartes de
  lumière vues de dessus (4 texels par mètre, RGBA8 × 2), le jour des fenêtres et les lampes,
  bornées à la pièce de leur source, ajoutées en émission (albedo × lumière) aux sols, murs,
  panneaux et meubles ; plus faibles en haut des murs. Préréglage `interieur`
  (`src/world/materials/lighting_interieur.tres`, `HD2DLighting` : ambiance chaude 0,34, soleil
  0,38, vignettage 0,45). Moment de la journée : `InteriorRoom.apply_phase` (morning, day,
  evening, night : teinte et énergie du jour, énergie des lampes), branchée sur
  `EventBus.day_phase_changed` ; la lueur des vitres suit le jour, celle des appliques et du
  fourneau suit les lampes. Vide autour du bâtiment : un sol presque noir (`VOID_COLOR`).
- **E3 — meubles** : `InteriorPanel` (sous-classe de `DecorPanel`, donc racine valide d'un décor) :
  nœud au milieu de l'emprise, image au bord sud (`image_offset`), ombre et boîte de collision sur
  l'emprise ; matériau des intérieurs partagé par image (le `PropBatcher` les fond : coordonnée de
  coupe et hauteur gardée dans UV2). Scènes écrites par `tools/hd2d_interior.py scenes` dans
  `src/world/props/` (sans méta de catégorie : `test_hd2d_decor` leur demande une collision).
  Règle de pose : au-delà d'1 m, contre un mur nord ; au milieu d'une pièce, profondeur
  d'emprise ≥ (h − 0,25) / 0,78 − 0,35 m (pente du regard de la caméra) ; d'où la chaise à
  0,65 m. Dans les 5 m nord d'un étage, la caméra butée sur `camera_bounds` voit plus à plat : on
  n'y laisse derrière un meuble haut que moins de 0,7 m (chaises du réfectoire contre le mur
  nord). Un meuble plaqué au mur (emprise < 0,3 m : le grand miroir) est coupé comme le mur
  (`cut_height` 0,15), sinon son mètre gardé cache le joueur de l'autre côté du mur.
- **E3 — images du lot I** (après la livraison réelle, PR #21) : au manifeste avec `lot: "I"`,
  75 images à leur taille réelle (12 matières, 4 portes, 3 fenêtres, 12 éléments de mur,
  42 meubles, 2 tapis de `assets/hd2d/decals/`) : les images livrées qu'emploie la carte d'essai
  et 6 remplaçants pour les noms encore absents (`floor_flagstone_cellar`, `wall_cellar_stone`,
  `wallcut_stone`, `door_armory`, `wallitem_height_marks`, et `door_frame_wood`, hors cahier).
  Les remplaçants doublons d'une image livrée sous un autre nom sont retirés avec leurs scènes ;
  `tools/hd2d_interior.py` ne dessine plus que les remplaçants, jamais une image livrée.
  `test_hd2d_assets.gd` lit aussi `docs/ASSETS_HD2D_SUKASUKA.md` (qui écrit les chemins
  complets) et accepte `solid_edge` sur tout bord, comme `tools/hd2d_assets.py check`
  (`rug_brown` touche le bord bas). `tools/hd2d_scenes.py`, `test_hd2d_scenes.gd` et le compte des
  45 décalques ne portent que sur les lots A à G du cahier n° 2.
- **E3 — portes qu'on franchit** : image à ouverture transparente (`door_frame_wood`) ou aucune ;
  `door_room` et `door_room_open` (battant ou embrasure opaques) cacheraient le joueur sur le seuil
  avant que la coupe ne passe : réservées aux portes fermées (`passable: false`).
- **E3 — carte d'essai** `entrepot_rdc_essai` (40 × 24 m) : couloir en L, réfectoire, cuisine,
  salle de lecture, archives, descente vers la salle des armes (porte rivetée fermée), salle de
  bains, infirmerie, entrée, salle de jeux, chambre de Nygglatho (d'après `v1_vex.md` et
  `v2_v3.md`, rubrique 3, et `docs/ASSETS_HD2D_SUKASUKA.md`, 3.17 ; la chambre de Nygglatho au
  rez-de-chaussée, près de l'entrée : emplacement original, à revoir avec les lieux de D2), meublée
  des images livrées. `camera_bounds` =
  Rect2(2, 5, 36, 14) : en x tout le bâtiment, la caméra reste au droit du joueur (le
  `Rect2(10, 9, L − 20, P − 17)` des cartes du dehors la décalerait, et une cloison nord-sud
  cacherait le joueur en biais). Après la fusion avec E1 : racine `Map`, sortie `MapExit`
  « vers_entrepot » franchie en marchant par la porte d'entrée, vers le `Spawn` de
  `ile_ancienne` tant que la carte `entrepot` (le dehors) n'existe pas ; la sortie « Descendre »
  de la porte rivetée attend la carte `entrepot_crypte` (marqueur `from_entrepot_crypte` déjà
  posé) : `test_maps.gd` demande des cibles qui existent.
- **E3 — lumière d'une carte intérieure** (en attendant E9, comme `map_light.tscn` dehors) :
  enfant `Light`, instance de `src/world/interior_light.tscn` (WorldEnvironment au fond uni
  `VOID_COLOR`, Sun) qui pose le préréglage `interieur` à l'entrée et rend le réglage par défaut
  (couchant) à l'étalonnage de la caméra et aux personnages en partant, par la carte (ses enfants
  ont déjà quitté l'arbre) : les cartes du dehors supposent ce réglage.
- **E3 — caches** : matériaux et meshes partagés des panneaux d'intérieur en références faibles
  (comme ceux de `DecorPanel` depuis E1) ; uniformes partagés (cartes de lumière, coupe) oubliés
  quand la pièce qui les a posés part.
- **E3 — requêtes du sol** : `InteriorRoom` répond aux mêmes questions que `MapGround` (E2) :
  `height_at`, `material_at` (nom de l'image du sol), `is_walkable` (dans une pièce, hors des
  murs ; les meubles ne comptent pas) et `room_at`, en coordonnées de la carte.
- **C3 — cahier des images n° 3** (`docs/ASSETS_HD2D_SUKASUKA.md`, d'après `docs/REFONTE.md`,
  sections 8 et 8.1) : 404 images, 90 planches et 2 portraits en six lots (I à N), lot J au-delà
  de l'ordre de grandeur (80 planches au lieu de 40 à 60) pour être exhaustif, priorités 1 à 3 ; les
  animations nouvelles d'un personnage livré viennent en planche complémentaire `<id>_life` (rangée
  `repos` recopiée comme étalon de taille), en planche de tenue (`_home` sans arme, `_pajamas`,
  `_rain`) ou de geste (`willem_cook`, `nygglatho_tea`…) ; à confirmer par les lots du moteur
  (section 9.4 du cahier) : ces planches, les noms hors de la section 8.1 (`etreinte`, `pare`,
  `broute`, `travaille` des fées pour la toilette), les cadences de la faune, les navires en volume
  (`ships/`), les faces de paliers (`cliff/step_*`), les décalques des pièces, la pluie, les vitres
  éclairées et les fenêtres de nuit ; aucune fée générique aux cheveux rouges (couleur de
  l'empiètement, V3).
- **E1 — carte héritée** : `src/world/maps/ile_ancienne/ile_ancienne.tscn` est une scène héritée
  d'`island.tscn`, dont le script (`island.gd`) étend désormais `Map` : `Ground` est le sol de
  l'île, les zones restent des zones (`World/ile_ancienne/Zones/<zone>`, `zone_entered`
  inchangé) ; la scène héritée ajoute `Geometry`, `Markers` (`Spawn` = celui du village, en
  (0 ; 0,2 ; 9)), `Exits` et `Life`. Elle garde les coordonnées de l'île, centrées sur l'origine
  (`island.gd` redéfinit `area()`) au lieu du coin nord-ouest du contrat : sauvegardes, PNJ,
  déclencheurs, masques du sol et tests en dépendent, pour une carte retirée en phase 5.
  `island.tscn` porte `size` (160 × 160) et les bornes de caméra de l'île.
- **E1 — nœud de la carte** : dans `game.tscn`, `World` (Node3D, groupe `map_slot`) remplace
  `Island` ; `game.gd` y pose la carte (`WorldManager.enter_map`, position sauvegardée ou Spawn) ;
  `main.gd` charge la partie et sa première carte sous une seule barre (`Loading.load_scenes`),
  la carte restant en cache jusqu'à ce que `game.gd` l'ait posée.
- **E1 — sorties à invite** : le joueur ne détecte que les couches 6 et 7 ; une `MapExit` dont
  `prompt` est rempli passe d'elle-même sur la couche 6 et dans le groupe `interactable` à son
  `_ready` (dans la scène, elle reste en couche 0, comme le dit le contrat).
- **E1 — joueur figé** : `process_mode` DISABLED du début du fondu au noir à la fin du fondu de
  retour (ni mouvement, ni coup, ni interaction, ni dégâts : il quitte l'espace physique),
  appliqué en fin d'image (`call_deferred`) : un `go_to` lancé de l'image physique du joueur (E)
  ou du pas de la physique (sortie à pied) lui faisait finir son `move_and_slide` sans espace
  (« Parameter "space" is null »). À `map_entered`, le joueur oublie son élan, sa cible et son
  invite (`player.gd`, `_stop_motion`, comme à la réapparition) : seule retouche de `player.gd`,
  la mission demandant une vitesse remise à zéro que seul le joueur tient (`_move_velocity`).
- **E1 — pas d'aller-retour** : `is_transitioning()` reste vrai `SETTLE_FRAMES` (3) images
  physiques après une arrivée (`go_to`, `enter_map`) ; une sortie ne part que sur une entrée
  (`body_entered`) ou une interaction : un joueur posé dedans doit en sortir et y revenir.
- **E1 — zones et cartes** : changer de carte vide `current_zone()`, `GameState.zone` et la
  dernière zone annoncée du joueur (`Zone.LAST_ZONE_META`) : de retour sur l'île, la zone
  d'arrivée s'annonce de nouveau (HUD, auto-sauvegarde). Au début d'une partie (aucune carte
  avant), la zone de la sauvegarde reste. Sur une carte sans zone, `respawn()` et `rescue()`
  ramènent au marqueur d'arrivée (`rescued(map_id)`) ; `load_zone`/`teleport` d'une zone de l'île
  depuis une autre carte ramènent sur l'île sans fondu (raccourci `?zone=`), sans rien faire s'il
  n'y a pas de nœud `World` (tests sans partie).
- **E1 — sauvegarde v3** : champ `map` (lu seulement avec une position valide, comme `zone`) ;
  migration v2 → v3 : `map` = `ile_ancienne` si la zone est connue, vide sinon (partie pas encore
  placée : Spawn du village, comme avant) ; une carte inconnue au chargement ramène au Spawn de
  `START_MAP` (avertissement). Vérifié sur une vraie sauvegarde écrite par le jeu de `50ec961`
  (`tests/data/saves/save_v2_avant_refonte.json` : rue du port, quête principale à
  `to_the_woods`, deux pages, record de 420 aux dunes).
- **E1 — fondu** : 0,35 s au noir (#0b0713), 0,35 s de retour ; l'opacité est tenue par
  WorldManager (`fade_alpha()`, tween pausable) et dessinée par `UI/MapFade` (traité même en
  pause, souris jamais prise) : une partie libérée pendant un fondu (retour au menu) emporte
  son noir, et `go_to` s'arrête proprement. Le nom de la carte (`display_name`) s'annonce une
  fois l'écran revenu, dans le style du nom de zone du HUD ; vide pour `ile_ancienne` (le HUD
  annonce ses zones).
- **E1 — chargement découpé** : comme `Loading.load_scene` (dépendances d'abord, feuilles en
  premier), 100 ms de travail par image sous le noir, où le monde 3D n'est plus dessiné
  (`Viewport.disable_3d`, rétabli juste après l'installation, une image avant le fondu de
  retour) : sur le Web en rendu logiciel, l'île se rechargeait en 17 s et 30 images (chacune
  redessinait la carte sous le noir), en 5 s et 15 images ensuite. L'ancienne carte est libérée (`free`) juste
  avant l'instanciation de la nouvelle, une fois les ressources de la nouvelle chargées : les
  images communes restent en cache, une seule carte instanciée. Aucune carte n'est préchargée
  (`preload`) par du code durable : elle resterait en mémoire.
- **E1 — caméra** : à chaque `map_entered`, `CameraRig.limits` = `WorldManager.camera_bounds()`,
  puis `make_current()` (l'`OverviewCamera` de l'île, `current` à son entrée dans l'arbre,
  prenait la main au retour sur l'île) et `snap()`. Les bornes restent celles du point visé.
- **E1 — lumière** : en attendant les préréglages de E9 (`light_preset`), une carte porte sa
  lumière : `src/world/map_light.tscn` (environnement, soleil et nœud `Lighting` de l'île).
- **E1 — carte d'essai** (`src/world/maps/essai/`) : 40 × 30 m, sol plat provisoire
  (`StaticBody3D`, plan d'herbe en tuiles de 4 m, chemin de terre, murs invisibles), décors de
  `src/world/props/`, sentier ouest (sortie à pied vers l'île, arrivée `from_ile_ancienne` tournée
  vers l'est), bornes de caméra `Rect2(10, 9, 20, 13)` (rien au-delà des bords à l'écran). Sur
  l'île, sortie de test discrète : un panneau au coin est du hangar du port (41 ; 63,4), invite
  « Carte d'essai », arrivée `from_essai` en (41 ; 66,2) tournée vers le sud (à 6,5 m du bord).
- **E1 — décalques** : `GroundDecal.follow_ground` suit `IslandTerrain` (le relief de l'île) ;
  sur une nouvelle carte, le mettre à faux tant que E2 ne l'a pas branché sur `MapGround`.
- **E1 — une seule carte en mémoire** (`tools/map_bench.gd`, aller-retour île ↔ essai) : deux
  caches statiques gardaient l'ancienne carte. `PropBatcher._soups` (triangles de chaque mesh
  fondu, clé = le mesh) gardait en vie les meshes propres à chaque décor (murs des `Building`,
  décalques drapés) de chaque carte instanciée : + 566 objets et + 3 Mo par aller-retour ; il est
  désormais propre à chaque `batch()`. Les caches de matériaux de `DecorPanel`, `Building` et
  `GroundDecal` (clé = RID de l'image) gardaient toutes les images vues : ils sont en références
  faibles, clé = chemin de l'image (RID sans chemin), et `update_foreground` oublie les matériaux
  morts. Mesuré sans écran : carte d'essai seule 148 Mo, 231 ressources ; après l'île, avant
  410 Mo et 584 ressources, après 263 Mo et 311 ressources (restent les caches de l'île :
  `IslandTerrain` et `IslandRock`, maillages et atlas du sol, et les planches des PNJ de
  `SheetLoader`) ; nœuds, objets et ressources identiques d'une visite à l'autre. Revers : l'île
  se recharge de zéro à chaque retour (1,5 s sous Xvfb au lieu de 0,3 s).
- **D2 — lieux, acte 1 et vie** (`docs/lore/CARTE.md`, `ACTE1.md`, `VIE.md`) : la côte nord porte le port, le village et la colline des étoiles (la caméra regarde le nord, le vide doit y être), l'entrepôt est au cœur de la forêt, la ville au sud-est, la forêt profonde et la montagne au sud ; l'entrepôt fait 30 × 14 m sur deux niveaux (un toit-terrasse à linge à l'est) et toutes les cartes sont vérifiées par un script hors dépôt ; l'acte 1 tient en douze jours (mission des aînées ramassée en un jour, départ le jour 12, comptes de jours non chiffrés à l'écran) ; hors des scènes, Chtholly porte un bâton, pas Seniorious ; un animal vaincu s'enfuit.
- **Budget Web relevé de 100 à 150 Mo compressés** (cahier n° 3 ; même choix de l'utilisateur : la
  qualité avant le poids, le bureau d'abord). Les lots I et J de priorité 1 (PR n° 21 et 22) portent
  l'export Web à 101,3 Mo compressés (wasm 9,7 Mo, pck 91,6 Mo) : `main` était rouge sur la seule
  étape de taille, les 877 tests passaient. Le reste du cahier n° 3 ajoutera encore des images :
  la version Web allégée (WebP avec perte pour le seul export Web, ou un pck par lieu chargé à la
  demande) est à mesurer en phase 5 de la refonte, sans toucher au bureau.
- **E2 — décalques sur les cartes** : `GroundDecal.follow_ground` drape sur le `MapGround` (enfant
  `Ground`) du premier ancêtre qui en a un, par `MapGround.triangles_in` (même forme que
  `IslandTerrain.triangles_in`, coordonnées de la carte décalées de sa position) ; sans `MapGround`,
  il suit `IslandTerrain` comme avant (île ancienne). Les décalques d'une carte en relief gardent
  donc `follow_ground` vrai (nénuphars d'`essai_relief`, décalque d'essai sur la rampe dans les tests).
- **E2 — matériau des faces partagé** : `MapGround.cliff_material()` est gardé par une référence
  faible (règle d'E1 : une carte quittée libère ses images) ; le sol se bâtit à `_ready`, ou plus
  tôt à la première question (`triangles_in` d'un décalque prêt avant lui).
- **E2 — mesures dans la vraie partie** (`game.tscn` + `WorldManager.enter_map(&"essai_relief")`,
  Xvfb, `tests/integration/demo_e2_relief.gd`) : 24 à 33 draw calls par vue (sol 1, faces 1, mer de
  nuages 1 ; le reste : décors, joueur, interface, post-traitement) ; construction du sol 36 à 60 ms
  à froid avec le rendu (33 ms à chaud sans écran). La vue « large » est au zoom le plus éloigné
  du jeu (`max_distance` 25 m) ; la carte entière se voit par `tools/map_build.py view`.

## E9 — La lumière et le temps

- **E9 — où vivent le moment et le temps** : dans `GameState` (`moment`, `weather`, setters qui
  émettent `EventBus.atmosphere_changed(moment, weather)`, sauvegardés), comme `skin_id` ; un
  autoload `Atmosphere` (`src/autoload/atmosphere.gd`, seul ajout à `project.godot`) en fait la
  lumière. Identifiants en français, ce sont des données comme les `map_id` : moments `aube`,
  `matin`, `apres_midi`, `couchant`, `nuit` (`GameState.MOMENTS`), temps `clair`, `pluie` (pluie
  fine), `averse` (`GameState.WEATHERS`) ; une autre valeur est refusée (avertissement). Une
  nouvelle partie et une sauvegarde d'avant E9 sont au couchant, sans pluie : le monde de
  toujours.
- **E9 — sauvegarde** : `moment` et `weather` sont des champs facultatifs du schéma v3 (absents
  ou inconnus : couchant, clair), sans nouvelle version ni migration (`SAVE_VERSION` reste 3) ;
  `to_dict` les écrit après `tracked_quest`.
- **E9 — préréglages** : des données, `data/lighting/<id>.tres` : un `HD2DLighting` par moment,
  plus `interieur` et `interieur_nuit` ; le temps est un `HD2DWeather` (`pluie.tres`,
  `averse.tres` ; « clair » n'a pas de fichier) qui *modifie* le préréglage du moment (moins de
  soleil, gris, brouillard, étalonnage terne, gouttes, sol mouillé) : la pluie au matin, au
  couchant ou la nuit sort du même fichier. Le couchant reprend exactement les valeurs
  d'`island.tscn` et de `post_fx.gdshader` (testé ; captures du village et de la carte d'essai
  identiques au pixel près à celles d'avant E9, hors bandeau du nom de la carte). Les anciens
  `src/world/materials/lighting_sunset|dusk|night.tres` sont retirés : le crépuscule n'est pas
  un moment du récit (« le port sous une pluie fine au crépuscule » = couchant + pluie).
- **E9 — préréglage effectif** : `Map.light_preset` s'il est rempli (un moment, `interieur`, ou
  tout `data/lighting/<id>`), sinon `interieur` pour une carte `interior`, sinon le moment ; le
  temps s'y ajoute dehors. Dedans, ni pluie ni sol mouillé : seule la lumière des fenêtres
  baisse et grisaille (`window_light_scale`). `interieur` mêle `interieur` (jour : lumière des
  fenêtres) et `interieur_nuit` (lampes ×2,2, cristaux, fenêtres sombres) selon le
  `night_amount` du moment du dehors (aube 0,45, couchant 0,15, nuit 1, jour 0), et teinte la
  lumière des fenêtres du soleil du dehors (orangée au couchant).
- **E9 — la lumière quitte les cartes** : `src/world/map_light.tscn` est retiré (la carte d'essai
  ne le porte plus), ainsi que le nœud `Lighting` d'`island.tscn` et `day_phase_lighting.gd`.
  `Atmosphere` ajoute à la carte courante un enfant `AtmosphereRig` (libéré avec elle) : un
  `WorldEnvironment` (réglages de l'île) et un soleil seulement si la carte n'en a pas, la
  lumière du joueur et la pluie. L'ancienne île garde son `WorldEnvironment` et son `Sun`
  (structure figée) : la lumière les règle sur une copie de l'environnement, sans en ajouter (un
  seul environnement par scène). Une carte de E2 ou E3 qui porterait encore les siens serait
  réglée de même.
- **E9 — quand la lumière se pose** : tout de suite à `map_entered` (sous le fondu au noir) et à
  `game_loaded` (paramètres de développement compris) ; à chaque image, `Atmosphere` compare la
  carte courante (`WorldManager.current_map_node()`) à celle qu'il a habillée : une carte posée à
  la main (démonstration, capture d'une carte seule) est habillée à l'image suivante. Le relevé
  (`HD2DLightTargets.scan`) se fait une fois par carte ; les transitions ne règlent ensuite que
  ce qui change (lueur, sol mouillé et images de nuit seulement quand leur valeur change).
- **E9 — transitions** : 4 s par défaut (`Atmosphere.transition_time`), adoucies (smoothstep) ;
  couleurs et nombres interpolés, l'azimut du soleil par le plus court chemin ; les deux ciels
  se fondent dans `sky.gdshader` (deux panoramas), les deux mers de nuages dans
  `cloud_sea.gdshader` ; un changement en cours de transition repart du mélange posé (le ciel
  repart de celui qui dominait). `set_moment(…, 0.0)` : tout de suite. Elles s'arrêtent pendant
  la pause.
- **E9 — le ciel ne se voit pas** : la caméra (32° vers le bas, champ de 30°) ne voit jamais
  au-dessus de l'horizon (le haut de l'écran est à 17° dessous) ; le panorama ne se voit qu'au
  bord d'une carte sans mer de nuages. `sky.gdshader` remplace le `PanoramaSkyMaterial` (même
  lecture au plus proche voisin, même rendu) ; la nuit prend `sky_night.png` (cahier n° 2) ; ses
  étoiles se voient dans les creux sombres de la mer de nuages (`clouds_stars`, points fixes qui
  scintillent), seule part du ciel étoilé à l'écran.
- **E9 — la nuit lisible** : lune froide à l'est (40°, énergie 0,42), ambiance bleutée 0,62,
  lanternes ×2,2, lueur des fenêtres et cristaux ×1,8, étalonnage bleuté sans noir écrasé, et la
  lumière du joueur. Mesuré : luminance moyenne 0,18 à 0,23 de l'écran, 0,25 à 0,30 du tiers du
  milieu (couchant 0,38) ; `test_e9_captures.gd` refuse une vue sous 0,10 (écran) ou 0,12
  (milieu).
- **E9 — la lumière des fées** (V1, « L'Homme sans Marque ») : une `OmniLight3D` blanc bleuté
  (énergie 1,5, portée 7,5 m) et l'orbe (`anim/fairy_light.png`, affiché à 64 px/m pour qu'il se
  voie) à hauteur de main, du côté où le joueur regarde (`Player.aim_direction`, lue par
  `has_method`), qui flotte un peu. Allumée la nuit dehors seulement (`player_light` du
  préréglage, mêlée pendant les transitions : elle s'allume avec la nuit) ;
  `Atmosphere.player_light_mode` (`auto`, `on`, `off`) pour une scène (Willem arrive sans
  lumière). Réglages dans `AtmosphereRig` (`light_energy`, `light_range`, `light_color`,
  `light_height`).
- **E9 — la pluie** : dans le monde, `RainFall` (gouttes en traits obliques, vent d'ouest, et
  éclaboussures au sol, 900 + 160 sprites, deux draw calls, tout le mouvement dans
  `rain.gdshader`, l'intensité est la part des gouttes qui tombent : rien à reconstruire, la
  pluie s'arrête en douceur) ; à l'écran, le rideau (`rain_curtain.gdshader`, un draw call : la
  bande de la pluie fine derrière, celle de l'averse devant, 1,5 fois plus grande) ; caché sans
  pluie, sans coût. Sol et décors mouillés : `hd2d_wetness` dans `hd2d_light.gdshaderinc` (ajout,
  0 par défaut : rien ne change ailleurs), posé sur chaque matériau de la carte : diffus −30 %
  sous chaque lumière, reflet serré des lumières (lune, lanternes, lumière du joueur) borné pour
  ne pas éblouir, lustre rasant léger ; plus fort à plat (sol, toits) qu'en panneau ; un
  `StandardMaterial3D` (sol provisoire de la carte d'essai) devient moins rugueux et un peu
  spéculaire. Les flaques animées attendent un `GroundDecal` animé (demande).
- **E9 — formats d'images confirmés** (cahier n° 3, sections 8 et 9.4) : rideau de pluie
  (`rain_curtain`, `rain_drizzle` : 384 × 384, 4 images, répétées à l'écran, une image pour
  384 px d'un écran de 720) ; éclaboussure (`rain_splash`, ancrée au milieu du bas) ; lumière des
  fées (`fairy_light`, centrée) ; fenêtres de nuit (`<nom>_night.png` à côté de `<nom>.png` le
  remplace quand `night_amount` ≥ 0,5) ; vitres éclairées (`window_lit_*` : ne se montrent que la
  nuit, par leur `alpha_cut`). Remplaçants générés (`tools/hd2d_sky.py`, lot N du manifeste,
  `python3 tools/hd2d_assets.py check` sans écart) et un effet `fx/rain_drop.png` (6 × 56).
  `test_hd2d_assets.gd` lit aussi le cahier n° 3 pour nommer chaque image.
- **E9 — la lueur des panneaux** : `glow_strength` de chaque matériau de la carte (fenêtres des
  façades, cristaux, lampadaires) × `window_glow` du préréglage (après-midi 0,6, nuit 1,8), la
  valeur de départ gardée en méta (les matériaux sont partagés entre cartes par les caches).
- **E9 — les personnages ne sont pas teintés** : leurs planches ne sont pas éclairées et
  `src/visuals/` n'est pas à E9 ; la nuit, ils restent clairs (ils ressortent, la lisibilité y
  gagne). `Atmosphere.sprite_tint()` donne la teinte à poser (demande dans
  docs/CONTRACT_REQUESTS.md).
- **E9 — raccourcis** : `?moment=nuit&temps=pluie` (Web) ou `-- --moment=nuit --temps=pluie` sont
  lus par `Atmosphere` lui-même (pas par `src/test_shortcuts.gd`, hors périmètre), posés à chaque
  partie chargée, sans transition ; avec `?trace` pour les mesures. F7 (moment suivant) et F8
  (temps suivant), Maj : tout de suite, dans une version de débogage (éditeur) ou quand l'un de
  ces paramètres est donné : jamais dans une partie publiée sans paramètre.
- **E9 — l'ancienne phase de la journée** : `EventBus.day_phase_changed` (M3, que rien
  n'émet) reste au contrat ; `Atmosphere` le traduit en moment (morning → matin, day →
  apres_midi, evening → couchant, night → nuit).
- **E9 — luminance testée sous Xvfb** : le rendu des tests sans écran est factice ;
  `tests/integration/test_e9_captures.gd` lance `tools/e9_shots.sh` (une partie rendue sous Xvfb,
  dix préréglages sur la carte d'essai et le village, environ 30 s) et lit les luminances et les
  draw calls ; sans `xvfb-run`, il est en attente. `tools/e9_shots.sh` sans argument rend les
  vingt vues (village, carte d'essai, carte d'essai prise pour un intérieur, bord de l'île).

## R1 — Le raccord de la lumière (E3, E9, E2, personnages)

- **R1 — une seule lumière pour les intérieurs, celle d'`Atmosphere`** : `InteriorRoom` ne
  connaît plus de phases (`PHASES` et le branchement sur `day_phase_changed` sont retirés) ;
  `HD2DLightTargets` relève les `InteriorRoom` de la carte et leur passe le réglage posé à chaque
  pose et à chaque image d'une transition (`InteriorRoom.apply_lighting`). `apply_phase(phase)`
  reste comme simple passage vers le moment correspondant d'`Atmosphere` (tout de suite).
  `src/world/interior_light.tscn` / `.gd` et `src/world/materials/lighting_interieur.tres` sont
  retirés, et le nœud `Light` de `entrepot_rdc_essai` : une carte intérieure ne porte aucune
  lumière. Fond des intérieurs : `AtmosphereRig` y pose un environnement à fond uni
  (`InteriorRoom.VOID_COLOR`), sans ciel.
- **R1 — le jour des fenêtres vient du moment du dehors** : deux champs ajoutés à
  `HD2DLighting`, `window_light` (énergie des flaques de jour devant les fenêtres et de la lueur
  des vitres) et `window_tint` (leur couleur), avec une valeur dans chaque préréglage : aube 0,6
  rosé, matin 1,3, après-midi 1,15, couchant 0,85 orangé, nuit 0,4 bleu lune ; `interieur` 1,15
  et `interieur_nuit` 0,4 pour une carte qui les prendrait directement. `Atmosphere.interior_for`
  copie ceux du moment du dehors (le matin, l'après-midi et le couchant se distinguent dedans,
  ce que le seul mélange `interieur` / `interieur_nuit` par la part de nuit ne faisait pas) ; les
  lampes, cheminées et cristaux suivent `lamp_energy` du mélange (part de nuit). La pluie dehors
  baisse et grise la lumière des fenêtres (`HD2DWeather.window_light_scale`, aussi sur
  `window_light`), jamais les lampes.
- **R1 — la nuit dedans se voit** : `interieur.tres` lampes ×0,25 (éteintes ou presque le
  jour) ; `interieur_nuit.tres` lampes ×2,7 (flaques chaudes sous chaque lampe, appliques et
  fourneau qui luisent), ambiance plus froide et plus basse (0,5, bleu-violet), vignette 0,42,
  teinte des personnages 0,82 / 0,76 / 0,74. Mesuré sous Xvfb (`tools/e9_shots.sh`, luminance
  de l'écran / du tiers du milieu) : réfectoire matin 0,243 / 0,321, couchant 0,209 / 0,266, nuit
  0,110 / 0,156 ; couloir matin 0,333 / 0,449, couchant 0,289 / 0,400, nuit 0,165 / 0,343. Avant
  le raccord, la nuit du réfectoire tombait sous le seuil de lisibilité (0,096) avec des fenêtres
  toujours au jour et des lampes sans effet ; `test_e9_captures.gd` vérifie désormais que la nuit
  reste au-dessus des seuils d'E9 et sous 0,65 fois la luminance du matin.
- **R1 — les vitres la nuit** : une fenêtre qui a son image de nuit (`<nom>_night.png`, lot N ;
  livrées depuis `f393bb1` pour `window_cross_small`, `window_cross_large`,
  `window_reading_seat`) la prend la nuit (`HD2DLightTargets`, `night_amount` ≥ 0,5). Pour une
  fenêtre sans image de nuit, `interior_panel.gdshader` assombrit et bleuit l'image de jour quand
  le jour des fenêtres baisse (`night_view`, bleu nuit, selon `window_energy` de 0,15 à 0,9) ;
  quand l'image de nuit existe, `HD2DLightTargets` pose `night_view` à blanc (pas de double
  assombrissement).
- **R1 — la lueur des panneaux d'intérieur** suit leur pièce (`glow_follows` : le jour pour les
  vitres, les lampes pour les appliques, le fourneau, les cristaux) et n'est plus multipliée en
  plus par le `window_glow` du préréglage (elle l'était deux fois depuis la fusion d'E9) :
  `HD2DLightTargets` ignore la lueur des matériaux qui ont l'uniforme `glow_follows`.
- **R1 — aucune lumière du moteur en plus** : ni lampe `OmniLight3D` ni environnement dans la
  carte (le soleil d'`AtmosphereRig` sert de lumière d'ensemble, comme celui de l'ancienne
  `interior_light.tscn`) ; draw calls inchangés : réfectoire 41, couloir 56, le matin, au
  couchant et la nuit (vues sans le bandeau du nom de la carte).
- **R1 — le soleil du sol en relief** : `HD2DLightTargets` relève les `MapGround` de la carte et
  appelle `set_sun(toward_sun())` à chaque pose et à chaque image d'une transition (ombres
  portées des falaises : elles tournent du matin au couchant, puis suivent la lune) ;
  `MapGround._follow_sun` (la première `DirectionalLight3D` de l'arbre, une fois au chargement)
  est retiré. `set_sun` règle le matériau effectivement dessiné de la mer de nuages (la copie
  qu'`Atmosphere` pose en `material_override`), plus l'original devenu invisible.
- **R1 — une seule mer de nuages** : vérifié sur `essai_relief` au nord (vue `relief` de
  `demo_e9.gd`) : la mer de nuages est celle de `MapGround` (`CloudSea`, E2) ; `Atmosphere` n'en
  ajoute pas, il règle celle-ci (teinte, côté du soleil, étoiles, image de nuit). On garde celle
  d'E2 : elle est construite avec la carte, seulement si elle touche le vide, à la bonne
  profondeur ; `test_light_links.gd` vérifie qu'il n'y en a qu'une.
- **R1 — les personnages** : `CharacterVisual` multiplie la couleur de son sprite par
  `HD2DLighting.active_sprite_tint()` (posée par `Atmosphere` avec chaque réglage, transitions
  comprises), dans `advance()` (appelé à chaque image par `_process`, ou par les tests qui
  pilotent l'horloge des visuels), en gardant la couleur que d'autres posent sur le sprite
  (`EnemyData.tint`). Blanche au couchant et sans carte : `Atmosphere.dress(null)` (retour au
  menu) oublie le réglage (`current()` null) et rend la teinte blanche.
- **R1 — démonstrations** : `demo_e9.gd` a trois lieux de plus (`refectoire`, `couloir` dans
  `entrepot_rdc_essai` ; `relief`, `falaise` dans `essai_relief`) et attend que le nom de la carte
  s'efface avant de mesurer ; `demo_interieur.gd` prend `INTERIOR_MOMENT` (un moment
  d'`Atmosphere`) au lieu de `INTERIOR_PHASE`.
- **T2 — grille d'un demi-mètre des intérieurs** : les plans de CARTE.md, section 3, posent des
  cloisons au demi-mètre (cuisine de 4,5 m, couloir z 8,5 → 10,5) ; `InteriorLayout.GRID` = 0,5 m
  (cases, lignes de murs, coupe, colonne de coupe d'`interior.gdshader`) ; les étages au mètre
  (carte d'essai d'E3) ne changent pas.
- **T2 — cartes écrites par un outil** : `tools/interior_maps.py gen` relit les blocs ```plan de
  CARTE.md et écrit `data/maps/<id>/interior.json` et `src/world/maps/<id>/<id>.tscn` des quatre
  cartes de l'entrepôt (`check` : à jour ?, `places` : listes de places dans CARTE.md) ; il imprime
  chaque écart au plan.
- **T2 — ouvertures ramenées** : une ouverture « de toute une largeur » du plan garde 0,2 m de
  montant à chaque angle (InteriorLayout refuse une porte contre l'angle) : réfectoire|couloir
  1,1 m, escalier|couloir et entrée|couloir 3,6 m, palier_armes|couloir 1,6 m, trémie|couloir
  1,8 m ; une toile d'araignée de la crypte recule de 5 cm de l'angle.
- **T2 — portes de pièce franchissables** : chambranle `door_frame_wood` (ouverture transparente)
  au lieu de `door_room` (opaque, cacherait le joueur sur le seuil) ; les portes du dehors gardent
  leur image (`door_double`, `door_service`, `door_armory` fermée, ouverte par son invite).
- **T2 — bornes de caméra élargies en x** : rez-de-chaussée et étage `Rect2(2, 4, 28, 6)` au lieu
  de `Rect2(8, 4, 16, 6)` : bornée à x 8 → 24, la caméra regardait de biais les pièces des bouts
  et les cloisons nord-sud cachaient le joueur. Salle des armes et toit : bornes du plan.
- **T2 — rien ne cache le joueur derrière un meuble haut** : un meuble de plus de 1,21 m adossé au
  mur sud se coupe avec lui (`InteriorPanel.cut_offset`) ; un meuble haut au milieu d'une pièce
  ferme, par une collision sans image (« <meuble>_arriere »), la place où il cacherait les pieds
  du joueur (calculée par la caméra du jeu, bornée, regard de biais compris) ; les piliers de la
  crypte, les séchoirs et la rambarde sud du toit sont des panneaux de premier plan qui
  s'effacent ; le grand miroir des bains, tourné vers l'est, a son occulteur dans son orientation.
- **T2 — l'armoire de Chtholly contre le mur sud** : au milieu du mur est (plan : z 6,6), elle
  cachait le joueur, et la place qu'elle cache fermait avec le lit le nord de la chambre (bureau,
  calendrier) ; elle s'adosse au mur sud, à l'est de la porte (z 8,075), et se coupe avec lui
  (`MOVED` de `tools/interior_maps.py`).
- **T2 — sorties vers le dehors provisoires** : tant que la carte `entrepot` (T1) n'existe pas,
  les portes d'entrée et de service mènent au `Spawn` d'`essai` ; `tools/interior_maps.py gen`
  les raccorde (`from_entrepot_rdc`, `from_entrepot_rdc_service`) dès qu'elle existe.
- **T2 — le toit, une carte du dehors** : `MapGround` (pas d'`InteriorRoom`) dont le niveau 0 est
  la terrasse (`height_zero_value`), la cour 6,5 m plus bas ; sol `planches` (matière de
  `map_ground`) faute de `floor_roof_deck` ; le pan d'ardoise ouest est le toit d'un `Building`
  (`roof_slate`) au lieu de `roof_edge_slate` ; la rambarde en modules de 2 m, le module tordu à la
  place du module le plus proche de sa cote (x 12).
- **T2 — salle des armes sans préréglage propre** : le préréglage `noir` d'E9 n'existe pas ; la
  carte n'a pas de `light_preset` (intérieur : `interieur` d'Atmosphere) et aucune lampe.
- **T2 — objets à examiner** : `Examinable` (src/world/examinable.gd) lit
  `data/texts/entrepot.json` (format des textes de l'histoire, une clé par carte puis par objet)
  et l'affiche par le protocole de DialogueRunner, sans nom ni portrait ; paraphrases, aucune
  citation ; les noms des épées des râteliers ne s'affichent pas (ils demandent Willem, E6).
## T1 — L'entrepôt vu du dehors (carte `entrepot`)
- **T1 — la carte** `src/world/maps/entrepot/entrepot.tscn` suit `docs/lore/CARTE.md`, section 2 :
  le bloc « plan » de 2.12 est relu par `tests/unit/test_entrepot.gd` (sorties, marqueurs, points,
  places, bâtiment) ; aucune lumière dans la carte (E9). La scène est écrite par un script de
  travail hors dépôt (ossature du plan, puis kits par bande tirés à graine fixe) ; ~1 090 décors,
  136 images, `PropBatcher.cell_size` 24 m.
- **T1 — sol** (`data/maps/entrepot/plan.json`) : paliers du plan (lisière +1 m, clairière +0,5 m,
  champ, marais et creux des bois −0,5 m), toutes les faces en talus de terre (`step_earth`,
  `wall_earth_1m`, `step_marsh` attendus du cahier n° 3 : E2 n'a qu'un talus). Berges des marais et
  du creux des bois bruitées d'un mètre au plus autour du rectangle du plan, franches au pied des
  rampes. Le replat d'un mètre entre la lisière et la clairière (z 4 → 5) suit la clairière (pas de
  fossé) ; une boîte de bord le ferme (x 6 → 12). Matières propres : `herbe_drue` (grass_b),
  `chemin` (path_dirt_b), `eau_basse` (eau qui ondule, praticable : « on y marche »). La cour est une
  terre battue aux bords mangés par l'herbe, la place du duel toujours en terre ; usures de terre
  devant les cages et au milieu du champ ; mousse, feuilles et herbe usée dans la clairière.
- **T1 — rampes ajoutées au plan** : au marais de l'ouest par le sud (x 2 → 6, z 30 → 32) et au
  marais du sud-ouest depuis le chemin du village (x 7 → 10, z 43 → 45) : on y descend sans sauter
  (les PNJ d'E4 ne sautent pas). Le chemin de la clairière passe par sa rampe du sud-est (le tracé
  du plan, 27,6 ; 22 → 24 ; 19, franchirait le talus) ; la bande libre du plan reste libre.
- **T1 — `map_build.py gen`** accepte `height_zero_value` dans `plan.json` (paliers négatifs) ; un
  palier hors de l'image est une erreur au lieu d'être ramené à 0 en silence.
- **T1 — `PropScatter`** pose ses exemplaires sur le `MapGround` de la carte qui le porte (comme
  `GroundDecal`), sinon sur l'île : seul changement hors des dossiers du lot, sans effet sur
  l'ancienne île.
- **T1 — bâtiment** : deux `Building` (`warehouse_front_a`, 18 × 14 m, faîte 10 m, ardoise ;
  `warehouse_front_b`, 12 × 14 m, toit plat de planches, rambarde `roof_railing` et séchoirs
  `drying_frame` posés dessus, linge animé ; `gable_front` vrai : un toit plat n'a pas de
  pignon, ses flancs sont des gouttereaux comme ceux d'un toit « pignon »). Les façades et flancs du plan (noms proposés, 12.1)
  ont des remplaçants faits des morceaux de `warehouse_main` (livrée) : porte d'entrée à 12 m du
  bord gauche (x = 42), fenêtres placées sur les pièces du dedans (dépolies aux bains), plannings
  et plaque près de la porte ; porte de service à **6 m** de l'angle sud du pignon ouest (z = 20,
  2.7), pas à 8 m comme l'écrit 12.1 (demande dans docs/CONTRACT_REQUESTS.md). Au manifeste en lot
  « K » ; `test_hd2d_assets.gd` lit aussi `docs/lore/CARTE.md` (12.1 nomme ces images et leur
  taille). `roof_railing` et `drying_frame` (lot I, livrées, hors manifeste) : scènes extérieures
  `warehouse_roof_railing`, `warehouse_drying_frame` ; leur entrée au manifeste revient au lot I
  (T2) pour éviter un doublon.
- **T1 — remplaçants du lot M** (cahier n° 3, 7.3 et 7.4) : `thicket_a/b/c`, `bramble_hedge`,
  `alder`, `marsh_snag`, `marsh_hummock_a/b`, recettes dans `tools/hd2d_nature.py`.
- **T1 — règle de caméra** : tout décor qui dépasse la tête du joueur (1,4 m) devant une case où
  l'on marche prend sa variante de premier plan (`_forest`, ou `_fg` nouvelles : grand arbre, cage
  rouge, aulne, fourrés, porche) ; vérifié depuis 3 887 places par `test_entrepot.gd` (murs et
  toits : pieds, taille, tête ; décors opaques : tête). Au-delà du bord ouest, saules et aulnes en
  toile de fond (on ne passe pas derrière).
- **T1 — portes** : `porte_entree` et `porte_service` portent la cible du plan en métadonnée
  (`plan_target_map = entrepot_rdc`, `plan_target_marker`) et mènent, tant que le lot T2 n'est pas
  fusionné, au `Spawn` de `entrepot_rdc_essai` (E3). Une fois `entrepot_rdc` présent,
  `test_entrepot.gd` exige la vraie cible : **raccord à faire à la fusion** (deux lignes par porte).
- **T1 — places et points** : points nommés en `Life/Places/<nom>` (Marker3D au sol) ; places
  réservées en `Life/Areas/<nom>` (Marker3D au centre, `metadata/area` = Rect2 du plan), deux
  dossiers parce que `coin_soleil` est à la fois une place et un point.
- **T1 — lumières** : la lanterne à cristal de la porte est une `OmniLight3D` (`Lights/lanterne_porte`,
  énergie de départ 0,7, réglée par `lamp_energy` d'E9) et le panneau `wall_lantern` (lueur) ;
  les fenêtres de la façade s'allument par `window_glow` (lueur des panneaux : les vitres des
  remplaçants sont peintes près de `glow_color`, #FFE6A6, pour s'allumer la nuit) ; `fenetres_facade`
  reste un repère (Marker3D). Aucun lampadaire. Fumée de la cheminée toujours là (automne).
- **T1 — cartes d'attente (provisoires, phase 3)** : `village`, `colline`, `sentier`,
  `foret_profonde`, 32 × 24 m, sol plat assourdi de la bonne matière, une lisière au nord,
  l'écriteau « Plus loin, bientôt » (`src/world/props/waiting_sign.tscn`, texte dans
  `data/texts/story.json`, `maps/waiting`, lu par la boîte de dialogue sans portrait), la sortie
  de retour vers le marqueur de l'entrepôt et `from_entrepot`. Les lots de la phase 3 les
  remplacent (le lot T2 crée `Examinable` pour les objets à examiner : l'écriteau pourra le
  prendre).
- **T1 — raccourci** `?map=<id>&marker=<nom>` (Web) et `--map=` `--marker=` (ligne de commande),
  dans `src/test_shortcuts.gd` : la partie se pose sur la carte par `WorldManager.enter_map`.
- **T1 — densité mesurée** (un écran = 20 × 20 m autour du point visé, 7 m au sud, 13 au nord,
  décors debout et décalques) : cour 71, abords ouest 79, abords est 100, champ 45, clairière 52,
  bois 103, marais 119, rivière 104 ; aucun carré de 6 × 6 m nu hors des places. La place du duel
  ne porte que des décalques (traces, cailloux, feuilles).
- **T1 — mesures** (Xvfb, `tests/integration/demo_entrepot_dehors.tscn`, couchant ; nuit : +1) : draw
  calls façade 102, porche 95, cour 102, champ 84, clairière 73, marais 90, bois 116, grand arbre
  90, potager 102 à 121, sentier 94, rivière 102, vue large 125 (budget 200 ; `test_entrepot.gd`
  en borne le pire cas sur une grille de 6 m). Banc headless (`tools/map_bench.gd`, essai ⇄
  entrepot) : chargement 917 ms à froid, 429 ms à chaud, installation 211 à 249 ms, total 1,2 à
  1,7 s ; 4 112 nœuds, mêmes comptes à chaque visite, carte libérée au départ. Web (Chromium sans
  écran, SwiftShader, `tools/web_maps.js` avec entrepot puis essai) : chargement 1 270 ms en
  3 images, installation 849 ms ; 1 image/s et 117 draw calls dans l'entrepôt (l'ancienne île :
  1 image/s, 131 ; essai : 2) : le rendu logiciel compare, il ne mesure pas un vrai navigateur.
- **C5 — cahier des images n° 5** (`docs/ASSETS_HD2D_ILE68.md`) : inventaire par script (CARTE.md, VIE.md, ACTE1.md, cahiers n° 3 et 4, CONTRACT_REQUESTS.md contre `assets/**`, le manifeste et les JSON des planches ; remplaçant = pixels identiques au rendu de la recette) ; 8 lots dans l'ordre du jeu : R0 corrections et vues manquantes (tables en perspective conique, meubles sans vue de flanc ni de dos, règle `<nom>_side` vers l'est, `_back`, `_foot`, projection orthographique oblique à 32°), R1 entrepôt, R2 personnages de l'acte 1, R3 chemin du port, R4 hommes-bêtes et ville, R5 nature et faune, R6 temps et lumière, R7 navires ; priorités redéfinies (1 : une scène d'ACTE1.md la cite ; 2 : densité et vie ; 3 : bonus) ; noms proposés à confirmer par le moteur : `willem_marsh`, `willem_carry`, `willem_piggyback`, `willem_life`, `*_work`, `_side`/`_back`/`_foot`.

## X1 — Les îles et la surface (PR « contrats »)

- **X1 — `WorldAtlas`, classe statique** (`src/world/world_atlas.gd`), pas un autoload : aucune
  ligne de `project.godot` ; les fichiers de `data/world/` sont lus à la demande et gardés en cache,
  comme `QuestData` ; rien d'une partie n'y vit (l'île courante est dans `GameState`, le voyage dans
  `WorldManager`) ; elle sert aussi sans arbre (tests) et depuis un `@tool` (`MapGround`).
- **X1 — Appartenance d'une carte** : la liste `maps` du fichier de l'île fait foi ; `Map.island`
  la répète dans la scène (défaut `ile_68`, aucune carte existante n'a eu à changer sauf
  `ile_ancienne`) et `test_world_atlas.gd` vérifie l'accord. Une carte hors de toute île (cartes
  de test sous `tests/`) n'a pas de règle : `IslandRules.UNRULED`, le comportement d'avant X1.
- **X1 — L'ancienne île est une île à part** (`data/world/islands/ile_ancienne.json`, `legacy`,
  numéro 68, Timeres permis par ses règles) plutôt qu'une exception par carte dans `ile_68` : elle
  part en phase 5 avec son fichier et sa carte. La sortie de test essai ⇄ ile_ancienne change
  d'île sans voyage (`island_entered` émis).
- **X1 — Règles en deux couches** : celles du monde (`rules` de `data/world/worlds/<monde>.json`),
  puis celles de l'île ; une règle absente des deux prend sa valeur d'`UNRULED`. Clés :
  `enemies_allowed`, `fauna`, `void_below` (`clouds`, `ground`), `sky`, `void_fall` (`last_safe`,
  `arrival`). Une clé inconnue rend le fichier invalide (ignoré, avertissement), comme les quêtes.
- **X1 — Garde des Timeres** : `Enemy._ready` (tout Timere qui apparaît : libre, de vague, banc de
  performance) se retire sans `enemy_spawned` si les règles de sa carte l'interdisent ;
  `WaveDirector.start` ne lance pas la série ; `FreeEnemies` n'enregistre aucune population. Un
  Timere ajouté hors d'une carte (sous `Game`) suit la carte courante ; sans carte (tests
  unitaires), rien ne l'interdit.
- **X1 — Ciel par défaut (`sky`)** : un préréglage de `data/lighting/`, pris quand la carte n'a pas
  de `light_preset` et n'est pas un intérieur ; vide : le moment de la journée (Regule Aire). La
  surface prend `apres_midi` (V5 : « désert gris sous un ciel bleu ») et ne suit donc pas le
  moment : à revoir quand la surface vivra ses journées (un préréglage de surface par moment).
- **X1 — Le sol jusqu'à l'horizon** (`void_below = ground`) : `MapGround` pose un cadre de 3 km
  (`FarGround`) autour de la carte et de sa jupe, 4 cm sous le palier 0, avec le matériau même du
  sol : le shader borne ses lectures à la carte, la matière du bord se prolonge ; un draw call. La
  caméra (32°, 30° de champ) ne voit jamais l'horizon : ce sol remplit le haut de l'écran au-delà
  du bord nord, là où Regule Aire montre sa mer de nuages, qui n'est plus posée (même si la carte
  touche le vide).
- **X1 — Ports et quais** : un port = une carte et un marqueur ; le marqueur se nomme
  `from_dirigeable` (convention des `from_<origine>` ; `from_dirigeable_<suffixe>` s'il y a
  plusieurs ports sur la carte). On embarque à un `AirshipDock` (interactable, couche 6) posé sous
  un nœud `Docks` de la carte : `Exits` n'accepte que des `MapExit`. Port provisoire de l'île
  n° 68 sur la carte `essai` (deux quais : l'île d'essai, la surface) jusqu'à la carte du port
  (C-port, phase 3), qui reprendra l'id de port `essai` ou en déclarera un autre.
- **X1 — Le voyage** : `travel()` réutilise le changement de carte d'E1 ; la carte d'arrivée se
  charge sous la vue du ciel, par tranches de 12 ms (la vue reste fluide), et la vue dure au moins
  `travel_time` (3,2 s). La vue (`src/world/travel_view.tscn`) est un `CanvasLayer` (couche 90)
  posé à la racine puis libéré ; la 3D n'est pas dessinée dessous. Elle n'emploie que des images
  du jeu : le ciel peint du moment (préréglage de `GameState.moment`), la ligne des îles, une île
  lointaine, la mer de nuages (dégradé d'opacité par sommet), le dirigeable de la ligne
  (`airship_ferry`) qui tangue, des nuages devant. Texte : `story.json`, `travel/caption`
  (« En dirigeable, cap sur », puis le nom de l'île sur sa ligne : les noms d'îles commencent par
  une majuscule).
- **X1 — La chute** (`void_fall`) : `last_safe` ramène à la dernière place au sol (à 0,3 m près)
  à plus de 1,5 m du vide, relevée toutes les 4 images physiques ; la hauteur du sol sert de
  preuve, `is_on_floor()` du joueur immobile clignotant d'une image à l'autre. L'ancienne île garde
  ses zones (Spawn de la zone). La réapparition après la mort reste au marqueur d'arrivée.
  `test_m2_maps.gd` (rattrapage sur la carte d'essai) attend désormais le dernier point sûr.
- **X1 — Contenu par île** : `data/<kind>/<island_id>/<fichier>` (`WorldAtlas.data_path`) ;
  `find_data` retombe sur `data/<kind>/<fichier>` (les fichiers d'avant la convention restent
  lus) ; `data_dirs` donne le dossier de l'île puis le dossier commun. Rien n'est déplacé tant que
  E4, E5 et E6 travaillent : la migration est notée dans `docs/CONTRACT_REQUESTS.md`.
- **X1 — Les terres grises, remplaçant de couleur** : leurs matières (sable, roche, boue) sont
  teintées pour neutraliser leur jaune (teinte au-delà de 1 sur le bleu), leurs décors teintés
  `Color(0.66, 0.7, 0.8)` (`DecorPanel.tint`) ; les falaises (`cliff.png`) restent ocre : une face
  de roche grise est à commander avec les images de la surface.
- **X1 — Raccourcis** : `?island=<id>&port=<id>` (Web) ou `-- --island=<id>`, et F6 dans une
  version de débogage (île suivante de `WorldAtlas.islands()`, sans l'ancienne) ; `?timeres=` est
  refusé (une ligne au journal) là où les règles n'admettent pas de Timere.

## C1 — L'outil des cartes du dehors et le sentier (cartes `sentier`, `port` d'attente)
- **C1 — `tools/exterior_maps.py`** (`gen`, `check`, `places`, `props` ; mode d'emploi en tête du
  fichier et dans PLAN.md, « (C1) Les cartes du dehors ») : les scripts de travail de T1 (hors
  dépôt) sont repris, généralisés (`tools/exterior_pose.py` : la pose et la règle de caméra ;
  `tools/exterior_ground.py` : le sol déduit du plan ; `tools/exterior_recipes/<id>.py` : une recette
  par carte) et rangés dans `tools/`. **Preuve** : `gen entrepot` redonne `entrepot.tscn` à l'octet,
  sauf les quatre lignes `metadata/plan_target_*` des deux portes (la cible provisoire d'avant T2 n'a
  plus de raison d'être : elles ne s'écrivent que si la sortie est provisoire) ; le sol et les images
  de `data/maps/entrepot/` sont identiques ; `test_entrepot.gd` reste vert. `check` compare les fichiers
  écrits à ce que l'outil écrirait (code 1 sinon), liste les écarts au plan et les avertissements de
  la règle de caméra (quatre pour l'entrepôt, connus de T1 : marsh_snag, play_goal, thicket_c,
  firewood_pile, sans variante de premier plan).
- **C1 — sortie vers une carte absente** : provisoire si la recette en donne une (`provisional`),
  sinon omise (`omit_if_missing`) ; l'outil la remet dès que la carte existe (`gen` relancé). Le
  chemin de la ville du sentier n'a donc **pas de sortie vers `ville_haute`** tant que cette carte
  n'existe pas : un écriteau « Plus loin, bientôt » (`waiting_sign_fg`) au bout du chemin ; le
  marqueur `from_ville_haute` est écrit quand même. Une carte d'attente n'a que la sortie de retour
  vers une carte construite (le port : `vers_sentier`).
- **C1 — cartes d'attente par l'outil** : `village`, `colline`, `foret_profonde` redonnent les fichiers
  de T1 à l'octet ; leur nom, leur lieu, la sortie de retour et ses marqueurs viennent maintenant du
  plan (CARTE.md). Le **port** (`port`, 32 × 24 m, sortie `vers_sentier` → `sentier`, `from_port`,
  arrivée `from_sentier`) entre dans `ile_68.json` (`maps`, lieu `port`) ; le port provisoire des
  dirigeables reste sur `essai` jusqu'à la vraie carte (C-port).
- **C1 — sol du sentier** (`data/maps/sentier/plan.json`) : paliers du plan (lisière +1 m, marais et
  chemin de la ville −0,5 m), rampe de la ville, faces en talus de terre. Ajouts : deux descentes de
  la levée dans le marais (x 33 → 36 et 52 → 55, z 18 → 20, mousse sous les pieds) : on y descend
  sans sauter, comme les PNJ d'E4 ; eau basse du marais libre au milieu (rectangle bruité de 1,5 m),
  tourbe sur les berges, six îlots de tourbe où poussent les touradons ; berges du creux du chemin
  de la ville bruitées (faiblement : le bruit de `map_build` ne déplace le bord que d'une case) ;
  plaques de mousse et de feuilles au bord du sentier. `path_overgrown` (cahier n° 5, « à confirmer »)
  est peint en `chemin` (path_dirt_b) **sur la bande du chemin seulement** (1,8 m de terre dans la
  bande libre de 3 m), pas sur le rectangle de 14 × 16 m du plan au sud-est : un tapis de terre nue de
  cette taille contredit le sentier mangé d'herbe de V3.
- **C1 — décor du sentier** : tout le plan (aulnes, roseaux, touradons, souche, mares, nénuphars,
  pierres, racine, fougères de bord, voûtes, fourré) à ses cotes ; kits par bande (lisière : rang
  d'arbres devant cinq pans de 16 m ; deux pans dressés à l'ouest et à l'est du marais ; marais :
  rideau de roseaux, roseaux, massettes, touradons, mares, brume ; levée : pierres, herbes, fougères,
  feuilles, ombres de feuillage ; sud : grands troncs rares, buissons et fougères de premier plan ;
  fourche : forêt des deux côtés, mousse, cairn). Au sud du sentier la caméra est près des arbres
  (21 m, 32°) : **pas de grands arbres serrés** (un pin de 11 m à 5 m au sud du joueur couvre
  l'écran), deux troncs en tout et des arbres moyens à 8 m les uns des autres. Pas de lucioles
  (CARTE.md 4.2 : absentes en fin d'automne), pas de rais de lumière (leur image de nuit n'existe pas :
  le sentier de nuit resterait éclairé), pas de `stepping_stones` (pierres de gué bleutées : le
  sentier a les siennes, `path_stones_a/b`).
- **C1 — règle de caméra du sentier** : le rideau de roseaux (2 m) et l'écriteau d'attente (2,4 m)
  se dressent au sud d'endroits où l'on marche : variantes `marsh_reed_wall_fg` et `waiting_sign_fg`
  (premier plan, `tools/exterior_props.py`), que `Pose.place` choisit seule. Les deux voûtes de
  feuillage (`fg_canopy_a`) sont des panneaux de premier plan **posés en l'air** à 2,6 m : le premier
  plan accroché à l'écran (cahier n° 5 : « format à confirmer par E10 ») n'existe pas encore
  (docs/CONTRACT_REQUESTS.md). `test_sentier.gd` vérifie que ni mur ni décor opaque ne cache le joueur
  (pieds, taille, tête) depuis 1 546 places.
- **C1 — images du lot R3** : sept remplaçants au manifeste (lot `R3`, `tools/hd2d_sentier.py`,
  scènes dans `tools/exterior_props.py`) : `props/marsh_reed_wall` (384 × 192, raccord), `path_edge_ferns`
  (384 × 106, raccord), `path_root_step` (192 × 58), `fg_canopy_a` (768 × 384, ancre libre : un
  panneau en l'air), `decals/bog_pool_a` (288 × 192), `path_stones_a` (192 × 144), `path_stones_b`
  (144 × 96). Seul `hd2d_assets.py` change (`recipes()` lit le nouveau module). La tuile
  `ground/path_overgrown` et les images de prio 3 (`bog_pool_b`, `fg_canopy_b`, `willow_pollard`)
  ne sont pas dans le plan : non faites.
- **C1 — places de la vie en plus du plan** (`PLACES_WHY`, `Life/Places`, listées dans CARTE.md par
  `exterior_maps.py places`) : `sentier_ouest`, `sentier_milieu`, `sentier_est`, `fourche_ville`
  (passants de VIE.md), `marais_berge_ouest`, `marais_berge_est` (grenouilles, libellules),
  `corbeau_perchoir` (la souche), `lisiere_renard`, `merle_sol` (VIE.md, faune). Une scène de E4 ou
  d'E5 les prend par leur nom ; `premiere_embuscade` (16 ; 23) est celui d'ACTE1.md.
- **C1 — la nuit** : aucune lampe dans la carte (V1) ; la nuit est le préréglage `nuit` d'E9 (le
  `nuit_sans_lune` de CARTE.md n'existe pas : demandé dans CONTRACT_REQUESTS.md) et la lumière des
  fées du joueur (4 m). Mesure (luminance moyenne, capture 1280 × 720, vues milieu / embuscade /
  marais) : jour 0,32 / 0,32 / 0,30 ; nuit avec la lumière du joueur 0,12 / 0,12 / 0,11 sur l'écran,
  **0,23 / 0,20 / 0,18 autour du joueur** (un rond de lumière net sur un fond à 0,10) ; nuit sans
  lumière (`Atmosphere.LIGHT_OFF`) 0,11 / 0,11 / 0,10 partout : le sol et les roseaux restent devinés,
  on ne voit pas le sentier mais on ne se perd pas non plus. Le sentier est donc lisible avec la
  lumière des fées ; le noir complet de V1 serait un préréglage plus sombre (E9).
- **C1 — densité mesurée** (écran de 20 × 20 m autour du point visé, décors debout et décalques,
  `test_sentier.gd`) : entrée 97, ouest 113, milieu 108, marais 90, embuscade 114, berge 135, est 83,
  fourche 119, chemin de la ville 122 (plan : 80 à 120 ; la berge et le chemin de la ville, entre
  roseaux et mousse, jusqu'à 140). Aucun carré de 6 × 6 m nu hors de la place `embuscade`. De la vie
  dans chaque vue : roseaux qui ondulent (`reeds_sway`), feuilles qui tombent, oiseaux.
- **C1 — mesures** (Xvfb, `tests/integration/demo_c1.tscn`, couchant ; nuit : +1) : draw calls
  entrée 112, ouest 113, milieu 92, marais 45, embuscade 85, berge 96, est 102, fourche 108, chemin de
  la ville 126, vue large 111 (budget 200 ; la carte d'attente du port : 18) ; `test_sentier.gd` en
  borne le pire cas sur une grille de 6 m : 107 lots de décor + 45 d'ailleurs. Banc headless
  (`tools/map_bench.gd`, ile_ancienne → sentier ⇄ essai) : chargement 88 ms à chaud, 353 ms à froid,
  installation 188 à 260 ms, total 0,9 à 1,1 s ; 2 731 nœuds (l'entrepôt : 4 112), mêmes comptes à
  chaque visite, 0 échec.
- **C1 — tests** : `tests/unit/test_sentier.gd` (23 : plan, exports, sorties, marqueurs, points, marche,
  caméra, densité, sol nu, draw calls, aucune lumière, relief, décors et images R3, voûtes, places de
  la vie) sur la base `tests/stubs/c1_exterior_test.gd` (réutilisable par les cartes qui suivent),
  `tests/unit/test_exterior_maps.gd` (4 : `check` de l'outil, cartes d'attente, `port` dans l'île,
  listes de places), `tests/integration/test_sentier_in_game.gd` (1 : de l'entrepôt au sentier, au
  marais, à la rampe de la ville, au port d'attente, et retour).
- **E5 — Format de la faune** : une espèce est une ressource `.tres` (`AnimalData`, qui hérite
  d'`EnemyData`) dans `data/fauna/<île>/<id>.tres`, pas un JSON : ses attaques sont des `AttackData`
  (`data/fauna/<île>/attacks/`, et non `data/attacks/` : les chiffres d'un animal vivent avec lui) et sa
  planche un `SkinData` (`data/fauna/<île>/visuals/`), exactement comme un Timere. Le peuplement, lui, est
  un JSON par île (`peuplement.json`), vérifié clé par clé (`FaunaRules.problems`), comme les quêtes.
- **E5 — Un animal est un `Enemy`** : `Animal` (`src/fauna/animal.gd`) en hérite et réutilise son corps, sa
  Health, ses boîtes de coup, la préparation d'un coup (zone au sol), le recul et l'IA de poursuite. La
  garde des Timeres (X1) devient la méthode `Enemy._is_admitted()` : `Enemy` demande `enemies_allowed`,
  `Animal` demande `FaunaRules.allowed_at` (liste `fauna` de l'île, régions sans animaux). Les deux se
  distinguent par les données (une `AnimalData`, l'id d'espèce dans les règles), jamais par un nom ; un
  animal n'est donc jamais retiré comme un Timere, et ne passe pas outre les règles de son île. Seul
  changement dans `src/enemies/` : cette méthode et son appel.
- **E5 — Ce qui est un « ennemi »** : tout animal est dans le groupe `fauna` ; seuls les dangereux (loup,
  sanglier, ours) restent dans `enemies` (verrouillage, « Ennemis » du HUD). Un animal ne fait jamais
  `EventBus.enemy_killed` (aucune quête ni arène ne le compte) mais `enemy_spawned` et `enemy_damaged`
  restent émis (le bruit d'un combat alarme les paisibles proches).
- **E5 — Un animal vaincu s'enfuit** (`docs/lore/ACTE1.md`, 3.5, vérifié) : à zéro PV il ne meurt pas, il
  court loin de celui qui l'a frappé (`degats` un instant, puis `course`) puis rétrécit et disparaît ;
  `max_hp` est donc le nombre de coups avant la fuite (loup 3, sanglier 4, ours 10, tous les autres 1 :
  « un coup de bâton les fait fuir »). L'animation `mort` des planches n'est jamais jouée ; le cahier la
  garde (« une bête vaincue reste à terre, sans sang ») pour une scène du récit.
- **E5 — Moments** : le jeu en a cinq (`GameState.MOMENTS`) ; `VIE.md` dit midi = `matin`, soir et
  crépuscule = `couchant`. Loups : `couchant` et `nuit` seulement (absents le jour plutôt que « cachés » :
  ils ne sont pas dans la scène) ; ours : `matin` et `apres_midi` (il dort la nuit) ; cerfs : `aube` et
  `couchant` ; sanglier : `matin` et `couchant` ; renard : `aube` et `couchant` ; écureuil et corbeau :
  matin et après-midi ; merle : `aube` et `matin` ; chouette : `nuit` ; grenouille : jour et couchant ;
  papillons : matin et après-midi par beau temps, libellules : l'après-midi par beau temps. Un groupe de
  `peuplement.json` peut restreindre ces moments (`moments`), jamais les élargir.
- **E5 — Où l'on ne croise pas d'animaux** : `banned_regions` de `peuplement.json` (entrepôt, village, ville,
  port), vérifié par `Map.region` et par le lieu du fichier de l'île ; la liste `fauna` des règles de l'île
  dit quelles espèces vivent sur quelle île (aucune sur la surface ni sur l'ancienne île). Les merles de
  l'entrepôt, les corbeaux du port, les papillons des jardins (`VIE.md`, 6.3) restent des `AmbientSprites`
  de ces cartes (consigne de la mission) : ce lot ne pose d'oiseaux (des `Animal` qui s'envolent) que dans
  les cartes de bois, et ses papillons et libellules (`behavior = ambiant`) que là aussi.
- **E5 — Peuplement** : un nœud `Fauna` sous `Life` de la carte (`src/fauna/fauna.tscn`) et des marqueurs
  sous `Life/Places`. Au chargement tout est posé ; ensuite `EventBus.atmosphere_changed` renvoie les
  groupes hors de saison (les bêtes s'éloignent et disparaissent) et fait venir les autres, hors du champ de
  la caméra et à 14 m du joueur au moins ; un groupe qui a perdu des bêtes (fuite, envol) les retrouve au
  bout de `respawn_s` (40 s par défaut, 90 à 120 s pour les dangereux). `planned` garde le peuplement
  des vraies cartes (`VIE.md`, 6.3) qui n'ont pas encore leur nœud `Fauna`.
- **E5 — La meute** : chaque loup a un créneau sur un cercle de 3,2 m autour du joueur, qui tourne à
  0,6 rad/s ; un seul porteur du jeton s'approche (bond annoncé 0,5 s, puis morsure) et le rend en frappant
  ou touché, avec 0,9 s de pause ; la moitié de l'effectif de départ partie, le reste se débande
  (`ACTE1.md`, 3.5). Une meute alertée chasse jusqu'à deux fois la portée de repérage de chacun.
- **E5 — Sanglier et ours** : la charge du sanglier est le « bond » d'`Enemy` (attaque `rush`, sans dégâts,
  portée de déclenchement 8 m) avec 1 s de préparation (il gratte le sol : `broute`, la zone de la charge se
  dessine) puis un coup de boutoir au contact ; contre un `StaticBody3D` (arbre, rocher, bord de carte), il
  reste étourdi 2 s (`stun_s`). L'ours est `stoic` (l'épée ne le fait pas reculer), annonce son coup 0,8 s,
  avance à 1,2 m/s et abandonne la poursuite à 15 m de sa tanière (`leash_m`).
- **E5 — Bruit** : un paisible alerte ou fuit à des distances multipliées par 1,5 si le joueur court (au-delà
  de 5,5 m/s), par 0,6 s'il est immobile ; un combat (un autre animal ou le joueur touché) à moins de
  `combat_noise_m` (12 à 14 m) l'alarme. Le coup d'épée dans le vide ne fait pas de bruit (aucun signal :
  à ajouter par une PR « contrats » si le récit le veut).
- **E5 — Navigation** : `FaunaNav` ne connaît que le sol de la carte (`MapGround.is_walkable`, `level_at` :
  un cran de palier, 0,5 m, au plus par pas) et essaie des directions de plus en plus détournées ; les décors
  se contournent par la collision (`Enemy._detour`). Une carte sans `MapGround` n'a pour limite que sa collision.
- **E5 — Planches de remplacement** : `tools/gen_fauna.py` (appelé par `gen_placeholders.py fauna`), profil
  seulement ; hauteurs au repos et animations du cahier n° 5, section 7.3, dont les nombres d'images et les
  cadences proposés sont **confirmés tels quels**, avec `broute` (4 images, 4 ips, boucle) et `fuite` ; la
  1re image de `repos` mesure la hauteur du cahier à 96 px par mètre. Les trois insectes du lot R5
  (`butterfly_orange_b`, `dragonfly_amber`, `dragonfly_blue`) ont leur recette dans `tools/hd2d_anim.py`.
- **E5 — Carte d'essai `foret_essai`** : 56 × 40 m, sur `MapGround`, région `essai`, dans `maps` de l'île
  n° 68 (pas dans un lieu : comme `essai` et `essai_relief`), `?map=foret_essai` ; une terrasse d'un mètre au
  nord (clairière des loups, rampe), la clairière des cerfs, la souille, la tanière de l'ours, une mare. La
  vraie `foret_profonde` (80 × 60 m, `CARTE.md`) viendra plus tard : `peuplement.json` la prévoit.
- **I1 — 88 images livrées inscrites au manifeste** : navires (`docs/ASSETS_HD2D_NAVIRES.md`, lots L et S1 à
  S5, 48 images), cahier n° 4 (O1, O2, P, Q : 24), lot N (4 ciels, `cloud_sea_night`, `sun_window`, 3
  fenêtres de nuit) et le reste du lot I (`door_room_open`, `bed_curtain`, `towel_rack`, `butter_cake`,
  `hat_blue`, `dessert_flans`, `drying_frame`). Tailles réelles, genres (`tile`, `tile_h`, `panorama`,
  `decal` doux, `panel`), lot du cahier d'origine (clé `lot`, chaîne libre : `check --lot S3`), priorité
  du cahier (2 pour L, 3 pour S2 à S5 et Q : le cahier ne la donne pas). Aucune bande animée dans la
  livraison. Les images d'intérieur passent par les listes de `tools/hd2d_interior.py` (`SURFACES_I1`,
  `WALL_PANELS_I1`, `FURNITURE_I1`, `OBJECTS_I1`, `OUTDOOR_POLES`, `LOT_NAMES`) et `manifest` ; les
  ciels, `sun_window`, `deck_*` et `trail_ribbon_stake` sont des lignes du manifeste. `ground_atlas.png`
  reste la seule image sans entrée (générée) ; `test_hd2d_assets.gd` le garantit.
- **I1 — scènes de décor** : meubles et objets d'intérieur par `hd2d_interior.py scenes`
  (`src/world/props/interior/`) ; profondeurs choisies par taille faute de cahier (0,15 m pour
  `ship_tool_rack` et `ship_privacy_curtain`, coupés comme le mur ; 1 m pour `ship_boiler`…) ; objets de
  0,6 m au plus sans collision ni ombre (`ship_compass`, `ship_crystal_lamp` avec lueur, les 24 petits
  objets) ; `drying_frame` en plein air, deux poteaux comme sa bande. Pont des navires et piquet : lots
  `L` et `Q` ajoutés à `hd2d_scenes.py` / `test_hd2d_scenes.gd` (avec `N`), catégories `deck_cabin`
  (boîte de 2 m), `stake`, `deck_hatch` traversable (0,6 m), `deck_railing` en clôture, `deck_vent` et
  `deck_crates_lashed` ; les images sous `interior/` n'y passent jamais. Les moyeux des hélices de
  `hd2d_scenes.json` sont ceux des silhouettes refaites (la PR des navires avait changé le test, pas la table).
- **I1 — recettes de remplaçants** : une image livrée sous le nom d'un remplaçant fait foi et sa recette
  s'en va (40 recettes de `tools/hd2d_interior_props.py` et `door_armory` retirées ; 22 remplaçants
  d'intérieur restent, dont les 3 vues de flanc, listés dans docs/INTERIEURS.md) ; `hd2d_assets.py gen --force` et `gen <noms>` ne réécrivent
  jamais un fichier que sa recette ne dessine plus (`--overwrite-delivered`). Les ~400 recettes des
  cahiers n° 1 et 2 (`hd2d_ground`, `props`, `nature`, `town`…) restent, hors périmètre : la même garde les
  protège. `hd2d_assets.py orphans` liste les images sans entrée.
- **I1 — vues par le nom, orientation par le plan** : `<nom>_side`, `_back`, `_foot` se trouvent à côté
  de la face (`DecorPanel.view_texture`), aucune scène ne les nomme ; l'orientation est `facing` ou la
  rotation du nœud. Le plan (`regard=E|O|N|S`, CARTE.md) est la donnée : `interior.json` ne porte pas les
  meubles (ils sont dans la scène générée), le générateur écrit `facing` sur eux et les tourne d'un quart
  de tour autour de leur bord arrière quand la vue existe ; les murs de la pièce redisent l'orientation
  (`InteriorLayout.facing_against_wall`, tolérance 0,25 m, le mur le plus proche l'emporte dans un angle).
  18 meubles marqués : ceux du plan adossés à un mur est ou ouest dont le cahier commande un flanc (hors
  lits, escaliers, tas de papiers), plus `armchair_reading` vers le nord (il regarde la fenêtre) ; les
  lits ne sont pas marqués (aucun n'a la tête au nord dans les plans). Emprise tournée : profondeur
  d'échelle (`DEPTHS`) en x, largeur du plan en z ; un lit vu par le pied (N sans `_back`) est tourné de
  même autour de son bord nord. Remplaçants `_side` du canapé, de la grande bibliothèque et de l'armoire
  de Chtholly (recettes de `hd2d_interior_props.py`, tailles du cahier).
- **I1 — plan retouché pour les deux états (face et tourné)** : `carte_plans.py check` vérifie les deux ;
  canapé z 6,5 → 6,6, bureau enterré z 3,9 → 3,6, tas `paper_pile_c` z 5,0 → 5,1, grande bibliothèque
  z 6,4 → 6,5, point `archives_bureau` (23,35 ; 4,95) → (24,4 ; 4,9) (un disque de 1,2 m n'y passait plus
  entre le bureau tourné et le canapé), armoire de Chtholly au plan contre le mur sud (z 7,85) : elle
  remplace le `MOVED` de T2 (vide) et passe, tournée ou non, les tests de caméra. Essai de l'état « toutes les
  vues livrées » (29 images factices) : cartes de l'entrepôt, tests verts.
- **I1 — petits objets du cahier n° 4 posés** (13 sur 24) : cuisine (comptoir : jatte au fouet, broc de
  lait, panier d'œufs ; table : sac de farine, plat de beurre, moule à flan), lecture (lutrin),
  archives (encrier), infirmerie (plateau de flacons, bandages, cuvette), chambres (courrier, boîte
  de clous, bobines, pièce reprisée, panier de reprise) ; chacun dans l'emprise de son meuble de face
  et tourné. Pas posés : la scie et le rabot (aucun établi dans les plans de l'entrepôt) et le lot Q
  (accessoires de départ : à poser par les scènes S2).

## E4 — La vie

- **E4 — six créneaux pour cinq lumières** : la vie compte six créneaux (`GameState.SLOTS` :
  `aube`, `matin`, `midi`, `apres_midi`, `soir`, `nuit`, ceux de docs/lore/VIE.md, 0.1) ; leur
  lumière est un moment d'E9 (`LifeSlots.MOMENT_OF`) : midi garde celle du matin, le soir est le
  couchant. Le créneau est `GameState.slot` s'il va avec le moment, sinon celui du moment ; un
  moment posé ailleurs (F7, `Atmosphere.set_moment` du récit) l'emporte et efface `slot`.
  `LifeDirector.set_slot` pose les deux : le récit (E6) passe de matin à midi sans changer la
  lumière. `slot` et `day` sont des champs facultatifs du schéma de sauvegarde v3 (absents : `""`
  et 0), comme `moment` et `weather` ; pas de nouvelle version.
- **E4 — le jour de l'acte** : `GameState.day` (0 par défaut : aucun jour, les lignes à `day` ne
  s'appliquent pas), ajouté par E4 pour être lu ; c'est E6 qui le tiendra (`ACTE1.md`, 1 à 12).
- **E4 — choix d'une ligne** : les lignes à `day` ou `if` passent d'abord, puis les autres, la
  première qui va l'emporte : on écrit la journée de base, puis ses variations (VIE.md, section 3),
  dans l'ordre qu'on veut. Aucune ligne : le PNJ n'est nulle part.
- **E4 — `away` plutôt qu'une carte absente** : une ligne vers une carte pas encore construite
  (l'étage, la ville) dit `"away": "entrepot_etage"` ; la vérification refuse une `map` absente
  (une faute de frappe) mais accepte `away` (un identifiant). On quitte la carte par la place
  `vers_<carte>` (avant la `MapExit` vers elle) : dans le rez-de-chaussée d'essai, qui n'a pas
  d'escalier, `vers_entrepot_etage` est au bout ouest du couloir (provisoire).
- **E4 — le directeur peuple, les cartes ne listent pas leurs PNJ** : les PNJ de la vie naissent
  des emplois du temps (`data/life/`), ajoutés au nœud `Life` de la carte à son `map_entered` ;
  aucune scène de carte n'a à les poser. Une carte posée à la main (un test d'une carte seule)
  reste vide (`LifeDirector.attach` pour une démonstration) : les tests d'E2 et E3 ne changent pas.
- **E4 — PNJ réutilisés** : Willem, Nygglatho, Ithea, Nephren et les petites gardent leur
  `NpcData` (dialogues, quêtes, `visible_if`, skin du joueur absent) : le même personnage parle
  sur l'ancienne île et dans l'entrepôt d'essai ; une seule carte est chargée, il n'est jamais en
  double. Les quêtes et leurs marqueurs restent (E6 les retire).
- **E4 — planches complémentaires** (cahier n° 3, 4.1, « format à confirmer par le moteur ») : une
  tenue `<id>_life` est une `SkinData` dont la planche principale est la planche de base
  (`tiat.png` : repos, marche, parle) et la planche complémentaire (`extra_*`) `tiat_life.png` ;
  `SheetLoader` fusionne vue par vue (la planche principale l'emporte, la taille vient d'elle). Le
  check des planches vérifie que la rangée `repos` complémentaire est la copie au pixel près.
- **E4 — tenues** : `NpcData.outfits` (nom → chemin d'une `SkinData` de `data/npcs/outfits/`)
  plutôt qu'un tableau de ressources : une tenue n'est chargée qu'au besoin (`load_outfit`), et
  le cache de `SheetLoader` passe en références faibles (un jeu d'images vit tant qu'un visuel
  l'affiche ; quitter la carte libère ses planches). Les tenues ne sont ni dans `data/skins/`
  (jouables) ni dans `data/npcs/visuals/` (dont le nombre et les portraits sont testés).
- **E4 — le PNJ change de tenue au départ** (après son délai, avant de marcher) ; posé d'un coup
  (entrée sur la carte), il est déjà dans la tenue du créneau.
- **E4 — fées génériques** : `data/npcs/generic/fairy_01` à `fairy_06`, planche `fairy_0N`, un
  prénom original tiré de `data/texts/life.json` (« fairy_names » : Brisa, Fenna, Mirelle, Odile,
  Liesel, Tamsin, Ysolde, Pervenche, Clio, Nelka, Sabine, Vesna ; aucun de l'œuvre) ; sans
  dialogue : on leur parle, elles répondent d'une bulle (`talk/generic`). Hors de `data/npcs/` :
  `test_npc.gd` y attend la liste exacte des PNJ de l'acte 1 et leur dialogue.
- **E4 — le joueur garde sa planche dans l'entrepôt** : `chtholly_home` (livrée) n'a pas les
  animations de combat (`attaque`, `charge`, `degats`, `mort`) ; `LifeDirector.player_home_outfit`
  ne la pose donc pas (elle le fera seule si la planche les gagne ; le skin choisi par la
  communauté prime toujours). Demande au cahier n° 3 (docs/CONTRACT_REQUESTS.md).
- **E4 — marcher sans physique** : un PNJ de la vie est déplacé par le directeur (position posée à
  chaque image physique, hauteur du sol lue sur `MapGround.height_at` / l'étage), pas par
  `move_and_slide` : les chemins évitent déjà murs, meubles, falaises et talus, et les escaliers
  se montent sans pas de marche. Pendant qu'il marche, son corps quitte la couche 1 (structure
  figée : couche 1 à l'arrêt) : il ne bloque jamais le joueur, c'est lui qui l'évite.
- **E4 — navigation** : `AStar2D` (C++, mono-thread) sur une grille d'un mètre dehors, d'un
  demi-mètre dedans ; deux cases sont reliées si les points de mesure entre elles sont
  praticables et que le sol ne monte ni ne descend de plus de 0,3 m de l'un au suivant (escaliers
  et rampes oui, talus de 0,5 m et falaises non) ; diagonales seulement si les quatre côtés le
  sont. Dedans, l'épaisseur des murs est relevée une fois en bitmap (8 px/m) et la réponse exacte
  d'`InteriorRoom.is_walkable` n'est demandée qu'au bord d'un mur (testé : mêmes réponses). Les
  meubles : leurs formes de collision (couche 1), élargies de 0,2 m, dans la tranche du corps.
  Construction découpée (3 ms par image) après l'entrée, en petits pas (une pièce de mur, un
  décor, huit cases d'une rangée : le pas le plus long reste court dans le build Web), et
  seulement sur une carte qui a des places ou des PNJ (pas l'ancienne île) ; chemins en file
  (deux par image), lissés par le parcours des cases du graphe, puis le segment retenu vérifié.
- **E4 — évitement** : face à un PNJ qui vient, chacun garde sa droite ; un PNJ arrêté ou le
  joueur juste devant : un pas de côté, puis un autre chemin qui évite sa case au bout de 0,8 s ;
  sans progrès 7 s, on se replace d'un coup au but. Personne ne bloque plus de 2 s un passage
  (VIE.md, 0.4) : un PNJ debout que le joueur pousse s'écarte de 1,3 m, puis revient.
- **E4 — places et sièges** : un siège devant une chaise vue de face est posé 0,4 m au sud du
  pied de la chaise (le PNJ se dessine devant son dossier et derrière la table) ; derrière une
  chaise vue de dos, au pied de la chaise ; les planches `assis` sont ancrées au sol sous
  l'assise.
- **E4 — l'avalanche se déclenche à l'approche de la porte** (à 1,5 m de son milieu) ou quand le
  joueur bouscule l'une d'elles : les portes d'essai ne s'ouvrent pas (images), et c'est en
  arrivant à la porte qu'on l'ouvrirait. La porte est donnée par ses deux pièces
  (`["couloir", "nygglatho"]`) : celles d'`entrepot_rdc_essai` n'ont pas d'id, et en ajouter
  demanderait des `MapExit` (règle d'E3).
- **E4 — sorties d'essai** : `entrepot_rdc_essai` gagne une sortie à invite dans l'entrée
  (« Sortir dans le pré (essai) », vers `essai_relief`, marqueur `from_essai_relief`), la porte
  d'entrée menant toujours à l'ancienne île (tests d'E3) ; les PNJ, eux, sortent par la porte
  d'entrée (place `vers_essai_relief`). `essai_relief` gagne une sortie au bout sud du sentier
  (vers l'intérieur d'essai, marqueur `from_entrepot_rdc_essai`).
- **E4 — touche F6** : créneau suivant (Maj : tout de suite), comme F7 (moment) et F8 (temps), en
  version de débogage ou avec un paramètre de développement.
- **R2 — raccord des livraisons R0 (PR n° 34) et d'I1** : la fusion avait perdu deux lignes de `InteriorPanel` (matériau `InteriorRoom.furniture_material`, et `occluder_triangles` qui lit `furniture_cut_line`), donc les meubles ne se coupaient plus au sud du joueur dans sa pièce ; rétablies sur la base d'I1 (`displayed_texture()`, `cut_z()`). Le coffre à jouets (`toy_chest`), tourné par sa vue de flanc livrée, touchait presque le mur nord : plan décalé à (22,3 ; 11,4) pour que les murs le fassent regarder O.
- **E8 — le ballon est une balle faite à la main** (`GameBall`, src/games/ball.gd), pas un `RigidBody3D` : pesanteur, rebond (62 % de la vitesse), roulement qui freine, murs et cages tiennent en quelques lignes, donnent les mêmes résultats sur tous les navigateurs et se laissent avancer plus vite que le temps (les tests jouent deux minutes de match en une seconde). Un joueur qui court contre lui le pousse ; la frappe d'épée l'envoie dans sa visée (`player/kick_*`), sans mal pour personne.
- **E8 — le match** : `BallMatch` (src/life/games/ballon.gd) hérite de `BallPlay` (src/games/ball_play.gd : terrain, équipes, IA, frappes) parce qu'une classe de plus de 1000 lignes échoue au lint. Le terrain est un rectangle de 18 × 20 m centré sur la place `champ_centre` (les places `champ_but_nord` et `champ_but_sud` donnent le poste des gardiennes) : les blanches défendent le nord en première mi-temps, on change de côté à la mi-temps ; au plus 5 joueuses par équipe sur le terrain (4 et une gardienne), les autres assises au bord ouest ; à la mi-temps la meilleure buteuse de chaque équipe reste, les remplaçantes entrent (V5). On attend les retardataires deux secondes avant de composer les équipes (les petites arrivent une à une : sans cela les dernières arrivées ne joueraient pas).
- **E8 — Willem arbitre, il ne joue pas** (la ligne a `role: arbitre`) : VIE.md le fait aussi passer le ballon, mais un arbitre qui joue ne peut pas faire cesser le jeu ; il suit la touche est, annonce le coup d'envoi, les buts, la mi-temps et la fin. Ses passes restent à faire si V1 veut un Willem joueur (rôle `rouge` ou `blanc`).
- **E8 — le ballon du jeu remplace le ballon du décor** : le plan du champ pose un panneau `ball` au rond central, fondu par le PropBatcher ; au début d'un match `GameBall.hide_decor_ball` retire ses triangles du lot fondu de la carte instanciée (sans cela il y aurait deux ballons). Retirer ce ballon du plan (CARTE.md) est demandé : docs/CONTRACT_REQUESTS.md, « E8 ».
- **E8 — le bâton est un équipement que le récit choisit** (`Player.set_weapon(&"baton" | &"seniorious")`, décision de D2) : Seniorious par défaut, pour que l'ancienne île, ses Timeres et ses tests gardent l'épée et la charge ; le récit (E6) donne le bâton au début de l'acte 1 et Seniorious aux scènes désignées. Bâton en main : les trois coups de `data/attacks/stick_1..3.tres` (mêmes chiffres que l'épée : la faune de E5 reste combattable), pas de charge de venenum, et la touche de charge (clic droit) **tient la parade** : aucune nouvelle action d'entrée, donc project.godot ne change pas. L'arme n'est pas sauvée (GameState est un contrat) : le récit la redonne au chargement.
- **E8 — l'animation `pare` est acceptée** pour les planches `_stick` du cahier n° 5 (R2) : 2 images, 2 ips, en boucle (la parade tenue) ; sans elle, la charge image 0. Chtholly à bout de forces s'assoit (`assis`, sinon `degats` : l'animation `mort` est la vraie mort du joueur, jamais jouée à l'entraînement) ; sans planche `_stick`, le bâton garde l'animation d'épée et n'est pas dessiné en main.
- **E8 — l'entraînement lit trois réponses, sans nouvelle commande** : bloquer (parade tenue à l'impact), dévier (parade relâchée dans les 0,15 s avant l'impact, qui découvre Willem 0,5 s), esquiver (sortir du cercle de 0,9 m annoncé au sol 0,5 s avant). Un coup reçu est un coup de bâton : une touche de plus à la jauge (6 en phase A, 3 contres en phase B), aucun `Health` touché. La déviation d'une contre est permise aussi à Chtholly (ACTE1.md ne dit que « esquiver » : la parade tenue n'y suffit pas, la déviation oui) et une aînée dévie une contre une fois sur deux. La fenêtre se ferme au jour 10 (signal `window_closed` : le rythme tremble, effet d'E9).
- **E8 — lancer un jeu** : `MiniGames.start_ball_match` / `start_staff_training` (fonctions statiques, ni autoload ni PR « contrats ») renvoient le jeu (`BallMatch`, `StaffTraining`) dont les signaux `match_finished(résultat)` et `finished(résultat)` disent la fin ; ils posent les PNJ absents de la carte (`LifeDirector.spawn_actor`) et les rendent à leur emploi du temps ensuite. Le raccourci de développement `?jeu=ballon|baton` (src/test_shortcuts.gd) pose la partie sur l'entrepôt au bon moment (après-midi, matin) et lance le jeu.
- **V1 — contenu de la vie par île** : `LifeData` lit `data/life/<île>/` (`WorldAtlas.data_dirs`), l'île de la carte que le directeur peuple (`LifeData.enter_island`, posée par `LifeDirector.attach` : `map_entered` précède `island_entered`), sinon `GameState.island`, sinon l'île n° 68 ; `activities.json` reste commun (`data/life/`). Une île sans dossier (l'ancienne île) n'a aucune vie. `LifeData.use_content(&"essai")` force un sous-dossier : les emplois du temps de démonstration d'E4 (cartes d'essai) vivent dans `data/life/essai/` (copiés avant la migration ; tests et démonstrations d'E4 les forcent) ; paramètre de développement `?contenu=essai`.
- **V1 — créneaux et repas** : un seul créneau `matin` pour le petit-déjeuner, donc le réfectoire est plein au `matin` (12 à 14 PNJ) et au `midi` (21) ; ce que VIE.md place « le matin après le petit-déjeuner » (entraînement de base, linge, potager, grand arbre) est tenu par ceux qui ne déjeunent pas au réfectoire à ce créneau (le linge à l'aube **et** le matin, l'arbre, le potager, la corvée de la cour), et l'entraînement du champ n'a lieu que les jours 9 à 12 (menées par `fairy_10`) ; le ballon (après-midi, jours 5 à 12) est laissé au lot E8 : en attendant, Willem et trois fées sont dans le champ (`champ_jeu`, `errer`).
- **V1 — dortoirs** : `CARTE.md` (« Qui dort où ») l'emporte sur VIE.md, 2.4 : le quatuor Tiat, Collon, Pannibal, Lakhesh au dortoir A, Almita (Kana et Giniette absentes) et `fairy_01`, `fairy_02` au B, `fairy_03` à `fairy_07` au C, `fairy_08` à `fairy_12` au D ; un PNJ par lit (`dortoir_a_lit_1_bas`…), le dormeur à 0,45 m (lit simple ou du bas) ou 1,35 m (lit du haut) ; les lits du plan prennent cette hauteur (`tools/life_zones.py`).
- **V1 — places** : les zones, les départs `vers_<carte>` (le premier de chaque carte est le repli des cartes à venir : la porte d'entrée, le pied de l'escalier, le seuil du porche ; des alias vers l'étage, le toit, la ville, pour que les trajets sans correspondance finissent à la porte ou à l'escalier) et l'orientation des points du plan sont dans `tools/life_zones.py`, lu par `tools/interior_maps.py` et `tools/exterior_maps.py` (jamais à la main dans une scène générée) ; `CARTE.md` en donne la liste (`places`). Seuls les sièges où l'on arrive sans traverser une table sont des places : le rang du fond du réfectoire (z = 7,9) n'en a pas. Les trois branches du grand arbre sont des zones à un point de hauteur 2,3 m, 4,3 m et 6,6 m (images de l'arbre, 96 px par mètre) ; la jupe de racines, trois points au sol.
- **V1 — pluie** : `LifeDirector` tient deux drapeaux d'après `GameState.weather` : `pluie_du_jour` tant qu'il pleut (pluie, averse), `apres_pluie` quand elle cesse, jusqu'à l'aube suivante ; les lignes `{"if": {"flag": "pluie_du_jour"}}` font rentrer tout le monde (salle de jeux, lecture, balle contre le mur), `apres_pluie` envoie les petites sauter dans les flaques du champ (`boue`). Le récit (E6) peut aussi poser ces drapeaux.
- **V1 — navigation** : `LifeNav.nearest_open` ne choisit plus, dedans, une case de l'autre côté d'un mur (un lit contre la porte d'un dortoir finissait dans le couloir) ; correctif sûr, éprouvé par `tests/unit/test_life_ile_68_nav.gd`.
- **V1 — jours** : `GameState.day` 0 (aucun jour) joue la journée de base ; les variations de VIE.md, section 3, sont des lignes à `day` : fuite (1 à 3), en ville (3), dessert (4, 6, 9, 11), aînées absentes et petite blessée (7 à 9), fièvre de Willem (8), entraînement (9 à 12), café et chasse à l'ours (9), horloge (11), départ (12). Les soirs, la tour de fées a lieu aux jours 0, 10 et 12 ; les jours 1 à 9 et 11, jeux de société. Un trajet qui change de carte s'arrête à la sortie de la carte courante (l'étage vers la ville : l'escalier) : le directeur ne suit pas la correspondance entre cartes.
- **C3 — la colline par l'outil** : `colline` passe de `WAITING` à `RECIPES` de `tools/exterior_maps.py`
  (recette `tools/exterior_recipes/colline.py`) ; `gen colline` écrit le sol (`data/maps/colline/`, avec une
  `structures.png` de plus : les rampes) et la scène ; `check` la reconnaît. L'outil gagne trois réglages de
  recette (`camera_bounds`, `light_preset`, `fauna` ; `no_lights` est celui de C2), la liste des places d'une carte
  de C3 (`PLACES_LOT`), et `Pose.height` rend 0 sur une case du vide.
- **C3 — lumière** : CARTE.md 7 et ACTE1.md 8.8 disent `nuit_claire`, que `data/lighting/` n'a pas ; le
  préréglage d'E9 qui est une nuit claire est `nuit` (PLAN.md, E9 : « `nuit` : la colline, une nuit claire »).
  `light_preset = &"nuit"` : la colline est de nuit quel que soit le moment (de jour, on y monte dans la nuit
  claire ; l'entrepôt retrouve le moment à la sortie). Les deux lignes `lumiere` du plan (`cristal_reglage`,
  `talismans`) ne sont pas écrites : la carte ne porte aucune lumière (consigne du lot) ; la lueur est celle
  de la scène de l'acte 1 (8.8). Un préréglage `nuit_claire` plus doux : docs/CONTRACT_REQUESTS.md.
- **C3 — bornes de la caméra** : `Rect2(10, 6, 20, 26)`, pas le `Rect2(10, 6, 20, 23)` du plan : avec 23, le point
  visé s'arrête à z = 29, la vue ne descend qu'à z = 36 et le joueur sortait de l'écran sur le bas du chemin
  (arrivée en z = 36,5, sortie en z = 39,4). z = 6 au nord (la vue sur le vide), z = 32 au sud (règle P − 8).
  Reporté dans CARTE.md (7) ; le socle de test accepte des bornes propres à la carte
  (`expected_camera_bounds`).
- **C3 — relief** : les paliers du plan (+1, +2, +3 m) sont prolongés au nord jusqu'au bord du vide (le plan
  les arrête à z = 4, ce qui laissait un replat de niveau 0 sous le sommet, une falaise de 3 m tournée vers la
  mer de nuages) ; le vide est une côte irrégulière autour de z = 2,5 (le bord `falaise 0 3 40 4` du plan ferme
  la bande de z = 3 à 4, le joueur s'arrête à 1 m de la côte) ; rampes en herbe ; la terre du chemin
  (`path_dirt_b` du plan, rectangles) n'est peinte que sur la bande du chemin (1,8 m, bords francs) : le
  rectangle de 12 → 28 × 26 → 30 touchait le pied du talus de 1 m, et `map_build` refuse un chemin qui longe
  une marche de plus de 0,5 m ; lisières ouest et est en sous-bois.
- **C3 — décor** : pas de `forest_wall_*` ni d'arbres devant le vide (une lisière au nord flottait sur la mer
  de nuages) ; les pans de la lisière ouest et est se dressent au-delà du bord (x = −4,5 et 44,5), un rang
  d'arbres devant ; au sud, grands troncs de premier plan seulement aux deux bouts du bord (au milieu, ils
  cachaient la montée) ; `lone_tree_fg` et `boulder_a_fg` (premier plan, `tools/exterior_props.py`, ajoutés en
  fin de table) pour la règle de caméra. Rochers du bord (`edge_rocks_*`) de part et d'autre du cercle, jamais
  devant lui : la vue au nord reste ouverte. Le cercle ne porte aucun décor debout (la scène s'y joue).
- **C3 — images** : toutes celles du plan sont livrées, aucun remplaçant n'est nécessaire pour la carte ;
  `anim/talisman_float` (cahier n° 5, lot R6, cité par CARTE.md 7 et ACTE1.md 8.8, posé par la scène et non
  par la carte) a un remplaçant (`tools/hd2d_colline.py`, 24 × 24 px × 4, manifeste), à remplacer par la
  livraison sans toucher au code.
- **C3 — faune** : les trois groupes de la colline (merles à l'aube et le matin, papillons, chouette) passent
  de `planned` à `maps` dans `data/fauna/ile_68/peuplement.json`, avec leurs marqueurs dans `Life/Places`
  (`merles`, `papillons`, `chouette` ; au lieu de `sommet` : le sommet est la scène des talismans, la chouette
  est à l'arbre solitaire et les merles sur la terrasse haute) et le nœud `Life/Fauna`.
- **C3 — vie** : places en plus du plan, `PLACES_WHY` : `vers_entrepot` (le départ vers l'entrepôt, devant la
  sortie), `pied_de_colline`, `arbre_seul`, `merles`, `papillons`, `chouette`. Willem y monte au soir du jour 8
  (`away: colline` dans `data/life/ile_68/willem.json`) : sa place sur la carte (`talismans_centre`, `dos_a_dos`)
  est à écrire par E6 et la scène.
- **C3 — densité et mesures** : 42 à 67 éléments par écran (CARTE.md 7 : 40 à 70) ; au plus 68 lots de décor
  fondus dans le champ (grille de points de vue) et 113 draw calls avec le reste (budget 200) ;
  Xvfb, `tests/integration/demo_c3.tscn` : 40 à 82 draw calls selon la vue, la nuit comme le jour.
- **C2 — la porte du café est à x = 19,8** (sortie `porte_cafe` 19,1 → 20,5, marqueur `from_cafe`, point
  `cafe_porte`), au droit de la porte de la façade livrée (`cafe.png`), au lieu de 18,5 du plan ; CARTE.md
  est corrigé en conséquence (idem `hanging_sign_key` à 12,7 et `firewood_pile` à 4,5, qui tombait dans le
  ruisseau). Les écarts de la carte sont dans la liste des écarts de la recette `village.py`.
- **C2 — le café a sa scène `cafe_village`** (7 × 6 m, mur 5,5 m, faîte 7,5 m) : celle de T1 pose trois
  tables de terrasse bloquantes dans la place `devant_cafe`, qui doit rester libre. `BUILDING_SCENES` de la
  recette donne la scène d'un bâtiment du plan qui n'a pas le nom de son image.
- **C2 — jardins clos et bords invisibles** : un toit de 5 m cache 7 m au nord de lui, et la règle de caméra
  veut que rien où l'on marche ne soit derrière un toit ; les jardins derrière les trois chaumières du sud
  sont donc clos (`Edges` invisibles, clôture de branches au nord, haies sur les côtés) et les trous entre
  bâtiments sont fermés par des haies et buissons visibles (jamais une collision seule qui se voit mal).
- **C2 — variantes de premier plan nommées `*_front`** (`scarecrow_front`, `firewood_pile_front`) : un `*_fg`
  libre est découvert par l'outil comme variante de la règle de caméra et changeait la scène de l'entrepôt ;
  `*_front` n'est pas un suffixe de cette règle, la recette de `village` les pose à la main.
- **C2 — aucune lumière dans les trois cartes** (règle de la mission) : ni lampe ni fenêtre lumineuse ; la
  nuit, Atmosphere et la lumière magique du joueur. `no_lights` dans `SETTINGS` d'une carte du dehors supprime
  le nœud `Lights` ; le café n'a donc pas de vitres allumées de nuit (demande dans CONTRACT_REQUESTS.md).
- **C2 — la porte de la maison Limashenka est posée ouverte, sa condition (jour 11) est en métadonnée** de
  la sortie (`open_from_day = 11`, `closed_text_key = "village/maison_close"`) : `MapExit` ne sait pas se
  fermer et n'est pas à C2 (demande dans CONTRACT_REQUESTS.md). L'examen `maison_close` donne le texte de
  la maison close.
- **C2 — `door_backroom`** (rideau rayé entre la salle du café et l'arrière-boutique) est une porte à image
  propre (`OWN_IMAGE_DOORS` de `interior_maps.py`) ; `door_room` des intérieurs a un côté « dehors » (`OUTSIDE_DOORS`).
- **C2 — `BLOCKERS["cafe"]`** : la vitrine à gâteaux masque la taille de qui se tient derrière le comptoir ;
  une zone bloquante `derriere_vitrine` (4,7 → 5,3 ; 1,8 → 2,55) l'interdit, la place `comptoir_arriere`
  restant libre à côté.
- **C2 — portrait de famille 58 × 77 px** (`wallitem_family_portrait`) : l'image la plus grande qui tienne
  sur le mur du salon à 96 px par mètre sans passer sous l'horloge ; `test_hd2d_assets` la compte (CARTE.md
  le mentionne).
- **C2 — l'horloge du salon** a trois états (`wallitem_clock_limashenka` fermée, `_open` ouverte,
  `anim/clock_limashenka_swing` : balancier de 4 images à 2 images/s, mêmes pixels du cadran : `random.Random(4242)`
  fixe) ; le récit (E6) les échange au jour 11 au point `horloge`. La scène `clock_limashenka_swing` est prête.
- **C2 — 38 remplaçants au manifeste, lot R3** (`tools/hd2d_village.py`) : 19 pour le dehors (matériaux
  `roof_thatch`, `wall_wattle_daub` ; chaumières `cottage_thatch_a/b/c`, `village_barn`, `village_house_stone`,
  `village_shed` avec leurs `_side` ; `fence_wattle`, `beehives`, `cart_hay`, `haystack`, `washing_trough`) et
  19 pour les intérieurs (sol `floor_terracotta`, `wall_panel_dark`, `wall_wallpaper_floral`, `door_backroom`,
  `window_shutters`, `wallitem_menu_cafe`, `wallitem_clock_limashenka` (et `_open`), `wallitem_family_portrait`, `cafe_counter`,
  `cafe_table_heavy`, `cafe_bottle_shelf`, `cafe_drinkers_table`, `toolbox_gears`, `side_table_salon`,
  `juice_glasses`, `cafe_cake_case`, `decals/rug_salon`, `anim/clock_limashenka_swing`). Une image livrée
  du même nom les remplace sans toucher au code ; `--force --overwrite-delivered` n'est que pour refaire un
  remplaçant.
- **C2 — outils touchés hors des cartes** : `exterior_maps.py` (réglages `no_lights`, `examine`, `exit_meta`,
  `PLACES_LOT`), `exterior_pose.py` (`Pose.height` rend 0 sur une case de vide), `exterior_props.py`
  (`building()`, décors du village), `interior_maps.py` (cafe, maison, `image_size_m` cherche aussi
  `props/`), `tests/stubs/t2_map_test.gd` (`expected_region`, `texts_path`, `OWN_IMAGE_DOORS`) ;
  `test_waiting_maps`, `test_exterior_maps`, `test_hd2d_assets`, `test_hd2d_scenes` suivent (le village n'est
  plus une carte d'attente ; 27 façades latérales au lieu de 21), sans rien relâcher.
- **C2 — mesures** : draw calls du village entre 78 et 139 par vue du jeu (≤ 200 ; la vue d'ensemble, hors
  jeu, 271), café 32 à 46, maison 29 à 41 ; chargement du village 390 à 600 ms, café 173 ms, maison 104 ms.

## I2 — l'entrepôt complet (lot R1 du cahier n° 5)

- **I2 — dix images inscrites, vingt-neuf remplaçants retirés** : la PR n° 37 livre 39 images ; 29 portaient le nom
  d'un remplaçant déjà au manifeste (façades et flancs de T1, `door_frame_wood`, sols et murs de la crypte,
  décalques, bandes animées, piano, trappe, échelle, coupures, fenêtre poussiéreuse, six panneaux du dehors) : leurs
  recettes s'en vont (`hd2d_interior`, `hd2d_interior_props`, `hd2d_town`, `hd2d_nature`) ; il ne reste que les trois
  vues de flanc de R0.3. Les 10 nouvelles passent par `LOT_NAMES["R1"]`, `SURFACES_R1`, `FURNITURE_R1`,
  `OUTDOOR_R1`, `ANIMS_R1` (`tools/hd2d_interior.py`) et `manifest` : `desk_clean`, `desk_chtholly_mirror_up`,
  `polishing_trestle`, `potted_plant`, `bed_iron_cover` (meubles), `roof_edge_slate` (panneau, `wrap` x),
  `floor_roof_deck` (tuile), `bath_steam` (6 images, 6 ips, alpha doux), `comm_crystal_call` (4, 6 ips),
  `wall_clock_swing` (4, 2 ips). `hd2d_assets.py check`, `orphans` et `hd2d_sheets.py check` propres.
- **I2 — le toit-terrasse : matière à part, pas de 28e couche** : une 28e tuile d'atlas toucherait le contrat du
  cahier n° 2 (`IslandTerrain.GROUND_LAYERS`, deux shaders et leurs tables de repli, `terrain.gd`, tests de
  27 tuiles, atlas). Le sol de `MapGround` reste (planches de l'atlas, dessous, sans trou) et `floor_roof_deck` s'y
  pose en 12 `GroundDecal` bout à bout (3 × 4 tuiles de 4 m, étirées à 3,5 m dans le sens des planches pour couvrir
  les 14 m sans dépasser du bord) ; un draw call de plus (le `PropBatcher` les fond en un) ; les taches de mousse
  passent à la couche 1 pour rester dessus. `roof_edge_slate` : deux panneaux de 4 m au pied de l'égout sud du volume
  ouest (x 1 et −3, z 15), sans collision (derrière la rambarde) ; le toit d'ardoise du `Building` reste, c'est lui qui
  monte vers le faîte.
- **I2 — bande animée au mur ou sur un meuble** : `bath_steam` est un `objet` sur la baignoire (bas de l'image 0,3 m
  sous son rebord) ; `wall_clock_swing` remplace l'élément de mur `wallitem_wall_clock` dans le plan (les
  éléments de mur sont fondus en un maillage sans animation) : `mural` de nom hors `wallitem_`, DecorPanel
  `keep_orientation` qui regarde l'est ; `comm_crystal_call` reprend `comm_crystal` au pixel près (pied au sol) et
  est **caché** (un appel est un événement, pas un décor) : E6 le montre. L'horloge regardée de face est vue de
  chant par la caméra (mur ouest) : on ne voit son balancier que dans la pièce.
- **I2 — meubles posés** : `desk_clean` à la place de `desk_clean_brooch` (grande sœur ; la variante à broche reste pour
  le souvenir du jour 6), `potted_plant` dans l'entrée, `polishing_trestle` dans la salle des armes ;
  **non posés** : `desk_chtholly_mirror_up` (acte 2) et `bed_iron_cover` (surimpression sur un dormeur : à
  poser par l'histoire ; scène sans ombre, avec la boîte de collision du lit). `carte_plans.py check` : 23 cartes,
  0 erreur ; CARTE.md : ASCII, places et inventaire réécrits.
- **I2 — vitres des façades livrées** : de nuit, elles s'allument à peine (carreaux de #FBD367 à #FCE496 à 0,14 de
  `glow_color` #FFE6A6 pour une tolérance de 0,12 : 15 % des pixels de vitre à l'ouest, 1 à 2 % à l'est). Image non
  retouchée ; correction à commander dans `docs/ASSETS_HD2D_ILE68.md` (3.6) et variante moteur
  (`Building.window_glow_color`) dans `docs/CONTRACT_REQUESTS.md`.

- **E6 — le récit est fait de données** : `data/scenes/<île>/act.json` (l'acte en jours : début, lit,
  repos, calendrier, jours) et une scène par fichier (déclencheur, conditions, présents, étapes),
  répliques dans `data/dialogues/<île>/`, textes courts dans `data/texts/<île>/story.json`. Un seul
  autoload ajouté (`StoryDirector`) ; `StoryRunner`, `StoryStage`, `StoryDialogue`, `StoryPrompt` en
  sont des enfants ou des outils. Le format se vérifie sans lancer le jeu (`StoryData.all_problems`),
  une clé inconnue est refusée (sauf `_…`).
- **E6 — nouvelle partie** : `WorldManager.START_MAP` devient `entrepot` (= `arrival_map` de l'île
  n° 68) ; l'acte s'ouvre à `game_loaded` d'une partie neuve (`SaveManager.started_new`, carte vide,
  jour 0, aucune scène jouée) et pose jour 1, nuit, grand vent. Une sauvegarde dont la carte n'est
  pas connue et qui n'a pas d'acte reprend sur `LEGACY_MAP`, avec ses quêtes, sans récit.
- **E6 — le temps n'avance que par les scènes et par le joueur** : « Dormir » au lit le soir ou la
  nuit quand les scènes de `sleep_after` sont faites ; « Laisser passer le temps » un créneau à la
  fois, jamais au-delà du créneau de la prochaine scène clé du jour ni au-delà de la nuit.
- **E6 — le calendrier remplace le journal pendant l'acte** (Tab / L / Select, menu pause, examen du
  calendrier de la chambre) : 12 cases, jours passés rayés, jour du départ entouré, la ligne du jour
  écrite au coucher (une ligne posée par une scène n'est pas réécrite).
- **E6 — quêtes à collecter tues pendant l'acte** : `QuestTracker` ne démarre rien, le HUD cache
  l'encadré, le journal et les « ! » / « ? » (`GameState.story_running()`) ; leur code et leurs
  données restent pour l'ancienne île.
- **E6 — cartes manquantes** : le port (carte d'attente de C1) et la ville (`ville_haute`, le
  snack-bar) ne sont pas jouées : `j1_1_port`, `j3_2_chemin` et `j3_3_snack` se racontent en fondu
  et cartons ; aucune carte inventée.
- **E6 — combats** : une étape `game` (crochet d'E8 : `StoryDirector.register_game`) et ses étapes
  de repli (courte séquence sans contrôle) ; l'embuscade du jour 1 est `embuscade_pannibal`.
- **E6 — écarts au scénario** : la chute de Willem dans le marais est un carton (planche
  `willem_marsh` absente) ; la cuisinière du jour 4 est `fairy_12` (sa ligne de V1 au fourneau ; elle porte une planche de
  `fairy_0x`), écartée à la table pendant que Willem cuisine ;
  le j2_3 reçoit un indice (« Willem n'est pas sorti de sa chambre… », original) puisqu'il compte pour le coucher ;
  la pose « hanches » de la protagoniste est dite par une réplique (absente de sa planche).
- **E6 — le jour 1 sur le vrai sentier de C1** : l'embuscade part quand on approche
  `premiere_embuscade` (7 m), l'intrus à `chtholly_arrivee` (4 m) ; Willem vient de `vue_marais` et
  tombe à `marais_chute`, Pannibal guette à `lumiere_pannibal`.
- **E6 — portes fermées jusqu'à un jour** : `StoryStage.apply_doors` lit `open_from_day` et
  `closed_text_key` d'une `MapExit` (porte de la maison Limashenka, C2) ; avant le jour, la sortie est
  coupée et un `Examinable` (`ClosedDoor`, même invite) lit le texte (fichier
  `data/texts/<premier segment>.json`). `MapExit` n'est pas modifiée.
- **E6 — étape `show`** : montre ou cache un nœud de la carte courante (le cristal
  `comm_crystal_call_1` d'I2, qui sonne aux jours 6 et 8 : lot S2) ; le `PropBatcher` ne fond pas un
  nœud caché, il reste donc à part et se montre seul.
- **E6 — écart entre les personnages** : deux personnages qui se parlent se tiennent à 1 m au moins,
  tournés l'un vers l'autre (étapes `walk` / `place` vers un personnage : décalage d'1 m au moins ;
  la protagoniste est menée à sa place avant le dialogue) ; seules exceptions, les voisines assises
  à table (chaises à 0,5 m) et les piles de petites (`tombe`). À vérifier sur la capture de
  chaque dialogue (lot S2 compris).
- **E6 — présentation des dialogues du récit** : champ facultatif `presentation` (bandeau, nuit) de
  l'étape `dialogue` ; sans lui, bandeau quand la scène a retiré le contrôle, nuit sinon (règle
  donnée pour l'interface « Nuit douce » du lot U1).
- **QC — garant de la qualité visuelle** : série standard de vues en données (`tools/qc_views.json`, une entrée par carte de `ile_68.json`), captures dans la vraie partie par `tools/qc_shots.sh` (`tests/integration/demo_qc.gd`), planches contact et vérification de couverture par `tools/qc_tool.py` ; grille et registre : `docs/QUALITE.md`. Les vues d'ensemble (caméra haute) ne comptent pas pour le budget de 200 draw calls.
- **QC — lueur des vitres** : `glow_color` (`panel_core.gdshaderinc`) n'a plus `source_color` et la couleur de l'image est ramenée en sRGB pour la comparaison ; sous Compatibility, la comparaison d'une couleur sRGB au pixel linéaire éteignait toutes les vitres, la nuit comme le jour. Tolérance inchangée (0,05 à 0,12) : plus large, elle allumerait le torchis ocre des chaumières.
- **QC — voûtes du sentier** : `fg_canopy_a` n'est plus posé en l'air au-dessus du sentier (une masse sombre au milieu de l'écran) ; il attend le premier plan accroché à l'écran (E10). `test_sentier.gd` vérifie qu'aucune voûte ne flotte.
- **U1 — interface « Nuit douce »** : un seul thème, `src/ui/wordend_theme.tres`, porté à la racine de chaque écran ; ses boîtes sont des `NuitBox` (`src/ui/nuit_box.gd`, StyleBox en script : fond arrondi, ombre, filet doré qui s'efface, point doré), ses jetons (couleurs, durées, tailles) au type `Nuit`, lus par `UiStyle` (`src/ui/ui_style.gd`). Les voiles (`Dim`, `FadeBlack`, `FlashWhite`, `GoldRule`, `BandeauVeil`) sont des `Panel` stylés par le thème : plus aucune `Color(` dans `src/ui/*.tscn` hors `journal.tscn` (E6), vérifié par `test_ui_nuit.gd`. `dialogue_box_theme.tres` est retiré.
- **U1 — verre dépoli** : `src/ui/frost.gdshader` (posé par `UiStyle.frost`) lit `hint_screen_texture` en niveaux de détail (le rendu Compatibility, Web compris, floute les mipmaps de la copie de l'écran) et ne touche que les pixels du fond de la NuitBox (même couleur que son `fill`) : ombre, filet et point gardent leur dessin. Une seule copie de l'écran par image, même avec plusieurs panneaux. Dialogue Nuit douce : 133 draw calls (129 avant).
- **U1 — polices** : Nunito (texte, graisse 600, gras 800, italique par inclinaison `variation_transform`) et Cormorant Garamond (noms, titres, graisse 600 ; italique pour le jour du menu de pause), SIL OFL 1.1, réduites au latin par fontTools (axes variables gardés : 507 Ko en tout). Nunito n'a pas l'espace fine insécable (U+202F) : elle se prend dans Cormorant (`fallbacks`).
- **U1 — présentations du dialogue** : `DialogueBox.set_presentation(&"bandeau" | &"nuit")` vaut pour la boîte ouverte et les suivantes jusqu'au prochain appel (variable statique) ; la géométrie des deux présentations est en constantes du type `DialogueBox` du thème. Les choix gardent le panneau Nuit douce dans les deux.
- **U1 — menu de pause** : panneau à droite, en tête « Jour n · moment » (`GameState.day`, `GameState.slot`, sinon `GameState.moment`), « Pause » quand `day` vaut 0 (l'ancienne île) ; noms des créneaux dans `pause_menu.gd` (`SLOT_NAMES`) en attendant ceux du calendrier d'E6.
- **U1 — signes d'interaction** : l'invite « E / A : Parler » (pastille `HUD/Prompt`) est retirée ; `HUD/InteractSigns` (`src/ui/interact_signs.gd`) pose un signe au-dessus de la cible (`Player.current_interactable()`) et des signes pâles sur les autres cibles à moins de 3,5 m du joueur (3 au plus : ce qu'on pourrait faire à deux pas). Genre par classe (Npc : parler, Pickup : prendre, MapExit et AirshipDock : entrer, le reste : examiner), ou par la méta `interact_sign` ; aucun signe quand `get_prompt()` est vide (règle d'E8). `EventBus.interaction_available` et `Player.current_prompt()` ne changent pas (les boutons tactiles affichent toujours le texte de l'invite).
- **U1 — rappel de la touche** : « E » (clavier et souris) ou « A » (manette) à côté du signe pendant les 180 premières secondes de jeu **depuis le lancement** (aucun compteur de temps de jeu n'est sauvegardé), après 3 s d'arrêt devant la cible, ou toujours (Options de la pause, `user://interface.cfg`, hors sauvegarde de la partie).
- **U1 — souris sur une cible** : liseré doré dessiné à ses pieds par le HUD (pas de modulate du sprite : il porte la teinte de la lumière, E9) et curseur en main ; un clic sur la cible du joueur vaut « interact » (le clic n'arrive pas au jeu : pas de coup d'épée). Le PNJ qui devient la cible se tourne vers le joueur (`Npc.look_toward`) s'il est arrêté.
- **E8 — pas d'invite « Parler » pendant un jeu** : `LifeGame.blocks_talk()` réserve les participants (le ballon tant que le joueur joue, l'entraînement jusqu'à sa fin) ; le plus petit changement hors périmètre est dans `Npc.get_prompt` / `Npc.interact` (via `LifeActor.talk_blocked`). Le ballon du jeu prend l'image claire `ball_white` (0,4 m) pour se lire sur l'herbe sèche ; données dans `data/games/ballon.json`.
- **QO — QC-02, lueur des vitres par bâtiment** : `Building.window_glow_color` et `window_glow_tolerance` (façade et flancs, par `DecorPanel.set_glow_rule` vers `glow_color` / `glow_tolerance` de `panel_core.gdshaderinc`). Constat : le rendu Compatibility lit l'image sans la convertir en linéaire, le pixel comparé est la couleur du fichier à la puissance 1/2,2 ; la règle par défaut allume donc les pixels proches de #FFCA63 (pas #FFE6A6) et la couleur d'un bâtiment est élevée de même avant d'aller au shader. Réglages : aile ouest (`warehouse_front_a`) #FCDB86 à 0,12, aile est (`warehouse_front_b`) #FCD070 à 0,15, café #E9C18D à 0,015 (ses quatre lampes de vitrine : la vitrine n'a pas de carreaux jaunes) ; les chaumières gardent la règle par défaut, leur torchis reste éteint (`tests/unit/test_window_glow.gd`). La commande d'image du cahier n° 5 (3.6) n'est plus nécessaire.
- **QO — QC-20, bornes de caméra des intérieurs resserrées** (remplace T2, « bornes élargies en x ») : rez-de-chaussée `Rect2(6, 4, 20, 6)`, étage `Rect2(5.5, 4, 21, 6)`, café `Rect2(5.5, 5, 3, 0)`, maison `Rect2(3.5, 4, 1.5, 0)` (`tools/interior_maps.py`, `MAP_SETTINGS` ; CARTE.md). La borne la plus serrée possible est la dernière cloison nord-sud à moins de 0,5 m : plus loin (x 8 → 24 du plan, ou une caméra fixe au café et à la maison), la caméra voit la pièce du bout de biais et la cloison cache les pieds du joueur qui la longe (`test_no_wall_or_tall_furniture_hides_the_player`). Le vide noir passe d'environ 45 % à 25 % de la largeur en haut de l'écran aux bouts de l'entrepôt, à presque rien en bas ; le joueur reste à moins de 0,55 du centre (−1 à 1). `Map.bounds()` : seul `Rect2()` vaut « toute la carte » ; un rectangle plat ou réduit à un point borne aussi (les bornes plates du café et de la maison étaient ignorées : la caméra y suivait le joueur dans toute la carte).
- **QO — QC-23, suspensions de cristal : la lumière seule** : les huit `meuble crystal_pendant` des plans (réfectoire, couloirs du rez-de-chaussée et de l'étage, infirmerie, café) sont retirés ; leurs `lumiere suspension_*` restent (flaques de lumière au sol). L'image, sans plafond, faisait un fouillis sombre de chaînes à hauteur de tête. Essayée et non retenue : la suspension remontée de 0,6 m avec la lueur de ses lanternes (règle de lueur propre) : toujours une silhouette noire, qui passe en plus devant le menu du réfectoire (planche `build/qo/QC-23.png`). L'image et sa scène restent au dépôt, non posées.
- **QO — QC-27, bordures habitées de la cour et du champ** : 20 décors bas (au plus 1,2 m) posés à la main en fin de recette (`tools/exterior_recipes/entrepot.py`, sans tirage : le reste de la carte ne bouge pas) : dans la cour, entre le duel et le bord (lessive au nord-ouest, bancs, souches et bûches au sud, brouette et caisse à l'est) ; au champ, sur le bord ouest où l'on ne joue pas (bancs, jouets, seau, ballon), souche et bûches au sud et au nord. Dans les places `cour` et `champ`, rien qui bloque (test « rien n'y bloque ») ; à plus de 1,2 m des places de la vie (marelle, corvée, cercle, jeu, buts, fourrés), hors des chemins ; le duel reste nu. Draw calls : cour 116 → 123, champ 85 → 93.
- **QO — QC-02, le café garde la règle de lueur par défaut** : la règle propre à ses lampes de vitrine (#E9C18D à 0,015) en faisait des taches blanches bruitées, au contour pixelisé ; retirée (`tools/exterior_props.py`). La vitrine du café attend sa façade de nuit (cahier n° 5, R0.9 ; docs/QUALITE.md, QC-16).

- **C3b — la colline, reprise visuelle** : le relief de `colline` n'est plus déduit des rectangles du plan mais dessiné en contours dans `tools/exterior_recipes/colline_relief.py` (polygones en tronçons parallèles aux axes, bord bruité de 0,4 m : la grille d'un mètre fait d'une diagonale une scie de marches) ; terrasses à +1, +2,5 et +3,5 m (sommet à 3,5 m, et non 3 m), un replat de +1,5 m au sud-est, trois rampes de 5 cases de large (11 à 14°). Les `palier` et `rampe` du plan en donnent l'enveloppe exacte (CARTE.md 7), les `sol` ne sont plus peints en rectangles. Les faces sont en talus de terre et en roche par pans (`ROCK_FACES`). Le chemin ne franchit aucune marche, même de 0,5 m : la recette le vérifie (un avertissement de `exterior_maps.py gen`).
- **C3b — le vide de la colline** : la caméra à 32° ne voit pas la face nord d'une falaise ; la recette peuple le groupe `Sky` (rochers flottants à 12 → 76 m, îles lointaines à l'échelle 0,4 → 0,8 posées vers 70 → 280 m au nord, cumulus et brume sur la nappe à y = −60 m, `horizon_islands`) pour que la mer de nuages se lise loin sous le bord. `distant_island_*` mesure 64 × 32 m à l'échelle 1. Les piliers de roche qui sortiraient de la nappe (la vraie falaise, face au sud) et une caméra qui s'incline au bord du vide sont demandés (cahier n° 5, R0.12 ; CONTRACT_REQUESTS).
- **C3b — le cercle des talismans** : dessiné dans le sol (anneau de dalles de roche à bord rompu, rayon 6,15 m) plutôt que posé en décalques `ring_stone_flat_*` (des ovales sombres qui se lisent comme des trous dans l'herbe). Rien de debout n'y entre, sauf l'herbe haute, la bruyère et les fleurs.
- **C3b — densité** : le tirage de la pose est fait par section (`random.Random("colline/<section>")`) : ajouter un bouquet ne déplace plus les autres décors ; visée haute de la fourchette de CARTE.md (45 à 67 éléments par écran pour 40 à 70).
- **E6 — branché sur « Nuit douce » (U1)** : présentation bandeau tant que la scène tient le joueur,
  nuit sinon et à la fin de chaque scène ; signes d'interaction cachés pendant une scène ; couleurs
  du calendrier dans le type `Calendar` du thème, sans valeurs de repli ; le journal de quêtes
  (ancienne île) prend lui aussi le thème (jetons `UiStyle`), plus d'exception dans `test_ui_nuit`.
- **E6 — l'embuscade de Pannibal reste la séquence de repli** : E8 offre le ballon et le bâton
  (`MiniGames`), pas de combat d'embuscade ; l'étape `game` « embuscade_pannibal » attend son
  inscription (`StoryDirector.register_game`).
- **G6 — cahier des images n° 6** (`docs/ASSETS_HD2D_ILE68_LIVRAISON6.md`) : le n° 5 reste l'archive, le n° 6 est le seul cahier à donner à ChatGPT pour la série suivante ; inventaire par script (manifeste, recettes, `assets/`, scènes `data/scenes/ile_68/`, plans de `CARTE.md`), 225 images et 61 planches en quatre lots (A : jours 1 à 4, port, sentier, ville haute, snack-bar ; B : l'existant visible ; C : phase 3, jours 5 à 12 ; D : le reste) ; les versions de nuit des façades dont le jour est un remplaçant se commandent avec leur jour (C.5), `pare` reste à 2 images, 2 ips, en boucle (E8), `wallitem_family_portrait` à 58 × 77, les animaux en profil seul ; les écarts entre documents sont à la section 10 du cahier.
- **CV — la ville haute suit son plan sans le changer** (`tools/exterior_recipes/ville_haute.py`, CARTE.md 9.2) : ce que la pose ajoute ou écarte est dit dans les `DEVIATIONS` de la recette, relevés par `exterior_maps.py gen`, et dans CARTE.md 9.2 (« Écarts et ajouts »). Écarts : volées de la grand-rue en vrais escaliers (`stairs` : marches de 0,1 m, joues en muret) plutôt qu'en rampes ; faces des paliers en muret ; pavés et dalles propres à la carte (`paves_v`, `paves_vb`, `dalles_v` : les matières « chemin » de la bibliothèque refusent une marche de plus de 0,5 m, les terrasses en ont de 1 m) ; sol d'herbe et de sous-bois au nord (le plan pave toute la carte) ; muret de la fontaine qui ferme le haut de la grand-rue ; bandes et cours que la règle de caméra dit cachées par un toit, fermées par des `Edges` (z 24 → 25, z 44 → 46, z 4 → 5, cours de l'est).
- **CV — pas de grand arbre au sud d'une rue** : les jardins clos des quatre blocs portent de jeunes arbres et des buissons ; un arbre de 9 m au sud de la rue haute ou de la rue du café couvre le tiers bas de l'écran même en premier plan (qui s'efface autour du joueur seulement). Les grands arbres d'or sont à la lisière nord, sur les bords est et ouest, et les toits de `town_roofs_a/b` ferment le nord.
- **CV — les portes de la ville** : snack, café, librairie en « Entrer » vers leur carte (café et librairie d'attente) ; la salle de projection porte `open_from_day = 5` et `closed_text_key = "ville/projection_close"` (data/texts/ville.json, « Pas sans un adulte. ») comme la maison Limashenka, que `StoryStage.apply_doors` lit déjà ; l'accessoiriste et l'apothicaire n'ont pas de porte au plan : leur vitrine s'examine (« fermée »).
- **CV — cartes d'attente d'intérieur** : `ville_cafe`, `ville_librairie`, `ville_projection` sont la pièce de leur plan (sol, murs, porte, points), sans meuble ni élément de mur, avec un écriteau à examiner sur le seuil ; `WAITING_INTERIORS` d'`interior_maps.py` (leur lot les en retire et pose leur mobilier). `ville_marche` est une carte d'attente du dehors (`WAITING` d'`exterior_maps.py`, sol de pavés). Boulangerie et horloger n'ont pas de carte : leur seule porte est sur la place du marché d'attente.
- **CV — le snack-bar** : sept pièces d'image au lot R4 (`tools/hd2d_ville.py` : comptoir, étagère, tabourets, plateau ; sol de dalles claires, murs de pierre apparente, enduit ocre des boutiques) ; la table est la `cafe_table_heavy` du café du village. Places en plus du plan : `snack_vendor` (derrière le comptoir : 0,35 m entre l'étagère et le comptoir, ce n'est pas un point atteignable), deux tabourets, deux places de la table, la porte. Caméra fixe, un point au milieu de la pièce : la pièce de 7 × 5 m tient dans un cadre étroit (le recul de la caméra ne change pas), le reste de l'écran est le vide noir des intérieurs.
- **CV — noms de pièces par carte** : `MAP_ROOM_NAMES` d'`interior_maps.py` (la pièce « salle » du snack n'est pas la « Salle du café »).
- **CV — images** : trente-huit remplaçants (lot R4 du cahier n° 5, 6.4 à 6.7) : dix façades de maisons et de boutiques avec leur flanc, la matière `wall_stone_town`, deux enseignes, six décors de rue, deux lisières de toits, trois matières de pièce et quatre meubles du snack-bar ; l'enseigne de la poêle et celle de la tasse sont des décors à part (le plan les pose) : les façades du snack et du café n'ont pas la leur. Les `town_stairs_a/b` et `town_retaining_wall` ne sont pas faits (les escaliers et les murets sont dans le sol).
- **CV — le chemin de la ville** : `exterior_maps.py gen sentier` écrit la sortie `vers_ville` dès que `ville_haute` existe, sans autre changement de recette ; les identifiants d'`ext_resource` de la scène sont renumérotés (l'écriteau n'est plus posé) : en cas de conflit avec une autre modification du sentier, relancer `gen sentier`.
- **E8c — l'embuscade de Pannibal compte chaque attaque** : « cinq attaques esquivées ou parées de suite »
  (ACTE1.md 3.1) compte le bond et chaque taillade (un bond et trois taillades font quatre) ; une taillade
  reçue finit la série (Pannibal compte son point et recule d'un bond) ; le bond ne se pare pas (seul le pas de
  côté l'esquive), les taillades se parent ou s'esquivent ; la riposte n'est ouverte qu'après une esquive
  (0,8 s). Le jour 1, l'issue ne change pas la suite (elle reconnaît Chtholly) : la réussite pose
  `j1_embuscade_gagnee` et donne une réplique de plus (« vaincue »), sans écran de défaite. Le jeu s'arrête aussi
  si Chtholly s'éloigne de plus de 10 m (`fled`) ou au bout de 75 s (`time`) : la scène ne reste jamais en plan.
- **E8c — le récit inscrit ses jeux au démarrage** : `StoryDirector._ready` appelle
  `MiniGames.register_story_games()` (une ligne dans le fichier d'E6, pas d'autoload de plus) ; un jeu qui ne
  peut pas démarrer rend `false` et l'étape « game » joue son repli (carte d'essai, personnage absent).
- **E8c — la levée du sentier corrigée par la navigation** : la rampe x 33 → 36 est taillée dans la levée ; ses
  bords sont des marches franches de 0 à 0,5 m, que le joueur ne franchit plus au-delà de 0,1 m mais que
  `LifeNav` croyait franchissables jusqu'à 0,3 m (MAX_RISE, mesuré tous les 0,34 m). `LifeNav.MAX_STEP`
  (0,105 m, mesures fines de 0,05 m là où le sol change de plus de 0,03 m entre deux mesures) refuse une marche
  franche ; pentes et contremarches d'escalier (0,1 m) passent. Le plan et la recette du sentier ne changent pas
  (un rebord de rampe existe sur toute carte ; une forme nouvelle déplacerait seulement la marche).
- **E8c — la place de Willem au réfectoire** : `entrepot_rdc:refectoire_porte_est` (15,75 ; 7,85), le seuil de la
  porte est (la plus proche de l'escalier) ; les petites filent par la porte ouest vers `couloir_ouest`
  (« par l'autre porte », ACTE1.md 2.2), au lieu de `couloir_est`, qui les faisait passer devant lui.
- **CP — la carte du port** (`tools/exterior_recipes/port.py`, CARTE.md 6.2) : construite d'après le plan ; écarts notés dans
  CARTE.md et dans `DEVIATIONS` de la recette : bornes de caméra `Rect2(10, 6, 50, 24)` (le plan arrêtait la vue à z = 30),
  relief de la colline refait (trois rampes qui montent vers le nord : les deux du plan menaient nulle part), point `navire_quai`
  ajouté (32,5 ; 7,6), aucune lumière (les lanternes de quai sont l'image `dock_lamp`, qui brille par son `glow`).
- **CP — le navire à quai** : un grand panneau de décor `ships/garde_transport_side` (16 × 7 m, lot R7 du cahier, sans collision,
  quille à −1,6 m sous le quai), remplaçant **dérivé du flanc livré du Barocupot** (ramené à 16 × 7 m, un peu bleui ; la recette est
  dans `tools/hd2d_port.py`). E7 le remplace par le navire en volume ; le point `navire_quai`, la passerelle et les trois bras
  d'ancrage restent (docs/CONTRACT_REQUESTS.md).
- **CP — la passerelle** : un plancher de 2 × 3,6 m (`gangway_quay`, `Building` sans façade) du quai à la coque, au lieu de l'image
  `gangway` (une rampe de flanc) ou de la scène `gangway` de T1 (12 m de long, pour la plage). Le bord du vide (`vide`) est une boîte
  invisible : on monte sur le début de la passerelle mais on ne marche pas jusqu'à la coque ; la scène du débarquement y fait descendre
  Willem. Les sorties `passerelle` (→ `transport_garde`) et `vers_ville` (→ `ville_marche`) sont omises tant que leur carte n'existe pas
  (un écriteau ferme la route de la ville), l'outil les remet quand elle existe.
- **CP — le panneau aux flèches rouges** : `signpost_port`, dérivé du panneau livré `signpost` (mêmes flèches écaillées, une ville de
  maisons de pierre à droite, un bâtiment de bois entre deux sapins à gauche). Il est au premier plan (le plan le veut : `pp`) et
  s'efface autour du joueur qui se tient derrière lui (au nord, comme le point `panneau`) : pour le gros plan de la scène 1.1, la place
  `panneau_sud` (6 ; 22,8, regard au nord) met le panneau derrière Willem.
- **CP — pas d'ornières sur les pavés** : le décalque livré `cart_ruts` se lit comme un sillon de labour (QC-32, R0.8), il n'est pas posé.
- **CP — ordre de travail** : après chaque `gen` d'une carte, `tools/import.sh` (le sol lit `materials.png` par l'import ; un import
  périmé donne des rectangles d'herbe aux bords des matières).
- **(G6) Le Carillon de Willem** : sur décision de l'utilisateur (15 octobre 2026), la planche `willem/willem_duel` (Willem et le Carillon de série Percival, duel du jour 8 et entraînement du jour 11) est commandée au cahier n° 6, C.10, priorité 1.
- **(Intégration CP + CV) Les retours d'une carte d'attente** : `WAITING[<id>]["more"]` (tools/exterior_maps.py) ajoute à une carte d'attente d'autres sorties de retour, chacune avec son marqueur d'arrivée `from_<cible>` ; `ville_marche` reçoit ainsi la route du port (sortie `vers_port`, marqueur `from_port`), que le contrat des cartes (`test_maps`) exige depuis que la route du port vers la ville s'ouvre.
- **E7 — le navire en volume est un assemblage de panneaux** (`Ship`, src/world/props/ships/garde_transport.tscn) : le flanc
  (`ships/garde_transport_side`, debout), le pont vu de dessus couché derrière lui (`ships/garde_transport_deck`, remplaçant), les
  rotors, la trappe, la passerelle (un Building incliné) ; pas un `Building` à façade : sa boîte se verrait derrière la quille
  courbe et l'étrave. Le navire n'est jamais sous `Geometry` (le PropBatcher fondrait ses panneaux et figerait son mouvement et ses
  bandes) : il est dans le poste d'amarrage `Berth` de la carte.
- **E7 — en dehors des scènes, le poste est vide** (CARTE.md 6.2, ACTE1.md 6) : le transport ne paraît qu'appelé par le récit
  (`ShipControl.descend`, ou `dock` / `pose`) ; son état (à quai, trappe, passerelle, embarquement) est dans des drapeaux de GameState
  (`ship_transport_garde_docked|hatch|gangway|boarding`), sauvegardés, pour qu'une carte du port rechargée le retrouve.
- **E7 — les bras d'ancrage sont des bandes** (`anim/mooring_arm_clamp`, image 0 = `mooring_arm_open` au pixel près) posées hors de
  `Geometry`, sous `Berth/Arms` (mêmes noms `BrasAncrage1..3`, mêmes x, même collision) : une bande posée par-dessus le bras fondu
  laisserait voir le bras ouvert derrière le bras abaissé. Ils se referment de la poupe (ouest) à la proue (est), s'ouvrent dans
  l'autre sens au départ.
- **E7 — la trappe au droit de la passerelle** (x 32,5, CARTE.md 6.2) et non « à l'arrière » (cahier n° 6, C.1) : le plan du port
  pose la passerelle et le point `navire_quai` à x 32,5, sous le seuil de la trappe, au-dessus du moyeu avant ; le navire reste
  centré en x 30 (de x 22 à 38). Le pont est à 1 m au-dessus du quai (la quille 1,5 m dessous) ; la passerelle (2 × 3,6 m,
  pente de 17°) se pose sur le quai en z 6,6, au nord de `navire_quai` (7,6).
- **E7 — le projecteur cache la silhouette** : un cône (`sky/ship_searchlight`, agrandi à 8 × 17,6 m sous la quille) et un
  éblouissement devant la coque (`sky/ship_glare`, hors cahier, lot E7), lumineux par eux-mêmes (lueur blanche), éteints entre 35 %
  et 85 % de la descente ; la descente ralentit (hauteur en (1 − t)²), un roulis de 1,6° s'éteint en arrivant.
- **E7 — la porte du vide** : le bord du vide du port est ouvert devant la passerelle (la boîte `vide` coupée de x 31,4 à 33,6 par la
  recette, et la barrière invisible de la côte ouverte par `barrier_gaps`, une clé nouvelle du sol, E2) ; le `Gate` du poste la
  ferme tant que la passerelle n'est pas posée. La sortie « Monter à bord » (plan : au pied de la passerelle) n'a ni invite ni
  signe tant que le navire n'est pas à quai, passerelle posée, **et** que le récit n'a pas permis l'embarquement
  (`ShipControl.allow_boarding` ; jamais à l'acte 1).
- **E7 — l'API du récit est statique** (`ShipControl`, sans autoload ni PR « contrats »), plus une étape `ship` du moteur de scènes
  (StoryData.STEPS, StoryRunner) : une séquence passée pose l'état final d'un coup. Les actions sont des lignes de temps du poste,
  avancées à l'image physique (`ShipBerth.advance`, que les tests et les captures avancent à la main).
- **E7 — le pont `transport_garde`** : le vide entre le pont et le quai passe de 1 à 2,5 m (la côte lissée du sol refermait 1 m) ;
  « Descendre à quai » est en haut de la passerelle (on arrive à 2,6 m d'elle) ; la coque sous le pont est un Building dont la façade
  est le bas du flanc (`ships/garde_transport_hull`, recette : le flanc coupé sous la ligne du pont), 0,4 m au sud du bord du pont
  pour cacher la roche que le sol dessine sous la côte (CARTE.md 6.3, écarts).
- **E7 — le Barocupot** : portes de passage en chambranle de bois (`door_frame_wood`, comme partout : `door_bulkhead`, opaque,
  cacherait le joueur sur le seuil) ; hublots à 1,3 m ; un vestiaire au sas, un banc et un bidon dans la coursive (lot S, en plus
  du plan) ; région `ciel`, hors de la carte de l'île (on n'y voyage pas : on y arrive par la scène 8.7).
- **E7 — l'ombre du Barocupot** (8.6) : la silhouette livrée (`props/airship_barocupot`) à 100 px/m, teintée sombre, à alpha doux,
  posée par `ShipControl.pass_shadow` à 60 m devant la caméra (à l'horizontale) et 30 m sous elle (dans la mer de nuages, au-delà du
  bord : vue de la colline, elle passe sous l'horizon, au-dessus de la terre), qui traverse 80 m d'ouest en est en 7 s, en fondu ;
  elle se pose dans la carte chargée (la colline, ou la chute dans les nuages d'E9), sans toucher à la carte.
- **CF — la forêt profonde** (`tools/exterior_recipes/foret_profonde.py`, CARTE.md 8) : construite d'après le plan ; elle sort de `WAITING` et entre dans `RECIPES`. Écarts notés dans CARTE.md (8, « Écarts au plan ») et dans `DEVIATIONS` de la recette.
- **CF — la rivière est peinte au ras du sol** : le plan donne un lit à −0,5 m en six rectangles ; sur une rivière en diagonale, la grille d'un mètre en faisait une scie de marches de 0,5 m (faces de terre à lèvre d'herbe tous les deux mètres), lue comme des terrasses en plaques (docs/QUALITE.md), et chaque passage demandait deux rampes pour les PNJ. Le lit (`lit_ruisseau`) et l'eau basse sont peints en méandres sur les centres des rectangles du plan, on y marche ; le gué garde le tronc `log_bridge_b` et des pierres plates. Le relief de la carte tient aux deux ressauts à +1 m (contours irréguliers, faces en talus de terre : la roche en briques se lisait comme un mur).
- **CF — la règle de pose des lisières** (docs/QUALITE.md, QC-S) : aucune image de lisière ou de mur de forêt dont le bord vertical est opaque n'est seule dans le champ. Une image de pan de 16 m est pleine jusqu'à ses bords dans sa moitié basse et son corps haut s'arrête à 0,7 m des bords : les pans se posent en chaînes qui se chevauchent de 3 m (le plus proche de la caméra cache le bout de l'autre), chaque bout qui reste à découvert dans le champ de la caméra (x de −6,5 à 86,5) est couvert par un grand tronc de premier plan (au nord : sa cime est au-delà du haut de l'écran) ou par un grand conifère et un feuillu (à l'ouest et à l'est : un tronc coupé en l'air se verrait), avec son buisson. Vérifié par `tests/unit/test_foret_profonde.gd` (`test_no_forest_wall_ends_in_the_open`). Les troncs de premier plan ne se posent plus au bord sud (leur cime coupée se voyait).
- **CF — pas d'arbre de premier plan sur le joueur** : la futaie n'a aucun grand arbre à moins de 9 m au sud, à moins de 3,6 m en x, d'un endroit où le joueur se tient (points, marqueurs, places, chemins) ; elle est à 3,8 m au moins des chemins ; les jeunes arbres suivent la même règle. Les grands arbres qui cachent quand même un passage prennent leur variante de premier plan (`_forest`), qui s'efface autour du joueur.
- **CF — densité** : 53 à 93 éléments par écran (le plan disait 90 à 120, la leçon de qualité 40 à 70 : la forêt est le décor le plus dense, le refuge et la souille sont les plus chargés) ; le test impose 40 à 100, aucun carré de 6 × 6 m nu hors des places (une passe de la recette comble ce qui reste), 200 draw calls au plus (au plus 116 lots de décor + 45 dans le champ).
- **CF — images** : les noms du plan que le cahier n° 5 (R5, 7.1 et 7.2) n'a pas livrés ont un remplaçant, `tools/hd2d_foret.py` : `refuge_oak` (le chêne creux `oak_c` livré, agrandi ×1,75, un creux ouvert à sa base), `forest_wall_deep` (le pan `forest_wall_b` livré, assombri et refroidi), `grove_dense` (trois arbres livrés assombris et un taillis), `fallen_pine` (le tronc couché `fallen_tree` livré, aplati et recoloré), `rowan`, `hidden_pool_a` et `_b`, `log_bridge_b` (le tronc livré retourné), `river_bank`, `anim/river_rapids`. Aucune image livrée n'est retouchée. Pas de `canopy_shadow_*` ni de `sun_dapple` au sol (des fantômes grisâtres), pas de `river_bank` dans l'eau.
- **CF — la nuit** : le sol est éclairci (teinte 1,12, mousse claire autour du refuge) pour que la nuit de la forêt (sans lumière dans la carte) passe le seuil de luminance du garant (0,1) ; la lumière des fées du joueur éclaire 4 m autour de lui.
- **CF — la faune** : le peuplement de la forêt passe de `planned` à `maps` (data/fauna/ile_68/peuplement.json), sans changement de groupe ; les marqueurs sont les points du plan (`cerfs`, `lisiere_riviere`, `souille`, `loups`, `gue`).
- **CF — la sortie vers la montagne** n'est pas posée tant que la carte `montagne` n'existe pas (`omit_if_missing`) : un écriteau « Plus loin, bientôt » (`SignMontagne`, en (77 ; 44,6)) ferme le sentier de l'est ; la scène l'écrira quand la montagne existera (`gen foret_profonde` puis `tools/import.sh`). Le marqueur d'arrivée `from_montagne` est déjà là.
- **(QC-S) Pans à raccord** : un pan `wrap: x` (`forest_wall_*`, `treeline_*`) ne finit jamais libre dans le champ (joint, prolongé hors de la carte, ou caché par un grand arbre posé devant, `oak_a` de préférence) ; `tools/exterior_maps.py check` échoue sinon (QC-33). Un bout au bord de la carte ne compte qu'au cadrage par défaut (21 m) ; les familles d'un PropScatter ne comptent pas comme cache. Aucune image n'est en cause : leur bord plein est voulu pour le raccord.
- **(Intégration) La démonstration de la faune a une graine fixe** : `FaunaPopulator.fixed_seed` (0 : au hasard, comme dans le jeu) et `seed()` dans `tests/integration/demo_e5.gd`. Sans elle, la meute n'attaquait pas toujours avant la limite d'images, et `test_e5_captures` échouait au hasard, en local comme en CI (PR n° 48).
- **(E8b) Le duel, phases et reprise** : phases `intro` → `dodge` (Willem fait un pas de côté de 1,2 m, de travers à l'axe du coup, au hasard semé ; jamais de parade) → `vision` (la charge tenue 2 s ; au bout des 30 s de la phase 1, Chtholly l'allume d'elle-même ; sans coup en 10 s de vision, elle s'élance) → `reversal` → `ended`. Le « premier coup chargé » est le premier coup quel qu'il soit pendant la vision (frappe ou onde : le venenum est allumé). La reprise « Encore une fois ! » est une option du jeu (`reprise`) : le choix reste à la scène (S2), qui rappelle le jeu ; `?jeu=duel` l'enchaîne une fois pour la montrer.
- **(E8b) Les effets de la vision** : deux réglages ajoutés au post-traitement (`pale_*`, `flash_color`, nuls par défaut, hors de l'étalonnage d'Atmosphere), posés et rendus par `GameVision` ; la pâleur épargne un disque autour de Chtholly (0,12 hauteur d'écran). Le ralenti (× 0,6) mène l'horloge des visuels de Willem et des PNJ à moins de 25 m (et les pas de Willem), pas le moteur (`Engine.time_scale` ralentirait Chtholly aussi). Le jeu n'a aucun son : le « silence », l'« eau tiède » et le battement de cœur sont visuels (le blanc se voile deux fois, la vue tressaille) et le signal `Duel.heartbeat(index)` attend un lot du son.
- **(E8b) La projection** : sur le dos dans l'herbe = l'animation `degats` (ACTE1.md 3.3), tenue jusqu'à la fin du jeu ; la distance (6 m) est raccourcie par pas de 0,5 m si l'aire du duel (`Life/Areas/duel`) ou un mur l'arrête. L'élan et la projection posent le corps du joueur au sol (trajet vérifié sur la navigation) et dessinent les foulées et l'arc par la hauteur de `Visual`.
- **(E8b) Percival brille** : un halo additif (disque doux, `Duel.make_glow`, devant tout) que la lueur du post-traitement fait déborder ; ce n'est pas un décor (CLAUDE.md : le décor est en images), c'est un effet comme les décalques de CombatFx.
- **(E8b) L'entraînement avec Seniorious** : la « parade » de la Grue et de l'annonce « Pare. » est la touche de charge (Seniorious en main, la charge de venenum) ; la touche compte même pendant la recharge de l'onde (1,2 s), sans quoi un appui suivant un souffle serait perdu. « Côté. » = un pas de 0,8 m de travers à l'axe Willem–Chtholly ; « Trois coups. » = trois attaques en 1,5 s. Neuf annonces = trois de chaque geste, dans un ordre tiré (graine). Échec : douze fends sans trois Grues ou 150 s : Chtholly s'assoit (`assis`, sinon `degats`). Willem fend de côté (est ou ouest de Chtholly), comme Pannibal. L'épée arrachée est une image d'effet (`src/games/fx/seniorious.png`, tirée par tools/gen_duel_sheet.py) qui tourne trois fois et plonge dans le marais (`marais_epee`) ; son invite « Ramasser Seniorious » est un Interactable de l'exercice (option `pickup`, vraie par défaut).
- **(E8b) La planche de remplacement `willem_duel`** : tirée au pixel près de `willem_home` (trois vues) avec une épée dessinée (`tools/gen_placeholders.py duel`), en attendant la vraie (cahier n° 6, C.10) ; `attaque` a `coup` [2] comme au cahier (le tableau « life » de tools/hd2d_sheets.py dit [1, 2, 3] : à accorder quand la vraie arrivera). Elle n'est pas au manifeste (remplaçant). Tenue « duel » de Willem (data/npcs/willem.tres) ; test_life_outfits compte 24 tenues.
- **S2 (jours 7 et 8) — la protagoniste couchée ou assise est une doublure** : la planche du joueur (`chtholly`, le combat) n'a ni `dort`, ni `assis`, ni pyjama, et `chtholly_home` n'a pas le combat (le joueur ne la porte donc jamais) : les poses couchée (7.5, 8.1) et assise (8.8, dos à dos) sont jouées par un PNJ de scène, `chtholly_double` (data/npcs, tenues `maison` et `pyjama`), la protagoniste cachée par l'étape `player` le temps de la pose ; la doublure part à la fin de chaque scène (`leave`).
- **S2 — Limeskin de l'acte 1** : d'abord une fiche à part (`limeskin_garde`), la fiche `limeskin` de l'ancienne île n'étant présente qu'avec le drapeau `duel_lost` ; depuis F1 (ancienne île retirée), `limeskin` n'a plus de condition : les scènes 7.4 et 8.7 l'emploient et `limeskin_garde` est retirée. Ses répliques parlent en sifflantes.
- **S2 — séquences sans la protagoniste** : la protagoniste est cachée (étape `player`) et posée dans la pièce de la scène (la découpe des murs d'un intérieur suit la pièce du joueur ; posée dans le couloir, la pièce restait derrière son mur) ; dehors, la nuit, loin du cadre (l'orbe de lumière la suit). Un fondu au noir laisse passer le nom de la carte (2,8 s) après chaque changement de carte ; 0,8 s de noir de plus quand la pièce change.
- **S2 — moteur** : trois correctifs petits et sûrs, avec leurs tests (`test_s2_story_steps.gd`, `test_s2_day7.gd`, `test_s2_day8.gd`) : l'étape `player`, l'étape `props` (un cercle de `DecorPanel` animés sous la carte et une `OmniLight3D`, retirés à la fin de la scène), la pose du joueur tenue (`Player.hold_pose` : sinon il rejoue `repos` à l'image suivante) ; et l'indice qui attendait une scène s'efface dès qu'elle commence (il restait affiché six secondes sur la scène).
- **S2 — le match de 7.2 est mis en scène**, pas joué : le ballon d'E8 n'est pas un jeu du récit ; le ballon emporté par le vent est un carton ; Tamsin est `fairy_06` (V1 la couche à l'infirmerie, jours 7 à 9) ; Willem l'emporte dans la planche `willem_carry` (tenue `bras`), ramène {player} sur la planche `willem_piggyback` (tenue `dos`, `height_m` 1,833 : la passagère dépasse Willem, 176 px).
- **S2 — le temps des jours 7 et 8** : le jour 7 se lève clair, la pluie commence à la fin de 7.1 (vue de la fenêtre), cesse l'après-midi (le match, `apres_pluie`), revient fine au port (7.4) et la nuit ; le jour 8 est clair. Le moment avance par les scènes : 7.2 après-midi, 7.4 soir, 7.5 nuit ; 8.1 matin, 8.4 midi, 8.5 après-midi, 8.7 soir (retour dans la cour), 8.8 nuit. Les jours 7 et 8 ne finissent pas au lit : 7.6 et 8.8 écrivent la ligne du calendrier et ouvrent le jour suivant (`calendar`, `next_day`) ; `sleep_after` nomme ces deux scènes.
- **S2 — le moment facultatif des talismans (8.8)** : un choix (« Toucher les talismans. » / « Rejoindre Willem. ») ; le premier rend la main pour frôler quatre points du cercle (`talisman_1` à `talisman_4`, ajoutés au plan de la colline, CARTE.md), 9 s au plus chacun, sans échec, Willem nommant ce qu'il règle en bulles. Sans son, « tinter » reste dans la narration.
- **S2 — écarts d'image** : la fièvre qui fait onduler l'image, le givre de la chute et le blanc qui envahit l'écran (E9) n'existent pas : la fièvre est dite, la chute est en cartons sur la mer de nuages, l'ombre du Barocupot passe avant le blanc ; la salle des armes garde la lumière de sa carte (pas de préréglage `noir`) ; Seniorious démontée et la serviette prêtée sont dites, pas dessinées.
- **S2 (jours 9 à 12) — les scènes** : `j9_1_porte` à `j12_3_epilogue` (data/scenes/ile_68), une par fiche d'ACTE1.md 9.1 à 12.3, plus `j12_1_embuscade` (la dernière embuscade de Pannibal, 12.1 : à la première sortie du porche le jour 12, facultative). La séquence du toit (10.4, « début de nuit ») se joue après la tour de fées (10.5, « soir ») : 10.5 finit sur la fuite de {player} à l'étage et la nuit, 10.4 part de là. 9.4 fait passer à la nuit (9.5 suit, « la nuit, Chtholly passe devant le réfectoire »). Les scènes du matin des jours 10 et 11 partent dès l'aube et posent le matin (`slot`).
- **S2 — l'entraînement au bâton au récit** : `MiniGames.play_story_staff` inscrit sous « entrainement_baton » (comme les jeux d'E8b) ; il rend la main au joueur le temps de l'exercice (StaffTraining ne le fait pas) et attend que Willem et les aînées soient rendus (`end_time`) avant que la scène reprenne. Le jour 10, la réussite de la phase A est hors d'atteinte par les données de la scène (`overrides : {"phase_a/success_deflections": 99}`, que la jauge ne montre pas) : un joueur parfait aurait gagné en 14 s, avant la fermeture de la fenêtre à 15 s, et « rien ne passe » (ACTE1.md 10.1).
- **S2 — l'étape `place` a une hauteur `lift`** (m) : la pile de la tour de fées (10.5) reprend les étages de `src/life/games/tour.gd` ; un PNJ soulevé perd sa collision (`Npc.set_moving`) et la reprend à la pose suivante sans `lift`.
- **S2 — la fin de l'acte 1** : après le départ (12.2), l'invite « Voir l'épilogue » / « Passer » est un choix de dialogue sur le noir ; l'épilogue (12.3) est une séquence (passable une fois vue) ; les deux finissent sur le carton « Fin de l'acte 1… » puis rendent la main dans la cour, la nuit du jour 12, avec le drapeau `acte1_fini`. Pas de jour 13 (`can_sleep` faux le dernier jour), aucun indice, aucune scène : la vie libre continue à l'entrepôt, la partie se sauvegarde et se reprend par « Continuer » sans rien rejouer ; « Nouvelle partie » rejoue l'acte. Les adieux du jour 12 se taisent après le départ (`not_scene : j12_2_depart`).
- **S2 — le couchant cramoisi puis vermillon** : E9 n'a qu'un préréglage `couchant` ; le passage se raconte (carton) pendant une transition lente du couchant à la nuit (`moment`, 9 s), la caméra levée sur le ciel (tangage 15°) ; l'envol est un fondu au blanc, et le joueur, qui ne s'envole pas, est posé hors du cadre (`lisiere_sud`). De même pour les coupes vues d'ailleurs (terrasse du café, toit la nuit, épilogue) : le joueur est posé loin du cadre.
- **S2 — l'averse du jour 10 vient avec le linge** (10.3, facultatif) : le temps du jour reste `clair` ; 10.3 pose `averse` à la fin d'après-midi, 10.5 rend le ciel clair ; sans 10.3, pas d'averse, et Nygglatho se plaint de ses draps trempés pendant la tour de fées.
- **S2 — replis de planches** : la protagoniste n'a ni pyjama (9.1 : la porte qui claque est racontée) ni pose assise dans sa planche de combat (le refuge, le goûter : debout) ; Ithea et Nephren ont la tenue `uniforme` (leur planche de combat) pour le départ ; Kana et Giniette sont des fées génériques (`data/npcs/generic`, planches livrées, sans portrait : `speaker` en clair).
- **S2 — le ballon de l'après-midi, jours 9 à 12** : une ligne `ballon` (rôles rouge / blanc) aux dix petites du match d'E8, après les lignes de pluie (la pluie et la boue l'emportent) ; Willem arbitre les jours 10 et 12 (au village le 9, à la clairière le 11 : le match se joue sans arbitre).
- **(F0) Mesure de l'export Web (15 octobre 2026, base 14125db)** : 141,3 Mo compressés (wasm 9,7, pck 131,7). Le pck tient à 97 % dans les images : 1 106 `.ctex`, 130 Mo, **déjà en WebP sans perte** (toutes les textures en « Lossless », sans mipmaps ; `force_png` à faux) ; le reste (scènes, scripts, JSON, polices) pèse 4 Mo. Par dossier : `hd2d/props` 24,0 Mo, `hd2d/buildings` 19,3, `hd2d/sky` 14,7, `hd2d/ground` 10,4 (dont l'atlas 5,8), `hd2d/interior` 7,3, planches des personnages 46 Mo environ. Aucune image en double (pixels identiques), aucune image agrandie au plus proche (bloc de 2, 3 ou 4 px), aucune VRAM compressée ; les couleurs cachées sous l'alpha nul coûtent moins de 1 %.
- **(F0) Encodeur WebP sans perte à l'effort 4 / 90** (project.godot, `rendering/textures/webp_compression/compression_method=4`, `lossless_compression_factor=90`, au lieu de 2 / 25) : −5,3 Mo d'images (130,0 → 124,7 Mo), mêmes pixels au bit près (les 1 081 textures exportées décodées et comparées). Mesuré aussi : 4 / 100 → 124,5 Mo ; 5 / 90 → 123,4 Mo ; 6 / 100 → −8 % environ mais un import complet de plus d'une heure. Un import complet (worktree neuf, CI) passe d'environ 40 à 80 s à 80 à 170 s selon la charge de la machine ; une image livrée seule ne coûte que quelques dixièmes de seconde de plus. Passer à 5 / 90 donnerait 1,3 Mo de plus pour 75 s d'import complet en plus.
- **(F0) Réglages d'import imposés** : `[importer_defaults]` de project.godot donne à toute nouvelle texture « Lossless », pas de mipmaps et la détection 3D coupée (`detect_3d/compress_to=0` : sans cela, l'éditeur ouvert avec une fenêtre passe en VRAM compressée, floue et avec mipmaps, toute image vue en 3D, soit presque toutes) ; `tools/import.sh` ramène à ces réglages tout `.import` de texture plus ancien ou venu d'une autre branche (puis relance l'import) et liste les fichiers corrigés, à commiter ; `tests/unit/test_texture_imports.gd` refuse toute texture importée avec perte ou mipmaps. Une exception future (une image qui voudrait des mipmaps) se décide ici et s'ajoute au script et au test.
- **(F0) Hors du paquet (PR « contrats », export_presets.cfg, les trois préréglages)** : les 25 tuiles de `assets/hd2d/ground/` que seul l'atlas lit (`tools/hd2d_assets.py atlas` les réunit ; le jeu ne lit que `ground_atlas.png`) et `data/maps/*/plan.json` (sources de `tools/exterior_maps.py`) : −4,4 Mo. `grass.png` et `path_dirt.png` restent (la carte `essai` les cite). Les filtres de Godot font aller `*` au-delà des `/` : les tuiles sont donc nommées une à une (`assets/hd2d/ground/*.png` emporterait l'atlas). Une nouvelle tuile n'est pas exclue d'office : l'ajouter au filtre et à `F0_EXCLUDED` du test. Le test refuse qu'un fichier du jeu cite un fichier exclu ou fabrique le chemin d'une tuile ou d'un plan.
- **(F0) Rien n'est retiré du dépôt** : 122 images ne sont citées ni par chemin ni par nom, mais presque toutes sont lues par un nom fabriqué (vues `_side`, `_back`, `_foot` de `DecorPanel.view_texture`, images `_night` de l'éclairage) ou attendent leur câblage : tenues de pluie et pyjamas livrées sans `data/npcs/outfits/*.tres` (chtholly, almita, collon, ithea, lakhesh, nephren, nygglatho, pannibal, tiat, snack_vendor : 12 Mo environ), `willem_carry` / `willem_piggyback` / `willem_marsh`, `kana`, `giniette`, vues de `fairy_11` / `fairy_12`, ciels `sky_dusk`, `sky_morning`, `sky_night_wind` (5,5 Mo, lot G, sans préréglage d'éclairage), intérieurs de navires. Les retirer casserait les lots en cours ; à revoir à F1 avec l'ancienne île.
- **(F0) Marge** : 132,2 Mo pour 150, soit 17,8 Mo de marge (8,7 avant). Une image livrée pèse 0,1 à 0,5 Mo en WebP sans perte : les quelque 225 images du cahier n° 6 (25 à 50 Mo) ne tiendront pas sans perte dans 150 Mo. Pistes hors de F0 : retirer à F1 les images de la seule ancienne île ; découper le jeu en paquets chargés à la demande (`ProjectSettings.load_resource_pack`, un pck par île) ; ou relever le budget.
- **S1b — le port du jour 1 sans carton** : `j1_1_port` reste une séquence déclenchée à l'entrepôt (début de partie) ; elle va au port (`go_to`), pose la protagoniste hors du champ au bout de la route de la ville (`from_ville_marche` : elle n'est pas dans la scène, et aucun moyen de cacher le joueur n'existe), Willem paraît sur la passerelle et en descend (le bord du vide ferme z < 5), le passeur (`ferryman`) le salue et remonte ; coupe (fondu court) vers `rue_ouest`, Willem marche jusqu'à `panneau_sud` (le panneau derrière lui), gros plan, puis il part vers le sentier et la séquence coupe sur le porche. Seul carton gardé : le titre « Cet acte suit le volume 1… » (l'attribution de MONDE.md 1.5, pas un résumé). Le navire reste le panneau du lot CP : il ne repart pas à l'écran (le panneau, fondu par le `PropBatcher`, ne se cache pas ; le navire en volume viendra avec E7).
- **S1b — le jour 3 en ville** : `j3_2_chemin` part à l'arrivée sur le sentier (Ithea et Nephren rattrapent {player} et bavardent, puis la suivent au pas de course : à la marche, 1,3 m/s, elles perdaient de vue le joueur, qui marche à 4 m/s), deux bulles en chemin, la vraie sortie `vers_ville` ; à l'entrée de la ville haute (midi), le passant sort de chez lui (la maison haute, perron à x 15), voit les trois fées, change de trottoir (z 11,6 → 15,1) et file vers le sentier ; la scène finit à 2 m de `porte_snack`, où `j3_3_snack` part (`reach`) : la scène fait entrer les trois aînées par un fondu court (`go_to`), pour que Willem et le cuistot soient déjà à leur place quand l'image revient. Pas de fondu de trajet : le chemin se marche (une minute environ).
- **S1b — le snack-bar** : gros plan (10 m) dans `ville_snack` (la caméra fixe de la pièce la montre petite au milieu du noir) ; Willem debout au comptoir (`snack_tabouret`, en manteau : il n'a pas de pose assise dans cette tenue, et le tabouret est à 1 m au nord de la place), les aînées debout à la table (`cafe_table_heavy` n'a pas de chaise) ; après le repas (créneau suivant, l'après-midi), Willem, puis Ithea et Nephren sortent par la porte (`leave` à `snack_entree`) : {player} a l'après-midi libre en ville et rentre à pied pour se coucher (plus de retour d'office à l'entrepôt).
- **S1b — le cuistot et le passant** : le cuistot du snack est le PNJ `snack_vendor` de l'ancienne île (planche livrée), avec une tenue `travail` (`snack_vendor_work`, PR n° 39 : `repos`, `travaille`), sans emploi du temps : la vie de l'île n° 68 ne nomme encore que les cartes de l'entrepôt (`test_life_ile_68_nav`) et sa place `snack_vendor` n'est pas atteignable à pied ; la scène le pose, puis le retire pendant le fondu de l'après-midi (rendu à la vie, il sortirait par la porte) ; le passant est `villager_cat_m` (nom de sa planche au cahier n° 6, A.7, déjà commandée), fiche dans `data/npcs/generic/` (un passant sans dialogue, comme les fées de la vie ; son visuel dans `data/npcs/visuals/`, face et dos copiés du profil en attendant la planche), avec une planche de remplacement (`tools/gen_placeholders.py`, fonctions `make_look` / `make_skin` avec `NPC_VISUALS_DIR` et `talk` : la commande `skin` écrirait un skin jouable).
- **S1b — la chute au marais** : la planche `willem_marsh` (tenue `marais` de Willem) remplace le carton de `j1_3_intrus` : deux esquives, `effondre`, Pannibal assise sur son dos (les deux l'un sur l'autre, voulu), puis `assis` dans l'eau après la reconnaissance, et la tenue `manteau` quand il se relève. La pose `hanches` de la protagoniste reste dite par la réplique de `j1_7_chambre` : elle n'existe que dans `chtholly_home`, que le joueur ne porte pas dans l'entrepôt (cette tenue n'a pas le combat).
- **S1b — l'indice se tait** : pendant une scène, l'indice affiché est celui de ses étapes `hint`, dès son début (avant, l'indice d'attente de la scène qui venait de partir restait à l'écran : « Cherche-la sur le sentier » pendant l'embuscade) ; pendant une étape `game`, plus d'indice du tout (`StoryDirector.run_game`), il revient à la fin du jeu.
- **S1b — `wait_for` avec `reach` et `map`** : `StoryData` acceptait une seule clé parmi reach, map, examine, talk, alors que `StoryDirector.expected_met` lit `map` comme la carte de `reach` (PLAN.md : « reach (+ radius, map) ») ; `map` à côté de `reach` est maintenant admis.
- **S1b — captures des scènes** : vue `sequence` de `tests/integration/demo_e6.gd` (`E6_FROM`, `E6_UNTIL`, `E6_STEP` = 0,5 s) : une image toutes les 0,5 s pendant chaque scène, le pilote marchant (actions de déplacement, `interact` aux portes) au lieu de se poser ; planches contact par scène.
- **S1b — relecture des jours 1 à 4 dans la vraie partie** (captures toutes les 0,5 s) : `j1_5_premiers_pas`, {player} est menée au pied du porche avant que Willem ne la rejoigne en courant (il marchait à 0,4 m d'elle), Willem garde son manteau d'une carte à l'autre (`StoryStage.restage_followers` lui rend la tenue qu'il portait : il reparaissait en tenue par défaut, l'épée du sentier à la main) ; à la porte de Nygglatho, {player} attend dans le couloir à 2 m du tas de petites (elle était dans l'embrasure, cachée par elles) ; `j1_6_diner` part à 1,5 m du lit de Pannibal (à 2,5 m, il partait dès la fin de `j1_5`, sans qu'on ait couché Pannibal) et pose {player} hors du champ dans la cuisine (depuis le couloir, la coupe des murs, qui suit le joueur, laissait le mur sud du réfectoire cacher la table) ; `j1_7_chambre` met dans le tas Almita et `fairy_05`, dont l'emploi du temps de cette nuit-là est la porte de Willem (elles restaient debout derrière, hors de la scène), et fait sortir Willem sur le seuil pour le nom (la cloison du couloir le cachait) ; `j2_1_matin` écarte Willem du point d'eau (sa place `eau_toilette` le mettait au milieu des petites en pyjama) ; `j2_2_fuite` : « les chaises des petites se sont vidées » (Ithea et Nephren restent à table) ; `j4_1_cuisine` : {player} en retrait des petites collées à la porte ; `j4_2_diner` : {player} et Nygglatho à 1 m de leurs voisins, la caméra du « renifle » recentrée (elle coupait Willem au bord du mur est).
- **S1b — suiveurs plus lents que le joueur** : Ithea et Nephren suivent au pas de course (3 m/s, `activities.json`) ; le joueur marche à 4 m/s : sur une longue rue, elles traînent derrière et rattrapent quand il s'arrête (la scène les mène à la porte du snack-bar). Rien de changé dans la vie (hors périmètre).
- **S2 — jours 5 et 6 : le ballon par la vie, pas par une étape `game`** : E8 n'inscrit au récit que l'embuscade (`register_story_games`) ; la séquence 5.1 (midi, au champ, à 15 m) pose Willem et quatorze petites, Collon donne le premier coup de pied (Willem n'a pas de planche `frappe`, cahier n° 6) puis la séquence passe au créneau de l'après-midi : les lignes `ballon` des jours 5 et 6 (Willem arbitre, sept rouges, sept blanches : Collon, Pannibal, `fairy_01/03/05/07/09` ; Tiat, Lakhesh, Almita, `fairy_02/04/06/08/10`) lancent le match d'E8, que la joueuse rejoint en entrant dans le champ. Les jours 9 à 12 ajouteront leur propre ligne (`day: [9, 12]`).
- **S2 — l'embuscade de Pannibal passe au matin les jours 5 et 6** : son après-midi est au ballon ; une ligne `fourre_embuscade` au matin garde le jeu (ACTE1.md 3.1 : du jour 2 au jour 12). Collon n'a pas encore de ligne d'embuscade (VIE.md 5.5 : « à partir du jour 5 »).
- **S2 — 5.2 : le champ vu de la fenêtre est le vrai champ** : la scène change de carte (fondu, cadrage de 6 s depuis le porche pendant que la partie de la vie s'assemble, retour) ; « J'arrive. » mène la joueuse à `champ_entree` (point ajouté au plan de l'entrepôt : le bout du chemin du champ), « Une autre fois. » la laisse à la fenêtre. 5.3 est une scène à part (`reach champ_centre` 12 m, jour 5, après-midi) : un mot de Willem, sans rien réserver, hors du coucher ; la partie elle-même est celle de la vie.
- **S2 — 6.1 sans indice dans l'œuvre, une ligne (original)** : la scène compte pour le coucher, donc « Il y a du remue-ménage dans le couloir, en bas. » (60 signes au plus, comme tous les indices ; `test_s2_day6.gd` les vérifie tous).
- **S2 — 6.3 : le cristal sonne avant le dîner** : la scène du dîner s'ouvre sur la chambre de Nygglatho (`show` de `comm_crystal_call_1`, la voix du cristal sans visage), puis revient au réfectoire (même placement que le dîner du jour 4) ; elle finit à la nuit (`slot nuit`) pour que 6.4 ait sa lumière. Pas de choix : deux « Une petite » et une « Une voix » sans fiche.
- **S2 — 6.4 : le souvenir sans sépia** : E9 n'a pas d'effet « souvenir » (moments : aube, matin, après-midi, couchant, nuit) ; le souvenir est un fondu au blanc, deux cartons et la voix de la grande sœur (« La grande sœur », sans fiche ni planche). La broche n'est dessinée dans aucune image de la chambre : la voix la montre. Demande dans CONTRACT_REQUESTS.
- **S2 — 6.2 : « s'asseoir ou rester à la porte »** est un vrai choix du dialogue (`j6_tapis`), sans effet sur la suite ; le carton du souvenir dure 3,4 s sur fond blanc (« Pas un visage. Pas un nom. »).
- **S2 — correctif de LifeActor : un jeu de groupe sur une place d'un seul point** : le ballon se joue sur `champ_centre` (un point : docs/CONTRACT_REQUESTS.md, V1) ; quand quinze joueuses arrivent à pied, la première occupe le point et les autres tournaient autour sans jamais l'atteindre (`_check_stuck` ne voit pas de blocage : elles bougent), le match n'avait qu'un membre. Une joueuse (ligne dont l'activité a un `game`) est arrivée à `GAME_ARRIVE_DISTANCE` (1,4 m) du but ; le jeu la range (GATHER). `test_s2_day5.gd` (« le match se forme tout seul ») le vérifie ; `test_no_place_is_overfull` laisse le ballon, comme le chat et la course, hors du compte « un point par PNJ » ; `test_entrepot` compte vingt points nommés.
- **S2 — tests des jours 5 et 6** : base `tests/stubs/s2_story_test.gd` (reprise au réveil d'un jour par une sauvegarde puis « Continuer » à la souris, laisser passer le temps par le lit, se coucher par l'invite) ; les marches et les sorties se réessayent (`walk_to_point_again`, `take_exit_again`) : à la tombée du jour, les petites regagnent leur place toutes en même temps et bouchent un moment l'escalier, le couloir ou la porte du réfectoire.

## F1 — Retrait de l'ancienne île (PR « contrats »)

- **(F1) Inventaire de ce qui ne servait qu'à l'ancienne île, retiré** (base 8c9bd99 ; 499 fichiers, 15,5 Mo bruts dans le dépôt) :
  - **cartes et scènes** : `src/world/island.tscn` et `src/world/maps/ile_ancienne/` (la carte héritée), les cinq zones `src/world/zones/` (village, dunes, forêt, plage, colline, et l'occlusion `see_through` du village), l'arène `src/enemies/arena.tscn`, les fichiers d'emplacement `src/npc|enemies|items/placements/*.tscn`, le déclencheur `src/quests/quest_trigger.tscn`, l'écran de fin de série `src/ui/arena_end.tscn` et le journal `src/ui/journal.tscn` ;
  - **données** : `data/world/islands/ile_ancienne.json` (et son id dans `regule_aire.json`), `data/waves/`, `data/quests/` (act1_main et six quêtes secondaires), les 15 objets de `data/items/`, les 19 dialogues de `data/dialogues/*.json`, les PNJ `baker`, `egg_vendor`, `ferryman`, `garde_lookout`, `willem_stars`, `willem_training` et leurs visuels, les textes `arenas/` de `data/texts/story.json` ;
  - **code** : `Island`, `Zone`, `IslandTerrain` (relief calculé), `IslandEdge`, `IslandRock`, leurs shaders (`terrain`, `rock`, `waterfall`) et matériaux, `Arena`, `ArenaPanel`, `WaveDirector`, `FreeEnemies`, tout `src/quests/` (`QuestData`, `QuestStep`, `QuestTracker`, `QuestTrigger`), `ArenaEnd`, `Journal`, `HudJournal` ; dans les autoloads : 11 signaux (`wave_*`, `arena_*`, `quest_*`, `zone_entered`, `trigger_entered`, `tracked_quest_changed`), l'état des quêtes, les scores d'arène, la zone et la quête suivie de `GameState`, les zones et `LEGACY_MAP` de `WorldManager`, `is_legacy` de `WorldAtlas`, les conditions et effets de quête et `arena_text` de `DialogueRunner`, `NpcData.quest_id` / `home_zone`, le marqueur « ! » / « ? » des PNJ, les panneaux d'arène, de zone et de quête du HUD, `QuestTracker` et `UI/ArenaEnd` de `game.tscn` ;
  - **images** : 56 images HD-2D (11,9 Mo bruts : bâtiments du bourg, de l'auberge, de l'horloger, de l'entrepôt de l'ancienne île, stands, palissades, puits, cloche de veille, fontaine…), 51 décors `src/world/props/` qui ne servaient qu'aux zones, 4 planches de PNJ (`assets/characters/{baker,egg_vendor,ferryman,garde_lookout}`, 2,4 Mo), 15 icônes d'objets et `assets/ui/quest.png` / `star.png` ; manifeste (`tools/hd2d_manifest.json`, `tools/hd2d_scenes.json`) et CREDITS mis à jour ;
  - **tests, démos et outils** : 75 tests, démos et stubs de l'ancienne île (quêtes, arène, zones, acte 1 en quêtes, `q_quest_test.gd`, `l2_island_fixture.gd`, `tests/data/quests|dialogues|npcs|placements`), `tools/web_m1.js` (l'arène) et `tools/web_m2.js` (l'acte 1 de l'ancienne île).
- **(F1) Ce qui reste, exprès** : le moteur des ennemis et les quatre Timeres (`Enemy`, `EnemyData`, `data/enemies/`, la planche du Timere : la surface les admet, `enemies_allowed`), la faune, le combat du joueur, l'inventaire et `Pickup` (génériques, `data/items/` est vide en attendant les objets du récit), `player_heal_requested` (n'importe quel système peut soigner), la couche 8 `enemy_barrier` (réservée), `SkyDrift` et les nuages, `airship_barocupot.tscn` et `gangway.tscn` (décors génériques), `cafe.tscn` (la scène du catalogue de `cafe.png`, que `cafe_village` partage), `tools/gen_item_icons.py`, l'action `journal` (Tab : le calendrier), les cartes d'essai et le port provisoire de la carte `essai`.
- **(F1) Sauvegarde v4** : `SAVE_VERSION` 4, sans `zone`, `quests`, `quest_progress`, `tracked_quest` ni `best_scores`. Une partie de l'ancienne île — v0 à v2 (easter egg compris), ou v3 hors de l'acte en jours (`day` absent ou 0) — ne se reprend pas : `load_game()` en garde une copie (`save_v1.json.ancienne`), démarre une nouvelle partie de l'acte 1 avec son skin et pose `SaveManager.notice` (« Ta partie se passait sur l'ancienne île, qui n'existe plus : l'histoire reprend au premier jour. », `data/texts/story.json`, `save/migrated`), que le menu affiche comme avis simple (MenuNotice, sans le style d'erreur) ; `import_json` fait de même, sans copie. Ses champs ne sont plus vérifiés (elle est remplacée) : rien ne plante, `load_game()` renvoie OK. Une v3 de l'acte passe en v4 sans perte. Tests : `test_save_migration.gd`, `test_e6_resume.gd` (dans la vraie partie, avec la vraie sauvegarde v2 d'avant la refonte).
- **(F1) L'atlas du sol a son propre script** : `GroundAtlas` (`src/world/ground_atlas.gd`) reprend de `IslandTerrain` les 27 tuiles, le repli à 12 et les mipmaps de l'atlas, seules parties encore lues (MapGround, décalques). Un `GroundDecal` sans `MapGround` se couche à plat à y = 0 ; `PropScatter` sans sol pose à y = 0.
- **(F1) Effets hors des zones** : `CombatFx.host_for` rend le parent de la cible (les zones et le conteneur `Enemies` compté par l'arène sont partis).
- **(F1) Les sorties des cartes d'essai** : `essai` ↔ `entrepot_rdc_essai` (`vers_entrepot_rdc_essai` / `from_entrepot_rdc_essai`, `vers_essai` / `from_essai`) remplacent les sorties vers l'ancienne île.
- **(F1) Tests du combat sur une île de test** : `tests/data/world/` (monde `combat`, île `ile_combat` = la carte `essai` où les Timeres sont permis), par `WorldAtlas.set_data_dirs` ; il remplace l'arène des dunes pour `test_m1_combat.gd`. La base M1 (`tests/stubs/m1_game_test.gd`) part de la carte `essai`, le récit coupé (`story_for_test()`, faux par défaut ; vrai dans la base E6) ; `place_player(at, aim)` prend des coordonnées de la carte ; la base des tests de sauvegarde (`l8_save_test.gd`) coupe aussi le récit, comme la carte de départ de l'ancienne île le faisait.
- **(F1) Objets et dialogues de test** : `tests/data/items/` (`test_flower`, `test_linen`, `test_page`, `test_picture`, icônes faites par un script de F1), lus par `ItemData.add_search_dir` ; `tests/data/dialogues/l6_nephren.json` et `tests/data/npcs/l6_nephren.tres` pour la démo du Lot 6 (l'offre du livre d'images pose un drapeau).
- **(F1) Aucune référence morte** : `tests/unit/test_no_dead_paths.gd` lit chaque « res://… » de `src/`, `data/` et `tools/` (sauf les gabarits et quelques exemples) et refuse un chemin disparu.
- **(F1) docs/QUETES.md devient docs/DIALOGUES.md** : le format des dialogues, conditions (`flag`, `not_flag`, `count`, `day`, `slot`, `scene`, `not_scene`), effets, `{player}`, `speaker_id`, `visible_if`, `story.json` ; les quêtes, déclencheurs, marqueurs et le journal en sont retirés.
- **(F1) Démos reposées sur les cartes** : `demo_hd2d` (vues `entrepot`, `port`, `village`, `colline`, `dialogue`, `combat` à la surface, `quai` / `fondu` / `arrivee` / `retour` sur la sortie du rez-de-chaussée d'essai), `demo_h1_views` et `demo_formats` (carte `essai` et `essai_relief`), `demo_e9` (la vue `village` est la carte du village de l'île n° 68 ; `bord` est retirée), `demo_u1` (sans la vue `arene`), `demo_l10` (sans zone, quête, vague ni fin de série), `demo_l5` (les Timeres sans l'arène).
- **(F1) Mesure de l'export Web** (`tools/build_size.sh`, même machine, avant à la base 8c9bd99, après à la fin de F1) : avant 135,7 Mo compressés (wasm 9,7, pck 126,0 ; 166,2 Mo bruts) ; après **127,1 Mo** (wasm 9,7, pck 117,5 ; 157,4 Mo bruts) : −8,6 Mo compressés, marge sous les 150 Mo portée de 14,3 à **22,9 Mo**. Les images ne servant qu'aux cartes d'essai pèsent encore 1,3 Mo (gardées : les cartes d'essai restent).
- **(F1) La capture de `tools/check.sh` rend le menu principal** (`src/main.tscn`) : une carte rendue seule sous Xvfb (essai, essai_relief, l'intérieur d'essai) laisse à la sortie deux textures 256 × 256 « leaked » (le ciel du rig d'Atmosphere), déjà à la base 8c9bd99 ; l'île retirée, qui avait son propre environnement, ne le faisait pas. Demande notée dans docs/CONTRACT_REQUESTS.md.
- **S2b — le passeur du jour 1 après F1** : F1 (75775b6) retire la fiche `ferryman` que `j1_1_port` (S1b) gardait dans `present` (StoryData : « PNJ inconnu ferryman », trois tests unitaires rouges) ; à la fusion, le passeur y devient le passant générique `villager_cat_m` (même réplique « passeur »), et test_e6_scenes le cherche sous cet id. Une fiche de passeur de l'île n° 68 pourra le remplacer.
- **(QC2) Places masquées, la règle chiffrée** : un décor de 2 m ou plus masque une place s'il couvre, vu de la caméra du jeu au cadrage par défaut (21 m, 32°, point visé 2,5 m au nord, borné), au moins 3 des 15 points d'un personnage debout (5 colonnes de −1 à +1 m, 3 hauteurs de 0,25 à 1,25 m) : une colonne entière (un tronc qui frôle) ou le tiers de la silhouette. Places : chemins (un point par mètre), points, places (centre) et marqueurs du plan, places de la vie, vues QC ; pas à moins de 4,5 m d'une sortie (on passe sous la lisière, les chênes qui couvrent les bouts de pans y font voûte, QC-34). Une famille compte chacune de ses variantes à sa plus grande taille, dans les deux sens (le tirage se fait au lancement).
- **(QC2) Tolérés** : l'arbre d'escalade de l'entrepôt (V5, au milieu du passage vers le champ, voulu par le plan) et le panneau du port sur le point `panneau` (le point est le panneau même, cible de la caméra et de l'examen du jour 1 ; on le lit de `panneau_sud`) ; la vue QC `port:panneau` passe à `panneau_sud` (6 ; 22,8).
- **(QC2) Le bandeau des jeux évite le coin du HUD** plutôt que de déplacer les cœurs : `GameScore` reste en haut au centre, se pousse à droite du coin (cœurs, jauge de charge) et se replie sur plusieurs lignes s'il manque de largeur.
- **(QC2) Une bulle de PNJ monte au-dessus du joueur** plutôt que de se cacher : la réplique de Pannibal couchée à ses pieds reste lisible.
- **(QC2) Le nom de la carte attend le jeu libre** (fin de scène, de jeu, de conversation, de sommeil) au lieu d'être sauté ; affiché quand une scène commence, il s'efface et ne revient pas.
- **(QC2) Le bas du calendrier** : un filet d'or, « Aujourd'hui : jour N » et le compte jusqu'au départ, puis l'indice ; la page se resserre sur son contenu. Les quatre textes ont un repli en dur et des clés `ui/…` à ajouter aux textes du récit (docs/CONTRACT_REQUESTS.md).
- **(AN) Allure : marche 3,1 m/s, course 5,8 m/s, cadence proportionnelle à la vitesse réelle** (décision de l'orchestrateur, à valider sur capture) : la foulée dessinée (84 px de planche par cycle de marche, 147 par cycle de course, mesurés sur Chtholly) donne 1,46 et 4,3 m/s à la cadence du JSON ; `CharacterVisual.match_stride` (joueur et PNJ) avance l'horloge de marche et de course au rapport vitesse mesurée / vitesse dessinée (borné entre 0,35 et 3). Conséquence : la marche de Chtholly joue à environ 21 i/s (2,1 × 10), la course à environ 19 i/s ; ennemis et faune gardent la cadence du JSON. Des planches à foulée plus longue (cahier C7) abaisseraient ce rythme.
- **(AN) Fin du pas plutôt que coupure** : à l'arrêt, le repos attend la prochaine image de contact (0 ou 3) ; en marche, un changement de vue (profil, face, dos, donc le côté de l'épée à l'écran) attend aussi le début d'un pas. Les vues de face et de dos ne sont pas retournées en miroir pour garder l'épée du même côté : changer de côté en tournant est fidèle au dessin, seul le moment (en plein pas) choquait.
- **(AN) Changement de carte** : le joueur garde la physique pendant le fondu au noir (commandes seules figées, `Player.hold_input`) et n'est retiré de la physique (process_mode DISABLED) qu'une fois l'écran noir, avant que les cartes ne changent (sinon il tomberait de l'ancienne carte libérée).
- **(AN) Caméra** : l'avance dans le sens de la marche ne fait que compenser le retard du suivi (lead_time = 1 / follow_speed) ; un plafond (vitesse × lead_time au-delà du point visé au repos, zéro pendant un freinage) supprime le dépassement à l'arrêt. La marge aux bords (12 % de l'écran) l'emporte sur les bornes de la carte : au bord d'une carte, on voit un peu au-delà des bornes plutôt que le joueur collé au bord de l'écran.
- **(AN) Respiration des PNJ** : l'étirement de 2 % est supprimé, sans remplacement par un décalage d'un pixel (tout le sprite, pieds compris, bougerait) ; la respiration est celle des deux images de repos de la planche, avec une horloge décalée au hasard pour chaque PNJ (plus d'unisson).
