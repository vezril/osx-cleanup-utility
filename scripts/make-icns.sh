#!/usr/bin/env bash
#
# make-icns.sh — generate a macOS AppIcon.icns from a single 1024x1024 master.
#
# Usage: scripts/make-icns.sh <master.png> <out.icns>
#
# Deterministically downscales the master into the Apple-required iconset sizes
# (16/32/128/256/512 at @1x and @2x) with `sips`, then packs them with
# `iconutil`. The iconset is a build artifact in a temp dir — only the .icns is
# kept. Fails loudly (non-zero) if the master is missing or not 1024x1024.

set -euo pipefail

MASTER="${1:-}"
OUT="${2:-}"

if [[ -z "${MASTER}" || -z "${OUT}" ]]; then
  echo "error: usage: $0 <master.png> <out.icns>" >&2
  exit 2
fi
if [[ ! -f "${MASTER}" ]]; then
  echo "error: master image not found: ${MASTER}" >&2
  exit 2
fi

W="$(sips -g pixelWidth  "${MASTER}" 2>/dev/null | awk '/pixelWidth/{print $2}')"
H="$(sips -g pixelHeight "${MASTER}" 2>/dev/null | awk '/pixelHeight/{print $2}')"
if [[ "${W}" != "1024" || "${H}" != "1024" ]]; then
  echo "error: master must be exactly 1024x1024 (got ${W:-?}x${H:-?}): ${MASTER}" >&2
  exit 2
fi

WORK="$(mktemp -d)"
ICONSET="${WORK}/AppIcon.iconset"
mkdir -p "${ICONSET}"
trap 'rm -rf "${WORK}"' EXIT

# size:filename pairs (10 required entries)
emit() { # <pixels> <filename>
  sips -z "$1" "$1" "${MASTER}" --out "${ICONSET}/$2" >/dev/null
}
emit 16   icon_16x16.png
emit 32   icon_16x16@2x.png
emit 32   icon_32x32.png
emit 64   icon_32x32@2x.png
emit 128  icon_128x128.png
emit 256  icon_128x128@2x.png
emit 256  icon_256x256.png
emit 512  icon_256x256@2x.png
emit 512  icon_512x512.png
emit 1024 icon_512x512@2x.png

COUNT="$(find "${ICONSET}" -name '*.png' | wc -l | tr -d ' ')"
if [[ "${COUNT}" != "10" ]]; then
  echo "error: expected 10 iconset images, generated ${COUNT}" >&2
  exit 1
fi

mkdir -p "$(dirname "${OUT}")"
iconutil -c icns "${ICONSET}" -o "${OUT}"
echo "wrote ${OUT} (from ${COUNT} iconset sizes)"
