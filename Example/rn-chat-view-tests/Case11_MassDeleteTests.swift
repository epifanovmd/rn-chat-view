import Testing
@testable import IOSChatView

@Suite("Case 11: Mass delete")
struct Case11_MassDeleteTests {

    @Test("many deleted = structural")
    func diffStrategy() {
        let old = TestMsgFactory.batch(count: 10)
        let new = [old[0], old[9]]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
        #expect(diff.deletedIDs.count == 8)
    }

    @Test("content size decreases")
    @MainActor func contentSizeDecreases() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 20))
        let sizeBefore = h.contentSize.height

        h.setMessages(TestMsgFactory.batch(count: 5))
        let sizeAfter = h.contentSize.height
        #expect(sizeAfter < sizeBefore, "Content should shrink: \(sizeBefore) → \(sizeAfter)")
    }
}
