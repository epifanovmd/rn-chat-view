import UIKit

final class FileContentView: UIView {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let sizeLabel = UILabel()
    private var currentLayout = ChatLayout()

    // MARK: - Stored constraints

    private var iconLeadingConstraint: NSLayoutConstraint!
    private var iconWidthConstraint: NSLayoutConstraint!
    private var iconHeightConstraint: NSLayoutConstraint!
    private var nameLabelLeadingConstraint: NSLayoutConstraint!
    private var nameLabelTrailingConstraint: NSLayoutConstraint!
    private var nameLabelTopConstraint: NSLayoutConstraint!
    private var sizeLabelBottomConstraint: NSLayoutConstraint!
    private var minHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let L = currentLayout

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

        iconLeadingConstraint = iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad)
        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: L.fileIconSize)
        iconHeightConstraint = iconView.heightAnchor.constraint(equalToConstant: L.fileIconSize)
        nameLabelLeadingConstraint = nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: L.fileContentSpacing)
        nameLabelTrailingConstraint = nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad)
        nameLabelTopConstraint = nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: pad)
        sizeLabelBottomConstraint = sizeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pad)
        minHeightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: L.fileIconSize + pad * 2)

        NSLayoutConstraint.activate([
            iconLeadingConstraint,
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconWidthConstraint,
            iconHeightConstraint,
            nameLabelLeadingConstraint,
            nameLabelTrailingConstraint,
            nameLabelTopConstraint,
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            sizeLabelBottomConstraint,
            minHeightConstraint,
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func configure(file: FilePayload, isMine: Bool, theme: ChatTheme, layout: ChatLayout = ChatLayout()) {
        currentLayout = layout
        let L = currentLayout
        let pad = L.filePadding

        // Update fonts
        nameLabel.font = L.fileNameFont
        sizeLabel.font = L.fileSizeFont
        layer.cornerRadius = L.fileCornerRadius

        // Update constraint constants
        iconLeadingConstraint.constant = pad
        iconWidthConstraint.constant = L.fileIconSize
        iconHeightConstraint.constant = L.fileIconSize
        nameLabelLeadingConstraint.constant = L.fileContentSpacing
        nameLabelTrailingConstraint.constant = -pad
        nameLabelTopConstraint.constant = pad
        sizeLabelBottomConstraint.constant = -pad
        minHeightConstraint.constant = L.fileIconSize + pad * 2

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
        let cfg = UIImage.SymbolConfiguration(pointSize: L.fileIconPointSize, weight: .regular)
        iconView.image = UIImage(systemName: icon, withConfiguration: cfg)
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    @objc private func tapped() { onTap?() }
}
