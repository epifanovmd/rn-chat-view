import UIKit

// MARK: - KeyboardInfo

struct KeyboardInfo {
    let frameBegin: CGRect
    let frameEnd: CGRect
    let animationDuration: Double
    let animationCurve: UIView.AnimationCurve
    let isLocal: Bool

    init?(notification: Notification) {
        guard let info = notification.userInfo else { return nil }
        frameBegin = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        frameEnd = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        animationDuration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) ?? 7
        animationCurve = UIView.AnimationCurve(rawValue: curveRaw) ?? .easeInOut
        isLocal = (info[UIResponder.keyboardIsLocalUserInfoKey] as? Bool) ?? true
    }
}

// MARK: - KeyboardListenerDelegate

protocol KeyboardListenerDelegate: AnyObject {
    func keyboardWillShow(info: KeyboardInfo)
    func keyboardDidShow(info: KeyboardInfo)
    func keyboardWillHide(info: KeyboardInfo)
    func keyboardDidHide(info: KeyboardInfo)
    func keyboardWillChangeFrame(info: KeyboardInfo)
    func keyboardDidChangeFrame(info: KeyboardInfo)
}

extension KeyboardListenerDelegate {
    func keyboardWillShow(info: KeyboardInfo) {}
    func keyboardDidShow(info: KeyboardInfo) {}
    func keyboardWillHide(info: KeyboardInfo) {}
    func keyboardDidHide(info: KeyboardInfo) {}
    func keyboardWillChangeFrame(info: KeyboardInfo) {}
    func keyboardDidChangeFrame(info: KeyboardInfo) {}
}

// MARK: - KeyboardListener

final class KeyboardListener {
    static let shared = KeyboardListener()

    private(set) var isKeyboardVisible = false
    private(set) var keyboardRect: CGRect?
    private var delegates = NSHashTable<AnyObject>.weakObjects()

    private init() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(onWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(onDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(onWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(onDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        nc.addObserver(self, selector: #selector(onWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        nc.addObserver(self, selector: #selector(onDidChange), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }

    func add(delegate: KeyboardListenerDelegate) { delegates.add(delegate) }
    func remove(delegate: KeyboardListenerDelegate) { delegates.remove(delegate) }

    @objc private func onWillShow(_ n: Notification) {
        guard let info = KeyboardInfo(notification: n) else { return }
        keyboardRect = info.frameEnd
        allDelegates.forEach { $0.keyboardWillShow(info: info) }
    }

    @objc private func onDidShow(_ n: Notification) {
        guard let info = KeyboardInfo(notification: n) else { return }
        isKeyboardVisible = true
        keyboardRect = info.frameEnd
        allDelegates.forEach { $0.keyboardDidShow(info: info) }
    }

    @objc private func onWillHide(_ n: Notification) {
        guard let info = KeyboardInfo(notification: n) else { return }
        allDelegates.forEach { $0.keyboardWillHide(info: info) }
    }

    @objc private func onDidHide(_ n: Notification) {
        guard let info = KeyboardInfo(notification: n) else { return }
        isKeyboardVisible = false
        keyboardRect = nil
        allDelegates.forEach { $0.keyboardDidHide(info: info) }
    }

    @objc private func onWillChange(_ n: Notification) {
        guard let info = KeyboardInfo(notification: n) else { return }
        keyboardRect = info.frameEnd
        allDelegates.forEach { $0.keyboardWillChangeFrame(info: info) }
    }

    @objc private func onDidChange(_ n: Notification) {
        guard let info = KeyboardInfo(notification: n) else { return }
        keyboardRect = info.frameEnd
        allDelegates.forEach { $0.keyboardDidChangeFrame(info: info) }
    }

    private var allDelegates: [KeyboardListenerDelegate] {
        delegates.allObjects.compactMap { $0 as? KeyboardListenerDelegate }
    }
}
