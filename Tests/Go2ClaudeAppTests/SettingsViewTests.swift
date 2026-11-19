import Go2ClaudeCore
import XCTest
@testable import Go2Claude

@MainActor
final class SettingsViewTests: XCTestCase {
    func test_primaryButtonModeDefaultsToLaunchClaude() {
        let view = makeSettingsView()

        XCTAssertEqual(view.primaryButtonMode, .launchClaude)
    }

    func test_launchClaudeButtonUsesDefaultTitleWhenStatusIsUnknown() {
        let view = makeSettingsView()

        XCTAssertTrue(view.canLaunchClaude)
        XCTAssertEqual(view.launchClaudeButtonTitle, "打开 Claude 终端")
    }

    func test_launchClaudeButtonSwitchesToInstallTitleWhenClaudeIsMissing() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .notInstalled
        let view = makeSettingsView(state: state)

        XCTAssertFalse(view.canLaunchClaude)
        XCTAssertEqual(view.primaryButtonMode, .installClaude)
        XCTAssertEqual(view.launchClaudeButtonTitle, "先安装 Claude")
    }

    func test_launchClaudeButtonSwitchesToWaitingTitleWhenInstallIsPending() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .notInstalled
        state.isWaitingForClaudeInstallation = true
        let view = makeSettingsView(state: state)

        XCTAssertEqual(view.primaryButtonMode, .waitingForInstall)
        XCTAssertEqual(view.launchClaudeButtonTitle, "等待安装完成…")
    }

    func test_launchClaudeButtonUsesDefaultTitleWhenClaudeIsInstalled() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .installed(executablePath: "/opt/homebrew/bin/claude")
        let view = makeSettingsView(state: state)

        XCTAssertTrue(view.canLaunchClaude)
        XCTAssertEqual(view.primaryButtonMode, .launchClaude)
        XCTAssertEqual(view.launchClaudeButtonTitle, "打开 Claude 终端")
    }

    func test_exposesInstalledExecutablePathWhenClaudeIsInstalled() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .installed(executablePath: "/opt/homebrew/bin/claude")
        let view = makeSettingsView(state: state)

        XCTAssertEqual(view.claudeInstalledExecutablePath, "/opt/homebrew/bin/claude")
    }

    func test_installedExecutablePathIsNilWhenClaudeIsMissing() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .notInstalled
        let view = makeSettingsView(state: state)

        XCTAssertNil(view.claudeInstalledExecutablePath)
    }

    func test_finderToolbarGuideButtonUsesSingleAppCopy() {
        let view = makeSettingsView()

        XCTAssertEqual(view.finderToolbarGuideButtonTitle, "一键添加到 Finder 工具栏")
        XCTAssertTrue(view.heroSubtitle.contains("Go2Claude.app"))
        XCTAssertTrue(view.heroSubtitle.contains("Go2Claude Toolbar.app"))
        XCTAssertTrue(view.commandTemplateHintText.contains("Go2Claude Toolbar.app"))
    }

    func test_layoutConstantsUseBalancedOuterPaddingForSettingsWindow() {
        XCTAssertEqual(SettingsView.topContentPadding, 16)
    }

    private func makeSettingsView(state: SettingsWindowState = SettingsWindowState()) -> SettingsView {
        SettingsView(
            settings: AppSettings(),
            state: state,
            onRevealAppInFinder: {},
            onLaunchClaude: {},
            onOpenClaudeInstallGuide: {},
            onRefreshClaudeInstallationStatus: {},
            onRunReferenceCommand: { _ in true },
            onUseDevelopmentMode: {},
            onShowUsageTips: {}
        )
    }
}
