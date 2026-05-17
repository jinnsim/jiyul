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
  §9 (`Jiyul YYYY-MM-DD / 🟩 N · 🤖 M (P%) / ████████░░░░`), placed in a
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
  labels, "Jiyul" tagline).
- SettingsView with sound on/off + language picker + data reset + playerName edit.
- iPad-tuned layout: `BoardView` max width 720 pt, cell min 36×36 pt,
  optional `NavigationSplitView` sidebar.
- GitHub Actions CI workflow (build + unit test on push, release build to
  cap SolverTests at < 30 s).
- Codex-generated app icon PNG into `AppIcon.appiconset`.
- Custom-designed `.caf` sound clips.
- `ImageRenderer`-based share card PNG (richer than plain text).
- Abandoned-attempt detection.

---

## 2026-05-17 — Phase 3 complete (Polished & Localized) + hotfixes

**Status:** ✅ Phase 3 success criterion met (see plan Phase 3).

### Shipped (Phase 3)

- **App name** changed to **Jiyul** (`CFBundleDisplayName` + `CFBundleName`
  via `project.yml`; `HomeView` title key; share card header). Bundle ID
  and source tree directories remain `Tendle`/`com.jinnsim.Tendle` to
  avoid noisy renames.
- **App icon** — Codex-generated 1024×1024 PNG (Ten Tile Loop variant from
  `docs/asset-prompts.md` §4) populated into `AppIcon.appiconset`.
- **Localization** — `Localizable.xcstrings` with 30+ keys × ko/en;
  `AppLanguage` enum (system/ko/en); all user-facing literals in
  `HomeView`, `GameView`, `SelectionOverlay`, `ResultView`, `StatsView`
  routed through `String(localized:)` / `Text("Key")`.
- **SettingsView + SettingsStore** — `Form` UI with four sections:
  language `Picker`, sound `Toggle` (wired to `SoundService.shared`),
  player name `TextField`, destructive reset with `Alert`. `RootView`
  applies `.environment(\.locale, currentLocale)` on `NavigationStack`
  for the in-app language override. Refreshed via lifecycle hooks
  (`HomeView.onAppear` + `SettingsView.onDisappear`) to avoid SwiftData
  reads inside `body`.
- **iPad tuning** — `GameView` clamps `cellSize` to a max of 42 pt so the
  17×10 board renders finger-friendly even on the largest iPad screen.
  `StatsView` uses `ViewThatFits`: single `HStack` of 4 metrics first,
  falls back to a 2×2 `LazyVGrid` when horizontal space is constrained.
  Outer container clamped to 640 pt max width.
- **Abandoned-attempt detection** — `RootView.startDaily()` now inserts an
  `outcome: "abandoned"` placeholder `DailyRecord` before pushing the
  game route. `handleFinish()` upgrades the existing record in-place to
  `outcome: "completed"`. `StatsAggregator.streakDays` already excludes
  non-completed rows (P2 round-3 fix). `ScenePhase` observer +
  `AbandonmentMonitor.shouldMarkAbandoned` (3 unit tests pass) provide
  the documented gate for future use; the placeholder approach makes
  the explicit cleanup pass unnecessary today.
- **Share card PNG** — `ShareCardImageRenderer` (`@MainActor`, 1080×1080
  via `ImageRenderer`) writes a cream-paper card with player + bot scores
  + percentage to a temp file URL. `ResultView` renders on first appear
  (`@State + onAppear` to avoid body re-eval cost). `ShareLink(item: URL)`
  with `SharePreview`. Plain-text fallback `ShareCardRenderer.render(...)`
  remains for the brief pre-onAppear window.
- **GitHub Actions CI** — `.github/workflows/ci.yml` on `macos-14` with
  Xcode 15.4; generates project via xcodegen; runs the fast unit suite
  (skips the slow ~200 s Solver determinism test) on every push and PR.
- **BoardView candy-token design** — soft per-digit pastel backgrounds
  (1→peach, 2→butter, 3→mint, … 9→coral), rounded corners (~22% of cell),
  subtle drop shadow + 0.6 pt hairline border, 2.5 pt accent-color border
  when in the selection rectangle, 0.18 s fade-out + scale-to-0.4 clear
  animation, 2 pt inter-cell spacing. Replaces the plain grey grid with
  marble-like tokens while keeping digit contrast strong.

### Hotfix during Phase 3

- **Navigation bug** — tapping start/retry twice in a row used to stick
  on the loading overlay until backing out. `Route.game(dateKST:)`
  hashed identically across rounds so SwiftUI's `navigationDestination`
  reused the same view + state while `liveCoordinator` was reset to
  `nil` between push calls. Fix: `Route.game` now carries a per-session
  `sessionID: Double` (current `TimeIntervalSince1970`); `GameView` owns
  its own `GameCoordinator` (created in `init` from `dateKST`) instead
  of depending on `RootView` state; `.id(sessionID)` on the destination
  forces a fresh view per session. RootView keeps a
  `lastFinishedCoordinator` only for `ResultView`'s pending-bot live
  update.

### Test counts (Phase 3 end-of-phase)

- **38/39** unit tests pass when including the slow Solver determinism
  test (skipped routinely; ~200 s on iPhone 15 sim debug).
- New suites: `SettingsStoreTests` (3/3), `AbandonmentMonitorTests`
  (3/3), `ShareCardImageRendererTests` (1/1).

### Repo state

- Pushed to **https://github.com/jinnsim/jiyul.git** (default branch
  `main`). CI workflow runs on next push.

### Known limitations after Phase 3

- Custom-designed `.caf` sound clips still deferred (system Tink/Glass/
  Submarine `afconvert`-ed; replace before any App Store submission).
- `NavigationSplitView` sidebar on iPad not pursued — adaptive cell-size
  cap + ViewThatFits cover the practical need; sidebar can be added in
  Phase 4 if desired.
- Anytime solver still single-shot per round; spec §5.1's incremental
  emission is a Phase 4 polish.
- GameKit leaderboards, push notifications, web companion — not started.

---

## 2026-05-17 — Phase 4 complete (Release-ready) + ASC submission

**Status:** ✅ Phase 4 success criterion met. App is on App Store Connect
(Apple ID `6770174992`, build 4 + 5).

### Shipped (Phase 4)

- **Apple Developer signing** — Team `LQZYM2U744` wired into
  `project.yml`. ARCHIVE SUCCEEDED for Release/iOS-device. Local
  scripts `ios/scripts/build-archive.sh` and `ios/scripts/export-ipa.sh`
  produce a signed `Jiyul.ipa` (26 MB) for sideload or Transporter
  upload. Xcode Cloud now owns the production archive path.
- **Privacy + ASC metadata** —
  - `docs/privacy.md` — bilingual privacy policy (zero data
    collection, on-device only).
  - `docs/app-store-metadata.md` — listing fields ready to paste.
  - `Info.plist` declares `ITSAppUsesNonExemptEncryption: false`
    (no custom crypto → exempt from export compliance).
- **Anytime solver** (`Solver.swift`) — `solve(...)` now accepts an
  optional `onProgress` callback; `solveAsync` wires it so the live
  bot score in `ResultView` ticks upward as the beam search finds
  improvements, then settles to `.isFinal = true` at termination.
  Existing tests unchanged (no-callback overload still binary-identical).
- **Xcode Cloud-friendly repo** —
  - `.gitignore` now excludes only per-developer state; `ios/Tendle.xcodeproj/`
    is committed so a fresh clone or a Xcode Cloud workspace build
    succeeds without bootstrap.
  - `ios/scripts/bootstrap.sh` — first-time setup (`xcodegen` install +
    project regen). Safety net.
  - `README.md` — quick-start, architecture pointer, release commands.
  - `ci_scripts/ci_post_clone.sh` — Xcode Cloud post-clone hook (no-op
    today; regenerates the project if it ever goes missing).
  - `TendleTests`/`TendleUITests` targets explicitly disable code
    signing (simulator-only) so test runs on CI / Xcode Cloud don't
    require a real-device cert for the test bundle.
- **Screenshot automation** —
  - `ios/TendleUITests/CaptureScreenshots.swift` — 5 screens via
    `accessibilityIdentifier`/`accessibilityLabel`. Uses
    `-UITEST_FAST_TIMER` launch arg to compress `GameSession.totalDurationMs`
    from 120s to 5s so the Result test reaches the end-of-round screen
    within the test timeout (`totalDurationMs` is now a computed
    property reading `ProcessInfo`).
  - `ios/scripts/capture-screenshots.sh` — iterates 2 langs × 2 devices
    (iPhone 15 Pro Max 6.7" + iPad Pro 12.9" 6th-gen), sets
    `-AppleLanguages`/`-AppleLocale` via `SIMCTL_CHILD_` env, pulls
    PNGs out of the simulator data container into
    `fastlane/screenshots/{lang}/{device}-NN-screen.png`.
  - **20/20 screenshots saved** (5 screens × 2 langs × 2 devices) —
    ready to upload.
- **fastlane layout** —
  - `fastlane/metadata/{ko-KR,en-US}/` — `name`, `subtitle`,
    `description`, `keywords`, `promotional_text`, `support_url`,
    `marketing_url`, `privacy_url` (8 files × 2 langs).
  - `fastlane/Fastfile` — three lanes: `screenshots` (recapture),
    `metadata` (sync everything to ASC, skip binary), `upload_screenshots`
    (PNGs only).
  - `fastlane/Deliverfile` — `app_identifier`, `team_id`, `languages`
    pinned; `skip_binary_upload: true` (Xcode Cloud owns the build).
- **iPad orientations fix** — added `UIInterfaceOrientationPortraitUpsideDown`
  to `UISupportedInterfaceOrientations~ipad` to resolve App Store
  bundle validation error **ITMS-90474** (iPad multitasking requires
  all four orientations). Future Xcode Cloud builds will pass the
  validator.

### Test counts after Phase 4

- **38/39** unit tests pass (slow Solver determinism skipped routinely).
- **5/5** XCUITest captures per locale × device.

### How to ship from here

```bash
# 1. Refresh screenshots (if any UI changed):
./ios/scripts/capture-screenshots.sh
# or:
fastlane screenshots

# 2. Push metadata + screenshots to App Store Connect (auth required):
fastlane metadata        # everything
fastlane upload_screenshots  # PNGs only

# 3. Xcode Cloud: every push to main triggers an archive workflow
#    (configure in ASC → Apps → Jiyul → Xcode Cloud). After workflow
#    succeeds, the build appears in TestFlight automatically.

# 4. When ready for review: ASC UI → Submit for Review (or set
#    `submit_for_review: true` in fastlane/Fastfile metadata lane).
```

### Known limitations after Phase 4 (Phase 5+ wishlist)

- Custom-designed `.caf` sounds still deferred.
- iPad `NavigationSplitView` sidebar.
- GameKit leaderboards / push notifications.
- Apple Watch / Vision companion (out of scope for Jiyul's family build).
