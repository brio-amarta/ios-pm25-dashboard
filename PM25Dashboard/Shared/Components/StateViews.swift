import SwiftUI

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading live pipeline data…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No pipeline data yet", systemImage: "wind")
        } description: {
            Text("Run the hourly prediction workflow, then try again.")
        } actions: {
            Button("Refresh") { Task { await retry() } }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t load the dashboard", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") { Task { await retry() } }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ConfigurationRequiredView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Supabase configuration required", systemImage: "gearshape.2")
        } description: {
            Text(message)
            Text("See README.md for setup instructions.")
        }
        .padding()
    }
}

