class_name MiniGames
extends RefCounted
## (E8) Lancer les jeux depuis le récit (lot E6), les démonstrations et le raccourci de
## développement `?jeu=` : fonctions statiques, sans état (pas d'autoload). Propriétaire : E8.
##
## - start_ball_match(options) : un match de ballon au champ de l'entrepôt avec les PNJ nommés
##   (par défaut Tiat, Lakhesh et trois fées chez les blanches, Collon, Pannibal et trois fées chez
##   les rouges, Willem à l'arbitrage). Renvoie le jeu (BallMatch) : son signal match_finished
##   (résultat) dit la fin ; stop_ball_match() disperse le groupe.
## - start_staff_training(options) : l'entraînement au bâton à la clairière, Willem contre le
##   joueur, puis Ithea et Nephren avec lui. Renvoie l'exercice (StaffTraining) : son signal
##   finished(résultat) dit la fin ; stop_staff_training() l'arrête.
## - start_ambush(options) : (E8c) l'embuscade de Pannibal, là où sont le joueur et Pannibal (le
##   sentier, le jour 1). Renvoie le jeu (Ambush) : son signal finished(résultat) dit la fin ;
##   stop_ambush() l'arrête. Inscrit au récit (StoryDirector.register_game) sous
##   STORY_AMBUSH (« embuscade_pannibal ») par register_story_games() : play_story_ambush(params).
## - start_duel(options) : (E8b) le duel ingagnable contre Willem (place `duel` de la cour, jour
##   8) ; la reprise « Encore une fois ! » par l'option reprise. Renvoie le jeu (Duel) : son signal
##   finished(résultat) dit la fin ; stop_duel() l'arrête. Inscrit au récit sous STORY_DUEL
##   (« duel_willem ») : play_story_duel(params).
## - start_seniorious_training(options) : (E8b) l'entraînement spécial avec Seniorious à la
##   clairière (le jour 11). Renvoie l'exercice (SenioriousTraining) : finished(résultat) ;
##   stop_seniorious_training(). Inscrit au récit sous STORY_SENIORIOUS
##   (« entrainement_seniorious ») : play_story_seniorious(params).
## - stop_all() : (X-L2) arrête et retire les jeux du récit en cours (une scène passée) ; le match
##   de ballon de la vie continue.
## - dev_start(jeu) : ce que fait `?jeu=ballon` / `baton` / `duel` / `seniorious` (voir
##   src/test_shortcuts.gd).
## Les PNJ qui ne sont pas encore sur la carte y sont posés (LifeDirector.spawn_actor) ; à la fin
## ils retournent à leur emploi du temps (LifeDirector.refresh). La carte doit être peuplée par
## LifeDirector (WorldManager.enter_map) et sa navigation construite (LifeDirector.build_nav_now ;
## fait ici si elle ne l'est pas).

const BALL_PLACE := &"champ_centre"
const BALL_ACTIVITY := &"ballon"
const TRAINING_PLACE := &"clairiere_centre"
const BENCH_PLACE := &"clairiere_banc"
const BALL_MAP := &"entrepot"
const WHITE_TEAM: Array[StringName] = [&"tiat", &"lakhesh", &"fairy_01", &"fairy_02", &"fairy_03"]
const RED_TEAM: Array[StringName] = [&"collon", &"pannibal", &"fairy_04", &"fairy_05", &"fairy_06"]
const REFEREE_ID := &"willem"
const ALLY_IDS: Array[StringName] = [&"ithea", &"nephren"]
## Tenue portée pendant le jeu, par PNJ (la planche de la maison court, frappe et tombe).
const OUTFITS := {&"willem": &"maison", &"ithea": &"maison", &"nephren": &"maison"}
const KID_OUTFIT := &"vie"
const RING_RADIUS := 5.0
## (E8c) L'embuscade : son id au récit (étape « game ») et son adversaire par défaut.
const STORY_AMBUSH := &"embuscade_pannibal"
const AMBUSH_NPC := &"pannibal"
## Où poser Pannibal si elle n'est pas sur la carte (devant le joueur, à l'est).
const AMBUSH_SPAWN_OFFSET := Vector3(3.0, 0.0, -0.5)
## (E8b) Le duel et l'entraînement avec Seniorious : leurs ids au récit, leurs places.
const STORY_DUEL := &"duel_willem"
const STORY_SENIORIOUS := &"entrainement_seniorious"
const DUEL_WILLEM_PLACE := &"cour_willem"
const DUEL_PLAYER_PLACE := &"cour_chtholly"
## (S2) L'entraînement au bâton au récit (scènes 9.2 et 10.1).
const STORY_STAFF := &"entrainement_baton"
## Les jeux de `?jeu=` (dev_start).
const DEV_GAMES: Array[String] = ["ballon", "baton", "duel", "seniorious"]

## Ligne d'emploi du temps des PNJ pris par un jeu (pour les y rendre).
static var _lines: Dictionary = {}

# --- Le ballon -----------------------------------------------------------------------------------


## Lance un match. options (tous facultatifs) : place (StringName, champ_centre), white / red
## (listes d'ids), referee (id, willem ; &"" : aucun), overrides (chemins de data/games/ballon.json,
## ex. {"half_time": 20}), muddy (bool), with_player (le joueur entre tout de suite), player_at
## (Vector3 où poser le joueur). Renvoie le match, null s'il n'y a pas de champ sur la carte.
static func start_ball_match(options: Dictionary = {}) -> BallMatch:
	var place: StringName = options.get("place", BALL_PLACE)
	var places := LifeDirector.places()
	if places == null or not places.has(place):
		push_warning("MiniGames : pas de place %s sur la carte (ballon)" % place)
		return null
	_ensure_nav()
	var existing := ball_match(place)
	if existing != null:
		stop_ball_match(place)
	var middle := places.center(place)
	var activity := LifeData.activity(BALL_ACTIVITY).duplicate(true)
	var params: Dictionary = (activity.get("params", {}) as Dictionary).duplicate()
	params.merge(options.get("overrides", {}), true)
	params["muddy"] = bool(options.get("muddy", false))
	activity["params"] = params
	var roster: Array = []
	var white: Array = options.get("white", WHITE_TEAM)
	var red: Array = options.get("red", RED_TEAM)
	var referee: StringName = options.get("referee", REFEREE_ID)
	for i: int in white.size():
		roster.append([StringName(str(white[i])), &"blanc", i * 2])
	for i: int in red.size():
		roster.append([StringName(str(red[i])), &"rouge", i * 2 + 1])
	if not referee.is_empty():
		roster.append([referee, &"arbitre", roster.size()])
	for entry: Array in roster:
		var angle := TAU * float(int(entry[2])) / maxf(roster.size(), 1) + 0.3
		var at := middle + Vector3(cos(angle), 0.0, sin(angle)) * RING_RADIUS
		var actor := _take(entry[0], at, entry[1], place, activity)
		if actor != null:
			LifeDirector.join_game(actor)
	var game := ball_match(place)
	if game == null:
		return null
	var player := LifeDirector.player_node()
	if options.has("player_at") and player != null:
		player.global_position = options["player_at"]
	if bool(options.get("with_player", false)) and player != null and game.running:
		game.join_player()
	return game


## Le match de ce champ (null s'il n'y en a pas).
static func ball_match(place: StringName = BALL_PLACE) -> BallMatch:
	return LifeDirector.game_at(BALL_ACTIVITY, place) as BallMatch


## Disperse le match : les joueuses quittent le groupe et retournent à leur emploi du temps.
static func stop_ball_match(place: StringName = BALL_PLACE) -> void:
	var game := ball_match(place)
	if game == null:
		return
	if game.running:
		game.finish()
	for actor: LifeActor in game.members.duplicate():
		LifeDirector.leave_game(actor)
		actor.state = LifeActor.State.ACTIVITY
		# Celle qui avait un emploi du temps ici y retourne ; les autres, refresh() s'en charge.
		if _lines.has(actor.id):
			actor.place_now(_lines[actor.id])
		_lines.erase(actor.id)
	LifeDirector.refresh(true)


# --- L'entraînement au bâton ---------------------------------------------------------------------


## Lance l'entraînement. options : variant (&"default", &"jour10"), place_player (poser le joueur
## face à Willem), restore_weapon (rendre l'arme d'avant à la fin, vrai), with_hud (vrai),
## overrides (chemins de data/games/staff_training.json), seed (graine du tirage : un exercice
## rejouable, pour les tests). Renvoie l'exercice ; null sans joueur ni clairière.
static func start_staff_training(options: Dictionary = {}) -> StaffTraining:
	var places := LifeDirector.places()
	var player := LifeDirector.player_node() as Player
	if player == null or places == null or not places.has(TRAINING_PLACE):
		push_warning("MiniGames : pas de joueur ou de place %s (entraînement)" % TRAINING_PLACE)
		return null
	_ensure_nav()
	var current := staff_training()
	if current != null:
		current.stop()
		current.queue_free()
	var middle := places.center(TRAINING_PLACE)
	var willem := _take(REFEREE_ID, middle, &"", &"", {})
	var allies: Array[LifeActor] = []
	var bench := (
		places.center(BENCH_PLACE) if places.has(BENCH_PLACE) else middle + Vector3(8.0, 0.0, 0.0)
	)
	for i: int in ALLY_IDS.size():
		var at := bench + Vector3(0.0, 0.0, -0.6 + 1.2 * i)
		var ally := _take(ALLY_IDS[i], at, &"", &"", {})
		if ally != null:
			allies.append(ally)
	if willem == null:
		return null
	var host := LifeDirector.current_map().get_node_or_null(^"Life") as Node
	var training := StaffTraining.new()
	training.overrides = options.get("overrides", {})
	training.show_hud = bool(options.get("with_hud", true))
	if options.has("seed"):
		training.seed_random(int(options["seed"]))
	host.add_child(training)
	if bool(options.get("place_player", false)):
		var spot := willem.position() + Vector3(0.0, 0.0, 2.2)
		spot.y = willem.position().y + 0.1
		player.global_position = spot
		player.velocity = Vector3.ZERO
		player.set_aim_direction(willem.position() - spot, true)
	training.setup(player, willem, allies, StringName(str(options.get("variant", "default"))))
	training.start(bool(options.get("restore_weapon", true)))
	return training


## L'exercice en cours (null s'il n'y en a pas).
static func staff_training() -> StaffTraining:
	var map := LifeDirector.current_map()
	var host := map.get_node_or_null(^"Life") if map != null else null
	if host == null:
		return null
	return host.get_node_or_null(^"StaffTraining") as StaffTraining


## Arrête l'exercice en cours.
static func stop_staff_training() -> void:
	var training := staff_training()
	if training != null:
		training.stop()


## (S2) Le jeu du récit « entrainement_baton » (étape « game » d'E6, scènes 9.2 et 10.1 ; params de
## la scène : variant, place_player, seed, overrides, et success_flag : posé si l'exercice réussit,
## retiré sinon). Le joueur a la main pendant l'exercice (la scène la reprend à la fin) ; attend la
## fin et que Willem et les aînées soient rendus à la scène (end_time). Faux s'il n'a pas pu
## démarrer (le récit joue alors le repli de l'étape).
static func play_story_staff(params: Dictionary) -> bool:
	var player := LifeDirector.player_node() as Player
	var held := player != null and player.is_story_held()
	if player != null:
		player.set_story_hold(false)
	var training := start_staff_training(params)
	if training == null:
		if held and is_instance_valid(player):
			player.set_story_hold(true)
		return false
	var tree := training.get_tree()
	var result := await _wait_finished(training)
	var left := GameRules.number(&"staff_training", "end_time", 3.0)
	while left > 0.0 and is_instance_valid(training) and tree != null:
		await tree.physics_frame
		left -= tree.root.get_physics_process_delta_time()
	if held and is_instance_valid(player):
		player.set_story_hold(true)
	var flag := StringName(str(params.get("success_flag", "")))
	if not flag.is_empty():
		GameState.set_flag(flag, bool(result.get("success", false)))
	return true


# --- L'embuscade de Pannibal (E8c) --------------------------------------------------------------


## Lance l'embuscade. options (tous facultatifs) : npc (id, pannibal), day (jour de l'acte,
## GameState.day ; les feintes viennent à partir du jour 5), help (les deux lignes d'aide du jour
## 1), seed (graine du tirage : une embuscade rejouable, pour les tests), outfit (sa tenue, vie :
## la planche qui bondit, frappe et tombe), overrides (chemins de
## data/games/embuscade.json), with_hud (vrai), restore_weapon (rendre l'arme d'avant, vrai). Le
## PNJ qui n'est pas sur la carte y est posé devant le joueur. Renvoie le jeu ; null sans joueur,
## sans carte peuplée par LifeDirector ou sans le PNJ (carte d'essai : le récit joue son repli).
static func start_ambush(options: Dictionary = {}) -> Ambush:
	var player := LifeDirector.player_node() as Player
	var map := LifeDirector.current_map()
	var host := map.get_node_or_null(^"Life") if map != null else null
	if player == null or host == null:
		push_warning("MiniGames : pas de joueur ou de carte peuplée (embuscade)")
		return null
	_ensure_nav()
	var npc_id := StringName(str(options.get("npc", AMBUSH_NPC)))
	var actor := LifeDirector.actor(npc_id)
	if actor == null:
		actor = LifeDirector.spawn_actor(npc_id, player.global_position + AMBUSH_SPAWN_OFFSET)
	if actor == null or actor.state == LifeActor.State.GONE:
		push_warning("MiniGames : %s n'est pas sur la carte (embuscade)" % npc_id)
		return null
	# La tenue de la vie : sa planche bondit, frappe et tombe (pannibal_life).
	var outfit := StringName(str(options.get("outfit", KID_OUTFIT)))
	if actor.data != null and actor.data.outfits.has(outfit) and actor.outfit != outfit:
		actor.outfit = outfit
		actor.npc.set_outfit(LifeDirector.outfit_skin(actor.data, outfit))
	var current := ambush()
	if current != null:
		current.stop()
	var game := Ambush.new()
	game.overrides = options.get("overrides", {})
	game.show_hud = bool(options.get("with_hud", true))
	if options.has("seed"):
		game.seed_random(int(options["seed"]))
	host.add_child(game)
	var day := int(options.get("day", maxi(GameState.day, 1)))
	game.setup(player, actor, day, bool(options.get("help", false)))
	game.start(bool(options.get("restore_weapon", true)))
	return game


## L'embuscade en cours (null s'il n'y en a pas).
static func ambush() -> Ambush:
	var map := LifeDirector.current_map()
	var host := map.get_node_or_null(^"Life") if map != null else null
	if host == null:
		return null
	for child: Node in host.get_children():
		if child is Ambush and not (child as Ambush).is_done():
			return child as Ambush
	return null


## Arrête l'embuscade en cours.
static func stop_ambush() -> void:
	var game := ambush()
	if game != null:
		game.stop()


## Le jeu du récit « embuscade_pannibal » (étape « game » d'E6 ; params de la scène : day, help,
## seed, overrides, et success_flag : le drapeau posé si Chtholly l'emporte, retiré sinon). Attend
## la fin du jeu ; faux s'il n'a pas pu démarrer (le récit joue alors le repli de l'étape).
static func play_story_ambush(params: Dictionary) -> bool:
	var game := start_ambush(params)
	if game == null:
		return false
	var tree := game.get_tree()
	var outcome := {}
	game.finished.connect(func(found: Dictionary) -> void: outcome["result"] = found)
	while is_instance_valid(game) and not outcome.has("result") and tree != null:
		await tree.physics_frame
	var result: Dictionary = outcome.get("result", {})
	var flag := StringName(str(params.get("success_flag", "")))
	if not flag.is_empty():
		GameState.set_flag(flag, bool(result.get("success", false)))
	return true


## Inscrit les jeux d'E8 au récit (StoryDirector.register_game) : l'embuscade de Pannibal, (E8b) le
## duel et l'entraînement avec Seniorious.
static func register_story_games() -> void:
	StoryDirector.register_game(STORY_AMBUSH, Callable(MiniGames, &"play_story_ambush"))
	StoryDirector.register_game(STORY_DUEL, Callable(MiniGames, &"play_story_duel"))
	StoryDirector.register_game(STORY_SENIORIOUS, Callable(MiniGames, &"play_story_seniorious"))
	StoryDirector.register_game(STORY_STAFF, Callable(MiniGames, &"play_story_staff"))


# --- Le duel ingagnable (E8b) -------------------------------------------------------------------


## Lance le duel. options (tous facultatifs) : reprise (« Encore une fois ! » : les phases 2 et 3,
## plus vite), place (poser Willem à cour_willem et le joueur à cour_chtholly, face à face ; faux :
## là où ils sont, Willem posé à cour_willem s'il n'est pas sur la carte), seed (graine : un duel
## rejouable), overrides (chemins de data/games/duel.json), with_hud (vrai), restore_weapon (rendre
## l'arme d'avant, vrai). Renvoie le duel ; null sans joueur, sans carte peuplée ou sans Willem.
static func start_duel(options: Dictionary = {}) -> Duel:
	var player := LifeDirector.player_node() as Player
	var map := LifeDirector.current_map()
	var host := map.get_node_or_null(^"Life") if map != null else null
	if player == null or host == null:
		push_warning("MiniGames : pas de joueur ou de carte peuplée (duel)")
		return null
	_ensure_nav()
	var places := LifeDirector.places()
	var willem_at := player.global_position + Vector3(0.0, 0.0, -4.0)
	if places != null and places.has(DUEL_WILLEM_PLACE):
		willem_at = places.center(DUEL_WILLEM_PLACE)
	var willem := LifeDirector.actor(REFEREE_ID)
	if willem == null:
		willem = LifeDirector.spawn_actor(REFEREE_ID, willem_at)
	if willem == null or willem.state == LifeActor.State.GONE:
		push_warning("MiniGames : Willem n'est pas sur la carte (duel)")
		return null
	if bool(options.get("place", false)):
		willem.stop()
		willem.set_position(willem_at)
		if places != null and places.has(DUEL_PLAYER_PLACE):
			_place_player(player, places.center(DUEL_PLAYER_PLACE), willem.position())
	var current := duel()
	if current != null:
		current.stop()
	var game := Duel.new()
	game.overrides = options.get("overrides", {})
	game.show_hud = bool(options.get("with_hud", true))
	if options.has("seed"):
		game.seed_random(int(options["seed"]))
	host.add_child(game)
	game.setup(player, willem, bool(options.get("reprise", false)))
	game.start(bool(options.get("restore_weapon", true)))
	return game


## Le duel en cours (null s'il n'y en a pas).
static func duel() -> Duel:
	return _running_child(Duel) as Duel


## Arrête le duel en cours.
static func stop_duel() -> void:
	var game := duel()
	if game != null:
		game.stop()


## Le jeu du récit « duel_willem » (étape « game » d'E6, scène 8.3 ; params de la scène : reprise,
## place, seed, overrides, et flag : le drapeau posé quand le duel est joué). Attend la fin du duel
## (Chtholly projetée) ; faux s'il n'a pas pu démarrer (le récit joue alors le repli de l'étape).
## La reprise : la scène pose le choix « Encore une fois ! » / « … D'accord. » après cette étape,
## puis une seconde étape « game » avec {"reprise": true}.
static func play_story_duel(params: Dictionary) -> bool:
	var game := start_duel(params)
	if game == null:
		return false
	await _wait_finished(game)
	var flag := StringName(str(params.get("flag", "")))
	if not flag.is_empty():
		GameState.set_flag(flag, true)
	return true


# --- L'entraînement avec Seniorious (E8b) --------------------------------------------------------


## Lance l'entraînement spécial. options : start_stage (1 : la respiration ; 2 : les mouvements,
## après la réussite du jour 9 ; 3 : la Grue), pickup (ramasser l'épée tombée dans le marais,
## vrai), place_player (poser le joueur à l'ouest de Willem, face à lui), seed, overrides (chemins
## de data/games/seniorious.json), with_hud (vrai), restore_weapon (vrai). Renvoie l'exercice ;
## null sans joueur ni clairière.
static func start_seniorious_training(options: Dictionary = {}) -> SenioriousTraining:
	var places := LifeDirector.places()
	var player := LifeDirector.player_node() as Player
	var map := LifeDirector.current_map()
	var host := map.get_node_or_null(^"Life") if map != null else null
	if player == null or host == null or places == null or not places.has(TRAINING_PLACE):
		push_warning("MiniGames : pas de joueur ou de place %s (Seniorious)" % TRAINING_PLACE)
		return null
	_ensure_nav()
	var current := seniorious_training()
	if current != null:
		current.stop()
	var middle := places.center(TRAINING_PLACE)
	var willem := LifeDirector.actor(REFEREE_ID)
	if willem == null:
		willem = LifeDirector.spawn_actor(REFEREE_ID, middle)
	if willem == null or willem.state == LifeActor.State.GONE:
		push_warning("MiniGames : Willem n'est pas sur la carte (Seniorious)")
		return null
	if bool(options.get("place_player", false)):
		willem.stop()
		willem.set_position(middle)
		var gap := GameRules.number(&"seniorious", "start_gap", 2.2)
		_place_player(player, middle + Vector3(-gap, 0.0, 0.0), middle)
	var training := SenioriousTraining.new()
	training.overrides = options.get("overrides", {})
	training.show_hud = bool(options.get("with_hud", true))
	if options.has("seed"):
		training.seed_random(int(options["seed"]))
	host.add_child(training)
	training.setup(
		player, willem, int(options.get("start_stage", 1)), bool(options.get("pickup", true))
	)
	training.start(bool(options.get("restore_weapon", true)))
	return training


## L'entraînement avec Seniorious en cours (null s'il n'y en a pas).
static func seniorious_training() -> SenioriousTraining:
	return _running_child(SenioriousTraining) as SenioriousTraining


## Arrête l'entraînement avec Seniorious en cours.
static func stop_seniorious_training() -> void:
	var training := seniorious_training()
	if training != null:
		training.stop()


## Le jeu du récit « entrainement_seniorious » (scène 11.4 ; params : start_stage, pickup,
## place_player, seed, overrides, et success_flag : posé si les trois Grues sont faites, retiré
## sinon). Attend la fin de l'exercice ; faux s'il n'a pas pu démarrer (repli de l'étape).
static func play_story_seniorious(params: Dictionary) -> bool:
	var training := start_seniorious_training(params)
	if training == null:
		return false
	var result := await _wait_finished(training)
	var flag := StringName(str(params.get("success_flag", "")))
	if not flag.is_empty():
		GameState.set_flag(flag, bool(result.get("success", false)))
	return true


# --- Tout arrêter (X-L2) -------------------------------------------------------------------------


## (X-L2) Arrête les jeux du récit en cours (le duel, l'embuscade, l'entraînement au bâton,
## l'entraînement avec Seniorious : stop_*) et les retire tout de suite de la carte (le bâton n'y
## attend pas sa pose de fin) : une scène passée (StoryRunner.skip). Chacun émet finished
## (« stopped ») et rend arme, image et personnages. Le match de ballon, une activité de la vie,
## continue (stop_ball_match).
static func stop_all() -> void:
	stop_duel()
	stop_ambush()
	stop_seniorious_training()
	var training := staff_training()
	if training == null:
		return
	if training.is_running():
		training.stop()
	# La pose de fin (end_time) passée d'un coup, par pas d'une demi-seconde (le nœud se retire au
	# pas qui l'achève) : personnages rendus, nœud retiré.
	var steps := ceili(training.rule("end_time", 3.0) / 0.5) + 1
	for _step: int in steps:
		if training.phase != &"ended" or training.is_queued_for_deletion():
			break
		training.advance(0.5)


# --- Raccourci de développement ------------------------------------------------------------------


## `?jeu=ballon` / `baton` / `duel` / `seniorious` : la partie se pose sur l'entrepôt au bon moment
## (après-midi pour le ballon et Seniorious, matin pour le bâton et le duel) et le jeu commence ; le
## joueur est posé près du terrain. Le duel enchaîne une fois sa reprise (« Encore une fois ! »).
## Renvoie le jeu lancé (BallMatch, StaffTraining, Duel ou SenioriousTraining), null pour un jeu
## inconnu.
static func dev_start(game_name: String) -> Object:
	if not DEV_GAMES.has(game_name):
		return null
	var morning := game_name == "baton" or game_name == "duel"
	LifeDirector.set_slot(&"matin" if morning else &"apres_midi", 0.0)
	if WorldManager.current_map() != BALL_MAP:
		WorldManager.enter_map(BALL_MAP)
	# Le créneau est pris en compte tout de suite : sans cela, le directeur l'appliquerait à l'image
	# suivante et renverrait les joueuses à leur emploi du temps.
	LifeDirector.refresh(false)
	LifeDirector.build_nav_now()
	var player := LifeDirector.player_node()
	if game_name == "ballon":
		var places := LifeDirector.places()
		var field := places.center(BALL_PLACE)
		if player != null:
			player.global_position = Vector3(field.x - 12.0, field.y + 0.2, field.z)
			(player as Player).set_aim_direction(Vector3.RIGHT, true)
		return start_ball_match()
	if game_name == "duel":
		var first := start_duel({"place": true})
		if first != null:
			first.finished.connect(_start_reprise, CONNECT_ONE_SHOT)
		return first
	if game_name == "seniorious":
		return start_seniorious_training({"place_player": true})
	return start_staff_training({"place_player": true})


# --- Interne -------------------------------------------------------------------------------------


## (E8b) Après le premier duel du raccourci : « Encore une fois ! ».
static func _start_reprise(_result: Dictionary) -> void:
	Callable(MiniGames, &"start_duel").call_deferred({"reprise": true})


## Le jeu de ce type dans Life (pas encore fini), null sinon.
static func _running_child(type: Variant) -> Node:
	var map := LifeDirector.current_map()
	var host := map.get_node_or_null(^"Life") if map != null else null
	if host == null:
		return null
	for child: Node in host.get_children():
		if is_instance_of(child, type) and not child.call(&"is_done"):
			return child
	return null


## Pose le joueur en at (au sol de la carte), tourné vers target.
static func _place_player(player: Player, at: Vector3, target: Vector3) -> void:
	var spot := at
	var nav := LifeDirector.nav()
	if nav != null and nav.ready:
		spot.y = nav.height_at(at.x, at.z)
	player.global_position = spot + Vector3(0.0, 0.1, 0.0)
	player.velocity = Vector3.ZERO
	player.set_aim_direction(target - spot, true)


## Attend le signal finished(résultat) d'un jeu (ou sa disparition) ; rend le résultat ({} sinon).
static func _wait_finished(game: Node) -> Dictionary:
	var tree := game.get_tree()
	var outcome := {}
	game.connect(&"finished", func(found: Dictionary) -> void: outcome["result"] = found)
	while is_instance_valid(game) and not outcome.has("result") and tree != null:
		await tree.physics_frame
	return outcome.get("result", {})


static func _ensure_nav() -> void:
	var nav := LifeDirector.nav()
	if nav == null or not nav.ready:
		LifeDirector.build_nav_now()


## Le PNJ de la carte (posé en at s'il n'y est pas) sous la tenue du jeu ; pour un jeu de groupe :
## son rôle, sa place, son activité.
static func _take(
	npc_id: StringName, at: Vector3, role: StringName, place: StringName, activity: Dictionary
) -> LifeActor:
	var actor := LifeDirector.actor(npc_id)
	if actor == null:
		actor = LifeDirector.spawn_actor(npc_id, at)
	if actor == null:
		return null
	# Une petite déjà prise par un autre jeu (le chat des hautes herbes) le quitte.
	if actor.game != null:
		LifeDirector.leave_game(actor)
	if not _lines.has(npc_id) and actor.line.has("map"):
		_lines[npc_id] = actor.line
	var outfit: StringName = OUTFITS.get(npc_id, KID_OUTFIT)
	if actor.data != null and actor.data.outfits.has(outfit):
		actor.outfit = outfit
		actor.npc.set_outfit(LifeDirector.outfit_skin(actor.data, outfit))
	actor.stop()
	actor.set_position(at)
	if not activity.is_empty():
		actor.role = role
		actor.place = place
		actor.activity_id = BALL_ACTIVITY
		actor.activity = activity
		actor.state = LifeActor.State.GAME
	return actor
