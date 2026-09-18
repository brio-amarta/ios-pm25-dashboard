import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidConfiguration(String)
    case invalidResponse
    case httpStatus(Int, String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return message
        case .invalidResponse:
            return "The server returned an invalid response."
        case .httpStatus(let code, let message):
            return "Supabase returned HTTP \(code). \(message)"
        case .decoding(let message):
            return "The server response did not match the app's data contract. \(message)"
        }
    }
}

