import XCTest
@testable import PointGuardCore

/// The single most important correctness requirement in this app: a null
/// `mergeTreeCheckedAt` (backstop never ran) must never look the same as a
/// present one (backstop ran, found nothing).
final class MergeTreeCheckStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testNullProducesNotYetCheckedCase() {
        let state = MergeTreeCheckState(mergeTreeCheckedAt: nil)
        XCTAssertEqual(state, .notYetChecked)
    }

    func testPresentTimestampProducesCheckedCase() {
        let state = MergeTreeCheckState(mergeTreeCheckedAt: 1_699_999_000_000)
        XCTAssertEqual(state, .checked(unixMillis: 1_699_999_000_000))
    }

    func testNullAndPresentProduceDifferentDisplayStates() {
        let notYetChecked = MergeTreeCheckState(mergeTreeCheckedAt: nil)
        let checked = MergeTreeCheckState(mergeTreeCheckedAt: 1_699_999_000_000)

        XCTAssertNotEqual(notYetChecked, checked)
        XCTAssertNotEqual(notYetChecked.displayText(now: now), checked.displayText(now: now))
    }

    func testNotYetCheckedText() {
        let state = MergeTreeCheckState(mergeTreeCheckedAt: nil)
        XCTAssertEqual(state.displayText(now: now), "Not yet checked")
    }

    func testCheckedTextNamesItAsCheckedNotAsAllClear() {
        let state = MergeTreeCheckState(mergeTreeCheckedAt: 1_699_999_000_000)
        let text = state.displayText(now: now)
        XCTAssertTrue(text.hasPrefix("Last checked"))
        XCTAssertFalse(text.lowercased().contains("all clear"))
        XCTAssertFalse(text.lowercased().contains("no conflict"))
    }
}
