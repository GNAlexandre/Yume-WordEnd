extends "res://tests/stubs/q_quest_test.gd"
## Acte 1, quête secondaire special_dessert « Le dessert spécial » (HISTOIRE.md 3.2), jouée avec
## le vrai moteur et les vrais dialogues : Willem la propose ; œufs de la marchande (qui ne vend
## pas volontiers à l'entrepôt), trois grappes de baies, crème du café La Clochette ; Willem
## cuisine (les ingrédients sont pris) ; Collon et les petites tombent de l'arbre ; Lakhesh sert ;
## récompenses : le dessert et la confiance des petites (« Willie »).

const QUEST := &"special_dessert"
const WILLEM := preload("res://data/npcs/willem.tres")
const EGG_VENDOR := preload("res://data/npcs/egg_vendor.tres")
const CAT_WAITER := preload("res://data/npcs/cat_waiter.tres")
const COLLON := preload("res://data/npcs/collon.tres")
const LAKHESH := preload("res://data/npcs/lakhesh.tres")


func test_special_dessert_from_offer_to_the_refectory() -> void:
	assert_eq(QuestData.state_of(QUEST), &"", "pas avant d'avoir salué Willem")
	GameState.set_flag(&"met_willem")
	assert_eq(QuestData.npc_marker(&"willem"), QuestData.MARKER_AVAILABLE, "« ! »")
	var said := talk(WILLEM, [-1, 0, -1])
	assert_string_contains(said[0], "Les petites me fuient")
	assert_string_contains(said[2], "La Clochette")
	assert_eq(step_of(QUEST), &"eggs")
	assert_string_contains(talk(WILLEM)[0], "Les œufs d’abord")
	# Les œufs : la marchande se laisse fléchir pour des enfants.
	assert_string_contains(talk(EGG_VENDOR)[0], "C’est pour l’entrepôt")
	said = talk(EGG_VENDOR, [0, -1])
	assert_string_contains(said[1], "Une douzaine")
	assert_eq(GameState.count(&"eggs"), 1)
	assert_eq(step_of(QUEST), &"berries", "œufs en poche : étape suivante")
	assert_string_contains(talk(EGG_VENDOR)[0], "Elles ont aimé", "une seule douzaine")
	assert_eq(GameState.count(&"eggs"), 1)
	# Trois grappes de baies.
	GameState.add_item(&"wild_berries", 2)
	assert_eq(QuestData.find(QUEST).current_progress(), "Baies sauvages : 2/3")
	assert_string_contains(talk(WILLEM)[0], "Trois grappes")
	GameState.add_item(&"wild_berries")
	assert_eq(step_of(QUEST), &"cream")
	# La crème du café.
	said = talk(CAT_WAITER)
	assert_string_contains(said[0], "De la crème fraîche")
	assert_eq(GameState.count(&"fresh_cream"), 1)
	assert_eq(step_of(QUEST), &"cook")
	# Willem cuisine : les ingrédients sont pris.
	assert_eq(QuestData.npc_marker(&"willem"), QuestData.MARKER_TURN_IN, "« ? »")
	said = talk(WILLEM, [-1, -1, -1])
	assert_string_contains(said[0], "Tout y est")
	assert_eq(step_of(QUEST), &"hiding")
	for item_id: StringName in [&"eggs", &"wild_berries", &"fresh_cream"]:
		assert_eq(GameState.count(item_id), 0, "%s utilisé" % item_id)
	# Les petites, cachées dans le grand arbre.
	said = talk(COLLON, [-1, -1, -1, -1])
	assert_string_contains(said[0], "On espionne le monstre")
	assert_eq(step_of(QUEST), &"served")
	# Lakhesh appelle tout le monde au réfectoire.
	said = talk(LAKHESH, [-1, -1, -1, -1, -1])
	assert_eq(said.size(), 5)
	assert_eq(GameState.quest_state(QUEST), &"done")
	assert_eq(GameState.count(&"dessert_cup"), 1, "le dessert spécial")
	assert_true(GameState.has_flag(&"little_ones_trust_willem"))
	# Ensuite : « Willie ».
	assert_string_contains(talk(WILLEM)[0], "« Willie »")
	assert_string_contains(talk(COLLON)[0], "Willie m’a laissée grimper")


func test_the_egg_vendor_asks_twice() -> void:
	GameState.set_flag(&"met_willem")
	start_quest(QUEST)
	var said := talk(EGG_VENDOR, [1, 0, -1])
	assert_eq(said.size(), 3)
	assert_string_contains(said[1], "c’est pour qui")
	assert_eq(GameState.count(&"eggs"), 1, "pour les petites : des œufs")
	assert_eq(step_of(QUEST), &"berries")
