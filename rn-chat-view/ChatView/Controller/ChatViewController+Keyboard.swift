import UIKit

// MARK: - KeyboardListenerDelegate (iOS < 15)

extension ChatViewController: KeyboardListenerDelegate {
    func keyboardWillChangeFrame(info: KeyboardInfo) {
        guard #unavailable(iOS 15) else { return }
        guard let window = view.window else { return }

        let kbInView = view.convert(info.frameEnd, from: window.screen.coordinateSpace)
        let kbHeight = max(0, view.bounds.height - kbInView.origin.y)
        let safeBottom = view.safeAreaInsets.bottom
        let newConst = -(max(kbHeight, safeBottom) - safeBottom)

        guard inputBarKeyboardConstraint?.constant != newConst else { return }
        inputBarKeyboardConstraint?.constant = newConst

        let curve = UIView.AnimationOptions(rawValue: UInt(info.animationCurve.rawValue) << 16)
        if info.animationDuration > 0 {
            UIView.animate(withDuration: info.animationDuration, delay: 0,
                           options: [curve, .beginFromCurrentState]) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
}
