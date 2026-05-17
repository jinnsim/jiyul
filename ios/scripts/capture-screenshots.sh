#!/usr/bin/env bash
set -euo pipefail

# Capture App Store screenshots for Jiyul across language × device matrix.
# Output layout (fastlane-deliver compatible):
#   fastlane/screenshots/
#     ko-KR/iphone67-01-home.png  ...  iphone67-05-settings.png
#                ipad129-01-home.png   ...   ipad129-05-settings.png
#     en-US/  (same)
#
# Files are written from inside the simulator's app container; we use
# `find` to locate the captured PNGs after each test run and copy them
# into the fastlane layout. .xcresult bundles also contain the same
# attachments for Xcode Test Report viewing.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

declare -a DEVICES=(
  "iphone67:iPhone 15 Pro Max:OS=17.2"
  "ipad129:iPad Pro (12.9-inch) (6th generation):OS=17.2"
)
declare -a LANGS=("ko:ko-KR" "en:en-US")

OUT_BASE="$ROOT/fastlane/screenshots"
mkdir -p "$OUT_BASE"

device_udid() {
  xcrun simctl list devices available \
    | grep -F "$1 (" \
    | head -1 \
    | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

for dev_spec in "${DEVICES[@]}"; do
  IFS=":" read -r dev_slot dev_name dev_os <<< "$dev_spec"
  echo
  echo "=== Device: $dev_name ($dev_slot) ==="
  udid="$(device_udid "$dev_name")"
  echo "    udid=$udid"
  # Ensure device is booted.
  xcrun simctl boot "$udid" 2>/dev/null || true

  for lang_spec in "${LANGS[@]}"; do
    IFS=":" read -r lang lang_dir <<< "$lang_spec"
    out_dir="$OUT_BASE/$lang_dir"
    mkdir -p "$out_dir"

    echo
    echo "  -- Language: $lang"

    # Wipe any previous in-simulator captures so we don't pick up stale PNGs.
    find "$HOME/Library/Developer/CoreSimulator/Devices/$udid/data" \
      -path "*tmp/jiyul-screenshots/*.png" -delete 2>/dev/null || true

    # `|| true` so a single failing test doesn't abort the whole matrix —
    # other tests in the same run still write their PNGs.
    SIMCTL_CHILD_JIYUL_TEST_LANG="$lang" \
    SIMCTL_CHILD_JIYUL_SCREENSHOT_DIR="$(mktemp -d -t jiyul-shots)/jiyul-screenshots" \
    xcodebuild test \
      -project ios/Tendle.xcodeproj \
      -scheme Tendle \
      -destination "platform=iOS Simulator,id=$udid" \
      -only-testing:TendleUITests/CaptureScreenshots \
      2>&1 | tail -8 || true

    # Pull the captured PNGs out of the simulator data container.
    sim_pngs="$(find "$HOME/Library/Developer/CoreSimulator/Devices/$udid/data" \
                     -path "*tmp/jiyul-screenshots/*.png" 2>/dev/null || true)"
    count=0
    while IFS= read -r png; do
      [ -n "$png" ] || continue
      base="$(basename "$png")"
      cp "$png" "$out_dir/${dev_slot}-${base}"
      count=$((count + 1))
    done <<< "$sim_pngs"
    echo "  -- Saved $count screenshot(s) to $out_dir/${dev_slot}-*.png"
  done
done

echo
echo "Done. Tree:"
find "$OUT_BASE" -type f -name "*.png" | sort
