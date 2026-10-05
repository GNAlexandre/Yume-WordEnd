class_name AttackData
extends Resource
## Une attaque (joueur ou ennemi) : ses chiffres vivent ici, jamais dans un script.
## Fichiers : data/attacks/<id>.tres. Propriétaire : L4 (PLAN.md section 3).

## Identifiant (nom du fichier sans extension), ex. &"sword_1".
@export var id: StringName
## Animation de la planche jouée pendant l'attaque (&"attaque", &"charge", &"morsure", &"fouet"…).
@export var animation: StringName
## Dégâts infligés à Health.
@export var damage: int = 1
## Vitesse de recul imprimée à la cible, en m/s, dans la direction attaquant → cible.
@export var knockback: float = 0.0
## true : traverse toutes les cibles (onde de charge). Un ennemi stoic ne recule que sous
## ces attaques.
@export var pierces: bool = false
## Portée en mètres, à l'échelle 1 (un ennemi la multiplie par son EnemyData.scale).
@export var range_m: float = 1.0
## Temps de recharge en secondes avant de pouvoir relancer l'attaque.
@export var cooldown: float = 0.0

@export_group("Compléments (Lot 0)")
## Ouverture de la zone de coup en degrés (épée : 90). 0 = non utilisé.
@export var arc_deg: float = 0.0
## Largeur de la zone de coup en mètres (onde : 2). 0 = non utilisé.
@export var width_m: float = 0.0
## Maintien minimal avant de pouvoir relâcher, en secondes (onde : 0,55). 0 = attaque immédiate.
@export var charge_time: float = 0.0
## Durée de l'état d'attaque en secondes (onde : 0,42). 0 = durée de l'animation.
@export var duration: float = 0.0
## Vitesse du projectile en m/s (onde) ; 0 = corps à corps.
@export var speed: float = 0.0
