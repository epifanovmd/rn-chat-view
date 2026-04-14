import Testing
@testable import IOSChatView

@Suite("Кейс 20: Обновление содержимого при прокрутке вверх")
struct Case20_ContentUpdateDetachedTests {

    @Test("скролл остаётся на месте при редактировании выше")
    @MainActor func scrollStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()
        let offsetBefore = h.contentOffset.y

        // Edit first message (far above viewport)
        var msgs = h.messages
        if let idx = msgs.indices.first {
            msgs[idx] = TestMsgFactory.msg(msgs[idx].id, text: "Edited to be much longer with multiple lines\nLine2\nLine3\nLine4", offset: 0)
        }
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        // Bottom-stable: should shift up by the height delta
        #expect(h.messageCount == 30)
        // Offset should change but not wildly
        #expect(abs(offsetAfter - offsetBefore) < 200, "Scroll should be stable")
    }
}
