import Foundation

/// Whether a debrief source answered, and what an empty result from it means.
///
/// The distinction this preserves: an empty `plans` array can mean "the plans
/// service answered and there are none" or "we could not reach it". Those
/// look identical in the data and must not look identical on screen -- the
/// first is information, the second is a gap in the page the reader should
/// not mistake for information.
public enum SourceHealth: Sendable, Equatable {
    /// The most recent read succeeded. An empty result really is empty.
    case ok(lastSucceededAt: Int64?)

    /// The most recent read failed, but an earlier one succeeded: the data on
    /// screen is real, just old.
    case stale(lastSucceededAt: Int64, error: String)

    /// Never read successfully. Any empty result here means "unknown".
    case unavailable(error: String)

    public init(status: DebriefSourceStatus) {
        switch (status.lastError, status.lastSucceededAt) {
        case (nil, let succeeded):
            self = .ok(lastSucceededAt: succeeded)
        case (let error?, let succeeded?):
            self = .stale(lastSucceededAt: succeeded, error: error)
        case (let error?, nil):
            self = .unavailable(error: error)
        }
    }

    /// Whether an empty list from this source can be read as a real zero.
    public var emptyMeansNone: Bool {
        if case .ok = self { return true }
        return false
    }

    /// A short warning, or `nil` when there is nothing wrong to report.
    public var warning: String? {
        switch self {
        case .ok: return nil
        case .stale(_, let error): return "showing older data — \(error)"
        case .unavailable(let error): return "unavailable — \(error)"
        }
    }
}
