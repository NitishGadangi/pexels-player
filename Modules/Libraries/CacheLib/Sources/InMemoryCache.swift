import Foundation

private final class NSCacheEntry<V> {
    let value: V
    init(_ value: V) { self.value = value }
}

public final class InMemoryCache<V>: CacheProtocol {
    private let cache = NSCache<NSString, NSCacheEntry<V>>()

    public init(countLimit: Int = 100) {
        cache.countLimit = countLimit
    }

    public func store(_ value: V, forKey key: String) {
        cache.setObject(NSCacheEntry(value), forKey: key as NSString)
    }

    public func retrieve(forKey key: String) -> V? {
        cache.object(forKey: key as NSString)?.value
    }

    public func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    public func removeAll() {
        cache.removeAllObjects()
    }
}
