import Foundation
import Combine
import SharedModelsInterface

final class VideoPaginationManager: VideoPaginationManagerProtocol {
    private let useCase: FetchPopularVideosUseCaseProtocol
    private let perPage: Int

    private let videosSubject = CurrentValueSubject<[Video], Never>([])
    private var currentPage = 0
    private var totalResults = Int.max
    private var _isLoading = false
    private var cancellables = Set<AnyCancellable>()

    var videos: [Video] { videosSubject.value }
    var videosPublisher: AnyPublisher<[Video], Never> { videosSubject.eraseToAnyPublisher() }
    var isLoading: Bool { _isLoading }
    var hasMorePages: Bool { videosSubject.value.count < totalResults }

    init(useCase: FetchPopularVideosUseCaseProtocol, perPage: Int = 15) {
        self.useCase = useCase
        self.perPage = perPage
    }

    func loadNextPage() -> AnyPublisher<Void, Error> {
        guard !_isLoading, hasMorePages else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }

        _isLoading = true
        let nextPage = currentPage + 1

        return useCase.execute(page: nextPage, perPage: perPage)
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self else { return }
                self.currentPage = response.page
                self.totalResults = response.totalResults
                var current = self.videosSubject.value
                current.append(contentsOf: response.videos)
                self.videosSubject.send(current)
            }, receiveCompletion: { [weak self] _ in
                self?._isLoading = false
            })
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        _isLoading = true
        currentPage = 0
        totalResults = Int.max
        videosSubject.send([])

        return useCase.execute(page: 1, perPage: perPage)
            .handleEvents(receiveOutput: { [weak self] response in
                guard let self else { return }
                self.currentPage = response.page
                self.totalResults = response.totalResults
                self.videosSubject.send(response.videos)
            }, receiveCompletion: { [weak self] _ in
                self?._isLoading = false
            })
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
