import UIKit

/// Lock indicator shown above the mic button during voice recording drag.
final class InputBarLockView: UIView {

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private let chevron = UIImageView()
    private let lockIcon = UIImageView()

    private func setup() {
        let L = InputBarLayout.current

        layer.cornerRadius = L.lockSize / 2
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        alpha = 0

        let chevCfg = UIImage.SymbolConfiguration(pointSize: L.lockChevronSize, weight: .bold)
        chevron.image = UIImage(systemName: "chevron.up", withConfiguration: chevCfg)
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chevron)

        let lockCfg = UIImage.SymbolConfiguration(pointSize: L.lockIconSize, weight: .bold)
        lockIcon.image = UIImage(systemName: "lock.fill", withConfiguration: lockCfg)
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lockIcon)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: L.lockSize),
            heightAnchor.constraint(equalToConstant: L.lockSize + 14),
            chevron.centerXAnchor.constraint(equalTo: centerXAnchor),
            chevron.topAnchor.constraint(equalTo: topAnchor, constant: L.lockChevronTopPad),
            lockIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            lockIcon.centerYAnchor.constraint(equalTo: centerYAnchor, constant: L.lockIconCenterOffset),
        ])
    }

    // MARK: - Theme

    func applyTheme(_ theme: InputBarTheme) {
        backgroundColor = theme.lockBackground
        chevron.tintColor = theme.lockIcon
        lockIcon.tintColor = theme.lockIcon
    }

    // MARK: - Animate

    func animateIn() {
        alpha = 0
        chevron.alpha = 1
        transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func animateOut() {
        UIView.animate(withDuration: 0.2) { self.alpha = 0 }
    }
}
