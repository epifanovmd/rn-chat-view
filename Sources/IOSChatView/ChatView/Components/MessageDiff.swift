import Foundation

// MARK: - Анализ изменений сообщений

public struct MessageDiff {

    public struct PendingMapping {
        public let oldToNew: [String: String]
        public let newToOld: [String: String]

        public var isEmpty: Bool { oldToNew.isEmpty }

        public static let empty = PendingMapping(oldToNew: [:], newToOld: [:])
    }

    // Pending→real: старое и новое сообщение с общим localId, но разными id
    public static func buildPendingMapping(old: [ChatMessage], new: [ChatMessage]) -> PendingMapping {
        let oldIDs = Set(old.map(\.id))
        let newIDs = Set(new.map(\.id))

        var oldByLocalId: [String: ChatMessage] = [:]
        for msg in old where !newIDs.contains(msg.id) {
            if let lid = msg.localId {
                oldByLocalId[lid] = msg
            }
        }

        var oldToNew: [String: String] = [:]
        var newToOld: [String: String] = [:]

        for msg in new where !oldIDs.contains(msg.id) {
            if let lid = msg.localId, let oldMsg = oldByLocalId[lid] {
                oldToNew[oldMsg.id] = msg.id
                newToOld[msg.id] = oldMsg.id
            }
        }

        return PendingMapping(oldToNew: oldToNew, newToOld: newToOld)
    }

    public static func isPrependOnly(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        guard new.count > old.count else { return false }
        let offset = new.count - old.count
        for i in 0..<old.count {
            if old[i].id != new[i + offset].id { return false }
        }
        return true
    }

    public static func isAppendOnly(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        guard new.count > old.count else { return false }
        for i in 0..<old.count {
            if old[i].id != new[i].id { return false }
        }
        return true
    }
}
