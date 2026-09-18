import Foundation

protocol DashboardDataProviding: Sendable {
    func fetchMetrics() async throws -> PipelineMetrics?
    func fetchForecast() async throws -> [ForecastPoint]
    func fetchActuals() async throws -> [ActualPoint]
    func fetchHorizonMetrics() async throws -> [HorizonMetric]
}

struct SupabaseClient: DashboardDataProviding, Sendable {
    let configuration: AppConfiguration
    var session: URLSession = .shared

    func fetchMetrics() async throws -> PipelineMetrics? {
        let rows: [PipelineMetrics] = try await fetch(
            view: "pipeline_metrics",
            query: [URLQueryItem(name: "limit", value: "1")]
        )
        return rows.first
    }

    func fetchForecast() async throws -> [ForecastPoint] {
        try await fetch(
            view: "forecast_latest",
            query: [URLQueryItem(name: "order", value: "target_ts.asc")]
        )
    }

    func fetchActuals() async throws -> [ActualPoint] {
        try await fetch(
            view: "actuals_recent",
            query: [URLQueryItem(name: "order", value: "ts.asc")]
        )
    }

    func fetchHorizonMetrics() async throws -> [HorizonMetric] {
        try await fetch(
            view: "mae_by_horizon",
            query: [URLQueryItem(name: "order", value: "horizon_h.asc")]
        )
    }

    private func fetch<T: Decodable>(
        view: String,
        query: [URLQueryItem]
    ) async throws -> T {
        guard let baseURL = configuration.restURL else {
            throw APIError.invalidConfiguration(
                configuration.validationMessage ?? "Supabase configuration is invalid."
            )
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent(view),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "select", value: "*")] + query
        guard let url = components?.url else {
            throw APIError.invalidConfiguration("Could not construct the Supabase URL.")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue(configuration.apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpStatus(http.statusCode, body)
        }

        do {
            return try JSONDecoder.supabase.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }
}

extension JSONDecoder {
    static var supabase: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) {
                return date
            }

            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 timestamp: \(value)"
            )
        }
        return decoder
    }
}
