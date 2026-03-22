import UIKit
import CacheLib

public class RemoteImageView: UIImageView {
    private var currentURL: String?
    private var currentTask: URLSessionDataTask?
    private let cache: TwoTierImageCache

    public init(cache: TwoTierImageCache = .shared) {
        self.cache = cache
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func loadImage(from urlString: String, placeholder: UIImage? = nil) {
        cancelLoad()
        currentURL = urlString
        image = placeholder

        if let cached = cache.retrieve(forKey: urlString) {
            image = cached
            return
        }

        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let downloaded = UIImage(data: data) else { return }
            self.cache.store(downloaded, forKey: urlString)
            DispatchQueue.main.async {
                guard self.currentURL == urlString else { return }
                self.image = downloaded
            }
        }
        currentTask = task
        task.resume()
    }

    public func cancelLoad() {
        currentTask?.cancel()
        currentTask = nil
        currentURL = nil
    }
}
