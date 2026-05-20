#!/usr/bin/env bash
# Download and extract a CEF (Chromium Embedded Framework) binary distribution
# for macOS into third_party/cef/. CEF binaries are large and are NOT committed.
#
# Usage:  Scripts/fetch_cef.sh [CEF_VERSION] [ARCH]
#   ARCH defaults to the host arch (arm64 on Apple Silicon, x86_64 otherwise).
#
# Distributions are published at https://cef-builds.spotifycdn.com/index.html
# Pick a "Standard Distribution" build matching your Chromium/CEF version and
# update CEF_VERSION below (or pass it as the first argument).

set -euo pipefail

# A known-good CEF version. Update to the latest stable from the index page.
CEF_VERSION="${1:-138.0.0+g000000+chromium-138.0.0000.00}"
ARCH="${2:-$(uname -m)}"

case "$ARCH" in
  arm64|aarch64) PLATFORM="macosarm64" ;;
  x86_64|amd64)  PLATFORM="macosx64" ;;
  *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;;
esac

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT_DIR/third_party/cef"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# CEF uses '+' in versions which must be URL-encoded as %2B.
ENCODED_VERSION="${CEF_VERSION//+/%2B}"
ARCHIVE="cef_binary_${ENCODED_VERSION}_${PLATFORM}_minimal.tar.bz2"
URL="https://cef-builds.spotifycdn.com/${ARCHIVE}"

echo "Downloading CEF ${CEF_VERSION} (${PLATFORM})..."
echo "  $URL"
curl -fL --retry 4 --retry-delay 2 -o "$TMP/cef.tar.bz2" "$URL"

echo "Extracting to $DEST ..."
rm -rf "$DEST"
mkdir -p "$DEST"
tar -xjf "$TMP/cef.tar.bz2" -C "$DEST" --strip-components=1

echo "Done. CEF is at: $DEST"
echo "Framework: $DEST/Release/Chromium Embedded Framework.framework"
