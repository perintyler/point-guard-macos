import Foundation

/// `GET /debrief`'s response: point-guard's view of what the whole team is
/// doing, as opposed to the book's per-session status. Field names, types and
/// optionality are pinned against the `Debrief` interface in
/// `bags/point-guard/src/debrief.ts` -- that file is the ground truth, not
/// this one.
///
/// The service wraps the payload in a `debrief` key, the way `/book` wraps in
/// `sessions`.
public struct DebriefResponse: Codable, Sendable {
    public let debrief: Debrief

    public init(debrief: Debrief) {
        self.debrief = debrief
    }
}

public struct Debrief: Codable, Sendable {
    public let generatedAt: Int64
    public let counts: DebriefCounts
    public let sessions: [DebriefSession]

    /// Open plans across every session, deduped. An EMPTY array means the
    /// plans service answered and had none -- which is a different fact from
    /// "we could not ask it". `sources.plans` is what separates the two, and
    /// a client that shows the same thing for both has lost that distinction.
    public let plans: [DebriefPlanLink]

    public let trouble: [DebriefTrouble]

    /// `nil` means NO NARRATIVE HAS BEEN GENERATED YET -- first boot, or every
    /// attempt so far has failed. Never a placeholder string, so that "not
    /// generated" stays distinguishable from "generated, and it says little".
    /// Use `NarrativeState` rather than reading this optional directly.
    public let narrative: DebriefNarrative?

    /// Hash of the structured inputs this debrief was built from. Compared
    /// against `narrative.inputsHash` to decide staleness.
    public let inputsHash: String

    public let sources: DebriefSources

    public init(
        generatedAt: Int64,
        counts: DebriefCounts,
        sessions: [DebriefSession],
        plans: [DebriefPlanLink],
        trouble: [DebriefTrouble],
        narrative: DebriefNarrative?,
        inputsHash: String,
        sources: DebriefSources
    ) {
        self.generatedAt = generatedAt
        self.counts = counts
        self.sessions = sessions
        self.plans = plans
        self.trouble = trouble
        self.narrative = narrative
        self.inputsHash = inputsHash
        self.sources = sources
    }
}

/// Every count is a real number, never optional: `0` is a measured zero, not
/// "unknown". A client must render `0 stuck` rather than hiding the row,
/// because a hidden row and a zero look the same to a reader who is
/// specifically checking whether anything is stuck.
public struct DebriefCounts: Codable, Sendable {
    public let total: Int
    public let working: Int
    public let idle: Int
    public let stuck: Int
    public let conflicted: Int

    public init(total: Int, working: Int, idle: Int, stuck: Int, conflicted: Int) {
        self.total = total
        self.working = working
        self.idle = idle
        self.stuck = stuck
        self.conflicted = conflicted
    }
}

public struct DebriefSession: Codable, Sendable, Identifiable {
    public var id: String { sessionId }

    public let sessionId: String

    /// Never `nil` -- the service's `getName()` always returns something.
    /// `nameSource` says which fallback produced it, so a real name can be
    /// styled differently from an id stub.
    public let name: String
    public let nameSource: String

    public let repo: String?

    /// Short display form of `repo` ("barry"), `nil` when `repo` is `nil`.
    /// Computed server-side so every client agrees on it.
    public let repoName: String?

    /// `nil` means no branch was recorded. Sparse in production today.
    public let branch: String?
    public let worktree: String?

    /// The session row's own lifecycle status. A session can be active AND
    /// "completed"; the debrief reports both rather than picking one.
    public let lifecycleStatus: String

    /// The book's verdict, read verbatim -- never recomputed here, so the
    /// debrief and the book can never disagree about a session.
    public let status: String

    /// Non-`nil` ONLY when `status != "ok"`.
    public let flaggedReason: String?

    public let createdAt: Int64

    /// `nil` means this session has produced NO messages at all -- distinct
    /// from old activity, which is a real number.
    public let lastActivityAt: Int64?

    /// How long the session has EXISTED. NOT working time: a session created
    /// four days ago and active this minute reports four days. Label it
    /// "alive", never "working".
    public let aliveMs: Int64

    /// `nil` when `lastActivityAt` is `nil`.
    public let idleMs: Int64?

    /// Newest entry of the bookkeeping job's summary. `nil` means that job has
    /// never summarized this session. MODEL-WRITTEN text from another job --
    /// present it as a description, never as a measurement.
    public let latestSummary: String?

    /// Distinct files touched. `0` is a measured zero (a read-only session
    /// genuinely touched none), never "unknown".
    public let filesTouched: Int

    /// `nil` means THE SLOW MERGE-TREE CHECK HAS NEVER RUN for this session.
    /// A timestamp means it ran and found no TEXTUAL conflict. Use
    /// `MergeTreeCheckState`; collapsing these two into one display string is
    /// the exact bug the backstop exists to catch.
    public let mergeTreeCheckedAt: Int64?

    public let plans: [DebriefPlanLink]

    public init(
        sessionId: String, name: String, nameSource: String, repo: String?, repoName: String?,
        branch: String?, worktree: String?, lifecycleStatus: String, status: String,
        flaggedReason: String?, createdAt: Int64, lastActivityAt: Int64?, aliveMs: Int64,
        idleMs: Int64?, latestSummary: String?, filesTouched: Int, mergeTreeCheckedAt: Int64?,
        plans: [DebriefPlanLink]
    ) {
        self.sessionId = sessionId
        self.name = name
        self.nameSource = nameSource
        self.repo = repo
        self.repoName = repoName
        self.branch = branch
        self.worktree = worktree
        self.lifecycleStatus = lifecycleStatus
        self.status = status
        self.flaggedReason = flaggedReason
        self.createdAt = createdAt
        self.lastActivityAt = lastActivityAt
        self.aliveMs = aliveMs
        self.idleMs = idleMs
        self.latestSummary = latestSummary
        self.filesTouched = filesTouched
        self.mergeTreeCheckedAt = mergeTreeCheckedAt
        self.plans = plans
    }
}

public struct DebriefPlanLink: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let status: String
    public let progress: DebriefPlanProgress
    public let url: String

    /// HOW this plan was tied to this session. Raw wire string; `PlanMatch` is
    /// where it becomes a type that a view can render honestly.
    public let match: String

    public init(id: String, title: String, status: String, progress: DebriefPlanProgress, url: String, match: String) {
        self.id = id
        self.title = title
        self.status = status
        self.progress = progress
        self.url = url
        self.match = match
    }
}

public struct DebriefPlanProgress: Codable, Sendable {
    public let done: Int
    public let total: Int
    public let of: String

    public init(done: Int, total: Int, of: String) {
        self.done = done
        self.total = total
        self.of = of
    }
}

public struct DebriefTrouble: Codable, Sendable, Identifiable {
    public let id: String
    public let kind: String

    /// `nil` for troubles that belong to no single session (the outbox).
    public let sessionId: String?

    /// Taken from the underlying row, never synthesized.
    public let detail: String
    public let at: Int64

    public init(id: String, kind: String, sessionId: String?, detail: String, at: Int64) {
        self.id = id
        self.kind = kind
        self.sessionId = sessionId
        self.detail = detail
        self.at = at
    }
}

public struct DebriefSources: Codable, Sendable {
    public let sessions: DebriefSourceStatus
    public let plans: DebriefSourceStatus

    public init(sessions: DebriefSourceStatus, plans: DebriefSourceStatus) {
        self.sessions = sessions
        self.plans = plans
    }
}

public struct DebriefSourceStatus: Codable, Sendable, Equatable {
    /// `nil` means this source has never been read successfully since the
    /// service started -- NOT "the read returned zero rows", which is a
    /// success with a timestamp.
    public let lastSucceededAt: Int64?

    /// `nil` means the most recent attempt SUCCEEDED. Non-`nil` alongside a
    /// non-`nil` `lastSucceededAt` means "stale data, shown anyway".
    public let lastError: String?

    public init(lastSucceededAt: Int64?, lastError: String?) {
        self.lastSucceededAt = lastSucceededAt
        self.lastError = lastError
    }
}

public struct DebriefNarrative: Codable, Sendable, Equatable {
    public let text: String
    public let model: String
    public let generatedAt: Int64

    /// Hash of the inputs this text was written FROM. When it differs from the
    /// debrief's own `inputsHash`, the prose describes an older state.
    public let inputsHash: String

    public init(text: String, model: String, generatedAt: Int64, inputsHash: String) {
        self.text = text
        self.model = model
        self.generatedAt = generatedAt
        self.inputsHash = inputsHash
    }
}
