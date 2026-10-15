#!/bin/bash
# (QC) La série standard de vues du garant de la qualité visuelle (docs/QUALITE.md) : toutes les
# cartes de l'île n° 68 dans la vraie partie (tests/integration/demo_qc.tscn sous Xvfb), d'après
# tools/qc_views.json, puis une planche contact par carte.
#   tools/qc_shots.sh                         # tout → build/qc/<date>/
#   tools/qc_shots.sh village cafe:salle      # seulement ces cartes ou ces vues
#   tools/qc_shots.sh village:rue:nuit:pluie  # une seule capture
#   QC_OUT=build/qc/apres tools/qc_shots.sh village:rue   # ailleurs (avant / après)
# Sortie : <dossier>/<carte>_<vue>_<moment>[_<temps>].png, index.tsv (draw calls, luminance),
# qc.log (lignes « QC vue … »), contact_<carte>.png. Code 1 si la liste des vues ne couvre pas
# l'île (tools/qc_tool.py check) ou si la démo échoue, 2 sans affichage virtuel.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
command -v xvfb-run >/dev/null || { echo "xvfb-run absent"; exit 2; }
python3 tools/qc_tool.py check || exit 1
out="${QC_OUT:-build/qc/$(date +%F)}"
out="${out%/}"
mkdir -p "$out"
select=""
if [ $# -gt 0 ]; then
  select=$(IFS=,; echo "$*")
fi
# Au plus QC_TIMEOUT s (5400 par défaut) : une démo qui ne compile pas ne quitte jamais.
QC_SHOTS="res://$out" QC_SELECT="$select" LIBGL_ALWAYS_SOFTWARE=1 \
  timeout "${QC_TIMEOUT:-5400}" xvfb-run -a -s "-screen 0 1280x720x24" \
  tools/godot --rendering-driver opengl3 --resolution 1280x720 \
  res://tests/integration/demo_qc.tscn >> "$out/qc.log" 2>&1
code=$?
sed 's/\x1b\[[0-9;]*m//g' "$out/qc.log" | grep -E "^QC fin|SCRIPT ERROR|SHADER ERROR" | tail -5
grep -q "^QC fin" "$out/qc.log" || code=1
python3 tools/qc_tool.py contact "$out" || code=1
exit $code
