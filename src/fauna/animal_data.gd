class_name AnimalData
extends EnemyData
## Une espèce de la faune (lot E5) : tous ses chiffres, comme EnemyData dont elle hérite (PV,
## vitesse, attaques : data/fauna/ile_68/attacks/*.tres) plus ce qui fait un animal : son
## comportement, ses distances de fuite, ses réactions au joueur, au bruit et au combat. Fichiers :
## data/fauna/<île>/<id>.tres (WorldAtlas.find_data("fauna", île, "<id>.tres")). Les peuplements
## (quelles espèces, combien, où, à quel moment) sont dans data/fauna/<île>/peuplement.json
## (FaunaRules). Mode d'emploi : PLAN.md, « (E5) Ajouter un animal ».
##
## Comportements (behavior) :
## - paisible : erre et broute ; lève la tête à alert_range_m, fuit à flee_range_m ;
## - fuyard : fuit dès qu'on approche (flee_range_m), sans lever la tête ;
## - dangereux : l'IA d'Enemy (poursuite, préparation, coup) ; la laisse, l'agressivité
##   (aggro_range_m), les bonds, la meute et l'étourdissement viennent d'ici ;
## - ambiant : pas de corps (papillons, libellules) : une bande animée (AmbientSprites) que
##   FaunaPopulator pose ; les champs « Ambiance » la règlent.
## Un animal vaincu s'enfuit (jamais de mort à l'écran) : docs/lore/ACTE1.md, 3.5.

const PEACEFUL := &"paisible"
const FLEEING := &"fuyard"
const DANGEROUS := &"dangereux"
const AMBIENT := &"ambiant"
const BEHAVIORS: Array[StringName] = [PEACEFUL, FLEEING, DANGEROUS, AMBIENT]

@export_group("Espèce")
## paisible, fuyard, dangereux ou ambiant.
@export var behavior: StringName = PEACEFUL
## Oiseau : il s'envole (animation de fuite, il monte) au lieu de courir.
@export var flies: bool = false
## Rayon du corps (m) : capsule, Hurtbox et ombre ; la hauteur du corps vaut 2,5 fois ce rayon.
@export var body_radius_m: float = 0.3
## Moments où l'espèce est dehors (GameState.MOMENTS) ; vide : toujours. Un peuplement
## (peuplement.json) peut les restreindre pour une carte.
@export var moments: Array[StringName] = []

@export_group("Paisibles et fuyards")
## À cette distance (m) le paisible s'arrête et regarde le joueur (0 : jamais).
@export var alert_range_m: float = 0.0
## À cette distance (m) il fuit.
@export var flee_range_m: float = 5.0
## Distance (m) du danger à partir de laquelle il se calme ; 0 : 2,5 fois flee_range_m.
@export var calm_distance_m: float = 0.0
## Vitesse de fuite (m/s) ; 0 : speed.
@export var flee_speed: float = 0.0
## Animation des pauses (« broute » pour le cerf et le sanglier) et part des pauses qu'il y passe.
@export var graze_animation: StringName = &"repos"
@export_range(0.0, 1.0) var graze_ratio: float = 0.6
## Animation de la fuite ; startle : animation du premier sursaut (grand bond de l'écureuil) et sa
## durée (s).
@export var flee_animation: StringName = &"course"
@export var startle_animation: StringName = &""
@export var startle_s: float = 0.0
## Il quitte la carte (s'envole, plonge) : délai (s) après le début de la fuite ; 0 : il fuit sur
## le sol puis se calme.
@export var vanish_s: float = 0.0

@export_group("Réactions")
## Le joueur qui court fait plus de bruit, celui qui reste immobile moins : multiplicateurs des
## distances d'alerte et de fuite. run_speed_m_s : vitesse au-delà de laquelle on court.
@export var noise_run_factor: float = 1.5
@export var noise_still_factor: float = 0.6
@export var run_speed_m_s: float = 5.5
## Un combat à moins de cette distance (m) (un animal ou le joueur touché) l'alarme (0 : sourd).
@export var combat_noise_m: float = 12.0

@export_group("Dangereux")
## Laisse : il abandonne la poursuite à plus de leash_m de son point de départ (la tanière de
## l'ours : 15 m) ; rayon d'errance autour de lui.
@export var leash_m: float = 20.0
@export var wander_radius_m: float = 3.0
## Animation jouée pendant la préparation d'une charge (le sanglier qui gratte le sol).
@export var windup_animation: StringName = &""
## Étourdissement (s) quand sa charge heurte un obstacle (arbre, rocher).
@export var stun_s: float = 0.0
## Meute : rayon (m) du cercle qu'elle trace autour du joueur (0 : pas de meute), vitesse
## angulaire (rad/s) et pause (s) entre deux attaques de la meute (une bête attaque à la fois).
@export var ring_radius_m: float = 0.0
@export var ring_speed: float = 0.6
@export var attack_gap_s: float = 0.8

@export_group("Défaite")
## Vaincu, il fuit au plus pendant defeat_flee_s secondes ou jusqu'à defeat_flee_m mètres du
## joueur, puis disparaît.
@export var defeat_flee_s: float = 3.0
@export var defeat_flee_m: float = 14.0

@export_group("Ambiance")
## Bande animée (frames images côte à côte, ancre au centre), cadence, mouvement
## (AmbientSprites.Motion : 0 feuille, 1 traversée, 2 voltige, 3 vol sur place), nombre,
## ampleur, hauteur au-dessus du sol (m), taille de la région (m) autour du point de peuplement.
@export var ambient_texture: Texture2D
@export var ambient_frames: int = 4
@export var ambient_fps: float = 12.0
@export var ambient_motion: int = 2
@export var ambient_count: int = 4
@export var ambient_speed: float = 0.6
@export var ambient_sway: float = 1.2
@export var ambient_lift: float = 0.3
@export var ambient_region_m: float = 12.0
## Il ne vole que par ces temps (GameState.WEATHERS) ; vide : tous.
@export var ambient_weather: Array[StringName] = []


## Vrai pour un animal qui a un corps (tout sauf l'ambiance).
func has_body() -> bool:
	return behavior != AMBIENT


func is_dangerous() -> bool:
	return behavior == DANGEROUS


## Vrai si l'espèce est dehors à ce moment (liste de l'espèce vide : toujours).
func active_at(moment: StringName) -> bool:
	return moments.is_empty() or moment in moments


## Distance du danger à partir de laquelle un fuyard se calme (calm_distance_m, sinon 2,5 fois
## flee_range_m).
func calm_distance() -> float:
	return calm_distance_m if calm_distance_m > 0.0 else flee_range_m * 2.5


## Vitesse de fuite en m/s.
func escape_speed() -> float:
	return flee_speed if flee_speed > 0.0 else speed
