#!/bin/bash
# (E9) Captures de la lumière et du temps (tests/integration/demo_e9.tscn) sous Xvfb : la même
# vue sous chaque préréglage (moment × temps), dans le village de l'ancienne île et la carte
# d'essai, avec la luminance moyenne et les draw calls de chacune.
#   tools/e9_shots.sh                          # toutes les vues → build/shots/e9/e9_<vue>.png
#   tools/e9_shots.sh village:nuit:clair essai:couchant:pluie   # seulement celles-ci
# Journal : build/shots/e9/e9.log (lignes « E9 vue … »). Code 1 si une vue est sous le seuil de
# luminance (demo_e9.gd, LUMA_FLOOR), 2 sans affichage virtuel (xvfb-run absent).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
command -v xvfb-run >/dev/null || { echo "xvfb-run absent"; exit 2; }
out="build/shots/e9"
mkdir -p "$out"
views=""
if [ $# -gt 0 ]; then
  views=$(IFS=,; echo "$*")
fi
# Au plus E9_TIMEOUT s (900 par défaut) : une démo qui ne compile pas ne quitte jamais.
E9_SHOTS="res://$out" E9_VIEWS="$views" LIBGL_ALWAYS_SOFTWARE=1 \
  timeout "${E9_TIMEOUT:-900}" xvfb-run -a -s "-screen 0 1280x720x24" \
  tools/godot --rendering-driver opengl3 --resolution 1280x720 \
  res://tests/integration/demo_e9.tscn > "$out/e9.log" 2>&1
code=$?
grep -E "^E9 |SCRIPT ERROR" "$out/e9.log"
grep -q "^E9 fin" "$out/e9.log" || code=1
exit $code
