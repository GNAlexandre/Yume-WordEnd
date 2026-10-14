extends Node
## (E4) LifeDirector (autoload) : le directeur de la vie (PLAN.md, « (E4) La vie »). À l'entrée sur
## une carte et à chaque changement de créneau, il décide qui est là et ce qu'il fait, d'après
## les emplois du temps (LifeData). Propriétaire : E4.
##
## - À l'entrée (EventBus.map_entered, sous le fondu) : chaque PNJ dont la ligne du créneau
##   courant est sur cette carte apparaît à sa place (Life/Places), déjà en activité, dans sa
##   tenue ; il est ajouté au nœud Life de la carte (npc.tscn, NpcData de data/npcs ou
##   data/npcs/generic). La navigation (LifeNav) se construit ensuite par morceaux (nav_budget_usec
##   par image).
## - Créneau changé pendant qu'on est là (LifeSlots.current(), GameState.day) : chacun part à
##   pied vers sa nouvelle place (délai de départ tiré, chemin par les portes) ; celui qui va sur
##   une autre carte ou hors des cartes gagne sa sortie (place vers_<carte>, sinon la MapExit vers
##   cette carte) et disparaît ; celui qui vient d'ailleurs entre par la sortie de sa carte
##   d'origine et marche jusqu'à sa place.
## - Hors de la carte, rien ne tourne : where(PNJ) consulte l'emploi du temps.
## - Chemins demandés en file (paths_per_frame par image) ; évitement entre PNJ et autour du
##   joueur (avoidance) ; jeux de groupe (LifeGame) ; une salutation à la fois (may_greet).
## - Rien n'est fait pour une carte posée à la main (démonstration, test d'une carte seule) :
##   attach(carte) la peuple ; l'ancienne île n'a pas d'emploi du temps, rien n'y change.
## Créneau : set_slot (le moment de lumière suit, par Atmosphere), next_slot ; F6 (créneau suivant,
## Maj : tout de suite) en version de débogage ou avec un paramètre ; ?creneau=midi (Web) ou
## -- --creneau=midi posé à chaque partie chargée ; ?vie=trace (mesures toutes les 2 s dans le
## journal), ?vie=off (directeur coupé : mesures « avant »), ?vie=cycle (créneau suivant toutes
## les 20 s : mesures pendant les trajets).

## Le créneau appliqué a changé (après les trajets lancés).
signal slot_changed(slot: StringName)
## Les PNJ de la carte courante ont été posés (entrée sur une carte).
signal populated(map_id: StringName)

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const PLAYER_GROUP := &"player"
const SLOT_KEY := "creneau"
const LIFE_KEY := "vie"
const SLOT_KEYCODE := KEY_F6
const TRACE_PERIOD := 2.0
const CYCLE_PERIOD := 20.0
## Départs étalés après un changement de créneau (s).
const DEPART_SPREAD := Vector2(0.2, 2.6)
## Une salutation au plus toutes les GREET_GAP s.
const GREET_GAP := 5.0
## Évitement : distance où l'on tient compte d'un autre (m), écart à droite d'un PNJ qui vient en
## face, distance où un obstacle arrêté bloque.
const AVOID_DISTANCE := 1.2
const KEEP_RIGHT := 0.9
const BLOCK_DISTANCE := 0.75
const BLOCK_LATERAL := 0.45

## Directeur actif (faux : rien n'est peuplé ; ?vie=off).
var enabled: bool = true
## Travail de construction de la navigation par image (µs).
var nav_budget_usec: int = 2500
## Chemins calculés par image au plus.
var paths_per_frame: int = 3
var debug_keys: bool = false
var trace: bool = false
var cycle: bool = false
var dev_parameters: Dictionary = {}

var _map: Map
var _nav: LifeNav
var _places: LifePlaces
var _actors: Dictionary = {}
var _games: Dictionary = {}
var _claims: Dictionary = {}
var _path_queue: Array[LifeActor] = []
var _slot: StringName = &""
var _day: int = 0
var _greet_left: float = 0.0
var _rng := RandomNumberGenerator.new()
var _stats := {}
var _trace_left: float = TRACE_PERIOD
var _cycle_left: float = CYCLE_PERIOD
## Tenue de la maison posée sur le joueur (player_home_outfit), null s'il porte sa planche.
var _player_home: SkinData = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.atmosphere_changed.connect(_on_atmosphere_changed)
	EventBus.dialogue_started.connect(_on_dialogue.bind(true))
	EventBus.dialogue_ended.connect(_on_dialogue.bind(false))
	EventBus.game_loaded.connect(_on_game_loaded)
	dev_parameters = read_parameters()
	debug_keys = OS.is_debug_build() or not dev_parameters.is_empty()
	var life := str(dev_parameters.get(LIFE_KEY, ""))
	enabled = life != "off"
	trace = life == "trace" or life == "cycle"
	cycle = life == "cycle"
	_reset_stats()


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var started := Time.get_ticks_usec()
	if _map != null and not is_instance_valid(_map):
		_clear()
	if _map == null or not _map.is_inside_tree():
		return
	if LifeSlots.current() != _slot or GameState.day != _day:
		_apply_slot(true)
	var nav_usec := 0
	if _nav != null and not _nav.ready:
		var nav_started := Time.get_ticks_usec()
		_nav.build_step(nav_budget_usec)
		nav_usec = Time.get_ticks_usec() - nav_started
	var path_started := Time.get_ticks_usec()
	_serve_paths()
	var path_usec := Time.get_ticks_usec() - path_started
	_greet_left = maxf(_greet_left - delta, 0.0)
	var player := player_node()
	for who: LifeActor in _actors.values():
		who.tick(delta, player)
	for game: LifeGame in _games.values():
		game.tick(delta, player)
	_record(Time.get_ticks_usec() - started, nav_usec, path_usec)
	if trace:
		_trace_left -= delta
		if _trace_left <= 0.0:
			_trace_left = TRACE_PERIOD
			print("[vie] %s" % stats_text())
			_reset_stats()
	if cycle:
		_cycle_left -= delta
		if _cycle_left <= 0.0:
			_cycle_left = CYCLE_PERIOD
			next_slot()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not debug_keys or key == null or not key.pressed or key.echo:
		return
	if key.keycode == SLOT_KEYCODE:
		next_slot(0.0 if key.shift_pressed else -1.0)
		get_viewport().set_input_as_handled()


# --- Créneaux ----------------------------------------------------------------------------------


## Créneau courant (LifeSlots.current()).
func slot() -> StringName:
	return LifeSlots.current()


## Passe au créneau slot : GameState.slot, et le moment de sa lumière par Atmosphere (transition
## de duration s ; < 0 : celle d'Atmosphere ; 0 : tout de suite). Les PNJ présents marchent vers
## leurs nouvelles places à l'image physique suivante.
func set_slot(new_slot: StringName, duration: float = -1.0) -> void:
	if not LifeSlots.is_slot(new_slot):
		push_warning("LifeDirector : créneau inconnu %s" % new_slot)
		return
	GameState.slot = new_slot
	var moment := LifeSlots.moment_of(new_slot)
	if GameState.moment != moment:
		Atmosphere.set_moment(moment, duration)


## Créneau suivant (après la nuit, l'aube).
func next_slot(duration: float = -1.0) -> void:
	set_slot(LifeSlots.next(slot()), duration)


## Ligne d'emploi du temps d'un PNJ pour le créneau courant (consultation, hors carte compris) :
## {map, place, away, activity, outfit, gait, role…} ; {} : nulle part.
func where(npc_id: StringName) -> Dictionary:
	return LifeData.current_line(npc_id)


## Relit les emplois du temps (le récit vient de changer un drapeau) : ceux dont la ligne a
## changé marchent vers leur nouvelle place (walk) ou y sont posés.
func refresh(walk: bool = true) -> void:
	if _map != null and is_instance_valid(_map):
		_apply_slot(walk)


# --- Carte -------------------------------------------------------------------------------------


## Peuple map (entrée sur la carte ; démonstration d'une carte posée à la main) : chaque PNJ dont
## la ligne courante est ici apparaît à sa place.
func attach(map: Map) -> void:
	_clear()
	_dress_player(map)
	if map == null or not enabled:
		return
	_map = map
	_places = LifePlaces.read(map)
	_nav = LifeNav.for_map(map)
	_slot = LifeSlots.current()
	_day = GameState.day
	for npc_id: StringName in LifeData.cast():
		var line := LifeData.line_for(npc_id, _slot, _day)
		if line.get("map", &"") == map.map_id():
			var placed := _spawn(npc_id)
			if placed != null:
				placed.place_now(line)
	populated.emit(map.map_id())


## Carte peuplée (null : aucune).
func current_map() -> Map:
	return _map if is_instance_valid(_map) else null


## Navigation de la carte courante (null sans carte).
func nav() -> LifeNav:
	return _nav


## Places de la carte courante (null sans carte).
func places() -> LifePlaces:
	return _places


## Construit tout de suite la navigation (tests, démonstrations).
func build_nav_now() -> void:
	if _nav != null:
		_nav.build_now()


# --- PNJ ---------------------------------------------------------------------------------------


## Le LifeActor d'un PNJ présent sur la carte (null sinon).
func actor(npc_id: StringName) -> LifeActor:
	return _actors.get(npc_id)


## Le nœud d'un PNJ présent sur la carte (null sinon).
func npc(npc_id: StringName) -> Npc:
	var found := actor(npc_id)
	return found.npc if found != null and is_instance_valid(found.npc) else null


## Les PNJ de la carte courante.
func actors() -> Array[LifeActor]:
	var result: Array[LifeActor] = []
	result.assign(_actors.values())
	return result


## Les jeux en cours sur la carte courante.
func games() -> Array[LifeGame]:
	var result: Array[LifeGame] = []
	result.assign(_games.values())
	return result


## Le joueur (null sans partie).
func player_node() -> Node3D:
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D


## Tenue d'un PNJ (NpcData.load_outfit : à la demande).
func outfit_skin(data: NpcData, outfit: StringName) -> SkinData:
	return data.load_outfit(outfit) if data != null else null


## Retire un PNJ parti (arrivé à sa sortie).
func despawn(who: LifeActor) -> void:
	_drop(who)


## (Joueur) Tenue de la maison de la protagoniste dans un intérieur de l'entrepôt : la tenue
## `<skin>_home` (data/npcs/outfits) si elle existe et a les animations de combat (attaque,
## charge, degats, mort) ; null sinon (le joueur garde sa planche ; aujourd'hui chtholly_home n'a
## pas le combat : docs/CONTRACT_REQUESTS.md). Le skin choisi par la communauté prime : seul le
## skin par défaut (Chtholly) en change.
static func player_home_outfit(map: Map, skin: SkinData) -> SkinData:
	if map == null or not map.interior or map.region != &"entrepot" or skin == null:
		return null
	if skin.id != SkinRegistry.default_skin().id:
		return null
	var path := "res://data/npcs/outfits/%s_home.tres" % skin.id
	if not ResourceLoader.exists(path):
		return null
	var home := load(path) as SkinData
	var anims := SheetLoader.animations(SheetLoader.read_sheet(home))
	for anim: String in ["attaque", "charge", "degats", "mort"]:
		if not anims.has(anim):
			return null
	return home


## Habille le joueur pour la carte : la tenue de la maison (player_home_outfit) dans un intérieur
## de l'entrepôt, sa planche ailleurs.
func _dress_player(map: Map) -> void:
	var player := player_node()
	var visual := player.get_node_or_null(^"Visual") as CharacterVisual if player != null else null
	if visual == null:
		return
	var home := player_home_outfit(map, DialogueRunner.player_skin())
	if home != null:
		visual.set_skin(home)
		_player_home = home
	elif _player_home != null:
		visual.set_skin(DialogueRunner.player_skin())
		_player_home = null


# --- Places, chemins, évitement (pour LifeActor) ----------------------------------------------


## Point libre d'une place pour un PNJ (le premier libre ; le moins occupé s'ils le sont tous).
func claim_point(who: LifeActor, place: StringName) -> int:
	if _places == null or not _places.has(place):
		return 0
	var taken: Dictionary = _claims.get(place, {})
	var count := _places.size(place)
	var best := 0
	var best_load := 1 << 30
	for index: int in count:
		var load_count := (taken.get(index, []) as Array).size()
		if load_count < best_load:
			best = index
			best_load = load_count
		if load_count == 0:
			break
	var holders: Array = taken.get(best, [])
	holders.append(who.id)
	taken[best] = holders
	_claims[place] = taken
	return best


## Libère le point d'une place.
func release_point(who: LifeActor, place: StringName, index: int) -> void:
	var taken: Dictionary = _claims.get(place, {})
	if taken.has(index):
		(taken[index] as Array).erase(who.id)


## Met un PNJ dans la file des chemins.
func request_path(who: LifeActor) -> void:
	if not _path_queue.has(who):
		_path_queue.append(who)


## Écart et blocage d'un PNJ qui marche de pos vers forward : {steer: Vector3 (à ajouter à la
## direction), blocked: bool, cells: cases à éviter}. On garde sa droite face à un PNJ qui vient,
## on contourne un PNJ arrêté ou le joueur quand on peut, on s'arrête s'il est juste devant.
func avoidance(who: LifeActor, pos: Vector3, forward: Vector3) -> Dictionary:
	var steer := Vector3.ZERO
	var blocked := false
	var cells: Array[Vector2i] = []
	var right := Vector3(-forward.z, 0.0, forward.x)
	var others: Array = []
	for other: LifeActor in _actors.values():
		if other != who and other.state != LifeActor.State.GONE and is_instance_valid(other.npc):
			if other.npc.visible:
				others.append([other.position(), other.heading(), other])
	var player := player_node()
	if player != null:
		var player_velocity := Vector3.ZERO
		if player is CharacterBody3D:
			player_velocity = (player as CharacterBody3D).velocity
		player_velocity.y = 0.0
		var player_heading := player_velocity.normalized() if player_velocity.length() > 0.3 else Vector3.ZERO
		others.append([player.global_position, player_heading, null])
	for entry: Array in others:
		var at: Vector3 = entry[0]
		var rel := Vector3(at.x - pos.x, 0.0, at.z - pos.z)
		var distance := rel.length()
		if distance > AVOID_DISTANCE or distance < 0.001:
			continue
		var ahead := rel.dot(forward)
		if ahead <= 0.0:
			continue
		var lateral := rel.dot(right)
		if absf(lateral) > 0.8:
			continue
		var heading: Vector3 = entry[1]
		var weight := 1.0 - distance / AVOID_DISTANCE
		if heading != Vector3.ZERO and heading.dot(forward) < -0.3:
			# En face : chacun garde sa droite.
			steer += right * KEEP_RIGHT * weight
		elif heading != Vector3.ZERO and heading.dot(forward) > 0.5:
			continue
		else:
			if absf(lateral) < BLOCK_LATERAL and distance < BLOCK_DISTANCE:
				blocked = true
				if _nav != null:
					cells.append(_nav.cell_of(at))
			steer -= right * signf(lateral if absf(lateral) > 0.01 else -0.1) * weight
	return {"steer": steer, "blocked": blocked, "cells": cells}


## Rang d'un PNJ parmi ceux qui font la même activité à deux, à la même place (0, 1…).
func pair_rank(who: LifeActor) -> int:
	var rank := 0
	for other: LifeActor in _actors.values():
		if other == who:
			return rank
		if other.place == who.place and other.activity_id == who.activity_id:
			rank += 1
	return rank


## Le partenaire de conversation le plus proche (même place, même activité), null sinon.
func pair_partner(who: LifeActor) -> LifeActor:
	var best: LifeActor = null
	var best_distance := INF
	for other: LifeActor in _actors.values():
		if other == who or other.place != who.place or other.activity_id != who.activity_id:
			continue
		var distance := other.position().distance_squared_to(who.position())
		if distance < best_distance:
			best = other
			best_distance = distance
	return best


## Vrai si un PNJ peut saluer maintenant (une bulle à la fois).
func may_greet() -> bool:
	if _greet_left > 0.0:
		return false
	_greet_left = GREET_GAP
	return true


# --- Jeux ---------------------------------------------------------------------------------------


## Fait entrer un PNJ dans le jeu de son activité, à sa place (le jeu est créé au besoin).
func join_game(who: LifeActor) -> void:
	var game_id := StringName(str(who.activity.get("game", "")))
	if game_id.is_empty():
		return
	var key := "%s|%s" % [game_id, who.place]
	var game: LifeGame = _games.get(key)
	if game == null:
		var script := load(LifeData.GAMES_DIR.path_join(String(game_id) + ".gd")) as GDScript
		if script == null:
			return
		game = script.new() as LifeGame
		game.setup(game_id, _map.map_id(), who.place, who.activity.get("params", {}))
		_games[key] = game
	game.add_member(who)


## Fait sortir un PNJ de son jeu (le jeu disparaît quand il n'a plus de membre).
func leave_game(who: LifeActor) -> void:
	for key: String in _games.keys():
		var game: LifeGame = _games[key]
		if game.members.has(who):
			game.remove_member(who)
			if game.members.is_empty():
				game.finish()
				_games.erase(key)


## Le jeu d'un PNJ (null s'il ne joue pas).
func game_of(who: LifeActor) -> LifeGame:
	return who.game


## Le jeu game_id à une place (null s'il n'y en a pas).
func game_at(game_id: StringName, place: StringName) -> LifeGame:
	return _games.get("%s|%s" % [game_id, place])


# --- Mesures ------------------------------------------------------------------------------------


## Mesures depuis la dernière remise à zéro : images, coût du directeur (moyen et maximal, µs),
## navigation, chemins, PNJ.
func stats() -> Dictionary:
	var result := _stats.duplicate()
	result["actors"] = _actors.size()
	result["nav_ready"] = _nav != null and _nav.ready
	result["nav_build_usec"] = _nav.build_usec if _nav != null else 0
	result["nav_frames"] = _nav.build_frames if _nav != null else 0
	return result


## Mesures en une ligne (journal ?vie=trace).
func stats_text() -> String:
	var data := stats()
	var frames := maxi(int(data["frames"]), 1)
	return (
		"créneau %s, %d PNJ ; directeur %.3f ms/image (max %.3f), navigation %.3f ms (max %.3f), "
		+ "chemins %.3f ms (max %.3f, %d) ; grille %s (%.1f ms en %d images)"
	) % [
		slot(),
		int(data["actors"]),
		float(data["usec"]) / frames / 1000.0,
		float(data["max_usec"]) / 1000.0,
		float(data["nav_usec"]) / frames / 1000.0,
		float(data["nav_max_usec"]) / 1000.0,
		float(data["path_usec"]) / frames / 1000.0,
		float(data["path_max_usec"]) / 1000.0,
		int(data["paths"]),
		"prête" if data["nav_ready"] else "en cours",
		float(data["nav_build_usec"]) / 1000.0,
		int(data["nav_frames"]),
	]


## Remet les mesures à zéro.
func reset_stats() -> void:
	_reset_stats()


# --- Paramètres de développement --------------------------------------------------------------


## Paramètres (creneau, vie) de l'adresse de la page (Web) ou des arguments utilisateur.
func read_parameters() -> Dictionary:
	var pairs: PackedStringArray = []
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		pairs = str(search if search != null else "").trim_prefix("?").split("&", false)
	else:
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--"):
				pairs.append(argument.trim_prefix("--"))
	return parse_pairs(pairs)


## Garde creneau=<créneau> et vie=trace|off|cycle parmi des « clé=valeur ».
func parse_pairs(pairs: PackedStringArray) -> Dictionary:
	var result := {}
	for pair: String in pairs:
		var key := pair.get_slice("=", 0).strip_edges()
		var value := pair.get_slice("=", 1).uri_decode().strip_edges()
		if key == SLOT_KEY and LifeSlots.is_slot(StringName(value)):
			result[SLOT_KEY] = StringName(value)
		elif key == LIFE_KEY and value in ["trace", "off", "cycle"]:
			result[LIFE_KEY] = value
	return result


# --- Interne ------------------------------------------------------------------------------------


func _apply_slot(walk: bool) -> void:
	var previous_slot := _slot
	var previous_day := _day
	_slot = LifeSlots.current()
	_day = GameState.day
	if _map == null:
		return
	var map_id := _map.map_id()
	for npc_id: StringName in LifeData.cast():
		var line := LifeData.line_for(npc_id, _slot, _day)
		var here: bool = line.get("map", &"") == map_id
		var current: LifeActor = _actors.get(npc_id)
		if current != null:
			if _same_line(current.line, line):
				continue
			if here:
				if walk:
					current.walk_to_line(line, _rng.randf_range(DEPART_SPREAD.x, DEPART_SPREAD.y))
				else:
					current.place_now(line)
			elif walk:
				current.leave_by(_exit_toward(_target_of(line)), _rng.randf_range(DEPART_SPREAD.x, DEPART_SPREAD.y))
			else:
				_drop(current)
		elif here:
			var arriving := _spawn(npc_id)
			if arriving == null:
				continue
			if walk:
				var before := LifeData.line_for(npc_id, previous_slot, previous_day)
				var entry := _exit_toward(_target_of(before))
				arriving.arrive_from(entry, line, _rng.randf_range(DEPART_SPREAD.x + 1.0, DEPART_SPREAD.y + 2.0))
			else:
				arriving.place_now(line)
	slot_changed.emit(_slot)


func _same_line(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return a.is_empty() and b.is_empty()
	return a.get("index", -1) == b.get("index", -2) and a.get("map") == b.get("map")


## Carte visée par une ligne (sa carte, ou la carte à venir d'away ; &"" : nulle part).
func _target_of(line: Dictionary) -> StringName:
	var map_id: StringName = line.get("map", &"")
	return map_id if not map_id.is_empty() else line.get("away", &"")


## Point par où l'on quitte la carte vers target (ou par où l'on arrive de target) : la place
## vers_<target>, sinon la sortie (MapExit) vers target, sinon la première place vers_…, sinon la
## première sortie, sinon le Spawn.
func _exit_toward(target: StringName) -> Transform3D:
	if _places != null and not target.is_empty():
		var departure := _places.departure(target)
		if not departure.is_empty():
			return _places.point(departure, 0)
	var exits := _map.exits()
	for exit: MapExit in exits:
		if exit.target_map == target and not target.is_empty():
			return _exit_transform(exit)
	if _places != null:
		for place: StringName in _places.names():
			if String(place).begins_with(LifePlaces.DEPARTURE_PREFIX):
				return _places.point(place, 0)
	if not exits.is_empty():
		return _exit_transform(exits[0])
	var spawn := _map.spawn()
	return spawn.global_transform if spawn != null else Transform3D.IDENTITY


func _exit_transform(exit: MapExit) -> Transform3D:
	var at := exit.global_position
	if _nav != null:
		at.y = _nav.height_at(at.x, at.z)
	return Transform3D(exit.global_basis, at)


func _spawn(npc_id: StringName) -> LifeActor:
	var data := LifeData.find_npc(npc_id)
	if data == null or _map == null:
		return null
	var root := _map.get_node_or_null(^"Life")
	if root == null:
		return null
	var node := NPC_SCENE.instantiate() as Npc
	node.name = String(npc_id)
	node.data = data
	if data.display_name.is_empty():
		var named := data.duplicate() as NpcData
		named.display_name = LifeTexts.fairy_name(npc_id)
		node.data = named
	var new_actor := LifeActor.new(npc_id, node.data, node)
	node.enter_life(new_actor)
	var line := LifeData.line_for(npc_id, LifeSlots.current(), GameState.day)
	node.outfit_skin = outfit_skin(node.data, line.get("outfit", &""))
	new_actor.outfit = line.get("outfit", &"")
	root.add_child(node)
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	_actors[npc_id] = new_actor
	return new_actor


func _drop(who: LifeActor) -> void:
	leave_game(who)
	if who.point_index >= 0:
		release_point(who, who.place, who.point_index)
	who.state = LifeActor.State.GONE
	_path_queue.erase(who)
	_actors.erase(who.id)
	if is_instance_valid(who.npc):
		who.npc.queue_free()


func _clear() -> void:
	for game: LifeGame in _games.values():
		game.finish()
	_games.clear()
	for who: LifeActor in _actors.values():
		who.state = LifeActor.State.GONE
		if is_instance_valid(who.npc) and is_instance_valid(_map) and who.npc.is_inside_tree():
			who.npc.queue_free()
	_actors.clear()
	_claims.clear()
	_path_queue.clear()
	_map = null
	_nav = null
	_places = null


func _serve_paths() -> void:
	if _nav == null or not _nav.ready:
		return
	var served := 0
	while served < paths_per_frame and not _path_queue.is_empty():
		var who: LifeActor = _path_queue.pop_front()
		if who.state == LifeActor.State.GONE or not who.is_moving():
			continue
		who.set_path(_nav.find_path(who.position(), who.goal(), who.avoid_cells()))
		served += 1
		_stats["paths"] = int(_stats.get("paths", 0)) + 1


func _record(usec: int, nav_usec: int, path_usec: int) -> void:
	_stats["frames"] = int(_stats["frames"]) + 1
	_stats["usec"] = int(_stats["usec"]) + usec
	_stats["max_usec"] = maxi(int(_stats["max_usec"]), usec)
	_stats["nav_usec"] = int(_stats["nav_usec"]) + nav_usec
	_stats["nav_max_usec"] = maxi(int(_stats["nav_max_usec"]), nav_usec)
	_stats["path_usec"] = int(_stats["path_usec"]) + path_usec
	_stats["path_max_usec"] = maxi(int(_stats["path_max_usec"]), path_usec)


func _reset_stats() -> void:
	_stats = {
		"frames": 0,
		"usec": 0,
		"max_usec": 0,
		"nav_usec": 0,
		"nav_max_usec": 0,
		"path_usec": 0,
		"path_max_usec": 0,
		"paths": 0,
	}


func _on_map_entered(_map_id: StringName) -> void:
	attach(WorldManager.current_map_node())


func _on_atmosphere_changed(moment: StringName, _weather: StringName) -> void:
	# Un moment posé ailleurs (F7, le récit) emporte le créneau s'il ne lui va plus.
	if not GameState.slot.is_empty() and LifeSlots.moment_of(GameState.slot) != moment:
		GameState.slot = &""


func _on_game_loaded() -> void:
	var wanted: StringName = dev_parameters.get(SLOT_KEY, &"")
	if not wanted.is_empty():
		set_slot(wanted, 0.0)


func _on_dialogue(npc_id: StringName, started: bool) -> void:
	var who: LifeActor = _actors.get(npc_id)
	if who != null:
		who.set_talking(started)
