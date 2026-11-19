import Go2ClaudeCore
import XCTest
@testable import Go2Claude

final class CommandReferenceActionHandlerTests: XCTestCase {
    func test_fillTemplateUpdatesSettingsCommandTemplate() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let settings = AppSettings(userDefaults: defaults)
        let handler = CommandReferenceActionHandler(
            settings: settings,
            commandCopier: CommandCopierStub()
        )

        handler.fillTemplate(with: "cd %PATH% && claude")

        XCTAssertEqual(settings.commandTemplate, "cd %PATH% && claude")
        XCTAssertEqual(defaults.string(forKey: AppSettings.commandTemplateKey), "cd %PATH% && claude")
    }

    func test_copyCommandForwardsStringToCommandCopier() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let copier = CommandCopierStub()
        let handler = CommandReferenceActionHandler(
            settings: AppSettings(userDefaults: defaults),
            commandCopier: copier
        )

        handler.copyCommand("open -a Go2Claude")

        XCTAssertEqual(copier.copiedCommands, ["open -a Go2Claude"])
    }
}

private final class CommandCopierStub: CommandCopying {
    private(set) var copiedCommands: [String] = []

    func copy(_ command: String) {
        copiedCommands.append(command)
    }
}
