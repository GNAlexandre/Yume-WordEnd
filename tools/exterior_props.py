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
}

# (C3) La colline des étoiles : variantes de premier plan (CARTE.md 0.3) de l'arbre solitaire et du rocher
# du plan, qui s'effacent devant le joueur quand ils se dressent au sud de lui.
PROPS.update({
    "lone_tree_fg": inherited("lone_tree", "LoneTree", "foreground = true"),
    "boulder_a_fg": inherited("boulder_a", "BoulderA", "foreground = true"),
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
