class_name SkinData
extends Resource
## Apparence d'un personnage : planche de sprites au format de l'easter egg (HD-2D, 96 px/m).
## Skins jouables : data/skins/<id>.tres (chargés par SkinRegistry). Visuels d'ennemis :
## data/enemies/visuals/<id>.tres (hors de data/skins, donc non jouables). Propriétaire : L3, H6.
##
## (H6) Trois vues : sprite_sheet + frames_json est le profil (tourné vers la droite, retourné
## pour la gauche), et la seule vue d'une planche simple (easter egg, remplaçants) ; front_* (face,
## vers la caméra) et back_* (dos) sont facultatives. Toutes les vues ont les mêmes animations,
## nombres d'images, cadences, « coup » et « onde » que le profil (SheetLoader.view_problem) :
## changer de vue ne change ni l'horloge ni le combat.

## Identifiant, ex. &"chtholly".
@export var id: StringName
## Nom affiché (menu de sélection, crédits).
@export var display_name: String = ""
## Planche PNG du profil (assets/characters/<id>/<id>.png ou assets/enemies/<id>/<id>.png).
@export var sprite_sheet: Texture2D
## JSON du profil, repris tel quel de l'easter egg (animations, images, ancres, coup, onde).
@export var frames_json: JSON
## (H6) Vue de face (<id>_front.png et .json), facultative.
@export var front_sheet: Texture2D
@export var front_json: JSON
## (H6) Vue de dos (<id>_back.png et .json), facultative.
@export var back_sheet: Texture2D
@export var back_json: JSON
## Portrait (boîte de dialogue, menu). Facultatif.
@export var portrait: Texture2D
## Taille du personnage debout, en mètres. pixel_size = height_m / hauteur (px) de la
## première image de « repos » du profil (Chtholly : 1,5 m / 144 px = 0,0104 m par pixel de
## planche), la même pour toutes les vues.
@export var height_m: float = 1.5
