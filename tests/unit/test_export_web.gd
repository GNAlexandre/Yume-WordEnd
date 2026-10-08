extends GutTest
## Export Web (Lot 9) : preset mono-thread et ses options, shell HTML, fichiers du site, CI et
## mesure de taille (tools/build_size.sh).

const PRESET := "preset.0"
const OPTIONS := "preset.0.options"

var _presets: ConfigFile


func before_all() -> void:
	_presets = ConfigFile.new()
	assert_eq(_presets.load("res://export_presets.cfg"), OK, "export_presets.cfg lisible")


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func test_single_web_preset_without_threads() -> void:
	assert_eq(_presets.get_value(PRESET, "name", ""), "Web")
	assert_eq(_presets.get_value(PRESET, "platform", ""), "Web")
	# (bureau) Windows et Linux ont leurs préréglages (tests/unit/test_desktop.gd) : le Web reste
	# le premier et le seul de sa plateforme.
	var web_presets: Array[String] = []
	for section: String in _presets.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			if _presets.get_value(section, "platform", "") == "Web":
				web_presets.append(section)
	assert_eq(web_presets, [PRESET] as Array[String], "un seul preset Web")
	assert_eq(_presets.get_value("runnable_presets", "Web", ""), "Web", "preset lancé par défaut")
	assert_false(_presets.get_value(OPTIONS, "variant/thread_support", true), "pas de COOP/COEP")
	assert_false(
		_presets.get_value(OPTIONS, "variant/extensions_support", true), "pas de GDExtension"
	)
	assert_false(_presets.get_value(OPTIONS, "progressive_web_app/enabled", true), "pas de PWA")


func test_export_path_and_filters() -> void:
	assert_eq(_presets.get_value(PRESET, "export_path", ""), "build/web/index.html")
	assert_eq(_presets.get_value(PRESET, "export_filter", ""), "all_resources")
	var excluded: String = _presets.get_value(PRESET, "exclude_filter", "")
	for pattern: String in ["addons/gut/*", "tests/*", "tools/*", "docs/*", "build/*", "web/*"]:
		assert_true(excluded.contains(pattern), "%s hors du paquet" % pattern)


func test_textures_for_desktop_and_mobile() -> void:
	assert_true(_presets.get_value(OPTIONS, "vram_texture_compression/for_desktop", false))
	assert_true(_presets.get_value(OPTIONS, "vram_texture_compression/for_mobile", false))
	assert_true(
		ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false),
		"ETC2/ASTC importés : requis par la compression mobile"
	)


func test_canvas_follows_the_iframe() -> void:
	assert_eq(_presets.get_value(OPTIONS, "html/canvas_resize_policy", -1), 2, "Adaptive")
	assert_true(_presets.get_value(OPTIONS, "html/focus_canvas_on_start", false), "focus")
	assert_true(_presets.get_value(OPTIONS, "html/export_icon", false), "icône")
	assert_false(_presets.get_value(OPTIONS, "html/experimental_virtual_keyboard", true))


func test_custom_shell_keeps_godot_placeholders() -> void:
	var path: String = _presets.get_value(OPTIONS, "html/custom_html_shell", "")
	assert_eq(path, "res://web/shell.html")
	var shell := _text(path)
	for placeholder: String in [
		"$GODOT_URL", "$GODOT_CONFIG", "$GODOT_THREADS_ENABLED", "$GODOT_HEAD_INCLUDE"
	]:
		assert_true(shell.contains(placeholder), "shell : %s" % placeholder)
	assert_true(shell.contains('<canvas id="canvas"'), "canvas attendu par le moteur")
	assert_true(shell.contains('lang="fr"'))
	assert_true(shell.contains("isWebGLAvailable(2)"), "WebGL 2 vérifié")
	assert_true(shell.contains("WordEnd a besoin de WebGL 2"), "message clair sans WebGL 2")
	assert_true(shell.contains("onProgress"), "barre de téléchargement")
	assert_true(shell.contains("touch-action: none"), "pas de défilement sous les doigts")


func test_site_files() -> void:
	assert_eq(_text("res://web/CNAME").strip_edges(), "jeu.yumenovel.fr")
	var page := _text("res://web/embed-test.html")
	assert_true(page.contains('allow="fullscreen; gamepad; autoplay"'), "snippet de la section 10")
	assert_true(page.contains("aspect-ratio:16/9"))
	assert_true(page.contains("requestFullscreen"), "bouton plein écran")
	assert_true(page.contains("WebGL 2"), "note WebGL 2")


func test_ci_builds_checks_size_and_deploys_main_only() -> void:
	var ci := _text("res://.github/workflows/ci.yml")
	assert_false(ci.is_empty(), "ci.yml lisible")
	assert_true(ci.contains("barichello/godot-ci:4.7.2"))
	assert_true(ci.contains("tools/check.sh"))
	assert_true(ci.contains("tools/build_size.sh"), "budget de taille")
	assert_true(ci.contains("safe.directory"), "git utilisable dans le conteneur")
	assert_true(ci.contains("github.ref == 'refs/heads/main'"), "déploiement depuis main seulement")
	assert_true(ci.contains("actions/deploy-pages"))
	assert_true(ci.contains("pages: write") and ci.contains("id-token: write"))


func test_build_size_script_budget() -> void:
	if not FileAccess.file_exists("/bin/bash") or OS.get_name() == "Windows":
		pending("bash indisponible")
		return
	var dir := ProjectSettings.globalize_path("user://l9_build_size")
	DirAccess.make_dir_recursive_absolute(dir)
	var wasm := FileAccess.open(dir.path_join("index.wasm"), FileAccess.WRITE)
	var noise := PackedByteArray()
	noise.resize(300_000)
	for i in noise.size():
		noise[i] = (i * 7919 + i * i) % 251
	wasm.store_buffer(noise)
	wasm.close()
	FileAccess.open(dir.path_join("index.pck"), FileAccess.WRITE).store_string("pck")
	var script := ProjectSettings.globalize_path("res://tools/build_size.sh")
	var output: Array = []
	assert_eq(OS.execute("bash", [script, dir, "25"], output), 0, "sous le budget")
	assert_string_contains(str(output), "compressé")
	assert_eq(OS.execute("bash", [script, dir, "0"], output), 1, "au-delà du budget")
	var empty := ProjectSettings.globalize_path("user://l9_build_size_vide")
	assert_eq(OS.execute("bash", [script, empty], output), 2, "build absent")
	for file: String in ["index.wasm", "index.pck"]:
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)


func test_check_enforces_the_size_budget() -> void:
	# (HD-2D) tools/check.sh échoue si l'export dépasse le budget (100 Mo compressés).
	var check := FileAccess.get_file_as_string("res://tools/check.sh")
	assert_string_contains(check, "tools/build_size.sh build/web")
	assert_string_contains(check, "au-delà du budget")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	assert_false(presets.contains("assets/models"), "plus de modèles 3D à exporter")
