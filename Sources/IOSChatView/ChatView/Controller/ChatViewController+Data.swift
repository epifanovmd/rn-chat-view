import UIKit

// MARK: - Построение строк и данных лейаута

extension ChatViewController {

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

        if isLoadingBottom && features.showBottomLoadingIndicator && !msgs.isEmpty {
            result.append(.loading(position: "bottom"))
        }
        return result
    }

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

    func computeLayoutData() -> [RowLayoutInfo] {
        rebuildCachesFromRows()
        return computeLayoutInfo(for: rows)
    }

    func computeLayoutInfo(for rowSlice: [ChatRow]) -> [RowLayoutInfo] {
        var width = collectionView.bounds.width
        if width <= 0 { width = UIScreen.main.bounds.width }

        var result: [RowLayoutInfo] = []
        result.reserveCapacity(rowSlice.count)

        for row in rowSlice {
            result.append(layoutInfo(for: row, width: width))
        }
        return result
    }

    /// Единственная точка сборки RowLayoutInfo для message-строки — используется
    /// и полным пересчётом, и инкрементальным contentOnly-патчем. Расхождение
    /// формул между ними = скрытый источник скролл-джампов.
    func messageRowLayoutInfo(for msg: ChatMessage, width: CGFloat) -> RowLayoutInfo {
        let h = computeMessageHeight(forId: msg.id, width: width)
        let extraSpacing: CGFloat
        switch msg.ownership {
        case .system: extraSpacing = layout.systemCellBottomSpacing
        case .pinned: extraSpacing = layout.pinnedCellBottomSpacing
        default:      extraSpacing = 0
        }
        return RowLayoutInfo(
            height: h,
            topInset: layout.cellVSpacing / 2 + extraSpacing,
            bottomInset: layout.cellVSpacing / 2 + extraSpacing
        )
    }

    private func layoutInfo(for row: ChatRow, width: CGFloat) -> RowLayoutInfo {
        switch row {
        case .message(let msg):
            return messageRowLayoutInfo(for: msg, width: width)

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
            return RowLayoutInfo(height: h, topInset: layout.sectionSpacing, bottomInset: layout.sectionSpacing)

        case .loading(let pos):
            let h: CGFloat = pos == "top" ? layout.dateSeparatorFont.lineHeight + layout.dateSeparatorVPad * 2 : 40
            let inset: CGFloat = pos == "top" ? layout.sectionSpacing : 8
            return RowLayoutInfo(height: h, topInset: inset, bottomInset: inset)
        }
    }

    /// Цитата в том виде, в каком её покажет ячейка: имя и текст берутся
    /// из оригинального сообщения, а не из сырого ReplyInfo.
    func resolvedReply(for msg: ChatMessage) -> ReplyDisplayInfo? {
        msg.reply.flatMap { info -> ReplyDisplayInfo? in
            guard let original = messageIndex[info.replyToId] else { return nil }
            return ReplyDisplayInfo(
                senderName: original.senderName ?? ChatStrings.unknownSender,
                text: original.content.text ?? "",
                hasImage: original.content.content != nil
            )
        }
    }

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
            factory: contentFactory,
            resolvedReply: resolvedReply(for: msg)
        )
        let h = max(height, layout.cellMinHeight)
        sizeCache.set(height: h, forKey: id, width: width)
        return h
    }

    /// Ширина пузыря с кешированием — иначе каждый dequeue заново меряет
    /// текст (имя, цитату, реакции) через boundingRect.
    func cachedBubbleWidth(for msg: ChatMessage, containerWidth: CGFloat) -> CGFloat {
        if let cached = sizeCache.bubbleWidth(forKey: msg.id, width: containerWidth) { return cached }
        let showName = ChatDataSource.shouldShowSenderName(for: msg, mode: features.senderNameMode)
        let bw = MessageSizeCalculator.bubbleWidth(
            for: msg,
            containerWidth: containerWidth,
            layout: layout,
            showSenderName: showName,
            features: features,
            factory: contentFactory,
            resolvedReply: resolvedReply(for: msg)
        )
        sizeCache.set(bubbleWidth: bw, forKey: msg.id, width: containerWidth)
        return bw
    }

    func rebuildMessageIndex() {
        messageIndex = Dictionary(minimumCapacity: messages.count)
        for msg in messages { messageIndex[msg.id] = msg }
    }

    func reloadAll() {
        rows = buildRows(from: messages)
        applyLayoutData(computeLayoutData())
        collectionView.reloadData()
    }

    // MARK: - Мутация состояния (используется MessageUpdateHandler)

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
        chatLayout.setNeedsFullPrepare()
        chatLayout.showAvatars = features.showAvatars
        chatLayout.avatarSize = layout.avatarSize
        chatLayout.avatarLeadingMargin = layout.avatarLeadingMargin
        chatLayout.avatarGroups = features.showAvatars ? computeAvatarGroups() : []
    }

    private func computeAvatarGroups() -> [AvatarGroup] {
        computeAvatarGroups(inRange: 0..<rows.count)
    }

    private func computeAvatarGroups(inRange range: Range<Int>) -> [AvatarGroup] {
        var groups: [AvatarGroup] = []
        var i = range.lowerBound
        while i < range.upperBound {
            guard case .message(let msg) = rows[i],
                  msg.ownership == .theirs,
                  let name = msg.senderName else {
                i += 1
                continue
            }

            let firstIdx = i
            var lastIdx = i
            let avatarUrl = msg.senderAvatarUrl

            while lastIdx + 1 < range.upperBound {
                guard case .message(let next) = rows[lastIdx + 1],
                      next.ownership == .theirs,
                      next.senderName == name else { break }
                lastIdx += 1
            }

            groups.append(AvatarGroup(
                firstIndex: firstIdx,
                lastIndex: lastIdx,
                senderName: name,
                senderAvatarUrl: avatarUrl
            ))
            i = lastIdx + 1
        }
        return groups
    }
}
