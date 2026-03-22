import XCTest
import Combine
@testable import Home
import SharedModelsInterface
import NetworkLib

final class HomeViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testViewDidLoadTriggersLoading() {
        let (sut, _, _) = makeSUT()
        let expectation = expectation(description: "State becomes loading")

        sut.statePublisher
            .dropFirst()
            .first()
            .sink { state in
                if case .loading = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.action.send(.viewDidLoad)
        waitForExpectations(timeout: 2)
    }

    func testDidSelectVideoCallsDelegate() {
        let (sut, _, navDelegate) = makeSUT()
        sut.action.send(.didSelectVideo(index: 3))

        XCTAssertEqual(navDelegate.selectedIndices, [3])
    }

    func testLoadedStateAfterSuccessfulFetch() {
        let videos = [makeVideo(id: 1), makeVideo(id: 2)]
        let (sut, _, _) = makeSUT(stubbedVideos: videos)
        let expectation = expectation(description: "State becomes loaded")

        sut.statePublisher
            .drop(while: { state in
                if case .loaded = state { return false }
                return true
            })
            .first()
            .sink { state in
                if case .loaded(let loadedVideos) = state {
                    XCTAssertEqual(loadedVideos.count, 2)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.action.send(.viewDidLoad)
        waitForExpectations(timeout: 2)
    }

    func testErrorStateOnFetchFailure() {
        let (sut, _, _) = makeSUT(shouldFail: true)
        let expectation = expectation(description: "State becomes error")

        sut.statePublisher
            .drop(while: { state in
                if case .error = state { return false }
                return true
            })
            .first()
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        sut.action.send(.viewDidLoad)
        waitForExpectations(timeout: 2)
    }

    // MARK: - Helpers

    private func makeSUT(
        stubbedVideos: [Video] = [makeVideo(id: 1)],
        shouldFail: Bool = false
    ) -> (HomeViewModel, StubPaginationManager, SpyNavigationDelegate) {
        let paginationManager = StubPaginationManager(stubbedVideos: stubbedVideos, shouldFail: shouldFail)
        let viewModel = HomeViewModel(paginationManager: paginationManager)
        let navDelegate = SpyNavigationDelegate()
        viewModel.navigationDelegate = navDelegate
        return (viewModel, paginationManager, navDelegate)
    }
}

private func makeVideo(id: Int) -> Video {
    Video(
        id: id,
        width: 1920,
        height: 1080,
        duration: 30,
        image: "https://example.com/thumb.jpg",
        user: VideoUser(id: 1, name: "Test User", url: "https://example.com"),
        videoFiles: [
            VideoFile(id: 1, quality: "hd", fileType: "video/mp4", width: 1920, height: 1080, fps: 30, link: "https://example.com/video.mp4")
        ]
    )
}

private final class StubPaginationManager: VideoPaginationManagerProtocol {
    private let stubbedVideos: [Video]
    private let shouldFail: Bool
    private let videosSubject: CurrentValueSubject<[Video], Never>

    var videos: [Video] { videosSubject.value }
    var videosPublisher: AnyPublisher<[Video], Never> { videosSubject.eraseToAnyPublisher() }
    var isLoading = false
    var hasMorePages = true

    init(stubbedVideos: [Video], shouldFail: Bool = false) {
        self.stubbedVideos = stubbedVideos
        self.shouldFail = shouldFail
        self.videosSubject = CurrentValueSubject([])
    }

    func loadNextPage() -> AnyPublisher<Void, Error> {
        if shouldFail {
            return Fail(error: NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
                .eraseToAnyPublisher()
        }
        videosSubject.send(stubbedVideos)
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        loadNextPage()
    }
}

private final class SpyNavigationDelegate: HomeViewModelNavigationDelegate {
    var selectedIndices: [Int] = []

    func homeViewModel(_ viewModel: HomeViewModel, didSelectVideoAt index: Int) {
        selectedIndices.append(index)
    }
}
