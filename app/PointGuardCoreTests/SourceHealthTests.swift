import XCTest
@testable import PointGuardCore

/// An empty list means different things depending on whether the source
/// answered. These pin that difference, because both render as "no rows" in
/// the data and only this type keeps them apart.
final class SourceHealthTests: XCTestCase {
    func testSucceededWithNoRowsMeansGenuinelyNone() {
        let health = SourceHealth(status: DebriefSourceStatus(lastSucceededAt: 100, lastError: nil))

        XCTAssertTrue(health.emptyMeansNone)
        XCTAssertNil(health.warning, "nothing is wrong, so nothing to warn about")
    }

    func testNeverReadMeansAnEmptyListIsUnknown() {
        let health = SourceHealth(status: DebriefSourceStatus(lastSucceededAt: nil, lastError: "connection refused"))

        XCTAssertEqual(health, .unavailable(error: "connection refused"))
        XCTAssertFalse(health.emptyMeansNone, "an empty list here is 'could not ask', not 'none'")
        XCTAssertNotNil(health.warning)
    }

    func testFailedAfterAnEarlierSuccessIsStaleNotEmpty() {
        let health = SourceHealth(status: DebriefSourceStatus(lastSucceededAt: 100, lastError: "timeout"))

        XCTAssertEqual(health, .stale(lastSucceededAt: 100, error: "timeout"))
        XCTAssertFalse(health.emptyMeansNone, "the rows on screen are real but old")
        XCTAssertTrue(health.warning?.contains("older data") == true)
    }
}
