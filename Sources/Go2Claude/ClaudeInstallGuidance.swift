import AppKit
import Foundation

struct ClaudeInstallGuidance: Equatable {
    static let installGuideURL = URL(string: "https://docs.anthropic.com/en/docs/claude-code/getting-started")!
    static let installCommand = "npm install -g @anthropic-ai/claude-code"
    static let `default` = ClaudeInstallGuidance(
        title: "未检测到 Claude CLI",
        message: "当前 Mac 上没有检测到可直接运行的 `claude` 命令，请先完成 Claude Code 安装。",
        installButtonTitle: "查看安装指南",
        installURL: installGuideURL,
        installCommand: installCommand
    )

    let title: String
    let message: String
    let installButtonTitle: String
    let installURL: URL
    let installCommand: String
}

enum ClaudeInstallGuidanceAction {
    case openInstallGuide
    case dismiss
}

@MainActor
protocol ClaudeInstallGuidancePresenting {
    func presentMissingClaudeInstallGuidance(_ guidance: ClaudeInstallGuidance) -> ClaudeInstallGuidanceAction
}

@MainActor
struct ClaudeInstallGuidanceAlertPresenter: ClaudeInstallGuidancePresenting {
    func presentMissingClaudeInstallGuidance(_ guidance: ClaudeInstallGuidance) -> ClaudeInstallGuidanceAction {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = guidance.title
        alert.informativeText = """
        \(guidance.message)

        推荐安装命令：
        \(guidance.installCommand)

        你也可以点击“\(guidance.installButtonTitle)”查看官方安装文档。
        """
        alert.addButton(withTitle: guidance.installButtonTitle)
        alert.addButton(withTitle: "稍后再说")

        let response = alert.runModal()
        return response == .alertFirstButtonReturn ? .openInstallGuide : .dismiss
    }
}

protocol ExternalResourceOpening {
    func open(_ url: URL)
}

struct WorkspaceResourceOpener: ExternalResourceOpening {
    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
