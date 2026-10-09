extends Node
## WorldManager : cartes, zones de l'ancienne île, points d'apparition, téléportation et
## réapparition (PLAN.md section 3 ; docs/REFONTE.md, section 7.1). Propriétaires : L2, puis E1
## (cartes).
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
##   du retour ; is_transitioning() reste vrai SETTLE_FRAMES images physiques de plus, le temps
##   que les zones voient le joueur : une sortie où l'on arrive ne repart pas aussitôt ;
## - enter_map(map_id, marker, at) : la même chose sans fondu ni chargement découpé (début de
##   partie : main.gd a déjà chargé la carte avec l'écran de chargement ; démonstrations) ;
## - GameState.map et GameState.position suivent la carte courante (sauvegarde) ; une carte
##   inconnue au chargement d'une partie ramène à START_MAP.
##
## Zones (L2, carte héritée `ile_ancienne` seulement) :
## - les zones sont les nœuds du groupe "zones" (racines Zone nommées comme leur zone_id) ;
##   load_zone() ne fait rien si la zone est là ; une zone de l'ancienne île demandée ailleurs
##   y ramène (enter_map(LEGACY_MAP), sans fondu) ;
## - teleport() pose le joueur (groupe "player") sur un Marker3D de la zone, au ras du sol
##   (rayon vers le bas sur la couche world, décor statique seulement) et annule sa vitesse ;
## - respawn() le ramène au Spawn du village (sur une carte sans village : au marqueur par
##   lequel il est arrivé), tourné comme le marqueur, et émet player_respawned (PlayerCombat
##   remet les PV au maximum) ; déclenché respawn_delay secondes après EventBus.player_died, si
##   le joueur mort est toujours dans l'arbre ;
## - rescue() ramène le joueur au Spawn de la zone courante (sans zone : au marqueur d'arrivée
##   de la carte) : appelé par la KillZone de l'île et, en filet de sécurité, quand le joueur
##   passe sous FALL_LIMIT ; (Systèmes et textes) émet alors rescued(zone_id), sur lequel le
##   HUD montre ses ailes (fondu au blanc) et le message de data/texts/story.json ;
## - zone_entered met à jour current_zone() et GameState.zone ; un changement de carte les vide
##   (et oublie la dernière zone annoncée sur le joueur) : la zone d'arrivée s'annonce de nouveau ;
## - is_zone_safe() dit si une zone est sûre (Zone.safe), pour l'IA des Timeres.

## (Systèmes et textes) Le joueur vient d'être rattrapé après une chute (rescue), au Spawn de
## zone_id (ou, sur une carte sans zone, à son marqueur d'arrivée : zone_id = map_id) :
## message « Tes ailes se sont ouvertes… » du HUD.
signal rescued(zone_id: StringName)
## (E1) Un changement de carte commence : fondu au noir pendant fade_time s vers map_id.
signal transition_started(map_id: StringName)
## (E1) Le changement de carte est fini : fondu de retour terminé, joueur rendu.
signal transition_finished(map_id: StringName)

const VILLAGE := &"village"
const SPAWN_MARKER := &"Spawn"
const ZONES_GROUP := &"zones"
const PLAYER_GROUP := &"player"
## (E1) Carte héritée : l'île à cinq zones, jouable jusqu'à la phase 5 de la refonte.
const LEGACY_MAP := &"ile_ancienne"
## (E1) Carte d'une nouvelle partie (et d'une sauvegarde dont la carte n'existe plus).
const START_MAP := &"ile_ancienne"
## (E1) Zones de la carte héritée : load_zone() et teleport() y ramènent.
const LEGACY_ZONES: Array[StringName] = [&"village", &"dunes", &"forest", &"beach", &"hill"]
## (E1) Groupe du nœud qui porte la carte courante (« World » de game.tscn).
const MAP_SLOT_GROUP := &"map_slot"
## Couche « world » (1) : sol et décor sur lesquels on pose le joueur.
const WORLD_MASK := 1
## Sous cette hauteur (m), le joueur est rattrapé (rescue) même sans KillZone.
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
## (E1) Bornes de la caméra sans carte : celles de l'ancienne île.
const DEFAULT_CAMERA_BOUNDS := Rect2(-71.0, -70.0, 142.0, 136.0)
## Ordre de chargement des dépendances (feuilles d'abord) : celui de l'écran de chargement.
const LoadingScript := preload("res://src/ui/loading.gd")

## Délai entre la mort du joueur et sa réapparition (animation de mort + fondu, jeu.js : 2,2 s).
var respawn_delay: float = 2.2
## (E1) Durée de chacun des deux fondus d'un changement de carte (s) ; 0 : sans fondu.
var fade_time: float = DEFAULT_FADE_TIME
## (E1) Travail de chargement par image pendant un changement de carte (ms).
var load_budget_ms: float = DEFAULT_LOAD_BUDGET_MS

var _current_zone: StringName = &""
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


func _ready() -> void:
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.player_died.connect(_on_player_died)


func _physics_process(_delta: float) -> void:
	if _settle_frames > 0:
		_settle_frames -= 1
	var player := _player()
	if player != null and not _busy and player.global_position.y < FALL_LIMIT:
		rescue()


# --- Cartes (E1) ------------------------------------------------------------------------------


## Change de carte : fondu au noir, chargement découpé en images, nouvelle carte à la place de
## l'ancienne, joueur posé sur le marqueur (Spawn s'il n'existe pas), map_entered, fondu de
## retour. Sans effet (avertissement) pendant un autre changement ; carte inconnue : erreur.
## Coroutine : `await WorldManager.go_to(&"essai")` attend la fin du fondu de retour.
func go_to(map_id: StringName, marker: StringName = SPAWN_MARKER) -> void:
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
	var started := Time.get_ticks_usec()
	var player := _player()
	_freeze(player)
	transition_started.emit(map_id)
	await _fade_to(1.0)
	var faded := Time.get_ticks_usec()
	# Écran noir : le monde 3D n'est plus dessiné pendant le chargement (une image ne coûte plus
	# que l'interface : le chargement découpé avance bien plus vite, surtout sur le Web).
	_set_world_hidden(true)
	var scene: PackedScene = null
	var frames := 0
	var current := current_map_node()
	var needs_load := current == null or current.map_id() != map_id
	if is_instance_valid(slot) and needs_load:
		var loaded: Array = await _load_in_frames(Map.scene_path(map_id))
		scene = loaded[0] as PackedScene
		frames = int(loaded[1])
	if not is_instance_valid(slot) or not slot.is_inside_tree():
		# La partie a été libérée pendant le fondu (retour au menu) : rien à installer.
		_set_world_hidden(false)
		_finish(player)
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
	_finish(player)
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
	}
	transition_finished.emit(map_id)


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


## Carte où commence la partie : GameState.map si elle existe, sinon START_MAP.
func starting_map() -> StringName:
	return GameState.map if Map.exists(GameState.map) else START_MAP


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


# --- Zones de l'ancienne île (L2) -------------------------------------------------------------


## S'assure que la zone est dans l'arbre : sans effet si elle y est ; une zone de l'ancienne île
## (LEGACY_ZONES) demandée dans une autre carte y ramène, sans fondu (s'il y a un nœud World où
## poser la carte ; sinon rien).
func load_zone(zone_id: StringName) -> void:
	if zone_id.is_empty() or _find_zone(zone_id) != null:
		return
	if zone_id in LEGACY_ZONES:
		if current_map() != LEGACY_MAP and _map_slot() != null and Map.exists(LEGACY_MAP):
			enter_map(LEGACY_MAP)
		return
	push_warning("WorldManager : zone inconnue %s" % zone_id)


## Pose le joueur sur le Marker3D `marker` de la zone, au ras du sol, et annule sa vitesse.
func teleport(zone_id: StringName, marker: StringName = SPAWN_MARKER) -> void:
	load_zone(zone_id)
	var zone := _find_zone(zone_id)
	var player := _player()
	if zone == null or player == null:
		return
	var target := zone.get_node_or_null(NodePath(String(marker))) as Node3D
	if target == null:
		target = zone.find_child(String(marker), true, false) as Node3D
	if target == null:
		return
	player.global_position = ground_position(target.global_position, player)
	# Lissage physique : pas de glissement de l'ancienne place à la nouvelle.
	player.reset_physics_interpolation()
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO


## Réapparition avec PV pleins (appliqués par PlayerCombat) : au Spawn du village sur l'ancienne
## île, sinon au marqueur par lequel le joueur est arrivé dans la carte.
func respawn() -> void:
	var map := current_map_node()
	if _find_zone(VILLAGE) != null or map == null:
		teleport(VILLAGE, SPAWN_MARKER)
		_face_marker(VILLAGE, SPAWN_MARKER)
	else:
		_place_at_marker(map, _arrival_marker)
	EventBus.player_respawned.emit()


## Rattrapage : ramène le joueur au Spawn de la zone courante (du village à défaut ; sur une
## carte sans zone, au marqueur d'arrivée), puis émet rescued (message du HUD).
func rescue() -> void:
	if _player() == null:
		return
	var zone := _current_zone if _find_zone(_current_zone) != null else VILLAGE
	var map := current_map_node()
	if _find_zone(zone) == null and map != null:
		_place_at_marker(map, _arrival_marker)
		rescued.emit(map.map_id())
		return
	teleport(zone, SPAWN_MARKER)
	rescued.emit(zone)


func current_zone() -> StringName:
	return _current_zone


## Vrai si la zone zone_id est sûre (Zone.safe, le village : aucun ennemi n'y poursuit le
## joueur) ; faux pour une zone inconnue ou &"". Les Timeres l'appellent avec current_zone().
func is_zone_safe(zone_id: StringName) -> bool:
	var zone := _find_zone(zone_id)
	return zone is Zone and (zone as Zone).safe


## Nom affiché d'une zone (Zone.display_name), ou son identifiant à défaut.
func zone_display_name(zone_id: StringName) -> String:
	var zone := _find_zone(zone_id)
	if zone is Zone and not (zone as Zone).display_name.is_empty():
		return (zone as Zone).display_name
	return String(zone_id)


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
			# Plus de zone : celle où l'on arrive s'annoncera (changement de zone). Au début
			# d'une partie (aucune carte avant), la zone de la sauvegarde reste.
			_current_zone = &""
			GameState.zone = &""
			var body := _player()
			if body != null:
				body.remove_meta(Zone.LAST_ZONE_META)
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
	_settle_frames = SETTLE_FRAMES
	EventBus.map_entered.emit(map_id)
	return true


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


## Charge path en plusieurs images (dépendances d'abord, au plus load_budget_ms de travail par
## image) ; renvoie [PackedScene ou null, nombre d'images].
func _load_in_frames(path: String) -> Array:
	var kept: Array[Resource] = []
	var frames := 1
	var started := Time.get_ticks_msec()
	for dependency: String in LoadingScript.dependency_order(path):
		var resource := ResourceLoader.load(dependency)
		if resource != null:
			kept.append(resource)
		if Time.get_ticks_msec() - started >= load_budget_ms:
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
func _finish(player: Node3D) -> void:
	_fade = 0.0
	if is_instance_valid(player):
		player.process_mode = _frozen_mode
	_settle_frames = SETTLE_FRAMES
	_busy = false


## Écran noir d'un changement de carte : le monde 3D de la fenêtre n'est plus dessiné
## (Viewport.disable_3d), l'interface si.
func _set_world_hidden(hidden: bool) -> void:
	get_tree().root.disable_3d = hidden


## Fige le joueur pendant le changement de carte (ni mouvement, ni coup, ni interaction), en
## fin d'image : go_to() part souvent de son image physique (interaction) ou du signal d'une
## zone pendant le pas de la physique ; le retirer de l'espace physique à ce moment-là lui
## ferait finir son image sans espace (« Parameter "space" is null »).
func _freeze(player: Node3D) -> void:
	if player == null:
		return
	_frozen_mode = player.process_mode
	_apply_freeze.call_deferred(player)


func _apply_freeze(player: Node3D) -> void:
	if _busy and is_instance_valid(player):
		player.process_mode = PROCESS_MODE_DISABLED


## Tourne le joueur (Player.set_aim_direction, caméra derrière lui) dans le sens du marqueur
## (−Z). Sans cela, la visée gardée de l'arène plaçait la caméra n'importe où autour du Spawn,
## parfois dans le feuillage d'un arbre.
func _face_marker(zone_id: StringName, marker: StringName) -> void:
	var zone := _find_zone(zone_id)
	var player := _player()
	if zone == null or player == null or not player.has_method(&"set_aim_direction"):
		return
	var target := zone.get_node_or_null(NodePath(String(marker))) as Node3D
	if target != null:
		player.call(&"set_aim_direction", -target.global_basis.z, true)


func _player() -> Node3D:
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D


func _find_zone(zone_id: StringName) -> Node3D:
	if zone_id.is_empty():
		return null
	for node: Node in get_tree().get_nodes_in_group(ZONES_GROUP):
		if node.name == zone_id and node is Node3D:
			return node as Node3D
	return null


## Nœud qui porte la carte courante : « World » de game.tscn (groupe MAP_SLOT_GROUP), à défaut
## le parent de la carte courante.
func _map_slot() -> Node:
	var slot := get_tree().get_first_node_in_group(MAP_SLOT_GROUP)
	if slot != null:
		return slot
	var map := current_map_node()
	return map.get_parent() if map != null else null


func _on_zone_entered(zone_id: StringName) -> void:
	_current_zone = zone_id
	GameState.zone = zone_id


func _on_player_died() -> void:
	# Seul le joueur mort réapparaît : s'il a quitté l'arbre entre-temps (retour au menu, fin
	# d'un test), rien ne se passe. Le délai s'arrête pendant la pause.
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)
	await get_tree().create_timer(respawn_delay, false).timeout
	if player != null and is_instance_valid(player) and player.is_inside_tree():
		respawn()
