import Foundation
import Combine
import SharedModelsInterface
import NetworkLib

final class VideoRepository: VideoRepositoryProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func fetchPopularVideos(page: Int, perPage: Int) -> AnyPublisher<PaginatedVideoResponse, NetworkError> {
        networkService.request(
            PexelsEndpoint.popular(page: page, perPage: perPage),
            responseType: PaginatedVideoResponse.self
        )
    }
}
