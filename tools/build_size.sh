#!/bin/bash
# tools/build_size.sh — taille du build Web (wasm + pck) brute et compressée (gzip -6, ce que fait
# un hébergement comme GitHub Pages) comparée au budget du jalon (PLAN.md section 9 : 25 Mo
# compressés jusqu'à M3, 60 Mo à M4). Utilisable en local et en CI.
#
#   tools/build_size.sh                      # build/web, budget 25 Mo
#   tools/build_size.sh build/web 60         # autre dossier, autre budget (Mo = 1 048 576 octets)
#   BUILD_BUDGET_MB=60 tools/build_size.sh   # budget par variable d'environnement
#   tools/build_size.sh --summary            # en plus, tableau dans $GITHUB_STEP_SUMMARY (CI)
#
# Code 0 : sous le budget ; 1 : au-delà ; 2 : build absent (lancer l'export d'abord :
# tools/godot --headless --export-release Web build/web/index.html).
set -euo pipefail
cd "$(dirname "$0")/.." || exit 2

summary=0
if [ "${1:-}" = "--summary" ]; then
  summary=1
  shift
fi
dir="${1:-build/web}"
budget_mb="${2:-${BUILD_BUDGET_MB:-25}}"
case "$budget_mb" in
  '' | *[!0-9]*) echo "budget invalide : $budget_mb (entier en Mo)"; exit 2 ;;
esac
budget=$((budget_mb * 1048576))

mo() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1048576 }' | tr . ,; }

shopt -s nullglob
files=("$dir"/*.wasm "$dir"/*.pck)
if [ "${#files[@]}" -eq 0 ]; then
  echo "build absent : aucun .wasm ni .pck dans $dir"
  echo "lance d'abord : tools/godot --headless --export-release Web build/web/index.html"
  exit 2
fi

rows=""
raw_total=0
gz_total=0
for f in "${files[@]}"; do
  raw=$(wc -c < "$f" | tr -d ' ')
  gz=$(gzip -6 -c "$f" | wc -c | tr -d ' ')
  raw_total=$((raw_total + raw))
  gz_total=$((gz_total + gz))
  rows="$rows| $(basename "$f") | $(mo "$raw") Mo | $(mo "$gz") Mo |"$'\n'
  printf "%-28s brut %8s Mo   gzip %8s Mo\n" "$(basename "$f")" "$(mo "$raw")" "$(mo "$gz")"
done
dir_total=0
for f in "$dir"/*; do
  [ -f "$f" ] && dir_total=$((dir_total + $(wc -c < "$f" | tr -d ' ')))
done

verdict="sous le budget"
code=0
if [ "$gz_total" -gt "$budget" ]; then
  verdict="AU-DELÀ DU BUDGET"
  code=1
fi
echo "wasm + pck : brut $(mo "$raw_total") Mo, compressé $(mo "$gz_total") Mo ; budget $budget_mb Mo compressés : $verdict"
echo "dossier $dir complet (brut) : $(mo "$dir_total") Mo"

if [ "$summary" = "1" ] && [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Taille du build Web"
    echo
    echo "| Fichier | Brut | gzip |"
    echo "| --- | --- | --- |"
    printf "%s" "$rows"
    echo "| **wasm + pck** | **$(mo "$raw_total") Mo** | **$(mo "$gz_total") Mo** |"
    echo
    echo "Budget : $budget_mb Mo compressés ($verdict)."
  } >> "$GITHUB_STEP_SUMMARY"
fi
exit "$code"
