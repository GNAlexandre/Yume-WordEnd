class_name DepthFocus
extends RefCounted
## (RD) Mise au point HD-2D partagée (src/world/shaders/depth_focus.gdshaderinc) : la caméra du
## joueur (camera_rig.gd) pose à chaque image la profondeur du joueur et les flous du réglage de
## lumière (apply) ; ils sont recopiés sur chaque matériau inscrit (register) qui se floute
## lui-même : ombres des décors (DecorPanel.shadow_material), panneaux à alpha doux, décalques
## doux (GroundDecal), ciel qui dérive (SkyDrift). Ces matériaux sont dessinés après le flou de
## l'écran (post_fx_depth.gdshader), qui ne les voit pas. Références faibles : un matériau vit
## tant qu'un décor s'en sert. Une valeur n'est recopiée que si elle a changé.

## Uniformes de depth_focus.gdshaderinc, dans l'ordre.
const PARAMETERS: Array[StringName] = [
	&"focus_depth",
	&"focus_near",
	&"focus_far",
	&"near_full",
	&"near_blur_px",
	&"far_full",
	&"far_blur_px",
]
## Valeurs par défaut des uniformes (celles de depth_focus.gdshaderinc).
const DEFAULTS := {
	&"focus_depth": 21.0,
	&"focus_near": 1.8,
	&"focus_far": 4.0,
	&"near_full": 3.5,
	&"near_blur_px": 7.0,
	&"far_full": 16.0,
	&"far_blur_px": 5.0,
}
## Écart en deçà duquel une valeur n'est pas recopiée.
const EPSILON := 0.005

static var _materials: Array[WeakRef] = []
static var _values: Dictionary = {}


## Inscrit un matériau (sans effet s'il l'est déjà) et lui pose les valeurs courantes.
static func register(material: ShaderMaterial) -> void:
	if material == null:
		return
	for ref in _materials:
		if ref.get_ref() == material:
			return
	_materials.append(weakref(material))
	for key: StringName in _values:
		material.set_shader_parameter(key, _values[key])


## Vrai si le matériau est inscrit.
static func is_registered(material: ShaderMaterial) -> bool:
	for ref in _materials:
		if ref.get_ref() == material:
			return true
	return false


## Pose des valeurs (uniforme → nombre) sur tous les matériaux inscrits ; seules celles qui ont
## changé sont recopiées. Renvoie le nombre de valeurs recopiées.
static func apply(values: Dictionary) -> int:
	var changed: Dictionary = {}
	for key: StringName in values:
		var value := float(values[key])
		if not _values.has(key) or absf(float(_values[key]) - value) > EPSILON:
			changed[key] = value
			_values[key] = value
	if changed.is_empty():
		return 0
	for index in range(_materials.size() - 1, -1, -1):
		var material := _materials[index].get_ref() as ShaderMaterial
		if material == null:
			_materials.remove_at(index)
			continue
		for key: StringName in changed:
			material.set_shader_parameter(key, changed[key])
	return changed.size()


## Valeurs posées en dernier (uniforme → nombre).
static func current() -> Dictionary:
	return _values.duplicate()


## Jumeau sur le processeur de focus_radius (depth_focus.gdshaderinc) : flou (px à 720 px de haut)
## d'un point à la profondeur z (m) sous des valeurs (uniforme → nombre ; DEFAULTS pour le reste).
static func radius_px(z: float, values: Dictionary = {}) -> float:
	var v := DEFAULTS.duplicate()
	v.merge(values, true)
	var depth := float(v[&"focus_depth"])
	var near := (
		float(v[&"near_blur_px"])
		* smoothstep(0.0, float(v[&"near_full"]), depth - float(v[&"focus_near"]) - z)
	)
	var far := (
		float(v[&"far_blur_px"])
		* smoothstep(0.0, float(v[&"far_full"]), z - depth - float(v[&"focus_far"]))
	)
	return maxf(near, far)
