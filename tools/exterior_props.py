"""(C1) Les scènes de décor que les recettes de tools/exterior_maps.py demandent et que le dépôt
n'a pas : src/world/props/<nom>.tscn, écrites selon la recette de CLAUDE.md (panneau DecorPanel ou
décalque GroundDecal, sa collision dans un enfant « Collision » de la couche 1).

    python3 tools/exterior_maps.py props      # écrit celles qui manquent ou qui ont changé

Une scène déjà au dépôt qui n'est pas dans la table (les décors du lot T1, retouchés à la main) n'est
jamais réécrite : seules celles de PROPS le sont, et elles ne sont jamais modifiées à la main.
Un décor nouveau : une entrée de PROPS (et son image au manifeste, tools/hd2d_manifest.json)."""

import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROPS_DIR = os.path.join(ROOT, "src", "world", "props")


def panel(node, image, props="", meta="", shapes=()):
    """Scène d'un DecorPanel ; shapes : [(type, paramètres, (x, y, z))] de sa collision."""
    lines = ["[gd_scene format=3]", "",
             '[ext_resource type="Script" path="res://src/world/decor_panel.gd" id="1_panel"]',
             '[ext_resource type="Texture2D" path="res://assets/hd2d/%s" id="2_image"]' % image, ""]
    for k, (kind, params, _at) in enumerate(shapes, 1):
        lines.append('[sub_resource type="%s" id="%s_%d"]' % (kind, kind, k))
        lines.extend(params)
        lines.append("")
    lines.append('[node name="%s" type="Node3D"]' % node)
    lines.append('script = ExtResource("1_panel")')
    lines.append('texture = ExtResource("2_image")')
    if props:
        lines.extend(props.strip().split("\n"))
    if meta:
        lines.append('metadata/hd2d_category = "%s"' % meta)
    if shapes:
        lines += ["", '[node name="Collision" type="StaticBody3D" parent="."]', "collision_mask = 0"]
        for k, (kind, _params, at) in enumerate(shapes, 1):
            lines += ["", '[node name="Shape%d" type="CollisionShape3D" parent="Collision"]' % k,
                      "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)" % at,
                      'shape = SubResource("%s_%d")' % (kind, k)]
    return "\n".join(lines) + "\n"


def decal(node, image, props="", meta="decal"):
    """Scène d'un GroundDecal (décalque au sol, sans collision)."""
    lines = ["[gd_scene format=3]", "",
             '[ext_resource type="Script" path="res://src/world/ground_decal.gd" id="1_decal"]',
             '[ext_resource type="Texture2D" path="res://assets/hd2d/%s" id="2_image"]' % image, "",
             '[node name="%s" type="Node3D"]' % node, 'script = ExtResource("1_decal")',
             'texture = ExtResource("2_image")']
    if props:
        lines.extend(props.strip().split("\n"))
    lines.append('metadata/hd2d_category = "%s"' % meta)
    return "\n".join(lines) + "\n"


def inherited(base, node, props):
    """Scène héritée d'un décor de src/world/props/ : ses propriétés en plus."""
    return ("[gd_scene format=3]\n\n"
            '[ext_resource type="PackedScene" path="res://src/world/props/%s.tscn" id="1_base"]\n\n'
            '[node name="%s" instance=ExtResource("1_base")]\n%s\n' % (base, node, props))


def building(node, facade, wall_texture, roof_texture, width, depth, wall, ridge, gable_front, side=True, glow=None):
    """Scène d'un Building (comme tools/hd2d_scenes.py : façade et flanc <facade>_side, matières, emprise, hauteurs ;
    collision : l'emprise sur la hauteur du mur). (QO) glow : (couleur des carreaux de l'image « #RRGGBB »,
    tolérance) pour Building.window_glow_color et window_glow_tolerance (docs/QUALITE.md, QC-02)."""
    lines = ["[gd_scene format=3]", "",
             '[ext_resource type="Script" path="res://src/world/building.gd" id="1_building"]',
             '[ext_resource type="Texture2D" path="res://assets/hd2d/buildings/%s.png" id="2_facade"]' % facade,
             '[ext_resource type="Texture2D" path="res://assets/hd2d/buildings/materials/%s.png" id="3_wall"]' % wall_texture,
             '[ext_resource type="Texture2D" path="res://assets/hd2d/buildings/materials/%s.png" id="4_roof"]' % roof_texture]
    if side:
        lines.append('[ext_resource type="Texture2D" path="res://assets/hd2d/buildings/%s_side.png" id="5_side"]' % facade)
    lines += ["", '[sub_resource type="BoxShape3D" id="BoxShape3D_1"]',
              "size = Vector3(%g, %g, %g)" % (width, wall, depth), "",
              '[node name="%s" type="Node3D"]' % node, 'script = ExtResource("1_building")',
              'facade = ExtResource("2_facade")', 'wall_texture = ExtResource("3_wall")',
              'roof_texture = ExtResource("4_roof")', "footprint = Vector2(%.1f, %.1f)" % (width, depth),
              "wall_height = %g" % wall, "ridge_height = %g" % ridge]
    if gable_front:
        lines.append("gable_front = true")
    if side:
        lines.append('side_facade = ExtResource("5_side")')
    if glow:
        rgb = [int(glow[0][i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
        lines += ["window_glow_color = Color(%s, 1)" % ", ".join("%.7g" % v for v in rgb),
                  "window_glow_tolerance = %g" % glow[1]]
    lines += ['metadata/hd2d_category = "building"', "", '[node name="Collision" type="StaticBody3D" parent="."]',
              "collision_mask = 0", "", '[node name="Shape1" type="CollisionShape3D" parent="Collision"]',
              "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, %g, 0)" % (wall / 2.0),
              'shape = SubResource("BoxShape3D_1")']
    return "\n".join(lines) + "\n"


def deck(node, texture, width, length, thick, meta):
    """Scène d'un plancher posé à plat (un Building sans façade : matière des murs et du toit, épaisseur thick), sa collision
    sur toute son emprise ; origine au centre de l'emprise (le dessus est à thick au-dessus de l'origine)."""
    return "\n".join([
        "[gd_scene format=3]", "",
        '[ext_resource type="Script" path="res://src/world/building.gd" id="1_building"]',
        '[ext_resource type="Texture2D" path="res://assets/hd2d/buildings/materials/%s.png" id="2_planks"]' % texture, "",
        '[sub_resource type="BoxShape3D" id="BoxShape3D_1"]', "size = Vector3(%g, %g, %g)" % (width, thick, length), "",
        '[node name="%s" type="Node3D"]' % node, 'script = ExtResource("1_building")',
        'wall_texture = ExtResource("2_planks")', 'roof_texture = ExtResource("2_planks")',
        "footprint = Vector2(%g, %g)" % (width, length), "wall_height = %g" % thick, "ridge_height = %g" % thick,
        "overhang = 0.0", 'metadata/hd2d_category = "%s"' % meta, "",
        '[node name="Collision" type="StaticBody3D" parent="."]', "collision_mask = 0", "",
        '[node name="Shape1" type="CollisionShape3D" parent="Collision"]',
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, %g, 0)" % (thick / 2.0), 'shape = SubResource("BoxShape3D_1")',
    ]) + "\n"


# Cahier n° 5, lot R3 (docs/ASSETS_HD2D_ILE68.md, 5.1) : le sentier et le marais. Remplaçants dans
# tools/hd2d_sentier.py ; CARTE.md, section 4.
PROPS = {
    "marsh_reed_wall": panel("MarshReedWall", "props/marsh_reed_wall.png", "shadow_width = 0.0", "plant"),
    "path_edge_ferns": panel("PathEdgeFerns", "props/path_edge_ferns.png", "shadow_width = 0.0", "plant"),
    "path_root_step": panel("PathRootStep", "props/path_root_step.png", "shadow_width = 0.3", "plant_low"),
    # Premier plan suspendu au-dessus du sentier : le panneau se pose en l'air (y de la pose), s'efface
    # autour du joueur quand il passe dessous ; le premier plan accroché à l'écran est au lot E10.
    # Variantes de premier plan (CARTE.md 0.3) : le rideau de roseaux se dresse au sud d'un joueur qui
    # marche derrière lui ; l'écriteau d'attente au bout d'un chemin qu'on parcourt vers lui.
    "marsh_reed_wall_fg": inherited("marsh_reed_wall", "MarshReedWall", "foreground = true"),
    "waiting_sign_fg": inherited("waiting_sign", "WaitingSign", "foreground = true"),
    "fg_canopy_a": panel("FgCanopyA", "props/fg_canopy_a.png", "shadow_width = 0.0\nforeground = true",
                         "foreground_canopy"),
    "bog_pool_a": decal("BogPoolA", "decals/bog_pool_a.png"),
    "path_stones_a": decal("PathStonesA", "decals/path_stones_a.png"),
    "path_stones_b": decal("PathStonesB", "decals/path_stones_b.png"),
    # (C2) Le village des hommes-bêtes (CARTE.md, section 5) : maisons (cahier n° 5, 5.3 : type, mur / faîte,
    # profondeur), le café sans les trois tables que sa scène de T1 posait devant sa porte (la place devant_cafe est
    # libre), clôtures, ruches, charrette, meule, lavoir et leurs variantes de premier plan.
    "cottage_thatch_a": building("CottageThatchA", "cottage_thatch_a", "wall_wattle_daub", "roof_thatch", 5, 5, 2.5,
                                 5.5, True),
    "cottage_thatch_b": building("CottageThatchB", "cottage_thatch_b", "wall_wattle_daub", "roof_thatch", 7, 5, 2.5, 5,
                                 False),
    "cottage_thatch_c": building("CottageThatchC", "cottage_thatch_c", "wall_wattle_daub", "roof_thatch", 4, 4, 2.25,
                                 5, True),
    "village_barn": building("VillageBarn", "village_barn", "wall_planks", "roof_thatch", 8, 6, 3.5, 7, False),
    "village_house_stone": building("VillageHouseStone", "village_house_stone", "wall_stone", "roof_shingles", 5, 5, 3,
                                    6, True),
    "village_shed": building("VillageShed", "village_shed", "wall_planks_b", "roof_shingles", 4, 3, 2.25, 3.5, False),
    # (QO) Règle de lueur par défaut : une règle propre à ses lampes de vitrine (#E9C18D) en faisait des taches
    # blanches bruitées ; la façade de nuit du café est commandée (cahier n° 5, R0.9 ; docs/QUALITE.md, QC-16).
    "cafe_village": building("CafeVillage", "cafe", "wall_plaster", "roof_tiles", 7, 6, 5.5, 7.5, False),
    "fence_wattle": panel("FenceWattle", "props/fence_wattle.png", "shadow_width = 0.6", "fence",
                          [("BoxShape3D", ["size = Vector3(1.9, 0.9, 0.25)"], (0, 0.45, 0))]),
    "fence_wattle_libre": panel("FenceWattleLibre", "props/fence_wattle.png", "shadow_width = 0.6", "fence"),
    "beehives": panel("Beehives", "props/beehives.png", "", "object_small",
                      [("BoxShape3D", ["size = Vector3(1.5, 0.9, 0.7)"], (0, 0.45, 0))]),
    "cart_hay": panel("CartHay", "props/cart_hay.png", "", "object_large",
                      [("BoxShape3D", ["size = Vector3(2.6, 1.0, 1.1)"], (0.1, 0.5, 0))]),
    "haystack": panel("Haystack", "props/haystack.png", "", "object_large",
                      [("BoxShape3D", ["size = Vector3(1.6, 1.4, 1.3)"], (0, 0.7, 0))]),
    "washing_trough": panel("WashingTrough", "props/washing_trough.png", "", "object_large",
                            [("BoxShape3D", ["size = Vector3(2.8, 0.8, 0.8)"], (0, 0.4, 0))]),
    # Variantes de premier plan (CARTE.md 0.3) : ce qui dépasse 1,2 m au sud d'un endroit où l'on marche.
    "cart_hay_fg": inherited("cart_hay", "CartHay", "foreground = true"),
    "haystack_fg": inherited("haystack", "Haystack", "foreground = true"),
    "scarecrow_front": inherited("scarecrow", "Scarecrow", "foreground = true"),
    "firewood_pile_front": inherited("firewood_pile", "FirewoodPile", "foreground = true"),
}

# (C3) La colline des étoiles : variantes de premier plan (CARTE.md 0.3) de l'arbre solitaire et du rocher
# du plan, qui s'effacent devant le joueur quand ils se dressent au sud de lui.
PROPS.update({
    "lone_tree_fg": inherited("lone_tree", "LoneTree", "foreground = true"),
    "boulder_a_fg": inherited("boulder_a", "BoulderA", "foreground = true"),
})

# (CP) Le port (CARTE.md, section 6) : les décors du quai et de la rue du port que le cahier n° 5 (5.6) n'a pas livrés,
# la cabane du gardien, le panneau de coque du transport de la Garde (remplaçant : E7 le remplace par le navire en
# volume, sans collision) et les variantes de premier plan (CARTE.md 0.3) de ce qui se dresse au sud d'un endroit où
# l'on marche.
PROPS.update({
    "mooring_arm_open": panel("MooringArmOpen", "props/mooring_arm_open.png", "shadow_width = 0.9", "mast",
                              [("BoxShape3D", ["size = Vector3(1.2, 4.0, 0.8)"], (-0.6, 2.0, 0))]),
    "steam_whistle": panel("SteamWhistle", "props/steam_whistle.png", "shadow_width = 0.5", "object_small",
                           [("BoxShape3D", ["size = Vector3(0.5, 2.0, 0.5)"], (0, 1.0, 0))]),
    "capstan": panel("Capstan", "props/capstan.png", "shadow_width = 0.9", "object_small",
                     [("CylinderShape3D", ["height = 0.9", "radius = 0.35"], (0, 0.45, 0))]),
    "signpost_port": panel("SignpostPort", "props/signpost_port.png", "shadow_width = 0.6", "mast",
                           [("CylinderShape3D", ["height = 3.0", "radius = 0.2"], (0, 1.5, 0))]),
    "wind_fence": panel("WindFence", "props/wind_fence.png", "shadow_width = 0.6", "fence",
                        [("BoxShape3D", ["size = Vector3(1.9, 1.4, 0.25)"], (0, 0.7, 0))]),
    "cargo_cart_a": panel("CargoCartA", "props/cargo_cart_a.png", "", "object_large",
                          [("BoxShape3D", ["size = Vector3(2.6, 1.0, 1.0)"], (0.1, 0.5, 0))]),
    "cargo_cart_b": panel("CargoCartB", "props/cargo_cart_b.png", "", "object_large",
                          [("BoxShape3D", ["size = Vector3(2.2, 1.0, 0.9)"], (0, 0.5, 0))]),
    "port_house_b": building("PortHouseB", "port_house_b", "wall_planks_b", "roof_tin", 4, 5, 4.0, 6.5, True),
    "garde_transport_side": panel("GardeTransportSide", "ships/garde_transport_side.png", "shadow_width = 0.0", "ship"),
    # La passerelle : un plancher de 2 × 3,6 m qui va du quai à la coque (le plan : `gangway`, 2 × 1,6 m, sans collision ;
    # l'image livrée est une rampe de flanc, la scène de T1 un plancher de 12 m pour la plage). E7 la remplace par la rampe.
    "gangway_quay": deck("GangwayQuay", "wall_planks", 2.0, 3.6, 0.25, "object_large"),
    "cargo_cart_a_fg": inherited("cargo_cart_a", "CargoCartA", "foreground = true"),
    "dock_lamp_fg": inherited("dock_lamp", "DockLamp", "foreground = true"),
    "signpost_port_fg": inherited("signpost_port", "SignpostPort", "foreground = true"),
    "notice_board_fg": inherited("notice_board", "NoticeBoard", "foreground = true"),
    "propeller_spare_fg": inherited("propeller_spare", "PropellerSpare", "foreground = true"),
})


def write_all(quiet=False):
    """Écrit les scènes de PROPS qui manquent ou ont changé ; rend les noms écrits."""
    written = []
    for name, text in PROPS.items():
        path = os.path.join(PROPS_DIR, name + ".tscn")
        old = open(path, encoding="utf-8").read() if os.path.exists(path) else None
        if old == text:
            continue
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)
        written.append(name)
        if not quiet:
            print("écrit src/world/props/%s.tscn" % name)
    if not written and not quiet:
        print("décors : à jour")
    return written
