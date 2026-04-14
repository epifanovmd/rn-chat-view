import Foundation

// MARK: - Message Diff

/// Pure-function diff analysis for ChatMessage arrays.
/// Extracted from MessageUpdateHandler for testability.
public struct MessageDiff {

    public struct Result {
        public let insertedIDs: Set<String>
        public let deletedIDs: Set<String>
        public let updatedIDs: Set<String>

        public var hasStructuralChanges: Bool {
            !insertedIDs.isEmpty || !deletedIDs.isEmpty
        }

        public var hasContentChanges: Bool {
            !updatedIDs.isEmpty
        }

        public var isEmpty: Bool {
            insertedIDs.isEmpty && deletedIDs.isEmpty && updatedIDs.isEmpty
        }
    }

    /// Mapping from old (pending) ID → new (real) ID via shared `localId`.
    public struct PendingMapping {
        /// old pending ID → new real ID
        public let oldToNew: [String: String]
        /// new real ID → old pending ID
        public let newToOld: [String: String]

        public var isEmpty: Bool { oldToNew.isEmpty }

        public static let empty = PendingMapping(oldToNew: [:], newToOld: [:])
    }

    /// Detect pending→real transitions where old and new messages share a `localId`
    /// but have different `id` values.
    public static func buildPendingMapping(old: [ChatMessage], new: [ChatMessage]) -> PendingMapping {
        let oldIDs = Set(old.map(\.id))
        let newIDs = Set(new.map(\.id))

        // Build localId → old message for messages that will be "deleted" (not in new by id)
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

    /// Compute inserted, deleted, and updated IDs between old and new arrays.
    /// Recognizes pending→real transitions via shared `localId`:
    /// paired delete+insert becomes an update (new ID goes into `updatedIDs`).
    public static func compute(old: [ChatMessage], new: [ChatMessage]) -> Result {
        let mapping = buildPendingMapping(old: old, new: new)

        let oldById = Dictionary(old.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        let oldIDs = Set(old.map(\.id))
        let newIDs = Set(new.map(\.id))

        var insertedIDs = newIDs.subtracting(oldIDs)
        var deletedIDs = oldIDs.subtracting(newIDs)

        // Remove pending→real pairs from inserted/deleted
        for (oldId, newId) in mapping.oldToNew {
            deletedIDs.remove(oldId)
            insertedIDs.remove(newId)
        }

        var updatedIDs = Set<String>()

        // Standard updates (same id, different content)
        for msg in new {
            if let prev = oldById[msg.id], prev != msg {
                updatedIDs.insert(msg.id)
            }
        }

        // Pending→real transitions are always considered updated
        for (_, newId) in mapping.oldToNew {
            updatedIDs.insert(newId)
        }

        return Result(insertedIDs: insertedIDs, deletedIDs: deletedIDs, updatedIDs: updatedIDs)
    }

    /// Check if all old IDs exist as a suffix of new (= pure prepend of older messages).
    public static func isPrependOnly(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        guard new.count > old.count else { return false }
        let offset = new.count - old.count
        for i in 0..<old.count {
            if old[i].id != new[i + offset].id { return false }
        }
        return true
    }

    /// Check if all old IDs exist as a prefix of new (= pure append of newer messages).
    public static func isAppendOnly(old: [ChatMessage], new: [ChatMessage]) -> Bool {
        guard new.count > old.count else { return false }
        for i in 0..<old.count {
            if old[i].id != new[i].id { return false }
        }
        return true
    }

    /// Determine the update strategy for a given diff.
    public enum Strategy {
        case initial
        case clear
        case prependOnly
        case appendOnly
        case contentOnly
        case structural
    }

    public static func classify(old: [ChatMessage], new: [ChatMessage], diff: Result) -> Strategy {
        if old.isEmpty && !new.isEmpty { return .initial }
        if new.isEmpty { return .clear }

        if !diff.hasStructuralChanges && !diff.hasContentChanges { return .contentOnly }

        if diff.deletedIDs.isEmpty && diff.updatedIDs.isEmpty && !diff.insertedIDs.isEmpty {
            if isPrependOnly(old: old, new: new) { return .prependOnly }
            if isAppendOnly(old: old, new: new) { return .appendOnly }
        }

        if !diff.hasStructuralChanges && diff.hasContentChanges {
            return .contentOnly
        }

        return .structural
    }
}
