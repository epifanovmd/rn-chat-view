import UIKit

// MARK: - Delegate

protocol ChatInputBarDelegate: AnyObject {
    func inputBarDidSend(text: String, replyToId: String?)
    func inputBarDidEdit(text: String, messageId: String)
    func inputBarDidCancelMode(type: String)
    func inputBarDidTapAttachment()
    func inputBarDidStartRecording()
    func inputBarDidStopRecording()
    func inputBarDidCancelRecording()
    func inputBarDidChangeText(_ text: String)
    func inputBarRecordingStateChanged(isRecording: Bool)
}

extension ChatInputBarDelegate {
    func inputBarRecordingStateChanged(isRecording: Bool) {}
}

// MARK: - Input Mode

enum InputBarMode: Equatable {
    case normal
    case reply(messageId: String, senderName: String?, text: String?, hasImage: Bool)
    case edit(messageId: String, text: String)
}

// MARK: - Recording State

enum RecordingState {
    case idle, recording, locked
}

// MARK: - ChatInputBar

final class ChatInputBar: UIView {
    weak var delegate: ChatInputBarDelegate?
    private(set) var mode: InputBarMode = .normal

    // MARK: - Layout

    let inputStack = UIStackView()
    let leftButton = UIButton(type: .system)
    let mainContainer = UIView()
    let mainStack = UIStackView()
    let rightButton = UIButton(type: .system)

    // MARK: - Reply Panel

    let replyPanel = UIView()
    var replyPanelHeight: NSLayoutConstraint!
    let replyAccentBar = UIView()
    let replyIconView = UIImageView()
    let replySenderLabel = UILabel()
    let replyTextLabel = UILabel()
    let replyCancelButton = UIButton(type: .system)
    let replySeparator = UIView()

    // MARK: - Text Area

    let textView = UITextView()
    let placeholderLabel = UILabel()
    var textViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Recording Row

    let recordingRow = UIView()
    let recordDot = UIView()
    let recordTimerLabel = UILabel()
    let slideHintContainer = UIView()
    let slideArrowLabel = UILabel()
    let slideTextLabel = UILabel()

    // MARK: - Floating Views

    let floatingMicButton = UIView()
    let floatingMicIcon = UIImageView()
    let lockContainer = UIView()
    let lockChevron = UIImageView()
    let lockButtonIcon = UIImageView()

    // MARK: - State

    var recordingState: RecordingState = .idle
    var micOriginCenter: CGPoint = .zero
    var gestureStartPoint: CGPoint = .zero
    var lastRecordedDuration: TimeInterval = 0
    var theme: ChatTheme = .light
    let hapticLight = UIImpactFeedbackGenerator(style: .light)
    let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    private func setupLayout() {
        backgroundColor = .clear
        let L = ChatLayout.current

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

        setupFloatingViews()
    }

    // MARK: - Left Button

    private func setupLeftButton() {
        let L = ChatLayout.current
        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        leftButton.setImage(UIImage(systemName: "paperclip", withConfiguration: cfg), for: .normal)
        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.layer.cornerRadius = L.inputButtonSize / 2
        leftButton.layer.borderWidth = L.inputBorderWidth
        NSLayoutConstraint.activate([
            leftButton.widthAnchor.constraint(equalToConstant: L.inputButtonSize),
            leftButton.heightAnchor.constraint(equalToConstant: L.inputButtonSize),
        ])
    }

    // MARK: - Right Button

    private func setupRightButton() {
        let L = ChatLayout.current
        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        rightButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: cfg), for: .normal)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.layer.cornerRadius = L.inputButtonSize / 2
        rightButton.layer.borderWidth = L.inputBorderWidth
        NSLayoutConstraint.activate([
            rightButton.widthAnchor.constraint(equalToConstant: L.inputButtonSize),
            rightButton.heightAnchor.constraint(equalToConstant: L.inputButtonSize),
        ])

        let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleRecordGesture(_:)))
        lp.minimumPressDuration = L.recordMinPressDuration
        rightButton.addGestureRecognizer(lp)
    }

    // MARK: - Main Container

    private func setupMainContainer() {
        let L = ChatLayout.current
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

        setupReplyPanel()
        setupTextView()
        setupRecordingRow()

        mainStack.addArrangedSubview(replyPanel)
        mainStack.addArrangedSubview(textView)
        mainStack.addArrangedSubview(recordingRow)
        recordingRow.isHidden = true
    }

    // MARK: - Reply Panel

    private func setupReplyPanel() {
        let L = ChatLayout.current
        replyPanel.translatesAutoresizingMaskIntoConstraints = false
        replyPanelHeight = replyPanel.heightAnchor.constraint(equalToConstant: 0)
        replyPanelHeight.isActive = true
        replyPanel.clipsToBounds = true

        replyAccentBar.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyAccentBar)

        replyIconView.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyIconView)

        replySenderLabel.font = L.replySenderFont
        replySenderLabel.numberOfLines = 1
        replySenderLabel.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replySenderLabel)

        replyTextLabel.font = L.replyFont
        replyTextLabel.numberOfLines = 1
        replyTextLabel.lineBreakMode = .byTruncatingTail
        replyTextLabel.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyTextLabel)

        let closeCfg = UIImage.SymbolConfiguration(pointSize: L.inputReplyCancelIconSize, weight: .semibold)
        replyCancelButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeCfg), for: .normal)
        replyCancelButton.addTarget(self, action: #selector(cancelModeTapped), for: .touchUpInside)
        replyCancelButton.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyCancelButton)

        replySeparator.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replySeparator)

        let sp = L.inputReplySpacing
        NSLayoutConstraint.activate([
            replyAccentBar.leadingAnchor.constraint(equalTo: replyPanel.leadingAnchor, constant: sp + 2),
            replyAccentBar.topAnchor.constraint(equalTo: replyPanel.topAnchor, constant: sp - 2),
            replyAccentBar.bottomAnchor.constraint(equalTo: replySeparator.topAnchor, constant: -(sp - 4)),
            replyAccentBar.widthAnchor.constraint(equalToConstant: L.replyAccentWidth),
            replyIconView.leadingAnchor.constraint(equalTo: replyAccentBar.trailingAnchor, constant: sp - 2),
            replyIconView.centerYAnchor.constraint(equalTo: replyPanel.centerYAnchor, constant: -1),
            replyIconView.widthAnchor.constraint(equalToConstant: L.inputReplyIconSize + 2),
            replySenderLabel.leadingAnchor.constraint(equalTo: replyIconView.trailingAnchor, constant: sp / 2),
            replySenderLabel.topAnchor.constraint(equalTo: replyPanel.topAnchor, constant: sp - 3),
            replySenderLabel.trailingAnchor.constraint(lessThanOrEqualTo: replyCancelButton.leadingAnchor, constant: -sp / 2),
            replyTextLabel.leadingAnchor.constraint(equalTo: replySenderLabel.leadingAnchor),
            replyTextLabel.topAnchor.constraint(equalTo: replySenderLabel.bottomAnchor, constant: 1),
            replyTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: replyCancelButton.leadingAnchor, constant: -sp / 2),
            replyCancelButton.trailingAnchor.constraint(equalTo: replyPanel.trailingAnchor, constant: -sp + 2),
            replyCancelButton.centerYAnchor.constraint(equalTo: replyPanel.centerYAnchor, constant: -1),
            replyCancelButton.widthAnchor.constraint(equalToConstant: L.inputReplyCancelSize),
            replyCancelButton.heightAnchor.constraint(equalToConstant: L.inputReplyCancelSize),
            replySeparator.leadingAnchor.constraint(equalTo: replyPanel.leadingAnchor, constant: sp),
            replySeparator.trailingAnchor.constraint(equalTo: replyPanel.trailingAnchor, constant: -sp),
            replySeparator.bottomAnchor.constraint(equalTo: replyPanel.bottomAnchor),
            replySeparator.heightAnchor.constraint(equalToConstant: L.inputSeparatorHeight),
        ])
    }

    // MARK: - Text View

    private func setupTextView() {
        let L = ChatLayout.current
        textView.font = L.textViewFont
        textView.isScrollEnabled = false
        textView.textContainerInset = L.textViewInsets
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear

        placeholderLabel.text = "Сообщение"
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

    // MARK: - Recording Row

    private func setupRecordingRow() {
        let L = ChatLayout.current
        recordingRow.translatesAutoresizingMaskIntoConstraints = false

        recordDot.layer.cornerRadius = L.recordDotSize / 2
        recordDot.translatesAutoresizingMaskIntoConstraints = false
        recordingRow.addSubview(recordDot)

        recordTimerLabel.font = L.recordTimerFont
        recordTimerLabel.text = "0:00,00"
        recordTimerLabel.translatesAutoresizingMaskIntoConstraints = false
        recordingRow.addSubview(recordTimerLabel)

        slideHintContainer.translatesAutoresizingMaskIntoConstraints = false
        recordingRow.addSubview(slideHintContainer)

        slideArrowLabel.text = "‹‹‹"
        slideArrowLabel.font = L.recordSlideArrowFont
        slideArrowLabel.translatesAutoresizingMaskIntoConstraints = false
        slideHintContainer.addSubview(slideArrowLabel)

        slideTextLabel.text = "Отмена"
        slideTextLabel.font = L.recordCancelFont
        slideTextLabel.translatesAutoresizingMaskIntoConstraints = false
        slideHintContainer.addSubview(slideTextLabel)

        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(cancelHintTapped))
        slideHintContainer.isUserInteractionEnabled = true
        slideHintContainer.addGestureRecognizer(cancelTap)

        NSLayoutConstraint.activate([
            recordingRow.heightAnchor.constraint(equalToConstant: L.textViewMinHeight),
            recordDot.leadingAnchor.constraint(equalTo: recordingRow.leadingAnchor, constant: L.recordDotLeading),
            recordDot.centerYAnchor.constraint(equalTo: recordingRow.centerYAnchor),
            recordDot.widthAnchor.constraint(equalToConstant: L.recordDotSize),
            recordDot.heightAnchor.constraint(equalToConstant: L.recordDotSize),
            recordTimerLabel.leadingAnchor.constraint(equalTo: recordDot.trailingAnchor, constant: L.recordTimerLeading),
            recordTimerLabel.centerYAnchor.constraint(equalTo: recordingRow.centerYAnchor),
            slideHintContainer.centerXAnchor.constraint(equalTo: recordingRow.centerXAnchor, constant: L.recordSlideHintOffset),
            slideHintContainer.centerYAnchor.constraint(equalTo: recordingRow.centerYAnchor),
            slideArrowLabel.leadingAnchor.constraint(equalTo: slideHintContainer.leadingAnchor),
            slideArrowLabel.centerYAnchor.constraint(equalTo: slideHintContainer.centerYAnchor),
            slideTextLabel.leadingAnchor.constraint(equalTo: slideArrowLabel.trailingAnchor, constant: 4),
            slideTextLabel.trailingAnchor.constraint(equalTo: slideHintContainer.trailingAnchor),
            slideTextLabel.centerYAnchor.constraint(equalTo: slideHintContainer.centerYAnchor),
        ])
    }

    // MARK: - Floating Views

    private func setupFloatingViews() {
        let L = ChatLayout.current

        // Lock container (added first — below floating mic in z-order)
        lockContainer.layer.cornerRadius = L.recordLockContainerSize / 2
        lockContainer.clipsToBounds = true
        lockContainer.translatesAutoresizingMaskIntoConstraints = false
        lockContainer.alpha = 0
        addSubview(lockContainer)

        let chevCfg = UIImage.SymbolConfiguration(pointSize: L.recordLockChevronSize, weight: .bold)
        lockChevron.image = UIImage(systemName: "chevron.up", withConfiguration: chevCfg)
        lockChevron.contentMode = .scaleAspectFit
        lockChevron.translatesAutoresizingMaskIntoConstraints = false
        lockContainer.addSubview(lockChevron)

        let lockCfg = UIImage.SymbolConfiguration(pointSize: L.recordLockButtonIconSize, weight: .bold)
        lockButtonIcon.image = UIImage(systemName: "lock.fill", withConfiguration: lockCfg)
        lockButtonIcon.contentMode = .scaleAspectFit
        lockButtonIcon.translatesAutoresizingMaskIntoConstraints = false
        lockContainer.addSubview(lockButtonIcon)

        NSLayoutConstraint.activate([
            lockContainer.widthAnchor.constraint(equalToConstant: L.recordLockContainerSize),
            lockContainer.heightAnchor.constraint(equalToConstant: L.recordLockContainerSize + 14),
            lockContainer.centerXAnchor.constraint(equalTo: rightButton.centerXAnchor),
            lockContainer.bottomAnchor.constraint(equalTo: rightButton.topAnchor, constant: -L.recordLockBottomMargin),
            lockChevron.centerXAnchor.constraint(equalTo: lockContainer.centerXAnchor),
            lockChevron.topAnchor.constraint(equalTo: lockContainer.topAnchor, constant: L.recordLockChevronTopPad),
            lockButtonIcon.centerXAnchor.constraint(equalTo: lockContainer.centerXAnchor),
            lockButtonIcon.centerYAnchor.constraint(equalTo: lockContainer.centerYAnchor, constant: L.recordLockIconCenterOffset),
        ])

        // Floating mic (added last — on top of everything)
        floatingMicButton.layer.cornerRadius = L.recordFloatingMicSize / 2
        floatingMicButton.translatesAutoresizingMaskIntoConstraints = false
        floatingMicButton.isHidden = true
        floatingMicButton.isUserInteractionEnabled = false
        addSubview(floatingMicButton)

        let micCfg = UIImage.SymbolConfiguration(pointSize: L.recordFloatingMicIconSize, weight: .medium)
        floatingMicIcon.image = UIImage(systemName: "mic.fill", withConfiguration: micCfg)
        floatingMicIcon.tintColor = .white
        floatingMicIcon.contentMode = .scaleAspectFit
        floatingMicIcon.translatesAutoresizingMaskIntoConstraints = false
        floatingMicButton.addSubview(floatingMicIcon)

        NSLayoutConstraint.activate([
            floatingMicButton.widthAnchor.constraint(equalToConstant: L.recordFloatingMicSize),
            floatingMicButton.heightAnchor.constraint(equalToConstant: L.recordFloatingMicSize),
            floatingMicIcon.centerXAnchor.constraint(equalTo: floatingMicButton.centerXAnchor),
            floatingMicIcon.centerYAnchor.constraint(equalTo: floatingMicButton.centerYAnchor),
        ])
    }

    // MARK: - Theme

    func applyTheme(_ theme: ChatTheme) {
        self.theme = theme

        mainContainer.backgroundColor = theme.inputBarTextViewBackground
        mainContainer.layer.borderColor = theme.inputBarBorder.cgColor
        textView.textColor = theme.inputBarText
        textView.tintColor = theme.inputBarTint
        placeholderLabel.textColor = theme.inputBarPlaceholder

        for btn in [leftButton, rightButton] {
            btn.backgroundColor = theme.inputBarTextViewBackground
            btn.layer.borderColor = theme.inputBarBorder.cgColor
            btn.tintColor = theme.inputBarTint
        }

        replyAccentBar.backgroundColor = theme.replyPanelAccent
        replySenderLabel.textColor = theme.replyPanelSender
        replyTextLabel.textColor = theme.replyPanelText
        replyCancelButton.tintColor = theme.replyPanelClose
        replySeparator.backgroundColor = theme.inputBarBorder

        recordDot.backgroundColor = theme.voiceRecordingIndicator
        recordTimerLabel.textColor = theme.inputBarText
        slideArrowLabel.textColor = theme.inputBarPlaceholder
        slideTextLabel.textColor = theme.inputBarPlaceholder

        lockContainer.backgroundColor = theme.voiceRecordingLockBackground
        lockChevron.tintColor = theme.voiceRecordingLockIcon
        lockButtonIcon.tintColor = theme.voiceRecordingLockIcon
        floatingMicButton.backgroundColor = theme.voiceRecordingMicBackground
    }

    // MARK: - Mode Management

    func beginReply(info: ReplyInfo, theme: ChatTheme) {
        let L = ChatLayout.current
        let name = info.senderName ?? "Сообщение"
        let text = info.text ?? (info.hasImage ? "📷 Photo" : "…")
        mode = .reply(messageId: info.replyToId, senderName: name, text: text, hasImage: info.hasImage)

        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputReplyIconSize, weight: .medium)
        replyIconView.image = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: cfg)
        replyIconView.tintColor = theme.replyPanelAccent
        replySenderLabel.text = name
        replyTextLabel.text = text
        showReplyPanel(true)
        textView.becomeFirstResponder()
    }

    func beginEdit(messageId: String, text: String, theme: ChatTheme) {
        let L = ChatLayout.current
        mode = .edit(messageId: messageId, text: text)

        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputReplyIconSize, weight: .medium)
        replyIconView.image = UIImage(systemName: "pencil", withConfiguration: cfg)
        replyIconView.tintColor = theme.replyPanelAccent
        replySenderLabel.text = "Редактирование"
        replyTextLabel.text = text
        textView.text = text
        placeholderLabel.isHidden = true
        updateTextViewHeight()
        updateRightButton()
        showReplyPanel(true)
        textView.becomeFirstResponder()
    }

    func cancelMode() {
        let prev = mode
        mode = .normal
        showReplyPanel(false)
        if case .edit = prev {
            textView.text = ""
            placeholderLabel.isHidden = false
            updateTextViewHeight()
            updateRightButton()
            textView.resignFirstResponder()
        }
    }

    // MARK: - Recording UI (called externally)

    func showRecordingUI(duration: TimeInterval) {
        lastRecordedDuration = duration
        recordTimerLabel.text = formatDuration(duration)
    }

    func hideRecordingUI() {}

    func formatDuration(_ d: TimeInterval) -> String {
        let m = Int(d) / 60, s = Int(d) % 60, ms = Int((d - floor(d)) * 100)
        return String(format: "%d:%02d,%02d", m, s, ms)
    }

    // MARK: - Reply Panel Animation

    func showReplyPanel(_ show: Bool) {
        let h: CGFloat = show ? ChatLayout.current.inputReplyPanelHeight : 0
        if show { replyPanel.alpha = 0 }
        replyPanelHeight.constant = h
        UIView.animate(withDuration: 0.25, delay: 0, options: show ? .curveEaseOut : .curveEaseIn) {
            self.replyPanel.alpha = show ? 1 : 0
            self.layoutIfNeeded()
        }
    }

    // MARK: - Helpers

    func updateTextViewHeight() {
        let L = ChatLayout.current
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let h = min(max(size.height, L.textViewMinHeight), L.textViewMaxHeight)
        textViewHeightConstraint.constant = h
        textView.isScrollEnabled = size.height > L.textViewMaxHeight
    }

    func updateRightButton() {
        let L = ChatLayout.current
        let hasText = !(textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let cfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: hasText ? .semibold : .medium)
        let icon = hasText ? "arrow.up.circle.fill" : "mic.fill"
        rightButton.setImage(UIImage(systemName: icon, withConfiguration: cfg), for: .normal)

        rightButton.gestureRecognizers?.forEach { rightButton.removeGestureRecognizer($0) }
        rightButton.removeTarget(nil, action: nil, for: .touchUpInside)

        if hasText {
            rightButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        } else {
            let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleRecordGesture(_:)))
            lp.minimumPressDuration = L.recordMinPressDuration
            rightButton.addGestureRecognizer(lp)
        }
    }

    func restoreLeftButtonToClip() {
        let cfg = UIImage.SymbolConfiguration(pointSize: ChatLayout.current.inputIconSize, weight: .medium)
        // Shrink trash → swap icon → scale back
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            self.leftButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }) { _ in
            self.leftButton.setImage(UIImage(systemName: "paperclip", withConfiguration: cfg), for: .normal)
            self.leftButton.tintColor = self.theme.inputBarTint
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.leftButton.transform = .identity
            }
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
        cancelMode()
        delegate?.inputBarDidCancelMode(type: type)
    }
}

// MARK: - UITextViewDelegate

extension ChatInputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateTextViewHeight()
        updateRightButton()
        delegate?.inputBarDidChangeText(textView.text ?? "")
    }
}
