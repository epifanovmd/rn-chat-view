import Testing
@testable import IOSChatView

@Suite("Case 18: Pending confirm + new message simultaneously")
struct Case18_PendingPlusNewTests {

    @Test("pending replaced + new socket = structural")
    func structural() {
        let old = [TestMsgFactory.msg("1"), TestMsgFactory.msg("pending_1", offset: 60)]
        let new = [TestMsgFactory.msg("1"), TestMsgFactory.msg("real_1", offset: 60), TestMsgFactory.msg("socket_1", offset: 120)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(diff.deletedIDs == ["pending_1"])
        #expect(diff.insertedIDs == ["real_1", "socket_1"])
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }
}
