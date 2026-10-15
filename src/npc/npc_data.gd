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
## (E4) Tenues : nom de la tenue (« maison », « cuisine », « pyjama »… : la clé « outfit » d'une
## ligne d'emploi du temps, data/life/<id>.json) → chemin d'une SkinData complète à trois vues
## (data/npcs/outfits/<planche>.tres). Chargée à la demande (load_outfit), libérée quand plus
## aucun visuel ne l'affiche : une planche par tenue en mémoire. La tenue par défaut, sans nom,
## est skin.
@export var outfits: Dictionary[StringName, String] = {}


## (E4) Chemin de la SkinData de la tenue outfit ("" : tenue inconnue ; nom vide : celle de skin).
func outfit_path(outfit: StringName) -> String:
	if outfit.is_empty():
		return skin.resource_path if skin != null else ""
	return outfits.get(outfit, "")


## (E4) Vrai si le PNJ a cette tenue (nom vide : la tenue par défaut, skin).
func has_outfit(outfit: StringName) -> bool:
	return outfit.is_empty() or outfits.has(outfit)


## (E4) SkinData de la tenue outfit, chargée à la demande (skin pour un nom vide ou une tenue
## inconnue).
func load_outfit(outfit: StringName) -> SkinData:
	var path := outfit_path(outfit)
	if outfit.is_empty() or path.is_empty() or not ResourceLoader.exists(path):
		return skin
	var loaded := load(path) as SkinData
	return loaded if loaded != null else skin


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
