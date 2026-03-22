import Foundation
import Combine
import SharedModelsInterface

protocol VideoFeedNavigationDelegate: AnyObject {
    func videoFeedDidRequestBack()
    func videoFeedDidRequestQualitySheet(
        videoFiles: [VideoFile],
        currentQuality: VideoQuality,
        onSelect: @escaping (VideoQuality) -> Void
    )
}

final class VideoFeedViewModel {
    enum Action {
        case viewDidLoad
        case didScrollTo(index: Int)
        case togglePlayPause
        case toggleMute
        case tapQuality
        case selectQuality(VideoQuality)
        case backTapped
        case didDismissError
    }

    enum State: Equatable {
        case idle
        case playing(index: Int)
        case buffering(index: Int)
        case paused(index: Int)
        case error(String, index: Int)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.playing(let a), .playing(let b)): return a == b
            case (.buffering(let a), .buffering(let b)): return a == b
            case (.paused(let a), .paused(let b)): return a == b
            case (.error(let ma, let ia), .error(let mb, let ib)): return ma == mb && ia == ib
            default: return false
            }
        }
    }

    let actionHandler = PassthroughSubject<Action, Never>()
    private let state = CurrentValueSubject<State, Never>(.idle)
    var statePublisher: AnyPublisher<State, Never> { state.eraseToAnyPublisher() }
    let isMuted = CurrentValueSubject<Bool, Never>(true)
    let playbackProgress = CurrentValueSubject<Double, Never>(0.0)
    let autoAdvance = PassthroughSubject<Int, Never>()
    let prepareVideo = PassthroughSubject<(Video, Int), Never>()
    let reloadData = PassthroughSubject<Void, Never>()

    weak var navigationDelegate: VideoFeedNavigationDelegate?

    let playerManager: VideoPlayerManager
    let startIndex: Int
    private(set) var currentIndex: Int
    private let paginationManager: VideoPaginationManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    var numberOfItems: Int { paginationManager.videos.count }

    func video(at index: Int) -> Video? {
        let videos = paginationManager.videos
        guard index < videos.count else { return nil }
        return videos[index]
    }

    init(
        paginationManager: VideoPaginationManagerProtocol,
        playerManager: VideoPlayerManager,
        startIndex: Int
    ) {
        self.paginationManager = paginationManager
        self.playerManager = playerManager
        self.startIndex = startIndex
        self.currentIndex = startIndex
        bindActions()
        bindPlayerState()
        bindVideos()
    }

    private func bindActions() {
        actionHandler
            .sink { [weak self] action in self?.handleAction(action) }
            .store(in: &cancellables)
    }

    private func bindVideos() {
        paginationManager.videosPublisher
            .sink { [weak self] videos in
                guard let self, !videos.isEmpty else { return }
                self.reloadData.send()
            }
            .store(in: &cancellables)
    }

    private func bindPlayerState() {
        playerManager.playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playbackState in
                guard let self else { return }
                switch playbackState {
                case .idle:
                    break
                case .buffering(let index):
                    guard index == self.currentIndex else { return }
                    self.state.send(.buffering(index: index))
                case .playing(let index):
                    guard index == self.currentIndex else { return }
                    self.state.send(.playing(index: index))
                case .paused(let index):
                    guard index == self.currentIndex else { return }
                    self.state.send(.paused(index: index))
                case .error(let msg, let index):
                    guard index == self.currentIndex else { return }
                    self.state.send(.error(msg, index: index))
                case .finished(let index):
                    guard index == self.currentIndex else { return }
                    let nextIndex = index + 1
                    if nextIndex < self.numberOfItems {
                        self.autoAdvance.send(nextIndex)
                    }
                }
            }
            .store(in: &cancellables)

        playerManager.progress
            .assign(to: \.value, on: playbackProgress)
            .store(in: &cancellables)
    }

    private func handleAction(_ action: Action) {
        switch action {
        case .viewDidLoad:
            currentIndex = startIndex

        case .didScrollTo(let index):
            currentIndex = index
            playCurrentVideo()
            checkPagination()

        case .togglePlayPause:
            switch state.value {
            case .playing(let index):
                playerManager.pause(at: index)
            case .paused(let index):
                playerManager.resume(at: index)
            default:
                break
            }

        case .toggleMute:
            playerManager.toggleMute()
            isMuted.send(playerManager.isMuted)

        case .tapQuality:
            guard let video = video(at: currentIndex) else { return }
            navigationDelegate?.videoFeedDidRequestQualitySheet(
                videoFiles: video.videoFiles,
                currentQuality: playerManager.qualityService.currentQuality
            ) { [weak self] selectedQuality in
                self?.actionHandler.send(.selectQuality(selectedQuality))
            }

        case .selectQuality(let quality):
            playerManager.qualityService.currentQuality = quality
            playCurrentVideo()

        case .backTapped:
            playerManager.pauseAll()
            navigationDelegate?.videoFeedDidRequestBack()

        case .didDismissError:
            let nextIndex = currentIndex + 1
            if nextIndex < numberOfItems {
                autoAdvance.send(nextIndex)
            }
        }
    }

    private func playCurrentVideo() {
        playerManager.pauseAll()
        guard let video = video(at: currentIndex) else { return }
        prepareVideo.send((video, currentIndex))
    }

    private func checkPagination() {
        if currentIndex >= numberOfItems - 5, paginationManager.hasMorePages, !paginationManager.isLoading {
            paginationManager.loadNextPage()
                .sink(receiveCompletion: { _ in }, receiveValue: { })
                .store(in: &cancellables)
        }
    }
}
