import UIKit

public final class FloatingDateManager {

    // MARK: - Вьюхи

    private let container = UIView()
    private var contentView: UIView?
    private var topConstraint: NSLayoutConstraint?

    // MARK: - Состояние

    private var hideTask: DispatchWorkItem?
    private var currentDate: String?
    private var layout = ChatLayout()
    private var theme: ChatTheme = .light
    private weak var factory: ChatContentFactory?

    // MARK: - Настройка

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

    // MARK: - Конфигурация

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

    // MARK: - Обновление

    func update(
        cachedSeparators: [(rowIndex: Int, groupDate: String)],
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

        for (rowIndex, groupDate) in cachedSeparators {
            guard let attrs = collectionView.layoutAttributesForItem(at: IndexPath(item: rowIndex, section: 0)) else { continue }
            let f = collectionView.convert(attrs.frame, to: parentView)
            dateSections.append(DateInfo(groupDate: groupDate, minY: f.minY, maxY: f.maxY))
        }

        guard !dateSections.isEmpty else { return }

        let pillRestY = parentView.safeAreaLayoutGuide.layoutFrame.minY + spacing + extraInsetTop
        let pillH = container.bounds.height > 0
            ? container.bounds.height
            : factory?.dateSeparatorHeight(layout: layout) ?? 24
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

    // MARK: - Контент

    private func rebuildContent(title: String) {
        contentView?.removeFromSuperview()
        guard let view = factory?.floatingDateView(title: title, theme: theme, layout: layout) else { return }
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

    // MARK: - Показ / Скрытие

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
