import UIKit

/// Manages the empty state view (spinner + "no messages" text).
public final class EmptyStateManager: NSObject {

    // MARK: - Views

    private let container = UIView()
    private var contentView: UIView?
    private var loadingView: UIView?

    // MARK: - Setup

    var onTap: (() -> Void)?

    func setup(in parentView: UIView, inputBar: UIView, factory: ChatContentFactory, layout: ChatLayout, theme: ChatTheme) {
        container.isHidden = true
        container.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(container)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        container.addGestureRecognizer(tap)

        // Empty state content (from factory)
        let content = factory.emptyStateView(theme: theme, layout: layout)
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        self.contentView = content

        // Loading view (from factory)
        let loading = factory.emptyStateLoadingView(theme: theme, layout: layout)
        loading.translatesAutoresizingMaskIntoConstraints = false
        loading.isHidden = true
        container.addSubview(loading)
        self.loadingView = loading

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: parentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: inputBar.topAnchor),
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: layout.emptyStatePadding),
            loading.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }

    // MARK: - Theme

    func applyTheme(factory: ChatContentFactory, theme: ChatTheme, layout: ChatLayout) {
        // Rebuild content views with new theme
        contentView?.removeFromSuperview()
        loadingView?.removeFromSuperview()

        let content = factory.emptyStateView(theme: theme, layout: layout)
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        self.contentView = content

        let loading = factory.emptyStateLoadingView(theme: theme, layout: layout)
        loading.translatesAutoresizingMaskIntoConstraints = false
        loading.isHidden = true
        container.addSubview(loading)
        self.loadingView = loading

        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            content.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: layout.emptyStatePadding),
            loading.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }

    // MARK: - Text

    func updateText(_ text: String?) {
        guard let label = contentView as? UILabel else { return }
        label.text = text ?? NSLocalizedString("chat.empty", value: "Сообщений пока нет.\nНапишите первым!", comment: "")
    }

    // MARK: - Update

    func update(isEmpty: Bool, isLoading: Bool, showEmptyState: Bool) {
        guard showEmptyState else {
            container.isHidden = true
            return
        }
        let wasHidden = container.isHidden
        container.isHidden = !isEmpty
        if isEmpty && isLoading {
            contentView?.isHidden = true
            loadingView?.isHidden = false
        } else {
            loadingView?.isHidden = true
            contentView?.isHidden = false
        }
        // Force layout before first show to prevent "fly in" animation
        if wasHidden && !container.isHidden {
            container.superview?.layoutIfNeeded()
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        onTap?()
    }
}
