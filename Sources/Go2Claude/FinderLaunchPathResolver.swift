import Foundation

enum FinderLaunchPathResolver {
    static func normalize(urls: [URL]) -> String? {
        guard let url = urls.first else {
            return nil
        }

        let standardizedURL = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: standardizedURL.path, isDirectory: &isDirectory)

        guard exists else {
            return nil
        }

        if isDirectory.boolValue, standardizedURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame {
            return nil
        }

        if isDirectory.boolValue {
            return standardizedURL.path
        }

        return standardizedURL.deletingLastPathComponent().path
    }
}
