import Testing
@testable import IOSChatView

@Suite("Кейс 21: Пакетные сокет-события")
struct Case21_BatchSocketTests {

    @Test("пакет изменений применяется корректно")
    @MainActor func batchApplied() {
        let h = ChatTestHelper()
        h.setMessages([TestMsgFactory.msg("1", status: .sent), TestMsgFactory.msg("2")])
        #expect(h.messageCount == 2)

        h.setMessages([
            TestMsgFactory.msg("1", status: .read, reactions: [Reaction(emoji: "❤️", count: 1, isSelected: false)]),
            TestMsgFactory.msg("2"),
            TestMsgFactory.msg("3", offset: 120),
        ])
        #expect(h.messageCount == 3)
    }
}
