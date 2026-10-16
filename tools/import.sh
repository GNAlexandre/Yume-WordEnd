#!/bin/bash
# Import headless : crée les .uid des scripts et les .import des assets, puis liste ce qu'il
# faut commiter et les fichiers générés devenus orphelins (source renommée ou supprimée).
# À lancer après avoir créé, renommé ou supprimé un script, une scène ou un asset.
#
# (F0) Réglages d'import des images, imposés à chaque passage (docs/DECISIONS.md, F0) : « Lossless »
# (WebP sans perte), sans mipmaps, sans « détection 3D » (l'éditeur ouvert avec une fenêtre
# passerait sinon en VRAM compressée, avec perte et mipmaps, toute image vue en 3D). Les nouvelles
# images les reçoivent de project.godot ([importer_defaults]) ; normalize_textures rattrape les
# .import plus anciens ou venus d'une autre branche, et l'import est relancé pour eux.
# tests/unit/test_texture_imports.gd le vérifie.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p build

# Ramène les .import de texture (hors addons/) aux réglages du projet ; écrit sur la sortie
# standard les fichiers corrigés. (F2) Les fonds peints et opaques du ciel (assets/hd2d/sky/ :
# panoramas sky*, mers de nuages cloud_sea*) sont en WebP avec perte, qualité LOSSY_QUALITY ; tout
# le reste reste sans perte : le pixel art, et les images détourées (la perte grise leurs bords).
LOSSY_DIR="assets/hd2d/sky/"
LOSSY_QUALITY="0.9"
is_lossy() {
  [[ "$1" == "${LOSSY_DIR}sky"*.png.import || "$1" == "${LOSSY_DIR}cloud_sea"*.png.import ]]
}
normalize_textures() {
  local file
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    grep -q '^importer="texture"$' "$file" || continue
    local changed=0
    if grep -q -E '^(detect_3d/compress_to=[12]|mipmaps/generate=true)$' "$file"; then
      sed -i -e 's#^detect_3d/compress_to=[12]$#detect_3d/compress_to=0#' \
        -e 's#^mipmaps/generate=true$#mipmaps/generate=false#' -- "$file"
      changed=1
    fi
    if is_lossy "$file"; then
      if ! grep -q '^compress/mode=1$' "$file" \
        || ! grep -q "^compress/lossy_quality=$LOSSY_QUALITY\$" "$file"; then
        sed -i -e 's#^compress/mode=[0-4]$#compress/mode=1#' \
          -e "s#^compress/lossy_quality=.*\$#compress/lossy_quality=$LOSSY_QUALITY#" -- "$file"
        changed=1
      fi
    elif grep -q -E '^compress/mode=[1-4]$' "$file"; then
      sed -i -e 's#^compress/mode=[1-4]$#compress/mode=0#' -- "$file"
      changed=1
    fi
    [ "$changed" = 1 ] && echo "$file"
  done < <(find . -name '*.import' -not -path './.godot/*' -not -path './build/*' \
    -not -path './addons/*' -not -path './.git/*' -not -path './.claude/*' | sed 's#^\./##' | sort)
}

fixed=$(normalize_textures)
tools/godot --headless --import > build/import.log 2>&1
code=$?
fixed_after=$(normalize_textures)
if [ -n "$fixed_after" ]; then
  tools/godot --headless --import >> build/import.log 2>&1
  code=$?
fi
fixed=$(printf "%s\n%s\n" "$fixed" "$fixed_after" | grep -v '^$' | sort -u)
sed 's/\x1b\[[0-9;]*m//g' build/import.log | grep -E "ERROR|WARNING" || true
if [ -n "$fixed" ]; then
  count=$(echo "$fixed" | wc -l)
  echo "Réglages d'import ramenés à ceux du projet (sans perte, fonds du ciel avec perte, sans mipmaps ni détection 3D) ($count, à commiter) :"
  echo "$fixed" | head -20 | sed 's/^/  /'
  [ "$count" -le 20 ] || echo "  … et $((count - 20)) autres"
fi

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
