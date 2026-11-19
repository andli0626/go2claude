import AppKit
import Go2ClaudeCore

@MainActor
final class ToolbarAppDelegate: NSObject, NSApplicationDelegate {
    private let controller: ToolbarLaunchController

    init(
        controller: ToolbarLaunchController? = nil,
        bundleURL: URL = Bundle.main.bundleURL
    ) {
        self.controller = controller ?? ToolbarLaunchController(
            launcher: AppCoordinator(
                settings: AppSettings(),
                finderPathResolver: FinderPathResolver(),
                commandRenderer: CommandTemplateRenderer(),
                terminalLauncher: TerminalLauncher()
            ),
            failurePresenter: AlertToolbarFailurePresenter(),
            mainAppOpener: MainAppOpener(helperBundleURL: bundleURL),
            terminateApplication: { NSApp.terminate(nil) }
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async { [controller] in
            controller.handleLaunch()
        }
    }
}
