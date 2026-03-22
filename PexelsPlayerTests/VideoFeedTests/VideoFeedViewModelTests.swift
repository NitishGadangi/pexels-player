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
        sut.actionHandler.send(.backTapped)
        XCTAssertTrue(navDelegate.didRequestBack)
    }

    func testToggleMuteUpdatesMuteState() {
        let (sut, _, _) = makeSUT()
        XCTAssertTrue(sut.isMuted.value)
        sut.actionHandler.send(.toggleMute)
        XCTAssertFalse(sut.isMuted.value)
        sut.actionHandler.send(.toggleMute)
        XCTAssertTrue(sut.isMuted.value)
    }

    func testDidScrollToUpdatesCurrentIndex() {
        let (sut, _, _) = makeSUT()
        sut.actionHandler.send(.didScrollTo(index: 5))
        XCTAssertEqual(sut.currentIndex, 5)
    }

    func testTapQualityCallsDelegate() {
        let videos = [makeVideo(id: 1)]
        let (sut, _, navDelegate) = makeSUT(stubbedVideos: videos)
        sut.actionHandler.send(.tapQuality)
        XCTAssertTrue(navDelegate.didRequestQualitySheet)
    }

    func testNumberOfItemsMatchesPaginationManager() {
        let videos = [makeVideo(id: 1), makeVideo(id: 2)]
        let (sut, _, _) = makeSUT(stubbedVideos: videos)
        XCTAssertEqual(sut.numberOfItems, 2)
    }

    func testVideoAtIndexReturnsCorrectVideo() {
        let videos = [makeVideo(id: 10), makeVideo(id: 20)]
        let (sut, _, _) = makeSUT(stubbedVideos: videos)
        XCTAssertEqual(sut.video(at: 0)?.id, 10)
        XCTAssertEqual(sut.video(at: 1)?.id, 20)
        XCTAssertNil(sut.video(at: 5))
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
    var didRequestQualitySheet = false

    func videoFeedDidRequestBack() {
        didRequestBack = true
    }

    func videoFeedDidRequestQualitySheet(
        videoFiles: [VideoFile],
        currentQuality: VideoQuality,
        onSelect: @escaping (VideoQuality) -> Void
    ) {
        didRequestQualitySheet = true
    }
}
