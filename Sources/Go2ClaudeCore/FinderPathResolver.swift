import Foundation
import OSLog

public protocol FinderPathResolving {
    func resolveCurrentFinderPath() throws -> String
}

public struct FinderPathResolver: FinderPathResolving {
    private let logger = Logger(subsystem: "com.lilin.Go2Claude", category: "FinderPathResolver")

    public enum Error: Swift.Error, LocalizedError, Equatable {
        case noOpenFinderWindow
        case appleScriptFailed(String)

        public var errorDescription: String? {
            switch self {
            case .noOpenFinderWindow:
                "没有找到已打开的 Finder 窗口，请先打开一个文件夹后再试。"
            case .appleScriptFailed(let message):
                "读取 Finder 当前目录失败：\(message)"
            }
        }
    }

    public init() {}

    public func resolveCurrentFinderPath() throws -> String {
        logger.info("开始通过 AppleScript 解析 Finder 当前目录")
        let script = """
        activate application "System Events"
        tell application "Finder"
            activate
            if (count of Finder windows) is 0 then
                error "No Finder window is open."
            end if
            try
                set targetAlias to (target of front Finder window) as alias
                return POSIX path of targetAlias
            on error
                return POSIX path of ((insertion location) as alias)
            end try
        end tell
        """

        do {
            let path = try AppleScriptRunner.run(script)
            logger.info("AppleScript 成功解析 Finder 路径：\(path, privacy: .public)")
            return path
        } catch let error as AppleScriptRunner.Error {
            if error.message.contains("No Finder window is open.") {
                logger.error("AppleScript 未找到已打开的 Finder 窗口")
                throw Error.noOpenFinderWindow
            }

            logger.error("AppleScript 解析 Finder 路径失败：\(error.message, privacy: .public)")
            throw Error.appleScriptFailed(error.message)
        }
    }
}
