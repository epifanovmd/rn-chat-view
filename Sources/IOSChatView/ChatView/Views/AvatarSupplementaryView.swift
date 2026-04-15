import UIKit

final class AvatarSupplementaryView: UICollectionReusableView {
    static let kind = "AvatarSupplementary"
    static let reuseID = "AvatarSupplementaryView"

    private var avatarView: UIView?

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView?.removeFromSuperview()
        avatarView = nil
    }

    func configure(view: UIView, size: CGFloat) {
        avatarView?.removeFromSuperview()
        avatarView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: size),
            view.heightAnchor.constraint(equalToConstant: size),
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}
