import SwiftUI

@main
struct PM25DashboardApp: App {
    private let configuration = AppConfiguration.live()

    var body: some Scene {
        WindowGroup {
            if let message = configuration.validationMessage {
                ConfigurationRequiredView(message: message)
            } else {
                DashboardRootView(
                    provider: SupabaseClient(configuration: configuration)
                )
            }
        }
    }
}

