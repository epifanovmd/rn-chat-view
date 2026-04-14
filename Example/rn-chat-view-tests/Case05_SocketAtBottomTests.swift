import Testing
@testable import IOSChatView

@Suite("Case 5: Socket message at bottom")
struct Case05_SocketAtBottomTests {

    @Test("message count increases by 1")
    @MainActor func countIncreases() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 10))
        h.scrollToBottom()
        #expect(h.messageCount == 10)

        let newMsg = TestMsgFactory.msg("new1", offset: 600)
        h.setMessages(h.messages + [newMsg])
        #expect(h.messageCount == 11)
    }
}
