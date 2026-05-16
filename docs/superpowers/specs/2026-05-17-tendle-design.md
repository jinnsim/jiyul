# Tendle — Design Spec

**Status:** Draft (awaiting user review)
**Date:** 2026-05-17
**Owner:** Jung Soon Shin (@jinnsim)
**Target Phase:** MVP (Phase 1)

---

## 1. Overview

Tendle is a universal iOS (iPhone/iPad) daily puzzle game based on the classic
Korean "사과게임" (Fruit Box / Apple Game). Players drag-select rectangular
regions of a 17×10 grid of digits 1–9; if the selected cells sum to exactly 10,
they clear. Two-minute round, score = cells cleared.

**Twist:** every board ships with a **"오늘의 봇 점수"** — an in-app heuristic
solver runs an anytime beam search in the background while the player plays and
publishes a benchmark score by the time the round ends. The player's score is
contextualized against the bot (e.g. "당신 87 / 봇 121"), turning a solitary
casual game into a daily benchmark exercise without any backend.

**Why this design fits the indie-portfolio bar of kpop-heardle:**
- Zero backend. Boards generated client-side from a deterministic date seed.
- Zero operational ask. No GitHub Actions, no CDN mirror, no data refresh.
- Same SwiftUI + SwiftData stack, same iOS 17.0 minimum.
- Offline-100%: the only dynamic input is the current date.

---

## 2. Game Rules

Strict classic rules — the entire twist is in the benchmark, not in the
mechanics.

- **Grid:** 17 columns × 10 rows of digits 1–9.
- **Distribution:** deterministic per seed; uniform sampling 1–9 (matches
  the canonical Apple Game distribution).
- **Selection:** player drags an axis-aligned rectangle covering one or more
  cells. Empty (already-cleared) cells inside the rectangle are ignored.
- **Clear rule:** rectangle clears if and only if the sum of remaining digits
  inside it equals exactly 10.
- **Score:** +1 per cell cleared.
- **Time limit:** 120 seconds, hard.
- **End:** time expires. (No "no moves possible" detection in MVP — board can
  technically deadlock but the timer always ends the round.)
- **No penalties** for invalid selections.

---

## 3. Modes

| Mode | Source of board | Recorded? | Bot score? |
|------|-----------------|-----------|------------|
| **오늘의 보드** (Daily) | `seed = hash("YYYY-MM-DD\|daily")` (KST date) | First completion per day → stats | Yes |
| **자유연습** (Practice) | `seed = user-entered 6-digit code` OR random | Never | Yes (computed per session) |
| **통계** (Stats) | n/a | View only | n/a |

**Daily reset:** KST (UTC+9) midnight. Same board worldwide at the same wall-clock
moment. The app derives "today" from `Date()` interpreted in `Asia/Seoul` —
device timezone is irrelevant to which board is "today's".

**Daily re-play:** allowed for fun. Only the first attempt of the day counts
toward stats; subsequent attempts show "이미 기록됨" badge.

**Practice seed sharing:** "이 보드 같이 풀자" share sheet outputs a deep link
or a 6-digit seed code the friend can paste in.

---

## 4. Architecture

### 4.1 Stack

- **UI:** SwiftUI, iOS 17.0+, universal (iPhone + iPad with adaptive layout)
- **Persistence:** SwiftData (game records, stats, settings)
- **Audio:** AVFoundation system sounds for tap / clear / game-over only
  (no music, no iTunes API — this is not a music game)
- **Build:** xcodegen + Xcode 15.2+, same conventions as kpop-heardle
- **Backend:** none
- **CI:** GitHub Actions for build verification only (no data jobs)

### 4.2 Component Boundaries

```
ios/Tendle/
  App/
    TendleApp.swift               @main entry, scene + root split
  Models/
    Board.swift                   17×10 grid, immutable snapshot
    Cell.swift                    digit + cleared flag
    Selection.swift               drag rectangle (col/row range)
    GameSession.swift             mutable state during a round
    DailyRecord.swift             SwiftData @Model — one per day
    Stats.swift                   computed aggregates
    SolverProgress.swift          { bestScore, elapsedMs, isFinal }
  Services/
    BoardGenerator.swift          seed → Board (SeedableRNG, splitmix64)
    BoardEngine.swift             pure functions — validate selection,
                                  sum, apply clear, board diff
    GameCoordinator.swift         timer + score + lifecycle.
                                  NOT @MainActor — view bodies call sync.
    Solver.swift                  anytime beam search.
                                  Task.detached(priority: .background).
                                  Publishes SolverProgress via AsyncStream.
    StatsStore.swift              SwiftData wrapper — query/aggregate
    ShareCardRenderer.swift       text + emoji-grid share payload
    SoundService.swift            preloaded AVAudioPlayer pool
  Views/
    RootView.swift                iPhone — NavigationStack
    RootSplitView.swift           iPad — NavigationSplitView sidebar/detail
    HomeView.swift                "오늘의 보드" CTA + 자유연습 + 통계 진입
    GameView.swift                BoardView + HUD + drag overlay
    BoardView.swift               17×10 grid render
    SelectionOverlay.swift        drag rectangle + live sum indicator
    ResultView.swift              점수 + 봇 비교 + 공유 + 다시 도전
    StatsView.swift               누적/연속/최고/봇 승률
    PracticeView.swift            시드 입력 + 랜덤 시작
    SettingsView.swift            언어, 사운드, 데이터 초기화
  Resources/
    Assets.xcassets/              (Codex-generated app icon + imagery)
    Sounds/                       tap.caf, clear.caf, gameover.caf
    Localizable.xcstrings         ko, en
```

### 4.3 Dependency Direction

Strictly one-way: `View → Service → Model`. Models are pure value types.
Services are class/actor singletons injected via `@Environment` where possible.
`BoardEngine` is a free-function namespace (`enum BoardEngine { static func … }`)
so it can be tested with no setup.

### 4.4 Threading

- `GameCoordinator` runs on the main actor for UI binding but mutates session
  state synchronously (matching kpop-heardle's deliberate non-`@MainActor`
  pattern on the data-only paths).
- `Solver` runs in a `Task.detached(priority: .background)`. It publishes
  `SolverProgress` updates via `AsyncStream<SolverProgress>` that
  `GameCoordinator` consumes and republishes to the UI. The solver task is
  bound to the game session — cancellation on session teardown is mandatory.
- `BoardEngine` is purely synchronous and thread-safe.

---

## 5. Solver Design

### 5.1 Algorithm: Anytime Beam Search

- Maintain a beam of width `W` (default 128 on A14+, 64 on older).
- At each step, expand every state in the beam: enumerate all rectangles whose
  current sum equals 10, score each successor state, keep top-`W`.
- Evaluation function: `realized_score + α · potential(remaining_board)`,
  where `potential` counts the number of pair/triple combinations that can
  still sum to 10 in the remaining board (cheap O(rows · cols) estimate).
  The weight `α` is tuned during implementation against a held-out set of
  seeds; persisted as part of `solverVersion`.
- Track `currentBest: Int` (highest realized score seen across all expanded
  states). Publish on every improvement.
- Termination: beam empty, or wall-clock budget reached, or task cancelled.

### 5.2 Time Budget

- Started: game start (player taps "시작").
- Soft target: 30 seconds — usually converges well before this.
- Hard cancel: game end (whichever comes first).
- Result available: by the time `ResultView` appears.
- Edge case (player finishes in <10s): keep the solver running briefly on
  `ResultView` with a small "봇 계산 중…" placeholder; once final, swap in.

### 5.3 Why beam search, not exact?

Exact solution is intractable in general (state space explodes with rectangle
choices). Beam search produces a strong, *deterministic*, *cancellable*
benchmark. We never claim "이론치" — UI copy is "봇 점수" / "도전 점수".

### 5.4 Determinism

Given identical (seed, beam width, scoring function, time budget), the solver
produces identical output. Important so: (a) two players on similar devices see
the same bot number; (b) bug reports reproduce.

### 5.5 Caching

`SolverResult { seed, botScore, beamWidth, version, computedAtMs }` cached in
SwiftData. On revisit of a known seed, show cached value instantly while
optionally re-running if `version` bumped.

---

## 6. Board Generation

### 6.1 Seeding

```
seed_input = "<YYYY-MM-DD KST>|daily"        # daily mode
seed_input = "<6-digit code>|practice"        # shared practice
seed_input = "<UUID>|practice"                # ad-hoc practice
seed_64    = SHA256(seed_input).prefix(8) as UInt64
rng        = SplitMix64(state: seed_64)
```

Each of the 170 cells: `rng.next() % 9 + 1`.

### 6.2 Why not "guaranteed solvable above N"

We do not pre-filter boards for solvability quality. Uniform random is the
classic distribution and produces playable boards. Stats — including the bot
score — naturally communicate board difficulty.

---

## 7. Screens (MVP)

### 7.1 HomeView
- Title + date + streak chip
- Primary CTA: **"오늘의 보드"** (badge if already played today)
- Secondary: **자유연습**, **통계**
- iPad: sidebar variant in `RootSplitView`

### 7.2 GameView
- HUD: 점수, 남은 시간, 봇 진행 표시 (subtle — "봇 계산 중 · 87")
- BoardView: 17×10 grid, generous tap targets, drag overlay shows live sum
  (red if >10, gray if <10, green if =10)
- Drag commit on touch-up: green → clear with animation + sound

### 7.3 ResultView
- 큰 점수 + 봇 점수 side-by-side
- 승/무/패 마이크로카피 (e.g. "봇을 이겼습니다!")
- 액션: **다시 도전** (오늘 추가 시도, stats 미반영), **공유**, **홈으로**
- Share button visible only for Daily mode. Practice mode shows the same
  result layout but without the share action and without a date in the header.
- Share payload: text + emoji grid (see §9)

### 7.4 StatsView
- 누적 플레이 수, 연속일, 평균 점수, 최고 점수, 봇 승률
- 최근 30일 점수 그래프 (스파크라인 정도, kpop-heardle 결)

### 7.5 PracticeView
- 시드 입력 필드 (6자리) + 랜덤 시작 버튼
- 친구가 보낸 코드 paste 지원

### 7.6 SettingsView
- 언어 (Korean / English)
- 사운드 on/off
- 데이터 초기화 (확인 dialog)
- About / 버전

### 7.7 iPad Layout
- `NavigationSplitView`: sidebar = HomeView 항목, detail = 선택 화면
- GameView on iPad: 보드 중앙, 우측에 통계/봇 진행 상시 노출 사이드 패널

---

## 8. Data & Persistence

### 8.1 SwiftData Models

```swift
@Model final class DailyRecord {
  @Attribute(.unique) var dateKST: String  // "2026-05-17"
  var seed: UInt64
  var playerScore: Int
  var botScore: Int
  var durationMs: Int
  var completedAt: Date
}

@Model final class SolverCache {
  @Attribute(.unique) var seed: UInt64
  var botScore: Int
  var solverVersion: Int
  var computedAt: Date
}

@Model final class Settings {
  var locale: String          // "ko" | "en" | "system"
  var soundEnabled: Bool
  var hapticsEnabled: Bool
}
```

### 8.2 Migration

None for MVP. Schema versioning hook reserved (`solverVersion` lets us
invalidate cached bot scores when the solver changes).

---

## 9. Share Format

Wordle-style, plain text. Example:

```
Tendle 2026-05-17
🟩 87 · 🤖 121
░░░░░░░░░░░░░░░░░ 72%
tendle.app/d/2026-05-17
```

- Emoji bar shows player/bot ratio
- Last line is an optional landing URL (Phase 2 — for MVP, omit URL since
  there is no website)

---

## 10. Localization (MVP)

- **Korean** (primary), **English**
- Single `Localizable.xcstrings` file (Xcode 15 catalog format)
- Numbers: locale-aware formatting via `Formatter.localizedString(from:number:style:)`
- Dates: explicit `Asia/Seoul` for daily, locale display for everything else
- Future locales added incrementally (kpop-heardle reached 13 over time)

---

## 11. Imagery & Audio Assets

### 11.1 Imagery — Codex workflow
- App icon (1024×1024), launch screen, empty-state illustrations are generated
  via OpenAI Codex / ChatGPT image generation, driven by documented prompts.
- Prompts checked into `docs/asset-prompts.md` for reproducibility (input
  prompt + output filename + revision notes).
- Generated PNGs placed into `Assets.xcassets` manually; no automation in MVP.
- Style direction: minimal, two-tone, soft rounded squares — visual identity
  follows the user's "중독성 · 아이디어 우선, 화려한 그래픽 지양" brief.

### 11.2 Audio
- Three short `.caf` clips: `tap.caf`, `clear.caf`, `gameover.caf`
- Royalty-free, embedded in app bundle
- Toggleable in Settings

---

## 12. Testing Strategy

| Layer | Approach |
|-------|----------|
| `BoardEngine` | XCTest unit tests — pure functions, exhaustive selection-validity cases |
| `BoardGenerator` | XCTest — determinism (same seed → same board), distribution sanity |
| `Solver` | XCTest — small hand-crafted boards with known optima; non-regression test |
| `GameCoordinator` | XCTest with fake timer — score accounting, end-of-round transitions |
| `StatsStore` | XCTest with in-memory `ModelContainer` |
| Views | Manual QA in iOS Simulator (iPhone 15, iPad Pro 11") |

CI: GitHub Actions runs `xcodebuild test` on push.

---

## 13. Non-Functional

- **Performance:** 60 fps board interactions on iPhone 12+. Solver throttled to
  not starve the main thread.
- **Battery:** solver capped at 30s/round; uses `.background` priority.
- **Offline:** 100% — no network calls anywhere in MVP.
- **Accessibility:** VoiceOver labels on cells ("3, 5열 8행"), Dynamic Type
  support on text, reduce-motion respected for clear animations.
- **Privacy:** zero data leaves device. No analytics, no crash reporter in MVP.

---

## 14. Out of Scope (Deferred)

| Item | Phase | Reason |
|------|-------|--------|
| GameKit leaderboards | 2 | Adds Apple-side ops; nice-to-have, not core |
| Push notifications (daily reminder) | 2 | Requires APNs config; deferable |
| Additional locales (ja, zh, …) | 2 | Add as adoption justifies |
| Themes / skins | 2 | Visual polish, not core |
| Deadlock detection (auto end) | 2 | Timer always ends round anyway |
| Multi-difficulty boards | 2 | Validate single-difficulty resonance first |
| Web companion | 3 | Native iOS is the defined target |
| Backend / cross-device sync | 3 | Explicitly rejected for MVP scope |

---

## 15. Hard Constraints (CLAUDE.md material)

- iOS deployment target: **17.0** (SwiftData requirement)
- Daily reset zone: **Asia/Seoul** (UTC+9). Not user-local.
- Solver: **anytime, cancellable, deterministic**. Never block UI.
- `GameCoordinator`: NOT `@MainActor` for data paths (matches kpop-heardle).
- No network calls in MVP. If added, must be optional.
- Imagery assets: generated via Codex workflow, prompts in
  `docs/asset-prompts.md`.

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

- Final app name (Tendle is placeholder — App Store listing TBD)
- Whether to expose haptic intensity slider (default on/off only for MVP)
- iPad landscape vs portrait first-class — MVP supports both, no special tuning
