class_name LifeGame
extends RefCounted
## (E4) Un jeu de groupe des petites (docs/REFONTE.md 4.2 ; docs/lore/VIE.md, section 5) : le
## cadre commun, que chaque jeu étend (src/life/games/<jeu>.gd). Propriétaire : E4.
##
## - Qui : les PNJ dont l'activité de la ligne courante nomme le jeu (activities.json, clé
##   « game ») sur la même place de la même carte forment un groupe (un LifeGame) ; LifeDirector
##   les y fait entrer (add_member) à leur arrivée et sortir (remove_member) quand leur ligne
##   change. Le jeu mène alors leurs gestes (LifeActor.walk_to, hold, play, face).
## - Des rôles (roles : PNJ → rôle) : la clé « role » de la ligne, ou ceux que le jeu donne
##   (la chasseuse, la base de la pile) ; des équipes (teams : équipe → PNJ ; assign_teams), pour
##   le ballon du lot E8.
## - Un lieu : la place (ses points : le terrain, la ligne de départ, les places d'une
##   formation : formation()).
## - Un début et une fin : start() quand il y a assez de monde (min_members, params), finish()
##   quand il n'y en a plus assez ; une manche peut finir et recommencer dans le jeu.
## - Le joueur : player_near() (à join_distance de la place) ; join_player() / leave_player()
##   (player_in) ; on_player_interact(PNJ) remplace le dialogue quand le jeu a mieux à faire (vrai :
##   rien d'autre ne se passe) ; on_player_attack() quand le joueur frappe de l'épée (sans mal).
## Paramètres (activities.json, « params ») lus par param() ; textes par text() (LifeTexts,
## games/<jeu>/<clé>).

## Événement d'un jeu (début, fin, rôle donné, joueur entré ou sorti…), pour les tests et
## démonstrations : kind (&"started", &"finished", &"role", &"player_joined", &"player_left",
## &"tagged", …), détail.
signal event(kind: StringName, detail: Variant)

var game_id: StringName = &""
var map_id: StringName = &""
var place: StringName = &""
var params: Dictionary = {}
var members: Array[LifeActor] = []
var roles: Dictionary = {}
var teams: Dictionary = {}
var running: bool = false
var player_in: bool = false
var min_members: int = 2
var join_distance: float = 3.0
var leave_distance: float = 10.0
var rng := RandomNumberGenerator.new()
## Événements reçus, dans l'ordre : [kind, détail] (tests).
var events: Array = []


## Prépare le jeu (appelé par LifeDirector une fois).
func setup(
	id: StringName, on_map: StringName, at_place: StringName, game_params: Dictionary
) -> void:
	game_id = id
	map_id = on_map
	place = at_place
	params = game_params
	min_members = int(param("min_members", min_members))
	join_distance = float(param("join_distance", join_distance))
	leave_distance = float(param("leave_distance", leave_distance))
	rng.seed = hash("%s|%s" % [id, at_place]) ^ Time.get_ticks_usec()
	_setup()


## Un PNJ entre dans le groupe (son rôle : la clé « role » de sa ligne, s'il y en a une).
func add_member(actor: LifeActor) -> void:
	if members.has(actor):
		return
	members.append(actor)
	actor.game = self
	actor.state = LifeActor.State.GAME
	if not actor.role.is_empty():
		roles[actor.id] = actor.role
	_member_added(actor)
	if not running and members.size() >= min_members:
		start()


## Un PNJ quitte le groupe (sa ligne a changé, il part).
func remove_member(actor: LifeActor) -> void:
	if not members.has(actor):
		return
	members.erase(actor)
	roles.erase(actor.id)
	for team: StringName in teams:
		(teams[team] as Array).erase(actor.id)
	_member_removed(actor)
	actor.game = null
	if running and members.size() < min_members:
		finish()


## Début du jeu (assez de monde).
func start() -> void:
	running = true
	_emit(&"started", members.size())
	_started()


## Fin du jeu (plus assez de monde, ou fin voulue).
func finish() -> void:
	if not running:
		return
	running = false
	if player_in:
		leave_player()
	_finished()
	_emit(&"finished", members.size())


## Une image : le joueur (entrée, sortie), puis le jeu.
func tick(delta: float, player: Node3D) -> void:
	if not running:
		_idle_tick(delta)
		return
	if player != null:
		if not player_in and _accepts_player() and _player_close(player):
			join_player()
		elif player_in and _player_far(player):
			leave_player()
	_tick(delta, player)


## Le joueur entre dans le jeu.
func join_player() -> void:
	player_in = true
	_emit(&"player_joined", null)
	_player_joined()


## Le joueur sort du jeu.
func leave_player() -> void:
	player_in = false
	_player_left()
	_emit(&"player_left", null)


## Donne un rôle à un PNJ (&"" : aucun).
func set_role(actor: LifeActor, role: StringName) -> void:
	if role.is_empty():
		roles.erase(actor.id)
	else:
		roles[actor.id] = role
	_emit(&"role", [actor.id, role])


## Rôle d'un PNJ (&"" : aucun).
func role_of(actor: LifeActor) -> StringName:
	return roles.get(actor.id, &"")


## PNJ qui ont ce rôle.
func with_role(role: StringName) -> Array[LifeActor]:
	var result: Array[LifeActor] = []
	for actor: LifeActor in members:
		if roles.get(actor.id, &"") == role:
			result.append(actor)
	return result


## (Ballon, E8) Répartit les membres en équipes, chacun dans la plus petite (un rôle d'équipe
## donné par la ligne, « role » : « rouge », l'emporte) ; renvoie teams. Les membres dont le rôle
## est dans except_roles (l'arbitre) n'entrent dans aucune équipe.
func assign_teams(
	team_names: Array[StringName], except_roles: Array[StringName] = []
) -> Dictionary:
	teams.clear()
	for team: StringName in team_names:
		teams[team] = [] as Array[StringName]
	for actor: LifeActor in members:
		var wanted: StringName = roles.get(actor.id, &"")
		if except_roles.has(wanted):
			continue
		if not teams.has(wanted):
			wanted = team_names[0]
			for team: StringName in team_names:
				if (teams[team] as Array).size() < (teams[wanted] as Array).size():
					wanted = team
		(teams[wanted] as Array).append(actor.id)
	return teams


## Équipe d'un PNJ (&"" : aucune).
func team_of(actor: LifeActor) -> StringName:
	for team: StringName in teams:
		if (teams[team] as Array).has(actor.id):
			return team
	return &""


## (Ballon, E8) Points de la place en formation : les count premiers points, ou des points en
## cercle autour du centre s'il en manque.
func formation(count: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var places := LifeDirector.places()
	var available := places.size(place) if places != null else 0
	for i: int in count:
		if i < available:
			result.append(places.point(place, i))
		else:
			var angle := TAU * i / maxf(count, 1)
			var at := center() + Vector3(cos(angle), 0.0, sin(angle)) * maxf(radius(), 1.5)
			result.append(Transform3D(Basis.IDENTITY, at))
	return result


## Centre de la place (repère du monde).
func center() -> Vector3:
	var places := LifeDirector.places()
	return places.center(place) if places != null and places.has(place) else Vector3.ZERO


## Rayon de la place.
func radius() -> float:
	var places := LifeDirector.places()
	return places.radius(place) if places != null else 0.0


## Paramètre du jeu (activities.json, « params »), default s'il manque.
func param(key: String, default: Variant) -> Variant:
	return params.get(key, default)


## Texte du jeu (data/texts/life.json, games/<jeu>/<clé>).
func text(key: String, fallback: String = "") -> String:
	return LifeTexts.text("games/%s/%s" % [game_id, key], fallback, rng)


## Distance au sol entre deux points.
static func flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _emit(kind: StringName, detail: Variant) -> void:
	events.append([kind, detail])
	event.emit(kind, detail)


# --- À redéfinir -------------------------------------------------------------------------------


## (E8) Vrai tant que le jeu réserve ses membres : le joueur n'y participe pas à côté d'une
## conversation, ils ne proposent pas « Parler » (le ballon quand il y joue, l'entraînement).
func blocks_talk() -> bool:
	return false


## Le joueur interagit avec un membre : vrai si le jeu y répond (pas de dialogue).
func on_player_interact(_actor: LifeActor) -> bool:
	return false


## Le joueur frappe de l'épée (sans faire de mal).
func on_player_attack(_player: Node3D) -> void:
	pass


## Fin de la conversation d'un membre avec le joueur.
func on_talk_ended(_actor: LifeActor) -> void:
	pass


func _setup() -> void:
	pass


func _member_added(_actor: LifeActor) -> void:
	pass


func _member_removed(_actor: LifeActor) -> void:
	pass


func _started() -> void:
	pass


func _finished() -> void:
	pass


func _tick(_delta: float, _player: Node3D) -> void:
	pass


## Pas encore assez de monde : les membres attendent (repos).
func _idle_tick(_delta: float) -> void:
	for actor: LifeActor in members:
		if not actor.is_moving() and not actor.is_holding():
			actor.play(&"repos")


func _accepts_player() -> bool:
	return false


## Le joueur est assez près pour entrer (à join_distance du bord de la place).
func _player_close(player: Node3D) -> bool:
	return flat_distance(player.global_position, center()) < join_distance + radius()


## Le joueur est assez loin pour sortir (à leave_distance du bord de la place).
func _player_far(player: Node3D) -> bool:
	return flat_distance(player.global_position, center()) > leave_distance + radius()


func _player_joined() -> void:
	pass


func _player_left() -> void:
	pass
