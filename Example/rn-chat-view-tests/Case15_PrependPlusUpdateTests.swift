import Testing
@testable import IOSChatView

@Suite("Case 15: Prepend + update simultaneously")
struct Case15_PrependPlusUpdateTests {

    @Test("prepend + status change → structural (not prependOnly)")
    func fallsToStructural() {
        let old = [TestMsgFactory.msg("3", offset: 120, status: .sent), TestMsgFactory.msg("4", offset: 180)]
        let new = [TestMsgFactory.msg("1"), TestMsgFactory.msg("2", offset: 60), TestMsgFactory.msg("3", offset: 120, status: .read), TestMsgFactory.msg("4", offset: 180)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(diff.insertedIDs == ["1", "2"])
        #expect(diff.updatedIDs == ["3"])
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }
}
