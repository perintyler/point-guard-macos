import Foundation

/// A book row's status, derived from the raw wire string.
///
/// This target has no AppKit/SwiftUI import, so it cannot return a `Color` --
/// that mapping lives in the app target, keyed off this enum. Keeping the
/// enum here (rather than passing the raw string straight to the view) is
/// what makes an unrecognized status a compile-time-checked `.unknown` case
/// instead of a view silently rendering nothing.
public enum SessionStatus: Sendable, Equatable {
    case ok
    case stuck
    case conflicted
    /// Any wire value other than the three known ones. Point-guard's contract
    /// only emits the three above; this exists so a future addition degrades
    /// to a labeled, visible state instead of a crash or a silent default.
    case unknown(String)

    public init(wire: String) {
        switch wire {
        case "ok": self = .ok
        case "stuck": self = .stuck
        case "conflicted": self = .conflicted
        default: self = .unknown(wire)
        }
    }

    public var label: String {
        switch self {
        case .ok: return "OK"
        case .stuck: return "Stuck"
        case .conflicted: return "Conflicted"
        case .unknown(let wire): return wire.capitalized
        }
    }
}
