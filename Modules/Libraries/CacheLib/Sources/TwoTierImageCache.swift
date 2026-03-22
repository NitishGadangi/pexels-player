import UIKit

public final class TwoTierImageCache {
    public static let shared = TwoTierImageCache()

    private let l1: InMemoryCache<UIImage>
    private let l2: PersistentCache

    public init(memoryCountLimit: Int = 100) {
        self.l1 = InMemoryCache(countLimit: memoryCountLimit)
        self.l2 = PersistentCache(subdirectory: "ImageCache")
    }

    public func store(_ image: UIImage, forKey key: String) {
        l1.store(image, forKey: key)
        if let data = image.pngData() {
            l2.store(data, forKey: key)
        }
    }

    public func retrieve(forKey key: String) -> UIImage? {
        if let image = l1.retrieve(forKey: key) {
            return image
        }
        if let data = l2.retrieve(forKey: key), let image = UIImage(data: data) {
            l1.store(image, forKey: key)
            return image
        }
        return nil
    }

    public func remove(forKey key: String) {
        l1.remove(forKey: key)
        l2.remove(forKey: key)
    }

    public func removeAll() {
        l1.removeAll()
        l2.removeAll()
    }

    public func clearCacheIfNeeded() {
        // TODO: Implement cache clearing logic based on config/version policy
    }
}
