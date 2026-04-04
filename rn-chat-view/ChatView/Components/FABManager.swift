import UIKit

/// Manages the Floating Action Button (scroll-to-bottom) and unread badge.
final class FABManager {

    // MARK: - Views

    let button = UIButton(type: .custom)
    let arrow = UIImageView()
    let badge = PaddedLabel(hPad: 6)

    // MARK: - State

    private(set) var isVisible = false
    private var isExpanded = false
    var onTap: (() -> Void)?

    // MARK: - Constraints

    /// Above mic button (inputBar.bottomAnchor based) — used when no text
    private var compactConstraint: NSLayoutConstraint!
    /// Above entire input bar (inputBar.topAnchor based) — used when text present
    private var expandedConstraint: NSLayoutConstraint!

    // MARK: - Setup

    func setup(in parentView: UIView, inputBar: UIView, layout: ChatLayout, theme: ChatTheme, features: ChatFeatures) {
        let size = layout.inputButtonSize

        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = size / 2
        button.layer.borderWidth = layout.inputBorderWidth
        button.alpha = 0
        button.isUserInteractionEnabled = false
        button.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        parentView.addSubview(button)

        if !features.showFab {
            button.isHidden = true
        }

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        arrow.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.isUserInteractionEnabled = false
        button.addSubview(arrow)

        badge.font = layout.fabBadgeFont
        badge.textAlignment = .center
        badge.layer.cornerRadius = layout.fabBadgeCornerRadius
        badge.layer.masksToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.isHidden = true
        badge.isUserInteractionEnabled = false
        parentView.addSubview(badge)

        let hPad = layout.inputBarHPad
        let aboveMicOffset = layout.inputBarVPad + size + layout.fabMargin
        let singleLineHeight = 2 * layout.inputBarVPad + layout.textViewMinHeight
        let expandedGap = aboveMicOffset - singleLineHeight

        compactConstraint = button.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -aboveMicOffset)
        expandedConstraint = button.bottomAnchor.constraint(equalTo: inputBar.topAnchor, constant: -expandedGap)

        compactConstraint.isActive = true
        expandedConstraint.isActive = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size),
            button.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -hPad),
            arrow.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            badge.centerXAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            badge.centerYAnchor.constraint(equalTo: button.topAnchor, constant: 4),
            badge.heightAnchor.constraint(equalToConstant: layout.fabBadgeHeight),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: layout.fabBadgeMinWidth),
        ])

        applyTheme(theme)
    }

    // MARK: - Theme

    func applyTheme(_ theme: ChatTheme) {
        let ibTheme = InputBarTheme.from(theme)
        button.backgroundColor = ibTheme.background
        button.layer.borderColor = ibTheme.border.cgColor
        arrow.tintColor = theme.fabArrowColor
        badge.backgroundColor = theme.fabBadgeBackground
        badge.textColor = theme.fabBadgeTextColor
    }

    // MARK: - Position

    /// Switch between compact (above mic) and expanded (above entire input bar) positions.
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
        badge.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
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
