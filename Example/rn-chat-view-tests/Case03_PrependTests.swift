import Testing
@testable import IOSChatView

@Suite("Case 3: Prepend older messages")
struct Case03_PrependTests {

    @Test("prepend = prependOnly strategy")
    func diffStrategy() {
        let old = TestMsgFactory.batch(count: 3, startId: 4, baseOffset: 180)
        let new = TestMsgFactory.batch(count: 3, startId: 1, baseOffset: 0) + old
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .prependOnly)
    }

    @Test("scroll offset compensated — user stays in place")
    @MainActor func offsetCompensation() {
        let h = ChatTestHelper()
        let initial = TestMsgFactory.batch(count: 20, startId: 21, baseOffset: 1200)
        h.setMessages(initial)

        // Scroll to middle
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        // Prepend 20 older messages
        let older = TestMsgFactory.batch(count: 20, startId: 1, baseOffset: 0)
        h.setMessages(older + initial)

        let offsetAfter = h.contentOffset.y

        // Offset should have increased by ~the height of prepended content
        #expect(h.messageCount == 40)
        #expect(offsetAfter > offsetBefore, "Offset should increase to compensate prepended content")
    }

    @Test("message count increases")
    @MainActor func countIncreases() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 5, startId: 6, baseOffset: 300))
        #expect(h.messageCount == 5)

        let older = TestMsgFactory.batch(count: 10, startId: 1, baseOffset: 0)
        h.setMessages(older + h.messages)
        #expect(h.messageCount == 15)
    }
}
