import UIKit

// MARK: - Recording Gesture & State

extension ChatInputBar {

    @objc func handleRecordGesture(_ g: UILongPressGestureRecognizer) {
        let loc = g.location(in: self)
        switch g.state {
        case .began:                startRecording(at: loc)
        case .changed:              guard recordingState == .recording else { return }; handleDrag(at: loc)
        case .ended, .cancelled:    guard recordingState == .recording else { return }; handleRelease()
        default: break
        }
    }

    // MARK: - Start

    private func startRecording(at point: CGPoint) {
        let L = ChatLayout.current
        recordingState = .recording
        gestureStartPoint = point
        lastRecordedDuration = 0
        haptic(.light)

        // Reset recording row
        recordTimerLabel.text = "0:00,00"
        recordTimerLabel.alpha = 1
        recordDot.alpha = 1
        recordDot.transform = .identity
        slideHintContainer.alpha = 1
        slideHintContainer.transform = .identity
        slideArrowLabel.text = "‹‹‹"
        slideArrowLabel.textColor = theme.inputBarPlaceholder
        slideTextLabel.textColor = theme.inputBarPlaceholder

        // Switch content
        textView.isHidden = true
        recordingRow.isHidden = false

        // Animate left button out + input expands
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.leftButton.alpha = 0
            self.leftButton.isHidden = true
            self.inputStack.layoutIfNeeded()
        }

        // Lift entire inputStack above lock container
        inputStack.layer.zPosition = 1000

        // Style rightButton as draggable mic (blue filled)
        rightButton.backgroundColor = theme.voiceRecordingMicBackground
        rightButton.tintColor = .white
        rightButton.layer.borderWidth = 0

        // Record origin for drag calculations
        let center = rightButton.superview!.convert(rightButton.center, to: self)
        micOriginCenter = center

        // Lock container
        lockContainer.alpha = 0
        lockContainer.transform = CGAffineTransform(translationX: 0, y: 20)
        lockChevron.alpha = 1
        UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.lockContainer.alpha = 1
            self.lockContainer.transform = .identity
        }

        startDotBlink()
        startSlideHintAnimation()
        delegate?.inputBarDidStartRecording()
        delegate?.inputBarRecordingStateChanged(isRecording: true)
    }

    // MARK: - Drag

    private func handleDrag(at point: CGPoint) {
        let L = ChatLayout.current
        let dx = point.x - gestureStartPoint.x
        let dy = point.y - gestureStartPoint.y

        if abs(dx) > abs(dy) && dx < 0 {
            // Cancel direction (left)
            let progress = min(1, abs(dx) / L.recordCancelThreshold)
            let tx = min(0, dx) * 0.8
            rightButton.transform = CGAffineTransform(translationX: tx, y: 0)
                .scaledBy(x: 1 - progress * 0.3, y: 1 - progress * 0.3)
            slideHintContainer.alpha = 1 - progress
            if progress >= 1 { performCancel(); return }
        } else if dy < 0 {
            // Lock direction (up)
            let progress = min(1, abs(dy) / L.recordLockThreshold)
            let ty = min(0, dy) * 0.8
            rightButton.transform = CGAffineTransform(translationX: 0, y: ty)
            lockContainer.transform = CGAffineTransform(scaleX: 1 + progress * 0.2, y: 1 + progress * 0.2)
            if progress >= 1 { performLock(); return }
        } else {
            // Return to origin
            rightButton.transform = .identity
            slideHintContainer.alpha = 1
            lockContainer.transform = .identity
        }
    }

    // MARK: - Release → Send

    private func handleRelease() {
        recordingState = .idle
        stopSlideHintAnimation()

        // Snap rightButton back, then restore
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, animations: {
            self.rightButton.transform = .identity
            self.lockContainer.alpha = 0
        }) { _ in
            self.restoreMicButton()
            self.restoreInputBar(trashAnimation: false) {
                self.delegate?.inputBarDidStopRecording()
            }
        }
        delegate?.inputBarRecordingStateChanged(isRecording: false)
    }

    // MARK: - Cancel

    @objc func cancelHintTapped() {
        guard recordingState == .recording || recordingState == .locked else { return }
        performCancel()
    }

    func performCancel() {
        let wasLocked = recordingState == .locked
        recordingState = .idle

        // 1. Stop recording first
        delegate?.inputBarDidCancelRecording()
        delegate?.inputBarRecordingStateChanged(isRecording: false)

        // 2. Haptic after recording stopped
        haptic(.heavy)

        // 3. Animate
        recordDot.layer.removeAllAnimations()
        stopSlideHintAnimation()

        UIView.animate(withDuration: 0.15) {
            self.recordDot.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.recordDot.alpha = 0
            self.slideHintContainer.alpha = 0
            self.recordTimerLabel.alpha = 0
            if !wasLocked {
                self.lockContainer.alpha = 0
            }
        } completion: { _ in
            if wasLocked {
                self.stopSendButtonPulse()
                self.recordingRow.isHidden = true
                self.textView.isHidden = false
                self.rightButton.removeTarget(self, action: #selector(self.lockedSendTapped), for: .touchUpInside)
                self.restoreMicButton()
                self.resetRightButtonToMic()
                self.restoreLeftButtonToClip()
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, animations: {
                    self.rightButton.transform = .identity
                }) { _ in
                    self.restoreMicButton()
                    self.restoreInputBar(trashAnimation: true) {}
                }
            }
        }
    }

    // MARK: - Lock

    private func performLock() {
        let L = ChatLayout.current
        recordingState = .locked
        stopSlideHintAnimation()

        // Snap rightButton back to origin and switch to send style + pulse
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.rightButton.transform = .identity
            self.lockContainer.alpha = 0
        }

        // Change icon to send arrow
        let sendCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .semibold)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UIView.transition(with: self.rightButton, duration: 0.15, options: .transitionCrossDissolve) {
                self.rightButton.setImage(UIImage(systemName: "arrow.up", withConfiguration: sendCfg), for: .normal)
            }
            self.startSendButtonPulse()
        }

        // Show left button as red trash
        let trashCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        leftButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: trashCfg), for: .normal)
        leftButton.tintColor = theme.voiceRecordingCancelColor
        leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        leftButton.alpha = 0

        UIView.animate(withDuration: 0.25, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8) {
            self.leftButton.isHidden = false
            self.leftButton.transform = .identity
            self.leftButton.alpha = 1
            self.inputStack.layoutIfNeeded()
        }

        rightButton.gestureRecognizers?.forEach { rightButton.removeGestureRecognizer($0) }
        rightButton.addTarget(self, action: #selector(lockedSendTapped), for: .touchUpInside)
    }

    private func startSendButtonPulse() {
        rightButton.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.15
        pulse.toValue = 1.28
        pulse.duration = 0.6
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
        restoreMicButton()
        restoreInputBar(trashAnimation: false) {
            self.delegate?.inputBarDidStopRecording()
        }
        delegate?.inputBarRecordingStateChanged(isRecording: false)
    }

    // MARK: - Restore Input Bar

    func restoreInputBar(trashAnimation: Bool, completion: @escaping () -> Void) {
        let L = ChatLayout.current
        recordDot.layer.removeAllAnimations()
        recordingRow.isHidden = true
        textView.isHidden = false

        // Restore right button
        rightButton.removeTarget(self, action: #selector(lockedSendTapped), for: .touchUpInside)
        resetRightButtonToMic()

        // Show left button — simultaneously with input shrinking
        leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        leftButton.alpha = 0

        if trashAnimation {
            let trashCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
            leftButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: trashCfg), for: .normal)
            leftButton.tintColor = theme.voiceRecordingCancelColor
        } else {
            restoreLeftButtonToClip()
        }

        if trashAnimation {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8, animations: {
                self.leftButton.isHidden = false
                self.leftButton.transform = .identity
                self.leftButton.alpha = 1
                self.inputStack.layoutIfNeeded()
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.restoreLeftButtonToClip()
                }
                completion()
            }
        } else {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8, animations: {
                self.leftButton.isHidden = false
                self.leftButton.transform = .identity
                self.leftButton.alpha = 1
                self.inputStack.layoutIfNeeded()
            }) { _ in
                completion()
            }
        }
    }

    // MARK: - Mic Button Helpers

    /// Restore rightButton visual style to normal (from blue draggable state)
    private func restoreMicButton() {
        inputStack.layer.zPosition = 0
        rightButton.backgroundColor = theme.inputBarTextViewBackground
        rightButton.tintColor = theme.inputBarTint
        rightButton.layer.borderWidth = ChatLayout.current.inputBorderWidth
    }

    private func bounceTrashThenRestore() {
        restoreLeftButtonToClip()
    }

    // MARK: - Single Pulse

    func singlePulse(_ view: UIView, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
            view.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.3, animations: {
                view.transform = .identity
            }) { _ in
                completion?()
            }
        }
    }

    // MARK: - Animations

    private func startDotBlink() {
        recordDot.alpha = 1
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse]) {
            self.recordDot.alpha = ChatLayout.current.recordDotMinAlpha
        }
    }

    private func startSlideHintAnimation() {
        animateSlideHint(toX: -12)
    }

    private func animateSlideHint(toX: CGFloat) {
        guard recordingState == .recording else { return }
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
            self.slideHintContainer.transform = CGAffineTransform(translationX: toX, y: 0)
        }) { _ in
            guard self.recordingState == .recording else { return }
            self.animateSlideHint(toX: toX > 0 ? -12 : 12)
        }
    }

    private func stopSlideHintAnimation() {
        slideHintContainer.layer.removeAllAnimations()
        slideHintContainer.transform = .identity
    }
}
