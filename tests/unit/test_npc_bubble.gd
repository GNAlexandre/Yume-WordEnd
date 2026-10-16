extends GutTest
## (QC2) La bulle d'un PNJ ne tombe jamais sur le joueur (docs/QUALITE.md, QC-40) : vue de la
## caméra (32°, vers le nord), un PNJ couché aux pieds du joueur (Pannibal dans l'embuscade) ou
## juste au sud de lui pose sa bulle au-dessus de la tête du joueur ; loin de lui, ou au nord, elle
## reste au-dessus de la sienne.

const NPC_SCENE := preload("res://src/npc/npc.tscn")
const PLAYER_STUB := preload("res://tests/stubs/player_stub.tscn")
const PANNIBAL := preload("res://data/npcs/pannibal.tres")

var _player: Node3D
var _npc: Npc


func before_each() -> void:
	GameState.reset()
	_player = PLAYER_STUB.instantiate()
	add_child_autofree(_player)
	_npc = NPC_SCENE.instantiate()
	_npc.data = PANNIBAL
	add_child_autofree(_npc)
	_npc.set_physics_process(false)
	_npc.global_position = Vector3.ZERO


func after_each() -> void:
	GameState.reset()


## Hauteur à l'écran (unité : m de hauteur, vue à 32°) du point (y, z).
func _screen_up(y: float, z: float) -> float:
	return y - z * tan(deg_to_rad(Npc.CAMERA_PITCH_DEG))


func _player_head() -> float:
	var skin := SkinRegistry.get_skin(GameState.skin_id)
	return skin.height_m if skin != null else Npc.PLAYER_HEIGHT


func test_far_or_north_npc_keeps_its_bubble_over_its_head() -> void:
	_player.global_position = Vector3(4.0, 0.0, -0.5)
	_npc.say("Haaa ! Halte-là, l'intrus !")
	assert_almost_eq(
		_npc.bubble.position.y, _npc.head_height() + Npc.BUBBLE_GAP, 0.001, "loin du joueur"
	)
	_player.global_position = Vector3(0.0, 0.0, 2.0)
	_npc.place_bubble()
	assert_almost_eq(
		_npc.bubble.position.y, _npc.head_height() + Npc.BUBBLE_GAP, 0.001, "le joueur au sud"
	)


func test_bubble_of_an_npc_at_the_player_feet_goes_over_the_player_head() -> void:
	# Pannibal couchée 0,8 m au sud du joueur (le joueur est au nord : z plus petit).
	_player.global_position = Vector3(0.3, 0.0, -0.8)
	_npc.say("Aïe. Dans l'herbe.")
	var bottom := _screen_up(_npc.bubble.position.y, 0.0)
	var head := _screen_up(_player_head(), -0.8)
	assert_gt(_npc.bubble.position.y, _npc.head_height() + Npc.BUBBLE_GAP, "la bulle monte")
	assert_gte(
		bottom, head + Npc.BUBBLE_CLEARANCE - 0.001, "son bas passe au-dessus de la tête du joueur"
	)


func test_bubble_follows_while_shown() -> void:
	_player.global_position = Vector3(5.0, 0.0, 0.0)
	_npc.say("Un point !", 2.0)
	var low := _npc.bubble.position.y
	_player.global_position = Vector3(0.0, 0.0, -1.0)
	await wait_process_frames(2)
	assert_gt(
		_npc.bubble.position.y, low, "le joueur s'approche : la bulle remonte au-dessus de lui"
	)
