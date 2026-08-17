import UIKit

/// Кэш размеров ячеек с учётом ширины.
/// Ключи — пары `(id, width)`: поворот экрана или split-view автоматически
/// инвалидирует кэш вместо возврата устаревших размеров.
struct SizeCache {
    private var store: [String: (width: CGFloat, height: CGFloat)] = [:]
    /// Ширина пузыря кешируется отдельно: считается в момент конфигурации
    /// ячейки (dequeue), а высота — в момент расчёта layout.
    private var bubbleWidths: [String: (width: CGFloat, bubbleWidth: CGFloat)] = [:]

    func height(forKey key: String, width: CGFloat) -> CGFloat? {
        guard let entry = store[key], entry.width == width else { return nil }
        return entry.height
    }

    mutating func set(height: CGFloat, forKey key: String, width: CGFloat) {
        store[key] = (width, height)
    }

    func bubbleWidth(forKey key: String, width: CGFloat) -> CGFloat? {
        guard let entry = bubbleWidths[key], entry.width == width else { return nil }
        return entry.bubbleWidth
    }

    mutating func set(bubbleWidth: CGFloat, forKey key: String, width: CGFloat) {
        bubbleWidths[key] = (width, bubbleWidth)
    }

    mutating func invalidate(forKey key: String) {
        store.removeValue(forKey: key)
        bubbleWidths.removeValue(forKey: key)
    }

    mutating func invalidateAll() {
        store.removeAll()
        bubbleWidths.removeAll()
    }
}
