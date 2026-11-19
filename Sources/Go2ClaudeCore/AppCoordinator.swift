import Foundation

public struct AppCoordinator {
    public enum LaunchResult: Equatable {
        case terminate
        case openSettings(message: String?)
    }

    private static let claudeCommandTemplate = "cd %PATH% && claude"

    private let settings: AppSettings
    private let finderPathResolver: FinderPathResolving
    private let commandRenderer: CommandTemplateRenderer
    private let terminalLauncher: TerminalLaunching

    public init(
        settings: AppSettings,
        finderPathResolver: FinderPathResolving,
        commandRenderer: CommandTemplateRenderer,
        terminalLauncher: TerminalLaunching
    ) {
        self.settings = settings
        self.finderPathResolver = finderPathResolver
        self.commandRenderer = commandRenderer
        self.terminalLauncher = terminalLauncher
    }

    public func launchCurrentFinderPath(explicitFinderPath: String? = nil) throws {
        try launchCommandTemplate(settings.commandTemplate, explicitFinderPath: explicitFinderPath)
    }

    public func launchClaudeCurrentFinderPath(explicitFinderPath: String? = nil) throws {
        try launchCommandTemplate(Self.claudeCommandTemplate, explicitFinderPath: explicitFinderPath)
    }

    public func launchCommandTemplate(_ template: String, explicitFinderPath: String? = nil) throws {
        let finderPath = try resolveFinderPath(explicitFinderPath)
        let command = try commandRenderer.render(
            template: template,
            finderPath: finderPath
        )
        try terminalLauncher.launch(command: command)
    }

    public func launchShellCommand(_ command: String) throws {
        try terminalLauncher.launch(command: command)
    }

    public func handleLaunch(mode: LaunchMode, explicitFinderPath: String? = nil) -> LaunchResult {
        switch mode {
        case .mainInterface, .configuration:
            return .openSettings(message: nil)
        case .openCurrentFinderPath:
            do {
                try launchCurrentFinderPath(explicitFinderPath: explicitFinderPath)
                return .terminate
            } catch {
                return .openSettings(message: error.localizedDescription)
            }
        }
    }

    private func resolveFinderPath(_ explicitFinderPath: String?) throws -> String {
        if let explicitFinderPath, !explicitFinderPath.isEmpty {
            return explicitFinderPath
        }

        return try finderPathResolver.resolveCurrentFinderPath()
    }
}
