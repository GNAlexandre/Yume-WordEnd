class_name Examinable
extends Area3D
## (T2) Objet à examiner (docs/lore/CARTE.md, section 3 : la colonne « À examiner » des plans) :
## une zone d'interaction (couche 6, groupe « interactable », contrat Interactable de PLAN.md
## section 3) posée devant un meuble, un élément de mur ou une fenêtre. Le joueur y lit l'invite
## « Examiner » ; un appui affiche une courte description dans la boîte de dialogue, sans nom ni
## portrait, par DialogueRunner (le protocole des dialogues : dialogue_started, dialogue_line,
## dialogue_ended ; le joueur est figé le temps de la lecture, un seul dialogue à la fois).
##
## Les textes sont des données : data/texts/entrepot.json (TEXTS_PATH), au format des textes de
## l'histoire (data/texts/story.json, DialogueRunner.load_story_texts : objets de textes, clés
## « _… » : commentaires) ; text_key en est le chemin (« entrepot_rdc/cuisine_fourneau »). Un texte
## se lit en plusieurs pages, séparées par une ligne vide ; {player} y est remplacé. Invite par
## défaut : la clé « prompt » du fichier. Le dialogue porte l'identifiant dialogue_id()
## (« examine_<clé> », aucun PNJ de ce nom : pas de portrait) ; le signal examined suit sa fin.
## La zone (BoxShape3D de taille size, au-dessus du nœud) est créée au chargement : la scène ne
## pose que le nœud, au pied de ce qu'on examine, côté où l'on se tient.

## Le texte a été lu jusqu'au bout (fin du dialogue).
signal examined(text_key: String)

## Textes des objets à examiner de l'entrepôt.
const TEXTS_PATH := "res://data/texts/entrepot.json"
## Couche 6 (interactable), groupe des interactables (PLAN.md, section 3).
const INTERACTABLE_LAYER := 32
const INTERACTABLE_GROUP := &"interactable"
## Invite quand le fichier n'en donne pas.
const DEFAULT_PROMPT := "Examiner"
## Préfixe de l'identifiant du dialogue (dialogue_started, dialogue_ended).
const DIALOGUE_PREFIX := "examine_"

## Fichiers de textes déjà lus (chemin → données).
static var _texts: Dictionary = {}

## Chemin du texte dans le fichier (« entrepot_rdc/cuisine_fourneau »).
@export var text_key: String = ""
## Invite ; vide : la clé « prompt » du fichier, sinon DEFAULT_PROMPT.
@export var prompt: String = ""
## Taille de la zone d'interaction (m), posée sur le sol au-dessus du nœud.
@export var size: Vector3 = Vector3(1.0, 1.6, 0.8)
## Fichier des textes (les tests en lisent d'autres).
@export_file("*.json") var texts_path: String = TEXTS_PATH

var _runner: TextRunner = null


## Déroule une suite de pages sans PNJ par le protocole de DialogueRunner.
class TextRunner:
	extends DialogueRunner

	## Démarre la lecture des pages (sans effet si un dialogue est déjà en cours).
	func show_pages(dialogue_id: StringName, pages: PackedStringArray) -> bool:
		if is_any_running() or pages.is_empty():
			return false
		var nodes := {}
		for index in pages.size():
			var page := {"speaker": "", "text": pages[index]}
			if index + 1 < pages.size():
				page["next"] = "page_%d" % (index + 1)
			nodes["page_%d" % index] = page
		_npc_id = dialogue_id
		_speaker = ""
		_line_speaker_id = &""
		_nodes = nodes
		_running = true
		_active = self
		EventBus.dialogue_choice_made.connect(_on_dialogue_choice_made)
		EventBus.dialogue_started.emit(_npc_id)
		_enter("page_0")
		return true


func _ready() -> void:
	collision_layer = INTERACTABLE_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group(INTERACTABLE_GROUP)
	var shape := BoxShape3D.new()
	shape.size = size
	var holder := CollisionShape3D.new()
	holder.name = "CollisionShape3D"
	holder.shape = shape
	holder.position = Vector3(0.0, size.y / 2.0, 0.0)
	add_child(holder, false, Node.INTERNAL_MODE_FRONT)
	_runner = TextRunner.new()
	_runner.name = "TextRunner"
	add_child(_runner, false, Node.INTERNAL_MODE_FRONT)
	EventBus.dialogue_ended.connect(_on_dialogue_ended)


## Invite de l'interactable (contrat Interactable).
func get_prompt() -> String:
	if not prompt.is_empty():
		return prompt
	var from_file := lookup(texts_path, "prompt")
	return from_file if not from_file.is_empty() else DEFAULT_PROMPT


## Interaction du joueur (contrat Interactable) : affiche le texte.
func interact(_player: Node3D) -> void:
	show_text()


## Affiche le texte dans la boîte de dialogue ; faux s'il manque ou si un dialogue est en cours.
func show_text() -> bool:
	var text := text_value()
	if text.is_empty():
		push_warning("Examinable %s : texte « %s » absent de %s" % [name, text_key, texts_path])
		return false
	var pages := PackedStringArray()
	for page: String in text.split("\n\n", false):
		pages.append(DialogueRunner.format_text(page.strip_edges()))
	return _runner != null and _runner.show_pages(dialogue_id(), pages)


## Texte brut (sans {player} remplacé) ; vide s'il manque.
func text_value() -> String:
	return lookup(texts_path, text_key)


## Identifiant du dialogue de cet objet : « examine_ » et la clé, « / » remplacés par « _ ».
func dialogue_id() -> StringName:
	return StringName(DIALOGUE_PREFIX + text_key.replace("/", "_"))


## Texte au chemin key_path (« entrepot_rdc/cuisine_fourneau ») d'un fichier de textes ; vide s'il
## manque ou si c'est un commentaire (clé « _… »). Le fichier est lu une fois (forget_texts()
## l'oublie).
static func lookup(path: String, key_path: String) -> String:
	if not _texts.has(path):
		_texts[path] = DialogueRunner.load_story_texts(path)
	var value: Variant = _texts[path]
	for key: String in key_path.split("/"):
		if key.begins_with("_"):
			return ""
		value = (value as Dictionary).get(key) if value is Dictionary else null
	return value if value is String else ""


## Oublie les fichiers lus (tests).
static func forget_texts() -> void:
	_texts.clear()


func _on_dialogue_ended(dialogue: StringName) -> void:
	if dialogue == dialogue_id():
		examined.emit(text_key)
