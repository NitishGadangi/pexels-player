import Foundation
import Combine

public protocol VideoPaginationManagerProtocol: AnyObject {
    var videos: [Video] { get }
    var videosPublisher: AnyPublisher<[Video], Never> { get }
    var isLoading: Bool { get }
    var hasMorePages: Bool { get }
    func loadNextPage() -> AnyPublisher<Void, Error>
    func refresh() -> AnyPublisher<Void, Error>
}
