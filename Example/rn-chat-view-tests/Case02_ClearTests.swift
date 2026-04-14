import Testing
@testable import IOSChatView

@Suite("Case 2: Clear all messages")
struct Case02_ClearTests {

    @Test("clear removes all messages and rows")
    @MainActor func clearRemovesAll() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 10))
        #expect(h.messageCount == 10)

        h.setMessages([])
        #expect(h.messageCount == 0)
        #expect(h.rowCount == 0)
        #expect(h.contentSize.height == 0 || h.contentSize.height < 1)
    }
}
