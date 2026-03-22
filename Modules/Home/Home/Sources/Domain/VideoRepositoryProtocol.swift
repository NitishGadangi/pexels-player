import Foundation
import Combine
import SharedModelsInterface
import NetworkLib

protocol VideoRepositoryProtocol {
    func fetchPopularVideos(page: Int, perPage: Int) -> AnyPublisher<PaginatedVideoResponse, NetworkError>
}
