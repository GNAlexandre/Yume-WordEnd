extends "res://tests/stubs/l10_ui_test.gd"
## HUD (L10) : chaque signal de l'EventBus met à jour ses nœuds, et rien d'autre ne le fait ;
## marqueur de la cible verrouillée, surcouche F3, coins laissés aux contrôles tactiles. (F1) Le
## panneau de l'arène, ses bannières, le nom de zone et l'objectif de quête sont partis avec
## l'ancienne île.

const HUD := preload("res://src/ui/hud.tscn")
const HudScript := preload("res://src/ui/hud.gd")
const LockPlayer := preload("res://tests/stubs/l10_lock_player.gd")
const SignPlayer := preload("res://tests/stubs/u1_sign_player.gd")
const Board := preload("res://tests/stubs/l1_interactable_stub.gd")


func _hud() -> HudScript:
	var hud: HudScript = HUD.instantiate()
	hud.fade_time = 0.02
	hud.saved_time = 0.05
	return add_child_autofree(hud)


func _node(hud: Control, unique_name: String) -> Control:
	return hud.get_node("%" + unique_name) as Control


func _hearts(hud: Control) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for heart: Node in _node(hud, "Hearts").get_children():
		textures.append((heart as TextureRect).texture)
	return textures


func test_hearts_start_from_game_state_then_follow_signal() -> void:
	var hud := _hud()
	assert_eq(hud.health(), Vector2i(5, 5), "avant la 1re émission : GameState.max_hp pleins")
	EventBus.player_health_changed.emit(3, 5)
	assert_eq(hud.health(), Vector2i(3, 5))
	var full := HudScript.HEART_FULL
	var empty := HudScript.HEART_EMPTY
	var expected: Array[Texture2D] = [full, full, full, empty, empty]
	assert_eq(_hearts(hud), expected)
	EventBus.player_health_changed.emit(4, 6)
	assert_eq(_hearts(hud).size(), 6, "6 cœurs avec la promesse du gâteau au beurre")
	assert_eq(hud.health(), Vector2i(4, 6))


func test_hud_reads_nothing_without_signals() -> void:
	var hud := _hud()
	EventBus.set_block_signals(true)
	GameState.max_hp = 6
	EventBus.set_block_signals(false)
	await wait_process_frames(2)
	assert_eq(hud.health(), Vector2i(5, 5), "PV max changés sans signal : rien ne bouge")


func test_damage_shakes_hearts_and_flashes_red() -> void:
	var hud := _hud()
	EventBus.player_damaged.emit(1, null)
	assert_true(hud.is_damage_feedback_playing(), "flash rouge")
	await wait_seconds(0.7)
	assert_false(hud.is_damage_feedback_playing(), "bref")
	assert_almost_eq(_node(hud, "Hearts").position.x, 0.0, 0.01, "tremblement terminé")


func test_charge_gauge_follows_charge_progress() -> void:
	var hud := _hud()
	var row := _node(hud, "ChargeRow")
	var bar := _node(hud, "ChargeBar") as ProgressBar
	var label := _node(hud, "ChargeLabel") as Label
	assert_false(row.visible, "0 au départ : cachée")
	EventBus.charge_progress.emit(0.4)
	assert_true(row.visible)
	assert_almost_eq(bar.value, 0.4, 0.001)
	assert_eq(bar.theme_type_variation, &"")
	EventBus.charge_progress.emit(1.0)
	assert_eq(bar.theme_type_variation, &"ChargeBarFull", "pleine : dorée")
	assert_eq(label.text, "Onde prête !")
	EventBus.charge_progress.emit(0.0)
	assert_false(row.visible, "0 au relâcher : cachée")


func test_old_island_panels_are_gone() -> void:
	var hud := _hud()
	for gone: String in ["ArenaPanel", "Banner", "ZoneBanner", "Quests", "Journal"]:
		assert_null(hud.get_node_or_null("%" + gone), "(F1) %s retiré" % gone)


## (U1) L'invite « E / A : Parler » est devenue un signe posé au-dessus de la cible du joueur.
func test_interaction_prompt() -> void:
	var hud := _hud()
	var signs := hud.interact_signs()
	var player := add_child_autofree(SignPlayer.new()) as Node3D
	var board := add_child_autofree(Board.new()) as Node3D
	board.set(&"prompt", "Parler")
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), "pas de cible : pas de signe")
	player.set(&"target", board)
	await wait_process_frames(2)
	assert_eq(signs.call(&"full_target"), board, "signe sur la cible")
	assert_eq(signs.call(&"full_kind"), InteractSign.EXAMINE)
	board.set(&"prompt", "")
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), '"" : plus rien')


func test_dialogue_hides_prompt_and_gauge() -> void:
	var hud := _hud()
	var signs := hud.interact_signs()
	var player := add_child_autofree(SignPlayer.new()) as Node3D
	player.set(&"target", add_child_autofree(Board.new()))
	EventBus.charge_progress.emit(0.5)
	await wait_process_frames(2)
	assert_not_null(signs.call(&"full_target"))
	EventBus.dialogue_started.emit(&"librarian")
	await wait_process_frames(2)
	assert_null(signs.call(&"full_target"), "signe masqué pendant un dialogue")
	assert_false(_node(hud, "ChargeRow").visible, "jauge masquée pendant un dialogue")
	EventBus.dialogue_ended.emit(&"librarian")
	await wait_process_frames(2)
	assert_not_null(signs.call(&"full_target"))
	assert_true(_node(hud, "ChargeRow").visible)


func test_death_fades_to_black_and_back() -> void:
	var hud := _hud()
	hud.death_delay = 0.0
	hud.death_fade_time = 0.1
	assert_eq(hud.death_fade_alpha(), 0.0)
	EventBus.player_died.emit()
	await wait_seconds(0.3)
	assert_almost_eq(hud.death_fade_alpha(), 1.0, 0.001, "noir")
	EventBus.player_respawned.emit()
	await wait_seconds(0.8)
	assert_eq(hud.death_fade_alpha(), 0.0, "retour")


func test_saved_indicator() -> void:
	var hud := _hud()
	assert_false(_node(hud, "SavedIndicator").visible)
	SaveManager.saved.emit("user://x.json")
	assert_true(_node(hud, "SavedIndicator").visible, "« Sauvegardé »")
	await wait_seconds(0.4)
	assert_false(_node(hud, "SavedIndicator").visible, "puis s'efface")


func test_lock_marker_follows_locked_target() -> void:
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.look_at_from_position(Vector3(0, 3, 8), Vector3.ZERO)
	camera.make_current()
	var target := Node3D.new()
	add_child_autofree(target)
	target.position = Vector3(1, 0, 0)
	var player: LockPlayer = add_child_autofree(LockPlayer.new())
	var hud := _hud()
	var marker := _node(hud, "LockMarker")
	await wait_process_frames(2)
	assert_false(marker.visible, "pas de cible : pas de marqueur")
	player.target = target
	await wait_process_frames(2)
	assert_true(marker.visible, "cible verrouillée marquée")
	var expected := camera.unproject_position(Vector3(1, hud.lock_marker_height, 0))
	assert_almost_eq(
		marker.position.x + marker.size.x * 0.5, expected.x, 0.5, "au-dessus de la cible"
	)
	assert_between(
		expected.y - (marker.position.y + marker.size.y), 0.0, 6.5, "flèche posée dessus"
	)
	target.position = Vector3(0, 0, 20)
	await wait_process_frames(2)
	assert_false(marker.visible, "cible derrière la caméra")
	target.position = Vector3(1, 0, 0)
	player.target = null
	await wait_process_frames(2)
	assert_false(marker.visible, "verrou levé")


func test_lock_marker_follows_the_shown_position_of_a_moving_target() -> void:
	# Lissage physique (project.godot) : un Timere est dessiné entre ses deux dernières images
	# physiques ; le marqueur, posé à chaque image, doit suivre cette place affichée et non la
	# position physique, sinon il tremble d'un pas de physique par rapport au sprite.
	assert_true(get_tree().root.is_physics_interpolated_and_enabled(), "lissage physique actif")
	var camera := Camera3D.new()
	# Comme la caméra du joueur (camera_rig.gd) : posée à chaque image, hors lissage.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child_autofree(camera)
	camera.look_at_from_position(Vector3(0, 3, 8), Vector3.ZERO)
	camera.make_current()
	var target := Node3D.new()
	add_child_autofree(target)
	var player: LockPlayer = add_child_autofree(LockPlayer.new())
	var hud := _hud()
	var marker := _node(hud, "LockMarker")
	await wait_process_frames(1)
	player.target = target
	# Un pas de 2 m vers l'est à chaque image physique, sans reset : la place affichée glisse.
	var stepper := func() -> void: target.position += Vector3(2, 0, 0)
	get_tree().physics_frame.connect(stepper)
	var worst := 0.0
	for _i in 8:
		await wait_process_frames(1)
		hud.call(&"_update_lock_marker")
		var shown := target.get_global_transform_interpolated().origin
		var expected := camera.unproject_position(shown + Vector3.UP * hud.lock_marker_height)
		worst = maxf(worst, absf(marker.position.x + marker.size.x * 0.5 - expected.x))
	get_tree().physics_frame.disconnect(stepper)
	assert_true(marker.visible, "cible marquée")
	assert_lt(worst, 0.5, "au-dessus de la place affichée, jamais de la position physique")


func test_f3_toggles_performance_overlay() -> void:
	var hud := _hud()
	var enemy := Node.new()
	enemy.add_to_group(&"enemies")
	add_child_autofree(enemy)
	assert_false(_node(hud, "PerfOverlay").visible)
	push_key(KEY_F3)
	assert_true(_node(hud, "PerfOverlay").visible, "F3 : surcouche")
	var text := (_node(hud, "PerfLabel") as Label).text
	for line: String in ["FPS", "Appels de dessin", "Primitives", "Mémoire vidéo"]:
		assert_string_contains(text, line)
	assert_string_contains(text, "Ennemis : %d" % get_tree().get_nodes_in_group(&"enemies").size())
	push_key(KEY_F3)
	assert_false(_node(hud, "PerfOverlay").visible, "F3 encore : cachée")


func test_layout_leaves_touch_corners_free_and_lets_mouse_through() -> void:
	var hud := _hud()
	EventBus.player_health_changed.emit(6, 6)
	EventBus.charge_progress.emit(1.0)
	EventBus.interaction_available.emit("Parler")
	SaveManager.saved.emit("user://x.json")
	hud.toggle_perf_overlay()
	await wait_process_frames(2)
	var area := hud.get_global_rect()
	var top_right := Rect2(area.end.x - 200.0, area.position.y, 200.0, 100.0)
	var bottom := Rect2(area.position.x, area.end.y - 200.0, area.size.x, 200.0)
	# Écrans modaux enfants du HUD (menu pause, (E6) calendrier et voile des scènes, plein
	# écran) : ils prennent la souris quand ils sont ouverts.
	var overlays: Array[Node] = [
		_node(hud, "DamageFlash"),
		_node(hud, "DeathFade"),
		_node(hud, "PauseMenu"),
		_node(hud, "StoryOverlay"),
		_node(hud, "Calendar"),
		# (U1) Les signes d'interaction se dessinent au-dessus du monde, là où sont les cibles,
		# sans prendre la souris.
		_node(hud, "InteractSigns"),
	]
	assert_eq(
		_node(hud, "InteractSigns").mouse_filter, Control.MOUSE_FILTER_IGNORE, "signes : IGNORE"
	)
	for node: Node in hud.find_children("*", "Control", true, false):
		var control := node as Control
		var in_overlay := overlays.any(
			func(o: Node) -> bool: return o == node or o.is_ancestor_of(node)
		)
		if in_overlay:
			continue
		assert_eq(control.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s laisse passer" % node.name)
		if control.is_visible_in_tree() and control.get_global_rect().has_area():
			var rect := control.get_global_rect()
			assert_false(rect.intersects(top_right), "%s hors du coin haut droit" % node.name)
			assert_false(rect.intersects(bottom), "%s hors du bas de l'écran" % node.name)
	assert_eq(hud.mouse_filter, Control.MOUSE_FILTER_IGNORE, "racine plein écran : IGNORE")
