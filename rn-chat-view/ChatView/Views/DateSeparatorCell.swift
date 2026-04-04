import UIKit

final class DateSeparatorCell: UICollectionViewCell {
    private let pillView = UIView()
    private let label = UILabel()
    private var currentLayout = ChatLayout()

    // MARK: - Stored constraints

    private var labelTopConstraint: NSLayoutConstraint!
    private var labelBottomConstraint: NSLayoutConstraint!
    private var labelLeadingConstraint: NSLayoutConstraint!
    private var labelTrailingConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let L = currentLayout

        backgroundColor = .clear
        contentView.backgroundColor = .clear

        pillView.layer.cornerRadius = L.dateSeparatorCornerRadius
        pillView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pillView)

        label.font = L.dateSeparatorFont
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pillView.addSubview(label)

        labelTopConstraint = label.topAnchor.constraint(equalTo: pillView.topAnchor, constant: L.dateSeparatorVPad)
        labelBottomConstraint = label.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: -L.dateSeparatorVPad)
        labelLeadingConstraint = label.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: L.dateSeparatorHPad)
        labelTrailingConstraint = label.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -L.dateSeparatorHPad)

        NSLayoutConstraint.activate([
            pillView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pillView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            labelTopConstraint,
            labelBottomConstraint,
            labelLeadingConstraint,
            labelTrailingConstraint,
        ])
    }

    func configure(title: String, theme: ChatTheme, layout: ChatLayout = ChatLayout()) {
        currentLayout = layout
        let L = currentLayout

        // Update layout-dependent values
        pillView.layer.cornerRadius = L.dateSeparatorCornerRadius
        label.font = L.dateSeparatorFont
        labelTopConstraint.constant = L.dateSeparatorVPad
        labelBottomConstraint.constant = -L.dateSeparatorVPad
        labelLeadingConstraint.constant = L.dateSeparatorHPad
        labelTrailingConstraint.constant = -L.dateSeparatorHPad

        label.text = title
        label.textColor = theme.dateSeparatorText
        pillView.backgroundColor = theme.dateSeparatorBackground
    }
}
