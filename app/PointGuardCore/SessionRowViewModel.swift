import Foundation

/// Everything a book row's SwiftUI view needs, already computed from a
/// `BookSession` and a reference "now" -- the point of this type is to keep
/// the null-semantics decisions (see each field's doc comment on
/// `BookSession`) in one pure, tested place instead of scattered across view
/// code.
public struct SessionRowViewModel: Sendable, Equatable {
    public let sessionId: String
    public let status: SessionStatus

    /// Last path component of `repo`, with a trailing `.git` stripped first.
    /// `nil` when `repo` is `nil` -- render as absent, not as an error.
    public let repoName: String?

    /// `nil` when no branch was recorded -- render as absent, not "unknown".
    public let branch: String?

    /// "no activity yet" when `lastActivityAt` is `nil`; otherwise a relative
    /// time string computed against the supplied "now".
    public let lastActivityText: String

    /// Present only when `status` is not `.ok` -- always non-nil in that case,
    /// per the wire contract, and always nil when `status == .ok`.
    public let flaggedReason: String?

    /// "Not yet checked" vs "Last checked <relative time>" -- see
    /// `MergeTreeCheckState`'s doc comment for why these must never collapse
    /// into one display state.
    public let mergeTreeCheckText: String

    public init(session: BookSession, now: Date) {
        self.sessionId = session.sessionId
        self.status = SessionStatus(wire: session.status)
        self.repoName = RepoName.displayName(repo: session.repo)
        self.branch = session.branch
        self.flaggedReason = session.flaggedReason

        if let lastActivityAt = session.lastActivityAt {
            self.lastActivityText = RelativeTime.format(unixMillis: lastActivityAt, now: now)
        } else {
            self.lastActivityText = "No activity yet"
        }

        self.mergeTreeCheckText = MergeTreeCheckState(
            mergeTreeCheckedAt: session.mergeTreeCheckedAt
        ).displayText(now: now)
    }
}
