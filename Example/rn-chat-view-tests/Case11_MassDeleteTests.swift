import Testing
@testable import IOSChatView

@Suite("Case 11: Mass delete")
struct Case11_MassDeleteTests {

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
