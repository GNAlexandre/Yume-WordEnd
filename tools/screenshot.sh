#!/bin/bash
# Rend une scène en PNG sous Xvfb (Mesa logiciel, 1280 × 720), puis ouvre le PNG pour le vérifier.
# Usage : tools/screenshot.sh res://chemin/scene.tscn build/shots/nom.png [images à attendre]
# Code 2 : environnement sans affichage virtuel (xvfb-run absent) ; la capture est alors sautée.
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# -ge 2 ] || { echo "usage : tools/screenshot.sh res://scene.tscn sortie.png [images]"; exit 2; }
command -v xvfb-run >/dev/null || { echo "xvfb-run absent"; exit 2; }
out="$2"
case "$out" in /*) ;; *) out="$PWD/$out" ;; esac
mkdir -p "$(dirname "$out")"
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1280x720x24" \
  tools/godot --rendering-driver opengl3 --resolution 1280x720 \
  --script tools/screenshot.gd -- "$1" "$out" ${3:+"$3"}
