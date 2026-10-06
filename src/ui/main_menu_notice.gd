extends CanvasLayer
## Avis du menu qui survit au passage au jeu (L10). main.gd libère le menu dès game_loaded ; or
## « Continuer » sur une sauvegarde illisible démarre quand même une nouvelle partie
## (SaveManager.load_game() → ERR_FILE_CORRUPT) : le menu ajoute cet avis à la racine de l'arbre
## pour que SaveManager.last_error reste lisible pendant le chargement puis dans le jeu. Il
## disparaît après `duration` secondes (pause comprise) ou au premier clic dessus.

const THEME := preload("res://src/ui/wordend_theme.tres")
## Nom du nœud sous la racine : un nouvel avis remplace le précédent.
const NODE_NAME := &"MenuNotice"

## Texte affiché.
var text: String = ""
## Durée d'affichage (s).
var duration: float = 9.0

var _panel: PanelContainer


func _init() -> void:
	name = NODE_NAME
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.theme = THEME
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.theme_type_variation = &"ErrorLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(760, 0)
	_panel.add_child(label)
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.position.y = 24.0
	_panel.gui_input.connect(_on_panel_gui_input)
	get_tree().create_timer(duration, true).timeout.connect(dismiss)


## Texte de l'avis affiché sous la racine de tree, "" s'il n'y en a pas.
static func current_text(tree: SceneTree) -> String:
	var notice := tree.root.get_node_or_null(NodePath(String(NODE_NAME)))
	return str(notice.get(&"text")) if notice != null else ""


## Fondu puis libération.
func dismiss() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var tween := create_tween()
	tween.tween_property(_panel, ^"modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)


func _on_panel_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		dismiss()
