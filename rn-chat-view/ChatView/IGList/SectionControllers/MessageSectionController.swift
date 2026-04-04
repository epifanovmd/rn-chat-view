import IGListKit
import UIKit

// MARK: - MessageSectionDelegate (interaction callbacks only)

protocol MessageSectionDelegate: AnyObject {
    func messageSectionDidTap(messageId: String, attachmentIndex: Int?)
    func messageSectionDidLongPress(messageId: String, cell: UICollectionViewCell)
    func messageSectionDidTapReply(messageId: String)
    func messageSectionDidTapPollOption(messageId: String, pollId: String, optionId: String)
    func messageSectionDidTapPollDetail(messageId: String, pollId: String)
    func messageSectionDidTapVoice(messageId: String, url: String)
    func messageSectionDidTapReaction(messageId: String, emoji: String)
}

// MARK: - MessageSectionController

final class MessageSectionController: ListSectionController {
    private var item: MessageListItem!
    weak var sectionDelegate: MessageSectionDelegate?

    var theme: ChatTheme = .light
    var layout: ChatLayout = ChatLayout()
    var features: ChatFeatures = ChatFeatures()
    var replyResolver: ((ReplyInfo) -> ReplyDisplayInfo?)?

    override init() {
        super.init()
        let spacing = ChatLayout().cellVSpacing
        inset = UIEdgeInsets(top: spacing / 2, left: 0, bottom: spacing / 2, right: 0)
    }

    override func numberOfItems() -> Int { 1 }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        let width = ctx.containerSize.width
        let showName = features.senderNameMode != .never
        let height = MessageSizeCalculator.cellHeight(
            for: item.message,
            maxWidth: width,
            layout: layout,
            showSenderName: showName,
            features: features
        )
        return CGSize(width: width, height: max(height, layout.cellMinHeight))
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let ctx = collectionContext else { fatalError() }
        let cell: MessageCell = ctx.dequeueReusableCell(of: MessageCell.self, for: self, at: index) as! MessageCell

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

        let reply = item.message.reply.flatMap { replyResolver?($0) }
        let showName = features.senderNameMode != .never

        cell.configure(
            message: item.message,
            resolvedReply: reply,
            theme: theme,
            maxWidth: ctx.containerSize.width,
            showSenderName: showName,
            features: features,
            layout: layout
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
