class_name GameVision
extends RefCounted
## (E8b) Les effets de la vision accélérée (docs/lore/ACTE1.md, 3.3 ; ligne E9 de la section 6) :
## l'image pâlit, le monde ralentit autour de Chtholly, l'écran blanchit. Propriétaire : E8.
##
## - Pâleur et écran blanc : les uniformes pale_amount, pale_center, pale_radius et flash_color du
##   post-traitement de la caméra du joueur (CameraRig/PostFX/Screen, src/player/post_fx.gdshader),
##   nuls par défaut et qu'Atmosphere ne touche pas. begin() retient leurs valeurs, end() les rend :
##   le post-traitement revient à l'état d'avant.
## - Ralenti : les visuels pris (slow) ne s'animent plus d'eux-mêmes ; tick(delta) les avance de
##   delta × time_scale ; end() leur rend leur horloge. Leurs déplacements, c'est le jeu qui les
##   mène (le duel avance Willem à son temps ralenti).
## Sans caméra du joueur (capture d'une carte seule, test sans post-traitement), les réglages sont
## retenus (pale(), flash()) sans rien poser.

const UNIFORMS: Array[StringName] = [&"pale_amount", &"pale_center", &"pale_radius", &"flash_color"]

## Part du temps des visuels ralentis (1 : temps normal).
var time_scale: float = 1.0

var _material: ShaderMaterial = null
var _saved: Dictionary = {}
var _pale: float = 0.0
var _flash: Color = Color(1.0, 1.0, 1.0, 0.0)
var _slowed: Array[CharacterVisual] = []
var _active: bool = false


## Le matériau du post-traitement de la caméra de player (null sans caméra ni post-traitement).
static func post_material(player: Node) -> ShaderMaterial:
	if player == null or not is_instance_valid(player):
		return null
	var screen := player.get_node_or_null(^"CameraRig/PostFX/Screen") as CanvasItem
	return screen.material as ShaderMaterial if screen != null else null


## Commence : retient l'état du post-traitement de material (null : aucun) pour le rendre à end().
func begin(material: ShaderMaterial) -> void:
	if _active:
		return
	_active = true
	_material = material
	_saved.clear()
	if _material != null:
		for key: StringName in UNIFORMS:
			_saved[key] = _material.get_shader_parameter(key)


## Vrai entre begin() et end().
func is_active() -> bool:
	return _active


## Pâleur : amount (0..1) de désaturation, sauf dans un disque de radius hauteurs d'écran autour de
## center (coordonnées d'écran 0..1 ; radius 0 : toute l'image).
func set_pale(amount: float, center: Vector2 = Vector2(0.5, 0.5), radius: float = 0.0) -> void:
	_pale = clampf(amount, 0.0, 1.0)
	if _material == null or not _active:
		return
	_material.set_shader_parameter(&"pale_amount", _pale)
	_material.set_shader_parameter(&"pale_center", center)
	_material.set_shader_parameter(&"pale_radius", maxf(radius, 0.0))


## Écran blanc (ou d'une autre couleur) : color, force amount (0..1).
func set_flash(amount: float, color: Color = Color.WHITE) -> void:
	_flash = Color(color.r, color.g, color.b, clampf(amount, 0.0, 1.0))
	if _material != null and _active:
		_material.set_shader_parameter(&"flash_color", _flash)


## Pâleur posée (0..1).
func pale() -> float:
	return _pale


## Force de l'écran blanc posée (0..1).
func flash() -> float:
	return _flash.a


## Ralentit les visuels donnés (ils ne s'avancent plus d'eux-mêmes : tick les avance).
func slow(visuals: Array[CharacterVisual], scale: float) -> void:
	time_scale = clampf(scale, 0.0, 1.0)
	for visual: CharacterVisual in visuals:
		if is_instance_valid(visual) and not _slowed.has(visual):
			_slowed.append(visual)
			visual.set_process(false)


## Rend leur horloge aux visuels ralentis.
func unslow() -> void:
	for visual: CharacterVisual in _slowed:
		if is_instance_valid(visual):
			visual.set_process(true)
	_slowed.clear()
	time_scale = 1.0


## Visuels ralentis.
func slowed() -> Array[CharacterVisual]:
	return _slowed


## Avance les visuels ralentis de delta × time_scale.
func tick(delta: float) -> void:
	for visual: CharacterVisual in _slowed:
		if is_instance_valid(visual):
			visual.advance(delta * time_scale)


## Rend tout : le post-traitement comme à begin(), l'horloge des visuels.
func end() -> void:
	unslow()
	if not _active:
		return
	_active = false
	if _material != null:
		for key: StringName in _saved:
			_material.set_shader_parameter(key, _saved[key])
	_material = null
	_saved.clear()
	_pale = 0.0
	_flash = Color(1.0, 1.0, 1.0, 0.0)
