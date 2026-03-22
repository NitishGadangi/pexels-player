import XCTest
import Combine
@testable import VideoFeed
import SharedModelsInterface

final class VideoFeedViewModelTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testBackTappedCallsDelegate() {
        let (sut, _, navDelegate) = makeSUT()
        sut.action.send(.backTapped)
        XCTAssertTrue(navDelegate.didRequestBack)
    }

    func testToggleMuteUpdatesMuteState() {
        let (sut, _, _) = makeSUT()
        XCTAssertFalse(sut.isMuted.value)
        sut.action.send(.toggleMute)
        XCTAssertTrue(sut.isMuted.value)
        sut.action.send(.toggleMute)
        XCTAssertFalse(sut.isMuted.value)
    }

    func testDidScrollToUpdatesCurrentIndex() {
        let (sut, _, _) = makeSUT()
        sut.action.send(.didScrollTo(index: 5))
        XCTAssertEqual(sut.currentIndex, 5)
    }

    func testTapQualityEmitsQualitySheet() {
        let videos = [makeVideo(id: 1)]
        let (sut, _, _) = makeSUT(stubbedVideos: videos)
        let expectation = expectation(description: "Quality sheet shown")

        sut.showQualitySheet
            .sink { files, quality in
                XCTAssertFalse(files.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.action.send(.tapQuality)
        waitForExpectations(timeout: 2)
    }

    // MARK: - Helpers

    private func makeSUT(
        stubbedVideos: [Video] = [makeVideo(id: 1)],
        startIndex: Int = 0
    ) -> (VideoFeedViewModel, StubPaginationManager, SpyNavigationDelegate) {
        let paginationManager = StubPaginationManager(stubbedVideos: stubbedVideos)
        let playerManager = VideoPlayerManager()
        let viewModel = VideoFeedViewModel(
            paginationManager: paginationManager,
            playerManager: playerManager,
            startIndex: startIndex
        )
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
    private let videosSubject: CurrentValueSubject<[Video], Never>

    var videos: [Video] { videosSubject.value }
    var videosPublisher: AnyPublisher<[Video], Never> { videosSubject.eraseToAnyPublisher() }
    var isLoading = false
    var hasMorePages = true

    init(stubbedVideos: [Video]) {
        self.videosSubject = CurrentValueSubject(stubbedVideos)
    }

    func loadNextPage() -> AnyPublisher<Void, Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Void, Error> {
        Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class SpyNavigationDelegate: VideoFeedNavigationDelegate {
    var didRequestBack = false

    func videoFeedDidRequestBack() {
        didRequestBack = true
    }
}
