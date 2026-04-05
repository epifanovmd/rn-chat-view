import UIKit

/// Manages keyboard freeze/restore during context menu presentation.
///
/// When a context menu is shown, the collection view's bottom inset is frozen
/// so keyboard dismissal doesn't cause visual jumps. On dismiss, the keyboard
/// is restored if it was previously visible.
final class KeyboardFreezeManager {

    private weak var collectionView: UICollectionView?
    private weak var inputBar: InputBarView?

    private var isFrozen = false
    private var frozenBottomInset: CGFloat?
    private var keyboardWasVisible = false
    private var kbHideObserver: Any?
    private var kbShowObserver: Any?
    private var onThaw: (() -> Void)?

    init(collectionView: UICollectionView?, inputBar: InputBarView?, onThaw: @escaping () -> Void) {
        self.collectionView = collectionView
        self.inputBar = inputBar
        self.onThaw = onThaw
    }

    var isInsetFrozen: Bool { isFrozen }

    // MARK: - Freeze

    func freeze() {
        guard !isFrozen else { return }

        keyboardWasVisible = inputBar?.isKeyboardActive ?? false
        isFrozen = true
        frozenBottomInset = collectionView?.contentInset.bottom

        kbHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { [weak self] note in
            self?.handleKeyboardWillHide(note)
        }
    }

    // MARK: - Restore

    func restore() {
        if let token = kbHideObserver {
            NotificationCenter.default.removeObserver(token)
            kbHideObserver = nil
        }

        let wasVisible = keyboardWasVisible
        keyboardWasVisible = false

        guard isFrozen else { return }

        if wasVisible {
            kbShowObserver = NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardDidShowNotification,
                object: nil, queue: .main
            ) { [weak self] _ in
                if let token = self?.kbShowObserver {
                    NotificationCenter.default.removeObserver(token)
                    self?.kbShowObserver = nil
                }
                self?.thaw()
            }
            inputBar?.activateKeyboard()
        } else {
            thaw()
        }
    }

    // MARK: - Private

    private func handleKeyboardWillHide(_ note: Notification) {
        guard isFrozen, let frozen = frozenBottomInset, let cv = collectionView else { return }
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw) << 16).union(.beginFromCurrentState)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            cv.contentInset.bottom = frozen
            cv.verticalScrollIndicatorInsets.bottom = frozen
        }
    }

    private func thaw() {
        isFrozen = false
        frozenBottomInset = nil
        onThaw?()
    }

    deinit {
        if let token = kbHideObserver { NotificationCenter.default.removeObserver(token) }
        if let token = kbShowObserver { NotificationCenter.default.removeObserver(token) }
    }
}
