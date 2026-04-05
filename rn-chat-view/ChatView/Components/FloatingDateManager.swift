import UIKit

/// Manages the floating date pill that appears during scrolling.
final class FloatingDateManager {

    // MARK: - Views

    private let container = UIView()
    private var contentView: UIView?
    private var topConstraint: NSLayoutConstraint?

    // MARK: - State

    private var hideTask: DispatchWorkItem?
    private var currentDate: String?
    private var layout = ChatLayout()
    private var theme: ChatTheme = .light
    private var factory: ChatContentFactory = DefaultChatContentFactory()

    // MARK: - Setup

    func setup(in parentView: UIView, safeAreaGuide: UILayoutGuide, layout: ChatLayout, theme: ChatTheme, extraInsetTop: CGFloat, factory: ChatContentFactory) {
        self.layout = layout
        self.theme = theme
        self.factory = factory

        container.translatesAutoresizingMaskIntoConstraints = false
        container.alpha = 0
        parentView.addSubview(container)

        let topC = container.topAnchor.constraint(
            equalTo: safeAreaGuide.topAnchor,
            constant: layout.sectionSpacing + extraInsetTop
        )
        topConstraint = topC

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            topC,
        ])
    }

    // MARK: - Configuration

    func setHidden(_ hidden: Bool) {
        container.isHidden = hidden
        if hidden { hide() }
    }

    func updateTopConstraint(extraInsetTop: CGFloat) {
        topConstraint?.constant = layout.sectionSpacing + extraInsetTop
    }

    func applyTheme(_ theme: ChatTheme) {
        self.theme = theme
        if let date = currentDate {
            rebuildContent(title: DateHelper.shared.sectionTitle(from: date))
        }
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
        let pillH = container.bounds.height > 0
            ? container.bounds.height
            : factory.dateSeparatorHeight(layout: layout)
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
                container.transform = CGAffineTransform(translationX: 0, y: next.minY - triggerY)
            } else {
                container.transform = .identity
            }
        } else {
            container.transform = .identity
        }

        if groupDate != currentDate {
            currentDate = groupDate
            rebuildContent(title: DateHelper.shared.sectionTitle(from: groupDate))
            container.transform = .identity
            container.alpha = 0
        }

        show()
    }

    // MARK: - Content

    private func rebuildContent(title: String) {
        contentView?.removeFromSuperview()
        let view = factory.floatingDateView(title: title, theme: theme, layout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        contentView = view
    }

    // MARK: - Show / Hide

    private func show() {
        hideTask?.cancel()
        if container.alpha < 1 {
            UIView.animate(withDuration: layout.floatingDateShowDuration) { self.container.alpha = 1 }
        }
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            UIView.animate(withDuration: self.layout.floatingDateHideDuration) { self.container.alpha = 0 }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + layout.floatingDateHideDelay, execute: task)
    }

    func hide() {
        hideTask?.cancel()
        UIView.animate(withDuration: layout.floatingDateHideDuration) {
            self.container.alpha = 0
            self.container.transform = .identity
        }
    }

    func cancelPendingTasks() {
        hideTask?.cancel()
    }
}
