import Combine
import Foundation

public final class AppSettings: ObservableObject {
    public static let commandTemplateKey = "commandTemplate"
    public static let claudeInstallationCheckCompletedKey = "claudeInstallationCheckCompleted"
    public static let defaultCommandTemplate = "cd %PATH% && claude --dangerously-skip-permissions"
    public static let developmentCommandTemplate = "cd %PATH% && claude"

    @Published public var commandTemplate: String {
        didSet {
            userDefaults.set(commandTemplate, forKey: Self.commandTemplateKey)
        }
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let storedTemplate = userDefaults.string(forKey: Self.commandTemplateKey), !storedTemplate.isEmpty {
            commandTemplate = storedTemplate
        } else {
            commandTemplate = Self.defaultCommandTemplate
            userDefaults.set(Self.defaultCommandTemplate, forKey: Self.commandTemplateKey)
        }
    }

    public func resetToDefault() {
        commandTemplate = Self.defaultCommandTemplate
    }

    public func useDevelopmentTemplate() {
        commandTemplate = Self.developmentCommandTemplate
    }

    public var hasCompletedClaudeInstallationCheck: Bool {
        userDefaults.bool(forKey: Self.claudeInstallationCheckCompletedKey)
    }

    public func markClaudeInstallationCheckCompleted() {
        userDefaults.set(true, forKey: Self.claudeInstallationCheckCompletedKey)
    }
}
