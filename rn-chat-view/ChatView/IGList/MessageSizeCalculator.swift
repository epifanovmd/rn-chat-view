import UIKit

enum MessageSizeCalculator {

    // MARK: - Public

    static func cellHeight(for msg: ChatMessage, maxWidth: CGFloat, layout L: ChatLayout = ChatLayout(), showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), factory: ChatContentFactory = DefaultChatContentFactory()) -> CGFloat {
        let bw = bubbleWidth(for: msg, containerWidth: maxWidth, layout: L, showSenderName: showSenderName, features: features)
        let bh = bubbleHeight(for: msg, bubbleWidth: bw, layout: L, showSenderName: showSenderName, features: features, factory: factory)
        return bh + L.cellVSpacing
    }

    // MARK: - Bubble Width

    static func bubbleWidth(for msg: ChatMessage, containerWidth: CGFloat, layout L: ChatLayout = ChatLayout(), showSenderName: Bool = false, features: ChatFeatures = ChatFeatures()) -> CGFloat {
        let maxW = containerWidth * L.bubbleMaxWidthRatio
        let content = msg.content

        if content.media == nil, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count, layout: L)
            let tw = textWidth(content.text!, font: font)
            var w = min(tw + L.bubbleHPad * 2, maxW)
            if features.showReactions, !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        var senderNameW: CGFloat = 0
        if showSenderName, let name = msg.senderName, !msg.isMine {
            senderNameW = textWidth(name, font: L.senderNameFont) + L.bubbleHPad * 2
        }

        var replyW: CGFloat = 0
        if features.showReplyPreview, let reply = msg.reply {
            let replyInner = L.replyAccentWidth + L.bubbleHPad + L.bubbleHPad
            let senderW = textWidth(reply.senderName ?? "", font: L.replySenderFont)
            let textW = textWidth(reply.text ?? "…", font: L.replyFont)
            let replyContentW = max(senderW, textW)
            let minReplyW = min(replyContentW + replyInner, maxW * 0.7)
            replyW = minReplyW + L.bubbleHPad * 2
        }

        if content.media != nil {
            var w = maxW
            if features.showReactions, !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        if content.media == nil, let text = content.text {
            let tw = textWidth(text, font: L.messageFont)
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

    // MARK: - Bubble Height

    static func bubbleHeight(for msg: ChatMessage, bubbleWidth bw: CGFloat, layout L: ChatLayout = ChatLayout(), showSenderName: Bool = false, features: ChatFeatures = ChatFeatures(), factory: ChatContentFactory = DefaultChatContentFactory()) -> CGFloat {
        let content = msg.content

        if content.media == nil, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count, layout: L)
            var h = textHeight(content.text!, font: font, width: bw - L.bubbleHPad * 2) + L.bubbleVPad * 2

            if features.showReactions, !msg.reactions.isEmpty {
                let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2, layout: L)
                h += CGFloat(reactionLines) * (L.reactionChipHeight + L.reactionChipSpacing)
            }

            let hasFooter = features.showTimestamp || (msg.isEdited && features.showEditedMark) || (msg.isMine && features.showMessageStatus)
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

        if showSenderName, msg.senderName != nil, !msg.isMine {
            h += L.senderNameFont.lineHeight + L.bubbleSpacing
        }
        if isForwarded {
            h += L.forwardedFont.lineHeight + L.bubbleSpacing
        }
        if features.showReplyPreview, msg.reply != nil {
            h += L.replyHeight + L.bubbleSpacing
        }

        let hasReply = features.showReplyPreview && msg.reply != nil
        let hasHeader = (showSenderName && msg.senderName != nil && !msg.isMine) || hasReply || isForwarded
        if case .voice = content.media, !hasHeader {
            h += L.bubbleSpacing + L.bubbleSpacing
        }

        h += contentHeight(for: content, width: innerW, layout: L, factory: factory)

        if features.showReactions, !msg.reactions.isEmpty {
            let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2, layout: L)
            h += CGFloat(reactionLines) * (L.reactionChipHeight + L.reactionChipSpacing)
        }

        let hasFooter = features.showTimestamp || (msg.isEdited && features.showEditedMark) || (msg.isMine && features.showMessageStatus)
        if hasFooter { h += L.footerHeight }
        h += L.bubbleBottomPad
        return h
    }

    // MARK: - Reaction Lines

    static func reactionLinesCount(for reactions: [Reaction], maxWidth: CGFloat, layout L: ChatLayout = ChatLayout()) -> Int {
        guard !reactions.isEmpty else { return 0 }
        var currentLineWidth: CGFloat = 0
        var lines = 1

        for reaction in reactions {
            let text = "\(reaction.emoji) \(reaction.count)"
            let chipWidth = textWidth(text, font: L.reactionFont) + L.reactionChipPadding * 2

            if currentLineWidth + chipWidth + (currentLineWidth > 0 ? L.reactionChipSpacing : 0) > maxWidth {
                lines += 1
                currentLineWidth = chipWidth
            } else {
                currentLineWidth += chipWidth + (currentLineWidth > 0 ? L.reactionChipSpacing : 0)
            }
        }

        return lines
    }

    // MARK: - Content Height

    static func contentHeight(for content: MessageContent, width: CGFloat, layout L: ChatLayout = ChatLayout(), factory: ChatContentFactory = DefaultChatContentFactory()) -> CGFloat {
        var h: CGFloat = 0

        if let media = content.media {
            h += factory.contentHeight(for: media, width: width, layout: L)
        }

        if let text = content.text, !text.isEmpty {
            if h > 0 { h += L.mixedContentSpacing }
            h += factory.textHeight(text: text, font: L.messageFont, width: width)
        }

        return max(h, 0)
    }

    // MARK: - Reaction Width

    static func reactionWidth(for reactions: [Reaction], layout L: ChatLayout = ChatLayout()) -> CGFloat {
        guard !reactions.isEmpty else { return 0 }
        var total: CGFloat = 0
        for reaction in reactions {
            let text = "\(reaction.emoji) \(reaction.count)"
            let w = textWidth(text, font: L.reactionFont) + L.reactionChipPadding * 2
            total += w + L.reactionChipSpacing
        }
        return total - L.reactionChipSpacing
    }

    // MARK: - Helpers

    static func pollHeight(_ poll: PollPayload, width: CGFloat, layout L: ChatLayout = ChatLayout()) -> CGFloat {
        let count = poll.options.count
        var h: CGFloat = textHeight(poll.question, font: L.pollQuestionFont, width: width)
        h += L.bubbleSpacing + L.pollSubtitleFont.lineHeight
        h += L.pollHeaderSpacing
        h += CGFloat(count) * L.pollBarHeight + CGFloat(max(0, count - 1)) * L.pollOptionSpacing
        h += L.pollHeaderSpacing + L.pollVotesFont.lineHeight
        return h
    }

    static func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let size = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
        return ceil(size.height)
    }

    static func textWidth(_ text: String, font: UIFont) -> CGFloat {
        let size = (text as NSString).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight),
            options: [.usesLineFragmentOrigin],
            attributes: [.font: font],
            context: nil
        ).size
        return ceil(size.width)
    }

    static func minFooterWidth(for msg: ChatMessage, layout L: ChatLayout = ChatLayout(), features: ChatFeatures = ChatFeatures()) -> CGFloat {
        var w: CGFloat = 0
        if features.showTimestamp {
            w += textWidth(DateHelper.shared.timeString(from: msg.timestamp), font: L.timeFont)
        }
        if msg.isMine && features.showMessageStatus {
            w += L.statusIconSize + L.footerSpacing
        }
        if msg.isEdited && features.showEditedMark {
            w += textWidth("изм.", font: L.editedFont) + L.footerSpacing
        }
        if w > 0 { w += L.footerSpacing * 2 }
        return w
    }

    static func emojiFont(for count: Int, layout L: ChatLayout = ChatLayout()) -> UIFont {
        switch count {
        case 1: return L.emojiFont1
        case 2: return L.emojiFont2
        default: return L.emojiFont3
        }
    }
}

// MARK: - Emoji Helper

enum EmojiHelper {
    static func emojiOnlyCount(_ text: String?) -> Int? {
        guard let text, !text.isEmpty else { return nil }
        let scalars = text.unicodeScalars
        let stripped = scalars.filter { !$0.properties.isJoinControl && !$0.properties.isVariationSelector && $0.value != 0xFE0F }
        guard stripped.allSatisfy({ $0.properties.isEmoji && $0.properties.isEmojiPresentation || $0.properties.isEmojiModifier || $0.value == 0x200D }) else { return nil }
        let count = text.count
        guard count >= 1 && count <= 3 else { return nil }
        return count
    }
}
