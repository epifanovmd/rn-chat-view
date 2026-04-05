import IGListKit
import UIKit

// MARK: - MessageSectionDelegate (interaction callbacks only)

public protocol MessageSectionDelegate: AnyObject {
    func messageSectionDidTap(messageId: String, attachmentIndex: Int?)
    func messageSectionDidLongPress(messageId: String, cell: UICollectionViewCell)
    func messageSectionDidTapReply(messageId: String)
    func messageSectionDidTapPollOption(messageId: String, pollId: String, optionId: String)
    func messageSectionDidTapPollDetail(messageId: String, pollId: String)
    func messageSectionDidTapVoice(messageId: String, url: String)
    func messageSectionDidTapReaction(messageId: String, emoji: String)
}

// MARK: - MessageSectionController

public final class MessageSectionController: ListSectionController {
    private var item: MessageListItem!
    weak var sectionDelegate: MessageSectionDelegate?

    var theme: ChatTheme = .light
    var layout: ChatLayout = ChatLayout()
    var features: ChatFeatures = ChatFeatures()
    var factory: ChatContentFactory = DefaultChatContentFactory()
    var replyResolver: ((ReplyInfo) -> ReplyDisplayInfo?)?

    public override init() {
        super.init()
        inset = UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0)
    }

    public override func numberOfItems() -> Int { 1 }

    public override func sizeForItem(at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        let width = ctx.containerSize.width
        let showName = features.senderNameMode != .never
        inset = UIEdgeInsets(top: layout.cellVSpacing / 2, left: 0, bottom: layout.cellVSpacing / 2, right: 0)
        let height = MessageSizeCalculator.cellHeight(
            for: item.message,
            maxWidth: width,
            layout: layout,
            showSenderName: showName,
            features: features,
            factory: factory
        )
        return CGSize(width: width, height: max(height, layout.cellMinHeight))
    }

    public override func cellForItem(at index: Int) -> UICollectionViewCell {
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
        cell.onContentInteraction = { [weak self] interaction in
            guard let self else { return }
            let id = self.item.message.id
            switch interaction {
            case .mediaTap(let i):
                self.sectionDelegate?.messageSectionDidTap(messageId: id, attachmentIndex: i)
            case .fileTap(let i):
                self.sectionDelegate?.messageSectionDidTap(messageId: id, attachmentIndex: i)
            case .pollOptionTap(let pId, let oId):
                self.sectionDelegate?.messageSectionDidTapPollOption(messageId: id, pollId: pId, optionId: oId)
            case .pollDetailTap(let pId):
                self.sectionDelegate?.messageSectionDidTapPollDetail(messageId: id, pollId: pId)
            case .voiceTap(let url):
                self.sectionDelegate?.messageSectionDidTapVoice(messageId: id, url: url)
            }
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
            layout: layout,
            factory: factory
        )

        return cell
    }

    public override func didUpdate(to object: Any) {
        item = object as? MessageListItem
    }

    public override func didSelectItem(at index: Int) {
        sectionDelegate?.messageSectionDidTap(messageId: item.message.id, attachmentIndex: nil)
    }

    // MARK: - Highlight

    func highlightCell() {
        guard let cell = collectionContext?.cellForItem(at: 0, sectionController: self) as? MessageCell else { return }
        cell.playHighlight()
    }
}
