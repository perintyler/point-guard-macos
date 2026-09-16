import XCTest
@testable import PointGuardCore

/// A repo match is a WEAK signal: a repo with fourteen sessions attaches the
/// same plan to all fourteen. These pin the wording so a future "improvement"
/// cannot quietly upgrade it into a claim of ownership.
final class PlanMatchTests: XCTestCase {
    func testRepoMatchNeverClaimsOwnership() {
        let qualifier = PlanMatch(rawValue: "repo").qualifier

        XCTAssertEqual(qualifier, "in this repo")
        XCTAssertFalse(qualifier.lowercased().contains("working"))
        XCTAssertFalse(qualifier.lowercased().contains("owns"))
    }

    func testSessionMatchIsDistinctFromRepo() {
        XCTAssertNotEqual(PlanMatch(rawValue: "session"), PlanMatch(rawValue: "repo"))
        XCTAssertEqual(PlanMatch(rawValue: "session").qualifier, "this session")
    }

    func testUnknownValueIsShownRatherThanGuessed() {
        // Mapping an unrecognized match onto the nearest known one would state
        // something the server did not say.
        XCTAssertEqual(PlanMatch(rawValue: "milestone"), .unknown("milestone"))
        XCTAssertEqual(PlanMatch(rawValue: "milestone").qualifier, "milestone")
    }
}
