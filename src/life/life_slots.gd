class_name LifeSlots
extends RefCounted
## (E4) Les créneaux de la vie : la journée des emplois du temps (data/life/ ; docs/lore/VIE.md,
## 0.1) et leur lumière (moments d'E9, GameState.MOMENTS). Propriétaire : E4.
##
## Six créneaux (GameState.SLOTS) pour cinq moments de lumière : midi garde la lumière du matin,
## le soir est le couchant. Le créneau courant est GameState.slot s'il va avec le moment
## (GameState.moment), sinon le créneau par défaut du moment (default_for) : un moment changé
## ailleurs (F7, le récit par Atmosphere.set_moment) entraîne le créneau ; LifeDirector.set_slot
## pose les deux (le moment par Atmosphere, avec sa transition).

## Lumière de chaque créneau (un moment de GameState.MOMENTS).
const MOMENT_OF := {
	&"aube": &"aube",
	&"matin": &"matin",
	&"midi": &"matin",
	&"apres_midi": &"apres_midi",
	&"soir": &"couchant",
	&"nuit": &"nuit",
}
## Créneau d'un moment quand rien d'autre n'est demandé.
const SLOT_OF := {
	&"aube": &"aube",
	&"matin": &"matin",
	&"apres_midi": &"apres_midi",
	&"couchant": &"soir",
	&"nuit": &"nuit",
}


## Les créneaux, dans l'ordre du jour.
static func all() -> Array[StringName]:
	return GameState.SLOTS


## Vrai si slot est un créneau.
static func is_slot(slot: StringName) -> bool:
	return slot in GameState.SLOTS


## Moment de lumière du créneau (&"" s'il est inconnu).
static func moment_of(slot: StringName) -> StringName:
	return MOMENT_OF.get(slot, &"")


## Créneau par défaut d'un moment (le soir pour le couchant ; &"" s'il est inconnu).
static func default_for(moment: StringName) -> StringName:
	return SLOT_OF.get(moment, &"")


## Créneau courant : GameState.slot s'il va avec GameState.moment, sinon celui du moment.
static func current() -> StringName:
	return resolve(GameState.slot, GameState.moment)


## Créneau effectif d'un créneau demandé (&"" : aucun) sous un moment donné.
static func resolve(slot: StringName, moment: StringName) -> StringName:
	if is_slot(slot) and moment_of(slot) == moment:
		return slot
	return default_for(moment)


## Créneau suivant (après la nuit : l'aube).
static func next(slot: StringName) -> StringName:
	var slots := all()
	var index := slots.find(slot)
	return slots[(index + 1) % slots.size()] if index >= 0 else slots[0]
