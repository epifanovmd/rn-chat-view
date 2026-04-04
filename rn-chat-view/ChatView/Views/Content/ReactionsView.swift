import UIKit

final class ReactionsView: UIView {
    var onReactionTap: ((String) -> Void)?

    private var chipViews: [UIView] = []
    private var currentMaxWidth: CGFloat = 0
    private var currentLayout = ChatLayout()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(reactions: [Reaction], theme: ChatTheme, maxWidth: CGFloat, layout: ChatLayout = ChatLayout()) {
        chipViews.forEach { $0.removeFromSuperview() }
        chipViews.removeAll()
        currentMaxWidth = maxWidth
        currentLayout = layout

        let spacing = currentLayout.reactionChipSpacing
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for reaction in reactions {
            let chip = makeChip(reaction: reaction, theme: theme)
            let chipWidth = chip.bounds.width

            // Перенос на новую строку
            if x + chipWidth > maxWidth && x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }

            chip.frame = CGRect(x: x, y: y, width: chipWidth, height: currentLayout.reactionChipHeight)
            addSubview(chip)
            chipViews.append(chip)

            x += chipWidth + spacing
            lineHeight = max(lineHeight, currentLayout.reactionChipHeight)
        }

        let totalHeight = y + lineHeight
        frame.size = CGSize(width: maxWidth, height: totalHeight)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        return frame.size
    }

    private func makeChip(reaction: Reaction, theme: ChatTheme) -> UIView {
        let container = UIView()
        let L = currentLayout
        container.layer.cornerRadius = L.reactionChipHeight / 2

        if reaction.isMine {
            container.backgroundColor = theme.reactionMineBackground
            container.layer.borderWidth = L.reactionBorderWidth
            container.layer.borderColor = theme.reactionMineBorder.cgColor
        } else {
            container.backgroundColor = theme.reactionBackground
        }

        let label = UILabel()
        label.font = L.reactionFont
        label.text = "\(reaction.emoji) \(reaction.count)"
        label.textColor = theme.reactionText
        label.sizeToFit()

        let chipWidth = label.bounds.width + 16
        label.frame = CGRect(
            x: 8,
            y: (L.reactionChipHeight - label.bounds.height) / 2,
            width: label.bounds.width,
            height: label.bounds.height
        )
        container.addSubview(label)
        container.frame.size = CGSize(width: chipWidth, height: L.reactionChipHeight)

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
