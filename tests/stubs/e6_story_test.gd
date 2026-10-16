extends "res://tests/stubs/m2_game_test.gd"
## (E6) Base des tests du récit dans la vraie partie (main.tscn, vrais appuis) : une nouvelle
## partie ouvre l'acte 1 à l'entrepôt (WorldManager.START_MAP), séquences vues dans un fichier
## propre au test, fondus de carte courts. Aides : marcher par un chemin de la navigation au
## stick, lire les dialogues à la touche E (choix par les flèches), attendre une scène.

const STORY_ISLAND := &"ile_68"
## (AN) Fenêtre (images physiques) où un joueur qui tremble sans avancer compte comme immobile.
const STILL_WINDOW := 30

var _previous_fade: float
var _previous_seen: String


func start_map_for_test() -> StringName:
	return WorldManager.START_MAP


## (F1) Le récit est allumé (la base M1 le coupe).
func story_for_test() -> bool:
	return true


func before_each() -> void:
	super()
	_previous_fade = WorldManager.fade_time
	WorldManager.fade_time = 0.05
	_previous_seen = StoryDirector.seen_path
	StoryDirector.seen_path = (
		"user://test_story_seen_%s.cfg" % get_script().resource_path.get_file().get_basename()
	)
	StoryDirector.forget_seen()


func after_each() -> void:
	super()
	StoryDirector.forget_seen()
	StoryDirector.seen_path = _previous_seen
	StoryDirector.forget_seen()
	WorldManager.fade_time = _previous_fade


# --- Attentes ---------------------------------------------------------------------------------


## Attend que la scène soit jouée (lit les dialogues en route, premier choix sauf indication) ;
## faux après max_seconds.
func play_until_done(
	scene_id: StringName, max_seconds: float = 60.0, choices: Dictionary = {}
) -> bool:
	return await read_until(
		func() -> bool: return GameState.is_scene_done(scene_id), max_seconds, choices
	)


## Lit les dialogues (E pour avancer, ↓ puis E pour un autre choix que le premier : choices
## donne, par texte de choix proposé, l'index voulu) jusqu'à predicate.
func read_until(predicate: Callable, max_seconds: float, choices: Dictionary = {}) -> bool:
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	while not predicate.call():
		if Time.get_ticks_msec() >= deadline:
			return false
		if dialogue_box.is_open() and (dialogue_box.is_waiting() or dialogue_box.is_choosing()):
			if dialogue_box.is_choosing():
				var wanted := _wanted_choice(choices)
				while dialogue_box.selected_choice() < wanted:
					await tap_key(KEY_DOWN)
			await tap_key(KEY_E)
		elif dialogue_box.is_open() and dialogue_box.is_typing():
			await tap_key(KEY_E)
		else:
			await frames(1)
	return true


## Attend que le joueur ait la main (scène qui la rend, ou aucune scène).
func wait_control(max_seconds: float = 30.0) -> bool:
	return await read_until(
		func() -> bool:
			return (
				not player.is_story_held()
				and not WorldManager.is_transitioning()
				and not dialogue_box.is_open()
			),
		max_seconds
	)


## Trace de l'état du récit (journal du test).
func trace(label: String) -> void:
	if player == null or dialogue_box == null:
		print("[e6] %s : pas de partie" % label)
		return
	print(
		(
			"[e6] %s : carte %s, scène %s (%s), tenu %s, dialogue %s, joueur %s, indice « %s »"
			% [
				label,
				WorldManager.current_map(),
				StoryDirector.current_scene(),
				StoryDirector.runner().current_step(),
				player.is_story_held(),
				dialogue_box.is_open(),
				player.global_position.snapped(Vector3.ONE * 0.1),
				StoryDirector.hint(),
			]
		)
	)


func _wanted_choice(choices: Dictionary) -> int:
	var shown: Array = dialogue_box.get(&"_buttons")
	for index: int in shown.size():
		var button := shown[index] as Button
		if button.visible and choices.has(button.text):
			return int(choices[button.text])
	return 0


# --- Marcher ----------------------------------------------------------------------------------


## Marche au stick jusqu'à moins de radius m du point (repère du monde), par le chemin de la
## navigation de la carte (construite au besoin) ; faux après max_seconds.
func walk_to(target: Vector3, radius: float = 0.8, max_seconds: float = 40.0) -> bool:
	var nav: LifeNav = StoryDirector.stage().ensure_nav()
	var waypoints := PackedVector3Array()
	if nav != null and nav.ready:
		waypoints = StoryDirector.stage().route(
			player.global_position, nav.find_path(player.global_position, target)
		)
	waypoints.append(target)
	print(
		(
			"[e6] marche vers %s : %d points, nav %s"
			% [target.snapped(Vector3.ONE * 0.1), waypoints.size(), nav != null and nav.ready]
		)
	)
	var deadline := Time.get_ticks_msec() + int(max_seconds * 1000.0)
	var index := 0
	var start_map := WorldManager.current_map()
	var last_check := player.global_position
	var still_frames := 0
	var recent: Array[Vector3] = []
	var nudge := 0
	while index < waypoints.size():
		if Time.get_ticks_msec() >= deadline:
			stick(0.0, 0.0)
			var others := ""
			for actor: LifeActor in LifeDirector.actors():
				others += " %s@%s" % [actor.id, actor.position().snapped(Vector3.ONE * 0.1)]
			print(
				(
					"[e6] marche abandonnée en %s (point %d de %s ;%s)"
					% [player.global_position.snapped(Vector3.ONE * 0.1), index, waypoints, others]
				)
			)
			return false
		if WorldManager.current_map() != start_map:
			break
		var toward := waypoints[index] - player.global_position
		toward.y = 0.0
		var last := index == waypoints.size() - 1
		if toward.length() <= (radius if last else 0.6):
			index += 1
			continue
		if dialogue_box.is_open():
			# Une réplique en chemin (la scène garde le contrôle au joueur) : on la lit.
			stick(0.0, 0.0)
			await read_until(func() -> bool: return not dialogue_box.is_open(), 30.0)
			continue
		if player.is_story_held():
			stick(0.0, 0.0)
			return true
		var direction := toward.normalized()
		if nudge > 0:
			# Coincé contre un angle ou un personnage : un pas de côté.
			nudge -= 1
			var side := (
				Vector3(-direction.z, 0.0, direction.x)
				* (1.0 if posmod(still_frames, 80) < 40 else -1.0)
			)
			direction = (side + direction * 0.3).normalized()
		stick(direction.x, direction.z)
		await frames(1)
		if OS.has_environment("E6_TRACE_WALK") and Engine.get_physics_frames() % 20 == 0:
			print(
				(
					"[e6]   pas %s → %s (point %d, nudge %d)"
					% [
						player.global_position.snapped(Vector3.ONE * 0.05),
						waypoints[index],
						index,
						nudge
					]
				)
			)
		var moved := (
			Vector2(
				player.global_position.x - last_check.x, player.global_position.z - last_check.z
			)
			. length()
		)
		last_check = player.global_position
		# (AN) Coincé dans un angle, le joueur peut trembler d'un ou deux centimètres d'une image à
		# l'autre sans avancer : on compte aussi comme immobile un chemin net de moins de 10 cm sur
		# les STILL_WINDOW dernières images.
		recent.append(player.global_position)
		if recent.size() > STILL_WINDOW:
			recent.remove_at(0)
		var net := Vector2(
			player.global_position.x - recent[0].x, player.global_position.z - recent[0].z
		)
		var jittering := recent.size() == STILL_WINDOW and net.length() < 0.1
		still_frames = still_frames + 1 if moved < 0.01 or jittering else 0
		if still_frames > 0 and still_frames % 20 == 0 and nudge == 0:
			nudge = 14
		if still_frames > 160 and not last:
			index += 1
			still_frames = 0
	stick(0.0, 0.0)
	await frames(2)
	return true


## Marche jusqu'à une place ou un marqueur de la carte courante (StoryStage.resolve).
func walk_to_point(spec: Variant, radius: float = 0.8, max_seconds: float = 40.0) -> bool:
	return await walk_to(StoryDirector.stage().resolve(spec).origin, radius, max_seconds)


## Marche jusqu'à la sortie de la carte courante vers map_id (à pied ou avec son invite, E) et
## attend l'arrivée.
func take_exit(map_id: StringName, max_seconds: float = 40.0) -> bool:
	var map := WorldManager.current_map_node()
	var exit: MapExit = null
	for candidate: MapExit in map.exits():
		if candidate.target_map == map_id:
			exit = candidate
	if exit == null:
		return false
	var with_prompt := exit.needs_interaction()
	await walk_to(exit.global_position, 0.5, max_seconds)
	if with_prompt and WorldManager.current_map() != map_id:
		await tap_key(KEY_E)
	return await until(
		func() -> bool:
			return WorldManager.current_map() == map_id and not WorldManager.is_transitioning(),
		10.0
	)


## Utilise l'invite du récit la plus proche (Dormir, Laisser passer le temps…) : y marche, E.
func use_prompt(role: StringName) -> bool:
	for prompt: StoryPrompt in StoryDirector.prompts():
		if prompt.roles.has(role) and prompt.is_available():
			await walk_to(prompt.global_position, 0.6)
			await frames(3)
			await tap_key(KEY_E)
			return true
	return false
