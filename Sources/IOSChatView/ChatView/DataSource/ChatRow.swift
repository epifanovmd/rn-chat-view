import DifferenceKit
import Foundation

// MARK: - Строка чата

public enum ChatRow: Hashable {
    case message(ChatMessage)
    case dateSeparator(groupDate: String)
    case loading(position: String)

    // MARK: - Удобные свойства

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

    /// Стабильная идентичность для diff: `localId` если есть, чтобы pending→real
    /// сообщения делили одну идентичность.
    public var differenceIdentifier: String {
        switch self {
        case .message(let msg):     return "m_\(msg.localId ?? msg.id)"
        case .dateSeparator(let d): return "d_\(d)"
        case .loading(let p):       return "l_\(p)"
        }
    }

    /// Сравнение контента — `false` вызывает перезагрузку ячейки.
    public func isContentEqual(to source: ChatRow) -> Bool {
        switch (self, source) {
        case (.message(let a), .message(let b)):             return a == b
        case (.dateSeparator(let a), .dateSeparator(let b)): return a == b
        case (.loading(let a), .loading(let b)):             return a == b
        default: return false
        }
    }
}
