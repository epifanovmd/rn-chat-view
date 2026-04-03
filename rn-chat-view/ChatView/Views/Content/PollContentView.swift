import UIKit

final class PollContentView: UIView {
    var onOptionTap: ((String) -> Void)?
    var onDetailTap: (() -> Void)?

    private let questionLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let optionsStack = UIStackView()
    private let footerStack = UIStackView()
    private let votesLabel = UILabel()
    private let resultsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let L = ChatLayout.current

        questionLabel.font = L.pollQuestionFont
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(questionLabel)

        subtitleLabel.font = L.pollSubtitleFont
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        optionsStack.axis = .vertical
        optionsStack.spacing = L.pollOptionSpacing
        optionsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(optionsStack)

        votesLabel.font = L.pollVotesFont
        votesLabel.translatesAutoresizingMaskIntoConstraints = false

        resultsLabel.text = "Результаты"
        resultsLabel.font = L.pollVotesFont
        resultsLabel.isUserInteractionEnabled = true
        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
        let tapResults = UITapGestureRecognizer(target: self, action: #selector(detailTapped))
        resultsLabel.addGestureRecognizer(tapResults)

        footerStack.axis = .horizontal
        footerStack.spacing = 8
        footerStack.alignment = .center
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        footerStack.addArrangedSubview(votesLabel)
        footerStack.addArrangedSubview(UIView())
        footerStack.addArrangedSubview(resultsLabel)
        addSubview(footerStack)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: topAnchor),
            questionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            questionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            optionsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: L.pollHeaderSpacing),
            optionsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            optionsStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            footerStack.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 6),
            footerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(poll: PollPayload, isMine: Bool, theme: ChatTheme) {
        questionLabel.text = poll.question
        questionLabel.textColor = isMine ? theme.outgoingText : theme.incomingText

        var parts: [String] = ["Опрос"]
        if poll.isMultipleChoice { parts.append("множественный выбор") }
        if poll.isAnonymous { parts.append("анонимный") }
        if poll.isClosed { parts = ["Опрос завершён"] }
        subtitleLabel.text = parts.joined(separator: " · ")
        subtitleLabel.textColor = theme.pollSubtitleColor

        optionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for option in poll.options {
            let row = PollOptionRow()
            let isSelected = poll.selectedOptionIds.contains(option.id)
            row.configure(option: option, isSelected: isSelected, isMine: isMine, theme: theme)
            row.onTap = poll.isClosed ? nil : { [weak self] in self?.onOptionTap?(option.id) }
            optionsStack.addArrangedSubview(row)
        }

        votesLabel.text = "\(poll.totalVotes) голосов"
        votesLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        resultsLabel.isHidden = poll.isAnonymous
        resultsLabel.textColor = isMine ? theme.outgoingStatusRead : theme.voiceWaveformActive
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
    private var fillWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let L = ChatLayout.current

        barBg.layer.cornerRadius = L.pollBarCornerRadius
        barBg.layer.masksToBounds = true
        barBg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(barBg)

        barFill.layer.cornerRadius = L.pollBarCornerRadius
        barFill.translatesAutoresizingMaskIntoConstraints = false
        barBg.addSubview(barFill)

        label.font = L.pollOptionFont
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        percentLabel.font = L.pollPercentFont
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(percentLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: L.pollBarHeight),

            barBg.topAnchor.constraint(equalTo: topAnchor),
            barBg.leadingAnchor.constraint(equalTo: leadingAnchor),
            barBg.trailingAnchor.constraint(equalTo: trailingAnchor),
            barBg.bottomAnchor.constraint(equalTo: bottomAnchor),

            barFill.topAnchor.constraint(equalTo: barBg.topAnchor),
            barFill.leadingAnchor.constraint(equalTo: barBg.leadingAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBg.bottomAnchor),

            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: L.pollBarHPad),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -6),

            percentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -L.pollBarHPad),
            percentLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func configure(option: PollOption, isSelected: Bool, isMine: Bool, theme: ChatTheme) {
        let L = ChatLayout.current

        label.text = option.text
        barBg.backgroundColor = theme.pollBarEmpty

        if isSelected {
            label.font = UIFont.systemFont(ofSize: L.pollOptionFont.pointSize, weight: .bold)
            label.textColor = isMine ? theme.outgoingText : theme.incomingText
            barFill.backgroundColor = theme.pollBarFilled.withAlphaComponent(0.5)
            percentLabel.textColor = theme.pollBarFilled
        } else {
            label.font = L.pollOptionFont
            label.textColor = (isMine ? theme.outgoingText : theme.incomingText).withAlphaComponent(0.8)
            barFill.backgroundColor = theme.pollBarFilled.withAlphaComponent(0.1)
            percentLabel.textColor = isMine ? theme.outgoingTime : theme.incomingTime
        }

        percentLabel.text = "\(Int(option.percentage * 100))%"

        fillWidthConstraint?.isActive = false
        let pct = max(0.02, option.percentage)
        fillWidthConstraint = barFill.widthAnchor.constraint(equalTo: barBg.widthAnchor, multiplier: pct)
        fillWidthConstraint?.isActive = true
    }

    @objc private func tapped() { onTap?() }
}
