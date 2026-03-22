import UIKit
import VideoFeedInterface
import SharedModelsInterface
import SharedRouterInterface

public final class VideoFeedCoordinator: VideoFeedBuildable {
    private weak var navigationController: UINavigationController?

    public init() {}

    public func build(paginationManager: VideoPaginationManagerProtocol, startIndex: Int) -> UIViewController {
        let playerManager = VideoPlayerManager()
        let viewModel = VideoFeedViewModel(
            paginationManager: paginationManager,
            playerManager: playerManager,
            startIndex: startIndex
        )
        viewModel.navigationDelegate = self
        let vc = VideoFeedViewController(viewModel: viewModel)
        return vc
    }

    public func setNavigationController(_ nav: UINavigationController?) {
        self.navigationController = nav
    }
}

extension VideoFeedCoordinator: VideoFeedNavigationDelegate {
    func videoFeedDidRequestBack() {
        navigationController?.popViewController(animated: true)
    }
}
