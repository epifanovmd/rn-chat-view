import Testing
@testable import IOSChatView

@Suite("Кейс 9: Удаление сообщения")
struct Case09_DeleteTests {

    @Test("количество сообщений уменьшается")
    @MainActor func countDecreases() {
        let h = ChatTestHelper()
        let msgs = TestMsgFactory.batch(count: 10)
        h.setMessages(msgs)
        #expect(h.messageCount == 10)

        var updated = msgs
        updated.remove(at: 5)
        h.setMessages(updated)
        #expect(h.messageCount == 9)
    }

    @Test("скролл сохраняется после удаления в середине")
    @MainActor func scrollPreserved() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        var msgs = h.messages
        msgs.remove(at: msgs.count / 2)
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        #expect(abs(offsetAfter - offsetBefore) < 100, "Scroll jumped: \(offsetBefore) → \(offsetAfter)")
    }
}
