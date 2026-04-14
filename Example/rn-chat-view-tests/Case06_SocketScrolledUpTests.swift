import Testing
@testable import IOSChatView

@Suite("Case 6: Socket message while scrolled up")
struct Case06_SocketScrolledUpTests {

    @Test("same strategy = appendOnly")
    func diffStrategy() {
        let old = TestMsgFactory.batch(count: 5)
        let new = old + [TestMsgFactory.msg("new1", offset: 300)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .appendOnly)
    }

    @Test("scroll stays at top when new message appended")
    @MainActor func scrollStaysAtTop() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 20))
        h.scrollToTop()
        let offsetBefore = h.contentOffset.y

        h.setMessages(h.messages + [TestMsgFactory.msg("new1", offset: 1200)])

        let offsetAfter = h.contentOffset.y
        #expect(abs(offsetAfter - offsetBefore) < 5, "Scroll should not move when scrolled up")
    }
}
