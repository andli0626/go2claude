import Foundation

public enum ClaudeInstallationStatus: Equatable, Sendable {
    case installed(executablePath: String)
    case notInstalled
}

public protocol ClaudeInstallationChecking: Sendable {
    func claudeInstallationStatus() -> ClaudeInstallationStatus
}

public struct ClaudeInstallationChecker: ClaudeInstallationChecking {
    private static let shellInvocationModes = ["-ilc", "-lc"]

    private let shellPathProvider: @Sendable () -> String
    private let commandLocator: @Sendable (String, String) throws -> String?

    public init(
        shellPathProvider: @escaping @Sendable () -> String = { UserShell.currentShellPath() }
    ) {
        self.init(
            shellPathProvider: shellPathProvider,
            commandLocator: { shellPath, command in
                try Self.locateCommand(named: command, shellPath: shellPath)
            }
        )
    }

    init(
        shellPathProvider: @escaping @Sendable () -> String,
        commandLocator: @escaping @Sendable (String, String) throws -> String?
    ) {
        self.shellPathProvider = shellPathProvider
        self.commandLocator = commandLocator
    }

    public func claudeInstallationStatus() -> ClaudeInstallationStatus {
        do {
            let shellPath = shellPathProvider()
            guard
                let executablePath = try commandLocator(shellPath, "claude")?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !executablePath.isEmpty
            else {
                return .notInstalled
            }

            return .installed(executablePath: executablePath)
        } catch {
            return .notInstalled
        }
    }

    private static func locateCommand(named command: String, shellPath: String) throws -> String? {
        for shellInvocationMode in shellInvocationModes {
            if let executablePath = try locateCommand(
                named: command,
                shellPath: shellPath,
                shellInvocationMode: shellInvocationMode
            ) {
                return executablePath
            }
        }

        return nil
    }

    private static func locateCommand(
        named command: String,
        shellPath: String,
        shellInvocationMode: String
    ) throws -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: shellPath)
        process.arguments = [shellInvocationMode, commandLookupScript(for: command)]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )

        return executablePath(from: output)
    }

    private static func executablePath(from output: String?) -> String? {
        guard let output else {
            return nil
        }

        let lines = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.reversed().first { $0.hasPrefix("/") } ?? lines.last
    }

    private static func commandLookupScript(for command: String) -> String {
        """
        if whence -p \(command) >/dev/null 2>&1; then
          whence -p \(command)
        elif type -p \(command) >/dev/null 2>&1; then
          type -p \(command)
        else
          command -v -- \(command)
        fi
        """
    }
}
