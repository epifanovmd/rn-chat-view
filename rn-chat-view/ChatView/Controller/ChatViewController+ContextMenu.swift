import UIKit

// MARK: - Context Menu Presentation

extension ChatViewController {
    func showContextMenu(for msg: ChatMessage, from cell: UICollectionViewCell) {
        guard let messageCell = cell as? MessageCell else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        freezeCollectionBottomInset()
        inputBar.textView.resignFirstResponder()

        let config = ContextMenuConfiguration(
            id: msg.id,
            sourceView: messageCell.bubbleView,
            emojis: contextMenuEmojis,
            actions: msg.actions.map {
                ContextMenuAction(id: $0.id, title: $0.title,
                                  systemImage: $0.systemImage, isDestructive: $0.isDestructive)
            },
            snapshotCornerRadius: ChatLayout.current.bubbleCornerRadius
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

// MARK: - ContextMenuDelegate

extension ChatViewController: ContextMenuDelegate {
    func contextMenu(_ menu: ContextMenuViewController, didSelectEmoji emoji: String, forId id: String) {
        menu.dismissMenu()
        restoreCollectionBottomInset()
        delegate?.chatDidSelectEmojiReaction(emoji: emoji, messageId: id)
    }

    func contextMenu(_ menu: ContextMenuViewController, didSelectAction action: ContextMenuAction, forId id: String) {
        menu.dismissMenu()
        restoreCollectionBottomInset()
        delegate?.chatDidSelectAction(actionId: action.id, messageId: id)
    }

    func contextMenuDidDismiss(_ menu: ContextMenuViewController, id: String) {
        restoreCollectionBottomInset()
    }
}

// MARK: - Keyboard Freeze / Restore

extension ChatViewController {

    /// Фиксирует текущий bottomInset. Вызвать СИНХРОННО до resignFirstResponder.
    func freezeCollectionBottomInset() {
        guard !isInsetFrozen else { return }

        keyboardWasVisible = inputBar.textView.isFirstResponder
        isInsetFrozen = true
        frozenBottomInset = collectionView.contentInset.bottom

        kbHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            self?.handleKeyboardWillHide(note)
        }
    }

    /// Восстанавливает нормальное поведение inset после закрытия меню.
    func restoreCollectionBottomInset() {
        if let token = kbHideObserver {
            NotificationCenter.default.removeObserver(token)
            kbHideObserver = nil
        }

        let wasVisible = keyboardWasVisible
        keyboardWasVisible = false

        guard isInsetFrozen else { return }

        if wasVisible {
            kbShowObserver = NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardDidShowNotification,
                object: nil, queue: .main
            ) { [weak self] _ in
                if let token = self?.kbShowObserver {
                    NotificationCenter.default.removeObserver(token)
                    self?.kbShowObserver = nil
                }
                self?.thawInset()
            }
            inputBar.textView.becomeFirstResponder()
        } else {
            thawInset()
        }
    }

    private func handleKeyboardWillHide(_ note: Notification) {
        guard isInsetFrozen, let frozen = frozenBottomInset else { return }
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw) << 16).union(.beginFromCurrentState)
        UIView.animate(withDuration: duration, delay: 0, options: options) { [weak self] in
            guard let self else { return }
            self.collectionView.contentInset.bottom = frozen
            self.collectionView.verticalScrollIndicatorInsets.bottom = frozen
        }
    }

    private func thawInset() {
        isInsetFrozen = false
        frozenBottomInset = nil
        updateCollectionInsets()
    }
}
