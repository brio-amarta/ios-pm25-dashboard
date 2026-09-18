import Foundation
import XCTest
@testable import PM25Dashboard

final class ModelDecodingTests: XCTestCase {
    func testDecodesTheFourSupabaseViews() throws {
        let metricsData = Data(#"[{"model_version":"v1","latest_actual":"2026-09-17T01:00:00+00:00","data_age_hours":0.5,"mae_7d":12.4,"scored_7d":120,"cams_mae_7d":14.1,"pending_forecasts":24}]"#.utf8)
        let forecastData = Data(#"[{"target_ts":"2026-09-17T02:00:00+00:00","predicted":44.2,"horizon_h":1,"model_version":"v1","run_at":"2026-09-17T01:10:00+00:00"}]"#.utf8)
        let actualData = Data(#"[{"ts":"2026-09-17T01:00:00+00:00","pm25":40.1}]"#.utf8)
        let horizonData = Data(#"[{"horizon_h":1,"n":50,"mae":8.3}]"#.utf8)

        let metrics = try JSONDecoder.supabase.decode([PipelineMetrics].self, from: metricsData)
        let forecast = try JSONDecoder.supabase.decode([ForecastPoint].self, from: forecastData)
        let actuals = try JSONDecoder.supabase.decode([ActualPoint].self, from: actualData)
        let horizons = try JSONDecoder.supabase.decode([HorizonMetric].self, from: horizonData)

        XCTAssertEqual(metrics.first?.modelVersion, "v1")
        XCTAssertEqual(metrics.first?.pendingForecasts, 24)
        XCTAssertEqual(metrics.first?.scoredPredictions7d, 120)
        XCTAssertEqual(metrics.first?.camsMae7d, 14.1)
        XCTAssertEqual(forecast.first?.predicted, 44.2)
        XCTAssertEqual(actuals.first?.pm25, 40.1)
        XCTAssertEqual(horizons.first?.sampleCount, 50)
    }

    func testForecastSummaryCalculatesClientStatistics() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let forecast = [1, 6, 24].map { horizon in
            ForecastPoint(
                targetTimestamp: now.addingTimeInterval(Double(horizon * 3600)),
                predicted: Double(40 + horizon),
                horizonHours: horizon,
                modelVersion: "v1",
                generatedAt: now
            )
        }

        let summary = ForecastSummary(forecast: forecast, currentPM25: 40)

        XCTAssertEqual(summary?.minimum.predicted, 41)
        XCTAssertEqual(summary?.maximum.predicted, 64)
        XCTAssertEqual(summary?.average ?? 0, 50.333, accuracy: 0.001)
        XCTAssertEqual(summary?.delta1h, 1)
        XCTAssertEqual(summary?.delta6h, 6)
        XCTAssertEqual(summary?.delta24h, 24)
    }
}
