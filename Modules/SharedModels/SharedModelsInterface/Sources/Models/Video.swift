import Foundation

public struct Video: Equatable, Identifiable, Decodable {
    public let id: Int
    public let width: Int
    public let height: Int
    public let duration: Int
    public let image: String
    public let user: VideoUser
    public let videoFiles: [VideoFile]

    enum CodingKeys: String, CodingKey {
        case id, width, height, duration, image, user
        case videoFiles = "video_files"
    }

    public init(
        id: Int,
        width: Int,
        height: Int,
        duration: Int,
        image: String,
        user: VideoUser,
        videoFiles: [VideoFile]
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.duration = duration
        self.image = image
        self.user = user
        self.videoFiles = videoFiles
    }
}

public struct VideoUser: Equatable, Decodable {
    public let id: Int
    public let name: String
    public let url: String

    public init(id: Int, name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
}

public struct VideoFile: Equatable, Decodable {
    public let id: Int
    public let quality: String
    public let fileType: String
    public let width: Int?
    public let height: Int?
    public let fps: Double?
    public let link: String

    enum CodingKeys: String, CodingKey {
        case id, quality, width, height, fps, link
        case fileType = "file_type"
    }

    public init(
        id: Int,
        quality: String,
        fileType: String,
        width: Int?,
        height: Int?,
        fps: Double?,
        link: String
    ) {
        self.id = id
        self.quality = quality
        self.fileType = fileType
        self.width = width
        self.height = height
        self.fps = fps
        self.link = link
    }
}
