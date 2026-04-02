import UIKit

final class DateSeparatorCell: UICollectionViewCell {
    private let pillView = UIView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        pillView.layer.cornerRadius = ChatLayout.current.dateSeparatorCornerRadius
        pillView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pillView)

        label.font = ChatLayout.current.dateSeparatorFont
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pillView.addSubview(label)

        NSLayoutConstraint.activate([
            pillView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            pillView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.topAnchor.constraint(equalTo: pillView.topAnchor, constant: ChatLayout.current.dateSeparatorVPad),
            label.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: -ChatLayout.current.dateSeparatorVPad),
            label.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: ChatLayout.current.dateSeparatorHPad),
            label.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -ChatLayout.current.dateSeparatorHPad),
        ])
    }

    func configure(title: String, theme: ChatTheme) {
        label.text = title
        label.textColor = theme.dateSeparatorText
        pillView.backgroundColor = theme.dateSeparatorBackground
    }
}
