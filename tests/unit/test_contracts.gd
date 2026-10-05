extends GutTest
## Contrats figés au Lot 0 (PLAN.md section 3 et « Structure figée au Lot 0 ») : signaux,
## signatures, champs des ressources, nœuds nommés, groupes, couches et actions.
## Un lot qui fait échouer ce test a cassé un contrat : il ouvre une PR « contrats ».

const OBJ := TYPE_OBJECT
const SN := TYPE_STRING_NAME
const STR := TYPE_STRING
const INT := TYPE_INT
const FLT := TYPE_FLOAT
const BOOL := TYPE_BOOL
const ARR := TYPE_ARRAY
const DICT := TYPE_DICTIONARY
const V3 := TYPE_VECTOR3
const VOID := TYPE_NIL

## Signaux d'EventBus : nom → types des arguments.
const EVENT_BUS_SIGNALS := {
	"player_health_changed": [INT, INT],
	"player_damaged": [INT, OBJ],
	"player_died": [],
	"player_respawned": [],
	"player_heal_requested": [INT],
	"enemy_spawned": [OBJ, SN],
	"enemy_damaged": [OBJ, INT],
	"enemy_killed": [SN, INT],
	"wave_started": [SN, INT, INT],
	"wave_cleared": [SN, INT, INT],
	"arena_score_changed": [SN, INT],
	"arena_finished": [SN, INT, BOOL],
	"charge_progress": [FLT],
	"item_collected": [SN, INT],
	"inventory_changed": [],
	"interaction_available": [STR],
	"dialogue_started": [SN],
	"dialogue_line": [STR, STR, ARR],
	"dialogue_choice_made": [INT],
	"dialogue_ended": [SN],
	"quest_updated": [SN, SN],
	"zone_entered": [SN],
	"day_phase_changed": [SN],
	"skin_changed": [SN],
	"max_hp_changed": [INT],
	"save_requested": [],
	"game_loaded": [],
}

## Méthodes des autoloads : nom → [types des arguments, type de retour].
const GAME_STATE_METHODS := {
	"add_item": [[SN, INT], VOID],
	"remove_item": [[SN, INT], BOOL],
	"count": [[SN], INT],
	"items": [[], DICT],
	"set_flag": [[SN, BOOL], VOID],
	"has_flag": [[SN], BOOL],
	"quest_state": [[SN], SN],
	"set_quest_state": [[SN, SN], VOID],
	"mark_pickup_collected": [[SN], VOID],
	"is_pickup_collected": [[SN], BOOL],
	"record_score": [[SN, INT, INT], BOOL],
	"best_score": [[SN], INT],
	"to_dict": [[], DICT],
	"from_dict": [[DICT], VOID],
	"reset": [[], VOID],
}
const SAVE_MANAGER_METHODS := {
	"has_save": [[], BOOL],
	"save": [[], INT],
	"load_game": [[], INT],
	"new_game": [[SN], VOID],
	"export_json": [[], STR],
	"import_json": [[STR], INT],
}
const SKIN_REGISTRY_METHODS := {
	"all": [[], ARR],
	"get_skin": [[SN], OBJ],
	"default_skin": [[], OBJ],
}
const WORLD_MANAGER_METHODS := {
	"load_zone": [[SN], VOID],
	"teleport": [[SN, SN], VOID],
	"respawn": [[], VOID],
	"current_zone": [[], SN],
	"zone_display_name": [[SN], STR],
}

## Champs des ressources : classe → {propriété: type}.
const RESOURCE_FIELDS := {
	"AttackData":
	{
		"id": SN,
		"animation": SN,
		"damage": INT,
		"knockback": FLT,
		"pierces": BOOL,
		"range_m": FLT,
		"cooldown": FLT,
		"arc_deg": FLT,
		"width_m": FLT,
		"charge_time": FLT,
		"duration": FLT,
		"speed": FLT,
	},
	"SkinData":
	{
		"id": SN,
		"display_name": STR,
		"sprite_sheet": OBJ,
		"frames_json": OBJ,
		"mesh_scene": OBJ,
		"portrait": OBJ,
		"height_m": FLT,
	},
	"EnemyData":
	{
		"id": SN,
		"display_name": STR,
		"visual": OBJ,
		"scale": FLT,
		"max_hp": INT,
		"speed": FLT,
		"points": INT,
		"attacks": ARR,
		"rush": BOOL,
		"stoic": BOOL,
		"aggro_range_m": FLT,
		"drops": DICT,
	},
	"ItemData":
	{
		"id": SN,
		"display_name": STR,
		"icon": OBJ,
		"stackable": BOOL,
		"max_stack": INT,
		"description": STR,
	},
	"NpcData":
	{
		"id": SN,
		"display_name": STR,
		"skin": OBJ,
		"dialogue_path": STR,
		"quest_id": SN,
		"home_zone": SN,
	},
	"QuestData":
	{
		"id": SN,
		"title": STR,
		"giver_npc": SN,
		"required_items": DICT,
		"required_flags": ARR,
		"reward_items": DICT,
	},
}

const ZONES: Array[String] = ["village", "dunes", "forest", "beach", "hill"]

# --- Outils -----------------------------------------------------------------------------------


func _method_info(obj: Object, method_name: String) -> Dictionary:
	var script := obj.get_script() as Script
	while script != null:
		for info: Dictionary in script.get_script_method_list():
			if info["name"] == method_name:
				return info
		script = script.get_base_script()
	return {}


func _assert_methods(obj: Object, label: String, methods: Dictionary) -> void:
	for method_name: String in methods:
		var expected: Array = methods[method_name]
		var info := _method_info(obj, method_name)
		assert_false(info.is_empty(), "%s.%s() existe" % [label, method_name])
		if info.is_empty():
			continue
		var args: Array = info["args"]
		var arg_types: Array = expected[0]
		assert_eq(
			args.size(), arg_types.size(), "%s.%s : nombre d'arguments" % [label, method_name]
		)
		for i in mini(args.size(), arg_types.size()):
			assert_eq(
				args[i]["type"],
				arg_types[i],
				"%s.%s : type de l'argument %d" % [label, method_name, i]
			)
		assert_eq(
			info["return"]["type"], expected[1], "%s.%s : type de retour" % [label, method_name]
		)


func _assert_signal(obj: Object, label: String, signal_name: String, arg_types: Array) -> void:
	assert_true(obj.has_signal(signal_name), "%s.%s existe" % [label, signal_name])
	for info: Dictionary in obj.get_signal_list():
		if info["name"] != signal_name:
			continue
		var args: Array = info["args"]
		assert_eq(
			args.size(), arg_types.size(), "%s.%s : nombre d'arguments" % [label, signal_name]
		)
		for i in mini(args.size(), arg_types.size()):
			assert_eq(
				args[i]["type"],
				arg_types[i],
				"%s.%s : type de l'argument %d" % [label, signal_name, i]
			)


func _property_type(obj: Object, property: String) -> int:
	for info: Dictionary in obj.get_property_list():
		if info["name"] == property:
			return info["type"]
	return -1


func _global_class(cls_name: String) -> Script:
	for info: Dictionary in ProjectSettings.get_global_class_list():
		if info["class"] == cls_name:
			return load(info["path"]) as Script
	return null


func _instance(path: String) -> Node:
	var packed := load(path) as PackedScene
	assert_not_null(packed, "scène %s" % path)
	if packed == null:
		return null
	return autofree(packed.instantiate())


func _assert_nodes(root: Node, path: String, nodes: Dictionary) -> void:
	for node_path: String in nodes:
		var node := root.get_node_or_null(NodePath(node_path))
		assert_not_null(node, "%s : nœud %s" % [path, node_path])
		if node != null and not String(nodes[node_path]).is_empty():
			assert_true(
				node.is_class(nodes[node_path]) or _is_script_class(node, nodes[node_path]),
				"%s : %s est un %s" % [path, node_path, nodes[node_path]]
			)


func _is_script_class(node: Node, cls_name: String) -> bool:
	var script := node.get_script() as Script
	while script != null:
		if script.get_global_name() == cls_name:
			return true
		script = script.get_base_script()
	return false


# --- Autoloads --------------------------------------------------------------------------------


func test_autoloads_are_registered_without_class_name() -> void:
	for autoload: String in [
		"EventBus", "GameState", "SaveManager", "SkinRegistry", "WorldManager"
	]:
		assert_true(ProjectSettings.has_setting("autoload/" + autoload), "autoload %s" % autoload)
		assert_not_null(get_tree().root.get_node_or_null(autoload), "%s dans l'arbre" % autoload)
		assert_null(_global_class(autoload), "pas de class_name %s" % autoload)


func test_event_bus_signals() -> void:
	for signal_name: String in EVENT_BUS_SIGNALS:
		_assert_signal(EventBus, "EventBus", signal_name, EVENT_BUS_SIGNALS[signal_name])


func test_game_state_api() -> void:
	_assert_methods(GameState, "GameState", GAME_STATE_METHODS)
	assert_eq(_property_type(GameState, "skin_id"), SN, "GameState.skin_id")
	assert_eq(_property_type(GameState, "max_hp"), INT, "GameState.max_hp")
	assert_eq(_property_type(GameState, "zone"), SN, "GameState.zone")
	assert_eq(_property_type(GameState, "position"), V3, "GameState.position")


func test_save_manager_api() -> void:
	_assert_methods(SaveManager, "SaveManager", SAVE_MANAGER_METHODS)
	assert_eq(_property_type(SaveManager, "save_path"), STR, "SaveManager.save_path")
	assert_eq(SaveManager.DEFAULT_SAVE_PATH, "user://save_v1.json")


func test_skin_registry_api() -> void:
	_assert_methods(SkinRegistry, "SkinRegistry", SKIN_REGISTRY_METHODS)
	var skin := SkinRegistry.default_skin()
	assert_not_null(skin, "skin par défaut")
	if skin != null:
		assert_eq(skin.id, &"chtholly")
	for skin_data: SkinData in SkinRegistry.all():
		assert_ne(skin_data.id, &"timere", "le visuel du Timere n'est pas un skin jouable")


func test_world_manager_api() -> void:
	_assert_methods(WorldManager, "WorldManager", WORLD_MANAGER_METHODS)
	assert_eq(WorldManager.VILLAGE, &"village")
	assert_eq(WorldManager.SPAWN_MARKER, &"Spawn")


# --- Classes partagées ------------------------------------------------------------------------


func test_resource_fields() -> void:
	for cls_name: String in RESOURCE_FIELDS:
		var script := _global_class(cls_name)
		assert_not_null(script, "class_name %s" % cls_name)
		if script == null:
			continue
		var resource: Resource = script.new()
		var fields: Dictionary = RESOURCE_FIELDS[cls_name]
		for field: String in fields:
			assert_eq(_property_type(resource, field), fields[field], "%s.%s" % [cls_name, field])


func test_health_contract() -> void:
	var health: Health = autofree(Health.new())
	_assert_signal(health, "Health", "changed", [INT, INT])
	_assert_signal(health, "Health", "damaged", [INT, OBJ])
	_assert_signal(health, "Health", "died", [])
	_assert_methods(health, "Health", {"take_damage": [[INT, OBJ], BOOL], "heal": [[INT], VOID]})
	assert_eq(_property_type(health, "max_hp"), INT)
	assert_eq(_property_type(health, "invincibility_time"), FLT)


func test_combat_classes() -> void:
	var combat: PlayerCombat = autofree(PlayerCombat.new())
	_assert_methods(
		combat,
		"PlayerCombat",
		{
			"attack": [[], VOID],
			"charge_begin": [[], VOID],
			"charge_release": [[], VOID],
			"is_busy": [[], BOOL],
		}
	)
	var hitbox: Hitbox = autofree(Hitbox.new())
	_assert_signal(hitbox, "Hitbox", "hit_landed", [OBJ])
	_assert_methods(
		hitbox,
		"Hitbox",
		{"activate": [[], VOID], "deactivate": [[], VOID], "is_active": [[], BOOL]}
	)
	assert_eq(_property_type(hitbox, "attack"), OBJ)
	assert_eq(_property_type(hitbox, "team"), SN)
	var hurtbox: Hurtbox = autofree(Hurtbox.new())
	_assert_signal(hurtbox, "Hurtbox", "hit_taken", [OBJ, OBJ])
	_assert_methods(hurtbox, "Hurtbox", {"receive_hit": [[OBJ, OBJ], BOOL]})
	assert_eq(_property_type(hurtbox, "health"), OBJ)
	assert_eq(_property_type(hurtbox, "team"), SN)


func test_character_visual_contract() -> void:
	var visual := _instance("res://src/visuals/character_visual.tscn")
	_assert_signal(visual, "CharacterVisual", "frame_changed", [SN, INT])
	_assert_signal(visual, "CharacterVisual", "animation_finished", [SN])
	_assert_methods(
		visual,
		"CharacterVisual",
		{
			"set_skin": [[OBJ], VOID],
			"play": [[SN, BOOL], VOID],
			"set_facing": [[V3], VOID],
			"hit_frames": [[SN], ARR],
			"wave_frame": [[SN], INT],
			"show_frame": [[SN, INT], VOID],
		}
	)


func test_wave_director_contract() -> void:
	var director: WaveDirector = autofree(WaveDirector.new())
	_assert_methods(
		director,
		"WaveDirector",
		{
			"start": [[], VOID],
			"stop": [[], VOID],
			"current_wave": [[], INT],
			"compose": [[INT], ARR]
		}
	)
	assert_eq(director.load_config("res://data/waves/dunes.json"), OK)
	assert_eq(director.compose(1).size(), 5, "vague 1 de dunes.json : 3 petits + 2 normaux")


func test_interactables_implement_contract() -> void:
	for path: String in ["res://src/npc/npc.tscn", "res://src/items/pickup.tscn"]:
		var node := _instance(path)
		assert_true(node.is_in_group(&"interactable"), "%s dans le groupe interactable" % path)
		_assert_methods(node, path, {"get_prompt": [[], STR], "interact": [[OBJ], VOID]})


# --- Structure figée des scènes ---------------------------------------------------------------


func test_player_structure() -> void:
	var path := "res://src/player/player.tscn"
	var player := _instance(path)
	assert_true(player is CharacterBody3D and player.is_in_group(&"player"))
	assert_true(_is_script_class(player, "Player"))
	_assert_nodes(
		player,
		path,
		{
			"CollisionShape3D": "CollisionShape3D",
			"Visual": "CharacterVisual",
			"Combat": "PlayerCombat",
			"Combat/SwordHitbox": "Hitbox",
			"Health": "Health",
			"Hurtbox": "Hurtbox",
			"CameraRig": "Node3D",
			"CameraRig/SpringArm3D": "SpringArm3D",
			"CameraRig/SpringArm3D/Camera3D": "Camera3D",
		}
	)
	assert_eq((player as CollisionObject3D).collision_layer, 2, "couche player")
	var health := player.get_node(^"Health") as Health
	assert_eq(health.max_hp, 5, "5 PV dans la scène")
	assert_almost_eq(health.invincibility_time, 1.2, 0.001, "1,2 s d'invincibilité dans la scène")
	var hurtbox := player.get_node(^"Hurtbox") as Hurtbox
	assert_eq(hurtbox.health, health, "Hurtbox.health = ../Health")
	assert_eq(hurtbox.team, &"player")
	assert_eq((player.get_node(^"Combat/SwordHitbox") as Hitbox).team, &"player")


func test_enemy_structure() -> void:
	var path := "res://src/enemies/enemy.tscn"
	var enemy := _instance(path)
	assert_true(enemy is Enemy and enemy.is_in_group(&"enemies"))
	_assert_nodes(
		enemy,
		path,
		{
			"CollisionShape3D": "CollisionShape3D",
			"Visual": "CharacterVisual",
			"Health": "Health",
			"Hurtbox": "Hurtbox",
			"Hitbox": "Hitbox",
		}
	)
	assert_eq((enemy as CollisionObject3D).collision_layer, 4, "couche enemy")
	assert_true(
		(enemy as CollisionObject3D).get_collision_mask_value(8), "bloqué par enemy_barrier"
	)
	assert_eq((enemy.get_node(^"Hurtbox") as Hurtbox).health, enemy.get_node(^"Health"))
	assert_eq((enemy.get_node(^"Hurtbox") as Hurtbox).team, &"enemy")
	assert_eq((enemy.get_node(^"Hitbox") as Hitbox).team, &"enemy")


func test_hitbox_hurtbox_layers() -> void:
	var hitbox := _instance("res://src/combat/hitbox.tscn") as Area3D
	assert_eq(hitbox.collision_layer, 8, "Hitbox : couche 4 hitbox")
	assert_eq(hitbox.collision_mask, 16, "Hitbox : masque 5 hurtbox")
	var hurtbox := _instance("res://src/combat/hurtbox.tscn") as Area3D
	assert_eq(hurtbox.collision_layer, 16, "Hurtbox : couche 5 hurtbox")
	var wave := _instance("res://src/combat/charge_wave.tscn")
	var wave_hitbox := wave.get_node(^"Hitbox") as Hitbox
	assert_not_null(wave_hitbox, "charge_wave : Hitbox")
	assert_true(wave_hitbox.attack != null and wave_hitbox.attack.pierces, "l'onde traverse")


func test_npc_pickup_arena_structure() -> void:
	var npc := _instance("res://src/npc/npc.tscn")
	assert_true(npc is Npc)
	_assert_nodes(
		npc,
		"npc.tscn",
		{
			"CollisionShape3D": "CollisionShape3D",
			"Visual": "CharacterVisual",
			"InteractArea": "Area3D",
			"DialogueRunner": "DialogueRunner",
		}
	)
	assert_eq((npc.get_node(^"InteractArea") as Area3D).collision_layer, 32, "couche interactable")
	var pickup := _instance("res://src/items/pickup.tscn")
	assert_true(pickup is Pickup)
	assert_eq((pickup as Area3D).collision_layer, 64, "couche pickup")
	var arena := _instance("res://src/enemies/arena.tscn")
	assert_true(arena is Arena)
	_assert_nodes(arena, "arena.tscn", {"WaveDirector": "WaveDirector"})


func test_zone_structure() -> void:
	for zone_id in ZONES:
		var path := "res://src/world/zones/%s/%s.tscn" % [zone_id, zone_id]
		var zone := _instance(path)
		assert_true(zone is Zone, "%s est une Zone" % path)
		assert_eq(String(zone.name), zone_id, "racine nommée comme la zone")
		assert_true(zone.is_in_group(&"zones"))
		_assert_nodes(
			zone,
			path,
			{
				"Spawn": "Marker3D",
				"Bounds": "Area3D",
				"NPCs": "Node3D",
				"Enemies": "Node3D",
				"Pickups": "Node3D",
			}
		)
		assert_eq(
			(zone.get_node(^"Bounds") as Area3D).collision_mask,
			2,
			"%s : Bounds détecte le joueur" % path
		)
		assert_eq((zone as Zone).safe, zone_id == "village", "%s : seul le village est sûr" % path)
	var dunes := _instance("res://src/world/zones/dunes/dunes.tscn")
	_assert_nodes(
		dunes,
		"dunes.tscn",
		{
			"SpawnN": "Marker3D",
			"SpawnS": "Marker3D",
			"SpawnE": "Marker3D",
			"SpawnW": "Marker3D",
			"Arena": "Arena",
			"Arena/WaveDirector": "WaveDirector",
		}
	)
	assert_eq((dunes.get_node(^"Arena") as Arena).arena_id, &"dunes")
	var village := _instance("res://src/world/zones/village/village.tscn")
	var barrier := village.get_node_or_null(^"EnemyBarrier") as CollisionObject3D
	assert_not_null(barrier, "village : EnemyBarrier")
	if barrier != null:
		assert_eq(barrier.collision_layer, 128, "barrière sur la couche 8 enemy_barrier")


func test_island_and_game_structure() -> void:
	var island := _instance("res://src/world/island.tscn")
	var island_nodes := {
		"WorldEnvironment": "WorldEnvironment",
		"Sun": "DirectionalLight3D",
		"OverviewCamera": "Camera3D",
		"Ground": "StaticBody3D",
		"Water": "MeshInstance3D",
		"Walls": "StaticBody3D",
		"KillZone": "Area3D",
		"Zones": "Node3D",
	}
	for zone_id in ZONES:
		island_nodes["Zones/" + zone_id] = "Zone"
	_assert_nodes(island, "island.tscn", island_nodes)
	var game := _instance("res://src/game.tscn")
	_assert_nodes(
		game,
		"game.tscn",
		{
			"Island": "Node3D",
			"Player": "Player",
			"QuestTracker": "QuestTracker",
			"UI": "CanvasLayer",
			"UI/HUD": "Control",
			"UI/DialogueBox": "Control",
			"UI/Inventory": "Control",
			"UI/ArenaEnd": "Control",
			"UI/TouchControls": "Control",
		}
	)
	for ui: String in ["main_menu", "credits", "loading"]:
		assert_true(_instance("res://src/ui/%s.tscn" % ui) is Control, "src/ui/%s.tscn" % ui)


# --- Projet -----------------------------------------------------------------------------------


func test_collision_layer_names() -> void:
	var names: Array[String] = [
		"world", "player", "enemy", "hitbox", "hurtbox", "interactable", "pickup", "enemy_barrier"
	]
	for i in names.size():
		var key := "layer_names/3d_physics/layer_%d" % (i + 1)
		assert_eq(ProjectSettings.get_setting(key, ""), names[i], key)


func test_input_actions() -> void:
	for action: String in [
		"move_left",
		"move_right",
		"move_forward",
		"move_back",
		"run",
		"jump",
		"attack",
		"charge",
		"interact",
		"lock_target",
		"inventory",
		"pause",
		"camera_left",
		"camera_right",
		"camera_up",
		"camera_down",
	]:
		assert_true(InputMap.has_action(action), "action %s" % action)


func test_data_files() -> void:
	var expected_attacks: Array[String] = [
		"sword_1", "sword_2", "sword_3", "charge_wave", "bite", "whip", "rush"
	]
	for attack_id in expected_attacks:
		var attack := load("res://data/attacks/%s.tres" % attack_id) as AttackData
		assert_not_null(attack, "data/attacks/%s.tres" % attack_id)
		if attack != null:
			assert_eq(attack.id, StringName(attack_id), "id = nom du fichier")
	for enemy_id: String in ["timere_small", "timere_normal", "timere_runner", "timere_big"]:
		var enemy := load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
		assert_not_null(enemy, "data/enemies/%s.tres" % enemy_id)
		if enemy != null:
			assert_eq(enemy.id, StringName(enemy_id))
			assert_not_null(enemy.visual, "%s : visuel" % enemy_id)
			assert_false(enemy.attacks.is_empty(), "%s : attaques" % enemy_id)
	for skin_id: String in ["chtholly", "bibliothecaire", "forgeron", "enfant"]:
		var skin := SkinRegistry.get_skin(StringName(skin_id))
		assert_not_null(skin, "skin %s" % skin_id)
		if skin != null:
			var sheet := SheetLoader.read_sheet(skin)
			var animations := SheetLoader.animations(sheet)
			for anim: String in [
				"repos", "marche", "course", "attaque", "charge", "degats", "mort"
			]:
				assert_true(animations.has(anim), "%s : animation %s" % [skin_id, anim])
			assert_eq(
				SheetLoader.hit_frames(sheet, &"attaque"),
				[1, 2, 3] as Array[int],
				"%s : coup" % skin_id
			)
			assert_eq(SheetLoader.wave_frame(sheet, &"charge"), 3, "%s : onde" % skin_id)
