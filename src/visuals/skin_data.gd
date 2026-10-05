class_name SkinData
extends Resource
## Apparence d'un personnage : planche de sprites (format de l'easter egg) ou mesh 3D.
## Skins jouables : data/skins/<id>.tres (chargés par SkinRegistry). Visuels d'ennemis :
## data/enemies/visuals/<id>.tres (hors de data/skins, donc non jouables). Propriétaire : L3.

## Identifiant, ex. &"chtholly".
@export var id: StringName
## Nom affiché (menu de sélection, crédits).
@export var display_name: String = ""
## Planche PNG (assets/characters/<id>/<id>.png ou assets/enemies/<id>/<id>.png).
@export var sprite_sheet: Texture2D
## JSON de la planche, repris tel quel de l'easter egg (animations, images, ancres, coup, onde).
@export var frames_json: JSON
## Variante 3D (M3+) : scène instanciée par CharacterVisual à la place du sprite.
@export var mesh_scene: PackedScene
## Portrait (boîte de dialogue, menu). Facultatif.
@export var portrait: Texture2D
## Taille du personnage debout, en mètres. pixel_size = height_m / hauteur (px) de la
## première image de « repos » (Chtholly : 1,5 m / 144 px = 0,0104 m par pixel de planche).
@export var height_m: float = 1.5
