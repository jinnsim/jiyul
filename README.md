# Jiyul

A calm daily 17×10 sum-to-10 puzzle for iOS. Personal/family build for
Jiyul; deployed under Bundle ID `com.jinnsim.Tendle`.

Same puzzle worldwide every day at Asia/Seoul midnight. Drag rectangles
that add to 10 to clear them. A deterministic in-app solver ("오늘의 봇
점수") races you on the same board.

100% offline. No accounts, no ads, no analytics, no tracking.

## Quick start

```bash
# First time (after `git clone`):
./ios/scripts/bootstrap.sh         # installs xcodegen if needed, regenerates project

# Open in Xcode:
open ios/Tendle.xcodeproj

# Or build + run tests from CLI:
xcodebuild -project ios/Tendle.xcodeproj \
  -scheme Tendle \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
  test
```

**The `ios/Tendle.xcodeproj/` is checked in** so a fresh clone can
build immediately without running `bootstrap.sh` first. The project
is regenerated deterministically from `ios/project.yml` whenever
`xcodegen` runs — only per-developer state under `xcuserdata/` is
gitignored.

## Layout

```
ios/
  project.yml                    # xcodegen source of truth
  Tendle.xcodeproj/              # generated, committed for clone-and-build
  Tendle/                        # SwiftUI sources (App/Models/Services/Views/Resources)
  TendleTests/                   # XCTest suite
  SolverSpike/                   # standalone Swift Package — solver gates
  scripts/
    bootstrap.sh                 # first-time setup
    build-archive.sh             # Release archive for device
    export-ipa.sh                # ExportOptions → .ipa
    import-illustrations.sh      # copy Layer-2 PNGs into Assets.xcassets
docs/
  superpowers/specs/             # design spec (v4)
  superpowers/plans/             # Phase 1–4 plans
  privacy.md                     # privacy policy (App Store)
  app-store-metadata.md          # listing metadata
  asset-prompts.md               # Codex image generation prompts
  handoff.md                     # development log
  spike-manifests/               # solver-gate evidence
  screenshots/                   # manual QA captures
assets/generated/                # source PNGs (also mirrored into Assets.xcassets)
.github/workflows/ci.yml         # xcodebuild test on push
```

## Architecture

SwiftUI + SwiftData, iOS 17.0+, universal (iPhone + iPad).
`GameCoordinator` (Observable, NOT `@MainActor`) drives a
`Task.detached(priority: .background)` running a deterministic beam-search
solver (`SolverProfile.mvpV1`, anytime emission via `SolverProgress`
`AsyncStream`). All state local to the device via SwiftData.

See `docs/superpowers/specs/2026-05-17-tendle-design.md` for the full
v4 design (Jiyul/Eunchan character layer, bilingual encouragement
system per spec §18, solver determinism contract per §5).

## Release

```bash
./ios/scripts/build-archive.sh   # → build/Tendle.xcarchive
# Edit ios/ExportOptions.plist <method> if needed.
./ios/scripts/export-ipa.sh      # → build/ipa/Jiyul.ipa
# Drag the .ipa into Transporter.app, or:
xcrun altool --upload-app -f build/ipa/Jiyul.ipa -t ios -u <APPLE_ID> -p <APP_PASSWORD>
```

Team ID `LQZYM2U744` wired in `project.yml`; automatic signing.

## License

Personal/family project. See `docs/privacy.md`.
