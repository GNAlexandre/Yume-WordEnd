#!/usr/bin/env python3
"""(QC) Outils du garant de la qualité visuelle (docs/QUALITE.md).

  python3 tools/qc_tool.py check               # la liste des vues (tools/qc_views.json) couvre-t-elle l'île ?
  python3 tools/qc_tool.py contact <dossier>   # planches contact des captures d'un passage de tools/qc_shots.sh

check (code 1 si un manque) :
- chaque carte de data/world/islands/ile_68.json a ses vues, et chaque carte des vues est une carte de l'île ;
- chaque vue a un nom unique, se tient dans la carte (size de la scène) et nomme des moments et des temps connus ;
- chaque pièce (son centre), place (son centre) et point nommé des plans de docs/lore/CARTE.md d'une carte
  « dehors » ou « dedans » est dans le champ d'au moins une vue : le point visé est à 2,5 m au nord du joueur,
  borné par camera_bounds ; on compte ce qui est à moins de 9,5 m de part et d'autre, 14 m au nord et 6,5 m au
  sud du point visé (docs/lore/CARTE.md, section 0.3, en retrait des bords de l'écran).

contact : lit <dossier>/index.tsv (écrit par tests/integration/demo_qc.gd ; la dernière ligne d'une capture
l'emporte) et écrit <dossier>/contact_<carte>.png : les captures réduites en grille, avec le nom de la vue, le
moment, les draw calls et la luminance ; en rouge ce qui dépasse le budget (200 draw calls, sauf les vues
d'ensemble) ou passe sous le seuil de luminance (0,1 en moyenne).
"""

from __future__ import annotations

import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

VIEWS = os.path.join(ROOT, "tools", "qc_views.json")
ISLAND = os.path.join(ROOT, "data", "world", "islands", "ile_68.json")
CARTE = os.path.join(ROOT, "docs", "lore", "CARTE.md")
MOMENTS = {"aube", "matin", "apres_midi", "couchant", "nuit"}
WEATHERS = {"clair", "pluie", "averse"}
KINDS = {"dehors", "dedans", "attente"}
LOOKS = {"N", "S", "E", "O"}
AIM_AHEAD = 2.5
HALF_WIDTH = 9.5
NORTH = 14.0
SOUTH = 6.5
DRAW_CALL_BUDGET = 200
LUMA_FLOOR = 0.1


def map_props(map_id: str) -> dict:
    """size et camera_bounds de la racine de src/world/maps/<id>/<id>.tscn."""
    path = os.path.join(ROOT, "src", "world", "maps", map_id, f"{map_id}.tscn")
    if not os.path.exists(path):
        return {}
    text = open(path, encoding="utf-8").read()
    start = text.find(f'[node name="{map_id}"')
    end = text.find("\n[", start + 5)
    block = text[start:end if end > 0 else len(text)]
    props: dict = {}
    m = re.search(r"^size = Vector2\(([-\d.]+), ([-\d.]+)\)", block, re.M)
    if m:
        props["size"] = (float(m.group(1)), float(m.group(2)))
    m = re.search(r"^camera_bounds = Rect2\(([-\d.]+), ([-\d.]+), ([-\d.]+), ([-\d.]+)\)", block, re.M)
    if m:
        props["bounds"] = tuple(float(m.group(i)) for i in range(1, 5))
    return props


def aim_of(at: list, props: dict) -> tuple[float, float]:
    ax, az = float(at[0]), float(at[1]) - AIM_AHEAD
    bounds = props.get("bounds")
    if bounds is None or (bounds[2] <= 0 and bounds[3] <= 0 and bounds[0] == 0 and bounds[1] == 0):
        size = props.get("size", (1e9, 1e9))
        bounds = (0.0, 0.0, size[0], size[1])
    x0, z0, w, d = bounds
    return min(max(ax, x0), x0 + w), min(max(az, z0), z0 + d)


def sees(aim: tuple[float, float], x: float, z: float) -> bool:
    return abs(x - aim[0]) <= HALF_WIDTH and aim[1] - NORTH <= z <= aim[1] + SOUTH


def check() -> int:
    import carte_plans

    data = json.load(open(VIEWS, encoding="utf-8"))
    island = json.load(open(ISLAND, encoding="utf-8"))
    maps = data.get("maps", {})
    problems: list[str] = []
    for map_id in island["maps"]:
        if map_id not in maps:
            problems.append(f"{map_id} : carte de l'île sans vue (tools/qc_views.json)")
    for map_id in maps:
        if map_id not in island["maps"]:
            problems.append(f"{map_id} : pas une carte de ile_68.json")
    plans = {m.id: m for m in carte_plans.parse(open(CARTE, encoding="utf-8").read())}
    count = 0
    for map_id, entry in maps.items():
        kind = entry.get("kind", "")
        if kind not in KINDS:
            problems.append(f"{map_id} : kind « {kind} » inconnu ({', '.join(sorted(KINDS))})")
        props = map_props(map_id)
        if not props:
            problems.append(f"{map_id} : scène src/world/maps/{map_id}/{map_id}.tscn introuvable")
            continue
        size = props.get("size", (0.0, 0.0))
        names: set[str] = set()
        aims: list[tuple[float, float]] = []
        for view in entry.get("views", []):
            name = view.get("name", "")
            if not name or name in names:
                problems.append(f"{map_id} : vue sans nom ou en double ({name})")
            names.add(name)
            moments = view.get("moments") or (
                data["defaults"]["overview_moments"] if view.get("overview")
                else data["defaults"]["interior_moments"] if kind == "dedans" else data["defaults"]["moments"]
            )
            for spec in moments:
                parts = spec.split(":")
                if parts[0] not in MOMENTS or (len(parts) > 1 and parts[1] not in WEATHERS) or len(parts) > 2:
                    problems.append(f"{map_id}:{name} : moment « {spec} » inconnu")
            count += len(moments)
            if view.get("overview"):
                continue
            at = view.get("at")
            if not isinstance(at, list) or len(at) != 2:
                problems.append(f"{map_id}:{name} : at = [x, z] attendu")
                continue
            if not (0 <= at[0] <= size[0] and 0 <= at[1] <= size[1]):
                problems.append(f"{map_id}:{name} : at {at} hors de la carte ({size[0]:g} × {size[1]:g} m)")
            if view.get("look", "N") not in LOOKS:
                problems.append(f"{map_id}:{name} : look N, S, E ou O attendu")
            aims.append(aim_of(at, props))
        if kind == "attente" or map_id not in plans:
            continue
        plan = plans[map_id]
        targets: list[tuple[str, float, float]] = []
        for room in plan.rooms.values():
            r = room.rect
            targets.append((f"pièce {room.name}", (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2))
        for place in plan.places:
            r = place.rect
            targets.append((f"place {place.name}", (r.x0 + r.x1) / 2, (r.z0 + r.z1) / 2))
        for name, point in plan.points.items():
            targets.append((f"point {name}", point.rect.x0, point.rect.z0))
        for label, x, z in targets:
            if not any(sees(aim, x, z) for aim in aims):
                problems.append(f"{map_id} : {label} ({x:g} ; {z:g}) dans le champ d'aucune vue")
    for p in problems:
        print("QC check :", p)
    print(f"QC check : {len(maps)} cartes, {count} captures prévues, {len(problems)} manque(s)")
    return 1 if problems else 0


def contact(folder: str) -> int:
    from PIL import Image, ImageDraw, ImageFont

    index = os.path.join(folder, "index.tsv")
    if not os.path.exists(index):
        print(f"QC contact : {index} absent")
        return 1
    rows: dict[str, dict] = {}
    with open(index, encoding="utf-8") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            rows[row["file"]] = row
    by_map: dict[str, list[dict]] = {}
    for row in rows.values():
        by_map.setdefault(row["map"], []).append(row)
    order = list(json.load(open(VIEWS, encoding="utf-8"))["maps"].keys())
    font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
    font = ImageFont.truetype(font_path, 15) if os.path.exists(font_path) else ImageFont.load_default(15)
    tw, th, label_h, cols, pad = 400, 225, 22, 4, 6
    for map_id, items in by_map.items():
        view_order = {}
        if map_id in order:
            views = json.load(open(VIEWS, encoding="utf-8"))["maps"][map_id]["views"]
            view_order = {v["name"]: i for i, v in enumerate(views)}
        moment_order = ["aube", "matin", "apres_midi", "couchant", "nuit"]
        items.sort(key=lambda r: (view_order.get(r["view"], 999), r["view"],
                                  moment_order.index(r["moment"]) if r["moment"] in moment_order else 9,
                                  r["weather"] != "clair"))
        rows_n = (len(items) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows_n * (th + label_h + pad) + pad + 28), (24, 24, 28))
        draw = ImageDraw.Draw(sheet)
        draw.text((pad, 6), f"{map_id} : {len(items)} vues ({os.path.basename(os.path.normpath(folder))})", fill=(240, 240, 240), font=font)
        for i, row in enumerate(items):
            x = pad + (i % cols) * (tw + pad)
            y = 28 + pad + (i // cols) * (th + label_h + pad)
            path = os.path.join(folder, row["file"])
            if os.path.exists(path):
                thumb = Image.open(path).convert("RGB").resize((tw, th), Image.LANCZOS)
                sheet.paste(thumb, (x, y))
            calls = int(float(row["draw_calls"]))
            luma = float(row["luma"])
            # Une vue d'ensemble (caméra haute, toute la carte) n'est pas une vue du jeu : pas de budget.
            bad = (calls > DRAW_CALL_BUDGET and row["view"] != "ensemble") or luma < LUMA_FLOOR
            label = f"{row['view']} · {row['moment']}" + (f" · {row['weather']}" if row["weather"] != "clair" else "")
            label += f" · {calls} dc · L {luma:.2f}"
            draw.text((x + 2, y + th + 2), label, fill=(255, 110, 110) if bad else (230, 230, 230), font=font)
        out = os.path.join(folder, f"contact_{map_id}.png")
        sheet.save(out)
        print(f"QC contact : {out} ({len(items)} vues)")
    return 0


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ("check", "contact"):
        print(__doc__)
        return 2
    if sys.argv[1] == "check":
        return check()
    if len(sys.argv) < 3:
        print("usage : qc_tool.py contact <dossier>")
        return 2
    return contact(sys.argv[2])


if __name__ == "__main__":
    sys.exit(main())
