import Foundation

public enum NetworkError: Error, Equatable {
    case invalidURL
    case noData
    case decodingFailed(String)
    case serverError(Int)
    case unknown(String)

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL), (.noData, .noData):
            return true
        case (.decodingFailed(let a), .decodingFailed(let b)):
            return a == b
        case (.serverError(let a), .serverError(let b)):
            return a == b
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}
