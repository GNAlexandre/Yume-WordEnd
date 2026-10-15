extends GutTest
## (QC-S) La vérification des bouts de pans à raccord de tools/exterior_pose.py (open_seams), que
## tools/exterior_maps.py check applique à chaque carte du dehors (docs/QUALITE.md, QC-33) : un pan
## de forêt (forest_wall_*, à raccord gauche-droite) dont le bout est libre se voit comme une bande
## de feuillage coupée net ; un bout qui touche un autre pan du même rang, ou caché par un décor
## posé devant lui, ne compte pas ; une haie basse (moins de 2 m pleins au bord) non plus. Passé
## si Python ou Pillow n'est pas là.

## Les cas, posés comme dans le sentier : le pan de forêt de l'ouest (x 0 → 16, z 18,2), vu des
## points visés du sentier (x 4,5 → 27,5 ; z 21).
const CASES := """
import json, sys
sys.path.insert(0, sys.argv[1])
import exterior_pose as ep
focus = [(x + 0.5, 21.0) for x in range(4, 28)]
def ends(*panels):
    found = ep.open_seams(list(panels), focus)
    return sorted('%s %s %.1f' % (n, s, x) for n, s, x, _z, _f in found)
wall = ep.seam_panel('Mur', 'forest_wall_d', 8.0, 0.0, 18.2)
print(json.dumps({
    'seul': ends(wall),
    'joint': ends(wall, ep.seam_panel('Voisin', 'forest_wall_a', 24.0, 0.0, 18.2, flip=True)),
    'cache': ends(wall, ep.seam_panel('Chene', 'oak_a', 15.67, 0.0, 18.7)),
    'haie': ends(ep.seam_panel('Haie', 'bramble_hedge', 8.0, 0.0, 18.2)),
}))
"""

var _cases: Dictionary = {}
## Python ou Pillow absent : les tests passent (pending) ; toute autre sortie sans résultat échoue.
var _missing: bool = false
var _output: String = ""


func before_all() -> void:
	var tools := ProjectSettings.globalize_path("res://tools")
	var output: Array = []
	var code := OS.execute("python3", ["-c", CASES, tools], output, true)
	_output = "\n".join(PackedStringArray(output))
	_missing = code == -1 or _output.contains("No module named")
	var parsed: Variant = JSON.parse_string(_output.strip_edges().split("\n")[-1])
	if code == 0 and parsed is Dictionary:
		_cases = parsed


func _case(case_name: String) -> Array:
	if _missing:
		pending("python3 ou Pillow absent : %s" % _output.substr(0, 120))
		return []
	assert_false(_cases.is_empty(), "open_seams répond : %s" % _output.substr(0, 400))
	return _cases.get(case_name, [])


func test_a_lone_forest_wall_shows_both_cut_ends() -> void:
	var ends := _case("seul")
	if _cases.is_empty():
		return
	assert_has(ends, "Mur est 16.0", "le bout côté marais se voit (la bande de l'embuscade)")
	assert_has(ends, "Mur ouest 0.0", "l'autre bout aussi, dans le champ")


func test_two_walls_end_to_end_hide_their_joint() -> void:
	var ends := _case("joint")
	if _cases.is_empty():
		return
	assert_does_not_have(ends, "Mur est 16.0", "joint : bout contre bout")
	assert_does_not_have(ends, "Voisin ouest 16.0", "joint : bout contre bout")
	assert_has(ends, "Voisin est 32.0", "le bout libre du second pan reste")


func test_an_oak_in_front_hides_the_cut_end() -> void:
	var ends := _case("cache")
	if _cases.is_empty():
		return
	assert_does_not_have(ends, "Mur est 16.0", "le chêne couvre le bout du pied à la cime")
	assert_has(ends, "Mur ouest 0.0", "l'autre bout, sans cache, reste")


func test_a_low_hedge_end_is_not_a_band() -> void:
	var ends := _case("haie")
	if _cases.is_empty():
		return
	assert_eq(ends, [], "une haie qui finit se lit comme une haie qui finit")
