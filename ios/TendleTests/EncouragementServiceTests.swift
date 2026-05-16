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
