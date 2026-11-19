import XCTest
@testable import Go2ClaudeCore

final class AppSettingsTests: XCTestCase {
    func test_initializesWithDefaultTemplateWhenNoSavedValueExists() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settings = AppSettings(userDefaults: defaults)

        XCTAssertEqual(settings.commandTemplate, AppSettings.defaultCommandTemplate)
        XCTAssertEqual(
            defaults.string(forKey: AppSettings.commandTemplateKey),
            AppSettings.defaultCommandTemplate
        )
    }

    func test_persistsCommandTemplateUpdates() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = AppSettings(userDefaults: defaults)

        settings.commandTemplate = "cd %PATH% && claude"

        XCTAssertEqual(defaults.string(forKey: AppSettings.commandTemplateKey), "cd %PATH% && claude")
    }

    func test_marksClaudeInstallationCheckAsCompleted() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = AppSettings(userDefaults: defaults)

        XCTAssertFalse(settings.hasCompletedClaudeInstallationCheck)

        settings.markClaudeInstallationCheckCompleted()

        XCTAssertTrue(settings.hasCompletedClaudeInstallationCheck)
        XCTAssertEqual(defaults.bool(forKey: AppSettings.claudeInstallationCheckCompletedKey), true)
    }
}
