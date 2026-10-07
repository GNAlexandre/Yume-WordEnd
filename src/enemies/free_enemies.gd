extends Node3D
## Racine « Enemies » d'un fichier d'emplacement (src/enemies/placements/<zone>.tscn) : les
## ennemis libres de la zone (PLAN.md section 3). Propriétaire : L5 ; (acte 1, intégration).
##
## Un ennemi libre tué disparaît pour la session (Enemy.queue_free) : la zone n'est jamais
## rechargée en M2. Une étape « vaincre » qui les vise doit pourtant toujours pouvoir être menée
## (les rejetons des bois, étape rejetons d'act1_main : quatre à abattre, quatre dans les bois),
## même si le joueur en a tué avant l'étape, ou hors de la zone (un kill ne compte que dans la
## zone du joueur). Donc, pendant une étape kill d'une quête active qui vise cette zone (son
## « zone », ou aucune) et ses ennemis (« any » ou l'id de l'un d'eux), les ennemis tués
## réapparaissent à leur place d'origine, avec leurs données : au début de l'étape, et à chaque
## retour du joueur dans la zone. Jamais plus que la population de départ ; hors de ces étapes,
## les morts restent morts (les bois se vident jusqu'au rechargement de la partie).

## Ennemis de départ : nom du nœud → {scene, data, transform}.
var _roster: Dictionary[StringName, Dictionary] = {}
var _zone_id: StringName = &""
var _respawn_pending: bool = false


func _ready() -> void:
	var zone := get_parent() as Zone
	_zone_id = zone.zone_id() if zone != null else &""
	for child: Node in get_children():
		var enemy := child as Enemy
		if enemy != null and enemy.data != null and not enemy.scene_file_path.is_empty():
			_roster[StringName(enemy.name)] = {
				"scene": enemy.scene_file_path,
				"data": enemy.data,
				"transform": enemy.transform,
			}
	EventBus.quest_step_updated.connect(_on_quest_step_updated)
	EventBus.zone_entered.connect(_on_zone_entered)


## Zone de ces ennemis (&"" hors d'une zone : rien ne réapparaît).
func zone_id() -> StringName:
	return _zone_id


## Ennemis vivants (ni morts, ni libérés) de la population de départ.
func alive_count() -> int:
	var alive := 0
	for enemy_name: StringName in _roster:
		var enemy := get_node_or_null(NodePath(String(enemy_name))) as Enemy
		if enemy != null and not enemy.is_dead() and not enemy.is_queued_for_deletion():
			alive += 1
	return alive


## Vrai si une étape kill en cours vise cette zone et ces ennemis.
func is_hunted() -> bool:
	if _zone_id.is_empty():
		return false
	for quest_id: StringName in QuestData.active_ids():
		var quest := QuestData.find(quest_id)
		if quest != null and _hunts(quest.current_step()):
			return true
	return false


## Fait réapparaître tout de suite, à leur place d'origine, les ennemis tués de la population de
## départ ; renvoie leur nombre. Un cadavre encore là est retiré.
func respawn_dead() -> int:
	_respawn_pending = false
	var spawned := 0
	for enemy_name: StringName in _roster:
		var current := get_node_or_null(NodePath(String(enemy_name))) as Enemy
		if current != null and not current.is_dead() and not current.is_queued_for_deletion():
			continue
		if current != null:
			remove_child(current)
			current.queue_free()
		var spec: Dictionary = _roster[enemy_name]
		var packed := load(spec["scene"] as String) as PackedScene
		var enemy := packed.instantiate() as Enemy
		enemy.name = enemy_name
		enemy.data = spec["data"]
		enemy.transform = spec["transform"]
		add_child(enemy)
		spawned += 1
	return spawned


func _hunts(step: QuestStep) -> bool:
	if step == null or step.type != QuestStep.KILL:
		return false
	if not step.zone.is_empty() and step.zone != _zone_id:
		return false
	if step.enemy == QuestStep.ANY_ENEMY:
		return true
	for enemy_name: StringName in _roster:
		if (_roster[enemy_name]["data"] as EnemyData).id == step.enemy:
			return true
	return false


## En fin d'image : les signaux de la même image (début d'étape, entrée dans la zone) regroupés,
## et l'arbre jamais modifié pendant l'émission d'un signal de mort ou de quête.
func _schedule_respawn() -> void:
	if not _respawn_pending:
		_respawn_pending = true
		_respawn_if_hunted.call_deferred()


func _respawn_if_hunted() -> void:
	_respawn_pending = false
	if is_inside_tree() and is_hunted():
		respawn_dead()


func _on_quest_step_updated(quest_id: StringName, step_id: StringName, count: int) -> void:
	if count != 0 or step_id.is_empty():
		return
	var quest := QuestData.find(quest_id)
	if quest != null and _hunts(quest.find_step(step_id)):
		_schedule_respawn()


func _on_zone_entered(entered: StringName) -> void:
	if entered == _zone_id:
		_schedule_respawn()
