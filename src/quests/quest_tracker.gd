class_name QuestTracker
extends Node
## Moteur de quêtes : fait avancer les quêtes en étapes (data/quests/*.json, voir QuestData et
## QuestStep) en écoutant l'EventBus, donne les récompenses et enchaîne les quêtes. Propriétaires :
## L7, puis Lot Q. Un seul, nœud « QuestTracker » de src/game.tscn : seul le premier nœud du
## groupe quest_tracker agit, pour qu'une récompense ne soit jamais donnée deux fois. Règles
## d'écriture : docs/QUETES.md.
##
## Démarrage : une quête devient active par GameState.set_quest_state(id, &"active") (effet de
## dialogue start_quest), ou toute seule (auto_start) dès que ses prérequis sont remplis ; son
## étape courante est alors la première, et elle devient la quête suivie (tracked_quest).
## Validation de l'étape courante, selon son type :
## - talk, collect avec npc : dialogue_ended de ce PNJ, si l'étape était déjà l'étape courante à
##   son dialogue_started (le dialogue qui démarre une quête ne valide pas sa première étape) ;
##   collect : seulement si le joueur a les objets ;
## - reach : zone_entered, trigger_entered, ou joueur déjà dans la zone ;
## - kill : enemy_killed qui correspond (ennemi, zone du joueur GameState.zone) ;
## - collect sans npc, flag : état de GameState, vérifié dès que l'étape commence puis à chaque
##   inventory_changed ou flag_changed ;
## - arena : wave_started, arena_score_changed, arena_finished de l'arène ;
## - toute étape : quest_advance_requested (effet de dialogue advance_quest ; collect : il faut
##   les objets).
## Étape validée : objets retirés (collect avec consume), récompense de l'étape,
## quest_step_completed, puis étape suivante (GameState.set_quest_step) ; après la dernière :
## objets de required_items retirés (héritage L7), récompense de la quête, état &"done",
## quest_completed, et la quête suivie passe à la première quête active.
## Fin forcée (effet complete_quest, ou GameState.set_quest_state(id, &"done") par un autre
## système) : les étapes restantes sont validées d'office si le joueur a les objets des étapes
## collect restantes (et de required_items, avec les drapeaux de required_flags) ; sinon la
## quête revient à &"active" à la même étape (completion_refused et push_warning). Vérification
## et récompense sont synchrones pendant l'émission de quest_updated : un écouteur branché après
## le tracker qui reçoit &"done" pour une quête refusée doit relire GameState.quest_state().
## Après chaque traitement, les vérifications d'état sont relancées jusqu'à stabilité : étapes
## validées par l'état de la partie, quêtes auto_start. Les événements reçus pendant un
## traitement (signaux émis par ses propres changements) sont mis en file et traités ensuite,
## dans l'ordre : jamais de traitement imbriqué, jamais de double validation.

## Quête terminée, récompense donnée.
signal quest_completed(quest_id: StringName)
## Fin forcée refusée (quête remise à &"active") ; missing_items : item_id → quantité manquante.
signal completion_refused(quest_id: StringName, missing_items: Dictionary)

const QUESTS_DIR := QuestData.DATA_DIR
const GROUP := &"quest_tracker"
## Garde-fou des vérifications en chaîne (données qui se valideraient en boucle).
const MAX_SETTLE_ROUNDS := 200

var _queue: Array[Callable] = []
var _running: bool = false
## Vrai pendant que le tracker change lui-même l'état d'une quête (son quest_updated est ignoré).
var _self_update: bool = false
## Étapes à valider à la fin du dialogue en cours (quest_id → step_id), relevées à son début.
var _talks: Dictionary[StringName, StringName] = {}
var _talk_npc: StringName = &""


func _ready() -> void:
	add_to_group(GROUP)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.quest_advance_requested.connect(_on_advance_requested)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)
	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.trigger_entered.connect(_on_trigger_entered)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.arena_score_changed.connect(_on_arena_score_changed)
	EventBus.arena_finished.connect(_on_arena_finished)
	EventBus.inventory_changed.connect(_on_state_changed)
	EventBus.flag_changed.connect(_on_flag_changed)
	EventBus.game_loaded.connect(_on_game_loaded)
	_run(_sync)


## Vrai pour le tracker qui agit : le premier nœud du groupe quest_tracker.
func is_leader() -> bool:
	return is_inside_tree() and get_tree().get_first_node_in_group(GROUP) == self


# --- Requêtes (statiques, testables sans scène) ------------------------------------------------


## Objets qui manquent pour terminer quest maintenant (fin forcée) : item_id → quantité
## manquante, vide si rien. Compte les étapes collect pas encore validées (dans l'ordre, les
## objets consommés par l'une ne servent plus aux suivantes) puis required_items (héritage L7).
static func missing_items(quest: QuestData) -> Dictionary:
	var requirements: Array[Array] = []
	for step: QuestStep in pending_steps(quest):
		if step.type == QuestStep.COLLECT:
			requirements.append([step.item, maxi(step.count, 1), step.consume])
	for item_id: StringName in quest.required_items:
		requirements.append([item_id, quest.required_items[item_id], true])
	var missing := {}
	var used: Dictionary[StringName, int] = {}
	for requirement: Array in requirements:
		var item_id: StringName = requirement[0]
		var needed: int = requirement[1]
		var already_used: int = used.get(item_id, 0)
		var lacking: int = needed - (GameState.count(item_id) - already_used)
		if lacking > 0:
			missing[item_id] = maxi(int(missing.get(item_id, 0)), lacking)
		if requirement[2]:
			used[item_id] = already_used + needed
	return missing


## Drapeaux de required_flags (héritage L7) que GameState n'a pas.
static func missing_flags(quest: QuestData) -> Array[StringName]:
	var missing: Array[StringName] = []
	for flag: StringName in quest.required_flags:
		if not GameState.has_flag(flag):
			missing.append(flag)
	return missing


## true si quest peut être terminée d'office maintenant (objets et drapeaux requis).
static func can_complete(quest: QuestData) -> bool:
	return missing_items(quest).is_empty() and missing_flags(quest).is_empty()


## Étapes pas encore validées : depuis l'étape enregistrée dans GameState (ou la première).
static func pending_steps(quest: QuestData) -> Array[QuestStep]:
	var start := maxi(quest.step_index(GameState.quest_step(quest.id)), 0)
	return quest.steps.slice(start)


# --- File de traitement -----------------------------------------------------------------------


## Exécute job, puis les vérifications d'état ; pendant un traitement, job attend son tour.
func _run(job: Callable) -> void:
	if not is_leader():
		return
	_queue.append(job)
	if _running:
		return
	_running = true
	while not _queue.is_empty():
		while not _queue.is_empty():
			var next: Callable = _queue.pop_front()
			next.call()
		_settle()
	_running = false


func _nothing() -> void:
	pass


## Remet l'avancement d'aplomb (partie chargée, scène qui démarre) : étape courante de chaque
## quête active (la première si aucune n'est enregistrée ou si elle n'existe plus), avancement
## des quêtes inactives oublié, quête suivie.
func _sync() -> void:
	for quest_id: StringName in QuestData.active_ids():
		var quest := QuestData.find(quest_id)
		if quest != null and quest.step_index(GameState.quest_step(quest_id)) < 0:
			GameState.set_quest_step(quest_id, quest.steps[0].id, 0)
	for quest_id: StringName in GameState.quest_progress():
		if GameState.quest_state(quest_id) != GameState.QUEST_ACTIVE:
			GameState.set_quest_step(quest_id, &"")
	_retrack()


## Vérifications d'état jusqu'à stabilité : quêtes auto_start, étapes validées par l'état.
func _settle() -> void:
	for _round: int in MAX_SETTLE_ROUNDS:
		if not _settle_once():
			return
	push_warning("QuestTracker : quêtes validées en boucle, vérifications arrêtées")


func _settle_once() -> bool:
	for quest: QuestData in QuestData.all():
		var state := GameState.quest_state(quest.id)
		var waiting := state.is_empty() or state == GameState.QUEST_AVAILABLE
		if quest.auto_start and waiting and quest.prerequisites_met():
			_set_state(quest.id, GameState.QUEST_ACTIVE)
			_start(quest, true)
			return true
	for quest_id: StringName in QuestData.active_ids():
		var quest := QuestData.find(quest_id)
		var step := quest.current_step() if quest != null else null
		if step != null and step.is_met_by_state() and _complete_step(quest, step):
			return true
	return false


# --- Événements -------------------------------------------------------------------------------


func _on_quest_updated(quest_id: StringName, state: StringName) -> void:
	if not _self_update:
		_run(_apply_state.bind(quest_id, state))


func _on_advance_requested(quest_id: StringName, step_id: StringName) -> void:
	_run(_advance.bind(quest_id, step_id))


func _on_dialogue_started(npc_id: StringName) -> void:
	_run(_note_talks.bind(npc_id))


func _on_dialogue_ended(npc_id: StringName) -> void:
	_run(_end_talks.bind(npc_id))


func _on_zone_entered(zone_id: StringName) -> void:
	_run(_reach.bind(zone_id, false))


func _on_trigger_entered(trigger_id: StringName) -> void:
	_run(_reach.bind(trigger_id, true))


func _on_enemy_killed(enemy_id: StringName, _points: int) -> void:
	_run(_count_kill.bind(enemy_id))


func _on_wave_started(arena_id: StringName, wave: int, _enemy_count: int) -> void:
	_run(_arena_progress.bind(arena_id, wave, true))


func _on_arena_score_changed(arena_id: StringName, score: int) -> void:
	_run(_arena_progress.bind(arena_id, score, false))


func _on_arena_finished(arena_id: StringName, score: int, _best: bool) -> void:
	_run(_arena_progress.bind(arena_id, score, false))


func _on_state_changed() -> void:
	_run(_nothing)


func _on_flag_changed(_flag: StringName, _value: bool) -> void:
	_run(_nothing)


func _on_game_loaded() -> void:
	_run(_sync)


# --- Traitements ------------------------------------------------------------------------------


## L'état de quest_id a été changé par un autre système (dialogue, code, test).
func _apply_state(quest_id: StringName, state: StringName) -> void:
	var quest := QuestData.find(quest_id)
	# Événement dépassé (l'état a encore changé depuis) ou quête sans données : rien à faire.
	if quest == null or GameState.quest_state(quest_id) != state:
		return
	match state:
		GameState.QUEST_DONE:
			_force_complete(quest)
		GameState.QUEST_ACTIVE:
			_start(quest, true)
		_:
			GameState.set_quest_step(quest_id, &"")
			_retrack()


## Quête qui devient active : sa première étape (sauf si une étape valide est déjà enregistrée) ;
## track : elle devient la quête suivie.
func _start(quest: QuestData, track: bool) -> void:
	if quest.step_index(GameState.quest_step(quest.id)) < 0:
		GameState.set_quest_step(quest.id, quest.steps[0].id, 0)
	if track:
		GameState.tracked_quest = quest.id


func _advance(quest_id: StringName, step_id: StringName) -> void:
	var quest := QuestData.find(quest_id)
	if quest == null or GameState.quest_state(quest_id) != GameState.QUEST_ACTIVE:
		push_warning("QuestTracker : advance_quest ignoré, « %s » n'est pas active" % quest_id)
		return
	var step := quest.current_step()
	if not step_id.is_empty() and step.id != step_id:
		return
	if not step.has_items():
		push_warning(
			(
				"QuestTracker : %s, étape « %s » : il faut %d × %s pour la valider"
				% [quest_id, step.id, step.count, step.item]
			)
		)
		return
	_complete_step(quest, step)


func _note_talks(npc_id: StringName) -> void:
	_talks.clear()
	_talk_npc = npc_id
	for quest_id: StringName in QuestData.active_ids():
		var quest := QuestData.find(quest_id)
		var step := quest.current_step() if quest != null else null
		if step != null and step.involves_npc(npc_id):
			_talks[quest_id] = step.id


func _end_talks(npc_id: StringName) -> void:
	var talks := _talks.duplicate()
	_talks.clear()
	if npc_id != _talk_npc:
		return
	for quest_id: StringName in talks:
		var quest := QuestData.find(quest_id)
		if quest == null or GameState.quest_state(quest_id) != GameState.QUEST_ACTIVE:
			continue
		var step := quest.current_step()
		if step != null and step.id == talks[quest_id] and step.has_items():
			_complete_step(quest, step)


## Zone (by_trigger faux) ou déclencheur atteint.
func _reach(target: StringName, by_trigger: bool) -> void:
	for quest_id: StringName in QuestData.active_ids():
		var quest := QuestData.find(quest_id)
		var step := quest.current_step() if quest != null else null
		if step == null or step.type != QuestStep.REACH:
			continue
		if (step.trigger if by_trigger else step.zone) == target:
			_complete_step(quest, step)


func _count_kill(enemy_id: StringName) -> void:
	for quest_id: StringName in QuestData.active_ids():
		var quest := QuestData.find(quest_id)
		var step := quest.current_step() if quest != null else null
		if step == null or step.type != QuestStep.KILL:
			continue
		if step.enemy != QuestStep.ANY_ENEMY and step.enemy != enemy_id:
			continue
		if not step.zone.is_empty() and step.zone != GameState.zone:
			continue
		var counter := GameState.quest_step_count(quest_id) + 1
		GameState.set_quest_step(quest_id, step.id, counter)
		if counter >= step.target():
			_complete_step(quest, step)


## Vague commencée (is_wave) ou score de la série courante de l'arène arena_id.
func _arena_progress(arena_id: StringName, value: int, is_wave: bool) -> void:
	for quest_id: StringName in QuestData.active_ids():
		var quest := QuestData.find(quest_id)
		var step := quest.current_step() if quest != null else null
		if step == null or step.type != QuestStep.ARENA or step.arena != arena_id:
			continue
		if (step.wave > 0) != is_wave:
			continue
		var counter := maxi(GameState.quest_step_count(quest_id), value)
		GameState.set_quest_step(quest_id, step.id, counter)
		if counter >= step.target():
			_complete_step(quest, step)


## Valide l'étape courante step de quest, puis passe à la suivante ou termine la quête.
## true si l'étape a été validée (false : il manquait des objets à retirer, rien n'a changé).
func _complete_step(quest: QuestData, step: QuestStep) -> bool:
	if not _validate(quest, step):
		return false
	var next := quest.step_index(step.id) + 1
	if next >= quest.steps.size():
		_finish(quest, true)
	else:
		GameState.set_quest_step(quest.id, quest.steps[next].id, 0)
	return true


## Objets retirés (collect avec consume), récompense de l'étape, quest_step_completed ; false
## (rien ne change) s'il manque des objets à retirer.
func _validate(quest: QuestData, step: QuestStep) -> bool:
	if step.type == QuestStep.COLLECT and step.consume:
		if not GameState.remove_item(step.item, maxi(step.count, 1)):
			return false
	_give(step.reward_items, step.reward_flags, step.reward_max_hp)
	EventBus.quest_step_completed.emit(quest.id, step.id)
	return true


## Fin forcée : la quête est passée à &"done" par un autre système.
func _force_complete(quest: QuestData) -> void:
	var missing := missing_items(quest)
	var flags := missing_flags(quest)
	if not missing.is_empty() or not flags.is_empty():
		var details := "%s %s" % [missing, flags]
		push_warning("QuestTracker : %s n'est pas terminée (manque %s)" % [quest.id, details])
		_set_state(quest.id, GameState.QUEST_ACTIVE)
		_start(quest, false)
		completion_refused.emit(quest.id, missing)
		return
	for step: QuestStep in pending_steps(quest):
		_validate(quest, step)
	_finish(quest, false)


## Fin de la quête : objets requis (héritage L7) retirés, récompense, avancement effacé, état
## &"done" (set_done : sinon il l'est déjà), quest_completed, quête suivie suivante.
func _finish(quest: QuestData, set_done: bool) -> void:
	for item_id: StringName in quest.required_items:
		GameState.remove_item(item_id, quest.required_items[item_id])
	_give(quest.reward_items, quest.reward_flags, quest.reward_max_hp)
	GameState.set_quest_step(quest.id, &"")
	if set_done:
		_set_state(quest.id, GameState.QUEST_DONE)
	quest_completed.emit(quest.id)
	_retrack()


func _give(items: Dictionary[StringName, int], flags: Array[StringName], max_hp: int) -> void:
	for item_id: StringName in items:
		GameState.add_item(item_id, items[item_id])
	for flag: StringName in flags:
		GameState.set_flag(flag)
	if max_hp > GameState.max_hp:
		GameState.max_hp = max_hp


func _set_state(quest_id: StringName, state: StringName) -> void:
	_self_update = true
	GameState.set_quest_state(quest_id, state)
	_self_update = false


## La quête suivie doit être active : sinon, la première quête active (ou aucune).
func _retrack() -> void:
	if not QuestData.active_ids().has(GameState.tracked_quest):
		GameState.tracked_quest = QuestData.shown_quest()
