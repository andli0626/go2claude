import Combine
import Foundation
import Go2ClaudeCore

@MainActor
final class SettingsWindowState: ObservableObject {
    @Published var launchMessage: String?
    @Published var claudeInstallationStatus: ClaudeInstallationStatus?
    @Published var shouldRefreshClaudeInstallationStatusWhenActive = false
    @Published var isWaitingForClaudeInstallation = false
}
