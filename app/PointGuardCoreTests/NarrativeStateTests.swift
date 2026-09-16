import XCTest
@testable import PointGuardCore

/// `.notGenerated`, `.current` and `.stale` are three separate cases for the
/// same reason `MergeTreeCheckState` has two: a view that cannot tell them
/// apart will show an empty box for "nothing was written" and let the reader
/// conclude "nothing to report".
final class NarrativeStateTests: XCTestCase {
    private func narrative(hash: String, generatedAt: Int64 = 1_000) -> DebriefNarrative {
        DebriefNarrative(text: "Four sessions are quiet.", model: "gpt-5.4-mini", generatedAt: generatedAt, inputsHash: hash)
    }

    private func debrief(narrative: DebriefNarrative?, inputsHash: String) -> Debrief {
        Debrief(
            generatedAt: 2_000,
            counts: DebriefCounts(total: 0, working: 0, idle: 0, stuck: 0, conflicted: 0),
            sessions: [], plans: [], trouble: [],
            narrative: narrative, inputsHash: inputsHash,
            sources: DebriefSources(
                sessions: DebriefSourceStatus(lastSucceededAt: 1, lastError: nil),
                plans: DebriefSourceStatus(lastSucceededAt: 1, lastError: nil)
            )
        )
    }

    func testNoNarrativeIsNotGenerated() {
        let state = NarrativeState(debrief: debrief(narrative: nil, inputsHash: "abc"))

        XCTAssertEqual(state, .notGenerated)
        XCTAssertNil(state.text, "must not invent a sentence where none was written")
        XCTAssertNil(state.attribution(), "nothing to attribute")
    }

    func testMatchingHashIsCurrent() {
        let state = NarrativeState(debrief: debrief(narrative: narrative(hash: "abc"), inputsHash: "abc"))

        XCTAssertFalse(state.isStale)
        XCTAssertEqual(state.text, "Four sessions are quiet.")
        XCTAssertEqual(state.attribution()?.contains("describes an earlier state"), false)
    }

    func testDifferingHashIsStaleButStillShown() {
        let state = NarrativeState(debrief: debrief(narrative: narrative(hash: "old"), inputsHash: "new"))

        XCTAssertTrue(state.isStale)
        XCTAssertEqual(state.text, "Four sessions are quiet.", "a stale narrative is still worth showing")
        XCTAssertTrue(state.attribution()?.contains("describes an earlier state") == true)
    }

    func testAttributionAlwaysNamesTheModel() {
        // Prose about measurements must be attributable, or a reader cannot
        // tell it apart from the measurements themselves.
        let current = NarrativeState(debrief: debrief(narrative: narrative(hash: "x"), inputsHash: "x"))
        let stale = NarrativeState(debrief: debrief(narrative: narrative(hash: "x"), inputsHash: "y"))

        XCTAssertTrue(current.attribution()?.contains("gpt-5.4-mini") == true)
        XCTAssertTrue(stale.attribution()?.contains("gpt-5.4-mini") == true)
    }
}
