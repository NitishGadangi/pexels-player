import Foundation
import Combine
import SharedModelsInterface
import NetworkLib

protocol FetchPopularVideosUseCaseProtocol {
    func execute(page: Int, perPage: Int) -> AnyPublisher<PaginatedVideoResponse, NetworkError>
}

final class FetchPopularVideosUseCase: FetchPopularVideosUseCaseProtocol {
    private let repository: VideoRepositoryProtocol

    init(repository: VideoRepositoryProtocol) {
        self.repository = repository
    }

    func execute(page: Int, perPage: Int) -> AnyPublisher<PaginatedVideoResponse, NetworkError> {
        repository.fetchPopularVideos(page: page, perPage: perPage)
    }
}
