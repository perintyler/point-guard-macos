import Foundation
import PointGuardCore
import XCTest

/// Decodes a real, captured `GET /debrief` payload against `PointGuardCore`'s
/// hand-written models, the same way `ContractDecodeTests` pins `/book`.
final class DebriefDecodeTests: XCTestCase {
    private let decoder = JSONDecoder()

    /// Captured from the live point-guard service on 2026-09-15 and trimmed to
    /// two real sessions chosen for CONTRAST: the first has a present
    /// `mergeTreeCheckedAt` and four attached plans; the second has
    /// `mergeTreeCheckedAt` null and no plans. Both states are real, and the
    /// difference between them is the one this client must never collapse.
    ///
    /// The narrative in it is genuinely stale (its `inputsHash` differs from
    /// the debrief's) -- also captured, not contrived. On a busy machine the
    /// team changes faster than the five-minute narrative tick, so stale is
    /// the common case rather than an edge one.
    private static let realDebriefFixture = #"""
    {"debrief":{"generatedAt":1789524492841,"counts":{"total":31,"working":4,"idle":27,"stuck":0,"conflicted":0},"sessions":[{"sessionId":"zkwFFBjLNzbn_D0F1qFQ8","name":"barry harness architecture research","nameSource":"metadata","repo":"/Users/tyler/repos/barry/.git","repoName":"barry","branch":null,"worktree":"/Users/tyler/repos/barry","lifecycleStatus":"running","status":"ok","flaggedReason":null,"createdAt":1789017109594,"lastActivityAt":1789504864907,"aliveMs":507383247,"idleMs":19627934,"latestSummary":"### Done\n- Restarted point-guard service\n- Verified book endpoint returns sessions with correct repo\n- Created worktrees for pg-web and pg-macos\n- Checked barry-iphone's git setup\n- Confirmed iOS app strategy with Tyler\n- Initialized point-guard-iphone repo\n- Launched 3 async agents: web, macOS, iOS builds\n\n### What went right\n- Point-guard service restarted cleanly\n- Book endpoint returns session\u2026","filesTouched":0,"mergeTreeCheckedAt":1789524432587,"plans":[{"id":"plan_f7595db773bf","title":"Harness and coding bags, with inline trait bounds","status":"in-progress","progress":{"done":21,"total":35,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_f7595db773bf","match":"repo"},{"id":"plan_969cb17fc525","title":"Documentation audit follow-through","status":"in-progress","progress":{"done":30,"total":37,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_969cb17fc525","match":"repo"},{"id":"plan_c9f9741ac805","title":"Checks that cannot fail: the metrics defects left after the delivery fix","status":"draft","progress":{"done":0,"total":17,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_c9f9741ac805","match":"repo"},{"id":"plan_c872e43bcf84","title":"Audit leftovers: deletions and two CLI rulings","status":"draft","progress":{"done":0,"total":8,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_c872e43bcf84","match":"repo"}]},{"sessionId":"C1ZZJwd2BJ5zWT4LNGpaH","name":"session-bookkeeping","nameSource":"metadata","repo":"/Users/tyler/repos/bags/metrics/.git","repoName":"metrics","branch":null,"worktree":"/Users/tyler/repos/bags/metrics","lifecycleStatus":"running","status":"ok","flaggedReason":null,"createdAt":1789485824474,"lastActivityAt":1789524491245,"aliveMs":38668367,"idleMs":1596,"latestSummary":"### Done\n- Merged fix for `collector-silent` firing (commit `992eb19`)\n- Live check confirms all 10 collectors now show `firing: 0`\n\n### Learnings\n- The bug was a side effect of a previous change that split collectors into job series\n- `job` label caused alias shadowing in `src/rules.ts` (90 lines changed)\n\n### What went right\n- Live check confirmed fix in production\n- Clear commit message with co\u2026","filesTouched":0,"mergeTreeCheckedAt":null,"plans":[]}],"plans":[{"id":"plan_f7595db773bf","title":"Harness and coding bags, with inline trait bounds","status":"in-progress","progress":{"done":21,"total":35,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_f7595db773bf","match":"repo"},{"id":"plan_969cb17fc525","title":"Documentation audit follow-through","status":"in-progress","progress":{"done":30,"total":37,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_969cb17fc525","match":"repo"},{"id":"plan_c9f9741ac805","title":"Checks that cannot fail: the metrics defects left after the delivery fix","status":"draft","progress":{"done":0,"total":17,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_c9f9741ac805","match":"repo"},{"id":"plan_c872e43bcf84","title":"Audit leftovers: deletions and two CLI rulings","status":"draft","progress":{"done":0,"total":8,"of":"spec"},"url":"http://127.0.0.1:4880/#plan_c872e43bcf84","match":"repo"}],"trouble":[],"narrative":{"text":"There are 39 total sessions, with 4 active in the last 10 minutes, 35 quiet, 0 stuck, and 0 conflicted. The listed sessions include names such as barry harness architecture research, tunnel-port-mapping, scout-api-backfill-plan-verification, session-bookkeeping, and several short ID-like session names. No troubles are recorded, and the open plans mention Harness and coding bags with inline trait bounds, Documentation audit follow-through, checks that cannot fail in the metrics defects left after the delivery fix, and audit leftovers covering deletions and two CLI rulings.","model":"gpt-5.4-mini","generatedAt":1789524435030,"inputsHash":"888aed908ed96695"},"inputsHash":"82f4ffe00c1272f0","sources":{"sessions":{"lastSucceededAt":1789524492841,"lastError":null},"plans":{"lastSucceededAt":1789524492841,"lastError":null}}}}
    """#

    private func decodeFixture() throws -> Debrief {
        try decoder.decode(DebriefResponse.self, from: Data(Self.realDebriefFixture.utf8)).debrief
    }

    func testDecodesRealCapturedPayload() throws {
        let debrief = try decodeFixture()

        XCTAssertEqual(debrief.counts.total, 31)
        XCTAssertEqual(debrief.counts.stuck, 0, "a measured zero, not a missing value")
        XCTAssertEqual(debrief.sessions.count, 2)
        XCTAssertFalse(debrief.inputsHash.isEmpty)
    }

    func testMergeTreeNullAndPresentAreBothRepresented() throws {
        let debrief = try decodeFixture()

        XCTAssertNotNil(
            debrief.sessions[0].mergeTreeCheckedAt,
            "first session's merge-tree backstop HAS run"
        )
        XCTAssertNil(
            debrief.sessions[1].mergeTreeCheckedAt,
            "second session's merge-tree backstop has never run -- not 'ran and found nothing'"
        )
    }

    func testMergeTreeStateKeepsTheTwoCasesApart() throws {
        let debrief = try decodeFixture()

        XCTAssertEqual(
            MergeTreeCheckState(mergeTreeCheckedAt: debrief.sessions[1].mergeTreeCheckedAt),
            .notYetChecked,
            "a never-checked session must not present as checked-and-clean"
        )
        if case .notYetChecked = MergeTreeCheckState(mergeTreeCheckedAt: debrief.sessions[0].mergeTreeCheckedAt) {
            XCTFail("a checked session must not present as never-checked")
        }
    }

    func testZeroCountsSurviveDecoding() throws {
        let debrief = try decodeFixture()

        // 0 stuck and 0 conflicted are the values a reader is most likely to
        // be checking. If they ever decoded as nil-then-defaulted, a real
        // problem could render identically to a healthy team.
        XCTAssertEqual(debrief.counts.stuck + debrief.counts.conflicted, 0)
        XCTAssertEqual(
            debrief.counts.working + debrief.counts.idle + debrief.counts.stuck + debrief.counts.conflicted,
            debrief.counts.total,
            "the four buckets must account for every session"
        )
    }

    func testPlanLinksCarryTheirMatchQualifier() throws {
        let debrief = try decodeFixture()
        let plans = debrief.sessions[0].plans

        XCTAssertFalse(plans.isEmpty, "the captured session really does have plans attached")
        for plan in plans {
            XCTAssertEqual(
                PlanMatch(rawValue: plan.match),
                .repo,
                "repo-matched plans must not claim the session is working on them"
            )
            XCTAssertEqual(PlanMatch(rawValue: plan.match).qualifier, "in this repo")
        }
    }

    func testSecondSessionHasNoPlansAndThatIsReal() throws {
        let debrief = try decodeFixture()

        XCTAssertTrue(debrief.sessions[1].plans.isEmpty)
        XCTAssertTrue(
            SourceHealth(status: debrief.sources.plans).emptyMeansNone,
            "the plans source answered, so empty really means none -- not 'could not ask'"
        )
    }

    func testCapturedNarrativeIsStaleAndSaysSo() throws {
        let debrief = try decodeFixture()
        let state = NarrativeState(debrief: debrief)

        XCTAssertTrue(state.isStale, "captured narrative was written from earlier inputs")
        XCTAssertNotNil(state.text, "a stale narrative is still shown -- it was true recently")
        XCTAssertTrue(
            state.attribution()?.contains("describes an earlier state") == true,
            "staleness must be visible in the attribution, not silently dropped"
        )
    }
}
