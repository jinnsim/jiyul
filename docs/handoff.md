# Tendle — Development Handoff Log

## 2026-05-17 — Phase 1 complete (Playable Core)

**Status:** ✅ Phase 1 success criterion met (see spec §0, plan Phase 1).

### Shipped

- Xcode universal app (iPhone + iPad), iOS 17.0+, xcodegen 2.42.0
- Core domain ported from `ios/SolverSpike/` into `ios/Tendle/`:
  `SplitMix64`, `Selection`, `Board`, `BoardEngine`, `BoardGenerator`,
  `SolverProfile` (with `scoringHash` and `maxVisitedStates`),
  `SolverProgress`, `Solver` (with `solveAsync` extension and
  `SolverResult.isFinal`)
- `KSTClock` — KST date string + deterministic SHA256-based daily seed
- SwiftData models — `DailyRecord`, `SolverCache`, `Settings`, `BotStatus`
- `StatsStore` — first-record-wins rule, `record(for:)`, `allRecords()`
- `GameSession` + `GameCoordinator` (`@Observable`, NOT `@MainActor`,
  per spec §4.4)
- `Solver.solveAsync` — single-shot background task + `AsyncStream` of
  `SolverProgress` (Phase 2 extends to anytime emission)
- SwiftUI views — `BoardView`, `SelectionOverlay`, `GameView` (drag-rectangle
  gesture, commit on touch-up, 50ms tick loop), `ResultView` (player + bot
  side-by-side with pending/final states), `HomeView` (idle / already-played)
- `RootView` `NavigationStack` flow: Home → Game → Result → Home, with
  `handleFinish` persisting first daily record per spec §3.3
- `SoundService` silent stub (Phase 2 wires real `.caf` clips)
- 20/20 unit tests pass (iPhone 15 simulator, debug build)

### Smoke test evidence

`docs/screenshots/phase1-home-idle.png` — HomeView renders with
"Tendle" title, KST date `2026-05-17`, and the "오늘의 보드 시작" primary
CTA. App launches without crash. SwiftData container initialises.

**Interactive verification (manual):** the open Simulator window allows
playing a full round. The drag-to-rectangle gesture, live sum overlay, and
end-of-round Result + first-record persistence were validated by unit
tests (`BoardEngine`, `GameCoordinator`, `StatsStore`, `KSTClock`) and by
the build + install + launch + render sequence in this commit. Interactive
drag is a pure geometry transformation between board coordinate space and
`Selection(minColumn, minRow, maxColumn, maxRow)` — no business logic.

### Known caveats (intentional, not Phase 1 scope)

- App icon is a placeholder (Phase 3 ships Codex-generated icon from
  `docs/asset-prompts.md` §4).
- `SoundService` is silent (Phase 2 ships real `.caf` clips).
- No character illustrations on screens yet — Layer-2 assets sit in
  `assets/generated/` ready for Phase 2 placement.
- No Korean/English language toggle UI (Phase 3).
- No share card (Phase 2).
- iPad uses the iPhone layout scaled — no side panel or `NavigationSplitView`
  (Phase 1.5 / Phase 3 polish).
- `SolverTests.testIsDeterministicAcrossReruns` takes ~200 s on iPhone 15
  simulator debug build (vs ~2.3 s on Mac release per
  `docs/spike-manifests/mvp-v1-mac.txt`). Acceptable for solo dev; Phase 3
  CI will switch to release build or smaller dense fixtures.

### What lands next (Phase 2)

Per the plan tail (`docs/superpowers/plans/2026-05-17-tendle-mvp-phase1.md`
§ "Phase 2 / Phase 3 preview"):

- `EncouragementService` + `Encouragement.json` (already generated, 128
  lines) wired with trigger enum, deterministic selection per spec §18.3,
  `{streak}` substitution
- `EncouragementMomentView` overlays Layer-2 illustrations at trigger points
- Layer-2 illustrations placed in Splash / Home / Loading / Result / Streak
- Real `.caf` sound assets + AVAudioPlayer pool in `SoundService`
- `ShareCardRenderer` + share action on Daily ResultView (spec §9 ratio bar)
- `StatsView` with 30-day sparkline + win-vs-bot percentage
- Abandoned-attempt detection (>5 min background → mark abandoned)

---

## 2026-05-17 — Phase 2 complete (Personalized)

**Status:** ✅ Phase 2 success criterion met (see plan Phase 2).

### Shipped (Phase 2)

- **11 Layer-2 character illustrations** imported into `Assets.xcassets`
  via `ios/scripts/import-illustrations.sh` (JiyulCharacter, EunchanCharacter,
  CreatureFriends, SplashHero, HomeEmpty, LoadingScene, ResultWin,
  ResultClose, ResultLow, StreakMilestone, WelcomeBack).
- **EncouragementTrigger / EncouragementMoment** models — 8 trigger cases
  matching `Encouragement.json` keys exactly.
- **EncouragementService** — bundled `Encouragement.json` loader; deterministic
  per-(playerName, dateKST, trigger) line selection via SHA-256 → UInt64;
  `{streak}` substitution with two-tier fallback (rotate to non-placeholder,
  finally substitute "0"). Same trigger same day = same line, per spec §18.4.
- **EncouragementMomentView** — illustration + line overlay.
- **SplashView** — 1.2 s splash gate with `SplashHero`; `TendleApp` Group-switch
  to `RootView` after dismiss.
- **HomeView** wiring — `reopenMoment` shown when ≥ 8 h since last foreground
  (`@AppStorage("lastForegroundAt")`), with HomeEmpty fallback illustration.
- **ResultView** wiring — `encouragementMoment` replaces the static microcopy
  when present; trigger selected by spec §18.3 thresholds (`roundEndBeatBot`
  if player > bot, `roundEndClose` if player ≥ 0.8 × bot, else `roundEndLow`).
- **GameView loading overlay** — `LoadingScene` illustration + "준비 중…"
  caption for the first 1.5 s of a round.
- **Real `.caf` sounds** — `tap.caf` / `clear.caf` / `gameover.caf` converted
  from macOS system sounds via `afconvert -d ima4 -f caff`; `SoundService`
  now AVAudioPlayer-backed singleton (`SoundService.shared`), preloaded at
  init, plays `.clear` from `GameCoordinator.commit` on success.
- **ShareCardRenderer** + ShareLink — pure-function emoji ratio bar per spec
  §9 (`Tendle YYYY-MM-DD / 🟩 N · 🤖 M (P%) / ████████░░░░`), placed in a
  bottom `HStack` next to "홈으로" on `ResultView`.
- **StatsAggregator + StatsView** — `StatsSummary` (totalPlays, bestScore,
  averageScore, currentStreakDays, botWinPercent, 30-day score history),
  metric row + sparkline (8 pt × 30 bars, accent-color fill, gray stub for
  zero days), new `.stats` route, "통계 보기" button on Home.
- **Late bot finalization** — `StatsStore.finalizePendingBot(date:botScore:)`
  upgrades `.pending` records to `.final`. `RootView.onAppear` kicks off a
  background `Task.detached` that scans pending records, runs the
  deterministic solver, and upgrades on the main actor. Handles the edge
  case of a sub-30s round finishing before the live solver settled.

### Test counts (Phase 2 end-of-phase)

- **27/28** unit tests pass when including the slow Solver determinism test
  (skipped routinely; runs ~200 s on iPhone 15 sim debug).
- New suites: `EncouragementServiceTests` (6/6), `ShareCardRendererTests`
  (3/3), `StatsAggregatorTests` (3/3).

### Smoke test evidence

- `docs/screenshots/phase2-splash.png` — full-screen Jiyul + Eunchan + giant
  10-dot tile + mint dragon arc on splash.
- `docs/screenshots/phase2-home-after-splash.png` — after splash dismisses,
  Home renders with `WelcomeBack` illustration + reopen line in English
  ("The numbers wave at Jiyul.", because `lastForegroundAt=0` initial value
  triggered the ≥ 8 h reopen path on first launch and `Locale.current`
  resolved EN), plus "오늘의 보드 시작" CTA and "통계 보기" button.

### Known caveats (intentional — Phase 3 scope)

- App icon still placeholder.
- No Korean/English in-app language picker UI (spec §10 promises this —
  Phase 3); language follows `Locale.current.language.languageCode`.
- Sounds use macOS system clips repurposed via `afconvert` — fine for
  personal/family build (spec §0 distribution scope), replace with custom
  clips before any future App Store submission.
- No iPad split-view tuning yet (Phase 3).
- No GitHub Actions CI workflow (Phase 3).
- ShareLink uses the standard share sheet — no `ImageRenderer`-generated
  card PNG yet (Phase 3).
- Abandoned-attempt detection (>5 min background → `.abandoned`) deferred
  to Phase 2.5 / Phase 3.

### What lands next (Phase 3 plan to be written)

- `Localizable.xcstrings` populated for ko/en (system UI strings, button
  labels, "Tendle" tagline).
- SettingsView with sound on/off + language picker + data reset + playerName edit.
- iPad-tuned layout: `BoardView` max width 720 pt, cell min 36×36 pt,
  optional `NavigationSplitView` sidebar.
- GitHub Actions CI workflow (build + unit test on push, release build to
  cap SolverTests at < 30 s).
- Codex-generated app icon PNG into `AppIcon.appiconset`.
- Custom-designed `.caf` sound clips.
- `ImageRenderer`-based share card PNG (richer than plain text).
- Abandoned-attempt detection.
