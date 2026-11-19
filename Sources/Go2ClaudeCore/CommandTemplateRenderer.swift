import Foundation

public struct CommandTemplateRenderer {
    public enum Error: Swift.Error, LocalizedError, Equatable {
        case missingPathPlaceholder

        public var errorDescription: String? {
            switch self {
            case .missingPathPlaceholder:
                "命令模板必须包含 %PATH% 占位符。"
            }
        }
    }

    public static let pathPlaceholder = "%PATH%"

    public init() {}

    public func render(template: String, finderPath: String) throws -> String {
        guard template.contains(Self.pathPlaceholder) else {
            throw Error.missingPathPlaceholder
        }

        return template.replacingOccurrences(
            of: Self.pathPlaceholder,
            with: shellQuote(path: finderPath)
        )
    }

    private func shellQuote(path: String) -> String {
        let escaped = path.replacingOccurrences(of: "'", with: "'\"'\"'")
        return "'\(escaped)'"
    }
}
