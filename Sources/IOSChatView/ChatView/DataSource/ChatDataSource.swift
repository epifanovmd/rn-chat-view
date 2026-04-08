import UIKit

/// Standard UICollectionViewDataSource backed by a flat [ChatRow] array.
/// Cell configuration via registered cell classes — no DiffableDataSource needed.
final class ChatDataSource: NSObject, UICollectionViewDataSource {

    private weak var controller: ChatViewController?

    init(controller: ChatViewController) {
        self.controller = controller
        super.init()
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return controller?.rows.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let vc = controller, indexPath.item < vc.rows.count else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: MessageCell.reuseID, for: indexPath)
        }

        let row = vc.rows[indexPath.item]

        switch row {
        case .message(let msg):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MessageCell.reuseID, for: indexPath) as! MessageCell
            configureMessageCell(cell, message: msg, vc: vc)
            return cell

        case .dateSeparator(let groupDate):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateSeparatorCell.reuseID, for: indexPath) as! DateSeparatorCell
            let title = DateHelper.shared.sectionTitle(from: groupDate)
            let view = vc.contentFactory.dateSeparatorView(title: title, theme: vc.theme, layout: vc.layout)
            cell.configure(view: view)
            return cell

        case .loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingCell.reuseID, for: indexPath) as! LoadingCell
            cell.configure(factory: vc.contentFactory, theme: vc.theme, layout: vc.layout)
            return cell
        }
    }

    // MARK: - In-Place Reconfiguration

    /// Reconfigures a visible message cell without dequeue, preserving the view hierarchy.
    func reconfigureMessageCellInPlace(_ cell: MessageCell, message msg: ChatMessage, vc: ChatViewController) {
        setupCallbacks(cell, message: msg, vc: vc)

        let reply = resolveReply(for: msg, vc: vc)
        let showName = Self.shouldShowSenderName(for: msg, mode: vc.features.senderNameMode)

        cell.reconfigureInPlace(
            message: msg,
            resolvedReply: reply,
            theme: vc.theme,
            maxWidth: vc.collectionView.bounds.width,
            showSenderName: showName,
            features: vc.features,
            layout: vc.layout,
            factory: vc.contentFactory
        )
    }

    // MARK: - Message Cell Configuration

    private func configureMessageCell(_ cell: MessageCell, message msg: ChatMessage, vc: ChatViewController) {
        setupCallbacks(cell, message: msg, vc: vc)

        let reply = resolveReply(for: msg, vc: vc)
        let showName = Self.shouldShowSenderName(for: msg, mode: vc.features.senderNameMode)

        cell.configure(
            message: msg,
            resolvedReply: reply,
            theme: vc.theme,
            maxWidth: vc.collectionView.bounds.width,
            showSenderName: showName,
            features: vc.features,
            layout: vc.layout,
            factory: vc.contentFactory
        )
    }

    // MARK: - Shared Helpers

    private func setupCallbacks(_ cell: MessageCell, message msg: ChatMessage, vc: ChatViewController) {
        cell.onTap = { [weak vc] in
            vc?.messageSectionDidTap(messageId: msg.id, attachmentIndex: nil)
        }
        cell.onLongPress = { [weak vc] c in
            vc?.messageSectionDidLongPress(messageId: msg.id, cell: c)
        }
        cell.onReplyTap = { [weak vc] in
            guard let replyTo = msg.reply?.replyToId else { return }
            vc?.messageSectionDidTapReply(messageId: replyTo)
        }
        cell.onContentInteraction = { [weak vc] interaction in
            vc?.messageSectionDidContentInteraction(messageId: msg.id, interaction: interaction)
        }
        cell.onReactionTap = { [weak vc] emoji in
            vc?.messageSectionDidTapReaction(messageId: msg.id, emoji: emoji)
        }
        cell.onThreadTap = { [weak vc] in
            guard let thread = msg.thread else { return }
            vc?.messageSectionDidTapThread(messageId: msg.id, threadId: thread.threadId)
        }
    }

    static func shouldShowSenderName(for msg: ChatMessage, mode: ChatFeatures.SenderNameMode) -> Bool {
        switch mode {
        case .never: return false
        case .incomingOnly: return msg.ownership == .theirs && msg.senderName != nil
        case .always: return (msg.ownership == .mine || msg.ownership == .theirs) && msg.senderName != nil
        }
    }

    private func resolveReply(for msg: ChatMessage, vc: ChatViewController) -> ReplyDisplayInfo? {
        msg.reply.flatMap { info -> ReplyDisplayInfo? in
            guard let original = vc.messageIndex[info.replyToId] else { return nil }
            return ReplyDisplayInfo(
                senderName: original.senderName ?? "Неизвестный",
                text: original.content.text ?? "",
                hasImage: original.content.content != nil
            )
        }
    }
}
