import XCTest
@testable import PointGuardCore

final class SessionStatusTests: XCTestCase {
    func testKnownWireValues() {
        XCTAssertEqual(SessionStatus(wire: "ok"), .ok)
        XCTAssertEqual(SessionStatus(wire: "stuck"), .stuck)
        XCTAssertEqual(SessionStatus(wire: "conflicted"), .conflicted)
    }

    func testUnrecognizedWireValueBecomesUnknownNotACrash() {
        XCTAssertEqual(SessionStatus(wire: "weird"), .unknown("weird"))
    }

    func testLabels() {
        XCTAssertEqual(SessionStatus.ok.label, "OK")
        XCTAssertEqual(SessionStatus.stuck.label, "Stuck")
        XCTAssertEqual(SessionStatus.conflicted.label, "Conflicted")
        XCTAssertEqual(SessionStatus.unknown("weird").label, "Weird")
    }
}
