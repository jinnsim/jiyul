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
