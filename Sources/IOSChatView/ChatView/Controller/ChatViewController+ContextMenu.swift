import UIKit

// MARK: - Показ контекстного меню

extension ChatViewController {
    public func showContextMenu(for msg: ChatMessage, from cell: UICollectionViewCell) {
        guard let messageCell = cell as? MessageCell else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        keyboardFreezeManager.freeze()
        inputBar.dismissKeyboard()

        let config = ContextMenuConfiguration(
            id: msg.id,
            sourceView: messageCell.bubbleView,
            emojis: features.emojiReactions.map { ContextMenuEmoji(emoji: $0) },
            actions: msg.actions.map {
                ContextMenuAction(id: $0.id, title: $0.title,
                                  systemImage: $0.systemImage, isDestructive: $0.isDestructive)
            },
            snapshotCornerRadius: layout.bubbleCornerRadius
        )

        let menuTheme: ContextMenuTheme = theme.isDark ? .dark : .light

        ContextMenuViewController.present(
            configuration: config,
            theme: menuTheme,
            from: self,
            delegate: self
        )
    }
}

// MARK: - Делегат контекстного меню

extension ChatViewController: ContextMenuDelegate {
    public func contextMenu(_ menu: ContextMenuViewController, didSelectEmoji emoji: String, forId id: String) {
        menu.dismissMenu()
        keyboardFreezeManager.restore()
        delegate?.chatDidSelectEmojiReaction(emoji: emoji, messageId: id)
    }

    public func contextMenu(_ menu: ContextMenuViewController, didSelectAction action: ContextMenuAction, forId id: String) {
        menu.dismissMenu()
        keyboardFreezeManager.restore()
        delegate?.chatDidSelectAction(actionId: action.id, messageId: id)
    }

    public func contextMenuDidDismiss(_ menu: ContextMenuViewController, id: String) {
        keyboardFreezeManager.restore()
    }
}
