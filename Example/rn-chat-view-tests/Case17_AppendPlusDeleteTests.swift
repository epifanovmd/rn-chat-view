import Testing
@testable import IOSChatView

@Suite("Case 17: Append + delete simultaneously")
struct Case17_AppendPlusDeleteTests {

    @Test("new message + TTL delete = structural")
    func structural() {
        let old = [TestMsgFactory.msg("1"), TestMsgFactory.msg("2"), TestMsgFactory.msg("3", offset: 120)]
        let new = [TestMsgFactory.msg("2"), TestMsgFactory.msg("3", offset: 120), TestMsgFactory.msg("4", offset: 180)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(diff.insertedIDs == ["4"])
        #expect(diff.deletedIDs == ["1"])
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }
}
