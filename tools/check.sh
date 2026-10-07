#!/bin/bash
# tools/check.sh — le « vert » du projet (PLAN.md section 9) : même commande en cloud, en local
# et en CI. Se lance depuis n'importe où, dans n'importe quel worktree (tout est relatif à la
# racine du dépôt qui contient ce script).
#
# Étapes : import, lint, tests GUT, fumée, export Web, capture de l'île. ROUGE (code 1) si :
#   - l'import, la fumée ou l'export impriment une erreur (ERROR:, SCRIPT ERROR, SHADER ERROR,
#     Parse Error…) ou un WARNING absent de tools/warnings_allow.txt ;
#   - gdlint ou gdformat --check échouent ;
#   - un test GUT échoue, ou un script / fichier de test ne compile pas (GUT l'ignorerait
#     sans échouer) ;
#   - une scène ne s'instancie pas (tools/smoke.gd) ;
#   - l'export Web échoue ou ne produit pas index.html / .js / .wasm / .pck, ou dépasse le budget
#     de taille (tools/build_size.sh : 25 Mo compressés) ;
#   - la capture a été rendue mais son journal contient une erreur ou un WARNING non toléré ;
#   - en CI (CI=true), des fichiers ont été générés ou modifiés (.uid, .import non commités).
# CHECK_FAST=1 saute l'export et la capture (itérations rapides ; jamais avant une PR).
# Journaux dans build/ : import.log, lint.log, tests.log (+ junit.xml), smoke.log, export.log,
# capture.log ; capture : build/shots/island.png.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
G="$PWD/tools/godot"
START=$(date +%s)
mkdir -p build/shots

step() { echo; echo "== $1"; }
red() {
  echo
  echo "ROUGE : $1"
  exit 1
}
strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }

# Liste blanche effective : sans commentaires ni lignes vides (une ligne vide tolérerait tout).
ALLOW="build/warnings_allow.effective"
grep -v -E '^[[:space:]]*(#|$)' tools/warnings_allow.txt > "$ALLOW" 2>/dev/null || : > "$ALLOW"

# scan_log <journal> <étape> <mode> : mode "strict" (toute erreur, WARNING non toléré) ou
# "compile" (erreurs de compilation seulement : journal des tests, où des push_error attendus
# s'affichent légitimement).
scan_log() {
  local log="$1" label="$2" mode="$3" errors warnings
  if [ "$mode" = "strict" ]; then
    errors=$(strip_ansi < "$log" | grep -E "ERROR:|SCRIPT ERROR|SHADER ERROR|USER ERROR|Parse Error|Compile Error")
    warnings=$(strip_ansi < "$log" | grep -E "WARNING" | grep -v -F -f "$ALLOW")
  else
    errors=$(strip_ansi < "$log" | grep -E "SCRIPT ERROR|SHADER ERROR|Parse Error|Compile Error|Failed to load script")
    warnings=""
  fi
  if [ -n "$errors" ]; then
    echo "$errors" | head -40
    red "erreurs pendant l'étape $label ($log)"
  fi
  if [ -n "$warnings" ]; then
    echo "$warnings" | head -40
    red "avertissements non tolérés pendant l'étape $label ($log) ; s'ils sont légitimes, ajoute-les à tools/warnings_allow.txt avec un commentaire"
  fi
}

STATUS_BEFORE=$(git status --porcelain --untracked-files=all 2>/dev/null || true)

step "import"
"$G" --headless --import > build/import.log 2>&1
code=$?
scan_log build/import.log import strict
[ "$code" -eq 0 ] || red "import (code $code, build/import.log)"
echo "ok"

step "lint"
command -v gdlint >/dev/null 2>&1 || red "gdlint absent : lance tools/setup.sh"
if ! gdlint src tests tools > build/lint.log 2>&1; then
  cat build/lint.log
  red "gdlint"
fi
if ! gdformat --check src tests tools >> build/lint.log 2>&1; then
  grep -v "would be left unchanged" build/lint.log
  red "gdformat --check (corrige avec : gdformat src tests tools)"
fi
echo "ok"

step "tests"
"$G" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gprefix=test_ \
  -gsuffix=.gd -gexit -gjunit_xml_file=build/junit.xml > build/tests.log 2>&1
code=$?
strip_ansi < build/tests.log | grep -E "^(Scripts|Tests|Passing Tests|Failing Tests|Risky|Pending|Asserts) "
scan_log build/tests.log tests compile
if [ "$code" -ne 0 ]; then
  strip_ansi < build/tests.log | grep -B3 -A8 "\[Failed\]" | head -80
  red "tests GUT (code $code, build/tests.log)"
fi

step "smoke"
"$G" --headless --script tools/smoke.gd > build/smoke.log 2>&1
code=$?
scan_log build/smoke.log smoke strict
if [ "$code" -ne 0 ]; then
  grep "SMOKE" build/smoke.log
  red "scène ou script en échec (build/smoke.log)"
fi
grep "^smoke" build/smoke.log

if [ "${CHECK_FAST:-0}" = "1" ]; then
  echo
  echo "CHECK_FAST=1 : export Web et capture sautés (ce n'est pas un vert complet)"
else
  step "export web"
  rm -rf build/web
  mkdir -p build/web
  "$G" --headless --export-release Web build/web/index.html > build/export.log 2>&1
  code=$?
  scan_log build/export.log export strict
  [ "$code" -eq 0 ] || red "export Web (code $code, build/export.log)"
  for f in index.html index.js index.wasm index.pck; do
    [ -s "build/web/$f" ] || red "export Web : build/web/$f manquant"
  done
  packed=$(cat build/web/index.wasm build/web/index.pck | gzip -c | wc -c)
  echo "build/web : $(du -sh build/web | cut -f1) ; wasm + pck compressés : $((packed / 1048576)) Mo (budget M2 : 25 Mo)"
  # (HD-2D) Le budget est vérifié, plus seulement affiché : au-delà de 25 Mo, rouge.
  if ! tools/build_size.sh build/web > build/size.log 2>&1; then
    cat build/size.log
    red "export Web au-delà du budget de taille (tools/build_size.sh, build/size.log)"
  fi

  step "capture"
  tools/screenshot.sh res://src/world/island.tscn build/shots/island.png > build/capture.log 2>&1
  code=$?
  case "$code" in
    0)
      scan_log build/capture.log capture strict
      echo "build/shots/island.png"
      ;;
    2) echo "capture sautée (pas d'affichage virtuel : xvfb-run absent)" ;;
    *) echo "ATTENTION : capture impossible (code $code, build/capture.log) : environnement graphique ?" ;;
  esac
fi

STATUS_AFTER=$(git status --porcelain --untracked-files=all 2>/dev/null || true)
CHANGED=$(comm -13 <(echo "$STATUS_BEFORE" | sort) <(echo "$STATUS_AFTER" | sort) | grep -v '^$')
if [ -n "$CHANGED" ]; then
  echo
  echo "Fichiers créés ou modifiés par la vérification :"
  echo "$CHANGED"
  [ "${CI:-}" = "true" ] && red "fichiers générés non commités (commite les .uid et .import)"
  echo "ATTENTION : commite-les avec le fichier qui les a fait naître (.uid d'un script, .import d'un asset)."
fi

echo
echo "VERT ($(($(date +%s) - START)) s)"
