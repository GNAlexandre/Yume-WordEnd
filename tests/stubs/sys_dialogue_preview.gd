extends Node3D
## (Systèmes et textes) Aperçu pour la capture build/shots/sys_dialogue.png : une scène à deux
## voix figée sur la réplique du second orateur (son portrait et son nom par "speaker_id",
## {player} remplacé par le nom du skin choisi, Chtholly par défaut). Les deux PNJ sont pris dans
## data/npcs au lancement : Willem et Nephren s'ils existent (étape fever de l'acte 1), sinon les
## deux premiers qui ont un portrait. Le dialogue est écrit dans user:// (rien dans le dépôt).
##   tools/screenshot.sh res://tests/stubs/sys_dialogue_preview.tscn build/shots/sys_dialogue.png 30

const PREFERRED: Array[StringName] = [&"willem", &"nephren"]
const DIALOGUE_PATH := "user://sys_dialogue_preview.json"

@onready var _first: Npc = $First
@onready var _second: Npc = $Second
@onready var _box: DialogueBox = $UI/DialogueBox


func _ready() -> void:
	var pair := speakers()
	if pair.size() < 2:
		return
	_first.data = pair[0]
	_second.data = pair[1]
	_box.characters_per_second = 0.0
	_play.call_deferred(pair[0], pair[1])


## Les deux orateurs de l'aperçu (moins de deux si data/npcs n'en a pas assez avec un portrait).
static func speakers() -> Array[NpcData]:
	var found: Array[NpcData] = []
	for npc_id: StringName in PREFERRED:
		var npc := DialogueRunner.find_npc(npc_id)
		if npc != null and DialogueBox.portrait_for(npc_id) != null:
			found.append(npc)
	if found.size() == PREFERRED.size():
		return found
	found.clear()
	var files := Array(DirAccess.get_files_at(DialogueRunner.NPCS_DIR))
	files.sort()
	for file_name: String in files:
		var npc_id := StringName(file_name.get_basename())
		if file_name.ends_with(".tres") and DialogueBox.portrait_for(npc_id) != null:
			found.append(DialogueRunner.find_npc(npc_id))
		if found.size() == 2:
			break
	return found


## Écrit la scène, la lance avec le premier PNJ et passe à la réplique du second.
func _play(first: NpcData, second: NpcData) -> void:
	var nodes := {
		"a": {"text": "Dors, {player}. Pas un mot de plus.", "next": "b"},
		"b":
		{
			"speaker_id": String(second.id),
			"text": "{player}. Café très sucré. Archives, toute la nuit.",
			"next": null,
		},
	}
	var file := FileAccess.open(DIALOGUE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"start": "a", "nodes": nodes}))
	file.close()
	var scene := first.duplicate() as NpcData
	scene.dialogue_path = DIALOGUE_PATH
	_first.runner.start(scene)
	if _first.runner.is_running():
		EventBus.dialogue_choice_made.emit(-1)
