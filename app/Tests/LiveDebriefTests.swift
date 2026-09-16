import Foundation
import PointGuardCore
import XCTest

/// Decodes what the LIVE service is serving right now. Skips (never fails)
/// when the service or secret is absent, following `LiveAPITests`' posture in
/// the iOS app: an integration test that fails on a stopped service teaches
/// people to ignore red.
final class LiveDebriefTests: XCTestCase {
    func testLiveDebriefDecodes() async throws {
        guard let secret = ProcessInfo.processInfo.environment["BARRY_SECRET"], !secret.isEmpty else {
            throw XCTSkip("BARRY_SECRET not set")
        }
        var request = URLRequest(url: URL(string: "http://127.0.0.1:3868/debrief")!)
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "authorization")
        request.timeoutInterval = 10

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw XCTSkip("point-guard not reachable: \(error)")
        }
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        if http.statusCode == 503 {
            throw XCTSkip("service up but no debrief yet (503) — a real state, not a failure")
        }
        XCTAssertEqual(http.statusCode, 200)

        let debrief = try JSONDecoder().decode(DebriefResponse.self, from: data).debrief

        // The contract, against today's real payload.
        XCTAssertEqual(
            debrief.counts.working + debrief.counts.idle + debrief.counts.stuck + debrief.counts.conflicted,
            debrief.counts.total,
            "the four buckets must account for every session"
        )
        XCTAssertFalse(debrief.inputsHash.isEmpty)
        for session in debrief.sessions {
            XCTAssertTrue(
                ["ok", "stuck", "conflicted"].contains(session.status),
                "unexpected status \(session.status) — the client models a closed set"
            )
            if session.status == "ok" {
                XCTAssertNil(session.flaggedReason, "an ok session must carry no reason")
            }
        }
    }
}
