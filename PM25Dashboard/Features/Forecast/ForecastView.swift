import Charts
import SwiftUI

struct ForecastView: View {
    let snapshot: DashboardSnapshot
    let refresh: () async -> Void

    private var points: [ForecastPoint] {
        snapshot.forecast.sorted { $0.targetTimestamp < $1.targetTimestamp }
    }

    private var summary: ForecastSummary? {
        ForecastSummary(
            forecast: points,
            currentPM25: snapshot.currentActual?.pm25
        )
    }

    var body: some View {
        ScrollView {
            if points.isEmpty {
                ContentUnavailableView(
                    "No current forecast",
                    systemImage: "chart.xyaxis.line",
                    description: Text("The next hourly pipeline run will publish 24 forecast points.")
                )
                .padding(.top, 80)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    forecastChart
                    summarySection
                    changeSection
                    hourlySection
                }
                .padding()
            }
        }
        .navigationTitle("24-hour Forecast")
        .refreshable { await refresh() }
    }

    private var forecastChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated \(DashboardFormatters.relative(points.first?.generatedAt))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(points) { point in
                AreaMark(
                    x: .value("Target hour", point.targetTimestamp),
                    y: .value("Predicted PM2.5", point.predicted)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.accentColor.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Target hour", point.targetTimestamp),
                    y: .value("Predicted PM2.5", point.predicted)
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Target hour", point.targetTimestamp),
                    y: .value("Predicted PM2.5", point.predicted)
                )
                .foregroundStyle(Color.accentColor)
            }
            .chartYAxisLabel("µg/m³")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
            .frame(height: 280)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("Next 24 hours PM2.5 forecast chart")
    }

    @ViewBuilder
    private var summarySection: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 12) {
                Text("Forecast summary")
                    .font(.title2.weight(.semibold))
                MetricGrid {
                    MetricCard(
                        title: "Peak",
                        value: DashboardFormatters.concentration(summary.maximum.predicted),
                        detail: DashboardFormatters.dateTime(summary.maximum.targetTimestamp),
                        systemImage: "arrow.up.right"
                    )
                    MetricCard(
                        title: "Average",
                        value: DashboardFormatters.concentration(summary.average),
                        detail: "Across all 24 horizons",
                        systemImage: "equal"
                    )
                    MetricCard(
                        title: "Minimum",
                        value: DashboardFormatters.concentration(summary.minimum.predicted),
                        detail: DashboardFormatters.dateTime(summary.minimum.targetTimestamp),
                        systemImage: "arrow.down.right"
                    )
                    MetricCard(
                        title: "Range",
                        value: DashboardFormatters.concentration(
                            summary.maximum.predicted - summary.minimum.predicted
                        ),
                        detail: "Peak minus minimum",
                        systemImage: "arrow.left.and.right"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var changeSection: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 12) {
                Text("Expected change from current")
                    .font(.title2.weight(.semibold))
                MetricGrid {
                    changeCard(title: "+1 hour", value: summary.delta1h)
                    changeCard(title: "+6 hours", value: summary.delta6h)
                    changeCard(title: "+24 hours", value: summary.delta24h)
                }
            }
        }
    }

    private func changeCard(title: String, value: Double?) -> some View {
        MetricCard(
            title: title,
            value: DashboardFormatters.signedConcentration(value),
            detail: value == nil ? "Current observation unavailable" : "Forecast minus current",
            systemImage: (value ?? 0) >= 0 ? "arrow.up" : "arrow.down",
            tint: (value ?? 0) >= 0 ? .orange : .green
        )
    }

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly values")
                .font(.title2.weight(.semibold))
            ForEach(points) { point in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(DashboardFormatters.hour(point.targetTimestamp))
                            .font(.headline)
                        Text("+\(point.horizonHours)h · \(point.modelVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(DashboardFormatters.concentration(point.predicted))
                        .font(.headline.monospacedDigit())
                }
                .padding(.vertical, 6)
                Divider()
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

