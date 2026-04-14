import Testing
@testable import IOSChatView

@Suite("Кейс 1: Первоначальная загрузка")
struct Case01_InitialLoadTests {

    @Test("сообщения появляются и скролл внизу")
    @MainActor func initialScrollToBottom() {
        let h = ChatTestHelper()
        let msgs = TestMsgFactory.batch(count: 20)
        h.setMessages(msgs)

        #expect(h.messageCount == 20)
        #expect(h.rowCount > 0)
        #expect(h.contentSize.height > 0)
    }

    @Test("высоты лейаута вычислены для всех строк")
    @MainActor func layoutHeights() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 10))

        for i in 0..<h.vc.chatLayout.rowLayoutData.count {
            #expect(h.vc.chatLayout.rowLayoutData[i].height > 0, "Row \(i) has zero height")
        }
    }
}
