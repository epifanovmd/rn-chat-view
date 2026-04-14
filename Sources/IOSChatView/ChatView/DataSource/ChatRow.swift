import DifferenceKit
import Foundation

// MARK: - Chat Row

/// A single item in the chat collection view.
///
/// The collection view uses a flat list (`[ChatRow]`) in a single section.
/// DifferenceKit diffs this array for animated batch updates.
public enum ChatRow: Hashable {
    case message(ChatMessage)
    case dateSeparator(groupDate: String)
    case loading(position: String)

    // MARK: - Convenience

    public var messageId: String? {
        if case .message(let msg) = self { return msg.id }
        return nil
    }

    public var message: ChatMessage? {
        if case .message(let msg) = self { return msg }
        return nil
    }
}

// MARK: - Differentiable

extension ChatRow: Differentiable {

    /// Stable identity for diffing — same ID means same logical item.
    /// Uses `localId` when available so pending→real messages share the same identity.
    public var differenceIdentifier: String {
        switch self {
        case .message(let msg):     return "m_\(msg.localId ?? msg.id)"
        case .dateSeparator(let d): return "d_\(d)"
        case .loading(let p):       return "l_\(p)"
        }
    }

    /// Content comparison — `false` triggers a cell reload for this item.
    public func isContentEqual(to source: ChatRow) -> Bool {
        switch (self, source) {
        case (.message(let a), .message(let b)):             return a == b
        case (.dateSeparator(let a), .dateSeparator(let b)): return a == b
        case (.loading(let a), .loading(let b)):             return a == b
        default: return false
        }
    }
}
