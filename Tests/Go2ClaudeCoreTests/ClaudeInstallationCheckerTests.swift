import XCTest
@testable import Go2ClaudeCore

final class ClaudeInstallationCheckerTests: XCTestCase {
    func test_returnsInstalledWhenCommandLocatorFindsClaudePath() {
        let checker = ClaudeInstallationChecker(
            shellPathProvider: { "/bin/zsh" },
            commandLocator: { shellPath, command in
                XCTAssertEqual(shellPath, "/bin/zsh")
                XCTAssertEqual(command, "claude")
                return "/opt/homebrew/bin/claude\n"
            }
        )

        let status = checker.claudeInstallationStatus()

        XCTAssertEqual(status, .installed(executablePath: "/opt/homebrew/bin/claude"))
    }

    func test_returnsNotInstalledWhenCommandLocatorReturnsNil() {
        let checker = ClaudeInstallationChecker(
            shellPathProvider: { "/bin/zsh" },
            commandLocator: { _, _ in nil }
        )

        let status = checker.claudeInstallationStatus()

        XCTAssertEqual(status, .notInstalled)
    }

    func test_returnsInstalledWhenCommandLocatorReturnsShellWrapperName() {
        let checker = ClaudeInstallationChecker(
            shellPathProvider: { "/bin/zsh" },
            commandLocator: { _, _ in "claude\n" }
        )

        let status = checker.claudeInstallationStatus()

        XCTAssertEqual(status, .installed(executablePath: "claude"))
    }

    func test_returnsNotInstalledWhenCommandLocatorThrows() {
        let checker = ClaudeInstallationChecker(
            shellPathProvider: { "/bin/zsh" },
            commandLocator: { _, _ in
                struct LocatorError: Error {}
                throw LocatorError()
            }
        )

        let status = checker.claudeInstallationStatus()

        XCTAssertEqual(status, .notInstalled)
    }

    func test_returnsInstalledWhenClaudeIsAvailableFromInteractiveZshConfiguration() throws {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let binDirectory = tempDirectory.appendingPathComponent("bin", isDirectory: true)
        let claudeURL = binDirectory.appendingPathComponent("claude")
        let zshrcURL = tempDirectory.appendingPathComponent(".zshrc")

        try fileManager.createDirectory(at: binDirectory, withIntermediateDirectories: true)
        try """
        #!/bin/sh
        exit 0
        """.write(to: claudeURL, atomically: true, encoding: .utf8)
        try """
        export PATH="\(binDirectory.path):$PATH"
        """.write(to: zshrcURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: claudeURL.path
        )

        let originalHome = ProcessInfo.processInfo.environment["HOME"]
        let originalPath = ProcessInfo.processInfo.environment["PATH"]

        defer {
            if let originalHome {
                setenv("HOME", originalHome, 1)
            } else {
                unsetenv("HOME")
            }

            if let originalPath {
                setenv("PATH", originalPath, 1)
            } else {
                unsetenv("PATH")
            }

            try? fileManager.removeItem(at: tempDirectory)
        }

        setenv("HOME", tempDirectory.path, 1)
        setenv("PATH", "/usr/bin:/bin:/usr/sbin:/sbin", 1)

        let checker = ClaudeInstallationChecker(shellPathProvider: { "/bin/zsh" })

        let status = checker.claudeInstallationStatus()

        XCTAssertEqual(status, .installed(executablePath: claudeURL.path))
    }
}
