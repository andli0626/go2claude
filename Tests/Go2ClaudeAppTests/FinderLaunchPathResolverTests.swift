import Foundation
import XCTest
@testable import Go2Claude

final class FinderLaunchPathResolverTests: XCTestCase {
    func test_returnsDirectoryPathWhenDirectoryIsPassed() throws {
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory())

        let resolvedPath = FinderLaunchPathResolver.normalize(urls: [directoryURL])

        XCTAssertEqual(resolvedPath, directoryURL.standardizedFileURL.path)
    }

    func test_returnsParentDirectoryWhenFileIsPassed() throws {
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("sample.txt")
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("demo".utf8))

        let resolvedPath = FinderLaunchPathResolver.normalize(urls: [fileURL])

        XCTAssertEqual(resolvedPath, directoryURL.standardizedFileURL.path)
    }

    func test_returnsNilForMissingPath() {
        let missingURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)

        let resolvedPath = FinderLaunchPathResolver.normalize(urls: [missingURL])

        XCTAssertNil(resolvedPath)
    }

    func test_returnsNilForAppBundleDirectory() throws {
        let appBundleURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(UUID().uuidString).app", isDirectory: true)
        try FileManager.default.createDirectory(at: appBundleURL, withIntermediateDirectories: true)

        let resolvedPath = FinderLaunchPathResolver.normalize(urls: [appBundleURL])

        XCTAssertNil(resolvedPath)
    }
}
