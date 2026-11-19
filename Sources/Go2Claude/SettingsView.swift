import Go2ClaudeCore
import SwiftUI

struct SettingsView: View {
    static let topContentPadding: CGFloat = 16

    private struct ContentHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    enum PrimaryButtonMode: Equatable {
        case launchClaude
        case installClaude
        case waitingForInstall
    }

    private struct CommandReference: Identifiable {
        let title: String
        let command: String
        let accentColor: Color

        var id: String { title }
    }

    private enum CommandReferenceFeedback {
        case copied(title: String)
        case applied(title: String)
        case launched(title: String)

        var text: String {
            switch self {
            case .copied(let title):
                return "已复制 \(title)"
            case .applied(let title):
                return "已填入模板：\(title)"
            case .launched(let title):
                return "已在终端运行：\(title)"
            }
        }

        var color: Color {
            switch self {
            case .copied:
                return .blue
            case .applied:
                return .green
            case .launched:
                return .orange
            }
        }
    }

    @ObservedObject var settings: AppSettings
    @ObservedObject var state: SettingsWindowState
    @State private var commandReferenceFeedback: CommandReferenceFeedback?

    let onRevealAppInFinder: () -> Void
    let onLaunchClaude: () -> Void
    let onOpenClaudeInstallGuide: () -> Void
    let onRefreshClaudeInstallationStatus: () -> Void
    let onRunReferenceCommand: (String) -> Bool
    let onUseDevelopmentMode: () -> Void
    let onShowUsageTips: () -> Void
    var onContentHeightChange: () -> Void = {}

    var primaryButtonMode: PrimaryButtonMode {
        if state.isWaitingForClaudeInstallation {
            return .waitingForInstall
        }

        return canLaunchClaude ? .launchClaude : .installClaude
    }

    var canLaunchClaude: Bool {
        if case .notInstalled = state.claudeInstallationStatus {
            return false
        }

        return true
    }

    var launchClaudeButtonTitle: String {
        switch primaryButtonMode {
        case .launchClaude:
            return "打开 Claude 终端"
        case .installClaude:
            return "先安装 Claude"
        case .waitingForInstall:
            return "等待安装完成…"
        }
    }

    var launchClaudeButtonBackground: LinearGradient {
        switch primaryButtonMode {
        case .launchClaude:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.20, blue: 0.20),
                    Color(red: 0.80, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .installClaude:
            return LinearGradient(
                colors: [
                    Color(nsColor: .systemGray),
                    Color(nsColor: .disabledControlTextColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .waitingForInstall:
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.63, blue: 0.12),
                    Color(red: 0.88, green: 0.46, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var claudeInstalledExecutablePath: String? {
        guard case .installed(let executablePath) = state.claudeInstallationStatus else {
            return nil
        }

        return executablePath
    }

    var heroSubtitle: String {
        "推荐先安装 Claude Code；确认 `claude` 命令可用后，Go2Claude.app 会配合 Go2Claude Toolbar.app 帮你从 Finder 当前目录一键进入 Claude CLI。点击右侧按钮可打开终端或准备 Finder 工具栏入口。"
    }

    var commandTemplateHintText: String {
        "使用 %PATH% 作为当前 Finder 窗口路径占位符；通过“一键添加”准备好的 Go2Claude Toolbar.app 会使用这里的当前模板命令。"
    }

    var finderToolbarGuideButtonTitle: String {
        "一键添加到 Finder 工具栏"
    }

    private var templateContainsPathPlaceholder: Bool {
        settings.commandTemplate.contains(CommandTemplateRenderer.pathPlaceholder)
    }

    private var commandReferences: [CommandReference] {
        [
            CommandReference(
                title: "默认模式",
                command: AppSettings.defaultCommandTemplate,
                accentColor: Color.blue
            ),
            CommandReference(
                title: "开发模式示例",
                command: AppSettings.developmentCommandTemplate,
                accentColor: Color.orange
            ),
            CommandReference(
                title: "普通启动主界面",
                command: "open -a Go2Claude",
                accentColor: Color.green
            ),
            CommandReference(
                title: "兼容打开配置",
                command: "open -a Go2Claude --args config",
                accentColor: Color.purple
            )
        ]
    }

    private var commandReferenceColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: 320, maximum: 460),
                spacing: 10,
                alignment: .top
            )
        ]
    }

    private var commandActionHandler: CommandReferenceActionHandler {
        CommandReferenceActionHandler(settings: settings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            heroSection

            if let executablePath = claudeInstalledExecutablePath {
                claudeInstalledStatusCard(executablePath: executablePath)
            }

            if case .notInstalled = state.claudeInstallationStatus {
                claudeInstallNoticeCard
            }

            if let launchMessage = state.launchMessage {
                launchMessageBanner(launchMessage)
            }

            mainContentSection
            disclaimerSection
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.top, Self.topContentPadding)
        .padding(.bottom, 14)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ContentHeightPreferenceKey.self,
                    value: proxy.size.height
                )
            }
        )
        .onPreferenceChange(ContentHeightPreferenceKey.self) { _ in
            onContentHeightChange()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finder 工具栏启动助手")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(Capsule())

                    Text("Go2Claude")
                        .font(.system(size: 30, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 10) {
                    HStack(spacing: 10) {
                        launchClaudeButton
                        finderToolbarGuideButton
                    }
                }
            }

            Text(heroSubtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.86, green: 0.93, blue: 1.0),
                            Color(red: 0.95, green: 0.97, blue: 1.0),
                            Color.white
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.blue.opacity(0.08), radius: 20, x: 0, y: 12)
    }

    private func launchMessageBanner(_ launchMessage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(launchMessage)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("关闭") {
                state.launchMessage = nil
            }
            .buttonStyle(.link)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func claudeInstalledStatusCard(executablePath: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 28, height: 28)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("已检测到可用的 Claude CLI")
                        .font(.headline)

                    Text("当前机器已经可以直接从 Finder 当前目录启动 Claude。若你刚完成升级或切换环境，可以点击重新检查。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onOpenClaudeInstallGuide) {
                        HStack(spacing: 4) {
                            Text("打开 Claude Code 安装文档")
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.link)
                }
            }

            Text(executablePath)
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                compactSecondaryButton(title: "复制路径") {
                    commandActionHandler.copyCommand(executablePath)
                    commandReferenceFeedback = .copied(title: "Claude 路径")
                }
                compactSecondaryButton(title: "重新检查", action: onRefreshClaudeInstallationStatus)
                compactSecondaryButton(title: "使用说明", action: onShowUsageTips)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private var claudeInstallNoticeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 28, height: 28)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("当前 Mac 还没有可用的 Claude CLI")
                        .font(.headline)

                    Text("请先安装 Claude Code，再使用 Finder 工具栏或“打开 Claude 终端”。你可以直接复制安装命令，或查看官方文档。")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onOpenClaudeInstallGuide) {
                        HStack(spacing: 4) {
                            Text("打开 Claude Code 安装文档")
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.link)
                }
            }

            Text(ClaudeInstallGuidance.default.installCommand)
                .font(.system(size: 13, design: .monospaced))
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                compactSecondaryButton(title: "复制命令") {
                    commandActionHandler.copyCommand(ClaudeInstallGuidance.default.installCommand)
                    commandReferenceFeedback = .copied(title: "安装命令")
                }
                compactSecondaryButton(title: "查看安装指南", action: onOpenClaudeInstallGuide)
                compactSecondaryButton(title: "重新检查", action: onRefreshClaudeInstallationStatus)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private var commandEditorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("终端命令模板")
                    .font(.headline)

                Spacer(minLength: 0)

                if let commandReferenceFeedback {
                    Text(commandReferenceFeedback.text)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(commandReferenceFeedback.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(commandReferenceFeedback.color.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text("当前配置生效")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            Text(commandTemplateHintText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                TextField("", text: $settings.commandTemplate)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                templateContainsPathPlaceholder ? Color.blue.opacity(0.3) : Color.red.opacity(0.5),
                                lineWidth: 1
                            )
                    )

                if !templateContainsPathPlaceholder {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("命令模板必须包含 %PATH% 占位符。")
                    }
                    .foregroundStyle(.red)
                    .font(.caption.weight(.medium))
                }
            }

            Divider()
                .padding(.vertical, 2)

            HStack(spacing: 8) {
                secondaryActionButtons
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(cardBackground)
    }

    @ViewBuilder
    private var secondaryActionButtons: some View {
        compactSecondaryButton(title: "恢复默认", action: settings.resetToDefault)
        compactSecondaryButton(title: "切换为开发模式", action: onUseDevelopmentMode)
        compactSecondaryButton(title: "使用说明", action: onShowUsageTips)
    }

    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            commandEditorCard
                .frame(maxWidth: .infinity, alignment: .topLeading)

            commandReferenceSection
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var disclaimerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)

            Text("免责声明：Go2Claude 是非官方工具，使用后果自行承担。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }

    private var commandReferenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("配置说明")
                .font(.headline)

            LazyVGrid(columns: commandReferenceColumns, spacing: 10) {
                ForEach(commandReferences) { reference in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 8) {
                            Circle()
                                .fill(reference.accentColor)
                                .frame(width: 10, height: 10)

                            Text(reference.title)
                                .font(.headline)

                            Spacer(minLength: 8)

                            compactCommandReferenceActionIcon(
                                systemImage: "apple.terminal",
                                tint: reference.accentColor,
                                helpText: "在终端中运行\(reference.title)"
                            ) {
                                if onRunReferenceCommand(reference.command) {
                                    commandReferenceFeedback = .launched(title: reference.title)
                                }
                            }

                            compactCommandReferenceActionIcon(
                                systemImage: "doc.on.doc",
                                tint: .blue,
                                helpText: "复制\(reference.title)"
                            ) {
                                commandActionHandler.copyCommand(reference.command)
                                commandReferenceFeedback = .copied(title: reference.title)
                            }

                            compactCommandReferenceActionIcon(
                                systemImage: "arrow.down.to.line",
                                tint: .green,
                                helpText: "填入模板：\(reference.title)"
                            ) {
                                commandActionHandler.fillTemplate(with: reference.command)
                                commandReferenceFeedback = .applied(title: reference.title)
                            }
                        }

                        Text(reference.command)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(14)
                    .background(cardBackground)
                }
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
    }

    private var launchClaudeButton: some View {
        Button(action: primaryButtonAction) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                Text(launchClaudeButtonTitle)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(launchClaudeButtonBackground)
            .clipShape(Capsule())
            .shadow(color: Color.red.opacity(0.28), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var primaryButtonAction: () -> Void {
        switch primaryButtonMode {
        case .launchClaude:
            return onLaunchClaude
        case .installClaude, .waitingForInstall:
            return onOpenClaudeInstallGuide
        }
    }

    private var finderToolbarGuideButton: some View {
        Button(action: onRevealAppInFinder) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Text(finderToolbarGuideButtonTitle)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.68))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func compactSecondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.black.opacity(0.04))
            .clipShape(Capsule())
    }

    private func compactCommandReferenceActionIcon(
        systemImage: String,
        tint: Color,
        helpText: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(helpText)
        .accessibilityLabel(helpText)
    }
}
