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

