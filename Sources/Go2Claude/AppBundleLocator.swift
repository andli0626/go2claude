import Foundation

enum AppBundleLocator {
    private static let toolbarHelperBundleName = "Go2Claude Toolbar.app"

    static func revealableURL(from bundleURL: URL) -> URL {
        if bundleURL.pathExtension == "app" {
            return bundleURL
        }

        return bundleURL.deletingLastPathComponent()
    }

    static func toolbarHelperURL(from bundleURL: URL, fileManager: FileManager = .default) -> URL? {
        let appBundleURL = bundleURL.pathExtension == "app" ? bundleURL : bundleURL.deletingLastPathComponent()
        let siblingDirectoryURL = appBundleURL.deletingLastPathComponent()
        let siblingHelperURL = siblingDirectoryURL.appendingPathComponent(toolbarHelperBundleName, isDirectory: true)

        if fileManager.fileExists(atPath: siblingHelperURL.path) {
            return siblingHelperURL
        }

        return nil
    }
}
