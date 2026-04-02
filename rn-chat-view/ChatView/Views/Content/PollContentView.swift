import UIKit

final class PollContentView: UIView {
    var onOptionTap: ((String) -> Void)?
    var onDetailTap: (() -> Void)?

    private let questionLabel = UILabel()
    private let optionsStack = UIStackView()
    private let votesLabel = UILabel()
    private var isMine = false
    private var theme: ChatTheme = .light

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        questionLabel.font = ChatLayout.current.pollQuestionFont
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(questionLabel)

        optionsStack.axis = .vertical
        optionsStack.spacing = ChatLayout.current.pollOptionSpacing
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(optionsStack)

        votesLabel.font = ChatLayout.current.pollVotesFont
        votesLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(votesLabel)

        let tapDetail = UITapGestureRecognizer(target: self, action: #selector(detailTapped))
        votesLabel.isUserInteractionEnabled = true
        votesLabel.addGestureRecognizer(tapDetail)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: topAnchor),
            questionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            questionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            optionsStack.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 8),
            optionsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            optionsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            votesLabel.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 4),
            votesLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            votesLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(poll: PollPayload, isMine: Bool, theme: ChatTheme) {
        self.isMine = isMine
        self.theme = theme

        questionLabel.text = "📊 \(poll.question)"
        questionLabel.textColor = isMine ? theme.outgoingText : theme.incomingText

        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for option in poll.options {
            let row = PollOptionRow()
            let isSelected = poll.selectedOptionIds.contains(option.id)
            row.configure(option: option, isSelected: isSelected, isMine: isMine, theme: theme)
            row.onTap = { [weak self] in self?.onOptionTap?(option.id) }
            optionsStack.addArrangedSubview(row)
        }

        let votesText = poll.isClosed ? "Poll closed" : "\(poll.totalVotes) votes"
        votesLabel.text = votesText
        votesLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
    }

    @objc private func detailTapped() { onDetailTap?() }
}

// MARK: - PollOptionRow

private final class PollOptionRow: UIView {
    var onTap: (() -> Void)?

    private let barBg = UIView()
    private let barFill = UIView()
    private let label = UILabel()
    private let percentLabel = UILabel()
    private let checkmark = UIImageView()
    private var fillWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        barBg.layer.cornerRadius = ChatLayout.current.pollBarCornerRadius
        barBg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(barBg)

        barFill.layer.cornerRadius = ChatLayout.current.pollBarCornerRadius
        barFill.translatesAutoresizingMaskIntoConstraints = false
        barBg.addSubview(barFill)

        label.font = ChatLayout.current.pollOptionFont
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        percentLabel.font = ChatLayout.current.pollVotesFont
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(percentLabel)

        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
        checkmark.image = UIImage(systemName: "checkmark", withConfiguration: config)
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkmark)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: ChatLayout.current.pollBarHeight),
            barBg.topAnchor.constraint(equalTo: topAnchor),
            barBg.leadingAnchor.constraint(equalTo: leadingAnchor),
            barBg.trailingAnchor.constraint(equalTo: trailingAnchor),
            barBg.bottomAnchor.constraint(equalTo: bottomAnchor),
            barFill.topAnchor.constraint(equalTo: barBg.topAnchor),
            barFill.leadingAnchor.constraint(equalTo: barBg.leadingAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBg.bottomAnchor),
            checkmark.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            checkmark.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 14),
            label.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 6),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -4),
            percentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            percentLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func configure(option: PollOption, isSelected: Bool, isMine: Bool, theme: ChatTheme) {
        label.text = option.text
        label.textColor = isMine ? theme.outgoingText : theme.incomingText
        percentLabel.text = "\(Int(option.percentage))%"
        percentLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        checkmark.isHidden = !isSelected
        checkmark.tintColor = theme.pollSelectedCheck

        barBg.backgroundColor = theme.pollBarEmpty
        barFill.backgroundColor = isSelected ? theme.pollBarFilled : theme.pollBarFilled.withAlphaComponent(ChatLayout.current.pollUnselectedAlpha)

        fillWidthConstraint?.isActive = false
        let pct = max(0.02, option.percentage / 100)
        fillWidthConstraint = barFill.widthAnchor.constraint(equalTo: barBg.widthAnchor, multiplier: pct)
        fillWidthConstraint?.isActive = true
    }

    @objc private func tapped() { onTap?() }
}
