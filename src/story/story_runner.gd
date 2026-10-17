class_name StoryRunner
extends Node
## (E6) Joue les étapes d'une scène du récit (StoryData.STEPS ; ACTE1.md, 0.2), une à une, en
## coroutine. Enfant « Runner » de StoryDirector, qui lui prête ses outils (places, personnages,
## joueur, voile, suiveurs). Propriétaire : E6.
##
## - Chaque étape fait ce qu'elle dit et rend la main quand elle est finie (marche attendue,
##   dialogue lu, fondu fini…) ; une étape dont le « if » est faux est passée.
## - stop() arrête la scène (partie libérée, autre partie chargée) ; skip() la passe (StorySkip :
##   une séquence déjà vue en scénarisé, toute scène en libre) : le reste se joue d'un coup
##   (attentes, cartons et répliques sautés, marches posées, fondus immédiats, jeux arrêtés), sans
##   rien perdre de ce qui change l'état (drapeaux, créneau, carte ; (X-L2) les effets des
##   dialogues sautés, un choix pris par la clé « skip » de la scène ou le premier choix ; une
##   attente remplie : carte atteinte, joueur posé au but).
## - (X-L2) StorySkip.FORWARD_ACTION tenue (plus de FORWARD_HOLD s) accélère la scène
##   (Engine.time_scale à FAST_FORWARD : répliques, attentes, marches, fondus) tant que la scène
##   tient le joueur ou qu'un de ses dialogues est ouvert, hors jeux ; les répliques passent seules
##   après leur temps de lecture.
## - Pendant un dialogue de la scène, le personnage qui parle (speaker_id) joue « parle » s'il
##   était au repos.

## Une étape commence (index dans sa liste, « do »).
signal step_started(index: int, kind: String)

## Délai au bout duquel une marche est terminée d'office (s).
const WALK_TIMEOUT := 25.0
## Distance à laquelle le joueur mené a atteint un point de passage, et son but (m).
const PASS_DISTANCE := 0.6
const ARRIVE_DISTANCE := 0.3
## Durées par défaut (s) : fondu, carton, cadrage.
const DEFAULT_FADE := 0.8
const DEFAULT_CARD := 2.6
const DEFAULT_CAMERA := 1.2
## (X-L2) Accélération d'une scène quand StorySkip.FORWARD_ACTION est tenue (Engine.time_scale).
const FAST_FORWARD := 3.5
## (X-L2) Durée (s, non accélérées) au-delà de laquelle un appui compte comme tenu : un appui bref
## fait seulement avancer le dialogue.
const FORWARD_HOLD := 0.3
## (X-L2) Temps de lecture d'une réplique entière quand la scène est accélérée (s de jeu, donc
## accélérées) : base + par caractère ; la réplique passe ensuite seule (pas les choix).
const FORWARD_READ_BASE := 0.8
const FORWARD_READ_PER_CHAR := 0.04
## (X-L2) Rayon par défaut d'une attente « reach » (StoryDirector.DEFAULT_RADIUS).
const REACH_RADIUS := 2.5
## Préfixe de l'identifiant des dialogues d'une scène (aucun PNJ de ce nom).
const DIALOGUE_PREFIX := "story_"
const TALK := &"parle"
const IDLE := &"repos"
## Présentations du dialogue (DialogueBox.set_presentation, lot U1).
const PRESENT_HELD := DialogueBox.PRESENTATION_BANDEAU
const PRESENT_FREE := DialogueBox.PRESENTATION_NUIT

var director: Node
var stage: StoryStage
var scene_id: StringName = &""
var island: StringName = &""
## Séquence passée : le reste se joue d'un coup.
var fast: bool = false

var _running: bool = false
var _stopped: bool = false
var _kind: String = ""
var _dialogue: StoryDialogue
var _talker: StringName = &""
## (X-L2) La scène en cours, le fichier du dialogue ouvert, la clé « skip » déjà appliquée.
var _data: Dictionary = {}
var _dialogue_path: String = ""
var _skip_flags_set: bool = false
## (X-L2) Accélération : appui tenu depuis (s), accélérée, échelle de temps d'avant, réplique.
var _forward_held: float = 0.0
var _forwarding: bool = false
var _scale_before: float = 1.0
var _line_wait: float = 0.0
var _line_length: int = 0


func _ready() -> void:
	_dialogue = StoryDialogue.new()
	_dialogue.name = "SceneDialogue"
	add_child(_dialogue)
	EventBus.dialogue_line.connect(_on_dialogue_line)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)


## Joue la scène (coroutine) ; vrai si elle est allée au bout (faux : arrêtée).
func run(id: StringName, data: Dictionary, island_id: StringName) -> bool:
	scene_id = id
	island = island_id
	fast = false
	_stopped = false
	_running = true
	_data = data
	_skip_flags_set = false
	var steps: Array = data.get("steps", [])
	var completed: bool = await _run_steps(steps)
	_running = false
	_kind = ""
	_set_forward(false)
	return completed and not _stopped


func _physics_process(delta: float) -> void:
	var held := _running and not fast and Input.is_action_pressed(StorySkip.FORWARD_ACTION)
	_forward_held = _forward_held + delta / maxf(Engine.time_scale, 0.01) if held else 0.0
	_set_forward(held and _forward_held >= FORWARD_HOLD and _can_forward())
	if _forwarding:
		_read_line(delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
		_set_forward(false)


func is_running() -> bool:
	return _running


## Étape en cours (« do »), "" hors scène.
func current_step() -> String:
	return _kind


## Arrête la scène (le dialogue en cours se ferme).
func stop() -> void:
	_stopped = true
	_set_forward(false)
	if _dialogue.is_running():
		_dialogue.stop()


## Passe le reste de la scène (StorySkip) : mode rapide, dialogue ouvert fermé (ses effets à
## venir appliqués), carton retiré, (X-L2) jeux arrêtés (MiniGames.stop_all).
func skip() -> void:
	if not _running or fast:
		return
	fast = true
	_set_forward(false)
	if _dialogue.is_running():
		var node := _dialogue.current_node()
		_dialogue.stop()
		_skip_dialogue(_dialogue_path, node, true)
	var overlay: Node = stage.overlay()
	if overlay != null:
		overlay.call(&"hide_card")
	MiniGames.stop_all()


## (X-L2) Vrai tant que la scène est accélérée (StorySkip.FORWARD_ACTION tenue).
func is_forwarding() -> bool:
	return _forwarding


func _run_steps(steps: Array) -> bool:
	for index: int in steps.size():
		if _stopped or not is_inside_tree():
			return false
		var step: Dictionary = steps[index]
		if step.has("if") and not DialogueRunner.evaluate(step["if"]):
			continue
		_kind = str(step.get("do", ""))
		step_started.emit(index, _kind)
		await _step(step)
	return not _stopped


func _step(step: Dictionary) -> void:
	match _kind:
		"control":
			stage.set_control(bool(step["on"]))
		"place":
			_place(step)
		"walk":
			await _walk(step)
		"follow":
			stage.add_follower(
				StringName(str(step["who"])),
				float(step.get("distance", 2.0)),
				float(step.get("stop_beyond", 8.0)),
				StringName(str(step.get("gait", "marche")))
			)
		"unfollow":
			stage.remove_follower(StringName(str(step["who"])))
		"face":
			_face(StringName(str(step["who"])), step["toward"])
		"anim":
			await _anim(step)
		"outfit":
			_outfit(StringName(str(step["who"])), StringName(str(step["outfit"])))
		"leave":
			stage.remove_follower(StringName(str(step["who"])))
			LifeDirector.dismiss(StringName(str(step["who"])))
		"release":
			stage.remove_follower(StringName(str(step["who"])))
			LifeDirector.release(StringName(str(step["who"])))
		"bubble":
			_bubble(step)
		"dialogue":
			await _talk(step)
		"camera":
			await _camera(step)
		"camera_reset":
			var rig: Node = stage.camera_rig()
			var time := 0.0 if fast else float(step.get("time", DEFAULT_CAMERA))
			if rig != null:
				rig.call(&"release_story", time)
			if step.get("wait", false):
				await _sleep(time)
		"fade":
			await _fade(str(step["to"]), float(step.get("time", DEFAULT_FADE)))
		"card":
			if not fast:
				var overlay: Node = stage.overlay()
				if overlay != null:
					var time := float(step.get("time", DEFAULT_CARD))
					overlay.call(&"show_card", _text(str(step["text"])), time)
					await stage.wait_overlay(_interrupted)
		"go_to":
			await WorldManager.go_to(
				StringName(str(step["map"])), StringName(str(step.get("marker", "Spawn")))
			)
		"moment":
			_moment(step)
		"slot":
			var wanted := StringName(str(step["slot"]))
			if wanted == &"next":
				wanted = LifeSlots.next(LifeSlots.current())
			LifeDirector.set_slot(wanted, 0.0 if fast else float(step.get("time", -1.0)))
		"next_day":
			director.call(&"advance_day")
		"flag":
			for flag: String in _names(step.get("set")):
				GameState.set_flag(StringName(flag))
			for flag: String in _names(step.get("clear")):
				GameState.set_flag(StringName(flag), false)
		"wait":
			await _sleep(float(step["time"]))
		"wait_for":
			await _wait_for(step)
		"game":
			await _game(step)
		"hint":
			director.call(&"set_scene_hint", _text(str(step["text"])) if step.has("text") else "")
		"calendar":
			GameState.write_calendar(GameState.day, StringName(str(step.get("line", ""))))
		"show":
			_show(str(step["node"]), bool(step["visible"]))
		"ship":
			await _ship(step)
		"player":
			stage.set_player_visible(bool(step["visible"]))
		"props":
			_props(step)


# --- Étapes -------------------------------------------------------------------------------------


## (E7) Un navire : l'action de ShipControl, attendue (sauf « wait » : false) ; séquence passée :
## son état final, d'un coup.
func _ship(step: Dictionary) -> void:
	var ship_id := StringName(str(step["ship"]))
	var action := StringName(str(step["action"]))
	if not fast:
		await ShipControl.play(ship_id, action, false)
		while (
			bool(step.get("wait", true))
			and ShipControl.is_playing(ship_id, action)
			and not fast
			and not _stopped
			and is_inside_tree()
		):
			await get_tree().physics_frame
	if fast:
		ShipControl.finish(ship_id, action)


## (S2) Pose (ou retire, « clear ») un cercle d'images animées et sa lueur (les talismans, 8.8).
func _props(step: Dictionary) -> void:
	var id := StringName(str(step["id"]))
	stage.clear_props(id)
	if step.get("clear", false):
		return
	var texture := load(StoryData.image_path(str(step["image"]))) as Texture2D
	var color := Color.html(str(step.get("color", "#ffffff")))
	(
		stage
		. add_props(
			id,
			texture,
			stage.resolve(step["at"]).origin,
			{
				"count": int(step.get("count", 1)),
				"radius": float(step.get("radius", 0.0)),
				"lift": float(step.get("lift", 0.0)),
				"frames": int(step.get("frames", 1)),
				"fps": float(step.get("fps", 0.0)),
				"light": float(step.get("light", 0.0)),
				"color": color,
			}
		)
	)


## Montre ou cache un nœud de la carte courante (le cristal qui sonne : Geometry/Nygglatho/
## comm_crystal_call_1) ; avertit s'il manque.
func _show(path: String, shown: bool) -> void:
	var map := WorldManager.current_map_node()
	var node := map.get_node_or_null(NodePath(path)) as Node3D if map != null else null
	if node == null:
		push_warning("StoryRunner : nœud %s absent de la carte (%s)" % [path, stage.scene_label])
		return
	node.visible = shown


func _place(step: Dictionary) -> void:
	var who := StringName(str(step["who"]))
	var at: Transform3D = stage.resolve(step["at"], step.get("offset"))
	var facing: Vector3 = (
		stage.direction(step["facing"], at.origin)
		if step.has("facing")
		else LifePlaces.facing_of(at)
	)
	if who == StoryData.PLAYER:
		stage.place_player(at.origin, facing)
		return
	# (S2) « lift » : posé au-dessus du sol (une pile de petites), sans collision ; sans lui, le
	# PNJ reprend sa collision de personnage immobile.
	var lift := float(step.get("lift", 0.0))
	var actor := LifeDirector.stage(who, at.origin + Vector3.UP * lift, facing)
	if actor == null:
		push_warning("StoryRunner : %s ne peut pas paraître (%s)" % [who, scene_id])
		return
	if is_instance_valid(actor.npc):
		actor.npc.set_moving(lift > 0.0)
	if step.has("outfit"):
		_outfit(who, StringName(str(step["outfit"])))
	if step.has("anim"):
		actor.play(StringName(str(step["anim"])), true)


func _walk(step: Dictionary) -> void:
	var who := StringName(str(step["who"]))
	var target: Transform3D = stage.resolve(step["to"], step.get("offset"))
	var facing: Vector3 = (
		stage.direction(step["facing"], target.origin) if step.has("facing") else Vector3.ZERO
	)
	var gait := StringName(str(step.get("gait", "marche")))
	if who == StoryData.PLAYER:
		stage.release_player_pose()
		if fast:
			stage.place_player(target.origin, facing)
		elif step.get("wait", true):
			# (X-L2) Passée en route : la marche cesse, le joueur est posé au but.
			await stage.walk_player(target.origin, gait, _interrupted)
			if facing != Vector3.ZERO:
				stage.place_player(Vector3.INF, facing)
		else:
			stage.walk_player(target.origin, gait, _interrupted)
		return
	var actor := LifeDirector.actor(who)
	if actor == null:
		actor = LifeDirector.stage(who, target.origin, facing)
		if actor == null:
			push_warning("StoryRunner : %s absent, marche impossible (%s)" % [who, scene_id])
		return
	if fast:
		actor.stop()
		actor.set_position(target.origin)
		actor.face(facing)
		actor.play(IDLE)
		return
	stage.ensure_nav()
	actor.walk_to(target.origin, facing, gait, Callable(), bool(step.get("direct", false)))
	if not step.get("wait", true):
		return
	var waited := 0.0
	while actor.is_moving() and not _stopped and not fast and waited < WALK_TIMEOUT:
		await get_tree().physics_frame
		if not get_tree().paused:
			waited += get_physics_process_delta_time()
	if actor.is_moving() and is_instance_valid(actor.npc):
		actor.stop()
		actor.set_position(target.origin)
		actor.face(facing)
	actor.play(IDLE)


func _face(who: StringName, toward: Variant) -> void:
	if who == StoryData.PLAYER:
		var player: Node3D = stage.player()
		if player != null:
			var direction: Vector3 = stage.direction(toward, player.global_position)
			stage.place_player(Vector3.INF, direction)
		return
	var actor := LifeDirector.actor(who)
	if actor != null:
		actor.face(stage.direction(toward, actor.position()))


func _anim(step: Dictionary) -> void:
	var who := StringName(str(step["who"]))
	var anim := StringName(str(step["anim"]))
	var visual: CharacterVisual = null
	if who == StoryData.PLAYER:
		var player: Node3D = stage.player()
		visual = player.get_node_or_null(^"Visual") as CharacterVisual if player != null else null
		if visual != null and visual.has_animation(anim):
			# (S2) Une pose tenue : sinon le joueur rejoue « repos » dès l'image suivante.
			stage.hold_player_pose(anim, 0.0 if fast else float(step.get("time", 0.0)))
	else:
		var actor := LifeDirector.actor(who)
		if actor == null:
			return
		actor.play(anim, true)
		visual = actor.npc.visual if is_instance_valid(actor.npc) else null
	var time := float(step.get("time", 0.0))
	if not step.get("wait", false) or fast:
		if time > 0.0 and not fast:
			stage.idle_later(who, time)
		return
	if time > 0.0:
		await _sleep(time)
	elif visual != null:
		var waited := 0.0
		while visual.is_playing() and waited < 3.0 and not fast and not _stopped:
			await get_tree().physics_frame
			waited += get_physics_process_delta_time()
	if who != StoryData.PLAYER and LifeDirector.actor(who) != null and time > 0.0:
		LifeDirector.actor(who).play(IDLE)


func _outfit(who: StringName, outfit: StringName) -> void:
	var actor := LifeDirector.actor(who)
	if actor == null or not is_instance_valid(actor.npc):
		return
	actor.outfit = outfit
	actor.npc.set_outfit(actor.data.load_outfit(outfit))


func _bubble(step: Dictionary) -> void:
	if fast:
		return
	var actor := LifeDirector.actor(StringName(str(step["who"])))
	if actor != null:
		actor.say(_text(str(step["text"])), float(step.get("time", Npc.BUBBLE_TIME)))


func _talk(step: Dictionary) -> void:
	var file := str(step.get("file", scene_id))
	var path := StoryData.dialogue_path(island, file)
	if fast:
		_skip_dialogue(path, str(step["node"]), false)
		return
	_dialogue_path = path
	var npc: NpcData = null
	var dialogue_id := StringName(DIALOGUE_PREFIX + String(scene_id))
	if step.has("npc"):
		npc = LifeData.find_npc(StringName(str(step["npc"])))
	_present(_presentation(step))
	if not _dialogue.play(path, str(step["node"]), dialogue_id, npc):
		push_warning(
			"StoryRunner : dialogue %s:%s impossible (%s)" % [file, step["node"], scene_id]
		)
		return
	while _dialogue.is_running() and not _stopped:
		await get_tree().process_frame
	_present(PRESENT_FREE)


## (X-L2) Les effets d'un dialogue sauté depuis node (entered : déjà affiché), sans rien montrer
## (StoryDialogue.apply_silently) : ses nœuds, et à un choix le premier proposé ; un choix qui
## change l'état cède à la clé « skip » de la scène si elle en a une (ses drapeaux, une fois).
func _skip_dialogue(path: String, node: String, entered: bool) -> void:
	if path.is_empty() or node.is_empty():
		return
	var flags := StorySkip.skip_flags(_data)
	var crossed := StoryDialogue.apply_silently(path, node, true, flags.is_empty(), entered)
	if crossed and not flags.is_empty() and not _skip_flags_set:
		_skip_flags_set = true
		for flag: StringName in flags:
			GameState.set_flag(flag)


## Présentation du dialogue (interface « Nuit douce », lot U1) : « presentation » de l'étape, sinon
## « bandeau » tant que la scène tient le joueur (séquence sans contrôle), « nuit » s'il a la main.
func _presentation(step: Dictionary) -> StringName:
	if step.has("presentation"):
		return StringName(str(step["presentation"]))
	var body: Player = stage.player()
	return PRESENT_HELD if body != null and body.is_story_held() else PRESENT_FREE


## Demande la présentation à la boîte de dialogue (DialogueBox.set_presentation, lot U1).
func _present(presentation: StringName) -> void:
	if DialogueBox.presentation() != presentation:
		DialogueBox.set_presentation(presentation)


func _camera(step: Dictionary) -> void:
	var rig: Node = stage.camera_rig()
	if rig == null:
		return
	var at: Transform3D = stage.resolve(step["to"], step.get("offset"))
	var time := 0.0 if fast else float(step.get("time", DEFAULT_CAMERA))
	rig.call(
		&"frame_story",
		at.origin + Vector3.UP * 0.8,
		float(step.get("distance", -1.0)),
		float(step.get("pitch", -1.0)),
		time
	)
	if step.get("wait", false):
		await _sleep(time)


func _fade(to: String, time: float) -> void:
	var overlay: Node = stage.overlay()
	if overlay == null:
		return
	var color := StoryData.WHITE if to == "white" else StoryData.BLACK
	if to == "clear":
		color = overlay.call(&"fade_color")
	overlay.call(&"fade_to", color, 0.0 if to == "clear" else 1.0, 0.0 if fast else time)
	await stage.wait_overlay(_interrupted)
	if fast and is_instance_valid(overlay):
		overlay.call(&"set_fade", color, 0.0 if to == "clear" else 1.0)


## Vrai quand une attente doit cesser : scène arrêtée ou passée.
func _interrupted() -> bool:
	return _stopped or fast


func _moment(step: Dictionary) -> void:
	var time := 0.0 if fast else float(step.get("time", -1.0))
	if step.has("moment") and step.has("weather"):
		Atmosphere.set_atmosphere(
			StringName(str(step["moment"])), StringName(str(step["weather"])), time
		)
	elif step.has("moment"):
		Atmosphere.set_moment(StringName(str(step["moment"])), time)
	elif step.has("weather"):
		Atmosphere.set_weather(StringName(str(step["weather"])), time)


func _wait_for(step: Dictionary) -> void:
	var timeout := float(step.get("timeout", 0.0))
	var waited := 0.0
	director.call(&"expect", step)
	while not _stopped and not bool(director.call(&"expected_met", step)):
		if fast:
			# (X-L2) Scène passée : ce qu'elle attendait arrive.
			await _meet(step)
			break
		if timeout > 0.0 and waited >= timeout:
			if step.has("timeout_flag"):
				GameState.set_flag(StringName(str(step["timeout_flag"])))
			break
		await get_tree().physics_frame
		if not get_tree().paused and not DialogueRunner.is_any_running():
			waited += get_physics_process_delta_time()
	director.call(&"expect", {})


## (X-L2) Une attente passée : la carte attendue est rejointe (go_to, par le marqueur où mène la
## sortie de la carte courante, sinon Spawn), le joueur posé au point à atteindre (à côté d'un
## personnage) ; une conversation ou un objet à examiner attendus sont tenus pour faits.
func _meet(step: Dictionary) -> void:
	while WorldManager.is_transitioning() and not _stopped and is_inside_tree():
		await get_tree().physics_frame
	if _stopped or bool(director.call(&"expected_met", step)):
		return
	var map_id := StringName(str(step.get("map", "")))
	if not map_id.is_empty() and WorldManager.current_map() != map_id:
		await WorldManager.go_to(map_id, _arrival_marker(map_id))
	if step.has("reach") and not _stopped and is_inside_tree():
		var radius := float(step.get("radius", REACH_RADIUS))
		stage.place_player(_reach_point(step["reach"], radius))


## (X-L2) Le marqueur d'arrivée sur map_id depuis la carte courante (sa première sortie vers elle).
func _arrival_marker(map_id: StringName) -> StringName:
	var map := WorldManager.current_map_node()
	if map != null:
		for exit: MapExit in map.exits():
			if exit.target_map == map_id:
				return exit.target_marker
	return WorldManager.SPAWN_MARKER


## (X-L2) Où poser le joueur qui atteint spec : le point, ou à côté du personnage (vers le joueur).
func _reach_point(spec: Variant, radius: float) -> Vector3:
	var at: Vector3 = stage.resolve(spec).origin
	if (
		not (spec is String or spec is StringName)
		or LifeDirector.actor(StringName(str(spec))) == null
	):
		return at
	var body: Player = stage.player()
	var away := body.global_position - at if body != null else Vector3.BACK
	away.y = 0.0
	if away.length_squared() < 0.0001:
		away = Vector3.BACK
	return at + away.normalized() * minf(radius * 0.5, 0.8)


func _game(step: Dictionary) -> void:
	var game := StringName(str(step["game"]))
	var params: Dictionary = step.get("params", {})
	if bool(director.call(&"has_game", game)) and not fast:
		# (E8c) Un jeu qui n'a pas pu démarrer (carte d'essai, personnage absent) rend false :
		# le repli se joue.
		if bool(await director.call(&"run_game", game, params)):
			return
	else:
		director.call(&"announce_game", game, params)
	await _run_steps(step.get("fallback", []))


## Attend seconds secondes de jeu (pas pendant la pause), sauf si la scène est passée ou arrêtée.
func _sleep(seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not _stopped and not fast and is_inside_tree():
		await get_tree().physics_frame
		if not get_tree().paused:
			left -= get_physics_process_delta_time()


func _text(key: String) -> String:
	return StoryData.text(island, key, scene_id, key)


# --- Accélération (X-L2) -------------------------------------------------------------------------


## Vrai si la scène peut être accélérée : elle tient le joueur ou l'un de ses dialogues est ouvert,
## hors jeu (étape « game ») et hors pause.
func _can_forward() -> bool:
	if _kind == "game" or not is_inside_tree() or get_tree().paused:
		return false
	var body: Player = stage.player()
	return _dialogue.is_running() or (body != null and body.is_story_held())


## Accélère (on) la scène ou lui rend son temps (Engine.time_scale d'avant).
func _set_forward(on: bool) -> void:
	if on == _forwarding:
		return
	_forwarding = on
	_line_wait = 0.0
	if on:
		_scale_before = Engine.time_scale
		Engine.time_scale = FAST_FORWARD
	else:
		Engine.time_scale = _scale_before


## Scène accélérée : la réplique entière passe seule après son temps de lecture (delta : s de jeu).
func _read_line(delta: float) -> void:
	var box := get_tree().get_first_node_in_group(DialogueBox.GROUP) as DialogueBox
	if box == null or not _dialogue.is_running() or not box.is_waiting():
		_line_wait = 0.0
		return
	_line_wait += delta
	if _line_wait >= FORWARD_READ_BASE + FORWARD_READ_PER_CHAR * _line_length:
		_line_wait = 0.0
		box.advance()


static func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value == null:
		return result
	for item: Variant in value if value is Array else [value]:
		result.append(str(item))
	return result


# --- Qui parle -----------------------------------------------------------------------------------


func _on_dialogue_line(_speaker: String, line: String, _choices: Array) -> void:
	if not _dialogue.is_running():
		return
	_line_length = line.length()
	_line_wait = 0.0
	var speaker := DialogueRunner.current_speaker_id()
	if speaker == _talker:
		return
	_quiet(_talker)
	_talker = speaker
	var actor := LifeDirector.actor(speaker) if not speaker.is_empty() else null
	if actor != null and is_instance_valid(actor.npc):
		if actor.npc.visual.current_animation() == IDLE:
			actor.play(TALK)


func _on_dialogue_ended(_dialogue_id: StringName) -> void:
	_quiet(_talker)
	_talker = &""


func _quiet(npc_id: StringName) -> void:
	var actor := LifeDirector.actor(npc_id) if not npc_id.is_empty() else null
	if actor != null and is_instance_valid(actor.npc):
		if actor.npc.visual.current_animation() == TALK:
			actor.play(IDLE)
