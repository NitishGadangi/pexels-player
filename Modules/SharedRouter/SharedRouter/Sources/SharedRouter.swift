import UIKit
import SharedRouterInterface
import HomeInterface
import VideoFeedInterface
import SavedItemsInterface

public final class SharedRouter: SharedRouterProtocol {
    private weak var navigationController: UINavigationController?
    private let homeBuilder: HomeBuildable
    private let videoFeedBuilder: VideoFeedBuildable
    private let savedItemsBuilder: SavedItemsBuildable

    public init(
        navigationController: UINavigationController,
        homeBuilder: HomeBuildable,
        videoFeedBuilder: VideoFeedBuildable,
        savedItemsBuilder: SavedItemsBuildable
    ) {
        self.navigationController = navigationController
        self.homeBuilder = homeBuilder
        self.videoFeedBuilder = videoFeedBuilder
        self.savedItemsBuilder = savedItemsBuilder
    }

    public func navigate(to route: Route, style: NavigationStyle) {
        let viewController = buildViewController(for: route)
        guard let viewController else { return }

        switch style {
        case .push:
            navigationController?.pushViewController(viewController, animated: true)
        case .present(let presentationStyle):
            viewController.modalPresentationStyle = presentationStyle
            navigationController?.present(viewController, animated: true)
        case .setRoot:
            navigationController?.setViewControllers([viewController], animated: true)
        }
    }

    public func pop(animated: Bool) {
        navigationController?.popViewController(animated: animated)
    }

    private func buildViewController(for route: Route) -> UIViewController? {
        switch route {
        case .home:
            return homeBuilder.build()
        case .videoFeed(let startIndex):
            return videoFeedBuilder.build(
                paginationManager: homeBuilder.paginationManager,
                startIndex: startIndex
            )
        case .savedItems:
            return savedItemsBuilder.build()
        }
    }
}
