#!/bin/bash
# Captures HD-2D de la vraie partie (tests/integration/demo_hd2d.tscn), une par vue :
#   tools/hd2d_shots.sh                 # toutes les vues → build/shots/hd2d_<vue>.png
#   tools/hd2d_shots.sh village dunes   # seulement celles-ci
#   tools/hd2d_shots.sh quai fondu essai retour   # (E1) les cartes : sortie, fondu, essai, retour
# Ouvre ensuite chaque PNG avec l'outil de lecture d'images. Les draw calls mesurés sont dans
# build/shots/hd2d_<vue>.log (ligne « HD-2D vue … »).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
views=("$@")
if [ ${#views[@]} -eq 0 ]; then
  views=(menu village entrepot forest dunes beach hill dialogue vigil quai fondu essai retour)
fi
mkdir -p build/shots
status=0
for view in "${views[@]}"; do
  # (E1) Les vues de cartes attendent la fin des changements de carte (l'île rechargée).
  frames=60
  case "$view" in quai | fondu | essai | retour) frames=160 ;; esac
  if HD2D_VIEW="$view" tools/screenshot.sh res://tests/integration/demo_hd2d.tscn \
    "build/shots/hd2d_$view.png" "$frames" > "build/shots/hd2d_$view.log" 2>&1; then
    line=$(grep -o "HD-2D vue.*" "build/shots/hd2d_$view.log" | head -1)
    echo "build/shots/hd2d_$view.png ${line:-}"
  else
    echo "ÉCHEC $view (build/shots/hd2d_$view.log)"
    status=1
  fi
done
exit $status
