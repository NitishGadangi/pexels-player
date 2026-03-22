import Foundation

public protocol CacheProtocol {
    associatedtype Value
    func store(_ value: Value, forKey key: String)
    func retrieve(forKey key: String) -> Value?
    func remove(forKey key: String)
    func removeAll()
}
