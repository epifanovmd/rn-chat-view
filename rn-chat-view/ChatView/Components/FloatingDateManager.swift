import UIKit

/// Manages the floating date pill that appears during scrolling.
final class FloatingDateManager {

    // MARK: - Views

    private let pill = UIView()
    private let label = UILabel()
    private var topConstraint: NSLayoutConstraint?

    // MARK: - State

    private var hideTask: DispatchWorkItem?
    private var currentDate: String?
    private var layout = ChatLayout()

    // MARK: - Setup

    func setup(in parentView: UIView, safeAreaGuide: UILayoutGuide, layout: ChatLayout, theme: ChatTheme, extraInsetTop: CGFloat) {
        self.layout = layout
        let L = layout

        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.layer.cornerRadius = L.dateSeparatorCornerRadius
        pill.alpha = 0
        parentView.addSubview(pill)

        label.font = L.dateSeparatorFont
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(label)

        let topC = pill.topAnchor.constraint(
            equalTo: safeAreaGuide.topAnchor,
            constant: L.sectionSpacing + extraInsetTop
        )
        topConstraint = topC

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            topC,
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: L.dateSeparatorVPad),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -L.dateSeparatorVPad),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: L.dateSeparatorHPad),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -L.dateSeparatorHPad),
        ])

        applyTheme(theme)
    }

    // MARK: - Configuration

    func setHidden(_ hidden: Bool) {
        pill.isHidden = hidden
        if hidden { hide() }
    }

    func updateTopConstraint(extraInsetTop: CGFloat) {
        topConstraint?.constant = layout.sectionSpacing + extraInsetTop
    }

    func applyTheme(_ theme: ChatTheme) {
        pill.backgroundColor = theme.dateSeparatorBackground
        label.textColor = theme.dateSeparatorText
    }

    // MARK: - Update

    func update(
        cachedSeparators: [(index: Int, item: DateSeparatorListItem)],
        collectionView: UICollectionView,
        parentView: UIView,
        extraInsetTop: CGFloat
    ) {
        let spacing = layout.sectionSpacing

        struct DateInfo {
            let groupDate: String
            let minY: CGFloat
            let maxY: CGFloat
        }
        var dateSections: [DateInfo] = []

        for (index, item) in cachedSeparators {
            guard let attrs = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: index)) else { continue }
            let f = collectionView.convert(attrs.frame, to: parentView)
            dateSections.append(DateInfo(groupDate: item.groupDate, minY: f.minY, maxY: f.maxY))
        }

        guard !dateSections.isEmpty else { return }

        let pillRestY = parentView.safeAreaLayoutGuide.layoutFrame.minY + spacing + extraInsetTop
        let pillH = pill.bounds.height > 0
            ? pill.bounds.height
            : layout.dateSeparatorFont.lineHeight + layout.dateSeparatorVPad * 2
        let pillBottom = pillRestY + pillH

        var foundDate: String?
        var datePassed = false
        var nextInfo: DateInfo?

        for (i, info) in dateSections.enumerated() {
            if info.maxY < pillRestY - spacing {
                foundDate = info.groupDate
                datePassed = true
                nextInfo = (i + 1 < dateSections.count) ? dateSections[i + 1] : nil
            }
        }

        if !datePassed {
            currentDate = nil
            hide()
            return
        }

        guard let groupDate = foundDate else { return }

        if let next = nextInfo {
            let triggerY = pillBottom + spacing
            if next.minY < triggerY {
                pill.transform = CGAffineTransform(translationX: 0, y: next.minY - triggerY)
            } else {
                pill.transform = .identity
            }
        } else {
            pill.transform = .identity
        }

        if groupDate != currentDate {
            currentDate = groupDate
            label.text = DateHelper.shared.sectionTitle(from: groupDate)
            pill.transform = .identity
            pill.alpha = 0
        }

        show()
    }

    // MARK: - Show / Hide

    private func show() {
        hideTask?.cancel()
        if pill.alpha < 1 {
            UIView.animate(withDuration: layout.floatingDateShowDuration) { self.pill.alpha = 1 }
        }
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: self.layout.floatingDateHideDuration) { self.pill.alpha = 0 }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + layout.floatingDateHideDelay, execute: task)
    }

    func hide() {
        hideTask?.cancel()
        UIView.animate(withDuration: layout.floatingDateHideDuration) {
            self.pill.alpha = 0
            self.pill.transform = .identity
        }
    }

    func cancelPendingTasks() {
        hideTask?.cancel()
    }
}
