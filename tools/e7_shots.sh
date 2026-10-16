#!/bin/bash
# (E7) Captures des navires (tests/integration/demo_e7.tscn) sous Xvfb : la descente du transport
# de la Garde au port (une image toutes les 0,5 s de jeu), la trappe, la passerelle, le départ, le
# pont du transport, l'intérieur du Barocupot, l'ombre du Barocupot dans les nuages de la colline.
#   tools/e7_shots.sh                     # tout → build/e7/shots/
#   tools/e7_shots.sh descente ombre      # seulement ces séries (descente, depart, cartes, ombre)
# Journal : build/e7/shots/e7.log (lignes « E7 vue … : draw calls »). Code 1 si la démo échoue, 2
# sans affichage virtuel (xvfb-run absent).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
command -v xvfb-run >/dev/null || { echo "xvfb-run absent"; exit 2; }
out="build/e7/shots"
mkdir -p "$out"
select=""
if [ $# -gt 0 ]; then
  select=$(IFS=,; echo "$*")
fi
E7_SHOTS="res://$out" E7_SELECT="$select" LIBGL_ALWAYS_SOFTWARE=1 \
  timeout "${E7_TIMEOUT:-1800}" xvfb-run -a -s "-screen 0 1280x720x24" \
  tools/godot --rendering-driver opengl3 --resolution 1280x720 \
  res://tests/integration/demo_e7.tscn > "$out/e7.log" 2>&1
code=$?
sed 's/\x1b\[[0-9;]*m//g' "$out/e7.log" | grep -E "^E7 |SCRIPT ERROR|SHADER ERROR" | tail -80
grep -q "^E7 fin" "$out/e7.log" || code=1
exit $code
