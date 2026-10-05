extends Control
## Menu principal minimal du Lot 0 : « Nouvelle partie » avec le skin par défaut.
## Propriétaire : L10 (sélection du skin, Continuer, crédits, « Cliquer pour jouer »).

@onready var _new_game_button: Button = %NewGameButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	var skin := SkinRegistry.default_skin()
	SaveManager.new_game(skin.id if skin != null else &"")
