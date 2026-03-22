import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var queryParams: [String: String]? { get }
    var headers: [String: String]? { get }
}

public extension Endpoint {
    var headers: [String: String]? { nil }

    var urlRequest: URLRequest? {
        let fullPath = baseURL.isEmpty ? path : baseURL + path
        guard var components = URLComponents(string: fullPath) else { return nil }

        if let queryParams {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }
}
