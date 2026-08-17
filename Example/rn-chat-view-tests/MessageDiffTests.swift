import XCTest
@testable import IOSChatView

// MARK: - Test Helpers

private func msg(_ id: String, localId: String? = nil, text: String = "text", timestamp: Date = Date(), status: MessageStatus = .read, ownership: MessageOwnership = .theirs) -> ChatMessage {
    ChatMessage(
        id: id,
        localId: localId,
        content: MessageBody(text: text, content: nil),
        timestamp: timestamp,
        senderName: "Test",
        ownership: ownership,
        groupDate: "2026-01-01",
        status: status,
        reply: nil,
        forwardedFrom: nil,
        reactions: [],
        isEdited: false,
        actions: []
    )
}

private let t0 = Date(timeIntervalSince1970: 1000)
private func ts(_ offset: TimeInterval) -> Date { t0.addingTimeInterval(offset) }

// MARK: - UnreadManager: только .theirs

final class UnreadManagerOwnershipTests: XCTestCase {

    func testTrackAppended_onlyTheirsMessages() {
        let manager = UnreadManager()
        let messages = [
            msg("1", ownership: .theirs),
            msg("2", ownership: .mine),
            msg("3", ownership: .system),
            msg("4", ownership: .theirs),
            msg("5", ownership: .pinned),
        ]
        manager.trackAppended(newMessages: messages, oldCount: 0)
        XCTAssertEqual(manager.count, 2)
        XCTAssertTrue(manager.unreadIDs.contains("1"))
        XCTAssertTrue(manager.unreadIDs.contains("4"))
        XCTAssertFalse(manager.unreadIDs.contains("2"))
        XCTAssertFalse(manager.unreadIDs.contains("3"))
        XCTAssertFalse(manager.unreadIDs.contains("5"))
    }

    func testTrackAppended_systemAndPinnedIgnored() {
        let manager = UnreadManager()
        let messages = [
            msg("1", ownership: .system),
            msg("2", ownership: .pinned),
        ]
        manager.trackAppended(newMessages: messages, oldCount: 0)
        XCTAssertEqual(manager.count, 0)
        XCTAssertTrue(manager.unreadIDs.isEmpty)
    }

    func testTrackAppended_mineIgnored() {
        let manager = UnreadManager()
        let messages = [
            msg("1", ownership: .mine),
            msg("2", ownership: .mine),
        ]
        manager.trackAppended(newMessages: messages, oldCount: 0)
        XCTAssertEqual(manager.count, 0)
    }
}

// MARK: - Prepend/Append Detection Tests

final class MessageDiffPatternTests: XCTestCase {

    func testIsPrependOnly_true() {
        let old = [msg("3"), msg("4")]
        let new = [msg("1"), msg("2"), msg("3"), msg("4")]
        XCTAssertTrue(MessageDiff.isPrependOnly(old: old, new: new))
    }

    func testIsPrependOnly_false_shuffled() {
        let old = [msg("3"), msg("4")]
        let new = [msg("1"), msg("3"), msg("2"), msg("4")]
        XCTAssertFalse(MessageDiff.isPrependOnly(old: old, new: new))
    }

    func testIsPrependOnly_false_sameCount() {
        let old = [msg("1"), msg("2")]
        let new = [msg("3"), msg("4")]
        XCTAssertFalse(MessageDiff.isPrependOnly(old: old, new: new))
    }

    func testIsAppendOnly_true() {
        let old = [msg("1"), msg("2")]
        let new = [msg("1"), msg("2"), msg("3"), msg("4")]
        XCTAssertTrue(MessageDiff.isAppendOnly(old: old, new: new))
    }

    func testIsAppendOnly_false_shuffled() {
        let old = [msg("1"), msg("2")]
        let new = [msg("1"), msg("3"), msg("2"), msg("4")]
        XCTAssertFalse(MessageDiff.isAppendOnly(old: old, new: new))
    }

    func testIsAppendOnly_false_sameCount() {
        let old = [msg("1"), msg("2")]
        let new = [msg("3"), msg("4")]
        XCTAssertFalse(MessageDiff.isAppendOnly(old: old, new: new))
    }

    func testPrependBatch() {
        let old = [msg("5"), msg("6"), msg("7")]
        let new = [msg("1"), msg("2"), msg("3"), msg("4"), msg("5"), msg("6"), msg("7")]
        XCTAssertTrue(MessageDiff.isPrependOnly(old: old, new: new))
    }

    func testAppendBatch() {
        let old = [msg("1"), msg("2"), msg("3")]
        let new = [msg("1"), msg("2"), msg("3"), msg("4"), msg("5"), msg("6"), msg("7")]
        XCTAssertTrue(MessageDiff.isAppendOnly(old: old, new: new))
    }
}

// MARK: - Pending Mapping Tests

final class MessageDiffPendingMappingTests: XCTestCase {

    func testPendingToReal_withLocalId() {
        let localId = "local_abc"
        let old = [msg("1"), msg("pending_1", localId: localId)]
        let new = [msg("1"), msg("real_1", localId: localId)]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        XCTAssertEqual(mapping.oldToNew, ["pending_1": "real_1"])
        XCTAssertEqual(mapping.newToOld, ["real_1": "pending_1"])
        XCTAssertFalse(mapping.isEmpty)
    }

    func testNoMapping_withoutLocalId() {
        let old = [msg("pending_1")]
        let new = [msg("real_1")]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        XCTAssertTrue(mapping.isEmpty)
    }

    func testNoMapping_differentLocalId() {
        let old = [msg("pending_1", localId: "a")]
        let new = [msg("real_1", localId: "b")]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        XCTAssertTrue(mapping.isEmpty)
    }

    func testNoMapping_sameIdStays() {
        // If the same ID exists in both old and new, no mapping needed
        let old = [msg("1", localId: "local_1")]
        let new = [msg("1", localId: "local_1")]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        XCTAssertTrue(mapping.isEmpty)
    }

    func testMultiplePendingMappings() {
        let old = [msg("p1", localId: "l1"), msg("p2", localId: "l2")]
        let new = [msg("r1", localId: "l1"), msg("r2", localId: "l2")]
        let mapping = MessageDiff.buildPendingMapping(old: old, new: new)
        XCTAssertEqual(mapping.oldToNew.count, 2)
        XCTAssertEqual(mapping.oldToNew["p1"], "r1")
        XCTAssertEqual(mapping.oldToNew["p2"], "r2")
    }
}

// MARK: - Structural Change Detection Tests

final class MessageDiffStructuralChangeTests: XCTestCase {

    func testNoChange_sameMessages() {
        let old = [msg("1"), msg("2")]
        let new = [msg("1"), msg("2")]
        XCTAssertFalse(MessageDiff.hasStructuralChange(old: old, new: new))
    }

    func testNoChange_contentOnlyUpdate() {
        let old = [msg("1"), msg("2", text: "a")]
        let new = [msg("1"), msg("2", text: "b")]
        XCTAssertFalse(MessageDiff.hasStructuralChange(old: old, new: new))
    }

    func testNoChange_pendingToRealSamePosition() {
        // pending→real с общим localId — одна DK-идентичность, не структурное
        let old = [msg("1"), msg("pending_1", localId: "l1")]
        let new = [msg("1"), msg("real_1", localId: "l1")]
        XCTAssertFalse(MessageDiff.hasStructuralChange(old: old, new: new))
    }

    func testStructural_countChanged() {
        let old = [msg("1")]
        let new = [msg("1"), msg("2")]
        XCTAssertTrue(MessageDiff.hasStructuralChange(old: old, new: new))
    }

    func testStructural_delete() {
        let old = [msg("1"), msg("2")]
        let new = [msg("1")]
        XCTAssertTrue(MessageDiff.hasStructuralChange(old: old, new: new))
    }

    func testStructural_reorder() {
        let old = [msg("1"), msg("2")]
        let new = [msg("2"), msg("1")]
        XCTAssertTrue(MessageDiff.hasStructuralChange(old: old, new: new))
    }

    func testStructural_replacedId() {
        // Смена id без общего localId — delete+insert
        let old = [msg("1"), msg("2")]
        let new = [msg("1"), msg("3")]
        XCTAssertTrue(MessageDiff.hasStructuralChange(old: old, new: new))
    }

    func testStructural_dateSeparatorChanges() {
        // Изменение groupDate меняет строки-разделители — структурное
        var old = [msg("1"), msg("2")]
        let changed = ChatMessage(
            id: "2", localId: nil,
            content: MessageBody(text: "text", content: nil),
            timestamp: t0, senderName: "Test", ownership: .theirs,
            groupDate: "2026-01-02", status: .read,
            reply: nil, forwardedFrom: nil, reactions: [],
            isEdited: false, actions: []
        )
        let new = [old[0], changed]
        XCTAssertTrue(MessageDiff.hasStructuralChange(old: old, new: new))
        old = []
    }

    func testEmpty_bothEmpty() {
        XCTAssertFalse(MessageDiff.hasStructuralChange(old: [], new: []))
    }
}

// MARK: - ChatStrings Tests

final class ChatStringsTests: XCTestCase {

    func testThreadRepliesPluralization() {
        XCTAssertEqual(ChatStrings.threadReplies(1), "1 ответ")
        XCTAssertEqual(ChatStrings.threadReplies(2), "2 ответа")
        XCTAssertEqual(ChatStrings.threadReplies(4), "4 ответа")
        XCTAssertEqual(ChatStrings.threadReplies(5), "5 ответов")
        XCTAssertEqual(ChatStrings.threadReplies(11), "11 ответов")
        XCTAssertEqual(ChatStrings.threadReplies(14), "14 ответов")
        XCTAssertEqual(ChatStrings.threadReplies(21), "21 ответ")
        XCTAssertEqual(ChatStrings.threadReplies(22), "22 ответа")
        XCTAssertEqual(ChatStrings.threadReplies(111), "111 ответов")
    }

    func testStaticStrings() {
        XCTAssertFalse(ChatStrings.editedMark.isEmpty)
        XCTAssertFalse(ChatStrings.unknownSender.isEmpty)
        XCTAssertTrue(ChatStrings.forwardedFrom("Иван").contains("Иван"))
    }
}

// MARK: - DateHelper Caching Tests

final class DateHelperCacheTests: XCTestCase {

    func testSectionTitleStableAcrossCalls() {
        let h = DateHelper.shared
        let first = h.sectionTitle(from: "2020-03-15")
        let second = h.sectionTitle(from: "2020-03-15")
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
    }

    func testSectionTitleToday() {
        let h = DateHelper.shared
        let todayKey = h.groupKey(from: Date())
        // Дважды — второй раз из кеша, результат идентичен
        XCTAssertEqual(h.sectionTitle(from: todayKey), h.sectionTitle(from: todayKey))
    }

    func testSectionTitleInvalidKeyReturnsKey() {
        XCTAssertEqual(DateHelper.shared.sectionTitle(from: "not-a-date"), "not-a-date")
    }
}

// MARK: - EmojiHelper Memoization Tests

final class EmojiHelperTests: XCTestCase {

    func testEmojiOnlyCount() {
        XCTAssertEqual(EmojiHelper.emojiOnlyCount("👍"), 1)
        XCTAssertEqual(EmojiHelper.emojiOnlyCount("👍🔥"), 2)
        XCTAssertEqual(EmojiHelper.emojiOnlyCount("👍🔥😂"), 3)
        XCTAssertNil(EmojiHelper.emojiOnlyCount("👍🔥😂😮"))  // > 3
        XCTAssertNil(EmojiHelper.emojiOnlyCount("hi"))
        XCTAssertNil(EmojiHelper.emojiOnlyCount("👍 hi"))
        XCTAssertNil(EmojiHelper.emojiOnlyCount(""))
        XCTAssertNil(EmojiHelper.emojiOnlyCount(nil))
        // Текст длиннее 3 графем — не эмодзи-сообщение (short-circuit по длине)
        XCTAssertNil(EmojiHelper.emojiOnlyCount(String(repeating: "длинный текст ", count: 20)))
    }

    func testEmojiOnlyCountStableOnRepeat() {
        // Повторный вызов (из кеша) даёт тот же результат
        XCTAssertEqual(EmojiHelper.emojiOnlyCount("👍"), EmojiHelper.emojiOnlyCount("👍"))
        XCTAssertEqual(EmojiHelper.emojiOnlyCount("text"), EmojiHelper.emojiOnlyCount("text"))
    }
}

