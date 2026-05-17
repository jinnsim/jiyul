import XCTest

/// Runs Jiyul through the five screens we want for App Store Connect and
/// writes a PNG per screen to the directory specified by the
/// `-SCREENSHOT_DIR` launch argument (or `$TMPDIR/jiyul-screenshots` if
/// absent). The capture script in `ios/scripts/capture-screenshots.sh`
/// invokes this test once per (locale × device) combination, with
/// `-AppleLanguages`/`-AppleLocale` and a per-run `-SCREENSHOT_DIR`.
final class CaptureScreenshots: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test01_Home() throws {
        let app = launch()
        // Splash auto-dismisses after 1.2s.
        sleep(3)
        capture(app, name: "01-home")
    }

    func test02_Game() throws {
        let app = launch()
        sleep(5)
        // Locale-independent identifier set in HomeView.
        let startButton = app.buttons["start-button"]
        if startButton.waitForExistence(timeout: 15) {
            startButton.tap()
        } else if !tap(app, oneOf: ["오늘의 보드 시작", "Start Today's Board",
                                    "다시 도전", "Play again"]) {
            XCTFail("Could not find Start CTA")
        }
        // Loading overlay shows for ~1.5s; capture once we're past it.
        sleep(2)
        capture(app, name: "02-game")
    }

    func test03_Result() throws {
        let app = launch(extraArgs: ["-UITEST_FAST_TIMER"])
        sleep(3)
        let startButton = app.buttons["start-button"]
        if startButton.waitForExistence(timeout: 6) {
            startButton.tap()
        } else if !tap(app, oneOf: ["오늘의 보드 시작", "Start Today's Board",
                                    "다시 도전", "Play again"]) {
            XCTFail("Could not find Start/Retry CTA")
            return
        }
        // With fast timer (5s) plus loading 1.5s plus settle, give 9s buffer.
        sleep(9)
        capture(app, name: "03-result")
    }

    func test04_Stats() throws {
        let app = launch()
        sleep(3)
        let statsButton = app.buttons["stats-button"]
        if statsButton.waitForExistence(timeout: 6) {
            statsButton.tap()
        } else if !tap(app, oneOf: ["통계 보기", "Stats"]) {
            XCTFail("Could not find Stats CTA")
        }
        sleep(2)
        capture(app, name: "04-stats")
    }

    func test05_Settings() throws {
        let app = launch()
        sleep(3)
        // Gear button has accessibilityLabel "Settings" — see HomeView.
        let gear = app.buttons["Settings"]
        if gear.waitForExistence(timeout: 2) {
            gear.tap()
        } else {
            XCTFail("Could not find Settings gear button")
            return
        }
        sleep(2)
        capture(app, name: "05-settings")
    }

    // MARK: - Helpers

    private func launch(extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += extraArgs
        // Locale + screenshot dir come from the test runner.
        if let lang = ProcessInfo.processInfo.environment["JIYUL_TEST_LANG"] {
            app.launchArguments += ["-AppleLanguages", "(\(lang))"]
            app.launchArguments += ["-AppleLocale", lang == "ko" ? "ko_KR" : "en_US"]
        }
        app.launch()
        return app
    }

    /// Returns true if any of the labels resolved and was tapped.
    /// Polls up to `timeout` total across all labels.
    private func tap(_ app: XCUIApplication, oneOf labels: [String], timeout: TimeInterval = 8) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for label in labels {
                let button = app.buttons[label]
                if button.exists, button.isHittable {
                    button.tap()
                    return true
                }
            }
            usleep(300_000) // 0.3s
        }
        return false
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        // Attach to .xcresult for Xcode Test Report.
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.lifetime = .keepAlways
        attachment.name = name
        add(attachment)
        // Also write to disk so capture-screenshots.sh can pick it up.
        let dir = ProcessInfo.processInfo.environment["JIYUL_SCREENSHOT_DIR"]
            ?? NSTemporaryDirectory().appending("jiyul-screenshots")
        try? FileManager.default.createDirectory(atPath: dir,
                                                  withIntermediateDirectories: true)
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: url)
    }
}
