import UIKit

// MARK: - ChatInputBarDelegate

extension ChatViewController: InputBarDelegate {
    func inputBarDidSend(text: String, replyToId: String?) {
        pendingScrollToBottom = true
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

    func inputBarDidStartRecording() {
        VoicePlayer.shared.pauseIfPlaying()
        voiceRecorder.startRecording()
    }
    func inputBarDidStopRecording() { voiceRecorder.stopRecording() }
    func inputBarDidCancelRecording() { voiceRecorder.cancelRecording() }

    func inputBarDidChangeText(_ text: String) {
        delegate?.chatDidChangeInputText(text)
    }

    func inputBarRecordingStateChanged(isRecording: Bool) {
        if isRecording {
            // Hide FAB when recording
            UIView.animate(withDuration: 0.2) {
                self.fabButton.alpha = 0
                self.fabBadge.alpha = 0
            }
        } else {
            // Restore FAB visibility
            updateFABVisibility(animated: true)
        }
    }
}

// MARK: - VoiceRecorderDelegate

extension ChatViewController: VoiceRecorderDelegate {
    func voiceRecorderDidStart() { inputBar.showRecordingUI(duration: 0) }

    func voiceRecorderDidStop(fileURL: URL, duration: TimeInterval) {
        inputBar.hideRecordingUI()
        pendingScrollToBottom = true
        delegate?.chatDidCompleteVoiceRecording(fileURL: fileURL, duration: duration)
    }

    func voiceRecorderDidCancel() { inputBar.hideRecordingUI() }
    func voiceRecorderDidFail(error: Error) { inputBar.hideRecordingUI() }
    func voiceRecorderDidUpdateDuration(_ duration: TimeInterval) { inputBar.showRecordingUI(duration: duration) }
    func voiceRecorderDidUpdateLevel(_ level: Float) {}
}
