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
        hapticLight.impactOccurred()

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

        // Animate left button out + input expands simultaneously
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.leftButton.alpha = 0
            self.leftButton.isHidden = true
            self.inputStack.layoutIfNeeded()
        }

        // Floating mic at right button center
        let center = rightButton.superview!.convert(rightButton.center, to: self)
        micOriginCenter = center
        floatingMicButton.center = center
        floatingMicButton.isHidden = false
        floatingMicButton.alpha = 1
        floatingMicButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let micCfg = UIImage.SymbolConfiguration(pointSize: L.recordFloatingMicIconSize, weight: .medium)
        floatingMicIcon.image = UIImage(systemName: "mic.fill", withConfiguration: micCfg)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            self.floatingMicButton.transform = .identity
        }

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
            let progress = min(1, abs(dx) / L.recordCancelThreshold)
            floatingMicButton.center = CGPoint(x: micOriginCenter.x + min(0, dx) * 0.8, y: micOriginCenter.y)
            slideHintContainer.alpha = 1 - progress
            floatingMicButton.transform = CGAffineTransform(scaleX: 1 - progress * 0.3, y: 1 - progress * 0.3)
            if progress >= 1 { performCancel(); return }
        } else if dy < 0 {
            let progress = min(1, abs(dy) / L.recordLockThreshold)
            floatingMicButton.center = CGPoint(x: micOriginCenter.x, y: micOriginCenter.y + min(0, dy) * 0.8)
            lockContainer.transform = CGAffineTransform(scaleX: 1 + progress * 0.2, y: 1 + progress * 0.2)
            if progress >= 1 { performLock(); return }
        } else {
            floatingMicButton.center = micOriginCenter
            floatingMicButton.transform = .identity
            slideHintContainer.alpha = 1
            lockContainer.transform = .identity
        }
    }

    // MARK: - Release → Send

    private func handleRelease() {
        recordingState = .idle
        stopSlideHintAnimation()
        dismissFloating()
        restoreInputBar(trashAnimation: false) {
            self.delegate?.inputBarDidStopRecording()
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
        hapticHeavy.impactOccurred()
        recordDot.layer.removeAllAnimations()
        stopSlideHintAnimation()
        stopSendButtonPulse()

        if !wasLocked { dismissFloating() }

        UIView.animate(withDuration: 0.15) {
            self.recordDot.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.recordDot.alpha = 0
            self.slideHintContainer.alpha = 0
            self.recordTimerLabel.alpha = 0
            if !wasLocked {
                self.floatingMicButton.alpha = 0
                self.lockContainer.alpha = 0
            }
        } completion: { _ in
            if wasLocked {
                // Left button already visible as trash — bounce then crossfade to clip
                self.stopSendButtonPulse()
                self.recordingRow.isHidden = true
                self.textView.isHidden = false
                self.rightButton.removeTarget(self, action: #selector(self.lockedSendTapped), for: .touchUpInside)
                self.resetRightButtonToMic()
                self.bounceTrashThenRestore()
                self.delegate?.inputBarDidCancelRecording()
            } else {
                self.restoreInputBar(trashAnimation: true) {
                    self.delegate?.inputBarDidCancelRecording()
                }
            }
        }

        delegate?.inputBarRecordingStateChanged(isRecording: false)
    }

    // MARK: - Lock

    private func performLock() {
        let L = ChatLayout.current
        recordingState = .locked
        hapticMedium.impactOccurred()
        stopSlideHintAnimation()

        // Hide floating mic + lock
        UIView.animate(withDuration: 0.25) {
            self.floatingMicButton.alpha = 0
            self.floatingMicButton.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            self.lockContainer.alpha = 0
        } completion: { _ in
            self.floatingMicButton.isHidden = true
            self.floatingMicButton.transform = .identity
        }

        // Show left button as red trash — simultaneously with input shrinking
        let trashCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
        leftButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: trashCfg), for: .normal)
        leftButton.tintColor = theme.voiceRecordingCancelColor
        leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        leftButton.alpha = 0

        // Trash appears at normal size
        leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        leftButton.alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0.1, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.8, animations: {
            self.leftButton.isHidden = false
            self.leftButton.transform = .identity
            self.leftButton.alpha = 1
            self.inputStack.layoutIfNeeded()
        })

        // Right button → filled send style + pulse
        let sendCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .semibold)
        UIView.transition(with: rightButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.rightButton.setImage(UIImage(systemName: "arrow.up", withConfiguration: sendCfg), for: .normal)
            self.rightButton.backgroundColor = self.theme.voiceRecordingMicBackground
            self.rightButton.tintColor = .white
            self.rightButton.layer.borderWidth = 0
        }
        startSendButtonPulse()

        rightButton.gestureRecognizers?.forEach { rightButton.removeGestureRecognizer($0) }
        rightButton.addTarget(self, action: #selector(lockedSendTapped), for: .touchUpInside)
    }

    private func startSendButtonPulse() {
        // Enlarge button and pulse around enlarged size
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
        rightButton.backgroundColor = theme.inputBarTextViewBackground
        rightButton.tintColor = theme.inputBarTint
        rightButton.layer.borderWidth = ChatLayout.current.inputBorderWidth
    }

    @objc private func lockedSendTapped() {
        guard recordingState == .locked else { return }
        recordingState = .idle
        hapticLight.impactOccurred()
        stopSendButtonPulse()
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
        if trashAnimation {
            // Trash appears normally, then restoreLeftButtonToClip shrinks before swapping
            let trashCfg = UIImage.SymbolConfiguration(pointSize: L.inputIconSize, weight: .medium)
            leftButton.setImage(UIImage(systemName: "trash.fill", withConfiguration: trashCfg), for: .normal)
            leftButton.tintColor = theme.voiceRecordingCancelColor
            leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            leftButton.alpha = 0

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
            restoreLeftButtonToClip()
            leftButton.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            leftButton.alpha = 0

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

    private func bounceTrashThenRestore() {
        restoreLeftButtonToClip()
    }

    // MARK: - Floating Helpers

    private func dismissFloating() {
        floatingMicButton.layer.removeAllAnimations()
        floatingMicButton.isHidden = true
        floatingMicButton.transform = .identity
        floatingMicButton.alpha = 1
        lockContainer.alpha = 0
        lockChevron.alpha = 1
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
