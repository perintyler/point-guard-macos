import Foundation

/// Formats a unix-ms timestamp relative to a reference "now".
///
/// `now` is a parameter rather than read internally via `Date()` so the
/// function stays deterministic under test -- a formatter that calls `Date()`
/// itself produces a result that depends on when the test happened to run.
public enum RelativeTime {
    /// Formats a present timestamp. Callers handle the "no timestamp at all"
    /// case (a `nil` upstream value) themselves with their own explicit copy
    /// (e.g. "no activity yet") -- this function only covers the case where a
    /// timestamp DOES exist.
    public static func format(unixMillis: Int64, now: Date) -> String {
        let then = Date(timeIntervalSince1970: TimeInterval(unixMillis) / 1_000)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: then, relativeTo: now)
    }
}
