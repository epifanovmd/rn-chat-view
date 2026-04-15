import UIKit

// MARK: - Делегат панели ввода

extension ChatViewController: InputBarDelegate {
    public func inputBarDidSend(text: String, replyToId: String?) {
        pendingScrollToBottom = true
        fabManager.setExpanded(false, animated: true)
        delegate?.chatDidSendMessage(text: text, replyToId: replyToId)
    }

    public func inputBarDidEdit(text: String, messageId: String) {
        delegate?.chatDidEditMessage(text: text, messageId: messageId)
    }

    public func inputBarDidCancelMode(type: String) {
        delegate?.chatDidCancelInputAction(type: type)
    }

    public func inputBarDidTapAttachment() {
        delegate?.chatDidTapAttachment()
    }

    public func inputBarDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {
        pendingScrollToBottom = true
        delegate?.chatDidCompleteVoiceRecording(fileURL: fileURL, duration: duration, waveform: waveform)
    }

    public func inputBarDidChangeText(_ text: String) {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        fabManager.setExpanded(hasText, animated: true)
        delegate?.chatDidChangeInputText(text)
    }

    public func inputBarRecordingStateChanged(isRecording: Bool) {
        if isRecording {
            fabManager.hideForRecording()
        } else {
            updateFABVisibility(animated: true)
        }
    }
}
