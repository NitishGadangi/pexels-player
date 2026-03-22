import Foundation
import Combine
import SharedModelsInterface

protocol VideoFeedNavigationDelegate: AnyObject {
    func videoFeedDidRequestBack()
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

    let action = PassthroughSubject<Action, Never>()
    let state = CurrentValueSubject<State, Never>(.idle)
    let isMuted = CurrentValueSubject<Bool, Never>(false)
    let playbackProgress = CurrentValueSubject<Double, Never>(0.0)
    let showQualitySheet = PassthroughSubject<([VideoFile], VideoQuality), Never>()
    let autoAdvance = PassthroughSubject<Int, Never>()
    let prepareVideo = PassthroughSubject<(Video, Int), Never>()

    weak var navigationDelegate: VideoFeedNavigationDelegate?

    let paginationManager: VideoPaginationManagerProtocol
    let playerManager: VideoPlayerManager
    let startIndex: Int
    private(set) var currentIndex: Int
    private var cancellables = Set<AnyCancellable>()

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
    }

    private func bindActions() {
        action
            .sink { [weak self] action in self?.handleAction(action) }
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
                    self.state.send(.buffering(index: index))
                case .playing(let index):
                    self.state.send(.playing(index: index))
                case .paused(let index):
                    self.state.send(.paused(index: index))
                case .error(let msg, let index):
                    self.state.send(.error(msg, index: index))
                case .finished(let index):
                    let nextIndex = index + 1
                    if nextIndex < self.paginationManager.videos.count {
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
            playCurrentVideo()

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
            let videos = paginationManager.videos
            guard currentIndex < videos.count else { return }
            let video = videos[currentIndex]
            showQualitySheet.send((video.videoFiles, playerManager.qualityService.currentQuality))

        case .selectQuality(let quality):
            playerManager.qualityService.currentQuality = quality

        case .backTapped:
            playerManager.pauseAll()
            navigationDelegate?.videoFeedDidRequestBack()

        case .didDismissError:
            let nextIndex = currentIndex + 1
            if nextIndex < paginationManager.videos.count {
                autoAdvance.send(nextIndex)
            }
        }
    }

    private func playCurrentVideo() {
        let videos = paginationManager.videos
        guard currentIndex < videos.count else { return }
        let video = videos[currentIndex]
        prepareVideo.send((video, currentIndex))
    }

    private func checkPagination() {
        let videos = paginationManager.videos
        if currentIndex >= videos.count - 5, paginationManager.hasMorePages, !paginationManager.isLoading {
            paginationManager.loadNextPage()
                .sink(receiveCompletion: { _ in }, receiveValue: { })
                .store(in: &cancellables)
        }
    }
}
