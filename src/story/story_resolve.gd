class_name StoryResolve
extends RefCounted
## (X-L0) Les jours du rythme libre (PLAN.md, « (X) Exploration libre : le rythme ») : régler
## sans les jouer les scènes laissées passer, et les règles du coucher et du temps qui passe en
## libre. Le socle (L0) ne pose que les points d'entrée, appelés par StoryDirector en libre ; le
## lot L4 les remplit (étapes d'état seulement, choix par défaut ou clé « skip », puis
## GameState.mark_scene_done et le drapeau passee_<id>). L0 : le comportement d'E6.

## Le directeur (autoload StoryDirector), posé par lui.
var director: Node


## Vrai si le joueur peut se coucher en libre ; rule : la règle d'E6 (créneau, sleep_after). L0 :
## la même.
func can_sleep(rule: bool) -> bool:
	return rule


## Vrai si le joueur peut laisser passer le temps en libre ; rule : la règle d'E6 (plafonnée par
## la prochaine scène clé). L0 : la même.
func can_rest(rule: bool) -> bool:
	return rule


## Le joueur se couche en libre, avant le jour suivant (StoryDirector.sleep) : règle les scènes
## du jour laissées passer. L0 : rien.
func before_sleep(_island: StringName, _day: int) -> void:
	pass


## Règle une scène sans la jouer ; vrai si elle est réglée. L0 : faux (rien n'est réglé).
func resolve_scene(_island: StringName, _scene_id: StringName) -> bool:
	return false
