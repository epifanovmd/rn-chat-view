import Testing
@testable import IOSChatView

@Suite("Case 5: Socket message at bottom")
struct Case05_SocketAtBottomTests {

    @Test("single append = appendOnly strategy")
    func diffStrategy() {
        let old = TestMsgFactory.batch(count: 5)
        let new = old + [TestMsgFactory.msg("new1", offset: 300)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .appendOnly)
        #expect(diff.insertedIDs.count == 1)
    }

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
