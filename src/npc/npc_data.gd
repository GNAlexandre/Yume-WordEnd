class_name NpcData
extends Resource
## Personnage non joueur. Fichiers : data/npcs/<id>.tres. Propriétaire : L6.
##
## (Systèmes et textes) Présence selon l'histoire : visible_if, même grammaire et même évaluateur
## que le « if » d'un nœud de dialogue (DialogueRunner.evaluate : drapeaux, objets, état et étape
## de quête, meilleur score ; docs/QUETES.md). Un PNJ absent (is_present() faux) est caché par
## Npc : ni visuel, ni collision, ni dialogue, ni marqueur. Le PNJ dont le skin est celui du
## joueur est toujours absent : la fée choisie comme héroïne n'est pas aussi un PNJ.

## Identifiant, ex. &"nygglatho" (transmis par EventBus.dialogue_started / dialogue_ended).
@export var id: StringName
## Nom affiché (locuteur par défaut).
@export var display_name: String = ""
## Apparence (un skin de data/skins/, partagé avec les skins jouables).
@export var skin: SkinData
## Dialogue au format JSON de PLAN.md section 4 (data/dialogues/<id>.json).
@export_file("*.json") var dialogue_path: String = ""
## Quête donnée par ce PNJ (data/quests/<id>.tres), &"" si aucune.
@export var quest_id: StringName
## Zone où il vit (zone_id).
@export var home_zone: StringName = &"village"
## (Systèmes et textes) Condition de présence, comme un « if » de dialogue ; {} : toujours là.
## Ex. {"quest_step": ["act1_main", "training"]} : seulement pendant cette étape ;
## {"not_quest_step": ["act1_main", ["training", "promise"]]} : sauf pendant ces étapes.
@export var visible_if: Dictionary = {}


## Vrai si le PNJ doit être là : son skin n'est pas celui du joueur et visible_if est vraie.
func is_present() -> bool:
	if is_player_skin():
		return false
	return visible_if.is_empty() or DialogueRunner.evaluate(visible_if)


## Vrai si le skin du PNJ est celui du joueur (DialogueRunner.player_skin() : GameState.skin_id,
## sinon le skin par défaut).
func is_player_skin() -> bool:
	if skin == null or skin.id.is_empty():
		return false
	var player_skin := DialogueRunner.player_skin()
	return player_skin != null and player_skin.id == skin.id


## Problème de visible_if (DialogueRunner.condition_problem), "" si elle est valide.
func visible_if_problem() -> String:
	return DialogueRunner.condition_problem(visible_if)
