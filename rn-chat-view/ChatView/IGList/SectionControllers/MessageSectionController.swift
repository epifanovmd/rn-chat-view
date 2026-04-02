import IGListKit
import UIKit

protocol MessageSectionDelegate: AnyObject {
    func messageSectionDidTap(messageId: String, attachmentIndex: Int?)
    func messageSectionDidLongPress(messageId: String, cell: UICollectionViewCell)
    func messageSectionDidTapReply(messageId: String)
    func messageSectionDidTapPollOption(messageId: String, pollId: String, optionId: String)
    func messageSectionDidTapPollDetail(messageId: String, pollId: String)
    func messageSectionDidTapVoice(messageId: String, url: String)
    func messageSectionDidTapReaction(messageId: String, emoji: String)
    func resolveReply(for info: ReplyInfo) -> ReplyDisplayInfo?
    var currentTheme: ChatTheme { get }
    var showSenderName: Bool { get }
}

final class MessageSectionController: ListSectionController {
    private var item: MessageListItem!
    weak var sectionDelegate: MessageSectionDelegate?

    override init() {
        super.init()
        inset = UIEdgeInsets(top: ChatLayout.current.cellVSpacing / 2, left: 0,
                             bottom: ChatLayout.current.cellVSpacing / 2, right: 0)
    }

    override func numberOfItems() -> Int { 1 }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        let width = ctx.containerSize.width
        let showName = sectionDelegate?.showSenderName ?? false
        let height = MessageSizeCalculator.cellHeight(
            for: item.message,
            maxWidth: width,
            resolvedReply: sectionDelegate?.resolveReply(for: item.message.reply ?? ReplyInfo(replyToId: "", senderName: nil, text: nil, hasImage: false)),
            showSenderName: showName
        )
        return CGSize(width: width, height: max(height, ChatLayout.current.cellMinHeight))
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let ctx = collectionContext else { fatalError() }
        let cell: MessageCell = ctx.dequeueReusableCell(of: MessageCell.self, for: self, at: index) as! MessageCell

        // Callbacks MUST be set BEFORE configure(), because configure() copies them to bubbleView
        cell.onTap = { [weak self] in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidTap(messageId: self.item.message.id, attachmentIndex: nil)
        }
        cell.onLongPress = { [weak self] c in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidLongPress(messageId: self.item.message.id, cell: c)
        }
        cell.onReplyTap = { [weak self] in
            guard let self, let replyTo = self.item.message.reply?.replyToId else { return }
            self.sectionDelegate?.messageSectionDidTapReply(messageId: replyTo)
        }
        cell.onMediaItemTap = { [weak self] index in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidTap(messageId: self.item.message.id, attachmentIndex: index)
        }
        cell.onFileItemTap = { [weak self] index in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidTap(messageId: self.item.message.id, attachmentIndex: index)
        }
        cell.onPollOptionTap = { [weak self] pollId, optionId in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidTapPollOption(messageId: self.item.message.id, pollId: pollId, optionId: optionId)
        }
        cell.onPollDetailTap = { [weak self] pollId in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidTapPollDetail(messageId: self.item.message.id, pollId: pollId)
        }
        cell.onVoiceTap = { [weak self] url in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidTapVoice(messageId: self.item.message.id, url: url)
        }
        cell.onReactionTap = { [weak self] emoji in
            guard let self else { return }
            self.sectionDelegate?.messageSectionDidTapReaction(messageId: self.item.message.id, emoji: emoji)
        }

        let theme = sectionDelegate?.currentTheme ?? .light
        let reply = item.message.reply.flatMap { sectionDelegate?.resolveReply(for: $0) }
        let maxWidth = ctx.containerSize.width
        let showName = sectionDelegate?.showSenderName ?? false

        cell.configure(
            message: item.message,
            resolvedReply: reply,
            theme: theme,
            maxWidth: maxWidth,
            showSenderName: showName
        )

        return cell
    }

    override func didUpdate(to object: Any) {
        item = object as? MessageListItem
    }

    override func didSelectItem(at index: Int) {
        sectionDelegate?.messageSectionDidTap(messageId: item.message.id, attachmentIndex: nil)
    }

    // MARK: - Highlight

    func highlightCell() {
        guard let cell = collectionContext?.cellForItem(at: 0, sectionController: self) as? MessageCell else { return }
        cell.playHighlight()
    }
}
