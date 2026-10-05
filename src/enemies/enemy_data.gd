class_name EnemyData
extends Resource
## Type d'ennemi : tous ses chiffres (PV, vitesse, points, attaques). Fichiers :
## data/enemies/<id>.tres. Propriétaire : L5 (PLAN.md sections 3 et 4).

## Identifiant, ex. &"timere_small" (transmis par EventBus.enemy_killed).
@export var id: StringName
## Nom affiché.
@export var display_name: String = ""
## Planche de l'ennemi (data/enemies/visuals/<id>.tres).
@export var visual: SkinData
## Échelle du visuel et des portées (Petit 0,8 ; Grand 1,3).
@export var scale: float = 1.0
## PV au départ (sans le bonus de vague du WaveDirector).
@export var max_hp: int = 1
## Vitesse de déplacement en m/s (sans le bonus de vague).
@export var speed: float = 2.0
## Points gagnés à sa mort (score d'arène).
@export var points: int = 0
## Attaques disponibles (data/attacks/*.tres).
@export var attacks: Array[AttackData] = []
## Coureur : charge en ligne droite (attaque &"rush") au lieu de marcher.
@export var rush: bool = false
## Ne recule que sous une attaque qui traverse (AttackData.pierces), comme le Grand.
@export var stoic: bool = false
## Distance à laquelle il repère le joueur, en mètres.
@export var aggro_range_m: float = 10.0
## Objets lâchés à la mort : item_id → probabilité (0..1).
@export var drops: Dictionary[StringName, float] = {}
