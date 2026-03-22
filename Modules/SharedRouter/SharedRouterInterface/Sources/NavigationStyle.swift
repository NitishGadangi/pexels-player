import UIKit

public enum NavigationStyle {
    case push
    case present(UIModalPresentationStyle = .fullScreen)
    case setRoot
}
