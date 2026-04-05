import UIKit

public final class LoadingCell: UICollectionViewCell {
    static let reuseID = "LoadingCell"
    private var indicatorView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    public required init?(coder: NSCoder) { fatalError() }

    func configure(factory: ChatContentFactory, theme: ChatTheme, layout: ChatLayout) {
        indicatorView?.removeFromSuperview()
        let view = factory.loadingIndicatorView(theme: theme, layout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        indicatorView = view
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        indicatorView?.removeFromSuperview()
        indicatorView = nil
    }
}
