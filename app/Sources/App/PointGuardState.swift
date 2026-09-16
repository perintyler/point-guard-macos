import Foundation
import Observation
import PointGuardCore

/// Drives the window: the polled book, message compose/reply/history, and
/// the load states behind each.
@MainActor
@Observable
public final class PointGuardState {
    public private(set) var book: LoadState<[BookSession]> = .idle

    /// The debrief, polled on the same timer as the book.
    public private(set) var debrief: LoadState<Debrief> = .idle

    /// True when the service answered 503 -- it is up, and has not produced a
    /// debrief yet. Kept apart from `debrief == .failed` so the view can say
    /// "starting up" instead of "can't reach point-guard", which would send
    /// the reader to debug a connection that is fine.
    public private(set) var debriefNotReady = false
    public private(set) var history: LoadState<[MessageLogEntry]> = .idle
    public private(set) var sendState: LoadState<String> = .idle

    public var composeText: String = ""

    private let client: PointGuardClient
    private var pollTask: Task<Void, Never>?

    public init(client: PointGuardClient = PointGuardClient()) {
        self.client = client
    }

    public func loadBook() async {
        book = .loading
        do {
            book = .loaded(try await client.fetchBook().sessions)
        } catch {
            book = .failed(describePointGuardFailure(error))
        }
    }

    public func loadDebrief() async {
        // No `.loading` transition on refresh: the debrief is polled every 45s
        // and flipping to a spinner each time would make a stable screen
        // flicker. Only the first load shows one.
        if case .idle = debrief { debrief = .loading }
        do {
            debrief = .loaded(try await client.fetchDebrief().debrief)
            debriefNotReady = false
        } catch PointGuardClientError.notReady {
            // Not a failure: the service is up and has nothing yet.
            debriefNotReady = true
            if case .loaded = debrief {} else { debrief = .idle }
        } catch {
            debriefNotReady = false
            debrief = .failed(describePointGuardFailure(error))
        }
    }

    public func loadHistory() async {
        history = .loading
        do {
            history = .loaded(try await client.fetchMessageHistory(limit: 20).messages)
        } catch {
            history = .failed(describePointGuardFailure(error))
        }
    }

    /// Sends the composed text, then refreshes history so the new entry
    /// appears in the "Recent" list underneath.
    public func sendMessage() async {
        let content = composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        sendState = .loading
        do {
            let result = try await client.sendMessage(content: content)
            sendState = .loaded(result.reply)
            composeText = ""
            await loadHistory()
        } catch {
            sendState = .failed(describePointGuardFailure(error))
        }
    }

    /// Fetches immediately, then re-fetches the book every 45 seconds while
    /// the window is open.
    ///
    /// Point-guard recomputes the book server-side only every 60 seconds
    /// (`SUPERVISOR_TICK_INTERVAL_MS` in `server/src/index.ts`) -- polling much
    /// faster than that would just repeat requests for data that has not
    /// changed. 45 seconds keeps the window from ever being more than about
    /// half a server tick stale without over-polling a status dashboard that
    /// nobody is watching live (there is no WebSocket surface on point-guard
    /// for this endpoint, unlike the sessions app's event stream).
    public func startPolling() {
        stopPolling()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.loadBook()
                await self.loadDebrief()
                try? await Task.sleep(for: .seconds(45))
            }
        }
    }

    public func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}
