import UIKit

/// Collapsible reply/edit preview panel displayed inside the input container.
final class InputBarReplyPanel: UIView {

    let accentBar = UIView()
    let iconView = UIImageView()
    let senderLabel = UILabel()
    let textLabel = UILabel()
    let closeButton = UIButton(type: .system)
    let separator = UIView()

    private(set) var heightConstraint: NSLayoutConstraint!

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
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        clipsToBounds = true

        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        senderLabel.font = L.replySenderFont
        senderLabel.numberOfLines = 1
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(senderLabel)

        textLabel.font = L.replyTextFont
        textLabel.numberOfLines = 1
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)

        let closeCfg = UIImage.SymbolConfiguration(pointSize: L.replyCancelIconSize, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeCfg), for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        let sp = L.replySpacing
        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sp + 2),
            accentBar.topAnchor.constraint(equalTo: topAnchor, constant: sp - 2),
            accentBar.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -(sp - 4)),
            accentBar.widthAnchor.constraint(equalToConstant: L.replyAccentWidth),

            iconView.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: sp - 2),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            iconView.widthAnchor.constraint(equalToConstant: L.replyIconSize + 2),

            senderLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: sp / 2),
            senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: sp - 3),
            senderLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -sp / 2),

            textLabel.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            textLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 1),
            textLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -sp / 2),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sp + 2),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            closeButton.widthAnchor.constraint(equalToConstant: L.replyCancelSize),
            closeButton.heightAnchor.constraint(equalToConstant: L.replyCancelSize),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sp),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sp),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: L.replySeparatorHeight),
        ])
    }

    // MARK: - Theme

    func applyTheme(_ theme: InputBarTheme) {
        accentBar.backgroundColor = theme.replyAccent
        senderLabel.textColor = theme.replySender
        textLabel.textColor = theme.replyText
        closeButton.tintColor = theme.replyClose
        separator.backgroundColor = theme.border
    }

    // MARK: - Show / Hide

    func show(in container: UIView) {
        alpha = 0
        heightConstraint.constant = InputBarLayout.current.replyPanelHeight
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            container.layoutIfNeeded()
        }
    }

    func hide(in container: UIView) {
        heightConstraint.constant = 0
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            container.layoutIfNeeded()
        }
    }
}
