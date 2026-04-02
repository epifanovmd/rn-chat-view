import UIKit

final class ContextMenuEmojiPanel: UIView {

    var onEmojiTap: ((String) -> Void)?

    private let theme: ContextMenuTheme

    private let stack: UIStackView = {
        let sv = UIStackView()
        sv.axis         = .horizontal
        sv.alignment    = .center
        sv.distribution = .equalSpacing
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    init(theme: ContextMenuTheme) {
        self.theme = theme
        super.init(frame: .zero)
        setupAppearance()
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Наполняет панель кнопками для переданного списка emoji.
    func configure(with emojis: [ContextMenuEmoji]) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        emojis.forEach { stack.addArrangedSubview(makeButton(emoji: $0.emoji)) }
    }

    /// Возвращает предпочтительный размер панели для заданного количества emoji.
    func preferredSize(for emojis: [ContextMenuEmoji]) -> CGSize {
        let padding: CGFloat = 10
        let width  = CGFloat(emojis.count) * theme.emojiItemSize + padding * 2
        let height = theme.emojiItemSize + padding * 2
        return CGSize(width: width, height: height)
    }

    // MARK: - Private

    private func setupAppearance() {
        backgroundColor    = theme.emojiPanelBackground
        layer.cornerRadius = theme.emojiPanelCornerRadius
        layer.cornerCurve  = .continuous
        layer.shadowColor   = theme.emojiPanelShadowColor.cgColor
        layer.shadowOpacity = theme.emojiPanelShadowOpacity
        layer.shadowRadius  = theme.emojiPanelShadowRadius
        layer.shadowOffset  = CGSize(width: 0, height: 4)
    }

    private func setupLayout() {
        addSubview(stack)
        let p: CGFloat = 10
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: p),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
        ])
    }

    private func makeButton(emoji: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(emoji, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: theme.emojiFontSize)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.widthAnchor.constraint(equalToConstant: theme.emojiItemSize),
            btn.heightAnchor.constraint(equalToConstant: theme.emojiItemSize),
        ])
        btn.addTarget(self, action: #selector(tapped(_:)),      for: .touchUpInside)
        btn.addTarget(self, action: #selector(touchDown(_:)),   for: .touchDown)
        btn.addTarget(self, action: #selector(touchUp(_:)),     for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return btn
    }

    @objc private func tapped(_ sender: UIButton) {
        guard let emoji = sender.title(for: .normal) else { return }
        onEmojiTap?(emoji)
    }

    @objc private func touchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.10, delay: 0,
                       options: [.curveEaseInOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.80, y: 0.80)
        }
    }

    @objc private func touchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.20, delay: 0,
                       usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8,
                       options: .allowUserInteraction) {
            sender.transform = .identity
        }
    }
}
