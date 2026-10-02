# Jiyul — App Store Listing Metadata

Ready-to-paste values for App Store Connect.

## Identity

| Field | Value |
|---|---|
| App Name (max 30) | **Jiyul** |
| Subtitle (max 30) | Daily puzzle with Jiyul |
| Bundle ID | `com.jinnsim.Tendle` |
| Team ID | `LQZYM2U744` |
| SKU | `jiyul-001` |
| Primary Language | Korean (한국어) |

## Categories

- **Primary:** Games > Puzzle
- **Secondary:** Games > Family
  - If filing as a Kids App, switch the Primary to **Kids** and add
    age band **6–8**. (Apple Kids Category review imposes COPPA-style
    requirements — Jiyul already collects zero data so the privacy
    answer is straightforward, but the parental gate requirement may
    apply to the Settings → Reset action.)

## Age Rating

- **4+** — no objectionable content.

## App Privacy ("Nutrition Label")

- **Data Used to Track You:** None
- **Data Linked to You:** None
- **Data Not Linked to You:** None
- **Data Not Collected:** ✓

## Promotional Text (max 170)

A warm daily 17×10 sum-to-10 puzzle. Drag rectangles that add to 10 to
clear them. See if you can beat today's bot. Jiyul and Eunchan cheer
you on.

## Description (max 4000)

Jiyul is a calm daily puzzle for one player.

Drag any rectangle on the 17×10 grid of digits 1–9. If the digits in
the rectangle add up to exactly 10, they clear and your score goes up
by however many cells you cleared. You have two minutes. Same puzzle
worldwide, every day, KST midnight.

Every round ships with an "오늘의 봇 점수" — a deterministic in-app
solver that runs on the same board and posts its score for the day.
Can you beat it?

Jiyul and her friend Eunchan show up across the app, with a friendly
mint dragon, a lavender spider, and an apple-green snake. The
encouragement copy is bilingual (Korean and English) and addresses
"지율" by default — you can change the player name in Settings.

100% offline. No accounts, no ads, no analytics, no tracking. Your
records stay on your device.

## Keywords (max 100 chars, comma-separated)

```
daily,puzzle,sum,ten,fruit box,사과게임,jiyul,kids,family,korean
```

## URLs

| Field | Value |
|---|---|
| Support URL | https://github.com/jinnsim/jiyul |
| Marketing URL | https://github.com/jinnsim/jiyul |
| Privacy Policy URL | _Host `docs/privacy.md` (e.g. GitHub Pages) and paste here_ |

## Screenshots required

| Device | Resolution | Min count |
|---|---|---|
| iPhone 6.7" (15/16 Pro Max) | 1290 × 2796 | 3 |
| iPhone 6.5" (XS/11 Pro Max) | 1242 × 2688 | optional |
| iPad 12.9" (Pro) | 2048 × 2732 | 3 (since iPad is supported) |

Suggested captures from Simulator (manual):

1. **Splash** — let app launch, capture before the splash dismisses
   (1.2 s window).
2. **Home** — Welcome-back illustration + encouragement line + CTA.
3. **Game mid-round** — board with a few cells cleared, drag selection
   active showing live sum.
4. **Result** — player vs bot side-by-side with encouragement card.
5. **Stats** — 30-day sparkline + four metrics.

Use `xcrun simctl io booted screenshot path.png` for each.

## TestFlight Beta App Description

Family-and-friends beta for Jiyul, a daily 17×10 sum-to-10 puzzle. No
data collection, fully offline. Feedback welcome: ootssu@ootssu.com.

## Review Notes (for App Store reviewer)

- The app is a single-player offline puzzle. No login, no network
  calls. The "share" button uses the standard system share sheet to
  share a locally-rendered PNG of the player's score.
- The encouragement text is read from a bundled JSON file. No remote
  config or A/B testing.
- The bot score is computed by a deterministic on-device beam-search
  solver. Same board + same solver profile always produces the same
  bot score.

## Build / Upload

```bash
# 1. Archive
./ios/scripts/build-archive.sh

# 2. (Once) edit ios/ExportOptions.plist — set method to
#    "app-store-connect" for TestFlight, or keep "development" for
#    sideload.

# 3. Export
./ios/scripts/export-ipa.sh

# 4. Upload to App Store Connect with Transporter.app (drag the .ipa)
#    or:
xcrun altool --upload-app -f ./build/ipa/Tendle.ipa \
  -t ios -u <APPLE_ID> -p <APP_SPECIFIC_PASSWORD>
```
