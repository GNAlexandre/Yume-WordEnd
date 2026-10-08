#!/bin/bash
# tools/build_desktop.sh — application de bureau Windows (bureau, docs/bureau.md) :
#   1. import Godot ;
#   2. export « Windows Desktop » d'export_presets.cfg (x86_64, pck dans l'exe, icône et
#      métadonnées écrites par Godot lui-même) → build/desktop/windows/WordEnd.exe ;
#   3. installateur NSIS (tools/installer/wordend.nsi, avertissements = erreurs) →
#      build/dist/WordEnd-Setup-<version>.exe ;
#   4. zip portable (l'exe seul) → build/dist/WordEnd-<version>-windows-portable.zip.
# La version vient de project.godot (application/config/version), seule source : Godot la met
# dans l'exe, ce script dans l'installateur et les noms de fichiers.
#
# Options :
#   --linux          exporte aussi « Linux » (build/desktop/linux/WordEnd.x86_64, même pck) et
#                    vérifie que l'application démarre, sans écran (tools/desktop_boot.sh)
#   --no-installer   export Windows seulement (ni makensis ni zip)
# Journaux : build/desktop/*.log. En CI (GITHUB_STEP_SUMMARY défini), les tailles vont dans le
# résumé du job. Prérequis : bash tools/setup.sh (Godot 4.7.2, template
# windows_release_x86_64.exe, et linux_release.x86_64 pour --linux ; nsis et zip).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
ROOT="$PWD"
G="$ROOT/tools/godot"
START=$(date +%s)

LINUX=0
INSTALLER=1
for argument in "$@"; do
  case "$argument" in
    --linux) LINUX=1 ;;
    --no-installer) INSTALLER=0 ;;
    *) echo "option inconnue : $argument"; exit 2 ;;
  esac
done

red() {
  echo
  echo "ÉCHEC : $1"
  exit 1
}
strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }
# Taille d'un fichier en Mo, une décimale, virgule française.
megabytes() { awk -v b="$(stat -c %s "$1")" 'BEGIN { printf "%.1f", b / 1048576 }' | tr . ,; }

mkdir -p build/desktop build/dist
ALLOW="build/desktop/warnings_allow.effective"
grep -v -E '^[[:space:]]*(#|$)' tools/warnings_allow.txt > "$ALLOW" 2>/dev/null || : > "$ALLOW"

# Même règle que tools/check.sh : erreur ou avertissement non toléré = échec.
scan_log() {
  local log="$1" label="$2" errors warnings
  errors=$(strip_ansi < "$log" | grep -E "ERROR:|SCRIPT ERROR|SHADER ERROR|USER ERROR|Parse Error|Compile Error")
  warnings=$(strip_ansi < "$log" | grep -E "WARNING" | grep -v -F -f "$ALLOW")
  if [ -n "$errors$warnings" ]; then
    printf '%s\n%s\n' "$errors" "$warnings" | head -40
    red "$label : erreurs ou avertissements ($log)"
  fi
}

VERSION=$(sed -n 's/^config\/version="\([^"]*\)"$/\1/p' project.godot | head -n 1)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || red "version introuvable ou invalide dans project.godot (application/config/version = X.Y.Z) : « $VERSION »"
echo "WordEnd $VERSION"
if [ "$INSTALLER" = "1" ]; then
  command -v makensis >/dev/null 2>&1 || red "makensis absent : bash tools/setup.sh (paquet nsis)"
  command -v zip >/dev/null 2>&1 || red "zip absent : bash tools/setup.sh"
fi

echo "== import"
"$G" --headless --import > build/desktop/import.log 2>&1 || red "import (build/desktop/import.log)"
scan_log build/desktop/import.log import

echo "== export Windows"
EXE="build/desktop/windows/WordEnd.exe"
rm -rf build/desktop/windows
mkdir -p build/desktop/windows
"$G" --headless --export-release "Windows Desktop" "$EXE" > build/desktop/export_windows.log 2>&1 \
  || red "export Windows (build/desktop/export_windows.log)"
scan_log build/desktop/export_windows.log "export Windows"
[ -s "$EXE" ] || red "export Windows : $EXE manquant"
echo "$EXE : $(megabytes "$EXE") Mo"

SETUP="build/dist/WordEnd-Setup-$VERSION.exe"
PORTABLE="build/dist/WordEnd-$VERSION-windows-portable.zip"
if [ "$INSTALLER" = "1" ]; then
  echo "== installateur"
  rm -f build/dist/WordEnd-*
  makensis -V2 -WX -INPUTCHARSET UTF8 "-DVERSION=$VERSION" "-DEXE=$ROOT/$EXE" \
    "-DOUTFILE=$ROOT/$SETUP" tools/installer/wordend.nsi > build/desktop/makensis.log 2>&1 \
    || { cat build/desktop/makensis.log; red "makensis (build/desktop/makensis.log)"; }
  [ -s "$SETUP" ] || red "installateur manquant : $SETUP"
  echo "$SETUP : $(megabytes "$SETUP") Mo"
  (cd build/desktop/windows && zip -9 -q -X "$ROOT/$PORTABLE" WordEnd.exe) || red "zip portable"
  echo "$PORTABLE : $(megabytes "$PORTABLE") Mo"
fi

if [ "$LINUX" = "1" ]; then
  echo "== export Linux"
  BIN="build/desktop/linux/WordEnd.x86_64"
  rm -rf build/desktop/linux
  mkdir -p build/desktop/linux
  "$G" --headless --export-release "Linux" "$BIN" > build/desktop/export_linux.log 2>&1 \
    || red "export Linux (build/desktop/export_linux.log)"
  scan_log build/desktop/export_linux.log "export Linux"
  [ -s "$BIN" ] || red "export Linux : $BIN manquant"
  echo "$BIN : $(megabytes "$BIN") Mo"
  echo "== démarrage (sans écran)"
  DESKTOP_BIN="$BIN" tools/desktop_boot.sh > build/desktop/boot.log 2>&1 \
    || { cat build/desktop/boot.log; red "l'application ne démarre pas (build/desktop/boot.log)"; }
  tail -n 1 build/desktop/boot.log
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Application de bureau WordEnd $VERSION"
    echo
    echo "| Fichier | Taille |"
    echo "| --- | --- |"
    echo "| \`WordEnd.exe\` (pck intégré) | $(megabytes "$EXE") Mo |"
    if [ "$INSTALLER" = "1" ]; then
      echo "| \`$(basename "$SETUP")\` (installateur) | **$(megabytes "$SETUP") Mo** |"
      echo "| \`$(basename "$PORTABLE")\` (exe seul) | $(megabytes "$PORTABLE") Mo |"
    fi
    if [ "$LINUX" = "1" ]; then
      echo "| \`WordEnd.x86_64\` (Linux, même pck ; démarrage vérifié sans écran) | $(megabytes "build/desktop/linux/WordEnd.x86_64") Mo |"
    fi
    echo
    echo "Le budget de 60 Mo ne concerne que le Web."
  } >> "$GITHUB_STEP_SUMMARY"
fi

echo
echo "FAIT ($(($(date +%s) - START)) s)"
