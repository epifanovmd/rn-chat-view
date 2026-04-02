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
}

// MARK: - Input Mode

enum InputBarMode: Equatable {
    case normal
    case reply(messageId: String, senderName: String?, text: String?, hasImage: Bool)
    case edit(messageId: String, text: String)
}

// MARK: - ChatInputBar

final class ChatInputBar: UIView {
    weak var delegate: ChatInputBarDelegate?

    private(set) var mode: InputBarMode = .normal

    // MARK: - Subviews

    private let separator = UIView()
    private let containerStack = UIStackView()
    private let replyPanel = UIView()
    private let replyAccentBar = UIView()
    private let replyIconView = UIImageView()
    private let replySenderLabel = UILabel()
    private let replyTextLabel = UILabel()
    private let replyCancelButton = UIButton(type: .system)
    private let inputStack = UIStackView()
    private let attachButton = UIButton(type: .system)
    private let textViewContainer = UIView()
    let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private let recordButton = UIButton(type: .system)

    // Recording overlay
    private let recordingOverlay = UIView()
    private let recordDot = UIView()
    private let recordTimerLabel = UILabel()
    private let recordCancelLabel = UILabel()
    private let recordStopButton = UIButton(type: .system)

    private var textViewHeightConstraint: NSLayoutConstraint!
    private var replyPanelHeight: NSLayoutConstraint!
    private var theme: ChatTheme = .light
    private var isRecording = false

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear

        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        containerStack.axis = .vertical
        containerStack.spacing = 0
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStack)

        setupReplyPanel()
        setupInputRow()
        setupRecordingOverlay()

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            containerStack.topAnchor.constraint(equalTo: separator.bottomAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Reply Panel

    private func setupReplyPanel() {
        replyPanel.translatesAutoresizingMaskIntoConstraints = false
        replyPanelHeight = replyPanel.heightAnchor.constraint(equalToConstant: 0)
        replyPanelHeight.isActive = true
        replyPanel.clipsToBounds = true

        replyAccentBar.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyAccentBar)

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        replyIconView.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyIconView)

        replySenderLabel.font = ChatLayout.current.replySenderFont
        replySenderLabel.numberOfLines = 1
        replySenderLabel.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replySenderLabel)

        replyTextLabel.font = ChatLayout.current.replyFont
        replyTextLabel.numberOfLines = 1
        replyTextLabel.lineBreakMode = .byTruncatingTail
        replyTextLabel.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyTextLabel)

        replyCancelButton.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        replyCancelButton.addTarget(self, action: #selector(cancelModeTapped), for: .touchUpInside)
        replyCancelButton.translatesAutoresizingMaskIntoConstraints = false
        replyPanel.addSubview(replyCancelButton)

        NSLayoutConstraint.activate([
            replyAccentBar.leadingAnchor.constraint(equalTo: replyPanel.leadingAnchor, constant: 12),
            replyAccentBar.topAnchor.constraint(equalTo: replyPanel.topAnchor, constant: 8),
            replyAccentBar.bottomAnchor.constraint(equalTo: replyPanel.bottomAnchor, constant: -8),
            replyAccentBar.widthAnchor.constraint(equalToConstant: 2.5),
            replyIconView.leadingAnchor.constraint(equalTo: replyAccentBar.trailingAnchor, constant: 8),
            replyIconView.centerYAnchor.constraint(equalTo: replyPanel.centerYAnchor),
            replyIconView.widthAnchor.constraint(equalToConstant: 16),
            replySenderLabel.leadingAnchor.constraint(equalTo: replyIconView.trailingAnchor, constant: 6),
            replySenderLabel.topAnchor.constraint(equalTo: replyPanel.topAnchor, constant: 6),
            replySenderLabel.trailingAnchor.constraint(lessThanOrEqualTo: replyCancelButton.leadingAnchor, constant: -8),
            replyTextLabel.leadingAnchor.constraint(equalTo: replySenderLabel.leadingAnchor),
            replyTextLabel.topAnchor.constraint(equalTo: replySenderLabel.bottomAnchor, constant: 1),
            replyTextLabel.trailingAnchor.constraint(lessThanOrEqualTo: replyCancelButton.leadingAnchor, constant: -8),
            replyCancelButton.trailingAnchor.constraint(equalTo: replyPanel.trailingAnchor, constant: -12),
            replyCancelButton.centerYAnchor.constraint(equalTo: replyPanel.centerYAnchor),
            replyCancelButton.widthAnchor.constraint(equalToConstant: 28),
            replyCancelButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        containerStack.addArrangedSubview(replyPanel)
    }

    // MARK: - Input Row

    private func setupInputRow() {
        inputStack.axis = .horizontal
        inputStack.alignment = .bottom
        inputStack.spacing = ChatLayout.current.inputStackSpacing
        inputStack.translatesAutoresizingMaskIntoConstraints = false
        inputStack.layoutMargins = UIEdgeInsets(top: ChatLayout.current.inputBarVPad, left: ChatLayout.current.inputBarHPad,
                                                 bottom: ChatLayout.current.inputBarVPad, right: ChatLayout.current.inputBarHPad)
        inputStack.isLayoutMarginsRelativeArrangement = true

        let attachConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        attachButton.setImage(UIImage(systemName: "paperclip", withConfiguration: attachConfig), for: .normal)
        attachButton.addTarget(self, action: #selector(attachTapped), for: .touchUpInside)
        attachButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            attachButton.widthAnchor.constraint(equalToConstant: ChatLayout.current.inputButtonSize),
            attachButton.heightAnchor.constraint(equalToConstant: ChatLayout.current.inputButtonSize),
        ])

        textViewContainer.layer.cornerRadius = ChatLayout.current.textViewCornerRadius
        textViewContainer.layer.borderWidth = ChatLayout.current.inputBorderWidth
        textViewContainer.translatesAutoresizingMaskIntoConstraints = false

        textView.font = ChatLayout.current.textViewFont
        textView.isScrollEnabled = false
        textView.textContainerInset = ChatLayout.current.textViewInsets
        textView.delegate = self
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textViewContainer.addSubview(textView)

        placeholderLabel.text = "Message"
        placeholderLabel.font = ChatLayout.current.textViewFont
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        textViewContainer.addSubview(placeholderLabel)

        textViewHeightConstraint = textView.heightAnchor.constraint(equalToConstant: ChatLayout.current.textViewMinHeight)
        textViewHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: textViewContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textViewContainer.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: textViewContainer.bottomAnchor),
            textViewHeightConstraint,
            placeholderLabel.leadingAnchor.constraint(equalTo: textViewContainer.leadingAnchor, constant: 13),
            placeholderLabel.centerYAnchor.constraint(equalTo: textViewContainer.centerYAnchor),
        ])

        let sendConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: sendConfig), for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.isHidden = true
        NSLayoutConstraint.activate([
            sendButton.widthAnchor.constraint(equalToConstant: ChatLayout.current.inputButtonSize),
            sendButton.heightAnchor.constraint(equalToConstant: ChatLayout.current.inputButtonSize),
        ])

        let recordConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        recordButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: recordConfig), for: .normal)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordButton.widthAnchor.constraint(equalToConstant: ChatLayout.current.inputButtonSize),
            recordButton.heightAnchor.constraint(equalToConstant: ChatLayout.current.inputButtonSize),
        ])

        inputStack.addArrangedSubview(attachButton)
        inputStack.addArrangedSubview(textViewContainer)
        inputStack.addArrangedSubview(sendButton)
        inputStack.addArrangedSubview(recordButton)
        containerStack.addArrangedSubview(inputStack)
    }

    // MARK: - Recording Overlay

    private func setupRecordingOverlay() {
        recordingOverlay.isHidden = true
        recordingOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(recordingOverlay)

        recordDot.backgroundColor = theme.voiceRecordingIndicator
        recordDot.layer.cornerRadius = ChatLayout.current.recordDotSize / 2
        recordDot.translatesAutoresizingMaskIntoConstraints = false
        recordingOverlay.addSubview(recordDot)

        recordTimerLabel.font = ChatLayout.current.recordTimerFont
        recordTimerLabel.text = "0:00"
        recordTimerLabel.translatesAutoresizingMaskIntoConstraints = false
        recordingOverlay.addSubview(recordTimerLabel)

        recordCancelLabel.text = "< Slide to cancel"
        recordCancelLabel.font = ChatLayout.current.recordCancelFont
        recordCancelLabel.textAlignment = .center
        recordCancelLabel.translatesAutoresizingMaskIntoConstraints = false
        recordingOverlay.addSubview(recordCancelLabel)

        let stopConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        recordStopButton.setImage(UIImage(systemName: "stop.circle.fill", withConfiguration: stopConfig), for: .normal)
        recordStopButton.tintColor = theme.voiceRecordingStopColor
        recordStopButton.addTarget(self, action: #selector(stopRecordTapped), for: .touchUpInside)
        recordStopButton.translatesAutoresizingMaskIntoConstraints = false
        recordingOverlay.addSubview(recordStopButton)

        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(cancelRecordTapped))
        recordCancelLabel.isUserInteractionEnabled = true
        recordCancelLabel.addGestureRecognizer(cancelTap)

        NSLayoutConstraint.activate([
            recordingOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            recordingOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            recordingOverlay.topAnchor.constraint(equalTo: separator.bottomAnchor),
            recordingOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            recordDot.leadingAnchor.constraint(equalTo: recordingOverlay.leadingAnchor, constant: 16),
            recordDot.centerYAnchor.constraint(equalTo: recordingOverlay.centerYAnchor),
            recordDot.widthAnchor.constraint(equalToConstant: ChatLayout.current.recordDotSize),
            recordDot.heightAnchor.constraint(equalToConstant: ChatLayout.current.recordDotSize),
            recordTimerLabel.leadingAnchor.constraint(equalTo: recordDot.trailingAnchor, constant: 8),
            recordTimerLabel.centerYAnchor.constraint(equalTo: recordingOverlay.centerYAnchor),
            recordCancelLabel.centerXAnchor.constraint(equalTo: recordingOverlay.centerXAnchor),
            recordCancelLabel.centerYAnchor.constraint(equalTo: recordingOverlay.centerYAnchor),
            recordStopButton.trailingAnchor.constraint(equalTo: recordingOverlay.trailingAnchor, constant: -16),
            recordStopButton.centerYAnchor.constraint(equalTo: recordingOverlay.centerYAnchor),
            recordStopButton.widthAnchor.constraint(equalToConstant: ChatLayout.current.recordStopSize),
            recordStopButton.heightAnchor.constraint(equalToConstant: ChatLayout.current.recordStopSize),
        ])
    }

    // MARK: - Theme

    func applyTheme(_ theme: ChatTheme) {
        self.theme = theme
        backgroundColor = theme.inputBarBackground
        separator.backgroundColor = theme.inputBarSeparator
        textViewContainer.backgroundColor = theme.inputBarTextViewBackground
        textViewContainer.layer.borderColor = theme.inputBarSeparator.cgColor
        textView.textColor = theme.inputBarText
        textView.tintColor = theme.inputBarTint
        placeholderLabel.textColor = theme.inputBarPlaceholder
        attachButton.tintColor = theme.inputBarTint
        sendButton.tintColor = theme.inputBarTint
        recordButton.tintColor = theme.inputBarTint

        replyPanel.backgroundColor = theme.replyPanelBackground
        replyAccentBar.backgroundColor = theme.replyPanelAccent
        replySenderLabel.textColor = theme.replyPanelSender
        replyTextLabel.textColor = theme.replyPanelText
        replyCancelButton.tintColor = theme.replyPanelClose

        recordingOverlay.backgroundColor = theme.inputBarBackground
        recordTimerLabel.textColor = theme.inputBarText
        recordCancelLabel.textColor = theme.inputBarPlaceholder
        recordDot.backgroundColor = theme.voiceRecordingIndicator
        recordStopButton.tintColor = theme.voiceRecordingStopColor
        textViewContainer.layer.borderColor = theme.inputBarBorder.cgColor
    }

    // MARK: - Mode Management

    func beginReply(info: ReplyInfo, theme: ChatTheme) {
        let senderName = info.senderName ?? "Message"
        let text = info.text ?? (info.hasImage ? "📷 Photo" : "…")
        mode = .reply(messageId: info.replyToId, senderName: senderName, text: text, hasImage: info.hasImage)

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        replyIconView.image = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: config)
        replyIconView.tintColor = theme.replyPanelAccent
        replySenderLabel.text = senderName
        replyTextLabel.text = text

        showReplyPanel(true)
        textView.becomeFirstResponder()
    }

    func beginEdit(messageId: String, text: String, theme: ChatTheme) {
        mode = .edit(messageId: messageId, text: text)

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        replyIconView.image = UIImage(systemName: "pencil", withConfiguration: config)
        replyIconView.tintColor = theme.replyPanelAccent
        replySenderLabel.text = "Edit Message"
        replyTextLabel.text = text

        textView.text = text
        placeholderLabel.isHidden = true
        updateTextViewHeight()
        updateSendButtonVisibility()

        showReplyPanel(true)
        textView.becomeFirstResponder()
    }

    func cancelMode() {
        let previousMode = mode
        mode = .normal
        textView.text = ""
        placeholderLabel.isHidden = false
        updateTextViewHeight()
        updateSendButtonVisibility()
        showReplyPanel(false)

        if case .edit = previousMode {
            textView.resignFirstResponder()
        }
    }

    // MARK: - Recording UI

    func showRecordingUI(duration: TimeInterval) {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        recordTimerLabel.text = String(format: "%d:%02d", mins, secs)

        if !isRecording {
            isRecording = true
            recordingOverlay.isHidden = false
            startDotAnimation()
        }
    }

    func hideRecordingUI() {
        isRecording = false
        recordingOverlay.isHidden = true
        recordDot.layer.removeAllAnimations()
    }

    // MARK: - Private

    private func showReplyPanel(_ show: Bool) {
        replyPanelHeight.constant = show ? ChatLayout.current.inputReplyPanelHeight : 0
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    private func updateTextViewHeight() {
        let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let h = min(max(size.height, ChatLayout.current.textViewMinHeight), ChatLayout.current.textViewMaxHeight)
        textViewHeightConstraint.constant = h
        textView.isScrollEnabled = size.height > ChatLayout.current.textViewMaxHeight
    }

    private func updateSendButtonVisibility() {
        let hasText = !(textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.isHidden = !hasText
        recordButton.isHidden = hasText
    }

    private func startDotAnimation() {
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse]) {
            self.recordDot.alpha = ChatLayout.current.recordDotMinAlpha
        }
    }

    // MARK: - Actions

    @objc private func attachTapped() { delegate?.inputBarDidTapAttachment() }

    @objc private func sendTapped() {
        let text = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        switch mode {
        case .normal:
            delegate?.inputBarDidSend(text: text, replyToId: nil)
        case .reply(let id, _, _, _):
            delegate?.inputBarDidSend(text: text, replyToId: id)
        case .edit(let id, _):
            delegate?.inputBarDidEdit(text: text, messageId: id)
        }

        textView.text = ""
        placeholderLabel.isHidden = false
        updateTextViewHeight()
        updateSendButtonVisibility()

        if mode != .normal {
            cancelMode()
        }
    }

    @objc private func recordTapped() { delegate?.inputBarDidStartRecording() }
    @objc private func stopRecordTapped() { delegate?.inputBarDidStopRecording() }
    @objc private func cancelRecordTapped() { delegate?.inputBarDidCancelRecording() }

    @objc private func cancelModeTapped() {
        let type: String
        switch mode {
        case .reply: type = "reply"
        case .edit: type = "edit"
        default: type = "none"
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
        updateSendButtonVisibility()
        delegate?.inputBarDidChangeText(textView.text ?? "")
    }
}
