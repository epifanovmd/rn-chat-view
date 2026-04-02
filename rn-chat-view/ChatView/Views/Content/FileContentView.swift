import UIKit

final class FileContentView: UIView {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        iconView.image = UIImage(systemName: "doc.fill", withConfiguration: config)
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        nameLabel.font = ChatLayout.current.fileNameFont
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        sizeLabel.font = ChatLayout.current.fileSizeFont
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sizeLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: ChatLayout.current.fileIconSize),
            iconView.heightAnchor.constraint(equalToConstant: ChatLayout.current.fileIconSize),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            sizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            heightAnchor.constraint(greaterThanOrEqualToConstant: ChatLayout.current.fileIconSize + 8),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func configure(file: FilePayload, isMine: Bool, theme: ChatTheme) {
        nameLabel.text = file.name
        nameLabel.textColor = isMine ? theme.outgoingText : theme.incomingText
        sizeLabel.text = formatSize(file.size)
        sizeLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        iconView.tintColor = isMine ? theme.outgoingText : theme.inputBarTint

        let ext = (file.name as NSString).pathExtension.lowercased()
        let icon: String
        switch ext {
        case "pdf": icon = "doc.richtext.fill"
        case "zip", "rar", "7z": icon = "doc.zipper"
        case "mp3", "wav", "aac", "m4a": icon = "music.note"
        case "mp4", "mov", "avi": icon = "film"
        default: icon = "doc.fill"
        }
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        iconView.image = UIImage(systemName: icon, withConfiguration: cfg)
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    @objc private func tapped() { onTap?() }
}
