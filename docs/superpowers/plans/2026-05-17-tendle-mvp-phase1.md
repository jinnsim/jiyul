# Tendle MVP Phase 1 — Playable Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a playable Tendle daily round — open the app, see today's
17×10 board, drag-select rectangles that sum to 10 to clear them, finish the
2-minute timer, see the player score side-by-side with a deterministic bot
score, and persist the first-of-day record. iPhone simulator only; iPad sizing
acceptable but not specifically tuned.

**Architecture:** SwiftUI + SwiftData, iOS 17+, single-window NavigationStack.
Game core (Board / BoardEngine / BoardGenerator / Solver) ports from the
already-built `ios/SolverSpike/` package into a `TendleCore` SwiftPM target
inside the app workspace so the app and tests both depend on the same
deterministic library. `GameCoordinator` (not `@MainActor`) owns the round
clock and drives a `Solver` `Task.detached` whose `SolverProgress` stream
hydrates `ResultView`.

**Tech Stack:**
- SwiftUI, iOS 17.0+, xcodegen, Xcode 15.2+
- SwiftData (DailyRecord, SolverCache, Settings @Models)
- Swift Testing for new tests; XCTest for ported tests
- Foundation only — no third-party dependencies

**Spec reference:** [`docs/superpowers/specs/2026-05-17-tendle-design.md`](../specs/2026-05-17-tendle-design.md) (v4)

**Out of Phase 1 scope** (deferred to Phase 2/3):
- EncouragementService + Encouragement.json wiring
- Layer-2 character illustrations into screens
- Layer-1 app icon (placeholder used)
- Share card / ShareCardRenderer
- StatsView sparkline (Phase 1 shows raw counts on Home)
- Localizable.xcstrings (Phase 1 uses Korean literals; ko/en catalog comes in Phase 3)
- Settings UI (Phase 1 only seeds default Settings; no UI to mutate)
- iPad split view / side panel (Phase 1 universal but uses the iPhone layout scaled)
- Sound assets (Phase 1 wires SoundService but ships silent placeholder clips)
- CI workflow (Phase 3)

**Phase 1 success criterion:** on the iPhone 15 simulator, an engineer can
launch the app, complete one full daily round, see `playerScore` and `botScore`
on `ResultView` (bot reaches `.final` within ~3 s on Apple Silicon Mac), kill
the app, relaunch, and see the day's record reflected on `HomeView` with the
"이미 기록됨" badge.

---

## File Structure

```
ios/
  project.yml                          # xcodegen workspace
  Tendle/
    App/
      TendleApp.swift                  # @main entry
      RootView.swift                   # NavigationStack root
    Models/
      Cell.swift                       # (just an alias / placeholder)
      Selection.swift                  # mirror of SolverSpike Selection
      Board.swift                      # mirror of SolverSpike Board
      GameSession.swift                # round state owned by Coordinator
      SolverProgress.swift             # AsyncStream payload
      DailyRecord.swift                # @Model
      SolverCache.swift                # @Model
      Settings.swift                   # @Model
      BotStatus.swift                  # enum
    Services/
      SeededRNG.swift                  # port (SplitMix64)
      BoardGenerator.swift             # port (rejection sampling)
      BoardEngine.swift                # port (pure functions)
      SolverProfile.swift              # port + scoringHash
      Solver.swift                     # port + AsyncStream publisher
      KSTClock.swift                   # KST date / "today" string helper
      GameCoordinator.swift            # round lifecycle (NOT @MainActor)
      StatsStore.swift                 # SwiftData wrapper + first-record rule
      SoundService.swift               # silent stub for Phase 1
    Views/
      HomeView.swift                   # idle / played states + CTA
      GameView.swift                   # BoardView + HUD + drag gesture
      BoardView.swift                  # 17×10 grid render
      SelectionOverlay.swift           # live drag rectangle + sum
      ResultView.swift                 # player + bot
    Resources/
      Assets.xcassets/                 # AppIcon placeholder
      Sounds/                          # tap.caf, clear.caf, gameover.caf (silent)
  TendleTests/
    BoardEngineTests.swift             # ported + expanded
    BoardGeneratorTests.swift          # ported + expanded
    SolverTests.swift                  # ported + dense-board case
    GameCoordinatorTests.swift         # fake clock, lifecycle
    StatsStoreTests.swift              # in-memory ModelContainer
    KSTClockTests.swift                # midnight rollover
```

---

## Phase 1 Plan

### Task 1: xcodegen project scaffold

**Files:**
- Create: `ios/project.yml`
- Create: `ios/Tendle/App/TendleApp.swift`
- Create: `ios/Tendle/App/RootView.swift`
- Create: `ios/Tendle/Resources/Assets.xcassets/Contents.json`
- Create: `ios/Tendle/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `ios/Tendle/Resources/Sounds/.gitkeep`
- Create: `ios/TendleTests/Smoke.swift`

- [ ] **Step 1: Write `ios/project.yml`**

```yaml
name: Tendle
options:
  bundleIdPrefix: com.jinnsim
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "15.2"
configs:
  Debug: debug
  Release: release
settings:
  base:
    SWIFT_VERSION: "5.9"
    DEVELOPMENT_TEAM: ""
    CODE_SIGNING_ALLOWED: NO
targets:
  Tendle:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Tendle
    info:
      path: Tendle/Info.plist
      properties:
        CFBundleDisplayName: Tendle
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
        UILaunchScreen:
          UIColorName: ""
        UIRequiredDeviceCapabilities:
          - armv7
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        UISupportedInterfaceOrientations~ipad:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
    settings:
      base:
        TARGETED_DEVICE_FAMILY: "1,2"   # iPhone + iPad universal
        ENABLE_PREVIEWS: YES
  TendleTests:
    type: bundle.unit-test
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: TendleTests
    dependencies:
      - target: Tendle
```

- [ ] **Step 2: Write `ios/Tendle/App/TendleApp.swift`**

```swift
import SwiftUI

@main
struct TendleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

- [ ] **Step 3: Write `ios/Tendle/App/RootView.swift`**

```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            Text("Tendle")
                .font(.largeTitle)
                .navigationTitle("Tendle")
        }
    }
}
```

- [ ] **Step 4: Write minimal `Assets.xcassets/Contents.json`**

```json
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

- [ ] **Step 5: Write minimal `AppIcon.appiconset/Contents.json` (placeholder, no PNG required)**

```json
{
  "images": [
    {
      "filename": "",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

- [ ] **Step 6: Write `ios/TendleTests/Smoke.swift`**

```swift
import XCTest

final class SmokeTests: XCTestCase {
    func testAlwaysPasses() {
        XCTAssertEqual(1 + 1, 2)
    }
}
```

- [ ] **Step 7: Generate and build**

Run:
```bash
brew list xcodegen >/dev/null 2>&1 || brew install xcodegen
cd ios && xcodegen generate
xcodebuild -project Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 8: Run smoke test**

Run:
```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

Expected: `Test Suite 'SmokeTests' passed`.

- [ ] **Step 9: Commit**

```bash
git add ios/project.yml ios/Tendle ios/TendleTests
echo "ios/Tendle.xcodeproj/" >> .gitignore
echo "ios/build/" >> .gitignore
git add .gitignore
git commit -m "feat(scaffold): bootstrap Tendle iOS app via xcodegen"
```

---

### Task 2: Port `SeededRNG` + `Selection` + `Board` into the app target

**Files:**
- Create: `ios/Tendle/Services/SeededRNG.swift`
- Create: `ios/Tendle/Models/Selection.swift`
- Create: `ios/Tendle/Models/Board.swift`

We **copy** (not depend on) the SolverSpike Swift Package code into the app
target. SolverSpike stays as a standalone validation harness; the app gets its
own canonical copies under `ios/Tendle/`. This is intentional: the spike's
visibility is `public` for tooling; the app uses `internal` and may evolve.

- [ ] **Step 1: Copy `SeededRNG.swift` from spike**

Source: `ios/SolverSpike/Sources/SolverSpikeCore/SeededRNG.swift`.

Write `ios/Tendle/Services/SeededRNG.swift`:

```swift
import Foundation

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
```

- [ ] **Step 2: Copy `Selection` and `Board` from spike**

Write `ios/Tendle/Models/Selection.swift`:

```swift
import Foundation

struct Selection: Hashable, Comparable {
    let minColumn: Int
    let minRow: Int
    let maxColumn: Int
    let maxRow: Int

    init(minColumn: Int, minRow: Int, maxColumn: Int, maxRow: Int) {
        self.minColumn = min(minColumn, maxColumn)
        self.minRow = min(minRow, maxRow)
        self.maxColumn = max(minColumn, maxColumn)
        self.maxRow = max(minRow, maxRow)
    }

    static func < (lhs: Selection, rhs: Selection) -> Bool {
        if lhs.minRow != rhs.minRow { return lhs.minRow < rhs.minRow }
        if lhs.minColumn != rhs.minColumn { return lhs.minColumn < rhs.minColumn }
        if lhs.maxRow != rhs.maxRow { return lhs.maxRow < rhs.maxRow }
        return lhs.maxColumn < rhs.maxColumn
    }
}
```

Write `ios/Tendle/Models/Board.swift` — copy the body of
`ios/SolverSpike/Sources/SolverSpikeCore/Board.swift` verbatim, but change all
`public` modifiers to `internal` (i.e. remove `public`). Keep
`static let columns = 17`, `rows = 10`, `cellCount`, `maskWordCount`, the
bitmask `clearedWords`, the `init(rows:)` fixture helper, `digit/value/
isCleared/clearing` methods.

- [ ] **Step 3: Build to ensure nothing breaks**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add ios/Tendle/Services/SeededRNG.swift ios/Tendle/Models/Selection.swift ios/Tendle/Models/Board.swift
git commit -m "feat(core): port SplitMix64, Selection, Board from SolverSpike"
```

---

### Task 3: Port `BoardGenerator` + write determinism test

**Files:**
- Create: `ios/Tendle/Services/BoardGenerator.swift`
- Create: `ios/TendleTests/BoardGeneratorTests.swift`

- [ ] **Step 1: Write failing test**

`ios/TendleTests/BoardGeneratorTests.swift`:

```swift
import XCTest
@testable import Tendle

final class BoardGeneratorTests: XCTestCase {
    func testSameSeedProducesSameBoard() {
        let a = BoardGenerator.generate(seed: 0xDEADBEEFCAFEBABE)
        let b = BoardGenerator.generate(seed: 0xDEADBEEFCAFEBABE)
        XCTAssertEqual(a.digits, b.digits)
    }

    func testAllDigitsInOneToNine() {
        let board = BoardGenerator.generate(seed: 42)
        XCTAssertTrue(board.digits.allSatisfy { (1...9).contains($0) })
        XCTAssertEqual(board.digits.count, Board.cellCount)
    }
}
```

- [ ] **Step 2: Run test (expect compile error — BoardGenerator missing)**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

Expected: compile error referencing `BoardGenerator`.

- [ ] **Step 3: Port BoardGenerator from spike**

`ios/Tendle/Services/BoardGenerator.swift`:

```swift
import Foundation

enum BoardGenerator {
    static func generate(seed: UInt64) -> Board {
        var rng = SplitMix64(seed: seed)
        return Board(digits: (0..<Board.cellCount).map { _ in UInt8(nextDigit(&rng)) })
    }

    static func nextDigit(_ rng: inout SplitMix64) -> Int {
        let bound = (UInt64.max / 9) * 9
        var value: UInt64
        repeat {
            value = rng.next()
        } while value >= bound
        return Int(value % 9) + 1
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

Expected: 2 BoardGeneratorTests pass.

- [ ] **Step 5: Commit**

```bash
git add ios/Tendle/Services/BoardGenerator.swift ios/TendleTests/BoardGeneratorTests.swift
git commit -m "feat(core): port BoardGenerator with determinism + range tests"
```

---

### Task 4: Port `BoardEngine` + tests

**Files:**
- Create: `ios/Tendle/Services/BoardEngine.swift`
- Create: `ios/TendleTests/BoardEngineTests.swift`

- [ ] **Step 1: Write failing tests**

`ios/TendleTests/BoardEngineTests.swift`:

```swift
import XCTest
@testable import Tendle

final class BoardEngineTests: XCTestCase {
    func testRectangleSumOnPristineBoard() {
        let b = Board(rows: ["19"])
        let s = Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0)
        XCTAssertEqual(BoardEngine.rectangleSum(s, on: b), 10)
    }

    func testClearSucceedsWhenSumIsTen() {
        let b = Board(rows: ["19"])
        let s = Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0)
        let r = BoardEngine.clear(s, on: b)
        XCTAssertEqual(r?.clearedCells, 2)
        XCTAssertEqual(r?.board.isCleared(column: 0, row: 0), true)
    }

    func testClearFailsWhenSumIsNotTen() {
        let b = Board(rows: ["18"])
        let s = Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0)
        XCTAssertNil(BoardEngine.clear(s, on: b))
    }

    func testClearedCellsContributeZero() {
        let b = Board(rows: ["191"])
        let first = BoardEngine.clear(
            Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0), on: b)!.board
        XCTAssertEqual(
            BoardEngine.rectangleSum(
                Selection(minColumn: 0, minRow: 0, maxColumn: 2, maxRow: 0), on: first),
            1)
    }
}
```

- [ ] **Step 2: Run tests — expect compile error**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

Expected: compile error on `BoardEngine`.

- [ ] **Step 3: Port BoardEngine from spike**

Copy `ios/SolverSpike/Sources/SolverSpikeCore/BoardEngine.swift` to
`ios/Tendle/Services/BoardEngine.swift`, removing all `public` modifiers.

Defines `ClearResult`, `ClearAction`, and `enum BoardEngine` with `isValid`,
`rectangleSum`, `clear`, `validClears`, `validClearActions`.

- [ ] **Step 4: Run tests**

Expected: 4 BoardEngineTests pass.

- [ ] **Step 5: Commit**

```bash
git add ios/Tendle/Services/BoardEngine.swift ios/TendleTests/BoardEngineTests.swift
git commit -m "feat(core): port BoardEngine with selection / sum / clear tests"
```

---

### Task 5: Port `SolverProfile` (with `scoringHash`) and `Solver`

**Files:**
- Create: `ios/Tendle/Services/SolverProfile.swift`
- Create: `ios/Tendle/Models/SolverProgress.swift`
- Create: `ios/Tendle/Services/Solver.swift`
- Create: `ios/TendleTests/SolverTests.swift`

- [ ] **Step 1: Write `SolverProfile.swift` (already includes scoringHash, per spec §5.2)**

```swift
import Foundation

struct SolverProfile: Equatable {
    let solverProfile: String
    let beamWidth: Int
    let maxExpandedStates: Int
    let maxVisitedStates: Int
    let alpha: Double
    let rngSeedForTies: UInt64
    let solverVersion: Int
    let scoringHash: String

    static let mvpV1 = SolverProfile(
        solverProfile: "mvp-v1",
        beamWidth: 64,
        maxExpandedStates: 200_000,
        maxVisitedStates: 800_000,
        alpha: 0.10,
        rngSeedForTies: 0,
        solverVersion: 1,
        scoringHash: "score+0.10*potential(pair+triple+quad,line-only,len<=4)"
    )

    var cacheKey: String {
        "\(solverProfile)|v\(solverVersion)|w\(beamWidth)|n\(maxExpandedStates)|h\(scoringHash)"
    }
}
```

- [ ] **Step 2: Write `SolverProgress.swift`**

```swift
import Foundation

struct SolverProgress: Equatable {
    let bestScore: Int
    let expandedStates: Int
    let isFinal: Bool
}
```

- [ ] **Step 3: Write failing solver tests**

`ios/TendleTests/SolverTests.swift`:

```swift
import XCTest
@testable import Tendle

final class SolverTests: XCTestCase {
    func testSolvesTrivialSingleRowBoard() {
        let board = Board(rows: ["1234"])  // 1+2+3+4 = 10
        let r = Solver.solve(board, profile: .mvpV1)
        XCTAssertEqual(r.score, 4)
        XCTAssertTrue(r.isFinal)
    }

    func testIsDeterministicAcrossReruns() {
        let board = BoardGenerator.generate(seed: 12345)
        let a = Solver.solve(board, profile: .mvpV1).score
        let b = Solver.solve(board, profile: .mvpV1).score
        XCTAssertEqual(a, b)
    }
}
```

- [ ] **Step 4: Run — expect compile error**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

Expected: compile error referencing `Solver`.

- [ ] **Step 5: Port Solver from spike with extended `SolverResult`**

Copy `ios/SolverSpike/Sources/SolverSpikeCore/Solver.swift` to
`ios/Tendle/Services/Solver.swift`, removing `public`. Extend `SolverResult`
with `isFinal: Bool` (set to `true` on natural termination, `false` if
externally cancelled — but for synchronous `solve` it is always `true`).
Wrap the existing return statement:

```swift
return SolverResult(
    score: best.score,
    moves: best.moves,
    expandedStates: expandedStates,
    isFinal: true
)
```

Update `SolverResult` definition at top of file:

```swift
struct SolverResult: Equatable {
    let score: Int
    let moves: [Selection]
    let expandedStates: Int
    let isFinal: Bool
}
```

- [ ] **Step 6: Run tests**

Expected: both SolverTests pass (testSolvesTrivialSingleRowBoard < 1 s,
testIsDeterministicAcrossReruns < 10 s on Apple Silicon Mac sim).

- [ ] **Step 7: Commit**

```bash
git add ios/Tendle/Services/SolverProfile.swift \
        ios/Tendle/Models/SolverProgress.swift \
        ios/Tendle/Services/Solver.swift \
        ios/TendleTests/SolverTests.swift
git commit -m "feat(core): port Solver + SolverProfile (scoringHash) + SolverProgress"
```

---

### Task 6: KST clock helper + test

**Files:**
- Create: `ios/Tendle/Services/KSTClock.swift`
- Create: `ios/TendleTests/KSTClockTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
@testable import Tendle

final class KSTClockTests: XCTestCase {
    func testTodayStringRendersKSTDate() {
        // 2026-05-17 14:00 UTC == 2026-05-17 23:00 KST → "2026-05-17"
        let d = Date(timeIntervalSince1970: 1779__022400)
        XCTAssertEqual(KSTClock.dateString(for: d), "2026-05-17")
    }

    func testJustAfterUTCMidnightStillSameKSTDay() {
        // 2026-05-17 00:30 UTC == 2026-05-17 09:30 KST → "2026-05-17"
        let d = Date(timeIntervalSince1970: 1778__972200)
        XCTAssertEqual(KSTClock.dateString(for: d), "2026-05-17")
    }

    func testSeedHashForDailyIsStable() {
        XCTAssertEqual(KSTClock.dailySeed(forDate: "2026-05-17"),
                       KSTClock.dailySeed(forDate: "2026-05-17"))
        XCTAssertNotEqual(KSTClock.dailySeed(forDate: "2026-05-17"),
                          KSTClock.dailySeed(forDate: "2026-05-18"))
    }
}
```

- [ ] **Step 2: Run — expect compile errors**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

- [ ] **Step 3: Implement KSTClock**

`ios/Tendle/Services/KSTClock.swift`:

```swift
import Foundation
import CryptoKit

enum KSTClock {
    private static let kst = TimeZone(identifier: "Asia/Seoul")!
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = kst
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dateString(for date: Date = Date()) -> String {
        formatter.string(from: date)
    }

    static func dailySeed(forDate kstDateString: String) -> UInt64 {
        let input = "\(kstDateString)|daily"
        let digest = SHA256.hash(data: Data(input.utf8))
        var seed: UInt64 = 0
        for (i, byte) in digest.prefix(8).enumerated() {
            seed |= UInt64(byte) << (UInt64(i) * 8)
        }
        return seed
    }
}
```

- [ ] **Step 4: Run tests — expect pass**

Expected: 3 KSTClockTests pass.

- [ ] **Step 5: Commit**

```bash
git add ios/Tendle/Services/KSTClock.swift ios/TendleTests/KSTClockTests.swift
git commit -m "feat(core): KSTClock — daily date string + deterministic seed"
```

---

### Task 7: SwiftData models (`BotStatus`, `DailyRecord`, `SolverCache`, `Settings`)

**Files:**
- Create: `ios/Tendle/Models/BotStatus.swift`
- Create: `ios/Tendle/Models/DailyRecord.swift`
- Create: `ios/Tendle/Models/SolverCache.swift`
- Create: `ios/Tendle/Models/Settings.swift`

- [ ] **Step 1: BotStatus enum**

```swift
import Foundation

enum BotStatus: String, Codable {
    case pending
    case final
    case failed
}
```

- [ ] **Step 2: DailyRecord @Model**

```swift
import Foundation
import SwiftData

@Model
final class DailyRecord {
    @Attribute(.unique) var dateKST: String
    var seedInputHash: String
    var startedAtKST: Date
    var endedAtKST: Date
    var dateKSTAtStart: String
    var playerScore: Int
    var durationMs: Int
    var botStatusRaw: String
    var botScore: Int?
    var botFinalizedAt: Date?
    var solverProfile: String
    var outcome: String   // "completed" | "abandoned"

    init(dateKST: String,
         seedInputHash: String,
         startedAtKST: Date,
         endedAtKST: Date,
         dateKSTAtStart: String,
         playerScore: Int,
         durationMs: Int,
         botStatus: BotStatus,
         botScore: Int?,
         botFinalizedAt: Date?,
         solverProfile: String,
         outcome: String) {
        self.dateKST = dateKST
        self.seedInputHash = seedInputHash
        self.startedAtKST = startedAtKST
        self.endedAtKST = endedAtKST
        self.dateKSTAtStart = dateKSTAtStart
        self.playerScore = playerScore
        self.durationMs = durationMs
        self.botStatusRaw = botStatus.rawValue
        self.botScore = botScore
        self.botFinalizedAt = botFinalizedAt
        self.solverProfile = solverProfile
        self.outcome = outcome
    }

    var botStatus: BotStatus {
        get { BotStatus(rawValue: botStatusRaw) ?? .failed }
        set { botStatusRaw = newValue.rawValue }
    }
}
```

- [ ] **Step 3: SolverCache @Model**

```swift
import Foundation
import SwiftData

@Model
final class SolverCache {
    @Attribute(.unique) var cacheKey: String
    var botScore: Int
    var solverProfile: String
    var solverVersion: Int
    var computedAt: Date

    init(cacheKey: String, botScore: Int, solverProfile: String,
         solverVersion: Int, computedAt: Date) {
        self.cacheKey = cacheKey
        self.botScore = botScore
        self.solverProfile = solverProfile
        self.solverVersion = solverVersion
        self.computedAt = computedAt
    }
}
```

- [ ] **Step 4: Settings @Model**

```swift
import Foundation
import SwiftData

@Model
final class Settings {
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var languageOverride: String?
    var playerName: String

    init(soundEnabled: Bool = true,
         hapticsEnabled: Bool = true,
         languageOverride: String? = nil,
         playerName: String = "지율") {
        self.soundEnabled = soundEnabled
        self.hapticsEnabled = hapticsEnabled
        self.languageOverride = languageOverride
        self.playerName = playerName
    }
}
```

- [ ] **Step 5: Build (no test yet — pure model declarations)**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add ios/Tendle/Models/BotStatus.swift \
        ios/Tendle/Models/DailyRecord.swift \
        ios/Tendle/Models/SolverCache.swift \
        ios/Tendle/Models/Settings.swift
git commit -m "feat(data): SwiftData models — DailyRecord, SolverCache, Settings, BotStatus"
```

---

### Task 8: StatsStore — first-record rule + in-memory tests

**Files:**
- Create: `ios/Tendle/Services/StatsStore.swift`
- Create: `ios/TendleTests/StatsStoreTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
import SwiftData
@testable import Tendle

final class StatsStoreTests: XCTestCase {
    func makeStore() throws -> StatsStore {
        let schema = Schema([DailyRecord.self, SolverCache.self, Settings.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [cfg])
        return StatsStore(modelContext: ModelContext(container))
    }

    func testFirstSaveCreatesRecord() throws {
        let s = try makeStore()
        let r = makeSampleRecord(date: "2026-05-17")
        let stored = try s.saveFirstAttempt(r)
        XCTAssertNotNil(stored)
        XCTAssertEqual(try s.record(for: "2026-05-17")?.playerScore, 87)
    }

    func testSecondSaveOnSameDateIsRejected() throws {
        let s = try makeStore()
        _ = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-17", score: 87))
        let again = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-17", score: 99))
        XCTAssertNil(again)  // already recorded
        XCTAssertEqual(try s.record(for: "2026-05-17")?.playerScore, 87)
    }

    func testDifferentDatesCoexist() throws {
        let s = try makeStore()
        _ = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-17", score: 87))
        _ = try s.saveFirstAttempt(makeSampleRecord(date: "2026-05-18", score: 99))
        XCTAssertEqual(try s.allRecords().count, 2)
    }

    private func makeSampleRecord(date: String, score: Int = 87) -> DailyRecord {
        DailyRecord(
            dateKST: date,
            seedInputHash: "abc",
            startedAtKST: Date(),
            endedAtKST: Date(),
            dateKSTAtStart: date,
            playerScore: score,
            durationMs: 120_000,
            botStatus: .final,
            botScore: 121,
            botFinalizedAt: Date(),
            solverProfile: "mvp-v1",
            outcome: "completed"
        )
    }
}
```

- [ ] **Step 2: Run — expect compile error**

- [ ] **Step 3: Implement StatsStore**

`ios/Tendle/Services/StatsStore.swift`:

```swift
import Foundation
import SwiftData

final class StatsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Returns the saved record on success, or nil if a record already
    /// exists for the same dateKST (first-record-wins per spec §3.3).
    @discardableResult
    func saveFirstAttempt(_ record: DailyRecord) throws -> DailyRecord? {
        if try recordExists(for: record.dateKST) { return nil }
        modelContext.insert(record)
        try modelContext.save()
        return record
    }

    func record(for dateKST: String) throws -> DailyRecord? {
        var descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate { $0.dateKST == dateKST })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func allRecords() throws -> [DailyRecord] {
        try modelContext.fetch(FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.dateKST, order: .reverse)]))
    }

    private func recordExists(for dateKST: String) throws -> Bool {
        try record(for: dateKST) != nil
    }
}
```

- [ ] **Step 4: Run tests**

Expected: 3 StatsStoreTests pass.

- [ ] **Step 5: Commit**

```bash
git add ios/Tendle/Services/StatsStore.swift ios/TendleTests/StatsStoreTests.swift
git commit -m "feat(data): StatsStore with first-record-wins rule + in-memory tests"
```

---

### Task 9: GameSession value type + GameCoordinator skeleton

**Files:**
- Create: `ios/Tendle/Models/GameSession.swift`
- Create: `ios/Tendle/Services/GameCoordinator.swift`

- [ ] **Step 1: GameSession value type**

```swift
import Foundation

enum GamePhase: Equatable {
    case idle
    case playing
    case ended
}

struct GameSession: Equatable {
    var board: Board
    var phase: GamePhase
    var playerScore: Int
    var remainingMs: Int
    var startedAt: Date
    var dateKSTAtStart: String
    var solverProgress: SolverProgress?

    static let totalDurationMs = 120_000

    static func newDaily(dateKST: String, now: Date) -> GameSession {
        let seed = KSTClock.dailySeed(forDate: dateKST)
        let board = BoardGenerator.generate(seed: seed)
        return GameSession(
            board: board,
            phase: .idle,
            playerScore: 0,
            remainingMs: Self.totalDurationMs,
            startedAt: now,
            dateKSTAtStart: dateKST,
            solverProgress: nil
        )
    }
}
```

- [ ] **Step 2: GameCoordinator skeleton (no timer/solver yet)**

```swift
import Foundation
import Observation

@Observable
final class GameCoordinator {
    var session: GameSession

    init(session: GameSession) {
        self.session = session
    }

    func start() {
        guard session.phase == .idle else { return }
        session.phase = .playing
    }

    /// Attempts to commit a selection. Returns the number of cells cleared.
    @discardableResult
    func commit(_ selection: Selection) -> Int {
        guard session.phase == .playing else { return 0 }
        guard let result = BoardEngine.clear(selection, on: session.board) else { return 0 }
        session.board = result.board
        session.playerScore += result.clearedCells
        return result.clearedCells
    }

    func end() {
        session.phase = .ended
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add ios/Tendle/Models/GameSession.swift ios/Tendle/Services/GameCoordinator.swift
git commit -m "feat(core): GameSession + GameCoordinator skeleton (no timer/solver yet)"
```

---

### Task 10: GameCoordinator timer + tests

**Files:**
- Modify: `ios/Tendle/Services/GameCoordinator.swift`
- Create: `ios/TendleTests/GameCoordinatorTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import XCTest
@testable import Tendle

final class GameCoordinatorTests: XCTestCase {
    func testStartTransitionsToPlaying() {
        let g = makeCoordinator()
        g.start()
        XCTAssertEqual(g.session.phase, .playing)
    }

    func testTickReducesRemainingTime() {
        let g = makeCoordinator()
        g.start()
        g.tick(deltaMs: 1000)
        XCTAssertEqual(g.session.remainingMs, 119_000)
    }

    func testTimerReachingZeroEndsSession() {
        let g = makeCoordinator()
        g.start()
        g.tick(deltaMs: GameSession.totalDurationMs)
        XCTAssertEqual(g.session.phase, .ended)
        XCTAssertEqual(g.session.remainingMs, 0)
    }

    func testCommitOnValidRectangleScores() {
        let g = makeCoordinator(rows: ["19"])
        g.start()
        let cleared = g.commit(Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0))
        XCTAssertEqual(cleared, 2)
        XCTAssertEqual(g.session.playerScore, 2)
    }

    func testCommitWhenIdleDoesNothing() {
        let g = makeCoordinator(rows: ["19"])
        let cleared = g.commit(Selection(minColumn: 0, minRow: 0, maxColumn: 1, maxRow: 0))
        XCTAssertEqual(cleared, 0)
    }

    private func makeCoordinator(rows: [String] = ["19"]) -> GameCoordinator {
        let session = GameSession(
            board: Board(rows: rows),
            phase: .idle,
            playerScore: 0,
            remainingMs: GameSession.totalDurationMs,
            startedAt: Date(),
            dateKSTAtStart: "2026-05-17",
            solverProgress: nil
        )
        return GameCoordinator(session: session)
    }
}
```

- [ ] **Step 2: Run — expect failures (no `tick` method)**

- [ ] **Step 3: Add `tick(deltaMs:)` to GameCoordinator**

Append inside the class:

```swift
func tick(deltaMs: Int) {
    guard session.phase == .playing else { return }
    let next = max(0, session.remainingMs - deltaMs)
    session.remainingMs = next
    if next == 0 {
        end()
    }
}
```

- [ ] **Step 4: Run tests**

Expected: all 5 GameCoordinatorTests pass.

- [ ] **Step 5: Commit**

```bash
git add ios/Tendle/Services/GameCoordinator.swift ios/TendleTests/GameCoordinatorTests.swift
git commit -m "feat(core): GameCoordinator.tick + lifecycle tests"
```

---

### Task 11: Wire Solver into GameCoordinator via AsyncStream

**Files:**
- Modify: `ios/Tendle/Services/Solver.swift`
- Modify: `ios/Tendle/Services/GameCoordinator.swift`

The synchronous `Solver.solve` is fine for tests, but the live game must run
it on `Task.detached(priority: .background)` and emit progress.

- [ ] **Step 1: Add `Solver.solveAsync` returning `(AsyncStream<SolverProgress>, Task<Void, Never>)`**

Append to `ios/Tendle/Services/Solver.swift`:

```swift
extension Solver {
    /// Background-priority detached task that emits progress updates and
    /// finalises with isFinal=true. Cancellation drops further emissions.
    static func solveAsync(
        _ board: Board,
        profile: SolverProfile = .mvpV1
    ) -> (AsyncStream<SolverProgress>, Task<Void, Never>) {
        let (stream, continuation) = AsyncStream.makeStream(of: SolverProgress.self)
        let task = Task.detached(priority: .background) {
            // For Phase 1 we run the synchronous solver in one shot and
            // emit a single final progress. Incremental "anytime" updates
            // are added in Phase 2 (see spec §5.1).
            let result = Solver.solve(board, profile: profile)
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
}
```

- [ ] **Step 2: Add solver lifecycle to GameCoordinator**

Modify `ios/Tendle/Services/GameCoordinator.swift`:

```swift
import Foundation
import Observation

@Observable
final class GameCoordinator {
    var session: GameSession
    private var solverTask: Task<Void, Never>?

    init(session: GameSession) {
        self.session = session
    }

    func start() {
        guard session.phase == .idle else { return }
        session.phase = .playing
        let board = session.board
        let (stream, task) = Solver.solveAsync(board)
        solverTask = task
        Task { [weak self] in
            for await progress in stream {
                await MainActor.run { self?.session.solverProgress = progress }
            }
        }
    }

    @discardableResult
    func commit(_ selection: Selection) -> Int {
        guard session.phase == .playing else { return 0 }
        guard let result = BoardEngine.clear(selection, on: session.board) else { return 0 }
        session.board = result.board
        session.playerScore += result.clearedCells
        return result.clearedCells
    }

    func tick(deltaMs: Int) {
        guard session.phase == .playing else { return }
        session.remainingMs = max(0, session.remainingMs - deltaMs)
        if session.remainingMs == 0 { end() }
    }

    func end() {
        session.phase = .ended
        // Let solver finish on its own — its result may not be ready yet;
        // ResultView shows `.pending` until the AsyncStream completes.
    }

    deinit {
        solverTask?.cancel()
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Re-run tests (no regression)**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' test
```

Expected: all prior tests still pass. (No new test for AsyncStream — UI smoke
test in Task 19 covers it.)

- [ ] **Step 5: Commit**

```bash
git add ios/Tendle/Services/Solver.swift ios/Tendle/Services/GameCoordinator.swift
git commit -m "feat(core): GameCoordinator drives Solver via AsyncStream + background Task"
```

---

### Task 12: SoundService (silent stub)

**Files:**
- Create: `ios/Tendle/Services/SoundService.swift`

For Phase 1 we expose the API but never actually load audio. Phase 2 ships
real .caf clips.

- [ ] **Step 1: Implement silent stub**

```swift
import Foundation

enum SoundEffect {
    case tap
    case clear
    case gameOver
}

final class SoundService {
    private var enabled: Bool

    init(enabled: Bool = true) {
        self.enabled = enabled
    }

    func setEnabled(_ value: Bool) { enabled = value }

    func play(_ effect: SoundEffect) {
        guard enabled else { return }
        // Phase 1: no-op. Phase 2 wires AVAudioPlayer pool with .caf clips.
    }
}
```

- [ ] **Step 2: Build**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ios/Tendle/Services/SoundService.swift
git commit -m "feat(audio): SoundService silent stub for Phase 1"
```

---

### Task 13: BoardView (17×10 grid render)

**Files:**
- Create: `ios/Tendle/Views/BoardView.swift`

- [ ] **Step 1: Implement BoardView**

```swift
import SwiftUI

struct BoardView: View {
    let board: Board
    let highlight: Selection?

    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(
                geometry.size.width / CGFloat(Board.columns),
                geometry.size.height / CGFloat(Board.rows)
            )
            VStack(spacing: 0) {
                ForEach(0..<Board.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<Board.columns, id: \.self) { column in
                            cell(column: column, row: row, size: cellSize)
                        }
                    }
                }
            }
            .frame(width: cellSize * CGFloat(Board.columns),
                   height: cellSize * CGFloat(Board.rows))
        }
        .aspectRatio(CGFloat(Board.columns) / CGFloat(Board.rows), contentMode: .fit)
    }

    @ViewBuilder
    private func cell(column: Int, row: Int, size: CGFloat) -> some View {
        let isHighlighted = highlight.map { sel in
            (sel.minColumn...sel.maxColumn).contains(column) &&
            (sel.minRow...sel.maxRow).contains(row)
        } ?? false
        let cleared = board.isCleared(column: column, row: row)
        ZStack {
            Rectangle()
                .fill(isHighlighted ? Color.accentColor.opacity(0.25) : Color(.systemGray6))
                .border(Color(.systemGray3).opacity(0.4))
            if !cleared {
                Text("\(board.digit(column: column, row: row))")
                    .font(.system(size: size * 0.55, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
            }
        }
        .frame(width: size, height: size)
    }
}
```

- [ ] **Step 2: Build**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ios/Tendle/Views/BoardView.swift
git commit -m "feat(ui): BoardView — 17×10 grid render with selection highlight"
```

---

### Task 14: SelectionOverlay (live sum indicator)

**Files:**
- Create: `ios/Tendle/Views/SelectionOverlay.swift`

- [ ] **Step 1: Implement SelectionOverlay**

```swift
import SwiftUI

struct SelectionOverlay: View {
    let sum: Int

    var body: some View {
        Text("합 \(sum)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(background, in: Capsule())
            .foregroundStyle(.white)
    }

    private var background: Color {
        switch sum {
        case 10: return .green
        case ..<10: return .gray
        default: return .red
        }
    }
}
```

- [ ] **Step 2: Build**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ios/Tendle/Views/SelectionOverlay.swift
git commit -m "feat(ui): SelectionOverlay — live sum indicator pill"
```

---

### Task 15: GameView with drag gesture + commit on touch-up

**Files:**
- Create: `ios/Tendle/Views/GameView.swift`

- [ ] **Step 1: Implement GameView**

```swift
import SwiftUI

struct GameView: View {
    @State var coordinator: GameCoordinator
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var boardSize: CGSize = .zero
    @State private var lastTick: Date = .now

    private let onFinish: (GameSession) -> Void

    init(coordinator: GameCoordinator, onFinish: @escaping (GameSession) -> Void) {
        self._coordinator = State(initialValue: coordinator)
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 16) {
            hud
            boardArea
                .padding(.horizontal)
        }
        .padding(.vertical)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            coordinator.start()
            lastTick = .now
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { now in
            let deltaMs = Int(now.timeIntervalSince(lastTick) * 1000)
            lastTick = now
            coordinator.tick(deltaMs: deltaMs)
            if coordinator.session.phase == .ended {
                onFinish(coordinator.session)
            }
        }
    }

    private var hud: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("점수").font(.caption).foregroundStyle(.secondary)
                Text("\(coordinator.session.playerScore)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("남은 시간").font(.caption).foregroundStyle(.secondary)
                Text(timeString(coordinator.session.remainingMs))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal)
    }

    private func timeString(_ ms: Int) -> String {
        let s = ms / 1000
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    @ViewBuilder
    private var boardArea: some View {
        let selection = currentSelection
        ZStack {
            GeometryReader { geo in
                BoardView(board: coordinator.session.board, highlight: selection)
                    .coordinateSpace(name: "board")
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
                            .onChanged { value in
                                boardSize = geo.size
                                if dragStart == nil { dragStart = value.startLocation }
                                dragCurrent = value.location
                            }
                            .onEnded { value in
                                boardSize = geo.size
                                if let sel = selectionFrom(start: value.startLocation,
                                                          end: value.location) {
                                    coordinator.commit(sel)
                                }
                                dragStart = nil
                                dragCurrent = nil
                            }
                    )
            }
            if let selection {
                let sum = BoardEngine.rectangleSum(selection, on: coordinator.session.board)
                SelectionOverlay(sum: sum)
                    .allowsHitTesting(false)
            }
        }
    }

    private var currentSelection: Selection? {
        guard let start = dragStart, let cur = dragCurrent, boardSize != .zero else { return nil }
        return selectionFrom(start: start, end: cur)
    }

    private func selectionFrom(start: CGPoint, end: CGPoint) -> Selection? {
        guard boardSize != .zero else { return nil }
        let cellW = boardSize.width / CGFloat(Board.columns)
        let cellH = boardSize.height / CGFloat(Board.rows)
        let c0 = Int(start.x / cellW); let r0 = Int(start.y / cellH)
        let c1 = Int(end.x / cellW);   let r1 = Int(end.y / cellH)
        let minC = max(0, min(c0, c1)); let maxC = min(Board.columns - 1, max(c0, c1))
        let minR = max(0, min(r0, r1)); let maxR = min(Board.rows - 1, max(r0, r1))
        guard minC <= maxC && minR <= maxR else { return nil }
        return Selection(minColumn: minC, minRow: minR, maxColumn: maxC, maxRow: maxR)
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ios/Tendle/Views/GameView.swift
git commit -m "feat(ui): GameView with drag-rectangle gesture, HUD, and tick loop"
```

---

### Task 16: ResultView (player + bot side-by-side)

**Files:**
- Create: `ios/Tendle/Views/ResultView.swift`

- [ ] **Step 1: Implement ResultView**

```swift
import SwiftUI

struct ResultView: View {
    let session: GameSession
    let onHome: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            HStack(spacing: 40) {
                column(label: "당신", value: "\(session.playerScore)", color: .accentColor)
                column(label: "봇", value: botText, color: .secondary)
            }
            Text(microcopy)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            Button("홈으로", action: onHome)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }

    private var botText: String {
        if let progress = session.solverProgress, progress.isFinal {
            return "\(progress.bestScore)"
        }
        return "…"
    }

    private var microcopy: String {
        guard let progress = session.solverProgress, progress.isFinal else {
            return "봇이 아직 계산 중이에요."
        }
        switch session.playerScore - progress.bestScore {
        case let d where d > 0: return "봇을 이겼어요!"
        case 0: return "봇과 동점!"
        default: return "다음엔 분명 이길 거예요."
        }
    }

    private func column(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }
}
```

- [ ] **Step 2: Build**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ios/Tendle/Views/ResultView.swift
git commit -m "feat(ui): ResultView — player + bot side-by-side with pending state"
```

---

### Task 17: HomeView (idle + played states)

**Files:**
- Create: `ios/Tendle/Views/HomeView.swift`

- [ ] **Step 1: Implement HomeView**

```swift
import SwiftUI

struct HomeView: View {
    let today: String
    let todayRecord: DailyRecord?
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text("Tendle")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
            Text(today)
                .font(.headline).foregroundStyle(.secondary)
            Spacer()
            if let record = todayRecord {
                playedCard(record)
            } else {
                Button(action: onStart) {
                    Text("오늘의 보드 시작")
                        .font(.title3.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func playedCard(_ record: DailyRecord) -> some View {
        VStack(spacing: 10) {
            Text("이미 기록됨").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 30) {
                metric("당신", value: "\(record.playerScore)", color: .accentColor)
                metric("봇", value: record.botScore.map(String.init) ?? "…", color: .secondary)
            }
            Button("다시 도전", action: onStart)
                .buttonStyle(.bordered)
                .controlSize(.regular)
        }
        .padding(20)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func metric(_ label: String, value: String, color: Color) -> some View {
        VStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }
}
```

- [ ] **Step 2: Build**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add ios/Tendle/Views/HomeView.swift
git commit -m "feat(ui): HomeView — idle + already-played states"
```

---

### Task 18: Wire navigation in RootView + ModelContainer setup

**Files:**
- Modify: `ios/Tendle/App/RootView.swift`
- Modify: `ios/Tendle/App/TendleApp.swift`

- [ ] **Step 1: Add ModelContainer to TendleApp**

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

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
```

- [ ] **Step 2: Implement navigation in RootView**

```swift
import SwiftUI
import SwiftData

enum Route: Hashable {
    case game(dateKST: String)
    case result(GameSessionSnapshot)
}

/// Hashable, Codable snapshot of session state at end-of-round used in
/// NavigationStack path. We can't put the whole GameSession (with Board)
/// in NavigationPath if Board ever loses Hashable; this keeps things tight.
struct GameSessionSnapshot: Hashable, Codable {
    let dateKST: String
    let playerScore: Int
    let botScore: Int?
    let botIsFinal: Bool
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()
    @State private var liveCoordinator: GameCoordinator?

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                today: KSTClock.dateString(),
                todayRecord: try? StatsStore(modelContext: modelContext)
                    .record(for: KSTClock.dateString()),
                onStart: startDaily
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .game:
                    if let liveCoordinator {
                        GameView(coordinator: liveCoordinator) { session in
                            handleFinish(session)
                        }
                    } else {
                        Text("준비 중…")
                    }
                case .result(let snapshot):
                    ResultView(session: GameSession(
                        board: Board(digits: Array(repeating: 1, count: Board.cellCount)),
                        phase: .ended,
                        playerScore: snapshot.playerScore,
                        remainingMs: 0,
                        startedAt: .now,
                        dateKSTAtStart: snapshot.dateKST,
                        solverProgress: snapshot.botScore.map {
                            SolverProgress(bestScore: $0, expandedStates: 0,
                                           isFinal: snapshot.botIsFinal)
                        }
                    )) {
                        path = NavigationPath()
                        liveCoordinator = nil
                    }
                }
            }
        }
    }

    private func startDaily() {
        let date = KSTClock.dateString()
        let session = GameSession.newDaily(dateKST: date, now: .now)
        liveCoordinator = GameCoordinator(session: session)
        path.append(Route.game(dateKST: date))
    }

    private func handleFinish(_ session: GameSession) {
        let store = StatsStore(modelContext: modelContext)
        let date = session.dateKSTAtStart
        let progress = session.solverProgress
        let record = DailyRecord(
            dateKST: date,
            seedInputHash: String(KSTClock.dailySeed(forDate: date), radix: 16),
            startedAtKST: session.startedAt,
            endedAtKST: .now,
            dateKSTAtStart: date,
            playerScore: session.playerScore,
            durationMs: GameSession.totalDurationMs - session.remainingMs,
            botStatus: (progress?.isFinal ?? false) ? .final : .pending,
            botScore: progress?.bestScore,
            botFinalizedAt: (progress?.isFinal ?? false) ? .now : nil,
            solverProfile: SolverProfile.mvpV1.solverProfile,
            outcome: "completed"
        )
        _ = try? store.saveFirstAttempt(record)
        path.append(Route.result(GameSessionSnapshot(
            dateKST: date,
            playerScore: session.playerScore,
            botScore: progress?.bestScore,
            botIsFinal: progress?.isFinal ?? false
        )))
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' build
```

Expected: BUILD SUCCEEDED. If the compiler complains about
`GameSession` needing `Hashable` conformance in `NavigationPath`, add
`extension GameSessionSnapshot: Hashable {}` if not synthesised (it should be).

- [ ] **Step 4: Commit**

```bash
git add ios/Tendle/App/TendleApp.swift ios/Tendle/App/RootView.swift
git commit -m "feat(ui): wire Home → Game → Result navigation + SwiftData container"
```

---

### Task 19: Manual smoke test in iPhone 15 simulator

This task has no code. Verify the Phase 1 success criterion.

- [ ] **Step 1: Boot simulator and install**

```bash
xcrun simctl boot "iPhone 15" 2>/dev/null || true
open -a Simulator
xcodebuild -project ios/Tendle.xcodeproj -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
  -derivedDataPath ./build_smoke build
xcrun simctl install booted ./build_smoke/Build/Products/Debug-iphonesimulator/Tendle.app
xcrun simctl launch booted com.jinnsim.Tendle
```

- [ ] **Step 2: Play one round manually**

Verify in order:
1. `HomeView` shows today's KST date and the "오늘의 보드 시작" button.
2. Tap → `GameView` shows 17×10 board, timer counts down from 2:00.
3. Drag across any rectangle whose digits sum to 10 → cells clear, score
   increments by cell count, selection overlay disappears.
4. Drag across an invalid sum (e.g. 1+2 = 3) → no change.
5. Wait 2 minutes (or temporarily lower `GameSession.totalDurationMs` for
   smoke test) → automatically advances to `ResultView`.
6. `ResultView` shows player score on the left and bot score on the right.
   Bot may briefly show "…" then resolve to a number.
7. Tap "홈으로" → return to Home, which now shows "이미 기록됨" card with
   the just-recorded player + bot scores.
8. Kill and relaunch the app → "이미 기록됨" card persists.

- [ ] **Step 3: Capture a screenshot for the handoff doc**

```bash
mkdir -p docs/screenshots
xcrun simctl io booted screenshot docs/screenshots/phase1-home-played.png
xcrun simctl io booted screenshot docs/screenshots/phase1-result.png
```

- [ ] **Step 4: Document Phase 1 completion**

Append to `docs/handoff.md` (create if missing):

```markdown
## Phase 1 complete — 2026-05-17

Playable daily mode end-to-end on iPhone 15 simulator. Drag-select clears,
2-minute timer, bot side-by-side, SwiftData persistence, first-record rule
verified. Screenshots in `docs/screenshots/phase1-*.png`.

Outstanding (Phase 2): EncouragementService, Layer-2 illustrations on screens,
share card, sparkline stats, sound assets. (Phase 3): localization,
iPad-specific layout, CI.
```

- [ ] **Step 5: Commit**

```bash
git add docs/handoff.md docs/screenshots/
git commit -m "docs(phase1): manual QA pass + screenshots + handoff note"
```

---

## Self-Review (run after writing all tasks)

**Spec coverage check** (Phase 1 scope only — Phase 2/3 items intentionally
deferred):

| Spec section | Task(s) | OK? |
|--------------|---------|-----|
| §2 game rules | 4 (BoardEngine), 15 (drag commit) | ✓ |
| §3 daily mode, KST reset | 6 (KSTClock), 18 (Home/Game/Result wiring) | ✓ |
| §3.3 attempt lifecycle (first-record) | 8 (StatsStore), 18 (handleFinish) | ✓ partial — abandoned detection deferred to Phase 2 |
| §4 architecture | 1 (scaffold), 2 (port) | ✓ |
| §5 solver | 5 (Solver port), 11 (AsyncStream wiring) | ✓ |
| §6 board generation | 3 (BoardGenerator) | ✓ |
| §7.1 HomeView idle/played | 17 (HomeView) | ✓ |
| §7.2 GameView with drag + HUD | 13 (BoardView), 14 (SelectionOverlay), 15 (GameView) | ✓ |
| §7.3 ResultView | 16 (ResultView) | ✓ partial — no share, no encouragement (Phase 2) |
| §7.6 iPad sizing | none (aspect-ratio fit handles it loosely) | ⚠ deferred to Phase 3 polish |
| §8 SwiftData models | 7 (models), 18 (container) | ✓ |
| §13 non-functional (perf, offline, privacy) | inherent in design | ✓ |
| §18 characters/encouragement | NONE | ⚠ Phase 2 |

**Placeholder scan**: searched for "TBD", "TODO", "fill in" — none present.
Every task has complete code in its steps. Commit messages are concrete.

**Type consistency**: cross-checked symbol names:
- `BoardEngine.clear`, `BoardEngine.rectangleSum`, `BoardEngine.validClearActions` — consistent
- `Selection(minColumn:minRow:maxColumn:maxRow:)` — same initialiser used everywhere
- `Board.columns`, `Board.rows`, `Board.cellCount` — consistent
- `SolverProgress(bestScore:expandedStates:isFinal:)` — same in §5, Task 5, Task 11, Task 16, Task 18
- `DailyRecord` initialiser parameter order — same in Task 7 (definition), Task 8 (tests), Task 18 (handleFinish)
- `GameSession.totalDurationMs` — used in Task 9 (definition), Task 10 (test), Task 18 (snapshot fallback)
- `KSTClock.dateString(for:)` vs `dailySeed(forDate:)` — distinct and consistent
- `StatsStore.saveFirstAttempt` / `.record(for:)` / `.allRecords()` — consistent

**Gap noted** (intentional): no UI tests in Phase 1. Manual smoke (Task 19)
is sufficient to verify "the game is playable end-to-end". UI testing is a
Phase 3 add as part of CI investment.

**Solver `Equatable` note**: `SolverResult.isFinal` field added in Task 5 — the
ported spike test `testIsDeterministicAcrossReruns` (which compares two
`Solver.solve` results) still works because both invocations produce
`isFinal: true`, so the Equatable conformance passes.

---

## Phase 2 / Phase 3 preview (for handoff)

After Phase 1 ships, the next two plans will cover:

**Phase 2 — Personalized**
- EncouragementService + `Encouragement.json` resource wiring with trigger
  enum, deterministic selection rule, {streak} substitution per spec §18.3.
- EncouragementMomentView overlaying Layer-2 illustrations at trigger points.
- Layer-2 illustrations placed in HomeView, GameView (loading scene),
  ResultView (win/close/low), splash, welcome-back, streak milestone.
- Real `.caf` sound assets and SoundService AVAudioPlayer pool.
- ShareCardRenderer + share action on Daily ResultView (spec §9 ratio bar).
- StatsView with 30-day sparkline + win-vs-bot percentage.
- Abandoned-attempt detection (>5 min background → mark abandoned).

**Phase 3 — Polished & Localized**
- Layer-1 app icon (Codex-generated PNG sized for AppIcon.appiconset).
- Real launch screen using the splash illustration.
- Localizable.xcstrings populated for ko/en.
- Settings view (sound on/off, language picker, data reset, playerName edit).
- iPad-tuned layout (board max width 720 pt, cell min 36×36 pt).
- GitHub Actions CI workflow (build + test on push).
- Anytime solver (Phase 2 ships single-shot; Phase 3 adds incremental
  progress emission for a "watching the bot think" UX).
- Manual QA full checklist + bug bash.
