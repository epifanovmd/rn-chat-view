import UIKit

final class MessageStatusView: UIView {
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(status: MessageStatus, isMine: Bool, theme: ChatTheme) {
        guard isMine else {
            isHidden = true
            return
        }
        isHidden = false

        let config = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        switch status {
        case .sending:
            iconView.image = UIImage(systemName: "clock", withConfiguration: config)
            iconView.tintColor = theme.outgoingStatus
        case .sent:
            iconView.image = UIImage(systemName: "checkmark", withConfiguration: config)
            iconView.tintColor = theme.outgoingStatus
        case .delivered:
            iconView.image = UIImage(systemName: "checkmark.circle", withConfiguration: config)
            iconView.tintColor = theme.outgoingStatus
        case .read:
            iconView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
            iconView.tintColor = theme.outgoingStatusRead
        }
    }
}
