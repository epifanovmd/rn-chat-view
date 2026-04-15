import UIKit

// MARK: - Жест и состояние записи

extension InputBarView {

    @objc func handleRecordGesture(_ g: UILongPressGestureRecognizer) {
        let loc = g.location(in: self)
        switch g.state {
        case .began:                startRecording(at: loc)
        case .changed:              guard recordingState == .recording else { return }; handleDrag(at: loc)
        case .ended, .cancelled:    guard recordingState == .recording else { return }; handleRelease()
        default: break
        }
    }

    // MARK: - Начало записи

    private func startRecording(at point: CGPoint) {
        haptic(.light)
        recordingState = .recording
        gestureStartPoint = point

        recordingRow.reset()
        recordingRow.applyTheme(currentTheme)
        textView.isHidden = true
        recordingRow.isHidden = false

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.leftButton.alpha = 0
            self.leftButton.isHidden = true
            self.inputStack.layoutIfNeeded()
        }

        inputStack.layer.zPosition = 1000
        rightButton.backgroundColor = currentTheme.recordingMicFill
        rightButton.tintColor = .white
        rightButton.layer.borderWidth = 0

        lockView.animateIn()

        recordingRow.startDotBlink(minAlpha: layout.recordDotMinAlpha)
        recordingRow.startSlideAnimation()
        VoicePlayer.shared.pauseIfPlaying()
        voiceRecorder.startRecording()
        delegate?.inputBarRecordingStateChanged(isRecording: true)
    }

    // MARK: - Перетаскивание

    private func handleDrag(at point: CGPoint) {
        let L = layout
        let dx = point.x - gestureStartPoint.x
        let dy = point.y - gestureStartPoint.y

        if abs(dx) > abs(dy) && dx < 0 {
            let progress = min(1, abs(dx) / L.recordCancelThreshold)
            let tx = min(0, dx) * 0.8
            rightButton.transform = CGAffineTransform(translationX: tx, y: 0)
                .scaledBy(x: 1 - progress * 0.3, y: 1 - progress * 0.3)
            recordingRow.slideContainer.alpha = 1 - progress
            if progress >= 1 { performCancel(); return }
        } else if dy < 0 {
            let progress = min(1, abs(dy) / L.recordLockThreshold)
            let ty = min(0, dy) * 0.8
            rightButton.transform = CGAffineTransform(translationX: 0, y: ty)
            lockView.transform = CGAffineTransform(scaleX: 1 + progress * 0.2, y: 1 + progress * 0.2)
            if progress >= 1 { performLock(); return }
        } else {
            rightButton.transform = .identity
            recordingRow.slideContainer.alpha = 1
            lockView.transform = .identity
        }
    }

    // MARK: - Отпускание → Отправка

    private func handleRelease() {
        recordingState = .idle
        recordingRow.stopSlideAnimation()

        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, animations: {
            self.rightButton.transform = .identity
            self.lockView.alpha = 0
        }) { _ in
            self.restoreMicStyle()
            self.restoreInputBar(trashAnimation: false) {
                self.voiceRecorder.stopRecording()
            }
        }
        delegate?.inputBarRecordingStateChanged(isRecording: false)
    }

    // MARK: - Отмена

    @objc func cancelHintTapped() {
        guard recordingState == .recording || recordingState == .locked else { return }
        performCancel()
    }

    func performCancel() {
        let wasLocked = recordingState == .locked
        recordingState = .idle

        voiceRecorder.cancelRecording()
        delegate?.inputBarRecordingStateChanged(isRecording: false)

        haptic(.heavy)
        recordingRow.stopDotBlink()
        recordingRow.stopSlideAnimation()

        recordingRow.fadeOut(hideLock: !wasLocked) { [self] in
            if wasLocked {
                stopSendButtonPulse()
                recordingRow.isHidden = true
                textView.isHidden = false
                rightButton.removeTarget(self, action: #selector(lockedSendTapped), for: .touchUpInside)
                restoreMicStyle()
                resetRightButtonToMic()
                restoreLeftButtonToClip()
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, animations: {
                    self.rightButton.transform = .identity
                }) { _ in
                    self.restoreMicStyle()
                    self.restoreInputBar(trashAnimation: true) {}
                }
            }
        }

        if !wasLocked { lockView.animateOut() }
    }

    // MARK: - Блокировка

    private func performLock() {
        let L = layout
        recordingState = .locked
        recordingRow.stopSlideAnimation()

        UIView.animate(withDuration: 0.15) {
            self.recordingRow.slideContainer.alpha = 0
        }

        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.rightButton.transform = .identity
            self.lockView.alpha = 0
        }

        let sendCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .semibold)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UIView.transition(with: self.rightButton, duration: 0.15, options: .transitionCrossDissolve) {
                self.rightButton.setImage(UIImage(systemName: "arrow.up", withConfiguration: sendCfg), for: .normal)
            }
            self.startSendButtonPulse()
        }

        let trashCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        leftButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: trashCfg), for: .normal)
        leftButton.tintColor = currentTheme.recordingCancel
        leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        leftButton.alpha = 0

        UIView.animate(withDuration: 0.25, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8) {
            self.leftButton.isHidden = !self.showAttachButton
            self.leftButton.transform = .identity
            self.leftButton.alpha = 1
            self.inputStack.layoutIfNeeded()
        }

        rightButton.gestureRecognizers?.forEach { rightButton.removeGestureRecognizer($0) }
        rightButton.addTarget(self, action: #selector(lockedSendTapped), for: .touchUpInside)
    }

    // MARK: - Пульсация

    private func startSendButtonPulse() {
        let L = layout
        rightButton.transform = CGAffineTransform(scaleX: L.recordPulseBaseScale, y: L.recordPulseBaseScale)
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = L.recordPulseBaseScale
        pulse.toValue = L.recordPulseMaxScale
        pulse.duration = L.recordPulseDuration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        rightButton.layer.add(pulse, forKey: "pulse")
    }

    private func stopSendButtonPulse() {
        rightButton.layer.removeAnimation(forKey: "pulse")
        rightButton.transform = .identity
    }

    @objc private func lockedSendTapped() {
        guard recordingState == .locked else { return }
        recordingState = .idle
        stopSendButtonPulse()
        restoreMicStyle()
        restoreInputBar(trashAnimation: false) {
            self.voiceRecorder.stopRecording()
        }
        delegate?.inputBarRecordingStateChanged(isRecording: false)
    }

    // MARK: - Восстановление

    func restoreInputBar(trashAnimation: Bool, completion: @escaping () -> Void) {
        let L = layout
        recordingRow.stopDotBlink()
        recordingRow.isHidden = true
        textView.isHidden = false

        rightButton.removeTarget(self, action: #selector(lockedSendTapped), for: .touchUpInside)
        resetRightButtonToMic()

        leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        leftButton.alpha = 0

        let iconCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        if trashAnimation {
            leftButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: iconCfg), for: .normal)
            leftButton.tintColor = currentTheme.recordingCancel
        } else {
            leftButton.setImage(UIImage(systemName: "paperclip", withConfiguration: iconCfg), for: .normal)
            leftButton.tintColor = currentTheme.tint
        }

        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8, animations: {
            self.leftButton.isHidden = !self.showAttachButton
            self.leftButton.transform = .identity
            self.leftButton.alpha = 1
            self.inputStack.layoutIfNeeded()
        }) { _ in
            if trashAnimation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.restoreLeftButtonToClip()
                }
            }
            completion()
        }
    }

    private func restoreMicStyle() {
        inputStack.layer.zPosition = 0
        rightButton.backgroundColor = currentTheme.background
        rightButton.tintColor = currentTheme.tint
        rightButton.layer.borderWidth = layout.inputBorderWidth
    }
}
