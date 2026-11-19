import Foundation

public enum LaunchMode: Equatable {
    case mainInterface
    case openCurrentFinderPath
    case configuration

    public init(arguments: [String]) {
        if arguments.dropFirst().contains(where: { $0.caseInsensitiveCompare("config") == .orderedSame }) {
            self = .configuration
        } else {
            self = .mainInterface
        }
    }
}
