extends GutTest
## (E5) La faune dans la vraie partie : la forêt d'essai est rendue sous Xvfb (le rendu sans écran
## des tests est factice) par tools/e5_shots.sh (tests/integration/demo_e5.tscn). Douze animaux
## dans le champ tiennent dans le budget de draw calls (200 au plus par vue, PLAN.md section 9), et
## la meute au couchant atteint bien l'attaque, un loup à la fois (état « attack » rencontré).
## Sans xvfb-run (machine sans affichage virtuel), le test est en attente.

const VIEWS: Array[String] = ["troupeau", "meute"]
const MAX_DRAW_CALLS := 200
const MIN_IN_VIEW := 12
const LINE := "^E5 vue (\\S+) : (\\d+) draw calls, (\\d+) primitives, (\\d+) animaux dans le champ"


func test_twelve_animals_in_view_fit_the_draw_call_budget() -> void:
	if OS.execute("bash", ["-c", "command -v xvfb-run"]) != 0:
		pending("xvfb-run absent : captures impossibles ici")
		return
	var output: Array = []
	var script := ProjectSettings.globalize_path("res://tools/e5_shots.sh")
	var arguments := PackedStringArray([script])
	arguments.append_array(VIEWS)
	var code := OS.execute("bash", arguments, output, true)
	var text := "\n".join(output)
	var pattern := RegEx.create_from_string(LINE)
	var seen: Dictionary = {}
	for line: String in text.split("\n"):
		var found := pattern.search(line)
		if found == null:
			continue
		seen[found.get_string(1)] = [int(found.get_string(2)), int(found.get_string(4))]
	assert_eq(seen.size(), VIEWS.size(), "toutes les vues rendues :\n%s" % text)
	assert_eq(
		code, 0, "tools/e5_shots.sh (build/shots/e5/e5.log) : la meute attaque, aucune erreur"
	)
	for view: String in seen:
		assert_lte(seen[view][0], MAX_DRAW_CALLS, "%s : draw calls" % view)
	var crowd: Array = seen.get("troupeau", [0, 0])
	assert_gte(crowd[1], MIN_IN_VIEW, "au moins douze animaux dans le champ de la vue « troupeau »")
	assert_lte(crowd[0], MAX_DRAW_CALLS, "douze animaux : au plus 200 draw calls (%s)" % crowd[0])
