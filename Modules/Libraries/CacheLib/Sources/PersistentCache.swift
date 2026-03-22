import Foundation

public final class PersistentCache: CacheProtocol {
    public typealias Value = Data

    private let directory: URL
    private let queue = DispatchQueue(label: "com.modularshop.persistentcache", attributes: .concurrent)

    public init(subdirectory: String = "ImageCache") {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = caches.appendingPathComponent(subdirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func store(_ value: Data, forKey key: String) {
        let fileURL = fileURL(for: key)
        queue.async(flags: .barrier) {
            try? value.write(to: fileURL, options: .atomic)
        }
    }

    public func retrieve(forKey key: String) -> Data? {
        let fileURL = fileURL(for: key)
        var result: Data?
        queue.sync {
            result = try? Data(contentsOf: fileURL)
        }
        return result
    }

    public func remove(forKey key: String) {
        let fileURL = fileURL(for: key)
        queue.async(flags: .barrier) {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    public func removeAll() {
        queue.async(flags: .barrier) {
            try? FileManager.default.removeItem(at: self.directory)
            try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        }
    }

    private func fileURL(for key: String) -> URL {
        let sanitized = key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
        return directory.appendingPathComponent(sanitized)
    }
}
