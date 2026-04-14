import Testing
@testable import IOSChatView

@Suite("Case 6: Socket message while scrolled up")
struct Case06_SocketScrolledUpTests {

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
