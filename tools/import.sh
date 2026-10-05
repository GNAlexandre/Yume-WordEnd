#!/bin/bash
# Import headless : crée les .uid des scripts et les .import des assets, puis liste ce qu'il
# faut commiter et les fichiers générés devenus orphelins (source renommée ou supprimée).
# À lancer après avoir créé, renommé ou supprimé un script, une scène ou un asset.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p build
tools/godot --headless --import > build/import.log 2>&1
code=$?
sed 's/\x1b\[[0-9;]*m//g' build/import.log | grep -E "ERROR|WARNING" || true

generated=$(git ls-files --others --exclude-standard 2>/dev/null | grep -E "\.(uid|import)$")
if [ -n "$generated" ]; then
  echo "À commiter (générés par l'import) :"
  echo "$generated" | sed 's/^/  /'
fi

orphans=""
while IFS= read -r file; do
  [ -n "$file" ] || continue
  source="${file%.uid}"
  source="${source%.import}"
  [ -e "$source" ] || orphans="$orphans  $file"$'\n'
done < <(git ls-files --cached --others --exclude-standard 2>/dev/null | grep -E "\.(uid|import)$")
if [ -n "$orphans" ]; then
  echo "Orphelins (source absente : git mv / git rm avec leur source) :"
  printf "%s" "$orphans"
fi
exit "$code"
