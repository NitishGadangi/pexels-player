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
        ["Authorization": "YOUR_PEXELS_API_KEY"]
    }
}
