import Foundation
import PointGuardCore
import XCTest

/// Decodes real, captured JSON shapes against `PointGuardCore`'s hand-written
/// Codable models. Point-guard has no generated OpenAPI client -- BarryKit's
/// generated types cover only Barry's main API -- so this pins the contract
/// the same way sessions-macos's `ContractDecodeTests` does, against a plain
/// `JSONDecoder` and these models instead of `Components.Schemas.*`.
final class ContractDecodeTests: XCTestCase {
    private let decoder = JSONDecoder()

    /// Trimmed to 3 real sessions from a live 14-session `/book` response,
    /// captured from the running point-guard service. Session 1 has a
    /// present `mergeTreeCheckedAt`; session 3 has both `lastActivityAt` and
    /// `mergeTreeCheckedAt` null -- both real, both meaningfully different
    /// from each other and from session 2 (only `mergeTreeCheckedAt` null).
    private static let realBookFixture = """
    {
      "sessions": [
        {
          "sessionId": "zkwFFBjLNzbn_D0F1qFQ8",
          "repo": "/Users/tyler/repos/barry/.git",
          "branch": null,
          "worktree": "/Users/tyler/repos/barry",
          "lastActivityAt": 1789504864907,
          "status": "ok",
          "flaggedReason": null,
          "mergeTreeCheckedAt": 1789504839982,
          "updatedAt": 1789505020012
        },
        {
          "sessionId": "C1ZZJwd2BJ5zWT4LNGpaH",
          "repo": "/Users/tyler/repos/bags/metrics/.git",
          "branch": null,
          "worktree": "/Users/tyler/repos/bags/metrics",
          "lastActivityAt": 1789504798579,
          "status": "ok",
          "flaggedReason": null,
          "mergeTreeCheckedAt": null,
          "updatedAt": 1789505020011
        },
        {
          "sessionId": "G0FdZs4MBKaJFb3WwHVOi",
          "repo": "/Users/tyler/repos/barry/.git",
          "branch": null,
          "worktree": "/Users/tyler/repos/barry",
          "lastActivityAt": null,
          "status": "ok",
          "flaggedReason": null,
          "mergeTreeCheckedAt": 1789504839982,
          "updatedAt": 1789505020010
        }
      ]
    }
    """

    func testBookResponseDecodesRealCapturedFixture() throws {
        let data = Data(Self.realBookFixture.utf8)
        let response = try decoder.decode(BookResponse.self, from: data)

        XCTAssertEqual(response.sessions.count, 3)

        let first = response.sessions[0]
        XCTAssertEqual(first.sessionId, "zkwFFBjLNzbn_D0F1qFQ8")
        XCTAssertEqual(first.repo, "/Users/tyler/repos/barry/.git")
        XCTAssertNil(first.branch)
        XCTAssertEqual(first.lastActivityAt, 1_789_504_864_907)
        XCTAssertEqual(first.status, "ok")
        XCTAssertNil(first.flaggedReason)
        XCTAssertEqual(first.mergeTreeCheckedAt, 1_789_504_839_982)
        XCTAssertEqual(first.updatedAt, 1_789_505_020_012)

        let second = response.sessions[1]
        XCTAssertNil(second.mergeTreeCheckedAt, "second session's merge-tree check has never run")

        let third = response.sessions[2]
        XCTAssertNil(third.lastActivityAt, "third session has no activity recorded yet")
        XCTAssertNotNil(third.mergeTreeCheckedAt, "third session's check HAS run, unlike the second's")
    }

    /// Live data for this endpoint is currently empty (the message feature is
    /// new) -- covered separately below. This is the real captured response.
    func testMessageHistoryDecodesRealCapturedEmptyResponse() throws {
        let json = #"{"messages":[]}"#
        let response = try decoder.decode(MessageHistoryResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.messages.count, 0)
    }

    /// Hand-constructed example matching `recentMessageLog()`'s schema in
    /// `store.ts` -- NOT a live capture, since real non-empty message data
    /// is not available yet.
    private static let syntheticMessageHistoryFixture = """
    {
      "messages": [
        {
          "id": "msg-1",
          "message": "anything stuck?",
          "reply": "all sessions are ok right now.",
          "createdAt": 1789504000000
        },
        {
          "id": "msg-2",
          "message": "how many active sessions",
          "reply": "14 sessions in the book, none flagged.",
          "createdAt": 1789504100000
        }
      ]
    }
    """

    func testMessageHistoryDecodesSyntheticNonEmptyExample() throws {
        let data = Data(Self.syntheticMessageHistoryFixture.utf8)
        let response = try decoder.decode(MessageHistoryResponse.self, from: data)

        XCTAssertEqual(response.messages.count, 2)
        XCTAssertEqual(response.messages[0].id, "msg-1")
        XCTAssertEqual(response.messages[0].message, "anything stuck?")
        XCTAssertEqual(response.messages[0].reply, "all sessions are ok right now.")
        XCTAssertEqual(response.messages[0].createdAt, 1_789_504_000_000)
        XCTAssertEqual(response.messages[1].id, "msg-2")
    }

    func testMessageSendResultDecodesSuccessBody() throws {
        let json = #"{"reply":"all clear"}"#
        let result = try decoder.decode(MessageSendResult.self, from: Data(json.utf8))
        XCTAssertEqual(result.reply, "all clear")
    }
}
