extends SceneTree
## Charge une scène, attend un vrai rendu, écrit un PNG et quitte (PLAN.md section 6).
## Lancé par tools/screenshot.sh (Xvfb + Mesa llvmpipe, 1280 × 720) :
##   -- <res://scene.tscn> <sortie.png> [images à attendre, défaut 12]

const DEFAULT_FRAMES := 12


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# Les autoloads n'existent qu'après la première image d'un script SceneTree.
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage : -- <scene.tscn> <sortie.png> [images]")
		quit(2)
		return
	var packed := load(args[0]) as PackedScene
	if packed == null:
		printerr("scène introuvable : %s" % args[0])
		quit(2)
		return
	get_root().add_child(packed.instantiate())
	var frames := int(args[2]) if args.size() > 2 else DEFAULT_FRAMES
	for _i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	var err := image.save_png(args[1])
	if err != OK:
		printerr("écriture impossible : %s (%s)" % [args[1], error_string(err)])
	quit(0 if err == OK else 1)
