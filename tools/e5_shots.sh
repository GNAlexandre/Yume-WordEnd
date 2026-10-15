#!/bin/bash
# (E5) Captures de la faune (tests/integration/demo_e5.tscn) sous Xvfb : la forêt d'essai (carte
# foret_essai) avec ses animaux, une vue par scénario (cerfs qui fuient, écureuils, meute au
# couchant, sanglier qui gratte, ours qui se dresse, troupeau de douze pour les draw calls).
#   tools/e5_shots.sh                      # toutes les vues → build/shots/e5/e5_<vue>.png
#   tools/e5_shots.sh meute sanglier       # seulement celles-ci
# Journal : build/shots/e5/e5.log (lignes « E5 vue … »). Code 1 si une vue n'atteint pas l'état
# attendu (la meute n'attaque jamais…), 2 sans affichage virtuel (xvfb-run absent).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
command -v xvfb-run >/dev/null || { echo "xvfb-run absent"; exit 2; }
out="build/shots/e5"
mkdir -p "$out"
views=""
if [ $# -gt 0 ]; then
  views=$(IFS=,; echo "$*")
fi
# Au plus E5_TIMEOUT s (900 par défaut) : une démo qui ne compile pas ne quitte jamais.
E5_SHOTS="res://$out" E5_VIEWS="$views" LIBGL_ALWAYS_SOFTWARE=1 \
  timeout "${E5_TIMEOUT:-900}" xvfb-run -a -s "-screen 0 1280x720x24" \
  tools/godot --rendering-driver opengl3 --resolution 1280x720 \
  res://tests/integration/demo_e5.tscn > "$out/e5.log" 2>&1
code=$?
grep -E "^E5 |SCRIPT ERROR" "$out/e5.log"
grep -q "^E5 fin" "$out/e5.log" || code=1
exit $code
