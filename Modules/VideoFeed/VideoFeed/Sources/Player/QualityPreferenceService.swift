import Foundation
import SharedModelsInterface

final class QualityPreferenceService {
    private let defaults: UserDefaults
    private let key = "com.pexelsplayer.selectedVideoQuality"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentQuality: VideoQuality {
        get {
            guard let raw = defaults.string(forKey: key),
                  let quality = VideoQuality(rawValue: raw) else {
                return .hd
            }
            return quality
        }
        set {
            defaults.set(newValue.rawValue, forKey: key)
        }
    }

    func bestFile(for video: Video) -> VideoFile? {
        let mp4Files = video.videoFiles.filter { $0.fileType == "video/mp4" }
        guard !mp4Files.isEmpty else { return video.videoFiles.first }

        let preferred = mp4Files.filter { $0.quality == currentQuality.rawValue }
        if let file = preferred.first { return file }

        let fallbackOrder: [VideoQuality] = {
            switch currentQuality {
            case .hd: return [.sd, .uhd]
            case .sd: return [.hd, .uhd]
            case .uhd: return [.hd, .sd]
            case .hls: return [.hd, .sd, .uhd]
            }
        }()

        for quality in fallbackOrder {
            if let file = mp4Files.first(where: { $0.quality == quality.rawValue }) {
                return file
            }
        }

        return mp4Files.first
    }
}
