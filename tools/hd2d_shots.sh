#!/bin/bash
# Captures HD-2D de la vraie partie (tests/integration/demo_hd2d.tscn), une par vue :
#   tools/hd2d_shots.sh                 # toutes les vues → build/shots/hd2d_<vue>.png
#   tools/hd2d_shots.sh village dunes   # seulement celles-ci
# Ouvre ensuite chaque PNG avec l'outil de lecture d'images. Les draw calls mesurés sont dans
# build/shots/hd2d_<vue>.log (ligne « HD-2D vue … »).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
views=("$@")
if [ ${#views[@]} -eq 0 ]; then
  views=(menu village entrepot forest dunes beach hill dialogue vigil)
fi
mkdir -p build/shots
status=0
for view in "${views[@]}"; do
  if HD2D_VIEW="$view" tools/screenshot.sh res://tests/integration/demo_hd2d.tscn \
    "build/shots/hd2d_$view.png" 60 > "build/shots/hd2d_$view.log" 2>&1; then
    line=$(grep -o "HD-2D vue.*" "build/shots/hd2d_$view.log" | head -1)
    echo "build/shots/hd2d_$view.png ${line:-}"
  else
    echo "ÉCHEC $view (build/shots/hd2d_$view.log)"
    status=1
  fi
done
exit $status
