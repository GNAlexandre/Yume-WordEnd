extends GutTest
## (H7) Lisibilité du combat en vue fixe : images d'effets (96 px/m), éclats qui se libèrent seuls
## et ne se posent jamais dans le conteneur des ennemis, arrêt sur image, secousse de l'écran par
## h_offset / v_offset (la caméra ne tourne pas), éclair d'un combattant touché, coup d'épée
## dessiné au sol à sa portée exacte, réticule et chevron de verrouillage, ombre nette qui reste
## au sol pendant un saut, onde tournée vers la caméra et vers là où elle file. Les chiffres :
## data/attacks (windup, hitstop, shake) et data/enemies (windup_scale, tint, strike_shake).

const RIG := preload("res://tests/stubs/l4_player_rig.tscn")
const PLAYER := preload("res://src/player/player.tscn")
const DUMMY := preload("res://tests/stubs/dummy.tscn")
const HITBOX := preload("res://src/combat/hitbox.tscn")
const WAVE_SCENE := preload("res://src/combat/charge_wave.tscn")
const VISUAL := preload("res://src/visuals/character_visual.tscn")
const TelegraphScript := preload("res://src/enemies/telegraph.gd")
const SWORD_1 := preload("res://data/attacks/sword_1.tres")
const SWORD_3 := preload("res://data/attacks/sword_3.tres")
const WAVE := preload("res://data/attacks/charge_wave.tres")
const BITE := preload("res://data/attacks/bite.tres")
const WHIP := preload("res://data/attacks/whip.tres")
const RUSH := preload("res://data/attacks/rush.tres")
## Images d'effets : nom → [largeur d'une image, hauteur, images] (src/combat/fx/make_fx.py).
const IMAGES := {
	"shadow": [64, 64, 1],
	"lock_ring": [96, 96, 1],
	"aim": [32, 32, 1],
	"danger_ring": [64, 64, 1],
	"danger_fill": [64, 64, 1],
	"rush_lane": [48, 192, 1],
	"glint": [32, 32, 3],
	"impact": [48, 48, 4],
	"bite": [48, 48, 3],
	"whip": [64, 32, 3],
	"dust": [32, 32, 4],
	"slash": [240, 120, 3],
	"wave": [192, 96, 2],
	"wave_trace": [192, 80, 1],
}
## Caméra fixe HD-2D (camera_rig.gd) : regarde le nord, inclinée de 32°.
const PITCH_DEG := 32.0

var _root: Node3D


func before_each() -> void:
	GameState.reset()
	_root = add_child_autofree(Node3D.new())


func after_all() -> void:
	GameState.reset()


## Caméra courante de la vue fixe, à 21 m de origin.
func _camera(origin: Vector3 = Vector3.ZERO) -> Camera3D:
	var camera := Camera3D.new()
	_root.add_child(camera)
	var tilt := deg_to_rad(PITCH_DEG)
	camera.global_transform = Transform3D(
		Basis(Vector3.RIGHT, -tilt), origin + Vector3(0.0, sin(tilt), cos(tilt)) * 21.0
	)
	camera.current = true
	return camera


func _ground() -> StaticBody3D:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(ground)
	return ground


# --- Données ----------------------------------------------------------------------------------


func test_readability_numbers_live_in_the_data() -> void:
	assert_almost_eq(BITE.windup, 0.3, 0.001, "morsure : 0,3 s de préparation")
	assert_almost_eq(WHIP.windup, 0.35, 0.001, "fouet : 0,35 s")
	assert_almost_eq(RUSH.windup, 0.4, 0.001, "charge du bondissant : 0,4 s")
	for attack: AttackData in [SWORD_1, SWORD_3, WAVE, BITE, WHIP]:
		assert_gt(attack.hitstop, 0.0, "%s : arrêt sur image" % attack.id)
		assert_lt(attack.hitstop, 0.1, "%s : bref (sous 0,1 s)" % attack.id)
		assert_gt(attack.shake, 0.0, "%s : secousse" % attack.id)
		assert_lt(attack.shake, 0.1, "%s : sobre (sous 10 cm)" % attack.id)
	assert_gt(SWORD_3.hitstop, SWORD_1.hitstop, "le 3e coup pèse plus")
	assert_gt(BITE.shake, SWORD_1.shake, "un coup reçu secoue plus qu'un coup donné")
	var big := load("res://data/enemies/timere_big.tres") as EnemyData
	assert_almost_eq(big.windup_scale, 1.5, 0.001, "le Grand se prépare plus lentement")
	assert_gt(big.strike_shake, 0.0, "le Grand fait trembler le sol")
	var tints := {}
	for enemy_id: String in ["timere_small", "timere_normal", "timere_runner", "timere_big"]:
		var data := load("res://data/enemies/%s.tres" % enemy_id) as EnemyData
		tints[data.tint.to_html()] = enemy_id
		assert_true(
			data.tint.r <= 1.0 and data.tint.g <= 1.0 and data.tint.b <= 1.0,
			"%s : une teinte ne peut que foncer la planche" % enemy_id
		)
	assert_eq(tints.size(), 4, "chaque corps a sa teinte")


func test_fx_images_are_pixel_art_strips_at_their_size() -> void:
	for fx_name: String in IMAGES:
		var spec: Array = IMAGES[fx_name]
		var image := CombatFx.texture(fx_name)
		assert_not_null(image, "src/combat/fx/%s.png" % fx_name)
		if image == null:
			continue
		assert_eq(image.get_width(), int(spec[0]) * int(spec[2]), "%s : largeur" % fx_name)
		assert_eq(image.get_height(), int(spec[1]), "%s : hauteur" % fx_name)
		assert_eq(CombatFx.frame_count(fx_name), int(spec[2]), "%s : images" % fx_name)
		if CombatFx.STRIPS.has(fx_name):
			var frames := CombatFx.sprite_frames(fx_name)
			assert_eq(frames.get_frame_count(&"default"), int(spec[2]), "%s : bande" % fx_name)
	assert_almost_eq(CombatFx.PIXEL_SIZE, 1.0 / 96.0, 0.00001, "96 px par mètre")
	# Le coup d'épée au sol couvre la portée de l'épée (1,2 m) à 96 px/m.
	assert_eq(int(IMAGES["slash"][1]), roundi(1.25 * 96.0))


# --- Éclats, arrêt sur image ------------------------------------------------------------------


func test_burst_plays_once_and_frees_itself() -> void:
	var near := Node3D.new()
	_root.add_child(near)
	var burst := CombatFx.spawn_burst(near, "impact", Vector3(1.0, 0.7, 0.0), CombatFx.COLOR_SWORD)
	assert_not_null(burst)
	assert_eq(burst.get_parent(), _root, "posé à côté de near (il ne le suit pas)")
	assert_true(burst.is_playing(), "joué")
	assert_true(burst.no_depth_test, "devant sa cible")
	assert_almost_eq(burst.global_position, Vector3(1.0, 0.7, 0.0), Vector3.ONE * 0.001)
	# Un objet libéré capturé tel quel par la lambda ferait une erreur moteur : référence faible.
	var ref: WeakRef = weakref(burst)
	var freed: bool = await wait_until(func() -> bool: return ref.get_ref() == null, 1.0)
	assert_true(freed, "libéré à la fin de son animation")


func test_effects_go_to_the_zone_not_to_the_enemies_container() -> void:
	var zone := Zone.new()
	_root.add_child(zone)
	var enemies := Node3D.new()
	enemies.name = "Enemies"
	zone.add_child(enemies)
	var body := Node3D.new()
	enemies.add_child(body)
	assert_eq(CombatFx.host_for(body), zone, "jamais sous Enemies (on en compte les enfants)")
	var burst := CombatFx.spawn_burst(body, "dust", Vector3.ZERO, CombatFx.COLOR_DUST)
	assert_eq(burst.get_parent(), zone)
	assert_eq(enemies.get_child_count(), 1)
	assert_false(burst.no_depth_test, "la poussière reste au sol, derrière les corps")


func test_freeze_holds_a_node_then_restores_it() -> void:
	var node := Node3D.new()
	node.process_mode = Node.PROCESS_MODE_PAUSABLE
	_root.add_child(node)
	CombatFx.freeze(node, 0.1)
	CombatFx.freeze(node, 0.2)
	assert_true(CombatFx.is_frozen(node))
	assert_eq(node.process_mode, Node.PROCESS_MODE_DISABLED, "figé")
	await wait_seconds(0.15)
	assert_true(CombatFx.is_frozen(node), "le gel le plus long court encore")
	await wait_seconds(0.15)
	assert_false(CombatFx.is_frozen(node))
	assert_eq(node.process_mode, Node.PROCESS_MODE_PAUSABLE, "mode d'origine rétabli")


# --- Caméra fixe : secousse, orientation des sprites ------------------------------------------


func test_shake_moves_the_image_without_turning_the_camera() -> void:
	var camera := _camera()
	var basis := camera.global_basis
	var shake := ScreenShake.new()
	_root.add_child(shake)
	ScreenShake.kick_in(get_tree(), 0.06, Vector3.RIGHT)
	assert_almost_eq(shake.current_amplitude(), 0.06, 0.001, "trouvée par son groupe")
	var widest := Vector2.ZERO
	for _i in 6:
		await wait_seconds(0.02)
		var offset := Vector2(camera.h_offset, camera.v_offset)
		if offset.length() > widest.length():
			widest = offset
	assert_gt(absf(widest.x), 0.01, "un coup venu de l'ouest pousse l'image de côté")
	assert_gt(absf(widest.x), absf(widest.y), "surtout de côté")
	assert_lte(widest.length(), 0.06 * 1.1, "jamais plus que la secousse demandée")
	assert_almost_eq(camera.global_basis.x, basis.x, Vector3.ONE * 0.0001, "pas de rotation")
	await wait_seconds(0.6)
	assert_eq(shake.current_amplitude(), 0.0, "amortie en une demi-seconde")
	assert_eq(Vector2(camera.h_offset, camera.v_offset), Vector2.ZERO, "image rendue à sa place")


func test_weaker_shake_does_not_cut_a_stronger_one() -> void:
	var shake := ScreenShake.new()
	_root.add_child(shake)
	shake.kick(0.08)
	shake.kick(0.02)
	assert_almost_eq(shake.current_amplitude(), 0.08, 0.001)
	shake.kick(5.0)
	assert_almost_eq(shake.current_amplitude(), shake.max_amplitude, 0.001, "plafonnée")


func test_screen_geometry_of_the_fixed_camera() -> void:
	var camera := _camera()
	assert_almost_eq(CombatFx.screen_length(camera, Vector3.RIGHT * 2.0), 2.0, 0.01, "est-ouest")
	assert_almost_eq(
		CombatFx.screen_length(camera, Vector3.FORWARD * 2.0),
		2.0 * sin(deg_to_rad(PITCH_DEG)),
		0.01,
		"nord-sud écrasé par l'inclinaison"
	)
	assert_almost_eq(
		CombatFx.screen_direction(camera, Vector3.FORWARD),
		Vector2(0.0, 1.0),
		Vector2.ONE * 0.01,
		"le nord en haut de l'écran"
	)
	var east := CombatFx.facing_basis(camera, Vector3.RIGHT)
	assert_almost_eq(east.y, Vector3.RIGHT, Vector3.ONE * 0.01, "vers l'est : vers la droite")
	assert_almost_eq(east.z, camera.global_basis.z, Vector3.ONE * 0.01, "face à la caméra")
	var north := CombatFx.facing_basis(camera, Vector3.FORWARD)
	assert_almost_eq(north.y, camera.global_basis.y, Vector3.ONE * 0.01, "vers le nord : en haut")


func test_wave_sprite_faces_the_camera_and_points_where_it_flies() -> void:
	var camera := _camera()
	var waves: Array[ChargeWave] = []
	for direction: Vector3 in [Vector3.RIGHT, Vector3.FORWARD]:
		var wave := WAVE_SCENE.instantiate() as ChargeWave
		_root.add_child(wave)
		wave.set_physics_process(false)
		wave.launch(direction, null)
		waves.append(wave)
	var east := (waves[0].get_node(^"Sprite") as Sprite3D).global_basis
	var north := (waves[1].get_node(^"Sprite") as Sprite3D).global_basis
	assert_almost_eq(east.y.normalized(), Vector3.RIGHT, Vector3.ONE * 0.01, "bosse vers l'est")
	assert_almost_eq(
		east.z, camera.global_basis.z, Vector3.ONE * 0.01, "de face, pas par la tranche"
	)
	assert_almost_eq(
		north.y.normalized(), camera.global_basis.y, Vector3.ONE * 0.01, "bosse vers le haut"
	)
	# Aussi large à l'écran que la trace au sol : 2 m vers le nord, 2 m écrasés vers l'est.
	assert_almost_eq(north.x.length(), 1.0, 0.02, "2 m de large (image de 2 m)")
	assert_almost_eq(east.x.length(), sin(deg_to_rad(PITCH_DEG)), 0.02, "2 m nord-sud à l'écran")
	var trace := waves[0].get_node(^"Mesh") as MeshInstance3D
	var plane := trace.mesh as PlaneMesh
	assert_almost_eq(plane.size.x * trace.scale.x, WAVE.width_m, 0.01, "trace : largeur de l'onde")
	assert_lt(trace.position.y, 0.1, "trace posée au sol")


# --- Éclair, joueur -----------------------------------------------------------------------------


func test_hit_flash_takes_the_shape_of_the_sprite_then_ends() -> void:
	var visual := VISUAL.instantiate() as CharacterVisual
	_root.add_child(visual)
	visual.set_skin(SkinRegistry.default_skin())
	visual.scale = Vector3.ONE * 1.3
	visual.set_facing(Vector3.LEFT)
	var sprite := visual.get_node(^"Sprite") as AnimatedSprite3D
	var flash := HitFlash.new()
	_root.add_child(flash)
	flash.bind(sprite)
	flash.flash(0.1)
	assert_true(flash.is_flashing())
	assert_eq(flash.animation, sprite.animation, "même animation")
	assert_eq(flash.frame, sprite.frame, "même image")
	assert_eq(flash.flip_h, sprite.flip_h, "même côté")
	assert_eq(flash.offset, sprite.offset, "même ancre")
	assert_almost_eq(flash.global_basis.get_scale(), Vector3.ONE * 1.3, Vector3.ONE * 0.001)
	assert_true(flash.material_override is ShaderMaterial, "silhouette peinte (hit_flash.gdshader)")
	# Un Timere touché passe à « degats » juste après l'éclair : la silhouette suit aussitôt.
	visual.play(&"degats", true)
	assert_eq(flash.animation, sprite.animation, "suit le changement d'animation sans attendre")
	assert_eq(flash.frame, sprite.frame)
	await wait_seconds(0.2)
	assert_false(flash.is_flashing(), "fini")
	assert_false(flash.visible)


func test_slash_is_drawn_on_coup_frames_at_the_sword_reach() -> void:
	var rig: Node3D = add_child_autofree(RIG.instantiate())
	var combat := rig.get_node(^"Combat") as PlayerCombat
	var visual := rig.get_node(^"Visual") as CharacterVisual
	visual.set(&"forced_hit_frames", {&"attaque": [1, 2, 3]})
	var slash := combat.fx_node(&"Slash")
	assert_not_null(slash, "Combat/Slash")
	combat.attack()
	visual.call(&"emit_frame", &"attaque", 0)
	assert_false(slash.visible, "pas avant les images « coup »")
	visual.call(&"emit_frame", &"attaque", 1)
	assert_true(slash.visible, "sur la 1re image « coup »")
	# Le secteur dessiné finit à range_m de la pointe (Combat), vers −Z.
	var tip := slash.position.z - 0.5 * PlayerCombat.SLASH_SIZE.y * slash.scale.z
	assert_almost_eq(-tip, SWORD_1.range_m + 0.05 * slash.scale.z, 0.01, "à la portée de l'épée")
	assert_almost_eq(slash.position.z + 0.5 * PlayerCombat.SLASH_SIZE.y * slash.scale.z, 0.0, 0.01)
	assert_gt(slash.scale.x, 0.0, "1er coup : balayé dans un sens")
	assert_true(
		(slash.material_override as StandardMaterial3D).no_depth_test, "par-dessus la cible"
	)
	combat.attack()
	visual.call(&"emit_frame", &"attaque", 3)
	visual.call(&"finish", &"attaque")
	assert_eq(combat.current_attack().id, &"sword_2")
	assert_false(slash.visible, "effacé à la fin du coup")
	visual.call(&"emit_frame", &"attaque", 1)
	assert_lt(slash.scale.x, 0.0, "2e coup : dans l'autre sens")
	# Lissage physique : retourné puis montré dans la même image, le trait est dessiné tout de
	# suite dans son nouveau sens, pas en train de s'écraser entre +x et −x.
	assert_almost_eq(
		slash.get_global_transform_interpolated().basis.x.x,
		slash.scale.x,
		0.01,
		"dessiné d'emblée retourné (lissage remis à zéro)"
	)


func test_telegraph_marks_appear_in_place_without_sliding() -> void:
	# Lissage physique (project.godot) : un décalque déplacé puis montré dans la même image
	# physique serait dessiné en train de glisser depuis son ancienne place (les pieds du Timere,
	# la zone du coup d'avant) pendant un pas de physique ; les signes du Telegraph remettent
	# leur lissage à zéro et apparaissent à leur place dès la première image.
	assert_true(get_tree().root.is_physics_interpolated_and_enabled(), "lissage physique actif")
	var timere := Node3D.new()
	_root.add_child(timere)
	var telegraph: Node3D = TelegraphScript.new()
	timere.add_child(telegraph)
	var ring := telegraph.get_node(^"Ring") as Node3D
	var lane := telegraph.get_node(^"Lane") as Node3D
	await wait_physics_frames(2)
	await get_tree().physics_frame
	# Dans l'image physique : comme _prepare() d'enemy.gd.
	telegraph.strike(Vector3(2.0, 0.0, 0.0), 0.5, Vector3.UP)
	var worst := absf(ring.get_global_transform_interpolated().origin.x - 2.0)
	for _i in 2:
		await wait_process_frames(1)
		worst = maxf(worst, absf(ring.get_global_transform_interpolated().origin.x - 2.0))
	assert_lt(worst, 0.001, "le cercle est dessiné à sa place dès la première image")
	await get_tree().physics_frame
	telegraph.rush(Vector3.RIGHT, 4.0, 0.8, Vector3.UP)
	worst = absf(lane.get_global_transform_interpolated().origin.x - 2.0)
	for _i in 2:
		await wait_process_frames(1)
		worst = maxf(worst, absf(lane.get_global_transform_interpolated().origin.x - 2.0))
	assert_lt(worst, 0.001, "le couloir aussi (milieu de la charge à 2 m)")


func test_sword_hit_freezes_the_swing_and_shakes() -> void:
	var rig: Node3D = add_child_autofree(RIG.instantiate())
	var combat := rig.get_node(^"Combat") as PlayerCombat
	var visual := rig.get_node(^"Visual") as CharacterVisual
	visual.set(&"forced_hit_frames", {&"attaque": [1, 2, 3]})
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	dummy.position = Vector3(0.0, 0.0, -1.0)
	await wait_physics_frames(3)
	combat.attack()
	visual.call(&"emit_frame", &"attaque", 1)
	await wait_physics_frames(2)
	assert_eq((dummy.get(&"hits") as Array).size(), 1, "touché")
	assert_true(CombatFx.is_frozen(visual), "arrêt sur image de la planche")
	assert_gt(combat.screen_shake().current_amplitude(), 0.0, "l'écran tressaille")
	await wait_seconds(SWORD_1.hitstop + 0.05)
	assert_false(CombatFx.is_frozen(visual), "elle repart")


func test_player_hit_flashes_and_shakes_toward_the_blow() -> void:
	var rig: Node3D = add_child_autofree(RIG.instantiate())
	var combat := rig.get_node(^"Combat") as PlayerCombat
	(rig.get_node(^"Visual") as CharacterVisual).set_skin(SkinRegistry.default_skin())
	var source: Node3D = add_child_autofree(Node3D.new())
	source.position = Vector3(-1.0, 0.0, 0.0)
	var hitbox: Hitbox = add_child_autofree(HITBOX.instantiate())
	hitbox.attack = BITE
	hitbox.team = &"enemy"
	hitbox.source = source
	hitbox.position = Vector3(0, 0.7, 0)
	await wait_physics_frames(2)
	hitbox.activate()
	await wait_physics_frames(2)
	assert_eq((rig.get_node(^"Health") as Health).current, 4, "mordu")
	var flash := combat.fx_node(&"HitFlash") as HitFlash
	assert_true(flash.is_flashing(), "éclair du joueur")
	assert_gt(combat.screen_shake().current_amplitude(), BITE.shake * 0.5, "secousse")


func test_lock_ring_and_aim_marker_follow_the_locked_target() -> void:
	_ground()
	var player := PLAYER.instantiate() as Player
	_root.add_child(player)
	var combat := player.combat
	var dummy: Node3D = add_child_autofree(DUMMY.instantiate())
	dummy.position = Vector3(3.0, 0.0, -1.0)
	await wait_physics_frames(3)
	var ring := combat.fx_node(&"LockRing")
	var aim := combat.fx_node(&"AimMarker")
	assert_false(ring.visible, "rien sans verrou")
	assert_false(aim.visible)
	var commands := Player.Commands.new()
	commands.lock = true
	player.set_physics_process(false)
	player.tick(1.0 / 60.0, commands)
	assert_eq(player.locked_target(), dummy, "verrouillé")
	await wait_process_frames(2)
	assert_true(ring.visible, "réticule au sol sous la cible")
	assert_almost_eq(ring.global_position.x, 3.0, 0.01)
	assert_almost_eq(ring.global_position.z, -1.0, 0.01)
	assert_lt(ring.global_position.y - dummy.global_position.y, 0.1, "posé au sol")
	assert_true(aim.visible, "chevron de visée")
	var toward := (aim.global_position - player.global_position).normalized()
	assert_gt(toward.dot(Vector3(3.0, 0.0, -1.0).normalized()), 0.95, "vers la cible")
	dummy.queue_free()
	await wait_physics_frames(2)
	player.tick(1.0 / 60.0, Player.Commands.new())
	await wait_process_frames(2)
	assert_false(ring.visible, "verrou perdu : réticule effacé")


func test_ground_shadow_stays_on_the_ground_during_a_jump() -> void:
	_ground()
	var player := PLAYER.instantiate() as Player
	_root.add_child(player)
	await wait_physics_frames(4)
	var shadow := player.combat.fx_node(&"GroundShadow")
	assert_not_null(shadow, "ombre nette du joueur")
	assert_true(shadow.visible)
	assert_almost_eq(shadow.global_position.y, CombatFx.SHADOW_LIFT, 0.02, "au sol")
	var plane := (shadow as MeshInstance3D).mesh as PlaneMesh
	assert_almost_eq(plane.size.x, 2.0 * PlayerCombat.SHADOW_RADIUS, 0.001)
	player.set_physics_process(false)
	player.global_position = Vector3(0.0, 1.5, 0.0)
	player.velocity = Vector3.UP
	player.move_and_slide()
	await wait_process_frames(2)
	assert_almost_eq(shadow.global_position.y, CombatFx.SHADOW_LIFT, 0.05, "reste au sol")
	assert_lt(shadow.global_basis.get_scale().x, 1.0, "plus petite en l'air")
