import Foundation

public struct PaginatedVideoResponse: Decodable {
    public let page: Int
    public let perPage: Int
    public let totalResults: Int
    public let url: String
    public let videos: [Video]

    enum CodingKeys: String, CodingKey {
        case page, url, videos
        case perPage = "per_page"
        case totalResults = "total_results"
    }

    public init(
        page: Int,
        perPage: Int,
        totalResults: Int,
        url: String,
        videos: [Video]
    ) {
        self.page = page
        self.perPage = perPage
        self.totalResults = totalResults
        self.url = url
        self.videos = videos
    }
}
