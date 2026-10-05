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
