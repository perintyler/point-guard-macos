import XCTest
@testable import PointGuardCore

final class SessionRowViewModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeSession(
        repo: String? = "/Users/tyler/repos/barry/.git",
        branch: String? = nil,
        lastActivityAt: Int64? = 1_699_999_000_000,
        status: String = "ok",
        flaggedReason: String? = nil,
        mergeTreeCheckedAt: Int64? = nil
    ) -> BookSession {
        BookSession(
            sessionId: "session-1",
            repo: repo,
            branch: branch,
            worktree: repo,
            lastActivityAt: lastActivityAt,
            status: status,
            flaggedReason: flaggedReason,
            mergeTreeCheckedAt: mergeTreeCheckedAt,
            updatedAt: 1_700_000_000_000
        )
    }

    func testNoActivityYetWhenLastActivityAtIsNil() {
        let row = SessionRowViewModel(session: makeSession(lastActivityAt: nil), now: now)
        XCTAssertEqual(row.lastActivityText, "No activity yet")
    }

    func testRelativeActivityTextWhenPresent() {
        let row = SessionRowViewModel(session: makeSession(lastActivityAt: 1_699_999_000_000), now: now)
        XCTAssertNotEqual(row.lastActivityText, "No activity yet")
    }

    func testNilRepoProducesNilRepoName() {
        let row = SessionRowViewModel(session: makeSession(repo: nil), now: now)
        XCTAssertNil(row.repoName)
    }

    func testRepoNameStripsGitSuffix() {
        let row = SessionRowViewModel(session: makeSession(repo: "/Users/tyler/repos/barry/.git"), now: now)
        XCTAssertEqual(row.repoName, "barry")
    }

    func testNilBranchIsAbsentNotAPlaceholder() {
        let row = SessionRowViewModel(session: makeSession(branch: nil), now: now)
        XCTAssertNil(row.branch)
    }

    func testOkStatusHasNoFlaggedReason() {
        let row = SessionRowViewModel(session: makeSession(status: "ok", flaggedReason: nil), now: now)
        XCTAssertEqual(row.status, .ok)
        XCTAssertNil(row.flaggedReason)
    }

    func testStuckStatusCarriesItsFlaggedReason() {
        let row = SessionRowViewModel(
            session: makeSession(status: "stuck", flaggedReason: "no output for 20 minutes"),
            now: now
        )
        XCTAssertEqual(row.status, .stuck)
        XCTAssertEqual(row.flaggedReason, "no output for 20 minutes")
    }

    func testNullVsPresentMergeTreeCheckedAtProduceDifferentRowText() {
        let neverChecked = SessionRowViewModel(session: makeSession(mergeTreeCheckedAt: nil), now: now)
        let checked = SessionRowViewModel(session: makeSession(mergeTreeCheckedAt: 1_699_999_500_000), now: now)
        XCTAssertNotEqual(neverChecked.mergeTreeCheckText, checked.mergeTreeCheckText)
    }
}
