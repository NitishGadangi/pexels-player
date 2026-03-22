import UIKit

public protocol SavedItemsBuildable: AnyObject {
    func build() -> UIViewController
}
