import UIKit

/// Recording indicator row: red dot + timer + animated cancel hint.
final class InputBarRecordingRow: UIView {

    let dot = UIView()
    let timerLabel = UILabel()
    let slideContainer = UIView()
    let slideArrow = UILabel()
    let slideText = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        let L = InputBarLayout.current
        translatesAutoresizingMaskIntoConstraints = false

        dot.layer.cornerRadius = L.recordDotSize / 2
        dot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dot)

        timerLabel.font = L.recordTimerFont
        timerLabel.text = "0:00,00"
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timerLabel)

        slideContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slideContainer)

        slideArrow.text = "‹"
        slideArrow.font = L.recordSlideArrowFont
        slideArrow.translatesAutoresizingMaskIntoConstraints = false
        slideContainer.addSubview(slideArrow)

        slideText.text = "Отмена"
        slideText.font = L.recordCancelFont
        slideText.translatesAutoresizingMaskIntoConstraints = false
        slideContainer.addSubview(slideText)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: L.textViewMinHeight),

            dot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: L.recordDotLeading),
            dot.centerYAnchor.constraint(equalTo: centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: L.recordDotSize),
            dot.heightAnchor.constraint(equalToConstant: L.recordDotSize),

            timerLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: L.recordTimerLeading),
            timerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            slideContainer.centerXAnchor.constraint(equalTo: centerXAnchor, constant: L.recordSlideHintOffset),
            slideContainer.centerYAnchor.constraint(equalTo: centerYAnchor),

            slideArrow.leadingAnchor.constraint(equalTo: slideContainer.leadingAnchor),
            slideArrow.centerYAnchor.constraint(equalTo: slideContainer.centerYAnchor),
            slideText.leadingAnchor.constraint(equalTo: slideArrow.trailingAnchor, constant: 4),
            slideText.trailingAnchor.constraint(equalTo: slideContainer.trailingAnchor),
            slideText.centerYAnchor.constraint(equalTo: slideContainer.centerYAnchor),
        ])
    }

    // MARK: - Theme

    func applyTheme(_ theme: InputBarTheme) {
        dot.backgroundColor = theme.recordingDot
        timerLabel.textColor = theme.text
        slideArrow.textColor = theme.placeholder
        slideText.textColor = theme.placeholder
    }

    // MARK: - State

    func reset() {
        timerLabel.text = "0:00,00"
        timerLabel.alpha = 1
        dot.alpha = 1
        dot.transform = .identity
        slideContainer.alpha = 1
        slideContainer.transform = .identity
    }

    func startDotBlink() {
        dot.alpha = 1
        UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .autoreverse]) {
            self.dot.alpha = InputBarLayout.current.recordDotMinAlpha
        }
    }

    func stopDotBlink() {
        dot.layer.removeAllAnimations()
    }

    func startSlideAnimation() {
        animateSlide(toX: -12)
    }

    func stopSlideAnimation() {
        slideContainer.layer.removeAllAnimations()
        slideContainer.transform = .identity
    }

    func fadeOut(hideLock: Bool, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.15, animations: {
            self.dot.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.dot.alpha = 0
            self.slideContainer.alpha = 0
            self.timerLabel.alpha = 0
        }, completion: { _ in completion() })
    }

    // MARK: - Private

    private func animateSlide(toX: CGFloat) {
        UIView.animate(withDuration: 1.0, delay: 0, options: .curveEaseInOut, animations: {
            self.slideContainer.transform = CGAffineTransform(translationX: toX, y: 0)
        }) { [weak self] _ in
            guard let self, self.slideContainer.layer.animation(forKey: "position") != nil || self.slideContainer.transform != .identity else { return }
            self.animateSlide(toX: toX > 0 ? -12 : 12)
        }
    }
}
