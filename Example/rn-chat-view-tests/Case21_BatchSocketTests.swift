import Testing
@testable import IOSChatView

@Suite("Case 21: Batch socket events")
struct Case21_BatchSocketTests {

    @Test("new msg + status + reaction = structural")
    func batchMixed() {
        let old = [TestMsgFactory.msg("1", status: .sent), TestMsgFactory.msg("2")]
        let new = [
            TestMsgFactory.msg("1", status: .read, reactions: [Reaction(emoji: "❤️", count: 1, isSelected: false)]),
            TestMsgFactory.msg("2"),
            TestMsgFactory.msg("3", offset: 120),
        ]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(diff.insertedIDs == ["3"])
        #expect(diff.updatedIDs == ["1"])
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }

    @Test("multiple status changes only = contentOnly")
    func statusOnly() {
        let old = [TestMsgFactory.msg("1", status: .sent), TestMsgFactory.msg("2", status: .sent)]
        let new = [TestMsgFactory.msg("1", status: .delivered), TestMsgFactory.msg("2", status: .read)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .contentOnly)
        #expect(diff.updatedIDs.count == 2)
    }

    @Test("batch applied correctly")
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
