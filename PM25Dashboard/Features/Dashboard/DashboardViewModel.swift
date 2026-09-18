import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failed(String)
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var snapshot: DashboardSnapshot?
    @Published private(set) var lastRefreshed: Date?

    private let provider: any DashboardDataProviding

    init(provider: any DashboardDataProviding) {
        self.provider = provider
    }

    func load(showLoading: Bool = true) async {
        if showLoading && snapshot == nil {
            phase = .loading
        }

        do {
            async let metrics = provider.fetchMetrics()
            async let forecast = provider.fetchForecast()
            async let actuals = provider.fetchActuals()
            async let horizonMetrics = provider.fetchHorizonMetrics()

            let result = try await DashboardSnapshot(
                metrics: metrics,
                forecast: forecast,
                actuals: actuals,
                horizonMetrics: horizonMetrics
            )

            snapshot = result
            lastRefreshed = Date()
            phase = result.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}

