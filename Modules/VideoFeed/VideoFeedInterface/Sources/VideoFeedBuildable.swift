import UIKit
import SharedModelsInterface

public protocol VideoFeedBuildable: AnyObject {
    func build(paginationManager: VideoPaginationManagerProtocol, startIndex: Int) -> UIViewController
}
