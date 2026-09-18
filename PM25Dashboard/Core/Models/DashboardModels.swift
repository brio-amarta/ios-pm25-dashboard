import Foundation

struct PipelineMetrics: Decodable, Equatable, Sendable {
    let modelVersion: String?
    let latestActual: Date?
    let dataAgeHours: Double?
    let latestForecast: Date?
    let latestRetrain: Date?
    let totalForecasts: Int?
    let pendingForecasts: Int
    let mae7d: Double?
    let scoredPredictions7d: Int
    let camsMae7d: Double?

    enum CodingKeys: String, CodingKey {
        case modelVersion = "model_version"
        case latestActual = "latest_actual"
        case dataAgeHours = "data_age_hours"
        case latestForecast = "latest_forecast"
        case latestRetrain = "latest_retrain"
        case totalForecasts = "total_forecasts"
        case pendingForecasts = "pending_forecasts"
        case mae7d = "mae_7d"
        case scoredPredictions7d = "scored_7d"
        case camsMae7d = "cams_mae_7d"
    }
}

struct ForecastPoint: Decodable, Identifiable, Equatable, Sendable {
    let targetTimestamp: Date
    let predicted: Double
    let horizonHours: Int
    let modelVersion: String
    let generatedAt: Date

    var id: String { "\(generatedAt.timeIntervalSince1970)-\(horizonHours)" }

    enum CodingKeys: String, CodingKey {
        case targetTimestamp = "target_ts"
        case predicted
        case horizonHours = "horizon_h"
        case modelVersion = "model_version"
        case generatedAt = "run_at"
    }
}

struct ActualPoint: Decodable, Identifiable, Equatable, Sendable {
    let timestamp: Date
    let pm25: Double
    let ingestedAt: Date?

    var id: Date { timestamp }

    enum CodingKeys: String, CodingKey {
        case timestamp = "ts"
        case pm25
        case ingestedAt = "ingested_at"
    }
}

struct HorizonMetric: Decodable, Identifiable, Equatable, Sendable {
    let horizonHours: Int
    let sampleCount: Int
    let mae: Double

    var id: Int { horizonHours }

    enum CodingKeys: String, CodingKey {
        case horizonHours = "horizon_h"
        case sampleCount = "n"
        case mae
    }
}

struct DashboardSnapshot: Equatable, Sendable {
    let metrics: PipelineMetrics?
    let forecast: [ForecastPoint]
    let actuals: [ActualPoint]
    let horizonMetrics: [HorizonMetric]

    var currentActual: ActualPoint? { actuals.max { $0.timestamp < $1.timestamp } }
    var latestForecast: Date? {
        metrics?.latestForecast ?? forecast.map(\.generatedAt).max()
    }
    var totalForecasts: Int {
        metrics?.totalForecasts ?? forecast.count
    }
    var isEmpty: Bool {
        metrics == nil && forecast.isEmpty && actuals.isEmpty && horizonMetrics.isEmpty
    }
}

struct ForecastSummary: Equatable {
    let minimum: ForecastPoint
    let maximum: ForecastPoint
    let average: Double
    let delta1h: Double?
    let delta6h: Double?
    let delta24h: Double?

    init?(forecast: [ForecastPoint], currentPM25: Double?) {
        guard
            let minimum = forecast.min(by: { $0.predicted < $1.predicted }),
            let maximum = forecast.max(by: { $0.predicted < $1.predicted })
        else { return nil }

        self.minimum = minimum
        self.maximum = maximum
        average = forecast.map(\.predicted).reduce(0, +) / Double(forecast.count)
        delta1h = Self.delta(at: 1, forecast: forecast, current: currentPM25)
        delta6h = Self.delta(at: 6, forecast: forecast, current: currentPM25)
        delta24h = Self.delta(at: 24, forecast: forecast, current: currentPM25)
    }

    private static func delta(
        at horizon: Int,
        forecast: [ForecastPoint],
        current: Double?
    ) -> Double? {
        guard
            let current,
            let point = forecast.first(where: { $0.horizonHours == horizon })
        else { return nil }
        return point.predicted - current
    }
}
