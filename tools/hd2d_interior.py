#!/usr/bin/env python3
"""Intérieurs (lot E3) : images du lot I employées par les intérieurs (cahier n° 3,
docs/ASSETS_HD2D_SUKASUKA.md, section 3 ; conventions de docs/REFONTE.md, section 8.1), leurs
entrées du manifeste, les remplaçants des images que la livraison n'a pas encore et les scènes des
meubles. Guide : docs/INTERIEURS.md.

Les images vivent dans assets/hd2d/interior/ :
- sols floor_<matière> (384 × 384, 4 × 4 m, tile : sans raccord, vue de dessus) ;
- murs wall_<matière> (384 × 288, 4 × 3 m, tile_h : raccord à gauche et à droite, vue de face,
  corniche en haut, plinthe en bas) ;
- dessus de mur coupé wallcut_<matière> (384 × 24, 4 × 0,25 m, tile_h) ;
- portes door_*, fenêtres window_*, éléments de mur wallitem_* (panel, posés contre un mur par
  InteriorRoom d'après interior.json) ;
- meubles props/<nom> (panel, vue de face légèrement plongeante, scène InteriorPanel de
  src/world/props/<nom>.tscn) ;
et les tapis dans assets/hd2d/decals/ (decal à bord plein, scène GroundDecal).

Les vraies images (livrées) ne se redessinent jamais : seules celles de PLACEHOLDERS ont une
recette, et une vraie image du même nom les remplacera sans toucher au code.

Usage :

    python3 tools/hd2d_interior.py manifest   # met les entrées du lot I du manifeste à jour
    python3 tools/hd2d_assets.py gen --lot I  # dessine les remplaçants absents (recettes ci-dessous)
    python3 tools/hd2d_interior.py scenes     # écrit les scènes des meubles et des tapis
    python3 tools/hd2d_assets.py check --lot I

(T2) Les cartes de l'entrepôt (docs/lore/CARTE.md, section 3) ajoutent leurs images : meubles livrés
ou remplaçants (FURNITURE_T2), objets posés sur un meuble (OBJECTS : sans collision), décors du toit
en plein air (OUTDOOR : DecorPanel), la suspension du réfectoire (HANGING : DecorPanel de premier
plan, qui s'efface devant le joueur), bandes animées (ANIMS) et décalques (DECALS_T2). Leurs
remplaçants sont dans tools/hd2d_interior_props.py ; leurs scènes dans src/world/props/interior/
(celles d'E3 restent dans src/world/props/). Les cartes elles-mêmes s'écrivent par
tools/interior_maps.py.

Le résultat est déterministe (graine tirée du nom de chaque image).
"""

import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from hd2d_art import (  # noqa: E402
    Canvas, WrapCanvas, darker, fractal, mix, noise, paste_wrap, posterize, ramp, rgba, threshold)
import hd2d_interior_props  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "hd2d_manifest.json")
PROPS_DIR = os.path.join(ROOT, "src", "world", "props")
# (T2) Scènes des images ajoutées par les cartes de l'entrepôt.
T2_PROPS_DIR = os.path.join(PROPS_DIR, "interior")
PPM = 96
LOT = "I"
# Meuble plaqué au mur (emprise de moins de 0,3 m, comme le grand miroir) : coupé comme le mur
# (InteriorRoom.CUT_HEIGHT), sinon ce qu'il garde de haut cacherait le joueur de l'autre côté.
WALL_MOUNTED = 0.3
WALL_CUT_HEIGHT = 0.15

DARK = "wood_dark"
HONEY = "#B08458"
IRON = "iron"
BRASS = "brass"

# --- Liste des images (nom, taille en px, priorité du cahier n° 3) ---------------------------------

# Matières (assets/hd2d/interior/) : (nom, taille, genre, priorité).
SURFACES = [
    ("floor_planks_worn", (384, 384), "tile", 1),
    ("floor_planks_dark", (384, 384), "tile", 1),
    ("floor_tiles_bath", (384, 384), "tile", 1),
    ("floor_flagstone_cellar", (384, 384), "tile", 2),
    ("floor_kitchen_tiles", (384, 384), "tile", 1),
    ("wall_plaster_worn", (384, 288), "tile_h", 1),
    ("wall_wainscot", (384, 288), "tile_h", 1),
    ("wall_wallpaper_faded", (384, 288), "tile_h", 1),
    ("wall_kitchen_tiles", (384, 288), "tile_h", 1),
    ("wall_cellar_stone", (384, 288), "tile_h", 2),
    ("wallcut_wood", (384, 24), "tile_h", 1),
    ("wallcut_stone", (384, 24), "tile_h", 2),
]

# Portes, fenêtres et éléments de mur (assets/hd2d/interior/, panel) : (nom, taille, priorité).
WALL_PANELS = [
    ("door_frame_wood", (126, 221), 1),
    ("door_room", (106, 211), 1),
    ("door_double", (192, 230), 1),
    ("door_armory", (125, 221), 2),
    ("window_cross_small", (77, 96), 1),
    ("window_cross_large", (230, 173), 1),
    ("window_reading_seat", (192, 211), 1),
    ("wallitem_chore_chart", (96, 72), 1),
    ("wallitem_notice_a", (34, 43), 1),
    ("wallitem_notice_b", (34, 43), 1),
    ("wallitem_coat_hooks", (115, 106), 1),
    ("wallitem_menu_board", (77, 96), 1),
    ("wallitem_height_marks", (38, 154), 2),
    ("wallitem_utensils", (115, 77), 1),
    ("wallitem_bronze_plaque", (48, 19), 1),
    ("wallitem_wall_clock", (48, 106), 1),
    ("wallitem_day_calendar", (29, 38), 1),
    ("wallitem_bath_rules", (38, 53), 1),
    ("wallitem_wall_lamp", (29, 43), 1),
]

# Meubles (assets/hd2d/interior/props/, panel) : (nom, taille, profondeur de l'emprise au sol en m
# vers le nord depuis l'image, lueur des pixels couleur cristal, priorité). Les panneaux touchent
# le bord bas de leur image (ancre au sol). Au milieu d'une pièce, un meuble de hauteur h a une
# emprise d'au moins (h − 0,25) / 0,78 − 0,35 m (docs/INTERIEURS.md, « Meubler »).
FURNITURE = [
    ("dining_table_long", (384, 106), 1.0, 0.0, 1),
    ("dining_table_set", (384, 115), 1.0, 0.0, 1),
    ("chair_wood", (48, 96), 0.65, 0.0, 1),
    ("chair_wood_back", (48, 96), 0.65, 0.0, 1),
    ("china_cabinet", (154, 211), 0.55, 0.0, 1),
    ("sink_stone", (134, 101), 0.65, 0.0, 1),
    ("crystal_stove", (134, 115), 0.75, 1.4, 1),
    ("kitchen_counter", (192, 101), 0.65, 0.0, 1),
    ("kitchen_table_ingredients", (154, 106), 0.9, 0.0, 1),
    ("water_tub", (96, 86), 0.7, 0.0, 1),
    ("bookshelf_tall", (154, 221), 0.45, 0.0, 1),
    ("bookshelf_low", (134, 86), 0.5, 0.0, 1),
    ("reading_table", (173, 91), 0.9, 1.0, 1),
    ("archive_shelves", (192, 230), 0.55, 0.0, 1),
    ("desk_buried", (134, 125), 1.05, 0.0, 1),
    ("sofa_beige", (192, 86), 0.9, 0.0, 1),
    ("paper_pile_a", (115, 134), 1.15, 0.0, 1),
    ("paper_pile_b", (77, 86), 0.6, 0.0, 1),
    ("paper_pile_c", (58, 48), 0.45, 0.0, 1),
    ("washstand_corridor", (173, 110), 0.6, 0.0, 1),
    ("shoe_rack", (115, 58), 0.4, 0.0, 1),
    ("bath_tub", (230, 96), 1.0, 0.0, 1),
    ("mirror_large", (115, 202), 0.12, 0.0, 1),
    ("towel_shelf", (96, 154), 0.4, 0.0, 1),
    ("wash_tub", (77, 48), 0.5, 0.0, 1),
    ("bed_iron", (192, 101), 1.0, 0.0, 1),
    ("bedside_table", (48, 67), 0.45, 0.0, 1),
    ("medicine_cabinet", (96, 173), 0.4, 0.0, 1),
    ("infirmary_desk", (125, 96), 0.75, 1.0, 1),
    ("chair_child", (43, 77), 0.45, 0.0, 1),
    ("board_games_shelf", (115, 154), 0.4, 0.0, 1),
    ("toy_chest", (96, 77), 0.6, 0.0, 1),
    ("plush_pile", (96, 58), 0.6, 0.0, 1),
    ("plush_blue", (48, 48), 0.4, 0.0, 1),
    ("game_table", (115, 58), 0.6, 0.0, 1),
    ("fireplace", (154, 134), 0.6, 0.0, 1),
    ("tea_table", (86, 77), 0.7, 0.0, 1),
    ("chair_guest", (77, 101), 0.7, 0.0, 1),
    ("desk_nygglatho", (134, 106), 0.8, 0.0, 1),
    ("comm_crystal", (67, 134), 0.4, 0.0, 1),
    ("bed_nygglatho", (202, 106), 1.1, 0.0, 1),
    ("shelf_nygglatho", (115, 173), 0.4, 0.0, 1),
]

# Tapis (assets/hd2d/decals/, decal à bord plein) : (nom, taille, priorité, bord que touche l'image
# livrée : solid_edge du manifeste).
RUGS = [
    ("rug_playroom", (384, 288), 1, ""),
    ("rug_brown", (192, 115), 1, "bottom"),
]

# --- (T2) Cartes de l'entrepôt (docs/lore/CARTE.md, section 3) -----------------------------------

# Portes, fenêtres et éléments de mur ajoutés : (nom, taille, priorité). Remplaçants (sauf
# wallitem_calendar, livré) : tools/hd2d_interior_props.py.
WALL_PANELS_T2 = [
    ("door_service", (96, 211), 2),
    ("door_armory_inside", (125, 221), 2),
    ("window_curtains_open", (115, 154), 2),
    ("window_curtains_closed", (115, 154), 2),
    ("window_bare", (106, 134), 2),
    ("window_dusty", (96, 96), 3),
    ("wallitem_calendar", (38, 48), 1),
    ("wallitem_notices_mix", (77, 58), 2),
    ("wallitem_frame_landscape", (58, 48), 2),
    ("wallitem_crystal_sconce", (29, 48), 2),
    ("wallitem_spice_shelf", (115, 67), 2),
    ("wallitem_apron_hook", (38, 86), 2),
    ("wallitem_clippings", (77, 58), 3),
    ("wallitem_labcoat", (48, 106), 2),
    ("wallitem_kids_drawings", (115, 58), 2),
    ("wallitem_cobweb", (48, 48), 2),
]

# Meubles ajoutés (assets/hd2d/interior/props/ ; InteriorPanel) : (nom, taille, profondeur de
# l'emprise (m) : celle des plans de CARTE.md, lueur, priorité). Livrés : bed_*, dresser_child,
# wardrobe_*, desk_chtholly, crypt_pillar, sword_rack_*, swords_wrapped, stairs_up, ball_white ;
# les autres sont des remplaçants. roof_ladder n'est pas au cahier (CARTE.md 12.1).
FURNITURE_T2 = [
    ("bed_child", (154, 77), 0.8, 0.0, 1),
    ("bed_child_messy", (154, 86), 0.9, 0.0, 1),
    ("bed_chtholly", (192, 91), 0.95, 0.0, 1),
    ("bed_plain", (192, 91), 0.95, 0.0, 1),
    ("dresser_child", (86, 86), 0.5, 0.0, 1),
    ("wardrobe_plain", (96, 192), 0.6, 0.0, 1),
    ("wardrobe_chtholly", (96, 192), 0.6, 0.0, 1),
    ("desk_chtholly", (106, 101), 0.6, 0.0, 1),
    ("sword_rack_a", (384, 182), 0.6, 0.0, 1),
    ("sword_rack_b", (384, 182), 0.6, 0.0, 1),
    ("swords_wrapped", (154, 154), 0.8, 0.0, 1),
    ("stairs_up", (154, 288), 3.0, 0.0, 1),
    ("pantry_cupboard", (106, 192), 0.6, 0.0, 2),
    ("sacks_vegetables", (115, 67), 0.7, 0.0, 2),
    ("filing_cabinet", (96, 134), 0.5, 0.0, 2),
    ("bookshelf_tall_b", (154, 221), 0.6, 0.0, 2),
    ("armchair_reading", (96, 101), 0.9, 0.0, 2),
    ("book_pile", (48, 48), 0.5, 0.0, 2),
    ("supply_cupboard", (96, 192), 0.5, 0.0, 2),
    # Plus profond que l'image (0,4 m) : au milieu du placard, on ne se tient pas juste derrière
    # ce qui dépasse 1,2 m (règle de caméra, CARTE.md 0.3).
    ("cleaning_set", (67, 134), 1.1, 0.0, 2),
    ("hamper", (58, 67), 0.5, 0.0, 2),
    ("piano_old", (154, 134), 0.7, 0.0, 3),
    ("floor_cushions", (115, 38), 0.4, 0.0, 2),
    ("washbasin_stand", (58, 96), 0.5, 0.0, 2),
    ("bunk_bed", (173, 182), 0.9, 0.0, 2),
    ("clothes_chest", (86, 58), 0.5, 0.0, 2),
    ("desk_clean_brooch", (106, 101), 0.6, 0.0, 2),
    ("footlocker", (77, 48), 0.5, 0.0, 2),
    ("leak_bucket", (48, 43), 0.45, 0.0, 2),
    ("repair_planks", (67, 173), 0.3, 0.0, 2),
    ("roof_ladder", (77, 288), 0.9, 0.0, 2),
    ("stairs_down", (154, 106), 3.0, 0.0, 2),
    ("crypt_stairs", (154, 240), 2.5, 0.0, 2),
    ("talisman_chest", (77, 58), 0.6, 0.0, 2),
]

# Meuble dont l'image n'est pas dans props/ : la fenêtre à banc, que le plan pose en meuble
# (emprise de 0,8 m) ; son entrée de manifeste est celle d'E3 (WALL_PANELS).
FURNITURE_OTHER_IMAGES = [
    ("window_reading_seat", "assets/hd2d/interior/window_reading_seat.png", (192, 211), 0.8, 0.0),
    # La porte rivetée vue de la crypte, plaquée au mur nord en haut des marches (« mural » du plan).
    ("door_armory_inside", "assets/hd2d/interior/door_armory_inside.png", (125, 221), 0.1, 0.0),
]

# Objets posés sur un meuble (« objet » des plans) ou par terre sans collision (« libre » : la balle
# blanche) : InteriorPanel sans collision ni ombre, posé à la hauteur du plateau ; (nom, taille,
# lueur, priorité).
OBJECTS = [
    ("meal_lunch", (96, 29), 0.0, 1),
    ("ball_white", (19, 19), 0.0, 1),
    ("tableware_a", (96, 29), 0.0, 1),
    ("crystal_lamp_table", (29, 48), 1.5, 2),
    ("coffee_tray", (48, 24), 0.0, 2),
    ("vase_flowers", (24, 38), 0.0, 2),
    ("oil_lamp", (24, 38), 1.2, 2),
    ("tea_tray_cheesecake", (58, 29), 0.0, 2),
]
# Hauteur au-delà de laquelle une image n'est plus un « objet posé » (m).
OBJECT_MAX_HEIGHT = 0.6

# Décors du toit en plein air (carte entrepot_toit, sol MapGround) : DecorPanel éclairé comme le
# dehors ; (nom, taille, priorité, boîte de collision (largeur, hauteur, profondeur) ou None).
OUTDOOR = [
    ("roof_railing", (192, 77), 1, (2.0, 0.8, 0.3)),
    ("roof_railing_broken", (192, 77), 2, (2.0, 0.8, 0.3)),
    ("roof_hatch", (96, 58), 2, (1.0, 0.6, 0.6)),
]

# Meubles hauts et minces au milieu d'une pièce, où l'on passe derrière : DecorPanel de premier
# plan (comme les grands arbres au milieu des passages, CARTE.md 0.3), qui s'efface autour du
# joueur ; image au bord sud de l'emprise, collision sur l'emprise ; (nom, taille, priorité,
# emprise (largeur, profondeur)).
FOREGROUND = [
    ("crypt_pillar", (58, 288), 1, (0.6, 0.6)),
]

# Suspendu (ancre libre, le haut de l'image au plafond) : DecorPanel de premier plan, qui s'efface
# autour du joueur quand il passe derrière ; (nom, taille, lueur, priorité).
HANGING = [
    ("crystal_pendant", (77, 134), 1.6, 2),
]

# Bandes animées (assets/hd2d/anim/, DecorPanel animé) : (nom, taille d'une image, images, ips,
# priorité, alpha doux, ancre libre, lueur). hearth_fire est livrée ; drying_frame_wave part du
# séchoir livré (drying_frame).
ANIMS = [
    ("hearth_fire", (77, 48), 6, 10, 1, False, False, 1.4),
    ("pot_steam", (48, 96), 6, 8, 2, True, False, 0.0),
    ("leak_drip", (24, 96), 4, 8, 2, False, True, 0.0),
    ("drying_frame_wave", (384, 211), 4, 4, 2, False, False, 0.0),
]
# Collision des poteaux du séchoir (cylindres de 0,1 m à ± POLE_X m), comme laundry_wave.
DRYING_POLE_X = 1.85

# Décalques (assets/hd2d/decals/, GroundDecal) : (nom, taille, priorité, raccord, alpha doux).
DECALS_T2 = [
    ("runner_rug", (96, 384), 2, "y", False),
    ("papers_floor", (192, 144), 2, "", False),
    ("bath_puddles", (192, 144), 2, "", True),
    ("cards_floor", (144, 96), 2, "", False),
    ("clothes_floor", (192, 144), 2, "", False),
]

# --- (I1) Images livrées après coup (docs/ASSETS_HD2D_COMPLEMENTS.md, ASSETS_HD2D_NAVIRES.md, lots N et
# I priorité 2) ---------------------------------------------------------------------------------------
#
# Chaque livraison arrive sur main par une PR d'images seules ; ces listes les inscrivent au manifeste
# (taille réelle, genre, lot du cahier d'origine) et leur donnent leurs scènes. Aucune n'a de
# recette : le fichier livré fait foi, et ces listes ne le redessinent jamais. Le lot de chaque image
# est LOT_OF (défaut : I) ; le manifeste le porte, `check --lot <lot>` le filtre.

# Lots du cahier n° 4 (O1, O2, P, Q), des navires (L : conseil, coursive, pont ; S1 à S5 : pièces de
# bord) et du lot N (temps et lumière : fenêtres de nuit).
LOT_NAMES = {
    "O1": ["flour_sack_open", "egg_basket_low", "milk_jug_stoneware", "butter_dish_open", "mixing_bowl_whisk",
           "flan_mould_empty"],
    "O2": ["repair_nail_box", "hand_plane_worn", "hand_saw_short", "mending_basket", "thread_spools_pair",
           "patched_cloth_folded"],
    "P": ["book_open_stand", "inkwell_quill", "letter_sealed_bundle", "bandage_rolls", "medicine_bottles_tray",
          "compress_bowl"],
    "Q": ["field_satchel_set_down", "leather_canteen", "oilskin_cloak_folded", "walking_boots_drying",
          "provisions_cloth_bundle"],
    "L": ["floor_ship_planks", "wall_ship_plate", "wallcut_ship", "war_table", "war_chair", "tea_set_tiny",
          "window_porthole", "door_bulkhead", "ship_ladder", "wallitem_ship_pipes", "wallitem_garde_emblem",
          "map_cabinet", "wallitem_speaking_tube"],
    "S1": ["ship_helm", "ship_engine_telegraph", "ship_navigation_desk", "ship_compass", "ship_pilot_chair",
           "ship_cockpit_window"],
    "S2": ["ship_bunk", "ship_locker", "ship_folding_table", "ship_wall_bench", "ship_hammock", "ship_washstand"],
    "S3": ["ship_boiler", "ship_motor", "ship_fuel_bin", "ship_tool_rack", "ship_workbench", "ship_pressure_tank"],
    "S4": ["ship_medical_cot", "ship_medical_cabinet", "ship_mess_counter", "ship_mess_bench", "ship_water_can",
           "ship_crystal_lamp"],
    "S5": ["ship_latrine", "ship_privacy_curtain", "ship_cargo_trolley", "ship_sword_rack", "floor_ship_grating",
           "ceiling_ship_plate"],
    "N": ["window_cross_small_night", "window_cross_large_night", "window_reading_seat_night"],
}
LOT_OF = {name: lot for lot, names in LOT_NAMES.items() for name in names}

# Matières livrées (assets/hd2d/interior/) : (nom, taille, genre, priorité). Le plafond de tôle est
# fourni pour réutilisation : le moteur ne l'affiche pas encore (NAVIRES.md).
SURFACES_I1 = [
    ("floor_ship_planks", (384, 384), "tile", 2),
    ("floor_ship_grating", (384, 384), "tile", 3),
    ("ceiling_ship_plate", (384, 384), "tile", 3),
    ("wall_ship_plate", (384, 288), "tile_h", 2),
    ("wallcut_ship", (384, 24), "tile_h", 2),
]

# Portes, fenêtres et éléments de mur livrés : (nom, taille, priorité). Les fenêtres de nuit
# (<nom>_night, lot N) n'ont pas de scène : HD2DLightTargets les échange avec celles de jour la nuit.
WALL_PANELS_I1 = [
    ("door_room_open", (106, 211), 1),
    ("door_bulkhead", (106, 211), 2),
    ("window_porthole", (58, 58), 2),
    ("ship_cockpit_window", (230, 96), 2),
    ("wallitem_garde_emblem", (77, 77), 2),
    ("wallitem_ship_pipes", (192, 96), 2),
    ("wallitem_speaking_tube", (29, 58), 2),
    ("window_cross_small_night", (77, 96), 1),
    ("window_cross_large_night", (230, 173), 1),
    ("window_reading_seat_night", (192, 211), 1),
]

# Meubles livrés (assets/hd2d/interior/props/ ; InteriorPanel) : (nom, taille, profondeur de
# l'emprise (m), lueur, priorité). Profondeurs : celles d'un meuble de cette taille, le cahier ne les
# donne pas (docs/DECISIONS.md, I1). ship_tool_rack et ship_privacy_curtain, plaqués au mur ou sur
# rail, sont minces (moins de 0,3 m : coupés comme le mur).
FURNITURE_I1 = [
    ("bed_curtain", (154, 202), 0.2, 0.0, 2),
    ("towel_rack", (96, 106), 0.35, 0.0, 2),
    ("map_cabinet", (115, 106), 0.6, 0.0, 2),
    ("war_table", (192, 106), 0.9, 0.0, 2),
    ("war_chair", (58, 106), 0.55, 0.0, 2),
    ("ship_ladder", (96, 288), 0.6, 0.0, 2),
    ("ship_helm", (77, 96), 0.6, 0.0, 2),
    ("ship_engine_telegraph", (48, 115), 0.4, 0.0, 2),
    ("ship_navigation_desk", (154, 106), 0.8, 0.0, 2),
    ("ship_pilot_chair", (58, 106), 0.6, 0.0, 2),
    ("ship_bunk", (192, 173), 0.9, 0.0, 3),
    ("ship_locker", (77, 182), 0.5, 0.0, 3),
    ("ship_folding_table", (115, 86), 0.7, 0.0, 3),
    ("ship_wall_bench", (154, 58), 0.45, 0.0, 3),
    ("ship_hammock", (192, 77), 0.5, 0.0, 3),
    ("ship_washstand", (77, 86), 0.5, 0.0, 3),
    ("ship_boiler", (154, 211), 1.0, 0.8, 3),
    ("ship_motor", (154, 134), 0.8, 0.0, 3),
    ("ship_fuel_bin", (96, 106), 0.7, 0.0, 3),
    ("ship_tool_rack", (154, 96), 0.15, 0.0, 3),
    ("ship_workbench", (192, 106), 0.8, 0.0, 3),
    ("ship_pressure_tank", (77, 134), 0.7, 0.0, 3),
    ("ship_medical_cot", (192, 86), 0.9, 0.0, 3),
    ("ship_medical_cabinet", (77, 134), 0.45, 0.0, 3),
    ("ship_mess_counter", (192, 115), 0.6, 0.0, 3),
    ("ship_mess_bench", (154, 58), 0.4, 0.0, 3),
    ("ship_water_can", (48, 58), 0.4, 0.0, 3),
    ("ship_latrine", (77, 96), 0.7, 0.0, 3),
    ("ship_privacy_curtain", (96, 173), 0.15, 0.0, 3),
    ("ship_cargo_trolley", (154, 106), 0.8, 0.0, 3),
    ("ship_sword_rack", (154, 154), 0.5, 0.0, 3),
]

# Objets livrés, posés sur un meuble (ou par terre : sacoche, bottes) : (nom, taille, lueur,
# priorité) ; InteriorPanel sans collision ni ombre, de 0,6 m de haut au plus.
OBJECTS_I1 = [
    ("butter_cake", (58, 34), 0.0, 2),
    ("dessert_flans", (77, 24), 0.0, 1),
    ("hat_blue", (48, 24), 0.0, 2),
    ("tea_set_tiny", (48, 24), 0.0, 2),
    ("ship_compass", (34, 38), 0.0, 2),
    ("ship_crystal_lamp", (38, 58), 1.2, 3),
    ("flour_sack_open", (48, 58), 0.0, 1),
    ("egg_basket_low", (58, 34), 0.0, 1),
    ("milk_jug_stoneware", (29, 43), 0.0, 1),
    ("butter_dish_open", (34, 19), 0.0, 1),
    ("mixing_bowl_whisk", (48, 29), 0.0, 1),
    ("flan_mould_empty", (38, 24), 0.0, 1),
    ("repair_nail_box", (34, 24), 0.0, 2),
    ("hand_plane_worn", (38, 19), 0.0, 2),
    ("hand_saw_short", (58, 24), 0.0, 2),
    ("mending_basket", (48, 34), 0.0, 2),
    ("thread_spools_pair", (24, 19), 0.0, 2),
    ("patched_cloth_folded", (38, 14), 0.0, 2),
    ("book_open_stand", (48, 48), 0.0, 2),
    ("inkwell_quill", (29, 34), 0.0, 2),
    ("letter_sealed_bundle", (34, 14), 0.0, 2),
    ("bandage_rolls", (34, 19), 0.0, 2),
    ("medicine_bottles_tray", (48, 34), 0.0, 2),
    ("compress_bowl", (34, 24), 0.0, 2),
    ("field_satchel_set_down", (48, 48), 0.0, 3),
    ("leather_canteen", (29, 38), 0.0, 3),
    ("oilskin_cloak_folded", (58, 24), 0.0, 3),
    ("walking_boots_drying", (48, 43), 0.0, 3),
    ("provisions_cloth_bundle", (48, 29), 0.0, 3),
]

# Le séchoir livré (le linge fixe ; sa bande animée est drying_frame_wave), en plein air : deux
# poteaux qui bloquent, comme la bande animée ; (nom, taille, priorité).
OUTDOOR_POLES = [
    ("drying_frame", (384, 211), 1),
]

# Tous les meubles, objets et décors de plein air des cartes : listes d'E3, de T2 et d'I1.
ALL_FURNITURE = FURNITURE + FURNITURE_T2 + FURNITURE_I1
ALL_OBJECTS = OBJECTS + OBJECTS_I1

# Remplaçants : images du lot I absentes de la livraison. door_frame_wood (chambranle seul, ouverture
# transparente, pour les portes qu'on franchit) n'est pas encore au cahier n° 3 :
# docs/CONTRACT_REQUESTS.md.
PLACEHOLDERS = [
    "floor_flagstone_cellar",
    "wall_cellar_stone",
    "wallcut_stone",
    "door_frame_wood",
    "wallitem_height_marks",
]


def entries():
    """Entrées du manifeste des images d'intérieur, dans l'ordre : le lot I (E3, T2), puis les images
    livrées après coup (I1 : lots L, S1 à S5, O1, O2, P, Q, N, et les vues de flanc, de dos et de
    pied qui existent)."""
    out = []
    for name, size, kind, prio in SURFACES + SURFACES_I1:
        out.append(_entry("interior/" + name, size, kind, prio, name))
    for name, size, prio in WALL_PANELS + WALL_PANELS_T2 + WALL_PANELS_I1:
        out.append(_entry("interior/" + name, size, "panel", prio, name))
    for name, size, _depth, _glow, prio in ALL_FURNITURE:
        out.append(_entry("interior/props/" + name, size, "panel", prio, name))
    for name, size, _glow, prio in ALL_OBJECTS:
        out.append(_entry("interior/props/" + name, size, "panel", prio, name))
    for name, size, prio, _box in OUTDOOR:
        out.append(_entry("interior/props/" + name, size, "panel", prio, name))
    for name, size, prio in OUTDOOR_POLES:
        out.append(_entry("interior/props/" + name, size, "panel", prio, name))
    for name, size, prio, _footprint in FOREGROUND:
        out.append(_entry("interior/props/" + name, size, "panel", prio, name))
    for name, size, _glow, prio in HANGING:
        entry = _entry("interior/props/" + name, size, "panel", prio, name)
        entry["anchor"] = "free"
        out.append(entry)
    for name, size, prio, solid in RUGS:
        entry = _entry("decals/" + name, size, "decal", prio, name)
        if solid:
            entry["solid_edge"] = solid
        out.append(entry)
    for name, size, prio, wrap, soft in DECALS_T2:
        entry = _entry("decals/" + name, size, "decal", prio, name)
        if wrap:
            entry["wrap"] = wrap
        if soft:
            entry["soft_alpha"] = True
        out.append(entry)
    for name, size, frames, fps, prio, soft, free, _glow in ANIMS:
        entry = _entry("anim/" + name, size, "anim", prio, name)
        entry["frames"] = frames
        entry["fps"] = fps
        if soft:
            entry["soft_alpha"] = True
        if free:
            entry["anchor"] = "free"
        out.append(entry)
    return out


def _entry(key, size, kind, prio, name=""):
    lot = LOT_OF.get(name or os.path.basename(key), LOT)
    return {"path": "assets/hd2d/%s.png" % key, "size": list(size), "kind": kind, "prio": prio, "lot": lot}


# --- Remplaçants : sols et murs de pierre -----------------------------------------------------------


def floor_flagstone_cellar(size, rnd):
    w, h = size
    img = posterize(fractal(size, (8, 8), rnd, 2), ramp("#4A443E", 4)[0:3], dither=40)
    y = 0
    rows = [64, 64, 64, 64, 64, 64]
    for rh in rows:
        widths = []
        while sum(widths) < w:
            widths.append(rnd.randint(52, 96))
        widths[-1] -= sum(widths) - w
        if widths[-1] < 40:
            widths[-2] += widths.pop()
        x = rnd.randrange(w)
        for sw in widths:
            base = mix("#8A8076", rnd.choice(["#6E6A66", "#9A8C78", "#7A7468", "#8E8478"]), rnd.uniform(0.2, 0.6))
            tones = ramp(base, 5, spread=0.38)
            c = Canvas(sw, rh, rnd)
            c.rect(2, 2, sw - 2, rh - 2, tones[2])
            pat = posterize(noise((sw - 6, rh - 6), (3, 3), rnd), tones[1:4], dither=50)
            c.img.paste(pat, (3, 3))
            c.rect(2, 2, sw - 2, 4, tones[4])
            c.rect(2, 2, 4, rh - 2, tones[3])
            c.rect(2, rh - 4, sw - 2, rh - 2, tones[0])
            c.rect(sw - 4, 2, sw - 2, rh - 2, tones[0])
            for _ in range(rnd.randint(0, 2)):
                cx, cy = rnd.uniform(8, sw - 8), rnd.uniform(8, rh - 8)
                c.line([(cx, cy), (cx + rnd.uniform(-10, 10), cy + rnd.uniform(4, 14))], tones[0])
            paste_wrap(img, c.img, x % w, y)
            x += sw
        y += rh
    # Humidité : taches sombres et un peu de mousse dans les joints.
    damp = fractal(size, (3, 3), rnd, 2).point(lambda v: max(0, int((v - 140) * 1.8)))
    img.paste(Image.blend(img, Image.new("RGBA", size, rgba("#2E2C2A")), 0.4), (0, 0), damp)
    moss = threshold(fractal(size, (12, 12), rnd, 2), 215)
    img.paste(Image.new("RGBA", size, rgba("#4C5A3C")), (0, 0), moss)
    return img


def wall_cellar_stone(size, rnd):
    w, h = size
    img = Image.new("RGBA", size, rgba("#3A3430"))
    c = WrapCanvas(w, h, rnd)
    c.img = img
    c.draw = ImageDraw.Draw(c.img)
    courses = [26, 40, 38, 42, 36, 40, 34]
    y = 0
    for i, ch in enumerate(courses):
        x = rnd.uniform(0, 40)
        while x < w:
            sw = rnd.uniform(40, 86)
            if i == 0:
                base = "#6E6258"
            elif i == len(courses) - 1:
                base = "#4E4640"
            else:
                base = mix("#7A7066", rnd.choice(["#6A645E", "#8A7C6C", "#5E5852"]), rnd.uniform(0.2, 0.6))
            tones = ramp(base, 5, spread=0.38)
            c.rect(x + 2, y + 2, x + sw - 2, y + ch - 2, tones[2])
            c.rect(x + 2, y + 2, x + sw - 2, y + 4, tones[4])
            c.rect(x + 2, y + 2, x + 4, y + ch - 2, tones[3])
            c.rect(x + 2, y + ch - 4, x + sw - 2, y + ch - 2, tones[0])
            for _ in range(3):
                px, py = rnd.uniform(x + 6, x + sw - 6), rnd.uniform(y + 6, y + ch - 6)
                c.rect(px, py, px + 2, py + 1, tones[rnd.choice([1, 3])])
            x += sw
        y += ch
    damp = Image.linear_gradient("L").resize(size).point(lambda v: max(0, int((v - 120) * 0.9)))
    c.img.paste(Image.blend(c.img, Image.new("RGBA", size, rgba("#1E1C1A")), 0.45), (0, 0), damp)
    return c.img


def wallcut_stone(size, rnd):
    w, h = size
    c = WrapCanvas(w, h, rnd)
    c.rect(0, 0, w, h, "#3A3430")
    x = 0
    while x < w:
        sw = rnd.choice([32, 48, 48, 64])
        sw = min(sw, w - x)
        tones = ramp(mix("#7A7066", rnd.choice(["#6A645E", "#8A7C6C"]), 0.4), 4, spread=0.35)
        c.rect(x + 1, 1, x + sw - 1, h - 1, tones[2])
        c.rect(x + 1, 1, x + sw - 1, 3, tones[3])
        c.rect(x + 1, h - 3, x + sw - 1, h - 1, tones[0])
        x += sw
    return c.img


# --- Remplaçants : portes et éléments de mur ----------------------------------------------------------


def _frame(c, w, h, jamb, lintel, base, sill=0):
    """Chambranle : montants et linteau moulurés."""
    tones = ramp(base, 5, spread=0.42)
    c.rect(0, 0, w, lintel, tones[2])
    c.rect(0, 0, w, 2, tones[4])
    c.rect(0, lintel - 2, w, lintel, tones[0])
    for x0 in (0, w - jamb):
        c.rect(x0, 0, x0 + jamb, h - sill, tones[2])
        c.rect(x0, lintel, x0 + 2, h - sill, tones[4] if x0 == 0 else tones[3])
        c.rect(x0 + jamb - 2, lintel, x0 + jamb, h - sill, tones[1])
    return tones


def door_frame_wood(size, rnd):
    w, h = size
    c = Canvas(w, h, rnd)
    _frame(c, w, h, 10, 10, DARK)
    # Seuil de bois usé entre les deux montants.
    c.rect(10, h - 4, w - 10, h, ramp(HONEY, 4)[1])
    c.rect(10, h - 4, w - 10, h - 3, ramp(HONEY, 4)[3])
    return c.finish(darker(DARK, 0.5))


def wallitem_height_marks(size, rnd):
    """Marques de taille sur le plâtre : traits entre 0,9 et 1,5 m, un signe à côté de chacun."""
    w, h = size
    c = Canvas(w, h, rnd)
    plaster = ramp("#E6DAC2", 4, spread=0.2)
    # Fond transparent : seuls les traits et les signes, posés sur une bande de plâtre éclaircie.
    c.rect(w * 0.3, 0, w * 0.7, h, plaster[2])
    c.rect(w * 0.3, 0, w * 0.34, h, plaster[3])
    colors = ["#B5443A", "#4E7A9A", "#5A8A50", "#C88A3A", "#8A5AA0", "#6C625A"]
    top, bottom = h - 1.5 * PPM, h - 0.9 * PPM
    levels = sorted(rnd.uniform(top, bottom) for _ in range(9))
    levels.append(levels[3] + 2)
    for k, y in enumerate(levels):
        col = colors[k % len(colors)]
        c.rect(w * 0.3, y, w * 0.7, y + 1, col)
        sx = 2 if k % 2 == 0 else w * 0.7 + 2
        sign = k % 4
        if sign == 0:
            c.rect(sx + 2, y - 4, sx + 3, y + 3, col)
            c.rect(sx, y - 1, sx + 5, y, col)
        elif sign == 1:
            c.ellipse(sx + 3, y - 1, 2, 2, col)
        elif sign == 2:
            c.poly([(sx, y - 3), (sx + 6, y - 3), (sx + 3, y + 2)], col)
        else:
            c.line([(sx, y + 3), (sx + 6, y - 4)], col)
    c.rect(w * 0.3, h - 3, w * 0.7, h, darker("#E6DAC2", 0.7))
    return c.finish(darker(HONEY, 0.45))


RECIPES = {"interior/" + _name: globals()[_name] for _name in PLACEHOLDERS}
RECIPES.update(hd2d_interior_props.RECIPES)


# --- Manifeste et scènes ------------------------------------------------------------------------------


def cmd_manifest():
    """Remplace les entrées du lot I du manifeste, et celles des images d'intérieur des autres lots
    (I1 : navires, cahier n° 4, fenêtres de nuit), par celles d'entries(), à la fin de la liste des
    images (une par ligne)."""
    with open(MANIFEST, encoding="utf-8") as handle:
        text = handle.read()
    marker = "\n ],\n \"sheets\""
    head, tail = text[:text.index(marker)], text[text.index(marker):]
    lines = head.split("\n")
    managed = ['"path": "%s"' % entry["path"] for entry in entries()]
    kept = [line for line in lines if '"lot": "%s"' % LOT not in line and not any(m in line for m in managed)]
    if kept[-1].endswith(","):
        kept[-1] = kept[-1][:-1]
    new = "\n".join(kept) + "".join(",\n  " + json.dumps(e, ensure_ascii=False) for e in entries()) + tail
    json.loads(new)
    if new == text:
        print("manifeste à jour (%d images du lot %s)" % (len(entries()), LOT))
        return 0
    with open(MANIFEST, "w", encoding="utf-8") as handle:
        handle.write(new)
    print("manifeste : %d images du lot %s (%d entrée(s) retirée(s))"
          % (len(entries()), LOT, len(lines) - len(kept)))
    return 0


def _vec(*values):
    return ", ".join(_num(v) for v in values)


def _num(value):
    text = ("%.4f" % value).rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def furniture_scene(name, size, depth, glow_amount, image="", node_name=""):
    """Texte de la scène d'un meuble : InteriorPanel posé au milieu de son emprise (l'image au bord
    sud, image_offset), ombre sur l'emprise, boîte de collision (couche 1) sur l'emprise."""
    image = image or "assets/hd2d/interior/props/%s.png" % name
    w_m, h_m = size[0] / float(PPM), size[1] / float(PPM)
    shadow_width = 0.9
    shadow_depth = min(2.0, max(0.05, depth / (w_m * shadow_width)))
    box = (round(w_m * 0.94, 3), round(h_m, 3), round(depth, 3))
    lines = [
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Script" path="res://src/world/interior_panel.gd" id="1_panel"]',
        '[ext_resource type="Texture2D" path="res://%s" id="2_image"]' % image,
        "",
        '[sub_resource type="BoxShape3D" id="BoxShape3D_%s"]' % name,
        "size = Vector3(%s)" % _vec(*box),
        "",
        '[node name="%s" type="Node3D"]' % (node_name or name),
        'script = ExtResource("1_panel")',
        'texture = ExtResource("2_image")',
        "shadow_width = %s" % _num(shadow_width),
        "shadow_depth = %s" % _num(round(shadow_depth, 3)),
        "image_offset = Vector3(0, 0, %s)" % _num(depth / 2.0),
    ]
    if glow_amount > 0.0:
        lines.append("glow = %s" % _num(glow_amount))
    if depth < WALL_MOUNTED:
        lines.append("cut_height = %s" % _num(WALL_CUT_HEIGHT))
    lines += [
        "",
        '[node name="Collision" type="StaticBody3D" parent="."]',
        "collision_mask = 0",
        "",
        '[node name="CollisionShape3D" type="CollisionShape3D" parent="Collision"]',
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, %s, 0)" % _num(box[1] / 2.0),
        'shape = SubResource("BoxShape3D_%s")' % name,
        "",
    ]
    return "\n".join(lines)


def rug_scene(name, soft=False):
    return "\n".join([
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Script" path="res://src/world/ground_decal.gd" id="1_decal"]',
        '[ext_resource type="Texture2D" path="res://assets/hd2d/decals/%s.png" id="2_image"]' % name,
        "",
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_decal")',
        'texture = ExtResource("2_image")',
    ] + (["soft_alpha = true"] if soft else []) + [
        "follow_ground = false",
        "",
    ])


def object_scene(name, size, glow_amount):
    """(T2) Objet posé sur un meuble : InteriorPanel sans ombre ni collision ; la carte le pose à
    la hauteur du plateau, juste devant l'image du meuble."""
    lines = [
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Script" path="res://src/world/interior_panel.gd" id="1_panel"]',
        '[ext_resource type="Texture2D" path="res://assets/hd2d/interior/props/%s.png" id="2_image"]' % name,
        "",
        '[node name="%s" type="Node3D"]' % name,
        'script = ExtResource("1_panel")',
        'texture = ExtResource("2_image")',
        "shadow_width = 0",
    ]
    if glow_amount > 0.0:
        lines.append("glow = %s" % _num(glow_amount))
    return "\n".join(lines + [""])


def outdoor_scene(name, image, box, glow_amount=0.0, frames=1, fps=0.0, foreground=False, poles=0.0,
                  soft=False, offset=0.0):
    """(T2) Décor en plein air ou animé : DecorPanel (éclairé comme le dehors, bande animée,
    premier plan) ; collision : une boîte (largeur, hauteur, profondeur) au pied de l'image, ou
    deux poteaux à ± poles m."""
    lines = [
        "[gd_scene format=3]",
        "",
        '[ext_resource type="Script" path="res://src/world/decor_panel.gd" id="1_panel"]',
        '[ext_resource type="Texture2D" path="res://%s" id="2_image"]' % image,
        "",
    ]
    if box:
        lines += ['[sub_resource type="BoxShape3D" id="BoxShape3D_%s"]' % name,
                  "size = Vector3(%s)" % _vec(*box), ""]
    if poles:
        lines += ['[sub_resource type="CylinderShape3D" id="CylinderShape3D_%s"]' % name,
                  "height = 2.2", "radius = 0.1", ""]
    lines += ['[node name="%s" type="Node3D"]' % name, 'script = ExtResource("1_panel")',
              'texture = ExtResource("2_image")']
    if not box and not poles:
        lines.append("shadow_width = 0")
    if glow_amount > 0.0:
        lines.append("glow = %s" % _num(glow_amount))
    if frames > 1:
        lines += ["frames = %d" % frames, "fps = %s" % _num(fps)]
    if foreground:
        lines.append("foreground = true")
    if offset:
        lines.append("image_offset = Vector3(0, 0, %s)" % _num(offset))
    if soft:
        lines.append("soft_alpha = true")
    if box or poles:
        lines += ["", '[node name="Collision" type="StaticBody3D" parent="."]', "collision_mask = 0"]
    if box:
        lines += ["", '[node name="CollisionShape3D" type="CollisionShape3D" parent="Collision"]',
                  "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, %s, 0)" % _num(box[1] / 2.0),
                  'shape = SubResource("BoxShape3D_%s")' % name]
    for k, x in enumerate((-poles, poles) if poles else ()):
        lines += ["", '[node name="Pole%d" type="CollisionShape3D" parent="Collision"]' % (k + 1),
                  "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, 1.1, 0)" % _num(x),
                  'shape = SubResource("CylinderShape3D_%s")' % name]
    return "\n".join(lines + [""])


def scene_path(name):
    """Chemin (relatif à la racine) de la scène d'une image : src/world/props/<nom>.tscn pour celles
    d'E3, src/world/props/interior/<nom>.tscn pour celles des cartes de l'entrepôt (T2)."""
    legacy = {n for n, *_ in FURNITURE} | {n for n, *_ in RUGS}
    folder = "src/world/props" if name in legacy else "src/world/props/interior"
    return "%s/%s.tscn" % (folder, name)


def cmd_scenes(force=False):
    written = 0
    for name, size, depth, glow_amount, _prio in ALL_FURNITURE:
        written += _write(name, furniture_scene(name, size, depth, glow_amount), force)
    for name, image, size, depth, glow_amount in FURNITURE_OTHER_IMAGES:
        written += _write(name, furniture_scene(name, size, depth, glow_amount, image), force)
    for name, size, glow_amount, _prio in ALL_OBJECTS:
        written += _write(name, object_scene(name, size, glow_amount), force)
    for name, _size, _prio, box in OUTDOOR:
        written += _write(name, outdoor_scene(name, "assets/hd2d/interior/props/%s.png" % name, box), force)
    for name, _size, _prio in OUTDOOR_POLES:
        text = outdoor_scene(name, "assets/hd2d/interior/props/%s.png" % name, None, poles=DRYING_POLE_X)
        written += _write(name, text, force)
    for name, size, _prio, (width, depth) in FOREGROUND:
        box = (width, round(size[1] / float(PPM), 3), depth)
        text = outdoor_scene(name, "assets/hd2d/interior/props/%s.png" % name, box, foreground=True,
                             offset=depth / 2.0)
        written += _write(name, text, force)
    for name, _size, glow_amount, _prio in HANGING:
        image = "assets/hd2d/interior/props/%s.png" % name
        written += _write(name, outdoor_scene(name, image, None, glow_amount, foreground=True), force)
    for name, _size, frames, fps, _prio, soft, _free, glow_amount in ANIMS:
        poles = DRYING_POLE_X if name == "drying_frame_wave" else 0.0
        text = outdoor_scene(name, "assets/hd2d/anim/%s.png" % name, None, glow_amount, frames, fps,
                             poles=poles, soft=soft)
        written += _write(name, text, force)
    for name, _size, _prio, _solid in RUGS:
        written += _write(name, rug_scene(name), force)
    for name, _size, _prio, _wrap, soft in DECALS_T2:
        written += _write(name, rug_scene(name, soft), force)
    print("%d scène(s) écrite(s) dans src/world/props/" % written)
    return 0


def _write(name, text, force):
    path = os.path.join(ROOT, scene_path(name))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if os.path.exists(path) and not force:
        with open(path, encoding="utf-8") as handle:
            if handle.read() == text:
                return 0
        print("%s existe (--force pour la réécrire)" % os.path.relpath(path, ROOT))
        return 0
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    print(os.path.relpath(path, ROOT))
    return 1


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("manifest", "scenes"):
        print(__doc__)
        return 2
    if args[0] == "manifest":
        return cmd_manifest()
    return cmd_scenes("--force" in args)


if __name__ == "__main__":
    sys.exit(main())
