import UIKit
import SharedModelsInterface

public protocol HomeBuildable: AnyObject {
    var paginationManager: VideoPaginationManagerProtocol { get }
    func build() -> UIViewController
}
