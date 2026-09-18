import Charts
import SwiftUI

struct AccuracyView: View {
    let snapshot: DashboardSnapshot
    let refresh: () async -> Void

    private var horizons: [HorizonMetric] {
        snapshot.horizonMetrics.sorted { $0.horizonHours < $1.horizonHours }
    }

    private var best: HorizonMetric? { horizons.min { $0.mae < $1.mae } }
    private var worst: HorizonMetric? { horizons.max { $0.mae < $1.mae } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headlineMetrics

                if horizons.isEmpty {
                    ContentUnavailableView(
                        "No scored horizons yet",
                        systemImage: "scope",
                        description: Text("Accuracy appears after forecast target hours receive matching observations.")
                    )
                    .padding(.top, 40)
                } else {
                    horizonChart
                    horizonHighlights
                    methodology
                }
            }
            .padding()
        }
        .navigationTitle("Accuracy")
        .refreshable { await refresh() }
    }

    private var headlineMetrics: some View {
        MetricGrid {
            MetricCard(
                title: "Live MAE · 7 days",
                value: DashboardFormatters.concentration(snapshot.metrics?.mae7d),
                detail: "Lower is better",
                systemImage: "scope"
            )
            MetricCard(
                title: "Scored predictions",
                value: DashboardFormatters.number(snapshot.metrics?.scoredPredictions7d ?? 0),
                detail: "Always read MAE together with n",
                systemImage: "number"
            )
            MetricCard(
                title: "CAMS baseline · 7 days",
                value: DashboardFormatters.concentration(snapshot.metrics?.camsMae7d),
                detail: "Reference error for comparison",
                systemImage: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private var horizonChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MAE by forecast distance")
                .font(.title2.weight(.semibold))
            Text("Last 30 days")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(horizons) { metric in
                BarMark(
                    x: .value("Horizon", metric.horizonHours),
                    y: .value("MAE", metric.mae)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: [1, 6, 12, 18, 24]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Int.self) {
                            Text("+\(hour)h")
                        }
                    }
                }
            }
            .chartYAxisLabel("MAE µg/m³")
            .frame(height: 280)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Mean absolute error by forecast horizon chart")
    }

    private var horizonHighlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Horizon highlights")
                .font(.title2.weight(.semibold))
            MetricGrid {
                MetricCard(
                    title: "Lowest error",
                    value: DashboardFormatters.concentration(best?.mae),
                    detail: best.map { "+\($0.horizonHours)h · \($0.sampleCount) samples" },
                    systemImage: "checkmark.circle",
                    tint: .green
                )
                MetricCard(
                    title: "Highest error",
                    value: DashboardFormatters.concentration(worst?.mae),
                    detail: worst.map { "+\($0.horizonHours)h · \($0.sampleCount) samples" },
                    systemImage: "exclamationmark.circle",
                    tint: .orange
                )
            }
        }
    }

    private var methodology: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("How this is scored", systemImage: "info.circle")
                .font(.headline)
            Text("A prediction is scored only after its target hour receives a matching observation. MAE is the average absolute distance between those two values. Error usually increases at longer horizons.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}
