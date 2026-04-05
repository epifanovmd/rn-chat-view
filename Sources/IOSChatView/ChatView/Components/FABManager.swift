import UIKit

/// Manages the Floating Action Button (scroll-to-bottom) and unread badge.
public final class FABManager {

    // MARK: - Views

    private(set) var button: UIView!
    private(set) var badge: UIView!

    // MARK: - State

    private(set) var isVisible = false
    private var isExpanded = false
    var onTap: (() -> Void)?

    // MARK: - Constraints

    private var compactConstraint: NSLayoutConstraint!
    private var expandedConstraint: NSLayoutConstraint!

    // MARK: - Setup

    func setup(in parentView: UIView, inputBar: UIView, factory: ChatContentFactory, layout: ChatLayout, theme: ChatTheme, features: ChatFeatures) {
        let size = layout.inputButtonSize

        // FAB button (from factory)
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

        // Badge (from factory)
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

    // MARK: - Position

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

    // MARK: - Visibility

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

    // MARK: - Actions

    @objc private func handleTap() {
        onTap?()
    }
}
