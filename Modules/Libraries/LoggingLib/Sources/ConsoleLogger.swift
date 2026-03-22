import Foundation

public final class ConsoleLogger: LoggerProtocol {
    public var minimumLevel: LogLevel

    public init(minimumLevel: LogLevel = .debug) {
        self.minimumLevel = minimumLevel
    }

    public func log(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        guard level >= minimumLevel else { return }
        let fileName = (file as NSString).lastPathComponent
        print("\(level.prefix) [\(fileName):\(line)] \(function) - \(message)")
    }
}
