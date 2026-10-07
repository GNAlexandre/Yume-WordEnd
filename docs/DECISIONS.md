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
