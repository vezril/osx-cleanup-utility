#!/usr/bin/env bash
#
# make-app-bundle.sh — assemble an unsigned osx-cleanup-utility.app and zip it.
#
# Usage: scripts/make-app-bundle.sh <version>      e.g. 0.1.1
#
# Builds the release binary, generates AppIcon.icns from the committed master,
# assembles the .app bundle (binary + icon + Info.plist with CFBundleIconFile),
# and packages it as osx-cleanup-utility-v<version>-unsigned.zip in the current
# directory. Used by the release workflow and reproducible locally. Unsigned;
# requires no secrets.

set -euo pipefail

VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  echo "error: usage: $0 <version>   (e.g. 0.1.1)" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MASTER="${ROOT}/docs/app-icon/AppIcon.png"
APP="osx-cleanup-utility.app"

echo "==> building release binary"
swift build -c release
BIN_SRC="$(swift build -c release --show-bin-path)/osx-cleanup"

echo "==> assembling ${APP}"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp "${BIN_SRC}" "${APP}/Contents/MacOS/osx-cleanup"

echo "==> generating icon"
"${ROOT}/scripts/make-icns.sh" "${MASTER}" "${APP}/Contents/Resources/AppIcon.icns"

cat > "${APP}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>osx-cleanup-utility</string>
  <key>CFBundleDisplayName</key><string>osx-cleanup-utility</string>
  <key>CFBundleIdentifier</key><string>dev.vezril.osx-cleanup-utility</string>
  <key>CFBundleExecutable</key><string>osx-cleanup</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${VERSION}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

ZIP="osx-cleanup-utility-v${VERSION}-unsigned.zip"
rm -f "${ZIP}"
ditto -c -k --keepParent "${APP}" "${ZIP}"
echo "==> wrote ${ZIP}"
echo "${ZIP}"
