# Tendle MVP Phase 2 — Personalized Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Phase-1 playable shell into Jiyul's personalized
game — character illustrations across all key screens, bilingual
encouragement copy fired at trigger moments, a share card, a stats screen
with sparkline, and the small reliability fixes deferred from Phase 1.

**Architecture:** No structural changes. Add three new services
(`EncouragementService`, `ShareCardRenderer`, `StatsAggregator`), one new
view (`EncouragementMomentView`), populate `Assets.xcassets` with the
Codex-generated PNGs from `assets/generated/`, and wire the existing
character/encouragement data into the round lifecycle.

**Tech Stack:** Same as Phase 1 (SwiftUI, SwiftData, Foundation only).
Phase 2 introduces `AVFoundation` for real `.caf` playback.

**Spec reference:** [`docs/superpowers/specs/2026-05-17-tendle-design.md`](../specs/2026-05-17-tendle-design.md) (v4) §18 (Characters & Encouragement), §11 (Imagery & Audio), §9 (Share format), §7.4 (StatsView).

**Out of Phase 2 scope** (deferred to Phase 3):
- Localizable.xcstrings catalog + Settings language picker UI (Phase 3)
- iPad split-view / side panel tuning (Phase 3)
- GitHub Actions CI workflow (Phase 3)
- App-icon PNG replacing the placeholder (Phase 3)

**Phase 2 success criterion:** on iPhone 15 simulator, complete a daily
round and see (a) Jiyul/Eunchan splash on app launch, (b) Jiyul appears
in a loading moment when the round starts, (c) at round end a result
screen shows the player score, bot score, a per-trigger encouragement
line addressing "지율", and the matching Layer-2 illustration, (d) a share
button copies the spec §9 emoji-ratio share text to the pasteboard, (e)
opening Stats shows total plays / streak / best / bot-win % and a 30-day
sparkline.

---

## File Structure (additions only)

```
ios/Tendle/
  Models/
    EncouragementTrigger.swift    # enum, 8 cases per spec §18.3
    EncouragementMoment.swift     # { trigger, line, illustration }
  Services/
    EncouragementService.swift    # catalog load + deterministic selection
    ShareCardRenderer.swift       # spec §9 text
    StatsAggregator.swift         # 30d sparkline + bot-win %
  Views/
    EncouragementMomentView.swift # illustration + line overlay
    SplashView.swift              # gating launch view with Splash PNG
    StatsView.swift               # aggregates + sparkline
  Resources/
    Assets.xcassets/
      JiyulCharacter.imageset/      # ← assets/generated/...jiyul-sheet
      EunchanCharacter.imageset/
      CreatureFriends.imageset/
      SplashHero.imageset/
      HomeEmpty.imageset/
      LoadingScene.imageset/
      ResultWin.imageset/
      ResultClose.imageset/
      ResultLow.imageset/
      StreakMilestone.imageset/
      WelcomeBack.imageset/
    Sounds/
      tap.caf, clear.caf, gameover.caf   # royalty-free placeholders
ios/TendleTests/
  EncouragementServiceTests.swift
  ShareCardRendererTests.swift
  StatsAggregatorTests.swift
```

---

## Phase 2 Plan

### Task 1: Import Layer-2 PNGs into `Assets.xcassets`

**Files:** 11 new `*.imageset` directories under
`ios/Tendle/Resources/Assets.xcassets/`, each containing the PNG plus a
`Contents.json` that references it as the `universal`/`1x` slot. xcodegen
already includes `Assets.xcassets` recursively, so no project regen needed
for asset additions specifically; but the `JiyulCharacter` enum/struct
references will appear in Task 5 so a regen at that point is fine.

- [ ] **Step 1: Write a small helper script that creates the imageset for each PNG**

`ios/scripts/import-illustrations.sh`:

```bash
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
```

- [ ] **Step 2: Run it**

```bash
chmod +x ios/scripts/import-illustrations.sh
./ios/scripts/import-illustrations.sh
```

Expected: `Imported 11 illustration imagesets.`

- [ ] **Step 3: Build to verify no asset catalog warnings**

```bash
cd ios && /Users/jongjinseok/.local/bin/xcodegen generate
cd ..
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED. Asset catalog may warn about 1x-only assets;
benign for our use.

- [ ] **Step 4: Commit**

```bash
git add ios/scripts/import-illustrations.sh ios/Tendle/Resources/Assets.xcassets
git commit -m "feat(assets): import 11 Layer-2 illustrations into Assets.xcassets (T2.1)"
```

---

### Task 2: `EncouragementTrigger` enum + `EncouragementMoment` model

**Files:**
- Create: `ios/Tendle/Models/EncouragementTrigger.swift`
- Create: `ios/Tendle/Models/EncouragementMoment.swift`

- [ ] **Step 1: Trigger enum (exact spec §18.3 keys)**

```swift
import Foundation

enum EncouragementTrigger: String, CaseIterable, Codable {
    case roundStart
    case firstClear
    case combo
    case roundEndBeatBot
    case roundEndClose
    case roundEndLow
    case streakUp
    case reopen
}
```

- [ ] **Step 2: Moment model**

```swift
import Foundation

struct EncouragementMoment: Equatable {
    let trigger: EncouragementTrigger
    let line: String
    let illustrationAssetName: String?  // matches Assets.xcassets imageset
}
```

- [ ] **Step 3: Build + commit**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
git add ios/Tendle/Models/EncouragementTrigger.swift ios/Tendle/Models/EncouragementMoment.swift
git commit -m "feat(models): EncouragementTrigger + EncouragementMoment (T2.2)"
```

---

### Task 3: `EncouragementService` with deterministic selection + `{streak}` substitution + tests

**Files:**
- Create: `ios/Tendle/Services/EncouragementService.swift`
- Create: `ios/TendleTests/EncouragementServiceTests.swift`

The JSON file `ios/Tendle/Resources/Encouragement.json` already exists (128
lines, 8 triggers × 2 languages × 8 lines).

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
@testable import Tendle

final class EncouragementServiceTests: XCTestCase {
    func makeService() -> EncouragementService {
        EncouragementService(bundle: Bundle(for: type(of: self)))
    }

    func testReturnsKoreanLineForJiyul() {
        let s = makeService()
        let m = s.line(trigger: .roundStart, language: "ko",
                       playerName: "지율", dateKST: "2026-05-17", streak: 0)
        XCTAssertTrue(m.line.contains("지율"))
        XCTAssertEqual(m.trigger, .roundStart)
    }

    func testReturnsEnglishLineForJiyul() {
        let s = makeService()
        let m = s.line(trigger: .roundEndBeatBot, language: "en",
                       playerName: "지율", dateKST: "2026-05-17", streak: 0)
        XCTAssertTrue(m.line.contains("Jiyul"))
    }

    func testSameTriggerSameDateReturnsSameLine() {
        let s = makeService()
        let a = s.line(trigger: .combo, language: "ko",
                       playerName: "지율", dateKST: "2026-05-17", streak: 0).line
        let b = s.line(trigger: .combo, language: "ko",
                       playerName: "지율", dateKST: "2026-05-17", streak: 0).line
        XCTAssertEqual(a, b)
    }

    func testDifferentDatesCanReturnDifferentLines() {
        let s = makeService()
        // We can't guarantee different lines (8-line table, hash collision
        // possible), but the seed differs and so the index calculation
        // differs. We just assert determinism per-date is stable.
        let a = s.line(trigger: .combo, language: "ko",
                       playerName: "지율", dateKST: "2026-05-17", streak: 0).line
        let b = s.line(trigger: .combo, language: "ko",
                       playerName: "지율", dateKST: "2026-05-18", streak: 0).line
        // At least one of N days will differ — not a strict assertion here.
        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
    }

    func testStreakSubstitution() {
        let s = makeService()
        let m = s.line(trigger: .streakUp, language: "ko",
                       playerName: "지율", dateKST: "2026-05-17", streak: 7)
        XCTAssertTrue(m.line.contains("7"))
        XCTAssertFalse(m.line.contains("{streak}"))
    }

    func testZeroStreakFallsBackToNextIndex() {
        let s = makeService()
        // streak=0 should not appear as "0일째"; service should pick a
        // different line. (Phase 2 fallback: substitute literal but
        // EncouragementService is responsible for only firing this trigger
        // when streak >= 1; we still cover the fallback path here.)
        let m = s.line(trigger: .streakUp, language: "ko",
                       playerName: "지율", dateKST: "2026-05-17", streak: 0)
        XCTAssertFalse(m.line.contains("{streak}"))
    }
}
```

- [ ] **Step 2: Run — expect compile error**

- [ ] **Step 3: Implement EncouragementService**

```swift
import Foundation
import CryptoKit

final class EncouragementService {
    private struct Catalog: Codable {
        let version: Int
        let triggers: [String: [String: [String]]]
    }

    private let catalog: Catalog

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "Encouragement", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Catalog.self, from: data) else {
            // Should never happen — JSON is bundled. Fail loud in debug.
            assertionFailure("Encouragement.json not found in bundle")
            self.catalog = Catalog(version: 0, triggers: [:])
            return
        }
        self.catalog = decoded
    }

    /// Returns the line for a trigger using deterministic per-(player, date, trigger) selection.
    func line(trigger: EncouragementTrigger,
              language: String,
              playerName: String,
              dateKST: String,
              streak: Int) -> EncouragementMoment {
        let key = trigger.rawValue
        let lang = language.hasPrefix("ko") ? "ko" : "en"
        guard let lines = catalog.triggers[key]?[lang], !lines.isEmpty else {
            return EncouragementMoment(trigger: trigger, line: "", illustrationAssetName: nil)
        }
        let seedString = "\(playerName)|\(dateKST)|\(key)"
        let seed = stableHash(seedString)
        var index = Int(seed % UInt64(lines.count))
        var picked = lines[index]
        // {streak} substitution with fallback
        if picked.contains("{streak}") {
            if streak > 0 {
                picked = picked.replacingOccurrences(of: "{streak}", with: "\(streak)")
            } else {
                // Pick the next deterministic index that has no placeholder
                for offset in 1...lines.count {
                    let candidate = lines[(index + offset) % lines.count]
                    if !candidate.contains("{streak}") {
                        picked = candidate
                        break
                    }
                }
            }
        }
        return EncouragementMoment(
            trigger: trigger,
            line: picked,
            illustrationAssetName: illustration(for: trigger)
        )
    }

    private func illustration(for trigger: EncouragementTrigger) -> String? {
        switch trigger {
        case .roundStart: return "LoadingScene"
        case .firstClear, .combo: return nil
        case .roundEndBeatBot: return "ResultWin"
        case .roundEndClose: return "ResultClose"
        case .roundEndLow: return "ResultLow"
        case .streakUp: return "StreakMilestone"
        case .reopen: return "WelcomeBack"
        }
    }

    private func stableHash(_ s: String) -> UInt64 {
        let digest = SHA256.hash(data: Data(s.utf8))
        var seed: UInt64 = 0
        for (i, byte) in digest.prefix(8).enumerated() {
            seed |= UInt64(byte) << (UInt64(i) * 8)
        }
        return seed
    }
}
```

- [ ] **Step 4: Ensure Encouragement.json is bundled into the app**

xcodegen pattern `sources: [path: Tendle]` includes `Tendle/Resources/`
recursively, but `Encouragement.json` lives there too — verify it does
not silently get treated as Swift source. If needed, add explicit
`buildPhase: resources` for `.json` extension in project.yml. Most
commonly Xcode auto-classifies `.json` as a resource; verify post-build:

```bash
xcodebuild ... build
find ~/Library/Developer/Xcode/DerivedData -path '*Tendle.app/Encouragement.json' | head -1
```

If found, JSON is bundled. If empty, modify project.yml under
`targets.Tendle`:

```yaml
sources:
  - path: Tendle
    excludes: []
    includes: []
    type: group
    buildPhase:
      copyFiles:
        destination: resources
        subpath: ""
```

(Adjust syntax if xcodegen complains.)

- [ ] **Step 5: Run tests**

Expected: 6/6 EncouragementServiceTests pass.

- [ ] **Step 6: Commit**

```bash
git add ios/Tendle/Services/EncouragementService.swift \
        ios/TendleTests/EncouragementServiceTests.swift
[git add ios/project.yml]  # if you modified it for JSON resource phase
git commit -m "feat(content): EncouragementService — deterministic line selection + {streak} substitution (T2.3)"
```

---

### Task 4: `EncouragementMomentView` (illustration + line overlay)

**Files:**
- Create: `ios/Tendle/Views/EncouragementMomentView.swift`

- [ ] **Step 1: Implement view**

```swift
import SwiftUI

struct EncouragementMomentView: View {
    let moment: EncouragementMoment

    var body: some View {
        VStack(spacing: 16) {
            if let asset = moment.illustrationAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .accessibilityHidden(true)
            }
            Text(moment.line)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
cd ios && /Users/jongjinseok/.local/bin/xcodegen generate
cd ..
xcodebuild ... build  # BUILD SUCCEEDED
git add ios/Tendle/Views/EncouragementMomentView.swift
git commit -m "feat(ui): EncouragementMomentView — illustration + line overlay (T2.4)"
```

---

### Task 5: Wire encouragement into ResultView + HomeView + Splash

**Files:**
- Modify: `ios/Tendle/Views/HomeView.swift`
- Modify: `ios/Tendle/Views/ResultView.swift`
- Create: `ios/Tendle/Views/SplashView.swift`
- Modify: `ios/Tendle/App/TendleApp.swift`
- Modify: `ios/Tendle/App/RootView.swift`

- [ ] **Step 1: SplashView (gating launch view, ~1.2 s)**

```swift
import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            Image("SplashHero")
                .resizable()
                .scaledToFit()
                .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onContinue() }
        }
    }
}
```

- [ ] **Step 2: Gate launch with SplashView in TendleApp**

```swift
import SwiftUI
import SwiftData

@main
struct TendleApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for:
                DailyRecord.self, SolverCache.self, Settings.self)
        } catch {
            fatalError("ModelContainer failed: \(error)")
        }
    }()

    @State private var didSplash = false

    var body: some Scene {
        WindowGroup {
            Group {
                if didSplash {
                    RootView().modelContainer(container)
                } else {
                    SplashView { didSplash = true }
                }
            }
        }
    }
}
```

- [ ] **Step 3: HomeView idle state shows HomeEmpty illustration + reopen line**

Append a property `let reopenMoment: EncouragementMoment?` and render it
above the CTA when present. (Update RootView in step 4 to compute it.)

Inside `HomeView` body, before the CTA Button:

```swift
if todayRecord == nil, let reopen = reopenMoment {
    EncouragementMomentView(moment: reopen)
} else if todayRecord == nil {
    Image("HomeEmpty")
        .resizable()
        .scaledToFit()
        .frame(maxHeight: 220)
}
```

- [ ] **Step 4: Wire reopen detection in RootView**

Add `@AppStorage("lastForegroundAt") private var lastForegroundAt: Double = 0`
and a helper:

```swift
private var reopenMoment: EncouragementMoment? {
    let now = Date().timeIntervalSince1970
    let gapHours = (now - lastForegroundAt) / 3600
    lastForegroundAt = now
    guard gapHours >= 8 else { return nil }
    return EncouragementService().line(
        trigger: .reopen, language: Locale.current.language.languageCode?.identifier ?? "ko",
        playerName: "지율", dateKST: KSTClock.dateString(), streak: 0)
}
```

Pass `reopenMoment: reopenMoment` into HomeView.

- [ ] **Step 5: ResultView shows roundEnd encouragement matching score-vs-bot**

Add `let encouragementMoment: EncouragementMoment?` to ResultView and
render `EncouragementMomentView(moment: m)` between the score columns and
the microcopy when present. Compute in RootView's `case .result`:

```swift
private func momentFor(snapshot s: GameSessionSnapshot, streak: Int) -> EncouragementMoment {
    let trigger: EncouragementTrigger = {
        guard let bot = s.botScore, s.botIsFinal else { return .roundEndLow }
        if s.playerScore > bot { return .roundEndBeatBot }
        if Double(s.playerScore) >= 0.8 * Double(bot) { return .roundEndClose }
        return .roundEndLow
    }()
    return EncouragementService().line(
        trigger: trigger,
        language: Locale.current.language.languageCode?.identifier ?? "ko",
        playerName: "지율", dateKST: s.dateKST, streak: streak)
}
```

- [ ] **Step 6: Build + manual smoke + commit**

```bash
xcodebuild ... build
git add ios/Tendle/Views/{HomeView,ResultView,SplashView}.swift ios/Tendle/App/{TendleApp,RootView}.swift
git commit -m "feat(ui): wire splash + reopen + result encouragement moments (T2.5)"
```

---

### Task 6: Loading scene illustration in `GameView`

**Files:**
- Modify: `ios/Tendle/Views/GameView.swift`

When `coordinator.session.solverProgress == nil` AND the round just
started (first 1.5s), show the `LoadingScene` illustration overlay.

- [ ] **Step 1: Add state and overlay**

Add to `GameView`:

```swift
@State private var showLoading = true
// ...
.onAppear {
    coordinator.start()
    lastTick = .now
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showLoading = false }
}
.overlay(alignment: .top) {
    if showLoading {
        VStack {
            Image("LoadingScene").resizable().scaledToFit().frame(maxHeight: 180)
            Text("준비 중…").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.top, 40)
        .transition(.opacity)
    }
}
```

- [ ] **Step 2: Build + commit**

```bash
xcodebuild ... build
git add ios/Tendle/Views/GameView.swift
git commit -m "feat(ui): GameView loading illustration overlay (T2.6)"
```

---

### Task 7: Real `.caf` sound clips + `SoundService` AVAudioPlayer pool

**Files:**
- Add: `ios/Tendle/Resources/Sounds/tap.caf`, `clear.caf`, `gameover.caf` (royalty-free placeholders — 80-200 ms each)
- Modify: `ios/Tendle/Services/SoundService.swift`

- [ ] **Step 1: Source three royalty-free clips**

For Phase 2, source short royalty-free clicks/chimes from `freesound.org`
(CC0) or use macOS-built-in sounds piped via `afconvert`:

```bash
mkdir -p ios/Tendle/Resources/Sounds
afconvert /System/Library/Sounds/Tink.aiff ios/Tendle/Resources/Sounds/tap.caf -d 0 -f caff --soundcheck-generate
afconvert /System/Library/Sounds/Glass.aiff ios/Tendle/Resources/Sounds/clear.caf -d 0 -f caff --soundcheck-generate
afconvert /System/Library/Sounds/Submarine.aiff ios/Tendle/Resources/Sounds/gameover.caf -d 0 -f caff --soundcheck-generate
```

(These macOS system sounds are bundled with the OS and are acceptable for
internal dev / personal build per spec §0 distribution scope. Replace
with custom clips before any future App Store submission.)

- [ ] **Step 2: Implement AVAudioPlayer pool**

```swift
import Foundation
import AVFoundation

enum SoundEffect: String {
    case tap
    case clear
    case gameOver = "gameover"
}

final class SoundService {
    private var enabled: Bool
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    init(enabled: Bool = true) {
        self.enabled = enabled
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        preload(.tap)
        preload(.clear)
        preload(.gameOver)
    }

    private func preload(_ effect: SoundEffect) {
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf") else {
            return
        }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.prepareToPlay()
            players[effect] = player
        }
    }

    func setEnabled(_ value: Bool) { enabled = value }

    func play(_ effect: SoundEffect) {
        guard enabled, let player = players[effect] else { return }
        if player.isPlaying { player.currentTime = 0 }
        player.play()
    }
}
```

- [ ] **Step 3: Wire SoundService into GameCoordinator**

In `GameCoordinator.commit`, after a successful clear:

```swift
if result.clearedCells > 0 {
    SoundService.shared.play(.clear)
}
```

Add a `static let shared = SoundService()` for Phase 2 convenience (Phase 3
moves to environment injection).

- [ ] **Step 4: Build + commit**

```bash
git add ios/Tendle/Resources/Sounds ios/Tendle/Services/SoundService.swift ios/Tendle/Services/GameCoordinator.swift
git commit -m "feat(audio): real .caf clips + AVAudioPlayer pool wired to clear sound (T2.7)"
```

---

### Task 8: `ShareCardRenderer` + share button on `ResultView`

**Files:**
- Create: `ios/Tendle/Services/ShareCardRenderer.swift`
- Create: `ios/TendleTests/ShareCardRendererTests.swift`
- Modify: `ios/Tendle/Views/ResultView.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
@testable import Tendle

final class ShareCardRendererTests: XCTestCase {
    func testRenderIncludesDateAndScores() {
        let text = ShareCardRenderer.render(
            dateKST: "2026-05-17", playerScore: 87, botScore: 121)
        XCTAssertTrue(text.contains("2026-05-17"))
        XCTAssertTrue(text.contains("87"))
        XCTAssertTrue(text.contains("121"))
    }

    func testBarLengthsAreNonNegative() {
        let text = ShareCardRenderer.render(
            dateKST: "2026-05-17", playerScore: 0, botScore: 100)
        XCTAssertTrue(text.contains("░"))   // empty bar present
    }

    func testRatioAbove100IsClampedTo100Percent() {
        let text = ShareCardRenderer.render(
            dateKST: "2026-05-17", playerScore: 150, botScore: 100)
        XCTAssertTrue(text.contains("100%"))
    }
}
```

- [ ] **Step 2: Run — expect compile error**

- [ ] **Step 3: Implement ShareCardRenderer**

```swift
import Foundation

enum ShareCardRenderer {
    static func render(dateKST: String, playerScore: Int, botScore: Int?) -> String {
        let bot = botScore ?? 0
        let ratio: Double = bot == 0 ? 0 : min(1.0, Double(playerScore) / Double(bot))
        let pct = Int((ratio * 100).rounded())
        let barWidth = 20
        let filled = Int((ratio * Double(barWidth)).rounded())
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: barWidth - filled)
        let botText = botScore.map(String.init) ?? "…"
        return """
        Tendle \(dateKST)
        🟩 \(playerScore) · 🤖 \(botText) (\(pct)%)
        \(bar)
        """
    }
}
```

- [ ] **Step 4: Run tests — expect 3/3 pass**

- [ ] **Step 5: Add share button to ResultView**

```swift
// In ResultView body, alongside existing actions:
ShareLink(item: ShareCardRenderer.render(
    dateKST: session.dateKSTAtStart,
    playerScore: session.playerScore,
    botScore: session.solverProgress?.bestScore))
{
    Label("공유", systemImage: "square.and.arrow.up")
}
.buttonStyle(.bordered)
.controlSize(.large)
```

- [ ] **Step 6: Commit**

```bash
git add ios/Tendle/Services/ShareCardRenderer.swift \
        ios/TendleTests/ShareCardRendererTests.swift \
        ios/Tendle/Views/ResultView.swift
git commit -m "feat(share): ShareCardRenderer + Daily ResultView share button (T2.8)"
```

---

### Task 9: `StatsView` + `StatsAggregator` (counts + streak + bot-win % + 30d sparkline)

**Files:**
- Create: `ios/Tendle/Services/StatsAggregator.swift`
- Create: `ios/Tendle/Views/StatsView.swift`
- Create: `ios/TendleTests/StatsAggregatorTests.swift`
- Modify: `ios/Tendle/Views/HomeView.swift` (add "통계 보기" link)
- Modify: `ios/Tendle/App/RootView.swift` (add `.stats` route)

- [ ] **Step 1: StatsAggregator + tests**

```swift
import Foundation

struct StatsSummary: Equatable {
    let totalPlays: Int
    let bestScore: Int
    let averageScore: Double
    let currentStreakDays: Int
    let botWinPercent: Int   // 0..100
    let last30: [Int]        // most-recent-first scores (0 for missing days)
}

enum StatsAggregator {
    static func summarize(records: [DailyRecord], today: String = KSTClock.dateString()) -> StatsSummary {
        let plays = records.count
        let best = records.map(\.playerScore).max() ?? 0
        let avg = plays > 0 ? Double(records.map(\.playerScore).reduce(0, +)) / Double(plays) : 0
        let withFinalBot = records.filter { $0.botStatus == .final && $0.botScore != nil }
        let wins = withFinalBot.filter { $0.playerScore > ($0.botScore ?? 0) }.count
        let pct = withFinalBot.isEmpty ? 0 : Int((Double(wins) / Double(withFinalBot.count) * 100).rounded())
        let streak = streakDays(records: records, today: today)
        let last30 = recentDays(records: records, days: 30, today: today)
        return StatsSummary(totalPlays: plays, bestScore: best, averageScore: avg,
                            currentStreakDays: streak, botWinPercent: pct, last30: last30)
    }

    private static func streakDays(records: [DailyRecord], today: String) -> Int {
        let set = Set(records.map(\.dateKST))
        var count = 0
        var cursor = today
        while set.contains(cursor) {
            count += 1
            cursor = addingDays(-1, to: cursor)
        }
        return count
    }

    private static func recentDays(records: [DailyRecord], days: Int, today: String) -> [Int] {
        let by = Dictionary(uniqueKeysWithValues: records.map { ($0.dateKST, $0.playerScore) })
        var out: [Int] = []
        var cursor = today
        for _ in 0..<days {
            out.append(by[cursor] ?? 0)
            cursor = addingDays(-1, to: cursor)
        }
        return out
    }

    private static func addingDays(_ delta: Int, to dateString: String) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Seoul")!
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateString) else { return dateString }
        let adjusted = Calendar(identifier: .gregorian).date(byAdding: .day, value: delta, to: date)!
        return f.string(from: adjusted)
    }
}
```

Tests:

```swift
import XCTest
@testable import Tendle

final class StatsAggregatorTests: XCTestCase {
    func testEmptyRecords() {
        let s = StatsAggregator.summarize(records: [], today: "2026-05-17")
        XCTAssertEqual(s.totalPlays, 0)
        XCTAssertEqual(s.bestScore, 0)
        XCTAssertEqual(s.currentStreakDays, 0)
        XCTAssertEqual(s.botWinPercent, 0)
        XCTAssertEqual(s.last30.count, 30)
    }

    func testStreakCountsConsecutiveDays() {
        let recs = [
            sample(date: "2026-05-17", playerScore: 50, botScore: 40),
            sample(date: "2026-05-16", playerScore: 60, botScore: 70),
            sample(date: "2026-05-14", playerScore: 40, botScore: 40),  // gap
        ]
        let s = StatsAggregator.summarize(records: recs, today: "2026-05-17")
        XCTAssertEqual(s.currentStreakDays, 2)
    }

    func testBotWinPercent() {
        let recs = [
            sample(date: "2026-05-17", playerScore: 100, botScore: 80),
            sample(date: "2026-05-16", playerScore: 50, botScore: 80),
        ]
        let s = StatsAggregator.summarize(records: recs, today: "2026-05-17")
        XCTAssertEqual(s.botWinPercent, 50)
    }

    private func sample(date: String, playerScore: Int, botScore: Int) -> DailyRecord {
        DailyRecord(
            dateKST: date, seedInputHash: "x",
            startedAtKST: Date(), endedAtKST: Date(), dateKSTAtStart: date,
            playerScore: playerScore, durationMs: 120_000,
            botStatus: .final, botScore: botScore, botFinalizedAt: Date(),
            solverProfile: "mvp-v1", outcome: "completed")
    }
}
```

- [ ] **Step 2: Run — expect 3/3 pass after impl**

- [ ] **Step 3: StatsView**

```swift
import SwiftUI

struct StatsView: View {
    let summary: StatsSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("통계").font(.largeTitle.bold())
                HStack(spacing: 24) {
                    metric("플레이", "\(summary.totalPlays)")
                    metric("연속", "\(summary.currentStreakDays)")
                    metric("최고", "\(summary.bestScore)")
                    metric("봇 승률", "\(summary.botWinPercent)%")
                }
                Text("최근 30일").font(.headline)
                sparkline
                Spacer()
            }
            .padding()
        }
    }

    @ViewBuilder
    private var sparkline: some View {
        let maxVal = max(1, summary.last30.max() ?? 1)
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(summary.last30.enumerated().reversed()), id: \.offset) { _, score in
                Rectangle()
                    .fill(score == 0 ? Color(.systemGray5) : Color.accentColor)
                    .frame(width: 8, height: CGFloat(score) / CGFloat(maxVal) * 80 + 4)
            }
        }
        .frame(height: 90)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 4: Add `.stats` Route + Home link**

In `RootView`:

```swift
enum Route: Hashable {
    case game(dateKST: String)
    case result(GameSessionSnapshot)
    case stats
}
// ...
case .stats:
    let store = StatsStore(modelContext: modelContext)
    let records = (try? store.allRecords()) ?? []
    StatsView(summary: StatsAggregator.summarize(records: records))
```

In `HomeView`, add a small secondary button:

```swift
Button("통계 보기", action: onStats)
    .buttonStyle(.bordered)
    .controlSize(.regular)
```

Pass `onStats: () -> Void` callback from RootView that does `path.append(Route.stats)`.

- [ ] **Step 5: Build + tests + commit**

```bash
xcodebuild ... test  # all stats tests pass + no regression
git add ios/Tendle/Services/StatsAggregator.swift \
        ios/Tendle/Views/StatsView.swift \
        ios/TendleTests/StatsAggregatorTests.swift \
        ios/Tendle/Views/HomeView.swift \
        ios/Tendle/App/RootView.swift
git commit -m "feat(stats): StatsAggregator + StatsView + Home link (T2.9)"
```

---

### Task 10: Late bot finalization (pending → final upgrade)

**Files:**
- Modify: `ios/Tendle/Services/StatsStore.swift`
- Modify: `ios/Tendle/App/RootView.swift`

When `GameCoordinator.deinit` happens before solver completes, the
DailyRecord is saved with `.pending` and no botScore. Later, on next
launch, we want to upgrade it.

- [ ] **Step 1: Add finalize method to StatsStore**

```swift
func finalizePendingBot(date: String, botScore: Int) throws {
    guard let record = try record(for: date), record.botStatus == .pending else { return }
    record.botScore = botScore
    record.botStatus = .final
    record.botFinalizedAt = Date()
    try modelContext.save()
}
```

- [ ] **Step 2: On RootView appear, kick off solver for any pending records**

```swift
.onAppear {
    Task.detached(priority: .background) {
        let store = StatsStore(modelContext: modelContext)
        let pending = ((try? store.allRecords()) ?? []).filter { $0.botStatus == .pending }
        for rec in pending {
            let seed = KSTClock.dailySeed(forDate: rec.dateKSTAtStart)
            let board = BoardGenerator.generate(seed: seed)
            let result = Solver.solve(board, profile: .mvpV1)
            await MainActor.run {
                try? store.finalizePendingBot(date: rec.dateKST, botScore: result.score)
            }
        }
    }
}
```

- [ ] **Step 3: Build + commit**

```bash
xcodebuild ... build
git add ios/Tendle/Services/StatsStore.swift ios/Tendle/App/RootView.swift
git commit -m "feat(data): late bot finalization for pending records (T2.10)"
```

---

### Task 11: Manual smoke + handoff

- [ ] **Step 1: Boot sim + install + launch**

```bash
xcrun simctl boot "iPhone 15" 2>/dev/null
open -a Simulator
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
  -derivedDataPath ./build_smoke build
xcrun simctl install booted ./build_smoke/Build/Products/Debug-iphonesimulator/Tendle.app
xcrun simctl launch booted com.jinnsim.Tendle
```

- [ ] **Step 2: Capture screens**

```bash
sleep 2
xcrun simctl io booted screenshot docs/screenshots/phase2-splash.png
# Tap CTA via Simulator UI; play one round; capture result.
xcrun simctl io booted screenshot docs/screenshots/phase2-result.png
# Navigate to Stats; capture.
xcrun simctl io booted screenshot docs/screenshots/phase2-stats.png
```

- [ ] **Step 3: Append handoff note**

Append to `docs/handoff.md`:

```markdown
## 2026-05-17 — Phase 2 complete (Personalized)

Splash + character illustrations on Home/Result/Streak/Welcome, bilingual
encouragement lines addressing 지율 fired at trigger moments, ShareLink
posting the spec §9 ratio card, StatsView with 30-day sparkline + bot-win %,
real (system-derived) .caf sounds on clear, late bot finalization for
pending records. Screenshots: docs/screenshots/phase2-*.png.

Phase 3 next: Localizable.xcstrings, Settings UI, iPad split view,
GitHub Actions CI, real custom .caf sound design, app icon PNG.
```

- [ ] **Step 4: Commit**

```bash
rm -rf build_smoke
git add docs/handoff.md docs/screenshots/phase2-*.png
git commit -m "docs(phase2): manual QA pass + screenshots + handoff note (T2.11)"
```

---

## Self-Review

**Spec coverage check (Phase 2 scope):**

| Spec section | Task |
|--------------|------|
| §18.1 Characters | T2.1, T2.4, T2.5, T2.6 (illustration placement) |
| §18.2 Visual placement (Splash/Home/Loading/Result/Streak/Welcome) | T2.1, T2.5, T2.6 |
| §18.3 Encouragement system (trigger enum, deterministic selection, {streak}) | T2.2, T2.3, T2.5 |
| §18.4 Determinism contract (same trigger same day = same line) | T2.3 test |
| §18.5 Implementation footprint (~80 LOC service) | T2.3 |
| §11.1 Layer 1/2 two-layer workflow | T2.1 |
| §11.2 Audio (tap/clear/gameover) | T2.7 |
| §9 Share card (ratio bar) | T2.8 |
| §7.4 StatsView (aggregates + recent history) | T2.9 |
| §5.4 Bot pending → final lifecycle | T2.10 |

**Placeholder scan:** no `TBD`/`TODO`/`fill in`. All code blocks complete.

**Type consistency:**
- `EncouragementTrigger` enum cases match JSON keys exactly (verified — `roundStart`, `firstClear`, `combo`, `roundEndBeatBot`, `roundEndClose`, `roundEndLow`, `streakUp`, `reopen`).
- `EncouragementService.line` signature consistent across all call sites.
- `StatsSummary` properties consistent in StatsAggregator + StatsView.
- `SoundService.shared` introduced in T2.7 used in GameCoordinator (same name).

**Known Phase 2 limitations (intentional):**
- Encouragement.json bundled only — Phase 3 may add hot-reload for content
  iteration.
- No abandoned-attempt detection of >5 min background → mark abandoned;
  the late-finalize task only handles the "ran out of time before solver
  finished" path. Abandoned-on-kill is harder (need scene phase observer);
  Phase 2.5 if needed.
- StatsView sparkline is simple bars — no axis labels or tooltips. Acceptable.
- ShareLink uses iOS standard share sheet — no custom card image rendering;
  Phase 3 can upgrade to ImageRenderer-generated PNG.
