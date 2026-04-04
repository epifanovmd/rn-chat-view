import UIKit

// MARK: - InputBarDelegate

extension ChatViewController: InputBarDelegate {
    func inputBarDidSend(text: String, replyToId: String?) {
        pendingScrollToBottom = true
        fabManager.setExpanded(false, animated: true)
        delegate?.chatDidSendMessage(text: text, replyToId: replyToId)
    }

    func inputBarDidEdit(text: String, messageId: String) {
        delegate?.chatDidEditMessage(text: text, messageId: messageId)
    }

    func inputBarDidCancelMode(type: String) {
        delegate?.chatDidCancelInputAction(type: type)
    }

    func inputBarDidTapAttachment() {
        delegate?.chatDidTapAttachment()
    }

    func inputBarDidCompleteVoiceRecording(fileURL: URL, duration: TimeInterval, waveform: [Float]) {
        pendingScrollToBottom = true
        delegate?.chatDidCompleteVoiceRecording(fileURL: fileURL, duration: duration, waveform: waveform)
    }

    func inputBarDidChangeText(_ text: String) {
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        fabManager.setExpanded(hasText, animated: true)
        delegate?.chatDidChangeInputText(text)
    }

    func inputBarRecordingStateChanged(isRecording: Bool) {
        if isRecording {
            fabManager.hideForRecording()
        } else {
            updateFABVisibility(animated: true)
        }
    }
}
