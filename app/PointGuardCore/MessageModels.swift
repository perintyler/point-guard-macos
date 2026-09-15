import Foundation

/// `GET /message/history`'s response, per `recentMessageLog()` in
/// `bags/point-guard/src/store.ts`.
public struct MessageHistoryResponse: Codable, Sendable {
    public let messages: [MessageLogEntry]

    public init(messages: [MessageLogEntry]) {
        self.messages = messages
    }
}

/// One past message/reply pair. Every field is non-optional -- unlike the
/// book, this row has no sparse/not-yet-run semantics to preserve.
public struct MessageLogEntry: Codable, Sendable, Identifiable {
    public let id: String
    public let message: String
    public let reply: String

    /// Unix ms. Never null.
    public let createdAt: Int64

    public init(id: String, message: String, reply: String, createdAt: Int64) {
        self.id = id
        self.message = message
        self.reply = reply
        self.createdAt = createdAt
    }
}

/// `POST /message`'s success body: `{"reply": string}`. The failure body,
/// `{"error": string}` on a non-2xx response, is not modeled as a value here --
/// `PointGuardClient` decodes it and throws a typed error instead, the same
/// split BarryCore draws with `ProblemResponse`.
public struct MessageSendResult: Codable, Sendable {
    public let reply: String

    public init(reply: String) {
        self.reply = reply
    }
}
