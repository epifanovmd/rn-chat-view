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

    func configure(text: String, isMine: Bool, theme: ChatTheme, layout: ChatLayout = ChatLayout()) {
        currentLayout = layout
        label.font = currentLayout.messageFont
        label.text = text
        label.textColor = isMine ? theme.outgoingText : theme.incomingText
    }
}
