#!/usr/bin/env bash
# Build CRWebView.framework (+ helper apps + Chromium runtime payload) from a
# Chromium checkout produced by Scripts/fetch_chromium.sh. This is Stage A's
# "assemble the framework" step (plan §7, A5).
#
# The engine source we own lives in this repo under Sources/CRWebView/. It is
# overlaid into the Chromium tree at src/arcadia/crwebview/ so GN can build it as
# an in-tree target, then the resulting bundles are copied back into the repo at
# third_party/crwebview/ (gitignored, like the old third_party/cef/).
#
# Usage:
#   Scripts/build_crwebview.sh [Release|Debug]
#
# Environment overrides:
#   CHROMIUM_DIR    Chromium checkout      (default: $HOME/chromium)
#   DEPOT_TOOLS_DIR depot_tools            (default: $HOME/depot_tools)
#   TARGET_CPU      arm64 | x64            (default: host arch)
#   OUT_DIR         gn out dir name        (default: out/<Config>)

set -euo pipefail

CONFIG="${1:-Release}"
CHROMIUM_DIR="${CHROMIUM_DIR:-$HOME/chromium}"
DEPOT_TOOLS_DIR="${DEPOT_TOOLS_DIR:-$HOME/depot_tools}"

case "${TARGET_CPU:-$(uname -m)}" in
  arm64|aarch64) TARGET_CPU="arm64" ;;
  x86_64|amd64|x64) TARGET_CPU="x64" ;;
  *) echo "Unsupported TARGET_CPU: ${TARGET_CPU:-}" >&2; exit 1 ;;
esac

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$CHROMIUM_DIR/src"
OUT_DIR="${OUT_DIR:-out/$CONFIG}"
DEST="$ROOT_DIR/third_party/crwebview"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

[[ -d "$SRC" ]] || { echo "No Chromium checkout at $SRC — run Scripts/fetch_chromium.sh first." >&2; exit 1; }
export PATH="$DEPOT_TOOLS_DIR:$PATH"

# --- overlay our embedder into the Chromium tree -------------------------------
log "Overlaying Sources/CRWebView -> $SRC/arcadia/crwebview"
mkdir -p "$SRC/arcadia"
rm -rf "$SRC/arcadia/crwebview"
# Copy (not symlink): GN/ninja resolve paths inside the source tree.
cp -R "$ROOT_DIR/Sources/CRWebView" "$SRC/arcadia/crwebview"

# --- configure -----------------------------------------------------------------
IS_DEBUG=false
SYMBOL_LEVEL=1
[[ "$CONFIG" == "Debug" ]] && { IS_DEBUG=true; SYMBOL_LEVEL=2; }

GN_ARGS="is_debug=$IS_DEBUG \
is_component_build=false \
target_cpu=\"$TARGET_CPU\" \
symbol_level=$SYMBOL_LEVEL \
enable_nacl=false \
dcheck_always_on=false \
proprietary_codecs=true \
ffmpeg_branding=\"Chrome\" \
mac_deployment_target=\"26.0\""

log "gn gen $OUT_DIR ($CONFIG, $TARGET_CPU)"
( cd "$SRC" && gn gen "$OUT_DIR" --args="$GN_ARGS" )

# --- build ---------------------------------------------------------------------
log "ninja: building //arcadia/crwebview:all (first build is multi-hour)"
( cd "$SRC" && autoninja -C "$OUT_DIR" arcadia/crwebview:all )

# --- collect artifacts ---------------------------------------------------------
log "Copying CRWebView.framework + helpers into $DEST"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -R "$SRC/$OUT_DIR/CRWebView.framework" "$DEST/"
# Helper apps (renderer/GPU/plugin/utility/alerts) live alongside the framework.
for helper in "$SRC/$OUT_DIR/"*"Helper"*.app; do
  [[ -e "$helper" ]] && cp -R "$helper" "$DEST/"
done

log "Done. CRWebView.framework: $DEST/CRWebView.framework"
log "Embed it (and the helpers) into Arcadia.app — see project.yml + README."
