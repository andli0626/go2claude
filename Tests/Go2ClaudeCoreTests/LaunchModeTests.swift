import XCTest
@testable import Go2ClaudeCore

final class LaunchModeTests: XCTestCase {
    func test_defaultsToMainInterface() {
        let mode = LaunchMode(arguments: ["Go2Claude"])

        XCTAssertEqual(mode, .mainInterface)
    }

    func test_parsesConfigurationMode() {
        let mode = LaunchMode(arguments: ["Go2Claude", "config"])

        XCTAssertEqual(mode, .configuration)
    }
}
