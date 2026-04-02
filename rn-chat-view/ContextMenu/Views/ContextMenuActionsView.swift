import UIKit

// MARK: - ContextMenuActionsView

final class ContextMenuActionsView: UIView {

    var onActionTap: ((ContextMenuAction) -> Void)?

    private let theme:   ContextMenuTheme
    private var actions: [ContextMenuAction] = []

    private static let separatorHeight: CGFloat = 0.5
    private static let separatorTag    = 999

    init(theme: ContextMenuTheme) {
        self.theme = theme
        super.init(frame: .zero)
        backgroundColor     = theme.menuBackground
        layer.cornerRadius  = theme.menuCornerRadius
        layer.cornerCurve   = .continuous
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Наполняет меню строками действий и разделителями.
    func configure(with actions: [ContextMenuAction]) {
        self.actions = actions
        subviews.forEach { $0.removeFromSuperview() }

        for (index, action) in actions.enumerated() {
            let row = ActionRowView(action: action, theme: theme)
            row.onTap = { [weak self] in self?.onActionTap?(action) }
            addSubview(row)

            if index < actions.count - 1 {
                let sep = UIView()
                sep.backgroundColor = theme.menuSeparatorColor
                sep.tag = Self.separatorTag
                addSubview(sep)
            }
        }
        setNeedsLayout()
    }

    /// Возвращает высоту под заданный список действий.
    func preferredHeight(for actions: [ContextMenuAction]) -> CGFloat {
        CGFloat(actions.count) * theme.actionItemHeight
            + CGFloat(max(0, actions.count - 1)) * Self.separatorHeight
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !actions.isEmpty else { return }

        let rows = subviews.compactMap { $0 as? ActionRowView }
        let seps = subviews.filter { $0.tag == Self.separatorTag }
        var y: CGFloat = 0

        for i in actions.indices {
            if i < rows.count {
                rows[i].frame = CGRect(x: 0, y: y, width: bounds.width, height: theme.actionItemHeight)
                y += theme.actionItemHeight
            }
            if i < actions.count - 1, i < seps.count {
                seps[i].frame = CGRect(x: 0, y: y, width: bounds.width, height: Self.separatorHeight)
                y += Self.separatorHeight
            }
        }
    }
}

// MARK: - ActionRowView

private final class ActionRowView: UIView {

    var onTap: (() -> Void)?

    private let highlightView = UIView()
    private var highlighted   = false

    init(action: ContextMenuAction, theme: ContextMenuTheme) {
        super.init(frame: .zero)
        setupHighlight(theme: theme)
        setupContent(action: action, theme: theme)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupHighlight(theme: ContextMenuTheme) {
        highlightView.backgroundColor = theme.actionHighlightColor
        highlightView.alpha           = 0
        highlightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(highlightView)
    }

    private func setupContent(action: ContextMenuAction, theme: ContextMenuTheme) {
        let titleColor = action.isDestructive ? theme.actionDestructiveTitleColor : theme.actionTitleColor
        let iconColor  = action.isDestructive ? theme.actionDestructiveIconColor  : theme.actionIconColor
        let pad        = theme.actionHorizontalPadding

        let label = UILabel()
        label.text      = action.title
        label.font      = theme.actionTitleFont
        label.textColor = titleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        if let imageName = action.systemImage {
            let config   = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            let icon     = UIImageView(image: UIImage(systemName: imageName, withConfiguration: config))
            icon.tintColor   = iconColor
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            addSubview(icon)

            NSLayoutConstraint.activate([
                icon.centerYAnchor.constraint(equalTo: centerYAnchor),
                icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
                icon.widthAnchor.constraint(equalToConstant: 20),
                icon.heightAnchor.constraint(equalToConstant: 20),
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
                label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            ])
        } else {
            NSLayoutConstraint.activate([
                label.centerYAnchor.constraint(equalTo: centerYAnchor),
                label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
                label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            ])
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setHighlighted(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        setHighlighted(touches.first.map { bounds.contains($0.location(in: self)) } ?? false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let inside = touches.first.map { bounds.contains($0.location(in: self)) } ?? false
        setHighlighted(false)
        if inside { onTap?() }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setHighlighted(false)
    }

    /// Плавно включает или выключает подсветку строки.
    private func setHighlighted(_ on: Bool) {
        guard highlighted != on else { return }
        highlighted = on
        UIView.animate(withDuration: on ? 0.08 : 0.18) {
            self.highlightView.alpha = on ? 1 : 0
        }
    }
}
