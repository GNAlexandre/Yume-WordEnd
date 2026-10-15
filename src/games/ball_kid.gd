class_name BallKid
extends RefCounted
## (E8) Une petite en jeu au ballon (BallPlay, BallMatch) : son PNJ, son équipe, son poste, ses
## compteurs, sa frappe en attente. Propriétaire : E8.

var actor: LifeActor
var team: StringName = &""
var on_field: bool = false
var keeper: bool = false
## Poste : (écart latéral −1..1, avancée 0..1 depuis sa ligne de but).
var home: Vector2 = Vector2(0.0, 0.5)
var touches: int = 0
var goals: int = 0
var chasing: bool = false
var think_left: float = 0.0
var kick_left: float = 0.0
var block_left: float = 0.0
var down_left: float = 0.0
var seated: bool = false
var was_on_field: bool = false
## Frappe en attente : {time, kind, dir, speed, lift, target, flight}.
var pending: Dictionary = {}
var ring: MeshInstance3D = null
var target: Vector3 = Vector3.INF
