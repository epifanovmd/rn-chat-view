import Testing
@testable import IOSChatView

@Suite("Кейс 5: Сокет-сообщение при скролле внизу")
struct Case05_SocketAtBottomTests {

    @Test("количество сообщений увеличивается на 1")
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
