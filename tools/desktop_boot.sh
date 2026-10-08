#!/bin/bash
# tools/desktop_boot.sh — l'application de bureau exportée démarre-t-elle ? (bureau, docs/bureau.md)
#
# Lance le build Linux (le même pck que l'exe Windows : préréglage « Linux » d'export_presets.cfg,
# fait par tools/build_desktop.sh --linux) deux fois sur un profil neuf, avec l'argument
# utilisateur --desktop-check=<phase> (src/desktop_check.gd, dans le pck : un jeu exporté ignore
# --script) :
#   first  : « Cliquer pour jouer », menu avec « Plein écran » et « Quitter », F11 et Alt+Entrée
#            (plein écran mémorisé), nouvelle partie jusqu'au joueur, pause → « Quitter le jeu » ;
#   resume : plein écran rétabli au lancement, « Continuer », pause → « Quitter le jeu ».
# Dossiers utilisateur isolés et vidés au départ : build/desktop/xdg (user:// y est
# build/desktop/xdg/data/WordEnd). Journal sans erreur ni avertissement non toléré
# (tools/warnings_allow.txt) exigé.
#
# Usage :
#   tools/desktop_boot.sh                        # sans écran (--headless)
#   tools/desktop_boot.sh --xvfb [capture.png]   # sous Xvfb (écran 1920 × 1080, Mesa logiciel),
#                                                # capture du menu (défaut build/shots/bureau_menu.png) ;
#                                                # avec openbox s'il est installé (sans gestionnaire de
#                                                # fenêtres, X11 n'a pas de vrai plein écran)
#   DESKTOP_BIN=<binaire> tools/desktop_boot.sh  # autre binaire (défaut build/desktop/linux/WordEnd.x86_64)
# Journaux : build/desktop/boot_first.log, build/desktop/boot_resume.log. Code 0 si tout va bien,
# 1 sinon, 2 si le binaire (ou Xvfb) manque.
set -uo pipefail

# Session graphique interne (appelée par xvfb-run) : gestionnaire de fenêtres, puis le jeu.
if [ "${1:-}" = "--display-session" ]; then
  shift
  if command -v openbox >/dev/null 2>&1; then
    openbox > /dev/null 2>&1 &
    sleep 1
  else
    set -- "$@" "--desktop-no-wm"
  fi
  exec "$@"
fi

cd "$(dirname "$0")/.." || exit 1
ROOT="$PWD"
BIN="${DESKTOP_BIN:-build/desktop/linux/WordEnd.x86_64}"
XVFB=0
SHOT=""
if [ "${1:-}" = "--xvfb" ]; then
  XVFB=1
  SHOT="${2:-build/shots/bureau_menu.png}"
  command -v xvfb-run >/dev/null 2>&1 || { echo "xvfb-run absent"; exit 2; }
fi
[ -f "$BIN" ] || { echo "binaire absent : $BIN (lance tools/build_desktop.sh --linux)"; exit 2; }
mkdir -p build/desktop build/shots

base="$ROOT/build/desktop/xdg"
rm -rf "$base"
mkdir -p "$base/data" "$base/config" "$base/cache"
export XDG_DATA_HOME="$base/data" XDG_CONFIG_HOME="$base/config" XDG_CACHE_HOME="$base/cache"

allow="build/desktop/warnings_allow.effective"
grep -v -E '^[[:space:]]*(#|$)' tools/warnings_allow.txt > "$allow" 2>/dev/null || : > "$allow"

status=0
for phase in first resume; do
  log="build/desktop/boot_$phase.log"
  user_args=("--desktop-check=$phase")
  if [ -n "$SHOT" ]; then
    # first : <capture>.png (menu) et <capture>_pause.png ; resume : <capture>_reprise*.png.
    shot="$ROOT/${SHOT%.png}.png"
    [ "$phase" = "resume" ] && shot="$ROOT/${SHOT%.png}_reprise.png"
    user_args+=("--desktop-shot=$shot")
  fi
  if [ "$XVFB" = "1" ]; then
    LIBGL_ALWAYS_SOFTWARE=1 timeout 300 xvfb-run -a -s "-screen 0 1920x1080x24" \
      "$ROOT/tools/desktop_boot.sh" --display-session "$BIN" \
      --rendering-driver opengl3 --audio-driver Dummy -- "${user_args[@]}" > "$log" 2>&1
  else
    timeout 300 "$BIN" --headless -- "${user_args[@]}" > "$log" 2>&1
  fi
  code=$?
  clean=$(sed 's/\x1b\[[0-9;]*m//g' "$log" | tr -d '\r')
  echo "$clean" | grep -E "^\[bureau\]|DESKTOP BOOT"
  errors=$(echo "$clean" | grep -E "ERROR:|SCRIPT ERROR|SHADER ERROR|Parse Error|DESKTOP BOOT ÉCHEC")
  warnings=$(echo "$clean" | grep "WARNING" | grep -v -F -f "$allow")
  if [ "$code" -ne 0 ] || [ -n "$errors" ] || [ -n "$warnings" ] \
    || ! echo "$clean" | grep -q "DESKTOP BOOT OK"; then
    [ -n "$errors$warnings" ] && printf '%s\n%s\n' "$errors" "$warnings" | head -40
    echo "ÉCHEC : phase $phase (code $code, $log)"
    status=1
    break
  fi
done
if [ "$status" -eq 0 ]; then
  echo "application de bureau : démarrage vérifié ($([ "$XVFB" = 1 ] && echo Xvfb || echo sans écran))"
fi
[ -n "$SHOT" ] && ls "${SHOT%.png}"*.png 2>/dev/null | sed "s/^/capture : /"
exit $status
