import UIKit
import NetworkLib
import LoggingLib
import UIComponents
import SharedRouterInterface
import SharedRouter
import Home
import VideoFeed
import SavedItems

final class CompositionRoot {
    private let networkService: NetworkServiceProtocol

    private(set) lazy var appConfigurator = AppConfigurator()

    private var router: SharedRouter!
    private var homeCoordinator: HomeCoordinator!
    private var videoFeedCoordinator: VideoFeedCoordinator!
    private var savedItemsCoordinator: SavedItemsCoordinator!

    init() {
        self.networkService = URLSessionNetworkService()
        networkService.configure(with: NetworkConfiguration(
            timeoutInterval: 30,
            logRequests: true,
            logResponses: true
        ))
    }

    func assembleAndStart() -> UIViewController {
        let homeNav = UINavigationController()
        homeNav.navigationBar.prefersLargeTitles = true
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let savedNav = UINavigationController()
        savedNav.navigationBar.prefersLargeTitles = true
        savedNav.tabBarItem = UITabBarItem(
            title: "Saved",
            image: UIImage(systemName: "bookmark"),
            selectedImage: UIImage(systemName: "bookmark.fill")
        )

        homeCoordinator = HomeCoordinator(
            networkService: networkService,
            router: LazyRouter { [weak self] in self?.router }
        )

        videoFeedCoordinator = VideoFeedCoordinator(
            router: LazyRouter { [weak self] in self?.router }
        )

        savedItemsCoordinator = SavedItemsCoordinator()

        router = SharedRouter(
            navigationController: homeNav,
            homeBuilder: homeCoordinator,
            videoFeedBuilder: videoFeedCoordinator,
            savedItemsBuilder: savedItemsCoordinator
        )

        homeNav.setViewControllers([homeCoordinator.build()], animated: false)
        savedNav.setViewControllers([savedItemsCoordinator.build()], animated: false)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeNav, savedNav]

        return tabBarController
    }

    func makeDeeplinkHandler() -> DeeplinkHandler {
        DeeplinkHandler(router: router)
    }
}

// MARK: - LazyRouter

/// Breaks the circular dependency between Router and Coordinators.
/// Coordinators are created with a LazyRouter that resolves to the real router after assembly.
private final class LazyRouter: SharedRouterProtocol {
    private let resolver: () -> SharedRouterProtocol?

    init(_ resolver: @escaping () -> SharedRouterProtocol?) {
        self.resolver = resolver
    }

    func navigate(to route: Route, style: NavigationStyle) {
        resolver()?.navigate(to: route, style: style)
    }

    func pop(animated: Bool) {
        resolver()?.pop(animated: animated)
    }
}
