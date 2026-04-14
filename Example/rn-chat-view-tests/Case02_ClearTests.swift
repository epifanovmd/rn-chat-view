import Testing
@testable import IOSChatView

@Suite("Кейс 2: Очистка всех сообщений")
struct Case02_ClearTests {

    @Test("очистка удаляет все сообщения и строки")
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
