import SwiftUI

struct DashboardRootView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(provider: any DashboardDataProviding) {
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(provider: provider)
        )
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle, .loading:
                LoadingStateView()
            case .empty:
                EmptyStateView {
                    await viewModel.load()
                }
            case .failed(let message):
                ErrorStateView(message: message) {
                    await viewModel.load()
                }
            case .loaded:
                if let snapshot = viewModel.snapshot {
                    dashboard(snapshot)
                } else {
                    EmptyStateView {
                        await viewModel.load()
                    }
                }
            }
        }
        .task {
            guard viewModel.phase == .idle else { return }
            await viewModel.load()
        }
    }

    private func dashboard(_ snapshot: DashboardSnapshot) -> some View {
        TabView {
            NavigationStack {
                OverviewView(
                    snapshot: snapshot,
                    lastRefreshed: viewModel.lastRefreshed,
                    refresh: refresh
                )
            }
            .tabItem { Label("Overview", systemImage: "gauge.with.dots.needle.50percent") }

            NavigationStack {
                ForecastView(snapshot: snapshot, refresh: refresh)
            }
            .tabItem { Label("Forecast", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                AccuracyView(snapshot: snapshot, refresh: refresh)
            }
            .tabItem { Label("Accuracy", systemImage: "scope") }
        }
    }

    private func refresh() async {
        await viewModel.load(showLoading: false)
    }
}

