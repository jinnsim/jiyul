#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/../assets/generated"
DEST="$ROOT/Tendle/Resources/Assets.xcassets"

declare -a MAP=(
  "tendle-character-jiyul-sheet-r01.png:JiyulCharacter"
  "tendle-character-eunchan-sheet-r01.png:EunchanCharacter"
  "tendle-character-creature-friends-sheet-r02.png:CreatureFriends"
  "tendle-splash-jiyul-eunchan-r01.png:SplashHero"
  "tendle-home-empty-jiyul-eunchan-calendar-r01.png:HomeEmpty"
  "tendle-loading-jiyul-scroll-snake-r01.png:LoadingScene"
  "tendle-result-win-jiyul-eunchan-dragon-r01.png:ResultWin"
  "tendle-result-close-jiyul-eunchan-r01.png:ResultClose"
  "tendle-result-low-jiyul-eunchan-spider-r01.png:ResultLow"
  "tendle-milestone-streak-jiyul-eunchan-snake-r02.png:StreakMilestone"
  "tendle-welcome-back-jiyul-eunchan-r01.png:WelcomeBack"
)

for entry in "${MAP[@]}"; do
  PNG="${entry%%:*}"
  NAME="${entry##*:}"
  IMGSET="$DEST/${NAME}.imageset"
  mkdir -p "$IMGSET"
  cp "$SRC/$PNG" "$IMGSET/$PNG"
  cat > "$IMGSET/Contents.json" <<JSON
{
  "images" : [
    {
      "filename" : "$PNG",
      "idiom" : "universal",
      "scale" : "1x"
    },
    { "idiom" : "universal", "scale" : "2x" },
    { "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
done

echo "Imported ${#MAP[@]} illustration imagesets."
