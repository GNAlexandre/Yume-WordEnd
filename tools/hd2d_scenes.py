#!/usr/bin/env python3
"""Scènes de décor des images du cahier n° 2 (docs/ASSETS_HD2D_MONDE.md) : une scène
src/world/props/<nom>.tscn prête à poser par image qui se pose dans le monde, au bon format et
avec la bonne collision, écrite selon la recette des fichiers écrits à la main (CLAUDE.md : pas
d'uid, ids lisibles).

Les images sont celles de tools/hd2d_manifest.json (clé lot : cahier n° 2 ; genres panel, anim,
decal, facade) ; le format et la collision de chacune viennent de la table des catégories
tools/hd2d_scenes.json (première catégorie dont un motif nomme l'image ; une image sans catégorie
est une erreur) :
- panel : DecorPanel (bande animée : frames et fps du manifeste ; densité : ppm du manifeste ;
  ancre center du manifeste : origine du nœud au centre de l'image ; image_anchor top : au bord
  haut) ; premier plan, détails de mur et de toit, ciel : propriétés de la catégorie ;
- decal : GroundDecal (soft_alpha du manifeste, couche de la catégorie), sans collision ;
- building : Building (façade, flanc <nom>_side, matières, emprise et hauteurs de la section 9.2,
  collision de l'emprise sur la hauteur du mur) ;
- ship : navire à 96 px/m et ses hélices (DecorPanel animés) posées sur les moyeux mesurés ;
- none : pas de scène (sprites qui volent : textures d'AmbientSprites ; hélices : enfants des
  navires).
La collision (enfant Collision, StaticBody3D de la couche 1, masque 0) est celle de la catégorie :
cylindre, boîte ou poteaux au pied du panneau, à la taille de l'image (96 px/m) ; aucune pour ce
qu'on traverse.

Usage (Python 3.9+) :

    python3 tools/hd2d_scenes.py gen               # crée les scènes absentes
    python3 tools/hd2d_scenes.py gen oak_a inn     # seulement celles-ci (si absentes)
    python3 tools/hd2d_scenes.py gen --force [noms] # réécrit les scènes (toutes, ou ces noms)
    python3 tools/hd2d_scenes.py check             # chaque scène attendue, son image, son format
    python3 tools/hd2d_scenes.py list              # nom, catégorie, format, collision

Après gen : tools/import.sh. check vérifie aussi que chaque flanc du manifeste est le side_facade
de son bâtiment (les neuf bâtiments du cahier n° 1 compris) et qu'aucune image de la catégorie
none n'a de scène. Le résultat de gen est déterministe.
"""

import argparse
import fnmatch
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "hd2d_manifest.json")
TABLE = os.path.join(ROOT, "tools", "hd2d_scenes.json")
PROPS_DIR = "src/world/props"
PPM = 96.0
# Genres du manifeste qui peuvent demander une scène.
SCENE_KINDS = ("panel", "anim", "decal", "facade")
PANEL_SCRIPT = "res://src/world/decor_panel.gd"
DECAL_SCRIPT = "res://src/world/ground_decal.gd"
BUILDING_SCRIPT = "res://src/world/building.gd"
MATERIALS = "assets/hd2d/buildings/materials"
# Métadonnée de la racine : catégorie de la table (lue par les tests et par la pose).
META = "hd2d_category"
# Défauts de DecorPanel (decor_panel.gd) : une propriété égale à son défaut n'est pas écrite.
PANEL_DEFAULTS = {"shadow_width": 0.8, "depth_offset": 0.0, "foreground": False, "glow": 0.0}


# --- Données ---------------------------------------------------------------------------------


def load_json(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def entry_key(entry):
    """Chemin sous assets/hd2d/, sans extension (« props/oak_a »)."""
    return os.path.splitext(entry["path"])[0].split("assets/hd2d/", 1)[1]


def entry_name(entry):
    return os.path.splitext(os.path.basename(entry["path"]))[0]


def image_m(entry):
    """Taille d'une image (une image de la bande) dans le monde, m."""
    ppm = float(entry.get("ppm", PPM))
    return entry["size"][0] / ppm, entry["size"][1] / ppm


def category_of(entry, table):
    key = entry_key(entry)
    for category in table["categories"]:
        if any(fnmatch.fnmatchcase(key, pattern) for pattern in category["match"]):
            return category
    return None


def planned(manifest, table):
    """Images du cahier n° 2 qui peuvent demander une scène : [(entrée, catégorie ou None)]."""
    out = []
    for entry in manifest["images"]:
        if entry.get("lot") and entry["kind"] in SCENE_KINDS:
            out.append((entry, category_of(entry, table)))
    return out


def scene_file(name):
    return os.path.join(ROOT, PROPS_DIR, name + ".tscn")


def res(path):
    return "res://" + path


# --- Écriture -------------------------------------------------------------------------------


def num(value):
    """Nombre à la manière des .tscn : 3, 2.5, 0.833 (3 décimales au plus)."""
    text = ("%.3f" % float(value)).rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def flt(value):
    """Propriété float à la manière des .tscn : 12.0, 0.06."""
    text = num(value)
    return text if "." in text else text + ".0"


def vec3(x, y, z):
    return "Vector3(%s, %s, %s)" % (num(x), num(y), num(z))


def at(x, y, z):
    return "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %s, %s, %s)" % (num(x), num(y), num(z))


def pascal(name):
    return "".join(part[:1].upper() + part[1:] for part in name.split("_"))


def collision_shapes(entry, category):
    """Formes de la collision : [(type de forme, propriétés, (x, y, z))], vide si on traverse."""
    spec = category.get("collision")
    if not spec:
        return []
    width, height = image_m(entry)
    h = height if spec.get("height", "image") == "image" else float(spec["height"])
    shape = spec["shape"]
    if shape == "cylinder":
        radius = spec["radius"] if "radius" in spec else spec["radius_factor"] * width
        return [("CylinderShape3D", {"height": num(h), "radius": num(radius)}, (0.0, h / 2.0, 0.0))]
    if shape == "box":
        size = (width * spec["width_factor"], h, spec["depth"])
        return [("BoxShape3D", {"size": vec3(*size)}, (0.0, h / 2.0, spec.get("z", 0.0)))]
    if shape == "poles":
        x = width / 2.0 - spec["inset"]
        props = {"height": num(h), "radius": num(spec["radius"])}
        return [("CylinderShape3D", props, (-x, h / 2.0, 0.0)), ("CylinderShape3D", props, (x, h / 2.0, 0.0))]
    raise ValueError("forme inconnue : %s" % shape)


def panel_properties(entry, category):
    """Propriétés de DecorPanel écrites dans la scène, dans l'ordre de decor_panel.gd."""
    props = []
    ppm = float(entry.get("ppm", PPM))
    if ppm != PPM:
        props.append(("pixels_per_meter", flt(ppm)))
    values = dict(PANEL_DEFAULTS)
    values.update(category.get("panel", {}))
    if values["shadow_width"] != PANEL_DEFAULTS["shadow_width"]:
        props.append(("shadow_width", flt(values["shadow_width"])))
    _, height = image_m(entry)
    anchor = category.get("image_anchor") or ("center" if entry.get("anchor") == "center" else "")
    if anchor == "center":
        props.append(("image_offset", vec3(0, -height / 2.0, 0)))
    elif anchor == "top":
        props.append(("image_offset", vec3(0, -height, 0)))
    if values["glow"]:
        props.append(("glow", flt(values["glow"])))
    if entry["kind"] == "anim":
        props.append(("frames", str(int(entry["frames"]))))
        props.append(("fps", flt(entry["fps"])))
    if values["depth_offset"]:
        props.append(("depth_offset", flt(values["depth_offset"])))
    if values["foreground"]:
        props.append(("foreground", "true"))
    elif entry.get("soft_alpha"):
        # Alpha doux du manifeste (fumée, brume, nuages, rais de lumière) : mélangé, pas découpé.
        props.append(("soft_alpha", "true"))
    return props


def _scene(ext, subs, nodes):
    """Texte d'une scène : ext_resources [(type, chemin, id)], sous-ressources [(type, id,
    propriétés)], nœuds [(en-tête, [(clé, valeur)])]."""
    lines = ["[gd_scene format=3]", ""]
    for kind, path, ident in ext:
        lines.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, ident))
    lines.append("")
    for kind, ident, props in subs:
        lines.append('[sub_resource type="%s" id="%s"]' % (kind, ident))
        lines.extend("%s = %s" % item for item in props.items())
        lines.append("")
    for header, props in nodes:
        lines.append(header)
        lines.extend("%s = %s" % item for item in props)
        lines.append("")
    return "\n".join(lines).rstrip("\n") + "\n"


def _collision_parts(shapes):
    subs, nodes = [], []
    if not shapes:
        return subs, nodes
    nodes.append(('[node name="Collision" type="StaticBody3D" parent="."]', [("collision_mask", "0")]))
    for k, (kind, props, (x, y, z)) in enumerate(shapes, 1):
        ident = "%s_%d" % (kind, k)
        subs.append((kind, ident, props))
        nodes.append(
            (
                '[node name="Shape%d" type="CollisionShape3D" parent="Collision"]' % k,
                [("transform", at(x, y, z)), ("shape", 'SubResource("%s")' % ident)],
            )
        )
    return subs, nodes


def render_panel(entry, category):
    name = entry_name(entry)
    ext = [("Script", PANEL_SCRIPT, "1_panel"), ("Texture2D", res(entry["path"]), "2_image")]
    props = [("script", 'ExtResource("1_panel")'), ("texture", 'ExtResource("2_image")')]
    props += panel_properties(entry, category)
    props.append(("metadata/" + META, '"%s"' % category["id"]))
    subs, nodes = _collision_parts(collision_shapes(entry, category))
    return _scene(ext, subs, [('[node name="%s" type="Node3D"]' % pascal(name), props)] + nodes)


def render_decal(entry, category):
    name = entry_name(entry)
    ext = [("Script", DECAL_SCRIPT, "1_decal"), ("Texture2D", res(entry["path"]), "2_image")]
    props = [("script", 'ExtResource("1_decal")'), ("texture", 'ExtResource("2_image")')]
    if entry.get("soft_alpha"):
        props.append(("soft_alpha", "true"))
    layer = int(category.get("decal", {}).get("layer", 0))
    if layer:
        props.append(("layer", str(layer)))
    props.append(("metadata/" + META, '"%s"' % category["id"]))
    return _scene(ext, [], [('[node name="%s" type="Node3D"]' % pascal(name), props)])


def building_data(entry, table, by_key):
    """Données d'un bâtiment : celles de la section 9.2 (table), contrôlées par les tailles de
    la façade et du flanc du manifeste."""
    name = entry_name(entry)
    data = table["buildings"].get(name)
    if data is None:
        raise ValueError("%s : bâtiment absent de la clé buildings de la table" % name)
    side = by_key.get("buildings/%s_side" % name)
    if side is None:
        raise ValueError("%s : flanc %s_side absent du manifeste" % (name, name))
    width = entry["size"][0] / PPM
    gable_front = data["type"] == "pignon"
    top = data["ridge"] if gable_front else data["wall"]
    side_size = (data["depth"], data["wall"] if gable_front else data["ridge"])
    problems = []
    if abs(entry["size"][1] / PPM - top) > 0.011:
        problems.append("façade de %.2f m de haut (%.2f attendus)" % (entry["size"][1] / PPM, top))
    for got, want, what in ((side["size"][0] / PPM, side_size[0], "largeur"), (side["size"][1] / PPM, side_size[1], "hauteur")):
        if abs(got - want) > 0.011:
            problems.append("flanc : %s %.2f m (%.2f attendus)" % (what, got, want))
    if side.get("roof") != ("eaves" if gable_front else "gable"):
        problems.append("flanc : forme %s pour un toit %s" % (side.get("roof"), data["type"]))
    if problems:
        raise ValueError("%s : %s" % (name, " ; ".join(problems)))
    return {
        "footprint": (width, data["depth"]),
        "wall": data["wall"],
        "ridge": data["ridge"],
        "gable_front": gable_front,
        "wall_texture": "%s/%s.png" % (MATERIALS, data["wall_texture"]),
        "roof_texture": "%s/%s.png" % (MATERIALS, data["roof_texture"]),
        "side": side["path"],
    }


def render_building(entry, category, table, by_key):
    name = entry_name(entry)
    data = building_data(entry, table, by_key)
    ext = [
        ("Script", BUILDING_SCRIPT, "1_building"),
        ("Texture2D", res(entry["path"]), "2_facade"),
        ("Texture2D", res(data["wall_texture"]), "3_wall"),
        ("Texture2D", res(data["roof_texture"]), "4_roof"),
        ("Texture2D", res(data["side"]), "5_side"),
    ]
    width, depth = data["footprint"]
    props = [
        ("script", 'ExtResource("1_building")'),
        ("facade", 'ExtResource("2_facade")'),
        ("wall_texture", 'ExtResource("3_wall")'),
        ("roof_texture", 'ExtResource("4_roof")'),
        ("footprint", "Vector2(%s, %s)" % (flt(width), flt(depth))),
        ("wall_height", flt(data["wall"])),
        ("ridge_height", flt(data["ridge"])),
    ]
    if data["gable_front"]:
        props.append(("gable_front", "true"))
    props.append(("side_facade", 'ExtResource("5_side")'))
    props.append(("metadata/" + META, '"%s"' % category["id"]))
    box = [("BoxShape3D", {"size": vec3(width, data["wall"], depth)}, (0.0, data["wall"] / 2.0, 0.0))]
    subs, nodes = _collision_parts(box)
    return _scene(ext, subs, [('[node name="%s" type="Node3D"]' % pascal(name), props)] + nodes)


def ship_propellers(entry, table, by_key):
    """Hélices d'un navire : [(nom du nœud, entrée de la bande, position (x, y), décalage)]."""
    name = entry_name(entry)
    data = table["ships"].get(name)
    if data is None:
        raise ValueError("%s : navire absent de la clé ships de la table" % name)
    strip = by_key.get("anim/" + data["propeller"])
    if strip is None:
        raise ValueError("%s : hélice %s absente du manifeste" % (name, data["propeller"]))
    hull_w, hull_h = entry["size"]
    _, blade_h = image_m(strip)
    out = []
    for node_name, (px, py) in zip(data["names"], data["hubs_px"]):
        # Moyeu dessiné (px) → m depuis l'ancre de la coque (milieu du bord bas) ; l'image de
        # l'hélice est centrée sur son moyeu : son ancre est une demi-image plus bas.
        x = (px - hull_w / 2.0) / PPM
        y = (hull_h - py) / PPM - blade_h / 2.0
        out.append((node_name, strip, (x, y), data["depth_offset"]))
    return out


def render_ship(entry, category, table, by_key):
    name = entry_name(entry)
    propellers = ship_propellers(entry, table, by_key)
    strip = propellers[0][1]
    ext = [
        ("Script", PANEL_SCRIPT, "1_panel"),
        ("Texture2D", res(entry["path"]), "2_image"),
        ("Texture2D", res(strip["path"]), "3_propeller"),
    ]
    root = [
        ("script", 'ExtResource("1_panel")'),
        ("texture", 'ExtResource("2_image")'),
        ("shadow_width", "0.0"),
        ("metadata/" + META, '"%s"' % category["id"]),
    ]
    nodes = [('[node name="%s" type="Node3D"]' % pascal(name), root)]
    for node_name, blade, (x, y), offset in propellers:
        props = [
            ("transform", at(x, y, 0.0)),
            ("script", 'ExtResource("1_panel")'),
            ("texture", 'ExtResource("3_propeller")'),
            ("shadow_width", "0.0"),
            ("frames", str(int(blade["frames"]))),
            ("fps", flt(blade["fps"])),
            ("depth_offset", flt(offset)),
        ]
        nodes.append(('[node name="%s" type="Node3D" parent="."]' % node_name, props))
    return _scene(ext, [], nodes)


def render(entry, category, table, by_key):
    kind = category["scene"]
    if kind == "panel":
        return render_panel(entry, category)
    if kind == "decal":
        return render_decal(entry, category)
    if kind == "building":
        return render_building(entry, category, table, by_key)
    if kind == "ship":
        return render_ship(entry, category, table, by_key)
    raise ValueError("%s : format de scène inconnu %s" % (entry_name(entry), kind))


# --- Commandes ------------------------------------------------------------------------------


def _context():
    manifest = load_json(MANIFEST)
    table = load_json(TABLE)
    by_key = {entry_key(e): e for e in manifest["images"]}
    return manifest, table, by_key


def _plan_errors(plan):
    errors = []
    seen = {}
    for entry, category in plan:
        name = entry_name(entry)
        if category is None:
            errors.append("%s : aucune catégorie dans tools/hd2d_scenes.json" % entry_key(entry))
            continue
        if category["scene"] == "none":
            continue
        if name in seen:
            errors.append("%s : même nom de scène que %s" % (entry_key(entry), seen[name]))
        seen[name] = entry_key(entry)
    return errors


def cmd_gen(names, force):
    manifest, table, by_key = _context()
    plan = planned(manifest, table)
    errors = _plan_errors(plan)
    if errors:
        print("\n".join(errors))
        return 1
    wanted = {os.path.splitext(os.path.basename(n))[0] for n in names}
    missing = set(wanted)
    written = kept = 0
    for entry, category in plan:
        name = entry_name(entry)
        if category["scene"] == "none" or (wanted and name not in wanted):
            continue
        missing.discard(name)
        path = scene_file(name)
        if os.path.exists(path) and not force:
            kept += 1
            continue
        text = render(entry, category, table, by_key)
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(text)
        written += 1
        print("%s/%s.tscn (%s)" % (PROPS_DIR, name, category["id"]))
    if missing:
        print("sans scène dans le manifeste : %s" % ", ".join(sorted(missing)))
        return 1
    print("%d scène(s) écrite(s), %d gardée(s) ; puis tools/import.sh" % (written, kept))
    return 0


def parse_scene(text):
    """Scène .tscn : (ext_resources {id: (type, chemin)}, nœuds [(attributs, propriétés)])."""
    ext = {}
    nodes = []
    current = None
    for line in text.splitlines():
        if line.startswith("["):
            current = None
            tag = line[1:].split(" ", 1)[0].rstrip("]")
            attrs = dict(re.findall(r'(\w+)=("[^"]*"|\S+?)(?=[ \]])', line))
            attrs = {k: v.strip('"') for k, v in attrs.items()}
            if tag == "ext_resource":
                ext[attrs.get("id")] = (attrs.get("type"), attrs.get("path"), "uid" in attrs)
            elif tag == "node":
                current = {}
                nodes.append((attrs, current))
            continue
        if current is not None and " = " in line:
            key, value = line.split(" = ", 1)
            current[key] = value
    return ext, nodes


def _ext_path(ext, value):
    match = re.fullmatch(r'ExtResource\("([^"]+)"\)', value or "")
    return ext.get(match.group(1), (None, None, False))[1] if match else None


def _numbers(value):
    """Nombres entre les parenthèses d'une valeur (Vector2(…), Transform3D(…))."""
    inside = (value or "").partition("(")[2].rpartition(")")[0]
    return [float(n) for n in inside.split(",")] if inside.strip() else []


def _float(props, key, default):
    return float(props[key]) if key in props else default


def check_scene(entry, category, table, by_key):
    """Écarts d'une scène attendue à son image et à sa catégorie (liste vide : conforme)."""
    name = entry_name(entry)
    path = scene_file(name)
    if not os.path.exists(path):
        return ["scène absente (python3 tools/hd2d_scenes.py gen)"]
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    problems = []
    if not text.startswith("[gd_scene format=3]\n"):
        problems.append("en-tête : [gd_scene format=3] sans uid")
    if "unique_id=" in text:
        problems.append("unique_id dans un nœud")
    ext, nodes = parse_scene(text)
    if any(has_uid for _, _, has_uid in ext.values()):
        problems.append("ext_resource avec uid")
    if not nodes or "parent" in nodes[0][0]:
        return problems + ["pas de nœud racine"]
    root = nodes[0][1]
    kind = category["scene"]
    script = {"panel": PANEL_SCRIPT, "ship": PANEL_SCRIPT, "decal": DECAL_SCRIPT, "building": BUILDING_SCRIPT}[kind]
    if _ext_path(ext, root.get("script")) != script:
        problems.append("racine : script %s attendu" % script)
    image_key = "facade" if kind == "building" else "texture"
    if _ext_path(ext, root.get(image_key)) != res(entry["path"]):
        problems.append("%s : %s attendu" % (image_key, res(entry["path"])))
    if root.get("metadata/" + META) != '"%s"' % category["id"]:
        problems.append("metadata/%s : \"%s\" attendu" % (META, category["id"]))
    collisions = [attrs for attrs, _ in nodes if attrs.get("name") == "Collision" and attrs.get("parent") == "."]
    blocks = kind == "building" or bool(category.get("collision"))
    if blocks and not collisions:
        problems.append("collision attendue (catégorie %s)" % category["id"])
    if not blocks and collisions:
        problems.append("collision en trop (catégorie %s : on traverse)" % category["id"])
    for attrs, props in nodes:
        if attrs.get("name") == "Collision" and attrs.get("type") == "StaticBody3D":
            if props.get("collision_mask") != "0" or props.get("collision_layer", "1") != "1":
                problems.append("Collision : couche 1, masque 0")
    if kind == "panel":
        problems += _check_panel(entry, category, root)
    elif kind == "decal":
        if (root.get("soft_alpha") == "true") != bool(entry.get("soft_alpha")):
            problems.append("soft_alpha : %s attendu" % bool(entry.get("soft_alpha")))
    elif kind == "building":
        problems += _check_building(entry, table, by_key, ext, root)
    elif kind == "ship":
        problems += _check_ship(entry, table, by_key, ext, nodes)
    return problems


def _check_panel(entry, category, root):
    problems = []
    ppm = float(entry.get("ppm", PPM))
    if abs(_float(root, "pixels_per_meter", PPM) - ppm) > 1e-6:
        problems.append("pixels_per_meter : %s attendu" % num(ppm))
    if entry["kind"] == "anim":
        if int(_float(root, "frames", 1)) != int(entry["frames"]):
            problems.append("frames : %d attendu" % entry["frames"])
        if abs(_float(root, "fps", 0.0) - float(entry["fps"])) > 1e-6:
            problems.append("fps : %s attendu" % entry["fps"])
    elif "frames" in root:
        problems.append("frames sur une image fixe")
    values = dict(PANEL_DEFAULTS)
    values.update(category.get("panel", {}))
    if (root.get("foreground") == "true") != bool(values["foreground"]):
        problems.append("foreground : %s attendu" % values["foreground"])
    if values["shadow_width"] == 0.0 and _float(root, "shadow_width", 0.8) != 0.0:
        problems.append("sans ombre (shadow_width = 0.0)")
    if values["depth_offset"] > 0.0 and _float(root, "depth_offset", 0.0) <= 0.0:
        problems.append("depth_offset attendu (posé contre un mur ou sur un toit)")
    soft = bool(entry.get("soft_alpha")) and not values["foreground"]
    if (root.get("soft_alpha") == "true") != soft:
        problems.append("soft_alpha : %s attendu (alpha doux du manifeste)" % soft)
    return problems


def _check_building(entry, table, by_key, ext, root):
    problems = []
    try:
        data = building_data(entry, table, by_key)
    except ValueError as error:
        return [str(error)]
    for key, want in (("side_facade", data["side"]), ("wall_texture", data["wall_texture"]), ("roof_texture", data["roof_texture"])):
        if _ext_path(ext, root.get(key)) != res(want):
            problems.append("%s : %s attendu" % (key, res(want)))
    numbers = _numbers(root.get("footprint"))
    footprint = tuple(numbers) if len(numbers) == 2 else None
    if footprint is None or max(abs(a - b) for a, b in zip(footprint, data["footprint"])) > 0.011:
        problems.append("footprint : Vector2(%s, %s) attendu" % tuple(num(v) for v in data["footprint"]))
    if abs(_float(root, "wall_height", 3.0) - data["wall"]) > 0.011:
        problems.append("wall_height : %s attendu" % num(data["wall"]))
    if abs(_float(root, "ridge_height", 5.0) - data["ridge"]) > 0.011:
        problems.append("ridge_height : %s attendu" % num(data["ridge"]))
    if (root.get("gable_front") == "true") != data["gable_front"]:
        problems.append("gable_front : %s attendu" % data["gable_front"])
    return problems


def _check_ship(entry, table, by_key, ext, nodes):
    problems = []
    root = nodes[0][1]
    if abs(_float(root, "pixels_per_meter", PPM) - PPM) > 1e-6:
        problems.append("pixels_per_meter : 96 attendu (navire à quai)")
    try:
        propellers = ship_propellers(entry, table, by_key)
    except ValueError as error:
        return problems + [str(error)]
    children = {attrs.get("name"): props for attrs, props in nodes[1:] if attrs.get("parent") == "."}
    for node_name, strip, (x, y), _ in propellers:
        props = children.get(node_name)
        if props is None:
            problems.append("hélice %s absente" % node_name)
            continue
        if _ext_path(ext, props.get("texture")) != res(strip["path"]):
            problems.append("%s : texture %s attendue" % (node_name, res(strip["path"])))
        if int(_float(props, "frames", 1)) != int(strip["frames"]) or _float(props, "fps", 0.0) != float(strip["fps"]):
            problems.append("%s : frames %d et fps %s attendus" % (node_name, strip["frames"], strip["fps"]))
        numbers = _numbers(props.get("transform"))
        if len(numbers) != 12 or abs(numbers[9] - x) > 0.011 or abs(numbers[10] - y) > 0.011:
            problems.append("%s : posée en (%s, %s) sur le moyeu" % (node_name, num(x), num(y)))
    return problems


def check_sides(manifest):
    """Chaque flanc du manifeste est le side_facade de son bâtiment (même nom sans _side)."""
    problems = []
    for entry in manifest["images"]:
        if entry["kind"] != "side":
            continue
        name = entry_name(entry)[: -len("_side")]
        path = scene_file(name)
        if not os.path.exists(path):
            problems.append("%s : bâtiment %s/%s.tscn absent" % (entry_name(entry), PROPS_DIR, name))
            continue
        with open(path, encoding="utf-8") as handle:
            ext, nodes = parse_scene(handle.read())
        if not nodes or _ext_path(ext, nodes[0][1].get("side_facade")) != res(entry["path"]):
            problems.append("%s.tscn : side_facade = %s attendu" % (name, res(entry["path"])))
    return problems


def cmd_check():
    manifest, table, by_key = _context()
    plan = planned(manifest, table)
    problems = _plan_errors(plan)
    count = 0
    for entry, category in plan:
        if category is None:
            continue
        name = entry_name(entry)
        if category["scene"] == "none":
            if os.path.exists(scene_file(name)):
                problems.append("%s : pas de scène pour la catégorie %s" % (name, category["id"]))
            continue
        count += 1
        problems += ["%s : %s" % (name, p) for p in check_scene(entry, category, table, by_key)]
    problems += check_sides(manifest)
    for problem in problems:
        print(problem)
    print("%d scène(s) vérifiée(s), %d écart(s)" % (count, len(problems)))
    return 1 if problems else 0


def cmd_list():
    manifest, table, by_key = _context()
    for entry, category in planned(manifest, table):
        if category is None:
            print("%-28s ?" % entry_name(entry))
            continue
        shapes = []
        if category["scene"] in ("panel",):
            shapes = ["%s %s" % (kind.replace("Shape3D", "").lower(), " ".join("%s=%s" % i for i in props.items()))
                      for kind, props, _ in collision_shapes(entry, category)]
        elif category["scene"] == "building":
            shapes = ["box (emprise)"]
        print("%-28s %-16s %-8s %s" % (entry_name(entry), category["id"], category["scene"], " ; ".join(shapes) or "-"))
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    gen = sub.add_parser("gen", help="crée les scènes absentes")
    gen.add_argument("names", nargs="*")
    gen.add_argument("--force", action="store_true", help="réécrit les scènes existantes")
    sub.add_parser("check", help="vérifie les scènes attendues")
    sub.add_parser("list", help="catégorie, format et collision de chaque image")
    args = parser.parse_args()
    if args.command == "gen":
        return cmd_gen(args.names, args.force)
    if args.command == "check":
        return cmd_check()
    return cmd_list()


if __name__ == "__main__":
    sys.exit(main())
