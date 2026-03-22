import UIKit
import Combine
import HomeInterface
import SharedModelsInterface
import SharedRouterInterface
import NetworkLib

public final class HomeCoordinator: HomeBuildable {
    private let networkService: NetworkServiceProtocol
    private let lazyRouter: LazyRouter
    private var _paginationManager: VideoPaginationManager?

    public var paginationManager: VideoPaginationManagerProtocol {
        if let existing = _paginationManager { return existing }
        let repository = VideoRepository(networkService: networkService)
        let useCase = FetchPopularVideosUseCase(repository: repository)
        let manager = VideoPaginationManager(useCase: useCase)
        _paginationManager = manager
        return manager
    }

    public init(networkService: NetworkServiceProtocol, lazyRouter: LazyRouter) {
        self.networkService = networkService
        self.lazyRouter = lazyRouter
    }

    public func build() -> UIViewController {
        let viewModel = HomeViewModel(paginationManager: paginationManager)
        viewModel.navigationDelegate = self
        return HomeViewController(viewModel: viewModel)
    }
}

extension HomeCoordinator: HomeViewModelNavigationDelegate {
    func homeViewModel(_ viewModel: HomeViewModel, didSelectVideoAt index: Int) {
        lazyRouter.navigate(to: .videoFeed(startIndex: index), style: .push)
    }
}
