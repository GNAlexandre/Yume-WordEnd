#!/bin/bash
# Reprise de session cloud (hook SessionStart de .claude/settings.json) : outils, LFS, import.
# Ne fait rien hors du cloud. Ne bloque jamais la session (exit 0).
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/..}" || exit 0

# Godot absent (environnement sans script de setup ou cache expiré) : installation au mieux.
if ! command -v godot >/dev/null 2>&1; then
  bash tools/setup.sh > /tmp/wordend-setup.log 2>&1 || true
fi

git lfs pull >/dev/null 2>&1 || true
tools/godot --headless --import >/dev/null 2>&1 || true
exit 0
