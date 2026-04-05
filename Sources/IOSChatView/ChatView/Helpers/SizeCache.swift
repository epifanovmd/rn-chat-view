import UIKit

/// Width-aware size cache for message cells.
///
/// Keys are `(id, width)` pairs — rotation or split-view width changes
/// automatically miss the cache instead of returning stale sizes.
struct SizeCache {
    private var store: [String: (width: CGFloat, height: CGFloat)] = [:]

    /// Returns cached height for the given key and width, or nil on miss.
    func height(forKey key: String, width: CGFloat) -> CGFloat? {
        guard let entry = store[key], entry.width == width else { return nil }
        return entry.height
    }

    /// Stores height for the given key and width.
    mutating func set(height: CGFloat, forKey key: String, width: CGFloat) {
        store[key] = (width, height)
    }

    /// Invalidates a single entry.
    mutating func invalidate(forKey key: String) {
        store.removeValue(forKey: key)
    }

    /// Clears all cached sizes.
    mutating func invalidateAll() {
        store.removeAll()
    }
}
