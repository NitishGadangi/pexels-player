import UIKit

public final class LazyRouter: SharedRouterProtocol {
    public weak var router: SharedRouterProtocol?

    public init() {}

    public func navigate(to route: Route, style: NavigationStyle) {
        router?.navigate(to: route, style: style)
    }
}
