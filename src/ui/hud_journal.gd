extends "res://src/ui/journal.gd"
## Journal de quêtes du HUD (nœud HUD/Journal de hud.tscn, Systèmes et textes) : le journal du
## Lot Q (journal.gd) dont les textes de quête affichés (titres de la liste, titre, résumé,
## étapes, aides) passent par DialogueRunner.format_text, comme le HUD et les dialogues :
## {player} devient le nom affiché du skin choisi. Après chaque mise à jour du détail
## (_show_details, appelée par refresh, select et track), les textes qui contiennent une
## variable sont remplacés, et l'objectif de shown_steps() avec eux.
## Sous-classe plutôt que modification de journal.gd : périmètre du lot ; à replier dans
## journal.gd quand ce fichier sera repris.


func _show_details() -> void:
	super()
	for label: Node in find_children("*", "Label", true, false):
		(label as Label).text = _formatted((label as Label).text)
	for button: Node in find_children("*", "Button", true, false):
		(button as Button).text = _formatted((button as Button).text)
	for row: Node in (get_node(^"%Steps") as Node).get_children():
		if row.has_meta(&"step"):
			var step: Dictionary = row.get_meta(&"step")
			step["objective"] = _formatted(str(step.get("objective", "")))
			row.set_meta(&"step", step)


## Texte avec ses variables remplacées ({player}, {count:…}…) ; inchangé sans « { ».
static func _formatted(text: String) -> String:
	return DialogueRunner.format_text(text) if text.contains("{") else text
