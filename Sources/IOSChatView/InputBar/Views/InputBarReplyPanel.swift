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

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        let L = ChatLayout()
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        clipsToBounds = true

        accentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(accentBar)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        senderLabel.font = L.inputReplySenderFont
        senderLabel.numberOfLines = 1
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(senderLabel)

        textLabel.font = L.inputReplyTextFont
        textLabel.numberOfLines = 1
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)

        let closeCfg = UIImage.SymbolConfiguration(pointSize: L.inputReplyCancelIconSize, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeCfg), for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        let sp = L.inputReplySpacing

        // Vertical constraints that touch top/bottom use high priority
        // so they yield to heightConstraint (required) when panel is collapsed to 0.
        let accentTop = accentBar.topAnchor.constraint(equalTo: topAnchor, constant: sp - 2)
        let accentBottom = accentBar.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -(sp - 4))
        let senderTop = senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: sp - 3)
        let sepBottom = separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        let sepHeight = separator.heightAnchor.constraint(equalToConstant: L.inputSeparatorHeight)

        let constraints = [
            accentBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sp + 2),
            accentTop,
            accentBottom,
            accentBar.widthAnchor.constraint(equalToConstant: L.inputReplyAccentWidth),

            iconView.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: sp - 2),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            iconView.widthAnchor.constraint(equalToConstant: L.inputReplyIconSize + 2),

            senderLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: sp / 2),
            senderTop,
            senderLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -sp / 2),

            textLabel.leadingAnchor.constraint(equalTo: senderLabel.leadingAnchor),
            textLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 1),
            textLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -sp / 2),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sp + 2),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1),
            closeButton.widthAnchor.constraint(equalToConstant: L.inputReplyCancelSize),
            closeButton.heightAnchor.constraint(equalToConstant: L.inputReplyCancelSize),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sp),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sp),
            sepBottom,
            sepHeight,
        ]
        // RN bridge начинает с width=0 — все horizontal constraints уступают
        constraints.forEach { $0.priority = .defaultHigh }
        NSLayoutConstraint.activate(constraints)
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

    func show(in container: UIView, height: CGFloat) {
        heightConstraint.constant = height
        alpha = 0
        container.setNeedsLayout()
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            container.superview?.layoutIfNeeded()
        }
    }

    func hide(in container: UIView) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 0
            self.heightConstraint.constant = 0
            container.superview?.layoutIfNeeded()
        })
    }
}
