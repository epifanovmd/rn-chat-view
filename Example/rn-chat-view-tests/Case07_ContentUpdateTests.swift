import Testing
@testable import IOSChatView

@Suite("Case 7: Content updates")
struct Case07_ContentUpdateTests {

    @Test("height changes when text gets longer")
    @MainActor func heightChangesOnEdit() {
        let h = ChatTestHelper()
        let short = TestMsgFactory.msg("1", text: "Hi")
        h.setMessages([short])

        let heightBefore = h.layoutHeight(forMessageId: "1")
        #expect(heightBefore != nil && heightBefore! > 0)

        let long = TestMsgFactory.msg("1", text: "This is a much longer message that should definitely require more vertical space in the cell layout.")
        h.setMessages([long])

        let heightAfter = h.layoutHeight(forMessageId: "1")
        #expect(heightAfter != nil)
        #expect(heightAfter! > heightBefore!, "Height should increase: \(heightBefore!) → \(heightAfter!)")
    }

    @Test("scroll stays in place on content update")
    @MainActor func scrollStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 20))
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        // Edit a message
        var msgs = h.messages
        if let idx = msgs.indices.first(where: { msgs[$0].id == "1" }) {
            msgs[idx] = TestMsgFactory.msg("1", text: "edited text")
        }
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        // Bottom-stable: offset may shift if changed msg is below viewport, but shouldn't jump wildly
        #expect(abs(offsetAfter - offsetBefore) < 100, "Scroll jumped too much: \(offsetBefore) → \(offsetAfter)")
    }
}
