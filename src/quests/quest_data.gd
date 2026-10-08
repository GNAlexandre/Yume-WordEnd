class_name QuestData
extends Resource
## Quête en étapes, écrite en données : data/quests/<id>.json (le nom du fichier est l'id).
## Propriétaires : L7, puis Lot Q (moteur de quêtes). Format complet, exemple commenté, conditions
## et effets de dialogue, déclencheurs et tests : docs/QUETES.md.
##
## {
##   "id": "picture_book", "title": "…", "summary": "… (journal)", "giver": "nephren",
##   "main": false, "auto_start": false,
##   "requires": {"quests": ["…"], "flags": ["…"], "not_flags": ["…"]},
##   "steps": [{"id": "…", "type": "collect", "objective": "…", …}, …],
##   "rewards": {"items": {"picture_book": 1}, "flags": ["…"], "max_hp": 6}
## }
## Seuls id, title et steps (au moins une étape, voir QuestStep) sont obligatoires ; une clé qui
## commence par « _ » est un commentaire. Un fichier invalide donne un push_warning qui dit
## pourquoi et la quête est ignorée (find() renvoie null) : tests/unit/test_quest_content.gd
## vérifie toutes les quêtes et leurs renvois (PNJ, objets, ennemis, zones, déclencheurs).
##
## États (GameState.quest_state) : &"" (inconnue, ou verrouillée par ses prérequis), &"active",
## &"done" ; &"available" n'est jamais écrit par le moteur : status() le calcule (pas d'état et
## prérequis remplis), ce que lisent les marqueurs des PNJ et la condition de dialogue « quest ».
## Le HUD, le journal et les PNJ lisent ces données (find, all, status, current_step…) ; seul
## le QuestTracker fait avancer les quêtes.

## Dossier des quêtes du jeu.
const DATA_DIR := "res://data/quests"
const FILE_EXTENSION := ".json"
## Clés JSON d'une quête et de son objet « requires ».
const QUEST_KEYS: Array[String] = [
	"id", "title", "summary", "giver", "main", "auto_start", "requires", "steps", "rewards"
]
const REQUIRE_KEYS: Array[String] = ["quests", "flags", "not_flags"]
## Marqueurs au-dessus des PNJ (npc_marker) : « ! » quête à prendre, « ? » quête à rendre.
const MARKER_AVAILABLE := &"available"
const MARKER_TURN_IN := &"turn_in"

## Dossiers lus par find() et all(), dans l'ordre (le premier qui a <id>.json gagne). Les tests
## y ajoutent leurs quêtes d'exemple (add_search_dir) puis les retirent.
static var _search_dirs: PackedStringArray = [DATA_DIR]
## Fichier lu → QuestData (null : fichier invalide, déjà signalé).
static var _by_path: Dictionary = {}
static var _listing: Array[QuestData] = []
static var _listed: bool = false

## Identifiant, ex. &"pages".
@export var id: StringName
## Titre affiché par le HUD et le journal, ex. « Les pages envolées ».
@export var title: String = ""
## Résumé affiché par le journal.
@export_multiline var summary: String = ""
## Objectif général (L7) ; pour une quête JSON, celui de sa première étape. Le HUD affiche
## l'objectif de l'étape courante (current_objective()).
@export_multiline var objective: String = ""
## PNJ qui la donne (NpcData.id) : « ! » au-dessus de lui quand elle est disponible.
@export var giver_npc: StringName
## Quête principale (journal : en tête, mention « Quête principale »).
@export var main: bool = false
## Démarre toute seule dès que ses prérequis sont remplis (actes de la quête principale…).
@export var auto_start: bool = false
## Prérequis pour être disponible : quêtes terminées, drapeaux posés, drapeaux absents.
@export var prereq_quests: Array[StringName] = []
@export var prereq_flags: Array[StringName] = []
@export var prereq_not_flags: Array[StringName] = []
## Étapes, dans l'ordre.
@export var steps: Array[QuestStep] = []
## Héritage du L7 (quêtes construites en code) : objets à rendre et drapeaux exigés quand la
## quête se termine (objets retirés). Une quête JSON utilise des étapes collect à la place.
@export var required_items: Dictionary[StringName, int] = {}
@export var required_flags: Array[StringName] = []
## Récompense de fin de quête : objets, drapeaux posés, PV max portés à cette valeur s'ils sont
## plus bas (0 = aucun effet).
@export var reward_items: Dictionary[StringName, int] = {}
@export var reward_flags: Array[StringName] = []
@export var reward_max_hp: int = 0

# --- Fichiers ----------------------------------------------------------------------------------


## Données de la quête quest_id (<dossier>/<id>.json), null si elle est inconnue ou invalide.
static func find(quest_id: StringName) -> QuestData:
	if not String(quest_id).is_valid_ascii_identifier():
		return null
	for dir: String in _search_dirs:
		var path := dir.path_join(String(quest_id) + FILE_EXTENSION)
		if FileAccess.file_exists(path):
			return load_file(path)
	return null


## Toutes les quêtes valides des dossiers de recherche, triées par id.
static func all() -> Array[QuestData]:
	if not _listed:
		_listing.clear()
		var seen: Dictionary[String, bool] = {}
		for dir: String in _search_dirs:
			for file_name: String in _list_files(dir):
				var quest_id := file_name.get_basename()
				if not file_name.ends_with(FILE_EXTENSION) or seen.has(quest_id):
					continue
				seen[quest_id] = true
				var quest := find(StringName(quest_id))
				if quest != null:
					_listing.append(quest)
		_listing.sort_custom(
			func(a: QuestData, b: QuestData) -> bool: return String(a.id) < String(b.id)
		)
		_listed = true
	return _listing.duplicate()


## Lit et vérifie un fichier de quête (mis en cache) ; null et un push_warning s'il est invalide.
static func load_file(path: String) -> QuestData:
	if _by_path.has(path):
		return _by_path[path]
	var quest := _parse_file(path)
	_by_path[path] = quest
	return quest


## Ajoute un dossier de quêtes (tests, quêtes d'exemple) après ceux déjà lus.
static func add_search_dir(dir: String) -> void:
	if not _search_dirs.has(dir):
		_search_dirs.append(dir)
	clear_cache()


static func remove_search_dir(dir: String) -> void:
	var index := _search_dirs.find(dir)
	if index >= 0 and dir != DATA_DIR:
		_search_dirs.remove_at(index)
	clear_cache()


## Oublie les fichiers lus (une quête modifiée sur le disque est relue).
static func clear_cache() -> void:
	_by_path.clear()
	_listing.clear()
	_listed = false


static func _list_files(dir: String) -> PackedStringArray:
	# ResourceLoader.list_directory lit aussi le paquet d'un jeu exporté.
	if dir.begins_with("res://"):
		return ResourceLoader.list_directory(dir)
	return DirAccess.get_files_at(dir)


static func _parse_file(path: String) -> QuestData:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_warning("QuestData : quête introuvable ou vide : %s" % path)
		return null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning(
			(
				"QuestData : JSON invalide dans %s, ligne %d : %s"
				% [path, json.get_error_line() + 1, json.get_error_message()]
			)
		)
		return null
	var problem_text := problem(json.data, path.get_file().get_basename())
	if not problem_text.is_empty():
		push_warning("QuestData : quête invalide dans %s : %s" % [path, problem_text])
		return null
	return from_dict(json.data)


# --- Format JSON -------------------------------------------------------------------------------


## Premier problème d'une quête JSON déjà lue, "" si elle est valide. file_id : nom du fichier
## sans extension, qui doit être l'id ("" : pas de vérification).
static func problem(data: Variant, file_id: String = "") -> String:
	if not data is Dictionary:
		return "la racine doit être un objet"
	var quest: Dictionary = data
	var unknown := QuestStep.unknown_key(quest, QUEST_KEYS)
	if not unknown.is_empty():
		return "clé inconnue « %s »" % unknown
	if not QuestStep.is_name(quest.get("id")):
		return "« id » doit être un identifiant (lettres, chiffres, _)"
	if not file_id.is_empty() and quest["id"] != file_id:
		return "« id » (%s) doit être le nom du fichier (%s)" % [quest["id"], file_id]
	if not (quest.get("title") is String and not (quest["title"] as String).is_empty()):
		return "« title » est obligatoire"
	if quest.has("summary") and not quest["summary"] is String:
		return "« summary » doit être un texte"
	if quest.has("giver") and not QuestStep.is_name(quest["giver"]):
		return "« giver » doit être un id de PNJ"
	for key: String in ["main", "auto_start"]:
		if quest.has(key) and not quest[key] is bool:
			return "« %s » doit valoir true ou false" % key
	var requires_problem := _requires_problem(quest.get("requires", {}))
	if not requires_problem.is_empty():
		return requires_problem
	var steps_problem := _steps_problem(quest.get("steps"))
	if not steps_problem.is_empty():
		return steps_problem
	var rewards_problem := QuestStep.rewards_problem(quest.get("rewards", {}))
	return "" if rewards_problem.is_empty() else "quête : " + rewards_problem


static func _requires_problem(value: Variant) -> String:
	if not value is Dictionary:
		return "« requires » doit être un objet {quests, flags, not_flags}"
	var requires: Dictionary = value
	var unknown := QuestStep.unknown_key(requires, REQUIRE_KEYS)
	if not unknown.is_empty():
		return "clé inconnue « %s » dans « requires »" % unknown
	for key: String in REQUIRE_KEYS:
		if requires.has(key) and not QuestStep.is_name_list(requires[key]):
			return "« requires.%s » doit être une liste d'identifiants" % key
	return ""


static func _steps_problem(value: Variant) -> String:
	if not value is Array or (value as Array).is_empty():
		return "« steps » doit être une liste d'au moins une étape"
	var ids: Dictionary[String, bool] = {}
	var index := 0
	for step: Variant in value:
		index += 1
		var step_problem := QuestStep.problem(step, "étape %d" % index)
		if not step_problem.is_empty():
			return step_problem
		var step_id: String = (step as Dictionary)["id"]
		if ids.has(step_id):
			return "étape %d : l'id « %s » est déjà pris dans cette quête" % [index, step_id]
		ids[step_id] = true
	return ""


## Quête construite depuis un objet JSON déjà vérifié par problem().
static func from_dict(data: Dictionary) -> QuestData:
	var quest := QuestData.new()
	quest.id = StringName(data["id"])
	quest.title = data["title"]
	quest.summary = data.get("summary", "")
	quest.giver_npc = StringName(data.get("giver", ""))
	quest.main = data.get("main", false)
	quest.auto_start = data.get("auto_start", false)
	var requires: Dictionary = data.get("requires", {})
	quest.prereq_quests = QuestStep.read_names(requires.get("quests", []))
	quest.prereq_flags = QuestStep.read_names(requires.get("flags", []))
	quest.prereq_not_flags = QuestStep.read_names(requires.get("not_flags", []))
	for step_data: Dictionary in data["steps"]:
		quest.steps.append(QuestStep.from_dict(step_data))
	quest.objective = quest.steps[0].objective
	var rewards: Dictionary = data.get("rewards", {})
	quest.reward_items = QuestStep.read_items(rewards.get("items", {}))
	quest.reward_flags = QuestStep.read_names(rewards.get("flags", []))
	quest.reward_max_hp = int(rewards.get("max_hp", 0))
	return quest


# --- Lecture de l'avancement (GameState) -------------------------------------------------------


## Rang de l'étape step_id (-1 si elle n'existe pas).
func step_index(step_id: StringName) -> int:
	for index: int in steps.size():
		if steps[index].id == step_id:
			return index
	return -1


## Étape step_id, null si elle n'existe pas.
func find_step(step_id: StringName) -> QuestStep:
	var index := step_index(step_id)
	return steps[index] if index >= 0 else null


## Rang de l'étape courante : celle de GameState pour une quête active (la première si aucune
## n'est enregistrée ou si elle n'existe plus), steps.size() pour une quête terminée, -1 sinon.
func current_index() -> int:
	match GameState.quest_state(id):
		GameState.QUEST_ACTIVE:
			return maxi(step_index(GameState.quest_step(id)), 0)
		GameState.QUEST_DONE:
			return steps.size()
	return -1


## Étape courante d'une quête active, null sinon.
func current_step() -> QuestStep:
	var index := current_index()
	return steps[index] if index >= 0 and index < steps.size() else null


## Objectif à afficher : celui de l'étape courante, sinon l'objectif général.
func current_objective() -> String:
	var step := current_step()
	return step.objective if step != null else objective


## Progression de l'étape courante (« Fragment de page : 3/5 »), "" sans progression chiffrée.
func current_progress() -> String:
	var step := current_step()
	return step.progress_text(GameState.quest_step_count(id)) if step != null else ""


## Vrai si les prérequis sont remplis : quêtes terminées, drapeaux posés et drapeaux absents.
func prerequisites_met() -> bool:
	for quest_id: StringName in prereq_quests:
		if GameState.quest_state(quest_id) != GameState.QUEST_DONE:
			return false
	for flag: StringName in prereq_flags:
		if not GameState.has_flag(flag):
			return false
	for flag: StringName in prereq_not_flags:
		if GameState.has_flag(flag):
			return false
	return true


## État vu par le joueur : &"done", &"active", &"available" (pas encore commencée, prérequis
## remplis) ou &"" (verrouillée).
func status() -> StringName:
	var state := GameState.quest_state(id)
	if not state.is_empty():
		return state
	return GameState.QUEST_AVAILABLE if prerequisites_met() else &""


func is_available() -> bool:
	return status() == GameState.QUEST_AVAILABLE


# --- Requêtes pour l'interface et les PNJ ------------------------------------------------------


## État vu par le joueur de quest_id (status()) ; l'état brut de GameState si elle n'a pas de
## données.
static func state_of(quest_id: StringName) -> StringName:
	var quest := find(quest_id)
	return quest.status() if quest != null else GameState.quest_state(quest_id)


## Marqueur au-dessus du PNJ npc_id : MARKER_TURN_IN (« ? ») si l'étape courante d'une quête
## active se valide en lui parlant (talk, ou collect « rapporter à » avec les objets en poche),
## sinon MARKER_AVAILABLE (« ! ») s'il donne une quête disponible (hors auto_start), sinon &"".
static func npc_marker(npc_id: StringName) -> StringName:
	if npc_id.is_empty():
		return &""
	var available := false
	for quest: QuestData in all():
		if GameState.quest_state(quest.id) == GameState.QUEST_ACTIVE:
			var step := quest.current_step()
			if step != null and step.involves_npc(npc_id) and step.has_items():
				return MARKER_TURN_IN
		elif quest.giver_npc == npc_id and not quest.auto_start and quest.is_available():
			available = true
	return MARKER_AVAILABLE if available else &""


## Quêtes actives dans l'ordre du journal : principales d'abord, puis dans l'ordre où elles ont
## commencé (GameState.quests()). Une quête sans données (retirée du jeu, comme « pages » dans
## une sauvegarde d'avant l'acte 1) n'y est pas : ni au journal, ni dans le « +n quêtes » du HUD.
static func active_ids() -> Array[StringName]:
	return _ids_in_state(GameState.QUEST_ACTIVE)


## Quêtes terminées, même ordre (principales d'abord), sans les quêtes sans données.
static func done_ids() -> Array[StringName]:
	return _ids_in_state(GameState.QUEST_DONE)


## Quête affichée par le HUD : la quête suivie si elle est active, sinon la première quête
## active (&"" s'il n'y en a pas).
static func shown_quest() -> StringName:
	var active := active_ids()
	if active.has(GameState.tracked_quest):
		return GameState.tracked_quest
	return active[0] if not active.is_empty() else &""


static func _ids_in_state(state: StringName) -> Array[StringName]:
	var main_ids: Array[StringName] = []
	var other_ids: Array[StringName] = []
	var states := GameState.quests()
	for quest_id: StringName in states:
		if states[quest_id] != state:
			continue
		var quest := find(quest_id)
		if quest == null:
			continue
		if quest.main:
			main_ids.append(quest_id)
		else:
			other_ids.append(quest_id)
	main_ids.append_array(other_ids)
	return main_ids
