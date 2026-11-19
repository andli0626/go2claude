import AppKit
import Go2ClaudeCore

protocol CommandCopying {
    func copy(_ command: String)
}

struct CommandReferenceActionHandler {
    let settings: AppSettings
    let commandCopier: any CommandCopying

    init(
        settings: AppSettings,
        commandCopier: any CommandCopying = PasteboardCommandCopier()
    ) {
        self.settings = settings
        self.commandCopier = commandCopier
    }

    func fillTemplate(with command: String) {
        settings.commandTemplate = command
    }

    func copyCommand(_ command: String) {
        commandCopier.copy(command)
    }
}

struct PasteboardCommandCopier: CommandCopying {
    func copy(_ command: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)
    }
}
