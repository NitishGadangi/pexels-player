import UIKit
import SavedItemsInterface

public final class SavedItemsCoordinator: SavedItemsBuildable {
    public init() {}

    public func build() -> UIViewController {
        SavedItemsViewController()
    }
}
