import XCTest
@testable import Go2ClaudeCore

final class TerminalLauncherTests: XCTestCase {
    func test_launchRunsGeneratedAppleScript() throws {
        var receivedScript: String?
        let launcher = TerminalLauncher(
            shellPathProvider: { "/bin/zsh" },
            scriptRunner: { script in
                receivedScript = script
            }
        )

        try launcher.launch(command: "cd '/tmp/Test Folder' && claude")

        XCTAssertEqual(
            receivedScript,
            launcher.appleScript(for: "cd '/tmp/Test Folder' && claude")
        )
    }

    func test_wrapsCommandWithLoginShell() {
        let launcher = TerminalLauncher(shellPathProvider: { "/bin/zsh" })

        let wrapped = launcher.wrappedCommand("cd '/tmp/Test Folder' && claude")

        XCTAssertEqual(
            wrapped,
            "/bin/zsh -lc 'cd '\"'\"'/tmp/Test Folder'\"'\"' && claude'"
        )
    }

    func test_buildsAppleScriptWithEscapedQuotes() {
        let launcher = TerminalLauncher(shellPathProvider: { "/bin/zsh" })

        let script = launcher.appleScript(for: "echo \"hello\"")

        XCTAssertTrue(script.contains("tell application \"Terminal\""))
        XCTAssertTrue(script.contains("/bin/zsh -lc 'echo \\\"hello\\\"'"))
    }

    func test_appleScript_usesLaunchBeforeDoScriptAndActivateAfter() {
        let launcher = TerminalLauncher(shellPathProvider: { "/bin/zsh" })

        let script = launcher.appleScript(for: "echo \"hello\"")
        let launchIndex = script.range(of: "launch")?.lowerBound
        let doScriptIndex = script.range(of: "do script")?.lowerBound
        let activateIndex = script.range(of: "activate")?.lowerBound

        XCTAssertNotNil(launchIndex)
        XCTAssertNotNil(doScriptIndex)
        XCTAssertNotNil(activateIndex)
        XCTAssertLessThan(launchIndex!, doScriptIndex!)
        XCTAssertLessThan(doScriptIndex!, activateIndex!)
        XCTAssertFalse(script.contains("in front window"))
    }
}
