extends Node
## Atmosphere (E9) : la lumière et le temps (PLAN.md section 3 ; docs/REFONTE.md, lot E9).
## Propriétaire : E9.
##
## Le moment de la journée et le temps qu'il fait sont tenus par GameState (moment, weather :
## sauvegardés ; EventBus.atmosphere_changed quand ils changent). Atmosphere en fait la lumière
## de la carte courante :
## - préréglage effectif (resolve()) : le light_preset de la carte s'il est rempli (un moment,
##   « interieur », ou tout préréglage de data/lighting/) ; sinon « interieur » pour une carte
##   intérieure (Map.interior), sinon celui du moment. « interieur » mêle les préréglages
##   interieur (fenêtres) et interieur_nuit (lampes, cristaux) selon la nuit du dehors, et prend
##   la couleur de son soleil ; le temps (HD2DWeather : pluie, averse) le modifie ensuite, sans
##   pluie dedans ;
## - transition douce (transition_time s, ou la durée demandée) d'un préréglage à l'autre quand
##   le moment ou le temps changent ; immédiate au chargement d'une partie (game_loaded) et à
##   l'arrivée dans une carte (map_entered, sous le fondu au noir) ;
## - pose (HD2DLightTargets, AtmosphereRig) : environnement, ciel, soleil ou lune, mer de
##   nuages, lanternes, lueur des fenêtres et des cristaux, images de nuit, sol mouillé, lumière
##   magique du joueur, pluie ; étalonnage et flou de profondeur du post-traitement de la caméra
##   courante (CameraRig/PostFX/Screen).
## La carte courante est WorldManager.current_map_node() : celle que WorldManager a posée, ou la
## première carte de l'arbre (démonstration, capture d'une carte seule) ; une carte qui entre
## dans l'arbre est habillée à l'image suivante (dress), à son map_entered tout de suite.
##
## Raccourcis de développement : ?moment=nuit&temps=pluie dans l'adresse de la page (Web) ou
## --moment=nuit --temps=pluie après « -- » (ailleurs), posés à chaque partie chargée ; F7
## (moment suivant) et F8 (temps suivant), Maj : sans transition, dans une version de débogage
## ou quand l'un de ces paramètres est donné (docs/web.md).
## L'ancien signal EventBus.day_phase_changed (M3) donne le moment correspondant
## (HD2DLighting.PHASE_MOMENTS).

## Un préréglage vient d'être posé en entier (fin de transition, arrivée, chargement).
signal preset_applied(preset_id: StringName)

## Durée par défaut d'une transition de lumière (s).
const DEFAULT_TRANSITION_TIME := 4.0
## Lumière du joueur : auto (la nuit dehors, selon le préréglage), on (toujours, par exemple
## pour une scène), off (jamais : Willem arrive sans lumière).
const LIGHT_AUTO := &"auto"
const LIGHT_ON := &"on"
const LIGHT_OFF := &"off"
## Paramètres de développement (adresse de la page ou arguments utilisateur).
const MOMENT_KEY := "moment"
const WEATHER_KEY := "temps"
const MOMENT_KEYCODE := KEY_F7
const WEATHER_KEYCODE := KEY_F8

## Durée des transitions demandées sans durée (s ; 0 : immédiates).
var transition_time: float = DEFAULT_TRANSITION_TIME
## Choix de la lumière du joueur (LIGHT_AUTO, LIGHT_ON, LIGHT_OFF).
var player_light_mode: StringName = LIGHT_AUTO:
	set(value):
		player_light_mode = value
		_apply()
## Touches de débogage F7 / F8 actives.
var debug_keys: bool = false
## Paramètres de développement lus au lancement (moment, temps).
var dev_parameters: Dictionary = {}

var _map: Node3D
var _targets: HD2DLightTargets
var _rig: AtmosphereRig
## Réglage posé (mélange en cours pendant une transition), départ et arrivée.
var _current: HD2DLighting
var _from: HD2DLighting
var _to: HD2DLighting
var _elapsed: float = 0.0
var _duration: float = 0.0
var _transitioning: bool = false
var _preset_id: StringName = &""
## Durée de la prochaine transition (set_moment…) ; < 0 : transition_time.
var _pending_duration: float = -1.0
## Plusieurs changements d'un coup (set_atmosphere) : une seule transition.
var _batching: bool = false
var _post: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	EventBus.atmosphere_changed.connect(_on_atmosphere_changed)
	EventBus.map_entered.connect(_on_map_entered)
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.day_phase_changed.connect(_on_day_phase_changed)
	dev_parameters = read_parameters()
	debug_keys = OS.is_debug_build() or not dev_parameters.is_empty()


func _process(delta: float) -> void:
	var map := WorldManager.current_map_node()
	if map != _valid_map():
		dress(map)
	if _transitioning:
		step(delta)
	elif _current != null:
		_apply_post_if_new_camera()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not debug_keys or key == null or not key.pressed or key.echo:
		return
	var duration := 0.0 if key.shift_pressed else -1.0
	if key.keycode == MOMENT_KEYCODE:
		set_moment(_next(GameState.MOMENTS, GameState.moment), duration)
		get_viewport().set_input_as_handled()
	elif key.keycode == WEATHER_KEYCODE:
		set_weather(_next(GameState.WEATHERS, GameState.weather), duration)
		get_viewport().set_input_as_handled()


# --- API --------------------------------------------------------------------------------------


## Change le moment de la journée (GameState.MOMENTS), en duration s (< 0 : transition_time ;
## 0 : tout de suite). Sans effet s'il est déjà celui-là.
func set_moment(moment_id: StringName, duration: float = -1.0) -> void:
	set_atmosphere(moment_id, GameState.weather, duration)


## Change le temps qu'il fait (GameState.WEATHERS), comme set_moment.
func set_weather(weather_id: StringName, duration: float = -1.0) -> void:
	set_atmosphere(GameState.moment, weather_id, duration)


## Change le moment et le temps d'un coup (une seule transition).
func set_atmosphere(
	moment_id: StringName, weather_id: StringName, duration: float = -1.0
) -> void:
	if moment_id == GameState.moment and weather_id == GameState.weather:
		return
	_pending_duration = duration
	_batching = true
	GameState.moment = moment_id
	GameState.weather = weather_id
	_batching = false
	_start_transition(_take_duration())


## Moment et temps courants (ceux de GameState).
func moment() -> StringName:
	return GameState.moment


func weather() -> StringName:
	return GameState.weather


## Identifiant du préréglage effectif de la carte courante (light_preset, interieur ou moment).
func preset_id() -> StringName:
	return _preset_id


## Réglage posé en ce moment (copie ; null sans carte).
func current() -> HD2DLighting:
	return _current.copy() if _current != null else null


## Vrai pendant une transition de lumière.
func is_transitioning() -> bool:
	return _transitioning


## Avancement de la transition en cours (0..1 ; 1 hors transition).
func transition_progress() -> float:
	if not _transitioning or _duration <= 0.0:
		return 1.0
	return clampf(_elapsed / _duration, 0.0, 1.0)


## Part de la lumière du joueur (0 : éteinte, 1 : pleine), selon le réglage posé et
## player_light_mode.
func player_light_amount() -> float:
	if _current == null or player_light_mode == LIGHT_OFF:
		return 0.0
	if player_light_mode == LIGHT_ON:
		return 1.0
	return _current.player_light


## Vrai si la lumière du joueur est allumée.
func is_player_light_on() -> bool:
	return is_instance_valid(_rig) and _rig.light_amount() > 0.0


## Vrai s'il pleut sur la carte courante (gouttes affichées).
func is_raining() -> bool:
	return is_instance_valid(_rig) and _rig.is_raining()


## Teinte des planches des personnages sous le réglage posé (blanc : le couchant ; la nuit,
## bleutée et plus sombre). CharacterVisual ne la lit pas encore (docs/CONTRACT_REQUESTS.md).
func sprite_tint() -> Color:
	return _current.sprite_tint if _current != null else Color.WHITE


## Le rig de la carte courante (lumière du joueur, pluie ; null sans carte).
func rig() -> AtmosphereRig:
	return _rig if is_instance_valid(_rig) else null


## Ce que la lumière règle dans la carte courante (null sans carte).
func targets() -> HD2DLightTargets:
	return _targets


## Préréglage effectif de la carte map (null : la carte courante) pour moment et weather (par
## défaut ceux de GameState) : nouvelle ressource.
func resolve(map: Node = null, moment_id: StringName = &"", weather_id: StringName = &"") -> HD2DLighting:
	if map == null:
		map = _valid_map()
	if moment_id.is_empty():
		moment_id = GameState.moment
	if weather_id.is_empty():
		weather_id = GameState.weather
	var outdoor := _preset_or_default(moment_id)
	var id := effective_preset_id(map, moment_id)
	var indoors := id == HD2DLighting.INTERIOR
	var base: HD2DLighting
	if indoors:
		base = interior_for(outdoor)
	elif id == moment_id:
		base = outdoor
	else:
		base = _preset_or_default(id)
	var map_inside := map is Map and (map as Map).interior
	var weather_preset := HD2DWeather.preset(weather_id)
	if weather_preset == null:
		return base.copy()
	return weather_preset.applied_to(base, not (indoors or map_inside))


## Identifiant du préréglage de map : son light_preset s'il est rempli, sinon « interieur » pour
## une carte intérieure, sinon le moment.
static func effective_preset_id(map: Node, moment_id: StringName) -> StringName:
	var as_map := map as Map
	if as_map != null and not as_map.light_preset.is_empty():
		return as_map.light_preset
	if as_map != null and as_map.interior:
		return HD2DLighting.INTERIOR
	return moment_id


## Lumière d'un intérieur sous le moment du dehors (outdoor) : interieur (jour, les fenêtres)
## mêlé à interieur_nuit (lampes et cristaux) selon sa part de nuit, la lumière des fenêtres
## teintée par son soleil ; jamais de lumière du joueur.
static func interior_for(outdoor: HD2DLighting) -> HD2DLighting:
	var day := HD2DLighting.preset(HD2DLighting.INTERIOR)
	var night := HD2DLighting.preset(HD2DLighting.INTERIOR_NIGHT)
	if day == null:
		return outdoor.copy()
	var result := day.blended(night, outdoor.night_amount) if night != null else day.copy()
	result.sun_color = result.sun_color * outdoor.sun_color.lerp(Color.WHITE, 0.35)
	result.night_amount = outdoor.night_amount
	result.player_light = 0.0
	return result


## Habille map (rig, relevé) et y pose tout de suite le réglage effectif (null : oublie la
## carte).
func dress(map: Node3D) -> void:
	_map = map
	_transitioning = false
	if map == null or not map.is_inside_tree():
		_map = null
		_targets = null
		_rig = null
		return
	_rig = AtmosphereRig.dress(map)
	_targets = HD2DLightTargets.scan(map)
	snap()


## Pose tout de suite le réglage effectif (sans transition).
func snap() -> void:
	_transitioning = false
	if _valid_map() == null:
		return
	_current = resolve()
	_preset_id = effective_preset_id(_map, GameState.moment)
	_apply()
	preset_applied.emit(_preset_id)


## Avance la transition en cours de delta s (appelé à chaque image ; les tests l'appellent).
func step(delta: float) -> void:
	if not _transitioning:
		return
	_elapsed += delta
	var t := 1.0 if _duration <= 0.0 else clampf(_elapsed / _duration, 0.0, 1.0)
	if t >= 1.0:
		_transitioning = false
		_current = _to.copy()
		_apply()
		preset_applied.emit(_preset_id)
		return
	HD2DLighting.blend_into(_current, _from, _to, smoothstep(0.0, 1.0, t))
	_apply(_from.sky_image(), smoothstep(0.0, 1.0, t), _from.clouds_texture)


## Paramètres de développement (moment, temps) de l'adresse de la page (Web) ou des arguments
## utilisateur.
static func read_parameters() -> Dictionary:
	var pairs: PackedStringArray = []
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		pairs = str(search if search != null else "").trim_prefix("?").split("&", false)
	else:
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--"):
				pairs.append(argument.trim_prefix("--"))
	return parse_pairs(pairs)


## Garde moment=<id> et temps=<id> valides parmi des « clé=valeur ».
static func parse_pairs(pairs: PackedStringArray) -> Dictionary:
	var result := {}
	for pair: String in pairs:
		var key := pair.get_slice("=", 0).strip_edges()
		var value := StringName(pair.get_slice("=", 1).uri_decode().strip_edges())
		if key == MOMENT_KEY and value in GameState.MOMENTS:
			result[MOMENT_KEY] = value
		elif key == WEATHER_KEY and value in GameState.WEATHERS:
			result[WEATHER_KEY] = value
	return result


# --- Interne ----------------------------------------------------------------------------------


func _start_transition(duration: float) -> void:
	if _valid_map() == null or _current == null:
		return
	var target := resolve()
	_preset_id = effective_preset_id(_map, GameState.moment)
	if duration <= 0.0:
		_current = target
		_transitioning = false
		_apply()
		preset_applied.emit(_preset_id)
		return
	_from = _current.copy()
	_to = target
	_elapsed = 0.0
	_duration = duration
	_transitioning = true


## La carte habillée, si elle existe encore (null sinon).
func _valid_map() -> Node3D:
	if _map != null and not is_instance_valid(_map):
		_map = null
	return _map


func _take_duration() -> float:
	var duration := _pending_duration if _pending_duration >= 0.0 else transition_time
	_pending_duration = -1.0
	return duration


func _apply(sky_from: Texture2D = null, mix: float = 1.0, clouds_from: Texture2D = null) -> void:
	if _current == null or _targets == null:
		return
	_targets.apply(_current, sky_from, mix, clouds_from)
	if is_instance_valid(_rig):
		_rig.apply(_current, player_light_amount())
	_post = null
	_apply_post_if_new_camera()


## Pose l'étalonnage sur le post-traitement de la caméra courante (à chaque pose, et quand la
## caméra courante change).
func _apply_post_if_new_camera() -> void:
	var viewport := get_viewport()
	var material := HD2DLighting.post_material(viewport.get_camera_3d()) if viewport else null
	if material == _post:
		return
	_post = material
	if _current != null:
		_current.apply_post(material)


func _preset_or_default(id: StringName) -> HD2DLighting:
	var found := HD2DLighting.preset(id)
	if found == null:
		push_warning("Atmosphere : préréglage inconnu %s, le couchant à la place" % id)
		found = HD2DLighting.preset(HD2DLighting.DEFAULT_PRESET)
	return found if found != null else HD2DLighting.new()


static func _next(ids: Array[StringName], current_id: StringName) -> StringName:
	return ids[(ids.find(current_id) + 1) % ids.size()]


func _on_atmosphere_changed(_moment: StringName, _weather: StringName) -> void:
	if _batching:
		return
	_start_transition(_take_duration())


## Arrivée dans une carte (sous le fondu au noir) : habillée et éclairée tout de suite.
func _on_map_entered(_map_id: StringName) -> void:
	dress(WorldManager.current_map_node())


## Partie chargée : les paramètres de développement, puis la lumière tout de suite.
func _on_game_loaded() -> void:
	var moment_id: StringName = dev_parameters.get(MOMENT_KEY, GameState.moment)
	var weather_id: StringName = dev_parameters.get(WEATHER_KEY, GameState.weather)
	set_atmosphere(moment_id, weather_id, 0.0)
	snap()


func _on_day_phase_changed(phase: StringName) -> void:
	if HD2DLighting.PHASE_MOMENTS.has(phase):
		set_moment(HD2DLighting.PHASE_MOMENTS[phase])
