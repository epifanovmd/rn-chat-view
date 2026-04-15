import Foundation

// Два режима: внутренний (библиотека отслеживает ID) и внешний (хост задаёт count)
final class UnreadManager {

    private(set) var count: Int = 0
    private(set) var unreadIDs: Set<String> = []
    private var isExternalManagement = false

    var onCountChanged: ((Int) -> Void)?

    // MARK: - Внешнее управление

    func setExternalCount(_ count: Int) {
        isExternalManagement = true
        self.count = count
        onCountChanged?(count)
    }

    // MARK: - Внутреннее отслеживание

    func trackAppended(newMessages: [ChatMessage], oldCount: Int) {
        guard !isExternalManagement else { return }
        let delta = newMessages.count - oldCount
        guard delta > 0 else { return }
        let newIDs = newMessages.suffix(delta).filter { $0.ownership != .mine }.map { $0.id }
        guard !newIDs.isEmpty else { return }
        unreadIDs.formUnion(newIDs)
        count = unreadIDs.count
        onCountChanged?(count)
    }

    func markAsRead(_ ids: Set<String>) {
        guard !isExternalManagement else { return }
        let readUnread = ids.intersection(unreadIDs)
        guard !readUnread.isEmpty else { return }
        unreadIDs.subtract(readUnread)
        count = unreadIDs.count
        onCountChanged?(count)
    }

    func clearAll() {
        unreadIDs.removeAll()
        count = 0
        isExternalManagement = false
        onCountChanged?(0)
    }
}
