import UIKit
@testable import IOSChatView

/// Helper for integration tests with real ChatViewController.
/// Creates a VC in a window, pumps layout, and provides assertions.
@MainActor
final class ChatTestHelper {

    let vc: ChatViewController
    private let window: UIWindow

    /// Messages sorted by timestamp ASC (as native receives from bridge).
    var messages: [ChatMessage] { vc.messages }

    init() {
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        vc = ChatViewController()
        vc.theme = .dark
        vc.features.senderNameMode = .never

        window.rootViewController = vc
        window.makeKeyAndVisible()
        vc.view.frame = window.bounds
        vc.view.layoutIfNeeded()
    }

    deinit {
        window.isHidden = true
    }

    // MARK: - Actions

    func setMessages(_ msgs: [ChatMessage]) {
        vc.updateMessages(msgs)
        pump()
    }

    func pump() {
        vc.view.layoutIfNeeded()
        vc.collectionView.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }

    // MARK: - Assertions

    var contentOffset: CGPoint { vc.collectionView.contentOffset }
    var contentSize: CGSize { vc.collectionView.contentSize }
    var visibleCellCount: Int { vc.collectionView.visibleCells.count }
    var rowCount: Int { vc.rows.count }
    var messageCount: Int { vc.messages.count }
    var isNearBottom: Bool { vc.isNearBottom() }

    var bottomInset: CGFloat { vc.collectionView.contentInset.bottom }
    var topInset: CGFloat { vc.collectionView.contentInset.top }

    /// Get the frame of a cell for a message ID (nil if not visible).
    func cellFrame(forMessageId id: String) -> CGRect? {
        guard let idx = vc.rowIndexCache[id] else { return nil }
        let ip = IndexPath(item: idx, section: 0)
        return vc.collectionView.layoutAttributesForItem(at: ip)?.frame
    }

    /// Get the height from layout data for a message ID.
    func layoutHeight(forMessageId id: String) -> CGFloat? {
        guard let idx = vc.rowIndexCache[id] else { return nil }
        guard idx < vc.chatLayout.rowLayoutData.count else { return nil }
        return vc.chatLayout.rowLayoutData[idx].height
    }

    /// Max scroll offset (bottom).
    var maxOffsetY: CGFloat {
        let cv = vc.collectionView!
        return cv.contentSize.height - cv.bounds.height + cv.contentInset.bottom
    }

    /// Scroll to a specific offset.
    func scrollTo(y: CGFloat) {
        vc.collectionView.contentOffset = CGPoint(x: 0, y: y)
        pump()
    }

    /// Scroll to bottom.
    func scrollToBottom() {
        scrollTo(y: maxOffsetY)
    }

    /// Scroll to top.
    func scrollToTop() {
        scrollTo(y: -topInset)
    }

    /// Scroll to middle.
    func scrollToMiddle() {
        scrollTo(y: maxOffsetY / 2)
    }

    /// Экранная Y-позиция ячейки (frame.minY - contentOffset.y).
    func screenY(forMessageId id: String) -> CGFloat? {
        guard let frame = cellFrame(forMessageId: id) else { return nil }
        return frame.minY - contentOffset.y
    }
}

// MARK: - Message Factory

enum TestMsgFactory {

    private static let t0 = Date(timeIntervalSince1970: 100_000)

    static func msg(
        _ id: String,
        localId: String? = nil,
        text: String = "Message text",
        offset: TimeInterval = 0,
        status: MessageStatus = .read,
        ownership: MessageOwnership = .theirs,
        reactions: [Reaction] = [],
        isEdited: Bool = false
    ) -> ChatMessage {
        let ts = t0.addingTimeInterval(offset)
        return ChatMessage(
            id: id,
            localId: localId,
            content: MessageBody(text: text, content: nil),
            timestamp: ts,
            senderName: ownership == .mine ? nil : "Alice",
            ownership: ownership,
            groupDate: DateHelper.shared.groupKey(from: ts),
            status: status,
            reply: nil,
            forwardedFrom: nil,
            reactions: reactions,
            isEdited: isEdited,
            actions: []
        )
    }

    /// Generate N messages with sequential timestamps.
    static func batch(count: Int, startId: Int = 1, baseOffset: TimeInterval = 0, ownership: MessageOwnership = .theirs) -> [ChatMessage] {
        (0..<count).map { i in
            msg("\(startId + i)", text: "Msg #\(startId + i)", offset: baseOffset + Double(i) * 60, ownership: i % 3 == 0 ? .mine : ownership)
        }
    }
}
