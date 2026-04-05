import UIKit

public final class DateSeparatorCell: UICollectionViewCell {
    private var customView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    public required init?(coder: NSCoder) { fatalError() }

    func configure(view: UIView) {
        customView?.removeFromSuperview()
        customView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        customView?.removeFromSuperview()
        customView = nil
    }
}
