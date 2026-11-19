import AppKit
import Go2ClaudeCore
import OSLog
import SwiftUI

protocol ClaudeLaunching {
    func launchClaudeCurrentFinderPath(explicitFinderPath: String?) throws
    func launchCommandTemplate(_ template: String, explicitFinderPath: String?) throws
    func launchShellCommand(_ command: String) throws
}

extension AppCoordinator: ClaudeLaunching {}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum FinderOpenEventSource: String {
        case openFile
        case openFiles
    }

    private struct FinderOpenEvent {
        let source: FinderOpenEventSource
        let explicitFinderPath: String?
        let timestamp: Date
    }

    private static let finderOpenEventDedupInterval: TimeInterval = 2
    static let claudeInstallGuidanceMessage =
        "未检测到 Claude CLI。请先安装 Claude Code（推荐命令：\(ClaudeInstallGuidance.installCommand)），安装完成后再重试。"

    private let settings: AppSettings
    private let windowState: SettingsWindowState
    private var launchRouter: LaunchRequestRouter
    private let claudeLauncher: any ClaudeLaunching
    private let claudeInstallationChecker: any ClaudeInstallationChecking
    private let installGuidancePresenter: any ClaudeInstallGuidancePresenting
    private let externalResourceOpener: any ExternalResourceOpening
    private let terminateApplication: () -> Void
    private let logger = Logger(subsystem: "com.lilin.Go2Claude", category: "AppDelegate")

    private var settingsWindowController: SettingsWindowController?
    private var lastFinderOpenEvent: FinderOpenEvent?

    init(
        settings: AppSettings = AppSettings(),
        windowState: SettingsWindowState = SettingsWindowState(),
        launchRouter: LaunchRequestRouter = LaunchRequestRouter(),
        claudeLauncher: (any ClaudeLaunching)? = nil,
        claudeInstallationChecker: (any ClaudeInstallationChecking)? = nil,
        installGuidancePresenter: (any ClaudeInstallGuidancePresenting)? = nil,
        externalResourceOpener: (any ExternalResourceOpening)? = nil,
        terminateApplication: @escaping () -> Void = { NSApp.terminate(nil) }
    ) {
        self.settings = settings
        self.windowState = windowState
        self.launchRouter = launchRouter
        self.claudeLauncher = claudeLauncher ?? AppCoordinator(
            settings: settings,
            finderPathResolver: FinderPathResolver(),
            commandRenderer: CommandTemplateRenderer(),
            terminalLauncher: TerminalLauncher()
        )
        self.claudeInstallationChecker = claudeInstallationChecker ?? ClaudeInstallationChecker()
        self.installGuidancePresenter = installGuidancePresenter ?? ClaudeInstallGuidanceAlertPresenter()
        self.externalResourceOpener = externalResourceOpener ?? WorkspaceResourceOpener()
        self.terminateApplication = terminateApplication
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureApplicationMenu()
        DispatchQueue.main.async { [weak self] in
            self?.handleInitialLaunchIfNeeded()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard windowState.shouldRefreshClaudeInstallationStatusWhenActive else {
            return
        }

        refreshClaudeInstallationStatusFromPendingRecheck()
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        handleIncomingFinderPaths([filename], source: .openFile)
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        handleIncomingFinderPaths(filenames, source: .openFiles)
        sender.reply(toOpenOrPrint: .success)
    }

    private func handleIncomingFinderPaths(_ filenames: [String], source: FinderOpenEventSource) {
        logger.info("收到 Finder 打开事件，文件数量：\(filenames.count, privacy: .public)")
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        guard let explicitFinderPath = FinderLaunchPathResolver.normalize(urls: urls) else {
            logger.info("Finder 打开事件未解析出有效路径，已忽略")
            return
        }

        logger.info("标准化后的 Finder 路径：\(explicitFinderPath, privacy: .public)")

        if shouldIgnoreDuplicateFinderOpenEvent(source: source, explicitFinderPath: explicitFinderPath) {
            logger.info(
                "忽略疑似重复 Finder 打开事件，来源：\(source.rawValue, privacy: .public)，路径：\(explicitFinderPath, privacy: .public)"
            )
            return
        }

        lastFinderOpenEvent = FinderOpenEvent(
            source: source,
            explicitFinderPath: explicitFinderPath,
            timestamp: Date()
        )

        switch launchRouter.receiveIncomingFinderPath(explicitFinderPath) {
        case .deferUntilInitialLaunch:
            logger.info("应用尚未完成首启，暂存 Finder 路径")
        case .launchFinderCommand(let path):
            handleFinderToolbarLaunch(explicitFinderPath: path, terminateOnSuccess: false)
        }
    }

    private func shouldIgnoreDuplicateFinderOpenEvent(
        source: FinderOpenEventSource,
        explicitFinderPath: String?
    ) -> Bool {
        guard let lastFinderOpenEvent else {
            return false
        }

        let elapsed = Date().timeIntervalSince(lastFinderOpenEvent.timestamp)
        guard elapsed <= Self.finderOpenEventDedupInterval else {
            return false
        }

        guard lastFinderOpenEvent.explicitFinderPath == explicitFinderPath else {
            return false
        }

        // Finder 在同一次打开流程中可能先后触发 openFile 与 openFiles。
        return lastFinderOpenEvent.source != source
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openSettingsWindow()
        }

        return true
    }

    @objc
    func openSettingsWindowFromMenu(_ sender: Any?) {
        openSettingsWindow()
    }

    @objc
    func showUsageTips(_ sender: Any?) {
        presentUsageTips()
    }

    private func handleInitialLaunchIfNeeded() {
        let mode = LaunchMode(arguments: ProcessInfo.processInfo.arguments)
        let action = launchRouter.consumeInitialLaunch(mode: mode)

        guard action != .ignore else {
            logger.info("首启请求已处理，忽略重复调用")
            return
        }

        switch action {
        case .openMainInterface:
            logger.info("首启为普通启动，打开主界面")
            windowState.launchMessage = nil
            openSettingsWindow()
            refreshClaudeInstallationStatusFromInitialLaunch()
        case .launchFinderCommand(let explicitFinderPath):
            handleFinderToolbarLaunch(explicitFinderPath: explicitFinderPath, terminateOnSuccess: true)
        case .ignore:
            break
        }
    }

    private func openSettingsWindow() {
        primeClaudeInstallationStatusIfNeeded()

        if settingsWindowController == nil {
            let view = SettingsView(
                settings: settings,
                state: windowState,
                onRevealAppInFinder: { [weak self] in
                    self?.showFinderToolbarGuide()
                },
                onLaunchClaude: { [weak self] in
                    self?.launchClaudeFromSettings()
                },
                onOpenClaudeInstallGuide: { [weak self] in
                    self?.openClaudeInstallGuide()
                },
                onRefreshClaudeInstallationStatus: { [weak self] in
                    self?.refreshClaudeInstallationStatusFromSettings()
                },
                onRunReferenceCommand: { [weak self] command in
                    self?.handleCommandReferenceLaunch(command: command) ?? false
                },
                onUseDevelopmentMode: { [weak self] in
                    self?.switchToDevelopmentMode()
                },
                onShowUsageTips: { [weak self] in
                    self?.presentUsageTips()
                }
            )

            settingsWindowController = SettingsWindowController(rootView: view)
        }

        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func primeClaudeInstallationStatusIfNeeded() {
        guard windowState.claudeInstallationStatus == nil else {
            return
        }

        windowState.claudeInstallationStatus = claudeInstallationChecker.claudeInstallationStatus()
    }

    private func showFinderToolbarGuide() {
        guard let helperURL = AppBundleLocator.toolbarHelperURL(from: Bundle.main.bundleURL) else {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "未找到 Go2Claude Toolbar.app"
            alert.informativeText = """
            Finder 工具栏应拖入 Go2Claude Toolbar.app，而不是 Go2Claude.app。

            请重新打包或重新安装应用，确认主应用和 Toolbar Helper 位于同一目录。
            """
            alert.addButton(withTitle: "好的")
            alert.runModal()
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([helperURL])

        let alert = NSAlert()
        alert.messageText = "将 Go2Claude Toolbar 添加到 Finder 工具栏"
        alert.informativeText = """
        1. 在 Finder 中找到 Go2Claude Toolbar.app。
        2. 按住 Command 键，将它拖到 Finder 工具栏。
        3. 之后在任意 Finder 窗口点击该按钮，就会直接读取当前 Finder 目录并打开 Claude。
        """
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    private func switchToDevelopmentMode() {
        settings.useDevelopmentTemplate()
        windowState.launchMessage = "已切换为开发模式命令：\(AppSettings.developmentCommandTemplate)"
    }

    private func launchClaudeFromSettings() {
        launchClaude(explicitFinderPath: nil)
    }

    private func launchClaude(explicitFinderPath: String?) {
        guard ensureClaudeInstalled() else {
            return
        }

        do {
            logger.info("准备显式进入 Claude，路径：\(explicitFinderPath ?? "<apple-script-fallback>", privacy: .public)")
            try claudeLauncher.launchClaudeCurrentFinderPath(explicitFinderPath: explicitFinderPath)
            windowState.launchMessage = nil
        } catch {
            logger.error("显式进入 Claude 失败：\(error.localizedDescription, privacy: .public)")
            windowState.launchMessage = error.localizedDescription
            openSettingsWindow()
        }
    }

    private func ensureClaudeInstalled() -> Bool {
        switch refreshClaudeInstallationStatus() {
        case .installed(let executablePath):
            logger.info("检测到 Claude CLI：\(executablePath, privacy: .public)")
            windowState.shouldRefreshClaudeInstallationStatusWhenActive = false
            windowState.isWaitingForClaudeInstallation = false
            windowState.launchMessage = nil
            return true
        case .notInstalled:
            logger.error("未检测到 Claude CLI，阻止启动请求")
            openSettingsWindow()
            let action = installGuidancePresenter.presentMissingClaudeInstallGuidance(.default)
            if action == .openInstallGuide {
                openClaudeInstallGuide()
            }
            return false
        }
    }

    @discardableResult
    private func refreshClaudeInstallationStatus() -> ClaudeInstallationStatus {
        let status = claudeInstallationChecker.claudeInstallationStatus()
        windowState.claudeInstallationStatus = status
        return status
    }

    private func refreshClaudeInstallationStatusFromInitialLaunch() {
        let shouldPresentInitialGuidance = !settings.hasCompletedClaudeInstallationCheck
        if shouldPresentInitialGuidance {
            settings.markClaudeInstallationCheckCompleted()
        }

        let checker = claudeInstallationChecker
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let status = checker.claudeInstallationStatus()
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }

                self.windowState.claudeInstallationStatus = status

                guard shouldPresentInitialGuidance, case .notInstalled = status else {
                    return
                }

                self.logger.info("首次启动未检测到 Claude CLI，展示安装引导")
                let action = self.installGuidancePresenter.presentMissingClaudeInstallGuidance(.default)
                if action == .openInstallGuide {
                    self.openClaudeInstallGuide()
                }
            }
        }
    }

    private func refreshClaudeInstallationStatusFromSettings() {
        switch refreshClaudeInstallationStatus() {
        case .installed:
            windowState.shouldRefreshClaudeInstallationStatusWhenActive = false
            windowState.isWaitingForClaudeInstallation = false
            windowState.launchMessage = nil
        case .notInstalled:
            windowState.shouldRefreshClaudeInstallationStatusWhenActive = true
            windowState.isWaitingForClaudeInstallation = false
            windowState.launchMessage = nil
        }
    }

    private func refreshClaudeInstallationStatusFromPendingRecheck() {
        switch refreshClaudeInstallationStatus() {
        case .installed(let executablePath):
            logger.info("应用回到前台后检测到 Claude CLI：\(executablePath, privacy: .public)")
            windowState.shouldRefreshClaudeInstallationStatusWhenActive = false
            windowState.isWaitingForClaudeInstallation = false
            windowState.launchMessage = nil
        case .notInstalled:
            logger.info("应用回到前台后仍未检测到 Claude CLI")
            windowState.shouldRefreshClaudeInstallationStatusWhenActive = true
            windowState.isWaitingForClaudeInstallation = false
            windowState.launchMessage = nil
        }
    }

    func handleCommandReferenceLaunch(command: String) -> Bool {
        do {
            if command.contains(CommandTemplateRenderer.pathPlaceholder) {
                logger.info("准备执行说明区模板命令：\(command, privacy: .public)")
                try claudeLauncher.launchCommandTemplate(command, explicitFinderPath: nil)
            } else {
                logger.info("准备执行说明区字面命令：\(command, privacy: .public)")
                try claudeLauncher.launchShellCommand(command)
            }

            windowState.launchMessage = nil
            return true
        } catch {
            logger.error("执行说明区命令失败：\(error.localizedDescription, privacy: .public)")
            windowState.launchMessage = error.localizedDescription
            openSettingsWindow()
            return false
        }
    }

    func handleFinderToolbarLaunch(explicitFinderPath: String?, terminateOnSuccess: Bool) {
        if explicitFinderPath == nil {
            logger.info("Finder 未显式传入目录，回退到 AppleScript 读取当前 Finder 路径")
        } else {
            logger.info("Finder 使用显式目录启动 Claude：\(explicitFinderPath ?? "<nil>", privacy: .public)")
        }

        launchClaude(explicitFinderPath: explicitFinderPath)

        guard terminateOnSuccess, windowState.launchMessage == nil else {
            return
        }

        logger.info("Finder 工具栏启动成功，应用即将退出")
        terminateApplication()
    }

    private func presentUsageTips() {
        let alert = NSAlert()
        alert.messageText = "Go2Claude 使用说明"
        alert.informativeText = """
        • 双击 Go2Claude 或执行 open -a Go2Claude 会打开主界面。
        • Finder 工具栏请拖入 Go2Claude Toolbar.app；点击后会直接执行当前模板命令。
        • 首次打开会检测当前机器是否已安装 Claude CLI；如果未安装，会提供官方安装指引。
        • %PATH% 会被替换为当前 Finder 窗口路径。
        • 默认模式：\(AppSettings.defaultCommandTemplate)
        • 开发模式：\(AppSettings.developmentCommandTemplate)
        • 兼容打开配置：open -a Go2Claude --args config
        """
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    private func configureApplicationMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(
            withTitle: "设置…",
            action: #selector(openSettingsWindowFromMenu(_:)),
            keyEquivalent: ","
        )
        appMenu.addItem(
            withTitle: "使用说明",
            action: #selector(showUsageTips(_:)),
            keyEquivalent: "?"
        )
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(
            withTitle: "退出 Go2Claude",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)

        let editMenu = NSMenu(title: "编辑")
        editMenuItem.submenu = editMenu
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        NSApp.mainMenu = mainMenu
    }

    func openClaudeInstallGuide() {
        windowState.shouldRefreshClaudeInstallationStatusWhenActive = true
        windowState.isWaitingForClaudeInstallation = true
        externalResourceOpener.open(ClaudeInstallGuidance.default.installURL)
    }

    func openClaudeInstallGuideForTesting() {
        openClaudeInstallGuide()
    }
}
