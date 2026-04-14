import Testing
@testable import IOSChatView

@Suite("Case 19: Same timestamp messages")
struct Case19_SameTimestampTests {

    @Test("two new messages same timestamp = appendOnly")
    func appendOnly() {
        let t = Date()
        let old = [TestMsgFactory.msg("1")]
        let new = [TestMsgFactory.msg("1"), TestMsgFactory.msg("2"), TestMsgFactory.msg("3")]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .appendOnly)
    }

    @Test("same messages same timestamp = no false updates")
    func noFalseUpdates() {
        let t = Date(timeIntervalSince1970: 50000)
        let m = [TestMsgFactory.msg("1", offset: 0), TestMsgFactory.msg("2", offset: 0)]
        let diff = MessageDiff.compute(old: m, new: m)
        #expect(diff.isEmpty)
    }
}
