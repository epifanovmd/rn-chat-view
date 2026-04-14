import Testing
@testable import IOSChatView

@Suite("Case 1: Initial load")
struct Case01_InitialLoadTests {

    // ── Unit ────────────────────────────────────────────────────────

    @Test("empty → messages = initial strategy")
    func diffStrategy() {
        let new = TestMsgFactory.batch(count: 3)
        let diff = MessageDiff.compute(old: [], new: new)
        #expect(MessageDiff.classify(old: [], new: new, diff: diff) == .initial)
    }

    @Test("all IDs inserted")
    func allInserted() {
        let new = TestMsgFactory.batch(count: 3)
        let diff = MessageDiff.compute(old: [], new: new)
        #expect(diff.insertedIDs.count == 3)
        #expect(diff.deletedIDs.isEmpty)
    }

    // ── Integration ─────────────────────────────────────────────────

    @Test("messages appear and scroll is at bottom")
    @MainActor func initialScrollToBottom() {
        let h = ChatTestHelper()
        let msgs = TestMsgFactory.batch(count: 20)
        h.setMessages(msgs)

        #expect(h.messageCount == 20)
        #expect(h.rowCount > 0)
        #expect(h.contentSize.height > 0)
    }

    @Test("layout heights computed for all rows")
    @MainActor func layoutHeights() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 10))

        for i in 0..<h.vc.chatLayout.rowLayoutData.count {
            #expect(h.vc.chatLayout.rowLayoutData[i].height > 0, "Row \(i) has zero height")
        }
    }
}
