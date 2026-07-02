import XCTest
@testable import OsirisCore

final class SkillRegistryTests: XCTestCase {
    func testRegisterAndLookupByCapability() async {
        let registry = InMemorySkillRegistry()
        let skill = SkillDefinition(
            id: SkillID("summarize"),
            version: "1.0.0",
            capabilityTags: [CapabilityTag("summarization")],
            purpose: "Summarize text into key points",
            inputs: ["text"],
            outputs: ["summary"]
        )

        await registry.register(skill)

        let byID = await registry.skill(withID: SkillID("summarize"))
        XCTAssertEqual(byID?.purpose, "Summarize text into key points")

        let byCapability = await registry.skills(providing: CapabilityTag("summarization"))
        XCTAssertEqual(byCapability.count, 1)
        XCTAssertEqual(byCapability.first?.id, SkillID("summarize"))

        let missing = await registry.skills(providing: CapabilityTag("video-processing"))
        XCTAssertTrue(missing.isEmpty)
    }
}
