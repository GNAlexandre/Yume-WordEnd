#!/usr/bin/env python3
"""Contrôle et aperçu autonome des corrections demandées au §12 (PNG/JSON réels)."""

import argparse
import base64
import hashlib
import html
import importlib.util
import io
import json
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = "1ff21b9"
module_spec = importlib.util.spec_from_file_location("sheets", ROOT / "tools/hd2d_sheets.py")
sheets = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(sheets)


def targets():
    result = {}

    def add(identifier, views, changed, heights=None, enemy=False):
        for suffix in views:
            folder = "enemies" if enemy else "characters"
            path = f"assets/{folder}/{identifier}/{identifier}{suffix}"
            result[path] = {"changed": changed, "heights": heights or {}}

    add("nygglatho", [""], ["parle"], {"parle": 178})
    add("limeskin", ["", "_front"], ["parle"], {"parle": 269})
    add("limeskin", ["_back"], ["repos", "parle"])
    add("lakhesh", [""], ["repos"])
    add("lakhesh", ["_front"], ["parle"], {"parle": 114})
    add("lakhesh", ["_back"], "all")
    add("pannibal", [""], "all", {"repos": 120, "parle": 120, "marche": 120})
    add("chtholly", ["_front"], "all", {"repos": 144})
    add("willem", ["", "_front", "_back"], ["parle"], {"parle": 168})
    add("nephren", ["", "_front"], ["parle"], {"parle": 125})
    add("cat_waiter", [""], ["parle", "marche"], {"parle": 158, "marche": "idle"})
    add("cat_waiter", ["_back"], ["marche"], {"marche": "idle"})
    add("snack_vendor", [""], ["parle", "marche"], {"parle": 154, "marche": "idle"})
    add("snack_vendor", ["_back"], ["marche"], {"marche": "idle"})
    add("ferryman", [""], ["parle"], {"parle": 163})
    add("tiat", ["", "_front", "_back"], ["parle", "marche"], {"parle": 106, "marche": 106})
    add("egg_vendor", [""], ["marche"], {"marche": "idle"})
    add("egg_vendor", ["_back"], ["parle", "marche"], {"parle": 149, "marche": 149})
    for identifier, views in [
        ("collon", ["_front", "_back"]), ("almita", ["", "_back"]),
        ("ramikeldi", ["_front", "_back"]), ("garde_lookout", ["_back"]),
    ]:
        add(identifier, views, ["marche"], {"marche": "idle"})
    add("timere", [""], ["fouet"], enemy=True)
    add("ithea", ["", "_front", "_back"], "all", {"repos": 139, "parle": 139})
    return result


def previous(path):
    return subprocess.check_output(["git", "show", f"{BASE}:{path}"], cwd=ROOT)


def source(path, old=False):
    data = previous(path) if old else (ROOT / path).read_bytes()
    return data


def png_uri(data):
    return "data:image/png;base64," + base64.b64encode(data).decode("ascii")


def frame_hash(image, frame):
    part = sheets.crop(image, frame)
    return hashlib.sha256(part.tobytes()).hexdigest(), part.size


def validate():
    errors, entries = [], []
    for path, contract in targets().items():
        before = json.loads(source(path + ".json", True))
        after = json.loads(source(path + ".json"))
        old_image = Image.open(io.BytesIO(source(path + ".png", True))).convert("RGBA")
        image = Image.open(ROOT / (path + ".png")).convert("RGBA")
        if after["planche"] != list(image.size):
            errors.append(f"{path}: dimensions du JSON différentes du PNG")
        if max(image.size) > 2048 or (ROOT / (path + ".png")).stat().st_size >= 1048576:
            errors.append(f"{path}: budget de planche dépassé")
        if {value for _, value in image.getchannel("A").getcolors(256)} - {0, 255}:
            errors.append(f"{path}: alpha non binaire")
        allowed = contract["changed"]
        unchanged, heights = 0, {}
        idle = after["animations"]["repos"]["images"][0]
        idle_height = sheets.standing_height(sheets.crop(image, idle), idle)
        for name, anim in before["animations"].items():
            new_anim = after["animations"].get(name)
            if not new_anim:
                errors.append(f"{path}: animation supprimée {name}")
                continue
            for field in ("ips", "boucle", "coup", "onde"):
                if anim.get(field) != new_anim.get(field):
                    errors.append(f"{path}/{name}: contrat {field} modifié")
            if len(anim["images"]) != len(new_anim["images"]):
                errors.append(f"{path}/{name}: nombre de poses modifié")
            if allowed != "all" and name not in allowed:
                for index, (frame, new_frame) in enumerate(zip(anim["images"], new_anim["images"])):
                    if frame_hash(old_image, frame) != frame_hash(image, new_frame):
                        errors.append(f"{path}/{name}/{index}: pixels non concernés modifiés")
                    elif frame[4:] != new_frame[4:]:
                        errors.append(f"{path}/{name}/{index}: ancre non concernée modifiée")
                    else:
                        unchanged += 1
        for name, anim in after["animations"].items():
            values = []
            for index, frame in enumerate(anim["images"]):
                x, y, w, h, ax, ay = frame
                if x < 0 or y < 0 or w <= 0 or h <= 0 or x + w > image.width or y + h > image.height:
                    errors.append(f"{path}/{name}/{index}: cadre hors de la planche")
                    continue
                part = sheets.crop(image, frame)
                if not part.getchannel("A").getbbox():
                    errors.append(f"{path}/{name}/{index}: pose vide")
                if not (-2 <= ax <= w + 2 and -2 <= ay <= h + 2):
                    errors.append(f"{path}/{name}/{index}: ancre hors du cadre")
                value = sheets.standing_height(part, frame)
                values.append(value)
                expected = contract["heights"].get(name)
                expected = idle_height if expected == "idle" else expected
                # Le repos respiré garde la hauteur de la tête ; les attaques conservent leurs
                # proportions et peuvent dépasser le repos. Aucune hauteur bbox d'épée ici.
                if expected is not None and abs(value - expected) > 1:
                    errors.append(f"{path}/{name}/{index}: {value:g} px debout, attendu {expected:g}")
            heights[name] = values
        if path.split("/")[-2] == "willem":
            talk = after["animations"].get("parle", {})
            if talk.get("ips") != 6 or talk.get("boucle") is not True or len(talk.get("images", [])) != 2:
                errors.append(f"{path}: contrat du nouveau dialogue incorrect")
            elif frame_hash(image, talk["images"][0]) == frame_hash(image, talk["images"][1]):
                errors.append(f"{path}: les deux nouveaux dialogues sont identiques")
        entries.append({"path": path, "unchanged_frames": unchanged, "standing_heights": heights})
    for identifier in ("lakhesh", "ithea"):
        path = ROOT / f"assets/characters/{identifier}/{identifier}_portrait.png"
        if Image.open(path).size != (256, 256):
            errors.append(f"{identifier}: portrait différent de 256 × 256")
    for name, size in (("palisade_gate", (384, 288)), ("ring_stone", (58, 20))):
        image = Image.open(ROOT / f"assets/hd2d/props/{name}.png").convert("RGBA")
        if image.size != size:
            errors.append(f"{name}: taille différente de {size}")
        if {value for _, value in image.getchannel("A").getcolors(256)} - {0, 255}:
            errors.append(f"{name}: alpha non binaire")
        if image.getchannel("A").getbbox()[3] != image.height:
            errors.append(f"{name}: base ne touche pas le bord bas")
    # Sous la lanterne, le passage doit laisser 2,5 m × 96 px/m entre les battants.
    gate_alpha = Image.open(ROOT / "assets/hd2d/props/palisade_gate.png").getchannel("A")
    openings = []
    for y in range(125, 288):
        left = right = 192
        while left >= 0 and not gate_alpha.getpixel((left, y)):
            left -= 1
        while right < 384 and not gate_alpha.getpixel((right, y)):
            right += 1
        openings.append(right - left - 1)
    if min(openings) < 240:
        errors.append(f"palisade_gate: passage de {min(openings)} px, au lieu d'au moins 240")
    return {"base_commit": BASE, "sheets": entries, "errors": errors,
            "gate_opening_min_px": min(openings), "gate_opening_min_m": min(openings) / 96,
            "unchanged_frames": sum(e["unchanged_frames"] for e in entries),
            "artistic_review": "Manuel : identité, côté de la couette et de la queue, sens de l'arme, fluidité.",
            "technical_fitting": "Reductions NN de format/échelle (§2) ; nouveaux dessins via image_gen."}


def review(output, report):
    cards = []
    for path, contract in targets().items():
        identifier = path.split("/")[-2]
        suffix = path.rsplit("/", 1)[1].removeprefix(identifier)
        label = {"": "Profil droit", "_front": "Face", "_back": "Dos"}[suffix]
        after = json.loads(source(path + ".json"))
        before = json.loads(source(path + ".json", True))
        current_bytes = source(path + ".png")
        prior_bytes = source(path + ".png", True)
        clips = list(after["animations"]) if contract["changed"] == "all" else contract["changed"]
        options = "".join(f'<option value="{html.escape(n)}">{html.escape(n)}</option>' for n in clips)
        json_uri = "data:application/json;base64," + base64.b64encode(source(path + ".json")).decode("ascii")
        cards.append(f'''<section class="sheet" data-id="{identifier}" data-view="{suffix}">
<h2>{html.escape(identifier.capitalize())} · {label}</h2>
<label>Animation <select>{options}</select></label> <label><input type="checkbox" class="pause"> Pause</label>
<div class="comparison"><figure><canvas class="before"></canvas><figcaption>Avant — version de main</figcaption></figure>
<figure><canvas class="after"></canvas><figcaption>Correction · <span class="measure"></span></figcaption></figure></div>
<img hidden class="source-before" src="{png_uri(prior_bytes)}"><img hidden class="source-after" src="{png_uri(current_bytes)}">
<script type="application/json" class="meta-before">{json.dumps(before)}</script>
<script type="application/json" class="meta-after">{json.dumps(after)}</script>
<p><a class="download" data-source=".source-after" download="{Path(path).name}.png">PNG complet</a> · <a href="{json_uri}" download="{Path(path).name}.json">JSON d’animation</a></p>
<details><summary>Planche complète corrigée</summary><img class="full-sheet" alt="Planche complète corrigée"></details></section>''')
    portraits = []
    for identifier in ("ithea", "lakhesh"):
        relative = f"assets/characters/{identifier}/{identifier}_portrait.png"
        portraits.append(f'<figure><img class="portrait" src="{png_uri(source(relative))}"><figcaption>{identifier.capitalize()} · portrait corrigé</figcaption></figure>')
    props = []
    for name, label in (("palisade_gate", "Portail · passage ouvert de 2,5 m minimum"), ("ring_stone", "Pierre du cercle de veille · 58 × 20 px")):
        relative = f"assets/hd2d/props/{name}.png"
        props.append(f'<figure><img class="prop" src="{png_uri(source(relative))}"><figcaption>{label}</figcaption><a class="download" data-source=".prop" download="{name}.png">PNG</a></figure>')
    document = '''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="data:,"><title>WordEnd · Corrections de la section 12</title>
<style>body{margin:0;background:#252536;color:#ece9e0;font:16px/1.6 system-ui,sans-serif}main{max-width:1100px;margin:auto;padding:24px}h1,h2{color:#ffe0a0}section{margin:28px 0;padding:20px;background:#303044;border-radius:8px}select{font:inherit;padding:6px;margin:12px;color:inherit;background:#252536}input{margin-left:10px}.comparison,.portraits,.props{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}figure{margin:0;text-align:center}canvas{display:block;width:100%;height:340px;object-fit:contain;background:#39394d;image-rendering:pixelated}.portrait{width:256px;max-width:100%;image-rendering:pixelated}.prop{max-width:100%;image-rendering:pixelated;max-height:360px}.full-sheet{max-width:100%;image-rendering:pixelated}a{color:#b4d5ff;cursor:pointer}figcaption{padding:8px}nav a{display:inline-block;padding:5px 12px}summary{cursor:pointer}@media(max-width:600px){main{padding:12px}section{padding:12px}.comparison{grid-template-columns:1fr}canvas{height:300px}}</style>
<main><h1>Corrections HD-2D · section 12</h1>
<p>Comparaison des images utilisées par le jeu. Les animations suivent les cadences des JSON ; leurs pieds sont placés sur la même ligne de sol. Les anciennes versions restent conservées.</p>
<p>Ithea suit les planches officielles de l’anime, selon ton choix. Les ajustements de taille seuls utilisent le plus proche voisin autorisé par le cahier ; les nouvelles poses et corrections de dessin sont générées avec image_gen.</p>
<p>Cette page contient ses images et ses téléchargements : aucun dossier d’assets ni connexion n’est nécessaire. La fluidité des cycles reste à juger en jeu.</p>
<div class="portraits">''' + "".join(portraits) + '</div><section><h2>Décors corrigés</h2><div class="props">' + "".join(props) + '</div></section>' + "".join(cards) + '''</main>
<script>
const states=[];
document.querySelectorAll('.sheet').forEach(section=>{
 const select=section.querySelector('select');
 const current=JSON.parse(section.querySelector('.meta-after').textContent);
 const prior=JSON.parse(section.querySelector('.meta-before').textContent);
 const images=[section.querySelector('.source-before'),section.querySelector('.source-after')];
 section.querySelector('.full-sheet').src=images[1].src;
 const canvases=[section.querySelector('.before'),section.querySelector('.after')];
 for(const c of canvases){c.width=500;c.height=340;}
 const state={section,select,metadata:[prior,current],images,canvases,start:performance.now()};
 select.addEventListener('change',()=>{state.start=performance.now();});states.push(state);
});
function tick(now){for(const s of states){
 const name=s.select.value;
 for(let side=0;side<2;side++){
  const canvas=s.canvases[side],ctx=canvas.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,500,340);
  const clip=s.metadata[side].animations[name];if(!clip){ctx.fillStyle='#ece9e0';ctx.font='18px system-ui';ctx.fillText('Animation absente',150,175);continue;}
  if(!s.images[side].complete||!s.images[side].naturalWidth)continue;
  const elapsed=s.section.querySelector('.pause').checked?0:Math.max(0,now-s.start)/1000;
  const n=Math.floor(elapsed*clip.ips),index=clip.boucle?n%clip.images.length:Math.min(n%(clip.images.length+8),clip.images.length-1);
  const frame=clip.images[index],scale=Math.min(2,450/Math.max(...clip.images.map(f=>f[2])),290/Math.max(...clip.images.map(f=>f[5])));
  const [x,y,w,h,ax,ay]=frame,ground=310;
  ctx.strokeStyle='#777789';ctx.beginPath();ctx.moveTo(0,ground);ctx.lineTo(500,ground);ctx.stroke();
  ctx.drawImage(s.images[side],x,y,w,h,Math.round(250-ax*scale),Math.round(ground-ay*scale),Math.round(w*scale),Math.round(h*scale));
  if(side===1)s.section.querySelector('.measure').textContent=`pose ${index+1}/${clip.images.length} · ${clip.ips} images/s`;
 }
}requestAnimationFrame(tick);}requestAnimationFrame(tick);
document.querySelectorAll('.download').forEach(a=>{a.addEventListener('click',e=>{e.preventDefault();const parent=a.closest('section,figure'),im=parent.querySelector(a.dataset.source);const encoded=im.src.split(',')[1],bytes=Uint8Array.from(atob(encoded),c=>c.charCodeAt(0)),url=URL.createObjectURL(new Blob([bytes],{type:'image/png'}));const link=document.createElement('a');link.href=url;link.download=a.download;link.click();setTimeout(()=>URL.revokeObjectURL(url),30000);});});
</script></html>'''
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(document, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/sprites/CORRECTIONS_SECTION12.html")
    parser.add_argument("--report", type=Path, default=ROOT / "build/section12-validation.json")
    args = parser.parse_args()
    report = validate()
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    review(args.output, report)
    print(f"{len(report['sheets'])} vues ; {report['unchanged_frames']} poses non concernées préservées ; {len(report['errors'])} écarts")
    for error in report["errors"]:
        print(error)
    return bool(report["errors"])


if __name__ == "__main__":
    raise SystemExit(main())
