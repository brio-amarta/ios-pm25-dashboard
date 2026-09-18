import Charts
import SwiftUI

struct OverviewView: View {
    let snapshot: DashboardSnapshot
    let lastRefreshed: Date?
    let refresh: () async -> Void

    private var metrics: PipelineMetrics? { snapshot.metrics }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PipelineStatusBanner(metrics: metrics)

                currentSection
                operationsSection

                if !snapshot.actuals.isEmpty {
                    observationsSection
                }

                sourceNote
            }
            .padding()
        }
        .navigationTitle("Jakarta PM2.5")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh dashboard")
            }
        }
        .refreshable { await refresh() }
    }

    private var currentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Now")
            MetricGrid {
                MetricCard(
                    title: "Current PM2.5",
                    value: DashboardFormatters.concentration(snapshot.currentActual?.pm25),
                    detail: DashboardFormatters.dateTime(snapshot.currentActual?.timestamp),
                    systemImage: "aqi.medium"
                )
                MetricCard(
                    title: "7-day MAE",
                    value: DashboardFormatters.concentration(metrics?.mae7d),
                    detail: "\(metrics?.scoredPredictions7d ?? 0) scored predictions",
                    systemImage: "scope"
                )
                MetricCard(
                    title: "Active model",
                    value: metrics?.modelVersion ?? "Unknown",
                    detail: metrics?.latestRetrain.map {
                        "Retrained \(DashboardFormatters.relative($0))"
                    } ?? "Version used for the latest run",
                    systemImage: "cpu"
                )
                MetricCard(
                    title: "Awaiting reality",
                    value: DashboardFormatters.number(metrics?.pendingForecasts ?? 0),
                    detail: "Predictions for future hours",
                    systemImage: "hourglass"
                )
            }
        }
    }

    private var operationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Pipeline activity")
            MetricGrid {
                MetricCard(
                    title: "Last data pull",
                    value: DashboardFormatters.relative(metrics?.latestActual),
                    detail: DashboardFormatters.dateTime(metrics?.latestActual),
                    systemImage: "arrow.down.circle"
                )
                MetricCard(
                    title: "Last forecast",
                    value: DashboardFormatters.relative(snapshot.latestForecast),
                    detail: DashboardFormatters.dateTime(snapshot.latestForecast),
                    systemImage: "wand.and.stars"
                )
                MetricCard(
                    title: "Forecasts logged",
                    value: DashboardFormatters.number(snapshot.totalForecasts),
                    detail: metrics?.totalForecasts == nil
                        ? "Points in the latest forecast run"
                        : "Committed before their target hour",
                    systemImage: "list.number"
                )
                MetricCard(
                    title: "App refreshed",
                    value: DashboardFormatters.relative(lastRefreshed),
                    detail: DashboardFormatters.dateTime(lastRefreshed),
                    systemImage: "iphone"
                )
            }
        }
    }

    private var observationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Recent observations")
            Chart(snapshot.actuals) { point in
                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("PM2.5", point.pm25)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [Color.accentColor.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("PM2.5", point.pm25)
                )
                .foregroundStyle(Color.accentColor)
                .interpolationMethod(.catmullRom)
            }
            .chartYAxisLabel("µg/m³")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated).hour())
                }
            }
            .frame(height: 230)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("Recent PM2.5 observations chart")
        }
    }

    private var sourceNote: some View {
        Text("Data source: Open-Meteo/CAMS. “Actual” values are CAMS analysis, not readings from a physical monitoring station.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.bottom)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.weight(.semibold))
    }
}
