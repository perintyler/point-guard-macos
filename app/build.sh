#!/bin/bash
# Build Point Guard as a proper .app bundle
set -euo pipefail

cd "$(dirname "$0")"

echo "Building Point Guard..."
swift build 2>&1

APP_DIR=".build/PointGuard.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"

rm -rf "$APP_DIR"
mkdir -p "$MACOS"

cp .build/debug/PointGuard "$MACOS/PointGuard"
cp Resources/Info.plist "$CONTENTS/Info.plist"

# No fonts/icons: this app is a status dashboard with plain SwiftUI text and
# system colors, not a markdown renderer -- unlike BarryActions, it has no
# reason to pull in Components' font dependency chain.

# Bind the ad-hoc signature to the assembled bundle. `swift build` signs the
# bare binary and seals resources, but the resources are copied in above --
# leaving the bundle verifiable as "code has no resources but signature
# indicates they must be present", which macOS refuses to launch with
# OS_REASON_CODESIGNING. The app simply never starts.
codesign --force --deep --sign - "$APP_DIR"
codesign --verify --strict "$APP_DIR"

echo "Built: $APP_DIR"
