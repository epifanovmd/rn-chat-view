import Testing
@testable import IOSChatView

@Suite("Case 10: Delete + update simultaneously")
struct Case10_DeleteAndUpdateTests {

    @Test("1 deleted + 1 updated = structural")
    func diffStrategy() {
        let old = [TestMsgFactory.msg("1", text: "old"), TestMsgFactory.msg("2"), TestMsgFactory.msg("3")]
        let new = [TestMsgFactory.msg("1", text: "new"), TestMsgFactory.msg("3")]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
        #expect(diff.deletedIDs == ["2"])
        #expect(diff.updatedIDs == ["1"])
    }

    @Test("both changes applied")
    @MainActor func bothApplied() {
        let h = ChatTestHelper()
        h.setMessages([TestMsgFactory.msg("1", text: "old"), TestMsgFactory.msg("2"), TestMsgFactory.msg("3")])
        #expect(h.messageCount == 3)

        h.setMessages([TestMsgFactory.msg("1", text: "new"), TestMsgFactory.msg("3")])
        #expect(h.messageCount == 2)
    }
}
