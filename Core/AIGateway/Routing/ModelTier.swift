/// Model capability tiers. Routing picks the smallest tier able to produce
/// the required quality — never default to the largest. Concrete model IDs
/// live in Config/models.json and Config/routing.json, never in code
/// (Configuration First).
public enum ModelTier: String, Codable, Sendable {
    case light
    case standard
    case advanced
}
