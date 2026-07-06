import XCTest
@testable import OsirisApplication
import OsirisCore

/// M2-5: the Advanced panel's skill inventory — pure mapping from Core.
final class SkillListingTests: XCTestCase {
    func testMapsSkillDefinitionFields() {
        let info = SkillInfo.from(GenericSkills.summarize)

        XCTAssertEqual(info.id, "core.summarize")
        XCTAssertEqual(info.version, "1.0.0")
        XCTAssertFalse(info.purpose.isEmpty)
        XCTAssertFalse(info.isComposition)
    }

    func testCompositionSkillIsBadged() {
        let info = SkillInfo.from(GenericSkills.researchThenDraft)

        XCTAssertTrue(info.isComposition)
    }

    func testAllBuiltInsMapCleanly() {
        let infos = GenericSkills.all.map(SkillInfo.from)

        XCTAssertEqual(infos.count, 4)
        XCTAssertEqual(infos.filter(\.isComposition).count, 1)
        XCTAssertEqual(Set(infos.map(\.id)).count, 4, "IDs stay unique")
    }
}
