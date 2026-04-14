import Testing
@testable import IOSChatView

@Suite("Кейс 6: Сокет-сообщение при прокрутке вверх")
struct Case06_SocketScrolledUpTests {

    @Test("скролл остаётся вверху при добавлении нового сообщения")
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
