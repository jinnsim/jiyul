# Tendle — Design Spec

**Status:** Draft v3 (character + encouragement layer — awaiting user approval)
**Date:** 2026-05-17
**Owner:** Jung Soon Shin (@jinnsim)
**Target Phase:** MVP (Phase 1)

---

## 0. Audience & Personalization

Tendle is designed primarily for **Jiyul (지율)**, the owner's daughter — an
imaginative, English-fluent child who loves dragons, spiders, and snakes. The
companion character **Eunchan (은찬)** plays alongside her in the game's visual
world. Two consequences for design:

1. **Encouragement-first tone.** Game copy addresses Jiyul by name and offers
   warm praise at meaningful moments. Negative or punitive language is banned
   even for low-scoring rounds.
2. **Child-drawn illustration layer.** Beyond the minimalist app icon and chips
   (§11.1), the app carries a parallel illustration layer rendered in the
   style of an 8-year-old's drawing — crayons, naive perspective, expressive
   imperfection — featuring Jiyul, Eunchan, and Jiyul's beloved creatures.

The game is still well-formed for any player; nothing breaks if a different
person plays. But Jiyul is its first user, and the experience is tuned for her.

---

## 1. Overview

Tendle is a universal iOS (iPhone/iPad) daily puzzle game based on the classic
Korean "사과게임" (Fruit Box / Apple Game). Players drag-select rectangular
regions of a 17×10 grid of digits 1–9; if the digits in the rectangle sum to
exactly 10, they clear. Two-minute round, score = cells cleared.

**Twist:** every board ships with a **"오늘의 봇 점수"** — an in-app
deterministic beam-search solver runs in the background while the player plays
and publishes a fixed-profile benchmark score by the time the round ends. The
player's score is contextualized against the bot ("당신 87 / 봇 121"), turning
solo play into a daily benchmark without any backend.

**Character layer:** Jiyul and Eunchan appear as drawn companions in splash,
loading, empty states, and result screens — see §18.

**Operational posture** (matches kpop-heardle's indie-portfolio bar — see §15):
- No scheduled data jobs, no CDN mirror, no live backend.
- CI-only GitHub Actions (build + unit tests on push).
- Boards generated client-side from a deterministic date seed.
- 100% offline at runtime — the only input is the device clock.

---

## 2. Game Rules

Strict classic rules. The differentiation lives in the benchmark, not in the
mechanics.

- **Grid:** 17 columns × 10 rows of digits 1–9.
- **Distribution:** each cell is generated independently from {1,…,9} using a
  deterministic seeded RNG with rejection sampling (no modulo bias). Practically
  uniform; canonical-style for Fruit Box variants.
- **Selection:** player drags an axis-aligned rectangle over one or more cells.
  Already-cleared cells inside the rectangle contribute 0 to the sum and cannot
  be re-cleared.
- **Commit:** selection is committed only on touch-up. While dragging, the
  current rectangle and live sum are visualised; the action takes effect only
  when the finger lifts.
- **Clear rule:** rectangle clears iff the sum of remaining (non-cleared)
  digits inside it equals exactly 10.
- **Score:** +1 per cell cleared (cells, not digit values).
- **Time limit:** 120 seconds, hard.
- **End:** time expires. No "no moves possible" auto-end in MVP.
- **Invalid selection:** brief shake + light haptic, no score penalty.

---

## 3. Modes

### 3.1 MVP scope (Phase 1)

| Mode | Source of board | Recorded? | Bot score? |
|------|-----------------|-----------|------------|
| **오늘의 보드** (Daily) | `seed = hash("YYYY-MM-DD\|daily")`, KST date | First completed attempt of the day → stats | Yes (deterministic profile) |
| **통계** (Stats) | n/a | View only | n/a |

Practice mode (seed entry, ad-hoc replay), seed sharing, and iPad-specific
split view are explicitly **deferred to Phase 1.5** (see §14).

### 3.2 Daily reset & timezone

- "Today" is derived from `Date()` interpreted in `Asia/Seoul` (UTC+9).
  Device timezone does not affect which board is "today's".
- The same board appears worldwide at the same wall-clock instant.

### 3.3 Attempt lifecycle

A daily *attempt* has the following SwiftData fields (see §8): `startedAtKST`,
`endedAtKST`, `dateKSTAtStart`, `outcome ∈ {completed, abandoned}`, plus score
and bot data.

- An attempt **belongs to the date it was started on**, even if it finishes
  after midnight KST. The new day's board does not become available until the
  previous attempt ends.
- **Abandoned:** background → terminate / kill / launch fresh after >5 min →
  the attempt is marked abandoned and does **not** count as the day's first
  recorded attempt. The player can re-start (will be that day's first record).
- **Backgrounded briefly (<5 min):** timer pauses on backgrounding; resumes
  with the remaining time intact. (Apple HIG aligns with this for casual
  puzzles.)
- **First-record rule:** only the first attempt with `outcome == completed`
  per `dateKSTAtStart` contributes to stats / share. Re-plays show "이미 기록됨"
  and let the player replay for fun; subsequent attempts are not persisted.

---

## 4. Architecture

### 4.1 Stack

- **UI:** SwiftUI, iOS 17.0+, universal (iPhone + iPad)
- **Persistence:** SwiftData
- **Audio:** AVFoundation system sounds (`tap.caf`, `clear.caf`, `gameover.caf`)
- **Build:** xcodegen + Xcode 15.2+
- **Backend / scheduled jobs:** none
- **CI:** GitHub Actions for build + unit tests only

### 4.2 Component Boundaries

```
ios/Tendle/
  App/
    TendleApp.swift               @main entry, single-window scene
  Models/
    Board.swift                   17×10 grid, immutable snapshot
    Cell.swift                    digit + cleared flag
    Selection.swift               drag rectangle (col/row range)
    GameSession.swift             round state (mutable, owned by Coordinator)
    DailyRecord.swift             SwiftData @Model
    SolverCache.swift             SwiftData @Model
    Stats.swift                   computed aggregates
    SolverProgress.swift          { bestScore, nodesExpanded, isFinal }
  Services/
    SeededRNG.swift               SplitMix64, deterministic
    BoardGenerator.swift          seedInput → Board (rejection sampling)
    BoardEngine.swift             pure functions — selection validity,
                                  rectangle sum, clear application
    GameCoordinator.swift         round lifecycle. See §4.4 on actor policy.
    Solver.swift                  deterministic beam search, node-budget
                                  bounded. Task.detached background priority.
    StatsStore.swift              SwiftData wrapper
    ShareCardRenderer.swift       text + emoji ratio bar
    SoundService.swift            preloaded AVAudioPlayer pool
  Views/
    RootView.swift                NavigationStack root (iPhone & iPad same)
    HomeView.swift                Daily CTA + Stats entry
    GameView.swift                BoardView + HUD + drag overlay
    BoardView.swift               17×10 grid render
    SelectionOverlay.swift        live drag rectangle + sum indicator
    ResultView.swift              score + bot + share + replay
    StatsView.swift               aggregates + recent history
    SettingsView.swift            sound on/off, data reset, about
  Resources/
    Assets.xcassets/              Codex-generated app icon + imagery
    Sounds/                       tap/clear/gameover (royalty-free)
    Localizable.xcstrings         ko, en (system locale, no in-app picker)
```

### 4.3 Dependency Direction

Strictly `View → Service → Model`. `BoardEngine` is a free-function namespace
(`enum BoardEngine { static func ... }`) so it is trivially testable.

### 4.4 Actor / Threading Policy

- `GameCoordinator` is `@Observable`, **not** annotated `@MainActor`.
  - UI-mutating entry points (start round, commit selection, end round) are
    invoked from `MainActor` view bodies.
  - Pure data helpers (e.g. timer tick handlers, score recompute) stay sync /
    nonisolated, allowing SwiftUI view bodies to read state without context
    hops. This mirrors the kpop-heardle precedent and the reason is identical:
    avoid spurious `await` requirements in casual view-body reads.
- `Solver` is invoked via `Task.detached(priority: .background)`. It publishes
  `SolverProgress` via an `AsyncStream<SolverProgress>` that `GameCoordinator`
  consumes and republishes to the UI on `MainActor`.
- The solver task is bound to the game session: session teardown cancels it.
- `BoardEngine` and `BoardGenerator` are synchronous and thread-safe (no
  shared state).

---

## 5. Solver Design

### 5.1 Algorithm: Deterministic Beam Search

- Beam of fixed width `W` per **solver profile** (see §5.2).
- At each step, expand every state in the beam: enumerate all rectangles whose
  current sum equals 10, score each successor, keep top-`W`.
- Evaluation function: `realized_score + α · potential(remaining_board)`,
  where `potential` is the count of pair/triple/quad combinations that can
  still sum to 10 in the remaining board (cheap O(rows · cols) estimate).
- `α` is fixed per `solverVersion`; never mutated at runtime.
- Tie-break: stable sort by `(score desc, lex(selectionOrder) asc)`. No
  randomness anywhere in the solver.
- Track `bestRealizedScore`; publish on every improvement.
- Termination: beam empty, OR `expandedStates >= maxExpandedStates`, OR task
  cancelled.

### 5.2 Solver Profile (deterministic, device-independent)

Profile = the complete set of parameters that determine output:

```
solverProfile = "mvp-v1"
  beamWidth          = 64
  maxExpandedStates  = 200_000
  alpha              = 0.10           # tuned per §5.6
  scoringHash        = sha1(serializedScoringSpec)   // see §5.3
  rngSeedForTies     = 0              // not used (deterministic tie-break)
  solverVersion      = 1
```

**Same profile + same board ⇒ identical bot score on every device.** Wall-clock
budget is **not** part of the profile. A faster device finishes earlier; the
score is the same.

### 5.3 Scoring spec serialization

`scoringHash` is derived from a stable serialization of the scoring function's
exact code path (constants + algorithm version). Bump `solverVersion` whenever
the hash changes, which invalidates the solver cache (§5.5).

### 5.4 UI / Determinism Contract

- During the round, UI shows `progress.bestRealizedScore` as a soft, growing
  indicator. This number is **non-decreasing**.
- The number stored in `DailyRecord.botScore` is **always the deterministic
  final** (when `expandedStates` reaches `maxExpandedStates` or beam empties).
- If the deterministic final has not yet been reached by `ResultView` time,
  the record is saved with `botStatus = .pending` and the bot UI shows
  "봇 계산 중…". When the solver settles, `botStatus → .final` and the UI
  updates. See §7.3 for behavior.

### 5.5 Caching

```swift
@Model final class SolverCache {
  @Attribute(.unique) var cacheKey: String   // "<seedInputHash>|<solverProfile>"
  var botScore: Int
  var solverProfile: String
  var solverVersion: Int
  var computedAt: Date
}
```

Cache hit ⇒ instant final value, no recomputation. `solverVersion` change
invalidates: next computation overwrites the entry.

### 5.6 Solver Spike — Exit Criteria (gates implementation)

Before solver code lands in main, a standalone spike must pass:

- Build a Swift package `SolverSpike` outside the app target.
- Generate 100 random seeds, run solver-mvp-v1 on each.
- **Gate 1 (correctness):** on 10 hand-crafted small boards with known optima,
  solver finds ≥ 90% of optimal.
- **Gate 2 (determinism):** rerun on the same seeds, **100%** identical scores
  bit-for-bit, on iPhone 12 sim, iPhone 15 sim, and Mac.
- **Gate 3 (performance):** on iPhone 12 simulator (Apple Silicon Mac host),
  p95 wall-clock < 30 s per board.
- If any gate fails, profile parameters are adjusted and `solverVersion`
  remains 1 (this is pre-ship tuning, not a deployed change).

---

## 6. Board Generation

### 6.1 Seeding

```
seedInput   = "<YYYY-MM-DD KST>|daily"          # daily mode
seed64      = SHA256(seedInput).prefix(8) as UInt64
rng         = SplitMix64(state: seed64)
```

### 6.2 Cell sampling (rejection, no modulo bias)

```
func nextDigit(_ rng: inout SplitMix64) -> Int {
  // 9 buckets in [0, ⌊2^64 / 9⌋ · 9); reject anything above
  let bound = (UInt64.max / 9) * 9
  var r: UInt64
  repeat { r = rng.next() } while r >= bound
  return Int(r % 9) + 1
}
```

Each of the 170 cells uses one call. Deterministic and bias-free.

---

## 7. Screens (MVP)

### 7.1 HomeView

States visible to the user:

| State | Trigger | UI |
|-------|---------|----|
| `idle.notPlayedToday` | first launch of the day | "오늘의 보드" primary CTA |
| `played.botCached` | first attempt completed, bot final stored | CTA shows score + 봇 비교 badge; "다시 도전" secondary |
| `played.botPending` | first attempt completed, bot still computing | Same as above with subtle "봇 계산 중…" |

iPad: same layout, scaled up. No sidebar / no split view in MVP.

### 7.2 GameView

- HUD: 점수, 남은 시간, 봇 진행 표시 ("봇 …")
- BoardView: fixed-aspect surface, **not inside a ScrollView**. Drag uses
  `DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))`. Hit
  testing is done in board-space to avoid pollution from sidebar / system
  edge swipes.
- SelectionOverlay: live rectangle + sum indicator
  (red `>10`, gray `<10`, green `=10`).
- Commit on touch-up only (§2).

### 7.3 ResultView

- Big player score + bot score side-by-side.
- Win/lose/tie microcopy ("봇을 이겼습니다!" etc.).
- Bot status states:
  - `.final` → show number.
  - `.pending` → show "봇 계산 중…" pulse; live-update when ready.
  - `.failed` → "봇 결과 없음" (shouldn't happen; logged).
- Actions: **다시 도전** (today extra attempt, stats unchanged), **공유**
  (Daily only), **홈으로**.
- Replay path: rebuilds a fresh `GameSession` with the same board; no record
  is written.

### 7.4 StatsView

- 누적 플레이 수, 연속일, 평균 점수, 최고 점수, 봇 승률
- 최근 30일 점수 sparkline.

### 7.5 SettingsView

- Sound on/off
- Language: 한국어 / English / 시스템 따름 (default: 시스템 따름)
- Data reset (with confirmation dialog)
- About / version

### 7.6 iPad layout

- Same `RootView` (NavigationStack) as iPhone, scaled.
- BoardView max width clamped (`min(geometry.width, 720pt)`) to keep cells
  finger-friendly. Cell minimum render size: 36×36 pt.
- No side panel in MVP.
- Both portrait and landscape supported; layout reflows around board's fixed
  aspect ratio.

---

## 8. Data & Persistence

```swift
enum BotStatus: String, Codable {
  case pending, final, failed
}

@Model final class DailyRecord {
  @Attribute(.unique) var dateKST: String        // "2026-05-17"
  var seedInputHash: String                       // hex of SHA256(seedInput)
  var startedAtKST: Date
  var endedAtKST: Date
  var dateKSTAtStart: String                      // == dateKST normally
  var playerScore: Int
  var durationMs: Int
  var botStatusRaw: String                        // BotStatus
  var botScore: Int?                              // nil while pending
  var botFinalizedAt: Date?
  var solverProfile: String
  var outcome: String                             // "completed" | "abandoned"
}

@Model final class SolverCache {
  @Attribute(.unique) var cacheKey: String        // see §5.5
  var botScore: Int
  var solverProfile: String
  var solverVersion: Int
  var computedAt: Date
}

@Model final class Settings {
  var soundEnabled: Bool
  var hapticsEnabled: Bool
  var languageOverride: String?    // nil = follow system; "ko" | "en"
  var playerName: String           // default: "지율"  — addressed in copy (§18)
}
```

Migration: none for MVP. `solverVersion` lets us invalidate cached bot scores
when the solver changes.

---

## 9. Share Format

Wordle-style, plain text. **Emoji ratio bar** (not a board snapshot):

```
Tendle 2026-05-17
🟩 87 · 🤖 121 (72%)
███████████████░░░░░
```

- Bar = player/bot ratio, capped at 100%.
- No URL in MVP (no landing site exists). Added in Phase 2.

---

## 10. Localization (MVP)

- Korean (primary) and English, both first-class. Jiyul speaks both; encouragement
  copy (see §18) is authored bilingually rather than machine-translated.
- System locale chooses the default; an in-app KO/EN toggle is provided in
  Settings even in MVP (small scope, large UX value for a bilingual child user).
- Single `Localizable.xcstrings`.
- Numbers via `Formatter`; dates via explicit `Asia/Seoul` for daily,
  user-locale for everything else.

---

## 11. Imagery & Audio Assets

### 11.1 Imagery — two-layer Codex workflow

The app has **two parallel visual layers**, each generated by Codex from
prompts checked into `docs/asset-prompts.md`:

**Layer 1 — System/UI (minimal two-tone)**
- App icon (1024×1024), system iconography, chips.
- Minimal, two-tone, soft rounded squares; "중독성 · 아이디어 우선, 화려한
  그래픽 지양" brief.

**Layer 2 — Character illustrations (child-drawn, 8-year-old aesthetic)**
- Jiyul and Eunchan illustrations placed in splash, loading, empty states,
  result screens, milestone moments (streak, win-vs-bot).
- Crayon / marker / colored-pencil texture, naive perspective, expressive
  imperfection, hand-lettered details acceptable.
- Jiyul recurring motifs: friendly dragons, cute spiders, playful snakes —
  drawn as companions, never threatening.

Workflow for both layers:
- Prompts in `docs/asset-prompts.md` (input prompt + output filename +
  revision notes) so anyone can re-generate.
- Generated PNGs placed into `Assets.xcassets` manually; no automation in MVP.
- The two layers do not compete: Layer 1 owns chrome, Layer 2 owns moments.

### 11.2 Audio

- Three short `.caf` clips: `tap.caf`, `clear.caf`, `gameover.caf`.
- Royalty-free, bundled in app.
- Toggleable in Settings.

---

## 12. Testing Strategy

| Layer | Approach |
|-------|----------|
| `BoardEngine` | XCTest — pure functions, exhaustive selection-validity cases |
| `BoardGenerator` | XCTest — determinism (same seed → same board), rejection-sampling stat sanity |
| `Solver` | XCTest — small known-optimum boards; determinism across reruns |
| `GameCoordinator` | XCTest with fake clock — score, end-of-round, attempt lifecycle |
| `StatsStore` | XCTest with in-memory `ModelContainer` |
| Solver spike gates | §5.6 — separate spike package, gating ship |
| Views | Manual QA in iOS Simulator (iPhone 15, iPad Pro 11") |

CI: GitHub Actions runs `xcodebuild test` on push.

---

## 13. Non-Functional

- **Performance:** 60 fps board interactions on iPhone 12+. Solver runs at
  `.background` priority so it cannot starve the main thread.
- **Battery:** node-budget bound (§5.2) caps solver CPU; no wall-clock chase.
- **Offline:** 100% — no network calls anywhere in MVP.
- **Accessibility:** VoiceOver labels on cells ("3, 5열 8행"), Dynamic Type
  support on text labels, reduce-motion respects clear animations.
- **Privacy:** zero data leaves device. No analytics, no crash reporter in MVP.

---

## 14. Out of Scope

### Phase 1.5 (post-MVP polish)

- **Practice mode** with 6-digit seed entry and "이 보드 같이 풀자" share
- Haptic intensity slider
- iPad split view + side panel
- Sound asset polish (custom-designed clips)
- Animated character illustrations (currently static — §18.6)

### Phase 2

- GameKit leaderboards
- Daily push notification reminder
- Additional locales (ja, zh, …)
- Themes / skins
- Universal Links / deep-link seed sharing
- Web companion / landing site

### Phase 3

- Backend / cross-device sync
- Multi-difficulty boards
- Deadlock auto-end detection

---

## 15. Hard Constraints (CLAUDE.md material)

- **iOS deployment target:** 17.0 (SwiftData requirement).
- **Daily reset zone:** `Asia/Seoul` (UTC+9). Not user-local.
- **Solver:** deterministic, node-budget-bounded, cancellable. Same profile +
  same board ⇒ identical bot score on every device. Never block UI.
- **GameCoordinator:** `@Observable`, **not** `@MainActor`. Pure data helpers
  remain sync/nonisolated. UI-mutating entry points are called from
  `MainActor` view bodies. (Same precedent and rationale as kpop-heardle.)
- **Networking:** none in MVP. If added later, must be optional and
  non-blocking.
- **Imagery assets:** generated via Codex workflow. Prompts live in
  `docs/asset-prompts.md`.
- **Operational posture:** no scheduled jobs / no live backend / no CDN
  mirror. CI-only GitHub Actions allowed (build + unit tests).

---

## 16. Project Layout

```
/Users/jongjinseok/Documents/Tendle/
  README.md
  CLAUDE.md
  AGENTS.md
  .gitignore
  ios/
    project.yml                # xcodegen
    Tendle/                    # SwiftUI sources (per §4.2)
    TendleTests/
    SolverSpike/               # standalone spike package (§5.6)
  docs/
    superpowers/specs/
      2026-05-17-tendle-design.md   ← this file
    decisions.md
    asset-prompts.md
    handoff.md
  .github/workflows/
    ci.yml                     # build + test only
```

---

## 17. Open Questions (none blocking implementation)

- Final App Store listing name (Tendle is placeholder).
- `α` final value pending §5.6 spike completion.
- Whether to expose haptic intensity slider — currently Phase 1.5.
- Whether `playerName` is user-editable in MVP (default "지율"). Recommend
  yes, single field in Settings.

---

## 18. Characters & Encouragement System

### 18.1 Characters

- **Jiyul (지율)** — long-haired, cheerful girl. The **protagonist**. Loves
  dragons, spiders, snakes. Imaginative; fluent in Korean and English. The
  in-app player avatar is implicitly Jiyul; encouragement copy addresses her
  by name (configurable in Settings — §8 `playerName`).
- **Eunchan (은찬)** — companion boy. Plays alongside Jiyul, cheering and
  sharing reactions. Appears in pair illustrations.

The pair always appears as friends — collaborative, never competitive with
each other. The competitive dimension of the game is "Jiyul + Eunchan vs the
bot", not "Jiyul vs Eunchan".

### 18.2 Visual placement

| Surface | Layer-2 illustration |
|---------|----------------------|
| Splash screen | Jiyul + Eunchan reaching toward a giant 10 tile, friendly dragon coiled around the title |
| HomeView empty-state | Jiyul and Eunchan sitting cross-legged, Jiyul holding the day's calendar tile, a spider companion peeking from behind |
| GameView loading / solver init | Jiyul reading a tiny scroll of numbers, snake friend draped over her shoulder |
| ResultView win | Jiyul and Eunchan high-fiving, dragon doing a happy loop overhead |
| ResultView lose / low-score | Jiyul and Eunchan shrugging warmly together, spider giving a thumbs-up (no sad faces) |
| Streak milestone | Jiyul wearing a paper crown, Eunchan clapping, snake forming a small celebratory loop |

All in Layer-2 child-drawn style (§11.1). Prompts in §7 of
`docs/asset-prompts.md` (added in this revision).

### 18.3 Encouragement copy system

A small, file-driven catalog of bilingual praise/encouragement lines selected
deterministically at runtime. Lives in `Services/EncouragementService.swift`
and `Resources/Encouragement.json`.

**Trigger moments:**

| Trigger | Example (KO) | Example (EN) |
|---------|--------------|--------------|
| Round start | "지율아, 오늘도 시작해 보자!" | "Let's go, Jiyul!" |
| First clear of round | "좋아! 멋진 출발이야 ✨" | "Nice start!" |
| Combo (≥3 clears in 5s) | "와! 지율이 천재인데?" | "Wow, you're on fire!" |
| Round end, beat bot | "지율이가 봇을 이겼어! 대단해!" | "You beat the bot, Jiyul!" |
| Round end, close to bot | "거의 다 왔어! 다음엔 분명 이길 거야." | "So close — next one's yours!" |
| Round end, low score | "오늘은 살짝 어려웠지? 같이 다시 해보자." | "Tough one today — let's try again together." |
| Streak day +1 | "벌써 N일째! 지율이 진짜 꾸준해." | "N days in a row! You're amazing, Jiyul." |
| App reopen after a break | "지율아 다시 와줘서 반가워!" | "Welcome back, Jiyul!" |

**Selection rule** (deterministic, varied):

```swift
seed = hash(playerName, dateKST, triggerKind, attemptIndex)
line = catalog[triggerKind][seed % catalog[triggerKind].count]
```

Same trigger same day → same line. Different attempts/days vary naturally.

**Language**: catalog stores `{ ko: [...], en: [...] }` arrays per trigger.
Active language follows `Settings.languageOverride ?? Locale.current`.

**Constraint**: every line must be warm. Banned: shame, sarcasm, comparative
disparagement, performance pressure ("you should have done better").

### 18.4 Why we keep it deterministic

Children notice variety, but they also notice unfairness. A deterministic
selection means a given trigger on a given day produces the same encouragement
across re-plays and devices — Jiyul can show Eunchan "see, the game said this
to me today" without weird non-repro behaviour.

### 18.5 Implementation footprint

- One new service: `EncouragementService` (~50 LOC).
- One new resource: `Encouragement.json` (KO+EN copy bank, ~30 lines/trigger).
- Hooks: `GameCoordinator` emits trigger events; `EncouragementService`
  returns line; relevant views display in a non-blocking banner / overlay.
- Layer-2 illustrations attached to triggers via `EncouragementMomentView`
  (chooses scene per trigger).

### 18.6 Out of scope (Phase 2+)

- Voiceover audio (recorded TTS / human VO of lines)
- Multi-character switching (Jiyul ↔ Eunchan as POV)
- Customizable character roster
- Animated illustrations

