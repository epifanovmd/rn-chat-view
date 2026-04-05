import Foundation

/// Manages unread message tracking and count.
///
/// Supports two modes:
/// - **Internal** (default): library tracks unread IDs from appended messages
///   and clears them when messages become visible.
/// - **External**: host app manages the count via `setUnreadCount(_:)`.
final class UnreadManager {

    private(set) var count: Int = 0
    private(set) var unreadIDs: Set<String> = []
    private var isExternalManagement = false

    var onCountChanged: ((Int) -> Void)?

    // MARK: - External Management

    /// Switch to external management — the library stops tracking internally.
    func setExternalCount(_ count: Int) {
        isExternalManagement = true
        self.count = count
        onCountChanged?(count)
    }

    // MARK: - Internal Tracking

    /// Track new unread messages from an append operation.
    func trackAppended(newMessages: [ChatMessage], oldCount: Int) {
        guard !isExternalManagement else { return }
        let delta = newMessages.count - oldCount
        guard delta > 0 else { return }
        let newIDs = newMessages.suffix(delta).filter { !$0.isMine }.map { $0.id }
        guard !newIDs.isEmpty else { return }
        unreadIDs.formUnion(newIDs)
        count = unreadIDs.count
        onCountChanged?(count)
    }

    /// Mark messages as read when they become visible.
    func markAsRead(_ ids: Set<String>) {
        guard !isExternalManagement else { return }
        let readUnread = ids.intersection(unreadIDs)
        guard !readUnread.isEmpty else { return }
        unreadIDs.subtract(readUnread)
        count = unreadIDs.count
        onCountChanged?(count)
    }

    /// Clear all unread state.
    func clearAll() {
        unreadIDs.removeAll()
        count = 0
        isExternalManagement = false
        onCountChanged?(0)
    }
}
