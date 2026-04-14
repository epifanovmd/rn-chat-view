import Testing
@testable import IOSChatView

@Suite("Case 8: Pending → real (send confirm)")
struct Case08_PendingToRealTests {

    // MARK: - Pending mapping unit tests (critical edge cases)

    @Test("pendingMapping: detects localId-based mapping")
    func pendingMapping() {
        let localId = "local_abc"
        let old = [
            TestMsgFactory.msg("1"),
            TestMsgFactory.msg("pending_1", localId: localId, status: .sending, ownership: .mine)
        ]
        let new = [
            TestMsgFactory.msg("1"),
            TestMsgFactory.msg("real_1", localId: localId, status: .sent, ownership: .mine)
        ]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        #expect(mapping.oldToNew == ["pending_1": "real_1"])
        #expect(mapping.newToOld == ["real_1": "pending_1"])
    }

    @Test("no mapping when localId is nil")
    func pendingMapping_noLocalId() {
        let old = [TestMsgFactory.msg("pending_1", status: .sending, ownership: .mine)]
        let new = [TestMsgFactory.msg("real_1", status: .sent, ownership: .mine)]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        #expect(mapping.isEmpty)
    }

    @Test("no mapping when localId differs")
    func pendingMapping_differentLocalId() {
        let old = [TestMsgFactory.msg("pending_1", localId: "a", status: .sending, ownership: .mine)]
        let new = [TestMsgFactory.msg("real_1", localId: "b", status: .sent, ownership: .mine)]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        #expect(mapping.isEmpty)
    }

    // MARK: - Integration (real ChatViewController)

    @Test("message count stays same after pending→real with localId")
    @MainActor func countStable_withLocalId() {
        let h = ChatTestHelper()
        let localId = "local_send_1"

        let pending = TestMsgFactory.msg("pending_1", localId: localId, text: "Sending...", offset: 60, status: .sending, ownership: .mine)
        h.setMessages([TestMsgFactory.msg("1"), pending])
        #expect(h.messageCount == 2)

        let real = TestMsgFactory.msg("real_1", localId: localId, text: "Delivered!", offset: 60, status: .sent, ownership: .mine)
        h.setMessages([TestMsgFactory.msg("1"), real])
        #expect(h.messageCount == 2)
    }

    @Test("message content updated after pending→real")
    @MainActor func contentUpdated() {
        let h = ChatTestHelper()
        let localId = "local_send_1"

        let pending = TestMsgFactory.msg("pending_1", localId: localId, text: "Sending...", offset: 60, status: .sending, ownership: .mine)
        h.setMessages([TestMsgFactory.msg("1"), pending])

        // Verify pending message is accessible
        #expect(h.vc.message(forID: "pending_1")?.status == .sending)

        let real = TestMsgFactory.msg("real_1", localId: localId, text: "Delivered!", offset: 60, status: .sent, ownership: .mine)
        h.setMessages([TestMsgFactory.msg("1"), real])

        // Real message replaces pending — accessible by new ID
        #expect(h.vc.message(forID: "real_1")?.status == .sent)
        #expect(h.vc.message(forID: "real_1")?.content.text == "Delivered!")
        // Old pending ID no longer exists
        #expect(h.vc.message(forID: "pending_1") == nil)
    }

    // MARK: - Legacy (without localId)

    @Test("message count stays same after replace (no localId)")
    @MainActor func countStable_noLocalId() {
        let h = ChatTestHelper()
        let pending = TestMsgFactory.msg("pending_1", text: "Sending...", offset: 60, status: .sending, ownership: .mine)
        h.setMessages([TestMsgFactory.msg("1"), pending])
        #expect(h.messageCount == 2)

        let real = TestMsgFactory.msg("real_1", text: "Delivered!", offset: 60, status: .sent, ownership: .mine)
        h.setMessages([TestMsgFactory.msg("1"), real])
        #expect(h.messageCount == 2)
    }
}
