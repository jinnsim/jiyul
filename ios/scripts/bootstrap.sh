#!/usr/bin/env bash
set -euo pipefail

# First-time setup for a fresh clone.
# Installs xcodegen (via Homebrew if available) and regenerates the
# Xcode project from ios/project.yml.
#
# Run me once after cloning, then open ios/Tendle.xcodeproj in Xcode.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Locate or install xcodegen
if command -v xcodegen >/dev/null 2>&1; then
  XCODEGEN=xcodegen
elif [ -x /opt/homebrew/bin/xcodegen ]; then
  XCODEGEN=/opt/homebrew/bin/xcodegen
elif [ -x /Users/jongjinseok/.local/bin/xcodegen ]; then
  XCODEGEN=/Users/jongjinseok/.local/bin/xcodegen
else
  if command -v brew >/dev/null 2>&1; then
    echo "Installing xcodegen via Homebrew..."
    brew install xcodegen
    XCODEGEN=xcodegen
  else
    echo "ERROR: xcodegen not found and Homebrew unavailable." >&2
    echo "Install xcodegen: https://github.com/yonaskolb/XcodeGen" >&2
    exit 1
  fi
fi

echo "Using $XCODEGEN ($($XCODEGEN --version))"
(cd "$ROOT/ios" && "$XCODEGEN" generate)

echo
echo "✓ Xcode project regenerated at $ROOT/ios/Tendle.xcodeproj"
echo "  Open in Xcode:  open $ROOT/ios/Tendle.xcodeproj"
echo "  Build + test:   xcodebuild -project $ROOT/ios/Tendle.xcodeproj -scheme Tendle -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test"
echo "  Archive:        $ROOT/ios/scripts/build-archive.sh"
