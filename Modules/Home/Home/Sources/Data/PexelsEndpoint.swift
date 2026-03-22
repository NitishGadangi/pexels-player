import Foundation
import NetworkLib

enum PexelsEndpoint: Endpoint {
    case popular(page: Int, perPage: Int)

    var baseURL: String { "https://api.pexels.com" }

    var path: String {
        switch self {
        case .popular:
            return "/videos/popular"
        }
    }

    var method: HTTPMethod { .get }

    var queryParams: [String: String]? {
        switch self {
        case .popular(let page, let perPage):
            return ["page": "\(page)", "per_page": "\(perPage)"]
        }
    }

    var headers: [String: String]? {
        // TODO: Make the API key a secret.
        // Ideally this auth token must be stored in some xcconfig/plist file and keep it away from git tracking
        // To keep the code easy to run I hardcoding for now. This token would be disabled later.
        ["Authorization": "e3SY7xHQSFntkEUwmeWAihiT131oYtyHTIOTxagzvdlPBRPMhu3k4Iwv"]
    }
}
