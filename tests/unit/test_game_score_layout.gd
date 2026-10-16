extends GutTest
## (QC2) Le bandeau d'un jeu (GameScore : duel, bâton, embuscade, ballon) ne couvre jamais les
## cœurs ni la jauge de charge du HUD (HUD.top_left_rect()) : centré s'il y a la place, poussé à
## droite du coin sinon, replié sur plusieurs lignes quand la largeur manque (docs/QUALITE.md,
## QC-39). Le tout dans un écran de 1280 × 720 (SubViewport).

const HUD := preload("res://src/ui/hud.tscn")
const SCORE := preload("res://src/games/game_score.gd")
const LONG_TEXT := "Willem esquive tout. Tiens la charge (clic droit, L2) : le venenum."

var _screen: SubViewport
var _hud: Control
var _score: GameScore


func before_each() -> void:
	GameState.reset()
	_screen = SubViewport.new()
	_screen.size = Vector2i(1280, 720)
	_screen.disable_3d = true
	add_child_autofree(_screen)
	_hud = HUD.instantiate()
	_screen.add_child(_hud)
	_score = SCORE.new()
	_screen.add_child(_score)


func after_each() -> void:
	GameState.reset()


func _settle() -> void:
	for _i in 3:
		await get_tree().process_frame
	_score.fit()


func _corner() -> Rect2:
	return _hud.call(&"top_left_rect")


func test_short_text_stays_centered() -> void:
	_score.set_text("Contres 0/3  ·  0:41")
	await _settle()
	var rect := _score.panel_rect()
	assert_almost_eq(rect.get_center().x, 640.0, 2.0, "centré en haut")
	assert_false(rect.intersects(_corner()), "loin des cœurs")


func test_long_text_with_charge_gauge_moves_right_of_the_corner() -> void:
	EventBus.charge_progress.emit(1.0)
	_score.set_text(LONG_TEXT)
	await _settle()
	var corner := _corner()
	assert_gt(corner.size.x, 300.0, "cœurs et jauge « Onde prête ! » : le coin s'élargit")
	var rect := _score.panel_rect()
	assert_false(
		rect.intersects(corner),
		"le bandeau ne couvre ni les cœurs ni la jauge : %s / %s" % [rect, corner]
	)
	assert_gte(rect.position.x, corner.end.x, "à droite du coin")
	assert_lte(rect.end.x, 1280.0 - SCORE.EDGE + 0.5, "dans l'écran")


func test_many_hearts_wrap_the_text_instead_of_covering_them() -> void:
	EventBus.player_health_changed.emit(24, 24)
	_score.set_text(LONG_TEXT)
	await _settle()
	var corner := _corner()
	assert_gt(corner.end.x, 800.0, "24 cœurs : un long rang")
	var rect := _score.panel_rect()
	assert_false(
		rect.intersects(corner), "le bandeau ne couvre aucun cœur : %s / %s" % [rect, corner]
	)
	assert_lte(rect.end.x, 1280.0 - SCORE.EDGE + 0.5, "dans l'écran")
	assert_gt(rect.size.y, 40.0, "replié sur plusieurs lignes")
	assert_eq(_score.shown_text(), LONG_TEXT, "le texte reste entier")
