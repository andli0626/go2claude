import XCTest
@testable import Go2ClaudeCore

final class AppCoordinatorTests: XCTestCase {
    func test_mainInterfaceModeOpensSettingsWithoutAttemptingLaunch() {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        let resolver = FinderPathResolverStub(result: .success("/tmp"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        let result = coordinator.handleLaunch(mode: .mainInterface)

        XCTAssertEqual(result, .openSettings(message: nil))
        XCTAssertEqual(resolver.invocationCount, 0)
        XCTAssertEqual(launcher.launchedCommands, [])
    }

    func test_launchClaudeCurrentFinderPathAlwaysOpensClaude() throws {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        settings.commandTemplate = "cd %PATH% && pwd"
        let resolver = FinderPathResolverStub(result: .success("/Users/lilin/Downloads/Demo Folder"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        try coordinator.launchClaudeCurrentFinderPath()

        XCTAssertEqual(launcher.launchedCommands, ["cd '/Users/lilin/Downloads/Demo Folder' && claude"])
    }

    func test_manualLaunchCurrentFinderPathRunsRenderedCommand() throws {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        settings.commandTemplate = "cd %PATH% && claude"
        let resolver = FinderPathResolverStub(result: .success("/Users/lilin/Downloads/Demo Folder"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        try coordinator.launchCurrentFinderPath()

        XCTAssertEqual(launcher.launchedCommands, ["cd '/Users/lilin/Downloads/Demo Folder' && claude"])
    }

    func test_launchCommandTemplateRendersResolvedFinderPath() throws {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        let resolver = FinderPathResolverStub(result: .success("/Users/lilin/Downloads/Demo Folder"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        try coordinator.launchCommandTemplate(AppSettings.developmentCommandTemplate)

        XCTAssertEqual(launcher.launchedCommands, ["cd '/Users/lilin/Downloads/Demo Folder' && claude"])
    }

    func test_launchShellCommandRunsLiteralCommand() throws {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        let resolver = FinderPathResolverStub(result: .success("/tmp"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        try coordinator.launchShellCommand("open -a Go2Claude")

        XCTAssertEqual(launcher.launchedCommands, ["open -a Go2Claude"])
    }

    func test_configurationModeOpensSettingsWithoutAttemptingLaunch() throws {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        let resolver = FinderPathResolverStub(result: .success("/tmp"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        let result = coordinator.handleLaunch(mode: .configuration)

        XCTAssertEqual(result, .openSettings(message: nil))
        XCTAssertEqual(resolver.invocationCount, 0)
        XCTAssertEqual(launcher.launchedCommands, [])
    }

    func test_finderFailureOpensSettingsWithError() {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        let resolver = FinderPathResolverStub(result: .failure(FinderPathResolver.Error.noOpenFinderWindow))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        let result = coordinator.handleLaunch(mode: .openCurrentFinderPath)

        XCTAssertEqual(
            result,
            .openSettings(message: FinderPathResolver.Error.noOpenFinderWindow.localizedDescription)
        )
    }

    func test_terminalFailureOpensSettingsWithError() {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        settings.commandTemplate = "cd %PATH% && claude"
        let resolver = FinderPathResolverStub(result: .success("/tmp"))
        let launcher = TerminalLauncherStub(result: .failure(TerminalLauncher.Error.appleScriptFailed("boom")))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        let result = coordinator.handleLaunch(mode: .openCurrentFinderPath)

        XCTAssertEqual(
            result,
            .openSettings(message: TerminalLauncher.Error.appleScriptFailed("boom").localizedDescription)
        )
    }

    func test_successfulLaunchRunsRenderedCommand() {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        settings.commandTemplate = "cd %PATH% && claude"
        let resolver = FinderPathResolverStub(result: .success("/Users/lilin/Downloads/Demo Folder"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        let result = coordinator.handleLaunch(mode: .openCurrentFinderPath)

        XCTAssertEqual(result, .terminate)
        XCTAssertEqual(launcher.launchedCommands, ["cd '/Users/lilin/Downloads/Demo Folder' && claude"])
    }

    func test_explicitFinderPathTakesPriorityOverAppleScriptLookup() {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: #function)!)
        settings.commandTemplate = "cd %PATH% && claude"
        let resolver = FinderPathResolverStub(result: .success("/Users/lilin/Wrong Folder"))
        let launcher = TerminalLauncherStub(result: .success(()))
        let coordinator = AppCoordinator(
            settings: settings,
            finderPathResolver: resolver,
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: launcher
        )

        let result = coordinator.handleLaunch(
            mode: .openCurrentFinderPath,
            explicitFinderPath: "/Users/lilin/Right Folder"
        )

        XCTAssertEqual(result, .terminate)
        XCTAssertEqual(resolver.invocationCount, 0)
        XCTAssertEqual(launcher.launchedCommands, ["cd '/Users/lilin/Right Folder' && claude"])
    }
}

private final class FinderPathResolverStub: FinderPathResolving {
    private let result: Result<String, Error>
    private(set) var invocationCount = 0

    init(result: Result<String, Error>) {
        self.result = result
    }

    func resolveCurrentFinderPath() throws -> String {
        invocationCount += 1
        return try result.get()
    }
}

private final class TerminalLauncherStub: TerminalLaunching {
    private let result: Result<Void, Error>
    private(set) var launchedCommands: [String] = []

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func launch(command: String) throws {
        launchedCommands.append(command)
        try result.get()
    }
}
