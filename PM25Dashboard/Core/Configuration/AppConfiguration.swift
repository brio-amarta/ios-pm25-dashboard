import Foundation

struct AppConfiguration: Equatable {
    let projectID: String
    let apiKey: String

    static func live(bundle: Bundle = .main) -> AppConfiguration {
        AppConfiguration(
            projectID: bundle.object(forInfoDictionaryKey: "SupabaseProjectID") as? String ?? "",
            apiKey: bundle.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? ""
        )
    }

    var validationMessage: String? {
        if projectID.trimmed.isEmpty || apiKey.trimmed.isEmpty {
            return "Add SUPABASE_PROJECT_ID and SUPABASE_ANON_KEY to Config/Secrets.xcconfig."
        }
        if projectID.contains("your-project") || apiKey.contains("your-publishable") {
            return "Replace the example Supabase values in Config/Secrets.xcconfig."
        }
        if projectID.contains("/") || projectID.contains(":") {
            return "SUPABASE_PROJECT_ID should be the project reference, not a full URL."
        }
        return nil
    }

    var restURL: URL? {
        guard validationMessage == nil else { return nil }
        return URL(string: "https://\(projectID.trimmed).supabase.co/rest/v1")
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

