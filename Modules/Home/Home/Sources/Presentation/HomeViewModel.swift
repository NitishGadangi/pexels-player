import Foundation
import Combine
import SharedModelsInterface

protocol HomeViewModelNavigationDelegate: AnyObject {
    func homeViewModel(_ viewModel: HomeViewModel, didSelectVideoAt index: Int)
}

final class HomeViewModel {
    enum Action {
        case viewDidLoad
        case pullToRefresh
        case loadMore
        case didSelectVideo(index: Int)
    }

    enum State: Equatable {
        case idle
        case loading
        case loaded([Video])
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading):
                return true
            case (.loaded(let a), .loaded(let b)):
                return a == b
            case (.error(let a), .error(let b)):
                return a == b
            default:
                return false
            }
        }
    }

    let action = PassthroughSubject<Action, Never>()
    private(set) var state = CurrentValueSubject<State, Never>(.idle)
    var statePublisher: AnyPublisher<State, Never> { state.eraseToAnyPublisher() }

    weak var navigationDelegate: HomeViewModelNavigationDelegate?

    private let paginationManager: VideoPaginationManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    init(paginationManager: VideoPaginationManagerProtocol) {
        self.paginationManager = paginationManager
        bindActions()
        bindPaginationManager()
    }

    private func bindActions() {
        action
            .sink { [weak self] action in self?.handleAction(action) }
            .store(in: &cancellables)
    }

    private func bindPaginationManager() {
        paginationManager.videosPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videos in
                guard let self, !videos.isEmpty else { return }
                self.state.send(.loaded(videos))
            }
            .store(in: &cancellables)
    }

    private func handleAction(_ action: Action) {
        switch action {
        case .viewDidLoad:
            loadInitial()
        case .pullToRefresh:
            refresh()
        case .loadMore:
            loadMore()
        case .didSelectVideo(let index):
            navigationDelegate?.homeViewModel(self, didSelectVideoAt: index)
        }
    }

    private func loadInitial() {
        state.send(.loading)
        paginationManager.loadNextPage()
            .receive(on: DispatchQueue.main)
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

    private func refresh() {
        paginationManager.refresh()
            .receive(on: DispatchQueue.main)
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
            .receive(on: DispatchQueue.main)
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
