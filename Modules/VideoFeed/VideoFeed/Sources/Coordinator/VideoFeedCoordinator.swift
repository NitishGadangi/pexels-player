import UIKit
import VideoFeedInterface
import SharedModelsInterface
import SharedRouterInterface

public final class VideoFeedCoordinator: VideoFeedBuildable {
    private let router: SharedRouterProtocol
    private weak var presentingViewController: UIViewController?

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
        let vc = VideoFeedViewController(viewModel: viewModel)
        presentingViewController = vc
        return vc
    }
}

extension VideoFeedCoordinator: VideoFeedNavigationDelegate {
    func videoFeedDidRequestBack() {
        router.pop(animated: true)
    }

    func videoFeedDidRequestQualitySheet(
        videoFiles: [VideoFile],
        currentQuality: VideoQuality,
        onSelect: @escaping (VideoQuality) -> Void
    ) {
        let vc = QualityBottomSheetViewController(
            videoFiles: videoFiles,
            currentQuality: currentQuality,
            onSelect: onSelect
        )
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        presentingViewController?.present(vc, animated: true)
    }
}
