import Foundation

/// The merge-tree backstop's state for one session -- a slower check that runs
/// server-side every 5 minutes, separate from the fast per-tick status.
///
/// `.notYetChecked` and `.checked` are deliberately SEPARATE cases, not one
/// case with an optional payload collapsed into a single display string. A
/// `nil` `mergeTreeCheckedAt` means the backstop has never run for this
/// session; a present timestamp means it ran and found no conflict (the
/// session's `status` field is where an actual conflict would show up).
/// Rendering both as "no conflicts" / "all clear" is exactly the bug class
/// the backstop exists to catch -- a session the backstop has not reached yet
/// would read as already-verified-safe.
public enum MergeTreeCheckState: Sendable, Equatable {
    case notYetChecked
    case checked(unixMillis: Int64)

    public init(mergeTreeCheckedAt: Int64?) {
        if let value = mergeTreeCheckedAt {
            self = .checked(unixMillis: value)
        } else {
            self = .notYetChecked
        }
    }

    /// De-emphasized supplementary text for the row's secondary line.
    public func displayText(now: Date) -> String {
        switch self {
        case .notYetChecked:
            return "Not yet checked"
        case .checked(let unixMillis):
            return "Last checked " + RelativeTime.format(unixMillis: unixMillis, now: now)
        }
    }
}
