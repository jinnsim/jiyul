#!/usr/bin/env bash
set -euo pipefail

# Export an IPA from the most recent archive.
# Output: ./build/ipa/Tendle.ipa
#
# Edit ios/ExportOptions.plist <method> before running:
#   "development"        — sideload to your own device
#   "ad-hoc"             — Diawi / TestFlight-via-Transporter (rare)
#   "app-store-connect"  — TestFlight + App Store submission

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

if [ ! -d ./build/Tendle.xcarchive ]; then
  echo "No archive at ./build/Tendle.xcarchive — run ./ios/scripts/build-archive.sh first." >&2
  exit 1
fi

mkdir -p ./build/ipa

xcodebuild \
  -exportArchive \
  -archivePath ./build/Tendle.xcarchive \
  -exportPath ./build/ipa \
  -exportOptionsPlist ios/ExportOptions.plist

echo
echo "IPA at $ROOT/build/ipa/Tendle.ipa"
echo "Upload: drag into Transporter.app, or:"
echo "  xcrun altool --upload-app -f ./build/ipa/Tendle.ipa -t ios -u <APPLE_ID> -p <APP_PASSWORD>"
