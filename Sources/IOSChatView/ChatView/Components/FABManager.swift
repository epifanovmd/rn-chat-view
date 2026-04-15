import UIKit

public final class FABManager {

    // MARK: - Вьюхи

    private(set) var button: UIView!
    private(set) var badge: UIView!

    // MARK: - Состояние

    private(set) var isVisible = false
    private var isExpanded = false
    private var isLoading = false
    private var loadingRing: CAShapeLayer?
    var onTap: (() -> Void)?

    // MARK: - Констрейнты

    private var compactConstraint: NSLayoutConstraint!
    private var expandedConstraint: NSLayoutConstraint!

    // MARK: - Настройка

    func setup(in parentView: UIView, inputBar: UIView, factory: ChatContentFactory, layout: ChatLayout, theme: ChatTheme, features: ChatFeatures) {
        let size = layout.inputButtonSize

        let fab = factory.fabView(theme: theme, layout: layout)
        fab.translatesAutoresizingMaskIntoConstraints = false
        fab.alpha = 0
        fab.isUserInteractionEnabled = false
        parentView.addSubview(fab)
        self.button = fab

        if let btn = fab as? UIButton {
            btn.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        } else {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            fab.addGestureRecognizer(tap)
        }

        if !features.showFab {
            fab.isHidden = true
        }

        let badgeView = factory.fabBadgeView(theme: theme, layout: layout)
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.isHidden = true
        badgeView.isUserInteractionEnabled = false
        parentView.addSubview(badgeView)
        self.badge = badgeView

        let hPad = layout.inputBarHPad
        let aboveMicOffset = layout.inputBarVPad + size + layout.fabMargin
        let singleLineHeight = 2 * layout.inputBarVPad + layout.textViewMinHeight
        let expandedGap = aboveMicOffset - singleLineHeight

        compactConstraint = fab.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -aboveMicOffset)
        expandedConstraint = fab.bottomAnchor.constraint(equalTo: inputBar.topAnchor, constant: -expandedGap)

        compactConstraint.isActive = true
        expandedConstraint.isActive = false

        NSLayoutConstraint.activate([
            fab.widthAnchor.constraint(equalToConstant: size),
            fab.heightAnchor.constraint(equalToConstant: size),
            fab.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -hPad),
            badgeView.centerXAnchor.constraint(equalTo: fab.leadingAnchor, constant: 4),
            badgeView.centerYAnchor.constraint(equalTo: fab.topAnchor, constant: 4),
            badgeView.heightAnchor.constraint(equalToConstant: layout.fabBadgeHeight),
            badgeView.widthAnchor.constraint(greaterThanOrEqualToConstant: layout.fabBadgeMinWidth),
        ])
    }

    // MARK: - Тема

    func applyTheme(_ theme: ChatTheme, layout: ChatLayout, factory: ChatContentFactory) {
        let newFab = factory.fabView(theme: theme, layout: layout)

        button.backgroundColor = newFab.backgroundColor
        button.layer.borderColor = newFab.layer.borderColor

        for sub in button.subviews {
            if let arrow = sub as? UIImageView {
                for newSub in newFab.subviews {
                    if let newArrow = newSub as? UIImageView {
                        arrow.tintColor = newArrow.tintColor
                    }
                }
            }
        }

        let newBadge = factory.fabBadgeView(theme: theme, layout: layout)
        badge.backgroundColor = newBadge.backgroundColor
        if let label = badge as? UILabel, let newLabel = newBadge as? UILabel {
            label.textColor = newLabel.textColor
        }

        updateLoadingRingColor()
    }

    // MARK: - Позиция

    func setExpanded(_ expanded: Bool, animated: Bool) {
        guard expanded != isExpanded else { return }
        isExpanded = expanded

        compactConstraint.isActive = !expanded
        expandedConstraint.isActive = expanded

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                self.button.superview?.layoutIfNeeded()
            }
        }
    }

    // MARK: - Видимость

    func updateVisibility(isNearBottom: Bool, hasMessages: Bool, animated: Bool) {
        let shouldShow = !isNearBottom && hasMessages
        guard shouldShow != isVisible else { return }
        isVisible = shouldShow
        let alpha: CGFloat = shouldShow ? 1 : 0
        button.isUserInteractionEnabled = shouldShow
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.button.alpha = alpha
            }
        } else {
            button.alpha = alpha
        }
    }

    func updateBadge(unreadCount: Int) {
        badge.isHidden = unreadCount == 0 || !isVisible
        guard unreadCount > 0 else { return }
        if let label = badge as? UILabel {
            label.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
        }
        let badgeAlpha: CGFloat = isVisible ? 1 : 0
        badge.alpha = badgeAlpha
    }

    func setEnabled(_ enabled: Bool) {
        button.isHidden = !enabled
        if !enabled {
            button.alpha = 0; badge.alpha = 0; isVisible = false
        }
    }

    func hideForRecording() {
        UIView.animate(withDuration: 0.2) {
            self.button.alpha = 0
            self.badge.alpha = 0
        }
    }

    // MARK: - Загрузка (спиннер-кольцо)

    /// Принудительно показывает FAB с анимацией.
    func forceShow() {
        guard !isVisible else { return }
        isVisible = true
        // При загрузке нажатия заблокированы
        button.isUserInteractionEnabled = !isLoading
        UIView.animate(withDuration: 0.25) {
            self.button.alpha = 1
        }
    }

    /// Включает/выключает спиннер-кольцо по внутреннему контуру FAB.
    /// При загрузке иконка приглушается и нажатия блокируются.
    func setLoading(_ loading: Bool) {
        guard loading != isLoading else { return }
        isLoading = loading

        if loading {
            showLoadingRing()
            setArrowAlpha(0.3)
            button.isUserInteractionEnabled = false
        } else {
            hideLoadingRing()
            setArrowAlpha(1.0)
            button.isUserInteractionEnabled = isVisible
        }
    }

    private func showLoadingRing() {
        guard loadingRing == nil else { return }
        let size = button.bounds.width
        guard size > 0 else { return }

        let ring = CAShapeLayer()
        let inset: CGFloat = 4
        let radius = size / 2 - inset
        ring.frame = button.bounds
        ring.path = UIBezierPath(
            arcCenter: CGPoint(x: size / 2, y: size / 2),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        ).cgPath
        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = button.tintColor?.cgColor ?? UIColor.systemBlue.cgColor
        ring.lineWidth = 2
        ring.lineCap = .round
        ring.strokeStart = 0
        ring.strokeEnd = 0.75

        button.layer.addSublayer(ring)
        loadingRing = ring

        updateLoadingRingColor()

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 0.8
        rotation.repeatCount = .infinity
        rotation.isRemovedOnCompletion = false
        ring.add(rotation, forKey: "spin")
    }

    private func hideLoadingRing() {
        loadingRing?.removeAnimation(forKey: "spin")
        loadingRing?.removeFromSuperlayer()
        loadingRing = nil
    }

    private func setArrowAlpha(_ alpha: CGFloat) {
        for sub in button.subviews {
            if sub is UIImageView {
                sub.alpha = alpha
            }
        }
    }

    /// Обновляет цвет кольца из arrow-цвета FAB.
    private func updateLoadingRingColor() {
        guard let ring = loadingRing else { return }
        // Берём цвет стрелки из subviews
        for sub in button.subviews {
            if let arrow = sub as? UIImageView {
                ring.strokeColor = arrow.tintColor.cgColor
                return
            }
        }
    }

    // MARK: - Действия

    @objc private func handleTap() {
        onTap?()
    }
}
