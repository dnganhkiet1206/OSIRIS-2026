import XCTest
@testable import OsirisApplication
import OsirisCore

/// M6-1: the Application-layer view of automation is a pure mapping from the
/// stored rule — testable on any platform (the composition root supplies the
/// Store + ChatService wiring).
final class AutomationTests: XCTestCase {
    func testSummaryMapsRuleFields() {
        let rule = AutomationRule(
            id: "r1", projectID: ProjectID("p1"), goalText: "Weekly recap",
            trigger: .daily(hour: 9), enabled: false
        )

        let summary = AutomationRuleSummary.from(rule)

        XCTAssertEqual(summary.id, "r1")
        XCTAssertEqual(summary.goalText, "Weekly recap")
        XCTAssertEqual(summary.trigger, .daily(hour: 9))
        XCTAssertFalse(summary.enabled)
    }

    func testManualRuleSummaryDefaults() {
        let summary = AutomationRuleSummary.from(
            AutomationRule(id: "r2", projectID: ProjectID("p1"), goalText: "Do it")
        )
        XCTAssertEqual(summary.trigger, .manual)
        XCTAssertTrue(summary.enabled)
    }
}
