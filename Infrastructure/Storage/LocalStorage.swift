import Foundation

/// Local-first byte storage. The physical foundation Core's Store persists
/// through. Read locally, process locally, cache locally.
///
/// Keys may contain `/` to form a hierarchy (e.g. `project-state/p1.json`);
/// `keys(withPrefix:)` enumerates the keys stored under one such prefix.
public protocol LocalStorage: Sendable {
    func read(key: String) throws -> Data?
    func write(_ data: Data, key: String) throws
    func delete(key: String) throws
    func keys(withPrefix prefix: String) throws -> [String]
}

/// Stores each key as a file inside a base directory; key prefixes map to
/// subdirectories.
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
        let url = baseDirectory.appendingPathComponent(key)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    public func delete(key: String) throws {
        let url = baseDirectory.appendingPathComponent(key)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    public func keys(withPrefix prefix: String) throws -> [String] {
        let directory = baseDirectory.appendingPathComponent(prefix)
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .sorted()
            .map { "\(prefix)/\($0)" }
    }
}
