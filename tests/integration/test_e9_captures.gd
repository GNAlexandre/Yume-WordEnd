extends GutTest
## (E9) Aucun préréglage ne rend une vue illisible : la vraie partie est rendue sous Xvfb (le rendu
## sans écran des tests est factice) par tools/e9_shots.sh (tests/integration/demo_e9.tscn), une
## capture par préréglage ; la luminance moyenne de chacune, et celle du tiers du milieu de
## l'écran (autour du joueur), restent au-dessus d'un seuil, et chaque vue tient dans le budget
## de draw calls. Chaque moment au clair, la pluie et l'averse, un intérieur de jour et de nuit.
## Sans xvfb-run (machine sans affichage virtuel), le test est en attente.

## Vues rendues (lieu:moment:temps, demo_e9.gd).
const VIEWS: Array[String] = [
	"essai:aube:clair",
	"essai:matin:clair",
	"essai:apres_midi:clair",
	"essai:couchant:clair",
	"essai:nuit:clair",
	"essai:couchant:pluie",
	"essai:nuit:averse",
	"dedans:apres_midi:clair",
	"dedans:nuit:clair",
	"village:nuit:averse",
]
## Seuils (ceux de demo_e9.gd) et budget de draw calls par vue (PLAN.md section 9).
const LUMA_FLOOR := 0.1
const CENTER_FLOOR := 0.12
const MAX_DRAW_CALLS := 200
const LINE := "^E9 vue (\\S+) : luminance ([0-9.]+) .*centre ([0-9.]+) .*, (\\d+) draw calls"


func test_no_preset_makes_a_view_unreadable() -> void:
	if OS.execute("bash", ["-c", "command -v xvfb-run"]) != 0:
		pending("xvfb-run absent : captures impossibles ici")
		return
	var output: Array = []
	var script := ProjectSettings.globalize_path("res://tools/e9_shots.sh")
	var arguments := PackedStringArray([script])
	arguments.append_array(VIEWS)
	var code := OS.execute("bash", arguments, output, true)
	var text := "\n".join(output)
	var pattern := RegEx.create_from_string(LINE)
	var seen: Array[String] = []
	for line: String in text.split("\n"):
		var found := pattern.search(line)
		if found == null:
			continue
		var view := found.get_string(1)
		seen.append(view)
		assert_gt(float(found.get_string(2)), LUMA_FLOOR, "%s : luminance de l'écran" % view)
		assert_gt(float(found.get_string(3)), CENTER_FLOOR, "%s : autour du joueur" % view)
		assert_lte(int(found.get_string(4)), MAX_DRAW_CALLS, "%s : draw calls" % view)
	assert_eq(seen.size(), VIEWS.size(), "toutes les vues rendues :\n%s" % text)
	assert_eq(code, 0, "tools/e9_shots.sh (build/shots/e9/e9.log)")
