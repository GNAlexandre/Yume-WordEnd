class_name StoryRunner
extends Node
## (E6) Joue les étapes d'une scène du récit (StoryData.STEPS ; ACTE1.md, 0.2), une à une, en
## coroutine. Enfant « Runner » de StoryDirector, qui lui prête ses outils (places, personnages,
## joueur, voile, suiveurs). Propriétaire : E6.
##
## - Chaque étape fait ce qu'elle dit et rend la main quand elle est finie (marche attendue,
##   dialogue lu, fondu fini…) ; une étape dont le « if » est faux est passée.
## - stop() arrête la scène (partie libérée, autre partie chargée) ; skip() passe une séquence déjà
##   vue : le reste se joue d'un coup (attentes, cartons et répliques sautés, marches posées,
##   fondus immédiats), sans rien perdre de ce qui change l'état (drapeaux, créneau, carte).
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
## Préfixe de l'identifiant des dialogues d'une scène (aucun PNJ de ce nom).
const DIALOGUE_PREFIX := "story_"
const TALK := &"parle"
const IDLE := &"repos"

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
	var steps: Array = data.get("steps", [])
	var completed: bool = await _run_steps(steps)
	_running = false
	_kind = ""
	return completed and not _stopped


func is_running() -> bool:
	return _running


## Étape en cours (« do »), "" hors scène.
func current_step() -> String:
	return _kind


## Arrête la scène (le dialogue en cours se ferme).
func stop() -> void:
	_stopped = true
	if _dialogue.is_running():
		_dialogue.stop()


## Passe le reste de la scène (séquence déjà vue).
func skip() -> void:
	if not _running or fast:
		return
	fast = true
	if _dialogue.is_running():
		_dialogue.stop()
	var overlay: Node = stage.overlay()
	if overlay != null:
		overlay.call(&"hide_card")


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


# --- Étapes -------------------------------------------------------------------------------------


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
	var actor := LifeDirector.stage(who, at.origin, facing)
	if actor == null:
		push_warning("StoryRunner : %s ne peut pas paraître (%s)" % [who, scene_id])
		return
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
		if fast:
			stage.place_player(target.origin, facing)
		elif step.get("wait", true):
			await stage.walk_player(target.origin, gait)
			if facing != Vector3.ZERO:
				stage.place_player(Vector3.INF, facing)
		else:
			stage.walk_player(target.origin, gait)
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
			visual.play(anim, true)
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
	if fast:
		return
	var file := str(step.get("file", scene_id))
	var path := StoryData.dialogue_path(island, file)
	var npc: NpcData = null
	var dialogue_id := StringName(DIALOGUE_PREFIX + String(scene_id))
	if step.has("npc"):
		npc = LifeData.find_npc(StringName(str(step["npc"])))
	if not _dialogue.play(path, str(step["node"]), dialogue_id, npc):
		push_warning(
			"StoryRunner : dialogue %s:%s impossible (%s)" % [file, step["node"], scene_id]
		)
		return
	while _dialogue.is_running() and not _stopped:
		await get_tree().process_frame


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
		if timeout > 0.0 and waited >= timeout:
			if step.has("timeout_flag"):
				GameState.set_flag(StringName(str(step["timeout_flag"])))
			break
		await get_tree().physics_frame
		if not get_tree().paused and not DialogueRunner.is_any_running():
			waited += get_physics_process_delta_time()
	director.call(&"expect", {})


func _game(step: Dictionary) -> void:
	var game := StringName(str(step["game"]))
	var params: Dictionary = step.get("params", {})
	if bool(director.call(&"has_game", game)) and not fast:
		await director.call(&"run_game", game, params)
		return
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


static func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value == null:
		return result
	for item: Variant in value if value is Array else [value]:
		result.append(str(item))
	return result


# --- Qui parle -----------------------------------------------------------------------------------


func _on_dialogue_line(_speaker: String, _line: String, _choices: Array[String]) -> void:
	if not _dialogue.is_running():
		return
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
