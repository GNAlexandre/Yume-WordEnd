extends Node
## WorldManager : cartes, points d'arrivée, réapparition, rattrapage des chutes et voyages
## (PLAN.md section 3 ; docs/REFONTE.md, section 7.1). Propriétaires : L2, puis E1 (cartes), X1
## (îles), F1 (zones de l'ancienne île retirées).
##
## Cartes (E1) :
## - une seule carte (Map, src/world/map.gd) est chargée à la fois, sous le nœud « World » de
##   game.tscn (groupe MAP_SLOT_GROUP) ; le joueur, la caméra et l'interface restent dans
##   game.tscn ;
## - go_to(map_id, marker) : fondu au noir (fade_alpha(), dessiné par src/ui/map_fade.gd),
##   chargement découpé en images (export Web mono-thread : les dépendances d'abord, au plus
##   load_budget_ms de travail par image, comme src/ui/loading.gd), retrait et libération de
##   l'ancienne carte, ajout de la nouvelle, joueur posé au sol sous le marqueur et tourné comme
##   lui (−Z), vitesse nulle, lissage physique remis à zéro ; EventBus.map_entered (la caméra se
##   recale et prend les bornes de la carte), puis fondu de retour. Le joueur est figé
##   (process_mode DISABLED : ni mouvement, ni coup, ni interaction) du début du fondu à la fin
##   du retour ; (AN) un Player n'a que ses commandes figées (hold_input) pendant le fondu au
##   noir (il s'arrête, finit son pas, passe au repos), puis est figé une fois l'écran noir ; is_transitioning() reste vrai SETTLE_FRAMES images physiques de plus, le temps
##   que les sorties voient le joueur : une sortie où l'on arrive ne repart pas aussitôt ;
## - enter_map(map_id, marker, at) : la même chose sans fondu ni chargement découpé (début de
##   partie : main.gd a déjà chargé la carte avec l'écran de chargement ; démonstrations) ;
## - GameState.map et GameState.position suivent la carte courante (sauvegarde) ; une carte
##   inconnue au chargement d'une partie ramène à start_map.
##
## Réapparition et rattrapage (L2, repris pour les cartes) :
## - respawn() ramène le joueur (groupe "player") au marqueur par lequel il est arrivé dans la
##   carte, au ras du sol (rayon vers le bas sur la couche world, décor statique seulement),
##   tourné comme le marqueur, et émet player_respawned (PlayerCombat remet les PV au maximum) ;
##   déclenché respawn_delay secondes après EventBus.player_died, si le joueur mort est toujours
##   dans l'arbre ;
## - rescue() ramène le joueur au dernier point sûr ou au marqueur d'arrivée (règle void_fall de
##   l'île) quand il passe sous FALL_LIMIT ; (Systèmes et textes) émet alors rescued(map_id), sur
##   lequel le HUD montre ses ailes (fondu au blanc) et le message de data/texts/story.json.
##
## Îles (X1, docs/REFONTE.md 11.1 ; PLAN.md, « Ajouter une île ») :
## - chaque carte posée donne l'île courante (WorldAtlas.island_of) : GameState.island et les îles
##   connues suivent, et EventBus.island_entered est émis quand l'île change (voyage, sortie,
##   début de partie) ;
## - travel(island_id, port) : le voyage en dirigeable ; fondu au noir, vue du ciel qui défile
##   (src/world/travel_view.tscn, au moins travel_time s, pendant que la carte d'arrivée se
##   charge en petites tranches), puis la carte d'arrivée au marqueur du port, fondu de retour ;
## - une chute hors de l'île ramène au dernier point sûr (règle void_fall de l'île : last_safe) ou
##   au marqueur d'arrivée (arrival) ; le dernier point sûr est la dernière place au sol du joueur
##   à au moins SAFE_MARGIN m du vide ;
## - raccourci de développement : F6 (version de débogage) part vers l'île suivante de l'atlas ;
##   ?island=<id>&port=<id> sur le Web (src/test_shortcuts.gd).

## (Systèmes et textes) Le joueur vient d'être rattrapé après une chute (rescue) dans la carte
## map_id : message « Tes ailes se sont ouvertes… » du HUD.
signal rescued(map_id: StringName)
## (E1) Un changement de carte commence : fondu au noir pendant fade_time s vers map_id.
signal transition_started(map_id: StringName)
## (E1) Le changement de carte est fini : fondu de retour terminé, joueur rendu.
signal transition_finished(map_id: StringName)
## (X1) Un voyage en dirigeable commence (vers island_id), avant le fondu au noir.
signal travel_started(island_id: StringName)
## (X1) Le voyage est fini : carte d'arrivée posée, fondu de retour terminé.
signal travel_finished(island_id: StringName)

const SPAWN_MARKER := &"Spawn"
const PLAYER_GROUP := &"player"
## (E1) Carte d'une nouvelle partie (et d'une sauvegarde dont la carte n'existe plus). (E6) La
## carte d'arrivée de l'île n° 68 (data/world/islands/ile_68.json, arrival_map) : une nouvelle
## partie ouvre l'acte 1 en jours (StoryDirector).
const START_MAP := &"entrepot"
## (E1) Groupe du nœud qui porte la carte courante (« World » de game.tscn).
const MAP_SLOT_GROUP := &"map_slot"
## Couche « world » (1) : sol et décor sur lesquels on pose le joueur.
const WORLD_MASK := 1
## Sous cette hauteur (m), le joueur est rattrapé (rescue).
const FALL_LIMIT := -30.0
## Le rayon qui cherche le sol part GROUND_PROBE_UP m au-dessus du marqueur et descend de
## GROUND_PROBE_DOWN m ; le joueur est posé GROUND_CLEARANCE m au-dessus du point touché.
const GROUND_PROBE_UP := 1.5
const GROUND_PROBE_DOWN := 30.0
const GROUND_CLEARANCE := 0.05
## (E1) Images physiques après une arrivée pendant lesquelles is_transitioning() reste vrai.
const SETTLE_FRAMES := 3
## (E1) Durée de chaque fondu (s) et travail de chargement par image (ms), par défaut : sous le
## noir, rien ne bouge à l'écran, une image tous les 100 ms suffit à garder la page vivante.
const DEFAULT_FADE_TIME := 0.35
const DEFAULT_LOAD_BUDGET_MS := 100.0
## (E1) Bornes de la caméra sans carte (scène de test sans carte) : un grand carré autour de
## l'origine, celui de CameraRig.limits.
const DEFAULT_CAMERA_BOUNDS := Rect2(-71.0, -70.0, 142.0, 136.0)
## Ordre de chargement des dépendances (feuilles d'abord) : celui de l'écran de chargement.
const LoadingScript := preload("res://src/ui/loading.gd")
## (X1) Scène de voyage (chargée à la demande, jamais gardée en mémoire).
const TRAVEL_VIEW_PATH := "res://src/world/travel_view.tscn"
## (X1) Durée minimale de la vue du ciel d'un voyage (s) et travail de chargement par image
## pendant qu'elle défile (ms : elle doit rester fluide).
const DEFAULT_TRAVEL_TIME := 3.2
const DEFAULT_TRAVEL_LOAD_BUDGET_MS := 12.0
## (X1) Un point est sûr s'il n'y a pas de vide à moins de SAFE_MARGIN m autour (sol en relief)
## et que le joueur touche le sol, à SAFE_HEIGHT m près ; vérifié toutes les SAFE_INTERVAL images
## physiques.
const SAFE_MARGIN := 1.5
const SAFE_HEIGHT := 0.3
const SAFE_INTERVAL := 4
## (X1) Touche de débogage : voyage vers l'île suivante de l'atlas.
const TRAVEL_KEYCODE := KEY_F6

## Délai entre la mort du joueur et sa réapparition (animation de mort + fondu, jeu.js : 2,2 s).
var respawn_delay: float = 2.2
## (E1) Durée de chacun des deux fondus d'un changement de carte (s) ; 0 : sans fondu.
var fade_time: float = DEFAULT_FADE_TIME
## (E1) Travail de chargement par image pendant un changement de carte (ms).
var load_budget_ms: float = DEFAULT_LOAD_BUDGET_MS
## (X1) Durée minimale de la vue du ciel d'un voyage (s) ; 0 : une image (tests).
var travel_time: float = DEFAULT_TRAVEL_TIME
## (X1) Travail de chargement par image pendant la vue du ciel (ms).
var travel_load_budget_ms: float = DEFAULT_TRAVEL_LOAD_BUDGET_MS
## (X1) Touche F6 active (voyage vers l'île suivante) : version de débogage.
var debug_keys: bool = false
## (E6) Carte d'une nouvelle partie (START_MAP) ; un test peut en poser une autre (une carte
## d'essai) et la rétablit après lui, comme respawn_delay.
var start_map: StringName = START_MAP

## Carte posée par WorldManager (voir current_map_node()).
var _map: Map
## Marqueur par lequel le joueur est arrivé dans la carte courante (réapparition, rattrapage).
var _arrival_marker: StringName = SPAWN_MARKER
var _busy: bool = false
var _settle_frames: int = 0
## Opacité du fondu au noir (0..1), animée pendant un changement de carte.
var _fade: float = 0.0
var _last_transition: Dictionary = {}
## process_mode du joueur figé pendant le changement de carte.
var _frozen_mode: ProcessMode = PROCESS_MODE_INHERIT
## (X1) Île de la carte posée (&"" : aucune, ou carte hors de toute île).
var _island: StringName = &""
## (X1) Voyage en cours (son île d'arrivée, &"" sinon) et vue du ciel ouverte.
var _traveling: StringName = &""
var _travel_view: TravelView = null
## (X1) Dernier point sûr de la carte courante (rattrapage d'une chute) ; valide si _has_safe.
var _last_safe: Vector3 = Vector3.ZERO
var _has_safe: bool = false
var _safe_countdown: int = 0


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_loaded.connect(_on_game_loaded)
	debug_keys = OS.is_debug_build()


func _physics_process(_delta: float) -> void:
	if _settle_frames > 0:
		_settle_frames -= 1
	var player := _player()
	if player != null and not _busy and player.global_position.y < FALL_LIMIT:
		rescue()
	elif player != null and not _busy:
		_track_safe_point(player)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not debug_keys or key == null or not key.pressed or key.echo:
		return
	if key.keycode == TRAVEL_KEYCODE and _map_slot() != null and not is_transitioning():
		var next := next_island()
		if not next.is_empty():
			travel(next)
			get_viewport().set_input_as_handled()


# --- Cartes (E1) ------------------------------------------------------------------------------


## Change de carte : fondu au noir, chargement découpé en images, nouvelle carte à la place de
## l'ancienne, joueur posé sur le marqueur (Spawn s'il n'existe pas), map_entered, fondu de
## retour. Sans effet (avertissement) pendant un autre changement ; carte inconnue : erreur.
## Coroutine : `await WorldManager.go_to(&"essai")` attend la fin du fondu de retour.
func go_to(map_id: StringName, marker: StringName = SPAWN_MARKER) -> void:
	await _change_map(map_id, marker, &"")


## (X1) Voyage en dirigeable vers island_id : fondu au noir, vue du ciel qui défile (au moins
## travel_time s, la carte d'arrivée se charge pendant ce temps), puis la carte d'arrivée posée au
## marqueur du port (WorldAtlas.arrival : le port nommé, sinon le premier port de l'île, sinon sa
## carte d'arrivée au Spawn), fondu de retour. Émet travel_started, puis (en plus des signaux de
## go_to et d'island_entered) travel_finished. Sans effet (avertissement) pendant un autre
## changement ; île ou port inconnus : erreur. Coroutine, comme go_to.
func travel(island_id: StringName, port: StringName = &"") -> void:
	var target := WorldAtlas.arrival(island_id, port)
	if target.is_empty():
		push_error("WorldManager : voyage impossible vers %s (port « %s »)" % [island_id, port])
		return
	await _change_map(target["map"], target["marker"], island_id)


## (X1) Île de la carte courante (&"" sans carte, ou carte hors de toute île).
func current_island() -> StringName:
	return _island


## (X1) Vrai pendant un voyage (de travel() à la fin du fondu de retour).
func is_traveling() -> bool:
	return not _traveling.is_empty()


## (X1) Vue du ciel du voyage en cours (null hors de la vue).
func travel_view() -> TravelView:
	return _travel_view if is_instance_valid(_travel_view) else null


## (X1) Île suivante de l'atlas (WorldAtlas.islands()), en boucle ; &"" s'il n'y en a pas
## d'autre. Touche F6.
func next_island() -> StringName:
	var ids: Array[StringName] = []
	for island_id: StringName in WorldAtlas.islands():
		if not WorldAtlas.arrival(island_id).is_empty():
			ids.append(island_id)
	if ids.is_empty():
		return &""
	var next := ids[(ids.find(_island) + 1) % ids.size()]
	return next if next != _island else &""


## (X1) Dernier point sûr de la carte courante (Vector3.INF s'il n'y en a pas encore).
func last_safe_point() -> Vector3:
	return _last_safe if _has_safe else Vector3.INF


## Changement de carte (go_to), ou voyage si voyage_island n'est pas vide (travel).
func _change_map(map_id: StringName, marker: StringName, voyage_island: StringName) -> void:
	if _busy:
		push_warning("WorldManager : changement de carte en cours, %s ignoré" % map_id)
		return
	if not Map.exists(map_id):
		push_error("WorldManager : carte inconnue %s" % map_id)
		return
	var slot := _map_slot()
	if slot == null:
		push_error("WorldManager : aucun nœud du groupe %s pour la carte" % MAP_SLOT_GROUP)
		return
	_busy = true
	_traveling = voyage_island
	var started := Time.get_ticks_usec()
	var player := _player()
	_freeze(player)
	if not voyage_island.is_empty():
		travel_started.emit(voyage_island)
	transition_started.emit(map_id)
	await _fade_to(1.0)
	# (AN) Écran noir : le joueur, qui a fini son pas, quitte la physique avant les cartes.
	_apply_freeze(player if is_instance_valid(player) else null)
	var faded := Time.get_ticks_usec()
	# Écran noir : le monde 3D n'est plus dessiné pendant le chargement (une image ne coûte plus
	# que l'interface : le chargement découpé avance bien plus vite, surtout sur le Web).
	_set_world_hidden(true)
	var budget := load_budget_ms
	if not voyage_island.is_empty():
		_open_travel_view(voyage_island)
		budget = travel_load_budget_ms
	var scene: PackedScene = null
	var frames := 0
	var current := current_map_node()
	var needs_load := current == null or current.map_id() != map_id
	if is_instance_valid(slot) and needs_load:
		var loaded: Array = await _load_in_frames(Map.scene_path(map_id), budget)
		scene = loaded[0] as PackedScene
		frames = int(loaded[1])
	await _close_travel_view()
	if not is_instance_valid(slot) or not slot.is_inside_tree():
		# La partie a été libérée pendant le fondu (retour au menu) : rien à installer.
		_set_world_hidden(false)
		_finish(player if is_instance_valid(player) else null)
		return
	var loaded_at := Time.get_ticks_usec()
	var installed := not (needs_load and scene == null) and _install(scene, map_id, marker, null)
	if not installed:
		push_error("WorldManager : carte %s illisible, on reste ici" % map_id)
	var installed_at := Time.get_ticks_usec()
	# Une image de la nouvelle carte sous le noir (constructions différées, premiers shaders),
	# puis le retour.
	_set_world_hidden(false)
	await get_tree().process_frame
	await _fade_to(0.0)
	_finish(player if is_instance_valid(player) else null)
	if not installed:
		return
	_last_transition = {
		"map": map_id,
		"marker": _arrival_marker,
		"fade_out_ms": (faded - started) / 1000.0,
		"load_ms": (loaded_at - faded) / 1000.0,
		"load_frames": frames,
		"install_ms": (installed_at - loaded_at) / 1000.0,
		"total_ms": (Time.get_ticks_usec() - started) / 1000.0,
		"island": voyage_island,
	}
	transition_finished.emit(map_id)
	if not voyage_island.is_empty():
		travel_finished.emit(voyage_island)


## Pose la carte map_id tout de suite (sans fondu, chargement d'un bloc ou depuis le cache) et
## y place le joueur : à la position `at` (Vector3, partie chargée) si elle est donnée, sinon
## au sol sous le marqueur, tourné comme lui. Émet map_entered. Faux si la carte est inconnue
## ou s'il n'y a pas de nœud World.
func enter_map(map_id: StringName, marker: StringName = SPAWN_MARKER, at: Variant = null) -> bool:
	if not Map.exists(map_id):
		push_error("WorldManager : carte inconnue %s" % map_id)
		return false
	if _map_slot() == null:
		push_error("WorldManager : aucun nœud du groupe %s pour la carte" % MAP_SLOT_GROUP)
		return false
	var current := current_map_node()
	var scene: PackedScene = null
	if current == null or current.map_id() != map_id:
		scene = load(Map.scene_path(map_id)) as PackedScene
	return _install(scene, map_id, marker, at)


## Identifiant de la carte courante (&"" sans carte).
func current_map() -> StringName:
	var map := current_map_node()
	return map.map_id() if map != null else &""


## Carte courante : celle que WorldManager a posée, ou à défaut la première carte de l'arbre
## (démonstration qui ajoute une carte à la main) ; null sans carte.
func current_map_node() -> Map:
	if is_instance_valid(_map) and _map.is_inside_tree() and not _map.is_queued_for_deletion():
		return _map
	_map = null
	for node: Node in get_tree().get_nodes_in_group(Map.GROUP):
		if node is Map and not node.is_queued_for_deletion():
			_map = node as Map
			return _map
	return null


## Carte où commence la partie : GameState.map si elle existe ; sinon (nouvelle partie, carte
## disparue) start_map (START_MAP, l'entrepôt de l'île n° 68). (F1) Une partie de l'ancienne île
## n'arrive plus ici : SaveManager la remplace par une nouvelle partie de l'acte 1.
func starting_map() -> StringName:
	if Map.exists(GameState.map):
		return GameState.map
	return start_map if Map.exists(start_map) else START_MAP


## Nom affiché d'une carte (Map.display_name) ; "" pour une carte inconnue ou sans nom. Lit la
## carte courante, sinon la scène de la carte (sans l'instancier).
func map_display_name(map_id: StringName) -> String:
	var current := current_map_node()
	if current != null and current.map_id() == map_id:
		return current.display_name
	if not Map.exists(map_id):
		return ""
	var state := (load(Map.scene_path(map_id)) as PackedScene).get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == &"display_name":
			return str(state.get_node_property_value(0, i))
	return ""


## Bornes du point visé par la caméra dans la carte courante (Map.bounds()), en x et z ;
## DEFAULT_CAMERA_BOUNDS sans carte.
func camera_bounds() -> Rect2:
	var map := current_map_node()
	return map.bounds() if map != null else DEFAULT_CAMERA_BOUNDS


## Vrai pendant un changement de carte (fondus, chargement) et SETTLE_FRAMES images physiques
## après une arrivée : les sorties (MapExit) ne partent pas.
func is_transitioning() -> bool:
	return _busy or _settle_frames > 0


## Opacité du fondu au noir d'un changement de carte (0 : rien, 1 : écran noir).
func fade_alpha() -> float:
	return _fade


## Marqueur par lequel le joueur est arrivé dans la carte courante.
func arrival_marker() -> StringName:
	return _arrival_marker


## Mesures du dernier go_to() : map, marker, fade_out_ms, load_ms (chargement découpé),
## load_frames (images qu'il a duré), install_ms (ancienne carte libérée, nouvelle instanciée et
## ajoutée, joueur posé : une seule image), total_ms (fondus compris). {} avant le premier.
func last_transition() -> Dictionary:
	return _last_transition.duplicate()


# --- Réapparition et rattrapage (L2) --------------------------------------------------------


## Réapparition avec PV pleins (appliqués par PlayerCombat) : au marqueur par lequel le joueur
## est arrivé dans la carte (sans carte : rien ne bouge).
func respawn() -> void:
	var map := current_map_node()
	if map != null:
		_place_at_marker(map, _arrival_marker)
	EventBus.player_respawned.emit()


## Rattrapage : ramène le joueur, (X1) au dernier point sûr si la règle void_fall de l'île le
## veut, sinon au marqueur d'arrivée, puis émet rescued (message du HUD). Sans carte : rien.
func rescue() -> void:
	var map := current_map_node()
	if _player() == null or map == null:
		return
	var rules := WorldAtlas.rules_for(map.map_id())
	if rules.void_fall == IslandRules.FALL_LAST_SAFE and _has_safe:
		_place_at(_last_safe)
	else:
		_place_at_marker(map, _arrival_marker)
	rescued.emit(map.map_id())


## Point au ras du décor statique (couche world) sous `point`, ou `point` s'il n'y a rien
## dessous. `body` (le joueur) est ignoré, ainsi que les corps non statiques (PNJ…).
func ground_position(point: Vector3, body: Node3D = null) -> Vector3:
	if body == null or not body.is_inside_tree():
		return point
	var space := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		point + Vector3.UP * GROUND_PROBE_UP, point + Vector3.DOWN * GROUND_PROBE_DOWN, WORLD_MASK
	)
	var excluded: Array[RID] = []
	if body is CollisionObject3D:
		excluded.append((body as CollisionObject3D).get_rid())
	for _attempt in 4:
		query.exclude = excluded
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return point
		if hit["collider"] is StaticBody3D:
			return (hit["position"] as Vector3) + Vector3.UP * GROUND_CLEARANCE
		excluded.append(hit["rid"] as RID)
	return point


# --- Interne ----------------------------------------------------------------------------------


## Remplace la carte courante par une instance de scene (null : même carte, seul le joueur
## bouge), place le joueur, met à jour GameState et émet map_entered.
func _install(scene: PackedScene, map_id: StringName, marker: StringName, at: Variant) -> bool:
	var slot := _map_slot()
	var map := current_map_node()
	if scene != null:
		var fresh := scene.instantiate() as Map
		if fresh == null:
			push_error("WorldManager : %s n'a pas une Map pour racine" % Map.scene_path(map_id))
			return false
		if map != null:
			# L'ancienne carte part avant que la nouvelle n'entre : une seule en mémoire.
			map.get_parent().remove_child(map)
			map.free()
		fresh.name = map_id
		slot.add_child(fresh)
		map = fresh
	_map = map
	var player := _player()
	if player != null:
		if at is Vector3:
			player.global_position = at
			player.reset_physics_interpolation()
			_arrival_marker = SPAWN_MARKER
			if player is CharacterBody3D:
				(player as CharacterBody3D).velocity = Vector3.ZERO
		else:
			_place_at_marker(map, marker)
	GameState.map = map_id
	if player != null:
		GameState.position = player.global_position
		_last_safe = player.global_position
		_has_safe = true
	_settle_frames = SETTLE_FRAMES
	EventBus.map_entered.emit(map_id)
	_enter_island(WorldAtlas.island_of(map_id))
	return true


## (X1) L'île de la carte posée : GameState.island, îles connues, island_entered si elle change.
func _enter_island(island_id: StringName) -> void:
	GameState.island = island_id
	GameState.discover_island(island_id)
	if island_id == _island:
		return
	_island = island_id
	if not island_id.is_empty():
		EventBus.island_entered.emit(island_id)


## (X1) Ouvre la vue du ciel d'un voyage (au-dessus de tout, sous le noir qu'elle lève).
func _open_travel_view(island_id: StringName) -> void:
	var packed := load(TRAVEL_VIEW_PATH) as PackedScene
	if packed == null:
		return
	_travel_view = packed.instantiate() as TravelView
	get_tree().root.add_child(_travel_view)
	_travel_view.begin(island_id, fade_time)


## (X1) Ferme la vue du ciel (après travel_time s au moins, fondu au noir) et la libère.
func _close_travel_view() -> void:
	if not is_instance_valid(_travel_view):
		_travel_view = null
		return
	await _travel_view.close(travel_time)
	if is_instance_valid(_travel_view):
		_travel_view.queue_free()
	_travel_view = null


## (X1) Retient la place du joueur comme dernier point sûr (toutes les SAFE_INTERVAL images
## physiques) s'il touche le sol (à SAFE_HEIGHT m près) loin du vide : sur un sol en relief, aucune
## case vide à SAFE_MARGIN m ; ailleurs, le décor statique juste dessous (ground_position).
func _track_safe_point(player: Node3D) -> void:
	_safe_countdown -= 1
	if _safe_countdown > 0 or _settle_frames > 0:
		return
	_safe_countdown = SAFE_INTERVAL
	var map := current_map_node()
	if map == null:
		return
	var at := player.global_position
	var ground := map.get_node_or_null(^"Ground") as MapGround
	if ground != null and ground.data != null:
		var local := map.to_local(at)
		var height := ground.height_at(local.x, local.z)
		if height == MapGround.VOID_HEIGHT or absf(local.y - height) > SAFE_HEIGHT:
			return
		for offset: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var probe := Vector2(local.x, local.z) + offset * SAFE_MARGIN
			if ground.height_at(probe.x, probe.y) == MapGround.VOID_HEIGHT:
				return
	else:
		# ground_position rend le point lui-même s'il n'y a rien dessous.
		var floor_at := ground_position(at, player)
		if floor_at.is_equal_approx(at) or absf(at.y - floor_at.y) > SAFE_HEIGHT:
			return
	_last_safe = at
	_has_safe = true


## (X1) Pose le joueur à point (dernier point sûr), vitesse nulle, sans changer son regard.
func _place_at(point: Vector3) -> void:
	var player := _player()
	if player == null:
		return
	player.global_position = point
	player.reset_physics_interpolation()
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO


## Pose le joueur au sol sous le marqueur marker_name de la carte (Spawn s'il n'existe pas),
## tourné comme lui, vitesse nulle.
func _place_at_marker(map: Map, marker_name: StringName) -> void:
	var player := _player()
	var target := map.marker(marker_name)
	if target == null:
		target = map.spawn()
	if player == null or target == null:
		return
	_arrival_marker = StringName(target.name)
	player.global_position = ground_position(target.global_position, player)
	player.reset_physics_interpolation()
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	if player.has_method(&"set_aim_direction"):
		player.call(&"set_aim_direction", -target.global_basis.z, true)


## Charge path en plusieurs images (dépendances d'abord, au plus budget_ms de travail par
## image) ; renvoie [PackedScene ou null, nombre d'images].
func _load_in_frames(path: String, budget_ms: float) -> Array:
	var kept: Array[Resource] = []
	var frames := 1
	var started := Time.get_ticks_msec()
	for dependency: String in LoadingScript.dependency_order(path):
		var resource := ResourceLoader.load(dependency)
		if resource != null:
			kept.append(resource)
		if Time.get_ticks_msec() - started >= budget_ms:
			await get_tree().process_frame
			frames += 1
			started = Time.get_ticks_msec()
	var scene := ResourceLoader.load(path) as PackedScene
	kept.clear()
	return [scene, frames]


func _fade_to(target: float) -> void:
	if fade_time <= 0.0 or is_equal_approx(_fade, target):
		_fade = target
		await get_tree().process_frame
		return
	var tween := create_tween()
	tween.tween_property(self, ^"_fade", target, fade_time * absf(target - _fade))
	await tween.finished


## Fin d'un changement de carte : joueur rendu, fondu levé, sorties sourdes encore
## SETTLE_FRAMES images physiques.
## player : le joueur figé au départ, ou null s'il a été libéré pendant le fondu (une valeur libérée
## ne passe pas un paramètre typé).
func _finish(player: Node3D) -> void:
	_fade = 0.0
	_traveling = &""
	if is_instance_valid(player):
		player.process_mode = _frozen_mode
		if player.has_method(&"hold_input"):
			player.call(&"hold_input", false)
	_settle_frames = SETTLE_FRAMES
	_busy = false


## Écran noir d'un changement de carte : le monde 3D de la fenêtre n'est plus dessiné
## (Viewport.disable_3d), l'interface si.
func _set_world_hidden(hidden: bool) -> void:
	get_tree().root.disable_3d = hidden


## Fige le joueur pendant le changement de carte (ni mouvement, ni coup, ni interaction), en
## fin d'image : go_to() part souvent de son image physique (interaction) ou du signal d'une
## sortie pendant le pas de la physique ; le retirer de l'espace physique à ce moment-là lui
## ferait finir son image sans espace (« Parameter "space" is null »).
## (AN) Un joueur qui sait figer ses seules commandes (Player.hold_input) n'est pas figé tout de
## suite : pendant le fondu au noir, il s'arrête, finit son pas et passe au repos au lieu de
## rester figé en pleine foulée ; _change_map le retire de la physique une fois l'écran noir
## (_apply_freeze), avant de toucher aux cartes. _finish lui rend ses commandes.
func _freeze(player: Node3D) -> void:
	if player == null:
		return
	_frozen_mode = player.process_mode
	if player.has_method(&"hold_input"):
		player.call(&"hold_input", true)
		return
	_apply_freeze.call_deferred(player)


func _apply_freeze(player: Node3D) -> void:
	if _busy and is_instance_valid(player):
		player.process_mode = PROCESS_MODE_DISABLED


func _player() -> Node3D:
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D


## Nœud qui porte la carte courante : « World » de game.tscn (groupe MAP_SLOT_GROUP), à défaut
## le parent de la carte courante.
func _map_slot() -> Node:
	var slot := get_tree().get_first_node_in_group(MAP_SLOT_GROUP)
	if slot != null:
		return slot
	var map := current_map_node()
	return map.get_parent() if map != null else null


func _on_game_loaded() -> void:
	# Une partie commence : l'île de sa première carte s'annoncera (island_entered).
	_island = &""
	_has_safe = false


func _on_player_died() -> void:
	# Seul le joueur mort réapparaît : s'il a quitté l'arbre entre-temps (retour au menu, fin
	# d'un test), rien ne se passe. Le délai s'arrête pendant la pause.
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)
	await get_tree().create_timer(respawn_delay, false).timeout
	if player != null and is_instance_valid(player) and player.is_inside_tree():
		respawn()
