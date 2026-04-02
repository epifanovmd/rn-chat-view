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

        // Any media → max width
        if content.hasMedia {
            return maxW
        }

        // Text-only
        if let text = content.text {
            let tw = textWidth(text, font: ChatLayout.current.messageFont)
            let minW = minFooterWidth(for: msg)
            let contentW = max(tw + ChatLayout.current.bubbleHPad * 2, minW + ChatLayout.current.bubbleHPad * 2)
            return min(max(contentW, senderNameW), maxW)
        }

        return max(ChatLayout.current.bubbleMinWidth, senderNameW)
    }

    // MARK: - Bubble Height

    static func bubbleHeight(for msg: ChatMessage, bubbleWidth bw: CGFloat, resolvedReply: ReplyDisplayInfo?, showSenderName: Bool = false) -> CGFloat {
        let content = msg.content

        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count)
            return textHeight(content.text!, font: font, width: bw - ChatLayout.current.bubbleHPad * 2) + 8
        }

        let innerW = bw - ChatLayout.current.bubbleHPad * 2
        var h: CGFloat = ChatLayout.current.bubbleVPad

        if showSenderName, msg.senderName != nil, !msg.isMine {
            h += ChatLayout.current.senderNameFont.lineHeight + 2
        }
        if msg.forwardedFrom != nil {
            h += ChatLayout.current.forwardedFont.lineHeight + 2
        }
        if msg.reply != nil {
            h += ChatLayout.current.replyHeight + 4
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
            let fileRowH = ChatLayout.current.fileIconSize + 8
            h += fileRowH * CGFloat(files.count) + 2 * CGFloat(max(0, files.count - 1))
        } else if content.voice != nil {
            h += ChatLayout.current.voiceWaveformHeight + ChatLayout.current.voicePlaySize / 2 + 8
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
        var h: CGFloat = textHeight(poll.question, font: ChatLayout.current.pollQuestionFont, width: width) + 8
        h += CGFloat(poll.options.count) * (ChatLayout.current.pollBarHeight + ChatLayout.current.pollOptionSpacing)
        h += ChatLayout.current.pollVotesFont.lineHeight + 4
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
        if msg.isEdited { w += textWidth("edited", font: ChatLayout.current.editedFont) + ChatLayout.current.footerSpacing }
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
