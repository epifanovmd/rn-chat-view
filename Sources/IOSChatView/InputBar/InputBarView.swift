import AudioToolbox
import UIKit

// MARK: - InputBarView

public final class InputBarView: UIView {
    public weak var delegate: InputBarDelegate?
    public private(set) var mode: InputBarMode = .normal

    // MARK: - Subviews (internal for +Recording extension)

    let inputStack = UIStackView()
    let leftButton = UIButton(type: .system)
    private let mainContainer = UIView()
    private let mainStack = UIStackView()
    let rightButton = UIButton(type: .system)
    private let replyPanel = InputBarReplyPanel()
    let textView = UITextView()
    private let placeholderLabel = UILabel()
    let internalSendButton = UIButton(type: .system)
    let recordingRow = InputBarRecordingRow()
    let lockView = InputBarLockView()

    // MARK: - State (internal for +Recording extension)

    var recordingState: RecordingState = .idle
    var gestureStartPoint: CGPoint = .zero
    var currentTheme = InputBarTheme.light
    private var textViewHeightConstraint: NSLayoutConstraint!
    private var hasText = false

    /// Layout constants.
    private(set) var layout = ChatLayout()

    /// Voice recorder, owned by InputBar.
    private(set) var voiceRecorder = VoiceRecorder()

    /// Public placeholder text setter.
    public var placeholder: String? {
        get { placeholderLabel.text }
        set { placeholderLabel.text = newValue }
    }

    /// Show/hide attach button.
    public var showAttachButton: Bool = true {
        didSet { leftButton.isHidden = !showAttachButton }
    }

    /// Enable voice recording. If false — mic button hidden, only send shown.
    public var voiceRecordingEnabled: Bool = true {
        didSet {
            guard oldValue != voiceRecordingEnabled else { return }
            if voiceRecordingEnabled {
                resetRightButtonToMic()
                updateRightButton()
            } else {
                rightButton.isHidden = true
                internalSendButton.alpha = 1
                internalSendButton.transform = .identity
            }
        }
    }

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    public required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public API

    public func applyLayout(_ newLayout: ChatLayout) {
        layout = newLayout
    }

    public func applyTheme(_ theme: InputBarTheme) {
        currentTheme = theme

        mainContainer.backgroundColor = theme.background
        mainContainer.layer.borderColor = theme.border.cgColor
        textView.textColor = theme.text
        textView.tintColor = theme.tint
        placeholderLabel.textColor = theme.placeholder

        for btn in [leftButton, rightButton] {
            btn.backgroundColor = theme.background
            btn.layer.borderColor = theme.border.cgColor
            btn.tintColor = theme.tint
        }

        internalSendButton.backgroundColor = theme.recordingMicFill

        replyPanel.applyTheme(theme)
        recordingRow.applyTheme(theme)
        lockView.applyTheme(theme)
    }

    /// Clear input text and reset mode.
    public func clearInput() {
        cancelMode()
        textView.text = ""
        placeholderLabel.isHidden = false
        updateTextViewHeight()
        updateRightButton()
    }

    /// Dismiss the keyboard.
    public func dismissKeyboard() {
        textView.resignFirstResponder()
    }

    /// Whether the keyboard is currently shown for this input bar.
    public var isKeyboardActive: Bool {
        textView.isFirstResponder
    }

    /// Focus the text view.
    public func activateKeyboard() {
        textView.becomeFirstResponder()
    }

    // MARK: - Mode Management

    public func beginReply(info: InputBarReplyInfo) {
        let L = layout
        let name = info.senderName ?? "Сообщение"
        let text = info.text ?? (info.hasImage ? "📷 Photo" : "…")
        mode = .reply(messageId: info.messageId, senderName: name, text: text, hasImage: info.hasImage)

        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputReplyIconSize, weight: .medium)
        replyPanel.iconView.image = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: cfg)
        replyPanel.iconView.tintColor = currentTheme.replyAccent
        replyPanel.senderLabel.text = name
        replyPanel.textLabel.text = text
        replyPanel.show(in: self, height: L.inputReplyPanelHeight)
        textView.becomeFirstResponder()
    }

    public func beginEdit(messageId: String, text: String) {
        let L = layout
        mode = .edit(messageId: messageId, text: text)

        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputReplyIconSize, weight: .medium)
        replyPanel.iconView.image = UIImage(systemName: "pencil", withConfiguration: cfg)
        replyPanel.iconView.tintColor = currentTheme.replyAccent
        replyPanel.senderLabel.text = "Редактирование"
        replyPanel.textLabel.text = text
        textView.text = text
        placeholderLabel.isHidden = true
        updateRightButton()
        replyPanel.show(in: self, height: L.inputReplyPanelHeight)
        // Программная установка текста не вызывает textViewDidChange — уведомляем вручную
        delegate?.inputBarDidChangeText(text)
        textView.becomeFirstResponder()
        // Пересчёт высоты после layout — textView.bounds.width может быть неактуальной до layout pass
        DispatchQueue.main.async { [weak self] in
            self?.updateTextViewHeight()
        }
    }

    public func cancelMode(dismissKeyboard: Bool = false) {
        let prev = mode
        mode = .normal
        replyPanel.hide(in: self)
        if case .edit = prev {
            textView.text = ""
            placeholderLabel.isHidden = false
            updateTextViewHeight()
            updateRightButton()
            if dismissKeyboard { textView.resignFirstResponder() }
        }
    }

    // MARK: - Recording UI

    func showRecordingUI(duration: TimeInterval) {
        let m = Int(duration) / 60, s = Int(duration) % 60, ms = Int((duration - floor(duration)) * 100)
        recordingRow.timerLabel.text = String(format: "%d:%02d,%02d", m, s, ms)
    }

    // MARK: - Setup

    private func setupLayout() {
        backgroundColor = .clear
        let L = layout

        inputStack.axis = .horizontal
        inputStack.alignment = .bottom
        inputStack.spacing = L.inputStackSpacing
        inputStack.translatesAutoresizingMaskIntoConstraints = false
        inputStack.layoutMargins = UIEdgeInsets(top: L.inputBarVPad, left: L.inputBarHPad,
                                                 bottom: L.inputBarVPad, right: L.inputBarHPad)
        inputStack.isLayoutMarginsRelativeArrangement = true
        addSubview(inputStack)

        NSLayoutConstraint.activate([
            inputStack.topAnchor.constraint(equalTo: topAnchor),
            inputStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            inputStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            inputStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        setupLeftButton()
        setupMainContainer()
        setupRightButton()

        inputStack.addArrangedSubview(leftButton)
        inputStack.addArrangedSubview(mainContainer)
        inputStack.addArrangedSubview(rightButton)

        setupLockView()
        voiceRecorder.delegate = self
        warmUpKeyboard()
    }

    /// Pre-load keyboard to avoid delay on first focus.
    private func warmUpKeyboard() {
        let field = UITextField(frame: .zero)
        addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
    }

    private func setupLeftButton() {
        let L = layout
        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        leftButton.setImage(UIImage(systemName: "paperclip", withConfiguration: cfg), for: .normal)
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.layer.cornerRadius = L.inputButtonSize / 2
        leftButton.layer.borderWidth = L.inputBorderWidth
        let lw = leftButton.widthAnchor.constraint(equalToConstant: L.inputButtonSize)
        let lh = leftButton.heightAnchor.constraint(equalToConstant: L.inputButtonSize)
        lw.priority = .defaultHigh
        lh.priority = .defaultHigh
        NSLayoutConstraint.activate([lw, lh])
    }

    private func setupRightButton() {
        let L = layout
        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        rightButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: cfg), for: .normal)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.layer.cornerRadius = L.inputButtonSize / 2
        rightButton.layer.borderWidth = L.inputBorderWidth
        let rw = rightButton.widthAnchor.constraint(equalToConstant: L.inputButtonSize)
        let rh = rightButton.heightAnchor.constraint(equalToConstant: L.inputButtonSize)
        rw.priority = .defaultHigh
        rh.priority = .defaultHigh
        NSLayoutConstraint.activate([rw, rh])

        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleRecordGesture(_:)))
        lp.minimumPressDuration = L.recordMinPressDuration
        rightButton.addGestureRecognizer(lp)
    }

    private func setupMainContainer() {
        let L = layout
        mainContainer.layer.cornerRadius = L.textViewCornerRadius
        mainContainer.layer.borderWidth = L.inputBorderWidth
        mainContainer.clipsToBounds = true
        mainContainer.translatesAutoresizingMaskIntoConstraints = false

        mainStack.axis = .vertical
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: mainContainer.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: mainContainer.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor),
        ])

        setupTextView()
        setupInternalSendButton()

        mainStack.addArrangedSubview(replyPanel)
        mainStack.addArrangedSubview(textView)
        mainStack.addArrangedSubview(recordingRow)
        recordingRow.isHidden = true

        replyPanel.closeButton.addTarget(self, action: #selector(cancelModeTapped), for: .touchUpInside)
        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(cancelHintTapped))
        recordingRow.slideContainer.isUserInteractionEnabled = true
        recordingRow.slideContainer.addGestureRecognizer(cancelTap)
    }

    private func setupTextView() {
        let L = layout
        textView.font = L.textViewFont
        textView.isScrollEnabled = false
        textView.textContainerInset = L.textViewInsets
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear

        placeholderLabel.text = L.inputPlaceholderText
        placeholderLabel.font = L.textViewFont
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(placeholderLabel)

        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: L.textViewMinHeight)
        textViewHeightConstraint.priority = .defaultHigh
        textViewHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: L.inputPlaceholderLeading),
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
        ])
    }

    private func setupInternalSendButton() {
        let L = layout
        let size = L.textViewMinHeight - L.inputSendButtonInset * 2
        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputSendButtonIconSize, weight: .semibold)
        internalSendButton.setImage(UIImage(systemName: "arrow.up", withConfiguration: cfg), for: .normal)
        internalSendButton.tintColor = .white
        internalSendButton.layer.cornerRadius = size / 2
        internalSendButton.translatesAutoresizingMaskIntoConstraints = false
        internalSendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        internalSendButton.alpha = 0
        internalSendButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        mainContainer.addSubview(internalSendButton)

        let sw = internalSendButton.widthAnchor.constraint(equalToConstant: size)
        let sh = internalSendButton.heightAnchor.constraint(equalToConstant: size)
        sw.priority = .defaultHigh
        sh.priority = .defaultHigh
        NSLayoutConstraint.activate([
            sw, sh,
            internalSendButton.trailingAnchor.constraint(equalTo: mainContainer.trailingAnchor, constant: -L.inputSendButtonInset),
            internalSendButton.bottomAnchor.constraint(equalTo: mainContainer.bottomAnchor, constant: -L.inputSendButtonInset),
        ])
    }

    private func setupLockView() {
        addSubview(lockView)
        NSLayoutConstraint.activate([
            lockView.centerXAnchor.constraint(equalTo: rightButton.centerXAnchor),
            lockView.bottomAnchor.constraint(equalTo: rightButton.topAnchor, constant: -layout.recordLockBottomMargin),
        ])
    }

    // MARK: - Helpers

    func updateTextViewHeight() {
        let L = layout
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let h = min(max(size.height, L.textViewMinHeight), L.textViewMaxHeight)
        textViewHeightConstraint.constant = h
        textView.isScrollEnabled = size.height > L.textViewMaxHeight
    }

    func updateRightButton() {
        guard voiceRecordingEnabled else { return }

        let newHasText = !(textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard newHasText != hasText else { return }
        hasText = newHasText

        if hasText {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                self.rightButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.rightButton.alpha = 0
                self.rightButton.isHidden = true
                self.inputStack.layoutIfNeeded()
            }
            UIView.animate(withDuration: 0.25, delay: 0.05, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.internalSendButton.alpha = 1
                self.internalSendButton.transform = .identity
            }
        } else {
            UIView.animate(withDuration: 0.15) {
                self.internalSendButton.alpha = 0
                self.internalSendButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }
            UIView.animate(withDuration: 0.25, delay: 0.05, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8) {
                self.rightButton.isHidden = false
                self.rightButton.transform = .identity
                self.rightButton.alpha = 1
                self.inputStack.layoutIfNeeded()
            }
        }
    }

    func resetRightButtonToMic() {
        let L = layout
        hasText = false
        internalSendButton.alpha = 0
        internalSendButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        rightButton.isHidden = false
        rightButton.transform = .identity
        rightButton.alpha = 1

        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        rightButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: cfg), for: .normal)
        rightButton.gestureRecognizers?.forEach { rightButton.removeGestureRecognizer($0) }
        rightButton.removeTarget(nil, action: nil, for: .touchUpInside)
        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleRecordGesture(_:)))
        lp.minimumPressDuration = L.recordMinPressDuration
        rightButton.addGestureRecognizer(lp)
    }

    func restoreLeftButtonToClip() {
        guard showAttachButton else {
            leftButton.isHidden = true
            return
        }
        let cfg = UIImage.SymbolConfiguration(pointSize: layout.inputIconSize, weight: .medium)
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            self.leftButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }) { _ in
            self.leftButton.setImage(UIImage(systemName: "paperclip", withConfiguration: cfg), for: .normal)
            self.leftButton.tintColor = self.currentTheme.tint
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.leftButton.transform = .identity
            }
        }
    }

    // MARK: - Haptic

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:  AudioServicesPlaySystemSound(1519)
        case .medium: AudioServicesPlaySystemSound(1520)
        case .heavy:  AudioServicesPlaySystemSound(1521)
        @unknown default: AudioServicesPlaySystemSound(1520)
        }
    }

    // MARK: - Actions

    @objc func leftButtonTapped() {
        switch recordingState {
        case .locked: performCancel()
        case .idle:   delegate?.inputBarDidTapAttachment()
        default:      break
        }
    }

    @objc func sendTapped() {
        let text = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        switch mode {
        case .normal:                  delegate?.inputBarDidSend(text: text, replyToId: nil)
        case .reply(let id, _, _, _):  delegate?.inputBarDidSend(text: text, replyToId: id)
        case .edit(let id, _):         delegate?.inputBarDidEdit(text: text, messageId: id)
        }

        textView.text = ""
        placeholderLabel.isHidden = false
        updateTextViewHeight()
        hasText = true
        updateRightButton()
        if mode != .normal { cancelMode() }
    }

    @objc private func cancelModeTapped() {
        let type: String
        switch mode {
        case .reply: type = "reply"
        case .edit:  type = "edit"
        default:     type = "none"
        }
        cancelMode(dismissKeyboard: true)
        delegate?.inputBarDidCancelMode(type: type)
    }
}

// MARK: - UITextViewDelegate

extension InputBarView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateTextViewHeight()
        updateRightButton()
        delegate?.inputBarDidChangeText(textView.text ?? "")
    }
}

// MARK: - VoiceRecorderDelegate

extension InputBarView: VoiceRecorderDelegate {
    public func voiceRecorderDidStart() {
        showRecordingUI(duration: 0)
    }

    public func voiceRecorderDidStop(fileURL: URL, duration: TimeInterval, waveform: [Float]) {
        delegate?.inputBarDidCompleteVoiceRecording(fileURL: fileURL, duration: duration, waveform: waveform)
    }

    public func voiceRecorderDidCancel() {}
    public func voiceRecorderDidFail(error: Error) {}

    public func voiceRecorderDidUpdateDuration(_ duration: TimeInterval) {
        showRecordingUI(duration: duration)
    }

    public func voiceRecorderDidUpdateLevel(_ level: Float) {}
}
