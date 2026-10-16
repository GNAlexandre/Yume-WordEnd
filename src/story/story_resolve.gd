class_name StoryResolve
extends RefCounted
## (X-L0, X-L4) Les jours du rythme libre (PLAN.md, « (X) Exploration libre : le rythme ») : le
## jour devient un chapitre. Le directeur n'appelle que ces points d'entrée, en libre seulement
## (en scénarisé, rien ne change). Propriétaire : X-L4.
##
## - Coucher (can_sleep) : le soir ou la nuit (act.json, sleep.slots), sans scène à avoir jouée
##   (sleep_after), le jour du départ compris ; après lui, les jours libres continuent.
## - Temps qui passe (can_rest) : sans plafond (la prochaine scène clé), sauf la nuit (il faut
##   dormir).
## - Au coucher (before_sleep), les scènes laissées passer (des jours passés ou du jour qui finit)
##   sont réglées sans être jouées (resolve_scene) : seules leurs étapes d'état s'appliquent
##   (flag, calendar, ship par ShipControl.finish, les drapeaux de succès des jeux mis à faux, les
##   dialogues sans rien montrer avec leurs choix : la clé « skip » de la scène, sinon le premier) ;
##   ni next_day, ni slot, ni go_to, place, walk, caméra. Puis GameState.mark_scene_done et le
##   drapeau passee_<id> : les chaînes « after » et les jours suivants restent cohérents. La ligne
##   du calendrier du jour : celle du jour si une de ses scènes a été vécue, sinon un texte libre
##   (FREE_LINE).
## - Plus d'indice impératif automatique (waiting_hint) ; le calendrier liste « À vivre
##   aujourd'hui » (today_scenes, scene_label) et marque les scènes passées (passed_on), sans les
##   juger.

## Préfixe du drapeau d'une scène laissée passer (passee_<id>).
const PASSED_PREFIX := "passee_"
## Ligne du calendrier d'un jour où aucune scène n'a été vécue (texte calendar/libre du récit).
const FREE_LINE := &"libre"
## Étapes appliquées quand une scène est réglée sans être jouée (les autres sont ignorées).
const STATE_STEPS: Array[String] = ["flag", "calendar", "ship", "game", "dialogue"]

## Le directeur (autoload StoryDirector), posé par lui.
var director: Node


## Vrai si le joueur peut se coucher en libre : le soir ou la nuit, hors scène, sans condition de
## scènes ; rule (la règle d'E6) n'y compte pas.
func can_sleep(_rule: bool) -> bool:
	if not _free_time():
		return false
	var sleep_data: Dictionary = StoryData.act(_island()).get("sleep", {})
	var slots: Variant = sleep_data.get("slots", [])
	var current := String(LifeSlots.current())
	var allowed := false
	for slot: Variant in slots if slots is Array else [slots]:
		allowed = allowed or str(slot) == current
	return allowed and GameState.day < GameState.MAX_DAY


## Vrai si le joueur peut laisser passer le temps en libre : à tout créneau sauf la nuit, hors
## scène ; rule (plafonnée par la prochaine scène clé) n'y compte pas.
func can_rest(_rule: bool) -> bool:
	if not _free_time():
		return false
	var current := GameState.SLOTS.find(LifeSlots.current())
	return current >= 0 and current < GameState.SLOTS.size() - 1


## Le joueur se couche en libre, avant le jour suivant (StoryDirector.sleep) : règle les scènes
## laissées passer jusqu'au jour day (due), dans l'ordre de leurs « after » (j10_4_toit vient
## après j10_5_tour), puis choisit la ligne du calendrier du jour (FREE_LINE si aucune de ses
## scènes n'a été vécue).
func before_sleep(island: StringName, day: int) -> void:
	var progressed := true
	while progressed:
		progressed = false
		for scene_id: StringName in due(island, day):
			var data := StoryData.scene(island, scene_id)
			if _after_met(data) and resolve_scene(island, scene_id):
				progressed = true
	var line: StringName = GameState.calendar().get(day, &"")
	if line.is_empty() and lived_on(island, day).is_empty():
		GameState.write_calendar(day, FREE_LINE)


## Les scènes pas faites dont les jours sont finis au soir du jour day (dans l'ordre des ids).
func due(island: StringName, day: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for scene_id: StringName in StoryData.scene_ids(island):
		var data := StoryData.scene(island, scene_id)
		if data.has("day") and not GameState.is_scene_done(scene_id):
			var days := DialogueRunner.day_range(data["day"])
			if days.y >= 1 and days.y <= day:
				result.append(scene_id)
	return result


## Règle une scène sans la jouer (ses étapes d'état, puis faite et passee_<id>) ; vrai si elle
## est réglée (faux : inconnue, déjà faite, ou son « if » faux).
func resolve_scene(island: StringName, scene_id: StringName) -> bool:
	var data := StoryData.scene(island, scene_id)
	if data.is_empty() or GameState.is_scene_done(scene_id):
		return false
	if data.has("if") and not DialogueRunner.evaluate(data["if"]):
		return false
	var state := {"skip_set": false}
	_apply_steps(island, scene_id, data, data.get("steps", []), state)
	GameState.mark_scene_done(scene_id)
	GameState.set_flag(passed_flag(scene_id))
	return true


## Drapeau d'une scène laissée passer : passee_<id>.
static func passed_flag(scene_id: StringName) -> StringName:
	return StringName(PASSED_PREFIX + String(scene_id))


## Vrai si la scène a été laissée passer (réglée au coucher sans être jouée).
static func is_passed(scene_id: StringName) -> bool:
	return GameState.has_flag(passed_flag(scene_id))


## Les scènes du jour day laissées passer (dans l'ordre des ids).
func passed_on(island: StringName, day: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for scene_id: StringName in _scenes_of_day(island, day):
		if is_passed(scene_id):
			result.append(scene_id)
	return result


## Les scènes du jour day vécues (faites sans avoir été laissées passer).
func lived_on(island: StringName, day: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for scene_id: StringName in _scenes_of_day(island, day):
		if GameState.is_scene_done(scene_id) and not is_passed(scene_id):
			result.append(scene_id)
	return result


## « À vivre aujourd'hui » : les scènes du jour courant pas encore faites dont les « after » sont
## faits et le « if » vrai, et dont un créneau est le courant ou plus tard dans la journée.
func today_scenes(island: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var now := GameState.SLOTS.find(LifeSlots.current())
	for scene_id: StringName in _scenes_of_day(island, GameState.day, true):
		if GameState.is_scene_done(scene_id):
			continue
		var data := StoryData.scene(island, scene_id)
		if not _after_met(data):
			continue
		if data.has("if") and not DialogueRunner.evaluate(data["if"]):
			continue
		if _last_slot(data) >= now:
			result.append(scene_id)
	return result


## Ce que le calendrier dit d'une scène à vivre : le texte de sa proposition (offer.text) s'il
## existe, sinon son titre ; suivi de son créneau s'il est plus tard dans la journée.
func scene_label(island: StringName, scene_id: StringName) -> String:
	var data := StoryData.scene(island, scene_id)
	var label := str(data.get("title", scene_id))
	var offer: Variant = data.get("offer")
	if offer is Dictionary and (offer as Dictionary).has("text"):
		label = StoryData.text(island, str(offer["text"]), scene_id, label)
	var first := _first_slot(data)
	if first > GameState.SLOTS.find(LifeSlots.current()):
		var slot := String(GameState.SLOTS[first])
		var when := StoryData.text(island, "ui/slot_" + slot, &"", slot)
		var later := StoryData.text(island, "ui/today_later", &"", "{scene} ({slot})")
		label = later.replace("{scene}", label).replace("{slot}", when)
	return label


## Le titre d'une scène (sa clé « title »).
func scene_title(island: StringName, scene_id: StringName) -> String:
	return str(StoryData.scene(island, scene_id).get("title", scene_id))


## L'indice hors scène en libre : aucun (plus de bulle impérative ; le calendrier dit ce qui est
## à vivre).
func waiting_hint() -> String:
	return ""


# --- Interne ----------------------------------------------------------------------------------


## Hors scène, pendant l'acte en jours.
func _free_time() -> bool:
	if director == null or bool(director.call(&"is_playing")):
		return false
	return GameState.story_running()


func _island() -> StringName:
	return StringName(director.call(&"island")) if director != null else &""


## Applique les étapes d'état d'une scène réglée sans être jouée (les « if » à leur tour).
func _apply_steps(
	island: StringName, scene_id: StringName, data: Dictionary, steps: Array, state: Dictionary
) -> void:
	for item: Variant in steps:
		if not item is Dictionary:
			continue
		var step: Dictionary = item
		var kind := str(step.get("do", ""))
		if not STATE_STEPS.has(kind):
			continue
		if step.has("if") and not DialogueRunner.evaluate(step["if"]):
			continue
		match kind:
			"flag":
				for flag: String in _names(step.get("set")):
					GameState.set_flag(StringName(flag))
				for flag: String in _names(step.get("clear")):
					GameState.set_flag(StringName(flag), false)
			"calendar":
				GameState.write_calendar(_day_of(data), StringName(str(step.get("line", ""))))
			"ship":
				ShipControl.finish(StringName(str(step["ship"])), StringName(str(step["action"])))
			"game":
				# Un jeu pas joué n'est pas gagné ; son repli (cartons, poses) n'est pas joué.
				var params: Dictionary = step.get("params", {})
				if params.has("success_flag"):
					GameState.set_flag(StringName(str(params["success_flag"])), false)
			"dialogue":
				_apply_dialogue(island, scene_id, data, step, state)


## Un dialogue réglé sans être montré : ses effets et, à un choix, la clé « skip » de la scène si
## l'un des choix change l'état (ses drapeaux, une fois), sinon le premier choix (X-L2).
func _apply_dialogue(
	island: StringName, scene_id: StringName, data: Dictionary, step: Dictionary, state: Dictionary
) -> void:
	var path := StoryData.dialogue_path(island, str(step.get("file", scene_id)))
	var flags := StorySkip.skip_flags(data)
	var crossed := StoryDialogue.apply_silently(path, str(step["node"]), true, flags.is_empty())
	if crossed and not flags.is_empty() and not state["skip_set"]:
		state["skip_set"] = true
		for flag: StringName in flags:
			GameState.set_flag(flag)


## Le jour où s'écrit la ligne d'une scène réglée : le jour courant, ramené dans ses jours.
func _day_of(data: Dictionary) -> int:
	var days := DialogueRunner.day_range(data.get("day"))
	if days.y < days.x:
		return GameState.day
	return clampi(GameState.day, days.x, days.y)


## Vrai si les « after » de la scène sont faits.
func _after_met(data: Dictionary) -> bool:
	for scene_id: String in _names(data.get("after", [])):
		if not GameState.is_scene_done(StringName(scene_id)):
			return false
	return true


## Les scènes dont les jours comprennent day (within) ou finissent à day.
func _scenes_of_day(island: StringName, day: int, within: bool = false) -> Array[StringName]:
	var result: Array[StringName] = []
	for scene_id: StringName in StoryData.scene_ids(island):
		var data := StoryData.scene(island, scene_id)
		if not data.has("day"):
			continue
		var days := DialogueRunner.day_range(data["day"])
		if (within and days.x <= day and day <= days.y) or (not within and days.y == day):
			result.append(scene_id)
	return result


## Premier et dernier créneau d'une scène (index de GameState.SLOTS ; sans « slot » : toute la
## journée).
func _first_slot(data: Dictionary) -> int:
	var found := GameState.SLOTS.size()
	for slot: String in _names(data.get("slot", [])):
		var index := GameState.SLOTS.find(StringName(slot))
		if index >= 0:
			found = mini(found, index)
	return 0 if found == GameState.SLOTS.size() else found


func _last_slot(data: Dictionary) -> int:
	var found := -1
	for slot: String in _names(data.get("slot", [])):
		found = maxi(found, GameState.SLOTS.find(StringName(slot)))
	return GameState.SLOTS.size() - 1 if found < 0 else found


static func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value == null:
		return result
	for item: Variant in value if value is Array else [value]:
		result.append(str(item))
	return result
