import AVFoundation
import UIKit

final class VideoPlayerPool {
    private struct PlayerEntry {
        let player: AVPlayer
        let layer: AVPlayerLayer
        var assignedIndex: Int?
    }

    private var entries: [PlayerEntry]
    private let poolSize = 3

    init() {
        entries = (0..<3).map { _ in
            let player = AVPlayer()
            player.automaticallyWaitsToMinimizeStalling = true
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            return PlayerEntry(player: player, layer: layer, assignedIndex: nil)
        }
    }

    func player(for videoIndex: Int, currentVisibleIndex: Int) -> (AVPlayer, AVPlayerLayer) {
        if let idx = entries.firstIndex(where: { $0.assignedIndex == videoIndex }) {
            return (entries[idx].player, entries[idx].layer)
        }

        if let idx = entries.firstIndex(where: { $0.assignedIndex == nil }) {
            entries[idx].assignedIndex = videoIndex
            return (entries[idx].player, entries[idx].layer)
        }

        let idx = entries.enumerated()
            .max(by: { abs(($0.element.assignedIndex ?? 0) - currentVisibleIndex) < abs(($1.element.assignedIndex ?? 0) - currentVisibleIndex) })!
            .offset

        entries[idx].player.pause()
        entries[idx].player.replaceCurrentItem(with: nil)
        entries[idx].layer.removeFromSuperlayer()
        entries[idx].assignedIndex = videoIndex
        return (entries[idx].player, entries[idx].layer)
    }

    func releasePlayer(for videoIndex: Int) {
        guard let idx = entries.firstIndex(where: { $0.assignedIndex == videoIndex }) else { return }
        entries[idx].player.pause()
        entries[idx].player.replaceCurrentItem(with: nil)
        entries[idx].layer.removeFromSuperlayer()
        entries[idx].assignedIndex = nil
    }

    func pauseAll() {
        entries.forEach { $0.player.pause() }
    }

    func releaseAll() {
        for i in entries.indices {
            entries[i].player.pause()
            entries[i].player.replaceCurrentItem(with: nil)
            entries[i].layer.removeFromSuperlayer()
            entries[i].assignedIndex = nil
        }
    }
}
