import Go2ClaudeCore
import XCTest
@testable import Go2ClaudeToolbar

@MainActor
final class ToolbarLaunchControllerTests: XCTestCase {
    func test_successfulLaunchRunsCurrentTemplateAndTerminates() {
        let launcher = ToolbarLauncherStub(result: .success(()))
        let alertPresenter = ToolbarAlertPresenterStub(action: .close)
        let mainAppOpener = MainAppOpenerStub()
        var terminateInvocationCount = 0
        let controller = ToolbarLaunchController(
            launcher: launcher,
            failurePresenter: alertPresenter,
            mainAppOpener: mainAppOpener,
            terminateApplication: {
                terminateInvocationCount += 1
            }
        )

        controller.handleLaunch()

        XCTAssertEqual(launcher.invocationCount, 1)
        XCTAssertEqual(alertPresenter.presentedMessages, [])
        XCTAssertEqual(mainAppOpener.openInvocationCount, 0)
        XCTAssertEqual(terminateInvocationCount, 1)
    }

    func test_failedLaunchCanOpenMainInterfaceBeforeTerminating() {
        let launcher = ToolbarLauncherStub(result: .failure(FinderPathResolver.Error.noOpenFinderWindow))
        let alertPresenter = ToolbarAlertPresenterStub(action: .openMainInterface)
        let mainAppOpener = MainAppOpenerStub()
        var terminateInvocationCount = 0
        let controller = ToolbarLaunchController(
            launcher: launcher,
            failurePresenter: alertPresenter,
            mainAppOpener: mainAppOpener,
            terminateApplication: {
                terminateInvocationCount += 1
            }
        )

        controller.handleLaunch()

        XCTAssertEqual(launcher.invocationCount, 1)
        XCTAssertEqual(alertPresenter.presentedMessages, [FinderPathResolver.Error.noOpenFinderWindow.localizedDescription])
        XCTAssertEqual(mainAppOpener.openInvocationCount, 1)
        XCTAssertEqual(terminateInvocationCount, 1)
    }

    func test_failedLaunchCanCloseWithoutOpeningMainInterface() {
        let launcher = ToolbarLauncherStub(result: .failure(FinderPathResolver.Error.noOpenFinderWindow))
        let alertPresenter = ToolbarAlertPresenterStub(action: .close)
        let mainAppOpener = MainAppOpenerStub()
        var terminateInvocationCount = 0
        let controller = ToolbarLaunchController(
            launcher: launcher,
            failurePresenter: alertPresenter,
            mainAppOpener: mainAppOpener,
            terminateApplication: {
                terminateInvocationCount += 1
            }
        )

        controller.handleLaunch()

        XCTAssertEqual(mainAppOpener.openInvocationCount, 0)
        XCTAssertEqual(terminateInvocationCount, 1)
    }
}

private final class ToolbarLauncherStub: ToolbarLaunching {
    private let result: Result<Void, Error>
    private(set) var invocationCount = 0

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func launchCurrentFinderPath(explicitFinderPath: String?) throws {
        invocationCount += 1
        return try result.get()
    }
}

private final class ToolbarAlertPresenterStub: ToolbarFailurePresenting {
    let action: ToolbarLaunchFailureAction
    private(set) var presentedMessages: [String] = []

    init(action: ToolbarLaunchFailureAction) {
        self.action = action
    }

    func presentLaunchFailure(message: String) -> ToolbarLaunchFailureAction {
        presentedMessages.append(message)
        return action
    }
}

private final class MainAppOpenerStub: MainAppOpening {
    private(set) var openInvocationCount = 0

    func openMainInterface() {
        openInvocationCount += 1
    }
}
