import Testing
@testable import IOSChatView

@Suite("Case 12: Insert + update simultaneously")
struct Case12_InsertAndUpdateTests {

    @Test("append + text change = structural")
    func appendPlusUpdate() {
        let old = [TestMsgFactory.msg("1", text: "old"), TestMsgFactory.msg("2")]
        let new = [TestMsgFactory.msg("1", text: "new"), TestMsgFactory.msg("2"), TestMsgFactory.msg("3", offset: 120)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
        #expect(diff.insertedIDs == ["3"])
        #expect(diff.updatedIDs == ["1"])
    }

    @Test("prepend + status change = structural")
    func prependPlusUpdate() {
        let old = [TestMsgFactory.msg("2", offset: 60, status: .sent), TestMsgFactory.msg("3", offset: 120)]
        let new = [TestMsgFactory.msg("1"), TestMsgFactory.msg("2", offset: 60, status: .read), TestMsgFactory.msg("3", offset: 120)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }
}
