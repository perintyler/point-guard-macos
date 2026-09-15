import PointGuardCore
import SwiftUI

/// One row of the book: status dot, repo/branch, last activity, the flagged
/// reason when present, and the merge-tree backstop's de-emphasized
/// secondary line.
struct SessionRow: View {
    let viewModel: SessionRowViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if let repoName = viewModel.repoName {
                        Text(repoName)
                            .font(.body.weight(.semibold))
                    } else {
                        Text(viewModel.sessionId)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    if let branch = viewModel.branch {
                        Text(branch)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(viewModel.lastActivityText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let flaggedReason = viewModel.flaggedReason {
                    Text(flaggedReason)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(flaggedTintColor)
                }

                Text(viewModel.mergeTreeCheckText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch viewModel.status {
        case .ok: return .green
        case .stuck: return .orange
        case .conflicted: return .red
        case .unknown: return .gray
        }
    }

    private var flaggedTintColor: Color {
        viewModel.status == .conflicted ? .red : .orange
    }
}
