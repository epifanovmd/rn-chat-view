import Testing
@testable import IOSChatView

@Suite("Кейс 23: Стабильность скролла при разных операциях")
struct Case23_ScrollStabilityTests {

    // MARK: - ContentOnly внизу

    @Test("реакция внизу: первый раз — скролл не прыгает")
    @MainActor func reactionAtBottomFirstTime() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        // Имитируем pendingScrollToBottom (как после FAB tap)
        h.vc.pendingScrollToBottom = true
        h.scrollToBottom()

        var msgs = h.messages
        let lastIdx = msgs.count - 1
        msgs[lastIdx] = TestMsgFactory.msg(
            msgs[lastIdx].id, text: msgs[lastIdx].content.text ?? "",
            offset: Double(lastIdx) * 60,
            reactions: [Reaction(emoji: "👍", count: 1, isSelected: true)]
        )
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Должен остаться внизу после первой реакции")
    }

    @Test("реакция внизу: повторно — скролл не прыгает")
    @MainActor func reactionAtBottomSecondTime() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()

        var msgs = h.messages
        let lastIdx = msgs.count - 1

        // Первая реакция
        msgs[lastIdx] = TestMsgFactory.msg(
            msgs[lastIdx].id, text: msgs[lastIdx].content.text ?? "",
            offset: Double(lastIdx) * 60,
            reactions: [Reaction(emoji: "👍", count: 1, isSelected: true)]
        )
        h.setMessages(msgs)

        // Вторая реакция — убираем
        msgs[lastIdx] = TestMsgFactory.msg(
            msgs[lastIdx].id, text: msgs[lastIdx].content.text ?? "",
            offset: Double(lastIdx) * 60
        )
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Должен остаться внизу после второй реакции")
    }

    @Test("edit+ внизу: скролл остаётся внизу")
    @MainActor func editLongerAtBottom() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()

        var msgs = h.messages
        let lastIdx = msgs.count - 1
        msgs[lastIdx] = TestMsgFactory.msg(
            msgs[lastIdx].id,
            text: "Длинный текст\nСтрока 2\nСтрока 3\nСтрока 4",
            offset: Double(lastIdx) * 60
        )
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Должен остаться внизу после увеличения текста")
    }

    @Test("edit- внизу: скролл остаётся внизу")
    @MainActor func editShorterAtBottom() {
        let h = ChatTestHelper()
        var msgs = TestMsgFactory.batch(count: 30)
        let lastIdx = msgs.count - 1
        msgs[lastIdx] = TestMsgFactory.msg(
            msgs[lastIdx].id,
            text: "Длинный текст\nСтрока 2\nСтрока 3\nСтрока 4",
            offset: Double(lastIdx) * 60
        )
        h.setMessages(msgs)
        h.scrollToBottom()

        msgs[lastIdx] = TestMsgFactory.msg(msgs[lastIdx].id, text: "OK.", offset: Double(lastIdx) * 60)
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Должен остаться внизу после уменьшения текста")
    }

    // MARK: - ContentOnly в середине

    @Test("edit выше viewport: нижние ячейки не смещаются")
    @MainActor func editAboveViewportBottomStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 40))
        h.scrollToBottom()

        let anchorId = h.messages.last!.id
        let screenYBefore = h.screenY(forMessageId: anchorId)!

        var msgs = h.messages
        msgs[0] = TestMsgFactory.msg("1", text: "Расширен\nСтрока 2\nСтрока 3\nСтрока 4\nСтрока 5")
        h.setMessages(msgs)

        let screenYAfter = h.screenY(forMessageId: anchorId)!
        #expect(abs(screenYAfter - screenYBefore) < 2, "Нижняя ячейка сдвинулась: \(screenYBefore) → \(screenYAfter)")
    }

    @Test("edit в середине: якорная ячейка не смещается")
    @MainActor func editInMiddleAnchorStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 40))
        h.scrollToMiddle()

        // Находим нижний видимый элемент
        let visibleIPs = h.vc.collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        guard let lastIP = visibleIPs.last, let anchorId = h.vc.rows[lastIP.item].messageId else {
            #expect(Bool(false), "Нет видимых ячеек")
            return
        }
        let screenYBefore = h.screenY(forMessageId: anchorId)!

        // Изменяем сообщение выше viewport
        var msgs = h.messages
        msgs[0] = TestMsgFactory.msg("1", text: "Расширен\nСтрока 2\nСтрока 3\nСтрока 4")
        h.setMessages(msgs)

        let screenYAfter = h.screenY(forMessageId: anchorId)!
        #expect(abs(screenYAfter - screenYBefore) < 2, "Якорная ячейка сдвинулась: \(screenYBefore) → \(screenYAfter)")
    }

    // MARK: - Structural: удаление

    @Test("удаление в viewport: остаёмся на месте")
    @MainActor func deleteInViewportStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 40))
        h.scrollToMiddle()

        let visibleIPs = h.vc.collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        // Якорь — первый видимый
        guard let firstIP = visibleIPs.first, let anchorId = h.vc.rows[firstIP.item].messageId else {
            #expect(Bool(false), "Нет видимых ячеек")
            return
        }
        // Удаляем последний видимый
        guard let lastIP = visibleIPs.last, let deleteId = h.vc.rows[lastIP.item].messageId else {
            return
        }

        let screenYBefore = h.screenY(forMessageId: anchorId)!

        var msgs = h.messages
        msgs.removeAll { $0.id == deleteId }
        h.setMessages(msgs)

        let screenYAfter = h.screenY(forMessageId: anchorId)
        #expect(screenYAfter != nil, "Якорная ячейка пропала")
        if let after = screenYAfter {
            #expect(abs(after - screenYBefore) < 5, "Якорь сдвинулся: \(screenYBefore) → \(after)")
        }
    }

    @Test("удаление выше viewport: видимые ячейки не смещаются")
    @MainActor func deleteAboveViewportStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 50))
        h.scrollToBottom()

        let anchorId = h.messages.last!.id
        let screenYBefore = h.screenY(forMessageId: anchorId)!

        var msgs = h.messages
        msgs.remove(at: 0)
        h.setMessages(msgs)

        let screenYAfter = h.screenY(forMessageId: anchorId)!
        #expect(abs(screenYAfter - screenYBefore) < 2, "Нижняя ячейка сдвинулась при удалении сверху: \(screenYBefore) → \(screenYAfter)")
    }

    // MARK: - Structural: вставка

    @Test("вставка выше viewport: видимые ячейки не смещаются")
    @MainActor func insertAboveViewportStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 50))
        h.scrollToBottom()

        let anchorId = h.messages.last!.id
        let screenYBefore = h.screenY(forMessageId: anchorId)!

        var msgs = h.messages
        let ts = msgs[0].timestamp.addingTimeInterval(-60)
        msgs.insert(TestMsgFactory.msg("new_top", text: "Вставлен сверху", offset: ts.timeIntervalSince1970 - 100_000), at: 0)
        h.setMessages(msgs)

        let screenYAfter = h.screenY(forMessageId: anchorId)!
        #expect(abs(screenYAfter - screenYBefore) < 5, "Нижняя ячейка сдвинулась при вставке сверху: \(screenYBefore) → \(screenYAfter)")
    }

    @Test("вставка внизу при wasAtBottom: остаёмся внизу")
    @MainActor func insertAtBottomStaysAtBottom() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()
        #expect(h.isNearBottom)

        var msgs = h.messages
        let ts = msgs.last!.timestamp.addingTimeInterval(60)
        msgs.append(TestMsgFactory.msg("new_bottom", text: "Новое снизу", offset: ts.timeIntervalSince1970 - 100_000))
        h.setMessages(msgs)

        #expect(h.isNearBottom, "Должен остаться внизу после вставки снизу")
    }

    // MARK: - Structural: del+ins

    @Test("del+ins на одной позиции: скролл не прыгает")
    @MainActor func deleteInsertSamePositionStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 40))
        h.scrollToMiddle()

        let visibleIPs = h.vc.collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        guard let firstIP = visibleIPs.first, let anchorId = h.vc.rows[firstIP.item].messageId else {
            return
        }
        let screenYBefore = h.screenY(forMessageId: anchorId)!

        var msgs = h.messages
        let mid = msgs.count / 2
        let ts = msgs[mid].timestamp
        msgs.remove(at: mid)
        msgs.insert(TestMsgFactory.msg("replaced", text: "Замена", offset: ts.timeIntervalSince1970 - 100_000), at: mid)
        h.setMessages(msgs)

        let screenYAfter = h.screenY(forMessageId: anchorId)
        if let after = screenYAfter {
            #expect(abs(after - screenYBefore) < 5, "Якорь сдвинулся при del+ins: \(screenYBefore) → \(after)")
        }
    }

    // MARK: - Prepend

    @Test("prepend: видимые ячейки не смещаются")
    @MainActor func prependStable() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 20))
        h.scrollToMiddle()

        let visibleIPs = h.vc.collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        guard let lastIP = visibleIPs.last, let anchorId = h.vc.rows[lastIP.item].messageId else {
            return
        }
        let screenYBefore = h.screenY(forMessageId: anchorId)!

        // Prepend 30 сообщений
        var msgs = h.messages
        let base = msgs[0].timestamp.addingTimeInterval(-7200)
        let prepended = TestMsgFactory.batch(count: 30, startId: 100, baseOffset: base.timeIntervalSince1970 - 100_000)
        msgs = prepended + msgs
        h.setMessages(msgs)

        let screenYAfter = h.screenY(forMessageId: anchorId)!
        #expect(abs(screenYAfter - screenYBefore) < 5, "Якорь сдвинулся при prepend: \(screenYBefore) → \(screenYAfter)")
    }

    // MARK: - pendingScrollToBottom не мешает

    @Test("pendingScrollToBottom + скролл вверх + реакция: не бросает вниз")
    @MainActor func pendingScrollDoesNotHijack() {
        let h = ChatTestHelper()
        h.setMessages(TestMsgFactory.batch(count: 30))
        h.scrollToBottom()

        // Имитируем FAB tap
        h.vc.scrollToBottom(animated: false)

        // Имитируем скролл пользователя вверх (сбрасывает pendingScrollToBottom)
        h.vc.scrollViewWillBeginDragging(h.vc.collectionView)
        h.scrollToMiddle()

        let offsetBefore = h.contentOffset.y
        #expect(!h.isNearBottom, "Должен быть в середине")

        // Реакция
        var msgs = h.messages
        let midIdx = msgs.count / 2
        msgs[midIdx] = TestMsgFactory.msg(
            msgs[midIdx].id, text: msgs[midIdx].content.text ?? "",
            offset: Double(midIdx) * 60,
            reactions: [Reaction(emoji: "❤️", count: 1, isSelected: true)]
        )
        h.setMessages(msgs)

        let offsetAfter = h.contentOffset.y
        #expect(!h.isNearBottom, "Не должен бросить вниз после реакции")
        #expect(abs(offsetAfter - offsetBefore) < 50, "Offset прыгнул: \(offsetBefore) → \(offsetAfter)")
    }
}
