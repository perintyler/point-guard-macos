import Foundation

/// How a plan came to be associated with a session.
///
/// This exists to stop a weak signal being rendered as a strong one. Today
/// the only real value is `.repo`, which means "this plan names the same repo
/// this session is in" -- NOT "this session is working on this plan". A repo
/// with fourteen sessions attaches the same plan to all fourteen.
///
/// So the qualifier is not decoration: "in this repo" is true, "working on"
/// is not, and the difference is the whole reason the wire field exists.
public enum PlanMatch: Sendable, Equatable {
    /// Matched because the plan names the session's repo. A weak signal.
    case repo

    /// Matched because the plan records this session id. Reserved -- nothing
    /// writes it yet.
    case session

    /// A value this client does not know. Rendered as itself rather than
    /// guessed at, following `SessionStatus.unknown`.
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "repo": self = .repo
        case "session": self = .session
        default: self = .unknown(rawValue)
        }
    }

    /// Short qualifier for a plan chip. Never phrased as ownership.
    public var qualifier: String {
        switch self {
        case .repo: return "in this repo"
        case .session: return "this session"
        case .unknown(let raw): return raw
        }
    }
}
