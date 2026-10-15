class_name InteractSign
extends RefCounted
## (U1) Signes d'interaction « Nuit douce » : ce qu'ils montrent et les moyens de les cacher.
## Propriétaire : U1. Le dessin est fait par le HUD (src/ui/interact_signs.gd, nœud
## HUD/InteractSigns) ; ce fichier ne garde que l'API partagée.
##
## - Genre du signe d'une cible (kind_of) : la métadonnée META de la cible si elle en a une (un des
##   KINDS, ou NONE), sinon selon sa classe : Npc → TALK (bulle « … »), Pickup → TAKE (main),
##   MapExit et AirshipDock → ENTER (porte), le reste (Examinable, panneaux, écriteaux) → EXAMINE
##   (étincelle) ; une cible sans invite (get_prompt() vide) n'a pas de signe.
## - Cacher le signe d'une cible (les participants d'un jeu ou d'une scène : E6, E8) :
##   InteractSign.set_hidden(cible, true), qui pose META = NONE ; set_hidden(cible, false) le rend.
## - Cacher tous les signes (une scène du récit, un jeu) : InteractSign.suppress(&"raison", true),
##   puis suppress(&"raison", false) ; plusieurs raisons se cumulent. Les signes sont aussi cachés
##   pendant un dialogue et quand la boîte de dialogue est en présentation « bandeau ».
## - Réglage « toujours montrer la touche » (menu Options de la pause) : always_show_key(),
##   set_always_show_key(), gardé dans SETTINGS_PATH.

const META := &"interact_sign"
const TALK := &"talk"
const EXAMINE := &"examine"
const TAKE := &"take"
const ENTER := &"enter"
const NONE := &"none"
const KINDS: Array[StringName] = [TALK, EXAMINE, TAKE, ENTER]
## Métadonnée facultative : hauteur du signe au-dessus de l'origine de la cible (m).
const HEIGHT_META := &"interact_sign_height"
## Réglages de l'interface (ConfigFile).
const SETTINGS_PATH := "user://interface.cfg"
const SETTINGS_SECTION := "interface"
const ALWAYS_KEY := "always_show_key"

static var _suppressors: Dictionary[StringName, bool] = {}
static var _always_show_key: int = -1


## Genre du signe de target (&"" : pas de signe).
static func kind_of(target: Node) -> StringName:
	if target == null or not is_instance_valid(target):
		return &""
	# Aucun signe sans invite (un PNJ absent, un participant d'un jeu : E8).
	if target.has_method(&"get_prompt") and str(target.call(&"get_prompt")).is_empty():
		return &""
	if target.has_meta(META):
		var forced := StringName(str(target.get_meta(META)))
		return forced if forced in KINDS else &""
	if target is Npc:
		return TALK
	if target is Pickup:
		return TAKE
	if target is MapExit or target is AirshipDock:
		return ENTER
	return EXAMINE


## Cache (hidden) ou rend le signe de target.
static func set_hidden(target: Node, hidden: bool) -> void:
	if hidden:
		target.set_meta(META, NONE)
	elif target.has_meta(META) and StringName(str(target.get_meta(META))) == NONE:
		target.remove_meta(META)


## true si le signe de target est caché par set_hidden.
static func is_hidden(target: Node) -> bool:
	return target.has_meta(META) and StringName(str(target.get_meta(META))) == NONE


## Cache (on) ou rend tous les signes pour la raison reason.
static func suppress(reason: StringName, on: bool) -> void:
	if on:
		_suppressors[reason] = true
	else:
		_suppressors.erase(reason)


## true si une raison cache tous les signes.
static func is_suppressed() -> bool:
	return not _suppressors.is_empty()


## Réglage « toujours montrer la touche » (lu dans SETTINGS_PATH au premier appel).
static func always_show_key() -> bool:
	if _always_show_key < 0:
		var config := ConfigFile.new()
		var shown := false
		if config.load(SETTINGS_PATH) == OK:
			shown = bool(config.get_value(SETTINGS_SECTION, ALWAYS_KEY, false))
		_always_show_key = 1 if shown else 0
	return _always_show_key == 1


## Change le réglage ; save : l'écrit dans SETTINGS_PATH.
static func set_always_show_key(shown: bool, save: bool = true) -> void:
	_always_show_key = 1 if shown else 0
	if not save:
		return
	var config := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH) and config.load(SETTINGS_PATH) != OK:
		push_warning("InteractSign : réglages illisibles, réécrits (%s)" % SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, ALWAYS_KEY, shown)
	if config.save(SETTINGS_PATH) != OK:
		push_warning("InteractSign : réglages non écrits (%s)" % SETTINGS_PATH)
