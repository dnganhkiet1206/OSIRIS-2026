import Foundation

/// Loads configuration artifacts from the Config directory.
/// Behavior changes through configuration, not code (Configuration First).
/// The static System Preamble (Vision, AD-13/AD-23) is loaded here as text.
public struct ConfigurationLoader: Sendable {
    public enum Error: Swift.Error {
        case fileNotFound(String)
    }

    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func loadJSON<T: Decodable>(_ type: T.Type, file: String) throws -> T {
        let url = directory.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Error.fileNotFound(file)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    public func loadText(file: String) throws -> String {
        let url = directory.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Error.fileNotFound(file)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}
