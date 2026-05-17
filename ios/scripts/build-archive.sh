#!/usr/bin/env bash
set -euo pipefail

# Build a signed Release archive for the iOS device target.
# Output: ./build/Tendle.xcarchive
# Requires: Team ID LQZYM2U744 cert + provisioning profile in keychain.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p build

# Locate xcodegen (Homebrew or local install)
if command -v xcodegen >/dev/null 2>&1; then
  XCODEGEN=xcodegen
elif [ -x /Users/jongjinseok/.local/bin/xcodegen ]; then
  XCODEGEN=/Users/jongjinseok/.local/bin/xcodegen
elif [ -x /opt/homebrew/bin/xcodegen ]; then
  XCODEGEN=/opt/homebrew/bin/xcodegen
else
  echo "xcodegen not found" >&2
  exit 1
fi

(cd ios && "$XCODEGEN" generate)

xcodebuild \
  -project ios/Tendle.xcodeproj \
  -scheme Tendle \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/Tendle.xcarchive \
  archive

echo
echo "Archive at $ROOT/build/Tendle.xcarchive"
echo "Next: ./ios/scripts/export-ipa.sh"
