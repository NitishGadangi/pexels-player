import Foundation
import Combine

public final class URLSessionNetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private(set) var configuration: NetworkConfiguration?

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func configure(with configuration: NetworkConfiguration) {
        self.configuration = configuration
    }

    public func request<T: Decodable>(_ endpoint: any Endpoint, responseType: T.Type) -> AnyPublisher<T, NetworkError> {
        var urlRequest: URLRequest

        if let endpointRequest = endpoint.urlRequest, !endpoint.baseURL.isEmpty {
            urlRequest = endpointRequest
        } else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        if let timeout = configuration?.timeoutInterval {
            urlRequest.timeoutInterval = timeout
        }

        if configuration?.logRequests == true {
            print("[Network] \(urlRequest.httpMethod ?? "GET") \(urlRequest.url?.absoluteString ?? "")")
        }

        let logResponses = configuration?.logResponses == true

        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown("Invalid response")
                }

                if logResponses {
                    let body = String(data: data.prefix(500), encoding: .utf8) ?? "<binary>"
                    print("[Network] Response \(httpResponse.statusCode): \(body)")
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                guard !data.isEmpty else {
                    throw NetworkError.noData
                }
                return data
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                }
                if error is DecodingError {
                    return NetworkError.decodingFailed(error.localizedDescription)
                }
                return NetworkError.unknown(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
}
