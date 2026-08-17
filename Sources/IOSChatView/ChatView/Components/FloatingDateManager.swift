import UIKit

public final class FloatingDateManager {

    // MARK: - Вьюхи

    private let container = UIView()
    private var contentView: UIView?
    private var topConstraint: NSLayoutConstraint?

    // MARK: - Состояние

    private var hideTask: DispatchWorkItem?
    private var lastActivity: CFTimeInterval = 0
    private var isShown = false
    private var currentDate: String?
    private var layout = ChatLayout.shared
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
        guard !cachedSeparators.isEmpty else { return }

        let pillRestY = parentView.safeAreaLayoutGuide.layoutFrame.minY + spacing + extraInsetTop
        let pillH = container.bounds.height > 0
            ? container.bounds.height
            : factory?.dateSeparatorHeight(layout: layout) ?? 24
        let pillBottom = pillRestY + pillH

        // Frame разделителя в координатах parentView — только для кандидатов поиска.
        func separatorFrame(at i: Int) -> CGRect? {
            let ip = IndexPath(item: cachedSeparators[i].rowIndex, section: 0)
            guard let attrs = collectionView.layoutAttributesForItem(at: ip) else { return nil }
            return collectionView.convert(attrs.frame, to: parentView)
        }

        // Разделители упорядочены по Y — бинарный поиск последнего ушедшего
        // за верхний край (maxY < pillRestY - spacing) вместо полного прохода.
        var lo = 0, hi = cachedSeparators.count
        while lo < hi {
            let mid = (lo + hi) >> 1
            if let f = separatorFrame(at: mid), f.maxY < pillRestY - spacing {
                lo = mid + 1
            } else {
                hi = mid
            }
        }

        guard lo > 0 else {
            currentDate = nil
            hide()
            return
        }

        let foundIdx = lo - 1
        let groupDate = cachedSeparators[foundIdx].groupDate

        // Вытеснение пилюли следующим разделителем
        if foundIdx + 1 < cachedSeparators.count, let next = separatorFrame(at: foundIdx + 1) {
            let triggerY = pillBottom + spacing
            container.transform = next.minY < triggerY
                ? CGAffineTransform(translationX: 0, y: next.minY - triggerY)
                : .identity
        } else {
            container.transform = .identity
        }

        if groupDate != currentDate {
            currentDate = groupDate
            rebuildContent(title: DateHelper.shared.sectionTitle(from: groupDate))
            container.transform = .identity
            container.alpha = 0
            isShown = false
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

    /// Вызывается на каждом кадре скролла: анимация запускается один раз,
    /// hide-таймер не пересоздаётся — вместо этого продлевается по lastActivity.
    private func show() {
        lastActivity = CACurrentMediaTime()
        if !isShown {
            isShown = true
            UIView.animate(withDuration: layout.floatingDateShowDuration) { self.container.alpha = 1 }
        }
        scheduleHideIfNeeded(after: layout.floatingDateHideDelay)
    }

    private func scheduleHideIfNeeded(after delay: TimeInterval) {
        guard hideTask == nil else { return }
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.hideTask = nil
            let remaining = self.layout.floatingDateHideDelay - (CACurrentMediaTime() - self.lastActivity)
            if remaining > 0.01 {
                self.scheduleHideIfNeeded(after: remaining)
            } else {
                self.isShown = false
                UIView.animate(withDuration: self.layout.floatingDateHideDuration) { self.container.alpha = 0 }
            }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    }

    func hide() {
        hideTask?.cancel()
        hideTask = nil
        isShown = false
        UIView.animate(withDuration: layout.floatingDateHideDuration) {
            self.container.alpha = 0
            self.container.transform = .identity
        }
    }

    func cancelPendingTasks() {
        hideTask?.cancel()
    }
}
