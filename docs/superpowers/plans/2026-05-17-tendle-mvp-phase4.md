# Tendle MVP Phase 4 — Release-ready Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Context:** Apple Developer setup is complete — Bundle ID
`com.jinnsim.Tendle` registered, Team ID `LQZYM2U744` wired into
`project.yml`, automatic signing verified (ARCHIVE SUCCEEDED for
Release configuration on generic/iOS device target). Phase 4 turns the
working app into something the owner can sideload onto Jiyul's device,
TestFlight to family, or submit to the App Store.

**Goal:** Ship-ready iOS build with privacy disclosures, an export
pipeline, an anytime solver for live-updating bot score, and tighter
ResultView behavior. No feature growth beyond what Apple/App Store
distribution actually needs.

**Architecture:** No structural changes. Add docs, scripts, two
incremental changes to existing services. ExportArchive uses the
existing project; ExportOptions.plist drives `xcodebuild -exportArchive`.

**Tech Stack:** Same as Phase 3 + `xcodebuild -exportArchive` + manual
App Store Connect upload (Transporter or `xcrun altool`).

**Out of Phase 4 scope** (deferred):
- GameKit leaderboards / push notifications / web companion.
- `NavigationSplitView` sidebar on iPad (current ViewThatFits is sufficient).
- Custom-designed `.caf` sound clips (system-derived stays for now).
- XCUITest automated screenshots (manual is faster for personal release).

**Phase 4 success criterion:** an engineer can run
`ios/scripts/build-archive.sh` and produce a signed Tendle.xcarchive,
then `ios/scripts/export-ipa.sh` to produce an `.ipa` ready for
Transporter or TestFlight. The Settings/About surface points to the
shipped privacy policy. The bot score on `ResultView` keeps ticking
upward (anytime emission) until it finalizes.

---

## File Structure (additions only)

```
docs/
  privacy.md                          # plain-text privacy policy
  app-store-metadata.md               # listing fields ready to paste
ios/
  ExportOptions.plist                 # for xcodebuild -exportArchive
  scripts/
    build-archive.sh                  # xcodebuild archive → ./build/
    export-ipa.sh                     # xcodebuild -exportArchive → ./build/
  Tendle/Resources/
    Info.plist                        # add NSPrivacyTracking, etc.
```

---

## Phase 4 Plan

### Task 1: Privacy policy + App Store metadata template

**Files:**
- Create: `docs/privacy.md`
- Create: `docs/app-store-metadata.md`
- Modify: `ios/project.yml` (add `NSUserTrackingUsageDescription`-style
  Info.plist privacy keys via `properties:` map)

- [ ] **Step 1: privacy.md** (Korean + English, plain markdown)

```markdown
# Jiyul — Privacy Policy

**Last updated:** 2026-05-17

## English

Jiyul is a single-player daily puzzle game built for Jiyul and her
family. The app:

- **Does not collect any personal information** from anyone, including
  children. Nothing is uploaded, shared, transmitted, or sold.
- **Does not use third-party analytics, advertising, or tracking SDKs.**
- **Stores only locally on your device** the day's score, your streak,
  the player name you set in Settings (default "지율"), and your
  language/sound preferences. This data lives in SwiftData on the device
  and never leaves it.
- **Plays a sound** through the system audio when you clear a rectangle,
  if you've enabled sound in Settings.
- **Reads the device clock** to determine which puzzle is "today's"
  in the Asia/Seoul timezone. No location data is read.

If you have questions, contact: **jinnsim@gmail.com**.

## 한국어

지율은 지율이와 가족을 위해 만든 1인 데일리 퍼즐 게임입니다.

- **누구의 개인정보도 수집하지 않습니다.** 어린이 포함. 아무것도
  업로드/공유/전송/판매하지 않습니다.
- **타사 분석/광고/추적 SDK를 사용하지 않습니다.**
- **기기 안에만 저장합니다**: 오늘 점수, 연속일, 설정에서 정한 플레이어
  이름(기본 "지율"), 언어/사운드 설정. SwiftData로 디바이스 내부에만
  존재하고 외부로 나가지 않습니다.
- 사각형을 지웠을 때 시스템 사운드를 재생합니다 (설정에서 끌 수
  있습니다).
- 오늘의 퍼즐을 정하기 위해 기기 시계를 KST 기준으로 읽습니다. 위치
  정보는 읽지 않습니다.

문의: **jinnsim@gmail.com**
```

- [ ] **Step 2: app-store-metadata.md**

```markdown
# Jiyul — App Store Listing Metadata

## Primary Category
Games > Puzzle

## Secondary Category
Games > Family (if filing as Kids category, switch to that and add the
required age band 6-8)

## Bundle ID
com.jinnsim.Tendle

## SKU
jiyul-001

## App Name (max 30)
Jiyul

## Subtitle (max 30)
Daily puzzle with Jiyul

## Promotional Text (max 170)
A warm daily 17×10 sum-to-10 puzzle. Drag rectangles that add to 10 to
clear them. See if you can beat today's bot. Jiyul and Eunchan cheer you on.

## Description (4000 max)
Jiyul is a calm daily puzzle for one player.

Drag any rectangle on the 17×10 grid of digits 1–9. If the digits in
the rectangle add up to exactly 10, they clear and your score goes up
by however many cells you cleared. You have two minutes. Same puzzle
worldwide, every day, KST midnight.

Every round ships with an "오늘의 봇 점수" — a deterministic in-app
solver that runs on the same board and posts its score for the day. Can
you beat it?

Jiyul and her friend Eunchan show up across the app, with a friendly
mint dragon, a lavender spider, and an apple-green snake. The
encouragement copy is bilingual (Korean and English) and addresses
"지율" by default — you can change the player name in Settings.

100% offline. No accounts, no ads, no analytics, no tracking. Your
records stay on your device.

## Keywords (100 chars, comma-separated)
daily,puzzle,sum,ten,fruit box,사과게임,jiyul,kids,family,korean

## Support URL
https://github.com/jinnsim/jiyul

## Marketing URL
https://github.com/jinnsim/jiyul

## Privacy Policy URL
(Host `docs/privacy.md` somewhere, e.g. GitHub Pages, then paste here)

## Age Rating
4+ (no objectionable content)

## App Privacy "Nutrition Label"
- Data Used to Track You: **None**
- Data Linked to You: **None**
- Data Not Linked to You: **None**
- Data Not Collected: ✓ (only category)

## Screenshots Required
- iPhone 6.7" (1290 × 2796) — at least 3
- iPhone 6.5" (1242 × 2688) — at least 3 (optional if 6.7" present)
- iPad 12.9" (2048 × 2732) — at least 3 if iPad target included

Manual capture from Simulator:
1. Splash (auto, freeze after launch)
2. Home with Welcome-back illustration
3. Game in-progress mid-round
4. Result with bot comparison + encouragement
5. Stats with 30-day sparkline

## TestFlight Beta Description
Family-and-friends beta for Jiyul, a daily 17×10 sum-to-10 puzzle. No
data collection, fully offline. Feedback welcome: jinnsim@gmail.com.
```

- [ ] **Step 3: Add privacy Info.plist keys via project.yml**

In `properties:` map under target `Tendle`, append:

```yaml
        ITSAppUsesNonExemptEncryption: false
        NSPrivacyAccessedAPITypes:
          - NSPrivacyAccessedAPIType: NSPrivacyAccessedAPICategoryUserDefaults
            NSPrivacyAccessedAPITypeReasons:
              - CA92.1
```

(`CA92.1` is the standard reason for "App functionality" UserDefaults
access. `ITSAppUsesNonExemptEncryption: false` because Jiyul only uses
HTTPS-equivalent system APIs (SwiftData), no custom crypto.)

- [ ] **Step 4: Build + commit**

```bash
cd /Users/jongjinseok/Documents/Tendle/ios && /Users/jongjinseok/.local/bin/xcodegen generate
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
git add docs/privacy.md docs/app-store-metadata.md ios/project.yml ios/Tendle/Info.plist
git commit -m "docs(p4): privacy policy + App Store metadata + Info.plist privacy keys (P4.T1)"
git push origin main
```

---

### Task 2: ExportOptions.plist + build/export scripts

**Files:**
- Create: `ios/ExportOptions.plist`
- Create: `ios/scripts/build-archive.sh`
- Create: `ios/scripts/export-ipa.sh`

- [ ] **Step 1: ExportOptions.plist** (Development for sideload; switch
  `method` to `app-store-connect` before uploading to TestFlight)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>LQZYM2U744</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
```

- [ ] **Step 2: build-archive.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
mkdir -p build
cd ios && /Users/jongjinseok/.local/bin/xcodegen generate
cd "$ROOT"
xcodebuild \
  -project ios/Tendle.xcodeproj \
  -scheme Tendle \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ./build/Tendle.xcarchive \
  archive
echo "Archive at ./build/Tendle.xcarchive"
```

- [ ] **Step 3: export-ipa.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
xcodebuild \
  -exportArchive \
  -archivePath ./build/Tendle.xcarchive \
  -exportPath ./build/ipa \
  -exportOptionsPlist ios/ExportOptions.plist
echo "IPA exported to ./build/ipa/Tendle.ipa"
```

- [ ] **Step 4: Make executable + smoke-test archive (don't export)**

```bash
chmod +x ios/scripts/build-archive.sh ios/scripts/export-ipa.sh
./ios/scripts/build-archive.sh   # ARCHIVE SUCCEEDED
# Skip ./ios/scripts/export-ipa.sh in CI — it talks to Apple's signing servers
```

- [ ] **Step 5: Commit**

```bash
git add ios/ExportOptions.plist ios/scripts/build-archive.sh ios/scripts/export-ipa.sh
git commit -m "build(p4): ExportOptions.plist + build-archive.sh + export-ipa.sh (P4.T2)"
git push origin main
```

---

### Task 3: Anytime solver — incremental SolverProgress emission

**Files:**
- Modify: `ios/Tendle/Services/Solver.swift`

The current `solve` runs to completion and emits a single
`SolverProgress(isFinal: true)`. The anytime variant emits a
`SolverProgress(isFinal: false)` whenever `bestRealizedScore`
improves, then the final at termination.

- [ ] **Step 1: Refactor `Solver.solve` to accept an optional `progress`
  callback**

Add an internal overload:

```swift
extension Solver {
    static func solve(
        _ board: Board,
        profile: SolverProfile = .mvpV1,
        onProgress: ((Int, Int) -> Void)? = nil
    ) -> SolverResult {
        // Same logic, but whenever `best.score` improves, call
        // `onProgress(best.score, expandedStates)`.
        ...
    }
}
```

Modify the inner loop's `best = successor` branch:

```swift
if isBetterRealized(successor, than: best) {
    best = successor
    onProgress?(best.score, expandedStates)
}
```

Then update `solveAsync` to wire it:

```swift
static func solveAsync(
    _ board: Board,
    profile: SolverProfile = .mvpV1
) -> (AsyncStream<SolverProgress>, Task<Void, Never>) {
    let (stream, continuation) = AsyncStream.makeStream(of: SolverProgress.self)
    let task = Task.detached(priority: .background) {
        let result = Solver.solve(board, profile: profile) { score, expanded in
            if Task.isCancelled { return }
            continuation.yield(SolverProgress(
                bestScore: score, expandedStates: expanded, isFinal: false))
        }
        if !Task.isCancelled {
            continuation.yield(SolverProgress(
                bestScore: result.score,
                expandedStates: result.expandedStates,
                isFinal: true))
        }
        continuation.finish()
    }
    return (stream, task)
}
```

- [ ] **Step 2: No new tests required** — existing `SolverTests` exercise
  the no-callback path; the callback path is incremental UI sugar.

- [ ] **Step 3: Build + test (fast suite)**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
  -skip-testing:TendleTests/SolverTests/testIsDeterministicAcrossReruns test
```

Expect: all 38+ tests still pass.

- [ ] **Step 4: Commit**

```bash
git add ios/Tendle/Services/Solver.swift
git commit -m "feat(solver): anytime emission — onProgress callback wired into solveAsync (P4.T3)"
git push origin main
```

---

### Task 4: ResultView bot-finalize integration check

**Files:**
- (verify only) `ios/Tendle/Views/ResultView.swift`
- (verify only) `ios/Tendle/App/RootView.swift`

After P4.T3 the live coordinator emits incremental `SolverProgress`
during the round, including `.pending` updates after `phase == .ended`
if the solver is still running on the result screen.

- [ ] **Step 1: Confirm `ResultView` already observes `liveCoordinator`**

In `ResultView.botText` and `currentBotScore`, the existing P2.T5 +
round-3 code reads `liveCoordinator?.session.solverProgress` — that
property is `@Observable` (via `@Observable GameCoordinator`), so
SwiftUI re-renders on update. No code change.

- [ ] **Step 2: Manual smoke** — start a round, finish quickly (say,
  after 10 s of intentional inaction), watch ResultView's bot field
  show "…" and then the bot's score appear within a few seconds.
  Capture screenshot.

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
  -derivedDataPath ./build_smoke build
xcrun simctl uninstall booted com.jinnsim.Tendle
xcrun simctl install booted ./build_smoke/Build/Products/Debug-iphonesimulator/Tendle.app
xcrun simctl launch booted com.jinnsim.Tendle
# manual: play, finish quickly, watch Result
xcrun simctl io booted screenshot docs/screenshots/p4-result-live-bot.png
rm -rf build_smoke
```

- [ ] **Step 3: Commit** (just the screenshot)

```bash
git add docs/screenshots/p4-result-live-bot.png
git commit -m "docs(p4): verify ResultView live-updates bot score via anytime emission (P4.T4)"
```

---

### Task 5: handoff log + final commit

- [ ] **Step 1: Append Phase 4 to docs/handoff.md** describing all of
  the above: privacy policy, metadata, ExportOptions, scripts, anytime
  solver, signing wired.

- [ ] **Step 2: Push**

```bash
git add docs/handoff.md
git commit -m "docs(p4): handoff — release infrastructure complete (P4.T5)"
git push origin main
```

---

## Self-Review

**Spec coverage check:**
- §5.1 anytime solver — covered in T3.
- §13.1 App Store posture — privacy policy (T1), metadata template (T1).
- §5.4 UI/Determinism contract — T4 verifies the live-update path.

**No placeholders.** No new test gaps; existing fast suite covers the
refactored Solver.

**Type consistency:** `Solver.solve` adds an optional callback; existing
call sites compile unchanged because the parameter has a default of
`nil`. `solveAsync` is the only call site that passes the callback.

**Known limitation:** Privacy policy URL in metadata is a placeholder
— the user must host `docs/privacy.md` (e.g. GitHub Pages) and paste
the URL into App Store Connect.
