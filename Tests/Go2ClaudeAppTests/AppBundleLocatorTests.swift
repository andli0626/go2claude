import XCTest
@testable import Go2Claude

final class AppBundleLocatorTests: XCTestCase {
    func test_toolbarHelperURLReturnsSiblingHelperApp() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let mainAppURL = tempDirectory.appendingPathComponent("Go2Claude.app", isDirectory: true)
        let helperAppURL = tempDirectory.appendingPathComponent("Go2Claude Toolbar.app", isDirectory: true)
        try FileManager.default.createDirectory(at: mainAppURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: helperAppURL, withIntermediateDirectories: true)

        let resolvedURL = AppBundleLocator.toolbarHelperURL(from: mainAppURL)

        XCTAssertEqual(resolvedURL, helperAppURL)
    }

    func test_toolbarHelperURLReturnsNilWhenHelperIsMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let mainAppURL = tempDirectory.appendingPathComponent("Go2Claude.app", isDirectory: true)
        try FileManager.default.createDirectory(at: mainAppURL, withIntermediateDirectories: true)

        XCTAssertNil(AppBundleLocator.toolbarHelperURL(from: mainAppURL))
    }
}
