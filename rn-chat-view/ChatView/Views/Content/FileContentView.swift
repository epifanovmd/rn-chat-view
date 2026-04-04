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
        let L = ChatLayout()

        layer.cornerRadius = L.fileCornerRadius
        layer.masksToBounds = true

        let config = UIImage.SymbolConfiguration(pointSize: L.fileIconPointSize, weight: .regular)
        iconView.image = UIImage(systemName: "doc.fill", withConfiguration: config)
        iconView.contentMode = .center
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)

        nameLabel.font = L.fileNameFont
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        sizeLabel.font = L.fileSizeFont
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sizeLabel)

        let pad = L.filePadding

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: L.fileIconSize),
            iconView.heightAnchor.constraint(equalToConstant: L.fileIconSize),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: L.fileContentSpacing),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: pad),
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            sizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pad),
            heightAnchor.constraint(greaterThanOrEqualToConstant: L.fileIconSize + pad * 2),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func configure(file: FilePayload, isMine: Bool, theme: ChatTheme) {
        backgroundColor = isMine ? theme.outgoingFileBackground : theme.incomingFileBackground
        nameLabel.text = file.name
        nameLabel.textColor = isMine ? theme.outgoingText : theme.incomingText
        sizeLabel.text = formatSize(file.size)
        sizeLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        iconView.tintColor = isMine ? theme.outgoingText : theme.fileIconColor

        let ext = (file.name as NSString).pathExtension.lowercased()
        let icon: String
        switch ext {
        case "pdf": icon = "doc.richtext.fill"
        case "zip", "rar", "7z": icon = "doc.zipper"
        case "mp3", "wav", "aac", "m4a": icon = "music.note"
        case "mp4", "mov", "avi": icon = "film"
        default: icon = "doc.fill"
        }
        let cfg = UIImage.SymbolConfiguration(pointSize: ChatLayout().fileIconPointSize, weight: .regular)
        iconView.image = UIImage(systemName: icon, withConfiguration: cfg)
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    @objc private func tapped() { onTap?() }
}
