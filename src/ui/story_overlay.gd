extends Control
## (E6) Le voile des scènes du récit : enfant StoryOverlay du HUD (groupe GROUP), sous la boîte de
## dialogue (une réplique peut se lire sur le noir). Propriétaire : E6.
##
## - Fondu (Fade) au noir ou au blanc (souvenir, éblouissement : ACTE1.md, 0.2), et retour ;
## - carton (Card) : un texte centré qui paraît, reste, puis s'efface (titre de l'acte, résumé
##   d'une scène dont la carte n'existe pas encore) ;
## - invite pour passer une séquence déjà vue (Skip, en bas à droite).
## Rien n'y est une coroutine (le HUD peut être libéré au milieu d'une scène) : fade_to et
## show_card lancent leur animation, is_busy() dit si elle dure ; StoryDirector.wait_overlay
## l'attend. Jamais de clic pris (mouse_filter IGNORE).

const GROUP := &"story_overlay"
const BLACK := StoryData.BLACK
const WHITE := StoryData.WHITE
## Fondu d'un carton (s, à l'entrée comme à la sortie).
const CARD_FADE := 0.5

var _fade_tween: Tween
var _card_tween: Tween

@onready var _fade: ColorRect = %Fade
@onready var _card: Label = %Card
@onready var _skip: Label = %Skip


func _ready() -> void:
	add_to_group(GROUP)
	set_fade(BLACK, 0.0)
	_card.hide()
	_skip.hide()


## Pose le voile tout de suite (couleur, opacité 0..1).
func set_fade(color: Color, alpha: float) -> void:
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null
	_fade.color = Color(color, clampf(alpha, 0.0, 1.0))
	_fade.visible = alpha > 0.0


## Fondu vers color à l'opacité alpha en time s (0 : tout de suite) ; is_busy() pendant.
func fade_to(color: Color, alpha: float, time: float) -> void:
	if time <= 0.0 or not is_inside_tree():
		set_fade(color, alpha)
		return
	if _fade.color.a <= 0.0:
		_fade.color = Color(color, 0.0)
	_fade.visible = true
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, ^"color", Color(color, clampf(alpha, 0.0, 1.0)), time)
	_fade_tween.tween_callback(_hide_clear_fade)


## Vrai pendant un fondu ou un carton.
func is_busy() -> bool:
	return _running(_fade_tween) or _running(_card_tween)


## Opacité du voile (0..1) et sa couleur.
func fade_alpha() -> float:
	return _fade.color.a if _fade.visible else 0.0


func fade_color() -> Color:
	return Color(_fade.color, 1.0)


## Carton : text paraît (CARD_FADE s), reste time s, puis s'efface ; is_busy() pendant.
func show_card(text: String, time: float) -> void:
	if _card_tween != null:
		_card_tween.kill()
	_card.text = text
	_card.modulate.a = 0.0
	_card.show()
	if not is_inside_tree():
		return
	_card_tween = create_tween()
	_card_tween.tween_property(_card, ^"modulate:a", 1.0, CARD_FADE)
	_card_tween.tween_interval(maxf(time, 0.0))
	_card_tween.tween_property(_card, ^"modulate:a", 0.0, CARD_FADE)
	_card_tween.tween_callback(_card.hide)


## Retire le carton tout de suite.
func hide_card() -> void:
	if _card_tween != null:
		_card_tween.kill()
		_card_tween = null
	_card.hide()


## Texte du carton affiché ("" : aucun).
func card_text() -> String:
	return _card.text if _card.visible else ""


## Invite pour passer la séquence ("" : cachée).
func set_skip_text(text: String) -> void:
	_skip.text = text
	_skip.visible = not text.is_empty()


func skip_text() -> String:
	return _skip.text if _skip.visible else ""


func _hide_clear_fade() -> void:
	_fade.visible = _fade.color.a > 0.0


static func _running(tween: Tween) -> bool:
	return tween != null and tween.is_valid() and tween.is_running()
