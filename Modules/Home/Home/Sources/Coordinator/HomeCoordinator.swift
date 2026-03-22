import UIKit
import Combine
import HomeInterface
import SharedModelsInterface
import SharedRouterInterface
import NetworkLib

public final class HomeCoordinator: HomeBuildable {
    private let networkService: NetworkServiceProtocol
    private let router: SharedRouterProtocol

    public private(set) lazy var paginationManager: VideoPaginationManagerProtocol = {
        let repository = VideoRepository(networkService: networkService)
        let useCase = FetchPopularVideosUseCase(repository: repository)
        return VideoPaginationManager(useCase: useCase)
    }()

    public init(networkService: NetworkServiceProtocol, router: SharedRouterProtocol) {
        self.networkService = networkService
        self.router = router
    }

    public func build() -> UIViewController {
        let viewModel = HomeViewModel(paginationManager: paginationManager)
        viewModel.navigationDelegate = self
        return HomeViewController(viewModel: viewModel)
    }
}

extension HomeCoordinator: HomeViewModelNavigationDelegate {
    func homeViewModel(_ viewModel: HomeViewModel, didSelectVideoAt index: Int) {
        router.navigate(to: .videoFeed(startIndex: index), style: .push)
    }
}
