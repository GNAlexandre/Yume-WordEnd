#!/usr/bin/env python3
"""(T2) Les cartes de l'entrepôt des fées, écrites d'après leurs plans : docs/lore/CARTE.md, section 3
(blocs ```plan, lus par tools/carte_plans.py), à la lettre. Quatre cartes :

- entrepot_rdc, entrepot_etage, salle_des_armes : intérieurs (InteriorRoom, lot E3) ;
  data/maps/<id>/interior.json (pièces, portes, fenêtres, éléments de mur, lampes) et la scène
  src/world/maps/<id>/<id>.tscn (Map, Ground, Geometry meublé, Markers, Exits, Examine, Life/Places) ;
- entrepot_toit : le toit-terrasse, dehors (sol MapGround du lot E2, écrit ici en images :
  map.json, heights.png, materials.png, structures.png) et sa scène.

Ce que le plan ne dit pas, ou que le moteur demande autrement, est dans les tables ci-dessous et
dans docs/DECISIONS.md (lot T2) : noms des pièces, appuis des fenêtres (cahier n° 3), portes qu'on
franchit (chambranle door_frame_wood), ouvertures de toute la largeur d'une pièce (montants de
0,2 m), lampes par type, objets à examiner (data/texts/entrepot.json), places de la vie (chaises,
lits), cloisonnement sous l'escalier, sorties vers une carte encore absente (PROVISIONAL).

(I1) Orientation des meubles : une ligne « meuble » du plan peut porter « regard=E|O|N|S » (le meuble
regarde l'est, l'ouest, le nord ou le sud ; un meuble adossé au mur ouest regarde l'est). Le
générateur écrit « facing » sur le meuble ; quand l'image de la vue existe (<nom>_side pour E et O,
<nom>_back ou <nom>_foot pour N : cahier n° 5, lot R0), il le tourne aussi d'un quart de tour autour
du milieu de son bord arrière (le mur) : emprise, collision et ombre suivent, la vue est choisie par
DecorPanel. Sans la vue, le meuble garde sa face et son emprise de face, comme avant (docs/INTERIEURS.md,
section 6). Relancer gen quand une vue arrive.

Usage (Python 3.9+) :

    python3 tools/interior_maps.py gen [map_id ...]   # écrit les cartes (toutes sans argument)
    python3 tools/interior_maps.py places             # réécrit la liste des places dans CARTE.md
    python3 tools/interior_maps.py check              # les cartes écrites sont-elles à jour ?

Après gen : tools/import.sh (images du toit), puis tools/test.sh tests/unit/test_maps.gd et les
tests des cartes (tests/unit/test_entrepot_*.gd, test_salle_des_armes.gd).
"""

import json
import math
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import carte_plans  # noqa: E402
import hd2d_interior  # noqa: E402
import life_zones  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARTE = os.path.join(ROOT, "docs", "lore", "CARTE.md")
INTERIOR_MAPS = ["entrepot_rdc", "entrepot_etage", "salle_des_armes", "cafe", "maison_limashenka"]
OUTDOOR_MAPS = ["entrepot_toit"]
WALL_HALF = 0.125
# Écart d'une ouverture à un angle (InteriorLayout : demi-mur + 0,05 m, et un peu de marge).
CORNER_GAP = 0.2
# Une porte de pièce (door_frame_wood) ne descend pas sous l'ouverture du chambranle.
DOOR_MIN = 1.1

# Pièces : nom affiché (InteriorLayout, room_at).
ROOM_NAMES = {
    "cuisine": "Cuisine", "refectoire": "Réfectoire", "escalier": "Cage d'escalier",
    "palier_armes": "Palier des armes", "archives": "Archives", "lecture": "Salle de lecture",
    "couloir": "Couloir", "bains": "Salle de bains", "toilettes": "Toilettes", "placard": "Placard",
    "entree": "Entrée", "jeux": "Salle de jeux", "infirmerie": "Infirmerie",
    "willem": "Chambre de Willem", "chtholly": "Chambre de Chtholly", "nygglatho": "Chambre de Nygglatho",
    "grande_soeur": "Chambre de la grande sœur", "tremie": "Trémie et palier", "ithea": "Chambre d'Ithea",
    "absentes": "Chambre des aînées absentes", "nephren": "Chambre de Nephren",
    "dortoir_a": "Dortoir A", "dortoir_b": "Dortoir B", "dortoir_c": "Dortoir C", "dortoir_d": "Dortoir D",
    "lingerie": "Lingerie", "crypte": "Crypte",
    # (C2) Le café du village et la maison Limashenka (CARTE.md, section 5).
    "salle": "Salle du café", "arriere": "Arrière-boutique", "vestibule": "Vestibule", "salon": "Salon",
}
WALLCUTS = {"wall_cellar_stone": "wallcut_stone"}
# Appui des fenêtres (cahier n° 3, 3.2) ; window_reading_seat est un meuble dans le plan.
SILLS = {
    "window_cross_small": 1.0, "window_cross_large": 0.8, "window_dusty": 1.3,
    "window_curtains_open": 0.8, "window_curtains_closed": 0.8, "window_bare": 0.7,
    "window_shutters": 0.8,
}
# Portes vers le dehors (CARTE.md 3.1) : identifiant (InteriorRoom.door_position), hauteur,
# franchie en marchant (porte d'entrée, porte de service) ou fermée (porte rivetée).
OUTSIDE_DOORS = {
    "door_double": {"id": "entree", "height": 2.4, "passable": True},
    "door_service": {"id": "service", "height": 2.2, "passable": True},
    "door_armory": {"id": "armes", "height": 2.3, "passable": False},
    # (C2) La porte du café et celle de la maison Limashenka, sur le mur sud (coupé) : on la franchit en marchant.
    "door_room": {"id": "sortie", "height": 2.2, "passable": True},
}
# Porte d'une pièce qu'on franchit : chambranle seul, ouverture transparente (E3 : door_room,
# opaque, cacherait le joueur sur le seuil).
PASSABLE_IMAGE = "door_frame_wood"
# (C2) Portes d'une pièce qu'on franchit et qui gardent leur image : le rideau de l'arrière-boutique, sur une cloison
# nord-sud (vue de chant par la caméra : il ne cache pas le joueur).
OWN_IMAGE_DOORS = ("door_backroom",)
# Lampes par type (« lumiere » des plans) : rayon (m), couleur, énergie. cristal_eteint : la lampe
# des archives, éteinte (pas de halo).
LIGHT_TYPES = {
    "cristal": (3.6, "#ffd59a", 0.75),
    "cristal_ambre": (3.0, "#ffb062", 1.0),
    "feu": (3.8, "#ff9a50", 1.1),
    "huile": (2.6, "#ffc070", 0.85),
    "cristal_eteint": None,
}
SUSPENSION_RADIUS = 4.5

# Réglages de la Map par carte. Bornes de la caméra : celles du plan, élargies en x à tout le
# bâtiment pour les étages (la caméra reste au droit du joueur ; docs/INTERIEURS.md, 1.6, et
# docs/DECISIONS.md, T2).
MAP_SETTINGS = {
    "entrepot_rdc": {"camera_bounds": (2.0, 4.0, 28.0, 6.0), "light_preset": "interieur"},
    "entrepot_etage": {"camera_bounds": (2.0, 4.0, 28.0, 6.0), "light_preset": "interieur"},
    "salle_des_armes": {"camera_bounds": (5.0, 3.0, 4.0, 3.0), "light_preset": ""},
    "entrepot_toit": {"camera_bounds": (6.0, 4.0, 4.0, 4.0), "light_preset": ""},
    # (C2) Une seule pièce de 10 × 8 m ou 12 × 10 m : la caméra reste au droit du joueur (x de 2 à la largeur − 2) et
    # cadre la pièce entière (docs/INTERIEURS.md, 1.6).
    "cafe": {"camera_bounds": (2.0, 5.0, 8.0, 0.0), "light_preset": "interieur"},
    "maison_limashenka": {"camera_bounds": (2.0, 4.0, 6.0, 0.0), "light_preset": "interieur"},
}
# Sorties vers une carte qui n'existe pas encore (construite en parallèle) : provisoirement vers
# une carte existante, au Spawn ; relancer gen les raccorde dès que la cible existe.
PROVISIONAL = {"entrepot": ("essai", "Spawn")}

# Objets à examiner : (clé de data/texts/entrepot.json sous la carte, quoi, référence, options).
# quoi : meuble (image, rang parmi les meubles de cette image), mural (image), fenetre (image),
# point (x, z) ; options : w (largeur de la zone), d (profondeur), dx (décalage en x).
EXAMINE = {
    "entrepot_rdc": [
        ("cuisine_fourneau", "meuble", ("crystal_stove", 0), {}),
        ("cuisine_moutarde", "mural", "wallitem_spice_shelf", {}),
        ("cuisine_tablier", "mural", "wallitem_apron_hook", {}),
        ("refectoire_menu", "mural", "wallitem_menu_board", {}),
        ("refectoire_marques", "mural", "wallitem_height_marks", {}),
        ("refectoire_vaisselier", "meuble", ("china_cabinet", 0), {}),
        ("refectoire_fenetre", "fenetre", "window_cross_large", {}),
        ("planning", "mural", "wallitem_chore_chart", {}),
        ("ecriteau_couloir", "mural", "wallitem_notice_b", {}),
        ("porte_armes", "point", (20.78, 1.4), {"w": 0.35, "d": 0.6}),
        ("archives_horloge", "mural", "wall_clock_swing", {}),
        ("archives_coupures", "mural", "wallitem_clippings", {}),
        ("archives_rapport", "meuble", ("paper_pile_a", 0), {}),
        ("archives_bon", "meuble", ("desk_buried", 0), {}),
        ("lecture_fenetre", "meuble", ("window_reading_seat", 0), {}),
        ("lecture_livre", "meuble", ("bookshelf_low", 0), {}),
        ("point_eau", "meuble", ("washstand_corridor", 0), {}),
        ("bains_reglement", "mural", "wallitem_bath_rules", {}),
        ("bains_miroir", "mural", "mirror_large", {}),
        ("placard_marteau", "meuble", ("supply_cupboard", 0), {}),
        ("entree_pateres", "mural", "wallitem_coat_hooks", {}),
        ("jeux_partie", "meuble", ("game_table", 0), {}),
        ("jeux_piano", "meuble", ("piano_old", 0), {}),
        ("infirmerie_calendrier", "mural", "wallitem_day_calendar", {}),
        ("infirmerie_trousse", "meuble", ("medicine_cabinet", 0), {}),
    ],
    "entrepot_etage": [
        ("willem_fenetre", "fenetre", "window_bare", {}),
        ("willem_armoire", "meuble", ("wardrobe_plain", 0), {}),
        ("chtholly_calendrier", "mural", "wallitem_calendar", {}),
        ("chtholly_armoire", "meuble", ("wardrobe_chtholly", 0), {}),
        ("chtholly_miroir", "meuble", ("desk_chtholly", 0), {}),
        ("nygglatho_cristal", "meuble", ("comm_crystal", 0), {}),
        ("nygglatho_the", "meuble", ("shelf_nygglatho", 0), {}),
        ("nygglatho_gateau", "meuble", ("tea_table", 0), {}),
        ("grande_soeur_bureau", "meuble", ("desk_clean", 0), {}),
        ("grande_soeur_cartes", "meuble", ("cards_floor", 0), {}),
        ("ecriteau_toilettes", "mural", "wallitem_notice_a", {}),
        ("ithea_roman", "meuble", ("book_pile", 0), {}),
        ("absentes_coffre", "meuble", ("clothes_chest", 0), {}),
        ("nephren_livres", "meuble", ("bookshelf_low", 0), {}),
        ("couloir_seau", "meuble", ("leak_bucket", 0), {}),
        ("couloir_trappe", "meuble", ("repair_planks", 0), {}),
    ],
    "salle_des_armes": [
        ("rateliers", "point", (8.65, 1.75), {"w": 8.0, "d": 0.8}),
        ("tissu", "meuble", ("swords_wrapped", 0), {}),
    ],
    "entrepot_toit": [],
    # (C2) Textes : data/texts/village.json (TEXTS_PATH).
    "cafe": [
        ("menu", "mural", "wallitem_menu_cafe", {}),
        ("comptoir", "meuble", ("cafe_counter", 0), {}),
        ("etagere", "meuble", ("cafe_bottle_shelf", 0), {}),
        ("buveurs", "meuble", ("cafe_drinkers_table", 0), {}),
        ("fenetre", "fenetre", "window_cross_small", {}),
        ("clochette", "point", (4.75, 8.3), {"w": 1.4, "d": 0.6}),
        ("arriere", "point", (8.0, 3.0), {"w": 0.5, "d": 1.2}),
    ],
    "maison_limashenka": [
        ("horloge", "mural", "wallitem_clock_limashenka", {}),
        ("portrait", "mural", "wallitem_family_portrait", {}),
        ("vitrine", "meuble", ("display_cabinet", 0), {}),
        ("boite_outils", "meuble", ("toolbox_gears", 0), {}),
        ("fauteuil", "meuble", ("armchair_sheeted", 0), {}),
        ("pateres", "mural", "wallitem_coat_hooks", {}),
    ],
}
# Fichier des textes à examiner de chaque carte (Examinable.texts_path) ; sans entrée : celui de l'entrepôt.
TEXTS_PATH = {"cafe": "res://data/texts/village.json", "maison_limashenka": "res://data/texts/village.json"}
# Ce qui bloque sans image : la place sous le haut de l'escalier (on n'y entre pas : le palier de
# l'étage est au-dessus). (nom, x0, z0, x1, z1, hauteur).
BLOCKERS = {
    "entrepot_rdc": [("sous_escalier", 16.7, 1.125, 18.3, 2.5, 3.0)],
    # (C2) Derrière le comptoir du café, au bout de la vitrine à gâteaux (1,2 m de comptoir + 0,6 m de vitrine) : on n'y
    # passe pas (la vitrine cacherait la taille du joueur, CARTE.md 0.3) ; le serveur tient en deçà (place
    # comptoir_arriere, x = 4).
    "cafe": [("derriere_vitrine", 4.7, 1.8, 5.3, 2.55, 1.0)],
}
# Éléments que le plan pose en « mural » mais qui sont des images de meubles (props/) ou de porte :
# InteriorPanel plaqué au mur. Le grand miroir, sur le mur ouest, regarde l'est (keep_orientation) ;
# la porte rivetée vue de la crypte, en haut des marches, finit au haut du mur.
FACE_EAST = "E"
# (I2) Éléments « mural » du plan qui sont des bandes animées (DecorPanel accroché au mur, comme le grand miroir) ;
# bandes « objet » qui reprennent l'image d'un meuble au pixel près (posées au sol, à son bord sud) ; celles que
# l'histoire allume (l'appel du cristal de Nygglatho : un nœud caché, `visible = true` quand il sonne) ; chute
# de la vapeur du bain sous le rebord de la baignoire (m).
WALL_ANIMS = ("wall_clock_swing",)
OVERLAYS = ("comm_crystal_call",)
HIDDEN_OBJECTS = ("comm_crystal_call",)
BATH_WATER_DROP = 0.3
PROVISIONAL_NOTE = "provisoire (docs/DECISIONS.md, T2)"

# Rien ne cache le joueur (docs/INTERIEURS.md ; CARTE.md 0.3) : un meuble dont l'image dépasse
# TALL m et qui n'est pas contre le mur nord de sa pièce
# - se coupe avec le mur sud s'il y est adossé (son image à moins de SOUTH_REACH m du mur :
#   InteriorPanel.cut_offset) ;
# - sinon, on ne se tient pas là où il cacherait les pieds du joueur : la place derrière lui (au
#   nord, jusqu'au prochain meuble ou mur) est fermée par une collision sans image (« <meuble>_arriere »).
# La caméra du jeu (src/player/camera_rig.tscn) : point visé 2,5 m au nord du joueur, à 0,8 m,
# borné à camera_bounds ; inclinée de 32°, à 21 m.
TALL = 1.21
SOUTH_REACH = 0.7
NORTH_REACH = 0.2
PLAYER_RADIUS = 0.35
FEET = 0.25
CAMERA_PITCH = 32.0
CAMERA_DISTANCE = 21.0
FOCUS_HEIGHT = 0.8
FOCUS_AHEAD = 2.5
BOX_INSET = 0.15
BOX_LEAD = 0.05

# Toit : niveau de la cour sous la terrasse (paliers de 0,5 m) et matières.
ROOF_DROP_LEVELS = 13
ROOF_ZERO = ROOF_DROP_LEVELS * 16
ROOF_MATERIALS = {"floor_roof_deck": "planches", "rock": "roche", "below": "sous_bois"}
LIB = None


def lib():
    global LIB
    if LIB is None:
        with open(os.path.join(ROOT, "data", "maps", "ground_materials.json"), encoding="utf-8") as handle:
            LIB = json.load(handle)
    return LIB


# --- Lecture du plan ---------------------------------------------------------------------------


def plans():
    with open(CARTE, encoding="utf-8") as handle:
        return {m.id: m for m in carte_plans.parse(handle.read())}


def num(value):
    text = ("%.4f" % value).rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def room_of(plan, x, z):
    for room_id, room in plan.rooms.items():
        if room.rect.has(x, z, -1e-6):
            return room_id
    for room_id, room in plan.rooms.items():
        if room.rect.has(x, z, 0.13):
            return room_id
    return ""


def side_of(rect, x, z):
    """Mur d'une pièce sur lequel tombe le point (N, S, W, E), ou ""."""
    eps = 1e-6
    if abs(z - rect.z0) < eps:
        return "N"
    if abs(z - rect.z1) < eps:
        return "S"
    if abs(x - rect.x0) < eps:
        return "W"
    if abs(x - rect.x1) < eps:
        return "E"
    return ""


def wall_side(letter):
    return {"N": "N", "S": "S", "E": "E", "O": "W", "W": "W"}[letter]


# Meubles déplacés par rapport au plan (docs/DECISIONS.md, T2) : (image, rang) -> nouveau z du milieu
# de l'emprise, tant qu'ils gardent leur face. Vide depuis I1 : l'armoire de Chtholly, que T2 avait
# reculée contre le mur sud parce que sa face de 1 m cachait le joueur, est au plan contre le mur
# sud, à l'est de la porte (z 7,85), et tournée vers sa vue de flanc quand elle existe.
MOVED = {}


def expand_furniture(plan):
    """Meubles du plan, rangées « xN » dépliées. Chaque meuble : image, x, z, l, p (emprise du milieu
    à sa largeur et sa profondeur : celle de la vue qu'il montre), h, libre, ligne, rang, et (I1) regard
    (E, O, N, S ou ""), facing (south, east, west, north ou ""), turned (tourné d'un quart de tour : sa
    vue de flanc ou par le pied existe), depth (profondeur de l'emprise, m), shown (image dessinée : la
    vue ou la face), yaw (degrés du nœud), face_width (largeur de la face, m). Les meubles de MOVED
    sont à leur nouvelle place quand ils gardent leur face."""
    out = []
    counts = {}
    for item in plan.furniture:
        flags = item.extra.get("flags", [])
        regard = item.extra.get("regard", "")
        row = 1
        for flag in flags:
            if flag.startswith("x") and flag[1:].isdigit():
                row = int(flag[1:])
        rect = item.rect
        width = rect.w() / row
        for k in range(row):
            x = rect.x0 + width * (k + 0.5)
            z = (rect.z0 + rect.z1) / 2.0
            index = counts.get(item.name, 0)
            counts[item.name] = index + 1
            entry = {"image": item.name, "x": x, "z": z, "l": width, "p": rect.d(), "h": item.h,
                     "free": not item.block, "line": item.line, "index": index, "regard": regard,
                     "facing": FACING_OF_REGARD.get(regard, ""), "turned": False, "shown": item.name,
                     "yaw": 0.0, "face_width": width}
            view, _size = chosen_view(item.name, regard) if item.name in DEPTHS else (None, None)
            if view:
                entry["shown"] = "%s_%s" % (item.name, view)
            if view in ("side", "foot"):
                turn_footprint(entry, rect, view)
            else:
                entry["z"] = MOVED.get((item.name, index), z)
                entry["depth"] = DEPTHS.get(item.name, rect.d())
            out.append(entry)
    return out


def turn_footprint(entry, rect, view):
    """Tourne l'emprise d'un meuble d'un quart de tour autour du milieu de son bord arrière : le mur
    ouest pour E, est pour O (vue de flanc), le mur nord pour un lit vu par le pied. Sa profondeur
    devient sa largeur en x, sa largeur sa profondeur en z (docs/INTERIEURS.md, section 6)."""
    depth = DEPTHS[entry["image"]]
    width = rect.w()
    entry["turned"] = True
    entry["depth"] = width
    entry["l"] = depth
    entry["p"] = width
    if entry["regard"] == "E":
        entry["x"] = rect.x0 + depth / 2.0
        entry["yaw"] = 90.0
    elif entry["regard"] == "O":
        entry["x"] = rect.x1 - depth / 2.0
        entry["yaw"] = -90.0
    else:
        # Lit vu par le pied : la tête reste contre le mur nord, le lit s'allonge vers le sud.
        entry["z"] = rect.z0 + width / 2.0
        entry["yaw"] = 90.0


# --- Données des meubles (scènes de tools/hd2d_interior.py) ------------------------------------

DECALS = {n for n, *_ in hd2d_interior.RUGS} | {n for n, *_ in hd2d_interior.DECALS_T2}
OBJECTS = {n for n, *_ in hd2d_interior.ALL_OBJECTS}
HANGING = {n for n, *_ in hd2d_interior.HANGING}
ANIMATED = {n for n, *_ in hd2d_interior.ANIMS}
OUTDOOR = {n for n, *_ in hd2d_interior.OUTDOOR}
DEPTHS = {n: depth for n, _s, depth, _g, _p in hd2d_interior.ALL_FURNITURE}
DEPTHS.update({n: depth for n, _i, _s, depth, _g in hd2d_interior.FURNITURE_OTHER_IMAGES})
HEIGHTS = {}
for _n, _size, *_rest in (hd2d_interior.ALL_FURNITURE + hd2d_interior.ALL_OBJECTS
                          + hd2d_interior.OUTDOOR + hd2d_interior.HANGING):
    HEIGHTS[_n] = _size[1] / 96.0
for _n, _image, _size, *_rest in hd2d_interior.FURNITURE_OTHER_IMAGES:
    HEIGHTS[_n] = _size[1] / 96.0


PROPS_IMAGES = os.path.join(ROOT, "assets", "hd2d", "interior", "props")
# Image qu'un meuble de ce regard montre : E et O le flanc, N le dos ou, pour un lit, le pied.
FACING_OF_REGARD = {"E": "east", "O": "west", "N": "north", "S": "south"}
# Un lit vu par le pied (tête contre le mur nord).
BED_PREFIXES = ("bed_", "bunk_bed")


def view_size(image, view):
    """Taille en px de la vue <image>_<view> si son image existe (livrée ou remplaçant), sinon None."""
    path = os.path.join(PROPS_IMAGES, "%s_%s.png" % (image, view))
    if not os.path.exists(path):
        return None
    with Image.open(path) as picture:
        return picture.size


def chosen_view(image, regard):
    """(vue, taille) que montre un meuble de ce regard : "side" pour E et O, "back" ou "foot" pour N,
    la face (None) pour S, sans regard ou sans image de la vue."""
    if regard in ("E", "O"):
        views = ["side"]
    elif regard == "N":
        views = ["back", "foot"]
    else:
        views = []
    for view in views:
        size = view_size(image, view)
        if size:
            return view, size
    return None, None


def scene_path(image):
    if image in ("laundry_basket", "chimney_brick", "treeline_autumn_a", "treeline_autumn_b", "tree_autumn",
                 "tree_autumn_rust", "moss_patch_a", "moss_patch_b", "bucket"):
        return "src/world/props/%s.tscn" % image
    if image in ("door_armory_inside",):
        return "src/world/props/interior/%s.tscn" % image
    return hd2d_interior.scene_path(image)


# --- Écriture d'une scène ------------------------------------------------------------------------


class Scene:
    """Scène .tscn écrite à la main (recette de CLAUDE.md) : ressources par chemin, formes, nœuds."""

    def __init__(self):
        self.ext = {}
        self.ext_order = []
        self.subs = []
        self.sub_keys = {}
        self.nodes = []

    def res(self, kind, path, rid=None):
        if path not in self.ext:
            rid = rid or "%d_%s" % (len(self.ext_order) + 1, os.path.splitext(os.path.basename(path))[0])
            self.ext[path] = (kind, rid)
            self.ext_order.append(path)
        return 'ExtResource("%s")' % self.ext[path][1]

    def box(self, size):
        key = tuple(round(v, 4) for v in size)
        if key not in self.sub_keys:
            sid = "BoxShape3D_%d" % (len(self.subs) + 1)
            self.sub_keys[key] = sid
            self.subs.append('[sub_resource type="BoxShape3D" id="%s"]\nsize = Vector3(%s)\n'
                             % (sid, ", ".join(num(v) for v in key)))
        return 'SubResource("%s")' % self.sub_keys[key]

    def node(self, name, kind=None, parent=None, instance=None, props=(), node_paths=None):
        head = '[node name="%s"' % name
        if kind:
            head += ' type="%s"' % kind
        if parent is not None:
            head += ' parent="%s"' % parent
        if instance:
            head += ' instance=%s' % instance
        head += "]"
        self.nodes.append("\n".join([head] + ["%s = %s" % (k, v) for k, v in props]) + "\n")

    def text(self):
        out = ["[gd_scene format=3]", ""]
        for path in self.ext_order:
            kind, rid = self.ext[path]
            out.append('[ext_resource type="%s" path="res://%s" id="%s"]' % (kind, path, rid))
        out.append("")
        out += self.subs
        out += self.nodes
        return "\n".join(out).rstrip("\n") + "\n"


def transform(x, y, z, yaw_deg=0.0):
    a = math.radians(yaw_deg)
    c, s = math.cos(a), math.sin(a)
    rows = [c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c]
    return "Transform3D(%s, %s, %s, %s)" % (", ".join(num(round(v, 6)) for v in rows), num(x), num(y), num(z))


# Regard d'un marqueur (son −Z) : N, S, E, O.
YAWS = {"N": 0.0, "S": 180.0, "E": -90.0, "O": 90.0, "W": 90.0}


def node_name(text):
    return "".join(part.capitalize() for part in text.split("_"))


# --- Intérieurs ----------------------------------------------------------------------------------


def opening(plan, door, rooms_side):
    """Ouverture entre deux pièces ou vers le dehors : axe, centre, largeur ajustée aux angles."""
    a, b = door.extra["a"], door.extra["b"]
    x, z = door.rect.x0, door.rect.z0
    width = door.extra["l"]
    inside = [r for r in (a, b) if r != "dehors"]
    rects = [plan.rooms[r].rect for r in inside]
    side = side_of(rects[0], x, z)
    horizontal = side in ("N", "S")
    if len(rects) == 2:
        if horizontal:
            lo, hi = max(rects[0].x0, rects[1].x0), min(rects[0].x1, rects[1].x1)
        else:
            lo, hi = max(rects[0].z0, rects[1].z0), min(rects[0].z1, rects[1].z1)
    else:
        lo, hi = (rects[0].x0, rects[0].x1) if horizontal else (rects[0].z0, rects[0].z1)
    center = x if horizontal else z
    room = max(0.0, min(center - lo, hi - center) - CORNER_GAP)
    adjusted = min(width, 2.0 * room)
    if adjusted < DOOR_MIN:
        adjusted = min(width, DOOR_MIN)
        center = min(max(center, lo + CORNER_GAP + adjusted / 2.0), hi - CORNER_GAP - adjusted / 2.0)
    return {"axis": "x" if horizontal else "z", "center": round(center, 3), "width": round(adjusted, 3),
            "side": side, "room": inside[0], "planned": (width, x if horizontal else z)}


def interior_json(map_id, plan):
    rooms = {}
    for room_id, room in plan.rooms.items():
        r = room.rect
        wall = room.extra["mur"]
        entry = {"name": ROOM_NAMES.get(room_id, room_id), "rects": [[r.x0, r.z0, r.w(), r.d()]],
                 "floor": room.extra["sol"], "wall": wall}
        if wall in WALLCUTS:
            entry["wallcut"] = WALLCUTS[wall]
        rooms[room_id] = entry
    doors = []
    deviations = []
    for door in plan.doors:
        place = opening(plan, door, None)
        a, b = door.extra["a"], door.extra["b"]
        image = door.extra["img"]
        if (place["width"], place["center"]) != place["planned"]:
            deviations.append("%s|%s : %.2f m en %.2f (plan : %.2f m en %.2f)"
                              % (a, b, place["width"], place["center"], place["planned"][0], place["planned"][1]))
        if "dehors" in (a, b):
            spec = OUTSIDE_DOORS[image]
            entry = {"id": spec["id"], "room": place["room"], "side": place["side"],
                     place["axis"]: place["center"], "width": place["width"], "height": spec["height"],
                     "image": image}
            if not spec["passable"]:
                entry["passable"] = False
        else:
            entry = {"between": [a, b], place["axis"]: place["center"], "width": place["width"]}
            if door.kind == "porte":
                entry["image"] = image if image in OWN_IMAGE_DOORS else PASSABLE_IMAGE
        doors.append(entry)
    windows = []
    for window in plan.windows:
        image = window.extra["img"]
        side = wall_side(window.extra["wall"])
        key = "x" if side in ("N", "S") else "z"
        windows.append({"room": window.extra["room"], "side": side, key: window.extra["pos"], "image": image,
                        "sill": SILLS[image]})
    items = []
    for item in plan.walls:
        if not item.name.startswith("wallitem_"):
            continue
        side = wall_side(item.extra["wall"])
        key = "x" if side in ("N", "S") else "z"
        pos = clamp_on_wall(plan.rooms[item.extra["room"]].rect, side, item.extra["pos"], image_width(item.name))
        if abs(pos - item.extra["pos"]) > 1e-6:
            deviations.append("%s : %s en %.2f (plan : %.2f, contre l'angle)" % (item.extra["room"], item.name, pos,
                                                                              item.extra["pos"]))
        items.append({"room": item.extra["room"], "side": side, key: pos, "y": item.extra["bas"],
                      "image": item.name})
    lights = []
    for light in plan.lights:
        spec = LIGHT_TYPES.get(light.extra["type"])
        if spec is None:
            continue
        x, z = light.rect.x0, light.rect.z0
        radius, color, energy = spec
        if light.name.startswith("suspension"):
            radius = SUSPENSION_RADIUS
        lights.append({"room": room_of(plan, x, z), "at": [x, z], "radius": radius, "color": color,
                       "energy": energy})
    data = {
        "_comment": "%s : écrit par tools/interior_maps.py d'après docs/lore/CARTE.md (section 3, bloc plan "
                    "« carte %s ») ; modifier le plan ou l'outil, puis relancer gen. Format : "
                    "docs/INTERIEURS.md." % (plan.meta.get("nom", [map_id])[0], map_id),
        "size": [int(plan.w), int(plan.d)],
        "wall_height": 3.0,
        "wall_thickness": 0.25,
        "rooms": rooms,
        "doors": doors,
        "windows": windows,
        "wall_items": items,
        "lights": lights,
    }
    return data, deviations


def clamp_on_wall(rect, side, pos, width):
    """Centre d'un élément de mur ramené à CORNER_GAP m des angles de sa pièce (InteriorLayout)."""
    lo, hi = (rect.x0, rect.x1) if side in ("N", "S") else (rect.z0, rect.z1)
    return round(min(max(pos, lo + CORNER_GAP + width / 2.0), hi - CORNER_GAP - width / 2.0), 3)


def json_text(data):
    """JSON lisible : une pièce, une porte, une fenêtre, un élément ou une lampe par ligne."""
    lines = ["{"]
    keys = list(data)
    for n, key in enumerate(keys):
        value = data[key]
        comma = "," if n < len(keys) - 1 else ""
        if isinstance(value, list) and value and isinstance(value[0], dict):
            lines.append("  %s: [" % json.dumps(key))
            for k, entry in enumerate(value):
                lines.append("    %s%s" % (json.dumps(entry, ensure_ascii=False), "," if k < len(value) - 1 else ""))
            lines.append("  ]" + comma)
        elif isinstance(value, dict):
            lines.append("  %s: {" % json.dumps(key))
            items = list(value.items())
            for k, (sub, entry) in enumerate(items):
                lines.append("    %s: %s%s" % (json.dumps(sub), json.dumps(entry, ensure_ascii=False),
                                               "," if k < len(items) - 1 else ""))
            lines.append("  }" + comma)
        else:
            lines.append("  %s: %s%s" % (json.dumps(key), json.dumps(value, ensure_ascii=False), comma))
    lines.append("}")
    text = "\n".join(lines) + "\n"
    json.loads(text)
    return text


def furniture_front(item):
    """z de l'image d'un meuble : le bord sud de son emprise dans le plan (la scène est posée pour
    que son image y tombe, quelle que soit la profondeur de sa collision)."""
    return item["z"] + item["p"] / 2.0


def support_of(furniture, x, z):
    """Meuble qui porte un objet posé en (x, z) (le plus haut sous le point)."""
    best = None
    for item in furniture:
        if item["image"] in DECALS or item["image"] in HANGING or item["free"]:
            continue
        if abs(item["x"] - x) <= item["l"] / 2.0 + 1e-6 and abs(item["z"] - z) <= item["p"] / 2.0 + 1e-6:
            if best is None or item["h"] > best["h"]:
                best = item
    return best


def feet_hidden(player_x, player_z, front, x0, x1, top, bounds):
    """Vrai si l'image (bord sud en front, de x0 à x1, haut à top) cache les pieds d'un joueur en
    (player_x, player_z), vu par la caméra du jeu bornée à bounds (x, z, largeur, profondeur) : la
    caméra suit le joueur dans ses bornes, donc le regarde de biais au-delà."""
    focus_x = min(max(player_x, bounds[0]), bounds[0] + bounds[2])
    focus_z = min(max(player_z - FOCUS_AHEAD, bounds[1]), bounds[1] + bounds[3])
    pitch = math.radians(CAMERA_PITCH)
    cam_y = FOCUS_HEIGHT + CAMERA_DISTANCE * math.sin(pitch)
    cam_z = focus_z + CAMERA_DISTANCE * math.cos(pitch)
    if front <= player_z or front >= cam_z:
        return False
    t = (cam_z - front) / (cam_z - player_z)
    x_at = focus_x + (player_x - focus_x) * t
    return x0 < x_at < x1 and cam_y + (FEET - cam_y) * t < top


def image_size_m(name):
    """(largeur, hauteur) en m d'une image d'intérieur (assets/hd2d/interior/, props/ compris)."""
    for folder in ("interior", os.path.join("interior", "props"), "props"):
        path = os.path.join(ROOT, "assets", "hd2d", folder, name + ".png")
        if os.path.exists(path):
            with Image.open(path) as image:
                return image.width / 96.0, image.height / 96.0
    raise SystemExit("image absente : %s" % name)


def image_width(name):
    return image_size_m(name)[0]


def hiding_rules(plan, furniture, settings, item, blockers):
    """Pour un meuble haut : {"cut_offset": m} s'il est adossé au mur sud, ou la boîte (x0, z0, x1,
    z1) qui ferme la place où il cacherait les pieds du joueur ; {} sinon."""
    image = item["image"]
    # (I1) L'image qui se dessine est celle de la vue (flanc, dos, pied) : sa largeur et sa hauteur.
    if image not in DEPTHS:
        return {}
    shown_width, shown_height = image_size_m(item["shown"])
    if (shown_height if item["shown"] != image else HEIGHTS.get(image, 0.0)) <= TALL:
        return {}
    room = plan.rooms[room_of(plan, item["x"], item["z"])].rect
    front = furniture_front(item)
    back = front - item["depth"]
    if back <= room.z0 + WALL_HALF + NORTH_REACH:
        return {}
    if front >= room.z1 - WALL_HALF - SOUTH_REACH:
        return {"cut_offset": round(room.z1 - front + 0.05, 3)}
    width = shown_width
    x0, x1 = item["x"] - width / 2.0, item["x"] + width / 2.0
    top = shown_height
    # Ce qui arrête déjà le joueur (un centre n'y entre pas) : les autres meubles et fermetures.
    solid = []
    for other in furniture:
        if other is item or other["image"] in DECALS or other["image"] in HANGING or other["free"]:
            continue
        o_front = furniture_front(other)
        o_depth = other["depth"]
        solid.append((other["x"] - other["l"] / 2.0, o_front - o_depth, other["x"] + other["l"] / 2.0, o_front))
    solid += [(bx0, bz0, bx1, bz1) for _name, bx0, bz0, bx1, bz1, _h in blockers]

    def reachable(px, pz):
        return not any(sx0 - PLAYER_RADIUS < px < sx1 + PLAYER_RADIUS and sz0 - PLAYER_RADIUS < pz < sz1 + PLAYER_RADIUS
                       for sx0, sz0, sx1, sz1 in solid)

    # Les centres du joueur dont les pieds sont cachés, derrière l'image (pas de 5 cm).
    hidden = []
    left = room.x0 + WALL_HALF + PLAYER_RADIUS
    right = room.x1 - WALL_HALF - PLAYER_RADIUS
    north = room.z0 + WALL_HALF + PLAYER_RADIUS
    steps_x = int(round((right - left) / 0.05))
    pz = back - PLAYER_RADIUS
    while pz >= north - 1e-6:
        for k in range(steps_x + 1):
            px = left + 0.05 * k
            if feet_hidden(px, pz, front, x0, x1, top, settings["camera_bounds"]) and reachable(px, pz):
                hidden.append((px, pz))
        pz -= 0.05
    if not hidden:
        return {}
    # La capsule du joueur est ronde : la boîte déborde un peu dans la place cachée (BOX_INSET) et
    # commence un peu avant sa limite (BOX_LEAD), pour qu'aucun centre caché ne s'y glisse en biais.
    z0 = max(min(z for _x, z in hidden) + PLAYER_RADIUS - BOX_LEAD, room.z0 + WALL_HALF)
    if back - z0 < 0.05:
        return {}
    hx0, hx1 = min(x for x, _z in hidden), max(x for x, _z in hidden)
    bx0 = max(hx0 - 0.025 + BOX_INSET, room.x0 + WALL_HALF)
    bx1 = min(hx1 + 0.025 - BOX_INSET, room.x1 - WALL_HALF)
    if bx1 - bx0 < 0.02:
        # Place cachée plus étroite que le joueur : une boîte fine en son milieu suffit.
        bx0, bx1 = (hx0 + hx1) / 2.0 - 0.01, (hx0 + hx1) / 2.0 + 0.01
    return {"box": (round(bx0, 3), round(z0, 3), round(bx1, 3), round(back, 3))}


def interior_scene(map_id, plan, settings):
    scene = Scene()
    map_script = scene.res("Script", "src/world/map.gd", "1_map")
    room_script = scene.res("Script", "src/world/interior_room.gd", "2_room")
    layout = scene.res("JSON", "data/maps/%s/interior.json" % map_id, "3_layout")
    batcher = scene.res("Script", "src/world/prop_batcher.gd", "4_batcher")
    exit_script = scene.res("Script", "src/world/map_exit.gd", "5_exit")
    bounds = settings["camera_bounds"]
    props = [("script", map_script), ("display_name", json.dumps(plan.meta["nom"][0], ensure_ascii=False)),
             ("region", '&"%s"' % plan.meta["region"][0]), ("interior", "true"),
             ("size", "Vector2(%s, %s)" % (num(plan.w), num(plan.d))),
             ("camera_bounds", "Rect2(%s)" % ", ".join(num(v) for v in bounds))]
    if settings["light_preset"]:
        props.append(("light_preset", '&"%s"' % settings["light_preset"]))
    scene.node(map_id, "Node3D", props=props)
    scene.node("Ground", "StaticBody3D", ".", props=[("collision_mask", "0"), ("script", room_script),
                                                      ("layout", layout)])
    scene.node("Geometry", "Node3D", ".", props=[("script", batcher)])
    furniture = expand_furniture(plan)
    groups = []
    for room_id in plan.rooms:
        groups.append(room_id)
        scene.node(node_name(room_id), "Node3D", "Geometry")
    names = {}

    def unique(base):
        names[base] = names.get(base, 0) + 1
        return "%s_%d" % (base, names[base])

    for item in furniture:
        image = item["image"]
        room_id = room_of(plan, item["x"], item["z"])
        parent = "Geometry/%s" % node_name(room_id)
        instance = scene.res("PackedScene", scene_path(image), "p_" + image)
        y = 0.0
        if image in HANGING:
            y = 3.0 - HEIGHTS[image]
        if image == "runner_rug":
            # Tapis de couloir (1 × 4 m, raccord en long) : couché en travers, bout à bout sur la
            # longueur du plan.
            length = item["l"]
            count = int(math.ceil(length / 4.0))
            x0 = item["x"] - length / 2.0
            for k in range(count):
                cx = min(x0 + 2.0 + 4.0 * k, item["x"] + length / 2.0 - 2.0)
                scene.node(unique(image), parent=parent, instance=instance,
                           props=[("transform", transform(cx, 0.0, item["z"], 90.0))])
            continue
        z = item["z"]
        if image in DEPTHS:
            # Meuble : son image (bord sud de la scène) au bord sud de l'emprise du plan.
            z = round(furniture_front(item) - item["depth"] / 2.0, 4)
        elif image in OBJECTS:
            z = round(furniture_front(item), 4)
        rules = hiding_rules(plan, furniture, settings, item, BLOCKERS.get(map_id, []))
        props = [("transform", transform(item["x"], y, z, item["yaw"]))]
        if item["turned"]:
            # (I1) Tourné d'un quart de tour (vue de flanc ou par le pied) : le nœud est au milieu de
            # l'emprise tournée, l'image au bord sud de sa profondeur (le long du mur), l'ombre sur elle.
            z = item["z"]
            props = [("transform", transform(item["x"], y, z, item["yaw"]))]
            shown_w = image_width(item["shown"])
            props.append(("image_offset", "Vector3(0, 0, %s)" % num(item["p"] / 2.0)))
            props.append(("shadow_width", "0.9"))
            props.append(("shadow_depth", num(round(min(2.0, max(0.05, item["p"] / (shown_w * 0.9))), 3))))
        if item["facing"]:
            props.append(("facing", '&"%s"' % item["facing"]))
        if "cut_offset" in rules:
            props.append(("cut_offset", num(rules["cut_offset"])))
        name = unique(image)
        scene.node(name, parent=parent, instance=instance, props=props)
        if "box" in rules:
            bx0, bz0, bx1, bz1 = rules["box"]
            body = "%s_arriere" % name
            scene.node(body, "StaticBody3D", parent, props=[("collision_mask", "0")])
            scene.node("CollisionShape3D", "CollisionShape3D", "%s/%s" % (parent, body),
                       props=[("transform", transform((bx0 + bx1) / 2.0, 1.5, (bz0 + bz1) / 2.0)),
                              ("shape", scene.box((bx1 - bx0, 3.0, bz1 - bz0)))])
    # Éléments « mural » qui sont des meubles ou une porte.
    for wall in plan.walls:
        if wall.name.startswith("wallitem_"):
            continue
        room = plan.rooms[wall.extra["room"]].rect
        side = wall_side(wall.extra["wall"])
        parent = "Geometry/%s" % node_name(wall.extra["room"])
        instance = scene.res("PackedScene", scene_path(wall.name), "p_" + wall.name)
        if wall.name == "mirror_large" and side == "W":
            x = room.x0 + WALL_HALF + 0.08
            scene.node(unique(wall.name), parent=parent, instance=instance,
                       props=[("transform", transform(x, wall.extra["bas"], wall.extra["pos"], YAWS[FACE_EAST])),
                              ("keep_orientation", "true"), ("image_offset", "Vector3(0, 0, 0)")])
        elif wall.name in WALL_ANIMS and side == "W":
            # (I2) Bande animée accrochée au mur ouest (l'horloge des archives) : DecorPanel qui regarde l'est.
            x = room.x0 + WALL_HALF + 0.03
            scene.node(unique(wall.name), parent=parent, instance=instance,
                       props=[("transform", transform(x, wall.extra["bas"], wall.extra["pos"], YAWS[FACE_EAST])),
                              ("keep_orientation", "true")])
        elif wall.name == "door_armory_inside" and side == "N":
            height = HEIGHTS[wall.name]
            y = max(0.0, min(wall.extra["bas"], 3.0 - height))
            z = room.z0 + WALL_HALF + DEPTHS[wall.name] / 2.0 + 0.02
            scene.node(unique(wall.name), parent=parent, instance=instance,
                       props=[("transform", transform(wall.extra["pos"], y, z))])
        else:
            raise SystemExit("%s : élément mural %s non pris en charge" % (map_id, wall.name))
    # Objets posés (sur leur meuble, juste devant son image) et bandes animées.
    for obj in plan.objects:
        x, z = obj.rect.x0, obj.rect.z0
        support = support_of(furniture, x, z)
        room_id = room_of(plan, x, z)
        parent = "Geometry/%s" % node_name(room_id)
        instance = scene.res("PackedScene", scene_path(obj.name), "p_" + obj.name)
        front = furniture_front(support) + 0.02 if support else z
        y = support["h"] if support else 0.0
        if obj.name == "pot_steam":
            y = support["h"] - 0.15
        elif obj.name == "bath_steam":
            # Le bas de l'image est la surface de l'eau : un peu sous le rebord de la baignoire.
            y = support["h"] - BATH_WATER_DROP
        elif obj.name == "hearth_fire":
            y = 0.1
        elif obj.name in OVERLAYS:
            # (I2) Image qui reprend celle d'un meuble au pixel près : même pied, même bord sud.
            y = 0.0
        props = [("transform", transform(x, round(y, 3), round(front, 3)))]
        if obj.name in HIDDEN_OBJECTS:
            props.append(("visible", "false"))
        scene.node(unique(obj.name), parent=parent, instance=instance, props=props)
    # Ce qui bloque sans image.
    for name, x0, z0, x1, z1, h in BLOCKERS.get(map_id, []):
        room_id = room_of(plan, (x0 + x1) / 2.0, (z0 + z1) / 2.0)
        parent = "Geometry/%s" % node_name(room_id)
        scene.node(name, "StaticBody3D", parent, props=[("collision_mask", "0")])
        scene.node("CollisionShape3D", "CollisionShape3D", "%s/%s" % (parent, name),
                   props=[("transform", transform((x0 + x1) / 2.0, h / 2.0, (z0 + z1) / 2.0)),
                          ("shape", scene.box((x1 - x0, h, z1 - z0)))])
    markers_exits_life(scene, map_id, plan, furniture, exit_script)
    return scene


def markers_exits_life(scene, map_id, plan, furniture, exit_script):
    scene.node("Markers", "Node3D", ".")
    for name, marker in plan.markers.items():
        scene.node(name, "Marker3D", "Markers",
                   props=[("transform", transform(marker.rect.x0, 0.2, marker.rect.z0,
                                                  YAWS[marker.extra["regard"]]))])
    scene.node("Exits", "Node3D", ".")
    for exit_item in plan.exits:
        r = exit_item.rect
        target = exit_item.extra["cible"]
        marker = exit_item.extra["marqueur"]
        if not os.path.exists(os.path.join(ROOT, "src", "world", "maps", target, target + ".tscn")) \
                and target in PROVISIONAL:
            target, marker = PROVISIONAL[target]
        props = [("transform", transform((r.x0 + r.x1) / 2.0, 0.0, (r.z0 + r.z1) / 2.0)),
                 ("collision_layer", "0"), ("collision_mask", "2"), ("script", exit_script),
                 ("target_map", '&"%s"' % target), ("target_marker", '&"%s"' % marker)]
        if exit_item.extra["invite"]:
            props.append(("prompt", json.dumps(exit_item.extra["invite"], ensure_ascii=False)))
        scene.node(exit_item.name, "Area3D", "Exits", props=props)
        scene.node("CollisionShape3D", "CollisionShape3D", "Exits/%s" % exit_item.name,
                   props=[("transform", transform(0.0, 1.2, 0.0)),
                          ("shape", scene.box((r.w(), 2.4, r.d())))])
    examinables = examine_spots(map_id, plan, furniture)
    if examinables:
        examine_script = scene.res("Script", "src/world/examinable.gd", "6_examine")
        scene.node("Examine", "Node3D", ".")
    for key, x, z, size in examinables:
        scene.node(key, "Area3D", "Examine",
                   props=[("transform", transform(x, 0.0, z)), ("script", examine_script),
                          ("text_key", json.dumps("%s/%s" % (map_id, key))),
                          ("size", "Vector3(%s)" % ", ".join(num(round(v, 3)) for v in size))]
                   + ([("texts_path", json.dumps(TEXTS_PATH[map_id]))] if map_id in TEXTS_PATH else []))
    scene.node("Life", "Node3D", ".")
    scene.node("Places", "Node3D", "Life")
    for name, x, z, yaw, y, children in places(map_id, plan, furniture):
        scene.node(name, "Marker3D", "Life/Places", props=[("transform", transform(x, y, z, yaw))])
        # (V1) Les points d'une zone : enfants du marqueur, en repère local (le marqueur n'est pas tourné).
        for k, (cx, cz, cyaw, dy) in enumerate(children):
            scene.node("p%d" % (k + 1), "Marker3D", "Life/Places/%s" % name,
                       props=[("transform", transform(round(cx - x, 3), round(dy - y, 3), round(cz - z, 3), cyaw))])


def examine_spots(map_id, plan, furniture):
    """Zones des objets à examiner : (clé, x, z, taille), au pied de ce qu'on examine, côté pièce."""
    out = []
    for key, kind, ref, opts in EXAMINE.get(map_id, []):
        depth = opts.get("d", 0.8)
        if kind == "meuble":
            image, index = ref
            item = [f for f in furniture if f["image"] == image][index]
            if image in DECALS:
                x, z, width, depth = item["x"], item["z"], item["l"], item["p"]
            elif item["turned"]:
                # (I1) Tourné vers sa vue de flanc : on l'examine de face, côté pièce (est ou ouest).
                side = 1.0 if item["regard"] == "E" else -1.0
                x, z = item["x"] + side * (item["l"] / 2.0 + 0.3), item["z"]
                width, depth = 0.8, max(item["p"], 0.8)
            else:
                x, z = item["x"], furniture_front(item)
                width = max(item["l"], 0.8)
        elif kind in ("mural", "fenetre"):
            source = plan.walls if kind == "mural" else plan.windows
            found = [w for w in source if (w.name if kind == "mural" else w.extra["img"]) == ref][0]
            room = plan.rooms[found.extra["room"]].rect
            side = wall_side(found.extra["wall"])
            pos = found.extra["pos"]
            width = max(found.extra.get("l", 0.5), 0.8)
            if side == "N":
                x, z = pos, room.z0 + WALL_HALF + depth / 2.0
            elif side == "W":
                x, z, width, depth = room.x0 + WALL_HALF + depth / 2.0, pos, depth, width
            elif side == "E":
                x, z, width, depth = room.x1 - WALL_HALF - depth / 2.0, pos, depth, width
            else:
                x, z = pos, room.z1 - WALL_HALF - depth / 2.0
        else:
            x, z = ref
            width = opts.get("w", 0.8)
        width = opts.get("w", width)
        out.append((key, x + opts.get("dx", 0.0), z, (width, 2.0, depth)))
    return out


# --- Places de la vie (Life/Places) ---------------------------------------------------------------

CHAIR_FACING = {"chair_wood": 180.0, "chair_wood_back": 0.0}
BEDS = ("bed_iron", "bed_plain", "bed_child", "bed_child_messy", "bed_chtholly", "bed_nygglatho", "bunk_bed")


def places(map_id, plan, furniture):
    """Places nommées : les points du plan, puis chaque chaise (assise) et chaque lit (couchage), puis les
    zones et les départs de tools/life_zones.py ; (nom, x, z, regard en degrés, hauteur, points enfants)."""
    out = [(name, p.rect.x0, p.rect.z0, life_zones.point_yaw(map_id, name), 0.0, [])
           for name, p in plan.points.items()]
    taken = {name for name, *_ in out}
    rows = {}
    for item in furniture:
        if item["image"] in CHAIR_FACING:
            rows.setdefault(round(item["z"], 2), []).append(item)
    for k, z in enumerate(sorted(rows)):
        letter = "abcdefgh"[k]
        for n, item in enumerate(sorted(rows[z], key=lambda f: f["x"])):
            out.append(("%s_chaise_%s%02d" % (room_of(plan, item["x"], item["z"]), letter, n + 1), item["x"],
                        item["z"], CHAIR_FACING[item["image"]], 0.0, []))
    beds = {}
    for item in furniture:
        if item["image"] in BEDS:
            room_id = room_of(plan, item["x"], item["z"])
            beds.setdefault(room_id, []).append(item)
    for room_id, items in beds.items():
        items.sort(key=lambda f: (f["z"], f["x"]))
        for n, item in enumerate(items):
            base = "%s_lit" % room_id if len(items) == 1 and item["image"] != "bunk_bed" else "%s_lit_%d" % (
                room_id, n + 1)
            if base in taken:
                base += "_couche"
            if item["image"] == "bunk_bed":
                out.append((base + "_bas", item["x"], item["z"], 0.0, life_zones.BED_HEIGHT, []))
                out.append((base + "_haut", item["x"], item["z"], 0.0, life_zones.BUNK_HEIGHT, []))
            else:
                out.append((base, item["x"], item["z"], 0.0, life_zones.BED_HEIGHT, []))
            taken.add(base)
    out += [(name, x, z, yaw, 0.0, []) for name, x, z, yaw in EXTRA_PLACES.get(map_id, [])]
    for entry in life_zones.zones_of(map_id):
        x, z, yaw, _dy = life_zones.anchor(entry)
        out.append((entry["name"], x, z, yaw, 0.0, entry["pts"]))
    names = [name for name, *_ in out]
    duplicates = {n for n in names if names.count(n) > 1}
    if duplicates:
        raise SystemExit("%s : places en double %s" % (map_id, sorted(duplicates)))
    return out


# Places citées par VIE.md et ACTE1.md que les points du plan ne nomment pas.
EXTRA_PLACES = {
    "entrepot_rdc": [
        ("lecture_fauteuil", 30.3, 7.4, 180.0),
        ("archives_canape_assise", 23.65, 6.5, 180.0),
        ("infirmerie_chevet", 25.0, 12.15, 180.0),
        ("jeux_piano", 16.2, 12.1, 0.0),
    ],
    "entrepot_etage": [
        ("nygglatho_chaise_invite", 9.0, 4.4, 180.0),
        ("chtholly_chaise", 6.2, 1.9, 0.0),
        ("willem_rebord_fenetre", 2.0, 1.6, 180.0),
    ],
    "salle_des_armes": [],
    "entrepot_toit": [],
    # (C2) Places que VIE.md et ACTE1.md citent et que les points du plan ne nomment pas.
    "cafe": [
        ("comptoir_arriere", 4.0, 2.2, 180.0),
        ("entree", 4.75, 8.3, 0.0),
    ],
    "maison_limashenka": [
        ("salon_canape_assise", 6.0, 5.3, 180.0),
        ("vestibule_porte", 2.25, 5.6, 0.0),
    ],
}


# --- Toit (dehors, MapGround) ---------------------------------------------------------------------


def roof_ground(map_id, plan):
    """Sol du toit : la terrasse (planches) au niveau 0, la cour 6,5 m plus bas tout autour (bord de
    la carte, et au-delà par la jupe du MapGround), le pan d'ardoise à l'ouest (roche, sous le
    volume ouest) ; faces de la chute en muret."""
    w, d = int(plan.w), int(plan.d)
    folder = os.path.join(ROOT, "data", "maps", map_id)
    os.makedirs(folder, exist_ok=True)
    deck = [g for g in plan.grounds if g.name == "floor_roof_deck"][0].rect
    roof = [g for g in plan.grounds if g.name == "rock"][0].rect
    materials = lib()["materials"]
    heights = Image.new("RGBA", (w, d), (0, 0, 0, 0))
    mats = Image.new("RGBA", (w, d), (0, 0, 0, 0))
    structures = Image.new("RGBA", (w, d), (0, 0, 0, 0))
    wall_face = (0x40, 0x40, 0x40, 255)
    used = []

    def paint(i, j, level, material):
        v = ROOF_ZERO + level * 16
        heights.putpixel((i, j), (v, v, v, 255))
        color = materials[material]["color"].lstrip("#")
        mats.putpixel((i, j), tuple(int(color[k:k + 2], 16) for k in (0, 2, 4)) + (255,))
        if material not in used:
            used.append(material)

    for j in range(d):
        for i in range(w):
            cx, cz = i + 0.5, j + 0.5
            if roof.has(cx, cz):
                paint(i, j, 0, ROOF_MATERIALS["rock"])
            elif deck.has(cx, cz):
                paint(i, j, 0, ROOF_MATERIALS["floor_roof_deck"])
                edge = i in (int(deck.x0), int(deck.x1) - 1) or j in (int(deck.z0), int(deck.z1) - 1)
                if edge:
                    structures.putpixel((i, j), wall_face)
            else:
                paint(i, j, -ROOF_DROP_LEVELS, ROOF_MATERIALS["below"])
    heights.save(os.path.join(folder, "heights.png"), optimize=True)
    mats.save(os.path.join(folder, "materials.png"), optimize=True)
    structures.save(os.path.join(folder, "structures.png"), optimize=True)
    spawn = plan.markers["Spawn"].rect
    spec = {
        "_comment": "Sol du toit-terrasse de l'entrepôt (docs/lore/CARTE.md 3.3), écrit par tools/interior_maps.py "
                    "(pas par map_build.py gen : la terrasse est au niveau 0 et la cour 6,5 m plus bas, "
                    "height_zero_value) : terrasse de planches, pan d'ardoise du volume ouest (roche, sous le "
                    "bâtiment), la cour et la lisière tout autour, faces de la chute en muret.",
        "format": "map_ground",
        "version": 1,
        "size": [w, d],
        "heights_image": "heights.png",
        "height_step_value": 16,
        "height_zero_value": ROOF_ZERO,
        "materials_image": "materials.png",
        "materials_scale": 1,
        "structures_image": "structures.png",
        "palette": {materials[m]["color"]: m for m in used},
        "edges": {"north": "land", "east": "land", "south": "land", "west": "land"},
        "skirt": 16,
        "barrier": True,
        "spawn": [int(spawn.x0), int(spawn.z0)],
    }
    with open(os.path.join(folder, "map.json"), "w", encoding="utf-8") as handle:
        handle.write(json.dumps(spec, ensure_ascii=False, indent=2) + "\n")


# Le toit : décors posés au-delà de ce que le plan donne en lignes (sa prose, 3.3) : rambarde en
# modules de 2 m au nord, à l'est et au sud ; le volume ouest (Building) et son pan d'ardoise ; les
# lisières au nord, 6,5 m plus bas ; quelques détails (linge, seau, mousse).
ROOF_RAILING = 2.0
# Tuiles de sol de la terrasse (floor_roof_deck : 4 × 4 m, étirée à 3,5 m dans le sens nord-sud pour que 4 rangées
# couvrent les 14 m de la terrasse sans dépasser) et modules du bord d'ardoise (centres en x).
ROOF_DECK_TILE = 4.0
ROOF_DECK_TILE_Z = 3.5
ROOF_EDGE_X = (1.0, -3.0)
ROOF_TREES = [
    ("treeline_autumn_b", 0.0, -2.5), ("treeline_autumn_a", 15.0, -2.5),
    ("treeline_autumn_a", -6.0, -9.0), ("treeline_autumn_b", 9.0, -9.0), ("treeline_autumn_a", 24.0, -9.0),
    ("treeline_autumn_b", 2.0, -16.0), ("treeline_autumn_a", 18.0, -16.0),
    ("tree_autumn_rust", 19.5, 3.0), ("tree_autumn", 21.0, 9.5),
    # (QC) Au sud-est, des couronnes au ras de la terrasse : on y voyait le sous-bois 6,5 m plus
    # bas comme un pré au niveau des planches, et le toit semblait posé par terre (docs/QUALITE.md,
    # QC-10).
    ("tree_autumn", 18.6, 12.0), ("tree_autumn_rust", 18.6, 16.5),
]
ROOF_DETAILS = [
    ("laundry_basket", 9.6, 13.0), ("bucket", 14.2, 12.6), ("moss_patch_a", 6.0, 3.0),
    ("moss_patch_b", 13.0, 13.8), ("moss_patch_a", 4.4, 9.5),
]


def roof_scene(map_id, plan, settings):
    scene = Scene()
    map_script = scene.res("Script", "src/world/map.gd", "1_map")
    ground_script = scene.res("Script", "src/world/map_ground.gd", "2_ground")
    batcher = scene.res("Script", "src/world/prop_batcher.gd", "4_batcher")
    exit_script = scene.res("Script", "src/world/map_exit.gd", "5_exit")
    building = scene.res("PackedScene", "src/world/props/interior/entrepot_volume_ouest.tscn", "7_volume")
    bounds = settings["camera_bounds"]
    props = [("script", map_script), ("display_name", json.dumps(plan.meta["nom"][0], ensure_ascii=False)),
             ("region", '&"%s"' % plan.meta["region"][0]),
             ("size", "Vector2(%s, %s)" % (num(plan.w), num(plan.d))),
             ("camera_bounds", "Rect2(%s)" % ", ".join(num(v) for v in bounds))]
    if settings["light_preset"]:
        props.append(("light_preset", '&"%s"' % settings["light_preset"]))
    scene.node(map_id, "Node3D", props=props)
    scene.node("Ground", "StaticBody3D", ".", props=[("collision_mask", "0"), ("script", ground_script)])
    scene.node("Geometry", "Node3D", ".", props=[("script", batcher)])
    for group in ("Terrasse", "Rambarde", "VolumeOuest", "Lisiere"):
        scene.node(group, "Node3D", "Geometry")
    names = {}

    def unique(base):
        names[base] = names.get(base, 0) + 1
        return "%s_%d" % (base, names[base])

    def place(parent, image, x, y, z, yaw=0.0, extra=()):
        instance = scene.res("PackedScene", scene_path(image), "p_" + image)
        scene.node(unique(image), parent=parent, instance=instance,
                   props=[("transform", transform(round(x, 3), y, round(z, 3), yaw))] + list(extra))

    for decor in plan.decors:
        r = decor.rect
        x, z = (r.x0 + r.x1) / 2.0, (r.z0 + r.z1) / 2.0
        image = decor.name
        if image == "drying_frame":
            # Le séchoir (2,2 m) cacherait le joueur qui passe derrière : panneau de premier plan,
            # qui s'efface devant lui (règle de caméra, CARTE.md 0.3).
            place("Geometry/Terrasse", "drying_frame_wave", x, 0.0, z, 0.0, [("foreground", "true")])
            continue
        if image == "chimney_brick":
            # Sur le pan d'ardoise, à la hauteur du toit à cet endroit (faîtage à 3,5 m en z = 8).
            place("Geometry/VolumeOuest", image, x, round(3.5 * min(1.0, (z - 1.0) / 7.0), 3), z)
            continue
        if image == "roof_railing_broken":
            continue
        place("Geometry/Terrasse", image, x, 0.0, z)
    # Rambarde : modules de 2 m sur le bord de la terrasse (nord, est, sud), le module tordu au sud.
    deck = [g for g in plan.grounds if g.name == "floor_roof_deck"][0].rect
    broken = [d for d in plan.decors if d.name == "roof_railing_broken"][0].rect
    # Modules bout à bout le long de chaque bord ; au sud (premier plan, « pp » du plan), le module
    # tordu remplace celui qui est le plus près de sa place dans le plan.
    modules = int(round(deck.w() / ROOF_RAILING))
    centers = [deck.x0 + ROOF_RAILING * (k + 0.5) for k in range(modules)]
    broken_x = (broken.x0 + broken.x1) / 2.0
    broken_at = min(centers, key=lambda c: (abs(c - broken_x), -c))
    for x in centers:
        place("Geometry/Rambarde", "roof_railing", x, 0.0, deck.z0 + 0.15)
    for k in range(int(round(deck.d() / ROOF_RAILING))):
        z = deck.z0 + ROOF_RAILING * (k + 0.5)
        place("Geometry/Rambarde", "roof_railing", deck.x1 + 0.15, 0.0, z, -90.0, [("keep_orientation", "true")])
    for x in centers:
        image = "roof_railing_broken" if x == broken_at else "roof_railing"
        place("Geometry/Rambarde", image, x, 0.0, deck.z1 - 0.15, 0.0, [("foreground", "true")])
    # Le volume ouest : son toit d'ardoise (faîtage est-ouest à 3,5 m au-dessus de la terrasse).
    scene.node("entrepot_volume_ouest", parent="Geometry/VolumeOuest", instance=building,
               props=[("transform", transform(-6.0, -6.5, 8.0))])
    # (I2) Le sol de la terrasse : floor_roof_deck (livrée) en tuiles de 4 m de large et 3,5 m de long (le sol
    # de MapGround reste dessous, sans trou), posées bout à bout sur toute la terrasse.
    columns = int(round(deck.w() / ROOF_DECK_TILE))
    rows = int(round(deck.d() / ROOF_DECK_TILE_Z))
    for row in range(rows):
        for column in range(columns):
            x = deck.x0 + ROOF_DECK_TILE * (column + 0.5)
            z = deck.z0 + ROOF_DECK_TILE_Z * (row + 0.5)
            scale = ROOF_DECK_TILE_Z / ROOF_DECK_TILE
            instance = scene.res("PackedScene", scene_path("floor_roof_deck"), "p_floor_roof_deck")
            scene.node(unique("floor_roof_deck"), parent="Geometry/Terrasse", instance=instance,
                       props=[("transform", "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, %s, %s, 0, %s)"
                               % (num(scale), num(x), num(z)))])
    # (I2) Le bord du pan d'ardoise (roof_edge_slate, 4 × 1 m) au pied de l'égout sud du volume ouest, contre la
    # terrasse : deux modules bout à bout, de x = -5 à 3.
    for x in ROOF_EDGE_X:
        place("Geometry/VolumeOuest", "roof_edge_slate", x, 0.0, deck.z1)
    for image, x, z in ROOF_TREES:
        place("Geometry/Lisiere", image, x, -6.5, z)
    for image, x, z in ROOF_DETAILS:
        # Les taches de mousse (décalques) passent d'une couche : le sol de la terrasse reste dessous.
        place("Geometry/Terrasse", image, x, 0.0, z, 0.0, [("layer", "1")] if image.startswith("moss_") else [])
    markers_exits_life(scene, map_id, plan, [], exit_script)
    return scene


BUILDING_SCENE = """[gd_scene format=3]

[ext_resource type="Script" path="res://src/world/building.gd" id="1_building"]
[ext_resource type="Texture2D" path="res://assets/hd2d/buildings/materials/wall_planks.png" id="2_wall"]
[ext_resource type="Texture2D" path="res://assets/hd2d/buildings/materials/roof_slate.png" id="3_roof"]

[sub_resource type="BoxShape3D" id="BoxShape3D_1"]
size = Vector3(18, 10, 14)

[node name="entrepot_volume_ouest" type="Node3D"]
script = ExtResource("1_building")
wall_texture = ExtResource("2_wall")
roof_texture = ExtResource("3_roof")
footprint = Vector2(18.0, 14.0)
wall_height = 6.5
ridge_height = 10.0

[node name="Collision" type="StaticBody3D" parent="."]
collision_mask = 0

[node name="Shape1" type="CollisionShape3D" parent="Collision"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 5, 0)
shape = SubResource("BoxShape3D_1")
"""


# --- CARTE.md : liste des places --------------------------------------------------------------------


def places_markdown(map_id, plan):
    furniture = expand_furniture(plan) if map_id in INTERIOR_MAPS else []
    entries = places(map_id, plan, furniture)
    points = set(plan.points)
    zone_names = {z["name"] for z in life_zones.zones_of(map_id)}
    extra = [e for e in entries if e[0] not in points and e[0] not in zone_names]
    chairs = [e[0] for e in extra if "_chaise_" in e[0] and e[0][-2:].isdigit()]
    beds = [e[0] for e in extra if "_lit" in e[0]]
    others = [e[0] for e in extra if e[0] not in chairs and e[0] not in beds]
    lines = ["<!-- places:%s -->" % map_id,
             "**Places de la vie** (lots %s ; `Marker3D` de `Life/Places` dans la carte, pour E4 et E6) : "
             "les points nommés ci-dessus, à leur nom" % ("C2 et V1" if map_id in ("cafe", "maison_limashenka") else "T2 et V1")]
    if chairs:
        lines[-1] += " ; chaque chaise, `%s` à `%s` (rangées a à %s du nord au sud, numérotées d'ouest en " \
                     "est ; regard vers la table)" % (chairs[0], chairs[-1], chairs[-1].split("_")[-1][0])
    if beds:
        lines[-1] += " ; chaque lit (hauteur du dormeur : %s m, %s m en haut d'un lit superposé) : %s" % (
            ("%g" % life_zones.BED_HEIGHT).replace(".", ","), ("%g" % life_zones.BUNK_HEIGHT).replace(".", ","),
            ", ".join("`%s`" % b for b in beds))
    if others:
        lines[-1] += " ; et %s" % ", ".join("`%s`" % o for o in others)
    lines[-1] += "."
    zones = life_zones.zones_of(map_id)
    if zones:
        lines.append("")
        lines.append("**Zones et départs de la vie** (lot V1 ; un point enfant `p1`, `p2`… par case, regard au −Z ; "
                     "`vers_<carte>` : par où l'on part vers une carte, et d'où l'on en arrive) :")
        lines.append("")
        for entry in zones:
            count = len(entry["pts"])
            lines.append("- `%s`%s : %s" % (entry["name"], " (%d points)" % count if count else "", entry["why"]))
    lines.append("<!-- /places:%s -->" % map_id)
    return "\n".join(lines)


def cmd_places():
    with open(CARTE, encoding="utf-8") as handle:
        text = handle.read()
    all_plans = plans()
    for map_id in INTERIOR_MAPS + OUTDOOR_MAPS:
        block = places_markdown(map_id, all_plans[map_id])
        start = "<!-- places:%s -->" % map_id
        end = "<!-- /places:%s -->" % map_id
        if start in text:
            head, rest = text.split(start, 1)
            tail = rest.split(end, 1)[1]
            text = head + block + tail
            continue
        marker = "carte %s " % map_id
        at = text.index(marker)
        close = text.index("```\n", at) + 4
        text = text[:close] + "\n" + block + "\n" + text[close:]
    with open(CARTE, "w", encoding="utf-8") as handle:
        handle.write(text)
    print("CARTE.md : places des %d cartes de l'entrepôt" % len(INTERIOR_MAPS + OUTDOOR_MAPS))


# --- Commandes --------------------------------------------------------------------------------------


def generate(map_id, all_plans, write=True):
    plan = all_plans[map_id]
    settings = MAP_SETTINGS[map_id]
    outputs = {}
    deviations = []
    if map_id in INTERIOR_MAPS:
        data, deviations = interior_json(map_id, plan)
        for item in plan.furniture:
            turned = chosen_view(item.name, item.extra.get("regard", ""))[0] in ("side", "foot")
            if (item.name, 0) in MOVED and not turned:
                deviations.append("%s déplacé en z = %.3f (plan : %.3f)"
                                  % (item.name, MOVED[(item.name, 0)], (item.rect.z0 + item.rect.z1) / 2.0))
        outputs["data/maps/%s/interior.json" % map_id] = data
        scene = interior_scene(map_id, plan, settings)
    else:
        if write:
            roof_ground(map_id, plan)
        scene = roof_scene(map_id, plan, settings)
        outputs["src/world/props/interior/entrepot_volume_ouest.tscn"] = BUILDING_SCENE
    outputs["src/world/maps/%s/%s.tscn" % (map_id, map_id)] = scene.text()
    changed = []
    for rel, content in outputs.items():
        path = os.path.join(ROOT, rel)
        if isinstance(content, dict):
            content = json_text(content)
        old = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if old != content:
            changed.append(rel)
            if write:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "w", encoding="utf-8") as handle:
                    handle.write(content)
    return changed, deviations


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("gen", "places", "check"):
        print(__doc__)
        return 2
    if args[0] == "places":
        cmd_places()
        return 0
    all_plans = plans()
    ids = args[1:] or INTERIOR_MAPS + OUTDOOR_MAPS
    status = 0
    for map_id in ids:
        changed, deviations = generate(map_id, all_plans, write=args[0] == "gen")
        for line in deviations:
            print("%s : écart au plan, %s" % (map_id, line))
        if args[0] == "check" and changed:
            print("%s : à réécrire (%s)" % (map_id, ", ".join(changed)))
            status = 1
        elif args[0] == "gen":
            print("%s : %s" % (map_id, ", ".join(changed) if changed else "à jour"))
    return status


if __name__ == "__main__":
    sys.exit(main())
