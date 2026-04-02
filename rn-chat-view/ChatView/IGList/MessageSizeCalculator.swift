import UIKit

enum MessageSizeCalculator {

    // MARK: - Public

    static func cellHeight(for msg: ChatMessage, maxWidth: CGFloat, resolvedReply: ReplyDisplayInfo?, showSenderName: Bool = false) -> CGFloat {
        let bw = bubbleWidth(for: msg, containerWidth: maxWidth, showSenderName: showSenderName)
        let bh = bubbleHeight(for: msg, bubbleWidth: bw, resolvedReply: resolvedReply, showSenderName: showSenderName)
        return bh + ChatLayout.current.cellVSpacing
    }

    // MARK: - Bubble Width

    static func bubbleWidth(for msg: ChatMessage, containerWidth: CGFloat, showSenderName: Bool = false) -> CGFloat {
        let maxW = containerWidth * ChatLayout.current.bubbleMaxWidthRatio
        let content = msg.content

        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count)
            let tw = textWidth(content.text!, font: font)
            return min(tw + ChatLayout.current.bubbleHPad * 2, maxW)
        }

        // Minimum width from sender name
        var senderNameW: CGFloat = 0
        if showSenderName, let name = msg.senderName, !msg.isMine {
            senderNameW = textWidth(name, font: ChatLayout.current.senderNameFont) + ChatLayout.current.bubbleHPad * 2
        }

        // Minimum width from reply preview
        var replyW: CGFloat = 0
        if let reply = msg.reply {
            let L = ChatLayout.current
            let replyInner = L.replyAccentWidth + 8 + 8 // accent + leading pad + trailing pad
            let senderW = textWidth(reply.senderName ?? "", font: L.replySenderFont)
            let textW = textWidth(reply.text ?? "…", font: L.replyFont)
            let replyContentW = max(senderW, textW)
            let minReplyW = min(replyContentW + replyInner, maxW * 0.7)
            replyW = minReplyW + L.bubbleHPad * 2
        }

        // Any media → max width
        if content.hasMedia {
            return maxW
        }

        // Text-only
        if let text = content.text {
            let tw = textWidth(text, font: ChatLayout.current.messageFont)
            let minW = minFooterWidth(for: msg)
            let contentW = max(tw + ChatLayout.current.bubbleHPad * 2, minW + ChatLayout.current.bubbleHPad * 2)
            return min(max(contentW, max(senderNameW, replyW)), maxW)
        }

        return min(max(ChatLayout.current.bubbleMinWidth, max(senderNameW, replyW)), maxW)
    }

    // MARK: - Bubble Height

    static func bubbleHeight(for msg: ChatMessage, bubbleWidth bw: CGFloat, resolvedReply: ReplyDisplayInfo?, showSenderName: Bool = false) -> CGFloat {
        let content = msg.content

        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count)
            return textHeight(content.text!, font: font, width: bw - ChatLayout.current.bubbleHPad * 2) + 8
        }

        let isForwarded = msg.forwardedFrom != nil
        let forwardedInset = isForwarded
            ? ChatLayout.current.forwardedAccentWidth + ChatLayout.current.forwardedContentInset
            : 0
        let innerW = bw - ChatLayout.current.bubbleHPad * 2 - forwardedInset
        var h: CGFloat = ChatLayout.current.bubbleVPad

        if showSenderName, msg.senderName != nil, !msg.isMine {
            h += ChatLayout.current.senderNameFont.lineHeight + 2
        }
        if isForwarded {
            h += ChatLayout.current.forwardedFont.lineHeight + 2
        }
        if msg.reply != nil {
            h += ChatLayout.current.replyHeight + 4
        }

        // Voice top spacer when no header
        let hasHeader = (showSenderName && msg.senderName != nil && !msg.isMine) || msg.reply != nil || isForwarded
        if content.voice != nil, !hasHeader {
            h += 4 + ChatLayout.current.bubbleSpacing
        }

        h += contentHeight(for: content, width: innerW)

        if !msg.reactions.isEmpty {
            h += ChatLayout.current.reactionChipHeight + 4
        }

        h += ChatLayout.current.footerHeight + ChatLayout.current.bubbleBottomPad
        return h
    }

    // MARK: - Content Height

    static func contentHeight(for content: MessageContent, width: CGFloat) -> CGFloat {
        var h: CGFloat = 0

        // Media height (by priority, matching bubble view)
        if let poll = content.poll {
            h += pollHeight(poll, width: width)
        } else if let files = content.files, !files.isEmpty {
            let L = ChatLayout.current
            let fileRowH = L.fileIconSize + L.filePadding * 2
            h += fileRowH * CGFloat(files.count) + L.fileRowSpacing * CGFloat(max(0, files.count - 1))
        } else if content.voice != nil {
            h += ChatLayout.current.voicePlaySize
        } else if let media = content.media, !media.isEmpty {
            h += MediaGridView.gridHeight(for: media, width: width)
        }

        // Text height (caption or standalone)
        if let text = content.text, !text.isEmpty {
            if h > 0 { h += 4 }
            h += textHeight(text, font: ChatLayout.current.messageFont, width: width)
        }

        return max(h, 0)
    }

    // MARK: - Helpers

    static func pollHeight(_ poll: PollPayload, width: CGFloat) -> CGFloat {
        let L = ChatLayout.current
        let count = poll.options.count
        var h: CGFloat = textHeight(poll.question, font: L.pollQuestionFont, width: width)
        h += 2 + L.pollSubtitleFont.lineHeight // subtitle
        h += L.pollHeaderSpacing
        h += CGFloat(count) * L.pollBarHeight + CGFloat(max(0, count - 1)) * L.pollOptionSpacing
        h += 6 + L.pollVotesFont.lineHeight // votes footer
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

    static func minFooterWidth(for msg: ChatMessage) -> CGFloat {
        var w = textWidth(DateHelper.shared.timeString(from: msg.timestamp), font: ChatLayout.current.timeFont)
        if msg.isMine { w += ChatLayout.current.statusIconSize + ChatLayout.current.footerSpacing }
        if msg.isEdited { w += textWidth("изм.", font: ChatLayout.current.editedFont) + ChatLayout.current.footerSpacing }
        return w + ChatLayout.current.footerSpacing * 2
    }

    static func emojiFont(for count: Int) -> UIFont {
        switch count {
        case 1: return ChatLayout.current.emojiFont1
        case 2: return ChatLayout.current.emojiFont2
        default: return ChatLayout.current.emojiFont3
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
