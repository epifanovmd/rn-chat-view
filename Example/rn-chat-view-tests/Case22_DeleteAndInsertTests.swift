import Testing
@testable import IOSChatView

@Suite("Case 22: Delete + insert simultaneously (replace)")
struct Case22_DeleteAndInsertTests {

    @Test("1 deleted + 1 inserted = structural")
    func diffStrategy() {
        let old = TestMsgFactory.batch(count: 5)
        var new = old
        new.remove(at: 2)
        new.insert(TestMsgFactory.msg("new1", text: "Replacement", offset: 120), at: 2)
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .structural)
        #expect(diff.deletedIDs.count == 1)
        #expect(diff.insertedIDs.count == 1)
    }

    @Test("message count stays the same")
    @MainActor func countPreserved() {
        let h = ChatTestHelper()
        let msgs = TestMsgFactory.batch(count: 10)
        h.setMessages(msgs)
        #expect(h.messageCount == 10)

        var updated = msgs
        updated.remove(at: 5)
        updated.insert(TestMsgFactory.msg("new1", text: "Replacement", offset: 300), at: 5)
        h.setMessages(updated)
        #expect(h.messageCount == 10)
    }

    @Test("scroll preserved when replacing same-height message in middle")
    @MainActor func scrollPreservedSameHeight() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        var msgs = h.messages
        let mid = msgs.count / 2
        let ts = msgs[mid].timestamp
        msgs.remove(at: mid)
        msgs.insert(TestMsgFactory.msg("replaced", text: "Same height text", offset: ts.timeIntervalSince1970 - 100_000), at: mid)
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        #expect(abs(offsetAfter - offsetBefore) < 5, "Scroll jumped: \(offsetBefore) → \(offsetAfter)")
    }

    @Test("scroll preserved when replacing with shorter message")
    @MainActor func scrollPreservedShorterMessage() {
        let h = ChatTestHelper()
        // Use messages with varying text to ensure different heights
        var msgs = TestMsgFactory.batch(count: 30)
        // Make one message tall
        let mid = msgs.count / 2
        msgs[mid] = TestMsgFactory.msg("\(mid + 1)", text: "This is a very long message that should be taller than the replacement.\nLine 2\nLine 3\nLine 4", offset: Double(mid) * 60)
        h.setMessages(msgs)
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        var updated = msgs
        let ts = updated[mid].timestamp
        updated.remove(at: mid)
        updated.insert(TestMsgFactory.msg("short", text: "OK", offset: ts.timeIntervalSince1970 - 100_000), at: mid)
        h.setMessages(updated)

        let offsetAfter = h.contentOffset.y
        // Offset may shift due to height change, but should not jump wildly
        #expect(abs(offsetAfter - offsetBefore) < 100, "Scroll jumped: \(offsetBefore) → \(offsetAfter)")
    }

    @Test("scroll preserved when replacing with taller message")
    @MainActor func scrollPreservedTallerMessage() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        var msgs = h.messages
        let mid = msgs.count / 2
        let ts = msgs[mid].timestamp
        msgs.remove(at: mid)
        msgs.insert(TestMsgFactory.msg("tall", text: "Tall replacement\nLine 2\nLine 3\nLine 4\nLine 5", offset: ts.timeIntervalSince1970 - 100_000), at: mid)
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        #expect(abs(offsetAfter - offsetBefore) < 100, "Scroll jumped: \(offsetBefore) → \(offsetAfter)")
    }

    @Test("delete last + insert at same position stays near bottom")
    @MainActor func deleteLastInsertSamePosition() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()

        var msgs = h.messages
        let lastTs = msgs.last!.timestamp
        msgs.removeLast()
        msgs.append(TestMsgFactory.msg("newLast", text: "Replaced last", offset: lastTs.timeIntervalSince1970 - 100_000 + 1))
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Should remain near bottom after replacing last message")
    }

    @Test("delete + insert above viewport preserves scroll")
    @MainActor func deleteInsertAboveViewport() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 50))
        h.scrollToBottom()
        let offsetBefore = h.contentOffset.y

        // Replace a message near the top (above viewport)
        var msgs = h.messages
        let ts = msgs[2].timestamp
        msgs.remove(at: 2)
        msgs.insert(TestMsgFactory.msg("aboveVP", text: "Above viewport", offset: ts.timeIntervalSince1970 - 100_000), at: 2)
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        #expect(abs(offsetAfter - offsetBefore) < 50, "Scroll jumped for above-viewport replace: \(offsetBefore) → \(offsetAfter)")
    }
}
