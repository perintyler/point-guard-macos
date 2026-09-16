import PointGuardCore
import SwiftUI

/// The team view: counts, the prose overview, trouble, and open plans.
///
/// Every absence here is rendered as an explicit statement rather than an
/// empty region. An empty box reads as "nothing to report"; these states mean
/// "nothing was written", "nothing has run yet", or "we could not ask" --
/// which are different, and which a reader checking on their team needs to
/// tell apart.
struct DebriefView: View {
    let debrief: Debrief

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                countsRow
                narrativeBlock
                troubleBlock
                plansBlock
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Counts

    private var countsRow: some View {
        HStack(spacing: 8) {
            countTile("total", debrief.counts.total, tint: .secondary)
            countTile("working", debrief.counts.working, tint: .green)
            countTile("idle", debrief.counts.idle, tint: .secondary)
            countTile("stuck", debrief.counts.stuck, tint: .orange)
            countTile("conflicted", debrief.counts.conflicted, tint: .red)
        }
    }

    /// Zeroes are rendered, never hidden. A reader checking whether anything
    /// is stuck needs to see "0 stuck"; a missing tile and a zero look the
    /// same, and only one of them is an answer.
    private func countTile(_ label: String, _ value: Int, tint: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(value == 0 ? AnyShapeStyle(.secondary) : AnyShapeStyle(tint))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Narrative

    /// Styled as an aside -- muted, indented behind a rule -- so it never
    /// reads as a measurement. It is model-written prose ABOUT the numbers
    /// above, and is always attributed to the model that wrote it.
    @ViewBuilder
    private var narrativeBlock: some View {
        let state = NarrativeState(debrief: debrief)
        VStack(alignment: .leading, spacing: 4) {
            switch state {
            case .notGenerated:
                Text("No overview generated yet.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .italic()
            case .current(let narrative), .stale(let narrative):
                Text(narrative.text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if let attribution = state.attribution() {
                    Text(attribution)
                        .font(.caption2)
                        .foregroundStyle(state.isStale ? AnyShapeStyle(.orange) : AnyShapeStyle(.tertiary))
                }
            }
        }
        .padding(.leading, 10)
        .overlay(alignment: .leading) {
            Rectangle().frame(width: 2).foregroundStyle(.quaternary)
        }
    }

    // MARK: - Trouble

    @ViewBuilder
    private var troubleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Trouble", count: debrief.trouble.count)
            if debrief.trouble.isEmpty {
                // "Nothing flagged" -- NOT "everything is fine". The
                // supervisor reports what it detected; it cannot observe that
                // a session is healthy.
                Text("Nothing flagged.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(debrief.trouble) { trouble in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(trouble.kind.replacingOccurrences(of: "_", with: " "))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.orange)
                        Text(trouble.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    // MARK: - Plans

    @ViewBuilder
    private var plansBlock: some View {
        let health = SourceHealth(status: debrief.sources.plans)
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("Plans", count: debrief.plans.count)

            if let warning = health.warning {
                // The plans list is empty AND we could not ask. Saying "no
                // plans" here would report a gap in the page as a fact about
                // the world.
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if debrief.plans.isEmpty {
                if health.emptyMeansNone {
                    Text("No open plans.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else {
                ForEach(debrief.plans) { plan in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(plan.title)
                            .font(.caption)
                            .lineLimit(1)
                        Text("\(plan.progress.done)/\(plan.progress.total)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                        Spacer(minLength: 4)
                        // The qualifier, never ownership: a repo match ties
                        // this plan to every session in the repo.
                        Text(PlanMatch(rawValue: plan.match).qualifier)
                            .font(.caption2)
                            .italic()
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(title).font(.caption.weight(.semibold))
            Text("(\(count))").font(.caption2).foregroundStyle(.tertiary)
        }
    }
}
