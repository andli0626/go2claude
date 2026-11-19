import XCTest
@testable import Go2ClaudeCore

final class CommandTemplateRendererTests: XCTestCase {
    private let renderer = CommandTemplateRenderer()

    func test_requiresPathPlaceholder() {
        XCTAssertThrowsError(
            try renderer.render(
                template: "claude --dangerously-skip-permissions",
                finderPath: "/Users/lilin/Downloads"
            )
        ) { error in
            XCTAssertEqual(error as? CommandTemplateRenderer.Error, .missingPathPlaceholder)
        }
    }

    func test_replacesPlaceholderWithShellEscapedPath() throws {
        let command = try renderer.render(
            template: "cd %PATH% && claude --dangerously-skip-permissions",
            finderPath: "/Users/lilin/中文 & Demo/O'Reilly (Test)"
        )

        XCTAssertEqual(
            command,
            "cd '/Users/lilin/中文 & Demo/O'\"'\"'Reilly (Test)' && claude --dangerously-skip-permissions"
        )
    }
}
