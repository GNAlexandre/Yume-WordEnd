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
## - dev_start(jeu) : ce que fait `?jeu=ballon` / `?jeu=baton` (voir src/test_shortcuts.gd).
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
	LifeDirector.refresh(true)


# --- L'entraînement au bâton ---------------------------------------------------------------------


## Lance l'entraînement. options : variant (&"default", &"jour10"), place_player (poser le joueur
## face à Willem), restore_weapon (rendre l'arme d'avant à la fin, vrai), with_hud (vrai),
## overrides (chemins de data/games/staff_training.json). Renvoie l'exercice ; null sans joueur ni
## clairière.
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


# --- Raccourci de développement ------------------------------------------------------------------


## `?jeu=ballon` / `?jeu=baton` : la partie se pose sur l'entrepôt au bon moment (après-midi pour le
## ballon, matin pour le bâton) et le jeu commence ; le joueur est posé près du terrain. Renvoie le
## jeu lancé (BallMatch ou StaffTraining), null pour un jeu inconnu.
static func dev_start(game_name: String) -> Object:
	if game_name != "ballon" and game_name != "baton":
		return null
	LifeDirector.set_slot(&"apres_midi" if game_name == "ballon" else &"matin", 0.0)
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
	return start_staff_training({"place_player": true})


# --- Interne -------------------------------------------------------------------------------------


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
