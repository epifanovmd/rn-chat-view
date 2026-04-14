import Testing
@testable import IOSChatView

@Suite("Кейс 4: Добавление новых сообщений (пагинация)")
struct Case04_AppendPaginationTests {

    @Test("скролл остаётся на месте (НЕ прыгает вниз)")
    @MainActor func scrollPreserved() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 20, startId: 1, baseOffset: 0))

        // Scroll to top
        h.scrollToTop()
        let offsetBefore = h.contentOffset.y

        // Append 30 newer
        let newer = TestMsgFactory.batch(count: 30, startId: 21, baseOffset: 1200)
        h.setMessages(h.messages + newer)

        let offsetAfter = h.contentOffset.y

        #expect(h.messageCount == 50)
        // Offset should stay approximately the same (not jump to bottom)
        #expect(abs(offsetAfter - offsetBefore) < 5, "Scroll should stay in place, delta=\(offsetAfter - offsetBefore)")
    }
}
