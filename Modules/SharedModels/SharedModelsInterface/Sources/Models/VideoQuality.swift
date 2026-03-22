import Foundation

public enum VideoQuality: String, CaseIterable {
    case sd
    case hd
    case uhd
    case hls

    public var displayName: String {
        switch self {
        case .sd: return "SD"
        case .hd: return "HD"
        case .uhd: return "UHD"
        case .hls: return "HLS"
        }
    }
}
