extends "res://tests/stubs/l10_ui_test.gd"
## HUD (L10) : chaque signal de l'EventBus met à jour ses nœuds, et rien d'autre ne le fait ;
## marqueur de la cible verrouillée, surcouche F3, coins laissés aux contrôles tactiles.

const HUD := preload("res://src/ui/hud.tscn")
const HudScript := preload("res://src/ui/hud.gd")
const LockPlayer := preload("res://tests/stubs/l10_lock_player.gd")


func _hud() -> HudScript:
	var hud: HudScript = HUD.instantiate()
	hud.fade_time = 0.02
	hud.banner_time = 0.05
	hud.zone_time = 0.05
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
	assert_eq(_hearts(hud).size(), 6, "6 cœurs avec le marque-page")
	assert_eq(hud.health(), Vector2i(4, 6))


func test_hud_reads_nothing_without_signals() -> void:
	var hud := _hud()
	EventBus.set_block_signals(true)
	GameState.max_hp = 6
	GameState.set_quest_state(&"pages", &"active")
	EventBus.set_block_signals(false)
	await wait_process_frames(2)
	assert_eq(hud.health(), Vector2i(5, 5), "PV max changés sans signal : rien ne bouge")
	assert_eq(hud.quest_objective(&"pages"), "", "quête changée sans signal : rien ne bouge")


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


func test_arena_wave_score_banners_and_end() -> void:
	var hud := _hud()
	var panel := _node(hud, "ArenaPanel")
	assert_false(panel.visible, "hors arène : rien")
	EventBus.arena_score_changed.emit(&"dunes", 0)
	assert_true(panel.visible, "série lancée")
	assert_eq((_node(hud, "ScoreLabel") as Label).text, "Score 0")
	EventBus.wave_started.emit(&"dunes", 2, 7)
	assert_eq((_node(hud, "WaveLabel") as Label).text, "Vague 2")
	assert_true(_node(hud, "Banner").visible)
	assert_eq((_node(hud, "BannerLabel") as Label).text, "Vague 2")
	assert_eq((_node(hud, "BannerSub") as Label).text, "7 Timeres")
	EventBus.arena_score_changed.emit(&"dunes", 45)
	assert_eq((_node(hud, "ScoreLabel") as Label).text, "Score 45")
	assert_eq((_node(hud, "RecordLabel") as Label).text, "Record 45", "record battu en direct")
	EventBus.wave_cleared.emit(&"dunes", 2, 100)
	assert_eq((_node(hud, "BannerLabel") as Label).text, "Vague 2 terminée")
	assert_eq((_node(hud, "BannerSub") as Label).text, "+100")
	EventBus.arena_finished.emit(&"dunes", 145, true)
	assert_false(panel.visible, "masqué sur arena_finished")
	assert_false(_node(hud, "Banner").visible)


func test_wave_cleared_alone_sets_wave_number() -> void:
	var hud := _hud()
	EventBus.wave_cleared.emit(&"dunes", 4, 200)
	assert_true(_node(hud, "ArenaPanel").visible, "HUD créé en pleine série")
	assert_eq((_node(hud, "WaveLabel") as Label).text, "Vague 4")


func test_banner_fades_out() -> void:
	var hud := _hud()
	EventBus.wave_started.emit(&"dunes", 1, 5)
	await wait_seconds(0.4)
	assert_false(_node(hud, "Banner").visible, "bannière effacée après son délai")


func test_zone_name_on_entry() -> void:
	var hud := _hud()
	EventBus.zone_entered.emit(&"forest")
	assert_true(_node(hud, "ZoneBanner").visible)
	var shown := (_node(hud, "ZoneLabel") as Label).text
	assert_eq(shown, WorldManager.zone_display_name(&"forest"))
	await wait_seconds(0.4)
	assert_false(_node(hud, "ZoneBanner").visible, "en fondu")


func test_interaction_prompt() -> void:
	var hud := _hud()
	var prompt := _node(hud, "Prompt")
	assert_false(prompt.visible)
	EventBus.interaction_available.emit("Parler")
	assert_true(prompt.visible)
	assert_eq((_node(hud, "PromptLabel") as Label).text, "Parler")
	EventBus.interaction_available.emit("")
	assert_false(prompt.visible, '"" : plus rien')


func test_dialogue_hides_prompt_and_gauge() -> void:
	var hud := _hud()
	EventBus.interaction_available.emit("Parler")
	EventBus.charge_progress.emit(0.5)
	EventBus.dialogue_started.emit(&"librarian")
	assert_false(_node(hud, "Prompt").visible, "invite masquée pendant un dialogue")
	assert_false(_node(hud, "ChargeRow").visible, "jauge masquée pendant un dialogue")
	EventBus.dialogue_ended.emit(&"librarian")
	assert_true(_node(hud, "Prompt").visible)
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
	GameState.set_quest_state(&"pages", &"active")
	EventBus.player_health_changed.emit(6, 6)
	EventBus.charge_progress.emit(1.0)
	EventBus.arena_score_changed.emit(&"dunes", 1234)
	EventBus.wave_started.emit(&"dunes", 12, 27)
	EventBus.zone_entered.emit(&"dunes")
	EventBus.interaction_available.emit("Affronter les Timeres")
	SaveManager.saved.emit("user://x.json")
	hud.toggle_perf_overlay()
	await wait_process_frames(2)
	var area := hud.get_global_rect()
	var top_right := Rect2(area.end.x - 200.0, area.position.y, 200.0, 100.0)
	var bottom := Rect2(area.position.x, area.end.y - 200.0, area.size.x, 200.0)
	# Écrans modaux enfants du HUD (menu pause, journal de quêtes du Lot Q) : ils prennent la
	# souris quand ils sont ouverts.
	var overlays: Array[Node] = [
		_node(hud, "DamageFlash"),
		_node(hud, "DeathFade"),
		_node(hud, "PauseMenu"),
		_node(hud, "Journal"),
	]
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
