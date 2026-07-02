import XCTest
@testable import OsirisInfrastructure

final class EventBusTests: XCTestCase {
    func testSubscriberReceivesPublishedEvents() async {
        let bus = EventBus<String>()
        let stream = await bus.events()

        await bus.publish("first")
        await bus.publish("second")

        var received: [String] = []
        for await event in stream {
            received.append(event)
            if received.count == 2 { break }
        }
        XCTAssertEqual(received, ["first", "second"])
    }
}
