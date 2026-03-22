import Foundation
import Combine
import SharedModelsInterface

protocol HomeViewModelNavigationDelegate: AnyObject {
    func homeViewModel(_ viewModel: HomeViewModel, didSelectVideoAt index: Int)
}

final class HomeViewModel {
    enum Action {
        case viewDidLoad
        case loadMore
        case didSelectVideo(index: Int)
    }

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    let actionHandler = PassthroughSubject<Action, Never>()
    private let state = CurrentValueSubject<State, Never>(.idle)
    var statePublisher: AnyPublisher<State, Never> { state.eraseToAnyPublisher() }

    weak var navigationDelegate: HomeViewModelNavigationDelegate?

    private let paginationManager: VideoPaginationManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    var numberOfItems: Int { paginationManager.videos.count }

    func video(at index: Int) -> Video? {
        let videos = paginationManager.videos
        guard index < videos.count else { return nil }
        return videos[index]
    }

    init(paginationManager: VideoPaginationManagerProtocol) {
        self.paginationManager = paginationManager
        bindActions()
        bindPaginationManager()
    }

    private func bindActions() {
        actionHandler
            .sink { [weak self] action in self?.handleAction(action) }
            .store(in: &cancellables)
    }

    private func bindPaginationManager() {
        paginationManager.videosPublisher
            .dropFirst()
            .sink { [weak self] videos in
                guard let self, !videos.isEmpty else { return }
                self.state.send(.loaded)
            }
            .store(in: &cancellables)
    }

    private func handleAction(_ action: Action) {
        switch action {
        case .viewDidLoad:
            loadInitial()
        case .loadMore:
            loadMore()
        case .didSelectVideo(let index):
            navigationDelegate?.homeViewModel(self, didSelectVideoAt: index)
        }
    }

    private func loadInitial() {
        state.send(.loading)
        paginationManager.loadNextPage()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.state.send(.error(error.localizedDescription))
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    private func loadMore() {
        guard !paginationManager.isLoading else { return }
        paginationManager.loadNextPage()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.state.send(.error(error.localizedDescription))
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}
