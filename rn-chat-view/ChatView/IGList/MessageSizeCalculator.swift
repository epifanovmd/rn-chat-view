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
        let L = ChatLayout.current

        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count)
            let tw = textWidth(content.text!, font: font)
            var w = min(tw + L.bubbleHPad * 2, maxW)
            // Учитываем реакции для эмодзи
            if !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        // Minimum width from sender name
        var senderNameW: CGFloat = 0
        if showSenderName, let name = msg.senderName, !msg.isMine {
            senderNameW = textWidth(name, font: L.senderNameFont) + L.bubbleHPad * 2
        }

        // Minimum width from reply preview
        var replyW: CGFloat = 0
        if let reply = msg.reply {
            let replyInner = L.replyAccentWidth + 8 + 8
            let senderW = textWidth(reply.senderName ?? "", font: L.replySenderFont)
            let textW = textWidth(reply.text ?? "…", font: L.replyFont)
            let replyContentW = max(senderW, textW)
            let minReplyW = min(replyContentW + replyInner, maxW * 0.7)
            replyW = minReplyW + L.bubbleHPad * 2
        }

        // Any media → учитываем реакции
        if content.hasMedia {
            var w = maxW
            if !msg.reactions.isEmpty {
                w = max(w, reactionWidth(for: msg.reactions) + L.bubbleHPad * 2)
            }
            return min(w, maxW)
        }

        // Text-only
        if let text = content.text {
            let tw = textWidth(text, font: L.messageFont)
            let minW = minFooterWidth(for: msg)
            var contentW = max(tw + L.bubbleHPad * 2, minW + L.bubbleHPad * 2)
            
            // Учитываем ширину реакций
            if !msg.reactions.isEmpty {
                let reactionW = reactionWidth(for: msg.reactions) + L.bubbleHPad * 2
                contentW = max(contentW, reactionW)
            }
            
            let baseW = min(max(contentW, max(senderNameW, replyW)), maxW)
            
            // Если реакции не влезают, всё равно ограничиваем maxW
            return baseW
        }

        return min(max(L.bubbleMinWidth, max(senderNameW, replyW)), maxW)
    }

    // MARK: - Bubble Height

    static func bubbleHeight(for msg: ChatMessage, bubbleWidth bw: CGFloat, resolvedReply: ReplyDisplayInfo?, showSenderName: Bool = false) -> CGFloat {
        let content = msg.content
        let L = ChatLayout.current

        if !content.hasMedia, let count = EmojiHelper.emojiOnlyCount(content.text) {
            let font = emojiFont(for: count)
            var h = textHeight(content.text!, font: font, width: bw - L.bubbleHPad * 2) + 8
            
            if !msg.reactions.isEmpty {
                // Вычисляем, сколько строк нужно для реакций
                let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2)
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

        h += contentHeight(for: content, width: innerW)

        if !msg.reactions.isEmpty {
            let reactionLines = reactionLinesCount(for: msg.reactions, maxWidth: bw - L.bubbleHPad * 2)
            h += CGFloat(reactionLines) * (L.reactionChipHeight + 4)
        }

        h += L.footerHeight + L.bubbleBottomPad
        return h
    }

    // MARK: - Helper для подсчёта строк реакций

    static func reactionLinesCount(for reactions: [Reaction], maxWidth: CGFloat) -> Int {
        guard !reactions.isEmpty else { return 0 }
        let L = ChatLayout.current
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
    
    // MARK: - Reaction Width

    static func reactionWidth(for reactions: [Reaction]) -> CGFloat {
        guard !reactions.isEmpty else { return 0 }
        let L = ChatLayout.current
        var total: CGFloat = 0
        for reaction in reactions {
            let text = "\(reaction.emoji) \(reaction.count)"
            let w = textWidth(text, font: L.reactionFont) + 16 // 16 = padding left + right
            total += w + L.reactionChipSpacing
        }
        return total - L.reactionChipSpacing // remove last spacing
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
