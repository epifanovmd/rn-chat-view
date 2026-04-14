import Testing
@testable import IOSChatView

@Suite("Case 10: Delete + update simultaneously")
struct Case10_DeleteAndUpdateTests {

    @Test("both changes applied")
    @MainActor func bothApplied() {
        let h = ChatTestHelper()
        h.setMessages([TestMsgFactory.msg("1", text: "old"), TestMsgFactory.msg("2"), TestMsgFactory.msg("3")])
        #expect(h.messageCount == 3)

        h.setMessages([TestMsgFactory.msg("1", text: "new"), TestMsgFactory.msg("3")])
        #expect(h.messageCount == 2)
    }
}
