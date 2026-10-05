#!/bin/bash
# tools/setup.sh — Godot headless + templates d'export Web + outils (VM Claude Code, CI, poste local).
#
# Idempotent et « meilleur effort » : chaque étape saute si son résultat est déjà là, et le
# script se termine toujours par exit 0 (un échec est signalé, jamais bloquant).
#
# Ordre pour Godot :
#   1. binaire et templates depuis les releases GitHub de godotengine/godot (joignables depuis
#      les VM cloud) ; les templates sont extraits par requêtes HTTP Range (tools/fetch_templates.py),
#      seulement templates/web*.zip et version.txt, sinon téléchargement complet du .tpz puis suppression ;
#   2. repli : image docker barichello/godot-ci (si un démon docker répond).
# Puis : gdtoolkit (gdlint, gdformat) et Pillow (tools/gen_placeholders.py).
#
# Variables : GODOT_VERSION (défaut 4.7.2), GDTOOLKIT_VERSION (défaut 4.5.0),
#             GODOT_BIN_DIR (défaut /usr/local/bin, ou ~/.local/bin sans droits d'écriture).
set -u

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
GDTOOLKIT_VERSION="${GDTOOLKIT_VERSION:-4.5.0}"
TAG="${GODOT_VERSION}-stable"
RELEASES="https://github.com/godotengine/godot/releases/download/${TAG}"
TPL_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
IMG="barichello/godot-ci:${GODOT_VERSION}"
HERE="$(cd "$(dirname "$0")" && pwd)"

log() { echo "[setup] $*"; }

SUDO=""
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo -n"
fi

BIN_DIR="${GODOT_BIN_DIR:-/usr/local/bin}"
if ! { [ -w "$BIN_DIR" ] || [ -n "$SUDO" ]; }; then
  BIN_DIR="$HOME/.local/bin"
fi
mkdir -p "$BIN_DIR" 2>/dev/null || true

godot_ok() {
  command -v godot >/dev/null 2>&1 && godot --headless --version 2>/dev/null | grep -q "^${GODOT_VERSION}\.stable"
}

templates_ok() {
  [ -f "$TPL_DIR/web_nothreads_release.zip" ] && [ -f "$TPL_DIR/web_nothreads_debug.zip" ]
}

# 1. Bibliothèques runtime de Godot, Xvfb + Mesa (captures), git-lfs, unzip.
install_packages() {
  command -v apt-get >/dev/null 2>&1 || return 0
  local asound=libasound2t64
  apt-cache show libasound2t64 >/dev/null 2>&1 || asound=libasound2
  local wanted="xvfb xauth libgl1 libgl1-mesa-dri libglx-mesa0 libx11-6 libxcursor1 libxinerama1
    libxrandr2 libxi6 libxext6 libxrender1 ${asound} libpulse0 libfontconfig1 libdbus-1-3 libudev1
    git-lfs unzip curl python3-pip"
  local missing=""
  for pkg in $wanted; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing="$missing $pkg"
  done
  [ -z "$missing" ] && return 0
  log "paquets apt :$missing"
  $SUDO apt-get update -qq >/dev/null 2>&1 || true
  # Un paquet introuvable sur cette version d'Ubuntu ne doit pas empêcher les autres.
  # shellcheck disable=SC2086
  if ! DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends $missing >/dev/null 2>&1; then
    for pkg in $missing; do
      DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends "$pkg" >/dev/null 2>&1 \
        || log "ATTENTION : paquet $pkg indisponible"
    done
  fi
}

# 2a. Godot depuis les releases GitHub.
install_godot_release() {
  local tmp
  tmp="$(mktemp -d)"
  local zip="Godot_v${TAG}_linux.x86_64.zip"
  log "téléchargement de $zip"
  if curl -fsSL --retry 3 -o "$tmp/$zip" "$RELEASES/$zip" && unzip -q -o "$tmp/$zip" -d "$tmp"; then
    $SUDO install -m 755 "$tmp/Godot_v${TAG}_linux.x86_64" "$BIN_DIR/godot" || cp "$tmp/Godot_v${TAG}_linux.x86_64" "$BIN_DIR/godot"
    chmod +x "$BIN_DIR/godot" 2>/dev/null || true
  else
    log "ATTENTION : téléchargement du binaire Godot impossible"
  fi
  rm -rf "$tmp"
}

# 2b. Templates d'export Web depuis les releases GitHub.
install_templates_release() {
  local tpz="Godot_v${TAG}_export_templates.tpz"
  mkdir -p "$TPL_DIR"
  log "templates Web (extraction partielle de $tpz)"
  if python3 "$HERE/fetch_templates.py" "$RELEASES/$tpz" "$TPL_DIR" 'templates/web*.zip' 'templates/version.txt'; then
    return 0
  fi
  log "extraction partielle impossible : téléchargement complet (1,3 Go)"
  local tmp
  tmp="$(mktemp -d)"
  if curl -fsSL --retry 3 -o "$tmp/$tpz" "$RELEASES/$tpz"; then
    unzip -q -o -j "$tmp/$tpz" 'templates/web*.zip' 'templates/version.txt' -d "$TPL_DIR" \
      || log "ATTENTION : décompression des templates impossible"
  else
    log "ATTENTION : téléchargement des templates impossible"
  fi
  rm -rf "$tmp"
}

# 2c. Repli docker (image godot-ci), si un démon répond.
install_from_docker() {
  command -v docker >/dev/null 2>&1 || return 0
  docker info >/dev/null 2>&1 || { log "docker présent mais sans démon : repli impossible"; return 0; }
  log "repli docker : $IMG"
  docker pull -q "$IMG" >/dev/null || return 0
  local cid
  cid="$(docker create "$IMG")" || return 0
  if ! godot_ok; then
    $SUDO docker cp "$cid":/usr/local/bin/godot "$BIN_DIR/godot" || true
    chmod +x "$BIN_DIR/godot" 2>/dev/null || true
  fi
  if ! templates_ok; then
    mkdir -p "$HOME/.local/share/godot"
    docker cp "$cid":/root/.local/share/godot/export_templates "$HOME/.local/share/godot/" || true
  fi
  docker rm "$cid" >/dev/null 2>&1 || true
}

# 3. gdtoolkit (version figée : le formatage doit être identique partout) et Pillow.
install_python_tools() {
  local need=""
  gdlint --version 2>/dev/null | grep -q " ${GDTOOLKIT_VERSION}$" || need="gdtoolkit==${GDTOOLKIT_VERSION}"
  python3 -c "import PIL" >/dev/null 2>&1 || need="$need Pillow"
  [ -z "$need" ] && return 0
  log "pip :$need"
  local flag=""
  python3 -m pip install --help 2>/dev/null | grep -q -- "--break-system-packages" && flag="--break-system-packages"
  # shellcheck disable=SC2086
  python3 -m pip install -q $flag $need || pip3 install -q $flag $need || log "ATTENTION : pip install a échoué ($need)"
}

install_packages
godot_ok || install_godot_release
templates_ok || install_templates_release
if ! godot_ok || ! templates_ok; then
  install_from_docker
fi
install_python_tools
command -v git-lfs >/dev/null 2>&1 && git lfs install --skip-repo >/dev/null 2>&1

if godot_ok; then
  log "godot $(godot --headless --version 2>/dev/null | head -n 1)"
else
  log "ATTENTION : godot ${GODOT_VERSION} absent ; tools/godot tentera docker"
fi
templates_ok && log "templates Web : $TPL_DIR" || log "ATTENTION : templates Web absents ($TPL_DIR)"
gdlint --version 2>/dev/null | sed 's/^/[setup] /' || log "ATTENTION : gdlint absent"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) log "ajoute $BIN_DIR au PATH" ;;
esac
exit 0
