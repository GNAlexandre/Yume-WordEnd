class_name QuestStep
extends Resource
## Étape d'une quête : un élément de la liste « steps » de data/quests/<id>.json. Propriétaire :
## Lot Q (moteur de quêtes). Format complet, exemples et règles d'écriture : docs/QUETES.md.
##
## Une quête active a une étape courante (GameState.quest_step) ; le QuestTracker la valide
## selon son type, donne sa récompense éventuelle, puis passe à la suivante (la dernière termine
## la quête). Champs communs : id, type, objective (texte du HUD et du journal), hint (aide du
## journal, facultative), rewards (facultatives : items, flags, max_hp). Champs par type :
## - talk    : npc — validée à la fin d'un dialogue avec ce PNJ commencé pendant l'étape, ou par
##             l'effet de dialogue advance_quest ;
## - reach   : zone ou trigger (un seul) — le joueur entre dans la zone (ou s'y trouve déjà quand
##             l'étape commence) ou dans le déclencheur (src/quests/quest_trigger.tscn) ;
## - kill    : enemy (id d'EnemyData, "any" par défaut), count (1), zone (facultative : zone où
##             se trouve le joueur au moment du coup fatal) — ennemis vaincus pendant l'étape ;
## - collect : item, count (1), consume (false), npc (facultatif) — sans npc, validée dès que le
##             joueur possède count objets ; avec npc (« rapporter à »), à la fin d'un dialogue
##             avec ce PNJ s'il les possède ; consume : objets retirés à la validation ;
## - arena   : arena, et wave ou score (un seul) — vague commencée ou score atteint pendant une
##             série de l'arène, pendant l'étape ;
## - flag    : flag — validée dès que le drapeau est posé (aussi s'il l'était déjà).

const TALK := &"talk"
const REACH := &"reach"
const KILL := &"kill"
const COLLECT := &"collect"
const ARENA := &"arena"
const FLAG := &"flag"
const TYPES: Array[StringName] = [TALK, REACH, KILL, COLLECT, ARENA, FLAG]
## Ennemi quelconque (étape kill).
const ANY_ENEMY := &"any"
## Clés JSON communes à toutes les étapes, puis propres à chaque type.
const COMMON_KEYS: Array[String] = ["id", "type", "objective", "hint", "rewards"]
const TYPE_KEYS := {
	TALK: ["npc"],
	REACH: ["zone", "trigger"],
	KILL: ["enemy", "count", "zone"],
	COLLECT: ["item", "count", "consume", "npc"],
	ARENA: ["arena", "wave", "score"],
	FLAG: ["flag"],
}
## Clés de « rewards » (étape ou quête).
const REWARD_KEYS: Array[String] = ["items", "flags", "max_hp"]
const ENEMIES_DIR := "res://data/enemies"

## Identifiant, unique dans la quête (conditions quest_step des dialogues, sauvegarde).
@export var id: StringName
## talk, reach, kill, collect, arena ou flag.
@export var type: StringName
## Objectif affiché par le HUD et le journal, ex. « Vaincre 2 Timeres dans la forêt ».
@export var objective: String = ""
## Aide affichée par le journal sous l'objectif (facultative).
@export var hint: String = ""
## PNJ (NpcData.id) : à qui parler (talk), à qui rapporter les objets (collect).
@export var npc: StringName
## Zone (zone_id) à atteindre (reach) ou où vaincre les ennemis (kill, facultative).
@export var zone: StringName
## Déclencheur (QuestTrigger.trigger_id) à atteindre (reach).
@export var trigger: StringName
## Ennemi à vaincre (EnemyData.id) ou ANY_ENEMY (kill).
@export var enemy: StringName = ANY_ENEMY
## Objet à posséder ou rapporter (collect).
@export var item: StringName
## Nombre d'ennemis (kill) ou d'objets (collect).
@export var count: int = 1
## Objets retirés de l'inventaire à la validation (collect).
@export var consume: bool = false
## Arène (Arena.arena_id) d'une étape arena.
@export var arena: StringName
## Vague à atteindre (arena) ; 0 : l'étape vise un score.
@export var wave: int = 0
## Score à atteindre pendant une série (arena) ; 0 : l'étape vise une vague.
@export var score: int = 0
## Drapeau attendu (flag).
@export var flag: StringName
## Récompense de l'étape, donnée à sa validation : objets, drapeaux posés, PV max (0 : aucun).
@export var reward_items: Dictionary[StringName, int] = {}
@export var reward_flags: Array[StringName] = []
@export var reward_max_hp: int = 0


## Étape construite depuis un objet JSON déjà vérifié par problem().
static func from_dict(data: Dictionary) -> QuestStep:
	var step := QuestStep.new()
	step.id = StringName(data["id"])
	step.type = StringName(data["type"])
	step.objective = data["objective"]
	step.hint = data.get("hint", "")
	step.npc = StringName(data.get("npc", ""))
	step.zone = StringName(data.get("zone", ""))
	step.trigger = StringName(data.get("trigger", ""))
	step.enemy = StringName(data.get("enemy", ANY_ENEMY))
	step.item = StringName(data.get("item", ""))
	step.count = int(data.get("count", 1))
	step.consume = data.get("consume", false)
	step.arena = StringName(data.get("arena", ""))
	step.wave = int(data.get("wave", 0))
	step.score = int(data.get("score", 0))
	step.flag = StringName(data.get("flag", ""))
	var rewards: Dictionary = data.get("rewards", {})
	step.reward_items = read_items(rewards.get("items", {}))
	step.reward_flags = read_names(rewards.get("flags", []))
	step.reward_max_hp = int(rewards.get("max_hp", 0))
	return step


## Premier problème d'une étape JSON (where situe l'étape dans le message), "" si elle est valide.
static func problem(data: Variant, where: String) -> String:
	if not data is Dictionary:
		return "%s : une étape doit être un objet" % where
	var step: Dictionary = data
	if not is_name(step.get("id")):
		return "%s : « id » doit être un identifiant (lettres, chiffres, _)" % where
	where = "%s « %s »" % [where, step["id"]]
	var type_name: Variant = step.get("type")
	if not (type_name is String and TYPES.has(StringName(type_name))):
		return "%s : « type » doit valoir %s" % [where, ", ".join(TYPES)]
	var allowed: Array = COMMON_KEYS.duplicate()
	allowed.append_array(TYPE_KEYS[StringName(type_name)])
	var unknown := unknown_key(step, allowed)
	if not unknown.is_empty():
		return "%s : clé inconnue « %s » pour une étape %s" % [where, unknown, type_name]
	if not (step.get("objective") is String and not (step["objective"] as String).is_empty()):
		return "%s : « objective » (texte du HUD) est obligatoire" % where
	if step.has("hint") and not step["hint"] is String:
		return "%s : « hint » doit être un texte" % where
	var reward_problem := rewards_problem(step.get("rewards", {}))
	if not reward_problem.is_empty():
		return "%s : %s" % [where, reward_problem]
	var type_problem := _type_problem(StringName(type_name), step)
	return "" if type_problem.is_empty() else "%s : %s" % [where, type_problem]


static func _type_problem(step_type: StringName, step: Dictionary) -> String:
	var problems: Array[String] = []
	match step_type:
		TALK:
			problems.append(_require_name(step, "npc"))
		REACH:
			if step.has("zone") == step.has("trigger"):
				return "une étape reach a « zone » ou « trigger » (un seul)"
			problems.append(_require_name(step, "zone" if step.has("zone") else "trigger"))
		KILL:
			if step.has("enemy") and not is_name(step["enemy"]):
				return '« enemy » doit être un id d\'ennemi ou "any"'
			problems.append(_optional_name(step, "zone"))
			problems.append(_optional_count(step, "count"))
		COLLECT:
			problems.append(_require_name(step, "item"))
			problems.append(_optional_count(step, "count"))
			if step.has("consume") and not step["consume"] is bool:
				problems.append("« consume » doit valoir true ou false")
			problems.append(_optional_name(step, "npc"))
		ARENA:
			if step.has("wave") == step.has("score"):
				return "une étape arena a « wave » ou « score » (un seul)"
			problems.append(_require_name(step, "arena"))
			problems.append(_optional_count(step, "wave" if step.has("wave") else "score"))
		FLAG:
			problems.append(_require_name(step, "flag"))
	for problem_text: String in problems:
		if not problem_text.is_empty():
			return problem_text
	return ""


static func _require_name(step: Dictionary, key: String) -> String:
	return "" if is_name(step.get(key)) else "« %s » doit être un identifiant" % key


static func _optional_name(step: Dictionary, key: String) -> String:
	return (
		"" if not step.has(key) or is_name(step[key]) else "« %s » doit être un identifiant" % key
	)


static func _optional_count(step: Dictionary, key: String) -> String:
	if not step.has(key) or read_int(step[key]) >= 1:
		return ""
	return "« %s » doit être un entier au moins égal à 1" % key


# --- Outils de lecture JSON, partagés avec QuestData -----------------------------------------


## Identifiant écrit dans un JSON : texte non vide de lettres, chiffres et _ (pas de chiffre au
## début), ex. "page_fragment".
static func is_name(value: Variant) -> bool:
	return value is String and (value as String).is_valid_ascii_identifier()


## Entier d'un JSON (les nombres y sont des float : 5.0 → 5) ; -1 si ce n'en est pas un.
static func read_int(value: Variant) -> int:
	if value is int:
		return value
	if value is float and is_finite(value) and value == floorf(value):
		return int(value)
	return -1


## Vrai pour un identifiant ou une liste d'identifiants (éventuellement vide).
static func is_name_list(value: Variant) -> bool:
	var values: Array = value if value is Array else [value]
	for entry: Variant in values:
		if not is_name(entry):
			return false
	return true


## Liste d'identifiants (ou un seul) → Array[StringName] ; [] si la valeur est mal formée.
static func read_names(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	var values: Array = value if value is Array else [value]
	for entry: Variant in values:
		if not is_name(entry):
			return [] as Array[StringName]
		result.append(StringName(entry))
	return result


## Objet {objet: quantité} → Dictionary[StringName, int] (entrées invalides ignorées).
static func read_items(value: Variant) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	if value is Dictionary:
		for key: Variant in value:
			if is_name(key) and read_int(value[key]) >= 1:
				result[StringName(key)] = read_int(value[key])
	return result


## Première clé de data hors de allowed (les clés qui commencent par « _ » sont des
## commentaires, toujours permis), "" s'il n'y en a pas.
static func unknown_key(data: Dictionary, allowed: Array) -> String:
	for key: Variant in data:
		if not key is String or (not allowed.has(key) and not (key as String).begins_with("_")):
			return str(key)
	return ""


## Problème d'un objet « rewards » (quête ou étape), "" s'il est valide.
static func rewards_problem(value: Variant) -> String:
	if not value is Dictionary:
		return "« rewards » doit être un objet {items, flags, max_hp}"
	var rewards: Dictionary = value
	var unknown := unknown_key(rewards, REWARD_KEYS)
	if not unknown.is_empty():
		return "clé inconnue « %s » dans « rewards »" % unknown
	if rewards.has("items"):
		if not rewards["items"] is Dictionary:
			return "« rewards.items » doit être un objet {objet: quantité}"
		if read_items(rewards["items"]).size() != (rewards["items"] as Dictionary).size():
			return "« rewards.items » : identifiants et quantités entières (au moins 1)"
	if rewards.has("flags") and not is_name_list(rewards["flags"]):
		return "« rewards.flags » doit être une liste d'identifiants"
	if rewards.has("max_hp") and read_int(rewards["max_hp"]) < 1:
		return "« rewards.max_hp » doit être un entier au moins égal à 1"
	return ""


# --- Avancement (lit GameState) ----------------------------------------------------------------


## Objectif chiffré de l'étape : objets (collect), ennemis (kill), vague ou score (arena) ; 0
## pour les étapes sans progression (talk, reach, flag).
func target() -> int:
	match type:
		COLLECT, KILL:
			return maxi(count, 1)
		ARENA:
			return wave if wave > 0 else score
	return 0


## Progression actuelle, entre 0 et target() : objets possédés (collect), sinon le compteur de
## l'étape (GameState.quest_step_count : ennemis vaincus, meilleure vague ou meilleur score).
func progress(counter: int) -> int:
	var value := GameState.count(item) if type == COLLECT else counter
	return clampi(value, 0, target())


## Texte de progression du HUD et du journal (« Fragment de page : 3/5 », « Ennemis vaincus :
## 1/2 », « Vague atteinte : 2/3 », « Score : 120/300 ») ; "" sans progression chiffrée.
func progress_text(counter: int) -> String:
	if target() <= 0:
		return ""
	var label := ""
	match type:
		COLLECT:
			label = ItemData.display_name_of(item)
		KILL:
			label = "Ennemis vaincus" if enemy == ANY_ENEMY else enemy_display_name(enemy)
		ARENA:
			label = "Vague atteinte" if wave > 0 else "Score"
	return "%s : %d/%d" % [label, progress(counter), target()]


## Vrai si l'étape se valide en parlant à npc_id (talk, ou collect avec « npc »).
func involves_npc(npc_id: StringName) -> bool:
	return not npc.is_empty() and npc == npc_id and (type == TALK or type == COLLECT)


## Vrai si les objets demandés sont dans l'inventaire (collect ; toujours vrai sinon).
func has_items() -> bool:
	return type != COLLECT or GameState.count(item) >= maxi(count, 1)


## Vrai si l'état de la partie suffit à valider l'étape, sans attendre d'événement : objets
## possédés (collect sans npc), drapeau posé (flag), joueur déjà dans la zone (reach zone).
func is_met_by_state() -> bool:
	match type:
		COLLECT:
			return npc.is_empty() and has_items()
		FLAG:
			return GameState.has_flag(flag)
		REACH:
			return not zone.is_empty() and GameState.zone == zone
	return false


## Nom affiché d'un ennemi (EnemyData.display_name), ou son id s'il est inconnu.
static func enemy_display_name(enemy_id: StringName) -> String:
	var path := "%s/%s.tres" % [ENEMIES_DIR, enemy_id]
	if String(enemy_id).is_valid_ascii_identifier() and ResourceLoader.exists(path):
		var data := load(path) as EnemyData
		if data != null and not data.display_name.is_empty():
			return data.display_name
	return String(enemy_id)
