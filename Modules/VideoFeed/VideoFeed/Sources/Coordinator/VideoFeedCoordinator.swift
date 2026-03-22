import UIKit
import VideoFeedInterface
import SharedModelsInterface
import SharedRouterInterface

public final class VideoFeedCoordinator: VideoFeedBuildable {
    private let router: SharedRouterProtocol

    public init(router: SharedRouterProtocol) {
        self.router = router
    }

    public func build(paginationManager: VideoPaginationManagerProtocol, startIndex: Int) -> UIViewController {
        let playerManager = VideoPlayerManager()
        let viewModel = VideoFeedViewModel(
            paginationManager: paginationManager,
            playerManager: playerManager,
            startIndex: startIndex
        )
        viewModel.navigationDelegate = self
        return VideoFeedViewController(viewModel: viewModel)
    }
}

extension VideoFeedCoordinator: VideoFeedNavigationDelegate {
    func videoFeedDidRequestBack() {
        router.pop(animated: true)
    }
}
