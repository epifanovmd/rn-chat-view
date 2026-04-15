import UIKit

/// Кэш размеров ячеек с учётом ширины.
/// Ключи — пары `(id, width)`: поворот экрана или split-view автоматически
/// инвалидирует кэш вместо возврата устаревших размеров.
struct SizeCache {
    private var store: [String: (width: CGFloat, height: CGFloat)] = [:]

    func height(forKey key: String, width: CGFloat) -> CGFloat? {
        guard let entry = store[key], entry.width == width else { return nil }
        return entry.height
    }

    mutating func set(height: CGFloat, forKey key: String, width: CGFloat) {
        store[key] = (width, height)
    }

    mutating func invalidate(forKey key: String) {
        store.removeValue(forKey: key)
    }

    mutating func invalidateAll() {
        store.removeAll()
    }
}
