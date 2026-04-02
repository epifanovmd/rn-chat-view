import UIKit

final class ReactionsView: UIView {
    var onReactionTap: ((String) -> Void)?

    private var chipViews: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(reactions: [Reaction], theme: ChatTheme) {
        chipViews.forEach { $0.removeFromSuperview() }
        chipViews.removeAll()

        var x: CGFloat = 0
        for reaction in reactions {
            let chip = makeChip(reaction: reaction, theme: theme)
            chip.frame.origin = CGPoint(x: x, y: 0)
            addSubview(chip)
            chipViews.append(chip)
            x += chip.bounds.width + ChatLayout.current.reactionChipSpacing
        }

        let totalW = max(0, x - ChatLayout.current.reactionChipSpacing)
        invalidateIntrinsicContentSize()
        frame.size = CGSize(width: totalW, height: ChatLayout.current.reactionChipHeight)
    }

    override var intrinsicContentSize: CGSize {
        let w = chipViews.reduce(CGFloat(0)) { $0 + $1.bounds.width + ChatLayout.current.reactionChipSpacing }
        return CGSize(width: max(0, w - ChatLayout.current.reactionChipSpacing), height: ChatLayout.current.reactionChipHeight)
    }

    private func makeChip(reaction: Reaction, theme: ChatTheme) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = ChatLayout.current.reactionChipHeight / 2

        if reaction.isMine {
            container.backgroundColor = theme.reactionMineBackground
            container.layer.borderWidth = ChatLayout.current.reactionBorderWidth
            container.layer.borderColor = theme.reactionMineBorder.cgColor
        } else {
            container.backgroundColor = theme.reactionBackground
        }

        let label = UILabel()
        label.font = ChatLayout.current.reactionFont
        label.text = "\(reaction.emoji) \(reaction.count)"
        label.textColor = theme.reactionText
        label.sizeToFit()

        label.frame.origin = CGPoint(x: 8, y: (ChatLayout.current.reactionChipHeight - label.bounds.height) / 2)
        container.addSubview(label)
        container.frame.size = CGSize(width: label.bounds.width + 16, height: ChatLayout.current.reactionChipHeight)

        let emoji = reaction.emoji
        let tap = UITapGestureRecognizer(target: self, action: #selector(chipTapped(_:)))
        container.tag = chipViews.count
        container.addGestureRecognizer(tap)
        container.isUserInteractionEnabled = true
        container.accessibilityLabel = emoji

        return container
    }

    @objc private func chipTapped(_ gesture: UITapGestureRecognizer) {
        guard let chip = gesture.view else { return }
        let emoji = chip.accessibilityLabel ?? ""
        onReactionTap?(emoji)
    }
}
