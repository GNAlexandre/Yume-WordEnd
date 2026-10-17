class_name ModeText
extends RefCounted
## (X-L5) Les textes du choix du mode de jeu (data/texts/<île>/story.json, section « ui ») pour
## les écrans qui n'ont pas encore de partie : le menu principal, où StoryDirector n'a pas encore
## d'île, lit l'île de départ du monde. Aucun texte en dur : une clé absente donne une chaîne vide
## (test_mode_text.gd les vérifie toutes).

## Les deux modes, dans l'ordre du choix : le libre d'abord (défaut).
const MODES: Array[StringName] = [StoryPacing.FREE, StoryPacing.SCENARIO]


## Texte « ui/<key> » de l'île de départ ; vars : {clé} remplacées (par exemple {mode}).
static func text(key: String, vars: Dictionary = {}) -> String:
	var island := WorldAtlas.island_of(WorldManager.starting_map())
	if island.is_empty():
		island = WorldAtlas.DEFAULT_ISLAND
	var result := StoryData.text(island, "ui/" + key)
	for name: String in vars:
		result = result.replace("{%s}" % name, str(vars[name]))
	return result


## « Mode libre », « Mode scénarisé ».
static func mode_name(mode: StringName) -> String:
	return text("mode_" + String(mode))


## La phrase qui explique le mode.
static func blurb(mode: StringName) -> String:
	return text("mode_%s_blurb" % mode)


## L'autre mode.
static func other(mode: StringName) -> StringName:
	return StoryPacing.SCENARIO if mode == StoryPacing.FREE else StoryPacing.FREE
