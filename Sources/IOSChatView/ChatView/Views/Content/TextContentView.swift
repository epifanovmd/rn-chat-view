import UIKit

public final class TextContentView: UIView {
    private let label = UILabel()
    private var currentLayout = ChatLayout()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = currentLayout.messageFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public required init?(coder: NSCoder) { fatalError() }

    func configure(text: String, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout = ChatLayout()) {
        currentLayout = layout
        label.font = currentLayout.messageFont
        label.text = text
        switch ownership {
        case .mine:   label.textColor = theme.outgoingText
        case .theirs: label.textColor = theme.incomingText
        case .system: label.textColor = theme.systemText
        case .pinned: label.textColor = theme.pinnedText
        }
        label.textAlignment = ownership == .system ? .center : .natural
    }
}
