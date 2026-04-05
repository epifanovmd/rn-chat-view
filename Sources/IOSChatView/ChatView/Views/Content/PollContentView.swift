import UIKit

public final class PollContentView: UIView {
    var onOptionTap: ((String) -> Void)?
    var onDetailTap: (() -> Void)?

    private let questionLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let optionsStack = UIStackView()
    private let footerStack = UIStackView()
    private let votesLabel = UILabel()
    private let resultsLabel = UILabel()
    private var currentLayout = ChatLayout()
    private var optionRows: [PollOptionRow] = []

    // MARK: - Stored constraints

    private var optionsTopConstraint: NSLayoutConstraint!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let L = currentLayout

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

        optionsTopConstraint = optionsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: L.pollHeaderSpacing)

        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: topAnchor),
            questionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            questionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            optionsTopConstraint,
            optionsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            optionsStack.trailingAnchor.constraint(equalTo: trailingAnchor),

            footerStack.topAnchor.constraint(equalTo: optionsStack.bottomAnchor, constant: 6),
            footerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(poll: PollPayload, isMine: Bool, theme: ChatTheme, layout: ChatLayout = ChatLayout()) {
        currentLayout = layout
        let L = currentLayout

        questionLabel.font = L.pollQuestionFont
        subtitleLabel.font = L.pollSubtitleFont
        optionsStack.spacing = L.pollOptionSpacing
        votesLabel.font = L.pollVotesFont
        resultsLabel.font = L.pollVotesFont
        optionsTopConstraint.constant = L.pollHeaderSpacing

        questionLabel.text = poll.question
        questionLabel.textColor = isMine ? theme.outgoingText : theme.incomingText

        var parts: [String] = ["Опрос"]
        if poll.isMultipleChoice { parts.append("множественный выбор") }
        if poll.isAnonymous { parts.append("анонимный") }
        if poll.isClosed { parts = ["Опрос завершён"] }
        subtitleLabel.text = parts.joined(separator: " · ")
        subtitleLabel.textColor = theme.pollSubtitleColor

        // Reuse existing rows or create/remove as needed
        let optionCount = poll.options.count
        while optionRows.count < optionCount {
            let row = PollOptionRow()
            optionRows.append(row)
            optionsStack.addArrangedSubview(row)
        }
        while optionRows.count > optionCount {
            let row = optionRows.removeLast()
            row.removeFromSuperview()
        }

        for (i, option) in poll.options.enumerated() {
            let row = optionRows[i]
            let isSelected = poll.selectedOptionIds.contains(option.id)
            row.update(option: option, isSelected: isSelected, isMine: isMine, theme: theme, layout: L)
            row.onTap = poll.isClosed ? nil : { [weak self] in self?.onOptionTap?(option.id) }
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
    private var currentLayout = ChatLayout()
    private var isFirstConfigure = true

    // MARK: - Stored constraints

    private var heightConst: NSLayoutConstraint!
    private var labelLeadingConstraint: NSLayoutConstraint!
    private var percentTrailingConstraint: NSLayoutConstraint!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let L = currentLayout

        barBg.layer.masksToBounds = true
        barBg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(barBg)

        barFill.layer.masksToBounds = true
        barFill.translatesAutoresizingMaskIntoConstraints = false
        barBg.addSubview(barFill)

        label.font = L.pollOptionFont
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        percentLabel.font = L.pollPercentFont
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(percentLabel)

        heightConst = heightAnchor.constraint(equalToConstant: L.pollBarHeight)
        labelLeadingConstraint = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: L.pollBarHPad)
        percentTrailingConstraint = percentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -L.pollBarHPad)

        NSLayoutConstraint.activate([
            heightConst,

            barBg.topAnchor.constraint(equalTo: topAnchor),
            barBg.leadingAnchor.constraint(equalTo: leadingAnchor),
            barBg.trailingAnchor.constraint(equalTo: trailingAnchor),
            barBg.bottomAnchor.constraint(equalTo: bottomAnchor),

            barFill.topAnchor.constraint(equalTo: barBg.topAnchor),
            barFill.leadingAnchor.constraint(equalTo: barBg.leadingAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBg.bottomAnchor),

            labelLeadingConstraint,
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: percentLabel.leadingAnchor, constant: -6),

            percentTrailingConstraint,
            percentLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func update(option: PollOption, isSelected: Bool, isMine: Bool, theme: ChatTheme, layout: ChatLayout) {
        currentLayout = layout
        let L = currentLayout

        // Corner radius — always set immediately with disabled implicit animations
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        barBg.layer.cornerRadius = L.pollBarCornerRadius
        barFill.layer.cornerRadius = L.pollBarCornerRadius
        CATransaction.commit()

        // Layout constants
        heightConst.constant = L.pollBarHeight
        labelLeadingConstraint.constant = L.pollBarHPad
        percentTrailingConstraint.constant = -L.pollBarHPad

        // Content
        label.text = option.text
        barBg.backgroundColor = theme.pollBarEmpty
        percentLabel.font = L.pollPercentFont
        percentLabel.text = "\(Int(option.percentage * 100))%"

        // Style based on selection
        let textColor: UIColor
        let fillColor: UIColor
        let pctColor: UIColor
        if isSelected {
            label.font = UIFont.systemFont(ofSize: L.pollOptionFont.pointSize, weight: .bold)
            textColor = isMine ? theme.outgoingText : theme.incomingText
            fillColor = theme.pollBarFilled.withAlphaComponent(0.5)
            pctColor = theme.pollBarFilled
        } else {
            label.font = L.pollOptionFont
            textColor = (isMine ? theme.outgoingText : theme.incomingText).withAlphaComponent(0.8)
            fillColor = theme.pollBarFilled.withAlphaComponent(0.1)
            pctColor = isMine ? theme.outgoingTime : theme.incomingTime
        }

        // Update fill width constraint
        fillWidthConstraint?.isActive = false
        let pct = max(0.02, option.percentage)
        fillWidthConstraint = barFill.widthAnchor.constraint(equalTo: barBg.widthAnchor, multiplier: pct)
        fillWidthConstraint?.isActive = true

        // Animate changes if this is a reconfigure (not first configure)
        let shouldAnimate = !isFirstConfigure
        isFirstConfigure = false

        if shouldAnimate {
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3, options: .curveEaseInOut) {
                self.label.textColor = textColor
                self.barFill.backgroundColor = fillColor
                self.percentLabel.textColor = pctColor
                self.barBg.layoutIfNeeded()
            }
        } else {
            label.textColor = textColor
            barFill.backgroundColor = fillColor
            percentLabel.textColor = pctColor
        }
    }

    @objc private func tapped() { onTap?() }
}
