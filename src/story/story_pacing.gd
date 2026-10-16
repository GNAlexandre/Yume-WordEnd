class_name StoryPacing
extends RefCounted
## (X-L0) Le rythme du récit : deux modes de jeu, « libre » (défaut du jeu) et « scénarisé » (le
## récit en jours tel qu'écrit par E6 et S2, au bit près). PLAN.md, « (X) Exploration libre : le
## rythme ». Propriétaire : X-L0.
##
## - Persistance : des drapeaux de partie, sans changer le schéma de la sauvegarde. FLAG
##   (« mode_scenario ») présent : scénarisé ; absent : libre. FREE_FLAG (« mode_libre ») marque
##   une partie commencée ou passée en libre ; une partie sans aucun des deux suit le mode par
##   défaut de StoryDirector (libre dans le jeu ; les tests en prennent un autre, comme enabled).
## - Une ancienne partie (d'avant les modes, sans drapeau) : libre, sauf si elle a déjà des scènes
##   faites : scénarisée, pour ne pas changer une partie en cours (migrate, au chargement).
## - Les règles du libre, toutes ici (le directeur ne fait que les appeler) :
##   - aucun déclencheur automatique (ready, enter, reach, talk) ne lance une scène, sauf une
##     suite (ready + after, ou free.chain) juste après sa tête, sur la même carte ; les invites
##     volontaires (prompt) et les objets examinés (examine) restent permis ;
##   - aucune porte fermée jusqu'à un jour (StoryStage.apply_doors : toutes ouvertes) ;
##   - une scène interrompue (partie reprise en pleine scène) n'est pas rejouée : elle redevient
##     disponible, sans retour forcé à sa carte ;
##   - nouvelle partie : pas d'écran noir, un carton « Jour 1 » (act.json, free.start_card), le
##     jour 1 au créneau free.start_slot.

const FREE := &"libre"
const SCENARIO := &"scenario"
const MODES: Array[StringName] = [FREE, SCENARIO]
## Drapeau de partie du mode scénarisé.
const FLAG := &"mode_scenario"
## Drapeau de partie du mode libre (partie commencée ou passée en libre).
const FREE_FLAG := &"mode_libre"
## Déclencheurs volontaires, permis en libre (le joueur les choisit).
const VOLUNTARY_TRIGGERS: Array[String] = ["prompt", "examine"]
## Créneau du jour 1 en libre sans free.start_slot (act.json).
const DEFAULT_FREE_SLOT := &"soir"
## Noms affichés des modes (repli des textes ui/mode_scenario, ui/mode_libre du récit).
const NAMES: Dictionary = {SCENARIO: "Mode scénarisé", FREE: "Mode libre"}


static func is_mode(value: StringName) -> bool:
	return MODES.has(value)


## Mode de la partie en cours : scénarisé si FLAG est posé, libre si FREE_FLAG l'est, sinon
## fallback (le mode par défaut).
static func of_game(fallback: StringName) -> StringName:
	if GameState.has_flag(FLAG):
		return SCENARIO
	if GameState.has_flag(FREE_FLAG):
		return FREE
	return fallback if is_mode(fallback) else FREE


## Écrit le mode dans la partie (ses drapeaux).
static func store(mode: StringName) -> void:
	GameState.set_flag(FLAG, mode == SCENARIO)
	GameState.set_flag(FREE_FLAG, mode == FREE)


## Partie chargée qui n'a aucun drapeau de mode (d'avant les modes) : scénarisée si elle a déjà
## des scènes faites (une partie en cours ne change pas de mode) ; vrai si elle l'a été.
static func migrate() -> bool:
	if GameState.has_flag(FLAG) or GameState.has_flag(FREE_FLAG):
		return false
	if GameState.scenes_done().is_empty():
		return false
	GameState.set_flag(FLAG, true)
	return true


## Vrai si la scène est une suite : elle s'enchaîne juste après sa tête (une de ses « after »)
## en libre. Par défaut ready + after ; la clé free.chain de la scène tranche sinon.
static func is_chained(data: Dictionary) -> bool:
	var settings: Variant = data.get("free", {})
	if settings is Dictionary and (settings as Dictionary).has("chain"):
		return (settings as Dictionary)["chain"] == true
	var trigger: Variant = data.get("trigger", {})
	var kind := str((trigger as Dictionary).get("on", "")) if trigger is Dictionary else ""
	return kind == "ready" and data.has("after")


## Vrai si le déclencheur de la scène peut la lancer. head : la dernière scène finie, quand on
## est encore sur la carte où elle a fini (&"" sinon) : sa suite peut partir.
static func allows_trigger(mode: StringName, data: Dictionary, head: StringName) -> bool:
	if mode != FREE:
		return true
	var trigger: Variant = data.get("trigger", {})
	var kind := str((trigger as Dictionary).get("on", "")) if trigger is Dictionary else ""
	if VOLUNTARY_TRIGGERS.has(kind):
		return true
	if head.is_empty() or not is_chained(data):
		return false
	var after: Variant = data.get("after", [])
	for item: Variant in after if after is Array else [after]:
		if str(item) == String(head):
			return true
	return false


## Vrai si les portes fermées jusqu'à un jour le sont (scénarisé) ; en libre, toutes ouvertes.
static func doors_by_day(mode: StringName) -> bool:
	return mode != FREE


## (L3) Vrai si un suiveur perdu est reposé derrière le joueur au lieu de s'arrêter (libre).
static func repose_lost(mode: StringName) -> bool:
	return mode == FREE


## Pose sur la mise en scène les règles du mode : portes fermées jusqu'à leur jour, suiveur perdu
## reposé derrière le joueur.
static func apply_to_stage(stage: StoryStage, mode: StringName) -> void:
	stage.doors_by_day = doors_by_day(mode)
	stage.repose_lost = repose_lost(mode)


## Vrai si une partie reprise en pleine scène la rejoue (scénarisé).
static func replays_interrupted(mode: StringName) -> bool:
	return mode != FREE


## Vrai si la nouvelle partie commence au noir (scénarisé : la première scène le lève).
static func starts_in_black(mode: StringName) -> bool:
	return mode != FREE


## Créneau du début de l'acte : start.slot (scénarisé), free.start_slot (libre).
static func start_slot(act: Dictionary, mode: StringName) -> StringName:
	var start: Dictionary = act.get("start", {})
	var slot := StringName(str(start.get("slot", "nuit")))
	if mode == FREE:
		var settings: Dictionary = act.get("free", {})
		slot = StringName(str(settings.get("start_slot", DEFAULT_FREE_SLOT)))
	return slot


## Vrai si la nouvelle partie montre le carton du jour (libre, free.start_card).
static func shows_start_card(act: Dictionary, mode: StringName) -> bool:
	if mode != FREE:
		return false
	var settings: Dictionary = act.get("free", {})
	return settings.get("start_card", true) == true


## La dernière scène finie (head) et la carte où elle a fini (map, &"" : pas encore connue, elle a
## fini pendant un changement de carte) : sa suite peut partir en libre tant que le joueur y est.
class Chain:
	extends RefCounted
	var head: StringName = &""
	var map: StringName = &""

	func clear() -> void:
		head = &""
		map = &""

	## Une scène finie : sa carte, sauf pendant un changement de carte (celle d'arrivée).
	func finished(scene_id: StringName) -> void:
		head = scene_id
		map = &"" if WorldManager.is_transitioning() else WorldManager.current_map()

	## Le joueur arrive sur map_id (hors scène) : une autre carte, la suite ne part plus seule.
	func entered(map_id: StringName) -> void:
		if not map.is_empty() and map != map_id:
			clear()

	## La tête si le joueur est encore sur sa carte, sinon &"".
	func head_on(map_id: StringName) -> StringName:
		if head.is_empty():
			return &""
		if map.is_empty():
			map = map_id
		return head if map == map_id else &""
