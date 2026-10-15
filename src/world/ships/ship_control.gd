class_name ShipControl
extends RefCounted
## (E7) Les navires pour le récit (PLAN.md, « (E7) Les navires ») : une API statique, sans
## autoload, qui pilote le poste d'amarrage (ShipBerth) du navire dans la carte chargée et garde son
## état dans les drapeaux de GameState (sauvegardés) ; sans poste dans la carte, seul l'état change
## (le navire sera à quai, ou parti, quand on viendra au port). Propriétaire : E7.
##
##     await ShipControl.descend(&"transport_garde")         # descente, amarrage, rotors arrêtés
##     await ShipControl.open_hatch(&"transport_garde")      # la trappe s'ouvre sous la pression
##     await ShipControl.deploy_gangway(&"transport_garde")  # la passerelle se pose sur le quai
##     await ShipControl.depart(&"transport_garde")          # rentre tout, se détache, remonte
##     await ShipControl.pass_shadow(&"barocupot")           # une ombre passe dans les nuages
##
## Toutes ces actions sont aussi l'étape « ship » des scènes (data/scenes/ : {"do": "ship",
## "ship": "transport_garde", "action": "descend"}) ; play(id, action, false) n'attend pas la fin,
## finish(id, action) pose l'état final d'un coup (séquence passée). Données (durées, vitesses,
## hauteurs) : data/ships/<id>.json.

## Actions (étape « ship » des scènes).
const ACTIONS: Array[StringName] = [
	&"descend",
	&"dock",
	&"open_hatch",
	&"close_hatch",
	&"deploy_gangway",
	&"stow_gangway",
	&"depart",
	&"clear",
	&"allow_boarding",
	&"forbid_boarding",
	&"shadow",
]
## Ce que retiennent les drapeaux d'un navire (ship_<id>_<partie>).
const PARTS: Array[StringName] = [&"docked", &"hatch", &"gangway", &"boarding"]
const DATA_DIR := "res://data/ships"

static var _data: Dictionary = {}


## Données d'un navire (data/ships/<id>.json) ; vide s'il n'existe pas.
static func data(ship_id: StringName) -> Dictionary:
	if not _data.has(ship_id):
		var path := "%s/%s.json" % [DATA_DIR, ship_id]
		var parsed: Variant = (
			JSON.parse_string(FileAccess.get_file_as_string(path))
			if FileAccess.file_exists(path)
			else null
		)
		_data[ship_id] = parsed if parsed is Dictionary else {}
	return _data[ship_id]


## Le navire existe-t-il (ses données) ?
static func has_ship(ship_id: StringName) -> bool:
	return FileAccess.file_exists("%s/%s.json" % [DATA_DIR, ship_id])


## Nom du drapeau d'une partie de l'état (PARTS) : ship_transport_garde_docked…
static func flag(ship_id: StringName, part: StringName) -> StringName:
	return StringName("ship_%s_%s" % [ship_id, part])


static func has_flag(ship_id: StringName, part: StringName) -> bool:
	return GameState.has_flag(flag(ship_id, part))


static func set_flag(ship_id: StringName, part: StringName, on: bool) -> void:
	if has_flag(ship_id, part) != on:
		GameState.set_flag(flag(ship_id, part), on)


## Le navire est-il à quai ?
static func is_docked(ship_id: StringName) -> bool:
	return has_flag(ship_id, &"docked")


## Le navire est parti : ni à quai, ni trappe ni passerelle (l'embarquement permis reste).
static func clear(ship_id: StringName) -> void:
	for part: StringName in [&"docked", &"hatch", &"gangway"]:
		set_flag(ship_id, part, false)


## Poste d'amarrage du navire dans l'arbre (la carte chargée), ou null.
static func berth(ship_id: StringName) -> ShipBerth:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node: Node in tree.get_nodes_in_group(ShipBerth.GROUP):
		var found := node as ShipBerth
		if found != null and found.ship_id == ship_id and found.is_inside_tree():
			return found
	return null


## Le navire posé dans la carte chargée (nœud Ship de son poste), ou null.
static func ship(ship_id: StringName) -> Ship:
	var place := berth(ship_id)
	return place.ship() if place != null else null


## Joue une action (ACTIONS) ; wait : attend sa fin (coroutine). Sans poste dans la carte, l'état
## final est posé tout de suite.
static func play(ship_id: StringName, action: StringName, wait: bool = true) -> void:
	if not ACTIONS.has(action):
		push_warning("ShipControl : action inconnue %s" % action)
		return
	var place := berth(ship_id)
	match action:
		&"shadow":
			await pass_shadow(ship_id, wait)
			return
		&"dock", &"clear", &"allow_boarding", &"forbid_boarding":
			finish(ship_id, action)
			return
	if place == null:
		settle(ship_id, action)
		return
	place.start(action)
	if not wait:
		return
	var tree := place.get_tree()
	while is_instance_valid(place) and place.is_inside_tree() and place.current_action() == action:
		await tree.physics_frame
	if not is_instance_valid(place) or not place.is_inside_tree():
		settle(ship_id, action)


## L'action est-elle en cours (le poste l'anime, ou l'ombre passe encore) ?
static func is_playing(ship_id: StringName, action: StringName) -> bool:
	if action == &"shadow":
		return not shadows(ship_id).is_empty()
	var place := berth(ship_id)
	return place != null and place.current_action() == action


## Ombres du navire qui passent encore.
static func shadows(ship_id: StringName) -> Array[ShipShadow]:
	var found: Array[ShipShadow] = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return found
	for node: Node in tree.get_nodes_in_group(ShipShadow.GROUP):
		var shadow := node as ShipShadow
		if shadow != null and shadow.ship_id == ship_id and not shadow.is_done():
			found.append(shadow)
	return found


## Pose d'un coup l'état final d'une action (séquence passée).
static func finish(ship_id: StringName, action: StringName) -> void:
	var place := berth(ship_id)
	match action:
		&"shadow":
			for shadow in shadows(ship_id):
				shadow.advance(INF)
			return
		&"dock", &"clear", &"allow_boarding", &"forbid_boarding":
			settle(ship_id, action)
			if place != null:
				place.apply_state()
			return
	if place == null:
		settle(ship_id, action)
		return
	place.start(action)
	place.finish_now()


static func descend(ship_id: StringName) -> void:
	await play(ship_id, &"descend")


static func dock(ship_id: StringName) -> void:
	finish(ship_id, &"dock")


static func open_hatch(ship_id: StringName) -> void:
	await play(ship_id, &"open_hatch")


static func close_hatch(ship_id: StringName) -> void:
	await play(ship_id, &"close_hatch")


static func deploy_gangway(ship_id: StringName) -> void:
	await play(ship_id, &"deploy_gangway")


static func stow_gangway(ship_id: StringName) -> void:
	await play(ship_id, &"stow_gangway")


static func depart(ship_id: StringName) -> void:
	await play(ship_id, &"depart")


## Permet (ou retire) l'embarquement : la sortie « Monter à bord » s'ouvre navire à quai,
## passerelle posée. Jamais à l'acte 1 (CARTE.md 6.2).
static func allow_boarding(ship_id: StringName, allowed: bool = true) -> void:
	finish(ship_id, &"allow_boarding" if allowed else &"forbid_boarding")


## Une ombre de navire passe dans le ciel, devant la caméra (scène 8.6 : le Barocupot dans les
## nuages) ; wait : attend qu'elle soit passée. Rend l'ombre (ShipShadow, déjà partie si wait).
static func pass_shadow(ship_id: StringName = &"barocupot", wait: bool = true) -> ShipShadow:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var host: Node = WorldManager.current_map_node()
	if host == null:
		host = tree.current_scene if tree.current_scene != null else tree.root
	var shadow := ShipShadow.new()
	shadow.name = "ShipShadow_%s" % ship_id
	shadow.ship_id = ship_id
	shadow.setup(data(ship_id).get("shadow", {}))
	host.add_child(shadow)
	if wait:
		while is_instance_valid(shadow) and shadow.is_inside_tree() and not shadow.is_done():
			await tree.physics_frame
	return shadow


## Pose un état d'un coup, sans animer (captures, démonstrations, reprise) : absent (parti),
## docked (à quai, trappe fermée), open_hatch (trappe ouverte) ou deploy_gangway (passerelle
## posée) ; l'embarquement permis ne change pas.
static func pose(ship_id: StringName, state: StringName) -> void:
	clear(ship_id)
	match state:
		&"docked", &"dock":
			set_flag(ship_id, &"docked", true)
		&"open_hatch":
			set_flag(ship_id, &"docked", true)
			set_flag(ship_id, &"hatch", true)
		&"deploy_gangway":
			set_flag(ship_id, &"docked", true)
			set_flag(ship_id, &"hatch", true)
			set_flag(ship_id, &"gangway", true)
	var place := berth(ship_id)
	if place != null:
		if place.is_busy():
			place.finish_now()
			clear(ship_id)
			pose(ship_id, state)
			return
		place.apply_state()


## L'état qu'une action laisse, sans poste à animer (ou quand le poste quitte l'arbre en route).
static func settle(ship_id: StringName, action: StringName) -> void:
	match action:
		&"descend", &"dock":
			set_flag(ship_id, &"docked", true)
		&"open_hatch":
			set_flag(ship_id, &"hatch", true)
		&"close_hatch":
			set_flag(ship_id, &"hatch", false)
		&"deploy_gangway":
			set_flag(ship_id, &"hatch", true)
			set_flag(ship_id, &"gangway", true)
		&"stow_gangway":
			set_flag(ship_id, &"gangway", false)
		&"depart", &"clear":
			clear(ship_id)
		&"allow_boarding":
			set_flag(ship_id, &"boarding", true)
		&"forbid_boarding":
			set_flag(ship_id, &"boarding", false)
	var place := berth(ship_id)
	if place != null and not place.is_busy():
		place.refresh_access()
