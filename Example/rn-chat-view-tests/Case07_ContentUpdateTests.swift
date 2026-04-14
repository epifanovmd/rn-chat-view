import Testing
@testable import IOSChatView

@Suite("Case 7: Content updates")
struct Case07_ContentUpdateTests {

    @Test("text edit = contentOnly")
    func textEditStrategy() {
        let old = [TestMsgFactory.msg("1", text: "short")]
        let new = [TestMsgFactory.msg("1", text: "much longer text")]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .contentOnly)
    }

    @Test("status change = contentOnly")
    func statusStrategy() {
        let old = [TestMsgFactory.msg("1", status: .sent, ownership: .mine)]
        let new = [TestMsgFactory.msg("1", status: .read, ownership: .mine)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .contentOnly)
    }

    @Test("reaction = contentOnly")
    func reactionStrategy() {
        let old = [TestMsgFactory.msg("1")]
        let new = [TestMsgFactory.msg("1", reactions: [Reaction(emoji: "👍", count: 1, isSelected: true)])]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .contentOnly)
    }

    @Test("height changes when text gets longer")
    @MainActor func heightChangesOnEdit() {
        let h = ChatTestHelper()
        let short = TestMsgFactory.msg("1", text: "Hi")
        h.setMessages([short])

        let heightBefore = h.layoutHeight(forMessageId: "1")
        #expect(heightBefore != nil && heightBefore! > 0)

        let long = TestMsgFactory.msg("1", text: "This is a much longer message that should definitely require more vertical space in the cell layout.")
        h.setMessages([long])

        let heightAfter = h.layoutHeight(forMessageId: "1")
        #expect(heightAfter != nil)
        #expect(heightAfter! > heightBefore!, "Height should increase: \(heightBefore!) → \(heightAfter!)")
    }

    @Test("scroll stays in place on content update")
    @MainActor func scrollStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 20))
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        // Edit a message
        var msgs = h.messages
        if let idx = msgs.indices.first(where: { msgs[$0].id == "1" }) {
            msgs[idx] = TestMsgFactory.msg("1", text: "edited text")
        }
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        // Bottom-stable: offset may shift if changed msg is below viewport, but shouldn't jump wildly
        #expect(abs(offsetAfter - offsetBefore) < 100, "Scroll jumped too much: \(offsetBefore) → \(offsetAfter)")
    }

    @Test("status cascade: all updated in one pass")
    func statusCascade() {
        let old = [TestMsgFactory.msg("1", status: .sent), TestMsgFactory.msg("2", status: .delivered), TestMsgFactory.msg("3", status: .sent)]
        let new = [TestMsgFactory.msg("1", status: .read), TestMsgFactory.msg("2", status: .read), TestMsgFactory.msg("3", status: .read)]
        let diff = MessageDiff.compute(old: old, new: new)
        #expect(diff.updatedIDs.count == 3)
        #expect(MessageDiff.classify(old: old, new: new, diff: diff) == .contentOnly)
    }
}
