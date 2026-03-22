import UIKit

public protocol SharedRouterProtocol: AnyObject {
    func navigate(to route: Route, style: NavigationStyle)
    func pop(animated: Bool)
}
