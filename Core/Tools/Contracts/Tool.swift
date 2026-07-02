import Foundation

/// Unique identifier of a tool.
public struct ToolID: Hashable, Codable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// Real-world adapter contract. Tools are always preferred over AI when they
/// can do the same job (AI Is The Last Tool). Two classes share this one
/// interface: on-device (Apple frameworks, URLSession directly — AD-27) and
/// remote MCP tools (optional, from M6 — AD-18). Adding a tool is adding an
/// adapter; the Core does not change.
public protocol Tool: Sendable {
    var id: ToolID { get }
    func run(_ input: ToolInput) async throws -> ToolOutput
}

public struct ToolInput: Sendable {
    public let parameters: [String: String]

    public init(parameters: [String: String] = [:]) {
        self.parameters = parameters
    }
}

public struct ToolOutput: Sendable {
    public let content: String

    public init(content: String) {
        self.content = content
    }
}
