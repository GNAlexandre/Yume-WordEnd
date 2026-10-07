extends Node3D
## Démo de la production « Monde » de l'acte 1 (docs/lore/MONDE.md) : l'île flottante seule,
## avec le contenu des fichiers d'emplacement, vue par une caméra fixe. F6 dans l'éditeur.
##
## Captures : MONDE_VIEW=<vue> tools/screenshot.sh res://tests/integration/demo_monde.tscn
## build/shots/monde_<vue>.png 40
##   ile       : vue d'ensemble, l'île au-dessus de la mer de nuages ;
##   entrepot  : l'entrepôt des fées, sa cour et son puits ;
##   bois      : les bois du marais et le terrain d'entraînement ;
##   couchant  : le cercle de veille et sa cloche, le vieux poste de guet ;
##   port      : la rue du Port, le quai, le dirigeable du passeur et le Barocupot ;
##   colline   : la colline des étoiles, son belvédère et ses myosotis ;
##   bord, dessous : le bord de l'île et la roche suspendue (vérifications).
## Draw calls et primitives de l'image mesurée sont écrits dans le journal (« Monde vue … »).

## Vues fixes : position de l'œil, point visé, champ (degrés).
const VIEWS := {
	"ile": [Vector3(-118.0, 74.0, 150.0), Vector3(-4.0, -14.0, 0.0), 50.0],
	"entrepot": [Vector3(13.0, 7.5, 17.0), Vector3(-8.0, 2.0, -8.0), 60.0],
	"bois": [Vector3(6.0, 6.0, -30.0), Vector3(-6.0, 1.0, -56.0), 62.0],
	"couchant": [Vector3(-27.0, 5.5, 9.0), Vector3(-55.0, 1.0, -3.0), 60.0],
	"port": [Vector3(26.0, 9.0, 32.0), Vector3(-2.0, 0.0, 58.0), 62.0],
	"colline": [Vector3(30.0, 6.0, 14.0), Vector3(52.0, 6.0, -4.0), 60.0],
	"bord": [Vector3(-70.0, 3.0, -2.0), Vector3(-110.0, -25.0, 10.0), 62.0],
	"dessous": [Vector3(30.0, -40.0, 150.0), Vector3(0.0, -12.0, 0.0), 55.0],
}
## Image à laquelle les mesures sont écrites.
const MEASURE_FRAME := 30

var _view := ""
var _frames := 0

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	_view = OS.get_environment("MONDE_VIEW")
	if _view.is_empty():
		_view = "ile"
	var view: Array = VIEWS.get(_view, VIEWS["ile"])
	_camera.fov = view[2]
	_camera.look_at_from_position(view[0], view[1])
	_camera.make_current()


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == MEASURE_FRAME:
		print(
			(
				"Monde vue %s : %d draw calls, %d primitives"
				% [
					_view,
					Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
					Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				]
			)
		)
