#!/bin/bash
# Tests GUT ciblés, pour itérer vite (le vert complet reste tools/check.sh).
#
#   tools/test.sh                                   # tous les tests
#   tools/test.sh res://tests/unit/test_health.gd   # un fichier (ou tests/unit/test_health.gd)
#   tools/test.sh res://tests/unit                  # un dossier (sous-dossiers compris)
#   tools/test.sh tests/unit/test_health.gd -gunit_test_name=invincibility   # un test précis
#
# Les options supplémentaires sont passées à GUT. Échoue aussi si un script ou un fichier de
# test ne compile pas (GUT l'ignorerait sans échouer). Journal complet : build/test.log.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p build

target="res://tests"
if [ $# -gt 0 ] && [[ "$1" != -* ]]; then
  target="$1"
  shift
fi
case "$target" in
  res://*) ;;
  *) target="res://${target#./}" ;;
esac
target="${target%/}"
if [[ "$target" == *.gd ]]; then
  selection=("-gtest=$target")
else
  selection=("-gdir=$target" "-ginclude_subdirs")
fi

tools/godot --headless -s addons/gut/gut_cmdln.gd "${selection[@]}" -gprefix=test_ -gsuffix=.gd \
  -gexit "$@" 2>&1 | tee build/test.log
code=${PIPESTATUS[0]}
if sed 's/\x1b\[[0-9;]*m//g' build/test.log | grep -qE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script"; then
  echo "ROUGE : un script ou un fichier de test ne compile pas (voir SCRIPT ERROR ci-dessus)"
  exit 1
fi
exit "$code"
