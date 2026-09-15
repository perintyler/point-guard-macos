import Foundation

/// `GET /book`'s response: point-guard's live view of every session it is
/// watching. Field names/types/optionality here are pinned against
/// `bookRows()` in `bags/point-guard/src/store.ts` -- that function is the
/// ground truth, not this file.
public struct BookResponse: Codable, Sendable {
    public let sessions: [BookSession]

    public init(sessions: [BookSession]) {
        self.sessions = sessions
    }
}

/// One row of the book.
///
/// Three fields carry meaning in their `nil` case that is easy to get wrong --
/// see each doc comment below, and `SessionRowViewModel` for where that
/// meaning gets turned into what a view actually shows.
public struct BookSession: Codable, Sendable, Identifiable {
    public var id: String { sessionId }

    public let sessionId: String

    /// `nil` means no git repo is associated with this session at all (a
    /// non-code task) -- not an error, and not "unknown".
    public let repo: String?

    /// `nil` means no branch info has been recorded for this session. Real
    /// production sessions mostly have this null right now; it is sparse
    /// data, not a failure.
    public let branch: String?

    /// `nil` alongside `repo == nil` -- no working directory for this session.
    public let worktree: String?

    /// Unix ms of the session's last activity. `nil` means the session has no
    /// messages yet -- render as "no activity yet", never as a bogus
    /// "just now"/epoch-zero relative time.
    public let lastActivityAt: Int64?

    /// One of "ok" / "stuck" / "conflicted". Kept as the raw wire string here;
    /// `SessionStatus` is where it becomes a real type.
    public let status: String

    /// `nil` exactly when `status == "ok"` -- nothing to report. Always a
    /// non-null explanation when status is "stuck" or "conflicted".
    public let flaggedReason: String?

    /// Unix ms the slower merge-tree backstop check last ran, or `nil` if it
    /// has NEVER run for this session yet. This is not the same as "checked,
    /// found nothing" -- collapsing the two into one "all clear" display is
    /// exactly the bug class the backstop exists to prevent. See
    /// `MergeTreeCheckState`.
    public let mergeTreeCheckedAt: Int64?

    /// Unix ms this row was last written. Never null.
    public let updatedAt: Int64

    public init(
        sessionId: String,
        repo: String?,
        branch: String?,
        worktree: String?,
        lastActivityAt: Int64?,
        status: String,
        flaggedReason: String?,
        mergeTreeCheckedAt: Int64?,
        updatedAt: Int64
    ) {
        self.sessionId = sessionId
        self.repo = repo
        self.branch = branch
        self.worktree = worktree
        self.lastActivityAt = lastActivityAt
        self.status = status
        self.flaggedReason = flaggedReason
        self.mergeTreeCheckedAt = mergeTreeCheckedAt
        self.updatedAt = updatedAt
    }
}
