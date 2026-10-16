class_name StoryOffers
extends RefCounted
## (X-L0) Les propositions du rythme libre : une scène du livre que l'on déclenche en allant voir
## un personnage ou un lieu (PLAN.md, « (X) Exploration libre : le rythme »). Le socle (L0) ne
## pose que les points d'entrée, appelés par StoryDirector ; le lot L1 les remplit (ancres :
## clé « offer » des scènes, StoryData.OFFER_KEYS ; signe du récit ; « Allons-y » / « Plus
## tard »). Rien ne s'y passe en scénarisé : chaque point d'entrée le vérifie (StoryDirector.mode).

## Le directeur (autoload StoryDirector), posé par lui.
var director: Node


## Nouvelle carte (après les invites du récit, StoryDirector._rebuild_prompts) ou rythme
## changé : pose les propositions de la carte. L0 : rien.
func rebuild(_map: Map) -> void:
	pass


## Réévalue les propositions posées (texte, présence) ; appelé par StoryDirector.refresh(). L0 :
## rien.
func refresh() -> void:
	pass


## Conversation avec un PNJ de la vie, en libre, hors scène (StoryDirector._on_talk) : vraie si
## une proposition la prend (sinon la conversation libre). L0 : faux.
func talk(_npc_id: StringName) -> bool:
	return false


## Une scène finie (completed) ou interrompue (StoryDirector._end_scene). L0 : rien.
func scene_ended(_scene_id: StringName, _completed: bool) -> void:
	pass
