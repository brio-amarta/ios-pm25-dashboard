import Foundation
import XCTest
@testable import PM25Dashboard

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testLoadPublishesSnapshot() async {
        let provider = MockProvider(populated: true)
        let viewModel = DashboardViewModel(provider: provider)

        await viewModel.load()

        XCTAssertEqual(viewModel.phase, .loaded)
        XCTAssertEqual(viewModel.snapshot?.forecast.count, 1)
        XCTAssertNotNil(viewModel.lastRefreshed)
    }

    func testLoadPublishesEmptyState() async {
        let provider = MockProvider(populated: false)
        let viewModel = DashboardViewModel(provider: provider)

        await viewModel.load()

        XCTAssertEqual(viewModel.phase, .empty)
    }
}

private struct MockProvider: DashboardDataProviding {
    let populated: Bool
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func fetchMetrics() async throws -> PipelineMetrics? {
        guard populated else { return nil }
        return PipelineMetrics(
            modelVersion: "v1",
            latestActual: now,
            dataAgeHours: 0.25,
            latestForecast: now,
            latestRetrain: now,
            totalForecasts: 10,
            pendingForecasts: 1,
            mae7d: 4.5,
            scoredPredictions7d: 9,
            camsMae7d: 5.1
        )
    }

    func fetchForecast() async throws -> [ForecastPoint] {
        guard populated else { return [] }
        return [
            ForecastPoint(
                targetTimestamp: now.addingTimeInterval(3600),
                predicted: 42,
                horizonHours: 1,
                modelVersion: "v1",
                generatedAt: now
            )
        ]
    }

    func fetchActuals() async throws -> [ActualPoint] {
        guard populated else { return [] }
        return [ActualPoint(timestamp: now, pm25: 40, ingestedAt: now)]
    }

    func fetchHorizonMetrics() async throws -> [HorizonMetric] {
        guard populated else { return [] }
        return [HorizonMetric(horizonHours: 1, sampleCount: 9, mae: 4.5)]
    }
}
