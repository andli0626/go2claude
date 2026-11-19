import Foundation

public enum AppleScriptRunner {
    struct Error: Swift.Error {
        let message: String
    }

    @discardableResult
    static func run(_ script: String) throws -> String {
        guard let appleScript = NSAppleScript(source: script) else {
            throw Error(message: "AppleScript 初始化失败。")
        }

        var errorInfo: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "未知错误"
            throw Error(message: message)
        }

        guard let value = result.stringValue, !value.isEmpty else {
            throw Error(message: "AppleScript 没有返回有效结果。")
        }

        return value
    }

    @discardableResult
    public static func runOptional(_ script: String) throws -> NSAppleEventDescriptor? {
        guard let appleScript = NSAppleScript(source: script) else {
            throw Error(message: "AppleScript 初始化失败。")
        }

        var errorInfo: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorInfo)

        if let errorInfo {
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? "未知错误"
            throw Error(message: message)
        }

        return result
    }
}
