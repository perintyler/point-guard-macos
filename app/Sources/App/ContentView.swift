import PointGuardCore
import SwiftUI

/// Barry's accent purple, ported from `Theme.accent` in barry-iphone's
/// `App/Theme.swift` -- the one custom color this app uses. The three status
/// dot colors (see `SessionRow`) stay plain system semantic colors, matching
/// how `Theme.statusColor` treats its own analogous states.
let pointGuardAccent = Color(red: 0.655, green: 0.545, blue: 0.980)

struct ContentView: View {
    @Bindable var state: PointGuardState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                bookSection
                Divider()
                composeSection
            }
            .navigationTitle("Point Guard")
        }
        .tint(pointGuardAccent)
        .task {
            state.startPolling()
            await state.loadHistory()
        }
    }

    @ViewBuilder
    private var bookSection: some View {
        switch state.book {
        case .idle, .loading:
            ProgressView("Loading sessions...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView(
                "Cannot load sessions",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let sessions):
            List(sessions) { session in
                SessionRow(viewModel: SessionRowViewModel(session: session, now: .now))
            }
            .listStyle(.inset)
        }
    }

    private var composeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Ask the supervisor...", text: $state.composeText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await state.sendMessage() } }
                Button("Send") {
                    Task { await state.sendMessage() }
                }
                .tint(pointGuardAccent)
                .disabled(isSendDisabled)
            }

            switch state.sendState {
            case .loaded(let reply):
                Text(reply)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .failed(let message):
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
            case .idle, .loading:
                EmptyView()
            }

            historySection
        }
        .padding()
    }

    private var isSendDisabled: Bool {
        let trimmed = state.composeText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || state.sendState.isLoading
    }

    @ViewBuilder
    private var historySection: some View {
        if let entries = state.history.value, !entries.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                // Reference material, not an ongoing chat thread -- every
                // point-guard message is fresh context server-side with no
                // chaining (the "Heartbeat pattern"), so this deliberately
                // avoids chat-bubble styling that would imply a continuity
                // the service does not actually have.
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(entries.prefix(5)) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.message)
                                    .font(.callout.weight(.medium))
                                Text(entry.reply)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(maxHeight: 160)
            }
        }
    }
}
