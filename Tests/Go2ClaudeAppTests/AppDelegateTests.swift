import Go2ClaudeCore
import AppKit
import XCTest
@testable import Go2Claude

@MainActor
final class AppDelegateTests: XCTestCase {
    func test_firstLaunchShowsClaudeInstallGuidanceWhenClaudeIsMissing() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = AppSettings(userDefaults: defaults)
        let state = SettingsWindowState()
        let checker = ClaudeInstallationCheckerStub(statuses: [.notInstalled])
        let presenter = ClaudeInstallGuidancePresenterStub(result: .openInstallGuide)
        let opener = ExternalResourceOpenerStub()
        let appDelegate = AppDelegate(
            settings: settings,
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: ClaudeLauncherStub(),
            claudeInstallationChecker: checker,
            installGuidancePresenter: presenter,
            externalResourceOpener: opener,
            terminateApplication: {}
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        let firstTick = expectation(description: "first launch tick")
        DispatchQueue.main.async {
            firstTick.fulfill()
        }
        wait(for: [firstTick], timeout: 1)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(checker.invocationCount, 2)
        XCTAssertEqual(presenter.presentedGuidance.count, 1)
        XCTAssertEqual(opener.openedURLs, [ClaudeInstallGuidance.default.installURL])
        XCTAssertEqual(state.claudeInstallationStatus, .notInstalled)
        XCTAssertTrue(settings.hasCompletedClaudeInstallationCheck)
    }

    func test_laterLaunchKeepsBannerButDoesNotRepeatFirstLaunchPrompt() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defaults.set(true, forKey: AppSettings.claudeInstallationCheckCompletedKey)
        let settings = AppSettings(userDefaults: defaults)
        let state = SettingsWindowState()
        let checker = ClaudeInstallationCheckerStub(statuses: [.notInstalled])
        let presenter = ClaudeInstallGuidancePresenterStub(result: .dismiss)
        let opener = ExternalResourceOpenerStub()
        let appDelegate = AppDelegate(
            settings: settings,
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: ClaudeLauncherStub(),
            claudeInstallationChecker: checker,
            installGuidancePresenter: presenter,
            externalResourceOpener: opener,
            terminateApplication: {}
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        let firstTick = expectation(description: "relaunch tick")
        DispatchQueue.main.async {
            firstTick.fulfill()
        }
        wait(for: [firstTick], timeout: 1)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(checker.invocationCount, 2)
        XCTAssertEqual(presenter.presentedGuidance.count, 0)
        XCTAssertEqual(opener.openedURLs, [])
        XCTAssertEqual(state.claudeInstallationStatus, .notInstalled)
    }

    func test_applicationBecomingActiveRefreshesPendingClaudeInstallCheck() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .notInstalled
        state.shouldRefreshClaudeInstallationStatusWhenActive = true
        let checker = ClaudeInstallationCheckerStub(
            statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
        )
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: ClaudeLauncherStub(),
            claudeInstallationChecker: checker,
            terminateApplication: {}
        )

        appDelegate.applicationDidBecomeActive(Notification(name: NSApplication.didBecomeActiveNotification))

        XCTAssertEqual(checker.invocationCount, 1)
        XCTAssertEqual(state.claudeInstallationStatus, .installed(executablePath: "/opt/homebrew/bin/claude"))
        XCTAssertFalse(state.shouldRefreshClaudeInstallationStatusWhenActive)
        XCTAssertFalse(state.isWaitingForClaudeInstallation)
        XCTAssertNil(state.launchMessage)
    }

    func test_openingInstallGuideMarksStateForPendingRefresh() {
        let opener = ExternalResourceOpenerStub()
        let state = SettingsWindowState()
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: ClaudeLauncherStub(),
            claudeInstallationChecker: ClaudeInstallationCheckerStub(statuses: [.notInstalled]),
            externalResourceOpener: opener,
            terminateApplication: {}
        )

        appDelegate.openClaudeInstallGuideForTesting()

        XCTAssertEqual(opener.openedURLs, [ClaudeInstallGuidance.default.installURL])
        XCTAssertTrue(state.shouldRefreshClaudeInstallationStatusWhenActive)
        XCTAssertTrue(state.isWaitingForClaudeInstallation)
    }

    func test_finderToolbarLaunchUsesClaudeLauncherWithExplicitPath() {
        let launcher = ClaudeLauncherStub()
        let state = SettingsWindowState()
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: launcher,
            claudeInstallationChecker: ClaudeInstallationCheckerStub(
                statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
            ),
            terminateApplication: {}
        )

        appDelegate.handleFinderToolbarLaunch(
            explicitFinderPath: "/Users/lilin/Downloads",
            terminateOnSuccess: false
        )

        XCTAssertEqual(launcher.launchedPaths, ["/Users/lilin/Downloads"])
        XCTAssertNil(state.launchMessage)
    }

    func test_finderToolbarLaunchCanTerminateAppAfterSuccessfulInitialLaunch() {
        let launcher = ClaudeLauncherStub()
        let state = SettingsWindowState()
        var terminateInvocationCount = 0
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: launcher,
            claudeInstallationChecker: ClaudeInstallationCheckerStub(
                statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
            ),
            terminateApplication: {
                terminateInvocationCount += 1
            }
        )

        appDelegate.handleFinderToolbarLaunch(
            explicitFinderPath: "/Users/lilin/Downloads",
            terminateOnSuccess: true
        )

        XCTAssertEqual(launcher.launchedPaths, ["/Users/lilin/Downloads"])
        XCTAssertEqual(terminateInvocationCount, 1)
        XCTAssertNil(state.launchMessage)
    }

    func test_commandReferenceLaunchUsesTemplateExecutionForPlaceholderCommands() {
        let launcher = ClaudeLauncherStub()
        let state = SettingsWindowState()
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: launcher,
            claudeInstallationChecker: ClaudeInstallationCheckerStub(
                statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
            ),
            terminateApplication: {}
        )

        XCTAssertTrue(appDelegate.handleCommandReferenceLaunch(command: AppSettings.defaultCommandTemplate))

        XCTAssertEqual(
            launcher.launchedTemplateCommands,
            [LaunchedTemplateCommand(template: AppSettings.defaultCommandTemplate, explicitFinderPath: nil)]
        )
        XCTAssertEqual(launcher.launchedLiteralCommands, [])
        XCTAssertNil(state.launchMessage)
    }

    func test_commandReferenceLaunchUsesLiteralExecutionForDirectShellCommands() {
        let launcher = ClaudeLauncherStub()
        let state = SettingsWindowState()
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: launcher,
            claudeInstallationChecker: ClaudeInstallationCheckerStub(
                statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
            ),
            terminateApplication: {}
        )

        XCTAssertTrue(appDelegate.handleCommandReferenceLaunch(command: "open -a Go2Claude --args config"))

        XCTAssertEqual(launcher.launchedTemplateCommands, [])
        XCTAssertEqual(launcher.launchedLiteralCommands, ["open -a Go2Claude --args config"])
        XCTAssertNil(state.launchMessage)
    }

    func test_firstLaunchDeduplicatesOpenFileAndOpenFilesForSamePath() {
        let app = NSApplication.shared
        let launcher = ClaudeLauncherStub()
        let state = SettingsWindowState()
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: launcher,
            claudeInstallationChecker: ClaudeInstallationCheckerStub(
                statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
            ),
            terminateApplication: {}
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        XCTAssertTrue(appDelegate.application(app, openFile: "/Users/lilin/Downloads"))

        let firstTick = expectation(description: "first tick")
        DispatchQueue.main.async {
            firstTick.fulfill()
        }
        wait(for: [firstTick], timeout: 1)

        appDelegate.application(app, openFiles: ["/Users/lilin/Downloads"])

        XCTAssertEqual(launcher.launchedPaths, ["/Users/lilin/Downloads"])
    }

    func test_dedupDoesNotSuppressDifferentIncomingPaths() {
        let app = NSApplication.shared
        let launcher = ClaudeLauncherStub()
        let state = SettingsWindowState()
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: launcher,
            claudeInstallationChecker: ClaudeInstallationCheckerStub(
                statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
            ),
            terminateApplication: {}
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        XCTAssertTrue(appDelegate.application(app, openFile: "/Users/lilin/Downloads"))

        let firstTick = expectation(description: "first tick")
        DispatchQueue.main.async {
            firstTick.fulfill()
        }
        wait(for: [firstTick], timeout: 1)

        appDelegate.application(app, openFiles: ["/Users/lilin/Documents"])

        XCTAssertEqual(launcher.launchedPaths, ["/Users/lilin/Downloads", "/Users/lilin/Documents"])
    }

    func test_ignoresAppBundleOpenEventAfterInitialLaunch() throws {
        let app = NSApplication.shared
        let launcher = ClaudeLauncherStub()
        let state = SettingsWindowState()
        let appDelegate = AppDelegate(
            settings: AppSettings(),
            windowState: state,
            launchRouter: LaunchRequestRouter(),
            claudeLauncher: launcher,
            claudeInstallationChecker: ClaudeInstallationCheckerStub(
                statuses: [.installed(executablePath: "/opt/homebrew/bin/claude")]
            ),
            terminateApplication: {}
        )

        appDelegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        let firstTick = expectation(description: "first launch tick")
        DispatchQueue.main.async {
            firstTick.fulfill()
        }
        wait(for: [firstTick], timeout: 1)

        let appBundlePath = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(UUID().uuidString).app", isDirectory: true)
        try FileManager.default.createDirectory(at: appBundlePath, withIntermediateDirectories: true)
        XCTAssertTrue(appDelegate.application(app, openFile: appBundlePath.path))

        XCTAssertEqual(launcher.launchedPaths, [])
    }
}

private struct LaunchedTemplateCommand: Equatable {
    let template: String
    let explicitFinderPath: String?
}

private final class ClaudeLauncherStub: ClaudeLaunching {
    private(set) var launchedPaths: [String?] = []
    private(set) var launchedTemplateCommands: [LaunchedTemplateCommand] = []
    private(set) var launchedLiteralCommands: [String] = []

    func launchClaudeCurrentFinderPath(explicitFinderPath: String?) throws {
        launchedPaths.append(explicitFinderPath)
    }

    func launchCommandTemplate(_ template: String, explicitFinderPath: String?) throws {
        launchedTemplateCommands.append(
            LaunchedTemplateCommand(template: template, explicitFinderPath: explicitFinderPath)
        )
    }

    func launchShellCommand(_ command: String) throws {
        launchedLiteralCommands.append(command)
    }
}

private final class ClaudeInstallationCheckerStub: ClaudeInstallationChecking, @unchecked Sendable {
    private let statuses: [ClaudeInstallationStatus]
    private(set) var invocationCount = 0

    init(statuses: [ClaudeInstallationStatus]) {
        self.statuses = statuses
    }

    func claudeInstallationStatus() -> ClaudeInstallationStatus {
        invocationCount += 1
        let index = min(invocationCount - 1, statuses.count - 1)
        return statuses[index]
    }
}

@MainActor
private final class ClaudeInstallGuidancePresenterStub: ClaudeInstallGuidancePresenting {
    let result: ClaudeInstallGuidanceAction
    private(set) var presentedGuidance: [ClaudeInstallGuidance] = []

    init(result: ClaudeInstallGuidanceAction) {
        self.result = result
    }

    func presentMissingClaudeInstallGuidance(_ guidance: ClaudeInstallGuidance) -> ClaudeInstallGuidanceAction {
        presentedGuidance.append(guidance)
        return result
    }
}

private final class ExternalResourceOpenerStub: ExternalResourceOpening {
    private(set) var openedURLs: [URL] = []

    func open(_ url: URL) {
        openedURLs.append(url)
    }
}
