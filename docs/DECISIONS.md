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
