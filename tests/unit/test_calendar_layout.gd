extends GutTest
## (QC2) La page du calendrier (src/ui/calendar.tscn) n'a plus de bas vide (docs/QUALITE.md,
## QC-42) : sous la grille et les lignes écrites, un filet d'or, le jour courant et le compte des
## jours jusqu'au départ, puis l'indice ; la page se resserre sur son contenu (au plus 640 px), les
## lignes défilent au-delà de 220 px. Dans un écran de 1280 × 720 (SubViewport).

const CALENDAR := preload("res://src/ui/calendar.tscn")

var _screen: SubViewport
var _calendar: Control


func before_each() -> void:
	GameState.reset()
	# L'île du récit (StoryDirector : l'île de la carte de départ, au chargement d'une partie).
	GameState.day = 1
	EventBus.game_loaded.emit()
	_screen = SubViewport.new()
	_screen.size = Vector2i(1280, 720)
	_screen.disable_3d = true
	add_child_autofree(_screen)
	var frame := Control.new()
	frame.size = Vector2(1280, 720)
	_screen.add_child(frame)
	_calendar = CALENDAR.instantiate()
	frame.add_child(_calendar)


func after_each() -> void:
	GameState.reset()


func _refresh() -> void:
	_calendar.call(&"refresh")
	_calendar.show()
	for _i in 3:
		await get_tree().process_frame


func _label(unique_name: String) -> Label:
	return _calendar.get_node("%" + unique_name) as Label


func test_day_two_page_is_tight_and_says_today_and_departure() -> void:
	GameState.day = 2
	GameState.write_calendar(1)
	await _refresh()
	var departure := StoryDirector.departure_day()
	assert_gt(departure, 2, "l'acte a un jour de départ")
	assert_string_contains(_label("TodayLabel").text, "2", "le jour courant")
	assert_string_contains(
		_label("DepartureLabel").text, str(departure - 2), "le compte jusqu'au départ"
	)
	var page: Rect2 = _calendar.call(&"page_rect")
	assert_lt(page.size.y, 600.0, "une ligne écrite : la page se resserre (%s)" % page)
	assert_almost_eq(page.get_center().y, 360.0, 2.0, "centrée")
	# Le bas de la page : l'indice ou le jour courant, à moins de 60 px du bord.
	var bottom := _label("TodayLabel").get_global_rect().end.y
	if _label("CalendarHint").visible:
		bottom = _label("CalendarHint").get_global_rect().end.y
	assert_lt(page.end.y - bottom, 60.0, "pas de bas de page vide")


func test_departure_countdown_words() -> void:
	var departure := StoryDirector.departure_day()
	GameState.day = departure - 1
	assert_eq(_calendar.call(&"departure_text"), "Départ demain")
	GameState.day = departure
	assert_eq(_calendar.call(&"departure_text"), "C'est le jour du départ")
	GameState.day = departure + 1
	assert_eq(_calendar.call(&"departure_text"), "", "après le départ : rien")


func test_many_lines_scroll_inside_a_bounded_page() -> void:
	var departure := StoryDirector.departure_day()
	GameState.day = departure
	for day: int in range(1, departure):
		GameState.write_calendar(day)
	await _refresh()
	var page: Rect2 = _calendar.call(&"page_rect")
	assert_lte(page.size.y, 640.5, "la page reste dans l'écran (%s)" % page)
	assert_gte(page.position.y, 0.0, "dans l'écran")
