import XCTest
@testable import PointGuardCore

final class RepoNameTests: XCTestCase {
    func testStripsTrailingGitDirectory() {
        XCTAssertEqual(RepoName.displayName(repo: "/Users/tyler/repos/barry/.git"), "barry")
    }

    func testStripsTrailingGitDirectoryWithTrailingSlash() {
        XCTAssertEqual(RepoName.displayName(repo: "/Users/tyler/repos/barry/.git/"), "barry")
    }

    func testPlainRepoRootWithNoGitSuffix() {
        XCTAssertEqual(RepoName.displayName(repo: "/Users/tyler/repos/bags/metrics"), "metrics")
    }

    func testNilRepoIsNilNotAPlaceholder() {
        XCTAssertNil(RepoName.displayName(repo: nil))
    }

    func testEmptyStringIsNil() {
        XCTAssertNil(RepoName.displayName(repo: ""))
    }
}
