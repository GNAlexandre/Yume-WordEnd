extends Control
## (U1) Signes d'interaction du HUD (nœud HUD/InteractSigns), à la place de l'ancienne invite
## « E / A : Parler ». Propriétaire : U1. API partagée et moyens de cacher : InteractSign.
##
## - Au-dessus de la cible du joueur (Player.current_interactable()), un signe plein à taille
##   fixe à l'écran : bulle « … » (parler), étincelle (examiner), main (prendre), porte (entrer),
##   images assets/hd2d/fx/sign_<genre>.png ; les autres cibles proches (à moins de
##   PALE_RANGE m du joueur) portent un signe pâle, PALE_MAX au plus. Un signe entre en fondu
##   en montant de RISE_PX, respire doucement, grossit un peu quand le joueur s'approche ; à
##   l'appui de « interact », il fait un petit rebond (gardé le temps du rebond, même si le
##   dialogue s'ouvre).
## - Un PNJ qui devient la cible tourne la tête vers le joueur (Npc.look_toward) s'il est arrêté.
## - La touche (« E », ou « A » à la manette ; rien au toucher, le bouton tactile a son texte) :
##   un petit rappel en cercle doré à côté du signe pendant les KEY_HINT_SECONDS premières
##   secondes de jeu, après STILL_SECONDS d'arrêt devant la cible, ou toujours (réglage
##   InteractSign.always_show_key, menu Options de la pause).
## - Souris : la cible survolée prend un liseré doré à ses pieds et le curseur devient une main ;
##   un clic sur la cible du joueur vaut l'appui de « interact » (le clic, lu dans _input, n'arrive
##   pas au jeu : pas de coup d'épée). Le nœud laisse passer la souris (MOUSE_FILTER_IGNORE).
## - Rien pendant un dialogue, en présentation « bandeau » (scènes du récit) ni quand
##   InteractSign.is_suppressed() ; une cible cachée par InteractSign.set_hidden n'a pas de signe.
## Un seul nœud dessine tous les signes (une image par genre : quelques draw calls au plus).

enum Device { KEYBOARD, PAD, TOUCH }

const TouchButtonScript := preload("res://src/ui/touch_button.gd")
const PLAYER_GROUP := &"player"
const INTERACTABLE_GROUP := &"interactable"
const TEXTURES := {
	InteractSign.TALK: preload("res://assets/hd2d/fx/sign_talk.png"),
	InteractSign.EXAMINE: preload("res://assets/hd2d/fx/sign_examine.png"),
	InteractSign.TAKE: preload("res://assets/hd2d/fx/sign_take.png"),
	InteractSign.ENTER: preload("res://assets/hd2d/fx/sign_enter.png"),
}
## Côté du signe plein et du signe pâle à l'écran (px de l'interface 1280 × 720).
const SIGN_PX := 26.0
const PALE_PX := 19.0
## Opacité d'un signe pâle ; nombre de signes pâles au plus.
const PALE_ALPHA := 0.45
const PALE_MAX := 3
## Distance (m) au joueur des cibles aux signes pâles : ce qu'on pourrait faire à deux pas.
const PALE_RANGE := 3.5
## Montée à l'apparition (px) et sa durée (s) ; vitesse des fondus (opacité par s).
const RISE_PX := 6.0
const RISE_TIME := 0.25
const FADE_SPEED := 5.0
## Grossissement du signe plein quand le joueur est tout près (part de sa taille), et la
## distance (m) où il commence.
const NEAR_GROW := 0.15
const NEAR_FROM := 1.6
## Rebond à l'appui (s) et son ampleur.
const BOUNCE_TIME := 0.24
const BOUNCE_SCALE := 0.35
## Rappel de la touche : premières secondes de jeu, arrêt devant la cible (s).
const KEY_HINT_SECONDS := 180.0
const STILL_SECONDS := 3.0
## Vitesse sous laquelle le joueur est arrêté (m/s).
const STILL_SPEED := 0.2
## Distance (m) au joueur des cibles qu'on peut survoler à la souris.
const HOVER_RANGE := 14.0
## Écart (px) quand le PNJ a déjà un marqueur ou une bulle au-dessus de la tête.
const MARKER_SHIFT := 24.0
## Hauteur par défaut d'un signe au-dessus d'une cible sans forme connue (m) ; marge au-dessus
## du haut de sa forme ou de la tête d'un PNJ (m).
const DEFAULT_HEIGHT := 1.0
const TOP_MARGIN := 0.3

## Secondes de jeu (hors dialogue et pause) depuis le lancement : le rappel de la touche.
static var played_seconds: float = 0.0

## Signes affichés : id de la cible → {node, kind, alpha, full, age}.
var _signs: Dictionary[int, Dictionary] = {}
var _full: Node3D
var _still: float = 0.0
var _in_dialogue: bool = false
var _bounce_left: float = 0.0
var _bounce_target: Node3D
var _hovered: Node3D
var _click_rect: Rect2 = Rect2()
var _pressing: bool = false
var _device: Device = Device.KEYBOARD
var _time: float = 0.0
var _heights: Dictionary[int, float] = {}
var _hand_cursor: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)


func _exit_tree() -> void:
	_set_hand_cursor(false)
	if _pressing:
		TouchButtonScript.send_action(&"interact", false)
		_pressing = false


func _process(delta: float) -> void:
	_time += delta
	_bounce_left = maxf(0.0, _bounce_left - delta)
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	var masked := signs_hidden()
	if not _in_dialogue:
		played_seconds += delta
	var full := _pick_full(player) if not masked else null
	if _bounce_left > 0.0 and is_instance_valid(_bounce_target):
		full = _bounce_target
	if full != _full:
		_still = 0.0
		_on_full_changed(full, player)
	_full = full
	if full != null and _is_still(player):
		_still += delta
	else:
		_still = 0.0
	var wanted: Dictionary[int, Dictionary] = {}
	if full != null:
		wanted[full.get_instance_id()] = {"node": full, "full": 1.0}
	if not masked:
		for pale: Node3D in _pick_pales(player, full):
			wanted[pale.get_instance_id()] = {"node": pale, "full": 0.0}
	_update_signs(wanted, delta)
	_update_hover(player, masked)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if (
		event is InputEventJoypadButton
		or (
			event is InputEventJoypadMotion
			and absf((event as InputEventJoypadMotion).axis_value) > 0.5
		)
	):
		_device = Device.PAD
	elif event is InputEventScreenTouch:
		_device = Device.TOUCH
	elif event is InputEventKey:
		_device = Device.KEYBOARD
	elif event is InputEventMouse and event.device != InputEvent.DEVICE_ID_EMULATION:
		_device = Device.KEYBOARD
	if event.is_action_pressed(&"interact") and not event.is_echo() and _full != null:
		bounce()
	_read_click(event)


## Clic gauche sur la cible du joueur (rectangle survolé) : appui de « interact », consommé.
func _read_click(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var point := _to_local(click.position)
	if click.pressed and _full != null and _click_rect.has_area() and _click_rect.has_point(point):
		_pressing = true
		TouchButtonScript.send_action(&"interact", true)
		bounce()
		get_viewport().set_input_as_handled()
	elif not click.pressed and _pressing:
		_pressing = false
		TouchButtonScript.send_action(&"interact", false)
		get_viewport().set_input_as_handled()


## true si aucun signe ne doit s'afficher (dialogue, bandeau, InteractSign.suppress).
func signs_hidden() -> bool:
	return (
		_in_dialogue
		or InteractSign.is_suppressed()
		or DialogueBox.presentation() == DialogueBox.PRESENTATION_BANDEAU
	)


## Cible au signe plein (null : aucune).
func full_target() -> Node3D:
	return _full if is_instance_valid(_full) else null


## Genre du signe plein (&"" : aucun).
func full_kind() -> StringName:
	return InteractSign.kind_of(full_target()) if full_target() != null else &""


## Cibles aux signes pâles voulus (en fondu compris).
func pale_targets() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for entry: Dictionary in _signs.values():
		var node := entry["node"] as Node3D
		if is_instance_valid(node) and node != _full and entry["wanted"]:
			result.append(node)
	return result


## true si le rappel de la touche est affiché à côté du signe plein.
func is_key_hint_shown() -> bool:
	if full_target() == null or _device == Device.TOUCH:
		return false
	return (
		InteractSign.always_show_key()
		or played_seconds < KEY_HINT_SECONDS
		or _still >= STILL_SECONDS
	)


## Texte du rappel de la touche : « E » (clavier et souris) ou « A » (manette).
func key_hint_text() -> String:
	return "A" if _device == Device.PAD else "E"


## Cible survolée par la souris (null : aucune).
func hovered_target() -> Node3D:
	return _hovered if is_instance_valid(_hovered) else null


## Petit rebond du signe plein (appui de « interact »).
func bounce() -> void:
	if _full == null:
		return
	_bounce_target = _full
	_bounce_left = BOUNCE_TIME


func _pick_full(player: Node3D) -> Node3D:
	if player == null or not player.has_method(&"current_interactable"):
		return null
	var target := player.call(&"current_interactable") as Node3D
	return target if _has_sign(target) else null


## Les autres cibles proches : du groupe « interactable », à moins de PALE_RANGE m du joueur.
func _pick_pales(player: Node3D, full: Node3D) -> Array[Node3D]:
	var result: Array[Node3D] = []
	if player == null:
		return result
	var found: Array[Node] = []
	if player.has_method(&"interactables_in_range"):
		# Joueur factice des tests (tests/stubs/u1_sign_player.gd).
		found.assign(player.call(&"interactables_in_range"))
	else:
		found = get_tree().get_nodes_in_group(INTERACTABLE_GROUP)
	var origin := player.global_position
	for node: Node in found:
		var target := Player.resolve_interactable(node)
		if target == null or target == full or result.has(target) or not _has_sign(target):
			continue
		var offset := target.global_position - origin
		if Vector2(offset.x, offset.z).length() <= PALE_RANGE and absf(offset.y) < PALE_RANGE:
			result.append(target)
	result.sort_custom(
		func(a: Node3D, b: Node3D) -> bool:
			return (
				a.global_position.distance_squared_to(origin)
				< b.global_position.distance_squared_to(origin)
			)
	)
	return result.slice(0, PALE_MAX)


func _has_sign(target: Node3D) -> bool:
	return (
		target != null
		and is_instance_valid(target)
		and target.is_inside_tree()
		and target.is_visible_in_tree()
		and not InteractSign.kind_of(target).is_empty()
	)


func _is_still(player: Node3D) -> bool:
	var body := player as CharacterBody3D
	return body != null and Vector2(body.velocity.x, body.velocity.z).length() < STILL_SPEED


func _on_full_changed(full: Node3D, player: Node3D) -> void:
	if full == null or player == null or not full.has_method(&"look_toward"):
		return
	var body := full as CharacterBody3D
	if body == null or body.velocity.length() < STILL_SPEED:
		full.call(&"look_toward", player.global_position)


func _update_signs(wanted: Dictionary[int, Dictionary], delta: float) -> void:
	for id: int in wanted:
		if not _signs.has(id):
			_signs[id] = {
				"node": wanted[id]["node"], "alpha": 0.0, "full": wanted[id]["full"], "age": 0.0
			}
	for id: int in _signs.keys():
		var entry := _signs[id]
		var node := entry["node"] as Node3D
		if not is_instance_valid(node) or not node.is_inside_tree():
			_signs.erase(id)
			continue
		var is_wanted := wanted.has(id)
		entry["wanted"] = is_wanted
		var goal_full: float = wanted[id]["full"] if is_wanted else entry["full"]
		var goal_alpha := (1.0 if goal_full > 0.5 else PALE_ALPHA) if is_wanted else 0.0
		entry["full"] = move_toward(entry["full"], goal_full, delta * FADE_SPEED)
		entry["alpha"] = move_toward(entry["alpha"], goal_alpha, delta * FADE_SPEED)
		entry["age"] = float(entry["age"]) + delta
		entry["kind"] = InteractSign.kind_of(node)
		if not is_wanted and entry["alpha"] <= 0.0:
			_signs.erase(id)


func _update_hover(player: Node3D, masked: bool) -> void:
	var hovered: Node3D = null
	_click_rect = Rect2()
	var camera := get_viewport().get_camera_3d()
	if not masked and player != null and camera != null and _device == Device.KEYBOARD:
		var mouse := get_local_mouse_position()
		var best := INF
		for node: Node in get_tree().get_nodes_in_group(INTERACTABLE_GROUP):
			var target := node as Node3D
			if target == null or not _has_sign(target):
				continue
			if target.global_position.distance_to(player.global_position) > HOVER_RANGE:
				continue
			var rect := _hover_rect(target, camera)
			if rect.has_area() and rect.has_point(mouse):
				var distance := rect.get_center().distance_to(mouse)
				if distance < best:
					best = distance
					hovered = target
					if target == _full:
						_click_rect = rect
	_hovered = hovered
	_set_hand_cursor(hovered != null)


## Rectangle à l'écran d'une cible : de ses pieds au haut de son signe.
func _hover_rect(target: Node3D, camera: Camera3D) -> Rect2:
	var feet_world := target.global_position
	var top_world := feet_world + Vector3.UP * _height_of(target)
	if camera.is_position_behind(feet_world) or camera.is_position_behind(top_world):
		return Rect2()
	var feet := _to_local(camera.unproject_position(feet_world))
	var top := _to_local(camera.unproject_position(top_world))
	var side := _to_local(camera.unproject_position(feet_world + camera.global_basis.x * 0.4))
	var half := maxf(22.0, absf(side.x - feet.x))
	return Rect2(feet.x - half, top.y, half * 2.0, maxf(feet.y - top.y, 24.0))


func _set_hand_cursor(on: bool) -> void:
	if on == _hand_cursor:
		return
	_hand_cursor = on
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if on else Input.CURSOR_ARROW)


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if hovered_target() != null:
		_draw_hover_ring(_hovered, camera)
	for entry: Dictionary in _signs.values():
		_draw_sign(entry, camera)


func _draw_sign(entry: Dictionary, camera: Camera3D) -> void:
	var node := entry["node"] as Node3D
	var texture: Texture2D = TEXTURES.get(entry.get("kind", &""))
	if texture == null or not is_instance_valid(node):
		return
	var world := node.global_position + Vector3.UP * _height_of(node)
	if camera.is_position_behind(world):
		return
	var full: float = entry["full"]
	var center := _to_local(camera.unproject_position(world))
	center.x += _marker_shift(node)
	var appear := clampf(float(entry["age"]) / RISE_TIME, 0.0, 1.0)
	center.y -= RISE_PX * ease(appear, 0.4)
	var side := lerpf(PALE_PX, SIGN_PX, full)
	var breath_period := maxf(UiStyle.seconds(&"breath_ms"), 0.1)
	var breath := 1.0 + 0.035 * sin(_time * TAU / breath_period)
	var grow := breath * (1.0 + NEAR_GROW * full * _closeness(node))
	if node == _bounce_target and _bounce_left > 0.0:
		grow *= 1.0 + BOUNCE_SCALE * sin(PI * (1.0 - _bounce_left / BOUNCE_TIME))
	side *= grow
	var rect := Rect2(center - Vector2(side * 0.5, side), Vector2(side, side))
	draw_texture_rect(texture, rect, false, Color(1, 1, 1, float(entry["alpha"])))
	if full > 0.5 and node == _full and is_key_hint_shown():
		_draw_key_hint(rect, float(entry["alpha"]))


func _draw_key_hint(sign_rect: Rect2, alpha: float) -> void:
	var radius := 9.0
	var center := Vector2(sign_rect.end.x + radius - 2.0, sign_rect.end.y - radius + 1.0)
	draw_circle(center, radius + 1.5, Color(UiStyle.color(&"ink"), 0.55 * alpha), true, -1.0, true)
	draw_circle(center, radius, Color(UiStyle.color(&"gold"), alpha), true, -1.0, true)
	var font := get_theme_font(&"font", &"KeyCapLabel")
	var font_size := 13
	var text := key_hint_text()
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	draw_string(
		font,
		Vector2(center.x - text_size.x * 0.5, baseline),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(UiStyle.color(&"ink"), alpha)
	)


## Liseré doré aux pieds de la cible survolée : un anneau doux couché sur le sol.
func _draw_hover_ring(target: Node3D, camera: Camera3D) -> void:
	var feet_world := target.global_position
	if camera.is_position_behind(feet_world):
		return
	var feet := _to_local(camera.unproject_position(feet_world))
	var side := _to_local(camera.unproject_position(feet_world + camera.global_basis.x * 0.45))
	var radius := maxf(absf(side.x - feet.x), 14.0)
	var gold := UiStyle.color(&"gold")
	var pulse := 0.8 + 0.2 * sin(_time * 4.0)
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, radius, Color(gold, 0.12 * pulse), true, -1.0, true)
	for i in 3:
		var width := 6.0 - i * 2.0
		draw_arc(
			Vector2.ZERO, radius, 0.0, TAU, 48, Color(gold, (0.12 + i * 0.25) * pulse), width, true
		)
	draw_set_transform(Vector2.ZERO)


## 0 loin de la cible, 1 tout près (signe plein qui grossit).
func _closeness(target: Node3D) -> float:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP) as Node3D
	if player == null:
		return 0.0
	var offset := target.global_position - player.global_position
	offset.y = 0.0
	return clampf(1.0 - offset.length() / NEAR_FROM, 0.0, 1.0)


## Hauteur du signe au-dessus de l'origine de la cible (m).
func _height_of(target: Node3D) -> float:
	if target.has_meta(InteractSign.HEIGHT_META):
		return float(target.get_meta(InteractSign.HEIGHT_META))
	var marker := target.get(&"quest_marker") as Node3D
	if marker != null:
		# Npc : son marqueur de quête est à la hauteur de sa tête + 0,5 m.
		return marker.position.y - 0.5 + TOP_MARGIN
	var id := target.get_instance_id()
	if not _heights.has(id):
		_heights[id] = _shape_top(target) + TOP_MARGIN
	return _heights[id]


## Haut des formes de collision de target (repère de target), DEFAULT_HEIGHT sans forme.
func _shape_top(target: Node3D) -> float:
	var top := -INF
	for child: Node in target.get_children():
		var shape_node := child as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			continue
		var box := shape_node.transform * shape_node.shape.get_debug_mesh().get_aabb()
		top = maxf(top, box.end.y)
	return top if top > -INF else DEFAULT_HEIGHT


## Décalage à droite quand le PNJ a déjà un marqueur de quête ou une bulle au-dessus de la tête.
func _marker_shift(target: Node3D) -> float:
	var marker := target.get(&"quest_marker") as Node3D
	var bubble := target.get(&"bubble") as Node3D
	if (marker != null and marker.visible) or (bubble != null and bubble.visible):
		return MARKER_SHIFT
	return 0.0


## Point de l'écran (viewport) dans le repère de ce nœud.
func _to_local(screen: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen


func _on_dialogue_started(_npc_id: StringName) -> void:
	_in_dialogue = true


func _on_dialogue_ended(_npc_id: StringName) -> void:
	_in_dialogue = false
