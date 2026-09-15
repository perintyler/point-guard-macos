import XCTest
@testable import PointGuardCore

final class RelativeTimeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testSecondsAgo() {
        let millis = Int64((now.timeIntervalSince1970 - 30) * 1_000)
        let text = RelativeTime.format(unixMillis: millis, now: now)
        XCTAssertTrue(text.contains("second"), "expected a seconds-scale string, got: \(text)")
    }

    func testMinutesAgo() {
        let millis = Int64((now.timeIntervalSince1970 - 5 * 60) * 1_000)
        let text = RelativeTime.format(unixMillis: millis, now: now)
        XCTAssertTrue(text.contains("minute"), "expected a minutes-scale string, got: \(text)")
    }

    func testHoursAgo() {
        let millis = Int64((now.timeIntervalSince1970 - 3 * 3_600) * 1_000)
        let text = RelativeTime.format(unixMillis: millis, now: now)
        XCTAssertTrue(text.contains("hour"), "expected an hours-scale string, got: \(text)")
    }

    func testDaysAgo() {
        let millis = Int64((now.timeIntervalSince1970 - 2 * 86_400) * 1_000)
        let text = RelativeTime.format(unixMillis: millis, now: now)
        XCTAssertTrue(text.contains("day"), "expected a days-scale string, got: \(text)")
    }
}
