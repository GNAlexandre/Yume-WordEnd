extends GutTest
## (QC2) La vérification des places masquées de tools/exterior_pose.py (masked_places,
## clear_of_places), que tools/exterior_maps.py check applique à chaque carte du dehors
## (docs/QUALITE.md, QC-37 et QC-38) : un grand décor (2 m ou plus) posé au sud d'une place où l'on
## se tient ne couvre pas, vu de la caméra du jeu, la place d'un personnage debout là (1 m de part
## et d'autre, du pied à la tête) ; près d'une sortie, on ne fait que passer. Passé si Python ou
## Pillow n'est pas là.

## Les cas, posés comme au sentier (le sentier à z 23-24, l'érable de la première embuscade à
## z 31,7, à sa plus grande taille dans sa famille : × 1,15) et à la colline (le tronc de premier
## plan au pied de la lisière est).
const CASES := """
import json, sys
sys.path.insert(0, sys.argv[1])
import exterior_pose as ep

class Fake:
    def __init__(self, exits=()):
        self.markers = {'from_village': (2.5, 24.0), 'Spawn': (40.0, 24.0)}
        self.points = {'premiere_embuscade': (16.0, 23.0)}
        self.places = {}
        self.paths = [('sentier', 3.0, [(1.0, 24.0), (60.0, 24.0)])]
        self.exits = [ep.Rect(*e) for e in exits]
        self.W, self.D = 60, 40
    def in_map(self, x, z, margin=0.0):
        return margin <= x <= self.W - margin and margin <= z <= self.D - margin
    def height(self, x, z):
        return 0.0

def masks(scene, x, z, sx, sz, bounds=(10, 9, 40, 23), scale=1.15):
    stands = ep._stand_cameras(Fake(), bounds, [('ici', sx, sz)])
    here = [s for s in stands if s[0] == 'ici'][0]
    panels = [ep.seam_panel('D', scene, x, 0.0, z, scale, f) for f in (False, True)]
    return any(ep._masks(q, here) for q in panels)

labels = [s[0] for s in ep.standing_places(Fake(exits=[(0.0, 22.0, 0.6, 26.0)]))]
print(json.dumps({
    'erable': masks('maple_a_forest', 16.0, 31.7, 16.0, 25.0),
    'erable_loin': masks('maple_a_forest', 16.0, 36.5, 16.0, 25.0),
    'erable_cote': masks('maple_a_forest', 24.0, 31.7, 16.0, 25.0),
    'tronc_frole': masks('fg_trunk_a', 29.7, 39.3, 31.0, 36.0, (10, 6, 20, 26)),
    'tronc_ecarte': masks('fg_trunk_a', 33.5, 39.3, 31.0, 36.0, (10, 6, 20, 26)),
    'buisson': masks('fg_grass', 16.0, 25.0, 16.0, 23.0),
    'sortie': 'marqueur from_village' in labels,
    'spawn': 'marqueur Spawn' in labels,
    'point': 'point premiere_embuscade' in labels,
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


func _case(case_name: String) -> Variant:
	if _missing:
		pending("python3 ou Pillow absent : %s" % _output.substr(0, 120))
		return null
	assert_false(_cases.is_empty(), "masked_places répond : %s" % _output.substr(0, 400))
	return _cases.get(case_name)


func test_a_tall_tree_south_of_the_path_masks_the_ambush_point() -> void:
	assert_eq(
		_case("erable"),
		true,
		"l'érable de premier plan à 6,7 m au sud couvre Chtholly (vue de la première embuscade)"
	)


func test_a_tree_far_enough_south_or_aside_does_not() -> void:
	assert_eq(
		_case("erable_loin"), false, "à 11,5 m au sud, seule sa couronne paraît au bas de l'écran"
	)
	assert_eq(_case("erable_cote"), false, "8 m à l'est, il ne la touche pas")


func test_a_trunk_brushing_the_player_counts() -> void:
	assert_eq(_case("tronc_frole"), true, "un tronc de 10 m à côté d'elle fend l'écran (colline)")
	assert_eq(_case("tronc_ecarte"), false, "écarté de 2,5 m, il ne gêne plus")


func test_low_foreground_never_counts() -> void:
	assert_eq(_case("buisson"), false, "une herbe de premier plan (1,5 m) ne compte pas")


func test_places_near_an_exit_are_left_out() -> void:
	assert_eq(_case("sortie"), false, "le marqueur d'arrivée près de la sortie : on y passe")
	assert_eq(_case("spawn"), true, "un marqueur loin des sorties compte")
	assert_eq(_case("point"), true, "un point du plan compte")
