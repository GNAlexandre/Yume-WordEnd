extends GutTest
## (QC2) Le nom de la carte (UI/MapFade) ne s'affiche qu'en jeu libre (docs/QUALITE.md, QC-41) :
## annoncé pendant une scène, un jeu (signes cachés) ou une conversation, il attend leur fin ;
## affiché quand l'une d'elles commence, il s'efface aussitôt et ne revient pas.

const MAP_FADE := preload("res://src/ui/map_fade.tscn")
const REASON := &"test_qc2"

var _fade: Control


func before_each() -> void:
	InteractSign.suppress(REASON, false)
	_fade = MAP_FADE.instantiate()
	add_child_autofree(_fade)


func after_each() -> void:
	InteractSign.suppress(REASON, false)


func _title() -> String:
	return str(_fade.call(&"title_text"))


func test_name_shows_in_free_play() -> void:
	assert_true(_fade.call(&"is_free_play"), "rien ne se joue")
	EventBus.map_entered.emit(&"sentier")
	await wait_process_frames(2)
	assert_eq(_title(), WorldManager.map_display_name(&"sentier"), "en jeu libre, le nom paraît")


func test_name_waits_for_the_end_of_a_game() -> void:
	InteractSign.suppress(REASON, true)
	EventBus.map_entered.emit(&"sentier")
	await wait_process_frames(3)
	assert_eq(_title(), "", "pendant un jeu ou une scène : rien")
	assert_eq(
		str(_fade.call(&"pending_title")), WorldManager.map_display_name(&"sentier"), "il attend"
	)
	InteractSign.suppress(REASON, false)
	await wait_process_frames(2)
	assert_eq(_title(), WorldManager.map_display_name(&"sentier"), "la scène finie, il paraît")


func test_name_waits_for_the_end_of_a_conversation() -> void:
	EventBus.dialogue_started.emit(&"pannibal")
	EventBus.map_entered.emit(&"sentier")
	await wait_process_frames(3)
	assert_eq(_title(), "", "pendant une conversation : rien")
	EventBus.dialogue_ended.emit(&"pannibal")
	await wait_process_frames(2)
	assert_ne(_title(), "", "la conversation finie, il paraît")


func test_shown_name_is_skipped_when_a_scene_starts() -> void:
	EventBus.map_entered.emit(&"sentier")
	await wait_process_frames(2)
	assert_ne(_title(), "", "affiché")
	InteractSign.suppress(REASON, true)
	await wait_process_frames(2)
	assert_eq(_title(), "", "une scène commence : il s'efface")
	InteractSign.suppress(REASON, false)
	await wait_process_frames(3)
	assert_eq(_title(), "", "et ne revient pas")
