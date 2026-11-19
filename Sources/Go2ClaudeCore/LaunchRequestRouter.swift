import Foundation

public struct LaunchRequestRouter {
    public enum IncomingPathAction: Equatable {
        case deferUntilInitialLaunch
        case launchFinderCommand(explicitFinderPath: String?)
    }

    public enum InitialLaunchAction: Equatable {
        case openMainInterface
        case launchFinderCommand(explicitFinderPath: String?)
        case ignore
    }

    private struct PendingFinderLaunchRequest: Equatable {
        let explicitFinderPath: String?
    }

    private var pendingFinderLaunchRequest: PendingFinderLaunchRequest?
    private var hasCompletedInitialLaunch = false

    public init() {}

    public mutating func receiveIncomingFinderPath(_ explicitFinderPath: String?) -> IncomingPathAction {
        guard hasCompletedInitialLaunch else {
            pendingFinderLaunchRequest = PendingFinderLaunchRequest(explicitFinderPath: explicitFinderPath)
            return .deferUntilInitialLaunch
        }

        return .launchFinderCommand(explicitFinderPath: explicitFinderPath)
    }

    public mutating func consumeInitialLaunch(mode: LaunchMode) -> InitialLaunchAction {
        guard !hasCompletedInitialLaunch else {
            return .ignore
        }

        hasCompletedInitialLaunch = true
        if let pendingFinderLaunchRequest {
            return .launchFinderCommand(explicitFinderPath: pendingFinderLaunchRequest.explicitFinderPath)
        }

        switch mode {
        case .mainInterface, .configuration:
            return .openMainInterface
        case .openCurrentFinderPath:
            return .launchFinderCommand(explicitFinderPath: nil)
        }
    }
}
