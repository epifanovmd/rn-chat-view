import Testing
@testable import IOSChatView

@Suite("Кейс 7: Обновление содержимого")
struct Case07_ContentUpdateTests {

    @Test("высота меняется при удлинении текста")
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

    @Test("обновление внизу: скролл остаётся внизу при увеличении высоты")
    @MainActor func contentGrowAtBottomStaysAtBottom() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()
        #expect(h.isNearBottom)

        // Увеличиваем высоту последнего сообщения
        var msgs = h.messages
        let lastIdx = msgs.count - 1
        let lastId = msgs[lastIdx].id
        msgs[lastIdx] = TestMsgFactory.msg(lastId, text: "Long text\nLine 2\nLine 3\nLine 4\nLine 5", offset: Double(lastIdx) * 60)
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Should stay at bottom after content grows")
    }

    @Test("обновление внизу: скролл остаётся внизу при уменьшении высоты")
    @MainActor func contentShrinkAtBottomStaysAtBottom() {
        let h = ChatTestHelper()
        // Начинаем с длинного последнего сообщения
        var msgs = TestMsgFactory.batch(count: 30)
        let lastIdx = msgs.count - 1
        let lastId = msgs[lastIdx].id
        msgs[lastIdx] = TestMsgFactory.msg(lastId, text: "Long text\nLine 2\nLine 3\nLine 4\nLine 5", offset: Double(lastIdx) * 60)
        h.setMessages(msgs)
        h.scrollToBottom()
        #expect(h.isNearBottom)

        // Сжимаем последнее сообщение
        msgs[lastIdx] = TestMsgFactory.msg(lastId, text: "OK.", offset: Double(lastIdx) * 60)
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Should stay at bottom after content shrinks")
    }

    @Test("обновление выше вьюпорта: нижние ячейки не сдвигаются")
    @MainActor func editAboveViewportNoShift() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 40))
        h.scrollToBottom()

        // Находим нижний видимый элемент и запоминаем его экранную позицию
        let msgs = h.messages
        let bottomMsgId = msgs.last!.id
        let frameBefore = h.cellFrame(forMessageId: bottomMsgId)
        #expect(frameBefore != nil, "Bottom cell should have a frame")
        let offsetBefore = h.contentOffset.y

        // Меняем сообщение вверху (далеко выше viewport) — делаем его значительно длиннее
        var updated = msgs
        updated[0] = TestMsgFactory.msg("1", text: "Expanded\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8")
        h.setMessages(updated)

        // Нижний элемент должен остаться на том же месте экрана (bottom-stable)
        let frameAfter = h.cellFrame(forMessageId: bottomMsgId)
        #expect(frameAfter != nil, "Bottom cell should still have a frame")

        // Экранная позиция = frame.minY - contentOffset.y
        let screenYBefore = frameBefore!.minY - offsetBefore
        let screenYAfter = frameAfter!.minY - h.contentOffset.y
        #expect(abs(screenYAfter - screenYBefore) < 2, "Bottom cell screen position shifted: \(screenYBefore) → \(screenYAfter)")
    }

    @Test("обновление выше вьюпорта: смещение сдвигается вверх, а не вниз")
    @MainActor func editAboveViewportOffsetShiftsUp() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 40))
        // Скроллим в середину, не на дно
        h.scrollToMiddle()
        let offsetBefore = h.contentOffset.y

        // Находим видимый элемент ближе к низу viewport
        let visibleIPs = h.vc.collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        guard let lastVisibleIP = visibleIPs.last,
              lastVisibleIP.item < h.vc.rows.count,
              let visibleMsgId = h.vc.rows[lastVisibleIP.item].messageId else {
            #expect(Bool(false), "No visible message found")
            return
        }
        let frameBefore = h.cellFrame(forMessageId: visibleMsgId)
        #expect(frameBefore != nil)

        // Увеличиваем сообщение выше viewport
        var updated = h.messages
        updated[0] = TestMsgFactory.msg("1", text: "Expanded\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6")
        h.setMessages(updated)

        let frameAfter = h.cellFrame(forMessageId: visibleMsgId)
        #expect(frameAfter != nil)

        // Экранная позиция нижнего видимого элемента не должна сдвинуться
        let screenYBefore = frameBefore!.minY - offsetBefore
        let screenYAfter = frameAfter!.minY - h.contentOffset.y
        #expect(abs(screenYAfter - screenYBefore) < 2, "Visible cell screen position shifted: \(screenYBefore) → \(screenYAfter)")

        // offset должен увеличиться (сдвиг вверх = контент расширился выше)
        #expect(h.contentOffset.y >= offsetBefore, "Offset should increase (shift up): \(offsetBefore) → \(h.contentOffset.y)")
    }

    @Test("обновление внизу: нет прыжка скролла при добавлении реакции")
    @MainActor func reactionAtBottomNoJump() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()
        let offsetBefore = h.contentOffset.y

        // Добавляем реакцию на последнее сообщение (меняет высоту)
        var msgs = h.messages
        let lastIdx = msgs.count - 1
        let lastId = msgs[lastIdx].id
        msgs[lastIdx] = TestMsgFactory.msg(lastId, text: msgs[lastIdx].content.text ?? "", offset: Double(lastIdx) * 60, reactions: [Reaction(emoji: "👍", count: 1, isSelected: true)])
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        // Должен остаться внизу — maxOffset мог измениться, но мы всё ещё near bottom
        #expect(h.isNearBottom, "Should stay at bottom after reaction, offset: \(offsetBefore) → \(offsetAfter)")
    }
}
