import UIKit

public final class TextContentView: UIView, UIGestureRecognizerDelegate {

    // MARK: - Колбэк

    var onLinkTap: ((URL) -> Void)?

    // MARK: - Вью

    private let label = UILabel()
    private var currentLayout = ChatLayout()

    // MARK: - Состояние детекции ссылок

    private var linkRanges: [(range: NSRange, url: URL)] = []
    private var hitTestStorage: NSTextStorage?
    private var hitTestLayoutManager: NSLayoutManager?
    private var hitTestContainer: NSTextContainer?

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = currentLayout.messageFont
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        label.addGestureRecognizer(tap)
    }

    public required init?(coder: NSCoder) { fatalError() }

    // MARK: - Конфигурация

    func configure(text: String, ownership: MessageOwnership, theme: ChatTheme, layout: ChatLayout = ChatLayout(), linkDetectionEnabled: Bool = true) {
        currentLayout = layout
        label.font = layout.messageFont
        label.textAlignment = ownership == .system ? .center : .natural

        let textColor: UIColor
        switch ownership {
        case .mine:   textColor = theme.outgoingText
        case .theirs: textColor = theme.incomingText
        case .system: textColor = theme.systemText
        case .pinned: textColor = theme.pinnedText
        }

        let linkColor: UIColor
        switch ownership {
        case .mine:   linkColor = theme.outgoingLink
        case .theirs: linkColor = theme.incomingLink
        case .system: linkColor = theme.incomingLink
        case .pinned: linkColor = theme.incomingLink
        }

        if linkDetectionEnabled {
            let attributed = Self.buildAttributedText(
                text: text,
                font: layout.messageFont,
                textColor: textColor,
                linkColor: linkColor
            )
            label.attributedText = attributed.string
            linkRanges = attributed.links
            setupHitTestKit(attributedText: attributed.string, font: layout.messageFont)
        } else {
            label.attributedText = nil
            label.text = text
            label.textColor = textColor
            linkRanges = []
            hitTestStorage = nil
            hitTestLayoutManager = nil
            hitTestContainer = nil
        }
    }

    // MARK: - Детекция ссылок

    private struct DetectedText {
        let string: NSAttributedString
        let links: [(range: NSRange, url: URL)]
    }

    private static let detector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
    }()

    private static func buildAttributedText(text: String, font: UIFont, textColor: UIColor, linkColor: UIColor) -> DetectedText {
        let attrStr = NSMutableAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: textColor,
        ])

        var links: [(range: NSRange, url: URL)] = []
        let nsRange = NSRange(location: 0, length: (text as NSString).length)

        detector?.enumerateMatches(in: text, options: [], range: nsRange) { result, _, _ in
            guard let result else { return }
            let range = result.range

            let url: URL?
            switch result.resultType {
            case .link:
                url = result.url
            case .phoneNumber:
                if let phone = result.phoneNumber {
                    url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")
                } else {
                    url = nil
                }
            default:
                url = nil
            }

            if let url {
                attrStr.addAttributes([
                    .foregroundColor: linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ], range: range)
                links.append((range: range, url: url))
            }
        }

        return DetectedText(string: attrStr, links: links)
    }

    // MARK: - Hit-тестирование

    private func setupHitTestKit(attributedText: NSAttributedString, font: UIFont) {
        let storage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: .zero)
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = 0
        container.lineBreakMode = .byWordWrapping
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)

        hitTestStorage = storage
        hitTestLayoutManager = layoutManager
        hitTestContainer = container
    }

    private func linkURL(at point: CGPoint) -> URL? {
        guard !linkRanges.isEmpty,
              let layoutManager = hitTestLayoutManager,
              let container = hitTestContainer else { return nil }

        container.size = label.bounds.size
        let index = layoutManager.characterIndex(for: point, in: container, fractionOfDistanceBetweenInsertionPoints: nil)

        for link in linkRanges {
            if NSLocationInRange(index, link.range) {
                return link.url
            }
        }
        return nil
    }

    // MARK: - Жесты

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: label)
        if let url = linkURL(at: point) {
            onLinkTap?(url)
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    /// Начинаем жест только если тап попал на ссылку.
    /// Иначе — пробрасываем дальше на cell-level тап (chatDidTapMessage).
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: label)
        return linkURL(at: point) != nil
    }
}
