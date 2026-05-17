#!/usr/bin/env bash
set -euo pipefail

# Xcode Cloud post-clone hook.
# The Xcode project is committed to the repo so this is usually a no-op,
# but if a future change moves it back behind xcodegen, this hook makes
# Xcode Cloud builds succeed without manual intervention.

if [ ! -d "$CI_PRIMARY_REPOSITORY_PATH/ios/Tendle.xcodeproj" ]; then
  echo "ios/Tendle.xcodeproj not present; running xcodegen."
  brew install xcodegen
  (cd "$CI_PRIMARY_REPOSITORY_PATH/ios" && xcodegen generate)
else
  echo "ios/Tendle.xcodeproj present; skipping xcodegen."
fi
