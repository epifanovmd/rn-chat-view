import Testing
@testable import IOSChatView

@Suite("Case 16: Append + update simultaneously")
struct Case16_AppendPlusUpdateTests {

    @Test("append + reaction → structural (not appendOnly)")
    func fallsToStructural() {
        let old = [TestMsgFactory.msg("1"), TestMsgFactory.msg("2")]
        let new = [TestMsgFactory.msg("1", reactions: [Reaction(emoji: "👍", count: 1, isSelected: true)]), TestMsgFactory.msg("2"), TestMsgFactory.msg("3", offset: 120)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(diff.insertedIDs == ["3"])
        #expect(diff.updatedIDs == ["1"])
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }
}
