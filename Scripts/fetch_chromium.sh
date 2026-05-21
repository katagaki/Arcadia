#!/usr/bin/env bash
# Fetch a Chromium source checkout pinned to a known revision, so CRWebView.framework
# can be built from source (Stage A of docs/cef-to-crwebview-migration.md).
#
# Unlike the old CEF flow (a prebuilt binary tarball), this clones depot_tools and
# syncs a full Chromium tree — expect ~100 GB on disk and a long first sync. The
# actual framework build is a separate step: Scripts/build_crwebview.sh.
#
# Usage:
#   Scripts/fetch_chromium.sh
#
# Environment overrides:
#   CHROMIUM_DIR      where the checkout lives        (default: $HOME/chromium)
#   DEPOT_TOOLS_DIR   where depot_tools is cloned      (default: $HOME/depot_tools)
#   CHROMIUM_VERSION  exact tag to pin                 (default: see below)
#
# NOTE (plan §12, open question): CHROMIUM_VERSION below is a PLACEHOLDER. Pin it
# to the exact Chromium release confirmed to build against the macOS 26 SDK with
# deployment target 26 before relying on this. Tags: https://chromiumdash.appspot.com/
# It is intentionally on the 138 milestone to match the Chromium version Arcadia
# rendered with under CEF, minimizing behavioral drift across the migration.

set -euo pipefail

CHROMIUM_DIR="${CHROMIUM_DIR:-$HOME/chromium}"
DEPOT_TOOLS_DIR="${DEPOT_TOOLS_DIR:-$HOME/depot_tools}"
CHROMIUM_VERSION="${CHROMIUM_VERSION:-138.0.7204.100}"  # PLACEHOLDER — see note above.

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This build targets macOS and must be fetched/built on a Mac." >&2
  exit 1
fi

# --- depot_tools ---------------------------------------------------------------
if [[ ! -d "$DEPOT_TOOLS_DIR" ]]; then
  log "Cloning depot_tools into $DEPOT_TOOLS_DIR"
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
else
  log "Updating depot_tools in $DEPOT_TOOLS_DIR"
  git -C "$DEPOT_TOOLS_DIR" pull --ff-only || true
fi
export PATH="$DEPOT_TOOLS_DIR:$PATH"

# --- checkout ------------------------------------------------------------------
mkdir -p "$CHROMIUM_DIR"
cd "$CHROMIUM_DIR"

if [[ ! -d "$CHROMIUM_DIR/src" ]]; then
  log "Fetching Chromium (no history) — this downloads tens of GB"
  fetch --nohooks --no-history chromium
fi

cd "$CHROMIUM_DIR/src"

log "Pinning to $CHROMIUM_VERSION"
git fetch --tags origin
if git rev-parse -q --verify "refs/tags/$CHROMIUM_VERSION" >/dev/null; then
  git checkout "tags/$CHROMIUM_VERSION" -B "arcadia-pin-$CHROMIUM_VERSION"
else
  echo "WARNING: tag '$CHROMIUM_VERSION' not found; staying on the fetched revision." >&2
  echo "         The checkout is still usable, but set CHROMIUM_VERSION to a real" >&2
  echo "         macOS-26-SDK-compatible tag before building (it must match the" >&2
  echo "         //content API the embedder targets)." >&2
fi

log "Syncing dependencies to the pinned revision (gclient sync)"
gclient sync -D --with_branch_heads --with_tags --reset

log "Running hooks"
gclient runhooks

log "Done. Chromium checkout: $CHROMIUM_DIR/src @ $CHROMIUM_VERSION"
log "Next: Scripts/build_crwebview.sh"
