import Foundation

/// Local-first byte storage. The physical foundation Core's Store persists
/// through. Read locally, process locally, cache locally.
public protocol LocalStorage: Sendable {
    func read(key: String) throws -> Data?
    func write(_ data: Data, key: String) throws
    func delete(key: String) throws
}

/// Stores each key as a file inside a base directory.
public struct FileStorage: LocalStorage {
    private let baseDirectory: URL

    public init(baseDirectory: URL) throws {
        self.baseDirectory = baseDirectory
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    public func read(key: String) throws -> Data? {
        let url = baseDirectory.appendingPathComponent(key)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try Data(contentsOf: url)
    }

    public func write(_ data: Data, key: String) throws {
        try data.write(to: baseDirectory.appendingPathComponent(key), options: .atomic)
    }

    public func delete(key: String) throws {
        let url = baseDirectory.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
