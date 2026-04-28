#!/bin/bash
# build.sh — assemble Claude Usage Monitor.app from the source files in this repo.
#
# Usage:
#   ./build.sh
#
# Produces ./Claude\ Usage\ Monitor.app, ad-hoc signed and ready to launch.
# Requires macOS (and the standard system codesign + xattr tools).

set -euo pipefail

APP_NAME="Claude Usage Monitor"
APP_DIR="${APP_NAME}.app"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$HERE"

# Sanity-check the source files exist.
for f in app.py login.html requirements.txt launcher Info.plist AppIcon.icns; do
  if [ ! -f "$f" ]; then
    echo "error: missing source file '$f' in $(pwd)" >&2
    exit 1
  fi
done

# Wipe any previous build.
rm -rf "$APP_DIR"

# Build the standard macOS .app bundle layout.
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp Info.plist        "$APP_DIR/Contents/Info.plist"
cp launcher          "$APP_DIR/Contents/MacOS/launcher"
chmod +x             "$APP_DIR/Contents/MacOS/launcher"
cp app.py            "$APP_DIR/Contents/Resources/app.py"
cp login.html        "$APP_DIR/Contents/Resources/login.html"
cp requirements.txt  "$APP_DIR/Contents/Resources/requirements.txt"
cp AppIcon.icns      "$APP_DIR/Contents/Resources/AppIcon.icns"

# Strip the macOS quarantine flag (otherwise the OS will refuse to open
# an unsigned bundle that came from the internet).
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP_DIR" || true
fi

# Ad-hoc sign so macOS lets the launcher run. This is NOT a real
# Developer ID signature — distributors who want notarization should
# replace this step with a proper signing identity.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_DIR"
fi

# Tell Launch Services about the new bundle so the icon shows up
# correctly in Finder right away (best-effort; safe to ignore failures).
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -f "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "Built: $HERE/$APP_DIR"
echo "Drag it to /Applications, or just double-click to launch."
