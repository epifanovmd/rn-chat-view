import UIKit

public enum MessageSizeCalculator {

    // MARK: - Публичное API

    public static func cellHeight(for msg: ChatMessage, maxWidth: CGFloat, layout L: ChatLayout = ChatLayout(), showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), factory: ChatContentFactory = DefaultChatContentFactory(), resolvedReply: ReplyDisplayInfo? = nil) -> CGFloat {
        let bw = bubbleWidth(for: msg, containerWidth: maxWidth, layout: L, showSenderName: showSenderName, features: features, factory: factory, resolvedReply: resolvedReply)
        let bh = bubbleHeight(for: msg, bubbleWidth: bw, layout: L, showSenderName: showSenderName, features: features, factory: factory)
        return bh + L.cellVSpacing
    }

    // MARK: - Ширина пузыря

    public static func bubbleWidth(for msg: ChatMessage, containerWidth: CGFloat, layout L: ChatLayout = ChatLayout(), showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), factory: ChatContentFactory = DefaultChatContentFactory(), resolvedReply: ReplyDisplayInfo? = nil) -> CGFloat {
        let avatarSpace: CGFloat = (features.showAvatars && msg.ownership == .theirs)
            ? L.avatarSize + L.avatarLeadingMargin + L.avatarBubbleSpacing
            : 0
        let maxW = containerWidth * L.bubbleMaxWidthRatio - avatarSpace
        let content = msg.content

        var senderNameW: CGFloat = 0
        if showSenderName, let name = msg.senderName {
            senderNameW = ChatTextMeasurer.width(name, font: L.senderNameFont) + L.bubbleHPad * 2
        }

        var replyW: CGFloat = 0
        if features.showReplyPreview, let reply = msg.reply {
            let replyInner = L.replyAccentWidth + L.bubbleHPad + L.bubbleHPad
            // Меряем ровно то, что покажет ReplyPreviewView (с его фоллбэками).
            let senderW = ChatTextMeasurer.width(
                ReplyPreviewView.senderText(reply: reply, resolved: resolvedReply),
                font: L.replySenderFont)
            let textW = ChatTextMeasurer.width(
                ReplyPreviewView.contentText(reply: reply, resolved: resolvedReply),
                font: L.replyFont)
            let replyContentW = max(senderW, textW)
            let minReplyW = min(replyContentW + replyInner, maxW * 0.7)
            replyW = minReplyW + L.bubbleHPad * 2
        }

        // Эмодзи-сообщение: ширина по крупному шрифту, но не уже имени
        // отправителя и цитаты — иначе они схлопываются в несколько символов.
        if content.content == nil, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = ChatTextMeasurer.emojiFont(for: count, layout: L)
            let tw = ChatTextMeasurer.width(content.text!, font: font)
            var w = min(tw + L.bubbleHPad * 2, maxW)

            w = max(w, senderNameW, replyW)
            if features.showReactions, !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        if let media = content.content {
            var w = maxW

            // Контент с предпочтительной шириной (голосовое) сжимает пузырь,
            // но не уже футера, цитаты, имени отправителя и текста.
            if let preferred = factory.contentPreferredWidth(
                for: media, maxWidth: maxW - L.bubbleHPad * 2, layout: L
            ) {
                w = preferred + L.bubbleHPad * 2
                if let text = content.text, !text.isEmpty {
                    w = max(w, ChatTextMeasurer.width(text, font: L.messageFont) + L.bubbleHPad * 2)
                }
                w = max(w, minFooterWidth(for: msg, layout: L, features: features) + L.bubbleHPad * 2)
                w = max(w, senderNameW, replyW)
            }

            if features.showReactions, !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        if content.content == nil, let text = content.text {
            let tw = ChatTextMeasurer.width(text, font: L.messageFont)
            let minW = minFooterWidth(for: msg, layout: L, features: features)
            var contentW = max(tw + L.bubbleHPad * 2, minW + L.bubbleHPad * 2)

            if features.showReactions, !msg.reactions.isEmpty {
                let reactionW = reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2
                contentW = max(contentW, reactionW)
            }

            let baseW = min(max(contentW, max(senderNameW, replyW)), maxW)
            return baseW
        }

        return min(max(L.bubbleMinWidth, max(senderNameW, replyW)), maxW)
    }

    // MARK: - Высота пузыря

    public static func bubbleHeight(for msg: ChatMessage, bubbleWidth bw: CGFloat, layout L: ChatLayout = ChatLayout(), showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), factory: ChatContentFactory = DefaultChatContentFactory()) -> CGFloat {
        let content = msg.content
        let emojiCount = content.content == nil ? EmojiHelper.emojiOnlyCount(content.text) : nil
        let showsName = showSenderName && msg.senderName != nil
        let hasReply = features.showReplyPreview && msg.reply != nil

        // Пузырь без фона — только у «чистого» эмодзи: с именем, цитатой или
        // пересылкой это обычное сообщение с крупным эмодзи внутри.
        if let count = emojiCount,
           !showsName,
           !hasReply,
           !(features.showForwardedMark && msg.forwardedFrom != nil) {
            let font = ChatTextMeasurer.emojiFont(for: count, layout: L)
            var h = ChatTextMeasurer.height(content.text!, font: font, width: bw - L.bubbleHPad * 2) + L.bubbleVPad * 2

            if features.showReactions, !msg.reactions.isEmpty {
                let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2, layout: L)
                h += CGFloat(reactionLines) * (L.reactionChipHeight + L.reactionChipSpacing)
            }

            let hasFooter = features.showTimestamp || (msg.isEdited && features.showEditedMark) || (msg.ownership == .mine && features.showMessageStatus)
            if hasFooter { h += L.footerHeight }
            h += L.bubbleBottomPad
            return h
        }

        let isForwarded = features.showForwardedMark && msg.forwardedFrom != nil
        let forwardedInset = isForwarded
            ? L.forwardedAccentWidth + L.forwardedContentInset
            : 0
        let innerW = bw - L.bubbleHPad * 2 - forwardedInset
        var h: CGFloat = L.bubbleVPad

        if showsName {
            h += L.senderNameFont.lineHeight + L.bubbleSpacing
        }
        if isForwarded {
            h += L.forwardedFont.lineHeight + L.bubbleSpacing
        }
        if hasReply {
            h += L.replyHeight + L.bubbleSpacing
        }

        // Текст эмодзи-сообщения меряется крупным шрифтом и в общем пути.
        let emojiFont = emojiCount.map { ChatTextMeasurer.emojiFont(for: $0, layout: L) }

        h += contentHeight(for: content, width: innerW, layout: L, factory: factory, textFont: emojiFont)

        if features.showThreadIndicator, msg.thread != nil {
            h += L.threadBarHeight + L.bubbleSpacing
        }

        if features.showReactions, !msg.reactions.isEmpty {
            let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2, layout: L)
            h += CGFloat(reactionLines) * (L.reactionChipHeight + L.reactionChipSpacing)
        }

        let hasFooter = features.showTimestamp || (msg.isEdited && features.showEditedMark) || (msg.ownership == .mine && features.showMessageStatus)
        if hasFooter { h += L.footerHeight }
        h += L.bubbleBottomPad
        return h
    }

    // MARK: - Строки реакций

    public static func reactionLinesCount(for reactions: [Reaction], maxWidth: CGFloat, layout L: ChatLayout = ChatLayout()) -> Int {
        guard !reactions.isEmpty else { return 0 }
        var currentLineWidth: CGFloat = 0
        var lines = 1

        for reaction in reactions {
            let text = "\(reaction.emoji) \(reaction.count)"
            let chipWidth = ChatTextMeasurer.width(text, font: L.reactionFont) + L.reactionChipPadding * 2

            if currentLineWidth + chipWidth + (currentLineWidth > 0 ? L.reactionChipSpacing : 0) > maxWidth {
                lines += 1
                currentLineWidth = chipWidth
            } else {
                currentLineWidth += chipWidth + (currentLineWidth > 0 ? L.reactionChipSpacing : 0)
            }
        }

        return lines
    }

    // MARK: - Высота контента

    public static func contentHeight(for content: MessageBody, width: CGFloat, layout L: ChatLayout = ChatLayout(), factory: ChatContentFactory = DefaultChatContentFactory(), textFont: UIFont? = nil) -> CGFloat {
        var h: CGFloat = 0

        if let media = content.content {
            h += factory.contentHeight(for: media, width: width, layout: L)
        }

        if let text = content.text, !text.isEmpty {
            if h > 0 { h += L.mixedContentSpacing }
            h += factory.textHeight(text: text, font: textFont ?? L.messageFont, width: width)
        }

        return max(h, 0)
    }

    // MARK: - Ширина реакций

    public static func reactionWidth(for reactions: [Reaction], layout L: ChatLayout = ChatLayout()) -> CGFloat {
        guard !reactions.isEmpty else { return 0 }
        var total: CGFloat = 0
        for reaction in reactions {
            let text = "\(reaction.emoji) \(reaction.count)"
            let w = ChatTextMeasurer.width(text, font: L.reactionFont) + L.reactionChipPadding * 2
            total += w + L.reactionChipSpacing
        }
        return total - L.reactionChipSpacing
    }

    // MARK: - Вспомогательные

    public static func minFooterWidth(for msg: ChatMessage, layout L: ChatLayout = ChatLayout(), features: ChatFeatures = ChatFeatures()) -> CGFloat {
        var w: CGFloat = 0
        if features.showTimestamp {
            w += ChatTextMeasurer.width(DateHelper.shared.timeString(from: msg.timestamp), font: L.timeFont)
        }
        if msg.ownership == .mine && features.showMessageStatus {
            w += L.statusIconSize + L.footerSpacing
        }
        if msg.isEdited && features.showEditedMark {
            w += ChatTextMeasurer.width("изм.", font: L.editedFont) + L.footerSpacing
        }
        if w > 0 { w += L.footerSpacing * 2 }
        return w
    }
}

// MARK: - Помощник эмодзи

public enum EmojiHelper {
    public static func emojiOnlyCount(_ text: String?) -> Int? {
        guard let text, !text.isEmpty else { return nil }
        let scalars = text.unicodeScalars
        let stripped = scalars.filter { !$0.properties.isJoinControl && !$0.properties.isVariationSelector && $0.value != 0xFE0F }
        guard stripped.allSatisfy({ $0.properties.isEmoji && $0.properties.isEmojiPresentation || $0.properties.isEmojiModifier || $0.value == 0x200D }) else { return nil }
        let count = text.count
        guard count >= 1 && count <= 3 else { return nil }
        return count
    }
}
