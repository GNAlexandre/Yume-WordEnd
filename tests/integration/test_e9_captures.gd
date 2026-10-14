extends GutTest
## (E9) Aucun préréglage ne rend une vue illisible : la vraie partie est rendue sous Xvfb (le rendu
## sans écran des tests est factice) par tools/e9_shots.sh (tests/integration/demo_e9.tscn), une
## capture par préréglage ; la luminance moyenne de chacune, et celle du tiers du milieu de
## l'écran (autour du joueur), restent au-dessus d'un seuil, et chaque vue tient dans le budget
## de draw calls. Chaque moment au clair, la pluie et l'averse, un intérieur de jour et de nuit.
## (R1) Dans le vrai intérieur (entrepot_rdc_essai, réfectoire et couloir), la nuit reste lisible
## mais nettement plus sombre que le matin (fenêtres éteintes, lampes allumées), sans un draw
## call de plus.
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
	"refectoire:matin:clair",
	"refectoire:nuit:clair",
	"couloir:matin:clair",
	"couloir:nuit:clair",
]
## (R1) Intérieurs comparés (lieu), et part de la luminance du matin que la nuit ne dépasse pas.
const INTERIORS: Array[String] = ["refectoire", "couloir"]
const NIGHT_RATIO := 0.65
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
	var measured: Dictionary = {}
	for line: String in text.split("\n"):
		var found := pattern.search(line)
		if found == null:
			continue
		var view := found.get_string(1)
		seen.append(view)
		measured[view] = [float(found.get_string(2)), int(found.get_string(4))]
		assert_gt(float(found.get_string(2)), LUMA_FLOOR, "%s : luminance de l'écran" % view)
		assert_gt(float(found.get_string(3)), CENTER_FLOOR, "%s : autour du joueur" % view)
		assert_lte(int(found.get_string(4)), MAX_DRAW_CALLS, "%s : draw calls" % view)
	assert_eq(seen.size(), VIEWS.size(), "toutes les vues rendues :\n%s" % text)
	assert_eq(code, 0, "tools/e9_shots.sh (build/shots/e9/e9.log)")
	for place: String in INTERIORS:
		var day: Array = measured.get("%s:matin:clair" % place, [])
		var night: Array = measured.get("%s:nuit:clair" % place, [])
		if day.is_empty() or night.is_empty():
			continue
		assert_lt(float(night[0]), float(day[0]) * NIGHT_RATIO, "%s : la nuit se voit" % place)
		assert_lte(int(night[1]), int(day[1]), "%s : pas un draw call de plus la nuit" % place)
