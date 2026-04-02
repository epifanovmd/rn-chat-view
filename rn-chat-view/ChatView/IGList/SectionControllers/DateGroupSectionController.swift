import IGListKit
import UIKit

protocol DateGroupSectionDelegate: AnyObject {
    func sectionDidTapMessage(id: String)
    func sectionDidLongPressMessage(id: String, cell: UICollectionViewCell)
    func sectionDidTapReply(messageId: String)
    func sectionDidTapVideo(messageId: String, url: String)
    func sectionDidTapFile(messageId: String, url: String, name: String)
    func sectionDidTapPollOption(messageId: String, pollId: String, optionId: String)
    func sectionDidTapPollDetail(messageId: String, pollId: String)
    func sectionDidTapVoice(messageId: String, url: String)
    func sectionDidTapReaction(messageId: String, emoji: String)
    func resolveReply(for info: ReplyInfo) -> ReplyDisplayInfo?
    var currentTheme: ChatTheme { get }
    var showSenderName: Bool { get }
}

final class DateGroupSectionController: ListBindingSectionController<DateGroupListItem>,
                                         ListBindingSectionControllerDataSource,
                                         ListSupplementaryViewSource {

    weak var sectionDelegate: DateGroupSectionDelegate?

    override init() {
        super.init()
        dataSource = self
        supplementaryViewSource = self
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        minimumLineSpacing = ChatLayout.current.cellVSpacing
    }

    // MARK: - ListBindingSectionControllerDataSource

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        viewModelsFor object: Any
    ) -> [ListDiffable] {
        guard let group = object as? DateGroupListItem else { return [] }
        return group.messages.map { MessageViewModel(message: $0) }
    }

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        cellForViewModel viewModel: Any,
        at index: Int
    ) -> UICollectionViewCell & ListBindable {
        guard let ctx = collectionContext,
              let vm = viewModel as? MessageViewModel else { fatalError() }
        let cell = ctx.dequeueReusableCell(of: MessageCell.self, for: self, at: index) as! MessageCell
        let msg = vm.message

        // Binding context — used by bindViewModel
        cell.bindTheme = sectionDelegate?.currentTheme ?? .light
        cell.bindMaxWidth = ctx.containerSize.width
        cell.bindShowSenderName = sectionDelegate?.showSenderName ?? false
        cell.bindResolveReply = { [weak self] info in self?.sectionDelegate?.resolveReply(for: info) }

        // Callbacks
        cell.onTap = { [weak self] in
            self?.sectionDelegate?.sectionDidTapMessage(id: msg.id)
        }
        cell.onLongPress = { [weak self] c in
            self?.sectionDelegate?.sectionDidLongPressMessage(id: msg.id, cell: c)
        }
        cell.onReplyTap = { [weak self] in
            guard let replyTo = msg.reply?.replyToId else { return }
            self?.sectionDelegate?.sectionDidTapReply(messageId: replyTo)
        }
        cell.onVideoTap = { [weak self] url in
            self?.sectionDelegate?.sectionDidTapVideo(messageId: msg.id, url: url)
        }
        cell.onFileTap = { [weak self] url, name in
            self?.sectionDelegate?.sectionDidTapFile(messageId: msg.id, url: url, name: name)
        }
        cell.onPollOptionTap = { [weak self] pollId, optionId in
            self?.sectionDelegate?.sectionDidTapPollOption(messageId: msg.id, pollId: pollId, optionId: optionId)
        }
        cell.onPollDetailTap = { [weak self] pollId in
            self?.sectionDelegate?.sectionDidTapPollDetail(messageId: msg.id, pollId: pollId)
        }
        cell.onVoiceTap = { [weak self] url in
            self?.sectionDelegate?.sectionDidTapVoice(messageId: msg.id, url: url)
        }
        cell.onReactionTap = { [weak self] emoji in
            self?.sectionDelegate?.sectionDidTapReaction(messageId: msg.id, emoji: emoji)
        }

        return cell
    }

    func sectionController(
        _ sectionController: ListBindingSectionController<ListDiffable>,
        sizeForViewModel viewModel: Any,
        at index: Int
    ) -> CGSize {
        guard let ctx = collectionContext,
              let vm = viewModel as? MessageViewModel else { return .zero }
        let width = ctx.containerSize.width
        let showName = sectionDelegate?.showSenderName ?? false
        let height = MessageSizeCalculator.cellHeight(
            for: vm.message,
            maxWidth: width,
            resolvedReply: vm.message.reply.flatMap { sectionDelegate?.resolveReply(for: $0) },
            showSenderName: showName
        )
        return CGSize(width: width, height: max(height, ChatLayout.current.cellMinHeight))
    }

    // MARK: - ListSupplementaryViewSource

    func supportedElementKinds() -> [String] {
        [DateSeparatorHeaderView.kind]
    }

    func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        guard let ctx = collectionContext else { fatalError() }
        let header = ctx.dequeueReusableSupplementaryView(
            ofKind: DateSeparatorHeaderView.kind,
            for: self,
            class: DateSeparatorHeaderView.self,
            at: index
        ) as! DateSeparatorHeaderView
        let theme = sectionDelegate?.currentTheme ?? .light
        header.configure(title: object?.dateTitle ?? "", theme: theme)
        return header
    }

    func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
        guard let ctx = collectionContext else { return .zero }
        let h = ChatLayout.current.dateSeparatorFont.lineHeight + ChatLayout.current.dateSeparatorVPad * 2 + ChatLayout.current.sectionSpacing * 2
        return CGSize(width: ctx.containerSize.width, height: h)
    }

    // MARK: - Selection

    override func didSelectItem(at index: Int) {
        guard let vm = viewModels[index] as? MessageViewModel else { return }
        sectionDelegate?.sectionDidTapMessage(id: vm.message.id)
    }

    // MARK: - Highlight

    func highlightMessage(at itemIndex: Int) {
        guard let cell = collectionContext?.cellForItem(at: itemIndex, sectionController: self) as? MessageCell else { return }
        cell.playHighlight()
    }
}
