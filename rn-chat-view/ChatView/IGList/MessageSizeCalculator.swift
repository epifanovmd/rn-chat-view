import UIKit

enum MessageSizeCalculator {

    // MARK: - Public

    static func cellHeight(for msg: ChatMessage, maxWidth: CGFloat, layout L: ChatLayout = .current, resolvedReply: ReplyDisplayInfo?, showSenderName: Bool = false) -> CGFloat {
        let bw = bubbleWidth(for: msg, containerWidth: maxWidth, layout: L, showSenderName: showSenderName)
        let bh = bubbleHeight(for: msg, bubbleWidth: bw, layout: L, resolvedReply: resolvedReply, showSenderName: showSenderName)
        return bh + L.cellVSpacing
    }

    // MARK: - Bubble Width

    static func bubbleWidth(for msg: ChatMessage, containerWidth: CGFloat, layout L: ChatLayout = .current, showSenderName: Bool = false) -> CGFloat {
        let maxW = containerWidth * L.bubbleMaxWidthRatio
        let content = msg.content

        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count, layout: L)
            let tw = textWidth(content.text!, font: font)
            var w = min(tw + L.bubbleHPad * 2, maxW)
            if !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        var senderNameW: CGFloat = 0
        if showSenderName, let name = msg.senderName, !msg.isMine {
            senderNameW = textWidth(name, font: L.senderNameFont) + L.bubbleHPad * 2
        }

        var replyW: CGFloat = 0
        if let reply = msg.reply {
            let replyInner = L.replyAccentWidth + 8 + 8
            let senderW = textWidth(reply.senderName ?? "", font: L.replySenderFont)
            let textW = textWidth(reply.text ?? "…", font: L.replyFont)
            let replyContentW = max(senderW, textW)
            let minReplyW = min(replyContentW + replyInner, maxW * 0.7)
            replyW = minReplyW + L.bubbleHPad * 2
        }

        if content.hasMedia {
            var w = maxW
            if !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        if let text = content.text {
            let tw = textWidth(text, font: L.messageFont)
            let minW = minFooterWidth(for: msg, layout: L)
            var contentW = max(tw + L.bubbleHPad * 2, minW + L.bubbleHPad * 2)

            if !msg.reactions.isEmpty {
                let reactionW = reactionWidth(for: msg.reactions, layout: L) + L.bubbleHPad * 2
                contentW = max(contentW, reactionW)
            }

            let baseW = min(max(contentW, max(senderNameW, replyW)), maxW)
            return baseW
        }

        return min(max(L.bubbleMinWidth, max(senderNameW, replyW)), maxW)
    }

    // MARK: - Bubble Height

    static func bubbleHeight(for msg: ChatMessage, bubbleWidth bw: CGFloat, layout L: ChatLayout = .current, resolvedReply: ReplyDisplayInfo?, showSenderName: Bool = false) -> CGFloat {
        let content = msg.content

        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count, layout: L)
            var h = textHeight(content.text!, font: font, width: bw - L.bubbleHPad * 2) + 8

            if !msg.reactions.isEmpty {
                let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2, layout: L)
                h += CGFloat(reactionLines) * (L.reactionChipHeight + 4)
            }

            h += L.footerHeight + L.bubbleBottomPad
            return h
        }

        let isForwarded = msg.forwardedFrom != nil
        let forwardedInset = isForwarded
            ? L.forwardedAccentWidth + L.forwardedContentInset
            : 0
        let innerW = bw - L.bubbleHPad * 2 - forwardedInset
        var h: CGFloat = L.bubbleVPad

        if showSenderName, msg.senderName != nil, !msg.isMine {
            h += L.senderNameFont.lineHeight + 2
        }
        if isForwarded {
            h += L.forwardedFont.lineHeight + 2
        }
        if msg.reply != nil {
            h += L.replyHeight + 4
        }

        let hasHeader = (showSenderName && msg.senderName != nil && !msg.isMine) || msg.reply != nil || isForwarded
        if content.voice != nil, !hasHeader {
            h += 4 + L.bubbleSpacing
        }

        h += contentHeight(for: content, width: innerW, layout: L)

        if !msg.reactions.isEmpty {
            let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2, layout: L)
            h += CGFloat(reactionLines) * (L.reactionChipHeight + 4)
        }

        h += L.footerHeight + L.bubbleBottomPad
        return h
    }

    // MARK: - Reaction Lines

    static func reactionLinesCount(for reactions: [Reaction], maxWidth: CGFloat, layout L: ChatLayout = .current) -> Int {
        guard !reactions.isEmpty else { return 0 }
        var currentLineWidth: CGFloat = 0
        var lines = 1

        for reaction in reactions {
            let text = "\(reaction.emoji) \(reaction.count)"
            let chipWidth = textWidth(text, font: L.reactionFont) + 16

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

    static func contentHeight(for content: MessageContent, width: CGFloat, layout L: ChatLayout = .current) -> CGFloat {
        var h: CGFloat = 0

        if let poll = content.poll {
            h += pollHeight(poll, width: width, layout: L)
        } else if let files = content.files, !files.isEmpty {
            let fileRowH = L.fileIconSize + L.filePadding * 2
            h += fileRowH * CGFloat(files.count) + L.fileRowSpacing * CGFloat(max(0, files.count - 1))
        } else if content.voice != nil {
            h += L.voicePlaySize
        } else if let media = content.media, !media.isEmpty {
            h += MediaGridView.gridHeight(for: media, width: width)
        }

        if let text = content.text, !text.isEmpty {
            if h > 0 { h += 4 }
            h += textHeight(text, font: L.messageFont, width: width)
        }

        return max(h, 0)
    }

    // MARK: - Reaction Width

    static func reactionWidth(for reactions: [Reaction], layout L: ChatLayout = .current) -> CGFloat {
        guard !reactions.isEmpty else { return 0 }
        var total: CGFloat = 0
        for reaction in reactions {
            let text = "\(reaction.emoji) \(reaction.count)"
            let w = textWidth(text, font: L.reactionFont) + 16
            total += w + L.reactionChipSpacing
        }
        return total - L.reactionChipSpacing
    }

    // MARK: - Helpers

    static func pollHeight(_ poll: PollPayload, width: CGFloat, layout L: ChatLayout = .current) -> CGFloat {
        let count = poll.options.count
        var h: CGFloat = textHeight(poll.question, font: L.pollQuestionFont, width: width)
        h += 2 + L.pollSubtitleFont.lineHeight
        h += L.pollHeaderSpacing
        h += CGFloat(count) * L.pollBarHeight + CGFloat(max(0, count - 1)) * L.pollOptionSpacing
        h += 6 + L.pollVotesFont.lineHeight
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

    static func minFooterWidth(for msg: ChatMessage, layout L: ChatLayout = .current) -> CGFloat {
        var w = textWidth(DateHelper.shared.timeString(from: msg.timestamp), font: L.timeFont)
        if msg.isMine { w += L.statusIconSize + L.footerSpacing }
        if msg.isEdited { w += textWidth("изм.", font: L.editedFont) + L.footerSpacing }
        return w + L.footerSpacing * 2
    }

    static func emojiFont(for count: Int, layout L: ChatLayout = .current) -> UIFont {
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
