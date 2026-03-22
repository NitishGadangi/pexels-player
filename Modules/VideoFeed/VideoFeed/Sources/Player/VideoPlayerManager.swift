import AVFoundation
import Combine
import UIKit
import SharedModelsInterface

final class VideoPlayerManager {
    enum PlaybackState {
        case idle
        case buffering(index: Int)
        case playing(index: Int)
        case paused(index: Int)
        case error(String, index: Int)
        case finished(index: Int)
    }

    let playbackState = CurrentValueSubject<PlaybackState, Never>(.idle)
    let progress = CurrentValueSubject<Double, Never>(0.0)

    private let pool: VideoPlayerPool
    let qualityService: QualityPreferenceService
    private(set) var isMuted = false
    private var currentIndex: Int?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    init(pool: VideoPlayerPool = VideoPlayerPool(), qualityService: QualityPreferenceService = QualityPreferenceService()) {
        self.pool = pool
        self.qualityService = qualityService
    }

    func prepareAndPlay(video: Video, at index: Int, in containerView: UIView) {
        guard let file = qualityService.bestFile(for: video),
              let url = URL(string: file.link) else {
            playbackState.send(.error("No playable video file found", index: index))
            return
        }

        cleanupCurrentObservers()
        currentIndex = index

        let (player, layer) = pool.player(for: index, currentVisibleIndex: index)
        layer.removeFromSuperlayer()
        layer.frame = containerView.bounds
        containerView.layer.insertSublayer(layer, at: 0)

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.isMuted = isMuted

        playbackState.send(.buffering(index: index))

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    player.play()
                    self.playbackState.send(.playing(index: index))
                case .failed:
                    let message = item.error?.localizedDescription ?? "Playback failed"
                    self.playbackState.send(.error(message, index: index))
                default:
                    break
                }
            }
        }

        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .sink { [weak self] _ in
                self?.playbackState.send(.finished(index: index))
            }
            .store(in: &cancellables)

        setupTimeObserver(for: player, item: item, index: index)
    }

    func pause(at index: Int) {
        let (player, _) = pool.player(for: index, currentVisibleIndex: index)
        player.pause()
        playbackState.send(.paused(index: index))
    }

    func resume(at index: Int) {
        let (player, _) = pool.player(for: index, currentVisibleIndex: index)
        player.play()
        playbackState.send(.playing(index: index))
    }

    func toggleMute() {
        isMuted.toggle()
        if let index = currentIndex {
            let (player, _) = pool.player(for: index, currentVisibleIndex: index)
            player.isMuted = isMuted
        }
    }

    func pauseAll() {
        pool.pauseAll()
    }

    func releaseAll() {
        cleanupCurrentObservers()
        pool.releaseAll()
        currentIndex = nil
    }

    func reloadCurrentVideo(video: Video, at index: Int, in containerView: UIView) {
        pool.releasePlayer(for: index)
        prepareAndPlay(video: video, at: index, in: containerView)
    }

    private func setupTimeObserver(for player: AVPlayer, item: AVPlayerItem, index: Int) {
        removeTimeObserver(from: player)
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let duration = player.currentItem?.duration,
                  duration.seconds.isFinite, duration.seconds > 0 else { return }
            self?.progress.send(time.seconds / duration.seconds)
        }
    }

    private func removeTimeObserver(from player: AVPlayer) {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func cleanupCurrentObservers() {
        statusObservation?.invalidate()
        statusObservation = nil
        cancellables.removeAll()
        if let index = currentIndex {
            let (player, _) = pool.player(for: index, currentVisibleIndex: index)
            removeTimeObserver(from: player)
        }
    }
}
