import AppKit
import Go2ClaudeCore

protocol ToolbarLaunching {
    func launchCurrentFinderPath(explicitFinderPath: String?) throws
}

extension AppCoordinator: ToolbarLaunching {}

enum ToolbarLaunchFailureAction {
    case openMainInterface
    case close
}

@MainActor
protocol ToolbarFailurePresenting {
    func presentLaunchFailure(message: String) -> ToolbarLaunchFailureAction
}

@MainActor
protocol MainAppOpening {
    func openMainInterface()
}

@MainActor
struct ToolbarLaunchController {
    let launcher: any ToolbarLaunching
    let failurePresenter: any ToolbarFailurePresenting
    let mainAppOpener: any MainAppOpening
    let terminateApplication: () -> Void

    func handleLaunch() {
        do {
            try launcher.launchCurrentFinderPath(explicitFinderPath: nil)
            terminateApplication()
        } catch {
            let action = failurePresenter.presentLaunchFailure(message: error.localizedDescription)

            if action == .openMainInterface {
                mainAppOpener.openMainInterface()
            }

            terminateApplication()
        }
    }
}

@MainActor
struct AlertToolbarFailurePresenter: ToolbarFailurePresenting {
    func presentLaunchFailure(message: String) -> ToolbarLaunchFailureAction {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "无法直接打开 Claude"
        alert.informativeText = """
        \(message)

        你可以先打开主界面检查命令模板、Finder 自动化权限和当前 Finder 窗口状态。
        """
        alert.addButton(withTitle: "打开主界面")
        alert.addButton(withTitle: "关闭")

        let response = alert.runModal()
        return response == .alertFirstButtonReturn ? .openMainInterface : .close
    }
}

struct MainAppLocator {
    private static let mainAppBundleName = "Go2Claude.app"
    private static let mainAppBundleIdentifier = "com.lilin.Go2Claude"

    static func mainAppURL(from helperBundleURL: URL, fileManager: FileManager = .default) -> URL? {
        let appBundleURL = helperBundleURL.pathExtension == "app"
            ? helperBundleURL
            : helperBundleURL.deletingLastPathComponent()
        let siblingDirectoryURL = appBundleURL.deletingLastPathComponent()
        let siblingMainAppURL = siblingDirectoryURL.appendingPathComponent(mainAppBundleName, isDirectory: true)

        if fileManager.fileExists(atPath: siblingMainAppURL.path) {
            return siblingMainAppURL
        }

        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppBundleIdentifier)
    }
}

@MainActor
struct MainAppOpener: MainAppOpening {
    let helperBundleURL: URL

    func openMainInterface() {
        guard let mainAppURL = MainAppLocator.mainAppURL(from: helperBundleURL) else {
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.arguments = ["config"]
        NSWorkspace.shared.openApplication(at: mainAppURL, configuration: configuration) { _, _ in }
    }
}
