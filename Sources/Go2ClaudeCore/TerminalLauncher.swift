import Darwin
import Foundation
import OSLog

public protocol TerminalLaunching {
    func launch(command: String) throws
}

public struct TerminalLauncher: TerminalLaunching {
    private let logger = Logger(subsystem: "com.lilin.Go2Claude", category: "TerminalLauncher")

    public enum Error: Swift.Error, LocalizedError, Equatable {
        case appleScriptFailed(String)

        public var errorDescription: String? {
            switch self {
            case .appleScriptFailed(let message):
                "在 Terminal 中启动 Claude 失败：\(message)"
            }
        }
    }

    private let shellPathProvider: () -> String
    private let scriptRunner: (String) throws -> Void

    public init(
        shellPathProvider: @escaping () -> String = { UserShell.currentShellPath() },
        scriptRunner: @escaping (String) throws -> Void = { script in
            _ = try AppleScriptRunner.runOptional(script)
        }
    ) {
        self.shellPathProvider = shellPathProvider
        self.scriptRunner = scriptRunner
    }

    func wrappedCommand(_ command: String) -> String {
        "\(shellPathProvider()) -lc \(shellQuote(command))"
    }

    func appleScript(for command: String) -> String {
        let appleScriptCommand = wrappedCommand(command)
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        return """
        tell application "Terminal"
            launch
            do script "\(appleScriptCommand)"
            activate
        end tell
        """
    }

    public func launch(command: String) throws {
        let script = appleScript(for: command)
        logger.info("准备通过 Terminal 启动命令：\(wrappedCommand(command), privacy: .public)")
        logger.debug("Terminal AppleScript 执行顺序：launch -> do script -> activate")

        do {
            try scriptRunner(script)
            logger.info("Terminal AppleScript 执行成功")
        } catch let error as AppleScriptRunner.Error {
            logger.error("Terminal AppleScript 执行失败：\(error.message, privacy: .public)")
            throw Error.appleScriptFailed(error.message)
        } catch {
            logger.error("Terminal 启动失败：\(error.localizedDescription, privacy: .public)")
            throw Error.appleScriptFailed(error.localizedDescription)
        }
    }

    private func shellQuote(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "'", with: "'\"'\"'")
        return "'\(escaped)'"
    }
}

public enum UserShell {
    public static func currentShellPath() -> String {
        guard let userInfo = getpwuid(getuid()), let shellPointer = userInfo.pointee.pw_shell else {
            return "/bin/zsh"
        }

        let shellPath = String(cString: shellPointer)
        return shellPath.isEmpty ? "/bin/zsh" : shellPath
    }
}
