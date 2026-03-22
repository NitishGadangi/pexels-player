import Foundation

public struct NetworkConfiguration {
    public let timeoutInterval: TimeInterval
    public let logRequests: Bool
    public let logResponses: Bool

    public init(
        timeoutInterval: TimeInterval = 30,
        logRequests: Bool = false,
        logResponses: Bool = false
    ) {
        self.timeoutInterval = timeoutInterval
        self.logRequests = logRequests
        self.logResponses = logResponses
    }
}
