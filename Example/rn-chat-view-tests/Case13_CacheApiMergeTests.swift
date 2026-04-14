import Testing
@testable import IOSChatView

@Suite("Case 13: Cache → API merge")
struct Case13_CacheApiMergeTests {

    @Test("same IDs, some updated = contentOnly")
    func sameIdsUpdated() {
        let old = [TestMsgFactory.msg("1", text: "cached"), TestMsgFactory.msg("2")]
        let new = [TestMsgFactory.msg("1", text: "from API"), TestMsgFactory.msg("2")]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .contentOnly)
    }

    @Test("same IDs + new = appendOnly")
    func sameIdsPlusNew() {
        let old = [TestMsgFactory.msg("1"), TestMsgFactory.msg("2")]
        let new = old + [TestMsgFactory.msg("3", offset: 120)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .appendOnly)
    }

    @Test("stale cache (different IDs) = structural")
    func staleCache() {
        let old = [TestMsgFactory.msg("old1"), TestMsgFactory.msg("old2")]
        let new = [TestMsgFactory.msg("new1"), TestMsgFactory.msg("new2")]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }
}
