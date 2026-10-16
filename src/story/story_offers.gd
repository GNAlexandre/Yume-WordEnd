class_name StoryOffers
extends RefCounted
## (X-L1) Les propositions du mode libre : une scène du livre que l'on déclenche en allant voir un
## personnage ou un lieu (PLAN.md, « (X) Exploration libre : le rythme »). Propriétaire : X-L1.
## Le directeur (StoryDirector) n'appelle que les points d'entrée : rebuild(carte), refresh(),
## talk(pnj), scene_ended(id, finie). Rien ne se passe en scénarisé (active() faux : aucune
## proposition, aucun signe, aucune invite).
##
## - Proposée (offered_scenes) : toute scène pas encore jouée dont les conditions tiennent (jour,
##   créneau, « after », « if » : conditions_met) ; une tête (déclencheur autre que « ready », ou
##   sans « after ») comme une suite qui ne s'est pas enchaînée (j12_1_embuscade, j10_4_toit…).
##   Une suite qui s'enchaîne part d'elle-même juste après sa tête (StoryPacing.allows_trigger).
## - L'ancre (anchor_for) : la clé « offer » de la scène ({"npc": id} ou {"point": nom,
##   "map": id}, plus « text ») ; sans elle : talk → le PNJ ; reach, prompt → le point ; enter →
##   le marqueur ; ready → le premier PNJ présent (« present ») sur la carte de la scène, sinon le
##   premier présent ailleurs. Un PNJ nulle part (LifeDirector.where : aucune carte) cède la place
##   au point de la scène ; sans point, la scène n'a pas d'ancre (elle attend).
## - Ancre sur un PNJ : son signe devient le ruban du récit (InteractSign.STORY) ; lui parler fait
##   d'abord dire la proposition (le texte « offer », sinon ui/offer_default), avec deux choix :
##   « Allons-y » (ui/offer_go : la scène se joue, StoryDirector.play) et « Plus tard »
##   (ui/offer_later : la conversation libre habituelle).
## - Ancre sur un lieu : une invite StoryPrompt (rôle ROLE_SCENE) sous le nœud « StoryOffers » de
##   la carte, au ruban du récit ; l'utiliser fait dire la proposition (sans orateur), mêmes
##   choix (« Plus tard » ne fait rien de plus). Une scène « prompt » a déjà son invite (celle du
##   directeur) : elle prend seulement le ruban.
## - Accepter une scène d'une autre carte (le PNJ est ailleurs) y mène d'abord (fondu, le marqueur
##   d'arrivée depuis la carte courante, sinon Spawn ; celui du déclencheur « enter »), le joueur
##   posé près du point du déclencheur.

## Nœud des invites des propositions, sous la carte.
const HOLDER_NODE := "StoryOffers"
## Nœud du dialogue d'une proposition, et index de ses deux choix.
const OFFER_NODE := "offer"
const GO := 0
const LATER := 1
## Identifiant de dialogue d'une proposition posée sur un lieu (suivi de l'id de la scène).
const PLACE_DIALOGUE_PREFIX := "offre_"
const PROMPT_SIZE := 1.6
## Le joueur posé à cette distance (m) au sud du point d'une scène, après un voyage.
const ARRIVAL_OFFSET := 1.2
const SPAWN_MARKER := &"Spawn"
const ARRIVAL_PREFIX := "from_"
## Replis des textes (data/texts/<île>/story.json, « ui/… »).
const FALLBACK_GO := "Allons-y"
const FALLBACK_LATER := "Plus tard"
const FALLBACK_DEFAULT := "Un moment de l'histoire t'attend : « {title} »."

## Le directeur (autoload StoryDirector), posé par lui.
var director: Node

var _map: Map
## Invites des propositions sur la carte courante : id de la scène → StoryPrompt.
var _prompts: Dictionary[StringName, StoryPrompt] = {}
## Cibles qui portent le ruban du récit (PNJ, invites du directeur).
var _tagged: Array[Node] = []
var _dialogue: OfferTalk
## Proposition en cours (dialogue ouvert) : scène, PNJ (&"" : un lieu), identifiant du dialogue.
var _pending: StringName = &""
var _pending_npc: StringName = &""
var _pending_dialogue: StringName = &""
## Un voyage vers la carte d'une scène acceptée est en cours.
var _travelling: bool = false
var _rng := RandomNumberGenerator.new()

# --- Points d'entrée (StoryDirector) -----------------------------------------------------------


## Nouvelle carte (après les invites du récit) ou mode changé : pose les propositions de la carte.
func rebuild(map: Map) -> void:
	_clear()
	_map = map
	refresh()


## Réévalue les propositions posées : rubans des PNJ et des invites, invites des lieux.
func refresh() -> void:
	var wanted_nodes: Array[Node] = []
	var wanted_points: Dictionary[StringName, Variant] = {}
	if active() and not StoryDirector.is_playing() and _map_valid():
		var map_id := _map.map_id()
		for scene_id: StringName in offered_scenes():
			var found := anchor(scene_id)
			if found.is_empty() or found["map"] != map_id:
				continue
			if found.has("npc"):
				var npc := LifeDirector.npc(found["npc"])
				if npc != null and not wanted_nodes.has(npc):
					wanted_nodes.append(npc)
				continue
			var own := _director_prompt(scene_id)
			if own != null:
				wanted_nodes.append(own)
			else:
				wanted_points[scene_id] = found["point"]
	_retag(wanted_nodes)
	_place_prompts(wanted_points)


## Conversation avec un PNJ, en libre, hors scène : vraie si une proposition la prend.
func talk(npc_id: StringName) -> bool:
	if not active() or _travelling:
		return false
	var map_id := WorldManager.current_map()
	for scene_id: StringName in offered_scenes():
		var found := anchor(scene_id)
		if found.get("npc", &"") == npc_id and found["map"] == map_id:
			return propose(scene_id, npc_id)
	return false


## Une scène finie ou interrompue : les propositions suivent.
func scene_ended(_scene_id: StringName, _completed: bool) -> void:
	refresh()


# --- État ----------------------------------------------------------------------------------


## Vrai si les propositions ont cours : récit allumé, acte en cours, mode libre.
func active() -> bool:
	return (
		StoryDirector.enabled
		and GameState.story_running()
		and StoryDirector.mode() == StoryPacing.FREE
	)


## Scènes proposées maintenant (ordre des ids), vide hors du mode libre.
func offered_scenes() -> Array[StringName]:
	var result: Array[StringName] = []
	if not active():
		return result
	var island := StoryDirector.island()
	for scene_id: StringName in StoryData.scene_ids(island):
		if GameState.is_scene_done(scene_id) or scene_id == StoryDirector.current_scene():
			continue
		if conditions_met(StoryData.scene(island, scene_id), GameState.day, LifeSlots.current()):
			result.append(scene_id)
	return result


## Ancre de la scène maintenant ({"npc", "map"} ou {"point", "map"} ; {} : aucune).
func anchor(scene_id: StringName) -> Dictionary:
	var data := StoryData.scene(StoryDirector.island(), scene_id)
	return anchor_for(data, func(npc_id: StringName) -> StringName: return _where(npc_id))


## Invites des propositions posées sur la carte courante.
func prompts() -> Array[StoryPrompt]:
	var result: Array[StoryPrompt] = []
	for prompt: StoryPrompt in _prompts.values():
		if is_instance_valid(prompt):
			result.append(prompt)
	return result


## Cibles au ruban du récit (PNJ, invites).
func tagged() -> Array[Node]:
	var result: Array[Node] = []
	for node: Node in _tagged:
		if is_instance_valid(node):
			result.append(node)
	return result


## Scène dont la proposition est dite en ce moment (&"" : aucune).
func proposing() -> StringName:
	return _pending


# --- Proposer, accepter ------------------------------------------------------------------------


## Dit la proposition de la scène (npc_id : le PNJ qui la porte ; &"" : un lieu), avec « Allons-y »
## et « Plus tard » ; vrai si le dialogue s'ouvre.
func propose(scene_id: StringName, npc_id: StringName = &"") -> bool:
	if DialogueRunner.is_any_running():
		return false
	var island := StoryDirector.island()
	var data := StoryData.scene(island, scene_id)
	if data.is_empty():
		return false
	_ensure_dialogue()
	var line := {"speaker": "", "text": _default_text(data)}
	var offer: Dictionary = data["offer"] if data.get("offer") is Dictionary else {}
	var for_npc := offer.has("npc")
	if offer.has("text") and for_npc != npc_id.is_empty():
		# Le texte de la clé « offer » est écrit pour son ancre : un PNJ qui parle, ou un lieu.
		line["text"] = StoryData.text(island, str(offer["text"]), scene_id, line["text"])
		if for_npc:
			line["speaker"] = _display_name(npc_id)
	line["choices"] = [
		{"text": StoryDirector.ui_text("offer_go", FALLBACK_GO)},
		{"text": StoryDirector.ui_text("offer_later", FALLBACK_LATER)},
	]
	var dialogue_id := npc_id
	if npc_id.is_empty():
		dialogue_id = StringName(PLACE_DIALOGUE_PREFIX + String(scene_id))
	_pending = scene_id
	_pending_npc = npc_id
	_pending_dialogue = dialogue_id
	if not _dialogue.open({OFFER_NODE: line}, dialogue_id):
		_pending = &""
		return false
	return true


## Joue la scène acceptée ; d'une autre carte, y mène d'abord (coroutine). Faux si elle ne part pas.
func accept(scene_id: StringName) -> bool:
	var data := StoryData.scene(StoryDirector.island(), scene_id)
	if data.is_empty() or StoryDirector.is_playing() or _travelling:
		return false
	var scene_map := StringName(str(data.get("map", "")))
	if not scene_map.is_empty() and WorldManager.current_map() != scene_map:
		_travelling = true
		var stage: StoryStage = StoryDirector.stage()
		stage.set_control(false)
		await WorldManager.go_to(scene_map, _arrival_marker(data, scene_map))
		_travelling = false
		var point: Variant = _trigger_point(data)
		if point != null and WorldManager.current_map() == scene_map:
			var at := stage.resolve(point).origin + Vector3(0.0, 0.0, ARRIVAL_OFFSET)
			stage.place_player(at, Vector3.FORWARD)
		stage.set_control(true)
	return StoryDirector.play(scene_id)


# --- Données (statiques : tests) ----------------------------------------------------------------


## Vrai si les conditions de la scène tiennent au jour et au créneau donnés (scènes jouées et
## drapeaux : ceux de la partie) : « day », « slot », « after », « if ».
static func conditions_met(data: Dictionary, day: int, slot: StringName) -> bool:
	if data.is_empty():
		return false
	if data.has("day"):
		var days := DialogueRunner.day_range(data["day"])
		if day < days.x or day > days.y:
			return false
	if data.has("slot") and not _names(data["slot"]).has(String(slot)):
		return false
	for scene_id: String in _names(data.get("after", [])):
		if not GameState.is_scene_done(StringName(scene_id)):
			return false
	return not data.has("if") or DialogueRunner.evaluate(data["if"])


## Créneaux où la scène peut se jouer (« slot », sinon tous).
static func slots_of(data: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	if not data.has("slot"):
		result.assign(GameState.SLOTS)
		return result
	for slot: String in _names(data["slot"]):
		result.append(StringName(slot))
	return result


## Ancre d'une scène : {"npc": id, "map": carte du PNJ} ou {"point": place, "map": carte} ; {}
## sans ancre. where.call(npc_id) rend la carte où se trouve le PNJ (&"" : nulle part).
static func anchor_for(data: Dictionary, where: Callable) -> Dictionary:
	if data.is_empty():
		return {}
	var scene_map := StringName(str(data.get("map", "")))
	var trigger: Dictionary = data["trigger"] if data.get("trigger") is Dictionary else {}
	var offer: Dictionary = data["offer"] if data.get("offer") is Dictionary else {}
	var elsewhere := {}
	for npc_id: StringName in _anchor_npcs(data, offer, trigger):
		var map_id: StringName = where.call(npc_id)
		if map_id.is_empty():
			continue
		if map_id == scene_map:
			return {"npc": npc_id, "map": map_id}
		if elsewhere.is_empty():
			elsewhere = {"npc": npc_id, "map": map_id}
	if not elsewhere.is_empty():
		return elsewhere
	if offer.has("point"):
		return {"point": offer["point"], "map": StringName(str(offer.get("map", scene_map)))}
	var point: Variant = _trigger_point(data)
	if point == null:
		return {}
	return {"point": point, "map": StringName(str(trigger.get("map", scene_map)))}


## PNJ candidats à l'ancre, dans l'ordre : offer.npc ; talk → son PNJ ; ready → les présents.
static func _anchor_npcs(
	data: Dictionary, offer: Dictionary, trigger: Dictionary
) -> Array[StringName]:
	var result: Array[StringName] = []
	if offer.has("npc"):
		result.append(StringName(str(offer["npc"])))
	elif offer.is_empty():
		match str(trigger.get("on", "")):
			"talk":
				result.append(StringName(str(trigger.get("npc", ""))))
			"ready":
				for npc_id: String in _names(data.get("present", [])):
					result.append(StringName(npc_id))
	return result


## Point du déclencheur : place de reach et prompt, marqueur d'enter ; null sinon.
static func _trigger_point(data: Dictionary) -> Variant:
	var trigger: Dictionary = data["trigger"] if data.get("trigger") is Dictionary else {}
	match str(trigger.get("on", "")):
		"reach", "prompt":
			return trigger.get("point")
		"enter":
			var marker := str(trigger.get("marker", ""))
			if not marker.is_empty():
				return marker
	return null


static func _names(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for item: Variant in value if value is Array else [value]:
		if item is String or item is StringName:
			result.append(str(item))
	return result


# --- Outils --------------------------------------------------------------------------------


func _where(npc_id: StringName) -> StringName:
	return LifeDirector.where(npc_id).get("map", &"")


func _map_valid() -> bool:
	return (
		is_instance_valid(_map)
		and _map.is_inside_tree()
		and not _map.is_queued_for_deletion()
		and _map == WorldManager.current_map_node()
	)


## L'invite du directeur d'une scène « prompt » (null : aucune).
func _director_prompt(scene_id: StringName) -> StoryPrompt:
	for prompt: StoryPrompt in StoryDirector.prompts():
		if prompt.scene_id == scene_id and prompt.roles.has(StoryPrompt.ROLE_SCENE):
			return prompt
	return null


func _retag(wanted: Array[Node]) -> void:
	for node: Node in _tagged:
		if is_instance_valid(node) and not wanted.has(node):
			InteractSign.set_story(node, false)
	for node: Node in wanted:
		InteractSign.set_story(node, true)
	_tagged = wanted


func _place_prompts(wanted: Dictionary[StringName, Variant]) -> void:
	for scene_id: StringName in _prompts.keys():
		var prompt := _prompts[scene_id]
		var stale := not is_instance_valid(prompt) or not wanted.has(scene_id)
		if not stale and prompt.point_name != str(wanted[scene_id]):
			stale = true
		if stale:
			if is_instance_valid(prompt):
				prompt.queue_free()
			_prompts.erase(scene_id)
	if wanted.is_empty():
		return
	var holder := _holder()
	var island := StoryDirector.island()
	for scene_id: StringName in wanted:
		if _prompts.has(scene_id):
			continue
		var prompt := StoryPrompt.new(PROMPT_SIZE)
		prompt.name = "Offer_%s" % scene_id
		prompt.roles = [StoryPrompt.ROLE_SCENE]
		prompt.scene_id = scene_id
		prompt.point_name = str(wanted[scene_id])
		holder.add_child(prompt)
		prompt.global_position = StoryDirector.stage().resolve(wanted[scene_id]).origin
		var title := str(StoryData.scene(island, scene_id).get("title", scene_id))
		prompt.set_text(title)
		InteractSign.set_story(prompt, true)
		prompt.used.connect(_on_prompt_used)
		_prompts[scene_id] = prompt


func _holder() -> Node3D:
	var holder := _map.get_node_or_null(NodePath(HOLDER_NODE)) as Node3D
	if holder == null:
		holder = Node3D.new()
		holder.name = HOLDER_NODE
		_map.add_child(holder)
	return holder


func _clear() -> void:
	_retag([] as Array[Node])
	for prompt: StoryPrompt in _prompts.values():
		if is_instance_valid(prompt):
			prompt.queue_free()
	_prompts.clear()


func _ensure_dialogue() -> void:
	if is_instance_valid(_dialogue):
		return
	_dialogue = OfferTalk.new()
	_dialogue.name = "OfferDialogue"
	director.add_child(_dialogue)
	if not EventBus.dialogue_ended.is_connected(_on_dialogue_ended):
		EventBus.dialogue_ended.connect(_on_dialogue_ended)


func _default_text(data: Dictionary) -> String:
	var text := StoryDirector.ui_text("offer_default", FALLBACK_DEFAULT)
	return text.replace("{title}", str(data.get("title", "")))


func _display_name(npc_id: StringName) -> String:
	var node := LifeDirector.npc(npc_id)
	if node != null and node.data != null and not node.data.display_name.is_empty():
		return node.data.display_name
	var data := LifeData.find_npc(npc_id)
	return data.display_name if data != null else ""


## Marqueur d'arrivée sur la carte d'une scène : celui du déclencheur « enter », sinon
## from_<carte courante>, sinon Spawn.
func _arrival_marker(data: Dictionary, scene_map: StringName) -> StringName:
	var trigger: Dictionary = data["trigger"] if data.get("trigger") is Dictionary else {}
	if str(trigger.get("on", "")) == "enter" and not str(trigger.get("marker", "")).is_empty():
		return StringName(str(trigger["marker"]))
	var from := StringName(ARRIVAL_PREFIX + String(WorldManager.current_map()))
	return from if WorldAtlas.scene_markers(scene_map).has(from) else SPAWN_MARKER


## La conversation libre du PNJ (« Plus tard ») : celle de StoryDirector hors scène.
func _free_talk(npc_id: StringName) -> void:
	if DialogueRunner.is_any_running() or StoryDirector.is_playing():
		return
	var path := StoryData.talk_path(StoryDirector.island(), npc_id)
	var npc := LifeData.find_npc(npc_id)
	_ensure_dialogue()
	if not path.is_empty() and npc != null and _dialogue.play(path, "", npc_id, npc):
		return
	var actor := LifeDirector.actor(npc_id)
	if actor != null:
		actor.say(LifeTexts.greeting(npc_id, _rng))


func _on_prompt_used(prompt: StoryPrompt) -> void:
	if not active() or StoryDirector.is_playing() or _travelling:
		return
	propose(prompt.scene_id)


func _on_dialogue_ended(dialogue_id: StringName) -> void:
	if _pending.is_empty() or dialogue_id != _pending_dialogue:
		return
	var scene_id := _pending
	var npc_id := _pending_npc
	var chosen := _dialogue.chosen if is_instance_valid(_dialogue) else -1
	_pending = &""
	_pending_npc = &""
	_pending_dialogue = &""
	if chosen == GO:
		accept.call_deferred(scene_id)
	elif chosen == LATER and not npc_id.is_empty():
		_free_talk.call_deferred(npc_id)


## Le dialogue d'une proposition : des nœuds construits (pas un fichier), le choix retenu.
class OfferTalk:
	extends StoryDialogue

	## Index du dernier choix fait (-1 : aucun).
	var chosen: int = -1

	## Ouvre les nœuds construits au nœud OFFER_NODE ; faux si un dialogue est en cours.
	func open(nodes: Dictionary, dialogue_id: StringName) -> bool:
		if is_any_running():
			return false
		chosen = -1
		_npc_id = dialogue_id
		_speaker = ""
		_line_speaker_id = dialogue_id
		_nodes = nodes
		_running = true
		_active = self
		EventBus.dialogue_choice_made.connect(_on_dialogue_choice_made)
		EventBus.dialogue_started.emit(_npc_id)
		_enter(StoryOffers.OFFER_NODE)
		return true

	func _on_dialogue_choice_made(index: int) -> void:
		if is_running() and not _choices.is_empty():
			chosen = index
		super(index)
