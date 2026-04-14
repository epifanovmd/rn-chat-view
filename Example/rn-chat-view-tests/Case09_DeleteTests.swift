import Testing
@testable import IOSChatView

@Suite("Case 9: Delete message")
struct Case09_DeleteTests {

    @Test("delete middle = structural")
    func deleteMiddleStrategy() {
        let old = TestMsgFactory.batch(count: 5)
        var new = old; new.remove(at: 2)
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
    }

    @Test("delete first = structural")
    func deleteFirst() {
        let old = TestMsgFactory.batch(count: 3)
        let diff = MessageDiff.compute(old: old, new: Array(old.dropFirst()))
        #expect(diff.deletedIDs.count == 1)
    }

    @Test("delete last = structural")
    func deleteLast() {
        let old = TestMsgFactory.batch(count: 3)
        let diff = MessageDiff.compute(old: old, new: Array(old.dropLast()))
        #expect(diff.deletedIDs.count == 1)
    }

    @Test("message count decreases")
    @MainActor func countDecreases() {
        let h = ChatTestHelper()
        let msgs = TestMsgFactory.batch(count: 10)
        h.setMessages(msgs)
        #expect(h.messageCount == 10)

        var updated = msgs
        updated.remove(at: 5)
        h.setMessages(updated)
        #expect(h.messageCount == 9)
    }

    @Test("scroll preserved after delete in middle")
    @MainActor func scrollPreserved() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        var msgs = h.messages
        msgs.remove(at: msgs.count / 2)
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        #expect(abs(offsetAfter - offsetBefore) < 100, "Scroll jumped: \(offsetBefore) → \(offsetAfter)")
    }
}
