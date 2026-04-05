import UIKit

// MARK: - Row Building & Layout Data

extension ChatViewController {

    /// Build flat `ChatRow` array from messages, injecting date separators and loading indicator.
    func buildRows(from msgs: [ChatMessage]) -> [ChatRow] {
        var result: [ChatRow] = []
        result.reserveCapacity(msgs.count + msgs.count / 5)
        let showSeps = features.showDateSeparators
        var seenGroups: Set<String> = []

        for msg in msgs {
            if showSeps, !seenGroups.contains(msg.groupDate) {
                seenGroups.insert(msg.groupDate)
                result.append(.dateSeparator(groupDate: msg.groupDate))
            }
            result.append(.message(msg))
        }

        if isLoadingBottom && features.showBottomLoadingIndicator {
            result.append(.loading(position: "bottom"))
        }
        return result
    }

    /// Rebuild `rowIndexCache` and `cachedDateSeparators` from current `rows`.
    func rebuildCachesFromRows() {
        var cache: [String: Int] = [:]
        cache.reserveCapacity(rows.count)
        var dateSeps: [(rowIndex: Int, groupDate: String)] = []

        for (idx, row) in rows.enumerated() {
            switch row {
            case .message(let msg): cache[msg.id] = idx
            case .dateSeparator(let gd): dateSeps.append((rowIndex: idx, groupDate: gd))
            case .loading: break
            }
        }
        rowIndexCache = cache
        cachedDateSeparators = dateSeps
    }

    /// Compute layout data (heights + insets) for every row. Uses `sizeCache` for O(1) lookups.
    func computeLayoutData() -> [RowLayoutInfo] {
        rebuildCachesFromRows()
        var width = collectionView.bounds.width
        if width <= 0 { width = UIScreen.main.bounds.width }

        var result: [RowLayoutInfo] = []
        result.reserveCapacity(rows.count)

        for row in rows {
            switch row {
            case .message(let msg):
                let h = computeMessageHeight(forId: msg.id, width: width)
                result.append(RowLayoutInfo(height: h, topInset: layout.cellVSpacing / 2, bottomInset: layout.cellVSpacing / 2))

            case .dateSeparator(let gd):
                let key = "date_\(gd)"
                let h: CGFloat
                if let cached = sizeCache.height(forKey: key, width: width) {
                    h = cached
                } else {
                    let hh = contentFactory.dateSeparatorHeight(layout: layout)
                    sizeCache.set(height: hh, forKey: key, width: width)
                    h = hh
                }
                result.append(RowLayoutInfo(height: h, topInset: layout.sectionSpacing, bottomInset: layout.sectionSpacing))

            case .loading(let pos):
                let h: CGFloat = pos == "top" ? layout.dateSeparatorFont.lineHeight + layout.dateSeparatorVPad * 2 : 40
                let inset: CGFloat = pos == "top" ? layout.sectionSpacing : 8
                result.append(RowLayoutInfo(height: h, topInset: inset, bottomInset: inset))
            }
        }
        return result
    }

    /// Compute height for a single message. Uses `sizeCache` for O(1) lookups.
    func computeMessageHeight(forId id: String, width: CGFloat) -> CGFloat {
        if let cached = sizeCache.height(forKey: id, width: width) { return cached }
        guard let msg = messageIndex[id] else { return layout.cellMinHeight }
        let showName = ChatDataSource.shouldShowSenderName(for: msg, mode: features.senderNameMode)
        let height = MessageSizeCalculator.cellHeight(
            for: msg,
            maxWidth: width,
            layout: layout,
            showSenderName: showName,
            features: features,
            factory: contentFactory
        )
        let h = max(height, layout.cellMinHeight)
        sizeCache.set(height: h, forKey: id, width: width)
        return h
    }

    /// Rebuild `messageIndex` from current `messages` array.
    func rebuildMessageIndex() {
        messageIndex = Dictionary(minimumCapacity: messages.count)
        for msg in messages { messageIndex[msg.id] = msg }
    }

    /// Full reload — rebuild rows, layout data, and collection view.
    func reloadAll() {
        rows = buildRows(from: messages)
        chatLayout.rowLayoutData = computeLayoutData()
        collectionView.reloadData()
    }

    // MARK: - Internal State Mutation (used by MessageUpdateHandler)

    func setMessages(_ newMessages: [ChatMessage]) {
        messages = newMessages
    }

    func setRows(_ newRows: [ChatRow]) {
        rows = newRows
    }

    func invalidateSizeCache(forKey key: String) {
        sizeCache.invalidate(forKey: key)
    }

    func applyLayoutData(_ data: [RowLayoutInfo]) {
        chatLayout.rowLayoutData = data
    }
}
