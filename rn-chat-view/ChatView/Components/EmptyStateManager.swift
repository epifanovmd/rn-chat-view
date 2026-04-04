import UIKit

/// Manages the empty state view (spinner + "no messages" text).
final class EmptyStateManager {

    // MARK: - Views

    private let container = UIView()
    private let label = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)

    // MARK: - Setup

    func setup(in parentView: UIView, layout: ChatLayout, theme: ChatTheme) {
        container.isHidden = true
        container.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(container)

        label.text = NSLocalizedString("chat.empty", value: "Сообщений пока нет.\nНапишите первым!", comment: "")
        label.font = layout.emptyStateFont
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spinner)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: parentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: layout.emptyStatePadding),
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        applyTheme(theme)
    }

    // MARK: - Theme

    func applyTheme(_ theme: ChatTheme) {
        label.textColor = theme.emptyStateText
    }

    // MARK: - Update

    func update(isEmpty: Bool, isLoading: Bool, showEmptyState: Bool) {
        guard showEmptyState else {
            container.isHidden = true
            return
        }
        container.isHidden = !isEmpty
        if isEmpty && isLoading {
            label.isHidden = true
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            label.isHidden = false
        }
    }
}
