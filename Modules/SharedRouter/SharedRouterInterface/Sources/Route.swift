import Foundation

public enum Route: Equatable {
    case home
    case videoFeed(startIndex: Int)
    case savedItems
}
