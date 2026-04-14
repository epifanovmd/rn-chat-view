import Testing
@testable import IOSChatView

@Suite("Кейс 10: Удаление + обновление одновременно")
struct Case10_DeleteAndUpdateTests {

    @Test("оба изменения применяются")
    @MainActor func bothApplied() {
        let h = ChatTestHelper()
        h.setMessages([TestMsgFactory.msg("1", text: "old"), TestMsgFactory.msg("2"), TestMsgFactory.msg("3")])
        #expect(h.messageCount == 3)

        h.setMessages([TestMsgFactory.msg("1", text: "new"), TestMsgFactory.msg("3")])
        #expect(h.messageCount == 2)
    }
}
