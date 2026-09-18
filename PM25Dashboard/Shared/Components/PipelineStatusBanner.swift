import SwiftUI

struct PipelineStatusBanner: View {
    let metrics: PipelineMetrics?

    private var isStale: Bool {
        guard let age = metrics?.dataAgeHours else { return true }
        return age >= 3
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isStale ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(isStale ? .orange : .green)

            VStack(alignment: .leading, spacing: 2) {
                Text(isStale ? "Pipeline data is stale" : "Pipeline is current")
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            (isStale ? Color.orange : Color.green).opacity(0.12),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .accessibilityElement(children: .combine)
    }

    private var statusDetail: String {
        guard let latest = metrics?.latestActual else {
            return "No observation timestamp is available."
        }
        return "Latest observation \(DashboardFormatters.relative(latest))."
    }
}
