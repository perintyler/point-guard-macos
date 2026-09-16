import Foundation

/// Whether the debrief's prose overview exists, and whether it still
/// describes the current state.
///
/// Three cases, not an optional, for the same reason `MergeTreeCheckState`
/// has two: the absent case and the present-but-old case are different facts,
/// and a view that renders an empty box for the first has silently told the
/// reader "nothing to say" when the truth is "nothing was written".
///
/// `.notGenerated` is not a rare edge. The narrative depends on a model call
/// that is allowed to fail, and on a machine where the team's state changes
/// faster than the narrative is regenerated, `.stale` is the steady state --
/// so both deserve real copy, not a placeholder.
public enum NarrativeState: Sendable, Equatable {
    /// No narrative has ever been written, or every attempt has failed.
    case notGenerated

    /// Written from the inputs this debrief was built from.
    case current(DebriefNarrative)

    /// Written from EARLIER inputs. Still worth showing -- it was true
    /// recently -- but it must be labelled, never presented as current.
    case stale(DebriefNarrative)

    public init(debrief: Debrief) {
        guard let narrative = debrief.narrative else {
            self = .notGenerated
            return
        }
        self = narrative.inputsHash == debrief.inputsHash ? .current(narrative) : .stale(narrative)
    }

    /// The narrative text, or `nil` when there is none. Deliberately does NOT
    /// invent a sentence for the `.notGenerated` case -- a caller that wants
    /// placeholder copy must write it knowingly.
    public var text: String? {
        switch self {
        case .notGenerated: return nil
        case .current(let n), .stale(let n): return n.text
        }
    }

    /// Attribution line: which model wrote it and how long ago. `nil` when
    /// there is nothing to attribute. Prose about measurements must always be
    /// attributable, so a reader can tell it from the measurements.
    public func attribution(now: Date = Date()) -> String? {
        switch self {
        case .notGenerated:
            return nil
        case .current(let n):
            return "\(n.model) · \(RelativeTime.format(unixMillis: n.generatedAt, now: now))"
        case .stale(let n):
            return "\(n.model) · \(RelativeTime.format(unixMillis: n.generatedAt, now: now)) · describes an earlier state"
        }
    }

    public var isStale: Bool {
        if case .stale = self { return true }
        return false
    }
}
