import XCTest
@testable import IOSChatView

// MARK: - Test Helpers

private func msg(_ id: String, text: String = "text", timestamp: Date = Date(), status: MessageStatus = .read, ownership: MessageOwnership = .theirs) -> ChatMessage {
    ChatMessage(
        id: id,
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

// MARK: - Diff Tests

final class MessageDiffComputeTests: XCTestCase {

    // ── Empty ──────────────────────────────────────────────────────

    func testEmptyToEmpty() {
        let r = MessageDiff.compute(old: [], new: [])
        XCTAssertTrue(r.isEmpty)
    }

    func testEmptyToSome() {
        let r = MessageDiff.compute(old: [], new: [msg("1"), msg("2")])
        XCTAssertEqual(r.insertedIDs, ["1", "2"])
        XCTAssertTrue(r.deletedIDs.isEmpty)
        XCTAssertTrue(r.updatedIDs.isEmpty)
    }

    func testSomeToEmpty() {
        let r = MessageDiff.compute(old: [msg("1"), msg("2")], new: [])
        XCTAssertTrue(r.insertedIDs.isEmpty)
        XCTAssertEqual(r.deletedIDs, ["1", "2"])
    }

    // ── Content updates ────────────────────────────────────────────

    func testNoChange() {
        let m = [msg("1"), msg("2")]
        let r = MessageDiff.compute(old: m, new: m)
        XCTAssertTrue(r.isEmpty)
    }

    func testTextChanged() {
        let old = [msg("1", text: "old")]
        let new = [msg("1", text: "new")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertTrue(r.insertedIDs.isEmpty)
        XCTAssertTrue(r.deletedIDs.isEmpty)
        XCTAssertEqual(r.updatedIDs, ["1"])
    }

    func testStatusChanged() {
        let old = [msg("1", status: .sent)]
        let new = [msg("1", status: .read)]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.updatedIDs, ["1"])
        XCTAssertFalse(r.hasStructuralChanges)
        XCTAssertTrue(r.hasContentChanges)
    }

    func testMultipleUpdates() {
        let old = [msg("1", text: "a"), msg("2", text: "b"), msg("3", text: "c")]
        let new = [msg("1", text: "a"), msg("2", text: "B"), msg("3", text: "C")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.updatedIDs, ["2", "3"])
    }

    // ── Inserts ────────────────────────────────────────────────────

    func testAppendOne() {
        let old = [msg("1"), msg("2")]
        let new = [msg("1"), msg("2"), msg("3")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.insertedIDs, ["3"])
        XCTAssertTrue(r.deletedIDs.isEmpty)
    }

    func testPrependOne() {
        let old = [msg("2"), msg("3")]
        let new = [msg("1"), msg("2"), msg("3")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.insertedIDs, ["1"])
    }

    func testInsertBatch() {
        let old = [msg("3"), msg("4")]
        let new = [msg("1"), msg("2"), msg("3"), msg("4")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.insertedIDs, ["1", "2"])
    }

    // ── Deletes ────────────────────────────────────────────────────

    func testDeleteOne() {
        let old = [msg("1"), msg("2"), msg("3")]
        let new = [msg("1"), msg("3")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.deletedIDs, ["2"])
    }

    func testDeleteBatch() {
        let old = [msg("1"), msg("2"), msg("3"), msg("4"), msg("5")]
        let new = [msg("1"), msg("5")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.deletedIDs, ["2", "3", "4"])
    }

    // ── Mixed ──────────────────────────────────────────────────────

    func testInsertAndUpdate() {
        let old = [msg("1", text: "old")]
        let new = [msg("1", text: "new"), msg("2")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.insertedIDs, ["2"])
        XCTAssertEqual(r.updatedIDs, ["1"])
        XCTAssertTrue(r.hasStructuralChanges)
        XCTAssertTrue(r.hasContentChanges)
    }

    func testDeleteAndUpdate() {
        let old = [msg("1", text: "old"), msg("2")]
        let new = [msg("1", text: "new")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.deletedIDs, ["2"])
        XCTAssertEqual(r.updatedIDs, ["1"])
    }

    func testInsertDeleteUpdate() {
        let old = [msg("1", text: "old"), msg("2")]
        let new = [msg("1", text: "new"), msg("3")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.insertedIDs, ["3"])
        XCTAssertEqual(r.deletedIDs, ["2"])
        XCTAssertEqual(r.updatedIDs, ["1"])
    }

    func testPendingToReal() {
        let old = [msg("1"), msg("pending_1")]
        let new = [msg("1"), msg("real_1")]
        let r = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(r.insertedIDs, ["real_1"])
        XCTAssertEqual(r.deletedIDs, ["pending_1"])
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
}

// MARK: - Classify Tests

final class MessageDiffClassifyTests: XCTestCase {

    func testInitial() {
        let diff = MessageDiff.compute(old: [], new: [msg("1")])
        XCTAssertEqual(MessageDiff.classify(old: [], new: [msg("1")], diff: diff), .initial)
    }

    func testClear() {
        let diff = MessageDiff.compute(old: [msg("1")], new: [])
        XCTAssertEqual(MessageDiff.classify(old: [msg("1")], new: [], diff: diff), .clear)
    }

    func testContentOnly_statusChange() {
        let old = [msg("1", status: .sent)]
        let new = [msg("1", status: .read)]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .contentOnly)
    }

    func testContentOnly_textEdit() {
        let old = [msg("1", text: "old")]
        let new = [msg("1", text: "new")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .contentOnly)
    }

    func testContentOnly_noChange() {
        let m = [msg("1")]
        let diff = MessageDiff.compute(old: m, new: m)
        XCTAssertEqual(MessageDiff.classify(old: m, new: m, diff: diff), .contentOnly)
    }

    func testPrependOnly() {
        let old = [msg("2"), msg("3")]
        let new = [msg("1"), msg("2"), msg("3")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .prependOnly)
    }

    func testAppendOnly() {
        let old = [msg("1"), msg("2")]
        let new = [msg("1"), msg("2"), msg("3")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .appendOnly)
    }

    func testStructural_insertMiddle() {
        let old = [msg("1"), msg("3")]
        let new = [msg("1"), msg("2"), msg("3")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
    }

    func testStructural_delete() {
        let old = [msg("1"), msg("2"), msg("3")]
        let new = [msg("1"), msg("3")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
    }

    func testStructural_insertAndUpdate() {
        let old = [msg("1", text: "old")]
        let new = [msg("1", text: "new"), msg("2")]
        let diff = MessageDiff.compute(old: old, new: new)
        // Has inserts + updates but inserts not pure append → structural
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
    }

    func testStructural_pendingToReal() {
        let old = [msg("1"), msg("pending_1")]
        let new = [msg("1"), msg("real_1")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
    }

    func testPrependBatch() {
        let old = [msg("5"), msg("6"), msg("7")]
        let new = [msg("1"), msg("2"), msg("3"), msg("4"), msg("5"), msg("6"), msg("7")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .prependOnly)
    }

    func testAppendBatch() {
        let old = [msg("1"), msg("2"), msg("3")]
        let new = [msg("1"), msg("2"), msg("3"), msg("4"), msg("5"), msg("6"), msg("7")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .appendOnly)
    }

    func testStatusCascade() {
        let old = [msg("1", status: .sent), msg("2", status: .sent), msg("3", status: .delivered)]
        let new = [msg("1", status: .read), msg("2", status: .read), msg("3", status: .read)]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .contentOnly)
        XCTAssertEqual(diff.updatedIDs.count, 3)
    }

    func testReplaceAll() {
        let old = [msg("1"), msg("2")]
        let new = [msg("3"), msg("4"), msg("5")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
        XCTAssertEqual(diff.insertedIDs, ["3", "4", "5"])
        XCTAssertEqual(diff.deletedIDs, ["1", "2"])
    }

    func testSameTimestamp_twoNewMessages() {
        let t = Date()
        let old = [msg("1", timestamp: t)]
        let new = [msg("1", timestamp: t), msg("2", timestamp: t), msg("3", timestamp: t)]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(diff.insertedIDs, ["2", "3"])
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .appendOnly)
    }

    func testDeleteFirst() {
        let old = [msg("1"), msg("2"), msg("3")]
        let new = [msg("2"), msg("3")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(diff.deletedIDs, ["1"])
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
    }

    func testDeleteLast() {
        let old = [msg("1"), msg("2"), msg("3")]
        let new = [msg("1"), msg("2")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(diff.deletedIDs, ["3"])
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
    }

    func testInsertDeleteUpdateMixed() {
        let old = [msg("1", text: "a"), msg("2"), msg("3")]
        let new = [msg("1", text: "b"), msg("3"), msg("4")]
        let diff = MessageDiff.compute(old: old, new: new)
        XCTAssertEqual(diff.insertedIDs, ["4"])
        XCTAssertEqual(diff.deletedIDs, ["2"])
        XCTAssertEqual(diff.updatedIDs, ["1"])
        XCTAssertEqual(MessageDiff.classify(old: old, new: new, diff: diff), .structural)
    }
}
